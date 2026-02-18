#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0' }
<#
.SYNOPSIS
    Unit tests for all Private helper functions.
#>

BeforeAll {
    # Enable transcript logging for external test runs
    $transcriptPath = Join-Path $PSScriptRoot '..' 'logs' "Private.Tests_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    $null = New-Item -Path (Split-Path $transcriptPath) -ItemType Directory -Force -ErrorAction SilentlyContinue
    Start-Transcript -Path $transcriptPath -Force
    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Starting Private.Tests.ps1" -ForegroundColor Cyan
    Write-Host "[TRANSCRIPT] Logging to: $transcriptPath" -ForegroundColor Green

    # Import the module so all internal functions are available
    $modulePath = Join-Path $PSScriptRoot '..' '..' 'UTCM.psd1'
    Import-Module $modulePath -Force

    # Get InternalModule so we can call private functions and access script-scope vars
    $internalModule = Get-Module UTCM
}

AfterAll {
    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Completed Private.Tests.ps1" -ForegroundColor Cyan
    Remove-Module UTCM -Force -ErrorAction SilentlyContinue
    Stop-Transcript
}

# ═══════════════════════════════════════════════════════════════════════════
# Assert-UTCMConnected
# ═══════════════════════════════════════════════════════════════════════════
Describe 'Assert-UTCMConnected' {
    BeforeAll {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Testing Assert-UTCMConnected" -ForegroundColor Yellow
    }

    It 'Throws when no token is set' {
        & $internalModule {
            $script:Token = $null
            $script:TokenExpiry = (Get-Date).AddHours(1)
        }
        { & $internalModule { Assert-UTCMConnected } } | Should -Throw '*Not connected*'
    }

    It 'Throws when token is expired' {
        & $internalModule {
            $script:Token = 'some-token'
            $script:TokenExpiry = (Get-Date).AddMinutes(-5)
        }
        { & $internalModule { Assert-UTCMConnected } } | Should -Throw '*expired*'
    }

    It 'Does not throw when token is valid and not expired' {
        & $internalModule {
            $script:Token = 'valid-token'
            $script:TokenExpiry = (Get-Date).AddHours(1)
        }
        { & $internalModule { Assert-UTCMConnected } } | Should -Not -Throw
    }
}

# ═══════════════════════════════════════════════════════════════════════════
# Get-UTCMAuthHeaders
# ═══════════════════════════════════════════════════════════════════════════
Describe 'Get-UTCMAuthHeaders' {
    BeforeAll {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Testing Get-UTCMAuthHeaders" -ForegroundColor Yellow
    }

    BeforeEach {
        & $internalModule {
            $script:Token = 'test-bearer-token'
            $script:TokenExpiry = (Get-Date).AddHours(1)
        }
    }

    It 'Returns a hashtable with Authorization header' {
        $headers = & $internalModule { Get-UTCMAuthHeaders }
        $headers.Authorization | Should -Be 'Bearer test-bearer-token'
    }

    It 'Returns Content-Type application/json' {
        $headers = & $internalModule { Get-UTCMAuthHeaders }
        $headers.'Content-Type' | Should -Be 'application/json'
    }

    It 'Returns ConsistencyLevel eventual' {
        $headers = & $internalModule { Get-UTCMAuthHeaders }
        $headers.ConsistencyLevel | Should -Be 'eventual'
    }

    It 'Throws when not connected' {
        & $internalModule { $script:Token = $null }
        { & $internalModule { Get-UTCMAuthHeaders } } | Should -Throw '*Not connected*'
    }
}

