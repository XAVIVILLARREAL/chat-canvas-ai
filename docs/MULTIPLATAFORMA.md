# MULTIPLATAFORMA.md — Compilar en cada plataforma

> SDD-005 · Empresa Dev es una sola codebase (ADR-002) que compila para desktop (Windows/macOS/Linux) y mobile (Android/iOS) via Tauri 2.0.

## Requisitos comunes

```bash
pnpm install          # deps frontend
cargo --version       # toolchain Rust
```

## Desktop

| SO | Comando | Salida |
|---|---|---|
| Linux | `pnpm tauri build` | `.deb` / `.AppImage` / `.rpm` |
| Windows | `pnpm tauri build` | `.msi` / `.exe` (NSIS) |
| macOS | `pnpm tauri build --target universal-apple-darwin` | `.app` / `.dmg` universal |

Requisitos por SO (una vez):
- **Linux:** `libwebkit2gtk-4.1-dev libgtk-3-dev libayatana-appindicator3-dev librsvg2-dev patchelf xdotool` (ya instalados en este servidor)
- **Windows:** WebView2 (viene con Win10/11) + Visual Studio Build Tools (C++)
- **macOS:** Xcode Command Line Tools (`xcode-select --install`)

Verificación continua: el job `build-desktop` de CI corre en los 3 SO en cada push.

## Android

Proyecto nativo **versionado** en `src-tauri/gen/android/` — no hace falta regenerarlo.

Una vez por máquina:
1. JDK 17+ y `JAVA_HOME`
2. Android SDK + NDK r27, con env vars:

```bash
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64        # Debian: apt install openjdk-21-jdk-headless
export ANDROID_HOME=/opt/android-sdk                       # cmdline-tools + platforms;android-34 + build-tools;34.0.0
export NDK_HOME=$ANDROID_HOME/ndk/27.0.12077973
rustup target add aarch64-linux-android armv7-linux-androideabi i686-linux-android x86_64-linux-android
```

Compilar APK debug:

```bash
pnpm tauri android build --debug --apk
# salida: src-tauri/gen/android/app/build/outputs/apk/universal/debug/
```

Correr en dispositivo/emulador conectado:

```bash
pnpm tauri android dev
```

Sin toolchain local: GitHub Actions → workflow **"Android Build"** (`workflow_dispatch`) genera un APK debug como artefacto.

## iOS

⚠️ Solo compilable desde macOS/Xcode (requisito de Apple). El proyecto nativo se genera ahí la primera vez:

```bash
rustup target add aarch64-apple-ios x86_64-apple-ios aarch64-apple-ios-sim
pnpm tauri ios init      # una sola vez, en un Mac
pnpm tauri ios build     # o: pnpm tauri ios dev con simulador abierto
```

CI ya declara targets Darwin (`build-desktop`, matriz macos-latest); el proyecto `gen/ios` se versionará cuando se ejecute `ios init` en un Mac.

## Reglas

1. Una sola codebase — nada de forks por plataforma (ADR-002)
2. Adaptación UI via `useResponsive()` (ADR-001), no archivos separados
3. Lógica platform-specific va en Rust (`src-tauri/src/platforms/`), expuesta por comandos Tauri
4. Todo cambio debe seguir compilando en los 3 SO desktop (CI lo verifica)
