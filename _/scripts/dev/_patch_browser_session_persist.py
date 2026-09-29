from pathlib import Path

p = Path(r"D:/c35/remotes/browser_engine/browser.ts")
t = p.read_text(encoding="utf-8")
anchor = "export type TabInfo = { tabId: string; url: string; title: string; active: boolean };"
insert = """export type TabInfo = { tabId: string; url: string; title: string; active: boolean };

const isBlankPageUrl = (url: string): boolean => {
  const u = url.trim().toLowerCase();
  return (
    !u ||
    u === 'about:blank' ||
    u === 'about:newtab' ||
    u.startsWith('chrome://newtab') ||
    u.startsWith('edge://newtab')
  );
};"""
if "isBlankPageUrl" not in t:
    t = t.replace(anchor, insert, 1)
old = """    const existing = this.context.pages();
    const first = existing.length > 0 ? existing[0] : await this.context.newPage();
    const tabId = this.nextTabId();
    this.pages.set(tabId, first);
    this.activeTabId = tabId;
    this.wireDownloadHandler(first);
    await first.addInitScript(() => {
      Object.defineProperty(navigator, 'webdriver', { get: () => undefined });
    });"""
new = """    const existing = this.context.pages();
    let first: Page;
    if (existing.length > 0) {
      for (const page of existing) {
        const tabId = this.nextTabId();
        this.pages.set(tabId, page);
        this.wireDownloadHandler(page);
        await page.addInitScript(() => {
          Object.defineProperty(navigator, 'webdriver', { get: () => undefined });
        });
      }
      first = existing[0];
      this.activeTabId = [...this.pages.keys()].pop() ?? null;
    } else {
      first = await this.context.newPage();
      const tabId = this.nextTabId();
      this.pages.set(tabId, first);
      this.activeTabId = tabId;
      this.wireDownloadHandler(first);
      await first.addInitScript(() => {
        Object.defineProperty(navigator, 'webdriver', { get: () => undefined });
      });
    }"""
if old not in t:
    raise SystemExit("tab registration block not found")
t = t.replace(old, new, 1)
old2 = """    const url = params.initialUrl ?? (headless ? 'about:blank' : HEADED_HOME_URL);
    if (url !== 'about:blank' && url !== 'about:newtab') {
      await first.goto(url, { waitUntil: 'domcontentloaded', timeout: 30_000 }).catch(() => {});
    }"""
new2 = """    const restoredSession = existing.length > 0 && existing.some((p) => !isBlankPageUrl(p.url()));
    const defaultUrl = params.initialUrl ?? (headless ? 'about:blank' : HEADED_HOME_URL);
    const shouldOpenDefault =
      defaultUrl !== 'about:blank' &&
      defaultUrl !== 'about:newtab' &&
      (!restoredSession || !isBlankPageUrl(first.url()));
    if (shouldOpenDefault) {
      await first.goto(defaultUrl, { waitUntil: 'domcontentloaded', timeout: 30_000 }).catch(() => {});
    }"""
if old2 not in t:
    raise SystemExit("goto block not found")
t = t.replace(old2, new2, 1)
p.write_text(t, encoding="utf-8", newline="\n")
print("patched")