function Set-UTCMMonitor {
    <#
    .SYNOPSIS
        Updates an existing configuration monitor.

    .PARAMETER MonitorId
        GUID of the monitor to update.

    .PARAMETER DisplayName
        New display name.

    .PARAMETER Description
        New description.

    .PARAMETER Baseline
        Updated baseline hashtable.

    .NOTES
        Updating the baseline deletes all previously generated monitoring results and drifts for that monitor.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string]$MonitorId,
        [string]$DisplayName,
        [string]$Description,
        [hashtable]$Baseline
    )

    $body = @{}
    if ($DisplayName) { $body.displayName = $DisplayName }
    if ($Description) { $body.description = $Description }
    if ($Baseline)    { $body.baseline    = $Baseline }

    $uri = "$script:GraphBaseUrl/admin/configurationManagement/configurationMonitors/$MonitorId"

    if ($PSCmdlet.ShouldProcess($MonitorId, "Update UTCM Monitor")) {
        Invoke-UTCMGraphRequest -Uri $uri -Method PATCH -Body $body -Raw
    }
}
