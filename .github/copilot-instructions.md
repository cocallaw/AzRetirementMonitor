# Copilot Instructions for AzRetirementMonitor

## Project Overview

PowerShell module (v2.0) that queries Azure Advisor for service retirement and deprecation recommendations. Published to PowerShell Gallery. Supports PowerShell 5.1 (Desktop) and 7+ (Core).

Two data retrieval modes:
- **Default (Az.Advisor)**: Uses `Az.Advisor` PowerShell module via `Connect-AzAccount`. No module-level auth needed.
- **API mode**: Uses Azure REST API directly. Requires `Connect-AzRetirementMonitor -UsingAPI` to acquire and store an access token in `$script:AccessToken`.

## Build, Lint, and Test

```powershell
# Lint (PSScriptAnalyzer with project settings — excludes Tests/)
Invoke-ScriptAnalyzer -Path ./Public/*.ps1 -Settings ./PSScriptAnalyzerSettings.psd1
Invoke-ScriptAnalyzer -Path ./Private/*.ps1 -Settings ./PSScriptAnalyzerSettings.psd1

# Run full test suite
Invoke-Pester ./Tests/AzRetirementMonitor.Tests.ps1

# Run a single test by name
Invoke-Pester ./Tests/AzRetirementMonitor.Tests.ps1 -Filter @{ FullName = '*Should clear the access token*' }
```

CI runs both PSScriptAnalyzer and Pester on every push/PR to `main`.

## Architecture

```
AzRetirementMonitor.psd1   # Module manifest — lists FunctionsToExport
AzRetirementMonitor.psm1   # Root module — dot-sources Public/ and Private/, exports Public functions
Public/                    # Exported functions (one function per file, filename = function name)
Private/                   # Internal helpers (not exported)
Tests/                     # Pester tests
```

**Module loader pattern** (`AzRetirementMonitor.psm1`): Dot-sources all `.ps1` files from `Public/` and `Private/`, then exports only `Public/` function names via `Export-ModuleMember`. When adding a new public function, also add it to `FunctionsToExport` in the `.psd1` manifest.

**Module-scoped state**: `$script:AccessToken` and `$script:ApiVersion` are declared in the `.psm1` and shared across all functions. API mode functions read/write `$script:AccessToken`; the default Az.Advisor mode ignores it entirely.

**Dual-mode pattern in `Get-AzRetirementRecommendation`**: The `-UseAPI` switch selects between two completely separate code paths in `begin`/`process` blocks — one calling `Az.Advisor` cmdlets, the other calling the REST API via `Invoke-AzPagedRequest`. Both paths normalize results into the same `PSCustomObject` shape with identical properties.

## Key Conventions

- **One function per file**. File name must match function name exactly.
- **All public functions include comment-based help** (`.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, `.EXAMPLE`).
- **Approved PowerShell verbs only** (`Get-`, `Set-`, `Connect-`, `Export-`, etc.).
- **`Write-Verbose`** for diagnostic messages, **`Write-Warning`** for recoverable errors, **`throw`** for fatal errors. `Write-Host` is used sparingly (only in `Connect-`/`Disconnect-` for user-facing status).
- **PowerShell 5.1 compatibility is required**. Avoid PS 7+-only syntax (e.g., `Get-Date -AsUTC`, ternary `?:`, `??=`, pipeline chain operators `&&`). Use `[DateTime]::UtcNow` instead of `Get-Date -AsUTC`.
- **`Az.Accounts` 5.0+ returns `SecureString` tokens**. The `Connect-AzRetirementMonitor` function handles both `SecureString` and plain-text `Token` properties for backward compatibility.
- **CSV export sanitizes formula injection** by prefixing cells starting with `=`, `+`, `-`, `@` with a single quote.
- **HTML export uses `[System.Net.WebUtility]::HtmlEncode()`** on all user-provided data and validates URLs against `^https?://` before rendering `<a>` tags.
- **Tests use Pester v5** with `BeforeAll`/`BeforeEach` blocks. External Azure dependencies (`Get-AzContext`, `Get-AzAccessToken`, `az` CLI) are mocked. Module-scoped state is accessed via `& $module { $script:AccessToken }`.
- **Publishing** is triggered by pushing a `v*` tag or via `workflow_dispatch`. The publish workflow stages files into `./staging/AzRetirementMonitor/` before calling `Publish-Module`.
