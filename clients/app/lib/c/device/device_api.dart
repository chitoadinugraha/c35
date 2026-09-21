import 'package:alienai_c35/c/api/referral_conn.dart';
import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/pb/c35/device.pb.dart';
import 'package:alienai_c35/c/pb/c35/identity.pb.dart';
import 'package:alienai_c35/c/pb/c35/wire.pb.dart';
import 'package:uuid/uuid.dart';

Future<ResIdentityList> identityList(ChatConn conn, List<String> kinds, {bool includeArchived = false}) =>
    conn.identityList(kinds, includeArchived: includeArchived);

Future<ResIdentityGrantPatch> identityGrantPatch(ChatConn conn, ReqIdentityGrantPatch req) => conn.identityGrantPatch(req);

Future<ResDevicePair> devicePair(ReferralConn conn, String code) async {
  final res = await conn.invoke(
    InvokeReq(reqId: const Uuid().v4(), devicePair: ReqDevicePair(code: code)),
    timeout: const Duration(seconds: 20),
  );
  invokeResThrow(res, fallback: 'Failed to pair device');
  if (!res.hasDevicePair()) throw 'No device pair data';
  return res.devicePair;
}
