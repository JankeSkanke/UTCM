#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0' }
<#
.SYNOPSIS
    Module-level tests — validates manifest, exported functions, and module loading.
#>

BeforeAll {
    # Enable transcript logging for external test runs
    $transcriptPath = Join-Path $PSScriptRoot 'logs' "Module.Tests_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    $null = New-Item -Path (Split-Path $transcriptPath) -ItemType Directory -Force -ErrorAction SilentlyContinue
    Start-Transcript -Path $transcriptPath -Force
    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Starting UTCM.Module.Tests.ps1" -ForegroundColor Cyan
    Write-Host "[TRANSCRIPT] Logging to: $transcriptPath" -ForegroundColor Green

    $modulePath = Join-Path $PSScriptRoot '..' 'UTCM.psd1'
    $manifest   = Test-ModuleManifest -Path $modulePath -ErrorAction Stop
}

Describe 'UTCM Module' {

    Context 'Manifest validation' {
        It 'Has a valid module manifest' {
            $manifest | Should -Not -BeNullOrEmpty
        }

        It 'Has RootModule set to UTCM.psm1' {
            $manifest.RootModule | Should -Be 'UTCM.psm1'
        }

        It 'Has a valid version number' {
            $manifest.Version | Should -Not -BeNullOrEmpty
            $manifest.Version.ToString() | Should -Match '^\d+\.\d+\.\d+$'
        }

        It 'Requires PowerShell 7.0 or later' {
            $manifest.PowerShellVersion | Should -Be '7.0'
        }

        It 'Has a non-empty description' {
            $manifest.Description | Should -Not -BeNullOrEmpty
        }

        It 'Has a valid GUID' {
            $manifest.Guid | Should -Not -Be ([guid]::Empty)
        }
    }

    Context 'Exported functions' {
        BeforeAll {
            $expectedPublic = @(
                'Connect-UTCM'
                'Disconnect-UTCM'
                'Get-UTCMContext'
                'Get-UTCMMonitor'
                'New-UTCMMonitor'
                'Set-UTCMMonitor'
                'Remove-UTCMMonitor'
                'Get-UTCMBaseline'
                'Get-UTCMDrift'
                'Get-UTCMMonitoringResult'
                'New-UTCMSnapshot'
                'Get-UTCMSnapshot'
                'Remove-UTCMSnapshot'
                'Save-UTCMSnapshot'
                'Wait-UTCMSnapshot'
                'Compare-UTCMSnapshot'
                'Install-UTCMServicePrincipal'
                'Grant-UTCMPermission'
                'Grant-UTCMDirectoryRole'
            )
        }

        It 'Exports exactly 19 functions' {
            $manifest.ExportedFunctions.Count | Should -Be 19
        }

        It 'Exports <_>' -ForEach @(
            'Connect-UTCM'
            'Disconnect-UTCM'
            'Get-UTCMContext'
            'Get-UTCMMonitor'
            'New-UTCMMonitor'
            'Set-UTCMMonitor'
            'Remove-UTCMMonitor'
            'Get-UTCMBaseline'
            'Get-UTCMDrift'
            'Get-UTCMMonitoringResult'
            'New-UTCMSnapshot'
            'Get-UTCMSnapshot'
            'Remove-UTCMSnapshot'
            'Save-UTCMSnapshot'
            'Wait-UTCMSnapshot'
            'Compare-UTCMSnapshot'
            'Install-UTCMServicePrincipal'
            'Grant-UTCMPermission'
            'Grant-UTCMDirectoryRole'
        ) {
            $manifest.ExportedFunctions.Keys | Should -Contain $_
        }

        It 'Does not export cmdlets' {
            $manifest.ExportedCmdlets.Count | Should -Be 0
        }

        It 'Does not export variables' {
            $manifest.ExportedVariables.Count | Should -Be 0
        }

        It 'Does not export aliases' {
            $manifest.ExportedAliases.Count | Should -Be 0
        }
    }

    Context 'File structure' {
        It 'Has a Public function file for each exported function' {
            foreach ($fn in $manifest.ExportedFunctions.Keys) {
                $file = Join-Path $PSScriptRoot '..' 'Public' "$fn.ps1"
                $file | Should -Exist
            }
        }

        It 'Has the expected Private helper files' -ForEach @(
            'Assert-UTCMConnected.ps1'
            'Get-UTCMAuthHeaders.ps1'
            'Get-UTCMTokenContext.ps1'
            'Invoke-UTCMGraphRequest.ps1'
            'Write-UTCMContext.ps1'
        ) {
            Join-Path $PSScriptRoot '..' 'Private' $_ | Should -Exist
        }
    }

    Context 'Module loading' {
        BeforeAll {
            # Import the module fresh for loading tests
            Import-Module $modulePath -Force -ErrorAction Stop
        }

        AfterAll {
            Remove-Module UTCM -Force -ErrorAction SilentlyContinue
        }

        It 'Loads without errors' {
            Get-Module UTCM | Should -Not -BeNullOrEmpty
        }

        It 'All 19 functions are available after import' {
            $commands = Get-Command -Module UTCM
            $commands.Count | Should -Be 19
        }
    }
}

AfterAll {
    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Completed UTCM.Module.Tests.ps1" -ForegroundColor Cyan
    Remove-Module UTCM -Force -ErrorAction SilentlyContinue
    Stop-Transcript
}
