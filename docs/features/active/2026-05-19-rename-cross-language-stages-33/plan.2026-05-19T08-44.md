# 2026-05-19-rename-cross-language-stages - Plan

- **Issue:** #33
- **Issue URL:** https://github.com/drmoisan/TMW/issues/33
- **Parent (optional):** none
- **Owner:** drmoisan
- **Last Updated:** 2026-05-19T08-44
- **Status:** Draft
- **Version:** 0.2
- **Work Mode:** minor-audit
- **Feature Folder:** `docs/features/active/2026-05-19-rename-cross-language-stages-33/`

## Required References

- General Code Change: `.claude/rules/general-code-change.md`
- General Unit Test: `.claude/rules/general-unit-test.md`
- Quality Tiers: `.claude/rules/quality-tiers.md`
- Tonality: `.claude/rules/tonality.md`
- Issue: `docs/features/active/2026-05-19-rename-cross-language-stages-33/issue.md`

All work must comply with these policies; do not duplicate their content here.

## Scope Summary

CI-config-only rename: five TypeScript-only reusable workflow callees are renamed to expose the actual toolchain in their filenames and job names; the orchestrator's `uses:` references are updated; the README descriptor table is rewritten; a branch-protection mapping artifact is produced for the admin. No production language source is touched. No coverage capture is required.

## Pattern Decision (P0)

**Recommendation: Pattern A — language-scoped suffix** (`_stage-1-format-prettier.yml`, `_stage-2-lint-eslint.yml`, `_stage-3-typecheck-tsc.yml`, `_stage-5-test-vitest.yml`, `_stage-7-integration-vitest.yml`).

Rationale: the existing `_stage-N-dotnet-*.yml` siblings already place the language/toolchain marker as a suffix on the stage stem (e.g. `_stage-1-dotnet-format.yml`). Pattern A places the toolchain marker in the same position (`_stage-1-format-prettier.yml`), which keeps the stage stem (`stage-1-format`) intact for sorting and preserves the existing convention that the suffix identifies the implementation. Pattern B (`_stage-1-ts-format.yml`) breaks the shared stage stem and reorders the suffix relative to the existing dotnet siblings, which would force re-sorting and renaming of the dotnet files to remain symmetric. P0 task surfaces this decision to the orchestrator for explicit confirmation before any rename executes.

## Evidence Location Invariant

All evidence artifacts MUST be written to canonical paths under `docs/features/active/2026-05-19-rename-cross-language-stages-33/evidence/<kind>/` as defined in `.claude/skills/evidence-and-timestamp-conventions/SKILL.md`. Any caller-supplied alternative path is rejected.

## Implementation Plan (Atomic Tasks)

### Phase 0 — Compliance & Decisions

- [x] [P0-T1] Read repository policy files in canonical order (`.claude/rules/general-code-change.md`, `.claude/rules/general-unit-test.md`, `.claude/rules/quality-tiers.md`, `.claude/rules/tonality.md`) and record evidence
  - Acceptance: file `docs/features/active/2026-05-19-rename-cross-language-stages-33/evidence/baseline/phase0-instructions-read.2026-05-19T08-44.md` exists with `Timestamp:`, `Policy Order:`, and explicit list of files read.

- [x] [P0-T2] Read `docs/features/active/2026-05-19-rename-cross-language-stages-33/issue.md` and confirm it contains an explicit `## Acceptance Criteria` section (minor-audit mode requires it)
  - Acceptance: evidence file `docs/features/active/2026-05-19-rename-cross-language-stages-33/evidence/baseline/issue-acceptance-criteria-confirmed.2026-05-19T08-44.md` records the AC list verbatim with timestamp.

- [x] [P0-T3] Capture baseline of orchestrator and renamed callees (verbatim copy of pre-change state)
  - Command: `git show HEAD:.github/workflows/pr-pipeline.yml`, `git show HEAD:.github/workflows/_stage-1-format.yml`, `git show HEAD:.github/workflows/_stage-2-lint.yml`, `git show HEAD:.github/workflows/_stage-3-typecheck.yml`, `git show HEAD:.github/workflows/_stage-5-test.yml`, `git show HEAD:.github/workflows/_stage-7-integration.yml`
  - Acceptance: artifact `docs/features/active/2026-05-19-rename-cross-language-stages-33/evidence/baseline/workflow-files-baseline.2026-05-19T08-44.md` contains `Timestamp:`, `Command:`, `EXIT_CODE: 0`, `Output Summary:` listing the six file SHAs and byte counts.

- [x] [P0-T4] Capture baseline workflow-lint state with `actionlint` over `.github/workflows/`
  - Command: `actionlint -color=never .github/workflows/_stage-1-format.yml .github/workflows/_stage-2-lint.yml .github/workflows/_stage-3-typecheck.yml .github/workflows/_stage-5-test.yml .github/workflows/_stage-7-integration.yml .github/workflows/pr-pipeline.yml`
  - Acceptance: artifact `docs/features/active/2026-05-19-rename-cross-language-stages-33/evidence/baseline/actionlint-baseline.2026-05-19T08-44.md` with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:` (pass/fail and count of diagnostics). If `actionlint` is not available, record `EXIT_CODE: TOOL_UNAVAILABLE` and document the substitute (`gh workflow view` smoke described in P7).

- [x] [P0-T5] Surface Pattern A vs Pattern B decision to the orchestrator for explicit confirmation
  - Acceptance: artifact `docs/features/active/2026-05-19-rename-cross-language-stages-33/evidence/baseline/pattern-decision.2026-05-19T08-44.md` records the recommendation (Pattern A, rationale per the Pattern Decision section above) and a `Decision:` line set to `CONFIRMED` or `OVERRIDDEN: <alternate>`. No subsequent phase may proceed until this artifact exists with `Decision:` set.

### Phase 1 — Workflow File Renames (one task per file)

Acceptance criteria common to P1 tasks: `git mv` is used (not copy+delete); the new file's `name:` field matches the new filename stem; the job key inside `jobs:` matches the new filename stem; `on: workflow_call:` and `on: workflow_dispatch:` triggers are preserved verbatim; `permissions:` block is preserved verbatim; the `steps:` body is preserved verbatim. P1 changes the file path only — internal job-name updates are scheduled in P3 to keep diff hunks atomic.

- [x] [P1-T1] Rename `.github/workflows/_stage-1-format.yml` to `.github/workflows/_stage-1-format-prettier.yml` (Pattern A) using `git mv`
  - Acceptance: `git status` shows the rename as a single renamed entry, not separate delete+add; file content is byte-identical pre-edit.

- [x] [P1-T2] Rename `.github/workflows/_stage-2-lint.yml` to `.github/workflows/_stage-2-lint-eslint.yml` using `git mv`
  - Acceptance: as P1-T1.

- [x] [P1-T3] Rename `.github/workflows/_stage-3-typecheck.yml` to `.github/workflows/_stage-3-typecheck-tsc.yml` using `git mv`
  - Acceptance: as P1-T1.

- [x] [P1-T4] Rename `.github/workflows/_stage-5-test.yml` to `.github/workflows/_stage-5-test-vitest.yml` using `git mv`
  - Acceptance: as P1-T1.

- [x] [P1-T5] Rename `.github/workflows/_stage-7-integration.yml` to `.github/workflows/_stage-7-integration-vitest.yml` using `git mv`
  - Acceptance: as P1-T1.

- [x] [P1-T6] Verify each renamed file parses as valid YAML
  - Command: `Get-ChildItem .github/workflows/_stage-{1-format-prettier,2-lint-eslint,3-typecheck-tsc,5-test-vitest,7-integration-vitest}.yml | ForEach-Object { python -c "import yaml,sys; yaml.safe_load(open(sys.argv[1])); print(sys.argv[1],'OK')" $_.FullName }`
  - Acceptance: artifact `docs/features/active/2026-05-19-rename-cross-language-stages-33/evidence/qa-gates/p1-yaml-parse.2026-05-19T08-44.md` records `EXIT_CODE: 0` and one `OK` line per renamed file.

### Phase 2 — Orchestrator `uses:` Updates (one task per reference)

- [x] [P2-T1] Update `.github/workflows/pr-pipeline.yml` line ~16 to replace `uses: ./.github/workflows/_stage-1-format.yml` with `uses: ./.github/workflows/_stage-1-format-prettier.yml`
  - Acceptance: `rg -n '_stage-1-format\.yml' .github/workflows/pr-pipeline.yml` returns no hits; `rg -n '_stage-1-format-prettier\.yml' .github/workflows/pr-pipeline.yml` returns exactly one hit.

- [x] [P2-T2] Update `.github/workflows/pr-pipeline.yml` line ~20 to replace `uses: ./.github/workflows/_stage-2-lint.yml` with `uses: ./.github/workflows/_stage-2-lint-eslint.yml`
  - Acceptance: equivalent grep proof for `_stage-2-lint.yml` → `_stage-2-lint-eslint.yml`.

- [x] [P2-T3] Update `.github/workflows/pr-pipeline.yml` line ~24 to replace `uses: ./.github/workflows/_stage-3-typecheck.yml` with `uses: ./.github/workflows/_stage-3-typecheck-tsc.yml`
  - Acceptance: equivalent grep proof for `_stage-3-typecheck.yml` → `_stage-3-typecheck-tsc.yml`.

- [x] [P2-T4] Update `.github/workflows/pr-pipeline.yml` line ~32 to replace `uses: ./.github/workflows/_stage-5-test.yml` with `uses: ./.github/workflows/_stage-5-test-vitest.yml`
  - Acceptance: equivalent grep proof for `_stage-5-test.yml` → `_stage-5-test-vitest.yml`.

- [x] [P2-T5] Update `.github/workflows/pr-pipeline.yml` line ~40 to replace `uses: ./.github/workflows/_stage-7-integration.yml` with `uses: ./.github/workflows/_stage-7-integration-vitest.yml`
  - Acceptance: equivalent grep proof for `_stage-7-integration.yml` → `_stage-7-integration-vitest.yml`.

- [x] [P2-T6] Verify `pr-pipeline.yml` parses as valid YAML and that every `uses:` path resolves to an existing file
  - Command: `python -c "import yaml; d=yaml.safe_load(open('.github/workflows/pr-pipeline.yml')); import os; missing=[v['uses'] for v in d['jobs'].values() if not os.path.exists(v['uses'].lstrip('./'))]; assert not missing, missing; print('OK')"`
  - Acceptance: artifact `docs/features/active/2026-05-19-rename-cross-language-stages-33/evidence/qa-gates/p2-uses-resolution.2026-05-19T08-44.md` records `EXIT_CODE: 0` and `Output Summary: All uses: resolve.`

### Phase 3 — Job-Name Internal Updates (one task per renamed file)

Each task updates two lines in the renamed file: the top-level `name:` (line 1) and the job key under `jobs:` (line ~10). The job key change also requires updating any internal reference to `jobs.<old-key>.<something>` if present (none of the five files currently have internal job-key references, but verification is part of the acceptance criterion).

- [x] [P3-T1] Update `.github/workflows/_stage-1-format-prettier.yml`: change `name: stage-1-format` → `name: stage-1-format-prettier` and job key `stage-1-format:` → `stage-1-format-prettier:`
  - Acceptance: `rg -n 'stage-1-format[^-]' .github/workflows/_stage-1-format-prettier.yml` returns zero hits; `rg -n 'stage-1-format-prettier' .github/workflows/_stage-1-format-prettier.yml` returns exactly two hits (the `name:` line and the job key).

- [x] [P3-T2] Update `.github/workflows/_stage-2-lint-eslint.yml`: change `name: stage-2-lint` → `name: stage-2-lint-eslint` and job key `stage-2-lint:` → `stage-2-lint-eslint:`
  - Acceptance: equivalent grep proof.

- [x] [P3-T3] Update `.github/workflows/_stage-3-typecheck-tsc.yml`: change `name: stage-3-typecheck` → `name: stage-3-typecheck-tsc` and job key `stage-3-typecheck:` → `stage-3-typecheck-tsc:`
  - Acceptance: equivalent grep proof.

- [x] [P3-T4] Update `.github/workflows/_stage-5-test-vitest.yml`: change `name: stage-5-test` → `name: stage-5-test-vitest` and job key `stage-5-test:` → `stage-5-test-vitest:`
  - Acceptance: equivalent grep proof.

- [x] [P3-T5] Update `.github/workflows/_stage-7-integration-vitest.yml`: change `name: stage-7-integration` → `name: stage-7-integration-vitest` and job key `stage-7-integration:` → `stage-7-integration-vitest:`
  - Acceptance: equivalent grep proof.

- [x] [P3-T6] Verify all five renamed files parse as valid YAML and that each file's job key matches its `name:` field
  - Command: `python -c "import yaml,glob; [print(f, list(yaml.safe_load(open(f))['jobs'].keys())) for f in glob.glob('.github/workflows/_stage-*-prettier.yml')+glob.glob('.github/workflows/_stage-*-eslint.yml')+glob.glob('.github/workflows/_stage-*-tsc.yml')+glob.glob('.github/workflows/_stage-*-vitest.yml')]"`
  - Acceptance: artifact `docs/features/active/2026-05-19-rename-cross-language-stages-33/evidence/qa-gates/p3-job-names.2026-05-19T08-44.md` confirms job key == `name:` field for each file.

### Phase 4 — README Descriptor Refresh

- [x] [P4-T1] Update the callees table in `.github/workflows/README.md` (rows 2, 3, 4, 6, 8) so the `Callee` column lists the new filenames and the `Purpose` column names the toolchain and covered file types
  - Required new row values (Pattern A):
    - Row 2: `` `_stage-1-format-prettier.yml` `` | `Prettier format check (JS/TS/JSON/YAML/MD); see also _stage-1-dotnet-format.yml for C# (CSharpier)`
    - Row 3: `` `_stage-2-lint-eslint.yml` `` | `ESLint v9 flat config with typescript-eslint (TS/JS only)`
    - Row 4: `` `_stage-3-typecheck-tsc.yml` `` | `tsc --noEmit (TS only); .NET nullable analysis runs inside _stage-3-dotnet-typecheck.yml`
    - Row 6: `` `_stage-5-test-vitest.yml` `` | `Vitest with V8 coverage (TS only); .NET unit tests run in _stage-5-dotnet-test.yml`
    - Row 8: `` `_stage-7-integration-vitest.yml` `` | `Vitest integration placeholder (TS only; currently no-op until integration tests exist)`
  - Acceptance: `rg -n 'Cross-language' .github/workflows/README.md` returns zero hits; the five new filenames each appear at least once in the table.

