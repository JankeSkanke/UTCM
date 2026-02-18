function Write-UTCMContext {
    <#
    .SYNOPSIS
        Displays the current connection context to the console.
    #>
    [CmdletBinding()]
    param(
        [string]$AuthFlow = ''
    )

    $ctx = $script:Context
    Write-Host ""
    Write-Host "  [UTCM] Connected" -ForegroundColor Green
    Write-Host "  Account    : $($ctx.Account)" -ForegroundColor Cyan
    Write-Host "  TenantId   : $($ctx.TenantId)" -ForegroundColor Cyan
    Write-Host "  AuthMethod : $($ctx.AuthMethod)$(if ($AuthFlow) { " ($AuthFlow)" })" -ForegroundColor Cyan
    Write-Host "  Scopes     : $($ctx.Scopes -join ', ')" -ForegroundColor Cyan
    Write-Host "  Expires    : $($ctx.ExpiresOn.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Cyan
    Write-Host ""
}
