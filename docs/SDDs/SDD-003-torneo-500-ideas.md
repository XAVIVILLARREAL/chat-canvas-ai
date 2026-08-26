# SDD-003 — Torneo de 500 Ideas → las 20 Ganadoras

> Fecha: 2026-08-23 · Estado: Aprobado · Método: generación masiva → eliminatoria por categoría → debate cruzado → selección final
> Fuentes de inspiración (SOLO productos de mercado): OpenAI Codex, Reasonix v1.23 (verificado en vivo), V3Code, Cursor, Claude Code, Zed, Aider, OpenHands, Cline/RooCode, Devin, Lovable, varve, codevira, Morph.
> Regla de oro: nada de infra privada ajena; todo patrón debe existir en un producto real.

## Metodología del torneo

1. **Generación (500)** — 25 categorías × 20 ideas, numeradas 001–500
2. **Eliminatoria por categoría** — cada categoría elige sus 2 finalistas por valor bruto
3. **Debate cruzado (50 finalistas)** — cada idea se enfrenta a 2 rivales de otras categorías; criterios: Valor ★, Viabilidad ★, Mantenibilidad ★, Encaje visión ★ (1–5 c/u, máx 20)
4. **Final (20)** — solo pasan ideas con ≥17/20 Y que no duplicen funcionalidad entre sí Y que fortalezcan la BASE (interfaz Codex + caché Reasonix + 6 capas V3Code)

Las ideas NO ganadoras no se pierden: quedan como backlog consultable en este mismo documento.

---

## LAS 500 IDEAS

### C1 · Composer/Input (001–020)
001. Cola de mensajes: escribir siguientes prompts mientras el agente trabaja (Codex)
002. @menciones de archivos/símbolos con autocomplete del índice (Cursor)
003. Pegar imagen al composer (screenshot → contexto) (Codex)
004. Drag&drop de archivo al chat lo adjunta
005. Detectar stack-trace pegado y ofrecer "analiza este error"
006. Plantillas de prompt reutilizables con variables {{x}}
007. Historial de prompts recientes searchable
008. Expandir a multi-línea sin soltar Enter
009. Stop + regenerate conservando contexto
010. Editar el último mensaje re-ramificando la conversación
011. Fork desde cualquier mensaje histórico
012. Citas de respuestas previas al componer
013. Snippets personales insertables
014. Slash commands extensibles por plugins
015. Indicador de límite de caracteres/tokens del prompt
016. Enter envía / Shift+Enter salta — configurable
017. Sugerencias contextuales inline según tarea
018. Modo dictado con push-to-talk
019. Adjuntar URL y resumirla al contexto
020. Composer fijo abajo con auto-grow elegante

### C2 · Chat UX (021–040)
021. Turnos colapsables: leer el chat como threads (Claude Code)
022. Virtualización del historial (10k mensajes fluidos)
023. Búsqueda global en todas las conversaciones
024. Saltar-al-tool-call desde el resumen del turno
025. Badge vivo de estado del agente junto a su nombre
026. Timestamps relativos ("hace 3 min")
027. Copy-button en cada bloque de código
028. Toggle wrap/scroll horizontal en código
029. Tamaño de fuente ajustable por usuario
030. Anclar mensajes clave al top del chat
031. Renderizado Mermaid para diagramas
032. "Pensó 4.2s" colapsable — reasoning plegado (DeepSeek)
033. Contador de tokens por respuesta
034. Minimapa lateral de la conversación
035. Exportar selección a Markdown
036. Resaltar diferencias entre dos respuestas del agente
037. Modo lectura limpia (oculta metadata)
038. Salto cronológico: ir a primer/último turno del día
039. Referencias cruzadas clicables entre sesiones
040. Compactar visualmente turnos antiguos leídos

### C3 · Streaming (041–060)
041. Token-streaming con markdown progresivo sin flashes
042. Deltas de diff pintándose EN VIVO en el editor
043. Cancelar mid-stream conservando lo parcial válido
044. Retry transparente ante red inestable (backoff visual)
045. Fallback automático a provider alterno si el primario muere
046. Métrica TTFT (time-to-first-token) visible en dev
047. Heartbeat/keepalive anti-timeouts largos
048. Reconexión SSE sin duplicar eventos (sequence numbers)
049. Parser partial-JSON tolerante a cortes
050. Pausa/reanudación del stream por el usuario
051. Stream espejo al panel terminal
052. Orden garantizado por campo sequence (Reasonix real)
053. Deduplicación de eventos repetidos
054. Buffer adaptativo según velocidad de red
055. Code-fence streaming seguro (no rompe render)
056. Indicador "el agente está pensando vs escribiendo"
057. Latencia por fase (reasoning/tool/write) en timeline
058. Modo offline: cola local y flush al volver
059. Compresión de eventos redundantes
060. Debug stream raw para desarrolladores

