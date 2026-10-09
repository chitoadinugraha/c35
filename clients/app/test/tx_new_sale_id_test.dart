import 'package:alienai_c35/c/pb/c35/tx.pb.dart';
import 'package:alienai_c35/c/site/tx_format.dart';
import 'package:alienai_c35/widgets/sites/tx/tx_offline_queue.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('txEnsureClientTxId assigns snowflake txId for new sale', () async {
    final tx = txNewSale(42);
    expect(tx.txId, Int64.ZERO);
    await TxOfflineQueue.txEnsureClientTxId(tx);
    expect(tx.txId > Int64.ZERO, isTrue);
    final before = tx.txId;
    await TxOfflineQueue.txEnsureClientTxId(tx);
    expect(tx.txId, before);
  });
}
