import 'package:alienai_c35/c/pb/c35/field.pb.dart';

// MCP inst_list filters: scope, kind, enabled — keys match ai.inst columns.

List<Field> instFilterFields() => [
      Field(key: 'scope', label: 'Scope', type: FieldType.FIELD_TYPE_TEXT, optional: true),
      Field(key: 'kind', label: 'Kind', type: FieldType.FIELD_TYPE_TEXT, optional: true),
      Field(key: 'enabled', label: 'Enabled', type: FieldType.FIELD_TYPE_BOOL, optional: true),
    ];

/// Hidden row keys for expanded inst editor / future MCP field metadata.
List<Field> instTableFields() => [
      Field(key: '_inst', label: 'Instruction', type: FieldType.FIELD_TYPE_TEXT, group: 'hidden'),
      Field(key: '_triggers', label: 'Triggers', type: FieldType.FIELD_TYPE_TEXT, group: 'hidden'),
      Field(key: '_topic_id', label: 'Topic ID', type: FieldType.FIELD_TYPE_TEXT, group: 'hidden'),
    ];

List<Map<String, String>> instApplyFilters(List<Map<String, String>> rows, Map<String, String> filters) {
  final scope = filters['scope']?.trim().toLowerCase() ?? '';
  final kind = filters['kind']?.trim().toLowerCase() ?? '';
  final enabled = filters['enabled']?.trim().toLowerCase() ?? '';
  return rows
      .where((row) {
        if (scope.isNotEmpty && !(row['scope'] ?? '').toLowerCase().contains(scope)) return false;
        if (kind.isNotEmpty && !(row['kind'] ?? '').toLowerCase().contains(kind)) return false;
        if (enabled.isNotEmpty) {
          final on = (row['enabled'] ?? '').toLowerCase();
          final wantOn = enabled == 'yes' || enabled == '1' || enabled == 'true';
          final isOn = on == 'yes' || on == '1' || on == 'true';
          if (wantOn != isOn) return false;
        }
        return true;
      })
      .toList(growable: false);
}
