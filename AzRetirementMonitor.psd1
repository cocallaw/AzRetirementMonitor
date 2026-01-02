@{
    RootModule           = 'AzRetirementMonitor.psm1'
    ModuleVersion        = '1.0.0'
    GUID                 = '6775bae9-a3ec-43de-abd9-14308dd345c4'
    Author               = 'Corey Callaway'
    CompanyName          = 'Independent'
    Description          = 'A PowerShell module for monitoring Azure service retirements and deprecation notices using Azure Advisor recommendations. Proactively identifies resources affected by upcoming retirements for HighAvailability category and ServiceUpgradeAndRetirement subcategory.'
    PowerShellVersion    = '7.0'
    CompatiblePSEditions = @('Core')

    FunctionsToExport    = @(
        'Connect-AzRetirementMonitor',
        'Get-AzRetirementRecommendation',
        'Get-AzRetirementMetadataItem',
        'Export-AzRetirementReport'
    )

    PrivateData          = @{
        PSData = @{
            Tags       = @('Azure', 'Advisor', 'Retirement', 'Monitoring')
            LicenseUri = 'https://opensource.org/licenses/MIT'
            ProjectUri = 'https://github.com/cocallaw/AzRetirementMonitor'
        }
    }
}