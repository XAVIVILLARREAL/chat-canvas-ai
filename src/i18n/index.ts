import { useCallback } from 'react';
import { create } from 'zustand';
import es from './locales/es.json';
import en from './locales/en.json';
import zhCN from './locales/zh-CN.json';
import ptBR from './locales/pt-BR.json';
import de from './locales/de.json';
import fr from './locales/fr.json';
import it from './locales/it.json';
import ja from './locales/ja.json';
import ko from './locales/ko.json';
import hi from './locales/hi.json';
import ru from './locales/ru.json';
import ar from './locales/ar.json';

export type Locale =
  | 'en'
  | 'es'
  | 'zh-CN'
  | 'pt-BR'
  | 'de'
  | 'fr'
  | 'it'
  | 'ja'
  | 'ko'
  | 'hi'
  | 'ru'
  | 'ar';

const dictionaries: Record<Locale, Record<string, string>> = {
  en,
  es,
  'zh-CN': zhCN,
  'pt-BR': ptBR,
  de,
  fr,
  it,
  ja,
  ko,
  hi,
  ru,
  ar,
};

export const SUPPORTED_LOCALES: Locale[] = [
  'en',
  'es',
  'zh-CN',
  'pt-BR',
  'de',
  'fr',
  'it',
  'ja',
  'ko',
  'hi',
  'ru',
  'ar',
];

const STORAGE_KEY = 'canvas-locale';

function detect(): Locale {
  const saved = localStorage.getItem(STORAGE_KEY);
  if (saved && saved in dictionaries) return saved as Locale;

  const nav = navigator.language;

  // Exact match first (e.g. "zh-CN", "pt-BR")
  if (nav in dictionaries) return nav as Locale;

  // Prefix match (e.g. "zh" → "zh-CN", "pt" → "pt-BR")
  const prefix = nav.split('-')[0];
  if (prefix === 'zh') return 'zh-CN';
  if (prefix === 'pt') return 'pt-BR';
  if (prefix in dictionaries) return prefix as Locale;

  return 'en';
}

interface I18nState {
  locale: Locale;
  setLocale: (l: Locale) => void;
}

const RTL_LOCALES: Locale[] = ['ar'];

function applyDocAttrs(l: Locale): void {
  document.documentElement.lang = l;
  document.documentElement.dir = RTL_LOCALES.includes(l) ? 'rtl' : 'ltr';
}

const initial = (): Locale => {
  const l = detect();
  applyDocAttrs(l);
  return l;
};

export const useI18nStore = create<I18nState>((set) => ({
  locale: initial(),
  setLocale: (l) => {
    if (!(l in dictionaries)) return;
    localStorage.setItem(STORAGE_KEY, l);
    applyDocAttrs(l);
    set({ locale: l });
  },
}));

/**
 * Traduce una key con fallback a `en` y, si tampoco existe, devuelve la key.
 * Expuesta pública para testing de fallback (plan-i18n §9).
 */
export function translateWith(locale: Locale, key: string, vars?: Record<string, string | number>): string {
  const raw = dictionaries[locale][key] ?? dictionaries.en[key] ?? key;
  if (!vars) return raw;
  return Object.entries(vars).reduce(
    (acc, [k, v]) => acc.replaceAll(`{${k}}`, String(v)),
    raw
  );
}

const dateFmtCache = new Map<string, Intl.DateTimeFormat>();

function intlDateFmt(locale: Locale, opts: Intl.DateTimeFormatOptions): Intl.DateTimeFormat {
  const key = `${locale}:${JSON.stringify(opts)}`;
  let f = dateFmtCache.get(key);
  if (!f) {
    f = new Intl.DateTimeFormat(locale, opts);
    dateFmtCache.set(key, f);
  }
  return f;
}

/**
 * Hook reactivo de i18n.
 * IMPORTANTE (React Compiler): `t` y los formateadores se crean POR LOCALE — el
 * compiler ve la dependencia `locale` y re-renderiza al cambiar de idioma.
 * Una función estable de módulo NO sirve (memoiza el texto viejo).
 */
export function useI18n() {
  const locale = useI18nStore((s) => s.locale);
  const setLocale = useI18nStore((s) => s.setLocale);
  const t = useCallback(
    (key: string, vars?: Record<string, string | number>) => translateWith(locale, key, vars),
    [locale]
  );
  // Números: Intl.NumberFormat (plan-i18n §2.4)
  const formatNumber = useCallback(
    (n: number, opts?: Intl.NumberFormatOptions) =>
      new Intl.NumberFormat(locale, opts).format(n),
    [locale]
  );
  // Fechas: Intl.DateTimeFormat (plan-i18n §2.4)
  const formatDate = useCallback(
    (d: Date | number | string, opts?: Intl.DateTimeFormatOptions) =>
      intlDateFmt(locale, opts ?? { dateStyle: 'medium' }).format(new Date(d)),
    [locale]
  );
  const formatDateTime = useCallback(
    (d: Date | number | string, opts?: Intl.DateTimeFormatOptions) =>
      intlDateFmt(locale, opts ?? { dateStyle: 'medium', timeStyle: 'short' }).format(new Date(d)),
    [locale]
  );
  // Tiempo relativo ("hace 5 min") — los strings cortos por locale:
  const formatRelative = useCallback(
    (d: Date | number | string) => {
      const now = Date.now();
      const then = new Date(d).getTime();
      const seconds = Math.round((then - now) / 1000);
      const abs = Math.abs(seconds);
      const rtf = new Intl.RelativeTimeFormat(locale, { numeric: 'auto' });
      if (abs < 60) return rtf.format(seconds, 'second');
      if (abs < 3600) return rtf.format(Math.round(seconds / 60), 'minute');
      if (abs < 86400) return rtf.format(Math.round(seconds / 3600), 'hour');
      if (abs < 2592000) return rtf.format(Math.round(seconds / 86400), 'day');
      if (abs < 31536000) return rtf.format(Math.round(seconds / 2592000), 'month');
      return rtf.format(Math.round(seconds / 31536000), 'year');
    },
    [locale]
  );
  return { locale, t, setLocale, formatNumber, formatDate, formatDateTime, formatRelative };
}
