# Security Policy

## Supported Versions

| Version | Supported          |
|---------|--------------------|
| 2.x     | ✅ Yes             |
| 1.x     | ❌ No              |

## Reporting a Vulnerability

If you discover a security vulnerability in AzRetirementMonitor, **please do not open a public issue**.

Instead, please report it through one of these channels:

1. **GitHub Security Advisories** (preferred): [Report a vulnerability](https://github.com/cocallaw/AzRetirementMonitor/security/advisories/new)
2. **Email**: Contact the maintainer directly through their [GitHub profile](https://github.com/cocallaw)

### What to Include

- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

### What to Expect

- **Acknowledgment** within 7 days of your report
- **Status update** within 30 days with an assessment and remediation plan
- **Credit** in the fix release (unless you prefer to remain anonymous)

## Security Scope

This module interacts with Azure through:

- **Az.Advisor PowerShell module** (default method) — authentication managed by Az.Accounts
- **Azure Resource Manager REST API** (API method) — uses short-lived, read-only access tokens scoped to `https://management.azure.com`

The module performs **read-only operations only**. It cannot create, modify, or delete Azure resources.

### Token Handling

When using API mode, the module stores an access token in a module-scoped variable for the duration of the PowerShell session. The token:

- Is scoped to Azure Resource Manager read operations
- Expires automatically based on Azure token lifetime policies
- Can be manually cleared with `Disconnect-AzRetirementMonitor`
- Is cleared when the module is unloaded
