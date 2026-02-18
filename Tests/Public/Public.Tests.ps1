#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0' }
<#
.SYNOPSIS
    Unit tests for Public functions — Connection, Context, Monitor CRUD,
    Snapshot, Drift, Results, Setup helpers.
#>

BeforeAll {
    # Enable transcript logging for external test runs
    $transcriptPath = Join-Path $PSScriptRoot '..' 'logs' "Public.Tests_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    $null = New-Item -Path (Split-Path $transcriptPath) -ItemType Directory -Force -ErrorAction SilentlyContinue
    Start-Transcript -Path $transcriptPath -Force
    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Starting Public.Tests.ps1" -ForegroundColor Cyan
    Write-Host "[TRANSCRIPT] Logging to: $transcriptPath" -ForegroundColor Green

    $modulePath = Join-Path $PSScriptRoot '..' '..' 'UTCM.psd1'
    Import-Module $modulePath -Force
    $internalModule = Get-Module UTCM

    # Set up a valid token context so all functions pass Assert-UTCMConnected
    & $internalModule {
        $script:Token      = 'fake-token-for-testing'
        $script:TokenExpiry = (Get-Date).AddHours(1)
        $script:Context    = @{
            Account    = 'test@contoso.com'
            TenantId   = 'test-tenant-id'
            ObjectId   = 'test-object-id'
            AppId      = 'test-app-id'
            Scopes     = @('openid')
            ExpiresOn  = (Get-Date).AddHours(1)
            AuthMethod = 'Delegated'
        }
    }

    # Mock Write-Host globally to suppress console output during tests
    Mock Write-Host -ModuleName UTCM -MockWith { }
}

AfterAll {
    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Completed Public.Tests.ps1" -ForegroundColor Cyan
    Remove-Module UTCM -Force -ErrorAction SilentlyContinue
    Stop-Transcript
}

# ═══════════════════════════════════════════════════════════════════════════
# Connect-UTCM  (Token parameter set only — no browser/HTTP in tests)
# ═══════════════════════════════════════════════════════════════════════════
Describe 'Connect-UTCM' {

    Context 'Token parameter set' {
        BeforeAll {
            # Create a minimal valid JWT
            $header  = @{ alg = 'none' } | ConvertTo-Json -Compress
            $payload = @{
                upn  = 'admin@contoso.com'
                tid  = 'aaa-bbb-ccc'
                oid  = 'ddd-eee-fff'
                scp  = 'openid'
                exp  = ([DateTimeOffset](Get-Date).AddHours(1)).ToUnixTimeSeconds()
            } | ConvertTo-Json -Compress
            $b64 = { param($t) [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($t)) -replace '\+','-' -replace '/','_' -replace '=' }
            $script:testJwt = "$(&$b64 $header).$(&$b64 $payload).sig"
        }

        It 'Sets the module token from -AccessToken' {
            Connect-UTCM -AccessToken $testJwt
            $ctx = Get-UTCMContext
            $ctx.Account | Should -Be 'admin@contoso.com'
        }

        It 'Sets the TenantId from the token' {
            Connect-UTCM -AccessToken $testJwt
            $ctx = Get-UTCMContext
            $ctx.TenantId | Should -Be 'aaa-bbb-ccc'
        }
    }
}

# ═══════════════════════════════════════════════════════════════════════════
# Disconnect-UTCM
# ═══════════════════════════════════════════════════════════════════════════
Describe 'Disconnect-UTCM' {

    It 'Clears token and context' {
        # Ensure connected first
        & $internalModule {
            $script:Token      = 'will-be-cleared'
            $script:TokenExpiry = (Get-Date).AddHours(1)
            $script:Context    = @{ Account = 'x' }
        }
        Disconnect-UTCM
        $ctx = Get-UTCMContext 3>&1  # capture warning
        # After disconnect, context should be null → warning emitted
        ($ctx | Where-Object { $_ -is [System.Management.Automation.WarningRecord] }) |
            Should -Not -BeNullOrEmpty
    }

    AfterAll {
        # Restore valid state for subsequent tests
        & $internalModule {
            $script:Token      = 'fake-token-for-testing'
            $script:TokenExpiry = (Get-Date).AddHours(1)
            $script:Context    = @{
                Account    = 'test@contoso.com'
                TenantId   = 'test-tenant-id'
                ObjectId   = 'test-object-id'
                AppId      = 'test-app-id'
                Scopes     = @('openid')
                ExpiresOn  = (Get-Date).AddHours(1)
                AuthMethod = 'Delegated'
            }
        }
    }
}

