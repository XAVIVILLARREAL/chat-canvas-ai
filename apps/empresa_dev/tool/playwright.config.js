// Config de E2E web del flujo crítico (Etapa 7, SDD-120).
// Se corre con tool/e2e_web.ps1: build web -> servidor estático 8765 -> tests.
// @ts-check
const { defineConfig } = require('@playwright/test');

module.exports = defineConfig({
  testDir: '.',
  testMatch: 'e2e_web.spec.js',
  timeout: 60_000,
  workers: 1,
  retries: 1,
  reporter: [['list']],
  use: { baseURL: 'http://127.0.0.1:8765', headless: true },
  projects: [{ name: 'chromium', use: { browserName: 'chromium' } }],
});
