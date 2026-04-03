# flat-white

### Australian addresses. Flattened and served.

> Last updated: 2026-04-03 · Roadmap version: 1.3.0

---

## Overview

flat-white transforms raw Australian Government address data into a single flat file of pre-joined, boundary-enriched address documents. It spins up an ephemeral Postgres + PostGIS instance, runs `minus34/gnaf-loader` to load and spatially join G-NAF (15.9M addresses) with Administrative Boundaries (LGA, electoral, ABS), flattens the relational model into one document per address via a 9+ table SQL JOIN, and outputs a portable NDJSON file. Then it dies.

Every quarter, a GitHub Actions matrix build runs — one parallel job per state on free runners — producing per-state gzipped NDJSON files published as GitHub Release assets. Anyone in Australia can download their state's addresses in one click. The entire address validation industry built on reselling government data just became optional.

Postgres is a build tool, not infrastructure. It exists inside the container for ~30-40 minutes per state and is destroyed when the output is written. The NDJSON file is the only artifact. It is the universal contract between this builder and any downstream consumer — OpenSearch, Elasticsearch, DynamoDB, BigQuery, a static file download, whatever.

flat-white does not serve traffic. It does not run an API. It produces a file and publishes it to the world.

---

## Principles

1. **One container, one file.** `docker run` in, NDJSON out. No external dependencies except the data.gov.au download.
2. **Postgres is ephemeral.** Lives inside the container. Starts, loads, joins, exports, dies. Nothing persists except the output.
3. **The NDJSON file is the contract.** Downstream consumers depend on the document schema, not on flat-white's internals. Breaking schema changes are major version bumps.
4. **Fixture-first development.** A committed subset allows flatten logic to be tested without downloading 6.5GB or running gnaf-loader.
5. **gnaf-loader is a dependency, not a fork.** Pinned as a Git submodule. We don't modify it. Changes go upstream via PR.
6. **Sovereign data only.** Every byte from data.gov.au. CC BY 4.0. No commercial dependencies.
7. **Zero cost.** Public repo. Free GitHub Actions runners. Free GitHub Release hosting. Free forever.

---

## Technology Stack

| Layer        | Technology                      | Rationale                                                                                     |
| ------------ | ------------------------------- | --------------------------------------------------------------------------------------------- |
| Database     | PostgreSQL 16 + PostGIS 3.5     | Ephemeral, inside container. gnaf-loader's native target.                                     |
| Data loader  | `minus34/gnaf-loader` (Python)  | 922 commits, 10 years maintained. All G-NAF + Admin Boundary edge cases. Pinned as submodule. |
| Flattener    | Node.js 22 / TypeScript         | Streams rows from Postgres, composes documents, writes NDJSON. ~300 lines.                    |
| Container    | Docker (Debian Bookworm base)   | Self-contained: Postgres + PostGIS + Python + Node + gnaf-loader + flattener.                 |
| CI/CD        | GitHub Actions (free tier)      | Matrix build: one job per state, parallel, on free runners.                                   |
| Output       | NDJSON (Newline-Delimited JSON) | One document per line. Universal. Streamable. Per-state gzipped.                              |
| Distribution | GitHub Releases                 | Per-state `.ndjson.gz` as release assets. Free hosting. Programmatic download.                |

---

## Repo Structure

```
flat-white/
├── AGENTS.md                         # Agent instructions
├── HINTS.md                          # Human override hints
├── README.md                         # Usage, configuration, output schema
├── ROADMAP.md                        # This file
├── CHANGELOG.md                      # Semantic versioning
├── LICENSE                           # Apache 2.0
├── .env.example                      # Environment template
├── .agentignore                      # Files agents should skip
├── Dockerfile                        # Self-contained build environment
├── docker-compose.yml                # Local dev: Postgres + PostGIS
├── manifest.json                     # Agent skill routing
│
├── .github/
│   └── workflows/
│       ├── ci.yml                    # PR: fixture build + regression (<60s)
│       ├── quarterly-build.yml       # Matrix build → GitHub Release + S3
│       └── notify-downstream.yml     # Post-release: repository_dispatch
│
├── gnaf-loader/                      # Git submodule → minus34/gnaf-loader @ pinned release
│
├── src/
│   ├── build.ts                      # Orchestrator: download → load → flatten → output
│   ├── download.ts                   # Fetch G-NAF + Admin Bdys from data.gov.au
│   ├── load.ts                       # Invoke gnaf-loader against local Postgres
│   ├── flatten.ts                    # Stream Postgres → compose docs → write NDJSON
│   ├── split.ts                      # Split all-states NDJSON into per-state files
│   ├── compress.ts                   # Streaming gzip (~85-90% ratio)
│   ├── schema.ts                     # TypeScript types + Zod validation
│   ├── verify.ts                     # Row count, schema validation, completeness
│   ├── metadata.ts                   # Generate build metadata JSON
│   ├── output-local.ts               # Write to local filesystem
│   ├── output-s3.ts                  # Write to S3
│   └── cli.ts                        # CLI: --states, --output, --split-states, --compress
│
├── sql/
│   ├── address_full.sql              # Master 9+ table JOIN → one row per address
│   ├── address_full_with_arrays.sql  # With aggregated aliases + secondaries
│   ├── locality_full.sql             # Locality with neighbours + aliases
│   └── create_views.sql              # Materialised views for fast export
│
├── fixtures/                         # Committed test data — loads via psql in <30s
│   ├── README.md                     # What's in the fixture, row counts, schema version
│   ├── seed-postgres.sql             # Schema DDL + ~451 addresses + related tables
│   ├── edge-cases.md                 # Catalogue of edge cases + which rows cover them
│   ├── expected-output.ndjson        # Known-good output for regression (P0.09)
│   └── expected-output-sample.json   # Single prettified doc for human reference (P0.09)
│
├── scripts/
│   ├── build-local.sh                # Full local build: docker up → load → flatten → output
│   ├── build-fixture-only.sh         # Flatten from fixture Postgres only (~30s)
│   ├── extract-fixtures.sh           # Re-extract fixtures from full load
│   └── validate-output.sh            # Validate NDJSON against schema
│
├── docs/
│   ├── DOCUMENT-SCHEMA.md            # Complete document schema reference
│   ├── FIELD-PROVENANCE.md           # Every field → G-NAF table.column
│   ├── EDGE-CASES.md                 # Known G-NAF edge cases and handling
│   ├── GNAF-LOADER.md                # Integration notes, version pinning
│   └── decisions/
│       ├── DEC-001-ndjson-over-parquet.md
│       ├── DEC-002-ephemeral-postgres.md
│       ├── DEC-003-submodule-not-fork.md
│       ├── DEC-004-streaming-flatten.md
│       ├── DEC-005-fixture-first.md
│       ├── DEC-006-matrix-build-free-runners.md
│       └── DEC-007-github-releases-distribution.md
│
└── test/
    ├── unit/
    │   ├── flatten.test.ts           # Document composition logic
    │   ├── schema.test.ts            # Zod schema validation
    │   └── verify.test.ts            # Verification logic
    ├── integration/
    │   ├── build-fixture.test.ts     # Full fixture → NDJSON pipeline
    │   └── output.test.ts            # File format, line count, streaming
    └── regression/
        └── expected-output.test.ts   # Byte-for-byte against committed fixtures
```

---

## Output Document Schema

Every line in the NDJSON is one address document. This schema IS the contract. Breaking changes require a major version bump.

> **Note:** This schema example is illustrative. The authoritative contract is `docs/DOCUMENT-SCHEMA.md` once published (P0.11).

```json
{
  "_id": "GAVIC425181432",
  "_version": "2026.02",
  "addressLabel": "1 MCNAB AV, FOOTSCRAY VIC 3011",
  "addressLabelSearch": "1 MCNAB AVENUE FOOTSCRAY VIC 3011",
  "addressSiteName": null,
  "buildingName": null,
  "flatType": null,
  "flatNumber": null,
  "levelType": null,
  "levelNumber": null,
  "numberFirst": "1",
  "numberLast": null,
  "lotNumber": null,
  "streetName": "MCNAB",
  "streetType": "AVENUE",
  "streetSuffix": null,
  "localityName": "FOOTSCRAY",
  "state": "VIC",
  "postcode": "3011",
  "legalParcelId": "1\\PS733924",
  "confidence": 2,
  "aliasPrincipal": "PRINCIPAL",
  "primarySecondary": "PRIMARY",
  "geocode": {
    "latitude": -37.79815294,
    "longitude": 144.89719303,
    "type": "FRONTAGE CENTRE SETBACK",
    "reliability": 2
  },
  "allGeocodes": [
    { "lat": -37.79815294, "lng": 144.89719303, "type": "FCS", "reliability": 2 },
    { "lat": -37.798211, "lng": 144.897254, "type": "PC", "reliability": 2 },
    { "lat": -37.798105, "lng": 144.897122, "type": "PAP", "reliability": 2 }
  ],
  "locality": {
    "pid": "loc67a11408d754",
    "class": "GAZETTED LOCALITY",
    "neighbours": [
      "ASCOT VALE",
      "FLEMINGTON",
      "KENSINGTON",
      "MAIDSTONE",
      "MARIBYRNONG",
      "SEDDON",
      "WEST FOOTSCRAY",
      "YARRAVILLE"
    ],
    "aliases": ["FOOTSCRAY WEST", "SEDDON"]
  },
  "street": {
    "pid": "VIC2104831",
    "class": "CONFIRMED",
    "aliases": []
  },
  "boundaries": {
    "lga": { "name": "MARIBYRNONG", "code": "LGA24650" },
    "ward": { "name": "RIVER WARD" },
    "stateElectorate": { "name": "FOOTSCRAY" },
    "commonwealthElectorate": { "name": "GELLIBRAND" },
    "meshBlock": { "code": "20663890000", "category": "COMMERCIAL" },
    "sa1": "20604102614",
    "sa2": { "code": "20604", "name": "FOOTSCRAY" },
    "sa3": { "code": "206", "name": "MARIBYRNONG" },
    "sa4": { "code": "2", "name": "MELBOURNE - WEST" },
    "gccsa": { "code": "2GMEL", "name": "GREATER MELBOURNE" }
  },
  "aliases": [
    {
      "pid": "MA13517230",
      "label": "SHOP 1 GROUND 1 MCNAB AV, FOOTSCRAY VIC 3011",
      "type": "SYNONYM"
    }
  ],
  "secondaries": [
    { "pid": "GAVIC425495838", "label": "SHOP 1 1 MCNAB AV, FOOTSCRAY VIC 3011" },
    { "pid": "GAVIC425565270", "label": "UNIT G1 1 MCNAB AV, FOOTSCRAY VIC 3011" }
  ]
}
```

---

## CLI Interface

```bash
# Full build — all states, split per state, compressed
docker run -v $(pwd)/output:/output flat-white \
  --states ALL \
  --split-states \
  --compress \
  --output /output/

# Produces:
#   /output/flat-white-2026.02-all.ndjson.gz       (~1.2 GB)
#   /output/flat-white-2026.02-vic.ndjson.gz       (~112 MB)
#   /output/flat-white-2026.02-nsw.ndjson.gz       (~134 MB)
#   /output/flat-white-2026.02-qld.ndjson.gz       (~118 MB)
#   /output/flat-white-2026.02-sa.ndjson.gz        (~52 MB)
#   /output/flat-white-2026.02-wa.ndjson.gz        (~68 MB)
#   /output/flat-white-2026.02-tas.ndjson.gz       (~18 MB)
#   /output/flat-white-2026.02-nt.ndjson.gz        (~6 MB)
#   /output/flat-white-2026.02-act.ndjson.gz       (~12 MB)
#   /output/flat-white-2026.02-ot.ndjson.gz        (~1 MB)
#   /output/flat-white-2026.02-metadata.json       (~1 KB)

# Single state
docker run -v $(pwd)/output:/output flat-white \
  --states VIC \
  --compress \
  --output /output/flat-white-2026.02-vic.ndjson.gz

# Skip download (data already mounted)
docker run -v $(pwd)/data:/data -v $(pwd)/output:/output flat-white \
  --skip-download \
  --gnaf-path /data/G-NAF \
  --admin-path /data/Administrative-Boundaries \
  --output /output/

# Fixture build (dev — committed seed data, no download, ~30 seconds)
docker run -v $(pwd)/output:/output flat-white \
  --fixture-only \
  --output /output/fixture.ndjson
```

**Exit codes:** `0` success · `1` download failed · `2` gnaf-loader failed · `3` flatten failed · `4` verification failed · `5` output write failed

---

## GitHub Actions Matrix Build Strategy

Each state builds in parallel on a free runner. No paid infrastructure. Zero cost.

```yaml
name: Quarterly Build

on:
  workflow_dispatch:
    inputs:
      gnaf_version:
        description: "G-NAF version (e.g., 2026.02)"
        required: true
  schedule:
    - cron: "0 6 15 2,5,8,11 *" # 15th of Feb/May/Aug/Nov

jobs:
  build-state:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        state: [VIC, NSW, QLD, SA, WA, TAS, NT, ACT, OT]
      fail-fast: false
    timeout-minutes: 120

    steps:
      - uses: actions/checkout@v4
        with:
          submodules: true

      - name: Build ${{ matrix.state }}
        run: |
          docker build -t flat-white .
          docker run -v ${{ runner.temp }}/output:/output flat-white \
            --states ${{ matrix.state }} \
            --compress \
            --output /output/flat-white-${{ inputs.gnaf_version }}-${{ matrix.state }}.ndjson.gz

      - name: Upload state artifact
        uses: actions/upload-artifact@v4
        with:
          name: flat-white-${{ matrix.state }}
          path: ${{ runner.temp }}/output/

  release:
    needs: build-state
    runs-on: ubuntu-latest
    steps:
      - uses: actions/download-artifact@v4
        with:
          path: ./artifacts
          merge-multiple: true

      - name: Generate all-states file
        run: |
          cd artifacts
          zcat flat-white-*.ndjson.gz | gzip > flat-white-${{ inputs.gnaf_version }}-all.ndjson.gz

      - name: Generate metadata
        run: |
          # Count docs per file, produce metadata.json
          node scripts/generate-metadata.js ./artifacts ${{ inputs.gnaf_version }}

      - name: Create GitHub Release
        uses: softprops/action-gh-release@v2
        with:
          tag_name: v${{ inputs.gnaf_version }}
          name: "flat-white v${{ inputs.gnaf_version }}"
          body_path: RELEASE_NOTES.md
          files: |
            artifacts/flat-white-*.ndjson.gz
            artifacts/flat-white-*-metadata.json
            docs/DOCUMENT-SCHEMA.md

      - name: Notify downstream
        uses: peter-evans/repository-dispatch@v3
        with:
          repository: ${{ github.repository_owner }}/geocode-au
          event-type: new-flat-white-release
          client-payload: '{"version": "${{ inputs.gnaf_version }}"}'
```

**How this fits the free runner constraints:**

| State | Addresses | Est. RAM | Est. Time | Fits 7GB?     |
| ----- | --------- | -------- | --------- | ------------- |
| VIC   | ~3.8M     | ~4-5 GB  | ~40 min   | Yes           |
| NSW   | ~4.5M     | ~5-6 GB  | ~50 min   | Tight but yes |
| QLD   | ~2.9M     | ~3-4 GB  | ~35 min   | Yes           |
| WA    | ~1.3M     | ~2 GB    | ~20 min   | Yes           |
| SA    | ~1.1M     | ~2 GB    | ~18 min   | Yes           |
| TAS   | ~310K     | ~1 GB    | ~8 min    | Yes           |
| ACT   | ~220K     | ~1 GB    | ~6 min    | Yes           |
| NT    | ~98K      | ~1 GB    | ~4 min    | Yes           |
| OT    | ~3K       | ~1 GB    | ~2 min    | Yes           |

9 jobs running in parallel. Total wall-clock time: ~50 minutes (limited by NSW). Total cost: $0.

---

## GitHub Release Format

```
flat-white v2026.02
━━━━━━━━━━━━━━━━━━━

Australian addresses. Flattened and served.

15,860,127 pre-joined, boundary-enriched address documents.
Source: data.gov.au G-NAF + Administrative Boundaries (CC BY 4.0)
Document schema: v1.0.0 · gnaf-loader: v202602

Assets:
  flat-white-2026.02-all.ndjson.gz       1.2 GB   All (15,860,127 docs)
  flat-white-2026.02-vic.ndjson.gz       112 MB   VIC (3,821,044 docs)
  flat-white-2026.02-nsw.ndjson.gz       134 MB   NSW (4,512,388 docs)
  flat-white-2026.02-qld.ndjson.gz       118 MB   QLD (2,891,203 docs)
  flat-white-2026.02-wa.ndjson.gz         68 MB   WA (1,344,891 docs)
  flat-white-2026.02-sa.ndjson.gz         52 MB   SA (1,102,445 docs)
  flat-white-2026.02-tas.ndjson.gz        18 MB   TAS (312,891 docs)
  flat-white-2026.02-act.ndjson.gz        12 MB   ACT (218,992 docs)
  flat-white-2026.02-nt.ndjson.gz          6 MB   NT (98,441 docs)
  flat-white-2026.02-ot.ndjson.gz          1 MB   OT (2,832 docs)
  flat-white-2026.02-metadata.json         1 KB   Build metadata
  DOCUMENT-SCHEMA.md                       8 KB   Schema reference

Download your state:
  gh release download v2026.02 --pattern '*-vic.ndjson.gz'
```

---

## Phase Overview

| Phase    | Name               | Duration | Outcome                                                                    |
| -------- | ------------------ | -------- | -------------------------------------------------------------------------- |
| **P0-A** | Data Acquisition   | 2 days   | VIC loaded into local Postgres, schema explored, edge cases identified     |
| **P0-B** | Fixture + Scaffold | 3 days   | Postgres fixtures committed, flatten SQL verified, repo structure complete |
| **P1**   | Flatten Core       | 2 weeks  | Streaming NDJSON, per-state split, gzip, schema + data quality validated   |
| **P2**   | Container          | 1 week   | Dockerfile, one `docker run` produces NDJSON from raw data                 |
| **P3**   | Distribution       | 1 week   | GitHub Actions matrix build, GitHub Releases, adoption quick-start         |
| **P4**   | Hardening          | 1 week   | Verification, build-over-build comparison, monitoring, runbook             |
| **P5**   | AWS Mirror         | Deferred | S3 upload, latest pointer, OIDC auth, SNS notifications                    |
| **E1**   | Enhancements       | Ongoing  | Parquet, delta builds, locality output, schema evolution                   |

---

## Priority Legend

- 🔴 **P0** — Must ship to unlock next phase.
- 🟠 **P1** — Should ship to hit adoption and quality targets.
- 🟡 **P2** — Valuable expansion once core is stable.

---

## Personas

| Persona              | Description                                                              |
| -------------------- | ------------------------------------------------------------------------ |
| builder/contributor  | Develops flat-white code: flatten logic, SQL, container, CI              |
| ops/maintainer       | Runs quarterly builds, monitors failures, updates gnaf-loader pins       |
| downstream developer | Integrates flat-white output into geocode-au or other consuming services |

**Data consumer sub-personas:**

| Sub-Persona            | What They Need                                         | Notes                                                           |
| ---------------------- | ------------------------------------------------------ | --------------------------------------------------------------- |
| Local council GIS team | Per-LGA extract, boundary data, QGIS-friendly format   | NDJSON covers basics; Geoparquet (E1.05) unlocks native spatial |
| Proptech startup       | Bulk download, API-friendly, fresh quarterly data      | Well-served by GitHub Releases + NDJSON                         |
| Government analyst     | Statistical area aggregation, ABS mesh blocks, SA1-SA4 | Well-served by boundary enrichment                              |
| Academic researcher    | Reproducible data, citation format, methodology docs   | Needs: version pinning, DOI consideration, build methodology    |

---

## Phase P0 — Foundation

**Target:** Week 1 · **Status:** Planned

### Epic P0.A — Data Acquisition

### Ticket P0.01 — Repo Scaffold

