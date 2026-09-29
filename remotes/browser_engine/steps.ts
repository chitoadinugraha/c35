import type { BrowserEngine } from './browser.js';

export type BrowserStep =
  | { op: 'navigate'; url: string; tab_id?: string }
  | { op: 'click'; selector: string; tab_id?: string }
  | { op: 'fill'; selector: string; text: string; tab_id?: string }
  | { op: 'wait'; ms?: number; selector?: string; tab_id?: string }
  | { op: 'extract'; selector: string; as?: string; tab_id?: string }
  | { op: 'download_wait'; timeout_ms?: number; as?: string; tab_id?: string }
  | { op: 'tab_activate'; tab_id: string }
  | { op: 'tab_new'; url?: string }
  | { op: 'tab_close'; tab_id?: string };

const stepTabId = (step: BrowserStep): string | undefined =>
  step.op === 'tab_activate' || step.op === 'tab_close'
    ? step.tab_id
    : 'tab_id' in step
      ? step.tab_id
      : undefined;

export async function runSteps(
  engine: BrowserEngine,
  steps: BrowserStep[],
  defaultTabId?: string,
): Promise<Record<string, string>> {
  const out: Record<string, string> = {};
  let batchTab = defaultTabId;
  for (const step of steps) {
    switch (step.op) {
      case 'tab_activate':
        await engine.tabActivate(step.tab_id);
        batchTab = step.tab_id;
        break;
      case 'tab_new': {
        const { tabId } = await engine.tabNew(step.url);
        out.last_tab_id = tabId;
        batchTab = tabId;
        break;
      }
      case 'tab_close': {
        const id = step.tab_id ?? batchTab ?? engine.getActiveTabId();
        if (!id) throw new Error('no tab to close');
        await engine.tabClose(id);
        if (batchTab === id) batchTab = engine.getActiveTabId() ?? undefined;
        break;
      }
      default: {
        const page = engine.pageFor(stepTabId(step) ?? batchTab);
        if (!page) throw new Error('no tab for step');
        switch (step.op) {
          case 'navigate':
            await page.goto(step.url, { waitUntil: 'domcontentloaded', timeout: 60_000 });
            break;
          case 'click':
            await page.click(step.selector, { timeout: 30_000 });
            break;
          case 'fill':
            await page.fill(step.selector, step.text, { timeout: 30_000 });
            break;
          case 'wait':
            if (step.selector) await page.waitForSelector(step.selector, { timeout: step.ms ?? 30_000 });
            else if (step.ms) await page.waitForTimeout(step.ms);
            break;
          case 'extract': {
            const text = await page.locator(step.selector).first().innerText({ timeout: 15_000 }).catch(() => '');
            const key = step.as ?? step.selector;
            out[key] = text.trim();
            break;
          }
          case 'download_wait': {
            const dl = await engine.downloadWait(step.timeout_ms ?? 60_000);
            const key = step.as ?? 'download';
            out[key] = JSON.stringify(dl);
            break;
          }
          default:
            break;
        }
        break;
      }
    }
  }
  return out;
}
