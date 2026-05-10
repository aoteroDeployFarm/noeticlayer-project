#!/usr/bin/env bash
set -euo pipefail

echo "Bootstrapping NoeticLayer project scaffold..."

mkdir -p \
  core/{api,models,services,config,tests} \
  mcp/{server,tools,transports,tests} \
  runtime/{orchestration,workers,events,tests} \
  agents/{executive,domain,business_analyst,shared,tests} \
  sync/{importers,connectors,parsers,tests} \
  docs/{architecture,decisions,operations,product} \
  infrastructure/{docker,gcp,terraform,scripts} \
  schema/{migrations,seed,data_contracts} \
  tools/{cli,dev,automation} \
  scripts

create_file_if_missing() {
  local file_path="$1"
  local content="$2"

  if [ ! -f "$file_path" ]; then
    mkdir -p "$(dirname "$file_path")"
    printf "%s\n" "$content" > "$file_path"
    echo "created: $file_path"
  else
    echo "exists:  $file_path"
  fi
}

create_file_if_missing ".gitignore" '# Python
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

# Local data
data/
.local/
tmp/

# Secrets
*.pem
*.key
secrets/
'

create_file_if_missing ".env.example" 'APP_ENV=local
APP_NAME=noeticlayer

DATABASE_URL=postgresql://noetic:noetic@localhost:5432/noeticlayer

OPENAI_API_KEY=
GOOGLE_APPLICATION_CREDENTIALS=

EMBEDDING_PROVIDER=openai
EMBEDDING_MODEL=text-embedding-3-small
'

create_file_if_missing "docker-compose.yml" 'services:
  postgres:
    image: pgvector/pgvector:pg16
    container_name: noeticlayer-postgres
    environment:
      POSTGRES_USER: noetic
      POSTGRES_PASSWORD: noetic
      POSTGRES_DB: noeticlayer
    ports:
      - "5432:5432"
    volumes:
      - noeticlayer_pgdata:/var/lib/postgresql/data

volumes:
  noeticlayer_pgdata:
'

create_file_if_missing "pyproject.toml" '[project]
name = "noeticlayer"
version = "0.1.0"
description = "Persistent cognition infrastructure for agents and business operations."
requires-python = ">=3.11"

dependencies = [
  "fastapi",
  "uvicorn",
  "psycopg[binary]",
  "pgvector",
  "pydantic",
  "python-dotenv",
  "openai"
]

[tool.pytest.ini_options]
pythonpath = ["."]
testpaths = ["core/tests", "mcp/tests", "runtime/tests", "agents/tests", "sync/tests"]
'

create_file_if_missing "README.md" '# NoeticLayer

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

## Repository Structure

```text
NoeticLayer
├── core              # memory engine, retrieval, data services
├── mcp               # MCP server and tool interfaces
├── runtime           # task execution and orchestration
├── agents            # specialized worker agents
├── sync              # ingestion and external connectors
├── docs              # architecture and operating documentation
├── infrastructure    # Docker, GCP, Terraform, deployment
├── schema            # database schema, migrations, contracts
├── tools             # CLI, automation, developer utilities
└── scripts           # repeatable project automation