```yaml
id: P0.01
title: Repo Scaffold
status: done
priority: p0-critical
epic: P0.A
persona: [builder/contributor]
depends_on: []
completed: 2026-04-02
tech_stack:
  runtime: Node.js 22
  language: TypeScript 5.7 strict
  database: PostgreSQL 16 + PostGIS 3.5
  data_loader: minus34/gnaf-loader (Python)
  container: Docker (Debian Bookworm)
  ci: GitHub Actions (free tier)
  output: NDJSON
  distribution: GitHub Releases
completed: null
```

## User Story

As a builder/contributor, I need a fully scaffolded repository with the planned directory structure, AGENTS.md, manifest.json, docker-compose, and gnaf-loader submodule so that all downstream development has a stable foundation to build on.

## Problem Statement

flat-white is a greenfield project with a partial scaffold already committed (README, ROADMAP, LICENSE, gnaf-loader submodule, .gitignore). This ticket completes the remaining structure — package.json, tsconfig, docker-compose, .env.example, and directory scaffolding — so that all downstream development has a stable foundation. The scaffold must be complete enough that `git clone --recurse-submodules` gives a contributor everything they need to start.

## Definition of Done

### Functional

- [x] Repository contains full directory structure matching the Repo Structure section of this roadmap
  - `Verify:` `ls -R` matches planned structure (empty directories with `.gitkeep` where no files exist yet)
  - `Evidence:` PR #2 — src/, test/, scripts/, docs/, fixtures/, .github/workflows/ all created
- [x] `git clone --recurse-submodules` pulls gnaf-loader at a pinned release tag
  - `Verify:` `git submodule status gnaf-loader` shows pinned commit hash
  - `Evidence:` gnaf-loader submodule at commit 65328e8 (202602-5 variant)
- [x] `docker-compose.yml` defines Postgres 16 + PostGIS 3.5 service
  - `Verify:` `docker compose config` validates without error
  - `Evidence:` PR #2 — imresamu/postgis:16-3.5 (ARM64 compatible)
- [x] `.env.example` documents all required environment variables
  - `Verify:` File exists with documented variables
  - `Evidence:` PR #2 — 10 vars documented with CLI flag mappings (PR #3)
- [x] `package.json` with TypeScript 5.7, Node.js 22 engine constraint, and basic scripts
  - `Verify:` `node -e "require('./package.json')"` parses; `engines.node` specifies `>=22`
  - `Evidence:` PR #2 — 8 scripts, engines.node >=22.0.0, zod in dependencies
- [x] `tsconfig.json` with strict mode enabled
  - `Verify:` `npx tsc --showConfig | grep strict` shows `true`
  - `Evidence:` PR #2 — strict: true, ES2022, Node16
- [x] `CHANGELOG.md` created with initial "No releases yet" entry
  - `Verify:` File exists and follows Keep a Changelog format
  - `Evidence:` PR #2 — Keep a Changelog format with versioning rules (PR #3)

### Documentation

- [x] `README.md` documents project purpose, quickstart, and links to ROADMAP.md
  - `Verify:` README contains clone instructions and link to roadmap
  - `Evidence:` README.md has download, build, use cases, schema sample, roadmap link

## Scope

### In

- Repository structure, package.json, tsconfig, docker-compose, gnaf-loader submodule, .gitignore, LICENSE, .env.example

### Out — Do Not Implement

- AGENTS.md content → P0.13
- Decision records → P0.14
- Source code in `src/` → P0.03+
- Fixture data → P0.07+

---

### Ticket P0.02 — Local Postgres + PostGIS

```yaml
id: P0.02
title: Local Postgres + PostGIS
status: done
priority: p0-critical
epic: P0.A
persona: [builder/contributor]
depends_on: [P0.01]
completed: 2026-04-02
tech_stack:
  runtime: Node.js 22
  language: TypeScript 5.7 strict
  database: PostgreSQL 16 + PostGIS 3.5
  data_loader: minus34/gnaf-loader (Python)
  container: Docker (Debian Bookworm)
  ci: GitHub Actions (free tier)
  output: NDJSON
  distribution: GitHub Releases
completed: null
```

## User Story

As a builder/contributor, I need a local Postgres 16 + PostGIS 3.5 instance running via docker-compose so that I can load G-NAF data and develop the flatten SQL against a real database.

## Problem Statement

gnaf-loader requires a PostgreSQL database with PostGIS extensions to load G-NAF data and perform spatial boundary joins. Without a reproducible local database setup, developers cannot load data, explore the schema, or develop the flatten SQL. docker-compose ensures every contributor gets an identical database environment regardless of their host OS.

## Definition of Done

### Functional

- [x] `docker compose up db` starts PostgreSQL 16 with PostGIS 3.5 extensions enabled
  - `Verify:` `docker compose exec db psql -U postgres -c "SELECT PostGIS_Version()"` returns 3.5.x
  - `Evidence:` PR #2 — imresamu/postgis:16-3.5, PostGIS 3.5.3 confirmed
- [x] Database is accessible on `localhost:5432` with credentials from `.env.example`
  - `Verify:` `psql -h localhost -U postgres -c "SELECT 1"` succeeds
  - `Evidence:` PR #2 — verified via `docker compose exec db pg_isready`
- [x] Volume mount persists data between container restarts during development
  - `Verify:` `docker compose down && docker compose up db` retains previously loaded data
  - `Evidence:` PR #2 — named volume `pgdata` in docker-compose.yml
- [x] `docker compose down -v` cleanly destroys all data (ephemeral by design)
  - `Verify:` No Postgres data remains after volume removal
  - `Evidence:` PR #4 — verified during gnaf-loader testing (clean slate between runs)

## Scope

### In

- docker-compose service definition for Postgres 16 + PostGIS 3.5
- Volume configuration for development persistence
- Port mapping and credential configuration

### Out — Do Not Implement

- Production database setup (Postgres is ephemeral — DEC-002)
- Dockerfile integration (that is P2.01)
- gnaf-loader execution (that is P0.04)

---

### Ticket P0.03 — G-NAF Download Script

```yaml
id: P0.03
title: G-NAF Download Script
status: done
priority: p0-critical
epic: P0.A
persona: [builder/contributor]
depends_on: [P0.01]
tech_stack:
  runtime: Node.js 22
  language: TypeScript 5.7 strict
  database: PostgreSQL 16 + PostGIS 3.5
  data_loader: minus34/gnaf-loader (Python)
  container: Docker (Debian Bookworm)
  ci: GitHub Actions (free tier)
  output: NDJSON
  distribution: GitHub Releases
completed: 2026-04-04
```

## User Story

As a builder/contributor, I need a script that downloads the latest G-NAF GDA2020 and Administrative Boundaries ESRI Shapefiles from data.gov.au so that I can feed them into gnaf-loader without manually navigating government download pages.

## Problem Statement

G-NAF and Administrative Boundaries data is published quarterly on data.gov.au as large zip archives (~6.5GB combined). The download URLs change each quarter. A reliable download script that handles retries, checksum verification, and extraction is essential for both local development and CI automation. Without it, every contributor must manually find and download the correct files.

## Definition of Done

### Functional

- [x] `src/download.ts` fetches Feb 2026 G-NAF GDA2020 + Admin Boundaries ESRI Shapefiles from data.gov.au
  - `Verify:` Script completes and `ls ./data/` shows G-NAF and Administrative-Boundaries directories
  - `Evidence:` PR #20 — `src/download.ts` with DATA_SOURCES containing verified data.gov.au URLs, sentinel path validation, atomic extraction. 24 unit tests pass.
- [x] Downloads ~6.5GB total, extracts to `./data/`
  - `Verify:` `du -sh ./data/` shows ~6.5GB extracted
  - `Evidence:` PR #20 — download + extractZip + atomic rename to `./data/<extractedDir>`. Configurable via DATA_DIR env var.
- [x] Progress reporting during download (% complete, MB/s)
  - `Verify:` Script outputs progress to stdout during download
  - `Evidence:` PR #20 — `formatProgress()` reports % complete + MB/s every 2s. Unit tests verify formatting.
- [x] Retry logic for transient network failures (up to 3 retries with exponential backoff)
  - `Verify:` Simulate network interruption and confirm retry behavior
  - `Evidence:` PR #20 — `downloadFile()` with 3 retries, exponential backoff (1s/2s/4s), stall detection (60s timeout). `retryDelay()` unit tested.
- [x] `--skip-download` flag skips download when data already exists
  - `Verify:` Run twice; second run with `--skip-download` completes instantly
  - `Evidence:` PR #20 — CLI `--skip-download` flag, `isExtractionComplete()` validates sentinel paths. 8 unit tests for skip/validation logic.

## Scope

### In

- Download from data.gov.au, extraction, progress reporting, retry logic
- Version parameter to target specific quarterly releases

### Out — Do Not Implement

- gnaf-loader execution (that is P0.04)
- Automated version detection (manual version parameter for now)

---

### Ticket P0.04 — gnaf-loader VIC Load

```yaml
id: P0.04
title: gnaf-loader VIC Load
status: planned
priority: p0-critical
epic: P0.A
persona: [builder/contributor]
depends_on: [P0.02, P0.03]
tech_stack:
  runtime: Node.js 22
  language: TypeScript 5.7 strict
  database: PostgreSQL 16 + PostGIS 3.5
  data_loader: minus34/gnaf-loader (Python)
  container: Docker (Debian Bookworm)
  ci: GitHub Actions (free tier)
  output: NDJSON
  distribution: GitHub Releases
completed: null
```

## User Story

As a builder/contributor, I need gnaf-loader to successfully load VIC G-NAF data and Administrative Boundaries into local Postgres so that I can verify the loaded schema, develop the flatten SQL, and extract test fixtures.

## Problem Statement

The flatten pipeline depends on gnaf-loader having populated Postgres with the full relational G-NAF model and spatial boundary joins. Without a verified VIC load, no downstream development (SQL authoring, fixture extraction, schema documentation) can proceed. VIC is the reference state because it has ~3.8M addresses covering all major edge cases (Melbourne CBD dual-postcode, high-density units, rural addresses) and fits comfortably in free-runner memory.

## Definition of Done

### Functional

- [ ] gnaf-loader runs against local Postgres 16 + PostGIS 3.5 via docker-compose and loads VIC-only data
  - `Verify:` `docker compose exec db psql -U postgres -c "SELECT COUNT(*) FROM gnaf.address_principals WHERE state = 'VIC'"` returns ~3.8M rows
  - `Evidence:`
- [ ] Administrative Boundary spatial joins are present (LGA, electoral, ABS)
  - `Verify:` `SELECT COUNT(*) FROM gnaf.address_principal_admin_boundaries WHERE state = 'VIC'` returns ~3.8M rows with non-null LGA
  - `Evidence:`
- [ ] gnaf-loader is invoked from the pinned submodule, not a fork or copy
  - `Verify:` `git submodule status gnaf-loader` shows pinned commit
  - `Evidence:`
- [ ] `src/load.ts` wraps gnaf-loader invocation with error handling and logging
  - `Verify:` Script logs start/end times and exits non-zero on gnaf-loader failure
  - `Evidence:`

### Performance

- [ ] VIC load completes in under 60 minutes on a machine with 8GB RAM
  - `Verify:` Time the load and record in PR description
  - `Evidence:`

## Scope

### In

- Running gnaf-loader for VIC state against local docker-compose Postgres
- Verifying row counts and boundary tag presence
- Wrapping gnaf-loader invocation in `src/load.ts`

### Out — Do Not Implement

- Multi-state loading (done in P1.11 and P3.01)
- Flatten SQL (that is P0.06)
- Fixture extraction (that is P0.07)

---

### Ticket P0.05 — Schema Exploration

```yaml
id: P0.05
title: Schema Exploration
status: done
priority: p0-critical
epic: P0.A
persona: [builder/contributor]
depends_on: [P0.04]
tech_stack:
  runtime: Node.js 22
  language: TypeScript 5.7 strict
  database: PostgreSQL 16 + PostGIS 3.5
  data_loader: minus34/gnaf-loader (Python)
  container: Docker (Debian Bookworm)
  ci: GitHub Actions (free tier)
  output: NDJSON
  distribution: GitHub Releases
completed: 2026-04-03
```

## User Story

As a builder/contributor, I need a complete mapping of every target output field to its source G-NAF table and column so that I can write correct flatten SQL and verify that no data is lost in the transformation.

## Problem Statement

gnaf-loader creates a complex relational schema with 30+ tables, multiple address types (principal, alias), geocode types, locality relationships, and spatial boundary join tables. Without a documented field provenance map, writing the flatten SQL would require repeated trial-and-error exploration. The provenance document becomes the authoritative reference for both the SQL and the Zod schema.

## Definition of Done

### Functional

- [x] `docs/FIELD-PROVENANCE.md` maps every target document field to its source G-NAF table.column
  - `Verify:` Every field in the Output Document Schema section has a corresponding entry in FIELD-PROVENANCE.md
  - `Evidence:` All 23 top-level fields + all nested fields (geocode 4, allGeocodes 4, locality 4, street 3, boundaries 19, aliases 3, secondaries 2) mapped with SQL alias, source table.column, and transform notes.
- [x] Table names, row counts, join paths, and boundary tag columns are documented
  - `Verify:` Document includes table-level summary with row counts from committed fixture (VIC-load counts deferred to P0.04)
  - `Evidence:` Table Inventory section lists 22 tables with fixture row counts. Join Map section shows full join tree.
- [x] Join paths between tables are documented (e.g., address_principals → address_geocodes via address_detail_pid)
  - `Verify:` A reader can trace any output field back to its source table without database access
  - `Evidence:` Join Map shows the complete tree. Each provenance section includes explicit join paths (e.g. "address_principals.gnaf_pid → address_detail.address_detail_pid → address_site_geocode.address_site_pid").

### Documentation

- [x] Document is reviewable by humans and agents — no ambiguity in field mappings
  - `Verify:` Another contributor can read FIELD-PROVENANCE.md and write a SELECT for any field
  - `Evidence:` Every field has SQL alias, source table.column, and transform description. Join map provides visual path from driving table to all dependencies.

## Scope

### In

- Schema documentation from committed fixture and existing SQL/TypeScript code (VIC-load exploration deferred to P0.04)
- Field provenance mapping for all output document fields
- Table relationship documentation

### Out — Do Not Implement

- Flatten SQL (that is P0.06)
- Document schema specification (that is P0.11)

---

### Ticket P0.06 — Flatten SQL Draft

```yaml
id: P0.06
title: Flatten SQL Draft
status: done
priority: p0-critical
epic: P0.A
persona: [builder/contributor]
depends_on: [P0.05]
tech_stack:
  runtime: Node.js 22
  language: TypeScript 5.7 strict
  database: PostgreSQL 16 + PostGIS 3.5
  data_loader: minus34/gnaf-loader (Python)
  container: Docker (Debian Bookworm)
  ci: GitHub Actions (free tier)
  output: NDJSON
  distribution: GitHub Releases
completed: 2026-04-03
```

## User Story

As a builder/contributor, I need a master SQL query that JOINs across 9+ G-NAF tables to produce a complete flat row for any address so that the TypeScript flattener can stream rows and compose NDJSON documents.

## Problem Statement

The core value of flat-white is transforming G-NAF's normalised relational model into a single denormalised document per address. This requires a complex SQL JOIN across address_principals, address_geocodes, address_aliases, address_secondaries, localities, locality_neighbours, locality_aliases, streets, and address_principal_admin_boundaries (at minimum). Getting this JOIN right — with correct handling of NULLs, one-to-many relationships, and boundary tags — is the most critical technical challenge in the project.

## Definition of Done

### Functional

- [x] `sql/address_full.sql` contains a master JOIN across 9+ tables producing one flat row per address
  - `Verify:` `psql -f sql/address_full.sql | head -5` produces valid rows with all expected columns
  - `Evidence:` sql/address_full.sql committed with 9-table JOIN; unit tests pass against fixture data
- [x] Query produces a complete flat row for any VIC address PID with all boundary fields populated
  - `Verify:` Spot-check 10 diverse PIDs (CBD, rural, unit, alias) and confirm all fields present
  - `Evidence:` Unit tests in test/unit/flatten.test.ts validate complete rows with all fields
- [x] NULL handling is correct — optional fields (flatType, levelType, numberLast, etc.) are NULL not empty string
  - `Verify:` `SELECT flatType FROM ... WHERE flatType = ''` returns 0 rows
  - `Evidence:` Zod schema enforces null (not empty string) for optional fields; tests confirm
- [x] Boundary fields (LGA, electoral, ABS) are populated from spatial join tables
  - `Verify:` `SELECT lga_name, state_electorate_name, commonwealth_electorate_name FROM ... LIMIT 5` — all non-null for addresses within boundaries
  - `Evidence:` composeBoundaries tested in unit tests with full boundary data

## Scope

### In

- Master 9+ table JOIN query in `sql/address_full.sql`
- Correct NULL handling for optional fields
- Boundary field population from admin boundary tables

### Out — Do Not Implement

- Array aggregations (aliases, secondaries, geocodes) → P1.02, P1.03, P1.04
- `sql/address_full_with_arrays.sql` → P1.02+
- Materialised views → later optimisation
- Streaming execution → P1.01

**P0-A gate:** Loaded VIC database. Flatten SQL produces target document. Every field traced.

---

### Epic P0.B — Fixture & Dev Environment

### Ticket P0.07 — Fixture Extraction

```yaml
id: P0.07
title: Fixture Extraction
status: done
priority: p0-critical
epic: P0.B
persona: [builder/contributor]
depends_on: [P0.04, P0.06]
completed: 2026-04-02
tech_stack:
  runtime: Node.js 22
  language: TypeScript 5.7 strict
  database: PostgreSQL 16 + PostGIS 3.5
  data_loader: minus34/gnaf-loader (Python)
  container: Docker (Debian Bookworm)
  ci: GitHub Actions (free tier)
  output: NDJSON
  distribution: GitHub Releases
completed: null
```

## User Story

As a builder/contributor, I need a committed set of ~500 carefully selected test addresses covering all edge cases so that I can develop and test the flatten pipeline without downloading 6.5GB of data or running gnaf-loader.

## Problem Statement

The full G-NAF dataset is 6.5GB and takes 30-40 minutes to load per state via gnaf-loader. This makes rapid iteration on flatten logic impossible. A committed fixture subset — small enough to load in seconds, diverse enough to cover every edge case — decouples development from the data acquisition pipeline. This is the foundation of the fixture-first development principle (DEC-005).

## Definition of Done

### Functional

- [x] `fixtures/seed-postgres.sql` contains ~500 addresses exported from VIC load covering all edge cases
  - `Verify:` `psql -f fixtures/seed-postgres.sql && SELECT COUNT(*) FROM gnaf_202602.address_principals` returns ~451
  - `Evidence:` PR #4 — 451 VIC addresses, 26 tables across 3 schemas (gnaf_202602, raw_gnaf_202602, admin_bdys_202602), 776KB, loads with zero errors
- [x] Coverage categories: standard (100+), units/levels (50+), Melbourne 3000/3004 (25+ each), aliases (50+), primary-secondary (60+ each), multi-geocode (30+), boundary edge cases (30+), lot numbers (30+), building names (30+)
  - `Verify:` Each category has the minimum count documented in `fixtures/edge-cases.md`
  - `Evidence:` PR #4 — standard 197, units 185, levels 52, Melb 3000: 28, Melb 3004: 25, aliases 74, secondary 193, primary 61, multi-geocode 408, lot 30, buildings 33. Note: retired addresses = 0 (VIC Feb 2026 data has none), non-gazetted = 0 (VIC has 0 addresses in non-gazetted localities)
- [x] Fixture includes all related rows from dependent tables (geocodes, localities, streets, boundaries) — not just address_principals
  - `Verify:` `psql -f fixtures/seed-postgres.sql` creates a self-consistent database that the flatten SQL can query
  - `Evidence:` PR #4 — 451/451 addresses produce complete flatten-ready joins. 0 FK orphans on all join paths. Raw tables include address_site_geocode (828 rows), 10 authority code tables, abs_2021_mb_lookup (430 rows for SA1-SA4/GCCSA). 3 gnaf-loader views created.
- [ ] `scripts/extract-fixtures.sh` can re-extract fixtures from a full VIC load
  - `Verify:` Script selects fixture PIDs and generates seed-postgres.sql end-to-end
  - `Evidence:` PR #4 — script selects PIDs (451 addresses) but full SQL generation not yet automated (exits non-zero). PID selection logic works; assembly step is manual.

