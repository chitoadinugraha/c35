import 'dart:async';
import 'dart:convert';

import 'package:alienai_c35/c/site/guest_order_api.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GuestSiteCartLine {
  const GuestSiteCartLine({required this.productId, required this.name, required this.price, this.qty = 1});

  final int productId;
  final String name;
  final int price;
  final int qty;

  int get lineTotal => price * qty;
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
      _lines.clear();
      for (final e in map.entries) {
        final pid = int.tryParse(e.key.toString());
        final qty = e.value is num ? e.value.toInt() : 0;
        if (pid == null || qty <= 0) continue;
        _lines[pid] = GuestSiteCartLine(productId: pid, name: 'Product $pid', price: 0, qty: qty);
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _persist() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
      'c35.guest.cart.v1.$siteIid',
      jsonEncode({for (final l in _lines.values) '${l.productId}': l.qty}),
    );
  }

  void addProduct({required int productId, required String name, required int price}) {
    final prev = _lines[productId];
    _lines[productId] = GuestSiteCartLine(
      productId: productId,
      name: name,
      price: price,
      qty: (prev?.qty ?? 0) + 1,
    );
    unawaited(_persist());
    notifyListeners();
  }

  void setQty(int productId, int qty) {
    if (qty <= 0) {
      _lines.remove(productId);
    } else {
      final prev = _lines[productId];
      if (prev == null) return;
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
      final res = await GuestOrderApi.orderPut(
        siteIid: siteIid,
        customerName: customerName.trim(),
        customerPhone: phone.trim(),
        note: note.trim(),
        items: _lines.values.map((l) => {'product_id': l.productId, 'qty': l.qty}).toList(),
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
                          trailing: Row(
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
