# SDD — Etapa 2, slice 1: Nodo agente IA + sesión de chat (opencode)

> **Proyecto:** empresa_dev — Etapa 2 del SUPER_PLAN.
> **Fecha:** 2026-08. **Estado:** En implementación.

## Objetivo

Los **agentes IA son ciudadanos de primera clase en el canva**: un nuevo tipo de nodo (`agent`) que, al hacer click, abre una **sesión de chat** con opencode CLI. El usuario dialoga con el agente desde dentro de la app, como una sesión más del producto.

## Alcance (este slice)

- `CanvaNodeType.agent` + nodo `CanvaNode` con `agentId` (nombre del agente).
- Menú de añadir en el canva: "Agente IA" → crea nodo.
- `AgentSession` (modelo) + `AgentMessage` (role user/assistant, texto, timestamp).
- `AgentStore`: persistencia de sesiones en JSON (`agent_sessions.json`).
- `AgentRunner` (abstracción) + `OpenCodeAgentRunner`: invoca `opencode run <prompt>` vía `dart:io Process`, con **streaming** de la salida.
- `AgentChatScreen`: historial, input, botón enviar, indicador de "pensando", respuesta en vivo.
- Click en nodo agente → abre chat (reusando la sesión del agente o creando una).

## Fuera de alcance (slices siguientes)

- Voz (STT navegador + Edge TTS) → slice 2.
- Evidencia por prompt guardada como `.md` navegable → slice 3.
- Verificación UI con Chrome headless → slice 4.
- Agente disponible en Android/iOS (no hay opencode CLI en móvil) → el nodo muestra "solo desktop". El hub como puente queda para después de Etapa 2.

## Flujo (caso feliz)

1. Canva → botón añadir → "Agente IA" → se crea el nodo (color violeta, icono `smart_toy`).
2. Click en el nodo agente → abre `AgentChatScreen(agentName, store, runner)`.
3. El usuario escribe un prompt → se añade `AgentMessage(role: user)` → se lanza `opencode run <prompt>` en el directorio de trabajo del proyecto.
4. La salida del proceso se va agregando a `AgentMessage(role: assistant)` en vivo (streaming).
5. Al terminar → la sesión se persiste. Volver al canva → click de nuevo → el historial sigue ahí.

### Casos límite

- opencode no instalado / no en PATH → mensaje claro "opencode no encontrado" en el chat.
- Proceso falla (exit != 0) → stderr se muestra como error.
- Node en móvil → diálogo "Agentes IA disponibles solo en desktop".
- Nodo sin sesión previa → nueva sesión; con sesión → reanuda.

## Contratos

### Modelo

```dart
enum AgentRole { user, assistant, system, error }

class AgentMessage {
  final AgentRole role;
  final String text;
  final DateTime at;
}

class AgentSession {
  final String id;            // 'a' + tiempo
  final String agentName;     // nombre del agente (nodo)
  final List<AgentMessage> messages;
  bool get isRunning;         // transitorio, no se persiste (o se persiste como estado)
}
```

### Runner

```dart
abstract class AgentRunner {
  Future<Process> startRun(String prompt, {String? cwd});
}

class OpenCodeAgentRunner implements AgentRunner {
  OpenCodeAgentRunner({String executable = 'opencode'});
  @override
  Future<Process> startRun(String prompt, {String? cwd}); // Process.start(executable, ['run', prompt], cwd)
}
```

> El runner devuelve un `Process` real: el chat escucha `stdout` (asistente) y `stderr` (errores), y espera `exitCode`. Inyectable para tests (fake process con stream controlado).

### Store

```dart
class AgentStore {
  Future<List<AgentSession>> load();
  Future<void> save(List<AgentSession> sessions);
  Future<AgentSession> getOrCreate(String agentName); // única sesión viva por agente
  Future<void> append(AgentSession s, AgentMessage m);
}
```

## Datos

- `agent_sessions.json` en `getApplicationDocumentsDirectory()` (mismo patrón que `canva_state.json`).
- Formato: `{ "sessions": [ {id, agentName, messages: [{role, text, at}]} ] }`.
- El nodo agente en el canva no guarda el historial: solo `agentId` (el nombre), como `hostId`.

## Errores

| Error | Manejo |
|---|---|
| opencode no encontrado (`ProcessException`) | mensaje tipo error en el chat |
| exitCode != 0 | stderr mostrado como mensaje `error` |
| Proceso lento | indicador "pensando…" + botón enviar deshabilitado mientras corre |
| Nodo agente en móvil | diálogo "solo desktop" |

## Tests

- **Unit (modelo):** `AgentSession`/`AgentMessage` roundtrip JSON; roles serializan; `getOrCreate` reusa sesión por agente.
- **Unit (store):** persistencia real en temp dir (con `path_provider` mockeado o path inyectable).
- **Widget:** `AgentChatScreen` con runner fake → enviar prompt muestra mensaje del usuario, luego el asistente, y deshabilita el input mientras corre.
- **Widget:** canva crea nodo agente y el click navega a `AgentChatScreen`.

## Verificación de UI (gate slice)

1. Canva → añadir → Agente IA → aparece el nodo.
2. Click → se abre el chat.
3. Escribir `¿qué comandos tiene la shell?` → la respuesta de opencode aparece en vivo.
4. Cerrar chat, reabrir → historial persistente.
5. Capturas como evidencia.

## Definition of Done

- [ ] `flutter analyze` 0 issues.
- [ ] Tests unit/widget verdes (excluyendo integration).
- [ ] Nodo agente + chat funcional en desktop.
- [ ] Slice marcado como hecho en SUPER_PLAN (Etapa 2, slice 1).