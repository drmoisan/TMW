#Requires -Version 7.0
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }

Describe 'check-conventional-commit.ps1' {
    BeforeAll {
        $script:UnderTest = (Resolve-Path "$PSScriptRoot/../../.githooks/check-conventional-commit.ps1").Path
        # Dot-source the script so Invoke-ConventionalCommitCheck is defined in this scope.
        # The script's outer `if ($MyInvocation.InvocationName -ne '.') { exit ... }`
        # guard skips the CLI exit path when dot-sourced, so dot-sourcing only loads
        # the function definition and does not require a -MessageFile argument.
        . $script:UnderTest -MessageFile 'unused-because-dot-sourced'
        $script:Fixtures = Join-Path -Path $TestDrive -ChildPath 'fixtures'
        New-Item -ItemType Directory -Path $script:Fixtures -Force | Out-Null

        function Invoke-Hook {
            param([string]$MessageFile)
            $origErr = [Console]::Error
            $sw = New-Object System.IO.StringWriter
            [Console]::SetError($sw)
            try {
                $code = Invoke-ConventionalCommitCheck -MessageFile $MessageFile
            }
            finally {
                [Console]::SetError($origErr)
            }
            return @{ Output = $sw.ToString(); ExitCode = [int]$code }
        }
    }

    Context 'missing message file' {
        It 'exits 2 when the file does not exist' {
            $result = Invoke-Hook -MessageFile (Join-Path -Path $script:Fixtures -ChildPath 'does-not-exist.txt')
            $result.ExitCode | Should -Be 2
            $result.Output | Should -Match 'Commit message file not found'
        }
    }

    Context 'empty / comment-only message' {
        It 'exits 3 when message is empty' {
            $f = Join-Path -Path $script:Fixtures -ChildPath 'empty.txt'
            Set-Content -Path $f -Value ''
            (Invoke-Hook -MessageFile $f).ExitCode | Should -Be 3
        }

        It 'exits 3 when message contains only comment lines' {
            $f = Join-Path -Path $script:Fixtures -ChildPath 'comments.txt'
            Set-Content -Path $f -Value "# just a comment`n# another"
            (Invoke-Hook -MessageFile $f).ExitCode | Should -Be 3
        }

        It 'exits 3 when first non-comment line is whitespace' {
            $f = Join-Path -Path $script:Fixtures -ChildPath 'whitespace.txt'
            Set-Content -Path $f -Value "# header`n   `n# trailing"
            (Invoke-Hook -MessageFile $f).ExitCode | Should -Be 3
        }
    }

    Context 'invalid format' {
        It 'exits 4 for "WIP fix things"' {
            $f = Join-Path -Path $script:Fixtures -ChildPath 'wip.txt'
            Set-Content -Path $f -Value 'WIP fix things'
            $r = Invoke-Hook -MessageFile $f
            $r.ExitCode | Should -Be 4
            $r.Output | Should -Match 'Conventional Commits'
        }

        It 'exits 4 for unknown type "thing: do stuff"' {
            $f = Join-Path -Path $script:Fixtures -ChildPath 'unknown-type.txt'
            Set-Content -Path $f -Value 'thing: do stuff'
            (Invoke-Hook -MessageFile $f).ExitCode | Should -Be 4
        }
    }

    Context 'valid format' {
        It 'exits 0 for "feat: add foo"' {
            $f = Join-Path -Path $script:Fixtures -ChildPath 'feat.txt'
            Set-Content -Path $f -Value 'feat: add foo'
            (Invoke-Hook -MessageFile $f).ExitCode | Should -Be 0
        }

        It 'exits 0 for scoped "feat(taskpane): add classifier seam"' {
            $f = Join-Path -Path $script:Fixtures -ChildPath 'scoped.txt'
            Set-Content -Path $f -Value 'feat(taskpane): add classifier seam'
            (Invoke-Hook -MessageFile $f).ExitCode | Should -Be 0
        }

        It 'exits 0 for breaking-change "feat!: rewrite API"' {
            $f = Join-Path -Path $script:Fixtures -ChildPath 'breaking.txt'
            Set-Content -Path $f -Value 'feat!: rewrite API'
            (Invoke-Hook -MessageFile $f).ExitCode | Should -Be 0
        }

        It 'exits 0 for scoped breaking "fix(api)!: rename endpoint"' {
            $f = Join-Path -Path $script:Fixtures -ChildPath 'scoped-breaking.txt'
            Set-Content -Path $f -Value 'fix(api)!: rename endpoint'
            (Invoke-Hook -MessageFile $f).ExitCode | Should -Be 0
        }

        It 'exits 0 when comment lines precede a valid first line' {
            $f = Join-Path -Path $script:Fixtures -ChildPath 'comments-then-valid.txt'
            Set-Content -Path $f -Value "# template`nfeat: x"
            (Invoke-Hook -MessageFile $f).ExitCode | Should -Be 0
        }

        It 'exits 0 for each allowed type' {
            foreach ($t in 'docs', 'style', 'refactor', 'perf', 'test', 'build', 'ci', 'chore', 'revert') {
                $f = Join-Path -Path $script:Fixtures -ChildPath "$t.txt"
                Set-Content -Path $f -Value "${t}: ok"
                (Invoke-Hook -MessageFile $f).ExitCode | Should -Be 0 -Because "type '$t' must be allowed"
            }
        }
    }
}
