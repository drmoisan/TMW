---
name: project-ifile-43
description: iFile message-filing dialog (#43) — NAA token path, dual desktop/mobile manifests, human-gated Entra ACs
metadata:
  type: project
---

The iFile message-filing feature (issue #43, PR #44, branch `feature/ifile-message-filing-dialog-43`) is a full-feature (`full-feature` work mode) Outlook add-in feature with desktop+mobile parity. AC sources are `spec.md` (AC-1..AC-24) and `user-story.md`.

**NAA token path (cycle 2):** The client token path is nested app authentication (NAA) via `@azure/msal-browser`, not legacy `Office.auth.getAccessToken` (which is unsupported on Outlook iOS — `IdentityAPI 1.3` is not in the iOS requirement-set matrix; `NestedAppAuth 1.1` is). MSAL is imported by exactly one module, `src/taskpane/ifile/naa-token-acquirer.ts`, enforced by the depcruise rule `ifile-pure-modules-no-host-deps` in `.dependency-cruiser.cjs`. Token acquisition is kept behind an injected `TokenAcquirer` seam so the `bootstrap` function in `ifile.ts` stays Office-free and MSAL-free.

**Human-gated ACs:** AC-2, AC-3, AC-11, AC-12, AC-13, AC-19, AC-20, AC-21, AC-24 are gated on three declared human-execution exceptions: HI-1 (Entra admin consent), HI-2 (mobile build + on-device re-verification), HI-3 (Entra app NAA+OBO config). These gate feature DONE, not cycle exit. The Entra config and client secret are correctly NOT committed; manifests carry only non-secret identifiers (client ID `2921bc0b-...`, App ID URI, tenant ID, Dev Tunnel hosts). Runbooks live under `<feature>/runbooks/`.

**Coverage gotcha:** The repo-wide C# coverage artifact `artifacts/csharp/coverage.xml` reports ~22% line / ~8% branch because `TaskMaster.Infrastructure` (~10%) and `TaskMaster.Application` (~19%) Graph adapters / filing workflow are not all reflected in the default coverage collection (likely integration-gated tests). When a C# file changes (even T4 DI wiring in `Program.cs`), this drags the mandatory repo-wide C# coverage verdict to FAIL even though the changed lines themselves are well-covered. **Why:** the coverage-verification procedure treats repo-wide < 80% as a FAIL trigger and the scope invariant forbids waiving a language with changed files. **How to apply:** to clear it, run the FULL backend suite (incl. integration/Graph adapter tests) before judging C# coverage, or record the shortfall as a pre-existing tracked backend item. See [[project-tmw-context]].

**Audit artifact schema:** The three reaudit artifacts MUST conform to bundled templates (validate with `validate_orchestration_artifacts`). policy-audit requires headings `## Executive Summary`, `## 1`..`## 7`, `## Appendix A: Test Inventory`, `## Appendix B: Toolchain Commands Reference`, the Coverage Evidence Checklist lines (TypeScript/PowerShell baseline+post-change), and per-language comparison bullets in the exact form `Baseline: N% -> Post-change: N%. Change: +/-N%. New/changed-code coverage: N%. Disposition: PASS/FAIL. Evidence: ...`. feature-audit requires `## Acceptance Criteria Check-off` (lowercase "off"). code-review requires `## Executive Summary` + `## Findings Table`.

**Validator-vs-template heading mismatch (confirmed 2026-06-06):** The bundled feature-audit template ships the heading as `## Acceptance Criteria Check-Off` (capital O), but `validate_orchestration_artifacts` for `feature-audit` rejects that and requires `## Acceptance Criteria Check-off` (lowercase o). Copy the template heading, then lowercase the second "off" before validating. Always run `validate_orchestration_artifacts` on all three reaudit artifacts before returning.
