# Remediation Inputs — Issue #35 (S9 CI-failure handling)

- Timestamp: 2026-05-20T16-30
- Source: S9 CI green gate against PR #38
- PR Pipeline run (failing): https://github.com/drmoisan/TMW/actions/runs/26172112325 (and 26173493029)

## Synthetic finding (from CI failure)

- Severity: Blocking
- Failing check: `stage-1-dotnet-format / stage-1-dotnet-format` (workflow "PR Pipeline")
- Failing job log:
  ```
  Run dotnet csharpier check .
  Error .\manifest.xml - Was not formatted.
    Expected (around line 3): 4-space indentation of xmlns attributes
    Actual: 2-space indentation
  ##[error]Process completed with exit code 1.
  ```

## Root cause

The `dotnet-format` composite action runs `dotnet csharpier check .` over the whole repository. CSharpier 1.2.6 formats XML files, and the new `manifest.xml` introduced by this feature did not conform to CSharpier's XML style (attribute indentation/wrapping). The repository's other XML files (`.csproj`/`.props`, 105 files checked total) already conform, so CSharpier XML formatting is an established repo practice. The local TypeScript toolchain (Prettier/ESLint/tsc/Vitest + office-addin-manifest) and the feature review did not run CSharpier (no C# files changed), so the violation surfaced only in CI.

## Fix applied

Ran `dotnet csharpier format manifest.xml` to reformat the manifest to CSharpier's XML style (consistent with all other repo XML, rather than exempting it via `.csharpierignore`). The change is formatting-only (indentation/line-wrapping); no element, attribute, or value content changed.

## Verification (local)

- `dotnet csharpier check .` → exit 0 (105 files checked, clean).
- `npm run validate:xml` (office-addin-manifest) → "The manifest is valid."
- `https://localhost:3000/` occurrences unchanged (17); `npm run build` rewrites them to `urlProd` (0 `localhost` in `dist/manifest.xml`).
- Critical mobile elements intact: `<MobileFormFactor>`, `MobileMessageReadCommandSurface`, `MobileButton`, `Mailbox MinVersion="1.5"`, nine mobile icons, `ShowTaskpane`; `<AppDomain>` trailing slash retained.

## Disposition

Mechanical formatter reflow; no behavioral or semantic change. Committed and pushed; S9 re-run against the new head SHA to confirm the PR Pipeline is green.
