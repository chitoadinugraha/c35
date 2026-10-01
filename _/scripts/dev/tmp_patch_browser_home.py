from pathlib import Path

def fix_utf16(path: Path) -> None:
    raw = path.read_bytes()
    if raw[:2] in (b"\xff\xfe", b"\xfe\xff") or (len(raw) > 2 and raw[1] == 0):
        text = raw.decode("utf-16")
        path.write_text(text, encoding="utf-8", newline="\n")

root = Path(r"D:/c35/remotes/browser_engine")
for name in ("home.ts", "home.html", "_patch_home.mjs"):
    p = root / name
    if p.exists():
        fix_utf16(p)

p = root / "browser.ts"
text = p.read_text(encoding="utf-8")

def rep(old: str, new: str, label: str) -> None:
    global text
    if old not in text:
        raise SystemExit(f"missing {label}")
    text = text.replace(old, new, 1)

rep(
    "import type { InputEvent, LaunchParams } from './protocol.js';",
    """import type { HomeContext, InputEvent, LaunchParams } from './protocol.js';
import {
  BROWSER_HOME_URL,
  canonicalTabUrl,
  isBlankOrHomeUrl,
  resolveNavigateUrl,
} from './home.js';""",
    "import",
)

rep(
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
    """export type TabInfo = {
  tabId: string;
  url: string;
  title: string;
  active: boolean;
  loading?: boolean;
  favicon?: string;
};

type TabMeta = { loading: boolean; favicon: string };""",
    "tabinfo",
)

rep(
    "  } | null = null;\n\n  public width = 1280;",
    "  } | null = null;\n  private tabMeta = new Map<string, TabMeta>();\n  private profileDir = '';\n  private homeContext: HomeContext | undefined;\n\n  public width = 1280;",
    "fields",
)

rep(
    "    this.downloadsDir = params.downloadsPath?.trim() || path.join(params.userDataDir ?? '.', 'downloads');\n    fs.mkdirSync(this.downloadsDir, { recursive: true });",
    "    this.downloadsDir = params.downloadsPath?.trim() || path.join(params.userDataDir ?? '.', 'downloads');\n    this.profileDir = params.userDataDir?.trim() || '';\n    this.homeContext = params.homeContext;\n    fs.mkdirSync(this.downloadsDir, { recursive: true });",
    "downloads",
)

rep(
    """    const restoredSession = existing.length > 0 && existing.some((pg) => !isBlankPageUrl(pg.url()));
    const defaultUrl = params.initialUrl ?? 'about:blank';
    const shouldOpenDefault =
      defaultUrl !== 'about:blank' &&
      defaultUrl !== 'about:newtab' &&
      (!restoredSession || !isBlankPageUrl(first.url()));
    if (shouldOpenDefault) {
      await first.goto(defaultUrl, { waitUntil: 'domcontentloaded', timeout: 30_000 }).catch(() => {});
    }
  }""",
    """    for (const [tabId, page] of this.pages) {
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
  }""",
    "launch",
)

rep(
    """      out.push({
        tabId,
        url: page.url(),
        title: await page.title().catch(() => ''),
        active: tabId === active,
      });""",
    """      const rawUrl = page.url();
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
      });""",
    "tablist",
)

rep(
    """    if (url && url !== 'about:blank') {
      await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 30_000 }).catch(() => {});
    }
    await this.rebindScreencast();
    return { tabId };
  }""",
    """    this.wireTabMeta(tabId, page);
    const dest = resolveNavigateUrl(url ?? BROWSER_HOME_URL, this.profileDir || this.downloadsDir, this.homeContext);
    await page.goto(dest, { waitUntil: 'domcontentloaded', timeout: 30_000 }).catch(() => {});
    await this.rebindScreencast();
    return { tabId };
  }""",
    "tabnew",
)

rep(
    """  public async navigate(url: string): Promise<void> {
    const page = this.activePage();
    if (!page) throw new Error('no active tab');
    await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 60_000 });
  }""",
    """  public async navigate(url: string): Promise<void> {
    const page = this.activePage();
    if (!page) throw new Error('no active tab');
    const dest = resolveNavigateUrl(url, this.profileDir || this.downloadsDir, this.homeContext);
    const tabId = this.activeTabId;
    if (tabId) this.setTabLoading(tabId, true);
    await page.goto(dest, { waitUntil: 'domcontentloaded', timeout: 60_000 }).catch(() => {});
    if (tabId) void this.refreshTabFavicon(tabId, page);
  }""",
    "navigate",
)

helper = """
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
          document.querySelector<HTMLLinkElement>('link[rel~=\"icon\"]') ||
          document.querySelector<HTMLLinkElement>('link[rel=\"shortcut icon\"]');
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

"""

needle = "  private nextTabId(): string {"
if "wireTabMeta" not in text:
    if needle not in text:
        raise SystemExit("nextTabId missing")
    text = text.replace(needle, helper + needle, 1)

text = text.replace(
    "    this.pages.clear();\n    this.activeTabId = null;",
    "    this.pages.clear();\n    this.tabMeta.clear();\n    this.activeTabId = null;",
)

p.write_text(text, encoding="utf-8", newline="\n")
print("done")