# Evidencia Etapa 5 — Grafo 3D (WebView2 + Three.js)

## Pruebas (2026-08)

1. **Unit** (`packages/graph_core/test/graph3d_html_test.dart`): HTML válido,
   Three.js + OrbitControls, JSON con nodos/posiciones y aristas, grafo vacío.
2. **Widget** (`test/project_graph_3d_widget_test.dart`): fallback 2D fuera de
   desktop (no navega + SnackBar), pop con mensaje en plataforma no soportada.
3. **E2E** (`integration_test/graph_flow_test.dart`, `flutter test -d windows
   --dart-define=EMPRESA_DEV_REPO=<fixture graph_demo>`): **All tests passed**
   — menú canva → "Grafo del proyecto" → 2D con nodos del fixture → botón 3D →
   WebView2 carga el moodel HTML+Three.js → indicador "3D cargado".
4. **Screenshots**: captura de pantalla del escritorio durante la corrida —
   `grafo-3d-webview2.png` (ventana del grafo 3D: fondo `#0F172A`, aristas
   violeta, esferas/labels por paquete).

## Bugs reales encontrados y corregidos (skill /dev)

- **Overflow de UI real**: el menú "Añadir al canva" (8 items en `Column`
  fijo) desbordaba 155 px en ventanas normales → envuelto en
  `SingleChildScrollView`.
- **E2E tap fuera de pantalla**: la entrada "Grafo del proyecto" quedaba bajo
  el fold (y=800 en ventana 684) → `ensureVisible` antes del tap.

## Notas de infraestructura (lecciones)

- El menú del canva no era scrollable → el item 7º+ no era alcanzable por tap
  (bug real de UI, no solo de test).
- `binding.takeScreenshot` en desktop requiere `flutter drive`; con
  `flutter test` lanza `MissingPluginException` → envuelto en try/catch.
- Evidencia visual de desktop: captura nativa por `tools/capture_app.ps1`
  (CopyFromScreen cada 2 s mientras corre el E2E).
- Build E2E en Windows: `nuget` en PATH (flutter_tts) + prefix de install
  manual tras borrar `build/windows` + matar `sshpro.exe` huérfano (LNK1104).