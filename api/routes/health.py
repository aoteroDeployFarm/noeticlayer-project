from __future__ import annotations

from datetime import datetime, timezone

from fastapi import APIRouter

router = APIRouter(tags=["health"])


@router.get("/health")
def health_check() -> dict[str, str]:
    return {
        "status": "ok",
        "service": "noeticlayer-runtime-api",
        "version": "0.2.0",
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }