import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:alienai_c35/c/site/guest_assistant_api.dart';
import 'package:alienai_c35/c/site/guest_order_api.dart';
import 'package:alienai_c35/c/ui/money_format.dart';
import 'package:alienai_c35/guest_site/guest_site_commerce_boot.dart';
import 'package:alienai_c35/guest_site/guest_site_member.dart';
import 'package:alienai_c35/guest_site/guest_site_pic.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum GuestSiteCartSheet { none, order, checkout }

enum GuestCheckoutStep { confirm, payment, payDetail }

class GuestOrderDraft {
  GuestOrderDraft({
    required this.productId,
    required this.name,
    required this.price,
    required this.pic,
    required this.qty,
    this.desc = '',
    this.note = '',
    this.stockMax,
  });

  final int productId;
  final String name;
  final int price;
  final String pic;
  final String desc;
  int qty;
  String note;
  final int? stockMax;
}

IconData guestPaymentMethodIcon(String type) => switch (type.trim().toLowerCase()) {
      'cash' => Icons.payments_outlined,
      'transfer' => Icons.account_balance_outlined,
      'qris' => Icons.qr_code_scanner,
      'whatsapp' => Icons.chat_outlined,
      _ => Icons.payment_outlined,
    };

class GuestReservationAssignment {
  const GuestReservationAssignment({this.siteObjectId = 0, this.objectName = ''});

  final int siteObjectId;
  final String objectName;

  bool get isAuto => siteObjectId <= 0;

  Map<String, dynamic> toStoredJson() => {
        'site_object_id': siteObjectId,
        'object_name': objectName,
      };

  static GuestReservationAssignment? fromStoredJson(Object? raw) {
    if (raw == null) return null;
    if (raw is! Map) return null;
    return GuestReservationAssignment(
      siteObjectId: (raw['site_object_id'] as num?)?.toInt() ?? 0,
      objectName: raw['object_name']?.toString() ?? '',
    );
  }
}

List<GuestReservationAssignment?> guestReservationAssignmentsFit(List<GuestReservationAssignment?> src, int units) {
  if (units <= 0) return const [];
  if (src.length == units) return List<GuestReservationAssignment?>.of(src);
  if (src.length > units) return src.take(units).toList();
  return [...src, for (var i = src.length; i < units; i++) null];
}

class GuestReservationSlot {
  const GuestReservationSlot({
    required this.start,
    required this.end,
    required this.units,
    required this.durationQty,
    this.siteObjectId = 0,
    this.objectName = '',
    this.assignments = const [],
  });

  final DateTime start;
  final DateTime end;
  final int units;
  final int durationQty;
  final int siteObjectId;
  final String objectName;
  /// Per-unit picks when guest chooses units; length equals [units] when set.
  final List<GuestReservationAssignment?> assignments;

  bool get expandsPerUnitReservations => units > 1 && assignments.isNotEmpty;

  Map<String, dynamic> toStoredJson() {
    final fit = guestReservationAssignmentsFit(assignments, units);
    return {
      'start_ts_ms': start.millisecondsSinceEpoch,
      'end_ts_ms': end.millisecondsSinceEpoch,
      'units': units,
      'duration_qty': durationQty,
      'site_object_id': siteObjectId,
      'object_name': objectName,
      if (fit.isNotEmpty)
        'assignments': [
          for (final a in fit) a?.toStoredJson(),
        ],
    };
  }

  List<Map<String, dynamic>> reservationMaps(int productId) {
    final durationQty = this.durationQty < 1 ? 1 : this.durationQty;
    final startMs = start.millisecondsSinceEpoch;
    final endMs = end.millisecondsSinceEpoch;
    if (expandsPerUnitReservations) {
      final fit = guestReservationAssignmentsFit(assignments, units);
      return [
        for (var i = 0; i < units; i++)
          {
            'product_id': productId,
            'qty': 1,
            'duration_qty': durationQty,
            'start_ts_ms': startMs,
            'end_ts_ms': endMs,
            'site_object_id': fit[i]?.siteObjectId ?? 0,
            'state': 'pending',
          },
      ];
    }
    final fit = guestReservationAssignmentsFit(assignments, units);
    final objId = fit.isNotEmpty && fit.first != null && !fit.first!.isAuto
        ? fit.first!.siteObjectId
        : siteObjectId;
    return [
      {
        'product_id': productId,
        'qty': units,
        'duration_qty': durationQty,
        'start_ts_ms': startMs,
        'end_ts_ms': endMs,
        'site_object_id': objId,
        'state': 'pending',
      },
    ];
  }

  static GuestReservationSlot? fromStoredJson(Object? raw) {
    if (raw is! Map) return null;
    final startMs = (raw['start_ts_ms'] as num?)?.toInt();
    final endMs = (raw['end_ts_ms'] as num?)?.toInt();
    if (startMs == null || endMs == null) return null;
    final units = (raw['units'] as num?)?.toInt() ?? 1;
    final siteObjectId = (raw['site_object_id'] as num?)?.toInt() ?? 0;
    final objectName = raw['object_name']?.toString() ?? '';
    final assignments = <GuestReservationAssignment?>[];
    final rawAssign = raw['assignments'];
    if (rawAssign is List) {
      for (final row in rawAssign) {
        assignments.add(GuestReservationAssignment.fromStoredJson(row));
      }
    } else if (siteObjectId > 0) {
      assignments.add(GuestReservationAssignment(siteObjectId: siteObjectId, objectName: objectName));
    }
    return GuestReservationSlot(
      start: DateTime.fromMillisecondsSinceEpoch(startMs),
      end: DateTime.fromMillisecondsSinceEpoch(endMs),
      units: units,
      durationQty: (raw['duration_qty'] as num?)?.toInt() ?? 1,
      siteObjectId: siteObjectId,
      objectName: objectName,
      assignments: guestReservationAssignmentsFit(assignments, units),
    );
  }
}

