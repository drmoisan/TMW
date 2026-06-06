# Policy Compliance Audit: iFile Message-Filing Dialog — Remediation Cycle 1 (#43)

**Audit Date:** 2026-06-04
**Code Under Test:** `src/taskpane/ifile/api-base-url.ts` (new), `src/taskpane/ifile/ifile.ts`, `src/taskpane/ifile/inline-host.ts`, `webpack.config.js` (build config), tests `tests/taskpane/ifile/api-base-url.test.ts` (new), `tests/taskpane/ifile/ifile.bootstrap.test.ts` (new), `tests/taskpane/ifile/ifile.host-shell.test.ts` (new), `tests/taskpane/ifile/inline-host.test.ts`, and doc `runbooks/outlook-on-device-verification.runbook.md`.

**Coverage Metrics by Language:**

| Language | Files Changed | Tests | Test Result | Baseline Coverage | Post-Change Coverage | New Code Coverage |
|----------|--------------|-------|-------------|-------------------|---------------------|-------------------|
| TypeScript | 3 prod + 4 test | 117 tests | ✅ 117 pass, 0 fail | 91.37% lines, 94.00% branches | 96.25% lines, 95.05% branches | api-base-url.ts 100% lines / 90.9% branches |

**Note:** This cycle changed only TypeScript production/test files, `webpack.config.js` (build config, not in coverage scope), and Markdown docs. C#, Python, and PowerShell have zero changed files this cycle (see Coverage Verification below).

### Coverage Evidence Checklist

- TypeScript baseline coverage artifact: `evidence/remediation-baseline/ts-test-coverage.md`
- TypeScript post-change coverage artifact: `evidence/qa-gates/final-ts-test-coverage.2026-06-04T17-50.md` and `evidence/qa-gates/final-coverage-delta.2026-06-04T17-50.md`
- PowerShell baseline coverage artifact: `N/A - zero changed files`
- PowerShell post-change coverage artifact: `N/A - zero changed files`
- Per-language comparison summary: section 1.2.1 below; reviewer-reproduced via `npm run test:coverage`

---

## Executive Summary

Remediation cycle 1 fixes a defect found in on-device verification (iFile search returned no matching folders, no error shown). The change is TypeScript-only: a new pure URL-reachability guard, a restructured `mountInline`, a split of `ifile.ts` into a testable `bootstrap` seam plus a thin `runBootstrap` shell, and a build-time mobile-build flag. All policy gates pass. The reviewer independently reproduced the full toolchain: format `--check` EXIT 0, lint EXIT 0, typecheck EXIT 0, depcruise EXIT 0 (0 errors, 6 pre-existing orphan warnings), test:coverage EXIT 0 with 117/117 tests passing.

**Policy documents evaluated:**
- ✅ `general-code-change.md`
- ✅ `general-unit-test.md` (incl. coverage-exclusion policy)

**Language-specific policies evaluated:**
- ✅ TypeScript: `typescript.md` + `typescript-suppressions.md`
- ✅ `architecture-boundaries.md` (No-COM), `quality-tiers.md`, `tonality.md`
- N/A Python, PowerShell, C# (zero changed files this cycle)

This cycle restored the runtime/wiring behavior backing AC-4, AC-5, and AC-8 on the real path (the host-bootstrap seam was previously coverage-excluded and could fail silently on device); the seam is now measured (0% -> 85.48% lines).

**Temporary artifacts cleanup:**
- ✅ No temporary/throwaway scripts were created during this cycle.
- ✅ All evidence is written to canonical `evidence/<kind>/` paths.

### Rejected Scope Narrowing

The remediation plan's "Languages in Scope" states C# is "not modified ... therefore no C# production/test changes and no C# QA loop are in scope this cycle." This is a factual statement that zero C# files changed this cycle, not an attempt to suppress a coverage verdict for a language with changed files; it is therefore a legitimate scope statement, not a rejected narrowing. The caller's out-of-scope note (README.md, Program.cs, csproj pre-existing; no workflow changes) is a factual pre-existing-state statement, confirmed below. No illegitimate scope narrowing was detected.

