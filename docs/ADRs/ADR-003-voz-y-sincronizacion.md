# ADR-003: Voz (TTS/STT) y Sincronizacion

> Fecha: 2026-08-21 . Estado: Pendiente . Contexto: Comunicacion por voz + sync entre dispositivos

## Contexto

Empresa Dev necesita:
1. **Comunicacion por voz** — el usuario habla con los agentes, los agentes responden con TTS
2. **Sincronizacion** — continuar donde dejaste en otro dispositivo

## Decisiones

### 1. Voz: Web Speech API + Edge TTS

**STT (reconocimiento de voz):**
- **Solucion:** Web Speech API nativo del browser
- **Por que:** Gratis, funciona offline, soporta espanol, latencia baja
- **Plataformas:** Chrome, Edge, Safari, Firefox
- **Limitaciones:** Requiere permiso del usuario, no funciona en todos los browsers mobile

**TTS (texto a voz):**
- **Solucion:** Edge TTS (Microsoft)
- **Por que:** Gratis, voces naturales en espanol, API simple via WebSocket
- **Voces recomendadas:**
  - `es-MX-DaliaNeural` (espanol Mexico, femenino)
  - `es-MX-JorgeNeural` (espanol Mexico, masculino)
  - `es-ES-ElviraNeural` (espanol Espana, femenino)
  - `es-ES-AlvaroNeural` (espanol Espana, masculino)
- **Latencia:** ~200ms
- **Calidad:** Natural, no robotica

**Por que NO otras opciones:**
- OpenAI TTS: De pago, requiere API key
- ElevenLabs: De pago, mas lento
- Browser TTS nativo: Voces roboticas, poco naturales
- Google Cloud TTS: De pago, requiere cuenta

### 2. Sincronizacion: Sesiones + Config + Skills

**Que sincronizar (via WebSocket):**
- **Sesiones** — estado de agentes, progreso, tareas
- **Config** — preferencias, theme, atajos de teclado
- **Skills creados** — JSON de skills del usuario

**Que NO sincronizar (via GitHub):**
- **Codigo fuente** — GitHub ya maneja version control
- **Documentacion** — vive en el repo

**Por que esta separacion:**
- GitHub es experto en codigo (diff, merge, PRs)
- WebSocket es experto en real-time (sesiones, config)
- No reinventar la rueda

### 3. Metodo de sync: WebSocket

**Protocolo:**
```
Cliente (React) <--WebSocket--> Backend (Rust) <--WebSocket--> Otro Cliente
```

**Eventos de sync:**
- `session:updated` — cambio en estado de agente
- `config:updated` — cambio en preferencias
- `skill:created` — nuevo skill
- `skill:updated` — skill modificado
- `skill:deleted` — skill eliminado

**Resolucion de conflictos:**
- Ultima escritura gana (LWW) para config
- Merge manual para sesiones (el humano decide)
- No hay conflictos para skills (creados localmente)

## Stack tecnologico

| Componente | Tecnologia | Paquete |
|---|---|---|
| STT | Web Speech API | Nativo del browser |
| TTS | Edge TTS | WebSocket directo |
| OAuth GitHub | Tauri OAuth | `tauri-plugin-oauth` |
| GitHub API | octocrab | `octocrab` (Rust) |
| Sync sessions | WebSocket | `tokio-tungstenite` (Rust) |
| SQLite | sqlx | `sqlx` (Rust) |

## Consecuencias

### Positivas
- STT gratis y nativo del browser
- TTS gratis y voces naturales
- Sync real-time via WebSocket
- GitHub para codigo (no reinventar)

### Negativas
- Web Speech API no funciona en todos los browsers mobile
- Edge TTS requiere conexion a internet
- Sync via WebSocket requiere servidor centralizado

### Riesgos mitigados
- Web Speech API tiene fallback a texto
- Edge TTS tiene cache local
- WebSocket tiene reconexion automatica

## References

- [Web Speech API](https://developer.mozilla.org/en-US/docs/Web/API/Web_Speech_API)
- [Edge TTS](https://github.com/rany2/edge-tts)
- [octocrab](https://github.com/XAMPPRocky/octocrab)
