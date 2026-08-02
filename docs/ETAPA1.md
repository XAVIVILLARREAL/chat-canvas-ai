# ETAPA 1 — Canva de diagramas con ventanitas de agente (construir primero)

> **Qué se construye primero** (antes que el resto del producto): un **canva libre para crear esquemas y diagramas** (nodos, cajas, flechas, notas), donde **insertas "ventanitas"** que al hacer clicks/touch **abren un chat/sesión con un agente de código estilo terminal** (como opencode / antigravity / goose).

## Por qué primero

Es la sección que falta y la que todos los demás espacios usan:

- El **canva** permite pensar visualmente el proyecto (arquitectura, flujos, módulos) y **colocar agentes en el diagrama**: "aquí voy a necesitar un agente que implemente la API", "aquí un bug a investigar".
- Cada ventanita ya conectada a un agente real = la app se vuelve útil el día 1.
- Todo lo demás (kanban, Chrome DevTools MCP, LangGraph) se construye **alrededor de esta base**.

## Qué siente el usuario (UX)

1. Abre un proyecto → **canva infinito, zoom, arrastrar** (igual que CanvaDev).
2. Dibuja libremente: cajas de texto, notas, flechas, colores, contenedores de proyecto.
3. Inserta una **ventanita de agente** desde un menú (o por voz: "pon un agente de flutter aquí").
4. La ventanita es una **caja en el canva** con mini-vista del agente (estado en vivo).
5. Click o touch en la ventanita → **se abre a pantalla** (responsive): es una **ventana de chat estilo terminal** (tipo opencode):
   - Streaming de tokens.
   - Log en vivo de herramientas (lee/edita/corre/terminal).
   - Código con resaltado, botón de ejecutar.
   - Permisos/parar/continuar (nivel de permisos conservador al inicio).
6. Cerrar → vuelve a su posición en el canva; sigue corriendo en segundo plano (server-side) y la mini-vista muestra avance.

## La "ventana del agente" — qué hay detrás

Cada ventanita = **una sesión de un agente** corriendo en el servidor, en un **directorio de trabajo real** de un proyecto:

- El motor del agente corre del lado del servidor (responde pero también **actúa**).
- La ventanita es el **visor remoto** (WebSocket), no la lógica.
- Puedes tener decenas de ventanitas en el canva, varias sesiones a la vez.

## Elección del motor de agente (decisión CENTRAL — tomada)

> **DECISIÓN: Forkear opencode (MIT) y construir nuestro propio chat de agente WEB (no terminal) sobre su núcleo.**

No vamos a integrar opencode "tal cual". Vamos a **partir de su código** (licencia MIT: se puede modificar, usar y vender) y construir encima **nuestra propia interfaz web** de chat de agente, cambiándola al gusto.

### Qué es opencode por dentro (lo que tomamos)

| Pieza | ¿La tomamos? | Por qué |
|---|---|---|
| **Core del agente** (loop, tools, MCP, sesiones) | ✅ Sí | La lógica del agente ya hecha y probada |
| **Capa LLM** (multi-modelo: Claude, GPT, local…) | ✅ Sí | Sin vendor lock-in |
| **Server headless/API + WebSocket** | ✅ Sí | Es el puente para nuestro frontend web |
| **TUI (terminal UI)** | ❌ No | Justo lo que no queremos: nosotros hacemos UI web |
| **Cliente web de opencode** (`opencode web`) | ⚠️ Referencia | Lo usamos de referencia/diseño, pero hacemos la nuestra |

### Cómo lo haremos (plan de fork)

```
Tu repo (fork, MIT):
  ├─ MÓDULOS PROPIOS:
  │   ├─ chat-web/          → nuestra UI web del chat de agente (React, la "ventanita")
  │   └─ más adelante: canva + kanban + ventanitas
  └─ MÓDULOS DE opencode (heredados del fork):
      ├─ core/     (bucle agente + tools + MCP)
      ├─ llm/      (multi-modelo)
      └─ server/   (API headless + WebSocket → conecta la UI web)
```

