@{
    RootModule           = 'AzRetirementMonitor.psm1'
    ModuleVersion        = '3.0.0'
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
## Version 3.0.0
- Adds `-Stream` for low-memory, pipeline-first recommendation retrieval.
- Adds retry with exponential backoff for transient Azure Resource Manager throttling.
- Validates pagination links before following them to prevent token forwarding to untrusted hosts.
- Stores API tokens as `SecureString` values in module scope and clears them on disconnect.
- Caches parsed Advisor extended properties during recommendation filtering.
- Adds output path validation and preserves CSV formula-injection and HTML/XSS protections.
'@
        }
    }
}