int guestReservationLineQty(List<GuestReservationSlot> slots) {
  var sum = 0;
  for (final slot in slots) {
    final duration = slot.durationQty < 1 ? 1 : slot.durationQty;
    if (slot.units < 1) continue;
    sum += slot.units * duration;
  }
  return sum;
}

class GuestSiteCartLine {
  GuestSiteCartLine({
    required this.productId,
    required this.name,
    required this.price,
    int qty = 1,
    this.note = '',
    List<GuestReservationSlot> slots = const [],
  })  : slots = List<GuestReservationSlot>.unmodifiable(slots),
        qty = slots.isEmpty ? qty : guestReservationLineQty(slots);

  final int productId;
  final String name;
  final int price;
  final int qty;
  final String note;
  final List<GuestReservationSlot> slots;

  int get lineTotal => price * qty;

  List<Map<String, dynamic>> reservationJson() => [
        for (final slot in slots) ...slot.reservationMaps(productId),
      ];

  Map<String, dynamic> orderItemJson() => {
        'product_id': productId,
        'qty': qty,
        if (note.trim().isNotEmpty) 'note': note.trim(),
        if (slots.isNotEmpty) 'reservations': reservationJson(),
      };

  Object toStoredJson() {
    if (slots.isNotEmpty) {
      return {
        'name': name,
        'price': price,
        'qty': qty,
        'slots': [for (final slot in slots) slot.toStoredJson()],
      };
    }
    if (note.trim().isEmpty) return qty;
    return {'qty': qty, 'note': note.trim()};
  }
}

Map<int, GuestSiteCartLine> guestCartLinesFromJsonMap(Map<dynamic, dynamic> map) {
  final lines = <int, GuestSiteCartLine>{};
  for (final entry in map.entries) {
    final pid = int.tryParse(entry.key.toString());
    if (pid == null) continue;
    final value = entry.value;
    if (value is num) {
      final qty = value.toInt();
      if (qty <= 0) continue;
      lines[pid] = GuestSiteCartLine(productId: pid, name: 'Product $pid', price: 0, qty: qty);
      continue;
    }
    if (value is Map && value['qty'] is num && value['slots'] == null) {
      final qty = (value['qty'] as num).toInt();
      if (qty <= 0) continue;
      final note = value['note']?.toString() ?? '';
      final name = value['name']?.toString() ?? 'Product $pid';
      final price = (value['price'] as num?)?.toInt() ?? 0;
      lines[pid] = GuestSiteCartLine(productId: pid, name: name, price: price, qty: qty, note: note);
      continue;
    }
    if (value is! Map) continue;
    final slots = <GuestReservationSlot>[];
    final rawSlots = value['slots'];
    if (rawSlots is List) {
      for (final raw in rawSlots) {
        final slot = GuestReservationSlot.fromStoredJson(raw);
        if (slot != null) slots.add(slot);
      }
    }
    final name = value['name']?.toString() ?? 'Product $pid';
    final price = (value['price'] as num?)?.toInt() ?? 0;
    final lineNote = value['note']?.toString() ?? '';
    if (slots.isEmpty) {
      final qty = (value['qty'] as num?)?.toInt() ?? 0;
      if (qty <= 0) continue;
      lines[pid] = GuestSiteCartLine(productId: pid, name: name, price: price, qty: qty, note: lineNote);
      continue;
    }
    lines[pid] = GuestSiteCartLine(productId: pid, name: name, price: price, slots: slots);
  }
  return lines;
}

class GuestSiteCartController extends ChangeNotifier {
  GuestSiteCartController({required this.siteIid});

  final int siteIid;
  final Map<int, GuestSiteCartLine> _lines = {};
  final Map<int, Map<String, dynamic>> _catalog = {};
  List<Map<String, dynamic>> _taxes = const [];
  List<Map<String, dynamic>> _paymentMethods = const [];
  var _paymentId = 'cash';
  var _sheet = GuestSiteCartSheet.none;
  var _checkoutStep = GuestCheckoutStep.confirm;
  GuestOrderDraft? _orderDraft;
  var _orderQtyReplaceNext = true;
  var _busy = false;
  String checkoutCustomerName = '';
  String checkoutCustomerPhone = '';
  String checkoutOrderNote = '';
  String? checkoutError;

  bool get sheetOpen => _sheet != GuestSiteCartSheet.none;
  GuestSiteCartSheet get sheet => _sheet;
  GuestCheckoutStep get checkoutStep => _checkoutStep;
  GuestOrderDraft? get orderDraft => _orderDraft;
  bool get busy => _busy;
  int get count => _lines.values.fold(0, (a, l) => a + l.qty);
  int get subtotal => _lines.values.fold(0, (a, l) => a + l.lineTotal);
  int get taxTotal => guestCommerceTaxTotal(subtotal, _taxes);
  int get total => subtotal + taxTotal;
  List<Map<String, dynamic>> get paymentMethods => _paymentMethods;
  String get paymentId => _paymentId;
  List<GuestSiteCartLine> get lines => _lines.values.toList(growable: false);

