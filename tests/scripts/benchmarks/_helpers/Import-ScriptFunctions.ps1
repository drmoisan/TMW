#Requires -Version 7.0
<#
.SYNOPSIS
  Extracts top-level function definitions from a PowerShell script as a script block.
.DESCRIPTION
  Parses the supplied script file using the PowerShell AST, collects every top-level
  `function` definition, and returns a single `[scriptblock]` that, when dot-sourced,
  imports those functions into the caller's scope without executing the script's
  top-level statements. This is required to unit-test helper functions in scripts
  whose top-level statements call `exit` or perform I/O.
#>
function Get-ScriptFunctionsScriptBlock {
    [CmdletBinding()]
    [OutputType([scriptblock])]
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [string[]]$FunctionName
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Script not found: $Path"
    }
    $tokens = $null
    $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$errors)
    if ($errors -and $errors.Count -gt 0) {
        throw ("Parser errors in {0}: {1}" -f $Path, ($errors | ForEach-Object { $_.Message } | Out-String))
    }

    # Collect only top-level function definitions: their parent is the root
    # ScriptBlockAst or one of its named blocks (BeginBlock/ProcessBlock/EndBlock),
    # and none of their ancestors is itself a FunctionDefinitionAst.
    $functions = $ast.FindAll({
            param($node)
            if (-not ($node -is [System.Management.Automation.Language.FunctionDefinitionAst])) { return $false }
            $p = $node.Parent
            while ($p) {
                if ($p -is [System.Management.Automation.Language.FunctionDefinitionAst]) { return $false }
                $p = $p.Parent
            }
            return $true
        }, $true)

    if ($FunctionName) {
        $functions = $functions | Where-Object { $FunctionName -contains $_.Name }
    }

    $text = ($functions | ForEach-Object { $_.Extent.Text }) -join "`n`n"
    return [scriptblock]::Create($text)
}
