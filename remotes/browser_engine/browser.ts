import * as fs from 'node:fs';
import * as path from 'node:path';
import { spawn, type ChildProcess } from 'node:child_process';
import * as net from 'node:net';
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
  '--disable-infobars',
  '--window-position=0,0',
];

const launchArgs = (): string[] =>
  process.platform === 'win32' ? LAUNCH_ARGS : [...LAUNCH_ARGS, '--no-sandbox'];

const resolveBrowserChannel = (channel?: string): string | undefined => {
  const c = channel?.trim();
  if (!c) return undefined;
  const lower = c.toLowerCase();
  if (lower === 'chromium' || lower === 'bundled') return undefined;
  return c;
};

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
  Object.defineProperty(navigator, 'webdriver', { get: () => false });
  const w = window as Window & { chrome?: { runtime?: Record<string, unknown> } };
  if (!w.chrome) w.chrome = { runtime: {} };
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

const launchChannelFallbacks = (preferred?: string): (string | undefined)[] => {
  if (preferred) return [preferred];
  if (process.platform === 'win32') return ['chrome', 'msedge', undefined];
  if (process.platform === 'darwin') return ['chrome', undefined];
  return ['chrome', 'msedge', undefined];
};

const resolveLaunchMode = (): 'cdp' | 'playwright' => {
  const m = (process.env.C35_BROWSER_LAUNCH_MODE ?? '').trim().toLowerCase();
  if (m === 'playwright' || m === 'pw') return 'playwright';
  if (m === 'cdp') return 'cdp';
  return process.platform === 'win32' ? 'cdp' : 'playwright';
};

const sleepMs = (ms: number): Promise<void> => new Promise((r) => setTimeout(r, ms));

const resolveChromeExecutable = (): string => {
  const fromEnv = process.env.C35_CHROME_PATH?.trim();
  if (fromEnv && fs.existsSync(fromEnv)) return fromEnv;
  const candidates: string[] = [];
  if (process.platform === 'win32') {
    const local = process.env.LOCALAPPDATA ?? '';
    if (local) candidates.push(path.join(local, 'Google', 'Chrome', 'Application', 'chrome.exe'));
    candidates.push('C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe');
    candidates.push('C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe');
  } else if (process.platform === 'darwin') {
    candidates.push('/Applications/Google Chrome.app/Contents/MacOS/Google Chrome');
  } else {
    candidates.push('/usr/bin/google-chrome', '/usr/bin/google-chrome-stable', '/usr/bin/chromium-browser');
  }
  const hit = candidates.find((p) => p && fs.existsSync(p));
  if (!hit) throw new Error('Google Chrome not found (set C35_CHROME_PATH)');
  return hit;
};

const pickFreePort = (): Promise<number> =>
  new Promise((resolve, reject) => {
    const srv = net.createServer();
    srv.listen(0, '127.0.0.1', () => {
      const addr = srv.address();
      const port = typeof addr === 'object' && addr?.port ? addr.port : 0;
      srv.close(() => (port ? resolve(port) : reject(new Error('no port'))));
    });
    srv.on('error', reject);
  });

const waitChromeCdp = async (cdpUrl: string, proc: ChildProcess, timeoutMs: number): Promise<void> => {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    if (proc.exitCode !== null) throw new Error('Chrome exited (' + String(proc.exitCode) + ')');
    try {
      const res = await fetch(cdpUrl + '/json/version');
      if (res.ok) return;
    } catch {
      /* retry */
    }
    await sleepMs(200);
  }
  throw new Error('Chrome CDP not ready');
};

const spawnChromeCdp = async (
  userDataDir: string,
  opts: { headless: boolean; width: number; height: number },
): Promise<{ proc: ChildProcess; cdpUrl: string }> => {
  fs.mkdirSync(userDataDir, { recursive: true });
  const port = await pickFreePort();
  const chromePath = resolveChromeExecutable();
  const args = [
    '--user-data-dir=' + userDataDir,
    '--remote-debugging-port=' + String(port),
    '--no-first-run',
    '--no-default-browser-check',
    ...launchArgs(),
  ];
  if (opts.headless) args.push('--headless=new');
  if (opts.width && opts.height) args.push('--window-size=' + opts.width + ',' + opts.height);
  const proc = spawn(chromePath, args, { stdio: ['ignore', 'pipe', 'pipe'], windowsHide: false });
  const cdpUrl = 'http://127.0.0.1:' + String(port);
  await waitChromeCdp(cdpUrl, proc, 30_000);
  return { proc, cdpUrl };
};

