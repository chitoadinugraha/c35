// Alien AI Remote — MV3 service worker (v1 plain JS)
import {
  automationOps,
  handleAutomationRpc,
  activeTabId as automationActiveTabId,
} from "./automation.js";
import { inputInject } from "./input.js";

const NATIVE_HOST = "com.alienai.c35.remote";
const EXT_LOG_MAX = 80;

let nativePort = null;
let extLogs = [];

const extLog = (level, text) => {
  const line = `${new Date().toISOString().slice(11, 19)} ${level} ${text}`;
  extLogs.push(line);
  if (extLogs.length > EXT_LOG_MAX) extLogs = extLogs.slice(-EXT_LOG_MAX);
  chrome.runtime.sendMessage({ type: "diagnostics.push" }).catch(() => {});
};
let nmConnectBusy = false;
let captureActive = false;
let captureTabId = null;
let captureTimer = null;
const CAPTURE_MAX_FPS = 15;
const CAPTURE_JPEG_QUALITY = 65;
let pairBusy = false;
let pairEnsurePending = false;

const nmSend = (msg) => {
  if (!nativePort) return false;
  try {
    nativePort.postMessage(msg);
    return true;
  } catch (e) {
    console.warn("native postMessage failed", e);
    return false;
  }
};

/** One-shot native host call (pair/ping). Reliable vs long-lived port + MV3 sleep. */
const nmRequest = (msg, timeoutMs = 12000) =>
  new Promise((resolve, reject) => {
    let done = false;
    const timer = setTimeout(() => {
      if (done) return;
      done = true;
      reject(new Error(`native messaging timeout (${timeoutMs}ms)`));
    }, timeoutMs);
    chrome.runtime.sendNativeMessage(NATIVE_HOST, msg, (response) => {
      if (done) return;
      done = true;
      clearTimeout(timer);
      if (chrome.runtime.lastError) {
        reject(new Error(chrome.runtime.lastError.message));
        return;
      }
      resolve(response ?? {});
    });
  });

const collectDiagnostics = async () => {
  extLog("info", "diagnostics.collect start");
  let agent = {};
  let nativePing = false;
  let nativePingError = "";
  try {
    const pingRes = await nmRequest({ type: "ping" }, 8000);
    nativePing = pingRes?.ok === true && pingRes?.pong === true;
    if (!nativePing) extLog("warn", `native ping failed: ${JSON.stringify(pingRes)}`);
  } catch (e) {
    nativePingError = String(e.message || e);
    extLog("error", `native ping: ${nativePingError}`);
  }
  try {
    agent = await nmRequest({ type: "agent.status" }, 10000);
    extLog("info", `agent.status ws=${agent.ws_connected} ipc=${agent.native_ipc}`);
  } catch (e) {
    agent = { agent_error: String(e.message || e) };
    extLog("error", `agent.status: ${agent.agent_error}`);
  }
  const storage = await pairStorageGet();
  return {
    ok: true,
    nativePort: !!nativePort,
    nativePing,
    nativePingError,
    captureActive,
    pairState: storage.pairState || "idle",
    agent,
    extLogs: extLogs.slice(),
  };
};

const nmConnect = () => {
  if (nativePort) return nativePort;
  if (nmConnectBusy) return null;
  nmConnectBusy = true;
  try {
    nativePort = chrome.runtime.connectNative(NATIVE_HOST);
    nativePort.onMessage.addListener((msg) => onNativeMessage(msg));
    nativePort.onDisconnect.addListener(() => {
      nativePort = null;
      nmConnectBusy = false;
      stopCapture();
      extLog("warn", "native port disconnected");
      broadcastStatus({ type: "native", state: "disconnected" });
    });
    nmConnectBusy = false;
    extLog("info", "native port connected");
    broadcastStatus({ type: "native", state: "connected" });
  } catch (e) {
    nativePort = null;
    nmConnectBusy = false;
    console.warn("connectNative failed", e);
    extLog("error", `connectNative: ${e}`);
    broadcastStatus({ type: "native", state: "error", error: String(e) });
  }
  return nativePort;
};

