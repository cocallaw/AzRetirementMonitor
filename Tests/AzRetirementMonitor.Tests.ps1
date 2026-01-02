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
}

Describe "Connect-AzRetirementMonitor" {
    It "Should have UseAzCLI parameter set as default" {
        $cmd = Get-Command Connect-AzRetirementMonitor
        $cmd.ParameterSets[0].Name | Should -Be 'AzCLI'
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
}