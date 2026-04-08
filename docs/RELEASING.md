# Releasing flat-white

## Quarterly releases

The normal release cadence is quarterly, triggered automatically by `.github/workflows/quarterly-build.yml` on a cron schedule (15th of Feb, May, Aug, Nov at 02:00 UTC). The version is `vYYYY.MM` matching the underlying G-NAF data version.

To trigger a quarterly build manually:

```bash
gh workflow run quarterly-build.yml -f gnaf_version=2026.05
```

### Version configuration

`GNAF_VERSION` is **required** for all production builds — there is no hardcoded default. The workflow sets it automatically from the `gnaf_version` input (or `date +%Y.%m` if omitted). For local builds, set it explicitly:

```bash
# Local build
GNAF_VERSION=2026.05 ./scripts/build-local.sh --version 2026.05 --states VIC

# Fixture builds default to 2026.02 (frozen fixture data) — no GNAF_VERSION needed
./scripts/build-fixture-only.sh
```

### Download URLs for new G-NAF releases

Each Geoscape quarterly release publishes new dataset UUIDs on data.gov.au, so download URLs change per release. The Feb 2026 URLs are built-in as a fallback. For newer releases, set these env vars before triggering the build:

```bash
# In the workflow dispatch, or in docker run -e flags:
DOWNLOAD_URL_GNAF="https://data.gov.au/data/dataset/.../download/g-naf_may26_....zip"
DOWNLOAD_URL_ADMIN_BDYS="https://data.gov.au/data/dataset/.../download/may26_adminbounds_....zip"
ADMIN_BDYS_EXTRACTED_DIR="MAY26_AdminBounds_GDA_2020_SHP"
```

Find the correct URLs by browsing the G-NAF dataset page on data.gov.au, or by querying the CKAN API:

```bash
curl -s 'https://data.gov.au/data/api/3/action/package_show?id=19432f89-dc3a-4ef3-b943-5326ef1dbecc' | jq '.result.resources[] | {name, url}'
```

## Patch releases

When a critical bug is found in a published release between quarterly cuts, ship a patch release. **Patch releases use new asset filenames so consumers can detect that previous downloads are stale.**

### Versioning convention

| Tag          | Asset filenames                          | When to use                             |
| ------------ | ---------------------------------------- | --------------------------------------- |
| `v2026.04`   | `flat-white-2026.04-{state}.ndjson.gz`   | Normal quarterly release                |
| `v2026.04.1` | `flat-white-2026.04.1-{state}.ndjson.gz` | First patch of v2026.04                 |
| `v2026.04.2` | `flat-white-2026.04.2-{state}.ndjson.gz` | Second patch of v2026.04                |
| `v2026.05`   | `flat-white-2026.05-{state}.ndjson.gz`   | Next quarterly release (new G-NAF data) |

The G-NAF data version stays at `2026.04` for all `v2026.04.N` patches — the patch number bumps the **flat-white release**, not the underlying data. This is reflected in `metadata.json`:

```json
{
  "version": "2026.04.1",
  "gnafVersion": "2026.04",
  ...
}
```

### When to bump the patch number

| Change                                                   | Patch?  | Rationale                                           |
| -------------------------------------------------------- | ------- | --------------------------------------------------- |
| Bug fix in SQL or flatten code that changes field values | **Yes** | Consumers need to re-download to get the fix        |
| Bug fix in download/load that didn't ship to a release   | No      | Roll into next quarterly                            |
| Schema field added (additive)                            | No      | Wait for next quarterly + minor schema version bump |
| Schema field removed/renamed (breaking)                  | No      | Wait for next quarterly + major schema version bump |
| Documentation-only fix                                   | No      | No need to republish data                           |
| New per-state coverage or boundary fields restored       | **Yes** | Consumers want this immediately                     |

### Procedure

1. **Land the bug fix on `main`.** All gates must be green: `npm test`, `npm run lint`, `npm run typecheck`, and `./scripts/build-fixture-only.sh` (which runs both flatten paths and asserts byte-equality).

2. **Decide the patch number.** Look at the most recent existing release for the same parent quarterly:

   ```bash
   gh release list --limit 5
   ```

   If `v2026.04` exists and there's no `v2026.04.1`, use `patch_version=1`. If `v2026.04.1` exists, use `patch_version=2`.

3. **Trigger the workflow:**

   ```bash
   gh workflow run quarterly-build.yml \
     -f gnaf_version=2026.04 \
     -f patch_version=1 \
     -f download_url_gnaf="https://data.gov.au/data/dataset/.../download/g-naf_apr26_....zip" \
     -f download_url_admin_bdys="https://data.gov.au/data/dataset/.../download/apr26_adminbounds_....zip" \
     -f admin_bdys_extracted_dir="APR26_AdminBounds_GDA_2020_SHP"
   ```

   This builds against the same G-NAF data version (`2026.04`) and publishes as `v2026.04.1`. The build cache may be a hit (~30 min saved per state) if the cache key is still warm. Total wall time: ~25 min on free runners.

   For any release newer than the built-in Feb 2026 fallback, you must also provide the matching data.gov.au URLs and the Admin Boundaries extracted directory name. Patch releases still rebuild the original quarterly data, so `v2026.04.1` needs the April 2026 dataset URLs, not the Feb 2026 fallback.

