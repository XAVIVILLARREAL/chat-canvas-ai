import { chromium, devices } from '@playwright/test';
const b = await chromium.launch();
const ctx = await b.newContext({ locale: 'es-MX', ...devices['Pixel 7'] });
const p = await ctx.newPage();
await p.goto('http://localhost:1420');
await p.waitForTimeout(600);
await p.locator('.header-left button').first().click();
await p.waitForTimeout(700);
const r = await p.evaluate(() => {
  const sb = document.querySelector('.app-sidebar').getBoundingClientRect();
  const tabsEl = document.querySelector('.sidebar-tabs');
  const cs = getComputedStyle(tabsEl);
  const tabsInfo = { pos: cs.position, ml: cs.marginLeft, tr: cs.transform, left: cs.left, w: cs.width, parent: tabsEl.parentElement.className };
  const tabs = tabsEl.getBoundingClientRect();
  const tab = [...document.querySelectorAll('.sidebar-tab')].at(-1).getBoundingClientRect();
  return { innerW: window.innerWidth, innerH: window.innerHeight,
    sidebar: { x: sb.x, y: sb.y, w: sb.width, h: sb.height },
    tabsRow: { x: tabs.x, w: tabs.width }, tabsInfo,
    tabConfig: { x: tab.x, y: tab.y, w: tab.width, h: tab.height } };
});
console.log(JSON.stringify(r, null, 2));
await b.close();