---

## 1. General Unit Test Policy Compliance

### 1.1 Core Principles

| Requirement | Status | Evidence |
|------------|--------|----------|
| **Independence** | ✅ PASS | Each test builds its own DOM via `makeDom()`/`installDom()`; `host-shell` resets globals in `afterEach` (`vi.restoreAllMocks`, `vi.unstubAllGlobals`). No shared mutable state. |
| **Isolation** | ✅ PASS | Each test targets one behavior (guard throws, error row rendered, handler bound, results render, selection posted). |
| **Fast Execution** | ✅ PASS | jsdom + awaited promises only; no waits. Full suite (26 files, 117 tests) runs in the standard Vitest pass. |
| **Determinism** | ✅ PASS | No `setTimeout`/`Date.now`/`Math.random`/wall-clock; fetch stubbed; no temp files. |
| **Readability & Maintainability** | ✅ PASS | Descriptive `it` names, labeled AAA sections, clear assertions. |

### 1.2 Coverage and Scenarios

| Requirement | Status | Evidence |
|------------|--------|----------|
| **Baseline Coverage Documented** | ✅ PASS | Baseline 91.37% lines / 94.00% branches (`evidence/remediation-baseline/ts-test-coverage.md`); `ifile.ts` baseline 0%. |
| **No Coverage Regression** | ✅ PASS | Post-change 96.25% lines / 95.05% branches (+4.88 / +1.05). `inline-host.ts` 96.29% -> 100%. No changed-line regression. |
| **New Code Coverage** | ✅ PASS | `api-base-url.ts` 100% lines / 90.9% branches; `ifile.ts` (modified) 85.48% / 94.11% — all above repo thresholds (line >= 85%, branch >= 75%). |
| **Comprehensive Coverage** | ✅ PASS | Guard: loopback variants + malformed-URL fallback. Wiring: token failure, load failure, URL-guard rejection, missing DOM, positive path, selection posting. |
| **Positive Flows** | ✅ PASS | Token+load success renders a result row (`ifile.bootstrap.test.ts`, `inline-host.test.ts`, `ifile.host-shell.test.ts`). |
| **Negative Flows** | ✅ PASS | Token failure, load failure, URL-guard rejection, missing DOM all covered. |
| **Edge Cases** | ✅ PASS | `127.0.0.1`, `[::1]`, malformed loopback and malformed non-loopback URLs. |
| **Error Handling** | ✅ PASS | Visible error row asserted on every failure branch; guard throws a specific error. |
| **Concurrency** | N/A | No concurrency in scope. |
| **State Transitions** | ✅ PASS | Empty-state -> error-state and empty-state -> results transitions asserted. |

### 1.2.1 Per-Language Coverage Comparison

- TypeScript: Baseline: 91.37% lines (94.00% branches) -> Post-change: 96.25% lines (95.05% branches). Change: +4.88% lines (+1.05% branches). New/changed-code coverage: 85.48% lines (new file `api-base-url.ts` 100% lines / 90.9% branches; modified `ifile.ts` 85.48% lines / 94.11% branches; modified `inline-host.ts` 100% lines / 100% branches). Disposition: PASS. Evidence: `evidence/qa-gates/final-ts-test-coverage.2026-06-04T17-50.md`, `evidence/qa-gates/final-coverage-delta.2026-06-04T17-50.md`, reviewer-run `npm run test:coverage`.
- C#: N/A - zero changed files this cycle (backend unchanged; audited in prior cycle).
- PowerShell / Python: N/A - zero changed files on branch.

### 1.3 Test Structure and Diagnostics

