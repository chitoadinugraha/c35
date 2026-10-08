import 'dart:async';
import 'dart:convert';

import 'package:alienai_c35/c/site/guest_order_api.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GuestReservationSlot {
  const GuestReservationSlot({
    required this.start,
    required this.end,
    required this.units,
    required this.durationQty,
    this.siteObjectId = 0,
    this.objectName = '',
  });

  final DateTime start;
  final DateTime end;
  final int units;
  final int durationQty;
  final int siteObjectId;
  final String objectName;

  Map<String, dynamic> toStoredJson() => {
        'start_ts_ms': start.millisecondsSinceEpoch,
        'end_ts_ms': end.millisecondsSinceEpoch,
        'units': units,
        'duration_qty': durationQty,
        'site_object_id': siteObjectId,
        'object_name': objectName,
      };

  static GuestReservationSlot? fromStoredJson(Object? raw) {
    if (raw is! Map) return null;
    final startMs = (raw['start_ts_ms'] as num?)?.toInt();
    final endMs = (raw['end_ts_ms'] as num?)?.toInt();
    if (startMs == null || endMs == null) return null;
    return GuestReservationSlot(
      start: DateTime.fromMillisecondsSinceEpoch(startMs),
      end: DateTime.fromMillisecondsSinceEpoch(endMs),
      units: (raw['units'] as num?)?.toInt() ?? 1,
      durationQty: (raw['duration_qty'] as num?)?.toInt() ?? 1,
      siteObjectId: (raw['site_object_id'] as num?)?.toInt() ?? 0,
      objectName: raw['object_name']?.toString() ?? '',
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
    List<GuestReservationSlot> slots = const [],
  })  : slots = List<GuestReservationSlot>.unmodifiable(slots),
        qty = slots.isEmpty ? qty : guestReservationLineQty(slots);

  final int productId;
  final String name;
  final int price;
  final int qty;
  final List<GuestReservationSlot> slots;

  int get lineTotal => price * qty;

  List<Map<String, dynamic>> reservationJson() => [
        for (final slot in slots)
          {
            'product_id': productId,
            'qty': slot.units,
            'duration_qty': slot.durationQty < 1 ? 1 : slot.durationQty,
            'start_ts_ms': slot.start.millisecondsSinceEpoch,
            'end_ts_ms': slot.end.millisecondsSinceEpoch,
            'site_object_id': slot.siteObjectId,
            'state': 'pending',
          },
      ];

  Map<String, dynamic> orderItemJson() => {
        'product_id': productId,
        'qty': qty,
        if (slots.isNotEmpty) 'reservations': reservationJson(),
      };

  Object toStoredJson() {
    if (slots.isEmpty) return qty;
    return {
      'name': name,
      'price': price,
      'qty': qty,
      'slots': [for (final slot in slots) slot.toStoredJson()],
    };
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
    if (slots.isEmpty) {
      final qty = (value['qty'] as num?)?.toInt() ?? 0;
      if (qty <= 0) continue;
      lines[pid] = GuestSiteCartLine(productId: pid, name: name, price: price, qty: qty);
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
  var _sheetOpen = false;
  var _busy = false;

  bool get sheetOpen => _sheetOpen;
  bool get busy => _busy;
  int get count => _lines.values.fold(0, (a, l) => a + l.qty);
  int get total => _lines.values.fold(0, (a, l) => a + l.lineTotal);
  List<GuestSiteCartLine> get lines => _lines.values.toList(growable: false);

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

  void addProduct({required int productId, required String name, required int price}) {
    final prev = _lines[productId];
    if (prev != null && prev.slots.isNotEmpty) return;
    _lines[productId] = GuestSiteCartLine(
      productId: productId,
      name: name,
      price: price,
      qty: (prev?.qty ?? 0) + 1,
    );
    unawaited(_persist());
    notifyListeners();
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
      _lines[productId] = GuestSiteCartLine(productId: productId, name: prev.name, price: prev.price, qty: qty);
    }
    unawaited(_persist());
    notifyListeners();
  }

  void openSheet() {
    if (count == 0) return;
    _sheetOpen = true;
    notifyListeners();
  }

  void closeSheet() {
    _sheetOpen = false;
    notifyListeners();
  }

  Future<int?> submit({required String customerName, String phone = '', String note = ''}) async {
    if (_busy || customerName.trim().isEmpty || _lines.isEmpty) return null;
    _busy = true;
    notifyListeners();
    try {
      final lines = _lines.values.toList(growable: false);
      final res = await GuestOrderApi.orderPut(
        siteIid: siteIid,
        customerName: customerName.trim(),
        customerPhone: phone.trim(),
        note: note.trim(),
        items: [for (final l in lines) l.orderItemJson()],
        reservations: [for (final l in lines) ...l.reservationJson()],
      );
      final tx = res['tx'];
      final txId = tx is Map ? (tx['tx_id'] as num?)?.toInt() : null;
      final orderTotal = tx is Map ? (tx['total'] as num?)?.toInt() ?? total : total;
      _lines.clear();
      await _persist();
      _sheetOpen = false;
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

class GuestSiteCartChrome extends StatelessWidget {
  const GuestSiteCartChrome({super.key, required this.controller, required this.accent, required this.child});

  final GuestSiteCartController controller;
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: controller,
        builder: (context, _) => Stack(
          children: [
            child,
            GuestSiteOrdersChip(siteIid: controller.siteIid, accent: accent, controller: controller),
            if (controller.count > 0)
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Material(
                  color: const Color(0xFF18181B),
                  borderRadius: BorderRadius.circular(999),
                  child: InkWell(
                    onTap: controller.openSheet,
                    borderRadius: BorderRadius.circular(999),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: accent,
                            child: Text('${controller.count}', style: const TextStyle(fontSize: 11, color: Colors.white)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text('Rp ${controller.total}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
                          Text('Lihat', style: TextStyle(color: accent, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (controller.sheetOpen) GuestSiteCheckoutSheet(controller: controller, accent: accent),
          ],
        ),
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
  late final TextEditingController _name = TextEditingController();
  late final TextEditingController _phone = TextEditingController();
  late final TextEditingController _note = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.black54,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 480, maxHeight: 520),
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF18181B),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(child: Text('Pesanan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
                    IconButton(onPressed: widget.controller.closeSheet, icon: const Icon(Icons.close, color: Colors.white70)),
                  ],
                ),
                Expanded(
                  child: ListView(
                    children: [
                      for (final l in widget.controller.lines)
                        ListTile(
                          dense: true,
                          title: Text(l.name, style: const TextStyle(color: Colors.white, fontSize: 13)),
                          subtitle: Text('Rp ${l.lineTotal}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                          trailing: l.slots.isEmpty
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove, size: 18, color: Colors.white70),
                                      onPressed: () => widget.controller.setQty(l.productId, l.qty - 1),
                                    ),
                                    Text('${l.qty}', style: const TextStyle(color: Colors.white)),
                                    IconButton(
                                      icon: const Icon(Icons.add, size: 18, color: Colors.white70),
                                      onPressed: () => widget.controller.setQty(l.productId, l.qty + 1),
                                    ),
                                  ],
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('${l.qty}', style: const TextStyle(color: Colors.white)),
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 18, color: Colors.white70),
                                      onPressed: () => widget.controller.setQty(l.productId, 0),
                                    ),
                                  ],
                                ),
                        ),
                      TextField(controller: _name, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Nama')),
                      TextField(controller: _phone, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'HP / WhatsApp')),
                    ],
                  ),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: widget.accent),
                  onPressed: widget.controller.busy
                      ? null
                      : () async {
                          final id = await widget.controller.submit(customerName: _name.text, phone: _phone.text, note: _note.text);
                          if (id != null && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pesanan #$id diterima')));
                          }
                        },
                  child: Text(widget.controller.busy ? 'Mengirim...' : 'Kirim pesanan'),
                ),
              ],
            ),
          ),
        ),
      );
}
class GuestSiteOrdersChip extends StatefulWidget {
  const GuestSiteOrdersChip({super.key, required this.siteIid, required this.accent, this.controller});

  final int siteIid;
  final Color accent;
  final GuestSiteCartController? controller;

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

  Future<void> _openSheet() async {
    final orders = await GuestSiteMemberStore.ordersList(widget.siteIid);
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF18181B),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Pesanan saya', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              if (orders.isEmpty)
                const Text('Belum ada pesanan', style: TextStyle(color: Colors.white54))
              else
                Expanded(
                  child: ListView(
                    children: [
                      for (final o in orders)
                        ListTile(
                          title: Text('#${o['tx_id']}', style: const TextStyle(color: Colors.white)),
                          subtitle: Text('IDR ${o['total']}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    if (_count <= 0) return const SizedBox.shrink();
    return Positioned(
      top: 12,
      right: 12,
      child: Material(
        color: const Color(0xCC18181B),
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: _openSheet,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text('Pesanan saya ($_count)', style: TextStyle(color: widget.accent, fontWeight: FontWeight.w600, fontSize: 12)),
          ),
        ),
      ),
    );
  }
}
