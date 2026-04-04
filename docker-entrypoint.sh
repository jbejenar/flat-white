#!/usr/bin/env bash
set -euo pipefail

# flat-white Docker entrypoint
#
# Minimal entrypoint for P2.01. Starts Postgres, runs the requested mode,
# and stops Postgres. Full orchestration (download → load → flatten) is P2.02.

PGDATA="${PGDATA:-/var/lib/postgresql/data}"
PGUSER="${POSTGRES_USER:-postgres}"
PGPASSWORD="${POSTGRES_PASSWORD:-postgres}"
PGDB="${POSTGRES_DB:-gnaf}"

# --- Help ---
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  cat <<'EOF'
flat-white — Australian address data, flattened and served.

Usage:
  docker run flat-white --help
  docker run flat-white --fixture-only --output /output/
  docker run -v $(pwd)/output:/output flat-white --states VIC --compress --output /output/

Flags:
  --help              Show this help
  --fixture-only      Run fixture build only (no download, no gnaf-loader)
  --states STATES     States to process (e.g. VIC, "VIC NSW")
  --output DIR        Output directory (default: /output)
  --compress          Gzip output files
  --skip-download     Skip data download (assumes data already in /data)

Full pipeline (P2.02+):
  download → gnaf-loader → flatten → split → compress → verify → output
EOF
  exit 0
fi

# --- Start Postgres ---
echo "[entrypoint] Starting Postgres..."
su postgres -c "pg_ctl -D $PGDATA -l /var/log/postgresql.log start -w -t 30" 2>/dev/null || {
  # First run: initialize the database
  echo "[entrypoint] Initializing Postgres..."
  su postgres -c "initdb -D $PGDATA --auth=trust"
  # Allow local connections without password
  echo "host all all 0.0.0.0/0 trust" >> "$PGDATA/pg_hba.conf"
  echo "listen_addresses = 'localhost'" >> "$PGDATA/postgresql.conf"
  su postgres -c "pg_ctl -D $PGDATA -l /var/log/postgresql.log start -w -t 30"
  su postgres -c "createdb $PGDB" || true
}

# Wait for Postgres to be ready
for i in $(seq 1 30); do
  if su postgres -c "pg_isready" >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

echo "[entrypoint] Postgres ready."

# --- Parse arguments ---
MODE=""
OUTPUT_DIR="/output"
STATES=""
COMPRESS=false
SKIP_DOWNLOAD=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --fixture-only) MODE="fixture"; shift ;;
    --states) shift; STATES="$1"; shift ;;
    --output) shift; OUTPUT_DIR="$1"; shift ;;
    --compress) COMPRESS=true; shift ;;
    --skip-download) SKIP_DOWNLOAD=true; shift ;;
    *) echo "[entrypoint] Unknown argument: $1"; exit 1 ;;
  esac
done

mkdir -p "$OUTPUT_DIR"

# --- Execute ---
cleanup() {
  echo "[entrypoint] Stopping Postgres..."
  su postgres -c "pg_ctl -D $PGDATA stop -m fast" 2>/dev/null || true
}
trap cleanup EXIT

if [[ "$MODE" == "fixture" ]]; then
  echo "[entrypoint] Running fixture-only build..."

  # Seed fixtures
  su postgres -c "psql -d $PGDB -q -f /app/fixtures/seed-postgres.sql"

  # Flatten
  GNAF_VERSION="2026.02" DATABASE_URL="postgres://$PGUSER:$PGPASSWORD@localhost:5432/$PGDB" \
    node /app/dist/flatten.js "$OUTPUT_DIR/fixture.ndjson"

  LINE_COUNT=$(wc -l < "$OUTPUT_DIR/fixture.ndjson" | tr -d ' ')
  echo "[entrypoint] Fixture build complete: $LINE_COUNT documents"
else
  echo "[entrypoint] Full pipeline mode not yet implemented (P2.02)."
  echo "[entrypoint] Use --fixture-only for now, or run build-local.sh outside Docker."
  exit 1
fi

echo "[entrypoint] Done."
