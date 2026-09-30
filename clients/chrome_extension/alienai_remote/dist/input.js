// CE-A4: remote input - CDP (trusted) on Google editors; DOM fallback elsewhere.

import { resolveTabId } from "./automation.js";
import { cdpInject, isCdpPreferred } from "./input_cdp.js";

export const REF_VIEWPORT_W = 1280;
export const REF_VIEWPORT_H = 800;

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

const injectRemoteInputDom = (p) => {
  const clamp01 = (v) => Math.min(1, Math.max(0, Number(v) || 0));
  const nx = clamp01(p.x);
  const ny = clamp01(p.y);
  const w = window.innerWidth || REF_VIEWPORT_W;
  const h = window.innerHeight || REF_VIEWPORT_H;
  const x = Math.round(nx * w);
  const y = Math.round(ny * h);
  const btn = Number(p.button) || 0;
  const mouseButton = btn === 2 ? 2 : btn === 1 ? 1 : 0;
  const buttonsMask = btn === 2 ? 2 : btn === 1 ? 4 : 1;

  const targetAt = () =>
    document.elementFromPoint(x, y) || document.body || document.documentElement;

  const mouseOpts = (type, buttonsHeld) => ({
    bubbles: true,
    cancelable: true,
    view: window,
    clientX: x,
    clientY: y,
    button: mouseButton,
    buttons: buttonsHeld ?? (type === "mouseup" ? 0 : buttonsMask),
  });

  const firePointer = (type, el, extra = {}) => {
    const held = type.includes("up") ? 0 : buttonsMask;
    const pe = new PointerEvent(type, {
      bubbles: true,
      cancelable: true,
      view: window,
      clientX: x,
      clientY: y,
      button: mouseButton,
      buttons: held,
      pointerId: 1,
      pointerType: "mouse",
      isPrimary: true,
      ...extra,
    });
    el.dispatchEvent(pe);
    const me = type.replace("pointer", "mouse");
    if (me !== type) {
      el.dispatchEvent(new MouseEvent(me, { ...mouseOpts(me, held), ...extra }));
    }
  };

  const clickAt = (detail = 1) => {
    const el = targetAt();
    firePointer("pointermove", el);
    firePointer("pointerdown", el);
    firePointer("pointerup", el);
    el.dispatchEvent(
      new MouseEvent("click", { ...mouseOpts("click", 0), detail })
    );
  };

  const eventType = p.event_type;
  switch (eventType) {
    case "mouse_move": {
      const el = targetAt();
      firePointer("pointermove", el, { buttons: 0 });
      break;
    }
    case "mouse_down": {
      const el = targetAt();
      firePointer("pointerdown", el);
      break;
    }
    case "mouse_up": {
      const el = targetAt();
      firePointer("pointerup", el);
      break;
    }
    case "mouse_click":
      clickAt(1);
      break;
    case "double_click":
      clickAt(1);
      clickAt(2);
      break;
    case "wheel": {
      const el = targetAt();
      el.dispatchEvent(
        new WheelEvent("wheel", {
          bubbles: true,
          cancelable: true,
          view: window,
          clientX: x,
          clientY: y,
          deltaX: Number(p.delta_x) || 0,
          deltaY: Number(p.delta_y) || 0,
        })
      );
      break;
    }
    case "key_down":
    case "key_up": {
      const key = String(p.text || "");
      const el = document.activeElement || targetAt();
      const type = eventType === "key_down" ? "keydown" : "keyup";
      el.dispatchEvent(new KeyboardEvent(type, { key, bubbles: true, cancelable: true }));
      break;
    }
    case "type_text": {
      const text = String(p.text || "");
      const el = document.activeElement;
      if (
        el &&
        (el instanceof HTMLInputElement ||
          el instanceof HTMLTextAreaElement ||
          el.isContentEditable)
      ) {
        el.focus();
        if (el instanceof HTMLInputElement || el instanceof HTMLTextAreaElement) {
          const start = el.selectionStart ?? el.value.length;
          const end = el.selectionEnd ?? start;
          el.value = el.value.slice(0, start) + text + el.value.slice(end);
          el.selectionStart = el.selectionEnd = start + text.length;
          el.dispatchEvent(new InputEvent("input", { bubbles: true, data: text, inputType: "insertText" }));
        } else {
          el.textContent = (el.textContent || "") + text;
          el.dispatchEvent(
            new InputEvent("input", { bubbles: true, data: text, inputType: "insertText" })
          );
        }
      } else if (document.execCommand) {
        document.execCommand("insertText", false, text);
      }
      break;
    }
    case "shortcut": {
      const combo = String(p.text || "").trim().toLowerCase();
      if (!combo) break;
      const parts = combo.split("+").map((s) => s.trim()).filter(Boolean);
      const key = parts[parts.length - 1] || "";
      const mods = parts.slice(0, -1);
      const modOpts = {
        ctrlKey: mods.includes("ctrl") || mods.includes("control"),
        altKey: mods.includes("alt"),
        shiftKey: mods.includes("shift"),
        metaKey: mods.includes("meta") || mods.includes("cmd") || mods.includes("win"),
      };
      const el = document.activeElement || targetAt();
      el.dispatchEvent(new KeyboardEvent("keydown", { key, bubbles: true, cancelable: true, ...modOpts }));
      el.dispatchEvent(new KeyboardEvent("keyup", { key, bubbles: true, cancelable: true, ...modOpts }));
      break;
    }
    default:
      throw new Error(`unknown input event_type: ${eventType}`);
  }
  return { ok: true, mode: "dom" };
};

const maybeFocusTabDom = async (tabId, tab, params) => {
  if (params.focus === false) return;
  if (params.focus !== true) {
    const win = await chrome.windows.get(tab.windowId);
    if (tab.active && win.focused) return;
  }
  await chrome.windows.update(tab.windowId, { focused: true });
  await chrome.tabs.update(tabId, { active: true });
};

const domInject = async (tabId, tab, params) => {
  await maybeFocusTabDom(tabId, tab, params);
  return execInTab(tabId, injectRemoteInputDom, [params]);
};

const inputQueues = new Map();

const inputInjectInner = async (params = {}) => {
  const tabId = await resolveTabId(params);
  const tab = await chrome.tabs.get(tabId);
  if (tab.url?.startsWith("chrome://") || tab.url?.startsWith("chrome-extension://")) {
    throw new Error("permission denied for restricted page");
  }
  const mode = params.input_mode;
  const wantCdp = mode !== "dom";
  if (wantCdp) {
    try {
      return await cdpInject(tabId, tab, params);
    } catch (e) {
      if (mode === "cdp") throw e;
      return domInject(tabId, tab, { ...params, cdp_error: String(e?.message || e) });
    }
  }
  return domInject(tabId, tab, params);
};

export const inputInject = async (params = {}) => {
  const tabId = await resolveTabId(params);
  const prev = inputQueues.get(tabId) || Promise.resolve();
  const next = prev.then(() => inputInjectInner(params));
  inputQueues.set(tabId, next.catch(() => {}));
  return next;
};

export const handleInputRpc = async (req) => {
  const req_id = req?.req_id;
  if (!req_id) throw new Error("req_id required");
  try {
    const result = await inputInject(req.params || {});
    return { req_id, ok: true, result };
  } catch (e) {
    return { req_id, ok: false, error: String(e?.message || e) };
  }
};