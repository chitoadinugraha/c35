import 'package:alienai_c35/widgets/ui/io_ask_items.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ioAskItemTile with actions invokes Edit callback', (tester) async {
    String? editedId;
    final item = IoAskItem(
      id: '42',
      title: 'Kopi Demo',
      subtitle: 'alienai.id/kopi-demo',
      icon: Icons.language_outlined,
      actions: [
        IoAskItemAction(label: 'Visit', onTap: () {}),
        IoAskItemAction(label: 'Edit', onTap: () => editedId = '42'),
        IoAskItemAction(label: 'POS', onTap: () {}),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(builder: (context) => ioAskItemTile(context, item)),
        ),
      ),
    );

    expect(find.text('Kopi Demo'), findsOneWidget);
    expect(find.text('alienai.id/kopi-demo'), findsOneWidget);

    await tester.tap(find.text('Edit'));
    await tester.pump();

    expect(editedId, '42');
  });
}
