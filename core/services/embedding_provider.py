from __future__ import annotations

import os
from dataclasses import dataclass
from typing import Protocol


@dataclass(frozen=True)
class EmbeddingResult:
    vector: list[float]
    model: str
    dimensions: int


class EmbeddingProvider(Protocol):
    def embed_text(self, text: str) -> EmbeddingResult:
        ...


class DeterministicFakeEmbeddingProvider:
    """
    Local deterministic embedding provider for tests and offline development.

    Produces a stable 1536-dimension vector without external API calls.
    Do not use for production semantic quality.
    """

    def __init__(self, dimensions: int = 1536, model: str = "fake-deterministic-1536"):
        self.dimensions = dimensions
        self.model = model

    def embed_text(self, text: str) -> EmbeddingResult:
        import hashlib
        import random

        digest = hashlib.sha256(text.encode("utf-8")).hexdigest()
        seed = int(digest[:16], 16)
        rng = random.Random(seed)

        vector = [rng.uniform(-1.0, 1.0) for _ in range(self.dimensions)]

        magnitude = sum(x * x for x in vector) ** 0.5
        if magnitude > 0:
            vector = [x / magnitude for x in vector]

        return EmbeddingResult(
            vector=vector,
            model=self.model,
            dimensions=self.dimensions,
        )


class OpenAIEmbeddingProvider:
    """
    OpenAI embedding provider.

    Requires:
        pip install openai

    Environment:
        OPENAI_API_KEY
        OPENAI_EMBEDDING_MODEL defaults to text-embedding-3-small
    """

    def __init__(self, model: str | None = None):
        self.model = model or os.getenv("OPENAI_EMBEDDING_MODEL", "text-embedding-3-small")

    def embed_text(self, text: str) -> EmbeddingResult:
        from openai import OpenAI

        client = OpenAI()
        response = client.embeddings.create(
            model=self.model,
            input=text,
        )

        vector = response.data[0].embedding

        return EmbeddingResult(
            vector=vector,
            model=self.model,
            dimensions=len(vector),
        )


def get_embedding_provider() -> EmbeddingProvider:
    provider = os.getenv("NOETICLAYER_EMBEDDING_PROVIDER", "fake").lower().strip()

    if provider == "openai":
        return OpenAIEmbeddingProvider()

    if provider == "fake":
        return DeterministicFakeEmbeddingProvider()

    raise ValueError(f"Unsupported embedding provider: {provider}")