  void applyCommerceBoot(GuestCommerceBoot boot) {
    _catalog
      ..clear()
      ..addAll(boot.productCatalog());
    _taxes = boot.taxes;
    _paymentMethods = boot.paymentMethods;
    if (_paymentMethods.isEmpty) {
      _paymentId = 'cash';
    } else if (!_paymentMethods.any((m) => m['id']?.toString() == _paymentId)) {
      _paymentId = _paymentMethods.first['id']?.toString() ?? 'cash';
    }
    _enrichLinesFromCatalog();
  }

  void _enrichLinesFromCatalog() {
    if (_catalog.isEmpty) return;
    for (final entry in _lines.entries.toList()) {
      final row = _catalog[entry.key];
      if (row == null) continue;
      final line = entry.value;
      final catalogName = row['name']?.toString().trim() ?? '';
      final catalogPrice = (row['price'] as num?)?.toInt() ?? 0;
      final staleName = catalogName.isNotEmpty &&
          (line.name.isEmpty || line.name == 'Product ${line.productId}' || line.name.startsWith('Product '));
      if (!staleName && (catalogPrice <= 0 || line.price > 0)) continue;
      _lines[entry.key] = GuestSiteCartLine(
        productId: line.productId,
        name: catalogName.isNotEmpty ? catalogName : line.name,
        price: catalogPrice > 0 ? catalogPrice : line.price,
        qty: line.qty,
        note: line.note,
        slots: line.slots,
      );
    }
  }

  void setPaymentId(String id) {
    if (id == _paymentId) return;
    _paymentId = id;
    notifyListeners();
  }

  Map<String, dynamic>? productRow(int productId) => _catalog[productId];

  int qtyForProduct(int productId) => _lines[productId]?.qty ?? 0;

