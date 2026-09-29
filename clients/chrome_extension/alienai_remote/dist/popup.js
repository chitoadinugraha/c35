const NATIVE_HOST = "com.alienai.c35.remote";

const LOG_INITIAL = 16;
const LOG_PAGE = 20;
const STATUS_POLL_MS = 3000;
const LOG_POLL_MS = 12000;

const statusEl = document.getElementById("status");
const pairPanel = document.getElementById("pairPanel");
const pairedPanel = document.getElementById("pairedPanel");
const subtitleEl = document.getElementById("subtitle");
const pairCodeEl = document.getElementById("pairCode");
const pairProgressEl = document.getElementById("pairProgress");
const btnPing = document.getElementById("btnPing");
const btnRefresh = document.getElementById("btnRefresh");
const btnCopyLogs = document.getElementById("btnCopyLogs");
const logTail = document.getElementById("logTail");
const logMoreHint = document.getElementById("logMoreHint");

const dotNative = document.getElementById("dotNative");
const dotAgent = document.getElementById("dotAgent");
const dotCloud = document.getElementById("dotCloud");
const dotWebrtc = document.getElementById("dotWebrtc");
const detailNative = document.getElementById("detailNative");
const detailAgent = document.getElementById("detailAgent");
const detailCloud = document.getElementById("detailCloud");
const detailWebrtc = document.getElementById("detailWebrtc");

let progressTimer = null;
let statusTimer = null;
let logTimer = null;
let statusInFlight = false;
let logInFlight = false;
let logLinesNewestFirst = [];
let logVisibleCount = LOG_INITIAL;
let lastStatusRes = null;

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

const setDot = (el, mode) => {
  el.className = `dot ${mode}`;
};

const stopProgressTimer = () => {
  if (progressTimer) {
    clearInterval(progressTimer);
    progressTimer = null;
  }
};

const stopDiagPoll = () => {
  if (statusTimer) {
    clearInterval(statusTimer);
    statusTimer = null;
  }
  if (logTimer) {
    clearInterval(logTimer);
    logTimer = null;
  }
};

const logLineKey = (line) => line;

const mergeLogLines = (res) => {
  const agent = res?.agent || {};
  const chronological = [];
  if (res?.nativePingError) chronological.push(`[native] ${res.nativePingError}`);
  if (agent.error) chronological.push(`[host] ${agent.error}`);
  if (agent.agent_error) chronological.push(`[agent] ${agent.agent_error}`);
  if (agent.server_url) chronological.push(`[server] ${agent.server_url}`);
  if (agent.device_iid) chronological.push(`[device] ${agent.device_iid}`);
  for (const l of agent.log_lines || []) chronological.push(l);
  for (const l of res?.extLogs || []) chronological.push(l);
  const seen = new Set();
  const newestFirst = [];
  for (let i = chronological.length - 1; i >= 0; i -= 1) {
    const line = chronological[i];
    const key = logLineKey(line);
    if (seen.has(key)) continue;
    seen.add(key);
    newestFirst.push(line);
  }
  return newestFirst;
};

const renderLogPanel = () => {
  if (!logLinesNewestFirst.length) {
    logTail.textContent = "(no logs yet)";
    if (logMoreHint) logMoreHint.textContent = "";
    return;
  }
  const shown = logLinesNewestFirst.slice(0, logVisibleCount);
  logTail.textContent = shown.join("\n");
  const hidden = logLinesNewestFirst.length - shown.length;
  if (logMoreHint) {
    logMoreHint.textContent = hidden > 0 ? `${hidden} older — scroll down or tap Load more` : "";
  }
};

const loadMoreLogs = () => {
  logVisibleCount += LOG_PAGE;
  renderLogPanel();
};

