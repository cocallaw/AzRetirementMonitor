BeforeAll {
    Import-Module "$PSScriptRoot/../AzRetirementMonitor.psd1" -Force
}

Describe "Module Import" {
    It "Should load the module" {
        Get-Module AzRetirementMonitor | Should -Not -BeNull
    }
    
    It "Should export 5 functions" {
        $commands = Get-Command -Module AzRetirementMonitor
        $commands.Count | Should -Be 5
    }
    
    It "Should export Connect-AzRetirementMonitor" {
        Get-Command Connect-AzRetirementMonitor -Module AzRetirementMonitor | Should -Not -BeNull
    }
    
    It "Should export Get-AzRetirementRecommendation" {
        Get-Command Get-AzRetirementRecommendation -Module AzRetirementMonitor | Should -Not -BeNull
    }
    
    It "Should export Get-AzRetirementMetadataItem" {
        Get-Command Get-AzRetirementMetadataItem -Module AzRetirementMonitor | Should -Not -BeNull
    }
    
    It "Should export Export-AzRetirementReport" {
        Get-Command Export-AzRetirementReport -Module AzRetirementMonitor | Should -Not -BeNull
    }
    
    It "Should export Disconnect-AzRetirementMonitor" {
        Get-Command Disconnect-AzRetirementMonitor -Module AzRetirementMonitor | Should -Not -BeNull
    }
}

Describe "Connect-AzRetirementMonitor" {
    It "Should have UseAzCLI parameter set as default" {
        $cmd = Get-Command Connect-AzRetirementMonitor
        $cmd.ParameterSets[0].Name | Should -Be 'AzCLI'
    }
    
    It "Should have two parameter sets" {
        $cmd = Get-Command Connect-AzRetirementMonitor
        $cmd.ParameterSets.Count | Should -Be 2
    }
}

