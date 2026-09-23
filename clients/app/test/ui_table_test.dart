import 'package:alienai_c35/c/pb/c35/collection.pb.dart';
import 'package:alienai_c35/c/site/site_table_rows.dart';
import 'package:alienai_c35/widgets/ui/ui_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uiTableFilterRows matches any column', () {
    final rows = [
      {'name': 'Apple', 'sku': 'A1'},
      {'name': 'Banana', 'sku': 'B2'},
    ];
    final cols = [
      ColDef(key: 'name', label: 'Name'),
      ColDef(key: 'sku', label: 'SKU'),
    ];
    final filtered = uiTableFilterRows(rows, 'ban', cols);
    expect(filtered.length, 1);
    expect(filtered.first['name'], 'Banana');
  });

  test('uiTableSortRows sorts ascending and descending', () {
    final rows = [
      {'name': 'Zed'},
      {'name': 'Amy'},
    ];
    final asc = uiTableSortRows(rows, 'name');
    expect(asc.first['name'], 'Amy');
    final desc = uiTableSortRows(rows, 'name', ascending: false);
    expect(desc.first['name'], 'Zed');
  });

  test('siteRowKey joins primary key columns', () {
    final def = TableDef(collection: 'site.product', primaryKey: 'site_iid,product_id');
    final key = siteRowKey(def, {'site_iid': '1', 'product_id': '99', 'name': 'X'});
    expect(key, '1|99');
  });

  testWidgets('UiTable renders header and row cells', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UiTable(
            def: TableDef(
              collection: 'test.items',
              label: 'Items',
              columns: [
                ColDef(key: 'name', label: 'Name', inlineEditable: true),
                ColDef(key: 'sku', label: 'SKU', inlineEditable: true),
              ],
            ),
            rows: [
              {'name': 'Apple', 'sku': 'A1'},
            ],
          ),
        ),
      ),
    );
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('SKU'), findsOneWidget);
    expect(find.text('Apple'), findsOneWidget);
  });
}
