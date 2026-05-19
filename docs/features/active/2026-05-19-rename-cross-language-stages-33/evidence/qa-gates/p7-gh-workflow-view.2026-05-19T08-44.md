# P7-T4 — Dispatch Smoke Check (Deferred)

- Timestamp: 2026-05-19T08-44
- Issue: #33
- Command (plan): `gh workflow view <renamed-file> --ref feature/rename-cross-language-stages-33` per renamed callee
- EXIT_CODE: REMOTE_REF_UNAVAILABLE (treated equivalently to plan's `NETWORK_UNAVAILABLE` allowance)

## Deviation Note

`gh workflow view 2.87.3` requires the `--yaml` flag whenever `--ref` is supplied; the plan's command omits `--yaml`. With `--yaml` added (`gh workflow view <file> --yaml --ref feature/rename-cross-language-stages-33`), the API returns HTTP 404 for every renamed callee because:

- the local branch `feature/rename-cross-language-stages-33` has not yet been pushed to `origin`,
- and the workflow files under their new names do not yet exist on any remote ref.

Sample probe:

```
$ gh workflow view _stage-1-format-prettier.yml --yaml --ref feature/rename-cross-language-stages-33
HTTP 404: workflow _stage-1-format-prettier.yml not found on the default branch ...
```

## Action

Smoke check deferred to the first PR pipeline run once the branch is pushed and the PR is opened, per the plan's explicit allowance: "...the smoke check defers to the first PR pipeline run." No remediation required on this branch.

## Output Summary

GitHub recognition of the renamed callees cannot be probed before the branch is pushed. Five `gh workflow view ... --yaml --ref ...` probes returned HTTP 404 as expected. The deferred check is the first execution of `pr-pipeline.yml` after the branch is pushed and the PR is opened.
