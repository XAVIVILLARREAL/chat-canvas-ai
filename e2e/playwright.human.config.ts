import { defineConfig, devices } from "@playwright/test";

// Suite HUMANA: simula a una persona real operando la app.
// Video siempre, screenshots por paso (los toma el fixture), trace en retry.
const CI = !!process.env.CI;

export default defineConfig({
  testDir: "./human/tests",
  fullyParallel: false, // humano = secuencial, una persona a la vez
  forbidOnly: CI,
  retries: CI ? 1 : 0,
  workers: 1,
  timeout: 90_000,

  use: {
    baseURL: "http://127.0.0.1:1420",
    video: "on", // evidencia completa SIEMPRE
    trace: "on-first-retry",
    screenshot: "only-on-failure", // los pasos normales los captura h.step()
    actionTimeout: 10_000,
    viewport: { width: 1440, height: 900 },
    locale: "es-MX",
  },

  projects: [
    { name: "human-desktop", use: { ...devices["Desktop Chrome"], viewport: { width: 1440, height: 900 } } },
    { name: "human-mobile", use: { ...devices["Pixel 7"] } },
  ],

  reporter: CI
    ? [["html", { open: "never", outputFolder: "evidence/human/report" }], ["list"]]
    : [["list"], ["html", { open: "never", outputFolder: "evidence/human/report" }]],
});
