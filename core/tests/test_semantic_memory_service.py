from core.services.memory_service import (
    capture_memory,
    get_memory_chunks,
    semantic_search_memory,
)


WORKSPACE_ID = "25cbd6eb-5aca-4cef-b519-90d58b5b86e5"


def main():
    print("\n--- Capturing Chunked Semantic Memory ---")

    result = capture_memory(
        workspace_id=WORKSPACE_ID,
        memory_type="architecture_note",
        title="Chunked Semantic Memory Architecture",
        raw_content="""
        NoeticLayer stores canonical memory items separately from semantic chunks.

        The memory item represents the durable knowledge object.
        The memory chunks represent retrievable semantic units.
        Agents should retrieve precise context from chunks instead of loading entire documents.

        Chunk-level embeddings make future re-embedding easier when embedding models change.
        Workspace isolation must be enforced on both memory_items and memory_chunks.
        Semantic retrieval should return ranked chunks joined back to their parent memory items.
        """,
        metadata={
            "source": "test_semantic_memory_service",
            "test_type": "chunked_semantic_retrieval",
        },
    )

    memory_item = result["memory_item"]

    print("Memory Item:")
    print(
        {
            "id": memory_item["id"],
            "title": memory_item["title"],
            "type": memory_item["type"],
            "workspace_id": memory_item["workspace_id"],
        }
    )

    print("\n--- Chunk Validation ---")

    chunks = get_memory_chunks(memory_item_id=memory_item["id"])

    if not chunks:
        raise AssertionError("Expected memory_chunks rows, but none were created.")

    print(f"Chunk count: {len(chunks)}")

    for chunk in chunks:
        if chunk["embedding_dimensions"] != 1536:
            raise AssertionError(
                f"Unexpected embedding dimensions: {chunk['embedding_dimensions']}"
            )

        print(
            {
                "chunk_index": chunk["chunk_index"],
                "embedding_model": chunk["embedding_model"],
                "embedding_dimensions": chunk["embedding_dimensions"],
                "token_estimate": chunk["token_estimate"],
                "content_preview": chunk["content"][:120],
            }
        )

    print("\n--- Semantic Search Validation ---")

    search_results = semantic_search_memory(
        workspace_id=WORKSPACE_ID,
        query="How should agents retrieve precise memory context?",
        limit=5,
    )

    if not search_results:
        raise AssertionError("Expected semantic search results, but none were returned.")

    for row in search_results:
        if row["workspace_id"] != memory_item["workspace_id"]:
            raise AssertionError("Semantic search returned result from wrong workspace.")

        print(
            {
                "title": row["title"],
                "chunk_index": row["chunk_index"],
                "embedding_model": row["embedding_model"],
                "similarity_score": row["similarity_score"],
                "chunk_content": row["chunk_content"][:180],
            }
        )

    print("\nSemantic memory validation passed.")


if __name__ == "__main__":
    main()