from pathlib import Path

p = Path(r"D:/c35/remotes/browser_engine/browser.ts")
t = p.read_text(encoding="utf-8")

STEALTH = """
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
"""

if "STEALTH_INIT_SCRIPT" not in t:
    t = t.replace(
        "export type TabInfo = { tabId: string; url: string; title: string; active: boolean };",
        "export type TabInfo = { tabId: string; url: string; title: string; active: boolean };\n" + STEALTH,
        1,
    )

if "isBlankPageUrl" not in t:
    t = t.replace(
        "export type TabInfo = { tabId: string; url: string; title: string; active: boolean };",
        """export type TabInfo = { tabId: string; url: string; title: string; active: boolean };

const isBlankPageUrl = (url: string): boolean => {
  const u = url.trim().toLowerCase();
  return (
    !u ||
    u === 'about:blank' ||
    u === 'about:newtab' ||
    u.startsWith('chrome://newtab') ||
    u.startsWith('edge://newtab')
  );
};""",
        1,
    )

LAUNCH_OLD = """      this.context = await chromium.launchPersistentContext(params.userDataDir, {
        headless,
        args: LAUNCH_ARGS,
        viewport,
        acceptDownloads: true,
        downloadsPath: this.downloadsDir,
      });"""
LAUNCH_NEW = """      this.context = await chromium.launchPersistentContext(params.userDataDir, {
        headless,
        args: LAUNCH_ARGS,
        ignoreDefaultArgs: ['--enable-automation'],
        viewport,
        acceptDownloads: true,
        downloadsPath: this.downloadsDir,
      });
      await this.context.addInitScript(STEALTH_INIT_SCRIPT);"""
if LAUNCH_NEW not in t and LAUNCH_OLD in t:
    t = t.replace(LAUNCH_OLD, LAUNCH_NEW, 1)

CTX_OLD = """      this.context = await this.browser.newContext({
        viewport,
        acceptDownloads: true,
      });"""
CTX_NEW = """      this.context = await this.browser.newContext({
        viewport,
        acceptDownloads: true,
      });
      await this.context.addInitScript(STEALTH_INIT_SCRIPT);"""
if CTX_NEW not in t and CTX_OLD in t:
    t = t.replace(CTX_OLD, CTX_NEW, 1)

INIT_OLD = """    await first.addInitScript(() => {
      Object.defineProperty(navigator, 'webdriver', { get: () => undefined });
    });"""
INIT_NEW = """    await first.addInitScript(STEALTH_INIT_SCRIPT);"""
if INIT_NEW not in t:
    t = t.replace(INIT_OLD, INIT_NEW)
    t = t.replace(
        """    await page.addInitScript(() => {
      Object.defineProperty(navigator, 'webdriver', { get: () => undefined });
    });""",
        "    await page.addInitScript(STEALTH_INIT_SCRIPT);",
    )

# session restore: register all restored pages
OLD_REG = """    const existing = this.context.pages();
    const first = existing.length > 0 ? existing[0] : await this.context.newPage();
    const tabId = this.nextTabId();
    this.pages.set(tabId, first);
    this.activeTabId = tabId;
    this.wireDownloadHandler(first);
    await first.addInitScript(STEALTH_INIT_SCRIPT);"""
NEW_REG = """    const existing = this.context.pages();
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
    }"""
if OLD_REG in t:
    t = t.replace(OLD_REG, NEW_REG, 1)

# skip goto on restored session
for old_goto, new_goto in [
    (
        """    const url = params.initialUrl ?? 'about:blank';
    if (url !== 'about:blank' && url !== 'about:newtab') {
      await first.goto(url, { waitUntil: 'domcontentloaded', timeout: 30_000 }).catch(() => {});
    }""",
        """    const restoredSession = existing.length > 0 && existing.some((pg) => !isBlankPageUrl(pg.url()));
    const defaultUrl = params.initialUrl ?? 'about:blank';
    const shouldOpenDefault =
      defaultUrl !== 'about:blank' &&
      defaultUrl !== 'about:newtab' &&
      (!restoredSession || !isBlankPageUrl(first.url()));
    if (shouldOpenDefault) {
      await first.goto(defaultUrl, { waitUntil: 'domcontentloaded', timeout: 30_000 }).catch(() => {});
    }""",
    ),
]:
    if old_goto in t:
        t = t.replace(old_goto, new_goto, 1)
        break

# re-apply history/reload if missing from HEAD
if "historyBack" not in t:
    t = t.replace(
        """  public async navigate(url: string): Promise<void> {
    const page = this.activePage();
    if (!page) throw new Error('no active tab');
    await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 60_000 });
  }""",
        """  public async navigate(url: string): Promise<void> {
    const page = this.activePage();
    if (!page) throw new Error('no active tab');
    await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 60_000 });
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
  }""",
        1,
    )

p.write_text(t, encoding="utf-8", newline="\n")
print("browser.ts patched")