<#
.SYNOPSIS
  Sensibilidad S2 (INC-34): compila y simula las 7 respuestas de A5 con END_STRUCT; normalizado.
  Uso:  powershell -ExecutionPolicy Bypass -File .\codesys\ejecutar_sens_endstruct.ps1
  No gasta API. CODESYS debe estar CERRADO. Dura unos 2 minutos.
#>
$ErrorActionPreference = "Continue"
$aqui = $PSScriptRoot
Set-Location (Split-Path $aqui -Parent)
& (Join-Path $aqui "ejecutar_compilar_lote.ps1") -Carpeta "data\processed_sens_endstruct" -Salida "data\results_codesys\sens_endstruct_compilacion.csv"
& (Join-Path $aqui "ejecutar_simular_lote.ps1") -Modo respuestas -Carpeta "data\processed_sens_endstruct" -Tareas A5 -Ciclos 10 -Salida "data\results_codesys\sens_endstruct_simulacion.csv"
Write-Host "Listo. Avisale a Claude para que complete el analisis de sensibilidad." -ForegroundColor Green
