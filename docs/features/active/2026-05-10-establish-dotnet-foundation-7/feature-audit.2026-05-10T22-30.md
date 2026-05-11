# Feature Audit — Issue #7 (Prompt C1 — Establish .NET Foundation)

- Timestamp: 2026-05-10T22-30
- Issue: #7
- Work Mode (issue.md marker): `full-feature`
- AC sources per work-mode contract: `spec.md` + `user-story.md`

## Scope and Baseline

- Base branch: `origin/main`
- Merge-base SHA: `01d399c655629e9dd8974da4b00caf6e5a79bbea`
- Feature folder: `docs/features/active/2026-05-10-establish-dotnet-foundation-7/`
- Branch tip diff: 129 files changed; 2126 insertions / 71 deletions.
- Material changed paths: see `policy-audit.2026-05-10T22-30.md` § Scope.

## Acceptance Criteria Inventory

Per the work-mode contract, `full-feature` resolves AC from `spec.md` and `user-story.md`. Neither file uses an explicit `## Acceptance Criteria` checkbox section; both describe outcomes in prose. The executor produced a 30-row tabular AC check-off keyed to the `## Acceptance Criteria` numbered list in `issue.md`. To avoid scope confusion, this audit evaluates:

1. The **eight outcome statements** distilled from `spec.md` + `user-story.md` (authoritative under the work-mode contract).
2. The **30 numbered AC** in `issue.md` (executor-recorded; included for traceability and downstream tooling).

### Spec / user-story outcomes (authoritative)

- O1: C# rule baseline matches the No-COM toolchain (xUnit, NSubstitute, `dotnet build`, `TimeProvider`, analyzer stack, uniform coverage thresholds).
- O2: A .NET solution skeleton exists where `dotnet csharpier check`, `dotnet build`, `dotnet test`, and architecture tests gate the PR pipeline.
- O3: Mirror discipline preserved between `.claude/rules/` ↔ `.github/instructions/` and `.claude/skills/` ↔ `.github/skills/`.
- O4: Central package management (`Directory.Packages.props`) and central build (`Directory.Build.props`) installed with the analyzer stack and banned-symbol wiring.
- O5: `BannedSymbols.txt` bans the five APIs; representative banned-API violation blocks the build.
- O6: `*.ArchitectureTests` xUnit project with `NetArchTest.Rules` and three rule categories (No-COM, forbidden legacy namespaces, Domain-vs-Infrastructure).
- O7: NSwag emits `artifacts/openapi/current.json`.
- O8: PR pipeline workflow extended with .NET stages 1-5 (csharpier check, dotnet build, nullable typecheck via build, architecture tests, dotnet test with coverage).

### Issue.md AC inventory

Issue.md `## Acceptance Criteria` numbered 1-30 (executor table at `p14-acceptance-criteria-checkoff.md`).

## Acceptance Criteria Evaluation

### Spec / user-story outcomes