### C4 · Contexto (061–080)
061. Medidor de ventana de contexto: usado/libre/coste EN VIVO (Claude Code)
062. Vista debug: ver EXACTAMENTE qué se envió al modelo (transparencia total)
063. Diff entre envíos consecutivos (qué cambió en el contexto)
064. Auto-incluir archivos abiertos en el editor
065. `.contextignore` por proyecto
066. Pin de archivos al contexto permanente
067. Presupuesto de contexto por sección (system/tools/historial/archivos)
068. Advertencia ANTES de truncar algo importante
069. Estimador de coste pre-envío
070. Contexto por carpeta/módulo automático
071. Dependencias relevantes incluidas por grafo de imports
072. Plantillas de contexto por tipo de tarea
073. Invalidación selectiva (olvidar solo X)
074. Límites reales por proveedor detectados y respetados
075. Compresión de historial viejo antes de desborde
076. Prioridad por recencia+relevancia al recortar
077. Multimodal: imágenes al contexto con presupuesto propio
078. Ver tokens gastados por sección (pie-chart dev)
079. Contexto compartido entre agentes de la misma empresa
080. Reset de contexto con checkpoint previo automático

### C5 · Caché estilo Reasonix (081–100) ⭐ prioridad base
081. Prefijo de contexto ESTABLE (system+tools fijos primero) para maximizar cache_hit del proveedor
082. Dashboard de cache_hit_tokens por sesión/proyecto (métrica real Reasonix --metrics)
083. Warm-up de caché al abrir proyecto (pre-llenar prefijo)
084. Umbral de auto-compacción CONFIGURABLE (reasonix config compact-ratio real)
085. Invalidación MÍNIMA: cambiar solo lo tocado, nunca reordenar el prefijo
086. Coalescing de preguntas pequeñas en una sola llamada
087. De-duplicación de consultas idénticas consecutivas
088. Semáforo de coste por sesión (verde/ámbar/rojo)
089. Presupuesto duro diario con corte y aviso
090. Comparativa flash-vs-reasoner por tipo de tarea con datos propios
091. Router heurístico LOCAL pre-LLM (reglas simples antes de gastar)
092. Métrica "ahorro del mes" por caché y routing
093. Informe semanal automático de coste/uso
094. Caché de respuestas frecuentes del proyecto (FAQ técnica)
095. Prefetch del contexto probable de la siguiente acción
096. Objetivo SLO de coste por tarea con tracking
097. Export CSV de telemetría para análisis externo
098. Modo economía agresivo (max caché, modelos chicos, menos tools)
099. Alerta de anomalía de gasto (spike >N× media)
100. Tabla de precios editable multi-proveedor

### C6 · Permisos/Sandbox (101–120)
101. Dos perillas ortogonales con presets nombrados (Codex) [YA EN PLAN A]
102. Allowlist de comandos por prefijo editable (Codex granular) [YA EN PLAN A]
103. Deny-patterns regex para lo jamás permitido
104. Red OFF por defecto con dominios permitidos en UI (Codex)
105. Confirmación granular: una vez / toda la sesión / siempre
106. Auditoría legible de quién-ejecutó-qué-cuándo
107. Modo YOLO consciente con banner permanente
108. Timeout duro por comando con kill limpio
109. Cuota CPU/RAM por proceso del agente
110. Paths de escritura restringidos al workspace
111. Scanner de secretos antes de enviar contexto
112. Dry-run de comandos destructivos (rm/git reset → mostrar plan)
113. Rollback automático si exit-code grave post-escritura
114. Permisos heredados por skill (tool-gating) [YA EN PLAN G]
115. Elevación temporal solicitada por el agente con razón
116. Política persistente por proyecto
117. Modo CI no interactivo (nunca pregunta) (Codex -a never)
118. Registro de denegaciones para aprender patrones
119. Sandbox filesystem copy-on-write por tarea
120. Firma de scripts generados antes de ejecutar

### C7 · Diffs (121–140)
121. Unificado + side-by-side conmutables
122. Diff palabra-a-palabra intra-línea
123. Navegación hunk-a-hunk con teclado
124. Aceptar/Rechazar POR HUNKS, no todo-o-nada (Cursor)
125. Feedback por línea que alimenta el siguiente turno [YA EN B]
126. Colapso automático de archivos enormes
127. Ignore-whitespace toggle
128. Historial de diffs por archivo (timeline)
129. Diff contra cualquier commit/base elegible
130. Estadísticas +/- por archivo y total
131. Tree-map visual de archivos cambiados
132. Marcar "revisado ✓" por archivo con firma
133. Filtros por tipo (.ts/.sql/.md…)
134. Diff AST-aware (ignora reformateo)
135. Copiar SOLO los cambios
136. Aplicar diff invertido (deshacer propuesta)
137. Atajos de teclado completos de revisión
138. Diff imprimible / export PDF
139. Vista de conflicto 3-vías guiada [YA EN M]
140. Nota de aprobación adjunta al diff en el Ledger

