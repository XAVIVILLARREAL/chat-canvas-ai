# SDD-005 · Cierre Multiplataforma (Windows / macOS / Android / iOS)

> Fecha: 2026-08-23 · Estado: En ejecución · Precedente: análisis de brechas post-auditoría multiplataforma
> Regla madre: ADR-001 (desktop Win/mac/Linux + mobile Android/iOS desde el día 1) y DoD "probado en 2 plataformas".

## Problema

La arquitectura ES multiplataforma (Tauri 2.0, crate-types `staticlib/cdylib`, iconos android/ios, ADR-001, suite humana Pixel 7), pero **nada lo verifica ni lo materializa**:

| Brecha | Impacto |
|---|---|
| CI solo corre en `ubuntu-latest` | Un commit puede romper compilación Windows/macOS sin que nadie se entere |
| No existe proyecto Android nativo (`src-tauri/gen/android`) | Imposible generar APK; cualquier dev que quiera probarlo en celular parte de cero |
| iOS nunca inicializado | Igual que Android; requiere Mac para compilar pero el proyecto se puede versionar |

## Objetivo

Que "multiplataforma" pase de diseño a **verificado en CI + proyecto Android versionado**, con comandos exactos documentados para iOS.

## Fases y gates

### Fase 1 — Entorno Android del servidor de desarrollo (prefase, no va al repo)

Instalar JDK 17 + Android SDK (cmdline-tools, platform-tools, platforms;android-34, build-tools) + NDK en `/opt/android-sdk`.
**Gate:** `tauri android init` corre sin errores de entorno.

### Fase 2 — Proyecto Android nativo versionado

- `pnpm tauri android init` → genera `src-tauri/gen/android/`
- Versionar el proyecto (respetando los `.gitignore` que Tauri genera dentro)
- **Gate:** `git status` muestra `gen/android` completo; estructura estándar Tauri (`app/`, `buildSrc/`, `settings.gradle`)

### Fase 3 — CI matriz desktop (verificación continua)

Nuevo job `build-desktop` con matriz `[ubuntu-latest, windows-latest, macos-latest]`:

```
pnpm install → typecheck → lint → vitest → cargo test → cargo check (release off) 
```

Se usa `cargo check` (no `tauri build`) para mantener CI rápido (<10 min); el bundling completo queda para release.
**Gate:** los 3 SO en verde en GitHub Actions.

### Fase 4 — Workflow Android opcional (manual)

Job `build-android` disparo solo con `workflow_dispatch` (no en cada push): instala NDK/JDK en runner, corre `tauri android build --debug --apk`, sube artefacto. Evita quemar minutos de CI en cada commit.
**Gate:** workflow válido (actionlint o push + dispatch manual).

### Fase 5 — Documentación

- `docs/MULTIPLATAFORMA.md`: comandos exactos para compilar en cada plataforma (incluye iOS: requiere Mac, pasos `tauri ios init`)
- CHANGELOG (append) + ESTADO.md reescrito + INDEX.md actualizado
- **Gate:** INDEX.md lista el doc nuevo; ESTADO refleja el cierre

## Fuera de alcance (explícito)

- Compilar/firmar APK release o IPA (requiere keystore/certificados Apple — decisión comercial posterior)
- Correr iOS en este servidor (imposible: Xcode solo existe en macOS); se documenta el camino
- Playwright en WebKit móvil real (queda cubierto por viewport Pixel 7 existente)

## Riesgos

| Riesgo | Mitigación |
|---|---|
| Toolchain Android pesa ~2GB en servidor | Disco tiene 104GB libres; instalación bajo `/opt/android-sdk`, documentada |
| CI Windows/macOS lento | Solo checks + tests unitarios, sin bundle |
| `gen/android` genera ruido en diffs | Respetar `.gitignore` interno generado por Tauri |

## Contrato de éxito (DoD)

- [ ] `src-tauri/gen/android/` versionado en main
- [ ] CI verde en ubuntu + windows + macos (job matriz)
- [ ] Workflow Android manual disponible (`workflow_dispatch`)
- [ ] `docs/MULTIPLATAFORMA.md` con comandos por plataforma
- [ ] Suite local verde completa (typecheck/lint/oxlint/knip/vitest/build/e2e humano)
