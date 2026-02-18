function Disconnect-UTCM {
    <#
    .SYNOPSIS
        Clears the stored UTCM access token and connection context.
    #>
    [CmdletBinding()]
    param()
    $script:Token         = $null
    $script:TokenExpiry   = [datetime]::MinValue
    $script:RefreshToken  = $null
    $script:TokenEndpoint = $null
    $script:ClientId      = $null
    $script:Context       = $null
    Write-Host "[UTCM] Disconnected." -ForegroundColor Yellow
}
