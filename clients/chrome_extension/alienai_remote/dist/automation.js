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

/** ePus list search via stable form names (typeName / typeSearch / typeSearchValue / birthDate). */
const epusSearchBySelectors = async (tabId, query, searchBy) => {
  const mode = String(searchBy || "nama").toLowerCase();
  const typeSearch = mode === "kartu" || mode === "penjamin" || mode === "nik";
  const q = String(query || "").trim();
  if (!q) throw new Error("text required for epus search");
  if (typeSearch) {
    await execInTab(tabId, () => {
      const sel = document.querySelector('select[name="typeSearch"]');
      if (!sel) return { ok: false, reason: "no typeSearch select" };
      const opts = Array.from(sel.options || []);
      const qDigits = q.replace(/\D/g, "");
      const prefer = qDigits.length >= 10 ? "nik_no_asuransi" : "nik";
      let hit =
        opts.find((o) => String(o.value || "").toLowerCase() === prefer) ||
        opts.find((o) => /asuransi|nik_no/i.test(`${o.value || ""} ${o.text || ""}`));
      if (!hit) return { ok: false, reason: "no dropdown option" };
      sel.value = hit.value;
      sel.dispatchEvent(new Event("change", { bubbles: true }));
      return { ok: true, dropdown: hit.value };
    });
    await execInTab(tabId, actFill, ['input[name="typeName"]', ""]);
    await execInTab(tabId, actFill, ['input[name="birthDate"]', ""]);
    await execInTab(tabId, actFill, ['input[name="typeSearchValue"]', q]);
  } else {
    await execInTab(tabId, actFill, ['input[name="typeSearchValue"]', ""]);
    await execInTab(tabId, actFill, ['input[name="birthDate"]', ""]);
    await execInTab(tabId, actFill, ['input[name="typeName"]', q]);
  }
  const cariMeta = await execInTab(tabId, () => {
    const cari = Array.from(document.querySelectorAll("button, a, input[type=button], input[type=submit]")).find(
      (el) => /^cari$/i.test((el.textContent || el.value || "").trim())
    );
    if (cari) cari.click();
    const nikEl = document.querySelector('input[name="typeSearchValue"]');
    const tglEl = document.querySelector('input[name="birthDate"]');
    return {
      ok: true,
      cari: !!cari,
      type_search_value: (nikEl?.value || "").slice(0, 40),
      birth_date_value: (tglEl?.value || "").slice(0, 40),
    };
  });
  return {
    ok: true,
    search_by: mode,
    type_search: typeSearch,
    query: q,
    input: typeSearch ? "typeSearchValue" : "typeName",
    ...cariMeta,
  };
};

