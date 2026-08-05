# AzRetirementMonitor Agent Guidance

This repository contains a PowerShell module for monitoring Azure retirement recommendations.

## Validation

Run:

Invoke-Pester ./Tests/AzRetirementMonitor.Tests.ps1

## Contribution rules

- Preserve PowerShell 5.1 and PowerShell 7+ compatibility.
- Follow approved PowerShell verbs.
- Do not require live Azure authentication for tests.
- Mock Azure API and Az module calls.
- Read SECURITY.md before discussing vulnerability reports.
- Do not expose credentials, tokens, subscription IDs, or customer data.
- Keep comments concise and actionable.