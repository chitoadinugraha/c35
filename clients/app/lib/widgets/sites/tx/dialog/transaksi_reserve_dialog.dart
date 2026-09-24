import 'package:alienai_c35/c/pb/c35/tx.pb.dart';
import 'package:alienai_c35/widgets/sites/tx/dialog/transaksi_reserve_utils.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';

const _border = Color(0xFF27272A);
const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _accent = Color(0xFF34D399);

Future<TxItemReservation?> showTransaksiReserveDialog({
  required BuildContext context,
  required String productName,
  TxItemReservation? initial,
}) =>
    showDialog<TxItemReservation>(
      context: context,
      builder: (ctx) => _DialogReserve(
        productName: productName,
        initial: initial,
      ),
    );

class _DialogReserve extends StatefulWidget {
  const _DialogReserve({required this.productName, this.initial});

  final String productName;
  final TxItemReservation? initial;

  @override
  State<_DialogReserve> createState() => _DialogReserveState();
}

class _DialogReserveState extends State<_DialogReserve> {
  late DateTime _start;
  late DateTime _end;
  var _unit = ReserveTimeUnit.hours;
  late int _qty = widget.initial != null && widget.initial!.qty > 0 ? widget.initial!.qty : 1;
  late final TextEditingController _noteCtrl = TextEditingController(text: widget.initial?.note ?? '');

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    if (widget.initial != null && widget.initial!.startTsMs > Int64.ZERO) {
      _start = DateTime.fromMillisecondsSinceEpoch(widget.initial!.startTsMs.toInt());
    } else {
      _start = DateTime(now.year, now.month, now.day, now.hour, 0);
    }
    if (widget.initial != null && widget.initial!.endTsMs > Int64.ZERO) {
      _end = DateTime.fromMillisecondsSinceEpoch(widget.initial!.endTsMs.toInt());
    } else {
      _end = _start.add(const Duration(hours: 1));
    }
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime(bool isStart) async {
    final current = isStart ? _start : _end;
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (time == null || !mounted) return;

    final chosen = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isStart) {
        _start = chosen;
        if (!_end.isAfter(_start)) {
          _end = _start.add(Duration(hours: _unit == ReserveTimeUnit.days ? 24 : 1));
        }
      } else {
        _end = chosen.isAfter(_start) ? chosen : _start.add(const Duration(hours: 1));
      }
    });
  }

  TxItemReservation _build() {
    final duration = calculateDurationQty(_start, _end, _unit);
    return TxItemReservation(
      startTsMs: Int64(_start.millisecondsSinceEpoch),
      endTsMs: Int64(_end.millisecondsSinceEpoch),
      qty: _qty,
      durationQty: duration,
      note: _noteCtrl.text.trim(),
      state: 'pending',
    );
  }

  @override
  Widget build(BuildContext context) {
    final duration = calculateDurationQty(_start, _end, _unit);
    final unitLabel = reserveTimeUnitLabel(_unit);
    return AlertDialog(
      backgroundColor: const Color(0xFF121215),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _border),
      ),
      title: Row(
        children: [
          const Icon(Icons.event_seat_outlined, color: _accent, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Reservasi: ${widget.productName}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 340,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Unit selection
              Row(
                children: [
                  for (final u in ReserveTimeUnit.values)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: ChoiceChip(
                          selected: _unit == u,
                          label: Text(reserveTimeUnitLabel(u)),
                          labelStyle: TextStyle(
                            color: _unit == u ? const Color(0xFF052E1B) : _text,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          selectedColor: _accent,
                          backgroundColor: const Color(0xFF18181B),
                          side: BorderSide(color: _unit == u ? _accent : _border),
                          onSelected: (sel) {
                            if (sel) setState(() => _unit = u);
                          },
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),

              // Date/time pickers
              _timeBox('Mulai (Check-in)', _start, () => _pickDateTime(true)),
              const SizedBox(height: 8),
              _timeBox('Selesai (Check-out)', _end, () => _pickDateTime(false)),
              const SizedBox(height: 12),

              // Calculated summary box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _accent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Durasi Terhitung', style: TextStyle(color: _muted, fontSize: 13)),
                    Text('$duration $unitLabel', style: const TextStyle(color: _accent, fontSize: 15, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Capacity / Qty
              Row(
                children: [
                  const Text('Kapasitas / Unit:', style: TextStyle(color: _muted, fontSize: 13)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: _muted, size: 20),
                    onPressed: _qty > 1 ? () => setState(() => _qty--) : null,
                  ),
                  Text('$_qty', style: const TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: _accent, size: 20),
                    onPressed: () => setState(() => _qty++),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Note
              TextField(
                controller: _noteCtrl,
                style: const TextStyle(color: _text, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Nomor Meja / Kamar / Catatan',
                  labelStyle: const TextStyle(color: _muted, fontSize: 12),
                  filled: true,
                  fillColor: const Color(0xFF18181B),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _accent)),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal', style: TextStyle(color: _muted)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _accent, foregroundColor: const Color(0xFF052E1B)),
          onPressed: () => Navigator.of(context).pop(_build()),
          child: const Text('Terapkan', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _timeBox(String label, DateTime dt, VoidCallback onTap) {
    final str = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF18181B),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: _muted, fontSize: 12)),
            Row(
              children: [
                Text(str, style: const TextStyle(color: _text, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(width: 6),
                const Icon(Icons.edit_calendar_outlined, size: 16, color: _accent),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
