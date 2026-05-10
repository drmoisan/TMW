# Branch Protection Requirements

This document records the branch protection rule that must be active on the `main` branch.
Application of the rule via the GitHub API is recorded as a manual follow-up because the
executor session does not have authenticated `gh` CLI access.

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

## Manual follow-up record

Status: PENDING (manual). Owner: repo administrator. Apply once authenticated `gh` CLI
access is available. Verification: re-run the command with `-X GET` and confirm each
context appears in the response payload.