# ═══════════════════════════════════════════════════════════════════════════
# Get-UTCMContext
# ═══════════════════════════════════════════════════════════════════════════
Describe 'Get-UTCMContext' {

    It 'Returns a PSCustomObject when connected' {
        $ctx = Get-UTCMContext
        $ctx | Should -Not -BeNullOrEmpty
        $ctx.Account | Should -Be 'test@contoso.com'
    }

    It 'Returns $null and warns when not connected' {
        & $internalModule { $script:Context = $null }
        $result = Get-UTCMContext 3>&1
        ($result | Where-Object { $_ -is [System.Management.Automation.WarningRecord] }) |
            Should -Not -BeNullOrEmpty
    }

    AfterAll {
        & $internalModule {
            $script:Context = @{
                Account    = 'test@contoso.com'
                TenantId   = 'test-tenant-id'
                ObjectId   = 'test-object-id'
                AppId      = 'test-app-id'
                Scopes     = @('openid')
                ExpiresOn  = (Get-Date).AddHours(1)
                AuthMethod = 'Delegated'
            }
        }
    }
}

# ═══════════════════════════════════════════════════════════════════════════
# Get-UTCMMonitor
# ═══════════════════════════════════════════════════════════════════════════
Describe 'Get-UTCMMonitor' {

    It 'Calls Invoke-UTCMGraphRequest with the monitors endpoint' {
        Mock Invoke-UTCMGraphRequest -ModuleName UTCM -MockWith {
            @(@{ id = 'm1'; displayName = 'Monitor 1' })
        }
        $result = Get-UTCMMonitor
        $result | Should -HaveCount 1
        Should -Invoke Invoke-UTCMGraphRequest -ModuleName UTCM -Times 1 -ParameterFilter {
            $Uri -like '*/configurationMonitors'
        }
    }

    It 'Appends MonitorId to the URI and sets -Raw' {
        Mock Invoke-UTCMGraphRequest -ModuleName UTCM -MockWith {
            @{ id = 'specific'; displayName = 'One Monitor' }
        }
        $result = Get-UTCMMonitor -MonitorId 'specific'
        $result.id | Should -Be 'specific'
        Should -Invoke Invoke-UTCMGraphRequest -ModuleName UTCM -Times 1 -ParameterFilter {
            $Uri -like '*/configurationMonitors/specific' -and $Raw -eq $true
        }
    }
}

# ═══════════════════════════════════════════════════════════════════════════
# New-UTCMMonitor
# ═══════════════════════════════════════════════════════════════════════════
Describe 'New-UTCMMonitor' {

    BeforeAll {
        Mock Invoke-UTCMGraphRequest -ModuleName UTCM -MockWith {
            @{ id = 'new-mon'; displayName = 'Created' }
        }
    }

    It 'Sends a POST with displayName and baseline' {
        $baseline = @{ displayName = 'BL'; resources = @() }
        $result = New-UTCMMonitor -DisplayName 'TestMon' -Baseline $baseline -Confirm:$false
        $result.id | Should -Be 'new-mon'
        Should -Invoke Invoke-UTCMGraphRequest -ModuleName UTCM -Times 1 -ParameterFilter {
            $Method -eq 'POST' -and $Uri -like '*/configurationMonitors'
        }
    }

    It 'Supports -WhatIf without calling the API' {
        Mock Invoke-UTCMGraphRequest -ModuleName UTCM
        $baseline = @{ displayName = 'BL'; resources = @() }
        New-UTCMMonitor -DisplayName 'WhatIf' -Baseline $baseline -WhatIf
        Should -Invoke Invoke-UTCMGraphRequest -ModuleName UTCM -Times 0
    }
}

