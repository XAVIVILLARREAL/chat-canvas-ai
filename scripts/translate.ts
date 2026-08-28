/**
 * translate.ts — AI translation pipeline for Canvas AI i18n
 *
 * Reads en.json (source of truth), translates missing keys to target locales,
 * and writes output files. Provider-agnostic: OpenAI, Anthropic, or Ollama.
 *
 * Usage:
 *   npx tsx scripts/translate.ts                    # translate all pending locales
 *   npx tsx scripts/translate.ts --locale zh-CN     # translate specific locale
 *   npx tsx scripts/translate.ts --provider ollama  # use Ollama instead of OpenAI
 *   npx tsx scripts/translate.ts --dry-run          # preview without writing
 *
 * Env vars:
 *   OPENAI_API_KEY     — for OpenAI provider (default)
 *   OPENAI_BASE_URL    — custom base URL (optional)
 *   OLLAMA_BASE_URL    — for Ollama provider (default: http://localhost:11434)
 *   TRANSLATE_MODEL    — model override (default: gpt-4o-mini / qwen3:8b)
 */

import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const LOCALES_DIR = resolve(__dirname, '../src/i18n/locales');

// ── Config ──────────────────────────────────────────────────────────────────

type Provider = 'openai' | 'ollama';

interface Config {
  provider: Provider;
  model: string;
  baseUrl: string;
  apiKey: string;
  dryRun: boolean;
  targetLocale: string | null;
  batchSize: number;
}

const LOCALE_NAMES: Record<string, string> = {
  'zh-CN': 'Simplified Chinese',
  'pt-BR': 'Brazilian Portuguese',
  'de': 'German',
  'fr': 'French',
  'it': 'Italian',
  'ja': 'Japanese',
  'ko': 'Korean',
  'hi': 'Hindi',
  'ru': 'Russian',
  'ar': 'Arabic',
};

const ALL_TARGET_LOCALES = Object.keys(LOCALE_NAMES);

// ── CLI args ────────────────────────────────────────────────────────────────

function parseArgs(): Partial<Config> {
  const args = process.argv.slice(2);
  const config: Partial<Config> = {};

  for (let i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--locale':
      case '-l':
        config.targetLocale = args[++i];
        break;
      case '--provider':
      case '-p':
        config.provider = args[++i] as Provider;
        break;
      case '--model':
      case '-m':
        config.model = args[++i];
        break;
      case '--dry-run':
      case '-d':
        config.dryRun = true;
        break;
      case '--batch-size':
      case '-b':
        config.batchSize = Number.parseInt(args[++i], 10);
        break;
      case '--help':
      case '-h':
        console.log(`
translate.ts — AI translation pipeline for Canvas AI i18n

Usage:
  npx tsx scripts/translate.ts [options]

Options:
  --locale, -l <locale>    Translate specific locale (e.g. zh-CN)
  --provider, -p <p>       Provider: openai (default) | ollama
  --model, -m <model>      Model override
  --batch-size, -n <n>     Keys per batch (default: 50)
  --dry-run, -d            Preview without writing files
  --help, -h               Show this help

Env vars:
  OPENAI_API_KEY           API key for OpenAI
  OPENAI_BASE_URL          Custom base URL (optional)
  OLLAMA_BASE_URL          Ollama URL (default: http://localhost:11434)
  TRANSLATE_MODEL          Model override
`);
        process.exit(0);
    }
  }

  return config;
}

// ── Provider abstraction ─────────────────────────────────────────────────────

interface TranslateResult {
  translations: Record<string, string>;
}

async function translateBatchOpenAI(
  keys: string[],
  sourceTexts: Record<string, string>,
  targetLang: string,
  config: Config
): Promise<Record<string, string>> {
  const systemPrompt = `You are a professional translator for a software UI application called "Canvas AI".
Translate the following UI strings from English to ${targetLang} (${LOCALE_NAMES[targetLang] || targetLang}).

Rules:
- Keep translation natural and idiomatic for the target language
- Preserve {variable} placeholders exactly as-is (they are interpolated at runtime)
- Keep technical terms like "Canvas", "MCP", "Skill", "Agent" untranslated (they are product-specific)
- Keep keyboard shortcuts like (⌘K) as-is
- Do NOT add any explanations or commentary
- Return ONLY a valid JSON object mapping keys to translated values
- Each translation should be concise (UI text, not prose)`;

  const sourceEntries = keys.map((k) => `"${k}": "${sourceTexts[k].replace(/"/g, '\\"')}"`);
  const userPrompt = `Translate these UI strings to ${targetLang}:\n{\n${sourceEntries.join(',\n')}\n}`;

  const response = await fetch(`${config.baseUrl}/v1/chat/completions`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      ...(config.apiKey ? { Authorization: `Bearer ${config.apiKey}` } : {}),
    },
    body: JSON.stringify({
      model: config.model,
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: userPrompt },
      ],
      temperature: 0.3,
      response_format: { type: 'json_object' },
    }),
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`API error ${response.status}: ${error}`);
  }

  const data = await response.json();
  const content = data.choices?.[0]?.message?.content;
  if (!content) throw new Error('Empty response from API');

  const parsed = JSON.parse(content) as Record<string, string>;
  return parsed;
}

