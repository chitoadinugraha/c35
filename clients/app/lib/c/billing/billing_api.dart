import 'package:alienai_c35/c/api/referral_conn.dart';
import 'package:alienai_c35/c/pb/c35/billing.pb.dart';
import 'package:alienai_c35/c/pb/c35/wire.pb.dart';
import 'package:uuid/uuid.dart';

Future<ResBillingTopupPut> billingTopupPut(
  ReferralConn conn, {
  required double amountUsd,
  double amountIdr = 0,
  required String proofUrl,
  String provider = 'manual',
  String paymentType = 'bank_transfer',
}) async {
  final res = await conn.invoke(
    InvokeReq(
      reqId: const Uuid().v4(),
      billingTopupPut: ReqBillingTopupPut(
        amountUsd: amountUsd,
        amountIdr: amountIdr,
        provider: provider,
        paymentType: paymentType,
        proofUrl: proofUrl,
      ),
    ),
    timeout: const Duration(seconds: 20),
  );
  invokeResThrow(res, fallback: 'Failed to submit top-up');
  if (!res.hasBillingTopupPut()) throw 'No top-up response';
  return res.billingTopupPut;
}

Future<ResBillingPlanSubscribe> billingPlanSubscribe(
  ReferralConn conn, {
  required String planSlug,
  String billingPeriod = 'monthly',
  String currency = 'IDR',
}) async {
  final res = await conn.invoke(
    InvokeReq(
      reqId: const Uuid().v4(),
      billingPlanSubscribe: ReqBillingPlanSubscribe(
        planSlug: planSlug,
        billingPeriod: billingPeriod,
        currency: currency,
      ),
    ),
    timeout: const Duration(seconds: 20),
  );
  invokeResThrow(res, fallback: 'Failed to subscribe');
  if (!res.hasBillingPlanSubscribe()) throw 'No subscribe response';
  return res.billingPlanSubscribe;
}
