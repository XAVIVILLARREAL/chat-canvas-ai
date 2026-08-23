import { test as base, expect, type Locator, type Page } from "@playwright/test";
import { mkdirSync } from "node:fs";
import path from "node:path";

const EVIDENCE_ROOT = path.join(process.cwd(), "evidence", "human");

type HumanStep = (nombre: string, accion: () => Promise<void>) => Promise<void>;

type HumanFixtures = {
  h: {
    page: Page;
    step: HumanStep;
    humanThink: (minMs?: number, maxMs?: number) => Promise<void>;
    humanClick: (loc: Locator) => Promise<void>;
    humanFill: (loc: Locator, texto: string) => Promise<void>;
    humanPress: (key: string) => Promise<void>;
    humanWheel: (deltaY: number) => Promise<void>;
  };
};

const rand = (min: number, max: number) =>
  Math.floor(min + Math.random() * (max - min));

export const test = base.extend<HumanFixtures>({
  h: [
    async ({ page }, use, testInfo) => {
      const dir = path.join(
        EVIDENCE_ROOT,
        testInfo.titlePath.join("/").replace(/[^\w/-]+/g, "_"),
      );
      mkdirSync(dir, { recursive: true });
      let paso = 0;

      const step: HumanStep = async (nombre, accion) => {
        paso += 1;
        const etiqueta = `${String(paso).padStart(2, "0")}-${nombre.replace(/[^\w-]+/g, "_")}`;
        await accion();
        await page.screenshot({
          path: path.join(dir, `${etiqueta}.png`),
          fullPage: false,
        });
        console.log(`  👤 paso ${paso}: ${nombre}`);
      };

      const humanThink = async (min = 300, max = 900) => {
        await page.waitForTimeout(rand(min, max));
      };

      const humanClick = async (loc: Locator) => {
        await loc.hover();
        await page.waitForTimeout(rand(200, 500));
        await loc.click();
        await page.waitForTimeout(rand(150, 400));
      };

      const humanFill = async (loc: Locator, texto: string) => {
        await loc.click();
        for (const ch of texto) {
          await loc.pressSequentially(ch, { delay: rand(40, 120) });
        }
        await page.waitForTimeout(rand(120, 300));
      };

      const humanPress = async (key: string) => {
        await page.keyboard.press(key);
        await page.waitForTimeout(rand(100, 250));
      };

      const humanWheel = async (deltaY: number) => {
        await page.mouse.wheel(0, deltaY);
        await page.waitForTimeout(rand(200, 450));
      };

      await use({ page, step, humanThink, humanClick, humanFill, humanPress, humanWheel });
    },
    { auto: true },
  ],
});

export { expect };
