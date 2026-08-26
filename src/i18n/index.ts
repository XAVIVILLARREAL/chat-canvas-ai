import { useSyncExternalStore } from 'react';
import es from './locales/es.json';
import en from './locales/en.json';

export type Locale = 'es' | 'en';

const dictionaries: Record<string, Record<string, string>> = {
  es,
  en,
};

export const SUPPORTED_LOCALES: Locale[] = ['es', 'en'];

const STORAGE_KEY = 'canvas-locale';
function detect(): Locale {
  const saved = localStorage.getItem(STORAGE_KEY) as Locale | null;
  if (saved && dictionaries[saved]) return saved;
  const nav = navigator.language.slice(0, 2);
  return dictionaries[nav] ? (nav as Locale) : 'es';
}

let current: Locale = detect();
const listeners = new Set<() => void>();
function emit() { listeners.forEach((l) => l()); }

document.documentElement.lang = current;

export function getLocale(): Locale { return current; }

export function setLocale(l: Locale) {
  if (!dictionaries[l]) return;
  current = l;
  localStorage.setItem(STORAGE_KEY, l);
  document.documentElement.lang = l;
  emit();
}

/** Traduce una clave; soporta {vars}. Fallback: inglés → la clave misma. */
export function translate(key: string, vars?: Record<string, string | number>): string {
  const raw =
    dictionaries[current][key] ??
    dictionaries.en[key] ??
    key;
  if (!vars) return raw;
  return Object.entries(vars).reduce(
    (acc, [k, v]) => acc.replaceAll(`{${k}}`, String(v)),
    raw
  );
}

export function useI18n() {
  useSyncExternalStore(
    (cb) => { listeners.add(cb); return () => listeners.delete(cb); },
    () => current
  );
  return { locale: current, t: translate, setLocale };
}
