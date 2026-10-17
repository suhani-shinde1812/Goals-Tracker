import os
from pydantic_settings import BaseSettings
from typing import List


class Settings(BaseSettings):
    APP_NAME: str = "BloomTrack API"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = False
    
    # Database
    DATABASE_URL: str = os.getenv("DATABASE_URL", "sqlite:///./bloomtrack.db")
    
    # JWT Auth
    SECRET_KEY: str = os.getenv("SECRET_KEY", "bloomtrack-production-insecure-secret-key-change-in-env-92841")
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7 days
    
    # CORS
    ALLOWED_ORIGINS: str = os.getenv(
        "ALLOWED_ORIGINS",
        "http://localhost:3000,http://localhost:8000,http://localhost:8080,http://localhost:5000,http://127.0.0.1:8000,http://127.0.0.1:3000,http://127.0.0.1:8080,https://bloomtrack.onrender.com"
    )

    @property
    def cors_origins(self) -> List[str]:
        return [origin.strip() for origin in self.ALLOWED_ORIGINS.split(",") if origin.strip()]

    model_config = {
        "env_file": ".env",
        "extra": "allow"
    }


settings = Settings()