- [x] [P4-T2] Update the "Dispatch invocations (per-stage)" code block in `.github/workflows/README.md` so the five `gh workflow run` lines reference the new filenames
  - Acceptance: `rg -n 'gh workflow run _stage-(1-format|2-lint|3-typecheck|5-test|7-integration)\.yml' .github/workflows/README.md` returns zero hits; five replacement lines (`_stage-1-format-prettier.yml`, `_stage-2-lint-eslint.yml`, `_stage-3-typecheck-tsc.yml`, `_stage-5-test-vitest.yml`, `_stage-7-integration-vitest.yml`) each appear exactly once in the code block.

- [x] [P4-T3] Update the "Branch-protection rename procedure" mapping table in `.github/workflows/README.md` so the five affected rows use the new caller-job-name / callee-job-name pairs
  - Required new row values (Add column):
    - `stage-1-format` → `stage-1-format / stage-1-format-prettier`
    - `stage-2-lint` → `stage-2-lint / stage-2-lint-eslint`
    - `stage-3-typecheck` → `stage-3-typecheck / stage-3-typecheck-tsc`
    - `stage-5-test` → `stage-5-test / stage-5-test-vitest`
    - `stage-7-integration` → `stage-7-integration / stage-7-integration-vitest`
  - Acceptance: each of the five new strings appears exactly once in the mapping table.