| Requirement | Status | Evidence |
|------------|--------|----------|
| **Clear Failure Messages** | ✅ PASS | Marker-attribute, call-count, and rendered-text assertions localize failures. |
| **Arrange-Act-Assert Pattern** | ✅ PASS | AAA sections labeled in the new/modified tests. |
| **Document Intent** | ✅ PASS | Descriptive `it` names + file-level docstrings. |

### 1.4 External Dependencies and Environment

| Requirement | Status | Evidence |
|------------|--------|----------|
| **Avoid External Dependencies** | ✅ PASS | No network/DB/process; fetch stubbed; jsdom only. |
| **Use Mocks/Stubs** | ✅ PASS | Office fake, stubbed fetch, injected `acquireToken`/`loadLeaves`. |
| **Environment Stability** | ✅ PASS | No temp files; globals reset in `afterEach`; no prohibited temporary file creation. |

### 1.5 Policy Audit Requirement

| Requirement | Status | Evidence |
|------------|--------|----------|
| **Pre-submission Review** | ✅ PASS | This audit is the required review. |

---

## 2. General Code Change Policy Compliance

### 2.1 Before Making Changes

| Requirement | Status | Evidence |
|------------|--------|----------|
| **Clarify the objective** | ✅ PASS | `remediation-inputs.2026-06-04T17-50.md` defines the defect and exit criteria. |
| **Read existing change plans** | ✅ PASS | `remediation-plan.2026-06-04T17-50.md` (24/24 tasks checked). |
| **Document the plan** | ✅ PASS | Plan + evidence under `evidence/`. |

### 2.2 Design Principles

| Requirement | Status | Evidence |
|------------|--------|----------|
| **Simplicity first** | ✅ PASS | Minimal guard module; `mountInline` restructure binds handler before load; no over-engineering. |
| **Reusability** | ✅ PASS | `renderLoadError` and the `bootstrap` seam are reused across the inline and shell paths. |
| **Extensibility** | ✅ PASS | `BootstrapDeps` injection keeps `bootstrap` Office-free and testable. |
| **Separation of concerns** | ✅ PASS | Pure guard / host-neutral wiring / thin host-bound shell are cleanly separated. |

### 2.3 Module & File Structure

| Requirement | Status | Evidence |
|------------|--------|----------|
| **Cohesive modules** | ✅ PASS | Each module has a single clear responsibility. |
| **Under 500 lines** | ✅ PASS | `ifile.ts` 153, `api-base-url.ts` 61, `inline-host.ts` 92; tests 64/93/149/150. |
| **Public vs internal** | ✅ PASS | Exported seams typed; host registration guarded. |
| **No circular dependencies** | ✅ PASS | `depcruise` EXIT 0, 0 errors. |

### 2.4 Naming, Docs, and Comments

| Requirement | Status | Evidence |
|------------|--------|----------|
| **Descriptive names** | ✅ PASS | `assertReachableApiBaseUrl`, `renderLoadError`, `runBootstrap`, `BootstrapDeps`. |
| **Docs/docstrings** | ✅ PASS | Each exported symbol carries a precise doc comment. |
| **Comment why, not what** | ✅ PASS | Comments explain the device-reachability rationale and the handler-before-load ordering. |

### 2.5 After Making Changes - Toolchain Execution

| Requirement | Status | Evidence |
|------------|--------|----------|
| **1. Formatting** | ✅ PASS | `npm run format -- --check` EXIT 0 ("All matched files use Prettier code style"). |
| **2. Linting** | ✅ PASS | `npm run lint` EXIT 0. |
| **3. Type checking** | ✅ PASS | `npm run typecheck` EXIT 0. |
| **4. Testing** | ✅ PASS | `npm run test:coverage` EXIT 0, 117/117. |
| **Full toolchain loop** | ✅ PASS | Reviewer reproduced all stages green in a single pass; depcruise EXIT 0. |
| **Explicit reporting** | ✅ PASS | Commands and results recorded here and in `evidence/qa-gates/`. |

