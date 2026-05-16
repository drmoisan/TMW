# Validation Scenario 1 — Breaking Change Without Version Bump [expect-fail]

Timestamp: 2026-05-14T23-20
Command: `oasdiff breaking <baseline> <pr-head> --fail-on ERR --format githubactions`
EXIT_CODE: 1 (expected non-zero — `[expect-fail]` task)

## Scenario

In a scratch working copy:
1. Edited `src/TaskMaster.Api/ClassifyResponse.cs` to rename the `Label` field to `Classification` (a breaking change on the 200 response of `POST /api/classify`).
2. Did **not** bump `<Version>` in `src/TaskMaster.Api/TaskMaster.Api.csproj` (still `1.0.0`).
3. Rebuilt `TaskMaster.Api` to re-emit `artifacts/openapi/current.json` containing the renamed property.
4. Ran the contract action's oasdiff breaking step locally against the committed baseline (`/tmp/baseline.json`, captured before the scratch edit).
5. Reverted the scratch edit after recording the result.

## Tooling

- `oasdiff` version: **1.15.3** (Windows binary downloaded from `https://github.com/oasdiff/oasdiff/releases/download/v1.15.3/oasdiff_1.15.3_windows_amd64.tar.gz`). Note: the contract action's pinned version was updated from the planning-time placeholder to `1.15.3` because that is the actually-published release.

## Output Summary

`oasdiff` exited with code **1** and reported the specific offending field:

```
::error title=response-required-property-removed,file=artifacts/openapi/current.json::in API POST /api/classify removed the required property `label` from the response with the `200` status
```

The output identifies:
- Breaking-change rule: `response-required-property-removed`.
- Endpoint: `POST /api/classify`.
- Offending field: required property `label` removed from the 200 response.
- Format: `githubactions` annotation (`::error title=...::...`), which renders on the PR diff at the affected file/line in CI.

This satisfies the `[expect-fail]` acceptance: a non-zero exit AND a specific offending-field identifier. The behavior demonstrates the contract gate operating end-to-end: when `info.version` is unchanged (P7-T2 covers the version-bump bypass), oasdiff flags removed-required-property breakage by name and blocks the PR.

## Revert

After capturing the output:
- `src/TaskMaster.Api/ClassifyResponse.cs` restored from `/tmp/ClassifyResponse.cs.bak`.
- `artifacts/openapi/current.json` will be re-emitted from the restored source in the next build step, restoring the `label` property and matching the committed baseline.