Describe "Connect-AzRetirementMonitor SecureString Handling" {
    BeforeAll {
        # Check if Az.Accounts is available, if not, skip the entire describe block
        $script:AzAccountsAvailable = $null -ne (Get-Module -ListAvailable -Name Az.Accounts)
    }
    
    BeforeEach {
        # Clear the token before each test
        $module = Get-Module AzRetirementMonitor
        & $module { $script:AccessToken = $null }
    }
    
    Context "Az.Accounts 5.0+ with SecureString Token" {
        It "Should convert SecureString token to plain text" -Skip:(-not $script:AzAccountsAvailable) {
            # Mock Get-Module to simulate Az.Accounts being available
            Mock -ModuleName AzRetirementMonitor Get-Module -ParameterFilter { $Name -eq 'Az.Accounts' -and $ListAvailable } {
                return @{ Name = 'Az.Accounts'; Version = '5.0.0' }
            }
            
            # Mock Import-Module to prevent actual import
            Mock -ModuleName AzRetirementMonitor Import-Module { }
            
            # Mock Get-AzContext to return a context
            Mock -ModuleName AzRetirementMonitor Get-AzContext {
                return @{
                    Account = @{ Id = "test@example.com" }
                    Subscription = @{ Id = "test-subscription-id" }
                }
            }
            
            # Create a SecureString token to simulate Az.Accounts 5.0+ behavior
            $plainTextToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjk5OTk5OTk5OTksImF1ZCI6Imh0dHBzOi8vbWFuYWdlbWVudC5henVyZS5jb20ifQ.dummysignature"
            $secureToken = ConvertTo-SecureString -String $plainTextToken -AsPlainText -Force
            
            # Mock Get-AzAccessToken to return a token object with SecureString Token property
            Mock -ModuleName AzRetirementMonitor Get-AzAccessToken {
                return [PSCustomObject]@{
                    Token = $secureToken
                    ExpiresOn = [DateTimeOffset]::UtcNow.AddHours(1)
                }
            }
            
            # Call Connect-AzRetirementMonitor with UseAzPowerShell
            Connect-AzRetirementMonitor -UseAzPowerShell
            
            # Verify the token was set correctly in module scope
            $module = Get-Module AzRetirementMonitor
            $storedToken = & $module { $script:AccessToken }
            
            # The stored token should be the plain text version
            $storedToken | Should -Be $plainTextToken
            $storedToken | Should -BeOfType [string]
            $storedToken | Should -Not -BeOfType [System.Security.SecureString]
        }
    }
    
    Context "Older Az.Accounts with Plain Text Token" {
        It "Should use plain text token directly" -Skip:(-not $script:AzAccountsAvailable) {
            # Mock Get-Module to simulate Az.Accounts being available
            Mock -ModuleName AzRetirementMonitor Get-Module -ParameterFilter { $Name -eq 'Az.Accounts' -and $ListAvailable } {
                return @{ Name = 'Az.Accounts'; Version = '4.9.0' }
            }
            
            # Mock Import-Module to prevent actual import
            Mock -ModuleName AzRetirementMonitor Import-Module { }
            
            # Mock Get-AzContext to return a context
            Mock -ModuleName AzRetirementMonitor Get-AzContext {
                return @{
                    Account = @{ Id = "test@example.com" }
                    Subscription = @{ Id = "test-subscription-id" }
                }
            }
            
            # Create a plain text token to simulate older Az.Accounts behavior
            $plainTextToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjk5OTk5OTk5OTksImF1ZCI6Imh0dHBzOi8vbWFuYWdlbWVudC5henVyZS5jb20ifQ.dummysignature"
            
            # Mock Get-AzAccessToken to return a token object with plain text Token property
            Mock -ModuleName AzRetirementMonitor Get-AzAccessToken {
                return [PSCustomObject]@{
                    Token = $plainTextToken
                    ExpiresOn = [DateTimeOffset]::UtcNow.AddHours(1)
                }
            }
            
            # Call Connect-AzRetirementMonitor with UseAzPowerShell
            Connect-AzRetirementMonitor -UseAzPowerShell
            
            # Verify the token was set correctly in module scope
            $module = Get-Module AzRetirementMonitor
            $storedToken = & $module { $script:AccessToken }
            
            # The stored token should be the plain text version
            $storedToken | Should -Be $plainTextToken
            $storedToken | Should -BeOfType [string]
        }
    }
}

Describe "Disconnect-AzRetirementMonitor" {
    BeforeEach {
        # Clear the token before each test
        $module = Get-Module AzRetirementMonitor
        & $module { $script:AccessToken = $null }
    }
    
    It "Should clear the access token when connected" {
        # Set up a token
        $module = Get-Module AzRetirementMonitor
        & $module { $script:AccessToken = "test-token-value" }
        
        # Verify token is set
        $tokenBefore = & $module { $script:AccessToken }
        $tokenBefore | Should -Be "test-token-value"
        
        # Disconnect
        Disconnect-AzRetirementMonitor
        
        # Verify token is cleared
        $tokenAfter = & $module { $script:AccessToken }
        $tokenAfter | Should -BeNullOrEmpty
    }
    
    It "Should handle disconnecting when not connected" {
        # Ensure no token is set
        $module = Get-Module AzRetirementMonitor
        & $module { $script:AccessToken = $null }
        
        # Should not throw
        { Disconnect-AzRetirementMonitor } | Should -Not -Throw
    }
}

Describe "Get-AzRetirementRecommendation" {
    It "Should have SubscriptionId parameter" {
        $cmd = Get-Command Get-AzRetirementRecommendation
        $cmd.Parameters.ContainsKey('SubscriptionId') | Should -Be $true
    }
    
    It "Should accept pipeline input for SubscriptionId" {
        $cmd = Get-Command Get-AzRetirementRecommendation
        $param = $cmd.Parameters['SubscriptionId']
        $param.Attributes.Where({$_.ValueFromPipeline}).Count | Should -BeGreaterThan 0
    }
    
    It "Should not have Category parameter" {
        $cmd = Get-Command Get-AzRetirementRecommendation
        $cmd.Parameters.ContainsKey('Category') | Should -Be $false
    }
    
    It "Should not have ImpactLevel parameter" {
        $cmd = Get-Command Get-AzRetirementRecommendation
        $cmd.Parameters.ContainsKey('ImpactLevel') | Should -Be $false
    }
}

