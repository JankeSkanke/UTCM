# UTCM Monitor Schema Reference

> **Source:** [https://json.schemastore.org/utcm-monitor.json](https://www.schemastore.org/utcm-monitor.json)  
> **Schema Version:** JSON Schema Draft-07  
> **Schema ID:** `https://json.schemastore.org/utcm-monitor.json`

## Overview

The **configurationMonitor** schema defines the structure for a UTCM configuration monitor object. A monitor ties together a display name, description, optional parameters, and a **baseline** containing resources to monitor across Microsoft 365 workloads.

---

## Top-Level Properties

| Property | Type | Description |
|---|---|---|
| `id` | `string` | Unique identifier for the monitor. |
| `displayName` | `string` | Human-readable name of the monitor. |
| `description` | `string` | Description of what the monitor tracks. |
| `parameters` | `object` | Open dictionary for custom key-value parameters (schema: `openComplexDictionaryType`). |
| `baseline` | `object` | The **configurationBaseline** containing the resources to be monitored. |

---

## Baseline Object (`configurationBaseline`)

The `baseline` property is an object with the following structure:

| Property | Type | Description |
|---|---|---|
| `id` | `string` | Unique identifier for the baseline. |
| `displayName` | `string` | Human-readable name of the baseline. |
| `description` | `string` | Description of the baseline. |
| `parameters` | `array` | Array of **baselineParameter** objects. |
| `resources` | `array` | Array of resource objects defining what to monitor. |

### Baseline Parameter (`baselineParameter`)

Each parameter in the `parameters` array has:

| Property | Type | Description |
|---|---|---|
| `displayName` | `string` | Name of the parameter. |
| `description` | `string` | Description of the parameter. |
| `parameterType` | `string` | Data type of the parameter. Valid values: `string`, `integer`, `boolean`, `unknownFutureValue`. |

### Baseline Resource

Each resource in the `resources` array has:

| Property | Type | Description |
|---|---|---|
| `displayName` | `string` | Friendly name of the resource. |
| `resourceType` | `string` | The type identifier (e.g., `microsoft.entra.conditionalaccesspolicy`). See [Supported Resource Types](#supported-resource-types). |
| `properties` | `object` | Resource-specific properties. The schema is dynamically resolved based on `resourceType` using conditional references (`allOf` / `if` / `then`). |

---

## Supported Resource Types

The schema defines **270** resource type definitions across 5 Microsoft 365 workloads.

### Microsoft Entra (40 resource types)

| Resource Type | Description |
|---|---|
| `microsoft.entra.administrativeunit` | Administrative units |
| `microsoft.entra.application` | Application registrations |
| `microsoft.entra.attributeset` | Custom security attribute sets |
| `microsoft.entra.authenticationcontextclassreference` | Authentication context class references |
| `microsoft.entra.authenticationmethodpolicy` | Authentication method policies |
| `microsoft.entra.authenticationmethodpolicyauthenticator` | Microsoft Authenticator policy |
| `microsoft.entra.authenticationmethodpolicyemail` | Email authentication method policy |
| `microsoft.entra.authenticationmethodpolicyfido2` | FIDO2 security key policy |
| `microsoft.entra.authenticationmethodpolicysms` | SMS authentication method policy |
| `microsoft.entra.authenticationmethodpolicysoftware` | Software OATH token policy |
| `microsoft.entra.authenticationmethodpolicytemporary` | Temporary Access Pass policy |
| `microsoft.entra.authenticationmethodpolicyvoice` | Voice call authentication policy |
| `microsoft.entra.authenticationmethodpolicyx509` | X.509 certificate authentication policy |
| `microsoft.entra.authenticationstrengthpolicy` | Authentication strength policies |
| `microsoft.entra.authorizationpolicy` | Authorization policies |
| `microsoft.entra.conditionalaccesspolicy` | Conditional Access policies |
| `microsoft.entra.crosstenantaccesspolicy` | Cross-tenant access policy |
| `microsoft.entra.crosstenantaccesspolicyconfigurationdefault` | Cross-tenant access defaults |
| `microsoft.entra.crosstenantaccesspolicyconfigurationpartner` | Cross-tenant partner configuration |
| `microsoft.entra.entitlementmanagementaccesspackage` | Entitlement management access packages |
| `microsoft.entra.entitlementmanagementaccesspackageassignmentpolicy` | Access package assignment policies |
| `microsoft.entra.entitlementmanagementaccesspackagecatalog` | Access package catalogs |
| `microsoft.entra.entitlementmanagementaccesspackagecatalogresource` | Access package catalog resources |
| `microsoft.entra.entitlementmanagementconnectedorganization` | Connected organizations |
| `microsoft.entra.externalidentitypolicy` | External identity policies |
| `microsoft.entra.group` | Security and Microsoft 365 groups |
| `microsoft.entra.grouplifecyclepolicy` | Group lifecycle (expiration) policies |
| `microsoft.entra.groupsnamingpolicy` | Groups naming policies |
| `microsoft.entra.groupssettings` | Groups settings |
| `microsoft.entra.namedlocationpolicy` | Named location policies |
| `microsoft.entra.roledefinition` | Role definitions |
| `microsoft.entra.roleeligibilityschedulerequest` | PIM role eligibility schedule requests |
| `microsoft.entra.rolesetting` | PIM role settings |
| `microsoft.entra.securitydefaults` | Security defaults |
| `microsoft.entra.serviceprincipal` | Service principals |
| `microsoft.entra.socialidentityprovider` | Social identity providers |
| `microsoft.entra.tenantdetails` | Tenant details |
| `microsoft.entra.tokenlifetimepolicy` | Token lifetime policies |
| `microsoft.entra.user` | User accounts |

### Microsoft Exchange Online (73 resource types)

| Resource Type | Description |
|---|---|
| `microsoft.exchange.accepteddomain` | Accepted email domains |
| `microsoft.exchange.activesyncdeviceaccessrule` | Active Sync device access rules |
| `microsoft.exchange.addressbookpolicy` | Address book policies |
| `microsoft.exchange.addresslist` | Address lists |
| `microsoft.exchange.antiphishpolicy` | Anti-phish policies |
| `microsoft.exchange.antiphishrule` | Anti-phish rules |
| `microsoft.exchange.applicationaccesspolicy` | Application access policies |
| `microsoft.exchange.atppolicyforo365` | ATP policies for Office 365 |
| `microsoft.exchange.authenticationpolicy` | Authentication policies |
| `microsoft.exchange.authenticationpolicyassignment` | Authentication policy assignments |
| `microsoft.exchange.availabilityaddressspace` | Availability address spaces |
| `microsoft.exchange.availabilityconfig` | Availability configuration |
| `microsoft.exchange.calendarprocessing` | Calendar processing settings |
| `microsoft.exchange.casmailboxplan` | CAS mailbox plans |
| `microsoft.exchange.casmailboxsettings` | CAS mailbox settings |
| `microsoft.exchange.clientaccessrule` | Client access rules |
| `microsoft.exchange.dataclassification` | Data classifications |
| `microsoft.exchange.dataencryptionpolicy` | Data encryption policies |
| `microsoft.exchange.distributiongroup` | Distribution groups |
| `microsoft.exchange.dkimsigningconfig` | DKIM signing configuration |
| `microsoft.exchange.emailaddresspolicy` | Email address policies |
| `microsoft.exchange.eopprotectionpolicyrule` | EOP protection policy rules |
| `microsoft.exchange.externalinoutlook` | External in Outlook settings |
| `microsoft.exchange.globaladdresslist` | Global address lists |
| `microsoft.exchange.groupsettings` | Group settings |
| `microsoft.exchange.hostedconnectionfilterpolicy` | Hosted connection filter policies |
| `microsoft.exchange.hostedcontentfilterpolicy` | Hosted content filter policies |
| `microsoft.exchange.hostedcontentfilterrule` | Hosted content filter rules |
| `microsoft.exchange.hostedoutboundspamfilterpolicy` | Hosted outbound spam filter policies |
| `microsoft.exchange.hostedoutboundspamfilterrule` | Hosted outbound spam filter rules |
| `microsoft.exchange.inboundconnector` | Inbound connectors |
| `microsoft.exchange.intraorganizationconnector` | Intra-organization connectors |
| `microsoft.exchange.irmconfiguration` | IRM configuration |
| `microsoft.exchange.journalrule` | Journal rules |
| `microsoft.exchange.mailboxautoreplyconfiguration` | Mailbox auto-reply configuration |
| `microsoft.exchange.mailboxcalendarfolder` | Mailbox calendar folders |
| `microsoft.exchange.mailboxpermission` | Mailbox permissions |
| `microsoft.exchange.mailboxplan` | Mailbox plans |
| `microsoft.exchange.mailboxsettings` | Mailbox settings |
| `microsoft.exchange.mailcontact` | Mail contacts |
| `microsoft.exchange.mailtips` | MailTips settings |
| `microsoft.exchange.malwarefilterpolicy` | Malware filter policies |
| `microsoft.exchange.malwarefilterrule` | Malware filter rules |
| `microsoft.exchange.managementrole` | Management roles |
| `microsoft.exchange.managementroleassignment` | Management role assignments |
| `microsoft.exchange.managementroleentry` | Management role entries |
| `microsoft.exchange.messageclassification` | Message classifications |
| `microsoft.exchange.mobiledevicemailboxpolicy` | Mobile device mailbox policies |
| `microsoft.exchange.offlineaddressbook` | Offline address books |
| `microsoft.exchange.omeconfiguration` | OME configuration |
| `microsoft.exchange.onpremisesorganization` | On-premises organizations |
| `microsoft.exchange.organizationconfig` | Organization configuration |
| `microsoft.exchange.organizationrelationship` | Organization relationships |
| `microsoft.exchange.outboundconnector` | Outbound connectors |
| `microsoft.exchange.owamailboxpolicy` | OWA mailbox policies |
| `microsoft.exchange.partnerapplication` | Partner applications |
| `microsoft.exchange.perimeterconfiguration` | Perimeter configuration |
| `microsoft.exchange.place` | Room and workspace places |
| `microsoft.exchange.policytipconfig` | Policy tip configurations |
| `microsoft.exchange.quarantinepolicy` | Quarantine policies |
| `microsoft.exchange.recipientpermission` | Recipient permissions |
| `microsoft.exchange.remotedomain` | Remote domains |
| `microsoft.exchange.reportsubmissionpolicy` | Report submission policies |
| `microsoft.exchange.reportsubmissionrule` | Report submission rules |
| `microsoft.exchange.resourceconfiguration` | Resource configuration |
| `microsoft.exchange.roleassignmentpolicy` | Role assignment policies |
| `microsoft.exchange.rolegroup` | Role groups |
| `microsoft.exchange.safeattachmentpolicy` | Safe Attachment policies |
| `microsoft.exchange.safeattachmentrule` | Safe Attachment rules |
| `microsoft.exchange.safelinkspolicy` | Safe Links policies |
| `microsoft.exchange.safelinksrule` | Safe Links rules |
| `microsoft.exchange.sharedmailbox` | Shared mailboxes |
| `microsoft.exchange.sharingpolicy` | Sharing policies |
| `microsoft.exchange.sweeprule` | Sweep rules |
| `microsoft.exchange.transportconfig` | Transport configuration |
| `microsoft.exchange.transportrule` | Transport rules |

### Microsoft Teams (60 resource types)

| Resource Type | Description |
|---|---|
| `microsoft.teams.apppermissionpolicy` | App permission policies |
| `microsoft.teams.appsetuppolicy` | App setup policies |
| `microsoft.teams.audioconferencingpolicy` | Audio conferencing policies |
| `microsoft.teams.callholdpolicy` | Call hold policies |
| `microsoft.teams.callingpolicy` | Calling policies |
| `microsoft.teams.callparkpolicy` | Call park policies |
| `microsoft.teams.callqueue` | Call queues |
| `microsoft.teams.channel` | Team channels |
| `microsoft.teams.channelspolicy` | Channels policies |
| `microsoft.teams.channeltab` | Channel tabs |
| `microsoft.teams.clientconfiguration` | Client configuration |
| `microsoft.teams.compliancerecordingpolicy` | Compliance recording policies |
| `microsoft.teams.cortanapolicy` | Cortana policies |
| `microsoft.teams.dialinconferencingtenantsettings` | Dial-in conferencing tenant settings |
| `microsoft.teams.emergencycallingpolicy` | Emergency calling policies |
| `microsoft.teams.emergencycallroutingpolicy` | Emergency call routing policies |
| `microsoft.teams.enhancedencryptionpolicy` | Enhanced encryption policies |
| `microsoft.teams.eventspolicy` | Events policies |
| `microsoft.teams.federationconfiguration` | Federation configuration |
| `microsoft.teams.feedbackpolicy` | Feedback policies |
| `microsoft.teams.filespolicy` | Files policies |
| `microsoft.teams.grouppolicyassignment` | Group policy assignments |
| `microsoft.teams.guestcallingconfiguration` | Guest calling configuration |
| `microsoft.teams.guestmeetingconfiguration` | Guest meeting configuration |
| `microsoft.teams.guestmessagingconfiguration` | Guest messaging configuration |
| `microsoft.teams.ipphonepolicy` | IP phone policies |
| `microsoft.teams.meetingbroadcastconfiguration` | Meeting broadcast configuration |
| `microsoft.teams.meetingbroadcastpolicy` | Meeting broadcast policies |
| `microsoft.teams.meetingconfiguration` | Meeting configuration |
| `microsoft.teams.meetingpolicy` | Meeting policies |
| `microsoft.teams.messagingpolicy` | Messaging policies |
| `microsoft.teams.mobilitypolicy` | Mobility policies |
| `microsoft.teams.networkroamingpolicy` | Network roaming policies |
| `microsoft.teams.onlinevoicemailpolicy` | Online voicemail policies |
| `microsoft.teams.onlinevoicemailusersettings` | Online voicemail user settings |
| `microsoft.teams.onlinevoiceuser` | Online voice users |
| `microsoft.teams.orgwideappsettings` | Org-wide app settings |
| `microsoft.teams.pstnusage` | PSTN usage records |
| `microsoft.teams.shiftspolicy` | Shifts policies |
| `microsoft.teams.team` | Teams |
| `microsoft.teams.templatespolicy` | Templates policies |
| `microsoft.teams.tenantdialplan` | Tenant dial plans |
| `microsoft.teams.tenantnetworkregion` | Tenant network regions |
| `microsoft.teams.tenantnetworksite` | Tenant network sites |
| `microsoft.teams.tenantnetworksubnet` | Tenant network subnets |
| `microsoft.teams.tenanttrustedipaddress` | Tenant trusted IP addresses |
| `microsoft.teams.translationrule` | Translation rules |
| `microsoft.teams.unassignednumbertreatment` | Unassigned number treatments |
| `microsoft.teams.updatemanagementpolicy` | Update management policies |
| `microsoft.teams.upgradeconfiguration` | Upgrade configuration |
| `microsoft.teams.upgradepolicy` | Upgrade policies |
| `microsoft.teams.user` | Teams users |
| `microsoft.teams.usercallingsettings` | User calling settings |
| `microsoft.teams.userpolicyassignment` | User policy assignments |
| `microsoft.teams.vdipolicy` | VDI policies |
| `microsoft.teams.voiceroute` | Voice routes |
| `microsoft.teams.voiceroutingpolicy` | Voice routing policies |
| `microsoft.teams.workloadpolicy` | Workload policies |

### Microsoft Intune (68 resource types)

| Resource Type | Description |
|---|---|
| `microsoft.intune.accountprotectionlocaladministratorpasswordsolutionpolicy` | Local admin password solution (LAPS) policies |
| `microsoft.intune.accountprotectionlocalusergroupmembershippolicy` | Local user group membership policies |
| `microsoft.intune.accountprotectionpolicy` | Account protection policies |
| `microsoft.intune.antiviruspolicywindows10settingcatalog` | Antivirus policies (Windows 10, Settings Catalog) |
| `microsoft.intune.appconfigurationpolicy` | App configuration policies |
| `microsoft.intune.applicationcontrolpolicywindows10` | Application control policies (Windows 10) |
| `microsoft.intune.appprotectionpolicyandroid` | App protection policies (Android) |
| `microsoft.intune.appprotectionpolicyios` | App protection policies (iOS) |
| `microsoft.intune.asrrulespolicywindows10` | ASR rules policies (Windows 10) |
| `microsoft.intune.attacksurfacereductionrulespolicywindows10configmanager` | ASR rules (Windows 10, ConfigManager) |
| `microsoft.intune.deviceandappmanagementassignmentfilter` | Assignment filters |
| `microsoft.intune.devicecategory` | Device categories |
| `microsoft.intune.devicecleanuprule` | Device cleanup rules |
| `microsoft.intune.devicecompliancepolicyandroid` | Device compliance (Android) |
| `microsoft.intune.devicecompliancepolicyandroiddeviceowner` | Device compliance (Android Device Owner) |
| `microsoft.intune.devicecompliancepolicyandroidworkprofile` | Device compliance (Android Work Profile) |
| `microsoft.intune.devicecompliancepolicyios` | Device compliance (iOS) |
| `microsoft.intune.devicecompliancepolicymacos` | Device compliance (macOS) |
| `microsoft.intune.devicecompliancepolicywindows10` | Device compliance (Windows 10) |
| `microsoft.intune.deviceconfigurationadministrativetemplatepolicywindows10` | Admin template policies (Windows 10) |
| `microsoft.intune.deviceconfigurationcustompolicywindows10` | Custom device config (Windows 10) |
| `microsoft.intune.deviceconfigurationdefenderforendpointonboardingpolicywindows10` | Defender for Endpoint onboarding (Windows 10) |
| `microsoft.intune.deviceconfigurationdeliveryoptimizationpolicywindows10` | Delivery optimization (Windows 10) |
| `microsoft.intune.deviceconfigurationdomainjoinpolicywindows10` | Domain join policies (Windows 10) |
| `microsoft.intune.deviceconfigurationemailprofilepolicywindows10` | Email profile (Windows 10) |
| `microsoft.intune.deviceconfigurationendpointprotectionpolicywindows10` | Endpoint protection (Windows 10) |
| `microsoft.intune.deviceconfigurationfirmwareinterfacepolicywindows10` | Firmware interface (Windows 10) |
| `microsoft.intune.deviceconfigurationhealthmonitoringconfigurationpolicywindows10` | Health monitoring (Windows 10) |
| `microsoft.intune.deviceconfigurationidentityprotectionpolicywindows10` | Identity protection (Windows 10) |
| `microsoft.intune.deviceconfigurationimportedpfxcertificatepolicywindows10` | Imported PFX certificates (Windows 10) |
| `microsoft.intune.deviceconfigurationkioskpolicywindows10` | Kiosk policies (Windows 10) |
| `microsoft.intune.deviceconfigurationnetworkboundarypolicywindows10` | Network boundary (Windows 10) |
| `microsoft.intune.deviceconfigurationpkcscertificatepolicywindows10` | PKCS certificate (Windows 10) |
| `microsoft.intune.deviceconfigurationpolicyandroiddeviceadministrator` | Device config (Android Device Admin) |
| `microsoft.intune.deviceconfigurationpolicyandroiddeviceowner` | Device config (Android Device Owner) |
| `microsoft.intune.deviceconfigurationpolicyandroidopensourceproject` | Device config (Android Open Source) |
| `microsoft.intune.deviceconfigurationpolicyandroidworkprofile` | Device config (Android Work Profile) |
| `microsoft.intune.deviceconfigurationpolicyios` | Device config (iOS) |
| `microsoft.intune.deviceconfigurationpolicymacos` | Device config (macOS) |
| `microsoft.intune.deviceconfigurationpolicywindows10` | Device config (Windows 10) |
| `microsoft.intune.deviceconfigurationscepcertificatepolicywindows10` | SCEP certificate (Windows 10) |
| `microsoft.intune.deviceconfigurationsecureassessmentpolicywindows10` | Secure assessment (Windows 10) |
| `microsoft.intune.deviceconfigurationsharedmultidevicepolicywindows10` | Shared multi-device (Windows 10) |
| `microsoft.intune.deviceconfigurationtrustedcertificatepolicywindows10` | Trusted certificates (Windows 10) |
| `microsoft.intune.deviceconfigurationvpnpolicywindows10` | VPN policies (Windows 10) |
| `microsoft.intune.deviceconfigurationwindowsteampolicywindows10` | Windows Teams policies (Windows 10) |
| `microsoft.intune.deviceconfigurationwirednetworkpolicywindows10` | Wired network (Windows 10) |
| `microsoft.intune.deviceenrollmentlimitrestriction` | Enrollment limit restrictions |
| `microsoft.intune.deviceenrollmentplatformrestriction` | Enrollment platform restrictions |
| `microsoft.intune.deviceenrollmentstatuspagewindows10` | Enrollment status page (Windows 10) |
| `microsoft.intune.endpointdetectionandresponsepolicywindows10` | EDR policies (Windows 10) |
| `microsoft.intune.exploitprotectionpolicywindows10settingcatalog` | Exploit protection (Windows 10, Settings Catalog) |
| `microsoft.intune.policysets` | Policy sets |
| `microsoft.intune.roleassignment` | Role assignments |
| `microsoft.intune.roledefinition` | Role definitions |
| `microsoft.intune.settingcatalogasrrulespolicywindows10` | Settings Catalog ASR rules (Windows 10) |
| `microsoft.intune.settingcatalogcustompolicywindows10` | Settings Catalog custom (Windows 10) |
| `microsoft.intune.wificonfigurationpolicyandroiddeviceadministrator` | Wi-Fi config (Android Device Admin) |
| `microsoft.intune.wificonfigurationpolicyandroidenterprisedeviceowner` | Wi-Fi config (Android Enterprise Device Owner) |
| `microsoft.intune.wificonfigurationpolicyandroidenterpriseworkprofile` | Wi-Fi config (Android Enterprise Work Profile) |
| `microsoft.intune.wificonfigurationpolicyandroidforwork` | Wi-Fi config (Android for Work) |
| `microsoft.intune.wificonfigurationpolicyandroidopensourceproject` | Wi-Fi config (Android Open Source) |
| `microsoft.intune.wificonfigurationpolicyios` | Wi-Fi config (iOS) |
| `microsoft.intune.wificonfigurationpolicymacos` | Wi-Fi config (macOS) |
| `microsoft.intune.wificonfigurationpolicywindows10` | Wi-Fi config (Windows 10) |
| `microsoft.intune.windowsautopilotdeploymentprofileazureadhybridjoined` | Autopilot (Hybrid Azure AD Joined) |
| `microsoft.intune.windowsautopilotdeploymentprofileazureadjoined` | Autopilot (Azure AD Joined) |
| `microsoft.intune.windowsinformationprotectionpolicywindows10mdmenrolled` | WIP (Windows 10 MDM enrolled) |
| `microsoft.intune.windowsupdateforbusinessfeatureupdateprofilewindows10` | WUfB feature update profiles (Windows 10) |
| `microsoft.intune.windowsupdateforbusinessringupdateprofilewindows10` | WUfB ring update profiles (Windows 10) |

### Microsoft Security & Compliance (29 resource types)

| Resource Type | Description |
|---|---|
| `microsoft.securityandcompliance.auditconfigurationpolicy` | Audit configuration policies |
| `microsoft.securityandcompliance.autosensitivitylabelpolicy` | Auto-sensitivity label policies |
| `microsoft.securityandcompliance.autosensitivitylabelrule` | Auto-sensitivity label rules |
| `microsoft.securityandcompliance.caseholdpolicy` | Case hold policies |
| `microsoft.securityandcompliance.caseholdrule` | Case hold rules |
| `microsoft.securityandcompliance.compliancecase` | Compliance cases |
| `microsoft.securityandcompliance.compliancesearch` | Compliance searches |
| `microsoft.securityandcompliance.compliancesearchaction` | Compliance search actions |
| `microsoft.securityandcompliance.compliancetag` | Compliance tags |
| `microsoft.securityandcompliance.deviceconditionalaccesspolicy` | Device conditional access policies |
| `microsoft.securityandcompliance.deviceconfigurationpolicy` | Device configuration policies |
| `microsoft.securityandcompliance.dlpcompliancepolicy` | DLP compliance policies |
| `microsoft.securityandcompliance.dlpcompliancerule` | DLP compliance rules |
| `microsoft.securityandcompliance.fileplanpropertyauthority` | File plan property – Authority |
| `microsoft.securityandcompliance.fileplanpropertycategory` | File plan property – Category |
| `microsoft.securityandcompliance.fileplanpropertycitation` | File plan property – Citation |
| `microsoft.securityandcompliance.fileplanpropertydepartment` | File plan property – Department |
| `microsoft.securityandcompliance.fileplanpropertyreferenceid` | File plan property – Reference ID |
| `microsoft.securityandcompliance.fileplanpropertysubcategory` | File plan property – Subcategory |
| `microsoft.securityandcompliance.labelpolicy` | Label policies |
| `microsoft.securityandcompliance.protectionalert` | Protection alerts |
| `microsoft.securityandcompliance.retentioncompliancepolicy` | Retention compliance policies |
| `microsoft.securityandcompliance.retentioncompliancerule` | Retention compliance rules |
| `microsoft.securityandcompliance.retentioneventtype` | Retention event types |
| `microsoft.securityandcompliance.securityfilter` | Security filters |
| `microsoft.securityandcompliance.sensitivitylabel` | Sensitivity labels |
| `microsoft.securityandcompliance.supervisoryreviewpolicy` | Supervisory review policies |
| `microsoft.securityandcompliance.supervisoryreviewrule` | Supervisory review rules |

---

## Schema Mechanics

### Conditional Resource Properties

The schema uses JSON Schema's `allOf` with `if`/`then` blocks to dynamically resolve resource-specific properties based on the `resourceType` value. When a resource's `resourceType` matches a known type, its `properties` object is validated against the corresponding definition in `$defs`.

For example, when `resourceType` is `microsoft.entra.conditionalaccesspolicy`, the `properties` object is validated against the `#/$defs/microsoft.entra.conditionalaccesspolicy` definition.

### Resource Definitions (`$defs`)

The schema contains **270 resource type definitions** in the `$defs` section. Each definition is a JSON Schema object describing the properties specific to that resource type, including:

- Property names and types
- Required fields
- Allowed values (via `pattern` or `enum`)
- Descriptions for each property
- Example values

### Common Patterns in Resource Definitions

- **`Ensure`** – Many resource types include an `Ensure` property with values `Present` or `Absent` to indicate whether the resource should exist.
- **`Identity` / `Name`** – Most resources have a primary identifier field, typically `Identity` or `Name`, which is usually required.
- **Case-insensitive matching** – Enum-like values use regex patterns (e.g., `^([Pp][Rr][Ee][Ss][Ee][Nn][Tt]|[Aa][Bb][Ss][Ee][Nn][Tt])$`) to allow case-insensitive input.

---

## Summary

| Workload | Resource Count |
|---|---|
| Microsoft Entra | 40 |
| Microsoft Exchange Online | 73 |
| Microsoft Teams | 60 |
| Microsoft Intune | 68 |
| Microsoft Security & Compliance | 29 |
| **Total** | **270** |
