<#
.SYNOPSIS
  Ejecuta la sonda del ScriptEngine en CODESYS V3.5 SP22 Patch 3 sin interfaz.
.DESCRIPTION
  Busca CODESYS.exe y el perfil de SP22 Patch 3, lanza sonda_scripting_sp22.py
  con --noUI y muestra sonda_resultado.txt. CODESYS debe estar CERRADO.
  Requisito: codesys\Plantilla_Simulacion.project (LEEME_AUTOMATIZACION.md, paso 3).
.EXAMPLE
  .\codesys\ejecutar_sonda.ps1
  .\codesys\ejecutar_sonda.ps1 -CodesysExe "D:\CODESYS\Common\CODESYS.exe" -Perfil "CODESYS V3.5 SP22 Patch 3"
#>
param(
    [string]$CodesysExe = "",
    [string]$Perfil = ""
)
$ErrorActionPreference = "Continue"
$aqui = $PSScriptRoot
$sonda = Join-Path $aqui "sonda_scripting_sp22.py"
$plantilla = Join-Path $aqui "Plantilla_Simulacion.project"

if (-not (Test-Path $plantilla)) {
    Write-Host "[FALTA] $plantilla" -ForegroundColor Red
    Write-Host "Creala una vez en CODESYS: Standard project > CODESYS Control Win V3 x64 > PLC_PRG en ST > Guardar como en esta carpeta."
    exit 1
}

if (-not $CodesysExe) {
    $cand = Get-ChildItem "C:\Program Files\CODESYS 3.5.22*\CODESYS\Common\CODESYS.exe", "C:\Program Files*\CODESYS*\CODESYS\Common\CODESYS.exe" -ErrorAction SilentlyContinue |
        Sort-Object FullName -Descending | Select-Object -First 1
    if (-not $cand) { Write-Host "[FALTA] No encontre CODESYS.exe. Pasalo con -CodesysExe." -ForegroundColor Red; exit 1 }
    $CodesysExe = $cand.FullName
}
if (-not $Perfil) {
    $dirPerf = Join-Path (Split-Path (Split-Path $CodesysExe -Parent) -Parent) "Profiles"
    $p = Get-ChildItem $dirPerf -Filter "*SP22*Patch 3*.profile.xml" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($p) { $Perfil = $p.Name -replace '\.profile\.xml$', '' } else { $Perfil = "CODESYS V3.5 SP22 Patch 3" }
}
Write-Host "CODESYS : $CodesysExe"
Write-Host "Perfil  : $Perfil"
Write-Host "Sonda   : $sonda"
Write-Host "Ejecutando (puede tardar 1-2 minutos)..." -ForegroundColor Cyan

$t0 = Get-Date
& $CodesysExe "--profile=$Perfil" "--runscript=$sonda" "--noUI"
Write-Host ("Codigo de salida: {0}  ({1:n0} s)" -f $LASTEXITCODE, ((Get-Date) - $t0).TotalSeconds)

$res = Join-Path $aqui "sonda_resultado.txt"
if (Test-Path $res) { Get-Content $res -Encoding UTF8 | Select-Object -First 80 }
else { Write-Host "[AVISO] No se genero sonda_resultado.txt. Revisa si CODESYS mostro un dialogo (licencia, perfil)." -ForegroundColor Yellow }