# ═══════════════════════════════════════════════════════════════════════════
# Set-UTCMMonitor
# ═══════════════════════════════════════════════════════════════════════════
Describe 'Set-UTCMMonitor' {

    It 'Sends a PATCH to the correct URI' {
        Mock Invoke-UTCMGraphRequest -ModuleName UTCM -MockWith {
            @{ id = 'mon-id'; displayName = 'Updated' }
        }
        $result = Set-UTCMMonitor -MonitorId 'mon-id' -DisplayName 'Updated' -Confirm:$false
        $result.displayName | Should -Be 'Updated'
        Should -Invoke Invoke-UTCMGraphRequest -ModuleName UTCM -Times 1 -ParameterFilter {
            $Method -eq 'PATCH' -and $Uri -like '*/configurationMonitors/mon-id'
        }
    }

    It 'Supports -WhatIf' {
        Mock Invoke-UTCMGraphRequest -ModuleName UTCM
        Set-UTCMMonitor -MonitorId 'x' -DisplayName 'Y' -WhatIf
        Should -Invoke Invoke-UTCMGraphRequest -ModuleName UTCM -Times 0
    }
}

# ═══════════════════════════════════════════════════════════════════════════
# Remove-UTCMMonitor
# ═══════════════════════════════════════════════════════════════════════════
Describe 'Remove-UTCMMonitor' {

    It 'Sends a DELETE to the correct URI' {
        Mock Invoke-UTCMGraphRequest -ModuleName UTCM -MockWith { $null }
        Remove-UTCMMonitor -MonitorId 'del-mon' -Confirm:$false
        Should -Invoke Invoke-UTCMGraphRequest -ModuleName UTCM -Times 1 -ParameterFilter {
            $Method -eq 'DELETE' -and $Uri -like '*/configurationMonitors/del-mon'
        }
    }

    It 'Supports -WhatIf' {
        Mock Invoke-UTCMGraphRequest -ModuleName UTCM
        Remove-UTCMMonitor -MonitorId 'x' -WhatIf
        Should -Invoke Invoke-UTCMGraphRequest -ModuleName UTCM -Times 0
    }
}

# ═══════════════════════════════════════════════════════════════════════════
# Get-UTCMBaseline
# ═══════════════════════════════════════════════════════════════════════════
Describe 'Get-UTCMBaseline' {

    It 'Calls the baseline endpoint with -Raw' {
        Mock Invoke-UTCMGraphRequest -ModuleName UTCM -MockWith {
            @{ displayName = 'Baseline'; resources = @() }
        }
        $result = Get-UTCMBaseline -MonitorId 'abc'
        $result.displayName | Should -Be 'Baseline'
        Should -Invoke Invoke-UTCMGraphRequest -ModuleName UTCM -Times 1 -ParameterFilter {
            $Uri -like '*/configurationMonitors/abc/baseline' -and $Raw -eq $true
        }
    }
}

# ═══════════════════════════════════════════════════════════════════════════
# Get-UTCMDrift
# ═══════════════════════════════════════════════════════════════════════════
Describe 'Get-UTCMDrift' {

    It 'Lists all drifts without filters' {
        Mock Invoke-UTCMGraphRequest -ModuleName UTCM -MockWith {
            @(@{ id = 'd1' }, @{ id = 'd2' })
        }
        $result = Get-UTCMDrift
        $result | Should -HaveCount 2
        Should -Invoke Invoke-UTCMGraphRequest -ModuleName UTCM -Times 1 -ParameterFilter {
            $Uri -like '*/configurationDrifts' -and $Uri -notlike '*$filter*'
        }
    }

    It 'Gets a specific drift by ID with -Raw' {
        Mock Invoke-UTCMGraphRequest -ModuleName UTCM -MockWith {
            @{ id = 'drift-1'; status = 'active' }
        }
        $result = Get-UTCMDrift -DriftId 'drift-1'
        $result.id | Should -Be 'drift-1'
        Should -Invoke Invoke-UTCMGraphRequest -ModuleName UTCM -Times 1 -ParameterFilter {
            $Uri -like '*/configurationDrifts/drift-1' -and $Raw -eq $true
        }
    }

    It 'Builds a $filter for MonitorId and Status' {
        Mock Invoke-UTCMGraphRequest -ModuleName UTCM -MockWith { @() }
        Get-UTCMDrift -MonitorId 'mon-123' -Status 'active'
        Should -Invoke Invoke-UTCMGraphRequest -ModuleName UTCM -Times 1 -ParameterFilter {
            $Uri -like "*`$filter=*monitorId*eq*'mon-123'*and*status*eq*'active'*"
        }
    }
}

