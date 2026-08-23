import { expect } from "../human-fixture";
import { test } from "../human-fixture";

// La misma app operada como humano en mobile y desktop (proyectos del config).
test.describe("Responsive — humano en cualquier pantalla", () => {
  test("la interfaz funciona igual de bien en mi pantalla", async ({ h }) => {
    await h.step("abro la app", () => h.page.goto("/"));

    await h.humanThink();

    await h.step("encuentro todo lo esencial sin importar el tamaño", async () => {
      await expect(h.page.getByRole("heading", { level: 1 })).toBeVisible();
      await expect(h.page.getByRole("heading", { name: "Oficina" })).toBeVisible();
      await expect(h.page.getByRole("heading", { name: "Panel" })).toBeVisible();
    });

    await h.step("creo un agente desde esta pantalla", async () => {
      const btn = h.page.getByRole("button", { name: "Crear primer agente" });
      await btn.scrollIntoViewIfNeeded();
      await h.humanClick(btn);
    });

    await h.step("interactúo con la tarjeta creada", async () => {
      const card = h.page.getByRole("button", { name: /Agente 1/ });
      await card.scrollIntoViewIfNeeded();
      await h.humanClick(card);
      await expect(h.page.locator(".agent-detail")).toBeVisible();
    });

    await h.step("hago scroll vertical natural sin roturas", async () => {
      await h.humanWheel(400);
      await h.humanWheel(-400);
      await expect(h.page.getByRole("heading", { level: 1 })).toBeVisible();
    });
  });
});
