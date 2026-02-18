function Get-UTCMContext {
    <#
    .SYNOPSIS
        Returns the current UTCM connection context.

    .DESCRIPTION
        Shows the account, tenant, scopes, and expiry of the current session.
        Returns null if not connected.

    .EXAMPLE
        Get-UTCMContext
    #>
    [CmdletBinding()]
    param()
    if (-not $script:Context) {
        Write-Warning "Not connected. Run Connect-UTCM first."
        return
    }
    [PSCustomObject]$script:Context
}
