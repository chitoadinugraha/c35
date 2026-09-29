import * as fs from 'node:fs';
import * as path from 'node:path';
import { fileURLToPath } from 'node:url';

export const BROWSER_HOME_URL = 'about:home';

export type HomeContext = {
  userName?: string;
  alienId?: string;
  packageName?: string;
};

const ENGINE_DIR = path.dirname(fileURLToPath(import.meta.url));

export function isBlankOrHomeUrl(url: string): boolean {
  const u = url.trim().toLowerCase();
  return (
    !u ||
    u === 'about:blank' ||
    u === 'about:newtab' ||
    u === BROWSER_HOME_URL ||
    u.startsWith('chrome://newtab') ||
    u.startsWith('edge://newtab') ||
    u.includes('/_c35/home.html')
  );
}

export function homeHtmlPath(profileDir: string): string {
  const dir = path.join(profileDir, '_c35');
  fs.mkdirSync(dir, { recursive: true });
  return path.join(dir, 'home.html');
}

function syncHomeAsset(name: string, destDir: string): void {
  const src = path.join(ENGINE_DIR, name);
  const dest = path.join(destDir, name);
  if (!fs.existsSync(src)) return;
  try {
    if (!fs.existsSync(dest) || fs.statSync(src).mtimeMs > fs.statSync(dest).mtimeMs) {
      fs.copyFileSync(src, dest);
    }
  } catch {
    fs.copyFileSync(src, dest);
  }
}

export function homeFileUrl(profileDir: string, ctx?: HomeContext): string {
  const dest = homeHtmlPath(profileDir);
  const destDir = path.dirname(dest);
  syncHomeAsset('home.html', destDir);
  syncHomeAsset('home_icon.png', destDir);
  if (ctx) {
    fs.writeFileSync(path.join(path.dirname(dest), 'home_ctx.json'), JSON.stringify(ctx), 'utf8');
  }
  return `file://${dest.replace(/\\/g, '/')}`;
}

export function canonicalTabUrl(url: string): string {
  return isBlankOrHomeUrl(url) ? BROWSER_HOME_URL : url;
}

export function resolveNavigateUrl(raw: string, profileDir: string, ctx?: HomeContext): string {
  const t = raw.trim();
  if (!t || t === 'about:blank' || t === 'about:newtab' || t === BROWSER_HOME_URL) {
    return homeFileUrl(profileDir, ctx);
  }
  return t;
}
