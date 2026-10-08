/** AlienAI marketing home: news, partners, clients, and links from GET /v1/site/platform-home. */
(function () {
  var MOUNTS = [
    'platform-news',
    'platform-partners',
    'platform-clients',
    'platform-client-list',
    'platform-links',
  ];

  function headings() {
    var locale = (document.documentElement.dataset.siteLocale || '').trim().toLowerCase();
    if (locale === 'id') {
      return { news: 'Berita', partners: 'Mitra', clients: 'Klien', links: 'Tautan' };
    }
    return { news: 'News', partners: 'Partners', clients: 'Clients', links: 'Links' };
  }

  function text(value) {
    if (value == null) return '';
    return String(value);
  }

  function escapeHtml(value) {
    return text(value)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
  }

  function mount(id) {
    return document.getElementById(id);
  }

  function hide(el) {
    if (!el) return;
    el.hidden = true;
    el.innerHTML = '';
  }

  function show(el) {
    if (!el) return;
    el.hidden = false;
  }

  function hideAll() {
    for (var i = 0; i < MOUNTS.length; i++) hide(mount(MOUNTS[i]));
  }

  function isJavascriptUrl(value) {
    var raw = text(value).replace(/[\u0000-\u001F\u007F\s]+/g, '');
    if (/^javascript:/i.test(raw)) return true;
    try {
      return new URL(raw, window.location.href).protocol === 'javascript:';
    } catch (_) {
      return false;
    }
  }

  function safeHref(value) {
    var raw = text(value).trim();
    if (!raw || isJavascriptUrl(raw)) return '';
    return raw;
  }

  function isExternal(href) {
    try {
      var url = new URL(href, window.location.href);
      return url.origin !== window.location.origin;
    } catch (_) {
      return false;
    }
  }

  function anchor(href, inner, className) {
    var safe = safeHref(href);
    if (!safe) return inner;
    var rel = isExternal(safe) ? ' rel="noopener"' : '';
    var cls = className ? ' class="' + className + '"' : '';
    return '<a href="' + escapeHtml(safe) + '"' + rel + cls + '>' + inner + '</a>';
  }

  function safeSrc(value) {
    var raw = text(value).trim();
    if (!raw || isJavascriptUrl(raw)) return '';
    return raw;
  }

  function formatDate(value) {
    var raw = text(value).trim();
    if (!raw) return '';
    var date = null;
    if (/^\d{10,13}$/.test(raw)) {
      var n = Number(raw);
      date = new Date(raw.length === 10 ? n * 1000 : n);
    } else {
      date = new Date(raw);
    }
    if (!date || isNaN(date.getTime())) return raw;
    var locale = (document.documentElement.dataset.siteLocale || '').trim().toLowerCase();
    var tag = locale === 'id' ? 'id-ID' : 'en-US';
    try {
      return date.toLocaleDateString(tag, { year: 'numeric', month: 'short', day: 'numeric' });
    } catch (_) {
      return raw;
    }
  }

  function sectionHeading(label) {
    return '<h2 class="text-2xl sm:text-3xl font-extrabold text-white mb-8 tracking-tight text-center">' +
      escapeHtml(label) + '</h2>';
  }

  function logoCard(item) {
    var name = escapeHtml(item && item.name);
    var pic = safeSrc(item && item.pic);
    var visual = pic
      ? '<img src="' + escapeHtml(pic) + '" alt="' + name + '" class="h-10 w-auto max-w-[7.5rem] object-contain">'
      : '';
    var card = '<div class="flex flex-col items-center justify-center gap-2 px-5 py-4 rounded-2xl bg-dark-card/60 border border-white/5 min-h-[5.5rem] min-w-[7rem]">' +
      visual +
      '<span class="text-xs text-slate-400 text-center">' + name + '</span></div>';
    return anchor(item && item.url, card, 'block hover:opacity-90 transition');
  }

  function renderNews(posts) {
    var el = mount('platform-news');
    if (!el || !Array.isArray(posts) || posts.length === 0) {
      hide(el);
      return;
    }
    var cards = posts.map(function (post) {
      post = post || {};
      var title = escapeHtml(post.title);
      var caption = escapeHtml(post.caption);
      var date = escapeHtml(formatDate(post.created_ts));
      var thumb = safeSrc(post.thumb);
      var thumbHtml = thumb
        ? '<img src="' + escapeHtml(thumb) + '" alt="" class="w-full h-36 object-cover rounded-xl mb-4 bg-white/5">'
        : '';
      return '<article class="p-6 rounded-2xl bg-dark-card/60 border border-white/5">' +
        thumbHtml +
        (date ? '<p class="text-[11px] font-mono uppercase tracking-[0.18em] text-slate-500 mb-2">' + date + '</p>' : '') +
        '<h3 class="text-lg font-bold text-white mb-2">' + title + '</h3>' +
        (caption ? '<p class="text-slate-400 text-sm leading-relaxed">' + caption + '</p>' : '') +
        '</article>';
    }).join('');
    el.innerHTML = sectionHeading(headings().news) +
      '<div class="grid grid-cols-1 md:grid-cols-3 gap-6">' + cards + '</div>';
    show(el);
  }

  function renderPartners(partners) {
    var el = mount('platform-partners');
    if (!el || !Array.isArray(partners) || partners.length === 0) {
      hide(el);
      return;
    }
    var cards = partners.map(logoCard).join('');
    el.innerHTML = sectionHeading(headings().partners) +
      '<div class="flex flex-wrap items-stretch justify-center gap-4">' + cards + '</div>';
    show(el);
  }

  function renderClients(clients) {
    var strip = mount('platform-clients');
    var list = mount('platform-client-list');
    if (!Array.isArray(clients) || clients.length === 0) {
      hide(strip);
      hide(list);
      return;
    }
    if (strip) {
      strip.innerHTML = sectionHeading(headings().clients) +
        '<div class="flex flex-wrap items-center justify-center gap-6">' + clients.map(logoCard).join('') + '</div>';
      show(strip);
    }
    if (list) {
      var items = clients.map(function (client) {
        client = client || {};
        var name = escapeHtml(client.name);
        return '<li class="text-sm text-slate-300">' +
          anchor(client.url, name, 'hover:text-white transition') +
          '</li>';
      }).join('');
      list.innerHTML = '<ul class="flex flex-wrap justify-center gap-x-6 gap-y-2">' + items + '</ul>';
      show(list);
    }
  }

  function renderLinks(links) {
    var el = mount('platform-links');
    if (!el || !Array.isArray(links) || links.length === 0) {
      hide(el);
      return;
    }
    var items = links.map(function (link) {
      link = link || {};
      var label = escapeHtml(link.label || link.url || '');
      return anchor(link.url, label, 'text-sm text-slate-300 hover:text-white transition');
    }).join('');
    el.innerHTML = sectionHeading(headings().links) +
      '<div class="flex flex-wrap items-center justify-center gap-6">' + items + '</div>';
    show(el);
  }

  function render(data) {
    data = data && typeof data === 'object' ? data : {};
    renderNews(data.posts);
    renderPartners(data.partners);
    renderClients(data.clients);
    renderLinks(data.links);
  }

  function boot() {
    var pending;
    try {
      pending = fetch('/v1/site/platform-home', { headers: { Accept: 'application/json' } });
    } catch (_) {
      hideAll();
      return;
    }
    pending
      .then(function (res) {
        if (!res || !res.ok) throw new Error('platform-home');
        return res.json();
      })
      .then(function (data) {
        try {
          render(data);
        } catch (_) {
          hideAll();
        }
      })
      .catch(function () {
        hideAll();
      });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', boot);
  } else {
    boot();
  }
})();
