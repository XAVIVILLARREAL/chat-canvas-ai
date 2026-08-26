import { chromium } from '@playwright/test';
const b = await chromium.launch();
const ctx = await b.newContext({ locale: 'es-MX' });
const p = await ctx.newPage();
p.on('pageerror', e => console.log('PAGEERROR:', String(e).slice(0,200)));
await p.goto('http://localhost:1420');
await p.waitForTimeout(500);
console.log('subtitle inicial:', await p.evaluate(() => document.querySelector('.subtitle')?.textContent));
await p.getByRole('button', { name: /^Idioma$/i }).click();
await p.waitForTimeout(300);
const items = p.locator('.header-dropdown .dropdown-menu .dropdown-item', { hasText: 'EN' });
console.log('items EN visibles:', await items.count());
await items.last().click();
await p.waitForTimeout(500);
console.log('subtitle tras EN:', await p.evaluate(() => document.querySelector('.subtitle')?.textContent),
  '| lang:', await p.evaluate(() => document.documentElement.lang));
await b.close();
