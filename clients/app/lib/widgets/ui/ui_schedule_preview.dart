import 'package:alienai_c35/c/site/site_color.dart';
import 'package:alienai_c35/c/site/site_schedule.dart';
import 'package:alienai_c35/c/site/site_schedule_overlap.dart';
import 'package:flutter/material.dart';

const uiSchedulePreviewHourW = 44.0;
const uiSchedulePreviewDayLabelW = 32.0;

class UiSchedulePreviewEntry {
  const UiSchedulePreviewEntry({
    required this.id,
    required this.name,
    required this.color,
    required this.slots,
    required this.enabled,
  });

  final String id;
  final String name;
  final String color;
  final List<SiteScheduleSlot> slots;
  final bool enabled;
}

class UiSchedulePreview extends StatefulWidget {
  const UiSchedulePreview({
    super.key,
    required this.entries,
    this.onToggle,
    this.label = 'Work shifts',
  });

  final List<UiSchedulePreviewEntry> entries;
  final ValueChanged<String>? onToggle;
  final String label;

  @override
  State<UiSchedulePreview> createState() => _UiSchedulePreviewState();
}

class _UiSchedulePreviewState extends State<UiSchedulePreview> {
  var _collapsed = false;

  List<UiSchedulePreviewEntry> get _enabled => widget.entries.where((e) => e.enabled).toList();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final enabled = _enabled;
    final allSlots = enabled.expand((e) => e.slots).toList();
    final bounds = siteScheduleSlotsBounds(allSlots);
    final shiftSlots = {for (final e in enabled) e.id: e.slots};
    final collisionDays = siteScheduleCollisionDays(shiftSlots);
    final daysByShift = siteScheduleDaysByShift(shiftSlots);
    final border = cs.outlineVariant.withValues(alpha: 0.35);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(widget.label, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600))),
            IconButton(
              tooltip: _collapsed ? 'Expand schedule' : 'Collapse schedule',
              visualDensity: VisualDensity.compact,
              onPressed: () => setState(() => _collapsed = !_collapsed),
              icon: Icon(_collapsed ? Icons.unfold_more : Icons.unfold_less, size: 18),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            for (final e in widget.entries)
              _LegendItem(
                entry: e,
                onToggle: widget.onToggle == null ? null : () => widget.onToggle!(e.id),
              ),
          ],
        ),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(12),
            color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: _collapsed
                ? _CollapsedDays(entries: enabled, daysByShift: daysByShift, collisionDays: collisionDays, cs: cs)
                : enabled.isEmpty
                    ? Text('No shifts selected', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant))
                    : _ScheduleGrid(entries: enabled, bounds: bounds, cs: cs),
          ),
        ),
      ],
    );
  }
}

class _CollapsedDays extends StatelessWidget {
  const _CollapsedDays({
    required this.entries,
    required this.daysByShift,
    required this.collisionDays,
    required this.cs,
  });

  final List<UiSchedulePreviewEntry> entries;
  final Map<int, List<String>> daysByShift;
  final Set<int> collisionDays;
  final ColorScheme cs;

  Color _shiftColor(String shiftId) {
    final e = entries.firstWhere((x) => x.id == shiftId, orElse: () => entries.first);
    return siteColorParse(e.color);
  }

  @override
  Widget build(BuildContext context) => Row(
        children: [
          for (var day = 0; day < 7; day++)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: day < 6 ? 4 : 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  decoration: BoxDecoration(
                    color: collisionDays.contains(day) ? Colors.red.shade600 : cs.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        siteScheduleWeekdayLabels[day],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: collisionDays.contains(day) ? Colors.white : cs.onSurfaceVariant,
                        ),
                      ),
                      if ((daysByShift[day] ?? []).isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          alignment: WrapAlignment.center,
                          children: [
                            for (final shiftId in daysByShift[day]!)
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: _shiftColor(shiftId),
                                  borderRadius: BorderRadius.circular(3),
                                  border: collisionDays.contains(day) ? Border.all(color: Colors.white, width: 1) : null,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
}

class _ScheduleGrid extends StatelessWidget {
  const _ScheduleGrid({required this.entries, required this.bounds, required this.cs});

  final List<UiSchedulePreviewEntry> entries;
  final ({int startMin, int endMin}) bounds;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final hours = [for (var m = bounds.startMin; m < bounds.endMin; m += 60) m];
    final gridW = hours.length * uiSchedulePreviewHourW;
    final pxPerMin = uiSchedulePreviewHourW / 60;
    final daySegments = <int, List<SiteDaySegment>>{
      for (var d = 0; d < 7; d++) d: entries.expand((e) => siteScheduleDaySegments(e.id, e.slots).where((s) => s.day == d)).toList(),
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: uiSchedulePreviewDayLabelW,
          child: Column(
            children: [
              const SizedBox(height: 14),
              for (var day = 0; day < 7; day++) ...[
                SizedBox(
                  height: 22,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(siteScheduleWeekdayLabels[day], style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
                  ),
                ),
                if (day < 6) Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.2)),
              ],
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: gridW,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      for (final h in hours)
                        SizedBox(
                          width: uiSchedulePreviewHourW,
                          child: Text(
                            siteScheduleMinFormat(h),
                            style: TextStyle(fontSize: 9, color: cs.onSurfaceVariant),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.35)),
                  for (var day = 0; day < 7; day++) ...[
                    _DayRow(
                      day: day,
                      segments: daySegments[day] ?? const [],
                      entries: entries,
                      bounds: bounds,
                      pxPerMin: pxPerMin,
                      cs: cs,
                    ),
                    if (day < 6) Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.2)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.day,
    required this.segments,
    required this.entries,
    required this.bounds,
    required this.pxPerMin,
    required this.cs,
  });

  final int day;
  final List<SiteDaySegment> segments;
  final List<UiSchedulePreviewEntry> entries;
  final ({int startMin, int endMin}) bounds;
  final double pxPerMin;
  final ColorScheme cs;

  Color _shiftColor(String shiftId) {
    final e = entries.firstWhere((x) => x.id == shiftId, orElse: () => entries.first);
    return siteColorParse(e.color);
  }

  @override
  Widget build(BuildContext context) {
    final overlaps = siteScheduleDayOverlaps(segments);
    return SizedBox(
      height: 22,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final seg in segments)
            _bar(
              left: (seg.start - bounds.startMin) * pxPerMin,
              width: (seg.end - seg.start) * pxPerMin,
              color: _shiftColor(seg.shiftId).withValues(alpha: 0.55),
            ),
          for (final o in overlaps)
            _bar(
              left: (o.start - bounds.startMin) * pxPerMin,
              width: (o.end - o.start) * pxPerMin,
              color: Colors.red.shade500,
            ),
        ],
      ),
    );
  }

  Widget _bar({required double left, required double width, required Color color}) => Positioned(
        left: left.clamp(0, double.infinity),
        width: width.clamp(1, double.infinity),
        top: 3,
        bottom: 3,
        child: DecoratedBox(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
      );
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.entry, this.onToggle});

  final UiSchedulePreviewEntry entry;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final color = siteColorParse(entry.color);
    final name = entry.name.trim().isNotEmpty ? entry.name.trim() : 'Unnamed shift';
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onToggle != null)
              SizedBox(
                width: 28,
                height: 28,
                child: Checkbox(value: entry.enabled, visualDensity: VisualDensity.compact, onChanged: (_) => onToggle?.call()),
              ),
            Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 6),
            Text(name, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface)),
          ],
        ),
      ),
    );
  }
}
