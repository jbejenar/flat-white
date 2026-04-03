# DEC-007 — GitHub Releases Distribution

## Status

Accepted

## Context

flat-white needs to distribute per-state gzipped NDJSON files (~1.2GB total compressed) to anyone in Australia who wants address data. The distribution mechanism must be free, programmatically accessible, and require no authentication for public downloads.

## Decision

Publish per-state `.ndjson.gz` files as GitHub Release assets. Each quarterly release is tagged `v{YYYY.MM}`. Consumers download via `gh release download` or direct URL. Downstream services are notified via `repository_dispatch`.

## Alternatives Considered

- **S3 + CloudFront:** Better for high-traffic distribution (CDN caching, range requests). But introduces AWS costs, IAM management, and infrastructure complexity. Deferred to P5 as an optional mirror.
- **npm registry:** Wrong tool — npm is for code packages, not multi-GB data files. Size limits would require splitting.
- **data.gov.au hosting:** The source data is already there. flat-white's value is the transformation, not re-hosting. Also, data.gov.au upload is manual and slow.
- **Git LFS:** GitHub's LFS has bandwidth limits on free tier (1GB/month). A single popular state file could exhaust the quota.

## Consequences

- Free hosting with no bandwidth limits for public repositories.
- Programmatic download: `gh release download v2026.02 --pattern '*-vic.ndjson.gz'`.
- GitHub Release asset limit is 2GB per file — total compressed output (~1.2GB) fits comfortably.
- Version history is maintained via Git tags — consumers can pin to a specific release.
- `repository_dispatch` enables downstream automation (e.g. geocode-au auto-ingestion).
- No CDN — downloads come directly from GitHub's asset servers. Acceptable for quarterly releases with modest download volume.
