import 'package:alienai_c35/c/admin/admin_format.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';

const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _barBg = Color(0xFF27272A);
const _barFill = Color(0xFF34D399);
const _barWarn = Color(0xFFFBBF24);
const _barCrit = Color(0xFFF87171);

class UiAdminStorageRow extends StatelessWidget {
  const UiAdminStorageRow({
    super.key,
    required this.device,
    required this.label,
    required this.usedBytes,
    required this.totalBytes,
    required this.readBps,
    required this.writeBps,
    this.isBoot = false,
  });

  final String device;
  final String label;
  final int usedBytes;
  final int totalBytes;
  final double readBps;
  final double writeBps;
  final bool isBoot;

  String get _title {
    if (isBoot) return '$device (${label.isNotEmpty ? label : 'boot'})';
    return device.isNotEmpty ? device : label;
  }

  Color _fill(double pct) => pct >= 90 ? _barCrit : pct >= 80 ? _barWarn : _barFill;

  @override
  Widget build(BuildContext context) {
    final used = Int64(usedBytes);
    final total = Int64(totalBytes);
    final pct = adminPct(used, total);
    final fill = _fill(pct);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(_title, style: const TextStyle(color: _text, fontSize: 13, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('${adminFmtBytes(used)} / ${adminFmtBytes(total)}', style: const TextStyle(color: _muted, fontSize: 12)),
              const SizedBox(width: 8),
              Text(adminFmtPct(pct), style: TextStyle(color: fill, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (pct / 100).clamp(0, 1),
              minHeight: 8,
              backgroundColor: _barBg,
              color: fill,
            ),
          ),
          const SizedBox(height: 4),
          Text('R ${adminFmtBps(readBps)}  W ${adminFmtBps(writeBps)}', style: const TextStyle(color: _muted, fontSize: 11)),
        ],
      ),
    );
  }
}
