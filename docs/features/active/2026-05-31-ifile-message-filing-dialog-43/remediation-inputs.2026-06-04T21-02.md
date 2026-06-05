# Remediation Inputs — iFile Message-Filing Dialog (#43)

- Cycle: 2 (end-of-cycle reaudit, exit timestamp 2026-06-04T21-02)
- Author: feature-review agent
- Feature folder: `docs/features/active/2026-05-31-ifile-message-filing-dialog-43`
- Branch: `feature/ifile-message-filing-dialog-43`
- Open PR: #44
- Base / merge-base: `main` @ `0eb035f`

## Remediation-Required Findings

### POL-1 (FAIL) — Repo-wide C# coverage below threshold for a language with changed files

- Source artifact: `docs/features/active/2026-05-31-ifile-message-filing-dialog-43/policy-audit.2026-06-04T21-02.md`
- Affected files (C# changed this cycle): `src/TaskMaster.Api/Program.cs` (DI wiring:
  `EnableTokenAcquisitionToCallDownstreamApi().AddMicrosoftGraph().AddInMemoryTokenCaches()`),
  `src/TaskMaster.Api/TaskMaster.Api.csproj` (whitespace-only).
- Evidence: `artifacts/csharp/coverage.xml` is current (timestamp Jun 4 14:30:55, generated ~1 minute
  after the Program.cs edit at 14:29:46, so it includes the cycle-2 change). It reports repo-wide
  line-rate 21.99% / branch-rate 8.01%, below the uniform 85% / 75% thresholds. The shortfall is
  concentrated in unchanged backend packages (`TaskMaster.Infrastructure` 9.83%,
  `TaskMaster.Application` 18.8%); the changed `Program` main class is 87% line-covered.
- Why this is remediation-required: the scope invariant requires an explicit coverage verdict for
  every language with changed files in the branch diff, and the coverage-verification procedure
  treats repo-wide below 80% as a FAIL trigger. The verdict cannot be waived even though the
  shortfall is in unchanged packages.
- Required remediation:
  1. Run the full backend test suite with coverage (including the integration / Graph adapter tests
     that are evidently not all reflected in the current 21.99% collection) so the repo-wide C#
     figure reflects the complete suite.
  2. Re-evaluate repo-wide C# coverage and the changed `Program.cs` lines against the 85% / 75%
     thresholds.
  3. If the refreshed repo-wide C# coverage remains below threshold and the gap is pre-existing
     backend coverage (not a cycle-2 regression on the changed entry-point lines, which are 87%
     covered), record it as a tracked backend-coverage item rather than a cycle-2 blocker.

## Non-Blocking Observations (no remediation required this cycle)

- POL-2: extend the `ifile-pure-modules-no-host-deps` depcruise `from` set to include `ifile.ts`
  so a future direct MSAL import into the bootstrap module would be caught. Currently `ifile.ts` is
  MSAL-free; latent rule-coverage gap only.
- POL-3: widen the `format:check` glob to cover `tests/**` (lint and tsc already cover the test
  tree and pass).
- CR-1: remove the vestigial `auth.getAccessToken` member from the host-shell test fake.

## Declared Human Exceptions (gate feature DONE, not cycle exit)

- HI-1 (admin consent), HI-2 (mobile build + on-device re-verification), HI-3 (Entra app NAA + OBO
  configuration) remain declared exceptions with runbooks. AC-2, AC-3, AC-11, AC-12, AC-13, AC-19,
  AC-20, AC-21, AC-24 remain pending those human steps. These are not code defects and require no
  code remediation.

## Aggregate

- Blocking findings requiring remediation: 1 (POL-1)
- Blocking-PARTIAL findings: 0
