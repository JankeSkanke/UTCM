#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0' }
<#
.SYNOPSIS
    Unit tests for Compare-UTCMSnapshot — the most complex function in the module.
    Tests snapshot comparison logic using temporary on-disk snapshot files.
#>

BeforeAll {
    # Enable transcript logging for external test runs
    $transcriptPath = Join-Path $PSScriptRoot '..' 'logs' "Compare-UTCMSnapshot.Tests_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    $null = New-Item -Path (Split-Path $transcriptPath) -ItemType Directory -Force -ErrorAction SilentlyContinue
    Start-Transcript -Path $transcriptPath -Force
    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Starting Compare-UTCMSnapshot.Tests.ps1" -ForegroundColor Cyan
    Write-Host "[TRANSCRIPT] Logging to: $transcriptPath" -ForegroundColor Green

    $modulePath = Join-Path $PSScriptRoot '..' '..' 'UTCM.psd1'
    Import-Module $modulePath -Force

    # Mock Write-Host globally to suppress console output during tests
    Mock Write-Host -ModuleName UTCM -MockWith { }

    # Helper: create a temporary snapshot directory with a snapshot.json
    function New-TestSnapshot {
        param(
            [string]$BasePath,
            [string]$Name,
            [array]$Resources
        )
        $dir = Join-Path $BasePath $Name
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        $snap = @{ resources = $Resources }
        $snap | ConvertTo-Json -Depth 20 | Set-Content (Join-Path $dir 'snapshot.json') -Encoding utf8
        return $dir
    }
}

AfterAll {
    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Completed Compare-UTCMSnapshot.Tests.ps1" -ForegroundColor Cyan
    Remove-Module UTCM -Force -ErrorAction SilentlyContinue
    Stop-Transcript
}

