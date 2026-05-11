# P2-T4 Branch Protection — Live (Post-Apply) State

Timestamp: 2026-05-10T00-17

Command: gh api -X GET repos/drmoisan/TMW/branches/main/protection
EXIT_CODE: 0

Output Summary: Branch protection successfully applied to `main`. All eight required contexts are present in `required_status_checks.contexts`:
- tier-classification
- stage-1-format
- stage-2-lint
- stage-3-typecheck
- stage-4-architecture
- stage-5-test
- stage-6-contract
- stage-7-integration

Additional settings asserted by the response:
- `required_status_checks.strict`: true
- `enforce_admins.enabled`: true
- `required_pull_request_reviews.required_approving_review_count`: 1
- `required_pull_request_reviews.dismiss_stale_reviews`: true
- `required_linear_history.enabled`: true
- `allow_force_pushes.enabled`: false
- `allow_deletions.enabled`: false

Full response JSON:

```json
{"url":"https://api.github.com/repos/drmoisan/TMW/branches/main/protection","required_status_checks":{"url":"https://api.github.com/repos/drmoisan/TMW/branches/main/protection/required_status_checks","strict":true,"contexts":["tier-classification","stage-1-format","stage-2-lint","stage-3-typecheck","stage-4-architecture","stage-5-test","stage-6-contract","stage-7-integration"],"contexts_url":"https://api.github.com/repos/drmoisan/TMW/branches/main/protection/required_status_checks/contexts","checks":[{"context":"tier-classification","app_id":15368},{"context":"stage-1-format","app_id":15368},{"context":"stage-2-lint","app_id":15368},{"context":"stage-3-typecheck","app_id":15368},{"context":"stage-4-architecture","app_id":15368},{"context":"stage-5-test","app_id":15368},{"context":"stage-6-contract","app_id":15368},{"context":"stage-7-integration","app_id":15368}]},"required_pull_request_reviews":{"url":"https://api.github.com/repos/drmoisan/TMW/branches/main/protection/required_pull_request_reviews","dismiss_stale_reviews":true,"require_code_owner_reviews":false,"require_last_push_approval":false,"required_approving_review_count":1},"required_signatures":{"url":"https://api.github.com/repos/drmoisan/TMW/branches/main/protection/required_signatures","enabled":false},"enforce_admins":{"url":"https://api.github.com/repos/drmoisan/TMW/branches/main/protection/enforce_admins","enabled":true},"required_linear_history":{"enabled":true},"allow_force_pushes":{"enabled":false},"allow_deletions":{"enabled":false},"block_creations":{"enabled":false},"required_conversation_resolution":{"enabled":false},"lock_branch":{"enabled":false},"allow_fork_syncing":{"enabled":false}}
```
