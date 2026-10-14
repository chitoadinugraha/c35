(function () {
  function reservationUnit(unit) {
    return String(unit == null ? '' : unit).trim().toLowerCase();
  }

  function reservationNeedsTime(unit) {
    const u = reservationUnit(unit);
    return u !== '' && u !== 'day';
  }

  function reservationInstant(value) {
    if (value instanceof Date) return new Date(value.getTime());
    if (typeof value !== 'string') return new Date(NaN);
    const s = value.trim();
    let m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(s);
    if (m) return new Date(+m[1], +m[2] - 1, +m[3], 0, 0, 0, 0);
    m = /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})(?::(\d{2}))?$/.exec(s);
    if (m) return new Date(+m[1], +m[2] - 1, +m[3], +m[4], +m[5], m[6] ? +m[6] : 0, 0);
    return new Date(NaN);
  }

  function reservationCalendarDays(start, end) {
    const s = Date.UTC(start.getFullYear(), start.getMonth(), start.getDate());
    const e = Date.UTC(end.getFullYear(), end.getMonth(), end.getDate());
    const days = Math.floor((e - s) / 86400000);
    return days > 0 ? days : 0;
  }

  function reservationAddCalendar(start, years, months, days) {
    return new Date(
      start.getFullYear() + years,
      start.getMonth() + months,
      start.getDate() + days,
      start.getHours(),
      start.getMinutes(),
      start.getSeconds(),
      start.getMilliseconds()
    );
  }

  function reservationDurationCount(start, end, unit) {
    const s = reservationInstant(start);
    const e = reservationInstant(end);
    if (!isFinite(s.getTime()) || !isFinite(e.getTime()) || e.getTime() <= s.getTime()) return 0;
    const u = reservationUnit(unit);
    if (u === '' || u === 'day') return reservationCalendarDays(s, e);
    if (u === 'hour' || u === 'minute' || u === 'second') {
      const ms = u === 'hour' ? 3600000 : (u === 'minute' ? 60000 : 1000);
      return Math.floor((e.getTime() - s.getTime()) / ms);
    }
    if (u === 'week') return Math.floor(reservationCalendarDays(s, e) / 7);
    if (u === 'month') {
      const months = (e.getFullYear() * 12 + e.getMonth()) - (s.getFullYear() * 12 + s.getMonth());
      return months > 0 ? months : 0;
    }
    if (u === 'year') {
      let years = e.getFullYear() - s.getFullYear();
      if (e.getMonth() < s.getMonth() || (e.getMonth() === s.getMonth() && e.getDate() < s.getDate())) {
        years -= 1;
      }
      return years > 0 ? years : 0;
    }
    return 0;
  }

  function reservationBillable(units, durationCount) {
    const u = units | 0;
    const d = durationCount | 0;
    if (u < 1 || d < 1) return 0;
    return u * d;
  }

  function guestSlotDurationQty(slot) {
    if (slot.durationQty != null) return slot.durationQty;
    if (slot.duration_qty != null) return slot.duration_qty;
    if (slot.durationCount != null) return slot.durationCount;
    return 1;
  }

  function guestAssignmentsFit(src, units) {
    const list = Array.isArray(src) ? src.slice() : [];
    const n = units | 0;
    if (n <= 0) return [];
    while (list.length < n) list.push(null);
    if (list.length > n) list.length = n;
    return list;
  }

  function guestSlotsOverlap(a, b) {
    const aStart = a.start && a.start.getTime ? a.start.getTime() : NaN;
    const aEnd = a.end && a.end.getTime ? a.end.getTime() : NaN;
    const bStart = b.start && b.start.getTime ? b.start.getTime() : NaN;
    const bEnd = b.end && b.end.getTime ? b.end.getTime() : NaN;
    if (!isFinite(aStart) || !isFinite(aEnd) || !isFinite(bStart) || !isFinite(bEnd)) return true;
    return aStart < bEnd && bStart < aEnd;
  }

  function guestTakenObjIds(slots, exceptSlot, exceptAssignIndex) {
    const taken = new Set();
    for (const other of slots) {
      const assigns = guestAssignmentsFit(other.assignments, other.units || 1);
      if (other === exceptSlot) {
        assigns.forEach(function (pick, i) {
          if (i === exceptAssignIndex) return;
          const id = pick && pick.site_object_id ? Number(pick.site_object_id) : 0;
          if (id > 0) taken.add(id);
        });
        continue;
      }
      if (!guestSlotsOverlap(exceptSlot, other)) continue;
      assigns.forEach(function (pick) {
        const id = pick && pick.site_object_id ? Number(pick.site_object_id) : 0;
        if (id > 0) taken.add(id);
      });
    }
    return taken;
  }

  function guestReservationsFromSlot(slot, productId) {
    const units = slot.units || 1;
    const durationQty = guestSlotDurationQty(slot) || 1;
    const startMs = slot.start_ts_ms != null ? slot.start_ts_ms : (slot.start && slot.start.getTime());
    const endMs = slot.end_ts_ms != null ? slot.end_ts_ms : (slot.end && slot.end.getTime());
    const assigns = guestAssignmentsFit(slot.assignments, units);
    const expand = units > 1 && Array.isArray(slot.assignments) && slot.assignments.length > 0;
    if (expand) {
      return assigns.map(function (pick) {
        return {
          product_id: productId,
          qty: 1,
          duration_qty: durationQty,
          start_ts_ms: startMs,
          end_ts_ms: endMs,
          site_object_id: pick && pick.site_object_id ? Number(pick.site_object_id) : 0,
          state: 'pending',
        };
      });
    }
    let objId = 0;
    if (assigns.length && assigns[0] && assigns[0].site_object_id) {
      objId = Number(assigns[0].site_object_id);
    } else if (slot.site_object_id) {
      objId = Number(slot.site_object_id);
    }
    return [{
      product_id: productId,
      qty: units,
      duration_qty: durationQty,
      start_ts_ms: startMs,
      end_ts_ms: endMs,
      site_object_id: objId,
      state: 'pending',
    }];
  }

  function reservationEndFromDuration(start, unit, count) {
    const s = reservationInstant(start);
    const n = count | 0;
    if (!isFinite(s.getTime()) || n < 1) return s;
    const u = reservationUnit(unit);
    if (u === 'second') return new Date(s.getTime() + n * 1000);
    if (u === 'minute') return new Date(s.getTime() + n * 60000);
    if (u === 'hour') return new Date(s.getTime() + n * 3600000);
    if (u === 'week') return reservationAddCalendar(s, 0, 0, n * 7);
    if (u === 'month') return reservationAddCalendar(s, 0, n, 0);
    if (u === 'year') return reservationAddCalendar(s, n, 0, 0);
    if (u === '' || u === 'day') return reservationAddCalendar(s, 0, 0, n);
    return s;
  }

  window.c35ReservationMath = {
    reservationNeedsTime,
    reservationDurationCount,
    reservationBillable,
    reservationEndFromDuration,
  };

  const GUEST_PRODUCT_PRICE_CONTACT = -1;

  function formatIdr(amount) {
    const s = Math.round(amount || 0).toString();
    let out = '';
    for (let i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 === 0) out += '.';
      out += s[i];
    }
    return 'Rp ' + out;
  }

  /** Cart/checkout totals — matches Flutter `GuestSiteCartChrome` (`Rp ${n}`). */
  function formatRpPlain(amount) {
    return 'Rp ' + Math.round(amount || 0);
  }

  /** Order history lines — matches Flutter `GuestSiteOrdersChip` subtitle. */
  function formatOrderTotal(amount) {
    return 'IDR ' + Math.round(amount || 0);
  }

  function guestI18nStrings() {
    const g = window.__SITE_GUEST__ || {};
    const i = g.i18n || {};
    return {
      priceContact: i.price_contact || 'Contact us',
      tileContactCta: i.tile_contact_cta || 'Contact',
      filterAll: i.filter_all || 'All',
      loadMore: i.load_more || 'Load more',
      loading: i.loading || 'Loading…',
      detailAria: i.detail_aria || 'Product details',
      shareAria: i.share_aria || 'Share product',
    };
  }

  function guestProductPriceLabel(price) {
    const p = Math.round(price || 0);
    if (p === GUEST_PRODUCT_PRICE_CONTACT) return guestI18nStrings().priceContact;
    if (p <= 0) return '';
    return formatIdr(p);
  }

  function guestProductCanAddToCart(price) {
    return Math.round(price || 0) > 0;
  }

  function picHashOnly(pic) {
    const raw = String(pic || '').trim();
    if (!raw) return '';
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    let path = raw;
    if (path.startsWith('/fs/')) path = path.slice(4);
    else if (path.startsWith('fs/')) path = path.slice(3);
    return path.split('?')[0];
  }

  function picUrlThumb(pic) {
    const h = picHashOnly(pic);
    if (!h) return '';
    if (h.startsWith('http')) return h;
    return '/fs/' + h + '?v=thumb';
  }

  function picUrlDisplay(pic) {
    const h = picHashOnly(pic);
    if (!h) return '';
    if (h.startsWith('http')) return h;
    return '/fs/' + h + '?v=small';
  }

  function productGridDisplayFromSection(section) {
    if (!section) return 'grid';
    const raw = (section.getAttribute('data-display') || '').trim().toLowerCase();
    return raw === 'list' ? 'list' : 'grid';
  }

  function openPicLightbox(url) {
    if (!url) return;
    const scrim = document.createElement('div');
    scrim.className = 'guest-pic-lightbox';
    scrim.innerHTML = '<button type="button" class="guest-pic-lightbox-close" aria-label="Close">&times;</button>'
      + '<img src="' + url.replace(/"/g, '&quot;') + '" alt=""/>';
    function close() { scrim.remove(); }
    scrim.addEventListener('click', function (e) {
      if (e.target === scrim || e.target.closest('.guest-pic-lightbox-close')) close();
    });
    document.body.appendChild(scrim);
  }

  function escHtml(value) {
    return String(value == null ? '' : value)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
  }

  function productDescText(product) {
    if (!product) return '';
    const raw = product.desc != null ? product.desc : product.description;
    return String(raw == null ? '' : raw).trim();
  }

  function apiBase() {
    if (window.__SITE_GUEST__ && window.__SITE_GUEST__.api_base) {
      return window.__SITE_GUEST__.api_base;
    }
    return (location.hostname === 'alienai.id' || location.hostname.endsWith('.alienai.id'))
      ? 'https://api.alienai.id'
      : '';
  }

  function siteIidFrom(el) {
    const section = el && el.closest ? el.closest('section[data-site-iid]') : null;
    if (section) {
      const v = parseInt(section.getAttribute('data-site-iid') || '0', 10);
      if (v) return v;
    }
    const g = window.__SITE_GUEST__;
    return g && g.site_iid ? g.site_iid : 0;
  }

  const PRODUCT_SHOPPING_SVG = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path fill="currentColor" d="M12 13a5 5 0 0 1-5-5h2a3 3 0 0 0 3 3a3 3 0 0 0 3-3h2a5 5 0 0 1-5 5m0-10a3 3 0 0 1 3 3H9a3 3 0 0 1 3-3m7 3h-2a5 5 0 0 0-5-5a5 5 0 0 0-5 5H5c-1.11 0-2 .89-2 2v12a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V8a2 2 0 0 0-2-2"/></svg>';

  function productPlaceholderHtml(item) {
    const raw = String((item && item.icon_svg) || '');
    const safe = raw.indexOf('<svg ') === 0 && !/<script|javascript:|on\w+=/i.test(raw)
      ? raw
      : PRODUCT_SHOPPING_SVG;
    return '<div class="product-ph" aria-hidden="true">' + safe + '</div>';
  }

  function productCategoryAttr(item) {
    const cat = String((item && item.category) || '').trim();
    if (!cat) return '';
    return ' data-product-category="' + escHtml(cat).replace(/"/g, '&quot;') + '"';
  }

  function guestAlienId() {
    const g = window.__SITE_GUEST__ || {};
    return String(g.alien_id || g.alienId || '').trim();
  }

  function guestDraftQuery() {
    const q = window.location.search || '';
    return /(?:^|[?&])draft=(?:1|true|yes)(?:&|$)/i.test(q) ? '?draft=1' : '';
  }

  function guestProductPageUrl(productId) {
    const draft = guestDraftQuery();
    const aid = guestAlienId();
    if (aid) {
      return '/' + aid + '/products/' + productId + draft;
    }
    const path = window.location.pathname || '/';
    const base = path.endsWith('/') ? path : path + '/';
    return base + 'products/' + productId + draft;
  }

  function productGalleryPaths(product) {
    const out = [];
    const primary = String(product && product.pic || '').trim();
    if (primary) out.push(primary);
    const extras = product && product.pics;
    if (Array.isArray(extras)) {
      for (let i = 0; i < extras.length; i++) {
        const e = String(extras[i] || '').trim();
        if (e && out.indexOf(e) < 0) out.push(e);
      }
    }
    return out;
  }

  function productPrimaryPic(product) {
    const paths = productGalleryPaths(product);
    return paths.length ? paths[0] : '';
  }

  function guestShareToast(msg) {
    const el = document.getElementById('c35-guest-toast');
    if (!el) return;
    el.textContent = msg;
    el.style.display = 'block';
    setTimeout(function () { el.style.display = 'none'; }, 2800);
  }

  function shareProduct(productId, name) {
    const url = new URL(guestProductPageUrl(productId), window.location.origin).href;
    const title = String(name || '').trim() || 'Product';
    if (navigator.share) {
      navigator.share({ title: title, url: url }).catch(function (err) {
        if (err && err.name === 'AbortError') return;
        if (navigator.clipboard && navigator.clipboard.writeText) {
          navigator.clipboard.writeText(url).then(function () { guestShareToast('Link copied'); });
        }
      });
      return;
    }
    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(url).then(function () { guestShareToast('Link copied'); });
      return;
    }
    window.prompt('Copy link:', url);
  }

  window.c35GuestShare = function () {
    const url = window.location.href;
    const title = document.title || 'Store';
    if (navigator.share) {
      navigator.share({ title: title, url: url }).catch(function (err) {
        if (err && err.name === 'AbortError') return;
        if (navigator.clipboard && navigator.clipboard.writeText) {
          navigator.clipboard.writeText(url).then(function () { guestShareToast('Link copied'); });
        }
      });
      return;
    }
    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(url).then(function () { guestShareToast('Link copied'); });
      return;
    }
    window.prompt('Copy link:', url);
  };

  function productPurchaseAction(item) {
    const pid = item.product_id;
    const i18n = guestI18nStrings();
    const price = Math.round(item.price || 0);
    if (price === GUEST_PRODUCT_PRICE_CONTACT) {
      return '<button type="button" class="guest-tile-cta guest-product-info-btn" data-product-info="' + pid + '">'
        + escHtml(i18n.tileContactCta) + '</button>';
    }
    return '';
  }

  window.c35GuestCatalog = window.c35GuestCatalog || {
    formatIdr,
    guestProductPriceLabel,
    productCardHtml(item) {
      const pic = item.pic || '';
      const thumb = picUrlThumb(pic) || pic;
      const displayUrl = picUrlDisplay(pic);
      const img = pic
        ? '<img class="guest-pic-thumb" src="' + thumb.replace(/"/g, '&quot;') + '" alt="" loading="lazy"'
          + ' data-pic-display="' + displayUrl.replace(/"/g, '&quot;') + '" role="button" tabindex="0"/>'
        : productPlaceholderHtml(item);
      const name = (item.name || '').replace(/</g, '&lt;').replace(/>/g, '&gt;');
      const desc = (item.desc || '').replace(/</g, '&lt;').replace(/>/g, '&gt;');
      const nameJs = (item.name || '').replace(/\\/g, '\\\\').replace(/'/g, "\\'");
      const picJs = (pic || '').replace(/\\/g, '\\\\').replace(/'/g, "\\'");
      const price = Math.round(item.price || 0);
      const pid = item.product_id;
      const canReserve = item.can_reserve === true || item.can_reserve === 1 || item.can_reserve === '1';
      let reserveAttr = '';
      if (canReserve) {
        reserveAttr = ' data-can-reserve="1"'
          + ' data-name="' + name.replace(/"/g, '&quot;') + '"'
          + ' data-price="' + price + '"'
          + ' data-pic="' + String(pic || '').replace(/"/g, '&quot;') + '"'
          + ' data-duration-value="' + (item.duration_value || 1) + '"'
          + ' data-duration-unit="' + escHtml(item.duration_unit || 'day') + '"'
          + ' data-unit-selection="' + escHtml(item.reservation_unit_selection || 'system') + '"';
      }
      const badgeHtml = canReserve
        ? '<span class="guest-product-pill guest-product-pill--reserve">Reservasi</span>'
        : (item.stock_show_to_customer && typeof item.stock_qty === 'number' && item.stock_qty > 0 && item.stock_qty <= 3)
          ? '<span class="guest-product-pill guest-product-pill--stock">Sisa ' + item.stock_qty + '</span>'
          : '';
      const priceLabel = guestProductPriceLabel(price);
      const quote = price === GUEST_PRODUCT_PRICE_CONTACT;
      const priceHtml = (!quote && priceLabel) ? '<span class="price">' + escHtml(priceLabel) + '</span>' : '';
      const bottomClass = quote ? ' product-bottom--quote' : '';
      const action = productPurchaseAction(item);
      return '<article class="product-card guest-product-tile" data-pid="' + pid + '"' + productCategoryAttr(item) + reserveAttr + '>'
        + '<div class="guest-product-thumb-wrap">' + badgeHtml + img + '<span class="guest-tile-cart-badge" hidden aria-hidden="true"></span></div>'
        + '<div class="product-info"><h3>' + name + '</h3><p>' + desc + '</p>'
        + '<div class="product-bottom' + bottomClass + '">' + priceHtml
        + action
        + '</div></div></article>';
    },
    productListRowHtml(item) {
      const pic = item.pic || '';
      const thumb = picUrlThumb(pic) || pic;
      const displayUrl = picUrlDisplay(pic);
      const img = pic
        ? '<img class="guest-pic-thumb" src="' + thumb.replace(/"/g, '&quot;') + '" alt="" loading="lazy"'
          + ' data-pic-display="' + displayUrl.replace(/"/g, '&quot;') + '" role="button" tabindex="0"/>'
        : productPlaceholderHtml(item);
      const name = (item.name || '').replace(/</g, '&lt;').replace(/>/g, '&gt;');
      const desc = (item.desc || '').replace(/</g, '&lt;').replace(/>/g, '&gt;');
      const nameJs = (item.name || '').replace(/\\/g, '\\\\').replace(/'/g, "\\'");
      const picJs = (pic || '').replace(/\\/g, '\\\\').replace(/'/g, "\\'");
      const price = Math.round(item.price || 0);
      const pid = item.product_id;
      const canReserve = item.can_reserve === true || item.can_reserve === 1 || item.can_reserve === '1';
      let reserveAttr = '';
      if (canReserve) {
        reserveAttr = ' data-can-reserve="1"'
          + ' data-name="' + name.replace(/"/g, '&quot;') + '"'
          + ' data-price="' + price + '"'
          + ' data-pic="' + String(pic || '').replace(/"/g, '&quot;') + '"'
          + ' data-duration-value="' + (item.duration_value || 1) + '"'
          + ' data-duration-unit="' + escHtml(item.duration_unit || 'day') + '"'
          + ' data-unit-selection="' + escHtml(item.reservation_unit_selection || 'system') + '"';
      }
      const priceLabel = guestProductPriceLabel(price);
      const quote = price === GUEST_PRODUCT_PRICE_CONTACT;
      const priceHtml = (!quote && priceLabel) ? '<span class="price">' + escHtml(priceLabel) + '</span>' : '';
      const action = productPurchaseAction(item);
      return '<article class="product-list-row guest-product-tile" data-pid="' + pid + '"' + productCategoryAttr(item) + reserveAttr + '>'
        + '<div class="product-list-thumb">' + img + '</div>'
        + '<div class="product-list-body"><h3>' + name + '</h3><p>' + desc + '</p></div>'
        + '<div class="product-list-trail">' + priceHtml + action + '</div></article>';
    },
    async loadMore(btn) {
      const section = btn && btn.closest ? btn.closest('section.product-grid') : null;
      if (!section) return;
      const siteIid = parseInt(section.getAttribute('data-site-iid') || '0', 10);
      const cursor = section.getAttribute('data-next-cursor') || '';
      if (!siteIid || !cursor) return;
      btn.disabled = true;
      btn.textContent = guestI18nStrings().loading;
      const payload = {
        site_iid: siteIid,
        filter: section.getAttribute('data-filter') || 'all',
        category: section.getAttribute('data-category') || '',
        cursor,
        limit: 24,
      };
      try {
        const resp = await fetch(apiBase() + '/v1/site/guest-product/list', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(payload),
        });
        if (!resp.ok) throw new Error((await resp.text()) || 'Gagal memuat produk');
        const data = await resp.json();
        const layout = section.querySelector('.grid, .list');
        const display = productGridDisplayFromSection(section);
        const items = (data && data.items) ? data.items : [];
        let html = '';
        const rowFn = display === 'list' ? this.productListRowHtml : this.productCardHtml;
        for (const item of items) html += rowFn(item);
        if (layout) layout.insertAdjacentHTML('beforeend', html);
        const next = (data && data.next_cursor) ? data.next_cursor : '';
        section.setAttribute('data-next-cursor', next);
        if (!next) btn.style.display = 'none';
        else {
          btn.disabled = false;
          btn.textContent = 'Muat lebih banyak';
        }
      } catch (err) {
        alert('Gagal memuat produk: ' + err.message);
        btn.disabled = false;
        btn.textContent = 'Muat lebih banyak';
      }
    },
  };

  window.c35GuestQueue = window.c35GuestQueue || {
    async take(btn) {
      const section = btn && btn.closest ? btn.closest('section.queue') : null;
      if (!section) return;
      const siteIid = siteIidFrom(btn);
      const queueId = parseInt(section.getAttribute('data-queue-id') || '0', 10);
      const statusEl = section.querySelector('.queue-status');
      btn.disabled = true;
      try {
        const resp = await fetch(apiBase() + '/v1/site/guest-queue/take', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ site_iid: siteIid, queue_id: queueId }),
        });
        const data = await resp.json();
        if (!data.ok) throw new Error(data.error || 'Gagal ambil nomor');
        if (statusEl) {
          statusEl.textContent = 'Nomor Anda: ' + data.ticket_no
            + ' (sedang dilayani: ' + data.serving_ticket_no + ')';
        }
        try {
          localStorage.setItem('c35_queue_ticket_' + siteIid, String(data.ticket_id));
        } catch (e) { /* ignore */ }
      } catch (err) {
        alert(err.message || String(err));
      } finally {
        btn.disabled = false;
      }
    },
  };

  function progressLabel(state, steps) {
    const s = `${state || ''}`;
    const list = steps || (window.__SITE_GUEST__ && window.__SITE_GUEST__.order_progress_steps) || [];
    for (const step of list) {
      if (step.state === s) return step.label || s;
    }
    return s || '—';
  }

  function renderProgressSteps(statusEl, state, steps) {
    if (!statusEl) return;
    const list = steps || [];
    const active = `${state || ''}`;
    let html = '<div class="guest-progress-steps">';
    for (const step of list) {
      const on = step.state === active ? ' guest-progress-on' : '';
      html += `<div class="guest-progress-step${on}"><span></span>${step.label || step.state}</div>`;
    }
    html += '</div>';
    statusEl.innerHTML = html;
  }

  window.c35GuestLead = window.c35GuestLead || {
    async submit(form) {
      const siteIid = siteIidFrom(form);
      if (!siteIid) {
        alert('Site tidak dikenali');
        return;
      }
      const fd = new FormData(form);
      const name = String(fd.get('name') || '').trim();
      const contactVal = String(fd.get('contact') || fd.get('contact_val') || fd.get('email') || '').trim();
      const message = String(fd.get('message') || '').trim();
      try {
        const resp = await fetch(apiBase() + '/v1/site/guest-contact/put', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ site_iid: siteIid, name, contact_val: contactVal, message }),
        });
        const data = await resp.json().catch(() => ({}));
        if (!resp.ok || data.ok === false) throw new Error(data.error || 'Gagal kirim');
        form.reset();
        alert('Pesan terkirim');
      } catch (err) {
        alert(err.message || String(err));
      }
    },
  };

  window.c35GuestOrder = window.c35GuestOrder || {
    async poll(btn) {
      const section = btn && btn.closest ? btn.closest('section.order-track') : null;
      if (!section) return;
      const siteIid = siteIidFrom(btn);
      const input = section.querySelector('.order-track-tx');
      const statusEl = section.querySelector('.order-track-status');
      const txId = parseInt((input && input.value) || '0', 10);
      if (!siteIid || !txId) {
        alert('Masukkan nomor pesanan');
        return;
      }
      btn.disabled = true;
      try {
        const resp = await fetch(apiBase() + '/v1/site/guest-order/get', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ site_iid: siteIid, tx_id: txId }),
        });
        if (!resp.ok) throw new Error((await resp.text()) || 'Pesanan tidak ditemukan');
        const data = await resp.json();
        const tx = data.tx || {};
        const state = tx.state || tx.status || '';
        const steps = window.__SITE_GUEST__ && window.__SITE_GUEST__.order_progress_steps;
        if (statusEl && steps && steps.length && state) {
          renderProgressSteps(statusEl, state, steps);
        } else if (statusEl) {
          const label = tx.progress_label || state || '—';
          statusEl.innerHTML = '<p class="order-track-label">' + String(label).replace(/</g, '&lt;') + '</p>';
        }
      } catch (err) {
        if (statusEl) statusEl.textContent = '';
        alert(err.message || String(err));
      } finally {
        btn.disabled = false;
      }
    },
  };

  function ordersStorageKey(siteIid) {
    return 'c35.guest.orders.v1.' + siteIid;
  }

  function loadOrders(siteIid) {
    try {
      const raw = localStorage.getItem(ordersStorageKey(siteIid));
      return raw ? JSON.parse(raw) : [];
    } catch (e) {
      return [];
    }
  }

  function saveOrder(siteIid, entry) {
    const list = loadOrders(siteIid);
    list.unshift(entry);
    localStorage.setItem(ordersStorageKey(siteIid), JSON.stringify(list.slice(0, 20)));
    if (window.c35GuestOrders) window.c35GuestOrders.refreshChip();
  }

  window.c35GuestCart = window.c35GuestCart || (function () {
    const g = window.__SITE_GUEST__ || {};
    const siteIid = g.site_iid || 0;
    const boot = g.commerce_boot || {};
    const products = new Map();
    for (const p of boot.products || []) {
      products.set(p.product_id, p);
    }
    const taxes = boot.taxes || [];
    const paymentMethods = boot.payment_methods || [];
    const storageKey = 'c35.guest.cart.v1.' + siteIid;

    function loadCart() {
      try {
        const raw = localStorage.getItem(storageKey);
        return raw ? JSON.parse(raw) : {};
      } catch (e) {
        return {};
      }
    }

    function migrateCart(raw) {
      const out = {};
      for (const pair of Object.entries(raw || {})) {
        const v = pair[1];
        if (typeof v === 'number') {
          if (v > 0) out[pair[0]] = { qty: v, note: '' };
        } else if (v && typeof v === 'object') {
          out[pair[0]] = v;
        }
      }
      return out;
    }

    let items = migrateCart(loadCart());
    let sheet = '';
    let orderProduct = null;
    let orderQty = 0;
    let orderNote = '';
    let orderError = '';
    let orderStockMax = null;
    const numpadKeys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '00', 'back'];
    let checkoutStep = 'confirm';
    let selectedPaymentId = paymentMethods.length ? paymentMethods[0].id : 'cash';
    let nameError = '';
    let checkoutError = '';
    let customerName = '';
    let customerPhone = '';
    let customerNotes = '';
    let busy = false;
    let reserveSeq = 0;
    let sheetMount = null;

    function persist() {
      localStorage.setItem(storageKey, JSON.stringify(items));
      refreshBar();
    }

    function isSlotLine(value) {
      return !!(value && typeof value === 'object' && Array.isArray(value.slots));
    }

    function slotDurationQty(slot) {
      if (slot.durationQty != null) return slot.durationQty;
      if (slot.duration_qty != null) return slot.duration_qty;
      return 0;
    }

    function slotsBillable(slots) {
      let n = 0;
      for (const slot of slots || []) {
        n += reservationBillable(slot.units || 0, slotDurationQty(slot));
      }
      return n;
    }

    function isProductLine(value) {
      return !!(value && typeof value === 'object' && !isSlotLine(value) && (value.qty != null || value.note != null));
    }

    function lineQty(value) {
      if (typeof value === 'number') return value;
      if (isSlotLine(value)) return slotsBillable(value.slots);
      if (isProductLine(value)) return value.qty || 0;
      return 0;
    }

    function lineView(key, value) {
      if (typeof value === 'number') {
        return { key: key, productId: parseInt(key, 10), qty: value, note: '', slots: null };
      }
      if (isSlotLine(value)) {
        return {
          key: key,
          productId: value.product_id,
          qty: slotsBillable(value.slots),
          note: '',
          slots: value.slots,
        };
      }
      if (isProductLine(value)) {
        return {
          key: key,
          productId: parseInt(key, 10),
          qty: value.qty || 0,
          note: value.note || '',
          slots: null,
        };
      }
      return null;
    }

    function checkoutLines() {
      const lines = [];
      eachLine(function (line) {
        const p = products.get(line.productId);
        lines.push({
          key: line.key,
          productId: line.productId,
          name: p ? p.name : 'Item',
          qty: line.qty,
          note: line.note || '',
          reservable: !!line.slots,
          lineTotal: lineTotal(line.productId, line.qty),
          slots: line.slots,
        });
      });
      return lines;
    }

    function taxLines() {
      const base = subtotal();
      return taxes.map(function (t) {
        const amount = Math.round(base * (t.percent || 0) / 100);
        return { id: t.id || t.name, name: t.name || 'Tax', percent: t.percent || 0, amount };
      });
    }

    function selectedPayment() {
      return paymentMethods.find(function (m) { return m.id === selectedPaymentId; }) || null;
    }

    function checkoutHeader() {
      if (checkoutStep === 'payment') return 'Metode pembayaran';
      if (checkoutStep === 'pay_detail') {
        const m = selectedPayment();
        return (m && (m.title || m.label)) || 'Pembayaran';
      }
      return 'Checkout';
    }

    function checkoutPrimaryLabel() {
      if (checkoutStep === 'confirm') {
        if (!paymentMethods.length) return 'Pesan \u00b7 ' + formatIdr(grandTotal());
        return 'Lanjut';
      }
      if (checkoutStep === 'payment') return 'Pilih metode';
      const m = selectedPayment();
      if (m && m.type === 'whatsapp') return 'Kirim via WhatsApp';
      return 'Konfirmasi \u00b7 ' + formatIdr(grandTotal());
    }

    function payIconHtml(method) {
      const t = (method && method.type) || '';
      const glyph = t === 'cash' ? '\uD83D\uDCB5' : (t === 'transfer' ? '\uD83C\uDFE6' : (t === 'qris' ? '\u25A3' : (t === 'whatsapp' ? '\uD83D\uDCAC' : '\u2022')));
      return '<span class="guest-pay-icon" aria-hidden="true">' + glyph + '</span>';
    }

    function transferSubtitle(method) {
      if (!method) return '';
      const bits = [method.bank, method.account_name, method.account_number].filter(function (x) {
        return !!(x && String(x).trim());
      });
      if (bits.length) return bits.join('\n');
      return (method.subtitle || method.title || '').trim();
    }

    function qrisData() {
      const m = selectedPayment();
      if (!m || m.type !== 'qris') return '';
      const pic = (m.qris_pic || m.qris_url || '').trim();
      if (pic) return picUrlDisplay(pic) || pic;
      return (m.account_number || m.account || '').trim();
    }

    function qrisIsImage(data) {
      const u = (data || '').trim();
      return u.startsWith('http://') || u.startsWith('https://') || u.startsWith('/fs/') || u.startsWith('data:');
    }

    function renderPayDetailHtml(method) {
      if (!method) return '<p class="guest-error">Metode tidak dipilih</p>';
      const t = method.type || '';
      if (t === 'cash') {
        return '<div class="guest-pay-detail-card"><div class="guest-pay-detail-sub" style="font-weight:700">Bayar di tempat</div></div>';
      }
      if (t === 'whatsapp') {
        const wa = (method.whatsapp || method.subtitle || '').trim();
        return '<div class="guest-pay-detail-card guest-pay-wa"><div class="guest-pay-detail-title">WhatsApp</div>'
          + '<div class="guest-pay-detail-sub">' + escHtml(wa || 'Hubungi toko via WhatsApp') + '</div></div>';
      }
      if (t === 'transfer') {
        return '<div class="guest-pay-detail-card guest-pay-transfer"><div class="guest-pay-detail-title">Transfer bank</div>'
          + '<div class="guest-pay-transfer-rows" style="white-space:pre-line">' + escHtml(transferSubtitle(method)) + '</div>'
          + '<div class="guest-checkout-row total" style="margin-top:12px"><span>Jumlah</span><span>'
          + escHtml(formatIdr(grandTotal())) + '</span></div></div>';
      }
      if (t === 'qris') {
        const data = qrisData();
        const has = data.length > 0;
        const img = has && qrisIsImage(data);
        let frame = '';
        if (img) frame = '<img class="guest-qris-img" src="' + escHtml(data) + '" alt="QRIS"/>';
        else if (has) frame = '<div class="guest-qris-empty"><span>QRIS</span></div>';
        else frame = '<div class="guest-qris-empty"><span>QRIS belum dikonfigurasi</span></div>';
        return '<div class="guest-qris-preview"><div class="guest-qris-frame' + (has ? ' has-data' : '') + '">' + frame
          + '</div><div class="guest-qris-amount">' + escHtml(formatIdr(grandTotal())) + '</div></div>';
      }
      return '<div class="guest-pay-detail-card"><div class="guest-pay-detail-sub">' + escHtml(method.title || method.id) + '</div></div>';
    }

    function countLabel() {
      const n = count();
      return n === 1 ? '1 item' : n + ' item';
    }

    function eachLine(fn) {
      for (const pair of Object.entries(items)) {
        const line = lineView(pair[0], pair[1]);
        if (line) fn(line);
      }
    }

    function lineTotal(productId, qty) {
      const p = products.get(productId);
      if (!p) return 0;
      return (p.price || 0) * qty;
    }

    function subtotal() {
      let s = 0;
      eachLine(function (line) {
        s += lineTotal(line.productId, line.qty);
      });
      return s;
    }

    function taxTotal() {
      let t = 0;
      const base = subtotal();
      for (const tax of taxes) {
        t += Math.round(base * (tax.percent || 0) / 100);
      }
      return t;
    }

    function grandTotal() {
      return subtotal() + taxTotal();
    }

    function count() {
      let n = 0;
      eachLine(function (line) { n += line.qty || 0; });
      return n;
    }

    function refreshTileBadges() {
      document.querySelectorAll('.guest-product-tile').forEach(function (tile) {
        const pid = parseInt(tile.getAttribute('data-pid') || '0', 10);
        const badge = tile.querySelector('.guest-tile-cart-badge');
        if (!badge) return;
        const line = items[pid];
        const qty = line && !isSlotLine(line) ? lineQty(line) : 0;
        if (qty > 0) {
          badge.hidden = false;
          badge.textContent = String(qty);
        } else {
          badge.hidden = true;
          badge.textContent = '';
        }
      });
    }

    function refreshBar() {
      const row = document.getElementById('c35-guest-cart-row');
      const bar = document.getElementById('c35-guest-cart-bar');
      const countEl = document.getElementById('c35-cart-count');
      const totalEl = document.getElementById('c35-cart-total');
      const n = count();
      const visible = n > 0 && !sheet;
      if (row) row.style.display = visible ? 'flex' : 'none';
      else if (bar) bar.style.display = visible ? 'flex' : 'none';
      if (countEl) countEl.textContent = countLabel();
      if (totalEl) totalEl.textContent = formatIdr(grandTotal());
      refreshTileBadges();
      if (window.c35GuestAssistant && window.c35GuestAssistant.syncCartLayout) {
        window.c35GuestAssistant.syncCartLayout();
      }
    }

    function toast(msg) {
      const el = document.getElementById('c35-guest-toast');
      if (!el) return;
      el.textContent = msg;
      el.style.display = 'block';
      setTimeout(() => {
        el.style.display = 'none';
      }, 3200);
    }

    function removeSheetMount() {
      if (sheetMount && sheetMount.parentNode) sheetMount.parentNode.removeChild(sheetMount);
      sheetMount = null;
      const legacy = document.getElementById('c35-guest-modal');
      if (legacy) legacy.style.display = 'none';
    }

    function renderSheet() {
      removeSheetMount();
      if (!sheet) return;
      sheetMount = document.createElement('div');
      sheetMount.className = 'guest-sheet-root';
      sheetMount.addEventListener('click', function (e) {
        if (e.target === sheetMount) api.closeSheet();
      });
      const inner = document.createElement('div');
      inner.className = 'guest-sheet' + (sheet === 'checkout' ? ' guest-sheet-tall' : '');
      inner.setAttribute('data-guest', sheet === 'order' ? 'order' : 'checkout');
      inner.addEventListener('click', function (e) { e.stopPropagation(); });
      if (sheet === 'order' && orderProduct) inner.innerHTML = renderOrderSheetHtml();
      else if (sheet === 'checkout') inner.innerHTML = renderCheckoutSheetHtml();
      sheetMount.appendChild(inner);
      document.body.appendChild(sheetMount);
      bindSheetEvents(inner);
      refreshBar();
    }

    function orderPriceLabel() {
      if (!orderProduct) return '';
      const total = (orderProduct.price || 0) * (orderQty || 0);
      return orderQty > 0 ? formatIdr(total) : formatIdr(orderProduct.price || 0);
    }

    function renderOrderSheetHtml() {
      const p = orderProduct;
      const picRaw = productPrimaryPic(p);
      const picUrl = picUrlThumb(picRaw) || picUrlDisplay(picRaw) || picRaw;
      const pic = picUrl
        ? '<img class="guest-order-pic guest-pic-preview" src="' + escHtml(picUrl) + '" alt="" data-pic-display="' + escHtml(picUrlDisplay(picRaw) || picUrl) + '" role="button" tabindex="0"/>'
        : '<div class="guest-order-pic guest-order-pic-empty">\uD83D\uDECD\uFE0F</div>';
      const descText = productDescText(p);
      const desc = descText ? '<p class="guest-product-desc">' + escHtml(descText) + '</p>' : '';
      const stock = orderStockMax != null ? '<p class="guest-stock">Stok: ' + orderStockMax + '</p>' : '';
      const err = orderError ? '<p class="guest-error">' + escHtml(orderError) + '</p>' : '';
      const keys = numpadKeys.map(function (k) {
        return '<button type="button" class="guest-numpad-key" data-numpad="' + escHtml(k) + '">' + (k === 'back' ? '⌫' : k) + '</button>';
      }).join('');
      const primary = orderQty > 0 ? ('Pesan ' + orderQty + ' item · ' + orderPriceLabel()) : 'Batalkan';
      return '<div class="guest-sheet-handle"></div><div class="guest-order-card"><div class="guest-order-pic-wrap">' + pic
        + (orderQty > 0 ? '<span class="guest-product-qty">' + orderQty + '</span>' : '') + '</div><div class="guest-order-info"><div class="guest-order-top">'
        + '<div class="guest-order-name">' + escHtml(p.name || 'Produk') + '</div><div class="guest-order-price">' + formatIdr(p.price || 0) + '</div></div>'
        + desc + '<label class="guest-note"><span>📝</span><textarea id="c35-order-note" rows="2" placeholder="Catatan (opsional)…">' + escHtml(orderNote) + '</textarea></label>'
        + '</div></div>' + stock + err + '<div class="guest-numpad">' + keys + '</div>'
        + '<button type="button" class="guest-sheet-primary' + (orderQty > 0 ? '' : ' muted') + '" id="c35-order-confirm">' + escHtml(primary) + '</button>';
    }

    function renderCheckoutSheetHtml() {
      const backBtn = checkoutStep !== 'confirm'
        ? '<button type="button" class="guest-icon-btn" id="c35-checkout-back" aria-label="Back">←</button>'
        : '<button type="button" class="guest-icon-btn" style="visibility:hidden" aria-hidden="true">←</button>';
      let body = '';
      if (checkoutStep === 'confirm') {
        const lineRows = checkoutLines().map(function (line) {
          const note = line.note ? '<div class="guest-checkout-line-note">Catatan: ' + escHtml(line.note) + '</div>' : '';
          const badge = line.reservable ? '<div class="guest-checkout-badge">Reservasi</div>' : '';
          return '<div class="guest-checkout-line"><span class="guest-checkout-qty">' + line.qty + '×</span><div class="guest-checkout-mid"><div class="guest-checkout-line-name">'
            + escHtml(line.name) + '</div>' + note + badge + '</div><div class="guest-checkout-line-price">' + formatIdr(line.lineTotal) + '</div></div>';
        }).join('');
        const taxRows = taxLines().map(function (t) {
          return '<div class="guest-checkout-row muted"><span>' + escHtml(t.name) + ' (' + t.percent + '%)</span><span>' + formatIdr(t.amount) + '</span></div>';
        }).join('');
        const sub = taxLines().length ? '<div class="guest-checkout-row muted"><span>Subtotal</span><span>' + formatIdr(subtotal()) + '</span></div>' : '';
        const warn = !paymentMethods.length ? '<div class="guest-warn-box">Belum ada metode pembayaran di Publish.</div>' : '';
        body = '<div class="guest-checkout-body"><div class="guest-checkout-lines">' + (lineRows || '<p>Keranjang kosong</p>') + '</div>' + sub + taxRows
          + '<div class="guest-checkout-row total"><span>Total</span><span>' + formatIdr(grandTotal()) + '</span></div>'
          + '<label class="guest-field"><span>Nama</span><input type="text" id="c35-guest-name" value="' + escHtml(customerName) + '" placeholder="Nama Anda"/>'
          + (nameError ? '<span class="guest-error">' + escHtml(nameError) + '</span>' : '') + '</label>'
          + '<label class="guest-field"><span>HP / WhatsApp</span><input type="text" id="c35-guest-phone" value="' + escHtml(customerPhone) + '" placeholder="08..."/></label>'
          + '<label class="guest-field"><span>Catatan pesanan</span><textarea id="c35-guest-notes" rows="2">' + escHtml(customerNotes) + '</textarea></label>' + warn + '</div>';
      } else if (checkoutStep === 'payment') {
        body = '<div class="guest-checkout-body">' + paymentMethods.map(function (m) {
          return '<button type="button" class="guest-pay-option" data-pay-id="' + escHtml(m.id) + '">' + payIconHtml(m)
            + '<span class="guest-pay-text"><span class="guest-pay-label">' + escHtml(m.title || m.id) + '</span>'
            + (m.subtitle ? '<span class="guest-pay-meta">' + escHtml(m.subtitle) + '</span>' : '')
            + '</span><span class="guest-pay-chevron">\u203A</span></button>';
        }).join('') + '</div>';
      } else if (checkoutStep === 'pay_detail') {
        body = '<div class="guest-checkout-body guest-pay-detail">' + renderPayDetailHtml(selectedPayment()) + '</div>';
      }
      return '<div class="guest-sheet-handle"></div><div class="guest-sheet-header">' + backBtn + '<h2 class="guest-sheet-title-center">' + escHtml(checkoutHeader())
        + '</h2><button type="button" class="guest-icon-btn" id="c35-sheet-close" aria-label="Close">×</button></div>' + body
        + '<div class="guest-sheet-footer"><button type="button" class="guest-sheet-primary" id="c35-checkout-primary">' + escHtml(checkoutPrimaryLabel()) + '</button>'
        + (checkoutError ? '<p class="guest-error">' + escHtml(checkoutError) + '</p>' : '') + '</div>';
    }

    function bindSheetEvents(root) {
      root.querySelector('#c35-sheet-close')?.addEventListener('click', () => api.closeSheet());
      root.querySelector('#c35-checkout-back')?.addEventListener('click', () => api.checkoutBack());
      root.querySelector('#c35-checkout-primary')?.addEventListener('click', () => api.checkoutPrimary());
      root.querySelector('#c35-order-confirm')?.addEventListener('click', () => api.confirmOrder());
      root.querySelector('#c35-order-note')?.addEventListener('input', (e) => { orderNote = e.target.value; });
      root.querySelectorAll('[data-numpad]').forEach((btn) => {
        btn.addEventListener('click', () => api.numpad(btn.getAttribute('data-numpad')));
      });
      root.querySelectorAll('[data-pay-id]').forEach((btn) => {
        btn.addEventListener('click', () => api.selectPayment(btn.getAttribute('data-pay-id')));
      });
      root.querySelector('#c35-guest-name')?.addEventListener('input', (e) => { customerName = e.target.value; nameError = ''; });
      root.querySelector('#c35-guest-phone')?.addEventListener('input', (e) => { customerPhone = e.target.value; });
      root.querySelector('#c35-guest-notes')?.addEventListener('input', (e) => { customerNotes = e.target.value; });
    }

    const api = {
      openOrder(pid) {
        const id = Number(pid);
        let p = products.get(id);
        if (!p) {
          p = { product_id: id, name: 'Produk', price: 0, can_reserve: false };
          products.set(id, p);
        }
        if (p.can_reserve) {
          if (window.c35GuestReserve) window.c35GuestReserve.open(p);
          return;
        }
        const key = String(id);
        const line = items[key];
        orderProduct = p;
        orderQty = line && isProductLine(line) ? (line.qty || 0) : (typeof line === 'number' ? line : 0);
        orderNote = line && isProductLine(line) ? (line.note || '') : '';
        orderError = '';
        const track = p.track_stock === true || p.track_stock === 1;
        const stockVal = p.stock_count != null ? p.stock_count : p.stock_qty;
        orderStockMax = track && typeof stockVal === 'number' && stockVal >= 0 ? stockVal : null;
        sheet = 'order';
        renderSheet();
      },
      numpad(key) {
        orderError = '';
        if (key === 'back') {
          const cur = String(orderQty);
          orderQty = cur.length <= 1 ? 0 : parseInt(cur.slice(0, -1), 10) || 0;
        } else {
          const nextStr = (orderQty === 0 ? '' : String(orderQty)) + key;
          let next = parseInt(nextStr, 10);
          if (Number.isNaN(next)) return;
          if (next > 9999) next = 9999;
          if (orderStockMax != null && next > orderStockMax) {
            orderError = 'Stok hanya ' + orderStockMax;
            orderQty = orderStockMax;
            renderSheet();
            return;
          }
          orderQty = next;
        }
        renderSheet();
      },
      confirmOrder() {
        const p = orderProduct;
        if (!p) return;
        const key = String(p.product_id);
        if (orderQty <= 0) delete items[key];
        else items[key] = { qty: orderQty, note: (orderNote || '').trim() };
        persist();
        api.closeSheet();
      },
      pesan() {
        if (!count()) return;
        checkoutStep = 'confirm';
        checkoutError = '';
        nameError = '';
        sheet = 'checkout';
        renderSheet();
      },
      closeSheet() {
        sheet = '';
        orderProduct = null;
        orderError = '';
        nameError = '';
        checkoutStep = 'confirm';
        removeSheetMount();
        refreshBar();
      },
      checkoutBack() {
        if (checkoutStep === 'pay_detail') {
          checkoutStep = 'payment';
          renderSheet();
          return;
        }
        if (checkoutStep === 'payment') {
          checkoutStep = 'confirm';
          renderSheet();
          return;
        }
        api.closeSheet();
      },
      selectPayment(id) {
        selectedPaymentId = id;
        checkoutStep = 'pay_detail';
        renderSheet();
      },
      checkoutPrimary() {
        if (checkoutStep === 'confirm') {
          if (!customerName.trim()) {
            nameError = 'Nama wajib diisi';
            renderSheet();
            return;
          }
          if (!paymentMethods.length) {
            api.submit();
            return;
          }
          checkoutStep = 'payment';
          renderSheet();
          return;
        }
        if (checkoutStep === 'payment') return;
        if (checkoutStep === 'pay_detail') {
          const m = selectedPayment();
          api.submit(!!(m && m.type === 'whatsapp'));
        }
      },
      add(pid, name, price, pic) {
        if (!products.has(pid)) {
          products.set(pid, { product_id: pid, name, price, pic, can_reserve: false });
        }
        api.openOrder(pid);
      },
      confirmReservation(product, slots) {
        if (!product || !slots || !slots.length) return;
        const pid = product.product_id;
        const prev = products.get(pid) || {};
        products.set(pid, Object.assign({}, prev, product, { can_reserve: true }));
        reserveSeq += 1;
        const key = 'r:' + pid + ':' + Date.now() + ':' + reserveSeq;
        items[key] = { product_id: pid, slots: slots };
        persist();
        toast('Reservasi ditambahkan');
      },
      openModal() { api.pesan(); },
      checkoutLines,
      closeModal() { api.closeSheet(); },
      async submit(openWhatsAppAfter) {
        if (busy || !siteIid) return;
        const name = customerName.trim();
        if (!name) {
          nameError = 'Nama wajib diisi';
          checkoutStep = 'confirm';
          renderSheet();
          return;
        }
        const txItems = [];
        eachLine(function (line) {
          if (!line.qty) return;
          if (line.slots) {
            const reservations = line.slots.flatMap(function (s) {
              return guestReservationsFromSlot(s, line.productId);
            });
            const qty = reservations.reduce(function (sum, r) {
              return sum + reservationBillable(r.qty, r.duration_qty);
            }, 0);
            txItems.push({
              product_id: line.productId,
              qty: qty,
              reservations: reservations,
            });
          } else {
            const item = { product_id: line.productId, qty: line.qty };
            if (line.note) item.note = line.note;
            txItems.push(item);
          }
        });
        if (!txItems.length) return;
        busy = true;
        checkoutError = '';
        renderSheet();
        const savedTotal = grandTotal();
        try {
          const payLabel = (paymentMethods.find(function (m) { return m.id === selectedPaymentId; }) || {}).title || selectedPaymentId;
          const baseNote = (customerNotes || '').trim();
          const lineNotes = checkoutLines().filter(function (l) { return l.note; }).map(function (l) { return l.name + ': ' + l.note; }).join('\n');
          const merged = [baseNote, lineNotes].filter(Boolean).join('\n');
          const payLine = payLabel ? ('Pembayaran: ' + payLabel) : '';
          const fullNote = payLine ? (merged ? (merged + '\n' + payLine) : payLine) : merged;
          const resp = await fetch(apiBase() + '/v1/site/guest-order/put', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              site_iid: siteIid,
              customer_name: name,
              customer_phone: (customerPhone || '').trim(),
              note: fullNote,
              tx: {
                subject_name: name,
                subject_phone: (customerPhone || '').trim(),
                desc: fullNote,
                items: txItems,
              },
            }),
          });
          const data = await resp.json().catch(() => ({}));
          if (!resp.ok) throw new Error(data.error || (await resp.text()) || 'Gagal kirim pesanan');
          const tx = data.tx || {};
          const txId = tx.tx_id || tx.txId;
          saveOrder(siteIid, {
            tx_id: txId,
            total: tx.total || savedTotal,
            placed_ts_ms: Date.now(),
          });
          items = {};
          persist();
          api.closeSheet();
          toast('Pesanan #' + txId + ' diterima');
          if (openWhatsAppAfter) {
            const m = selectedPayment();
            const digits = String(m && (m.whatsapp || m.subtitle) || '').replace(/\D/g, '');
            if (digits) {
              const text = encodeURIComponent('Halo, pesanan #' + txId + ' \u2014 ' + formatIdr(savedTotal));
              window.open('https://wa.me/' + digits + '?text=' + text, '_blank', 'noopener');
            }
          }
        } catch (err) {
          checkoutError = err.message || String(err);
          renderSheet();
        } finally {
          busy = false;
          if (sheet === 'checkout') renderSheet();
        }
      },
    };

    refreshBar();
    return api;
  })();

  function initGuestCatalogFilters() {
    document.querySelectorAll('.guest-catalog-filters').forEach(function (bar) {
      if (bar.getAttribute('data-bound') === '1') return;
      bar.setAttribute('data-bound', '1');
      const section = bar.closest('section.product-grid');
      if (!section) return;
      bar.addEventListener('click', function (e) {
        const chip = e.target && e.target.closest ? e.target.closest('.guest-catalog-chip') : null;
        if (!chip || !bar.contains(chip)) return;
        const filter = chip.getAttribute('data-guest-filter') || '';
        bar.querySelectorAll('.guest-catalog-chip').forEach(function (c) {
          const active = c === chip;
          c.classList.toggle('is-active', active);
          c.setAttribute('aria-pressed', active ? 'true' : 'false');
        });
        section.querySelectorAll('.guest-product-tile').forEach(function (tile) {
          const cat = tile.getAttribute('data-product-category') || '';
          const show = !filter || cat === filter;
          tile.hidden = !show;
          tile.classList.toggle('is-filtered-out', !show);
        });
      });
    });
  }

  function initGuestStickyBar() {
    const bar = document.getElementById('c35-guest-sticky');
    if (!bar || bar.getAttribute('data-bound') === '1') return;
    bar.setAttribute('data-bound', '1');
    const titleEl = bar.querySelector('.guest-sticky-title');
    const avatarEl = bar.querySelector('.guest-sticky-avatar');
    const ctaEl = bar.querySelector('.guest-sticky-cta');
    const hubTitle = document.querySelector('.guest-hub-title');
    const hubAvatar = document.querySelector('.guest-hub-avatar, .hub-avatar');
    if (titleEl && hubTitle) titleEl.textContent = hubTitle.textContent || '';
    if (avatarEl && hubAvatar && hubAvatar.getAttribute('src')) {
      avatarEl.src = hubAvatar.getAttribute('src');
      avatarEl.hidden = false;
    }
    const link = document.querySelector('a.guest-link-list[href]');
    if (ctaEl && link) {
      ctaEl.href = link.getAttribute('href') || '#';
      ctaEl.textContent = (link.querySelector('.guest-link-label') || {}).textContent || guestI18nStrings().tileContactCta;
      ctaEl.hidden = false;
    }
    function onScroll() {
      const show = window.scrollY > 72;
      bar.hidden = !show;
      bar.setAttribute('aria-hidden', show ? 'false' : 'true');
      bar.classList.toggle('is-visible', show);
    }
    window.addEventListener('scroll', onScroll, { passive: true });
    onScroll();
  }

  window.c35GuestCatalogUi = {
    init() {
      if (window.__c35CatalogUiBound) return;
      window.__c35CatalogUiBound = true;
      initGuestCatalogFilters();
      initGuestStickyBar();
      if (!document.getElementById('c35-guest-pic-lightbox-style')) {
        const st = document.createElement('style');
        st.id = 'c35-guest-pic-lightbox-style';
        st.textContent = '.guest-pic-lightbox{position:fixed;inset:0;z-index:9999;background:rgba(0,0,0,.85);display:flex;align-items:center;justify-content:center;padding:24px}'
          + '.guest-pic-lightbox img{max-width:100%;max-height:100%;object-fit:contain;border-radius:8px}'
          + '.guest-pic-lightbox-close{position:absolute;top:12px;right:16px;border:0;background:transparent;color:#fff;font-size:32px;cursor:pointer}';
        document.head.appendChild(st);
      }
      document.addEventListener('click', function (e) {
        const shareBtn = e.target && e.target.closest
          ? e.target.closest('.guest-product-share-btn')
          : null;
        if (shareBtn) {
          e.preventDefault();
          e.stopPropagation();
          const pid = shareBtn.getAttribute('data-product-share');
          if (pid) {
            const found = bootProducts().find(function (p) { return String(p.product_id) === String(pid); });
            shareProduct(pid, found && found.name);
          }
          return;
        }
        const detailBtn = e.target && e.target.closest
          ? e.target.closest('.guest-tile-cta[data-product-info]')
          : null;
        if (detailBtn) {
          e.preventDefault();
          e.stopPropagation();
          const pid = detailBtn.getAttribute('data-product-info');
          if (pid) window.location.href = guestProductPageUrl(pid);
          return;
        }
        const orderPic = e.target && e.target.closest ? e.target.closest('img.guest-order-pic') : null;
        if (orderPic) {
          const url = orderPic.getAttribute('data-pic-display') || orderPic.getAttribute('src') || '';
          if (url) {
            e.preventDefault();
            e.stopPropagation();
            openPicLightbox(url);
          }
          return;
        }
        const tile = e.target && e.target.closest ? e.target.closest('.guest-product-tile') : null;
        if (tile && window.c35GuestCart) {
          const pid = parseInt(tile.getAttribute('data-pid') || '0', 10);
          if (!pid) return;
          const found = bootProducts().find(function (p) { return Number(p.product_id) === pid; });
          const price = found ? Math.round(found.price || 0) : parseInt(attrOf(tile, 'data-price') || '0', 10) || 0;
          const name = found ? (found.name || 'Produk') : (attrOf(tile, 'data-name') || 'Produk');
          const pic = found ? (found.pic || '') : (attrOf(tile, 'data-pic') || '');
          const canReserve = found
            ? (found.can_reserve === true || found.can_reserve === 1)
            : tile.getAttribute('data-can-reserve') === '1';
          if (canReserve) {
            e.preventDefault();
            const product = found || {
              product_id: pid,
              name,
              price,
              pic,
              can_reserve: true,
              duration_value: parseInt(attrOf(tile, 'data-duration-value') || '1', 10) || 1,
              duration_unit: attrOf(tile, 'data-duration-unit') || 'day',
              reservation_unit_selection: attrOf(tile, 'data-unit-selection') || 'system',
            };
            if (window.c35GuestReserve) window.c35GuestReserve.open(product);
            return;
          }
          if (!guestProductCanAddToCart(price)) return;
          e.preventDefault();
          if (!found) {
            window.c35GuestCart.add(pid, name, price, pic);
          } else {
            window.c35GuestCart.openOrder(pid);
          }
          return;
        }
        const img = e.target && e.target.closest ? e.target.closest('img.guest-pic-thumb') : null;
        if (img) {
          const url = img.getAttribute('data-pic-display') || img.getAttribute('src') || '';
          if (url) {
            e.preventDefault();
            openPicLightbox(url);
          }
        }
      });
    },
  };

  window.c35GuestReserve = {
    init() {
      if (window.__c35ReserveBound) return;
      window.__c35ReserveBound = true;
      document.addEventListener('click', function (e) {
        const btn = e.target && e.target.closest ? e.target.closest('.guest-reserve-btn') : null;
        if (!btn) return;
        e.preventDefault();
        const product = productFromButton(btn);
        if (product) window.c35GuestReserve.open(product);
      });
    },
    open(product) {
      openSheet(product);
    },
  };

  function bootProducts() {
    const g = window.__SITE_GUEST__ || {};
    const boot = g.commerce_boot || {};
    return boot.products || [];
  }

  function bootObjects() {
    const g = window.__SITE_GUEST__ || {};
    const boot = g.commerce_boot || {};
    return boot.objects || [];
  }

  function attrOf(el, name) {
    return el ? (el.getAttribute(name) || '') : '';
  }

  function productFromButton(btn) {
    const pid = parseInt(btn.getAttribute('data-reserve-product') || '0', 10);
    if (!pid) return null;
    const card = btn.closest ? btn.closest('[data-pid]') : null;
    const fromDom = {
      product_id: pid,
      name: attrOf(card, 'data-name') || 'Produk',
      price: parseInt(attrOf(card, 'data-price') || '0', 10) || 0,
      pic: attrOf(card, 'data-pic') || '',
      can_reserve: true,
      duration_value: parseInt(attrOf(card, 'data-duration-value') || '1', 10) || 1,
      duration_unit: attrOf(card, 'data-duration-unit') || 'day',
      reservation_unit_selection: attrOf(card, 'data-unit-selection') || 'system',
    };
    const found = bootProducts().find(function (p) { return Number(p.product_id) === pid; });
    if (!found) return fromDom;
    return {
      product_id: pid,
      name: found.name || fromDom.name,
      price: found.price != null ? found.price : fromDom.price,
      pic: found.pic || fromDom.pic,
      can_reserve: true,
      duration_value: found.duration_value || fromDom.duration_value || 1,
      duration_unit: found.duration_unit || fromDom.duration_unit || 'day',
      reservation_unit_selection: found.reservation_unit_selection || fromDom.reservation_unit_selection || 'system',
    };
  }

  function pad2(n) {
    return String(n).padStart(2, '0');
  }

  function formatField(date, needsTime) {
    const y = date.getFullYear();
    const m = pad2(date.getMonth() + 1);
    const d = pad2(date.getDate());
    const day = y + '-' + m + '-' + d;
    if (!needsTime) return day;
    return day + 'T' + pad2(date.getHours()) + ':' + pad2(date.getMinutes());
  }

  function defaultStart(needsTime) {
    const now = new Date();
    if (!needsTime) return new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0, 0);
    return new Date(now.getFullYear(), now.getMonth(), now.getDate(), now.getHours(), now.getMinutes(), 0, 0);
  }

  function makeSlot(product) {
    const unit = product.duration_unit || 'day';
    const needs = reservationNeedsTime(unit);
    const count = Math.max(1, product.duration_value || 1);
    const start = defaultStart(needs);
    const end = reservationEndFromDuration(start, unit, count);
    return {
      units: 1,
      durationCount: count,
      start: start,
      end: end,
      site_object_id: 0,
      objectName: '',
      assignments: [null],
      pickAssignIndex: null,
      freeIds: null,
      unitsAvailable: null,
      availTimer: null,
      availGen: 0,
    };
  }

  function sheetBillable(slots) {
    let n = 0;
    for (const slot of slots) n += reservationBillable(slot.units, slot.durationCount);
    return n;
  }

  function closeReservationSheet() {
    const sheet = document.querySelector('[data-guest="reservation"]');
    if (!sheet) return;
    const scrim = sheet.closest('.guest-sheet-scrim');
    (scrim || sheet).remove();
  }

  function openSheet(product) {
    closeReservationSheet();
    const unit = product.duration_unit || 'day';
    const needsTime = reservationNeedsTime(unit);
    const guestPicks = product.reservation_unit_selection === 'guest_picks';
    const objects = bootObjects().filter(function (o) {
      return Number(o.product_id) === Number(product.product_id);
    });
    const slots = [makeSlot(product)];
    let pickSlotIndex = null;
    let pickAssignIndex = null;
    let alive = true;
    const scrim = document.createElement('div');
    scrim.className = 'guest-sheet-scrim';
    const sheet = document.createElement('div');
    sheet.className = 'guest-sheet guest-sheet-tall';
    sheet.setAttribute('data-guest', 'reservation');
    scrim.appendChild(sheet);
    document.body.appendChild(scrim);

    function inputType() {
      return needsTime ? 'datetime-local' : 'date';
    }

    function scheduleAvail(slot) {
      if (slot.availTimer) clearTimeout(slot.availTimer);
      slot.availTimer = setTimeout(function () { loadAvail(slot); }, 300);
    }

    async function loadAvail(slot) {
      const g = window.__SITE_GUEST__ || {};
      const siteIid = g.site_iid || 0;
      const startMs = slot.start && slot.start.getTime ? slot.start.getTime() : NaN;
      const endMs = slot.end && slot.end.getTime ? slot.end.getTime() : NaN;
      if (!alive || !siteIid || !isFinite(startMs) || !isFinite(endMs) || endMs <= startMs) return;
      const gen = (slot.availGen || 0) + 1;
      slot.availGen = gen;
      try {
        const resp = await fetch(apiBase() + '/v1/site/guest-reservation/availability', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            site_iid: siteIid,
            product_id: product.product_id,
            start_ts_ms: startMs,
            end_ts_ms: endMs,
            units: slot.units,
          }),
        });
        if (!alive || slot.availGen !== gen || !resp.ok) return;
        const data = await resp.json();
        const free = Array.isArray(data.free_objects) ? data.free_objects : [];
        slot.freeIds = new Set(free.map(function (o) { return Number(o.id); }));
        slot.unitsAvailable = data.units_available;
        const nextAssign = guestAssignmentsFit(slot.assignments, slot.units || 1);
        nextAssign.forEach(function (pick, i) {
          const id = pick && pick.site_object_id ? Number(pick.site_object_id) : 0;
          if (id > 0 && !slot.freeIds.has(id)) nextAssign[i] = null;
        });
        slot.assignments = nextAssign;
        if (slot.site_object_id && !slot.freeIds.has(Number(slot.site_object_id))) {
          slot.site_object_id = 0;
          slot.objectName = '';
        }
        if (alive) render();
      } catch (e) {
        /* leave the sheet usable */
      }
    }

    function render() {
      const billable = sheetBillable(slots);
      const price = Math.round(product.price || 0);
      const total = price * billable;
      const pic = product.pic
        ? '<img class="guest-reserve-pic" src="' + escHtml(product.pic) + '" alt="">'
        : '';
      const slotHtml = slots.map(function (slot, index) {
        const left = slot.unitsAvailable == null
          ? ''
          : '<p class="guest-units-left">Unit left: ' + slot.unitsAvailable + '</p>';
        let seats = '';
        if (guestPicks) {
          const assigns = guestAssignmentsFit(slot.assignments, slot.units || 1);
          const chips = assigns.map(function (pick, ai) {
            const label = pick && pick.objectName ? pick.objectName : ('Unit ' + (ai + 1));
            const on = pickSlotIndex === index && pickAssignIndex === ai;
            return '<button type="button" class="guest-assign-chip' + (on ? ' guest-assign-chip-on' : '') + '"'
              + ' data-pick-slot="' + index + '" data-pick-assign="' + ai + '">' + escHtml(label) + '</button>';
          }).join('');
          let grid = '';
          if (pickSlotIndex === index && pickAssignIndex != null) {
            const taken = guestTakenObjIds(slots, slot, pickAssignIndex);
            const current = assigns[pickAssignIndex];
            const currentId = current && current.site_object_id ? Number(current.site_object_id) : 0;
            const autoCls = 'guest-seat' + (currentId <= 0 ? ' guest-seat-on' : '');
            const autoBtn = '<button type="button" class="' + autoCls + '" data-seat="' + index + '" data-object-id="0">'
              + '<span class="guest-seat-fallback">A</span><span>Auto</span></button>';
            const tiles = objects.map(function (o) {
              const id = Number(o.id);
              const dimAvail = slot.freeIds && !slot.freeIds.has(id);
              const dimTaken = taken.has(id) && currentId !== id;
              const dim = dimAvail || dimTaken;
              const on = currentId === id;
              const cls = 'guest-seat' + (on ? ' guest-seat-on' : '') + (dim ? ' guest-seat-dim' : '');
              const img = o.pic
                ? '<img src="' + escHtml(o.pic) + '" alt="">'
                : '<span class="guest-seat-fallback">' + escHtml(String(o.name || o.code || '?').slice(0, 1)) + '</span>';
              return '<button type="button" class="' + cls + '" data-seat="' + index + '" data-assign="' + pickAssignIndex + '" data-object-id="' + id + '"'
                + (dim ? ' disabled' : '') + '>'
                + img + '<span>' + escHtml(o.name || o.code || '') + '</span></button>';
            }).join('');
            grid = '<div class="guest-seat-grid">' + autoBtn + tiles + '</div>';
          }
          seats = '<div class="guest-assign-chips">' + chips + '</div>' + grid;
        }
        const remove = slots.length > 1
          ? '<button type="button" class="guest-close-btn" data-remove-slot="' + index + '">\u00d7</button>'
          : '';
        return '<div class="guest-slot-card" data-slot="' + index + '">'
          + '<div class="guest-slot-head"><span>Slot ' + (index + 1) + '</span>' + remove + '</div>'
          + '<div class="guest-stepper"><span>Unit</span>'
          + '<button type="button" data-step="units" data-dir="-1" data-slot="' + index + '">\u2212</button>'
          + '<strong>' + slot.units + '</strong>'
          + '<button type="button" data-step="units" data-dir="1" data-slot="' + index + '">+</button></div>'
          + '<div class="guest-stepper"><span>Durasi</span>'
          + '<button type="button" data-step="duration" data-dir="-1" data-slot="' + index + '">\u2212</button>'
          + '<strong>' + slot.durationCount + '</strong>'
          + '<button type="button" data-step="duration" data-dir="1" data-slot="' + index + '">+</button></div>'
          + '<label class="guest-field"><span>Mulai</span>'
          + '<input type="' + inputType() + '" data-field="start" data-slot="' + index + '" value="' + formatField(slot.start, needsTime) + '"></label>'
          + '<label class="guest-field"><span>Selesai</span>'
          + '<input type="' + inputType() + '" data-field="end" data-slot="' + index + '" value="' + formatField(slot.end, needsTime) + '"></label>'
          + left + seats + '</div>';
      }).join('');
      const label = 'OK \u00b7 ' + slots.length + ' \u00b7 ' + formatIdr(total);
      sheet.innerHTML = '<div class="guest-reserve-head">' + pic
        + '<div class="guest-reserve-copy"><div class="guest-reserve-name">' + escHtml(product.name || '')
        + ' <span class="guest-billable-badge">' + billable + '</span></div>'
        + '<div class="guest-reserve-total">' + formatIdr(total) + '</div>'
        + '<div class="guest-reserve-unit">' + formatIdr(price) + ' / ' + escHtml(unit) + '</div></div>'
        + '<button type="button" class="guest-close-btn" data-act="close">\u00d7</button></div>'
        + slotHtml
        + '<button type="button" class="guest-add-slot" data-act="add-slot">Slot Reservasi</button>'
        + '<button type="button" class="guest-submit-btn guest-reserve-ok" data-act="ok"'
        + (billable > 0 ? '' : ' disabled') + '>' + label + '</button>';
      bind();
    }

    function bind() {
      sheet.querySelector('[data-act="close"]').addEventListener('click', function () { destroy(); });
      sheet.querySelector('[data-act="add-slot"]').addEventListener('click', function () {
        const slot = makeSlot(product);
        slots.push(slot);
        render();
        scheduleAvail(slot);
      });
      sheet.querySelector('[data-act="ok"]').addEventListener('click', function () {
        if (sheetBillable(slots) <= 0) return;
        const payload = slots.map(function (s) {
          const assigns = guestPicks ? guestAssignmentsFit(s.assignments, s.units || 1) : [];
          const first = assigns.length ? assigns[0] : null;
          return {
            units: s.units,
            durationQty: s.durationCount,
            start_ts_ms: s.start.getTime(),
            end_ts_ms: s.end.getTime(),
            site_object_id: first && first.site_object_id ? Number(first.site_object_id) : (s.site_object_id || 0),
            objectName: first && first.objectName ? first.objectName : (s.objectName || ''),
            assignments: assigns,
            startLabel: formatField(s.start, needsTime),
            endLabel: formatField(s.end, needsTime),
          };
        }).filter(function (s) { return reservationBillable(s.units, s.durationQty) > 0; });
        if (!payload.length || !window.c35GuestCart || !window.c35GuestCart.confirmReservation) return;
        window.c35GuestCart.confirmReservation(product, payload);
        destroy();
      });
      sheet.querySelectorAll('[data-remove-slot]').forEach(function (btn) {
        btn.addEventListener('click', function () {
          const index = parseInt(btn.getAttribute('data-remove-slot'), 10);
          const slot = slots[index];
          if (slot && slot.availTimer) clearTimeout(slot.availTimer);
          slots.splice(index, 1);
          render();
        });
      });
      sheet.querySelectorAll('[data-step]').forEach(function (btn) {
        btn.addEventListener('click', function () {
          const index = parseInt(btn.getAttribute('data-slot'), 10);
          const slot = slots[index];
          if (!slot) return;
          const dir = parseInt(btn.getAttribute('data-dir'), 10);
          const step = btn.getAttribute('data-step');
          if (step === 'units') {
            slot.units = Math.max(1, (slot.units || 1) + dir);
            slot.assignments = guestAssignmentsFit(slot.assignments, slot.units);
            if (pickAssignIndex != null && pickAssignIndex >= slot.units) {
              pickSlotIndex = null;
              pickAssignIndex = null;
            }
            render();
            scheduleAvail(slot);
          } else {
            slot.durationCount = Math.max(1, (slot.durationCount || 1) + dir);
            slot.end = reservationEndFromDuration(slot.start, unit, slot.durationCount);
            render();
            scheduleAvail(slot);
          }
        });
      });
      sheet.querySelectorAll('input[data-field]').forEach(function (input) {
        input.addEventListener('change', function () {
          const index = parseInt(input.getAttribute('data-slot'), 10);
          const slot = slots[index];
          if (!slot) return;
          const next = reservationInstant(input.value);
          if (!isFinite(next.getTime())) return;
          if (input.getAttribute('data-field') === 'start') {
            const count = slot.durationCount;
            slot.start = next;
            slot.end = reservationEndFromDuration(slot.start, unit, count);
          } else {
            slot.end = next;
            slot.durationCount = reservationDurationCount(slot.start, slot.end, unit);
          }
          render();
          scheduleAvail(slot);
        });
      });
      sheet.querySelectorAll('[data-pick-assign]').forEach(function (btn) {
        btn.addEventListener('click', function () {
          const index = parseInt(btn.getAttribute('data-pick-slot'), 10);
          const ai = parseInt(btn.getAttribute('data-pick-assign'), 10);
          if (pickSlotIndex === index && pickAssignIndex === ai) {
            pickSlotIndex = null;
            pickAssignIndex = null;
          } else {
            pickSlotIndex = index;
            pickAssignIndex = ai;
          }
          render();
        });
      });
      sheet.querySelectorAll('[data-object-id]').forEach(function (btn) {
        btn.addEventListener('click', function () {
          if (btn.disabled) return;
          const index = parseInt(btn.getAttribute('data-seat'), 10);
          const slot = slots[index];
          if (!slot) return;
          const id = Number(btn.getAttribute('data-object-id'));
          const ai = btn.hasAttribute('data-assign')
            ? parseInt(btn.getAttribute('data-assign'), 10)
            : (pickAssignIndex != null ? pickAssignIndex : 0);
          const next = guestAssignmentsFit(slot.assignments, slot.units || 1);
          if (id <= 0) {
            if (ai >= 0 && ai < next.length) next[ai] = null;
          } else if (next[ai] && Number(next[ai].site_object_id) === id) {
            next[ai] = null;
          } else {
            const obj = objects.find(function (o) { return Number(o.id) === id; });
            next[ai] = {
              site_object_id: id,
              objectName: obj ? (obj.name || obj.code || '') : '',
            };
          }
          slot.assignments = next;
          pickSlotIndex = null;
          pickAssignIndex = null;
          render();
        });
      });
    }

    function destroy() {
      alive = false;
      for (const slot of slots) {
        if (slot.availTimer) clearTimeout(slot.availTimer);
      }
      scrim.remove();
    }

    scrim.addEventListener('click', function (e) {
      if (e.target === scrim) destroy();
    });
    sheet.addEventListener('click', function (e) { e.stopPropagation(); });
    render();
    for (const slot of slots) scheduleAvail(slot);
  }

  window.c35GuestPost = window.c35GuestPost || {
    init() {
      document.querySelectorAll('.guest-post-carousel').forEach(function (root) {
        if (root.getAttribute('data-carousel-bound') === '1') return;
        root.setAttribute('data-carousel-bound', '1');
        const slides = root.querySelectorAll('.guest-post-carousel-slide');
        const dots = root.querySelectorAll('.guest-post-carousel-dot');
        if (slides.length < 2) return;
        let idx = 0;
        function show(i) {
          idx = i;
          slides.forEach(function (el, n) {
            el.style.display = n === idx ? 'block' : 'none';
          });
          dots.forEach(function (el, n) {
            el.classList.toggle('is-active', n === idx);
          });
        }
        dots.forEach(function (dot, n) {
          dot.addEventListener('click', function (e) {
            e.preventDefault();
            show(n);
          });
        });
        show(0);
      });
    },
  };

  window.c35GuestAssistant = window.c35GuestAssistant || (function () {
    const VISITOR_KEY = 'c35.guest.visitor.v1';

    function guestBoot() {
      return window.__SITE_GUEST__ || {};
    }

    function readAssistantConfig() {
      const g = guestBoot();
      const raw = g.ai_assistant || (g.meta && g.meta.ai_assistant) || null;
      if (!raw || typeof raw !== 'object') {
        return {
          configured: false,
          chatEnabled: true,
          callEnabled: false,
          chatIntro: '',
          chatPlaceholder: 'Ask Alien AI...',
          callIntro: '',
        };
      }
      const map = raw;
      const configured = map.configured === true || Object.keys(map).length > 0;
      let chatEnabled = true;
      if (map.chat_enabled === false) chatEnabled = false;
      else if (map.chat_enabled === true) chatEnabled = true;
      else if (map.floating_bubble === false) chatEnabled = false;
      const callEnabled = map.call_enabled === true;
      const placeholder = String(map.chat_placeholder || '').trim();
      return {
        configured: configured,
        chatEnabled: configured ? chatEnabled : true,
        callEnabled: configured ? callEnabled : false,
        chatIntro: String(map.chat_intro || ''),
        chatPlaceholder: placeholder || 'Ask Alien AI...',
        callIntro: String(map.call_intro || ''),
      };
    }

    function assistantApiBase() {
      const g = guestBoot();
      const base = (g.api_base || '').trim();
      if (base) return base.replace(/\/$/, '');
      return 'https://api.alienai.id';
    }

    function siteIid() {
      const g = guestBoot();
      return g.site_iid || g.site_id || 0;
    }

    function visitorId() {
      const sid = siteIid();
      const key = VISITOR_KEY + '.' + sid;
      try {
        const existing = localStorage.getItem(key);
        if (existing) return existing;
        const id = 'v_' + Math.random().toString(36).slice(2) + Date.now().toString(36);
        localStorage.setItem(key, id);
        return id;
      } catch (e) {
        return 'v_anon';
      }
    }

    function assistantBootMode() {
      const g = window.__SITE_GUEST__ || {};
      const fromBoot = String(g.mode || g.boot_mode || '').trim().toLowerCase();
      if (fromBoot === 'draft') return 'draft';
      try {
        const q = new URLSearchParams(window.location.search);
        const d = String(q.get('draft') || '').trim().toLowerCase();
        if (d === '1' || d === 'true' || d === 'yes') return 'draft';
      } catch (e) { /* ignore */ }
      return 'published';
    }

    function cartSessionPayload() {
      if (!window.c35GuestCart || !window.c35GuestCart.checkoutLines) return null;
      try {
        const lines = window.c35GuestCart.checkoutLines();
        if (!lines || !lines.length) return null;
        return { lines: lines };
      } catch (e) {
        return null;
      }
    }

    let root = null;
    let chatFab = null;
    let callFab = null;
    let chatDockFab = null;
    let chatPanel = null;
    let callOverlay = null;
    let messages = [];
    let chatOpen = false;
    let callActive = false;
    let callTimerId = null;
    let callStartedAt = 0;
    let streaming = false;

    function ensureRoot() {
      if (root) return root;
      root = document.getElementById('c35-guest-assistant-root');
      if (!root) {
        root = document.createElement('div');
        root.id = 'c35-guest-assistant-root';
        root.setAttribute('data-guest-assistant', '');
        document.body.appendChild(root);
      }
      root.removeAttribute('hidden');
      return root;
    }

    function fabHtml(kind, label) {
      return '<button type="button" class="guest-assistant-fab guest-assistant-fab--' + kind + '" data-assistant-fab="' + kind + '" aria-label="' + escHtml(label) + '">' + (kind === 'call' ? '\uD83D\uDCDE' : '\uD83D\uDCAC') + '</button>';
    }

    function renderChrome() {
      const cfg = readAssistantConfig();
      const host = ensureRoot();
      host.innerHTML = '';
      chatFab = null;
      callFab = null;
      chatDockFab = null;
      if (!cfg.chatEnabled && !cfg.callEnabled) {
        host.setAttribute('hidden', '');
        return;
      }
      host.removeAttribute('hidden');
      if (cfg.chatEnabled) {
        host.insertAdjacentHTML('beforeend', fabHtml('chat', 'Alien AI chat'));
        chatFab = host.querySelector('[data-assistant-fab="chat"]');
        chatFab.addEventListener('click', function () { api.openChat(); });
      }
      if (cfg.callEnabled) {
        host.insertAdjacentHTML('beforeend', fabHtml('call', 'Alien AI call'));
        callFab = host.querySelector('[data-assistant-fab="call"]');
        callFab.addEventListener('click', function () { api.startCall(); });
      }
      syncCartLayout();
    }

    function cartRowVisible() {
      const row = document.getElementById('c35-guest-cart-row');
      if (!row) return false;
      return row.style.display !== 'none' && row.offsetParent !== null;
    }

    function pesanButton() {
      return document.querySelector('#c35-guest-cart-bar .guest-cart-btn, #c35-guest-cart-trailing .guest-cart-btn');
    }

    function syncCartLayout() {
      const cfg = readAssistantConfig();
      const row = document.getElementById('c35-guest-cart-row');
      const bar = document.getElementById('c35-guest-cart-bar');
      const trailing = document.getElementById('c35-guest-cart-trailing');
      const dock = chatDockFab;
      const useDock = cfg.chatEnabled && cartRowVisible();
      document.body.classList.toggle('guest-assistant-cart-dock', useDock);
      if (dock && dock.parentNode) dock.parentNode.removeChild(dock);
      chatDockFab = null;
      if (chatFab) chatFab.style.display = useDock ? 'none' : '';
      if (useDock && trailing && bar) {
        trailing.hidden = false;
        trailing.innerHTML = '';
        const dockBtn = document.createElement('button');
        dockBtn.type = 'button';
        dockBtn.className = 'guest-assistant-fab guest-assistant-fab--chat guest-assistant-fab--dock';
        dockBtn.setAttribute('aria-label', 'Alien AI chat');
        dockBtn.textContent = '\uD83D\uDCAC';
        dockBtn.addEventListener('click', function () { api.openChat(); });
        trailing.appendChild(dockBtn);
        chatDockFab = dockBtn;
        const pesan = pesanButton();
        if (pesan && pesan.parentNode === bar) {
          trailing.appendChild(pesan);
        }
        bar.classList.add('guest-cart--meta-only');
      } else if (trailing) {
        trailing.hidden = true;
        const pesan = pesanButton();
        if (pesan && pesan.parentNode === trailing && bar) {
          bar.appendChild(pesan);
        }
        if (bar) bar.classList.remove('guest-cart--meta-only');
      }
      if (row) row.classList.toggle('guest-cart-row--assistant', useDock);
    }

    function removeChatPanel() {
      if (chatPanel && chatPanel.parentNode) chatPanel.parentNode.removeChild(chatPanel);
      chatPanel = null;
      chatOpen = false;
      document.body.classList.remove('guest-assistant-chat-open');
    }

    function renderMessagesHtml() {
      return messages.map(function (m) {
        const role = m.role === 'user' ? 'user' : 'assistant';
        return '<div class="guest-assistant-msg guest-assistant-msg--' + role + '">' + escHtml(m.text) + '</div>';
      }).join('');
    }

    function renderChatPanel() {
      removeChatPanel();
      const cfg = readAssistantConfig();
      chatOpen = true;
      document.body.classList.add('guest-assistant-chat-open');
      chatPanel = document.createElement('div');
      chatPanel.className = 'guest-assistant-chat-root';
      chatPanel.setAttribute('data-guest-assistant', 'chat');
      const intro = cfg.chatIntro ? '<p class="guest-assistant-intro">' + escHtml(cfg.chatIntro) + '</p>' : '';
      chatPanel.innerHTML = '<div class="guest-assistant-chat-scrim"></div><div class="guest-assistant-chat-sheet" role="dialog" aria-label="Alien AI chat">'
        + '<div class="guest-assistant-chat-header"><span>Alien AI</span><button type="button" class="guest-icon-btn guest-assistant-chat-close" aria-label="Close">\u00D7</button></div>'
        + '<div class="guest-assistant-chat-body" id="c35-assistant-messages">' + intro + renderMessagesHtml() + '</div>'
        + '<div class="guest-assistant-chat-compose"><input type="text" id="c35-assistant-input" placeholder="' + escHtml(cfg.chatPlaceholder) + '" autocomplete="off"/>'
        + '<button type="button" class="guest-assistant-send" id="c35-assistant-send">Send</button></div></div>';
      document.body.appendChild(chatPanel);
      chatPanel.querySelector('.guest-assistant-chat-scrim').addEventListener('click', function () { api.closeChat(); });
      chatPanel.querySelector('.guest-assistant-chat-close').addEventListener('click', function () { api.closeChat(); });
      const input = chatPanel.querySelector('#c35-assistant-input');
      const send = chatPanel.querySelector('#c35-assistant-send');
      send.addEventListener('click', function () { api.sendChat(input.value); });
      input.addEventListener('keydown', function (e) {
        if (e.key === 'Enter') api.sendChat(input.value);
      });
      input.focus();
      scrollMessages();
    }

    function scrollMessages() {
      const el = document.getElementById('c35-assistant-messages');
      if (el) el.scrollTop = el.scrollHeight;
    }

    function appendMessage(role, text) {
      messages.push({ role: role, text: text });
      const el = document.getElementById('c35-assistant-messages');
      if (!el) return;
      const intro = el.querySelector('.guest-assistant-intro');
      const node = document.createElement('div');
      node.className = 'guest-assistant-msg guest-assistant-msg--' + role;
      node.textContent = text;
      el.appendChild(node);
      scrollMessages();
    }

    function updateAssistantBubble(text) {
      const el = document.getElementById('c35-assistant-messages');
      if (!el) return;
      let bubble = el.querySelector('.guest-assistant-msg--assistant-stream');
      if (!bubble) {
        bubble = document.createElement('div');
        bubble.className = 'guest-assistant-msg guest-assistant-msg--assistant guest-assistant-msg--assistant-stream';
        el.appendChild(bubble);
      }
      bubble.textContent = text;
      scrollMessages();
    }

    function finalizeAssistantStream() {
      const el = document.getElementById('c35-assistant-messages');
      if (!el) return;
      const bubble = el.querySelector('.guest-assistant-msg--assistant-stream');
      if (!bubble) return;
      const text = bubble.textContent || '';
      bubble.classList.remove('guest-assistant-msg--assistant-stream');
      if (text) messages.push({ role: 'assistant', text: text });
    }

    async function consumeChatStream(resp) {
      const ctype = (resp.headers.get('content-type') || '').toLowerCase();
      if (ctype.indexOf('text/event-stream') >= 0 && resp.body) {
        const reader = resp.body.getReader();
        const decoder = new TextDecoder();
        let buf = '';
        let acc = '';
        while (true) {
          const chunk = await reader.read();
          if (chunk.done) break;
          buf += decoder.decode(chunk.value, { stream: true });
          const parts = buf.split('\n');
          buf = parts.pop() || '';
          for (const line of parts) {
            const trimmed = line.trim();
            if (!trimmed.startsWith('data:')) continue;
            const payload = trimmed.slice(5).trim();
            if (payload === '[DONE]') continue;
            try {
              const data = JSON.parse(payload);
              const delta = data.text || data.delta || data.content || '';
              if (delta) {
                acc += delta;
                updateAssistantBubble(acc);
              }
            } catch (e) {
              if (payload) {
                acc += payload;
                updateAssistantBubble(acc);
              }
            }
          }
        }
        finalizeAssistantStream();
        return acc;
      }
      const text = await resp.text();
      try {
        const data = JSON.parse(text);
        const reply = data.text || data.reply || data.message || '';
        if (reply) appendMessage('assistant', reply);
        return reply;
      } catch (e) {
        if (text) appendMessage('assistant', text);
        return text;
      }
    }

    function formatCallElapsed(ms) {
      const s = Math.floor(ms / 1000);
      const m = Math.floor(s / 60);
      const r = s % 60;
      return (m < 10 ? '0' : '') + m + ':' + (r < 10 ? '0' : '') + r;
    }

    function removeCallOverlay() {
      if (callTimerId) {
        clearInterval(callTimerId);
        callTimerId = null;
      }
      if (callOverlay && callOverlay.parentNode) callOverlay.parentNode.removeChild(callOverlay);
      callOverlay = null;
      callActive = false;
      document.body.classList.remove('guest-assistant-call-open');
    }

    function renderCallOverlay() {
      removeCallOverlay();
      const cfg = readAssistantConfig();
      callActive = true;
      callStartedAt = Date.now();
      document.body.classList.add('guest-assistant-call-open');
      callOverlay = document.createElement('div');
      callOverlay.className = 'guest-assistant-call-root';
      callOverlay.setAttribute('data-guest-assistant', 'call');
      const intro = cfg.callIntro ? '<p class="guest-assistant-call-intro">' + escHtml(cfg.callIntro) + '</p>' : '';
      callOverlay.innerHTML = '<div class="guest-assistant-call-card"><div class="guest-assistant-call-icon" aria-hidden="true">\uD83D\uDD0A</div>'
        + '<div class="guest-assistant-call-title">Alien AI Call</div>' + intro
        + '<div class="guest-assistant-call-timer" id="c35-assistant-call-timer">00:00</div>'
        + '<p class="guest-assistant-call-hint">Speakerphone · live session placeholder</p>'
        + '<button type="button" class="guest-assistant-call-end" id="c35-assistant-call-end">End call</button></div>';
      document.body.appendChild(callOverlay);
      callOverlay.querySelector('#c35-assistant-call-end').addEventListener('click', function () { api.endCall(); });
      callTimerId = setInterval(function () {
        const el = document.getElementById('c35-assistant-call-timer');
        if (el) el.textContent = formatCallElapsed(Date.now() - callStartedAt);
      }, 1000);
    }

    const api = {
      init() {
        renderChrome();
      },
      syncCartLayout,
      openChat() {
        if (!readAssistantConfig().chatEnabled) return;
        renderChatPanel();
      },
      closeChat() {
        removeChatPanel();
      },
      async sendChat(text) {
        const msg = String(text || '').trim();
        if (!msg || streaming) return;
        const input = document.getElementById('c35-assistant-input');
        if (input) input.value = '';
        appendMessage('user', msg);
        streaming = true;
        try {
          const payload = {
            site_iid: siteIid(),
            visitor_id: visitorId(),
            message: msg,
            cart: cartSessionPayload(),
          };
          if (assistantBootMode() === 'draft') payload.boot_mode = 'draft';
          const resp = await fetch(assistantApiBase() + '/v1/site/guest-assistant/chat', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', Accept: 'text/event-stream, application/json' },
            body: JSON.stringify(payload),
          });
          if (!resp.ok) {
            const errText = await resp.text();
            throw new Error(errText || 'Chat failed');
          }
          await consumeChatStream(resp);
        } catch (err) {
          appendMessage('assistant', (err && err.message) ? err.message : String(err));
        } finally {
          streaming = false;
        }
      },
      startCall() {
        if (!readAssistantConfig().callEnabled) return;
        renderCallOverlay();
      },
      endCall() {
        removeCallOverlay();
      },
      readAssistantConfig,
      visitorId,
    };
    return api;
  })();

  window.c35GuestAnalytics = window.c35GuestAnalytics || (function () {
    const SESSION_KEY_PREFIX = 'c35.guest.session.v1.';
    const VISITOR_KEY_PREFIX = 'c35.guest.visitor.v1.';
    let started = false;
    let totalActiveTime = 0;
    let activeStart = Date.now();
    let isPageVisible = document.visibilityState === 'visible';

    function guestBoot() {
      return window.__SITE_GUEST__ || {};
    }

    function analyticsEnabled() {
      const caps = guestBoot().capabilities;
      if (!caps || typeof caps !== 'object') return true;
      return caps.analytics !== false;
    }

    function alienId() {
      const g = guestBoot();
      return String(g.alien_id || g.alienId || '').trim();
    }

    function siteIid() {
      const g = guestBoot();
      return g.site_iid || g.site_id || 0;
    }

    function visitorId() {
      if (window.c35GuestAssistant && typeof window.c35GuestAssistant.visitorId === 'function') {
        return window.c35GuestAssistant.visitorId();
      }
      const sid = siteIid();
      const key = VISITOR_KEY_PREFIX + sid;
      try {
        const existing = localStorage.getItem(key);
        if (existing) return existing;
        const id = 'v_' + Math.random().toString(36).slice(2) + Date.now().toString(36);
        localStorage.setItem(key, id);
        return id;
      } catch (e) {
        return 'v_anon';
      }
    }

    function sessionId() {
      const sid = siteIid();
      const key = SESSION_KEY_PREFIX + sid;
      try {
        let existing = sessionStorage.getItem(key);
        if (!existing) {
          existing = 's_' + Math.random().toString(36).slice(2) + Date.now().toString(36);
          sessionStorage.setItem(key, existing);
        }
        return existing;
      } catch (e) {
        return 's_anon';
      }
    }

    function updateActiveTime() {
      if (isPageVisible) {
        totalActiveTime += Date.now() - activeStart;
      }
    }

    function sendPing() {
      const aid = alienId();
      if (!aid || !analyticsEnabled()) return;
      updateActiveTime();
      activeStart = Date.now();
      const payload = JSON.stringify({
        alien_id: aid,
        session_id: sessionId(),
        path: window.location.pathname || '/',
        visitor_id: visitorId(),
        referrer: document.referrer || null,
        active_duration_ms: Math.round(totalActiveTime),
        user_agent: navigator.userAgent || null,
      });
      const url = apiBase() + '/v1/site/guest-analytics/ping';
      if (navigator.sendBeacon) {
        navigator.sendBeacon(url, new Blob([payload], { type: 'application/json' }));
      } else {
        fetch(url, {
          method: 'POST',
          body: payload,
          keepalive: true,
          headers: { 'Content-Type': 'application/json' },
        }).catch(function () { /* ignore */ });
      }
    }

    function trackLinkClick(linkId) {
      const aid = alienId();
      if (!aid || !analyticsEnabled() || !linkId) return;
      const payload = JSON.stringify({
        alien_id: aid,
        link_id: linkId,
        visitor_id: visitorId(),
      });
      const url = apiBase() + '/v1/site/guest-analytics/link-click';
      fetch(url, {
        method: 'POST',
        body: payload,
        keepalive: true,
        headers: { 'Content-Type': 'application/json' },
      }).catch(function () { /* ignore */ });
    }

    function bindLinkClicks() {
      if (window.__c35GuestAnalyticsLinksBound) return;
      window.__c35GuestAnalyticsLinksBound = true;
      document.addEventListener('click', function (e) {
        const el = e.target && e.target.closest ? e.target.closest('[data-link-id]') : null;
        if (!el) return;
        const linkId = parseInt(el.getAttribute('data-link-id') || '0', 10);
        if (linkId > 0) trackLinkClick(linkId);
      });
    }

    return {
      start() {
        if (started) return;
        if (!analyticsEnabled() || !alienId()) return;
        started = true;
        totalActiveTime = 0;
        activeStart = Date.now();
        isPageVisible = document.visibilityState === 'visible';
        bindLinkClicks();
        document.addEventListener('visibilitychange', function () {
          if (document.visibilityState === 'hidden') {
            isPageVisible = false;
            sendPing();
          } else {
            activeStart = Date.now();
            isPageVisible = true;
          }
        });
        window.addEventListener('pagehide', function () {
          sendPing();
        });
      },
    };
  })();

  window.c35GuestOrders = window.c35GuestOrders || {
    refreshChip() {
      const g = window.__SITE_GUEST__ || {};
      const siteIid = g.site_iid || 0;
      const chip = document.getElementById('c35-guest-orders-chip');
      if (!chip || !siteIid) return;
      const n = loadOrders(siteIid).length;
      chip.style.display = n > 0 ? 'block' : 'none';
      chip.textContent = n > 0 ? 'Pesanan saya (' + n + ')' : 'Pesanan saya';
    },
    open() {
      const g = window.__SITE_GUEST__ || {};
      const siteIid = g.site_iid || 0;
      const list = loadOrders(siteIid);
      if (!list.length) {
        alert('Belum ada pesanan');
        return;
      }
      const lines = list
        .map((o) => '#' + o.tx_id + (o.total ? ' · ' + formatOrderTotal(o.total) : ''))
        .join('\n');
      alert('Pesanan tersimpan:\n' + lines);
    },
  };

  function guestSiteInit() {
    window.c35GuestCatalogUi.init();
    window.c35GuestReserve.init();
    window.c35GuestPost.init();
    window.c35GuestOrders.refreshChip();
    if (window.c35GuestAssistant) window.c35GuestAssistant.init();
    if (window.c35GuestAnalytics) window.c35GuestAnalytics.start();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', guestSiteInit);
  } else {
    guestSiteInit();
  }
})();
