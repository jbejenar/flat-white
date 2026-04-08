# flat-white — Self-contained G-NAF address flattener
#
# Bundles: Postgres 16 + PostGIS 3.5, Python 3, gnaf-loader, Node.js 22,
#          TypeScript flattener. One container, one NDJSON file.
#
# Build:  docker build -t flat-white .
# Run:    docker run -v $(pwd)/output:/output flat-white --states VIC --compress --output /output/

# ---------------------------------------------------------------------------
# Stage 1: Build TypeScript
# ---------------------------------------------------------------------------
FROM node:22-bookworm-slim AS builder

WORKDIR /app

# Install dependencies first (cache layer)
COPY package.json package-lock.json ./
RUN npm ci --ignore-scripts

# Copy source and build inputs
COPY tsconfig.json ./
COPY src/ ./src/
COPY scripts/ ./scripts/
COPY sql/ ./sql/
RUN npm run build

# ---------------------------------------------------------------------------
# Stage 2: Runtime image
# ---------------------------------------------------------------------------
FROM imresamu/postgis:16-3.5

# Prevent interactive prompts during apt-get
ENV DEBIAN_FRONTEND=noninteractive

# Install Node.js 22 and Python 3 (for gnaf-loader)
# Python 3 is already in the postgis image
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    python3 \
    python3-pip \
    unzip \
  && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
  && apt-get install -y --no-install-recommends nodejs \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# gnaf-loader requires psycopg 3 (not psycopg2)
RUN pip3 install --no-cache-dir --break-system-packages psycopg[binary]

WORKDIR /app

# Copy built TypeScript output and runtime deps
COPY --from=builder /app/dist/ ./dist/
COPY --from=builder /app/node_modules/ ./node_modules/
COPY package.json ./

# Copy SQL files generated/validated during the builder stage
COPY --from=builder /app/sql/ ./sql/

# Copy fixtures (for --fixture-only mode)
COPY fixtures/seed-postgres.sql ./fixtures/seed-postgres.sql
COPY fixtures/seed-admin-bdys.sql ./fixtures/seed-admin-bdys.sql
COPY fixtures/prep-admin-bdys.sql ./fixtures/prep-admin-bdys.sql
COPY fixtures/expected-output.ndjson ./fixtures/expected-output.ndjson

# Copy gnaf-loader submodule
COPY gnaf-loader/ ./gnaf-loader/

# Copy scripts
COPY scripts/build-fixture-only.sh ./scripts/build-fixture-only.sh
COPY scripts/build-local.sh ./scripts/build-local.sh
COPY scripts/extract-boundary-prelude.mjs ./scripts/extract-boundary-prelude.mjs
# detect-load-failure.sh is invoked by docker-entrypoint.sh to classify
# gnaf-loader failures and decide whether to retry with --no-boundary-tag
COPY scripts/detect-load-failure.sh ./scripts/detect-load-failure.sh
COPY scripts/validate-db-cache.sh ./scripts/validate-db-cache.sh
RUN chmod +x ./scripts/detect-load-failure.sh ./scripts/validate-db-cache.sh

# Copy entrypoint (P2.02 will replace this with a proper orchestrator)
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# Output volume
VOLUME ["/output"]

# Data volume (for downloaded G-NAF + Admin Boundaries)
VOLUME ["/data"]

ENTRYPOINT ["/docker-entrypoint.sh"]