### 2.6 Summarize and Document

| Requirement | Status | Evidence |
|------------|--------|----------|
| **Summarize changes** | ✅ PASS | See Executive Summary and code-review artifact. |
| **Design choices explained** | ✅ PASS | Doc comments + runbook Section 0. |
| **Update supporting documents** | ✅ PASS | `runbooks/outlook-on-device-verification.runbook.md` updated (build step + HI-2 restatement). |
| **Provide next steps** | ✅ PASS | HI-2 on-device confirmation is the remaining feature-DONE gate. |

---

## 3. Language-Specific Code Change Policy Compliance

### Section 3-TS: TypeScript Code Change Policy Compliance

#### Tooling & Baseline

| Requirement | Status | Evidence |
|------------|--------|----------|
| **Formatting (Prettier)** | ✅ PASS | `npm run format -- --check` EXIT 0. |
| **Linting (ESLint)** | ✅ PASS | `npm run lint` EXIT 0. |
| **Type checking (TSC)** | ✅ PASS | `npm run typecheck` EXIT 0. |
| **Testing (Vitest)** | ✅ PASS | `npm run test:coverage` EXIT 0, 117/117. |

#### Design & Typing

| Requirement | Status | Evidence |
|------------|--------|----------|
| **Strong typing / no `any`** | ✅ PASS | Exported seams typed; `catch (error: unknown)` without unsafe narrowing. |
| **ES modules** | ✅ PASS | Import/export syntax only; no CommonJS in source. |
| **Domain types / interfaces** | ✅ PASS | `BootstrapDeps`, `ApiBaseUrlGuardOptions`, `InlineHostDom`. |
| **Naming / kebab-case files** | ✅ PASS | `api-base-url.ts`; camelCase locals, PascalCase types. |
| **Separation of host-bound logic** | ✅ PASS | Pure guard isolated; `bootstrap` is Office-free. |

#### Error Handling

| Requirement | Status | Evidence |
|------------|--------|----------|
| **Fail fast / explicit errors** | ✅ PASS | Guard throws a specific Error; failures render a visible state. |
| **No silent catch-all** | ✅ PASS | Only the missing-DOM path logs (no DOM to render into); all others surface visibly. |
| **No new runtime dependencies** | ✅ PASS | None added. |

#### Suppression Policy (`typescript-suppressions.md`)

| Requirement | Status | Evidence |
|------------|--------|----------|
| **No unauthorized suppressions** | ✅ PASS | No `eslint-disable`, `@ts-expect-error`, `@ts-ignore`, or `@ts-nocheck` introduced in any changed file. |

---

## 4. Language-Specific Unit Test Policy Compliance

### Section 4-TS: TypeScript Unit Test Policy Compliance

| Requirement | Status | Evidence |
|------------|--------|----------|
| **Use Vitest** | ✅ PASS | All tests use Vitest; `*.test.ts` naming. |
| **No Outlook host runtime** | ✅ PASS | Office fake / jsdom; the `bootstrap` seam is Office-free. |
| **Test file location mirrors src** | ✅ PASS | `tests/taskpane/ifile/**` mirrors `src/taskpane/ifile/**`; no colocation. |
| **AAA / single behavior** | ✅ PASS | Labeled AAA, one behavior per test. |
| **Mock reset** | ✅ PASS | `vi.restoreAllMocks()` / `vi.unstubAllGlobals()` in `afterEach` (host-shell). |
| **No external dependencies / temp files** | ✅ PASS | Stubbed fetch; jsdom only; no temp files. |
| **Coverage thresholds (uniform)** | ✅ PASS | Repo-wide and changed/new files above line >= 85% / branch >= 75%. |

---

## 5. Test Coverage Detail

### api-base-url.ts (`assertReachableApiBaseUrl`) — 6 tests

