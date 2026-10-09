import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/widgets/sites/tx/section_tx_items.dart';
import 'package:alienai_c35/widgets/sites/tx/ui_site_product_thumb.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('pos shell wide layout shows inline cart pay footer', (tester) async {
    final product = SiteProduct(productId: Int64(1), name: 'Kopi', price: Int64(15000), canSell: true);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 700,
            width: 900,
            child: SectionTxItems(
              items: const [],
              products: [product],
              onChanged: (_) {},
              posShell: true,
              payments: const [],
              onCheckout: () async {},
              onRemovePayment: (_) {},
            ),
          ),
        ),
      ),
    );
    expect(find.text('Total'), findsOneWidget);
    expect(find.text('Cari produk / scan barcode'), findsOneWidget);
  });

  testWidgets('pos shell narrow layout hides inline cart', (tester) async {
    final product = SiteProduct(productId: Int64(1), name: 'Kopi', price: Int64(15000), canSell: true);
    final key = GlobalKey<SectionTxItemsState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 700,
            width: 400,
            child: SectionTxItems(
              key: key,
              items: const [],
              products: [product],
              onChanged: (_) {},
              posShell: true,
              payments: const [],
              onCheckout: () async {},
              onRemovePayment: (_) {},
            ),
          ),
        ),
      ),
    );
    expect(find.text('Total'), findsNothing);
    expect(find.text('Cari produk / scan barcode'), findsOneWidget);
    key.currentState!.openCartDrawer();
    await tester.pumpAndSettle();
    expect(find.text('Total'), findsOneWidget);
    expect(find.text('Keranjang'), findsOneWidget);
  });

  testWidgets('product thumb shows fallback icon when pic empty', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UiSiteProductThumb(product: SiteProduct(productId: Int64(1), name: 'X', canSell: true)),
        ),
      ),
    );
    expect(find.byType(UiSiteProductThumb), findsOneWidget);
  });
}
