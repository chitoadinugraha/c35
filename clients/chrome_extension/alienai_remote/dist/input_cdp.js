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
  enter: { key: "Enter", code: "Enter", windowsVirtualKeyCode: 13 },
  tab: { key: "Tab", code: "Tab", windowsVirtualKeyCode: 9 },
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
  };
  await sendCdp(tabId, "Input.dispatchKeyEvent", { type: "keyDown", ...base });
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
    let best = { value: "", found: false };
    const pick = (el) => {
      if (!el) return;
      const raw = el.value ?? el.textContent ?? el.innerText ?? "";
      const v = String(raw).trim();
      if (v.length >= best.value.length) best = { value: v, found: true };
    };
    const sels = [
      "#t-formula-bar-input",
      "#formula-bar input",
      '[aria-label="Formula bar"]',
      '[aria-label="Bar formula"]',
      '[aria-label="Baris rumus"]',
      '[aria-label="Rumus"]',
    ];
    for (const sel of sels) {
      for (const el of document.querySelectorAll(sel)) pick(el);
    }
    for (const el of document.querySelectorAll('[role="textbox"], [contenteditable="true"]')) {
      const a = (el.getAttribute("aria-label") || "").toLowerCase();
      if (a.includes("formula") || a.includes("rumus")) pick(el);
    }
    return best.found ? best : null;
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

const setNameBoxRefDom = async (tabId, ref) => {
  const hit = await execFirstFrame(tabId, (cellRef) => {
    const sels = [
      "#docs-name-box input",
      "input#t-name-box",
      'input[aria-label="Name box"]',
      'input[aria-label="Kotak nama"]',
      "#t-name-box",
    ];
    let el = null;
    for (const sel of sels) {
      el = document.querySelector(sel);
      if (el) break;
    }
    if (!el) return null;
    el.focus();
    if (el.tagName === "INPUT") {
      el.select();
      const setter = Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype, "value")?.set;
      if (setter) setter.call(el, cellRef);
      else el.value = cellRef;
      el.dispatchEvent(new Event("input", { bubbles: true }));
      el.dispatchEvent(new Event("change", { bubbles: true }));
    } else {
      el.textContent = cellRef;
      el.dispatchEvent(new Event("input", { bubbles: true }));
    }
    return { ok: true };
  }, [ref]);
  return hit || { ok: false, error: "name box not found" };
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
  await focusNameBoxCdp(tabId);
  await cdpShortcut(tabId, "ctrl+a");
  await delay(60);
  await cdpInsertText(tabId, ref);
  await delay(80);
  await cdpShortcut(tabId, "enter");
  await delay(450);
  await sheetsLeaveEdit(tabId);
};

const sheetsNameBoxGoto = async (tabId, ref) => {
  let set = await setNameBoxRefDom(tabId, ref);
  if (!set?.ok) {
    await focusNameBoxCdp(tabId);
    await delay(100);
    set = await setNameBoxRefDom(tabId, ref);
  }
  if (set?.ok) {
    await delay(80);
    await cdpShortcut(tabId, "enter");
    await delay(450);
    await sheetsLeaveEdit(tabId);
    return { via: "dom" };
  }
  await sheetsNameBoxGotoCdp(tabId, ref);
  return { via: "cdp" };
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
  const nav = await sheetsNameBoxGoto(tabId, ref);
  const current = await readNameBoxRef(tabId);
  return { cell: ref, via: "namebox", nav_via: nav.via, name_box: current };
};

const sheetsInsertTextDom = async (tabId, text) => {
  const ok = await execFirstFrame(tabId, (t) => {
    const s = String(t ?? "");
    const el = document.activeElement;
    if (!el) return null;
    el.focus();
    if (typeof document.execCommand === "function" && document.execCommand("insertText", false, s)) return true;
    if (el.isContentEditable) {
      el.textContent = s;
      el.dispatchEvent(new InputEvent("input", { bubbles: true, data: s, inputType: "insertText" }));
      return true;
    }
    return null;
  }, [text]);
  return ok === true;
};

const formulaBarRectScript = () => {
  const sels = [
    "#t-formula-bar-input",
    "#formula-bar input",
    '[aria-label="Formula bar"]',
    '[aria-label="Bar formula"]',
  ];
  let el = null;
  for (const sel of sels) {
    el = document.querySelector(sel);
    if (el) break;
  }
  if (!el) return null;
  const r = el.getBoundingClientRect();
  return {
    x: (r.left + r.width / 2) / window.innerWidth,
    y: (r.top + r.height / 2) / window.innerHeight,
  };
};

