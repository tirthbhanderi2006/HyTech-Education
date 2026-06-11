import uuid
from datetime import datetime
from sqlalchemy import String, Boolean, DateTime, Enum as SAEnum
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.dialects.postgresql import UUID, JSONB
from app.db.database import Base
import enum


class SubscriptionTier(str, enum.Enum):
    free = "free"
    pro = "pro"
    premium = "premium"
    enterprise = "enterprise"


class User(Base):
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email: Mapped[str] = mapped_column(String(255), unique=True, nullable=False, index=True)
    phone: Mapped[str | None] = mapped_column(String(20))
    full_name: Mapped[str] = mapped_column(String(255))
    hashed_password: Mapped[str] = mapped_column(String(255))
    nationality: Mapped[str | None] = mapped_column(String(3))          # ISO 3166-1 alpha-2
    date_of_birth: Mapped[str | None] = mapped_column(String(20))
    passport_number: Mapped[str | None] = mapped_column(String(50))
    passport_expiry: Mapped[str | None] = mapped_column(String(20))
    education_level: Mapped[str | None] = mapped_column(String(50))
    work_years: Mapped[int | None] = mapped_column()
    language_scores: Mapped[dict | None] = mapped_column(JSONB)         # {"ielts": 7.0, "toefl": 100}
    financial_info: Mapped[dict | None] = mapped_column(JSONB)          # {"monthly_income": X, "savings": Y}
    travel_history: Mapped[dict | None] = mapped_column(JSONB)          # [{"country": "US", "year": 2023}]
    subscription_tier: Mapped[SubscriptionTier] = mapped_column(
        SAEnum(SubscriptionTier), default=SubscriptionTier.free
    )
    fcm_token: Mapped[str | None] = mapped_column(String(500))         # Firebase push token
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    is_verified: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
