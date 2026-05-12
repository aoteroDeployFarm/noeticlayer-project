from core.services.embedding_provider import get_embedding_provider


def main():
    provider = get_embedding_provider()

    result = provider.embed_text(
        "NoeticLayer is persistent cognition infrastructure."
    )

    print(
        {
            "model": result.model,
            "dimensions": result.dimensions,
            "vector_preview": result.vector[:5],
        }
    )

    if result.dimensions != 1536:
        raise AssertionError(
            f"Expected 1536 dimensions, got {result.dimensions}"
        )

    print("\nOpenAI embedding provider validation passed.")


if __name__ == "__main__":
    main()