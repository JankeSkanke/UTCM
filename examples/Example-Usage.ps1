<#
.SYNOPSIS
    Example usage of the UTCM PowerShell module.

.DESCRIPTION
    Walk-through covering:
      1. Prerequisites (UTCM service principal setup)
      2. Authentication
      3. Creating a monitor with a baseline
      4. Listing monitors, drifts, and monitoring results
      5. Creating and downloading a snapshot
#>

# ── 0. Import the module ────────────────────────────────────────────────
Import-Module "$PSScriptRoot\..\UTCM.psd1" -Force

# ── 1. Connect ──────────────────────────────────────────────────────────
# Option A: Interactive browser sign-in with PKCE (uses the MS Graph PowerShell app — no custom app needed)
Connect-UTCM -TenantId "contoso.onmicrosoft.com"

# Option B: Interactive with a custom app registration
# Connect-UTCM -TenantId "contoso.onmicrosoft.com" -ClientId "<your-client-id>"

# Option C: Client credentials (application flow)
# Connect-UTCM -TenantId "contoso.onmicrosoft.com" `
#              -ClientId "<your-client-id>" `
#              -ClientSecret "<your-client-secret>"

# Option D: Bring your own token
# Connect-UTCM -AccessToken $myToken

# ── 2. One-time setup (run once per tenant) ─────────────────────────────
# Create the UTCM service principal in the tenant
Install-UTCMServicePrincipal

# Grant it the permissions it needs to read tenant config
Grant-UTCMPermission -PermissionName @(
    'User.ReadWrite.All',
    'Policy.Read.All'
)

# ── 3. Create a configuration monitor ──────────────────────────────────
$baseline = @{
    displayName = "Exchange Baseline"
    description = "Monitors key Exchange Online resources"
    resources   = @(
        @{
            displayName  = "Shared Mailbox - HR"
            resourceType = "microsoft.exchange.sharedmailbox"
            properties   = @{
                DisplayName        = "HR Mailbox"
                Alias              = "hrmailbox"
                Identity           = "HR Mailbox"
                Ensure             = "Present"
                PrimarySmtpAddress = "hr@contoso.onmicrosoft.com"
                EmailAddresses     = @("hr@contoso.onmicrosoft.com")
            }
        },
        @{
            displayName  = "Accepted Domain"
            resourceType = "microsoft.exchange.accepteddomain"
            properties   = @{
                Identity   = "contoso.onmicrosoft.com"
                DomainType = "InternalRelay"
                Ensure     = "Present"
            }
        },
        @{
            displayName  = "Mail Contact - Partner"
            resourceType = "microsoft.exchange.mailcontact"
            properties   = @{
                Name                 = "PartnerContact"
                DisplayName          = "Partner Contact"
                ExternalEmailAddress = "SMTP:partner@fabrikam.com"
                Alias                = "partnercontact"
                Ensure               = "Present"
            }
        }
    )
}

$monitor = New-UTCMMonitor -DisplayName "EXO Production Monitor" `
                           -Description "Monitors Exchange Online drift" `
                           -Baseline $baseline

Write-Host "Created monitor: $($monitor.id)"

# ── 4. List monitors ───────────────────────────────────────────────────
$monitors = Get-UTCMMonitor
$monitors | Format-Table id, displayName, status, monitorRunFrequencyInHours

# ── 5. Get baseline for a monitor ──────────────────────────────────────
$bl = Get-UTCMBaseline -MonitorId $monitor.id
$bl | ConvertTo-Json -Depth 10

# ── 6. View monitoring results ─────────────────────────────────────────
# (Results appear after the monitor has run — every 6 hours)
$results = Get-UTCMMonitoringResult -MonitorId $monitor.id
$results | Format-Table id, runStatus, driftsCount, runCompletionDateTime

# ── 7. List drifts ─────────────────────────────────────────────────────
$drifts = Get-UTCMDrift -Status active
$drifts | Format-Table id, resourceType, baselineResourceDisplayName, status

# Get drift details
if ($drifts.Count -gt 0) {
    $detail = Get-UTCMDrift -DriftId $drifts[0].id
    $detail.driftedProperties | Format-List
}

# ── 8. Configuration snapshot ──────────────────────────────────────────
$snapshotJob = New-UTCMSnapshot -DisplayName "Feb 2026 Snapshot" `
                                -Description "Monthly config extraction" `
                                -Resources @(
                                    "microsoft.exchange.sharedmailbox",
                                    "microsoft.exchange.transportrule"
                                )

Write-Host "Snapshot job created: $($snapshotJob.id) — status: $($snapshotJob.status)"

# Wait for the snapshot to complete
$completed = Wait-UTCMSnapshot -SnapshotId $snapshotJob.id -TimeoutSeconds 300

# Download the snapshot file
if ($completed.status -eq 'succeeded') {
    Save-UTCMSnapshot -SnapshotId $completed.id -OutputPath "$PSScriptRoot\snapshot_feb2026.json"
}

# ── 9. List & clean up snapshots ───────────────────────────────────────
Get-UTCMSnapshot | Format-Table id, displayName, status, createdDateTime

# Delete a snapshot job (max 12 visible at a time)
# Remove-UTCMSnapshot -SnapshotId "<snapshot-id>"

# ── 10. Update or remove a monitor ─────────────────────────────────────
# Set-UTCMMonitor -MonitorId $monitor.id -DisplayName "Updated Monitor Name"
# Remove-UTCMMonitor -MonitorId $monitor.id

# ── 11. Disconnect ─────────────────────────────────────────────────────
Disconnect-UTCM
