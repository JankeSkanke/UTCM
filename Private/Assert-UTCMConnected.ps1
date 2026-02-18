function Assert-UTCMConnected {
    if (-not $script:Token) {
        throw "Not connected. Run Connect-UTCM first."
    }
    if ((Get-Date) -ge $script:TokenExpiry) {
        # Attempt silent token refresh before throwing
        if (Update-UTCMToken) {
            Write-Verbose "[UTCM] Access token automatically refreshed"
            return
        }
        throw "Access token has expired. Run Connect-UTCM again."
    }
}
