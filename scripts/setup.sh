#!/usr/bin/env bash
set -euo pipefail

# setup.sh — Bootstrap flat-white development environment
# Usage: ./scripts/setup.sh

echo "=== flat-white setup ==="

# Check Node.js version
REQUIRED_NODE=22
CURRENT_NODE=$(node -v | sed 's/v//' | cut -d. -f1)
if [ "$CURRENT_NODE" -lt "$REQUIRED_NODE" ]; then
  echo "ERROR: Node.js >= $REQUIRED_NODE required (found v$(node -v))"
  echo "  Install via: nvm install $REQUIRED_NODE"
  exit 1
fi
echo "Node.js $(node -v) — OK"

# Check Docker
if ! command -v docker &> /dev/null; then
  echo "WARNING: Docker not found — required for Postgres + PostGIS"
  echo "  Install: https://docs.docker.com/get-docker/"
else
  echo "Docker $(docker --version | cut -d' ' -f3 | tr -d ',') — OK"
fi

# Install dependencies
echo "Installing npm dependencies..."
npm install

# Verify TypeScript compiles
echo "Type-checking..."
npm run typecheck

# Run tests
echo "Running tests..."
npm test

echo ""
echo "=== Setup complete ==="
echo "Next steps:"
echo "  docker compose up db    # Start Postgres + PostGIS"
echo "  npm test                # Run tests"
echo "  npm run typecheck       # Type-check"
