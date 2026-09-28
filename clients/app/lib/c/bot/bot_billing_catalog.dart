import 'package:alienai_c35/c/api/referral_conn.dart';
import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/pb/c35/billing.pb.dart';
import 'package:alienai_c35/c/pb/c35/wire.pb.dart';
import 'package:fixnum/fixnum.dart';
import 'package:uuid/uuid.dart';

Future<List<BillingPlanDoc>> botBillingCatalogLoad(ChatConn conn) async {
  final res = await conn.invoke(
    InvokeReq(reqId: const Uuid().v4(), billingSummary: ReqBillingSummary(billingAccountId: Int64.ZERO)),
  );
  invokeResThrow(res, fallback: 'Failed to load bot billing catalog');
  if (!res.hasBillingSummary()) return const [];
  return res.billingSummary.botPlans;
}