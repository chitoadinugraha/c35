import 'package:alienai_c35/c/api/referral_conn.dart';
import 'package:alienai_c35/c/pb/c35/billing.pb.dart';
import 'package:alienai_c35/c/pb/c35/wire.pb.dart';
import 'package:fixnum/fixnum.dart';
import 'package:uuid/uuid.dart';

Future<List<BillingTopupQueueItem>> financeTopupList(ReferralConn conn, {String status = 'pending', int limit = 100}) async {
  final res = await conn.invoke(
    InvokeReq(reqId: const Uuid().v4(), billingTopupList: ReqBillingTopupList(status: status, limit: limit)),
    timeout: const Duration(seconds: 20),
  );
  invokeResThrow(res, fallback: 'Failed to load top-ups');
  if (!res.hasBillingTopupList()) return [];
  return res.billingTopupList.requests;
}

Future<void> financeTopupReview(ReferralConn conn, {required int requestId, required String action, String reason = ''}) async {
  final res = await conn.invoke(
    InvokeReq(
      reqId: const Uuid().v4(),
      billingTopupReview: ReqBillingTopupReview(requestId: Int64(requestId), action: action, reason: reason),
    ),
    timeout: const Duration(seconds: 20),
  );
  invokeResThrow(res, fallback: 'Review failed');
}

Future<List<CommissionWithdrawQueueItem>> financeWithdrawList(ReferralConn conn, {String status = 'pending', int limit = 100}) async {
  final res = await conn.invoke(
    InvokeReq(reqId: const Uuid().v4(), commissionWithdrawList: ReqCommissionWithdrawList(status: status, limit: limit)),
    timeout: const Duration(seconds: 20),
  );
  invokeResThrow(res, fallback: 'Failed to load withdrawals');
  if (!res.hasCommissionWithdrawList()) return [];
  return res.commissionWithdrawList.requests;
}

Future<void> financeWithdrawReview(
  ReferralConn conn, {
  required int requestId,
  required String action,
  String transferProofUrl = '',
  String reason = '',
}) async {
  final res = await conn.invoke(
    InvokeReq(
      reqId: const Uuid().v4(),
      commissionWithdrawReview: ReqCommissionWithdrawReview(
        requestId: Int64(requestId),
        action: action,
        transferProofUrl: transferProofUrl,
        reason: reason,
      ),
    ),
    timeout: const Duration(seconds: 20),
  );
  invokeResThrow(res, fallback: 'Review failed');
}

Future<List<BillingReceiveAccount>> financeReceiveAccountList(ReferralConn conn, {String currency = 'IDR', bool activeOnly = true}) async {
  final res = await conn.invoke(
    InvokeReq(
      reqId: const Uuid().v4(),
      billingReceiveAccountList: ReqBillingReceiveAccountList(currency: currency, activeOnly: activeOnly),
    ),
    timeout: const Duration(seconds: 15),
  );
  invokeResThrow(res, fallback: 'Failed to load receive accounts');
  if (!res.hasBillingReceiveAccountList()) return [];
  return res.billingReceiveAccountList.accounts;
}

Future<BillingReceiveAccount> financeReceiveAccountPut(ReferralConn conn, BillingReceiveAccount account) async {
  final res = await conn.invoke(
    InvokeReq(reqId: const Uuid().v4(), billingReceiveAccountPut: ReqBillingReceiveAccountPut(account: account)),
    timeout: const Duration(seconds: 20),
  );
  invokeResThrow(res, fallback: 'Failed to save receive account');
  if (!res.hasBillingReceiveAccountPut()) throw 'No receive account response';
  return res.billingReceiveAccountPut.account;
}
