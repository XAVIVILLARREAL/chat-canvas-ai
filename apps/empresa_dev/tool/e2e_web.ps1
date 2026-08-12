# E2E web del flujo crítico con Playwright (Etapa 7, SDD-120).
# Build web (con semántica E2E) -> servidor estático -> npx playwright test.
# Uso: powershell -File tool/e2e_web.ps1 [-SkipBuild] [-KeepServer]
param(
  [switch]$SkipBuild,
  [switch]$KeepServer
)
$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $false

$proj = Split-Path -Parent $PSScriptRoot
$web = "$proj\build\web"

if (-not $SkipBuild -or -not (Test-Path "$web\index.html")) {
  Write-Host "=== flutter build web (E2E_WEB=true) ==="
  Push-Location $proj
  & flutter build web --debug --dart-define=E2E_WEB=true 2>&1 | Out-Host
  if ($LASTEXITCODE -ne 0) { Write-Host "build falló" -ForegroundColor Red; exit 1 }
  Pop-Location
}

# Servidor estático local (patrón verify_ui.ps1)
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
  Start-Sleep -Seconds 2
  Write-Host "=== Playwright: e2e_web.spec.js ==="
  Push-Location "$proj\tool"
  if (-not (Test-Path "node_modules\@playwright")) {
    Write-Host "Instalando dependencias de tool/ (una vez)..."
    npm install 2>&1 | Out-Host
  }
  & npx playwright test 2>&1 | Out-Host
  $exit = $LASTEXITCODE
  Pop-Location
  Write-Host "playwright exit: $exit"
  if ($exit -eq 0) {
    Write-Host "=== E2E WEB OK ==="
    exit 0
  } else {
    Write-Host "=== E2E WEB FAIL ===" -ForegroundColor Red
    exit 1
  }
} finally {
  if (-not $KeepServer) {
    Stop-Job $server -ErrorAction SilentlyContinue | Out-Null
    Remove-Job $server -Force -ErrorAction SilentlyContinue | Out-Null
  }
}
