import 'package:alienai_c35/c/site/site_schedule.dart';
import 'package:alienai_c35/c/site/site_schedule_overlap.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_catalog_shared.dart';
import 'package:flutter/material.dart';

const inScheduleSlotDayW = 92.0;
const inScheduleSlotTimeW = 48.0;

class InScheduleSlots extends StatelessWidget {
  const InScheduleSlots({
    super.key,
    required this.slots,
    required this.onAdd,
    required this.onUpdate,
    required this.onRemove,
    this.label = 'Open hours',
  });

  final List<SiteScheduleSlot> slots;
  final VoidCallback onAdd;
  final void Function(String id, {int? startDay, int? startMin, int? endDay, int? endMin}) onUpdate;
  final ValueChanged<String> onRemove;
  final String label;

  @override
  Widget build(BuildContext context) {
    final sorted = siteScheduleSort(slots);
    final conflicts = siteScheduleSlotConflicts(sorted);
    final conflictIds = siteScheduleConflictIds(conflicts);
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600))),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add'),
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact, padding: const EdgeInsets.symmetric(horizontal: 8)),
            ),
          ],
        ),
        if (sorted.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 2),
            child: Text('No hours yet', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
          )
        else ...[
          for (final slot in sorted) ...[
            _SlotCard(
              slot: slot,
              conflict: conflictIds.contains(slot.id),
              onUpdate: onUpdate,
              onRemove: onRemove,
            ),
            const SizedBox(height: 4),
          ],
          if (conflicts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final c in conflicts)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        siteScheduleConflictLabel(c),
                        style: TextStyle(fontSize: 12, color: cs.error, height: 1.35),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

class _SlotCard extends StatelessWidget {
  const _SlotCard({required this.slot, required this.conflict, required this.onUpdate, required this.onRemove});

  final SiteScheduleSlot slot;
  final bool conflict;
  final void Function(String id, {int? startDay, int? startMin, int? endDay, int? endMin}) onUpdate;
  final ValueChanged<String> onRemove;

  Future<void> _pickDay(BuildContext context, RenderBox anchor, {required bool start}) async {
    final offset = anchor.localToGlobal(Offset.zero);
    final picked = await showMenu<int>(
      context: context,
      position: RelativeRect.fromLTRB(offset.dx, offset.dy + anchor.size.height + 2, offset.dx + anchor.size.width, offset.dy),
      items: [for (var d = 0; d < 7; d++) PopupMenuItem(value: d, child: Text(siteScheduleWeekdayLabelsLong[d]))],
    );
    if (picked == null) return;
    if (start) {
      final nextEndDay = slot.endDay == slot.startDay ? picked : slot.endDay;
      onUpdate(slot.id, startDay: picked, endDay: nextEndDay);
    } else {
      onUpdate(slot.id, endDay: picked);
    }
  }

  Future<void> _pickTime(BuildContext context, {required bool start}) async {
    final initial = TimeOfDay(hour: (start ? slot.startMin : slot.endMin) ~/ 60, minute: (start ? slot.startMin : slot.endMin) % 60);
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    final min = picked.hour * 60 + picked.minute;
    if (start) {
      final sd = slot.startDay;
      if (slot.endDay == sd && slot.endMin <= min) {
        onUpdate(slot.id, startMin: min, endDay: (sd + 1) % 7);
      } else if (slot.endDay == (sd + 1) % 7 && slot.endMin > min) {
        onUpdate(slot.id, startMin: min, endDay: sd);
      } else {
        onUpdate(slot.id, startMin: min);
      }
    } else if (min <= slot.startMin) {
      onUpdate(slot.id, endDay: (slot.startDay + 1) % 7, endMin: min);
    } else {
      onUpdate(slot.id, endDay: slot.startDay, endMin: min);
    }
  }

  void _openDayMenu(BuildContext context, {required bool start}) {
    final box = context.findRenderObject();
    if (box is! RenderBox) return;
    _pickDay(context, box, start: start);
  }

  Future<void> _confirmRemove(BuildContext context) async {
    final start = '${siteScheduleWeekdayLabelsLong[slot.startDay.clamp(0, 6)]} ${siteScheduleMinFormat(slot.startMin)}';
    final end = slot.endDay == slot.startDay
        ? siteScheduleMinFormat(slot.endMin)
        : '${siteScheduleWeekdayLabelsLong[slot.endDay.clamp(0, 6)]} ${siteScheduleMinFormat(slot.endMin)}';
    final ok = await siteCatalogConfirmDelete(
      context,
      title: 'Delete hour slot',
      body: '$start – $end (${siteScheduleDurationLabel(slot)})',
    );
    if (ok) onRemove(slot.id);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final chipBg = conflict ? cs.error.withValues(alpha: 0.22) : cs.surfaceContainerHighest.withValues(alpha: 0.55);
    final chipBorder = conflict ? cs.error.withValues(alpha: 0.35) : cs.outlineVariant.withValues(alpha: 0.3);
    final duration = siteScheduleDurationLabel(slot);
    final chipStyle = TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: cs.onSurface);
    final cardBg = conflict ? cs.error.withValues(alpha: 0.22) : cs.surfaceContainerHighest.withValues(alpha: 0.28);
    final cardBorder = conflict ? cs.error.withValues(alpha: 0.55) : cs.outlineVariant.withValues(alpha: 0.28);

    return Material(
      color: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 4, 2, 4),
        child: Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Builder(
                      builder: (ctx) => _ScheduleChip(
                        width: inScheduleSlotDayW,
                        align: Alignment.centerLeft,
                        bg: chipBg,
                        border: chipBorder,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        onTap: () => _openDayMenu(ctx, start: true),
                        child: Text(
                          siteScheduleWeekdayLabelsLong[slot.startDay.clamp(0, 6)],
                          style: chipStyle,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    _ScheduleChip(
                      width: inScheduleSlotTimeW,
                      bg: chipBg,
                      border: chipBorder,
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                      onTap: () => _pickTime(context, start: true),
                      child: Text(siteScheduleMinFormat(slot.startMin), style: chipStyle, textAlign: TextAlign.center),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 14,
                      height: 28,
                      child: Center(
                        child: Text('–', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: cs.onSurfaceVariant)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Builder(
                      builder: (ctx) => _ScheduleChip(
                        width: inScheduleSlotDayW,
                        align: Alignment.centerLeft,
                        bg: chipBg,
                        border: chipBorder,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        onTap: () => _openDayMenu(ctx, start: false),
                        child: Text(
                          siteScheduleWeekdayLabelsLong[slot.endDay.clamp(0, 6)],
                          style: chipStyle,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    _ScheduleChip(
                      width: inScheduleSlotTimeW,
                      bg: chipBg,
                      border: chipBorder,
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                      onTap: () => _pickTime(context, start: false),
                      child: Text(siteScheduleMinFormat(slot.endMin), style: chipStyle, textAlign: TextAlign.center),
                    ),
                    const SizedBox(width: 8),
                    Text('($duration)', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
            ),
            InkWell(
              onTap: () => _confirmRemove(context),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: Icon(Icons.close, size: 15, color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleChip extends StatelessWidget {
  const _ScheduleChip({
    required this.bg,
    required this.border,
    required this.child,
    this.onTap,
    this.width,
    this.align = Alignment.center,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  });

  final Color bg;
  final Color border;
  final Widget child;
  final VoidCallback? onTap;
  final double? width;
  final Alignment align;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final chip = Material(
      color: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7), side: BorderSide(color: border)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: padding,
          child: width == null ? child : Align(alignment: align, widthFactor: 1, child: child),
        ),
      ),
    );
    return width == null ? chip : SizedBox(width: width, child: chip);
  }
}
