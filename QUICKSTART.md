# AzRetirementMonitor v3.0 - Quick Start Guide

**Compatible with PowerShell 5.1+ (Desktop and Core)**

## Quick Start (Recommended Method)

```powershell
# Step 1: Install required modules
Install-Module -Name Az.Advisor, Az.Accounts -Scope CurrentUser

# Step 2: Connect to Azure
Connect-AzAccount

# Step 3: Get retirement recommendations
Get-AzRetirementRecommendation

# Step 4: Export to HTML report
Get-AzRetirementRecommendation | Export-AzRetirementReport -OutputPath "report.html" -Format HTML
```

## Alternative Method (REST API)

```powershell
# Step 1: Log in to Azure CLI
az login

# Step 2: Connect module for API access
Connect-AzRetirementMonitor -UsingAPI

# Step 3: Get retirement recommendations via API
Get-AzRetirementRecommendation -UseAPI

# Step 4: Export to CSV report
Get-AzRetirementRecommendation -UseAPI | Export-AzRetirementReport -OutputPath "report.csv" -Format CSV

# Step 5: Disconnect when done
Disconnect-AzRetirementMonitor
```

## What's New in v3.0?

### 📊 Change Tracking

Track your progress in resolving retirement recommendations over time:

- **`-EnableChangeTracking`** — saves a snapshot on each run and compares it to the previous one
- **`-ChangeTrackingPath`** — use a custom history file path instead of the default
- Console output shows total count deltas, impact-level changes, and new/resolved resources

See the **Track Changes Over Time** section above for usage examples.

## What Changed in v2.0?

### ✅ Default Method (NEW)

- Uses **Az.Advisor PowerShell module**
- Full parity with Azure Portal
- No need for `Connect-AzRetirementMonitor`
- Just run `Connect-AzAccount` and go!

### ⚙️ API Method (Still Available)

- Uses **REST API** directly
- Requires `Connect-AzRetirementMonitor -UsingAPI`
- Use `-UseAPI` switch on `Get-AzRetirementRecommendation`

## Common Commands

### Get All Recommendations

```powershell
# Default method
Get-AzRetirementRecommendation

# API method
Get-AzRetirementRecommendation -UseAPI
```

### Get Recommendations for Specific Subscriptions

```powershell
Get-AzRetirementRecommendation -SubscriptionId "12345678-1234-1234-1234-123456789012"
```

### Export to Different Formats

```powershell
# CSV
Get-AzRetirementRecommendation | Export-AzRetirementReport -OutputPath "report.csv" -Format CSV

# JSON
Get-AzRetirementRecommendation | Export-AzRetirementReport -OutputPath "report.json" -Format JSON

# HTML
Get-AzRetirementRecommendation | Export-AzRetirementReport -OutputPath "report.html" -Format HTML
```

## Track Changes Over Time

Use change tracking to monitor your progress in resolving retirement recommendations:

```powershell
# First run — establishes the baseline
Get-AzRetirementRecommendation -EnableChangeTracking

# Subsequent runs — shows what has been resolved and what is new
Get-AzRetirementRecommendation -EnableChangeTracking

# Use a custom history file path
Get-AzRetirementRecommendation -EnableChangeTracking -ChangeTrackingPath "C:\Reports\retirement-history.json"
```

The history file is updated automatically on each run. The console output shows:

- Total recommendation count with delta from the previous run
- Per-impact-level counts (High / Medium / Low) with deltas
- Newly appeared resource IDs
- Resource IDs that have been resolved since the last run

## Troubleshooting

### "Az.Advisor module not available or not connected"

**Solution**: Install the module and connect to Azure

```powershell
Install-Module -Name Az.Advisor -Scope CurrentUser
Connect-AzAccount
```

### "Not authenticated. Run Connect-AzRetirementMonitor -UsingAPI first"

**Solution**: You're trying to use API mode. Either:

1. Remove `-UseAPI` to use default method, OR
2. Run `Connect-AzRetirementMonitor -UsingAPI` first

### "Connect-AzRetirementMonitor requires -UsingAPI parameter"

**Solution**: This is expected! For default method, you don't need `Connect-AzRetirementMonitor`.

```powershell
# For default method (recommended)
Connect-AzAccount  # NOT Connect-AzRetirementMonitor

# For API method only
Connect-AzRetirementMonitor -UsingAPI
```

## Migration from v1.x

**Old workflow:**

```powershell
Connect-AzRetirementMonitor
Get-AzRetirementRecommendation
```

**New workflow (recommended):**

```powershell
Connect-AzAccount
Get-AzRetirementRecommendation
```

**New workflow (API method):**

```powershell
Connect-AzRetirementMonitor -UsingAPI
Get-AzRetirementRecommendation -UseAPI
```
