import * as fs from 'node:fs';
import * as path from 'node:path';
import { chromium, type Browser, type BrowserContext, type Download, type Page } from 'playwright';
import type { InputEvent, LaunchParams } from './protocol.js';
import { Screencast } from './screencast.js';
import { runSteps, type BrowserStep } from './steps.js';

export type DownloadInfo = { path: string; filename: string; url: string };

const LAUNCH_ARGS = [
  '--disable-blink-features=AutomationControlled',
  '--no-sandbox',
  '--disable-setuid-sandbox',
  '--disable-infobars',
  '--window-position=0,0',
];

export type TabInfo = { tabId: string; url: string; title: string; active: boolean };

export class BrowserEngine {
  private browser: Browser | null = null;
  private context: BrowserContext | null = null;
  private pages = new Map<string, Page>();
  private activeTabId: string | null = null;
  private screencast: Screencast | null = null;
  private screencastSink: ((jpeg: Buffer, seq: number, sessionId: number) => void) | null = null;
  private tabSeq = 0;
  private downloadsDir = '';
  private downloadWaiter: {
    resolve: (info: DownloadInfo) => void;
    reject: (err: Error) => void;
    timer: ReturnType<typeof setTimeout>;
  } | null = null;

  public width = 1280;
  public height = 800;

  public async launch(params: LaunchParams = {}): Promise<void> {
    await this.shutdown();
    if (params.viewport) {
      this.width = params.viewport.width;
      this.height = params.viewport.height;
    }
    const headless = params.headless ?? false;
    const viewport = { width: this.width, height: this.height };
    this.downloadsDir = params.downloadsPath?.trim() || path.join(params.userDataDir ?? '.', 'downloads');
    fs.mkdirSync(this.downloadsDir, { recursive: true });
    if (params.userDataDir) {
      this.context = await chromium.launchPersistentContext(params.userDataDir, {
        headless,
        args: LAUNCH_ARGS,
        viewport,
        acceptDownloads: true,
        downloadsPath: this.downloadsDir,
      });
    } else {
      this.browser = await chromium.launch({ headless, args: LAUNCH_ARGS });
      this.context = await this.browser.newContext({
        viewport,
        acceptDownloads: true,
      });
    }
    this.context.on('page', (page) => this.wireDownloadHandler(page));
    const existing = this.context.pages();
    const first = existing.length > 0 ? existing[0] : await this.context.newPage();
    const tabId = this.nextTabId();
    this.pages.set(tabId, first);
    this.activeTabId = tabId;
    this.wireDownloadHandler(first);
    await first.addInitScript(() => {
      Object.defineProperty(navigator, 'webdriver', { get: () => undefined });
    });
    const url = params.initialUrl ?? 'about:blank';
    if (url !== 'about:blank' && url !== 'about:newtab') {
      await first.goto(url, { waitUntil: 'domcontentloaded', timeout: 30_000 }).catch(() => {});
    }
  }

  public getActiveTabId(): string | null {
    return this.activeTabId;
  }

  public pageFor(tabId?: string): Page | null {
    const id = tabId ?? this.activeTabId;
    return id ? this.pages.get(id) ?? null : null;
  }

  public activePage(): Page | null {
    return this.pageFor();
  }

  public async tabList(): Promise<TabInfo[]> {
    const active = this.activeTabId;
    const out: TabInfo[] = [];
    for (const [tabId, page] of this.pages) {
      out.push({
        tabId,
        url: page.url(),
        title: await page.title().catch(() => ''),
        active: tabId === active,
      });
    }
    return out;
  }

  public async tabActivate(tabId: string): Promise<void> {
    if (!this.pages.has(tabId)) throw new Error(`unknown tab: ${tabId}`);
    this.activeTabId = tabId;
    await this.rebindScreencast();
  }

