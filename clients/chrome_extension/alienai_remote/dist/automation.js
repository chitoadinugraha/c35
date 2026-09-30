// CE-A2: page automation via chrome.scripting on the active / target tab.

export const automationOps = new Set([
  "page.observe",
  "page.act",
  "page.extract",
  "page.screenshot",
  "navigate",
  "reload",
  "history.back",
  "history.forward",
  "task.run",
]);

export const focusedActiveTabId = async () => {
  const win = await chrome.windows.getLastFocused({ windowTypes: ["normal"] }).catch(() => null);
  if (win?.id == null) throw new Error("no focused window");
  const tabs = await chrome.tabs.query({ active: true, windowId: win.id });
  const id = tabs[0]?.id;
  if (id == null) throw new Error("no active tab");
  return id;
};

export const activeTabId = async () => focusedActiveTabId();

const tabToRecord = (t, focusedWindowId) => ({
  tabId: String(t.id ?? ""),
  id: t.id,
  title: t.title || "",
  url: t.url || "",
  active: !!t.active,
  windowId: t.windowId,
  windowFocused: focusedWindowId != null && t.windowId === focusedWindowId,
  index: t.index,
  favicon: t.favIconUrl || "",
});

/** All normal windows; last-focused window first, then tab index. */
export const tabsListAll = async () => {
  const win = await chrome.windows.getLastFocused({ windowTypes: ["normal"] }).catch(() => null);
  const focusedWindowId = win?.id ?? null;
  const tabs = await chrome.tabs.query({});
  return tabs
    .slice()
    .sort((a, b) => {
      const aF = a.windowId === focusedWindowId ? 0 : 1;
      const bF = b.windowId === focusedWindowId ? 0 : 1;
      if (aF !== bF) return aF - bF;
      if (a.windowId !== b.windowId) return a.windowId - b.windowId;
      if (a.active !== b.active) return a.active ? -1 : 1;
      return a.index - b.index;
    })
    .map((t) => tabToRecord(t, focusedWindowId));
};

export const resolveTabId = async (params) => {
  const raw = params?.tab_id ?? params?.tabId;
  if (raw != null && String(raw).trim() !== "") {
    const n = Number(raw);
    if (!Number.isFinite(n)) throw new Error("invalid tab_id");
    return n;
  }
  return activeTabId();
};

const execInTab = (tabId, func, args = []) =>
  new Promise((resolve, reject) => {
    chrome.scripting.executeScript(
      { target: { tabId }, func, args, injectImmediately: true },
      (results) => {
        if (chrome.runtime.lastError) {
          reject(new Error(chrome.runtime.lastError.message));
          return;
        }
        const r = results?.[0];
        if (r?.error) {
          reject(new Error(r.error.message || String(r.error)));
          return;
        }
        resolve(r?.result);
      }
    );
  });

const observeInPage = (maxChars) => {
  const cap = Math.min(Math.max(Number(maxChars) || 8000, 500), 50000);
  const body = document.body;
  const inner = body ? (body.innerText || "").trim() : "";
  const lines = [];
  const walk = (el, depth) => {
    if (lines.length >= 200 || depth > 12) return;
    if (!el || el.nodeType !== 1) return;
    const tag = el.tagName.toLowerCase();
    const id = el.id ? `#${el.id}` : "";
    const role = el.getAttribute("role");
    const label = el.getAttribute("aria-label") || el.getAttribute("name") || "";
    let snippet = "";
    if (el.childNodes.length === 1 && el.childNodes[0].nodeType === 3) {
      snippet = (el.textContent || "").trim().slice(0, 80);
    }
    let line = `${"  ".repeat(depth)}${tag}${id}`;
    if (role) line += `[role=${role}]`;
    if (label) line += ` "${label.slice(0, 60)}"`;
    if (snippet) line += `: ${snippet}`;
    lines.push(line);
    for (const c of el.children) walk(c, depth + 1);
  };
  if (body) walk(body, 0);
  const tree = lines.join("\n");
  let snapshot = inner;
  if (tree) snapshot = `${inner}\n\n--- dom (simplified) ---\n${tree}`;
  const truncated = snapshot.length > cap;
  if (truncated) snapshot = snapshot.slice(0, cap);
  return { snapshot, truncated };
};

const actClick = (selector) => {
  const el = document.querySelector(selector);
  if (!el) throw new Error(`selector not found: ${selector}`);
  el.scrollIntoView({ block: "center", inline: "center" });
  if (typeof el.click === "function") el.click();
  else el.dispatchEvent(new MouseEvent("click", { bubbles: true, cancelable: true, view: window }));
  return { ok: true };
};

const actFill = (selector, text) => {
  const el = document.querySelector(selector);
  if (!el) throw new Error(`selector not found: ${selector}`);
  const value = text == null ? "" : String(text);
  if (el instanceof HTMLInputElement || el instanceof HTMLTextAreaElement || el instanceof HTMLSelectElement) {
    el.focus();
    el.value = value;
    el.dispatchEvent(new Event("input", { bubbles: true }));
    el.dispatchEvent(new Event("change", { bubbles: true }));
    return { ok: true };
  }
  if (el.isContentEditable) {
    el.focus();
    el.textContent = value;
    el.dispatchEvent(new InputEvent("input", { bubbles: true, data: value, inputType: "insertText" }));
    return { ok: true };
  }
  throw new Error("element not fillable");
};

const actPress = (selector, text) => {
  const el = document.querySelector(selector);
  if (!el) throw new Error(`selector not found: ${selector}`);
  el.focus();
  const key = text && String(text).trim() ? String(text).trim() : "Enter";
  const opts = { key, bubbles: true, cancelable: true };
  el.dispatchEvent(new KeyboardEvent("keydown", opts));
  el.dispatchEvent(new KeyboardEvent("keyup", opts));
  return { ok: true };
};

