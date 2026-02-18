function Remove-UTCMMonitor {
    <#
    .SYNOPSIS
        Permanently deletes a configuration monitor.

    .PARAMETER MonitorId
        GUID of the monitor to delete.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param([Parameter(Mandatory)][string]$MonitorId)

    $uri = "$script:GraphBaseUrl/admin/configurationManagement/configurationMonitors/$MonitorId"

    if ($PSCmdlet.ShouldProcess($MonitorId, "Delete UTCM Monitor")) {
        Invoke-UTCMGraphRequest -Uri $uri -Method DELETE -Raw
        Write-Host "[UTCM] Monitor $MonitorId deleted." -ForegroundColor Yellow
    }
}
