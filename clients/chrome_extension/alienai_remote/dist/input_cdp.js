// CDP Input (trusted) for Google Sheets and other canvas editors.

const CDP_VERSION = "1.3";
const attachPromises = new Map();

const tabViewport = (tabId) =>
  new Promise((resolve, reject) => {
    chrome.scripting.executeScript(
      { target: { tabId }, func: () => ({ w: window.innerWidth, h: window.innerHeight }) },
      (results) => {
        if (chrome.runtime.lastError) {
          reject(new Error(chrome.runtime.lastError.message));
          return;
        }
        const r = results?.[0]?.result;
        resolve({ w: r?.w || 1280, h: r?.h || 800 });
      }
    );
  });

const attachTab = (tabId) => {
  const existing = attachPromises.get(tabId);
  if (existing) return existing;
  const p = new Promise((resolve, reject) => {
    chrome.debugger.attach({ tabId }, CDP_VERSION, () => {
      if (chrome.runtime.lastError) reject(new Error(chrome.runtime.lastError.message));
      else resolve();
    });
  });
  attachPromises.set(tabId, p);
  p.catch(() => attachPromises.delete(tabId));
  return p;
};

const sendCdp = async (tabId, method, params = {}) => {
  await attachTab(tabId);
  return new Promise((resolve, reject) => {
    chrome.debugger.sendCommand({ tabId }, method, params, (result) => {
      if (chrome.runtime.lastError) reject(new Error(chrome.runtime.lastError.message));
      else resolve(result);
    });
  });
};

chrome.debugger.onDetach.addListener((source) => {
  if (source.tabId != null) attachPromises.delete(source.tabId);
});

export const isSpreadsheetUrl = (url) => {
  try {
    const u = new URL(url);
    return u.hostname === "docs.google.com" && u.pathname.includes("/spreadsheets/");
  } catch {
    return false;
  }
};

/** @deprecated use isSpreadsheetUrl */
export const isCdpPreferred = isSpreadsheetUrl;

const clamp01 = (v) => Math.min(1, Math.max(0, Number(v) || 0));

const mouseButtonName = (btn) => (btn === 2 ? "right" : btn === 1 ? "middle" : "left");

const cdpPointerXY = async (tabId, nx, ny) => {
  const { w, h } = await tabViewport(tabId);
  return {
    x: Math.round(clamp01(nx) * w),
    y: Math.round(clamp01(ny) * h),
  };
};

const cdpMouseAt = async (tabId, nx, ny, button = "left", clicks = 1) => {
  const { x, y } = await cdpPointerXY(tabId, nx, ny);
  await sendCdp(tabId, "Input.dispatchMouseEvent", { type: "mouseMoved", x, y });
  for (let i = 0; i < clicks; i += 1) {
    await sendCdp(tabId, "Input.dispatchMouseEvent", {
      type: "mousePressed",
      x,
      y,
      button,
      clickCount: i + 1,
    });
    await sendCdp(tabId, "Input.dispatchMouseEvent", {
      type: "mouseReleased",
      x,
      y,
      button,
      clickCount: i + 1,
    });
  }
  return { x, y };
};

const KEY_DEFS = {
  enter: { key: "Enter", code: "Enter", windowsVirtualKeyCode: 13, text: "\r", unmodifiedText: "\r" },
  tab: { key: "Tab", code: "Tab", windowsVirtualKeyCode: 9, text: "\t", unmodifiedText: "\t" },
  escape: { key: "Escape", code: "Escape", windowsVirtualKeyCode: 27 },
  backspace: { key: "Backspace", code: "Backspace", windowsVirtualKeyCode: 8 },
  delete: { key: "Delete", code: "Delete", windowsVirtualKeyCode: 46 },
  home: { key: "Home", code: "Home", windowsVirtualKeyCode: 36 },
  end: { key: "End", code: "End", windowsVirtualKeyCode: 35 },
  arrowup: { key: "ArrowUp", code: "ArrowUp", windowsVirtualKeyCode: 38 },
  arrowdown: { key: "ArrowDown", code: "ArrowDown", windowsVirtualKeyCode: 40 },
  arrowleft: { key: "ArrowLeft", code: "ArrowLeft", windowsVirtualKeyCode: 37 },
  arrowright: { key: "ArrowRight", code: "ArrowRight", windowsVirtualKeyCode: 39 },
  f2: { key: "F2", code: "F2", windowsVirtualKeyCode: 113 },
};

const modifierMask = (mods) => {
  let m = 0;
  if (mods.ctrl) m |= 2;
  if (mods.shift) m |= 8;
  if (mods.alt) m |= 1;
  if (mods.meta) m |= 4;
  return m;
};

const cdpKeyTap = async (tabId, def, mods = {}) => {
  const modifiers = modifierMask(mods);
  const base = {
    key: def.key,
    code: def.code,
    windowsVirtualKeyCode: def.windowsVirtualKeyCode,
    nativeVirtualKeyCode: def.windowsVirtualKeyCode,
    modifiers,
    ...(def.text ? { text: def.text, unmodifiedText: def.unmodifiedText || def.text } : {}),
  };
  await sendCdp(tabId, "Input.dispatchKeyEvent", { type: "keyDown", ...base });
  if (def.text && !modifiers) {
    await sendCdp(tabId, "Input.dispatchKeyEvent", { type: "char", ...base });
  }
  await sendCdp(tabId, "Input.dispatchKeyEvent", { type: "keyUp", ...base });
};

const CELL_REF_RE = /^[A-Z]{1,3}[0-9]{1,7}$/;

const colLetterToIndex = (col) => {
  const s = String(col || "A").trim().toUpperCase();
  let n = 0;
  for (const ch of s) n = n * 26 + (ch.charCodeAt(0) - 64);
  return Math.max(0, n - 1);
};

const colIndexToLetter = (idx) => {
  let n = Math.max(0, idx);
  let s = "";
  do {
    s = String.fromCharCode(65 + (n % 26)) + s;
    n = Math.floor(n / 26) - 1;
  } while (n >= 0);
  return s || "A";
};

const parseCellRef = (ref) => {
  const m = /^([A-Z]{1,3})([0-9]{1,7})$/i.exec(String(ref || "").trim());
  if (!m) throw new Error(`invalid cell ref: ${ref}`);
  return { col: m[1].toUpperCase(), row: Math.max(1, Number(m[2]) || 1) };
};

const sheetsRequireSpreadsheetTab = (tab) => {
  if (!isSpreadsheetUrl(tab?.url || "")) {
    throw new Error("tab is not a Google Sheet — open docs.google.com/spreadsheets and pass tab_id");
  }
};

const findFormulaBarInPage = () => {
  const sels = [
    "#t-formula-bar-input",
    "#formula-bar input",
    '[aria-label="Formula bar"]',
    '[aria-label="Bar formula"]',
    'div[role="textbox"][aria-label*="formula" i]',
  ];
  for (const sel of sels) {
    const el = document.querySelector(sel);
    if (el) return el;
  }
  return null;
};

const readFormulaBar = async (tabId) => {
  const r = await execFirstFrame(tabId, () => {
    const sels = [
      "#t-formula-bar-input",
      "#formula-bar input",
      '[aria-label="Formula bar"]',
      '[aria-label="Bar formula"]',
      '[aria-label="Baris rumus"]',
      '[aria-label="Rumus"]',
    ];
    for (const sel of sels) {
      const el = document.querySelector(sel);
      if (!el) continue;
      const raw = el.value ?? el.textContent ?? el.innerText ?? "";
      return { value: String(raw).trim(), found: true };
    }
    for (const el of document.querySelectorAll('[role="textbox"], [contenteditable="true"]')) {
      const a = (el.getAttribute("aria-label") || "").toLowerCase();
      if (!a.includes("formula") && !a.includes("rumus")) continue;
      const raw = el.value ?? el.textContent ?? el.innerText ?? "";
      return { value: String(raw).trim(), found: true };
    }
    return null;
  });
  return r ?? { value: "", found: false };
};

