# AzRetirementMonitor

A PowerShell module for monitoring Azure service retirements and deprecation notices using Azure Advisor recommendations.

## What Problem Does This Solve?

Azure services evolve constantly, with features, APIs, and entire services being retired or deprecated over time. Missing these retirement notifications can lead to:

- **Service disruptions** when deprecated features stop working
- **Security vulnerabilities** from running unsupported services
- **Compliance issues** when regulations require supported infrastructure
- **Unexpected costs** from forced migrations under time pressure

**AzRetirementMonitor** helps you proactively identify Azure resources affected by upcoming retirements by querying Azure Advisor for service upgrade and retirement recommendations across all your subscriptions. This gives you time to plan migrations and upgrades before services are discontinued.

## How Do I Install It?

### From PowerShell Gallery (Recommended)

```powershell
Install-Module -Name AzRetirementMonitor -Scope CurrentUser
```

### Manual Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/cocallaw/AzRetirementMonitor.git
   ```

2. Import the module:
   ```powershell
   Import-Module ./AzRetirementMonitor/AzRetirementMonitor.psd1
   ```

### Prerequisites

- **PowerShell 7.0 or later**
- **Authentication method** (one of the following):
  - Azure CLI (`az`) - Default and recommended
  - Az.Accounts PowerShell module

## How Do I Authenticate?

AzRetirementMonitor supports two authentication methods:

### Option 1: Azure CLI (Default)

1. Install the [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli)
2. Log in to Azure:
   ```bash
   az login
   ```
3. Connect the module:
   ```powershell
   Connect-AzRetirementMonitor
   ```

### Option 2: Az PowerShell Module

1. Install Az.Accounts:
   ```powershell
   Install-Module -Name Az.Accounts -Scope CurrentUser
   ```
2. Connect to Azure:
   ```powershell
   Connect-AzAccount
   ```
3. Connect the module using Az PowerShell:
   ```powershell
   Connect-AzRetirementMonitor -UseAzPowerShell
   ```

## What Commands Are Available?

### Connect-AzRetirementMonitor

Authenticates to Azure and obtains an access token for subsequent API calls.

```powershell
# Using Azure CLI (default)
Connect-AzRetirementMonitor

# Using Az PowerShell module
Connect-AzRetirementMonitor -UseAzPowerShell
```

### Get-AzRetirementRecommendation

Retrieves Azure Advisor recommendations related to service retirements and deprecations. This function specifically returns only HighAvailability category recommendations with ServiceUpgradeAndRetirement subcategory.

```powershell
# Get all retirement recommendations across all subscriptions
Get-AzRetirementRecommendation

# Get recommendations for specific subscriptions
Get-AzRetirementRecommendation -SubscriptionId "sub-id-1", "sub-id-2"
```

**Parameters:**
- `SubscriptionId` - One or more subscription IDs (defaults to all subscriptions)

**Note:** This function is hardcoded to return only recommendations where Category is 'HighAvailability' and SubCategory is 'ServiceUpgradeAndRetirement'.

### Get-AzRetirementMetadataItem

Retrieves metadata about retirement recommendation types from Azure Advisor, filtered for HighAvailability category and ServiceUpgradeAndRetirement subcategory.

```powershell
Get-AzRetirementMetadataItem
```

### Export-AzRetirementReport

Exports retirement recommendations to various formats for reporting and analysis.

```powershell
# Export to CSV
Get-AzRetirementRecommendation | Export-AzRetirementReport -OutputPath "report.csv" -Format CSV

# Export to JSON
Get-AzRetirementRecommendation | Export-AzRetirementReport -OutputPath "report.json" -Format JSON

# Export to HTML
Get-AzRetirementRecommendation | Export-AzRetirementReport -OutputPath "report.html" -Format HTML
```

**Parameters:**
- `Recommendations` - Recommendation objects from Get-AzRetirementRecommendation (accepts pipeline input)
- `OutputPath` - File path for the exported report
- `Format` - Export format: CSV, JSON, or HTML (default: CSV)

## Example Output

### Get-AzRetirementRecommendation

```powershell
PS> Connect-AzRetirementMonitor
Authenticated to Azure successfully

PS> Get-AzRetirementRecommendation

SubscriptionId   : 12345678-1234-1234-1234-123456789012
ResourceId       : /subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/myRG/providers/Microsoft.Compute/virtualMachines/myVM
ResourceName     : myVM
Category         : HighAvailability
Impact           : High
Problem          : Virtual machine is using a retiring VM size
Solution         : Migrate to a supported VM size before the retirement date
Description      : Basic A-series VM sizes will be retired on August 31, 2024
LastUpdated      : 2024-01-15T10:30:00Z
IsRetirement     : True
RecommendationId : abc123-def456-ghi789
LearnMoreLink    : https://learn.microsoft.com/azure/virtual-machines/sizes-previous-gen
```

### Export-AzRetirementReport

```powershell
PS> Get-AzRetirementRecommendation | Export-AzRetirementReport -OutputPath "./retirement-report.html" -Format HTML
```

This creates an HTML report with all retirement recommendations, including resource details, impact levels, and actionable solutions.

## Usage Workflow

Here's a typical workflow for monitoring Azure retirements:

```powershell
# 1. Authenticate
Connect-AzRetirementMonitor

# 2. Get retirement recommendations
$recommendations = Get-AzRetirementRecommendation

# 3. Review the recommendations
$recommendations | Format-Table ResourceName, Impact, Problem, Solution

# 4. Export for team review
$recommendations | Export-AzRetirementReport -OutputPath "retirement-report.csv" -Format CSV

# 5. Get metadata about retirement types (optional)
Get-AzRetirementMetadataItem
```

## Contributing Guidelines

We welcome contributions to AzRetirementMonitor! Here's how you can help:

### Reporting Issues

- Use the GitHub issue tracker to report bugs or request features
- Provide clear reproduction steps for bugs
- Include PowerShell version, OS, and authentication method used

### Pull Requests

1. **Fork the repository** and create a feature branch
2. **Follow existing code style** - use the same patterns as existing functions
3. **Add tests** for new functionality in the `Tests/` directory
4. **Update documentation** if you change functionality
5. **Keep changes focused** - one feature or fix per PR
6. **Test your changes** with both authentication methods (Azure CLI and Az.Accounts)

### Code Style

- Use approved PowerShell verbs (Get, Set, New, Remove, etc.)
- Include comment-based help for all public functions
- Use proper parameter validation
- Write verbose messages for troubleshooting
- Handle errors gracefully

### Testing

Run the Pester tests before submitting:

```powershell
# Install Pester if needed
Install-Module -Name Pester -Force -SkipPublisherCheck

# Run tests
Invoke-Pester ./Tests/AzRetirementMonitor.Tests.ps1
```

### Development Setup

1. Clone the repository
2. Make your changes in a feature branch
3. Test locally by importing the module:
   ```powershell
   Import-Module ./AzRetirementMonitor.psd1 -Force
   ```
4. Run tests and ensure they pass
5. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- **Issues**: [GitHub Issues](https://github.com/cocallaw/AzRetirementMonitor/issues)
- **Discussions**: [GitHub Discussions](https://github.com/cocallaw/AzRetirementMonitor/discussions)

## Acknowledgments

This module uses the Azure Advisor API to retrieve retirement recommendations. For more information about Azure Advisor, visit the [Azure Advisor documentation](https://learn.microsoft.com/azure/advisor/).
