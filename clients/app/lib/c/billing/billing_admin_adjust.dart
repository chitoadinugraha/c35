import 'package:alienai_c35/c/api/referral_conn.dart';
import 'package:alienai_c35/c/pb/c35/billing.pb.dart';
import 'package:alienai_c35/c/pb/c35/wire.pb.dart';
import 'package:fixnum/fixnum.dart';
import 'package:uuid/uuid.dart';

const billingAdminAdjustKindBalance = 'balance';
const billingAdminAdjustKindCommission = 'commission';
const billingAdminAdjustDirCredit = 'credit';
const billingAdminAdjustDirDebit = 'debit';

const billingAdminAdjustReasons = <({String id, String label})>[
  (id: 'promotional', label: 'Promotional'),
  (id: 'compensation', label: 'Compensation'),
  (id: 'correction', label: 'Correction'),
  (id: 'manual_accrual', label: 'Manual accrual'),
  (id: 'commission_clawback', label: 'Commission clawback'),
  (id: 'refund', label: 'Refund'),
  (id: 'topup_manual', label: 'Manual top-up'),
  (id: 'migration', label: 'Migration'),
  (id: 'internal_test', label: 'Internal test'),
  (id: 'withdraw_reversal', label: 'Withdraw reversal'),
  (id: 'other', label: 'Other'),
];

String billingAdminAdjustReasonLabel(String id) {
  for (final r in billingAdminAdjustReasons) {
    if (r.id == id) return r.label;
  }
  return id;
}

Future<ResBillingAdminAdjust> billingAdminAdjustPut(
  ReferralConn conn, {
  required int subjectUid,
  required String kind,
  required String direction,
  required String reason,
  String note = '',
  String currency = 'IDR',
  double amountIdr = 0,
  double amountUsd = 0,
}) async {
  final res = await conn.invoke(
    InvokeReq(
      reqId: const Uuid().v4(),
      billingAdminAdjust: ReqBillingAdminAdjust(
        subjectUid: Int64(subjectUid),
        kind: kind,
        direction: direction,
        reason: reason,
        note: note,
        currency: currency,
        amountIdr: amountIdr,
        amountUsd: amountUsd,
      ),
    ),
    timeout: const Duration(seconds: 15),
  );
  invokeResThrow(res, fallback: 'Failed to adjust balance');
  if (!res.hasBillingAdminAdjust()) throw 'No adjust response';
  return res.billingAdminAdjust;
}

Future<ResBillingAdminAdjustList> billingAdminAdjustList(
  ReferralConn conn, {
  int subjectUid = 0,
  String kind = '',
  String reason = '',
  int fromMs = 0,
  int toMs = 0,
  int limit = 50,
}) async {
  final res = await conn.invoke(
    InvokeReq(
      reqId: const Uuid().v4(),
      billingAdminAdjustList: ReqBillingAdminAdjustList(
        subjectUid: Int64(subjectUid),
        kind: kind,
        reason: reason,
        fromMs: Int64(fromMs),
        toMs: Int64(toMs),
        limit: limit,
      ),
    ),
    timeout: const Duration(seconds: 15),
  );
  invokeResThrow(res, fallback: 'Failed to load adjustments');
  if (!res.hasBillingAdminAdjustList()) throw 'No adjustment list';
  return res.billingAdminAdjustList;
}
