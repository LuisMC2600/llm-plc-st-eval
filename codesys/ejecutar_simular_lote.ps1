<#
.SYNOPSIS
  Simula con harnesses en CODESYS V3.5 SP22 Patch 3 (criterio 1) con evidencia.
.DESCRIPTION
  -Modo dobles     verifica los 12 harnesses con los dobles de prueba de
                   codesys\dobles (68 dobles traducidos de los validadores Python).
  -Modo respuestas aplica los harnesses a respuestas de modelos.
  Cada simulacion abre la plantilla limpia, fija el ciclo de la MainTask,
  compila, simula hasta el veredicto y cierra SIN guardar. CODESYS debe estar
  CERRADO. Evidencia en evidencias\codesys\<fecha>_simulacion_<modo>\.
.EXAMPLE
  .\codesys\ejecutar_simular_lote.ps1 -Modo dobles -Tareas B1,B3,B4,I3,I6 -Ciclos 10 -Salida data\results_codesys\harness_prueba.csv
  .\codesys\ejecutar_simular_lote.ps1 -Modo dobles                      # los 12 harnesses, ciclos 4 y 10 ms
  .\codesys\ejecutar_simular_lote.ps1 -Modo respuestas                  # piloto: data\processed
#>
param(
    [ValidateSet("dobles", "respuestas")][string]$Modo = "dobles",
    [string[]]$Tareas = @(),
    [int[]]$Ciclos = @(4, 10),
    [string]$Carpeta = "data\processed",
    [string]$Salida = "",
    [int]$Limite = 0,
    [string]$CodesysExe = "",
    [string]$Perfil = "",
    [int]$TimeoutMin = 300
)
$ErrorActionPreference = "Continue"
$aqui = $PSScriptRoot
$raiz = Split-Path $aqui -Parent
$script = Join-Path $aqui "simular_lote_sp22.py"
$plantilla = Join-Path $aqui "Plantilla_Simulacion.project"
if (-not $Salida) { $Salida = "data\results_codesys\harness_$Modo.csv" }
$salidaAbs = Join-Path $raiz $Salida
$Tareas = @($Tareas | ForEach-Object { $_ -split "," } | Where-Object { $_ })

$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$ev = Join-Path $raiz ("evidencias\codesys\{0}_simulacion_{1}" -f $stamp, $Modo)
New-Item -ItemType Directory -Force -Path $ev | Out-Null
Start-Transcript -Path (Join-Path $ev "transcript.txt") | Out-Null
try {
    if (-not (Test-Path $plantilla)) { throw "Falta $plantilla" }
    if (Get-Process -Name CODESYS -ErrorAction SilentlyContinue) { throw "CODESYS esta abierto. Cierralo y vuelve a ejecutar." }
    if (Test-Path $salidaAbs) { throw "Ya existe $salidaAbs. Elige otra -Salida (no se sobrescriben resultados)." }
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

    $params = @{ modo = $Modo; carpeta_dobles = (Join-Path $aqui "dobles"); carpeta_codigo = (Join-Path $raiz $Carpeta)
                 carpeta_harness = $aqui; salida_csv = $salidaAbs; plantilla = $plantilla
                 ciclos_ms = $Ciclos; tareas = $Tareas; limite = $Limite }
    $params | ConvertTo-Json | Out-File (Join-Path $aqui "params_simular.json") -Encoding ascii
    Copy-Item (Join-Path $aqui "params_simular.json") $ev
    $hAntes = (Get-FileHash -Algorithm SHA256 $plantilla).Hash
    $hScript = (Get-FileHash -Algorithm SHA256 $script).Hash
    $hHarness = @{}
    Get-ChildItem $aqui -Filter "PRG_Test_*.st" | ForEach-Object { $hHarness[$_.Name] = (Get-FileHash -Algorithm SHA256 $_.FullName).Hash }
    Write-Host ("Modo {0} | tareas: {1} | ciclos: {2} ms" -f $Modo, ($(if ($Tareas.Count) { $Tareas -join "," } else { "todas" })), ($Ciclos -join ",")) -ForegroundColor Cyan
    Write-Host "Los harnesses largos (B5, I1, I2) tardan ~1-2 min por simulacion. El lote completo de dobles ronda 1-1.5 h." -ForegroundColor Cyan

    $argumentos = "--profile=`"$Perfil`" --runscript=`"$script`" --noUI"
    $t0 = Get-Date
    $proc = Start-Process -FilePath $CodesysExe -ArgumentList $argumentos -WorkingDirectory $dirCommon -PassThru -NoNewWindow
    $null = $proc.Handle
    if (-not $proc.WaitForExit($TimeoutMin * 60000)) { Write-Host "[AVISO] CODESYS sigue abierto tras $TimeoutMin min." -ForegroundColor Yellow }
    $dur = ((Get-Date) - $t0).TotalMinutes
    $hDespues = (Get-FileHash -Algorithm SHA256 $plantilla).Hash
    Write-Host ("Codigo de salida: {0}  |  duracion: {1:n1} min" -f $proc.ExitCode, $dur)
    if ($hAntes -eq $hDespues) { Write-Host "[OK] Plantilla sin cambios" -ForegroundColor Green } else { Write-Host "[ALERTA] La plantilla cambio" -ForegroundColor Red }

    $resumen = @{ fecha = $stamp; modo = $Modo; codigo_salida = $proc.ExitCode; duracion_min = [math]::Round($dur, 1)
                  sha256_script = $hScript; sha256_harness = $hHarness
                  sha256_plantilla_antes = $hAntes; sha256_plantilla_despues = $hDespues; salida = $salidaAbs }
    if (Test-Path $salidaAbs) {
        Copy-Item $salidaAbs $ev
        $filas = @(Import-Csv $salidaAbs)
        $resumen.simulaciones = $filas.Count
        $resumen.sha256_csv = (Get-FileHash -Algorithm SHA256 $salidaAbs).Hash
        if ($Modo -eq "dobles") {
            $resumen.coinciden = @($filas | Where-Object coincide -eq "1").Count
            Write-Host ("Simulaciones: {0} | coinciden con Python: {1}" -f $filas.Count, $resumen.coinciden) -ForegroundColor Cyan
            $filas | Group-Object tarea | ForEach-Object {
                $ok = @($_.Group | Where-Object coincide -eq "1").Count
                $estado = $(if ($ok -eq $_.Count) { "VERIFICADO" } else { "REVISAR" })
                Write-Host ("  {0}: {1}/{2}  {3}" -f $_.Name, $ok, $_.Count, $estado)
            }
        } else {
            Write-Host ("Simulaciones: {0}" -f $filas.Count) -ForegroundColor Cyan
        }
    } else {
        Write-Host "[AVISO] No se genero el CSV. Revisa el transcript." -ForegroundColor Yellow
    }
    $resumen | ConvertTo-Json -Depth 3 | Out-File (Join-Path $ev "resumen.json") -Encoding utf8
    Write-Host "Evidencia: $ev"
}
finally {
    Stop-Transcript | Out-Null
}
