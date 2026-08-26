import { useSyncExternalStore } from 'react';

export type Theme = 'dark' | 'light' | 'system';

const STORAGE_KEY = 'canvas-theme';
let current: Theme = (localStorage.getItem(STORAGE_KEY) as Theme) || 'system';

const listeners = new Set<() => void>();
function emit() { listeners.forEach((l) => l()); }

function systemPrefersLight(): boolean {
  return window.matchMedia('(prefers-color-scheme: light)').matches;
}

function resolved(t: Theme): 'dark' | 'light' {
  return t === 'system' ? (systemPrefersLight() ? 'light' : 'dark') : t;
}

function apply() {
  document.documentElement.dataset.theme = resolved(current);
}

// Listener del sistema para modo "system"
window.matchMedia('(prefers-color-scheme: light)').addEventListener('change', () => {
  if (current === 'system') apply();
});

apply();

export function getTheme(): Theme { return current; }
export function getResolvedTheme(): 'dark' | 'light' { return resolved(current); }

export function setTheme(t: Theme) {
  current = t;
  localStorage.setItem(STORAGE_KEY, t);
  apply();
  emit();
}

export function toggleTheme() {
  setTheme(resolved(current) === 'dark' ? 'light' : 'dark');
}

export function useTheme(): { theme: Theme; resolved: 'dark' | 'light'; setTheme: typeof setTheme; toggle: typeof toggleTheme } {
  useSyncExternalStore(
    (cb) => { listeners.add(cb); return () => listeners.delete(cb); },
    () => current
  );
  return { theme: current, resolved: resolved(current), setTheme, toggle: toggleTheme };
}
