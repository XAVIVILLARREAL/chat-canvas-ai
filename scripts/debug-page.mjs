import { chromium } from '@playwright/test';
const b = await chromium.launch();
const p = await b.newPage();
p.on('pageerror', e => console.log('PAGEERROR:', String(e).slice(0,300)));
p.on('response', r => { if (r.status() >= 400) console.log('HTTP', r.status(), r.url()); });
await p.goto('http://localhost:1420', { waitUntil: 'networkidle' });
console.log('ROOT:', await p.evaluate(() => document.getElementById('root')?.innerHTML?.slice(0,150) || 'VACÍO'));
await b.close();
