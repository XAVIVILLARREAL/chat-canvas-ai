# Security Policy

**Producto:** Canvas AI · Complementa [THREAT-MODEL](./docs/THREAT-MODEL.md) y [plan-t](./docs/SDDs/SDD-001-plan-base/plan-t-excelencia.md#tsec)

## Reportar una vulnerabilidad

**NO abras un issue público.** Escribe a un canal privado con la información de contacto declarada en `security.txt` (se genera en la Etapa de seguridad T.SEC) o, si ya existe, usa la key PGP publicada en el repo.

**Proceso:**
1. Reportas con pasos de reproducción + impacto + versión afectada.
2. Respondemos en **≤ 72 h** con acuse y plan.
3. Coordinamos una ventana de divulgación responsable (default 90 días).
4. Publicamos aviso (CVE si aplica) + fix + crédito al investigador.

**Recompensas:** programa de recompensas de seguridad aún no activo; el crédito público y el reconocimiento en `SECURITY/ACKNOWLEDGEMENTS.md` sí.

## Alcance

En foco: ejecución de código no confiable (sandbox Linux), gestión de secretos BYOK, path traversal, XSS vía respuestas del agente, aislamiento multi-tenant (RLS), inyección de prompts/tools. Fuera de alcance: ingeniería social sobre el propio autor.

## Prácticas aplicadas

- `cargo-audit` + `cargo-deny` + SBOM (cyclonedx) en CI; fallo en CVE crítico.
- Dependencias pineadas con checksums; `pnpm` lockfile.
- CSP estricta del webview; markdown sanitizado; preview en iframe sandbox.
- Secretos BYOK nunca en el bundle ni al webview ([THREAT-MODEL](./docs/THREAT-MODEL.md)).
- Workers sin credenciales de DB; sandbox por contenedor Linux con red off.
- Vulnerabilidades críticas → release urgente fuera de cadencia.
