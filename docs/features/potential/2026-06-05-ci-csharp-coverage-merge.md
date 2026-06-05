# ci-csharp-coverage-merge (Potential)

- Date captured: 2026-06-05
- Author: Dan Moisan
- Status: Draft
- Origin: Surfaced as CI-COV-1 during iFile (#43) remediation cycle 2. Out of iFile scope; recorded as a standalone follow-up.

## Problem / Why

The C# coverage gate consumes a single test project's coverage file as if it were a repo-wide figure. `.github/actions/dotnet-test/action.yml` runs `dotnet test TaskMaster.sln --collect:"XPlat Code Coverage"`, which emits a separate `coverage.cobertura.xml` per test project. The "Emit canonical coverage artifact" step then selects only the most-recently-written single file:

```powershell
$latest = Get-ChildItem TestResults -Recurse -Filter coverage.cobertura.xml |
  Sort-Object LastWriteTime -Descending | Select-Object -First 1
Copy-Item $latest.FullName artifacts/csharp/coverage.xml
```

There is no merge across projects. The canonical `artifacts/csharp/coverage.xml` therefore reflects whichever test project finishes last (observed: `TaskMaster.Api.Tests`, which loads but barely exercises the Application/Classifier/Infrastructure assemblies). Measured ground truth on 2026-06-04: the full suite passes 145/145, but the eight per-project coverage files range 0%–65% line-rate, and the latest single file reports ~22.79% — a number that looks like a repo-wide failure but is an artifact of the single-file pick. Evidence: `docs/features/active/2026-05-31-ifile-message-filing-dialog-43/evidence/qa-gates/2026-06-04T21-23/csharp-coverage-methodology.md`.

Consequence: the C# coverage gate is unreliable. It can report a false failure (a low single-project file) or a false pass (a high single-project file), and it does not measure true solution-wide coverage against the 85%/75% thresholds.

## Proposed Behavior

Merge all per-project `coverage.cobertura.xml` outputs into one solution-wide report before applying the coverage gate, and assert the line/branch thresholds against the merged figure.

- Run `dotnet test` with per-project coverage as today.
- Merge with ReportGenerator (e.g. `reportgenerator -reports:**/coverage.cobertura.xml -targettypes:Cobertura -targetdir:artifacts/csharp`) into a single canonical Cobertura report.
- Apply the line >= 85% / branch >= 75% thresholds (and any changed-lines check) against the merged report.

## Acceptance Criteria (early draft)

- [ ] The canonical C# coverage artifact is a merge of all test projects' coverage, not a single arbitrary file.
- [ ] The coverage gate evaluates the merged line/branch percentages against the repo thresholds.
- [ ] A synthetic coverage drop in any covered package is detected by the gate (negative-path proof).
- [ ] The change is demonstrated green on a workflow run against the branch head.

## Constraints & Risks

- Touches `.github/actions/dotnet-test/**` (and possibly the pipeline). Per `modified-workflow-needs-green-run`, a green workflow run against the branch head is required before merge.
- Adds a ReportGenerator tool dependency to the CI action (already common in .NET CI; justify in the change).
- Establishing the true merged baseline may reveal genuine pre-existing coverage gaps in backend packages that the single-file gate masked; those would need separate remediation and should not block this tooling fix.

## Test Conditions to Consider

- [ ] Unit/script coverage of the merge + threshold-evaluation step.
- [ ] Negative-path: a synthetic uncovered region fails the gate on the merged report.
- [ ] CI example: the action produces one merged `artifacts/csharp/coverage.xml` and a correct pass/fail decision.

## Next Step

- [ ] Promote to GitHub issue (refactor/CI template)
- [ ] Create `docs/features/active/ci-csharp-coverage-merge/` folder from the template
