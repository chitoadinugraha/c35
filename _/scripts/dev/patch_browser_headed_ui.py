from pathlib import Path
path = Path(r"D:/c35/remotes/browser_engine/browser.ts")
text = path.read_text(encoding="utf-8")
old_args = """const LAUNCH_ARGS = [
  '--disable-blink-features=AutomationControlled',
  '--no-sandbox',
  '--disable-setuid-sandbox',
  '--disable-infobars',
  '--window-position=0,0',
];"""
new_args = """const LAUNCH_ARGS_BASE = [
  '--disable-blink-features=AutomationControlled',
  '--no-sandbox',
  '--disable-setuid-sandbox',
  '--disable-infobars',
];

const launchArgs = (headless: boolean): string[] =>
  headless
    ? [...LAUNCH_ARGS_BASE, '--window-position=0,0']
    : [...LAUNCH_ARGS_BASE, '--start-maximized', '--window-size=1280,800'];

const HEADED_HOME_URL =
  'data:text/html;charset=utf-8,' +
  encodeURIComponent(
    '<!doctype html><html><head><title>Alien AI Remote Browser</title></head>' +
      '<body style="font-family:system-ui;margin:2rem">' +
      '<h1>Alien AI Remote Browser</h1><p>Chromium is running on this PC. Use the app Remote tab to drive this session.</p>' +
      '</body></html>',
  );"""
if old_args not in text:
    raise SystemExit("LAUNCH_ARGS block not found")
text = text.replace(old_args, new_args)
text = text.replace("args: LAUNCH_ARGS,", "args: launchArgs(headless),")
text = text.replace(
    "this.browser = await chromium.launch({ headless, args: LAUNCH_ARGS });",
    "this.browser = await chromium.launch({ headless, args: launchArgs(headless) });",
)
old_tail = """    const url = params.initialUrl ?? 'about:blank';
    if (url !== 'about:blank' && url !== 'about:newtab') {
      await first.goto(url, { waitUntil: 'domcontentloaded', timeout: 30_000 }).catch(() => {});
    }
  }"""
new_tail = """    const url = params.initialUrl ?? (headless ? 'about:blank' : HEADED_HOME_URL);
    if (url !== 'about:blank' && url !== 'about:newtab') {
      await first.goto(url, { waitUntil: 'domcontentloaded', timeout: 30_000 }).catch(() => {});
    }
    if (!headless) {
      try {
        await first.bringToFront();
        await first.evaluate(() => window.focus());
      } catch {
        /* ignore */
      }
      console.error('[c35-browser-engine] headed Chromium window is open (check taskbar)');
    } else {
      console.error('[c35-browser-engine] headless Chromium started');
    }
  }"""
if old_tail not in text:
    raise SystemExit("launch tail block not found")
text = text.replace(old_tail, new_tail)
path.write_text(text, encoding="utf-8", newline="\n")
print("patched browser.ts")