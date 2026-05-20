# 2026-05-17-orchestration-missing-ci-green-gate (Plan)

- **Issue:** #26
- **Issue URL:** https://github.com/drmoisan/TMW/issues/26
- **Parent (optional):** none
- **Owner:** drmoisan
- **Branch:** feature/orchestration-missing-ci-green-gate-26
- **Last Updated:** 2026-05-19T10-15
- **Status:** Draft
- **Version:** 0.3
- **Work Mode:** full-bug

**Fail-closed evidence rule:** Each evidence-producing task records its expected artifact path. Audit verdict cannot be PASS while any required baseline, QA, regression, or coverage artifact is missing.

**Evidence accounting rule:** Do not mark evidence-backed tasks complete without the named artifact on disk.

**Evidence location invariant:** All evidence under `docs/features/active/2026-05-17-orchestration-missing-ci-green-gate-26/evidence/<kind>/` per `.claude/skills/evidence-and-timestamp-conventions/SKILL.md`. Non-canonical `artifacts/<kind>/` paths are rejected.

**Work-mode note:** This is a `full-bug` plan. Per the mode contract, `spec.md` is the required acceptance-criteria source (AC1..AC15) and `user-story.md` is absent by default (it has been deleted from this feature folder; full-bug mode does not use a user story). The multi-phase Phase 0..Phase 9 structure below is the correct full-bug structure and must not be collapsed to the 3-phase minor-audit contract.

**Source inputs:**
- `docs/features/active/2026-05-17-orchestration-missing-ci-green-gate-26/issue.md`
- `docs/features/active/2026-05-17-orchestration-missing-ci-green-gate-26/spec.md` (AC1..AC15)
- `docs/features/active/2026-05-17-orchestration-missing-ci-green-gate-26/feature-document.md`

---

### Phase 0 — Context & Baseline Capture

