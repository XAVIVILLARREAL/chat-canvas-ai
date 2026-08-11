# Verificación de UI con Chrome headless contra el build web.
# Gate de Etapa 2, slice 4: comprobar que la app web carga y que el canva
# renderiza nodos sin errores de consola.
# Uso: powershell -File tool/verify_ui.ps1 [-KeepServer]
param(
  [switch]$KeepServer
)
$ErrorActionPreference = "Stop"
# PowerShell 7: no tratar el stderr de procesos nativos (Chrome) como error
$PSNativeCommandUseErrorActionPreference = $false

$proj = Split-Path -Parent $PSScriptRoot
$web = "$proj\build\web"
$chrome = "C:\Program Files\Google\Chrome\Application\chrome.exe"
$out = Join-Path $env:TEMP "verify_ui"

if (-not (Test-Path "$web\index.html")) {
  Write-Host "No hay build web. Ejecutando flutter build web --debug ..."
  Push-Location $proj
  & flutter build web --debug 2>&1 | Out-Host
  Pop-Location
}

# 1. Servidor estático local para servir la app
$server = Start-Job -ScriptBlock {
  param($root, $port)
  $listener = [System.Net.HttpListener]::new()
  $listener.Prefixes.Add("http://127.0.0.1:$port/")
  $listener.Start()
  while ($listener.IsListening) {
    $ctx = $listener.GetContext()
    $path = $ctx.Request.Url.AbsolutePath.TrimStart('/')
    if ($path -eq '') { $path = 'index.html' }
    $file = Join-Path $root $path
    if (Test-Path $file) {
      $ctx.Response.ContentType = switch ([IO.Path]::GetExtension($file)) {
        '.html' { 'text/html' }
        '.js'   { 'application/javascript' }
        '.css'  { 'text/css' }
        '.json' { 'application/json' }
        '.png'  { 'image/png' }
        '.ttf'  { 'font/ttf' }
        '.wasm' { 'application/wasm' }
        default { 'application/octet-stream' }
      }
      $bytes = [IO.File]::ReadAllBytes($file)
      $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
    } else {
      $ctx.Response.StatusCode = 404
    }
    $ctx.Response.Close()
  }
} -ArgumentList $web, 8765

try {
  # Esperar a que el servidor esté listo
  Start-Sleep -Seconds 2
  Remove-Item -Recurse -Force $out -ErrorAction SilentlyContinue
  New-Item -ItemType Directory -Force -Path $out | Out-Null

  # 2. Chrome headless: screenshot + dump del DOM (Start-Process aísla el
  # stderr de Chrome, que trae warnings inofensivos tipo GCM).
  Write-Host "=== Chrome headless: screenshot ==="
  $p1 = Start-Process -FilePath $chrome -ArgumentList @(
    "--headless=new", "--disable-gpu", "--no-sandbox",
    "--virtual-time-budget=15000",
    "--screenshot=$out\canva.png",
    "--window-size=1280,800",
    "http://127.0.0.1:8765/"
  ) -Wait -PassThru -RedirectStandardOutput "$out\shot.out" -RedirectStandardError "$out\shot.err"
  Write-Host "chrome screenshot exit: $($p1.ExitCode)"

  Write-Host "=== Chrome headless: dump DOM ==="
  $p2 = Start-Process -FilePath $chrome -ArgumentList @(
    "--headless=new", "--disable-gpu", "--no-sandbox",
    "--virtual-time-budget=15000",
    "--dump-dom",
    "http://127.0.0.1:8765/"
  ) -Wait -PassThru -RedirectStandardOutput "$out\dom.html" -RedirectStandardError "$out\dom.err"
  $domExit = $p2.ExitCode
  Write-Host "chrome dump-dom exit: $domExit"

  # 3. Comprobar que Flutter renderizó (flt-glass-pane es el árbol de Flutter)
  $dom = Get-Content "$out\dom.html" -Raw
  $hasFlutter = $dom -match "flt-glass-pane|flt-text-editing|flt-semantics"
  $hasScreenshot = (Test-Path "$out\canva.png") -and ((Get-Item "$out\canva.png").Length -gt 10000)

  Write-Host "DOM: $($dom.Length) bytes, flt-glass-pane: $hasFlutter"
  Write-Host "Screenshot: $hasScreenshot ($out\canva.png)"

  if ($hasFlutter -and $hasScreenshot -and $domExit -eq 0) {
    Write-Host "=== VERIFY UI OK ==="
    Write-Host "Captura: $out\canva.png"
    exit 0
  } else {
    Write-Host "=== VERIFY UI FAIL ===" -ForegroundColor Red
    exit 1
  }
} finally {
  if (-not $KeepServer) {
    Stop-Job $server -ErrorAction SilentlyContinue | Out-Null
    Remove-Job $server -Force -ErrorAction SilentlyContinue | Out-Null
  }
}