| Test Name | Scenario Type | Status |
|-----------|--------------|--------|
| throws for localhost on mobile build | Negative | ✅ |
| returns non-localhost URL unchanged on mobile | Positive | ✅ |
| returns localhost unchanged on desktop | Positive | ✅ |
| throws for 127.0.0.1 and `[::1]` on mobile | Edge Case | ✅ |
| fails closed for malformed loopback URL (fallback) | Edge Case | ✅ |
| returns malformed non-loopback URL unchanged (fallback) | Edge Case | ✅ |

**Coverage:** 100% lines / 90.9% branches. Not covered: line 35 (`?? withoutScheme` defensive fallback, unreachable with valid string input).

### ifile.ts (`bootstrap`, `runBootstrap`) — bootstrap (3) + host-shell (4) tests

| Test Name | Scenario Type | Status |
|-----------|--------------|--------|
| bind handler + visible error on token failure | Error Handling | ✅ |
| bind handler + visible error on load failure | Error Handling | ✅ |
| render results on input when token+load succeed | Positive | ✅ |
| log + return when host DOM missing | Negative | ✅ |
| visible error + responsive box when URL guard rejects | Error Handling | ✅ |
| load folders + render results on reachable desktop build | Positive | ✅ |
| post selection to parent in dialog presentation | Positive | ✅ |

**Coverage:** 85.48% lines / 94.11% branches (baseline 0%). Not covered: lines 141-149 (host-only `Office.onReady` registration, cannot execute under the test runtime; intentionally not excluded).

### inline-host.ts (`renderResults`, `mountInline`, `renderLoadError`) — extended

| Test Name | Scenario Type | Status |
|-----------|--------------|--------|
| load once + render results on input | Positive | ✅ |
| responsive box + visible error on failed load | Error Handling | ✅ |
| error row distinct from result row | Edge Case | ✅ |
| positive path preserved on successful load | Positive | ✅ |
| renderLoadError renders single distinct alert row | Edge Case | ✅ |

**Coverage:** 100% lines / 100% branches (baseline 96.29% / 100%).

---

## 6. Test Execution Metrics

| Metric | Value | Status |
|--------|-------|--------|
| Total Tests | 117 | ✅ |
| Tests Passed | 117 (100%) | ✅ |
| Tests Failed | 0 | ✅ |
| Test Files | 26 | ✅ |
| Code Coverage | 96.25% lines, 95.05% branches | ✅ |

---

## 7. Code Quality Checks

**For TypeScript:**

| Check | Command | Result | Status |
|-------|---------|--------|--------|
| Prettier Formatting | `npm run format -- --check` | All matched files use Prettier code style | ✅ |
| ESLint Linting | `npm run lint` | 0 errors | ✅ |
| TSC Type Checking | `npm run typecheck` | 0 errors | ✅ |
| dependency-cruiser | `npm run depcruise` | 0 errors, 6 pre-existing orphan warnings | ✅ |
| Vitest + Coverage | `npm run test:coverage` | 117/117 pass, thresholds met | ✅ |

**Notes:** The 6 `no-orphans` warnings (taskpane.ts, folder-result.ts, archive-root-picker.ts, classifier-client.ts, commands.ts, v1.ts) are pre-existing and unrelated to this cycle. No `.github/workflows/**` file changed this cycle (verified `git diff --name-only -- .github/workflows/` is empty), so `modified-workflow-needs-green-run` does not trigger; `webpack.config.js` is build config, not a CI workflow.

### Architecture Boundaries (No-COM) — PASS

`depcruise` EXIT 0, 0 errors. `api-base-url.ts` is pure (no Office.js/Graph/fetch), satisfying `ifile-pure-modules-no-host-deps`. Mailbox access remains via Office.js only; business logic host-neutral; UI is web UI.

### Quality Tiers — PASS

Uniform coverage thresholds (line >= 85%, branch >= 75%) met on all changed/new files and repo-wide. iFile modules are T2; no tier-specific lower floor applied. No new project introduced (no `quality-tiers.yml` change needed this cycle).

