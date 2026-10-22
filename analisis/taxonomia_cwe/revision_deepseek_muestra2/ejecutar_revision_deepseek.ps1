<#
  Revisión DeepSeek a ciegas de la segunda muestra del mapa de pasos v2 (22 casos). Gasta API (≈ USD 0.2).
  Uso:  powershell -ExecutionPolicy Bypass -File .\ejecutar_revision_deepseek.ps1
#>
$ErrorActionPreference = "Continue"
Set-Location $PSScriptRoot
if (-not $env:DEEPSEEK_API_KEY) { $env:DEEPSEEK_API_KEY = [Environment]::GetEnvironmentVariable("DEEPSEEK_API_KEY", "User") }
python revisar_cwe_deepseek.py --estimar
$r = Read-Host "¿Lanzar las llamadas reales? (s/n)"
if ($r -eq "s") { python revisar_cwe_deepseek.py } else { Write-Host "Cancelado; no se gastó nada." }