const renderStatus = (res) => {
  const agent = res?.agent || {};
  const nativeOk = res?.nativePing === true;

  if (nativeOk) {
    setDot(dotNative, "on");
    detailNative.textContent = "ping OK";
  } else {
    setDot(dotNative, "err");
    detailNative.textContent = res?.nativePingError || "unreachable";
  }

  if (agent.agent_reachable) {
    setDot(dotAgent, "on");
    detailAgent.textContent = agent.agent_version || "online";
  } else if (agent.native_ipc) {
    setDot(dotAgent, "warn");
    detailAgent.textContent = "IPC up, agent down";
  } else {
    setDot(dotAgent, "err");
    detailAgent.textContent = agent.agent_error ? "no IPC" : "offline";
  }

  if (agent.agent_reachable && agent.ws_connected) {
    setDot(dotCloud, "on");
    detailCloud.textContent = "connected";
  } else if (agent.agent_reachable) {
    setDot(dotCloud, "warn");
    detailCloud.textContent = "offline";
  } else {
    setDot(dotCloud, "off");
    detailCloud.textContent = "—";
  }

  const sessions = Number(agent.webrtc_sessions || 0);
  if (agent.webrtc_connecting) {
    setDot(dotWebrtc, "warn");
    detailWebrtc.textContent = "connecting…";
  } else if (sessions > 0) {
    setDot(dotWebrtc, "on");
    detailWebrtc.textContent =
      agent.webrtc_subtitle || `${sessions} viewer${sessions === 1 ? "" : "s"}`;
  } else if (res?.captureActive) {
    setDot(dotWebrtc, "warn");
    detailWebrtc.textContent = "capture active";
  } else if (agent.agent_reachable) {
    setDot(dotWebrtc, "off");
    detailWebrtc.textContent = "idle";
  } else {
    setDot(dotWebrtc, "off");
    detailWebrtc.textContent = "—";
  }
};

const fetchDiagnosticsPayload = async () => {
  let nativePing = false;
  let nativePingError = "";
  let agent = {};
  let extLogs = [];
  let captureActive = false;

  try {
    const pingRes = await nmRequest({ type: "ping" }, 8000);
    nativePing = pingRes?.ok === true && pingRes?.pong === true;
    if (!nativePing) nativePingError = `ping failed: ${JSON.stringify(pingRes)}`;
  } catch (e) {
    nativePingError = String(e.message || e);
  }

  try {
    agent = await nmRequest({ type: "agent.status" }, 10000);
  } catch (e) {
    agent = { agent_error: String(e.message || e) };
  }

  try {
    const sw = await Promise.race([
      chrome.runtime.sendMessage({ type: "diagnostics.logs" }),
      new Promise((resolve) => setTimeout(() => resolve(null), 1500)),
    ]);
    if (sw?.extLogs) extLogs = sw.extLogs;
    if (sw?.captureActive) captureActive = true;
  } catch {
    /* optional */
  }

  return { ok: true, nativePing, nativePingError, captureActive, agent, extLogs };
};

const refreshStatus = async () => {
  if (statusInFlight) return;
  statusInFlight = true;
  try {
    const res = await fetchDiagnosticsPayload();
    lastStatusRes = res;
    renderStatus(res);
  } catch (e) {
    setDot(dotNative, "err");
    detailNative.textContent = "error";
    if (!logLinesNewestFirst.length) {
      logTail.textContent = String(e.message || e);
    }
  } finally {
    statusInFlight = false;
  }
};

const refreshLogs = async (resetVisible) => {
  if (logInFlight) return;
  logInFlight = true;
  try {
    const res = lastStatusRes || await fetchDiagnosticsPayload();
    lastStatusRes = res;
    logLinesNewestFirst = mergeLogLines(res);
    if (resetVisible) logVisibleCount = LOG_INITIAL;
    renderLogPanel();
  } finally {
    logInFlight = false;
  }
};

const refreshAll = async () => {
  await refreshStatus();
  await refreshLogs(true);
};

const showDiagFault = (text) => {
  setDot(dotNative, "err");
  detailNative.textContent = "error";
  logLinesNewestFirst = [text];
  logVisibleCount = LOG_INITIAL;
  renderLogPanel();
};

const startDiagPoll = () => {
  refreshAll();
  stopDiagPoll();
  statusTimer = setInterval(refreshStatus, STATUS_POLL_MS);
  logTimer = setInterval(() => refreshLogs(false), LOG_POLL_MS);
};

const updateProgress = (expiresAt, expiresTotalSec) => {
  const totalMs = Math.max(1, (expiresTotalSec || 300) * 1000);
  const tick = () => {
    const remain = Math.max(0, expiresAt - Date.now());
    pairProgressEl.style.width = `${(remain / totalMs) * 100}%`;
    if (remain <= 0) {
      stopProgressTimer();
      chrome.runtime.sendMessage({ type: "pair.ensure" });
    }
  };
  tick();
  stopProgressTimer();
  progressTimer = setInterval(tick, 250);
};

