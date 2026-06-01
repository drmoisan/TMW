# QA Diff Scope — permitted-files check

Timestamp: 2026-06-01T14-06
Command: git diff --name-only
EXIT_CODE: 0

Output Summary: The tracked change set contains exactly the two permitted files:
- .github/workflows/pr-pipeline.yml
- .github/workflows/README.md

No `_*.yml` callee, `pre-merge-pipeline.yml`, `.github/scripts/apply-branch-protection.ps1`,
or `tests/powershell/apply-branch-protection.Tests.ps1` appears in the change set.
Evidence artifacts under
docs/features/active/2026-06-01-parallelize-ci-pipeline-46/evidence/ are the only
other additions (untracked, expected and permitted per the plan). Diff scope is
within the permitted boundary.
