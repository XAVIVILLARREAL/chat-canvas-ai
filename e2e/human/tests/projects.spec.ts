import { test, expect } from "../human-fixture";

/**
 * A.0 — Proyectos como SCOPE (@core): entrar por switcher, cambiar de proyecto,
 * crear uno nuevo, la selección persiste tras recargar y nada se mezcla.
 * Requiere el gateway Rust en :3030 (vite proxía /api → :3030).
 */

const GATEWAY_UP = process.env.A0_GATEWAY === "1";

test.describe("Proyectos como scope — A.0", () => {
  test("@core cambio de proyecto: crea, alterna, persiste tras recargar", async ({ h, page }, testInfo) => {
    test.skip(!GATEWAY_UP, "A.0 requiere gateway (A0_GATEWAY=1 + gateway en :3030)");
    test.skip(testInfo.project.name.includes("mobile"), "switcher es desktop-only por ahora");
    const { step, humanClick, humanThink } = h;

    await step("abro la app con el switcher visible", async () => {
      await page.goto("/");
      await expect(page.getByRole("heading", { name: "Canvas AI" })).toBeVisible();
      await expect(page.getByTestId("project-switcher")).toBeVisible();
    });

    const projectName = `B-${Date.now().toString(36)}`;

    await step(`creo un proyecto único (${projectName}) desde el switcher`, async () => {
      await humanClick(page.getByTestId("project-switcher").locator("button").first());
      page.once("dialog", (d) => d.accept(projectName));
      await humanClick(page.getByTestId("project-new"));
      await humanThink();
      // al crear, el componente selecciona y cierra el menú: reabrir para verificar
      await humanClick(page.getByTestId("project-switcher").locator("button").first());
      await expect(page.getByRole("button", { name: projectName })).toBeVisible();
    });

    await step("el proyecto nuevo quedó activo (badge ✓)", async () => {
      await expect(page.getByRole("button", { name: projectName })).toHaveClass(/active/);
      await humanClick(page.getByTestId("project-switcher").locator("button").first()); // cerrar menú
    });

    await step("recargo → la selección persiste (settings del gateway)", async () => {
      await page.reload();
      await expect(page.getByRole("heading", { name: "Canvas AI" })).toBeVisible();
      await humanClick(page.getByTestId("project-switcher").locator("button").first());
      await expect(page.getByRole("button", { name: projectName })).toHaveClass(/active/);
      await humanClick(page.getByTestId("project-switcher").locator("button").first());
    });

    await step("vuelvo al proyecto default y nada se mezcla", async () => {
      await humanClick(page.getByTestId("project-switcher").locator("button").first());
      await humanClick(page.getByTestId("project-local-default"));
      await humanThink();
      await page.reload();
      await expect(page.getByRole("heading", { name: "Canvas AI" })).toBeVisible();
      await humanClick(page.getByTestId("project-switcher").locator("button").first());
      await expect(page.getByTestId("project-local-default")).toHaveClass(/active/);
    });
  });
});
