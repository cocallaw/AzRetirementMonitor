function Test-AzAdvisorSession {
    <#
    .SYNOPSIS
    Tests if Az.Advisor module is available and an Azure PowerShell session is active
    .DESCRIPTION
    Validates that:
    1. Az.Advisor module is installed and can be imported
    2. An active Azure PowerShell context exists (user is connected via Connect-AzAccount)
    
    Returns $true if both conditions are met, $false otherwise.
    Writes informative verbose messages to help troubleshoot connection issues.
    .OUTPUTS
    System.Boolean
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    # Check if Az.Advisor module is available
    if (-not (Get-Module -ListAvailable -Name Az.Advisor)) {
        Write-Verbose "Az.Advisor module is not installed. Install it with: Install-Module -Name Az.Advisor"
        return $false
    }

    # Try to import the module
    try {
        Import-Module Az.Advisor -ErrorAction Stop
        Write-Verbose "Az.Advisor module loaded successfully"
    }
    catch {
        Write-Verbose "Failed to import Az.Advisor module: $_"
        return $false
    }

    # Check if there's an active Azure PowerShell context
    try {
        $context = Get-AzContext -ErrorAction Stop
        
        if (-not $context) {
            Write-Verbose "No active Azure PowerShell context. Run Connect-AzAccount first."
            return $false
        }

        Write-Verbose "Active Azure context found: $($context.Account.Id) in subscription $($context.Subscription.Name)"
        return $true
    }
    catch {
        Write-Verbose "Failed to get Azure context: $_"
        Write-Verbose "Run Connect-AzAccount to establish an Azure PowerShell session"
        return $false
    }
}
