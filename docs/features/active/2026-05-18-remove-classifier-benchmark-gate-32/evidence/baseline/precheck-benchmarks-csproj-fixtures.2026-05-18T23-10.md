---
Timestamp: 2026-05-18T23-10
Command: Get-Content tests/TaskMaster.Benchmarks/TaskMaster.Benchmarks.csproj | Select-String 'Fixtures|EmbeddedResource|None Include|Content Include'
EXIT_CODE: 0
Output Summary: no Fixtures reference; csproj has no <EmbeddedResource>, <None Include>, or <Content Include> globbing items at all. Safe to proceed with P6-T8/T9/T11 Fixtures deletions without a follow-up csproj edit task.
---

## Full csproj contents (for audit reference)

```xml
<Project Sdk="Microsoft.NET.Sdk">
    <PropertyGroup>
        <TargetFramework>net10.0</TargetFramework>
        <OutputType>Exe</OutputType>
        <ImplicitUsings>enable</ImplicitUsings>
        <IsPackable>false</IsPackable>
        <!--
            BenchmarkDotNet requires specific code shapes (public types so benchmark
            discovery works, instance benchmark methods invoked by the harness, and
            benchmark identifiers that may carry underscores). The solution-wide
            TreatWarningsAsErrors=true setting turns the corresponding analyzer
            diagnostics into build failures, so the following analyzer IDs are
            suppressed at the project scope. Each ID is justified in
            docs/features/active/2026-05-15-idempotency-and-benchmark-infra-23/evidence/other/p1-analyzer-justification.md.
        -->
        <NoWarn>$(NoWarn);CA1822;CA1707;CA1515;MA0051;S1135</NoWarn>
    </PropertyGroup>

    <ItemGroup>
        <PackageReference Include="BenchmarkDotNet" />
    </ItemGroup>

    <ItemGroup>
        <ProjectReference Include="..\..\src\TaskMaster.Classifier\TaskMaster.Classifier.csproj" />
    </ItemGroup>
</Project>
```

## Decision

The csproj does not reference `Fixtures/` via `<EmbeddedResource>`, `<None Include>`, `<Content Include>`, or any other item glob. Phase 6 deletions of `Fixtures/SyntheticLatencyRegressionFixture.json`, `Fixtures/SyntheticAllocationRegressionFixture.json`, and the now-empty `Fixtures/` directory will not break the project build. Proceeding to P6-T2.
