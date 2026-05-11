# P0-T3 gh CLI Authentication & PR #1 Baseline

Timestamp: 2026-05-10T00-06

Command: gh auth status
EXIT_CODE: 0
Output:
```
github.com
  ✓ Logged in to github.com account drmoisan (keyring)
  - Active account: true
  - Git operations protocol: https
  - Token: gho_************************************
  - Token scopes: 'gist', 'read:org', 'repo', 'workflow'
```

Command: gh api repos/drmoisan/TMW/pulls/1 --jq '{number,state,head:.head.ref}'
EXIT_CODE: 0
Output: {"head":"feature/establish-repository-foundation-1","number":1,"state":"open"}

Output Summary: gh authenticated as drmoisan with `repo` and `workflow` scopes. PR #1 state == open; head.ref == feature/establish-repository-foundation-1 (matches local branch). Auth and PR preconditions for RP-2 (branch protection apply) are satisfied.