# ═══════════════════════════════════════════════════════════════════════════
# Get-UTCMTokenContext
# ═══════════════════════════════════════════════════════════════════════════
Describe 'Get-UTCMTokenContext' {
    BeforeAll {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Testing Get-UTCMTokenContext" -ForegroundColor Yellow
    }

    Context 'Delegated token (with scp claim)' {
        BeforeAll {
            # Build a realistic JWT with delegated claims
            $header  = @{ alg = 'RS256'; typ = 'JWT' } | ConvertTo-Json -Compress
            $payload = @{
                upn  = 'user@contoso.com'
                tid  = '00000000-0000-0000-0000-000000000001'
                oid  = '00000000-0000-0000-0000-000000000002'
                appid = '14d82eec-204b-4c2f-b7e8-296a70dab67e'
                scp  = 'openid profile offline_access ConfigurationMonitoring.ReadWrite.All'
                exp  = ([DateTimeOffset](Get-Date).AddHours(1)).ToUnixTimeSeconds()
            } | ConvertTo-Json -Compress

            # Base64url-encode
            $toBase64Url = {
                param([string]$text)
                [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($text)) -replace '\+','-' -replace '/','_' -replace '='
            }

            $script:testToken = "$(&$toBase64Url $header).$(&$toBase64Url $payload).fake-signature"
        }

        It 'Extracts the Account from upn claim' {
            $ctx = & $internalModule { param($t) Get-UTCMTokenContext -Token $t } $testToken
            $ctx.Account | Should -Be 'user@contoso.com'
        }

        It 'Extracts the TenantId' {
            $ctx = & $internalModule { param($t) Get-UTCMTokenContext -Token $t } $testToken
            $ctx.TenantId | Should -Be '00000000-0000-0000-0000-000000000001'
        }

        It 'Identifies AuthMethod as Delegated' {
            $ctx = & $internalModule { param($t) Get-UTCMTokenContext -Token $t } $testToken
            $ctx.AuthMethod | Should -Be 'Delegated'
        }

        It 'Splits scopes into an array' {
            $ctx = & $internalModule { param($t) Get-UTCMTokenContext -Token $t } $testToken
            $ctx.Scopes | Should -HaveCount 4
            $ctx.Scopes | Should -Contain 'openid'
            $ctx.Scopes | Should -Contain 'ConfigurationMonitoring.ReadWrite.All'
        }
    }

    Context 'Application token (with roles claim, no scp)' {
        BeforeAll {
            $header  = @{ alg = 'RS256'; typ = 'JWT' } | ConvertTo-Json -Compress
            $payload = @{
                azp   = 'app-client-id'
                tid   = 'tenant-123'
                oid   = 'object-456'
                roles = @('Application.Read.All', 'Policy.Read.All')
                exp   = ([DateTimeOffset](Get-Date).AddHours(1)).ToUnixTimeSeconds()
            } | ConvertTo-Json -Compress

            $toBase64Url = {
                param([string]$text)
                [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($text)) -replace '\+','-' -replace '/','_' -replace '='
            }
            $script:appToken = "$(&$toBase64Url $header).$(&$toBase64Url $payload).fake-signature"
        }

        It 'Identifies AuthMethod as Application when no scp claim' {
            $ctx = & $internalModule { param($t) Get-UTCMTokenContext -Token $t } $appToken
            $ctx.AuthMethod | Should -Be 'Application'
        }

        It 'Returns roles as Scopes' {
            $ctx = & $internalModule { param($t) Get-UTCMTokenContext -Token $t } $appToken
            $ctx.Scopes | Should -Contain 'Application.Read.All'
            $ctx.Scopes | Should -Contain 'Policy.Read.All'
        }
    }

    Context 'Malformed token' {
        It 'Returns fallback values without throwing' {
            $ctx = & $internalModule { param($t) Get-UTCMTokenContext -Token $t } 'not.a.jwt'
            $ctx.Account    | Should -Be 'Unknown'
            $ctx.TenantId   | Should -Be 'Unknown'
            $ctx.AuthMethod | Should -Be 'Unknown'
        }
    }
}

