<#
.SYNOPSIS
  Lanza un lote de la Fase 4 (un modelo o todos) dejando evidencia auditable.

.DESCRIPTION
  1. Verifica la integridad del banco frente al piloto (verificar_hashes.py).
  2. Genera una configuracion de lote derivada de src\config.yaml que solo
     filtra la lista de modelos. Parametros, rutas y tareas son identicos.
  3. Hace un dry-run y lo guarda.
  4. SOLO con -Confirmar llama a las APIs (runner.py es idempotente: si se
     corta, relanzar completa lo que falte).
  5. Captura pantalla en cada hito y escribe resumen.json con los conteos y
     el SHA-256 del log.
  Todo queda en evidencias\fase4\<fecha>_<modelo>\ (incluido el transcript).

.EXAMPLE
  .\herramientas\ejecutar_con_evidencia.ps1 -Modelo todos                     # solo dry-run
  .\herramientas\ejecutar_con_evidencia.ps1 -Modelo qwen2.5-coder:14b -Confirmar
#>
param(
    [Parameter(Mandatory = $true)][string]$Modelo,
    [string]$Config = "config.yaml",
    [switch]$Confirmar,
    [switch]$SinCapturas
)
# "Continue" a proposito: en Windows PowerShell 5.1, con "Stop", cualquier linea que
# runner.py escriba en stderr (avisos, reintentos) abortaria el lote a mitad.
# Los fallos reales se detectan con $LASTEXITCODE y se lanzan con throw.
$ErrorActionPreference = "Continue"
foreach ($k in @("OPENAI_API_KEY","ANTHROPIC_API_KEY","GOOGLE_API_KEY")) {
    # INC-27: si la ventana no heredo la variable de usuario, se carga en esta sesion.
    if ([string]::IsNullOrEmpty([Environment]::GetEnvironmentVariable($k))) {
        $u = [Environment]::GetEnvironmentVariable($k, "User")
        if (-not [string]::IsNullOrEmpty($u)) { [Environment]::SetEnvironmentVariable($k, $u, "Process") }
    }
}
$raiz = Split-Path $PSScriptRoot -Parent
$src = Join-Path $raiz "src"
$capturar = Join-Path $PSScriptRoot "capturar_pantalla.ps1"

$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$slugModelo = ($Modelo -replace '[^\w\.\-]+', '_')
$ev = Join-Path $raiz ("evidencias\fase4\{0}_{1}" -f $stamp, $slugModelo)
New-Item -ItemType Directory -Force -Path $ev | Out-Null
Start-Transcript -Path (Join-Path $ev "transcript.txt") | Out-Null

function Titulo($t) { Write-Host "`n===== $t =====" -ForegroundColor Cyan }
function Captura($etq) {
    if (-not $SinCapturas) { & $capturar -Etiqueta $etq -Carpeta $ev }
}

try {
    Set-Location $src

    Titulo "1. Integridad del banco frente al piloto"
    python verificar_hashes.py
    if ($LASTEXITCODE -ne 0) { throw "verificar_hashes.py fallo: el banco no coincide con el piloto. No se ejecuta nada." }
    Captura "01_integridad_hashes"

    Titulo "2. Configuracion del lote"
    $cfgLote = Join-Path $ev "config_lote.yaml"
    $py = @"
import sys, yaml
cfg = yaml.safe_load(open(sys.argv[1], encoding='utf-8'))
m = sys.argv[2]
if m != 'todos':
    ids = [x['id'] for x in cfg['modelos']]
    if m not in ids:
        sys.exit('Modelo desconocido: %s. Validos: %s' % (m, ids))
    cfg['modelos'] = [x for x in cfg['modelos'] if x['id'] == m]
yaml.safe_dump(cfg, open(sys.argv[3], 'w', encoding='utf-8'), allow_unicode=True, sort_keys=False)
print('Modelos del lote:', [x['id'] for x in cfg['modelos']])
print('Parametros:', cfg['generacion'], '| ejecuciones por tarea:', cfg['experimento']['ejecuciones_por_tarea'])
"@
    $py | python - $Config $Modelo $cfgLote
    if ($LASTEXITCODE -ne 0) { throw "No se pudo generar la configuracion del lote." }
    # runner.py resuelve las rutas relativas a src\, por eso el lote se ejecuta desde ahi
    $cfgEnSrc = Join-Path $src ("_config_lote_{0}.yaml" -f $stamp)
    Copy-Item $cfgLote $cfgEnSrc

    Titulo "3. Dry-run"
    python runner.py --config $cfgEnSrc --dry-run | Tee-Object -FilePath (Join-Path $ev "dryrun.txt") | Select-Object -Last 3
    Captura "02_dryrun"

    if (-not $Confirmar) {
        Write-Host "`nSin -Confirmar: no se llamo a ninguna API. Evidencia en $ev" -ForegroundColor Yellow
        return
    }

    Titulo "4. Ejecucion (llamadas reales)"
    $t0 = Get-Date
    python runner.py --config $cfgEnSrc 2>&1 | Tee-Object -FilePath (Join-Path $ev "ejecucion.txt")
    $dur = ((Get-Date) - $t0).TotalMinutes
    Write-Host ("Duracion: {0:n1} min" -f $dur)
    Captura "03_fin_ejecucion"

    Titulo "5. Verificacion posterior (pendientes deben ser 0)"
    python runner.py --config $cfgEnSrc --dry-run | Select-Object -Last 1 | Tee-Object -FilePath (Join-Path $ev "pendientes_post.txt")

    Titulo "6. Resumen"
    $pyRes = @"
import sys, json, yaml, hashlib, collections, os
cfg = yaml.safe_load(open(sys.argv[1], encoding='utf-8'))
log = cfg['rutas']['log']
res = {'log': os.path.abspath(log), 'duracion_min': float(sys.argv[3])}
if os.path.exists(log):
    filas = [json.loads(l) for l in open(log, encoding='utf-8') if l.strip()]
    res['registros_totales'] = len(filas)
    res['por_modelo'] = dict(collections.Counter(f['modelo_config'] for f in filas))
    lat = collections.defaultdict(list)
    for f in filas: lat[f['modelo_config']].append(f['latencia_s'])
    res['latencia_media_s'] = {k: round(sum(v)/len(v), 2) for k, v in lat.items()}
    res['sha256_log'] = hashlib.sha256(open(log, 'rb').read()).hexdigest()
json.dump(res, open(sys.argv[2], 'w', encoding='utf-8'), indent=2, ensure_ascii=False)
print(json.dumps(res, indent=2, ensure_ascii=False))
"@
    $pyRes | python - $cfgEnSrc (Join-Path $ev "resumen.json") $dur
}
finally {
    if ($cfgEnSrc -and (Test-Path $cfgEnSrc)) { Remove-Item $cfgEnSrc }  # la copia buena queda en la evidencia
    Set-Location $raiz
    Stop-Transcript | Out-Null
}
