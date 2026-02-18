function Grant-UTCMDirectoryRole {
    <#
    .SYNOPSIS
        Assigns a Microsoft Entra directory role to the UTCM service principal.

    .PARAMETER RoleDisplayName
        The display name of the directory role (e.g. "Global Reader", "Security Reader").

    .EXAMPLE
        Grant-UTCMDirectoryRole -RoleDisplayName "Global Reader"
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string[]]$RoleDisplayName
    )

    $utcmAppId = '03b07b79-c5bc-4b5e-9bfa-13acf4a99998'
    $utcmSp = (Invoke-UTCMGraphRequest -Uri "$script:GraphV1Url/servicePrincipals?`$filter=appId eq '$utcmAppId'") | Select-Object -First 1

    if (-not $utcmSp) {
        throw "Could not find UTCM service principal. Run Install-UTCMServicePrincipal first."
    }

    # Get current role assignments for UTCM SP
    $existingAssignments = Invoke-UTCMGraphRequest -Uri "$script:GraphV1Url/roleManagement/directory/roleAssignments?`$filter=principalId eq '$($utcmSp.id)'"
    $existingRoleDefIds = @($existingAssignments | ForEach-Object { $_.roleDefinitionId })

    foreach ($roleName in $RoleDisplayName) {
        # Resolve role template ID from display name
        $roleDefinitions = Invoke-UTCMGraphRequest -Uri "$script:GraphV1Url/roleManagement/directory/roleDefinitions?`$filter=displayName eq '$roleName'"
        $roleDef = $roleDefinitions | Select-Object -First 1

        if (-not $roleDef) {
            Write-Warning "Directory role '$roleName' not found. Skipping."
            continue
        }

        # Check if already assigned
        if ($roleDef.id -in $existingRoleDefIds) {
            Write-Host "  Already assigned: $roleName" -ForegroundColor DarkGray
            continue
        }

        $assignBody = @{
            principalId      = $utcmSp.id
            roleDefinitionId = $roleDef.id
            directoryScopeId = '/'
        }

        if ($PSCmdlet.ShouldProcess($roleName, 'Assign directory role to UTCM SP')) {
            Invoke-UTCMGraphRequest -Uri "$script:GraphV1Url/roleManagement/directory/roleAssignments" -Method POST -Body $assignBody -Raw | Out-Null
            Write-Host "  Assigned: $roleName" -ForegroundColor Green
        }
    }
}
