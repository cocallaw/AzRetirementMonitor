# Module-scoped access token storage
# Security Note: The access token is stored in plain text in memory as a module-scoped variable.
# This is acceptable because:
# 1. These are short-lived session tokens (typically 1 hour), not long-lived credentials
# 2. The token is only accessible within this module's scope, not from other modules
# 3. The token is cleared when the module is unloaded or via Disconnect-AzRetirementMonitor
# 4. PowerShell doesn't provide secure string protection for in-memory session tokens
# 5. The token expires automatically based on Azure's token lifetime policies
$script:AccessToken = $null
$script:ApiVersion  = "2025-01-01"

$Public  = Get-ChildItem "$PSScriptRoot/Public/*.ps1" -Recurse
$Private = Get-ChildItem "$PSScriptRoot/Private/*.ps1" -Recurse

foreach ($file in @($Public + $Private)) {
    . $file.FullName
}

Export-ModuleMember -Function $Public.BaseName