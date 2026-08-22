import { test as base, expect } from "@playwright/test";

type TestFixtures = {
  tauriPage: Awaited<ReturnType<typeof base["info"]>> extends infer Info
    ? import("@playwright/test").Page
    : never;
};

export const test = base.extend<TestFixtures>({
  tauriPage: async ({ page }, use) => {
    await use(page);
  },
});

export { expect };
