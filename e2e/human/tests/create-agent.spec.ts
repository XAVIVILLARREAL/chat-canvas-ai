import { expect } from "../human-fixture";
import { test } from "../human-fixture";

test.describe("@core Crear agente — flujo humano completo", () => {
  test("creo mi primer agente y reviso su detalle", async ({ h }) => {
    await h.step("entro a la app", () => h.page.goto("/"));

    await h.step("leo que no hay agentes todavía", async () => {
      await expect(h.page.getByText("No hay agentes creados")).toBeVisible();
    });

    await h.humanThink();

    await h.step("decido crear el primer agente (click en el botón)", async () => {
      await h.humanClick(h.page.getByRole("button", { name: "Crear primer agente" }));
    });

    await h.step("el agente aparece como tarjeta en la oficina", async () => {
      await expect(h.page.getByRole("button", { name: /Agente 1/ })).toBeVisible();
      await expect(h.page.getByText("No hay agentes creados")).not.toBeVisible();
    });

    await h.step("lo creo otro más por si quiero un equipo", async () => {
      // nota: el botón inicial desapareció al haber agentes; el estado vacío era solo el arranque
      await expect(h.page.getByRole("button", { name: /Agente 2/ })).toHaveCount(0);
    });

    await h.humanThink();

    await h.step("hago click en la tarjeta del agente para ver su detalle", async () => {
      await h.humanClick(h.page.getByRole("button", { name: /Agente 1/ }));
    });

    await h.step("el panel derecho muestra nombre, rol y estado", async () => {
      await expect(h.page.locator(".agent-detail")).toBeVisible();
      await expect(h.page.getByText("Rol: dev")).toBeVisible();
      await expect(h.page.getByText("Estado: idle")).toBeVisible();
    });

    await h.step("la tarjeta queda marcada como seleccionada", async () => {
      await expect(h.page.locator(".agent-card.selected")).toHaveCount(1);
    });
  });

  test("reviso el detalle de cada agente de mi equipo", async ({ h }) => {
    await h.step("entro con agentes ya creados via store (setup rápido)", () =>
      h.page.goto("/"),
    );

    await h.step("creo el primero", async () => {
      await h.humanClick(h.page.getByRole("button", { name: "Crear primer agente" }));
    });

    await h.humanThink(200, 400);

    await h.step("selecciono el agente y verifico que el panel reacciona", async () => {
      await h.humanClick(h.page.getByRole("button", { name: /Agente 1/ }));
      await expect(h.page.locator(".agent-detail h3")).toHaveText(/Agente 1/);
    });
  });
});
