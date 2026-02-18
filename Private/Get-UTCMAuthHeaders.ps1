function Get-UTCMAuthHeaders {
    Assert-UTCMConnected
    @{
        Authorization    = "Bearer $($script:Token)"
        'Content-Type'   = 'application/json'
        ConsistencyLevel = 'eventual'
    }
}
