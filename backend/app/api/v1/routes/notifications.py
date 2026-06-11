from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update
from app.db.database import get_db
from app.models.notification import Notification
from app.models.user import User
from app.api.v1.middleware.auth_middleware import get_current_user
import uuid
from datetime import datetime

router = APIRouter(prefix="/notifications", tags=["Notifications"])


@router.get("/")
async def list_notifications(current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(Notification)
        .where(Notification.user_id == current_user.id)
        .order_by(Notification.sent_at.desc())
        .limit(50)
    )
    notifs = result.scalars().all()
    return [{"id": str(n.id), "title": n.title, "body": n.body, "type": n.notification_type,
             "is_read": n.is_read, "sent_at": n.sent_at.isoformat()} for n in notifs]


@router.patch("/{notification_id}/read")
async def mark_read(notification_id: str, current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    await db.execute(
        update(Notification)
        .where(Notification.id == uuid.UUID(notification_id), Notification.user_id == current_user.id)
        .values(is_read=True, read_at=datetime.utcnow())
    )
    await db.commit()
    return {"success": True}
