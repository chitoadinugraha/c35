import fs from "node:fs";
import path from "node:path";
import { pathToFileURL } from "node:url";
const repo = "D:/c35";
const { BrowserEngine } = await import(pathToFileURL(path.join(repo,"remotes/browser_engine/dist/browser.js")).href);
const local = process.env.LOCALAPPDATA;
const userDataDir = path.join(local,"AlienAI","browser","slots","default");
const engine = new BrowserEngine();
await engine.launch({ headless:false, userDataDir, downloadsPath:path.join(userDataDir,"downloads"), channel:"chrome", viewport:{width:1280,height:800}});
await engine.tabNew("https://malang.epuskesmas.id/login");
const page = engine.activePage();
const sleep = (ms)=>new Promise(r=>setTimeout(r,ms));
await sleep(5000);
let frames = page.frames().map(f=>f.url()).filter(u=>u.includes("cloudflare")||u.includes("turnstile"));
console.log("frames", frames);
for (const fr of page.frames()) {
  if (!/challenges\.cloudflare\.com|turnstile/i.test(fr.url())) continue;
  try {
    const box = fr.locator("body");
    await box.click({ position: { x: 30, y: 30 }, timeout: 5000 });
    console.log("clicked frame", fr.url());
  } catch (e) { console.log("click fail", e.message); }
}
await sleep(12000);
const body = await page.locator("body").innerText();
const ok = /success!/i.test(body);
const jpeg = await page.screenshot({ type:"jpeg", quality:80});
fs.writeFileSync("D:/c35/_/scripts/dev/cf_probe_after_click.jpg", jpeg);
console.log("success", ok, "snippet", body.replace(/\s+/g," ").slice(0,200));
await engine.shutdown();