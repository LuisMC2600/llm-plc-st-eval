<#
.SYNOPSIS
  Comprueba SIN GASTAR API si los 4 modelos de config.yaml estan disponibles.
.DESCRIPTION
  Solo hace consultas de catalogo (GET /models), que no generan texto ni costo.
  Nunca muestra el valor de las claves. No toca data/.
  Uso:  powershell -ExecutionPolicy Bypass -File .\herramientas\verificar_modelos.ps1
#>
$ErrorActionPreference = "Continue"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
function Titulo($t) { Write-Host "`n===== $t =====" -ForegroundColor Cyan }
function Consultar($nombre, $url, $headers) {
    try {
        $null = Invoke-RestMethod -Uri $url -Headers $headers -Method Get -TimeoutSec 30
        Write-Host "  [OK] $nombre aparece en el catalogo de tu cuenta" -ForegroundColor Green
    } catch {
        $err = $_
        $codigo = 0
        if ($err.Exception.Response) { $codigo = [int]$err.Exception.Response.StatusCode }
        $pista = switch ($codigo) {
            401 { "clave invalida o revocada" }
            403 { "la clave no tiene permiso para este modelo" }
            404 { "el modelo no existe para tu cuenta (retirado o sin acceso)" }
            429 { "limite de peticiones o sin saldo" }
            default { $err.Exception.Message }
        }
        Write-Host "  [FALLA] $nombre -> HTTP $codigo : $pista" -ForegroundColor Red
    }
}

Titulo "1. Claves en variables de entorno (solo presencia)"
$claves = @{}
foreach ($k in @("OPENAI_API_KEY", "ANTHROPIC_API_KEY", "GOOGLE_API_KEY")) {
    $v = [Environment]::GetEnvironmentVariable($k)
    if ([string]::IsNullOrEmpty($v)) { $v = [Environment]::GetEnvironmentVariable($k, "User") }
    $claves[$k] = $v
    if ([string]::IsNullOrEmpty($v)) { Write-Host "  [FALTA] $k" -ForegroundColor Red }
    else { Write-Host ("  [ok] {0} presente ({1} caracteres)" -f $k, $v.Length) }
}

Titulo "2. OpenAI: gpt-4o-2024-08-06"
if ($claves["OPENAI_API_KEY"]) {
    Consultar "gpt-4o-2024-08-06" "https://api.openai.com/v1/models/gpt-4o-2024-08-06" @{ Authorization = "Bearer " + $claves["OPENAI_API_KEY"] }
} else { Write-Host "  (sin clave: no se puede comprobar)" -ForegroundColor Yellow }

Titulo "3. Anthropic: claude-sonnet-4-6"
if ($claves["ANTHROPIC_API_KEY"]) {
    Consultar "claude-sonnet-4-6" "https://api.anthropic.com/v1/models/claude-sonnet-4-6" @{ "x-api-key" = $claves["ANTHROPIC_API_KEY"]; "anthropic-version" = "2023-06-01" }
} else { Write-Host "  (sin clave: no se puede comprobar)" -ForegroundColor Yellow }

Titulo "4. Google: gemini-3.1-pro-preview"
if ($claves["GOOGLE_API_KEY"]) {
    Consultar "gemini-3.1-pro-preview" "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-pro-preview" @{ "x-goog-api-key" = $claves["GOOGLE_API_KEY"] }
    Write-Host "  OJO: sustituye a gemini-2.5-pro (INC-19) y exige nivel de pago. Aparecer en el" -ForegroundColor Yellow
    Write-Host "  catalogo no garantiza poder generar: eso solo se confirma con una llamada real." -ForegroundColor Yellow
} else { Write-Host "  (sin clave: no se puede comprobar)" -ForegroundColor Yellow }

Titulo "5. Ollama local: qwen2.5-coder:14b"
$ollama = Get-Command ollama -ErrorAction SilentlyContinue
if (-not $ollama) {
    Write-Host "  [FALTA] Ollama no esta instalado (https://ollama.com/download)" -ForegroundColor Red
} else {
    Write-Host "  [ok] Ollama instalado: $(ollama --version 2>&1)"
    $lista = (ollama list 2>&1 | Out-String)
    if ($lista -match "qwen2\.5-coder:14b") { Write-Host "  [OK] qwen2.5-coder:14b ya esta descargado" -ForegroundColor Green }
    else { Write-Host "  [FALTA] modelo no descargado -> ollama pull qwen2.5-coder:14b  (~9 GB, gratis)" -ForegroundColor Red }
}

Titulo "6. Equipo (para saber si Qwen 14b correra bien en local)"
$ram = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 1)
Write-Host "  RAM: $ram GB"
Get-CimInstance Win32_VideoController | ForEach-Object {
    Write-Host ("  GPU: {0}  (VRAM reportada: {1} GB)" -f $_.Name, [math]::Round($_.AdapterRAM / 1GB, 1))
}
$disco = Get-PSDrive C
Write-Host ("  Disco C: libre {0} GB" -f [math]::Round($disco.Free / 1GB, 1))
Write-Host "`nListo. Copia esta salida completa y pegala en el chat." -ForegroundColor Cyan
