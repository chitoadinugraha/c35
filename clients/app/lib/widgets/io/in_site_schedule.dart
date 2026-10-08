import 'package:alienai_c35/c/site/site_schedule.dart';
import 'package:alienai_c35/widgets/io/in_schedule_slots.dart';
import 'package:flutter/material.dart';

class InSiteSchedule extends StatelessWidget {
  const InSiteSchedule({super.key, required this.slots, required this.onChanged, this.label = 'Open hours'});

  final List<SiteScheduleSlot> slots;
  final ValueChanged<List<SiteScheduleSlot>> onChanged;
  final String label;

  void _add() => onChanged([...slots, siteScheduleSlotDefault()]);

  void _update(String id, {int? startDay, int? startMin, int? endDay, int? endMin}) {
    onChanged(slots.map((s) {
      if (s.id != id) return s;
      return s.copyWith(startDay: startDay, startMin: startMin, endDay: endDay, endMin: endMin);
    }).toList(growable: false));
  }

  void _remove(String id) => onChanged(slots.where((s) => s.id != id).toList(growable: false));

  @override
  Widget build(BuildContext context) => InScheduleSlots(
        label: label,
        slots: slots,
        onAdd: _add,
        onUpdate: _update,
        onRemove: _remove,
      );
}
