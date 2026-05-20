# Policy Compliance Audit — orchestration-missing-ci-green-gate (Issue #26)

- Component: orchestration-missing-ci-green-gate (CI-green PR gate, S9, and supporting policy rules)
- Date: 2026-05-19T22-11
- Reviewer: feature-review agent
- Work Mode: full-bug (AC source: spec.md, AC1..AC15)
- Base branch (resolved): main @ b25e678bd82312301eaad971b1a04173915e2314
- Head SHA: cdba24d9ea33bd2901c88be9745331eb178a9b5d
- Branch: feature/orchestration-missing-ci-green-gate-26
- PR context: artifacts/pr_context.summary.txt, artifacts/pr_context.appendix.txt

## Executive Summary

The branch delivers the issue #26 fix: a new orchestrate `S9_ci_green` step, an extended checkpoint schema, a fifth PR Creation Gate condition, CI-failure remediation handling, the feature-review policy rule `modified-workflow-needs-green-run`, two new repo rule files, three PowerShell validators, and Pester coverage for the validators. The branch diff touches PowerShell (3 production scripts, 4 test files) and Markdown/docs only. No Python, TypeScript, or C# files changed.

The local toolchain results were independently re-verified by this review: PSScriptAnalyzer reports 0 findings across all 7 changed PowerShell files; 26 Pester tests pass; formatter reports no drift; new-code line coverage is 100% (96/96 commands, 0 missed), independently re-measured. These results are PASS.

One Blocking policy finding is present and is intrinsic to the feature: the branch diff adds `scripts/benchmarks/Test-BaselineProvenance.ps1`, which matches the `scripts/benchmarks/**` trigger glob of the very `modified-workflow-needs-green-run` rule this branch introduces. The rule therefore fires on this branch, and no green workflow run (PR-context or workflow_dispatch) against the head SHA is present. This is consistent with AC15 being deferred to the orchestrator's post-handoff S9 lifecycle. The Blocking finding is recorded and routed to remediation inputs as the rule prescribes; resolution is a green run against the head SHA, not a code change.

Overall verdict: PARTIAL. AC1..AC14 are satisfied; AC15 is unmet (deferred by construction). The `modified-workflow-needs-green-run` rule emits one Blocking finding that can only be cleared by a green run against the head SHA.

## 1. General Unit Test Policy Compliance

Status: PASS

- Independence/Isolation/Determinism: Tests use a `NowProvider` clock seam (parser) and a pure-logic content seam plus mocked `Test-Path`/`Get-Content` (provenance) so no temp files are created and no wall-clock or filesystem dependency is introduced. This complies with `.claude/rules/general-unit-test.md` (no temp files, controllable clock, determinism).
- Scenario completeness: parser tests cover positive (all-pass), negative (fail, cancel, in-progress), edge (single-object normalization, unknown bucket), determinism (clock seam), and error paths (malformed JSON, empty list). Provenance tests cover the three required scenarios plus partial-field, malformed-provenance, malformed-baseline, and the Path parameter set.
- AAA structure and descriptive names: present throughout.
- Banned APIs (`Start-Sleep`, real waits): none observed in changed test files.

Evidence: tests/pester/orchestration/CiGate.Parser.Tests.ps1; tests/pester/benchmarks/BaselineProvenance.Tests.ps1; tests/pester/feature-review/ModifiedWorkflowNeedsGreenRun.Tests.ps1; tests/pester/orchestration/S9CiGreen.Integration.Tests.ps1. Independent run: 26 passed / 0 failed.

## 2. General Code Change Policy Compliance

Status: PASS

- Simplicity and separation of concerns: each validator is a single-purpose advanced script; the parser separates pure derivation logic from `gh` invocation (it accepts JSON text), the provenance validator exposes a pure-logic seam separate from the file-reading wrapper. This matches the I/O-boundary and seam guidance in `.claude/rules/general-code-change.md` and `.claude/rules/powershell.md`.
- Error handling: scripts use `throw` with specific messages for malformed JSON and empty input; `$ErrorActionPreference = 'Stop'` and `Set-StrictMode -Version Latest` are set. No broad catch-all that swallows errors.
- File size: all changed files are well under the 500-line limit (largest production script is 114 lines).
- Naming and approved verbs: `Invoke-CiGateParser`, `Test-BaselineProvenance`, `Test-ModifiedWorkflowNeedsGreenRun` use approved verbs and descriptive nouns.
- Dependencies: no new external dependencies introduced.

Evidence: scripts/orchestration/Invoke-CiGateParser.ps1; scripts/benchmarks/Test-BaselineProvenance.ps1; scripts/feature-review/Test-ModifiedWorkflowNeedsGreenRun.ps1.

## 3. Language-Specific Code Change Policy Compliance

### PowerShell — Status: PASS

