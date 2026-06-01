---
name: no-required-checks-configured-on-main
description: As of 2026-06-01, gh pr checks --required returns empty on TMW; S9 must derive ci_gate from the full PR Pipeline run instead.
metadata:
  type: project
---

As of 2026-06-01, `gh pr checks 47 --required` returned "no required checks
reported on the branch" for TMW PRs against `main`. Branch protection does not
currently have required status-check contexts configured (the README documents
that an admin must add them, and they only appear in the picker after the new
reusable-workflow pipeline has produced at least one run).

**Why:** The pipeline was refactored to reusable workflows, which change the
status-check context names to the nested `caller / callee` form (e.g.
`tier-classification / tier-classification`). `apply-branch-protection.ps1` and
its test still assert the older flat names (`tier-classification`, etc.), so the
required-check set on `main` has not been reconciled.

**How to apply:** During the orchestrator S9 CI green gate,
`scripts/orchestration/Invoke-CiGateParser.ps1` throws on an empty
`--required` list. Fall back to parsing the full `gh pr checks <n> --json
name,state,bucket,workflow,link` output (all PR Pipeline checks) to derive
`ci_gate.conclusion`. Verify against the live PR head SHA. Configuring required
contexts on `main` is an admin task; flag it as a follow-up rather than a
blocker. Re-verify this state before relying on it — it may change once an admin
reconciles the contexts. Related: [[project_no_bundled_workflow_mirrors]].
