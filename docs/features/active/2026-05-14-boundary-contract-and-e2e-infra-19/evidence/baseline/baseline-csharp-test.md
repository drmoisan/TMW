# Baseline — C# Unit Tests + Coverage

Timestamp: 2026-05-14T22-14
Command: `dotnet test TaskMaster.sln --collect:"XPlat Code Coverage"`
EXIT_CODE: 0

Output Summary:
All test projects passed. Totals: ArchitectureTests 7 passed; PlaceholderGolden.Tests 1 passed; Application.Tests 20 passed; Infrastructure.Tests 7 passed; Classifier.Tests 14 passed; Api.Tests 19 passed. Failed: 0 across all projects.

Coverage (TaskMaster.Api package, from `tests/TaskMaster.Api.Tests` cobertura report):
- Line coverage: 18.97% (line-rate 0.1897)
- Branch coverage: 4.12% (branch-rate 0.0412)

Note: `TaskMaster.Api` baseline line/branch coverage is below the 85%/75% policy thresholds. `TaskMaster.Api` is largely composed of ASP.NET host wiring (`Program.cs` minimal API + DI registration) which the existing `TaskMaster.Api.Tests` exercise only partially. This is the pre-change baseline; the coverage-delta verification task (P7-T14) compares post-change coverage against this baseline and requires no regression on changed lines. Aggregate cobertura header for the Api.Tests run: lines-covered 158 / lines-valid 673; branches-covered 15 / branches-valid 250.

Per-package line/branch rates observed in the Api.Tests aggregate report:
- TaskMaster.Api: line 0.1897 / branch 0.0412
- TaskMaster.Application: line 0.5641 / branch 0.5000
- TaskMaster.Classifier: line 0.6333 / branch 0.2000
- TaskMaster.Domain: line 1.0000 / branch 1.0000
- TaskMaster.Infrastructure: line 0.2074 / branch 0.0000