- Format (Invoke-Formatter): re-verified, no drift on the three production scripts. Command: `Invoke-Formatter -ScriptDefinition <content>` per file; result FORMAT_CLEAN.
- Lint (PSScriptAnalyzer): re-verified, 0 findings across all 7 changed PowerShell files. Command: `Invoke-ScriptAnalyzer -Path <file>` per file; result COUNT=0.
- Type checking: not applicable for PowerShell per `.claude/rules/powershell.md`.
- Coding standards: `CmdletBinding()`, mandatory/typed parameters, no `Invoke-Expression`, no plaintext secrets, no global mutable state. The seam design follows the wrapper/injectable-delegate pattern (`NowProvider` scriptblock seam; `-BaselineContent`/`-ProvenancePresent` content seam).
- PowerShell 7+ compatibility: `#Requires -Version 7.0` declared in every script and test.

### Python / TypeScript / C# — Status: N/A

No Python, TypeScript, or C# files changed in the branch diff. N/A is the correct verdict for these languages because they have zero changed files on the branch.

## 4. Language-Specific Unit Test Policy Compliance

### PowerShell — Status: PASS

- Pester v5.x, `*.Tests.ps1` naming, Describe/Context/It one-behavior-per-It structure, mirror of code structure under tests/pester/.
- Mocking rules: the provenance Path-set tests mock `Test-Path`/`Get-Content` (filesystem adapters) rather than mocking executables; no `git`/`gh` executable is mocked directly. The parser is exercised by passing JSON text, so `gh` is never invoked.

Evidence: independent Pester run, 26 tests passed.

## 5. Test Coverage Detail

Status: PASS (PowerShell)

PowerShell is the only language with changed production code; coverage verdict is explicit PASS.