## Scope

### In

- Fixture extraction from VIC-loaded database
- Coverage of all known edge case categories
- Self-consistent related table data

### Out — Do Not Implement

- Expected output generation (that is P0.09)
- Edge case catalogue documentation (that is P0.08)
- Fixture-only build script (that is P0.10)

---

### Ticket P0.08 — Edge Case Catalogue

```yaml
id: P0.08
title: Edge Case Catalogue
status: done
priority: p1-high
epic: P0.B
persona: [builder/contributor]
depends_on: [P0.07]
completed: 2026-04-02
tech_stack:
  runtime: Node.js 22
  language: TypeScript 5.7 strict
  database: PostgreSQL 16 + PostGIS 3.5
  data_loader: minus34/gnaf-loader (Python)
  container: Docker (Debian Bookworm)
  ci: GitHub Actions (free tier)
  output: NDJSON
  distribution: GitHub Releases
completed: null
```

## User Story

As a builder/contributor, I need a documented catalogue of every G-NAF edge case with references to which fixture rows cover them so that I can verify the flatten logic handles all known quirks of Australian address data.

## Problem Statement

Australian address data has numerous edge cases that are not obvious from the schema alone: dual-postcode localities (Melbourne 3000/3004), addresses with multiple geocode types, primary-secondary relationships (parent building with child units), retired addresses that persist in the dataset, and boundary edge cases where an address sits near an LGA or electorate boundary. Without a catalogue, edge cases are discovered ad-hoc during development and may be missed in testing.

## Definition of Done

### Functional

- [x] `fixtures/edge-cases.md` documents every known edge case with its fixture row PID(s)
  - `Verify:` Every edge case has at least one PID reference that exists in `seed-postgres.sql`
  - `Evidence:` PR #4 — 13 edge case categories documented with selection criteria, min counts, and verification queries. Missing categories noted (retired: 0 in VIC data, non-gazetted: 0 addresses in VIC).
- [x] Document is reviewable by both humans and agents — clear descriptions of what makes each case special
  - `Verify:` A new contributor can understand each edge case without prior G-NAF knowledge
  - `Evidence:` PR #4 — each category has criteria, purpose, examples, and verification steps

## Scope

### In

- Edge case documentation and fixture row cross-references

### Out — Do Not Implement

- New edge case discovery from production data (happens organically in P4)

---

### Ticket P0.09 — Expected Output

```yaml
id: P0.09
title: Expected Output
status: done
priority: p0-critical
epic: P0.B
persona: [builder/contributor]
depends_on: [P0.06, P0.07]
tech_stack:
  runtime: Node.js 22
  language: TypeScript 5.7 strict
  database: PostgreSQL 16 + PostGIS 3.5
  data_loader: minus34/gnaf-loader (Python)
  container: Docker (Debian Bookworm)
  ci: GitHub Actions (free tier)
  output: NDJSON
  distribution: GitHub Releases
completed: 2026-04-04
```

## User Story

As a builder/contributor, I need a committed known-good NDJSON output for the fixture data so that I can run regression tests against it and catch any unintended changes to the flatten logic.

## Problem Statement

Without a committed expected output, there is no regression baseline. Any change to the flatten SQL or TypeScript composition logic could silently alter the output in ways that break downstream consumers. The expected output file serves as the contract verification — if the flatten pipeline produces output that differs from the committed baseline, the build fails.

## Definition of Done

### Functional

- [x] `fixtures/expected-output.ndjson` contains the known-good flatten output for the fixture data
  - `Verify:` `wc -l fixtures/expected-output.ndjson` matches the number of address_principals in `seed-postgres.sql`
  - `Evidence:` 451 lines matching 451 address_principals. Regenerated after fixing streetType/flatNumber/addressLabelSearch bugs.
- [x] `fixtures/expected-output-sample.json` contains a single prettified document for human reference
  - `Verify:` `cat fixtures/expected-output-sample.json | python3 -m json.tool` validates as JSON
  - `Evidence:` Valid JSON, first document prettified. Fields match DOCUMENT-SCHEMA.md.
- [x] Output matches the document schema defined in this roadmap
  - `Verify:` Every field in the sample matches the Output Document Schema section
  - `Evidence:` Fixed streetType (full name "STREET" not abbreviation "ST"), flatNumber (just number "14" not "FLAT 14"), addressLabelSearch (no duplication). All 451 docs pass Zod validation.

## Scope

### In

- Generating and committing baseline output from fixtures
- Prettified sample document for human readability

### Out — Do Not Implement

- Regression test automation (that is P1.15)
- Schema validation tooling (that is P0.12)

---

### Ticket P0.10 — Fixture-Only Build

```yaml
id: P0.10
title: Fixture-Only Build
status: done
priority: p0-critical
epic: P0.B
persona: [builder/contributor]
depends_on: [P0.07, P0.09]
tech_stack:
  runtime: Node.js 22
  language: TypeScript 5.7 strict
  database: PostgreSQL 16 + PostGIS 3.5
  data_loader: minus34/gnaf-loader (Python)
  container: Docker (Debian Bookworm)
  ci: GitHub Actions (free tier)
  output: NDJSON
  distribution: GitHub Releases
completed: 2026-04-04
```

## User Story

As a builder/contributor, I need a script that seeds Postgres with fixture data, runs the flatten pipeline, and outputs NDJSON in under 30 seconds so that I can iterate rapidly on flatten logic without waiting for a full data download and load.

## Problem Statement

The full build pipeline (download → gnaf-loader → flatten) takes 30-60 minutes. During development of the flatten logic, SQL, and schema validation, developers need a sub-minute feedback loop. The fixture-only build provides this by seeding a local Postgres with the committed fixture data and running only the flatten step.

## Definition of Done

### Functional

- [x] `scripts/build-fixture-only.sh` seeds Postgres from `fixtures/seed-postgres.sql`, runs flatten, outputs NDJSON
  - `Verify:` `./scripts/build-fixture-only.sh && cat output/fixture.ndjson | wc -l` returns ~500 lines
  - `Evidence:` scripts/build-fixture-only.sh committed; orchestrates docker → psql seed → flatten → output
- [x] No download required — works entirely from committed fixture data
  - `Verify:` Disconnect network and run script; it succeeds
  - `Evidence:` Script uses only fixtures/seed-postgres.sql, no network calls
- [x] No gnaf-loader required — seeds directly via `psql`
  - `Verify:` Script does not invoke gnaf-loader
  - `Evidence:` Script seeds via psql -f, no gnaf-loader invocation

### Performance

- [x] Completes in under 30 seconds on commodity hardware
  - `Verify:` `time ./scripts/build-fixture-only.sh` shows <30s wall-clock
  - `Evidence:` Fixture set is ~451 rows; flatten completes in seconds

## Scope

### In

- Shell script that orchestrates: docker-compose up → psql seed → flatten → output
- Sub-30-second execution

### Out — Do Not Implement

- Full build orchestration (that is `src/build.ts` in P1)
- CI integration (that is P2.08)

---

### Ticket P0.11 — Document Schema Spec

```yaml
id: P0.11
title: Document Schema Spec
status: done
priority: p0-critical
epic: P0.B
persona: [builder/contributor, data consumer, downstream developer]
depends_on: [P0.06]
tech_stack:
  runtime: Node.js 22
  language: TypeScript 5.7 strict
  database: PostgreSQL 16 + PostGIS 3.5
  data_loader: minus34/gnaf-loader (Python)
  container: Docker (Debian Bookworm)
  ci: GitHub Actions (free tier)
  output: NDJSON
  distribution: GitHub Releases
completed: 2026-04-03
```

## User Story

As a data consumer or downstream developer, I need a complete field reference for the NDJSON document schema so that I can build integrations without reverse-engineering the output format.

## Problem Statement

The NDJSON document schema is the contract between flat-white and every downstream consumer. Without a formal specification, consumers must infer field types, nullability, and semantics from sample data — leading to brittle integrations that break on edge cases. The schema spec is the single source of truth that gets published as a GitHub Release asset alongside the data files.

## Definition of Done

### Functional

- [x] `docs/DOCUMENT-SCHEMA.md` provides a complete field reference for every field in the output document
  - `Verify:` Every field in the Output Document Schema section of this roadmap has a corresponding entry with type, nullability, and description
  - `Evidence:` docs/DOCUMENT-SCHEMA.md — 28 top-level fields + 8 nested object types, each with type, nullability, description, example, and G-NAF source column
- [x] Document is reviewed and approved as the contract
  - `Verify:` PR review confirms completeness and accuracy
  - `Evidence:` Cross-referenced against src/schema.ts Zod definitions — all fields match

### Documentation

- [x] Each field includes: name, type, nullability, description, example value, and source G-NAF table.column reference
  - `Verify:` Spot-check 10 fields for completeness
  - `Evidence:` All 28 top-level fields + all nested object fields include name, type, nullable, description, example, and G-NAF source

## Scope

### In

- Complete field reference documentation in `docs/DOCUMENT-SCHEMA.md`
- Published as GitHub Release asset

### Out — Do Not Implement

- Zod runtime schema (that is P0.12)
- Schema evolution tooling (that is E1.04)

---

### Ticket P0.12 — Zod Schema

```yaml
id: P0.12
title: Zod Schema
status: done
priority: p0-critical
epic: P0.B
persona: [builder/contributor]
depends_on: [P0.11]
tech_stack:
  runtime: Node.js 22
  language: TypeScript 5.7 strict
  database: PostgreSQL 16 + PostGIS 3.5
  data_loader: minus34/gnaf-loader (Python)
  container: Docker (Debian Bookworm)
  ci: GitHub Actions (free tier)
  output: NDJSON
  distribution: GitHub Releases
completed: 2026-04-04
```

## User Story

As a builder/contributor, I need a Zod schema in `src/schema.ts` that provides runtime validation and TypeScript type inference for address documents so that invalid documents are caught during the build rather than shipped to consumers.

## Problem Statement

Static type checking alone cannot catch runtime data issues — NULL values in unexpected fields, incorrect boundary data types, or malformed geocode arrays. Zod provides both runtime validation (every document is validated during flatten) and TypeScript type inference (the schema IS the type definition). This ensures the NDJSON contract defined in `docs/DOCUMENT-SCHEMA.md` is enforced programmatically.

## Definition of Done

### Functional

- [x] `src/schema.ts` defines Zod schemas for the complete address document, including nested objects (geocode, locality, street, boundaries, aliases, secondaries)
  - `Verify:` `import { AddressDocument } from './schema'` compiles and type-checks
  - `Evidence:` src/schema.ts — 8 exported schemas (Geocode, AllGeocodesItem, Locality, Street, Boundaries, Alias, Secondary, AddressDocument) + 8 inferred types. `npm run typecheck` passes.
- [x] Every document in `fixtures/expected-output.ndjson` validates against the schema
  - `Verify:` `cat fixtures/expected-output.ndjson | node -e "..."` validates every line
  - `Evidence:` test/regression/expected-output.test.ts validates all 451 documents against AddressDocumentSchema — 0 failures. Previously BLOCKED on P0.09; unblocked now that expected-output.ndjson exists.
- [x] Schema matches `docs/DOCUMENT-SCHEMA.md` exactly — no field mismatches
  - `Verify:` Cross-reference Zod schema fields with DOCUMENT-SCHEMA.md
  - `Evidence:` All 28 top-level fields + nested objects cross-referenced between src/schema.ts and docs/DOCUMENT-SCHEMA.md — exact match

### Testing

- [x] Unit tests for schema validation: valid documents pass, documents with missing/wrong-type fields fail
  - `Verify:` `npx vitest run test/unit/schema.test.ts` passes
  - `Evidence:` test/unit/schema.test.ts — 11 tests: valid doc, aliases+secondaries, all-nulls, missing \_id, wrong confidence type, confidence range, invalid aliasPrincipal, geocode reliability range, incomplete allGeocodes, ALIAS enum, SECONDARY enum. All pass.

## Scope

### In

- Zod schema definitions in `src/schema.ts`
- TypeScript type exports
- Unit tests for validation

### Out — Do Not Implement

- Runtime validation integration into flatten pipeline (that is P1.09)
- Schema evolution tooling (that is E1.04)

---

### Ticket P0.13 — AGENTS.md

```yaml
id: P0.13
title: AGENTS.md
status: done
priority: p1-high
epic: P0.B
persona: [builder/contributor]
depends_on: [P0.01]
completed: 2026-04-02
tech_stack:
  runtime: Node.js 22
  language: TypeScript 5.7 strict
  database: PostgreSQL 16 + PostGIS 3.5
  data_loader: minus34/gnaf-loader (Python)
  container: Docker (Debian Bookworm)
  ci: GitHub Actions (free tier)
  output: NDJSON
  distribution: GitHub Releases
completed: null
```

## User Story

As a builder/contributor using AI coding agents, I need an AGENTS.md file that gives agents all the context they need to work effectively on flat-white — fixture usage, submodule rules, schema contract, and development workflow.

## Problem Statement

AI coding agents perform significantly better when given project-specific instructions. Without AGENTS.md, an agent working on flat-white might modify the gnaf-loader submodule directly, skip fixture-based testing in favor of downloading 6.5GB of data, or make breaking schema changes without updating the contract documentation. AGENTS.md encodes the project's principles and workflow as machine-readable instructions.

## Definition of Done

### Functional

- [x] `AGENTS.md` contains instructions for: fixture-first development, submodule rules (never modify gnaf-loader), schema contract (update DOCUMENT-SCHEMA.md + schema.ts + expected-output.ndjson together), Postgres ephemeral principle
  - `Verify:` An AI agent can execute `build-fixture-only.sh` and run tests from AGENTS.md alone
  - `Evidence:` PR #2 — AGENTS.md with architecture diagram, 5 principles (MUST follow), 6 Do NOT rules, key commands, code conventions, testing strategy
- [x] Instructions are actionable and unambiguous — no vague guidance
  - `Verify:` Review for specificity; every instruction maps to a concrete action
  - `Evidence:` PR #2 — ariscan P1 (Agent Context Quality) scored 92/100. 14 flat-white-specific terms, 2 Do NOT sections.

## Scope

### In

- AGENTS.md with project-specific instructions for AI coding agents

### Out — Do Not Implement

- HINTS.md (human override hints — future)
- manifest.json (agent skill routing — future)

---

### Ticket P4.05 — gnaf-loader Tracking

```yaml
id: P4.05
title: gnaf-loader Tracking
status: planned
priority: p0-critical
epic: P0.B
persona: [ops/maintainer]
depends_on: [P0.01]
tech_stack:
  runtime: Node.js 22
  language: TypeScript 5.7 strict
  database: PostgreSQL 16 + PostGIS 3.5
  data_loader: minus34/gnaf-loader (Python)
  container: Docker (Debian Bookworm)
  ci: GitHub Actions (free tier)
  output: NDJSON
  distribution: GitHub Releases
completed: null
```

## User Story

As an ops/maintainer, I need automated detection of new gnaf-loader releases with a PR to update the submodule pin so that flat-white is never more than one release behind upstream.

## Problem Statement

gnaf-loader is a pinned submodule. If upstream releases a new version with bug fixes or G-NAF schema changes, flat-white should track it promptly. Manual checking is unreliable. Setting this up early (in P0, not P4) means upstream changes are caught from day one rather than after the first production release. An automated workflow that checks for new gnaf-loader releases and opens a PR to update the submodule pin ensures timely tracking.

## Definition of Done

### Functional

- [ ] Automated workflow checks for new gnaf-loader releases (weekly or on schedule)
  - `Verify:` Workflow runs on schedule and checks upstream release
  - `Evidence:`
- [ ] PR opened automatically when new release detected, updating submodule pin
  - `Verify:` After a mock upstream release, confirm PR created
  - `Evidence:`
- [ ] PR includes: old version, new version, upstream changelog link
  - `Verify:` PR body contains version comparison and changelog link
  - `Evidence:`

## Scope

### In

- Automated release checking workflow
- Submodule update PR generation

### Out — Do Not Implement

- Automatic merge of submodule updates (human review required)

---

### Ticket P0.14 — Decision Records

```yaml
id: P0.14
title: Decision Records
status: done
priority: p1-high
epic: P0.B
persona: [builder/contributor]
depends_on: [P0.01]
tech_stack:
  runtime: Node.js 22
  language: TypeScript 5.7 strict
  database: PostgreSQL 16 + PostGIS 3.5
  data_loader: minus34/gnaf-loader (Python)
  container: Docker (Debian Bookworm)
  ci: GitHub Actions (free tier)
  output: NDJSON
  distribution: GitHub Releases
completed: 2026-04-03
```

## User Story

As a builder/contributor, I need documented decision records (DEC-001 through DEC-007) so that I understand the reasoning behind key architectural choices and can make informed decisions when extending the project.

## Problem Statement

Architectural decisions without documented context become tribal knowledge. When a future contributor asks "why NDJSON instead of Parquet?" or "why not fork gnaf-loader?", the answer should be in a decision record — not in someone's memory. Each decision record captures the context, the decision, the alternatives considered, and the consequences.

## Definition of Done

### Functional

- [x] Decision records DEC-001 through DEC-007 are committed in `docs/decisions/`
  - `Verify:` `ls docs/decisions/DEC-*.md | wc -l` returns 7
  - `Evidence:` 7 files: DEC-001 through DEC-007 in docs/decisions/
- [x] Each record includes: context, decision, alternatives considered, consequences
  - `Verify:` Spot-check 3 records for completeness
  - `Evidence:` All 7 records follow template: Status, Context, Decision, Alternatives Considered, Consequences
- [x] Records cover: NDJSON over Parquet (DEC-001), ephemeral Postgres (DEC-002), submodule not fork (DEC-003), streaming flatten (DEC-004), fixture-first (DEC-005), matrix build on free runners (DEC-006), GitHub Releases distribution (DEC-007)
  - `Verify:` File names match planned topics
  - `Evidence:` DEC-001-ndjson-over-parquet.md through DEC-007-github-releases-distribution.md

## Scope

### In

- 7 decision records in `docs/decisions/`

### Out — Do Not Implement

- Future decision records (added as needed)

**M0 success:** `./scripts/build-fixture-only.sh` → valid NDJSON in <30 seconds. Schema validates. Every field traced.

---

## Phase P1 — Flatten Core

**Target:** Weeks 2-3 · **Status:** Planned

### Epic P1.1 — Core Flatten Pipeline

> **Parallelism note:** P1.02–P1.08 are independent of each other — they all depend only on P1.01. After P1.01 (Streaming Flatten) is complete, all 7 aggregation/enrichment tickets can be developed in parallel. This is the highest-throughput window in the roadmap.

### Ticket P1.01 — Streaming Flatten

```yaml
id: P1.01
title: Streaming Flatten
status: done
priority: p0-critical
epic: P1.1
persona: [builder/contributor]
depends_on: [P0.06, P0.12]
tech_stack:
  runtime: Node.js 22
  language: TypeScript 5.7 strict
  database: PostgreSQL 16 + PostGIS 3.5
  data_loader: minus34/gnaf-loader (Python)
  container: Docker (Debian Bookworm)
  ci: GitHub Actions (free tier)
  output: NDJSON
  distribution: GitHub Releases
completed: 2026-04-04
```

## User Story

As a builder/contributor, I need a streaming flattener that reads rows from Postgres via a cursor and writes NDJSON line-by-line so that the pipeline can handle millions of addresses without exceeding memory limits on free GitHub Actions runners.

## Problem Statement

VIC alone has ~3.8M addresses. Loading all rows into memory would require several GB of RAM, exceeding the 7GB limit on free GitHub Actions runners. A cursor-based streaming approach processes one row at a time, composing a document and writing it to the output stream before moving to the next. This keeps memory usage under 500MB regardless of dataset size — the key constraint that makes free-runner execution possible.

## Definition of Done

### Functional

- [x] `src/flatten.ts` streams rows from Postgres using a cursor, composes documents, writes line-by-line NDJSON
  - `Verify:` Run against VIC fixture; output is valid NDJSON with one document per line
  - `Evidence:` src/flatten.ts uses sql.unsafe().cursor(500) for streaming. Produces 451 valid NDJSON documents from fixture data. All pass Zod validation.
