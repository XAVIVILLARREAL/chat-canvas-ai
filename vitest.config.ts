import { defineConfig } from "vitest/config";

// Unit tests viven junto al código en src/. Los specs E2E de Playwright (e2e/)
// corren aparte con `pnpm test:e2e`.
export default defineConfig({
  test: {
    include: ["src/**/*.{test,spec}.{ts,tsx}"],
    environment: "node",
  },
});
