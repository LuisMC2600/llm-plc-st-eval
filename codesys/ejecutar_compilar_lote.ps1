<#
.SYNOPSIS
  Compila por lotes en CODESYS V3.5 SP22 Patch 3 (criterio 2) con evidencia.
.DESCRIPTION
  Escribe params_compilar.json, lanza compilar_lote_sp22.py con --noUI y espera a
  que termine. El script compila primero dos controles del instrumento (uno
  correcto y otro con errores) y se detiene si no discriminan. Cada respuesta se
  compila en la plantilla recien abierta, instanciada desde PRG_Envoltorio, y se
  cierra SIN guardar. Evidencia en evidencias\codesys\<fecha>_compilacion\.
  CODESYS debe estar CERRADO. Solo LEE las respuestas.
.EXAMPLE
  .\codesys\ejecutar_compilar_lote.ps1 -Limite 6                   # prueba corta
  .\codesys\ejecutar_compilar_lote.ps1                             # piloto completo (144)
  .\codesys\ejecutar_compilar_lote.ps1 -Carpeta data\processed_definitivo -Salida data\results_codesys\compilacion_definitivo.csv
#>
param(
    [string]$Carpeta = "data\processed",
    [string]$Salida = "data\results_codesys\compilacion_piloto.csv",
    [int]$Limite = 0,
    [string]$CodesysExe = "",
    [string]$Perfil = "",
    [int]$TimeoutMin = 240
)
$ErrorActionPreference = "Continue"
$aqui = $PSScriptRoot
$raiz = Split-Path $aqui -Parent
$script = Join-Path $aqui "compilar_lote_sp22.py"
$plantilla = Join-Path $aqui "Plantilla_Simulacion.project"
$carpetaAbs = Join-Path $raiz $Carpeta
$salidaAbs = Join-Path $raiz $Salida

$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$ev = Join-Path $raiz ("evidencias\codesys\{0}_compilacion" -f $stamp)
New-Item -ItemType Directory -Force -Path $ev | Out-Null
Start-Transcript -Path (Join-Path $ev "transcript.txt") | Out-Null
try {
    if (-not (Test-Path $carpetaAbs)) { throw "No existe la carpeta de respuestas: $carpetaAbs" }
    if (-not (Test-Path $plantilla)) { throw "Falta $plantilla" }
    if (Get-Process -Name CODESYS -ErrorAction SilentlyContinue) { throw "CODESYS esta abierto. Cierralo y vuelve a ejecutar." }
    if (Test-Path $salidaAbs) { throw "Ya existe $salidaAbs. Muevelo o elige otra -Salida (no se sobrescriben resultados)." }
    New-Item -ItemType Directory -Force -Path (Split-Path $salidaAbs -Parent) | Out-Null

    if (-not $CodesysExe) {
        $cand = Get-ChildItem "C:\Program Files\CODESYS 3.5.22*\CODESYS\Common\CODESYS.exe", "C:\Program Files*\CODESYS*\CODESYS\Common\CODESYS.exe" -ErrorAction SilentlyContinue |
            Sort-Object FullName -Descending | Select-Object -First 1
        if (-not $cand) { throw "No encontre CODESYS.exe. Pasalo con -CodesysExe." }
        $CodesysExe = $cand.FullName
    }
    $dirCommon = Split-Path $CodesysExe -Parent
    if (-not $Perfil) {
        $p = Get-ChildItem (Join-Path (Split-Path $dirCommon -Parent) "Profiles") -Filter "*SP22*Patch 3*.profile.xml" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($p) { $Perfil = $p.Name -replace '\.profile\.xml$', '' } else { $Perfil = "CODESYS V3.5 SP22 Patch 3" }
    }

    $nResp = (Get-ChildItem $carpetaAbs -Recurse -Filter *.st).Count
    if ($Limite -gt 0) { $nResp = [math]::Min($nResp, $Limite) }
    Write-Host ("Respuestas a compilar: {0}  (estimado {1:n0}-{2:n0} min)" -f $nResp, ($nResp * 4 / 60), ($nResp * 7 / 60)) -ForegroundColor Cyan

    @{ carpeta_codigo = $carpetaAbs; salida_csv = $salidaAbs; plantilla = $plantilla; limite = $Limite } |
        ConvertTo-Json | Out-File (Join-Path $aqui "params_compilar.json") -Encoding ascii
    Copy-Item (Join-Path $aqui "params_compilar.json") $ev
    $hAntes = (Get-FileHash -Algorithm SHA256 $plantilla).Hash
    $hScript = (Get-FileHash -Algorithm SHA256 $script).Hash

    $argumentos = "--profile=`"$Perfil`" --runscript=`"$script`" --noUI"
    Write-Host "Argumentos: $argumentos"
    $t0 = Get-Date
    $proc = Start-Process -FilePath $CodesysExe -ArgumentList $argumentos -WorkingDirectory $dirCommon -PassThru -NoNewWindow
    $null = $proc.Handle
    if (-not $proc.WaitForExit($TimeoutMin * 60000)) {
        Write-Host "[AVISO] CODESYS sigue abierto tras $TimeoutMin min: puede haber un dialogo esperando." -ForegroundColor Yellow
    }
    $dur = ((Get-Date) - $t0).TotalMinutes
    $hDespues = (Get-FileHash -Algorithm SHA256 $plantilla).Hash
    Write-Host ("Codigo de salida: {0}  |  duracion: {1:n1} min" -f $proc.ExitCode, $dur)
    if ($hAntes -eq $hDespues) { Write-Host "[OK] Plantilla sin cambios" -ForegroundColor Green }
    else { Write-Host "[ALERTA] La plantilla cambio" -ForegroundColor Red }

    $ctrl = "$salidaAbs.controles.json"
    if (Test-Path $ctrl) {
        Copy-Item $ctrl $ev
        $c = Get-Content $ctrl -Raw | ConvertFrom-Json
        Write-Host ("Controles -> correcto: compila={0} errores={1} | con errores: compila={2} errores={3} | funcion: compila={4}" -f `
            $c.control_ok.compila, $c.control_ok.errores, $c.control_error.compila, $c.control_error.errores, $c.control_funcion.compila)
    }
    $resumen = @{ fecha = $stamp; codigo_salida = $proc.ExitCode; duracion_min = [math]::Round($dur, 1)
                  sha256_plantilla_antes = $hAntes; sha256_plantilla_despues = $hDespues; sha256_script = $hScript
                  salida = $salidaAbs }
    if (Test-Path $salidaAbs) {
        Copy-Item $salidaAbs $ev
        $filas = @(Import-Csv $salidaAbs)
        $resumen.respuestas = $filas.Count
        $resumen.compila_1 = @($filas | Where-Object compila -eq "1").Count
        $resumen.compila_0 = @($filas | Where-Object compila -eq "0").Count
        $resumen.compila_NA = @($filas | Where-Object compila -eq "NA").Count
        $resumen.sha256_csv = (Get-FileHash -Algorithm SHA256 $salidaAbs).Hash
        Write-Host ("Resultado: {0} respuestas | compilan {1} | no compilan {2} | NA {3}" -f $filas.Count, $resumen.compila_1, $resumen.compila_0, $resumen.compila_NA) -ForegroundColor Cyan
    } else {
        Write-Host "[AVISO] No se genero el CSV. Si los controles fallaron, el lote no se ejecuta (ver controles.json)." -ForegroundColor Yellow
    }
    $resumen | ConvertTo-Json | Out-File (Join-Path $ev "resumen.json") -Encoding utf8
    Write-Host "Evidencia: $ev"
}
finally {
    Stop-Transcript | Out-Null
}
