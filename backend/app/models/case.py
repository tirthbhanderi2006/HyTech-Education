import uuid
from datetime import datetime
from sqlalchemy import String, Float, DateTime, ForeignKey, Enum as SAEnum
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.dialects.postgresql import UUID, JSONB
from app.db.database import Base
import enum


class CaseStatus(str, enum.Enum):
    discovery = "discovery"
    assessment = "assessment"
    documents = "documents"
    form_filling = "form_filling"
    review = "review"
    submitted = "submitted"
    approved = "approved"
    rejected = "rejected"


class Case(Base):
    __tablename__ = "cases"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    visa_program_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), ForeignKey("visa_programs.id"))
    destination_country: Mapped[str | None] = mapped_column(String(3))
    visa_type: Mapped[str | None] = mapped_column(String(50))
    purpose: Mapped[str | None] = mapped_column(String(100))
    intended_travel_date: Mapped[str | None] = mapped_column(String(20))
    status: Mapped[CaseStatus] = mapped_column(SAEnum(CaseStatus), default=CaseStatus.discovery)
    readiness_score: Mapped[float | None] = mapped_column(Float)
    risk_score: Mapped[float | None] = mapped_column(Float)
    eligibility_score: Mapped[float | None] = mapped_column(Float)
    agent_memory: Mapped[dict | None] = mapped_column(JSONB)            # persisted AI agent state
    notes: Mapped[str | None] = mapped_column(String(2000))
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    documents: Mapped[list["Document"]] = relationship("Document", back_populates="case", lazy="selectin")
    checklist_items: Mapped[list["UserChecklist"]] = relationship("UserChecklist", back_populates="case", lazy="selectin")