/** Legacy in-page search (kept for reference); prefer epusSearchBySelectors. */
const epusPasienSearchInPage = (query, searchBy) => {
  const setVal = (el, v) => {
    el.focus();
    el.value = v;
    el.dispatchEvent(new Event("input", { bubbles: true }));
    el.dispatchEvent(new Event("change", { bubbles: true }));
  };
  const clear = (el) => {
    if (el) setVal(el, "");
  };
  const isPenjaminValue = (el) => {
    const n = `${el.name || ""} ${el.id || ""}`.toLowerCase();
    return n.includes("typesearchvalue") || n.includes("typetypesearchvalue");
  };
  const isNikPenjaminPh = (el) => /cari\s*(nik\s*\/\s*no\s*asuransi|nik|no\s*asuransi)/i.test(el.placeholder || "");
  const isCariNamaPh = (el) => /cari\s*nama/i.test(el.placeholder || "");
  const isTglLahir = (el) => {
    const ph = (el.placeholder || "").toLowerCase();
    const typ = String(el.type || "").toLowerCase();
    const aria = (el.getAttribute("aria-label") || "").toLowerCase();
    return /cari\s*tanggal|tanggal\s*lahir/i.test(ph) || /tanggal\s*lahir/i.test(aria) || typ === "date";
  };
  const visibleInputs = (sel = "input[type=text], input:not([type]), textarea") =>
    Array.from(document.querySelectorAll(sel)).filter((el) => el.offsetParent !== null);
  const inputs = () => visibleInputs();
  const tanggalEl = (list) => {
    const fromList = (list || inputs()).find((el) => isTglLahir(el));
    if (fromList) return fromList;
    return document.querySelector(
      'input[type=date], input[placeholder*="Tanggal" i], input[placeholder*="tanggal lahir" i]'
    );
  };
  const cariNamaEl = (list) => {
    const byPh = list.find((el) => /cari\s*nama/i.test(el.placeholder || ""));
    if (byPh) return byPh;
    const byName = list.find(
      (el) => /typename/i.test(`${el.name || ""} ${el.id || ""}`) && !isPenjaminValue(el)
    );
    if (byName) return byName;
    const byPos = list
      .filter((el) => !isPenjaminValue(el) && !isTglLahir(el))
      .map((el) => ({ el, r: el.getBoundingClientRect() }))
      .filter((x) => x.r.width > 8 && x.r.height > 8)
      .sort((a, b) => a.r.top - b.r.top || a.r.left - b.r.left);
    return byPos[0]?.el || null;
  };
  const nikPenjaminEl = (list) => {
    const visible = (list || inputs()).filter((el) => !isTglLahir(el));
    const byPh = visible.find((el) => isNikPenjaminPh(el));
    if (byPh) return byPh;
    const byName = visible.find((el) => isPenjaminValue(el));
    if (byName) return byName;
    const tgl = tanggalEl(list);
    if (tgl) {
      const tr = tgl.getBoundingClientRect();
      const nama = cariNamaEl(list);
      const leftOfTgl = visible
        .filter((el) => el !== nama && !isCariNamaPh(el))
        .map((el) => ({ el, r: el.getBoundingClientRect() }))
        .filter(
          (x) =>
            x.r.width > 8 &&
            x.r.height > 8 &&
            Math.abs(x.r.top - tr.top) < 48 &&
            x.r.right <= tr.left + 4 &&
            !isTglLahir(x.el)
        )
        .sort((a, b) => b.r.left - a.r.left);
      if (leftOfTgl[0]) return leftOfTgl[0].el;
    }
    return (
      document.querySelector(
        'input[name="typeSearchValue"], input[name*="typeSearchValue" i]:not([type=date]), input[name*="typeTypeSearchValue" i]:not([type=date])'
      ) || null
    );
  };
  const ensureTypeSearchDropdown = (mode, query) => {
    const sel = document.querySelector(
      'select[name="typeSearch"], select[name*="typeTypeSearch" i], select[id*="typeTypeSearch" i], select[name*="typetypesearch" i]'
    );
    if (!sel) return false;
    const opts = Array.from(sel.options || []);
    const m = String(mode || "").toLowerCase();
    const qDigits = String(query || "").replace(/\D/g, "");
    const asuransiQ = qDigits.length >= 10;
    let hit = null;
    if (m === "nik" && !asuransiQ) {
      hit = opts.find((o) => {
        const v = `${o.value || ""}`.toLowerCase();
        const t = `${o.text || ""}`.toLowerCase();
        return v === "nik" || /^\s*nik\s*$/i.test(t);
      });
    }
    if (!hit && (m === "nik" || m === "kartu" || m === "penjamin" || asuransiQ)) {
      hit = opts.find((o) => {
        const v = `${o.value || ""}`.toLowerCase();
        const t = `${o.text || ""}`.toLowerCase();
        return v.includes("asuransi") || v.includes("nik_no") || t.includes("asuransi") || t.includes("penjamin");
      });
    }
    if (!hit) {
      hit = opts.find((o) => {
        const v = `${o.value || ""}`.toLowerCase();
        const t = `${o.text || ""}`.toLowerCase();
        return v.includes("nik") || v.includes("asuransi") || t.includes("nik") || t.includes("asuransi");
      });
    }
    if (!hit) return false;
    sel.value = hit.value;
    sel.dispatchEvent(new Event("change", { bubbles: true }));
    return true;
  };
  const mode = String(searchBy || "nama").toLowerCase();
  const typeSearch = mode === "kartu" || mode === "penjamin" || mode === "nik";
  let pick = null;
  if (typeSearch) {
    ensureTypeSearchDropdown(mode, query);
    const all = inputs();
    const tgl = tanggalEl(all);
    const nama = cariNamaEl(all);
    pick = nikPenjaminEl(all);
    if (!pick || isTglLahir(pick) || isCariNamaPh(pick)) throw new Error("NIK / No Asuransi input not found");
    all.forEach((el) => {
      if (el === pick) return;
      clear(el);
    });
    if (tgl && tgl !== pick) clear(tgl);
    if (nama && nama !== pick) clear(nama);
  } else {
    const all = inputs();
    const nama = cariNamaEl(all);
    const nik = nikPenjaminEl(all);
    if (!nama) throw new Error("Cari Nama input not found");
    all.forEach((el) => {
      if (el !== nama) clear(el);
    });
    if (nik) clear(nik);
    pick = nama;
  }
  if (!pick) throw new Error("no search input found");
  if (typeSearch && (isTglLahir(pick) || isCariNamaPh(pick))) throw new Error("refusing wrong search input");
  if (!typeSearch && isTglLahir(pick)) throw new Error("refusing Cari Tanggal lahir input");
  setVal(pick, query);
  const cari = Array.from(document.querySelectorAll("button, a, input[type=button], input[type=submit]")).find(
    (el) => /^cari$/i.test((el.textContent || el.value || "").trim())
  );
  if (cari) cari.click();
  return {
    ok: true,
    search_by: mode,
    input: pick.placeholder || pick.name || pick.id || "input",
    input_is_nik: isPenjaminValue(pick) || isNikPenjaminPh(pick),
    refused_tanggal: isTglLahir(pick),
    type_search: typeSearch,
    dropdown_mode: mode,
    value_set: String(pick.value || ""),
    cari: !!cari,
  };
};

