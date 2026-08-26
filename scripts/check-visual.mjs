#!/usr/bin/env node
/**
 * check-visual.mjs — Calidad visual (SDD-013 §8): Liquid Glass hoy, VR-ready mañana.
 *
 * Reglas verificadas sobre src/ (componentes y stores, NO el archivo de tokens):
 *  1. Cero colores hex hardcodeados fuera de styles.css (tokens oklch canónicos).
 *  2. Cero `position:absolute` en componentes del canvas (SpatialMeta manda).
 *
 * Mecanismo de BASELINE: la deuda actual está registrada en scripts/.visual-baseline.
 * El build FALLA si el conteo actual > baseline (la deuda solo puede BAJAR).
 * Para bajar el baseline: arregla violaciones, corre con --update-baseline.
 *
 * Uso: node scripts/check-visual.mjs [--update-baseline]
 */
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const srcDir = path.join(root, "src");
const baselineFile = path.join(root, "scripts", ".visual-baseline");
const update = process.argv.includes("--update-baseline");

// Archivos donde los hex SÍ son legítimos (definición de tokens)
const ALLOW_TOKEN_FILES = /styles\.css$/;
const HEX_RE = /#[0-9a-fA-F]{6}\b|#[0-9a-fA-F]{3}\b/;
const ABS_RE = /position:\s*absolute|position:\s*"absolute"/;

function* walk(dir) {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) yield* walk(p);
    else if (/\.(tsx?|css)$/.test(e.name)) yield p;
  }
}

let violations = 0;
const details = [];
for (const file of walk(srcDir)) {
  if (ALLOW_TOKEN_FILES.test(file)) continue; // tokens canónicos
  const rel = path.relative(root, file);
  const lines = fs.readFileSync(file, "utf-8").split("\n");
  lines.forEach((line, i) => {
    if (/\/\/|\/\*|\*/.test(line) && !/[\"'`]/.test(line)) return; // saltar comentarios simples
    if (HEX_RE.test(line) && /\.(tsx|ts)$/.test(file)) {
      violations++;
      details.push(`hex hardcodeado: ${rel}:${i + 1}`);
    }
    if (ABS_RE.test(line) && /canvas/i.test(rel)) {
      violations++;
      details.push(`position:absolute en canvas: ${rel}:${i + 1}`);
    }
  });
}

let baseline = Infinity;
if (fs.existsSync(baselineFile)) {
  baseline = parseInt(fs.readFileSync(baselineFile, "utf-8").trim(), 10) || 0;
}

if (update || !fs.existsSync(baselineFile)) {
  fs.writeFileSync(baselineFile, String(violations));
  console.log(`Baseline visual guardado: ${violations} violaciones.`);
  process.exit(0);
}

console.log(
  `Calidad visual (SDD-013 §8): ${violations} violaciones · baseline ${baseline} · deuda ${
    violations <= baseline ? "bajando o estable ✅" : "SUBIENDO ❌"
  }`
);

if (violations > baseline) {
  console.error("FAIL: la deuda visual creció. Arregla las nuevas violaciones (usa tokens oklch, SpatialMeta).");
  for (const d of details.slice(0, 20)) console.error("  -", d);
  process.exit(1);
}
console.log("OK: calidad visual estable o mejorando.");
