[CmdletBinding()]
param(
    [switch]$ConfigureCodex
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$CodexDir = Join-Path $HOME ".codex"
$CodexConfig = Join-Path $CodexDir "config.toml"
$McpBlock = @'

[mcp_servers."godot-ai"]
url = "http://127.0.0.1:8000/mcp"
'@

Write-Host "Ruptura Temporal AI desktop setup"
Write-Host "Repo: $RepoRoot"

$uv = Get-Command uv -ErrorAction SilentlyContinue
if (-not $uv) {
    $python = Get-Command python -ErrorAction SilentlyContinue
    if (-not $python) {
        throw "Python was not found. Install Python first, then run this script again."
    }
    Write-Host "uv not found. Installing with python -m pip install --user uv..."
    & python -m pip install --user uv
    $uv = Get-Command uv -ErrorAction SilentlyContinue
    if (-not $uv) {
        Write-Warning "uv installed but is not on PATH yet. Restart the terminal or add the Python user Scripts folder to PATH."
    }
} else {
    Write-Host "uv found: $($uv.Source)"
}

if ($ConfigureCodex) {
    New-Item -ItemType Directory -Force -Path $CodexDir | Out-Null
    $configText = ""
    if (Test-Path -LiteralPath $CodexConfig) {
        $configText = Get-Content -LiteralPath $CodexConfig -Raw
    }
    if ($configText -notmatch '\[mcp_servers\."godot-ai"\]') {
        Add-Content -LiteralPath $CodexConfig -Value $McpBlock
        Write-Host "Added godot-ai MCP server to $CodexConfig"
    } else {
        Write-Host "godot-ai MCP server already exists in $CodexConfig"
    }
} else {
    Write-Host ""
    Write-Host "Run with -ConfigureCodex to add this block to ${CodexConfig}:"
    Write-Host $McpBlock
}

Write-Host ""
Write-Host "Next steps:"
Write-Host "1. Open the project in Godot 4.7+ so the Godot AI addon can run."
Write-Host "2. Restart Codex Desktop after changing ~/.codex/config.toml."
Write-Host "3. Validate with: powershell -ExecutionPolicy Bypass -File .\tools\validate_godot.ps1 -Deep"
