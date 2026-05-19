# Grep Sweep — stage-10-benchmark-regression (P6-T1)

Timestamp: 2026-05-18T22-40
Command: git grep -n "stage-10-benchmark-regression"
EXIT_CODE: 0
Output Summary: 26 files match. Allowlist analysis:
- This plan file: 1 (allowed)
- This feature's evidence/**: 0
- Promoted potential entry `docs/features/potential/promoted/2026-05-18-remove-classifier-benchmark-gate.md`: present (allowed)
- Other active feature folders (`docs/features/active/2026-05-15-idempotency-and-benchmark-infra-23/**`, `docs/features/active/2026-05-17-reusable-workflow-refactor-pr-pipeline-27/**`): MANY (not in allowlist — historical/archival evidence of prior completed work)
- Live code/config (non-docs): 0

NOTE: Plan tool prerequisite gap: `rg --files-from=-` is unsupported by ripgrep 14.1.1 installed on this machine. Substituted `git grep`, which is equivalent in scope (operates on tracked files only).

SCOPE-DISCOVERY EVENT: Historical references in other feature folders (`docs/features/active/2026-05-15-idempotency-and-benchmark-infra-23/**` and `docs/features/active/2026-05-17-reusable-workflow-refactor-pr-pipeline-27/**`) are outside the plan's documented allowlist. Per the plan's stop-and-report trigger ("Any grep sweep finds residual references outside the documented allowlist (a new scope-discovery event)") and the anti-replanning rules, execution halts. See `<feature>/evidence/regression-testing/scope-discovery-report.2026-05-18T22-40.md` for the consolidated finding.
