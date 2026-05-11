#!/usr/bin/env bash
set -euo pipefail

DATABASE_URL="${DATABASE_URL:-postgresql://noetic:noetic@localhost:5432/noeticlayer}"
MIGRATIONS_DIR="${MIGRATIONS_DIR:-schema/migrations}"

if [ ! -d "$MIGRATIONS_DIR" ]; then
  echo "Migration directory not found: $MIGRATIONS_DIR"
  exit 1
fi

echo "Database: $DATABASE_URL"
echo "Migrations directory: $MIGRATIONS_DIR"

psql "$DATABASE_URL" -v ON_ERROR_STOP=1 <<'SQL'
CREATE TABLE IF NOT EXISTS schema_migrations (
    version text PRIMARY KEY,
    applied_at timestamptz NOT NULL DEFAULT now()
);
SQL

for migration in "$MIGRATIONS_DIR"/*.sql; do
  [ -f "$migration" ] || continue

  version="$(basename "$migration")"

  already_applied="$(
    psql "$DATABASE_URL" -tAc \
      "SELECT 1 FROM schema_migrations WHERE version = '$version';"
  )"

  if [ "$already_applied" = "1" ]; then
    echo "Skipping already applied migration: $version"
    continue
  fi

  echo "Applying migration: $version"

  psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "$migration"

  psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -c \
    "INSERT INTO schema_migrations(version) VALUES ('$version');"

  echo "Applied migration: $version"
done

echo "Migrations complete."