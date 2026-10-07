import 'package:alienai_c35/c/api/referral_conn.dart';
import 'package:alienai_c35/c/pb/c35/billing.pb.dart';
import 'package:alienai_c35/c/pb/c35/wire.pb.dart';
import 'package:fixnum/fixnum.dart';
import 'package:uuid/uuid.dart';

Future<ResBillingPlanChange> billingAdminPlanChange(
  ReferralConn conn, {
  required int subjectUid,
  required String planSlug,
  String billingPeriod = 'monthly',
  String currency = 'IDR',
}) async {
  final res = await conn.invoke(
    InvokeReq(
      reqId: const Uuid().v4(),
      billingAdminPlanChange: ReqBillingAdminPlanChange(
        subjectUid: Int64(subjectUid),
        planSlug: planSlug,
        billingPeriod: billingPeriod,
        currency: currency,
      ),
    ),
    timeout: const Duration(seconds: 20),
  );
  invokeResThrow(res, fallback: 'Failed to set package');
  if (!res.hasBillingAdminPlanChange()) throw 'No plan change response';
  return res.billingAdminPlanChange;
}
