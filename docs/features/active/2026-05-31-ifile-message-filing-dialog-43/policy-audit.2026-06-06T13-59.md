# Policy Compliance Audit: iFile Message-Filing Dialog — Cycle 4 Reaudit (#43)

**Audit Date:** 2026-06-06
**Code Under Test:** `src/taskpane/ifile/naa-token-acquirer.ts`, `tests/taskpane/ifile/naa-token-acquirer.test.ts`, `manifest.json`, `manifest.xml`, `docs/features/active/2026-05-31-ifile-message-filing-dialog-43/runbooks/entra-app-sso-config.runbook.md`, `docs/features/active/2026-05-31-ifile-message-filing-dialog-43/runbooks/outlook-on-device-verification.runbook.md`

**Coverage Metrics by Language:**

| Language | Files Changed | Tests | Test Result | Baseline Coverage | Post-Change Coverage | New Code Coverage |
|----------|--------------|-------|-------------|-------------------|---------------------|-------------------|
| TypeScript | 2 files (1 src, 1 test) | 163 tests | ✅ 163 pass, 0 fail | 95.45% lines, 92.43% branch | 95.47% lines, 92.49% branch | 98.27% lines on changed file (no new file added this cycle) |
| JSON | 1 file (`manifest.json`) | N/A | ✅ validation | N/A (config) | N/A (config) | N/A |
| XML | 1 file (`manifest.xml`) | N/A | ✅ validation | N/A (config) | N/A (config) | N/A |

**Note:** Only TypeScript has changed source/test files with coverage requirements this cycle. No Python, PowerShell, or C# production file changed in the cycle-4 diff (verified — see Evidence rule below).

### Coverage Evidence Checklist

- TypeScript baseline coverage artifact: `docs/features/active/2026-05-31-ifile-message-filing-dialog-43/evidence/remediation-baseline/ts-test-coverage.2026-06-06T13-42.md`
- TypeScript post-change coverage artifact: `docs/features/active/2026-05-31-ifile-message-filing-dialog-43/evidence/qa-gates/final-ts-test-coverage.2026-06-06T13-42.md`
- PowerShell baseline coverage artifact: `N/A - out of scope` (no PowerShell file changed this cycle)
- PowerShell post-change coverage artifact: `N/A - out of scope` (no PowerShell file changed this cycle)
- Per-language comparison summary: Section 1.2.1

**Non-negotiable verdict rule:** Numeric baseline and post-change coverage are present for the one in-scope language (TypeScript). PASS is permitted.

**Fail-closed rule:** All required baseline, QA, and coverage-comparison artifacts are present.

**Evidence rule:** No audit evidence was synthesized. C#/Python/PowerShell are out of scope because the cycle-4 diff has zero changed files in those languages (`git diff --name-only HEAD` for the cycle-4 targets contains only `.ts`, `.json`, `.xml`, and `.md` files).

---

## Executive Summary

Cycle 4 realigns the in-repo iFile authentication chain onto the user-configured Entra app `3592bf52-46f6-4eb0-835c-4f961058de97`, replacing the prior `2921bc0b-...` whose registration lacked the matching NAA SPA redirect (the root cause of the Outlook iOS pre-AAD broker rejection). The cycle also reverts a temporary on-device PII diagnostic (restoring `piiLoggingEnabled: false` and the `if (containsPii) { return; }` guard) and realigns two operational runbooks. The change is TypeScript + manifest-config only; no backend C# production change was required and none was made.

The full seven-stage TypeScript toolchain was re-run independently for this audit and passes clean: format (`src/**/*.ts`), lint, type-check, dependency-cruiser (0 errors, MSAL import boundary intact), vitest + coverage (163 tests, no regression), and both manifest validations. No secret value entered the repository, and no immutable historical/audit artifact was rewritten.

**Policy documents evaluated:**
- ✅ `general-code-change.md`
- ✅ `general-unit-test.md`
- ✅ `quality-tiers.md` (uniform coverage thresholds: line >= 85%, branch >= 75%)

**Language-specific policies evaluated:**
- N/A `python.md`
- N/A `powershell.md`
- ✅ `typescript.md` + `typescript-suppressions.md`
- N/A `csharp.md`

