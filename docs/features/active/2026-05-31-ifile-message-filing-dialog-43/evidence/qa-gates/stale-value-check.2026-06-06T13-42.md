# Phase 5 — Stale-Value Check (old client ID) — iFile #43 Cycle 4

Timestamp: 2026-06-06T13-42

Command:
- git grep -n "2921bc0b-4518-4547-b8ca-f937713688ec" -- (in-scope files)
- grep -rl "2921bc0b-4518-4547-b8ca-f937713688ec" docs/  (repo-wide, incl. untracked historical)

EXIT_CODE: 0 (verification searches completed; zero matches in in-scope files)

SearchScope:
- In-scope files (must be zero): src/taskpane/ifile/naa-token-acquirer.ts,
  tests/taskpane/ifile/naa-token-acquirer.test.ts, manifest.json, manifest.xml,
  runbooks/entra-app-sso-config.runbook.md, runbooks/outlook-on-device-verification.runbook.md
- Repo-wide docs/ (to classify remaining occurrences).

SearchPatterns: old client ID `2921bc0b-4518-4547-b8ca-f937713688ec`.

SearchResult:
- In-scope production/test/manifest/runbook files: ZERO occurrences. The old client ID has been
  fully removed from every in-scope target.
- Remaining repo-wide occurrences (all expected/acceptable — immutable historical artifacts or
  this cycle's own change-record):
  - docs/.../2026-06-04-ifile-token-path-naa-vs-sso-research-43.md (research doc — immutable)
  - docs/.../2026-06-04T20-29-remediation/remediation-inputs.2026-06-04T20-29.md (immutable)
  - docs/.../2026-06-04T20-29-remediation/remediation-plan.2026-06-04T20-29.md (immutable)
  - docs/.../evidence/other/backend-azuread-verification.2026-06-04T20-29.md (immutable)
  - docs/.../evidence/other/manifest-changes.md (immutable prior evidence)
  - docs/.../evidence/other/backend-verification.2026-06-06T13-42.md (this cycle — records the
    old ID as a search pattern in the verification)
  - docs/.../remediation-inputs.2026-06-06T13-42.md (this cycle — Old value in the trigger/table)
  - docs/.../remediation-plan.2026-06-06T13-42.md (this cycle — Old value in the canonical table)

Output Summary: PASS. Zero occurrences of the old client ID in any in-scope production, test,
manifest, or runbook file. All remaining occurrences are confined to immutable historical/audit
artifacts and this cycle's own change-record documents (which legitimately cite the old value as
the value being replaced).
