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

  testWidgets('UiTable expand row does not throw layout errors', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UiTable(
            def: TableDef(
              collection: 'test.items',
              label: 'Items',
              columns: [
                ColDef(key: 'name', label: 'Name'),
                ColDef(key: 'enabled', label: 'On', type: ColType.COL_TYPE_BOOL, inlineEditable: true),
              ],
            ),
            rows: [
              {'name': 'Apple', 'enabled': 'yes'},
            ],
            onCellCommit: (_, __, ___) async {},
            expandedBuilder: (rowKey) => Text('expanded:$rowKey'),
          ),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.expand_more));
    await tester.pumpAndSettle();
    expect(find.textContaining('expanded:'), findsOneWidget);
  });

  testWidgets('UiTable cellBuilder overrides a column', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UiTable(
            def: TableDef(
              collection: 'test.items',
              label: 'Items',
              columns: [
                ColDef(key: 'name', label: 'Name'),
                ColDef(key: 'badge', label: 'Badge'),
              ],
            ),
            rows: [
              {'name': 'Apple', 'badge': 'hot'},
            ],
            cellBuilder: (scope) => scope.col.key == 'badge' ? const Text('CUSTOM') : null,
          ),
        ),
      ),
    );
    expect(find.text('Apple'), findsOneWidget);
    expect(find.text('CUSTOM'), findsOneWidget);
    expect(find.text('hot'), findsNothing);
  });

  testWidgets('UiTable rowBuilder replaces default row', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UiTable(
            def: TableDef(
              collection: 'test.items',
              label: 'Items',
              columns: [
                ColDef(key: 'name', label: 'Name'),
              ],
            ),
            rows: [
              {'name': 'Apple'},
            ],
            rowBuilder: (scope) => [Text('row:${scope.rowKey}')],
          ),
        ),
      ),
    );
    expect(find.text('row:Apple'), findsOneWidget);
    expect(find.text('Apple'), findsNothing);
  });
}
