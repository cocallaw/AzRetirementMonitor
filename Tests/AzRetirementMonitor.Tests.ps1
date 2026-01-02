BeforeAll {
    Import-Module "$PSScriptRoot/../AzRetirementMonitor.psd1" -Force
}

Describe "Module Import" {
    It "Should load the module" {
        Get-Module AzRetirementMonitor | Should -Not -BeNull
    }
    
    It "Should export 4 functions" {
        $commands = Get-Command -Module AzRetirementMonitor
        $commands.Count | Should -Be 4
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
            
            # Create payload with specified expiration using ConvertTo-Json
            $payloadObj = @{exp = $ExpirationUnixTime}
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
        # Create a token that expires in the future (January 1, 2030)
        $futureTime = [DateTimeOffset]::new(2030, 1, 1, 0, 0, 0, [TimeSpan]::Zero).ToUnixTimeSeconds()
        $validToken = New-TestToken -ExpirationUnixTime $futureTime
        
        # Access the module's script scope to set the token and test it
        $module = Get-Module AzRetirementMonitor
        & $module { param($token) $script:AccessToken = $token } $validToken
        
        # Call the private Test function to verify the token is valid
        $testResult = & $module { Test-AzRetirementMonitorToken }
        $testResult | Should -Be $true
    }
}