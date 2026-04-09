# Contributing to AzRetirementMonitor

Thank you for your interest in contributing to AzRetirementMonitor! This document outlines the process for reporting issues, submitting pull requests, and maintaining code quality.

## Table of Contents

- [Development Setup](#development-setup)
- [Code Style](#code-style)
- [Testing](#testing)
- [Pull Request Process](#pull-request-process)
- [Reporting Issues](#reporting-issues)

## Development Setup

1. **Fork and clone** the repository:

   ```powershell
   git clone https://github.com/<your-username>/AzRetirementMonitor.git
   cd AzRetirementMonitor
   ```

2. **Create a feature branch** from `main`:

   ```powershell
   git checkout -b feature/my-improvement
   ```

3. **Install prerequisites** — the module requires either the `Az.Advisor` PowerShell module (default) or access to the Azure Advisor REST API:

   ```powershell
   Install-Module -Name Az.Advisor -Repository PSGallery -Force
   Install-Module -Name Az.Accounts -Repository PSGallery -Force
   ```

4. **Import the module locally** to test your changes:

   ```powershell
   Import-Module ./AzRetirementMonitor.psd1 -Force
   ```

5. **Module layout** — keep this structure in mind when adding code:
   - `Public/` — exported (user-facing) functions; each new public function must also be added to `FunctionsToExport` in `AzRetirementMonitor.psd1`.
   - `Private/` — internal helper functions not exported to consumers.
   - `Tests/` — Pester v5 test files.

## Code Style

- **Use approved PowerShell verbs** (`Get`, `Set`, `New`, `Remove`, etc.) for all function names.
- **Include comment-based help** (`<# .SYNOPSIS … #>`) for every public function.
- **Use proper parameter validation** (`[ValidateNotNullOrEmpty()]`, `[ValidateSet()]`, etc.).
- **Write verbose messages** (`Write-Verbose`) to aid troubleshooting.
- **Handle errors gracefully** with `try/catch` and meaningful error messages.
- **PowerShell 5.1 compatibility** — the module must run on both PowerShell Desktop 5.1 and Core 7+. Avoid 7+-only syntax such as ternary operators (`? :`), `??=`, pipeline chain operators (`&&`, `||`), or `Get-Date -AsUTC`.
- Follow the patterns used in existing functions in `Public/` and `Private/`.

## Testing

All changes must be covered by Pester v5 tests. Run the test suite before opening a pull request.

### Install Pester (if needed)

```powershell
Install-Module -Name Pester -MinimumVersion 5.0.0 -Force -SkipPublisherCheck
```

### Run the full test suite

```powershell
Invoke-Pester ./Tests/AzRetirementMonitor.Tests.ps1
```

### Run a single test by name pattern

```powershell
Invoke-Pester ./Tests/AzRetirementMonitor.Tests.ps1 -Filter @{ FullName = '*pattern*' }
```

### Expectations

- All existing tests must continue to pass.
- New public functions require corresponding tests in `Tests/AzRetirementMonitor.Tests.ps1`.
- Mock any Azure API/module calls so tests do not require a live Azure connection.

## Pull Request Process

1. **Keep changes focused** — one feature or bug fix per PR.
2. **Update documentation** — update `README.md` and inline help if you change or add functionality.
3. **Add or update tests** — ensure new code paths are covered.
4. **Test both authentication methods** — verify behavior with Az.Accounts (`Connect-AzAccount`) and the REST API (`Connect-AzRetirementMonitor -UsingAPI`).
5. **Fill in the PR template** — describe the problem, solution, and how you tested the change.
6. **Pass CI** — all GitHub Actions checks must be green before a PR can be merged.

### PR Checklist

- [ ] Feature branch created from `main`
- [ ] Code follows the style guidelines above
- [ ] Comment-based help added/updated for any public functions
- [ ] Pester tests added/updated and all tests pass locally
- [ ] `FunctionsToExport` in `AzRetirementMonitor.psd1` updated (if adding a new public function)
- [ ] `README.md` updated (if behavior or public API changes)
- [ ] PR template completed

## Reporting Issues

- Use the [GitHub issue tracker](https://github.com/cocallaw/AzRetirementMonitor/issues) to report bugs or request features.
- Search existing issues before opening a new one.
- For bug reports, include:
  - PowerShell version (`$PSVersionTable`)
  - Operating system
  - Authentication method used (Az.Accounts or Azure CLI)
  - Steps to reproduce the problem
  - Expected vs. actual behavior

> **Security vulnerabilities** should not be reported through public issues. Please follow the process described in [SECURITY.md](SECURITY.md).
