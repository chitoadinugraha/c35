import 'package:alienai_c35/c/site/site_schedule.dart';
import 'package:alienai_c35/c/site/site_schedule_overlap.dart';

class SiteScheduleDaySummary {
  const SiteScheduleDaySummary({required this.day, required this.label, required this.times});

  final int day;
  final String label;
  final List<String> times;
}

List<SiteScheduleDaySummary> siteScheduleSummarizeByDay(List<SiteScheduleSlot> slots) {
  final buckets = List<List<List<int>>>.generate(7, (_) => []);

  for (final slot in slots) {
    for (final seg in siteScheduleSlotSegments(slot)) {
      buckets[seg.day].add([seg.start, seg.end]);
    }
  }

  return [
    for (var day = 0; day < 7; day++)
      if (buckets[day].isNotEmpty)
        SiteScheduleDaySummary(
          day: day,
          label: siteScheduleWeekdayLabels[day],
          times: (buckets[day]..sort((a, b) => a[0].compareTo(b[0])))
              .map((r) => '${siteScheduleMinFormat(r[0])}–${siteScheduleMinFormat(r[1])} (${siteScheduleMinsDurationLabel(r[1] - r[0])})')
              .toList(),
        ),
  ];
}

({List<SiteScheduleDaySummary> left, List<SiteScheduleDaySummary> right}) siteScheduleSummarySplit(
  List<SiteScheduleSlot> slots,
) {
  final rows = siteScheduleSummarizeByDay(slots);
  final left = rows.where((r) => r.day <= 3).toList();
  final right = rows.where((r) => r.day >= 4).toList();
  if (left.isEmpty && right.isNotEmpty) return (left: right, right: []);
  return (left: left, right: right);
}
