# remove-classifier-benchmark-gate - Refactor Plan

- **Issue:** #32
- **Parent (optional):** none
- **Owner:** drmoisan
- **Last Updated:** 2026-05-18T21-11
- **Status:** Draft
- **Version:** 0.1

## Required References (read, do not restate)

- Coding workflow and standards: [`docs/code-change.instructions.md`](../../code-change.instructions.md)
- Unit test policy: [`docs/unit-test-policy.md`](../../unit-test-policy.md)

## Strategy

Brief approach to reach the target structure while keeping behavior stable.

Fail-closed evidence rule: include explicit baseline artifact tasks, final-QA artifact tasks, and coverage-comparison tasks for each in-scope language when policy requires coverage. If any required baseline artifact, QA artifact, or coverage-comparison artifact is missing, the audit verdict must be BLOCKED or INCOMPLETE, never PASS.

Evidence accounting rule: record the expected artifact path or location in each evidence-producing task. Do not mark evidence-backed work complete without the artifact.

## Work Breakdown

### Phase 1: Inventory & Plan [0%]
- [ ] Enumerate current entry points/paths/imports to touch
- [ ] Confirm invariants and non-goals

### Phase 2: Execute Structural Changes [0%]
- [ ] Apply moves/renames to reach the target layout
- [ ] Update imports/tooling/entry points
- [ ] Remove or redirect legacy paths

### Phase 3: Verification & Cleanup [0%]
- [ ] Run tests/type checks; fix fallout
- [ ] Update docs/tasks/initiative references
- [ ] Final pass for stray references to old locations

## Test Plan

- Unit/Integration: impacted modules and any regression tests for invariants
- CLI/Workflow: end-to-end commands/tasks expected to remain stable
- Tooling: lint/type checks after path updates
- Coverage evidence: list baseline artifact paths, post-change artifact paths, and comparison artifact paths for each in-scope language

## Rollback / Contingency

How to revert or isolate if the refactor breaks downstream consumers (e.g., keep branch snapshot, git move plan).

## Open Questions / Notes

Capture decisions, risks, and follow-ups.
