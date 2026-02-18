#Requires -Version 7.0
<#
.SYNOPSIS
    Demonstrates the enhanced features of the UTCM module.

.DESCRIPTION
    This script showcases the new formatting, comparison improvements,
    and other enhanced features added to the UTCM module.

    Features demonstrated:
    - Custom table formatting for monitors, snapshots, and drifts
    - Improved snapshot comparison with property filtering
    - JSON normalization to reduce false positives
#>

# Import the module
Import-Module (Join-Path $PSScriptRoot '..' 'UTCM.psd1') -Force

Write-Host "`n═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  UTCM Enhanced Features Demo" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════`n" -ForegroundColor Cyan

# ──────────────────────────────────────────────────────────────────────────────
# 1. Custom Formatting Demo
# ──────────────────────────────────────────────────────────────────────────────
Write-Host "▶ Feature 1: Custom Table Formatting" -ForegroundColor Green
Write-Host "  Shows monitors, snapshots, and drifts with color-coded status" -ForegroundColor DarkGray
Write-Host ""

# Note: This requires authentication
# Uncomment and run if you want to see live data formatting:
<#
Connect-UTCM -TenantId "your-tenant.onmicrosoft.com"

Write-Host "Monitors (formatted with custom view):" -ForegroundColor Yellow
Get-UTCMMonitor

Write-Host "`nSnapshots (formatted with custom view):" -ForegroundColor Yellow
Get-UTCMSnapshot | Select-Object -First 5

Write-Host "`nDrifts (formatted with custom view):" -ForegroundColor Yellow
Get-UTCMDrift | Select-Object -First 5

Disconnect-UTCM
#>

Write-Host "  ✓ Custom formatting provides:" -ForegroundColor Green
Write-Host "    • Color-coded status indicators (green=success, yellow=warning, red=error)" -ForegroundColor DarkGray
Write-Host "    • Automatic date/time formatting" -ForegroundColor DarkGray
Write-Host "    • Duration calculations for long-running operations" -ForegroundColor DarkGray
Write-Host "    • Compact, easy-to-read tables" -ForegroundColor DarkGray
Write-Host ""

Start-Sleep -Seconds 2

# ──────────────────────────────────────────────────────────────────────────────
# 2. Comparison Improvements Demo
# ──────────────────────────────────────────────────────────────────────────────
Write-Host "▶ Feature 2: Enhanced Snapshot Comparison" -ForegroundColor Green
Write-Host "  Reduces false positives and ignores irrelevant properties" -ForegroundColor DarkGray
Write-Host ""

# Create sample snapshots for demonstration
$sampleDir = Join-Path $PSScriptRoot '..' 'snapshots' 'demo'
if (-not (Test-Path $sampleDir)) {
    New-Item -ItemType Directory -Path $sampleDir -Force | Out-Null
}

# Sample snapshot 1 (baseline)
$snapshot1 = @{
    resources = @(
        @{
            resourceType = 'microsoft.entra.group'
            displayName = 'Security Group A'
            properties = @{
                displayName = 'Security Group A'
                description = 'Production security group'
                createdDateTime = '2026-02-01T10:00:00Z'
                lastModifiedDateTime = '2026-02-01T10:00:00Z'
                memberCount = 15
            }
        },
        @{
            resourceType = 'microsoft.entra.group'
            displayName = 'Security Group B'
            properties = @{
                displayName = 'Security Group B'
                description = 'Development security group'
                createdDateTime = '2026-02-01T11:00:00Z'
                lastModifiedDateTime = '2026-02-01T11:00:00Z'
                memberCount = 8
            }
        }
    )
}

# Sample snapshot 2 (with changes - only timestamps and property order different)
$snapshot2 = @{
    resources = @(
        @{
            resourceType = 'microsoft.entra.group'
            displayName = 'Security Group A'
            properties = @{
                # Properties in different order + updated timestamp
                lastModifiedDateTime = '2026-02-15T14:30:00Z'
                memberCount = 15
                description = 'Production security group'
                displayName = 'Security Group A'
                createdDateTime = '2026-02-01T10:00:00Z'
            }
        },
        @{
            resourceType = 'microsoft.entra.group'
            displayName = 'Security Group B'
            properties = @{
                displayName = 'Security Group B'
                description = 'Development security group - Updated'  # Real change
                createdDateTime = '2026-02-01T11:00:00Z'
                lastModifiedDateTime = '2026-02-15T14:35:00Z'
                memberCount = 12  # Real change
            }
        }
    )
}

