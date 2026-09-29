import * as fs from 'node:fs';
import * as path from 'node:path';
import { chromium, type Browser, type BrowserContext, type Download, type Page } from 'playwright';
import type { HomeContext, InputEvent, LaunchParams } from './protocol.js';
import {
  BROWSER_HOME_URL,
  canonicalTabUrl,
  isBlankOrHomeUrl,
  resolveNavigateUrl,
} from './home.js';
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

export type TabInfo = {
  tabId: string;
  url: string;
  title: string;
  active: boolean;
  loading?: boolean;
  favicon?: string;
};

type TabMeta = { loading: boolean; favicon: string };

const STEALTH_INIT_SCRIPT = () => {
  Object.defineProperty(navigator, 'webdriver', { get: () => undefined });
  const originalQuery = window.navigator.permissions.query.bind(window.navigator.permissions);
  window.navigator.permissions.query = (parameters: PermissionDescriptor) =>
    parameters.name === 'notifications'
      ? Promise.resolve({ state: Notification.permission } as PermissionStatus)
      : originalQuery(parameters);
  // @ts-expect-error playwright probe
  delete window.__playwright;
  // @ts-expect-error playwright probe
  delete window.__pwInitScripts;
};


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
  private tabMeta = new Map<string, TabMeta>();
  private profileDir = '';
  private homeContext: HomeContext | undefined;

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
    this.profileDir = params.userDataDir?.trim() || '';
    this.homeContext = params.homeContext;
    fs.mkdirSync(this.downloadsDir, { recursive: true });
    if (params.userDataDir) {
      this.context = await chromium.launchPersistentContext(params.userDataDir, {
        headless,
        args: LAUNCH_ARGS,
        ignoreDefaultArgs: ['--enable-automation'],
        viewport,
        acceptDownloads: true,
        downloadsPath: this.downloadsDir,
      });
      await this.context.addInitScript(STEALTH_INIT_SCRIPT);
    } else {
      this.browser = await chromium.launch({ headless, args: LAUNCH_ARGS });
      this.context = await this.browser.newContext({
        viewport,
        acceptDownloads: true,
      });
      await this.context.addInitScript(STEALTH_INIT_SCRIPT);
    }
    this.context.on('page', (page) => this.wireDownloadHandler(page));
    const existing = this.context.pages();
    let first: Page;
    if (existing.length > 0) {
      for (const page of existing) {
        const tabId = this.nextTabId();
        this.pages.set(tabId, page);
        this.wireDownloadHandler(page);
        await page.addInitScript(STEALTH_INIT_SCRIPT);
      }
      first = existing[0];
      this.activeTabId = [...this.pages.keys()][this.pages.size - 1] ?? null;
    } else {
      first = await this.context.newPage();
      const tabId = this.nextTabId();
      this.pages.set(tabId, first);
      this.activeTabId = tabId;
      this.wireDownloadHandler(first);
      await first.addInitScript(STEALTH_INIT_SCRIPT);
    }
    for (const [tabId, page] of this.pages) {
      this.wireTabMeta(tabId, page);
    }
    const restoredSession = existing.length > 0 && existing.some((pg) => !isBlankOrHomeUrl(pg.url()));
    const defaultUrl = params.initialUrl ?? (headless ? 'about:blank' : BROWSER_HOME_URL);
    const openHome = !headless && (!restoredSession || isBlankOrHomeUrl(first.url()));
    if (openHome) {
      const home = resolveNavigateUrl(BROWSER_HOME_URL, this.profileDir || this.downloadsDir, this.homeContext);
      await first.goto(home, { waitUntil: 'domcontentloaded', timeout: 30_000 }).catch(() => {});
    } else if (
      defaultUrl !== 'about:blank' &&
      defaultUrl !== 'about:newtab' &&
      defaultUrl !== BROWSER_HOME_URL &&
      (!restoredSession || isBlankOrHomeUrl(first.url()))
    ) {
      await first.goto(defaultUrl, { waitUntil: 'domcontentloaded', timeout: 30_000 }).catch(() => {});
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
      const rawUrl = page.url();
      const meta = this.tabMeta.get(tabId) ?? { loading: false, favicon: '' };
      let title = await page.title().catch(() => '');
      if (isBlankOrHomeUrl(rawUrl)) title = title.trim() || 'Alien AI';
      out.push({
        tabId,
        url: canonicalTabUrl(rawUrl),
        title,
        active: tabId === active,
        loading: meta.loading,
        favicon: meta.favicon,
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
    await page.addInitScript(STEALTH_INIT_SCRIPT);
    const tabId = this.nextTabId();
    this.pages.set(tabId, page);
    this.activeTabId = tabId;
    this.wireTabMeta(tabId, page);
    const dest = resolveNavigateUrl(url ?? BROWSER_HOME_URL, this.profileDir || this.downloadsDir, this.homeContext);
    await page.goto(dest, { waitUntil: 'domcontentloaded', timeout: 30_000 }).catch(() => {});
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
    const dest = resolveNavigateUrl(url, this.profileDir || this.downloadsDir, this.homeContext);
    const tabId = this.activeTabId;
    if (tabId) this.setTabLoading(tabId, true);
    await page.goto(dest, { waitUntil: 'domcontentloaded', timeout: 60_000 }).catch(() => {});
    if (tabId) void this.refreshTabFavicon(tabId, page);
  }

  public async historyBack(): Promise<void> {
    const page = this.activePage();
    if (!page) throw new Error('no active tab');
    await page.goBack({ waitUntil: 'domcontentloaded', timeout: 30_000 }).catch(() => undefined);
  }

  public async historyForward(): Promise<void> {
    const page = this.activePage();
    if (!page) throw new Error('no active tab');
    await page.goForward({ waitUntil: 'domcontentloaded', timeout: 30_000 }).catch(() => undefined);
  }

  public async reload(): Promise<void> {
    const page = this.activePage();
    if (!page) throw new Error('no active tab');
    await page.reload({ waitUntil: 'domcontentloaded', timeout: 60_000 });
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
    this.tabMeta.clear();
    this.activeTabId = null;
    if (this.context) await this.context.close().catch(() => {});
    if (this.browser) await this.browser.close().catch(() => {});
    this.context = null;
    this.browser = null;
  }


  private setTabLoading(tabId: string, loading: boolean): void {
    const cur = this.tabMeta.get(tabId) ?? { loading: false, favicon: '' };
    this.tabMeta.set(tabId, { ...cur, loading });
  }

  private async refreshTabFavicon(tabId: string, page: Page): Promise<void> {
    const cur = this.tabMeta.get(tabId) ?? { loading: false, favicon: '' };
    let favicon = '';
    try {
      favicon = await page.evaluate(() => {
        const link =
          document.querySelector<HTMLLinkElement>('link[rel~="icon"]') ||
          document.querySelector<HTMLLinkElement>('link[rel="shortcut icon"]');
        return link?.href?.trim() ?? '';
      });
    } catch {
      favicon = '';
    }
    this.tabMeta.set(tabId, { ...cur, loading: false, favicon });
  }

  private wireTabMeta(tabId: string, page: Page): void {
    if (!this.tabMeta.has(tabId)) this.tabMeta.set(tabId, { loading: false, favicon: '' });
    page.on('domcontentloaded', () => void this.refreshTabFavicon(tabId, page));
    page.on('framenavigated', (frame) => {
      if (frame !== page.mainFrame()) return;
      this.setTabLoading(tabId, true);
    });
    page.on('load', () => void this.refreshTabFavicon(tabId, page));
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