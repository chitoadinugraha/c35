import 'package:alienai_c35/c/pb/c35/site.pb.dart';

const siteObjectBatchMaxCount = 100;

const siteObjectKindRoom = 'room';
const siteObjectKindTable = 'table';
const siteObjectKindOther = 'other';

const siteObjectKindValues = [siteObjectKindRoom, siteObjectKindTable, siteObjectKindOther];

String siteObjectKindLabel(String kind) => switch (kind) {
      siteObjectKindTable => 'Table',
      siteObjectKindRoom => 'Room',
      _ => 'Other',
    };

String siteObjectCodeFromName(String name) {
  final base = name.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-+|-+$'), '');
  return base.isEmpty ? 'obj' : base;
}

/// Generate names `prefix` + padded number from [start]..[end] inclusive (max [siteObjectBatchMaxCount]).
List<({String name, String code})> siteObjectBatchPreview({
  required String prefix,
  required int start,
  required int end,
  int digits = 0,
}) {
  if (start <= 0 || end <= 0) return const [];
  final lo = start < end ? start : end;
  final hi = start > end ? start : end;
  if (hi - lo + 1 > siteObjectBatchMaxCount) return const [];
  final p = prefix;
  final out = <({String name, String code})>[];
  for (var n = lo; n <= hi; n++) {
    final num = digits > 0 ? n.toString().padLeft(digits, '0') : '$n';
    final name = '$p$num'.trim();
    if (name.isEmpty) continue;
    out.add((name: name, code: siteObjectCodeFromName(name)));
  }
  return out;
}

final _siteObjectNamePrefixRe = RegExp(r'^(.*?)[\s_-]*\d+\s*$');

/// Leading name before a trailing number (`Villa 01` -> `Villa`). Blank names are `Other`.
String siteObjectNamePrefix(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return 'Other';
  final match = _siteObjectNamePrefixRe.firstMatch(trimmed);
  if (match == null) return trimmed;
  final prefix = (match.group(1) ?? '').trim();
  if (prefix.isEmpty) return trimmed;
  return prefix;
}

/// Groups objects by kind (`room`, `table`, `other`, then any other kind) and name prefix.
List<({String kind, List<({String prefix, List<SiteObject> objs})> prefixes})> siteObjectsGroupByKindPrefix(
  Iterable<SiteObject> objs,
) {
  const preferred = [siteObjectKindRoom, siteObjectKindTable, siteObjectKindOther];
  final byKind = <String, Map<String, List<SiteObject>>>{};
  final seenKinds = <String>[];
  for (final obj in objs) {
    final kind = obj.kind;
    final prefixes = byKind.putIfAbsent(kind, () {
      seenKinds.add(kind);
      return <String, List<SiteObject>>{};
    });
    final prefix = siteObjectNamePrefix(obj.name);
    prefixes.putIfAbsent(prefix, () => <SiteObject>[]).add(obj);
  }

  final kinds = <String>[
    for (final kind in preferred)
      if (byKind.containsKey(kind)) kind,
    for (final kind in seenKinds)
      if (!preferred.contains(kind)) kind,
  ];

  return [
    for (final kind in kinds)
      (
        kind: kind,
        prefixes: () {
          final prefixes = byKind[kind]!;
          final names = prefixes.keys.toList()..sort();
          return [
            for (final prefix in names) (prefix: prefix, objs: prefixes[prefix]!),
          ];
        }(),
      ),
  ];
}
