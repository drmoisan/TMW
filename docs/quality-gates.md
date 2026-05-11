# Quality Gates

This document describes the quality gates enforced on every pull request, how
to run each gate locally, and where each gate is configured. The list of gates
and their order match the seven-stage toolchain defined in
[`.claude/rules/general-code-change.md`](../.claude/rules/general-code-change.md).

The CI pipeline is the source of truth. The composite actions under
[`.github/actions/`](../.github/actions/) contain the exact commands CI runs;
the npm scripts described below invoke the same tooling with the same flags.

## Prerequisites

- Node.js 20.x (the version pinned in the CI composite actions)
- npm 10.x (ships with Node 20)
- PowerShell 7+ (the repository's default shell on Windows; commands below are
  pwsh-compatible)

One-time setup after cloning or pulling:

```powershell
npm ci
```

`npm ci` is preferred over `npm install` because it installs the exact
versions recorded in `package-lock.json` and matches what CI does.

## Stage-by-stage reference

The seven-stage toolchain is run in order. Restart from stage 1 if any stage
fails or auto-fixes files. Stages 6 and 7 are reserved for future contract and
integration tests respectively; both are currently no-ops.

### Stage 1 — Format (Prettier)

| | |
| --- | --- |
| Command | `npm run format:check` |
| Auto-fix | `npm run format` |
| Config | `package.json` `"prettier"` field references [`office-addin-prettier-config`](https://www.npmjs.com/package/office-addin-prettier-config) |
| CI action | [`.github/actions/format/action.yml`](../.github/actions/format/action.yml) |
| Scope | `src/**/*.ts` |

Prettier writes LF line endings by default. The repo's `.gitattributes` pins
all text-source files to `eol=lf` so the check produces the same result on
every platform.

### Stage 2 — Lint (ESLint flat config)

| | |
| --- | --- |
| Command | `npm run lint` |
| Auto-fix | `npm run lint:fix` |
| Config | [`eslint.config.mjs`](../eslint.config.mjs) |
| CI action | [`.github/actions/lint/action.yml`](../.github/actions/lint/action.yml) |

`npm run lint` invokes `office-addin-lint check`, which auto-discovers the
flat config file `eslint.config.mjs` in the repo root. The config composes:

- `typescript-eslint` strict-type-checked + stylistic-type-checked rule sets,
  with type-aware parsing (`projectService: true`).
- `eslint-plugin-office-addins`, `eslint-plugin-promise`,
  `eslint-plugin-import`, `eslint-plugin-security`.
- Error-level `no-floating-promises`, `no-misused-promises`, all
  `no-unsafe-*`.
- `no-restricted-syntax` bans `Date.now`, `setTimeout`, `setInterval`, and
  `Math.random` outside an explicit infrastructure allowlist.
- A test-file override that relaxes a small number of strict rules. Each
  relaxation carries a `// justification:` comment per
  [`.claude/rules/typescript-suppressions.md`](../.claude/rules/typescript-suppressions.md).

### Stage 3 — Typecheck (tsc)

| | |
| --- | --- |
| Command | `npm run typecheck` |
| Auto-fix | none — failures must be resolved by source edits |
| Config | [`tsconfig.json`](../tsconfig.json) |
| CI action | [`.github/actions/typecheck/action.yml`](../.github/actions/typecheck/action.yml) |

`npm run typecheck` runs `tsc --noEmit`. The repository tsconfig enables:

- `strict`
- `noUncheckedIndexedAccess`
- `exactOptionalPropertyTypes`
- `noImplicitOverride`
- `noPropertyAccessFromIndexSignature`

Authorized suppression patterns are documented in
[`.claude/rules/typescript-suppressions.md`](../.claude/rules/typescript-suppressions.md).

### Stage 4 — Architecture (dependency-cruiser)

| | |
| --- | --- |
| Command | `npm run depcruise` |
| Auto-fix | none — failures must be resolved by source edits |
| Config | [`.dependency-cruiser.cjs`](../.dependency-cruiser.cjs) |
| CI action | [`.github/actions/architecture/action.yml`](../.github/actions/architecture/action.yml) |

Active rules:

- `no-circular` — error — forbids cyclic imports.
- `no-orphans` — warn — flags modules with no importer. Severity is `warn`
  rather than `error` because webpack entry points
  (`src/taskpane/taskpane.ts`, `src/commands/commands.ts`) have no TypeScript
  importer and would otherwise produce false positives.
- `taskpane-not-from-commands` — error — forbids `src/commands/**` from
  importing `src/taskpane/**`.
- `commands-not-from-taskpane` — error — forbids `src/taskpane/**` from
  importing `src/commands/**`.

Additional No-COM architectural assertions are listed in
[`.claude/rules/architecture-boundaries.md`](../.claude/rules/architecture-boundaries.md);
layer rules listed there will be added to `.dependency-cruiser.cjs` by later
prompts.

### Stage 5 — Unit tests (Vitest)

| | |
| --- | --- |
| Iterative command | `npm test` |
| Coverage command | `npm run test:coverage` (used in CI) |
| Config | [`vitest.config.ts`](../vitest.config.ts) |
| CI action | [`.github/actions/test/action.yml`](../.github/actions/test/action.yml) |

`npm test` runs `vitest run`. `npm run test:coverage` runs
`vitest run --coverage` and enforces the coverage thresholds defined in
`vitest.config.ts`:

| Metric | Threshold |
| --- | --- |
| Lines | 85 |
| Branches | 75 |
| Functions | 85 |
| Statements | 85 |

The thresholds match the uniform-across-tiers floor defined in
[`.claude/rules/quality-tiers.md`](../.claude/rules/quality-tiers.md).
A failing threshold exits non-zero and fails the stage.

#### Test environment

- `jsdom` provides a DOM for tests that touch `document` / `window`.
- An Office.js fake module is wired via `resolve.alias` and via
  `globalThis.Office` in the setup file. The fake lives in
  [`src/test-support/office-fake.ts`](../src/test-support/office-fake.ts).
- [`src/test-support/msw-server.ts`](../src/test-support/msw-server.ts)
  hosts an MSW v2 `setupServer` instance for HTTP stubbing.
- [`src/test-support/vitest-setup.ts`](../src/test-support/vitest-setup.ts)
  wires the MSW lifecycle and resets the Office global between tests.

Determinism requirements (controlled clock, seeded RNG, no real waits, no
temp files) are spelled out in
[`.claude/rules/general-unit-test.md`](../.claude/rules/general-unit-test.md).

### Stage 6 — Contract / schema (placeholder)

| | |
| --- | --- |
| Command | none — placeholder |
| CI action | [`.github/actions/contract/action.yml`](../.github/actions/contract/action.yml) |

Reserved for `oasdiff` and schema-snapshot checks once a backend contract
exists.

### Stage 7 — Integration tests (placeholder)

| | |
| --- | --- |
| Command | none — placeholder |
| CI action | [`.github/actions/integration/action.yml`](../.github/actions/integration/action.yml) |

Reserved for integration tests once the relevant adapters exist.

## Running every gate in one shot

The following PowerShell command runs stages 1 through 5 in order and
short-circuits at the first failure, matching the `needs:` chain in CI:

```powershell
npm run format:check; if ($?) { npm run lint; if ($?) { npm run typecheck; if ($?) { npm run depcruise; if ($?) { npm run test:coverage } } } }
```

## Pre-commit and pre-push hooks

[`lefthook.yml`](../lefthook.yml) wires a subset of the gates into Git hooks.
Install once after cloning:

```powershell
npx lefthook install
```

Current hook coverage:

- `pre-commit` — runs `gitleaks` against staged content.
- `commit-msg` — enforces Conventional Commits via
  `.githooks/check-conventional-commit.ps1`.
- `pre-push` — placeholder; stage-specific gates will be wired by later
  prompts.

Local hooks can be skipped for a single commit with `LEFTHOOK=0`, but doing
so does not bypass CI. See
[`docs/lefthook-setup.md`](./lefthook-setup.md) for setup details.

## Branch protection

The `main` branch is governed by a repository ruleset that requires every CI
check listed above to pass before merge. The ruleset is managed by
[`.github/scripts/apply-branch-protection.ps1`](../.github/scripts/apply-branch-protection.ps1);
the required checks and merge settings are documented in
[`docs/branch-protection.md`](./branch-protection.md).

## Module rigor tiers

Coverage thresholds are uniform across all rigor tiers (T1–T4). Other gates
(mutation score, property-test density, contract breaking changes, etc.) are
tier-dependent. Tier classification is in
[`quality-tiers.yml`](../quality-tiers.yml) at the repo root; the tier
definitions and gate matrix are in
[`.claude/rules/quality-tiers.md`](../.claude/rules/quality-tiers.md).

## Demonstrating that a gate blocks a regression

[`tests/violations/`](../tests/violations/) holds five `.disabled` fixture
files — one per category (format, lint, typecheck, architecture, test). The
[`tests/violations/README.md`](../tests/violations/README.md) documents the
copy-run-revert protocol used to capture evidence that each gate rejects the
corresponding violation.

## Troubleshooting

### "Gate passes locally but fails on CI"

The most common cause is line endings. CI runs on Windows hosted runners with
`core.autocrlf=true`, which would normally convert text files to CRLF on
checkout. The repository's `.gitattributes` pins all text source types to
`eol=lf`, so a fresh `git clone` is consistent with CI. If you have a
pre-existing working tree that predates the `.gitattributes` change, run
`git add --renormalize .` and commit the result.

### "Office Add-in plugin rules are not firing"

The flat config strips the `@typescript-eslint` plugin key from the spread of
`officeAddins.configs.recommended` so that ESLint v9 does not raise
`ConfigError: Cannot redefine plugin "@typescript-eslint"`. The
`typescript-eslint` strict and stylistic rule sets re-register the plugin
and apply all rules; no Office Add-in rule is silenced. If you add or
upgrade `eslint-plugin-office-addins`, re-verify the lint run is green and
inspect `eslint.config.mjs` for any new plugin-key collisions.

### "Coverage drops below threshold after a refactor"

`vitest.config.ts` includes only `src/**/*.ts` in coverage and excludes
`webpack.config.js` and `lib-amd/**`. New production sources are picked up
automatically; if a file is unintentionally outside the include glob, add a
corresponding test or adjust the include scope rather than lowering the
threshold.
