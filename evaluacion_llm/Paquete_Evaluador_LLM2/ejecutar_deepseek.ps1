# Lanza el segundo evaluador LLM (DeepSeek). Uso, desde PowerShell:
#   powershell -ExecutionPolicy Bypass -File ".\ejecutar_deepseek.ps1" --estimar
#   powershell -ExecutionPolicy Bypass -File ".\ejecutar_deepseek.ps1" --solo C1
#   powershell -ExecutionPolicy Bypass -File ".\ejecutar_deepseek.ps1"
$ErrorActionPreference = "Stop"
Set-Location -Path $PSScriptRoot
$env:DEEPSEEK_API_KEY = [Environment]::GetEnvironmentVariable("DEEPSEEK_API_KEY", "User")
if ((-not $env:DEEPSEEK_API_KEY) -and ($args -notcontains "--estimar")) {
    Write-Host "Falta DEEPSEEK_API_KEY en las variables de Usuario." -ForegroundColor Red
    exit 1
}
Write-Host ("Clave cargada: {0} caracteres" -f $env:DEEPSEEK_API_KEY.Length)
python .\evaluar_deepseek.py @args
