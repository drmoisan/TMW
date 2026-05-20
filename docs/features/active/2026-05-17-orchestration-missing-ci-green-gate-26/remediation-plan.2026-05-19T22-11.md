# 2026-05-17-orchestration-missing-ci-green-gate (Remediation Plan)

- **Issue:** #26
- **Issue URL:** https://github.com/drmoisan/TMW/issues/26
- **Parent (optional):** none
- **Owner:** drmoisan
- **Branch:** feature/orchestration-missing-ci-green-gate-26
- **Last Updated:** 2026-05-19T22-11
- **Status:** Draft (awaiting atomic_planner expansion)
- **Version:** 0.1
- **Work Mode:** full-bug

**Fail-closed evidence rule:** Each evidence-producing task records its expected artifact path. The remediation cannot be PASS while any required green-run, mirror-parity, or AC-checkoff artifact is missing.

**Evidence location invariant:** All evidence under `docs/features/active/2026-05-17-orchestration-missing-ci-green-gate-26/evidence/<kind>/` per `.claude/skills/evidence-and-timestamp-conventions/SKILL.md`. Non-canonical `artifacts/<kind>/` paths are rejected.

**Authoritative inputs:**
- `docs/features/active/2026-05-17-orchestration-missing-ci-green-gate-26/remediation-inputs.2026-05-19T22-11.md` (authoritative spec for this plan)
- `docs/features/active/2026-05-17-orchestration-missing-ci-green-gate-26/policy-audit.2026-05-19T22-11.md`
- `docs/features/active/2026-05-17-orchestration-missing-ci-green-gate-26/feature-audit.2026-05-19T22-11.md`
- `docs/features/active/2026-05-17-orchestration-missing-ci-green-gate-26/spec.md` (AC1..AC15)

---

## Remediation Scope (to be expanded into [P#-T#] atomic tasks by atomic_planner)

### Phase R1 — Clear the CI green-run gate (Blocking finding + AC15)
- Open the PR and obtain a green PR Pipeline (or green `workflow_dispatch`) run against head SHA cdba24d9ea33bd2901c88be9745331eb178a9b5d.
- Record the `ci_gate` object and set `step9_status: passed`, `last_verified_ci_sha` to the head SHA in artifacts/orchestration/orchestrator-state.json.
- Re-run `scripts/feature-review/Test-ModifiedWorkflowNeedsGreenRun.ps1` with `-GreenRunEvidencePresent $true` and confirm `IsBlocking=$false`.
- Check off AC15 `[x]` in spec.md only after the green run against the head SHA is recorded.

### Phase R2 — Resolve AC13 mirror-contract clause
- Decide (explicit, do not guess) whether `.codex/` and the absent `.github`/`.agents` rule/skill trees are expected mirror targets.
- Either add the python + pester mirror-contract test suite named by AC13 and confirm it passes, or correct the AC13 text/scope so it does not reference a non-existent suite.
- Re-verify SHA-256 parity for every source/mirror pair after any change.

(Do-not-do constraints are inherited verbatim from remediation-inputs.2026-05-19T22-11.md.)
