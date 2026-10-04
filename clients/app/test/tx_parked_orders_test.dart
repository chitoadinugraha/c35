import 'package:alienai_c35/c/pb/c35/tx.pb.dart';
import 'package:alienai_c35/widgets/sites/tx/dialog/transaksi_parked_dialog.dart';
import 'package:alienai_c35/widgets/sites/tx/tx_parked_orders.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TxParkedOrders', () {
    const siteIid = 101;
    final store = TxParkedOrders.instance;

    setUp(() {
      store.clear(siteIid);
    });

    test('add and list parked orders', () {
      final tx = Tx(
        siteIid: Int64(siteIid),
        items: [
          TxItem(productId: Int64(1), note: 'Item A', qty: 2, price: Int64(5000)),
        ],
      );

      expect(store.count(siteIid), 0);
      final parked = store.add(siteIid, tx, note: 'Customer in blue');
      expect(parked.note, 'Customer in blue');
      expect(parked.itemCount, 2);
      expect(parked.totalAmount, Int64(10000));
      expect(store.count(siteIid), 1);

      final list = store.list(siteIid);
      expect(list.length, 1);
      expect(list.first.id, parked.id);
    });

    test('default note is generated when note is omitted or empty', () {
      final tx = Tx(siteIid: Int64(siteIid));
      final p1 = store.add(siteIid, tx);
      final p2 = store.add(siteIid, tx, note: '   ');

      expect(p1.note, 'Order #1');
      expect(p2.note, 'Order #2');
    });

    test('remove and restore parked order', () {
      final tx = Tx(siteIid: Int64(siteIid));
      final p1 = store.add(siteIid, tx, note: 'Order A');

      expect(store.count(siteIid), 1);
      final removed = store.remove(siteIid, p1.id);
      expect(removed?.id, p1.id);
      expect(store.count(siteIid), 0);

      // Restore order back
      store.restore(siteIid, removed!);
      expect(store.count(siteIid), 1);
      expect(store.list(siteIid).first.id, p1.id);
    });

    test('clear removes all orders for given siteIid', () {
      final tx = Tx(siteIid: Int64(siteIid));
      store.add(siteIid, tx);
      store.add(siteIid, tx);
      expect(store.count(siteIid), 2);

      store.clear(siteIid);
      expect(store.count(siteIid), 0);
      expect(store.list(siteIid), isEmpty);
    });
  });

  group('formatTimeAgo', () {
    test('formats seconds as just now', () {
      final now = DateTime.now();
      expect(formatTimeAgo(now.subtract(const Duration(seconds: 10))), 'Just now');
    });

    test('formats minutes', () {
      final now = DateTime.now();
      expect(formatTimeAgo(now.subtract(const Duration(minutes: 5))), '5 mins ago');
      expect(formatTimeAgo(now.subtract(const Duration(minutes: 1))), '1 min ago');
    });

    test('formats hours and days', () {
      final now = DateTime.now();
      expect(formatTimeAgo(now.subtract(const Duration(hours: 3))), '3 hours ago');
      expect(formatTimeAgo(now.subtract(const Duration(days: 2))), '2 days ago');
    });
  });
}
