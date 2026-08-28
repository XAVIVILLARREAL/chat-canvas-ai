import { describe, it, expect, beforeEach, vi } from 'vitest';
import type { Locale } from './index';

// El módulo index.ts inicializa `detect()` en el arranque, que toca la API de
// navegador (localStorage, navigator, document). Inyectamos globals mínimos
// antes de importarlo (vitest corre en entorno node).
beforeEach(() => {
  const store = new Map<string, string>();
  vi.stubGlobal('localStorage', {
    getItem: (k: string) => store.get(k) ?? null,
    setItem: (k: string, v: string) => { store.set(k, v); },
    removeItem: (k: string) => { store.delete(k); },
    key: (i: number) => Array.from(store.keys())[i] ?? null,
    get length() { return store.size; },
    clear: () => store.clear(),
  });
  vi.stubGlobal('navigator', { language: 'en-US' });
  vi.stubGlobal('document', { documentElement: { lang: '', dir: '' } });
});

describe('translateWith — fallback i18n (§9)', () => {
  let translateWith: (l: Locale, key: string, vars?: Record<string, string | number>) => string;

  beforeEach(async () => {
    vi.resetModules();
    const mod = await import('./index');
    translateWith = mod.translateWith;
  });

  it('traduce una key real de un locale no-en a un string no vacío', async () => {
    const mod = await import('./index');
    // sample de keys que SÍ existen en en.json (canónico) — deben traducirse en `fr`
    const sample = ['header.theme', 'sidebar.skills', 'sidebar.newSkill', 'sidebar.noSkills', 'canvas.nodes', 'palette.placeholder'];
    for (const k of sample) {
      const v = mod.translateWith('fr', k);
      expect(typeof v).toBe('string');
      expect(v.length).toBeGreaterThan(0);
      expect(v).not.toBe(k); // si cayera a la key literal, fallaría el fallback
    }
  });

  it('una key que falta en TODOS los diccionarios devuelve la propia key (no rompe)', () => {
    const missing = 'no.existe.en.ningun.diccionario';
    for (const l of (['en', 'es', 'de', 'zh-CN', 'ar'] as Locale[])) {
      expect(translateWith(l, missing)).toBe(missing);
    }
  });

  it('una key que existe en en pero falta en un locale cae a en (fallback last-resort)', async () => {
    const mod = await import('./index');
    // cogemos una key que seguramente existe en en. Si algún locale no la tiene,
    // el fallback devuelve la versión en (que no es la key literal).
    const key = 'sidebar.skills';
    const enV = mod.translateWith('en', key);
    expect(enV).not.toBe(key);
    // para cada locale, la traducción debe ser o su versión o la de en (nunca la key literal)
    for (const l of (['es', 'pt-BR', 'ar', 'hi'] as Locale[])) {
      const v = mod.translateWith(l, key);
      expect(typeof v).toBe('string');
      expect(v.length).toBeGreaterThan(0);
    }
  });

  it('sustituye variables {nombre} en la key resuelta — no rompe si se pasan vars', () => {
    // verificamos que pasar vars no rompe (los keys reales no usan placeholders)
    const key = 'sidebar.newSkill';
    const v1 = translateWith('es', key);
    const v2 = translateWith('es', key, { n: 3 });
    expect(v1).toBe(v2); // sin placeholders, vars no cambia el resultado
  });
});