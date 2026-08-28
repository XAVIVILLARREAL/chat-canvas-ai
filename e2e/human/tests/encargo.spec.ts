import { test, expect } from "../human-fixture";

/**
 * A.7 — Modo ENCARGO (@core, desktop):
 * crear encargo SIN escribir prompt (título + criterios con clicks) →
 * agente mock lo completa → notificación con evidencia visible.
 * Requiere gateway (A1_GATEWAY=1).
 */
const GATEWAY_UP = process.env.A1_GATEWAY === "1";

test.describe("Modo ENCARGO — A.7", () => {
  test("@core desktop: delegar sin prompt, agente mock completa, evidencia", async ({ h, page }, testInfo) => {
    test.skip(testInfo.project.name.includes("mobile"), "desktop-only");
    test.skip(!GATEWAY_UP, "requiere gateway (A1_GATEWAY=1)");
    const { step, humanClick, humanFill, humanThink } = h;

    await step("abro la app y voy al chat", async () => {
      await page.goto("/");
      await expect(page.getByRole("heading", { name: "Canvas AI" })).toBeVisible();
      await humanClick(page.getByTestId("view-chat"));
      await expect(page.getByTestId("memory-rail")).toBeVisible();
    });

    await step("registro un agente mock que completa encargos", async () => {
      const http = await import("node:http");
      const server = http.createServer((reqq, res) => {
        let body = "";
        reqq.on("data", (c) => (body += c));
        reqq.on("end", () => {
          res.writeHead(200, { "content-type": "application/json" });
          res.end(JSON.stringify({
            id: "chatcmpl-enc",
            choices: [{ message: { role: "assistant", content: "criterios cumplidos 1) 2) 3)" }, finish_reason: "stop" }],
            usage: { prompt_tokens: 12, completion_tokens: 30 },
          }));
        });
      });
      await new Promise<void>((r) => server.listen(0, "127.0.0.1", r));
      const port = (server.address() as { port: number }).port;
      await page.evaluate(async (url) => {
        await fetch("/api/providers", {
          method: "POST",
          headers: { "content-type": "application/json" },
          body: JSON.stringify({ provider_type: "generic", name: "mock-enc", base_url: url, api_key: "k", validate: false }),
        });
      }, `http://127.0.0.1:${port}/v1`);
    });

    await step("creo un encargo SIN escribir prompt: título + criterios con clicks", async () => {
      await humanClick(page.getByTestId("encargo-toggle-form"));
      await humanFill(page.getByTestId("encargo-title"), "Preparar informe A7");
      await humanFill(page.getByTestId("encargo-criteria"), "Resumen ejecutivo\nConclusión clara");
      await humanClick(page.getByTestId("encargo-create"));
      // el encargo aparece en el panel (pendiente/en curso o ya completado)
      await expect(page.locator('[data-testid^="encargo-item-"]').first()).toBeVisible({ timeout: 5000 });
    });

    await step("el agente mock lo completa → estado completed en el panel", async () => {
      await expect(page.getByTestId("encargo-item-completed").first()).toBeVisible({ timeout: 15000 });
    });

    await step("la notificación de vuelta llega (toast con evidencia)", async () => {
      // el toast de completado dura 6s y el polling lo detecta en ≤2s — ventana amplia
      await expect(page.locator(".toast-container")).toContainText(
        /completado|completed/i,
        { timeout: 10000 },
      );
    });

    await step("abro el encargo → la evidencia es visible", async () => {
      await humanClick(page.getByTestId("encargo-item-completed").first());
      const evidence = page.getByTestId("encargo-evidence");
      await expect(evidence).toBeVisible();
      await expect(evidence).toContainText("criterios cumplidos");
    });

    await step("la evidencia también quedó en su sesión (mensajes)", async () => {
      // el encargo corre en su propia sesión "Encargo: …" — el humano la abre
      const sesionTab = page
        .locator(".sidebar-tab", { hasText: /Sesiones|Sessions|セッション|Сессии|Juni|الجلسات/ })
        .first();
      await humanClick(sesionTab);
      await humanClick(
        page.locator('[data-testid="sessions-list"] .item', { hasText: /Encargo: Preparar informe A7/ }).first(),
      );
      await expect(page.locator('[data-testid="msg-assistant"]').first()).toBeVisible({ timeout: 8000 });
      await expect(page.locator('[data-testid="msg-assistant"]').first()).toContainText("criterios cumplidos");
    });
  });
});
