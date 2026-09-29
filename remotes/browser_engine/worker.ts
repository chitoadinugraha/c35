#!/usr/bin/env node
import { BrowserEngine } from './browser.js';
import type { IpcReq, LaunchParams } from './protocol.js';
import { evt, frameEncode, frameTryParse, resErr, resOk, type InputEvent, type ScreencastFrameParams } from './protocol.js';
import type { BrowserStep } from './steps.js';

const engine = new BrowserEngine();
let rx: Buffer = Buffer.alloc(0);

const writeMessage = (msg: Parameters<typeof frameEncode>[0]): void => {
  process.stdout.write(frameEncode(msg));
};

const emitScreencastFrame = (jpeg: Buffer, seq: number, sessionId: number): void => {
  writeMessage(evt('screencast.frame', { seq, width: engine.width, height: engine.height, sessionId, jpeg_b64: jpeg.toString('base64') }));
};

const handleReq = async (req: IpcReq): Promise<void> => {
  const { id, method, params } = req;
  try {
    switch (method) {
      case 'ping': writeMessage(resOk(id, { pong: true })); return;
      case 'launch': await engine.launch((params ?? {}) as LaunchParams); writeMessage(resOk(id, { width: engine.width, height: engine.height })); return;
      case 'shutdown': await engine.shutdown(); writeMessage(resOk(id)); return;
      case 'screencast.start': await engine.screencastStart(emitScreencastFrame); writeMessage(resOk(id)); return;
      case 'screencast.stop': await engine.screencastStop(); writeMessage(resOk(id)); return;
      case 'input': await engine.input((params ?? {}) as InputEvent); writeMessage(resOk(id)); return;
      case 'tab.list': writeMessage(resOk(id, { tabs: await engine.tabList() })); return;
      case 'tab.activate': { const tabId = (params as { tabId?: string })?.tabId; if (!tabId) throw new Error('tabId required'); await engine.tabActivate(tabId); writeMessage(resOk(id)); return; }
      case 'tab.new': writeMessage(resOk(id, await engine.tabNew((params as { url?: string })?.url))); return;
      case 'tab.close': { const tabId = (params as { tabId?: string })?.tabId; if (!tabId) throw new Error('tabId required'); await engine.tabClose(tabId); writeMessage(resOk(id)); return; }
      case 'navigate': { const url = (params as { url?: string })?.url; if (!url) throw new Error('url required'); await engine.navigate(url); writeMessage(resOk(id)); return; }
      case 'page.observe': {
        const p = params as { tab_id?: string; max_chars?: number };
        const maxChars = p?.max_chars ?? 8000;
        writeMessage(resOk(id, await engine.pageObserve(p?.tab_id, maxChars)));
        return;
      }
      case 'task.run': {
        const p = params as { steps?: BrowserStep[]; slot_id?: string; tab_id?: string };
        const steps = p?.steps ?? [];
        writeMessage(resOk(id, { result: await engine.taskRun(steps, p?.slot_id, p?.tab_id) }));
        return;
      }
      case 'download.wait': {
        const timeoutMs = (params as { timeout_ms?: number })?.timeout_ms ?? 60_000;
        writeMessage(resOk(id, await engine.downloadWait(timeoutMs)));
        return;
      }
      case 'file.upload': {
        const p = params as { tab_id?: string; selector?: string; files?: { name: string; b64: string }[] };
        const selector = p?.selector?.trim();
        if (!selector) throw new Error('selector required');
        const files = (p?.files ?? []).map((f) => ({ name: f.name, bytes: Buffer.from(f.b64, 'base64') }));
        if (!files.length) throw new Error('files required');
        await engine.fileUpload(p?.tab_id, selector, files);
        writeMessage(resOk(id));
        return;
      }
      default: writeMessage(resErr(id, 'unknown_method', method));
    }
  } catch (err) {
    writeMessage(resErr(id, 'error', err instanceof Error ? err.message : String(err)));
  }
};

process.stdin.on('data', (chunk: Buffer) => {
  rx = Buffer.concat([rx, chunk]);
  for (;;) {
    const parsed = frameTryParse(rx);
    if (!parsed) break;
    rx = parsed.rest;
    if (parsed.message.kind === 'req') void handleReq(parsed.message);
  }
});
process.stdin.on('end', () => { void engine.shutdown().finally(() => process.exit(0)); });
process.stdin.resume();
writeMessage(evt('worker.ready', { pid: process.pid }));