const setFormulaBarDom = async (tabId, value) => {
  const hit = await execFirstFrame(tabId, (val) => {
    const sels = [
      "#t-formula-bar-input",
      "#formula-bar input",
      '[aria-label="Formula bar"]',
      '[aria-label="Bar formula"]',
    ];
    let el = null;
    for (const sel of sels) {
      el = document.querySelector(sel);
      if (el) break;
    }
    if (!el) return null;
    el.focus();
    const text = String(val ?? "");
    if (el.tagName === "INPUT" || el.tagName === "TEXTAREA") {
      const proto = el.tagName === "TEXTAREA" ? window.HTMLTextAreaElement.prototype : window.HTMLInputElement.prototype;
      const setter = Object.getOwnPropertyDescriptor(proto, "value")?.set;
      if (setter) setter.call(el, text);
      else el.value = text;
    } else if (el.isContentEditable) {
      el.textContent = text;
    } else return null;
    el.dispatchEvent(new Event("input", { bubbles: true }));
    el.dispatchEvent(new Event("change", { bubbles: true }));
    return { ok: true, len: text.length };
  }, [value]);
  return hit?.ok === true;
};

const sheetsCommitEdit = async (tabId, value) => {
  const s = String(value ?? "");
  await sheetsLeaveEdit(tabId);
  await delay(120);
  await cdpShortcut(tabId, "f2");
  await delay(280);
  if (s) {
    await cdpInsertText(tabId, s);
  } else {
    await cdpShortcut(tabId, "delete");
  }
  await delay(120);
  await cdpShortcut(tabId, "tab");
  await delay(800);
  return { write_via: "f2_insert_tab" };
};

/** Edit active cell: F2 → insertText → Tab commit. */
const sheetsWriteActiveCell = async (tabId, value) => sheetsCommitEdit(tabId, value);

/** Product col then stock col — two F2+insertText+Tab commits (same path as cell_set). */
const sheetsWriteRowPair = async (tabId, tab, productCol, stockCol, row, product, stock) => {
  const productCell = `${productCol}${row}`;
  const stockCell = `${stockCol}${row}`;
  await sheetsGoToCell(tabId, tab, productCell);
  await sheetsWriteActiveCell(tabId, product);
  await sheetsGoToCell(tabId, tab, stockCell);
  await sheetsWriteActiveCell(tabId, stock);
};

const sheetsColLetter = (params, key, fallback) => {
  const v = String(params[key] ?? fallback).trim().toUpperCase();
  return /^[A-Z]{1,3}$/.test(v) ? v : fallback;
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
    const modifiers = modifierMask(mods);
    await sendCdp(tabId, "Input.dispatchKeyEvent", {
      type: "keyDown",
      key: ch,
      text: ch,
      modifiers,
    });
    await sendCdp(tabId, "Input.dispatchKeyEvent", { type: "char", text: ch, modifiers });
    await sendCdp(tabId, "Input.dispatchKeyEvent", {
      type: "keyUp",
      key: ch,
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
    const row = Math.max(1, Number(params.row) || 7);
    const product = String(params.product || "").trim();
    const stock = String(params.stock ?? "").trim();
    if (!product) throw new Error("product required");
    const productCol = sheetsColLetter(params, "product_col", "B");
    const stockCol = sheetsColLetter(params, "stock_col", "C");
    const cellRef = `${productCol}${row}`;
    await sheetsWriteRowPair(tabId, tab, productCol, stockCol, row, product, stock);
    return {
      ok: true,
      mode: "cdp",
      nav: "v13",
      row,
      product_col: productCol,
      stock_col: stockCol,
      cell: cellRef,
      product,
      stock,
    };
  });

export const sheetsCellSet = (tabId, tab, params = {}) =>
  sheetsWithQueue(tabId, async () => {
    const tabNow = await chrome.tabs.get(tabId);
    sheetsRequireSpreadsheetTab(tabNow);
    const cell = String(params.cell || params.cell_ref || "").trim().toUpperCase();
    const value = String(params.value ?? "");
    if (!CELL_REF_RE.test(cell)) throw new Error("cell required (e.g. A7)");
    const goto = await sheetsGoToCell(tabId, tab, cell);
    const write = await sheetsWriteActiveCell(tabId, value);
    await sheetsGoToCell(tabId, tab, cell);
    await delay(250);
    const verify = await readFormulaBar(tabId);
    const committed = verify.value === value || (value && verify.value.includes(value));
    return {
      ok: committed,
      mode: "cdp",
      nav: "v11",
      cell,
      value,
      goto,
      write,
      verify_value: verify.value,
      formula_bar_found: verify.found,
      committed,
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