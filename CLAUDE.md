@AGENTS.md

# Claude Code — Session Rules

These rules address observed failure patterns in autonomous sessions. They supplement AGENTS.md (imported above).

## Sandbox Boundaries (claude-loop)

When running under `claude-loop`, you **CANNOT** run:

- `rm`, `git rm` (destructive — note blockers in build-notes for manual cleanup)
- `kill`, `chmod` (rarely needed, risky in autonomous mode)

You **CAN** run:

- `docker`, `docker compose`, `docker exec` (core workflow — ephemeral DB)
- `psql` (fixture seeds, query testing)
- `bash scripts/*.sh` (e.g. `build-fixture-only.sh` dev loop)

Do NOT attempt workarounds for blocked commands (Node.js scripts, background processes, etc.). **Max 2 retries** on any blocked command, then document in `.claude-loop/build-notes.md` and move on.

## Read Discipline

- **Start with `NEXT-WORK.md`** for active tickets and DoD checkboxes. Only consult ROADMAP.md if NEXT-WORK.md is missing or you need a specific ticket's full context (search by ticket ID — do not read the whole file).
- **Use `fixtures/SCHEMA-REFERENCE.md`** for table schemas. Do NOT read `fixtures/seed-postgres.sql` (~10k lines, ~200k tokens). The schema reference has all table definitions, row counts, and join relationships.
- **Read large files once.** If you already read a file this session, work from memory. Do not re-read.
- **Grep before Read.** When you need one value from a large file, use Grep with a targeted pattern.

## Branch Safety

Run `git branch --show-current` before your **first commit** in any session. Verify you are on the correct feature branch — not `main` and not a stale branch from a previous session.

## Streaming & Memory

NEVER use `sql.unsafe()` without `.cursor()`. All Postgres query execution must be cursor-based. Memory must stay under 500MB. The pre-commit hook will reject `sql.unsafe()` without `.cursor()`.

## File Hygiene

- Do NOT create temporary `.mjs` or `.js` script files as workarounds.
- Do NOT leave empty (0-byte) files in the repo. The pre-commit hook will reject them.
- If you cannot delete a file (rm/git rm blocked), note it in build-notes for manual cleanup.

## .gitignore Awareness

`*.ndjson` is git-ignored, but `fixtures/expected-output.ndjson` has a `!` exception and CAN be committed. Check `.gitignore` before creating files with ignored extensions.
