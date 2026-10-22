<#
.SYNOPSIS
  Ejecuta la sonda v2 del ScriptEngine en CODESYS V3.5 SP22 Patch 3 sin interfaz.
.DESCRIPTION
  Localiza CODESYS.exe y el perfil de SP22 Patch 3 y lanza sonda_scripting_sp22_v2.py
  con --noUI, ESPERANDO a que CODESYS termine (Start-Process -Wait). El perfil se
  pasa como --profile="<nombre>" (comillas solo en el valor), que es lo que CODESYS
  exige en modo --noUI; con las comillas alrededor del argumento completo aborta con
  "indicar un perfil". Deja evidencia en evidencias\codesys\<fecha>_sonda_v2\:
  transcript, copia del informe y SHA-256 de la plantilla antes y despues (debe
  coincidir: la sonda cierra sin guardar). CODESYS debe estar CERRADO.
.EXAMPLE
  .\codesys\ejecutar_sonda_v2.ps1
  .\codesys\ejecutar_sonda_v2.ps1 -CodesysExe "D:\CODESYS\Common\CODESYS.exe" -Perfil "CODESYS V3.5 SP22 Patch 3"
#>
param(
    [string]$CodesysExe = "",
    [string]$Perfil = "",
    [int]$TimeoutSeg = 600
)
$ErrorActionPreference = "Continue"
$aqui = $PSScriptRoot
$raiz = Split-Path $aqui -Parent
$sonda = Join-Path $aqui "sonda_scripting_sp22_v2.py"
$plantilla = Join-Path $aqui "Plantilla_Simulacion.project"
$res = Join-Path $aqui "sonda_v2_resultado.txt"

$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$ev = Join-Path $raiz ("evidencias\codesys\{0}_sonda_v2" -f $stamp)
New-Item -ItemType Directory -Force -Path $ev | Out-Null
Start-Transcript -Path (Join-Path $ev "transcript.txt") | Out-Null
try {
    if (-not (Test-Path $plantilla)) { throw "Falta $plantilla" }
    if (Get-Process -Name CODESYS -ErrorAction SilentlyContinue) {
        throw "CODESYS esta abierto. Cierralo y vuelve a ejecutar."
    }
    if (-not $CodesysExe) {
        $cand = Get-ChildItem "C:\Program Files\CODESYS 3.5.22*\CODESYS\Common\CODESYS.exe", "C:\Program Files*\CODESYS*\CODESYS\Common\CODESYS.exe" -ErrorAction SilentlyContinue |
            Sort-Object FullName -Descending | Select-Object -First 1
        if (-not $cand) { throw "No encontre CODESYS.exe. Pasalo con -CodesysExe." }
        $CodesysExe = $cand.FullName
    }
    $dirCommon = Split-Path $CodesysExe -Parent
    if (-not $Perfil) {
        $dirPerf = Join-Path (Split-Path $dirCommon -Parent) "Profiles"
        $p = Get-ChildItem $dirPerf -Filter "*SP22*Patch 3*.profile.xml" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($p) { $Perfil = $p.Name -replace '\.profile\.xml$', '' } else { $Perfil = "CODESYS V3.5 SP22 Patch 3" }
    }
    if (Test-Path $res) { Move-Item $res (Join-Path $ev "resultado_anterior.txt") }

    $hAntes = (Get-FileHash -Algorithm SHA256 $plantilla).Hash
    # Comillas SOLO alrededor de los valores: --profile="..." --runscript="..."
    $argumentos = "--profile=`"$Perfil`" --runscript=`"$sonda`" --noUI"
    Write-Host "CODESYS    : $CodesysExe"
    Write-Host "Argumentos : $argumentos"
    Write-Host "Ejecutando y esperando a que CODESYS termine (1-3 min)..." -ForegroundColor Cyan

    $t0 = Get-Date
    $proc = Start-Process -FilePath $CodesysExe -ArgumentList $argumentos -WorkingDirectory $dirCommon -PassThru -NoNewWindow
    $null = $proc.Handle   # necesario en PS 5.1 para que ExitCode quede disponible
    if (-not $proc.WaitForExit($TimeoutSeg * 1000)) {
        Write-Host "[AVISO] CODESYS sigue abierto tras $TimeoutSeg s: puede haber un dialogo esperando respuesta." -ForegroundColor Yellow
    }
    $dur = ((Get-Date) - $t0).TotalSeconds
    Write-Host ("Codigo de salida: {0}  |  duracion: {1:n0} s" -f $proc.ExitCode, $dur)

    $hDespues = (Get-FileHash -Algorithm SHA256 $plantilla).Hash
    if ($hAntes -eq $hDespues) { Write-Host "[OK] Plantilla sin cambios" -ForegroundColor Green }
    else { Write-Host "[ALERTA] La plantilla cambio: restaurarla antes de usarla en lotes" -ForegroundColor Red }

    @{ fecha = $stamp; codesys = $CodesysExe; perfil = $Perfil; argumentos = $argumentos
       codigo_salida = $proc.ExitCode; duracion_s = [math]::Round($dur, 1)
       sha256_plantilla_antes = $hAntes; sha256_plantilla_despues = $hDespues } |
        ConvertTo-Json | Out-File (Join-Path $ev "resumen.json") -Encoding utf8

    if (Test-Path $res) {
        Copy-Item $res $ev
        $j = Join-Path $aqui "sonda_v2_resultado.json"
        if (Test-Path $j) { Copy-Item $j $ev }
        Get-Content $res | Select-Object -First 100
    } else {
        Write-Host "[AVISO] No se genero sonda_v2_resultado.txt. Revisa el transcript y si CODESYS mostro un dialogo." -ForegroundColor Yellow
    }
    Write-Host "Evidencia: $ev"
}
finally {
    Stop-Transcript | Out-Null
}
