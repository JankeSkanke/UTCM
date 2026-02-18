# UTCM API Reference — Research Notes

> Compiled from the Microsoft Graph Beta documentation (as of Feb 2026).
> Source: <https://learn.microsoft.com/en-us/graph/api/resources/unified-tenant-configuration-management-api-overview?view=graph-rest-beta>

---

## Overview

The **Unified Tenant Configuration Management (UTCM)** APIs (preview, `/beta`) let admins:

- **Monitor** configuration settings across workloads and detect **drifts** from a desired state.
- **Snapshot** the current tenant configuration for baselining or auditing.

Base path: `https://graph.microsoft.com/beta/admin/configurationManagement/`

---

## Prerequisites

1. **UTCM Service Principal** — Must be added to the tenant before monitors can run.
   - App ID: `03b07b79-c5bc-4b5e-9bfa-13acf4a99998`
   - Display Name: *Unified Tenant Configuration Management*
   - Create via:
     ```http
     POST https://graph.microsoft.com/v1.0/servicePrincipals
     { "appId": "03b07b79-c5bc-4b5e-9bfa-13acf4a99998" }
     ```
   - Or PowerShell:
     ```powershell
     New-MgServicePrincipal -AppId '03b07b79-c5bc-4b5e-9bfa-13acf4a99998'
     ```

2. **Grant permissions** to the UTCM SP for each workload it will read (e.g. `User.ReadWrite.All`, `Policy.Read.All`).

3. **Calling app permissions** — The app or user calling the Graph UTCM endpoints needs:

   | Scenario            | Delegated                                    | Application                                  |
   |---------------------|----------------------------------------------|----------------------------------------------|
   | Monitor management  | `ConfigurationMonitoring.Read.All` or `.ReadWrite.All` | `ConfigurationMonitoring.Read.All` or `.ReadWrite.All` |
   | Snapshots           | `ConfigurationMonitoring.ReadWrite.All`       | `ConfigurationMonitoring.ReadWrite.All`       |

   The delegated user must also hold a privileged Entra role.

Docs: <https://learn.microsoft.com/en-us/graph/utcm-authentication-setup>

---

## Resources & Endpoints

### 1. configurationMonitor

Represents a monitor that periodically checks tenant config against a baseline.

| Method  | HTTP                                                                  | Notes |
|---------|-----------------------------------------------------------------------|-------|
| List    | `GET  /admin/configurationManagement/configurationMonitors`           | Returns collection. |
| Get     | `GET  /admin/configurationManagement/configurationMonitors/{id}`      | Single monitor. |
| Create  | `POST /admin/configurationManagement/configurationMonitors`           | Body includes `baseline`. |
| Update  | `PATCH /admin/configurationManagement/configurationMonitors/{id}`     | **Warning**: updating baseline deletes all prior results & drifts. |
| Delete  | `DELETE /admin/configurationManagement/configurationMonitors/{id}`    | Permanent. |
| Get baseline | `GET /admin/configurationManagement/configurationMonitors/{id}/baseline` | Returns `configurationBaseline`. |

**Key properties:**

| Property                    | Type                        | Notes |
|-----------------------------|-----------------------------|-------|
| `id`                        | String (GUID)               | System-generated. |
| `displayName`               | String                      | Required on create. |
| `description`               | String                      | Optional. |
| `status`                    | `active` / `unknownFutureValue` | Default: `active`. |
| `mode`                      | `monitorOnly` / `unknownFutureValue` | Default: `monitorOnly`. |
| `monitorRunFrequencyInHours`| Int32                       | Fixed at **6 hours**. Runs at 6 AM, 12 PM, 6 PM, 12 AM GMT. |
| `tenantId`                  | String (GUID)               | Auto-populated. |
| `createdBy` / `lastModifiedBy` | identitySet              |  |
| `createdDateTime` / `lastModifiedDateTime` | DateTimeOffset |  |
| `parameters`                | openComplexDictionaryType   | Key-value pairs for baseline. |
| `baseline` *(relationship)* | `configurationBaseline`     | At least 1 resource + 1 property required. |

**JSON:**
```json
{
  "id": "f1b46220-...",
  "displayName": "Monitor for EXO100",
  "description": "...",
  "tenantId": "909d5e4a-...",
  "status": "active",
  "monitorRunFrequencyInHours": 6,
  "mode": "monitorOnly",
  "createdDateTime": "2025-03-24T09:00:44Z",
  "lastModifiedDateTime": "2025-03-24T09:00:44Z",
  "createdBy": { "user": { "id": "...", "displayName": "MOD Administrator" } },
  "parameters": {}
}
```

