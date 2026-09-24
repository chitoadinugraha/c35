import 'package:alienai_c35/c/pb/c35/collection.pb.dart';
import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/widgets/ui/ui_col_cell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixnum/fixnum.dart';

Widget _cell({
  required ColDef col,
  String value = '',
  bool editable = false,
  UiColCellCommit? onCommit,
  UiColCellHost? host,
}) =>
    Builder(
      builder: (context) => uiColCellBuild(UiColCellScope(
        context: context,
        rowKey: 'r1',
        row: {col.key: value},
        col: col,
        value: value,
        editable: editable,
        onCommit: onCommit,
        host: host,
      )),
    );

void main() {
  test('refLabel resolves product and contact names', () {
    final host = UiColCellHost(
      products: {'42': SiteProduct(productId: Int64(42), name: 'Widget')},
      contacts: {'7': SiteContact(contactId: Int64(7), name: 'Alice')},
    );
    expect(host.refLabel(ColDef(type: ColType.COL_TYPE_REF, refCollection: 'site.product'), '42'), 'Widget');
    expect(host.refLabel(ColDef(type: ColType.COL_TYPE_REF, refCollection: 'site.contact'), '7'), 'Alice');
    expect(host.refLabel(ColDef(type: ColType.COL_TYPE_REF, refCollection: 'site.product'), '99'), '99');
  });

  testWidgets('bool cell renders switch when editable', (tester) async {
    var committed = '';
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: _cell(
          col: ColDef(key: 'on', type: ColType.COL_TYPE_BOOL),
          value: 'no',
          editable: true,
          onCommit: (v) async => committed = v,
        ),
      ),
    ));
    expect(find.byType(Switch), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(committed, 'yes');
  });

  testWidgets('ref read-only shows resolved label', (tester) async {
    final host = UiColCellHost(products: {'5': SiteProduct(productId: Int64(5), name: 'Coffee')});
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: _cell(
          col: ColDef(key: 'product_id', type: ColType.COL_TYPE_REF, refCollection: 'site.product'),
          value: '5',
          host: host,
        ),
      ),
    ));
    expect(find.text('Coffee'), findsOneWidget);
    expect(find.text('5'), findsNothing);
  });

  testWidgets('registry override replaces type builder', (tester) async {
    uiColCellRegister(ColType.COL_TYPE_INT, (scope) => const Text('INT_OVERRIDE'));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: _cell(col: ColDef(key: 'qty', type: ColType.COL_TYPE_INT), value: '3'),
      ),
    ));
    expect(find.text('INT_OVERRIDE'), findsOneWidget);
  });

  testWidgets('registry override replaces ref builder', (tester) async {
    uiColCellRegisterRef('test.custom', (scope) => const Text('CUSTOM_REF'));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: _cell(col: ColDef(key: 'x', type: ColType.COL_TYPE_REF, refCollection: 'test.custom'), value: '1'),
      ),
    ));
    expect(find.text('CUSTOM_REF'), findsOneWidget);
  });
}
