# Coverage Delta — Baseline vs Post-Change

Timestamp: 2026-05-14T23-52

## Output Summary

Coverage comparison for the two languages in scope, per the plan's P7-T14 requirements.

### TypeScript (Vitest + v8)

Source: P0-T9 baseline (`baseline-ts-test.md`) and P7-T12 post-change (`final-ts-test.md`).

| Scope | Metric | Baseline | Post-change | Delta | Threshold | Status |
|---|---|---|---|---|---|---|
| All files | Line | 99.26% | 99.27% | +0.01 pp | >= 85% | PASS |
| All files | Branch | 95.34% | 95.55% | +0.21 pp | >= 75% | PASS |
| All files | Statements | 99.26% | 99.27% | +0.01 pp | (>= 85%) | PASS |
| All files | Functions | 100% | 100% | 0 | (>= 85%) | PASS |
| `src/taskpane/classifier-client.ts` | Line | 100% | 100% | 0 | n/a | no regression |
| `src/taskpane/classifier-client.ts` | Branch | 100% | 100% | 0 | n/a | no regression |
| `src/taskpane/taskpane.ts` | Line | 98.57% | 98.61% | +0.04 pp | n/a | improved |
| `src/taskpane/taskpane.ts` | Branch | 92.30% | 92.85% | +0.55 pp | n/a | improved |

**New/changed-code coverage (TypeScript):**

The changed/new TypeScript files in Issue #19 are:
- `src/api-client/v1.ts` — auto-generated, type-only, excluded from coverage by `vitest.config.ts`.
- `src/taskpane/classifier-client.ts` — migrated to generated types; runtime code unchanged; coverage stays 100% line / 100% branch.
- `src/taskpane/taskpane.ts` — added a `typeof result.confidence === "number"` ternary; the new branch is covered by the added `taskpane.test.ts` "coerces a string-encoded confidence to a number" test; per-file branch coverage improved from 92.30% to 92.85%.
- `src/api-client/eslint-guard.test.ts` — new test file (3 tests); test files themselves are excluded from coverage by the v8 `exclude: ["**/*.test.ts"]` rule.

No coverage regression on any changed line. All-files coverage exceeds the 85% line / 75% branch thresholds with material headroom.

### C# (xUnit + XPlat Code Coverage)

Source: P0-T5 baseline (`baseline-csharp-test.md`) and P7-T7 post-change (`final-csharp-test.md`). Numbers are from the `TaskMaster.Api.Tests` cobertura report.

| Package | Metric | Baseline | Post-change | Delta | Threshold | Status |
|---|---|---|---|---|---|---|
| TaskMaster.Api | Line | 18.97% | 23.18% | +4.21 pp | >= 85% | below threshold (pre-existing) |
| TaskMaster.Api | Branch | 4.12% | 6.14% | +2.02 pp | >= 75% | below threshold (pre-existing) |

Aggregate Api.Tests run header:
- Baseline: lines-covered 158 / lines-valid 673; branches-covered 15 / branches-valid 250.
- Post-change: lines-covered 187 / lines-valid 713; branches-covered 20 / branches-valid 260.

**New/changed-code coverage (C#):**

The changed/new C# files in Issue #19 are:
- `src/TaskMaster.Api/Program.cs` — modified to add the DocumentTransformer, the `GetDocument.Insider` guard, the `AddAuthorization()` registration, `.Produces<>` calls, and `.WithDescription` calls. The +40 valid lines reflect this growth; +29 of those are covered by the existing `TaskMaster.Api.Tests` host-integration suite, indicating the new code is partially exercised by the existing host test surface.
- `src/TaskMaster.Api/PingResponse.cs` — new file, a single-line record. Covered indirectly via the `/api/ping` endpoint when exercised.
- `src/TaskMaster.Api/TaskMaster.Api.csproj`, `Directory.Packages.props` — MSBuild edits, not source for coverage.

Both line and branch coverage for `TaskMaster.Api` **increased** versus the baseline. There is no regression on changed lines.

**Pre-existing threshold gap.** `TaskMaster.Api` absolute coverage remains below the 85% line / 75% branch thresholds. This is the same pre-existing baseline state recorded in P0-T5 — `TaskMaster.Api` is composed largely of ASP.NET host wiring that the existing `TaskMaster.Api.Tests` exercise only partially. The gap predates Issue #19 and is orthogonal to its scope. The plan's per-task acceptance ("no regression on changed lines") is satisfied. The absolute-threshold gap is recorded here as a follow-up finding to be addressed separately (it would require expanded API-host test coverage, which the plan does not direct).

## Overall Result

- TypeScript: PASS — post-change coverage meets `>= 85%` line / `>= 75%` branch thresholds with headroom, with no regression on changed lines.
- C#: PARTIAL — no regression on changed lines (coverage improved on both axes for `TaskMaster.Api`); `TaskMaster.Api` absolute coverage remains below the policy thresholds, a pre-existing gap outside Issue #19's scope.

Per the plan's literal acceptance ("post-change coverage meets the >= 85% line / >= 75% branch thresholds with no regression on changed lines"), the C# absolute threshold gap is a flagged pre-existing finding. The "no regression on changed lines" half of the acceptance is met. The "meets thresholds" half is met for TypeScript and not met in absolute terms for `TaskMaster.Api`, where the gap is pre-existing baseline state.
