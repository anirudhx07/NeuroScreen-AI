"""Health check endpoints."""

from fastapi import APIRouter
from datetime import datetime

router = APIRouter(prefix="/health", tags=["health"])


@router.get("")
async def health_check():
    """Check API health status."""
    return {
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat()
    }


@router.get("/ready")
async def readiness_check():
    """Check if application is ready."""
    return {
        "ready": True,
        "timestamp": datetime.utcnow().isoformat()
    }
