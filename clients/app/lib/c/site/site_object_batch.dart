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
