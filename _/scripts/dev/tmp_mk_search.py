from pathlib import Path
src = Path(r"D:/c35/remotes/browser_engine/home.html").read_text(encoding="utf-8")
# Adapt for hosted search page
html = src.replace('href="home_icon.png"', 'href="/apple-touch-icon.png"')
html = html.replace('src="home_icon.png"', 'src="/apple-touch-icon.png"')
html = html.replace('<title>Alien AI</title>', '<title>Search — Alien AI</title>')
html = html.replace('<p class="tagline" id="brandTagline">Remote browser</p>', '<p class="tagline" id="brandTagline">Search the web</p>')
# Add agent dock styles before </style>
dock_css = """
    .agent-dock {
      width: min(580px, 100%);
      margin-top: 28px;
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: 16px;
      padding: 14px 16px;
      display: none;
    }
    .agent-dock.visible { display: block; }
    .agent-dock h3 { margin: 0 0 10px; font-size: 12px; font-weight: 600; color: var(--muted); text-transform: uppercase; letter-spacing: 0.06em; }
    .agent-row { display: flex; align-items: center; justify-content: space-between; gap: 12px; padding: 6px 0; font-size: 13px; }
    .agent-row .label { color: var(--muted); }
    .status-dot { width: 8px; height: 8px; border-radius: 50%; display: inline-block; margin-right: 6px; }
    .status-dot.on { background: var(--accent); box-shadow: 0 0 8px rgba(52,211,153,0.6); }
    .status-dot.off { background: #71717a; }
"""
html = html.replace("  </style>", dock_css + "\n  </style>")
html = html.replace(
  '<p class="hint">Quota and billing sync with your Alien AI account in the app.</p>',
  '''<p class="hint" id="publicHint">Search the web with Alien AI. Sign in to the app for quota and billing.</p>
  <aside class="agent-dock" id="agentDock" aria-label="Remote browser agent">
    <h3>Remote browser agent</h3>
    <div class="agent-row"><span class="label">Alien AI Cloud</span><span id="cloudStatus">—</span></div>
    <div class="agent-row"><span class="label">Account</span><span id="accountLine">—</span></div>
    <div class="agent-row"><span class="label">Package</span><span id="packageLine">—</span></div>
    <div class="agent-row"><span class="label">Device</span><span id="deviceLine">—</span></div>
    <div class="agent-row"><span class="label">Agent</span><span id="agentLine">—</span></div>
  </aside>'''
)
# Replace user card + fetch block with agent render script
old_script_tail = """    fetch('home_ctx.json')
      .then((r) => (r.ok ? r.json() : null))
      .catch(() => null)
      .then((ctx) => {
        if (!ctx) return;
        const card = document.getElementById('userCard');
        if (ctx.userName) {
          document.getElementById('userName').textContent = ctx.userName;
          document.getElementById('brandTagline').textContent = ctx.userName;
        }
        const sub = [];
        if (ctx.alienId) sub.push('@' + ctx.alienId);
        if (ctx.packageName) sub.push(ctx.packageName);
        if (sub.length) {
          document.getElementById('userSub').textContent = sub.join(' · ');
          if (ctx.alienId) document.getElementById('brandTagline').textContent = '@' + ctx.alienId;
        }
        const pills = document.getElementById('userPills');
        if (ctx.packageName) {
          const p = document.createElement('span');
          p.className = 'pill';
          p.textContent = ctx.packageName;
          pills.appendChild(p);
          card.hidden = false;
        }
      });"""
new_tail = """    function renderRemoteBrowser(ctx) {
      if (!ctx || typeof ctx !== 'object') return;
      const dock = document.getElementById('agentDock');
      const hint = document.getElementById('publicHint');
      if (hint) hint.hidden = true;
      dock.classList.add('visible');
      const online = ctx.cloudOnline === true;
      document.getElementById('cloudStatus').innerHTML =
        '<span class="status-dot ' + (online ? 'on' : 'off') + '"></span>' + (online ? 'Connected' : 'Offline');
      const acct = [];
      if (ctx.userName) acct.push(ctx.userName);
      if (ctx.alienId) acct.push('@' + ctx.alienId);
      document.getElementById('accountLine').textContent = acct.length ? acct.join(' · ') : '—';
      document.getElementById('packageLine').textContent = ctx.packageName || '—';
      document.getElementById('deviceLine').textContent = ctx.deviceName || 'Remote browser';
      document.getElementById('agentLine').textContent = ctx.agentVersion || '—';
      if (ctx.userName) document.getElementById('brandTagline').textContent = ctx.userName;
      else if (ctx.alienId) document.getElementById('brandTagline').textContent = '@' + ctx.alienId;
    }
    window.addEventListener('c35-remote-browser-context', (ev) => renderRemoteBrowser(ev.detail));
    if (window.__C35_REMOTE_BROWSER__) renderRemoteBrowser(window.__C35_REMOTE_BROWSER__);"""
html = html.replace(old_script_tail, new_tail)
# Remove hidden user card block (optional keep hidden)
html = html.replace('  <div class="card" id="userCard" hidden>\n    <h2 id="userName">Alien AI</h2>\n    <div class="muted" id="userSub">Remote browser</div>\n    <div class="row" id="userPills"></div>\n  </div>\n', '')
Path(r"D:/c35/clients/web/search.html").write_text(html, encoding="utf-8", newline="\n")
print("wrote search.html", len(html))