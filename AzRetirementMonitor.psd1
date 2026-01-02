@{
    RootModule           = 'AzRetirementMonitor.psm1'
    ModuleVersion        = '1.0.0'
    PowerShellVersion    = '7.0'
    CompatiblePSEditions = @('Core')

    FunctionsToExport    = @(
        'Connect-AzRetirementMonitor',
        'Get-AzRetirementRecommendations',
        'Get-AzRetirementMetadata',
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