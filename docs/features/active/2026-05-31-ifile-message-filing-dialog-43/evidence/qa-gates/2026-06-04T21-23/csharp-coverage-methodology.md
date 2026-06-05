# C# Coverage Ground-Truth — Cycle 2 POL-1 Re-evaluation Evidence

- Captured: 2026-06-04T21-23 by orchestrator diagnostic (full backend suite)
- Purpose: establish whether the cycle-2 reaudit finding POL-1 ("repo-wide C# coverage 21.99% line / 8.01% branch — FAIL") is a real defect or a measurement artifact.

## Finding 1 — The CI "canonical" C# coverage artifact is a single test project's file, not a merged repo-wide figure

`.github/actions/dotnet-test/action.yml` runs `dotnet test TaskMaster.sln --collect:"XPlat Code Coverage"`, which emits a SEPARATE `coverage.cobertura.xml` per test project. The next step then selects ONE file:

```
$latest = Get-ChildItem TestResults -Recurse -Filter coverage.cobertura.xml |
  Sort-Object LastWriteTime -Descending | Select-Object -First 1
Copy-Item $latest.FullName artifacts/csharp/coverage.xml
```

It copies the most-recently-written single project file as `artifacts/csharp/coverage.xml`. There is no ReportGenerator merge. The canonical artifact therefore represents whichever test project finished last — not the solution.

## Finding 2 — Full-suite ground truth (this run): all backend tests pass; per-project files vary 0%–65%

`dotnet build TaskMaster.sln --warnaserror` succeeded (0 warnings/0 errors). `dotnet test TaskMaster.sln --collect:"XPlat Code Coverage"` — all projects pass: ArchitectureTests 10, Schema.Tests 24, Application.Tests 43, Worker.Tests 4, PlaceholderGolden.Tests 1, Classifier.Tests 14, Infrastructure.Tests 21, Api.Tests 28 (total 145).

Eight per-project `coverage.cobertura.xml` files were emitted. Each measures the assemblies loaded during that project's run, so each reports a different line-rate:

| LastWriteTime | line-rate | branch-rate | packages in file |
|---|---|---|---|
| 21:23:27 (LATEST — the one CI would pick) | 0.2279 | 0.0896 | Api, Application, Classifier, Domain, Infrastructure |
| 21:23:26 | 0.6541 | 0.50 | Application, Domain, Infrastructure |
| 21:23:26 | 0.2835 | 0.2289 | Application, Domain, Infrastructure |
| 21:23:26 | 0.1464 | 0.2777 | Application, Classifier, Domain |
| 21:23:26 | 0.1067 | 0.1435 | schema-diff, Application, Domain, Infrastructure |
| 21:23:26 | 0 | 0 | (empty / Classifier+Infra not exercised) |

The "~22.79%" latest file is the Api.Tests view: Api.Tests exercises the API layer but loads (without exercising) the Application/Classifier/Infrastructure assemblies, so their lines count against the denominator. This is exactly the single-project artifact the reaudit read as "repo-wide 21.99%". No single file is a true merged repo-wide figure; computing one requires merging all eight with ReportGenerator.

## Finding 3 — Cycle 2 introduced zero C# production changes

Cycle 2 changed only TypeScript, manifests, package.json/lock, .dependency-cruiser.cjs, and docs (per the executor report and `git diff`). The only modified C# files in the working tree — `src/TaskMaster.Api/Program.cs` (OBO wiring) and `src/TaskMaster.Api/TaskMaster.Api.csproj` (whitespace) — were already modified at session start, before any iFile remediation (they are not cycle-1 or cycle-2 deliverables; both executors reported no C# change). The reaudit's own analysis found the changed `Program` class at 87% with no changed-line regression.

## Conclusion

POL-1 as written ("repo-wide C# coverage FAIL, triggered by a language with changed files this cycle") rests on (a) reading a single-project coverage file as a merged repo-wide figure, and (b) attributing pre-existing, out-of-cycle working-tree C# edits to cycle 2. Cycle 2 introduced no C# changed lines, and the one pre-existing C# edit has covered changed lines with no regression. The low number reflects the CI single-file-pick methodology applied to unchanged backend packages.

Separately (out of iFile scope): the CI canonical-coverage methodology — picking one arbitrary project's file rather than merging — is a pre-existing reliability gap in the C# coverage gate. Recommended as a standalone follow-up (potential entry); fixing it touches `.github/actions/**` and would trigger `modified-workflow-needs-green-run`. It must not be folded into iFile.

Regeneration: `dotnet build TaskMaster.sln --warnaserror; dotnet test TaskMaster.sln --collect:"XPlat Code Coverage" --no-build`.
