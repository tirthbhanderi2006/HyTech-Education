from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.v1.routes import auth, cases, documents, notifications
from app.core.config import settings

# Import all models to ensure they are registered in the SQLAlchemy Metadata registry
from app.models.user import User
from app.models.case import Case
from app.models.checklist import UserChecklist
from app.models.document import Document
from app.models.notification import Notification
from app.models.visa_program import VisaProgram
from app.models.audit_log import AuditLog

app = FastAPI(
    title=settings.APP_NAME,
    version="1.0.0",
    description="AI-Powered Visa Preparation & Compliance Platform — Backend API",
    docs_url="/docs",
    redoc_url="/redoc",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router, prefix="/api/v1")
app.include_router(cases.router, prefix="/api/v1")
app.include_router(documents.router, prefix="/api/v1")
app.include_router(notifications.router, prefix="/api/v1")


@app.get("/health")
async def health():
    return {"status": "ok", "service": settings.APP_NAME}
