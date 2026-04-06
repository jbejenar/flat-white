# Security Policy

## Reporting a Vulnerability

Please report security vulnerabilities to the maintainer via GitHub Security Advisories:
https://github.com/jbejenar/flat-white/security/advisories/new

Do NOT open a public issue for security vulnerabilities.

## Scope

flat-white is a data transformation tool — it reads government data and produces NDJSON files. The primary security concerns are:

- **Credential exposure** in environment variables or committed files
- **Supply chain** via gnaf-loader submodule or npm dependencies
- **Output integrity** — ensuring the NDJSON output accurately reflects the source data

## Supported Versions

| Version | Supported |
| ------- | --------- |
| latest  | Yes       |
