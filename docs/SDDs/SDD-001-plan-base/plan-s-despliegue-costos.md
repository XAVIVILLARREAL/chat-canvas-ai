# PLAN S — Despliegue, Costos y Stack Eficiente (transversal, datos verificados ago-2026)

> [← Maestro](./README.md) · Investiga y fija CÓMO desplegar barato hoy sin bloquear el escalado mañana. Fuentes: investigación con sub-agentes sobre Hetzner/ARM/PaaS/LLM-pricing, stack Rust 2026 y cliente Tauri 2.x.
> **Prerequisito de Etapa 1**: S.1 (hosting) y S.2 (stack servidor) se ejecutan ANTES de arrancar Etapa 1 — el gateway axum sirve la web desde el día 1 y el stack ya está ~70% ejecutado (crates/core + crates/server). S.3 (Tauri) SOLO cuando haya demanda demostrada (WEB-FIRST, [ADR-005](../ADRs/ADR-005-modelo-despliegue-dual.md)); S.4 continuo.

<a id="s1"></a>
## S · 1 — Hosting por etapas con COSTOS REALES

| Etapa | Cuándo | Infra | Costo/mes |
|---|---|---|---|
| **1. MVP** | 1–50 usuarios | 1× Hetzner **CAX21 ARM** (4 vCPU dedicados/8GB, €10.49) todo-en-uno Compose: gateway+workers+Postgres self-hosted (CloudNativePG/pgBackRest) + sandbox ligero | **~$16–26** |
| **2. Crecimiento** | 50–2k usuarios | Separar planos: CAX41 (16vCPU/32GB, €41) orquestador+DB primaria CNPG con standby; workers/sandboxes en segundo nodo ARM (Netcup VPS2000 ARM €13 o CAX extra) | **~$75–110** |
| **3. Escala** | >2k / multi-tenant serio | Dedicado Hetzner AX/RX bare-metal (~$45–50/nodo — NO subió en junio) con Proxmox/K8s para densidad; CNPG 3 nodos; segunda región para HA | **~$250–600** |

Referencia dura: el equivalente gestionado (Fly/Railway/Render con app+DB+egress) cuesta $25–90/mes por MENOS capacidad desde el día 1, y los hyperscalers 4–7× más.

### Reglas de dinero (no negociables)
1. **Los datos NUNCA viven solo en el VPS**: backups WAL+full diarios a **Backblaze B2** ($6.95/TB, egress gratis hasta 3× almacenamiento → 500GB backups ≈ $3.50/mes); artefactos servidos por **Cloudflare R2** (egresos SIEMPRE $0)
2. LLM: DeepSeek V4 Flash como motor diario (**$0.14/$0.28 por M**, cache-hit −98%) + Pro/reasoner solo decisiones difíciles → agente trabajando horas ≈ $10–15/mes
3. ARM64 (Ampere dedicado Hetzner) = mejor MT-per-€ para Rust; evitar líneas CPX/CCX (subidas +170%)
4. Todo reproducible con IaC: el mercado EU subió 30–170% en 10 semanas (DRAM shock) — cero lock-in
5. Contabo/Netcup-shared SOLO para staging/workers tolerantes; jamás el nodo central sin HA

<a id="s2"></a>
## S · 2 — Stack servidor Rust eficiente (versiones fijadas ago-2026)

