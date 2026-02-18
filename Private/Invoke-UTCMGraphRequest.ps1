function Invoke-UTCMGraphRequest {
    <#
    .SYNOPSIS
        Core helper — sends an authenticated request to Microsoft Graph
        and handles pagination and throttling automatically.

    .DESCRIPTION
        Wraps Invoke-RestMethod with:
        - Automatic retry on HTTP 429 (Too Many Requests) and 503/504
          with exponential back-off, honouring the Retry-After header.
        - Automatic pagination via @odata.nextLink.
        - JSON body serialisation.

    .PARAMETER MaxRetries
        Maximum number of retries on throttling errors (default: 3).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Uri,
        [ValidateSet('GET','POST','PATCH','DELETE')][string]$Method = 'GET',
        [object]$Body,
        [switch]$Raw,          # return entire response object, not just .value
        [int]$MaxRetries = 3   # retry limit for 429 / 503 / 504
    )

    $headers = Get-UTCMAuthHeaders
    $params  = @{
        Uri     = $Uri
        Method  = $Method
        Headers = $headers
    }
    if ($Body) {
        $params.Body = if ($Body -is [string]) { $Body } else { $Body | ConvertTo-Json -Depth 20 }
    }

    # ── Execute with retry logic ─────────────────────────────────────
    $attempt  = 0
    $response = $null
    
    Write-Verbose "[UTCM] $Method $Uri"
    if ($Body -and $PSCmdlet.MyInvocation.BoundParameters['Verbose']) {
        Write-Verbose "[UTCM] Request body: $($params.Body)"
    }
    
    while ($true) {
        try {
            $response = Invoke-RestMethod @params
            Write-Verbose "[UTCM] Request completed successfully"
            break   # success — exit retry loop
        }
        catch {
            $statusCode = $null
            $errorMessage = $_.Exception.Message
            $errorDetails = $null
            
            if ($_.Exception.Response) {
                $statusCode = [int]$_.Exception.Response.StatusCode
            }
            
            # Try to extract detailed error from Graph API response
            if ($_.ErrorDetails.Message) {
                try {
                    $errorObj = $_.ErrorDetails.Message | ConvertFrom-Json
                    if ($errorObj.error) {
                        $errorDetails = "$($errorObj.error.code): $($errorObj.error.message)"
                    }
                } catch {
                    $errorDetails = $_.ErrorDetails.Message
                }
            }

            $retryable = $statusCode -in @(429, 503, 504)
            $attempt++

            if ($retryable -and $attempt -le $MaxRetries) {
                # Determine wait time: prefer Retry-After header, fall back to exponential back-off
                $retryAfter = $null
                if ($_.Exception.Response.Headers) {
                    try {
                        $raHeader = $_.Exception.Response.Headers |
                            Where-Object { $_.Key -eq 'Retry-After' } |
                            Select-Object -ExpandProperty Value -First 1
                        if ($raHeader) { $retryAfter = [int]$raHeader }
                    } catch { }
                }
                if (-not $retryAfter -or $retryAfter -le 0) {
                    $retryAfter = [math]::Pow(2, $attempt)   # 2, 4, 8 seconds
                }

                Write-Warning "[UTCM] HTTP $statusCode on $Method $Uri — retrying in ${retryAfter}s (attempt $attempt/$MaxRetries)"
                Start-Sleep -Seconds $retryAfter
                continue
            }

            # Non-retryable or retries exhausted
            $fullError = if ($errorDetails) { $errorDetails } else { $errorMessage }
            $errorMsg = "Graph API request failed [$Method $Uri]"
            if ($statusCode) { $errorMsg += " (HTTP $statusCode)" }
            $errorMsg += ": $fullError"
            
            Write-Error $errorMsg
            throw
        }
    }

    if ($Raw) { return $response }

    # ── Handle paginated collections ─────────────────────────────────
    $results = @()
    if ($null -ne $response.value) {
        $results += $response.value
        while ($response.'@odata.nextLink') {
            # Pagination requests also get retry logic
            $pageAttempt = 0
            while ($true) {
                try {
                    $response = Invoke-RestMethod -Uri $response.'@odata.nextLink' -Headers $headers
                    break
                }
                catch {
                    $statusCode = $null
                    $errorMessage = $_.Exception.Message
                    $errorDetails = $null
                    
                    if ($_.Exception.Response) {
                        $statusCode = [int]$_.Exception.Response.StatusCode
                    }
                    
                    # Try to extract detailed error from Graph API response
                    if ($_.ErrorDetails.Message) {
                        try {
                            $errorObj = $_.ErrorDetails.Message | ConvertFrom-Json
                            if ($errorObj.error) {
                                $errorDetails = "$($errorObj.error.code): $($errorObj.error.message)"
                            }
                        } catch {
                            $errorDetails = $_.ErrorDetails.Message
                        }
                    }
                    
                    $pageAttempt++
                    $retryable = $statusCode -in @(429, 503, 504)

                    if ($retryable -and $pageAttempt -le $MaxRetries) {
                        $retryAfter = $null
                        if ($_.Exception.Response.Headers) {
                            try {
                                $raHeader = $_.Exception.Response.Headers |
                                    Where-Object { $_.Key -eq 'Retry-After' } |
                                    Select-Object -ExpandProperty Value -First 1
                                if ($raHeader) { $retryAfter = [int]$raHeader }
                            } catch { }
                        }
                        if (-not $retryAfter -or $retryAfter -le 0) {
                            $retryAfter = [math]::Pow(2, $pageAttempt)
                        }
                        Write-Warning "[UTCM] HTTP $statusCode during pagination — retrying in ${retryAfter}s (attempt $pageAttempt/$MaxRetries)"
                        Start-Sleep -Seconds $retryAfter
                        continue
                    }

                    $fullError = if ($errorDetails) { $errorDetails } else { $errorMessage }
                    $errorMsg = "Graph API pagination failed"
                    if ($statusCode) { $errorMsg += " (HTTP $statusCode)" }
                    $errorMsg += ": $fullError"
                    
                    Write-Error $errorMsg
                    throw
                }
            }
            $results += $response.value
        }
        return $results
    }

    return $response
}
