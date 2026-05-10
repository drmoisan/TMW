# Branch Governance Ruleset Requirements

This document records the repository ruleset and repository merge settings that must
govern the `main` branch. The configuration is applied programmatically by
`.github/scripts/apply-branch-protection.ps1`, which now manages a repository ruleset
plus the repository-level PR merge-method setting.

## Required status checks

The following status checks (job names from `.github/workflows/pr-pipeline.yml`) must pass
before a pull request can merge to `main`:

- `tier-classification`
- `stage-1-format`
- `stage-2-lint`
- `stage-3-typecheck`
- `stage-4-architecture`
- `stage-5-test`
- `stage-6-contract`
- `stage-7-integration`

Additional governance settings:

- Pull request reviews are **not** required by the repository ruleset.
- Merge commits are explicitly allowed for pull requests via the repository setting
  `allow_merge_commit=true`.
- Linear-history enforcement is **not** enabled, so merge commits are permitted.
- Branches must be up to date before merging because the ruleset requires strict
  status checks.
- The legacy branch-based protection rule for `main` is deleted after the ruleset is
  applied.

## Manual application commands (gh CLI)

The following commands apply the desired state once `gh auth login` is complete:

```bash
gh api -X PATCH repos/{owner}/{repo} \
  -F allow_merge_commit=true

gh api -X DELETE repos/{owner}/{repo}/branches/main/protection

gh api -X POST repos/{owner}/{repo}/rulesets \
  -f name='Main branch PR governance' \
  -f target='branch' \
  -f enforcement='active' \
  -f 'conditions[ref_name][include][]=refs/heads/main' \
  -f 'rules[][type]=required_status_checks' \
  -f 'rules[][parameters][strict_required_status_checks_policy]=true' \
  -f 'rules[][parameters][required_status_checks][][context]=tier-classification' \
  -f 'rules[][parameters][required_status_checks][][context]=stage-1-format' \
  -f 'rules[][parameters][required_status_checks][][context]=stage-2-lint' \
  -f 'rules[][parameters][required_status_checks][][context]=stage-3-typecheck' \
  -f 'rules[][parameters][required_status_checks][][context]=stage-4-architecture' \
  -f 'rules[][parameters][required_status_checks][][context]=stage-5-test' \
  -f 'rules[][parameters][required_status_checks][][context]=stage-6-contract' \
  -f 'rules[][parameters][required_status_checks][][context]=stage-7-integration'
```

## Application record

Status: AUTOMATED. Apply: `pwsh -NoProfile -File .github/scripts/apply-branch-protection.ps1`.
Verify:

- `gh api -X GET repos/drmoisan/TMW` and confirm `allow_merge_commit` is `true`
- `gh api -X GET repos/drmoisan/TMW/branches/main/protection` returns `404`
- `gh api -X GET repos/drmoisan/TMW/rulesets` includes the active `Main branch PR governance` ruleset
- `gh api -X GET repos/drmoisan/TMW/rules/branches/main` shows the eight required status checks
