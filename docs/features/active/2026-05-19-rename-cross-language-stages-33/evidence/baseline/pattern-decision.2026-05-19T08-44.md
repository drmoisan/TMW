# Pattern Decision — Cross-Language Stage Rename

- Timestamp: 2026-05-19T08-44
- Issue: #33

## Recommendation

Pattern A — language-scoped suffix. Final filenames:

- `_stage-1-format.yml` -> `_stage-1-format-prettier.yml`
- `_stage-2-lint.yml` -> `_stage-2-lint-eslint.yml`
- `_stage-3-typecheck.yml` -> `_stage-3-typecheck-tsc.yml`
- `_stage-5-test.yml` -> `_stage-5-test-vitest.yml`
- `_stage-7-integration.yml` -> `_stage-7-integration-vitest.yml`

## Rationale

The existing `_stage-N-dotnet-*.yml` siblings place the language/toolchain marker as a suffix on the stage stem (for example `_stage-1-dotnet-format.yml`). Pattern A places the toolchain marker in the same suffix position, preserves the `stage-N-<kind>` stem for sorting, and avoids re-sorting the existing dotnet siblings.

## Decision

Decision: CONFIRMED (Pattern A)

Confirmed in the orchestrator delegation prompt for issue #33. No further confirmation required before P1.
