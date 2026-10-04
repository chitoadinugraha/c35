import 'package:alienai_c35/c/pb/c35/tx.pb.dart';
import 'package:alienai_c35/c/site/tx_format.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TxDiscount calculations in tx_format', () {
    test('txItemDiscountNominal returns totalDiscount or zero', () {
      final itemZero = TxItem(productId: Int64(1), price: Int64(10000), qty: 1);
      expect(txItemDiscountNominal(itemZero), Int64.ZERO);

      final itemWithDisc = TxItem(
        productId: Int64(1),
        price: Int64(10000),
        qty: 1,
        totalDiscount: Int64(2000),
      );
      expect(txItemDiscountNominal(itemWithDisc), Int64(2000));
    });

    test('txItemLineNet calculates net line price clamped to zero', () {
      final item = TxItem(
        productId: Int64(1),
        price: Int64(10000),
        qty: 2,
        totalDiscount: Int64(5000),
      );
      // gross = 2 * 10000 = 20000, discount = 5000 -> net = 15000
      expect(txItemLineNominal(item), Int64(20000));
      expect(txItemLineNet(item), Int64(15000));

      final itemOverDiscount = TxItem(
        productId: Int64(1),
        price: Int64(10000),
        qty: 1,
        totalDiscount: Int64(15000),
      );
      expect(txItemLineNet(itemOverDiscount), Int64.ZERO);
    });

    test('txCartDiscountsTotal sums discounts on tx', () {
      final tx = Tx(
        discounts: [
          TxDiscount(discountType: 'fixed', amount: Int64(5000)),
          TxDiscount(discountType: 'percent', amount: Int64(10000)),
        ],
      );
      expect(txCartDiscountsTotal(tx), Int64(15000));
    });

    test('txItemsNominal accounts for both item discounts and cart discounts', () {
      final tx = Tx(
        items: [
          TxItem(
            productId: Int64(1),
            price: Int64(20000),
            qty: 1,
            totalDiscount: Int64(2000), // net 18000
          ),
          TxItem(
            productId: Int64(2),
            price: Int64(30000),
            qty: 1,
            totalDiscount: Int64(5000), // net 25000
          ),
        ],
        discounts: [
          TxDiscount(discountType: 'fixed', amount: Int64(3000)), // cart discount
        ],
      );

      // items gross: 20000 + 30000 = 50000
      // items discount: 2000 + 5000 = 7000
      // items net: 18000 + 25000 = 43000
      // cart discount: 3000
      // tx total net: 43000 - 3000 = 40000
      expect(txItemsGrossNominal(tx), Int64(50000));
      expect(txItemsDiscountNominal(tx), Int64(7000));
      expect(txTotalDiscounts(tx), Int64(10000));
      expect(txItemsNominal(tx), Int64(40000));
    });

    test('txValidateSale validates sale with discounts', () {
      final tx = Tx(
        items: [
          TxItem(productId: Int64(1), price: Int64(10000), qty: 1, totalDiscount: Int64(2000)),
        ],
      );
      // Net is 8000, but no payment
      expect(txValidateSale(tx), 'Add a payment');

      tx.payments.add(TxPayment(amount: Int64(10000)));
      expect(txValidateSale(tx), 'Payment total must match items total');

      tx.payments[0].amount = Int64(8000);
      expect(txValidateSale(tx), isNull);
    });

    test('txEnsureCashPayment automatically sets cash payment to discounted nominal', () {
      final tx = Tx(
        items: [
          TxItem(productId: Int64(1), price: Int64(50000), qty: 1, totalDiscount: Int64(10000)),
        ],
        discounts: [
          TxDiscount(amount: Int64(5000)),
        ],
      );

      final prepared = txEnsureCashPayment(tx);
      // Net: 50000 - 10000 - 5000 = 35000
      expect(prepared.total, Int64(35000));
      expect(prepared.totalDiscounts, Int64(15000));
      expect(prepared.payments.length, 1);
      expect(prepared.payments.first.amount, Int64(35000));
      expect(prepared.payments.first.method, TxPaymentMethod.TX_PAYMENT_METHOD_CASH);
      expect(prepared.items.first.totalNet, Int64(40000));
    });
  });
}
