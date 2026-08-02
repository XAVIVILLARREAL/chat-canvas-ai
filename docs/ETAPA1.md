# ETAPA 1 — Canva de diagramas con ventanitas de agente (construir primero)

> **Qué se construye primero** (antes que el resto del producto): un **canva libre para crear esquemas y diagramas** (nodos, cajas, flechas, notas), donde **insertas "ventanitas"** que al hacer click/touch **abren un chat/sesión con un agente de código estilo terminal** (como opencode / antigravity / goose).
>
> **El corazón de la Etapa 1 son 3 cosas:**
> 1. **El canva es el mapa de todas tus sesiones** — siempre a la mano, cambias de conversación en un clic.
> 2. **Voz (STT/TTS) en cada ventanita** — hablas con la IA *sin abrir* la conversación.
> 3. **Screenshot de evidencia en cada prompt** — la IA te muestra capturas de lo que hizo y las pruebas de que lo resolvió.

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
7. **El canva SIEMPRE es el mapa de sesiones:** todas las ventanitas visibles de un vistazo, mini-estado (pensando / esperando / listo / error / CI), y cambiar de conversación = un clic en otra ventanita. Nunca pierdes el contexto general.
8. **Hablar sin abrir:** cada ventanita tiene botón de micrófono y altavoz — le dictas (STT) y te responde por voz (TTS) **sin abrir la ventana**. La conversación por voz queda registrada en la sesión (transcripción visible al abrir).
9. **Evidencia en cada prompt:** cada vez que la IA responde, adjunta **screenshots** de lo que hizo (código, terminal, navegador, tests) y el resultado de las pruebas — ves si resolvió o no lo que ordenaste, sin adivinar.

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

## Voz en cada ventanita (STT/TTS) — feature central

Poder hablar con la IA **sin abrir la conversación** es uno de los 3 pilares de la Etapa 1. El canva es un "walkie-talkie de agentes".

### Flujo de voz

1. Toca el **🎤** de una ventanita → el micrófono captura tu voz.
2. **STT** (speech-to-text): tu audio se transcribe (en el servidor o navegador, según configuración).
3. El texto entra a la sesión del agente como un mensaje normal.
4. El agente procesa y **responde por voz (TTS)** — y su respuesta también queda como texto en la sesión.
5. Puedes seguir una conversación completa **sin abrir la ventanita**: mini-hilos de voz por nodo.

### Tecnología de voz (opciones)

| Paso | Opción A (local, gratis) | Opción B (servidor/API) | Decisión |
|---|---|---|---|
| **STT** | Web Speech API del navegador (nativo, sin costo) | **Whisper** local en el servidor (mejor precisión, idioma español fuerte) | Whisper en servidor para calidad; fallback Web Speech API |
| **TTS** | Web Speech API `speechSynthesis` (voces del navegador) | **TTS local en servidor** (p.ej. Piper/Coqui/Kokoro) o API (OpenAI TTS, Edge TTS) | Servidor para voz natural; fallback navegador |
| **Transporte** | — | WebSocket (audio streaming) | WebSocket |

- El servidor ya tiene **ollama** corriendo → opción de STT/TTS local de verdad (Whisper vía llama.cpp u ollama, Kokoro/Piper para TTS).
- **Latencia:** el objetivo es conversación natural (<1s a empezar la respuesta). Streaming de audio en vez de esperar el audio completo.
- **Privacidad:** el audio se procesa en tu propio servidor (no se manda a terceros) si usamos Whisper/TTS local.

### Reglas de voz

- El micrófono es **opt-in por ventanita** y se indica visualmente (botón activo, onda de audio).
- Detección de fin de frase (VAD) para no grabar de más.
- La **transcripción siempre queda en la sesión** — la voz nunca reemplaza el registro de texto.
- Si el navegador no soporta audio → fallback a texto normal (la ventanita siempre funciona).

## Screenshot de evidencia en cada prompt — feature central

Cada respuesta del agente puede adjuntar **evidencia visual**: lo que hizo y las pruebas de que resolvió lo ordenado.

