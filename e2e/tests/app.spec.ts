import { test, expect } from "../fixtures";

test.describe("Empresa Dev", () => {
  test("loads the app", async ({ page }) => {
    await page.goto("/");
    await expect(page.locator("h1")).toContainText("Empresa Dev");
  });

  test("shows empty state when no agents", async ({ page }) => {
    await page.goto("/");
    await expect(page.getByText("No hay agentes creados")).toBeVisible();
  });

  test("has create agent button", async ({ page }) => {
    await page.goto("/");
    await expect(
      page.getByRole("button", { name: "Crear primer agente" }),
    ).toBeVisible();
  });

  test("shows subtitle", async ({ page }) => {
    await page.goto("/");
    await expect(page.getByText("Sistema multiagente visual")).toBeVisible();
  });
});
