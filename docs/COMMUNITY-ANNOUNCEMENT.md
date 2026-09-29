# Community announcement draft

> **Schema 1.0.0 change:** this draft announces the move to ASGS 2026. Use it only
> after verifying an actual published release's metadata and download links.
> Documentation on a branch is not evidence that the new data is available.

## Before using this draft

Choose the published release tag and link it in the message. Check its
`schemaVersion`, `asgsYear`, source versions and counts. Link the
[migration guide](MIGRATING-TO-ASGS-2026.md) prominently so existing users see the
breaking change before upgrading. Follow the destination community's current
posting rules. This file records suggested wording; it does not send an announcement.

## Short message

> flat-white turns Australian G-NAF addresses into downloadable NDJSON, with one
> document per principal address and files for each state and territory.
>
> Schema 1.0.0 moves mesh block, SA1–SA4 and GCCSA to ASGS 2026. The JSON fields keep
> their shape, but geographic joins, saved filters and historical comparisons may
> need changes. Check the release metadata before importing.
>
> [Get started](https://github.com/jbejenar/flat-white#quick-start) ·
> [Migration guide](https://github.com/jbejenar/flat-white/blob/main/docs/MIGRATING-TO-ASGS-2026.md)

## Longer message

> flat-white combines G-NAF addresses with administrative and census geography,
> then publishes per-state compressed NDJSON. Each document includes address
> components, available geocodes, locality details and boundary assignments. You
> can use the files for search, bulk imports or analysis without rebuilding the
> source database joins.
>
> The new schema 1.0.0 contract uses ASGS 2026 for mesh block, SA1–SA4 and GCCSA.
> This is a breaking change in meaning even though the JSON field names and types
> remain the same. Consumers should update geographic reference data and rebuild
> affected indexes and aggregates. It does not add Census statistical results.
>
> The migration guide explains metadata checks, geographic correspondences,
> validation and rollback. Older releases retain their original geography.
> The README shows how to select one release and download its metadata before
> downloading addresses.
>
> [README](https://github.com/jbejenar/flat-white) ·
> [Migration guide](https://github.com/jbejenar/flat-white/blob/main/docs/MIGRATING-TO-ASGS-2026.md)

## Possible audiences

GIS and open-data communities, civic-tech groups, and developers maintaining
address search or data pipelines may find the release useful. Tailor the message
to the audience and include the actual release link; avoid promising a fixed
import time or copying old national address counts.

For a derivative-dataset listing, identify both upstream datasets, the selected
source quarters, output format, schema version and ASGS year. Preserve the
[source attribution and licensing](../README.md#data-sources-and-attribution).
The Apache 2.0 code licence does not replace the source data's terms.
