function Install-UTCMServicePrincipal {
    <#
    .SYNOPSIS
        Creates the UTCM service principal in the tenant (pre-requisite).

    .DESCRIPTION
        The UTCM service principal (AppId 03b07b79-c5bc-4b5e-9bfa-13acf4a99998)
        must exist in the tenant before monitors can run.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param()

    $uri  = "$script:GraphV1Url/servicePrincipals"
    $body = @{ appId = '03b07b79-c5bc-4b5e-9bfa-13acf4a99998' }

    if ($PSCmdlet.ShouldProcess('UTCM Service Principal', 'Create in tenant')) {
        # Check if already exists
        $existing = Invoke-UTCMGraphRequest -Uri "$script:GraphV1Url/servicePrincipals?`$filter=appId eq '03b07b79-c5bc-4b5e-9bfa-13acf4a99998'" | Select-Object -First 1
        if ($existing) {
            Write-Host "[UTCM] Service principal already exists. Object ID: $($existing.id)" -ForegroundColor DarkGray
            return $existing
        }
        $result = Invoke-UTCMGraphRequest -Uri $uri -Method POST -Body $body -Raw
        Write-Host "[UTCM] Service principal created. Object ID: $($result.id)" -ForegroundColor Green
        return $result
    }
}