### C8 · Preview (141–160)
141. Iframe sandbox origen opaco [YA EN B] 
142. Hot-reload por watcher debounced [YA EN B]
143. Consola del preview capturada con botón "enviar error al agente"
144. Device toolbar responsivo DENTRO del preview
145. Overlay de errores runtime clicables
146. Screenshots del preview al chat como evidencia
147. Múltiples rutas/preview simultáneos
148. Mock de APIs locales para prototipos
149. Variables de entorno del preview editables
150. Recarga manual + auto toggle
151. Abrir en navegador externo
152. QR para probar en móvil físico
153. Score básico de calidad inline (accesibilidad/perf)
154. Network tab simplificado
155. Storage inspector ligero (localStorage)
156. Fullscreen preview
157. Persistir interacciones humanas entre recargas
158. Templates con preview instantáneo
159. Proxy de assets con caché
160. Error-boundary visual elegante del sandbox

### C9 · Editor (161–180)
161. Tabs + split panes Monaco
162. Breadcrumbs de símbolo
163. Go-to-definition vía índice propio (sin LSP externo)
164. Find-references local rápido
165. Rename seguro local (scope del índice)
166. Format-on-save Biome integrado
167. Markers de lint inline en gutter
168. **Gutter teñido por agente-autor de cada línea** (V3Code Memory Rail) [YA EN D]
169. Iconos candado en líneas human-locked [YA EN D]
170. Blame POR RUNG (quién-agente/cuándo-sesión), complementario al git
171. Hover docs desde el índice del repo
172. Insertar snippet desde skill
173. Command palette global ⌘K (Zed)
174. Archivos recientes y pineados
175. Drag de tabs entre paneles
176. Zen mode sin distracciones
177. Labels accesibles para screen readers
178. Minimap con marcas de cambios del agente
179. Multi-cursor completo
180. Buscar-y-reemplazar en proyecto con preview

### C10 · Canva (181–200) — [base YA EN PLAN F]
181. Nodos arrastrables con snap a grid
182. Edges bezier animadas suaves
183. Minimap desktop clicable
184. Zoom pinch + rueda fluido
185. Multi-selección rubber-band
186. Agrupar nodos como "empresa"
187. Layout jerárquico automático
188. Undo/redo del canva
189. Copiar/pegar nodos
190. Export PNG del lienzo
191. Colapsar/expander grupos
192. Edge-labels con artefacto que viaja
193. Partículas de actividad real en edges
194. Color-coding consistente de estados
195. Doble-click abre detalle en panel
196. Drag nodo→panel asigna responsable
197. Grid snap + alinear/distribuir
198. Lock de posición de nodo
199. Import/export layout JSON
200. Mini-branch visual para explorar alternativas

### C11 · Agentes paralelos (201–220)
201. Worktrees automáticos por operativo (Codex/Cursor) [YA EN N]
202. Pool concurrente limitado por presupuesto
203. Cola de tareas priorizable drag&drop
204. Skill-match para asignación automática
205. Merge train: merges secuenciales validados (bors-ng pattern)
206. Detector temprano de conflictos entre ramas de agentes
207. Dashboard de actividad paralela en vivo
208. Pausar/un agente sin matar la empresa
209. Logs separados por agente con filtro unificado
210. Identidad visual por agente (color+avatar persistentes)
211. Clonar agente con micro-ajustes A/B
212. Handoff agente→agente con resumen automático
213. Votación entre soluciones candidatas (best-of-N)
214. Crítico "diablo's advocate" opcional por tarea
215. Ranking automático de skills por efectividad histórica
216. Cooldown post-fallo antes de reintentar agente
217. Circuit-breaker de agente problemático
218. Replay de la decisión de asignación (por qué él)
219. Cuota de pasos máximos por operativo
220. Herencia de contexto controlada líder→operativo

### C12 · Skills (221–240) — [base YA EN PLAN G]
221. Editor form sin YAML visible
222. Validación Zod en vivo
223. Versionado semántico de skills
224. Changelog por skill
225. Import SKILL.md codex-compat
226. Export subagent-profile reasonix
227. Marketplace local entre proyectos
228. Tests declarativos del skill
229. Golden outputs: regression por skill
230. Rating de éxito histórico
231. Fork de skill con linaje visible
232. Tags + búsqueda FTS
233. Sharing por bundle firmado
234. Tool-gating visual por rol
235. Modelo preferido por skill
236. Triggers regex/semánticos
237. Editor de few-shot examples
238. Params (temperatura/max-tokens) por skill
239. Dry-run gratis con provider mock
240. Docs autogenerada del skill

