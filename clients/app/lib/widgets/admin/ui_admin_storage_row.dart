import 'package:alienai_c35/c/admin/admin_format.dart';
import 'package:alienai_c35/widgets/admin/ui_admin_theme.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';

const _diskIoScaleBps = 50 * 1024 * 1024;

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

  Color _fill(double pct) => pct >= 90 ? adminBarCrit : pct >= 80 ? adminBarWarn : adminBarFill;

  @override
  Widget build(BuildContext context) {
    final used = Int64(usedBytes);
    final total = Int64(totalBytes);
    final pct = adminPct(used, total);
    final fill = _fill(pct);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(_title, style: const TextStyle(color: adminText, fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                    Text('${adminFmtBytes(used)} / ${adminFmtBytes(total)}', style: const TextStyle(color: adminMuted, fontSize: 11)),
                    const SizedBox(width: 6),
                    Text(adminFmtPct(pct), style: TextStyle(color: fill, fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (pct / 100).clamp(0, 1),
                    minHeight: 7,
                    backgroundColor: adminBarBg,
                    color: fill,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(width: 104, child: _DiskIoColumn(readBps: readBps, writeBps: writeBps)),
        ],
      ),
    );
  }
}

class _DiskIoColumn extends StatelessWidget {
  const _DiskIoColumn({required this.readBps, required this.writeBps});

  final double readBps;
  final double writeBps;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DiskIoLine(label: 'R', bps: readBps, color: adminBarIn),
          const SizedBox(height: 6),
          _DiskIoLine(label: 'W', bps: writeBps, color: adminBarOut),
        ],
      );
}

class _DiskIoLine extends StatelessWidget {
  const _DiskIoLine({required this.label, required this.bps, required this.color});

  final String label;
  final double bps;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final frac = (bps / _diskIoScaleBps).clamp(0.0, 1.0);
    final showBar = bps > 0 && frac >= 0.02;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            SizedBox(
              width: 12,
              child: Text(label, style: const TextStyle(color: adminMuted, fontSize: 10, fontWeight: FontWeight.w600)),
            ),
            Expanded(
              child: Text(
                adminFmtBps(bps),
                style: const TextStyle(color: adminMuted, fontSize: 10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
        if (showBar) ...[
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(value: frac, minHeight: 4, backgroundColor: adminBarBg, color: color),
          ),
        ],
      ],
    );
  }
}
