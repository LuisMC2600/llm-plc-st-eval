<#
.SYNOPSIS
  Ampliacion de la sensibilidad S2 (decision del autor 2026-10-13): compila y simula las 2 respuestas
  que usan la entrada `R` del CTU (forma IEC) en lugar de `RESET` (CODESYS), normalizadas en copias aparte.
  Uso:  powershell -ExecutionPolicy Bypass -File .\codesys\ejecutar_sens_dialecto.ps1
  No gasta API. CODESYS debe estar CERRADO. Dura 1-2 minutos.
#>
$ErrorActionPreference = "Continue"
$aqui = $PSScriptRoot
Set-Location (Split-Path $aqui -Parent)
& (Join-Path $aqui "ejecutar_compilar_lote.ps1") -Carpeta "data\processed_sens_dialecto" -Salida "data\results_codesys\sens_dialecto_compilacion.csv"
& (Join-Path $aqui "ejecutar_simular_lote.ps1") -Modo respuestas -Carpeta "data\processed_sens_dialecto" -Tareas B3,C7 -Ciclos 10 -Salida "data\results_codesys\sens_dialecto_simulacion.csv"
Write-Host "Listo. Avisale a Claude para que complete la ampliacion de S2." -ForegroundColor Green