| Qué se captura | Cómo | Cuándo |
|---|---|---|
| Código editado | diff + resaltado en la ventanita | al escribir/editar |
| Salida de terminal/comandos | log en vivo + captura del bloque | al ejecutar |
| **UI del proyecto** | **Chrome headless (MCP Chrome DevTools)** → screenshot real | cuando cambia la app/navega |
| Tests | salida de `npm test` / runner | al correr la suite |
| Resultado final | comparación "antes/después" si aplica | fin del turno |

- Cada screenshot se **guarda en la sesión** y se muestra en la ventanita como una "tarjeta de evidencia".
- La ventanita muestra **veredicto visual**: ✅ resolvió / ❌ falló (con captura del error) — como el UI Tester del pipeline, pero integrado en cada prompt.
- Es el puente directo hacia la Fase 3 (Chrome DevTools MCP): lo que empieza como "screenshot por prompt" madura a "UI Tester automático".
- **En voz:** cuando respondes por TTS y hay evidencia, la IA puede decir "listo, lo resolví — mira la captura" y la captura queda en la ventanita para cuando la abras.

## UX mínima de la ventana (imagen mental)

```
┌────────────────────── VENTANITA DE AGENTE ──────────────────────┐
│ [•] Implementación API-auth   (flutter)   [🎤] [🔊] [↗] [✕]     │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ jestea@user: ~/proyecto/modelo                              │ │
│ │ > crea el endpoint /login con validación y su test          │ │
│ │                                                             │ │
│ │ [✓] read model/user.ts                                       │ │
│ │ [✓] write src/api/auth.ts  (+N lines)                        │ │
│ │ [▶] npm test -- auth                                         │ │
│ │     PASS 5 tests                                             │ │
│ │ Texto resumen del agente…                 ├──[infl]──────►  │ │
│ │ ┌─ 📷 EVIDENCIA ──────────────────────────────────────────┐ │ │
│ │ │ ✅ Tests pasaron · captura de la UI con el login        │ │ │
│ │ └─────────────────────────────────────────────────────────┘ │ │
│ └─────────────────────────────────────────────────────────────┘ │
│ [ Mensaje al agente…                          ]  [➜]  [🎤]     │
└──────────────────────────────────────────────────────────────────┘
```

En el **canva** (sin abrir): cada ventanita muestra mini-estado + botones 🎤 (hablar) y 🔊 (oír respuesta), y una miniatura de la última captura de evidencia.

## Criterios de aceptación de la Etapa 1

- [ ] Canva libre: crear cajas/notas, conectores, colores, zoom/arrastrar, responsive (touch en el cel).
- [ ] **El canva es el mapa de sesiones:** todas las ventanitas visibles con mini-estado; cambiar de conversación = un clic sin perder contexto.
- [ ] Se inserta una ventanita de agente y **abre una sesión real** de agente al click/tocar.
- [ ] La ventana chat funciona estilo terminal: streaming, logs de tools, código coloreado.
- [ ] **Voz (STT/TTS):** hablar con la IA y oír su respuesta **sin abrir la ventanita** (botón 🎤/🔊 en el canva). La transcripción queda en la sesión.
- [ ] **Screenshot de evidencia por prompt:** cada respuesta adjunta capturas (código, terminal, UI, tests) con veredicto visual ✅/❌.
- [ ] Varias ventanitas → varias sesiones a la vez (cada una en su directorio real).
- [ ] La sesión continua aunque cierre la ventanita (minimiza; mini-estado en el canva).
- [ ] Funciona en móvil y desktop (PWA).
- [ ] Haptic o flashes visuales en hitos del agente.
- [ ] Acción peligrosa pide aprobación; nivel de permisos conservador al inicio (configurable).

## Después de la Etapa 1 (en el ROADMAP)

El resto del plan (kanban/empresa, Chrome DevTools MCP, LangGraph multi-agente) se construye **sobre** este canva: el kanban verá los tickets, el UI Tester usará las mismas ventanas para verificar, y el orquestador LangGraph lanzará agentes que aparecen como ventanas en el canva.

