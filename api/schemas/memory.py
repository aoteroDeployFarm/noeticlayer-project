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
