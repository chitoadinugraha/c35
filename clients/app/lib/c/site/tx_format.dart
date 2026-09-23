import 'package:alienai_c35/c/pb/c35/tx.pb.dart';
import 'package:fixnum/fixnum.dart';

String txTypeLabel(TxType type) => switch (type) {
      TxType.TX_TYPE_SALE => 'Sale',
      TxType.TX_TYPE_PURCHASE => 'Purchase',
      TxType.TX_TYPE_TRANSFER => 'Transfer',
      TxType.TX_TYPE_ADJUSTMENT => 'Adjustment',
      TxType.TX_TYPE_RETURN_SALE => 'Return sale',
      TxType.TX_TYPE_RETURN_PURCHASE => 'Return purchase',
      TxType.TX_TYPE_RESERVATION => 'Reservation',
      TxType.TX_TYPE_SHIP => 'Ship',
      TxType.TX_TYPE_PAYMENT => 'Payment',
      TxType.TX_TYPE_RECEIPT => 'Receipt',
      TxType.TX_TYPE_DEBT_PAYABLE => 'Debt payable',
      TxType.TX_TYPE_DEBT_RECEIVABLE => 'Debt receivable',
      TxType.TX_TYPE_INVENTORY => 'Inventory',
      _ => '—',
    };

String txStateLabel(TxState state) => switch (state) {
      TxState.TX_STATE_OK => 'OK',
      TxState.TX_STATE_DRAFT => 'Draft',
      TxState.TX_STATE_PENDING => 'Pending',
      TxState.TX_STATE_WAITING_PAYMENT => 'Waiting payment',
      TxState.TX_STATE_CANCELLED => 'Cancelled',
      _ => '—',
    };

String txPaymentMethodLabel(TxPaymentMethod method) => switch (method) {
      TxPaymentMethod.TX_PAYMENT_METHOD_CASH => 'Cash',
      TxPaymentMethod.TX_PAYMENT_METHOD_CARD => 'Card',
      TxPaymentMethod.TX_PAYMENT_METHOD_TRANSFER => 'Transfer',
      TxPaymentMethod.TX_PAYMENT_METHOD_QRIS => 'QRIS',
      TxPaymentMethod.TX_PAYMENT_METHOD_DEBT => 'Debt',
      TxPaymentMethod.TX_PAYMENT_METHOD_WALLET => 'Wallet',
      _ => '—',
    };

Int64 txItemsNominal(Tx tx) => tx.items.fold(Int64.ZERO, (sum, item) => sum + Int64(item.qty) * item.price);

Int64 txPaymentsTotal(Tx tx) => tx.payments.fold(Int64.ZERO, (sum, p) => sum + p.amount);

Tx txNewSale(int siteIid) => Tx(
      siteIid: Int64(siteIid),
      type: TxType.TX_TYPE_SALE,
      state: TxState.TX_STATE_OK,
      inputMode: TxInputMode.TX_INPUT_MODE_SELL,
      inputSource: TxInputSource.TX_INPUT_SOURCE_MANUAL,
      timeTsMs: Int64(DateTime.now().millisecondsSinceEpoch),
    );

String? txValidateSale(Tx tx) {
  if (tx.items.isEmpty) return 'Add at least one item';
  for (final item in tx.items) {
    if (item.productId <= Int64.ZERO) return 'Select a product for each line';
    if (item.qty == 0) return 'Quantity cannot be zero';
  }
  final nominal = txItemsNominal(tx);
  if (tx.payments.isEmpty) return 'Add a payment';
  if (txPaymentsTotal(tx) != nominal) return 'Payment total must match items total';
  return null;
}

Tx txEnsureCashPayment(Tx tx) {
  final out = tx.clone();
  final nominal = txItemsNominal(out);
  if (nominal <= Int64.ZERO) return out;
  if (txPaymentsTotal(out) == nominal) return out;
  out.payments.clear();
  out.payments.add(TxPayment(
    method: TxPaymentMethod.TX_PAYMENT_METHOD_CASH,
    amount: nominal,
    tsMs: out.timeTsMs > Int64.ZERO ? out.timeTsMs : Int64(DateTime.now().millisecondsSinceEpoch),
  ));
  return out;
}
