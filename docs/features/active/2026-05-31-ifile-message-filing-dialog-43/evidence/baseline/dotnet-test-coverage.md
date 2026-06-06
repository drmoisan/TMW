# Baseline — .NET Unit Tests + Coverage (Issue #43)

Timestamp: 2026-06-01T00-00
Command: dotnet test tests/TaskMaster.Application.Tests ; dotnet test tests/TaskMaster.Infrastructure.Tests ; dotnet test tests/TaskMaster.Api.Tests (each with --collect:"XPlat Code Coverage")
EXIT_CODE: 0
Output Summary: All three suites pass — Application.Tests 20/20, Infrastructure.Tests 9/9, Api.Tests 19/19 (48 total).

Per-assembly cobertura line/branch rates at baseline (each run instruments the whole solution, so per-project reports under-count code not exercised by that project — these are the raw reference figures):
- TaskMaster.Api.Tests report: line-rate 0.2746 (27.46%), branch-rate 0.0766 (7.66%)
- TaskMaster.Application.Tests report: line-rate 0.2270 (22.70%), branch-rate 0.2222 (22.22%)
- TaskMaster.Infrastructure.Tests report: line-rate 0.6892 (68.92%), branch-rate 0.6944 (69.44%)

Note: these raw per-run rates reflect full-solution instrumentation across all three runs, not per-owning-project coverage. The CI gate evaluates the merged report scoped to changed code. The iFile feature targets line >= 85% / branch >= 75% on the new IFile/ production code, verified in Phase 8 (P8-T9, P8-T11) against the new code specifically.
