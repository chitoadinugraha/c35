// Guest overlay effects. Loads overlay_effects wasm and paints an 8-float particle buffer.
// Canvas is paint-only (pointer-events: none). The page stays the pointer target so links remain clickable.
(function () {
  var KIND_LINE = 0;
  var KIND_GLYPH = 1;
  var KIND_ELLIPSE = 2;
  var KIND_ELLIPSE_FILLED = 3;
  var KIND_SAKURA = 4;
  var KIND_LEAF = 5;
  var KIND_MOON = 6;

  var KNOWN = {
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

  function log(msg) {
    console.log("[effects]", msg);
  }

  function logErr(err) {
    console.error("[effects]", err);
  }

  function canonicalPreset(id) {
    var raw = String(id || "").trim();
    if (!raw) return "";
    var dashed = raw.replace(/_/g, "-");
    return KNOWN[dashed] ? dashed : "";
  }

  function paramsJsonOf(row) {
    if (typeof row.params_json === "string") return row.params_json;
    if (row.params_json && typeof row.params_json === "object") return JSON.stringify(row.params_json);
    if (typeof row.params === "string") return row.params;
    if (row.params && typeof row.params === "object") return JSON.stringify(row.params);
    return "{}";
  }

  function activeEffects(rows) {
    var out = [];
    for (var i = 0; i < rows.length; i++) {
      var row = rows[i] || {};
      if (row.active === false) continue;
      var preset = canonicalPreset(row.presetId || row.preset_id);
      if (!preset) continue;
      out.push({
        preset_id: preset,
        params_json: paramsJsonOf(row)
      });
    }
    return out;
  }

  var boot = window.__SITE_BOOT__ || {};
  var rows = Array.isArray(boot.effects) ? boot.effects : [];
  var active = activeEffects(rows);
  if (!active.length) return;

  function ensureCanvas() {
    var canvas = document.getElementById("guest-effects");
    if (!canvas) {
      canvas = document.createElement("canvas");
      canvas.id = "guest-effects";
      canvas.setAttribute("aria-hidden", "true");
      canvas.style.cssText = "position:fixed;inset:0;width:100%;height:100%;pointer-events:none;z-index:0";
      var page = document.querySelector("main") || document.body;
      if (page && page.parentNode) page.parentNode.insertBefore(canvas, page);
      else document.body.appendChild(canvas);
      if (page && page !== document.body) {
        if (!page.style.position) page.style.position = "relative";
        if (!page.style.zIndex) page.style.zIndex = "1";
      }
    }
    canvas.style.pointerEvents = "none";
    return canvas;
  }

  var canvas = ensureCanvas();

  function parsePalette(paramsJson) {
    try {
      var p = JSON.parse(paramsJson || "{}");
      var raw = String((p && p.color) || "").trim();
      if (!raw) return ["#ffffff"];
      var parts = raw.split(/[,|]/);
      var out = [];
      for (var i = 0; i < parts.length; i++) {
        var part = parts[i].trim();
        if (!part) continue;
        var hex = part.charAt(0) === "#" ? part.slice(1) : part;
        if (/^[0-9a-fA-F]{6}$/.test(hex)) out.push("#" + hex);
        else if (/^[0-9a-fA-F]{3}$/.test(hex)) {
          out.push("#" + hex.charAt(0) + hex.charAt(0) + hex.charAt(1) + hex.charAt(1) + hex.charAt(2) + hex.charAt(2));
        }
      }
      return out.length ? out : ["#ffffff"];
    } catch (e) {
      return ["#ffffff"];
    }
  }

  function colorFromParticle(f, palette, index) {
    var n = Math.round(f);
    if (n > 0) {
      var r = (n >> 16) & 0xff;
      var g = (n >> 8) & 0xff;
      var b = n & 0xff;
      if (r + g + b > 12) return "rgb(" + r + "," + g + "," + b + ")";
    }
    if (palette.length) return palette[index % palette.length];
    var bits = new DataView(new ArrayBuffer(4));
    bits.setFloat32(0, f, true);
    var c = bits.getUint32(0, true);
    var r2 = (c >> 16) & 0xff;
    var g2 = (c >> 8) & 0xff;
    var b2 = c & 0xff;
    if (r2 + g2 + b2 < 40) return "#ffffff";
    return "rgb(" + r2 + "," + g2 + "," + b2 + ")";
  }

  function drawHeart(ctx, size) {
    var s = Math.max(6, size) * 0.5;
    ctx.beginPath();
    ctx.moveTo(0, s * 0.35);
    ctx.bezierCurveTo(s * 0.9, -s * 0.35, s * 1.1, s * 0.55, 0, s * 1.15);
    ctx.bezierCurveTo(-s * 1.1, s * 0.55, -s * 0.9, -s * 0.35, 0, s * 0.35);
    ctx.closePath();
    ctx.fill();
  }

  function drawMoonCrescent(ctx, R) {
    var r = Math.max(6, R);
    ctx.beginPath();
    ctx.moveTo(0, -r);
    ctx.quadraticCurveTo(r * 1.1, 0, 0, r);
    ctx.quadraticCurveTo(r * 0.35, 0, 0, -r);
    ctx.closePath();
    ctx.fill();
  }

  function drawGlyph(ctx, size, code, fill) {
    if (code >= 32 && code < 0x110000) {
      var px = Math.max(8, Math.round(size || 14));
      ctx.font = "600 " + px + "px ui-monospace, SFMono-Regular, Menlo, Consolas, monospace";
      ctx.textAlign = "center";
      ctx.textBaseline = "middle";
      ctx.fillStyle = fill;
      ctx.fillText(String.fromCharCode(code), 0, 0);
      return;
    }
    drawHeart(ctx, size || 14);
  }

  function strokeEllipse(ctx, a, b, rot) {
    var ra = Math.max(0.5, a / 2);
    var rb = Math.max(0.5, (b || a) / 2);
    var circleLike = Math.abs(a - b) <= Math.max(a, b) * 0.12;
    if (circleLike && rot > 0 && rot <= 6) {
      ctx.lineWidth = rot;
      ctx.beginPath();
      ctx.arc(0, 0, Math.max(ra, rb), 0, Math.PI * 2);
      ctx.stroke();
      return;
    }
    ctx.lineWidth = 1.2;
    ctx.beginPath();
    ctx.ellipse(0, 0, ra, rb, rot, 0, Math.PI * 2);
    ctx.stroke();
  }

  function drawParticles(ctx, data, count, stride, palette) {
    for (var i = 0; i < count; i++) {
      var o = i * stride;
      var kind = data[o];
      var x = data[o + 1];
      var y = data[o + 2];
      var a = data[o + 3];
      var b = data[o + 4];
      var rot = data[o + 5];
      var opacity = Math.max(0, Math.min(1, data[o + 6]));
      if (opacity <= 0.01) continue;
      var fill = colorFromParticle(data[o + 7], palette, i);
      ctx.save();
      ctx.globalAlpha = opacity;
      ctx.fillStyle = fill;
      ctx.strokeStyle = fill;
      if (kind === KIND_LINE) {
        var dx = a - x;
        var dy = b - y;
        ctx.lineWidth = Math.max(1, rot || 1.5);
        ctx.lineCap = "round";
        ctx.beginPath();
        ctx.moveTo(x, y);
        ctx.lineTo(x + dx, y + dy);
        ctx.stroke();
        ctx.restore();
        continue;
      }
      ctx.translate(x, y);
      ctx.rotate(rot);
      if (kind === KIND_MOON) {
        drawMoonCrescent(ctx, a || 12);
      } else if (kind === KIND_GLYPH) {
        drawGlyph(ctx, a || 14, Math.round(b), fill);
      } else if (kind === KIND_ELLIPSE || kind === KIND_ELLIPSE_FILLED) {
        var ra = Math.max(0.5, a / 2);
        var rb = Math.max(0.5, (b || a) / 2);
        var circleLike = Math.abs(a - b) <= Math.max(a, b) * 0.12;
        var angle = circleLike && rot > 0 && rot <= 6 ? 0 : rot;
        ctx.beginPath();
        ctx.ellipse(0, 0, ra, rb, angle, 0, Math.PI * 2);
        if (kind === KIND_ELLIPSE_FILLED) ctx.fill();
        else strokeEllipse(ctx, a, b, rot);
      } else if (kind === KIND_SAKURA) {
        var r = Math.max(2, a / 2);
        ctx.beginPath();
        for (var p = 0; p < 5; p++) {
          var ang = (p / 5) * Math.PI * 2;
          ctx.ellipse(Math.cos(ang) * r * 0.35, Math.sin(ang) * r * 0.35, r * 0.45, r * 0.22, ang, 0, Math.PI * 2);
        }
        ctx.fill();
      } else if (kind === KIND_LEAF) {
        var lr = a / 2;
        ctx.beginPath();
        ctx.moveTo(0, -lr);
        ctx.lineTo(-lr * 0.2, -lr * 0.5);
        ctx.lineTo(-lr * 0.4, -lr * 0.65);
        ctx.lineTo(-lr * 0.3, -lr * 0.35);
        ctx.lineTo(-lr * 0.75, -lr * 0.3);
        ctx.lineTo(-lr * 0.45, -lr * 0.05);
        ctx.lineTo(-lr * 0.65, lr * 0.15);
        ctx.lineTo(-lr * 0.35, lr * 0.3);
        ctx.lineTo(-lr * 0.15, lr * 0.5);
        ctx.lineTo(0, lr * 0.75);
        ctx.lineTo(lr * 0.15, lr * 0.5);
        ctx.lineTo(lr * 0.35, lr * 0.3);
        ctx.lineTo(lr * 0.65, lr * 0.15);
        ctx.lineTo(lr * 0.45, -lr * 0.05);
        ctx.lineTo(lr * 0.75, -lr * 0.3);
        ctx.lineTo(lr * 0.3, -lr * 0.35);
        ctx.lineTo(lr * 0.4, -lr * 0.65);
        ctx.lineTo(lr * 0.2, -lr * 0.5);
        ctx.closePath();
        ctx.fill();

        var prevLineWidth = ctx.lineWidth;
        var prevLineCap = ctx.lineCap;
        var prevStrokeStyle = ctx.strokeStyle;

        ctx.beginPath();
        ctx.moveTo(0, lr * 0.75);
        ctx.lineTo(0, lr * 1.15);
        ctx.lineWidth = Math.max(1, lr * 0.1);
        ctx.lineCap = "round";
        ctx.strokeStyle = "rgba(0, 0, 0, 0.15)";
        ctx.stroke();

        ctx.beginPath();
        ctx.moveTo(0, lr * 0.75);
        ctx.lineTo(0, -lr * 0.8);
        ctx.moveTo(0, -lr * 0.2);
        ctx.lineTo(-lr * 0.3, -lr * 0.5);
        ctx.moveTo(0, -lr * 0.2);
        ctx.lineTo(lr * 0.3, -lr * 0.5);
        ctx.moveTo(0, lr * 0.1);
        ctx.lineTo(-lr * 0.55, -lr * 0.15);
        ctx.moveTo(0, lr * 0.1);
        ctx.lineTo(lr * 0.55, -lr * 0.15);
        ctx.moveTo(0, lr * 0.4);
        ctx.lineTo(-lr * 0.45, lr * 0.25);
        ctx.moveTo(0, lr * 0.4);
        ctx.lineTo(lr * 0.45, lr * 0.25);
        ctx.lineWidth = Math.max(0.6, lr * 0.06);
        ctx.strokeStyle = "rgba(255, 255, 255, 0.25)";
        ctx.stroke();

        ctx.lineWidth = prevLineWidth;
        ctx.lineCap = prevLineCap;
        ctx.strokeStyle = prevStrokeStyle;
      } else {
        ctx.beginPath();
        ctx.arc(0, 0, Math.max(1, a / 2), 0, Math.PI * 2);
        ctx.fill();
      }
      ctx.restore();
    }
  }

  var importer = new Function("u", "return import(u)");

  importer("/static/site-guest/effects/overlay_effects.js").then(function (mod) {
    return mod.default({
      module_or_path: "/static/site-guest/effects/overlay_effects_bg.wasm"
    }).then(function (wasm) {
      return { mod: mod, wasm: wasm };
    });
  }).then(function (loaded) {
    var mod = loaded.mod;
    var wasm = loaded.wasm;
    var ctx = canvas.getContext("2d");
    if (!ctx) return;

    function syncEngines(w, h) {
      var first = active[0];
      var ok = mod.overlay_init(first.preset_id, (first.params_json || "").trim() || "{}", w, h);
      if (!ok) {
        logErr("overlay_init failed for " + first.preset_id);
        return false;
      }
      var push = mod.overlay_push;
      if (push) {
        for (var i = 1; i < active.length; i++) {
          var e = active[i];
          if (!push(e.preset_id, (e.params_json || "").trim() || "{}", w, h)) {
            logErr("overlay_push failed for " + e.preset_id);
          }
        }
      }
      mod.overlay_resize(w, h);
      return true;
    }

    var viewW = window.innerWidth;
    var viewH = window.innerHeight;

    function resize() {
      var dpr = Math.min(window.devicePixelRatio || 1, 2);
      var w = window.innerWidth;
      var h = window.innerHeight;
      viewW = w;
      viewH = h;
      canvas.width = Math.floor(w * dpr);
      canvas.height = Math.floor(h * dpr);
      canvas.style.width = w + "px";
      canvas.style.height = h + "px";
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
      return syncEngines(w, h);
    }

    if (!resize()) return;
    log("effects " + active.map(function (e) { return e.preset_id; }).join("+"));

    var palette = parsePalette(active[0].params_json || "{}");
    if (!palette.length) palette.push("#ffffff");

    window.addEventListener("resize", resize);
    if (window.visualViewport) window.visualViewport.addEventListener("resize", resize);

    var last = performance.now();
    var stride = mod.overlay_particle_stride() || 8;

    function frame(now) {
      var dt = Math.min(0.05, (now - last) / 1000);
      last = now;
      var count = mod.overlay_tick(dt);
      var ptr = mod.overlay_particles_ptr();
      ctx.clearRect(0, 0, viewW, viewH);
      if (count > 0 && wasm.memory) {
        var f32 = new Float32Array(wasm.memory.buffer, ptr, count * stride);
        drawParticles(ctx, f32, count, stride, palette);
      }
      requestAnimationFrame(frame);
    }
    requestAnimationFrame(frame);
  }).catch(function (err) {
    logErr(err);
  });
})();
