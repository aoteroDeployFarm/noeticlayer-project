from core.services.embedding_provider import DeterministicFakeEmbeddingProvider
from core.services.memory_service import (
    browse_recent,
    capture_memory,
    get_memory_chunks,
    semantic_search_memory,
)


WORKSPACE_ID = "25cbd6eb-5aca-4cef-b519-90d58b5b86e5"


def main():
    embedding_provider = DeterministicFakeEmbeddingProvider()

    print("\n--- Capturing Chunked Semantic Memory ---")

    result = capture_memory(
        workspace_id=WORKSPACE_ID,
        memory_type="architecture_note",
        title="Chunked Semantic Memory Architecture",
        raw_content="""
        NoeticLayer should store canonical memory items separately from semantic chunks.
        The memory item represents the durable knowledge object.
        The memory chunks represent retrievable semantic units.
        This allows agents to retrieve precise context without loading entire documents.
        Chunk-level embeddings also make it easier to re-embed content when embedding models change.
        Workspace isolation must be enforced on both memory_items and memory_chunks.
        """,
        metadata={
            "source": "manual_test",
            "phase": "semantic_memory_v0",
        },
        embedding_provider=embedding_provider,
    )

    memory_item = result["memory_item"]

    print("Memory Item:")
    print(memory_item)

    print("\nChunk Count:")
    print(result["chunk_count"])

    print("\n--- Chunks ---")
    chunks = get_memory_chunks(memory_item_id=memory_item["id"])
    for chunk in chunks:
        print(
            {
                "chunk_index": chunk["chunk_index"],
                "content": chunk["content"],
                "embedding_model": chunk["embedding_model"],
                "embedding_dimensions": chunk["embedding_dimensions"],
            }
        )

    print("\n--- Recent Memories ---")
    recent = browse_recent(workspace_id=WORKSPACE_ID, limit=5)
    for item in recent:
        print(
            {
                "id": item["id"],
                "title": item["title"],
                "type": item["type"],
                "created_at": item["created_at"],
            }
        )

    print("\n--- Semantic Search Results ---")
    results = semantic_search_memory(
        workspace_id=WORKSPACE_ID,
        query="How should agents retrieve precise memory context?",
        limit=5,
        embedding_provider=embedding_provider,
    )

    for row in results:
        print(
            {
                "title": row["title"],
                "chunk_index": row["chunk_index"],
                "similarity_score": row["similarity_score"],
                "chunk_content": row["chunk_content"],
            }
        )


if __name__ == "__main__":
    main()