const handleNativePairPayload = (msg) => {
  if (!msg || msg.pong) return false;
  if (msg.ok === false && msg.error) {
    pairEnsurePending = false;
    broadcastPairStatus({ state: "error", error: String(msg.error) });
    return true;
  }
  if (msg.ok === true && msg.code) {
    pairEnsurePending = false;
    broadcastPairStatus({
      state: "pairing",
      error: "",
      code: msg.code,
      expires_in_sec: msg.expires_in_sec,
    });
    return true;
  }
  if (msg.status) {
    const state = msg.status === "claimed" ? "paired" : msg.status === "pending" ? "pairing" : msg.status;
    if (state === "paired") pairEnsurePending = false;
    if (state === "pairing" && msg.code) pairEnsurePending = false;
    if (pairEnsurePending && (msg.status === "idle" || (msg.status === "pending" && !msg.code))) {
      pairEnsurePending = false;
      pairStart();
      return true;
    }
    broadcastPairStatus({
      state,
      error: msg.error || "",
      code: msg.code,
      expires_in_sec: msg.expires_in_sec,
    });
    return true;
  }
  return false;
};

const onNativeMessage = (msg) => {
  if (!msg) return;
  if (handleNativePairPayload(msg)) return;
  if (!msg.type) return;
  switch (msg.type) {
    case "pair.status":
      broadcastPairStatus(msg);
      break;
    case "capture.start":
      nmConnect();
      extLog("info", "capture.start from agent");
      void startCapture(msg.tabId ?? msg.tab_id);
      break;
    case "capture.stop":
    case "screencast.stop":
      stopCapture();
      break;
    case "tabs.list":
      tabsList().then((tabs) => nmSend({ type: "tabs.list", tabs }));
      break;
    case "tabs.activate":
      tabsActivate(msg.tabId);
      break;
    case "tabs.new":
      tabsNew(msg.url);
      break;
    case "tabs.close":
      tabsClose(msg.tabId);
      break;
    case "rpc":
    case "extension.ipc.rpc":
      nmConnect();
      void onExtensionIpcRpc({
        req_id: msg.req_id,
        op: msg.op,
        params: msg.params || {},
      });
      break;
    default:
      break;
  }
};

const broadcastPairStatus = (msg) => {
  let state = msg.state || msg.status || "unknown";
  if (state === "claimed") state = "paired";
  const error = msg.error || "";
  const code = msg.code || "";
  const expiresSec = msg.expires_in_sec != null ? Number(msg.expires_in_sec) : 0;
  const payload = { pairState: state, pairError: error };
  if (state === "connecting") {
    payload.pairCode = "";
  } else if (state === "pairing" && code) {
    payload.pairCode = code;
    payload.pairExpiresTotalSec = expiresSec > 0 ? expiresSec : 300;
    payload.pairExpiresAt = Date.now() + payload.pairExpiresTotalSec * 1000;
  } else if (state === "paired" || state === "idle" || state === "error") {
    payload.pairCode = "";
    payload.pairExpiresAt = 0;
    payload.pairExpiresTotalSec = 0;
  }
  chrome.storage.local.set(payload);
  chrome.runtime.sendMessage({ type: "pair.status", state, error, code }).catch(() => {});
};

let pairEnsureInflight = null;
const pairStorageGet = () =>
  new Promise((resolve) => {
    chrome.storage.local.get(
      ["pairState", "pairError", "pairCode", "pairExpiresAt", "pairExpiresTotalSec"],
      resolve
    );
  });

const pairEnsure = async () => {
  if (pairEnsureInflight) return pairEnsureInflight;
  pairEnsureInflight = (async () => {
    broadcastPairStatus({ state: "connecting", error: "" });
    try {
      let res = await nmRequest({ type: "pair.status" });
      if (!handleNativePairPayload(res)) {
        const st = res?.status;
        if (st === "idle" || (st === "pending" && !res?.code)) {
          res = await nmRequest({ type: "pair.start" });
          handleNativePairPayload(res);
        }
      }
    } catch (e) {
      extLog("error", `pair.ensure: ${e.message || e}`);
      broadcastPairStatus({
        state: "error",
        error: String(e.message || e),
      });
    }
    return pairStorageGet();
  })().finally(() => {
    pairEnsureInflight = null;
  });
  return pairEnsureInflight;
};

