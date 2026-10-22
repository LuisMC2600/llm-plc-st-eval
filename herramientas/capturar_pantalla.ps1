<#
.SYNOPSIS
  Captura de pantalla con registro de evidencia (tesis LLMs + PLC, FIE-UTP).

.DESCRIPTION
  Guarda un PNG con fecha y hora en la carpeta indicada y añade una fila a
  INDICE_CAPTURAS.csv (fecha, etiqueta, archivo, SHA-256). Por defecto captura
  todos los monitores; con -Ventana captura solo la ventana en primer plano.
  Compatible con Windows PowerShell 5.1 y PowerShell 7.

.EXAMPLE
  .\herramientas\capturar_pantalla.ps1 -Etiqueta "dryrun gemini" -Carpeta evidencias\fase4
  .\herramientas\capturar_pantalla.ps1 -Etiqueta "veredicto B1 en CODESYS" -Ventana -Retardo 3
#>
param(
    [Parameter(Mandatory = $true)][string]$Etiqueta,
    [string]$Carpeta = "evidencias\manual",
    [switch]$Ventana,
    [int]$Retardo = 0
)
$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
if (-not ("Captura.Win32" -as [type])) {
    Add-Type -Namespace Captura -Name Win32 -MemberDefinition @'
[DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
[DllImport("user32.dll")] public static extern System.IntPtr GetForegroundWindow();
[DllImport("user32.dll")] public static extern bool GetWindowRect(System.IntPtr hWnd, out RECT rect);
[System.Runtime.InteropServices.StructLayout(System.Runtime.InteropServices.LayoutKind.Sequential)]
public struct RECT { public int Left; public int Top; public int Right; public int Bottom; }
'@
}
# Resolucion real en pantallas con escalado (125 %, 150 %...)
[void][Captura.Win32]::SetProcessDPIAware()

if ($Retardo -gt 0) { Start-Sleep -Seconds $Retardo }

if ($Ventana) {
    $h = [Captura.Win32]::GetForegroundWindow()
    $r = New-Object Captura.Win32+RECT
    [void][Captura.Win32]::GetWindowRect($h, [ref]$r)
    $x = $r.Left; $y = $r.Top; $w = $r.Right - $r.Left; $hgt = $r.Bottom - $r.Top
} else {
    $vs = [System.Windows.Forms.SystemInformation]::VirtualScreen
    $x = $vs.Left; $y = $vs.Top; $w = $vs.Width; $hgt = $vs.Height
}

New-Item -ItemType Directory -Force -Path $Carpeta | Out-Null
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$slug = ($Etiqueta -replace '[^\w\-]+', '_').Trim('_')
$archivo = Join-Path $Carpeta ("{0}_{1}.png" -f $stamp, $slug)

$bmp = New-Object System.Drawing.Bitmap $w, $hgt
$g = [System.Drawing.Graphics]::FromImage($bmp)
try {
    $g.CopyFromScreen($x, $y, 0, 0, $bmp.Size)
    $bmp.Save($archivo, [System.Drawing.Imaging.ImageFormat]::Png)
} finally {
    $g.Dispose(); $bmp.Dispose()
}

$hash = (Get-FileHash -Algorithm SHA256 -Path $archivo).Hash.ToLower()
$indice = Join-Path $Carpeta "INDICE_CAPTURAS.csv"
if (-not (Test-Path $indice)) { "fecha,etiqueta,archivo,sha256" | Out-File -FilePath $indice -Encoding utf8 }
('{0},"{1}",{2},{3}' -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Etiqueta.Replace('"', "'"), (Split-Path $archivo -Leaf), $hash) |
    Out-File -FilePath $indice -Append -Encoding utf8

Write-Host ("[captura] {0}  ({1}x{2})  sha256={3}" -f $archivo, $w, $hgt, $hash.Substring(0, 16))
