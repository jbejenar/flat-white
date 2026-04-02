# ☕ flat-white

### Australian addresses. Flattened and served.

15.9 million addresses. Pre-joined with LGA, electoral, and ABS boundaries. Geocoded. Updated quarterly. Free forever.

---

## What is this?

flat-white takes Australia's two canonical government datasets — [G-NAF](https://data.gov.au/data/dataset/geocoded-national-address-file-g-naf) (every physical address) and [Administrative Boundaries](https://data.gov.au/data/dataset/geoscape-administrative-boundaries) (LGA, electoral, ABS) — and joins them into a single flat file of one-document-per-address NDJSON.

Every document contains the full address, multiple geocode types, locality context with neighbours and aliases, and all boundary enrichment (LGA, ward, state electorate, commonwealth electorate, mesh block, SA1–SA4, GCCSA). No joins. No database. Just download and search.

## Download

Grab the latest release for your state:

```bash
# Victoria
gh release download latest --pattern '*-vic.ndjson.gz'

# All states
gh release download latest --pattern '*-all.ndjson.gz'
```

Or browse the [Releases](../../releases) page.

## Build it yourself

```bash
docker run -v $(pwd)/output:/output flat-white \
  --states VIC \
  --compress \
  --output /output/
```

## What's in a document?

Every line in the NDJSON is one address:

```json
{
  "_id": "GAVIC425181432",
  "addressLabel": "1 MCNAB AV, FOOTSCRAY VIC 3011",
  "state": "VIC",
  "postcode": "3011",
  "geocode": { "latitude": -37.798, "longitude": 144.897, "type": "FRONTAGE CENTRE SETBACK" },
  "boundaries": {
    "lga": { "name": "MARIBYRNONG" },
    "stateElectorate": { "name": "FOOTSCRAY" },
    "commonwealthElectorate": { "name": "GELLIBRAND" },
    "sa2": { "name": "FOOTSCRAY" }
  }
}
```

Full schema: [DOCUMENT-SCHEMA.md](docs/DOCUMENT-SCHEMA.md)

## How it works

1. Spin up ephemeral Postgres + PostGIS (inside Docker)
2. Run [gnaf-loader](https://github.com/minus34/gnaf-loader) to load G-NAF + Admin Boundaries
3. PostGIS spatial joins tag every address with its boundaries
4. Flatten 9+ tables into one document per address
5. Output NDJSON (per-state, gzipped)
6. Kill Postgres

Postgres is a build tool. It exists for ~30 minutes per state and is destroyed. The NDJSON is the only artifact.

## Use cases

- **Self-host address validation** — pipe into OpenSearch/Elasticsearch, add a Lambda, done
- **Replace Experian/Geoscape** — same data, richer output, zero licence cost
- **Data science** — 15.9M geocoded, boundary-enriched address records ready for analysis
- **Government** — every department gets the same data without separate vendor contracts

## Data sources

| Dataset | Source | Licence | Updated |
|---|---|---|---|
| G-NAF | [data.gov.au](https://data.gov.au/data/dataset/geocoded-national-address-file-g-naf) | CC BY 4.0 | Quarterly |
| Admin Boundaries | [data.gov.au](https://data.gov.au/data/dataset/geoscape-administrative-boundaries) | CC BY 4.0 | Quarterly |

## Attribution

> G-NAF © Geoscape Australia licensed by the Commonwealth of Australia under the Open G-NAF End User Licence Agreement.

> Administrative Boundaries © Geoscape Australia licensed by the Commonwealth of Australia under CC BY 4.0.

## Roadmap

See [ROADMAP.md](ROADMAP.md).

## Licence

Apache 2.0
