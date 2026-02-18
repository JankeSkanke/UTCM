# UTCM MVP — Project Status & Context

> Last updated: February 17, 2026

## What This Is

A PowerShell module (`UTCM`) that wraps the **Microsoft Graph Beta UTCM APIs** (Unified Tenant Configuration Management) using native `Invoke-RestMethod` — no SDK dependencies. Built as an MVP to explore and work with the UTCM preview APIs.

## Working Directory

```
D:\GitHub\CloudWay\UTCM
```

## File Structure

```
UTCM/
├── UTCM.psd1                        # Module manifest (v0.1.0)
├── UTCM.psm1                        # Slim loader — module-scoped vars + dot-sources Public/ & Private/
├── Public/                           # 19 exported functions (one file per function)
│   ├── Compare-UTCMSnapshot.ps1
│   ├── Connect-UTCM.ps1
│   ├── Disconnect-UTCM.ps1
│   ├── Get-UTCMBaseline.ps1
│   ├── Get-UTCMContext.ps1
│   ├── Get-UTCMDrift.ps1
│   ├── Get-UTCMMonitor.ps1
│   ├── Get-UTCMMonitoringResult.ps1
│   ├── Get-UTCMSnapshot.ps1
│   ├── Grant-UTCMDirectoryRole.ps1
│   ├── Grant-UTCMPermission.ps1
│   ├── Install-UTCMServicePrincipal.ps1
│   ├── New-UTCMMonitor.ps1
│   ├── New-UTCMSnapshot.ps1
│   ├── Remove-UTCMMonitor.ps1
│   ├── Remove-UTCMSnapshot.ps1
│   ├── Save-UTCMSnapshot.ps1
│   ├── Set-UTCMMonitor.ps1
│   └── Wait-UTCMSnapshot.ps1
├── Private/                          # 6 internal helper functions
│   ├── Assert-UTCMConnected.ps1
│   ├── Get-UTCMAuthHeaders.ps1
│   ├── Get-UTCMTokenContext.ps1
│   ├── Invoke-UTCMGraphRequest.ps1
│   ├── Update-UTCMToken.ps1
│   └── Write-UTCMContext.ps1
├── Tests/                            # Pester test suite (111/111 passing)
├── docs/
│   └── UTCM-API-Reference.md        # Full API research notes
├── examples/
│   └── Enhanced-Features-Demo.ps1   # Custom formatting & comparison demo
├── snapshots/                        # Snapshot storage (local)
├── reports/                          # Generated comparison reports
└── UTCM.Format.ps1xml               # Custom table formatting (color-coded output)
```

## Exported Functions (19)

| Category       | Functions |
|----------------|-----------|
| **Auth**       | `Connect-UTCM` (Auth Code + PKCE with account picker, client-credentials, or bring-your-own-token), `Disconnect-UTCM`, `Get-UTCMContext` |
| **Monitors**   | `Get-UTCMMonitor`, `New-UTCMMonitor`, `Set-UTCMMonitor`, `Remove-UTCMMonitor` |
| **Baselines**  | `Get-UTCMBaseline` |
| **Drifts**     | `Get-UTCMDrift` (supports `-MonitorId`, `-Status` filters) |
| **Results**    | `Get-UTCMMonitoringResult` (supports `-MonitorId` filter) |
| **Snapshots**  | `New-UTCMSnapshot`, `Get-UTCMSnapshot`, `Remove-UTCMSnapshot`, `Save-UTCMSnapshot`, `Wait-UTCMSnapshot`, `Compare-UTCMSnapshot` |
| **Setup**      | `Install-UTCMServicePrincipal`, `Grant-UTCMPermission`, `Grant-UTCMDirectoryRole` |

## Internal (Private) Functions (6)

| Function | Purpose |
|----------|---------|
| `Assert-UTCMConnected` | Guard — throws if token is missing or expired; attempts silent refresh |
| `Get-UTCMAuthHeaders` | Returns `Authorization` + `Content-Type` + `ConsistencyLevel` headers |
| `Get-UTCMTokenContext` | Decodes JWT payload, extracts identity/scope claims |
| `Invoke-UTCMGraphRequest` | Core REST helper with automatic pagination, retry logic, and enhanced error handling |
| `Update-UTCMToken` | Silent token refresh using stored refresh token (delegated flows only) |
| `Write-UTCMContext` | Formats and displays connection info to console |

## What's Done

