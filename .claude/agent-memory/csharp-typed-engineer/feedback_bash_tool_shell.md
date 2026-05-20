---
name: bash-tool-uses-posix-not-powershell
description: The Bash tool in this repo runs POSIX bash, not PowerShell, despite the win32 env note
metadata:
  type: feedback
---

The Bash tool executes under POSIX `bash` (`/usr/bin/bash`), even though the environment banner reports `Platform: win32` / `Shell: PowerShell`.

**Why:** A `dotnet build ... | Select-Object -Last 25` invocation failed with exit 127 (`Select-Object: command not found`) because the pipe ran in bash.

**How to apply:** When using the Bash tool, use POSIX syntax: `tail -n N`, `grep`, `unset VAR`, `VAR=value cmd` for one-shot env vars (e.g. `CsCheck_Seed=fh2TnxRKwBu3 dotnet test ...`). Reserve PowerShell syntax for any PowerShell-specific tooling, not the Bash tool.
