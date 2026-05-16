# Baseline — CI State

Timestamp: 2026-05-14T22-25

Output Summary: Records the pre-change CI structure for the three files modified by Phases 4 and 6, for later diff comparison.

## `.github/actions/contract/action.yml` (current — no-op placeholder)

```yaml
name: Contract
description: Contract / schema compatibility stage. Wires oasdiff or schema-snapshot diff when API specs exist.
runs:
  using: composite
  steps:
    - name: Contract checks (placeholder)
      shell: pwsh
      run: |
        Write-Host "Contract stage: no API specs in repo yet; skipping (no-op)."
```

Status: no-op. The composite action prints a skip message and performs no contract validation.

## `.github/workflows/pr-pipeline.yml` — `stage-6-contract` job (current)

```yaml
  stage-6-contract:
    runs-on: windows-latest
    needs: [stage-5-test]
    steps:
      - uses: actions/checkout@v4
      - uses: ./.github/actions/contract
```

`stage-6-contract` `runs-on:` value: **`windows-latest`** (to be changed to `ubuntu-latest` by P4-T4).
Checkout: `actions/checkout@v4` with no `fetch-depth` (to gain `fetch-depth: 0` in P4-T5).

## `.github/workflows/pre-merge-pipeline.yml` — final stage (current)

The pipeline currently ends at `stage-9-golden`:

```yaml
  stage-9-golden:
    runs-on: windows-latest
    needs: [stage-8-mutation]
    steps:
      - uses: actions/checkout@v4
      - name: Setup .NET
        uses: actions/setup-dotnet@v4
        with:
          dotnet-version: 10.0.x
      - name: Restore
        shell: pwsh
        run: dotnet restore TaskMaster.sln
      - name: Run placeholder golden tests
        shell: pwsh
        run: |
          dotnet test tests/TaskMaster.PlaceholderGolden.Tests/TaskMaster.PlaceholderGolden.Tests.csproj --no-restore --collect:"XPlat Code Coverage"
      - name: Run classifier golden tests
        shell: pwsh
        run: |
          dotnet test tests/TaskMaster.Classifier.Tests/TaskMaster.Classifier.Tests.csproj --no-restore --collect:"XPlat Code Coverage"
```

No `stage-10-e2e` job exists (to be added by P6-T2). Jobs present: `stage-8-mutation`, `stage-9-golden`.
