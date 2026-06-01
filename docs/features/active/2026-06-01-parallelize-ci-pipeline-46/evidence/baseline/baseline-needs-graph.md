# Baseline `needs:` Graph — pr-pipeline.yml

Timestamp: 2026-06-01T14-04
Command: Read .github/workflows/pr-pipeline.yml and enumerate each job key with its current `needs:` value
EXIT_CODE: 0

Output Summary:

15 job keys total. Two serial per-language lanes plus e2e-smoke, secret-scan, and the root gate.

Root gate:
- `tier-classification` — no `needs:` (single root)

TypeScript lane (7-job serial chain):
- `stage-1-format` — needs: [tier-classification]
- `stage-2-lint` — needs: [stage-1-format]
- `stage-3-typecheck` — needs: [stage-2-lint]
- `stage-4-architecture` — needs: [stage-3-typecheck]
- `stage-5-test` — needs: [stage-4-architecture]
- `stage-6-contract` — needs: [stage-5-test]
- `stage-7-integration` — needs: [stage-6-contract]

.NET lane (5-job serial chain):
- `stage-1-dotnet-format` — needs: [tier-classification]
- `stage-2-dotnet-build` — needs: [stage-1-dotnet-format]
- `stage-3-dotnet-typecheck` — needs: [stage-2-dotnet-build]
- `stage-4-dotnet-architecture` — needs: [stage-3-dotnet-typecheck]
- `stage-5-dotnet-test` — needs: [stage-4-dotnet-architecture]

E2E smoke (label-gated):
- `stage-e2e-smoke` — needs: [stage-7-integration]; if: contains(github.event.pull_request.labels.*.name, 'e2e:run'); uses: ./.github/workflows/_stage-e2e-smoke.yml; secrets: inherit

Secret scan:
- `secret-scan` — no `needs:` (runs unconditionally)

Confirmed: TS lane is a 7-job chain, .NET lane is a 5-job chain, stage-e2e-smoke
needs: [stage-7-integration], and secret-scan has no needs:.
