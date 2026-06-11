import uuid
from datetime import datetime
from sqlalchemy import String, DateTime, ForeignKey, Boolean
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.dialects.postgresql import UUID, JSONB
from app.db.database import Base


class Notification(Base):
    __tablename__ = "notifications"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    case_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), ForeignKey("cases.id"))
    title: Mapped[str] = mapped_column(String(255))
    body: Mapped[str] = mapped_column(String(1000))
    notification_type: Mapped[str] = mapped_column(String(50))         # deadline/document/status/interview
    data: Mapped[dict | None] = mapped_column(JSONB)                   # extra payload for deep link
    is_read: Mapped[bool] = mapped_column(Boolean, default=False)
    sent_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    read_at: Mapped[datetime | None] = mapped_column(DateTime)
