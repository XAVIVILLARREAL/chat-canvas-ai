#!/usr/bin/env node
/**
 * test-provider.mjs — Humo del provider LLM free (regla free-first).
 *
 * Verifica contra OpenRouter REAL:
 *  1. La key es válida.
 *  2. El modelo de pruebas (stealth/ox-alpha) responde un chat completion.
 *  3. El costo es $0 (free) — si dejara de serlo, avisamos.
 *
 * Config: OPENROUTER_API_KEY + CANVAS_TEST_MODEL (desde .env o entorno).
 * Uso: node scripts/test-provider.mjs   (o: pnpm test:provider)
 */
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

// Cargar .env simple (KEY=VALUE por línea)
const envFile = path.join(root, ".env");
if (fs.existsSync(envFile)) {
  for (const line of fs.readFileSync(envFile, "utf-8").split("\n")) {
    const m = line.match(/^([A-Z_]+)=(.*)$/);
    if (m && !process.env[m[1]]) process.env[m[1]] = m[2].trim();
  }
}

const KEY = process.env.OPENROUTER_API_KEY;
const MODEL = process.env.CANVAS_TEST_MODEL || "stealth/ox-alpha";
const BASE = process.env.OPENROUTER_BASE || "https://openrouter.ai/api/v1";

if (!KEY) {
  console.error("FALTA OPENROUTER_API_KEY (.env o entorno). Setup: docs/DEV-ENVIRONMENT.md");
  process.exit(1);
}

// 1) Key válida
const keyRes = await fetch(`${BASE}/key`, { headers: { Authorization: `Bearer ${KEY}` } });
if (!keyRes.ok) {
  console.error(`❌ Key inválida o rechazada (HTTP ${keyRes.status})`);
  process.exit(1);
}
console.log("✅ Key válida");

// 2) Chat completion real
let data;
try {
  const res = await fetch(`${BASE}/chat/completions`, {
    method: "POST",
    headers: { Authorization: `Bearer ${KEY}`, "Content-Type": "application/json" },
    body: JSON.stringify({
      model: MODEL,
      messages: [{ role: "user", content: "Responde exactamente: OK" }],
      max_tokens: 2000,
    }),
  });
  data = await res.json();
} catch (e) {
  console.error("❌ Error de red:", e.message);
  process.exit(1);
}

if (!data.choices?.[0]) {
  console.error(`❌ Sin respuesta del modelo ${MODEL}:`, JSON.stringify(data).slice(0, 300));
  process.exit(1);
}

const content = data.choices[0].message?.content ?? "";
const usage = data.usage ?? {};
const cost = usage.cost ?? usage.cost_details?.upstream_inference_cost ?? 0;

console.log(`✅ Modelo ${data.model} respondió (${String(content).trim().slice(0, 60)!=="OK"?"texto libre":"OK"})`);
console.log(`   tokens: ${usage.total_tokens} · cost: $${cost}`);

// 3) Regla free-first: el modelo de pruebas debe ser gratis
if (Number(cost) > 0) {
  console.warn(`⚠️ ATENCIÓN: ${MODEL} ya NO es gratis (cost=$${cost}). Elegir otro :free en OpenRouter y actualizar CANVAS_TEST_MODEL + registro BYOK.`);
  process.exit(2); // no rompe CI pero lo señala fuerte
}
console.log("OK: provider free-first operativo ($0).");
