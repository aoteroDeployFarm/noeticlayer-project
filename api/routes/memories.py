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