# ═══════════════════════════════════════════════════════════════════════════
# Get-UTCMMonitoringResult
# ═══════════════════════════════════════════════════════════════════════════
Describe 'Get-UTCMMonitoringResult' {

    It 'Lists all results without filters' {
        Mock Invoke-UTCMGraphRequest -ModuleName UTCM -MockWith {
            @(@{ id = 'r1' })
        }
        $result = Get-UTCMMonitoringResult
        $result | Should -HaveCount 1
    }

    It 'Gets a specific result by ID with -Raw' {
        Mock Invoke-UTCMGraphRequest -ModuleName UTCM -MockWith {
            @{ id = 'result-1' }
        }
        $result = Get-UTCMMonitoringResult -ResultId 'result-1'
        $result.id | Should -Be 'result-1'
        Should -Invoke Invoke-UTCMGraphRequest -ModuleName UTCM -Times 1 -ParameterFilter {
            $Uri -like '*/configurationMonitoringResults/result-1' -and $Raw -eq $true
        }
    }

    It 'Filters by MonitorId' {
        Mock Invoke-UTCMGraphRequest -ModuleName UTCM -MockWith { @() }
        Get-UTCMMonitoringResult -MonitorId 'mon-x'
        Should -Invoke Invoke-UTCMGraphRequest -ModuleName UTCM -Times 1 -ParameterFilter {
            $Uri -like "*`$filter=*monitorId*eq*'mon-x'*"
        }
    }
}

# ═══════════════════════════════════════════════════════════════════════════
# Get-UTCMSnapshot
# ═══════════════════════════════════════════════════════════════════════════
Describe 'Get-UTCMSnapshot' {

    It 'Lists all snapshots' {
        Mock Invoke-UTCMGraphRequest -ModuleName UTCM -MockWith {
            @(@{ id = 's1' }, @{ id = 's2' })
        }
        $result = Get-UTCMSnapshot
        $result | Should -HaveCount 2
    }

    It 'Gets a specific snapshot by ID with -Raw' {
        Mock Invoke-UTCMGraphRequest -ModuleName UTCM -MockWith {
            @{ id = 'snap-1'; status = 'succeeded' }
        }
        $result = Get-UTCMSnapshot -SnapshotId 'snap-1'
        $result.id | Should -Be 'snap-1'
        Should -Invoke Invoke-UTCMGraphRequest -ModuleName UTCM -Times 1 -ParameterFilter {
            $Uri -like '*/configurationSnapshotJobs/snap-1' -and $Raw -eq $true
        }
    }
}

# ═══════════════════════════════════════════════════════════════════════════
# New-UTCMSnapshot
# ═══════════════════════════════════════════════════════════════════════════
Describe 'New-UTCMSnapshot' {

    It 'Sends a POST with displayName and resources' {
        Mock Invoke-UTCMGraphRequest -ModuleName UTCM -MockWith {
            @{ id = 'new-snap'; status = 'running' }
        }
        $result = New-UTCMSnapshot -DisplayName 'TestSnap1' -Resources @('microsoft.entra.group') -Confirm:$false
        $result.id | Should -Be 'new-snap'
        Should -Invoke Invoke-UTCMGraphRequest -ModuleName UTCM -Times 1 -ParameterFilter {
            $Method -eq 'POST' -and $Uri -like '*/configurationSnapshots/createSnapshot'
        }
    }

    It 'Rejects DisplayName shorter than 8 chars' {
        { New-UTCMSnapshot -DisplayName 'Short' -Resources @('x') -Confirm:$false } |
            Should -Throw
    }

    It 'Rejects DisplayName with special characters' {
        { New-UTCMSnapshot -DisplayName 'Invalid!@#' -Resources @('x') -Confirm:$false } |
            Should -Throw
    }

    It 'Supports -WhatIf' {
        Mock Invoke-UTCMGraphRequest -ModuleName UTCM
        New-UTCMSnapshot -DisplayName 'WhatIfSnap' -Resources @('microsoft.entra.group') -WhatIf
        Should -Invoke Invoke-UTCMGraphRequest -ModuleName UTCM -Times 0
    }
}

