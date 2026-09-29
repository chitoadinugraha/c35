// Alien AI Remote — MV3 service worker (v1 plain JS)
const NATIVE_HOST = "com.alienai.c35.remote";

let nativePort = null;
let captureActive = false;
let captureTabId = null;
let captureTimer = null;
const CAPTURE_MAX_FPS = 15;
const CAPTURE_JPEG_QUALITY = 65;

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

const nmConnect = () => {
  if (nativePort) return nativePort;
  try {
    nativePort = chrome.runtime.connectNative(NATIVE_HOST);
    nativePort.onMessage.addListener((msg) => onNativeMessage(msg));
    nativePort.onDisconnect.addListener(() => {
      nativePort = null;
      stopCapture();
      broadcastStatus({ type: "native", state: "disconnected" });
    });
    nmSend({ type: "ping" });
    broadcastStatus({ type: "native", state: "connected" });
  } catch (e) {
    console.warn("connectNative failed", e);
    broadcastStatus({ type: "native", state: "error", error: String(e) });
  }
  return nativePort;
};

const onNativeMessage = (msg) => {
  if (!msg || !msg.type) return;
  switch (msg.type) {
    case "pair.status":
      broadcastPairStatus(msg);
      break;
    case "capture.start":
      startCapture(msg.tabId);
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
    default:
      break;
  }
};

const broadcastPairStatus = (msg) => {
  const state = msg.state || "unknown";
  const error = msg.error || "";
  chrome.storage.local.set({ pairState: state, pairError: error });
  chrome.runtime.sendMessage({ type: "pair.status", state, error }).catch(() => {});
  chrome.tabs.query({ url: "https://alienai.id/device/pair/chrome-extension*" }, (tabs) => {
    for (const tab of tabs) {
      if (!tab.id) continue;
      chrome.scripting
        .executeScript({
          target: { tabId: tab.id },
          func: (st, err) => {
            window.postMessage(
              { source: "alienai-chrome-extension", type: "pair.status", state: st, error: err },
              "*"
            );
          },
          args: [state, error],
        })
        .catch(() => {});
    }
  });
};

const broadcastStatus = (payload) => {
  chrome.runtime.sendMessage({ type: "status", ...payload }).catch(() => {});
};

// --- Pair (extension UI triggers host via NM) ---
const pairStart = () => {
  nmConnect();
  nmSend({ type: "pair.start" });
  broadcastPairStatus({ state: "pairing" });
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
  const tabs = await chrome.tabs.query({ active: true, currentWindow: true });
  return tabs[0]?.id ?? null;
};

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
      nmConnect();
      sendResponse({ ok: !!nativePort });
      return true;
    case "pair.start":
      pairStart();
      sendResponse({ ok: true });
      return true;
    case "capture.stop":
      stopCapture();
      sendResponse({ ok: true });
      return true;
    default:
      return false;
  }
});

chrome.runtime.onInstalled.addListener(() => {
  chrome.storage.local.set({ pairState: "idle" });
});

nmConnect();