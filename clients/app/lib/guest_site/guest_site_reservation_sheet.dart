import 'dart:async';
import 'dart:convert';

import 'package:alienai_c35/c/config.dart';
import 'package:alienai_c35/c/site/site_reservation_math.dart';
import 'package:alienai_c35/c/ui/money_format.dart';
import 'package:alienai_c35/guest_site/guest_site_cart.dart';
import 'package:alienai_c35/guest_site/guest_site_pic.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String guestReservationWhenLabel(DateTime value, String unit) {
  final date = '${value.day} ${_months[value.month - 1]}';
  if (!reservationNeedsTime(unit)) return date;
  final hh = value.hour.toString().padLeft(2, '0');
  final mm = value.minute.toString().padLeft(2, '0');
  return '$date, $hh:$mm';
}

class GuestReservationAvailability {
  const GuestReservationAvailability({required this.unitsAvailable, required this.freeObjectIds});

  final int unitsAvailable;
  final Set<int> freeObjectIds;
}

Future<GuestReservationAvailability?> guestReservationAvailability({
  required int siteIid,
  required int productId,
  required int startTsMs,
  required int endTsMs,
  required int units,
}) async {
  try {
    final resp = await http.post(
      Uri.parse('$authApiProductionUrl/v1/site/guest-reservation/availability'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'site_iid': siteIid,
        'product_id': productId,
        'start_ts_ms': startTsMs,
        'end_ts_ms': endTsMs,
        'units': units,
      }),
    );
    if (resp.statusCode != 200) return null;
    final data = jsonDecode(resp.body);
    if (data is! Map) return null;
    final ids = <int>{};
    final free = data['free_objects'];
    if (free is List) {
      for (final row in free) {
        if (row is! Map) continue;
        final id = (row['id'] as num?)?.toInt();
        if (id != null) ids.add(id);
      }
    }
    return GuestReservationAvailability(
      unitsAvailable: (data['units_available'] as num?)?.toInt() ?? 0,
      freeObjectIds: ids,
    );
  } catch (_) {
    return null;
  }
}

Future<void> showGuestSiteReservationSheet({
  required BuildContext context,
  required int siteIid,
  required Map<String, dynamic> product,
  required List<Map<String, dynamic>> objects,
  Color accent = const Color(0xFFF97316),
}) async {
  final cart = GuestSiteCartScope.maybeOf(context);
  final productId = (product['product_id'] as num?)?.toInt() ?? 0;
  if (cart == null || productId <= 0) return;
  final durationValue = (product['duration_value'] as num?)?.toInt() ?? 1;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF18181B),
    builder: (ctx) => GuestSiteReservationSheet(
      cart: cart,
      siteIid: siteIid,
      productId: productId,
      name: product['name']?.toString() ?? 'Product',
      price: product['price'] is num ? (product['price'] as num).toInt() : 0,
      pic: product['pic']?.toString() ?? '',
      durationUnit: product['duration_unit']?.toString() ?? 'day',
      durationValue: durationValue < 1 ? 1 : durationValue,
      guestPicks: product['reservation_unit_selection']?.toString() == 'guest_picks',
      objects: objects,
      accent: accent,
    ),
  );
}

class GuestSiteReservationSheet extends StatefulWidget {
  const GuestSiteReservationSheet({
    super.key,
    required this.cart,
    required this.siteIid,
    required this.productId,
    required this.name,
    required this.price,
    required this.pic,
    required this.durationUnit,
    required this.durationValue,
    required this.guestPicks,
    required this.objects,
    required this.accent,
  });

  final GuestSiteCartController cart;
  final int siteIid;
  final int productId;
  final String name;
  final int price;
  final String pic;
  final String durationUnit;
  final int durationValue;
  final bool guestPicks;
  final List<Map<String, dynamic>> objects;
  final Color accent;

  @override
  State<GuestSiteReservationSheet> createState() => _GuestSiteReservationSheetState();
}

class _SlotDraft {
  _SlotDraft({required this.start, required this.end, required this.units, required this.durationQty});

  DateTime start;
  DateTime end;
  int units;
  int durationQty;
  int siteObjectId = 0;
  String objectName = '';
  int? unitsAvailable;
  Set<int>? freeObjectIds;
  Timer? timer;
  int fetchGen = 0;
}

