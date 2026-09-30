# Upgrading to schema 1.1

Schema 1.1 keeps ASGS 2026 and adds `fallbackGeocode`. It answers a common
question: when the source has no property point, does it at least locate the
street or locality? The answer now has its own field and an explicit precision.

Check the downloaded release's `metadata.json` before upgrading. This guide
describes the current code; an older published release remains schema 1.0.
Consumers migrating from schema 0.x must also follow the
[ASGS 2026 migration](MIGRATING-TO-ASGS-2026.md).

## What changes

| Area              | Schema 1.1 behavior                                                                   | Consumer action                                                                                                     |
| ----------------- | ------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| `fallbackGeocode` | New object or null on every document. The reader accepts older documents without it.  | Treat an absent field as unavailable; allow the new field in strict readers.                                        |
| Primary point     | Still uses a valid site geocode. A fallback leaves `geocode` and `location` null.     | Keep property searches on `location`. Display coarse results separately, with their precision.                      |
| Site selection    | Invalid/retired candidates are excluded; source PID resolves equal-ranked candidates. | Expect reviewed coordinate or array-order corrections on ties; do not infer a moved property from a tie correction. |
| Parquet           | Adds a nullable JSON column for the fallback.                                         | Refresh schemas that enumerate columns and decode the JSON where needed.                                            |
| GeoParquet        | Correctly declares GDA2020 / EPSG:7844. Primary geometry remains site-only.           | Regenerate older files before precise spatial work. Use a CRS-aware reader.                                         |
| Census fields     | Remain ASGS 2026.                                                                     | Keep the same edition of reference tables.                                                                          |

A fallback looks like this:

```json
{
  "latitude": -12.11865383,
  "longitude": 96.89588962,
  "typeCode": "STL",
  "type": "STREET LOCALITY",
  "source": "GNAF_DEFAULT",
  "precision": "street"
}
```

This is a real default for an August 2026 Home Island address, not a property
coordinate. `STL` means street precision; `LOC` means locality precision; all
other source codes have `unknown` precision. Do not use these defaults to infer
a NSW ward or place a precise property marker.

## Upgrade in a separate index or dataset

1. Pin one published release tag. Download its metadata, document contract,
   mapping and evidence index together. Accept only schema versions your reader
   supports; do not silently accept every future 1.x version.
2. Update strict readers to accept the nullable fallback object. The exported
   `AddressDocumentSchema` reads both 1.0 and 1.1. The producer uses the stricter
   `AddressDocumentWriterSchema`, which always requires the new field.
3. Create a fresh index using the selected release's mapping. The fallback has
   separate numeric coordinates and precision fields; `location` remains the
   primary `geo_point`. Import the versioned data and compare counts and PIDs.
4. Review `comparison.json`, `comparison.md` and the compressed per-state change
   records. Every changed field is recorded. Source checksums and the fixed
   boundary date distinguish code repairs from source changes.
5. Review `geocodes-STATE.json` alongside the verification report. Conflicting
   active defaults block publication. Invalid source points, missing points and
   collapsed identical defaults remain visible as affected-address counts with
   bounded PID samples. Zero conflicts does not mean every address has a point.
6. Check fallback-only addresses in the application. They must not appear as
   precise property locations. Switch readers after these checks pass.

For August 2026, the audited OT expectation is 3,394 site points plus 411
separate fallbacks: 332 street and 79 locality. The two documented federal
boundary exceptions remain null; this update does not snap points into polygons.
These are checks for that source edition, not permanent targets for later quarters.

## Rollback and coordinate handling

Keep the prior release, index and mappings intact. Roll back readers and their
matching index together if validation fails. Releases are immutable; a correction
receives another release version. The document `_version` still identifies the
G-NAF quarter, while release metadata identifies the schema and patch release.

The GeoParquet repair changes the CRS declaration, not the source coordinate
numbers. Geometry uses longitude, latitude order, as required by the
[GeoParquet 1.1 specification](https://geoparquet.org/releases/v1.1.0/).
Regeneration is safer than relabelling files whose source or transformation
history is unknown. NDJSON coordinates continue to use GDA2020.
