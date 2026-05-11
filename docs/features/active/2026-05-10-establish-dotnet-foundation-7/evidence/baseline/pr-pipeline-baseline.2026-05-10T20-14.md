---
Timestamp: 2026-05-10T20-14
Task: P0-T8
Source: .github/workflows/pr-pipeline.yml (raw copy)
---

```yaml
name: PR Pipeline
on:
  pull_request:
    branches: [main]

permissions:
  contents: read

jobs:
  tier-classification:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4
      - shell: pwsh
        run: pwsh -NoProfile -File .github/scripts/validate-quality-tiers.ps1
  stage-1-format:
    runs-on: windows-latest
    needs: [tier-classification]
    steps:
      - uses: actions/checkout@v4
      - uses: ./.github/actions/format
  stage-2-lint:
    runs-on: windows-latest
    needs: [stage-1-format]
    steps:
      - uses: actions/checkout@v4
      - uses: ./.github/actions/lint
  stage-3-typecheck:
    runs-on: windows-latest
    needs: [stage-2-lint]
    steps:
      - uses: actions/checkout@v4
      - uses: ./.github/actions/typecheck
  stage-4-architecture:
    runs-on: windows-latest
    needs: [stage-3-typecheck]
    steps:
      - uses: actions/checkout@v4
      - uses: ./.github/actions/architecture
  stage-5-test:
    runs-on: windows-latest
    needs: [stage-4-architecture]
    steps:
      - uses: actions/checkout@v4
      - uses: ./.github/actions/test
  stage-6-contract:
    runs-on: windows-latest
    needs: [stage-5-test]
    steps:
      - uses: actions/checkout@v4
      - uses: ./.github/actions/contract
  stage-7-integration:
    runs-on: windows-latest
    needs: [stage-6-contract]
    steps:
      - uses: actions/checkout@v4
      - uses: ./.github/actions/integration
  secret-scan:
    runs-on: windows-latest
    env:
      GH_TOKEN: ${{ github.token }}
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - name: Install gitleaks
        shell: pwsh
        run: |
          $bin = & .github/scripts/install-gitleaks.ps1
          "GITLEAKS_BIN=$bin" | Out-File -FilePath $env:GITHUB_ENV -Append
      - name: Scan PR diff
        shell: pwsh
        run: |
          & $env:GITLEAKS_BIN detect --no-banner --redact --config=.gitleaks.toml --log-opts="origin/${{ github.base_ref }}..HEAD"
```

Observation: existing workflow already has `stage-1-format` ... `stage-7-integration` for the TypeScript scaffold. P10 will introduce parallel/sequenced .NET-specific stages named `stage-1-dotnet-format` through `stage-5-dotnet-test` per the plan.
