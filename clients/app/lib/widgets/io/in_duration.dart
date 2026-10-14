import 'package:alienai_c35/widgets/io/in_money_idr.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_editor_form.dart';
import 'package:flutter/material.dart';

class InDurationPeriod {
  const InDurationPeriod({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String id;
  final String label;
  final IconData icon;
}

const inDurationPeriods = <InDurationPeriod>[
  InDurationPeriod(id: 'day', label: 'Day', icon: Icons.today_outlined),
  InDurationPeriod(id: 'week', label: 'Week', icon: Icons.date_range_outlined),
  InDurationPeriod(id: 'month', label: 'Month', icon: Icons.calendar_month_outlined),
  InDurationPeriod(id: 'year', label: 'Year', icon: Icons.event_outlined),
  InDurationPeriod(id: 'hour', label: 'Hour', icon: Icons.schedule_outlined),
  InDurationPeriod(id: 'minute', label: 'Minute', icon: Icons.timelapse_outlined),
  InDurationPeriod(id: 'second', label: 'Second', icon: Icons.timer_outlined),
];

InDurationPeriod inDurationPeriodOf(String id) {
  for (final p in inDurationPeriods) {
    if (p.id == id) return p;
  }
  return inDurationPeriods.first;
}

/// Duration value + period picker (CSA `InDuration` parity).
class InDuration extends StatelessWidget {
  const InDuration({
    super.key,
    required this.controller,
    required this.periodId,
    this.labelText = 'Per',
    this.hintText = '1',
    this.enabled = true,
    this.onValueChanged,
    this.onPeriodChanged,
  });

  final TextEditingController controller;
  final String periodId;
  final String? labelText;
  final String? hintText;
  final bool enabled;
  final ValueChanged<String>? onValueChanged;
  final ValueChanged<String>? onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    final period = inDurationPeriodOf(periodId);
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.number,
      inputFormatters: moneyIdrInputFormatters,
      textAlign: TextAlign.right,
      onChanged: onValueChanged,
      style: const TextStyle(color: siteEditorFormText, fontSize: 13, fontFeatures: [FontFeature.tabularFigures()]),
      decoration: siteEditorInputDecoration(hintText: hintText, suffixText: period.label).copyWith(
        labelText: labelText,
        labelStyle: const TextStyle(color: siteEditorFormMuted, fontSize: 12),
        suffixIcon: onPeriodChanged == null
            ? null
            : PopupMenuButton<String>(
                tooltip: 'Period',
                enabled: enabled,
                onSelected: onPeriodChanged,
                itemBuilder: (ctx) => [
                  for (final opt in inDurationPeriods)
                    PopupMenuItem(
                      value: opt.id,
                      child: Row(
                        children: [
                          Icon(opt.icon, size: 18, color: siteEditorFormMuted),
                          const SizedBox(width: 10),
                          Text(opt.label, style: const TextStyle(color: siteEditorFormText)),
                        ],
                      ),
                    ),
                ],
                child: const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.expand_more, size: 20, color: siteEditorFormMuted),
                ),
              ),
      ),
    );
  }
}