  GuestSiteCartLine? lineForProduct(int productId) => _lines[productId];

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString('c35.guest.cart.v1.$siteIid');
    if (raw == null) return;
    try {
      final map = jsonDecode(raw);
      if (map is! Map) return;
      _lines
        ..clear()
        ..addAll(guestCartLinesFromJsonMap(map));
      _enrichLinesFromCatalog();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _persist() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
      'c35.guest.cart.v1.$siteIid',
      jsonEncode({for (final l in _lines.values) '${l.productId}': l.toStoredJson()}),
    );
  }

  void addProduct({required int productId, required String name, required int price, int delta = 1}) {
    final prev = _lines[productId];
    if (prev != null && prev.slots.isNotEmpty) return;
    final nextQty = (prev?.qty ?? 0) + delta;
    if (nextQty <= 0) {
      _lines.remove(productId);
    } else {
      _lines[productId] = GuestSiteCartLine(
        productId: productId,
        name: name,
        price: price,
        qty: nextQty,
        note: prev?.note ?? '',
      );
    }
    unawaited(_persist());
    notifyListeners();
  }

  void openOrder({
    required int productId,
    required String name,
    required int price,
    String pic = '',
    String desc = '',
    int? stockMax,
  }) {
    final prev = _lines[productId];
    if (prev != null && prev.slots.isNotEmpty) return;
    final startQty = prev?.qty ?? 0;
    _orderDraft = GuestOrderDraft(
      productId: productId,
      name: name,
      price: price,
      pic: pic,
      qty: startQty,
      desc: desc,
      note: prev?.note ?? '',
      stockMax: stockMax,
    );
    _orderQtyReplaceNext = startQty == 0;
    _sheet = GuestSiteCartSheet.order;
    notifyListeners();
  }

  void orderSetNote(String note) {
    final draft = _orderDraft;
    if (draft == null) return;
    draft.note = note;
    notifyListeners();
  }

  void orderNumpad(String key) {
    final draft = _orderDraft;
    if (draft == null) return;
    var qty = draft.qty;
    if (key == 'C') {
      qty = 0;
      _orderQtyReplaceNext = true;
    } else if (key == '⌫') {
      final s = qty.toString();
      qty = s.length > 1 ? int.parse(s.substring(0, s.length - 1)) : 0;
      _orderQtyReplaceNext = qty == 0;
    } else {
      if (_orderQtyReplaceNext) {
        qty = int.tryParse(key) ?? qty;
        _orderQtyReplaceNext = false;
      } else {
        final s = qty == 0 ? key : '$qty$key';
        qty = int.tryParse(s) ?? qty;
      }
    }
    final max = draft.stockMax;
    if (max != null && qty > max) qty = max;
    draft.qty = qty.clamp(0, 9999);
    notifyListeners();
  }

  void confirmOrder() {
    final draft = _orderDraft;
    if (draft == null) return;
    if (draft.qty <= 0) {
      _lines.remove(draft.productId);
    } else {
      _lines[draft.productId] = GuestSiteCartLine(
        productId: draft.productId,
        name: draft.name,
        price: draft.price,
        qty: draft.qty,
        note: draft.note.trim(),
      );
    }
    _orderDraft = null;
    _sheet = GuestSiteCartSheet.none;
    unawaited(_persist());
    notifyListeners();
  }

  void cancelOrder() {
    _orderDraft = null;
    if (_sheet == GuestSiteCartSheet.order) _sheet = GuestSiteCartSheet.none;
    notifyListeners();
  }

  void pesan() {
    if (count == 0) return;
    _enrichLinesFromCatalog();
    checkoutError = null;
    _checkoutStep = GuestCheckoutStep.confirm;
    _sheet = GuestSiteCartSheet.checkout;
    notifyListeners();
  }

  void checkoutBack() {
    checkoutError = null;
    if (_checkoutStep == GuestCheckoutStep.payDetail) {
      _checkoutStep = GuestCheckoutStep.payment;
    } else if (_checkoutStep == GuestCheckoutStep.payment) {
      _checkoutStep = GuestCheckoutStep.confirm;
    } else {
      closeSheet();
    }
    notifyListeners();
  }

  void checkoutSelectPayment(String id) {
    setPaymentId(id);
    _checkoutStep = GuestCheckoutStep.payDetail;
    checkoutError = null;
    notifyListeners();
  }

  bool checkoutAdvance() {
    checkoutError = null;
    if (_checkoutStep == GuestCheckoutStep.confirm) {
      if (_paymentMethods.isEmpty) {
        _checkoutStep = GuestCheckoutStep.payDetail;
      } else {
        _checkoutStep = GuestCheckoutStep.payment;
      }
      notifyListeners();
      return false;
    }
    return _checkoutStep == GuestCheckoutStep.payDetail;
  }

  Map<String, dynamic>? selectedPaymentMethod() {
    for (final m in _paymentMethods) {
      if (m['id']?.toString() == _paymentId) return m;
    }
    return _paymentMethods.isEmpty ? null : _paymentMethods.first;
  }

  String checkoutPrimaryLabel() {
    switch (_checkoutStep) {
      case GuestCheckoutStep.confirm:
        return _paymentMethods.isEmpty ? 'Kirim pesanan' : 'Lanjutkan';
      case GuestCheckoutStep.payment:
        return 'Pilih metode pembayaran';
      case GuestCheckoutStep.payDetail:
        return busy ? 'Mengirim...' : 'Kirim pesanan';
    }
  }

  String checkoutTitle() {
    switch (_checkoutStep) {
      case GuestCheckoutStep.confirm:
        return 'Pesanan';
      case GuestCheckoutStep.payment:
        return 'Pembayaran';
      case GuestCheckoutStep.payDetail:
        final m = selectedPaymentMethod();
        return m?['title']?.toString() ?? 'Detail pembayaran';
    }
  }

  void replaceReservation({
    required int productId,
    required String name,
    required int price,
    required List<GuestReservationSlot> slots,
  }) {
    if (productId <= 0 || slots.isEmpty) return;
    _lines[productId] = GuestSiteCartLine(productId: productId, name: name, price: price, slots: slots);
    unawaited(_persist());
    notifyListeners();
  }

  void setQty(int productId, int qty) {
    final prev = _lines[productId];
    if (prev == null) return;
    if (prev.slots.isNotEmpty) {
      if (qty <= 0) _lines.remove(productId);
    } else if (qty <= 0) {
      _lines.remove(productId);
    } else {
      _lines[productId] = GuestSiteCartLine(
        productId: productId,
        name: prev.name,
        price: prev.price,
        qty: qty,
        note: prev.note,
      );
    }
    unawaited(_persist());
    notifyListeners();
  }

  void openSheet() => pesan();

  void closeSheet() {
    _sheet = GuestSiteCartSheet.none;
    _checkoutStep = GuestCheckoutStep.confirm;
    checkoutError = null;
    notifyListeners();
  }

  Future<int?> submit({required String customerName, String phone = '', String note = ''}) async {
    if (_busy || customerName.trim().isEmpty || _lines.isEmpty) return null;
    _busy = true;
    notifyListeners();
    try {
      final lines = _lines.values.toList(growable: false);
      final orderNote = guestOrderNoteWithPayment(
        note: note,
        paymentId: _paymentId,
        paymentMethods: _paymentMethods,
      );
      final visitorId = await GuestAssistantApi.visitorIdForSite(siteIid);
      final res = await GuestOrderApi.orderPut(
        siteIid: siteIid,
        customerName: customerName.trim(),
        customerPhone: phone.trim(),
        note: orderNote,
        items: [for (final l in lines) l.orderItemJson()],
        reservations: [for (final l in lines) ...l.reservationJson()],
        visitorId: visitorId,
      );
      final tx = res['tx'];
      final txId = tx is Map ? (tx['tx_id'] as num?)?.toInt() : null;
      final orderTotal = tx is Map ? (tx['total'] as num?)?.toInt() ?? total : total;
      _lines.clear();
      await _persist();
      _sheet = GuestSiteCartSheet.none;
      _checkoutStep = GuestCheckoutStep.confirm;
      if (txId != null) await GuestSiteMemberStore.orderSave(siteIid: siteIid, txId: txId, total: orderTotal);
      return txId;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}

class GuestSiteMemberStore {
  static Future<void> orderSave({required int siteIid, required int txId, required int total}) async {
    final p = await SharedPreferences.getInstance();
    final key = 'c35.guest.orders.v1.$siteIid';
    final raw = p.getString(key);
    final list = raw != null ? (jsonDecode(raw) as List?)?.toList() ?? [] : <dynamic>[];
    list.insert(0, {'tx_id': txId, 'total': total, 'placed_ts_ms': DateTime.now().millisecondsSinceEpoch});
    await p.setString(key, jsonEncode(list.take(20).toList()));
  }

  static Future<List<Map<String, dynamic>>> ordersList(int siteIid) async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString('c35.guest.orders.v1.$siteIid');
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw);
      if (list is! List) return [];
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList(growable: false);
    } catch (_) {
      return [];
    }
  }
}