const execInTab = (tabId, func, args = [], allFrames = false) =>
  new Promise((resolve, reject) => {
    chrome.scripting.executeScript(
      { target: { tabId, allFrames }, func, args, injectImmediately: true },
      (results) => {
        if (chrome.runtime.lastError) {
          reject(new Error(chrome.runtime.lastError.message));
          return;
        }
        resolve(allFrames ? results || [] : results?.[0]?.result);
      }
    );
  });

const execFirstFrame = async (tabId, func, args = []) => {
  const hits = await execInTab(tabId, func, args, true);
  for (const row of hits) {
    const r = row?.result;
    if (r != null && r !== false && r !== "") return r;
  }
  return null;
};

const findNameBoxInPage = () => {
  const sels = [
    "#docs-name-box input",
    "#docs-name-box-input",
    "input#t-name-box",
    'input[aria-label="Name box"]',
    'input[aria-label="Kotak nama"]',
    "#t-name-box input",
    "#t-name-box",
    '[role="combobox"][aria-label*="name" i]',
    '[role="combobox"][aria-label*="nama" i]',
  ];
  for (const sel of sels) {
    const el = document.querySelector(sel);
    if (!el) continue;
    if (el.tagName === "INPUT") return el;
    const inner = el.querySelector("input");
    if (inner) return inner;
    if (el.isContentEditable) return el;
  }
  for (const el of document.querySelectorAll("input")) {
    const a = (el.getAttribute("aria-label") || "").toLowerCase();
    if (a.includes("name box") || a.includes("kotak nama")) return el;
  }
  return null;
};

const nameBoxRectScript = () => {
  const sels = [
    "#docs-name-box input",
    "#docs-name-box-input",
    "input#t-name-box",
    'input[aria-label="Name box"]',
    'input[aria-label="Kotak nama"]',
    "#t-name-box input",
    "#t-name-box",
  ];
  let el = null;
  for (const sel of sels) {
    el = document.querySelector(sel);
    if (el) break;
  }
  if (!el) {
    for (const inp of document.querySelectorAll("input")) {
      const a = (inp.getAttribute("aria-label") || "").toLowerCase();
      if (a.includes("name box") || a.includes("kotak nama")) {
        el = inp;
        break;
      }
    }
  }
  if (!el) return null;
  const r = el.getBoundingClientRect();
  if (r.width < 2 || r.height < 2) return null;
  return {
    x: (r.left + r.width / 2) / window.innerWidth,
    y: (r.top + r.height / 2) / window.innerHeight,
  };
};

const readNameBoxRef = async (tabId) => {
  const v = await execFirstFrame(tabId, function readNameBoxValue() {
    const sels = [
      "#docs-name-box input",
      "input#t-name-box",
      'input[aria-label="Name box"]',
      'input[aria-label="Kotak nama"]',
      "#t-name-box",
    ];
    let el = null;
    for (const sel of sels) el = document.querySelector(sel) || el;
    if (!el) return null;
    if (el.tagName === "INPUT") return (el.value || "").trim().toUpperCase();
    return (el.textContent || "").trim().toUpperCase();
  });
  const raw = String(v || "").trim().toUpperCase();
  return raw.split(":")[0].replace(/\$/g, "");
};
const normalizeCellRef = (ref) => String(ref || "").trim().toUpperCase().split(":")[0].replace(/\$/g, "");

/** Click the name box (DOM rect in any frame, else fixed toolbar guess). */
const focusNameBoxCdp = async (tabId) => {
  const pt = await execFirstFrame(tabId, nameBoxRectScript);
  if (pt?.x != null && pt?.y != null) await cdpMouseAt(tabId, pt.x, pt.y, "left", 1);
  else await cdpMouseAt(tabId, 0.055, 0.118, "left", 1);
  await delay(160);
};

const sheetsNameBoxGotoCdp = async (tabId, ref) => {
  await sheetsLeaveEdit(tabId);
  await delay(60);
  await focusNameBoxCdp(tabId);
  await delay(80);
  await cdpShortcut(tabId, "ctrl+a");
  await delay(50);
  await cdpShortcut(tabId, "backspace");
  await delay(40);
  await cdpInsertText(tabId, ref);
  await delay(80);
  await cdpShortcut(tabId, "enter");
  await delay(400);
  await sheetsLeaveEdit(tabId);
  await delay(60);
};

const sheetsNameBoxGoto = async (tabId, ref) => {
  await sheetsNameBoxGotoCdp(tabId, ref);
  return { via: "cdp" };
};

const sheetsScrollColIntoView = async (tabId, colIdx) => {
  if (colIdx <= colLetterToIndex("F")) return false;
  return execFirstFrame(tabId, (idx) => {
    const candidates = [...document.querySelectorAll("div")].filter(
      (e) => e.scrollWidth > e.clientWidth + 24 && e.clientWidth > 280
    );
    const el = candidates.sort((a, b) => b.clientWidth - a.clientWidth)[0];
    if (!el) return false;
    el.scrollLeft = Math.max(0, (idx - 2) * 105);
    return true;
  }, [colIdx]);
};

const sheetsCsvGridCacheClear = (tabId) => {
  for (const key of [...sheetsCsvGridCache.keys()]) {
    if (key.startsWith(`${tabId}:`)) sheetsCsvGridCache.delete(key);
  }
};

const sheetsCellValueFromExport = async (tabId, cellRef) => {
  const ref = normalizeCellRef(cellRef);
  const p = parseCellRef(ref);
  const pack = await sheetsCsvGridGet(tabId);
  const line = pack?.grid?.[p.row - 1] || [];
  return String(line[colLetterToIndex(p.col)] ?? "").trim();
};

const sheetsFocusGrid = async (tabId) => {
  await sheetsLeaveEdit(tabId);
  await delay(60);
  await cdpShortcut(tabId, "escape");
  await delay(80);
};

const sheetsPasteClipboardText = async (tabId, text, opts = {}) => {
  const clip = await execFirstFrame(tabId, async (t) => {
    try {
      await navigator.clipboard.writeText(String(t ?? ""));
      return { ok: true };
    } catch (e) {
      return { ok: false, error: String(e?.message || e) };
    }
  }, [text]);
  if (!clip?.ok) return { ok: false, write_via: "clipboard_paste", error: clip?.error };
  await sheetsFocusGrid(tabId);
  await cdpShortcut(tabId, "ctrl+v");
  await delay(opts.range ? 720 : 480);
  if (!opts.range) {
    await cdpShortcut(tabId, "enter");
    await delay(220);
  }
  return { ok: true, write_via: "clipboard_paste" };
};

const sheetsValueMatchLoose = (expected, got) => {
  const e = String(expected ?? "").trim();
  const g = String(got ?? "").trim();
  if (e === g) return true;
  if (!e && !g) return true;
  if (/^\d+$/.test(e) && /^\d+$/.test(g) && Number(e) === Number(g)) return true;
  return false;
};

const sheetsExpectedValues = (params) => {
  if (!Array.isArray(params.values)) return [];
  const rows = params.values;
  if (!rows.length) return [];
  return rows.length && Array.isArray(rows[0]) ? rows[0].map((c) => String(c ?? "")) : rows.map((c) => String(c ?? ""));
};

const sheetsVerifyRowExport = async (tabId, row, startCol, expected) => {
  const mismatches = [];
  for (let i = 0; i < expected.length; i += 1) {
    const exp = expected[i] ?? "";
    if (!exp) continue;
    const col = colIndexToLetter(colLetterToIndex(startCol) + i);
    const cell = `${col}${row}`;
    const got = await sheetsCellValueFromExport(tabId, cell);
    if (!sheetsValueMatchLoose(exp, got)) mismatches.push({ cell, expected: exp, got });
  }
  return { ok: mismatches.length === 0, mismatches };
};

const sheetsNormKey = (s) => String(s ?? "").trim().replace(/\s+/g, " ").toUpperCase();

