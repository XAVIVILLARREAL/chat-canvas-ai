#!/usr/bin/env node
/**
 * check-coverage.mjs — Enforce la REGLA DURA "COVERAGE GUI 100%".
 *
 * Lee docs/COVERAGE-GUI.md y verifica:
 *  - Toda fila marcada ✅ tiene SU archivo de test humano en e2e/human/tests/.
 *  - Ningún test humano queda huérfano (existe sin fila en la tabla).
 *
 * Estado ⬜ (no escrito) / 🟡 (escrito sin gate) no fallan; se reportan.
 * Una fila ✅ sin archivo = CI rojo = la feature NO existe.
 *
 * Uso: node scripts/check-coverage.mjs   (o: pnpm test:coverage)
 */
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const coveragePath = path.join(root, "docs", "COVERAGE-GUI.md");
const testsDir = path.join(root, "e2e", "human", "tests");

if (!fs.existsSync(coveragePath)) {
  console.error("FALTA docs/COVERAGE-GUI.md");
  process.exit(1);
}

const text = fs.readFileSync(coveragePath, "utf-8");
const rowRe = /^\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|\s*`([^`]+\.spec\.ts)`\s*\|\s*(⬜|🟡|✅)\s*\|/gm;

const rows = [];
let m;
while ((m = rowRe.exec(text))) {
  rows.push({ vista: m[1], elem: m[2], accion: m[3], file: m[4], state: m[5] });
}

const byState = { "✅": 0, "🟡": 0, "⬜": 0 };
const greenFiles = new Set();
for (const r of rows) {
  byState[r.state]++;
  if (r.state === "✅") greenFiles.add(r.file);
}

let failures = 0;

// 1) Fila ✅ sin archivo de test
for (const r of rows) {
  if (r.state === "✅" && !fs.existsSync(path.join(testsDir, r.file))) {
    failures++;
    console.error(`❌ Fila ✅ sin test: ${r.file}  (${r.vista} → ${r.elem})`);
  }
}

// 2) Archivos de test huérfanos (existen pero sin fila)
const orphan = new Set();
if (fs.existsSync(testsDir)) {
  for (const f of fs.readdirSync(testsDir)) {
    if (f.endsWith(".spec.ts") && !rows.some((r) => r.file === f)) orphan.add(f);
  }
}
for (const f of orphan) {
  failures++;
  console.error(`❌ Test huérfano (sin fila en COVERAGE-GUI): ${f}`);
}

console.log(
  `COVERAGE-GUI: ${rows.length} elementos · ✅ ${byState["✅"]} · 🟡 ${byState["🟡"]} · ⬜ ${byState["⬜"]}`
);
if (failures > 0) {
  console.error(`FAIL: ${failures} problema(s) de cobertura.`);
  process.exit(1);
}
console.log("OK: toda fila ✅ tiene su test humano. (⬜/🟡 pendientes no bloquean)");
