function Remove-UTCMSnapshot {
    <#
    .SYNOPSIS
        Deletes a snapshot job.

    .PARAMETER SnapshotId
        GUID of the snapshot job to delete.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param([Parameter(Mandatory)][string]$SnapshotId)

    $uri = "$script:GraphBaseUrl/admin/configurationManagement/configurationSnapshotJobs/$SnapshotId"

    if ($PSCmdlet.ShouldProcess($SnapshotId, "Delete UTCM Snapshot")) {
        Invoke-UTCMGraphRequest -Uri $uri -Method DELETE -Raw
        Write-Host "[UTCM] Snapshot $SnapshotId deleted." -ForegroundColor Yellow
    }
}
