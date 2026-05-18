# Plan — Reusable Workflow Refactor for `pr-pipeline.yml` (Issue #27)

- Issue: #27
- Feature folder: `docs/features/active/2026-05-17-reusable-workflow-refactor-pr-pipeline-27/`
- Plan timestamp: 2026-05-18T10-15
- Work Mode: full-feature (CI/YAML-only refactor; no production code change)
- Authoritative sources: `spec.md` (v0.2) > `user-story.md` (AC1–AC10) > `issue.md`
- Evidence root (canonical): `docs/features/active/2026-05-17-reusable-workflow-refactor-pr-pipeline-27/evidence/`

## Scope and Toolchain Notes

This refactor moves only YAML between files. There is no Python, TypeScript, C#, or PowerShell production-code change. The seven-stage toolchain from `general-code-change.md` reduces, for each task, to:

1. YAML formatting + structural parse (`actionlint` if present; otherwise `ConvertFrom-Yaml` parse of touched files).
2. YAML lint — same step as above when `actionlint` is present.
3. Type check — not applicable (no typed language touched).
4. Architecture-boundary tests — not applicable.
5. Pre-existing Pester/Pytest/PSScriptAnalyzer regression suites must still pass unchanged. Full regression run is gated at Phase 6 only (per the instructions). Per-task verification uses YAML parse + structural diff.
6. Contract / schema diff — not applicable (no public-API surface changed).
7. Integration tests — exercised via `pr-pipeline.yml`-driven dispatch verification in Phase 6.

No P#-T# task modifies more than three production files. Production files for this refactor = `.github/workflows/*.yml`, `.github/workflows/README.md`, `.claude/skills/orchestrate/SKILL.md`.

Evidence-location invariant: every artifact path below resolves under `<FEATURE>/evidence/<kind>/`. Non-canonical locations (`artifacts/baselines/`, `artifacts/qa/`, etc.) are rejected by policy.

---

### Phase 0 — Policy reads and baseline capture

- [x] [P0-T1] Read repository policy files in canonical order and record evidence.
  - Files read (no edits): `CLAUDE.md`, `.claude/rules/general-code-change.md`, `.claude/rules/general-unit-test.md`, `.claude/rules/quality-tiers.md`, `.claude/rules/powershell.md`, `.claude/rules/tonality.md`.
  - Verification method: file read confirmation.
  - Evidence: `evidence/baseline/phase0-instructions-read.md` containing `Timestamp:`, `Policy Order:`, explicit file list.

- [x] [P0-T2] Capture baseline directory listing of `.github/workflows/`.
  - File touched: none (read-only).
  - Verification: `Get-ChildItem .github/workflows/ -File | Select-Object Name, Length, LastWriteTime`.
  - Evidence: `evidence/baseline/workflows-listing.2026-05-18T10-15.md` with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:` (file count and names).

- [x] [P0-T3] Capture full pre-refactor text of `.github/workflows/pr-pipeline.yml` for byte-identity diffing.
  - File touched: none (read-only copy).
  - Verification: copy file content into evidence artifact unchanged.
  - Evidence: `evidence/baseline/pr-pipeline.pre-refactor.yml` (verbatim copy) plus `evidence/baseline/pr-pipeline.pre-refactor.sha256.md` with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:` (sha256 hash).

- [x] [P0-T4] Capture full pre-refactor text of the two duplicate mirror files for deletion provenance.
  - Files touched: none (read-only copies).
  - Verification: copy `.github/workflows/stage-10-benchmark-regression.yml` and `.github/workflows/benchmark-gate-self-validation.yml` content into evidence artifacts.
  - Evidence: `evidence/baseline/stage-10-benchmark-regression.pre-delete.yml` and `evidence/baseline/benchmark-gate-self-validation.pre-delete.yml` plus a single `evidence/baseline/duplicate-mirrors.sha256.md` with sha256 of each.

- [x] [P0-T5] Build a per-job inventory of `pr-pipeline.yml` (17 jobs) for extraction tracking.
  - File touched: none.
  - Verification: enumerate each `jobs.<id>` block; record job id, `runs-on:`, `needs:`, `if:`, `env:`, secrets consumed, step count, and target callee filename per spec section "Files to create".
  - Evidence: `evidence/baseline/job-inventory.2026-05-18T10-15.md` with one table row per job, `Timestamp:`, `Output Summary:` ("17 jobs catalogued").

