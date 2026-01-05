@{
    RootModule           = 'AzRetirementMonitor.psm1'
    ModuleVersion        = '1.2.0'
    GUID                 = '6775bae9-a3ec-43de-abd9-14308dd345c4'
    Author               = 'Corey Callaway'
    CompanyName          = 'Independent'
    Description          = 'A PowerShell module for identifying and monitoring Azure service retirements and deprecation notices of Azure services in your subscriptions.'
    PowerShellVersion    = '7.0'
    CompatiblePSEditions = @('Core')

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
        }
    }
}