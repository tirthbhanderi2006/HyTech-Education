from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, or_
from app.db.database import get_db
from app.api.v1.middleware.auth_middleware import get_current_user
from app.models.user import User
from app.models.meeting import Meeting, MeetingStatus
from app.models.counselor_account import CounselorGoogleAccount
from app.schemas.meeting import MeetingBookRequest, MeetingOut, MeetingRescheduleRequest
from app.schemas.user import UserOut
from app.services.google.google_service import (
    get_calendar_service, create_meeting_event,
    delete_calendar_event, update_calendar_event,
)
import logging
import uuid

logger = logging.getLogger("uvicorn")

router = APIRouter(prefix="/meetings", tags=["Meetings"])

@router.post("/book", response_model=MeetingOut)
async def book_meeting(
    payload: MeetingBookRequest,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Candidate books a session — creates DB record and Calendar event."""
    counselor = await db.get(User, payload.counselor_id)
    if not counselor:
        raise HTTPException(status_code=404, detail="Counselor not found.")

    # Get counselor's Google account
    result = await db.execute(
        select(CounselorGoogleAccount)
        .where(CounselorGoogleAccount.user_id == payload.counselor_id)
    )
    google_acc = result.scalars().first()

    event = None
    meet_link = None
    calendar_event_id = None

    # Check if Google OAuth settings are configured and account is linked
    if google_acc and google_acc.is_active:
        try:
            service = get_calendar_service(google_acc.encrypted_refresh_token)
            event = create_meeting_event(
                service=service,
                candidate_email=current_user.email,
                counselor_email=counselor.email,
                title=f"Visa Counseling — {current_user.full_name}",
                start_time=payload.start_time,
                end_time=payload.end_time,
                notes=payload.notes,
            )
            meet_link = event.get("hangoutLink")
            calendar_event_id = event.get("id")
        except Exception as e:
            logger.error(f"Failed to create Google Calendar event: {str(e)}")
            # Graceful fallback to mock Meet link for demo purposes
            meet_link = f"https://meet.google.com/mock-{uuid.uuid4().hex[:8]}"
            calendar_event_id = f"mock-event-{uuid.uuid4().hex[:8]}"
    else:
        # Graceful fallback if counselor has not linked Google account yet
        logger.info(f"Counselor {counselor.full_name} has not connected Google Calendar. Using fallback mock link.")
        meet_link = f"https://meet.google.com/mock-{uuid.uuid4().hex[:8]}"
        calendar_event_id = f"mock-event-{uuid.uuid4().hex[:8]}"

    meeting = Meeting(
        id=uuid.uuid4(),
        case_id=payload.case_id,
        candidate_id=current_user.id,
        counselor_id=payload.counselor_id,
        title=f"Visa Counseling — {current_user.full_name}",
        notes=payload.notes,
        start_time=payload.start_time,
        end_time=payload.end_time,
        meet_link=meet_link,
        calendar_event_id=calendar_event_id,
        status=MeetingStatus.confirmed,
    )
    db.add(meeting)
    await db.commit()
    await db.refresh(meeting)
    return meeting

@router.get("/", response_model=list[MeetingOut])
async def list_meetings(
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Meeting).where(
            or_(
                Meeting.candidate_id == current_user.id,
                Meeting.counselor_id == current_user.id
            )
        ).order_by(Meeting.start_time)
    )
    return result.scalars().all()

@router.get("/all", response_model=list[MeetingOut])
async def list_all_meetings(
    db: AsyncSession = Depends(get_db),
):
    """Returns list of ALL meetings in the system for admin management."""
    result = await db.execute(select(Meeting).order_by(Meeting.start_time.desc()))
    return result.scalars().all()


@router.patch("/{meeting_id}/reschedule", response_model=MeetingOut)
async def reschedule_meeting(
    meeting_id: uuid.UUID,
    payload: MeetingRescheduleRequest,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    meeting = await db.get(Meeting, meeting_id)
    if not meeting:
        raise HTTPException(status_code=404, detail="Meeting not found.")

    # Get counselor's Google account
    result = await db.execute(
        select(CounselorGoogleAccount)
        .where(CounselorGoogleAccount.user_id == meeting.counselor_id)
    )
    google_acc = result.scalars().first()

    if google_acc and google_acc.is_active and meeting.calendar_event_id and not meeting.calendar_event_id.startswith("mock-"):
        try:
            service = get_calendar_service(google_acc.encrypted_refresh_token)
            update_calendar_event(service, meeting.calendar_event_id, payload.start_time, payload.end_time)
        except Exception as e:
            logger.error(f"Failed to update Google Calendar event: {str(e)}")

    meeting.start_time = payload.start_time
    meeting.end_time = payload.end_time
    meeting.status = MeetingStatus.rescheduled
    await db.commit()
    await db.refresh(meeting)
    return meeting

@router.delete("/{meeting_id}")
async def cancel_meeting(
    meeting_id: uuid.UUID,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    meeting = await db.get(Meeting, meeting_id)
    if not meeting:
        raise HTTPException(status_code=404, detail="Meeting not found.")

    # Get counselor's Google account
    result = await db.execute(
        select(CounselorGoogleAccount)
        .where(CounselorGoogleAccount.user_id == meeting.counselor_id)
    )
    google_acc = result.scalars().first()

    if google_acc and google_acc.is_active and meeting.calendar_event_id and not meeting.calendar_event_id.startswith("mock-"):
        try:
            service = get_calendar_service(google_acc.encrypted_refresh_token)
            delete_calendar_event(service, meeting.calendar_event_id)
        except Exception as e:
            logger.error(f"Failed to delete Google Calendar event: {str(e)}")

    meeting.status = MeetingStatus.cancelled
    await db.commit()
    return {"message": "Meeting cancelled."}

@router.get("/counselors", response_model=list[UserOut])
async def list_counselors(
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Returns list of available counselors.
    If no users have linked google accounts, returns all users except the current one as fallbacks.
    """
    # 1. Try to find counselors with active linked Google accounts
    result = await db.execute(
        select(User)
        .join(CounselorGoogleAccount, User.id == CounselorGoogleAccount.user_id)
        .where(CounselorGoogleAccount.is_active == True)
    )
    counselors = result.scalars().all()
    
    # 2. Fallback: return all other active users in system so dropdown has options
    if not counselors:
        result = await db.execute(
            select(User)
            .where(User.id != current_user.id)
            .where(User.is_active == True)
        )
        counselors = result.scalars().all()
        
    return counselors