**Temporary artifacts cleanup:**
- ✅ All temporary `DIAGNOSTIC ONLY` / `REVERT before release` markers were removed from `naa-token-acquirer.ts` and its test (the cycle's explicit revert objective).
- ✅ No throwaway scripts were created by this audit; all checks used repo-defined `npm` scripts.

---

## Rejected Scope Narrowing

None. The caller prompt scoped this reaudit to the cycle-4 working-tree diff against the branch head and did not attempt to narrow the audit to a subset of changed files, to mark any language with changed files as out of scope, or to skip a required toolchain/coverage check for such a language. The audit was performed against the full cycle-4 diff. The pre-existing uncommitted working state (MSAL log-capture subsystem and other untracked files) was correctly identified by the caller as prior state, not a cycle-4 product; treating it as out of cycle-4 scope is consistent with the working-tree baseline and is not a rejected narrowing.

---

## Evidence Location Compliance

All evidence artifacts produced for cycle 4 are written under the canonical `docs/features/active/2026-05-31-ifile-message-filing-dialog-43/evidence/<kind>/` path (subfolders `remediation-baseline/`, `qa-gates/`, `other/`). A scan of the working tree for evidence written under non-canonical paths (`artifacts/baselines/`, `artifacts/qa/`, `artifacts/evidence/`, `artifacts/coverage/`) found no such directories. No `EVIDENCE_LOCATION_OVERRIDE_REJECTED` condition arose.

- Non-canonical evidence directories present: none.
- Cycle-4 evidence files outside the canonical path: none (verified via `git status` filtered on the `2026-06-06T13-42` evidence timestamp).
- The repo `scripts/validate_evidence_locations.py` referenced by policy was not present at that path in this checkout; the manual scan above substitutes and is recorded as the evidence. No FAIL-level evidence-location finding.

---

## 1. General Unit Test Policy Compliance

### 1.1 Core Principles

| Requirement | Status | Evidence |
|------------|--------|----------|
| **Independence** | ✅ PASS | The cycle-4 tests drive the logger seam via injected `logCapture`; no shared mutable state across tests. Full suite passes in a single run. |
| **Isolation** | ✅ PASS | Each new/updated test targets one behavior: clientId value, PII-skip true path, PII-skip false path, `loggerOptions` shape. |
| **Fast Execution** | ✅ PASS | Pure unit suite (29 files, 163 tests); no integration latency, timers, or network. |
| **Determinism** | ✅ PASS | No wall-clock, RNG, or external I/O in the changed tests; the logger callback is invoked directly with fixed inputs. |
| **Readability & Maintainability** | ✅ PASS | Descriptive `it(...)` names and Arrange/Act/Assert comments; assertions are specific (exact drained arrays, exact clientId string). |

### 1.2 Coverage and Scenarios

| Requirement | Status | Evidence |
|------------|--------|----------|
| **Baseline Coverage Documented** | ✅ PASS | Baseline 95.45% lines / 92.43% branch. Command `npm run test:coverage`. Artifact `evidence/remediation-baseline/ts-test-coverage.2026-06-06T13-42.md`. |
| **No Coverage Regression** | ✅ PASS | Post-change 95.47% lines / 92.49% branch. Change +0.02% lines / +0.06% branch. No regression. `naa-token-acquirer.ts` branch coverage rose 95.00% → 95.23%. |
| **New Code Coverage** | ✅ PASS | No new file was added this cycle. The changed file `naa-token-acquirer.ts` is at 98.27% lines / 95.23% branch, above the uniform thresholds (line >= 85%, branch >= 75%). |
| **Comprehensive Coverage** | ✅ PASS | The reinstated `if (containsPii) { return; }` branch is exercised on both true and false paths by restored PII-skip tests. |
| **Positive Flows** | ✅ PASS | Non-PII Warning/Error retained; clientId resolves to the new value. |
| **Negative Flows** | ✅ PASS | PII-flagged message excluded; Info/Verbose dropped. |
| **Edge Cases** | ✅ PASS | Same-level PII vs non-PII discrimination at Warning level. |
| **Error Handling** | ✅ PASS | `attachMsalLog` propagation on silent and popup failure remains covered (prior-state behavior, unchanged). |
| **Concurrency** | N/A | No concurrency in the changed surface. |
| **State Transitions** | N/A | No stateful transitions in the changed surface. |

### 1.2.1 Per-Language Coverage Comparison

- TypeScript: Baseline: 95.45% lines -> Post-change: 95.47% lines. Change: +0.02% lines (+0.06% branch). New/changed-code coverage: 98.27% lines / 95.23% branch on `naa-token-acquirer.ts` (no new file). Disposition: PASS. Evidence: `evidence/remediation-baseline/ts-test-coverage.2026-06-06T13-42.md`, `evidence/qa-gates/final-ts-test-coverage.2026-06-06T13-42.md`, `evidence/qa-gates/final-coverage-delta.2026-06-06T13-42.md`.
- PowerShell: Baseline: N/A - out of scope -> Post-change: N/A - out of scope. Change: N/A. New/changed-code coverage: N/A - out of scope. Disposition: N/A. Evidence: no PowerShell file changed in the cycle-4 diff.
- C#: Baseline: N/A - out of scope -> Post-change: N/A - out of scope. Change: N/A. New/changed-code coverage: N/A - out of scope. Disposition: N/A. Evidence: no C# file changed in the cycle-4 diff (backend verification artifact `evidence/other/backend-verification.2026-06-06T13-42.md`).

### 1.3 Test Structure and Diagnostics

| Requirement | Status | Evidence |
|------------|--------|----------|
| **Clear Failure Messages** | ✅ PASS | Assertions compare exact drained-message arrays and the exact clientId string, localizing failures. |
| **Arrange-Act-Assert Pattern** | ✅ PASS | Changed tests carry explicit Arrange/Act/Assert comments. |
| **Document Intent** | ✅ PASS | Test names state the scenario (PII-flagged excluded, non-PII retained, PII logging disabled). |

### 1.4 External Dependencies and Environment

| Requirement | Status | Evidence |
|------------|--------|----------|
| **Avoid External Dependencies** | ✅ PASS | No DB/network/filesystem; MSAL is exercised only through the injected seam. |
| **Use Mocks/Stubs** | ✅ PASS | The logger callback and capture buffer are driven directly; no real MSAL `Logger` is constructed. |
| **Environment Stability** | ✅ PASS | No temporary files; no mutable global state. |

### 1.5 Policy Audit Requirement

| Requirement | Status | Evidence |
|------------|--------|----------|
| **Pre-submission Review** | ✅ PASS | This audit constitutes the required cycle-4 policy review. |

---

## 2. General Code Change Policy Compliance

### 2.1 Before Making Changes

| Requirement | Status | Evidence |
|------------|--------|----------|
| **Clarify the objective** | ✅ PASS | Objective fixed by scope contract `remediation-inputs.2026-06-06T13-42.md` (client-ID/app realignment + PII revert). |
| **Read existing change plans** | ✅ PASS | Executed plan `remediation-plan.2026-06-06T13-42.md` (Phases 0–6, all tasks checked with evidence). |
| **Document the plan** | ✅ PASS | Plan and per-phase evidence artifacts present under `evidence/`. |

### 2.2 Design Principles

| Requirement | Status | Evidence |
|------------|--------|----------|
| **Simplicity first** | ✅ PASS | Single-source `CLIENT_ID` constant; minimal guard reinstatement. |
| **Reusability** | ✅ PASS | No duplication; the manifest values mirror the single non-secret identifier. |
| **Extensibility** | ✅ PASS | `logCapture` remains injectable; the seam is preserved. |
| **Separation of concerns** | ✅ PASS | MSAL-bound logic stays in `naa-token-acquirer.ts`; the bootstrap path stays MSAL-free (depcruise enforced). |

### 2.3 Module & File Structure

| Requirement | Status | Evidence |
|------------|--------|----------|
| **Cohesive modules** | ✅ PASS | The auth adapter remains the single MSAL-bound module. |
| **Under 500 lines** | ✅ PASS | `naa-token-acquirer.ts` remains within the 500-line limit. |
| **Public vs internal** | ✅ PASS | No new public API introduced by cycle 4. |
| **No circular dependencies** | ✅ PASS | `npm run depcruise` → 0 errors. |

### 2.4 Naming, Docs, and Comments

| Requirement | Status | Evidence |
|------------|--------|----------|
| **Descriptive names** | ✅ PASS | `containsPii`, `CLIENT_ID`, `loggerOptions` are descriptive. |
| **Docs/docstrings** | ✅ PASS | The non-secret nature of the client ID is documented at the constant. |
| **Comment why, not what** | ✅ PASS | Temporary diagnostic comments were removed; remaining comments explain rationale. |

### 2.5 After Making Changes - Toolchain Execution

| Requirement | Status | Evidence |
|------------|--------|----------|
| **1. Formatting** | ✅ PASS | `npm run format:check` (`prettier --check "src/**/*.ts"`) → "All matched files use Prettier code style!", exit 0. |
| **2. Linting** | ✅ PASS | `npm run lint` (`office-addin-lint check`) → exit 0, no findings. |
| **3. Type checking** | ✅ PASS | `npm run typecheck` (`tsc --noEmit`) → exit 0, 0 errors. |
| **4. Architecture-boundary** | ✅ PASS | `npm run depcruise` → 0 errors (6 pre-existing `warn` no-orphans); MSAL import boundary intact. |
| **5. Testing** | ✅ PASS | `npm run test:coverage` → 163 tests pass, exit 0. |
| **6. Contract / manifest** | ✅ PASS | `npm run validate` and `npm run validate:xml` → both exit 0, "The manifest is valid." |
| **Full toolchain loop** | ✅ PASS | All stages pass in a single pass; independently reproduced for this audit. |
| **Explicit reporting** | ✅ PASS | Commands and results recorded in `evidence/qa-gates/final-ts-*.md` and reproduced here. |

### 2.6 Summarize and Document

| Requirement | Status | Evidence |
|------------|--------|----------|
| **Summarize changes** | ✅ PASS | Summarized in the code-review and this audit. |
| **Design choices explained** | ✅ PASS | App-realignment rationale documented in the scope contract. |
| **Update supporting documents** | ✅ PASS | Two runbooks realigned to the new client ID / App ID URI. |
| **Provide next steps** | ✅ PASS | HI-1/HI-2/HI-3 follow-ups stated. |

---

## 3. Language-Specific Code Change Policy Compliance

### Section 3 (TypeScript) — `typescript.md` + `typescript-suppressions.md`

| Requirement | Status | Evidence |
|------------|--------|----------|
| **Prettier formatting** | ✅ PASS | `npm run format:check` clean on `src/**/*.ts`. |
| **ESLint clean** | ✅ PASS | `office-addin-lint check` exit 0. |
| **Strict typing, no new `any`** | ✅ PASS | `tsc --noEmit` exit 0; no `any` introduced by cycle 4 (T3 adapter; untyped-escape budget not exercised). |
| **Suppressions** | ✅ PASS | No new `eslint-disable` / `@ts-expect-error` introduced by cycle 4. |

Python, PowerShell, Bash, JSON-schema, and C# code-change sections are not applicable: no files in those languages changed in the cycle-4 diff. (`manifest.json` / `manifest.xml` are validated as Office manifests via `office-addin-manifest`, recorded under stage 6 above.)

---

## 4. Language-Specific Unit Test Policy Compliance

### Section 4 (TypeScript / Vitest)

| Requirement | Status | Evidence |
|------------|--------|----------|
| **Use Vitest** | ✅ PASS | `vitest run --coverage`; 29 files, 163 tests. |
| **Coverage expectation** | ✅ PASS | All-files 95.47% lines / 92.49% branch; changed file 98.27% / 95.23% — above uniform thresholds. |
| **Test file location mirrors source** | ✅ PASS | `tests/taskpane/ifile/naa-token-acquirer.test.ts` mirrors `src/taskpane/ifile/naa-token-acquirer.ts`. |
| **No alternative runners** | ✅ PASS | Only Vitest is used. |

Python and PowerShell unit-test sections are N/A (no test files in those languages changed this cycle).

---

## 5. Test Coverage Detail

### naa-token-acquirer.ts — PII-skip and clientId (cycle-4-affected tests)

| Test Name | Scenario Type | Status |
|-----------|--------------|--------|
| excludes a Warning/Error message flagged as containing PII while retaining a non-PII message at the same level | Negative / Edge | ✅ |
| exposes loggerOptions typed for MSAL (Verbose level, PII logging disabled) | Positive | ✅ |
| drops Info and Verbose messages and any PII-flagged message, retaining only non-PII Warning/Error | Negative / Edge | ✅ |
| builds MSAL config with the realigned non-secret clientId | Positive | ✅ |

**Coverage:** `naa-token-acquirer.ts` 98.27% lines / 95.23% branch. Uncovered lines 198, 249 are the host-bound default nestable-client constructor adapter and the `attachMsalLog` non-writable-target catch — both pre-existing default paths, not cycle-4 changed lines.

**Not covered:** None among cycle-4 changed executable lines.

---

## 6. Test Execution Metrics

| Metric | Value | Status |
|--------|-------|--------|
| Total Tests | 163 | ✅ |
| Tests Passed | 163 (100%) | ✅ |
| Tests Failed | 0 | ✅ |
| Test Files | 29 | ✅ |
| Code Coverage (all files) | 95.47% lines, 92.49% branches | ✅ |
| Code Coverage (changed file) | 98.27% lines, 95.23% branches | ✅ |

---

## 7. Code Quality Checks

**For TypeScript:**

| Check | Command | Result | Status |
|-------|---------|--------|--------|
| Prettier formatting | `npm run format:check` | All matched files conform | ✅ |
| ESLint | `npm run lint` | 0 findings | ✅ |
| Type checking | `npm run typecheck` | 0 errors | ✅ |
| Architecture boundary | `npm run depcruise` | 0 errors, MSAL boundary intact | ✅ |
| Vitest + coverage | `npm run test:coverage` | 163 pass, no regression | ✅ |
| Manifest validate | `npm run validate` | manifest is valid | ✅ |
| Manifest validate (XML) | `npm run validate:xml` | manifest is valid | ✅ |

**Notes:**
Independent prettier run over `tests/**` and `manifest.json` reports style warnings in four pre-existing untracked test files (`api-base-url.test.ts`, `ifile.bootstrap.test.ts`, `ifile.host-shell.test.ts`, `inline-host.test.ts`) and `manifest.json`. These are outside the project format gate, whose glob is `src/**/*.ts` only (`package.json` `format` / `format:check`). They are not cycle-4 in-scope files (the cycle-4 in-scope source `naa-token-acquirer.ts` passes `format:check`). Recorded as an observation; not a cycle-4 finding.

---

## 8. Gaps and Exceptions

### Identified Gaps

**None** at the code level for cycle 4. Feature DONE remains gated on declared human exceptions HI-1 (admin consent), HI-2 (mobile build + on-device re-verification), and HI-3 (backend OBO user-secrets injection) — tracked, not code defects.

### Approved Exceptions

- HI-1, HI-2, HI-3 are declared human-execution exceptions per the scope contract section 4 and the feature's human-exception runbooks. They gate feature DONE, not cycle exit.

### Removed/Skipped Tests

**None.** The PII-skip test was converted from the temporary diagnostic form back to asserting PII exclusion; no test coverage was lost (branch coverage on the file increased).

---

## 9. Summary of Changes

### Files Modified (cycle 4)

1. **`src/taskpane/ifile/naa-token-acquirer.ts`** (MODIFIED) — `CLIENT_ID` realigned to `3592bf52-...`; `piiLoggingEnabled: false` restored; `if (containsPii) { return; }` guard + third callback parameter reinstated; all `DIAGNOSTIC`/`REVERT` text removed.
2. **`manifest.json`** (MODIFIED) — `webApplicationInfo.id` / `.resource` updated to the new client ID and Application ID URI.
3. **`manifest.xml`** (MODIFIED) — `<WebApplicationInfo><Id>` / `<Resource>` updated to match.
4. **`tests/taskpane/ifile/naa-token-acquirer.test.ts`** (MODIFIED) — clientId assertion updated; PII-skip coverage restored.
5. **`runbooks/entra-app-sso-config.runbook.md`** (MODIFIED) — client ID / App ID URI references realigned; non-secret UserSecretsId added to the `dotnet user-secrets set` example (observation; non-secret).
6. **`runbooks/outlook-on-device-verification.runbook.md`** (MODIFIED) — Application ID URI reference realigned.

Observation (out of cycle-4 scope): a pre-existing uncommitted working state coexists in the tree (MSAL log-capture subsystem in `naa-token-acquirer.ts`, plus untracked `README.md`, `ifile.html`, `ifile.ts`, `build-stamp.ts`, `sign-in-error-detail.ts` changes and an audit-folder reorganization). These are prior state, assessed only as observations.

---

## 10. Compliance Verdict

### Overall Status: ✅ FULLY COMPLIANT (cycle-4 scope)

The cycle-4 change complies with the cross-language code-change and unit-test policies and the TypeScript-specific policies. The seven-stage TypeScript toolchain passes clean and was independently reproduced for this audit; coverage did not regress on changed lines; no secret value entered the repository; the MSAL import boundary is intact; and no immutable historical/audit artifact was rewritten. No `.github/workflows/**` or `scripts/benchmarks/**` file changed in this cycle, so the `modified-workflow-needs-green-run` rule does not apply.

**Fail-closed reminder:** All required baseline, QA, and coverage-comparison artifacts are present; no fail-closed condition is triggered.

### Policy-by-Policy Summary

#### General Code Change Policy (Section 2)
- ✅ Before Making Changes; ✅ Design Principles; ✅ Module & File Structure; ✅ Naming/Docs/Comments; ✅ Toolchain Execution; ✅ Summarize & Document.

#### Language-Specific Code Change Policy (Section 3)
- ✅ TypeScript: Tooling & Baseline, typing, suppressions all clean. Python/PowerShell/C#: N/A (no changed files).

#### General Unit Test Policy (Section 1)
- ✅ Core Principles; ✅ Coverage & Scenarios; ✅ Test Structure; ✅ External Dependencies; ✅ Policy Audit.

#### Language-Specific Unit Test Policy (Section 4)
- ✅ TypeScript/Vitest: Framework, coverage, location, runner all compliant.

### Metrics Summary

- ✅ 163/163 tests passing (100%)
- ✅ 95.47% line / 92.49% branch coverage (all files), above uniform thresholds
- ✅ 98.27% line / 95.23% branch on the changed file; no regression on changed lines
- ✅ All seven TypeScript toolchain stages passing in a single pass
- ✅ No secret in repo; MSAL boundary intact; no immutable artifact rewritten

### Recommendation

**Ready for merge (cycle-4 scope).** The cycle-4 code change is policy-compliant and verified. Feature-level merge remains gated on the declared human exceptions HI-1, HI-2, and HI-3, which are not code defects.

---

## Appendix A: Test Inventory

Cycle-4-affected tests in `tests/taskpane/ifile/naa-token-acquirer.test.ts`:

1. createMsalLogCapture › excludes a Warning/Error message flagged as containing PII while retaining a non-PII message at the same level
2. createMsalLogCapture › exposes loggerOptions typed for MSAL (Verbose level, PII logging disabled)
3. createMsalLogCapture › drops Info and Verbose messages and any PII-flagged message, retaining only non-PII Warning/Error
4. createNaaTokenAcquirer › builds MSAL config with the realigned non-secret clientId (asserts `3592bf52-...`)

Full suite scope: 29 test files, 163 tests, all passing.

---

## Appendix B: Toolchain Commands Reference

**For TypeScript:**
```bash
# Formatting (project gate: src/**/*.ts)
npm run format:check

# Linting
npm run lint

# Type checking
npm run typecheck

# Architecture boundary (MSAL import-boundary rule)
npm run depcruise

# Testing + coverage
npm run test:coverage

# Manifest contract validation
npm run validate
npm run validate:xml
```

---

**Audit Completed By:** feature-review agent
**Audit Date:** 2026-06-06
**Policy Version:** Current (as of audit date)
