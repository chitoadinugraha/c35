import 'package:alienai_c35/c/api/referral_conn.dart' show ReferralConn, invokeResThrow;
import 'package:alienai_c35/c/pb/c35/billing.pb.dart';
import 'package:alienai_c35/c/pb/c35/wire.pb.dart';
import 'package:uuid/uuid.dart';

Future<ResBillingHistory> billingHistoryGet(ReferralConn conn, {int limit = 50, required String currency}) async {
  final res = await conn.invoke(
    InvokeReq(reqId: const Uuid().v4(), billingHistory: ReqBillingHistory(limit: limit, currency: currency)),
    timeout: const Duration(seconds: 15),
  );
  invokeResThrow(res, fallback: 'Failed to load billing history');
  if (!res.hasBillingHistory()) throw 'No billing history data';
  return res.billingHistory;
}
