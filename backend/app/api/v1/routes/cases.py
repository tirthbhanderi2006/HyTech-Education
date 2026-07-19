from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, delete
from app.db.database import get_db
from app.models.case import Case
from app.models.user import User
from app.schemas.case import CaseCreate, CaseOut, EligibilityResult, ChecklistOut, ChecklistUpdate
from app.services.ai.eligibility_agent import run_eligibility_agent
from app.services.ai.risk_agent import run_risk_agent
from app.services.ai.checklist_agent import generate_personalized_checklist
from app.models.checklist import UserChecklist
from app.api.v1.middleware.auth_middleware import get_current_user
import uuid

router = APIRouter(prefix="/cases", tags=["Cases"])


@router.post("/", response_model=CaseOut, status_code=201)
async def create_case(data: CaseCreate, current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    case = Case(
        id=uuid.uuid4(),
        user_id=current_user.id,
        destination_country=data.destination_country,
        visa_type=data.visa_type,
        purpose=data.purpose,
        intended_travel_date=data.intended_travel_date,
    )
    db.add(case)

    # Generate personalized checklist
    user_profile = {
        "nationality": current_user.nationality,
        "education_level": current_user.education_level,
        "work_years": current_user.work_years,
        "language_scores": current_user.language_scores,
        "financial_info": current_user.financial_info,
    }
    items = await generate_personalized_checklist(user_profile, data.visa_type, data.destination_country)
    for idx, item in enumerate(items):
        checklist_item = UserChecklist(
            id=uuid.uuid4(),
            case_id=case.id,
            document_type=item.get("type", "other"),
            item_type=item.get("item_type", "mandatory"),
            personalized_description=item.get("template", ""),
            sort_order=idx,
        )
        db.add(checklist_item)

    await db.commit()
    await db.refresh(case)
    return CaseOut.model_validate(case)


@router.get("/", response_model=list[CaseOut])
async def list_cases(user_id: str | None = None, current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    target_user_id = uuid.UUID(user_id) if user_id else current_user.id
    result = await db.execute(select(Case).where(Case.user_id == target_user_id).order_by(Case.created_at.desc()))
    return [CaseOut.model_validate(c) for c in result.scalars().all()]


@router.get("/{case_id}", response_model=CaseOut)
async def get_case(case_id: str, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Case).where(Case.id == uuid.UUID(case_id)))
    case = result.scalar_one_or_none()
    if not case:
        raise HTTPException(404, "Case not found")
    return CaseOut.model_validate(case)


@router.post("/{case_id}/eligibility", response_model=EligibilityResult)
async def run_eligibility(case_id: str, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Case).where(Case.id == uuid.UUID(case_id)))
    case = result.scalar_one_or_none()
    if not case:
        raise HTTPException(404, "Case not found")

    owner_result = await db.execute(select(User).where(User.id == case.user_id))
    owner = owner_result.scalar_one_or_none()
    if not owner:
        raise HTTPException(404, "User not found")

    user_profile = {
        "nationality": owner.nationality,
        "education_level": owner.education_level,
        "work_years": owner.work_years,
        "language_scores": owner.language_scores,
        "financial_info": owner.financial_info,
        "travel_history": owner.travel_history,
        "passport_expiry": owner.passport_expiry,
    }
    visa_program = {
        "country": case.destination_country,
        "type": case.visa_type,
        "purpose": case.purpose,
    }
    report = await run_eligibility_agent(user_profile, visa_program)
    case.eligibility_score = report.get("overall_score", 0)
    await db.commit()
    return EligibilityResult(**report)


@router.post("/{case_id}/risk", response_model=dict)
async def run_risk(case_id: str, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Case).where(Case.id == uuid.UUID(case_id)))
    case = result.scalar_one_or_none()
    if not case:
        raise HTTPException(404, "Case not found")

    owner_result = await db.execute(select(User).where(User.id == case.user_id))
    owner = owner_result.scalar_one_or_none()
    if not owner:
        raise HTTPException(404, "User not found")

    case_data = {
        "user_profile": {"nationality": owner.nationality, "education_level": owner.education_level},
        "case": {"destination": case.destination_country, "visa_type": case.visa_type, "status": case.status},
        "checklist_completion": f"{len([i for i in case.checklist_items if i.status == 'validated'])}/{len(case.checklist_items)}",
    }
    risk = await run_risk_agent(case_data)
    case.risk_score = risk.get("risk_score", 0)
    await db.commit()
    return risk


@router.get("/{case_id}/checklist", response_model=list[ChecklistOut])
async def list_checklist(case_id: str, db: AsyncSession = Depends(get_db)):
    checklist_result = await db.execute(
        select(UserChecklist)
        .where(UserChecklist.case_id == uuid.UUID(case_id))
        .order_by(UserChecklist.sort_order.asc())
    )
    return [ChecklistOut.model_validate(item) for item in checklist_result.scalars().all()]


@router.patch("/{case_id}/checklist/{checklist_id}", response_model=ChecklistOut)
async def update_checklist_item(
    case_id: str,
    checklist_id: str,
    data: ChecklistUpdate,
    db: AsyncSession = Depends(get_db),
):
    item_result = await db.execute(
        select(UserChecklist)
        .where(UserChecklist.id == uuid.UUID(checklist_id), UserChecklist.case_id == uuid.UUID(case_id))
    )
    item = item_result.scalar_one_or_none()
    if not item:
        raise HTTPException(404, "Checklist item not found")

    for field, value in data.model_dump(exclude_unset=True).items():
        setattr(item, field, value)

    await db.commit()
    await db.refresh(item)
    return ChecklistOut.model_validate(item)


@router.delete("/{case_id}", status_code=204)
async def delete_case(case_id: str, current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Case).where(Case.id == uuid.UUID(case_id), Case.user_id == current_user.id))
    case = result.scalar_one_or_none()
    if not case:
        raise HTTPException(404, "Case not found")
        
    from app.models.checklist import UserChecklist
    from app.models.document import Document
    
    # Delete related checklist items & documents
    await db.execute(delete(UserChecklist).where(UserChecklist.case_id == case.id))
    await db.execute(delete(Document).where(Document.case_id == case.id))
    
    await db.delete(case)
    await db.commit()
    return None