### C13 · Pruebas (241–260) — [base YA EN PLAN H]
241. Criterios estructurados por tarea
242. Runner sandbox con timeout duro
243. Allowlist de comandos ejecutables
244. Red OFF durante tests
245. Gate de cobertura mínima configurable
246. Detector de flaky estadístico
247. Snapshot testing de UI crítica
248. Builders de datos de prueba
249. Smoke-matrix rápida pre-push
250. Shards paralelos de suite
251. Reporte unificado pass/fail/tiempo
252. Re-run solo fallidos
253. Cuarentena temporal de flaky
254. Benchmark básico de perf
255. Contract tests entre módulos
256. Mutation testing ligero puntual
257. Seeds deterministas
258. Fixtures compartidos versionados
259. Pre-push local obligatorio
260. Evidencia adjunta automática a la tarea

### C14 · Revisión (261–280) — [base YA EN PLAN I]
261. Review subagente sobre el diff
262. Security-review con severidades
263. Checklist reviewer configurable
264. Comentarios inline del agente revisor
265. Fixes sugeridos aplicables 1-click
266. Flag de TODO/FIXME nuevos introducidos
267. Breaking-change detector de APIs
268. Coverage delta como gate
269. Check de convenciones del repo
270. Flag dead-code añadido
271. Flag complejidad ciclomática alta
272. Scan de secretos en diff
273. Scan licencias de dependencias nuevas
274. Resumen PR autogenerado
275. Risk-score del cambio pre-aprobación
276. Doble-review obligatorio en cambios críticos
277. Gates humanos configurables por ruta
278. Aprende de rechazos pasados (patrones)
279. Plantillas de review por tipo de cambio
280. Veredicto firmado como rung en Ledger

### C15 · Git (281–300) — [base YA EN PLAN M]
281. Status sidebar por archivo
282. Staging granular por hunk
283. Commit-msg AI según convención del repo
284. Branch create/switch desde UI
285. Merge asistido 3-vías
286. Rebase con confirmación segura
287. Stash manager visual
288. Log gráfico simple
289. Revert / cherry-pick puntuales
290. Hooks pre-commit locales
291. Push protection anti-force
292. PR body autogenerado del Ledger
293. Issues sync (lectura+comentario)
294. Releases tagging desde UI
295. Submodules awareness
296. LFS detection y aviso
297. Worktree UI nativa
298. Clean ignored wizard seguro
299. Auth tokens en keyring del OS
300. Export DECISIONS.md commiteada al repo

### C16 · Voz (301–320) — [base YA EN PLAN K]
301. Dictado en composer push-to-talk
302. TTS de respuestas del agente
303. Voz assignable por agente
304. Auto-play opt-in por usuario
305. Cola de audio secuencial
306. Barge-in: hablar corta la reproducción
307. Comandos de voz globales ("aprueba", "pausa")
308. Transcripción siempre editable antes de enviar
309. Idioma es/en detección automática
310. Velocidad TTS ajustable
311. Sonidos distintos por estado de agente
312. Volúmenes por tipo de evento
313. Mute nocturno programado
314. Caché de audio por hash texto+voz
315. TTS on por defecto en modo accesibilidad
316. Noise gate simple del micrófono
317. Indicador visual "escuchando…"
318. Export transcript de la sesión
319. Privacidad: audio nunca sale salvo TTS elegido
320. Fallback graceful si browser sin Web Speech

### C17 · Sync (321–340) — [base YA EN PLAN L]
321. Pairing dispositivos QR+token efímero
322. Selector granular de qué sincronizar
323. Conflictos con UI diff-and-choose
324. LWW para config con historial
325. Merge manual asistido de sesiones
326. Skills sincronizadas automáticamente
327. Cifrado e2e entre dispositivos
328. Modo solo-LAN sin internet
329. Hub self-host vía docker-compose
330. Offline queue con flush al volver
331. Status clara de última sync por dispositivo
332. Revocación inmediata de dispositivo
333. Multi-perfil (personal/trabajo)
334. Migración a máquina nueva 1-click
335. Backup cifrado rotativo local
336. Restore point global del workspace
337. Export/import total portátil
338. Audit log de eventos de sync
339. Bandwidth cap configurable
340. Lista de dispositivos gestionable