class GuestSiteCartScope extends InheritedNotifier<GuestSiteCartController> {
  const GuestSiteCartScope({super.key, required GuestSiteCartController controller, required super.child})
      : super(notifier: controller);

  static GuestSiteCartController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GuestSiteCartScope>()?.notifier;
}

Color _guestCartBarFill(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  return Theme.of(context).brightness == Brightness.dark ? const Color(0xFF18181B) : scheme.surfaceContainerHigh;
}

/// CSA guest sheet — blurred scrim + slide-up panel (site-guest.v1.css).
Widget _guestCartBarInner({
  required BuildContext context,
  required Color onBar,
  required Color mutedOnBar,
  required Color accent,
  required GuestSiteCartController controller,
}) {
  final content = Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                moneyFmtIdr(controller.total),
                style: TextStyle(
                  color: onBar,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${controller.count} item',
                  style: TextStyle(
                    color: mutedOnBar,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        ),
        FilledButton(
          key: const Key('guest-cart-pesan'),
          style: FilledButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: controller.pesan,
          child: const Text('Pesan', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );
  if (Theme.of(context).brightness == Brightness.dark) {
    return BackdropFilter(filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14), child: content);
  }
  return content;
}

class GuestSiteCommerceSheetHost extends StatelessWidget {
  const GuestSiteCommerceSheetHost({super.key, required this.panel});

  final Widget panel;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: const ColoredBox(color: Color(0x73000000)),
              ),
            ),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 1, end: 0),
              duration: const Duration(milliseconds: 340),
              curve: Curves.easeOutCubic,
              builder: (context, slide, child) => Transform.translate(
                offset: Offset(0, 20 * slide),
                child: Opacity(opacity: 1 - slide * 0.25, child: child),
              ),
              child: Align(alignment: Alignment.bottomCenter, child: panel),
            ),
          ],
        ),
      );
}

class GuestSiteCartChrome extends StatelessWidget {
  const GuestSiteCartChrome({
    super.key,
    required this.controller,
    required this.accent,
    required this.child,
    this.memberPortalEnabled = true,
  });

  final GuestSiteCartController controller;
  final Color accent;
  final Widget child;
  final bool memberPortalEnabled;

  @override
  Widget build(BuildContext context) {
    final barFill = _guestCartBarFill(context);
    final onBar = Theme.of(context).brightness == Brightness.dark ? const Color(0xFFF4F4F5) : Theme.of(context).colorScheme.onSurface;
    final mutedOnBar = Theme.of(context).brightness == Brightness.dark ? const Color(0xFFA1A1AA) : Theme.of(context).colorScheme.onSurfaceVariant;

    return ListenableBuilder(
        listenable: controller,
        builder: (context, _) => Stack(
          children: [
            child,
            GuestSiteOrdersChip(
              siteIid: controller.siteIid,
              accent: accent,
              controller: controller,
              memberPortalEnabled: memberPortalEnabled,
            ),
            if (controller.count > 0 && !controller.sheetOpen)
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: TweenAnimationBuilder<double>(
                  key: ValueKey<int>(controller.count),
                  tween: Tween(begin: 1, end: 0),
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                  builder: (context, slide, child) => Transform.translate(
                    offset: Offset(0, 18 * slide),
                    child: Opacity(opacity: 1 - slide * 0.2, child: child),
                  ),
                  child: Material(
                    key: const Key('guest-cart-bar'),
                    color: barFill.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.92 : 1),
                    elevation: 8,
                    shadowColor: Colors.black.withValues(alpha: 0.28),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: onBar.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.08 : 0.12),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _guestCartBarInner(
                      context: context,
                      onBar: onBar,
                      mutedOnBar: mutedOnBar,
                      accent: accent,
                      controller: controller,
                    ),
                  ),
                ),
              ),
            if (controller.sheet == GuestSiteCartSheet.order)
              GuestSiteOrderSheet(
                controller: controller,
                accent: accent,
                fg: const Color(0xFFF4F4F5),
                cardBg: const Color(0xFF18181B),
                muted: const Color(0xFFA1A1AA),
              ),
            if (controller.sheet == GuestSiteCartSheet.checkout)
              GuestSiteCheckoutSheet(controller: controller, accent: accent),
          ],
        ),
      );
  }
}

class GuestSiteOrderSheet extends StatelessWidget {
  const GuestSiteOrderSheet({
    super.key,
    required this.controller,
    required this.accent,
    required this.fg,
    required this.cardBg,
    required this.muted,
  });

  final GuestSiteCartController controller;
  final Color accent;
  final Color fg;
  final Color cardBg;
  final Color muted;

