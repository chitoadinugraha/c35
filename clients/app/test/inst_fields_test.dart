import 'package:alienai_c35/c/admin/inst_fields.dart';
import 'package:alienai_c35/c/field/field_col.dart';
import 'package:alienai_c35/c/pb/c35/collection.pb.dart';
import 'package:alienai_c35/c/pb/c35/field.pb.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fieldFromColDef maps bool type', () {
    final field = fieldFromColDef(ColDef(key: 'enabled', label: 'On', type: ColType.COL_TYPE_BOOL));
    expect(field.type, FieldType.FIELD_TYPE_BOOL);
    expect(field.key, 'enabled');
  });

  test('instApplyFilters matches scope kind and enabled', () {
    final rows = [
      {'scope': 'global', 'kind': 'task', 'enabled': 'yes'},
      {'scope': 'role:pa', 'kind': 'mention', 'enabled': 'no'},
    ];
    final filtered = instApplyFilters(rows, {'scope': 'global', 'enabled': 'yes'});
    expect(filtered.length, 1);
    expect(filtered.first['kind'], 'task');
  });
}
