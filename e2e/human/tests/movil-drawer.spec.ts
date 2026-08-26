import { test, expect } from "../human-fixture";

test.describe("Móvil 375 — drawer del sidebar y sin scroll horizontal", () => {
  test("@core el panel se abre/cierra como drawer y la página no desborda", async ({ h, page }, testInfo) => {
    // Solo tiene sentido en el proyecto móvil
    test.skip(!testInfo.project.name.includes("mobile"), "Solo en proyecto móvil");

    const { step, humanClick, humanThink } = h;

    await step("abro la app en móvil", async () => {
      await page.goto("/");
      await expect(page.getByRole("heading", { name: "Canvas AI" })).toBeVisible();
    });
    await humanThink();

    await step("sin scroll horizontal al cargar", async () => {
      const { scrollWidth, innerWidth } = await page.evaluate(() => ({
        scrollWidth: document.documentElement.scrollWidth,
        innerWidth: window.innerWidth,
      }));
      expect(scrollWidth).toBeLessThanOrEqual(innerWidth + 1);
    });

    const toggle = page.getByRole("button", { name: /Mostrar\/ocultar panel/i });

    await step("abro el panel (drawer)", async () => {
      await humanClick(toggle);
      // espera a que termine la transición de deslizamiento
      await expect
        .poll(async () => (await page.locator(".app-sidebar").boundingBox())?.x ?? -1, {
          timeout: 2_000,
        })
        .toBeGreaterThanOrEqual(0);
    });

    await step("el drawer no desborda la pantalla", async () => {
      const { scrollWidth, innerWidth } = await page.evaluate(() => ({
        scrollWidth: document.documentElement.scrollWidth,
        innerWidth: window.innerWidth,
      }));
      expect(scrollWidth).toBeLessThanOrEqual(innerWidth + 1);
    });

    await step("cierro el panel — queda fuera de pantalla", async () => {
      await humanClick(toggle);
      const ancho = page.viewportSize()!.width;
      // espera a que la transición de cierre termine
      await expect
        .poll(async () => (await page.locator(".app-sidebar").boundingBox())?.x ?? -1, {
          timeout: 2_000,
        })
        .toBeGreaterThanOrEqual(ancho - 1);
    });
  });
});
