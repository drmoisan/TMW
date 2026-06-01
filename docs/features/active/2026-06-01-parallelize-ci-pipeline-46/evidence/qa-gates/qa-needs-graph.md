# QA Post-Change `needs:` Graph — pr-pipeline.yml

Timestamp: 2026-06-01T14-06
Command: Read .github/workflows/pr-pipeline.yml and confirm each job key's `needs:` value against the required end-state
EXIT_CODE: 0

Output Summary: All 15 job keys are unchanged from baseline (no rename). The
post-change `needs:` graph matches the required end-state exactly:

Root gate:
- `tier-classification` — no `needs:` (single root). MATCH.

Twelve gate jobs each `needs: [tier-classification]`:
- `stage-1-format` — needs: [tier-classification]. MATCH.
- `stage-2-lint` — needs: [tier-classification]. MATCH.
- `stage-3-typecheck` — needs: [tier-classification]. MATCH.
- `stage-4-architecture` — needs: [tier-classification]. MATCH.
- `stage-5-test` — needs: [tier-classification]. MATCH.
- `stage-6-contract` — needs: [tier-classification]. MATCH.
- `stage-7-integration` — needs: [tier-classification]. MATCH.
- `stage-1-dotnet-format` — needs: [tier-classification]. MATCH.
- `stage-2-dotnet-build` — needs: [tier-classification]. MATCH.
- `stage-3-dotnet-typecheck` — needs: [tier-classification]. MATCH.
- `stage-4-dotnet-architecture` — needs: [tier-classification]. MATCH.
- `stage-5-dotnet-test` — needs: [tier-classification]. MATCH.

E2E smoke:
- `stage-e2e-smoke` — needs: [tier-classification]; if: contains(github.event.pull_request.labels.*.name, 'e2e:run'); uses: ./.github/workflows/_stage-e2e-smoke.yml; secrets: inherit. MATCH (re-parented; guard, callee, and secrets preserved).

Secret scan:
- `secret-scan` — no `needs:`, no `if:` (runs unconditionally). MATCH.

No serial per-language lane edge remains. The orchestrator still contains zero
inline `steps:`; every job is a `uses:` reference. Reusable-workflow nesting depth
remains one level. No `_*.yml` callee was added, removed, or modified.
