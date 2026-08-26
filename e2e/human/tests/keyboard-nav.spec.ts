import { expect } from "../human-fixture";
import { test } from "../human-fixture";

test.describe("Navegación por teclado — sin mouse", () => {
  test("alcanzo el botón crear solo con Tab y lo activo con Enter", async ({ h }) => {
    const { page, step, humanClick, humanPress } = h;

    // En móvil el sidebar es drawer: abrirlo primero
    const abrirPanelSiCerrado = async () => {
      const abierta = await page.locator(".app-sidebar").evaluate((el) => {
        const r = el.getBoundingClientRect();
        return r.left < window.innerWidth && r.width > 50;
      });
      if (!abierta) {
        await h.humanClick(h.page.locator(".header-left button").first());
        await page.waitForTimeout(700);
      }
    };

    await step("abro la app y voy a Agentes", async () => {
      await page.goto("/");
      await abrirPanelSiCerrado();
      await humanClick(page.getByRole("button", { name: "Agentes" }).first());
    });

    await step("navego con Tab hasta el botón Crear Agente", async () => {
      let alcanzado = false;
      for (let i = 0; i < 15 && !alcanzado; i += 1) {
        const texto = await page
          .locator(":focus")
          .textContent()
          .catch(() => "");
        if (texto?.includes("Crear Agente")) {
          alcanzado = true;
          break;
        }
        await humanPress("Tab");
      }
      expect(alcanzado, "el botón Crear debe ser alcanzable por teclado").toBe(true);
    });

    await step("lo activo con Enter y el modal se abre", async () => {
      await humanPress("Enter");
      await expect(page.getByRole("dialog")).toBeVisible();
    });

    await step("el input está enfocado: escribo el nombre directo", async () => {
      await expect(page.getByRole("textbox", { name: "Nombre" })).toBeFocused();
      await page.keyboard.type("Agente Teclado");
    });

    await step("Enter guarda y el agente aparece en la lista", async () => {
      await humanPress("Enter");
      await expect(page.getByText("Agente Teclado")).toBeVisible();
    });

    await step("el item del agente es enfocable también", async () => {
      let vioItem = false;
      for (let i = 0; i < 60 && !vioItem; i += 1) {
        const texto = await page
          .locator(":focus")
          .textContent()
          .catch(() => "");
        if (texto?.includes("Agente Teclado")) {
          vioItem = true;
          break;
        }
        await humanPress("Tab");
      }
      expect(vioItem, "el item del agente debe ser enfocable").toBe(true);
    });
  });

  test("Escape no rompe nada en estado normal", async ({ h }) => {
    const { page, step, humanPress } = h;
    await step("abro y presiono Escape varias veces", async () => {
      await page.goto("/");
      await humanPress("Escape");
      await humanPress("Escape");
      await expect(page.getByRole("heading", { level: 1 })).toBeVisible();
    });
  });
});
