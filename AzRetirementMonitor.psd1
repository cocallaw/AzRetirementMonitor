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
## Version 3.0.0 - Change Tracking
- **New**: `-EnableChangeTracking` parameter on `Get-AzRetirementRecommendation` to monitor progress over time
- **New**: `-ChangeTrackingPath` parameter to specify a custom history file location (defaults to `AzRetirementMonitor-History.json` in the current directory)
- Snapshots of each run are stored in a JSON history file
- Console output shows comparison with the previous run: total count, impact-level deltas, new and resolved resources
- PowerShell 5.1 compatibility for JSON snapshot deserialization

## Version 2.0.0 - Breaking Changes
- Default behavior changed: Now uses Az.Advisor PowerShell module by default instead of REST API
- Connect-AzRetirementMonitor now requires -UsingAPI switch and is only needed for API mode
- PowerShell compatibility: Supports both PowerShell Core (7+) and Desktop (5.1)
'@
        }
    }
}