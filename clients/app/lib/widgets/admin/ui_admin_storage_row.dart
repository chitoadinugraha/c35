import 'package:alienai_c35/c/admin/admin_format.dart';
import 'package:alienai_c35/widgets/admin/ui_admin_stat_bar.dart';
import 'package:alienai_c35/widgets/admin/ui_admin_theme.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';

const double _diskIoScaleBps = 50 * 1024 * 1024;

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
    final role = label.isNotEmpty ? label : (isBoot ? 'Boot' : '');
    if (role.isNotEmpty && device.isNotEmpty) return '$device ($role)';
    if (device.isNotEmpty) return device;
    return role;
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
                      child: Text(_title, style: const TextStyle(color: adminText, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                    Text(adminFmtBytesPair(used, total), style: const TextStyle(color: adminMuted, fontSize: 10)),
                    const SizedBox(width: 4),
                    Text(adminFmtPct(pct), style: TextStyle(color: fill, fontSize: 10, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 4),
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
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                UiAdminIoBarRow(prefix: 'R', bps: readBps, scaleBps: _diskIoScaleBps, color: adminBarIn),
                const SizedBox(height: 5),
                UiAdminIoBarRow(prefix: 'W', bps: writeBps, scaleBps: _diskIoScaleBps, color: adminBarOut),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