const showPaired = () => {
  pairedPanel.classList.add("active");
  pairPanel.classList.remove("active");
  statusEl.classList.add("hidden");
  subtitleEl.classList.add("hidden");
  stopProgressTimer();
  startDiagPoll();
};

const showPairing = (code, expiresAt, expiresTotalSec, mode) => {
  pairedPanel.classList.remove("active");
  pairPanel.classList.add("active");
  statusEl.classList.add("hidden");
  subtitleEl.classList.remove("hidden");
  startDiagPoll();
  if (mode === "connecting") {
    pairCodeEl.textContent = "Connecting…";
    pairProgressEl.style.width = "35%";
    stopProgressTimer();
    return;
  }
  pairCodeEl.textContent = mode === "loading" ? "··· ···" : code || "··· ···";
  updateProgress(expiresAt || Date.now() + 300000, expiresTotalSec || 300);
};

const showError = (text) => {
  pairedPanel.classList.remove("active");
  pairPanel.classList.remove("active");
  statusEl.classList.remove("hidden");
  statusEl.textContent = text;
  statusEl.className = "err";
  stopProgressTimer();
  startDiagPoll();
};

const applyPairStorage = (data) => {
  const st = data.pairState || "idle";
  const err = data.pairError || "";
  const code = data.pairCode || "";
  const expiresAt = data.pairExpiresAt || 0;
  const expiresTotalSec = data.pairExpiresTotalSec || 300;

  if (st === "paired") {
    showPaired();
    return;
  }
  if (st === "error") {
    showError(err || "Pairing failed. Check native host install.");
    return;
  }
  if (st === "connecting") {
    showPairing("", 0, 300, "connecting");
    return;
  }
  if (st === "pairing" && code) {
    showPairing(code, expiresAt, expiresTotalSec, "code");
    return;
  }
  if (st === "pairing") {
    showPairing("", 0, 300, "loading");
    return;
  }
  showPairing("", 0, 300, "connecting");
};

const refreshPairState = () =>
  chrome.storage.local.get(
    ["pairState", "pairError", "pairCode", "pairExpiresAt", "pairExpiresTotalSec"],
    applyPairStorage
  );

btnPing.addEventListener("click", async () => {
  btnPing.disabled = true;
  try {
    const res = await nmRequest({ type: "ping" }, 8000);
    if (res?.ok !== true || res?.pong !== true) {
      showError("Native host failed — reinstall host binary + reload extension.");
      return;
    }
    refreshPairState();
    refreshAll();
  } catch {
    showError("Native host failed — reinstall host binary + reload extension.");
    refreshAll();
  } finally {
    btnPing.disabled = false;
  }
});

btnRefresh.addEventListener("click", () => refreshAll());

btnCopyLogs.addEventListener("click", async () => {
  const text = logLinesNewestFirst.join("\n");
  try {
    await navigator.clipboard.writeText(text);
    btnCopyLogs.textContent = "Copied";
    setTimeout(() => {
      btnCopyLogs.textContent = "Copy logs";
    }, 1200);
  } catch {
    btnCopyLogs.textContent = "Copy failed";
  }
});

if (logTail) {
  logTail.addEventListener("scroll", () => {
    const nearBottom = logTail.scrollTop + logTail.clientHeight >= logTail.scrollHeight - 12;
    if (nearBottom && logVisibleCount < logLinesNewestFirst.length) loadMoreLogs();
  });
}

if (logMoreHint) {
  logMoreHint.addEventListener("click", () => loadMoreLogs());
}

chrome.storage.onChanged.addListener((changes, area) => {
  if (area !== "local") return;
  if (changes.pairState || changes.pairError || changes.pairCode || changes.pairExpiresAt) {
    refreshPairState();
  }
});

chrome.runtime.onMessage.addListener((msg) => {
  if (msg?.type === "pair.status") refreshPairState();
});

window.addEventListener("unload", () => stopDiagPoll());

logTail.textContent = "Fetching logs…";
startDiagPoll();

chrome.runtime.sendMessage({ type: "pair.ensure" }, (res) => {
  if (chrome.runtime.lastError) {
    showError(chrome.runtime.lastError.message);
    return;
  }
  if (res?.pairState) applyPairStorage(res);
  else refreshPairState();
});
