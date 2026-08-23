import { expect } from "../human-fixture";
import { test } from "../human-fixture";

test.describe("Boot — primera impresión como humano", () => {
  test("abro la app y entiendo qué es", async ({ h }) => {
    await h.step("abro la aplicación", () => h.page.goto("/"));

    await h.step("veo el título principal", async () => {
      const titulo = h.page.getByRole("heading", { level: 1 });
      await expect(titulo).toHaveText("Empresa Dev");
    });

    await h.humanThink();

    await h.step("leo el subtítulo que explica el producto", async () => {
      await expect(h.page.getByText("Sistema multiagente visual")).toBeVisible();
    });

    await h.step("scrolleo para ver toda la página", () => h.humanWheel(300));
    await h.step("vuelvo arriba con la rueda", () => h.humanWheel(-300));

    await h.step("la oficina está presente sin errores de consola", async () => {
      await expect(h.page.getByRole("heading", { name: "Oficina" })).toBeVisible();
      await expect(h.page.getByRole("heading", { name: "Panel" })).toBeVisible();
    });
  });
});
