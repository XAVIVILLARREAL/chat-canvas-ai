import { expect } from "../human-fixture";
import { test } from "../human-fixture";

test.describe("@core Boot — primera impresión como humano", () => {
  test("abro la app y entiendo qué es", async ({ h, page }, testInfo) => {
    const esMovil = testInfo.project.name.includes("mobile");
    // En móvil el sidebar es drawer: abrirlo para operar el panel
    const abrirPanelSiCerrado = async () => {
      const abierta = await page.locator(".app-sidebar").evaluate((el) => {
        const r = el.getBoundingClientRect();
        return r.left < window.innerWidth && r.width > 50;
      });
      if (!abierta) {
        await h.humanClick(h.page.locator(".header-left button").first());
        await h.page.waitForTimeout(400);
      }
    };

    await h.step("abro la aplicación", () => h.page.goto("/"));

    await h.step("veo el título principal", async () => {
      const titulo = h.page.getByRole("heading", { level: 1 });
      await expect(titulo).toHaveText("Canvas AI");
    });

    await h.humanThink();

    await h.step("leo el subtítulo que explica el producto", async () => {
      if (!esMovil) {
        await expect(h.page.getByText("Automatizaciones con IA nativa")).toBeVisible();
      }
    });

    await h.step("veo las secciones de trabajo: Skills, Agentes, MCP", async () => {
      if (esMovil) await abrirPanelSiCerrado();
      await expect(h.page.getByRole("button", { name: "Skills" }).first()).toBeVisible();
      await expect(h.page.getByRole("button", { name: "Agentes" }).first()).toBeVisible();
      await expect(h.page.getByRole("button", { name: "MCP", exact: true }).first()).toBeVisible();
    });

    await h.step("scrolleo para ver toda la página", () => h.humanWheel(300));
    await h.step("vuelvo arriba con la rueda", () => h.humanWheel(-300));

    await h.step("el header sigue presente sin errores", async () => {
      await expect(h.page.getByRole("heading", { level: 1 })).toBeVisible();
    });
  });
});
