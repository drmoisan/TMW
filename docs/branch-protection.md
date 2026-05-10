# Branch Protection Requirements

This document records the branch protection rule that is active on the `main` branch.
The rule is applied programmatically by `.github/scripts/apply-branch-protection.ps1`
and verified by `gh api -X GET repos/drmoisan/TMW/branches/main/protection`.

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

Additional protection rule settings:

- Require pull request reviews before merging: 1 approving review.
- Dismiss stale reviews on new commits.
- Require linear history.
- Require branches to be up to date before merging.
- Restrict who can push to matching branches: empty allowlist (no direct pushes).

## Manual application command (gh CLI)

The following command applies the rule once `gh auth login` is complete:

```bash
gh api -X PUT repos/{owner}/{repo}/branches/main/protection \
  -F required_status_checks.strict=true \
  -F 'required_status_checks.contexts[]=tier-classification' \
  -F 'required_status_checks.contexts[]=stage-1-format' \
  -F 'required_status_checks.contexts[]=stage-2-lint' \
  -F 'required_status_checks.contexts[]=stage-3-typecheck' \
  -F 'required_status_checks.contexts[]=stage-4-architecture' \
  -F 'required_status_checks.contexts[]=stage-5-test' \
  -F 'required_status_checks.contexts[]=stage-6-contract' \
  -F 'required_status_checks.contexts[]=stage-7-integration' \
  -F enforce_admins=true \
  -F required_pull_request_reviews.required_approving_review_count=1 \
  -F required_pull_request_reviews.dismiss_stale_reviews=true \
  -F required_linear_history=true \
  -F restrictions=null
```

## Application record

Status: AUTOMATED. Apply: `pwsh -NoProfile -File .github/scripts/apply-branch-protection.ps1`.
Verify: `gh api -X GET repos/drmoisan/TMW/branches/main/protection` and confirm each of
the eight contexts is present in `required_status_checks.contexts`.
