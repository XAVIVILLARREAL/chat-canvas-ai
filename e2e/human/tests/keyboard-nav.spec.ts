import { expect } from "../human-fixture";
import { test } from "../human-fixture";

test.describe("Navegación por teclado — sin mouse", () => {
  test("alcanzo el botón crear solo con Tab y lo activo con Enter", async ({ h }) => {
    await h.step("abro la app", () => h.page.goto("/"));

    await h.step("navego con Tab hasta el botón Crear primer agente", async () => {
      let alcanzado = false;
      for (let i = 0; i < 10 && !alcanzado; i += 1) {
        const texto = await h.page
          .locator(":focus")
          .textContent()
          .catch(() => "");
        if (texto?.includes("Crear primer agente")) {
          alcanzado = true;
          break;
        }
        await h.humanPress("Tab");
      }
      expect(alcanzado, "el botón Crear debe ser alcanzable por teclado").toBe(true);
    });

    await h.step("lo activo con Enter y el agente aparece", async () => {
      await h.humanPress("Enter");
      await expect(h.page.getByRole("button", { name: /Agente 1/ })).toBeVisible();
    });

    await h.humanThink();

    await h.step("ahora hay tarjetas de agente navegables por Tab también", async () => {
      let vioTarjeta = false;
      for (let i = 0; i < 6 && !vioTarjeta; i += 1) {
        const texto = await h.page
          .locator(":focus")
          .textContent()
          .catch(() => "");
        if (texto?.includes("Agente 1")) {
          vioTarjeta = true;
          break;
        }
        await h.humanPress("Tab");
      }
      expect(vioTarjeta, "la tarjeta del agente debe ser enfocable").toBe(true);
    });
  });

  test("Escape no rompe nada en estado normal", async ({ h }) => {
    await h.step("abro y presiono Escape varias veces", async () => {
      await h.page.goto("/");
      await h.humanPress("Escape");
      await h.humanPress("Escape");
      await expect(h.page.getByRole("heading", { level: 1 })).toBeVisible();
    });
  });
});
