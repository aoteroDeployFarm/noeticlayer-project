````markdown
# NoeticLayer

Persistent cognition infrastructure for AI systems.

NoeticLayer is a memory-first platform for building AI agents and applications with durable semantic memory, workspace isolation, vector-native retrieval, and infrastructure-grade operational patterns.

This project is not a chatbot wrapper or a toy RAG demo.

The goal is to build reusable cognition infrastructure:
- persistent semantic memory
- retrieval-native architectures
- workspace-scoped cognition
- long-term memory systems
- cloud-portable AI infrastructure
- production-oriented agent runtime foundations

---

# Current Status

## Infrastructure

Operational GCP development environment:
- Custom VPC
- Hardened SSH access
- OS Login enforced
- Ubuntu 22.04 dev VM
- PostgreSQL + pgvector
- Infrastructure automation scripts

## Data Layer

Working:
- PostgreSQL
- pgvector
- workspace-scoped memory model
- semantic memory persistence

Validated:
- memory capture
- recent memory retrieval
- semantic search scaffolding

## Development Status

Current phase:
- Embedding pipeline implementation
- Semantic retrieval engine
- FastAPI service layer
- Agent memory runtime foundations

---

# Architecture

```text
                +----------------------+
                |     AI Agents        |
                |  Applications/API    |
                +----------+-----------+
                           |
                           v
                +----------------------+
                |   NoeticLayer Core   |
                |----------------------|
                | Memory Service       |
                | Embedding Pipeline   |
                | Retrieval Engine     |
                | Workspace Isolation  |
                +----------+-----------+
                           |
                           v
                +----------------------+
                | PostgreSQL + pgvector|
                +----------------------+
````

---

# Core Concepts

## Workspace-Scoped Cognition

Each workspace acts as an isolated cognitive boundary.

Examples:

* organization memory
* agent memory
* project memory
* research memory
* customer memory

This allows:

* multi-tenant cognition
* isolated retrieval contexts
* controlled semantic boundaries

---

## Persistent Semantic Memory

Memories are stored as:

* raw content
* metadata
* embeddings
* semantic vectors
* timestamps
* workspace associations

This creates durable retrieval layers for:

* agents
* copilots
* automation systems
* AI runtimes

---

## Retrieval-Native Design

Retrieval is not bolted on later.

The platform is designed around:

* semantic indexing
* vector similarity
* memory persistence
* retrieval orchestration
* long-term context management

---

# Technology Stack

## Infrastructure

* Google Cloud Platform (GCP)
* Compute Engine
* Custom VPC
* OS Login
* Infrastructure shell automation

## Backend

* Python 3
* PostgreSQL
* pgvector
* psycopg
* FastAPI (planned)

## AI Layer

Planned:

* OpenAI embeddings
* provider abstraction layer
* local embedding providers
* hybrid retrieval
* reranking

---

# Repository Structure

```text
noeticlayer-project/
├── core/
│   ├── services/
│   ├── tests/
│   └── models/
│
├── schema/
│   └── migrations/
│
├── scripts/
│   └── infrastructure/
│
├── docs/
│
└── README.md
```

---

# Infrastructure Scripts

## Create Dev VM

```bash
./scripts/infrastructure/create-noeticlayer-devbox.sh
```

Creates:

* GCP VM
* PostgreSQL
* pgvector
* OS Login configuration
* base development environment

---

## Start Dev VM

```bash
./scripts/infrastructure/start-noeticlayer-devbox.sh
```

---

## Stop Dev VM

```bash
./scripts/infrastructure/stop-noeticlayer-devbox.sh
```

Used to reduce idle infrastructure costs.

---

# Local Development

## SSH Into VM

```bash
gcloud compute ssh noeticlayer-devbox \
  --project=regulatory-monitor-ai \
  --zone=us-central1-a
```

---

## Connect to PostgreSQL

```bash
psql postgresql://noetic:noetic@localhost:5432/noeticlayer
```

---

## Activate Python Environment

```bash
source .venv/bin/activate
```

---

## Run Memory Service Tests

```bash
PYTHONPATH=. python core/tests/test_memory_service.py
```

---

# Database Extensions

Installed:

* pgvector
* pgcrypto

---

# Current Database Tables

## workspaces

Logical cognitive boundary container.

## memory_items

Stores:

* semantic memories
* embeddings
* raw content
* metadata
* workspace associations

---

# Current Priorities

## Phase 1 — Semantic Memory Foundation

* [x] PostgreSQL + pgvector
* [x] workspace model
* [x] memory persistence
* [x] infrastructure automation
* [ ] embedding provider abstraction
* [ ] vector similarity retrieval
* [ ] semantic ranking
* [ ] FastAPI service layer

---

## Phase 2 — Retrieval Runtime

Planned:

* hybrid search
* reranking
* memory summarization
* context window management
* temporal retrieval
* agent session persistence

---

## Phase 3 — Cognitive Infrastructure Platform

Long-term goals:

* distributed cognition infrastructure
* multi-agent memory systems
* cognition orchestration
* memory lifecycle management
* semantic governance
* policy-aware retrieval
* enterprise cognition platform patterns

---

# Security Notes

Current posture:

* restricted SSH ingress
* custom VPC
* OS Login enforced
* infrastructure automation
* project-scoped IAM

Future work:

* IAP tunneling
* secrets management
* workload identity
* service perimeter hardening
* audit pipelines

---

# Design Philosophy

AI systems fail when memory is treated as an afterthought.

Most AI applications are stateless wrappers around prompts.

NoeticLayer treats memory as infrastructure.

The objective is to provide a reusable cognition substrate that enables:

* durable semantic recall
* retrieval-native AI systems
* scalable agent memory
* operationally reliable cognition services

---

# Author

Alex Otero
AI Architect | DevSecOps Engineer | Infrastructure Builder

Focused on:

* AI infrastructure
* secure automation
* retrieval systems
* production AI architecture
* cognition platform engineering

---

```
```