  static const _numpad = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '00', '\u232b'];

  @override
  Widget build(BuildContext context) {
    final draft = controller.orderDraft;
    if (draft == null) return const SizedBox.shrink();
    final lineTotal = draft.price * draft.qty;
    final primary = draft.qty > 0 ? 'Pesan ${draft.qty} item · Rp $lineTotal' : 'Batalkan';
    return GuestSiteCommerceSheetHost(
      panel: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 480),
        decoration: BoxDecoration(color: cardBg, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: muted.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2))),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          _orderPic(context, draft.pic, accent),
                          if (draft.qty > 0)
                            Positioned(
                              top: -6,
                              right: -6,
                              child: CircleAvatar(radius: 10, backgroundColor: accent, child: Text('${draft.qty}', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w800))),
                            ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(children: [
                              Expanded(child: Text(draft.name, style: TextStyle(fontWeight: FontWeight.w700, color: fg))),
                              Text('Rp ${draft.price}', style: TextStyle(fontWeight: FontWeight.w800, color: accent)),
                            ]),
                            if (draft.desc.trim().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  draft.desc.trim(),
                                  style: TextStyle(fontSize: 12, height: 1.35, color: muted),
                                ),
                              ),
                            const SizedBox(height: 8),
                            TextField(
                              style: TextStyle(color: fg),
                              minLines: 2,
                              maxLines: 4,
                              keyboardType: TextInputType.multiline,
                              decoration: InputDecoration(isDense: true, hintText: 'Catatan (opsional)...', hintStyle: TextStyle(color: muted), filled: true, fillColor: fg.withValues(alpha: 0.06), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
                              onChanged: controller.orderSetNote,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (draft.stockMax != null)
                    Padding(padding: const EdgeInsets.only(top: 8), child: Align(alignment: Alignment.centerLeft, child: Text('Stok: ${draft.stockMax}', style: TextStyle(fontSize: 12, color: muted)))),
                  const SizedBox(height: 12),
                  GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 3,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.8,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      for (final k in _numpad)
                        Material(
                          color: fg.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: () => controller.orderNumpad(k),
                            borderRadius: BorderRadius.circular(12),
                            child: Center(child: Text(k, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: fg))),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: draft.qty > 0 ? accent : muted.withValues(alpha: 0.3), foregroundColor: draft.qty > 0 ? Colors.white : muted, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      onPressed: () => draft.qty <= 0 ? controller.cancelOrder() : controller.confirmOrder(),
                      child: Text(primary, textAlign: TextAlign.center),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    );
  }

  Widget _orderPic(BuildContext context, String pic, Color accent) {
    if (pic.isNotEmpty) {
      return GestureDetector(
        onTap: () => unawaited(showGuestSitePicViewer(context, pic)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: GuestSitePic(pic: pic, width: 52, height: 52, fit: BoxFit.cover),
        ),
      );
    }
    return Container(width: 52, height: 52, alignment: Alignment.center, decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)), child: const Text('\u{1F6CD}', style: TextStyle(fontSize: 22)));
  }
}

/// CSA `guest-field` — label above bordered input (site-guest.v1.css).
Widget guestSiteFormField({
  required String label,
  required Color labelColor,
  required Color fg,
  required Color borderColor,
  required Widget child,
}) {
  return Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: TextStyle(color: labelColor, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        child,
      ],
    ),
  );
}

InputDecoration guestSiteFieldDecoration({
  required Color fg,
  required Color fillColor,
  required Color borderColor,
  required Color focusColor,
  String? hintText,
}) {
  final radius = BorderRadius.circular(10);
  return InputDecoration(
    hintText: hintText,
    hintStyle: TextStyle(color: borderColor.withValues(alpha: 0.85)),
    isDense: true,
    filled: true,
    fillColor: fillColor,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    border: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: borderColor)),
    enabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: borderColor)),
    focusedBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: focusColor, width: 1.5)),
  );
}

class GuestSiteCheckoutSheet extends StatefulWidget {
  const GuestSiteCheckoutSheet({super.key, required this.controller, required this.accent});

  final GuestSiteCartController controller;
  final Color accent;

  @override
  State<GuestSiteCheckoutSheet> createState() => _GuestSiteCheckoutSheetState();
}

class _GuestSiteCheckoutSheetState extends State<GuestSiteCheckoutSheet> {
  static const _fg = Color(0xFFF4F4F5);
  static const _cardBg = Color(0xFF18181B);
  static const _muted = Color(0xFFA1A1AA);

