import 'package:alienai_c35/c/site/site_schedule.dart';

typedef SiteMinuteRange = ({int start, int end});
typedef SiteSlotSegment = ({int day, int start, int end});

/// Expands a slot into per-day segments. Multi-day slots (endDay > startDay) repeat startMin–endMin on each day.
List<SiteSlotSegment> siteScheduleSlotSegments(SiteScheduleSlot slot) {
  final sd = slot.startDay.clamp(0, 6);
  final ed = slot.endDay.clamp(0, 6);
  final sm = slot.startMin.clamp(0, 1439);
  final em = slot.endMin.clamp(0, 1439);

  if (ed > sd && em > sm) {
    return [for (var d = sd; d <= ed; d++) (day: d, start: sm, end: em)];
  }

  if (ed == sd) {
    if (em > sm) return [(day: sd, start: sm, end: em)];
    if (em < sm) {
      return [
        (day: sd, start: sm, end: 1440),
        (day: (sd + 1) % 7, start: 0, end: em),
      ];
    }
    return [];
  }

  final start = siteScheduleWeekMin(sd, sm);
  var end = siteScheduleWeekMin(ed, em);
  if (end <= start) end += 7 * 1440;
  final out = <SiteSlotSegment>[];
  var pos = start;
  while (pos < end) {
    final day = (pos ~/ 1440) % 7;
    final dayBase = day * 1440;
    final segStart = pos - dayBase;
    final segEnd = (end < dayBase + 1440 ? end : dayBase + 1440) - dayBase;
    if (segEnd > segStart) out.add((day: day, start: segStart, end: segEnd));
    pos = dayBase + 1440;
  }
  return out;
}

List<SiteMinuteRange> siteScheduleSlotRanges(SiteScheduleSlot slot) =>
    siteScheduleSlotSegments(slot).map((s) => (start: s.day * 1440 + s.start, end: s.day * 1440 + s.end)).toList();

class SiteDaySegment {
  const SiteDaySegment({required this.day, required this.start, required this.end, required this.shiftId});

  final int day;
  final int start;
  final int end;
  final String shiftId;
}

List<SiteDaySegment> siteScheduleDaySegments(String shiftId, List<SiteScheduleSlot> slots) => [
      for (final slot in slots)
        for (final seg in siteScheduleSlotSegments(slot))
          SiteDaySegment(day: seg.day, start: seg.start, end: seg.end, shiftId: shiftId),
    ];

List<SiteMinuteRange> siteScheduleDayOverlaps(List<SiteDaySegment> segments) {
  final overlaps = <SiteMinuteRange>[];
  for (var i = 0; i < segments.length; i++) {
    for (var j = i + 1; j < segments.length; j++) {
      final a = segments[i];
      final b = segments[j];
      if (a.day != b.day || a.shiftId == b.shiftId) continue;
      final start = a.start > b.start ? a.start : b.start;
      final end = a.end < b.end ? a.end : b.end;
      if (start < end) overlaps.add((start: start, end: end));
    }
  }
  return _mergeMinuteRanges(overlaps);
}

List<SiteMinuteRange> _mergeMinuteRanges(List<SiteMinuteRange> ranges) {
  if (ranges.isEmpty) return [];
  final sorted = [...ranges]..sort((a, b) => a.start.compareTo(b.start));
  final out = <SiteMinuteRange>[sorted.first];
  for (var i = 1; i < sorted.length; i++) {
    final last = out.last;
    final cur = sorted[i];
    if (cur.start <= last.end) {
      out[out.length - 1] = (start: last.start, end: cur.end > last.end ? cur.end : last.end);
    } else {
      out.add(cur);
    }
  }
  return out;
}

