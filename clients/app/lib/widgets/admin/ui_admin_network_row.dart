import 'package:alienai_c35/c/admin/admin_format.dart';
import 'package:alienai_c35/widgets/admin/ui_admin_stat_bar.dart';
import 'package:alienai_c35/widgets/admin/ui_admin_theme.dart';
import 'package:flutter/material.dart';

class UiAdminNetworkRow extends StatelessWidget {
  const UiAdminNetworkRow({
    super.key,
    required this.inBps,
    required this.outBps,
    required this.maxBps,
    this.interfaceLabel = 'Network',
    this.compact = true,
  });

  final double inBps;
  final double outBps;
  final double maxBps;
  final String interfaceLabel;
  final bool compact;

  double get _scale => maxBps < 1 ? 1 : maxBps;

  double _frac(double bps) => (bps / _scale).clamp(0, 1);

  @override
  Widget build(BuildContext context) {
    if (!compact) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _wideBar(label: 'In ${adminFmtBps(inBps)}', value: inBps / _scale, color: adminBarIn),
            const SizedBox(height: 8),
            _wideBar(label: 'Out ${adminFmtBps(outBps)}', value: outBps / _scale, color: adminBarOut),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: kAdminStatLabelWidth,
            child: Text(interfaceLabel, style: const TextStyle(color: adminText, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          SizedBox(
            width: kAdminStatDetailWidth,
            child: Row(
              children: [
                Icon(Icons.arrow_downward_rounded, size: 12, color: adminBarIn),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    adminFmtBps(inBps),
                    style: const TextStyle(color: adminMuted, fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _frac(inBps),
                      minHeight: 7,
                      backgroundColor: adminBarBg,
                      color: adminBarIn,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(Icons.arrow_upward_rounded, size: 13, color: adminBarOut),
                const SizedBox(width: 4),
                SizedBox(
                  width: 58,
                  child: Text(
                    adminFmtBps(outBps),
                    style: const TextStyle(color: adminMuted, fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _frac(outBps),
                      minHeight: 7,
                      backgroundColor: adminBarBg,
                      color: adminBarOut,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _wideBar({required String label, required double value, required Color color}) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: const TextStyle(color: adminText, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value.clamp(0, 1),
              minHeight: 8,
              backgroundColor: adminBarBg,
              color: color,
            ),
          ),
        ],
      );
}