### C18 · Costes/Negocio (341–360)
341. Presupuesto por empresa con alerta 80%/corte 100% [YA EN N]
342. Kill-switch global <2s [YA EN N]
343. Dashboard histórico de gasto por proyecto/agente/modelo
344. Atribución de coste por feature/tarea (del Ledger)
345. Forecast de fin de mes por tendencia
346. Comparador costo/calidad histórico por modelo
347. Export contabilidad CSV
348. Anomalías de gasto detectadas y explicadas
349. Badge de coste en cada respuesta del chat
350. Sugeridor "este task sale más barato en flash" con evidencia
351. Licencia open-core con features Pro flaggeadas
352. Trial 30d empresas ilimitadas
353. Pricing per-seat simple
354. Marketplace con revenue-share devs
355. White-label para agencias
356. SSO enterprise + audit-export pack
357. Onboarding-as-service (plantillas de empresa listas)
358. Certificación pública de skills de devs
359. Upgrade flows no intrusivos
360. Métricas de producto locales (opt-in telemetría anónima)

### C19 · Robustez (361–380)
361. Crash-recovery: reabrir sesión exacta tras muerte de la app
362. Autosave continuo de stores (debounced persist)
363. SQLite WAL + backups rotativos automáticos
364. Health-check periódico de providers con estado visible
365. Circuit-breaker por provider caído (ya diseñado) [YA EN C]
366. Retry idempotente con idempotency-keys
367. Timeouts en TODA llamada externa (zero-hang policy)
368. Error-boundaries React por panel independiente
369. Modo seguro (arranca sin plugins/skills de terceros)
370. Validación de entrada rigurosa en commands Rust
371. Suite chaos automatizada [YA EN E]
372. Runbooks de incidentes comunes
373. Logs con rotación y niveles
374. Telemetría de errores 100% local
375. Rollback de versión de la app
376. Actualizaciones delta firmadas
377. Escape/encoding de paths en todos los commands
378. Presión de GC/monitoreo memoria en dev
379. Watchdog de la UI (renderer colgado → recover)
380. Contrato de estabilidad: API interna versionada

### C20 · Performance (381–400)
381. Arranque lazy de paneles pesados
382. Code-splitting por ruta/app
383. Virtualización en TODAS las listas >50
384. Workers para parseo/indexación (no bloquear UI)
385. Debounce en watchers de archivos
386. React Compiler activo auditado [hecho en setup]
387. Profiling HUD en modo dev
388. Budgets de bundle en CI (falla si crece)
389. Prefetch idle de la vista probable
390. Fuentes subseteadas woff2
391. Imágenes/assets óptimos
392. Meta 60fps canva con 100 nodos
393. Cold vs warm start medidos
394. Regresión de perf como gate CI nightly
395. Battery-aware en mobile (reduce efectos)
396. Caché HTTP local de recursos estáticos
397. IndexedDB para blobs grandes fuera de SQLite
398. Instrumentación real-usuarios opt-in
399. Lazy-bindings IPC (crear al primer uso)
400. Snapshot de arranque (v8 snapshot-style para webview)

### C21 · Seguridad (401–420)
401. Keyring del OS para tokens (no SQLite plano)
402. Cifrado AES-GCM de settings sensibles
403. No-telemetry por defecto absoluto
404. Sanitización de Markdown render (XSS-safe)
405. Links externos con confirmación + noopener
406. CSP estricta en el webview
407. Prompts de permiso sin spam (agrupación)
408. Path-traversal suite de tests exhaustiva
409. Dependency audit + SBOM en CI
410. Supply-chain: versiones pineadas + checksums
411. Tests de escape de sandbox
412. Clipboard: limpiar contenido sensible tras N min
413. Screen-redact al compartir (oculta keys en screenshots)
414. Sesiones con expiry + revocación
415. 2FA en pairing de sync
416. Audit log append-only criptográficamente encadenado
417. GDPR: borrar workspace = borrar TODO derivado
418. security.txt + política de divulgación
419. Rate-limit local de acciones del agente
420. Modelo de amenazas documentado por capa

### C22 · Accesibilidad (421–440)
421. Contraste AA verificado automated
422. Foco visible SIEMPRE
423. aria-live polite en streaming
424. prefers-reduced-motion respetado global
425. Landmarks + roles correctos
426. Shortcuts descubribles (?)
427. Targets ≥44px mobile
428. Zoom 200% sin romper layouts
429. Lenguaje claro y consistente
430. i18n central (es/en) listo
431. Alto-contraste extra modo
432. Fuente dislexia-friendly opción
433. Capturas sustitutas de cues de audio
434. Alcanzabilidad one-handed mobile
435. RTL-ready estructura
436. Errores accionables (qué hacer ahora)
437. Axe-core en CI E2E
438. Skip-links principales
439. Tooltips también por foco (no solo hover)
440. Preferencias persistidas por usuario

