#!/usr/bin/env node
/** Smoke: worker IPC page.screenshot returns jpeg_b64. */
import { spawn } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..', '..');
const workerJs = path.join(repoRoot, 'remotes', 'browser_engine', 'dist', 'worker.js');
const { frameEncode, frameTryParse } = await import(
  pathToFileURL(path.join(repoRoot, 'remotes', 'browser_engine', 'dist', 'protocol.js')).href
);

const local = process.env.LOCALAPPDATA ?? '';
const userDataDir = path.join(local, 'AlienAI', 'browser', 'slots', 'screenshot_ipc_test');
const downloadsPath = path.join(userDataDir, 'downloads');
fs.mkdirSync(downloadsPath, { recursive: true });

const proc = spawn(process.execPath, [workerJs], { stdio: ['pipe', 'pipe', 'inherit'] });
let rx = Buffer.alloc(0);
let nextId = 1;
const pending = new Map();

const writeReq = (method, params) =>
  new Promise((resolve, reject) => {
    const id = String(nextId++);
    pending.set(id, { resolve, reject });
    proc.stdin.write(frameEncode({ bridge_version: 1, kind: 'req', id, method, params }));
  });

proc.stdout.on('data', (chunk) => {
  rx = Buffer.concat([rx, chunk]);
  for (;;) {
    const parsed = frameTryParse(rx);
    if (!parsed) break;
    rx = parsed.rest;
    const msg = parsed.message;
    if (msg.kind === 'res') {
      const p = pending.get(msg.id);
      if (!p) continue;
      pending.delete(msg.id);
      if (msg.ok) p.resolve(msg.result ?? {});
      else p.reject(new Error(msg.error?.message ?? 'ipc error'));
    }
  }
});

await new Promise((r) => setTimeout(r, 500));
await writeReq('launch', {
  headless: process.env.C35_BROWSER_HEADLESS === '1',
  userDataDir,
  downloadsPath,
  channel: 'chrome',
  viewport: { width: 1280, height: 800 },
});
await writeReq('tab.new', { url: 'https://example.com/' });
await new Promise((r) => setTimeout(r, 2000));
const shot = await writeReq('page.screenshot', { quality: 75 });
if (!shot?.jpeg_b64 || shot.jpeg_b64.length < 100) {
  console.error('missing jpeg_b64', shot);
  proc.kill();
  process.exit(1);
}
const out = path.join(repoRoot, '_', 'scripts', 'dev', 'browser_ipc_screenshot_test.jpg');
fs.writeFileSync(out, Buffer.from(shot.jpeg_b64, 'base64'));
console.log('ok', out, `${shot.width}x${shot.height}`, shot.url);
await writeReq('shutdown', {});
proc.stdin.end();
setTimeout(() => proc.kill(), 2000);
process.exit(0);
