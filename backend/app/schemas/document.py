from pydantic import BaseModel
from uuid import UUID
from typing import Optional, List, Dict, Any
from datetime import datetime


class DocumentOut(BaseModel):
    id: UUID
    case_id: UUID
    document_type: str
    original_filename: str
    status: str
    health_score: Optional[float]
    extracted_data: Optional[Dict[str, Any]]
    validation_flags: Optional[Dict[str, Any]]
    suggested_fixes: Optional[List[str]]
    uploaded_at: datetime
    validated_at: Optional[datetime]

    class Config:
        from_attributes = True


class DocumentValidationResult(BaseModel):
    document_id: UUID
    health_score: float
    extracted_fields: Dict[str, Any]
    flags: List[Dict[str, str]]       # [{"field": "expiry", "severity": "critical", "message": "..."}]
    suggested_fixes: List[str]
    is_valid: bool
