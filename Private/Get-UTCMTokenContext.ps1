function Get-UTCMTokenContext {
    <#
    .SYNOPSIS
        Decodes a JWT access token and extracts identity and scope claims.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [string]$Token
    )

    try {
        # Decode the JWT payload (second segment)
        $parts   = $Token.Split('.')
        $payload = $parts[1]
        
        # Convert Base64url to standard Base64
        $payload = $payload -replace '-','+' -replace '_','/'
        
        # Fix Base64 padding
        switch ($payload.Length % 4) {
            2 { $payload += '==' }
            3 { $payload += '='  }
        }
        $json   = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($payload))
        $claims = $json | ConvertFrom-Json

        @{
            Account    = $claims.upn  ?? $claims.unique_name ?? $claims.preferred_username ?? $claims.app_displayname ?? $claims.azp ?? 'Unknown'
            TenantId   = $claims.tid  ?? 'Unknown'
            ObjectId   = $claims.oid  ?? 'Unknown'
            AppId      = $claims.appid ?? $claims.azp ?? 'Unknown'
            Scopes     = if ($claims.scp) { $claims.scp -split ' ' } elseif ($claims.roles) { $claims.roles } else { @() }
            ExpiresOn  = if ($claims.exp) { [DateTimeOffset]::FromUnixTimeSeconds($claims.exp).LocalDateTime } else { $script:TokenExpiry }
            AuthMethod = if ($claims.scp) { 'Delegated' } else { 'Application' }
        }
    }
    catch {
        Write-Warning "[UTCM] Could not decode token claims: $_"
        @{
            Account    = 'Unknown'
            TenantId   = 'Unknown'
            ObjectId   = 'Unknown'
            AppId      = 'Unknown'
            Scopes     = @()
            ExpiresOn  = $script:TokenExpiry
            AuthMethod = 'Unknown'
        }
    }
}