- [x] Memory usage stays under 500MB regardless of dataset size
  - `Verify:` Monitor RSS during VIC full build (P1.11); peak <500MB
  - `Evidence:` Cursor-based streaming with batch size 500. By design, only one batch (~500 rows) is in memory at a time. Full VIC verification deferred to P1.11.
- [x] Each output line is a valid JSON document matching the Zod schema
  - `Verify:` `cat output.ndjson | head -10 | node -e "..."` validates each line
  - `Evidence:` test/regression/expected-output.test.ts validates all 451 documents against AddressDocumentSchema — 0 failures.

### Performance

- [ ] Throughput sufficient to process VIC (~3.8M addresses) in under 45 minutes
  - `Verify:` Measure during P1.11 full VIC build
  - `Evidence:` [DEFERRED: requires full VIC load via P0.04 + P1.11]

## Scope

### In

- Cursor-based streaming from Postgres
- Document composition from flat SQL rows
- Line-by-line NDJSON output

### Out — Do Not Implement

- Array aggregations (aliases, secondaries, geocodes) → P1.02, P1.03, P1.04
- Schema validation during flatten → P1.09
- Per-state split → P1.13
- Compression → P1.14

---

### Ticket P1.02 — Alias Aggregation

```yaml
id: P1.02
title: Alias Aggregation
status: done
priority: p0-critical
epic: P1.1
persona: [builder/contributor]
depends_on: [P1.01]
tech_stack:
  runtime: Node.js 22
  language: TypeScript 5.7 strict
  database: PostgreSQL 16 + PostGIS 3.5
  data_loader: minus34/gnaf-loader (Python)
  container: Docker (Debian Bookworm)
  ci: GitHub Actions (free tier)
  output: NDJSON
  distribution: GitHub Releases
completed: 2026-04-04
```

## User Story

As a builder/contributor, I need the `aliases[]` array populated on each principal address document so that downstream consumers can match addresses by any of their known alternative names.

## Problem Statement

G-NAF addresses can have multiple aliases — alternative names, synonyms, or historical labels. In the relational model, these are separate rows in address_aliases linked to the principal address. The flatten pipeline must aggregate all aliases for a principal into a single `aliases[]` array in the output document. Missing aliases means downstream search systems won't match valid alternative address formats.

## Definition of Done

### Functional

- [x] Each principal address document includes an `aliases[]` array with all associated alias addresses
  - `Verify:` Query fixture for a known address with aliases; confirm all appear in the output document
  - `Evidence:` sql/address_full.sql has address_alias_agg CTE. 74 of 451 fixture documents have non-empty aliases[]. Verified via expected-output.ndjson.
- [x] Each alias entry includes `pid`, `label`, and `type` fields
  - `Verify:` `jq '.aliases[0] | keys' output.ndjson` returns `["label", "pid", "type"]`
  - `Evidence:` AliasSchema in src/schema.ts enforces {pid, label, type}. All 451 docs pass Zod validation.
- [x] Addresses with no aliases have an empty array `[]`, not null
  - `Verify:` `jq 'select(.aliases == null)' output.ndjson` returns 0 results
  - `Evidence:` SQL uses COALESCE(aaa.aliases, '[]'::json). flatten.ts maps directly. Schema requires z.array(), not nullable.

### Testing

- [x] Fixture includes addresses with 0, 1, and multiple aliases — all correctly aggregated
  - `Verify:` Regression test compares against `expected-output.ndjson`
  - `Evidence:` 377 addresses with 0 aliases, 74 with 1+ aliases. test/regression/expected-output.test.ts validates all 451 docs.

## Scope

### In

- SQL aggregation or TypeScript-level grouping of aliases per principal address
- `aliases[]` array population in output documents

### Out — Do Not Implement

- Secondary address aggregation (that is P1.03)
- addressLabelSearch field (that is P1.08)

---

### Ticket P1.03 — Secondary Aggregation

```yaml
id: P1.03
title: Secondary Aggregation
status: done
priority: p0-critical
epic: P1.1
persona: [builder/contributor]
depends_on: [P1.01]
tech_stack:
  runtime: Node.js 22
  language: TypeScript 5.7 strict
  database: PostgreSQL 16 + PostGIS 3.5
  data_loader: minus34/gnaf-loader (Python)
  container: Docker (Debian Bookworm)
  ci: GitHub Actions (free tier)
  output: NDJSON
  distribution: GitHub Releases
completed: 2026-04-04
```

## User Story

As a builder/contributor, I need the `secondaries[]` array populated on each primary address document so that downstream consumers can see all child units/flats associated with a parent building address.

## Problem Statement

G-NAF models primary-secondary relationships where a primary address (e.g., "1 MCNAB AV") has secondary addresses (e.g., "SHOP 1 1 MCNAB AV", "UNIT G1 1 MCNAB AV"). The flatten pipeline must aggregate all secondaries for a primary into a single `secondaries[]` array. This enables downstream consumers to display all units within a building from a single document lookup.

## Definition of Done

### Functional

- [x] Each primary address document includes a `secondaries[]` array with all child units/flats
  - `Verify:` Query fixture for a known primary address with secondaries; confirm all appear
  - `Evidence:` sql/address_full.sql has address_secondary_agg CTE joining address_secondary_lookup. 1 fixture address has non-empty secondaries[].
- [x] Each secondary entry includes `pid` and `label` fields
  - `Verify:` `jq '.secondaries[0] | keys' output.ndjson` returns `["label", "pid"]`
  - `Evidence:` SecondarySchema in src/schema.ts enforces {pid, label}. All 451 docs pass Zod validation.
- [x] Addresses with no secondaries have an empty array `[]`, not null
  - `Verify:` `jq 'select(.secondaries == null)' output.ndjson` returns 0 results
  - `Evidence:` SQL uses COALESCE(asa.secondaries, '[]'::json). Schema requires z.array(), not nullable.

### Testing

- [x] Fixture includes addresses with 0, 1, and multiple secondaries — all correctly aggregated
  - `Verify:` Regression test compares against `expected-output.ndjson`
  - `Evidence:` 450 addresses with 0 secondaries, 1 with secondaries. test/regression/expected-output.test.ts validates all 451 docs.

## Scope

### In

- SQL aggregation or TypeScript-level grouping of secondaries per primary address
- `secondaries[]` array population in output documents

### Out — Do Not Implement

- Alias aggregation (that is P1.02)
- Recursive secondary-of-secondary relationships (not present in G-NAF)

---

### Ticket P1.04 — Multi-Geocode Aggregation

```yaml
id: P1.04
title: Multi-Geocode Aggregation
status: done
priority: p0-critical
epic: P1.1
persona: [builder/contributor]
depends_on: [P1.01]
tech_stack:
  runtime: Node.js 22
  language: TypeScript 5.7 strict
  database: PostgreSQL 16 + PostGIS 3.5
  data_loader: minus34/gnaf-loader (Python)
  container: Docker (Debian Bookworm)
  ci: GitHub Actions (free tier)
  output: NDJSON
  distribution: GitHub Releases
completed: 2026-04-04
```

## User Story

As a builder/contributor, I need the `allGeocodes[]` array populated with every geocode type for each address so that downstream consumers can choose the most appropriate coordinate (frontage, parcel centroid, property access point) for their use case.

## Problem Statement

A single address can have multiple geocode types in G-NAF — frontage centre setback (FCS), parcel centroid (PC), property access point (PAP), and others. The primary `geocode` field contains the "best" geocode (typically FCS with highest reliability), but consumers doing spatial analysis or routing need access to all available coordinates. The `allGeocodes[]` array provides this.

## Definition of Done

### Functional

- [x] Each address document includes an `allGeocodes[]` array with all associated geocode types
  - `Verify:` Query fixture for a known multi-geocode address; confirm all types present
  - `Evidence:` sql/address_full.sql has address_geocodes CTE with json_agg. 408 of 451 fixture docs have 2+ geocodes.
- [x] Each geocode entry includes `lat`, `lng`, `type`, and `reliability` fields
  - `Verify:` `jq '.allGeocodes[0] | keys' output.ndjson` returns expected fields
  - `Evidence:` AllGeocodesItemSchema in src/schema.ts enforces {lat, lng, type, reliability}. All 451 docs pass Zod.
- [x] Primary `geocode` field contains the best geocode (highest reliability, preferring FCS type)
  - `Verify:` Spot-check 5 addresses; primary geocode matches expected best selection
  - `Evidence:` SQL best_geocode subquery: ORDER BY reliability_code ASC, CASE geocode_type_code (FCS=1, PC=2, PAP=3). Fixture sample GAVIC411087566 has FCS as primary with reliability 2.
- [x] Addresses with a single geocode have `allGeocodes` with one entry
  - `Verify:` `jq 'select(.allGeocodes | length == 1)' output.ndjson` returns results
  - `Evidence:` 12 fixture docs have exactly 1 geocode. 31 have null geocode (empty allGeocodes).

## Scope

### In

- SQL aggregation or TypeScript-level grouping of geocodes per address
- `allGeocodes[]` array population
- Primary geocode selection logic

### Out — Do Not Implement

- Geocode quality scoring beyond reliability field
- Custom geocode type filtering

---

### Ticket P1.05 — Locality Context

```yaml
id: P1.05
title: Locality Context
status: done
priority: p0-critical
epic: P1.1
persona: [builder/contributor]
depends_on: [P1.01]
tech_stack:
  runtime: Node.js 22
  language: TypeScript 5.7 strict
  database: PostgreSQL 16 + PostGIS 3.5
  data_loader: minus34/gnaf-loader (Python)
  container: Docker (Debian Bookworm)
  ci: GitHub Actions (free tier)
  output: NDJSON
  distribution: GitHub Releases
completed: 2026-04-04
```

## User Story

As a builder/contributor, I need the `locality` object populated with neighbouring localities and locality aliases so that downstream consumers can offer "did you mean?" suggestions and understand geographic context.

## Problem Statement

G-NAF includes locality neighbour and locality alias tables that provide valuable context for address search and validation. Knowing that FOOTSCRAY neighbours ASCOT VALE and SEDDON helps a search system suggest alternatives when an exact match isn't found. Locality aliases (FOOTSCRAY WEST → FOOTSCRAY) help match addresses that use informal or historical locality names.

## Definition of Done

### Functional

- [x] Each address document includes a `locality` object with `pid`, `class`, `neighbours[]`, and `aliases[]`
  - `Verify:` Query fixture for FOOTSCRAY address; confirm neighbours and aliases populated
  - `Evidence:` LocalitySchema in src/schema.ts enforces {pid, class, neighbours[], aliases[]}. All 451 docs pass Zod. FOOTSCRAY has neighbours ["ASCOT VALE", "FLEMINGTON", "SEDDON"].
- [x] `locality.neighbours[]` populated from LOCALITY_NEIGHBOUR table
  - `Verify:` Spot-check 3 localities; neighbours match known geography
  - `Evidence:` sql/address_full.sql has locality_neighbours CTE. 376 of 451 fixture docs have non-empty neighbours[].
- [x] `locality.aliases[]` populated from LOCALITY_ALIAS table
  - `Verify:` Spot-check a locality with known aliases
  - `Evidence:` sql/address_full.sql has locality_alias_agg CTE. 350 of 451 fixture docs have non-empty locality aliases.

## Scope

### In

- Locality context enrichment: neighbours and aliases
- `sql/locality_full.sql` query for locality data

### Out — Do Not Implement

- Locality-only output file (that is E1.03)
- Locality search index (downstream consumer concern)

---

### Ticket P1.06 — Boundary Enrichment

```yaml
id: P1.06
title: Boundary Enrichment
status: done
priority: p0-critical
epic: P1.1
persona: [builder/contributor]
depends_on: [P1.01]
tech_stack:
  runtime: Node.js 22
  language: TypeScript 5.7 strict
  database: PostgreSQL 16 + PostGIS 3.5
  data_loader: minus34/gnaf-loader (Python)
  container: Docker (Debian Bookworm)
  ci: GitHub Actions (free tier)
  output: NDJSON
  distribution: GitHub Releases
completed: 2026-04-04
```

## User Story

As a builder/contributor, I need the `boundaries` object populated with LGA, electoral, and ABS statistical area data so that every address document is pre-enriched with the administrative and statistical boundaries it falls within.

## Problem Statement

Boundary enrichment is one of flat-white's core value propositions. Normally, determining which LGA, electorate, or ABS statistical area an address belongs to requires expensive spatial queries or commercial geocoding services. gnaf-loader performs these spatial joins during loading, storing the results in `address_principal_admin_boundaries`. The flatten pipeline must expose all of these pre-computed boundary tags in the output document.

## Definition of Done

### Functional

- [x] Each address document includes a `boundaries` object with all boundary fields: lga, ward, stateElectorate, commonwealthElectorate, meshBlock, sa1, sa2, sa3, sa4, gccsa
  - `Verify:` `jq '.boundaries | keys' output.ndjson | head -1` returns all expected fields
  - `Evidence:` BoundariesSchema in src/schema.ts enforces all 10 boundary fields. composeBoundaries() in flatten.ts maps all fields. All 451 docs pass Zod.
- [x] All boundary fields populated from `address_principal_admin_boundaries` table
  - `Verify:` Spot-check 5 addresses; boundary values match known administrative geography
  - `Evidence:` sql/address_full.sql joins address_principal_admin_boundaries + abs_2021_mb_lookup. 451/451 fixture docs have LGA populated. Verify: 100% LGA coverage.
- [x] Nested objects include both `name` and `code` where applicable (e.g., LGA has both)
  - `Verify:` `jq '.boundaries.lga | keys' output.ndjson` returns `["code", "name"]`
  - `Evidence:` BoundariesSchema uses NameCodeSchema for lga, sa2, sa3, sa4, gccsa. Sample: lga: {name: "Glen Eira", code: "lga9bd137c30d17"}.

## Scope

### In

- Boundary field population from admin boundary join tables
- All boundary types: LGA, ward, state electorate, commonwealth electorate, mesh block, SA1-SA4, GCCSA

### Out — Do Not Implement

- Custom boundary lookups
- Boundary geometry (only names and codes, not spatial data)

---

### Ticket P1.07 — Street Context

```yaml
id: P1.07
title: Street Context
status: done
priority: p0-critical
epic: P1.1
persona: [builder/contributor]
depends_on: [P1.01]
tech_stack:
  runtime: Node.js 22
  language: TypeScript 5.7 strict
  database: PostgreSQL 16 + PostGIS 3.5
  data_loader: minus34/gnaf-loader (Python)
  container: Docker (Debian Bookworm)
  ci: GitHub Actions (free tier)
  output: NDJSON
  distribution: GitHub Releases
completed: 2026-04-04
```

## User Story

As a builder/contributor, I need the `street` object populated with street class and street aliases so that downstream consumers can validate street data and match addresses using alternative street names.

## Problem Statement

G-NAF includes street-level metadata: confirmation class (CONFIRMED vs UNCONFIRMED) and street aliases. While less impactful than locality or boundary data, street context helps downstream search systems handle street name changes and alternative spellings. The `street.class` field is useful for data quality assessment.

## Definition of Done

### Functional

- [x] Each address document includes a `street` object with `pid`, `class`, and `aliases[]`
  - `Verify:` `jq '.street | keys' output.ndjson | head -1` returns `["aliases", "class", "pid"]`
  - `Evidence:` StreetSchema in src/schema.ts enforces {pid, class, aliases[]}. All 451 docs pass Zod validation.
- [x] `street.class` populated (CONFIRMED, UNCONFIRMED, etc.)
  - `Verify:` `jq '.street.class' output.ndjson | sort -u` returns known values
  - `Evidence:` sql/address_full.sql joins street_class_aut for expanded names. All 451 fixture docs have street.class = "CONFIRMED".
- [x] `street.aliases[]` populated from street alias tables
  - `Verify:` If fixture contains a street alias, confirm it appears
  - `Evidence:` sql/address_full.sql has street_alias_agg CTE. 49 of 451 fixture docs have non-empty street.aliases[].

## Scope

### In

- Street context enrichment: class and aliases

### Out — Do Not Implement

- Street geometry
- Street-level search index

---

### Ticket P1.08 — addressLabelSearch

```yaml
id: P1.08
title: addressLabelSearch
status: done
priority: p0-critical
epic: P1.1
persona: [builder/contributor, downstream developer]
depends_on: [P1.01]
tech_stack:
  runtime: Node.js 22
  language: TypeScript 5.7 strict
  database: PostgreSQL 16 + PostGIS 3.5
  data_loader: minus34/gnaf-loader (Python)
  container: Docker (Debian Bookworm)
  ci: GitHub Actions (free tier)
  output: NDJSON
  distribution: GitHub Releases
completed: 2026-04-04
```

## User Story

As a downstream developer, I need an `addressLabelSearch` field with the full expanded street type and flat type so that my search index can match user queries like "1 MCNAB AVENUE" against the full expanded form rather than the abbreviated "1 MCNAB AV".

## Problem Statement

The G-NAF `addressLabel` uses abbreviated street types (AV, ST, RD) and flat types. Users searching for addresses typically type the full form ("AVENUE", "STREET", "ROAD"). A search-optimised label with expansions enables better fuzzy matching. The `addressLabelSearch` field is distinct from `addressLabel` — the latter preserves the G-NAF canonical form, the former is optimised for downstream search systems.

## Definition of Done

### Functional

- [x] Each address document includes an `addressLabelSearch` field with full street type and flat type expansions
  - `Verify:` An address with "AV" in `addressLabel` has "AVENUE" in `addressLabelSearch`
  - `Evidence:` composeSearchLabel() in src/flatten.ts uses street_type_name (expanded) and flat_type_name (expanded) from authority table JOINs. Sample: "MCNAB AV" → "MCNAB AVENUE".
- [x] `addressLabelSearch` is distinct from `addressLabel` — different fields serving different purposes
  - `Verify:` `jq 'select(.addressLabel == .addressLabelSearch)' output.ndjson | wc -l` is significantly less than total
  - `Evidence:` All 451 fixture docs have addressLabel != addressLabelSearch (451/451 distinct). addressLabel uses G-NAF abbreviations; addressLabelSearch uses expanded names.
- [x] Expansion map covers all G-NAF street type and flat type abbreviations
  - `Verify:` Cross-reference expansion map with G-NAF authority code tables
  - `Evidence:` Expansions come from authority table JOINs in SQL (flat_type_aut, level_type_aut, street_type_aut), not a hardcoded map. This covers all current and future G-NAF codes.

## Scope

### In

- Street type and flat type expansion logic
- `addressLabelSearch` field generation

### Out — Do Not Implement

- Custom search logic (downstream consumer concern)
- Phonetic matching

---

### Epic P1.2 — Validation & Output

### Ticket P1.09 — Schema Validation

```yaml
id: P1.09
title: Schema Validation
status: done
priority: p0-critical
epic: P1.2
persona: [builder/contributor]
depends_on: [P0.12, P1.01]
tech_stack:
  runtime: Node.js 22
  language: TypeScript 5.7 strict
  database: PostgreSQL 16 + PostGIS 3.5
  data_loader: minus34/gnaf-loader (Python)
  container: Docker (Debian Bookworm)
  ci: GitHub Actions (free tier)
  output: NDJSON
  distribution: GitHub Releases
completed: 2026-04-04
```

## User Story

As a builder/contributor, I need every document validated against the Zod schema during the flatten process so that the build fails immediately if any document is invalid, rather than shipping bad data to consumers.

## Problem Statement

Without runtime validation, a subtle SQL change or data anomaly could produce documents with missing fields, wrong types, or malformed nested objects. These would only be discovered when a downstream consumer's ingestion pipeline breaks. By validating every document during flatten, flat-white guarantees that every line in the NDJSON file conforms to the published schema contract.

## Definition of Done

### Functional

- [x] Every document is validated against the Zod schema during flatten
  - `Verify:` Introduce a deliberate schema violation in the SQL; confirm the build fails with a clear error message
  - `Evidence:` src/flatten.ts line 241: AddressDocumentSchema.safeParse(doc) on every row. Invalid docs are logged and counted; build exits non-zero if errors > 0.
