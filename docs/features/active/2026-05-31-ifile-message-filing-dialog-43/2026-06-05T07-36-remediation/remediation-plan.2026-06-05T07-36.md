# Remediation Plan — iFile Message-Filing Dialog (#43), Cycle 3

- Cycle: 3
- Plan timestamp: 2026-06-05T07-36
- Author: atomic-planner
- Feature folder: `docs/features/active/2026-05-31-ifile-message-filing-dialog-43`
- Branch: `feature/ifile-message-filing-dialog-43`
- Open PR: #44
- Authoritative inputs: `docs/features/active/2026-05-31-ifile-message-filing-dialog-43/remediation-inputs.2026-06-05T07-36.md`
- Target file under change: `.gitleaks.toml` (repo root) — single config file.

## Scope and Mode

This is a minimal single-file configuration remediation. The failing required CI check
`secret-scan` (gitleaks 8.30.1) reports one false-positive finding (`generic-api-key`) on a
non-secret dotnet `UserSecretsId` GUID in the repo-root `README.md` line 153. The fix adds the
narrowest defensible allowlist entry to the existing `[allowlist]` in `.gitleaks.toml`.

Out of scope: iFile feature code (cycles 1-2 complete and GO), actual secret handling, and any
file other than `.gitleaks.toml` plus evidence artifacts under
`docs/features/active/2026-05-31-ifile-message-filing-dialog-43/evidence/`.

## Policy Notes

- `modified-workflow-needs-green-run` does NOT apply: `.gitleaks.toml` is at repo root, not under
  `.github/workflows/**`, `scripts/benchmarks/**`, or `.github/actions/**`. No green-run evidence
  prerequisite is created by this change. (Confirmed against
  `.claude/skills/feature-review-workflow/SKILL.md` in the inputs file.)
- No programming-language source is changed; there is no C#/TypeScript/Python toolchain delta, so
  the language QA loop is not applicable. The applicable verification is a local gitleaks rescan.
- Constraints from inputs: do not add `useDefault = false`; do not disable the `generic-api-key`
  rule globally; do not broadly allowlist the entire repo-root `README.md` unless the narrow
  approach is shown not to work (justify in evidence if so).

## Evidence Location

All evidence artifacts MUST be written under
`docs/features/active/2026-05-31-ifile-message-filing-dialog-43/evidence/<kind>/` per
`evidence-and-timestamp-conventions`. Baseline evidence uses `evidence/remediation-baseline/`;
verification evidence uses `evidence/qa-gates/`. Non-canonical paths (e.g., `artifacts/baselines/`,
`artifacts/qa/`) are forbidden and rejected.

---

### Phase 0 — Policy Read and Baseline Capture

- [x] [P0-T1] Read repository policy files in required order and record an evidence artifact.
  - Files to read, in order: `CLAUDE.md`, `.claude/rules/general-code-change.md`,
    `.claude/rules/general-unit-test.md`, `.claude/rules/tonality.md`,
    `.claude/rules/benchmark-baselines.md`, `.claude/rules/ci-workflows.md`,
    `.claude/skills/feature-review-workflow/SKILL.md`.
  - Write: `docs/features/active/2026-05-31-ifile-message-filing-dialog-43/evidence/remediation-baseline/phase0-instructions-read.2026-06-05T07-36.md`
  - Artifact MUST contain: `Timestamp:`, `Policy Order:`, and an explicit list of files read.
  - Acceptance: artifact exists with all three required fields populated and lists every file above.

- [x] [P0-T2] Capture the failing-baseline gitleaks scan that reproduces the false positive.
  - Precondition: gitleaks 8.30.1 is on PATH; current working directory is repo root
    `C:\Users\DanMoisan\repos\TMW`; `.gitleaks.toml` is unmodified.
  - Command: `gitleaks detect --no-banner --redact --config=.gitleaks.toml --log-opts="origin/main..HEAD"`
  - Write: `docs/features/active/2026-05-31-ifile-message-filing-dialog-43/evidence/remediation-baseline/gitleaks-baseline.2026-06-05T07-36.md`
  - Artifact MUST contain: `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:`.
  - `Output Summary:` MUST record the leak count, the rule id (`generic-api-key`), the file
    (`README.md`), and the line (153).
  - Acceptance: artifact records `EXIT_CODE: 1` and exactly one finding for rule `generic-api-key`
    on `README.md`, confirming the pre-fix failing state.

---

### Phase 1 — Apply Narrow Allowlist Entry (Delegated Implementation)

