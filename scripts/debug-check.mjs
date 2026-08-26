import { chromium } from '@playwright/test';
const b = await chromium.launch();
const ctx = await b.newContext({ locale: 'es-MX' });
const p = await ctx.newPage();
await p.goto('http://localhost:1420');
await p.waitForTimeout(500);
await p.getByRole('button', { name: /^Idioma$/i }).click();
await p.locator('.header-dropdown .dropdown-menu .dropdown-item', { hasText: 'EN' }).last().click();
await p.waitForTimeout(400);
console.log('subtitle EN (en vivo):', await p.evaluate(() => document.querySelector('.subtitle')?.textContent));
// volver a ES vía Config (select sobrevive al cambio de idioma)
await page_config_es(p);
async function page_config_es(p) {
  await p.getByRole('button', { name: /Config/i }).first().click();
  await p.locator('.sidebar select').nth(1).selectOption('es');
  await p.waitForTimeout(300);
  console.log('subtitle ES (vía Config):', await p.evaluate(() => document.querySelector('.subtitle')?.textContent));
}
await b.close();
