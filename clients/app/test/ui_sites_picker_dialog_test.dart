import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/widgets/sites/ui_sites_picker_dialog.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('UiSitesPickerRows renders sites and Edit invokes callback', (tester) async {
    String? editedId;
    final rows = [
      SiteRow(siteIid: Int64(42), alienId: 'kopi-demo', name: 'Kopi Demo'),
      SiteRow(siteIid: Int64(99), alienId: 'bakery', name: 'Bakery'),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UiSitesPickerRows(
            rows: rows,
            api: SiteApi(ChatConn()),
            onVisit: (_) {},
            onEdit: (id) => editedId = id,
            onPos: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Kopi Demo'), findsOneWidget);
    expect(find.text('alienai.id/kopi-demo'), findsOneWidget);
    expect(find.text('Bakery'), findsOneWidget);

    await tester.tap(find.text('Edit').first);
    await tester.pump();

    expect(editedId, '42');
  });
}
