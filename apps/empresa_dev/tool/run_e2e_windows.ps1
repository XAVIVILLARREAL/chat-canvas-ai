# Ejecuta el ciclo E2E en Windows (build + tests de integración).
# El parche de VS 2026 en flutter_tools ya está aplicado, así que
# `flutter build`/`flutter test` funcionan directamente.
# Uso: powershell -File tool/run_e2e_windows.ps1
$ErrorActionPreference = "Stop"

$proj = Split-Path -Parent $PSScriptRoot
Write-Host "Proyecto: $proj"

# 1. Limpiar build de windows (evita caches de generador)
if (Test-Path "$proj\build\windows") { Remove-Item -Recurse -Force "$proj\build\windows" }

# 2. Build release (verifica que compila)
Write-Host "=== Build release ==="
& flutter build windows --release 2>&1 | Out-Host

# 3. Copiar la llave de test al directorio del exe (para conexión SSH local)
$rel = "$proj\build\windows\x64\runner\Release"
New-Item -ItemType Directory -Force -Path "$rel\test\fixtures" | Out-Null
Copy-Item "$proj\test\fixtures\app_test_key" "$rel\test\fixtures\app_test_key" -Force

# 4. Tests E2E (integration_test) en Windows
Write-Host "=== Tests E2E ==="
& flutter test integration_test -d windows 2>&1 | Out-Host

# 5. Tests unitarios
Write-Host "=== Tests unitarios ==="
& flutter test --exclude-tags integration 2>&1 | Out-Host

Write-Host ""
Write-Host "=== Ciclo /dev completado ==="
