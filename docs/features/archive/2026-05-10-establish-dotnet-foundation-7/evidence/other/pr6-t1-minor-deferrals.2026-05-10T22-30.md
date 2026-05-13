# PR6-T1 — Minor / Info Deferrals

- Timestamp: 2026-05-10T22-30
- Task: [PR6-T1]

Each deferred item below was reviewed in remediation-inputs and assessed as defer-acceptable. None are blockers; each will be tracked as a follow-up improvement.

## R5 — Redundant `<ImplicitUsings>enable</ImplicitUsings>` in three csproj files

- Finding ID: R5 (code-review Minor)
- Severity: Minor
- Deferral rationale: cosmetic redundancy; `ImplicitUsings` already defaults to enabled in modern SDK templates. Removing the property does not change build behavior or fail any gate. The cost of touching three csproj files (and rerunning the full toolchain) exceeds the benefit.
- Follow-up tracking: tracked in a future cleanup commit when the three projects are touched for another reason; not blocking merge.

## R6 — Empty `stage-3-dotnet-typecheck` pipeline job

- Finding ID: R6 (code-review Minor)
- Severity: Minor
- Deferral rationale: stage placeholder reserved for an explicit type-check gate once a non-build-gated diagnostic is wired. The current build already enforces nullable analysis and analyzers via `Directory.Build.props` with `TreatWarningsAsErrors=true`, so the stage is conceptually a no-op in steady state but documents the intent. Removing it would weaken the auditable pipeline stage list; converting it to a guard is a Phase B+ design decision.
- Follow-up tracking: revisit when the next code-change PR touches `.github/workflows/pr-pipeline.yml`.

## R7 — `--no-build` flag in `.github/actions/dotnet-test/action.yml`

- Finding ID: R7 (code-review Info)
- Severity: Info
- Deferral rationale: `--no-build` requires the prior CI stage to have produced the build artifacts in the same job. The current PR pipeline runs build and test in the same composite job, so the flag is correct in this layout. If a future split moves test into a separate job, build artifacts would need to be uploaded/downloaded as an inter-job artifact — out of scope for this remediation.
- Follow-up tracking: revisit when the pipeline is split into separate build/test jobs; document via inline pipeline comment at that time.

## R8 — Spec/plan `T:` vs `P:` mismatch for `Random.Shared`

- Finding ID: R8 (code-review Minor)
- Severity: Minor
- Deferral rationale: narrative-only mismatch in plan and spec prose; the `BannedSymbols.txt` file itself is correct (uses `T:` for type) and is enforced by `Microsoft.CodeAnalysis.BannedApiAnalyzers`. The runtime behavior is correct; the discrepancy is purely textual in supporting documents.
- Follow-up tracking: correct on the next plan/spec update touching the banned-API section.
