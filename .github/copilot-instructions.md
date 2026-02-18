# Copilot Instructions for UTCM

## Internal Documentation

- All internal development docs (status tracking, testing notes, tenant identifiers, dev context) **must** be placed in the `internaldocs/` folder.
- The `internaldocs/` folder is gitignored and must **never** be committed to the public repository.
- When creating or updating project status, testing status, or development notes, always use `internaldocs/` as the target directory.

## Sensitive Data

- **Never** include real tenant identifiers (tenant IDs, GUIDs, domain names) in files that will be committed.
- **Never** include personal information (names, email addresses, UPNs) in committed files.
- Snapshot data (`snapshots/`) and reports (`reports/`) are gitignored because they contain tenant-specific configuration data.
- Example scripts and documentation should use placeholder values like `contoso.onmicrosoft.com`, `00000000-0000-0000-0000-000000000000`, etc.

## Module Structure

- **Public/** — One exported function per `.ps1` file. All new public functions go here.
- **Private/** — Internal helper functions, not exported. One function per file.
- **UTCM.psm1** — Slim module loader. Dot-sources all files from `Private/` then `Public/`.
- **UTCM.psd1** — Module manifest. Update `FunctionsToExport` when adding new public functions.
- **UTCM.Format.ps1xml** — Custom formatting views. Ships with the module.

## Coding Conventions

- PowerShell 7.0+ required (`#Requires -Version 7.0`)
- Use `SupportsShouldProcess` on all write/delete operations
- Use `ConfirmImpact = 'High'` on destructive operations (Remove-*)
- All Graph API calls go through `Invoke-UTCMGraphRequest` (handles pagination, retries, errors)
- Auth state is stored in module-scoped `$script:` variables in `UTCM.psm1`
