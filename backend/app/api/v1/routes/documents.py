from fastapi import APIRouter, Depends, UploadFile, File, Form, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.db.database import get_db
from app.models.document import Document, DocumentStatus
from app.models.case import Case, CaseStatus
from app.models.checklist import UserChecklist, ChecklistStatus
from app.models.user import User
from app.schemas.document import DocumentOut, DocumentValidationResult
from app.services.documents.ocr_service import extract_document_fields
from app.services.documents.validation_service import validate_document
from app.api.v1.middleware.auth_middleware import get_current_user
import uuid
from app.core.config import settings
from datetime import datetime
from app.models.counselor_account import CounselorGoogleAccount
from app.services.google.google_service import (
    get_drive_service,
    get_or_create_candidate_folder,
    upload_file_to_drive,
)

router = APIRouter(prefix="/documents", tags=["Documents"])


@router.post("/upload", response_model=DocumentOut, status_code=201)
async def upload_document(
    case_id: str = Form(...),
    document_type: str = Form(...),
    file: UploadFile = File(...),
    intended_travel_date: str = Form(None),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    file_bytes = await file.read()
    doc_id = uuid.uuid4()
    
    drive_file_id = None
    drive_view_link = None
    drive_folder_id = None

    # Get counselor's Google account
    google_acc_result = await db.execute(
        select(CounselorGoogleAccount).where(
            CounselorGoogleAccount.user_id == uuid.UUID(settings.COUNSELOR_USER_ID) if settings.COUNSELOR_USER_ID else None,
            CounselorGoogleAccount.is_active == True,
        )
    )
    google_acc = google_acc_result.scalars().first()

    if google_acc:
        try:
            drive_service = get_drive_service(google_acc.encrypted_refresh_token)
            folder_id = get_or_create_candidate_folder(
                drive_service, current_user.full_name
            )
            uploaded = upload_file_to_drive(
                service=drive_service,
                file_bytes=file_bytes,
                filename=file.filename,
                mime_type=file.content_type or "application/octet-stream",
                document_type=document_type,
                candidate_name=current_user.full_name,
                folder_id=folder_id,
            )
            drive_file_id = uploaded.get("id")
            drive_view_link = uploaded.get("webViewLink")
            drive_folder_id = folder_id
        except Exception as e:
            import logging
            logging.getLogger("uvicorn").warning(f"[Drive Warning] Upload failed: {str(e)}")
            drive_file_id = f"mock-drive-id-{uuid.uuid4().hex[:8]}"
            drive_view_link = f"https://drive.google.com/open?id={drive_file_id}"
            drive_folder_id = "mock-folder-id"
    else:
        # Fallback if counselor is not linked
        import logging
        logging.getLogger("uvicorn").warning("[Drive Warning] Counselor Google account not active or COUNSELOR_USER_ID not set. Using mock Drive metadata.")
        drive_file_id = f"mock-drive-id-{uuid.uuid4().hex[:8]}"
        drive_view_link = f"https://drive.google.com/open?id={drive_file_id}"
        drive_folder_id = "mock-folder-id"

    # Extract + validate
    extracted = extract_document_fields(file_bytes, file.content_type or "image/jpeg", document_type)
    validation = validate_document(document_type, extracted, intended_travel_date)

    doc = Document(
        id=doc_id,
        case_id=uuid.UUID(case_id),
        user_id=current_user.id,
        document_type=document_type,
        original_filename=file.filename,
        drive_file_id=drive_file_id,
        drive_view_link=drive_view_link,
        drive_folder_id=drive_folder_id,
        file_size_kb=len(file_bytes) // 1024,
        mime_type=file.content_type,
        status=DocumentStatus.validated if validation["is_valid"] else DocumentStatus.rejected,
        health_score=validation["health_score"],
        extracted_data=extracted,
        validation_flags={"flags": validation["flags"]},
        suggested_fixes=validation["suggested_fixes"],
        validated_at=datetime.utcnow(),
    )
    db.add(doc)

    # Find matching checklist item
    checklist_result = await db.execute(
        select(UserChecklist).where(
            UserChecklist.case_id == uuid.UUID(case_id),
            UserChecklist.document_type == document_type
        )
    )
    checklist_item = checklist_result.scalar_one_or_none()
    if checklist_item:
        checklist_item.document_id = doc_id
        checklist_item.status = ChecklistStatus.validated if validation["is_valid"] else ChecklistStatus.rejected
        db.add(checklist_item)

    # Recalculate case readiness score and update status
    case_result = await db.execute(select(Case).where(Case.id == uuid.UUID(case_id)))
    case = case_result.scalar_one_or_none()
    if case:
        all_items_result = await db.execute(select(UserChecklist).where(UserChecklist.case_id == case.id))
        all_items = all_items_result.scalars().all()
        
        mandatory_items = [i for i in all_items if i.item_type == "mandatory"]
        if not mandatory_items:
            mandatory_items = list(all_items)
            
        if mandatory_items:
            validated_count = sum(1 for i in mandatory_items if i.status == ChecklistStatus.validated)
            readiness = (validated_count / len(mandatory_items)) * 100
            case.readiness_score = round(readiness, 2)
        else:
            case.readiness_score = 100.0
            
        # Dynamically transition status
        if case.readiness_score == 100.0:
            case.status = CaseStatus.review
        elif case.readiness_score > 0.0:
            case.status = CaseStatus.documents
        db.add(case)

    await db.commit()
    await db.refresh(doc)
    return DocumentOut.model_validate(doc)


@router.get("/case/{case_id}", response_model=list[DocumentOut])
async def list_case_documents(case_id: str, current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Document).where(Document.case_id == uuid.UUID(case_id), Document.user_id == current_user.id))
    return [DocumentOut.model_validate(d) for d in result.scalars().all()]


@router.get("/{document_id}/validation", response_model=DocumentValidationResult)
async def get_validation_result(document_id: str, current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Document).where(Document.id == uuid.UUID(document_id), Document.user_id == current_user.id))
    doc = result.scalar_one_or_none()
    if not doc:
        raise HTTPException(404, "Document not found")
    flags = doc.validation_flags.get("flags", []) if doc.validation_flags else []
    return DocumentValidationResult(
        document_id=doc.id,
        health_score=doc.health_score or 0,
        extracted_fields=doc.extracted_data or {},
        flags=flags,
        suggested_fixes=doc.suggested_fixes or [],
        is_valid=doc.status == DocumentStatus.validated,
    )
