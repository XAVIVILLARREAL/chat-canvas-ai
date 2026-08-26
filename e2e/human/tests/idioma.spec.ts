import { test, expect } from "../human-fixture";

test.describe("Idioma es/en — operado como humano", () => {
  test("@core cambio de idioma con clicks, persiste tras recargar", async ({ h, page }, testInfo) => {
    const esMovil = testInfo.project.name.includes("mobile");
    const { step, humanClick, humanThink } = h;

    // Abre el panel si está cerrado (en móvil arranca cerrado)
    const abrirPanelSiCerrado = async () => {
      const abierta = await page.locator(".app-sidebar").evaluate((el) => {
        const r = el.getBoundingClientRect();
        return r.left < window.innerWidth && r.width > 50;
      });
      if (!abierta) {
        await humanClick(page.locator(".header-left button").first());
        await page.waitForTimeout(700); // transición del drawer
      }
    };

    // Sonda de idioma visible en cualquier viewport:
    // desktop → subtítulo · móvil → placeholder del buscador (panel abierto)
    const esperarIdioma = async (texto: string) => {
      if (esMovil) {
        await abrirPanelSiCerrado();
        const esperado = texto.includes("IA nativa") ? "Buscar..." : "Search...";
        await expect(page.getByPlaceholder(esperado, { exact: true })).toBeVisible();
      } else {
        await expect(page.getByText(texto)).toBeVisible();
      }
      expect(await page.evaluate(() => document.documentElement.lang)).toBe(
        texto.includes("IA nativa") ? "es" : "en"
      );
    };

    await step("abro la app (arranca en español)", async () => {
      await page.goto("/");
      await expect(page.getByRole("heading", { name: "Canvas AI" })).toBeVisible();
      await esperarIdioma("Automatizaciones con IA nativa");
    });
    await humanThink();

    if (!esMovil) {
      // ── Desktop: el flujo natural es el selector del header ──
      await step("abro el selector de idioma y elijo EN", async () => {
        await humanClick(page.getByRole("button", { name: /^Idioma$/i }));
        await page.getByRole("button", { name: "EN", exact: true }).click();
        await page.mouse.move(10, 300); // alejo el puntero: el menú se cierra
        await humanThink();
      });
      await step("la UI se tradujo al inglés sin recargar", async () => {
        await esperarIdioma("AI-native automations");
      });
      await step("recargo — el idioma persiste", async () => {
        await page.reload();
        await expect(page.getByRole("heading", { name: "Canvas AI" })).toBeVisible();
        await esperarIdioma("AI-native automations");
      });
      await step("vuelvo a ES (el botón ahora se llama Language)", async () => {
        await humanClick(page.getByRole("button", { name: /^Language$/i }));
        await page.getByRole("button", { name: "ES", exact: true }).click();
        await page.mouse.move(10, 300);
        await humanThink();
        await esperarIdioma("Automatizaciones con IA nativa");
      });
    } else {
      // ── Móvil: el flujo natural es Config dentro del drawer ──
      await step("abro Config y elijo EN desde el select", async () => {
        await abrirPanelSiCerrado();
        await page.locator(".sidebar-tab").last().click();
        await page.locator(".sidebar-list select").nth(2).selectOption("en");
      });
      await step("la UI se tradujo al inglés sin recargar", async () => {
        await esperarIdioma("AI-native automations");
      });
      await step("recargo — el idioma persiste", async () => {
        await page.reload();
        await expect(page.getByRole("heading", { name: "Canvas AI" })).toBeVisible();
        await esperarIdioma("AI-native automations");
      });
      await step("vuelvo a ES desde el select", async () => {
        await abrirPanelSiCerrado();
        await page.locator(".sidebar-tab").last().click();
        await page.locator(".sidebar-list select").nth(2).selectOption("es");
        await esperarIdioma("Automatizaciones con IA nativa");
      });
    }
  });
});
