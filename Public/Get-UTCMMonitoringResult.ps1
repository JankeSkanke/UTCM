function Get-UTCMMonitoringResult {
    <#
    .SYNOPSIS
        Lists monitoring results, or gets a specific one by ID.

    .PARAMETER ResultId
        Optional GUID of a specific monitoring result.

    .PARAMETER MonitorId
        Optional filter by monitor ID.

    .EXAMPLE
        Get-UTCMMonitoringResult
        Get-UTCMMonitoringResult -MonitorId "abc..."
    #>
    [CmdletBinding()]
    param(
        [string]$ResultId,
        [string]$MonitorId
    )

    $uri = "$script:GraphBaseUrl/admin/configurationManagement/configurationMonitoringResults"
    if ($ResultId) {
        $uri += "/$ResultId"
        return Invoke-UTCMGraphRequest -Uri $uri -Raw
    }

    if ($MonitorId) {
        $uri += "?`$filter=monitorId eq '$MonitorId'"
    }

    Invoke-UTCMGraphRequest -Uri $uri
}
