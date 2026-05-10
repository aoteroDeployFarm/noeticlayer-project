#!/usr/bin/env bash
set -euo pipefail

echo "Filling NoeticLayer scaffold files..."

write_if_missing() {
  local path="$1"
  local content="$2"

  if [ -f "$path" ]; then
    echo "exists:  $path"
  else
    mkdir -p "$(dirname "$path")"
    printf "%s\n" "$content" > "$path"
    echo "created: $path"
  fi
}

write_if_missing "README.md" '# NoeticLayer

Persistent cognition infrastructure for agents, models, and business operations.

## Purpose

NoeticLayer is the cognitive operating layer for Precision Neural Systems LLC.

It provides:

- persistent semantic memory
- business/domain scoped context
- MCP-accessible tools
- role-based agents
- task assignments
- knowledge ingestion
- governed operational intelligence
'

write_if_missing ".env.example" 'APP_ENV=local
APP_NAME=noeticlayer

DATABASE_URL=postgresql://noetic:noetic@localhost:5432/noeticlayer

OPENAI_API_KEY=
GOOGLE_APPLICATION_CREDENTIALS=

EMBEDDING_PROVIDER=openai
EMBEDDING_MODEL=text-embedding-3-small
'

write_if_missing ".gitignore" '# Python
__pycache__/
*.py[cod]
.venv/
venv/
.env

# Node
node_modules/

# OS
.DS_Store

# Logs
*.log
'

write_if_missing "docker-compose.yml" 'services:
  postgres:
    image: pgvector/pgvector:pg16
    container_name: noeticlayer-postgres
    environment:
      POSTGRES_USER: noetic
      POSTGRES_PASSWORD: noetic
      POSTGRES_DB: noeticlayer
    ports:
      - "5432:5432"
'

write_if_missing "pyproject.toml" '[project]
name = "noeticlayer"
version = "0.1.0"
description = "Persistent cognition infrastructure for agents and business operations."
requires-python = ">=3.11"
'

write_if_missing "docs/architecture/system-overview.md" '# NoeticLayer System Overview

## Core Principle

Memory first. Agents second. Autonomy last.
'

write_if_missing "schema/data_contracts/memory-item.md" '# Memory Item Contract

## Purpose

A memory item is the base unit of stored cognition.
'

write_if_missing "schema/migrations/001_initial_schema.sql" 'CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS workspaces (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS memory_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type TEXT NOT NULL,
    title TEXT,
    raw_content TEXT NOT NULL,
    embedding vector(1536),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
'

write_if_missing "core/README.md" '# Core

Memory engine and semantic retrieval.
'

write_if_missing "mcp/README.md" '# MCP

Model Context Protocol services.
'

write_if_missing "runtime/README.md" '# Runtime

Task execution and orchestration.
'

write_if_missing "agents/README.md" '# Agents

Specialized role-based agents.
'

write_if_missing "sync/README.md" '# Sync

Ingestion and external connectors.
'

write_if_missing "infrastructure/README.md" '# Infrastructure

Deployment and cloud infrastructure.
'

write_if_missing "schema/README.md" '# Schema

Database migrations and contracts.
'

write_if_missing "tools/README.md" '# Tools

Developer automation utilities.
'

echo "Scaffold file fill complete."
