from pydantic import BaseModel
from uuid import UUID
from typing import Optional, List
from datetime import datetime


class CaseCreate(BaseModel):
    destination_country: str
    visa_type: str
    purpose: str
    intended_travel_date: Optional[str] = None


class CaseOut(BaseModel):
    id: UUID
    user_id: UUID
    destination_country: Optional[str]
    visa_type: Optional[str]
    purpose: Optional[str]
    status: str
    readiness_score: Optional[float]
    risk_score: Optional[float]
    eligibility_score: Optional[float]
    created_at: datetime

    class Config:
        from_attributes = True


class EligibilityResult(BaseModel):
    overall_score: float
    category: str                     # Low / Medium / High / Critical
    factors: dict
    gap_analysis: List[dict]
    recommended_actions: List[str]
    explainability: str               # LLM-generated plain language summary


class ChecklistOut(BaseModel):
    id: UUID
    case_id: UUID
    document_type: str
    item_type: str
    personalized_description: str
    requirement_detail: Optional[str] = None
    status: str
    document_id: Optional[UUID] = None
    sort_order: int
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class ChecklistUpdate(BaseModel):
    status: Optional[str] = None
    personalized_description: Optional[str] = None
    requirement_detail: Optional[str] = None

