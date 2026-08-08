# SDD — Fase 1.2: Llaves públicas + SFTP + sesiones persistentes

> **Proyecto:** empresa_dev (terminal SSH Flutter) — Fase 1.2 del ROADMAP.
> **Fecha:** 2026-08. **Estado:** En implementación.

## Objetivo

Ampliar la Fase 1.1 (SSH con password) para cubrir lo que más se usa de Termius:
1. **Autenticación con llaves públicas** (importar/generar PEM).
2. **SFTP** completo: navegar, subir, bajar, crear carpetas.
3. **Sesiones persistentes** por host (guardar conexiones para reabrir).
4. **Agrupación** por carpeta/color.

## Alcance (este slice)

- `SshService`: autenticación con llaves (`identities`) además de password; reutilizable por shell y SFTP.
- `SftpService`: sobre el mismo `SSHClient`, operaciones básicas de SFTP.
- UI: pantalla **SFTP** (lista de archivos, subir/bajar, crear carpeta) accesible desde el host.
- UI: formulario de host con opción **llave** (campo de texto PEM o selector de archivo).
- Tests: unitarios del modelo + integración SFTP real contra pve.

## Fuera de alcance (siguientes slices)

- Túneles (local/remoto/SOCKS5) y jump servers (Fase 1.2 completa, se agregan después).
- Almacenamiento cifrado de llaves (flutter_secure_storage) — se integra luego.
- Canva (Fase 1.3), hub sync (Fase 1.4).

## Flujo (caso feliz)

1. Usuario agrega un host y elige autenticación: password **o** llave PEM.
2. Toca "Conectar" → `SshService.connect()` con password o `identities`.
3. Desde la pantalla del host, toca el botón **SFTP** → se abre la vista de archivos.
4. Navega carpetas (listado), sube un archivo local, baja un remoto, crea una carpeta.
5. La conexión SFTP usa el mismo cliente SSH autenticado.

### Casos límite

- **Llave inválida / passphrase** → error claro en la UI.
- **Servidor no soporta SFTP** → mensaje.
- **Archivo duplicado / sin permisos** → error con detalle.
- **Red caída** → reconexión con mensaje.

## Contratos

### SshService

```dart
Future<SSHClient> connect(SshHost host, {String? keyPem, String? passphrase})
// shell() y sftp() se obtienen del client devuelto
```

### SftpService

```dart
Future<List<SftpEntry>> list(String path)
Future<void> upload(String localPath, String remotePath)
Future<void> download(String remotePath, String localPath)
Future<void> mkdir(String path)
Future<String?> read(String path)
```

## Datos

- `SshHost` se extiende con: `authType` (password | key), `keyPem` (opcional), `folder` (grupo), `color`.
- Persistencia: en memoria por ahora (SQLite llega con el hub, Fase 1.4). Lista estática en la pantalla de hosts.

## Errores

| Error | Manejo |
|---|---|
| Llave inválida | mostrar error "llave no válida" al conectar |
| Passphrase incorrecta | pedir de nuevo |
| SFTP no disponible | banner "este servidor no soporta SFTP" |
| Permisos denegados | mostrar stderr del comando |

## Tests

- **Unit (SshHost):** authType por defecto password; keyPem opcional.
- **Integración (`integration` tag):**
  - `list('/root')` contra pve → contiene al menos `.ssh`.
  - `mkdir('/tmp/empresa-test-<ts>')` → existe.
  - `upload` + `download` de un archivo pequeño → mismo contenido.
  - Limpieza del archivo de prueba.

## Verificación de UI (gate Fase 1.2)

1. Agregar host con llave (usar `test/fixtures/app_test_key` — es la instalada en pve).
2. Conectar → terminal funciona.
3. Abrir SFTP → listar `/root`.
4. Subir un archivo de prueba → aparece en el listado.
5. Bajarlo → se guarda local con mismo contenido.
6. Capturas de cada paso como evidencia.

## Definition of Done

- [ ] `flutter analyze` 0 issues.
- [ ] Tests unitarios verdes.
- [ ] Test de integración SFTP contra pve verdes.
- [ ] UI: conectar con llave, SFTP listar/subir/bajar.
- [ ] Gate 1.2 documentado en ROADMAP como completado.
