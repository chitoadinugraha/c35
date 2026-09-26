import 'package:alienai_c35/c/admin/admin_format.dart';
import 'package:alienai_c35/widgets/admin/ui_admin_theme.dart';
import 'package:flutter/material.dart';

class UiAdminNetworkRow extends StatelessWidget {
  const UiAdminNetworkRow({
    super.key,
    required this.inBps,
    required this.outBps,
    required this.maxBps,
    this.compact = true,
  });

  final double inBps;
  final double outBps;
  final double maxBps;
  final bool compact;

  double get _scale => maxBps < 1 ? 1 : maxBps;

  bool _showBar(double bps) {
    final frac = bps / _scale;
    return bps > 0 && frac >= 0.08;
  }

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
      padding: const EdgeInsets.only(top: 2, bottom: 4),
      child: Row(
        children: [
          _compactChip(icon: Icons.arrow_downward_rounded, label: adminFmtBps(inBps), color: adminBarIn, showBar: _showBar(inBps), frac: inBps / _scale),
          const SizedBox(width: 16),
          _compactChip(icon: Icons.arrow_upward_rounded, label: adminFmtBps(outBps), color: adminBarOut, showBar: _showBar(outBps), frac: outBps / _scale),
        ],
      ),
    );
  }

  Widget _compactChip({
    required IconData icon,
    required String label,
    required Color color,
    required bool showBar,
    required double frac,
  }) =>
      Expanded(
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(label, style: const TextStyle(color: adminText, fontSize: 12, fontWeight: FontWeight.w500)),
                  if (showBar) ...[
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: frac.clamp(0, 1),
                        minHeight: 4,
                        backgroundColor: adminBarBg,
                        color: color,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );

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
