import uuid
from datetime import datetime
from sqlalchemy import String, Float, DateTime, Integer
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.dialects.postgresql import UUID, JSONB
from app.db.database import Base


class VisaProgram(Base):
    __tablename__ = "visa_programs"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    country_code: Mapped[str] = mapped_column(String(3), index=True)
    visa_type: Mapped[str] = mapped_column(String(50))
    name: Mapped[str] = mapped_column(String(255))
    description: Mapped[str | None] = mapped_column(String(2000))
    processing_days_min: Mapped[int] = mapped_column(Integer)
    processing_days_max: Mapped[int] = mapped_column(Integer)
    fee_usd: Mapped[float | None] = mapped_column(Float)
    complexity_score: Mapped[float | None] = mapped_column(Float)       # 1-10
    success_rate: Mapped[float | None] = mapped_column(Float)           # 0-1
    required_documents: Mapped[list] = mapped_column(JSONB)             # list of doc types
    eligibility_rules: Mapped[dict | None] = mapped_column(JSONB)       # rule config
    embassy_url: Mapped[str | None] = mapped_column(String(500))
    last_updated: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
