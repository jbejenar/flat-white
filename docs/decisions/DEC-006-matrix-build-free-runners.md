# DEC-006 — Matrix Build on Free Runners

> **Schema 1.0.0 change — current clarification.**
> The nine-state matrix remains. Discovery now checks weekly and builds new
> quarterly data only when needed. The first ASGS 2026 build cannot reuse older
> incompatible database caches. Runner capacity, timings and costs must be checked
> for the selected environment; the original estimates below are not guarantees.
> See [release procedure](../RELEASING.md) and [runner planning](../SELF-HOSTED-RUNNER.md).

## Status

Accepted

## Context

flat-white processes 9 Australian states/territories. A sequential build would take 4-5 hours. GitHub Actions offers free runners with 7GB RAM and 2 vCPU. The project's principle is "zero cost" — no paid infrastructure.

## Decision

Use a GitHub Actions matrix strategy with 9 parallel jobs (VIC, NSW, QLD, SA, WA, TAS, NT, ACT, OT), each running on a free `ubuntu-latest` runner. `fail-fast: false` ensures one state's failure doesn't cancel the others. Total wall-clock time target: ~50 minutes (limited by NSW, the largest state).

## Alternatives Considered

- **Sequential single-runner build:** Simple but 4-5 hours is too slow for a quarterly release. Also risks OOM on the largest states when other processing is happening.
- **Self-hosted runners:** More RAM (could use 16-32GB), but introduces infrastructure cost and management burden. Violates zero-cost principle. Documented as a fallback option (E1.09).
- **Paid GitHub Actions runners:** 4x or 8x CPU options available but cost money. Unnecessary when the matrix approach works.

## Consequences

- State jobs run independently. The original timing and free-runner budget were planning assumptions; measure the ASGS 2026 run before relying on them.
- Each job is independent — a failed state can be re-run without re-running others.
- NSW (~4.5M addresses, ~5-6GB RAM) is the tightest fit on 7GB runners. Requires memory optimisation (P4.07).
- A separate concatenation job combines the state artifacts after the matrix completes.
- Each state produces an independent gzipped NDJSON file — consumers can download only their state.