  late final TextEditingController _name = TextEditingController(text: widget.controller.checkoutCustomerName);
  late final TextEditingController _phone = TextEditingController(text: widget.controller.checkoutCustomerPhone);
  late final TextEditingController _note = TextEditingController(text: widget.controller.checkoutOrderNote);

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _note.dispose();
    super.dispose();
  }

  void _syncCheckoutFields() {
    widget.controller.checkoutCustomerName = _name.text;
    widget.controller.checkoutCustomerPhone = _phone.text;
    widget.controller.checkoutOrderNote = _note.text;
  }

  Future<void> _submit() async {
    _syncCheckoutFields();
    final name = _name.text.trim();
    if (name.isEmpty) {
      widget.controller.checkoutError = 'Nama wajib diisi';
      setState(() {});
      return;
    }
    final id = await widget.controller.submit(customerName: name, phone: _phone.text, note: _note.text);
    if (id != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pesanan #$id diterima')));
    }
  }

  Future<void> _onPrimary() async {
    final c = widget.controller;
    if (c.checkoutStep == GuestCheckoutStep.payment) return;
    if (c.checkoutStep == GuestCheckoutStep.confirm) {
      c.checkoutAdvance();
      if (c.paymentMethods.isEmpty) {
        await _submit();
      } else {
        setState(() {});
      }
      return;
    }
    await _submit();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final step = c.checkoutStep;
    final canSubmit = step == GuestCheckoutStep.payDetail || (step == GuestCheckoutStep.confirm && c.paymentMethods.isEmpty);

    return GuestSiteCheckoutSheetPanel(
      fg: _fg,
      cardBg: _cardBg,
      muted: _muted,
      accent: widget.accent,
      title: c.checkoutTitle(),
      onBack: step == GuestCheckoutStep.confirm ? null : c.checkoutBack,
      onClose: c.closeSheet,
      body: switch (step) {
        GuestCheckoutStep.confirm => _confirmBody(c),
        GuestCheckoutStep.payment => _paymentBody(c),
        GuestCheckoutStep.payDetail => _payDetailBody(c),
      },
      footer: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: widget.accent,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: c.busy || (step == GuestCheckoutStep.payment && !canSubmit)
            ? null
            : () => unawaited(_onPrimary()),
        child: Text(c.checkoutPrimaryLabel()),
      ),
    );
  }

  Widget _confirmBody(GuestSiteCartController c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: _fg.withValues(alpha: 0.06),
          ),
          child: Column(
            children: [
              for (final l in c.lines) _checkoutLineRow(l, c),
            ],
          ),
        ),
        _checkoutRow('Subtotal', moneyFmtIdr(c.subtotal), muted: true),
        if (c.taxTotal > 0) _checkoutRow('Pajak', moneyFmtIdr(c.taxTotal), muted: true),
        _checkoutRow('Total', moneyFmtIdr(c.total), bold: true),
        const SizedBox(height: 4),
        guestSiteFormField(
          label: 'Nama',
          labelColor: _muted,
          fg: _fg,
          borderColor: _muted.withValues(alpha: 0.45),
          child: TextField(
            controller: _name,
            onChanged: (_) => _syncCheckoutFields(),
            style: TextStyle(color: _fg, fontSize: 14),
            decoration: guestSiteFieldDecoration(
              fg: _fg,
              fillColor: _fg.withValues(alpha: 0.06),
              borderColor: _muted.withValues(alpha: 0.45),
              focusColor: widget.accent,
              hintText: 'Nama Anda',
            ),
          ),
        ),
        guestSiteFormField(
          label: 'HP / WhatsApp',
          labelColor: _muted,
          fg: _fg,
          borderColor: _muted.withValues(alpha: 0.45),
          child: TextField(
            controller: _phone,
            onChanged: (_) => _syncCheckoutFields(),
            keyboardType: TextInputType.phone,
            style: TextStyle(color: _fg, fontSize: 14),
            decoration: guestSiteFieldDecoration(
              fg: _fg,
              fillColor: _fg.withValues(alpha: 0.06),
              borderColor: _muted.withValues(alpha: 0.45),
              focusColor: widget.accent,
              hintText: '08...',
            ),
          ),
        ),
        guestSiteFormField(
          label: 'Catatan pesanan',
          labelColor: _muted,
          fg: _fg,
          borderColor: _muted.withValues(alpha: 0.45),
          child: TextField(
            controller: _note,
            onChanged: (_) => _syncCheckoutFields(),
            style: TextStyle(color: _fg, fontSize: 14),
            maxLines: 2,
            decoration: guestSiteFieldDecoration(
              fg: _fg,
              fillColor: _fg.withValues(alpha: 0.06),
              borderColor: _muted.withValues(alpha: 0.45),
              focusColor: widget.accent,
            ),
          ),
        ),
        if (c.paymentMethods.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Tidak ada metode pembayaran dikonfigurasi. Pesanan tetap bisa dikirim.',
              style: TextStyle(color: Color(0xFFF59E0B), fontSize: 12),
            ),
          ),
        if (c.checkoutError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(c.checkoutError!, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12)),
          ),
      ],
    );
  }

  Widget _checkoutLineRow(GuestSiteCartLine l, GuestSiteCartController c) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: widget.accent, borderRadius: BorderRadius.circular(999)),
            child: Text('${l.qty}×', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.name, style: const TextStyle(color: _fg, fontWeight: FontWeight.w600)),
                if (l.note.trim().isNotEmpty)
                  Text(l.note.trim(), style: const TextStyle(color: _muted, fontSize: 12)),
                if (l.slots.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFFFFEDD5), borderRadius: BorderRadius.circular(999)),
                    child: const Text('Reservasi', style: TextStyle(color: Color(0xFF9A3412), fontSize: 10, fontWeight: FontWeight.w800)),
                  ),
              ],
            ),
          ),
          Text(
            moneyFmtIdr(l.lineTotal),
            style: const TextStyle(
              color: _fg,
              fontWeight: FontWeight.w700,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _checkoutRow(String label, String value, {bool muted = false, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(color: muted ? _muted : _fg, fontWeight: bold ? FontWeight.w800 : FontWeight.w500))),
          Text(
            value,
            style: TextStyle(
              color: _fg,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentBody(GuestSiteCartController c) {
    return Column(
      children: [
        for (final m in c.paymentMethods)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: _fg.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  final id = m['id']?.toString() ?? '';
                  if (id.isEmpty) return;
                  c.checkoutSelectPayment(id);
                  setState(() {});
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: _cardBg,
                        child: Icon(guestPaymentMethodIcon(m['type']?.toString() ?? ''), color: _muted, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m['title']?.toString() ?? m['id']?.toString() ?? '', style: const TextStyle(color: _fg, fontWeight: FontWeight.w700)),
                            if ((m['subtitle']?.toString() ?? '').trim().isNotEmpty)
                              Text(m['subtitle']!.toString(), style: const TextStyle(color: _muted, fontSize: 12)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: _muted),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _qrisPreview(Map<String, dynamic>? method) {
    final qris = method?['qris_pic']?.toString() ?? '';
    if (qris.trim().isEmpty) {
      return const Text('QRIS belum dikonfigurasi.', style: TextStyle(color: _muted));
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: GuestSitePic(pic: qris, height: 180, width: 180, fit: BoxFit.contain),
    );
  }

  Widget _payDetailBody(GuestSiteCartController c) {
    final m = c.selectedPaymentMethod();
    final type = m?['type']?.toString().toLowerCase() ?? 'cash';
    final title = m?['title']?.toString() ?? 'Pembayaran';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: _fg.withValues(alpha: 0.05),
          ),
          child: Column(
            children: [
              Icon(guestPaymentMethodIcon(type), size: 32, color: _fg),
              const SizedBox(height: 8),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(color: _fg, fontWeight: FontWeight.w800, fontSize: 17)),
              const SizedBox(height: 6),
              if (type == 'cash')
                const Text('Siapkan uang pas saat pesanan diantar.', textAlign: TextAlign.center, style: TextStyle(color: _muted))
              else if (type == 'transfer') ...[
                if ((m?['bank']?.toString() ?? '').trim().isNotEmpty) Text('Bank: ${m!['bank']}', style: const TextStyle(color: _muted)),
                if ((m?['account_name']?.toString() ?? '').trim().isNotEmpty) Text(m!['account_name']!.toString(), style: const TextStyle(color: _fg, fontWeight: FontWeight.w600)),
                if ((m?['account_number']?.toString() ?? '').trim().isNotEmpty) Text(m!['account_number']!.toString(), style: const TextStyle(color: _fg, fontWeight: FontWeight.w700)),
              ]               else if (type == 'qris')
                _qrisPreview(m)
              else
                const Text('Ikuti instruksi dari toko setelah pesanan dikirim.', textAlign: TextAlign.center, style: TextStyle(color: _muted)),
              const SizedBox(height: 12),
              Text(moneyFmtIdr(c.total), style: TextStyle(color: widget.accent, fontWeight: FontWeight.w900, fontSize: 20)),
            ],
          ),
        ),
        if (c.checkoutError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(c.checkoutError!, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12)),
          ),
      ],
    );
  }
}

