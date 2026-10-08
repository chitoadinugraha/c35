import 'package:alienai_c35/c/site/site_schedule.dart';
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
  Widget build(BuildContext context) {
    final sorted = siteScheduleSort(slots);
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
            TextButton.icon(onPressed: _add, icon: const Icon(Icons.add, size: 16), label: const Text('Add')),
          ],
        ),
        if (sorted.isEmpty)
          Text('No hours yet', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12))
        else
          for (final slot in sorted) ...[
            _SlotRow(slot: slot, onUpdate: _update, onRemove: () => _remove(slot.id)),
            const SizedBox(height: 6),
          ],
      ],
    );
  }
}

class _SlotRow extends StatelessWidget {
  const _SlotRow({required this.slot, required this.onUpdate, required this.onRemove});

  final SiteScheduleSlot slot;
  final void Function(String id, {int? startDay, int? startMin, int? endDay, int? endMin}) onUpdate;
  final VoidCallback onRemove;

  Future<void> _pickDay(BuildContext context, {required bool start}) async {
    final picked = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(start ? 'Start day' : 'End day'),
        children: [for (var d = 0; d < 7; d++) SimpleDialogOption(onPressed: () => Navigator.pop(ctx, d), child: Text(siteScheduleWeekdayLabels[d]))],
      ),
    );
    if (picked == null) return;
    if (start) {
      onUpdate(slot.id, startDay: picked, endDay: slot.endDay == slot.startDay ? picked : slot.endDay);
    } else {
      onUpdate(slot.id, endDay: picked);
    }
  }

  Future<void> _pickTime(BuildContext context, {required bool start}) async {
    final min = start ? slot.startMin : slot.endMin;
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay(hour: min ~/ 60, minute: min % 60));
    if (picked == null) return;
    final v = picked.hour * 60 + picked.minute;
    if (start) {
      onUpdate(slot.id, startMin: v);
    } else {
      onUpdate(slot.id, endMin: v);
    }
  }

  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: Text(siteScheduleSlotPreview(slot), style: const TextStyle(fontSize: 12))),
                  IconButton(onPressed: onRemove, icon: const Icon(Icons.close, size: 18)),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  OutlinedButton(onPressed: () => _pickDay(context, start: true), child: Text(siteScheduleWeekdayLabels[slot.startDay.clamp(0, 6)])),
                  OutlinedButton(onPressed: () => _pickTime(context, start: true), child: Text(siteScheduleMinFormat(slot.startMin))),
                  const Text('–'),
                  OutlinedButton(onPressed: () => _pickDay(context, start: false), child: Text(siteScheduleWeekdayLabels[slot.endDay.clamp(0, 6)])),
                  OutlinedButton(onPressed: () => _pickTime(context, start: false), child: Text(siteScheduleMinFormat(slot.endMin))),
                ],
              ),
            ],
          ),
        ),
      );
}
