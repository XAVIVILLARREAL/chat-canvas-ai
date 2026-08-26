import { chromium, devices } from '@playwright/test';
const b = await chromium.launch();
const ctx = await b.newContext({ locale: 'es-MX', ...devices['Pixel 7'] });
const p = await ctx.newPage();
const rect = () => p.evaluate(() => { const e = document.querySelector('.app-sidebar'); const r = e.getBoundingClientRect(); return `x=${Math.round(r.x)} w=${Math.round(r.width)} clase=${e.className}`; });
await p.goto('http://localhost:1420');
await p.waitForTimeout(600);
console.log('inicio:', await rect());
const abierta = await p.locator('.app-sidebar').evaluate((el) => { const r = el.getBoundingClientRect(); return r.left < window.innerWidth && r.width > 50; });
console.log('panelAbierto?', abierta);
if (!abierta) { await p.locator('.header-left button').first().click(); await p.waitForTimeout(700); }
console.log('tras abrir:', await rect());
await p.getByRole('button', { name: 'Agentes' }).first().click();
await p.waitForTimeout(300);
console.log('tab Agentes visible:', await p.getByRole('button', { name: 'Agentes' }).first().isVisible());
await p.getByRole('button', { name: /Crear Agente|Nuevo Agente/ }).first().click();
await p.waitForTimeout(300);
console.log('modal visible:', await p.getByRole('dialog').isVisible().catch(() => false));
await b.close();
