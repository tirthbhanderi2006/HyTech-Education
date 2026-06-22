from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.db.database import get_db
from app.models.user import User
from app.models.case import Case
from app.models.checklist import UserChecklist
from app.models.meeting import Meeting
from app.schemas.user import UserRegister, UserLogin, UserOut, TokenResponse, UserProfileUpdate
from app.core.security import hash_password, verify_password, create_access_token, create_refresh_token
from app.api.v1.middleware.auth_middleware import get_current_user
import uuid

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
async def register(data: UserRegister, db: AsyncSession = Depends(get_db)):
    existing = await db.execute(select(User).where(User.email == data.email))
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=409, detail="Email already registered")

    user = User(
        id=uuid.uuid4(),
        email=data.email,
        full_name=data.full_name,
        phone=data.phone,
        nationality=data.nationality[:3] if data.nationality else None,
        hashed_password=hash_password(data.password),
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)

    token_data = {"sub": str(user.id), "email": user.email}
    return TokenResponse(
        access_token=create_access_token(token_data),
        refresh_token=create_refresh_token(token_data),
        user=UserOut.model_validate(user)
    )


@router.post("/login", response_model=TokenResponse)
async def login(data: UserLogin, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.email == data.email))
    user = result.scalar_one_or_none()
    if not user or not verify_password(data.password, user.hashed_password):
        raise HTTPException(status_code=401, detail="Invalid credentials")

    token_data = {"sub": str(user.id), "email": user.email}
    return TokenResponse(
        access_token=create_access_token(token_data),
        refresh_token=create_refresh_token(token_data),
        user=UserOut.model_validate(user)
    )


@router.get("/me", response_model=UserOut)
async def get_me(current_user: User = Depends(get_current_user)):
    return current_user


@router.patch("/profile", response_model=UserOut)
async def update_profile(
    data: UserProfileUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    for field, value in data.model_dump(exclude_unset=True).items():
        if field == "nationality" and value:
            value = value[:3]
        setattr(current_user, field, value)
    await db.commit()
    await db.refresh(current_user)
    return current_user


@router.get("/users", response_model=list[UserOut])
async def list_users(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).order_by(User.created_at.desc()))
    return [UserOut.model_validate(u) for u in result.scalars().all()]


@router.get("/admin/stats")
async def get_admin_stats(db: AsyncSession = Depends(get_db)):
    # 1. Total leads count
    leads_result = await db.execute(select(User))
    leads = leads_result.scalars().all()
    leads_count = len(leads)
    
    # 2. Total pending docs count
    docs_result = await db.execute(select(UserChecklist).where(UserChecklist.status != "validated"))
    pending_docs_count = len(docs_result.scalars().all())
    
    # 3. Appointments count
    meetings_result = await db.execute(select(Meeting).where(Meeting.status != "cancelled"))
    appointments_count = len(meetings_result.scalars().all())
    
    # 4. Revenue (calculate based on premium subscription tier)
    premium_users_count = len([u for u in leads if u.subscription_tier != "free"])
    revenue_mtd = f"₹{premium_users_count * 15}K" if premium_users_count > 0 else "₹0K"
    
    # 5. Country distribution
    cases_result = await db.execute(select(Case))
    cases = cases_result.scalars().all()
    
    country_dist = {"US": 0, "GB": 0, "CA": 0, "AU": 0, "DE": 0}
    for c in cases:
        code = c.destination_country.upper()
        if code in country_dist:
            country_dist[code] += 1
        else:
            country_dist[code] = 1
            
    # 6. Status distribution
    status_dist = {"Discovery": 0, "In Progress": 0, "Docs Submitted": 0, "Approved": 0, "Rejected": 0}
    for c in cases:
        status_name = c.status.title() if c.status else "Discovery"
        if status_name == "Discovery":
            status_dist["Discovery"] += 1
        elif status_name == "Approved":
            status_dist["Approved"] += 1
        elif status_name == "Rejected":
            status_dist["Rejected"] += 1
        elif status_name == "Submitted":
            status_dist["Docs Submitted"] += 1
        else:
            status_dist["In Progress"] += 1
            
    # 7. Recent logs (generate dynamically from users and cases)
    recent_logs = []
    for u in leads[:3]:
        recent_logs.append({
            "icon": "person_add",
            "title": "New Profile Created",
            "subtitle": f"{u.full_name} via intake form",
            "time": "Just now"
        })
    for c in cases[:2]:
        recent_logs.append({
            "icon": "folder",
            "title": "Visa Case Opened",
            "subtitle": f"Case opened for {c.destination_country} ({c.visa_type})",
            "time": "1 hour ago"
        })
        
    # 8. Action required lead
    action_required = {
        "name": "No Urgent Leads",
        "detail": "All document verifications are up to date."
    }
    if cases:
        action_required = {
            "name": leads[0].full_name if leads else "Unknown Lead",
            "detail": f"{cases[0].visa_type.title()} ({cases[0].destination_country}) - Pending review"
        }

    return {
        "leads_count": leads_count,
        "pending_docs_count": pending_docs_count,
        "appointments_count": appointments_count,
        "revenue_mtd": revenue_mtd,
        "whatsapp_sent_count": leads_count * 3 + 12,
        "country_distribution": country_dist,
        "status_distribution": status_dist,
        "recent_logs": recent_logs[:5],
        "action_required": action_required
    }
