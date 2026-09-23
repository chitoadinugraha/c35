(function () {
  var c = document.getElementById('stars');
  if (!c || !c.getContext) return;
  var ctx = c.getContext('2d');
  var w, h, stars = [], shooting = [];
  function resize() {
    w = c.width = window.innerWidth;
    h = c.height = window.innerHeight;
    stars = Array.from({ length: 140 }, function () {
      return {
        x: Math.random() * w,
        y: Math.random() * h,
        r: Math.random() * 1.4 + 0.3,
        base: Math.random() * 0.45 + 0.25,
        phase: Math.random() * Math.PI * 2,
        speed: Math.random() * 0.04 + 0.012
      };
    });
    shooting = [];
  }
  function spawnShooting() {
    if (Math.random() > 0.992) {
      shooting.push({
        x: Math.random() * w * 0.7 + w * 0.15,
        y: Math.random() * h * 0.35,
        len: Math.random() * 70 + 50,
        vx: Math.random() * 5 + 4,
        vy: Math.random() * 4 + 3,
        life: 1
      });
    }
  }
  function draw() {
    var g = ctx.createLinearGradient(0, 0, 0, h);
    g.addColorStop(0, '#0f1014');
    g.addColorStop(0.45, '#17181f');
    g.addColorStop(1, '#12131a');
    ctx.fillStyle = g;
    ctx.fillRect(0, 0, w, h);
    for (var i = 0; i < stars.length; i++) {
      var s = stars[i];
      s.phase += s.speed;
      var a = s.base + Math.sin(s.phase) * 0.4;
      ctx.fillStyle = 'rgba(255,255,255,' + a + ')';
      ctx.beginPath();
      ctx.arc(s.x, s.y, s.r, 0, Math.PI * 2);
      ctx.fill();
    }
    spawnShooting();
    for (var j = shooting.length - 1; j >= 0; j--) {
      var m = shooting[j];
      var tx = m.x - m.vx * m.len / 7;
      var ty = m.y - m.vy * m.len / 7;
      var trail = ctx.createLinearGradient(m.x, m.y, tx, ty);
      trail.addColorStop(0, 'rgba(255,255,255,' + m.life + ')');
      trail.addColorStop(1, 'rgba(255,255,255,0)');
      ctx.strokeStyle = trail;
      ctx.lineWidth = 1.8;
      ctx.beginPath();
      ctx.moveTo(m.x, m.y);
      ctx.lineTo(tx, ty);
      ctx.stroke();
      m.x += m.vx;
      m.y += m.vy;
      m.life -= 0.018;
      if (m.life <= 0 || m.x > w + 120 || m.y > h + 120) shooting.splice(j, 1);
    }
    requestAnimationFrame(draw);
  }
  resize();
  window.addEventListener('resize', resize);
  draw();
})();
