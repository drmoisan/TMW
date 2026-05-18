# [P5-T3] LatencyRegressionGateTests Self-Validation

Timestamp: 2026-05-15T22-18
Command: `dotnet test tests/TaskMaster.Worker.Tests -c Release --filter "FullyQualifiedName~LatencyRegressionGateTests" --nologo`
EXIT_CODE: 0
Output Summary: 1 passed, 0 failed. The test invokes `scripts/benchmarks/compare-benchmarks.ps1` against `artifacts/benchmarks/baseline.json` and `tests/TaskMaster.Benchmarks/Fixtures/SyntheticLatencyRegressionFixture.json` with `-T1BenchmarkIdPattern "ClassifierBenchmarks"`, and asserts the comparator exit code is non-zero. The comparator returned exit 1 (latency regression detected), satisfying AC7's validation scenario.

Note on placement: The plan offered "xUnit test inside benchmarks project or a small companion test project". The TaskMaster.Benchmarks project is `OutputType=Exe` (BenchmarkDotNet host) and does not include the xUnit test SDK; the test is therefore placed in `tests/TaskMaster.Worker.Tests/SelfValidation/LatencyRegressionGateTests.cs` (the companion test project option). The test is decorated `[Trait("Category","benchmark-gate-self-validation")]` so it is excluded from the default lane and invoked only by the self-validation job in `[P6-T2]`.
