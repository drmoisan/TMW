# [P1-T3] Analyzer Suppression Justification — TaskMaster.Benchmarks

Timestamp: 2026-05-15T21-52
Command (verification): `dotnet build tests/TaskMaster.Benchmarks/TaskMaster.Benchmarks.csproj -c Release -warnaserror`
EXIT_CODE: 0
Output Summary: Build succeeded with 0 warnings and 0 errors. Suppressions are project-scoped only (declared in `<NoWarn>` inside `TaskMaster.Benchmarks.csproj`) and do not affect any other project.

Suppressed analyzer IDs with justifications:

- CA1822 — "Mark members as static." BenchmarkDotNet requires `[Benchmark]` methods to be instance methods so the harness can construct the benchmark class, run `[GlobalSetup]`, and invoke the benchmark on the same instance. Making benchmark methods static would prevent benchmark discovery and per-instance state setup.
- CA1707 — "Identifiers should not contain underscores." Benchmark IDs reported in the BenchmarkDotNet output and consumed by `scripts/benchmarks/compare-benchmarks.ps1` use readable, structured names that may include underscores to separate scenario qualifiers from the operation under test. The comparator parses these identifiers; renaming them would break the stage-10 contract.
- CA1515 — "Consider making public types internal." BenchmarkDotNet discovers benchmark classes via reflection over the assembly's public types. Marking benchmark classes `internal` would hide them from `BenchmarkSwitcher.FromAssembly`.
- S1135 — "Complete the task associated to this 'TODO' comment." The plan explicitly requires a `TODO(G2)` marker on `DeltaReconciliationBenchmarks.DeltaReconciliation_Apply` per [P2-T2] acceptance, and that marker is itself part of the contract with Prompt G2. The suppression is scoped to this project only.
- MA0051 — "Method is too long." Benchmark methods inline setup of in-memory fixtures to minimize allocations outside the measured region; splitting them into helpers would either add invocation overhead inside the measurement or require attributes (`[GlobalSetup]`) that change what is measured. The suppression is bounded to this scaffolding project and does not affect production code.

Each suppression is scoped to `tests/TaskMaster.Benchmarks/TaskMaster.Benchmarks.csproj`; production projects continue to enforce the full analyzer set.
