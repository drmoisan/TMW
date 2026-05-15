# Validation Scenario 1 — Version Bump Bypass

Timestamp: 2026-05-14T23-25
Command: contract action's `info.version` comparison step (followed by conditional `oasdiff breaking`)
EXIT_CODE: 0 (expected zero — version bump permits breaking change)

## Scenario

In a scratch working copy:
1. Kept the P7-T1 scratch edit (`ClassifyResponse.Label` renamed to `Classification`).
2. **Also** bumped `<Version>` in `src/TaskMaster.Api/TaskMaster.Api.csproj` from `1.0.0` to `2.0.0`.
3. Rebuilt to re-emit `artifacts/openapi/current.json`; the document's `info.version` is now `2.0.0`.
4. Captured the original committed baseline via `git show :artifacts/openapi/current.json > artifacts/openapi/_baseline.json` (baseline `info.version` is `1.0.0`).
5. Ran the contract action's `info.version` comparison step locally; if versions differ, the contract check exits zero without running oasdiff.
6. Reverted the scratch edits after recording the result.

## Output Summary

```
Baseline info.version: 1.0.0
PR-head info.version:  2.0.0
VERSION_BUMPED: true — breaking changes permitted; oasdiff skipped
EXIT_CODE: 0
```

The version-bump bypass step correctly detects the `info.version` change (`1.0.0` -> `2.0.0`) and exits the contract stage with code 0, treating the renamed-field breaking change as explicitly permitted by the API version bump. This is the contract action behavior described in P4-T2 (the bypass step added before `oasdiff breaking`).

## Comparison with P7-T1

- P7-T1: same breaking edit, **no** version bump — contract action runs `oasdiff breaking` and exits **1** with a `response-required-property-removed` annotation naming the offending field `label`.
- P7-T2: same breaking edit, **with** version bump — contract action's bypass detects the version change and exits **0** without invoking oasdiff.

Together the two scenarios demonstrate the AC4/AC8 contract gate behavior: breaking changes block PRs by default, and the API version bump is the explicit opt-in escape hatch.

## Revert

After capturing the output:
- `src/TaskMaster.Api/TaskMaster.Api.csproj` `<Version>` restored to `1.0.0`.
- `src/TaskMaster.Api/ClassifyResponse.cs` restored to the committed `record ClassifyResponse(string Label, double Confidence)`.
- `artifacts/openapi/current.json` re-emitted from the restored sources to match the committed baseline.
- `artifacts/openapi/_baseline.json` removed (scratch artifact).