Describe "Get-AzRetirementMetadataItem" {
    It "Should have no parameters" {
        $cmd = Get-Command Get-AzRetirementMetadataItem
        $cmd.Parameters.Keys.Where({$_ -notin @('Verbose', 'Debug', 'ErrorAction', 'WarningAction', 'InformationAction', 'ErrorVariable', 'WarningVariable', 'InformationVariable', 'OutVariable', 'OutBuffer', 'PipelineVariable', 'ProgressAction')}).Count | Should -Be 0
    }
}

Describe "Export-AzRetirementReport" {
    It "Should accept valid formats" {
        $cmd = Get-Command Export-AzRetirementReport
        $param = $cmd.Parameters['Format']
        $param.Attributes.ValidValues | Should -Contain 'CSV'
        $param.Attributes.ValidValues | Should -Contain 'JSON'
        $param.Attributes.ValidValues | Should -Contain 'HTML'
    }
    
    It "Should have Recommendations parameter as mandatory" {
        $cmd = Get-Command Export-AzRetirementReport
        $param = $cmd.Parameters['Recommendations']
        $param.Attributes.Where({$_.TypeId.Name -eq 'ParameterAttribute' -and $_.Mandatory}).Count | Should -BeGreaterThan 0
    }
    
    It "Should have OutputPath parameter as mandatory" {
        $cmd = Get-Command Export-AzRetirementReport
        $param = $cmd.Parameters['OutputPath']
        $param.Attributes.Where({$_.TypeId.Name -eq 'ParameterAttribute' -and $_.Mandatory}).Count | Should -BeGreaterThan 0
    }
    
    It "Should accept pipeline input for Recommendations" {
        $cmd = Get-Command Export-AzRetirementReport
        $param = $cmd.Parameters['Recommendations']
        $param.Attributes.Where({$_.ValueFromPipeline}).Count | Should -BeGreaterThan 0
    }
}

