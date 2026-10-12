# NSW council wards: what is covered, and why

**New in schema 1.1:** flat-white can fill a NSW ward when we have a reviewed
council boundary source and a sufficiently precise address point. The first
enabled council is **Camden**. This is limited coverage, not a statewide ward map.

The field stays `boundaries.ward: { name } | null`. A null does not always mean
something is broken. A council may have no wards, its data may not yet qualify,
or the address may lack a suitable site point. The release's `wards-NSW.json`
separates those cases and shows coverage for each council.

## The first qualified source

Camden Council publishes [Ward Map — Camden (2024)](https://data.camden.nsw.gov.au/explore/dataset/camden-council-proposed-wards/).
Its old dataset identifier still contains `proposed-wards`. We did not treat the
identifier or a search result as proof of currency:

- Council adopted the exhibited boundary changes on 10 October 2023, resolution
  ORD182/23 in the [meeting minutes](https://www.camden.nsw.gov.au/assets/Uploads/ORD-10102023-MIN.pdf).
- The council's current [councillors page](https://www.camden.nsw.gov.au/council/councillors)
  embeds an [interactive 2024 ward map](https://data.camden.nsw.gov.au/pages/ward-map/?headless=true)
  backed by that exact dataset.
- The [NSW Electoral Commission](https://elections.nsw.gov.au/elections/find-my-electorate/councils/camden)
  confirms Central, North and South wards. Its page was updated in June 2026.
- The dataset's licence metadata is blank. The governing council
  [Open Data Policy](https://data.camden.nsw.gov.au/api/datasets/1.0/open-documents/attachments/open_data_policy_pdf/),
  section 5.3, specifies CC BY 4.0 for council open data published on its portal.
  The policy's February 2026 review date is a review deadline, not an expiry clause.
  This policy is the recorded licence basis; public access alone is not a licence.

**Attribution:** Ward boundaries: Camden Council, Ward Map — Camden (2024),
[CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). flat-white reprojects the
polygons to GDA2020 and derives address ward assignments. Council does not endorse
those derived assignments.

The API request explicitly selects ward names and polygons, orders them by ward,
and requests EPSG:4326. The [API documentation](https://help.opendatasoft.com/apis/ods-explore-v2/)
defines the export's `epsg` parameter. PostGIS transforms those coordinates to
EPSG:7844 before comparison with G-NAF site points. No coordinates are relabelled
as another datum without transformation.

The exact Geoscape crosswalk is `lga2a2057496fb7`, **Camden Council**. Qualification
on 12 October 2026 checked all 58,791 Camden addresses in the checksum-verified
published August baseline. All 57,844 qualifying site points intersected exactly
one logical ward. Another 208 had reliability-3 gap geocodes; 739 had no primary
site point. Those 947 do not qualify.

The first published enrichment release,
[v2026.08.3](https://github.com/jbejenar/flat-white/releases/tag/v2026.08.3), confirmed
the same counts on its final artifacts: 57,844 matched out of 57,844 eligible,
947 excluded, and no unmatched or ambiguous points. Its publication verifier
independently recomputed every eligible assignment from the locked polygons.
See the [published coverage report](https://github.com/jbejenar/flat-white/releases/download/v2026.08.3/wards-NSW.json);
later releases must pass their own checks against their own source snapshots.

## How an address qualifies

The address must be in NSW and its Geoscape LGA code and name must match the
reviewed crosswalk. We use the same selected, valid, active site point as
`geocode`. Its reliability must be 1 or 2, and its type must be one of the
reviewed precise site types in [the registry](../config/nsw-wards.json).

Street/locality defaults, gap geocodes, unknown types and reliability 3–6 cannot
assign a ward. `fallbackGeocode` never enters this join. This remains true even
when an approximate point happens to land inside a polygon.

Duplicate polygon parts with the same logical ward identity count once. If the
point touches two different wards, the result stays null and is reported as
ambiguous. A point outside all ward polygons stays null and is unmatched. We do
not snap points, select the nearest polygon or pick an arbitrary overlap winner.

## Reading the coverage report

| Reason                   | Meaning                                                              |
| ------------------------ | -------------------------------------------------------------------- |
| `matched`                | A qualifying site point lies in one logical ward.                    |
| `unsupported`            | No approved source or council-status crosswalk is available.         |
| `undivided`              | The reviewed council has no wards.                                   |
| `insufficient_precision` | An enabled council's address has no qualifying site point.           |
| `unmatched`              | A qualifying point lies outside the enabled council's ward polygons. |
| `ambiguous`              | A qualifying point intersects more than one logical ward.            |

The City of Sydney is explicitly recorded as undivided, based on the
[Electoral Commission's council record](https://elections.nsw.gov.au/elections/find-my-electorate/councils/sydney),
with Geoscape code `lga605d8cdb0eb8`. Other councils remain unsupported until
reviewed. In particular, this change does not claim coverage for the previously
sampled Inner West or Lake Macquarie addresses: their current digital sources
still need a complete licence and currency qualification.

Each enabled council must match at least 99% of its eligible addresses. Zero
eligible addresses means **undefined coverage** and fails an NSW build; it never
counts as 100%. Unsupported, undivided and insufficient-precision records stay
outside that denominator. The report includes counts and bounded PID samples
for every reason. The compressed-artifact verifier independently reconciles the
denominator, council identities and source lock against the export. It also
recomputes every eligible address's ward from the exported primary coordinates
and the locked source polygons in a fresh PostGIS session. A swapped ward name,
a false null, or an incorrect overlap/gap reason blocks publication even when
aggregate coverage still exceeds 99%. Checks stream in batches of at most 1,000
points; the verification database is temporary and keeps no address state.

## Rebuilding and adding councils

[The registry](../config/nsw-wards.json) pins the URL, byte length, SHA-256, CRS,
expected feature count, logical ward names, crosswalk, licence and evidence links.
This snapshot is approved only for the **31 August 2026** boundary reference date.
A new reference date needs a reviewed registry update; an unchanged URL does not
prove that boundaries are still current.

The sources job downloads each ward file once and creates `ward-source-lock.json`.
All state jobs verify the same files and import them into temporary session
tables when flattening. They are never part of the base G-NAF/Geoscape database
cache. Missing files, checksum drift, invalid polygons, missing wards or a changed
crosswalk stop the build. A previously enabled source cannot silently disappear.

The release includes the source lock, exact ward JSON files, this guide and each
state's ward report. Their checksums live in `evidence-index.json`; S3 mirrors and
recovery retain them as evidence, separately from address ingestion files.

For local production builds, acquire base archives with `node dist/source-lock.js
acquire`, then run `node dist/ward-sources.js` using the same `SOURCE_ARCHIVE_DIR`.
For local production-artifact verification, set `WARD_VERIFICATION_DATABASE_URL`
to an ephemeral PostGIS database. The release workflow starts one automatically;
no persistent AWS database is involved.

Fixture builds use only tiny, explicitly synthetic ward files. The integration
test changes one fixture address inside a transaction and rolls it back; it does
not download production G-NAF data or alter the committed address baseline.
