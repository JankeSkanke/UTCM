function Compare-UTCMSnapshot {
    <#
    .SYNOPSIS
        Compares two saved snapshots and reports resource-level differences.

    .DESCRIPTION
        Loads two snapshot.json files (or directories containing snapshot.json) and
        performs a two-phase comparison:

        Phase 1 — Resource-type coverage:
          Identifies resource types present in one snapshot but missing from the other.
          These are flagged separately because a missing type typically indicates a
          collection gap (permissions, partial failure) rather than a real configuration
          change.

        Phase 2 — Resource-by-resource comparison (within shared types):
          For resource types collected by BOTH snapshots, individual resources are
          matched by resourceType + displayName and compared property-by-property.
          Reports:
          - Added   : resource exists in Difference snapshot only
          - Removed : resource exists in Reference snapshot only
          - Modified: same resource with different property values

    .PARAMETER ReferencePath
        Path to the reference (baseline/older) snapshot directory or snapshot.json file.

    .PARAMETER DifferencePath
        Path to the difference (newer) snapshot directory or snapshot.json file.

    .PARAMETER ResourceType
        Optional filter to compare only specific resource types.

    .PARAMETER ExcludeResourceType
        Optional resource types to exclude from comparison.

    .PARAMETER IncludeMissingTypes
        When set, resources from types that only exist in one snapshot are included
        in the Added/Removed lists instead of being reported separately.

    .PARAMETER IgnoreProperties
        Array of property names to exclude from comparison. Useful for ignoring
        timestamps or auto-generated fields that change frequently.

    .PARAMETER NormalizeJson
        When set, normalizes JSON property ordering before comparison to reduce
        false positives from property order differences. Enabled by default.

    .EXAMPLE
        Compare-UTCMSnapshot -ReferencePath ".\snapshots\entra-2026-02-15" `
                             -DifferencePath ".\snapshots\entra-2026-02-16"

    .EXAMPLE
        Compare-UTCMSnapshot -ReferencePath ".\snapshots\entra-2026-02-15" `
                             -DifferencePath ".\snapshots\entra-2026-02-16" `
                             -ExcludeResourceType "microsoft.entra.user","microsoft.entra.group"

    .PARAMETER OutputFormat
        Export results to a file in the specified format: CSV, JSON, XML, or HTML.
        Requires -OutputPath.

    .PARAMETER OutputPath
        File path for the exported report. The appropriate extension is appended
        automatically if not already present.

    .EXAMPLE
        # Treat missing types as real adds/removes rather than collection gaps
        Compare-UTCMSnapshot -ReferencePath ".\snapshots\old" `
                             -DifferencePath ".\snapshots\new" -IncludeMissingTypes

    .EXAMPLE
        # Export comparison as an HTML report
        Compare-UTCMSnapshot -ReferencePath ".\snapshots\entra-2026-02-15" `
                             -DifferencePath ".\snapshots\entra-2026-02-16" `
                             -OutputFormat HTML -OutputPath ".\reports\drift-report.html"

    .EXAMPLE
        # Export as CSV for spreadsheet analysis
        Compare-UTCMSnapshot -ReferencePath ".\snapshots\old" `
                             -DifferencePath ".\snapshots\new" `
                             -OutputFormat CSV -OutputPath ".\reports\changes.csv"

    .EXAMPLE
        # Ignore timestamp properties to reduce false positives
        Compare-UTCMSnapshot -ReferencePath ".\snapshots\old" `
                             -DifferencePath ".\snapshots\new" `
                             -IgnoreProperties @('lastModifiedDateTime', 'createdDateTime', 'lastActionDateTime')
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ReferencePath,
        [Parameter(Mandatory)][string]$DifferencePath,
        [string[]]$ResourceType,
        [string[]]$ExcludeResourceType,
        [switch]$IncludeMissingTypes,
        [string[]]$IgnoreProperties = @(),
        [switch]$NormalizeJson = $true,
        [ValidateSet('CSV','JSON','XML','HTML')][string]$OutputFormat,
        [string]$OutputPath
    )

    if ($OutputFormat -and -not $OutputPath) {
        throw "-OutputPath is required when -OutputFormat is specified."
    }
    if ($OutputPath -and -not $OutputFormat) {
        # Infer format from extension
        $ext = [System.IO.Path]::GetExtension($OutputPath).TrimStart('.').ToUpper()
        if ($ext -in @('CSV','JSON','XML','HTML','HTM')) {
            $OutputFormat = if ($ext -eq 'HTM') { 'HTML' } else { $ext }
        }
        else {
            throw "Cannot infer format from extension '$ext'. Use -OutputFormat to specify CSV, JSON, XML, or HTML."
        }
    }

    # ── Load snapshots ───────────────────────────────────────────────
    function Load-SnapshotResources([string]$Path) {
        if (Test-Path (Join-Path $Path 'snapshot.json')) {
            $Path = Join-Path $Path 'snapshot.json'
        }
        if (-not (Test-Path $Path)) {
            throw "Snapshot not found at: $Path"
        }
        $snap = Get-Content $Path -Raw | ConvertFrom-Json
        return @($snap.resources)
    }

    $refResources = Load-SnapshotResources $ReferencePath
    $newResources = Load-SnapshotResources $DifferencePath

    # Apply explicit filters
    if ($ResourceType) {
        $refResources = @($refResources | Where-Object { $_.resourceType -in $ResourceType })
        $newResources = @($newResources | Where-Object { $_.resourceType -in $ResourceType })
    }
    if ($ExcludeResourceType) {
        $refResources = @($refResources | Where-Object { $_.resourceType -notin $ExcludeResourceType })
        $newResources = @($newResources | Where-Object { $_.resourceType -notin $ExcludeResourceType })
    }

    # ── Phase 1: Resource-type coverage ──────────────────────────────
    $refTypes = @($refResources | ForEach-Object { $_.resourceType } | Select-Object -Unique)
    $newTypes = @($newResources | ForEach-Object { $_.resourceType } | Select-Object -Unique)

    $typesOnlyInRef = @($refTypes | Where-Object { $_ -notin $newTypes })
    $typesOnlyInNew = @($newTypes | Where-Object { $_ -notin $refTypes })
    $sharedTypes    = @($refTypes | Where-Object { $_ -in $newTypes })

    # Build per-type resource counts for the coverage report
    $missingFromNew = foreach ($t in $typesOnlyInRef) {
        $count = @($refResources | Where-Object { $_.resourceType -eq $t }).Count
        [PSCustomObject]@{ ResourceType = $t; ResourceCount = $count; Side = 'Reference only' }
    }
    $missingFromRef = foreach ($t in $typesOnlyInNew) {
        $count = @($newResources | Where-Object { $_.resourceType -eq $t }).Count
        [PSCustomObject]@{ ResourceType = $t; ResourceCount = $count; Side = 'Difference only' }
    }

    # ── Phase 2: Resource-by-resource comparison (shared types) ──────
    # Scope to shared types, unless -IncludeMissingTypes is set
    if ($IncludeMissingTypes) {
        $refCompare = $refResources
        $newCompare = $newResources
    }
    else {
        $refCompare = @($refResources | Where-Object { $_.resourceType -in $sharedTypes })
        $newCompare = @($newResources | Where-Object { $_.resourceType -in $sharedTypes })
    }

    # Helper: Remove ignored properties from an object
    function Remove-IgnoredProperties($obj, $propertiesToIgnore) {
        if (-not $obj -or $propertiesToIgnore.Count -eq 0) { return $obj }
        
        $filtered = [PSCustomObject]@{}
        foreach ($prop in $obj.PSObject.Properties) {
            if ($prop.Name -notin $propertiesToIgnore) {
                $filtered | Add-Member -NotePropertyName $prop.Name -NotePropertyValue $prop.Value
            }
        }
        return $filtered
    }

    # Helper: Normalize JSON by sorting properties recursively
    function ConvertTo-NormalizedJson($obj, $depth = 10) {
        if ($depth -le 0 -or $null -eq $obj) { return $null }
        
        if ($obj -is [System.Collections.IEnumerable] -and $obj -isnot [string]) {
            # Handle arrays
            $normalized = @()
            foreach ($item in $obj) {
                $normalized += ConvertTo-NormalizedJson $item ($depth - 1)
            }
            return $normalized
        }
        elseif ($obj.PSObject.Properties.Count -gt 0) {
            # Handle objects - sort properties by name
            $sortedObj = [ordered]@{}
            $obj.PSObject.Properties | Sort-Object Name | ForEach-Object {
                $sortedObj[$_.Name] = ConvertTo-NormalizedJson $_.Value ($depth - 1)
            }
            return $sortedObj
        }
        else {
            # Primitive value
            return $obj
        }
    }

    function Get-ResourceKey($resource) {
        return "$($resource.resourceType)|$($resource.displayName)"
    }

    $refMap = @{}
    foreach ($r in $refCompare) { $refMap[(Get-ResourceKey $r)] = $r }

    $newMap = @{}
    foreach ($r in $newCompare) { $newMap[(Get-ResourceKey $r)] = $r }

    $results = @{
        Added    = [System.Collections.Generic.List[object]]::new()
        Removed  = [System.Collections.Generic.List[object]]::new()
        Modified = [System.Collections.Generic.List[object]]::new()
    }

    # Added resources (in Difference, not in Reference)
    foreach ($key in $newMap.Keys) {
        if (-not $refMap.ContainsKey($key)) {
            $results.Added.Add([PSCustomObject]@{
                ChangeType   = 'Added'
                ResourceType = $newMap[$key].resourceType
                DisplayName  = $newMap[$key].displayName
            })
        }
    }

    # Removed resources (in Reference, not in Difference)
    foreach ($key in $refMap.Keys) {
        if (-not $newMap.ContainsKey($key)) {
            $results.Removed.Add([PSCustomObject]@{
                ChangeType   = 'Removed'
                ResourceType = $refMap[$key].resourceType
                DisplayName  = $refMap[$key].displayName
            })
        }
    }

    # Modified resources (same key, different properties)
    foreach ($key in $refMap.Keys) {
        if ($newMap.ContainsKey($key)) {
            # Get properties and apply filters & normalization
            $refProps = $refMap[$key].properties
            $newProps = $newMap[$key].properties
            
            # Remove ignored properties
            if ($IgnoreProperties.Count -gt 0) {
                $refProps = Remove-IgnoredProperties $refProps $IgnoreProperties
                $newProps = Remove-IgnoredProperties $newProps $IgnoreProperties
            }
            
            # Convert to JSON with optional normalization
            if ($NormalizeJson) {
                $refNormalized = ConvertTo-NormalizedJson $refProps 10
                $newNormalized = ConvertTo-NormalizedJson $newProps 10
                $refJson = $refNormalized | ConvertTo-Json -Depth 10 -Compress
                $newJson = $newNormalized | ConvertTo-Json -Depth 10 -Compress
            } else {
                $refJson = $refProps | ConvertTo-Json -Depth 10 -Compress
                $newJson = $newProps | ConvertTo-Json -Depth 10 -Compress
            }
            
            if ($refJson -ne $newJson) {
                $changes = @()
                $allPropNames = @($refProps.PSObject.Properties.Name) + @($newProps.PSObject.Properties.Name) | 
                    Select-Object -Unique | 
                    Where-Object { $_ -notin $IgnoreProperties }

                foreach ($prop in $allPropNames) {
                    if ($NormalizeJson) {
                        $refVal = ConvertTo-NormalizedJson $refProps.$prop 5 | ConvertTo-Json -Depth 5 -Compress 2>$null
                        $newVal = ConvertTo-NormalizedJson $newProps.$prop 5 | ConvertTo-Json -Depth 5 -Compress 2>$null
                    } else {
                        $refVal = $refProps.$prop | ConvertTo-Json -Depth 5 -Compress 2>$null
                        $newVal = $newProps.$prop | ConvertTo-Json -Depth 5 -Compress 2>$null
                    }
                    
                    if ($refVal -ne $newVal) {
                        $changes += [PSCustomObject]@{
                            Property        = $prop
                            ReferenceValue  = $refProps.$prop
                            DifferenceValue = $newProps.$prop
                        }
                    }
                }

                if ($changes.Count -gt 0) {
                    $results.Modified.Add([PSCustomObject]@{
                        ChangeType   = 'Modified'
                        ResourceType = $refMap[$key].resourceType
                        DisplayName  = $refMap[$key].displayName
                        Changes      = $changes
                    })
                }
            }
        }
    }

    # ── Console output ───────────────────────────────────────────────
    Write-Host ""
    Write-Host "  Snapshot Comparison Results" -ForegroundColor Cyan
    Write-Host "  Reference : $ReferencePath" -ForegroundColor DarkGray
    Write-Host "  Difference: $DifferencePath" -ForegroundColor DarkGray
    Write-Host "  ─────────────────────────────────" -ForegroundColor DarkGray

    # Coverage warnings
    if ($missingFromNew.Count -gt 0 -or $missingFromRef.Count -gt 0) {
        Write-Host ""
        Write-Host "  Resource Type Coverage" -ForegroundColor Magenta
        if ($missingFromNew.Count -gt 0) {
            Write-Host "  Missing from Difference snapshot ($($missingFromNew.Count) types):" -ForegroundColor Magenta
            foreach ($m in $missingFromNew) {
                Write-Host "    ! $($m.ResourceType) ($($m.ResourceCount) resources)" -ForegroundColor Magenta
            }
        }
        if ($missingFromRef.Count -gt 0) {
            Write-Host "  New in Difference snapshot ($($missingFromRef.Count) types):" -ForegroundColor Magenta
            foreach ($m in $missingFromRef) {
                Write-Host "    ! $($m.ResourceType) ($($m.ResourceCount) resources)" -ForegroundColor Magenta
            }
        }
        if (-not $IncludeMissingTypes) {
            Write-Host "  (Resources in non-shared types excluded — use -IncludeMissingTypes to include)" -ForegroundColor DarkGray
        }
    }

    Write-Host ""
    Write-Host "  Shared types compared: $($sharedTypes.Count)" -ForegroundColor DarkGray
    Write-Host "  Added:    $($results.Added.Count)" -ForegroundColor Green
    Write-Host "  Removed:  $($results.Removed.Count)" -ForegroundColor Red
    Write-Host "  Modified: $($results.Modified.Count)" -ForegroundColor Yellow
    Write-Host ""

    if ($results.Added.Count -gt 0) {
        Write-Host "  Added Resources:" -ForegroundColor Green
        foreach ($a in $results.Added) {
            Write-Host "    + [$($a.ResourceType)] $($a.DisplayName)" -ForegroundColor Green
        }
        Write-Host ""
    }

    if ($results.Removed.Count -gt 0) {
        Write-Host "  Removed Resources:" -ForegroundColor Red
        foreach ($r in $results.Removed) {
            Write-Host "    - [$($r.ResourceType)] $($r.DisplayName)" -ForegroundColor Red
        }
        Write-Host ""
    }

    if ($results.Modified.Count -gt 0) {
        Write-Host "  Modified Resources:" -ForegroundColor Yellow
        foreach ($m in $results.Modified) {
            Write-Host "    ~ [$($m.ResourceType)] $($m.DisplayName)" -ForegroundColor Yellow
            foreach ($c in $m.Changes) {
                Write-Host "        $($c.Property):" -ForegroundColor DarkGray
                Write-Host "          ref: $($c.ReferenceValue | ConvertTo-Json -Depth 3 -Compress)" -ForegroundColor DarkGray
                Write-Host "          new: $($c.DifferenceValue | ConvertTo-Json -Depth 3 -Compress)" -ForegroundColor DarkGray
            }
        }
        Write-Host ""
    }

    # ── Export if requested ──────────────────────────────────────────
    if ($OutputFormat) {
        # Build flat row list for CSV / XML (one row per change entry)
        function Build-FlatRows {
            $rows = [System.Collections.Generic.List[object]]::new()

            # Coverage gaps
            foreach ($m in $missingFromNew) {
                $rows.Add([PSCustomObject]@{
                    ChangeType      = 'CoverageGap'
                    ResourceType    = $m.ResourceType
                    DisplayName     = ''
                    Property        = ''
                    ReferenceValue  = "$($m.ResourceCount) resources"
                    DifferenceValue = '(not collected)'
                    Side            = $m.Side
                })
            }
            foreach ($m in $missingFromRef) {
                $rows.Add([PSCustomObject]@{
                    ChangeType      = 'CoverageGap'
                    ResourceType    = $m.ResourceType
                    DisplayName     = ''
                    Property        = ''
                    ReferenceValue  = '(not collected)'
                    DifferenceValue = "$($m.ResourceCount) resources"
                    Side            = $m.Side
                })
            }

            # Added
            foreach ($a in $results.Added) {
                $rows.Add([PSCustomObject]@{
                    ChangeType      = 'Added'
                    ResourceType    = $a.ResourceType
                    DisplayName     = $a.DisplayName
                    Property        = ''
                    ReferenceValue  = ''
                    DifferenceValue = ''
                    Side            = ''
                })
            }

            # Removed
            foreach ($r in $results.Removed) {
                $rows.Add([PSCustomObject]@{
                    ChangeType      = 'Removed'
                    ResourceType    = $r.ResourceType
                    DisplayName     = $r.DisplayName
                    Property        = ''
                    ReferenceValue  = ''
                    DifferenceValue = ''
                    Side            = ''
                })
            }

            # Modified — one row per property change
            foreach ($m in $results.Modified) {
                foreach ($c in $m.Changes) {
                    $rows.Add([PSCustomObject]@{
                        ChangeType      = 'Modified'
                        ResourceType    = $m.ResourceType
                        DisplayName     = $m.DisplayName
                        Property        = $c.Property
                        ReferenceValue  = ($c.ReferenceValue | ConvertTo-Json -Depth 5 -Compress)
                        DifferenceValue = ($c.DifferenceValue | ConvertTo-Json -Depth 5 -Compress)
                        Side            = ''
                    })
                }
            }
            return $rows
        }

        # Ensure output directory exists
        $outDir = Split-Path $OutputPath -Parent
        if ($outDir -and -not (Test-Path $outDir)) {
            New-Item -ItemType Directory -Path $outDir -Force | Out-Null
        }

        switch ($OutputFormat) {
            'CSV' {
                $flatRows = Build-FlatRows
                $flatRows | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
                Write-Host "[UTCM] Comparison exported to CSV: $OutputPath" -ForegroundColor Green
            }
            'JSON' {
                $jsonObj = [ordered]@{
                    metadata = [ordered]@{
                        generatedAt = (Get-Date -Format 'o')
                        referencePath  = $ReferencePath
                        differencePath = $DifferencePath
                        sharedTypes    = $sharedTypes.Count
                    }
                    coverageGaps = [ordered]@{
                        missingFromDifference = @($missingFromNew)
                        missingFromReference  = @($missingFromRef)
                    }
                    added    = @($results.Added)
                    removed  = @($results.Removed)
                    modified = @(foreach ($m in $results.Modified) {
                        [ordered]@{
                            resourceType = $m.ResourceType
                            displayName  = $m.DisplayName
                            changes      = @(foreach ($c in $m.Changes) {
                                [ordered]@{
                                    property        = $c.Property
                                    referenceValue  = $c.ReferenceValue
                                    differenceValue = $c.DifferenceValue
                                }
                            })
                        }
                    })
                }
                $jsonObj | ConvertTo-Json -Depth 20 | Set-Content -Path $OutputPath -Encoding UTF8
                Write-Host "[UTCM] Comparison exported to JSON: $OutputPath" -ForegroundColor Green
            }
            'XML' {
                $flatRows = Build-FlatRows
                $xmlDoc = [xml]'<?xml version="1.0" encoding="utf-8"?><ComparisonReport/>'
                $root = $xmlDoc.DocumentElement

                # Metadata
                $meta = $xmlDoc.CreateElement('Metadata')
                foreach ($kv in @(
                    @('GeneratedAt',    (Get-Date -Format 'o')),
                    @('ReferencePath',  $ReferencePath),
                    @('DifferencePath', $DifferencePath),
                    @('SharedTypes',    $sharedTypes.Count)
                )) {
                    $el = $xmlDoc.CreateElement($kv[0])
                    $el.InnerText = $kv[1]
                    $meta.AppendChild($el) | Out-Null
                }
                $root.AppendChild($meta) | Out-Null

                # Changes
                $changesEl = $xmlDoc.CreateElement('Changes')
                foreach ($row in $flatRows) {
                    $entry = $xmlDoc.CreateElement('Change')
                    foreach ($prop in @('ChangeType','ResourceType','DisplayName','Property','ReferenceValue','DifferenceValue','Side')) {
                        $el = $xmlDoc.CreateElement($prop)
                        $el.InnerText = "$($row.$prop)"
                        $entry.AppendChild($el) | Out-Null
                    }
                    $changesEl.AppendChild($entry) | Out-Null
                }
                $root.AppendChild($changesEl) | Out-Null

                $xmlDoc.Save($OutputPath)
                Write-Host "[UTCM] Comparison exported to XML: $OutputPath" -ForegroundColor Green
            }
            'HTML' {
                $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
                $totalChanges = $results.Added.Count + $results.Removed.Count + $results.Modified.Count
                $coverageGaps = $missingFromNew.Count + $missingFromRef.Count

                $html = [System.Text.StringBuilder]::new()
                [void]$html.AppendLine(@"
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8"/>
<title>UTCM Snapshot Comparison Report</title>
<style>
  :root { --bg: #0d1117; --card: #161b22; --border: #30363d; --text: #e6edf3; --muted: #8b949e; --green: #3fb950; --red: #f85149; --yellow: #d29922; --magenta: #bc8cff; --blue: #58a6ff; }
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Helvetica, Arial, sans-serif; background: var(--bg); color: var(--text); padding: 2rem; line-height: 1.5; }
  h1 { font-size: 1.5rem; margin-bottom: 0.25rem; }
  .subtitle { color: var(--muted); font-size: 0.85rem; margin-bottom: 1.5rem; }
  .summary-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(140px, 1fr)); gap: 0.75rem; margin-bottom: 1.5rem; }
  .summary-card { background: var(--card); border: 1px solid var(--border); border-radius: 8px; padding: 1rem; text-align: center; }
  .summary-card .value { font-size: 2rem; font-weight: 700; }
  .summary-card .label { font-size: 0.8rem; color: var(--muted); }
  .green  { color: var(--green); }
  .red    { color: var(--red); }
  .yellow { color: var(--yellow); }
  .magenta{ color: var(--magenta); }
  section { background: var(--card); border: 1px solid var(--border); border-radius: 8px; padding: 1.25rem; margin-bottom: 1rem; }
  section h2 { font-size: 1.1rem; margin-bottom: 0.75rem; }
  table { width: 100%; border-collapse: collapse; font-size: 0.85rem; }
  th, td { text-align: left; padding: 0.5rem 0.75rem; border-bottom: 1px solid var(--border); }
  th { color: var(--muted); font-weight: 600; font-size: 0.75rem; text-transform: uppercase; }
  tr:last-child td { border-bottom: none; }
  .badge { display: inline-block; padding: 0.15rem 0.5rem; border-radius: 12px; font-size: 0.75rem; font-weight: 600; }
  .badge-added   { background: #238636; color: #fff; }
  .badge-removed { background: #da3633; color: #fff; }
  .badge-modified{ background: #9e6a03; color: #fff; }
  .badge-gap     { background: #6e40c9; color: #fff; }
  .prop-change   { margin: 0.25rem 0 0.25rem 1rem; font-size: 0.82rem; }
  .prop-name     { color: var(--blue); font-weight: 600; }
  .ref-val       { color: var(--red); }
  .new-val       { color: var(--green); }
  .empty-state   { color: var(--muted); font-style: italic; padding: 1rem; }
  code { font-family: 'Cascadia Code', 'Fira Code', Consolas, monospace; font-size: 0.82rem; background: var(--bg); padding: 0.15rem 0.35rem; border-radius: 4px; }
</style>
</head>
<body>
<h1>UTCM Snapshot Comparison Report</h1>
<div class="subtitle">Generated $timestamp &mdash; Reference: <code>$([System.Web.HttpUtility]::HtmlEncode($ReferencePath))</code> &mdash; Difference: <code>$([System.Web.HttpUtility]::HtmlEncode($DifferencePath))</code></div>

<div class="summary-grid">
  <div class="summary-card"><div class="value">$($sharedTypes.Count)</div><div class="label">Shared Types</div></div>
  <div class="summary-card"><div class="value green">$($results.Added.Count)</div><div class="label">Added</div></div>
  <div class="summary-card"><div class="value red">$($results.Removed.Count)</div><div class="label">Removed</div></div>
  <div class="summary-card"><div class="value yellow">$($results.Modified.Count)</div><div class="label">Modified</div></div>
  <div class="summary-card"><div class="value magenta">$coverageGaps</div><div class="label">Coverage Gaps</div></div>
</div>
"@)

                # Coverage gaps section
                if ($coverageGaps -gt 0) {
                    [void]$html.AppendLine('<section><h2 class="magenta">Resource Type Coverage Gaps</h2>')
                    [void]$html.AppendLine('<table><tr><th>Resource Type</th><th>Resources</th><th>Present In</th></tr>')
                    foreach ($m in $missingFromNew) {
                        [void]$html.AppendLine("<tr><td>$([System.Web.HttpUtility]::HtmlEncode($m.ResourceType))</td><td>$($m.ResourceCount)</td><td><span class='badge badge-gap'>Reference only</span></td></tr>")
                    }
                    foreach ($m in $missingFromRef) {
                        [void]$html.AppendLine("<tr><td>$([System.Web.HttpUtility]::HtmlEncode($m.ResourceType))</td><td>$($m.ResourceCount)</td><td><span class='badge badge-gap'>Difference only</span></td></tr>")
                    }
                    [void]$html.AppendLine('</table></section>')
                }

                # Added section
                if ($results.Added.Count -gt 0) {
                    [void]$html.AppendLine('<section><h2 class="green">Added Resources</h2>')
                    [void]$html.AppendLine('<table><tr><th>Resource Type</th><th>Display Name</th></tr>')
                    foreach ($a in ($results.Added | Sort-Object ResourceType, DisplayName)) {
                        [void]$html.AppendLine("<tr><td>$([System.Web.HttpUtility]::HtmlEncode($a.ResourceType))</td><td>$([System.Web.HttpUtility]::HtmlEncode($a.DisplayName))</td></tr>")
                    }
                    [void]$html.AppendLine('</table></section>')
                }

                # Removed section
                if ($results.Removed.Count -gt 0) {
                    [void]$html.AppendLine('<section><h2 class="red">Removed Resources</h2>')
                    [void]$html.AppendLine('<table><tr><th>Resource Type</th><th>Display Name</th></tr>')
                    foreach ($r in ($results.Removed | Sort-Object ResourceType, DisplayName)) {
                        [void]$html.AppendLine("<tr><td>$([System.Web.HttpUtility]::HtmlEncode($r.ResourceType))</td><td>$([System.Web.HttpUtility]::HtmlEncode($r.DisplayName))</td></tr>")
                    }
                    [void]$html.AppendLine('</table></section>')
                }

                # Modified section
                if ($results.Modified.Count -gt 0) {
                    [void]$html.AppendLine('<section><h2 class="yellow">Modified Resources</h2>')
                    [void]$html.AppendLine('<table><tr><th>Resource Type</th><th>Display Name</th><th>Property Changes</th></tr>')
                    foreach ($m in ($results.Modified | Sort-Object ResourceType, DisplayName)) {
                        $changeCells = ""
                        foreach ($c in $m.Changes) {
                            $refStr = [System.Web.HttpUtility]::HtmlEncode(($c.ReferenceValue | ConvertTo-Json -Depth 3 -Compress))
                            $newStr = [System.Web.HttpUtility]::HtmlEncode(($c.DifferenceValue | ConvertTo-Json -Depth 3 -Compress))
                            $changeCells += "<div class='prop-change'><span class='prop-name'>$([System.Web.HttpUtility]::HtmlEncode($c.Property))</span>: <span class='ref-val'>$refStr</span> &rarr; <span class='new-val'>$newStr</span></div>"
                        }
                        [void]$html.AppendLine("<tr><td>$([System.Web.HttpUtility]::HtmlEncode($m.ResourceType))</td><td>$([System.Web.HttpUtility]::HtmlEncode($m.DisplayName))</td><td>$changeCells</td></tr>")
                    }
                    [void]$html.AppendLine('</table></section>')
                }

                # No changes message
                if ($totalChanges -eq 0 -and $coverageGaps -eq 0) {
                    [void]$html.AppendLine('<section><p class="empty-state">No differences found between the two snapshots.</p></section>')
                }

                [void]$html.AppendLine('</body></html>')
                $html.ToString() | Set-Content -Path $OutputPath -Encoding UTF8
                Write-Host "[UTCM] Comparison exported to HTML: $OutputPath" -ForegroundColor Green
            }
        }
    }

    # Return structured results for pipeline use
    $totalChanges = $results.Added.Count + $results.Removed.Count + $results.Modified.Count
    $coverageGapsArray = @($missingFromNew) + @($missingFromRef)
    
    $comparisonResult = [PSCustomObject]@{
        PSTypeName = 'UTCM.SnapshotComparison'
        Summary = [PSCustomObject]@{
            TotalChanges      = $totalChanges
            SharedTypes       = $sharedTypes.Count
            AddedCount        = $results.Added.Count
            RemovedCount      = $results.Removed.Count
            ModifiedCount     = $results.Modified.Count
            CoverageGapsCount = $coverageGapsArray.Count
        }
        ResourceChanges = [PSCustomObject]@{
            Added    = $results.Added
            Removed  = $results.Removed
            Modified = $results.Modified
        }
        CoverageGaps = $coverageGapsArray
        SharedTypes  = $sharedTypes
    }
    
    return $comparisonResult
}