class _GuestSiteReservationSheetState extends State<GuestSiteReservationSheet> {
  late final List<_SlotDraft> _slots = [_freshSlot()];

  @override
  void initState() {
    super.initState();
    for (final slot in _slots) {
      _schedule(slot);
    }
  }

  @override
  void dispose() {
    for (final slot in _slots) {
      slot.timer?.cancel();
    }
    super.dispose();
  }

  String get _unit => widget.durationUnit.trim().isEmpty ? 'day' : widget.durationUnit.trim();

  List<Map<String, dynamic>> get _productObjects => [
        for (final object in widget.objects)
          if ((object['product_id'] as num?)?.toInt() == widget.productId) object,
      ];

  int get _billable => _slots.fold(
        0,
        (sum, slot) => sum + reservationBillable(units: slot.units, durationCount: slot.durationQty),
      );

  int get _sheetPrice => widget.price * _billable;

  _SlotDraft _freshSlot() {
    final count = widget.durationValue < 1 ? 1 : widget.durationValue;
    final now = DateTime.now();
    final start = reservationNeedsTime(_unit)
        ? DateTime(now.year, now.month, now.day, now.hour, now.minute)
        : DateTime(now.year, now.month, now.day);
    return _SlotDraft(
      start: start,
      end: reservationEndFromDuration(start: start, unit: _unit, count: count),
      units: 1,
      durationQty: count,
    );
  }

  void _schedule(_SlotDraft slot) {
    slot.timer?.cancel();
    slot.timer = Timer(const Duration(milliseconds: 300), () {
      unawaited(_fetch(slot));
    });
  }

  Future<void> _fetch(_SlotDraft slot) async {
    final gen = ++slot.fetchGen;
    final result = await guestReservationAvailability(
      siteIid: widget.siteIid,
      productId: widget.productId,
      startTsMs: slot.start.millisecondsSinceEpoch,
      endTsMs: slot.end.millisecondsSinceEpoch,
      units: slot.units,
    );
    if (!mounted || gen != slot.fetchGen || !_slots.contains(slot) || result == null) return;
    setState(() {
      slot.unitsAvailable = result.unitsAvailable;
      slot.freeObjectIds = result.freeObjectIds;
    });
  }

  void _setUnits(_SlotDraft slot, int units) {
    if (units < 1) return;
    setState(() => slot.units = units);
    _schedule(slot);
  }

  void _setDuration(_SlotDraft slot, int count) {
    if (count < 1) return;
    setState(() {
      slot.durationQty = count;
      slot.end = reservationEndFromDuration(start: slot.start, unit: _unit, count: count);
    });
    _schedule(slot);
  }

  void _setStart(_SlotDraft slot, DateTime start) {
    final count = slot.durationQty < 1 ? 1 : slot.durationQty;
    setState(() {
      slot.start = start;
      slot.durationQty = count;
      slot.end = reservationEndFromDuration(start: start, unit: _unit, count: count);
    });
    _schedule(slot);
  }

  void _setEnd(_SlotDraft slot, DateTime end) {
    setState(() {
      slot.end = end;
      slot.durationQty = reservationDurationCount(start: slot.start, end: end, unit: _unit);
    });
    _schedule(slot);
  }

