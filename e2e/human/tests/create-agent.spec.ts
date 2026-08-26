import { expect } from "../human-fixture";
import { test } from "../human-fixture";

test.describe("@core Crear agente — flujo humano completo", () => {
  test("creo mi primer agente y lo selecciono", async ({ h, page }, testInfo) => {
    const esMovil = testInfo.project.name.includes("mobile");
    const { page: _p, step, humanClick, humanFill, humanThink } = h;
    // En móvil el sidebar es drawer: abrirlo para operar el panel
    const abrirPanelSiCerrado = async () => {
      const abierta = await h.page.locator(".app-sidebar").evaluate((el) => {
        const r = el.getBoundingClientRect();
        return r.left < window.innerWidth && r.width > 50;
      });
      if (!abierta) {
        await humanClick(h.page.locator(".header-left button").first());
        await h.page.waitForTimeout(700); // transición del drawer
      }
    };


    await step("entro a la app y voy a la pestaña Agentes", async () => {
      await h.page.goto("/");
      await abrirPanelSiCerrado();
      await humanClick(h.page.getByRole("button", { name: "Agentes" }).first());
    });

    await step("leo que no hay agentes todavía", async () => {
      await expect(h.page.getByText("No hay agentes")).toBeVisible();
    });

    await humanThink();

    await step("decido crear el primer agente (abre el modal)", async () => {
      await humanClick(h.page.getByRole("button", { name: /Crear Agente|Nuevo Agente/ }).first());
      await expect(page.getByRole("dialog")).toBeVisible();
    });

    await step("le pongo nombre y lo guardo", async () => {
      await humanFill(h.page.getByRole("textbox", { name: "Nombre" }), "Mi Primer Agente");
      await h.page.getByRole("button", { name: "Guardar" }).click();
    });

    await step("el agente aparece en la lista y queda seleccionado", async () => {
      await expect(h.page.getByText("Mi Primer Agente")).toBeVisible();
      await expect(h.page.locator(".item.selected")).toHaveCount(1);
      await expect(h.page.getByText("No hay agentes")).not.toBeVisible();
    });

    await humanThink();

    await step("su detalle está accesible en la lista (item seleccionado)", async () => {
      await expect(h.page.locator(".item.selected .item-name")).toHaveText("Mi Primer Agente");
    });
  });

  test("reviso el detalle de cada agente de mi equipo", async ({ h, page }, testInfo) => {
    const esMovil = testInfo.project.name.includes("mobile");
    const { step, humanClick, humanFill, humanThink } = h;
    // En móvil el sidebar es drawer: abrirlo para operar el panel
    const abrirPanelSiCerrado = async () => {
      const abierta = await h.page.locator(".app-sidebar").evaluate((el) => {
        const r = el.getBoundingClientRect();
        return r.left < window.innerWidth && r.width > 50;
      });
      if (!abierta) {
        await humanClick(h.page.locator(".header-left button").first());
        await h.page.waitForTimeout(700); // transición del drawer
      }
    };


    await step("entro y creo el primero", async () => {
      await h.page.goto("/");
      await abrirPanelSiCerrado();
      await humanClick(h.page.getByRole("button", { name: "Agentes" }).first());
      await humanClick(h.page.getByRole("button", { name: /Crear Agente|Nuevo Agente/ }).first());
      await humanFill(h.page.getByRole("textbox", { name: "Nombre" }), "Agente Uno");
      await h.page.getByRole("button", { name: "Guardar" }).click();
    });

    await humanThink(200, 400);

    await step("creo el segundo", async () => {
      await humanClick(h.page.getByRole("button", { name: /Crear Agente|Nuevo Agente/ }).first());
      await humanFill(h.page.getByRole("textbox", { name: "Nombre" }), "Agente Dos");
      await h.page.getByRole("button", { name: "Guardar" }).click();
    });

    await step("selecciono el primero y el panel reacciona", async () => {
      await humanClick(h.page.locator(".item", { hasText: "Agente Uno" }));
      await expect(h.page.locator(".item.selected .item-name")).toHaveText("Agente Uno");
    });

    await step("selecciono el segundo y la selección cambia", async () => {
      await humanClick(h.page.locator(".item", { hasText: "Agente Dos" }));
      await expect(h.page.locator(".item.selected .item-name")).toHaveText("Agente Dos");
    });
  });
});
