function New-UTCMMonitor {
    <#
    .SYNOPSIS
        Creates a new configuration monitor with a baseline.

    .PARAMETER DisplayName
        Display name for the monitor.

    .PARAMETER Description
        Optional description.

    .PARAMETER Baseline
        Hashtable representing the configurationBaseline object.
        Must include displayName and a resources array (each entry needs
        displayName, resourceType, and a properties hashtable).

    .PARAMETER Parameters
        Optional key-value parameter pairs used in the baseline.

    .EXAMPLE
        $baseline = @{
            displayName = "EXO Baseline"
            description = "Exchange Online resources"
            resources = @(
                @{
                    displayName  = "Shared Mailbox"
                    resourceType = "microsoft.exchange.sharedmailbox"
                    properties   = @{
                        DisplayName      = "TestMailbox"
                        Alias            = "testmailbox"
                        Identity         = "TestMailbox"
                        Ensure           = "Present"
                        PrimarySmtpAddress = "test@contoso.onmicrosoft.com"
                    }
                }
            )
        }
        New-UTCMMonitor -DisplayName "EXO Monitor" -Baseline $baseline
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string]$DisplayName,
        [string]$Description,
        [Parameter(Mandatory)][hashtable]$Baseline,
        [hashtable]$Parameters
    )

    $body = @{ displayName = $DisplayName; baseline = $Baseline }
    if ($Description) { $body.description = $Description }
    if ($Parameters)  { $body.parameters  = $Parameters }

    $uri = "$script:GraphBaseUrl/admin/configurationManagement/configurationMonitors"

    if ($PSCmdlet.ShouldProcess($DisplayName, "Create UTCM Monitor")) {
        Invoke-UTCMGraphRequest -Uri $uri -Method POST -Body $body -Raw
    }
}
