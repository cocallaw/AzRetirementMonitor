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