/** Pick one grid row before dblclick — exact name cell + no kartu when duplicates share a name. */
const epusPasienFetchInPage = async (
  query,
  openDetail,
  waitMs,
  cariClicked,
  expectedName,
  expectedKartu
) => {
  const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
  const normKey = (s) =>
    String(s || "")
      .trim()
      .toLowerCase()
      .replace(/\s+/g, " ")
      .replace(/[^a-z0-9 ]/g, "");
  const rowCells = (rowEl) => {
    const cells = Array.from(rowEl.querySelectorAll("td, .x-grid-cell, .ag-cell, [role=gridcell]"))
      .map((c) => (c.textContent || "").trim())
      .filter(Boolean);
    if (cells.length) return cells;
    return (rowEl.textContent || "")
      .trim()
      .split(/\s{2,}|\t/)
      .map((s) => s.trim())
      .filter(Boolean);
  };
  const digits = (s) => String(s || "").replace(/\D/g, "");
  const kartuNorm = (d) => {
    const x = digits(d);
    return x.replace(/^0+/, "") || x;
  };
  const kartuExactInRow = (rowEl, kartu) => {
    const k = digits(kartu);
    if (!k) return false;
    const want = kartuNorm(k);
    for (const c of rowCells(rowEl)) {
      const d = digits(c);
      if (!d) continue;
      if (d === k || kartuNorm(d) === want) return true;
    }
    return false;
  };
  const kartuMatch = (hay, kartu) => {
    const k = digits(kartu);
    if (!k) return false;
    const h = digits(hay);
    if (!h) return false;
    const kTrim = kartuNorm(k);
    return h.includes(k) || h.includes(kTrim);
  };
  const nameExact = (cells, name) => {
    const want = normKey(name);
    if (!want) return false;
    return cells.some((c) => normKey(c) === want);
  };
  const pickResultRow = (dataRows, q, expName, expKartu) => {
    if (!dataRows?.length) return { row: null, ambiguous: false, matches: 0 };
    const kartu = digits(expKartu) || (/^\d{8,}$/.test(digits(q)) ? digits(q) : "");
    const name = String(expName || "").trim() || (kartu ? "" : String(q || "").trim());
    if (kartu) {
      const exactRows = dataRows.filter((r) => kartuExactInRow(r, kartu));
      if (exactRows.length === 1) {
        return { row: exactRows[0], ambiguous: false, matches: dataRows.length };
      }
      if (exactRows.length > 1) dataRows = exactRows;
      const rowHay = (r) => `${rowCells(r).join(" ")} ${(r.textContent || "").trim()}`;
      const withKartu = dataRows.filter((r) => kartuMatch(rowHay(r), kartu));
      if (withKartu.length === 1) {
        return { row: withKartu[0], ambiguous: false, matches: dataRows.length };
      }
      if (withKartu.length > 1) dataRows = withKartu;
    }
    const scored = dataRows.map((row) => {
      const cells = rowCells(row);
      const text = cells.join(" ") || (row.textContent || "").trim();
      let score = 0;
      if (kartu && kartuMatch(text, kartu)) score += 100;
      if (name && nameExact(cells, name)) score += 80;
      else if (name && normKey(text).includes(normKey(name))) score += 15;
      return { row, score, cells, text };
    });
    scored.sort((a, b) => b.score - a.score);
    const best = scored[0];
    if (!best || best.score <= 0) {
      return { row: null, ambiguous: dataRows.length > 1, matches: dataRows.length };
    }
    const ties = scored.filter((s) => s.score === best.score);
    if (ties.length === 1) return { row: best.row, ambiguous: false, matches: dataRows.length };
    if (kartu) {
      const byKartu = ties.filter((s) => kartuMatch(s.text, kartu));
      if (byKartu.length === 1) return { row: byKartu[0].row, ambiguous: false, matches: dataRows.length };
    }
    if (name) {
      const byName = ties.filter((s) => nameExact(s.cells, name));
      if (byName.length === 1) return { row: byName[0].row, ambiguous: false, matches: dataRows.length };
    }
    return { row: null, ambiguous: true, matches: dataRows.length };
  };

  const bodyText = document.body?.innerText || "";
  if (/data\s+tidak\s+ditemukan/i.test(bodyText)) {
    return {
      ok: false,
      not_found: true,
      query,
      searched: true,
      cari: cariClicked,
      row_opened: false,
      fields: {},
      url: location.href,
      title: document.title || "",
    };
  }
  const rowSelectors = [
    ".x-grid-item-container .x-grid-item",
    ".ag-center-cols-container .ag-row",
    "table tbody tr",
    '[role="row"]',
  ];
  let dataRows = [];
  for (const sel of rowSelectors) {
    const rows = Array.from(document.querySelectorAll(sel)).filter((el) => el.offsetParent !== null);
    dataRows = rows.filter((r) => {
      const t = (r.textContent || "").trim();
      if (t.length < 4) return false;
      if (/tidak\s+ditemukan/i.test(t)) return false;
      if (/^(no|nama|#)/i.test(t) && t.length < 40) return false;
      return true;
    });
    if (dataRows.length) break;
  }
  const pick = pickResultRow(dataRows, query, expectedName, expectedKartu);
  const row = pick.row;
  if (openDetail && dataRows.length && !row) {
    return {
      ok: false,
      ambiguous: !!pick.ambiguous,
      not_found: false,
      query,
      expected_name: expectedName,
      expected_kartu: expectedKartu,
      matches: pick.matches,
      searched: true,
      cari: cariClicked,
      row_opened: false,
      fields: {},
      url: location.href,
      title: document.title || "",
    };
  }
  if (openDetail && row) {
    row.scrollIntoView({ block: "center", inline: "center" });
    row.dispatchEvent(new MouseEvent("dblclick", { bubbles: true, cancelable: true, view: window }));
    await sleep(Math.min(waitMs, 2800));
  }
  const fields = {};
  const alias = {
    alamat: ["alamat", "alamat lengkap", "alamat domisili"],
    dusun: ["dusun", "kampung", "lingkungan"],
    rt: ["rt"],
    rw: ["rw"],
    desa: ["desa", "kelurahan"],
    kecamatan: ["kecamatan"],
    faskes: ["faskes", "puskesmas", "pkm", "tempat pelayanan"],
    nama: ["nama", "nama pasien", "nama lengkap"],
    no_kartu: ["no kartu", "no. kartu", "nomor kartu", "no kartu bpjs", "no bpjs"],
    no_telp: ["no telp", "telepon", "hp", "no hp"],
    usia: ["usia", "umur"],
  };
  const put = (key, val) => {
    const v = String(val || "").trim();
    if (!v || fields[key]) return;
    fields[key] = v;
  };
  const labelNodes = Array.from(
    document.querySelectorAll("dt, th, label, .form-label, .x-form-item-label, td.label, .control-label")
  );
  for (const labelEl of labelNodes) {
    const raw = (labelEl.textContent || "").replace(/[:\s]+$/g, "").trim();
    const nk = normKey(raw);
    if (!nk) continue;
    let val = "";
    const sib = labelEl.nextElementSibling;
    if (sib) val = (sib.textContent || "").trim();
    if (!val && labelEl.parentElement) {
      const inp = labelEl.parentElement.querySelector("input, textarea, select");
      if (inp) val = (inp.value || inp.textContent || "").trim();
    }
    for (const [out, keys] of Object.entries(alias)) {
      if (keys.some((k) => nk === normKey(k) || nk.includes(normKey(k)))) put(out, val);
    }
  }
  const body = document.body?.innerText || "";
  const linePick = (re) => {
    const m = body.match(re);
    return m ? m[1].trim() : "";
  };
  if (!fields.alamat) put("alamat", linePick(/alamat(?:\s+lengkap)?\s*[:\n]\s*([^\n]+)/i));
  if (!fields.dusun) put("dusun", linePick(/dusun\s*[:\n]\s*([^\n]+)/i));
  if (!fields.rt) put("rt", linePick(/\bRT\s*[:\/]\s*([0-9'\"]+)/i));
  if (!fields.rw) put("rw", linePick(/\bRW\s*[:\/]\s*([0-9'\"]+)/i));
  if (!fields.desa) put("desa", linePick(/desa\s*[:\n]\s*([^\n]+)/i));
  if (!fields.kecamatan) put("kecamatan", linePick(/kecamatan\s*[:\n]\s*([^\n]+)/i));
  if (!fields.faskes) put("faskes", linePick(/(?:faskes|puskesmas|pkm)\s*[:\n]\s*([^\n]+)/i));
  return {
    ok: true,
    query,
    searched: true,
    cari: cariClicked,
    row_opened: !!(openDetail && row),
    fields,
    url: location.href,
    title: document.title || "",
  };
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
    const proto =
      el instanceof HTMLTextAreaElement
        ? HTMLTextAreaElement.prototype
        : HTMLInputElement.prototype;
    const setter = Object.getOwnPropertyDescriptor(proto, "value")?.set;
    if (setter) setter.call(el, value);
    else el.value = value;
    el.dispatchEvent(new InputEvent("input", { bubbles: true, data: value, inputType: "insertText" }));
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

const setInputValue = (el, value) => {
  const v = value == null ? "" : String(value);
  const setter = Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, "value")?.set;
  if (setter) setter.call(el, v);
  else el.value = v;
  el.dispatchEvent(new InputEvent("input", { bubbles: true, data: v, inputType: "insertText" }));
  el.dispatchEvent(new Event("change", { bubbles: true }));
};

const clickExactText = (needle, root = document) => {
  const n = needle.toLowerCase();
  const nodes = Array.from(root.querySelectorAll("button, a, input[type=button], input[type=submit], span"));
  const hit = nodes.find((el) => (el.textContent || "").trim().toLowerCase() === n);
  if (!hit) throw new Error(`text not found: ${needle}`);
  hit.click();
  return hit;
};

const dialogRoot = () => document.querySelector("[role=dialog]") || document.body;

const clickDialogButton = (label) => {
  const dialog = dialogRoot();
  const btn = Array.from(dialog.querySelectorAll("button")).find(
    (b) => (b.textContent || "").trim() === label
  );
  if (!btn) throw new Error(`${label} button not found in dialog`);
  btn.click();
  return { ok: true };
};

const listItemsIn = (root) => {
  const fromRole = Array.from(root.querySelectorAll("mat-list-option, [role=listitem], mat-list-item"));
  if (fromRole.length) return fromRole;
  const fromChecks = Array.from(root.querySelectorAll('[role="checkbox"]'))
    .map((cb) => cb.closest("mat-list-option, [role=listitem], mat-list-item, li, div") || cb.parentElement)
    .filter(Boolean);
  return fromChecks.filter((el, i, arr) => arr.indexOf(el) === i);
};

const checkboxIn = (row) =>
  row.querySelector('[role="checkbox"], mat-pseudo-checkbox, input[type="checkbox"]') || row;

const rowChecked = (row) => {
  if (!row) return false;
  if (row.getAttribute?.("aria-selected") === "true") return true;
  const cb = row.querySelector('[role="checkbox"]');
  const v = cb?.getAttribute("aria-checked");
  if (v === "true") return true;
  if (v === "false") return false;
  const input = row.querySelector('input[type="checkbox"]');
  if (input) return input.checked;
  if (row.classList?.contains("mat-list-option-selected")) return true;
  return false;
};

const toggleCheckboxRow = (row, wantChecked) => {
  if (rowChecked(row) === wantChecked) return;
  const target = checkboxIn(row);
  target.click();
  if (rowChecked(row) !== wantChecked) row.click();
};

/** Play Console: limit base plan to one country (Manage country / region availability). */
export const playRestrictAvailability = async (tabId, countryName) => {
  const name = String(countryName || "").trim();
  if (!name) throw new Error("country required");
  await execInTab(tabId, () => {
    if (!document.querySelector("[role=dialog]")) {
      const hit = Array.from(document.querySelectorAll("a, button, span, label")).find((el) =>
        (el.textContent || "").includes("Manage country / region availability")
      );
      if (!hit) throw new Error("Manage country / region availability not found");
      hit.click();
    }
    return { ok: true };
  });
  await new Promise((r) => setTimeout(r, 2000));
  const applyResult = await execInTab(tabId, (country) => {
    const dialog = document.querySelector("[role=dialog]");
    if (!dialog) throw new Error("availability dialog not found");
    const search =
      dialog.querySelector('input[aria-label="Search"]') ||
      dialog.querySelector('input[aria-label*="Search" i]');
    if (!search) throw new Error("availability search not found");
    setInputValue(search, country);
    const waitRows = () => {
      const items = listItemsIn(dialog).filter((row) => {
        const t = (row.textContent || "").replace(/\s+/g, " ").trim();
        return !/\d+\s+countries\s*\/\s*regions/i.test(t);
      });
      return items;
    };
    let rows = waitRows();
    rows = waitRows().filter((r) => (r.textContent || "").includes(country));
    if (!rows.length) throw new Error(`country not visible after search: ${country}`);
    const master = listItemsIn(dialog).find((el) =>
      /\d+\s+countries\s*\/\s*regions/i.test(el.textContent || "")
    );
    if (master && rowChecked(master)) {
      toggleCheckboxRow(master, false);
    }
    for (const row of waitRows()) {
      const t = (row.textContent || "").replace(/\s+/g, " ").trim();
      const isTarget = t === country || t.endsWith(` ${country}`);
      toggleCheckboxRow(row, isTarget);
    }
    const selected = waitRows().filter((row) => rowChecked(row)).length;
    if (selected !== 1) {
      throw new Error(`expected 1 country selected after filter, got ${selected}`);
    }
    clickDialogButton("Apply");
    if (document.querySelector("[role=dialog]")) {
      throw new Error("availability dialog still open after Apply");
    }
    return { ok: true, country, selected_count: selected };
  }, [name]);
  await new Promise((r) => setTimeout(r, 2000));
  return { ok: true, country: name, build: 51, ...applyResult };
};

/** Sticky footer Save on Play Console forms. */
export const playClickSave = async (tabId) => {
  return execInTab(tabId, () => {
    const saves = Array.from(document.querySelectorAll("button")).filter(
      (b) => (b.textContent || "").trim() === "Save"
    );
    if (!saves.length) throw new Error("Save button not found");
    const save = saves[saves.length - 1];
    save.scrollIntoView({ block: "center" });
    save.click();
    return { ok: true, count: saves.length };
  });
};

/** Read Play Console validation / snackbar errors after Save. */
export const playConsoleErrors = async (tabId) => {
  return execInTab(tabId, () => {
    const alerts = Array.from(document.querySelectorAll("mat-error, [role=alert], simple-snack-bar"))
      .map((el) => (el.textContent || "").replace(/\s+/g, " ").trim())
      .filter((t) => t.length > 0 && t.length < 300);
    const banner = Array.from(document.querySelectorAll(".error-message, [class*='error-banner']"))
      .map((el) => (el.textContent || "").replace(/\s+/g, " ").trim())
      .filter(Boolean);
    const errors = [...new Set([...alerts, ...banner])].slice(0, 20);
    const body = document.body.innerText || "";
    const save_failed = /couldn't be saved/i.test(body);
    const regionErr = /countries \/ regions have an error/i.test(body);
    const setPriceRows = Array.from(document.querySelectorAll("mat-row, tr[role=row], tr")).filter((row) =>
      /set a price/i.test(row.textContent || "")
    ).length;
    const indoRow = Array.from(document.querySelectorAll("mat-row, tr[role=row], tr")).find((row) =>
      (row.textContent || "").includes("Indonesia")
    );
    const indoText = (indoRow?.textContent || "").replace(/\s+/g, " ");
    const indonesia_price_missing = !indoRow || /\bIndonesia\b[\s\S]{0,40}\-\b/.test(indoText);
    return {
      ok: true,
      errors,
      region_error: regionErr,
      set_price_row_count: setPriceRows,
      indonesia_price_missing,
      save_failed,
    };
  });
};

/** Dismiss Play Console bottom sheets / dialogs (Cancel). */
export const playDismissOverlays = async (tabId) => {
  return execInTab(tabId, () => {
    const cancels = Array.from(document.querySelectorAll("button")).filter(
      (b) => (b.textContent || "").trim() === "Cancel"
    );
    for (const btn of cancels) btn.click();
    return { ok: true, cancelled: cancels.length };
  });
};

/** Set price for one country via row link (search table first). */
export const playSetCountryPriceInline = async (tabId, country, amount) => {
  const c = String(country || "").trim();
  const amt = String(amount || "").trim();
  if (!c || !amt) throw new Error("country and amount required");
  await playDismissOverlays(tabId);
  await new Promise((r) => setTimeout(r, 400));
  await execInTab(
    tabId,
    (name) => {
      const search = document.querySelector('input[aria-label="Search country or region by name"]');
      if (!search) throw new Error("country search input not found");
      setInputValue(search, name);
      return { ok: true };
    },
    [c]
  );
  await new Promise((r) => setTimeout(r, 1200));
  await execInTab(
    tabId,
    (name) => {
      const visible = (el) => {
        const r = el.getBoundingClientRect();
        return r.height > 2 && r.width > 2;
      };
      const row = Array.from(document.querySelectorAll("mat-row, tr[role=row], tr")).find(
        (r) => visible(r) && (r.textContent || "").includes(name)
      );
      if (!row) throw new Error(`country row not found: ${name}`);
      const setLink = Array.from(row.querySelectorAll("a, button, span, label, [role=button]")).find(
        (el) => (el.textContent || "").trim().toLowerCase() === "set a price"
      );
      if (!setLink) throw new Error(`Set a price link missing for ${name}`);
      setLink.click();
      return { ok: true };
    },
    [c]
  );
  await new Promise((r) => setTimeout(r, 1200));
  await execInTab(
    tabId,
    (price) => {
      const dialog = document.querySelector("[role=dialog]");
      if (!dialog) throw new Error("price dialog not found");
      const priceIn =
        dialog.querySelector('input[aria-label="New price in IDR"]') ||
        dialog.querySelector('input[aria-label*="price" i]') ||
        dialog.querySelector('input[aria-label*="IDR" i]') ||
        Array.from(dialog.querySelectorAll("input[type=text], input:not([type])")).find((inp) => {
          const al = (inp.getAttribute("aria-label") || "").toLowerCase();
          return al.includes("price") || al.includes("idr");
        });
      if (!priceIn) throw new Error("price input not found in dialog");
      setInputValue(priceIn, price);
      return { ok: true };
    },
    [amt]
  );
  await new Promise((r) => setTimeout(r, 400));
  await execInTab(tabId, () => clickDialogButton("Apply"));
  await new Promise((r) => setTimeout(r, 1000));
  return { ok: true, country: c, amount: amt };
};

/** Play Console base-plan / IAP regional price (bulk Set prices flow). */
export const playSetCountryPrice = async (tabId, country, amount) => {
  const c = String(country || "").trim();
  const amt = String(amount || "").trim();
  if (!c || !amt) throw new Error("country and amount required");
  await execInTab(
    tabId,
    (name) => {
      const search = document.querySelector('input[aria-label="Search country or region by name"]');
      if (!search) throw new Error("country search input not found");
      setInputValue(search, name);
      return { ok: true };
    },
    [c]
  );
  await new Promise((r) => setTimeout(r, 1200));
  let bulk = false;
  try {
    await execInTab(
      tabId,
      (name) => {
        const visible = (el) => {
          const r = el.getBoundingClientRect();
          return r.height > 2 && r.width > 2;
        };
        const row = Array.from(document.querySelectorAll("mat-row, tr[role=row], tr")).find(
          (r) => visible(r) && (r.textContent || "").includes(name)
        );
        if (!row) throw new Error(`country row not found: ${name}`);
        const setLink = Array.from(
          row.querySelectorAll("a, button, span, label, div, [role=button], mat-cell")
        ).find((el) => (el.textContent || "").trim().toLowerCase() === "set a price");
        if (setLink) {
          setLink.click();
          return { ok: true, mode: "row-link" };
        }
        const cell = row.querySelector("mat-cell:nth-child(2), td:nth-child(2)") || row;
        const btn = cell.querySelector("button, a, [role=button]");
        if (btn) btn.click();
        else cell.click();
        return { ok: true, mode: "row-cell" };
      },
      [c]
    );
  } catch {
    bulk = true;
    await execInTab(tabId, () => {
      clickExactText("Set prices");
      return { ok: true };
    });
    await new Promise((r) => setTimeout(r, 700));
    await execInTab(
      tabId,
      (name) => {
        const row = Array.from(document.querySelectorAll("mat-row")).find((r) =>
          (r.textContent || "").includes(name)
        );
        if (!row) throw new Error(`country row not found: ${name}`);
        const cb = row.querySelector("mat-checkbox, input[type=checkbox]");
        if (cb) cb.click();
        else row.click();
        return { ok: true };
      },
      [c]
    );
    await new Promise((r) => setTimeout(r, 400));
    await execInTab(tabId, () => {
      clickExactText("Set price");
      return { ok: true };
    });
    await new Promise((r) => setTimeout(r, 700));
  }
  await execInTab(
    tabId,
    (price) => {
      const dialog = document.querySelector("[role=dialog]") || document.body;
      const inDialog = (sel) => dialog.querySelector(sel);
      const priceIn =
        inDialog('input[aria-label="New price in IDR"]') ||
        inDialog('input[aria-label*="price" i]') ||
        inDialog('input[aria-label*="IDR" i]') ||
        Array.from(dialog.querySelectorAll("input[type=text], input:not([type])")).find(
          (inp) => {
            const al = (inp.getAttribute("aria-label") || "").toLowerCase();
            return al.includes("price") || al.includes("idr");
          }
        );
      if (!priceIn) throw new Error("price input not found");
      setInputValue(priceIn, price);
      priceIn.blur();
      return { ok: true };
    },
    [amt]
  );
  await new Promise((r) => setTimeout(r, 500));
  await execInTab(tabId, () => {
    const dialog = document.querySelector("[role=dialog]");
    if (!dialog) throw new Error("price dialog not found after row click");
    const labels = ["Apply", "Save", "Update"];
    for (const label of labels) {
      try {
        clickExactText(label, dialog);
        return { ok: true, dialog_action: label };
      } catch {
        /* try next */
      }
    }
    throw new Error("no Apply/Save in price dialog");
  });
  await new Promise((r) => setTimeout(r, 800));
  return { ok: true, country: c, amount: amt };
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
  const needsSelector = ![
    "list_inputs",
    "click_text",
    "click_text_contains",
    "select_country",
    "play_set_country_price",
    "play_fill_dialog_price",
    "play_dialog_apply",
    "play_restrict_availability",
    "play_click_save",
    "play_console_errors",
    "play_dismiss_overlays",
    "play_set_country_price_inline",
    "goto",
    "epus_pasien_search",
    "epus_pasien_fetch",
  ].includes(action);
  if (needsSelector && !selector) throw new Error("selector required");
  const tabId = await resolveTabId(params);
  const tab = await chrome.tabs.get(tabId);
  if (tab.url?.startsWith("chrome://") || tab.url?.startsWith("chrome-extension://")) {
    throw new Error("permission denied for restricted page");
  }
  const focusTab = params.focus !== false && params.activate !== false;
  if (focusTab) await chrome.tabs.update(tabId, { active: true });
  switch (action) {
    case "click":
      return execInTab(tabId, actClick, [selector]);
    case "fill":
      return execInTab(tabId, actFill, [selector, params.text ?? ""]);
    case "press":
      return execInTab(tabId, actPress, [selector, params.text ?? ""]);
    case "list_inputs":
      return execInTab(tabId, () =>
        Array.from(document.querySelectorAll("input, textarea, select")).map((el, i) => ({
          i,
          tag: el.tagName.toLowerCase(),
          id: el.id || "",
          name: el.name || "",
          type: el.type || "",
          placeholder: el.placeholder || "",
          aria: el.getAttribute("aria-label") || "",
          value: (el.value || "").slice(0, 80),
        }))
      );
    case "click_text": {
      const label = String(params.text ?? params.label ?? "").trim();
      if (!label) throw new Error("text required for click_text");
      return execInTab(tabId, (needle) => {
        const n = needle.toLowerCase();
        const nodes = Array.from(document.querySelectorAll("button, a, input[type=button], input[type=submit], span"));
        const hit = nodes.find((el) => (el.textContent || "").trim().toLowerCase() === n);
        if (!hit) throw new Error(`click_text not found: ${needle}`);
        hit.click();
        return { ok: true };
      }, [label]);
    }
    case "click_text_contains": {
      const label = String(params.text ?? params.label ?? "").trim();
      if (!label) throw new Error("text required for click_text_contains");
      return execInTab(tabId, (needle) => {
        const n = needle.toLowerCase();
        const nodes = Array.from(
          document.querySelectorAll("button, a, input[type=button], input[type=submit], span, label")
        );
        const hit = nodes.find((el) => (el.textContent || "").trim().toLowerCase().includes(n));
        if (!hit) throw new Error(`click_text_contains not found: ${needle}`);
        hit.click();
        return { ok: true };
      }, [label]);
    }
    case "play_set_country_price": {
      let country = params.country ?? params.text ?? "";
      let amount = params.amount ?? params.price ?? "";
      const combo = String(country).trim();
      if (combo.includes("|")) {
        const [c, a] = combo.split("|").map((s) => s.trim());
        country = c;
        if (!String(amount).trim()) amount = a;
      }
      return playSetCountryPrice(tabId, country, amount);
    }
    case "play_dialog_apply":
      return execInTab(tabId, () => clickDialogButton("Apply"));
    case "play_restrict_availability":
      return playRestrictAvailability(tabId, params.text ?? params.country ?? "");
    case "play_click_save":
      return playClickSave(tabId);
    case "play_console_errors":
      return playConsoleErrors(tabId);
    case "play_dismiss_overlays":
      return playDismissOverlays(tabId);
    case "play_set_country_price_inline": {
      let country = params.country ?? params.text ?? "";
      let amount = params.amount ?? params.price ?? "";
      const combo = String(country).trim();
      if (combo.includes("|")) {
        const [c, a] = combo.split("|").map((s) => s.trim());
        country = c;
        if (!String(amount).trim()) amount = a;
      }
      return playSetCountryPriceInline(tabId, country, amount);
    }
    case "play_fill_dialog_price": {
      const amt = String(params.text ?? params.amount ?? params.price ?? "").trim();
      if (!amt) throw new Error("text (price amount) required");
      return execInTab(
        tabId,
        (price) => {
          const dialog = document.querySelector("[role=dialog]") || document.body;
          const inDialog = (sel) => dialog.querySelector(sel);
          const priceIn =
            inDialog('input[aria-label="New price in IDR"]') ||
            inDialog('input[aria-label*="price" i]') ||
            inDialog('input[aria-label*="IDR" i]') ||
            Array.from(dialog.querySelectorAll("input[type=text], input:not([type])")).find(
              (inp) => {
                const al = (inp.getAttribute("aria-label") || "").toLowerCase();
                return al.includes("price") || al.includes("idr");
              }
            );
          if (!priceIn) throw new Error("price input not found");
          setInputValue(priceIn, price);
          priceIn.blur();
          return { ok: true };
        },
        [amt]
      );
    }
    case "select_country": {
      const country = String(params.text ?? params.country ?? "").trim();
      if (!country) throw new Error("text required for select_country");
      return execInTab(tabId, (name) => {
        const rows = Array.from(
          document.querySelectorAll("mat-row, tr[role=row], tr, [role=row]")
        );
        for (const row of rows) {
          const t = (row.textContent || "").trim();
          if (!t.includes(name)) continue;
          const cb = row.querySelector('input[type="checkbox"]');
          if (cb) {
            cb.click();
            return { ok: true, mode: "checkbox" };
          }
          row.click();
          return { ok: true, mode: "row" };
        }
        throw new Error(`select_country not found: ${name}`);
      }, [country]);
    }
    case "goto": {
      const url = String(params.url ?? params.text ?? "").trim();
      if (!url) throw new Error("url required for goto");
      return execInTab(tabId, (u) => {
        window.location.href = u;
        return { ok: true, url: u };
      }, [url]);
    }
    case "epus_pasien_search": {
      const q = String(params.text ?? "").trim();
      if (!q) throw new Error("text required for epus_pasien_search");
      const searchBy = String(params.search_by ?? params.searchBy ?? "nama");
      return epusSearchBySelectors(tabId, q, searchBy);
    }
    case "epus_pasien_fetch": {
      const q = String(params.text ?? "").trim();
      if (!q) throw new Error("text required for epus_pasien_fetch");
      const searchBy = String(params.search_by ?? params.searchBy ?? "nama");
      const openDetail = params.open_detail !== false;
      const waitMs = Math.min(10_000, Math.max(600, Number(params.wait_ms) || 2400));
      const mode = String(searchBy || "nama").toLowerCase();
      const typeSearch = mode === "kartu" || mode === "penjamin" || mode === "nik";
      await execInTab(tabId, () => {
        const reset = Array.from(document.querySelectorAll("button, a, input[type=button]")).find((el) =>
          /^reset$/i.test((el.textContent || el.value || "").trim())
        );
        if (reset) reset.click();
        return { ok: true };
      });
      await new Promise((r) => setTimeout(r, typeSearch ? 800 : 600));
      const searchMeta = await epusSearchBySelectors(tabId, q, searchBy);
      await new Promise((r) => setTimeout(r, waitMs));
      const cariClicked = !!searchMeta?.cari;
      const expectedName = String(
        params.nama ?? params.expected_name ?? params.name ?? params.expectedName ?? ""
      ).trim();
      const expectedKartu = String(
        params.no_kartu ?? params.expected_kartu ?? params.noKartu ?? params.expectedKartu ?? ""
      ).trim();
      return execInTab(tabId, epusPasienFetchInPage, [
        q,
        openDetail,
        waitMs,
        cariClicked,
        expectedName,
        expectedKartu,
      ]);
    }
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
