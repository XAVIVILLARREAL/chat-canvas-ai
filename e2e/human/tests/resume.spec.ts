import { test, expect } from "../human-fixture";

/**
 * A.8 — Resume inteligente (@core, desktop):
 * cerrar a mitad → reabrir → card "dónde se quedó" (turno sin responder) →
 * continuar fluido · /compact comprime el historial viejo con un provider.
 * Requiere gateway (A1_GATEWAY=1).
 */
const GATEWAY_UP = process.env.A1_GATEWAY === "1";

test.describe("Resume inteligente — A.8", () => {
  test("@core desktop: card de resume + /compact", async ({ h, page }, testInfo) => {
    test.skip(testInfo.project.name.includes("mobile"), "desktop-only");
    test.skip(!GATEWAY_UP, "requiere gateway (A1_GATEWAY=1)");
    const { step, humanClick, humanFill, humanThink } = h;

    const sesionTab = () =>
      page.locator(".sidebar-tab", { hasText: /Sesiones|Sessions|セッション|Сессии|Juni|الجلسات/ }).first();
    // títulos únicos por ejecución (el gateway persiste entre runs)
    const nombre = `Sesión A8 ${Date.now()}`;

    await step("abro el chat y creo la sesión de trabajo", async () => {
      await page.goto("/");
      // limpio providers de specs anteriores (sus servidores mock ya murieron;
      // puertos efímeros reciclados pueden responder basura y "contestar")
      await page.evaluate(async () => {
        const list = await (await fetch("/api/providers")).json();
        for (const p of list) await fetch(`/api/providers/${p.id}`, { method: "DELETE" });
      });
      await expect(page.getByRole("heading", { name: "Canvas AI" })).toBeVisible();
      await humanClick(page.getByTestId("view-chat"));
      await humanClick(sesionTab());
      await humanFill(page.getByTestId("session-name-input"), nombre);
      await humanClick(page.getByTestId("session-create"));
      await humanThink();
      await expect(page.getByTestId("chat-panel")).toBeVisible();
    });

    await step("dejo la conversación a mitad: pregunta sin responder", async () => {
      await humanFill(page.getByTestId("chat-input"), "pregunta importante sin responder A8");
      await humanClick(page.getByTestId("chat-send"));
      await expect(
        page.locator('[data-testid="msg-user"]', { hasText: "pregunta importante" }).first(),
      ).toBeVisible({ timeout: 10000 });
    });

    await step("cambio a otra sesión (cierro la interrumpida)", async () => {
      await humanFill(page.getByTestId("session-name-input"), "Otra sesión");
      await humanClick(page.getByTestId("session-create"));
      await humanThink();
      await expect(page.getByTestId("chat-empty")).toBeVisible();
    });

    await step("reabro la sesión interrumpida → card 'dónde te quedaste'", async () => {
      await humanClick(page.locator('[data-testid="sessions-list"] .item', { hasText: nombre }).first());
      const card = page.getByTestId("resume-card");
      await expect(card).toBeVisible({ timeout: 8000 });
      // el turno quedó sin responder y el preview muestra la pregunta
      await expect(page.getByTestId("resume-unanswered")).toBeVisible();
      await expect(card).toContainText("pregunta importante sin responder A8");
    });

    await step("continuo fluido: escribo y el mensaje sale (card descartable)", async () => {
      await humanClick(page.getByTestId("resume-dismiss"));
      await expect(page.getByTestId("resume-card")).toBeHidden();
      await humanFill(page.getByTestId("chat-input"), "sigamos entonces");
      await humanClick(page.getByTestId("chat-send"));
      await expect(
        page.locator('[data-testid="msg-user"]', { hasText: "sigamos entonces" }).first(),
      ).toBeVisible({ timeout: 10000 });
    });

    await step("preparo historial viejo y ejecuto /compact con provider mock", async () => {
      // provider mock no-streaming (resume + compact lo usan)
      const http = await import("node:http");
      const server = http.createServer((reqq, res) => {
        let body = "";
        reqq.on("data", (c) => (body += c));
        reqq.on("end", () => {
          res.writeHead(200, { "content-type": "application/json" });
          res.end(JSON.stringify({
            id: "chatcmpl-sum",
            choices: [{ message: { role: "assistant", content: "RESUMEN: se habló de A8" }, finish_reason: "stop" }],
            usage: { prompt_tokens: 10, completion_tokens: 8 },
          }));
        });
      });
      await new Promise<void>((r) => server.listen(0, "127.0.0.1", r));
      const port = (server.address() as { port: number }).port;
      await page.evaluate(async (url) => {
        await fetch("/api/providers", {
          method: "POST",
          headers: { "content-type": "application/json" },
          body: JSON.stringify({ provider_type: "generic", name: "mock-sum", base_url: url, api_key: "k", validate: false }),
        });
        // 6 mensajes viejos (título: contenido) para que el /compact tenga materia
        const sidRes = await fetch("/api/sessions", { method: "POST", headers: { "content-type": "application/json" }, body: JSON.stringify({ title: "Sesión compactable" }) });
        const sid = (await sidRes.json()).id;
        for (let i = 1; i <= 6; i++) {
          await fetch(`/api/sessions/${sid}/messages`, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: JSON.stringify({ role: i % 2 === 1 ? "user" : "assistant", content: `mensaje numero ${i}: contenido sustancial `.repeat(2) }),
          });
        }
      }, `http://127.0.0.1:${port}/v1`);

      // la lista de sesiones quedó stale (creada por API) — recargo como haría el humano
      await page.reload();
      await expect(page.getByRole("heading", { name: "Canvas AI" })).toBeVisible();
      await humanClick(page.getByTestId("view-chat"));

      // abro la sesión compactable y ejecuto /compact desde el input
      await humanClick(sesionTab());
      await humanClick(page.locator('[data-testid="sessions-list"] .item', { hasText: "Sesión compactable" }).first());
      await humanFill(page.getByTestId("chat-input"), "/compact");
      await humanClick(page.getByTestId("chat-send"));
      await expect(page.getByTestId("chat-notice")).toContainText(/comprimido|compacted/i, { timeout: 10000 });
      // el resumen aparece en la conversación (mensaje system del compact)
      await expect(page.locator('[data-testid="msg-system"]', { hasText: "RESUMEN" }).first()).toBeVisible({ timeout: 8000 });
    });
  });
});
