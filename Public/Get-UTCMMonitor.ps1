function Get-UTCMMonitor {
    <#
    .SYNOPSIS
        Lists all configuration monitors or gets a specific one by ID.

    .PARAMETER MonitorId
        Optional GUID of a specific monitor.

    .EXAMPLE
        Get-UTCMMonitor
        Get-UTCMMonitor -MonitorId "f1b46220-74af-4347-9ac7-89fe17d57bd7"
    #>
    [CmdletBinding()]
    param([string]$MonitorId)

    $uri = "$script:GraphBaseUrl/admin/configurationManagement/configurationMonitors"
    if ($MonitorId) { $uri += "/$MonitorId" }

    $result = Invoke-UTCMGraphRequest -Uri $uri -Raw:([bool]$MonitorId)
    
    # Add custom type name for formatting
    if ($result) {
        if ($MonitorId) {
            $result.PSObject.TypeNames.Insert(0, 'Microsoft.Graph.Beta.ConfigurationMonitor')
        } else {
            foreach ($monitor in $result) {
                $monitor.PSObject.TypeNames.Insert(0, 'Microsoft.Graph.Beta.ConfigurationMonitor')
            }
        }
    }
    
    return $result
}