| Capa | Elección | Nota |
|---|---|---|
| Runtime | tokio 1.52 (LTS 1.51) | dial9 flight-recorder para diagnosticar stalls |
| HTTP | axum 0.8.9 + tower-http | WS sobre HTTP/2, graceful shutdown cubre WS; SSE con CancellationToken |
| DB driver | sqlx 0.9 (macros, offline mode) | compile-time checks sin DB viva en CI |
| KV embebido | redb 4.1 (transaccional) / fjall 3.0 (write-heavy) | sled descartado (estancado) |
| JSON | serde_json default + **sonic-rs en hot-path LLM** (>100KB/payload: ~3× más rápido) | sonic requiere `-C target-cpu=native` |
| Interno binario | postcard (mensajes) / rkyv (cachés read-heavy zero-copy ~5ns) | nunca cruza la frontera HTTP |
| HTTP client | reqwest 0.13 pool único compartido vía Arc | SSE: bytes_stream + parser propio |
| TLS | rustls 0.23 + aws-lc-rs (handshake 1.38× vs OpenSSL) | X25519MLKEM768 post-cuántico incluido |
| Observabilidad | tracing→OTLP batch (~1–2% CPU) + metrics-rs | tenant_id JAMÁS como label Prometheus |
| Imagen | cargo-chef multi-stage → **distroless/static nonroot** (o chainguard) | CA certs+tzdata manuales si scratch |
| Builds rápidos | mold linker + cranelift(debug: 60s→19s) + sccache + workspace granular | incremental <20s |

WebSocket 10k conexiones: KBs por conexión (no MBs) — sobrado en un contenedor pequeño; broadcast acotado + dashmap + Message::Binary + heartbeat.

<a id="s3"></a>
## S · 3 — Cliente Tauri eficiente (patrones obligatorios)

1. **Streaming del agente = Command async + `Channel<TokenEvent>`** (tagged enum, batch coalescido ~30ms en Rust): NO `emit` ni fetch-SSE dentro del webview (iOS pausa todo en background; el stream vive en reqwest/Rust y sobrevive)
2. Payloads grandes (snapshots canva, diffs): `Channel<Vec<u8>>` binario — **11× más rápido @64KB** que JSON IPC; JSON basta para tokens (<1KB)
3. `React.lazy` agresivo para Monaco (~2-3MB) y ReactFlow; virtualización >50 items (WebKitGTK castiga DOM pesado)
4. **Linux = degradación gráfica planificada**: WebKitGTK es el punto débil declarado (DMABUF freezes NVIDIA, animaciones pobres) → menos partículas, DPR cap 1.5, WEBKIT_DISABLE_DMABUF_RENDERER=1 documentado
5. Auto-updater: firma minisignv2 OBLIGATORIA (perder la private key = imposible actualizar) · **no hay delta updates** → sidecars/modelos pesados NUNCA bundled: descarga lazy post-install a $APPDATA con reanudación propia
6. Sidecar worker local (si aplica): spawn + health-check propio (NO hay lifecycle manager oficial, issue #3062); socket Unix para datos, invoke() solo control-plane
7. Móvil fase 2: push vía plugin comunitario (no oficial, issue #11651); deep-link requiere single-instance PRIMERO + parseo argv (bug getCurrent null Win/Linux)
8. Preview iframe: WKWebView ITP rompe cookies cross-origin → contexto por postMessage, no cookies/localStorage

<a id="s4"></a>
## S · 4 — Presupuesto de costos proyectado (visión completa funcionando)

| Concepto | MVP | Escala media |
|---|---|---|
| Servidor(es) | $11.5–23 | $75–110 |
| Backups B2 | $3.5 | $7–14 |
| LLM APIs (agentes horas/día, flash+caching) | $5–15 | $40–120 |
| Dominio/TLS | ~$1 | ~$1 |
| **Total** | **~$21–42/mes** | **~$125–245/mes** |

vs equivalente managed: $400–700/mes. El costo escala LINEAL con uso (tokens) no con arquitectura.

## Pruebas del plan S

- Unit: cálculo costos por scope ([C·C.2](./plan-c-reasonix-deepseek.md#c2)) contra tabla de precios del registro ([C·C.7](./plan-c-reasonix-deepseek.md#c7))
- Integration: restore completo desde backup B2 en máquina limpia ≤30min (drill trimestral automatizado)
- E2E: despliegue Compose desde cero con IaC en VPS limpio ≤15 min
- Humana: operador cambia preset KV/hardware en un click y ve el efecto en memoria real

---
[← Maestro](./README.md)
