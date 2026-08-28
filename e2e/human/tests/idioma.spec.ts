import { test, expect } from "../human-fixture";
import enDict from "../../../src/i18n/locales/en.json" with { type: "json" };
import esDict from "../../../src/i18n/locales/es.json" with { type: "json" };
import zhDict from "../../../src/i18n/locales/zh-CN.json" with { type: "json" };
import ptDict from "../../../src/i18n/locales/pt-BR.json" with { type: "json" };
import deDict from "../../../src/i18n/locales/de.json" with { type: "json" };
import frDict from "../../../src/i18n/locales/fr.json" with { type: "json" };
import itDict from "../../../src/i18n/locales/it.json" with { type: "json" };
import jaDict from "../../../src/i18n/locales/ja.json" with { type: "json" };
import koDict from "../../../src/i18n/locales/ko.json" with { type: "json" };
import hiDict from "../../../src/i18n/locales/hi.json" with { type: "json" };
import ruDict from "../../../src/i18n/locales/ru.json" with { type: "json" };
import arDict from "../../../src/i18n/locales/ar.json" with { type: "json" };

// Locator del botón de idioma INDEPENDIENTE del locale activo: el aria-label
// del botón se traduce con la UI, así que matcheamos las 12 traducciones.
const DICTS = [enDict, esDict, zhDict, ptDict, deDict, frDict, itDict, jaDict, koDict, hiDict, ruDict, arDict];
const escapeRe = (s: string) => s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
const LANG_BTN = new RegExp(`^(?:${DICTS.map((d) => escapeRe(d["header.language"])).join("|")})$`, "i");

const LOCALE_PROBES: Record<string, { subtitle: string; lang: string; search: string; dir: string }> = {
  en: { subtitle: "AI-native automations", lang: "en", search: "Search...", dir: "ltr" },
  es: { subtitle: "Automatizaciones con IA nativa", lang: "es", search: "Buscar...", dir: "ltr" },
  "zh-CN": { subtitle: "自动化与AI原生", lang: "zh-CN", search: "搜索...", dir: "ltr" },
  "pt-BR": { subtitle: "Automações com IA nativa", lang: "pt-BR", search: "Pesquisar...", dir: "ltr" },
  de: { subtitle: "KI-native Automatisierungen", lang: "de", search: "Suchen...", dir: "ltr" },
  fr: { subtitle: "Automatisations IA natives", lang: "fr", search: "Rechercher...", dir: "ltr" },
  it: { subtitle: "Automazioni con IA nativa", lang: "it", search: "Cerca...", dir: "ltr" },
  ja: { subtitle: "AIネイティブ自動化", lang: "ja", search: "検索...", dir: "ltr" },
  ko: { subtitle: "AI 네이티브 자동화", lang: "ko", search: "검색...", dir: "ltr" },
  hi: { subtitle: "AI-नेटिव स्वचालन", lang: "hi", search: "खोजें...", dir: "ltr" },
  ru: { subtitle: "Автоматизация на базе ИИ", lang: "ru", search: "Поиск...", dir: "ltr" },
  ar: { subtitle: "أتمتة أصلية بالذكاء الاصطناعي", lang: "ar", search: "بحث...", dir: "rtl" },
};

