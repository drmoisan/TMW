# Prompt A0 Foundation Baseline Research
# Date: 2026-05-09

---

## 1. Authoritative Decisions (Non-Negotiable)

These two decisions are stated in `docs/TaskMaster-Modern-Architecture-Migrationresearch-NoCOM.md` lines 614–615 and govern every file touched by A0.

**Decision 1 — Python formatter stays Black.**
The existing Python toolchain (Black + Ruff + Pyright + Pytest) is preserved. No rule or skill file may replace Black with Ruff format.

**Decision 2 — Uniform coverage thresholds across all tiers.**
Line coverage >= 85%, branch coverage >= 75%, no regression on changed lines. No tier-specific lower thresholds anywhere in the rule set.

Rationale stated in source doc (line 615): "high test coverage is a fundamental quality-control design choice that enables autonomous agentic development and trust in the work product."

Important: `docs/ci.research.md` section 3 defines a tiered gate matrix with tier-dependent line coverage floors (T1 >= 85%, T2 >= 75%, T3 >= 50%, T4 none). The A0 authoritative decision overrides those tier-specific floors with a uniform 85%/75% floor across all tiers. The tier system (T1–T4 designations, property-test density, mutation score, benchmark regression) otherwise stands as described.

---

## 2. Files to Create

### 2a. Frontmatter conventions observed in existing rule files

`.claude/rules/*.md` files use this frontmatter pattern (from `.claude/rules/typescript.md`):

```
---
paths:
  - "**/*.ts"
description: TypeScript-specific toolchain and coding standards.
---
```

`.github/instructions/*.instructions.md` files use this pattern (from `.github/instructions/typescript-code-change.instructions.md`):

```
---
description: "TypeScript-specific code change rules layered on top of the general code change policy"
applyTo: "**/*.ts"
name: typescript-code-change-policy
---
```

`.claude/rules/general-*.md` files use `paths: ["**"]` and no `applyTo`. `.github/instructions/general-*.instructions.md` files use `applyTo: "**"`.

### 2b. Files to create — target paths and frontmatter

| File | Frontmatter `paths`/`applyTo` | `description` |
|---|---|---|
| `.claude/rules/quality-tiers.md` | `paths: ["**"]` | `Module rigor tier system and uniform coverage thresholds.` |
| `.github/instructions/quality-tiers.instructions.md` | `applyTo: "**"` | `Module rigor tier system and uniform coverage thresholds.` |
| `.claude/rules/architecture-boundaries.md` | `paths: ["**/*.ts","**/*.cs"]` | `Architecture boundary enforcement rules for No-COM architecture.` |
| `.github/instructions/architecture-boundaries.instructions.md` | `applyTo: "**/*.ts,**/*.cs"` | `Architecture boundary enforcement rules for No-COM architecture.` |
| `quality-tiers.yml` | (no frontmatter — YAML config at repo root) | N/A |

`quality-tiers.yml` content requirements per A0 spec:
- Tier mapping for every existing project (currently the TS scaffold only).
- A build rule that fails CI if a new project is added without a tier classification.

---

## 3. Files to Modify — Exact-Quote Excerpts Grouped by Edit Category

### 3a. Jest → Vitest replacements

**`.claude/rules/typescript.md` lines 4 and 34–39 (current):**

```
4. **Testing — Jest**: All TypeScript unit tests must use Jest. Command: `npm run test:unit`
```
```
- Use **Jest** as the test framework.
```
```
- Use `jest.spyOn` or `jest.mock` for targeted mocking; reset mocks with `afterEach(() => { jest.resetAllMocks(); })`.
```
```
- Repository-wide line coverage must remain >= 80%.
- Any new module, class, or method must reach >= 90% coverage.
- Coverage command: `npm run test:unit:coverage`
```

Required replacements:
- `Jest` → `Vitest`, command `npm run test:unit` → `npm run test`
- `jest.spyOn` → `vi.spyOn`, `jest.mock` → `vi.mock`, `jest.resetAllMocks` → `vi.resetAllMocks`
- Coverage thresholds: `>= 80%` repo-wide → `>= 85% line, >= 75% branch`, `>= 90%` new modules → same uniform rule

**`.github/instructions/typescript-code-change.instructions.md` line 49 (current):**

```
4. **Testing — Jest**

   - TypeScript unit tests must pass Jest.
   - Approved command: `npm run test:unit`
```

**`.github/instructions/typescript-unit-test.instructions.md` lines 24–31 (current):**

```
## 1. Framework and Scope

- **Testing framework**
  - All TypeScript unit tests must use **Jest**.

- **Unit test definition**
  - Unit tests validate small, isolated behaviors (functions, helpers, small classes).
  - Unit tests must not require launching the VS Code extension host or depending on a live VS Code environment.
```
Lines 82–89 (current):
```
### **Mocking guidance**

- Mock external APIs or platform dependencies to keep tests deterministic.
- Prefer targeted mocks:
  - `jest.spyOn(obj, 'method')` for specific functions
  - `jest.mock('module')` for module-level dependencies

### **Resetting mocks**

- Reset mocks between tests to ensure independence.
- Preferred pattern:
  - `afterEach(() => { jest.resetAllMocks(); });`
```
Lines 92–95 (current):
```
### **Time and timers**

- Avoid brittle timing assertions.
- Prefer fake timers (`jest.useFakeTimers()`) or injected clocks when time is part of behavior.
```
Line 107–111 (current):
```
## 6. Required Commands

When verifying TypeScript unit tests locally, use the repo-standard scripts:

- Approved command: `npm run test:unit`
```

**`.claude/agents/atomic-executor.md` lines 16–17 (current):**

