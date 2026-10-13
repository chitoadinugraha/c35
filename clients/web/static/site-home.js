/** Marketing home: locale URLs (/ vs /id/), switcher, shared UI helpers. */
(function (global) {
  const siteLocale = document.documentElement.getAttribute('data-site-locale') || 'en';
  let currentLang = siteLocale;
  const localeCache = {};

  const isLikelyBot = () => /bot|crawl|spider|slurp|bingpreview|googlebot|yandex|baidu/i.test(
    global.navigator?.userAgent || '',
  );

  async function loadLocale(lang) {
    if (localeCache[lang]) return localeCache[lang];
    try {
      const res = await fetch('/locales/' + lang + '.json');
      if (!res.ok) return null;
      const data = await res.json();
      localeCache[lang] = data;
      return data;
    } catch (_) {
      return null;
    }
  }

  function persistLang(lang) {
    global.localStorage?.setItem('alienai_lang', lang);
    document.cookie = 'alienai_lang=' + lang + '; path=/; max-age=31536000; SameSite=Lax';
  }

  function updateSwitcher(lang) {
    const enBtn = document.getElementById('btnLangEn');
    const idBtn = document.getElementById('btnLangId');
    if (!enBtn || !idBtn) return;
    enBtn.classList.toggle('active', lang === 'en');
    enBtn.classList.toggle('text-slate-400', lang !== 'en');
    idBtn.classList.toggle('active', lang === 'id');
    idBtn.classList.toggle('text-slate-400', lang !== 'id');
  }

  function changeLanguage(lang) {
    persistLang(lang);
    const target = lang === 'id' ? '/id/' : '/';
    if (global.location.pathname.replace(/\/+$/, '') !== target.replace(/\/+$/, '')) {
      global.location.href = target + global.location.search + global.location.hash;
    }
  }

  async function initLang() {
    currentLang = siteLocale;
    document.documentElement.lang = siteLocale;
    persistLang(siteLocale);
    updateSwitcher(siteLocale);
    await loadLocale(siteLocale);

    if (!isLikelyBot()) {
      const resolved = await global.AlienLocale.resolveSiteLang();
      const onId = /^\/id(\/|$)/.test(global.location.pathname);
      if (resolved === 'id' && !onId) {
        global.location.replace('/id/' + global.location.search + global.location.hash);
        return;
      }
      if (resolved === 'en' && onId) {
        global.location.replace('/' + global.location.search + global.location.hash);
      }
    }
  }

  global.changeLanguage = changeLanguage;
  global.siteHomeLocaleCache = localeCache;
  global.siteHomeCurrentLang = () => currentLang;

  global.toggleDropdown = (id, event) => {
    if (event) event.stopPropagation();
    const target = document.getElementById(id);
    if (!target) return;
    const isHidden = target.classList.contains('hidden');
    document.querySelectorAll('.dropdown-panel').forEach((el) => el.classList.add('hidden'));
    if (isHidden) target.classList.remove('hidden');
  };

  global.addEventListener('click', (e) => {
    if (!e.target.closest('.dropdown-panel') && !e.target.closest('button[onclick*="toggleDropdown"]')) {
      document.querySelectorAll('.dropdown-panel').forEach((el) => el.classList.add('hidden'));
    }
  });

  global.loadHeroAppVersion = async () => {
    const wrap = document.getElementById('heroAppVersion');
    const num = document.getElementById('heroAppVersionNum');
    if (!wrap || !num) return;
    try {
      const res = await fetch('/version');
      if (!res.ok) return;
      const data = await res.json();
      const platforms = data.platforms || {};
      let latest = null;
      for (const body of Object.values(platforms)) {
        if (!body?.version) continue;
        if (!latest || body.version > latest.version) latest = body;
      }
      if (!latest?.version) return;
      num.textContent = String(latest.version);
      wrap.classList.remove('hidden');
    } catch (_) {}
  };

  global.showComingSoon = (event) => {
    if (event) event.stopPropagation();
    const label = document.getElementById('autoWebBrowserLabel');
    if (!label) return;
    const dict = localeCache[currentLang] || {};
    const orig = dict['hero.browser'] || label.innerText;
    label.innerText = dict['hero.comingSoon'] || 'Coming Soon';
    setTimeout(() => { label.innerText = orig; }, 2000);
  };

  global.copyPs1Command = (event) => {
    if (event) event.stopPropagation();
    const cmd = 'powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest https://alienai.id/download/agent-update.ps1 -OutFile $env:TEMP\\agent-update.ps1; & $env:TEMP\\agent-update.ps1"';
    global.navigator.clipboard.writeText(cmd).then(() => {
      const badge = document.getElementById('ps1CopyBadge');
      if (!badge) return;
      const dict = localeCache[currentLang] || {};
      const orig = badge.innerText;
      badge.innerText = dict['hero.copied'] || (currentLang === 'id' ? 'Tersalin!' : 'Copied!');
      badge.classList.remove('bg-white/10', 'text-emerald-400');
      badge.classList.add('bg-brand-500', 'text-black', 'font-bold');
      setTimeout(() => {
        badge.innerText = orig;
        badge.classList.remove('bg-brand-500', 'text-black', 'font-bold');
        badge.classList.add('bg-white/10', 'text-emerald-400');
      }, 2000);
    });
  };

  global.initPlatformLanding = function initPlatformLanding() {
    const dropdown = document.getElementById('custom-dropdown');
    const trigger = document.getElementById('dropdown-trigger');
    const selectedText = document.getElementById('selected-version-text');
    const menu = document.getElementById('dropdown-menu');
    const winCard = document.getElementById('card-win');
    const webCard = document.getElementById('card-web');
    const winVerLabel = document.getElementById('win-ver-label');
    const webVerLabel = document.getElementById('web-ver-label');
    const androidVerLabel = document.getElementById('android-ver-label');
    if (!dropdown || !trigger || !menu || !winCard || !webCard) return;

    const PUBLIC_ORIGIN = global.location.origin || 'https://alienai.id';
    const WEB_APP_ORIGIN = 'https://app.alienai.id';
    const windowsUrlByVersion = new Map();
    let versionData = null;
    let selectedVersion = null;
    let latestWebVersion = null;
    let latestAndroidVersion = null;
    let selectedIsLatestRelease = false;

    const latestTag = () => (currentLang === 'id' ? ' (Terbaru)' : ' (Latest)');

    trigger.addEventListener('click', (e) => {
      e.stopPropagation();
      const open = dropdown.classList.toggle('open');
      trigger.setAttribute('aria-expanded', open ? 'true' : 'false');
    });

    global.addEventListener('click', (e) => {
      if (!dropdown.contains(e.target)) {
        dropdown.classList.remove('open');
        trigger.setAttribute('aria-expanded', 'false');
      }
    });

    function formatDate(isoString) {
      if (!isoString) return '';
      try {
        const d = new Date(isoString);
        if (Number.isNaN(d.getTime())) return '';
        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        const hr = String(d.getHours()).padStart(2, '0');
        const min = String(d.getMinutes()).padStart(2, '0');
        return `${months[d.getMonth()]} ${d.getDate()}, ${d.getFullYear()}, ${hr}:${min}`;
      } catch (_) {
        return '';
      }
    }

    function windowsDownloadUrl(version, storeUrl) {
      if (storeUrl && storeUrl.indexOf('objectstorage') !== -1) {
        return `${PUBLIC_ORIGIN}/windows/${version}/AlienAI-${version}.msix`;
      }
      if (storeUrl) {
        return storeUrl.replace(/^https:\/\/app\.alienai\.id/i, PUBLIC_ORIGIN);
      }
      return `${PUBLIC_ORIGIN}/windows/${version}/AlienAI-${version}.msix`;
    }

    function indexWindowsHistory(history) {
      windowsUrlByVersion.clear();
      history
        .filter((item) => item.platform === 'windows')
        .forEach((item) => {
          windowsUrlByVersion.set(item.version, windowsDownloadUrl(item.version, item.url));
        });
    }

    function webHistoryHasVersion(version) {
      if (!versionData || !versionData.history) return false;
      return versionData.history.some((item) => item.platform === 'web' && item.version === version);
    }

    function webLaunchUrl(version) {
      if (selectedIsLatestRelease || (latestWebVersion && version === latestWebVersion)) {
        return `${WEB_APP_ORIGIN}/`;
      }
      if (!webHistoryHasVersion(version)) {
        return '/download/web';
      }
      return `${PUBLIC_ORIGIN}/v/${version}/`;
    }

    function webVersionLabel(version) {
      if (
        selectedIsLatestRelease
        || (latestWebVersion && version === latestWebVersion)
        || !webHistoryHasVersion(version)
      ) {
        return 'v' + (latestWebVersion || version);
      }
      return 'v' + version;
    }

    function updateLinks() {
      if (!selectedVersion) return;
      const winUrl = windowsUrlByVersion.get(selectedVersion)
        || windowsDownloadUrl(selectedVersion, null);
      winCard.href = winUrl;
      if (winVerLabel) winVerLabel.textContent = 'v' + selectedVersion;
      webCard.href = webLaunchUrl(selectedVersion);
      if (webVerLabel) webVerLabel.textContent = webVersionLabel(selectedVersion);
    }

    function bindVersionItem(item, code, isLatest, dateStr) {
      item.addEventListener('click', (e) => {
        e.stopPropagation();
        menu.querySelectorAll('.dropdown-item').forEach((el) => el.classList.remove('selected'));
        item.classList.add('selected');
        selectedVersion = code;
        selectedIsLatestRelease = isLatest;
        selectedText.textContent = `${code}${isLatest ? latestTag() : ''}`;
        dropdown.classList.remove('open');
        trigger.setAttribute('aria-expanded', 'false');
        updateLinks();
      });
      item.className = 'dropdown-item' + (isLatest ? ' selected' : '');
      item.setAttribute('role', 'option');
      item.setAttribute('data-value', String(code));
      const suffix = dateStr ? ` — ${dateStr}` : '';
      item.textContent = `${code}${isLatest ? latestTag() : ''}${suffix}`;
      if (isLatest) {
        selectedText.textContent = `${code}${latestTag()}`;
      }
      menu.appendChild(item);
    }

    function populateVersionsFromHistory(history, latestCode) {
      menu.innerHTML = '';
      selectedVersion = latestCode;
      selectedIsLatestRelease = true;
      const releases = history
        .filter((item) => item.platform === 'windows')
        .sort((a, b) => b.version - a.version);
      if (releases.length === 0) {
        populateFallbackVersions(latestCode);
        return;
      }
      releases.forEach((rel, index) => {
        const li = document.createElement('li');
        bindVersionItem(li, rel.version, index === 0, formatDate(rel.updatedAt));
      });
      updateLinks();
    }

    function populateFallbackVersions(latestCode) {
      menu.innerHTML = '';
      selectedVersion = latestCode;
      selectedIsLatestRelease = true;
      windowsUrlByVersion.clear();
      for (let i = 0; i < 10; i++) {
        const code = latestCode - i;
        if (code <= 0) break;
        windowsUrlByVersion.set(code, windowsDownloadUrl(code, null));
        const li = document.createElement('li');
        bindVersionItem(li, code, i === 0, '');
      }
      updateLinks();
    }

    async function init() {
      selectedText.textContent = currentLang === 'id' ? 'Memuat…' : 'Loading…';
      try {
        const res = await fetch('/version');
        if (!res.ok) throw new Error('HTTP ' + res.status);
        versionData = await res.json();
        const win = versionData.platforms?.windows;
        const web = versionData.platforms?.web;
        const android = versionData.platforms?.android;
        latestWebVersion = web?.version ?? null;
        latestAndroidVersion = android?.version ?? null;
        if (androidVerLabel && latestAndroidVersion) {
          androidVerLabel.textContent = 'v' + latestAndroidVersion;
        }
        if (win && versionData.history) {
          indexWindowsHistory(versionData.history);
          populateVersionsFromHistory(versionData.history, win.version);
        } else if (win) {
          populateFallbackVersions(win.version);
        } else {
          populateFallbackVersions(158);
        }
      } catch (_) {
        populateFallbackVersions(158);
      }
    }

    init();
  };

  initLang().then(() => {
    global.loadHeroAppVersion();
    global.initPlatformLanding();
  });
})(window);
