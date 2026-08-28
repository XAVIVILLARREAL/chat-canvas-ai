/**
 * i18n-check.mjs — CI gate: detecta missing keys entre locales
 *
 * Compara todas las traducciones contra en.json (fuente canónica).
 * Exit 0 si todo OK, exit 1 si hay keys faltantes.
 *
 * Usage:
 *   node scripts/i18n-check.mjs              # check all locales
 *   node scripts/i18n-check.mjs --locale fr  # check specific locale
 *   node scripts/i18n-check.mjs --strict     # fail on extra keys too
 */

import { readFileSync, readdirSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const LOCALES_DIR = resolve(__dirname, '../src/i18n/locales');

// ── CLI args ────────────────────────────────────────────────────────────────

const args = process.argv.slice(2);
const strict = args.includes('--strict');
const localeIdx = args.indexOf('--locale');
const targetLocale = localeIdx !== -1 ? args[localeIdx + 1] : null;

// ── Load source ─────────────────────────────────────────────────────────────

const source = JSON.parse(readFileSync(resolve(LOCALES_DIR, 'en.json'), 'utf-8'));
const sourceKeys = new Set(Object.keys(source));

// ── Check each locale ───────────────────────────────────────────────────────

const localeFiles = readdirSync(LOCALES_DIR).filter((f) => f.endsWith('.json') && f !== 'en.json');

let hasErrors = false;
const results = [];

for (const file of localeFiles) {
  const locale = file.replace('.json', '');
  if (targetLocale && locale !== targetLocale) continue;

  const localeData = JSON.parse(readFileSync(resolve(LOCALES_DIR, file), 'utf-8'));
  const localeKeys = new Set(Object.keys(localeData));

  const missing = [...sourceKeys].filter((k) => !localeKeys.has(k));
  const extra = [...localeKeys].filter((k) => !sourceKeys.has(k));

  const status = missing.length === 0 && (strict ? extra.length === 0 : true) ? '✅' : '❌';
  if (status === '❌') hasErrors = true;

  results.push({ locale, status, missing, extra });
}

// ── Output ──────────────────────────────────────────────────────────────────

console.log('\n📋 i18n coverage report\n');
console.log(`Source: en.json (${sourceKeys.size} keys)\n`);

for (const r of results) {
  const missingStr = r.missing.length > 0 ? `Missing: ${r.missing.join(', ')}` : '';
  const extraStr = strict && r.extra.length > 0 ? `Extra: ${r.extra.join(', ')}` : '';
  const details = [missingStr, extraStr].filter(Boolean).join(' | ');

  console.log(`${r.status} ${r.locale.padEnd(8)} ${details || 'OK'}`);
}

const totalMissing = results.reduce((acc, r) => acc + r.missing.length, 0);
console.log(`\n${totalMissing === 0 ? '✅ All locales complete' : `❌ ${totalMissing} missing key(s) across all locales`}`);

process.exit(hasErrors ? 1 : 0);
