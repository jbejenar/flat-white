# Next work — flat-white

> Updated: 2026-10-12. **Schema 1.0.0 change:** the current migration targets
> ASGS 2026. Earlier April work records are retained below as history, not the
> active release plan.

## Current focus

The ASGS 2026 migration is merged through [PR #204](https://github.com/jbejenar/flat-white/pull/204)
and [PR #205](https://github.com/jbejenar/flat-white/pull/205).
[Production build 36571342428](https://github.com/jbejenar/flat-white/actions/runs/36571342428)
published [v2026.08](https://github.com/jbejenar/flat-white/releases/tag/v2026.08):
15,108,510 principal addresses, schema 1.0.0, ASGS 2026. All nine state builds,
release verification and the S3 mirror passed. A read-only S3 check also verified
the published manifest and all 11 data/mapping object sizes and SHA-256 checksums.

- Catalogue repair is merged in PR #207; the September 30 deployment now reads
  validated release metadata and shows the correct counts and schema.
- Implement the audited enrichment plan in reviewable stages:
  1. OT federal dependencies, exact PID reconciliation, shared coverage gates
     and atomic assignment rebuilding. Upstream fix: [PR #104](https://github.com/minus34/gnaf-loader/pull/104).
     Merged in [PR #208](https://github.com/jbejenar/flat-white/pull/208); CI and main checks passed. A corrected data release remains pending.
  2. Locked source bytes, deterministic cache identity and dated boundary preparation.
     Implementation includes publication/recovery evidence and real dump/restore checks.
     Merged in PR #209. Draft v2026.08.1 was held for three SA site-point ties.
     PR #222 fixes their ordering; all CI and review checks passed. New correction
     [38185895740](https://github.com/jbejenar/flat-white/actions/runs/38185895740)
     targets v2026.08.2. Do not publish the held draft or claim S3 success before verification.
     Upstream date policy: [PR #105](https://github.com/minus34/gnaf-loader/pull/105).
  3. Schema 1.1.0 `fallbackGeocode`, deterministic valid site-point selection,
     converter/CRS and compatibility checks merged in [PR #221](https://github.com/jbejenar/flat-white/pull/221).
     Primary geometry stays null when only street/locality coordinates exist.
     The v2026.08.3 metadata preflight passed; national publication is pending.
  4. Qualify official NSW council ward snapshots, starting with the sampled
     councils where licensing and currency permit. Assign only qualifying site
     points; publish coverage reasons and dated source evidence. Camden is qualified
     for 31 August 2026. [PR #224](https://github.com/jbejenar/flat-white/pull/224)
     merged with all checks passing. It includes a source lock, strict site-point
     eligibility, independent spatial verification of every eligible exported point,
     and evidence mirroring. The 451-document baseline, real SQL integration,
     empty-database verifier and fixture container pass.
     See docs/NSW-WARD-SOURCES.md. National schema 1.1 publication is still pending.
  5. Publish immutable patch releases, verify S3 and catalogue evidence, and
     compare all PIDs and changed fields with the prior release.
- Track [upstream loader PR #103](https://github.com/minus34/gnaf-loader/pull/103).
  Replace its temporary fix pin with an upstream version containing the repair
  once the authority integration and existing compatibility checks pass.
- Record national build memory/capacity evidence separately from the successful
  publication and the small random-sample check. Neither proves every source
  field is complete or every geographic assignment is correct.
- Coordinate downstream geographic references, index rebuilds, comparisons and
  rollback using the migration guide. Do not assume every consumer of `latest`
  already supports the new contract.

## Follow-up findings from the release sample check

A reproducible random check of two records from each of the nine published state
files found all 18 ASGS 2026 hierarchies consistent with the ABS service. All 17
available geocodes intersected their recorded mesh block. This is a spot check,
not certification of every field or of the complete dataset.

- **Other Territories completeness:** `GAOT_717320346` (30 Jalan Kembang Molok,
  Home Island) has no site geocode. `GAOT_718710324` (39D Taylors Road, Norfolk
  Island) has no federal electorate. The [AEC identifies Norfolk Island as part
  of Bean](https://www.aec.gov.au/profiles/act/bean.htm). Investigate source coverage,
  geocode selection and cross-territory boundary loading with focused fixtures;
  do not guess values or overwrite the immutable published release. Null is
  permitted by the contract but is still incomplete information.
- **Electoral currency:** the [ACT redistribution timetable](https://www.aec.gov.au/redistributions/2025/act/index.html)
  schedules determination for 8 October 2026. The August release and 2025 ABS
  electoral reference predate that scheduled boundary change and should not be
  described as containing it. Recheck the next quarter, including Symonston.

## Follow-up findings from the documentation audit

- **Schema 1.1 implementation:** fallback coordinates, deterministic valid-site
  selection, generated shared SQL, publication diagnostics, converter CRS and
  compatibility checks merged in PR #221. Data publication remains pending.
- **Fixture coverage:** the new geocode overlay covers three points, stable ties,
  invalid/retired points, duplicate defaults and a conflict failure test. Non-gazetted
  localities and broader parent/child coverage remain separate gaps.
- **First mirror recovery:** the explicit `mirror_release_tag` mode now covers
  approved drafts and missing mirrors using checksum-verified public assets.
  Record the first production recovery outcome separately from the fixture and
  mocked-service checks. See [the procedure](docs/RELEASING.md#recover-a-draft-or-incomplete-mirror).

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
