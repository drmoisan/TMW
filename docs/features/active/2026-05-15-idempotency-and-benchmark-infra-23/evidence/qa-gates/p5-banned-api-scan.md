# [P5-T4] Banned API Scan — tests/TaskMaster.Worker.Tests

Timestamp: 2026-05-15T22-18
Command: `pwsh -NoProfile -Command "Get-ChildItem tests/TaskMaster.Worker.Tests -Recurse -Filter *.cs | Select-String -Pattern 'Thread\.Sleep|Task\.Delay|DateTime\.UtcNow|TimeProvider\.System' -CaseSensitive"`
EXIT_CODE: 0
Output Summary: Zero matches. None of the banned APIs (`Thread.Sleep`, `Task.Delay`, `DateTime.UtcNow`, `TimeProvider.System`) appear in any test file under `tests/TaskMaster.Worker.Tests`. All clock reads route through the injected `FakeTimeProvider` on `SubscriptionHandlerTestBase.Clock`.

Note: `Process.WaitForExit(60_000)` in `LatencyRegressionGateTests` uses a millisecond-based timeout argument; it is not a banned-clock API and does not trigger any of the banned patterns above.
