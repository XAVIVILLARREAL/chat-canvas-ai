# Captura de pantalla de la ventana de la app durante el E2E (evidencia Etapa 5-3D).
# Uso: powershell -File tools/capture_app.ps1
param(
    [int]$WaitSeconds = 30,
    [string]$OutDir = "data\evidence\etapa5-3d"
)
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$out = Join-Path (Get-Location) $OutDir
New-Item -ItemType Directory -Force -Path $out | Out-Null

# espera a que la app (sshpro) tenga ventana visible
$started = Get-Date
$hwnd = [IntPtr]::Zero
while (((Get-Date) - $started).TotalSeconds -lt 90) {
    $p = Get-Process -Name "sshpro" -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
    if ($p) { $hwnd = $p.MainWindowHandle; break }
    Start-Sleep -Milliseconds 500
}
if ($hwnd -eq [IntPtr]::Zero) { Write-Output "NO se encontro ventana sshpro"; exit 1 }

Write-Output "Ventana encontrada; capturando cada 2s durante $WaitSeconds s"
$shot = 0
$end = (Get-Date).AddSeconds($WaitSeconds)
while ((Get-Date) -lt $end) {
    $shot++
    $bmp = New-Object System.Drawing.Bitmap([System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Width, [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Height)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.CopyFromScreen(0, 0, 0, 0, $bmp.Size)
    $file = Join-Path $out ("shot-{0:D2}.png" -f $shot)
    $bmp.Save($file, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $bmp.Dispose()
    Write-Output "guardado $file"
    Start-Sleep -Seconds 2
}
Write-Output "DONE"
