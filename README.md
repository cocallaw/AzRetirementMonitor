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

## How Does Authentication and Token Management Work?

### Security Model

AzRetirementMonitor uses a **read-only, scoped token** approach to ensure security and isolation:

1. **Token Acquisition**: The module obtains a time-limited access token from your existing Azure authentication:
   - **Azure CLI**: Uses `az account get-access-token` to request a token from your logged-in session
   - **Az.Accounts**: Uses `Get-AzAccessToken` to request a token from your connected context
   
2. **Token Storage**: The token is stored in a **module-scoped variable** (`$script:AccessToken`):
   - Only accessible within the AzRetirementMonitor module
   - Not accessible to other PowerShell modules or sessions
   - Automatically cleared when the module is unloaded
   - Can be manually cleared with `Disconnect-AzRetirementMonitor`

3. **Token Scope**: The token is requested specifically for `https://management.azure.com`:
   - Only grants access to Azure Resource Manager APIs
   - Used exclusively for **read-only** operations (Azure Advisor recommendations)
   - Cannot be used to modify Azure resources
   - The module validates the token's audience claim to ensure it's properly scoped
   - Tokens scoped to other resources (e.g., Microsoft Graph) are rejected

**Note**: Azure does not provide resource-specific OAuth scopes for individual Azure Resource Manager APIs (like Azure Advisor). All ARM API calls use the same token scope (`https://management.azure.com`). However, actual permissions are controlled by Azure RBAC role assignments, allowing you to limit what the authenticated user can access. See the "Security Best Practices" section below for guidance on implementing least privilege access.

4. **Module Isolation**: The module's authentication is completely isolated:
   - `Connect-AzRetirementMonitor` **does not** authenticate you to Azure (you must already be logged in)
   - `Connect-AzRetirementMonitor` **only** requests an access token from your existing session
   - `Disconnect-AzRetirementMonitor` **only** clears the module's stored token
   - `Disconnect-AzRetirementMonitor` **does not** affect your Azure CLI or Az.Accounts session
   - You remain logged in to Azure CLI (`az login`) or Az.Accounts (`Connect-AzAccount`) after disconnecting

### Token Lifecycle

```powershell
# You authenticate to Azure first (outside the module)
az login  # or Connect-AzAccount

# Module requests a token from your session (does not re-authenticate)
Connect-AzRetirementMonitor

# Module uses the token for API calls
Get-AzRetirementRecommendation

# Module clears its token (you remain logged in to Azure)
Disconnect-AzRetirementMonitor

# You can still use Azure CLI/PowerShell
az account show  # Still works - you're still logged in
```

### Security Best Practices

To implement the principle of least privilege when using AzRetirementMonitor:

#### 1. Required Azure RBAC Permissions

The module only requires **read-only** permissions. The minimum RBAC permissions needed are:

- `Microsoft.Advisor/recommendations/read` - Read Azure Advisor recommendations
- `Microsoft.Advisor/metadata/read` - Read Azure Advisor metadata
- `Microsoft.Resources/subscriptions/read` - List subscriptions (only if querying all subscriptions)

#### 2. Recommended RBAC Role Assignment

Assign the built-in **Reader** role at the minimum necessary scope:

```bash
# Option 1: Subscription scope (recommended for most scenarios)
az role assignment create \
  --assignee user@example.com \
  --role Reader \
  --scope /subscriptions/{subscription-id}

# Option 2: Resource Group scope (most restrictive)
az role assignment create \
  --assignee user@example.com \
  --role Reader \
  --scope /subscriptions/{subscription-id}/resourceGroups/{resource-group-name}
```

**Why Reader role?** The Reader role provides the minimum permissions needed to view Azure Advisor recommendations without granting any write, modify, or delete capabilities.

#### 3. Using a Custom RBAC Role (Advanced)

For maximum restriction, create a custom role with only the exact permissions needed:

```bash
# Create custom role definition
az role definition create --role-definition '{
  "Name": "Azure Advisor Reader",
  "Description": "Can read Azure Advisor recommendations only",
  "Actions": [
    "Microsoft.Advisor/recommendations/read",
    "Microsoft.Advisor/metadata/read",
    "Microsoft.Resources/subscriptions/read"
  ],
  "NotActions": [],
  "AssignableScopes": [
    "/subscriptions/{subscription-id}"
  ]
}'

# Assign the custom role
az role assignment create \
  --assignee user@example.com \
  --role "Azure Advisor Reader" \
  --scope /subscriptions/{subscription-id}
```

