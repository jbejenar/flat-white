# flat-white

### Australian addresses. Flattened and served.

> Last updated: 2026-04-02 · Roadmap version: 1.0.0

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

| Layer | Technology | Rationale |
|---|---|---|
| Database | PostgreSQL 16 + PostGIS 3.5 | Ephemeral, inside container. gnaf-loader's native target. |
| Data loader | `minus34/gnaf-loader` (Python) | 922 commits, 10 years maintained. All G-NAF + Admin Boundary edge cases. Pinned as submodule. |
| Flattener | Node.js 22 / TypeScript | Streams rows from Postgres, composes documents, writes NDJSON. ~300 lines. |
| Container | Docker (Debian Bookworm base) | Self-contained: Postgres + PostGIS + Python + Node + gnaf-loader + flattener. |
| CI/CD | GitHub Actions (free tier) | Matrix build: one job per state, parallel, on free runners. |
| Output | NDJSON (Newline-Delimited JSON) | One document per line. Universal. Streamable. Per-state gzipped. |
| Distribution | GitHub Releases | Per-state `.ndjson.gz` as release assets. Free hosting. Programmatic download. |

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
├── fixtures/                         # Committed test data — NO gnaf-loader required
│   ├── README.md                     # What's in the fixture, why each row exists
│   ├── seed-postgres.sql             # Small fixture (~500 addresses, all edge cases)
│   ├── expected-output.ndjson        # Known-good output for regression
│   ├── expected-output-sample.json   # Single prettified doc for human reference
│   └── edge-cases.md                 # Catalogue of edge cases + which rows cover them
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
    { "lat": -37.79821100, "lng": 144.89725400, "type": "PC", "reliability": 2 },
    { "lat": -37.79810500, "lng": 144.89712200, "type": "PAP", "reliability": 2 }
  ],
  "locality": {
    "pid": "loc67a11408d754",
    "class": "GAZETTED LOCALITY",
    "neighbours": ["ASCOT VALE", "FLEMINGTON", "KENSINGTON", "MAIDSTONE", "MARIBYRNONG", "SEDDON", "WEST FOOTSCRAY", "YARRAVILLE"],
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
    { "pid": "MA13517230", "label": "SHOP 1 GROUND 1 MCNAB AV, FOOTSCRAY VIC 3011", "type": "SYNONYM" }
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
        description: 'G-NAF version (e.g., 2026.02)'
        required: true
  schedule:
    - cron: '0 6 15 2,5,8,11 *'  # 15th of Feb/May/Aug/Nov

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

| State | Addresses | Est. RAM | Est. Time | Fits 7GB? |
|---|---|---|---|---|
| VIC | ~3.8M | ~4-5 GB | ~40 min | Yes |
| NSW | ~4.5M | ~5-6 GB | ~50 min | Tight but yes |
| QLD | ~2.9M | ~3-4 GB | ~35 min | Yes |
| WA | ~1.3M | ~2 GB | ~20 min | Yes |
| SA | ~1.1M | ~2 GB | ~18 min | Yes |
| TAS | ~310K | ~1 GB | ~8 min | Yes |
| ACT | ~220K | ~1 GB | ~6 min | Yes |
| NT | ~98K | ~1 GB | ~4 min | Yes |
| OT | ~3K | ~1 GB | ~2 min | Yes |

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

| Phase | Name | Duration | Outcome |
|---|---|---|---|
| **P0-A** | Data Acquisition | 2 days | VIC loaded into local Postgres, schema explored, edge cases identified |
| **P0-B** | Fixture + Scaffold | 3 days | Postgres fixtures committed, flatten SQL verified, repo structure complete |
| **P1** | Flatten Core | 2 weeks | Streaming NDJSON, per-state split, gzip, schema validated, all edge cases |
| **P2** | Container | 1 week | Dockerfile, one `docker run` produces NDJSON from raw data |
| **P3** | Distribution | 1 week | GitHub Actions matrix build, GitHub Releases, downstream notification |
| **P4** | Hardening | 1 week | Verification, build-over-build comparison, monitoring, runbook |
| **E1** | Enhancements | Ongoing | Parquet, delta builds, locality output, schema evolution |

---

## Phase P0 — Foundation

**Target:** Week 1 · **Status:** Planned

### P0-A — Data Acquisition (Days 1-2)

| ID | Feature | Pri | Description | Acceptance Criteria |
|---|---|---|---|---|
| P0.01 | Repo scaffold | P0 | Create repo with full structure, AGENTS.md, manifest.json, docker-compose, gnaf-loader submodule | `git clone --recurse-submodules` pulls gnaf-loader at pinned release |
| P0.02 | Local Postgres + PostGIS | P0 | docker-compose with Postgres 16 + PostGIS 3.5 | `docker compose up db` starts Postgres |
| P0.03 | G-NAF download script | P0 | `src/download.ts` fetches Feb 2026 G-NAF GDA2020 + Admin Boundaries ESRI Shapefiles | Downloads ~6.5GB, extracts to `./data/` |
| P0.04 | gnaf-loader VIC load | P0 | Run gnaf-loader against local Postgres; VIC-only | `address_principals` has ~3.8M rows; boundary tags present |
| P0.05 | Schema exploration | P0 | Document loaded schema: table names, row counts, join paths, boundary tag columns | `docs/FIELD-PROVENANCE.md` maps every target field to source table.column |
| P0.06 | Flatten SQL draft | P0 | `sql/address_full.sql` — master JOIN across 9+ tables | Complete flat row for any VIC PID; all boundary fields populated |

**P0-A gate:** Loaded VIC database. Flatten SQL produces target document. Every field traced.

### P0-B — Fixture + Dev Environment (Days 3-5)

| ID | Feature | Pri | Description | Acceptance Criteria |
|---|---|---|---|---|
| P0.07 | Fixture extraction | P0 | ~500 addresses covering all edge cases, exported as `seed-postgres.sql` | Standard (50+), units/levels (50+), rural (20+), Melbourne 3000/3004 (20+), aliases (20+), primary-secondary (20+), multi-geocode (20+), boundary edges (10+), retired (10+) |
| P0.08 | Edge case catalogue | P0 | `fixtures/edge-cases.md` — every edge case with its fixture row | Reviewable by humans and agents |
| P0.09 | Expected output | P0 | Flatten against fixtures, verify, commit as `expected-output.ndjson` | Regression baseline established |
| P0.10 | Fixture-only build | P0 | `scripts/build-fixture-only.sh` — seed Postgres, flatten, output NDJSON | <30 seconds. No download. No gnaf-loader. |
| P0.11 | Document schema spec | P0 | `docs/DOCUMENT-SCHEMA.md` — complete field reference | The contract. Reviewed. |
| P0.12 | Zod schema | P0 | `src/schema.ts` — runtime validation | Every doc validates |
| P0.13 | AGENTS.md | P0 | Agent instructions: fixtures, submodule rules, schema contract | Agent-executable from AGENTS.md alone |
| P0.14 | Decision records | P0 | DEC-001 through DEC-007 | Context, decision, consequences |

**M0 success:** `./scripts/build-fixture-only.sh` → valid NDJSON in <30 seconds. Schema validates. Every field traced.

---

## Phase P1 — Flatten Core

**Target:** Weeks 2-3 · **Status:** Planned

| ID | Feature | Pri | Description | Acceptance Criteria |
|---|---|---|---|---|
| P1.01 | Streaming flatten | P0 | Cursor-based streaming from Postgres, line-by-line NDJSON | <500MB memory regardless of dataset size |
| P1.02 | Alias aggregation | P0 | `aliases[]` array per principal address | All aliases for a principal in one document |
| P1.03 | Secondary aggregation | P0 | `secondaries[]` array per primary address | All child units/flats in parent document |
| P1.04 | Multi-geocode aggregation | P0 | `allGeocodes[]` array per address | All geocode types listed |
| P1.05 | Locality context | P0 | `locality.neighbours[]` and `locality.aliases[]` | Populated from LOCALITY_NEIGHBOUR + LOCALITY_ALIAS |
| P1.06 | Boundary enrichment | P0 | LGA, electoral, ABS tags from `address_principal_admin_boundaries` | All boundary fields populated |
| P1.07 | Street context | P0 | `street.class` and `street.aliases[]` | Populated |
| P1.08 | addressLabelSearch | P0 | Expanded label: full street type, full flat type | Distinct from addressLabel; search-optimised |
| P1.09 | Schema validation | P0 | Every doc validated against Zod during flatten | Build fails on invalid doc |
| P1.10 | Row count verification | P0 | Output count vs source count | Within 0.1% |
| P1.11 | Full VIC build | P0 | End-to-end: download → gnaf-loader → flatten → NDJSON | ~3.8M docs in <45 min; 50 PIDs spot-checked |
| P1.12 | Output metadata | P0 | `metadata.json`: version, states, per-state counts, schema version, build timestamp | Machine-readable; consumers verify without opening NDJSON |
| P1.13 | Per-state split | P0 | `--split-states` produces one file per state | 9 state files; counts match source; each has metadata line |
| P1.14 | Gzip compression | P0 | `--compress` streams gzip output | ~85-90% compression; each `.ndjson.gz` is valid gzip |
| P1.15 | Regression tests | P0 | Fixture build compared against `expected-output.ndjson` | CI fails on any change without fixture update |
| P1.16 | Performance baseline | P1 | VIC build time, memory, file sizes, per-state row counts | `docs/PERFORMANCE.md` |

**M1 success:** 3.8M VIC NDJSON. Per-state split + gzip. All aggregations correct. Schema validated. Regression green.

---

## Phase P2 — Container

**Target:** Week 4 · **Status:** Planned

| ID | Feature | Pri | Description | Acceptance Criteria |
|---|---|---|---|---|
| P2.01 | Dockerfile | P0 | Self-contained: Postgres 16 + PostGIS + Python + gnaf-loader + Node + flattener | Image <3GB |
| P2.02 | Entrypoint | P0 | Start Postgres → download → gnaf-loader → flatten → output → stop Postgres | One `docker run` → valid NDJSON |
| P2.03 | CLI arguments | P0 | `--states`, `--output`, `--split-states`, `--compress`, `--skip-download`, `--gnaf-path`, `--admin-path`, `--fixture-only` | All flags work; `--help` documents them |
| P2.04 | Exit codes | P0 | Distinct per failure type | CI distinguishes failures |
| P2.05 | Volume mount | P0 | `-v $(pwd)/output:/output` | Output on host filesystem |
| P2.06 | Progress logging | P1 | Structured JSON: stage, progress %, rows, elapsed | Parseable + human-readable |
| P2.07 | Image publish | P0 | GitHub Actions → Docker Hub on tag | `docker pull flat-white:latest` |
| P2.08 | Fixture CI | P0 | Every PR runs fixture build + regression | <60 seconds; schema changes caught |

**M2 success:** `docker run flat-white --states VIC --compress --output ./` — one command, valid gzipped NDJSON.

---

## Phase P3 — Distribution

**Target:** Week 5 · **Status:** Planned

### GitHub Releases (Public)

| ID | Feature | Pri | Description | Acceptance Criteria |
|---|---|---|---|---|
| P3.01 | Matrix build workflow | P0 | `quarterly-build.yml` — 9 parallel jobs (one per state) on free runners, manual trigger + scheduled cron | All 9 states build in parallel; total wall-clock <60 min |
| P3.02 | All-states concatenation | P0 | Release job concatenates per-state gzips into `flat-white-{version}-all.ndjson.gz` | All-states file valid; doc count = sum of state counts |
| P3.03 | GitHub Release creation | P0 | Tagged release `v{YYYY.MM}` with per-state `.ndjson.gz` + metadata + schema as assets | Total assets <2GB (GitHub limit); all states present |
| P3.04 | Release notes | P0 | Auto-generated: total + per-state counts, delta from prior, schema version | Non-technical reader understands the release |
| P3.05 | Downstream dispatch | P0 | `repository_dispatch` to `geocode-au` serving repo with version + asset URLs | Downstream pipeline auto-triggers |
| P3.06 | Download docs | P1 | `gh release download v2026.02 --pattern '*-vic.ndjson.gz'` documented | Anyone can script it |

### AWS Mirror (Operational)

| ID | Feature | Pri | Description | Acceptance Criteria |
|---|---|---|---|---|
| P3.07 | S3 upload | P1 | Workflow uploads artifacts to `s3://flat-white/builds/v{YYYY.MM}/` | S3 matches GitHub Release assets |
| P3.08 | S3 latest pointer | P1 | `s3://flat-white/builds/latest/` always current | Consumers reference `latest` or pin |
| P3.09 | OIDC auth | P1 | GitHub Actions OIDC → AWS IAM role, no stored keys | Least privilege |
| P3.10 | SNS notification | P1 | Success/failure: status, release URL, counts, duration | Team + downstream subscribed |

**M3 success:** `v2026.02` release live. Per-state gzipped NDJSON downloadable. Downstream auto-triggered. Anyone in Australia can download pre-joined address data from the release page. Cost: $0.

---

## Phase P4 — Hardening

**Target:** Week 6 · **Status:** Planned

| ID | Feature | Pri | Description | Acceptance Criteria |
|---|---|---|---|---|
| P4.01 | All-states production release | P0 | First real quarterly release via matrix build | All states present; release assets valid |
| P4.02 | Verification report | P0 | Per-state row counts, boundary coverage %, schema results | Uploaded as release asset |
| P4.03 | Build-over-build comparison | P0 | Delta from prior: total, per-state, new/retired addresses | >1% anomaly triggers warning |
| P4.04 | Retry logic | P1 | Auto-retry on transient failures (download timeout, OOM) | Up to 2 retries; distinct alerting |
| P4.05 | gnaf-loader tracking | P0 | Automated PR when new gnaf-loader release detected | Never >1 release behind |
| P4.06 | Runbook | P0 | Download failures, gnaf-loader errors, flatten failures, manual re-run | Tested by uninvolved person |
| P4.07 | NSW memory optimisation | P1 | NSW (~4.5M) is the tightest fit on free runners; optimise gnaf-loader memory | NSW builds reliably on 7GB runner |

**M4 success:** Quarterly autopilot. Verification catches anomalies. No human intervention unless flagged.

---

## Phase E1 — Enhancements (Ongoing)

| ID | Feature | Pri | Description |
|---|---|---|---|
| E1.01 | Parquet output | P1 | `--format parquet` for analytics consumers |
| E1.02 | Delta builds | P2 | Output only changed/new/retired since prior release |
| E1.03 | Locality-only output | P2 | Separate `localities.ndjson` for locality search index |
| E1.04 | Schema evolution tooling | P2 | Automated breaking-change detection |
| E1.05 | Geoparquet output | P2 | `--format geoparquet` for spatial analytics |
| E1.06 | Build cache | P1 | Cache gnaf-loader dump; skip reload if version unchanged |
| E1.07 | Multi-arch image | P1 | ARM64 + AMD64 for Graviton |
| E1.08 | GitHub Pages catalogue | P2 | Static site: per-release stats, schema docs, download links |
| E1.09 | Self-hosted runner fallback | P1 | Documented setup for orgs where free runners aren't sufficient |

---

## Milestones

### M0: Foundation

**Target:** End of Week 1

- [ ] Repo live with gnaf-loader submodule, AGENTS.md, decisions
- [ ] VIC loaded via gnaf-loader; schema documented from live data
- [ ] Flatten SQL produces complete document from 9+ table JOIN
- [ ] ~500 address fixture extracted; `expected-output.ndjson` committed
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

### M4: Autopilot

**Target:** End of Week 6

- [ ] Build-over-build verification operational
- [ ] Runbook tested
- [ ] NSW memory-optimised for free runners
- [ ] Quarterly cron active

---

## Cost Model

| Component | Per Build | Annual (4 builds) |
|---|---|---|
| GitHub Actions (free, public repo) | $0 | $0 |
| GitHub Release hosting | $0 | $0 |
| S3 mirror (optional, ~3GB) | $0.07 | $0.28 |
| **Total** | **$0** | **$0.28** |

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

| Version | Date | Author | Changes |
|---|---|---|---|
| 1.0.0 | 2026-04-02 | John Bejenar | Initial roadmap: flat-white with matrix build on free runners, GitHub Releases, per-state split |