- [x] Module scaffolded with `.psm1` + `.psd1` (manifest validates clean)
- [x] **Refactored to Public/Private folder pattern** — one function per file, slim dot-sourcing loader
- [x] Auth: Auth Code + PKCE with browser account picker, client-credentials, and BYOT
- [x] Full CRUD for configuration monitors
- [x] Baseline retrieval per monitor
- [x] Drift listing with filtering
- [x] Monitoring result listing with filtering
- [x] Snapshot create / list / get / delete / download / poll-wait
- [x] **Snapshot comparison** (`Compare-UTCMSnapshot`) — two-phase analysis (coverage gaps + resource diffs), export to CSV / JSON / XML / HTML
- [x] Tenant setup helpers (create UTCM SP, grant Graph permissions, assign directory roles)
- [x] Pagination handling in the internal `Invoke-UTCMGraphRequest` helper
- [x] Example script covering full workflow
- [x] API reference doc with all endpoints, properties, limits, and auth flows
- [x] **Live tenant testing** — all 19 functions tested successfully against `demodummies.onmicrosoft.com`
- [x] Full Entra ID snapshots with all 27 resource types (1164 items)
- [x] Policy-only drift monitor created and running (196 resources, 6-hour cycle)
- [x] `partiallySuccessful` root cause identified — only `conditionalaccesspolicy` typ6 triggers it; all 44 CA policies captured correctly
- [x] **Comprehensive Pester tests** — 111 tests covering all 19 public functions and 5 private helpers
- [x] **All tests passing** (111/111) — Module, Private, Public, and Compare-UTCMSnapshot test suites
- [x] **Retry-after handling on 429 throttling** — Implemented with exponential backoff in `Invoke-UTCMGraphRequest`
- [x] **Automatic token refresh** — Silent refresh for interactive sessions using refresh tokens (delegated flows only)
- [x] **Enhanced error handling** — Detailed error messages with context and Graph API error code extraction
- [x] **Custom formatting (`.ps1xml`)** — Color-coded table views for monitors, snapshots, drifts, and comparison results
- [x] **Enhanced snapshot comparison** — JSON normalization and property filtering to reduce false positives
## What's NOT Done Yet

- [ ] Support for `-Select` / `-Top` / `-OrderBy` OData query parameters (in progress)
- [ ] CI/CD pipeline (GitHub Actions)
- [ ] PSGallery publishing prep (README, CHANGELOG, LICENSE)

## Known Issues

- **`Set-UTCMMonitor` PATCH fails** on monitors containing `entitlementManagementAccessPackageCatalogResource` — API returns a DateTime/String type mismatch on `AddedOn` field. This is a Microsoft API bug, not a module issue.
- **`conditionalaccesspolicy` snapshots** always return `partiallySuccessful` status even though all policies are captured correctly.

## Test Tenant & Identifiers

| Item | Value |
|------|-------|
| Tenant | `demodummies.onmicrosoft.com` |
| Tenant ID | `37b0413e-64f2-4b89-aae8-ffd9eb5c9d9e` |
| Default App ID | `14d82eec-204b-4c2f-b7e8-296a70dab67e` (MS Graph PowerShell) |
| UTCM SP App ID | `03b07b79-c5bc-4b5e-9bfa-13acf4a99998` |
| UTCM SP Object ID | `cda64097-93ec-46ee-9dd6-6cf7f04de3c9` |
| Active Monitor | `c1e4de5b-228b-499d-94ce-746e1405e6a6` (Entra Security Monitor) |

## Key API Details (Quick Reference)

- **Base path:** `https://graph.microsoft.com/beta/admin/configurationManagement/`
- **UTCM SP App ID:** `03b07b79-c5bc-4b5e-9bfa-13acf4a99998` (must exist in tenant)
- **Required permission:** `ConfigurationMonitoring.ReadWrite.All`
- **Endpoint asymmetry:** Create snapshot uses `configurationSnapshots/createSnapshot`; list/get/delete use `configurationSnapshotJobs`
- **Monitor interval:** Fixed 6 hours (6 AM, 12 PM, 6 PM, 12 AM GMT)
- **Limits:** 30 monitors, 800 resources/day, 20k snapshot resources/month, 12 visible snapshots
- **DisplayName validation:** 8–32 chars, `[a-zA-Z0-9 ]` only; Description max 128 chars
- **Global cloud only** (no GCC/DoD/China)
- Full details in `docs/UTCM-API-Reference.md`

## Tech Choices

- **PowerShell 7+** with raw `Invoke-RestMethod` (no MS Graph SDK dependency)
- **Public/Private folder pattern** — one function per `.ps1` file, dot-sourced by loader
- `SupportsShouldProcess` on all write operations
- `ConfirmImpact = 'High'` on deletes
- Module-scoped token storage (`$script:Token`, `$script:Context`, etc.) in `UTCM.psm1`
- Auth Code + PKCE with `System.Net.HttpListener` on random localhost port
