from pathlib import Path
p = Path(r"D:/c35/remotes/browser_engine/browser.ts")
text = p.read_text(encoding="utf-8")
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
if "private wireTabMeta" not in text:
    text = text.replace(needle, helper + needle, 1)
    p.write_text(text, encoding="utf-8", newline="\n")
    print("inserted helpers")
else:
    print("already has helpers")