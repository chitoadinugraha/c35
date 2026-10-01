#!/usr/bin/env node
/**
 * Dev probe: launch browser_engine like dev_browser, open a URL, save JPEG + text hints for Cloudflare.
 * Usage (from repo root):
 *   node _/scripts/dev/browser_cf_probe.mjs [url]
 * Env: C35_BROWSER_LAUNCH_MODE=cdp|playwright, C35_BROWSER_HEADLESS=0|1
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..', '..');
const engineDir = path.join(repoRoot, 'remotes', 'browser_engine');
const { BrowserEngine } = await import(pathToFileURL(path.join(engineDir, 'dist', 'browser.js')).href);

const url = process.argv[2] ?? 'https://malang.epuskesmas.id/login';
const launchMode = (process.env.C35_BROWSER_LAUNCH_MODE ?? 'cdp').toLowerCase();
const headless = process.env.C35_BROWSER_HEADLESS === '1';
const local = process.env.LOCALAPPDATA ?? path.join(process.env.HOME ?? '/tmp', '.local');
const userDataDir = path.join(local, 'AlienAI', 'browser', 'slots', 'cf_probe');
const downloadsPath = path.join(userDataDir, 'downloads');
const outDir = path.join(repoRoot, '.cache', 'browser-cf-probe');

fs.mkdirSync(outDir, { recursive: true });
fs.mkdirSync(downloadsPath, { recursive: true });

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

const engine = new BrowserEngine();
console.log('launch', { launchMode, headless, userDataDir, url });

await engine.launch({
  headless,
  userDataDir,
  downloadsPath,
  viewport: { width: 1280, height: 800 },
  channel: 'chrome',
});

await engine.tabNew(url);
await sleep(8000);

const page = engine.activePage();
if (!page) throw new Error('no active page');

const title = await page.title().catch(() => '');
const bodyText = await page.locator('body').innerText({ timeout: 20_000 }).catch(() => '');
const hasSuccess = /success!/i.test(bodyText);
const hasTurnstile = /cloudflare|turnstile|verify you are human/i.test(bodyText);
const shot = await engine.pageScreenshot(undefined, 80);
const jpeg = Buffer.from(shot.jpeg_b64, 'base64');
const stamp = new Date().toISOString().replace(/[:.]/g, '-');
const base = path.join(outDir, `${stamp}_${launchMode}`);
fs.writeFileSync(`${base}.jpg`, jpeg);
fs.writeFileSync(
  `${base}.txt`,
  [
    `url: ${page.url()}`,
    `title: ${title}`,
    `launchMode: ${launchMode}`,
    `headless: ${headless}`,
    `cf_success_text: ${hasSuccess}`,
    `cf_challenge_hints: ${hasTurnstile}`,
    '--- body (first 4000 chars) ---',
    bodyText.slice(0, 4000),
  ].join('\n'),
);

console.log('saved', `${base}.jpg`);
console.log('cf_success_text:', hasSuccess);
console.log('cf_challenge_hints:', hasTurnstile);
console.log('title:', title);

await engine.shutdown();
process.exit(hasSuccess ? 0 : 2);