- [x] [P0-T6] Baseline YAML parse of every file in `.github/workflows/` (proves the starting state is parseable).
  - File touched: none.
  - Verification: `Get-ChildItem .github/workflows/*.yml | ForEach-Object { try { Get-Content $_.FullName -Raw | ConvertFrom-Yaml | Out-Null; "OK: $($_.Name)" } catch { "FAIL: $($_.Name) - $_" } }`. If `actionlint.exe` is on PATH, also run `actionlint .github/workflows/*.yml`.
  - Evidence: `evidence/baseline/yaml-parse-baseline.2026-05-18T10-15.md` with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:` (pass/fail per file; presence/absence of actionlint).

- [x] [P0-T7] Baseline regression-suite run for languages that have pre-existing test surface — Pester.
  - File touched: none.
  - Verification: run repo's Pester invocation (e.g., `Invoke-Pester -CI`) once and record outcome. Coverage numbers are captured if the existing harness reports them; otherwise note "harness does not emit coverage in this invocation" — no policy violation because this refactor adds no new PowerShell code subject to the coverage gate.
  - Evidence: `evidence/baseline/pester-baseline.2026-05-18T10-15.md` with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:` (pass/fail counts, coverage headline if available).

- [x] [P0-T8] Baseline regression-suite run — Pytest (if any Python test surface is reachable from this branch).
  - File touched: none.
  - Verification: run `pytest --cov --cov-report=term` against the repository's Python test root if present; otherwise record `Output Summary: no python test surface in scope`.
  - Evidence: `evidence/baseline/pytest-baseline.2026-05-18T10-15.md` with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:` (pass/fail and coverage headline, or N/A note).

- [x] [P0-T9] Baseline PSScriptAnalyzer run on `scripts/` and `.github/scripts/`.
  - File touched: none.
  - Verification: `Invoke-ScriptAnalyzer -Path scripts/, .github/scripts/ -Recurse`.
  - Evidence: `evidence/baseline/psscriptanalyzer-baseline.2026-05-18T10-15.md` with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:` (issue count by severity).

---

### Phase 1 — Cross-job filesystem dependency audit (confirm spec assertion)

