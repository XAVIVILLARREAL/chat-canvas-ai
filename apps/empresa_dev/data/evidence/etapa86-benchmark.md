# Evidencia Etapa 8.6 — benchmark canva LOD (10.000 nodos)

> Generado por `integration_test/canva_perf_test.dart` (Windows real, `-d windows`).

- Nodos totales: 10000
- Zoom 1.0 → nodos dibujados en el canvas: 2009 / 10000 · clusters: 0
- Zoom-out total → nodos sueltos en el canvas: 0 · clusters: 18
- Zoom 1.0 (culling): media 3.53 ms/frame · tardíos(>33.3 ms) 0/108 (0.0%)
- Zoom-out total (clusters): media 2.21 ms/frame · tardíos(>33.3 ms) 0/152 (0.0%)
- Resultado fase zoom-out: OK ≥30fps
- Resultado fase zoom 1.0: OK ≥30fps
