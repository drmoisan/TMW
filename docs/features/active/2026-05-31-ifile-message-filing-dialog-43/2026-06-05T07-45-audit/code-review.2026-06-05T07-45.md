# Code Review: iFile Message-Filing Dialog (#43) — Cycle 3 Reaudit

**Review Date:** 2026-06-05
**Exit Timestamp:** 2026-06-05T07-45
**Feature Folder:** `docs/features/active/2026-05-31-ifile-message-filing-dialog-43`
**Base Branch:** `main`
**Head Branch:** `feature/ifile-message-filing-dialog-43`
**Open PR:** #44
**Work Mode:** `full-feature`
**Review Type:** Post-remediation code review (cycle 3)
**Authoritative inputs:** `remediation-inputs.2026-06-05T07-36.md`
**Executed plan:** `remediation-plan.2026-06-05T07-36.md` (6 tasks, all checked)

---

## Scope

Cycle-3 changed surface, confirmed via `git diff`:

1. `.gitleaks.toml` (repo root) — one `regexes` entry added to the existing `[allowlist]` block; the
   block `description` was updated; a five-line reason comment was added above the new entry.
2. Evidence artifacts under
   `docs/features/active/2026-05-31-ifile-message-filing-dialog-43/evidence/` (qa-gates and
   remediation-baseline).

No programming-language source changed this cycle. There is no TypeScript, C#, Python, or PowerShell
delta. Confirmed via `git diff` and `git status --short`: the only tracked working-tree modification
outside the evidence/doc tree is `.gitleaks.toml`. (The session-start working-tree edits to
`src/TaskMaster.Api/Program.cs`, `TaskMaster.Api.csproj`, and `README.md` are pre-existing and not
cycle-3 deliverables; they are reviewed for regression only and are unchanged by this cycle.)

The audit scope is the full branch diff against the resolved base branch. No scope narrowing was
attempted by the caller. The cycle-3 change footprint is genuinely a single config file plus evidence.

---

## The Change Under Review

`.gitleaks.toml` working-tree diff (verified):

```toml
[allowlist]
-description = "Allowlist for documentation and test fixtures"
+description = "Allowlist for documentation, test fixtures, and the published dotnet UserSecretsId"
 paths = [
   '''(?i)docs/.*\.md''',
   '''(?i)\.gitleaks\.toml''',
   '''(?i)docs/features/.*'''
 ]
+# The value below is the dotnet UserSecretsId, a non-secret project identifier that names
+# where user-secrets are stored on disk. It is committed by design in
+# src/TaskMaster.Api/TaskMaster.Api.csproj and is documented in the repo-root README. It is
+# not a credential. This regex allowlists only that specific published GUID, so generic-api-key
+# and all other default and custom rules continue to scan every other value in the repository.
+regexes = [
+  '''b3c44e17-fca8-45e2-a550-80f2d481007e'''
+]
```

---

## Narrowest-Scope Assessment (CR-1)

The change is the narrowest defensible scope for clearing the false positive. Each weakening
alternative was checked against the final config and confirmed NOT taken:

| Property checked | Required state | Observed state | Verdict |
|---|---|---|---|
| `[extend].useDefault` | remains `true` | `true` (line 7, unchanged) | PASS |
| `generic-api-key` rule disabled globally | NOT disabled | not disabled/removed/overridden anywhere | PASS |
| Repo-root `README.md` added to `paths` | NOT added | `paths` unchanged (`docs/.*\.md`, `.gitleaks.toml`, `docs/features/.*`) | PASS |
| Custom rule `graph-client-secret` | active | present and unchanged (lines 9-13) | PASS |
| Custom rule `office-addin-shared-key` | active | present and unchanged (lines 15-19) | PASS |
| Allowlist entry breadth | only the specific GUID | single literal GUID `b3c44e17-fca8-45e2-a550-80f2d481007e` | PASS |
| Number of `[allowlist]` blocks | exactly one | one (no second block added) | PASS |

The allowlisted value is a single fixed GUID literal. It is not a regex shape (such as a generic
`secretsId = "<guid>"` assignment pattern) that could match unrelated future values; it matches only
the one published identifier. This is the tightest form available in gitleaks' allowlist mechanism.

---

## Negative-Control Verification (CR-2)

