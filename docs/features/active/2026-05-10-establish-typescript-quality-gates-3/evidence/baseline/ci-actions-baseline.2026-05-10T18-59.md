Timestamp: 2026-05-10T18-59

# Baseline CI composite-action files

Output Summary: All five stage actions present with stub/no-op or conditional bodies. Phase 5 will replace format and test bodies and add setup-node + npm ci to the other three.

## .github/actions/format/action.yml
```yaml
name: Format
description: Repository format check stage. No-op until later prompts wire prettier into the TS scaffold (per Prompt A0 Phase 2 contract).
runs:
  using: composite
  steps:
    - name: Format stage (no-op)
      shell: pwsh
      run: |
        Write-Host "Format stage: no-op. Per Prompt A0, format-stage tooling will be activated in a later prompt that owns Vitest + prettier integration."
```

## .github/actions/lint/action.yml
```yaml
name: Lint
description: Repository lint stage. Scoped to existing scaffold; full ESLint config lights up in Prompt B1.
runs:
  using: composite
  steps:
    - name: ESLint (scaffold only)
      shell: pwsh
      run: |
        if (Test-Path package.json) {
          npm ci --no-audit --no-fund
          if ((Get-Content package.json -Raw) -match '"lint"\s*:') {
            npm run lint
          } else {
            Write-Host "Lint stage: no lint script defined yet; skipping (no-op)."
          }
        } else {
          Write-Host "Lint stage: no package.json present; skipping (no-op)."
        }
```

## .github/actions/typecheck/action.yml
```yaml
name: Typecheck
description: TypeScript type-check stage. Scoped to existing tsconfig; .NET nullable analysis added when backend exists.
runs:
  using: composite
  steps:
    - name: tsc --noEmit
      shell: pwsh
      run: |
        if (Test-Path tsconfig.json) {
          npm ci --no-audit --no-fund
          if ((Get-Content package.json -Raw) -match '"typecheck"\s*:') {
            npm run typecheck
          } else {
            npx tsc --noEmit
          }
        } else {
          Write-Host "Typecheck stage: no tsconfig.json; skipping (no-op)."
        }
```

## .github/actions/architecture/action.yml
```yaml
name: Architecture
description: Architecture-boundary tests stage. Wires dependency-cruiser (TS) and NetArchTest.Rules (.NET) when configs exist.
runs:
  using: composite
  steps:
    - name: dependency-cruiser (when configured)
      shell: pwsh
      run: |
        if (Test-Path .dependency-cruiser.cjs) {
          npm ci --no-audit --no-fund
          npx depcruise --config .dependency-cruiser.cjs src
        } else {
          Write-Host "Architecture stage: no .dependency-cruiser.cjs yet; skipping (no-op)."
        }
```

## .github/actions/test/action.yml
```yaml
name: Test
description: Unit + property test stage. Vitest wiring added in Prompt B1.
runs:
  using: composite
  steps:
    - name: Vitest (when wired)
      shell: pwsh
      run: |
        if ((Test-Path package.json) -and ((Get-Content package.json -Raw) -match '"test"\s*:')) {
          npm ci --no-audit --no-fund
          npm test
        } else {
          Write-Host "Test stage: no test script wired yet; skipping (no-op)."
        }
```
