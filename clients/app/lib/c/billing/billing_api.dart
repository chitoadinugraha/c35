import 'package:alienai_c35/c/api/referral_conn.dart';
import 'package:alienai_c35/c/pb/c35/billing.pb.dart';
import 'package:alienai_c35/c/pb/c35/wire.pb.dart';
import 'package:uuid/uuid.dart';

Future<ResBillingTopupMethods> billingTopupMethods(ReferralConn conn, {double sampleAmountIdr = 0}) async {
  final res = await conn.invoke(
    InvokeReq(
      reqId: const Uuid().v4(),
      billingTopupMethods: ReqBillingTopupMethods(sampleAmountIdr: sampleAmountIdr),
    ),
    timeout: const Duration(seconds: 15),
  );
  invokeResThrow(res, fallback: 'Failed to load payment methods');
  if (!res.hasBillingTopupMethods()) throw 'No payment methods response';
  return res.billingTopupMethods;
}

Future<ResBillingTopupGet> billingTopupGet(ReferralConn conn, {required String orderId}) async {
  final res = await conn.invoke(
    InvokeReq(
      reqId: const Uuid().v4(),
      billingTopupGet: ReqBillingTopupGet(orderId: orderId),
    ),
    timeout: const Duration(seconds: 10),
  );
  invokeResThrow(res, fallback: 'Failed to check payment status');
  if (!res.hasBillingTopupGet()) throw 'No top-up status response';
  return res.billingTopupGet;
}

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
