# Community Announcement Plan

Target: first quarterly release (`v2026.02` or later).

## Channels

| Channel                                                                | Audience                                         | Format                                                      | Timing                              |
| ---------------------------------------------------------------------- | ------------------------------------------------ | ----------------------------------------------------------- | ----------------------------------- |
| [FOSS4G-Oceania](https://foss4g-oceania.org/) mailing list / Slack     | GIS developers, open-source geospatial community | Short announcement + link to release                        | Within 1 week of first release      |
| [OSGeo mailing list](https://lists.osgeo.org/mailman/listinfo/discuss) | Open geospatial community                        | Email announcement                                          | Within 1 week of first release      |
| [data.gov.au](https://data.gov.au/) derivative dataset listing         | Government data consumers                        | Dataset listing referencing source G-NAF + Admin Boundaries | Submit after first verified release |
| [GovHack](https://govhack.org/) Slack / forums                         | Civic tech community, hackathon participants     | Discussion post with use case examples                      | Before next GovHack event           |
| GitHub Discussions / Issues                                            | Developers, data engineers                       | Release announcement pinned to repo                         | Same day as release                 |
| Reddit r/australia, r/datascience                                      | General Australian tech community                | Post with Quick Start examples                              | Within 1 week of first release      |

## Draft Messaging

### Short (social / forums)

> flat-white: Australia's 15.9M addresses, pre-joined with LGA, electorate, ABS boundaries. One flat NDJSON file per state. Free. Quarterly. Zero vendor lock-in.
>
> Download and query in 60 seconds:
> `gh release download latest --pattern '*-vic.ndjson.gz'`
>
> GitHub: github.com/jbejenar/flat-white

### Long (mailing lists)

> **flat-white** transforms Australia's G-NAF and Administrative Boundaries datasets into pre-joined, boundary-enriched NDJSON files — one document per address with full geocode, locality context, and all administrative boundaries (LGA, state/commonwealth electorate, mesh block, SA1-SA4, GCCSA).
>
> **Why?** G-NAF is powerful but requires Postgres, PostGIS, and gnaf-loader to join 15+ relational tables with spatial boundary data. flat-white runs that pipeline quarterly on free GitHub Actions runners and publishes the result as downloadable per-state `.ndjson.gz` files on GitHub Releases.
>
> **Who is this for?**
>
> - Anyone who needs Australian address data without a commercial licence
> - Data scientists who want geocoded, boundary-enriched addresses ready for analysis
> - Government teams tired of separate vendor contracts for the same public data
> - Developers building address validation or geocoding services
>
> **Quick start:** download a state file and query with DuckDB or jq in under 60 seconds. See the README for examples.

## data.gov.au Listing

Submit as a derivative dataset referencing:

- Source: [G-NAF](https://data.gov.au/data/dataset/geocoded-national-address-file-g-naf) (CC BY 4.0)
- Source: [Administrative Boundaries](https://data.gov.au/data/dataset/geoscape-administrative-boundaries) (CC BY 4.0)
- Format: NDJSON (gzipped, per-state)
- Update frequency: Quarterly (aligned with G-NAF releases)
- Licence: Apache 2.0 (code), CC BY 4.0 (derived data)

Submission requires a data.gov.au account. Submit via the "Suggest a Dataset" flow or contact the data.gov.au team directly.