4. **Wait for the build to complete and the draft release to publish.** Watch with:

   ```bash
   gh run watch
   ```

   The release is created as a draft and auto-published if no build-over-build anomalies are detected. For patch releases the count comparison is automatically skipped (the same data should produce ~the same counts).

5. **Manually edit the patch release notes to link the fixing PR(s):**

   ```bash
   gh release edit v2026.04.1 --notes-file - <<'EOF'
   > ⚠️ **Patch release.** This is a hotfix for v2026.04. Underlying G-NAF data is unchanged (still 2026.04). Fixes:
   >
   > - **streetType** field returned the abbreviation (`"PL"`) instead of the long form (`"PLACE"`). Affects all addresses where the street type code differs from the name. Fixed in #67.
   > - **addressLabelSearch** included the same abbreviation. Same root cause, fixed by the same PR.
   >
   > Consumers should re-download. Asset filenames are versioned as `flat-white-2026.04.1-{state}.ndjson.gz` so stale downloads can be detected by filename comparison.

   ## Summary
   ... (auto-generated content from the workflow stays below)
   EOF
   ```

   (E1.13 will eventually automate this — for now it's manual.)

6. **Update the parent release notes to point at the patch:**

   ```bash
   ORIG_BODY=$(gh release view v2026.04 --json body --jq '.body')
   gh release edit v2026.04 --notes - <<EOF
   > ⚠️ **Superseded by [v2026.04.1](https://github.com/jbejenar/flat-white/releases/tag/v2026.04.1).** This release contains a streetType regression — re-download the patched assets.

   ${ORIG_BODY}
   EOF
   ```

7. **Notify downstream consumers** (if not already triggered automatically by the workflow's repository_dispatch).

### What patch releases do NOT do

- **Do not delete the parent release.** Patches are additive. Consumers who pinned to `v2026.04` can keep that pin if they accept the bug; consumers who want the fix bump their pin to `v2026.04.1`. The catalogue (E1.08) eventually shows both.
- **Do not rebuild the G-NAF data.** Use the same `gnaf_version`. The fix is in flat-white code, not in upstream G-NAF.
- **Do not change the schema.** Patches are bug fixes only. Schema changes need a quarterly release with a schema version bump.

### Verifying a patch release

After publishing, verify:

```bash
# Tag exists and is published (not draft)
gh release view v2026.04.1 --json tagName,isDraft

# Asset filenames include the patch version
gh release view v2026.04.1 --json assets --jq '.assets[].name' | sort

# metadata.json has both versions
gh release download v2026.04.1 --pattern metadata.json --dir /tmp
jq '{version, gnafVersion}' /tmp/metadata.json
# Expected: { "version": "2026.04.1", "gnafVersion": "2026.04" }

# Spot-check the bug fix
gh release download v2026.04.1 --pattern '*-act.ndjson.gz' --dir /tmp
gunzip -c /tmp/flat-white-2026.04.1-act.ndjson.gz | grep -m5 '"streetType":"STREET"'
# Should find addresses with long-form streetType
```

## Schema versioning

Independent of release versioning, the NDJSON schema has its own version in `package.json` (semver):

| Schema change                   | Bump                      | Example                                  |
| ------------------------------- | ------------------------- | ---------------------------------------- |
| Field added                     | Minor (`0.2.0` → `0.3.0`) | E1.05 added geoparquet support           |
| Field removed or renamed        | Major (`0.2.0` → `1.0.0`) | Would require consumer migration         |
| Field type changed              | Major                     | Number → string                          |
| Bug fix to existing field value | Patch (`0.2.0` → `0.2.1`) | The v2026.04.1 streetType fix is a patch |

The release tag (`vYYYY.MM[.N]`) and schema version (`X.Y.Z`) are tracked independently. A patch release can ship a schema patch bump, or no schema change at all.

## Version references in documentation

Documentation files use two conventions for version numbers:

| Doc type                                                                             | Convention                                                               | Rationale                                                                                                      |
| ------------------------------------------------------------------------------------ | ------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------- |
| **Consumer-facing** (`DOCUMENT-SCHEMA.md`, `COMMUNITY-ANNOUNCEMENT.md`, `README.md`) | Use the latest release version as illustrative examples (e.g. `2026.04`) | Helps users understand what real data looks like                                                               |
| **Operational** (`RUNBOOK.md`)                                                       | Use `${VERSION}` shell variable placeholders                             | Operators copy-paste commands and substitute their target version — hardcoded versions are a copy-paste hazard |

When a new quarterly release ships, update the consumer-facing examples to reference the new version. Operational docs do not need updating because the placeholder is version-agnostic.