- [x] [P1-T1] Programmatically confirm no job in `pr-pipeline.yml` consumes another job's working-tree path or `actions/download-artifact`.
  - File touched: none.
  - Verification: grep `pr-pipeline.yml` for `download-artifact`, `needs.<id>.outputs`, `actions/cache`. Expected: only `upload-artifact` in `stage-10-benchmark-regression`, no `download-artifact`, no `outputs:` cross-references.
  - Evidence: `evidence/baseline/cross-job-fs-audit.2026-05-18T10-15.md` with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:` ("no cross-job filesystem reliance found — confirms spec section 'Risks & Mitigations'" or, if a counter-example is found, halt and report STRUCTURAL IMPOSSIBILITY before continuing).

---

### Phase 2 — Extract callees (one file per task)

For every task in this phase the toolchain loop is: write the callee file -> `ConvertFrom-Yaml` parse the new file -> diff its `steps:` block against the corresponding inline block captured in `evidence/baseline/pr-pipeline.pre-refactor.yml`. The diff must show only the `on: workflow_call:` + `on: workflow_dispatch:` trigger block as added content and the `needs:` line as removed (relocation to caller).

Each task touches exactly one new file (`<= 3` production-file limit honoured trivially).

- [x] [P2-T1] Create `.github/workflows/_tier-classification.yml` from the `tier-classification` job.
  - Source job: `tier-classification` (windows-latest, no `needs:`, no `env:`, one step invoking `validate-quality-tiers.ps1`).
  - File created: `.github/workflows/_tier-classification.yml`.
  - Triggers: `on: workflow_call:` (no inputs, no secrets) and `on: workflow_dispatch:`.
  - Verification: YAML parse OK; `steps:` byte-identical to baseline inline block.
  - Evidence: `evidence/qa-gates/extract-tier-classification.2026-05-18T10-15.md` (`Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:` with diff summary).

- [x] [P2-T2] Create `.github/workflows/_stage-1-format.yml` from `stage-1-format`.
  - Source job: `stage-1-format` (windows-latest, single composite-action step `./.github/actions/format`).
  - File created: `.github/workflows/_stage-1-format.yml`.
  - Triggers: `workflow_call:` + `workflow_dispatch:`.
  - Verification: parse + steps-diff vs baseline.
  - Evidence: `evidence/qa-gates/extract-stage-1-format.2026-05-18T10-15.md`.

- [x] [P2-T3] Create `.github/workflows/_stage-2-lint.yml` from `stage-2-lint`.
  - File created: `.github/workflows/_stage-2-lint.yml`.
  - Verification: parse + steps-diff.
  - Evidence: `evidence/qa-gates/extract-stage-2-lint.2026-05-18T10-15.md`.

- [x] [P2-T4] Create `.github/workflows/_stage-3-typecheck.yml` from `stage-3-typecheck`.
  - File created: `.github/workflows/_stage-3-typecheck.yml`.
  - Verification: parse + steps-diff.
  - Evidence: `evidence/qa-gates/extract-stage-3-typecheck.2026-05-18T10-15.md`.

- [x] [P2-T5] Create `.github/workflows/_stage-4-architecture.yml` from `stage-4-architecture`.
  - File created: `.github/workflows/_stage-4-architecture.yml`.
  - Verification: parse + steps-diff.
  - Evidence: `evidence/qa-gates/extract-stage-4-architecture.2026-05-18T10-15.md`.

- [x] [P2-T6] Create `.github/workflows/_stage-5-test.yml` from `stage-5-test`.
  - File created: `.github/workflows/_stage-5-test.yml`.
  - Verification: parse + steps-diff.
  - Evidence: `evidence/qa-gates/extract-stage-5-test.2026-05-18T10-15.md`.

- [x] [P2-T7] Create `.github/workflows/_stage-6-contract.yml` from `stage-6-contract`.
  - Source job: ubuntu-latest, `actions/checkout@v4` with `fetch-depth: 0`, two composite actions (`contract`, `schema-contract`).
  - File created: `.github/workflows/_stage-6-contract.yml`.
  - Verification: parse + steps-diff (must preserve `fetch-depth: 0`).
  - Evidence: `evidence/qa-gates/extract-stage-6-contract.2026-05-18T10-15.md`.

- [x] [P2-T8] Create `.github/workflows/_stage-7-integration.yml` from `stage-7-integration`.
  - File created: `.github/workflows/_stage-7-integration.yml`.
  - Verification: parse + steps-diff.
  - Evidence: `evidence/qa-gates/extract-stage-7-integration.2026-05-18T10-15.md`.

- [x] [P2-T9] Create `.github/workflows/_stage-1-dotnet-format.yml` from `stage-1-dotnet-format`.
  - File created: `.github/workflows/_stage-1-dotnet-format.yml`.
  - Verification: parse + steps-diff.
  - Evidence: `evidence/qa-gates/extract-stage-1-dotnet-format.2026-05-18T10-15.md`.

- [x] [P2-T10] Create `.github/workflows/_stage-2-dotnet-build.yml` from `stage-2-dotnet-build`.
  - File created: `.github/workflows/_stage-2-dotnet-build.yml`.
  - Verification: parse + steps-diff.
  - Evidence: `evidence/qa-gates/extract-stage-2-dotnet-build.2026-05-18T10-15.md`.

- [x] [P2-T11] Create `.github/workflows/_stage-3-dotnet-typecheck.yml` from `stage-3-dotnet-typecheck`.
  - Source job: contains a `name:` + inline `pwsh` `Write-Host` step explaining nullable analysis. Preserve verbatim.
  - File created: `.github/workflows/_stage-3-dotnet-typecheck.yml`.
  - Verification: parse + steps-diff (inline pwsh string byte-identical).
  - Evidence: `evidence/qa-gates/extract-stage-3-dotnet-typecheck.2026-05-18T10-15.md`.

- [x] [P2-T12] Create `.github/workflows/_stage-4-dotnet-architecture.yml` from `stage-4-dotnet-architecture`.
  - File created: `.github/workflows/_stage-4-dotnet-architecture.yml`.
  - Verification: parse + steps-diff.
  - Evidence: `evidence/qa-gates/extract-stage-4-dotnet-architecture.2026-05-18T10-15.md`.

- [x] [P2-T13] Create `.github/workflows/_stage-5-dotnet-test.yml` from `stage-5-dotnet-test`.
  - File created: `.github/workflows/_stage-5-dotnet-test.yml`.
  - Verification: parse + steps-diff.
  - Evidence: `evidence/qa-gates/extract-stage-5-dotnet-test.2026-05-18T10-15.md`.

- [x] [P2-T14] Create `.github/workflows/_stage-e2e-smoke.yml` from `stage-e2e-smoke`.
  - Source job: ubuntu-latest, four steps (`setup-node@v4` with `cache: npm`, `npm ci`, `npx playwright install`, `npx playwright test`). Consumes secrets `AZURE_TENANT_ID`, `AZURE_CLIENT_ID`, `AZURE_CLIENT_SECRET`, `E2E_API_BASE_URL` via `env:` mapping on the final step.
  - File created: `.github/workflows/_stage-e2e-smoke.yml`.
  - Triggers: `on: workflow_call:` MUST include a `secrets:` block declaring all four secrets as `required: true`. `on: workflow_dispatch:` also included.
  - `if:` guard is NOT moved to the callee (per spec invariant: `if:` is a caller-level construct).
  - Verification: parse + steps-diff (env block byte-identical); inspect `workflow_call.secrets:` for the four named entries.
  - Evidence: `evidence/qa-gates/extract-stage-e2e-smoke.2026-05-18T10-15.md` (`Output Summary:` must explicitly list the four declared secrets).

- [x] [P2-T15] Create `.github/workflows/_stage-10-benchmark-regression.yml` from `stage-10-benchmark-regression`.
  - Source job: windows-latest, four steps (setup-dotnet, run benchmarks, enrich report, upload-artifact `if: always()`, compare against baseline). Preserve `if: always()` and all pwsh `run:` blocks verbatim.
  - File created: `.github/workflows/_stage-10-benchmark-regression.yml`.
  - Triggers: `workflow_call:` + `workflow_dispatch:`.
  - Verification: parse + steps-diff (upload-artifact name `stage-10-benchmark-report` and path `artifacts/benchmarks/run/results/*-report-full.json` preserved).
  - Evidence: `evidence/qa-gates/extract-stage-10-benchmark-regression.2026-05-18T10-15.md`.

- [x] [P2-T16] Create `.github/workflows/_benchmark-gate-self-validation.yml` from `benchmark-gate-self-validation`.
  - Source job: windows-latest, setup-dotnet plus the composite pwsh step containing the latency-gate pass + non-idempotent-negative test + `exit 0` reset. Preserve the multi-line `run:` block byte-identically.
  - File created: `.github/workflows/_benchmark-gate-self-validation.yml`.
  - Triggers: `workflow_call:` + `workflow_dispatch:`.
  - Verification: parse + character-exact diff of the pwsh `run:` block including the trailing `exit 0` line and the comment above it.
  - Evidence: `evidence/qa-gates/extract-benchmark-gate-self-validation.2026-05-18T10-15.md`.

- [x] [P2-T17] Create `.github/workflows/_secret-scan.yml` from `secret-scan`.
  - Source job: windows-latest, top-level `env: GH_TOKEN: ${{ github.token }}`, `actions/checkout@v4` with `fetch-depth: 0`, install-gitleaks pwsh step, scan PR diff pwsh step using `origin/${{ github.base_ref }}..HEAD`.
  - File created: `.github/workflows/_secret-scan.yml`.
  - Triggers: `workflow_call:` + `workflow_dispatch:`.
  - Verification: parse + steps-diff (env block + fetch-depth preserved). Note: `github.base_ref` is empty under `workflow_dispatch`; callee remains byte-identical to source and that behavioural nuance is unchanged from the pre-refactor state.
  - Evidence: `evidence/qa-gates/extract-secret-scan.2026-05-18T10-15.md`.

---

### Phase 3 — Refactor orchestrator `pr-pipeline.yml`

- [ ] [P3-T1] Rewrite `.github/workflows/pr-pipeline.yml` to bodyless `uses:` jobs.
  - File touched: `.github/workflows/pr-pipeline.yml` (1 file).
  - Required structure:
    - Top-level `name: PR Pipeline`, `on: pull_request: branches: [main]` + `workflow_dispatch:`, `permissions: contents: read` — unchanged.
    - `jobs:` map with one entry per pre-refactor job id (17 entries), each containing only `uses: ./.github/workflows/_<name>.yml`, plus `needs:` exactly matching the pre-refactor graph, plus `if:` on `stage-e2e-smoke` (`contains(github.event.pull_request.labels.*.name, 'e2e:run')`), plus `secrets: inherit` on `stage-e2e-smoke`.
    - No inline `steps:` anywhere in the file.
  - Verification: `ConvertFrom-Yaml` parse OK; assert `jobs.*.steps` is absent across the document; assert `jobs.stage-e2e-smoke.if` matches the baseline `if:` string; assert every `uses:` path resolves to a `_*.yml` file created in Phase 2.
  - Evidence: `evidence/qa-gates/orchestrator-rewrite.2026-05-18T10-15.md` with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:` ("no inline steps; 17 uses-jobs; needs graph matches baseline; e2e if-guard and secrets:inherit present").

---

### Phase 4 — Delete duplicate mirrors

- [ ] [P4-T1] Delete `.github/workflows/stage-10-benchmark-regression.yml`.
  - File touched: `.github/workflows/stage-10-benchmark-regression.yml` (deletion).
  - Verification: file no longer exists; sha256 recorded in `evidence/baseline/duplicate-mirrors.sha256.md` matches `evidence/baseline/stage-10-benchmark-regression.pre-delete.yml` (provenance preserved).
  - Evidence: `evidence/qa-gates/delete-stage-10-mirror.2026-05-18T10-15.md` with `Timestamp:`, `Command:` (`git rm .github/workflows/stage-10-benchmark-regression.yml`), `EXIT_CODE:`, `Output Summary:`.

- [ ] [P4-T2] Delete `.github/workflows/benchmark-gate-self-validation.yml`.
  - File touched: `.github/workflows/benchmark-gate-self-validation.yml` (deletion).
  - Verification: file no longer exists; baseline copy preserved.
  - Evidence: `evidence/qa-gates/delete-self-validation-mirror.2026-05-18T10-15.md`.

---

### Phase 5 — Documentation

- [ ] [P5-T1] Create `.github/workflows/README.md` documenting the callee/caller convention and dispatch invocations.
  - File touched: `.github/workflows/README.md` (1 new file).
  - Required content:
    - Convention statement: any new gate ships as `_<name>.yml` callee with `workflow_call:` + `workflow_dispatch:`; the orchestrator only references callees via `uses:`. Document the GitHub Actions reusable-workflow nesting depth cap of 4.
    - Per-stage one-line dispatch invocations for all 17 callees: `gh workflow run _<name>.yml --ref <branch>`.
    - Branch-protection rename procedure: enumerate the pre-refactor check names and the post-refactor `<caller-job-name> / <callee-job-name>` mapping; instruct admin to remove the old names and add the new names in the required-checks list on `main`.
    - Secrets-forwarding note: `_stage-e2e-smoke.yml` declares Azure secrets; caller passes `secrets: inherit`.
  - Verification: structural inspection of the document; presence of all 17 stage names and the branch-protection mapping.
  - Evidence: `evidence/qa-gates/readme-created.2026-05-18T10-15.md` with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:` (section list).

- [ ] [P5-T2] Update `.claude/skills/orchestrate/SKILL.md` with the callee/caller convention rule.
  - File touched: `.claude/skills/orchestrate/SKILL.md` (1 file).
  - Required content: a short subsection (under an existing "Conventions" heading, or a new "GitHub Actions Reusable Workflows" subsection) stating: every new CI gate is a `_<name>.yml` callee with `workflow_call:` + `workflow_dispatch:`; orchestrators contain no inline `steps:`; cross-job filesystem reliance must use explicit `upload-artifact`/`download-artifact`; reusable-workflow nesting depth cap is 4.
  - Verification: grep for the new subsection text after edit.
  - Evidence: `evidence/qa-gates/skill-updated.2026-05-18T10-15.md` with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:` (subsection title + line count).

---

### Phase 6 — Verification (full regression and dispatch plan)

- [ ] [P6-T1] Post-refactor YAML parse and (if available) `actionlint` on `.github/workflows/*.yml`.
  - File touched: none.
  - Verification: same commands as P0-T6, run against the refactored tree. Result: every file parses; if `actionlint` is present it must report zero errors.
  - Evidence: `evidence/qa-gates/yaml-parse-postrefactor.2026-05-18T10-15.md` with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:` (file count and pass/fail map; actionlint outcome).

- [ ] [P6-T2] Structural byte-identity diff of each callee's `steps:` block vs the captured baseline inline job.
  - File touched: none.
  - Verification: for each of the 17 callees, extract its `jobs.<id>.steps` block and diff against the corresponding block in `evidence/baseline/pr-pipeline.pre-refactor.yml`. Acceptable differences: indentation normalisation only. The `needs:` line is expected to be absent in the callee (moved to caller). The orchestrator side is verified separately: extract `jobs.<id>.needs` from refactored `pr-pipeline.yml` and confirm it matches the baseline `needs:` declaration for each job.
  - Evidence: `evidence/qa-gates/steps-byte-identity-diff.2026-05-18T10-15.md` with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:` ("17/17 callees match baseline; needs graph preserved on caller").

- [ ] [P6-T3] Verify orchestrator `uses:` targets resolve.
  - File touched: none.
  - Verification: parse `pr-pipeline.yml`, enumerate all `uses:` values, assert each `./.github/workflows/_*.yml` path exists on disk.
  - Evidence: `evidence/qa-gates/uses-resolution.2026-05-18T10-15.md`.

- [ ] [P6-T4] Verify `_stage-e2e-smoke.yml` declares all four Azure-related secrets and orchestrator forwards them.
  - File touched: none.
  - Verification: parse `_stage-e2e-smoke.yml`; assert `on.workflow_call.secrets` map contains `AZURE_TENANT_ID`, `AZURE_CLIENT_ID`, `AZURE_CLIENT_SECRET`, `E2E_API_BASE_URL`. Parse `pr-pipeline.yml`; assert `jobs.stage-e2e-smoke.secrets == inherit` (or an explicit map containing all four).
  - Evidence: `evidence/qa-gates/secrets-surface-verified.2026-05-18T10-15.md`.

- [ ] [P6-T5] Pester regression run (unchanged pass set).
  - File touched: none.
  - Verification: rerun the same Pester invocation captured in P0-T7. Compare pass/fail counts to the baseline; the post-refactor result must be `>=` baseline pass count with no new failures.
  - Evidence: `evidence/regression-testing/pester-postrefactor.2026-05-18T10-15.md` with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:` (baseline vs post counts).

- [ ] [P6-T6] Pytest regression run (unchanged pass set, or N/A note matching baseline).
  - File touched: none.
  - Verification: rerun the same pytest invocation captured in P0-T8. Pass/fail counts must match baseline.
  - Evidence: `evidence/regression-testing/pytest-postrefactor.2026-05-18T10-15.md`.

- [ ] [P6-T7] PSScriptAnalyzer post-refactor run.
  - File touched: none.
  - Verification: rerun P0-T9 command. Issue counts by severity must equal baseline (no new findings; refactor adds no PowerShell).
  - Evidence: `evidence/regression-testing/psscriptanalyzer-postrefactor.2026-05-18T10-15.md`.

- [ ] [P6-T8] Document the post-merge dispatch-verification commands (executed by maintainer after merge).
  - File touched: none (documentation evidence only).
  - Verification: enumerate the exact `gh` commands to be run after merge and the expected outputs:
    - `gh workflow run _stage-10-benchmark-regression.yml --ref <branch>` -> exactly one run id; one job; no `stage-7-integration` queued.
    - `gh workflow run _stage-1-format.yml --ref <branch>` -> one run id, one job, no other stages queued.
    - `gh workflow run pr-pipeline.yml --ref <branch>` -> orchestrator chains all 17 callees in expected `needs:` order; check names take the form `<caller-job-name> / <callee-job-name>`.
    - Synthetic failure (revert before merge): introduce a malformed `run:` line in `_stage-1-format.yml`; the orchestrator's check list surfaces the failure under the combined name.
  - Evidence: `evidence/qa-gates/dispatch-verification-plan.2026-05-18T10-15.md` with `Timestamp:`, `Command:` (the four `gh` invocations), `EXIT_CODE: planned-post-merge`, `Output Summary:` (expected outputs per scenario).

---

### Phase 7 — Acceptance-criteria sign-off

One task per AC1–AC10 from `user-story.md`. Each task references the evidence artifact that proves the AC.

- [ ] [P7-T1] AC1 verified: every inline job in pre-refactor `pr-pipeline.yml` has a corresponding `_*.yml` callee.
  - Verification: cross-reference `evidence/baseline/job-inventory.2026-05-18T10-15.md` (17 jobs) with files created in P2-T1..P2-T17 (17 callees).
  - Evidence: `evidence/qa-gates/ac1-extraction-complete.2026-05-18T10-15.md`.

- [ ] [P7-T2] AC2 verified: each `_*.yml` declares both `workflow_call:` and `workflow_dispatch:`.
  - Verification: parse each callee; assert both keys present under `on:`.
  - Evidence: `evidence/qa-gates/ac2-triggers-present.2026-05-18T10-15.md`.

- [ ] [P7-T3] AC3 verified: `pr-pipeline.yml` has no inline `steps:`; every job is a `uses:` block with `needs:`, `if:`, `secrets:` as applicable.
  - Verification: result from P3-T1 + P6-T3.
  - Evidence: `evidence/qa-gates/ac3-orchestrator-bodyless.2026-05-18T10-15.md`.

- [ ] [P7-T4] AC4 verified: step content is byte-identical to pre-refactor inline definitions.
  - Verification: result from P6-T2.
  - Evidence: `evidence/qa-gates/ac4-byte-identity.2026-05-18T10-15.md`.

- [ ] [P7-T5] AC5 documented: `gh workflow run _stage-10-benchmark-regression.yml --ref <branch>` runs only that stage.
  - Verification: post-merge dispatch — command and expected outcome documented in P6-T8.
  - Evidence: `evidence/qa-gates/ac5-isolated-dispatch-plan.2026-05-18T10-15.md` referencing P6-T8 (actual run id captured post-merge).

- [ ] [P7-T6] AC6 documented: representative-branch PR shows identical pass/fail outcome to pre-refactor.
  - Verification: post-merge — captured by the maintainer on the first representative PR; documented plan in P6-T8.
  - Evidence: `evidence/qa-gates/ac6-representative-pr-plan.2026-05-18T10-15.md` referencing P6-T8.

- [ ] [P7-T7] AC7 verified: the two duplicate mirror files are deleted.
  - Verification: results from P4-T1 and P4-T2; both files absent from `.github/workflows/`.
  - Evidence: `evidence/qa-gates/ac7-mirrors-deleted.2026-05-18T10-15.md`.

- [ ] [P7-T8] AC8 documented: branch-protection rename procedure is captured in `.github/workflows/README.md` and the PR description.
  - Verification: presence of the rename procedure section in `README.md` (from P5-T1) and a placeholder note that the PR description must include the same mapping.
  - Evidence: `evidence/qa-gates/ac8-branch-protection-procedure.2026-05-18T10-15.md`.

- [ ] [P7-T9] AC9 verified: `_stage-e2e-smoke.yml` declares its four secrets and the caller forwards them.
  - Verification: result from P6-T4.
  - Evidence: `evidence/qa-gates/ac9-secrets-surface.2026-05-18T10-15.md`.

- [ ] [P7-T10] AC10 verified: `.github/workflows/README.md` exists with convention, dispatch invocations, branch-protection rename, and secrets forwarding.
  - Verification: result from P5-T1.
  - Evidence: `evidence/qa-gates/ac10-readme-complete.2026-05-18T10-15.md`.

---

## Summary

- Phase count: 8 (Phase 0 through Phase 7).
- Task count: 50.
  - Phase 0: 9 (P0-T1..P0-T9)
  - Phase 1: 1 (P1-T1)
  - Phase 2: 17 (P2-T1..P2-T17)
  - Phase 3: 1 (P3-T1)
  - Phase 4: 2 (P4-T1..P4-T2)
  - Phase 5: 2 (P5-T1..P5-T2)
  - Phase 6: 8 (P6-T1..P6-T8)
  - Phase 7: 10 (P7-T1..P7-T10)

## Structural impossibilities detected during planning

None. Reading the current `.github/workflows/pr-pipeline.yml` confirms every job begins with `actions/checkout@v4`; there is no `download-artifact`, no `actions/cache` cross-job sharing, no `needs.*.outputs.*` cross-reference, and no shared working-tree reliance. The single `upload-artifact@v4` step in `stage-10-benchmark-regression` has no downstream `download-artifact` consumer, so it relocates verbatim into `_stage-10-benchmark-regression.yml` without requiring a new artifact contract. The spec's assertion that the refactor is pure relocation is confirmed. P1-T1 re-verifies this programmatically and will halt the execution path if a counter-example is found.