### Coverage-Exclusion Policy — PASS

`vitest.config.ts` `coverage.exclude` contains only non-production paths (`node_modules/**`, `dist/**`, `lib/**`, `lib-amd/**`, `**/*.test.ts`, `src/test-support/**`, and config files). No `src/` production path is excluded. The previously-excluded host-bootstrap seam is now measured (0% -> 85.48%).

### Evidence Location Compliance — PASS

All cycle evidence is under the canonical `docs/features/active/2026-05-31-ifile-message-filing-dialog-43/evidence/<kind>/` paths. A scan of the diff and working tree for files under `artifacts/baselines/`, `artifacts/qa/`, `artifacts/coverage/`, or `artifacts/evidence/` found zero occurrences. The repo does not contain `scripts/validate_evidence_locations.py`; the scan was performed via `git diff`/`git status` path matching and returned no non-canonical paths. No `EVIDENCE_LOCATION_OVERRIDE_REJECTED` events occurred.

### Tonality — PASS

Code comments, runbook, and evidence use professional, factual language. No humor, hyperbole, or decorative metaphor in the changed files.

### Autonomous-Execution Mandate (#45) — PASS

HI-2 remains the single declared exception (runbook restates response `exception`, "gates feature DONE but not cycle exit"). The build-with-reachable-URL step is documented (runbook Section 0). No undeclared manual dependency: the code-and-test changes are fully automatable and CI-verified.

---

## 8. Gaps and Exceptions

### Identified Gaps
**None.** All policy requirements are met.