```
  - "Bash(npx jest *)"
```
Line 78 (current):
```
- **TypeScript**: `npx prettier`, `npx eslint`, `npx tsc`, `npx jest`
```

Required: replace `Bash(npx jest *)` with `Bash(npx vitest *)` and `npx jest` with `npx vitest`.

**`.github/agents/typescript-engineer.agent.md` — multiple locations (current):**

Line 8 (in TDD Red Phase handoff):
```
"Write the smallest failing Jest test(s) for the requested TypeScript change..."
```
Line 135 (current):
```
- Deterministic Jest unit tests that do not require the VS Code extension host
```
Line 136 (current, in "Jest unit test standards" section heading):
```
## Jest unit test standards

- Use `afterEach(() => { jest.resetAllMocks(); })` for isolation.
- Use fake timers or injected clocks when time is involved.
```
Line 143–144 (current, in TDD execution model):
```
- Hand off the red phase to the **"TDD Red Phase - Write Failing Tests First"** agent (via the configured `handoffs` entry) and use the returned failing Jest test(s) + failure output as the spec.
```

Required replacements in this file:
- All `Jest` → `Vitest`, `jest.resetAllMocks` → `vi.resetAllMocks`, `jest.spyOn` → `vi.spyOn`, `jest.mock` → `vi.mock`, `jest.useFakeTimers` → `vi.useFakeTimers`
- Section heading "Jest unit test standards" → "Vitest unit test standards"

### 3b. VS Code extension → Outlook host framing replacements

**`.github/agents/typescript-engineer.agent.md` — multiple locations (current):**

Line 34 (role section):
```
- Deterministic Jest unit tests that do not require the VS Code extension host
```

Line 100 (unit test boundary section):
```
## Unit test boundary

Unit tests MUST NOT launch the VS Code extension host.
```

Line 29 (separation of concerns):
```
- Keep VS Code API usage behind thin adapters.
- Put pure logic in modules that can be unit tested under Jest without the extension host.
```

Lines 76–78 (in section "9. UI/UX and Lifecycle Hygiene (VS Code Extension Context)"):
(these are in `.github/instructions/typescript-code-change.instructions.md` lines 184–204)
```
## 9. UI/UX and Lifecycle Hygiene (VS Code Extension Context)
```

**`.github/instructions/typescript-code-change.instructions.md` lines 74–79 (current):**

```
4. **Separation of concerns**

   - Keep pure logic separate from:
     - VS Code extension APIs
     - filesystem/network I/O
     - UI/presentation wiring
   - Write core logic so it can be unit tested without VS Code host processes.
```

Lines 185–204 (current):
```
## 9. UI/UX and Lifecycle Hygiene (VS Code Extension Context)
```

**`.github/instructions/typescript-unit-test.instructions.md` lines 28–30 (current):**

```
- **Unit test definition**
  - Unit tests validate small, isolated behaviors (functions, helpers, small classes).
  - Unit tests must not require launching the VS Code extension host or depending on a live VS Code environment.
```

**`.claude/rules/typescript.md` lines 28–29 (current):**

```
- **Separation of concerns**: Keep pure logic separate from VS Code extension APIs, filesystem/network I/O, and UI wiring.
```

Line 36 (current):
```
- Unit tests must not require the VS Code extension host.
```

Required replacements across all four files:
- "VS Code extension APIs" → "Office.js APIs, Microsoft Graph SDK, and other host-bound APIs"
- "VS Code extension host" → "Outlook host runtime"
- "VS Code extension context" (section heading) → "Outlook add-in lifecycle and UI hygiene"
- "VS Code host processes" → "Outlook host runtime"
- "the extension host" (standalone) → "the Outlook host runtime"

### 3c. Coverage threshold replacements

**`.claude/rules/general-unit-test.md` lines 23–26 (current):**

```
- **Repository-wide line coverage must remain >= 80%.**
- **Any new module, class, or method must target >= 90% coverage.**
- Code changes or refactors must not reduce coverage for the lines that were changed.
```

Required replacement: `>= 80%` repo-wide → `>= 85% line, >= 75% branch across all tiers`; `>= 90%` new modules → same uniform tier rule.

**`.github/instructions/general-unit-test.instructions.md` lines 38–43 (current):**

```
  - Repository-wide line coverage must remain `>= 80%`.
  - Any new modules, classes, or methods added must target `>= 90%` coverage.
  - Code changes or refactors must not reduce coverage for the lines that were changed.
```

**`.claude/rules/typescript.md` lines 42–46 (current):**

```
- Repository-wide line coverage must remain >= 80%.
- Any new module, class, or method must reach >= 90% coverage.
- Coverage command: `npm run test:unit:coverage`
- Coverage regression on changed lines is a blocking finding.
```

**`.claude/rules/python.md` lines 16 and 87–90 (current):**

Line 16 (toolchain entry):
```
4. **Testing — Pytest**: All tests use Pytest. New logic must have test coverage >= 90%. Command: `poetry run pytest --cov --cov-report=term-missing`
```
Lines 87–90 (Pytest Rules section):
```
- Repository-wide line coverage must remain >= 80%.
- Any new module, class, or method must reach >= 90% coverage.
- Coverage regression on changed lines is a blocking finding.
```

**`.github/instructions/python-code-change.instructions.md`** — does not contain explicit coverage threshold prose (the python-code-change instructions defer coverage to the unit test policy). Verify at edit time; the instruction block at line 72 reads "Testing tools and behavior are defined in the unit test policies."

