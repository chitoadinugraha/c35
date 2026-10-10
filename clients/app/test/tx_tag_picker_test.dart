import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/widgets/io/in_site_tx_tags.dart';
import 'package:alienai_c35/widgets/sites/tx/section_tx_items.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpPos(WidgetTester tester, {required GlobalKey<SectionTxItemsState> key}) async {
  final product = SiteProduct(productId: Int64(1), name: 'Kopi', price: Int64(15000), canSell: true);
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      startLocale: const Locale('en'),
      child: Builder(
        builder: (context) => MaterialApp(
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          home: Scaffold(
            body: SizedBox(
              height: 700,
              width: 900,
              child: SectionTxItems(
                key: key,
                items: const [],
                products: [product],
                onChanged: (_) {},
                posShell: true,
                onContactChanged: (_) {},
                payments: const [],
                onCheckout: () async {},
                onRemovePayment: (_) {},
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  test('normalizeTxTag strips hash and blank input', () {
    expect(normalizeTxTag('  #cashier1 '), 'cashier1');
    expect(normalizeTxTag('## cashier 2'), 'cashier 2');
    expect(normalizeTxTag('#'), isNull);
    expect(normalizeTxTag('   '), isNull);
  });

  testWidgets('tag button searches and creates a tag', (tester) async {
    final key = GlobalKey<SectionTxItemsState>();
    await _pumpPos(tester, key: key);

    expect(find.byKey(posTxTagsButtonKey), findsOneWidget);
    await tester.tap(find.byKey(posTxTagsButtonKey));
    await tester.pumpAndSettle();
    expect(find.text('No tags yet'), findsOneWidget);

    final tagSearch = find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.hintText == 'Search tag...',
    );
    await tester.enterText(tagSearch, 'cashier1');
    await tester.pump();
    expect(find.text('New tag'), findsOneWidget);
    await tester.tap(find.text('New tag'));
    await tester.pumpAndSettle();

    expect(find.text('cashier1'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);

    await tester.tap(find.text('cashier1'));
    await tester.pump();
    expect(find.byIcon(Icons.check), findsNothing);

    await tester.tap(find.text('cashier1'));
    await tester.pump();
    expect(find.byIcon(Icons.check), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    key.currentState!.clearTxTags();
    await tester.pump();

    await tester.tap(find.byKey(posTxTagsButtonKey));
    await tester.pumpAndSettle();
    expect(find.text('cashier1'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsNothing);
  });
}