---

### 2. configurationBaseline

The desired-state definition attached to a monitor.

| Property      | Type                      | Notes |
|---------------|---------------------------|-------|
| `id`          | String (GUID)             |  |
| `displayName` | String                    |  |
| `description` | String                    |  |
| `resources`   | `baselineResource[]`      | Each has `displayName`, `resourceType`, `properties` (dict). |
| `parameters`  | `baselineParameter[]`     | Key-value parameters. |

**Create monitor request body example:**
```json
{
  "displayName": "Demo Monitor",
  "description": "This is a Demo Monitor",
  "baseline": {
    "displayName": "Demo Baseline",
    "description": "...",
    "resources": [
      {
        "displayName": "TestSharedMailbox Resource",
        "resourceType": "microsoft.exchange.sharedmailbox",
        "properties": {
          "DisplayName": "TestSharedMailbox",
          "Alias": "testSharedMailbox",
          "Identity": "TestSharedMailbox",
          "Ensure": "Present",
          "PrimarySmtpAddress": "testSharedMailbox@contoso.onmicrosoft.com",
          "EmailAddresses": ["abc@contoso.onmicrosoft.com"]
        }
      },
      {
        "displayName": "Accepted Domain",
        "resourceType": "microsoft.exchange.accepteddomain",
        "properties": {
          "Identity": "contoso.onmicrosoft.com",
          "DomainType": "InternalRelay",
          "Ensure": "Present"
        }
      },
      {
        "displayName": "Mail Contact Resource",
        "resourceType": "microsoft.exchange.mailcontact",
        "properties": {
          "Name": "Chris",
          "DisplayName": "Chris",
          "ExternalEmailAddress": "SMTP:chris@fabrikam.com",
          "Alias": "Chrisa",
          "Ensure": "Present"
        }
      }
    ]
  }
}
```

---

### 3. configurationDrift

Represents a deviation from the baseline detected by a monitor run.

| Method | HTTP                                                                  |
|--------|-----------------------------------------------------------------------|
| List   | `GET  /admin/configurationManagement/configurationDrifts`             |
| Get    | `GET  /admin/configurationManagement/configurationDrifts/{id}`        |

**Key properties:**

| Property                     | Type                        | Notes |
|------------------------------|-----------------------------|-------|
| `id`                         | String (GUID)               |  |
| `monitorId`                  | String (GUID)               |  |
| `resourceType`               | String                      | e.g. `microsoft.exchange.sharedmailbox` |
| `baselineResourceDisplayName`| String                      |  |
| `driftedProperties`          | `driftedProperty[]`         | Each has property name + expected vs. actual value. |
| `resourceInstanceIdentifier` | openComplexDictionaryType   | Locates exactly where the drift is. |
| `status`                     | `active` / `fixed` / `unknownFutureValue` |  |
| `firstReportedDateTime`      | DateTimeOffset              |  |
| `tenantId`                   | String (GUID)               |  |

**Retention:**
- Active drifts retained indefinitely.
- Fixed drifts deleted 30 days after resolution.

---

### 4. configurationMonitoringResult

Result of a single monitor run cycle.

| Method | HTTP                                                                            |
|--------|---------------------------------------------------------------------------------|
| List   | `GET  /admin/configurationManagement/configurationMonitoringResults`             |
| Get    | `GET  /admin/configurationManagement/configurationMonitoringResults/{id}`        |

**Key properties:**

| Property                 | Type                  | Notes |
|--------------------------|-----------------------|-------|
| `id`                     | String (GUID)         |  |
| `monitorId`              | String (GUID)         |  |
| `driftsCount`            | Int32                 |  |
| `runStatus`              | `successful` / `partiallySuccessful` / `failed` / `unknownFutureValue` |  |
| `runInitiationDateTime`  | DateTimeOffset        |  |
| `runCompletionDateTime`  | DateTimeOffset        |  |
| `errorDetails`           | `errorDetail[]`       | Reasons for failure. |
| `tenantId`               | String (GUID)         |  |

---

### 5. configurationSnapshotJob

An async job that extracts current tenant configuration for selected resources.

| Method   | HTTP                                                                        |
|----------|-----------------------------------------------------------------------------|
| Create   | `POST /admin/configurationManagement/configurationSnapshots/createSnapshot`     |
| List     | `GET  /admin/configurationManagement/configurationSnapshotJobs`                 |
| Get      | `GET  /admin/configurationManagement/configurationSnapshotJobs/{id}`            |
| Delete   | `DELETE /admin/configurationManagement/configurationSnapshotJobs/{id}`          |

