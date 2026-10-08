import 'package:alienai_c35/c/site/site_schedule.dart';
import 'package:alienai_c35/c/site/site_schedule_overlap.dart';

class SiteScheduleStatus {
  const SiteScheduleStatus({required this.open, required this.label});

  final bool open;
  final String label;
}

/// Site weekday 0=Mon … 6=Sun from local [now].
int siteScheduleDayFromDateTime(DateTime now) => (now.weekday + 6) % 7;

int siteScheduleNowWeekMin(DateTime now) =>
    siteScheduleWeekMin(siteScheduleDayFromDateTime(now), now.hour * 60 + now.minute);

/// Compact guest label: `Open` | `Open in 1 hour` | `Open next Friday`.
SiteScheduleStatus siteScheduleStatus(List<SiteScheduleSlot> slots, [DateTime? at]) {
  if (slots.isEmpty) return const SiteScheduleStatus(open: false, label: 'Closed');
  final nowMin = siteScheduleNowWeekMin(at ?? DateTime.now());
  final week = 7 * 1440;
  final ranges = <SiteMinuteRange>[
    for (final slot in slots)
      for (final r in siteScheduleSlotRanges(slot)) ...[r, (start: r.start + week, end: r.end + week)],
  ]..sort((a, b) => a.start.compareTo(b.start));

  for (final r in ranges) {
    if (nowMin >= r.start && nowMin < r.end) return const SiteScheduleStatus(open: true, label: 'Open');
  }

  SiteMinuteRange? next;
  for (final r in ranges) {
    if (r.start > nowMin) {
      next = r;
      break;
    }
  }
  if (next == null) return const SiteScheduleStatus(open: false, label: 'Closed');

  final delta = next.start - nowMin;
  if (delta < 24 * 60) {
    if (delta < 60) return SiteScheduleStatus(open: false, label: 'Open in ${delta < 1 ? 1 : delta} min');
    final h = (delta / 60).round().clamp(1, 23);
    return SiteScheduleStatus(open: false, label: h == 1 ? 'Open in 1 hour' : 'Open in $h hours');
  }
  return SiteScheduleStatus(open: false, label: 'Open next ${siteScheduleWeekdayLabelsLong[(next.start ~/ 1440) % 7]}');
}
