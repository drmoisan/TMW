# .gitignore — OpenAPI Snapshot Re-inclusion Check

Timestamp: 2026-05-14T22-40
Command: `git check-ignore artifacts/openapi/current.json` and `git add artifacts/openapi/current.json`
EXIT_CODE: 1 (check-ignore: no match — file is NOT ignored) / 0 (git add succeeded)

## Pre-change observation

`.gitignore` line 52 was `artifacts/`, a parent-directory ignore. `git check-ignore -v artifacts/openapi/current.json` matched rule `.gitignore:52:artifacts/`. Git cannot re-include files under a fully ignored parent directory, so a bare `!artifacts/openapi/` negation was insufficient.

## Change applied

`.gitignore` line 52 changed from `artifacts/` to `artifacts/*` (ignores directory contents but leaves the directory traversable), followed by the negation pair:
```
artifacts/*
!artifacts/openapi/
!artifacts/openapi/*
```

## Post-change verification

- `git check-ignore artifacts/openapi/current.json` returns no match (exit code 1) — the file is no longer ignored.
- `git add artifacts/openapi/current.json` succeeds — the file is stageable; `git status --short` shows `A  artifacts/openapi/current.json`.
- `git check-ignore artifacts/orchestration/` and `git check-ignore artifacts/research/` still return matches (exit 0) — other `artifacts/` subdirectories remain ignored as before; no unintended widening of tracked files.
