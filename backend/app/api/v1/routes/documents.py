from fastapi import APIRouter, Depends, UploadFile, File, Form, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.db.database import get_db
from app.models.document import Document, DocumentStatus
from app.models.case import Case, CaseStatus
from app.models.checklist import UserChecklist, ChecklistStatus
from app.models.user import User
from app.schemas.document import DocumentOut, DocumentValidationResult
from app.services.documents.ocr_service import extract_document_fields
from app.services.documents.validation_service import validate_document
from app.api.v1.middleware.auth_middleware import get_current_user
import uuid, boto3, io
from app.core.config import settings
from datetime import datetime

router = APIRouter(prefix="/documents", tags=["Documents"])


def get_s3_client():
    return boto3.client(
        "s3",
        aws_access_key_id=settings.AWS_ACCESS_KEY_ID,
        aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY,
        region_name=settings.AWS_REGION,
    )


@router.post("/upload", response_model=DocumentOut, status_code=201)
async def upload_document(
    case_id: str = Form(...),
    document_type: str = Form(...),
    file: UploadFile = File(...),
    intended_travel_date: str = Form(None),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    file_bytes = await file.read()
    doc_id = uuid.uuid4()
    s3_key = f"documents/{current_user.id}/{case_id}/{doc_id}/{file.filename}"

    # Upload to S3
    try:
        s3 = get_s3_client()
        s3.upload_fileobj(io.BytesIO(file_bytes), settings.AWS_BUCKET_NAME, s3_key)
    except Exception:
        s3_key = f"local/{doc_id}"  # fallback for dev without S3

    # Extract + validate
    extracted = extract_document_fields(file_bytes, file.content_type or "image/jpeg", document_type)
    validation = validate_document(document_type, extracted, intended_travel_date)

    doc = Document(
        id=doc_id,
        case_id=uuid.UUID(case_id),
        user_id=current_user.id,
        document_type=document_type,
        original_filename=file.filename,
        storage_key=s3_key,
        file_size_kb=len(file_bytes) // 1024,
        mime_type=file.content_type,
        status=DocumentStatus.validated if validation["is_valid"] else DocumentStatus.rejected,
        health_score=validation["health_score"],
        extracted_data=extracted,
        validation_flags={"flags": validation["flags"]},
        suggested_fixes=validation["suggested_fixes"],
        validated_at=datetime.utcnow(),
    )
    db.add(doc)

    # Find matching checklist item
    checklist_result = await db.execute(
        select(UserChecklist).where(
            UserChecklist.case_id == uuid.UUID(case_id),
            UserChecklist.document_type == document_type
        )
    )
    checklist_item = checklist_result.scalar_one_or_none()
    if checklist_item:
        checklist_item.document_id = doc_id
        checklist_item.status = ChecklistStatus.validated if validation["is_valid"] else ChecklistStatus.rejected
        db.add(checklist_item)

    # Recalculate case readiness score and update status
    case_result = await db.execute(select(Case).where(Case.id == uuid.UUID(case_id)))
    case = case_result.scalar_one_or_none()
    if case:
        all_items_result = await db.execute(select(UserChecklist).where(UserChecklist.case_id == case.id))
        all_items = all_items_result.scalars().all()
        
        mandatory_items = [i for i in all_items if i.item_type == "mandatory"]
        if not mandatory_items:
            mandatory_items = list(all_items)
            
        if mandatory_items:
            validated_count = sum(1 for i in mandatory_items if i.status == ChecklistStatus.validated)
            readiness = (validated_count / len(mandatory_items)) * 100
            case.readiness_score = round(readiness, 2)
        else:
            case.readiness_score = 100.0
            
        # Dynamically transition status
        if case.readiness_score == 100.0:
            case.status = CaseStatus.review
        elif case.readiness_score > 0.0:
            case.status = CaseStatus.documents
        db.add(case)

    await db.commit()
    await db.refresh(doc)
    return DocumentOut.model_validate(doc)


@router.get("/case/{case_id}", response_model=list[DocumentOut])
async def list_case_documents(case_id: str, current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Document).where(Document.case_id == uuid.UUID(case_id), Document.user_id == current_user.id))
    return [DocumentOut.model_validate(d) for d in result.scalars().all()]


@router.get("/{document_id}/validation", response_model=DocumentValidationResult)
async def get_validation_result(document_id: str, current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Document).where(Document.id == uuid.UUID(document_id), Document.user_id == current_user.id))
    doc = result.scalar_one_or_none()
    if not doc:
        raise HTTPException(404, "Document not found")
    flags = doc.validation_flags.get("flags", []) if doc.validation_flags else []
    return DocumentValidationResult(
        document_id=doc.id,
        health_score=doc.health_score or 0,
        extracted_fields=doc.extracted_data or {},
        flags=flags,
        suggested_fixes=doc.suggested_fixes or [],
        is_valid=doc.status == DocumentStatus.validated,
    )
