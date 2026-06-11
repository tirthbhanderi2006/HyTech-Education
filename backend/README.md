# HyTech Visa Copilot — Backend API

FastAPI backend for the HyTech Visa Preparation & Compliance Platform.

## Quick Start

```bash
# 1. Clone and setup
cp .env.example .env
# Fill in your DATABASE_URL, OPENAI_API_KEY, AWS keys

# 2. Docker (recommended)
docker-compose up -d

# 3. Run migrations
alembic upgrade head

# 4. Seed visa programs
python scripts/seed_visa_programs.py

# 5. API docs
open http://localhost:8000/docs
```

## Architecture
- **FastAPI** — async REST API
- **PostgreSQL** — primary data store (via SQLAlchemy async)
- **Redis** — caching + Celery task queue
- **AWS S3** — document file storage
- **OpenAI GPT-4o** — eligibility, risk, checklist AI agents
- **Firebase FCM** — push notifications to Flutter app
- **Tesseract OCR** — document text extraction

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| POST | /api/v1/auth/register | Register user |
| POST | /api/v1/auth/login | Login |
| POST | /api/v1/cases/ | Create visa case |
| GET  | /api/v1/cases/ | List user cases |
| POST | /api/v1/cases/{id}/eligibility | Run eligibility AI |
| POST | /api/v1/cases/{id}/risk | Run risk analysis AI |
| POST | /api/v1/documents/upload | Upload + OCR + validate document |
| GET  | /api/v1/documents/case/{id} | List case documents |
| GET  | /api/v1/documents/{id}/validation | Get validation result |
| GET  | /api/v1/notifications/ | List notifications |
| PATCH| /api/v1/notifications/{id}/read | Mark as read |

## Documents Required Per Visa Type

| Visa Type | Mandatory Documents |
|-----------|-------------------|
| Student | Passport, Admission Letter, Bank Statement (6mo), Language Score, Photo |
| Work | Passport, Employment Letter, Degree, Bank Statement, Tax Returns, Police Clearance |
| Tourist | Passport, Bank Statement (3mo), Photo, Travel Insurance |
| Family | Passport, Invitation Letter, Sponsor Bank Statement, Relationship Proof |
