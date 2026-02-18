function Get-UTCMDrift {
    <#
    .SYNOPSIS
        Lists all configuration drifts, or retrieves a specific drift by ID.

    .PARAMETER DriftId
        Optional GUID of a specific drift.

    .PARAMETER MonitorId
        Optional filter by monitor ID.

    .PARAMETER Status
        Optional filter by status: active or fixed.

    .EXAMPLE
        Get-UTCMDrift
        Get-UTCMDrift -MonitorId "abc..." -Status active
    #>
    [CmdletBinding()]
    param(
        [string]$DriftId,
        [string]$MonitorId,
        [ValidateSet('active','fixed')][string]$Status
    )

    $uri = "$script:GraphBaseUrl/admin/configurationManagement/configurationDrifts"
    if ($DriftId) {
        $uri += "/$DriftId"
        $result = Invoke-UTCMGraphRequest -Uri $uri -Raw
        if ($result) {
            $result.PSObject.TypeNames.Insert(0, 'Microsoft.Graph.Beta.ConfigurationDrift')
        }
        return $result
    }

    $filters = @()
    if ($MonitorId) { $filters += "monitorId eq '$MonitorId'" }
    if ($Status)    { $filters += "status eq '$Status'" }
    if ($filters.Count -gt 0) {
        $uri += "?`$filter=" + ($filters -join ' and ')
    }

    $result = Invoke-UTCMGraphRequest -Uri $uri
    
    # Add custom type name for formatting
    if ($result) {
        foreach ($drift in $result) {
            $drift.PSObject.TypeNames.Insert(0, 'Microsoft.Graph.Beta.ConfigurationDrift')
        }
    }
    
    return $result
}