1. **Fork del repo de opencode** (clone + nueva remote en tu GitHub).
2. **Descartar la UI de terminal** (TUI) como interfaz principal.
3. Mantener `core + llm + server` casi intactos al inicio → garantiza que el agente "funciona igual que opencode" (ya probado).
4. Construir **nuestra UI web** sobre `server` vía API + WebSocket (SDK de opencode o llamadas directas).
5. Personalización progresiva: branding, modo oscuro, ventanitas, voz, canvas, permisos, modelos.

### Por qué funciona esta decisión

- **MIT**: forkeamos, modificamos y vendemos sin peaje.
- **Balance perfecto**: no partimos de cero (el agente ya funciona), pero el producto final es **nuestro** (nuestra UI, nuestra marca, nuestro flujo).
- **Velocidad**: llegamos a la "ventanita web" en días, no meses, enfocándonos en lo que nos diferencia: el canva + la UX web + (más adelante) LangGraph y la verificación visual.

> ⚠️ **Atribución MIT:** obligatorio conservar el aviso de licencia (LICENSE) y dar crédito a opencode en el README/About. No impide customizar ni comercializar.

## Arquitectura de la Etapa 1

```
Nuestra UI web (canva + ventanita de chat) ← MÓDULO PROPIO
     │  WebSocket (eventos en vivo: tokens, tools, estado)
     ▼
Nuestro server (Node/TS) ── lanza/gestiona sesiones
     │
     ▼
Fork opencode (core + llm + server)  ──► directorios de trabajo reales
     │  (MCP: filesystem, shell, node, terminal)
     └─ (Fase 2: añadir orquestador LangGraph sobre el core)
```

- **Canva**: React Flow (xyflow). Nodos personalizados: cajas de esquema + **nodos "ventanita de agente"** (con mini-estado y botón de abrir).
- **Ventanita/Ventana**: el chat del agente. Estilo terminal moderno (líneas de prompt, monospace, colores), streaming + logs de tools + perm para acciones que necesitan aprobación.
- **Server**: lanza una sesión de opencode per ventanita (`opencode serve`), en el dir de trabajo del proyecto. WebSocket hace bridge del streaming a la UI.
- **Persistencia**: posiciones del canva, contenidos de cajas, conexiones, y referencias de sesión (SQLite). La sesión del agente en sí vive server-side (streaming), la desvinculación es solo referencia.

## UX mínima de la ventana (imagen mental)

```
┌────────────────────── VENTANITA DE AGENTE ──────────────────────┐
│ [•] Implementación API-auth   (flutter)   [—]   [↗]  [✕]        │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ jestea@user: ~/proyecto/modelo                              │ │
│ │ > crea el endpoint /login con validación y su test          │ │
│ │                                                             │ │
│ │ [✓] read model/user.ts                                       │ │
│ │ [✓] write src/api/auth.ts  (+N lines)                        │ │
│ │ [▶] npm test -- auth                                         │ │
│ │     PASS 5 tests                                             │ │
│ │ Texto resumen del agente…                 ├──[infl]──────►  │ │
│ └─────────────────────────────────────────────────────────────┘ │
│ [ Mensaje al agente…                          ]  [➜]  [🎤]     │
└──────────────────────────────────────────────────────────────────┘
```

## Criterios de aceptación de la Etapa 1

- [ ] Canva libre: crear cajas/notas, conectores, colores, zoom/arrastrar, responsive (touch en el cel).
- [ ] Se inserta una ventanita de agente y **abre una sesión real** de agente al click/tocar.
- [ ] La ventana chat funciona estilo terminal: streaming, logs de tools, código coloreado, respuesta en voz (opcional inicio).
- [ ] Varias ventanitas → varias sesiones a la vez (cada una en su directorio real).
- [ ] La sesión continua aunque cierre la ventanita (minimiza; mini-estado en el canva).
- [ ] Funciona en móvil y desktop (PWA).
- [ ] Haptic o flashes visuales en hitos del agente.
- [ ] Acción peligrosa pide aprobación; nivel de permisos conservador al inicio (configurable).

## Después de la Etapa 1 (en el ROADMAP)

El resto del plan (kanban/empresa, Chrome DevTools MCP, LangGraph multi-agente) se construye **sobre** este canva: el kanban verá los tickets, el UI Tester usará las mismas ventanas para verificar, y el orquestador LangGraph lanzará agentes que aparecen como ventanas en el canva.

