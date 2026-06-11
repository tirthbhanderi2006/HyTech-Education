from google.oauth2.credentials import Credentials
from google.auth.transport.requests import Request
from googleapiclient.discovery import build
from cryptography.fernet import Fernet
from datetime import datetime
from app.core.config import settings

# A fallback key generated using Fernet.generate_key().decode()
# This is a safe fallback in case FERNET_KEY is not set in settings yet.
DEFAULT_FERNET_KEY = "3Lg-j8Z2r5k2bM3aV8j7c4vB6n3m2qW1e4t5y6u7i8o="

def _fernet() -> Fernet:
    key = settings.FERNET_KEY or DEFAULT_FERNET_KEY
    try:
        return Fernet(key.encode())
    except Exception:
        # Fallback to default if key is not URL-safe base64-encoded 32-byte
        return Fernet(DEFAULT_FERNET_KEY.encode())

def encrypt_token(token: str) -> str:
    if not token:
        return ""
    return _fernet().encrypt(token.encode()).decode()

def decrypt_token(token: str) -> str:
    if not token:
        return ""
    return _fernet().decrypt(token.encode()).decode()

def _get_credentials(encrypted_refresh_token: str) -> Credentials:
    """Shared credential builder used by both Calendar and Drive services."""
    refresh_token = decrypt_token(encrypted_refresh_token)
    creds = Credentials(
        token=None,
        refresh_token=refresh_token,
        token_uri="https://oauth2.googleapis.com/token",
        client_id=settings.GOOGLE_CLIENT_ID,
        client_secret=settings.GOOGLE_CLIENT_SECRET,
        scopes=settings.GOOGLE_SCOPES.split(" "),
    )
    if not creds.valid:
        creds.refresh(Request())
    return creds

def get_calendar_service(encrypted_refresh_token: str):
    """Returns authenticated Google Calendar v3 service."""
    return build("calendar", "v3", credentials=_get_credentials(encrypted_refresh_token))

def get_drive_service(encrypted_refresh_token: str):
    """Returns authenticated Google Drive v3 service."""
    return build("drive", "v3", credentials=_get_credentials(encrypted_refresh_token))

# ── Calendar ──────────────────────────────────────────────────────────────────

def create_meeting_event(
    service,
    candidate_email: str,
    counselor_email: str,
    title: str,
    start_time: datetime,
    end_time: datetime,
    notes: str | None = None,
    timezone: str = "Asia/Kolkata",
) -> dict:
    """Creates a Calendar event with Google Meet conferencing enabled."""
    event_body = {
        "summary": title,
        "description": notes or "HyTech Visa Copilot — Counseling Session",
        "start": {
            "dateTime": start_time.isoformat(),
            "timeZone": timezone,
        },
        "end": {
            "dateTime": end_time.isoformat(),
            "timeZone": timezone,
        },
        "attendees": [
            {"email": counselor_email},
            {"email": candidate_email},
        ],
        "conferenceData": {
            "createRequest": {
                "requestId": f"hytech-{start_time.timestamp()}",
                "conferenceSolutionKey": {"type": "hangoutsMeet"},
            }
        },
        "reminders": {
            "useDefault": False,
            "overrides": [
                {"method": "email", "minutes": 60},
                {"method": "popup", "minutes": 15},
            ],
        },
    }

    created_event = (
        service.events()
        .insert(
            calendarId="primary",
            body=event_body,
            conferenceDataVersion=1,   # Required to generate Meet link
            sendUpdates="all",         # Sends email invites to attendees
        )
        .execute()
    )
    return created_event

def delete_calendar_event(service, event_id: str):
    """Deletes the calendar event on counselor's calendar."""
    service.events().delete(
        calendarId="primary",
        eventId=event_id,
        sendUpdates="all",
    ).execute()

def update_calendar_event(
    service,
    event_id: str,
    start_time: datetime,
    end_time: datetime,
    timezone: str = "Asia/Kolkata"
) -> dict:
    """Reschedules the calendar event."""
    event = service.events().get(calendarId="primary", eventId=event_id).execute()
    event["start"] = {"dateTime": start_time.isoformat(), "timeZone": timezone}
    event["end"] = {"dateTime": end_time.isoformat(), "timeZone": timezone}
    return service.events().update(
        calendarId="primary",
        eventId=event_id,
        body=event,
        sendUpdates="all"
    ).execute()

# ── Drive ──────────────────────────────────────────────────────────────────────

def get_or_create_candidate_folder(
    service,
    candidate_name: str,
    parent_folder_id: str | None = None,
) -> str:
    """
    Looks for an existing folder named after the candidate.
    Creates one if it doesn't exist. Returns folder ID.
    """
    query = (
        f"name='{candidate_name} — Visa Docs' "
        f"and mimeType='application/vnd.google-apps.folder' "
        f"and trashed=false"
    )
    results = service.files().list(q=query, fields="files(id, name)").execute()
    files = results.get("files", [])
    if files:
        return files[0]["id"]

    metadata = {
        "name": f"{candidate_name} — Visa Docs",
        "mimeType": "application/vnd.google-apps.folder",
    }
    if parent_folder_id:
        metadata["parents"] = [parent_folder_id]

    folder = service.files().create(body=metadata, fields="id").execute()
    return folder["id"]

def upload_file_to_drive(
    service,
    file_bytes: bytes,
    filename: str,
    mime_type: str,
    document_type: str,
    candidate_name: str,
    folder_id: str | None = None,
) -> dict:
    """
    Uploads a document to Google Drive.
    Returns dict with 'id' (drive_file_id) and 'webViewLink' (drive_view_link).
    """
    import tempfile
    import os
    from googleapiclient.http import MediaFileUpload

    display_name = f"{candidate_name} — {document_type} — {filename}"

    # Write bytes to temp file
    with tempfile.NamedTemporaryFile(delete=False, suffix=os.path.splitext(filename)[1]) as tmp:
        tmp.write(file_bytes)
        tmp_path = tmp.name

    try:
        file_metadata = {"name": display_name}
        if folder_id:
            file_metadata["parents"] = [folder_id]

        media = MediaFileUpload(tmp_path, mimetype=mime_type, resumable=True)
        uploaded = (
            service.files()
            .create(
                body=file_metadata,
                media_body=media,
                fields="id, webViewLink, name, size",
            )
            .execute()
        )

        # Grant read access to anyone with the link
        service.permissions().create(
            fileId=uploaded["id"],
            body={"role": "reader", "type": "anyone"},
        ).execute()

        return uploaded
    finally:
        try:
            os.unlink(tmp_path)
        except Exception:
            pass
            
def delete_file_from_drive(service, file_id: str):
    """Permanently deletes a file from Drive."""
    service.files().delete(fileId=file_id).execute()
