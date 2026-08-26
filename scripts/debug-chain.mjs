import { chromium, devices } from '@playwright/test';
const b = await chromium.launch();
const ctx = await b.newContext({ locale: 'es-MX', ...devices['Pixel 7'] });
const p = await ctx.newPage();
await p.goto('http://localhost:1420');
await p.waitForTimeout(600);
const chain = await p.evaluate(() => {
  const btn = [...document.querySelectorAll('button')].find(b => b.getAttribute('aria-label') === 'Idioma');
  const r = btn.getBoundingClientRect();
  let el = document.elementFromPoint(r.x + r.width/2, r.y + r.height/2);
  const out = [];
  while (el && el !== document.body && out.length < 10) {
    const cs = getComputedStyle(el);
    out.push(`${el.tagName}.${String(el.className).slice(0,30)} z=${cs.zIndex} pos=${cs.position} tf=${cs.transform !== 'none'}`);
    el = el.parentElement;
  }
  return out;
});
console.log(chain.join('\n'));
await b.close();
