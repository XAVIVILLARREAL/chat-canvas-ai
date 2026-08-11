/// Generador del HTML 3D (Three.js) del grafo del proyecto.
///
/// Devuelve un documento autocontenido que referencia `three.min.js` y
/// `orbitcontrols.js` como assets relativos (los sirve un HttpServer local en
/// la app; nada de CDN → offline y reproducible).
library;

import 'models.dart';

String buildGraph3dHtml(
  Graph graph, {
  Map<String, Offset2>? positions,
}) {
  final pos = positions ?? const {};
  final nodesJson = graph.nodes
      .map((n) {
        final p = pos[n.id] ?? const Offset2(0, 0);
        return '{"id":"${n.id}","label":"${n.label}","kind":"${_esc(n.kind.name)}",'
            '"package":"${_esc(n.package)}","x":${p.x},"y":${p.y}}';
      })
      .join(',');
  final edgesJson = graph.edges
      .map((e) => '{"from":"${_esc(e.from)}","to":"${_esc(e.to)}",'
          '"kind":"${_esc(e.kind.name)}"}')
      .join(',');

  return '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>Grafo 3D</title>
<style>
html,body{margin:0;height:100%;overflow:hidden;background:#0F172A;font-family:Consolas,monospace}
#tooltip{position:absolute;display:none;pointer-events:none;background:rgba(15,23,42,.92);border:1px solid rgba(34,211,238,.6);color:#fff;padding:6px 10px;border-radius:8px;font-size:12px;z-index:10}
#legend{position:absolute;left:12px;top:12px;color:rgba(255,255,255,.55);font-size:11px;pointer-events:none;z-index:10}
</style>
</head>
<body>
<div id="tooltip"></div>
<div id="legend">arrastra = rotar · rueda = zoom · clic derecho = pan · hover = nombre</div>
<script>
window.__GRAPH__ = {
  nodes:[$nodesJson],
  edges:[$edgesJson]
};
</script>
<script src="three.min.js"></script>
<script src="orbitcontrols.js"></script>
<script>
(function () {
  const G = window.__GRAPH__;
  const scene = new THREE.Scene();
  scene.background = new THREE.Color(0x0F172A);
  const camera = new THREE.PerspectiveCamera(60, innerWidth / innerHeight, 0.1, 5000);
  camera.position.set(0, 0, G.nodes.length > 60 ? 1200 : 800);
  const renderer = new THREE.WebGLRenderer({ antialias: true });
  renderer.setSize(innerWidth, innerHeight);
  renderer.setPixelRatio(devicePixelRatio);
  document.body.appendChild(renderer.domElement);

  const controls = new THREE.OrbitControls(camera, renderer.domElement);
  controls.enableDamping = true;
  controls.dampingFactor = 0.08;

  scene.add(new THREE.AmbientLight(0x404060));
  const dl = new THREE.DirectionalLight(0xffffff, 1);
  dl.position.set(1, 1, 1);
  scene.add(dl);
  const pl = new THREE.PointLight(0x22D3EE, 0.8, 2500);
  pl.position.set(-600, 400, -300);
  scene.add(pl);

  const palette = ['#22D3EE', '#A855F7', '#4ADE80', '#F59E0B', '#F472B6', '#60A5FA'];
  const colorFor = function (p) {
    let h = 0;
    for (let i = 0; i < p.length; i++) h = (h * 31 + p.charCodeAt(i)) >>> 0;
    return palette[h % palette.length];
  };

  const byId = {};
  G.nodes.forEach(function (n) { byId[n.id] = n; });

  const linePos = [];
  G.edges.forEach(function (e) {
    const a = byId[e.from], b = byId[e.to];
    if (!a || !b) return;
    linePos.push(a.x, a.y, a.z || 0, b.x, b.y, b.z || 0);
  });
  if (linePos.length > 0) {
    const geo = new THREE.BufferGeometry();
    geo.setAttribute('position', new THREE.Float32BufferAttribute(linePos, 3));
    const mat = new THREE.LineBasicMaterial({
      color: 0xA855F7, transparent: true, opacity: 0.4
    });
    scene.add(new THREE.LineSegments(geo, mat));
  }

  function makeLabel(text, color) {
    const c = document.createElement('canvas');
    const ctx = c.getContext('2d');
    ctx.font = '14px Consolas, monospace';
    const w = Math.ceil(ctx.measureText(text).width) + 16;
    c.width = w; c.height = 24;
    ctx.font = '14px Consolas, monospace';
    ctx.textBaseline = 'middle';
    ctx.fillStyle = 'rgba(15,23,42,0.55)';
    ctx.fillRect(0, 0, w, 24);
    ctx.strokeStyle = 'rgba(255,255,255,0.25)';
    ctx.strokeRect(0.5, 0.5, w - 1, 23);
    ctx.fillStyle = color;
    ctx.fillText(text, 8, 13);
    const sp = new THREE.Sprite(new THREE.SpriteMaterial({
      map: new THREE.CanvasTexture(c), transparent: true, depthWrite: false
    }));
    sp.scale.set(w, 24, 1);
    return sp;
  }

  const group = new THREE.Group();
  const spheres = [];
  G.nodes.forEach(function (n, i) {
    const z = ((i % 7) - 3) * 70;
    n.z = z;
    const color = colorFor(n.package);
    const m = new THREE.Mesh(
      new THREE.SphereGeometry(n.kind === 'other' ? 3 : 4, 16, 16),
      new THREE.MeshPhongMaterial({
        color: color,
        emissive: new THREE.Color(color).multiplyScalar(0.25)
      })
    );
    m.position.set(n.x, n.y, z);
    m.userData.node = n;
    group.add(m);
    spheres.push(m);
    const label = makeLabel(n.label, color);
    label.position.set(n.x, n.y + 16, z);
    group.add(label);
  });
  scene.add(group);

  const tooltip = document.getElementById('tooltip');
  const raycaster = new THREE.Raycaster();
  const pointer = new THREE.Vector2();
  const hovered = { mesh: null };

  function animate() {
    requestAnimationFrame(animate);
    controls.update();
    raycaster.setFromCamera(pointer, camera);
    const hits = raycaster.intersectObjects(spheres);
    const hit = hits.length > 0 ? hits[0].object : null;
    if (hit !== hovered.mesh) {
      hovered.mesh = hit;
      if (hit) {
        const n = hit.userData.node;
        tooltip.textContent = n.label + ' · ' + n.id;
        tooltip.style.display = 'block';
      } else {
        tooltip.style.display = 'none';
      }
    }
    renderer.render(scene, camera);
  }
  animate();

  addEventListener('pointermove', function (e) {
    pointer.x = (e.clientX / innerWidth) * 2 - 1;
    pointer.y = -(e.clientY / innerHeight) * 2 + 1;
  });
  addEventListener('resize', function () {
    camera.aspect = innerWidth / innerHeight;
    camera.updateProjectionMatrix();
    renderer.setSize(innerWidth, innerHeight);
  });
})();
</script>
</body>
</html>
''';
}

String _esc(String s) =>
    s.replaceAll('\\', '\\\\').replaceAll('"', '\\"').replaceAll('\n', ' ');