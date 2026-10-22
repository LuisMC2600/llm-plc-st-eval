# =====================================================================
# Sonda de razonamiento de Gemini (INC-28)
# gemini-3.1-pro-preview x tarea A6 x 2 estrategias x 3 ejecuciones = 6 llamadas
# Tope de API 20000 tokens (razonamiento + respuesta). Costo estimado: 0.5 a 1 USD;
# tope teorico si las 6 agotaran los 20000 tokens: ~1.5 USD.
# Salida aislada en data/sonda_gemini/. NO toca data/raw ni data/definitivo.
#
# Uso:  powershell -ExecutionPolicy Bypass -File .\ejecutar_sonda_gemini.ps1
# =====================================================================
$ErrorActionPreference = "Continue"
Set-Location $PSScriptRoot

$k = "GOOGLE_API_KEY"
if ([string]::IsNullOrEmpty([Environment]::GetEnvironmentVariable($k))) {
    $u = [Environment]::GetEnvironmentVariable($k, "User")
    if (-not [string]::IsNullOrEmpty($u)) { [Environment]::SetEnvironmentVariable($k, $u, "Process") }
}
$v = [Environment]::GetEnvironmentVariable($k)
if ([string]::IsNullOrEmpty($v)) { Write-Host "[FALTA] GOOGLE_API_KEY. No se ejecuta nada." -ForegroundColor Red; exit 1 }
Write-Host ("[ok] GOOGLE_API_KEY presente ({0} caracteres)" -f $v.Length)

Write-Host "`n===== Dry-run (debe reportar 6 pendientes) =====" -ForegroundColor Cyan
python runner.py --config config_sonda_gemini.yaml --dry-run | Select-Object -Last 2

Write-Host "`nSe van a realizar hasta 6 llamadas reales a Google (estimado: 0.5 a 1 USD)." -ForegroundColor Yellow
$resp = Read-Host "Escribe SI para continuar"
if ($resp -ne "SI") { Write-Host "Cancelado por el usuario."; exit 0 }

python runner.py --config config_sonda_gemini.yaml

Write-Host "`n===== Verificacion (debe reportar 0 pendientes) =====" -ForegroundColor Cyan
python runner.py --config config_sonda_gemini.yaml --dry-run | Select-Object -Last 2
Write-Host "`nListo. Avisale a Claude: puede leer data/sonda_gemini/ directamente." -ForegroundColor Green