# ═══════════════════════════════════════════════════════════════════════════
# Remove-UTCMSnapshot
# ═══════════════════════════════════════════════════════════════════════════
Describe 'Remove-UTCMSnapshot' {

    It 'Sends a DELETE to the correct URI' {
        Mock Invoke-UTCMGraphRequest -ModuleName UTCM -MockWith { $null }
        Remove-UTCMSnapshot -SnapshotId 'del-snap' -Confirm:$false
        Should -Invoke Invoke-UTCMGraphRequest -ModuleName UTCM -Times 1 -ParameterFilter {
            $Method -eq 'DELETE' -and $Uri -like '*/configurationSnapshotJobs/del-snap'
        }
    }

    It 'Supports -WhatIf' {
        Mock Invoke-UTCMGraphRequest -ModuleName UTCM
        Remove-UTCMSnapshot -SnapshotId 'x' -WhatIf
        Should -Invoke Invoke-UTCMGraphRequest -ModuleName UTCM -Times 0
    }
}

# ═══════════════════════════════════════════════════════════════════════════
# Wait-UTCMSnapshot
# ═══════════════════════════════════════════════════════════════════════════
Describe 'Wait-UTCMSnapshot' {

    It 'Returns immediately when snapshot is already succeeded' {
        Mock Get-UTCMSnapshot -ModuleName UTCM -MockWith {
            @{ id = 'ws1'; status = 'succeeded' }
        }
        Mock Start-Sleep -ModuleName UTCM -MockWith { }

        $result = Wait-UTCMSnapshot -SnapshotId 'ws1'
        $result.status | Should -Be 'succeeded'
        Should -Invoke Start-Sleep -ModuleName UTCM -Times 0
    }

    It 'Polls until succeeded' {
        $script:pollCount = 0
        Mock Get-UTCMSnapshot -ModuleName UTCM -MockWith {
            $script:pollCount++
            if ($script:pollCount -lt 3) {
                @{ id = 'ws2'; status = 'running' }
            } else {
                @{ id = 'ws2'; status = 'succeeded' }
            }
        }
        Mock Start-Sleep -ModuleName UTCM -MockWith { }

        $result = Wait-UTCMSnapshot -SnapshotId 'ws2' -PollIntervalSeconds 1
        $result.status | Should -Be 'succeeded'
    }

    It 'Returns on partiallySuccessful status' {
        Mock Get-UTCMSnapshot -ModuleName UTCM -MockWith {
            @{ id = 'ws3'; status = 'partiallySuccessful' }
        }
        Mock Start-Sleep -ModuleName UTCM -MockWith { }

        $result = Wait-UTCMSnapshot -SnapshotId 'ws3'
        $result.status | Should -Be 'partiallySuccessful'
    }
}

