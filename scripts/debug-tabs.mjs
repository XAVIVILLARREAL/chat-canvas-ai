import { chromium } from '@playwright/test';
const b = await chromium.launch();
const ctx = await b.newContext({ locale: 'es-MX' }); const p = await ctx.newPage();
await p.goto('http://localhost:1420');
await p.waitForTimeout(600);
await p.getByRole('button', { name: 'Agentes' }).first().click();
await p.getByRole('button', { name: /Crear Agente|Nuevo Agente/ }).first().click();
await p.waitForTimeout(300);
await p.keyboard.type('Agente Tab');
await p.keyboard.press('Enter');
await p.waitForTimeout(400);
let donde = [];
for (let i = 0; i < 30; i++) {
  const foco = await p.evaluate(() => {
    const el = document.activeElement;
    return `${el?.tagName}.${el?.className?.toString().slice(0,30)} :: ${(el?.textContent||'').slice(0,30)}`;
  });
  donde.push(`${i}: ${foco}`);
  if (foco.includes('Agente Tab')) break;
  await p.keyboard.press('Tab');
}
console.log(donde.join('\n'));
await b.close();
