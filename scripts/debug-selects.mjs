import { chromium } from '@playwright/test';
const b = await chromium.launch();
const ctx = await b.newContext({ locale: 'es-MX' });
const p = await ctx.newPage();
await p.goto('http://localhost:1420');
await p.waitForTimeout(600);
// activar tab Config (última)
await p.locator('.sidebar-tab').last().click();
await p.waitForTimeout(400);
const selects = await p.evaluate(() => [...document.querySelectorAll('select')].map((s,i) => ({
  i,
  aria: s.getAttribute('aria-label'),
  value: s.value,
  enSidebarList: !!s.closest('.sidebar-list'),
  enSidebar: !!s.closest('.sidebar'),
  options: [...s.options].map(o=>o.value).slice(0,4),
})));
console.log(JSON.stringify(selects, null, 2));
await b.close();
