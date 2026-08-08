# Workaround de build en Windows (VS 2026 instala 18.x; flutter pide generador 16 2019).
# Uso: powershell -File tool/run_e2e_windows.ps1
# Genera el build con el cmake de VS instalado y ejecuta los tests de integración E2E.

$ErrorActionPreference = "Stop"

# Detecta el cmake de Visual Studio (18 = 2026, 17 = 2022)
$vsBase = "C:\Program Files\Microsoft Visual Studio"
$cmake = $null
$msbuild = $null
foreach ($vs in @("18", "17")) {
  $c = Join-Path $vsBase "$vs\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe"
  $m = Join-Path $vsBase "$vs\Community\MSBuild\Current\Bin\MSBuild.exe"
  if ((Test-Path $c) -and (Test-Path $m)) { $cmake = $c; $msbuild = $m; break }
}
if (-not $cmake) { Write-Error "No se encontro cmake/MSBuild de Visual Studio"; exit 1 }

$proj = Split-Path -Parent $PSScriptRoot
Write-Host "Proyecto: $proj"
Write-Host "CMake: $cmake"

# 1. Limpiar cache de build windows (evita conflicto de generadores)
if (Test-Path "$proj\build\windows") { Remove-Item -Recurse -Force "$proj\build\windows" }

# 2. Generar con el generador correcto
& $cmake -G "Visual Studio 17 2022" -A x64 -S "$proj\windows" -B "$proj\build\windows\x64" | Out-Host

# 3. Compilar (Debug)
& $msbuild "$proj\build\windows\x64\empresa_dev.sln" /p:Configuration=Debug /p:Platform=x64 | Out-Host

Write-Host ""
Write-Host "=== Ejecutando tests E2E (integration_test) ==="
Write-Host "Este comando usa el build ya generado; si flutter re-genera y falla por VS 16, usa el binario directo."
& flutter test integration_test -d windows 2>&1 | Out-Host

Write-Host ""
Write-Host "=== Fin ==="