Describe 'Compare-UTCMSnapshot' {

    BeforeAll {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Testing Compare-UTCMSnapshot" -ForegroundColor Yellow
        $tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) "utcm-tests-$([guid]::NewGuid().ToString('N'))"
        New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
    }

    AfterAll {
        Remove-Item $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    Context 'Identical snapshots' {
        BeforeAll {
            $resources = @(
                @{
                    resourceType = 'microsoft.entra.group'
                    displayName  = 'Group A'
                    properties   = @{ displayName = 'Group A'; description = 'Test' }
                }
            )
            $script:refPath = New-TestSnapshot -BasePath $tempRoot -Name 'identical-ref' -Resources $resources
            $script:difPath = New-TestSnapshot -BasePath $tempRoot -Name 'identical-dif' -Resources $resources
        }

        It 'Reports no changes' {
            $result = Compare-UTCMSnapshot -ReferencePath $refPath -DifferencePath $difPath
            $result.Summary.TotalChanges | Should -Be 0
            $result.ResourceChanges.Added   | Should -HaveCount 0
            $result.ResourceChanges.Removed | Should -HaveCount 0
            $result.ResourceChanges.Modified | Should -HaveCount 0
        }
    }

    Context 'Added resources' {
        BeforeAll {
            $refRes = @(
                @{
                    resourceType = 'microsoft.entra.group'
                    displayName  = 'Group A'
                    properties   = @{ displayName = 'Group A' }
                }
            )
            $difRes = @(
                @{
                    resourceType = 'microsoft.entra.group'
                    displayName  = 'Group A'
                    properties   = @{ displayName = 'Group A' }
                },
                @{
                    resourceType = 'microsoft.entra.group'
                    displayName  = 'Group B'
                    properties   = @{ displayName = 'Group B' }
                }
            )
            $script:refPath = New-TestSnapshot -BasePath $tempRoot -Name 'added-ref' -Resources $refRes
            $script:difPath = New-TestSnapshot -BasePath $tempRoot -Name 'added-dif' -Resources $difRes
        }

        It 'Detects the added resource' {
            $result = Compare-UTCMSnapshot -ReferencePath $refPath -DifferencePath $difPath
            $result.ResourceChanges.Added | Should -HaveCount 1
            $result.ResourceChanges.Added[0].DisplayName | Should -Be 'Group B'
        }
    }

    Context 'Removed resources' {
        BeforeAll {
            $refRes = @(
                @{
                    resourceType = 'microsoft.entra.group'
                    displayName  = 'Group A'
                    properties   = @{ displayName = 'Group A' }
                },
                @{
                    resourceType = 'microsoft.entra.group'
                    displayName  = 'Group B'
                    properties   = @{ displayName = 'Group B' }
                }
            )
            $difRes = @(
                @{
                    resourceType = 'microsoft.entra.group'
                    displayName  = 'Group A'
                    properties   = @{ displayName = 'Group A' }
                }
            )
            $script:refPath = New-TestSnapshot -BasePath $tempRoot -Name 'removed-ref' -Resources $refRes
            $script:difPath = New-TestSnapshot -BasePath $tempRoot -Name 'removed-dif' -Resources $difRes
        }

        It 'Detects the removed resource' {
            $result = Compare-UTCMSnapshot -ReferencePath $refPath -DifferencePath $difPath
            $result.ResourceChanges.Removed | Should -HaveCount 1
            $result.ResourceChanges.Removed[0].DisplayName | Should -Be 'Group B'
        }
    }

    Context 'Modified resources' {
        BeforeAll {
            $refRes = @(
                @{
                    resourceType = 'microsoft.entra.group'
                    displayName  = 'Group A'
                    properties   = @{ displayName = 'Group A'; description = 'Old' }
                }
            )
            $difRes = @(
                @{
                    resourceType = 'microsoft.entra.group'
                    displayName  = 'Group A'
                    properties   = @{ displayName = 'Group A'; description = 'New' }
                }
            )
            $script:refPath = New-TestSnapshot -BasePath $tempRoot -Name 'modified-ref' -Resources $refRes
            $script:difPath = New-TestSnapshot -BasePath $tempRoot -Name 'modified-dif' -Resources $difRes
        }

        It 'Detects modified properties' {
            $result = Compare-UTCMSnapshot -ReferencePath $refPath -DifferencePath $difPath
            $result.ResourceChanges.Modified | Should -HaveCount 1
            $result.ResourceChanges.Modified[0].DisplayName | Should -Be 'Group A'
        }
    }

    Context 'Resource type coverage gaps' {
        BeforeAll {
            $refRes = @(
                @{
                    resourceType = 'microsoft.entra.group'
                    displayName  = 'Group A'
                    properties   = @{ displayName = 'Group A' }
                }
            )
            $difRes = @(
                @{
                    resourceType = 'microsoft.entra.conditionalaccesspolicy'
                    displayName  = 'CA Policy'
                    properties   = @{ displayName = 'CA Policy' }
                }
            )
            $script:refPath = New-TestSnapshot -BasePath $tempRoot -Name 'coverage-ref' -Resources $refRes
            $script:difPath = New-TestSnapshot -BasePath $tempRoot -Name 'coverage-dif' -Resources $difRes
        }

        It 'Reports types only in reference' {
            $result = Compare-UTCMSnapshot -ReferencePath $refPath -DifferencePath $difPath
            $result.CoverageGaps | Should -Not -BeNullOrEmpty
            $refOnly = $result.CoverageGaps | Where-Object { $_.Side -eq 'Reference only' }
            $refOnly.ResourceType | Should -Contain 'microsoft.entra.group'
        }

        It 'Reports types only in difference' {
            $result = Compare-UTCMSnapshot -ReferencePath $refPath -DifferencePath $difPath
            $difOnly = $result.CoverageGaps | Where-Object { $_.Side -eq 'Difference only' }
            $difOnly.ResourceType | Should -Contain 'microsoft.entra.conditionalaccesspolicy'
        }

        It 'With -IncludeMissingTypes, treats them as Added/Removed' {
            $result = Compare-UTCMSnapshot -ReferencePath $refPath -DifferencePath $difPath -IncludeMissingTypes
            $result.ResourceChanges.Added   | Should -HaveCount 1
            $result.ResourceChanges.Removed | Should -HaveCount 1
        }
    }

    Context 'ResourceType filter' {
        BeforeAll {
            $resources = @(
                @{
                    resourceType = 'microsoft.entra.group'
                    displayName  = 'Group A'
                    properties   = @{ displayName = 'Group A' }
                },
                @{
                    resourceType = 'microsoft.entra.conditionalaccesspolicy'
                    displayName  = 'CA Policy'
                    properties   = @{ displayName = 'CA Policy' }
                }
            )
            $script:refPath = New-TestSnapshot -BasePath $tempRoot -Name 'filter-ref' -Resources $resources
            $script:difPath = New-TestSnapshot -BasePath $tempRoot -Name 'filter-dif' -Resources $resources
        }

        It 'Limits comparison to specified ResourceType' {
            $result = Compare-UTCMSnapshot -ReferencePath $refPath -DifferencePath $difPath `
                -ResourceType 'microsoft.entra.group'
            # Should process only grouptype, so no changes but no CA policy in scope
            $result.Summary.TotalChanges | Should -Be 0
        }
    }

    Context 'ExcludeResourceType filter' {
        BeforeAll {
            $refRes = @(
                @{
                    resourceType = 'microsoft.entra.group'
                    displayName  = 'Group A'
                    properties   = @{ displayName = 'Group A'; description = 'Old' }
                },
                @{
                    resourceType = 'microsoft.entra.user'
                    displayName  = 'User 1'
                    properties   = @{ displayName = 'User 1' }
                }
            )
            $difRes = @(
                @{
                    resourceType = 'microsoft.entra.group'
                    displayName  = 'Group A'
                    properties   = @{ displayName = 'Group A'; description = 'New' }
                },
                @{
                    resourceType = 'microsoft.entra.user'
                    displayName  = 'User 1'
                    properties   = @{ displayName = 'User 1' }
                }
            )
            $script:refPath = New-TestSnapshot -BasePath $tempRoot -Name 'exclude-ref' -Resources $refRes
            $script:difPath = New-TestSnapshot -BasePath $tempRoot -Name 'exclude-dif' -Resources $difRes
        }

        It 'Excludes the specified resource type' {
            $result = Compare-UTCMSnapshot -ReferencePath $refPath -DifferencePath $difPath `
                -ExcludeResourceType 'microsoft.entra.group'
            # Only user type left which is identical → no changes
            $result.Summary.TotalChanges | Should -Be 0
        }
    }

    Context 'Output format validation' {
        BeforeAll {
            $resources = @(
                @{
                    resourceType = 'microsoft.entra.group'
                    displayName  = 'Group A'
                    properties   = @{ displayName = 'Group A' }
                }
            )
            $script:refPath = New-TestSnapshot -BasePath $tempRoot -Name 'output-ref' -Resources $resources
            $script:difPath = New-TestSnapshot -BasePath $tempRoot -Name 'output-dif' -Resources $resources
        }

        It 'Throws when OutputFormat is set without OutputPath' {
            { Compare-UTCMSnapshot -ReferencePath $refPath -DifferencePath $difPath -OutputFormat CSV } |
                Should -Throw '*-OutputPath*'
        }

        It 'Exports to CSV without error' {
            $csvPath = Join-Path $tempRoot 'test-output.csv'
            { Compare-UTCMSnapshot -ReferencePath $refPath -DifferencePath $difPath `
                -OutputFormat CSV -OutputPath $csvPath } | Should -Not -Throw
        }

        It 'Exports to JSON without error' {
            $jsonPath = Join-Path $tempRoot 'test-output.json'
            { Compare-UTCMSnapshot -ReferencePath $refPath -DifferencePath $difPath `
                -OutputFormat JSON -OutputPath $jsonPath } | Should -Not -Throw
        }

        It 'Exports to HTML without error' {
            $htmlPath = Join-Path $tempRoot 'test-output.html'
            { Compare-UTCMSnapshot -ReferencePath $refPath -DifferencePath $difPath `
                -OutputFormat HTML -OutputPath $htmlPath } | Should -Not -Throw
        }
    }

    Context 'Invalid paths' {
        It 'Throws when ReferencePath does not exist' {
            { Compare-UTCMSnapshot -ReferencePath 'C:\nonexistent\ref' -DifferencePath 'C:\nonexistent\dif' } |
                Should -Throw '*not found*'
        }
    }
}
