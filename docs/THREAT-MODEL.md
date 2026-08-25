# THREAT-MODEL — Modelo de amenazas, sandbox Linux y flujo BYOK

> **Producto:** Canvas AI · **Estado:** v1.0 · 2026-08-25 · Base: [ADR-006](./ADRs/ADR-006-vision-hibrida-local-nube.md), [plan-t](./SDDs/SDD-001-plan-base/plan-t-excelencia.md#tsec)
> **Alcance:** las 3 capas (gateway, sandbox, cliente) + el activo más sensible (la **API key BYOK** del usuario).

---

## 1 · Activos y confianza

| Activo | Sensibilidad | Dónde vive |
|---|---|---|
| API keys del usuario (BYOK) | 🔴 crítica | keychain OS (local) / vault cifrado por tenant (nube) |
| Código y diffs | 🔴 alta | disco local / Postgres cifrado en reposo |
| Prompts/conversaciones | 🟠 media | SQLite local / Postgres (RLS) |
| Skills `.md` | 🟠 media | SQLite local / Postgres |
| Telemetría | 🟢 baja | local, opt-in export |

**Frontera de confianza (regla dura):** el webview y el bundle **nunca** contienen ni reciben secretos en claro. Todo lo sensible pasa por Rust (Tauri command / gateway), nunca por JS.

## 2 · Modelo por capa

### Capa Cliente (webview/frontend)
| Amenaza | Mitigación |
|---|---|
| XSS vía respuesta del agente (markdown malicioso) | Markdown sanitizado (DOMPurify-style) + CSP estricta del webview + `react-markdown` sin dangerouslySetInnerHTML |
| Exfiltración de datos al preview | Preview en iframe **sandbox** (`sandbox="allow-scripts"` sin allow-same-origin), postMessage como único canal, sin cookies/localStorage |
| Script injection por skill importado | `tools_allowlist` saneada al importar + firma del bundle verificada |
| Path traversal al leer archivos del workspace | Validación de rutas server-side (rechaza `..`, symlinks fuera de raíz) — suite anti path-traversal en B/H |
| Keys en el bundle | Jamás: el secreto solo existe en keychain/vault Rust; el frontend ve `key_ref`, no la key |

### Capa Sandbox (código que ejecutan los agentes) — patrón GrokBot
| Amenaza | Mitigación (frontera numérica) |
|---|---|
| Código malicioso del agente | **Contenedor Linux (Ubuntu)** por tarea; **red DENEGADA por defecto** (namespace net aislado; solo salida opt-in a allowlist) |
| Fuga de memoria/disco | Limits: **CPU 1 core · RAM 512 MB · disco 1 GB · pids 128 · timeout 60 s** (configurable por skill) |
| Lectura del host | mounts **read-only** de solo lo necesario; /workspace es copia, no bind del host |
| Escalamiento | usuario **non-root**, sin capabilities, `no-new-privileges`, seccomp default |
| Persistencia maliciosa | cada tarea = contenedor efímero; el estado útil vuelve como snapshot versionado (H.9b) |
| Destrucción de datos | `--read-only` en la raíz del contenedor; solo un tmpfs desechable |

### Capa Gateway/Servidor (nube)
| Amenaza | Mitigación |
|---|---|
| Acceso cross-tenant | **RLS fail-closed** (Postgres): sin `tenant_id` → 0 filas; `app.actor_type`/`actor_id` de Ory Kratos |
| Secretos en claro en DB | `providers.key_ref` apunta al vault; **envelope AES-GCM por tenant** (KEK maestra en KMS/env; DEK por tenant en tabla cifrada) |
| Workers comprometidos | workers **sin credenciales de DB** (Everruns: claim `SKIP LOCKED` vía gateway), sin red saliente salvo allowlist, sin docker socket |
| LLM poisoning / prompt injection | shield de entrada (patrón P0 del ERP): fail-closed en tool-calls, fail-open en chat |
| Logs con PII | `tracing`→OTLP batch; `tenant_id` jamás como label Prometheus ([plan-s](./SDDs/SDD-001-plan-base/plan-s-despliegue-costos.md#s2)) |

## 3 · Flujo BYOK (trae tu API key)

```
Local-first:
  usuario pega key → comando Tauri → crate keyring (keychain del OS)
  → key_ref = "keyring:service=canvas-ai,account=<provider-id>"
  → el runtime Rust lee la key SOLO en memoria al invocar el provider
  → el webview NUNCA la ve; solo muestra "conectado ✅"

Nube (suscripción):
  usuario pega key → gateway → DEK_tenant = random 32B
  → cifra key con AES-256-GCM(DEK_tenant) → guarda ciphertext + key_ref en vault
  → KEK_maestra en env/KMS; DEK_tenant cifrada con KEK y guardada por tenant
  → el worker solicita descifrado vía gateway (nunca recibe KEK ni DEK en claro persistente)
  → rotación: re-cifrar con DEK nueva; revocación por tenant inmediata
```

**Reglas BYOK**
1. La key **jamás** viaja al webview, al bundle ni a logs.
2. Al pegar la key, validar contra el provider **antes** de guardarla (roundtrip mínimo).
3. Scanner de secretos antes de enviar contexto al proveedor (si el usuario pega otra key en el chat, se redacta y se avisa) — [C·C.7](./SDDs/SDD-001-plan-base/plan-c-reasonix-deepseek.md).
4. Guardrail por sesión/día (budget) **aplica a nivel de runtime**, no confía en la UI.

## 4 · Security.txt + supply chain (T.SEC)

- `cargo-audit` + `cargo-deny` + SBOM (cyclonedx) en CI; dependencias pineadas con checksums.
- `security.txt` y política de divulgación responsable en el repo (contacto + PGP).
- Modelo de amenazas por capa: **este documento** es la referencia viva; se re-certifica en cada release (GATE T).

## 5 · Verificación (gates)

- **H.9a**: spawn/kill/timeout del contenedor + red denegada verificada (chaos: matar contenedor a mitad → agente se recupera).
- **T.SEC**: intento de XSS vía respuesta del agente → neutralizado; suite path-traversal completa verde.
- **BYOK**: la key cifrada no aparece en `sqlite` dump en claro; cambiar de dispositivo en nube no expone la key del otro tenant.
