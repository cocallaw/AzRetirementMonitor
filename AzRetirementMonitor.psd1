@{
    RootModule           = 'AzRetirementMonitor.psm1'
    ModuleVersion        = '3.0.1'
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
## Version 3.0.1
- Fixes Az.Advisor retirement recommendation filtering when extended properties are exposed through `AdditionalProperties`.
- Preserves support for JSON strings, dictionaries, materialized objects, and cached extended properties.
'@
        }
    }
}