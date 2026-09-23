import 'package:alienai_c35/c/admin/admin_format.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';

const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _barBg = Color(0xFF27272A);
const _barFill = Color(0xFF34D399);
const _barWarn = Color(0xFFFBBF24);
const _barCrit = Color(0xFFF87171);

class UiAdminStatBar extends StatelessWidget {
  const UiAdminStatBar({
    super.key,
    required this.label,
    required this.detail,
    required this.pct,
    this.warnPct = 80,
    this.critPct = 90,
  });

  final String label;
  final String detail;
  final double pct;
  final double warnPct;
  final double critPct;

  Color get _fill => pct >= critPct ? _barCrit : pct >= warnPct ? _barWarn : _barFill;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(label, style: const TextStyle(color: _text, fontSize: 13, fontWeight: FontWeight.w600)),
                const Spacer(),
                Text(detail, style: const TextStyle(color: _muted, fontSize: 12)),
                const SizedBox(width: 8),
                Text(adminFmtPct(pct), style: TextStyle(color: _fill, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (pct / 100).clamp(0, 1),
                minHeight: 8,
                backgroundColor: _barBg,
                color: _fill,
              ),
            ),
          ],
        ),
      );
}

class UiAdminMountRow extends StatelessWidget {
  const UiAdminMountRow({
    super.key,
    required this.label,
    required this.usedBytes,
    required this.totalBytes,
    required this.readBps,
    required this.writeBps,
  });

  final String label;
  final int usedBytes;
  final int totalBytes;
  final double readBps;
  final double writeBps;

  @override
  Widget build(BuildContext context) {
    final used = Int64(usedBytes);
    final total = Int64(totalBytes);
    final pct = adminPct(used, total);
    final ioPct = ((readBps + writeBps) / (50 * 1024 * 1024)).clamp(0, 1) * 100;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(color: _text, fontSize: 13, fontWeight: FontWeight.w500))),
            Text('R ${adminFmtBps(readBps)}  W ${adminFmtBps(writeBps)}', style: const TextStyle(color: _muted, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(value: (ioPct / 100).clamp(0, 1), minHeight: 6, backgroundColor: _barBg, color: const Color(0xFF60A5FA)),
              ),
            ),
            const SizedBox(width: 12),
            Text('${adminFmtBytes(used)} / ${adminFmtBytes(total)}', style: const TextStyle(color: _muted, fontSize: 11)),
            const SizedBox(width: 8),
            SizedBox(
              width: 72,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: (pct / 100).clamp(0, 1),
                  minHeight: 6,
                  backgroundColor: _barBg,
                  color: pct >= 90 ? _barCrit : pct >= 80 ? _barWarn : _barFill,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
