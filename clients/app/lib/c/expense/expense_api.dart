import 'dart:convert';

import 'package:alienai_c35/c/api/referral_conn.dart';
import 'package:alienai_c35/c/expense/expense_receipt.dart';
import 'package:alienai_c35/c/pb/c35/tx.pb.dart';
import 'package:alienai_c35/c/pb/c35/wire.pb.dart';
import 'package:fixnum/fixnum.dart';
import 'package:uuid/uuid.dart';

class ExpenseApi {
  ExpenseApi({ReferralConn? conn}) : _conn = conn ?? ReferralConn();

  final ReferralConn _conn;

  Future<Map<String, dynamic>> update({
    required int txId,
    required List<ExpenseItemRow> items,
    String locale = 'id-ID',
  }) async {
    final res = await _conn.invoke(
      InvokeReq(
        reqId: const Uuid().v4(),
        expensePut: ReqExpensePut(
          txId: Int64(txId),
          items: items
              .map(
                (e) => ExpenseItemInput(
                  name: e.name,
                  nameId: e.nameId,
                  qty: e.qty,
                  priceMinor: Int64(e.priceMinor),
                  totalMinor: Int64(e.totalMinor),
                  objId: Int64(e.objId),
                ),
              )
              .toList(),
        ),
      ),
    );
    invokeResThrow(res, fallback: 'expense update failed');
    if (!res.hasExpensePut()) return const {};
    final put = res.expensePut;
    final raw = put.blocksJson.trim();
    if (raw.isEmpty || raw == '[]') return const {};
    final arr = jsonDecode(raw) as List<dynamic>;
    if (arr.isEmpty) return const {};
    final block = arr.first;
    if (block is Map<String, dynamic>) return {'block': block};
    return {'block': Map<String, dynamic>.from(block as Map)};
  }

  Future<bool> delete({required int txId}) async {
    final res = await _conn.invoke(
      InvokeReq(
        reqId: const Uuid().v4(),
        expensePut: ReqExpensePut(
          txId: Int64(txId),
          deletedTsMs: Int64(DateTime.now().millisecondsSinceEpoch),
        ),
      ),
    );
    invokeResThrow(res, fallback: 'expense delete failed');
    return true;
  }
}
