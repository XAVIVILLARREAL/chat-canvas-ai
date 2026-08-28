import { test, expect } from "../human-fixture";

/**
 * A.9 — Ramas visuales al editar (@core, desktop):
 * edito un mensaje 2× → se crean variantes; flechas ‹/› navegan las
 * alternativas sin perder ninguna. No requiere provider (editar es puro repo).
 */
test.describe("Ramas visuales — A.9", () => {
  test("@core desktop: edito 2× y navego las variantes con ‹/›", async ({ h, page }, testInfo) => {
    test.skip(testInfo.project.name.includes("mobile"), "desktop-only");
    test.skip(process.env.A1_GATEWAY !== "1", "requiere gateway (A1_GATEWAY=1)");
    const { step, humanClick, humanFill, humanThink } = h;
    const nombre = `Ramas ${Date.now()}`;

    await step("abro el chat y creo la sesión", async () => {
      await page.goto("/");
      await expect(page.getByRole("heading", { name: "Canvas AI" })).toBeVisible();
      await humanClick(page.getByTestId("view-chat"));
      const sesionTab = page
        .locator(".sidebar-tab", { hasText: /Sesiones|Sessions|セッション|Сессии|Juni|الجلسات/ })
        .first();
      await humanClick(sesionTab);
      await humanFill(page.getByTestId("session-name-input"), nombre);
      await humanClick(page.getByTestId("session-create"));
      await humanThink();
      await expect(page.getByTestId("chat-panel")).toBeVisible();
    });

    await step("envío el mensaje original", async () => {
      await humanFill(page.getByTestId("chat-input"), "pregunta original");
      await humanClick(page.getByTestId("chat-send"));
      await expect(
        page.locator('[data-testid="msg-user"]', { hasText: "pregunta original" }).first(),
      ).toBeVisible({ timeout: 10000 });
    });

    await step("edito el mensaje (1ª vez) → aparece la variante con indicador 2/2", async () => {
      await humanClick(page.locator('[data-testid^="msg-edit-"]').first());
      await page.getByTestId("msg-edit-input").fill("pregunta editada uno");
      await humanClick(page.getByTestId("msg-edit-save"));
      await humanThink();
      await expect(
        page.locator('[data-testid="msg-user"]', { hasText: "pregunta editada uno" }).first(),
      ).toBeVisible({ timeout: 10000 });
      // solo hay UNA burbuja visible (la variante activa) con su indicador 2/2
      await expect(page.locator('[data-testid="msg-user"]')).toHaveCount(1);
      await expect(page.locator('[data-testid^="msg-variant-pos-"]')).toHaveText("2/2");
    });

    await step("edito de nuevo (2ª vez) → 3/3", async () => {
      await humanClick(page.locator('[data-testid^="msg-edit-"]').first());
      await page.getByTestId("msg-edit-input").fill("pregunta editada dos");
      await humanClick(page.getByTestId("msg-edit-save"));
      await humanThink();
      await expect(page.locator('[data-testid^="msg-variant-pos-"]')).toHaveText("3/3");
    });

    await step("flecha ‹ → navego a la variante anterior (nada se pierde)", async () => {
      await humanClick(page.locator('[data-testid^="msg-prev-"]').first());
      await humanThink();
      await expect(
        page.locator('[data-testid="msg-user"]', { hasText: "pregunta editada uno" }).first(),
      ).toBeVisible({ timeout: 10000 });
      await expect(page.locator('[data-testid^="msg-variant-pos-"]')).toHaveText("2/3");
    });

    await step("‹ otra vez → el original; › vuelve hacia adelante", async () => {
      await humanClick(page.locator('[data-testid^="msg-prev-"]').first());
      await humanThink();
      await expect(
        page.locator('[data-testid="msg-user"]', { hasText: "pregunta original" }).first(),
      ).toBeVisible({ timeout: 10000 });
      await expect(page.locator('[data-testid^="msg-variant-pos-"]')).toHaveText("1/3");

      await humanClick(page.locator('[data-testid^="msg-next-"]').first());
      await humanThink();
      await expect(
        page.locator('[data-testid="msg-user"]', { hasText: "pregunta editada uno" }).first(),
      ).toBeVisible({ timeout: 10000 });
      await expect(page.locator('[data-testid^="msg-variant-pos-"]')).toHaveText("2/3");
    });
  });
});
