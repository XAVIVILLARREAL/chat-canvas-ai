import { test, expect } from "../human-fixture";

/**
 * A.6 — Centro de Configuración (@core, desktop):
 * no-programador cambia un ajuste con clicks (scope Proyecto, badge de origen
 * visible) · programador edita JSON validado · el override del proyecto
 * persiste tras recargar.
 * Requiere gateway (A1_GATEWAY=1).
 */
const GATEWAY_UP = process.env.A1_GATEWAY === "1";

test.describe("Centro de Configuración — A.6", () => {
  test("@core desktop: clicks + JSON + override de proyecto", async ({ h, page }, testInfo) => {
    test.skip(testInfo.project.name.includes("mobile"), "desktop-only");
    test.skip(!GATEWAY_UP, "requiere gateway (A1_GATEWAY=1)");
    const { step, humanClick, humanFill, humanThink } = h;

    await step("abro la app y voy al tab de Configuración del sidebar", async () => {
      await page.goto("/");
      await expect(page.getByRole("heading", { name: "Canvas AI" })).toBeVisible();
      const cfgTab = page
        .locator(".sidebar-tab", { hasText: /Config\b|Configuración|Settings|設定|Настройки|الإعدادات/ })
        .first();
      await humanClick(cfgTab);
      await expect(page.getByTestId("config-center")).toBeVisible();
      await expect(page.getByTestId("cfg-knob-context_max_tokens")).toBeVisible();
    });

    await step("no-programador: elijo scope Proyecto y cambio el límite con clicks", async () => {
      await humanClick(page.getByTestId("cfg-scope-project"));
      await humanFill(page.getByTestId("cfg-input-context_max_tokens"), "4096");
      await humanClick(page.getByTestId("cfg-save-context_max_tokens"));
      await humanThink();
      // el valor efectivo de esa perilla ahora viene del PROYECTO (badge visible)
      await expect(
        page
          .getByTestId("cfg-knob-context_max_tokens")
          .getByTestId("cfg-origin-project"),
      ).toBeVisible();
    });

    await step("programador: modo JSON con overrides del proyecto + edición validada", async () => {
      await humanClick(page.getByTestId("cfg-mode-json"));
      const json = page.getByTestId("cfg-json");
      await expect(json).toBeVisible();
      // el JSON de overrides del proyecto contiene el ajuste recién hecho con clicks
      await expect(json).toContainText("context_max_tokens");
      // edito el JSON (programador) para añadir temperature
      await json.fill(JSON.stringify({ temperature: 0.33, context_max_tokens: 4096 }, null, 2));
      await humanClick(page.getByTestId("cfg-json-apply"));
      await humanThink();
    });

    await step("vuelvo a modo simple → temperature quedó en el proyecto (badge)", async () => {
      await humanClick(page.getByTestId("cfg-mode-simple"));
      await expect(
        page.getByTestId("cfg-knob-temperature").getByTestId("cfg-origin-project"),
      ).toBeVisible();
    });

    await step("JSON inválido → error visible, sin aplicar", async () => {
      await humanClick(page.getByTestId("cfg-mode-json"));
      await page.getByTestId("cfg-json").fill("{ temperature: no-json }");
      await humanClick(page.getByTestId("cfg-json-apply"));
      await expect(page.getByTestId("cfg-json-error")).toBeVisible();
    });

    await step("recargo → el override del proyecto persiste (settings del gateway)", async () => {
      await page.reload();
      await expect(page.getByRole("heading", { name: "Canvas AI" })).toBeVisible();
      const cfgTab = page
        .locator(".sidebar-tab", { hasText: /Config\b|Configuración|Settings|設定|Настройки|الإعدادات/ })
        .first();
      await humanClick(cfgTab);
      const knob = page.getByTestId("cfg-knob-context_max_tokens");
      await expect(knob).toBeVisible();
      await expect(knob.getByTestId("cfg-origin-project")).toBeVisible();
      const input = page.getByTestId("cfg-input-context_max_tokens");
      await expect(input).toHaveValue(/4096/);
    });
  });
});
