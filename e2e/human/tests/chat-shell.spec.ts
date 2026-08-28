import { test, expect } from "../human-fixture";

/**
 * A.1 — AppShell + stores (@core):
 * desktop 1440: sidebar con tab Sesiones + panel chat + memory rail.
 * móvil 375: BottomNav visible y alterna Canvas/Chat.
 * Requiere gateway (A1_GATEWAY=1) para crear sesión y enviar mensaje.
 */
const GATEWAY_UP = process.env.A1_GATEWAY === "1";

test.describe("AppShell chat — A.1", () => {
  test("@core desktop: sesiones tab + chat + memory rail", async ({ h, page }, testInfo) => {
    test.skip(testInfo.project.name.includes("mobile"), "desktop-only");
    test.skip(!GATEWAY_UP, "requiere gateway (A1_GATEWAY=1)");
    const { step, humanClick, humanThink, humanFill } = h;

    await step("abro la app (vista Canvas por defecto)", async () => {
      await page.goto("/");
      await expect(page.getByRole("heading", { name: "Canvas AI" })).toBeVisible();
      await expect(page.getByTestId("canvas-view")).toBeVisible();
    });

    await step("alterno a la vista Chat", async () => {
      await humanClick(page.getByTestId("view-chat"));
      await expect(page.getByTestId("chat-view")).toBeVisible();
      await expect(page.getByTestId("memory-rail")).toBeVisible();
    });

    await step("creo una sesión desde el sidebar (tab Sesiones)", async () => {
      const sesionTab = page.locator(".sidebar-tab", { hasText: /Sesiones|Sessions|セッション|Сессии|Juni|الجلسات/ }).first();
      await humanClick(sesionTab);
      await humanFill(page.getByTestId("session-name-input"), "Sesión A1");
      await humanClick(page.getByTestId("session-create"));
      await humanThink();
      await expect(page.getByTestId("chat-panel")).toBeVisible();
    });

    await step("envío un mensaje y aparece en la conversación", async () => {
      await humanFill(page.getByTestId("chat-input"), "hola desde A1");
      await humanClick(page.getByTestId("chat-send"));
      await expect(page.getByTestId("msg-user").last()).toContainText("hola desde A1");
    });

    await step("recargo → la conversación restauró (persistencia)", async () => {
      await page.reload();
      await expect(page.getByRole("heading", { name: "Canvas AI" })).toBeVisible();
      await humanClick(page.getByTestId("view-chat"));
      const sesionTab = page.locator(".sidebar-tab", { hasText: /Sesiones|Sessions|セッション|Сессии|Juni|الجلسات/ }).first();
      await humanClick(sesionTab);
      await humanClick(page.locator("[data-testid^='session-']").last());
      await expect(page.getByTestId("msg-user").last()).toContainText("hola desde A1");
    });

    await step("vuelvo a Canvas sin rastros del chat", async () => {
      await humanClick(page.getByTestId("view-canvas"));
      await expect(page.getByTestId("canvas-view")).toBeVisible();
    });
  });

  test("@core móvil 375: BottomNav visible y alterna vistas", async ({ h, page }, testInfo) => {
    test.skip(!testInfo.project.name.includes("mobile"), "mobile-only");
    const { step, humanClick } = h;

    await step("abro en móvil: BottomNav presente", async () => {
      await page.goto("/");
      await expect(page.getByTestId("bottom-nav")).toBeVisible();
    });

    await step("BottomNav alterna a Chat", async () => {
      await humanClick(page.getByTestId("bottom-chat"));
      await expect(page.getByTestId("chat-view")).toBeVisible();
    });

    await step("BottomNav vuelve a Canvas", async () => {
      await humanClick(page.getByTestId("bottom-canvas"));
      await expect(page.getByTestId("canvas-view")).toBeVisible();
    });
  });
});
