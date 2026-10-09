import puppeteer from "puppeteer";

const url = process.argv[2] || "http://127.0.0.1:8780/";
const browser = await puppeteer.launch({
  headless: "new",
  args: ["--enable-webgl", "--use-gl=angle", "--ignore-gpu-blocklist"],
});
const page = await browser.newPage();
page.on("pageerror", (e) => console.error("pageerror:", e.message));
await page.setViewport({ width: 1280, height: 900 });
await page.goto(url, { waitUntil: "networkidle2", timeout: 180000 });
await new Promise((r) => setTimeout(r, 12000));
const placeholder = await page.$("flt-semantics-placeholder");
if (placeholder) await placeholder.click();
await new Promise((r) => setTimeout(r, 2000));
const out = await page.evaluate(() => ({
  text: document.body.innerText.slice(0, 2000),
  aria: document.querySelector("flt-semantics-host")?.innerText?.slice(0, 2000) || "",
  splash: !!document.getElementById("splash"),
  label: document.getElementById("flutter-load-label")?.textContent || "",
}));
console.log(JSON.stringify(out, null, 2));
await browser.close();