**Create snapshot request body:**
```json
{
  "displayName": "Snapshot Demo",
  "description": "...",
  "resources": [
    "microsoft.exchange.sharedmailbox",
    "microsoft.exchange.transportrule"
  ]
}
```

**Key properties:**

| Property            | Type            | Notes |
|---------------------|-----------------|-------|
| `id`                | String (GUID)   |  |
| `displayName`       | String          | Required. |
| `description`       | String          | Optional. |
| `resources`         | String[]        | Resource type names in the request. |
| `status`            | `notStarted` / `running` / `succeeded` / `failed` / `partiallySuccessful` / `unknownFutureValue` |  |
| `resourceLocation`  | String (URL)    | Download URL once complete. |
| `createdDateTime`   | DateTimeOffset  |  |
| `completedDateTime` | DateTimeOffset  |  |
| `errorDetails`      | String[]        |  |
| `tenantId`          | String (GUID)   |  |
| `createdBy`         | identitySet     |  |

---

## API Limits

### Monitors
- Max **30** monitors per tenant.
- Fixed 6-hour run interval (4 cycles/day).
- Up to **800** configuration resources monitored per day per tenant (across all monitors).
- Updating a baseline **deletes all prior monitoring results and drifts** for that monitor.

### Drifts
- Active drifts kept indefinitely.
- Fixed drifts deleted **30 days** after resolution.

### Snapshots
- Max **20,000 resources** extracted per tenant per month (cumulative).
- No limit on number of snapshot jobs per day/month (within the 20k quota).
- Max **12 visible** snapshot jobs — must delete old ones to create more.
- Snapshots retained for **7 days**, then auto-deleted.

---

## Known Resource Types (from examples)

| Resource Type                            | Workload         |
|------------------------------------------|------------------|
| `microsoft.exchange.sharedmailbox`       | Exchange Online  |
| `microsoft.exchange.accepteddomain`      | Exchange Online  |
| `microsoft.exchange.mailcontact`         | Exchange Online  |
| `microsoft.exchange.transportrule`       | Exchange Online  |

> More resource types are listed in the "Supported workloads and resource types" doc
> (URL returned 404 at time of writing — may not be published yet).

---

## Authentication Flow Summary

```
┌─────────────────────────────────────────────────────────────┐
│  1. App/User authenticates to Graph                         │
│     ConfigurationMonitoring.ReadWrite.All permission        │
│     Privileged Entra role (delegated)                       │
├─────────────────────────────────────────────────────────────┤
│  2. UTCM Service Principal (03b07b79-...)                   │
│     Must exist in tenant                                    │
│     Granted workload permissions (User.RW.All, Policy.R.A)  │
│     Monitors impersonate this SP when running               │
├─────────────────────────────────────────────────────────────┤
│  3. Monitor runs every 6 hours                              │
│     Uses UTCM SP identity to call workload endpoints        │
│     Compares current state vs. baseline → produces drifts   │
└─────────────────────────────────────────────────────────────┘
```

---

## Cloud Availability

| Global | US Gov L4 | US Gov L5 (DOD) | China (21Vianet) |
|--------|-----------|------------------|-------------------|
| ✅      | ❌         | ❌                | ❌                 |

---

## Links

- [API overview](https://learn.microsoft.com/en-us/graph/api/resources/unified-tenant-configuration-management-api-overview?view=graph-rest-beta)
- [Concept overview](https://learn.microsoft.com/en-us/graph/unified-tenant-configuration-management-concept-overview)
- [Auth setup](https://learn.microsoft.com/en-us/graph/utcm-authentication-setup)
- [configurationMonitor](https://learn.microsoft.com/en-us/graph/api/resources/configurationmonitor?view=graph-rest-beta)
- [configurationBaseline](https://learn.microsoft.com/en-us/graph/api/resources/configurationbaseline?view=graph-rest-beta)
- [configurationDrift](https://learn.microsoft.com/en-us/graph/api/resources/configurationdrift?view=graph-rest-beta)
- [configurationMonitoringResult](https://learn.microsoft.com/en-us/graph/api/resources/configurationmonitoringresult?view=graph-rest-beta)
- [configurationSnapshotJob](https://learn.microsoft.com/en-us/graph/api/resources/configurationsnapshotjob?view=graph-rest-beta)
- [Create monitor](https://learn.microsoft.com/en-us/graph/api/configurationmanagement-post-configurationmonitors?view=graph-rest-beta)
- [Create snapshot](https://learn.microsoft.com/en-us/graph/api/configurationbaseline-createsnapshot?view=graph-rest-beta)
- [Graph Explorer](https://developer.microsoft.com/graph/graph-explorer)
