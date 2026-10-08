// Include next to site-guest.v1.js from guest_client_script_tags in servers/crates/mod_site/src/render.rs
(function () {
  var boot = window.__SITE_BOOT__ || {};
  var rows = Array.isArray(boot.effects) ? boot.effects : [];
  var known = {
    "falling-hearts": 1,
    "rain-shower": 1,
    "snow-fall": 1,
    "floating-bubbles": 1,
    "thunderstorm": 1,
    "fireworks": 1,
    "starry-night": 1,
    "drifting-clouds": 1,
    "matrix-rain": 1,
    "sakura-petals": 1,
    "moonlight": 1,
    "autumn-leaves": 1
  };

  function canonical(id) {
    if (known[id]) return id;
    var dashed = String(id || "").replace(/_/g, "-");
    return known[dashed] ? dashed : "";
  }

  var active = [];
  for (var i = 0; i < rows.length; i++) {
    var row = rows[i] || {};
    if (row.active === false) continue;
    var preset = canonical(row.presetId);
    if (!preset) continue;
    active.push({ id: row.id || preset, presetId: preset, params: row.params || {} });
  }
  if (!active.length) return;

  var canvas = document.createElement("canvas");
  canvas.setAttribute("aria-hidden", "true");
  canvas.style.cssText = "position:fixed;inset:0;width:100%;height:100%;pointer-events:none;z-index:0";
  var page = document.querySelector("main") || document.body;
  if (page && page.parentNode) page.parentNode.insertBefore(canvas, page);
  else document.body.appendChild(canvas);
  if (page) page.style.position = page.style.position || "relative";
  if (page) page.style.zIndex = page.style.zIndex || "1";

  var ctx = canvas.getContext("2d");
  var parts = [];
  var w = 0;
  var h = 0;

  function num(params, key, fallback) {
    var v = params && params[key];
    return typeof v === "number" ? v : fallback;
  }

  function resize() {
    w = window.innerWidth;
    h = window.innerHeight;
    var dpr = window.devicePixelRatio || 1;
    canvas.width = Math.max(1, Math.floor(w * dpr));
    canvas.height = Math.max(1, Math.floor(h * dpr));
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
  }

  function seed() {
    parts = [];
    for (var i = 0; i < active.length; i++) {
      var fx = active[i];
      var density = Math.max(8, Math.min(80, num(fx.params, "density", 28)));
      for (var n = 0; n < density; n++) {
        parts.push({
          preset: fx.presetId,
          x: Math.random() * (w || 1),
          y: Math.random() * (h || 1),
          v: 0.4 + Math.random() * num(fx.params, "speed", 2),
          s: num(fx.params, "size", 3),
          color: typeof (fx.params && fx.params.color) === "string" ? fx.params.color : ""
        });
      }
    }
  }

  function draw() {
    if (!ctx) return;
    ctx.clearRect(0, 0, w, h);
    for (var i = 0; i < parts.length; i++) {
      var p = parts[i];
      var color = p.color || "#ffffff";
      ctx.globalAlpha = 0.75;
      ctx.fillStyle = color;
      ctx.strokeStyle = color;
      if (p.preset === "rain-shower" || p.preset === "matrix-rain" || p.preset === "thunderstorm") {
        p.y += p.v * 4;
        if (p.y > h) p.y = -10;
        ctx.fillRect(p.x, p.y, p.preset === "matrix-rain" ? 2 : 1.2, p.s * 4);
      } else if (p.preset === "fireworks") {
        p.y -= p.v;
        if (p.y < 0) p.y = h;
        ctx.beginPath();
        ctx.arc(p.x, p.y, Math.max(1, p.s / 6), 0, Math.PI * 2);
        ctx.fill();
      } else {
        p.y += p.v;
        p.x += Math.sin(p.y / 24) * 0.4;
        if (p.y > h) p.y = -8;
        ctx.beginPath();
        ctx.arc(p.x, p.y, Math.max(1.5, p.s / 4), 0, Math.PI * 2);
        ctx.fill();
      }
    }
    ctx.globalAlpha = 1;
    window.requestAnimationFrame(draw);
  }

  resize();
  seed();
  window.addEventListener("resize", function () {
    resize();
    seed();
  });
  window.requestAnimationFrame(draw);
})();
