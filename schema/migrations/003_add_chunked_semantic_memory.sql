BEGIN;

-- ============================================================================
-- memory_chunks
--
-- Semantic retrieval units derived from canonical memory_items.
--
-- Architecture:
--
-- memory_items  = durable canonical memory object
-- memory_chunks = retrievable semantic units
--
-- This separation enables:
-- - fine-grained semantic retrieval
-- - future re-embedding
-- - chunk-level ranking
-- - MCP context packaging
-- - scalable cognition retrieval
-- ============================================================================

CREATE TABLE IF NOT EXISTS memory_chunks (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    memory_item_id uuid NOT NULL
        REFERENCES memory_items(id)
        ON DELETE CASCADE,

    workspace_id uuid NOT NULL
        REFERENCES workspaces(id)
        ON DELETE CASCADE,

    chunk_index integer NOT NULL,

    content text NOT NULL,

    embedding vector(1536),

    embedding_model text,

    embedding_dimensions integer,

    embedding_generated_at timestamptz,

    token_estimate integer,

    metadata jsonb NOT NULL DEFAULT '{}'::jsonb,

    created_at timestamptz NOT NULL DEFAULT now(),

    UNIQUE(memory_item_id, chunk_index)
);

-- ============================================================================
-- Indexes
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_memory_chunks_workspace_id
ON memory_chunks(workspace_id);

CREATE INDEX IF NOT EXISTS idx_memory_chunks_memory_item_id
ON memory_chunks(memory_item_id);

CREATE INDEX IF NOT EXISTS idx_memory_chunks_created_at
ON memory_chunks(created_at DESC);

-- ============================================================================
-- HNSW vector index for cosine similarity search
--
-- pgvector recommendation:
-- HNSW provides strong semantic retrieval performance with lower latency.
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_memory_chunks_embedding_hnsw
ON memory_chunks
USING hnsw (embedding vector_cosine_ops);

-- ============================================================================
-- Expand memory_items metadata support
-- ============================================================================

ALTER TABLE memory_items
ADD COLUMN IF NOT EXISTS metadata jsonb NOT NULL DEFAULT '{}'::jsonb;

-- ============================================================================
-- Future-proofing for embedding lifecycle management
-- ============================================================================

ALTER TABLE memory_items
ADD COLUMN IF NOT EXISTS embedding_status text
DEFAULT 'pending';

ALTER TABLE memory_items
ADD COLUMN IF NOT EXISTS embedding_updated_at timestamptz;

-- ============================================================================
-- Optional hardening
--
-- Uncomment ONLY after confirming all existing rows contain workspace_id.
-- ============================================================================

-- ALTER TABLE memory_items
-- ALTER COLUMN workspace_id SET NOT NULL;

COMMIT;