- [x] [P4-T4] Verify README still renders as well-formed Markdown (no broken table syntax) by running a Markdown lint or structural check
  - Command: `python -c "import re; s=open('.github/workflows/README.md').read(); rows=[l for l in s.splitlines() if l.strip().startswith('|')]; bad=[l for l in rows if l.count('|')<3]; assert not bad, bad; print('OK', len(rows), 'table rows')"`
  - Acceptance: artifact `docs/features/active/2026-05-19-rename-cross-language-stages-33/evidence/qa-gates/p4-readme-structure.2026-05-19T08-44.md` records `EXIT_CODE: 0` and the rendered row count.

### Phase 5 — Residual-Reference Sweep

- [x] [P5-T1] Run a repo-wide grep to confirm no stale reference to any of the five old filenames remains outside `docs/features/**` historical evidence
  - Command: `rg -n -F -e _stage-1-format.yml -e _stage-2-lint.yml -e _stage-3-typecheck.yml -e _stage-5-test.yml -e _stage-7-integration.yml --glob '!docs/features/**'`
  - Acceptance: artifact `docs/features/active/2026-05-19-rename-cross-language-stages-33/evidence/qa-gates/p5-residual-old-names.2026-05-19T08-44.md` records `EXIT_CODE: 1` (no matches) and `Output Summary: No residual references.` Any match fails the phase and must be remediated before P6 begins.

