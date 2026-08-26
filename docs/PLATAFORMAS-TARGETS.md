# PLATAFORMAS-TARGETS — Qué se instala dónde (matriz canónica)

> **Producto:** Canvas AI · **Estado:** v1.0 · 2026-08-25 · Base: [ADR-006](./ADR-006-vision-hibrida-local-nube.md), [MULTIPLATAFORMA](./MULTIPLATAFORMA.md)
> **Respuesta a la pregunta:** el plan construye **ambos lados** — el **servidor Linux 24/7** (nube de pago) Y los **clientes instalables** en Windows, macOS, Linux, Android e iOS (local-first, gratis). Esta matriz es la fuente de verdad de entregables por plataforma.

## 1 · Modelo de despliegue (2 caras)

```
LOCAL-FIRST (gratis, BYOK)                        NUBE (de pago, 24/7)
┌──────────────────────────────┐                  ┌──────────────────────────────┐
│ Cliente instalable           │                  │ Servidor Linux               │
│ Windows · macOS · Linux      │  sync (Pro)     │ Gateway axum + Workers       │
│ Android · iOS                │◀──────────────▶ │ + Postgres+RLS + Sandbox     │
│ = la misma app Tauri/React   │                 │ = "lo que corre 24/7"        │
└──────────────────────────────┘                  └──────────────────────────────┘
   agentes corren EN TU máquina                      agentes corren EN EL servidor
   datos en SQLite local                             datos en Postgres (RLS)
```

## 2 · Matriz de entregables (qué se instala/despliega en cada destino)

| Destino | Qué se instala | Artefacto | Runtime | Estado | Verificación |
|---|---|---|---|---|---|
| **Servidor Linux (nube 24/7)** | Gateway axum + workers + Postgres + sandbox | imágenes Docker + `docker-compose.yml` + runbook | Rust (axum) + Postgres | 🚧 Etapa 10 (plan-s) | deploy ≤15 min desde cero · RTO ≤1h |
| **Windows** | App desktop Canvas AI | `.msi` / `.exe` (NSIS) | Tauri 2 + WebView2 | ✅ CI `build-desktop` | auto-update firmado (S.3) |
| **macOS** | App desktop (universal, notarizada) | `.app` / `.dmg` (universal) | Tauri 2 + WKWebView | ✅ CI `build-desktop` | notarización Apple |
| **Linux desktop** | App desktop | `.AppImage` / `.deb` / `.rpm` | Tauri 2 + WebKitGTK | ✅ CI `build-desktop` | degradación gráfica planificada |
| **Android** | App móvil (BYOK, local-first) | `.apk` / `.aab` (Play Store) | Tauri mobile (`gen/android` versionado) | ✅ gen existe · 🚧 release | `android-build.yml` (APK debug) |
| **iOS** | App móvil (BYOK, local-first) | `.ipa` (App Store) | Tauri mobile (`gen/apple` pendiente) | 🔲 **faltante: generar en un Mac** | `tauri ios init` 1 vez + CI |
| **Web / PWA** | SPA ligera (acceso lectura/light) | build estático servido por gateway | React (mismo bundle) | 🚧 Etapa 10 | n/a |

## 3 · Qué corre en cada destino (cómputo client-first)

| Capacidad | En el cliente (local-first) | En el servidor (nube) |
|---|---|---|
| Agentes | spawn local + Ollama | workers Linux 24/7 |
| LLM | BYOK (tu key, keychain) | BYOK (tu key, cifrada por tenant) |
| Datos | SQLite local | Postgres+RLS |
| Sandbox de código | contenedor local (Docker/WASM fallback) | contenedor Linux provisionado |
| Canvas/editor/Monaco | cliente (WASM) | cliente (WASM) — el servidor no paga CPU del usuario |
| Sync | — | solo suscriptores (Pro/Teams) |
| Push (móvil) | — | fase 2 (plugin comunitario, S.3) |

## 4 · Orden de construcción (en el roadmap)

- **MVP-1** — desktop (Windows/macOS/Linux) compilando + servidor en dev local. Mobile NO bloquea.
- **MVP-3** — **servidor nube 24/7 desplegado** + **Android** en tienda + **iOS** (gen/apple + build en Mac) + **web/PWA**. Los clientes móviles son la **misma app** (BYOK + sync para suscriptores), no apps separadas.

## 5 · Reglas por plataforma

1. **Una sola codebase** — nada de forks por SO (ADR-002); adaptación con `useResponsive()`.
2. **Windows/macOS/Linux** se verifican en cada push (CI `build-desktop`).
3. **Android**: proyecto nativo **versionado** (`src-tauri/gen/android/`), no se regenera.
4. **iOS**: requiere un **Mac** para `tauri ios init` (proyecto `gen/apple` se versiona entonces). Es el ÚNICO entregable pendiente de generar.
5. **Linux server**: IaC reproducible (Compose/Proxmox), backups B2, RLS probada de verdad (plan-s).
6. **El web/PWA** es acceso ligero; el producto completo es la app instalada.

## 6 · Estado de los entregables hoy

| Target | ¿Se construye hoy? |
|---|---|
| Server Linux | Parcial (crates/server + worker compilan; deploy es Etapa 10) |
| Windows / macOS / Linux desktop | ✅ (CI `build-desktop` en 3 SO) |
| Android | ✅ (gen/android versionado + workflow APK debug) |
| **iOS** | 🔲 Falta `tauri ios init` en un Mac (gen/apple) |
| Web/PWA | Parcial (SPA sirve por gateway) |
