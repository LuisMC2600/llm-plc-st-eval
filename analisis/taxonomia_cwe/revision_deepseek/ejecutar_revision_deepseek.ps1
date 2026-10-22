<#
  Revisión DeepSeek de las 51 clasificaciones por juicio (taxonomía CWE). Gasta API (≈ USD 0.5).
  Uso:  powershell -ExecutionPolicy Bypass -File .\ejecutar_revision_deepseek.ps1
#>
$ErrorActionPreference = "Continue"
Set-Location $PSScriptRoot
if (-not $env:DEEPSEEK_API_KEY) { $env:DEEPSEEK_API_KEY = [Environment]::GetEnvironmentVariable("DEEPSEEK_API_KEY", "User") }
python revisar_cwe_deepseek.py --estimar
$r = Read-Host "¿Lanzar las llamadas reales? (s/n)"
if ($r -eq "s") { python revisar_cwe_deepseek.py } else { Write-Host "Cancelado; no se gastó nada." }