const sheetsGoToCellVerified = async (tabId, tab, cellRef) => {
  const want = normalizeCellRef(cellRef);
  await sheetsGoToCell(tabId, tab, want);
  await delay(140);
  let nb = normalizeCellRef(await readNameBoxRef(tabId));
  if (nb !== want) {
    await maybeFocusTab(tabId, tab, { focus: true });
    await sheetsLeaveEdit(tabId);
    await delay(80);
    await sheetsNameBoxGoto(tabId, want);
    await delay(350);
    nb = normalizeCellRef(await readNameBoxRef(tabId));
  }
  if (nb !== want) {
    throw new Error(`goto ${want} failed (name box shows ${nb}, preventing write on wrong cell)`);
  }
  return { cell: want, name_box: nb };
};

const sheetsAssertWriteRow = async (tabId, tab, row, startCol, expectedKey) => {
  const key = String(expectedKey ?? "").trim();
  if (key) {
    const gotKey = await sheetsCellValueFromExport(tabId, `B${row}`);
    if (!gotKey) throw new Error(`row ${row}: column B is empty (cannot anchor to "${key}")`);
    if (sheetsNormKey(gotKey) !== sheetsNormKey(key)) {
      throw new Error(`row ${row} name mismatch: sheet B${row} is "${gotKey}", expected "${key}"`);
    }
  }
  await sheetsGoToCellVerified(tabId, tab, `${startCol}${row}`);
};

const sheetsWriteRowSequential = async (tabId, tab, row, startCol, expected) => {
  const writes = [];
  const wideFrom = colLetterToIndex("G");
  for (let i = 0; i < expected.length; i += 1) {
    const col = colIndexToLetter(colLetterToIndex(startCol) + i);
    const cell = `${col}${row}`;
    const val = String(expected[i] ?? "");
    if (!val) {
      writes.push({ cell, skipped: true });
      continue;
    }
    const verified = await sheetsGoToCellVerified(tabId, tab, cell);
    const p = parseCellRef(verified.cell);
    if (p.row !== row) {
      throw new Error(`Row mismatch before write: target is row ${row} (${cell}), but active cell is ${verified.cell}`);
    }
    const wide = colLetterToIndex(col) >= wideFrom;
    const w = wide
      ? await sheetsWriteFormulaBar(tabId, val)
      : await sheetsWriteActiveCell(tabId, val, "enter");
    await delay(wide ? 280 : 160);
    writes.push({ cell, write: w, wide });
  }
  return writes;
};

/** Goto cell then commit value via formula bar (works when G+ cols are off-screen). */
const sheetsWriteFormulaBar = async (tabId, value) => {
  const s = String(value ?? "");
  const pt = await execFirstFrame(tabId, formulaBarRectScript);
  if (pt?.x != null && pt?.y != null) await cdpMouseAt(tabId, pt.x, pt.y, "left", 1);
  else await cdpMouseAt(tabId, 0.42, 0.118, "left", 1);
  await delay(120);
  await cdpShortcut(tabId, "ctrl+a");
  await delay(50);
  await cdpShortcut(tabId, "backspace");
  await delay(40);
  if (s) {
    await cdpInsertText(tabId, s);
    await delay(60);
  }
  await cdpShortcut(tabId, "enter");
  await delay(380);
  return { write_via: "formula_bar_cdp" };
};

export const sheetsGoToCell = async (tabId, tab, cellRef) => {
  const ref = normalizeCellRef(cellRef);
  if (!CELL_REF_RE.test(ref)) throw new Error(`invalid cell ref: ${cellRef}`);
  const tabNow = await chrome.tabs.get(tabId);
  await maybeFocusTab(tabId, tabNow, { focus: true });
  await attachTab(tabId);
  await sendCdp(tabId, "Page.bringToFront", {});
  await sendCdp(tabId, "Input.setIgnoreInputEvents", { ignore: false });
  await sheetsLeaveEdit(tabId);
  await delay(100);
  const parsed = parseCellRef(ref);
  const colIdx = colLetterToIndex(parsed.col);
  await sheetsScrollColIntoView(tabId, colIdx);
  await delay(80);
  const nav = await sheetsNameBoxGoto(tabId, ref);
  const current = await readNameBoxRef(tabId);
  return { cell: ref, via: "namebox", nav_via: nav.via, name_box: current };
};

const formulaBarRectScript = () => {
  const sels = [
    "#t-formula-bar-input",
    "#formula-bar input",
    '[aria-label="Formula bar"]',
    '[aria-label="Bar formula"]',
    '[aria-label="Baris rumus"]',
    '[aria-label="Rumus"]',
  ];
  let el = null;
  for (const sel of sels) {
    el = document.querySelector(sel);
    if (el) break;
  }
  if (!el) return null;
  const r = el.getBoundingClientRect();
  if (r.width < 5 || r.height < 5) return null;
  return {
    x: (r.left + Math.min(60, r.width / 4)) / window.innerWidth,
    y: (r.top + r.height / 2) / window.innerHeight,
  };
};

const sheetsCommitEdit = async (tabId, value, commitKey = "tab") => {
  const s = String(value ?? "");
  await sheetsLeaveEdit(tabId);
  await delay(60);
  await cdpShortcut(tabId, "f2");
  await delay(120);
  await cdpShortcut(tabId, "ctrl+a");
  await delay(50);
  await cdpShortcut(tabId, "backspace");
  await delay(40);
  if (s) {
    await cdpInsertText(tabId, s);
    await delay(60);
  }
  await cdpShortcut(tabId, commitKey === "enter" ? "enter" : "tab");
  await delay(commitKey === "enter" ? 320 : 380);
  return { write_via: "f2_cdp_insertText", commit: commitKey };
};

/** Edit active cell; Tab moves selection right (pair write), Enter stays on cell (cell_set). */
const sheetsWriteActiveCell = (tabId, value, commitKey = "tab") => sheetsCommitEdit(tabId, value, commitKey);

/** Product cell then stock cell — explicit goto each (Tab after F2 is unreliable in Sheets). */
const sheetsWriteRowPair = async (tabId, tab, productCol, stockCol, row, product, stock) => {
  const productCell = `${productCol}${row}`;
  const stockCell = `${stockCol}${row}`;
  await sheetsGoToCell(tabId, tab, productCell);
  const w1 = await sheetsWriteActiveCell(tabId, product, "enter");
  await sheetsGoToCell(tabId, tab, stockCell);
  const w2 = await sheetsWriteActiveCell(tabId, stock, "enter");
  return { product: w1, stock: w2 };
};

const sheetsRowCache = new Map();

const sheetsRowCacheKey = (tabId, col) => `${tabId}:${String(col || "B").toUpperCase()}`;

const sheetsRowCacheSet = (tabId, col, row) => {
  if (Number.isFinite(row) && row >= 1) sheetsRowCache.set(sheetsRowCacheKey(tabId, col), Math.floor(row));
};

const sheetsReadActiveCell = async (tabId) => {
  await sheetsLeaveEdit(tabId);
  await delay(50);
  return String((await readFormulaBar(tabId)).value ?? "");
};

const sheetsColLetter = (params, key, fallback) => {
  const v = String(params[key] ?? fallback).trim().toUpperCase();
  return /^[A-Z]{1,3}$/.test(v) ? v : fallback;
};

