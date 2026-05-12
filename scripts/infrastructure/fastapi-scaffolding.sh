#!/usr/bin/env bash
set -euo pipefail

# NoeticLayer FastAPI Runtime Layer Scaffold
# Intended usage:
#   cd <repo-root>
#   bash ./scripts/infrastructure/fastapi-scaffolding.sh
#
# Or, from ./scripts/infrastructure:
#   bash ./fastapi-scaffolding.sh
#
# The script resolves the repository root automatically from either location.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "${SCRIPT_DIR}/../../requirements.txt" ]]; then
  REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
elif [[ -f "${PWD}/requirements.txt" ]]; then
  REPO_ROOT="${PWD}"
else
  echo "ERROR: Could not resolve repository root. Run from repo root or ./scripts/infrastructure." >&2
  exit 1
fi

cd "${REPO_ROOT}"

echo "Scaffolding NoeticLayer FastAPI runtime layer in: ${REPO_ROOT}"

backup_if_exists() {
  local file_path="$1"
  if [[ -f "${file_path}" ]]; then
    local backup_path="${file_path}.bak.$(date +%Y%m%d%H%M%S)"
    cp "${file_path}" "${backup_path}"
    echo "Backed up ${file_path} -> ${backup_path}"
  fi
}

write_file() {
  local file_path="$1"
  backup_if_exists "${file_path}"
  mkdir -p "$(dirname "${file_path}")"
  cat > "${file_path}"
  echo "Wrote ${file_path}"
}

mkdir -p api/routes api/schemas api/services

# Package markers
touch api/__init__.py
touch api/routes/__init__.py
touch api/schemas/__init__.py
touch api/services/__init__.py

write_file api/main.py <<'PY'
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
PY

write_file api/dependencies.py <<'PY'
from api.services.memory_api_service import MemoryAPIService


def get_memory_api_service() -> MemoryAPIService:
    return MemoryAPIService()
PY

write_file api/routes/health.py <<'PY'
from fastapi import APIRouter

router = APIRouter(tags=["health"])


@router.get("/health")
def health_check() -> dict[str, str]:
    return {
        "status": "ok",
        "service": "noeticlayer-runtime-api",
    }
PY

write_file api/routes/memories.py <<'PY'
from fastapi import APIRouter, Depends, Query

from api.dependencies import get_memory_api_service
from api.schemas.memory import (
    CaptureMemoryRequest,
    CaptureMemoryResponse,
    RecentMemoryResponse,
    SemanticSearchResponse,
)
from api.services.memory_api_service import MemoryAPIService

router = APIRouter(prefix="/memories", tags=["memories"])


@router.post("", response_model=CaptureMemoryResponse)
def create_memory(
    request: CaptureMemoryRequest,
    service: MemoryAPIService = Depends(get_memory_api_service),
) -> CaptureMemoryResponse:
    return service.capture_memory(request)


@router.get("/recent", response_model=list[RecentMemoryResponse])
def get_recent_memories(
    workspace_id: str = Query(..., description="Workspace isolation boundary."),
    limit: int = Query(10, ge=1, le=100),
    service: MemoryAPIService = Depends(get_memory_api_service),
) -> list[RecentMemoryResponse]:
    return service.get_recent_memories(
        workspace_id=workspace_id,
        limit=limit,
    )


@router.get("/search", response_model=list[SemanticSearchResponse])
def search_memories(
    workspace_id: str = Query(..., description="Workspace isolation boundary."),
    query: str = Query(..., min_length=1),
    limit: int = Query(10, ge=1, le=100),
    embedding_model: str | None = Query(
        None,
        description="Optional override. Defaults to active embedding provider model.",
    ),
    service: MemoryAPIService = Depends(get_memory_api_service),
) -> list[SemanticSearchResponse]:
    return service.search_memories(
        workspace_id=workspace_id,
        query=query,
        limit=limit,
        embedding_model=embedding_model,
    )
PY

write_file api/schemas/memory.py <<'PY'
from datetime import datetime
from typing import Any
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class CaptureMemoryRequest(BaseModel):
    workspace_id: UUID | str = Field(..., description="Workspace isolation boundary.")
    memory_type: str = Field(default="note", min_length=1, max_length=64)
    title: str | None = Field(default=None, max_length=256)
    raw_content: str = Field(..., min_length=1)
    metadata: dict[str, Any] = Field(default_factory=dict)


class MemoryItemResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID | str
    workspace_id: UUID | str
    type: str
    title: str | None = None
    raw_content: str
    metadata: dict[str, Any] = Field(default_factory=dict)
    created_at: datetime


class MemoryChunkResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID | str
    memory_item_id: UUID | str
    workspace_id: UUID | str
    chunk_index: int
    content: str
    embedding_model: str
    embedding_dimensions: int
    token_estimate: int | None = None
    metadata: dict[str, Any] = Field(default_factory=dict)
    created_at: datetime


class CaptureMemoryResponse(BaseModel):
    memory_item: MemoryItemResponse
    chunks: list[MemoryChunkResponse]
    chunk_count: int


class RecentMemoryResponse(MemoryItemResponse):
    pass


class SemanticSearchResponse(BaseModel):
    chunk_id: UUID | str
    memory_item_id: UUID | str
    workspace_id: UUID | str
    chunk_index: int
    chunk_content: str
    embedding_model: str
    embedding_dimensions: int
    token_estimate: int | None = None
    chunk_created_at: datetime

    type: str
    title: str | None = None
    raw_content: str
    metadata: dict[str, Any] = Field(default_factory=dict)
    memory_created_at: datetime

    cosine_distance: float
    similarity_score: float
PY

write_file api/services/memory_api_service.py <<'PY'
from typing import Any

from fastapi import HTTPException, status

from api.schemas.memory import (
    CaptureMemoryRequest,
    CaptureMemoryResponse,
    RecentMemoryResponse,
    SemanticSearchResponse,
)
from core.services.memory_service import (
    browse_recent,
    capture_memory,
    semantic_search_memory,
)


class MemoryAPIService:
    """
    Thin API-facing service boundary.

    This layer intentionally does not own chunking, embedding, persistence,
    or vector ranking. Those remain in core.services.memory_service.

    Responsibilities:
    - API input normalization
    - API-safe error translation
    - response shaping
    - future auth / async / MCP-compatible seam
    """

    def capture_memory(self, request: CaptureMemoryRequest) -> CaptureMemoryResponse:
        try:
            result = capture_memory(
                workspace_id=request.workspace_id,
                memory_type=request.memory_type,
                title=request.title,
                raw_content=request.raw_content,
                metadata=request.metadata,
            )
            return CaptureMemoryResponse(**result)

        except ValueError as exc:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=str(exc),
            ) from exc

        except Exception as exc:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to capture memory.",
            ) from exc

    def get_recent_memories(
        self,
        *,
        workspace_id: str,
        limit: int,
    ) -> list[RecentMemoryResponse]:
        try:
            rows = browse_recent(
                workspace_id=workspace_id,
                limit=limit,
            )
            return [RecentMemoryResponse(**row) for row in rows]

        except Exception as exc:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to fetch recent memories.",
            ) from exc

    def search_memories(
        self,
        *,
        workspace_id: str,
        query: str,
        limit: int,
        embedding_model: str | None = None,
    ) -> list[SemanticSearchResponse]:
        try:
            rows: list[dict[str, Any]] = semantic_search_memory(
                workspace_id=workspace_id,
                query=query,
                limit=limit,
                embedding_model=embedding_model,
            )
            return [SemanticSearchResponse(**row) for row in rows]

        except ValueError as exc:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=str(exc),
            ) from exc

        except Exception as exc:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to search memories.",
            ) from exc
PY

# Requirements update. Preserve existing ordering and append missing packages.
if [[ ! -f requirements.txt ]]; then
  touch requirements.txt
fi

for dependency in "fastapi" "uvicorn[standard]" "pydantic"; do
  if ! grep -Fxq "${dependency}" requirements.txt; then
    echo "${dependency}" >> requirements.txt
    echo "Added ${dependency} to requirements.txt"
  else
    echo "requirements.txt already contains ${dependency}"
  fi
done

echo ""
echo "FastAPI scaffold complete."
echo ""
echo "Next commands:"
echo "  source .venv/bin/activate"
echo "  pip install -r requirements.txt"
echo "  uvicorn api.main:app --host 0.0.0.0 --port 8000 --reload"
echo ""
echo "Validation:"
echo "  curl http://localhost:8000/health"
echo "  curl \"http://localhost:8000/memories/recent?workspace_id=00000000-0000-0000-0000-000000000001&limit=5\""
