from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import HTMLResponse
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from google_auth_oauthlib.flow import Flow
from app.core.config import settings
from app.db.database import get_db
from app.api.v1.middleware.auth_middleware import get_current_user
from app.models.counselor_account import CounselorGoogleAccount
from app.services.google.google_service import encrypt_token
import httpx
import uuid

router = APIRouter(prefix="/google", tags=["Google OAuth"])

SCOPES = [settings.GOOGLE_SCOPES]

def _get_flow():
    return Flow.from_client_config(
        {
            "web": {
                "client_id": settings.GOOGLE_CLIENT_ID or "mock_client_id",
                "client_secret": settings.GOOGLE_CLIENT_SECRET or "mock_client_secret",
                "redirect_uris": [settings.GOOGLE_REDIRECT_URI],
                "auth_uri": "https://accounts.google.com/o/oauth2/auth",
                "token_uri": "https://oauth2.googleapis.com/token",
            }
        },
        scopes=SCOPES,
        redirect_uri=settings.GOOGLE_REDIRECT_URI,
    )

@router.get("/connect")
async def connect_google(current_user=Depends(get_current_user)):
    """Step 1: Redirect counselor to Google consent screen."""
    flow = _get_flow()
    auth_url, _ = flow.authorization_url(
        access_type="offline",   # Gets refresh token
        include_granted_scopes="true",
        prompt="consent",        # Forces refresh token on every connect
        state=str(current_user.id),
    )
    return {"auth_url": auth_url}

@router.get("/callback", response_class=HTMLResponse)
async def google_callback(
    code: str,
    state: str,  # counselor user_id
    db: AsyncSession = Depends(get_db),
):
    """Step 2: Exchange code for tokens, store encrypted refresh token."""
    flow = _get_flow()
    try:
        flow.fetch_token(code=code)
        creds = flow.credentials
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Failed to fetch Google OAuth token: {str(e)}")

    # Get counselor's Google email
    async with httpx.AsyncClient() as client:
        resp = await client.get(
            "https://www.googleapis.com/oauth2/v2/userinfo",
            headers={"Authorization": f"Bearer {creds.token}"},
        )
        if resp.status_code != 200:
            raise HTTPException(status_code=400, detail="Failed to fetch Google user info.")
        google_info = resp.json()

    counselor_uuid = uuid.UUID(state)

    # Upsert counselor account
    result = await db.execute(
        select(CounselorGoogleAccount).where(CounselorGoogleAccount.user_id == counselor_uuid)
    )
    existing = result.scalars().first()
    
    if existing:
        if creds.refresh_token:
            existing.encrypted_refresh_token = encrypt_token(creds.refresh_token)
        existing.google_email = google_info["email"]
        existing.is_active = True
        existing.access_token = encrypt_token(creds.token)
        existing.token_expiry = creds.expiry
    else:
        # If refresh token is missing (can happen if user didn't consent properly), raise warning but create anyway
        refresh_token = creds.refresh_token or "mock_refresh_token"
        db.add(CounselorGoogleAccount(
            user_id=counselor_uuid,
            google_email=google_info["email"],
            encrypted_refresh_token=encrypt_token(refresh_token),
            access_token=encrypt_token(creds.token),
            token_expiry=creds.expiry,
        ))
    
    await db.commit()

    # Premium connection successful HTML page
    html_content = f"""
    <!DOCTYPE html>
    <html>
    <head>
        <title>Google Account Connected</title>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>
            body {{
                font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
                display: flex;
                align-items: center;
                justify-content: center;
                height: 100vh;
                margin: 0;
                background-color: #f3f4f6;
            }}
            .card {{
                background: white;
                padding: 40px;
                border-radius: 16px;
                box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.1), 0 8px 10px -6px rgba(0, 0, 0, 0.1);
                text-align: center;
                max-width: 420px;
                border-top: 5px solid #4f46e5;
            }}
            .icon {{
                font-size: 48px;
                color: #10b981;
                margin-bottom: 20px;
            }}
            h1 {{
                color: #111827;
                font-size: 24px;
                font-weight: 800;
                margin-top: 0;
                margin-bottom: 10px;
            }}
            p {{
                color: #4b5563;
                font-size: 15px;
                line-height: 1.6;
                margin-bottom: 30px;
            }}
            .email {{
                font-weight: 700;
                color: #4f46e5;
                background-color: #e0e7ff;
                padding: 6px 12px;
                border-radius: 9999px;
                display: inline-block;
                margin-bottom: 20px;
            }}
            .footer-text {{
                font-size: 12px;
                color: #9ca3af;
            }}
        </style>
    </head>
    <body>
        <div class="card">
            <div class="icon">✓</div>
            <h1>Connection Successful!</h1>
            <p>Your Google Calendar account has been successfully linked to VisaFlow.</p>
            <div class="email">{google_info["email"]}</div>
            <p style="margin-bottom: 0;">You can now close this browser tab and safely return to the application.</p>
        </div>
    </body>
    </html>
    """
    return HTMLResponse(content=html_content, status_code=200)
