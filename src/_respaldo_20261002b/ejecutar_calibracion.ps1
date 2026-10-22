# =====================================================================
# Calibracion previa (Etapa 2.3 de GUIA_EJECUCION.md)
# 4 modelos x tarea B1 x 2 estrategias x 3 ejecuciones = 24 llamadas (~$0.17)
# Salida aislada en data/calibracion/. NO toca data/raw ni data/definitivo.
#
# Uso:  powershell -ExecutionPolicy Bypass -File .\ejecutar_calibracion.ps1
# =====================================================================
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

$dirCal = Join-Path $PSScriptRoot "..\data\calibracion"
New-Item -ItemType Directory -Force -Path $dirCal | Out-Null
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
Start-Transcript -Path (Join-Path $dirCal "consola_$stamp.log") | Out-Null

function Titulo($t) { Write-Host "`n===== $t =====" -ForegroundColor Cyan }

Titulo "1. Entorno"
python --version
foreach ($m in @("openai","anthropic","google.genai","yaml")) {
    $r = python -c "import $m; print('  [ok] $m')" 2>&1
    if ($LASTEXITCODE -ne 0) { Write-Host "  [FALTA] $m  -> pip install -r ..\requirements.txt" -ForegroundColor Red }
    else { Write-Host $r }
}

Titulo "2. Claves de API (solo se comprueba presencia, nunca el valor)"
foreach ($k in @("OPENAI_API_KEY","ANTHROPIC_API_KEY","GOOGLE_API_KEY")) {
    $v = [Environment]::GetEnvironmentVariable($k)
    if ([string]::IsNullOrEmpty($v)) { Write-Host "  [FALTA] $k" -ForegroundColor Red }
    else { Write-Host ("  [ok] {0} presente ({1} caracteres)" -f $k, $v.Length) }
}

Titulo "3. Modelo local (Ollama)"
try {
    $tags = ollama list 2>&1 | Out-String
    Write-Host $tags
    if ($tags -notmatch "qwen2\.5-coder:14b") {
        Write-Host "  [AVISO] qwen2.5-coder:14b no aparece. Descargalo con:" -ForegroundColor Yellow
        Write-Host "          ollama pull qwen2.5-coder:14b" -ForegroundColor Yellow
    }
} catch { Write-Host "  [AVISO] Ollama no responde. Abre la app de Ollama y reintenta." -ForegroundColor Yellow }

Titulo "4. Dry-run (debe reportar 24 pendientes)"
python runner.py --config config_calibracion.yaml --dry-run | Select-Object -Last 2

Titulo "5. Confirmacion"
Write-Host "Se van a realizar hasta 24 llamadas reales (~`$0.17)." -ForegroundColor Yellow
$resp = Read-Host "Escribe SI para continuar"
if ($resp -ne "SI") { Write-Host "Cancelado por el usuario."; Stop-Transcript | Out-Null; exit 0 }

Titulo "6. Ejecucion"
$t0 = Get-Date
python runner.py --config config_calibracion.yaml
$dur = (Get-Date) - $t0
Write-Host ("`nDuracion total: {0:n1} minutos" -f $dur.TotalMinutes)

Titulo "7. Verificacion (debe reportar 0 pendientes)"
python runner.py --config config_calibracion.yaml --dry-run | Select-Object -Last 2

Titulo "8. Resumen del log"
python -c "import json,collections;L=[json.loads(l) for l in open(r'..\data\calibracion\log.jsonl',encoding='utf-8') if l.strip()];print('Registros:',len(L));c=collections.Counter(r['modelo_config'] for r in L);[print(' ',k,v) for k,v in c.items()];print('Tokens entrada:',sum(r['tokens_entrada'] for r in L));print('Tokens salida :',sum(r['tokens_salida'] for r in L))"

Stop-Transcript | Out-Null
Write-Host "`nListo. Avisale a Claude: puede leer data/calibracion/ directamente." -ForegroundColor Green
