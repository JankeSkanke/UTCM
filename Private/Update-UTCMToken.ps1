function Update-UTCMToken {
    <#
    .SYNOPSIS
        Attempts to refresh the access token using a stored refresh token.

    .DESCRIPTION
        Internal helper that attempts silent token refresh when the access token
        has expired but a refresh token is available. This only works for delegated
        (interactive) flows where offline_access scope was granted.

        Returns $true if refresh succeeded, $false otherwise.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    # Can't refresh without necessary context
    if (-not $script:RefreshToken -or -not $script:TokenEndpoint -or -not $script:ClientId) {
        Write-Verbose "[UTCM] Token refresh not possible - missing refresh token or client context"
        return $false
    }

    try {
        Write-Verbose "[UTCM] Attempting silent token refresh..."
        
        $body = @{
            client_id     = $script:ClientId
            grant_type    = 'refresh_token'
            refresh_token = $script:RefreshToken
        }

        $response = Invoke-RestMethod -Uri $script:TokenEndpoint -Method Post -Body $body -ContentType 'application/x-www-form-urlencoded' -ErrorAction Stop

        # Update module state with new tokens
        $script:Token      = $response.access_token
        $script:TokenExpiry = (Get-Date).AddSeconds($response.expires_in - 60)
        
        # Update refresh token if a new one was issued
        if ($response.refresh_token) {
            $script:RefreshToken = $response.refresh_token
        }

        # Update context with new token claims
        $script:Context = Get-UTCMTokenContext -Token $response.access_token

        Write-Verbose "[UTCM] Token refreshed successfully. New expiry: $($script:TokenExpiry)"
        return $true
    }
    catch {
        Write-Verbose "[UTCM] Token refresh failed: $($_.Exception.Message)"
        
        # Clear refresh token on failure to prevent repeated failed attempts
        $script:RefreshToken = $null
        return $false
    }
}
