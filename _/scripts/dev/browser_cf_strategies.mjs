#!/usr/bin/env node
/**
 * Try Turnstile click strategies on e-Puskesmas; print JSON report.
 */
import { spawn, execSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..', '..');
const { BrowserEngine } = await import(pathToFileURL(path.join(repoRoot, 'remotes/browser_engine/dist/browser.js')).href);

const url = process.argv[2] ?? 'https://malang.epuskesmas.id/login';
const launchMode = (process.env.C35_BROWSER_LAUNCH_MODE ?? 'cdp').toLowerCase();
const local = process.env.LOCALAPPDATA ?? '';
const userDataDir = path.join(local, 'AlienAI', 'browser', 'slots', 'cf_strategies');
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

const detectState = async (page) => {
  const parts = [];
  parts.push(await page.locator('body').innerText().catch(() => ''));
  for (const fr of page.frames()) {
    if (!/cloudflare|turnstile/i.test(fr.url())) continue;
    parts.push(await fr.locator('body').innerText().catch(() => ''));
  }
  const t = parts.join('\n');
  if (/success!/i.test(t)) return 'success';
  if (/verifying/i.test(t)) return 'verifying';
  if (/verify you are human/i.test(t)) return 'checkbox';
  if (/challenge|turnstile|cloudflare/i.test(t)) return 'challenge_visible';
  return 'unknown';
};

const saveShot = async (page, name) => {
  const out = path.join(repoRoot, '_', 'scripts', 'dev', `cf_${name}.jpg`);
  const jpeg = await page.screenshot({ type: 'jpeg', quality: 78 });
  fs.writeFileSync(out, jpeg);
  return out;
};

const nativeWinClick = (screenX, screenY) => {
  const ps = `
Add-Type @"
using System; using System.Runtime.InteropServices;
public class W {
  [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
  [DllImport("user32.dll")] public static extern void mouse_event(uint f, int dx, int dy, uint b, uint e);
  public static void Click(int x,int y) {
    SetCursorPos(x,y); Thread.Sleep(40);
    mouse_event(0x0002,0,0,0,0); Thread.Sleep(60);
    mouse_event(0x0004,0,0,0,0);
  }
}
"@
[W]::Click(${Math.round(screenX)},${Math.round(screenY)})
`;
  execSync(`powershell -NoProfile -Command ${JSON.stringify(ps)}`, { stdio: 'pipe' });
};

const engine = new BrowserEngine();
await engine.launch({
  headless: false,
  userDataDir,
  downloadsPath: path.join(userDataDir, 'downloads'),
  channel: 'chrome',
  viewport: { width: 1280, height: 800 },
});
await engine.tabNew(url);
await sleep(6000);
const page = engine.activePage();
if (!page) throw new Error('no page');

const report = { url, launchMode, strategies: [] };

const runStrategy = async (id, fn) => {
  await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 60_000 }).catch(() => {});
  await sleep(5000);
  const before = await detectState(page);
  try {
    await fn();
  } catch (e) {
    report.strategies.push({ id, before, after: 'click_error', error: String(e.message ?? e) });
    return;
  }
  await sleep(15000);
  const after = await detectState(page);
  const shot = await saveShot(page, id);
  report.strategies.push({ id, before, after, shot, success: after === 'success' });
};

// 1) Playwright iframe body click
await runStrategy('iframe_body_click', async () => {
  const fr = page.frames().find((f) => /challenges\.cloudflare\.com/i.test(f.url()));
  if (!fr) throw new Error('no cf frame');
  await fr.locator('body').click({ position: { x: 28, y: 28 }, timeout: 8000 });
});

// 2) Playwright page mouse on iframe bbox
await runStrategy('iframe_bbox_mouse', async () => {
  const iframe = page.locator('iframe[src*="challenges.cloudflare"], iframe[src*="turnstile"]').first();
  const box = await iframe.boundingBox({ timeout: 8000 });
  if (!box) throw new Error('no iframe box');
  await page.mouse.click(box.x + 28, box.y + box.height / 2, { delay: 80 });
});

// 3) Engine IPC mouseClick (same path as Remote tab)
await runStrategy('engine_ipc_mouse_click', async () => {
  const iframe = page.locator('iframe[src*="challenges.cloudflare"], iframe[src*="turnstile"]').first();
  const box = await iframe.boundingBox({ timeout: 8000 });
  if (!box) throw new Error('no iframe box');
  const x = box.x + 28;
  const y = box.y + box.height / 2;
  await engine.input({ type: 'mouseClick', button: 'left', x, y, clickCount: 1 });
});

// 4) CDP Input.dispatchMouseEvent
await runStrategy('cdp_dispatch_mouse', async () => {
  const iframe = page.locator('iframe[src*="challenges.cloudflare"], iframe[src*="turnstile"]').first();
  const box = await iframe.boundingBox({ timeout: 8000 });
  if (!box) throw new Error('no iframe box');
  const x = box.x + 28;
  const y = box.y + box.height / 2;
  const cdp = await page.context().newCDPSession(page);
  await cdp.send('Input.dispatchMouseEvent', { type: 'mouseMoved', x, y });
  await cdp.send('Input.dispatchMouseEvent', { type: 'mousePressed', x, y, button: 'left', clickCount: 1 });
  await cdp.send('Input.dispatchMouseEvent', { type: 'mouseReleased', x, y, button: 'left', clickCount: 1 });
});

// 5) Windows native screen click (headed only)
if (process.platform === 'win32') {
  await runStrategy('win32_native_screen_click', async () => {
    const iframe = page.locator('iframe[src*="challenges.cloudflare"], iframe[src*="turnstile"]').first();
    const box = await iframe.boundingBox({ timeout: 8000 });
    if (!box) throw new Error('no iframe box');
    const cdp = await page.context().newCDPSession(page);
    const { windowId } = await cdp.send('Browser.getWindowForTarget');
    const { bounds } = await cdp.send('Browser.getWindowBounds', { windowId });
    const chromeTop = 88;
    const sx = bounds.left + box.x + 28;
    const sy = bounds.top + chromeTop + box.y + box.height / 2;
    nativeWinClick(sx, sy);
  });
}

report.summary = {
  any_success: report.strategies.some((s) => s.success),
  winners: report.strategies.filter((s) => s.success).map((s) => s.id),
};
console.log(JSON.stringify(report, null, 2));
await engine.shutdown();
process.exit(report.summary.any_success ? 0 : 2);
