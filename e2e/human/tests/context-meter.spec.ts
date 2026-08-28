import { test, expect } from "../human-fixture";

/**
 * A.5 — Medidor y debug de contexto (@core, desktop):
 * abrir el medidor en una sesión real → desglose por fuentes en vivo →
 * ajustar el límite → el siguiente estado lo refleja (y persiste en settings).
 * Requiere gateway (A1_GATEWAY=1).
 */
const GATEWAY_UP = process.env.A1_GATEWAY === "1";
const LIMITE = 2048; // distinto del default (8192) para que el ajuste sea real

test.describe("Medidor de contexto — A.5", () => {
  test("@core desktop: desglose en vivo + ajustar límite", async ({ h, page }, testInfo) => {
    test.skip(testInfo.project.name.includes("mobile"), "desktop-only");
    test.skip(!GATEWAY_UP, "requiere gateway (A1_GATEWAY=1)");
    const { step, humanClick, humanFill, humanThink } = h;

    await step("abro la app y voy al chat", async () => {
      await page.goto("/");
      await expect(page.getByRole("heading", { name: "Canvas AI" })).toBeVisible();
      await humanClick(page.getByTestId("view-chat"));
      await expect(page.getByTestId("memory-rail")).toBeVisible();
    });

    await step("creo una sesión nueva", async () => {
      const sesionTab = page
        .locator(".sidebar-tab", { hasText: /Sesiones|Sessions|セッション|Сессии|Juni|الجلسات/ })
        .first();
      await humanClick(sesionTab);
      await humanFill(page.getByTestId("session-name-input"), "Sesión A5");
      await humanClick(page.getByTestId("session-create"));
      await humanThink();
      await expect(page.getByTestId("chat-panel")).toBeVisible();
    });

    await step("A.5 — el medidor aparece con desglose vacío (sesión sin mensajes)", async () => {
      const meter = page.getByTestId("context-meter");
      await expect(meter).toBeVisible();
      // fila de historial presente (0 tokens en sesión nueva — la barra interna mide 0%)
      await expect(page.getByTestId("ctx-row-historial")).toBeVisible();
    });

    await step("envío un mensaje → el historial sube en el medidor", async () => {
      await humanFill(page.getByTestId("chat-input"), "hola desde A5, mensaje para el medidor");
      await humanClick(page.getByTestId("chat-send"));
      await expect(
        page.locator('[data-testid="msg-user"]', { hasText: "hola desde A5" }).first(),
      ).toBeVisible({ timeout: 10000 });
      // el medidor se refresca (invalidación tras el done del stream o el envío)
      await expect(page.getByTestId("context-total")).toBeVisible();
      await humanThink();
    });

    await step("ajusto el límite → el medidor lo refleja", async () => {
      const input = page.getByTestId("context-limit-input");
      await humanFill(input, String(LIMITE));
      await humanClick(page.getByTestId("context-limit-apply"));
      await humanThink();
      // el límite efectivo (leído del gateway tras invalidar) muestra el ajuste
      await expect(page.getByTestId("context-total")).toContainText(/2[,.\s\u00a0]?048/);
    });

    await step("recargo → re-abro la sesión → el límite ajustado persiste (setting del proyecto)", async () => {
      await page.reload();
      await expect(page.getByRole("heading", { name: "Canvas AI" })).toBeVisible();
      await humanClick(page.getByTestId("view-chat"));
      // tras recargar la selección de sesión se pierde (estado de UI) — el
      // humano la vuelve a abrir; el LÍMITE persiste porque vive en settings
      const sesionTab = page
        .locator(".sidebar-tab", { hasText: /Sesiones|Sessions|セッション|Сессии|Juni|الجلسات/ })
        .first();
      await humanClick(sesionTab);
      await humanClick(page.locator('[data-testid="sessions-list"] .item', { hasText: "Sesión A5" }).first());
      const meter = page.getByTestId("context-meter");
      await expect(meter).toBeVisible();
      await expect(page.getByTestId("context-total")).toContainText(/2[,.\s\u00a0]?048/);
    });
  });
});
