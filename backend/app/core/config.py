from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    APP_NAME: str = "HyTech Visa Copilot"
    APP_ENV: str = "development"
    SECRET_KEY: str
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 1440
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30

    DATABASE_URL: str
    SYNC_DATABASE_URL: str
    REDIS_URL: str = "redis://localhost:6379/0"

    COUNSELOR_USER_ID: str = ""

    OPENAI_API_KEY: str
    OPENAI_MODEL: str = "gpt-4o"

    # Groq API settings
    GROQ_API_KEY: str | None = None
    GROQ_API_BASE: str = "https://api.groq.com/openai/v1"
    GROQ_MODEL: str = "llama-3.3-70b-versatile"

    FIREBASE_CREDENTIALS_PATH: str = "./firebase-credentials.json"
    TESSERACT_CMD: str = "/usr/bin/tesseract"

    GOOGLE_CLIENT_ID: str = ""
    GOOGLE_CLIENT_SECRET: str = ""
    GOOGLE_REDIRECT_URI: str = "http://localhost:8000/api/v1/google/callback"
    GOOGLE_SCOPES: str = "https://www.googleapis.com/auth/calendar"
    FERNET_KEY: str = ""

    class Config:
        env_file = ".env"


@lru_cache
def get_settings() -> Settings:
    return Settings()

settings = get_settings()
