# PLAN — Empresa de Desarrollo Autónoma con Agentes de IA (Web App)

> **Estado:** Plan en curso (se documenta y ajusta iterativamente).
> **Formato:** Aplicación web moderna (NO CLI). Mobile-first, rápida, con apariencia excepcional.
> **Uso:** Primero para desarrollos propios; con potencial de convertirse en producto para otros.

## 🎯 Misión

Construir **tu propia empresa de desarrollo con IA, completa, dentro de una app web**:

- Un **canva** donde ves todas tus sesiones de desarrollo organizadas en proyectos.
- Una sección de **organización tipo kanban** que gestiona el trabajo como lo haría una empresa real (tickets, agentes, PRs, verificación).
- Un **sistema multi-agente confiable en producción** (LangGraph) que desarrolla tus proyectos.
- Un sistema de verificación centrado en **MCP Chrome DevTools**: el agente prueba la interfaz **como lo haría un humano** en un **Chrome headless que corre siempre en segundo plano del lado del servidor** (hace clic, navega, escribe, mira la consola, toma capturas).

El objetivo no es "un agente que hace todo", sino **agentes especializados + bucles de verificación** donde la prueba de la UI en un navegador real es el corazón.

## 🧠 Principios rectores

1. **Web, no CLI.** Todo el control es gráfico, con estética cuidada y rendimiento excelente, mobile-first y responsive.
2. **El navegador es la fuente de verdad.** Todo código se valida ejecutándolo y probándolo en un Chrome real vía **MCP Chrome DevTools** — como lo haría un humano, con capturas de pantalla como evidencia.
3. **Orquestación con LangGraph.** Un grafo de agentes con estado, retry, y human-in-the-loop: producción confiable, no scripts sueltos.
4. **SDD primero.** Cada feature se diseña (SDD) antes de implementarse; los tests se escriben antes que el código (TDD).
5. **Los errores no se eliminan, se hacen imposibles de ignorar.** Verificación en capas + bucle de retroalimentación del error real al agente.
6. **Cambios pequeños y frecuentes.** PRs de ≤300 líneas; el humano aprueba en hitos, no en cada línea.
7. **Memoria del proyecto.** Los agentes consultan la arquitectura, SDDs y decisiones antes de tocar código.

## 🏗️ Arquitectura en una frase

```
App Web (canva + kanban + sesiones)
        │  WebSocket / API
        ▼
Orquestador LangGraph (estado, retry, human-in-the-loop)
        │  delega
        ▼
Agentes especializados ──► herramientas MCP
                              ├─ Chrome DevTools MCP  ← el núcleo (prueba la UI como humano)
                              ├─ filesystem / shell / node
                              └─ git / CI
```

## 📚 Índice de documentación

| Documento | Contenido |
|---|---|
| [ETAPA1.md](./ETAPA1.md) | **Lo primero a construir:** canva de diagramas + ventanitas de agente, con **nuestro propio chat web basado en un fork de opencode (MIT)**. |
| [PRODUCTO.md](./PRODUCTO.md) | El producto: pantallas, secciones (canva, kanban, sesiones), UX mobile-first y stack moderno. |
| [ARQUITECTURA.md](./ARQUITECTURA.md) | Sistema: frontend, backend, LangGraph, capa MCP, flujo de control. |
| [AGENTES.md](./AGENTES.md) | Roles de agentes (incluido el UI Tester con Chrome DevTools MCP) y Definition of Done. |
| [VERIFICACION.md](./VERIFICACION.md) | **El corazón:** cómo Chrome DevTools MCP prueba la UI como un humano y cómo el error vuelve al agente. |
| [PIPELINE.md](./PIPELINE.md) | Flujo completo idea → producción, con SDD + TDD + verificación visual. |
| [ROADMAP.md](./ROADMAP.md) | Fases de construcción del producto. |

## ✅ Decisiones (por resolver)

- [ ] **Motor de la Etapa 1 (TOMADA):** **fork de opencode (MIT)** y construir **nuestro propio chat web de agente** sobre su core+llm+server, descartando la UI de terminal (ver [ETAPA1.md](./ETAPA1.md)).
- [ ] ¿Reconstruir sobre CanvaDev (React Flow + server Node ya hechos) o integrar el canva dentro del fork de opencode desde cero con el stack que ya trae?
- [ ] ¿LangGraph en TypeScript (mismo idioma que el resto) o Python (más maduro)?
- [ ] ¿MCP Chrome DevTools oficial de Chrome o alternativa comunitaria (puppeteer/playwright)?
- [ ] ¿Producto para otros desde el inicio (auth multi-usuario) o primero uso personal?
