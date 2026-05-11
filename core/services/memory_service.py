from __future__ import annotations

import os
from typing import Any
from uuid import UUID

import psycopg
from psycopg.rows import dict_row
from pgvector.psycopg import register_vector

from core.services.chunking_service import SimpleTextChunker
from core.services.embedding_provider import EmbeddingProvider, get_embedding_provider


DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://noetic:noetic@localhost:5432/noeticlayer",
)


def _connect():
    conn = psycopg.connect(DATABASE_URL, row_factory=dict_row)
    register_vector(conn)
    return conn


def _to_vector_literal(vector: list[float]) -> str:
    return "[" + ",".join(str(x) for x in vector) + "]"


def capture_memory(
    *,
    workspace_id: str | UUID,
    memory_type: str,
    title: str | None,
    raw_content: str,
    metadata: dict[str, Any] | None = None,
    embedding_provider: EmbeddingProvider | None = None,
) -> dict[str, Any]:
    """
    Stores canonical memory item, chunks it, embeds each chunk, and persists vectors.

    memory_items = source of truth
    memory_chunks = semantic retrieval units
    """

    if not raw_content or not raw_content.strip():
        raise ValueError("raw_content cannot be empty")

    provider = embedding_provider or get_embedding_provider()
    chunker = SimpleTextChunker()

    chunks = chunker.chunk_text(raw_content)

    if not chunks:
        raise ValueError("No chunks produced from raw_content")

    with _connect() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO memory_items (
                    workspace_id,
                    type,
                    title,
                    raw_content,
                    metadata
                )
                VALUES (%s, %s, %s, %s, %s)
                RETURNING id, workspace_id, type, title, raw_content, metadata, created_at;
                """,
                (
                    str(workspace_id),
                    memory_type,
                    title,
                    raw_content,
                    metadata or {},
                ),
            )

            memory_item = cur.fetchone()

            inserted_chunks = []

            for chunk in chunks:
                embedding = provider.embed_text(chunk.content)

                cur.execute(
                    """
                    INSERT INTO memory_chunks (
                        memory_item_id,
                        workspace_id,
                        chunk_index,
                        content,
                        embedding,
                        embedding_model,
                        embedding_dimensions,
                        embedding_generated_at,
                        token_estimate
                    )
                    VALUES (
                        %s,
                        %s,
                        %s,
                        %s,
                        %s::vector,
                        %s,
                        %s,
                        now(),
                        %s
                    )
                    RETURNING
                        id,
                        memory_item_id,
                        workspace_id,
                        chunk_index,
                        content,
                        embedding_model,
                        embedding_dimensions,
                        embedding_generated_at,
                        token_estimate,
                        created_at;
                    """,
                    (
                        memory_item["id"],
                        str(workspace_id),
                        chunk.chunk_index,
                        chunk.content,
                        _to_vector_literal(embedding.vector),
                        embedding.model,
                        embedding.dimensions,
                        chunk.token_estimate,
                    ),
                )

                inserted_chunks.append(cur.fetchone())

            conn.commit()

            return {
                "memory_item": memory_item,
                "chunks": inserted_chunks,
                "chunk_count": len(inserted_chunks),
            }


def browse_recent(
    *,
    workspace_id: str | UUID,
    limit: int = 10,
) -> list[dict[str, Any]]:
    with _connect() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT
                    id,
                    workspace_id,
                    type,
                    title,
                    raw_content,
                    metadata,
                    created_at
                FROM memory_items
                WHERE workspace_id = %s
                ORDER BY created_at DESC
                LIMIT %s;
                """,
                (str(workspace_id), limit),
            )

            return list(cur.fetchall())


def search_memory(
    *,
    workspace_id: str | UUID,
    query: str,
    limit: int = 10,
) -> list[dict[str, Any]]:
    """
    Basic keyword search retained as fallback.
    """

    with _connect() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT
                    id,
                    workspace_id,
                    type,
                    title,
                    raw_content,
                    metadata,
                    created_at
                FROM memory_items
                WHERE workspace_id = %s
                  AND (
                    raw_content ILIKE %s
                    OR title ILIKE %s
                  )
                ORDER BY created_at DESC
                LIMIT %s;
                """,
                (
                    str(workspace_id),
                    f"%{query}%",
                    f"%{query}%",
                    limit,
                ),
            )

            return list(cur.fetchall())


def semantic_search_memory(
    *,
    workspace_id: str | UUID,
    query: str,
    limit: int = 10,
    embedding_provider: EmbeddingProvider | None = None,
) -> list[dict[str, Any]]:
    """
    Vector search over memory_chunks.

    Lower cosine distance means stronger match.
    similarity_score is normalized as 1 - cosine_distance.
    """

    if not query or not query.strip():
        raise ValueError("query cannot be empty")

    provider = embedding_provider or get_embedding_provider()
    query_embedding = provider.embed_text(query)

    with _connect() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT
                    mc.id AS chunk_id,
                    mc.memory_item_id,
                    mc.workspace_id,
                    mc.chunk_index,
                    mc.content AS chunk_content,
                    mc.embedding_model,
                    mc.embedding_dimensions,
                    mc.token_estimate,
                    mc.created_at AS chunk_created_at,

                    mi.type,
                    mi.title,
                    mi.raw_content,
                    mi.metadata,
                    mi.created_at AS memory_created_at,

                    (mc.embedding <=> %s::vector) AS cosine_distance,
                    (1 - (mc.embedding <=> %s::vector)) AS similarity_score
                FROM memory_chunks mc
                JOIN memory_items mi
                    ON mi.id = mc.memory_item_id
                WHERE mc.workspace_id = %s
                  AND mc.embedding IS NOT NULL
                ORDER BY mc.embedding <=> %s::vector
                LIMIT %s;
                """,
                (
                    _to_vector_literal(query_embedding.vector),
                    _to_vector_literal(query_embedding.vector),
                    str(workspace_id),
                    _to_vector_literal(query_embedding.vector),
                    limit,
                ),
            )

            return list(cur.fetchall())


def get_memory_chunks(
    *,
    memory_item_id: str | UUID,
) -> list[dict[str, Any]]:
    with _connect() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT
                    id,
                    memory_item_id,
                    workspace_id,
                    chunk_index,
                    content,
                    embedding_model,
                    embedding_dimensions,
                    embedding_generated_at,
                    token_estimate,
                    created_at
                FROM memory_chunks
                WHERE memory_item_id = %s
                ORDER BY chunk_index ASC;
                """,
                (str(memory_item_id),),
            )

            return list(cur.fetchall())