# Verify Snapshot Diff Tool Setup

This document describes how to configure local diff tools for reviewing `Verify.XunitV3`
snapshot differences. CI behavior is unaffected.

## How Verify Selects a Diff Tool

When a snapshot test fails, Verify attempts to launch an external diff tool automatically.
It probes the system in order for each registered tool. The tool is launched with the
`.received.json` and `.verified.json` files so you can review the diff and decide whether to
accept the new output.

The auto-detection order (on Windows) is:

| Tool | Detection Method |
|------|-----------------|
| Beyond Compare | Looks for `bcomp.exe` on PATH or in default install paths |
| WinMerge | Looks for `WinMergeU.exe` on PATH or in default install paths |
| Visual Studio Code | Looks for `code.cmd` / `code` on PATH |
| JetBrains Rider | Looks for `rider64.exe` on PATH or in default install paths |
| Visual Studio | Looks for `devenv.exe` on PATH or in default install paths |

Verify uses `DiffEngine` internally. If multiple tools are installed, the first match in
the priority list wins.

## Explicitly Configuring a Tool

To override auto-detection and always use a specific tool, add a call in a `[ModuleInitializer]`
or in an assembly-level test setup:

```csharp
// Force VS Code as the diff tool
DiffRunner.Disabled = false;
DiffTools.UseOrder(DiffTool.VisualStudioCode);
```

Alternatively, set the environment variable before running tests:

```
$env:DiffEngine_Disabled = "true"   # Disable tool launch entirely
```

## CI Behavior

When the environment variable `CI` is set to `true` (GitHub Actions sets this automatically),
Verify skips launching any external diff tool. The test still fails with a clear message
showing the diff in text form. No special configuration is required for CI.

## Accepting a New Snapshot

After reviewing the `.received.json` file:

1. Copy the content to the corresponding `.verified.json` file, or
2. Rename `.received.json` to `.verified.json` (replaces the old verified snapshot).

The `.verified.json` file must be committed to source control. The `.received.json` file
is excluded from source control via `.gitignore` (`*.received.*`).

## References

- [Verify documentation](https://github.com/VerifyTests/Verify)
- [DiffEngine documentation](https://github.com/VerifyTests/DiffEngine)
