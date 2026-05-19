# Evidence: README format-row clarification

- Timestamp: 2026-05-19T01-30 UTC
- Command: `Edit .github/workflows/README.md`
- EXIT_CODE: 0

## Rationale

During final review, the user observed that the table row for `_stage-1-format.yml` was labeled "Cross-language format check" while a separate row labeled ".NET format" exists for `_stage-1-dotnet-format.yml`. Inspection of the underlying composite actions confirms the labeling is inaccurate:

- `_stage-1-format.yml` invokes `.github/actions/format/action.yml`, which runs `npm run format:check` (Prettier with `office-addin-prettier-config`). Prettier covers JS, TS, JSON, YAML, Markdown only — not C#, PowerShell, or Python.
- `_stage-1-dotnet-format.yml` invokes `.github/actions/dotnet-format/action.yml`, which runs `dotnet csharpier check .` for C#.

The two stages cover disjoint file types; the original "Cross-language" label was aspirational at best and contradicted the existence of the separate `.NET format` row.

## Change

Replaced the descriptor cell for `_stage-1-format.yml` with `"Prettier format check (JS/TS/JSON/YAML/MD); see also _stage-1-dotnet-format.yml for C# (CSharpier)"`. The workflow file name is unchanged; no branch-protection impact.

## Out-of-scope finding

The same misleading "Cross-language X" pattern applies to four other rows (`stage-2-lint`, `stage-3-typecheck`, `stage-5-test`, `stage-7-integration`). Each is paired with a `.NET X` stage that handles C#, and each composite action under `.github/actions/` confirms TypeScript-only scope (ESLint flat-config, `tsc --noEmit`, Vitest, integration placeholder). Renaming those workflow files plus their README descriptors plus the branch-protection check names is captured in a separate potential feature (`rename-cross-language-stages`) created in the same session.

## Output summary

Single-cell markdown table edit. No source code, no tests, no toolchain impact. Re-run of the toolchain loop is not required because the change touches only documentation and does not modify any executable file.
