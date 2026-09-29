const statusEl = document.getElementById("status");
const btnPair = document.getElementById("btnPair");
const btnPing = document.getElementById("btnPing");

const setStatus = (text, cls) => {
  statusEl.textContent = text;
  statusEl.className = cls || "";
};

const refreshPairState = () => {
  chrome.storage.local.get(["pairState", "pairError"], (data) => {
    const st = data.pairState || "idle";
    const err = data.pairError || "";
    if (st === "paired") setStatus("Paired — open Alien AI → Devices → Remote.", "ok");
    else if (st === "pairing") setStatus("Pairing… complete the code in the Alien AI app.", "warn");
    else if (st === "error") setStatus("Pair error: " + (err || "unknown"), "err");
    else setStatus("Not paired. Click Pair device after native host is installed.", "");
  });
};

btnPing.addEventListener("click", () => {
  chrome.runtime.sendMessage({ type: "native.ping" }, (res) => {
    if (chrome.runtime.lastError) {
      setStatus("Extension error: " + chrome.runtime.lastError.message, "err");
      return;
    }
    setStatus(res?.ok ? "Native host connected." : "Native host not reachable. Install alienai_remote_browser + host manifest.", res?.ok ? "ok" : "err");
  });
});

btnPair.addEventListener("click", () => {
  chrome.runtime.sendMessage({ type: "pair.start" }, () => {
    setStatus("Starting pair… watch for a tab with your code.", "warn");
    refreshPairState();
  });
});

chrome.storage.onChanged.addListener((changes, area) => {
  if (area === "local" && (changes.pairState || changes.pairError)) refreshPairState();
});

chrome.runtime.sendMessage({ type: "native.ping" }, (res) => {
  if (res?.ok) setStatus("Native host OK. Pair when ready.", "ok");
  else setStatus("Install native messaging host (see Install help).", "warn");
  refreshPairState();
});