### Approved Exceptions
- HI-2 (on-device visual/end-to-end confirmation): declared human-interaction exception under the autonomous-execution mandate (#45), recorded in `runbooks/outlook-on-device-verification.runbook.md`. Gates feature DONE, not cycle exit.

### Removed/Skipped Tests
**None.** All planned tests implemented. P4-T2 (token-path alignment) was OUT_OF_SCOPE_DEFERRED per the plan's guarded investigation (`evidence/regression-testing/od8-token-path-investigation.2026-06-04T17-50.md`).

---

## 9. Summary of Changes

### Files Modified (cycle 1)

1. **src/taskpane/ifile/api-base-url.ts** (NEW) — pure URL-reachability guard.
2. **src/taskpane/ifile/ifile.ts** (MODIFIED) — split into `bootstrap` seam + thin `runBootstrap` shell; visible error routing.
3. **src/taskpane/ifile/inline-host.ts** (MODIFIED) — handler-before-load restructure; `renderLoadError`.
4. **webpack.config.js** (MODIFIED) — `__IS_MOBILE_BUILD__` flag + documented mobile build requirement.
5. **tests/taskpane/ifile/{api-base-url,ifile.bootstrap,ifile.host-shell}.test.ts** (NEW) and **inline-host.test.ts** (MODIFIED).
6. **runbooks/outlook-on-device-verification.runbook.md** (MODIFIED) — build step + HI-2 restatement.

Pre-existing working-tree changes not attributed to this cycle: `README.md`, `src/TaskMaster.Api/Program.cs`, `src/TaskMaster.Api/TaskMaster.Api.csproj`.

---

## 10. Compliance Verdict

### Overall Status: ✅ FULLY COMPLIANT

All evaluated policies pass with reviewer-reproduced toolchain evidence and complete coverage metrics. No required baseline, QA, or coverage-comparison artifact is missing.

### Policy-by-Policy Summary

#### General Code Change Policy (Section 2)
- ✅ Before Making Changes, Design Principles, Module & File Structure, Naming/Docs/Comments, Toolchain Execution, Summarize & Document.

#### Language-Specific Code Change Policy (Section 3)
- ✅ TypeScript Tooling & Baseline, Design & Typing, Error Handling, Suppression Policy.

#### General Unit Test Policy (Section 1)
- ✅ Core Principles, Coverage & Scenarios, Test Structure, External Dependencies, Policy Audit.

#### Language-Specific Unit Test Policy (Section 4)
- ✅ TypeScript Framework & Scope, Test Style & Structure, Naming & Readability, Toolchain.

### Metrics Summary

- ✅ 117/117 tests passing (100%)
- ✅ 96.25% line coverage / 95.05% branch coverage repo-wide
- ✅ Host-bootstrap seam recovered: `ifile.ts` 0% -> 85.48% lines
- ✅ All code quality checks passing (format/lint/typecheck/depcruise/test)

### Recommendation

**Ready for merge** (cycle exit). The remaining feature-DONE gate is the HI-2 on-device confirmation, which is a declared exception and does not block cycle exit.

**FAIL findings: 0. Blocking-PARTIAL findings: 0.**

---

**Audit Completed By:** feature-review
**Audit Date:** 2026-06-04
**Policy Version:** Current (as of audit date)

---

## Appendix A: Test Inventory

TypeScript (Vitest), iFile cycle-1 tests:

- `api-base-url.test.ts` › assertReachableApiBaseUrl › throws for a localhost URL when the build is a mobile build
- `api-base-url.test.ts` › assertReachableApiBaseUrl › returns the URL unchanged for a non-localhost host on a mobile build
- `api-base-url.test.ts` › assertReachableApiBaseUrl › returns a localhost URL unchanged for a non-mobile (desktop) build
- `api-base-url.test.ts` › assertReachableApiBaseUrl › throws for the 127.0.0.1 and IPv6 loopback hosts on a mobile build
- `api-base-url.test.ts` › assertReachableApiBaseUrl › fails closed for a malformed URL whose host token is loopback (fallback path)
- `api-base-url.test.ts` › assertReachableApiBaseUrl › returns a malformed non-loopback URL unchanged on a mobile build (fallback, non-loopback)
- `ifile.bootstrap.test.ts` › ifile bootstrap — resilient wiring › binds the input handler and surfaces a visible error when token acquisition fails
- `ifile.bootstrap.test.ts` › ifile bootstrap — resilient wiring › binds the input handler and surfaces a visible error when the one-time load fails
- `ifile.bootstrap.test.ts` › ifile bootstrap — resilient wiring › renders results on input when token and load both succeed (positive path)
- `ifile.host-shell.test.ts` › ifile runBootstrap host shell › logs and returns without throwing when the host DOM is missing
- `ifile.host-shell.test.ts` › ifile runBootstrap host shell › renders a visible error and keeps the box responsive when the URL guard rejects
- `ifile.host-shell.test.ts` › ifile runBootstrap host shell › loads folders and renders results on input for a reachable desktop build
- `ifile.host-shell.test.ts` › ifile runBootstrap host shell › posts the selection to the parent in the dialog presentation on row click
- `inline-host.test.ts` › inline-host renderResults › renders one row per result with the folder id and a click handler
- `inline-host.test.ts` › inline-host renderResults › clears prior rows on re-render
- `inline-host.test.ts` › inline-host mountInline › loads the folder list once and renders results on input
- `inline-host.test.ts` › inline-host mountInline › keeps the box responsive and shows a visible error state when the one-time load fails
- `inline-host.test.ts` › inline-host mountInline › renders an error row that is distinct from a normal result row
- `inline-host.test.ts` › inline-host mountInline › renders results on input when the load succeeds (positive path preserved)
- `inline-host.test.ts` › inline-host renderLoadError › renders a single distinct alert row with the given message

Full suite: 26 test files, 117 tests, all passing.

---

## Appendix B: Toolchain Commands Reference

**For TypeScript:**

```bash
# Formatting
npm run format -- --check

# Linting
npm run lint

# Type checking
npm run typecheck

# Architecture boundaries
npm run depcruise

# Testing + coverage
npm run test:coverage
```
