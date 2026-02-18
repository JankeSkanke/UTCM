function Get-UTCMBaseline {
    <#
    .SYNOPSIS
        Gets the baseline attached to a specific monitor.

    .PARAMETER MonitorId
        GUID of the monitor whose baseline to retrieve.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$MonitorId)

    $uri = "$script:GraphBaseUrl/admin/configurationManagement/configurationMonitors/$MonitorId/baseline"
    Invoke-UTCMGraphRequest -Uri $uri -Raw
}
