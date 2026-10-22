<#
.SYNOPSIS
  Criterio 1 de C7 y C8 (conversion LD->ST) con los harnesses verificados de B3 y B2.
  Uso:  powershell -ExecutionPolicy Bypass -File .\codesys\ejecutar_c7c8.ps1
  48 simulaciones, unos 8 minutos. No gasta API. CODESYS debe estar CERRADO.
#>
$ErrorActionPreference = "Continue"
$aqui = $PSScriptRoot
Set-Location (Split-Path $aqui -Parent)
& (Join-Path $aqui "ejecutar_simular_lote.ps1") -Modo respuestas -Carpeta "data\processed_definitivo" -Tareas C7,C8 -Ciclos 10 -Salida "data\results_codesys\definitivo_c7c8.csv"
Write-Host "Listo. Avisale a Claude para que incorpore C7 y C8 al criterio 1." -ForegroundColor Green