  Future<void> _pick(_SlotDraft slot, {required bool start}) async {
    final current = start ? slot.start : slot.end;
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    DateTime picked;
    if (!reservationNeedsTime(_unit)) {
      picked = DateTime(date.year, date.month, date.day);
    } else {
      final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(current));
      if (time == null || !mounted) return;
      picked = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    }
    if (start) {
      _setStart(slot, picked);
    } else {
      _setEnd(slot, picked);
    }
  }

  void _confirm() {
    final slots = <GuestReservationSlot>[
      for (final slot in _slots)
        if (reservationBillable(units: slot.units, durationCount: slot.durationQty) > 0)
          GuestReservationSlot(
            start: slot.start,
            end: slot.end,
            units: slot.units,
            durationQty: slot.durationQty,
            siteObjectId: slot.siteObjectId,
            objectName: slot.objectName,
          ),
    ];
    if (slots.isEmpty) return;
    widget.cart.replaceReservation(
      productId: widget.productId,
      name: widget.name,
      price: widget.price,
      slots: slots,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.88;
    final picUrl = guestSitePicUrl(widget.pic);
    final priceLabel = 'Rp ${moneyFmtIdrGrouped(_sheetPrice)}';
    return SafeArea(
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: picUrl.isEmpty
                        ? Container(width: 56, height: 56, color: const Color(0xFF27272A))
                        : Image.network(
                            picUrl,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(width: 56, height: 56, color: const Color(0xFF27272A)),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(widget.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: widget.accent,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text('$_billable', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(priceLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        Text(
                          'Rp ${moneyFmtIdrGrouped(widget.price)} / $_unit',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: [
                    for (var i = 0; i < _slots.length; i++) _slotCard(_slots[i], i),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () {
                          final slot = _freshSlot();
                          setState(() => _slots.add(slot));
                          _schedule(slot);
                        },
                        child: const Text('Tambah slot'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: widget.accent),
                onPressed: _billable > 0 ? _confirm : null,
                child: Text('OK · ${_slots.length} · $priceLabel'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _slotCard(_SlotDraft slot, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF26262C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('Slot ${index + 1}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              const Spacer(),
              if (_slots.length > 1)
                IconButton(
                  onPressed: () {
                    slot.timer?.cancel();
                    setState(() => _slots.remove(slot));
                  },
                  icon: const Icon(Icons.close, size: 18, color: Colors.white54),
                ),
            ],
          ),
          _stepper(
            label: 'Unit',
            value: slot.units,
            onDec: () => _setUnits(slot, slot.units - 1),
            onInc: () => _setUnits(slot, slot.units + 1),
          ),
          _stepper(
            label: 'Durasi',
            value: slot.durationQty,
            onDec: () => _setDuration(slot, slot.durationQty - 1),
            onInc: () => _setDuration(slot, slot.durationQty + 1),
          ),
          _whenRow('Mulai', guestReservationWhenLabel(slot.start, _unit), () => _pick(slot, start: true)),
          _whenRow('Selesai', guestReservationWhenLabel(slot.end, _unit), () => _pick(slot, start: false)),
          if (slot.unitsAvailable != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Unit left: ${slot.unitsAvailable}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ),
          if (widget.guestPicks) _objectTiles(slot),
        ],
      ),
    );
  }

  Widget _stepper({
    required String label,
    required int value,
    required VoidCallback onDec,
    required VoidCallback onInc,
  }) {
    return Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(color: Colors.white))),
        IconButton(onPressed: onDec, icon: const Icon(Icons.remove, color: Colors.white70, size: 18)),
        Text('$value', style: const TextStyle(color: Colors.white)),
        IconButton(onPressed: onInc, icon: const Icon(Icons.add, color: Colors.white70, size: 18)),
      ],
    );
  }

  Widget _whenRow(String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            SizedBox(width: 72, child: Text(label, style: const TextStyle(color: Colors.white70))),
            Expanded(child: Text(value, style: const TextStyle(color: Colors.white))),
          ],
        ),
      ),
    );
  }

  Widget _objectTiles(_SlotDraft slot) {
    final free = slot.freeObjectIds;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final object in _productObjects)
            _objectTile(slot, object, free),
        ],
      ),
    );
  }

  Widget _objectTile(_SlotDraft slot, Map<String, dynamic> object, Set<int>? free) {
    final id = (object['id'] as num?)?.toInt() ?? 0;
    final name = object['name']?.toString() ?? '';
    final known = free != null;
    final taken = known && !free.contains(id);
    final selected = slot.siteObjectId == id && id > 0;
    final picUrl = guestSitePicUrl(object['pic']?.toString() ?? '');
    return Opacity(
      opacity: taken ? 0.35 : 1,
      child: Material(
        color: selected ? widget.accent.withValues(alpha: 0.25) : const Color(0xFF27272A),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: taken
              ? null
              : () {
                  setState(() {
                    if (slot.siteObjectId == id) {
                      slot.siteObjectId = 0;
                      slot.objectName = '';
                    } else {
                      slot.siteObjectId = id;
                      slot.objectName = name;
                    }
                  });
                },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 96,
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                if (picUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(picUrl, height: 48, width: 80, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox(height: 48)),
                  ),
                Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 12)),
                if ((object['code']?.toString() ?? '').isNotEmpty)
                  Text(object['code'].toString(), style: const TextStyle(color: Colors.white54, fontSize: 10)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
