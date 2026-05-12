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
