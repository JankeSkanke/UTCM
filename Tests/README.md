# Running UTCM Tests

## Overview

The UTCM module has comprehensive Pester tests organized into:
- **Module Tests** - Manifest validation and module structure
- **Private Tests** - Unit tests for internal helper functions  
- **Public Tests** - Unit tests for exported cmdlets
- **Compare-UTCMSnapshot Tests** - Specialized tests for snapshot comparison

## Quick Start

### Running from External PowerShell (Recommended)

**DO NOT run from VS Code terminal** - transcript logging can cause VS Code to hang.

```powershell
# Open a standalone PowerShell 7+ console
pwsh

# Navigate to the Tests directory
cd D:\GitHub\JankeSkanke\UTCM\Tests

# Run all tests
.\Run-Tests.ps1

# Run with verbose output from module functions
.\Run-Tests.ps1 -Verbose

# Run with debug output
.\Run-Tests.ps1 -Verbose -Debug
```

### Running Specific Test Suites

```powershell
# Run only module tests
.\Run-Tests.ps1 -TestPath .\UTCM.Module.Tests.ps1

# Run only private function tests
.\Run-Tests.ps1 -TestPath .\Private\Private.Tests.ps1 -Verbose

# Run only public function tests  
.\Run-Tests.ps1 -TestPath .\Public\Public.Tests.ps1 -Verbose

# Run only snapshot comparison tests
.\Run-Tests.ps1 -TestPath .\Public\Compare-UTCMSnapshot.Tests.ps1 -Verbose
```

### Using Pester Directly

```powershell
# Run all tests
Invoke-Pester -Path . -Output Detailed

# Run specific test
Invoke-Pester -Path .\Private\Private.Tests.ps1 -Output Detailed
```

## Test Logging

All tests generate timestamped transcript logs in `Tests/logs/`:
- Each test file creates its own log: `<TestName>_yyyyMMdd_HHmmss.log`
- Session logs from Run-Tests.ps1: `TestSession_yyyyMMdd_HHmmss.log`
- NUnit XML results for CI/CD: `TestResults_yyyyMMdd_HHmmss.xml`

See [Tests/logs/README.md](logs/README.md) for details on log analysis.

## Test Requirements

- **PowerShell**: 7.0 or later
- **Pester**: 5.0 or later

Check Pester version:
```powershell
Get-Module Pester -ListAvailable | Select-Object Name, Version
```

Install/Update Pester if needed:
```powershell
Install-Module Pester -MinimumVersion 5.0 -Force -SkipPublisherCheck
```

## Troubleshooting

### VS Code Hangs
- **Solution**: Run tests from external PowerShell console, not VS Code terminal
- Transcript logging in VS Code can cause terminal locking

### Permission Errors
- Run PowerShell as Administrator
- Ensure logs directory is writable

### Module Not Found
- Ensure you're running from the Tests directory
- The test files automatically import the module from `../<UTCM.psd1`

### Failed Tests
- Check the timestamped log files in `Tests/logs/`
- Look for `[-]` markers indicating failed tests
- Review error messages and stack traces
- Run with `-Verbose -Debug` for more details

## Contributing

When adding new functions:
1. Add corresponding tests in the appropriate file
2. Follow existing test patterns (Describe/Context/It structure)
3. Use mocks for external dependencies (Invoke-RestMethod, etc.)
4. Run all tests before submitting changes
