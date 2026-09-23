import 'package:alienai_c35/c/api/referral_conn.dart';
import 'package:alienai_c35/c/pb/c35/billing.pb.dart';
import 'package:alienai_c35/c/pb/c35/referral.pb.dart';
import 'package:alienai_c35/c/pb/c35/wire.pb.dart';
import 'package:fixnum/fixnum.dart';
import 'package:uuid/uuid.dart';

Future<ResReferralCommissionSimulate> referralCommissionSimulate(
  ReferralConn conn, {
  required int subjectUid,
  required int purchaseAmount,
}) async {
  final res = await conn.invoke(
    InvokeReq(
      reqId: const Uuid().v4(),
      referralCommissionSimulate: ReqReferralCommissionSimulate(
        subjectUid: Int64(subjectUid),
        purchaseAmount: Int64(purchaseAmount),
      ),
    ),
    timeout: const Duration(seconds: 15),
  );
  invokeResThrow(res, fallback: 'Failed to simulate commission');
  if (!res.hasReferralCommissionSimulate()) throw 'No commission preview data';
  return res.referralCommissionSimulate;
}

Future<ResBillingPackagePreview> billingPackagePreview(ReferralConn conn, {required String code}) async {
  final res = await conn.invoke(
    InvokeReq(reqId: const Uuid().v4(), billingPackagePreview: ReqBillingPackagePreview(code: code)),
    timeout: const Duration(seconds: 15),
  );
  invokeResThrow(res, fallback: 'Failed to preview package');
  if (!res.hasBillingPackagePreview()) throw 'No package preview data';
  return res.billingPackagePreview;
}

Future<ResBillingPackageRedeem> billingPackageRedeem(ReferralConn conn, {required String code}) async {
  final res = await conn.invoke(
    InvokeReq(reqId: const Uuid().v4(), billingPackageRedeem: ReqBillingPackageRedeem(code: code)),
    timeout: const Duration(seconds: 20),
  );
  invokeResThrow(res, fallback: 'Failed to redeem package');
  if (!res.hasBillingPackageRedeem()) throw 'No package redeem data';
  return res.billingPackageRedeem;
}

Future<ResCommissionWithdraw> commissionWithdraw(
  ReferralConn conn, {
  required double amountIdr,
  required String payoutMethod,
  String currency = 'IDR',
  String bankId = '',
  String accountNumber = '',
  String accountName = '',
  double amountUsd = 0,
}) async {
  final res = await conn.invoke(
    InvokeReq(
      reqId: const Uuid().v4(),
      commissionWithdraw: ReqCommissionWithdraw(
        amountIdr: amountIdr,
        amountUsd: amountUsd,
        currency: currency,
        payoutMethod: payoutMethod,
        bankId: bankId,
        accountNumber: accountNumber,
        accountName: accountName,
      ),
    ),
    timeout: const Duration(seconds: 20),
  );
  invokeResThrow(res, fallback: 'Withdraw failed');
  if (!res.hasCommissionWithdraw()) throw 'No withdraw response';
  return res.commissionWithdraw;
}

Future<ResReferralLedgerList> referralLedgerList(ReferralConn conn, {int limit = 50}) async {
  final res = await conn.invoke(
    InvokeReq(reqId: const Uuid().v4(), referralLedgerList: ReqReferralLedgerList(limit: limit)),
    timeout: const Duration(seconds: 15),
  );
  invokeResThrow(res, fallback: 'Failed to load commission ledger');
  if (!res.hasReferralLedgerList()) throw 'No ledger data';
  return res.referralLedgerList;
}
