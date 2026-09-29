# Boundary processing before schema 1.0.0

The full historical guide is preserved in Git at the last pre-migration `main`
commit. Linking that immutable snapshot avoids copying its 655 lines into this
PR and presenting superseded SQL and recovery instructions as current guidance.

[Read the complete historical guide at commit 5975600](https://github.com/jbejenar/flat-white/blob/59756008148f89b2ee1c54ed7bbf9bb77abc036d/docs/BOUNDARIES.md).

It records the earlier dual-path design, boundary incidents, fixes, per-state
behaviour and supporting PRs. Those records retain their original dates and ASGS
2021 references. No historical text has been rewritten as an ASGS 2026 result.

The same complete text is available locally when that commit is present:

```bash
git show 59756008148f89b2ee1c54ed7bbf9bb77abc036d:docs/BOUNDARIES.md
```

For current instructions, use [boundary processing](../BOUNDARIES.md) and the
[ASGS 2026 migration guide](../MIGRATING-TO-ASGS-2026.md).
