import { useCallback } from 'react';
import { create } from 'zustand';
import es from './locales/es.json';
import en from './locales/en.json';

export type Locale = 'es' | 'en';

const dictionaries: Record<string, Record<string, string>> = { es, en };
export const SUPPORTED_LOCALES: Locale[] = ['es', 'en'];

const STORAGE_KEY = 'canvas-locale';

function detect(): Locale {
  const saved = localStorage.getItem(STORAGE_KEY) as Locale | null;
  if (saved && dictionaries[saved]) return saved;
  const nav = navigator.language.slice(0, 2);
  return dictionaries[nav] ? (nav as Locale) : 'es';
}

interface I18nState {
  locale: Locale;
  setLocale: (l: Locale) => void;
}

const initial = (): Locale => {
  const l = detect();
  document.documentElement.lang = l;
  return l;
};

export const useI18nStore = create<I18nState>((set) => ({
  locale: initial(),
  setLocale: (l) => {
    if (!dictionaries[l]) return;
    localStorage.setItem(STORAGE_KEY, l);
    document.documentElement.lang = l;
    set({ locale: l });
  },
}));

function translateWith(locale: Locale, key: string, vars?: Record<string, string | number>): string {
  const raw = dictionaries[locale][key] ?? dictionaries.en[key] ?? key;
  if (!vars) return raw;
  return Object.entries(vars).reduce(
    (acc, [k, v]) => acc.replaceAll(`{${k}}`, String(v)),
    raw
  );
}

/**
 * Hook reactivo de i18n.
 * IMPORTANTE (React Compiler): `t` se crea POR LOCALE — el compiler ve la
 * dependencia `locale` y re-renderiza los textos al cambiar de idioma.
 * Una función estable de módulo NO sirve (memoiza el texto viejo).
 */
export function useI18n() {
  const locale = useI18nStore((s) => s.locale);
  const setLocale = useI18nStore((s) => s.setLocale);
  const t = useCallback(
    (key: string, vars?: Record<string, string | number>) => translateWith(locale, key, vars),
    [locale]
  );
  return { locale, t, setLocale };
}