  public async tabNew(url?: string): Promise<{ tabId: string }> {
    if (!this.context) throw new Error('engine not launched');
    const page = await this.context.newPage();
    this.wireDownloadHandler(page);
    await page.addInitScript(() => {
      Object.defineProperty(navigator, 'webdriver', { get: () => undefined });
    });
    const tabId = this.nextTabId();
    this.pages.set(tabId, page);
    this.activeTabId = tabId;
    if (url && url !== 'about:blank') {
      await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 30_000 }).catch(() => {});
    }
    await this.rebindScreencast();
    return { tabId };
  }

  public async tabClose(tabId: string): Promise<void> {
    const page = this.pages.get(tabId);
    if (!page) throw new Error(`unknown tab: ${tabId}`);
    this.pages.delete(tabId);
    if (this.activeTabId === tabId) {
      this.activeTabId = this.pages.keys().next().value ?? null;
      await this.rebindScreencast();
    }
    await page.close().catch(() => {});
  }

  public async downloadWait(timeoutMs: number): Promise<DownloadInfo> {
    return new Promise((resolve, reject) => {
      if (this.downloadWaiter) {
        clearTimeout(this.downloadWaiter.timer);
        this.downloadWaiter.reject(new Error('download wait superseded'));
      }
      const timer = setTimeout(() => {
        this.downloadWaiter = null;
        reject(new Error('download wait timed out'));
      }, timeoutMs);
      this.downloadWaiter = { resolve, reject, timer };
    });
  }

  public async fileUpload(
    tabId: string | undefined,
    selector: string,
    files: { name: string; bytes: Buffer }[],
  ): Promise<void> {
    const page = this.pageFor(tabId);
    if (!page) throw new Error('no tab for upload');
    const paths: string[] = [];
    for (const f of files) {
      const dest = path.join(this.downloadsDir, `upload_${Date.now()}_${f.name}`);
      fs.writeFileSync(dest, f.bytes);
      paths.push(dest);
    }
    try {
      const loc = page.locator(selector);
      if (await loc.count()) {
        await loc.setInputFiles(paths);
        return;
      }
      const [chooser] = await Promise.all([
        page.waitForEvent('filechooser', { timeout: 15_000 }),
        page.click(selector, { timeout: 15_000 }),
      ]);
      await chooser.setFiles(paths);
    } finally {
      for (const p of paths) fs.unlinkSync(p);
    }
  }

  public async navigate(url: string): Promise<void> {
    const page = this.activePage();
    if (!page) throw new Error('no active tab');
    await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 60_000 });
  }

  public async pageObserve(
    tabId?: string,
    maxChars = 8000,
  ): Promise<{ url: string; title: string; snapshot: string; truncated: boolean }> {
    const page = this.pageFor(tabId);
    if (!page) throw new Error('no tab for observe');
    const cap = Math.min(Math.max(maxChars, 500), 50_000);
    const url = page.url();
    const title = await page.title().catch(() => '');
    let snapshot = '';
    try {
      const root = page.locator('body');
      if (typeof (root as { ariaSnapshot?: (opts?: { timeout?: number }) => Promise<string> }).ariaSnapshot === 'function') {
        snapshot = await (root as { ariaSnapshot: (opts?: { timeout?: number }) => Promise<string> }).ariaSnapshot({
          timeout: 20_000,
        });
      } else {
        snapshot = await root.innerText({ timeout: 20_000 });
      }
    } catch {
      snapshot = await page.locator('body').innerText({ timeout: 15_000 }).catch(() => '');
    }
    const truncated = snapshot.length > cap;
    if (truncated) snapshot = snapshot.slice(0, cap);
    return { url, title, snapshot, truncated };
  }

  public async taskRun(
    steps: BrowserStep[],
    _slotId?: string,
    defaultTabId?: string,
  ): Promise<Record<string, string>> {
    void _slotId;
    if (!this.pageFor(defaultTabId) && !this.activePage()) throw new Error('no active tab');
    return runSteps(this, steps, defaultTabId);
  }

  public async screencastStart(onFrame: (jpeg: Buffer, seq: number, sessionId: number) => void): Promise<void> {
    await this.screencastStop();
    const page = this.activePage();
    if (!page) throw new Error('no active tab');
    this.screencastSink = onFrame;
    this.screencast = new Screencast(page, {
      width: this.width,
      height: this.height,
      onFrame: (frame, seq) => onFrame(frame.jpeg, seq, frame.sessionId),
    });
    await this.screencast.start();
  }

  public async screencastStop(): Promise<void> {
    if (!this.screencast) return;
    await this.screencast.stop();
    this.screencast = null;
    this.screencastSink = null;
  }

  public async input(event: InputEvent): Promise<void> {
    const page = this.activePage();
    if (!page) return;
    switch (event.type) {
      case 'mouseMove':
        await page.mouse.move(event.x, event.y);
        break;
      case 'mouseDown':
        await page.mouse.move(event.x, event.y);
        await page.mouse.down({ button: event.button });
        break;
      case 'mouseUp':
        await page.mouse.move(event.x, event.y);
        await page.mouse.up({ button: event.button });
        break;
      case 'wheel':
        await page.mouse.move(event.x, event.y);
        await page.mouse.wheel(event.deltaX, event.deltaY);
        break;
      case 'keyDown':
        await page.keyboard.down(event.key);
        break;
      case 'keyUp':
        await page.keyboard.up(event.key);
        break;
      case 'text':
        await page.keyboard.insertText(event.text);
        break;
      default:
        break;
    }
  }

  private wireDownloadHandler(page: Page): void {
    page.on('download', (download: Download) => void this.onDownload(download));
  }

  private async onDownload(download: Download): Promise<void> {
    const waiter = this.downloadWaiter;
    if (!waiter) return;
    clearTimeout(waiter.timer);
    this.downloadWaiter = null;
    try {
      const filename = download.suggestedFilename();
      const dest = path.join(this.downloadsDir, filename);
      await download.saveAs(dest);
      waiter.resolve({ path: dest, filename, url: download.url() });
    } catch (e) {
      waiter.reject(e instanceof Error ? e : new Error(String(e)));
    }
  }

  public async shutdown(): Promise<void> {
    if (this.downloadWaiter) {
      clearTimeout(this.downloadWaiter.timer);
      this.downloadWaiter.reject(new Error('engine shutdown'));
      this.downloadWaiter = null;
    }
    await this.screencastStop();
    for (const p of this.pages.values()) await p.close().catch(() => {});
    this.pages.clear();
    this.activeTabId = null;
    if (this.context) await this.context.close().catch(() => {});
    if (this.browser) await this.browser.close().catch(() => {});
    this.context = null;
    this.browser = null;
  }

  private nextTabId(): string {
    this.tabSeq += 1;
    return `tab_${this.tabSeq}`;
  }

  private async rebindScreencast(): Promise<void> {
    if (!this.screencastSink) return;
    const sink = this.screencastSink;
    await this.screencastStart(sink);
  }
}