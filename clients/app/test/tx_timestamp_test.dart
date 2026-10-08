import 'package:alienai_c35/c/pb/c35/tx.pb.dart';
import 'package:alienai_c35/c/site/tx_format.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('POS transaction timestamp behavior', () {
    test('txNewSale starts with zero timeTsMs', () {
      final tx = txNewSale(100);
      expect(tx.timeTsMs, Int64.ZERO);
      expect(tx.siteIid, Int64(100));
      expect(tx.type, TxType.TX_TYPE_SALE);
    });

    test('first item stamps timeTsMs, subsequent items preserve it', () {
      final tx = txNewSale(100);
      expect(tx.timeTsMs, Int64.ZERO);

      // Simulate first item added
      final t1 = DateTime(2026, 10, 8, 10, 0).millisecondsSinceEpoch;
      final next1 = tx.clone();
      if (tx.txId <= Int64.ZERO && tx.items.isEmpty) {
        next1.timeTsMs = Int64(t1);
      }
      next1.items.add(TxItem(productId: Int64(1), price: Int64(10000), qty: 1));

      expect(next1.timeTsMs, Int64(t1));

      // Simulate second item added at a later time t2
      final t2 = DateTime(2026, 10, 8, 10, 5).millisecondsSinceEpoch;
      final next2 = next1.clone();
      if (next1.txId <= Int64.ZERO && next1.items.isEmpty) {
        next2.timeTsMs = Int64(t2);
      }
      next2.items.add(TxItem(productId: Int64(2), price: Int64(20000), qty: 1));

      // Original timestamp t1 is preserved!
      expect(next2.timeTsMs, Int64(t1));
    });

    test('clearing cart resets timeTsMs, re-adding stamps new time', () {
      final tx = txNewSale(100);
      final t1 = DateTime(2026, 10, 8, 10, 0).millisecondsSinceEpoch;

      final cartWithItem = tx.clone()
        ..timeTsMs = Int64(t1)
        ..items.add(TxItem(productId: Int64(1), price: Int64(10000), qty: 1));
      expect(cartWithItem.timeTsMs, Int64(t1));

      // Items cleared
      final emptyCart = cartWithItem.clone()..items.clear();
      if (cartWithItem.txId <= Int64.ZERO && emptyCart.items.isEmpty) {
        emptyCart.timeTsMs = Int64.ZERO;
      }
      expect(emptyCart.timeTsMs, Int64.ZERO);

      // Re-adding item at t3
      final t3 = DateTime(2026, 10, 8, 10, 15).millisecondsSinceEpoch;
      final newCart = emptyCart.clone();
      if (emptyCart.txId <= Int64.ZERO && emptyCart.items.isEmpty) {
        newCart.timeTsMs = Int64(t3);
      }
      newCart.items.add(TxItem(productId: Int64(3), price: Int64(15000), qty: 1));

      expect(newCart.timeTsMs, Int64(t3));
    });

    test('existing loaded order with txId preserves original timestamp', () {
      final tOriginal = DateTime(2026, 10, 7, 14, 0).millisecondsSinceEpoch;
      final existingTx = Tx(
        txId: Int64(9999),
        siteIid: Int64(100),
        timeTsMs: Int64(tOriginal),
        items: [TxItem(productId: Int64(1), price: Int64(5000), qty: 1)],
      );

      final tNow = DateTime(2026, 10, 8, 10, 0).millisecondsSinceEpoch;
      final next = existingTx.clone();
      // Only unsaved tx (txId <= 0) should have its timestamp modified
      if (existingTx.txId <= Int64.ZERO && existingTx.items.isEmpty) {
        next.timeTsMs = Int64(tNow);
      }
      next.items.add(TxItem(productId: Int64(2), price: Int64(7000), qty: 1));

      expect(next.timeTsMs, Int64(tOriginal));
    });
  });
}
