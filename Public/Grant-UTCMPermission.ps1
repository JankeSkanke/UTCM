function Grant-UTCMPermission {
    <#
    .SYNOPSIS
        Grants application permissions to the UTCM service principal.

    .PARAMETER PermissionName
        One or more Graph application permission values
        (e.g. "User.ReadWrite.All", "Policy.Read.All").

    .EXAMPLE
        Grant-UTCMPermission -PermissionName "User.ReadWrite.All","Policy.Read.All"
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string[]]$PermissionName
    )

    $utcmAppId  = '03b07b79-c5bc-4b5e-9bfa-13acf4a99998'
    $graphAppId = '00000003-0000-0000-c000-000000000000'

    $graphSp = (Invoke-UTCMGraphRequest -Uri "$script:GraphV1Url/servicePrincipals?`$filter=appId eq '$graphAppId'") | Select-Object -First 1
    $utcmSp  = (Invoke-UTCMGraphRequest -Uri "$script:GraphV1Url/servicePrincipals?`$filter=appId eq '$utcmAppId'")  | Select-Object -First 1

    if (-not $graphSp -or -not $utcmSp) {
        throw "Could not find Graph or UTCM service principal. Run Install-UTCMServicePrincipal first."
    }

    # Get existing role assignments to avoid re-granting
    $existingAssignments = Invoke-UTCMGraphRequest -Uri "$script:GraphV1Url/servicePrincipals/$($utcmSp.id)/appRoleAssignments"
    $existingRoleIds = @($existingAssignments | ForEach-Object { $_.appRoleId })

    foreach ($perm in $PermissionName) {
        $appRole = $graphSp.appRoles | Where-Object { $_.Value -eq $perm }
        if (-not $appRole) {
            Write-Warning "Permission '$perm' not found in Graph app roles. Skipping."
            continue
        }

        # Skip if already assigned
        if ($appRole.Id -in $existingRoleIds) {
            Write-Host "  Already assigned: $perm" -ForegroundColor DarkGray
            continue
        }

        $assignBody = @{
            appRoleId   = $appRole.Id
            resourceId  = $graphSp.id
            principalId = $utcmSp.id
        }
        $uri = "$script:GraphV1Url/servicePrincipals/$($utcmSp.id)/appRoleAssignments"

        if ($PSCmdlet.ShouldProcess($perm, 'Grant to UTCM SP')) {
            Invoke-UTCMGraphRequest -Uri $uri -Method POST -Body $assignBody -Raw | Out-Null
            Write-Host "  Granted: $perm" -ForegroundColor Green
        }
    }
}
