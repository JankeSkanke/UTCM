function Save-UTCMSnapshot {
    <#
    .SYNOPSIS
        Downloads a completed snapshot and saves it locally.

    .DESCRIPTION
        Saves the snapshot in two formats:
        1. A single properly formatted JSON file containing all resources.
        2. Individual JSON files per resource type in a subfolder.

        Output structure:
          <OutputPath>/
            snapshot.json                          # Full snapshot (formatted)
            resources/
              microsoft.entra.conditionalAccessPolicy.json
              microsoft.entra.group.json
              ...

    .PARAMETER SnapshotId
        GUID of the snapshot job.

    .PARAMETER OutputPath
        Directory path where snapshot files will be saved. Created if it does not exist.

    .EXAMPLE
        Save-UTCMSnapshot -SnapshotId "b267fe29-..." -OutputPath .\snapshots\entra-2026-02-16
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$SnapshotId,
        [Parameter(Mandatory)][string]$OutputPath
    )

    $snapshot = Get-UTCMSnapshot -SnapshotId $SnapshotId
    if (-not $snapshot.resourceLocation) {
        throw "Snapshot $SnapshotId does not have a resourceLocation yet. Status: $($snapshot.status)"
    }

    # Ensure output directories exist
    if (-not (Test-Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    }
    $resourceDir = Join-Path $OutputPath 'resources'
    if (-not (Test-Path $resourceDir)) {
        New-Item -ItemType Directory -Path $resourceDir -Force | Out-Null
    }

    # Download snapshot data
    $headers = Get-UTCMAuthHeaders
    $data = Invoke-RestMethod -Uri $snapshot.resourceLocation -Headers $headers

    # 1. Save full snapshot as formatted JSON
    $fullPath = Join-Path $OutputPath 'snapshot.json'
    $data | ConvertTo-Json -Depth 100 | Set-Content -Path $fullPath -Encoding utf8
    $fullSize = [math]::Round((Get-Item $fullPath).Length / 1KB)
    Write-Host "[UTCM] Full snapshot saved to $fullPath ($fullSize KB)" -ForegroundColor Green

    # 2. Save individual files per resource type
    $resourceTypes = $data.resources | Group-Object resourceType
    foreach ($group in $resourceTypes) {
        $fileName = "$($group.Name).json"
        $filePath = Join-Path $resourceDir $fileName
        $group.Group | ConvertTo-Json -Depth 100 | Set-Content -Path $filePath -Encoding utf8
        Write-Host "  $($group.Name) ($($group.Count) items)" -ForegroundColor DarkGray
    }

    Write-Host "[UTCM] $($resourceTypes.Count) resource type files saved to $resourceDir" -ForegroundColor Green
}
