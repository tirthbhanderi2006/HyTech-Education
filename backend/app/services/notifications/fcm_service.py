import firebase_admin
from firebase_admin import credentials, messaging
from app.core.config import settings
import os

_initialized = False


def _init_firebase():
    global _initialized
    if not _initialized and os.path.exists(settings.FIREBASE_CREDENTIALS_PATH):
        cred = credentials.Certificate(settings.FIREBASE_CREDENTIALS_PATH)
        firebase_admin.initialize_app(cred)
        _initialized = True


def send_push_notification(fcm_token: str, title: str, body: str, data: dict = None) -> bool:
    _init_firebase()
    try:
        message = messaging.Message(
            notification=messaging.Notification(title=title, body=body),
            data={str(k): str(v) for k, v in (data or {}).items()},
            token=fcm_token,
        )
        messaging.send(message)
        return True
    except Exception as e:
        print(f"FCM error: {e}")
        return False
