import 'package:alienai_c35/c/api/referral_conn.dart';
import 'package:alienai_c35/c/pb/c35/wire.pb.dart';
import 'package:alienai_c35/c/pb/c35/referral.pb.dart';
import 'package:alienai_c35/c/referral/referral_period.dart';
import 'package:fixnum/fixnum.dart';
import 'package:uuid/uuid.dart';

typedef ReferralUserStatsRow = ({
  ReferralUserStatColumn colA,
  ReferralUserStatColumn colB,
  ReferralUserWalletSnapshot? wallet,
  String authEmail,
  String authPhone,
});

// ignore: unintended_html_in_doc_comment
/// Fetches referral + token stats for two date columns in one RPC round-trip.

Future<ReferralUserStatsRow> referralUserStatsGet(
  ReferralConn conn, {
  required int subjectUid,
  required ReferralPeriodRange colA,
  required ReferralPeriodRange colB,
}) async {
  final res = await conn.invoke(
    InvokeReq(
      reqId: const Uuid().v4(),
      referralUserStats: ReqReferralUserStats(
        subjectUid: Int64(subjectUid),
        colA: referralStatPeriod(colA),
        colB: referralStatPeriod(colB),
      ),
    ),
    timeout: const Duration(seconds: 15),
  );
  invokeResThrow(res, fallback: 'Failed to load stats');
  if (!res.hasReferralUserStats()) throw 'No stats data';
  final body = res.referralUserStats;
  return (
    colA: body.hasColA() ? body.colA : ReferralUserStatColumn(),
    colB: body.hasColB() ? body.colB : ReferralUserStatColumn(),
    wallet: body.hasWallet() ? body.wallet : null,
    authEmail: body.authEmail,
    authPhone: body.authPhone,
  );
}