Describe "Token Expiration Validation" {
    BeforeAll {
        # Helper function to create a test JWT token with specified expiration
        function New-TestToken {
            param(
                [Parameter(Mandatory)]
                [long]$ExpirationUnixTime
            )
            
            # Header: {"alg":"HS256","typ":"JWT"}
            $header = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9"
            
            # Create payload with specified expiration and valid audience using ConvertTo-Json
            $payloadObj = @{
                exp = $ExpirationUnixTime
                aud = "https://management.azure.com"
            }
            $payloadJson = $payloadObj | ConvertTo-Json -Compress
            $payloadBytes = [System.Text.Encoding]::UTF8.GetBytes($payloadJson)
            $payload = [Convert]::ToBase64String($payloadBytes).TrimEnd('=').Replace('+', '-').Replace('/', '_')
            
            # Dummy signature
            $signature = "dummysignature"
            
            return "$header.$payload.$signature"
        }
    }
    
    BeforeEach {
        # Clear the token without reimporting the entire module
        $module = Get-Module AzRetirementMonitor
        & $module { $script:AccessToken = $null }
    }
    
    It "Get-AzRetirementMetadataItem should throw when not authenticated" {
        { Get-AzRetirementMetadataItem -ErrorAction Stop } | Should -Throw "*Not authenticated*"
    }
    
    It "Get-AzRetirementRecommendation should throw when not authenticated" {
        { Get-AzRetirementRecommendation -ErrorAction Stop } | Should -Throw "*Not authenticated*"
    }
    
    It "Get-AzRetirementMetadataItem should throw when token is expired" {
        # Create an expired token (January 1, 2020)
        $expiredTime = [DateTimeOffset]::new(2020, 1, 1, 0, 0, 0, [TimeSpan]::Zero).ToUnixTimeSeconds()
        $expiredToken = New-TestToken -ExpirationUnixTime $expiredTime
        
        # Access the module's script scope to set the token
        $module = Get-Module AzRetirementMonitor
        & $module { param($token) $script:AccessToken = $token } $expiredToken
        
        { Get-AzRetirementMetadataItem -ErrorAction Stop } | Should -Throw "*expired*"
    }
    
    It "Get-AzRetirementRecommendation should throw when token is expired" {
        # Create an expired token (January 1, 2020)
        $expiredTime = [DateTimeOffset]::new(2020, 1, 1, 0, 0, 0, [TimeSpan]::Zero).ToUnixTimeSeconds()
        $expiredToken = New-TestToken -ExpirationUnixTime $expiredTime
        
        # Access the module's script scope to set the token
        $module = Get-Module AzRetirementMonitor
        & $module { param($token) $script:AccessToken = $token } $expiredToken
        
        { Get-AzRetirementRecommendation -ErrorAction Stop } | Should -Throw "*expired*"
    }
    
    It "Should validate a token with future expiration as valid" {
        # Create a token that expires in the near future (relative to now)
        $futureTime = [DateTimeOffset]::UtcNow.AddDays(1).ToUnixTimeSeconds()
        $validToken = New-TestToken -ExpirationUnixTime $futureTime
        
        # Access the module's script scope to set the token and test it
        $module = Get-Module AzRetirementMonitor
        & $module { param($token) $script:AccessToken = $token } $validToken
        
        # Call the private Test function to verify the token is valid
        $testResult = & $module { Test-AzRetirementMonitorToken }
        $testResult | Should -Be $true
    }
    
    It "Should reject token with incorrect number of segments" {
        # Test with token that has only 2 segments (missing signature)
        $malformedToken = "header.payload"
        
        $module = Get-Module AzRetirementMonitor
        & $module { param($token) $script:AccessToken = $token } $malformedToken
        
        $testResult = & $module { Test-AzRetirementMonitorToken }
        $testResult | Should -Be $false
    }
    
    It "Should reject token with invalid Base64 encoding" {
        # Token with invalid Base64 characters in payload
        $header = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9"
        $invalidPayload = "!!!invalid@@@base64###"
        $signature = "dummysignature"
        $malformedToken = "$header.$invalidPayload.$signature"
        
        $module = Get-Module AzRetirementMonitor
        & $module { param($token) $script:AccessToken = $token } $malformedToken
        
        $testResult = & $module { Test-AzRetirementMonitorToken }
        $testResult | Should -Be $false
    }
    
    It "Should reject token without exp claim" {
        # Create a token with valid structure but no exp claim
        $header = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9"
        
        # Payload with only sub claim, no exp
        $payloadObj = @{sub = "user123"; iat = 1234567890}
        $payloadJson = $payloadObj | ConvertTo-Json -Compress
        $payloadBytes = [System.Text.Encoding]::UTF8.GetBytes($payloadJson)
        $payload = [Convert]::ToBase64String($payloadBytes).TrimEnd('=').Replace('+', '-').Replace('/', '_')
        
        $signature = "dummysignature"
        $tokenNoExp = "$header.$payload.$signature"
        
        $module = Get-Module AzRetirementMonitor
        & $module { param($token) $script:AccessToken = $token } $tokenNoExp
        
        $testResult = & $module { Test-AzRetirementMonitorToken }
        $testResult | Should -Be $false
    }
}

