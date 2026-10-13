import 'package:alienai_c35/c/pb/c35/tx.pb.dart';
import 'package:alienai_c35/c/site/tx_format.dart';
import 'package:alienai_c35/widgets/sites/tx/pos_queue/pos_queue_mode.dart';
import 'package:alienai_c35/widgets/sites/tx/tx_parked_orders.dart';
import 'package:fixnum/fixnum.dart';

bool txQueueIsPaymentVerification(Tx tx) =>
    tx.type == TxType.TX_TYPE_SALE && tx.state == TxState.TX_STATE_WAITING_PAYMENT;

bool txQueueIsOpenOrder(Tx tx) {
  if (tx.type != TxType.TX_TYPE_SALE) return false;
  if (tx.state == TxState.TX_STATE_CANCELLED ||
      tx.state == TxState.TX_STATE_DRAFT ||
      tx.state == TxState.TX_STATE_WAITING_PAYMENT) {
    return false;
  }
  return tx.state == TxState.TX_STATE_PENDING;
}

TxState txQueueStateAfterPaymentConfirm({required bool orderFulfillment}) =>
    orderFulfillment ? TxState.TX_STATE_PENDING : TxState.TX_STATE_OK;

bool txQueueMatchesMode(Tx tx, PosQueueMode mode) => switch (mode) {
      PosQueueMode.paymentVerification => txQueueIsPaymentVerification(tx),
      PosQueueMode.orders => txQueueIsOpenOrder(tx),
    };

String txQueueCustomerLabel(Tx tx, {String walkInLabel = 'Walk-In'}) =>
    parkedTxCustomerLabel(tx, walkInLabel: walkInLabel);

String? txQueueFirstProofPath(Tx tx) {
  for (final p in tx.txData.proofs) {
    final t = p.trim();
    if (t.isNotEmpty) return t;
  }
  return null;
}

List<String> txPaymentProofPaths(Tx tx) {
  final out = <String>[];
  for (final p in tx.txData.proofs) {
    final t = p.trim();
    if (t.isNotEmpty) out.add(t);
  }
  return out;
}

DateTime? txQueuePlacedAt(Tx tx) {
  if (tx.timeTsMs <= Int64.ZERO) return null;
  return DateTime.fromMillisecondsSinceEpoch(tx.timeTsMs.toInt());
}

TxPaymentMethod txQueuePrimaryPaymentMethod(Tx tx) {
  if (tx.payments.isEmpty) return TxPaymentMethod.TX_PAYMENT_METHOD_UNSPECIFIED;
  return tx.payments.first.method;
}

String txQueuePaymentMethodLabel(Tx tx) =>
    txPaymentMethodLabel(txQueuePrimaryPaymentMethod(tx));

String txQueueFormatTimeAgo(DateTime dateTime) {
  final diff = DateTime.now().difference(dateTime);
  if (diff.inSeconds < 45) return 'Just now';
  if (diff.inMinutes < 60) {
    final mins = diff.inMinutes;
    return '$mins min${mins == 1 ? '' : 's'} ago';
  }
  if (diff.inHours < 24) {
    final hrs = diff.inHours;
    return '$hrs hour${hrs == 1 ? '' : 's'} ago';
  }
  final days = diff.inDays;
  return '$days day${days == 1 ? '' : 's'} ago';
}

String formatTimeAgo(DateTime dateTime) => txQueueFormatTimeAgo(dateTime);
