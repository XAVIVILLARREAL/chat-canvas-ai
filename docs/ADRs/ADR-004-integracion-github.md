# ADR-004: Integracion GitHub

> Fecha: 2026-08-21 . Estado: Pendiente . Contexto: Gestion de codigo y colaboracion

## Contexto

Canvas AI necesita gestionar codigo fuente. Los desarrolladores ya usan GitHub. No reinventar la rueda: integrarse con GitHub en vez de crear un sistema de version control propio.

## Decision: Integracion profunda con GitHub

### 1. Login con GitHub (OAuth)

**Flujo:**
```
1. Usuario hace click en "Login con GitHub"
2. Tauri abre browser para autorizacion
3. GitHub redirige con codigo de autorizacion
4. Backend intercambia codigo por access token
5. Token se almacena en SQLite (encriptado)
6. Usuario queda logueado
```

**Permisos solicitados:**
- `repo` — acceder a repositorios privados
- `workflow` — gestionar GitHub Actions (futuro)
- `read:user` — info basica del usuario

**Almacenamiento:**
- Access token: SQLite encriptado (campo `github_token`)
- Refresh token: SQLite encriptado
- Expiracion: 30 dias (renovacion automatica)

### 2. Gestion de repositorios

**Ver repos del usuario:**
```
GET /user/repos
```
- Lista repos publicos y privados
- Filtrar por nombre, lenguaje, fecha
- Mostrar: nombre, descripcion, stars, forks, lenguaje

**Clonar repositorio:**
```
git clone <url> --depth 1
```
- Clon superficial (solo HEAD) para rapido
- Ubicacion: `~/canvas-ai/repos/<nombre>`
- Opcion de clonar completo despues

**Crear repositorio:**
```
POST /user/repos
```
- Nombre, descripcion, visibilidad (public/private)
- Readme automatico
- License: MIT por defecto

### 3. Push/Pull desde la app

**Push:**
```
git add .
git commit -m "feat: descripcion"
git push origin main
```
- Commit message generado por el agente (conventional commits)
- Push manual o automatico (configurable)
- Conflict detection antes de push

**Pull:**
```
git pull origin main
```
- Pull manual o al iniciar sesion
- Merge automatico si no hay conflictos
- Notificacion si hay conflictos (el humano resuelve)

**Branches:**
```
git checkout -b feature/nueva-feature
git push origin feature/nueva-feature
```
- Crear ramas desde la app
- Cambiar de rama
- Eliminar ramas merged

### 4. Crear Pull Requests

**Flujo:**
```
1. Agente completa una feature
2. Crea rama automaticamente (feature/nombre)
3. Push a la rama
4. Crea PR con:
   - Titulo descriptivo
   - Descripcion con cambios
   - Criterios de aceptacion
   - Screenshots/evidencia
5. Notificacion al humano
6. Humano revisa y merge en GitHub
```

**Campos del PR:**
- `title`: Titulo descriptivo
- `body`: Descripcion con markdown
- `head`: Rama origen
- `base`: Rama destino (main)
- `draft`: Boolean (para PRs en progreso)

### 5. Ver Issues

**Lectura:**
```
GET /repos/{owner}/{repo}/issues
```
- Lista issues abiertos/cerrados
- Filtrar por labels, asignee, milestone
- Mostrar: titulo, estado, labels, asignado

### 6. Crear Issues

**Desde la app:**
```
POST /repos/{owner}/{repo}/issues
```
- Titulo del issue
- Descripcion con markdown
- Labels (bug, feature, enhancement)
- Asignee (agente o humano)
- Milestone

**Uso:**
- PM crea issues desde la app
- Issues se vinculan a tareas del canva
- Cierre automatico cuando se mergea PR

## Stack tecnologico

| Componente | Tecnologia | Paquete |
|---|---|---|
| OAuth | Tauri OAuth | `tauri-plugin-oauth` |
| GitHub API | octocrab | `octocrab` (Rust) |
| Git operations | git2-rs | `git2` (Rust) |
| Encriptacion | ring | `ring` (Rust) |

## Consecuencias

### Positivas
- Flujo familiar para desarrolladores
- Version control profesional
- Colaboracion en equipo
- CI/CD via GitHub Actions (futuro)

### Negativas
- Requiere conexion a internet
- Dependencia de un servicio externo
- Complexity de OAuth

### Riesgos mitigados
- Fallback a working offline (push despues)
- GitHub tiene SLA 99.9%
- OAuth es estandar de la industria

## References

- [GitHub REST API](https://docs.github.com/en/rest)
- [GitHub OAuth](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps)
- [octocrab](https://github.com/XAMPPRocky/octocrab)
- [git2-rs](https://github.com/rust-lang/git2-rs)