class GuestSiteCheckoutSheetPanel extends StatelessWidget {
  const GuestSiteCheckoutSheetPanel({
    super.key,
    required this.fg,
    required this.cardBg,
    required this.muted,
    required this.accent,
    required this.title,
    required this.body,
    required this.footer,
    this.onBack,
    required this.onClose,
  });

  final Color fg;
  final Color cardBg;
  final Color muted;
  final Color accent;
  final String title;
  final Widget body;
  final Widget footer;
  final VoidCallback? onBack;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => GuestSiteCommerceSheetHost(
        panel: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(color: muted.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)),
                  ),
                  Row(
                    children: [
                      SizedBox(
                        width: 40,
                        child: onBack != null
                            ? IconButton(onPressed: onBack, icon: Icon(Icons.arrow_back, color: fg))
                            : const SizedBox.shrink(),
                      ),
                      Expanded(
                        child: Text(title, textAlign: TextAlign.center, style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 17)),
                      ),
                      IconButton(onPressed: onClose, icon: Icon(Icons.close, color: muted)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(child: SingleChildScrollView(child: body)),
                  const SizedBox(height: 12),
                  footer,
                ],
              ),
            ),
          ),
        ),
      );
}

class GuestSiteOrdersChip extends StatefulWidget {
  const GuestSiteOrdersChip({
    super.key,
    required this.siteIid,
    required this.accent,
    this.controller,
    this.memberPortalEnabled = true,
  });

  final int siteIid;
  final Color accent;
  final GuestSiteCartController? controller;
  final bool memberPortalEnabled;

  @override
  State<GuestSiteOrdersChip> createState() => _GuestSiteOrdersChipState();
}

class _GuestSiteOrdersChipState extends State<GuestSiteOrdersChip> {
  var _count = 0;

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_onCart);
    unawaited(_reload());
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onCart);
    super.dispose();
  }

  void _onCart() => unawaited(_reload());

  Future<void> _reload() async {
    final list = await GuestSiteMemberStore.ordersList(widget.siteIid);
    if (!mounted) return;
    setState(() => _count = list.length);
  }

  @override
  Widget build(BuildContext context) {
    if (_count <= 0 && !widget.memberPortalEnabled) return const SizedBox.shrink();
    return Positioned(
      top: 12,
      right: 12,
      child: Material(
        color: const Color(0xCC18181B),
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: () => guestSiteShowMemberPortal(context: context, siteIid: widget.siteIid, accent: widget.accent),
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              _count > 0 ? 'Pesanan saya ($_count)' : 'Akun',
              style: TextStyle(color: widget.accent, fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
        ),
      ),
    );
  }
}