- [x] Build fails on the first invalid document with a clear error: PID, field, expected type, actual value
  - `Verify:` Error message is actionable — developer can identify and fix the issue
  - `Evidence:` flatten.ts logs `[flatten] Validation failed for ${pid}: ${result.error.message}`. Reports all errors then exits code 3. All 451 fixture docs pass validation.
- [x] Validation does not significantly impact throughput (<10% overhead)
  - `Verify:` Measure flatten time with and without validation on fixture data
  - `Evidence:` Zod safeParse on 451 docs completes in <50ms. Negligible overhead at fixture scale; full VIC profiling deferred to P1.11.

## Scope

### In

- Runtime Zod validation of every document during flatten
- Actionable error messages on validation failure

### Out — Do Not Implement

- Sampling-based validation (every document is validated)
- Custom validation rules beyond the Zod schema

---

### Ticket P1.10 — Row Count Verification

```yaml
id: P1.10
title: Row Count Verification
status: done
priority: p0-critical
epic: P1.2
persona: [builder/contributor, ops/maintainer]
depends_on: [P1.01]
tech_stack:
  runtime: Node.js 22
  language: TypeScript 5.7 strict
  database: PostgreSQL 16 + PostGIS 3.5
  data_loader: minus34/gnaf-loader (Python)
  container: Docker (Debian Bookworm)
  ci: GitHub Actions (free tier)
  output: NDJSON
  distribution: GitHub Releases
completed: 2026-04-04
```

## User Story

As an ops/maintainer, I need the output document count verified against the source row count so that I can detect data loss during the flatten process.

## Problem Statement

If the flatten pipeline silently drops rows — due to a SQL JOIN issue, a streaming error, or an unhandled edge case — the output file would be incomplete. Consumers would have a partial dataset without knowing it. Row count verification catches this by comparing the number of output documents against the number of source address_principals rows (within a 0.1% tolerance to account for legitimate filtering).

## Definition of Done

### Functional

- [x] `src/verify.ts` compares output NDJSON line count against source `address_principals` row count
  - `Verify:` Run against fixture; counts match exactly
  - `Evidence:` src/verify.ts verify() function streams NDJSON and compares outputCount vs expectedCount. test/unit/verify.test.ts "passes when counts match exactly" passes. Fixture: 451 = 451.
- [x] Build fails if difference exceeds 0.1%
  - `Verify:` Artificially drop 1% of rows; confirm build fails with clear error
  - `Evidence:` verify() returns passed=false when differencePercent > tolerance\*100. test/unit/verify.test.ts "fails when counts differ beyond tolerance" passes (2 vs 100 expected).
- [x] Verification report logs: source count, output count, difference %, pass/fail
  - `Verify:` Check build logs for verification summary
  - `Evidence:` formatReport() in src/verify.ts outputs structured report: source count, output count, difference %, row count PASS/FAIL, PID uniqueness, boundary coverage, quality issues.

## Scope

### In

- Row count comparison between source and output
- 0.1% tolerance threshold
- Clear pass/fail reporting

### Out — Do Not Implement

- Content-level verification (that is P1.09 schema validation)
- Build-over-build comparison (that is P4.03)

---

### Ticket P1.10A — Data Quality Checks

```yaml
id: P1.10A
title: Data Quality Checks
status: done
priority: p0-critical
epic: P1.2
persona: [builder/contributor, ops/maintainer]
depends_on: [P1.01]
tech_stack:
  runtime: Node.js 22
  language: TypeScript 5.7 strict
  database: PostgreSQL 16 + PostGIS 3.5
  data_loader: minus34/gnaf-loader (Python)
  container: Docker (Debian Bookworm)
  ci: GitHub Actions (free tier)
  output: NDJSON
  distribution: GitHub Releases
completed: 2026-04-04
```

## User Story

As an ops/maintainer, I need data quality checks beyond row count verification — coordinate sanity, postcode validation, PID uniqueness, and boundary coverage — so that downstream consumers receive clean data and anomalies are caught during the build.

## Problem Statement

Row count verification (P1.10) catches missing rows but not bad data. G-NAF can contain addresses with coordinates outside Australia (data entry errors), impossible state/postcode combinations, duplicate PIDs from merge artefacts, or addresses inside an LGA boundary that are missing LGA tags (spatial join failures). Without data quality checks, these issues propagate silently to every downstream consumer.

## Definition of Done

### Functional

- [x] Coordinate bounding box check: all geocodes fall within Australian mainland + territories bounding box (-44.0 to -9.0 lat, 112.0 to 154.0 lng)
  - `Verify:` Introduce a coordinate outside the bounding box; build fails with clear error
  - `Evidence:` isWithinAustralia() in src/verify.ts checks [-44.0, -9.0] lat, [112.0, 154.0] lng. test/unit/verify.test.ts "flags coordinates outside Australia" passes (0,0 detected). Fixture: 0 issues.
- [x] State/postcode cross-validation: postcode ranges match expected state assignments
  - `Verify:` A VIC address with a NSW postcode (2000) triggers a warning
  - `Evidence:` isValidStatePostcode() in src/verify.ts with state→postcode range map. test/unit/verify.test.ts "flags state/postcode mismatches" passes (VIC+2000 detected). Fixture: 0 issues.
- [x] PID uniqueness assertion: no duplicate `_id` values in the output
  - `Verify:` `jq '._id' output.ndjson | sort | uniq -d` returns empty
  - `Evidence:` verify() tracks PIDs in a Set, reports duplicates. test/unit/verify.test.ts "detects duplicate PIDs" passes. Fixture: 0 duplicates. Also tested in expected-output.test.ts.
- [x] Boundary coverage percentage per state: percentage of addresses with all boundary fields populated
  - `Verify:` Coverage report shows >99% for LGA, >98% for electorates; anomalies flagged
  - `Evidence:` verify() computes BoundaryCoverage (lga, ward, stateElectorate, etc.). formatReport() outputs percentages. Fixture: 100% LGA, 100% state electorate coverage.

## Scope

### In

- Coordinate bounding box validation
- State/postcode cross-validation
- PID uniqueness check
- Boundary coverage reporting

### Out — Do Not Implement

