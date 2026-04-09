# Contributing to AzRetirementMonitor

Thank you for your interest in contributing! This guide covers everything you need to get started.

## Reporting Issues

- Use the [GitHub issue tracker](https://github.com/cocallaw/AzRetirementMonitor/issues) to report bugs or request features
- For bugs, provide clear reproduction steps, your PowerShell version (`$PSVersionTable`), OS, and authentication method used
- For security vulnerabilities, **do not open a public issue** — see [SECURITY.md](SECURITY.md)

## Development Setup

1. **Fork and clone** the repository:

   ```bash
   git clone https://github.com/<your-username>/AzRetirementMonitor.git
   cd AzRetirementMonitor
   ```

2. **Install development dependencies**:

   ```powershell
   Install-Module -Name Pester -Force -Scope CurrentUser -SkipPublisherCheck
   Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser
   ```

3. **Import the module locally** to test changes:

   ```powershell
   Import-Module ./AzRetirementMonitor.psd1 -Force
   ```

## Project Structure

```
AzRetirementMonitor.psd1   # Module manifest — lists exported functions
AzRetirementMonitor.psm1   # Root module — dot-sources Public/ and Private/
Public/                     # Exported functions (one function per file)
Private/                    # Internal helper functions (not exported)
Tests/                      # Pester v5 tests
```

The root module dot-sources all `.ps1` files from `Public/` and `Private/`, then exports only the `Public/` function names. When adding a new public function:

1. Create a new `.ps1` file in `Public/` — the file name **must** match the function name
2. Add the function name to `FunctionsToExport` in `AzRetirementMonitor.psd1`

## Code Style

### PowerShell Conventions

- **Use approved PowerShell verbs** (`Get-`, `Set-`, `Connect-`, `Export-`, etc.) — run `Get-Verb` for the full list
- **One function per file**, file name matching function name exactly
- **Include comment-based help** on all public functions (`.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, `.EXAMPLE`)
- **Use proper parameter validation** — `[ValidateNotNullOrEmpty()]`, `[ValidateSet()]`, `[ValidatePattern()]` as appropriate

### Output and Error Handling

- `Write-Verbose` for diagnostic/troubleshooting messages
- `Write-Warning` for recoverable errors (e.g., skipping a subscription)
- `throw` for fatal errors that should halt execution
- `Write-Host` only in `Connect-`/`Disconnect-` functions for user-facing status messages

### Compatibility

**PowerShell 5.1 (Desktop) compatibility is required.** Do not use PS 7+-only features:

- ❌ Ternary operator (`$x ? $a : $b`)
- ❌ Null-coalescing (`$x ?? $default`, `$x ??= $value`)
- ❌ Pipeline chain operators (`cmd1 && cmd2`)
- ❌ `Get-Date -AsUTC` — use `[DateTime]::UtcNow` instead
- ❌ `clean` block in functions

### Linting

The project uses [PSScriptAnalyzer](https://github.com/PowerShell/PSScriptAnalyzer) with a project-level settings file (`PSScriptAnalyzerSettings.psd1`) that enforces PS 5.1 syntax compatibility. Run the linter before submitting:

```powershell
# Lint all module source files
Invoke-ScriptAnalyzer -Path ./Public/*.ps1 -Settings ./PSScriptAnalyzerSettings.psd1
Invoke-ScriptAnalyzer -Path ./Private/*.ps1 -Settings ./PSScriptAnalyzerSettings.psd1
```

## Testing

Tests use [Pester v5](https://pester.dev/). External Azure dependencies (`Get-AzContext`, `Get-AzAccessToken`, `az` CLI) are mocked — you do **not** need an Azure account to run tests.

```powershell
# Run the full test suite
Invoke-Pester ./Tests/AzRetirementMonitor.Tests.ps1

# Run a single test by name pattern
Invoke-Pester ./Tests/AzRetirementMonitor.Tests.ps1 -Filter @{ FullName = '*Should clear the access token*' }

# Run with detailed output
Invoke-Pester ./Tests/AzRetirementMonitor.Tests.ps1 -Output Detailed
```

CI runs both PSScriptAnalyzer and Pester on every push and pull request to `main`.

## Pull Request Process

1. **Create a feature branch** from `main`
2. **Make focused changes** — one feature or fix per PR
3. **Add or update tests** for any new or changed functionality
4. **Run linting and tests** locally and confirm they pass
5. **Update documentation** (README, function help) if you change behavior
6. **Test with both authentication methods** if your change touches auth or recommendation retrieval:
   - Default method (Az.Advisor via `Connect-AzAccount`)
   - API method (REST API via `Connect-AzRetirementMonitor -UsingAPI`)
7. **Submit the PR** using the pull request template and fill out all sections

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE).