### C23 · Docs/Onboarding (441–460)
441. Guided tour primera vez (3 pasos, skipeable)
442. Empty-states que enseñan (no vacíos tristes)
443. Proyecto ejemplo incluido funcional
444. Cheatsheet ⌘/ siempre disponible
445. Tooltips progresivos según uso
446. Videos cortos embebidos por feature clave
447. FAQ contextual en errores comunes
448. Glosario de términos IA
449. Changelog in-app
450. Widget de feedback directo
451. Plantillas de primeras empresas
452. Recetas de uso por caso
453. Docs autogeneradas del código (rustdoc+tsdoc CI)
454. Búsqueda en docs local
455. Tutoriales interactivos en sandbox
456. Badges de progreso de aprendizaje
457. Link a comunidad
458. Soporte in-app con diagnóstico adjunto
459. Página de licenses/atribuciones
460. Modo presentación (demo scriptada)

### C24 · Negocio avanzado (461–480)
461. Billing Stripe-ready detrás de flag
462. Gestión de seats por organización
463. Facturas automáticas
464. Usage-based pricing opcional
465. Programa de afiliados
466. Case studies embebidos en app
467. Status page propia del producto
468. SLA monitoring tier enterprise
469. Mapeo controles SOC2-lite documentado
470. Opción data-residency
471. Custom branding white-label
472. API pública rateada por plan
473. Webhooks de eventos del sistema
474. Integraciones tipo-zapier básicas
475. Templates pagados en marketplace
476. Escrow para servicios entre devs
477. Reviews verificadas de compras
478. Flujo de disputas con evidencia
479. Analytics del marketplace
480. Onboarding de pago asistido

### C25 · Ecosistema MCP (481–500) — [O.2 base]
481. Servidor MCP de memoria/decisiones (read) [YA EN O.2]
482. MCP de repo-map queries [YA EN O.2]
483. MCP para invocar skills compilados [YA EN O.2]
484. Cliente MCP para tools externas en el agente interno
485. UI de configuración de servers MCP
486. Panel de salud de servers conectados
487. Tokens por-server con scopes
488. Sandbox para llamadas MCP de terceros
489. Logs de llamadas MCP auditables
490. Registry versionado de tools
491. Compat spec MCP vigente + streaming
492. Resources MCP expuestos (archivos/decisions)
493. Prompt-templates MCP reutilizables
494. Discover: servidores recomendados verificados
495. Import config desde otros editors
496. Export config portable
497. Bridge reasonix↔MCP bidireccional
498. Rate-limit y coste por server externo
499. Contrato de versión estable documentado
500. Test-conformance suite MCP propia

---

## ELIMINATORIA POR CATEGORÍA (50 finalistas)

Cada categoría nominó sus 2 más valiosas. Finalistas:

| Cat | Finalistas | Cat | Finalistas | Cat | Finalistas |
|---|---|---|---|---|---|
| C1 | **001** cola, **002** @menciones | C2 | 021 threads, 032 reasoning plegable | C3 | 043 cancelar-parcial, 048 reconexión seq |
| C4 | **061** medidor, **062** debug-view | C5 | **081** prefijo-caché, **084** auto-compactación | C6 | 104 red-off, 112 dry-run destructivos |
| C7 | **124** hunks, 132 revisado✓ por archivo | C8 | **143** consola→agente, 146 screenshot evidencia | C9 | **170** blame-rung, **173** ⌘K paleta |
| C10 | 193 partículas, 187 layout auto | C11 | **205** merge-train, **213** best-of-N | C12 | **229** golden-outputs, 225 import SKILL.md |
| C13 | **253** cuarentena-flaky, 246 flaky-detector | C14 | **275** risk-score, 267 breaking-API | C15 | **300** DECISIONS.md, 291 push-protection |
| C16 | 306 barge-in, 302 TTS respuestas | C17 | 323 conflictos choose, 329 hub docker | C18 | **343** dashboard gasto, **344** coste/feature |
| C19 | **361** crash-recovery, 401 keyring | C20 | 383 virtualización total, 392 canva 60fps | C21 | 401 keyring, 408 path-traversal suite |
| C22 | 423 aria-live stream, 437 axe en CI | C23 | 443 proyecto ejemplo, 441 guided tour | C24 | 351 open-core, 354 marketplace rev-share |
| C25 | **481** MCP memoria, 489 logs llamadas MCP | | | | |

## DEBATES CRUZADOS (extracto del jurado)

**D1 · #081 prefijo-caché vs #092 métrica-ahorro** → *Gana #081.* El ahorro es CONSECUENCIA del mecanismo; sin prefijo estable no hay nada que medir. La métrica entra como parte del dashboard de #082. *(mecanismo > vanity metric)*

**D2 · #061 medidor-contexto vs #349 badge-coste-por-respuesta** → *Gana #061.* El medidor incluye coste y evita el problema ANTES de enviar; el badge es informativo post-hoc. Badge se hereda al dashboard de Etapa N.

**D3 · #001 cola-mensajes vs #011 fork-desde-mensaje** → *Gana #001.* La cola cambia el flujo diario completo (piensas mientras trabaja); fork es ocasional. Fork ya cubierto por slash-command existente en A.4.