const extractInPage = (selector) => {
  const el = document.querySelector(selector);
  if (!el) throw new Error(`selector not found: ${selector}`);
  if (el instanceof HTMLInputElement || el instanceof HTMLTextAreaElement) {
    return (el.value || "").trim();
  }
  return (el.textContent || "").trim();
};

export const pageObserve = async (params = {}) => {
  const tabId = await resolveTabId(params);
  const tab = await chrome.tabs.get(tabId);
  if (tab.url?.startsWith("chrome://") || tab.url?.startsWith("chrome-extension://")) {
    throw new Error("permission denied for restricted page");
  }
  const maxChars = params.max_chars ?? params.maxChars ?? 8000;
  const page = await execInTab(tabId, observeInPage, [maxChars]);
  return {
    url: tab.url || "",
    title: tab.title || "",
    snapshot: page?.snapshot ?? "",
    truncated: !!page?.truncated,
  };
};

export const pageAct = async (params = {}) => {
  const action = params.action;
  if (!action) throw new Error("action required");
  const selector = params.selector;
  if (!selector) throw new Error("selector required");
  const tabId = await resolveTabId(params);
  const tab = await chrome.tabs.get(tabId);
  if (tab.url?.startsWith("chrome://") || tab.url?.startsWith("chrome-extension://")) {
    throw new Error("permission denied for restricted page");
  }
  await chrome.tabs.update(tabId, { active: true });
  switch (action) {
    case "click":
      return execInTab(tabId, actClick, [selector]);
    case "fill":
      return execInTab(tabId, actFill, [selector, params.text ?? ""]);
    case "press":
      return execInTab(tabId, actPress, [selector, params.text ?? ""]);
    default:
      throw new Error(`unknown page.act action: ${action}`);
  }
};

export const pageExtract = async (params = {}) => {
  const selector = params.selector;
  if (!selector) throw new Error("selector required");
  const tabId = await resolveTabId(params);
  const tab = await chrome.tabs.get(tabId);
  if (tab.url?.startsWith("chrome://") || tab.url?.startsWith("chrome-extension://")) {
    throw new Error("permission denied for restricted page");
  }
  const text = await execInTab(tabId, extractInPage, [selector]);
  const key = params.as || selector;
  return { [key]: text ?? "" };
};

export const pageScreenshot = async (params = {}) => {
  const tabId = await resolveTabId(params);
  const tab = await chrome.tabs.get(tabId);
  if (tab.url?.startsWith("chrome://") || tab.url?.startsWith("chrome-extension://")) {
    throw new Error("permission denied for restricted page");
  }
  const quality = Math.min(95, Math.max(40, Number(params.quality) || 80));
  await chrome.tabs.update(tabId, { active: true });
  const dataUrl = await chrome.tabs.captureVisibleTab(tab.windowId, {
    format: "jpeg",
    quality,
  });
  const comma = dataUrl.indexOf(",");
  const jpeg_b64 = comma >= 0 ? dataUrl.slice(comma + 1) : dataUrl;
  const dims = await execInTab(tabId, () => ({
    width: window.innerWidth,
    height: window.innerHeight,
  }));
  return {
    url: tab.url || "",
    title: tab.title || "",
    width: dims?.width ?? 0,
    height: dims?.height ?? 0,
    jpeg_b64,
  };
};

export const navigate = async (params = {}) => {
  const url = params.url;
  if (!url || typeof url !== "string") throw new Error("url required");
  const tabId = await resolveTabId(params);
  await chrome.tabs.update(tabId, { url });
  return { ok: true };
};

export const reload = async (params = {}) => {
  const tabId = await resolveTabId(params);
  await chrome.tabs.reload(tabId);
  return { ok: true };
};

export const historyBack = async (params = {}) => {
  const tabId = await resolveTabId(params);
  await chrome.scripting.executeScript({
    target: { tabId },
    func: () => {
      window.history.back();
    },
  });
  return { ok: true };
};

export const historyForward = async (params = {}) => {
  const tabId = await resolveTabId(params);
  await chrome.scripting.executeScript({
    target: { tabId },
    func: () => {
      window.history.forward();
    },
  });
  return { ok: true };
};

export const automationDispatch = async (op, params = {}) => {
  switch (op) {
    case "page.observe":
      return pageObserve(params);
    case "page.act":
      return pageAct(params);
    case "page.extract":
      return pageExtract(params);
    case "page.screenshot":
      return pageScreenshot(params);
    case "navigate":
      return navigate(params);
    case "reload":
      return reload(params);
    case "history.back":
      return historyBack(params);
    case "history.forward":
      return historyForward(params);
    case "task.run": {
      const { taskRun } = await import("./task_run.js");
      return taskRun(params);
    }
    default:
      throw new Error(`unknown automation op: ${op}`);
  }
};

export const automationRpcReply = (req_id, ok, result, error) => ({
  req_id,
  ok: !!ok,
  ...(ok ? { result } : { error: String(error || "error") }),
});

/** CE-A1 IPC / NM bridge calls this with { req_id, op, params }. */
export const handleAutomationRpc = async (req) => {
  const req_id = req?.req_id;
  const op = req?.op;
  if (!req_id || !op) throw new Error("req_id and op required");
  try {
    const result = await automationDispatch(op, req.params || {});
    return automationRpcReply(req_id, true, result);
  } catch (e) {
    return automationRpcReply(req_id, false, null, e?.message || e);
  }
};