# ═══════════════════════════════════════════════════════════════════════════
# Install-UTCMServicePrincipal
# ═══════════════════════════════════════════════════════════════════════════
Describe 'Install-UTCMServicePrincipal' {

    It 'Creates the SP when it does not exist' {
        Mock Invoke-UTCMGraphRequest -ModuleName UTCM -MockWith {
            # First call = filter query returns empty, second call = POST returns SP
            $null
        } -ParameterFilter { $Uri -like '*$filter*' }

        Mock Invoke-UTCMGraphRequest -ModuleName UTCM -MockWith {
            @{ id = 'new-sp-id'; appId = '03b07b79-c5bc-4b5e-9bfa-13acf4a99998' }
        } -ParameterFilter { $Method -eq 'POST' }

        $result = Install-UTCMServicePrincipal -Confirm:$false
        $result.id | Should -Be 'new-sp-id'
    }

    It 'Returns existing SP without creating' {
        Mock Invoke-UTCMGraphRequest -ModuleName UTCM -MockWith {
            @{ id = 'existing-sp'; appId = '03b07b79-c5bc-4b5e-9bfa-13acf4a99998' }
        } -ParameterFilter { $Uri -like '*$filter*' }

        $result = Install-UTCMServicePrincipal -Confirm:$false
        $result.id | Should -Be 'existing-sp'
    }
}

# ═══════════════════════════════════════════════════════════════════════════
# Grant-UTCMPermission
# ═══════════════════════════════════════════════════════════════════════════
Describe 'Grant-UTCMPermission' {

    BeforeAll {
        # Mock the Graph SP lookup with appRoles
        Mock Invoke-UTCMGraphRequest -ModuleName UTCM -MockWith {
            @{
                id       = 'graph-sp-id'
                appRoles = @(
                    @{ Id = 'role-1'; Value = 'User.ReadWrite.All' }
                    @{ Id = 'role-2'; Value = 'Policy.Read.All' }
                )
            }
        } -ParameterFilter { $Uri -like '*00000003-0000-0000*' }

        # Mock the UTCM SP lookup
        Mock Invoke-UTCMGraphRequest -ModuleName UTCM -MockWith {
            @{ id = 'utcm-sp-id' }
        } -ParameterFilter { $Uri -like '*03b07b79*' }

        # Mock existing assignments (empty)
        Mock Invoke-UTCMGraphRequest -ModuleName UTCM -MockWith {
            @()
        } -ParameterFilter { $Uri -like '*appRoleAssignments' -and $Method -ne 'POST' }

        # Mock the POST for assignment
        Mock Invoke-UTCMGraphRequest -ModuleName UTCM -MockWith {
            @{ id = 'assignment-1' }
        } -ParameterFilter { $Method -eq 'POST' }
    }

    It 'Grants a permission that is not yet assigned' {
        Grant-UTCMPermission -PermissionName 'User.ReadWrite.All' -Confirm:$false
        Should -Invoke Invoke-UTCMGraphRequest -ModuleName UTCM -ParameterFilter { $Method -eq 'POST' } -Times 1
    }
}

# ═══════════════════════════════════════════════════════════════════════════
# Grant-UTCMDirectoryRole
# ═══════════════════════════════════════════════════════════════════════════
Describe 'Grant-UTCMDirectoryRole' {

    BeforeAll {
        # Mock UTCM SP lookup
        Mock Invoke-UTCMGraphRequest -ModuleName UTCM -MockWith {
            @{ id = 'utcm-sp-id' }
        } -ParameterFilter { $Uri -like '*03b07b79*' }

        # Mock existing role assignments (empty)
        Mock Invoke-UTCMGraphRequest -ModuleName UTCM -MockWith {
            @()
        } -ParameterFilter { $Uri -like '*roleAssignments*' -and $Method -ne 'POST' -and $Uri -notlike '*roleDefinitions*' }

        # Mock role definition lookup
        Mock Invoke-UTCMGraphRequest -ModuleName UTCM -MockWith {
            @{ id = 'role-def-1'; displayName = 'Global Reader' }
        } -ParameterFilter { $Uri -like '*roleDefinitions*' }

        # Mock the POST for role assignment
        Mock Invoke-UTCMGraphRequest -ModuleName UTCM -MockWith {
            @{ id = 'role-assign-1' }
        } -ParameterFilter { $Method -eq 'POST' }
    }

    It 'Assigns a directory role that is not yet assigned' {
        Grant-UTCMDirectoryRole -RoleDisplayName 'Global Reader' -Confirm:$false
        Should -Invoke Invoke-UTCMGraphRequest -ModuleName UTCM -ParameterFilter { $Method -eq 'POST' } -Times 1
    }
}
