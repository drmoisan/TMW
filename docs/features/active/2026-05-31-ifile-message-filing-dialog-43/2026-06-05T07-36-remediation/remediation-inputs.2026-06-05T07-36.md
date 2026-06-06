# Remediation Inputs — iFile Message-Filing Dialog (#43)

- Cycle: 3
- Entry timestamp: 2026-06-05T07-36
- Author: orchestrator
- Feature folder: `docs/features/active/2026-05-31-ifile-message-filing-dialog-43`
- Branch: `feature/ifile-message-filing-dialog-43`
- Open PR: #44
- Trigger class: required CI check failing after the PR is open (`secret-scan` / gitleaks) on PR Pipeline run 27012265573 (head `2d9e9b5`).

## 1. Failing Check

`secret-scan / secret-scan` failed: `gitleaks detect --redact --config=.gitleaks.toml --log-opts="origin/main..HEAD"` reported `leaks found: 1`, exit 1. All other stages on run 27012265573 passed (format, lint, typecheck TS+.NET, both architecture stages, Vitest, .NET tests, contract, integration, tier-classification; e2e-smoke skipped).

## 2. Root Cause (reproduced locally, gitleaks 8.30.1)

Single finding, a false positive on a non-secret identifier:

- Rule: `generic-api-key` (gitleaks default ruleset)
- File: `README.md` (repo root), current line 153: `$secretsId = "b3c44e17-fca8-45e2-a550-80f2d481007e"   # project UserSecretsId (from TaskMaster.Api.csproj)`
- The value `b3c44e17-fca8-45e2-a550-80f2d481007e` is the dotnet **`UserSecretsId`** — a non-secret project identifier that names *where* user-secrets are stored (committed by design in `src/TaskMaster.Api/TaskMaster.Api.csproj` line 6). It is not a credential.
- It trips `generic-api-key` because the text `secretsId = "<high-entropy-guid>"` matches the rule's assignment pattern. The XML `<UserSecretsId>…</UserSecretsId>` form in the csproj does not match, so only the README assignment form is flagged.
- The repo `.gitleaks.toml` allowlist covers `docs/**/*.md` and `docs/features/**`, but **not** the repo-root `README.md`, so the README setup docs are scanned.
- The underlying line is attributed to commit `89f8381` (a pre-existing "docs: updated README" commit already on the branch before this remediation); the branch's prior PR Pipeline runs were already failing secret-scan. The fix commit `2d9e9b5` restructured that README section, so the line is in the PR diff range.

This is not a real secret leak. No credential is exposed. The `AzureAd:ClientSecret` is never written to any committed file (confirmed in cycles 1-2).

## 3. Scope for This Cycle

In scope:
- Make `secret-scan` pass on the branch head by allowlisting the `UserSecretsId` non-secret in `.gitleaks.toml`. Prefer the narrowest defensible option that does not weaken real secret detection. Candidate approaches (planner/executor to choose, feature-review to validate):
  1. Narrowest — an `[allowlist]` `regexes` (or `stopwords`) entry matching the specific non-secret GUID `b3c44e17-fca8-45e2-a550-80f2d481007e` (it is a published, non-secret UserSecretsId), and/or a regex for the `UserSecretsId`/`secretsId = "<guid>"` assignment shape.
  2. Add the repo-root `README.md` to the allowlist `paths`. Broader: this would stop scanning the entire root README, which could mask a future real secret there. Use only if option 1 is not viable.
- Verify locally that `gitleaks detect --config=.gitleaks.toml --log-opts="origin/main..HEAD"` reports 0 leaks after the change, and that no other secret-detection coverage is lost.

Out of scope: any change to actual secret handling (the client secret remains user-secrets/environment only); the iFile feature code (cycles 1-2, already GO); production-domain substitution; the CI coverage-merge follow-up (CI-COV-1).

## 4. Constraints

- `.gitleaks.toml` is at repo root — it is NOT under `.github/workflows/**`, `scripts/benchmarks/**`, or `.github/actions/**`, so the `modified-workflow-needs-green-run` policy rule does not fire for this change (confirmed against `.claude/skills/feature-review-workflow/SKILL.md`). No green-run evidence prerequisite applies; nevertheless the orchestrator will re-run CI after the fix and confirm `secret-scan` green.
- Do not broaden the allowlist further than needed; do not disable the `generic-api-key` rule globally; do not add `useDefault = false`.
- Tonality and file-policy rules apply. `.gitleaks.toml` is a small config edit; keep it minimal and commented with the reason.

## 5. Exit Criteria for This Cycle

- `gitleaks detect --config=.gitleaks.toml --log-opts="origin/main..HEAD"` reports 0 leaks locally; the allowlist change is minimal and targeted to the `UserSecretsId` non-secret.
- The three end-of-cycle reaudit artifacts report `blocking_count == 0`.
- After push, PR Pipeline `secret-scan` passes on the new branch head and the full pipeline is green (orchestrator verifies post-cycle).

## 6. Handoff

Next delegate: `atomic-planner` — author `remediation-plan.2026-06-05T07-36.md` against this inputs file per the `atomic-plan-contract`. The plan is a small, single-file `.gitleaks.toml` allowlist change plus a local gitleaks re-scan verification task. The orchestrator delegates only to atomic-planner → atomic-executor → feature-review; `atomic-executor` performs the edit while executing the approved plan.
