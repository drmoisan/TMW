#Requires -Version 7.0
<#
.SYNOPSIS
  Conventional Commits commit-msg hook.
.DESCRIPTION
  Reads the staged commit message file and rejects messages that do not match the
  Conventional Commits format. Invoked by lefthook (commit-msg / conventional-commits).
.PARAMETER MessageFile
  Path to the commit message file (lefthook substitutes {1}).
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$MessageFile
)

$ErrorActionPreference = 'Stop'

function Invoke-ConventionalCommitCheck {
    [CmdletBinding()]
    [OutputType([int])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$MessageFile
    )

    if (-not (Test-Path $MessageFile)) {
        [Console]::Error.WriteLine("Commit message file not found: $MessageFile")
        return 2
    }

    $raw = Get-Content -Raw -Path $MessageFile
    $lines = $raw -split "`r?`n" | Where-Object { $_ -notmatch '^\s*#' }
    $firstLine = ($lines | Where-Object { $_ -ne '' } | Select-Object -First 1)

    if ([string]::IsNullOrWhiteSpace($firstLine)) {
        [Console]::Error.WriteLine("Commit message is empty.")
        return 3
    }

    # Conventional Commits subject pattern:
    # <type>(<scope>)?!?: <subject>
    # type in {feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert}
    $pattern = '^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\([\w\-/. ]+\))?!?:\s.+'
    if ($firstLine -notmatch $pattern) {
        $message = @"
Commit message does not match Conventional Commits format.
First line: $firstLine
Expected:   <type>(<optional scope>)?!?: <subject>
Allowed types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert
Example:    feat(taskpane): add classifier seam
"@
        [Console]::Error.WriteLine($message)
        return 4
    }

    return 0
}

if ($MyInvocation.InvocationName -ne '.') {
    exit (Invoke-ConventionalCommitCheck -MessageFile $MessageFile)
}
