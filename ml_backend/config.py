"""
Configuration management for ML backend.
Handles environment variables and application settings.
"""

import os
from typing import Optional
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""

    # Application
    APP_NAME: str = "NeuroScreen ML Backend"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = os.getenv("DEBUG", "false").lower() == "true"

    # Server
    HOST: str = os.getenv("HOST", "0.0.0.0")
    PORT: int = int(os.getenv("PORT", 8000))

    # Firebase
    FIREBASE_CREDENTIALS: Optional[str] = os.getenv("FIREBASE_CREDENTIALS")
    FIREBASE_DATABASE_URL: Optional[str] = os.getenv("FIREBASE_DATABASE_URL")

    # Database
    DATABASE_URL: str = os.getenv(
        "DATABASE_URL",
        "postgresql://user:password@localhost/neuroscreen_ml"
    )

    # JWT
    SECRET_KEY: str = os.getenv(
        "SECRET_KEY",
        "your-secret-key-change-in-production"
    )
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30

    # ML Model Paths
    MODEL_DIR: str = os.getenv("MODEL_DIR", "./models")
    SCALER_PATH: str = os.path.join(MODEL_DIR, "scaler.pkl")
    RISK_MODEL_PATH: str = os.path.join(MODEL_DIR, "risk_predictor.pkl")
    TREND_MODEL_PATH: str = os.path.join(MODEL_DIR, "trend_analyzer.pkl")
    ANOMALY_MODEL_PATH: str = os.path.join(MODEL_DIR, "anomaly_detector.pkl")

    # Batch Processing
    BATCH_SIZE: int = 32
    MAX_WORKERS: int = 4

    class Config:
        """Pydantic config."""
        env_file = ".env"
        case_sensitive = True


settings = Settings()
