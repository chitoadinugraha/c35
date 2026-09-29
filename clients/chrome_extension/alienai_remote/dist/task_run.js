// CE-A5: multi-step browser.task.run for MV3 (subset of Playwright steps.js).

import { navigate, pageAct, pageExtract, resolveTabId } from "./automation.js";

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

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

const waitForSelector = async (tabId, selector, timeoutMs) => {
  const deadline = Date.now() + Math.min(Math.max(Number(timeoutMs) || 30_000, 500), 120_000);
  while (Date.now() < deadline) {
    const found = await execInTab(tabId, (sel) => !!document.querySelector(sel), [selector]);
    if (found) return;
    await sleep(200);
  }
  throw new Error(`timeout waiting for selector: ${selector}`);
};

const stepTabParams = (step, batchTab) => {
  const raw = step.tab_id ?? step.tabId ?? batchTab;
  if (raw == null || String(raw).trim() === "") return {};
  return { tab_id: String(raw) };
};

export const taskRun = async (params = {}) => {
  const steps = Array.isArray(params.steps) ? params.steps : [];
  if (!steps.length) throw new Error("steps must be a non-empty array");

  const defaultTabRaw = params.tab_id ?? params.tabId;
  let batchTab =
    defaultTabRaw != null && String(defaultTabRaw).trim() !== "" ? String(defaultTabRaw) : undefined;
  const out = {};

  for (const step of steps) {
    if (!step || typeof step !== "object") throw new Error("invalid step");
    const op = step.op;
    if (!op) throw new Error("step.op required");

    switch (op) {
      case "tab_activate": {
        const tabId = Number(step.tab_id ?? step.tabId);
        if (!Number.isFinite(tabId)) throw new Error("tab_id required for tab_activate");
        await chrome.tabs.update(tabId, { active: true });
        batchTab = String(tabId);
        break;
      }
      case "tab_new": {
        const tab = await chrome.tabs.create({ url: step.url || "about:blank" });
        out.last_tab_id = String(tab.id);
        batchTab = String(tab.id);
        break;
      }
      case "tab_close": {
        const tabId = Number(step.tab_id ?? step.tabId ?? batchTab);
        if (!Number.isFinite(tabId)) throw new Error("no tab to close");
        await chrome.tabs.remove(tabId);
        if (batchTab === String(tabId)) batchTab = undefined;
        break;
      }
      case "navigate":
        await navigate({ url: step.url, ...stepTabParams(step, batchTab) });
        break;
      case "click":
        await pageAct({
          action: "click",
          selector: step.selector,
          ...stepTabParams(step, batchTab),
        });
        break;
      case "fill":
        await pageAct({
          action: "fill",
          selector: step.selector,
          text: step.text ?? "",
          ...stepTabParams(step, batchTab),
        });
        break;
      case "extract": {
        const chunk = await pageExtract({
          selector: step.selector,
          as: step.as,
          ...stepTabParams(step, batchTab),
        });
        Object.assign(out, chunk);
        break;
      }
      case "wait":
        if (step.selector) {
          const tabId = await resolveTabId(stepTabParams(step, batchTab));
          await waitForSelector(tabId, step.selector, step.ms);
        } else if (step.ms) {
          await sleep(Math.min(Math.max(Number(step.ms) || 0, 0), 120_000));
        }
        break;
      default:
        throw new Error(`unknown step op: ${op}`);
    }
  }

  return { result: out };
};