export class BrowserEngine {
  private browser: Browser | null = null;
  private context: BrowserContext | null = null;
  private chromeProc: ChildProcess | null = null;
  private cdpAttached = false;
  private pages = new Map<string, Page>();
  private activeTabId: string | null = null;
  private screencast: Screencast | null = null;
  private screenshotTimer: ReturnType<typeof setInterval> | null = null;
  private screenshotSeq = 0;
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
    const channel = resolveBrowserChannel(params.channel);
    const viewport = { width: this.width, height: this.height };
    const args = launchArgs();
    this.downloadsDir = params.downloadsPath?.trim() || path.join(params.userDataDir ?? '.', 'downloads');
    this.profileDir = params.userDataDir?.trim() || '';
    this.homeContext = params.homeContext;
    fs.mkdirSync(this.downloadsDir, { recursive: true });
    const channels = launchChannelFallbacks(channel);
    let lastLaunchErr: unknown;
    const tryCdp = resolveLaunchMode() === 'cdp' && !!params.userDataDir && !headless;
    if (params.userDataDir && tryCdp) {
      try {
        const { proc, cdpUrl } = await spawnChromeCdp(params.userDataDir, {
          headless,
          width: viewport.width,
          height: viewport.height,
        });
        this.chromeProc = proc;
        this.browser = await chromium.connectOverCDP(cdpUrl);
        this.cdpAttached = true;
        this.context = this.browser.contexts()[0] ?? null;
        if (!this.context) throw new Error('CDP connect: no browser context');
        lastLaunchErr = undefined;
      } catch (e) {
        lastLaunchErr = e;
        await this.killChromeProc();
        this.browser = null;
        this.context = null;
        this.cdpAttached = false;
      }
    }
    if (params.userDataDir && !this.context) {
      for (const ch of channels) {
        try {
          this.context = await chromium.launchPersistentContext(params.userDataDir, {
            headless,
            ...(ch ? { channel: ch } : {}),
            args,
            ignoreDefaultArgs: ['--enable-automation'],
            viewport,
            acceptDownloads: true,
            downloadsPath: this.downloadsDir,
          });
          lastLaunchErr = undefined;
          break;
        } catch (e) {
          lastLaunchErr = e;
        }
      }
      if (!this.context) throw lastLaunchErr ?? new Error('launchPersistentContext failed');
      await this.context.addInitScript(STEALTH_INIT_SCRIPT);
    } else if (!params.userDataDir) {
      for (const ch of channels) {
        try {
          this.browser = await chromium.launch({
            headless,
            ...(ch ? { channel: ch } : {}),
            args,
            ignoreDefaultArgs: ['--enable-automation'],
          });
          this.context = await this.browser.newContext({
            viewport,
            acceptDownloads: true,
          });
          lastLaunchErr = undefined;
          break;
        } catch (e) {
          lastLaunchErr = e;
        }
      }
      if (!this.context) throw lastLaunchErr ?? new Error('chromium.launch failed');
      await this.context.addInitScript(STEALTH_INIT_SCRIPT);
    }
    await this.installRemoteBrowserContextScript();
    const ctx = this.context;
    if (!ctx) throw lastLaunchErr ?? new Error('browser context missing after launch');
    ctx.on('page', (page) => this.wireDownloadHandler(page));
    const existing = ctx.pages();
    let first: Page;
    if (existing.length > 0) {
      for (const page of existing) {
        const tabId = this.nextTabId();
        this.pages.set(tabId, page);
        this.wireDownloadHandler(page);
        if (!this.cdpAttached) await page.addInitScript(STEALTH_INIT_SCRIPT);
      }
      first = existing[0];
      this.activeTabId = [...this.pages.keys()][this.pages.size - 1] ?? null;
    } else {
      first = await ctx.newPage();
      const tabId = this.nextTabId();
      this.pages.set(tabId, first);
      this.activeTabId = tabId;
      this.wireDownloadHandler(first);
      if (!this.cdpAttached) await first.addInitScript(STEALTH_INIT_SCRIPT);
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
    const page = this.pages.get(tabId);
    if (!page) throw new Error(`unknown tab: ${tabId}`);
    this.activeTabId = tabId;
    await page.bringToFront().catch(() => {});
    try {
      await this.rebindScreencast();
    } catch (e) {
      console.error(`screencast rebind after tab.activate: ${e}`);
    }
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
    if (this.pages.size <= 1) {
      const dest = resolveNavigateUrl(
        BROWSER_HOME_URL,
        this.profileDir || this.downloadsDir,
        this.homeContext,
      );
      await page.goto(dest, { waitUntil: 'domcontentloaded', timeout: 30_000 }).catch(() => {});
      await this.rebindScreencast();
      return;
    }
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

  public async pageScreenshot(
    tabId?: string,
    quality = 80,
  ): Promise<{ url: string; title: string; width: number; height: number; jpeg_b64: string }> {
    const page = this.pageFor(tabId);
    if (!page) throw new Error('no tab for screenshot');
    const q = Math.min(95, Math.max(40, quality));
    const jpeg = await page.screenshot({ type: 'jpeg', quality: q, fullPage: false });
    const vp = page.viewportSize();
    const width = vp?.width ?? this.width;
    const height = vp?.height ?? this.height;
    return {
      url: page.url(),
      title: await page.title().catch(() => ''),
      width,
      height,
      jpeg_b64: jpeg.toString('base64'),
    };
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
    if (this.cdpAttached) {
      this.startScreenshotPump(page, onFrame);
      return;
    }
    this.screencast = new Screencast(page, {
      width: this.width,
      height: this.height,
      onFrame: (frame, seq) => onFrame(frame.jpeg, seq, frame.sessionId),
    });
    await this.screencast.start();
  }

  private startScreenshotPump(page: Page, onFrame: (jpeg: Buffer, seq: number, sessionId: number) => void): void {
    if (this.screenshotTimer) return;
    const fps = Math.min(30, Math.max(5, Number(process.env.C35_BROWSER_JPEG_MAX_FPS ?? 15) || 15));
    const intervalMs = Math.round(1000 / fps);
    const tick = async () => {
      const active = this.activePage();
      if (!active || active !== page) return;
      try {
        const jpeg = await active.screenshot({ type: 'jpeg', quality: 65 });
        this.screenshotSeq += 1;
        onFrame(jpeg, this.screenshotSeq, this.screenshotSeq);
      } catch {
        /* tab navigating or closed */
      }
    };
    void tick();
    this.screenshotTimer = setInterval(() => void tick(), intervalMs);
  }

  private stopScreenshotPump(): void {
    if (!this.screenshotTimer) return;
    clearInterval(this.screenshotTimer);
    this.screenshotTimer = null;
  }

  public async screencastStop(): Promise<void> {
    this.stopScreenshotPump();
    if (!this.screencast) return;
    await this.screencast.stop();
    this.screencast = null;
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
      case 'mouseClick':
        await page.mouse.click(event.x, event.y, {
          button: event.button,
          clickCount: event.clickCount ?? 1,
          delay: 50,
        });
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

  private async installRemoteBrowserContextScript(): Promise<void> {
    if (!this.context || !this.homeContext) return;
    const payload = {
      userName: this.homeContext.userName ?? '',
      alienId: this.homeContext.alienId ?? '',
      packageName: this.homeContext.packageName ?? '',
      deviceName: this.homeContext.deviceName ?? 'Remote browser',
      agentVersion: this.homeContext.agentVersion ?? '',
      cloudOnline: this.homeContext.cloudOnline === true,
    };
    await this.context.addInitScript((ctx: typeof payload) => {
      (window as unknown as { __C35_REMOTE_BROWSER__?: typeof payload }).__C35_REMOTE_BROWSER__ = ctx;
      window.dispatchEvent(new CustomEvent('c35-remote-browser-context', { detail: ctx }));
    }, payload);
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

  private async killChromeProc(): Promise<void> {
    const proc = this.chromeProc;
    this.chromeProc = null;
    if (!proc || proc.killed) return;
    proc.kill();
    await new Promise<void>((r) => {
      const t = setTimeout(r, 2000);
      proc.once('exit', () => {
        clearTimeout(t);
        r();
      });
    });
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
    if (this.cdpAttached) {
      if (this.browser) await this.browser.close().catch(() => {});
      await this.killChromeProc();
    } else {
      if (this.context) await this.context.close().catch(() => {});
      if (this.browser) await this.browser.close().catch(() => {});
    }
    this.context = null;
    this.browser = null;
    this.cdpAttached = false;
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
    if (!this.activePage()) {
      await this.screencastStop();
      return;
    }
    const sink = this.screencastSink;
    await this.screencastStart(sink);
  }
}