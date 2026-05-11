from core.services.embedding_provider import DeterministicFakeEmbeddingProvider
from core.services.memory_service import (
    browse_recent,
    capture_memory,
    search_memory,
)


WORKSPACE_ID = "25cbd6eb-5aca-4cef-b519-90d58b5b86e5"


def main():
    embedding_provider = DeterministicFakeEmbeddingProvider()

    print("\n--- Memory Capture Result ---")

    result = capture_memory(
        workspace_id=WORKSPACE_ID,
        memory_type="business_idea",
        title="Initial Business Idea",
        raw_content="NoeticLayer is a persistent cognition infrastructure platform.",
        metadata={
            "source": "test_memory_service",
        },
        embedding_provider=embedding_provider,
    )

    print(result["memory_item"])

    print("\n--- Recent Memories ---")

    recent = browse_recent(
        workspace_id=WORKSPACE_ID,
        limit=5,
    )

    for item in recent:
        print(
            {
                "id": item["id"],
                "title": item["title"],
                "type": item["type"],
                "created_at": item["created_at"],
            }
        )

    print("\n--- Search Results ---")

    results = search_memory(
        workspace_id=WORKSPACE_ID,
        query="persistent cognition",
        limit=5,
    )

    for item in results:
        print(
            {
                "id": item["id"],
                "title": item["title"],
                "type": item["type"],
                "raw_content": item["raw_content"],
            }
        )


if __name__ == "__main__":
    main()