Set<int> siteScheduleCollisionDays(Map<String, List<SiteScheduleSlot>> shiftSlots) {
  final all = <SiteDaySegment>[];
  for (final e in shiftSlots.entries) {
    all.addAll(siteScheduleDaySegments(e.key, e.value));
  }
  final days = <int>{};
  for (var day = 0; day < 7; day++) {
    final daySegs = all.where((s) => s.day == day).toList();
    if (siteScheduleDayOverlaps(daySegs).isNotEmpty) days.add(day);
  }
  return days;
}

Map<int, List<String>> siteScheduleDaysByShift(Map<String, List<SiteScheduleSlot>> shiftSlots) {
  final out = <int, List<String>>{for (var d = 0; d < 7; d++) d: []};
  for (final e in shiftSlots.entries) {
    for (final seg in siteScheduleDaySegments(e.key, e.value)) {
      if (!out[seg.day]!.contains(e.key)) out[seg.day]!.add(e.key);
    }
  }
  return out;
}

({int startMin, int endMin}) siteScheduleSlotsBounds(List<SiteScheduleSlot> slots) {
  final segs = slots.expand(siteScheduleSlotSegments).toList();
  if (segs.isEmpty) return (startMin: 8 * 60, endMin: 18 * 60);
  var min = segs.first.start;
  var max = segs.first.end;
  for (final s in segs.skip(1)) {
    if (s.start < min) min = s.start;
    if (s.end > max) max = s.end;
  }
  final startHour = (min ~/ 60).clamp(0, 23);
  final endHour = ((max + 59) ~/ 60).clamp(startHour + 1, 24);
  return (startMin: startHour * 60, endMin: endHour * 60);
}

bool _siteMinuteRangesOverlap(List<SiteMinuteRange> a, List<SiteMinuteRange> b) {
  for (final ra in a) {
    for (final rb in b) {
      if (ra.start < rb.end && rb.start < ra.end) return true;
    }
  }
  return false;
}

/// True when two slots share any open interval (wraps week for overnight edges).
bool siteScheduleSlotsOverlap(SiteScheduleSlot a, SiteScheduleSlot b) {
  final week = 7 * 1440;
  final ar = siteScheduleSlotRanges(a);
  final br = siteScheduleSlotRanges(b);
  final brExt = [...br, for (final r in br) (start: r.start + week, end: r.end + week)];
  return _siteMinuteRangesOverlap(ar, brExt);
}

class SiteScheduleSlotConflict {
  const SiteScheduleSlotConflict({required this.a, required this.b, required this.indexA, required this.indexB});

  final SiteScheduleSlot a;
  final SiteScheduleSlot b;
  final int indexA;
  final int indexB;
}

/// Pairwise overlaps within [slots] (display order). Indexes are 1-based.
List<SiteScheduleSlotConflict> siteScheduleSlotConflicts(List<SiteScheduleSlot> slots) {
  final out = <SiteScheduleSlotConflict>[];
  for (var i = 0; i < slots.length; i++) {
    for (var j = i + 1; j < slots.length; j++) {
      if (siteScheduleSlotsOverlap(slots[i], slots[j])) {
        out.add(SiteScheduleSlotConflict(a: slots[i], b: slots[j], indexA: i + 1, indexB: j + 1));
      }
    }
  }
  return out;
}

Set<String> siteScheduleConflictIds(List<SiteScheduleSlotConflict> conflicts) => {
      for (final c in conflicts) ...[c.a.id, c.b.id],
    };

String siteScheduleConflictLabel(SiteScheduleSlotConflict c) {
  String brief(SiteScheduleSlot s) {
    final start = '${siteScheduleWeekdayLabels[s.startDay.clamp(0, 6)]} ${siteScheduleMinFormat(s.startMin)}';
    final end = s.endDay == s.startDay
        ? siteScheduleMinFormat(s.endMin)
        : '${siteScheduleWeekdayLabels[s.endDay.clamp(0, 6)]} ${siteScheduleMinFormat(s.endMin)}';
    return '$start – $end';
  }

  return '#${c.indexA} ${brief(c.a)} conflicts with #${c.indexB} ${brief(c.b)}';
}