**D4 · #124 hunks vs #133 filtros-tipo** → *Gana #124.* La confianza humana se gana aprobando PIEZAS, no categorías. Los filtros son azúcar; los hunks son control real.

**D5 · #170 blame-rung vs #168 gutter-autor** → *Empate técnico, pasan fusionados:* mismo componente visual (gutter V3Code) alimenta ambos — quién escribió cada línea Y en qué sesión/rung. Una implementación, dos vistas.

**D6 · #361 crash-recovery vs #401 keyring** → *Ambos pasan la final* — seguridad y recuperación no compiten: una protege datos, otra protege experiencia. Se asignan a robustez transversal (Etapa E) y seguridad (transversal).

**D7 · #213 best-of-N vs #215 ranking-skills** → *Gana #213 para base.* Best-of-N da valor inmediato visible; el ranking necesita meses de datos acumulados. Ranking queda en backlog de Etapa N+.

**D8 · #229 golden-outputs vs #239 dry-run-mock** → *Gana #229.* El dry-run es UI del laboratorio ya prevista; los golden outputs son la RED DE SEGURIDAD que hace los skills profesionales (regresión al editar un skill).

**D9 · #062 debug-view vs #075 compresión-historial** → *Ambos, roles distintos:* #062 es CONFIANZA (ver qué se envió), #075 es SUPERVIVENCIA (caber en contexto). Ninguno sustituye al otro.

**D10 · #143 consola→agente vs #146 screenshot-evidencia** → *Gana #143.* Convertir un error visible en input del agente cierra el bucle de corrección; el screenshot es subconjunto de la evidencia ya obligatoria (SDD-002).

## 🏆 LAS 20 GANADORAS (de 500)

Rubrica: Valor / Viabilidad / Mantenibilidad / Encaje (máx 20). Corte: ≥17 y sin duplicar ganadora.

| # | Idea | Origen | V/Vi/M/E | Aterriza en |
|---|---|---|---|---|
| 1 | **Prefijo estable de caché + warm-up** | Reasonix | 5/5/5/5 | Etapa C · nueva fase C.5 |
| 2 | **Auto-compacción configurable** (`compact-ratio`) | Reasonix | 5/5/5/4 | Etapa C · dentro de C.5 |
| 3 | **Dashboard cache_hit + semáforo coste** | Reasonix metrics | 5/5/4/5 | Etapa C · dentro de C.5 |
| 4 | **Medidor de contexto/coste EN VIVO** | Claude Code/Cursor | 5/5/5/5 | Etapa A · nueva fase A.5 |
| 5 | **Debug view: ver exactamente qué se envió** | transparencia Codex | 5/5/4/5 | Etapa A · A.5 |
| 6 | **Presupuesto de contexto por sección** | Cursor/Aider | 4/5/5/4 | Etapa A · A.5 |
| 7 | **Cola de mensajes durante ejecución** | Codex/Cursor | 5/5/5/4 | Etapa A · A.4 ampliada |
| 8 | **@menciones archivos/símbolos autocomplete** | Cursor/Codex | 5/4/4/5 | Etapa B · B.6 (usa índice J) |
| 9 | **Editar último mensaje re-ramificando** | ChatGPT/Codex | 4/5/4/4 | Etapa A · A.4 ampliada |
| 10 | **Revisión por HUNKS aceptar/rechazar** | Cursor/GitHub | 5/5/4/5 | Etapa B · B.7 |
| 11 | **Consola preview → botón "enviar al agente"** | Lovable/bolt.new | 5/5/5/5 | Etapa B · B.8 |
| 12 | **Blame-rung + gutter autor (fusionado)** | V3Code Memory Rail | 5/4/4/5 | Etapa D · D.7 |
| 13 | **Reset de contexto con checkpoint automático** | V3Code checkpoints | 5/5/4/4 | Etapa D · D.6 ampliada |
| 14 | **Compresión de historial pre-desborde** | Claude Code compact | 5/5/4/5 | Etapa D · D.3 ampliada |
| 15 | **Command palette global ⌘K** | Zed/VSCode | 4/5/5/4 | Etapa F · F.7 |
| 16 | **Merge train de worktrees** | bors/Cursor teams | 4/4/4/5 | Etapa N · N.2 ampliada |
| 17 | **Best-of-N: votación entre soluciones** | Devin/best-of-n | 4/4/4/4 | Etapa H · H.7 |
| 18 | **Golden outputs regression de skills** | testing clásico→skills | 5/5/5/4 | Etapa G · G.4 ampliada |
| 19 | **Cuarentena de tests flaky** | Google/flaky-bot | 4/5/5/4 | Etapa H · H.8 |
| 20 | **Risk-score pre-aprobación** | Codex auto_review | 4/5/4/5 | Etapa I · refuerza I.4 |

