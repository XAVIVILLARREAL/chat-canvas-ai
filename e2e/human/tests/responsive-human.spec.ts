import { expect } from "../human-fixture";
import { test } from "../human-fixture";

// La misma app operada como humano en mobile y desktop (proyectos del config).
test.describe("Responsive — humano en cualquier pantalla", () => {
  test("la interfaz funciona igual de bien en mi pantalla", async ({ h, page }, testInfo) => {
    const esMovil = testInfo.project.name.includes("mobile");
    const { step, humanClick, humanFill, humanThink, humanWheel } = h;

    await step("abro la app", () => page.goto("/"));

    await humanThink();

    await step("encuentro lo esencial sin importar el tamaño", async () => {
      await expect(page.getByRole("heading", { level: 1 })).toBeVisible();
      await expect(page.getByRole("button", { name: "Agentes" }).first()).toBeVisible();
    });

    // En móvil el sidebar es drawer: abro el panel para operar
    const abrirPanelSiCerrado = async () => {
      const abierta = await page.locator(".app-sidebar").evaluate((el) => {
        const r = el.getBoundingClientRect();
        return r.left < window.innerWidth && r.width > 50;
      });
      if (!abierta) {
        await humanClick(page.locator(".header-left button").first());
      }
    };

    await step("voy a Agentes y creo un agente desde esta pantalla", async () => {
      await abrirPanelSiCerrado();
      await humanClick(page.getByRole("button", { name: "Agentes" }).first());
      await humanClick(page.getByRole("button", { name: /Crear Agente|Nuevo Agente/ }).first());
      await humanFill(page.getByRole("textbox", { name: "Nombre" }), "Agente Responsive");
      await page.getByRole("button", { name: "Guardar" }).click();
    });

    await step("interactúo con el agente creado", async () => {
      const item = page.locator(".item", { hasText: "Agente Responsive" });
      await item.scrollIntoViewIfNeeded();
      await humanClick(item);
      await expect(page.locator(".item.selected .item-name")).toHaveText("Agente Responsive");
    });

    await step("hago scroll natural sin roturas", async () => {
      await humanClick(page.locator(".header-left button").first()); // cierro panel si abierto
      await humanWheel(400);
      await humanWheel(-400);
      await expect(page.getByRole("heading", { level: 1 })).toBeVisible();
    });

    await step("sin scroll horizontal en esta pantalla", async () => {
      const { scrollWidth, innerWidth } = await page.evaluate(() => ({
        scrollWidth: document.documentElement.scrollWidth,
        innerWidth: window.innerWidth,
      }));
      expect(scrollWidth).toBeLessThanOrEqual(innerWidth + 1);
    });
  });
});
