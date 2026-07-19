"""Seed initial visa programs into the database."""
import asyncio
import uuid
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from app.models.visa_program import VisaProgram
from app.core.config import settings

db_url = settings.DATABASE_URL
if db_url.startswith("postgresql://"):
    db_url = db_url.replace("postgresql://", "postgresql+asyncpg://", 1)
engine = create_async_engine(db_url)
Session = async_sessionmaker(engine, class_=AsyncSession)

PROGRAMS = [
    {"country_code": "GB", "visa_type": "student", "name": "UK Student Visa (Tier 4)", "processing_days_min": 15, "processing_days_max": 30, "fee_usd": 490, "complexity_score": 6.5, "success_rate": 0.82, "required_documents": ["passport","admission_letter","bank_statement","language_score_card","photo","tuberculosis_test"]},
    {"country_code": "US", "visa_type": "student", "name": "US F-1 Student Visa", "processing_days_min": 3, "processing_days_max": 60, "fee_usd": 185, "complexity_score": 7.0, "success_rate": 0.78, "required_documents": ["passport","i20","bank_statement","ds160","sevis_fee","photo"]},
    {"country_code": "CA", "visa_type": "student", "name": "Canada Study Permit", "processing_days_min": 30, "processing_days_max": 120, "fee_usd": 150, "complexity_score": 6.0, "success_rate": 0.80, "required_documents": ["passport","admission_letter","bank_statement","photo","biometrics"]},
    {"country_code": "AU", "visa_type": "student", "name": "Australia Student Visa (500)", "processing_days_min": 28, "processing_days_max": 90, "fee_usd": 620, "complexity_score": 6.5, "success_rate": 0.85, "required_documents": ["passport","coe","bank_statement","oshc","english_results"]},
    {"country_code": "DE", "visa_type": "student", "name": "Germany Student Visa", "processing_days_min": 30, "processing_days_max": 90, "fee_usd": 80, "complexity_score": 7.5, "success_rate": 0.75, "required_documents": ["passport","admission_letter","bank_statement","blocked_account","language_cert","photo"]},
    {"country_code": "JP", "visa_type": "student", "name": "Japan Student Visa (CoE required)", "processing_days_min": 30, "processing_days_max": 90, "fee_usd": 35, "complexity_score": 7.0, "success_rate": 0.88, "required_documents": ["passport","coe","admission_letter","photo"]},
]

async def seed():
    async with Session() as db:
        for p in PROGRAMS:
            prog = VisaProgram(id=uuid.uuid4(), **p)
            db.add(prog)
        await db.commit()
        print(f"Seeded {len(PROGRAMS)} visa programs.")

asyncio.run(seed())