| ID | Outcome | Status | Evidence |
|---|---|---|---|
| O1 | C# rule baseline matches No-COM toolchain | PASS | `.claude/rules/csharp.md` (analyzer stack, banned APIs, DI seams, uniform coverage, CsCheck/Stryker.NET/Verify.Xunit sections all present); `evidence/qa-gates/phase1-grep.2026-05-10T20-14.txt`. |
| O2 | Solution skeleton gates PR pipeline via four toolchain commands | PASS | `TaskMaster.sln`, `.github/workflows/pr-pipeline.yml` stages 1-dotnet-format through 5-dotnet-test; `evidence/qa-gates/p14-t2-*.2026-05-10T20-14.txt`. |
| O3 | Mirror discipline preserved | PASS | `.github/instructions/csharp-*.instructions.md`, `.github/skills/feature-review-workflow/SKILL.md`, `.github/agents/csharp-typed-engineer.agent.md` all updated; `evidence/qa-gates/p3-t3-mirror-absence.2026-05-10T20-14.md`, `p3-t5-mirror-absence.2026-05-10T20-14.md`, `phase3-grep.2026-05-10T20-14.txt`. |
| O4 | Central package management + central build with analyzer stack installed | PASS | `Directory.Build.props` (six analyzers with `PrivateAssets="all"`); `Directory.Packages.props` (versions pinned; `ManagePackageVersionsCentrally=true`); `evidence/qa-gates/p5-t1-grep`, `p5-t2-grep`, `p6-t1-grep`, `p6-t4-dotnet-build.2026-05-10T20-14.txt`. |
| O5 | BannedSymbols.txt bans five APIs; representative violation blocks build | PASS | `BannedSymbols.txt` (five entries); `evidence/regression-testing/p13-t2-banned-api-build.2026-05-10T20-14.txt`. Executor deviation #5 (Random.Shared substituted for DateTime.UtcNow as the demonstration vector) is documented and does not weaken the assertion: the analyzer wiring is exercised. |
| O6 | ArchitectureTests project with three rule categories | PARTIAL | Project exists with three `[Fact]` methods (No-Outlook, Forbidden-legacy-namespaces, Domain-vs-Infrastructure). All three pass. However, the Domain-vs-Infrastructure fact was not provably negative-tested (executor deviation #6); the assertion is wired but unverified against a concrete violation. |
| O7 | NSwag emits `artifacts/openapi/current.json` | PARTIAL | The MSBuild target is wired in `src/TaskMaster.Api/TaskMaster.Api.csproj` and `artifacts/openapi/current.json` exists. However, the artifact was hand-authored because NSwag.MSBuild's launcher fails on net10.0; the target is suppressed via `ContinueOnError="true"`. Documented as deviation #4. The outcome is materially met but emission is not yet live. |
| O8 | PR pipeline workflow extended with .NET stages 1-5 | PASS | `.github/workflows/pr-pipeline.yml` adds `stage-{1-dotnet-format,2-dotnet-build,3-dotnet-typecheck,4-dotnet-architecture,5-dotnet-test}` jobs and four `.github/actions/dotnet-*/action.yml` composite actions. The five-stage shape matches `spec.md` §"PR Pipeline Stages (.NET extension)". Note from code-review: `--no-build` in `dotnet-test/action.yml` may fail at runtime because each job is a separate runner; tracked as INFO in the code review. |

### Issue.md AC (executor table — reviewer concurrence)

The reviewer reproduced the executor's table and concurs with all 30 PASS evaluations on the literal text of each criterion, with the following qualifications drawn from the spec-level analysis above:

- AC26 ("All gates pass on empty solution skeleton (CI green)") — Reviewer reads this literally as "the gates that run all return non-error". On that reading, PASS, matching the executor. However, the **uniform coverage gate** is not literally a green test result; the cobertura `lines-valid=0` headline does not satisfy `line >= 85% / branch >= 75%` for new files (see policy audit F1). The executor table records AC26 PASS based on test execution; the policy audit records the coverage shortfall separately.
- AC24 ("NSwag wired to emit `artifacts/openapi/current.json`") — Wired and emits a valid file; emission is currently hand-authored. PARTIAL on the spirit, PASS on the literal text.
- AC28 ("Representative architecture-rule violation blocks the build") — PASS via the forbidden-legacy-namespaces fact; the Domain-vs-Infrastructure fact is wired but not negative-tested.

The executor's table is preserved in `p14-acceptance-criteria-checkoff.md`. No checkboxes are updated by the reviewer because the executor's table is a free-form table, not a markdown checkbox list.

## Summary

- Outcomes PASS: 6/8.
- Outcomes PARTIAL: 2/8 (O6, O7).
- Outcomes FAIL: 0/8.
- Coverage on new production files: 0% effective (uniform tier rule violated). Recorded as a policy-audit FAIL (F1) and a code-review Blocker. This concerns the broader feature-quality gate rather than any individual outcome statement.

**Overall feature verdict: NO-GO for PR merge until F1 (new-file coverage) and F2 (canonical coverage artifact) are remediated.** O6 and O7 PARTIAL findings can ship as documented deviations if the orchestrator accepts them; the policy-audit FAILs cannot.

## Acceptance Criteria Check-off

Per `acceptance-criteria-tracking`:

- `spec.md` and `user-story.md` do not use markdown `- [ ]` checkboxes for acceptance criteria. No checkbox edits are made to those files; this audit's outcome evaluation is the recorded verdict.
- `issue.md` `## Acceptance Criteria` uses a numbered list (`1.`, `2.`, ...), not checkbox format. Per skill rule "If AC items are not in checkbox format... do NOT reformat them", no edits are made to issue.md. The reviewer concurrence on each numbered AC is recorded in the table above.
- The executor's `p14-acceptance-criteria-checkoff.md` table remains the authoritative status snapshot for the 30 issue-level criteria.

### Acceptance Criteria Status

```
### Acceptance Criteria Status
- Source: spec.md + user-story.md (work-mode contract); issue.md (executor table)
- Total outcome statements (spec/user-story): 8
- PASS: 6
- PARTIAL: 2 (O6 — Domain-vs-Infrastructure fact not negative-tested; O7 — NSwag emission is hand-authored)
- FAIL: 0
- Total issue.md numbered AC: 30
- Executor PASS: 30 (concurred on literal text; see qualifications above)
- Cross-cutting policy FAIL (not an AC item): coverage on new production files (F1) and missing canonical coverage artifact (F2).
```

