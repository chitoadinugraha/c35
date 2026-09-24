import 'package:alienai_c35/c/api/referral_conn.dart';
import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/pb/c35/report.pb.dart';
import 'package:alienai_c35/c/pb/c35/wire.pb.dart';
import 'package:fixnum/fixnum.dart';
import 'package:uuid/uuid.dart';

class AdminPnlApi {
  AdminPnlApi(ReferralConn conn) : _invoke = conn.invoke;

  AdminPnlApi.chat(ChatConn conn) : _invoke = conn.invoke;

  final Future<InvokeRes> Function(InvokeReq) _invoke;

  Future<ResAdminPlatformPnl> platformPnl({required Int64 sinceMs, required Int64 untilMs}) async {
    final res = await _invoke(InvokeReq(
      reqId: const Uuid().v4(),
      adminPlatformPnl: ReqAdminPlatformPnl(sinceMs: sinceMs, untilMs: untilMs),
    ));
    invokeResThrow(res, fallback: 'Failed to load P&L');
    if (!res.hasAdminPlatformPnl()) throw 'Failed to load P&L';
    return res.adminPlatformPnl;
  }
}
