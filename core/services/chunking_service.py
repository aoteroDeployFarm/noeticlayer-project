from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class TextChunk:
    chunk_index: int
    content: str
    token_estimate: int


class SimpleTextChunker:
    """
    Simple word-based chunker.

    This is intentionally dependency-light for the current phase.
    Later, replace with tokenizer-aware chunking.
    """

    def __init__(self, max_words: int = 220, overlap_words: int = 40):
        if max_words <= 0:
            raise ValueError("max_words must be greater than zero")

        if overlap_words < 0:
            raise ValueError("overlap_words cannot be negative")

        if overlap_words >= max_words:
            raise ValueError("overlap_words must be smaller than max_words")

        self.max_words = max_words
        self.overlap_words = overlap_words

    def chunk_text(self, text: str) -> list[TextChunk]:
        normalized = " ".join(text.split())

        if not normalized:
            return []

        words = normalized.split(" ")

        chunks: list[TextChunk] = []
        start = 0
        chunk_index = 0

        while start < len(words):
            end = min(start + self.max_words, len(words))
            chunk_words = words[start:end]
            content = " ".join(chunk_words)

            chunks.append(
                TextChunk(
                    chunk_index=chunk_index,
                    content=content,
                    token_estimate=max(1, int(len(chunk_words) * 1.3)),
                )
            )

            if end == len(words):
                break

            start = end - self.overlap_words
            chunk_index += 1

        return chunks