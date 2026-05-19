---
Timestamp: 2026-05-18T23-10
Command: Edit .github/actions/dotnet-test/action.yml; Get-Content .github/actions/dotnet-test/action.yml | Select-String 'benchmark-gate-self-validation'; ConvertFrom-Yaml on file contents
EXIT_CODE: 0
Output Summary: Removed multi-line comment block (lines 17-21) and `--filter "Category!=benchmark-gate-self-validation"` argument from dotnet test command. Grep `benchmark-gate-self-validation` returns 0 matches. YAML parses cleanly via powershell-yaml ConvertFrom-Yaml (YAML_PARSE=OK).
---

## Diff

Before (lines 16-23):
```yaml
    - name: dotnet test (with coverage)
      # Excludes the `benchmark-gate-self-validation` category (Issue #23):
      # those tests assert the comparator/idempotency-base-class gate fires
      # against synthetic fixtures and a deliberately non-idempotent handler.
      # They are exercised only by the dedicated `benchmark-gate-self-validation`
      # job, which inverts the inner exit codes to prove the gate works.
      shell: pwsh
      run: dotnet test TaskMaster.sln --collect:"XPlat Code Coverage" --no-build --results-directory TestResults/ --filter "Category!=benchmark-gate-self-validation"
```

After:
```yaml
    - name: dotnet test (with coverage)
      shell: pwsh
      run: dotnet test TaskMaster.sln --collect:"XPlat Code Coverage" --no-build --results-directory TestResults/
```

## Verification

- `Get-Content .github/actions/dotnet-test/action.yml | Select-String 'benchmark-gate-self-validation'` -> 0 matches.
- `Get-Content -Raw | ConvertFrom-Yaml` -> YAML_PARSE=OK (composite action remains a valid YAML document).
- actionlint was not used because actionlint treats action.yml as a workflow file (missing `jobs:` / `on:` keys) and produces false-positive syntax-check errors; powershell-yaml ConvertFrom-Yaml is the appropriate parser for composite-action YAML and is what the plan task contemplates as the alternative.
