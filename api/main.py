from fastapi import FastAPI

from api.routes.health import router as health_router
from api.routes.memories import router as memories_router


def create_app() -> FastAPI:
    app = FastAPI(
        title="NoeticLayer Runtime API",
        description="Network-accessible cognition infrastructure runtime for persistent semantic memory.",
        version="0.1.0",
    )

    app.include_router(health_router)
    app.include_router(memories_router)

    return app


app = create_app()
