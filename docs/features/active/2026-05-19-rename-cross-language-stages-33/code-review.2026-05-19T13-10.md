# Code Review — Issue #33 (rename-cross-language-stages)

- Timestamp: 2026-05-19T13-10
- Reviewer: feature-review agent
- Base: `origin/main @ 4e71861a2ab14ffac36f29d36644172d47fcca24`
- Head: `feature/rename-cross-language-stages-33 @ 0e9b9d24feed1b8966cd4c4345ab58b0352cbc84`

## Scope

Mechanical workflow rename plus README/branch-protection-mapping documentation update. No production code or tests change.

## Review Dimensions

### Design (simplicity, reusability, extensibility, separation of concerns)

- **Pattern choice.** The change adopts Pattern A from `issue.md` (`_stage-N-<gate>-<toolchain>.yml`). The decision is recorded explicitly in `evidence/baseline/pattern-decision.2026-05-19T08-44.md`. This pairs cleanly with the existing `_stage-N-dotnet-*.yml` siblings and is consistent with the convention that one callee owns one toolchain. PASS.
- **No abstraction creep.** Only `name:` strings, the single `jobs:` key in each callee, and five `uses:` paths in `pr-pipeline.yml` are touched. `steps:`, `on:`, `permissions:` blocks are unchanged. PASS.
- **Separation of concerns.** Orchestrator vs. callee separation is preserved. PASS.

### Naming

- New filenames and job names use lowercase-kebab-case with the gate stage and the underlying toolchain. Consistent with the dotnet siblings and the existing `_secret-scan.yml`/`_tier-classification.yml` patterns. PASS.

### Documentation

- `.github/workflows/README.md` table rows 2/3/4/6/8 now list the toolchain (Prettier, ESLint v9, `tsc --noEmit`, Vitest, Vitest integration placeholder) and the file types covered (TS/JS/JSON/YAML/MD; TS/JS; TS; TS; TS). The misleading "Cross-language" label is removed from every row. PASS.
- The branch-protection-name mapping table is duplicated in two places: `.github/workflows/README.md` lines 81-97 and `docs/features/active/2026-05-19-rename-cross-language-stages-33/branch-protection-mapping.md`. Both list the same five rename rows. **Observation, not a defect**: the duplication is intentional — README is the permanent home, feature folder copy is the paste-ready PR-description artifact.

### Public-API and back-compat impact

- This refactor breaks any external automation pinned to the old required-status-check names (`stage-1-format`, `stage-2-lint`, `stage-3-typecheck`, `stage-5-test`, `stage-7-integration`). The breakage is documented and a mapping is provided. The orchestrator-job names (`stage-1-format`, etc.) remain unchanged, so any consumer that pins the caller-job rather than the callee-job continues to work without the `/ <new>` suffix change. **Recommendation:** flag this clearly in the PR description, not just in the feature folder. (Branch-protection-mapping artifact already exists and is paste-ready.)

### Error-handling and logging

- N/A (no executable code changed).

### Dependencies

- No new dependencies introduced. PASS.

### I/O boundaries

- N/A.

## Workflow-specific Observations

- **Callee/orchestrator job-name decoupling.** The orchestrator job ids in `pr-pipeline.yml` keep the legacy bare names (`stage-1-format`, etc.) while the callees' internal job names take the new names. This is deliberate: the orchestrator-side rename was already taken in PR #27 (see the README "stage-1-format / stage-1-format-prettier" mapping), and changing the orchestrator job id would require a second branch-protection update. The chosen scheme produces a single rename event in the required-status-check namespace. PASS.
- **`_stage-7-integration-vitest.yml` rename.** The callee is currently a placeholder no-op. Renaming it with a `-vitest` suffix locks the slot to Vitest; if a future integration framework is chosen, the file will need another rename. **Observation, not blocking.** This is a known constraint of Pattern A and is consistent with the decision record.

## Risk Summary

| Risk | Severity | Mitigation status |
|---|---|---|
| Branch-protection breakage on `main` until the admin updates required-check names | High (blocks merges) | Mapping documented in `branch-protection-mapping.md` and `.github/workflows/README.md`. Mitigation requires a human admin action external to this PR. **Open.** |
| External dashboards / status-monitoring scripts pinned to old names | Medium | Documented in `issue.md` Constraints & Risks. Out of scope for this PR but flagged for follow-up. |
| Future re-rename if Vitest is replaced for integration tests | Low | Documented in `evidence/baseline/pattern-decision.2026-05-19T08-44.md`. Acceptable trade-off. |

## Overall Verdict

**PASS with one open follow-up.** The change is mechanical, well-scoped, and accurately documented. The single open follow-up (admin must update `main` branch protection during the merge window) is acknowledged in `branch-protection-mapping.md` and is intrinsic to the refactor, not a defect.
