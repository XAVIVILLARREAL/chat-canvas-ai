import { test, expect } from "../human-fixture";
import type { Page } from "@playwright/test";

/** Abre la app y devuelve el tema resuelto del <html>. */
async function temaActual(page: Page): Promise<string> {
  return page.evaluate(() => document.documentElement.dataset.theme ?? "(none)");
}

test.describe("Temas dark/light — operado como humano", () => {
  test("@core cambio de tema con clicks, persiste tras recargar", async ({ h }) => {
    const { page, step, humanClick, humanThink } = h;

    await step("abro la app", async () => {
      await page.goto("/");
      await expect(page.getByRole("heading", { name: "Canvas AI" })).toBeVisible();
    });
    await humanThink();

    const temaInicial = await temaActual(page);
    const botonTema = page.getByRole("button", { name: /Cambiar tema/i });

    await step("pulso el toggle de tema en el header", async () => {
      await humanClick(botonTema);
    });
    await step("el tema cambió al alternario", async () => {
      const ahora = await temaActual(page);
      const esperado = temaInicial === "dark" ? "light" : "dark";
      expect(ahora).toBe(esperado);
    });

    await step("recargo la página — el tema persiste", async () => {
      await page.reload();
      await expect(page.getByRole("heading", { name: "Canvas AI" })).toBeVisible();
      expect(await temaActual(page)).toBe(temaInicial === "dark" ? "light" : "dark");
    });

    await step("vuelvo al tema original", async () => {
      await humanClick(botonTema);
      expect(await temaActual(page)).toBe(temaInicial);
    });

    // Si el panel está cerrado (móvil), lo abro como lo haría una persona
    const panelAbierto = async () =>
      page.locator(".app-sidebar").evaluate((el) => {
        const r = el.getBoundingClientRect();
        return r.left < window.innerWidth && r.width > 50;
      });
    if (!(await panelAbierto())) {
      await humanClick(page.getByRole("button", { name: /Mostrar\/ocultar panel/i }));
    }
    await step("Config: el select de tema también funciona", async () => {
      await page.getByRole("button", { name: "Config", exact: true }).click();
      const combo = page.getByRole("combobox", { name: /Cambiar tema/i });
      await combo.selectOption("light");
      expect(await temaActual(page)).toBe("light");
      await combo.selectOption("dark");
      expect(await temaActual(page)).toBe("dark");
    });
  });
});