**`.github/instructions/python-unit-test.instructions.md`** — coverage expectation is stated only as "All new Python logic must be covered by Pytest tests that follow the general unit test policy" (line 26). The thresholds flow from the general policy. Update to be explicit per the uniform tier rule.

**`.claude/rules/powershell.md` lines in Testing Standards (current):**

```
- Repository-wide line coverage must remain >= 80%.
- Any new module, class, or method must reach >= 90% coverage.
- Coverage regression on changed lines is a blocking finding.
```

**`.github/instructions/powershell-unit-test.instructions.md`** — no explicit threshold prose found; coverage requirements defer to general policy. Add explicit prose per uniform tier rule.

**`.github/instructions/powershell-code-change.instructions.md`** — no coverage threshold prose found. No change required for coverage; verify at edit time.

**`.claude/agents/feature-review.md` lines 109–112 (current):**

```
### Coverage Thresholds

- **New code files** (files added in this feature, not previously existing): line coverage must be >= 90%.
- **Modified files** (files that existed before and were changed): line coverage must show no regression relative to the baseline and must remain >= 80%.
- **Repo-wide**: line coverage must remain >= 80% for each language.
```

Required replacement: apply uniform tier rule — new files: `>= 85% line, >= 75% branch`; modified files: `no regression, >= 85% line, >= 75% branch`; repo-wide: `>= 85% line, >= 75% branch per language`.

**`.claude/skills/feature-review-workflow/SKILL.md` lines 100–104 (current):**

```
        - Coverage thresholds:
          - New code files (added in this feature): line coverage must be >= 90%. Flag as FAIL otherwise.
          - Modified files (changed but previously existing): line coverage must show no regression relative to baseline and must remain >= 80%. Flag as FAIL otherwise.
          - Repo-wide line coverage must remain >= 80% per language. Flag as FAIL otherwise.
```

Required replacement: apply uniform tier rule to all three bullets.