### Phase 6 — Branch-Protection Mapping Artifact

- [x] [P6-T1] Create `docs/features/active/2026-05-19-rename-cross-language-stages-33/branch-protection-mapping.md` containing the old-check-name → new-check-name table for the five renamed stages, formatted for direct paste into the PR description
  - Required content: `Timestamp:`, an `Issue:` line referencing #33, and a Markdown table with five rows (one per renamed callee) listing the pre-rename status-check name (e.g. `stage-1-format / stage-1-format`) in the Remove column and the post-rename name (e.g. `stage-1-format / stage-1-format-prettier`) in the Add column, plus a final paragraph instructing the admin where to apply it (Settings → Branches → main → Required status checks).
  - Acceptance: the file exists, contains exactly five mapping rows, and `rg -n 'stage-1-format / stage-1-format-prettier' docs/features/active/2026-05-19-rename-cross-language-stages-33/branch-protection-mapping.md` returns one hit.

- [x] [P6-T2] Cross-link the mapping artifact from the feature folder's `issue.md` so the PR-author agent picks it up automatically
  - Acceptance: `rg -n 'branch-protection-mapping.md' docs/features/active/2026-05-19-rename-cross-language-stages-33/issue.md` returns at least one hit. (If issue.md is intentionally append-only, instead record the link in a new `evidence/other/branch-protection-mapping-link.2026-05-19T08-44.md` and document the choice there.)

### Phase 7 — Final QC

- [x] [P7-T1] Final repo-wide grep for residual old workflow filenames (regression of P5-T3 immediately before tagging done)
  - Command: `rg -n -F -e _stage-1-format.yml -e _stage-2-lint.yml -e _stage-3-typecheck.yml -e _stage-5-test.yml -e _stage-7-integration.yml --glob '!docs/features/**'`
  - Acceptance: artifact `docs/features/active/2026-05-19-rename-cross-language-stages-33/evidence/qa-gates/p7-grep-residual.2026-05-19T08-44.md` with `EXIT_CODE: 1` (no matches), `Output Summary: clean.`

- [x] [P7-T2] Final repo-wide grep for the literal string `Cross-language` to confirm no misleading label remains in workflow descriptors
  - Command: `rg -n 'Cross-language' .github/`
  - Acceptance: artifact `docs/features/active/2026-05-19-rename-cross-language-stages-33/evidence/qa-gates/p7-grep-cross-language.2026-05-19T08-44.md` records the grep result. The repo policy is that the string must not appear in `.github/workflows/README.md` or in any callee `name:` field; matches elsewhere (e.g. legacy commentary) must be enumerated and justified.

- [x] [P7-T3] Final `actionlint` over all renamed workflow files plus the orchestrator
  - Command: `actionlint -color=never .github/workflows/_stage-1-format-prettier.yml .github/workflows/_stage-2-lint-eslint.yml .github/workflows/_stage-3-typecheck-tsc.yml .github/workflows/_stage-5-test-vitest.yml .github/workflows/_stage-7-integration-vitest.yml .github/workflows/pr-pipeline.yml`
  - Acceptance: artifact `docs/features/active/2026-05-19-rename-cross-language-stages-33/evidence/qa-gates/p7-actionlint.2026-05-19T08-44.md` records `EXIT_CODE: 0` and `Output Summary: no diagnostics`. If `actionlint` is unavailable on the executor host, substitute `gh workflow view <file>` (next task) and record `EXIT_CODE: TOOL_UNAVAILABLE` with justification.

