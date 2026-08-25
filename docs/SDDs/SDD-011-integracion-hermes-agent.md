# SDD-011 · Integración de patrones Hermes Agent → Canvas AI

> Fecha: 2026-08-24 · Estado: Propuesto · Inspiración: [Hermes Agent](https://github.com/NousResearch/hermes-agent/) (MIT, Nous Research)
> **Este documento NO modifica los planes existentes.** Amplía la visión y agrega mejoras concretas que se insertan en los planes originales sin romper nada.
> Repositorio de referencia clonado: `reference/hermes-agent/` (gitignored)

## Objetivo

Extraer los patrones arquitectónicos más valiosos de Hermes Agent e integrarlos como mejoras incrementales en los 15 planes existentes de Canvas AI. Cada inserción se indica con el formato: **`[Hermes→Plan·Fase]`** para que al ejecutar la fase, se incluya la mejora sin modificar el alcance original.

---

## 1. 🛡️ SEGURIDAD — Inserción en Plan T (T.SEC) + Plan A (A.2)

### 1.1 Threat Pattern Library (30+ regex patterns)

**Fuente:** `tools/threat_patterns.py` (284 líneas)

**Qué copiar:**
```python
# Patrón central: scope-filtered regex
FILLER = r"(?:\w+\s+){0,8}"  # Previene backtracking adversarial
PATTERNS = [
    # "all" — se aplica en TODOS los textos
    (rf'ignore\s+{FILLER}(previous|all|above|prior)\s+{FILLER}instructions', "prompt_injection", "all"),
    (r'system\s+prompt\s+override', "sys_prompt_override", "all"),
    # "context" — archivos de contexto + memoria + tool results
    (r'register\s+(as\s+)?a?\s*node', "c2_node_registration", "context"),
    (r'you\s+are\s+{_FILLER}now\s+(?:a|an|the)\s+', "role_hijack", "context"),
    # "strict" — solo escrituras de memoria + installs
    # (agresivo, solo para contenido que el usuario cura)
]
def scan_for_threats(text, scope="all", max_chars=65536):
    # Escanea texto, retorna lista de pattern_ids encontrados
```

**Dónde insertar:**
- **`[Hermes→T.SEC]`** — Nueva fase **T.SEC.1**: "Threat Pattern Library"
  - Crear `server/security/threat_patterns.py` (copia directa de Hermes, 284L)
  - Integrar como middleware FastAPI que escanea cada request antes de enviar al LLM
  - Scope `all` → escanea mensajes del usuario
  - Scope `context` → escanea archivos de contexto (AGENTS.md, ADRs, SOUL.md)
  - Scope `strict` → escanea writes de memoria y skills instaladas
  - **Costo:** 0.5 días

- **`[Hermes→A.2]`** — Extensión a A.2 (Persistencia SQLite)
  - Agregar tabla `threat_scans` para auditoría de escaneos: `(id, session_id, scope, pattern_id, severity, blocked, created_at)`
  - Cada escaneo queda registrado para revisión futura
  - **Costo:** 0.5 días (migración SQL + middleware)

### 1.2 Skills Guard (Trust Matrix × Verdict)

**Fuente:** `tools/skills_guard.py` (1,175 líneas)

**Qué copiar:**
```python
INSTALL_POLICY = {
    "builtin":       ("allow",  "allow",   "allow"),
    "trusted":       ("allow",  "allow",   "block"),
    "community":     ("allow",  "block",   "block"),
    "agent-created": ("allow",  "allow",   "ask"),
}

@dataclass
class Finding:
    pattern_id: str; severity: str; category: str
    file: str; line: int; match: str; description: str

@dataclass
class ScanResult:
    skill_name: str; source: str; trust_level: str; verdict: str
    findings: List[Finding]; scanned_at: str; summary: str

def scan_skill(skill_path, source="community") -> ScanResult:
    # Escanea skill completa, retorna verdict
def should_allow_install(result, force=False) -> Tuple[bool, str]:
    # Decisión: allow/block/ask según trust × verdict
```

**Dónde insertar:**
- **`[Hermes→T.SEC]`** — Nueva fase **T.SEC.2**: "Skills Security Scanner"
  - Crear `server/security/skills_guard.py` (copiar 400L principales de Hermes)
  - Integrar con `server/skills/skill_manager.py` existente
  - Cada skill que se instala pasa por el scanner ANTES de activarse
  - UI muestra resultado del escaneo con findings detallados
  - **Costo:** 1 día

- **`[Hermes→G.G2]`** — Extensión a G.2 (Tool-Gating)
  - Agregar verificación de seguridad ANTES del tool-gating
  - Si el skill tiene findings críticos → bloqueado sin importar el tool-gating
  - **Costo:** 0.5 días (integración)

### 1.3 Context File Injection Scanner

**Fuente:** `agent/prompt_builder.py:61-85` (25 líneas)

**Qué copiar:**
```python
def _scan_context_content(content: str, filename: str) -> str:
    """Escanea archivos de contexto ANTES de inyectarlos al system prompt."""
    if content.startswith("\ufeff"):
        content = content[1:]  # Strip BOM
    findings = scan_for_threats(content, scope="context")
    if findings:
        return f"[BLOCKED: {filename} contained potential injection]"
    return content
```

**Dónde insertar:**
- **`[Hermes→D.D2]`** — Extensión a D.2 (Workspace Knowledge)
  - Antes de inyectar knowledge al contexto del agente, escanear cada archivo
  - Archivos con findings críticos → reemplazar con placeholder `[BLOCKED]`
  - **Costo:** 0.5 días

### 1.4 Tool Guardrails (Loop Detection + Circuit Breaker)

**Fuente:** `agent/tool_guardrails.py` (855 líneas)

**Qué copiar:**
```python
IDEMPOTENT_TOOL_NAMES = frozenset({"read_file", "search_files", "web_search", ...})
MUTATING_TOOL_NAMES = frozenset({"terminal", "write_file", "patch", ...})

@dataclass
class ToolCallGuardrailConfig:
    warnings_enabled: bool = True
    hard_stop_enabled: bool = False
    exact_failure_warn_after: int = 2
    exact_failure_block_after: int = 5
    same_tool_failure_warn_after: int = 3
    same_tool_failure_halt_after: int = 8
    no_progress_warn_after: int = 2
    no_progress_block_after: int = 5
```

**Dónde insertar:**
- **`[Hermes→C.C3]`** — Extensión a C.3 (Robustez)
  - Agregar detección de loops de tools: si un agente repite la misma tool 3+ veces con el mismo resultado → warning
  - Si repite 5+ veces → circuit breaker (pausa y pide intervención humana)
  - Configurable por scope de [A.A6]
  - **Costo:** 1 día

---

## 2. ⏰ CRON SCHEDULER — Inserción en Plan N (N.6)

### 2.1 Execution Ledger (SQLite)

**Fuente:** `cron/executions.py` (284 líneas)

**Qué copiar:**
```sql
CREATE TABLE IF NOT EXISTS cron_executions (
    id TEXT PRIMARY KEY,
    job_id TEXT NOT NULL,
    source TEXT NOT NULL,
    process_id TEXT NOT NULL,
    pid INTEGER NOT NULL,
    status TEXT CHECK(status IN ('claimed','running','completed','failed','unknown')),
    claimed_at TEXT NOT NULL,
    started_at TEXT,
    finished_at TEXT,
    error TEXT
)
```

```python
@contextmanager
def _transaction():
    """Context manager que abre conexión SQLite, hace commit/rollback, y SIEMPRE cierra."""
    with _lock:
        conn = _connect()
        try:
            _initialize_schema(conn)
            with conn:
                yield conn
        finally:
            conn.close()
```

**Dónde insertar:**
- **`[Hermes→N.6]`** — Extensión a N.6 (Rutinas programadas)
  - Crear `server/cron/executions.py` (copiar 284L de Hermes)
  - Tabla `cron_executions` con status `claimed→running→completed/failed/unknown`
  - Context manager `_transaction()` para operaciones atómicas
  - **Costo:** 0.5 días

### 2.2 Tick-Based Scheduler

**Fuente:** `cron/scheduler.py` (7,695 líneas — solo copiar patrón, no código entero)

**Patrón a copiar:**
```python
def tick():
    # 1. File lock cross-process (fcntl/msvcrt)
    lock_fd = open(lock_file, "w")
    fcntl.flock(lock_fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
    
    # 2. Emergency stop check
    if estop_paused("cron"): return 0
    
    # 3. Reclaim dead-owner executions (procesos que murieron)
    recover_interrupted_executions()
    
    # 4. Get due jobs
    due_jobs = get_due_jobs()
    
    # 5. Advance next_run ANTES de ejecutar (at-most-once semantics)
    advance_next_runs([job["id"] for job in due_jobs])
    
    # 6. Parallel execution with max_workers
    with ThreadPoolExecutor(max_workers=_max_workers) as pool:
        futures = [pool.submit(run_job, job) for job in due_jobs]
```

**Dónde insertar:**
- **`[Hermes→N.6]`** — Extensión a N.6 (Rutinas programadas)
  - Crear `server/cron/scheduler.py` (simplificado de 7695 → ~300L)
  - Implementar `tick()` con: file lock → reclaim dead → get due → advance → parallel exec
  - Integrar con `server/main.py` como background task que corre cada 60s
  - **Costo:** 1 día

### 2.3 Lifecycle Guard (Prevent Gateway Restart)

**Fuente:** `cron/lifecycle_guard.py` (50 líneas)

**Qué copiar:**
```python
_GATEWAY_LIFECYCLE_PATTERN = re.compile(
    r"(?i)"
    r"(?:(?<![/\w.\-])hermes\s+gateway\s+(?:restart|stop|uninstall)\b)"
    r"|(?:systemctl\s+(?:-\S+\s+)*(?:restart|stop|start)\b[^\n]*\bhermes[.\-]?gateway)"
    r"|(?:\b(?:pkill|kill)\b[^\n]*\bhermes[.\-]?gateway\b)"
)

def check_gateway_lifecycle(command: str) -> Optional[GatewayLifecycleBlocked]:
    """Bloquea cron jobs que intentan reiniciar el gateway."""
    if _GATEWAY_LIFECYCLE_PATTERN.search(command):
        return GatewayLifecycleBlocked("Cron job blocked: would restart gateway")
    return None
```

**Dónde insertar:**
- **`[Hermes→N.6]`** — Extensión a N.6
  - Agregar verificación de lifecycle antes de ejecutar cron jobs
  - Prevenir que un agente reinicie el servidor via cron
  - **Costo:** 0.25 días (copia directa)

---

## 3. 🎙️ VOZ (TTS/STT) — Inserción en Plan K (K.1-K.3)

### 3.1 TTS Provider ABC (Interface Pluggable)

**Fuente:** `tools/tts_provider.py` (50 líneas)

**Qué copiar:**
```python
class TTSProvider(abc.ABC):
    @property
    @abc.abstractmethod
    def name(self) -> str: ...
    
    def is_available(self) -> bool:
        return True
    
    @abc.abstractmethod
    def synthesize(self, text: str, output_path: str, voice: str = "default",
                   model: str = None, speed: float = 1.0,
                   instructions: str = None, output_format: str = "mp3") -> str: ...
    
    def list_voices(self) -> List[Dict[str, Any]]:
        return []
    
    def list_models(self) -> List[Dict[str, Any]]:
        return []
```

**Dónde insertar:**
- **`[Hermes→K.1]`** — Extensión a K.1 (TTS de respuestas)
  - Crear `server/voice/tts_provider.py` (copiar 50L)
  - Crear `server/voice/tts_edge.py` (adaptar de Hermes `tts_tool.py` — solo Edge TTS)
  - Patrón de lazy import: `edge_tts` se importa solo cuando se usa
  - Chunk splitting para textos >5000 chars
  - **Costo:** 1 día

### 3.2 Transcription Provider ABC

**Fuente:** `tools/transcription_provider.py` (50 líneas)

**Qué copiar:**
```python
class TranscriptionProvider(abc.ABC):
    @property
    @abc.abstractmethod
    def name(self) -> str: ...
    
    def is_available(self) -> bool:
        return True
    
    @abc.abstractmethod
    def transcribe(self, audio_path: str, language: str = None,
                   model: str = None, prompt: str = None) -> Dict[str, Any]: ...
    # Returns: {"success": bool, "transcript": str, "provider": str, "error": str}
```

**Dónde insertar:**
- **`[Hermes→K.2]`** — Extensión a K.2 (STT dictado)
  - Crear `server/voice/transcription_provider.py` (copiar 50L)
  - Crear `server/voice/stt_whisper.py` (adaptar — Whisper local o API)
  - **Costo:** 0.5 días

### 3.3 Audio Container Sniffing (Magic Bytes)

**Fuente:** `tools/audio_container.py` (100 líneas)

**Qué copiar:**
```python
def sniff_container(data: bytes) -> Optional[str]:
    """Detecta formato real del audio por magic bytes, sin dependencias."""
    if len(data) >= 8 and data[4:8] == b"ftyp":
        if len(data) >= 12 and data[8:12].lower() in (b"m4a ", b"m4b "): return "m4a"
        return "mp4"
    if data.startswith(b"OggS"): return "ogg"
    if data.startswith(b"fLaC"): return "flac"
    if len(data) >= 12 and data[:4] == b"RIFF" and data[8:12] == b"WAVE": return "wav"
    if data.startswith(b"ID3"): return "mp3"
    if len(data) >= 2 and data[0] == 0xFF and (data[1] & 0xE0) == 0xE0:
        if (data[1] & 0xF6) == 0xF0: return "aac"
        return "mp3"
    if data.startswith(b"\x1a\x45\xdf\xa3"): return "webm"
    return None
```

**Dónde insertar:**
- **`[Hermes→K.1]`** — Extensión a K.1
  - Crear `server/voice/audio_utils.py` (copiar 100L)
  - Usar para detectar formato real antes de enviar a TTS/STT
  - **Costo:** 0.25 días

---

## 4. 📋 SKILLS — Inserción en Plan G (G.1-G.3)

### 4.1 SKILL.md Format (Frontmatter YAML + Markdown)

**Fuente:** `skills/` directorio completo (85+ skills de ejemplo)

**Formato a adoptar:**
```yaml
---
name: skill-name                    # lowercase, hyphens, <=64 chars
description: "Concise description." # <=60 chars, una oración
version: 1.0.0                      # semver
author: Nombre (handle)
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [relevant, tags]
    related_skills: [other-skill]
---
# When to Use
# Prerequisites
# How to Run
# Quick Reference
# Procedure
# Pitfalls
# Verification
```

**Dónde insertar:**
- **`[Hermes→G.1]`** — Extensión a G.1 (Modelo de datos)
  - Adoptar el formato SKILL.md como estándar de Canvas AI
  - Crear `server/skills/skill_schema.py` con validación del frontmatter
  - Migrar skills existentes al nuevo formato
  - **Costo:** 1 día

### 4.2 Skill Preprocessing (Template Variables + Inline Shell)

**Fuente:** `agent/skill_preprocessing.py` (144 líneas)

**Qué copiar:**
```python
def substitute_template_vars(text: str, skill_dir: Path, session_id: str) -> str:
    """Reemplaza ${HERMES_SKILL_DIR}, ${HERMES_SESSION_ID}, etc."""
    text = text.replace("${HERMES_SKILL_DIR}", str(skill_dir))
    text = text.replace("${HERMES_SESSION_ID}", session_id)
    return text

def run_inline_shell(text: str) -> str:
    """Ejecuta inline shell `!date` y reemplaza con resultado (cap 4000 chars)."""
    pattern = r'!`([^`]+)`'
    def replace(match):
        cmd = match.group(1)
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=10)
        return result.stdout[:4000]
    return re.sub(pattern, replace, text)
```

**Dónde insertar:**
- **`[Hermes→G.3]`** — Extensión a G.3 (Compilador a dialectos)
  - Crear `server/skills/skill_preprocessing.py` (copiar 144L)
  - Adaptar variables: `${HERMES_SKILL_DIR}` → `${SKILL_DIR}`, `${HERMES_SESSION_ID}` → `${SESSION_ID}`
  - Inline shell: ejecutar comandos seguros (solo lectura) antes de pasar skill al LLM
  - **Costo:** 0.5 días

### 4.3 Skill Loading Utilities

**Fuente:** `agent/skill_utils.py` (~200 líneas)

**Qué copiar:**
```python
def parse_frontmatter(text: str) -> tuple[dict, str]:
    """Parsea YAML frontmatter entre delimitadores ---."""
    # Fallback para YAML malformado
    # Retorna (metadata_dict, body_text)

def extract_skill_conditions(frontmatter: dict) -> dict:
    """Extrae condiciones de activación del skill."""
    # platforms, tags, related_skills, etc.

def get_all_skills_dirs() -> List[Path]:
    """Retorna todos los directorios de skills (global + locale)."""
    # ~/.hermes/skills/ + ./skills/ + project skills
```

**Dónde insertar:**
- **`[Hermes→G.1]`** — Extensión a G.1
  - Crear `server/skills/skill_utils.py` (copiar 200L)
  - Integrar con el CRUD existente de G.1
  - **Costo:** 0.5 días

---

## 5. 🧬 LEARNING GRAPH — Inserción en Plan D (D.5-D.8)

### 5.1 SkillNode Graph (Skills + Memories como nodos)

**Fuente:** `agent/learning_graph.py` (328 líneas)

**Qué copiar:**
```python
@dataclass
class SkillNode:
    name: str
    category: str
    source: str = "profile"
    timestamp: Optional[int] = None
    use_count: int = 0
    state: str = "active"
    created_by: Optional[str] = None
    pinned: bool = False
    related: list[str] = field(default_factory=list)

def build_skill_nodes(skill_roots: list[tuple[str, Path]]) -> dict[str, SkillNode]:
    """Construye nodos desde archivos SKILL.md + usage data."""
    usage = _load_usage()
    nodes = {}
    for source, skill_md in _iter_skill_files(skill_roots):
        fm = parse_frontmatter(skill_md.read_text()[:4000])
        name = fm.get("name") or skill_md.parent.name
        rec = usage.get(name, {})
        nodes[name] = SkillNode(
            name=name, category=_category(fm, skill_md),
            use_count=rec.get("use_count", 0),
            related=_related(fm),
        )
    return nodes

def build_edges(nodes: dict[str, SkillNode]) -> list[tuple[str, str]]:
    """Edges por related_skills donde AMBOS endpoints existen."""
    seen = set()
    edges = []
    for node in nodes.values():
        for target in node.related:
            if target in nodes and target != node.name:
                a, b = sorted((node.name, target))
                if (a, b) not in seen:
                    seen.add((a, b))
                    edges.append((a, b))
    return edges

def density_stats(nodes, edges) -> dict:
    """Estadísticas: nodes, edges, linked_nodes, isolated_pct, categories."""
```

**Dónde insertar:**
- **`[Hermes→D.D5]`** — Extensión a D.5 (Índice semántico dual)
  - Crear `server/memory/learning_graph.py` (copiar 328L)
  - Integrar con el índice FTS5 existente
  - Skills y memorias se visualizan como nodos conectados
  - **Costo:** 1 día

- **`[Hermes→F.F2]`** — Extensión a F.2 (Canva Oficina)
  - Agregar vista de "Grafo de Aprendizaje" como nodo visual en el canvas
  - Nodos = skills, edges = related_skills, tamaño = use_count
  - **Costo:** 1 día (integración con ReactFlow)

### 5.2 Trajectory Format (para entrenamiento futuro)

**Fuente:** `batch_runner.py` (1,380 líneas)

**Formato a adoptar:**
```python
# Formato Hermes de trayectorias (simplificado)
{"from": "system", "value": "..."}
{"from": "human", "value": "..."}
{"from": "gpt", "value": "content\n"}
{"from": "tool", "value": "<tool_response>\n{tool_call_id, name, content}\n</tool_response>"}

# Campos adicionales para Canvas AI:
{
    "session_id": "...",
    "project_id": "...",  # multitenant
    "agent_role": "dev|qa|pm|reviewer",
    "outcome": "success|failure|partial",
    "cost_usd": 0.0043,
    "tokens": {"prompt": 1500, "completion": 800}
}
```

**Dónde insertar:**
- **`[Hermes→D.D1]`** — Extensión a D.1 (Decision Ledger)
  - El `event_stream` existente ya tiene `session_id, event_type, summary, payload`
  - Agregar campos: `project_id`, `agent_role`, `outcome`, `cost_usd`, `tokens`
  - Formato compatible con batch training de Hermes
  - **Costo:** 0.5 días (migración SQL)

### 5.3 Trajectory Compression (Protect First/Last, Compress Middle)

**Fuente:** `trajectory_compressor.py` (1,598 líneas — solo copiar estrategia)

**Estrategia a copiar:**
```python
# 1. Proteger primeros turnos: system, human, first gpt, first tool
# 2. Proteger últimos N turnos (default: 4)
# 3. Comprimir SOLO el medio, empezando desde 2da tool response
# 4. Reemplazar región comprimida con 1 mensaje resumen del LLM
# 5. Mantener tool calls restantes intactos

# Config simplificada:
@dataclass
class CompressionConfig:
    target_max_tokens: int = 15250
    summary_target_tokens: int = 750
    protected_first_turns: int = 4
    protected_last_turns: int = 4
    # Summarization model: deepseek-v4-flash (barato)
```

**Dónde insertar:**
- **`[Hermes→D.D3]`** — Extensión a D.3 (Memory Rail UI)
  - Implementar compresión de sesiones largas antes de inyectar al contexto
  - Usar `deepseek-v4-flash` para generar resúmenes (costo ~$0.0001/sesión)
  - **Costo:** 1 día (implementación simplificada)

---

## 6. 🔌 PROVIDER/TOOL REGISTRY — Inserción en Plan C (C.7)

### 6.1 Provider Profile (Declarative Config)

**Fuente:** `providers/base.py` (267 líneas)

**Qué copiar:**
```python
@dataclass
class ProviderProfile:
    name: str
    api_mode: str  # "openai", "anthropic", "gemini"
    env_vars: List[str]
    base_url: Optional[str]
    auth_type: str  # "api_key", "oauth_device_code"
    supports_vision: bool = False
    fallback_models: List[str] = field(default_factory=list)
    default_headers: Dict[str, str] = field(default_factory=dict)
    fixed_temperature: Optional[float] = None
    default_max_tokens: Optional[int] = None
```

**Dónde insertar:**
- **`[Hermes→C.C7]`** — Extensión a C.7 (Registro universal)
  - Crear `server/providers/provider_profile.py` (copiar 267L)
  - Integrar con el catálogo models.dev existente
  - Cada proveedor se declara con su Profile, no con código
  - **Costo:** 0.5 días

### 6.2 Tool Registry (Self-Registration + TTL Cache)

**Fuente:** `tools/registry.py` (1,335 líneas — solo patrón central)

**Qué copiar:**
```python
@dataclass
class ToolEntry:
    name: str
    toolset: str
    schema: dict  # JSON Schema del tool
    handler: Callable
    check_fn: Optional[Callable] = None  # TTL cached (30s)
    requires_env: List[str] = field(default_factory=list)
    is_async: bool = False
    max_result_size_chars: int = 100_000
    description: str = ""
    emoji: str = ""

# Self-registration pattern:
_registry: Dict[str, ToolEntry] = {}

def register(tool: ToolEntry):
    _registry[tool.name] = tool

def get_tool(name: str) -> Optional[ToolEntry]:
    return _registry.get(name)
```

**Dónde insertar:**
- **`[Hermes→N.N1]`** — Extensión a N.1 (Gestión de sesiones)
  - Crear `server/tools/registry.py` (copiar patrón ~200L)
  - Cada skill registra sus tools al activarse
  - Tool-gating verifica contra el registry
  - **Costo:** 0.5 días

---

## 7. 📊 RESUMEN DE INSERCIÓN POR PLAN

| Plan | Fase existente | Mejora Hermes | Archivo a crear | Esfuerzo |
|---|---|---|---|---|
| **T.SEC** | T.SEC (nueva) | Threat patterns + Skills guard + Context scanner | `server/security/threat_patterns.py`, `skills_guard.py` | **2 días** |
| **A.2** | A.2 (Persistencia) | Tabla `threat_scans` para auditoría | Migración SQL | **0.5 días** |
| **C.3** | C.3 (Robustez) | Tool guardrails (loop detection + circuit breaker) | `server/security/tool_guardrails.py` | **1 día** |
| **C.7** | C.7 (Registro) | Provider Profile ABC + Tool Registry | `server/providers/provider_profile.py`, `server/tools/registry.py` | **1 día** |
| **D.1** | D.1 (Ledger) | Campos expandidos: project_id, outcome, cost, tokens | Migración SQL | **0.5 días** |
| **D.2** | D.2 (Knowledge) | Context injection scanner | Integración con threat_patterns | **0.5 días** |
| **D.3** | D.3 (Memory Rail) | Trajectory compression (protect first/last) | `server/memory/trajectory_compressor.py` | **1 día** |
| **D.5** | D.5 (Índice dual) | Learning graph (SkillNode + edges) | `server/memory/learning_graph.py` | **1 día** |
| **G.1** | G.1 (Modelo datos) | SKILL.md format + frontmatter parser | `server/skills/skill_schema.py`, `skill_utils.py` | **1 día** |
| **G.3** | G.3 (Compilador) | Skill preprocessing (template vars + inline shell) | `server/skills/skill_preprocessing.py` | **0.5 días** |
| **K.1** | K.1 (TTS) | TTS Provider ABC + Edge provider + audio sniffing | `server/voice/tts_provider.py`, `tts_edge.py`, `audio_utils.py` | **1.5 días** |
| **K.2** | K.2 (STT) | Transcription Provider ABC | `server/voice/transcription_provider.py` | **0.5 días** |
| **N.6** | N.6 (Rutinas) | Cron scheduler (tick + executions ledger + lifecycle guard) | `server/cron/scheduler.py`, `executions.py`, `lifecycle_guard.py` | **2 días** |
| **F.2** | F.2 (Canva) | Learning graph visual en canvas | Integración con ReactFlow | **1 día** |
| **TOTAL** | | | | **~14 días** |

---

## 8. 🔗 DEPENDENCIAS ENTRE MEJORAS

```
T.SEC.1 (threat_patterns) ──┬──→ T.SEC.2 (skills_guard)
                            └──→ D.D2 (context scanner)
                            
C.C7 (provider profile) ──→ N.N1 (tool registry)
                         └──→ C.C3 (tool guardrails)

D.D1 (trajectory format) ──→ D.D5 (learning graph)
                          └──→ D.D3 (trajectory compression)

K.1 (TTS) ──→ K.2 (STT) ──→ N.6 (cron con voz)

N.6 (cron) es independiente — puede ejecutarse en paralelo
```

---

## 9. ⚠️ REGLAS DE INSERCIÓN

1. **NO MODIFICAR** fases existentes — solo agregar sub-fases o extensiones
2. **Formato:** cada mejora se indica como **`[Hermes→Plan·Fase]`** con referencia al archivo Hermes original
3. **Independencia:** cada mejora funciona por sí misma — no rompe nada si se ejecuta sin las demás
4. **Testing:** cada mejora incluye sus propias pruebas (no reutiliza las de la fase original)
5. **Fallback:** todas las mejoras son fail-open — si fallan, el sistema funciona sin ellas
6. **Documentación:** cada archivo creado lleva header `// Adapted from Hermes Agent (MIT) — Nous Research`

---

## 10. 📋 ORDEN DE EJECUCIÓN RECOMENDADO

| Prioridad | Mejora | Bloquea a | Se ejecuta con |
|---|---|---|---|
| **P0** | T.SEC.1 + T.SEC.2 (Security) | Todo lo demás | Desde Etapa 1 |
| **P0** | A.2 ext (threat_scans table) | T.SEC.1 | Etapa 1 |
| **P1** | C.C3 ext (tool guardrails) | — | Etapa 3 |
| **P1** | C.C7 ext (provider profile) | N.N1 | Etapa 3 |
| **P1** | D.D1 ext (trajectory format) | D.D5 | Etapa 4 |
| **P1** | D.D2 ext (context scanner) | — | Etapa 4 |
| **P2** | G.1 ext (SKILL.md format) | G.3 | Etapa 7 |
| **P2** | K.1 + K.2 (TTS/STT) | — | Etapa 11 |
| **P2** | N.6 ext (cron scheduler) | — | Etapa 14 |
| **P3** | D.D5 (learning graph) | F.2 | Etapa 4+6 |
| **P3** | D.D3 ext (compression) | — | Etapa 4 |
| **P3** | F.2 ext (graph visual) | — | Etapa 6 |

---

## 11. 🎯 VALOR ESPERADO POR MEJORA

| Mejora | Impacto en producto | Impacto en seguridad | Impacto en costo |
|---|---|---|---|
| Threat patterns | — | 🔴 Protege contra injection | — |
| Skills guard | Confianza en skills instaladas | 🔴 Previene supply-chain | — |
| Context scanner | — | 🔴 Previene prompt injection | — |
| Tool guardrails | Previene loops infinitos | 🟡 Previene abuso de tools | 🟡 Ahorra tokens |
| Provider profile | 75+ proveedores sin código | — | 🟢 Elige el más barato |
| Trajectory format | Dataset de entrenamiento | — | 🟢 Habilita fine-tuning |
| SKILL.md format | Skills estandarizadas | — | — |
| TTS/STT | Voz natural | — | — |
| Cron scheduler | Rutinas autónomas | — | 🟢 Automatiza tareas |
| Learning graph | Visualización de conocimiento | — | — |
| Compression | Sesiones más baratas | — | 🟢 70% ahorro tokens |

---

Documento derivado de análisis profundo de `reference/hermes-agent/` (10,216 archivos, 245MB, MIT).
No modifica los planes existentes — solo amplía la visión con mejoras concretas.
