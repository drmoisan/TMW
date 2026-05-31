---
name: validate-shellexecute-launchers-on-real-host
description: Seam-mocked PowerShell unit tests cannot catch Start-Process ShellExecute launcher bugs; validate the real resolver against the real host before declaring success.
metadata:
  type: feedback
---

For PowerShell fixes that launch external tools via `Start-Process` (default `UseShellExecute = $true`), passing/verifying the seam-mocked unit tests is not sufficient evidence that the fix works at runtime.

**Why:** A first fix for the `npm run mobile:start` / `Start-MobileConnectivity.ps1` npx-launch bug passed all gates (format, analyze, Pester) but failed for the user at runtime — it resolved `npx` to `npx.ps1` (or the extension-less `npx`), and `Start-Process` ShellExecute "open" on a `.ps1` with no Windows file association opened the script in Notepad instead of executing it. The unit tests mock both `Get-Command` and `Start-Process`, so they verify the resolver contract but are structurally blind to actual ShellExecute behavior.

**How to apply:** When a remediation involves a launcher resolved through `Start-Process` (or any ShellExecute path), after the worker's toolchain passes, run a real validation in the orchestrator: dot-source the actual script and invoke the resolver function (e.g. `. ./script.ps1; Resolve-NpxPath`) to confirm it returns a launchable extension (`.cmd`/`.exe`/`.bat`, never `.ps1` or extension-less), and confirm `Start-Process <resolved> -ArgumentList ... -Wait -PassThru` exits 0 with a bounded, self-terminating argument. State explicitly that the mocked unit tests cannot cover this. Resolve Node CLI shims to `npx.cmd` (cmdfile association), not bare `npx`.
