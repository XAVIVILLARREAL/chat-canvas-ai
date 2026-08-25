# SDD-007 — Análisis exhaustivo: OpenCode + Models.dev → Registro Universal de Proveedores

> Fecha: 2026-08-23 · Estado: Aprobado · Fuentes: docs.opencode.ai/providers (oficial), github.com/anomalyco/opencode (MIT), models.dev (MIT, mismo equipo)
> Integra y AMPLÍA [C·C.7](./SDD-001-plan-base/plan-c-reasonix-deepseek.md#c7) en la base.

## Cómo funciona el sistema de OpenCode (verificado en docs oficiales)

1. **AI SDK + Models.dev = 75+ proveedores sin código**: el catálogo models.dev da por modelo: contexto, max output, precio in/out por M tokens, soporte reasoning/tools/vision
2. **`/connect` interactivo**: dos vías de credenciales —
   - API key pegada manualmente (DeepSeek, Groq, Together, Fireworks…)
   - **OAuth a SUSCRIPCIONES existentes**: ChatGPT Plus/Pro, Claude Pro/Max, GitHub Copilot (device flow), GitLab Duo, DigitalOcean — usa lo que el usuario YA PAGA
   - Credenciales en `~/.local/share/opencode/auth.json`
3. **Config declarativa** (`opencode.json`): `provider.{id}.options.baseURL` override · `blacklist`/`whitelist` de modelos por proveedor · proveedor CUSTOM vía paquete npm (`@ai-sdk/openai-compatible`) apuntando a cualquier endpoint
4. **Locales first-class**: Ollama, LM Studio, llama.cpp-server, Atomic Chat — todos como openai-compatible con baseURL localhost
5. **`small_model`**: un modelo barato separado para tareas internas (títulos de sesión) — no quemes Opus para nombrar un chat
6. **Gateways con headers custom**: Helicone/Cloudflare AI Gateway — opciones.headers passthrough
7. **Zen/Go**: listas curadas y verificadas por el equipo + plan low-cost

## 🎯 Ideas robadas (14) — todas integradas a C.7

| # | Idea | Dónde |
|---|---|---|
| OC1 | Catálogo models.dev autocompleta precios/contexto/capacidades de 75+ proveedores | C.7·a |
| OC2 | `/connect`: flujo interactivo de credenciales unificado | C.7·b |
| OC3 | **OAuth a suscripciones que el usuario ya paga** (ChatGPT Plus, Claude Pro, Copilot) | C.7·b |
| OC4 | baseURL override → proxies/gateways/azure funcionan sin código | C.7·a |
| OC5 | **blacklist/whitelist de modelos** por proveedor (scope [A.6](./plan-a-chat-codex.md#a6)) | C.7·c |
| OC6 | Proveedor CUSTOM openai-compatible → cualquier endpoint | C.7·a |
| OC7 | Locales first-class: Ollama/LM Studio/llama.cpp/LM-Studio-like | [C.6](./plan-c-reasonix-deepseek.md#c6) ampliado |
| OC8 | **`small_model`** para tareas internas baratas (títulos, resúmenes chicos) | C.7·d — conecta con router [C.6](./plan-c-reasonix-deepseek.md#c6) |
| OC9 | Gateways con headers custom (Helicone/Cloudflare) | C.7·a options.headers |
| OC10 | Lista curada verificada por el equipo (Zen) | C.7·d "Modelos verificados Canvas AI" |
| OC11 | `/models` picker con precio/contexto visible al elegir | C.7·c UI |
| OC12 | auth.json separado del config (credenciales ≠ preferencias) | C.7·b seguridad |
| OC13 | Device flow GitHub/OAuth browser para desktop apps | [M·M.1](./plan-m-github.md#m1) ya previsto; reutilizar mecanismo |
| OC14 | Directorio documentado proveedor-por-proveedor (guía de obtención de key) | P·P.4 plantillas |

## ❌ No copiar

- Acoplamiento a SDK npm de Node (`@ai-sdk/*`): nuestro trait es Rust; los 3 tipos de API cubren el mercado
- Compartir credenciales de suscripción contra ToS (Anthropic lo prohíbe explícitamente): solo OAuth donde el proveedor lo permita oficialmente

## Esquema del registro (contrato)

```jsonc
{
  "id": "openrouter",                    // cualquier string
  "tipo_api": "openai-compat",           // openai-compat | anthropic | google
  "nombre": "OpenRouter",
  "options": {
    "baseURL": "https://openrouter.ai/api/v1",
    "headers": {}                        // gateways/custom
  },
  "auth": { "modo": "api_key|oauth_device|suscripcion_oauth", "key_ref": "settings.cifrada" },
  "modelos": {
    "deepseek/deepseek-v4-flash": {
      "nombre": "DeepSeek V4 Flash",
      "contexto": 1000000, "max_output": 384000,
      "precio_in": 0.28, "precio_out": 0.42,   // USD por M tokens (del catálogo)
      "capacidades": { "tools": true, "reasoning": false, "vision": false }
    }
  },
  "blacklist": [], "whitelist": []
}
```