- [x] [P0-T1] Read policy files in required order (`CLAUDE.md`, `.claude/rules/general-code-change.md`, `.claude/rules/general-unit-test.md`, `.claude/rules/quality-tiers.md`, `.claude/rules/powershell.md`, `.claude/rules/tonality.md`) and record evidence at `docs/features/active/2026-05-17-orchestration-missing-ci-green-gate-26/evidence/baseline/phase0-instructions-read.md` with `Timestamp:`, `Policy Order:`, and the explicit list of files read.
- [x] [P0-T2] Record branch + HEAD SHA baseline (`git rev-parse HEAD`, `git status --short`) at `docs/features/active/2026-05-17-orchestration-missing-ci-green-gate-26/evidence/baseline/branch-head.md` with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:`.
- [x] [P0-T3] Capture Pester baseline (`Invoke-Pester -CI` on `tests/pester` or repo-standard root) at `evidence/baseline/pester-baseline.md` with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:` including pass/fail count and coverage headline.
- [x] [P0-T4] Capture Python baseline (`pytest -q` repo root) at `evidence/baseline/pytest-baseline.md` with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:` including pass/fail count and coverage headline if produced.
- [x] [P0-T5] Capture PSScriptAnalyzer baseline (`Invoke-ScriptAnalyzer -Path scripts -Recurse`) at `evidence/baseline/psscriptanalyzer-baseline.md` with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:`.
- [x] [P0-T6] Capture Invoke-Formatter dry-run baseline (`Invoke-Formatter` over `scripts/**/*.ps1`) at `evidence/baseline/posh-format-baseline.md` with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:`.
- [x] [P0-T7] Record links to inputs (issue, spec, feature doc) at `evidence/baseline/inputs-index.md` with absolute paths, and record `user-story.md ABSENT (full-bug mode, no user story)` in the same artifact.

### Phase 1 — Regression / Synthetic-Failure Design

- [x] [P1-T1] [expect-fail] Author Pester regression `tests/pester/orchestration/CiGate.Parser.Tests.ps1` covering `gh pr checks --json` parser with at least: all-success positive case, one-required-failed negative case, one-in-progress negative case, malformed-JSON error path, empty-checks error path. Record artifact at `evidence/regression-testing/p1-t1-parser-regression.md` capturing the failing run (`Timestamp:`, `Command:`, `EXIT_CODE: non-zero`, `Output Summary:`).
- [x] [P1-T2] [expect-fail] Author Pester regression `tests/pester/benchmarks/BaselineProvenance.Tests.ps1` covering rejection of `HostEnvironmentInfo.ProcessorName == "Unknown processor"`, rejection of missing sibling `baseline.provenance.json`, and acceptance of a valid runner-captured baseline. Record failing run at `evidence/regression-testing/p1-t2-provenance-regression.md`.
- [x] [P1-T3] [expect-fail] Author Pester regression `tests/pester/feature-review/ModifiedWorkflowNeedsGreenRun.Tests.ps1` for the policy-audit rule that flags diffs under `.github/workflows/**`, `scripts/benchmarks/**`, `.github/actions/**` without green-run evidence. Record failing run at `evidence/regression-testing/p1-t3-policy-rule-regression.md`.
- [x] [P1-T4] Verify all three regressions fail for the documented reason (target artifact missing or behavior absent), not for unrelated harness errors. Record consolidated verification at `evidence/regression-testing/p1-t4-fail-before-summary.md`.

### Phase 2 — Author Repo Rule Files

- [x] [P2-T1] Create `.claude/rules/benchmark-baselines.md` defining runner-environment parity: explicit rejection of `HostEnvironmentInfo.ProcessorName == "Unknown processor"` and required sibling `baseline.provenance.json` recording runner class, host signature, and producing workflow run URL. Evidence path `evidence/other/p2-t1-benchmark-baselines-rule.md` capturing diff and file path.
- [x] [P2-T2] Create `.claude/rules/ci-workflows.md` documenting the `pwsh` deliberately-failing-nested-command pattern: requires explicit `$LASTEXITCODE = 0` reset after expected failure or explicit `exit 0` on success path. Evidence path `evidence/other/p2-t2-ci-workflows-rule.md`.
- [x] [P2-T3] Run `Invoke-ScriptAnalyzer` (no-op for markdown but validates discovery) and `markdownlint` if available on the two new rule files; record results at `evidence/qa-gates/p2-t3-rules-lint.md`.

### Phase 3 — Update `.claude/skills/orchestrate/SKILL.md`

- [x] [P3-T1] Add `S9_ci_green` step definition between `S8_create_pr` and DONE, requiring `gh pr checks --required --json` against live PR head SHA. Evidence at `evidence/other/p3-t1-s9-step.md` (diff hunk + file path).
- [x] [P3-T2] Extend checkpoint schema with `ci_gate` object (`head_sha`, `pr_pipeline_run_id`, `pr_pipeline_run_url`, `conclusion`, `verified_at`) and top-level `last_verified_ci_sha`, `step9_status` (enum: `pending`, `passed`, `failed_remediation_required`, `blocked_ci_loop_limit`). Evidence at `evidence/other/p3-t2-checkpoint-schema.md`.
- [x] [P3-T3] Add fifth PR Creation Gate condition: `ci_gate.conclusion == "success"` AND `ci_gate.head_sha == current head SHA`; state explicitly DONE is not written while either sub-condition is false. Evidence at `evidence/other/p3-t3-pr-gate-fifth.md`.
- [x] [P3-T4] Document remediation-loop CI-failure handling: failed required check converted to synthetic blocking finding written to `remediation-inputs.<timestamp>.md`; R1-R5 loop processes that finding. Evidence at `evidence/other/p3-t4-remediation-ci.md`.
- [x] [P3-T5] Document `remediation_pass` cap of 3 applied to CI failure passes; third pass sets `step9_status: "blocked_ci_loop_limit"`, does not write DONE, halts. Evidence at `evidence/other/p3-t5-cap-and-halt.md`.
- [x] [P3-T6] Document backward-compat: missing `ci_gate` in pre-existing checkpoints is treated as `pending`. Evidence at `evidence/other/p3-t6-backcompat.md`.

### Phase 4 — Update `.claude/skills/feature-review-workflow/SKILL.md`

- [x] [P4-T1] Add policy rule `modified-workflow-needs-green-run` with trigger paths `.github/workflows/**`, `scripts/benchmarks/**`, `.github/actions/**`; rule emits Blocking finding unless a green workflow run against branch head appears in remediation inputs. Evidence at `evidence/other/p4-t1-policy-rule.md` (diff hunk + file path).
- [x] [P4-T2] Document that a green `workflow_dispatch` run against the branch head also satisfies the rule (chicken-and-egg mitigation per spec risks). Evidence at `evidence/other/p4-t2-dispatch-allowance.md`.

### Phase 5 — Supporting PowerShell Validators

- [x] [P5-T1] Create `scripts/orchestration/Invoke-CiGateParser.ps1` that consumes `gh pr checks --required --json` output and emits the `ci_gate` JSON object defined in P3-T2. Evidence at `evidence/other/p5-t1-parser-script.md` (file path + 5-line summary).
- [x] [P5-T2] Create `scripts/benchmarks/Test-BaselineProvenance.ps1` enforcing the rule in `.claude/rules/benchmark-baselines.md`: reject `ProcessorName == "Unknown processor"`, reject missing sibling `baseline.provenance.json`. Evidence at `evidence/other/p5-t2-provenance-script.md`.
- [x] [P5-T3] Re-run Pester regression `tests/pester/orchestration/CiGate.Parser.Tests.ps1`; confirm all five scenarios now pass. Evidence at `evidence/qa-gates/p5-t3-parser-pass.md` with `Timestamp:`, `Command:`, `EXIT_CODE: 0`, `Output Summary:`.
- [x] [P5-T4] Re-run Pester regression `tests/pester/benchmarks/BaselineProvenance.Tests.ps1`; confirm all three scenarios now pass. Evidence at `evidence/qa-gates/p5-t4-provenance-pass.md`.
- [x] [P5-T5] Re-run Pester regression `tests/pester/feature-review/ModifiedWorkflowNeedsGreenRun.Tests.ps1`; confirm rule logic passes. Evidence at `evidence/qa-gates/p5-t5-policy-rule-pass.md`.
- [x] [P5-T6] Apply PoshQC loop on the two new scripts: `Invoke-Formatter` → `Invoke-ScriptAnalyzer` → Pester. Restart on any change. Evidence at `evidence/qa-gates/p5-t6-poshqc.md`.

### Phase 6 — Bundled-Mirror Sync

Scope note (repository-specific): TMW does not maintain a fixed `.codex/` + `.agents/` + `.github/` mirror set for every `.claude/` file, and `.github/workflows/` has no bundled mirror at all. `.codex/` contains only `prompts/` and a plan file (no `skills/` or `rules/`). `.agents/` contains `skills/` but no `rules/`. `.github/` exposes `skills/` (partial coverage) and uses `instructions/*.instructions.md` naming rather than a 1:1 `rules/` mirror. Mirror-sync tasks below MUST first confirm the authoritative mirror map for the specific changed files rather than assuming a uniform mirror set, and MUST only edit mirrors that actually exist.

- [x] [P6-T1] Enumerate every modified or added file under `.claude/` since branch base; list at `evidence/other/p6-t1-claude-changeset.md` with `Timestamp:`, `Command: git diff --name-only main -- .claude`, `EXIT_CODE:`, `Output Summary:`.
- [x] [P6-T2] Build the authoritative mirror map: for each changed `.claude/skills/**` and `.claude/rules/**` file from P6-T1, probe the repo bundle layout (`.codex/`, `.agents/`, `.github/`) to determine which mirrors actually exist for that exact file (e.g., `.agents/skills/orchestrate/SKILL.md`, `.agents/skills/feature-review-workflow/SKILL.md`, `.github/skills/feature-review-workflow/SKILL.md`), and record which paths exist versus do not exist. New `.claude/rules/*.md` files (e.g., `benchmark-baselines.md`, `ci-workflows.md`) have no `.agents/rules/` or `.codex/rules/` target and no 1:1 `.github/rules/` target; record that explicitly. Evidence at `evidence/other/p6-t2-mirror-map.md` with `Timestamp:`, per-file `EXISTS:`/`ABSENT:` lines, and `Output Summary:`.
- [x] [P6-T3] For each `.claude/` changed file that has an existing `.agents/` mirror per the P6-T2 map (at minimum `.agents/skills/orchestrate/SKILL.md` and `.agents/skills/feature-review-workflow/SKILL.md`), update the `.agents/` mirror to byte-match the `.claude/` source. Evidence at `evidence/other/p6-t3-agents-sync.md` (one line per file synced; record `NO .agents MIRROR` for changed files with no `.agents/` counterpart).
- [x] [P6-T4] For each `.claude/` changed file that has an existing `.github/` mirror per the P6-T2 map (at minimum `.github/skills/feature-review-workflow/SKILL.md`), update the `.github/` mirror to match the `.claude/` source. Record `NO .github MIRROR` for changed files with no `.github/` counterpart (including the new `.claude/rules/*.md` files). Evidence at `evidence/other/p6-t4-github-sync.md`.
- [x] [P6-T5] Verify byte/content parity between each `.claude/` source and every existing mirror identified in P6-T2 (`git diff --no-index` per pair or sha256 comparison). Evidence at `evidence/qa-gates/p6-t5-mirror-parity.md` with `Timestamp:`, `Command:`, `EXIT_CODE: 0`, and one parity line per mirrored pair.
- [x] [P6-T6] Confirm the no-mirror facts for this changeset: `.codex/` has no `skills/`/`rules/` target, `.agents/` has no `rules/` target, and `.github/workflows/` has no bundled mirror, so no mirror edits are required for those roots. Record at `evidence/qa-gates/p6-t6-no-mirror-attestation.md`. (If a repo bundle-contract test suite is discovered during P6-T2, run it and record `Command:`/`EXIT_CODE:` here instead of an attestation.)

### Phase 7 — Full Mandatory Toolchain Loop

- [x] [P7-T1] Run formatting stage (`Invoke-Formatter` on scripts; `black`/`prettier` if applicable to changes). Restart loop on any auto-fix. Evidence at `evidence/qa-gates/p7-t1-format.md`.
- [x] [P7-T2] Run lint stage (`Invoke-ScriptAnalyzer`; `ruff`/`eslint` if applicable). Evidence at `evidence/qa-gates/p7-t2-lint.md` with `EXIT_CODE: 0`.
- [x] [P7-T3] Run type-check stage for in-scope languages (skip PowerShell per policy). Evidence at `evidence/qa-gates/p7-t3-typecheck.md`.
- [x] [P7-T4] Run architecture-boundary tests (`dependency-cruiser`/`NetArchTest` if applicable; record `SKIPPED` only if no such tests apply to the changeset and document the reason in the artifact). Evidence at `evidence/qa-gates/p7-t4-arch.md`.
- [x] [P7-T5] Run unit tests with coverage: Pester (`Invoke-Pester -CodeCoverage`) and pytest (`pytest --cov`). Record numeric line + branch coverage in `Output Summary:` at `evidence/qa-gates/p7-t5-unit.md`. EXIT_CODE must be 0; coverage line >= 85%, branch >= 75%.
- [x] [P7-T6] Run contract/schema compatibility checks for the orchestrator-state schema and any modified contract surfaces. Evidence at `evidence/qa-gates/p7-t6-contract.md`.
- [x] [P7-T7] Run integration tests covering the orchestrate skill S9 path end-to-end against fixture `gh` output. Evidence at `evidence/qa-gates/p7-t7-integration.md`.
- [x] [P7-T8] Confirm the full seven-stage loop completed in a single pass with no auto-fixes and no failures. Evidence at `evidence/qa-gates/p7-t8-clean-pass-attestation.md`.
- [x] [P7-T9] Capture post-change coverage delta vs. Phase 0 baselines (Pester + pytest) at `evidence/qa-gates/p7-t9-coverage-delta.md` showing baseline %, post-change %, and new-code % with no regression on changed lines.

### Phase 8 — Acceptance-Criteria Checkoff

- [x] [P8-T1] Verify AC1 (`S9_ci_green` defined in `.claude/skills/orchestrate/SKILL.md`); record at `evidence/qa-gates/p8-ac01.md` with file path + line range.
- [x] [P8-T2] Verify AC2 (checkpoint schema fields present with enumerated `step9_status`); record at `evidence/qa-gates/p8-ac02.md`.
- [x] [P8-T3] Verify AC3 (fifth PR Creation Gate condition); record at `evidence/qa-gates/p8-ac03.md`.
- [x] [P8-T4] Verify AC4 (synthetic blocking finding + `remediation-inputs.<timestamp>.md` flow documented); record at `evidence/qa-gates/p8-ac04.md`.
- [x] [P8-T5] Verify AC5 (`remediation_pass` cap 3 and `blocked_ci_loop_limit` halt documented); record at `evidence/qa-gates/p8-ac05.md`.
- [x] [P8-T6] Verify AC6 (`modified-workflow-needs-green-run` rule with three trigger globs); record at `evidence/qa-gates/p8-ac06.md`.
- [x] [P8-T7] Verify AC7 (`.claude/rules/benchmark-baselines.md` rejects `"Unknown processor"` and requires sibling provenance JSON); record at `evidence/qa-gates/p8-ac07.md`.
- [x] [P8-T8] Verify AC8 (`.claude/rules/ci-workflows.md` documents pwsh exit-code pattern); record at `evidence/qa-gates/p8-ac08.md`.
- [x] [P8-T9] Verify AC9 (parser script exists and is invoked by S9 per skill text); record at `evidence/qa-gates/p8-ac09.md`.
- [x] [P8-T10] Verify AC10 (Pester coverage of all five parser scenarios; cross-link P5-T3 evidence); record at `evidence/qa-gates/p8-ac10.md`.
- [x] [P8-T11] Verify AC11 (provenance validator script exists with both rejection paths); record at `evidence/qa-gates/p8-ac11.md`.
- [x] [P8-T12] Verify AC12 (Pester coverage of three provenance scenarios; cross-link P5-T4 evidence); record at `evidence/qa-gates/p8-ac12.md`.
- [x] [P8-T13] Verify AC13 (bundled-mirror parity for existing mirrors confirmed by P6-T5, plus the P6-T6 no-mirror attestation for roots without a mirror target); record at `evidence/qa-gates/p8-ac13.md`.
- [x] [P8-T14] Verify AC14 (full mandatory toolchain single-pass clean; cross-link P7-T8); record at `evidence/qa-gates/p8-ac14.md`.
- [x] [P8-T15] Verify AC15 (recorded PARTIAL/UNVERIFIED — see evidence/qa-gates/p8-ac15.md; AC15 left unchecked in spec.md pending orchestrator S8/S9 green-run) (PR Pipeline `success` against branch head SHA and `ci_gate` recorded on this feature's checkpoint before DONE). Evidence at `evidence/qa-gates/p8-ac15.md` including `gh pr checks --required --json` snapshot and checkpoint file excerpt.

### Phase 9 — Documentation, Status Sync, Handoff

- [x] [P9-T1] Update `docs/features/active/2026-05-17-orchestration-missing-ci-green-gate-26/feature-document.md` status section to `Implemented`; record diff hunk at `evidence/other/p9-t1-feature-doc-update.md`.
- [x] [P9-T2] Update `docs/features/active/2026-05-17-orchestration-missing-ci-green-gate-26/spec.md` Status from `Draft` to `Implemented`; record at `evidence/other/p9-t2-spec-status.md`.
- [x] [P9-T3] Post issue update comment on #26 summarizing closure with AC1..AC15 cross-references; mirror at `evidence/issue-updates/issue-26.2026-05-19T10-15.md` with `PostedAs:`, GitHub URL, `Timestamp:`.
- [x] [P9-T4] Delete or overwrite the prior MCP-stub plan file `plan.2026-05-19T08-53.md`; record action at `evidence/other/p9-t4-stub-removal.md`.
- [x] [P9-T5] Final handoff: emit `PREFLIGHT: ALL CLEAR` signal for the executor and record handoff manifest at `evidence/other/p9-t5-handoff.md` referencing this plan path and the AC8 cross-reference table.
