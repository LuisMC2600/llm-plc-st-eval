<#
.SYNOPSIS
  Evaluacion en CODESYS del experimento definitivo: criterio 2 y criterio 1.
.DESCRIPTION
  Lanza, uno tras otro, la compilacion de las 720 extracciones y la simulacion
  con harness de cada modelo (ciclo de 10 ms). Un lote cuyo CSV de salida ya
  existe se omite, asi que se puede interrumpir y volver a lanzar: retoma en el
  primer lote que falte. No gasta API. CODESYS debe estar CERRADO.
  Uso:  powershell -ExecutionPolicy Bypass -File .\codesys\ejecutar_definitivo.ps1
#>
$ErrorActionPreference = "Continue"
$aqui = $PSScriptRoot
$raiz = Split-Path $aqui -Parent
Set-Location $raiz
$res = "data\results_codesys"
$t0 = Get-Date

function Titulo($t) { Write-Host ("`n########## {0}  ({1}) ##########" -f $t, (Get-Date -Format "HH:mm:ss")) -ForegroundColor Magenta }

Titulo "1 de 5: compilacion de las 720 extracciones (criterio 2)"
$sal = "$res\compilacion_definitivo_v2.csv"
if (Test-Path (Join-Path $raiz $sal)) { Write-Host "[omitido] ya existe $sal" -ForegroundColor Yellow }
else { & (Join-Path $aqui "ejecutar_compilar_lote.ps1") -Carpeta "data\processed_definitivo" -Salida $sal }

$lotes = @(
    @{ n = "2 de 5: simulacion gpt-4o-2024-08-06";      c = "gpt-4o-2024-08-06";      s = "definitivo_gpt4o.csv" },
    @{ n = "3 de 5: simulacion claude-sonnet-4-6";      c = "claude-sonnet-4-6";      s = "definitivo_claude.csv" },
    @{ n = "4 de 5: simulacion gemini-3.1-pro-preview"; c = "gemini-3.1-pro-preview"; s = "definitivo_gemini.csv" },
    @{ n = "5 de 5: simulacion qwen2.5-coder_14b";      c = "qwen2.5-coder_14b";      s = "definitivo_qwen.csv" }
)
foreach ($l in $lotes) {
    Titulo $l.n
    $sal = "$res\" + $l.s
    if (Test-Path (Join-Path $raiz $sal)) { Write-Host "[omitido] ya existe $sal" -ForegroundColor Yellow; continue }
    & (Join-Path $aqui "ejecutar_simular_lote.ps1") -Modo respuestas -Carpeta ("data\processed_definitivo\" + $l.c) -Ciclos 10 -Salida $sal
}

Titulo "FIN"
Write-Host ("Duracion total: {0:n1} horas" -f ((Get-Date) - $t0).TotalHours)
Write-Host "Listo. Avisale a Claude para que revise data\results_codesys." -ForegroundColor Green