const broadcastStatus = (payload) => {
  chrome.runtime.sendMessage({ type: "status", ...payload }).catch(() => {});
};

// --- Pair (extension UI triggers host via NM) ---
const pairStart = async () => {
  if (pairBusy) return;
  pairBusy = true;
  setTimeout(() => {
    pairBusy = false;
  }, 5000);
  broadcastPairStatus({ state: "connecting", error: "" });
  try {
    const res = await nmRequest({ type: "pair.start" });
    handleNativePairPayload(res);
  } catch (e) {
    broadcastPairStatus({ state: "error", error: String(e.message || e) });
  }
};

// --- Capture stub (Track F) ---
const captureOnce = async () => {
  if (!captureActive) return;
  const tabId = captureTabId;
  if (tabId == null) return;
  try {
    const dataUrl = await chrome.tabs.captureVisibleTab(null, {
      format: "jpeg",
      quality: CAPTURE_JPEG_QUALITY,
    });
    const comma = dataUrl.indexOf(",");
    const b64 = comma >= 0 ? dataUrl.slice(comma + 1) : dataUrl;
    nmSend({
      type: "frame",
      tabId,
      width: msgWidth,
      height: msgHeight,
      jpeg_b64: b64,
    });
  } catch (e) {
    console.warn("captureVisibleTab failed", e);
  }
};

let msgWidth = 0;
let msgHeight = 0;

const startCapture = async (tabId) => {
  stopCapture();
  captureActive = true;
  captureTabId = tabId ?? (await activeTabId());
  const intervalMs = Math.max(1, Math.floor(1000 / CAPTURE_MAX_FPS));
  captureTimer = setInterval(() => captureOnce(), intervalMs);
  nmSend({ type: "capture.started", tabId: captureTabId });
};

const stopCapture = () => {
  captureActive = false;
  captureTabId = null;
  if (captureTimer) {
    clearInterval(captureTimer);
    captureTimer = null;
  }
  nmSend({ type: "capture.stopped" });
};

const activeTabId = async () => {
  try {
    return await automationActiveTabId();
  } catch {
    return null;
  }
};

// --- Extension IPC RPC (CE-A1 op + params + req_id; CE-A2 automation ops) ---
const extensionRpcHandle = async (req) => {
  const req_id = req?.req_id;
  const op = req?.op;
  if (!req_id || !op) return { req_id: req_id || "", ok: false, error: "req_id and op required" };
  if (automationOps.has(op)) return handleAutomationRpc(req);
  try {
    let result;
    switch (op) {
      case "tabs.list":
        result = { tabs: await tabsList() };
        break;
      case "tabs.activate": {
        const tabId = Number(req.params?.tab_id ?? req.params?.tabId);
        if (!Number.isFinite(tabId)) throw new Error("tab_id required");
        await tabsActivate(tabId);
        result = { ok: true };
        break;
      }
      case "tabs.new": {
        const tab = await chrome.tabs.create({ url: req.params?.url || "about:blank" });
        result = { tabId: tab.id, ok: true };
        break;
      }
      case "tabs.close": {
        const tabId = Number(req.params?.tab_id ?? req.params?.tabId);
        if (!Number.isFinite(tabId)) throw new Error("tab_id required");
        await tabsClose(tabId);
        result = { ok: true };
        break;
      }
      case "input.inject":
        result = await inputInject(req.params || {});
        break;
      default:
        throw new Error(`unknown op: ${op}`);
    }
    return { req_id, ok: true, result };
  } catch (e) {
    return { req_id, ok: false, error: String(e?.message || e) };
  }
};

const extensionRpcReplyNative = (reply) => {
  if (!reply?.req_id) return;
  nmSend({
    type: "rpc.result",
    req_id: reply.req_id,
    ok: reply.ok === true,
    error: reply.error,
    result: reply.result,
  });
};

/** CE-A1 TCP/NM bridge entry — call from ipc client when wired. */
globalThis.__c35_extensionRpcHandle = extensionRpcHandle;

