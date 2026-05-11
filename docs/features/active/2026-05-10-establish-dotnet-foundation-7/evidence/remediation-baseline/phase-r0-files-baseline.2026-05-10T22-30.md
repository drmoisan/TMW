# Phase R0 — Files Baseline (Pre-Remediation Diff Reference)

- Timestamp: 2026-05-10T22-30
- Task: [PR0-T6]

## `.github/actions/dotnet-test/action.yml` (baseline)

```yaml
name: dotnet-test
description: Run the TaskMaster solution unit tests with coverage.
runs:
  using: composite
  steps:
    - name: Setup .NET
      uses: actions/setup-dotnet@v4
      with:
        dotnet-version: 10.0.x
    - name: dotnet test (with coverage)
      shell: pwsh
      run: dotnet test TaskMaster.sln --collect:"XPlat Code Coverage" --no-build --results-directory TestResults/
```

## `src/TaskMaster.Api/TaskMaster.Api.csproj` (baseline)

```xml
<Project Sdk="Microsoft.NET.Sdk.Web">
    <PropertyGroup>
        <TargetFramework>net10.0</TargetFramework>
        <ImplicitUsings>enable</ImplicitUsings>
    </PropertyGroup>

    <ItemGroup>
        <PackageReference Include="Microsoft.AspNetCore.OpenApi" />
        <PackageReference Include="NSwag.MSBuild">
            <PrivateAssets>all</PrivateAssets>
            <IncludeAssets>runtime; build; native; contentfiles; analyzers</IncludeAssets>
        </PackageReference>
    </ItemGroup>

    <!-- Phase 9 / AC24: emit OpenAPI to artifacts/openapi/current.json after build via NSwag. -->
    <Target Name="GenerateOpenApi" AfterTargets="Build" Condition="'$(SkipNSwag)' != 'true'">
        <MakeDir Directories="$(MSBuildThisFileDirectory)..\..\artifacts\openapi\" />
        <Exec
            Command="$(NSwagExe_Net100) aspnetcore2openapi /project:&quot;$(MSBuildProjectFullPath)&quot; /noBuild:true /output:&quot;$(MSBuildThisFileDirectory)..\..\artifacts\openapi\current.json&quot;"
            ContinueOnError="true"
            IgnoreExitCode="true"
        />
    </Target>
</Project>
```
