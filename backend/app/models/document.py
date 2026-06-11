import uuid
from datetime import datetime
from sqlalchemy import String, Float, DateTime, ForeignKey, Enum as SAEnum, Integer
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.dialects.postgresql import UUID, JSONB
from app.db.database import Base
import enum


class DocumentType(str, enum.Enum):
    passport = "passport"
    bank_statement = "bank_statement"
    employment_letter = "employment_letter"
    degree_certificate = "degree_certificate"
    tax_return = "tax_return"
    invitation_letter = "invitation_letter"
    language_score_card = "language_score_card"
    photo = "photo"
    medical_certificate = "medical_certificate"
    police_clearance = "police_clearance"
    travel_insurance = "travel_insurance"
    admission_letter = "admission_letter"
    other = "other"


class DocumentStatus(str, enum.Enum):
    uploaded = "uploaded"
    processing = "processing"
    validated = "validated"
    rejected = "rejected"
    expired = "expired"


class Document(Base):
    __tablename__ = "documents"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    case_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("cases.id"), nullable=False)
    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    document_type: Mapped[DocumentType] = mapped_column(SAEnum(DocumentType))
    original_filename: Mapped[str] = mapped_column(String(255))
    drive_file_id: Mapped[str | None] = mapped_column(String(500), nullable=True)     # Google Drive file ID
    drive_view_link: Mapped[str | None] = mapped_column(String(1000), nullable=True)  # Shareable Drive link
    drive_folder_id: Mapped[str | None] = mapped_column(String(500), nullable=True)   # Candidate folder ID
    file_size_kb: Mapped[int | None] = mapped_column(Integer)
    mime_type: Mapped[str | None] = mapped_column(String(100))
    status: Mapped[DocumentStatus] = mapped_column(SAEnum(DocumentStatus), default=DocumentStatus.uploaded)
    health_score: Mapped[float | None] = mapped_column(Float)           # 0-100
    extracted_data: Mapped[dict | None] = mapped_column(JSONB)          # OCR extracted fields
    validation_flags: Mapped[dict | None] = mapped_column(JSONB)        # issues found
    suggested_fixes: Mapped[list | None] = mapped_column(JSONB)
    page_count: Mapped[int | None] = mapped_column(Integer)
    uploaded_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    validated_at: Mapped[datetime | None] = mapped_column(DateTime)

    case: Mapped["Case"] = relationship("Case", back_populates="documents")