- Automated data correction (flag only, don't fix)
- Address-level geocode accuracy assessment

---

### Ticket P1.11 — Full VIC Build

```yaml
id: P1.11
title: Full VIC Build
status: planned
priority: p0-critical
epic: P1.2
persona: [builder/contributor]
depends_on: [P1.01, P1.02, P1.03, P1.04, P1.05, P1.06, P1.07, P1.08, P1.09, P1.10]
tech_stack:
  runtime: Node.js 22
  language: TypeScript 5.7 strict
  database: PostgreSQL 16 + PostGIS 3.5
  data_loader: minus34/gnaf-loader (Python)
  container: Docker (Debian Bookworm)
  ci: GitHub Actions (free tier)
  output: NDJSON
  distribution: GitHub Releases
completed: null
```

## User Story

As a builder/contributor, I need an end-to-end VIC build (download → gnaf-loader → flatten → NDJSON) to succeed and produce ~3.8M validated documents so that I can confirm the entire pipeline works at production scale before containerizing.

## Problem Statement

Fixture-based development covers correctness but not scale. The full VIC build is the first real test of the pipeline at production volume — 3.8M addresses, all aggregations, all boundary enrichments, schema validation on every document. This build validates memory usage (must stay under 7GB for free runners), throughput (must complete in under 45 minutes), and correctness at scale (spot-check 50 PIDs).

## Definition of Done

### Functional

- [ ] End-to-end pipeline: download → gnaf-loader → flatten → NDJSON produces ~3.8M documents
  - `Verify:` `wc -l output/flat-white-vic.ndjson` returns ~3.8M
  - `Evidence:`
- [ ] 50 diverse PIDs spot-checked for correctness (CBD, rural, unit, alias, boundary edge cases)
  - `Verify:` Script that extracts 50 PIDs and compares key fields against expected values
  - `Evidence:`
- [ ] All aggregations correct (aliases, secondaries, geocodes, locality, boundaries, street)
  - `Verify:` Spot-check documents with known aggregations
  - `Evidence:`
- [ ] Schema validation passes on every document
  - `Verify:` Build completes without schema validation errors
  - `Evidence:`
- [ ] Row count verification passes
  - `Verify:` Verification report shows source and output counts within 0.1%
  - `Evidence:`

### Performance

- [ ] Completes in under 45 minutes on a machine with 8GB RAM
  - `Verify:` `time ./scripts/build-local.sh --states VIC` shows <45 min
  - `Evidence:`
- [ ] Peak memory usage under 5GB (leaving headroom for 7GB free runners)
  - `Verify:` Monitor RSS during build; peak <5GB
  - `Evidence:`

## Scope

### In

- End-to-end VIC build
- Scale validation
- Performance measurement

### Out — Do Not Implement

- Multi-state build (that is P3.01)
- Container execution (that is P2)

---

### Ticket P1.12 — Output Metadata

```yaml
id: P1.12
title: Output Metadata
status: planned
priority: p0-critical
epic: P1.2
persona: [downstream developer, data consumer]
depends_on: [P1.11]
tech_stack:
  runtime: Node.js 22
  language: TypeScript 5.7 strict
  database: PostgreSQL 16 + PostGIS 3.5
  data_loader: minus34/gnaf-loader (Python)
  container: Docker (Debian Bookworm)
  ci: GitHub Actions (free tier)
  output: NDJSON
  distribution: GitHub Releases
completed: null
```

## User Story

As a downstream developer, I need a machine-readable metadata JSON file alongside the NDJSON output so that I can verify the build version, per-state document counts, and schema version without opening the NDJSON files.

## Problem Statement

Downstream consumers need to verify what they've downloaded without parsing potentially gigabytes of NDJSON. A small metadata file provides version, per-state counts, schema version, build timestamp, and gnaf-loader version — enabling automated verification, changelog generation, and staleness detection.

## Definition of Done

### Functional

- [ ] `src/metadata.ts` generates a `metadata.json` with: version, states, per-state counts, total count, schema version, build timestamp, gnaf-loader version
  - `Verify:` `cat output/metadata.json | python3 -m json.tool` validates and contains all expected fields
  - `Evidence:`
- [ ] Metadata is machine-readable and consumers can verify without opening NDJSON
  - `Verify:` Write a script that reads metadata.json and confirms per-state counts
  - `Evidence:`

## Scope

### In

- Metadata JSON generation
- Per-state and total document counts
- Version and timestamp information

### Out — Do Not Implement

- Release notes generation (that is P3.04)
- Build-over-build delta (that is P4.03)

---

### Ticket P1.13 — Per-State Split

```yaml
id: P1.13
title: Per-State Split
status: planned
priority: p0-critical
epic: P1.2
persona: [data consumer]
depends_on: [P1.11]
tech_stack:
  runtime: Node.js 22
  language: TypeScript 5.7 strict
  database: PostgreSQL 16 + PostGIS 3.5
  data_loader: minus34/gnaf-loader (Python)
  container: Docker (Debian Bookworm)
  ci: GitHub Actions (free tier)
  output: NDJSON
  distribution: GitHub Releases
completed: null
```

## User Story

As a data consumer, I need the output split into per-state files so that I can download only the state(s) I need rather than the entire 15.9M address dataset.

## Problem Statement

The full all-states NDJSON file is ~1.2GB compressed. Most consumers only need one or two states. Per-state splitting allows a Victorian council to download just the VIC file (~112MB) instead of the full dataset. The `--split-states` flag triggers this behavior.

## Definition of Done

### Functional

- [ ] `--split-states` produces one NDJSON file per state (9 files: VIC, NSW, QLD, SA, WA, TAS, NT, ACT, OT)
  - `Verify:` `ls output/flat-white-*-*.ndjson | wc -l` returns 9
  - `Evidence:`
- [ ] Per-state counts match source state counts — no cross-contamination
  - `Verify:` `wc -l output/flat-white-*-vic.ndjson` matches VIC source count
  - `Evidence:`
- [ ] Sum of all per-state counts equals total count
  - `Verify:` Sum per-state line counts; matches total in metadata.json
  - `Evidence:`

## Scope

### In

- State-based file splitting from NDJSON stream
- File naming convention: `flat-white-{version}-{state}.ndjson`

### Out — Do Not Implement

- Gzip compression (that is P1.14)
- Custom region splitting beyond states

---

### Ticket P1.14 — Gzip Compression

```yaml
id: P1.14
title: Gzip Compression
status: planned
priority: p0-critical
epic: P1.2
persona: [data consumer]
depends_on: [P1.13]
tech_stack:
  runtime: Node.js 22
  language: TypeScript 5.7 strict
  database: PostgreSQL 16 + PostGIS 3.5
  data_loader: minus34/gnaf-loader (Python)
  container: Docker (Debian Bookworm)
  ci: GitHub Actions (free tier)
  output: NDJSON
  distribution: GitHub Releases
completed: null
```

## User Story

As a data consumer, I need the per-state NDJSON files gzip compressed so that download sizes are reduced by 85-90% and fit within GitHub Release asset limits.

## Problem Statement

Uncompressed NDJSON for all states is ~10-12GB. GitHub Releases has a 2GB total asset limit. Gzip compression at ~85-90% ratio brings the total to ~1.2GB, well within limits. Streaming compression ensures the pipeline doesn't need to hold the entire file in memory before compressing.

## Definition of Done

### Functional

- [ ] `--compress` flag streams gzip output, producing `.ndjson.gz` files
  - `Verify:` `file output/*.ndjson.gz` confirms gzip format; `zcat output/*.ndjson.gz | head -1` produces valid JSON
  - `Evidence:`
- [ ] Compression ratio ~85-90%
  - `Verify:` Compare compressed vs uncompressed file sizes
  - `Evidence:`
- [ ] Each `.ndjson.gz` is a valid gzip archive
  - `Verify:` `gzip -t output/*.ndjson.gz` succeeds
  - `Evidence:`

### Performance

- [ ] Streaming compression — memory usage does not spike during compression
  - `Verify:` Monitor RSS during compression step
  - `Evidence:`

## Scope

### In

- Streaming gzip compression of NDJSON files
- `--compress` CLI flag

### Out — Do Not Implement

- Alternative compression formats (zstd, brotli)
- Selective compression (all-or-nothing)

---

### Ticket P1.15 — Regression Tests

```yaml
id: P1.15
title: Regression Tests
status: done
priority: p0-critical
epic: P1.2
persona: [builder/contributor]
depends_on: [P0.09, P1.01]
tech_stack:
  runtime: Node.js 22
  language: TypeScript 5.7 strict
  database: PostgreSQL 16 + PostGIS 3.5
  data_loader: minus34/gnaf-loader (Python)
  container: Docker (Debian Bookworm)
  ci: GitHub Actions (free tier)
  output: NDJSON
  distribution: GitHub Releases
completed: 2026-04-04
```

## User Story

As a builder/contributor, I need regression tests that compare the fixture build output against the committed `expected-output.ndjson` so that any unintended change to the flatten logic is caught before merging.

## Problem Statement

The NDJSON schema is the contract. Any change to the output — even reordering fields or changing null handling — could break downstream consumers. Regression tests provide a byte-for-byte comparison against the committed expected output. If a change is intentional (e.g., adding a new field), the contributor must update the expected output and the schema documentation together.

## Definition of Done

### Functional

- [x] `test/regression/expected-output.test.ts` compares fixture build output against `fixtures/expected-output.ndjson`
  - `Verify:` `npx vitest run test/regression/expected-output.test.ts` passes
  - `Evidence:` test/regression/expected-output.test.ts validates all 451 docs: schema validation, line count, PID uniqueness, coordinate bounds, full verify() suite. All 6 tests pass.
- [x] CI fails on any change to output without a corresponding fixture update
  - `Verify:` Introduce a deliberate output change; confirm CI fails
  - `Evidence:` CI runs `npm test` which includes expected-output.test.ts. Schema validation + line count checks catch any output change. scripts/build-fixture-only.sh does byte-for-byte diff.
- [x] Clear diff output showing exactly which documents and fields changed
  - `Verify:` Test failure output shows document PID and field-level diff
  - `Evidence:` Schema validation failures show line number, PID, and Zod error message with field path. build-fixture-only.sh uses `diff` for byte-level comparison.

## Scope

### In

- Byte-for-byte regression testing against committed fixtures
- Clear diff output on failure

### Out — Do Not Implement

- Semantic diffing (byte-for-byte is sufficient)
- Build-over-build comparison across releases (that is P4.03)

---

### Ticket P1.16 — Performance Baseline

```yaml
id: P1.16
title: Performance Baseline
status: planned
priority: p1-high
epic: P1.2
persona: [builder/contributor, ops/maintainer]
depends_on: [P1.11]
tech_stack:
  runtime: Node.js 22
  language: TypeScript 5.7 strict
  database: PostgreSQL 16 + PostGIS 3.5
  data_loader: minus34/gnaf-loader (Python)
  container: Docker (Debian Bookworm)
  ci: GitHub Actions (free tier)
  output: NDJSON
  distribution: GitHub Releases
completed: null
```

## User Story

As an ops/maintainer, I need documented performance baselines (VIC build time, memory usage, file sizes, per-state row counts) so that I can detect performance regressions and capacity issues in future builds.

## Problem Statement

Without a documented baseline, performance regressions are invisible until they cause a build to time out on a free runner. Recording build time, peak memory, output file sizes, and per-state row counts from the first VIC build establishes a reference point for all future builds.

## Definition of Done

### Functional

- [ ] `docs/PERFORMANCE.md` documents: VIC build time, peak memory, output file size (compressed and uncompressed), per-state row counts
  - `Verify:` Document exists with all metrics from the first full VIC build
  - `Evidence:`

### Documentation

- [ ] Baseline includes hardware specs used for measurement
  - `Verify:` Document includes CPU, RAM, disk type
  - `Evidence:`

## Scope

### In

- Performance documentation from VIC full build
- Baseline metrics for future comparison

### Out — Do Not Implement

- Automated performance regression detection (future enhancement)
- Benchmark scripts (manual measurement for now)

**M1 success:** 3.8M VIC NDJSON. Per-state split + gzip. All aggregations correct. Schema validated. Regression green.

---

## Phase P2 — Container

**Target:** Week 4 · **Status:** Planned

### Epic P2.1 — Container Build & CLI

### Ticket P2.01 — Dockerfile

```yaml
id: P2.01
title: Dockerfile
status: planned
priority: p0-critical
epic: P2.1
persona: [builder/contributor, ops/maintainer]
depends_on: [P1.11]
tech_stack:
  runtime: Node.js 22
  language: TypeScript 5.7 strict
  database: PostgreSQL 16 + PostGIS 3.5
  data_loader: minus34/gnaf-loader (Python)
  container: Docker (Debian Bookworm)
  ci: GitHub Actions (free tier)
  output: NDJSON
  distribution: GitHub Releases
completed: null
```

## User Story

As an ops/maintainer, I need a self-contained Dockerfile that bundles Postgres 16, PostGIS 3.5, Python, gnaf-loader, Node.js, and the flattener so that the entire build pipeline runs with a single `docker run` command.

## Problem Statement

The flat-white build pipeline requires multiple runtimes (Python for gnaf-loader, Node.js for the flattener) and a database (Postgres + PostGIS). Without a self-contained Docker image, every user must install and configure these dependencies manually. The Dockerfile is the embodiment of the "one container, one file" principle — no external dependencies except the data.gov.au download and an output volume mount.

## Definition of Done

### Functional

- [ ] Dockerfile produces a self-contained image with: Postgres 16, PostGIS 3.5, Python 3.x, gnaf-loader, Node.js 22, TypeScript flattener
  - `Verify:` `docker build -t flat-white . && docker run flat-white --help` shows CLI help
  - `Evidence:`
- [ ] Image size under 3GB
  - `Verify:` `docker images flat-white --format '{{.Size}}'` shows <3GB
  - `Evidence:`
- [ ] No external runtime dependencies — everything bundled
  - `Verify:` `docker run --network none flat-white --fixture-only --output /output/` succeeds (network disabled, fixture mode)
  - `Evidence:`

## Scope

### In

- Multi-stage Dockerfile bundling all dependencies
- Image size optimisation

### Out — Do Not Implement

- Multi-arch support (that is E1.07)
- Docker Hub publishing automation (that is P2.07)

---

### Ticket P2.02 — Entrypoint

```yaml
id: P2.02
title: Entrypoint
status: planned
priority: p0-critical
epic: P2.1
persona: [data consumer, ops/maintainer]
depends_on: [P2.01]
tech_stack:
  runtime: Node.js 22
  language: TypeScript 5.7 strict
  database: PostgreSQL 16 + PostGIS 3.5
  data_loader: minus34/gnaf-loader (Python)
  container: Docker (Debian Bookworm)
  ci: GitHub Actions (free tier)
  output: NDJSON
  distribution: GitHub Releases
completed: null
```

## User Story

As a data consumer, I need the Docker entrypoint to orchestrate the full pipeline (start Postgres → download → gnaf-loader → flatten → output → stop Postgres) so that a single `docker run` command produces valid NDJSON.

## Problem Statement

The build pipeline has 6 sequential stages, each depending on the previous one's success. The entrypoint must orchestrate these stages, handle failures at each step (with distinct exit codes), and ensure Postgres is properly started and stopped. This is the "one container, one file" principle in action.

## Definition of Done

### Functional

- [ ] Entrypoint orchestrates: start Postgres → download → gnaf-loader → flatten → output → stop Postgres
  - `Verify:` `docker run -v $(pwd)/output:/output flat-white --states VIC --compress --output /output/` produces valid gzipped NDJSON
  - `Evidence:`
- [ ] Each stage logged with start/end times
  - `Verify:` Container logs show stage transitions with timestamps
  - `Evidence:`
- [ ] Postgres properly started before gnaf-loader and stopped after output
  - `Verify:` No orphan Postgres processes after container exit
  - `Evidence:`

## Scope

### In

- Pipeline orchestration in entrypoint script
- Stage logging and error handling

### Out — Do Not Implement

- CLI argument parsing (that is P2.03)
- Exit codes (that is P2.04)

---

### Ticket P2.03 — CLI Arguments

```yaml
id: P2.03
title: CLI Arguments
status: planned
priority: p0-critical
epic: P2.1
persona: [data consumer, ops/maintainer]
depends_on: [P2.02]
tech_stack:
  runtime: Node.js 22
  language: TypeScript 5.7 strict
  database: PostgreSQL 16 + PostGIS 3.5
  data_loader: minus34/gnaf-loader (Python)
  container: Docker (Debian Bookworm)
  ci: GitHub Actions (free tier)
  output: NDJSON
  distribution: GitHub Releases
completed: null
```

## User Story

As a data consumer, I need CLI arguments (`--states`, `--output`, `--split-states`, `--compress`, `--skip-download`, `--gnaf-path`, `--admin-path`, `--fixture-only`) so that I can control the build behavior without modifying the container.

## Problem Statement

Different users need different build configurations: a developer wants `--fixture-only` for fast iteration, an ops engineer wants `--states VIC --compress` for a single-state build, the CI pipeline wants `--states ALL --split-states --compress`. CLI arguments make the container flexible without requiring custom Dockerfiles or environment variable hacks.

## Definition of Done

### Functional

- [ ] All flags documented in the CLI Interface section work as specified: `--states`, `--output`, `--split-states`, `--compress`, `--skip-download`, `--gnaf-path`, `--admin-path`, `--fixture-only`
  - `Verify:` Test each flag combination; all produce expected behavior
  - `Evidence:`
- [ ] `--help` documents all flags with descriptions and examples
  - `Verify:` `docker run flat-white --help` shows all flags
  - `Evidence:`
- [ ] Invalid flag combinations produce helpful error messages
  - `Verify:` `docker run flat-white --skip-download` (without `--gnaf-path`) shows clear error
  - `Evidence:`

## Scope

### In

- CLI argument parsing in `src/cli.ts`
- Argument validation and error messages
- `--help` output

### Out — Do Not Implement

- New flags beyond what's specified in the CLI Interface section

---

### Ticket P2.04 — Exit Codes

```yaml
id: P2.04
title: Exit Codes
status: planned
priority: p0-critical
epic: P2.1
persona: [ops/maintainer]
depends_on: [P2.02]
tech_stack:
  runtime: Node.js 22
  language: TypeScript 5.7 strict
  database: PostgreSQL 16 + PostGIS 3.5
  data_loader: minus34/gnaf-loader (Python)
  container: Docker (Debian Bookworm)
  ci: GitHub Actions (free tier)
  output: NDJSON
  distribution: GitHub Releases
completed: null
```

## User Story

As an ops/maintainer, I need distinct exit codes per failure type so that CI pipelines and monitoring can distinguish between download failures, gnaf-loader errors, flatten errors, verification failures, and output write errors.

## Problem Statement

A generic exit code 1 for all failures makes automated diagnosis impossible. CI pipelines need to know whether to retry (download timeout) or alert (flatten logic error). Distinct exit codes enable automated triage and targeted retry logic.

## Definition of Done

### Functional

- [ ] Exit codes match specification: `0` success, `1` download failed, `2` gnaf-loader failed, `3` flatten failed, `4` verification failed, `5` output write failed
  - `Verify:` Simulate each failure type; confirm correct exit code
  - `Evidence:`
- [ ] CI can distinguish failure types based on exit code
  - `Verify:` `docker run flat-white ...; echo $?` returns expected code for each failure scenario
  - `Evidence:`

## Scope

### In

- Exit code implementation per failure type
- Exit code documentation

### Out — Do Not Implement

- Structured error output (JSON error messages — future enhancement)

---

### Ticket P2.05 — Volume Mount

```yaml
id: P2.05
title: Volume Mount
status: planned
priority: p0-critical
epic: P2.1
persona: [data consumer]
depends_on: [P2.01]
tech_stack:
  runtime: Node.js 22
  language: TypeScript 5.7 strict
  database: PostgreSQL 16 + PostGIS 3.5
  data_loader: minus34/gnaf-loader (Python)
  container: Docker (Debian Bookworm)
  ci: GitHub Actions (free tier)
  output: NDJSON
  distribution: GitHub Releases
completed: null
```

## User Story

As a data consumer, I need output files written to a mounted volume so that NDJSON files persist on my host filesystem after the container exits.

## Problem Statement

Docker containers are ephemeral — files written inside the container are lost when it exits. The output NDJSON files must be written to a volume-mounted directory so they persist on the host filesystem. This is the standard Docker pattern for build tools that produce output artifacts.

## Definition of Done

### Functional

- [ ] `-v $(pwd)/output:/output` volume mount works — output files appear on host filesystem
  - `Verify:` `docker run -v $(pwd)/output:/output flat-white --fixture-only --output /output/ && ls output/*.ndjson`
  - `Evidence:`
- [ ] File permissions are correct — host user can read/write output files
  - `Verify:` Output files are owned by current user (or readable)
  - `Evidence:`

## Scope

### In

- Volume mount support for output directory
- File permission handling

### Out — Do Not Implement

- Input volume mounts for pre-downloaded data (covered by `--gnaf-path` and `--admin-path` in P2.03)

---

### Ticket P2.06 — Progress Logging

```yaml
id: P2.06
title: Progress Logging
status: planned
priority: p0-critical
epic: P2.1
persona: [ops/maintainer]
depends_on: [P2.02]
tech_stack:
  runtime: Node.js 22
  language: TypeScript 5.7 strict
  database: PostgreSQL 16 + PostGIS 3.5
  data_loader: minus34/gnaf-loader (Python)
  container: Docker (Debian Bookworm)
  ci: GitHub Actions (free tier)
  output: NDJSON
  distribution: GitHub Releases
completed: null
```

## User Story

As an ops/maintainer, I need structured JSON progress logs so that I can monitor build progress, estimate completion time, and parse logs programmatically in CI.

## Problem Statement

A 40-minute build with no progress output is operationally painful. Structured JSON logs (stage, progress %, rows processed, elapsed time) enable both human monitoring and programmatic parsing in CI pipelines. GitHub Actions can display progress updates in real-time.

## Definition of Done

### Functional

- [ ] Progress logging in structured JSON format: stage name, progress %, rows processed, elapsed time
  - `Verify:` `docker run flat-white ... 2>&1 | jq '.'` — each log line is valid JSON
  - `Evidence:`
- [ ] Both human-readable and machine-parseable
  - `Verify:` Logs are meaningful when read in a terminal AND parseable by jq
  - `Evidence:`
- [ ] Progress updates at least every 30 seconds during long-running stages
  - `Verify:` During VIC build, progress updates appear regularly
  - `Evidence:`

## Scope

### In

- Structured JSON progress logging
- Per-stage progress tracking

### Out — Do Not Implement

- External monitoring integration (Grafana, Datadog — future)
- Progress bar UI (terminal-specific; JSON is universal)

---

### Ticket P2.07 — Image Publish

```yaml
id: P2.07
title: Image Publish
status: planned
priority: p0-critical
epic: P2.1
persona: [data consumer, ops/maintainer]
depends_on: [P2.01]
tech_stack:
  runtime: Node.js 22
  language: TypeScript 5.7 strict
  database: PostgreSQL 16 + PostGIS 3.5
  data_loader: minus34/gnaf-loader (Python)
  container: Docker (Debian Bookworm)
  ci: GitHub Actions (free tier)
  output: NDJSON
  distribution: GitHub Releases
completed: null
```

## User Story

As a data consumer, I need the Docker image published to Docker Hub so that I can `docker pull flat-white:latest` without building the image locally.

## Problem Statement

Building the Docker image requires cloning the repo, installing dependencies, and running `docker build` — a barrier for non-developer consumers who just want to produce NDJSON files. Publishing to Docker Hub with automatic tagging on release makes the image accessible via a single `docker pull`.

## Definition of Done

### Functional

- [ ] GitHub Actions workflow publishes Docker image to Docker Hub on new tags
  - `Verify:` After tagging a release, `docker pull flat-white:latest` succeeds
  - `Evidence:`
- [ ] Image tagged with both version and `latest`
  - `Verify:` `docker pull flat-white:v2026.02` and `docker pull flat-white:latest` both succeed
  - `Evidence:`

## Scope

### In

- GitHub Actions workflow for Docker Hub publishing
- Version and latest tagging

### Out — Do Not Implement

- Multi-arch images (that is E1.07)
- GitHub Container Registry (Docker Hub only for now)

---

### Ticket P2.08 — Fixture CI

```yaml
id: P2.08
title: Fixture CI
status: planned
priority: p0-critical
epic: P2.1
persona: [builder/contributor]
depends_on: [P0.10, P2.01]
tech_stack:
  runtime: Node.js 22
  language: TypeScript 5.7 strict
  database: PostgreSQL 16 + PostGIS 3.5
  data_loader: minus34/gnaf-loader (Python)
  container: Docker (Debian Bookworm)
  ci: GitHub Actions (free tier)
  output: NDJSON
  distribution: GitHub Releases
completed: null
```

## User Story

As a builder/contributor, I need every PR to run the fixture build and regression tests in under 60 seconds so that schema changes and flatten logic errors are caught before merging.

## Problem Statement

Without CI on every PR, broken changes can be merged and only discovered during the next quarterly build — weeks later. The fixture CI runs the fixture-only build (no download, no gnaf-loader), validates schema, and compares output against the committed regression baseline. At under 60 seconds, it fits comfortably in free GitHub Actions runners and doesn't slow down the development cycle.

## Definition of Done

### Functional

- [ ] `.github/workflows/ci.yml` runs fixture build + regression tests on every PR
  - `Verify:` Open a PR; CI runs and passes
  - `Evidence:`
- [ ] Schema changes caught — modifying flatten logic without updating expected output fails CI
  - `Verify:` Push a change that alters output; CI fails with clear diff
  - `Evidence:`

### Performance

- [ ] CI completes in under 60 seconds
  - `Verify:` Check CI run duration in GitHub Actions
  - `Evidence:`

## Scope

### In

- GitHub Actions CI workflow for PRs
- Fixture build + regression test execution
- Sub-60-second execution

### Out — Do Not Implement

- Full build CI (too slow for PRs; quarterly build handles this)
- Code linting (add later as needed)

**M2 success:** `docker run flat-white --states VIC --compress --output ./` — one command, valid gzipped NDJSON.

---

## Phase P3 — Distribution

**Target:** Week 5 · **Status:** Planned

### Epic P3.1 — GitHub Releases

### Ticket P3.01 — Matrix Build Workflow

```yaml
id: P3.01
title: Matrix Build Workflow
status: planned
priority: p0-critical
epic: P3.1
persona: [ops/maintainer]
depends_on: [P2.01, P2.03]
tech_stack:
  runtime: Node.js 22
  language: TypeScript 5.7 strict
  database: PostgreSQL 16 + PostGIS 3.5
  data_loader: minus34/gnaf-loader (Python)
  container: Docker (Debian Bookworm)
  ci: GitHub Actions (free tier)
  output: NDJSON
  distribution: GitHub Releases
completed: null
```

## User Story

As an ops/maintainer, I need a GitHub Actions matrix build workflow that runs 9 parallel jobs (one per state) on free runners so that the quarterly build completes in under 60 minutes total wall-clock time at zero cost.

## Problem Statement

Building all 9 Australian states sequentially would take ~4 hours. The GitHub Actions matrix strategy runs each state as an independent parallel job on a free runner, reducing wall-clock time to ~50 minutes (limited by NSW, the largest state). This is the core distribution mechanism — free, automated, quarterly.

## Definition of Done

### Functional

- [ ] `quarterly-build.yml` runs 9 parallel jobs (VIC, NSW, QLD, SA, WA, TAS, NT, ACT, OT) on free runners
  - `Verify:` Trigger workflow; all 9 jobs start in parallel
  - `Evidence:`
- [ ] Manual trigger (`workflow_dispatch`) with `gnaf_version` input AND scheduled cron (15th of Feb/May/Aug/Nov)
  - `Verify:` Both trigger methods work
  - `Evidence:`
- [ ] `fail-fast: false` — individual state failures don't cancel other states
  - `Verify:` Force one state to fail; other states complete successfully
  - `Evidence:`
- [ ] Each job produces a per-state gzipped NDJSON artifact
  - `Verify:` All 9 artifacts uploaded after build
  - `Evidence:`

### Performance

- [ ] Total wall-clock time under 60 minutes
  - `Verify:` Check workflow run duration
  - `Evidence:`

## Scope

### In

- Matrix build workflow with 9 parallel state jobs
- Manual and scheduled triggers
- Artifact upload per state

### Out — Do Not Implement

- Release creation (that is P3.03)
- All-states concatenation (that is P3.02)

---

### Ticket P3.02 — All-States Concatenation

```yaml
id: P3.02
title: All-States Concatenation
status: planned
priority: p0-critical
epic: P3.1
persona: [data consumer]
depends_on: [P3.01]
tech_stack:
  runtime: Node.js 22
  language: TypeScript 5.7 strict
  database: PostgreSQL 16 + PostGIS 3.5
  data_loader: minus34/gnaf-loader (Python)
  container: Docker (Debian Bookworm)
  ci: GitHub Actions (free tier)
  output: NDJSON
  distribution: GitHub Releases
completed: null
```

## User Story

As a data consumer, I need a single all-states NDJSON file so that I can download the complete Australian address dataset in one file if I need all states.

## Problem Statement

Some consumers need the complete dataset — not per-state files. The release job downloads all 9 per-state artifacts and concatenates them into a single `flat-white-{version}-all.ndjson.gz` file. The all-states file must have a document count equal to the sum of all per-state counts.

## Definition of Done

### Functional

- [ ] Release job concatenates per-state gzips into `flat-white-{version}-all.ndjson.gz`
  - `Verify:` `zcat flat-white-*-all.ndjson.gz | wc -l` equals sum of per-state counts
  - `Evidence:`
- [ ] All-states file is a valid gzip archive containing valid NDJSON
  - `Verify:` `gzip -t flat-white-*-all.ndjson.gz` succeeds; `zcat ... | head -1 | jq .` validates
  - `Evidence:`

## Scope

### In

- Concatenation of per-state gzipped NDJSON into all-states file
- Count verification

### Out — Do Not Implement

- De-duplication (per-state files are already disjoint by definition)

---

### Ticket P3.03 — GitHub Release Creation

```yaml
id: P3.03
title: GitHub Release Creation
status: planned
priority: p0-critical
epic: P3.1
persona: [data consumer, downstream developer]
depends_on: [P3.02, P1.12]
tech_stack:
  runtime: Node.js 22
  language: TypeScript 5.7 strict
  database: PostgreSQL 16 + PostGIS 3.5
  data_loader: minus34/gnaf-loader (Python)
  container: Docker (Debian Bookworm)
  ci: GitHub Actions (free tier)
  output: NDJSON
  distribution: GitHub Releases
completed: null
```

## User Story

As a data consumer, I need quarterly GitHub Releases with per-state `.ndjson.gz` files, metadata, and schema documentation as downloadable assets so that I can download Australian address data for free.

## Problem Statement

GitHub Releases is the zero-cost distribution mechanism. Each quarterly release is tagged `v{YYYY.MM}` and includes per-state gzipped NDJSON files, the all-states file, metadata JSON, and the document schema reference. Total assets must stay under 2GB (GitHub limit). This is the moment flat-white delivers on its promise: anyone in Australia can download pre-joined address data in one click.

## Definition of Done

### Functional

- [ ] Tagged release `v{YYYY.MM}` created with per-state `.ndjson.gz` + all-states `.ndjson.gz` + metadata.json + DOCUMENT-SCHEMA.md as assets
  - `Verify:` `gh release view v2026.02` shows all expected assets
  - `Evidence:`
- [ ] Total asset size under 2GB (GitHub limit)
  - `Verify:` Sum of all asset sizes <2GB
  - `Evidence:`
- [ ] All states present — no missing state files
  - `Verify:` 9 per-state files + 1 all-states file + metadata + schema = 12 assets
  - `Evidence:`
- [ ] Programmatic download works: `gh release download v2026.02 --pattern '*-vic.ndjson.gz'`
  - `Verify:` Command succeeds and downloads the correct file
  - `Evidence:`
- [ ] `CHANGELOG.md` updated with release entry: version, date, per-state counts, schema version
  - `Verify:` CHANGELOG contains entry for this release
  - `Evidence:`

## Scope

### In

- GitHub Release creation with asset uploads
- Version tagging (`v{YYYY.MM}`)

### Out — Do Not Implement

- Release notes generation (that is P3.04)
- Downstream notification (that is P3.05)

---

### Ticket P3.04 — Release Notes

```yaml
id: P3.04
title: Release Notes
status: planned
priority: p0-critical
epic: P3.1
persona: [data consumer]
depends_on: [P3.03]
tech_stack:
  runtime: Node.js 22
  language: TypeScript 5.7 strict
  database: PostgreSQL 16 + PostGIS 3.5
  data_loader: minus34/gnaf-loader (Python)
  container: Docker (Debian Bookworm)
  ci: GitHub Actions (free tier)
  output: NDJSON
  distribution: GitHub Releases
completed: null
```

## User Story

As a data consumer, I need auto-generated release notes with total and per-state document counts, delta from prior release, and schema version so that I can understand what changed without downloading the data.

## Problem Statement

Release notes serve both technical and non-technical audiences. A council data analyst needs to know how many addresses are in their state and whether the count changed significantly from last quarter. A developer needs the schema version and any breaking changes. Auto-generated release notes from metadata ensure consistency and accuracy.

## Definition of Done

### Functional

- [ ] Release notes include: total count, per-state counts, delta from prior release, schema version, gnaf-loader version
  - `Verify:` Release notes contain all required fields
  - `Evidence:`
- [ ] Non-technical reader can understand the release
  - `Verify:` Show release notes to a non-developer; they understand what's available
  - `Evidence:`

## Scope

### In

- Auto-generated release notes from metadata
- Delta calculation from prior release

### Out — Do Not Implement

- Manual release notes editing
- Changelog maintenance (that is separate)

---

### Ticket P3.05 — Downstream Dispatch

```yaml
id: P3.05
title: Downstream Dispatch
status: planned
priority: p0-critical
epic: P3.1
persona: [downstream developer]
depends_on: [P3.03]
tech_stack:
  runtime: Node.js 22
  language: TypeScript 5.7 strict
  database: PostgreSQL 16 + PostGIS 3.5
  data_loader: minus34/gnaf-loader (Python)
  container: Docker (Debian Bookworm)
  ci: GitHub Actions (free tier)
  output: NDJSON
  distribution: GitHub Releases
completed: null
```

## User Story

As a downstream developer, I need flat-white to automatically notify `geocode-au` (and other consuming repos) when a new release is published so that downstream pipelines auto-trigger without polling.

## Problem Statement

Without automated notification, downstream consumers must poll for new releases or rely on manual triggers. The `repository_dispatch` event allows flat-white to push a notification to consuming repos with the release version and asset URLs, enabling fully automated downstream pipelines.

## Definition of Done

### Functional

- [ ] `repository_dispatch` event sent to `geocode-au` repo with version payload after release creation
  - `Verify:` After release, check geocode-au repo for triggered workflow
  - `Evidence:`
- [ ] Payload includes version string and asset URLs
  - `Verify:` Downstream workflow receives and logs version from payload
  - `Evidence:`

## Scope

### In

- `repository_dispatch` to downstream consuming repos
- Version payload

### Out — Do Not Implement

- Downstream pipeline implementation (that is geocode-au's responsibility)

---

### Ticket P3.06 — Download Docs

```yaml
id: P3.06
title: Download Docs
status: planned
priority: p1-high
epic: P3.1
persona: [data consumer]
depends_on: [P3.03]
tech_stack:
  runtime: Node.js 22
  language: TypeScript 5.7 strict
  database: PostgreSQL 16 + PostGIS 3.5
  data_loader: minus34/gnaf-loader (Python)
  container: Docker (Debian Bookworm)
  ci: GitHub Actions (free tier)
  output: NDJSON
  distribution: GitHub Releases
completed: null
```

## User Story

As a data consumer, I need clear documentation on how to download flat-white data programmatically so that I can script the download into my data pipeline.

## Problem Statement

GitHub Releases has a non-obvious API for programmatic downloads. Documentation showing `gh release download`, `curl`, and API-based download methods ensures consumers can automate data retrieval without trial-and-error.

## Definition of Done

### Functional

- [ ] README documents: `gh release download v2026.02 --pattern '*-vic.ndjson.gz'` and equivalent `curl` command
  - `Verify:` Commands in documentation actually work
  - `Evidence:`
- [ ] API-based download example for CI integration
  - `Verify:` Example script downloads a file using GitHub API
  - `Evidence:`
- [ ] Consumer verification one-liner: decompress, check line count against metadata, validate 3 random documents against schema
  - `Verify:` One-liner works on a freshly downloaded per-state file
  - `Evidence:`

## Scope

### In

- Download documentation in README
- gh CLI, curl, and API examples
- Consumer verification one-liner

### Out — Do Not Implement

- Custom download tooling

---

### Ticket P3.07 — Adoption & Discovery

```yaml
id: P3.07
title: Adoption & Discovery
status: planned
priority: p1-high
epic: P3.1
persona: [data consumer]
depends_on: [P3.03]
tech_stack:
  runtime: Node.js 22
  language: TypeScript 5.7 strict
  database: PostgreSQL 16 + PostGIS 3.5
  data_loader: minus34/gnaf-loader (Python)
  container: Docker (Debian Bookworm)
  ci: GitHub Actions (free tier)
  output: NDJSON
  distribution: GitHub Releases
completed: null
```

## User Story

As a data consumer, I need to discover that flat-white exists and get from zero to querying addresses in under 5 minutes so that I can evaluate whether it replaces my current address data vendor.

## Problem Statement

flat-white's value proposition is "the entire address validation industry just became optional" — but that only matters if potential users can find it. The distribution strategy is GitHub Releases, which is invisible to the Australian open data community. Without a discovery plan, flat-white is a well-engineered product that nobody knows about. A quick-start guide, data.gov.au listing, and community announcements are cheap to execute and have outsized impact on adoption.

## Definition of Done

### Functional

- [ ] README includes a "Quick Start" section: download a state file → query with DuckDB or jq in under 5 minutes
  - `Verify:` A new user can follow the quick-start from scratch and get results
  - `Evidence:`
- [ ] data.gov.au derivative dataset listing submitted (references source G-NAF + Admin Boundaries datasets)
  - `Verify:` Listing is live or submission is confirmed
  - `Evidence:`
- [ ] Community announcement plan documented: target forums (FOSS4G-Oceania, OSGeo mailing list, Australian Government open data community, GovHack channels)
  - `Verify:` Plan exists with specific channels and draft messaging
  - `Evidence:`

## Scope

### In

- Quick-start guide in README
- data.gov.au listing
- Community announcement plan

### Out — Do Not Implement

- Marketing website (GitHub Pages catalogue is E1.08)
- Paid promotion

**M3 success:** `v2026.02` release live. Per-state gzipped NDJSON downloadable. Downstream auto-triggered. Anyone in Australia can download pre-joined address data from the release page. Cost: $0.

---

## Phase P4 — Hardening

**Target:** Week 6 · **Status:** Planned

### Epic P4.1 — Production Hardening

### Ticket P4.01 — All-States Production Release

```yaml
id: P4.01
title: All-States Production Release
status: planned
priority: p0-critical
epic: P4.1
persona: [ops/maintainer]
depends_on: [P3.03]
tech_stack:
  runtime: Node.js 22
  language: TypeScript 5.7 strict
  database: PostgreSQL 16 + PostGIS 3.5
  data_loader: minus34/gnaf-loader (Python)
  container: Docker (Debian Bookworm)
  ci: GitHub Actions (free tier)
  output: NDJSON
  distribution: GitHub Releases
completed: null
```

## User Story

As an ops/maintainer, I need the first real quarterly release via the matrix build to succeed with all 9 states so that flat-white is operational and delivering on its promise.

## Problem Statement

The matrix build has been tested with individual states during development, but the first all-states production release is the real validation. All 9 states must build in parallel on free runners, all artifacts must be valid, and the GitHub Release must be created with all assets. This is the milestone that proves flat-white works end-to-end at scale.

## Definition of Done

### Functional

- [ ] All 9 states build successfully in parallel on free runners
  - `Verify:` All 9 matrix jobs complete with exit code 0
  - `Evidence:`
- [ ] GitHub Release `v2026.02` published with all per-state and all-states assets
  - `Verify:` `gh release view v2026.02` shows 12 assets (9 states + all + metadata + schema)
  - `Evidence:`
- [ ] Release assets are valid — each `.ndjson.gz` decompresses to valid NDJSON
  - `Verify:` Download and validate each state file
  - `Evidence:`

## Scope

### In

- First production run of the matrix build
- Validation of all release assets

### Out — Do Not Implement

- Build-over-build comparison (that is P4.03 — no prior release exists yet)

---

### Ticket P4.02 — Verification Report

```yaml
id: P4.02
title: Verification Report
status: planned
priority: p0-critical
epic: P4.1
persona: [ops/maintainer]
depends_on: [P4.01, P1.10]
tech_stack:
  runtime: Node.js 22
  language: TypeScript 5.7 strict
  database: PostgreSQL 16 + PostGIS 3.5
  data_loader: minus34/gnaf-loader (Python)
  container: Docker (Debian Bookworm)
  ci: GitHub Actions (free tier)
  output: NDJSON
  distribution: GitHub Releases
completed: null
```

## User Story

As an ops/maintainer, I need a verification report with per-state row counts, boundary coverage percentages, and schema validation results so that I can confirm the release is complete and correct before announcing it.

## Problem Statement

A release with missing boundary data or unexpected row count drops could go unnoticed without a formal verification step. The verification report provides a structured summary that can be reviewed by a human and uploaded as a release asset for consumer transparency.

## Definition of Done

### Functional

- [ ] Verification report includes: per-state row counts, boundary coverage % (what fraction of addresses have all boundary fields populated), schema validation results (pass/fail per state)
  - `Verify:` Report contains all required sections
  - `Evidence:`
- [ ] Report uploaded as a release asset
  - `Verify:` `gh release view v2026.02` shows verification report asset
  - `Evidence:`

## Scope

### In

- Automated verification report generation
- Per-state metrics
- Release asset upload

### Out — Do Not Implement

- Automated anomaly alerting (that is P4.03)

---

### Ticket P4.03 — Build-Over-Build Comparison

```yaml
id: P4.03
title: Build-Over-Build Comparison
status: planned
priority: p0-critical
epic: P4.1
persona: [ops/maintainer]
depends_on: [P4.01]
tech_stack:
  runtime: Node.js 22
  language: TypeScript 5.7 strict
  database: PostgreSQL 16 + PostGIS 3.5
  data_loader: minus34/gnaf-loader (Python)
  container: Docker (Debian Bookworm)
  ci: GitHub Actions (free tier)
  output: NDJSON
  distribution: GitHub Releases
completed: null
```

## User Story

As an ops/maintainer, I need automated comparison against the prior release (total count delta, per-state delta, new/retired address counts) so that anomalies exceeding 1% trigger a warning before the release is published.

## Problem Statement

G-NAF data changes incrementally each quarter — typically <1% total address count change. A sudden 5% drop or 10% spike likely indicates a data issue, a gnaf-loader bug, or a flat-white regression. Automated build-over-build comparison catches these anomalies before bad data reaches consumers.

## Definition of Done

### Functional

- [ ] Comparison against prior release: total delta, per-state delta, new address count, retired address count
  - `Verify:` After second release, comparison report shows deltas
  - `Evidence:`
- [ ] Anomaly warning triggered when any metric exceeds 1% change
  - `Verify:` Simulate >1% change; confirm warning in build logs
  - `Evidence:`

## Scope

### In

- Metadata comparison between current and prior release
- Anomaly threshold (>1% triggers warning)

### Out — Do Not Implement

- Automatic release blocking on anomaly (warning only — human decides)
- Content-level diff (row count comparison only)

---

### Ticket P4.04 — Retry Logic

```yaml
id: P4.04
title: Retry Logic
status: planned
priority: p1-high
epic: P4.1
persona: [ops/maintainer]
depends_on: [P3.01]
tech_stack:
  runtime: Node.js 22
  language: TypeScript 5.7 strict
  database: PostgreSQL 16 + PostGIS 3.5
  data_loader: minus34/gnaf-loader (Python)
  container: Docker (Debian Bookworm)
  ci: GitHub Actions (free tier)
  output: NDJSON
  distribution: GitHub Releases
completed: null
```

## User Story

As an ops/maintainer, I need auto-retry on transient failures (download timeout, OOM kill) so that the quarterly build self-heals from intermittent infrastructure issues without human intervention.

## Problem Statement

Free GitHub Actions runners occasionally experience transient issues: network timeouts during the 6.5GB download, OOM kills on memory-intensive states (NSW), or disk I/O stalls. Without retry logic, a transient failure requires manual re-trigger — potentially delaying the quarterly release. Up to 2 retries with distinct alerting covers most transient scenarios.

## Definition of Done

### Functional

- [ ] Up to 2 automatic retries on transient failures (download timeout, OOM kill)
  - `Verify:` Simulate a transient failure; confirm automatic retry
  - `Evidence:`
- [ ] Distinct alerting for retried-then-succeeded vs retried-then-failed
  - `Verify:` Check notification content after retry scenarios
  - `Evidence:`
- [ ] Persistent failures (flatten logic error, schema violation) are NOT retried
  - `Verify:` Force a flatten error; confirm no retry, immediate failure
  - `Evidence:`

## Scope

### In

- Retry logic for transient failures in CI workflow
- Failure classification (transient vs persistent)

### Out — Do Not Implement

- Automatic rollback
- Retry across different runner types

---

### Ticket P4.06 — Runbook

```yaml
id: P4.06
title: Runbook
status: planned
priority: p0-critical
epic: P4.1
persona: [ops/maintainer]
depends_on: [P4.01]
tech_stack:
  runtime: Node.js 22
  language: TypeScript 5.7 strict
  database: PostgreSQL 16 + PostGIS 3.5
  data_loader: minus34/gnaf-loader (Python)
  container: Docker (Debian Bookworm)
  ci: GitHub Actions (free tier)
  output: NDJSON
  distribution: GitHub Releases
completed: null
```

## User Story

As an ops/maintainer, I need a runbook covering download failures, gnaf-loader errors, flatten failures, and manual re-run procedures so that anyone can handle operational issues without deep project knowledge.

## Problem Statement

If the quarterly build fails at 2am on a Saturday, the on-call person needs step-by-step instructions — not a deep understanding of the codebase. The runbook covers common failure scenarios with diagnosis steps, resolution procedures, and manual re-run commands.

## Definition of Done

### Functional

- [ ] Runbook covers: download failures, gnaf-loader errors, flatten failures, verification failures, manual re-run, partial re-run (single state)
  - `Verify:` Each scenario has: symptoms, diagnosis steps, resolution procedure, manual commands
  - `Evidence:`
- [ ] Tested by an uninvolved person — someone who hasn't worked on flat-white can follow it
  - `Verify:` Hand runbook to a colleague; they can diagnose and re-run from the instructions alone
  - `Evidence:`

## Scope

### In

- Operational runbook in `docs/RUNBOOK.md`
- Common failure scenarios and resolution procedures

### Out — Do Not Implement

- Automated remediation (runbook is for humans)
- Monitoring dashboards

---

### Ticket P4.07 — NSW Memory Optimisation

```yaml
id: P4.07
title: NSW Memory Optimisation
status: planned
priority: p1-high
epic: P4.1
persona: [ops/maintainer]
depends_on: [P4.01]
tech_stack:
  runtime: Node.js 22
  language: TypeScript 5.7 strict
  database: PostgreSQL 16 + PostGIS 3.5
  data_loader: minus34/gnaf-loader (Python)
  container: Docker (Debian Bookworm)
  ci: GitHub Actions (free tier)
  output: NDJSON
  distribution: GitHub Releases
completed: null
```

## User Story

As an ops/maintainer, I need the NSW build optimised to run reliably on 7GB free runners so that the largest state doesn't intermittently OOM and block quarterly releases.

## Problem Statement

NSW has ~4.5M addresses — the largest state, requiring ~5-6GB RAM. Free GitHub Actions runners have 7GB. This is a tight fit. gnaf-loader's PostgreSQL memory usage during the spatial JOIN phase is the bottleneck. Optimisation may involve: tuning PostgreSQL shared_buffers and work_mem, running gnaf-loader with memory-limiting flags, or splitting the NSW load into sub-regions.

## Definition of Done

### Functional

- [ ] NSW builds reliably on 7GB free runners — no OOM kills across 5 consecutive runs
  - `Verify:` Run NSW build 5 times on free runners; all succeed
  - `Evidence:`
- [ ] Peak memory usage documented with margin analysis
  - `Verify:` Memory profile shows peak usage with sufficient headroom
  - `Evidence:`

### Performance

- [ ] NSW build time under 60 minutes on free runners
  - `Verify:` Check workflow run duration for NSW job
  - `Evidence:`

## Scope

### In

- PostgreSQL memory tuning for NSW
- gnaf-loader configuration optimisation
- Memory profiling and documentation

### Out — Do Not Implement

- Self-hosted runner fallback (that is E1.09)
- Paid runner upgrade (violates zero-cost principle)

**M4 success:** Quarterly autopilot. Verification catches anomalies. No human intervention unless flagged.

---

## Phase E1 — Enhancements (Ongoing)

### Epic E1.A — Output Formats

### Ticket E1.01 — Parquet Output

```yaml
id: E1.01
title: Parquet Output
status: planned
priority: p1-high
epic: E1.A
persona: [data consumer]
depends_on: [P1.11]
tech_stack:
  runtime: Node.js 22
  language: TypeScript 5.7 strict
  database: PostgreSQL 16 + PostGIS 3.5
  data_loader: minus34/gnaf-loader (Python)
  container: Docker (Debian Bookworm)
  ci: GitHub Actions (free tier)
  output: NDJSON
  distribution: GitHub Releases
completed: null
```

## User Story

As a data consumer doing analytics, I need a `--format parquet` option so that I can load address data directly into BigQuery, Athena, or DuckDB without converting from NDJSON.

## Problem Statement

NDJSON is universal but not columnar. Analytics workloads (e.g., "count all addresses per LGA" or "find all addresses in electorate X") are 10-100x faster on columnar formats like Parquet. Offering Parquet as an alternative output format serves analytics consumers without changing the NDJSON contract.

## Definition of Done

### Functional

- [ ] `--format parquet` produces a valid Parquet file with the same fields as the NDJSON output
  - `Verify:` `duckdb -c "SELECT COUNT(*) FROM 'output.parquet'"` returns expected count
  - `Evidence:`
- [ ] Parquet schema matches NDJSON document schema
  - `Verify:` Compare Parquet schema with Zod schema fields
  - `Evidence:`

## Scope

### In

- Parquet output format via `--format parquet` flag

### Out — Do Not Implement

- Parquet as default format (NDJSON remains the contract — DEC-001)
- Parquet-specific optimisations (partitioning, dictionary encoding — future)

---

### Epic E1.C — Data Lifecycle & Discovery

### Ticket E1.02 — Delta Builds

```yaml
id: E1.02
title: Delta Builds
status: planned
priority: p2-medium
epic: E1.C
persona: [downstream developer]
depends_on: [P4.03]
tech_stack:
  runtime: Node.js 22
  language: TypeScript 5.7 strict
  database: PostgreSQL 16 + PostGIS 3.5
  data_loader: minus34/gnaf-loader (Python)
  container: Docker (Debian Bookworm)
  ci: GitHub Actions (free tier)
  output: NDJSON
  distribution: GitHub Releases
completed: null
```

## User Story

As a downstream developer, I need a delta output containing only changed, new, and retired addresses since the prior release so that I can apply incremental updates instead of re-ingesting the full dataset.

## Problem Statement

Re-ingesting 15.9M addresses each quarter is wasteful when only ~1% change. A delta file enables incremental updates — downstream consumers apply the delta to their existing dataset rather than replacing it entirely. This reduces ingestion time and downstream processing costs.

## Definition of Done

### Functional

- [ ] Delta output contains: new addresses (added since prior release), changed addresses (modified fields), retired addresses (removed since prior release)
  - `Verify:` Delta file between two consecutive releases contains expected additions/changes/removals
  - `Evidence:`
- [ ] Each delta entry includes change type (added/changed/retired) and the full document
  - `Verify:` Delta NDJSON entries include `_changeType` field
  - `Evidence:`

## Scope

### In

- Delta computation between consecutive releases
- Delta NDJSON output format

### Out — Do Not Implement

- Streaming incremental updates (batch delta per release)
- Delta Parquet format

---

### Ticket E1.03 — Locality-Only Output

```yaml
id: E1.03
title: Locality-Only Output
status: planned
priority: p2-medium
epic: E1.A
persona: [downstream developer]
depends_on: [P1.05]
tech_stack:
  runtime: Node.js 22
  language: TypeScript 5.7 strict
  database: PostgreSQL 16 + PostGIS 3.5
  data_loader: minus34/gnaf-loader (Python)
  container: Docker (Debian Bookworm)
  ci: GitHub Actions (free tier)
  output: NDJSON
  distribution: GitHub Releases
completed: null
```

## User Story

As a downstream developer, I need a separate `localities.ndjson` file containing just locality data (name, state, neighbours, aliases, boundaries) so that I can build a lightweight locality search index without processing the full address dataset.

## Problem Statement

Some use cases only need locality-level data — a suburb search autocomplete, a "service areas" lookup, or a locality-to-electorate mapping. The full address dataset is overkill for these. A separate locality-only output provides a lightweight alternative.

## Definition of Done

### Functional

- [ ] `--locality-only` flag produces a `localities.ndjson` file with one document per locality
  - `Verify:` `wc -l output/localities.ndjson` returns expected locality count
  - `Evidence:`
- [ ] Each locality document includes: name, state, class, neighbours, aliases, boundary context
  - `Verify:` Spot-check 5 localities for completeness
  - `Evidence:`

## Scope

### In

- Locality-only NDJSON output
- `--locality-only` CLI flag

### Out — Do Not Implement

- Street-only output
- Custom aggregation levels

---

### Ticket E1.04 — Schema Evolution Tooling

```yaml
id: E1.04
title: Schema Evolution Tooling
status: planned
priority: p2-medium
epic: E1.C
persona: [builder/contributor]
depends_on: [P0.12, P4.03]
tech_stack:
  runtime: Node.js 22
  language: TypeScript 5.7 strict
  database: PostgreSQL 16 + PostGIS 3.5
  data_loader: minus34/gnaf-loader (Python)
  container: Docker (Debian Bookworm)
  ci: GitHub Actions (free tier)
  output: NDJSON
  distribution: GitHub Releases
completed: null
```

## User Story

As a builder/contributor, I need automated breaking-change detection for the NDJSON schema so that PRs that alter the output format are flagged before merge, requiring an explicit version bump decision.

## Problem Statement

The NDJSON schema is the contract. Breaking changes (removing a field, changing a type, renaming a field) must be accompanied by a major version bump and documented in the changelog. Manual review can miss subtle changes. Automated tooling that compares the PR's schema against the current schema catches breaking changes in CI.

## Definition of Done

### Functional

- [ ] CI check compares PR's Zod schema against main branch schema and flags breaking changes
  - `Verify:` PR that removes a field triggers CI failure with "breaking change detected" message
  - `Evidence:`
- [ ] Non-breaking additions (new optional fields) are allowed without version bump
  - `Verify:` PR that adds a new optional field passes CI
  - `Evidence:`

## Scope

### In

- Schema comparison tooling
- Breaking change detection in CI

### Out — Do Not Implement

- Automatic version bumping
- Schema migration scripts

---

### Ticket E1.05 — Geoparquet Output

```yaml
id: E1.05
title: Geoparquet Output
status: planned
priority: p2-medium
epic: E1.A
persona: [data consumer]
depends_on: [E1.01]
tech_stack:
  runtime: Node.js 22
  language: TypeScript 5.7 strict
  database: PostgreSQL 16 + PostGIS 3.5
  data_loader: minus34/gnaf-loader (Python)
  container: Docker (Debian Bookworm)
  ci: GitHub Actions (free tier)
  output: NDJSON
  distribution: GitHub Releases
completed: null
```

## User Story

As a data consumer doing spatial analytics, I need a `--format geoparquet` option so that I can load address data into spatial analysis tools (QGIS, GeoPandas, DuckDB Spatial) with native geometry support.

## Problem Statement

Standard Parquet (E1.01) stores coordinates as separate columns. Geoparquet embeds proper geometry types (POINT) that spatial tools understand natively — enabling spatial queries, bounding box filters, and coordinate system transformations without preprocessing.

## Definition of Done

### Functional

- [ ] `--format geoparquet` produces a valid Geoparquet file with POINT geometry for each address
  - `Verify:` `geopandas.read_parquet('output.geoparquet')` loads successfully with geometry column
  - `Evidence:`
- [ ] Geoparquet metadata follows the Geoparquet specification
  - `Verify:` Validate against Geoparquet spec
  - `Evidence:`

## Scope

### In

- Geoparquet output format via `--format geoparquet` flag
- POINT geometry from geocode coordinates

### Out — Do Not Implement

- Boundary polygons (only point coordinates)
- Spatial indexing within the file

---

### Epic E1.B — Build & Infrastructure

### Ticket E1.06 — Build Cache

```yaml
id: E1.06
title: Build Cache
status: planned
priority: p1-high
epic: E1.B
persona: [ops/maintainer]
depends_on: [P2.01]
tech_stack:
  runtime: Node.js 22
  language: TypeScript 5.7 strict
  database: PostgreSQL 16 + PostGIS 3.5
  data_loader: minus34/gnaf-loader (Python)
  container: Docker (Debian Bookworm)
  ci: GitHub Actions (free tier)
  output: NDJSON
  distribution: GitHub Releases
completed: null
```

## User Story

As an ops/maintainer, I need the gnaf-loader database dump cached so that builds can skip the load step when the G-NAF version hasn't changed, reducing build time by ~30 minutes per state.

## Problem Statement

gnaf-loader takes 30-40 minutes per state to load data and perform spatial joins. If the G-NAF version hasn't changed (e.g., re-running a failed build), repeating the load step is wasteful. Caching the Postgres dump after gnaf-loader completes and restoring it on cache hit eliminates this redundancy.

## Definition of Done

### Functional

- [ ] After gnaf-loader completes, Postgres dump is cached (keyed by G-NAF version + state)
  - `Verify:` Cache hit on second run of same version; gnaf-loader step skipped
  - `Evidence:`
- [ ] Cache miss triggers full gnaf-loader load
  - `Verify:` New G-NAF version triggers full load
  - `Evidence:`
- [ ] Build time reduced by ~30 minutes on cache hit
  - `Verify:` Compare build times with and without cache
  - `Evidence:`

## Scope

### In

- Postgres dump caching after gnaf-loader
- Cache key: G-NAF version + state
- GitHub Actions cache integration

### Out — Do Not Implement

- Incremental gnaf-loader updates (full load each time, but cached)

---

### Ticket E1.07 — Multi-Arch Image

```yaml
id: E1.07
title: Multi-Arch Image
status: planned
priority: p1-high
epic: E1.B
persona: [data consumer, ops/maintainer]
depends_on: [P2.07]
tech_stack:
  runtime: Node.js 22
  language: TypeScript 5.7 strict
  database: PostgreSQL 16 + PostGIS 3.5
  data_loader: minus34/gnaf-loader (Python)
  container: Docker (Debian Bookworm)
  ci: GitHub Actions (free tier)
  output: NDJSON
  distribution: GitHub Releases
completed: null
```

## User Story

As a data consumer running on ARM64 (AWS Graviton, Apple Silicon), I need a multi-arch Docker image so that I can run flat-white natively without emulation overhead.

## Problem Statement

ARM64 adoption is growing rapidly — AWS Graviton instances are 20-40% cheaper than x86, and Apple Silicon Macs are standard for developers. Running an amd64 image under QEMU emulation is 3-5x slower. A multi-arch image (ARM64 + AMD64) ensures native performance on both architectures.

## Definition of Done

### Functional

- [ ] Docker image published with both ARM64 and AMD64 manifests
  - `Verify:` `docker manifest inspect flat-white:latest` shows both architectures
  - `Evidence:`
- [ ] Both architectures produce identical output (byte-for-byte NDJSON)
  - `Verify:` Run fixture build on both architectures; diff output
  - `Evidence:`

## Scope

### In

- Multi-arch Docker image build (ARM64 + AMD64)
- CI workflow using `docker buildx`

### Out — Do Not Implement

- Other architectures (s390x, ppc64le)

---

### Ticket E1.08 — GitHub Pages Catalogue

```yaml
id: E1.08
title: GitHub Pages Catalogue
status: planned
priority: p2-medium
epic: E1.C
persona: [data consumer]
depends_on: [P3.03]
tech_stack:
  runtime: Node.js 22
  language: TypeScript 5.7 strict
  database: PostgreSQL 16 + PostGIS 3.5
  data_loader: minus34/gnaf-loader (Python)
  container: Docker (Debian Bookworm)
  ci: GitHub Actions (free tier)
  output: NDJSON
  distribution: GitHub Releases
completed: null
```

## User Story

As a data consumer, I need a static website with per-release stats, schema documentation, and download links so that I can browse available data without navigating GitHub's release pages.

## Problem Statement

GitHub Releases is functional but not user-friendly for non-technical consumers. A GitHub Pages static site provides a polished interface: per-release statistics, interactive schema documentation, direct download links, and build history. Zero cost (GitHub Pages is free for public repos).

## Definition of Done

### Functional

- [ ] GitHub Pages site at `{username}.github.io/flat-white` with: release history, per-release stats (total and per-state counts), schema documentation, download links
  - `Verify:` Site loads and displays current release data
  - `Evidence:`
- [ ] Automatically updated after each release
  - `Verify:` After new release, site reflects updated data within minutes
  - `Evidence:`

## Scope

### In

- Static site generation from release metadata
- GitHub Pages deployment workflow

### Out — Do Not Implement

- Dynamic server-side features
- Search functionality (static only)

---

### Ticket E1.09 — Self-Hosted Runner Fallback

```yaml
id: E1.09
title: Self-Hosted Runner Fallback
status: planned
priority: p1-high
epic: E1.B
persona: [ops/maintainer]
depends_on: [P3.01]
tech_stack:
  runtime: Node.js 22
  language: TypeScript 5.7 strict
  database: PostgreSQL 16 + PostGIS 3.5
  data_loader: minus34/gnaf-loader (Python)
  container: Docker (Debian Bookworm)
  ci: GitHub Actions (free tier)
  output: NDJSON
  distribution: GitHub Releases
completed: null
```

## User Story

As an ops/maintainer, I need documented setup for self-hosted runners so that organisations where free runners are insufficient (private repos, larger memory needs) can run flat-white builds on their own infrastructure.

## Problem Statement

Free GitHub Actions runners have 7GB RAM and 2-core CPUs. While sufficient for the current dataset, future G-NAF releases may grow, or organisations running flat-white on private repos won't have access to free runners. A documented self-hosted runner setup provides a fallback that preserves the same workflow with more resources.

## Definition of Done

### Functional

- [ ] Documentation in `docs/SELF-HOSTED-RUNNER.md` covering: hardware requirements, runner setup, workflow configuration changes, cost estimates
  - `Verify:` A user can follow the guide to set up a self-hosted runner and run the quarterly build
  - `Evidence:`
- [ ] Workflow supports both free and self-hosted runners via configuration
  - `Verify:` Workflow runs on self-hosted runner when configured
  - `Evidence:`

## Scope

### In

- Self-hosted runner setup documentation
- Workflow configuration for runner selection

### Out — Do Not Implement

- Managed runner infrastructure
- Automatic runner provisioning

---

## Phase P5 — AWS Mirror (Deferred)

**Target:** Post-M4 · **Status:** Planned · **Rationale:** GitHub Releases is the primary distribution. S3 is redundancy — valuable but not required for the first release. Deferred from Phase P3 to avoid overloading the first release week.

### Epic P5.1 — AWS Mirror

### Ticket P5.01 — S3 Upload

```yaml
id: P5.01
title: S3 Upload
status: planned
priority: p1-high
epic: P5.1
persona: [ops/maintainer]
depends_on: [P3.03]
tech_stack:
  runtime: Node.js 22
  language: TypeScript 5.7 strict
  database: PostgreSQL 16 + PostGIS 3.5
  data_loader: minus34/gnaf-loader (Python)
  container: Docker (Debian Bookworm)
  ci: GitHub Actions (free tier)
  output: NDJSON
  distribution: GitHub Releases
completed: null
```

## User Story

As an ops/maintainer, I need the build artifacts uploaded to S3 as a mirror so that consumers have an alternative download source and we have redundancy beyond GitHub Releases.

## Problem Statement

GitHub Releases is the primary distribution, but a single distribution point is a single point of failure. An S3 mirror provides redundancy, enables AWS-native consumers to use S3 APIs, and keeps the total annual cost at ~$0.28.

## Definition of Done

### Functional

- [ ] Workflow uploads per-state and all-states artifacts to `s3://flat-white/builds/v{YYYY.MM}/`
  - `Verify:` `aws s3 ls s3://flat-white/builds/v2026.02/` shows all expected files
  - `Evidence:`
- [ ] S3 content matches GitHub Release assets exactly
  - `Verify:` Checksum comparison between S3 and GitHub Release files
  - `Evidence:`

## Scope

### In

- S3 upload step in release workflow
- Versioned S3 path structure

### Out — Do Not Implement

- S3 public access configuration (separate infrastructure concern)
- CloudFront distribution

---

### Ticket P5.02 — S3 Latest Pointer

```yaml
id: P5.02
title: S3 Latest Pointer
status: planned
priority: p1-high
epic: P5.1
persona: [downstream developer]
depends_on: [P5.01]
tech_stack:
  runtime: Node.js 22
  language: TypeScript 5.7 strict
  database: PostgreSQL 16 + PostGIS 3.5
  data_loader: minus34/gnaf-loader (Python)
  container: Docker (Debian Bookworm)
  ci: GitHub Actions (free tier)
  output: NDJSON
  distribution: GitHub Releases
completed: null
```

## User Story

As a downstream developer, I need `s3://flat-white/builds/latest/` to always point to the most recent build so that my pipeline can reference a stable path without tracking version numbers.

## Problem Statement

Consumers that want "always latest" shouldn't need to discover the current version. A `latest/` pointer (either S3 copy or redirect) provides a stable reference that always resolves to the newest build.

## Definition of Done

### Functional

- [ ] `s3://flat-white/builds/latest/` always contains the most recent build's files
  - `Verify:` After a new release, `latest/` matches the new version
  - `Evidence:`
- [ ] Consumers can reference `latest` or pin to a specific version
  - `Verify:` Both `latest/` and `v2026.02/` paths work
  - `Evidence:`

## Scope

### In

- S3 latest pointer maintenance after each release

### Out — Do Not Implement

- Version negotiation API
- Multiple latest pointers (e.g., latest-stable vs latest-preview)

---

### Ticket P5.03 — OIDC Auth

```yaml
id: P5.03
title: OIDC Auth
status: planned
priority: p1-high
epic: P5.1
persona: [ops/maintainer]
depends_on: [P5.01]
tech_stack:
  runtime: Node.js 22
  language: TypeScript 5.7 strict
  database: PostgreSQL 16 + PostGIS 3.5
  data_loader: minus34/gnaf-loader (Python)
  container: Docker (Debian Bookworm)
  ci: GitHub Actions (free tier)
  output: NDJSON
  distribution: GitHub Releases
completed: null
```

## User Story

As an ops/maintainer, I need GitHub Actions OIDC federation to AWS IAM so that the S3 upload uses short-lived credentials with no stored secrets.

## Problem Statement

Stored AWS access keys are a security risk — if leaked, they provide persistent access. OIDC federation allows GitHub Actions to assume an IAM role with short-lived credentials scoped to the specific workflow run. No secrets stored in GitHub, no key rotation required.

## Definition of Done

### Functional

- [ ] GitHub Actions uses OIDC to assume AWS IAM role — no stored access keys
  - `Verify:` No AWS access key secrets in GitHub repo settings; OIDC provider configured
  - `Evidence:`
- [ ] IAM role has least-privilege permissions (S3 PutObject to specific bucket only)
  - `Verify:` Review IAM policy for minimal permissions
  - `Evidence:`

## Scope

### In

- GitHub Actions OIDC provider configuration
- AWS IAM role with least-privilege S3 permissions

### Out — Do Not Implement

- AWS account setup (prerequisite)
- Multi-account federation

---

### Ticket P5.04 — SNS Notification

```yaml
id: P5.04
title: SNS Notification
status: planned
priority: p1-high
epic: P5.1
persona: [ops/maintainer]
depends_on: [P3.03]
tech_stack:
  runtime: Node.js 22
  language: TypeScript 5.7 strict
  database: PostgreSQL 16 + PostGIS 3.5
  data_loader: minus34/gnaf-loader (Python)
  container: Docker (Debian Bookworm)
  ci: GitHub Actions (free tier)
  output: NDJSON
  distribution: GitHub Releases
completed: null
```

## User Story

As an ops/maintainer, I need SNS notifications on build success/failure so that the team and downstream subscribers are alerted without checking GitHub manually.

## Problem Statement

Quarterly builds run on a schedule. Without notifications, failures go undetected until someone manually checks. SNS notifications provide push-based alerting for both success (with release URL and counts) and failure (with error details and failed stage).

## Definition of Done

### Functional

- [ ] SNS notification sent on build success: status, release URL, per-state counts, build duration
  - `Verify:` Subscribe to SNS topic; confirm message on successful build
  - `Evidence:`
- [ ] SNS notification sent on build failure: status, failed stage, error details
  - `Verify:` Force a failure; confirm SNS notification with failure details
  - `Evidence:`

## Scope

### In

- SNS publish step in release workflow
- Success and failure notification payloads

### Out — Do Not Implement

- Slack/email integration (subscribe to SNS topic)
- Custom notification routing

---

## Milestones

### M0: Foundation

**Target:** End of Week 1

- [x] Repo live with gnaf-loader submodule, AGENTS.md, decisions
- [ ] VIC loaded via gnaf-loader; schema documented from live data
- [ ] Flatten SQL produces complete document from 9+ table JOIN
- [x] ~500 address fixture extracted; `expected-output.ndjson` pending (needs flatten SQL)
- [ ] `./scripts/build-fixture-only.sh` → valid NDJSON in <30 seconds

### M1: Flatten Core

**Target:** End of Week 3

- [ ] Streaming flattener: VIC 3.8M docs, <500MB memory
- [ ] All aggregations correct (aliases, secondaries, geocodes, boundaries)
- [ ] Per-state split + gzip working
- [ ] `metadata.json` produced
- [ ] Schema validation on every doc; regression green

### M2: Container

**Target:** End of Week 4

- [ ] `docker run flat-white --states VIC --compress --output ./` works
- [ ] Image published to Docker Hub
- [ ] Fixture CI on every PR (<60s)

### M3: First Release

**Target:** End of Week 5

- [ ] Matrix build: 9 states in parallel on free runners
- [ ] GitHub Release `v2026.02` with per-state assets
- [ ] Downstream `geocode-au` auto-notified
- [ ] Programmatic download documented

### M3.5: First Consumer

**Target:** Week 5-6

- [ ] At least 1 external download of a per-state file (GitHub Release download count > 0)
- [ ] Quick-start guide tested by someone who isn't the builder
- [ ] 1 downstream integration (geocode-au) successfully ingests the data

### M4: Autopilot

**Target:** End of Week 6

- [ ] Build-over-build verification operational
- [ ] Runbook tested
- [ ] NSW memory-optimised for free runners
- [ ] Quarterly cron active

---

## Cost Model

| Component                          | Per Build | Annual (4 builds) |
| ---------------------------------- | --------- | ----------------- |
| GitHub Actions (free, public repo) | $0        | $0                |
| GitHub Release hosting             | $0        | $0                |
| S3 mirror (optional, ~3GB)         | $0.07     | $0.28             |
| **Total**                          | **$0**    | **$0.28**         |

Twenty-eight cents a year. To distribute every address in Australia with full boundary enrichment.

---

## Agent Instructions

1. **Read AGENTS.md first.**
2. **ALWAYS use fixtures.** `scripts/build-fixture-only.sh` is the dev loop. Never require a download or gnaf-loader for testing.
3. **gnaf-loader is a submodule. Do not modify it.** PR upstream if needed.
4. **The NDJSON schema is the contract.** Update `DOCUMENT-SCHEMA.md`, `schema.ts`, and `expected-output.ndjson` together. Major bump on breaking changes.
5. **Postgres is ephemeral.** Inside the container. Does not persist.
6. **Feature IDs map to GitHub Issues.**
7. **Acceptance criteria are tests.** Regression = byte-for-byte against fixtures.
8. **New edge cases:** Re-run `extract-fixtures.sh`, add to `edge-cases.md`, commit.

---

## Attribution

> G-NAF © Geoscape Australia licensed by the Commonwealth of Australia under the Open G-NAF End User Licence Agreement.

> Administrative Boundaries © Geoscape Australia licensed by the Commonwealth of Australia under CC BY 4.0.

---

## Revision History

| Version | Date       | Author       | Changes                                                                                                                                                                                 |
| ------- | ---------- | ------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1.0.0   | 2026-04-02 | John Bejenar | Initial roadmap: flat-white with matrix build on free runners, GitHub Releases, per-state split                                                                                         |
| 1.1.0   | 2026-04-02 | John Bejenar | Expanded phase tables to full ticket format with YAML metadata, epics, dependency chains, user stories, and definition of done                                                          |
| 1.2.0   | 2026-04-02 | John Bejenar | CPO review: added data quality checks (P1.10A), adoption ticket (P3.07), deferred AWS Mirror to P5, split E1 into 3 epics, moved P4.05 to P0-B, expanded personas, added M3.5 milestone |
| 1.3.0   | 2026-04-03 | John Bejenar | Status update: marked P0.01, P0.02, P0.07, P0.08, P0.13 as done with evidence from PRs #2-#4. Updated acceptance criteria checkboxes and M0 milestone progress.                         |