/** One in-tab fetch (cookies + full location.href). Fast path for range_read. */
const sheetsFetchSpreadsheetCsv = (tabId) =>
  new Promise((resolve, reject) => {
    chrome.scripting.executeScript(
      {
        target: { tabId },
        world: "MAIN",
        func: async () => {
          const href = String(location.href || "");
          const idM = href.match(/\/spreadsheets\/d\/([a-zA-Z0-9-_]+)/);
          if (!idM) return { ok: false, reason: "not_spreadsheet" };
          const gidM = href.match(/[#?&]gid=(\d+)/);
          let gid = gidM ? gidM[1] : null;
          if (!gid) {
            const tab =
              document.querySelector(".docs-sheet-tab.docs-sheet-active-tab") ||
              document.querySelector(".docs-sheet-tab[aria-selected='true']");
            const fromDom = tab?.getAttribute("data-sheet-id") || tab?.getAttribute("data-gid");
            if (fromDom && /^\d+$/.test(fromDom)) gid = fromDom;
          }
          if (!gid) gid = "0";
          const id = idM[1];
          const urls = [
            `https://docs.google.com/spreadsheets/d/${id}/export?format=csv&gid=${gid}`,
            `https://docs.google.com/spreadsheets/d/${id}/gviz/tq?tqx=out:csv&gid=${gid}`,
          ];
          for (const u of urls) {
            try {
              const r = await fetch(u, { credentials: "include", redirect: "follow" });
              const t = await r.text();
              if (!r.ok) continue;
              const head = t.slice(0, 120).toLowerCase();
              if (head.includes("<!doctype") || head.includes("<html")) continue;
              if (!t.trim()) continue;
              const via = u.includes("/gviz/") ? "gviz_csv" : "export_csv";
              return { ok: true, text: t, gid, via };
            } catch {
              /* try next */
            }
          }
          return { ok: false, reason: "fetch_failed", gid };
        },
      },
      (results) => {
        if (chrome.runtime.lastError) reject(new Error(chrome.runtime.lastError.message));
        else resolve(results?.[0]?.result);
      }
    );
  });

const parseCsvText = (text) => {
  const out = [];
  let row = [];
  let cell = "";
  let inQ = false;
  const s = String(text || "").replace(/\r\n/g, "\n").replace(/\r/g, "\n");
  for (let i = 0; i < s.length; i += 1) {
    const ch = s[i];
    if (inQ) {
      if (ch === '"') {
        if (s[i + 1] === '"') {
          cell += '"';
          i += 1;
        } else inQ = false;
        continue;
      }
      cell += ch;
      continue;
    }
    if (ch === '"') {
      inQ = true;
      continue;
    }
    if (ch === ",") {
      row.push(cell);
      cell = "";
      continue;
    }
    if (ch === "\n") {
      row.push(cell);
      out.push(row);
      row = [];
      cell = "";
      continue;
    }
    cell += ch;
  }
  if (cell.length || row.length) {
    row.push(cell);
    out.push(row);
  }
  return out;
};

const sheetsRangeFromCsvGrid = (grid, productCol, stockCol, opts = {}) => {
  const wideCols = Number(opts.columns);
  const useWide = Number.isFinite(wideCols) && wideCols > 0;
  const startColWide = String(opts.start_col || "A").trim().toUpperCase();
  const keyCol = String(opts.key_col || productCol || "B").trim().toUpperCase();
  const pIdx = colLetterToIndex(productCol);
  const sIdx = colLetterToIndex(stockCol);
  const keyIdx = colLetterToIndex(keyCol);
  const startRow = Math.max(2, Number(opts.from_row) || 2);
  const toRow = Number(opts.to_row);
  const maxSheetRow =
    Number.isFinite(toRow) && toRow >= startRow
      ? Math.min(grid.length, toRow)
      : grid.length;
  const stopEmpty = Math.max(1, Number(opts.stop_empty) || 2);
  const rows = [];
  let lastFilled = Math.max(1, startRow - 1);
  let emptyStreak = 0;
  for (let sheetRow = startRow; sheetRow <= maxSheetRow; sheetRow += 1) {
    const line = grid[sheetRow - 1] || [];
    const keyVal = String(line[keyIdx] ?? "").trim();
    if (!keyVal) {
      if (lastFilled >= startRow) {
        emptyStreak += 1;
        if (emptyStreak >= stopEmpty) break;
      }
      continue;
    }
    lastFilled = sheetRow;
    emptyStreak = 0;
    if (useWide) {
      const startIdx = colLetterToIndex(startColWide);
      const cells = {};
      for (let c = 0; c < Math.min(26, wideCols); c += 1) {
        const col = colIndexToLetter(startIdx + c);
        cells[col] = String(line[colLetterToIndex(col)] ?? "").trim();
      }
      rows.push({ row: sheetRow, cells, key_col: keyCol, key: keyVal });
    } else {
      const product = String(line[pIdx] ?? "").trim();
      const stockVal = String(line[sIdx] ?? "").trim();
      rows.push({ row: sheetRow, product, stock: stockVal });
    }
  }
  return {
    rows,
    last_filled_row: lastFilled,
    next_row: lastFilled + 1,
    product_col: productCol,
    stock_col: stockCol,
    key_col: keyCol,
    start_col: useWide ? startColWide : undefined,
    columns: useWide ? Math.min(26, wideCols) : undefined,
  };
};

const sheetsCsvGridCache = new Map();
const SHEETS_CSV_CACHE_MS = 45_000;

const sheetsCsvGridGet = async (tabId) => {
  const tabNow = await chrome.tabs.get(tabId);
  sheetsRequireSpreadsheetTab(tabNow);
  const gid = tabNow.url?.match(/[#?&]gid=(\d+)/)?.[1] || "0";
  const key = `${tabId}:${gid}`;
  const hit = sheetsCsvGridCache.get(key);
  if (hit && Date.now() - hit.at < SHEETS_CSV_CACHE_MS) return hit;
  const fetched = await sheetsFetchSpreadsheetCsv(tabId);
  if (!fetched?.ok || !fetched.text) return null;
  const grid = parseCsvText(fetched.text);
  const pack = { grid, via: fetched.via || "export_csv", gid: fetched.gid, at: Date.now() };
  sheetsCsvGridCache.set(key, pack);
  return pack;
};

const sheetsRowReadViaExport = async (tabId, row, startCol, columns, cellArg) => {
  const pack = await sheetsCsvGridGet(tabId);
  if (!pack?.grid?.length || row < 1 || row > pack.grid.length) return null;
  const startIdx = colLetterToIndex(startCol);
  const line = pack.grid[row - 1] || [];
  const values = [];
  const cells = {};
  for (let c = 0; c < columns; c += 1) {
    const col = colIndexToLetter(startIdx + c);
    const v = String(line[colLetterToIndex(col)] ?? "").trim();
    values.push(v);
    cells[col] = v;
  }
  const out = {
    ok: true,
    mode: "export",
    read_via: pack.via,
    nav: "v27-row-export",
    row,
    start_col: startCol,
    columns,
    values,
    cells,
    formula_bar_found: false,
    grid_rows: pack.grid.length,
  };
  if (CELL_REF_RE.test(cellArg)) {
    out.cell = cellArg;
    out.value = values[0] ?? "";
  }
  return out;
};

const sheetsRangeReadViaExport = async (tabId, tab, productCol, stockCol, opts) => {
  const tabNow = tab || (await chrome.tabs.get(tabId));
  sheetsRequireSpreadsheetTab(tabNow);
  if (opts.row_align) await maybeFocusTab(tabId, tabNow, { focus: true });
  let fetched = null;
  const cached = await sheetsCsvGridGet(tabId);
  if (cached?.grid?.length) {
    fetched = { ok: true, text: null, via: cached.via, gid: cached.gid, grid: cached.grid };
  } else {
    fetched = await sheetsFetchSpreadsheetCsv(tabId);
  }
  if (!fetched?.ok && !fetched?.grid) {
    return {
      rows: [],
      ok: false,
      error: `csv_export_failed:${fetched?.reason || "unknown"}`,
      read_via: "export_failed",
      grid_rows: 0,
    };
  }
  const grid = fetched.grid?.length ? fetched.grid : parseCsvText(fetched.text || "");
  if (!grid.length) {
    return {
      rows: [],
      ok: false,
      error: "csv_export_empty",
      read_via: "export_empty",
      grid_rows: 0,
    };
  }
  const scan = sheetsRangeFromCsvGrid(grid, productCol, stockCol, opts);
  const csvRows = scan.rows.filter((r) => !/^product$/i.test(String(r.product ?? "").trim()));
  const maxRows = Math.min(Math.max(Number(opts.max_rows) || 0, 0), 50_000);
  const limitedRows = maxRows > 0 ? csvRows.slice(0, maxRows) : csvRows;
  const via = fetched.via || "export_csv";
  if (!opts.row_align) {
    return {
      rows: limitedRows,
      last_filled_row: scan.last_filled_row,
      next_row: scan.next_row,
      product_col: productCol,
      stock_col: stockCol,
      read_via: via,
      row_aligned: false,
      sheet_gid: fetched.gid,
      grid_rows: grid.length,
      row_count: limitedRows.length,
      truncated: maxRows > 0 && csvRows.length > maxRows,
    };
  }
  if (!limitedRows.length) {
    return {
      rows: [],
      last_filled_row: scan.last_filled_row,
      next_row: scan.next_row,
      product_col: productCol,
      stock_col: stockCol,
      read_via: via,
      row_aligned: false,
      sheet_gid: fetched.gid,
      grid_rows: grid.length,
      row_count: 0,
    };
  }
  await maybeFocusTab(tabId, tabNow, { focus: true });
  const sheetScan = await sheetsScanProductColRows(tabId, tabNow, productCol, opts);
  if (!sheetScan?.rows?.length) return null;
  const aligned = sheetsMergeCsvRowsWithSheetRows(limitedRows, sheetScan.rows);
  return {
    ...aligned,
    product_col: productCol,
    stock_col: stockCol,
    read_via: `${via}+sheet_rows`,
    row_aligned: true,
    sheet_gid: fetched.gid,
    grid_rows: grid.length,
    truncated: maxRows > 0 && csvRows.length > maxRows,
  };
};

const parseTsvText = (text) =>
  String(text || "")
    .replace(/\r\n/g, "\n")
    .replace(/\r/g, "\n")
    .split("\n")
    .filter((line) => line.length > 0)
    .map((line) => line.split("\t"));

/** Select B2:C{n}, Ctrl+C, clipboard.readText — interactive only (permission prompt). */
const sheetsNameBoxGotoRange = async (tabId, rangeRef) => {
  const ref = String(rangeRef || "").trim().toUpperCase();
  if (!ref.includes(":")) return sheetsNameBoxGoto(tabId, ref);
  const tabNow = await chrome.tabs.get(tabId);
  await maybeFocusTab(tabId, tabNow, { focus: true });
  await attachTab(tabId);
  await sendCdp(tabId, "Page.bringToFront", {});
  await sheetsLeaveEdit(tabId);
  await delay(80);
  const nav = await sheetsNameBoxGoto(tabId, ref);
  return { ref, nav };
};

const sheetsRangeReadViaClipboard = async (tabId, tab, productCol, stockCol, opts) => {
  const fromRow = Math.max(2, Number(opts.from_row) || 2);
  const toRow = Math.min(500, Math.max(fromRow, Number(opts.to_row) || 500));
  const rangeRef = `${productCol}${fromRow}:${stockCol}${toRow}`;
  await sheetsNameBoxGotoRange(tabId, rangeRef);
  await delay(120);
  await cdpShortcut(tabId, "ctrl+c");
  await delay(200);
  const clip = await execFirstFrame(tabId, async () => {
    try {
      const text = await navigator.clipboard.readText();
      return { ok: true, text: String(text ?? "") };
    } catch (e) {
      return { ok: false, error: String(e?.message || e) };
    }
  });
  if (!clip?.ok || !clip.text?.trim()) return null;
  const grid = parseTsvText(clip.text);
  if (!grid.length) return null;
  const colCount = Math.max(...grid.map((r) => r.length));
  if (colCount < 2) return null;
  const scan = sheetsRangeFromCsvGrid(grid, productCol, stockCol, {
    ...opts,
    from_row: fromRow,
    to_row: fromRow + grid.length,
  });
  return { ...scan, read_via: "clipboard_tsv" };
};

/** Scan product (+ optional stock) column; stop after [stopEmpty] empty rows below last data. */
const sheetsScanDataRows = async (tabId, tab, productCol, stockCol, opts = {}) => {
  const col = String(productCol || "B").trim().toUpperCase();
  const stock = String(stockCol || "C").trim().toUpperCase();
  const startRow = Math.max(2, Number(opts.from_row) || 2);
  const toRow = Number(opts.to_row);
  const maxRow =
    Number.isFinite(toRow) && toRow >= startRow
      ? Math.min(20_000, toRow)
      : Math.min(20_000, Math.max(startRow, 500));
  const stopEmpty = Math.max(1, Number(opts.stop_empty) || 2);
  const readStock = opts.read_stock !== false;
  const rows = [];
  let lastFilled = Math.max(1, startRow - 1);
  let emptyStreak = 0;
  for (let row = startRow; row <= maxRow; row += 1) {
    await sheetsGoToCell(tabId, tab, `${col}${row}`);
    const product = await sheetsReadActiveCell(tabId);
    if (!product.trim()) {
      if (lastFilled >= startRow) {
        emptyStreak += 1;
        if (emptyStreak >= stopEmpty) break;
      }
      continue;
    }
    lastFilled = row;
    emptyStreak = 0;
    let stockVal = "";
    if (readStock && stock) {
      await sheetsGoToCell(tabId, tab, `${stock}${row}`);
      stockVal = await sheetsReadActiveCell(tabId);
    }
    rows.push({ row, product, stock: stockVal });
  }
  sheetsRowCacheSet(tabId, col, lastFilled);
  return { rows, last_filled_row: lastFilled, next_row: lastFilled + 1, product_col: col, stock_col: stock };
};

/** CDP scan product column only (name box + formula bar per row). */
const sheetsScanProductColRows = async (tabId, tab, productCol, opts = {}) =>
  sheetsScanDataRows(tabId, tab, productCol, null, { ...opts, read_stock: false });

/** Align CSV export rows with physical sheet rows (product column CDP scan). */
const sheetsMergeCsvRowsWithSheetRows = (csvRows, sheetRows) => {
  const csv = Array.isArray(csvRows) ? csvRows : [];
  const sheet = Array.isArray(sheetRows) ? sheetRows : [];
  const stockOf = (r) => String(r?.stock ?? "");
  let merged;
  if (csv.length === sheet.length) {
    merged = csv.map((c, i) => ({
      row: sheet[i].row,
      product: c.product,
      stock: stockOf(c),
    }));
  } else {
    const pool = sheet.map((s, i) => ({ ...s, _i: i }));
    const used = new Set();
    merged = [];
    for (const c of csv) {
      const prod = String(c.product ?? "").trim();
      let pick = pool.find(
        (s) => !used.has(s._i) && String(s.product ?? "").trim() === prod
      );
      if (!pick) pick = pool.find((s) => !used.has(s._i));
      if (pick) {
        used.add(pick._i);
        merged.push({ row: pick.row, product: c.product, stock: stockOf(c) });
      } else {
        merged.push({ row: c.row, product: c.product, stock: stockOf(c) });
      }
    }
  }
  const lastFilled = merged.reduce((m, r) => (r.row > m ? r.row : m), 1);
  return { rows: merged, last_filled_row: lastFilled, next_row: lastFilled + 1 };
};

/** Append row after last filled cell in product column (cached per tab when possible). */
const sheetsFindNextEmptyRow = async (tabId, tab, productCol, startRow = 2) => {
  const col = String(productCol || "B").trim().toUpperCase();
  const cached = sheetsRowCache.get(sheetsRowCacheKey(tabId, col));
  if (cached != null && cached >= 2) {
    const guess = cached + 1;
    await sheetsGoToCell(tabId, tab, `${col}${guess}`);
    const v = await sheetsReadActiveCell(tabId);
    if (!v.trim()) return { row: guess, col, row_cache: true };
  }
  const scan = await sheetsScanDataRows(tabId, tab, col, null, {
    from_row: cached != null && cached >= 2 ? cached : startRow,
    read_stock: false,
    stop_empty: 2,
  });
  return { row: scan.next_row, col, row_cache: false };
};

const focusNameBox = (tabId) =>
  new Promise((resolve, reject) => {
    chrome.scripting.executeScript(
      {
        target: { tabId },
        func: () => {
          const el =
            document.querySelector("#docs-name-box input") ||
            document.querySelector('input[aria-label="Name box"]') ||
            document.querySelector("#t-name-box");
          if (!el) return false;
          el.focus();
          el.select();
          return true;
        },
      },
      (results) => {
        if (chrome.runtime.lastError) {
          reject(new Error(chrome.runtime.lastError.message));
          return;
        }
        resolve(!!results?.[0]?.result);
      }
    );
  });

const delay = (ms) => new Promise((r) => setTimeout(r, ms));

const sheetsQueues = new Map();

/** Serialize Sheets CDP ops per tab (parallel MCP tool_exec must not interleave). */
const sheetsWithQueue = (tabId, fn) => {
  const prev = sheetsQueues.get(tabId) || Promise.resolve();
  const next = prev.then(() => fn());
  sheetsQueues.set(tabId, next.catch(() => {}));
  return next;
};

const cdpInsertText = async (tabId, text) => {
  await attachTab(tabId);
  await sendCdp(tabId, "Input.insertText", { text: String(text ?? "") });
};

const sheetsLeaveEdit = async (tabId) => {
  await cdpShortcut(tabId, "escape");
  await delay(120);
};

const keyDefForChar = (ch) => {
  if (ch >= "a" && ch <= "z") {
    const u = ch.toUpperCase();
    return {
      key: ch,
      code: `Key${u}`,
      windowsVirtualKeyCode: u.charCodeAt(0),
      text: ch,
      modifiers: 0,
    };
  }
  if (ch >= "A" && ch <= "Z") {
    return {
      key: ch,
      code: `Key${ch}`,
      windowsVirtualKeyCode: ch.charCodeAt(0),
      text: ch,
      modifiers: 8,
    };
  }
  if (ch >= "0" && ch <= "9") {
    return {
      key: ch,
      code: `Digit${ch}`,
      windowsVirtualKeyCode: ch.charCodeAt(0),
      text: ch,
      modifiers: 0,
    };
  }
  if (ch === " ") {
    return {
      key: " ",
      code: "Space",
      windowsVirtualKeyCode: 32,
      text: " ",
      modifiers: 0,
    };
  }
  return { key: ch, code: "", windowsVirtualKeyCode: 0, text: ch, modifiers: 0 };
};

const cdpTypeChars = async (tabId, text) => {
  const s = String(text || "");
  for (const ch of s) {
    const d = keyDefForChar(ch);
    const base = {
      key: d.key,
      code: d.code || undefined,
      windowsVirtualKeyCode: d.windowsVirtualKeyCode || undefined,
      nativeVirtualKeyCode: d.windowsVirtualKeyCode || undefined,
      text: d.text,
      modifiers: d.modifiers,
    };
    await sendCdp(tabId, "Input.dispatchKeyEvent", { type: "keyDown", ...base });
    if (d.text) {
      await sendCdp(tabId, "Input.dispatchKeyEvent", {
        type: "char",
        text: d.text,
        modifiers: d.modifiers,
      });
    }
    await sendCdp(tabId, "Input.dispatchKeyEvent", { type: "keyUp", ...base });
  }
};

const cdpTypeText = async (tabId, text, tabUrl) => {
  const s = String(text || "");
  if (!s) return;
  const sheet = isSpreadsheetUrl(tabUrl || "");
  if (sheet && CELL_REF_RE.test(s.trim())) {
    await focusNameBox(tabId);
    await cdpTypeChars(tabId, s.trim());
    return;
  }
  if (sheet) {
    await cdpTypeChars(tabId, s);
    return;
  }
  await sendCdp(tabId, "Input.insertText", { text: s });
};

const parseShortcut = (combo) => {
  const parts = String(combo || "")
    .trim()
    .toLowerCase()
    .split("+")
    .map((s) => s.trim())
    .filter(Boolean);
  const keyToken = parts[parts.length - 1] || "";
  const mods = {
    ctrl: parts.some((p) => p === "ctrl" || p === "control"),
    alt: parts.includes("alt"),
    shift: parts.includes("shift"),
    meta: parts.some((p) => p === "meta" || p === "cmd" || p === "win"),
  };
  return { keyToken, mods };
};

const cdpShortcut = async (tabId, combo) => {
  const { keyToken, mods } = parseShortcut(combo);
  const def = KEY_DEFS[keyToken];
  if (def) {
    await cdpKeyTap(tabId, def, mods);
    return;
  }
  if (keyToken.length === 1) {
    const ch = keyToken;
    const u = ch.toUpperCase();
    const modifiers = modifierMask(mods);
    const hasMod = modifiers !== 0;
    await sendCdp(tabId, "Input.dispatchKeyEvent", {
      type: "keyDown",
      key: ch,
      code: `Key${u}`,
      windowsVirtualKeyCode: u.charCodeAt(0),
      nativeVirtualKeyCode: u.charCodeAt(0),
      modifiers,
      ...(hasMod ? {} : { text: ch }),
    });
    if (!hasMod) {
      await sendCdp(tabId, "Input.dispatchKeyEvent", { type: "char", text: ch, modifiers });
    }
    await sendCdp(tabId, "Input.dispatchKeyEvent", {
      type: "keyUp",
      key: ch,
      code: `Key${u}`,
      windowsVirtualKeyCode: u.charCodeAt(0),
      nativeVirtualKeyCode: u.charCodeAt(0),
      modifiers,
    });
  }
};

const maybeFocusTab = async (tabId, tab, params) => {
  if (params.focus === false) return;
  if (params.focus !== true) {
    const win = await chrome.windows.get(tab.windowId);
    if (tab.active && win.focused) return;
  }
  await chrome.windows.update(tab.windowId, { focused: true });
  await chrome.tabs.update(tabId, { active: true });
};

export const cdpInject = async (tabId, tab, params) => {
  await maybeFocusTab(tabId, tab, params);
  const eventType = params.event_type;
  const btn = Number(params.button) || 0;
  const button = mouseButtonName(btn);

  switch (eventType) {
    case "mouse_move": {
      const { w, h } = await tabViewport(tabId);
      const x = Math.round(clamp01(params.x) * w);
      const y = Math.round(clamp01(params.y) * h);
      await sendCdp(tabId, "Input.dispatchMouseEvent", { type: "mouseMoved", x, y });
      break;
    }
    case "mouse_down": {
      const { x, y } = await cdpPointerXY(tabId, params.x, params.y);
      await sendCdp(tabId, "Input.dispatchMouseEvent", { type: "mouseMoved", x, y });
      await sendCdp(tabId, "Input.dispatchMouseEvent", {
        type: "mousePressed",
        x,
        y,
        button,
        clickCount: 1,
      });
      break;
    }
    case "mouse_up": {
      const { x, y } = await cdpPointerXY(tabId, params.x, params.y);
      await sendCdp(tabId, "Input.dispatchMouseEvent", {
        type: "mouseReleased",
        x,
        y,
        button,
        clickCount: 1,
      });
      break;
    }
    case "mouse_click":
      await cdpMouseAt(tabId, params.x, params.y, button, 1);
      break;
    case "double_click":
      await cdpMouseAt(tabId, params.x, params.y, button, 2);
      break;
    case "wheel": {
      const { w, h } = await tabViewport(tabId);
      const x = Math.round(clamp01(params.x) * w);
      const y = Math.round(clamp01(params.y) * h);
      await sendCdp(tabId, "Input.dispatchMouseEvent", {
        type: "mouseWheel",
        x,
        y,
        deltaX: Number(params.delta_x) || 0,
        deltaY: Number(params.delta_y) || 0,
      });
      break;
    }
    case "type_text":
      await cdpTypeText(tabId, params.text, tab.url || "");
      break;
    case "shortcut":
    case "hotkey":
    case "key_combo":
      await cdpShortcut(tabId, params.text);
      break;
    case "key_down":
    case "key_up": {
      const token = String(params.text || "").toLowerCase();
      const def = KEY_DEFS[token];
      if (!def) break;
      const type = eventType === "key_down" ? "keyDown" : "keyUp";
      await sendCdp(tabId, "Input.dispatchKeyEvent", {
        type,
        key: def.key,
        code: def.code,
        windowsVirtualKeyCode: def.windowsVirtualKeyCode,
        nativeVirtualKeyCode: def.windowsVirtualKeyCode,
      });
      break;
    }
    default:
      throw new Error(`unknown input event_type: ${eventType}`);
  }
  return { ok: true, mode: "cdp" };
};

/** One-shot Sheets row append (name box -> product -> stock). */
export const sheetsAppendRow = (tabId, tab, params = {}) =>
  sheetsWithQueue(tabId, async () => {
    const tabNow = await chrome.tabs.get(tabId);
    sheetsRequireSpreadsheetTab(tabNow);
    const product = String(params.product || "").trim();
    const stock = String(params.stock ?? "").trim();
    if (!product) throw new Error("product required");
    const productCol = sheetsColLetter(params, "product_col", "B");
    const stockCol = sheetsColLetter(params, "stock_col", "C");
    const rowParam = Number(params.row);
    let row;
    let row_auto = false;
    if (Number.isFinite(rowParam) && rowParam >= 1) {
      row = Math.floor(rowParam);
    } else {
      const found = await sheetsFindNextEmptyRow(tabId, tabNow, productCol, 2);
      row = found.row;
      row_auto = true;
    }
    const productCell = `${productCol}${row}`;
    const stockCell = `${stockCol}${row}`;
    const writes = await sheetsWriteRowPair(tabId, tabNow, productCol, stockCol, row, product, stock);
    await sheetsGoToCell(tabId, tabNow, stockCell);
    const gotStock = await sheetsReadActiveCell(tabId);
    const ok =
      writes.product?.dom_ok !== false &&
      writes.stock?.dom_ok !== false &&
      gotStock === stock;
    if (!ok) {
      return {
        ok: false,
        error: `append_row verify failed row ${row}: expected ${stockCell}="${stock}", got "${gotStock}"`,
      };
    }
    sheetsRowCacheSet(tabId, productCol, row);
    const summary = `Row ${row}: ${productCell}="${product}", ${stockCell}="${stock}"`;
    return { ok: true, summary, row, row_auto, nav: "v19" };
  });

const sheetsParamTruthy = (params, key) =>
  params[key] === true || params[key] === 1 || String(params[key] || "").toLowerCase() === "true";

export const sheetsCellSet = (tabId, tab, params = {}) =>
  sheetsWithQueue(tabId, async () => {
    const tabNow = await chrome.tabs.get(tabId);
    sheetsRequireSpreadsheetTab(tabNow);
    const cell = String(params.cell || params.cell_ref || "").trim().toUpperCase();
    const value = String(params.value ?? "");
    if (!CELL_REF_RE.test(cell)) throw new Error("cell required (e.g. A7)");
    const writeMode = String(params.write_mode || "cell").toLowerCase();
    const doVerify = sheetsParamTruthy(params, "verify");
    await sheetsGoToCell(tabId, tab, cell);
    let write;
    if (writeMode === "paste") write = await sheetsPasteClipboardText(tabId, value);
    else if (writeMode === "formula_bar" || writeMode === "formula")
      write = await sheetsWriteFormulaBar(tabId, value);
    else write = await sheetsWriteActiveCell(tabId, value, "enter");
    sheetsCsvGridCacheClear(tabId);
    if (!doVerify) {
      return {
        ok: true,
        summary: `${cell} set to "${value}"`,
        write,
        nav: "v32-enter-commit",
        verify: false,
      };
    }
    await delay(280);
    const gotBar = await sheetsReadActiveCell(tabId);
    let got = await sheetsCellValueFromExport(tabId, cell);
    if (!got && gotBar) got = gotBar;
    const ok = got === value || gotBar === value;
    if (ok) {
      return {
        ok: true,
        summary: `${cell} set to "${value}"`,
        write,
        nav: "v32-enter-commit",
        verify_via: gotBar === value ? "formula_bar" : "export_csv",
      };
    }
    return {
      ok: false,
      error: `Could not set ${cell} to "${value}" (sheet shows "${gotBar}"; export "${got}")`,
      write,
      nav: "v32-enter-commit",
    };
  });

const sheetsTsvFromValues = (params) => {
  const raw = String(params.tsv ?? "").trimEnd();
  if (raw) return raw;
  if (!Array.isArray(params.values)) return "";
  const rows = params.values;
  if (!rows.length) return "";
  return rows.length && Array.isArray(rows[0])
    ? rows.map((row) => row.map((c) => String(c ?? "")).join("\t")).join("\n")
    : rows.map((c) => String(c ?? "")).join("\t");
};

/** Paste TSV into a selected range (e.g. G3:L3). Verifies export; falls back to per-cell F2. */
export const sheetsRangeSet = (tabId, tab, params = {}) =>
  sheetsWithQueue(tabId, async () => {
    const tabNow = await chrome.tabs.get(tabId);
    sheetsRequireSpreadsheetTab(tabNow);
    const range = String(params.range || "").trim().toUpperCase();
    if (!range.includes(":")) throw new Error("range required (e.g. G3:L3)");
    const tsv = sheetsTsvFromValues(params);
    if (!tsv) throw new Error("tsv or values required");
    const parsed = range.split(":");
    const startRef = parsed[0];
    const row = parseCellRef(startRef).row;
    const startCol = parseCellRef(startRef).col;
    const expected = sheetsExpectedValues(params);
    const endCol = parseCellRef(parsed[1] || startRef).col;
    const expectedKey = params.key ?? params.expected_key ?? params.name ?? "";
    const skipVerify = sheetsParamTruthy(params, "skip_verify");
    const runVerify = !skipVerify && expected.length > 0;

    if (expectedKey) await sheetsAssertWriteRow(tabId, tabNow, row, startCol, expectedKey);

    const attemptPaste = async () => {
      await sheetsScrollColIntoView(tabId, colLetterToIndex(startCol));
      await sheetsNameBoxGotoRange(tabId, range);
      await delay(200);
      await sheetsFocusGrid(tabId);
      return sheetsPasteClipboardText(tabId, tsv, { range: true });
    };

    let write = await attemptPaste();
    if (!write?.ok) {
      return { ok: false, error: write?.error || "paste failed", range, write, nav: "v35-row-anchor" };
    }
    sheetsCsvGridCacheClear(tabId);
    await delay(runVerify ? 520 : 200);

    let verify = runVerify ? await sheetsVerifyRowExport(tabId, row, startCol, expected) : { ok: true, mismatches: [] };
    if (runVerify && !verify.ok) {
      write = await attemptPaste();
      sheetsCsvGridCacheClear(tabId);
      await delay(520);
      verify = await sheetsVerifyRowExport(tabId, row, startCol, expected);
    }
    if (runVerify && !verify.ok) {
      const seq = await sheetsWriteRowSequential(tabId, tabNow, row, startCol, expected);
      sheetsCsvGridCacheClear(tabId);
      await delay(480);
      verify = await sheetsVerifyRowExport(tabId, row, startCol, expected);
      if (!verify.ok) {
        const miss = verify.mismatches?.slice(0, 3) || [];
        return {
          ok: false,
          error: `row paste incomplete for ${range} (${miss.map((m) => `${m.cell} expected "${m.expected}" got "${m.got}"`).join("; ")})`,
          range,
          write: { paste: write, sequential: seq },
          mismatches: verify.mismatches,
          nav: "v35-row-anchor",
        };
      }
      return {
        ok: true,
        summary: `${range} filled (sequential fallback)`,
        range,
        write: { paste: write, sequential: seq },
        verify_via: "export_csv",
        row,
        key: expectedKey || undefined,
        nav: "v35-row-anchor",
      };
    }

    return {
      ok: true,
      summary: `${range} filled`,
      range,
      write,
      verify_via: runVerify ? "export_csv" : "none",
      row,
      key: expectedKey || undefined,
      nav: "v35-row-anchor",
    };
  });

/** One row G{n}:L{n} — sequential cell writes only (no clipboard paste). */
export const sheetsRowSet = (tabId, tab, params = {}) =>
  sheetsWithQueue(tabId, async () => {
    const tabNow = await chrome.tabs.get(tabId);
    sheetsRequireSpreadsheetTab(tabNow);
    const row = Math.floor(Number(params.row));
    if (!Number.isFinite(row) || row < 1) throw new Error("row required (e.g. 4)");
    const startCol = sheetsColLetter(params, "start_col", "G");
    const expected = sheetsExpectedValues(params);
    if (!expected.length) throw new Error("values required");
    const defaultEndCol = colIndexToLetter(colLetterToIndex(startCol) + expected.length - 1);
    const endCol = params.end_col ? sheetsColLetter(params, "end_col", defaultEndCol) : defaultEndCol;
    const range = `${startCol}${row}:${endCol}${row}`;
    const expectedKey =
      params.key ?? params.expected_key ?? params.name ?? params.key_name ?? params.expected_name ?? "";
    await sheetsAssertWriteRow(tabId, tabNow, row, startCol, expectedKey);
    const write = await sheetsWriteRowSequential(tabId, tabNow, row, startCol, expected);
    sheetsCsvGridCacheClear(tabId);
    await delay(480);
    const verify = await sheetsVerifyRowExport(tabId, row, startCol, expected);
    if (!verify.ok) {
      const miss = verify.mismatches?.slice(0, 4) || [];
      return {
        ok: false,
        error: `row ${row} write incomplete (${miss.map((m) => `${m.cell} expected "${m.expected}" got "${m.got}"`).join("; ")})`,
        range,
        row,
        key: expectedKey,
        mismatches: verify.mismatches,
        write,
        nav: "v36-sequential-row",
      };
    }
    return {
      ok: true,
      summary: `row ${row} ${range} filled`,
      range,
      row,
      key: expectedKey,
      write,
      verify_via: "export_csv",
      nav: "v36-sequential-row",
    };
  });

/** Read product/stock slice in one op; returns next_row for append_row (pass row= to skip auto-scan). */
export const sheetsRangeRead = (tabId, tab, params = {}) =>
  sheetsWithQueue(tabId, async () => {
    const tabNow = await chrome.tabs.get(tabId);
    sheetsRequireSpreadsheetTab(tabNow);
    const productCol = sheetsColLetter(params, "product_col", "B");
    const stockCol = sheetsColLetter(params, "stock_col", "C");
    const fromRow = Math.max(2, Number(params.from_row) || 2);
    const toRow = Number(params.to_row);
    const maxRows = Number(params.max_rows ?? params.limit);
    const columns = Number(params.columns);
    const startCol = String(params.start_col || "A").trim().toUpperCase();
    const keyCol = params.key_col ? sheetsColLetter(params, "key_col", productCol) : productCol;
    const scanOpts = {
      from_row: fromRow,
      to_row: Number.isFinite(toRow) && toRow >= fromRow ? toRow : undefined,
      max_rows: Number.isFinite(maxRows) && maxRows > 0 ? maxRows : undefined,
      columns: Number.isFinite(columns) && columns > 0 ? columns : undefined,
      start_col: startCol,
      key_col: keyCol,
      read_stock: true,
      stop_empty: 2,
      row_align:
        params.row_align === true ||
        params.row_align === 1 ||
        String(params.row_align || "").toLowerCase() === "true",
    };
    const readMode = String(params.read_mode || params.scan_mode || "auto").toLowerCase();
    const preferExport = readMode === "export" || readMode === "auto";
    let scan = null;
    if (readMode !== "cdp") {
      const exportOpts = { ...scanOpts };
      if (preferExport) exportOpts.row_align = false;
      if (readMode === "align") exportOpts.row_align = true;
      try {
        scan = await sheetsRangeReadViaExport(tabId, tabNow, productCol, stockCol, exportOpts);
      } catch (e) {
        scan = preferExport
          ? { rows: [], ok: false, error: String(e?.message || e), read_via: "export_error" }
          : null;
      }
      if ((!scan || scan.ok === false) && readMode === "clipboard") {
        try {
          scan = await sheetsRangeReadViaClipboard(tabId, tabNow, productCol, stockCol, scanOpts);
        } catch {
          scan = null;
        }
      }
    }
    if (!scan || (scan.ok === false && preferExport)) {
      if (preferExport && scan?.error) {
        throw new Error(
          `${scan.error} (read_mode=${readMode}; no per-row CDP fallback). Open the spreadsheet tab and retry.`
        );
      }
      if (readMode === "cdp" || readMode === "align") {
        scan = await sheetsScanDataRows(tabId, tabNow, productCol, stockCol, scanOpts);
        scan.read_via = "cdp_scan";
      } else if (!scan) {
        throw new Error("sheets range_read failed; use read_mode=cdp only for small ranges");
      }
    }
    const lines = scan.rows.map((r) =>
      r.cells ? `${r.row}:${Object.values(r.cells).join("|")}` : `${r.row}:${r.product}/${r.stock}`
    );
    const via = scan.read_via || "cdp_scan";
    const summary = scan.rows.length
      ? `${scan.rows.length} row(s); next_row=${scan.next_row}; via=${via}. ${lines.slice(-8).join("; ")}`
      : `empty from row ${fromRow}; next_row=${scan.next_row}; via=${via}`;
    return {
      ok: true,
      nav: "v28-range-only",
      ...scan,
      summary,
      row_count: scan.rows?.length ?? 0,
    };
  });

/** @deprecated use sheetsRowRead with cell= — kept for legacy IPC op sheets.cell_read */
export const sheetsCellRead = (tabId, tab, params = {}) => {
  const cell = String(params.cell || params.cell_ref || "").trim().toUpperCase();
  if (!CELL_REF_RE.test(cell)) throw new Error("cell required (e.g. B3)");
  return sheetsRowRead(tabId, tab, { tab_id: params.tab_id, cell, columns: 1 });
};

export const sheetsRowRead = (tabId, tab, params = {}) =>
  sheetsWithQueue(tabId, async () => {
    const tabNow = await chrome.tabs.get(tabId);
    sheetsRequireSpreadsheetTab(tabNow);
    const cellArg = String(params.cell || params.cell_ref || "").trim().toUpperCase();
    let row;
    let startCol;
    let columns;
    if (CELL_REF_RE.test(cellArg)) {
      const p = parseCellRef(cellArg);
      row = p.row;
      startCol = p.col;
      columns = Math.min(26, Math.max(1, Number(params.columns) || 1));
    } else {
      row = Math.max(1, Number(params.row) || 0);
      if (row < 1) throw new Error("row (>=1) or cell (e.g. B7) required");
      startCol = String(params.start_col || "A").trim().toUpperCase();
      if (!/^[A-Z]{1,3}$/.test(startCol)) startCol = "A";
      columns = Math.min(26, Math.max(1, Number(params.columns) || 6));
    }
    const readMode = String(params.read_mode || params.scan_mode || "auto").toLowerCase();
    if (readMode !== "cdp") {
      const exported = await sheetsRowReadViaExport(tabId, row, startCol, columns, cellArg);
      if (exported) return exported;
      if (readMode === "export") {
        throw new Error("row_read CSV export failed (no cdp fallback in export mode)");
      }
    }
    const startIdx = colLetterToIndex(startCol);
    const values = [];
    const cells = {};
    for (let c = 0; c < columns; c += 1) {
      const col = colIndexToLetter(startIdx + c);
      const cellRef = `${col}${row}`;
      await sheetsGoToCell(tabId, tabNow, cellRef);
      await sheetsLeaveEdit(tabId);
      await delay(80);
      const bar = await readFormulaBar(tabId);
      values.push(bar.value);
      cells[col] = bar.value;
    }
    const out = {
      ok: true,
      mode: "cdp",
      nav: "v12",
      row,
      start_col: startCol,
      columns,
      values,
      cells,
      formula_bar_found: true,
    };
    if (CELL_REF_RE.test(cellArg)) {
      out.cell = cellArg;
      out.value = values[0] ?? "";
    }
    return out;
  });