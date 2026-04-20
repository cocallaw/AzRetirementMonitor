# Security Policy

## Supported Versions

Only the latest published release of AzRetirementMonitor on the [PowerShell Gallery](https://www.powershellgallery.com/packages/AzRetirementMonitor) receives security fixes. Please upgrade to the latest version before reporting a vulnerability.

| Version | Supported |
| ------- | --------- |
| Latest  | ✅        |
| Older   | ❌        |

## Reporting a Vulnerability

**Please do not report security vulnerabilities through public GitHub issues.**

To report a vulnerability, use one of the following private disclosure channels:

1. **GitHub Security Advisories (preferred)** — open a [private security advisory](https://github.com/cocallaw/AzRetirementMonitor/security/advisories/new) directly in this repository. This keeps the report confidential until a fix is available.

2. **Email** — if you are unable to use GitHub Security Advisories, you may contact the maintainer privately through the contact information listed on the [GitHub profile](https://github.com/cocallaw).

### What to Include

Please provide as much of the following as possible to help us understand and reproduce the issue:

- A description of the vulnerability and its potential impact
- The affected version(s)
- Steps to reproduce or a proof-of-concept
- Any suggested mitigations or fixes you have already identified

### Response Timeline

| Milestone                          | Target        |
| ---------------------------------- | ------------- |
| Acknowledgment of your report      | Within 5 business days  |
| Confirmation of vulnerability      | Within 10 business days |
| Release of patch / advisory        | Within 30 days of confirmation (may vary with complexity) |

We will keep you informed throughout the process. If you do not receive an acknowledgment within the timeframe above, please follow up.

## Disclosure Policy

We follow **coordinated (responsible) disclosure**:

1. The vulnerability is reported privately.
2. We investigate, develop a fix, and prepare a new release.
3. A [GitHub Security Advisory](https://github.com/cocallaw/AzRetirementMonitor/security/advisories) is published after the fix is released.

We kindly ask reporters not to publicly disclose a vulnerability until a fix has been released or 90 days have passed since the initial report, whichever comes first.

## Scope

This security policy covers the PowerShell source code in this repository. It does **not** cover:

- Third-party dependencies (Az.Accounts, Az.Advisor, Azure Advisor REST API) — report those to Microsoft.
- Infrastructure or deployment environments operated by individual users.

## Token Storage Considerations

When using API mode (`Connect-AzRetirementMonitor -UsingAPI`), the access token is stored as a module-scoped variable for the duration of the session. Be aware of the following:

- **Module scope is not a security boundary.** Any code running in the same PowerShell session can access module-scoped variables via `& (Get-Module ModuleName) { $script:Variable }`. Do not run untrusted scripts alongside this module when authenticated.
- **Token lifetime.** The token is a short-lived Azure access token (typically 60–90 minutes). It is scoped to `https://management.azure.com` with read-only permissions.
- **Clearing the token.** `Disconnect-AzRetirementMonitor` sets the variable to `$null`, but the string may remain in managed memory until garbage collected. PowerShell does not offer deterministic memory clearing for strings.
- **Best practice.** Run `Disconnect-AzRetirementMonitor` when finished, and prefer isolated sessions or dedicated automation accounts for sensitive environments.