- [x] [P1-T1] Read the current `.gitleaks.toml` structure before editing.
  - Read: `C:\Users\DanMoisan\repos\TMW\.gitleaks.toml`
  - Confirm structure: `[extend]` with `useDefault = true`; two custom `[[rules]]`
    (`graph-client-secret`, `office-addin-shared-key`); one `[allowlist]` block with `description`
    and a `paths` array.
  - Acceptance: the file has been read and the single existing `[allowlist]` block is identified
    (no second allowlist will be created).

- [x] [P1-T2] Add the narrowest defensible allowlist entry for the non-secret `UserSecretsId` to the
      existing `[allowlist]` block in `.gitleaks.toml`.
  - File: `C:\Users\DanMoisan\repos\TMW\.gitleaks.toml`
  - Edit the SINGLE existing `[allowlist]` block (do not add a second `[allowlist]`). Add a
    `regexes` array (and only if necessary, a `stopwords` array) inside that block. The regex MUST
    match the specific non-secret value and/or the `UserSecretsId`/`secretsId = "<guid>"`
    assignment shape; preferred narrowest form is the specific GUID
    `b3c44e17-fca8-45e2-a550-80f2d481007e`.
  - Add a professional comment stating the value is the dotnet `UserSecretsId` (a non-secret
    project identifier), referencing `src/TaskMaster.Api/TaskMaster.Api.csproj`.
  - Constraints (all MUST hold): keep `[extend].useDefault = true`; do NOT disable or remove the
    `generic-api-key` default rule; do NOT add a `paths` entry for the entire repo-root `README.md`
    unless P2-T1 demonstrates the regex approach does not clear the finding (record justification
    in the P2-T1 evidence if that fallback is taken); keep `description` on the `[allowlist]` block
    accurate. Tonality policy applies to the comment.
  - Acceptance: `.gitleaks.toml` remains valid TOML with exactly one `[allowlist]` block; the new
    `regexes` (and optional `stopwords`) entry targets only the `UserSecretsId` non-secret; the two
    custom `[[rules]]` and `useDefault = true` are unchanged; a reason comment is present.

---

### Phase 2 — Verification (Final QC)

- [x] [P2-T1] Rerun the gitleaks scan and assert zero leaks after the allowlist change.
  - Precondition: P1-T2 complete; gitleaks 8.30.1 on PATH; working directory is repo root.
  - Command: `gitleaks detect --no-banner --config=.gitleaks.toml --log-opts="origin/main..HEAD"`
  - Write: `docs/features/active/2026-05-31-ifile-message-filing-dialog-43/evidence/qa-gates/gitleaks-verify.2026-06-05T07-36.md`
  - Artifact MUST contain: `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:`.
  - `Output Summary:` MUST record the leak count (expected 0) and confirm the prior
    `generic-api-key` / `README.md:153` finding is gone.
  - If the regex approach from P1-T2 did not clear the finding and the `paths` fallback was used,
    record an explicit justification paragraph in this artifact explaining why the narrow regex was
    not viable.
  - Acceptance: artifact records `EXIT_CODE: 0` and `no leaks found` (0 findings).

- [x] [P2-T2] Confirm the change does not introduce a broad suppression.
  - Read: `C:\Users\DanMoisan\repos\TMW\.gitleaks.toml`
  - Write: `docs/features/active/2026-05-31-ifile-message-filing-dialog-43/evidence/qa-gates/gitleaks-scope-check.2026-06-05T07-36.md`
  - Artifact MUST contain: `Timestamp:`, `Command:` (or `Inspection:` describing the read),
    `EXIT_CODE:` (use `0` for a passing manual inspection), `Output Summary:`.
  - `Output Summary:` MUST confirm all of: `[extend].useDefault = true` is unchanged; both custom
    `[[rules]]` (`graph-client-secret`, `office-addin-shared-key`) remain present and active; the
    `generic-api-key` default rule is NOT disabled; the new allowlist entry is scoped to the
    `UserSecretsId` non-secret and does not broadly exclude the repo-root `README.md` (unless the
    justified fallback from P2-T1 was required).
  - Acceptance: artifact confirms each item above; no broad suppression was introduced.

---

## Exit Criteria

- P0-T2 reproduces the failing state (`EXIT_CODE: 1`, one `generic-api-key` finding on `README.md`).
- P1-T2 applies a single narrow allowlist entry to the existing `[allowlist]` block, valid TOML.
- P2-T1 records `EXIT_CODE: 0` with zero leaks from the post-change scan.
- P2-T2 confirms no broad suppression: default and custom rules remain active; only the
  `UserSecretsId` non-secret is allowlisted.
- All evidence artifacts are written under canonical
  `docs/features/active/2026-05-31-ifile-message-filing-dialog-43/evidence/<kind>/` paths.
