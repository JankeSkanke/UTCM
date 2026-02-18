@{
    RootModule        = 'UTCM.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = 'a3e7c1f0-5b2d-4e8a-9f1c-6d3b7a2e0f4c'
    Author            = 'Jan Ketil Skanke'
    CompanyName       = 'Jan Ketil Skanke'
    Copyright         = '(c) 2026 Jan Ketil Skanke. All rights reserved.'
    Description       = 'PowerShell module for the Microsoft Graph Unified Tenant Configuration Management (UTCM) beta APIs. Manage configuration snapshots, monitors, baselines, and drift detection using native REST calls with no SDK dependency.'
    PowerShellVersion = '7.0'

    FormatsToProcess  = @('UTCM.Format.ps1xml')

    FunctionsToExport = @(
        # Auth
        'Connect-UTCM'
        'Disconnect-UTCM'
        'Get-UTCMContext'
        # Monitors
        'Get-UTCMMonitor'
        'New-UTCMMonitor'
        'Set-UTCMMonitor'
        'Remove-UTCMMonitor'
        # Baselines
        'Get-UTCMBaseline'
        # Drifts
        'Get-UTCMDrift'
        # Monitoring Results
        'Get-UTCMMonitoringResult'
        # Snapshots
        'New-UTCMSnapshot'
        'Get-UTCMSnapshot'
        'Remove-UTCMSnapshot'
        'Save-UTCMSnapshot'
        'Wait-UTCMSnapshot'
        'Compare-UTCMSnapshot'
        # Setup helpers
        'Install-UTCMServicePrincipal'
        'Grant-UTCMPermission'
        'Grant-UTCMDirectoryRole'
    )

    CmdletsToExport   = @()
    VariablesToExport  = @()
    AliasesToExport    = @()

    PrivateData = @{
        PSData = @{
            Tags       = @('MicrosoftGraph', 'UTCM', 'ConfigurationManagement', 'Monitoring', 'Drift')
            ProjectUri = 'https://github.com/JankeSkanke/UTCM'
            LicenseUri = 'https://github.com/JankeSkanke/UTCM/blob/main/LICENSE'
        }
    }
}
