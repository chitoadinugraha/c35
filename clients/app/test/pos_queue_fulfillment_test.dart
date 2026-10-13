import 'package:alienai_c35/c/pb/c35/tx.pb.dart';
import 'package:alienai_c35/widgets/sites/tx/pos_queue/tx_queue_helpers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('payment confirm targets pending when fulfillment on', () {
    expect(
      txQueueStateAfterPaymentConfirm(orderFulfillment: true),
      TxState.TX_STATE_PENDING,
    );
  });

  test('payment confirm targets ok when fulfillment off', () {
    expect(
      txQueueStateAfterPaymentConfirm(orderFulfillment: false),
      TxState.TX_STATE_OK,
    );
  });
}