Describe "Token Audience Validation" {
    BeforeAll {
        # Helper function to create a test JWT token with audience and expiration
        function New-TestTokenWithAudience {
            param(
                [Parameter(Mandatory)]
                [string]$Audience,
                [long]$ExpirationUnixTime = ([DateTimeOffset]::UtcNow.AddDays(1).ToUnixTimeSeconds())
            )
            
            # Header: {"alg":"HS256","typ":"JWT"}
            $header = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9"
            
            # Create payload with audience and expiration
            $payloadObj = @{
                aud = $Audience
                exp = $ExpirationUnixTime
            }
            $payloadJson = $payloadObj | ConvertTo-Json -Compress
            $payloadBytes = [System.Text.Encoding]::UTF8.GetBytes($payloadJson)
            $payload = [Convert]::ToBase64String($payloadBytes).TrimEnd('=').Replace('+', '-').Replace('/', '_')
            
            # Dummy signature
            $signature = "dummysignature"
            
            return "$header.$payload.$signature"
        }
    }
    
    BeforeEach {
        # Clear the token before each test
        $module = Get-Module AzRetirementMonitor
        & $module { $script:AccessToken = $null }
    }
    
    It "Should accept token with https://management.azure.com audience" {
        $token = New-TestTokenWithAudience -Audience "https://management.azure.com"
        
        $module = Get-Module AzRetirementMonitor
        & $module { param($token) $script:AccessToken = $token } $token
        
        $testResult = & $module { Test-AzRetirementMonitorToken }
        $testResult | Should -Be $true
    }
    
    It "Should accept token with https://management.azure.com/ audience (with trailing slash)" {
        $token = New-TestTokenWithAudience -Audience "https://management.azure.com/"
        
        $module = Get-Module AzRetirementMonitor
        & $module { param($token) $script:AccessToken = $token } $token
        
        $testResult = & $module { Test-AzRetirementMonitorToken }
        $testResult | Should -Be $true
    }
    
    It "Should accept token with https://management.core.windows.net audience" {
        # Legacy Azure Resource Manager endpoint for backward compatibility with older Azure CLI versions
        $token = New-TestTokenWithAudience -Audience "https://management.core.windows.net"
        
        $module = Get-Module AzRetirementMonitor
        & $module { param($token) $script:AccessToken = $token } $token
        
        $testResult = & $module { Test-AzRetirementMonitorToken }
        $testResult | Should -Be $true
    }
    
    It "Should reject token with incorrect audience (Graph API)" {
        $token = New-TestTokenWithAudience -Audience "https://graph.microsoft.com"
        
        $module = Get-Module AzRetirementMonitor
        & $module { param($token) $script:AccessToken = $token } $token
        
        $testResult = & $module { Test-AzRetirementMonitorToken }
        $testResult | Should -Be $false
    }
    
    It "Should reject token with incorrect audience (arbitrary resource)" {
        $token = New-TestTokenWithAudience -Audience "https://example.com"
        
        $module = Get-Module AzRetirementMonitor
        & $module { param($token) $script:AccessToken = $token } $token
        
        $testResult = & $module { Test-AzRetirementMonitorToken }
        $testResult | Should -Be $false
    }
    
    It "Should reject token without audience claim" {
        $header = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9"
        
        # Payload with exp but no aud
        $futureTime = [DateTimeOffset]::UtcNow.AddDays(1).ToUnixTimeSeconds()
        $payloadObj = @{exp = $futureTime; sub = "user123"}
        $payloadJson = $payloadObj | ConvertTo-Json -Compress
        $payloadBytes = [System.Text.Encoding]::UTF8.GetBytes($payloadJson)
        $payload = [Convert]::ToBase64String($payloadBytes).TrimEnd('=').Replace('+', '-').Replace('/', '_')
        
        $signature = "dummysignature"
        $tokenNoAud = "$header.$payload.$signature"
        
        $module = Get-Module AzRetirementMonitor
        & $module { param($token) $script:AccessToken = $token } $tokenNoAud
        
        $testResult = & $module { Test-AzRetirementMonitorToken }
        $testResult | Should -Be $false
    }
}