The reviewer independently re-ran gitleaks against the final config (the reviewer's Bash profile
permitted the run in this session). Two checks:

1. **Authoritative repository scan** —
   `gitleaks detect --no-banner --config=.gitleaks.toml --log-opts="origin/main..HEAD"`:
   `6 commits scanned`, `no leaks found`, exit 0.

2. **Negative control (unrelated secret still detected)** — a synthetic probe file outside the repo
   tree containing three lines (an `api_key = "<32-char high-entropy>"`, an AWS-style key, and the
   allowlisted `UserSecretsId` GUID) was scanned with the final config. gitleaks reported
   `leaks found: 1` (exit 1), flagging the unrelated `api_key` line via `generic-api-key`, while the
   allowlisted GUID line was NOT reported.

The executor's negative-control claim (evidence `gitleaks-scope-check.2026-06-05T07-36.md`) is sound
and is independently reproduced. An unrelated secret would still be detected; the allowlist suppresses
only the one non-secret GUID.

---

## Non-Secret Confirmation (CR-3)

The allowlisted value is genuinely a non-secret, so the fix does not mask a real leak:

- `src/TaskMaster.Api/TaskMaster.Api.csproj` line 6 contains
  `<UserSecretsId>b3c44e17-fca8-45e2-a550-80f2d481007e</UserSecretsId>` (verified via
  `git show HEAD:...`). A dotnet `UserSecretsId` is the name of the on-disk location where the
  developer's user-secrets are stored; it is committed by design and is not itself a credential.
- The repo-root `README.md` documents the same GUID in a setup snippet
  (`$secretsId = "b3c44e17-fca8-45e2-a550-80f2d481007e"   # project UserSecretsId`), which is the form
  that the `generic-api-key` assignment pattern matched.
- No actual credential is committed. A targeted search for committed client-secret literals found
  only `tests/e2e/auth.setup.ts:68` (`client_secret: env.AZURE_CLIENT_SECRET`, read from an
  environment variable — not a literal) and synthetic example secrets inside archived audit documents.
  No real `AzureAd:ClientSecret` value is present in the working tree.

---

## Tonality and Minimalism (CR-4)

| Check | Status | Evidence |
|---|---|---|
| Change is minimal | PASS | Single config file; one allowlist entry; one description edit; one comment block. |
| Reason comment present | PASS | Five-line comment states the value is a non-secret `UserSecretsId` and references the csproj. |
| Professional tone | PASS | Comment is factual and neutral; no hyperbole, humor, or metaphor. |
| Valid TOML | PASS | File parses; gitleaks consumed it successfully (exit 0). |
| File-size policy | PASS | `.gitleaks.toml` is 35 lines, well under the 500-line limit; config files are exempt regardless. |

---

## General Code-Change Policy (config change)

- **Simplicity first:** PASS — the simplest sufficient fix; no rule surgery.
- **Error handling / fail-fast:** N/A — config file, no runtime control flow.
- **No silent suppression of real defects:** PASS — the suppression is scoped to a verified non-secret;
  detection of all other values is preserved (negative control above).
- **Dependencies:** N/A — no dependency change.

---

## Findings

- **CR-1 (PASS):** Allowlist is the narrowest defensible scope. `useDefault=true` retained; both
  custom rules retained; `generic-api-key` not disabled; `README.md` not added to `paths`; entry is a
  single GUID literal.
- **CR-2 (PASS):** gitleaks reports 0 leaks / exit 0 on the branch range (reviewer-reproduced).
  Negative control confirms unrelated secrets are still detected.
- **CR-3 (PASS):** The allowlisted value is a non-secret dotnet `UserSecretsId` (confirmed in csproj);
  no real credential is committed anywhere in the working tree.
- **CR-4 (PASS):** Change is minimal, commented, valid TOML, and tonality-compliant.

No best-practice or quality concerns identified for the cycle-3 change.

---

## Verdict

**Overall: PASS.** The cycle-3 `.gitleaks.toml` change is a correct, minimal, narrowly scoped
allowlist of a verified non-secret identifier. No detection capability is weakened.

### Verdict Counts
- FAIL findings: **0**
- Blocking-PARTIAL findings: **0**
- code-review blocking_count = **0**
