import uuid
from datetime import datetime
from sqlalchemy import String, DateTime, ForeignKey, Enum as SAEnum, Integer
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.dialects.postgresql import UUID, JSONB
from app.db.database import Base
import enum


class ChecklistStatus(str, enum.Enum):
    pending = "pending"
    uploaded = "uploaded"
    validated = "validated"
    rejected = "rejected"
    waived = "waived"


class UserChecklist(Base):
    __tablename__ = "user_checklists"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    case_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("cases.id"), nullable=False)
    document_type: Mapped[str] = mapped_column(String(100))
    item_type: Mapped[str] = mapped_column(String(20))                  # mandatory/conditional/recommended
    personalized_description: Mapped[str] = mapped_column(String(1000))
    requirement_detail: Mapped[str | None] = mapped_column(String(500)) # e.g. "must be < 6 months old"
    status: Mapped[ChecklistStatus] = mapped_column(SAEnum(ChecklistStatus), default=ChecklistStatus.pending)
    document_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), ForeignKey("documents.id"))
    sort_order: Mapped[int] = mapped_column(Integer, default=0)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    case: Mapped["Case"] = relationship("Case", back_populates="checklist_items")
