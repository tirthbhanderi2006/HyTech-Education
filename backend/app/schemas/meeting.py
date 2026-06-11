from pydantic import BaseModel
from datetime import datetime
from typing import Optional
from uuid import UUID

class MeetingBookRequest(BaseModel):
    case_id: Optional[UUID] = None
    counselor_id: UUID
    start_time: datetime
    end_time: datetime
    notes: Optional[str] = None

class MeetingOut(BaseModel):
    id: UUID
    case_id: Optional[UUID]
    candidate_id: UUID
    counselor_id: UUID
    title: str
    notes: Optional[str]
    start_time: datetime
    end_time: datetime
    meet_link: Optional[str]
    status: str
    created_at: datetime

    class Config:
        from_attributes = True

class MeetingRescheduleRequest(BaseModel):
    start_time: datetime
    end_time: datetime

class MeetingCancelRequest(BaseModel):
    reason: Optional[str] = None
