import { create } from 'zustand';

export type Theme = 'dark' | 'light' | 'system';

const STORAGE_KEY = 'canvas-theme';

function systemPrefersLight(): boolean {
  return window.matchMedia('(prefers-color-scheme: light)').matches;
}

function resolve(t: Theme): 'dark' | 'light' {
  return t === 'system' ? (systemPrefersLight() ? 'light' : 'dark') : t;
}

function apply(t: Theme) {
  document.documentElement.dataset.theme = resolve(t);
}

const initial = (): Theme => {
  const saved = (localStorage.getItem(STORAGE_KEY) as Theme) || 'system';
  apply(saved);
  return saved;
};

interface ThemeState {
  theme: Theme;
  setTheme: (t: Theme) => void;
  toggle: () => void;
}

export const useThemeStore = create<ThemeState>((set, get) => ({
  theme: initial(),
  setTheme: (t) => {
    localStorage.setItem(STORAGE_KEY, t);
    apply(t);
    set({ theme: t });
  },
  toggle: () => {
    const next = resolve(get().theme) === 'dark' ? 'light' : 'dark';
    get().setTheme(next);
  },
}));

// El modo "system" sigue al OS en vivo
window.matchMedia('(prefers-color-scheme: light)').addEventListener('change', () => {
  apply(useThemeStore.getState().theme);
});

export function useTheme() {
  const theme = useThemeStore((s) => s.theme);
  const setTheme = useThemeStore((s) => s.setTheme);
  const toggle = useThemeStore((s) => s.toggle);
  return { theme, resolved: resolve(theme), setTheme, toggle };
}