const onExtensionIpcRpc = (req) =>
  extensionRpcHandle(req).then((reply) => {
    extensionRpcReplyNative(reply);
    return reply;
  });

// --- Tabs stub (Track I) ---
const tabsList = async () => {
  const tabs = await chrome.tabs.query({ currentWindow: true });
  return tabs.map((t) => ({
    tabId: String(t.id ?? ""),
    id: t.id,
    title: t.title || "",
    url: t.url || "",
    active: t.active,
    windowId: t.windowId,
    favicon: t.favIconUrl || "",
  }));
};

const tabsActivate = async (tabId) => {
  if (tabId == null) return;
  await chrome.tabs.update(tabId, { active: true });
  nmSend({ type: "tabs.activated", tabId });
};

const tabsNew = async (url) => {
  const tab = await chrome.tabs.create({ url: url || "about:blank" });
  nmSend({ type: "tabs.created", tabId: tab.id });
};

const tabsClose = async (tabId) => {
  if (tabId == null) return;
  await chrome.tabs.remove(tabId);
  nmSend({ type: "tabs.closed", tabId });
};

// --- External: pair page on alienai.id ---
chrome.runtime.onMessageExternal.addListener((msg, sender, sendResponse) => {
  if (!msg || !msg.type) return;
  if (msg.type === "pair.page.ready") {
    chrome.storage.local.get(["pairState", "pairError"], (data) => {
      sendResponse({
        ok: true,
        state: data.pairState || "idle",
        error: data.pairError || "",
      });
    });
    return true;
  }
  if (msg.type === "extension.status") {
    sendResponse({ ok: true, native: !!nativePort, captureActive });
    return true;
  }
  return false;
});

chrome.runtime.onMessage.addListener((msg, _sender, sendResponse) => {
  if (!msg || !msg.type) return;
  switch (msg.type) {
    case "native.ping":
      nmRequest({ type: "ping" })
        .then((res) => {
          const ok = res?.ok === true && res?.pong === true;
          extLog(ok ? "info" : "warn", ok ? "native ping OK" : "native ping failed");
          sendResponse({ ok });
        })
        .catch((e) => {
          extLog("error", `native ping: ${e.message || e}`);
          sendResponse({ ok: false, error: String(e.message || e) });
        });
      return true;
    case "diagnostics.logs":
      sendResponse({ ok: true, extLogs: extLogs.slice(), captureActive });
      return true;
    case "diagnostics.get":
      return collectDiagnostics().catch((e) => {
        extLog("error", `diagnostics.get: ${e.message || e}`);
        return {
          ok: true,
          nativePort: !!nativePort,
          nativePing: false,
          nativePingError: String(e.message || e),
          captureActive,
          agent: {},
          extLogs: extLogs.slice(),
        };
      });
    case "pair.start":
      pairStart().then(() => sendResponse({ ok: true }));
      return true;
    case "pair.refresh":
    case "pair.ensure":
      pairEnsure()
        .then((data) => sendResponse({ ok: true, ...(data || {}) }))
        .catch((e) => sendResponse({ ok: false, error: String(e.message || e) }));
      return true;
    case "capture.stop":
      stopCapture();
      sendResponse({ ok: true });
      return true;
    case "extension.ipc.rpc":
      extensionRpcHandle({
        req_id: msg.req_id,
        op: msg.op,
        params: msg.params || {},
      })
        .then((reply) => sendResponse(reply))
        .catch((e) =>
          sendResponse({
            req_id: msg.req_id || "",
            ok: false,
            error: String(e?.message || e),
          })
        );
      return true;
    default:
      return false;
  }
});

chrome.runtime.onInstalled.addListener((details) => {
  if (details.reason === "install") {
    chrome.storage.local.set({ pairState: "idle", pairCode: "", pairExpiresAt: 0 });
  }
  nmConnect();
});

extLog("info", "service worker loaded");
nmConnect();

chrome.runtime.onStartup.addListener(() => {
  nmConnect();
});

export { extensionRpcHandle, onExtensionIpcRpc };