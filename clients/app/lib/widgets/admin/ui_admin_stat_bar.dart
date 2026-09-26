import 'package:alienai_c35/c/admin/admin_format.dart';
import 'package:alienai_c35/widgets/admin/ui_admin_theme.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';

class UiAdminStatBar extends StatelessWidget {
  const UiAdminStatBar({
    super.key,
    required this.label,
    required this.detail,
    required this.pct,
    this.warnPct = 80,
    this.critPct = 90,
    this.dense = false,
  });

  final String label;
  final String detail;
  final double pct;
  final double warnPct;
  final double critPct;
  final bool dense;

  Color get _fill => pct >= critPct ? adminBarCrit : pct >= warnPct ? adminBarWarn : adminBarFill;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(vertical: dense ? 4 : 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(label, style: const TextStyle(color: adminText, fontSize: 13, fontWeight: FontWeight.w600)),
                const Spacer(),
                Text(detail, style: const TextStyle(color: adminMuted, fontSize: 11)),
                const SizedBox(width: 6),
                Text(adminFmtPct(pct), style: TextStyle(color: _fill, fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
            SizedBox(height: dense ? 4 : 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (pct / 100).clamp(0, 1),
                minHeight: dense ? 7 : 8,
                backgroundColor: adminBarBg,
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
            Expanded(child: Text(label, style: const TextStyle(color: adminText, fontSize: 13, fontWeight: FontWeight.w500))),
            Text('R ${adminFmtBps(readBps)}  W ${adminFmtBps(writeBps)}', style: const TextStyle(color: adminMuted, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(value: (ioPct / 100).clamp(0, 1), minHeight: 6, backgroundColor: adminBarBg, color: adminBarIn),
              ),
            ),
            const SizedBox(width: 12),
            Text('${adminFmtBytes(used)} / ${adminFmtBytes(total)}', style: const TextStyle(color: adminMuted, fontSize: 11)),
            const SizedBox(width: 8),
            SizedBox(
              width: 72,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: (pct / 100).clamp(0, 1),
                  minHeight: 6,
                  backgroundColor: adminBarBg,
                  color: pct >= 90 ? adminBarCrit : pct >= 80 ? adminBarWarn : adminBarFill,
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