- [x] [P7-T4] Dispatch smoke check for each renamed callee via `gh workflow view` to confirm GitHub recognizes each renamed workflow on the change branch
  - Command: `gh workflow view _stage-1-format-prettier.yml --ref feature/rename-cross-language-stages-33; gh workflow view _stage-2-lint-eslint.yml --ref feature/rename-cross-language-stages-33; gh workflow view _stage-3-typecheck-tsc.yml --ref feature/rename-cross-language-stages-33; gh workflow view _stage-5-test-vitest.yml --ref feature/rename-cross-language-stages-33; gh workflow view _stage-7-integration-vitest.yml --ref feature/rename-cross-language-stages-33`
  - Acceptance: artifact `docs/features/active/2026-05-19-rename-cross-language-stages-33/evidence/qa-gates/p7-gh-workflow-view.2026-05-19T08-44.md` records one block per command with `EXIT_CODE: 0` (or `EXIT_CODE: NETWORK_UNAVAILABLE` with explicit justification if the executor lacks GitHub network access; in that case the smoke check defers to the first PR pipeline run).

- [x] [P7-T5] Confirm `pr-pipeline.yml` `uses:` graph is internally consistent (every `uses:` path exists, no orphan callee outside the orchestrator graph)
  - Command: `python -c "import yaml,os,glob; d=yaml.safe_load(open('.github/workflows/pr-pipeline.yml')); referenced={v['uses'].lstrip('./') for v in d['jobs'].values()}; on_disk=set(glob.glob('.github/workflows/_*.yml')); missing=referenced-on_disk; print('missing',missing); orphans=on_disk-referenced; print('orphans',orphans)"`
  - Acceptance: artifact `docs/features/active/2026-05-19-rename-cross-language-stages-33/evidence/qa-gates/p7-uses-graph.2026-05-19T08-44.md` records `missing set()` and lists any expected orphan callees (e.g. `_stage-4-architecture.yml`, `_stage-6-contract.yml`, `_stage-e2e-smoke.yml`, `_secret-scan.yml`, dotnet siblings) with justification that those are reached via existing orchestrator jobs.

- [x] [P7-T6] Re-read the issue Acceptance Criteria checklist (issue.md lines 38–46) and record each item with verified evidence pointer
  - Acceptance: artifact `docs/features/active/2026-05-19-rename-cross-language-stages-33/evidence/qa-gates/p7-acceptance-mapping.2026-05-19T08-44.md` contains one row per AC bullet listing the evidence artifact path that proves it. No bullet may be marked `verified` without a matching evidence file.

## Test Plan

- **Format / lint of workflows:** `actionlint` over the five renamed callees plus `pr-pipeline.yml` (baseline P0-T4, final P7-T3). If `actionlint` unavailable, `gh workflow view` substitutes (P7-T4).
- **YAML parse:** python `yaml.safe_load` over each renamed file (P1-T6) and the orchestrator (P2-T6, P7-T5).
- **Internal consistency:** `pr-pipeline.yml` `uses:` graph validator confirms every reference resolves to a file on disk (P2-T6, P7-T5).
- **Repo-wide grep:** `rg -F` for each old filename and for the literal `Cross-language` string with `docs/features/**` excluded (P5-T1, P7-T1, P7-T2).
- **Workflow smoke:** `gh workflow view _stage-*.yml --ref feature/rename-cross-language-stages-33` for each renamed callee (P7-T4).
- **Acceptance Criteria reconciliation:** P7-T6 maps every AC bullet from `issue.md` to an evidence artifact.

## Open Questions / Notes

- **`actionlint` availability.** Plan assumes `actionlint` is on PATH for the executor. P0-T4 and P7-T3 include explicit `TOOL_UNAVAILABLE` fallbacks so absence is not silently passed.
- **Pattern A confirmation.** P0-T5 must record `Decision: CONFIRMED` before P1 begins. If the orchestrator instead selects Pattern B, every P1, P2, P3, P4, P6-T1, P7-T3, P7-T4 acceptance criterion must be regenerated using `_stage-N-ts-*.yml` filenames; this is a single global substitution and not a structural plan change.
- **Branch-protection rollout.** This plan produces the mapping artifact (P6-T1) but does not itself flip the protection rule on `main`; that action is reserved for a repo admin and is called out in the PR description.
