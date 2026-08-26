import { chromium, devices } from '@playwright/test';
const b = await chromium.launch();
const ctx = await b.newContext({ locale: 'es-MX', ...devices['Pixel 7'] });
const p = await ctx.newPage();
await p.goto('http://localhost:1420');
await p.waitForTimeout(600);
const info = await p.evaluate(() => {
  const btn = [...document.querySelectorAll('button')].find(b => b.getAttribute('aria-label') === 'Idioma');
  const r = btn.getBoundingClientRect();
  const cx = r.x + r.width/2, cy = r.y + r.height/2;
  const top = document.elementFromPoint(cx, cy);
  const header = document.querySelector('.app-header');
  const cs = getComputedStyle(header);
  const toolbar = document.querySelector('.canvas-toolbar');
  return {
    btnRect: { x: Math.round(r.x), y: Math.round(r.y), w: Math.round(r.width) },
    topElement: top?.tagName + '.' + (top?.className?.toString().slice(0,40)),
    headerZ: cs.zIndex, headerPos: cs.position,
    toolbarZ: toolbar ? getComputedStyle(toolbar).zIndex : 'n/a',
  };
});
console.log(JSON.stringify(info, null, 2));
await b.close();