#### 4. Token Scope Limitations

**Important**: While the OAuth token is scoped to `https://management.azure.com` (which covers all Azure Resource Manager APIs), the actual operations the module can perform are limited by:

1. **RBAC Permissions**: Azure evaluates every API call against the user's assigned RBAC roles
2. **Module Design**: The module only makes read-only calls to Azure Advisor endpoints
3. **Token Validation**: The module validates that tokens have the correct audience claim

Even though the token technically grants access to the entire Azure Resource Manager API, if you assign only the Reader role (or the custom role above), the authenticated user cannot:
- Modify or delete resources
- Create new resources  
- Access APIs outside their assigned RBAC permissions
- Dismiss or postpone Advisor recommendations (requires Contributor role)

This defense-in-depth approach ensures security even if the token were somehow used outside the module.

#### 5. Additional Security Recommendations

- **Use service principals** for automation scenarios instead of user accounts
- **Enable conditional access policies** to restrict where authentication can occur
- **Regularly review role assignments** to ensure least privilege is maintained
- **Use managed identities** when running on Azure compute resources
- **Monitor audit logs** for unexpected API calls using Azure Monitor


### What the Module Cannot Do

For security and transparency, the module is designed with strict limitations:

- ❌ Cannot authenticate you to Azure (requires existing `az login` or `Connect-AzAccount`)
- ❌ Cannot modify, create, or delete Azure resources (only uses read-only API operations)
- ❌ Cannot access tokens or credentials from other modules
- ❌ Cannot persist tokens beyond the PowerShell session
- ❌ Cannot disconnect you from Azure CLI or Az.Accounts
- ❌ Cannot accept tokens scoped to resources other than Azure Resource Manager
- ✅ Can only read Azure Advisor recommendations and metadata for retirement planning
- ✅ Validates token audience to ensure proper scoping to `https://management.azure.com`

**Security Note**: While the OAuth token is scoped to the entire Azure Resource Manager API (`https://management.azure.com`), actual access is controlled by Azure RBAC. Assigning the Reader role (or a custom role with only Advisor read permissions) ensures the authenticated user cannot perform any write operations, even if they tried to use the token outside this module.

## What Commands Are Available?

### Connect-AzRetirementMonitor

Authenticates to Azure and obtains an access token for subsequent API calls.

```powershell
# Using Azure CLI (default)
Connect-AzRetirementMonitor

# Using Az PowerShell module
Connect-AzRetirementMonitor -UseAzPowerShell
```

### Disconnect-AzRetirementMonitor

Clears the access token stored by the module. This does not affect your Azure CLI or Az.Accounts session.

```powershell
# Disconnect from AzRetirementMonitor
Disconnect-AzRetirementMonitor
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

## Understanding Impact Levels

Azure Advisor assigns an impact level (High, Medium, or Low) to each recommendation to help you prioritize actions:

- **High Impact**: Recommendations that can have the greatest positive effect on your environment, such as preventing service disruptions, avoiding security vulnerabilities, or addressing critical retirements. These should be addressed with highest priority.

- **Medium Impact**: Meaningful improvements with moderate effect. These recommendations are important but may have more flexible timelines than high-impact items.

- **Low Impact**: Beneficial optimizations with minor improvements. These are lower priority but still worth addressing when resources allow.

Impact levels are determined by Azure Advisor based on factors including potential business impact, risk severity, resource usage patterns, and the scope of affected resources. For retirement recommendations specifically, the impact level reflects the urgency and criticality of migrating away from deprecated services.

For more information, see [Azure Advisor documentation](https://learn.microsoft.com/azure/advisor/advisor-overview).

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

# 6. Disconnect when finished (optional)
Disconnect-AzRetirementMonitor
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

This module uses the Azure Advisor API to retrieve retirement recommendations. For more information about Azure Advisor, visit the [Azure Advisor documentation](https://learn.microsoft.com/azure/advisor/).