async function translateBatchOllama(
  keys: string[],
  sourceTexts: Record<string, string>,
  targetLang: string,
  config: Config
): Promise<Record<string, string>> {
  const systemPrompt = `You are a professional translator for a software UI application called "Canvas AI".
Translate the following UI strings from English to ${targetLang} (${LOCALE_NAMES[targetLang] || targetLang}).

Rules:
- Keep translation natural and idiomatic for the target language
- Preserve {variable} placeholders exactly as-is
- Keep technical terms like "Canvas", "MCP", "Skill", "Agent" untranslated
- Keep keyboard shortcuts like (⌘K) as-is
- Do NOT add any explanations or commentary
- Return ONLY a valid JSON object mapping keys to translated values
- Each translation should be concise (UI text, not prose)`;

  const sourceEntries = keys.map((k) => `"${k}": "${sourceTexts[k].replace(/"/g, '\\"')}"`);
  const userPrompt = `Translate these UI strings to ${targetLang}:\n{\n${sourceEntries.join(',\n')}\n}`;

  const baseUrl = config.baseUrl || 'http://localhost:11434';

  const response = await fetch(`${baseUrl}/api/chat`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      model: config.model,
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: userPrompt },
      ],
      format: 'json',
      stream: false,
    }),
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`Ollama error ${response.status}: ${error}`);
  }

  const data = await response.json();
  const content = data.message?.content;
  if (!content) throw new Error('Empty response from Ollama');

  const parsed = JSON.parse(content) as Record<string, string>;
  return parsed;
}

// ── Main ────────────────────────────────────────────────────────────────────

async function translate(
  keys: string[],
  sourceTexts: Record<string, string>,
  targetLang: string,
  config: Config
): Promise<Record<string, string>> {
  if (config.provider === 'ollama') {
    return translateBatchOllama(keys, sourceTexts, targetLang, config);
  }
  return translateBatchOpenAI(keys, sourceTexts, targetLang, config);
}

async function main() {
  const argConfig = parseArgs();

  const provider = argConfig.provider || (process.env.OLLAMA_BASE_URL ? 'ollama' : 'openai');
  const config: Config = {
    provider,
    model:
      argConfig.model ||
      process.env.TRANSLATE_MODEL ||
      (provider === 'ollama' ? 'qwen3:8b' : 'gpt-4o-mini'),
    baseUrl:
      argConfig.baseUrl ||
      (provider === 'ollama'
        ? process.env.OLLAMA_BASE_URL || 'http://localhost:11434'
        : process.env.OPENAI_BASE_URL || 'https://api.openai.com'),
    apiKey: provider === 'openai' ? process.env.OPENAI_API_KEY || '' : '',
    dryRun: argConfig.dryRun || false,
    targetLocale: argConfig.targetLocale || null,
    batchSize: argConfig.batchSize || 50,
  };

  // Load source
  const sourcePath = resolve(LOCALES_DIR, 'en.json');
  const source: Record<string, string> = JSON.parse(readFileSync(sourcePath, 'utf-8'));
  const sourceKeys = Object.keys(source);

  console.log(`📖 Source: en.json (${sourceKeys.length} keys)`);

  const targets = config.targetLocale
    ? [config.targetLocale]
    : ALL_TARGET_LOCALES;

  for (const locale of targets) {
    console.log(`\n🌍 Translating to ${locale} (${LOCALE_NAMES[locale] || locale})...`);

    const targetPath = resolve(LOCALES_DIR, `${locale}.json`);
    const existing: Record<string, string> = existsSync(targetPath)
      ? JSON.parse(readFileSync(targetPath, 'utf-8'))
      : {};

    // Find missing keys
    const missingKeys = sourceKeys.filter((k) => !existing[k]);
    if (missingKeys.length === 0) {
      console.log(`  ✅ All keys present — skipping`);
      continue;
    }

    console.log(`  📝 Missing ${missingKeys.length} keys: ${missingKeys.slice(0, 5).join(', ')}${missingKeys.length > 5 ? '...' : ''}`);

    if (config.dryRun) {
      console.log(`  🔍 Dry run — would translate ${missingKeys.length} keys`);
      continue;
    }

    // Translate in batches
    const result: Record<string, string> = { ...existing };
    const batches: string[][] = [];
    for (let i = 0; i < missingKeys.length; i += config.batchSize) {
      batches.push(missingKeys.slice(i, i + config.batchSize));
    }

    for (let b = 0; b < batches.length; b++) {
      const batch = batches[b];
      console.log(`  ⏳ Batch ${b + 1}/${batches.length} (${batch.length} keys)...`);

      try {
        const translations = await translate(batch, source, locale, config);
        for (const key of batch) {
          if (translations[key]) {
            result[key] = translations[key];
          } else {
            // Fallback: use English if translation missing
            console.log(`  ⚠️  Missing translation for "${key}" — falling back to en`);
            result[key] = source[key];
          }
        }
      } catch (error) {
        console.error(`  ❌ Batch ${b + 1} failed:`, error);
        // Fallback: use English for failed batch
        for (const key of batch) {
          if (!result[key]) result[key] = source[key];
        }
      }

      // Small delay between batches to avoid rate limits
      if (b < batches.length - 1) {
        await new Promise((r) => setTimeout(r, 500));
      }
    }

    // Write output — preserve key order from en.json
    const ordered: Record<string, string> = {};
    for (const key of sourceKeys) {
      ordered[key] = result[key] || source[key];
    }

    const targetPathFinal = resolve(LOCALES_DIR, `${locale}.json`);
    writeFileSync(targetPathFinal, `${JSON.stringify(ordered, null, 2)}\n`);
    console.log(`  ✅ Written ${targetPathFinal} (${Object.keys(ordered).length} keys)`);
  }

  console.log('\n🎉 Done!');
}

main().catch((err) => {
  console.error('Fatal error:', err);
  process.exit(1);
});
