# Copilot Instructions for AzRetirementMonitor

## Project Overview

AzRetirementMonitor is a PowerShell module that identifies Azure service retirements and deprecation notices by querying Azure Advisor recommendations. It supports two retrieval methods: the Az.Advisor PowerShell module (default) and a direct REST API mode.

## Module Layout

```
AzRetirementMonitor/
├── AzRetirementMonitor.psd1   # Module manifest (version, exports, metadata)
├── AzRetirementMonitor.psm1   # Module loader (dot-sources Public/ and Private/)
├── Public/                    # Exported user-facing functions
├── Private/                   # Internal helper functions (not exported)
├── Tests/                     # Pester v5 test suite
├── .github/workflows/         # CI (lint + test) and publish workflows
└── images/                    # Documentation assets
```

- **Public functions** are exported and must be listed in `FunctionsToExport` in the `.psd1` manifest.
- **Private functions** are internal helpers — never add them to `FunctionsToExport`.
- Each function lives in its own `.ps1` file named after the function.

## PowerShell Compatibility

This module targets **both PowerShell Desktop 5.1 and PowerShell Core 7+**.

### Do NOT use PowerShell 7+ only syntax:
- Ternary operators (`$x ? $a : $b`)
- Null-coalescing operators (`??`, `??=`)
- Pipeline chain operators (`&&`, `||`)
- `Get-Date -AsUTC` (use `[DateTime]::UtcNow` instead)
- `$PSStyle` or ANSI escape sequences without fallback

### Use instead:
- `if/else` statements for conditional assignment
- `[string]::IsNullOrWhiteSpace()` for null checks
- `[DateTime]::UtcNow` for UTC timestamps
- `[System.Collections.Generic.List[object]]::new()` for typed lists

## Coding Conventions

### Function Structure
- Use **approved PowerShell verbs** (Get, Set, New, Remove, Connect, Disconnect, Export, Test, Invoke).
- Include **comment-based help** (`<# .SYNOPSIS .DESCRIPTION .PARAMETER .EXAMPLE .OUTPUTS #>`) for every public function.
- Use `[CmdletBinding()]` on all functions.
- Apply `[OutputType()]` attribute when the return type is known.
- Use `[Parameter()]` attributes with validation (`[ValidatePattern()]`, `[ValidateSet()]`, `[ValidateNotNullOrEmpty()]`).

### Error Handling
- Use `try/catch` blocks with meaningful error messages via `Write-Error`.
- Use `Write-Warning` for non-fatal issues (e.g., skipping a subscription).
- Use `Write-Verbose` for diagnostic/troubleshooting messages.
- Never silently swallow errors.

### Security Practices
- Sanitize user-supplied data before outputting to CSV (formula injection) or HTML (XSS).
- Validate URLs with scheme checks (`https://` only) before rendering links.
- Validate pagination `nextLink` URIs against an allowlist of trusted hosts.
- Access tokens are module-scoped (`$script:AccessToken`) and cleared on disconnect.
- The module is strictly **read-only** — never add write operations against Azure resources.

### API Patterns
- Use `Invoke-AzPagedRequest` for all paginated REST API calls.
- Always pass `$script:ApiVersion` for API versioning.
- Filter recommendations server-side with `$filter` OData parameters where possible.
- Extract resource metadata (type, group, subscription) from resource IDs using regex.

## Testing

- Tests use **Pester v5** with `BeforeAll` module imports.
- Test file: `Tests/AzRetirementMonitor.Tests.ps1`
- Mock all Azure API/module calls — tests must work without a live Azure connection.
- Use `InModuleScope AzRetirementMonitor { }` when testing private/internal functions.
- Run tests: `Invoke-Pester ./Tests/AzRetirementMonitor.Tests.ps1`

## CI/CD

- **Lint**: PSScriptAnalyzer with `PSGallery` settings (excludes `Tests/` directory).
- **Test matrix**: ubuntu-latest (pwsh) + windows-latest (powershell 5.1).
- All CI checks must pass before merge.

## Adding New Functions

1. Create a `.ps1` file in `Public/` (exported) or `Private/` (internal).
2. If public, add the function name to `FunctionsToExport` in `AzRetirementMonitor.psd1`.
3. Add corresponding Pester tests in `Tests/AzRetirementMonitor.Tests.ps1`.
4. Update `README.md` if the function is user-facing.

## Key Design Decisions

- **Dual retrieval modes**: Default uses Az.Advisor module; `-UseAPI` switch enables direct REST calls. Both return identical `[PSCustomObject]` output shapes.
- **`SupportsShouldProcess`**: Used on destructive or file-writing operations (e.g., `Export-AzRetirementReport`).
- **Pipeline support**: `Get-AzRetirementRecommendation` output pipes directly into `Export-AzRetirementReport`.
- **No external dependencies at runtime** beyond Az.Advisor/Az.Accounts (for default mode) or Azure CLI (for API mode).
