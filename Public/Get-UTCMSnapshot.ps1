function Get-UTCMSnapshot {
    <#
    .SYNOPSIS
        Lists all snapshot jobs, or gets a specific one by ID.

    .PARAMETER SnapshotId
        Optional GUID of a specific snapshot job.
    #>
    [CmdletBinding()]
    param([string]$SnapshotId)

    $uri = "$script:GraphBaseUrl/admin/configurationManagement/configurationSnapshotJobs"
    if ($SnapshotId) { $uri += "/$SnapshotId" }

    $result = Invoke-UTCMGraphRequest -Uri $uri -Raw:([bool]$SnapshotId)
    
    # Add custom type name for formatting
    if ($result) {
        if ($SnapshotId) {
            $result.PSObject.TypeNames.Insert(0, 'Microsoft.Graph.Beta.ConfigurationSnapshotJob')
        } else {
            foreach ($snapshot in $result) {
                $snapshot.PSObject.TypeNames.Insert(0, 'Microsoft.Graph.Beta.ConfigurationSnapshotJob')
            }
        }
    }
    
    return $result
}
