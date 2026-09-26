import 'package:alienai_c35/c/admin/admin_format.dart';
import 'package:alienai_c35/widgets/admin/ui_admin_theme.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';

class UiAdminNodeCard extends StatelessWidget {
  const UiAdminNodeCard({
    super.key,
    required this.nodeName,
    required this.cpuPct,
    required this.cpuCores,
    required this.memUsed,
    required this.memTotal,
    this.storagePct,
    this.storageLabel = 'sda',
    this.tsMs,
    required this.selected,
    required this.expanded,
    required this.onTap,
    this.expandedBody,
  });

  final String nodeName;
  final double cpuPct;
  final int cpuCores;
  final Int64 memUsed;
  final Int64 memTotal;
  final double? storagePct;
  final String storageLabel;
  final Int64? tsMs;
  final bool selected;
  final bool expanded;
  final VoidCallback onTap;
  final Widget? expandedBody;

  bool get _healthOk {
    final ts = tsMs?.toInt();
    if (ts == null || ts <= 0) return false;
    return DateTime.now().millisecondsSinceEpoch - ts < 60000;
  }

  static const _muted = adminMuted;
  static const _text = adminText;
  static const _panel = adminPanel;
  static const _border = adminBorder;
  static const _accent = adminAccent;
  static const _healthDotOk = adminHealthOk;
  static const _healthDotStale = adminHealthStale;

  String get _summary {
    final memPct = adminPct(memUsed, memTotal).round();
    final cpu = cpuPct.clamp(0, 100).round();
    final parts = ['CPU $cpu%', 'RAM $memPct%'];
    if (storagePct != null) parts.add('$storageLabel ${storagePct!.clamp(0, 100).round()}%');
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: _panel,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: selected ? _accent : _border, width: selected ? 1.5 : 1),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (expanded)
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _healthOk ? _healthDotOk : _healthDotStale,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            nodeName,
                            style: const TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (cpuCores > 0)
                          Text('$cpuCores cores', style: const TextStyle(color: _muted, fontSize: 11)),
                      ],
                    )
                  else
                    Text(_summary, style: const TextStyle(color: _text, fontSize: 13)),
                  if (expanded && expandedBody != null) ...[
                    const SizedBox(height: 12),
                    expandedBody!,
                  ],
                ],
              ),
            ),
          ),
        ),
      );
}