### Los 3 pilares de la BASE confirmados por el torneo

1. **Interfaz increíble de Codex** ← ganadoras 4,5,6,7,9 (+ plan A completo)
2. **Caché optimizado de Reasonix** ← ganadoras 1,2,3 (fase C.5 nueva, mecanismo medido: `cache_hit_tokens` real)
3. **Las 6 capas de memoria de V3Code** (mecanismo de copia.md §2) — mapeo explícito:
   - Capa 1 Episódica/Shadow → [H·H.5](./SDD-001-plan-base/plan-h-motor-pruebas.md#h5)
   - Capa 2 Auditoría/EventStream+rungs → [D·D.1](./SDD-001-plan-base/plan-d-memoria-v3code.md#d1)
   - Capa 3 Invariantes/Human-Lock → [D·D.2](./SDD-001-plan-base/plan-d-memoria-v3code.md#d2)
   - Capa 4 Estructural/RepoMap-PageRank → [PLAN J](./SDD-001-plan-base/plan-j-grafo3d-repomap.md)
   - Capa 5 Empresarial/Knowledge dual → [D·D.5](./SDD-001-plan-base/plan-d-memoria-v3code.md#d5)
   - Capa 6 Procedimental/Roles-Skills-DSPy → [PLAN G](./SDD-001-plan-base/plan-g-skills-lab.md) + [N](./SDD-001-plan-base/plan-n-orchestration.md)

## ETAPAS DE PRUEBA OBLIGATORIAS por ganadora

| Ganadora | Unit | Integración | E2E funcional | Suite HUMANA |
|---|---|---|---|---|
| 1 Prefijo caché | test orden-secciones estable | cache_hit>90% tras warm-up real | n/a backend | verifica badge "cached ✓" |
| 2 Auto-compacción | umbral dispara exacto | resumen conserva rungs clave | conversación larga no degrada | chat sigue coherente tras compactar |
| 3 Dashboard caché | cálculo % correcto | datos reales --metrics | panel actualiza en vivo | entiende su gasto sin explicar |
| 4 Medidor vivo | presupuesto aritmética | eventos tokens→UI | barra reacciona durante stream | "siempre sé cuánto llevo" |
| 5 Debug view | serializer snapshot | request capturado = vista mostrada | toggle muestra/oculta | confianza: "veo qué sabe de mí" |
| 6 Presupuesto secciones | allocator respeta caps | truncado por prioridad correcto | warn antes de recortar | nunca pierde lo anclado |
| 7 Cola mensajes | FIFO + cancelación | envío diferido tras turno | 3 mensajes encolados se ejecutan orden | escribe mientras piensa sin fricción |
| 8 @menciones | fuzzy-match índice | símbolo→snippet correcto | dropdown navegable teclado | encuentra archivo en <2s |
| 9 Editar último | branch tree store | re-rama conserva Ledger | editar→nueva rama visible | corrige typo sin miedo |
| 10 Hunks review | parser hunks | estado parcial persiste | aprueba 2 de 3 hunks | control fino = confianza |
| 11 Consola→agente | captura error formateada | error→prompt contextual | click envía, agente corrige | bucle error-fix sin copiar/pegar |
| 12 Blame-rung | mapeo línea→rung | gutter pinta sesiones | hover muestra autor/sesión | rail V3Code reconocible |
| 13 Checkpoint reset | snapshot git-backed | restore código+contexto | rebobinar turno N exacto | "volver atrás" sin miedo |
| 14 Compresión historial | ratio objetivo | calidad post-resumen (golden) | 200-turnos cabe | historia larga sigue útil |
| 15 ⌘K paleta | registro comandos | acciones cross-panel | abrir/buscar/ejecutar teclado | todo a ≤3 teclas |
| 16 Merge train | orden serialización | conflicto detiene tren | 2 PRs paralelos merge limpio | paralelismo sin pánico |
| 17 Best-of-N | orquestador N runs | scoring por criterios | 3 candidatas→elige mejor | elige con evidencia visible |
| 18 Golden skills | runner fixtures | diff salida≠golden marca | editar skill rompe→test rojo | skills confiables al editar |
| 19 Cuarentena flaky | detector estadístico | move-in/out automático | flaky sale del gate | gate verde significa verde |
| 20 Risk-score | fórmula factores | calibra con históricos | badge riesgo en aprobación | prioriza qué mirar primero |

## Backlog vivo

Las 480 ideas no ganadoras PERMANECEN en este documento como backlog consultable. Al cerrar cada etapa se re-visita: si una idea backlog se vuelve crítica (cambio de mercado/uso), entra por mini-SDD con la misma rúbrica. Nada se descarta; todo se difiere con intención.

