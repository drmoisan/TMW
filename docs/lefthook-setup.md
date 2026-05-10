# Lefthook Setup

This document describes how to install and use lefthook for local Git hook execution in this repository.

## Installation

Install lefthook as a development dependency in this repository:

```bash
npm install --save-dev @evilmartians/lefthook
```

After installation, register the hooks with Git:

```bash
npx lefthook install
```

Lefthook reads `lefthook.yml` at the repository root and registers pre-commit, commit-msg, and pre-push handlers.

## Windows pwsh notes

All hook commands in `lefthook.yml` invoke `pwsh -NoProfile ...` rather than `powershell.exe` to ensure PowerShell 7+ is used.

The conventional-commits hook script lives at `.githooks/check-conventional-commit.ps1`. Lefthook substitutes `{1}` with the path to the commit message file produced by Git during the `commit-msg` phase.

## CI behavior

Set the environment variable `LEFTHOOK=0` to skip lefthook execution. CI is configured to run the equivalent stages directly via the GitHub Actions pipeline rather than via lefthook, so disabling lefthook in CI avoids duplicated work.

## Verifying installation

After `npx lefthook install`, run:

```bash
git commit --allow-empty -m "feat(test): verify hooks"
```

The commit-msg hook should accept a message that follows Conventional Commits. A non-conformant message (for example, `fix stuff`) should be rejected by `.githooks/check-conventional-commit.ps1` with a non-zero exit code.

The gitleaks pre-commit hook should reject staged content that matches a default or repository-specific secret pattern defined in `.gitleaks.toml`.

## References

- `lefthook.yml` (repository root)
- `.gitleaks.toml`
- `.githooks/check-conventional-commit.ps1`
