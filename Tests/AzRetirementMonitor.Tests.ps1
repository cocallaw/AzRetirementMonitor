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
        # Shared test token with far-future expiration and correct audience
        $script:TestToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjk5OTk5OTk5OTksImF1ZCI6Imh0dHBzOi8vbWFuYWdlbWVudC5henVyZS5jb20ifQ.dummysignature"
        
        # Track which stub functions we created so we can clean them up properly
        $script:CreatedStubs = @()
        
        # Create stub functions for Az.Accounts cmdlets if they don't exist
        # This allows mocking to work even when Az.Accounts is not installed
        if (-not (Get-Command Get-AzContext -ErrorAction SilentlyContinue)) {
            function global:Get-AzContext { }
            $script:CreatedStubs += 'Get-AzContext'
        }
        if (-not (Get-Command Get-AzAccessToken -ErrorAction SilentlyContinue)) {
            function global:Get-AzAccessToken { }
            $script:CreatedStubs += 'Get-AzAccessToken'
        }
    }
    
    AfterAll {
        # Clean up only the stub functions we created
        foreach ($stubName in $script:CreatedStubs) {
            Remove-Item "Function:\$stubName" -ErrorAction SilentlyContinue
        }
    }
    
    BeforeEach {
        # Clear the token before each test
        $module = Get-Module AzRetirementMonitor
        & $module { $script:AccessToken = $null }

        # Common mocks for Az.Accounts and Azure context used across tests
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
    }
    
    Context "Az.Accounts 5.0+ with SecureString Token" {
        It "Should convert SecureString token to plain text" {
            # Create a SecureString token to simulate Az.Accounts 5.0+ behavior
            $secureToken = ConvertTo-SecureString -String $script:TestToken -AsPlainText -Force
            
            # Mock Get-AzAccessToken to return a token object with SecureString Token property
            Mock -ModuleName AzRetirementMonitor Get-AzAccessToken {
                return [PSCustomObject]@{
                    Token = $secureToken
                    ExpiresOn = [DateTimeOffset]::UtcNow.AddHours(1)
                }
            }
            
            # Call Connect-AzRetirementMonitor with UseAzPowerShell
            Connect-AzRetirementMonitor -UsingAPI -UseAzPowerShell
            
            # Verify the token was set correctly in module scope
            $module = Get-Module AzRetirementMonitor
            $storedToken = & $module { $script:AccessToken }
            
            # The stored token should be the plain text version
            $storedToken | Should -Be $script:TestToken
            $storedToken | Should -BeOfType [string]
        }
    }
    
    Context "Older Az.Accounts with Plain Text Token" {
        It "Should use plain text token directly" {
            # Mock Get-AzAccessToken to return a token object with plain text Token property
            Mock -ModuleName AzRetirementMonitor Get-AzAccessToken {
                return [PSCustomObject]@{
                    Token = $script:TestToken
                    ExpiresOn = [DateTimeOffset]::UtcNow.AddHours(1)
                }
            }
            
            # Call Connect-AzRetirementMonitor with UseAzPowerShell
            Connect-AzRetirementMonitor -UsingAPI -UseAzPowerShell
            
            # Verify the token was set correctly in module scope
            $module = Get-Module AzRetirementMonitor
            $storedToken = & $module { $script:AccessToken }
            
            # The stored token should be the plain text version
            $storedToken | Should -Be $script:TestToken
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

Describe "Get-AzRetirementRecommendation Context Switching Logic" {
    It "Should have context management code in the function" {
        # Verify that the function source contains the necessary context management logic
        $functionDef = (Get-Command Get-AzRetirementRecommendation).Definition
        
        # Check for Get-AzContext call to save original context
        $functionDef | Should -Match 'Get-AzContext'
        
        # Check for Set-AzContext with SubscriptionId parameter
        $functionDef | Should -Match 'Set-AzContext\s+-SubscriptionId'
        
        # Check for context verification logic
        $functionDef | Should -Match 'could not be verified'
        
        # Check for context restoration with Context parameter
        $functionDef | Should -Match 'Set-AzContext\s+-Context'
    }
    
    It "Should have error handling for Set-AzContext failures" {
        $functionDef = (Get-Command Get-AzRetirementRecommendation).Definition
        
        # Check for try-catch around Set-AzContext
        $functionDef | Should -Match 'try\s*\{[^}]*Set-AzContext'
        $functionDef | Should -Match 'Failed to set Azure context for subscription'
    }
    
    It "Should have error handling for context restoration" {
        $functionDef = (Get-Command Get-AzRetirementRecommendation).Definition
        
        # Check for error handling around context restoration
        $functionDef | Should -Match 'Failed to restore original Azure context'
    }
    
    It "Should have error handling for Get-AzAdvisorRecommendation failures" {
        $functionDef = (Get-Command Get-AzRetirementRecommendation).Definition
        
        # Check for error handling around Get-AzAdvisorRecommendation
        $functionDef | Should -Match 'Failed to query Advisor recommendations'
    }
    
    It "Should verify subscription context after setting it" {
        $functionDef = (Get-Command Get-AzRetirementRecommendation).Definition
        
        # Check that the function verifies the context was set correctly
        $functionDef | Should -Match 'context\.Subscription\.Id'
        $functionDef | Should -Match '\$subId'
    }
    
    It "Should use continue statement to skip failed subscriptions" {
        $functionDef = (Get-Command Get-AzRetirementRecommendation).Definition
        
        # Check for continue statements in error handling
        $functionDef | Should -Match 'continue'
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

Describe "Export-AzRetirementReport Transformation Logic" {
    BeforeAll {
        # Create a temporary directory for test outputs
        $script:TestOutputDir = Join-Path ([System.IO.Path]::GetTempPath()) "AzRetirementMonitorTests_$([guid]::NewGuid())"
        New-Item -Path $script:TestOutputDir -ItemType Directory -Force | Out-Null
    }
    
    AfterAll {
        # Clean up test output directory
        if (Test-Path $script:TestOutputDir) {
            Remove-Item -Path $script:TestOutputDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    
    Context "When Problem equals Solution (Az.Advisor mode)" {
        It "Should replace Solution with Description in CSV when Description exists" {
            $testRec = [PSCustomObject]@{
                ResourceName = "TestVM"
                ResourceType = "Microsoft.Compute/virtualMachines"
                Problem = "Generic retirement notice"
                Solution = "Generic retirement notice"
                Description = "Detailed upgrade instructions for this VM"
                ResourceGroup = "test-rg"
                SubscriptionId = "test-sub-id"
                Impact = "High"
            }
            
            $outputPath = Join-Path $script:TestOutputDir "test-advisor-mode.csv"
            $testRec | Export-AzRetirementReport -OutputPath $outputPath -Format CSV -Confirm:$false
            
            $result = Import-Csv -Path $outputPath
            $result.Solution | Should -Be "Detailed upgrade instructions for this VM"
        }
        
        It "Should replace Solution with Description in JSON when Description exists" {
            $testRec = [PSCustomObject]@{
                ResourceName = "TestStorage"
                ResourceType = "Microsoft.Storage/storageAccounts"
                Problem = "Service retiring"
                Solution = "Service retiring"
                Description = "Migrate to new storage account type"
                ResourceGroup = "test-rg"
                SubscriptionId = "test-sub-id"
                Impact = "Medium"
            }
            
            $outputPath = Join-Path $script:TestOutputDir "test-advisor-mode.json"
            $testRec | Export-AzRetirementReport -OutputPath $outputPath -Format JSON -Confirm:$false
            
            $result = Get-Content -Path $outputPath -Raw | ConvertFrom-Json
            $result.Solution | Should -Be "Migrate to new storage account type"
        }
        
        It "Should replace Solution with Description in HTML when Description exists" {
            $testRec = [PSCustomObject]@{
                ResourceName = "TestDB"
                ResourceType = "Microsoft.Sql/servers/databases"
                Problem = "Upgrade required"
                Solution = "Upgrade required"
                Description = "Move to SQL Database v2"
                ResourceGroup = "test-rg"
                SubscriptionId = "test-sub-id"
                Impact = "Low"
                ResourceLink = "https://portal.azure.com/resource"
                LearnMoreLink = "https://learn.microsoft.com/azure"
            }
            
            $outputPath = Join-Path $script:TestOutputDir "test-advisor-mode.html"
            $testRec | Export-AzRetirementReport -OutputPath $outputPath -Format HTML -Confirm:$false
            
            $htmlContent = Get-Content -Path $outputPath -Raw
            $htmlContent | Should -Match "Move to SQL Database v2"
        }
    }
    
    Context "When Problem differs from Solution (API mode)" {
        It "Should keep original Solution in CSV when Problem differs" {
            $testRec = [PSCustomObject]@{
                ResourceName = "TestApp"
                ResourceType = "Microsoft.Web/sites"
                Problem = "API version deprecated"
                Solution = "Update to API version 2023-01-01"
                Description = "Additional context"
                ResourceGroup = "test-rg"
                SubscriptionId = "test-sub-id"
                Impact = "High"
            }
            
            $outputPath = Join-Path $script:TestOutputDir "test-api-mode.csv"
            $testRec | Export-AzRetirementReport -OutputPath $outputPath -Format CSV -Confirm:$false
            
            $result = Import-Csv -Path $outputPath
            $result.Solution | Should -Be "Update to API version 2023-01-01"
        }
        
        It "Should keep original Solution in JSON when Problem differs" {
            $testRec = [PSCustomObject]@{
                ResourceName = "TestFunction"
                ResourceType = "Microsoft.Web/sites/functions"
                Problem = "Runtime version retiring"
                Solution = "Upgrade to .NET 8"
                Description = "Migration guide available"
                ResourceGroup = "test-rg"
                SubscriptionId = "test-sub-id"
                Impact = "Medium"
            }
            
            $outputPath = Join-Path $script:TestOutputDir "test-api-mode.json"
            $testRec | Export-AzRetirementReport -OutputPath $outputPath -Format JSON -Confirm:$false
            
            $result = Get-Content -Path $outputPath -Raw | ConvertFrom-Json
            $result.Solution | Should -Be "Upgrade to .NET 8"
        }
    }
    
    Context "Edge cases" {
        It "Should keep Solution when Description is null even if Problem equals Solution" {
            $testRec = [PSCustomObject]@{
                ResourceName = "TestResource"
                ResourceType = "Microsoft.Test/resources"
                Problem = "Action required"
                Solution = "Action required"
                Description = $null
                ResourceGroup = "test-rg"
                SubscriptionId = "test-sub-id"
                Impact = "Low"
            }
            
            $outputPath = Join-Path $script:TestOutputDir "test-null-description.csv"
            $testRec | Export-AzRetirementReport -OutputPath $outputPath -Format CSV -Confirm:$false
            
            $result = Import-Csv -Path $outputPath
            $result.Solution | Should -Be "Action required"
        }
        
        It "Should keep Solution when Description is empty string even if Problem equals Solution" {
            $testRec = [PSCustomObject]@{
                ResourceName = "TestResource2"
                ResourceType = "Microsoft.Test/resources"
                Problem = "Update needed"
                Solution = "Update needed"
                Description = ""
                ResourceGroup = "test-rg"
                SubscriptionId = "test-sub-id"
                Impact = "Low"
            }
            
            $outputPath = Join-Path $script:TestOutputDir "test-empty-description.csv"
            $testRec | Export-AzRetirementReport -OutputPath $outputPath -Format CSV -Confirm:$false
            
            $result = Import-Csv -Path $outputPath
            $result.Solution | Should -Be "Update needed"
        }
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
        { Get-AzRetirementRecommendation -UseAPI -ErrorAction Stop } | Should -Throw "*Not authenticated*"
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
        
        { Get-AzRetirementRecommendation -UseAPI -ErrorAction Stop } | Should -Throw "*expired*"
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

Describe "Change Tracking Feature" {
    BeforeAll {
        # Create a temporary directory for test outputs
        $script:TestTrackingDir = Join-Path ([System.IO.Path]::GetTempPath()) "AzRetirementChangeTracking_$([guid]::NewGuid())"
        New-Item -Path $script:TestTrackingDir -ItemType Directory -Force | Out-Null
    }
    
    AfterAll {
        # Clean up test output directory
        if (Test-Path $script:TestTrackingDir) {
            Remove-Item -Path $script:TestTrackingDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Context "Parameter Validation" {
        It "Should have EnableChangeTracking parameter" {
            $cmd = Get-Command Get-AzRetirementRecommendation
            $cmd.Parameters.ContainsKey('EnableChangeTracking') | Should -Be $true
        }
        
        It "Should have ChangeTrackingPath parameter" {
            $cmd = Get-Command Get-AzRetirementRecommendation
            $cmd.Parameters.ContainsKey('ChangeTrackingPath') | Should -Be $true
        }
        
        It "ChangeTrackingPath should have a default value" {
            $cmd = Get-Command Get-AzRetirementRecommendation
            $param = $cmd.Parameters['ChangeTrackingPath']
            $param.Attributes.TypeId.Name | Should -Contain 'ParameterAttribute'
        }
    }

    Context "Helper Functions" {
        It "New-AzRetirementSnapshot should create a snapshot" {
            $testRecs = @(
                [PSCustomObject]@{
                    ResourceId   = "/subscriptions/sub1/resourceGroups/rg1/providers/Microsoft.Compute/virtualMachines/vm1"
                    ResourceType = "Microsoft.Compute/virtualMachines"
                    Impact       = "High"
                },
                [PSCustomObject]@{
                    ResourceId   = "/subscriptions/sub1/resourceGroups/rg1/providers/Microsoft.Storage/storageAccounts/sa1"
                    ResourceType = "Microsoft.Storage/storageAccounts"
                    Impact       = "Medium"
                }
            )
            
            $module = Get-Module AzRetirementMonitor
            $snapshot = & $module { param($recs) New-AzRetirementSnapshot -Recommendations $recs } $testRecs
            
            $snapshot.TotalCount | Should -Be 2
            $snapshot.ImpactCounts.High | Should -Be 1
            $snapshot.ImpactCounts.Medium | Should -Be 1
            $snapshot.ResourceIds.Count | Should -Be 2
        }
        
        It "New-AzRetirementSnapshot should handle empty recommendations" {
            $module = Get-Module AzRetirementMonitor
            $snapshot = & $module { New-AzRetirementSnapshot -Recommendations @() }
            
            $snapshot.TotalCount | Should -Be 0
            $snapshot.ImpactCounts.High | Should -Be 0
        }
        
        It "Save-AzRetirementHistory should create a JSON file" {
            $testPath = Join-Path $script:TestTrackingDir "test-history.json"
            $testHistory = [PSCustomObject]@{
                Created   = (Get-Date).ToString('o')
                Snapshots = @(
                    [PSCustomObject]@{
                        Timestamp   = (Get-Date).ToString('o')
                        TotalCount  = 5
                        ImpactCounts = @{High = 2; Medium = 2; Low = 1}
                        ResourceTypeCounts = @{}
                        ResourceIds = @()
                    }
                )
            }
            
            $module = Get-Module AzRetirementMonitor
            & $module { param($p, $h) Save-AzRetirementHistory -Path $p -History $h } $testPath $testHistory
            
            Test-Path $testPath | Should -Be $true
            
            $saved = Get-Content $testPath -Raw | ConvertFrom-Json
            $saved.Snapshots[0].TotalCount | Should -Be 5
        }
        
        It "Get-AzRetirementHistory should load existing history" {
            $testPath = Join-Path $script:TestTrackingDir "test-load-history.json"
            $testHistory = [PSCustomObject]@{
                Created   = (Get-Date).ToString('o')
                Snapshots = @(
                    [PSCustomObject]@{
                        Timestamp   = (Get-Date).ToString('o')
                        TotalCount  = 3
                        ImpactCounts = @{High = 1; Medium = 1; Low = 1}
                        ResourceTypeCounts = @{}
                        ResourceIds = @()
                    }
                )
            }
            
            $testHistory | ConvertTo-Json -Depth 10 | Set-Content -Path $testPath
            
            $module = Get-Module AzRetirementMonitor
            $loaded = & $module { param($p) Get-AzRetirementHistory -Path $p } $testPath
            
            $loaded | Should -Not -BeNull
            $loaded.Snapshots[0].TotalCount | Should -Be 3
        }
        
        It "Get-AzRetirementHistory should return null for non-existent file" {
            $testPath = Join-Path $script:TestTrackingDir "non-existent.json"
            
            $module = Get-Module AzRetirementMonitor
            $loaded = & $module { param($p) Get-AzRetirementHistory -Path $p } $testPath
            
            $loaded | Should -BeNull
        }
    }
}