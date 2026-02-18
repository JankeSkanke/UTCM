function Wait-UTCMSnapshot {
    <#
    .SYNOPSIS
        Polls a snapshot job until it completes or times out.

    .PARAMETER SnapshotId
        GUID of the snapshot job.

    .PARAMETER TimeoutSeconds
        Maximum wait time (default 300).

    .PARAMETER PollIntervalSeconds
        Seconds between status checks (default 15).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$SnapshotId,
        [int]$TimeoutSeconds = 300,
        [int]$PollIntervalSeconds = 15
    )

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    while ((Get-Date) -lt $deadline) {
        $snap = Get-UTCMSnapshot -SnapshotId $SnapshotId
        Write-Host "  Snapshot status: $($snap.status)" -ForegroundColor DarkGray
        if ($snap.status -in @('succeeded','failed','partiallySuccessful')) {
            return $snap
        }
        Start-Sleep -Seconds $PollIntervalSeconds
    }
    Write-Warning "Timed out waiting for snapshot $SnapshotId."
    return Get-UTCMSnapshot -SnapshotId $SnapshotId
}
