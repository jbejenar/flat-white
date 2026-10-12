#!/usr/bin/env bash
set -euo pipefail

# setup.sh — Bootstrap flat-white development environment
# Usage: ./scripts/setup.sh

echo "=== flat-white setup ==="

# Let npm enforce package.json and dependency engines through .npmrc before
# other setup. This also installs the exact lockfile rather than updating it.
echo "Node.js $(node -v) — checking declared engine requirements..."
echo "Installing locked npm dependencies..."
npm ci

# Check Docker
if ! command -v docker &> /dev/null; then
  echo "WARNING: Docker not found — required for Postgres + PostGIS"
  echo "  Install: https://docs.docker.com/get-docker/"
else
  echo "Docker $(docker --version | cut -d' ' -f3 | tr -d ',') — OK"
  # Verify docker compose works
  if docker compose version &> /dev/null; then
    echo "Docker Compose $(docker compose version --short) — OK"
  else
    echo "WARNING: Docker Compose not available"
  fi
fi

# Check gnaf-loader submodule
if [ -f gnaf-loader/load-gnaf.py ]; then
  echo "gnaf-loader submodule — OK"
else
  echo "Initialising gnaf-loader submodule..."
  git submodule update --init
fi

# Verify TypeScript compiles
echo "Type-checking..."
npm run typecheck

# Run tests
echo "Running tests..."
npm test

echo ""
echo "=== Setup complete ==="
echo "Next steps:"
echo "  docker compose up db           # Start Postgres + PostGIS"
echo "  ./scripts/build-fixture-only.sh # Run fixture build (<30s)"
echo "  npm test                        # Run tests"
