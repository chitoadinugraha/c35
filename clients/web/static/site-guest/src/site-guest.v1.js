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

  function guestProductPriceLabel(price) {
    const p = Math.round(price || 0);
    if (p === GUEST_PRODUCT_PRICE_CONTACT) return 'Contact Us';
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

  function productPurchaseAction(item) {
    const pid = item.product_id;
    return '<button type="button" class="guest-product-info-btn" data-product-info="' + pid + '" aria-label="Detail">&#9432;</button>';
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
      const priceLabel = guestProductPriceLabel(price);
      const priceHtml = priceLabel ? '<span class="price">' + escHtml(priceLabel) + '</span>' : '';
      const action = productPurchaseAction(item);
      return '<article class="product-card guest-product-tile" data-pid="' + pid + '"' + reserveAttr + '>' + img
        + '<div class="product-info"><h3>' + name + '</h3><p>' + desc + '</p>'
        + '<div class="product-bottom">' + priceHtml
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
      const priceHtml = priceLabel ? '<span class="price">' + escHtml(priceLabel) + '</span>' : '';
      const action = productPurchaseAction(item);
      return '<article class="product-list-row guest-product-tile" data-pid="' + pid + '"' + reserveAttr + '>'
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
      btn.textContent = 'Memuat…';
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
        if (!paymentMethods.length) return 'Pesan \u00b7 ' + formatRpPlain(grandTotal());
        return 'Lanjut';
      }
      if (checkoutStep === 'payment') return 'Pilih metode';
      const m = selectedPayment();
      if (m && m.type === 'whatsapp') return 'Kirim via WhatsApp';
      return 'Konfirmasi \u00b7 ' + formatRpPlain(grandTotal());
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
      const bar = document.getElementById('c35-guest-cart-bar');
      const countEl = document.getElementById('c35-cart-count');
      const totalEl = document.getElementById('c35-cart-total');
      const n = count();
      if (bar) bar.style.display = n > 0 && !sheet ? 'flex' : 'none';
      if (countEl) countEl.textContent = countLabel();
      if (totalEl) totalEl.textContent = formatRpPlain(grandTotal());
      refreshTileBadges();
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
      const picUrl = picUrlDisplay(p.pic || '');
      const pic = picUrl ? '<img class="guest-order-pic" src="' + escHtml(picUrl) + '" alt=""/>' : '<div class="guest-order-pic guest-order-pic-empty">\uD83D\uDECD\uFE0F</div>';
      const desc = p.description ? '<p class="guest-product-desc">' + escHtml(p.description) + '</p>' : '';
      const stock = orderStockMax != null ? '<p class="guest-stock">Stok: ' + orderStockMax + '</p>' : '';
      const err = orderError ? '<p class="guest-error">' + escHtml(orderError) + '</p>' : '';
      const keys = numpadKeys.map(function (k) {
        return '<button type="button" class="guest-numpad-key" data-numpad="' + escHtml(k) + '">' + (k === 'back' ? '⌫' : k) + '</button>';
      }).join('');
      const primary = orderQty > 0 ? ('Pesan ' + orderQty + ' item · ' + orderPriceLabel()) : 'Batalkan';
      return '<div class="guest-sheet-handle"></div><div class="guest-order-card"><div class="guest-order-pic-wrap">' + pic
        + (orderQty > 0 ? '<span class="guest-product-qty">' + orderQty + '</span>' : '') + '</div><div class="guest-order-info"><div class="guest-order-top">'
        + '<div class="guest-order-name">' + escHtml(p.name || 'Produk') + '</div><div class="guest-order-price">' + formatIdr(p.price || 0) + '</div></div>'
        + desc + '<label class="guest-note"><span>📝</span><input type="text" id="c35-order-note" value="' + escHtml(orderNote) + '" placeholder="Catatan (opsional)…"/></label>'
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
            const reservations = line.slots.map(function (s) {
              const units = s.units || 1;
              const durationQty = slotDurationQty(s) || 1;
              return {
                product_id: line.productId,
                qty: units,
                duration_qty: durationQty,
                start_ts_ms: s.start_ts_ms,
                end_ts_ms: s.end_ts_ms,
                site_object_id: s.site_object_id || 0,
                state: 'pending',
              };
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
              const text = encodeURIComponent('Halo, pesanan #' + txId + ' \u2014 ' + formatRpPlain(savedTotal));
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

  window.c35GuestCatalogUi = {
    init() {
      if (window.__c35CatalogUiBound) return;
      window.__c35CatalogUiBound = true;
      if (!document.getElementById('c35-guest-pic-lightbox-style')) {
        const st = document.createElement('style');
        st.id = 'c35-guest-pic-lightbox-style';
        st.textContent = '.guest-pic-lightbox{position:fixed;inset:0;z-index:9999;background:rgba(0,0,0,.85);display:flex;align-items:center;justify-content:center;padding:24px}'
          + '.guest-pic-lightbox img{max-width:100%;max-height:100%;object-fit:contain;border-radius:8px}'
          + '.guest-pic-lightbox-close{position:absolute;top:12px;right:16px;border:0;background:transparent;color:#fff;font-size:32px;cursor:pointer}';
        document.head.appendChild(st);
      }
      document.addEventListener('click', function (e) {
        const img = e.target && e.target.closest ? e.target.closest('img.guest-pic-thumb') : null;
        if (img) {
          const url = img.getAttribute('data-pic-display') || img.getAttribute('src') || '';
          if (url) {
            e.preventDefault();
            openPicLightbox(url);
          }
          return;
        }
        const infoBtn = e.target && e.target.closest ? e.target.closest('.guest-product-info-btn') : null;
        if (infoBtn) {
          e.preventDefault();
          e.stopPropagation();
          const pid = infoBtn.getAttribute('data-product-info');
          if (pid) window.location.href = 'products/' + pid;
          return;
        }
        const tile = e.target && e.target.closest ? e.target.closest('.guest-product-tile') : null;
        if (!tile || !window.c35GuestCart) return;
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
        const nameJs = name.replace(/\\/g, '\\\\').replace(/'/g, "\\'");
        const picJs = String(pic || '').replace(/\\/g, '\\\\').replace(/'/g, "\\'");
        window.c35GuestCart.add(pid, nameJs, price, picJs);
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
          const tiles = objects.map(function (o) {
            const id = Number(o.id);
            const dim = slot.freeIds && !slot.freeIds.has(id);
            const on = Number(slot.site_object_id) === id;
            const cls = 'guest-seat' + (on ? ' guest-seat-on' : '') + (dim ? ' guest-seat-dim' : '');
            const img = o.pic
              ? '<img src="' + escHtml(o.pic) + '" alt="">'
              : '<span class="guest-seat-fallback">' + escHtml(String(o.name || o.code || '?').slice(0, 1)) + '</span>';
            return '<button type="button" class="' + cls + '" data-seat="' + index + '" data-object-id="' + id + '"'
              + (dim ? ' disabled' : '') + '>'
              + img + '<span>' + escHtml(o.name || o.code || '') + '</span></button>';
          }).join('');
          seats = '<div class="guest-seat-grid">' + tiles + '</div>';
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
          return {
            units: s.units,
            durationQty: s.durationCount,
            start_ts_ms: s.start.getTime(),
            end_ts_ms: s.end.getTime(),
            site_object_id: s.site_object_id || 0,
            objectName: s.objectName || '',
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
      sheet.querySelectorAll('[data-object-id]').forEach(function (btn) {
        btn.addEventListener('click', function () {
          if (btn.disabled) return;
          const index = parseInt(btn.getAttribute('data-seat'), 10);
          const slot = slots[index];
          if (!slot) return;
          const id = Number(btn.getAttribute('data-object-id'));
          if (Number(slot.site_object_id) === id) {
            slot.site_object_id = 0;
            slot.objectName = '';
          } else {
            const obj = objects.find(function (o) { return Number(o.id) === id; });
            slot.site_object_id = id;
            slot.objectName = obj ? (obj.name || obj.code || '') : '';
          }
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

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function () {
      window.c35GuestCatalogUi.init();
      window.c35GuestReserve.init();
      window.c35GuestPost.init();
      window.c35GuestOrders.refreshChip();
    });
  } else {
    window.c35GuestCatalogUi.init();
    window.c35GuestReserve.init();
    window.c35GuestPost.init();
    window.c35GuestOrders.refreshChip();
  }
})();
