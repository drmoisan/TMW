# Baseline — pr-pipeline.yml job inventory

Timestamp: 2026-05-18T10-15
Source: .github/workflows/pr-pipeline.yml (sha256 4256CA20AAC94C06F5E1B42D43875F8D433E97EB0E1AF44C54059D2427B36E46)
Output Summary: 17 jobs catalogued.

| # | Job ID | runs-on | needs | if | env | secrets | Step count | Target callee filename |
|---|---|---|---|---|---|---|---|---|
| 1 | tier-classification | windows-latest | (none) | (none) | (none) | (none) | 2 | _tier-classification.yml |
| 2 | stage-1-format | windows-latest | [tier-classification] | (none) | (none) | (none) | 2 | _stage-1-format.yml |
| 3 | stage-2-lint | windows-latest | [stage-1-format] | (none) | (none) | (none) | 2 | _stage-2-lint.yml |
| 4 | stage-3-typecheck | windows-latest | [stage-2-lint] | (none) | (none) | (none) | 2 | _stage-3-typecheck.yml |
| 5 | stage-4-architecture | windows-latest | [stage-3-typecheck] | (none) | (none) | (none) | 2 | _stage-4-architecture.yml |
| 6 | stage-5-test | windows-latest | [stage-4-architecture] | (none) | (none) | (none) | 2 | _stage-5-test.yml |
| 7 | stage-6-contract | ubuntu-latest | [stage-5-test] | (none) | (none) | (none) | 3 (checkout w/ fetch-depth:0, contract, schema-contract) | _stage-6-contract.yml |
| 8 | stage-7-integration | windows-latest | [stage-6-contract] | (none) | (none) | (none) | 2 | _stage-7-integration.yml |
| 9 | stage-1-dotnet-format | windows-latest | [tier-classification] | (none) | (none) | (none) | 2 | _stage-1-dotnet-format.yml |
| 10 | stage-2-dotnet-build | windows-latest | [stage-1-dotnet-format] | (none) | (none) | (none) | 2 | _stage-2-dotnet-build.yml |
| 11 | stage-3-dotnet-typecheck | windows-latest | [stage-2-dotnet-build] | (none) | (none) | (none) | 2 (checkout + inline pwsh Write-Host explainer) | _stage-3-dotnet-typecheck.yml |
| 12 | stage-4-dotnet-architecture | windows-latest | [stage-3-dotnet-typecheck] | (none) | (none) | (none) | 2 | _stage-4-dotnet-architecture.yml |
| 13 | stage-5-dotnet-test | windows-latest | [stage-4-dotnet-architecture] | (none) | (none) | (none) | 2 | _stage-5-dotnet-test.yml |
| 14 | stage-e2e-smoke | ubuntu-latest | [stage-7-integration] | contains(github.event.pull_request.labels.*.name, 'e2e:run') | step-level env on Run Playwright step | AZURE_TENANT_ID, AZURE_CLIENT_ID, AZURE_CLIENT_SECRET, E2E_API_BASE_URL | 5 (checkout, setup-node, npm ci, playwright install, playwright test) | _stage-e2e-smoke.yml |
| 15 | stage-10-benchmark-regression | windows-latest | [stage-7-integration] | (none) | (none) | (none) | 5 (checkout, setup-dotnet, run benchmarks, enrich, upload-artifact `if: always()`, compare) | _stage-10-benchmark-regression.yml |
| 16 | benchmark-gate-self-validation | windows-latest | [stage-7-integration] | (none) | (none) | (none) | 3 (checkout, setup-dotnet, self-validation pwsh block ending in `exit 0`) | _benchmark-gate-self-validation.yml |
| 17 | secret-scan | windows-latest | (none — runs in parallel with tier-classification) | (none) | top-level `GH_TOKEN: ${{ github.token }}` | (none — uses github.token) | 3 (checkout w/ fetch-depth:0, install-gitleaks, scan PR diff) | _secret-scan.yml |

Notes:
- Step counts include `actions/checkout@v4` as a step.
- `stage-10-benchmark-regression` step count of 5 reflects (checkout, setup-dotnet, run, enrich, upload-artifact, compare) = 6 step entries; the upload-artifact step uses `if: always()`.
- Correction: stage-10 step count is 6.
- All jobs begin with `actions/checkout@v4`; no `download-artifact`; only one `upload-artifact` (stage-10).
- `needs:` graph forms two parallel chains rooted at `tier-classification` (lint/test chain and dotnet chain), plus `secret-scan` standalone and three jobs branching from `stage-7-integration` (e2e-smoke, stage-10, self-validation).
