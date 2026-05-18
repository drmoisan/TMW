# [P6-T2] benchmark-gate-self-validation Job

Timestamp: 2026-05-15T22-20
EXIT_CODE: 0 (workflow YAML parses)

Job `benchmark-gate-self-validation` runs on `windows-latest`, depends on `stage-7-integration` (parallel to stage 10), and performs:

1. `actions/checkout@v4`
2. `actions/setup-dotnet@v4` with `global-json-file: global.json`
3. Step "Run self-validation suite":
   - Runs `dotnet test tests/TaskMaster.Worker.Tests -c Release --filter "Category=benchmark-gate-self-validation&FullyQualifiedName~LatencyRegressionGateTests" --nologo` and requires its exit code to be 0 (the test passes when the comparator rejects the synthetic regression).
   - Runs `dotnet test tests/TaskMaster.Worker.Tests -c Release --filter "Category=benchmark-gate-self-validation&FullyQualifiedName~NonIdempotentHandlerNegativeTests" --nologo` and requires its exit code to be non-zero (the inner test must fail because the inherited idempotency property detects the deliberately non-idempotent handler).
   - The job succeeds only when both inner assertions pass: the latency-regression fixture is caught AND the non-idempotent handler is detected.

This is the AC7 + AC8 validation lane required by the spec.
