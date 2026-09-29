import 'package:alienai_c35/c/api/referral_conn.dart';
import 'package:alienai_c35/c/pb/c35/billing.pb.dart';
import 'package:alienai_c35/c/pb/c35/wire.pb.dart';
import 'package:fixnum/fixnum.dart';
import 'package:uuid/uuid.dart';

Future<ResBillingVoucherIssue> billingVoucherIssue(
  ReferralConn conn, {
  required String kind,
  String planSlug = '',
  int durationMonths = 1,
  double creditIdr = 0,
  required double faceValueIdr,
  int maxUses = 1,
  Int64 expiresAtMs = Int64.ZERO,
  String paymentRef = '',
  String code = '',
  String name = '',
  String scope = 'user',
  String billingPeriod = 'monthly',
  double listPriceIdr = 0,
  double alienPoolLimitIdr = 0,
  double frontierPoolLimitIdr = 0,
  int quantity = 1,
}) async {
  final res = await conn.invoke(
    InvokeReq(
      reqId: const Uuid().v4(),
      billingVoucherIssue: ReqBillingVoucherIssue(
        kind: kind,
        planSlug: planSlug,
        durationMonths: durationMonths,
        creditIdr: creditIdr,
        faceValueIdr: faceValueIdr,
        maxUses: maxUses,
        expiresAtMs: expiresAtMs,
        paymentRef: paymentRef,
        code: code,
        name: name,
        scope: scope,
        billingPeriod: billingPeriod,
        listPriceIdr: listPriceIdr,
        alienPoolLimitIdr: alienPoolLimitIdr,
        frontierPoolLimitIdr: frontierPoolLimitIdr,
        quantity: quantity,
      ),
    ),
    timeout: const Duration(seconds: 25),
  );
  invokeResThrow(res, fallback: 'Failed to issue voucher');
  if (!res.hasBillingVoucherIssue()) throw 'No voucher issue response';
  return res.billingVoucherIssue;
}

Future<ResBillingVoucherLimit> billingVoucherLimitGet(ReferralConn conn, {required int targetIid}) async {
  final res = await conn.invoke(
    InvokeReq(
      reqId: const Uuid().v4(),
      billingVoucherLimitGet: ReqBillingVoucherLimitGet(targetIid: Int64(targetIid)),
    ),
    timeout: const Duration(seconds: 12),
  );
  invokeResThrow(res, fallback: 'Failed to load voucher limit');
  if (!res.hasBillingVoucherLimitGet()) throw 'No voucher limit response';
  return res.billingVoucherLimitGet;
}

Future<ResBillingVoucherLimit> billingVoucherLimitPut(
  ReferralConn conn, {
  required int targetIid,
  required double limitIdr,
}) async {
  final res = await conn.invoke(
    InvokeReq(
      reqId: const Uuid().v4(),
      billingVoucherLimitPut: ReqBillingVoucherLimitPut(targetIid: Int64(targetIid), limitIdr: limitIdr),
    ),
    timeout: const Duration(seconds: 12),
  );
  invokeResThrow(res, fallback: 'Failed to save voucher limit');
  if (!res.hasBillingVoucherLimitPut()) throw 'No voucher limit response';
  return res.billingVoucherLimitPut;
}

Future<ResBillingVoucherList> billingVoucherList(ReferralConn conn) async {
  final res = await conn.invoke(
    InvokeReq(reqId: const Uuid().v4(), billingVoucherList: ReqBillingVoucherList()),
    timeout: const Duration(seconds: 20),
  );
  invokeResThrow(res, fallback: 'Failed to load vouchers');
  if (!res.hasBillingVoucherList()) throw 'No voucher list response';
  return res.billingVoucherList;
}

Future<ResBillingVoucherRedeemList> billingVoucherRedeemList(ReferralConn conn, {int limit = 100}) async {
  final res = await conn.invoke(
    InvokeReq(reqId: const Uuid().v4(), billingVoucherRedeemList: ReqBillingVoucherRedeemList(limit: limit)),
    timeout: const Duration(seconds: 20),
  );
  invokeResThrow(res, fallback: 'Failed to load redeem history');
  if (!res.hasBillingVoucherRedeemList()) throw 'No redeem history response';
  return res.billingVoucherRedeemList;
}

Future<void> billingVoucherVoid(ReferralConn conn, {required String code}) async {
  final res = await conn.invoke(
    InvokeReq(reqId: const Uuid().v4(), billingVoucherVoid: ReqBillingVoucherVoid(code: code)),
    timeout: const Duration(seconds: 15),
  );
  invokeResThrow(res, fallback: 'Failed to void voucher');
}

Future<ResBillingEntitlementList> billingEntitlementList(ReferralConn conn) async {
  final res = await conn.invoke(
    InvokeReq(reqId: const Uuid().v4(), billingEntitlementList: ReqBillingEntitlementList()),
    timeout: const Duration(seconds: 15),
  );
  invokeResThrow(res, fallback: 'Failed to load entitlements');
  if (!res.hasBillingEntitlementList()) throw 'No entitlement list response';
  return res.billingEntitlementList;
}
