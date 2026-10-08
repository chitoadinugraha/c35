import 'dart:convert';

class SiteScheduleSlot {
  const SiteScheduleSlot({
    required this.id,
    this.startDay = 0,
    this.startMin = 9 * 60,
    this.endDay = 0,
    this.endMin = 17 * 60,
  });

  final String id;
  final int startDay;
  final int startMin;
  final int endDay;
  final int endMin;

  SiteScheduleSlot copyWith({int? startDay, int? startMin, int? endDay, int? endMin}) => SiteScheduleSlot(
        id: id,
        startDay: startDay ?? this.startDay,
        startMin: startMin ?? this.startMin,
        endDay: endDay ?? this.endDay,
        endMin: endMin ?? this.endMin,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'startDay': startDay,
        'startMin': startMin,
        'endDay': endDay,
        'endMin': endMin,
      };

  static SiteScheduleSlot fromJson(Map<String, dynamic> m) => SiteScheduleSlot(
        id: m['id']?.toString() ?? '',
        startDay: (m['startDay'] as num?)?.toInt() ?? 0,
        startMin: (m['startMin'] as num?)?.toInt() ?? 9 * 60,
        endDay: (m['endDay'] as num?)?.toInt() ?? 0,
        endMin: (m['endMin'] as num?)?.toInt() ?? 17 * 60,
      );
}

const siteScheduleWeekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String siteScheduleSlotNewId() => 'slot-${DateTime.now().millisecondsSinceEpoch}';

SiteScheduleSlot siteScheduleSlotDefault() => SiteScheduleSlot(id: siteScheduleSlotNewId());

String siteScheduleMinFormat(int min) {
  final h = (min ~/ 60).clamp(0, 23);
  final m = (min % 60).clamp(0, 59);
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}

String siteScheduleSlotPreview(SiteScheduleSlot slot) {
  final start = '${siteScheduleWeekdayLabels[slot.startDay.clamp(0, 6)]} ${siteScheduleMinFormat(slot.startMin)}';
  final end = slot.endDay == slot.startDay
      ? siteScheduleMinFormat(slot.endMin)
      : '${siteScheduleWeekdayLabels[slot.endDay.clamp(0, 6)]} ${siteScheduleMinFormat(slot.endMin)}';
  return '$start – $end';
}

List<SiteScheduleSlot> siteScheduleSort(List<SiteScheduleSlot> slots) => [...slots]
  ..sort((a, b) => (a.startDay * 1440 + a.startMin).compareTo(b.startDay * 1440 + b.startMin));

List<SiteScheduleSlot> siteScheduleSlotsFromMetaJson(String metaJson) {
  final map = _metaMap(metaJson);
  final raw = map['open_hours'];
  if (raw is! List) return [];
  return raw.whereType<Map>().map((e) => SiteScheduleSlot.fromJson(e.map((k, v) => MapEntry(k.toString(), v)))).toList(growable: false);
}

List<Map<String, dynamic>> siteScheduleSlotsToHoursRows(List<SiteScheduleSlot> slots) => siteScheduleSort(slots)
    .map((s) => {
          'day': siteScheduleSlotPreview(s),
          'open': siteScheduleMinFormat(s.startMin),
          'close': siteScheduleMinFormat(s.endMin),
        })
    .toList(growable: false);

Map<String, dynamic> _metaMap(String metaJson) {
  if (metaJson.trim().isEmpty) return {};
  try {
    final decoded = jsonDecode(metaJson);
    return decoded is Map<String, dynamic> ? decoded : {};
  } catch (_) {
    return {};
  }
}
