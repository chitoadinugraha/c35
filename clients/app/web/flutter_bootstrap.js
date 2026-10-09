{{flutter_js}}
{{flutter_build_config}}

(function () {
  const bar = document.getElementById('flutter-load-bar');
  const label = document.getElementById('flutter-load-label');
  let progress = 0;
  let raf = 0;

  function setLoadProgress(p, text) {
    progress = Math.max(progress, Math.min(1, p));
    if (bar) bar.style.width = (progress * 100).toFixed(1) + '%';
    if (label && text) label.textContent = text;
  }

  function tickLoadLabel() {
    if (!label || label.dataset.done === '1') return;
    const s = ((Date.now() - Number(label.dataset.t0 || Date.now())) / 1000).toFixed(1);
    if (!label.textContent || label.textContent.startsWith('Loading')) {
      label.textContent = 'Loading... ' + s + 's';
    }
    raf = requestAnimationFrame(tickLoadLabel);
  }

  if (label) {
    label.dataset.t0 = String(Date.now());
    tickLoadLabel();
  }

  setLoadProgress(0.04, 'Loading...');

  const loadConfig = {
    serviceWorkerSettings: {
      serviceWorkerVersion: {{flutter_service_worker_version}},
    },
    onEntrypointLoaded: async function (engineInitializer) {
      try {
        setLoadProgress(0.22, 'Loading engine...');
        const appRunner = await engineInitializer.initializeEngine();
        setLoadProgress(0.72, 'Starting app...');
        await appRunner.runApp();
        setLoadProgress(0.96, 'Almost ready...');
        if (typeof removeSplashFromWeb === 'function') removeSplashFromWeb();
        if (label) {
          label.dataset.done = '1';
          label.textContent = 'Ready';
        }
        setLoadProgress(1, 'Ready');
        cancelAnimationFrame(raf);
      } catch (err) {
        console.error('Flutter web boot failed:', err);
        if (label) {
          label.dataset.done = '1';
          label.textContent = 'Failed to start. Try a hard refresh or another browser.';
        }
        setLoadProgress(0, 'Failed to start');
      }
    },
  };

  _flutter.loader.load(loadConfig);
})();