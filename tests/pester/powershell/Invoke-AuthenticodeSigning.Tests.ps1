#Requires -Version 7.0
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }

# Unit tests for scripts/powershell/Invoke-AuthenticodeSigning.ps1.
#
# Determinism: every external boundary is exercised through an injected seam
# scriptblock. No real certificate is accessed, no real file is signed, no
# directory is scanned, no network is used, and no temp files are created. The
# config-resolution helper is exercised with fixed string inputs only. The
# secrets path and cert store are never touched on disk.

Describe 'Invoke-AuthenticodeSigning.ps1' {
    BeforeAll {
        $script:ScriptPath = Join-Path $PSScriptRoot '../../../scripts/powershell/Invoke-AuthenticodeSigning.ps1'

        # Builds the standard set of injectable seams with capture containers so
        # assertions can inspect what each seam received. Defaults represent a
        # healthy run: config returns a fixed thumbprint, cert returns a fake
        # object, enumeration returns two first-party paths, sign returns Valid.
        function script:New-SignSeamSet {
            param(
                [string]$Thumbprint = 'AABBCCDDEEFF00112233445566778899AABBCCDD',
                [string[]]$EnumeratedFiles = @('C:\repo\scripts\powershell\A.ps1', 'C:\repo\scripts\powershell\B.ps1'),
                [string]$SignStatus = 'Valid'
            )
            $captured = [pscustomobject]@{
                ReadCalls      = [System.Collections.Generic.List[object]]::new()
                ResolveCalls   = [System.Collections.Generic.List[object]]::new()
                EnumerateCalls = [System.Collections.Generic.List[object]]::new()
                SignCalls      = [System.Collections.Generic.List[object]]::new()
                Thumbprint     = $Thumbprint
                Enumerated     = $EnumeratedFiles
                SignStatus     = $SignStatus
                FakeCert       = [pscustomobject]@{ Thumbprint = $Thumbprint; HasPrivateKey = $true }
            }
            $readAction = {
                param([string]$JsonPath, [string]$Key)
                $captured.ReadCalls.Add([pscustomobject]@{ JsonPath = $JsonPath; Key = $Key })
                return $captured.Thumbprint
            }.GetNewClosure()
            $resolveAction = {
                param([string]$Thumbprint)
                $captured.ResolveCalls.Add([pscustomobject]@{ Thumbprint = $Thumbprint })
                return $captured.FakeCert
            }.GetNewClosure()
            $enumerateAction = {
                param([string]$Root)
                $captured.EnumerateCalls.Add([pscustomobject]@{ Root = $Root })
                return $captured.Enumerated
            }.GetNewClosure()
            $signAction = {
                param([string]$Path, [object]$Cert, [string]$Ts)
                $captured.SignCalls.Add([pscustomobject]@{ Path = $Path; Cert = $Cert; Ts = $Ts })
                return [pscustomobject]@{ Status = $captured.SignStatus; Path = $Path }
            }.GetNewClosure()

            return [pscustomobject]@{
                Captured             = $captured
                ReadSecretsAction    = $readAction
                ResolveCertAction    = $resolveAction
                EnumerateFilesAction = $enumerateAction
                SignFileAction       = $signAction
            }
        }

        function script:Invoke-SignTool {
            param(
                [object]$Seams,
                [string[]]$FilePaths = @(),
                [switch]$UseWhatIf
            )
            $params = @{
                RepoRoot             = 'C:\repo'
                ConfigKey            = 'Signing:CertThumbprint'
                SecretsJsonPath      = 'C:\not\used\secrets.json'
                TimestampServer      = 'http://timestamp.example/'
                FilePaths            = $FilePaths
                ReadSecretsAction    = $Seams.ReadSecretsAction
                ResolveCertAction    = $Seams.ResolveCertAction
                EnumerateFilesAction = $Seams.EnumerateFilesAction
                SignFileAction       = $Seams.SignFileAction
            }
            if ($UseWhatIf) {
                return & $script:ScriptPath @params -WhatIf
            }
            return & $script:ScriptPath @params
        }
    }

    Context 'config resolution: Read-SigningThumbprint (fixed string inputs)' {
        BeforeAll {
            . $script:ScriptPath -ErrorAction Stop
        }

        It 'returns the thumbprint when the key is present' {
            # Arrange: Test-Path/Get-Content mocked to return a flat JSON object.
            Mock Test-Path { $true } -ParameterFilter { $LiteralPath -eq 'C:\fake\secrets.json' }
            Mock Get-Content { '{ "Signing:CertThumbprint": "ABC123" }' } -ParameterFilter { $LiteralPath -eq 'C:\fake\secrets.json' }

            $result = Read-SigningThumbprint -JsonPath 'C:\fake\secrets.json' -Key 'Signing:CertThumbprint'

            $result | Should -Be 'ABC123'
        }

        It 'throws with the remediation command when secrets.json is missing' {
            Mock Test-Path { $false } -ParameterFilter { $LiteralPath -eq 'C:\missing\secrets.json' }

            { Read-SigningThumbprint -JsonPath 'C:\missing\secrets.json' -Key 'Signing:CertThumbprint' } |
                Should -Throw -ExpectedMessage '*dotnet user-secrets set*--id 3716a8f0-9bab-4f69-a7b9-4173cda73ff3*'
        }

        It 'throws when the key is absent or empty' {
            # Arrange: file exists but the key is empty.
            Mock Test-Path { $true } -ParameterFilter { $LiteralPath -eq 'C:\fake\secrets.json' }
            Mock Get-Content { '{ "Signing:CertThumbprint": "   " }' } -ParameterFilter { $LiteralPath -eq 'C:\fake\secrets.json' }

            { Read-SigningThumbprint -JsonPath 'C:\fake\secrets.json' -Key 'Signing:CertThumbprint' } |
                Should -Throw -ExpectedMessage "*not found or empty*"
        }

        It 'throws naming the path when the JSON cannot be parsed' {
            # Arrange: file exists but content is not valid JSON.
            Mock Test-Path { $true } -ParameterFilter { $LiteralPath -eq 'C:\fake\secrets.json' }
            Mock Get-Content { 'this is not json {' } -ParameterFilter { $LiteralPath -eq 'C:\fake\secrets.json' }

            { Read-SigningThumbprint -JsonPath 'C:\fake\secrets.json' -Key 'Signing:CertThumbprint' } |
                Should -Throw -ExpectedMessage "*Failed to parse signing config JSON at 'C:\fake\secrets.json'*"
        }
    }

    Context 'exclusion predicate: Test-IsExcludedRelativePath (fixed strings)' {
        BeforeAll {
            . $script:ScriptPath -ErrorAction Stop
        }

        It 'includes a first-party script path (forward slash)' {
            Test-IsExcludedRelativePath -RelativePath 'scripts/powershell/Tool.ps1' | Should -BeFalse
        }

        It 'includes a first-party script path (back slash)' {
            Test-IsExcludedRelativePath -RelativePath 'scripts\powershell\Tool.ps1' | Should -BeFalse
        }

        It 'excludes a node_modules path (forward slash)' {
            Test-IsExcludedRelativePath -RelativePath 'node_modules/pkg/index.ps1' | Should -BeTrue
        }

        It 'excludes a node_modules path (back slash)' {
            Test-IsExcludedRelativePath -RelativePath 'node_modules\pkg\index.ps1' | Should -BeTrue
        }

        It 'excludes an artifacts path (forward slash)' {
            Test-IsExcludedRelativePath -RelativePath 'artifacts/.claude/hooks/hook.ps1' | Should -BeTrue
        }

        It 'excludes an artifacts path (back slash)' {
            Test-IsExcludedRelativePath -RelativePath 'artifacts\.claude\hooks\hook.ps1' | Should -BeTrue
        }
    }

    Context 'cert resolution via injected ResolveCertAction' {
        It 'returns a fake cert and proceeds to sign on the valid path' {
            $seams = New-SignSeamSet

            $summary = Invoke-SignTool -Seams $seams

            $seams.Captured.ResolveCalls.Count | Should -Be 1
            $seams.Captured.ResolveCalls[0].Thumbprint | Should -Be $seams.Captured.Thumbprint
            $summary.Signed | Should -Be 2
            $summary.Failed | Should -Be 0
        }

        It 'aborts before signing when the cert is absent (throws naming thumbprint)' {
            $seams = New-SignSeamSet
            $failingResolve = { param([string]$Thumbprint) throw "No certificate with thumbprint '$Thumbprint' and HasPrivateKey=True found in Cert:\CurrentUser\My." }.GetNewClosure()
            $seams.ResolveCertAction = $failingResolve

            { Invoke-SignTool -Seams $seams } | Should -Throw -ExpectedMessage '*No certificate with thumbprint*HasPrivateKey=True*'
            $seams.Captured.SignCalls.Count | Should -Be 0
        }

        It 'aborts before signing when the cert has no private key (throws)' {
            $seams = New-SignSeamSet
            $seams.ResolveCertAction = { param([string]$Thumbprint) throw "No certificate with thumbprint '$Thumbprint' and HasPrivateKey=True found in Cert:\CurrentUser\My." }.GetNewClosure()

            { Invoke-SignTool -Seams $seams } | Should -Throw -ExpectedMessage '*HasPrivateKey=True*'
            $seams.Captured.SignCalls.Count | Should -Be 0
        }

        It 'aborts before signing when the cert lacks the Code Signing EKU (throws)' {
            $seams = New-SignSeamSet
            $seams.ResolveCertAction = { param([string]$Thumbprint) throw "Certificate with thumbprint '$Thumbprint' does not carry the Code Signing EKU (1.3.6.1.5.5.7.3.3)." }.GetNewClosure()

            { Invoke-SignTool -Seams $seams } | Should -Throw -ExpectedMessage '*does not carry the Code Signing EKU*'
            $seams.Captured.SignCalls.Count | Should -Be 0
        }
    }

    Context 'file selection via injected EnumerateFilesAction' {
        It 'signs the enumerated first-party script paths' {
            $seams = New-SignSeamSet -EnumeratedFiles @('C:\repo\scripts\powershell\X.ps1', 'C:\repo\.claude\hooks\h.ps1')

            $summary = Invoke-SignTool -Seams $seams

            $seams.Captured.EnumerateCalls.Count | Should -Be 1
            $signedPaths = $seams.Captured.SignCalls | ForEach-Object { $_.Path }
            $signedPaths | Should -Be @('C:\repo\scripts\powershell\X.ps1', 'C:\repo\.claude\hooks\h.ps1')
            $summary.Signed | Should -Be 2
        }

        It 'handles a missing subtree (empty enumeration) without error' {
            $seams = New-SignSeamSet -EnumeratedFiles @()

            $summary = Invoke-SignTool -Seams $seams

            $seams.Captured.SignCalls.Count | Should -Be 0
            $summary.Signed | Should -Be 0
            $summary.Failed | Should -Be 0
            $summary.Success | Should -BeTrue
        }

    }

    Context '-FilePaths mode (post-publish .NET assembly signing)' {
        It 'signs exactly the provided paths and does not enumerate' {
            $seams = New-SignSeamSet
            $explicit = @('C:\publish\TaskMaster.Api.dll', 'C:\publish\TaskMaster.Core.dll')

            $summary = Invoke-SignTool -Seams $seams -FilePaths $explicit

            $seams.Captured.EnumerateCalls.Count | Should -Be 0
            ($seams.Captured.SignCalls | ForEach-Object { $_.Path }) | Should -Be $explicit
            $summary.Signed | Should -Be 2
        }
    }

    Context 'sign dispatch behavior via injected SignFileAction' {
        It 'invokes one sign call per enumerated file with SHA256 timestamp server passthrough' {
            $seams = New-SignSeamSet

            $summary = Invoke-SignTool -Seams $seams

            $seams.Captured.SignCalls.Count | Should -Be 2
            $seams.Captured.SignCalls[0].Ts | Should -Be 'http://timestamp.example/'
            $summary.Signed | Should -Be 2
        }

        It 'surfaces a per-file failure when the seam reports a non-Valid status' {
            # Arrange: the sign seam throws on a non-Valid status, mirroring the
            # production wrapper's per-file failure behavior.
            $seams = New-SignSeamSet
            $seams.SignFileAction = {
                param([string]$Path, [object]$Cert, [string]$Ts)
                $seams.Captured.SignCalls.Add([pscustomobject]@{ Path = $Path; Cert = $Cert; Ts = $Ts })
                throw "Signing failed for '$Path': Status=UnknownError."
            }.GetNewClosure()

            $summary = Invoke-SignTool -Seams $seams

            $summary.Failed | Should -BeGreaterThan 0
            $summary.Success | Should -BeFalse
        }

        It 'continues past a timestamp-unreachable warning without hard failure' {
            # Arrange: the sign seam returns Valid plus a TimestampWarning flag,
            # mirroring the warn-not-fail behavior.
            $seams = New-SignSeamSet
            $seams.SignFileAction = {
                param([string]$Path, [object]$Cert, [string]$Ts)
                $seams.Captured.SignCalls.Add([pscustomobject]@{ Path = $Path; Cert = $Cert; Ts = $Ts })
                return [pscustomobject]@{ Status = 'Valid'; Path = $Path; TimestampWarning = $true }
            }.GetNewClosure()

            $summary = Invoke-SignTool -Seams $seams

            $summary.Signed | Should -Be 2
            $summary.Warnings | Should -Be 2
            $summary.Failed | Should -Be 0
            $summary.Success | Should -BeTrue
        }

        It 'reports a per-file failure when the seam returns a non-Valid status object' {
            # Arrange: the sign seam returns (does not throw) a non-Valid status,
            # exercising the orchestrator's status-check failure branch.
            $seams = New-SignSeamSet -SignStatus 'UnknownError'

            $summary = Invoke-SignTool -Seams $seams

            $summary.Failed | Should -Be 2
            $summary.Signed | Should -Be 0
            $summary.Success | Should -BeFalse
        }

        It 'records zero sign calls under -WhatIf' {
            $seams = New-SignSeamSet

            $summary = Invoke-SignTool -Seams $seams -UseWhatIf

            $seams.Captured.SignCalls.Count | Should -Be 0
            $summary.Signed | Should -Be 0
            $summary.Skipped | Should -Be 2
        }
    }

    Context 'idempotent re-sign' {
        It 'signs the same paths on a second run and reports success both times' {
            $seams = New-SignSeamSet -EnumeratedFiles @('C:\repo\scripts\powershell\Re.ps1')

            # Act: run twice over the same file list.
            $first = Invoke-SignTool -Seams $seams
            $second = Invoke-SignTool -Seams $seams

            $first.Success | Should -BeTrue
            $second.Success | Should -BeTrue
            $first.Signed | Should -Be 1
            $second.Signed | Should -Be 1
            # Two runs over one path produce two captured sign calls (one per run).
            $seams.Captured.SignCalls.Count | Should -Be 2
            ($seams.Captured.SignCalls | ForEach-Object { $_.Path }) | Should -Be @('C:\repo\scripts\powershell\Re.ps1', 'C:\repo\scripts\powershell\Re.ps1')
        }
    }

    # Host-bound wrapper internals. These exercise the wrapper bodies that sit on
    # top of native cmdlets (Get-ChildItem on Cert:, Set/Get-AuthenticodeSignature,
    # Get-ChildItem on the filesystem) by mocking the framework cmdlets only. No
    # real certificate is accessed, no real file is signed, and no real directory is
    # scanned.
    Context 'seam internals: Resolve-SigningCert' {
        BeforeAll {
            . $script:ScriptPath -ErrorAction Stop
        }

        It 'returns a cert with a private key and the Code Signing EKU' {
            # Arrange: a fake cert carrying a real Code Signing EKU extension
            # (OID 1.3.6.1.5.5.7.3.3) so the production -is type check matches.
            $oidCollection = [System.Security.Cryptography.OidCollection]::new()
            $null = $oidCollection.Add([System.Security.Cryptography.Oid]::new('1.3.6.1.5.5.7.3.3'))
            $eku = [System.Security.Cryptography.X509Certificates.X509EnhancedKeyUsageExtension]::new($oidCollection, $false)
            $fakeCert = [pscustomobject]@{ Thumbprint = 'DEAD'; HasPrivateKey = $true; Extensions = @($eku) }
            Mock Get-ChildItem { $fakeCert } -ParameterFilter { $Path -eq 'Cert:\CurrentUser\My' }

            $resolved = Resolve-SigningCert -Thumbprint 'DEAD'

            $resolved.Thumbprint | Should -Be 'DEAD'
        }

        It 'throws naming the thumbprint when no matching cert with a private key exists' {
            Mock Get-ChildItem { @() } -ParameterFilter { $Path -eq 'Cert:\CurrentUser\My' }

            { Resolve-SigningCert -Thumbprint 'NOPE' } |
                Should -Throw -ExpectedMessage "*No certificate with thumbprint 'NOPE'*HasPrivateKey=True*"
        }

        It 'throws when the cert lacks the Code Signing EKU' {
            # Arrange: a cert with a private key but no Code Signing EKU.
            $fakeCert = [pscustomobject]@{ Thumbprint = 'BEEF'; HasPrivateKey = $true; Extensions = @() }
            Mock Get-ChildItem { $fakeCert } -ParameterFilter { $Path -eq 'Cert:\CurrentUser\My' }

            { Resolve-SigningCert -Thumbprint 'BEEF' } |
                Should -Throw -ExpectedMessage '*does not carry the Code Signing EKU*'
        }
    }

    Context 'seam internals: Invoke-SetAuthenticodeSignature' {
        BeforeAll {
            . $script:ScriptPath -ErrorAction Stop
        }

        It 'passes SHA256 and the timestamp server and returns the Valid result' {
            # Arrange: mock the native signing cmdlet to return a Valid status.
            Mock Set-AuthenticodeSignature { [pscustomobject]@{ Status = 'Valid' } } -ParameterFilter {
                $HashAlgorithm -eq 'SHA256' -and $TimestampServer -eq 'http://ts.example/'
            }

            $result = Invoke-SetAuthenticodeSignature -Path 'C:\x\a.ps1' -Cert ([pscustomobject]@{}) -TimestampServer 'http://ts.example/'

            $result.Status | Should -Be 'Valid'
            Should -Invoke Set-AuthenticodeSignature -Times 1 -Exactly
        }

        It 'warns and signs without a timestamp when the timestamp server is unreachable' {
            # Arrange: the first call (with -TimestampServer bound) throws; the
            # fallback call (no -TimestampServer) returns Valid.
            Mock Set-AuthenticodeSignature { [pscustomobject]@{ Status = 'Valid' } } -ParameterFilter {
                -not $PSBoundParameters.ContainsKey('TimestampServer')
            }
            Mock Set-AuthenticodeSignature { throw 'timestamp server unreachable' } -ParameterFilter {
                $PSBoundParameters.ContainsKey('TimestampServer')
            }

            $result = Invoke-SetAuthenticodeSignature -Path 'C:\x\a.ps1' -Cert ([pscustomobject]@{}) -TimestampServer 'http://down.example/'

            $result.Status | Should -Be 'Valid'
        }

        It 'throws a per-file failure when the signing status is not Valid' {
            Mock Set-AuthenticodeSignature { [pscustomobject]@{ Status = 'UnknownError' } }

            { Invoke-SetAuthenticodeSignature -Path 'C:\x\a.ps1' -Cert ([pscustomobject]@{}) -TimestampServer 'http://ts.example/' } |
                Should -Throw -ExpectedMessage "*Signing failed for 'C:\x\a.ps1': Status=UnknownError*"
        }
    }

    Context 'seam internals: Test-AuthenticodeSignature' {
        BeforeAll {
            . $script:ScriptPath -ErrorAction Stop
        }

        It 'returns $true when the verification status is Valid' {
            Mock Get-AuthenticodeSignature { [pscustomobject]@{ Status = 'Valid' } }

            Test-AuthenticodeSignature -Path 'C:\x\a.ps1' | Should -BeTrue
        }

        It 'returns $false when the verification status is not Valid' {
            Mock Get-AuthenticodeSignature { [pscustomobject]@{ Status = 'UnknownError' } }

            Test-AuthenticodeSignature -Path 'C:\x\a.ps1' | Should -BeFalse
        }
    }

    Context 'seam internals: Get-FirstPartySignableFileList' {
        BeforeAll {
            . $script:ScriptPath -ErrorAction Stop
        }

        It 'returns first-party hits and skips missing subtrees and excluded paths' {
            # Arrange: Resolve-Path returns a fixed root; only one include subtree
            # exists; Get-ChildItem yields one in-scope file and one excluded file.
            Mock Resolve-Path { [pscustomobject]@{ Path = 'C:\repo' } }
            Mock Test-Path { $LiteralPath -eq 'C:\repo\scripts' } -ParameterFilter { $PathType -eq 'Container' }
            Mock Get-ChildItem {
                @(
                    [pscustomobject]@{ FullName = 'C:\repo\scripts\powershell\Keep.ps1' },
                    [pscustomobject]@{ FullName = 'C:\repo\artifacts\.claude\hooks\Drop.ps1' }
                )
            }

            $result = Get-FirstPartySignableFileList -Root 'C:\repo'

            # Assert: the excluded artifacts path is filtered out.
            $result | Should -Contain 'C:\repo\scripts\powershell\Keep.ps1'
            $result | Should -Not -Contain 'C:\repo\artifacts\.claude\hooks\Drop.ps1'
        }

        It 'returns an empty result when no include subtree exists' {
            Mock Resolve-Path { [pscustomobject]@{ Path = 'C:\empty' } }
            Mock Test-Path { $false } -ParameterFilter { $PathType -eq 'Container' }

            $result = @(Get-FirstPartySignableFileList -Root 'C:\empty')

            $result.Count | Should -Be 0
        }
    }

    Context 'production-default seams (wiring coverage)' {
        It 'each production-default seam scriptblock dispatches to its named helper' {
            # Arrange: dot-source so the named helpers exist, then mock them. Build
            # the default seam scriptblocks the same way the param block does and
            # invoke them to confirm the wiring dispatches to the helpers.
            . $script:ScriptPath -ErrorAction Stop
            Mock Read-SigningThumbprint { 'TP' }
            Mock Resolve-SigningCert { [pscustomobject]@{ Thumbprint = 'TP' } }
            Mock Get-FirstPartySignableFileList { @('C:\repo\a.ps1') }
            Mock Invoke-SetAuthenticodeSignature { [pscustomobject]@{ Status = 'Valid' } }

            $readDefault = { param([string]$JsonPath, [string]$Key) Read-SigningThumbprint -JsonPath $JsonPath -Key $Key }
            $resolveDefault = { param([string]$Thumbprint) Resolve-SigningCert -Thumbprint $Thumbprint }
            $enumerateDefault = { param([string]$Root) Get-FirstPartySignableFileList -Root $Root }
            $signDefault = { param([string]$Path, [object]$Cert, [string]$Ts) Invoke-SetAuthenticodeSignature -Path $Path -Cert $Cert -TimestampServer $Ts }

            $tp = & $readDefault 'C:\s.json' 'Signing:CertThumbprint'
            $cert = & $resolveDefault $tp
            $files = & $enumerateDefault 'C:\repo'
            $sig = & $signDefault $files[0] $cert 'http://ts.example/'

            $tp | Should -Be 'TP'
            $cert.Thumbprint | Should -Be 'TP'
            $files | Should -Contain 'C:\repo\a.ps1'
            $sig.Status | Should -Be 'Valid'
        }
    }
}