- Coverage artifact: artifacts/pester/feature26-coverage.xml (JaCoCo format, feature-scoped).
- Repo-wide PowerShell suite (pre-existing): 91.75% line over the pre-existing covered files; no regression (58/58 tests).
- New-code (this feature's three production scripts), independently re-measured by this review:
  - scripts/orchestration/Invoke-CiGateParser.ps1
  - scripts/benchmarks/Test-BaselineProvenance.ps1
  - scripts/feature-review/Test-ModifiedWorkflowNeedsGreenRun.ps1
  - Result: 96/96 commands executed, 0 missed = 100% line coverage. >= 85% threshold met.
- Branch coverage: Pester's JaCoCo export emits no discrete BRANCH counter (verified: 0 BRANCH counters in feature26-coverage.xml). Effective branch coverage is treated as satisfied because every conditional in the three scripts has explicit both-arm tests (fail/cancel/pending/unknown buckets, single-object normalization, present/absent provenance, each required field, malformed inputs). Verdict: PASS for the >= 75% branch threshold, with the measurement caveat that the tool does not emit a numeric branch counter.

Command (independent re-measure): `Invoke-Pester` with `CodeCoverage.Path` = the three production scripts; reported PCT=100, MISSED=0.

Languages with zero changed files (Python, TypeScript, C#): coverage N/A — acceptable because they have no changed files on the branch.

## 6. Test Execution Metrics

- PowerShell (independent run, this review): 26 tests, 26 passed, 0 failed, 0 skipped, ~1.26 s.
- Executor-recorded repo suite: 58/58 pre-existing Pester tests passing, no regression (evidence/qa-gates/p7-t5-unit.md, p7-t9-coverage-delta.md).

## 7. Code Quality Checks

- Formatting: PASS (no drift).
- Lint: PASS (0 PSScriptAnalyzer findings).
- Type check: N/A (PowerShell).
- Architecture-boundary: not applicable to standalone PowerShell scripts; no architecture test target exists for this scope (evidence/qa-gates/p7-t4-arch.md).
- Contract/schema: the checkpoint schema is documented in the orchestrate SKILL; no JSON-schema file exists under schemas/ for orchestrator-state (evidence/qa-gates/p7-t6-contract.md), so contract verification is documentation-level only.

## 8. Gaps and Exceptions

1. Blocking — `modified-workflow-needs-green-run` fires on this branch. The diff adds `scripts/benchmarks/Test-BaselineProvenance.ps1`, matching the `scripts/benchmarks/**` trigger glob. No green workflow run (PR-context or workflow_dispatch) against head SHA cdba24d is present. Per the rule text the policy audit must emit a Blocking finding. Resolution path: a green run against the head SHA recorded in remediation inputs, or a green `workflow_dispatch` run against the branch head (the rule's chicken-and-egg allowance). This is the same condition AC15 captures and is expected to be cleared by the orchestrator's S9 lifecycle after the PR is opened. Routed to remediation-inputs.2026-05-19T22-11.md.

2. AC15 unmet (deferred) — No PR exists for this branch yet (PR context: "no PR exists yet"); CI status at HEAD is "not available"; orchestrator-state.json shows step9_status: "pending" with no ci_gate object. AC15 cannot be satisfied at review time and is structurally the orchestrator's S9 responsibility post-handoff. Assessed as an acceptable deferral: the S9 mechanism that AC15 exercises is implemented and tested (AC1..AC5, AC9, AC10), so AC15's deferral is a sequencing artifact, not a defect in the deliverable.

3. AC13 literal-vs-interpretation gap — AC13 text reads "Every modified or added file under `.claude/` has a synchronized bundled mirror under `.codex/`, `.agents/`, and `.github/`." The implementation synced only the mirrors that already exist (.agents/skills/orchestrate, .agents/ + .github/ for feature-review-workflow) and recorded explicit no-mirror facts for absent trees (.codex/ has no skills/ or rules/ tree; .github/ has no rules/ tree and no skills/orchestrate; .agents/ has no rules/ tree). Mirror parity for the three existing pairs is byte-identical (re-verified by SHA-256). The "python + pester mirror-contract tests" named in AC13 do not exist in this repo (no such suite found), so that clause is not demonstrable as written. This is a verification gap, not an observed parity defect. PARTIAL.

4. MCP template/validation tooling unavailable in this review environment — the workflow specifies resolving review-artifact templates and validating artifacts via `mcp__drm-copilot__resolve_policy_audit_template_asset` and `mcp__drm-copilot__validate_orchestration_artifacts`. These MCP tools are not available in this environment. Artifacts were authored using the canonical major-heading structure enumerated in the policy-audit-template-usage skill; the post-write MCP validation step is UNVERIFIED for that reason.

## 9. Summary of Changes

- 3 production PowerShell scripts (parser, provenance validator, policy-rule validator); 4 Pester test files.
- 2 modified skill files (.claude/skills/orchestrate/SKILL.md, .claude/skills/feature-review-workflow/SKILL.md) with .agents/ and (for feature-review-workflow) .github/ mirrors synced.
- 2 new rule files (.claude/rules/benchmark-baselines.md, .claude/rules/ci-workflows.md).
- Feature scoping docs and evidence artifacts under the canonical feature folder.

## 10. Compliance Verdict

PARTIAL.

- PASS: general code-change policy, general unit-test policy, PowerShell code and test policy, formatting, lint, coverage (PowerShell), test execution.
- Blocking finding: `modified-workflow-needs-green-run` (scripts/benchmarks/** match, no green-run evidence) — routed to remediation.
- PARTIAL/UNVERIFIED: AC13 mirror-contract clause (no contract test suite exists), AC15 (deferred), MCP artifact validation (tooling unavailable).

## Evidence Location Compliance

A scan of the branch diff for files written under `artifacts/baselines/`, `artifacts/qa/`, `artifacts/evidence/`, or `artifacts/coverage/` found no occurrences. All feature evidence is written under the canonical `docs/features/active/2026-05-17-orchestration-missing-ci-green-gate-26/evidence/<kind>/` layout. The repository does not contain a `validate_evidence_locations.py` script; the scan was performed via `git diff --name-only b25e678..cdba24d` path inspection. The `enforce-evidence-locations.ps1` PreToolUse hook is present at .claude/hooks/enforce-evidence-locations.ps1. Verdict: PASS (no evidence-location violations).

## Rejected Scope Narrowing

The caller note states: "Note for context (do not treat as scope narrowing): this branch's deliverable is itself the new CI-green gate ... AC15 ... can only be satisfied after a PR is opened; assess whether the implemented S9 mechanism is correct and whether AC15's deferred status is acceptable." This note explicitly disclaims scope narrowing and asks for an assessment rather than instructing the agent to drop any language's coverage or skip a check. No prohibited narrowing was detected. The full feature-vs-base audit was performed across all languages with changed files (PowerShell coverage explicitly verified). No verbatim narrowing instruction requires recording beyond this acknowledgement.

## Appendix A: Test Inventory

- tests/pester/orchestration/CiGate.Parser.Tests.ps1 — parser: positive, fail, cancel, in-progress, single-object, unknown-bucket, clock seam, malformed JSON, empty list.
- tests/pester/benchmarks/BaselineProvenance.Tests.ps1 — provenance: unknown-processor reject, missing-sibling reject, valid accept, partial-field, malformed-provenance, malformed-baseline, Path-set (3 mocked-fs cases).
- tests/pester/feature-review/ModifiedWorkflowNeedsGreenRun.Tests.ps1 — rule: workflows/benchmarks/actions trigger blocking, evidence-present non-blocking, no-trigger non-blocking.
- tests/pester/orchestration/S9CiGreen.Integration.Tests.ps1 — S9 end-to-end against fixture gh output.

## Appendix B: Toolchain Commands Reference

- Lint: `Invoke-ScriptAnalyzer -Path <each changed .ps1>` → 0 findings (COUNT=0).
- Format: `Invoke-Formatter -ScriptDefinition <content>` per production script → no drift (FORMAT_CLEAN).
- Tests: `Invoke-Pester` over tests/pester/{orchestration,benchmarks,feature-review} → 26 passed / 0 failed.
- Coverage: `Invoke-Pester` with `CodeCoverage.Path` = the three production scripts → 96/96 commands, 0 missed, 100% line.
- Rule self-check: `scripts/feature-review/Test-ModifiedWorkflowNeedsGreenRun.ps1 -ChangedFiles (git diff --name-only b25e678..cdba24d) -GreenRunEvidencePresent $false` → IsBlocking=True, MatchedPaths=scripts/benchmarks/Test-BaselineProvenance.ps1.
- Coverage artifact: artifacts/pester/feature26-coverage.xml.
