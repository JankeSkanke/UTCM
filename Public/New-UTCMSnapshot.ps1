function New-UTCMSnapshot {
    <#
    .SYNOPSIS
        Creates a new configuration snapshot job.

    .PARAMETER DisplayName
        Display name for the snapshot.

    .PARAMETER Description
        Optional description.

    .PARAMETER Resources
        Array of resource type names to include (e.g. "microsoft.exchange.sharedmailbox").

    .EXAMPLE
        New-UTCMSnapshot -DisplayName "Entra Snapshot" -Resources @(
            "microsoft.entra.conditionalAccessPolicy",
            "microsoft.entra.authorizationPolicy"
        )

    .NOTES
        DisplayName must be 8-32 characters, only letters, numbers, and spaces allowed.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [ValidateLength(8, 32)]
        [ValidatePattern('^[a-zA-Z0-9 ]+$', ErrorMessage = 'DisplayName can only contain letters, numbers, and spaces.')]
        [string]$DisplayName,

        [string]$Description,

        [Parameter(Mandatory)][string[]]$Resources
    )

    $body = @{ displayName = $DisplayName; resources = $Resources }
    if ($Description) { $body.description = $Description }

    $uri = "$script:GraphBaseUrl/admin/configurationManagement/configurationSnapshots/createSnapshot"

    if ($PSCmdlet.ShouldProcess($DisplayName, "Create UTCM Snapshot")) {
        Invoke-UTCMGraphRequest -Uri $uri -Method POST -Body $body -Raw
    }
}