Also on line 99 (coverage command for C#):
```
        - C#: `vstest.console.exe <test-assembly-paths> /EnableCodeCoverage` → artifact: `artifacts/csharp/coverage.xml`
```
This line is noted as a Prompt C1 concern but will need updating to `dotnet test --collect:"XPlat Code Coverage"`. The A0 scope only requires coverage threshold changes; verify if C# command appears in skill files touched by A0.

**`.claude/skills/python-qa-gate/SKILL.md` line 47 (current):**

```
- **New modules, classes, or methods**: coverage >= 90% for each new unit introduced in the batch.
```

Required replacement: `>= 90%` → `>= 85% line, >= 75% branch per the uniform tier rule`.

**`.claude/skills/powershell-qa-gate/SKILL.md` line 45 (current):**

```
- **New modules, classes, or methods**: coverage >= 90% for each new unit introduced in the batch.
```

Required replacement: same as python-qa-gate.

**`.claude/hooks/validate-feature-review-coverage.ps1` lines 252–258 (current):**

```powershell
    if ($null -ne $RepoWidePct -and $RepoWidePct -lt 80.0) {
        $failLines = $coverageLines | Where-Object { $_ -match '\bFAIL\b' }
        if (-not $failLines -or $failLines.Count -eq 0) {
            return @{
                Ok     = $false
                Reason = ("{0} repo-wide coverage is {1}% (below the 80% floor) but the policy-audit contains no FAIL verdict on a coverage row for {0}." -f $Language, $RepoWidePct)
            }
        }
    }
```

Required changes:
1. Change `$RepoWidePct -lt 80.0` to `$RepoWidePct -lt 85.0`.
2. Update the `Reason` string from "below the 80% floor" to "below the 85% line coverage floor".
3. Add a branch-coverage check at 75.0. The script currently reads only LCOV `LF:`/`LH:` for line coverage and Jacoco `counter[@type="LINE"]` for CSharp/PowerShell. A new branch-coverage check at `75.0` must parse LCOV `BRF:`/`BRH:` (for TypeScript/Python) and Jacoco `counter[@type="BRANCH"]` (for C#/PowerShell). The check must fail validation when branch coverage is below 75.0, with a parallel `FAIL` verdict requirement in the policy audit.

Note: the script currently has no `Get-LcovBranchCoverage` function. The planner must add one alongside `Get-LcovRepoCoverage` and wire it into `Test-LanguageCoverageRow`.

### 3d. New subsections to add

The following subsections are added to existing files. The planner writes the content from scratch using the A0 spec and ci.research.md as source of truth.

**`.claude/rules/typescript.md` — add these subsections:**
- "ESLint stack" — `typescript-eslint` strict-type-checked + stylistic-type-checked, type-aware parsing, `eslint-plugin-office-addins`, `eslint-plugin-promise`, `eslint-plugin-security`, `eslint-plugin-import`, error-level `no-floating-promises`, `no-misused-promises`, `no-unsafe-*`, `no-restricted-syntax` banning `Date.now`, `setTimeout`, `setInterval`, `Math.random` outside an explicit infrastructure allowlist.
- "Architecture boundaries" — reference `architecture-boundaries.md`.
- "Property-based and mutation testing" — `fast-check` (>= 1 property test per pure function on T1/T2), `StrykerJS` (mutation score >= 75% on T1).
- "Golden tests" — classifier-output snapshots for T1 modules against a versioned corpus; soften (do not remove) existing "Avoid snapshot tests unless stable and intentional" to carve out classifier-output and schema-evolution scenarios.
- "Runtime determinism" — `Date`/`Math.random`/`setTimeout` through an injected `Clock`/`Random` interface, Vitest fake timers in tests, `await flushPromises()` over `setTimeout(0)`.
- "Coverage Requirements" update — reference `quality-tiers.md` and apply uniform tier rule.

Mirror of all six subsections into `.github/instructions/typescript-code-change.instructions.md` and `.github/instructions/typescript-unit-test.instructions.md` as appropriate.

**`.claude/rules/general-unit-test.md` — add these subsections:**
- "Test Categories" — unit tests (all tiers), property-based tests (T1/T2, >= 1 per pure function), golden/snapshot tests (T1 classifier outputs only, against a versioned corpus), contract/schema tests (host-service boundary), mutation tests (T1 only, >= 75% mutation score), integration tests.
- "Determinism Infrastructure" — controllable clock (`Clock` for TS / `TimeProvider` for .NET), seeded RNG with seed printed on test failure, banned APIs in test code (`setTimeout`, `Thread.Sleep`, `Task.Delay`, real wall-clock waits, `Date.now()` outside the clock interface), virtual scheduler / fake timers / `FakeTimeProvider` for async tests.

Mirror into `.github/instructions/general-unit-test.instructions.md`.

**`.claude/rules/general-code-change.md` — add these subsections:**
- "Module Rigor Tiers" — pointer to `quality-tiers.md`.
- Expand "Mandatory Toolchain Loop" from 4 stages to 7: (1) formatting, (2) linting, (3) type checking, (4) architecture-boundary tests, (5) unit tests with property tests where applicable, (6) contract/schema compatibility checks, (7) integration tests. Note mutation testing, golden tests, and benchmark regression run in pre-merge or nightly pipelines only. The restart-from-step-1 rule applies to the full 7-stage loop.

Currently `.claude/rules/general-code-change.md` line 34 reads:
```
**Restart from step 1** if any step fails or auto-fixes any files. Do not stop the loop until all four steps complete without errors in a single pass.
```
This must change to reference "seven stages" and "a single pass".

Mirror into `.github/instructions/general-code-change.instructions.md`.

---

## 4. Mirror-Impact Map

The orchestrator memory (`.claude/agent-memory/orchestrator/MEMORY.md`) states: "every runtime file under `.claude/`, `.codex/`, `.agents/`, `.github/` has a bundled mirror enforced by python contract tests; run pytest+pester before reporting completion."

The Python contract tests live in the drm-copilot extension (`c:\Users\DanMoisan\repos\drm-copilot\`), not in the TMW repo. The push-down script is `extensions/drm-copilot/resources/scripts/dev_tools/push_down_claude_customizations.py`, which publishes `.claude/` content into target workspaces.

Mirror convention observed from `.codex/agents/typescript-engineer.toml`:
- `.github/agents/<name>.agent.md` is the canonical source for agent definitions.
- `.codex/agents/<name>.toml` is the Codex mirror (reads canonical source at runtime via embedded instruction block).
- `.agents/skills/<name>/SKILL.md` is the OpenAI Agents SDK mirror of `.claude/skills/<name>/SKILL.md`.

| Source file (`.claude/` or `.github/`) | `.codex/` mirror | `.agents/` mirror | Contract test note |
|---|---|---|---|
| `.claude/agents/atomic-executor.md` | `.codex/agents/atomic-executor.toml` | None observed | Update both |
| `.claude/agents/feature-review.md` | `.codex/agents/feature-review.toml` | `.agents/skills/feature-review/SKILL.md` | Update both |
| `.github/agents/typescript-engineer.agent.md` | `.codex/agents/typescript-engineer.toml` | None observed | `.codex/agents/typescript-engineer.toml` embeds the source by reference; updating the `.github/agents/` file propagates automatically if the toml reads the canonical source at runtime. Verify the toml pattern. |
| `.claude/hooks/validate-feature-review-coverage.ps1` | `.codex/hooks/validate-feature-review-coverage.ps1` | None | Both must be updated |
| `.claude/skills/feature-review-workflow/SKILL.md` | None observed in `.codex/` | `.agents/skills/feature-review-workflow/SKILL.md` | Update `.agents/` mirror |
| `.claude/skills/python-qa-gate/SKILL.md` | None observed in `.codex/` | `.agents/skills/python-qa-gate/SKILL.md` | Update `.agents/` mirror |
| `.claude/skills/powershell-qa-gate/SKILL.md` | None observed in `.codex/` | `.agents/skills/powershell-qa-gate/SKILL.md` | Update `.agents/` mirror |
| `.claude/rules/general-unit-test.md` | Indirectly mirrored via push-down | `.agents/skills/` (no direct rule mirror found) | Push-down propagates; verify |
| `.claude/rules/general-code-change.md` | Indirectly mirrored via push-down | None observed | Push-down propagates |
| `.claude/rules/typescript.md` | Indirectly mirrored via push-down | `.agents/skills/typescript/SKILL.md` | Update `.agents/` mirror |
| `.claude/rules/python.md` | Indirectly mirrored via push-down | `.agents/skills/python/SKILL.md` | Update `.agents/` mirror |
| `.claude/rules/powershell.md` | Indirectly mirrored via push-down | `.agents/skills/powershell/SKILL.md` | Update `.agents/` mirror |
| `.github/instructions/general-unit-test.instructions.md` | No codex toml mirror observed | None | Update only |
| `.github/instructions/general-code-change.instructions.md` | No codex toml mirror observed | None | Update only |
| `.github/instructions/typescript-code-change.instructions.md` | No codex toml mirror observed | None | Update only |
| `.github/instructions/typescript-unit-test.instructions.md` | No codex toml mirror observed | None | Update only |
| `.github/instructions/python-code-change.instructions.md` | No codex toml mirror observed | None | Update only |
| `.github/instructions/python-unit-test.instructions.md` | No codex toml mirror observed | None | Update only |
| `.github/instructions/powershell-code-change.instructions.md` | No codex toml mirror observed | None | Update only |
| `.github/instructions/powershell-unit-test.instructions.md` | No codex toml mirror observed | None | Update only |
| New: `.claude/rules/quality-tiers.md` | None yet — create `.codex/` mirror per convention | Create `.agents/skills/quality-tiers/SKILL.md` | New pair |
| New: `.claude/rules/architecture-boundaries.md` | None yet | Create `.agents/skills/architecture-boundaries/SKILL.md` | New pair |
| New: `.github/instructions/quality-tiers.instructions.md` | No codex toml mirror pattern for instructions | None | New only |
| New: `.github/instructions/architecture-boundaries.instructions.md` | No codex toml mirror pattern for instructions | None | New only |

**Contract test location:** `c:\Users\DanMoisan\repos\drm-copilot\extensions\drm-copilot\resources\scripts\dev_tools\push_down_claude_customizations.py` drives the push-down. No separate pytest contract test file was located in the TMW repo or the drm-copilot repo at `tests/`. The enforcement is implemented as a push-down script that copies `.claude/` content to target workspaces; a successful push-down run after editing is the verification step the orchestrator memory refers to. The planner should treat "run push-down script and confirm zero diff in target" as the contract-test equivalent.

---

## 5. Phase 2 Hygiene Tooling Research

### lefthook

**Canonical config filename:** `lefthook.yml` at repo root.

**Invocation pattern:**
- Install: single binary; on Windows use `scoop install lefthook` or download from GitHub Releases (`lefthook_<version>_Windows_x86_64.zip`). Alternatively install as an npm dev dependency: `npm install --save-dev @evilmartians/lefthook`.
- Hook installation: `lefthook install` (writes git hooks into `.git/hooks/`).
- Run hooks manually: `lefthook run pre-commit`, `lefthook run commit-msg`.

**Windows/pwsh-specific gotchas:**
- lefthook runs hook scripts via the OS shell. On Windows, shell scripts default to `cmd.exe` unless the config specifies `shell: pwsh` or paths use `.ps1` extensions explicitly.
- The `scripts` block in `lefthook.yml` must specify `runner: pwsh` for any PowerShell hook on Windows.
- npm-installed lefthook requires that the npm `.bin/` directory is on PATH in the shell that runs git operations.
- The CI agent environment is Windows PowerShell (confirmed by agent definitions), so all lefthook runner commands must be valid in pwsh.

**Example `lefthook.yml` structure for this repo:**

```yaml
pre-commit:
  parallel: true
  commands:
    prettier:
      glob: "*.{ts,tsx}"
      run: npx prettier --check {staged_files}
    gitleaks:
      run: gitleaks protect --staged --no-banner
commit-msg:
  commands:
    conventional-commits:
      run: npx commitlint --edit {1}
```

### gitleaks

**Canonical config filename:** `.gitleaks.toml` at repo root (optional; gitleaks has built-in rules).

**Invocation pattern:**
- Install: single Go binary; download from GitHub Releases (`gitleaks_<version>_windows_x64.zip`) or `winget install gitleaks`.
- Pre-commit use: `gitleaks protect --staged --no-banner` (scans staged files only).
- CI use: `gitleaks detect --source . --no-banner` (scans full history or current checkout).

**Windows/pwsh-specific gotchas:**
- On Windows the binary name is `gitleaks.exe`. The lefthook runner must invoke `gitleaks.exe` or ensure the binary is on PATH.
- In GitHub Actions on a Windows runner: use `actions/checkout` with `fetch-depth: 0` for full history scans; partial scans use `--log-opts="HEAD~1..HEAD"`.
- The `protect` subcommand requires a git repo with a staged area; it cannot run in a bare clone.

### Renovate

**Canonical config filename:** `renovate.json` or `.github/renovate.json` at repo root or in `.github/`.

**Invocation pattern:**
- For GitHub: install the [Renovate GitHub App](https://github.com/apps/renovate) on the repository; the app reads `renovate.json`.
- Self-hosted alternative: `npx renovate` with a `RENOVATE_TOKEN` environment variable.
- The config covers npm, NuGet (when `nuget` manager enabled), GitHub Actions (when `github-actions` manager enabled), and Docker.

**Example `renovate.json` for this repo (npm + future NuGet + GHA):**

```json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": ["config:base"],
  "packageRules": [
    {
      "matchManagers": ["npm"],
      "groupName": "npm dependencies",
      "automerge": false
    }
  ],
  "enabledManagers": ["npm", "nuget", "github-actions"]
}
```

**Windows/pwsh-specific gotchas:**
- No Windows-specific issues for Renovate; it runs as a cloud service (app) or Docker container (self-hosted). The app installation requires no local tooling.
- Self-hosted with `npx renovate` on Windows requires Node.js >= 18 and that `RENOVATE_TOKEN` is set in the environment.

### Conventional Commits commit-msg hook

**Canonical config filename:** `commitlint.config.js` (or `.commitlintrc.js`, `.commitlintrc.json`) at repo root.

**Invocation pattern:**
- Install: `npm install --save-dev @commitlint/cli @commitlint/config-conventional`.
- commit-msg hook (via lefthook): `npx commitlint --edit $1` where `$1` is `{1}` in lefthook syntax.
- Direct test: `echo "feat: add classifier" | npx commitlint`.

**`commitlint.config.js`:**

```js
module.exports = { extends: ['@commitlint/config-conventional'] };
```

**Windows/pwsh-specific gotchas:**
- In lefthook on Windows, `{1}` expands to the commit message file path. Passing it to `npx commitlint --edit {1}` works in pwsh.
- The `HUSKY_SKIP_HOOKS` / `LEFTHOOK=0` environment variable can disable hooks in CI if needed; set `LEFTHOOK=0` in CI runners that should not run pre-commit hooks.
- PowerShell does not expand `$1` the same way bash does; use lefthook's `{1}` placeholder, not a shell positional parameter.

### GitHub Actions composite actions and baseline workflow

**Canonical config filenames:**
- Reusable workflow: `.github/workflows/<name>.yml` with `on: workflow_call:`.
- Composite action: `.github/actions/<name>/action.yml` with `runs.using: composite`.

**Invocation pattern (composite action):**

```yaml
# .github/actions/format-check/action.yml
name: Format Check
runs:
  using: composite
  steps:
    - name: Run Prettier
      shell: pwsh
      run: npx prettier --check "**/*.ts"
```

```yaml
# Called from a workflow:
steps:
  - uses: ./.github/actions/format-check
```

**Baseline workflow structure for A0:**

```yaml
# .github/workflows/pr-pipeline.yml
name: PR Pipeline
on:
  pull_request:
    branches: [main]
jobs:
  stage-1-format:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ./.github/actions/format-check
  stage-2-lint:
    runs-on: windows-latest
    needs: stage-1-format
    steps:
      - uses: actions/checkout@v4
      - uses: ./.github/actions/lint-check
  # stages 3-7 as stubs
```

**Windows/pwsh-specific gotchas:**
- The CI host is Windows (confirmed by agent definitions referencing `pwsh`). All `shell:` directives in composite actions must specify `shell: pwsh` explicitly, not `bash`.
- `actions/checkout@v4` on Windows requires `git config core.longpaths true` if paths exceed 260 characters; add it as a setup step.
- lefthook does not run inside GitHub Actions by default; set `LEFTHOOK=0` or do not install lefthook in the CI runner.
- `gitleaks detect` should run in CI as a separate job with `fetch-depth: 0`.
- npm cache: use `actions/setup-node@v4` with `cache: 'npm'` on Windows runners.

---

## 6. Validation Matrix

The following items are drawn directly from the A0 spec validation bullets (source doc lines 686–703). Each is stated as a mechanically verifiable check.

### Phase 1 — Rule baseline

- [ ] `grep -ri "jest" .claude/rules/typescript.md .github/instructions/typescript-code-change.instructions.md .github/instructions/typescript-unit-test.instructions.md .claude/agents/atomic-executor.md .github/agents/typescript-engineer.agent.md` returns zero matches in active text (i.e., not in comments or code-fence examples that are labeled as "old" content).
- [ ] `grep -ri "vs code extension\|vscode extension" .claude/rules/typescript.md .github/instructions/typescript-code-change.instructions.md .github/instructions/typescript-unit-test.instructions.md .github/agents/typescript-engineer.agent.md` returns zero matches.
- [ ] Files `.claude/rules/quality-tiers.md`, `.claude/rules/architecture-boundaries.md`, `.github/instructions/quality-tiers.instructions.md`, and `.github/instructions/architecture-boundaries.instructions.md` exist on disk with frontmatter matching the conventions in Section 2a of this artifact.
- [ ] The coverage rule in `.claude/rules/general-unit-test.md` reads ">= 85% line, >= 75% branch across all tiers" with no tier-specific lower thresholds anywhere in the file.
- [ ] The same threshold prose appears (consistently) in: `.claude/rules/python.md`, `.claude/rules/powershell.md`, `.claude/skills/python-qa-gate/SKILL.md`, `.claude/skills/powershell-qa-gate/SKILL.md`, `.claude/skills/feature-review-workflow/SKILL.md`, `.claude/agents/feature-review.md`, `.claude/hooks/validate-feature-review-coverage.ps1`, and all corresponding `.github/instructions/` mirrors.
- [ ] `.claude/rules/python.md` still contains "Black" as the formatter. `grep -i "black" .claude/rules/python.md` returns at least one match.
- [ ] Every `.claude/rules/` file that was modified has a corresponding modified `.github/instructions/` file (diff both directories and confirm no unpaired edits).
- [ ] Existing repository tests still pass (currently there are no TS, Python, or PowerShell test files in the TMW repo itself; the check is that `npm run lint` and `npm run typecheck` pass on the unmodified scaffold after rule file edits, since rule files are Markdown and do not affect build artifacts).

### Phase 2 — Hygiene controls

- [ ] A test commit containing a known fake secret pattern (e.g., `AKIA` + 16 alphanumeric chars) is rejected by the pre-commit gitleaks hook before the commit is created.
- [ ] A commit with a non-conformant message (e.g., `"fix stuff"`, missing conventional-commits type) is rejected by the commit-msg hook.
- [ ] `quality-tiers.yml` exists at repo root and contains a tier mapping for the TypeScript scaffold project.
- [ ] Adding a dummy project entry to `quality-tiers.yml` without a tier field causes the CI pipeline to fail (requires the CI pipeline stage to exist and validate the file schema).
- [ ] The PR pipeline workflow `.github/workflows/pr-pipeline.yml` exists, is syntactically valid YAML, and reports per-stage status on a push to a PR branch (even if individual stages are no-ops at this point).

---

## 7. Risks and Ambiguities

The following items are underspecified relative to repo state. The planner must resolve or flag each.

1. **`.github/agents/typescript-engineer.agent.md` vs `.github/instructions/` boundary.** The file exists and contains Jest/VS Code references (verified). However, this file is a GitHub Copilot agent definition (`.agent.md`), not a Copilot instructions file. The A0 spec requires updating it. Confirm the update target is the `.github/agents/typescript-engineer.agent.md` file (the one verified at read time), not a separate file.

2. **`CLAUDE.md` does not exist.** The A0 spec reads "Read first: CLAUDE.md" but no `CLAUDE.md` exists in the repo root. This is not a blocker for A0 (the spec reads it, not writes it), but the planner should note that branch protection configuration may need to be done manually or through the GitHub API since `CLAUDE.md` is not present to document it.

3. **`quality-tiers.yml` JSON schema.** The A0 spec requires a build rule that fails CI if a new project is added without a tier classification. The spec does not define a JSON Schema file for `quality-tiers.yml`. The planner must decide: (a) use a jsonschema file at e.g. `.github/schemas/quality-tiers.schema.json` and validate it in CI, or (b) write a lightweight validation script. Neither path is specified. The planner should pick one and document it.

4. **No `.github/workflows/` directory exists.** Verified: the directory does not exist. The entire GitHub Actions infrastructure must be created from scratch. The A0 spec requires "Baseline GitHub Actions workflow exists with reusable composite actions." The planner must define the initial workflow file path, runner OS (Windows based on agent definitions), and whether composite actions go in `.github/actions/<name>/` or are inlined.

5. **Branch protection rules.** The A0 spec requires "Branch protection rules require the PR pipeline to pass." Branch protection is a GitHub repository setting, not a file in the repo. It cannot be applied by an executor agent that only writes files. The planner must note this as a manual step or document a `gh` CLI command (e.g., `gh api repos/{owner}/{repo}/branches/main/protection -X PUT ...`).

6. **Mirror discipline for new rule files.** `.claude/rules/quality-tiers.md` and `.claude/rules/architecture-boundaries.md` are new files with no existing `.codex/` or `.agents/` mirror. The planner must create `.agents/skills/quality-tiers/SKILL.md` and `.agents/skills/architecture-boundaries/SKILL.md` as mirrors. Whether `.codex/` mirrors are needed for new `.claude/rules/` files (not agent files) is unclear from the observed convention. The `.codex/agents/` directory mirrors `.github/agents/`; there is no observed `.codex/rules/` directory. The planner should confirm whether `.claude/rules/` files require a `.codex/` mirror or only a `.github/instructions/` mirror.

7. **`.claude/skills/feature-review-workflow/SKILL.md` C# coverage command.** Line 99 contains `vstest.console.exe <test-assembly-paths> /EnableCodeCoverage`. The A0 scope is coverage threshold changes only; the C# command change is scoped to Prompt C1. The planner must decide whether to update the command in A0 (to avoid a mixed state) or defer it. The A0 spec is explicit: "No changes ... beyond the coverage-threshold update required by Authoritative Decision #2." The vstest line remains unchanged in A0.

8. **`npm run test:unit:coverage` command reference.** After replacing Jest with Vitest, the coverage command `npm run test:unit:coverage` (referenced in `.claude/rules/typescript.md` line 44 and `.claude/skills/feature-review-workflow/SKILL.md` line 97) must be updated to a Vitest-compatible coverage command. However, `package.json` currently has no `test:unit` or `test:unit:coverage` scripts at all (it only has `lint`, `build`, `validate`, etc.). The A0 spec says "No edits to package.json scripts beyond what hygiene tooling requires." Adding Vitest scripts to `package.json` is a Prompt B1 concern. The rule files should reference the eventual script name; the planner must pick a placeholder that is consistent with Prompt B1 expectations.

9. **`validate_evidence_locations.py` reference in `.claude/agents/feature-review.md`.** Line 136 of the file references `validate_evidence_locations.py --root .`. This script is not present in the TMW repo (confirmed: no `.py` files exist in the repo). It is presumably a tool provided by the drm-copilot MCP server or push-down scripts. No change is required for A0, but the planner should flag this as a dependency risk if the script is not available in the execution environment.

10. **Property-based testing tool for Python.** The A0 spec states "Add Hypothesis as the property-test framework only if a Python classifier service is later confirmed in scope." No Python service exists today. No Python test files exist in the TMW repo. The planner should add a note in the Python rule files that Hypothesis will be added when a Python classifier service is confirmed, but should not add it now.

11. **Lefthook binary availability on Windows CI.** The GitHub Actions runner will be `windows-latest`. Lefthook must be installed via npm (`npm install --save-dev @evilmartians/lefthook`) to avoid a separate binary download step. The planner should confirm whether lefthook runs during CI or is skipped (set `LEFTHOOK=0`). Running lefthook in CI duplicates the individual stage steps; the recommended pattern is to skip lefthook in CI and run the stages directly.

12. **`.codex/agents/` toml pattern for new agent files.** The observed pattern (`.codex/agents/typescript-engineer.toml`) embeds the canonical source by reference and does not duplicate content. For new files created in A0 (if any new agent definitions are required), the planner should follow this same pattern.

---

## Appendix A: Key Source File Locations Verified

| File | Status | Key content |
|---|---|---|
| `docs/TaskMaster-Modern-Architecture-Migrationresearch-NoCOM.md` | Exists | Full No-COM architecture + Prompt A0 spec (lines 595–703) |
| `docs/ci.research.md` | Exists | T1–T4 tier system, pipeline stages, gate thresholds |
| `.claude/rules/typescript.md` | Exists | Jest, 80% coverage, VS Code extension framing |
| `.claude/rules/general-unit-test.md` | Exists | 80% / 90% coverage thresholds |
| `.claude/rules/general-code-change.md` | Exists | 4-stage toolchain loop |
| `.claude/rules/python.md` | Exists | Black formatter, 80%/90% thresholds |
| `.claude/rules/powershell.md` | Exists | 80%/90% thresholds in Testing Standards |
| `.claude/agents/atomic-executor.md` | Exists | `Bash(npx jest *)` tool, `npx jest` in toolchain |
| `.claude/agents/feature-review.md` | Exists | 80%/90% coverage thresholds |
| `.claude/hooks/validate-feature-review-coverage.ps1` | Exists | Hard-coded `80.0` threshold, no branch check |
| `.claude/skills/feature-review-workflow/SKILL.md` | Exists | 80%/90% coverage prose |
| `.claude/skills/python-qa-gate/SKILL.md` | Exists | `>= 90%` new unit threshold |
| `.claude/skills/powershell-qa-gate/SKILL.md` | Exists | `>= 90%` new unit threshold |
| `.github/agents/typescript-engineer.agent.md` | Exists | Jest, VS Code extension host framing |
| `.github/instructions/typescript-code-change.instructions.md` | Exists | Jest, VS Code extension APIs |
| `.github/instructions/typescript-unit-test.instructions.md` | Exists | Jest, VS Code extension host |
| `.github/instructions/general-unit-test.instructions.md` | Exists | 80%/90% thresholds |
| `.github/instructions/general-code-change.instructions.md` | Exists | 4-stage toolchain loop |
| `.github/instructions/python-code-change.instructions.md` | Exists | Black formatter, no explicit coverage thresholds |
| `.github/instructions/python-unit-test.instructions.md` | Exists | No explicit thresholds (defers to general policy) |
| `.github/instructions/powershell-code-change.instructions.md` | Exists | No coverage threshold prose |
| `.github/instructions/powershell-unit-test.instructions.md` | Exists | No explicit thresholds |
| `.github/workflows/` | Does NOT exist | Must be created from scratch |
| `CLAUDE.md` | Does NOT exist | Not a blocker; noted as ambiguity |
| `quality-tiers.yml` | Does NOT exist | Must be created |
| `.github/actions/` | Does NOT exist | Must be created for composite actions |
| `.claude/rules/quality-tiers.md` | Does NOT exist | Must be created |
| `.claude/rules/architecture-boundaries.md` | Does NOT exist | Must be created |
| `package.json` | Exists | No test scripts; lint via `office-addin-lint`; no Jest or Vitest |
| `.gitignore` | Exists | `artifacts/` is gitignored |
| `.mcp.json` | Exists | drm-copilot MCP server at `@danmoisan/drm-copilot-mcp` |
| `.codex/agents/typescript-engineer.toml` | Exists | Mirror of `.github/agents/typescript-engineer.agent.md` |
| `.codex/hooks/validate-feature-review-coverage.ps1` | Exists | Mirror of `.claude/hooks/validate-feature-review-coverage.ps1` |
| `.agents/skills/feature-review-workflow/SKILL.md` | Exists | Mirror of `.claude/skills/feature-review-workflow/SKILL.md` |
| `.agents/skills/python-qa-gate/SKILL.md` | Exists | Mirror of `.claude/skills/python-qa-gate/SKILL.md` |
| `.agents/skills/powershell-qa-gate/SKILL.md` | Exists | Mirror of `.claude/skills/powershell-qa-gate/SKILL.md` |

---

## Appendix B: ci.research.md Gate Threshold Matrix (Verbatim)

Source: `docs/ci.research.md` section 3, lines 109–123.

```
| Gate | T1 | T2 | T3 | T4 |
|---|---|---|---|---|
| Format | 100% | 100% | 100% | 100% |
| Lint errors | 0 | 0 | 0 | 0 |
| Type errors | 0 | 0 | 0 | 0 |
| Untyped escape hatches (`any`/`dynamic`) | 0 | 0 | ≤ 5 per file, justified | unlimited |
| Architecture violations | 0 | 0 | 0 | 0 |
| Line coverage | ≥ 85% | ≥ 75% | ≥ 50% (integration) | none |
| Branch coverage | ≥ 75% | ≥ 65% | none | none |
| Property test count | ≥ 1 per pure function | ≥ 1 per pure function | none | none |
| Mutation score | ≥ 75% | trend-only | none | none |
| Contract breaking changes | major-bump required | major-bump required | n/a | n/a |
| Benchmark p99 regression | < 5% | < 10% | none | none |
| Determinism (no flaky tests) | retry rate < 0.5% | < 1% | < 2% | n/a |
```

Note: Authoritative Decision #2 overrides the tier-specific line and branch coverage floors with a uniform floor of line >= 85% and branch >= 75% across all tiers. The other rows in this matrix remain tier-dependent as specified.

---

## Appendix C: No-COM Architecture Rules (Verbatim from Source)

Source: `docs/TaskMaster-Modern-Architecture-Migrationresearch-NoCOM.md` lines 581–590.

```
The following rules are acceptance criteria for the no-COM architecture:

- New runtime code must not reference VSTO APIs.
- New runtime code must not reference Outlook desktop automation APIs.
- New runtime code must not expose COM-visible interfaces.
- New runtime code must not use Ribbon extensibility callbacks from the desktop object model.
- New runtime code must not depend on local Outlook event streams.
- New runtime code must not depend on Outlook user-defined fields as the primary state store.
- New runtime code must access mailbox data through Office.js or Microsoft Graph.
- Business behavior must be implemented in the backend or in host-neutral domain/application modules.
- Client UI must be implemented as web UI.
- Legacy integration, if required, must be limited to offline data import from files or exported data.
```

These rules are the source of truth for the `.claude/rules/architecture-boundaries.md` content.
