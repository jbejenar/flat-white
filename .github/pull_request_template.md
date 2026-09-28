## Summary

<!-- Describe the problem, resulting behaviour and any consumer impact. -->

## Validation

<!-- Include the checks you ran and their results. For documentation-only work,
     explain which links, examples and source contracts you checked. -->

- [ ] Relevant tests and checks pass; output changes include the fixture build and regression checks
- [ ] Validation limits are stated (a fixture or metadata preflight is not a production load)

## Contract and documentation

- [ ] Any output change updates `docs/DOCUMENT-SCHEMA.md`, `src/schema.ts` and `fixtures/expected-output.ndjson` together
- [ ] Breaking field meanings or types have a major schema version and a README-linked migration guide
- [ ] Examples, release metadata, S3 manifests and OpenSearch mapping metadata agree where affected
- [ ] Changed guidance is highlighted; historical examples are clearly labelled
- [ ] No gnaf-loader source changes; any reviewed submodule pin update is explained
- [ ] No secrets or credentials in committed files
