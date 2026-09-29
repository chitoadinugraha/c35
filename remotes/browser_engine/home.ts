import type { HomeContext } from './protocol.js';

export const BROWSER_HOME_URL = 'about:home';

/** Hosted new-tab page for remote browser (Playwright). */
export const BROWSER_HOME_HTTPS = 'https://alienai.id/search';

export function isBlankOrHomeUrl(url: string): boolean {
  const u = url.trim().toLowerCase();
  return (
    !u ||
    u === 'about:blank' ||
    u === 'about:newtab' ||
    u === BROWSER_HOME_URL ||
    u.startsWith('chrome://newtab') ||
    u.startsWith('edge://newtab') ||
    u.includes('alienai.id/search') ||
    u.includes('/_c35/home.html')
  );
}

export function canonicalTabUrl(url: string): string {
  if (isBlankOrHomeUrl(url)) return BROWSER_HOME_HTTPS;
  return url;
}

export function resolveNavigateUrl(raw: string, _profileDir: string, _ctx?: HomeContext): string {
  const t = raw.trim();
  if (!t || t === 'about:blank' || t === 'about:newtab' || t === BROWSER_HOME_URL) {
    return BROWSER_HOME_HTTPS;
  }
  if (isBlankOrHomeUrl(t)) return BROWSER_HOME_HTTPS;
  return t;
}
