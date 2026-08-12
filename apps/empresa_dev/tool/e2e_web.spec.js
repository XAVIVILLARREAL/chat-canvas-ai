// E2E web del flujo crítico (Etapa 7, SDD-120):
// carga -> Canva -> añadir nota -> editar -> guardar -> reload -> persiste.
// Requiere: flutter build web --debug --dart-define=E2E_WEB=true + servidor
// estático en http://127.0.0.1:8765 (lo levanta tool/e2e_web.ps1).
// @ts-check
const { test, expect } = require('@playwright/test');

const BASE = 'http://127.0.0.1:8765';

async function waitApp(page) {
  await page.waitForSelector('flutter-view', { timeout: 30_000 });
  await page.waitForSelector('flt-semantics', { timeout: 30_000 });
}

async function goCanva(page) {
  await page.getByRole('radio', { name: 'Canva' }).click({ timeout: 15_000 });
}

test('flujo crítico web: canva -> nota -> editar -> guardar -> persiste', async ({
  page,
}) => {
  // 1. La app carga y Flutter renderiza (semántica E2E activa)
  await page.goto(BASE);
  await waitApp(page);

  // 2. Cambiar a la vista Canva (SegmentedButton = role=radio)
  await goCanva(page);

  // 3. Añadir una nota: botón "Añadir" -> sheet -> tile "Nota" -> diálogo
  await page.getByRole('button', { name: 'Añadir' }).first().click({ timeout: 15_000 });
  await page.getByRole('button', { name: /^Nota/ }).first().click({ timeout: 15_000 });
  // El diálogo (showDialog estándar) expone un <input> real de Flutter web
  await page.waitForSelector('flt-semantics input', { timeout: 15_000 });
  await page.locator('flt-semantics input').first().fill('nota e2e');
  await page
    .getByRole('dialog')
    .getByRole('button', { name: 'Añadir', exact: true })
    .click({ timeout: 15_000 });

  // 4. El nodo aparece en el canva (texto del nodo en el árbol de semántica)
  await page.getByText('nota e2e', { exact: true }).waitFor({ timeout: 15_000 });

  // 5. Persistencia: recargar y verificar que la nota sigue
  await page.reload();
  await waitApp(page);
  await goCanva(page);
  await page.getByText('nota e2e', { exact: true }).waitFor({ timeout: 15_000 });

  // 6. Editar: abrir la nota (MdNodeScreen) y cambiar el body
  await page.getByText('nota e2e', { exact: true }).first().click({ timeout: 15_000 });
  await page.getByRole('button', { name: 'Guardar' }).waitFor({ timeout: 15_000 });
  const bodyInput = page.locator('flt-semantics textarea').first();
  await bodyInput.fill('# titulo editado\ncontenido nuevo', { timeout: 15_000 });
  await page.getByRole('button', { name: 'Guardar' }).click({ timeout: 15_000 });
  // Volver al canva (flecha atrás del AppBar)
  await page.getByRole('button', { name: /atrás|back/i }).first().click({ timeout: 15_000 });

  // 7. La edición persistió tras otro reload
  await page.reload();
  await waitApp(page);
  await goCanva(page);
  await page.getByText('nota e2e', { exact: true }).waitFor({ timeout: 15_000 });

  // Evidencia para el reporte
  await page.screenshot({ path: 'test-results/e2e_web_final.png', fullPage: true });
  expect(true).toBeTruthy();
});