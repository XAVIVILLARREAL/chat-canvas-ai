import { chromium } from '@playwright/test';
const b = await chromium.launch();
const ctx = await b.newContext({ locale: 'es-MX' });
const p = await ctx.newPage();
await p.goto('http://localhost:1420');
await p.waitForTimeout(400);
// Inspección directa: ¿qué hay en el span y qué módulos i18n existen?
const info = await p.evaluate(() => {
  const span = document.querySelector('.subtitle');
  const h1 = document.querySelector('.app-header h1');
  return {
    spanText: span?.textContent,
    spanHTML: span?.outerHTML?.slice(0, 120),
    h1Text: h1?.textContent,
    h1HTML: h1?.outerHTML?.slice(0, 160),
  };
});
console.log(JSON.stringify(info, null, 2));
await b.close();