# Save snapshots
$ref = Join-Path $sampleDir 'baseline'
$dif = Join-Path $sampleDir 'current'
New-Item -ItemType Directory -Path $ref -Force | OutNull
New-Item -ItemType Directory -Path $dif -Force | Out-Null
$snapshot1 | ConvertTo-Json -Depth 10 | Set-Content (Join-Path $ref 'snapshot.json') -Encoding UTF8
$snapshot2 | ConvertTo-Json -Depth 10 | Set-Content (Join-Path $dif 'snapshot.json') -Encoding UTF8

Write-Host "  Without enhancements:" -ForegroundColor Yellow
$oldComparison = Compare-UTCMSnapshot -ReferencePath $ref -DifferencePath $dif -NormalizeJson:$false
Write-Host "    Modified resources: $($oldComparison.Summary.ModifiedCount)" -ForegroundColor DarkGray
Write-Host "    (Reports changes due to property order and timestamps)" -ForegroundColor DarkGray
Write-Host ""

Write-Host "  With JSON normalization (default):" -ForegroundColor Yellow
$normalizedComparison = Compare-UTCMSnapshot -ReferencePath $ref -DifferencePath $dif
Write-Host "    Modified resources: $($normalizedComparison.Summary.ModifiedCount)" -ForegroundColor DarkGray
Write-Host "    (Property order differences are ignored)" -ForegroundColor DarkGray
Write-Host ""

Write-Host "  With ignored timestamp properties:" -ForegroundColor Yellow
$filteredComparison = Compare-UTCMSnapshot -ReferencePath $ref -DifferencePath $dif `
    -IgnoreProperties @('createdDateTime', 'lastModifiedDateTime')
Write-Host "    Modified resources: $($filteredComparison.Summary.ModifiedCount)" -ForegroundColor DarkGray
Write-Host "    Total changes: $($filteredComparison.Summary.TotalChanges)" -ForegroundColor DarkGray
Write-Host "    (Timestamps are ignored - only real config changes detected)" -ForegroundColor DarkGray
Write-Host ""

if ($filteredComparison.ResourceChanges.Modified.Count -gt 0) {
    Write-Host "  Detected real changes:" -ForegroundColor Magenta
    foreach ($mod in $filteredComparison.ResourceChanges.Modified) {
        Write-Host "    • $($mod.DisplayName)" -ForegroundColor Cyan
        foreach ($change in $mod.Changes) {
            Write-Host "      - $($change.Property): $($change.ReferenceValue) → $($change.DifferenceValue)" -ForegroundColor DarkGray
        }
    }
}

Write-Host ""
Write-Host "  ✓ Comparison improvements provide:" -ForegroundColor Green
Write-Host "    • JSON normalization eliminates property order false positives" -ForegroundColor DarkGray
Write-Host "    • Ignore irrelevant properties (timestamps, auto-generated IDs)" -ForegroundColor DarkGray
Write-Host "    • Focus on real configuration changes" -ForegroundColor DarkGray
Write-Host "    • Reduced alert fatigue in drift monitoring" -ForegroundColor DarkGray
Write-Host ""

# Clean up demo files
Remove-Item -Path $sampleDir -Recurse -Force -ErrorAction SilentlyContinue

Start-Sleep -Seconds 2

# ──────────────────────────────────────────────────────────────────────────────
# 3. Formatted Comparison Output
# ──────────────────────────────────────────────────────────────────────────────
Write-Host "▶ Feature 3: Formatted Comparison Summary" -ForegroundColor Green
Write-Host "  Comparison results now display in a clean summary table" -ForegroundColor DarkGray
Write-Host ""

Write-Host "  Sample comparison output:" -ForegroundColor Yellow
$filteredComparison
Write-Host ""

Write-Host "  ✓ Formatted output provides:" -ForegroundColor Green
Write-Host "    • At-a-glance change summary with color coding" -ForegroundColor DarkGray
Write-Host "    • Easy pipeline integration" -ForegroundColor DarkGray
Write-Host "    • Professional reports for stakeholders" -ForegroundColor DarkGray
Write-Host ""

# ──────────────────────────────────────────────────────────────────────────────
# Summary
# ──────────────────────────────────────────────────────────────────────────────
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  🎉 Enhanced Features Summary" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Custom table formatting makes data easier to read" -ForegroundColor Green
Write-Host "2. Comparison improvements reduce false positives" -ForegroundColor Green
Write-Host "3. Formatted outputs are ready for reports and dashboards" -ForegroundColor Green
Write-Host ""
Write-Host "These enhancements improve the user experience and make" -ForegroundColor White
Write-Host "drift detection more accurate and actionable." -ForegroundColor White
Write-Host ""
