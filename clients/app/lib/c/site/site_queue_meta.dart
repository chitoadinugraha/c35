import 'dart:convert';

import 'package:alienai_c35/c/pb/c35/site.pb.dart';

/// Guest field definitions and queue extras stored in [SiteQueue.metaJson].
class SiteQueueFieldDef {
  const SiteQueueFieldDef({
    required this.id,
    required this.label,
    this.type = 'text',
    this.required = false,
  });

  final String id;
  final String label;
  final String type;
  final bool required;

  SiteQueueFieldDef copyWith({String? label, String? type, bool? required}) => SiteQueueFieldDef(
        id: id,
        label: label ?? this.label,
        type: type ?? this.type,
        required: required ?? this.required,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'type': type,
        'required': required,
      };

  static SiteQueueFieldDef fromJson(Map<String, dynamic> j) {
    final type = (j['type'] as String?)?.trim().toLowerCase() ?? 'text';
    return SiteQueueFieldDef(
      id: (j['id'] as String?)?.trim() ?? '',
      label: (j['label'] as String?)?.trim() ?? '',
      type: type == 'phone' ? 'phone' : 'text',
      required: j['required'] == true,
    );
  }
}

class SiteQueueMeta {
  const SiteQueueMeta({
    this.description = '',
    this.takeOnline = true,
    this.sortOrder = 0,
    this.resetDaily = true,
    this.fields = const [],
  });

  final String description;
  final bool takeOnline;
  final int sortOrder;
  final bool resetDaily;
  final List<SiteQueueFieldDef> fields;

  SiteQueueMeta copyWith({
    String? description,
    bool? takeOnline,
    int? sortOrder,
    bool? resetDaily,
    List<SiteQueueFieldDef>? fields,
  }) =>
      SiteQueueMeta(
        description: description ?? this.description,
        takeOnline: takeOnline ?? this.takeOnline,
        sortOrder: sortOrder ?? this.sortOrder,
        resetDaily: resetDaily ?? this.resetDaily,
        fields: fields ?? this.fields,
      );

  static SiteQueueMeta parse(String metaJson) {
    if (metaJson.trim().isEmpty) return const SiteQueueMeta();
    try {
      final decoded = jsonDecode(metaJson);
      if (decoded is! Map) return const SiteQueueMeta();
      final map = Map<String, dynamic>.from(decoded);
      final resetPolicy = map['reset_policy'];
      var resetDaily = true;
      if (resetPolicy is Map) {
        final mode = (resetPolicy['mode'] as String?)?.trim().toLowerCase();
        if (mode == 'manual') resetDaily = false;
      } else if (map['reset_daily'] == false) {
        resetDaily = false;
      }
      final rawFields = map['fields'];
      final fields = <SiteQueueFieldDef>[];
      if (rawFields is List) {
        for (final item in rawFields) {
          if (item is Map) {
            final f = SiteQueueFieldDef.fromJson(Map<String, dynamic>.from(item));
            if (f.id.isNotEmpty && f.label.isNotEmpty) fields.add(f);
          }
        }
      }
      return SiteQueueMeta(
        description: (map['description'] as String?)?.trim() ?? '',
        takeOnline: map['take_online'] != false,
        sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
        resetDaily: resetDaily,
        fields: fields,
      );
    } catch (_) {
      return const SiteQueueMeta();
    }
  }

  String encode({Map<String, dynamic>? preserve}) {
    final base = preserve != null ? Map<String, dynamic>.from(preserve) : <String, dynamic>{};
    base['description'] = description;
    base['take_online'] = takeOnline;
    base['sort_order'] = sortOrder;
    base['reset_policy'] = resetDaily ? {'mode': 'daily'} : {'mode': 'manual'};
    base['fields'] = fields.map((f) => f.toJson()).toList();
    return jsonEncode(base);
  }
}

SiteQueueMeta siteQueueMetaOf(SiteQueue queue) => SiteQueueMeta.parse(queue.metaJson);

void siteQueueApplyMeta(SiteQueue queue, SiteQueueMeta meta) {
  Map<String, dynamic>? preserve;
  final raw = queue.metaJson.trim();
  if (raw.isNotEmpty) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) preserve = Map<String, dynamic>.from(decoded);
    } catch (_) {}
  }
  queue.metaJson = meta.encode(preserve: preserve);
}

int siteQueueSortOrder(SiteQueue queue) => siteQueueMetaOf(queue).sortOrder;

List<SiteQueue> siteQueuesSorted(List<SiteQueue> items) {
  final copy = [...items];
  copy.sort((a, b) {
    final sa = siteQueueSortOrder(a);
    final sb = siteQueueSortOrder(b);
    if (sa != sb) return sa.compareTo(sb);
    return a.queueId.compareTo(b.queueId);
  });
  return copy;
}

String siteQueueTicketPreview(SiteQueue queue, {int ticketNo = 1}) {
  final prefix = queue.prefix.trim().toUpperCase();
  final num = ticketNo.toString().padLeft(3, '0');
  return prefix.isEmpty ? num : '$prefix-$num';
}
