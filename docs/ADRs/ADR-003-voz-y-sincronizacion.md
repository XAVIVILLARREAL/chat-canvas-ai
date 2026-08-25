# ADR-003: Voz (TTS/STT) y Sincronizacion

> Fecha: 2026-08-21 . Estado: Pendiente . Contexto: Comunicacion por voz + sync entre dispositivos

## Contexto

Canvas AI necesita:
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

### 2. Sincronizacion: WebSocket + GitHub (NO P2P)

**Decision clave:** NO implementar rsync ni sync P2P nativo.

**Por que NO P2P/rsync:**
- Lo que sincronizamos es pequeno (sesiones ~10KB, config ~5KB, skills ~1KB)
- GitHub ya maneja el codigo fuente
- Conflictos sin servidor central son complejos de resolver
- NAT traversal es fragil y requiere STUN/TURN servers
- Ambos dispositivos deben estar online al mismo tiempo

**Estrategia de sync:**

| Que sincronizar | Metodo | Por que |
|---|---|---|
| **Codigo fuente** | GitHub (Git) | Version control, diff, merge, PRs |
| **Documentacion** | GitHub (Git) | Vive en el repo |
| **Sesiones** | WebSocket | Real-time, ligero |
| **Config** | WebSocket | Real-time, cambia poco |
| **Skills** | WebSocket | JSON ligero |

**Separacion clara:**
```
GitHub: Codigo y documentacion (version control)
WebSocket: Estado y configuracion (real-time)
```

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

**Tamano de datos sincronizados:**
- Sesiones: ~10KB por sesion
- Config: ~5KB total
- Skills: ~1KB cada uno
- Total tipico: <50KB por sync

## Stack tecnologico

| Componente | Tecnologia | Paquete |
|---|---|---|
| STT | Web Speech API | Nativo del browser |
| TTS | Edge TTS | WebSocket directo |
| Sync sessions/config | WebSocket | `tokio-tungstenite` (Rust) |
| Codigo/documentacion | GitHub | `octocrab` + `git2` (Rust) |
| SQLite | sqlx | `sqlx` (Rust) |

## Consecuencias

### Positivas
- STT gratis y nativo del browser
- TTS gratis y voces naturales
- Sync real-time via WebSocket
- GitHub para codigo (no reinventar)
- Sin servidor centralizado para codigo
- Sin complejidad de NAT traversal

### Negativas
- Web Speech API no funciona en todos los browsers mobile
- Edge TTS requiere conexion a internet
- Sync via WebSocket requiere servidor ligero
- Sin sync offline entre dispositivos (ambos deben estar online)

### Riesgos mitigados
- Web Speech API tiene fallback a texto
- Edge TTS tiene cache local
- WebSocket tiene reconexion automatica
- GitHub funciona offline (push despues)

## References

- [Web Speech API](https://developer.mozilla.org/en-US/docs/Web/API/Web_Speech_API)
- [Edge TTS](https://github.com/rany2/edge-tts)
- [octocrab](https://github.com/XAMPPRocky/octocrab)