test.describe("Idiomas — operado como humano (12 idiomas)", () => {
  test("@core cambio de idioma con clicks, persiste tras recargar (12 locales)", async ({ h, page }, testInfo) => {
    const esMovil = testInfo.project.name.includes("mobile");
    const { step, humanClick, humanThink } = h;

    const abrirPanelSiCerrado = async () => {
      const abierta = await page.locator(".app-sidebar").evaluate((el) => {
        const r = el.getBoundingClientRect();
        // visible = dentro del viewport en AMBOS bordes (en RTL cerrado, el drawer
        // se esconde a la izquierda con translateX(-100%) → left negativo pero right=0)
        return r.width > 50 && r.left < window.innerWidth && r.right > 0;
      });
      if (!abierta) {
        await humanClick(page.locator(".header-left button").first());
        await page.waitForTimeout(700);
      }
    };

    const esperarIdioma = async (probe: { subtitle: string; lang: string; search: string; dir: string }) => {
      if (esMovil) {
        await abrirPanelSiCerrado();
        await expect(page.getByPlaceholder(probe.search, { exact: true })).toBeVisible();
      } else {
        await expect(page.getByText(probe.subtitle)).toBeVisible();
      }
      expect(await page.evaluate(() => document.documentElement.lang)).toBe(probe.lang);
      expect(await page.evaluate(() => document.documentElement.dir)).toBe(probe.dir);
    };

    await step("abro la app (arranca en español por defecto)", async () => {
      await page.goto("/");
      await expect(page.getByRole("heading", { name: "Canvas AI" })).toBeVisible();
      await esperarIdioma(LOCALE_PROBES.es);
    });
    await humanThink();

    // Test each non-default locale
    const localesToTest = (["en", "zh-CN", "pt-BR", "de", "fr", "it", "ja", "ko", "hi", "ru", "ar"] as const);

    for (const locale of localesToTest) {
      const probe = LOCALE_PROBES[locale];
      const label = locale.toUpperCase();

      if (!esMovil) {
        await step(`cambio a ${locale} desde el selector del header`, async () => {
          await humanClick(page.getByRole("button", { name: LANG_BTN }));
          await page.getByRole("button", { name: label, exact: true }).click();
          await page.mouse.move(10, 300);
          await humanThink();
        });
        await step(`${locale} — la UI se tradujo sin recargar`, async () => {
          await esperarIdioma(probe);
        });
        await step(`${locale} — recargo, el idioma persiste`, async () => {
          await page.reload();
          await expect(page.getByRole("heading", { name: "Canvas AI" })).toBeVisible();
          await esperarIdioma(probe);
        });
      } else {
        await step(`cambio a ${locale} desde Config en el drawer`, async () => {
          await abrirPanelSiCerrado();
          await page.locator(".sidebar-tab").last().click();
          await page.locator(".sidebar-list select").nth(2).selectOption(locale);
        });
        await step(`${locale} — la UI se tradujo sin recargar`, async () => {
          await esperarIdioma(probe);
        });
        await step(`${locale} — recargo, el idioma persiste`, async () => {
          await page.reload();
          await expect(page.getByRole("heading", { name: "Canvas AI" })).toBeVisible();
          await esperarIdioma(probe);
        });
      }
      await humanThink();
    }

    // Volver a es al final
    await step("vuelvo a ES al final", async () => {
      if (!esMovil) {
        await humanClick(page.getByRole("button", { name: LANG_BTN }));
        await page.getByRole("button", { name: "ES", exact: true }).click();
        await page.mouse.move(10, 300);
      } else {
        await abrirPanelSiCerrado();
        await page.locator(".sidebar-tab").last().click();
        await page.locator(".sidebar-list select").nth(2).selectOption("es");
      }
      await humanThink();
      await esperarIdioma(LOCALE_PROBES.es);
    });
  });

  test("@rtl layout en RTL (ar): sidebar al inicio y panels del canvas espejados", async ({ h, page }, testInfo) => {
    test.skip(testInfo.project.name.includes("mobile"), "RTL layout check es desktop-only");
    const { step, humanClick, humanThink } = h;

    await step("cambio a AR (RTL)", async () => {
      await page.goto("/");
      await humanClick(page.getByRole("button", { name: LANG_BTN }));
      await page.getByRole("button", { name: "AR", exact: true }).click();
      await page.mouse.move(10, 300);
      await humanThink();
      expect(await page.evaluate(() => document.documentElement.dir)).toBe("rtl");
      await expect(page.getByText(LOCALE_PROBES.ar.subtitle)).toBeVisible();
    });

    await step("el sidebar queda al inline-start (izquierda en RTL)", async () => {
      const layout = await page.evaluate(() => {
        const sidebar = document.querySelector(".app-sidebar");
        const canvas = document.querySelector(".canvas-section");
        if (!sidebar || !canvas) return null;
        const s = sidebar.getBoundingClientRect();
        const c = canvas.getBoundingClientRect();
        return { sidebarLeft: s.left, canvasLeft: c.left };
      });
      expect(layout).not.toBeNull();
      expect(layout!.sidebarLeft).toBeLessThan(layout!.canvasLeft);
    });

    await step("al volver a LTR el sidebar está al inline-end", async () => {
      await humanClick(page.getByRole("button", { name: LANG_BTN }));
      await page.getByRole("button", { name: "EN", exact: true }).click();
      await page.mouse.move(10, 300);
      await humanThink();
      expect(await page.evaluate(() => document.documentElement.dir)).toBe("ltr");
      const layout = await page.evaluate(() => {
        const sidebar = document.querySelector(".app-sidebar");
        const canvas = document.querySelector(".canvas-section");
        if (!sidebar || !canvas) return null;
        const s = sidebar.getBoundingClientRect();
        const c = canvas.getBoundingClientRect();
        return { sidebarLeft: s.left, canvasLeft: c.left };
      });
      expect(layout).not.toBeNull();
      expect(layout!.sidebarLeft).toBeGreaterThan(layout!.canvasLeft);
    });
  });
});