# ═══════════════════════════════════════════════════════════════════════════
# Write-UTCMContext
# ═══════════════════════════════════════════════════════════════════════════
Describe 'Write-UTCMContext' {
    BeforeAll {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Testing Write-UTCMContext" -ForegroundColor Yellow
    }

    BeforeEach {
        & $internalModule {
            $script:Context = @{
                Account    = 'test@contoso.com'
                TenantId   = 'tenant-guid'
                AuthMethod = 'Delegated'
                Scopes     = @('openid','profile')
                ExpiresOn  = (Get-Date '2026-12-31 23:59:59')
            }
        }
        # Mock Write-Host to suppress console output
        Mock Write-Host -ModuleName UTCM -MockWith { }
    }

    It 'Runs without error' {
        { & $internalModule { Write-UTCMContext } } | Should -Not -Throw
        Should -Invoke Write-Host -ModuleName UTCM -Times 6  # 6 Write-Host calls in the function
    }

    It 'Accepts an AuthFlow parameter' {
        { & $internalModule { Write-UTCMContext -AuthFlow 'Interactive' } } | Should -Not -Throw
        Should -Invoke Write-Host -ModuleName UTCM -Times 6
    }
}

# ═══════════════════════════════════════════════════════════════════════════
# Invoke-UTCMGraphRequest
# ═══════════════════════════════════════════════════════════════════════════
Describe 'Invoke-UTCMGraphRequest' {
    BeforeAll {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Testing Invoke-UTCMGraphRequest" -ForegroundColor Yellow
    }

    BeforeEach {
        # Ensure token is valid so Get-UTCMAuthHeaders passes
        & $internalModule {
            $script:Token = 'valid-token'
            $script:TokenExpiry = (Get-Date).AddHours(1)
        }
    }

    Context 'Successful simple request' {
        It 'Returns full response with -Raw' {
            Mock Invoke-RestMethod -ModuleName UTCM -MockWith {
                @{ id = '123'; displayName = 'Test Monitor' }
            }

            $result = & $internalModule {
                Invoke-UTCMGraphRequest -Uri 'https://graph.microsoft.com/beta/test' -Raw
            }
            $result.id | Should -Be '123'
        }

        It 'Returns .value collection without -Raw' {
            Mock Invoke-RestMethod -ModuleName UTCM -MockWith {
                @{ value = @(@{ id = '1' }, @{ id = '2' }) }
            }

            $result = & $internalModule {
                Invoke-UTCMGraphRequest -Uri 'https://graph.microsoft.com/beta/test'
            }
            $result | Should -HaveCount 2
        }
    }

    Context 'Pagination' {
        It 'Follows @odata.nextLink and aggregates results' {
            # First call returns page 1 with nextLink
            Mock Invoke-RestMethod -ModuleName UTCM -MockWith {
                @{
                    value             = @(@{ id = '1' })
                    '@odata.nextLink' = 'https://graph.microsoft.com/beta/test?$skiptoken=page2'
                }
            } -ParameterFilter { $Uri -notlike '*skiptoken*' }

            # Second call (pagination follow-up) returns page 2 without nextLink
            Mock Invoke-RestMethod -ModuleName UTCM -MockWith {
                @{
                    value = @(@{ id = '2' })
                }
            } -ParameterFilter { $Uri -like '*skiptoken*' }

            $result = & $internalModule {
                Invoke-UTCMGraphRequest -Uri 'https://graph.microsoft.com/beta/test'
            }
            $result | Should -HaveCount 2
        }
    }

    Context 'Retry on throttling (429)' {
        It 'Retries and eventually succeeds' {
            $script:retryCallCount = 0
            Mock Invoke-RestMethod -ModuleName UTCM -MockWith {
                $script:retryCallCount++
                if ($script:retryCallCount -le 1) {
                    # Simulate 429
                    $response     = [System.Net.Http.HttpResponseMessage]::new([System.Net.HttpStatusCode]::TooManyRequests)
                    $errorRecord  = [System.Management.Automation.ErrorRecord]::new(
                        [Microsoft.PowerShell.Commands.HttpResponseException]::new("429 Too Many Requests", $response),
                        'WebCmdletWebResponseException',
                        [System.Management.Automation.ErrorCategory]::InvalidOperation,
                        $null
                    )
                    throw $errorRecord
                }
                @{ id = 'ok'; displayName = 'Succeeded after retry' }
            }

            Mock Start-Sleep -ModuleName UTCM -MockWith { }

            $result = & $internalModule {
                Invoke-UTCMGraphRequest -Uri 'https://graph.microsoft.com/beta/test' -Raw -MaxRetries 3
            }
            $result.id | Should -Be 'ok'
        }

        It 'Throws after exhausting MaxRetries' {
            Mock Invoke-RestMethod -ModuleName UTCM -MockWith {
                $response    = [System.Net.Http.HttpResponseMessage]::new([System.Net.HttpStatusCode]::TooManyRequests)
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    [Microsoft.PowerShell.Commands.HttpResponseException]::new("429 Too Many Requests", $response),
                    'WebCmdletWebResponseException',
                    [System.Management.Automation.ErrorCategory]::InvalidOperation,
                    $null
                )
                throw $errorRecord
            }

            Mock Start-Sleep -ModuleName UTCM -MockWith { }

            {
                & $internalModule {
                    Invoke-UTCMGraphRequest -Uri 'https://graph.microsoft.com/beta/test' -Raw -MaxRetries 2
                }
            } | Should -Throw
        }
    }

    Context 'Non-retryable errors' {
        It 'Throws immediately on 400 Bad Request' {
            Mock Invoke-RestMethod -ModuleName UTCM -MockWith {
                $response = [System.Net.Http.HttpResponseMessage]::new([System.Net.HttpStatusCode]::BadRequest)
                $ex       = [Microsoft.PowerShell.Commands.HttpResponseException]::new("400 Bad Request", $response)
                throw $ex
            }

            {
                & $internalModule {
                    Invoke-UTCMGraphRequest -Uri 'https://graph.microsoft.com/beta/test' -Raw
                }
            } | Should -Throw
        }

        It 'Throws immediately on 404 Not Found' {
            Mock Invoke-RestMethod -ModuleName UTCM -MockWith {
                $response = [System.Net.Http.HttpResponseMessage]::new([System.Net.HttpStatusCode]::NotFound)
                $ex       = [Microsoft.PowerShell.Commands.HttpResponseException]::new("404 Not Found", $response)
                throw $ex
            }

            {
                & $internalModule {
                    Invoke-UTCMGraphRequest -Uri 'https://graph.microsoft.com/beta/test' -Raw
                }
            } | Should -Throw
        }
    }

    Context 'Request body' {
        It 'Serialises a hashtable body to JSON' {
            Mock Invoke-RestMethod -ModuleName UTCM -MockWith {
                @{ id = 'created' }
            } -ParameterFilter { $Body -and ($Body | ConvertFrom-Json).displayName -eq 'TestBody' }

            $result = & $internalModule {
                Invoke-UTCMGraphRequest -Uri 'https://graph.microsoft.com/beta/test' -Method POST -Body @{ displayName = 'TestBody' } -Raw
            }
            $result.id | Should -Be 'created'
        }

        It 'Passes a string body as-is' {
            $jsonString = '{"displayName":"raw"}'
            Mock Invoke-RestMethod -ModuleName UTCM -MockWith {
                @{ id = 'raw-ok' }
            } -ParameterFilter { $Body -eq '{"displayName":"raw"}' }

            $result = & $internalModule {
                Invoke-UTCMGraphRequest -Uri 'https://graph.microsoft.com/beta/test' -Method POST -Body '{"displayName":"raw"}' -Raw
            }
            $result.id | Should -Be 'raw-ok'
        }
    }
}
