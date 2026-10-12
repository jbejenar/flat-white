# Next work — flat-white

> Updated: 2026-10-12. **Schema 1.0.0 change:** the current migration targets
> ASGS 2026. Earlier April work records are retained below as history, not the
> active release plan.

## Current focus

The audited enrichment work is published in
[v2026.08.3](https://github.com/jbejenar/flat-white/releases/tag/v2026.08.3):
**15,108,510 addresses, schema 1.1.0, ASGS 2026**. All nine state builds and
national verification passed. The full comparison with the preceding correction
uses identical source-archive bytes and finds no added/removed IDs or unexpected
changes. Only the new fallback field and 57,844 Camden ward fills change.
Read-only checks verified all 69 S3 objects, and the live catalogue shows the
correct count, schema and ASGS year. The audited release plan is complete.

The preceding [v2026.08.2](https://github.com/jbejenar/flat-white/releases/tag/v2026.08.2)
is the schema 1.0 correction and rollback reference. The original ASGS 2026
migration shipped in `v2026.08` through PRs #204 and #205. See the dated
[changelog](CHANGELOG.md) and [schema 1.1 upgrade guide](docs/MIGRATING-TO-SCHEMA-1.1.md).

- Catalogue repair is merged in PR #207; the September 30 deployment now reads
  validated release metadata and shows the correct counts and schema.
- Completed implementation stages:
  1. OT federal dependencies, exact PID reconciliation, shared coverage gates
     and atomic assignment rebuilding. Upstream fix: [PR #104](https://github.com/minus34/gnaf-loader/pull/104).
     Merged in [PR #208](https://github.com/jbejenar/flat-white/pull/208).
     [v2026.08.2](https://github.com/jbejenar/flat-white/releases/tag/v2026.08.2)
     restores 3,803 federal assignments; two source-boundary exceptions remain null.
  2. Locked source bytes, deterministic cache identity and dated boundary preparation.
     Implementation includes publication/recovery evidence and real dump/restore checks.
     Merged in PR #209. Draft v2026.08.1 was held for three SA site-point ties.
     PR #222 fixes their ordering. Correction
     [38185895740](https://github.com/jbejenar/flat-white/actions/runs/38185895740)
     published v2026.08.2 with all nine states passing and no unexpected changes.
     All 47 S3 objects passed read-only size/SHA-256 checks; the catalogue is updated.
     Keep the superseded v2026.08.1 draft unpublished.
     Upstream date policy: [PR #105](https://github.com/minus34/gnaf-loader/pull/105).
  3. Schema 1.1.0 `fallbackGeocode`, deterministic valid site-point selection,
     converter/CRS and compatibility checks merged in [PR #221](https://github.com/jbejenar/flat-white/pull/221).
     Primary geometry stays null when only street/locality coordinates exist.
     [National build 38193082828](https://github.com/jbejenar/flat-white/actions/runs/38193082828)
     published v2026.08.3 from the v2026.08.2 source lock. There are 14,822,288
     site points, 276,837 street fallbacks and 9,385 locality fallbacks nationally.
  4. Qualify official NSW council ward snapshots, starting with the sampled
     councils where licensing and currency permit. Assign only qualifying site
     points; publish coverage reasons and dated source evidence. Camden is qualified
     for 31 August 2026. [PR #224](https://github.com/jbejenar/flat-white/pull/224)
     merged with all checks passing. It includes a source lock, strict site-point
     eligibility, independent spatial verification of every eligible exported point,
     and evidence mirroring. The 451-document baseline, real SQL integration,
     empty-database verifier and fixture container pass.
     The final national artifacts passed the independent spatial check: all
     57,844 eligible Camden addresses matched, with no unmatched or ambiguous
     points; 947 insufficiently precise addresses remain excluded. See
     [the source guide](docs/NSW-WARD-SOURCES.md).
  5. Both immutable releases are public. All PIDs and fields were compared,
     and all 58 schema 1.1 evidence files match their GitHub checksums.
     The S3 manifest is `manifests/address-2026-08-3.json`; all 69 data, mapping
     and evidence objects passed size/SHA-256 checks. [Catalogue deployment
     38199929841](https://github.com/jbejenar/flat-white/actions/runs/38199929841)
     passed, and its live page was checked over HTTP.
- Upstream loader repairs [#103](https://github.com/minus34/gnaf-loader/pull/103),
  [#104](https://github.com/minus34/gnaf-loader/pull/104) and
  [#105](https://github.com/minus34/gnaf-loader/pull/105) merged on 4–5 October.
  As of 12 October, the latest published upstream release is still `202608`,
  which predates those repairs. Keep the recorded `a0fec3b` pin until a replacement
  containing all three fixes passes the authority, dependency/date and existing
  compatibility checks. The published builds retain their exact original pin.
- Record national build memory/capacity evidence separately from the successful
  publication and the small random-sample check. Neither proves every source
  field is complete or every geographic assignment is correct.
- Coordinate downstream geographic references, index rebuilds, comparisons and
  rollback using the migration guide. Do not assume every consumer of `latest`
  already supports the new contract.
- Docker Hub distribution needs separate setup and verification. On 12 October,
  the repository exposed no Docker publication runs or repository secrets for
  `DOCKER_USERNAME` / `DOCKER_PASSWORD`. Current README instructions build the
  image from source, as the quarterly data workflow does. Before advertising a
  published image, configure its destination and credentials, connect publication
  to an approved release, and verify both architectures. A tag created with
  `GITHUB_TOKEN` [does not trigger the tag-push workflow](https://docs.github.com/en/actions/concepts/security/github_token).
  The historical P2.07/E1.07 checkboxes record implemented workflow code; they do
  not establish current registry availability.

## Follow-up findings from the release sample check

A reproducible random check of two records from each of the nine published state
files found all 18 ASGS 2026 hierarchies consistent with the ABS service. All 17
available geocodes intersected their recorded mesh block. This is a spot check,
not certification of every field or of the complete dataset.

- **Other Territories findings addressed:** the original sample exposed both a
  loader defect and a source limitation. The correction restores Bean for
  `GAOT_718710324` (39D Taylors Road, Norfolk Island). `GAOT_717320346` (30 Jalan
  Kembang Molok, Home Island) still has no source site point; the schema 1.1 build
  now exposes its street-level default separately, with primary geometry null.
  All 3,805 OT records were rechecked: 3,394 site points, 332 street fallbacks and
  79 locality fallbacks. The two remaining federal nulls, `GAOT_720637896` and
  `GAOT_720637906`, lie outside the supplied Bean polygon. Keep those documented
  source exceptions visible; do not snap points or invent assignments.
- **Electoral currency:** the AEC [confirmed the ACT, SA and Tasmania
  redistributions on 8 October 2026](https://www.aec.gov.au/media/2026/10-08.htm).
  The repaired August snapshot predates those determinations and does not claim
  to include them. Recheck the next source quarter, including Symonston. The
  [AEC distinguishes three dates](https://www.aec.gov.au/redistributions/about/need-to-know.html):
  the new names and boundaries took effect on 8 October; elections will use them
  when a writ is issued for the next general election; and MPs will represent the
  new electorates after that election. The later election timing does not delay
  the boundary change.

## Follow-up findings from the documentation audit

- **Schema 1.1 implementation:** fallback coordinates, deterministic valid-site
  selection, generated shared SQL, publication diagnostics, converter CRS and
  compatibility checks merged in PR #221 and shipped in v2026.08.3.
- **Fixture coverage:** the new geocode overlay covers three points, stable ties,
  invalid/retired points, duplicate defaults and a conflict failure test. Non-gazetted
  localities and broader parent/child coverage remain separate gaps.
- **Production recovery rehearsal:** [run 38193152206](https://github.com/jbejenar/flat-white/actions/runs/38193152206)
  verified and reconstructed v2026.08.2 from public release assets. It detected
  the existing S3 manifest and skipped every write step. Read-only checks confirmed
  unchanged manifest bytes and modification time. This validates public-asset
  reconstruction and idempotency for an existing mirror. See
  [the procedure](docs/RELEASING.md#recover-a-draft-or-incomplete-mirror).

## Historical work log — April 2026

The dates, release targets, completed items and unchecked tasks below describe
the state recorded in April. Reassess old pending items against current code and
release evidence before treating them as active work. The former May 15 schedule
and ASGS 2021 table guidance are superseded by the guides linked above.

## Completed (2026-04-10, session 6)

### E1.21 — Bulk spatial join optimisation (done, PR #106)

- [x] NSW spatial join 67min → 7.5min; all 9 states under budget

### E1.22 — Fix extract-fixtures.sh naming (done, PR #120)

- [x] `abs_2021_mb_lookup` → `abs_2021_mb` (matches production gnaf-loader)

### E1.23 — Collapse dual-path architecture (done, PR #120)

- [x] Always `--no-boundary-tag`, deleted detect-load-failure.sh + retry branch

### E1.24–E1.29 — Latent bug fixes (done, PRs #112–#117, #120)

- [x] E1.24: flatten.ts session management (sql.reserve + max_lifetime: null)
- [x] E1.25: docker-entrypoint.sh env-var gap
- [x] E1.26: ANALYZE after cache restore
- [x] E1.27: CHANGELOG PR instead of direct push
- [x] E1.28: Catalogue workflow trigger fix
- [x] E1.29: GitHub Actions Node.js 24 upgrade

### P5.01 — S3 upload (done, PR #111)

- [x] Staging → verify → promote → manifest ordering

### P5.03 — OIDC auth (done, PR #120)

- [x] aws-actions/configure-aws-credentials with role-to-assume

### P5.02 — S3 latest pointer (wont-do, removed in PR #131)

- [x] Not part of original design; versioned manifests are canonical

### P5.04 — SNS notification (wont-do, removed in PR #131)

- [x] No topic subscribers exist; can re-add when demand emerges

### S3 convention fix (PR #131)

- [x] All-states file uploaded to data/address/{version}/all.ndjson.gz
- [x] Latest pointer removed
- [x] SNS step removed

### Deps rollup (PR #129)

- [x] postgres 3.4.9, vitest 4.1.4, @types/node 25.5.2, eslint 10.2.0, typescript-eslint 8.58.1

## Completed (2026-04-07, session 5)

### E1.05 — Geoparquet Output (done — roadmap updated)

- [x] Roadmap updated: code already existed, checkboxes checked with evidence

### E1.08 — GitHub Pages Catalogue (done)

- [x] `src/generate-catalogue.ts` + 14 unit tests
- [x] `.github/workflows/catalogue.yml` deploys on release publish
- Note: GitHub Pages must be enabled in repo settings (source: GitHub Actions)

## Completed Prior Sessions

### E1.06 — Build Cache (in-progress)

- [x] `--dump-db` / `--restore-db` flags in docker-entrypoint.sh
- [x] `actions/cache@v4` integration in quarterly-build.yml
- [ ] Build time reduction verified in production (DEFERRED: v2026.05)

### E1.01 — Parquet Output (done — roadmap updated)

- [x] Roadmap updated to reflect PR #57 merge

## Awaiting v2026.05 (cron fires 2026-05-15, no action needed until then)

### P4.03 — Build-Over-Build Comparison

- [ ] Needs second release to verify (v2026.05)

### P4.06 — Runbook

- [ ] Tested by uninvolved person [BLOCKED: requires human tester]

### P4.07 — NSW Memory Optimisation

- [ ] NSW builds reliably on 7GB free runners (2/5 consecutive; needs 3 more clean cron cycles)

### E1.14 — Restore boundary field population

- [x] All code shipped (gnaf-loader fix, verify gate, CHANGELOG)
- [ ] Awaiting v2026.05 build to confirm fields populate in production

### E1.17 — De-hardcode G-NAF version

- [x] All code shipped (download.ts, load.ts, SQL placeholders, entrypoint)
- [ ] Awaiting v2026.05 cron to validate against new G-NAF data

### E1.02 — Delta Builds (planned, p2-medium)

- [ ] Depends on P4.03

## Reference Files

| Need               | Read this                               | NOT this                     |
| ------------------ | --------------------------------------- | ---------------------------- |
| Table schemas      | `fixtures/SCHEMA-REFERENCE.md`          | `fixtures/seed-postgres.sql` |
| Field provenance   | `docs/FIELD-PROVENANCE.md`              | —                            |
| Document schema    | `docs/DOCUMENT-SCHEMA.md`               | —                            |
| Flatten SQL        | `sql/address_full.sql`                  | —                            |
| Self-hosted runner | `docs/SELF-HOSTED-RUNNER.md`            | —                            |
| Quarterly build    | `.github/workflows/quarterly-build.yml` | —                            |
| Docker publish     | `.github/workflows/docker-publish.yml`  | —                            |
| Catalogue          | `.github/workflows/catalogue.yml`       | —                            |
| Agent rules        | `CLAUDE.md` (auto-loaded)               | —                            |
