#Requires -Version 7.0
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0' }
<#
.SYNOPSIS
    Runs all UTCM Pester tests with full transcript and verbose logging.

.DESCRIPTION
    This script is designed to be run from an external PowerShell console (not VS Code terminal)
    to avoid transcript locking issues. It enables:
      - Transcript logging for each test file
      - Verbose output from module functions
      - Debug output from module functions
      - Detailed Pester output

.PARAMETER TestPath
    Path to specific test file or directory. Defaults to all tests.

.PARAMETER Verbose
    Enable verbose output from module functions.

.PARAMETER Debug
    Enable debug output from module functions.

.EXAMPLE
    .\Run-Tests.ps1
    Runs all tests with standard output.

.EXAMPLE
    .\Run-Tests.ps1 -Verbose
    Runs all tests with verbose output from module functions.

.EXAMPLE
    .\Run-Tests.ps1 -TestPath .\Private\Private.Tests.ps1 -Verbose -Debug
    Runs only Private tests with verbose and debug output.
#>
[CmdletBinding()]
param(
    [Parameter()]
    [string]$TestPath = $PSScriptRoot,

    [Parameter()]
    [switch]$DebugOutput
)

# Ensure the logs directory exists
$logsDir = Join-Path $PSScriptRoot 'logs'
if (-not (Test-Path $logsDir)) {
    New-Item -Path $logsDir -ItemType Directory -Force | Out-Null
}

# Create a session log file
$sessionLogPath = Join-Path $logsDir "TestSession_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
Start-Transcript -Path $sessionLogPath -Force

Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host "UTCM Test Runner" -ForegroundColor Cyan
Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host "Session Log: $sessionLogPath" -ForegroundColor Green
Write-Host "Test Path:   $TestPath" -ForegroundColor Green
Write-Host "Verbose:     $($PSBoundParameters.ContainsKey('Verbose'))" -ForegroundColor Green
Write-Host "Debug:       $DebugOutput" -ForegroundColor Green
Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host ""

try {
    # Configure Pester
    $pesterConfig = New-PesterConfiguration
    $pesterConfig.Run.Path = $TestPath
    $pesterConfig.Output.Verbosity = 'Detailed'
    $pesterConfig.CodeCoverage.Enabled = $false
    $pesterConfig.TestResult.Enabled = $true
    $pesterConfig.TestResult.OutputPath = Join-Path $logsDir "TestResults_$(Get-Date -Format 'yyyyMMdd_HHmmss').xml"
    $pesterConfig.TestResult.OutputFormat = 'NUnitXml'

    # Run Pester with appropriate verbose/debug preferences
    if ($PSBoundParameters.ContainsKey('Verbose')) {
        $VerbosePreference = 'Continue'
    }
    if ($DebugOutput) {
        $DebugPreference = 'Continue'
    }

    Write-Host "Running Pester tests..." -ForegroundColor Yellow
    Write-Host ""
    
    $result = Invoke-Pester -Configuration $pesterConfig

    Write-Host ""
    Write-Host "=====================================================================" -ForegroundColor Cyan
    Write-Host "Test Summary" -ForegroundColor Cyan
    Write-Host "=====================================================================" -ForegroundColor Cyan
    Write-Host "Total Tests:  $($result.TotalCount)" -ForegroundColor White
    Write-Host "Passed:       $($result.PassedCount)" -ForegroundColor Green
    Write-Host "Failed:       $($result.FailedCount)" -ForegroundColor $(if ($result.FailedCount -gt 0) { 'Red' } else { 'Green' })
    Write-Host "Skipped:      $($result.SkippedCount)" -ForegroundColor Yellow
    Write-Host "Duration:     $($result.Duration)" -ForegroundColor White
    Write-Host "=====================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Logs are available in: $logsDir" -ForegroundColor Green
    Write-Host ""

    if ($result.FailedCount -gt 0) {
        Write-Host "Failed tests:" -ForegroundColor Red
        foreach ($test in $result.Failed) {
            Write-Host "  - $($test.ExpandedPath)" -ForegroundColor Red
            if ($test.ErrorRecord) {
                Write-Host "    $($test.ErrorRecord.Exception.Message)" -ForegroundColor DarkRed
            }
        }
        Write-Host ""
    }
}
catch {
    Write-Host "ERROR: Test execution failed" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor DarkRed
}
finally {
    Stop-Transcript
    Write-Host "Session log saved to: $sessionLogPath" -ForegroundColor Green
}
