@{
    RootModule           = 'AzRetirementMonitor.psm1'
    ModuleVersion        = '2.0.0'
    GUID                 = '6775bae9-a3ec-43de-abd9-14308dd345c4'
    Author               = 'Corey Callaway'
    CompanyName          = 'Independent'
    Description          = 'A PowerShell module for identifying and monitoring Azure service retirements and deprecation notices of Azure services in your subscriptions.'
    PowerShellVersion    = '5.1'
    CompatiblePSEditions = @('Core', 'Desktop')

    FunctionsToExport    = @(
        'Connect-AzRetirementMonitor',
        'Disconnect-AzRetirementMonitor',
        'Get-AzRetirementRecommendation',
        'Get-AzRetirementMetadataItem',
        'Export-AzRetirementReport'
    )

    PrivateData          = @{
        PSData = @{
            Tags       = @('Azure', 'Advisor', 'Retirement', 'Monitoring')
            LicenseUri = 'https://github.com/cocallaw/AzRetirementMonitor/blob/main/LICENSE'
            ProjectUri = 'https://github.com/cocallaw/AzRetirementMonitor'
            ReleaseNotes = @'
## Version 2.0.0 - Breaking Changes
- **Default behavior changed**: Now uses Az.Advisor PowerShell module by default instead of REST API
- **Connect-AzRetirementMonitor** now requires -UsingAPI switch and is only needed for API mode
- For default usage: Install Az.Advisor, run Connect-AzAccount, then Get-AzRetirementRecommendation
- For API usage: Run Connect-AzRetirementMonitor -UsingAPI, then Get-AzRetirementRecommendation -UseAPI
- Az.Advisor module is now recommended (checked at runtime)
- Provides full parity with Azure Advisor recommendations
- **PowerShell compatibility**: Now supports both PowerShell Core (7+) and Desktop (5.1)
'@
        }
    }
}