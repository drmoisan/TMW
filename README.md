# TMW

TaskMaster — a No-COM Outlook task pane add-in. The runtime is implemented in
TypeScript using the Office.js API and (in later phases) Microsoft Graph; the
project deliberately avoids VSTO, Outlook PIA / COM interop, and any
dependence on the desktop object model. See
[`docs/TaskMaster-Modern-Architecture-Migrationresearch-NoCOM.md`](docs/TaskMaster-Modern-Architecture-Migrationresearch-NoCOM.md)
for the architecture decision record and
[`.claude/rules/architecture-boundaries.md`](.claude/rules/architecture-boundaries.md)
for the enforceable boundary assertions.

The current codebase is an Office Add-in TaskPane scaffold with quality gates,
CI pipeline, and supporting infrastructure in place. Feature work targeting
TaskMaster behavior lands in subsequent prompts.

## Repository layout

| Path | Purpose |
| --- | --- |
| `src/taskpane/` | Office.js task pane UI entry point and supporting modules. |
| `src/commands/` | Function-file command handlers invoked by ribbon controls. |
| `src/test-support/` | Vitest setup, Office.js fake module, MSW server. Not shipped to production. |
| `tests/violations/` | Disabled fixtures used to demonstrate that each CI gate rejects the matching violation. |
| `.github/actions/` | Composite actions for the seven-stage CI pipeline (format, lint, typecheck, architecture, test, contract, integration). |
| `.github/workflows/` | Workflow definitions that orchestrate the composite actions. |
| `.github/scripts/` | PowerShell helpers used by hooks and workflows (e.g. branch protection, gitleaks install). |
| `.claude/rules/` | Authoritative policy files for code change, testing, suppressions, architecture, and tonality. |
| `.claude/skills/` | Workflow definitions consumed by automation agents. |
| `docs/` | Architecture notes, governance documents, and feature-folder evidence. |
| `assets/` | Static assets referenced by the add-in manifest. |
| `manifest.json` | Office Add-in manifest. |

## Prerequisites

- Node.js 20.x (matches the version pinned in CI).
- npm 10.x.
- PowerShell 7+ for local script invocation. The repository's shell-bound
  tooling (lefthook, gitleaks helper, branch-protection script) targets pwsh.

## Getting started

```powershell
git clone https://github.com/drmoisan/TMW.git
cd TMW
npm ci
npx lefthook install
```

## Quality gates

The project enforces a seven-stage CI toolchain that mirrors the local
toolchain commands. Run the gates locally before pushing:

```powershell
npm run format:check    # stage 1 — Prettier
npm run lint            # stage 2 — ESLint flat config (type-aware)
npm run typecheck       # stage 3 — tsc --noEmit
npm run depcruise       # stage 4 — dependency-cruiser architecture rules
npm run test:coverage   # stage 5 — Vitest with coverage thresholds 85/75/85/85
```

Auto-fix scripts: `npm run format`, `npm run lint:fix`. The full reference,
including configuration paths, CI action mapping, coverage thresholds, and
troubleshooting, is in [`docs/quality-gates.md`](docs/quality-gates.md).

## Local development

| Command | Purpose |
| --- | --- |
| `npm run build` | Production webpack build. |
| `npm run build:dev` | Development webpack build. |
| `npm run dev-server` | Run the webpack dev server over HTTPS. |
| `npm run watch` | Webpack in watch mode. |
| `npm run start` | Side-load the add-in into the configured Office host. |
| `npm run stop` | Stop a running side-load session. |
| `npm run validate` | Validate `manifest.json`. |
| `npm run signin` / `npm run signout` | Manage the dev M365 account used by `office-addin-dev-settings`. |

## Testing

Unit tests use Vitest with jsdom, MSW v2 for HTTP stubbing, and an Office.js
fake module wired via `resolve.alias` and `globalThis`. Coverage thresholds
are uniform across all rigor tiers per
[`.claude/rules/quality-tiers.md`](.claude/rules/quality-tiers.md). Test
conventions (Arrange–Act–Assert, controlled clock, seeded RNG, no temp files)
are defined in
[`.claude/rules/general-unit-test.md`](.claude/rules/general-unit-test.md).

## Contributing

1. Branch from `main` using the `feature/<short-name>-<issue-number>` naming
   convention.
2. Make small, focused commits that follow
   [Conventional Commits](https://www.conventionalcommits.org/). The
   `commit-msg` lefthook hook enforces this locally; CI does not.
3. Run the local gate sweep (see [Quality gates](#quality-gates)) before
   pushing.
4. Open a pull request against `main`. Branch protection requires every CI
   check to pass before merge; the required checks are documented in
   [`docs/branch-protection.md`](docs/branch-protection.md).

Policy files referenced by reviewers and automation:

- [`.claude/rules/general-code-change.md`](.claude/rules/general-code-change.md)
  — design principles, toolchain order, file-size limit, error handling.
- [`.claude/rules/general-unit-test.md`](.claude/rules/general-unit-test.md)
  — test independence, isolation, determinism, coverage requirements.
- [`.claude/rules/typescript.md`](.claude/rules/typescript.md) — TypeScript
  coding standards, ESLint stack, testing standards.
- [`.claude/rules/typescript-suppressions.md`](.claude/rules/typescript-suppressions.md)
  — authorized suppression patterns and escalation path.
- [`.claude/rules/architecture-boundaries.md`](.claude/rules/architecture-boundaries.md)
  — No-COM architecture assertions and layer boundaries.
- [`.claude/rules/quality-tiers.md`](.claude/rules/quality-tiers.md) — module
  rigor tier definitions and gate matrix.
- [`.claude/rules/tonality.md`](.claude/rules/tonality.md) — required tone
  for agent-authored content.

## License

MIT, per the `"license"` field in [`package.json`](package.json).
