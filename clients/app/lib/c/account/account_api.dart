import 'package:alienai_c35/c/account/invoke_account.dart';
import 'package:alienai_c35/c/api/wire.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:uuid/uuid.dart';

class AccountApi {
  AccountApi({required this.invoke, required this.uid});
  final AuthInvokeFn invoke;
  final int uid;

  Future<UserSettingsRes> userSettingsGet() async {
    final res = await _rpc(invokeUserSettingsBytes(reqId: const Uuid().v4(), uid: uid));
    return res.userSettings ?? const UserSettingsRes();
  }

  Future<void> passwordSet({required String currentPassword, required String newPassword}) async {
    await _rpc(invokePasswordSetBytes(reqId: const Uuid().v4(), uid: uid, currentPassword: currentPassword, newPassword: newPassword));
  }

  Future<void> pinSet({String? currentPin, required String newPin}) async {
    await _rpc(invokePinSetBytes(reqId: const Uuid().v4(), uid: uid, currentPin: currentPin ?? '', newPin: newPin));
  }

  Future<String> sessionUnlockModePut(String mode) async {
    final res = await _rpc(invokeUnlockModePutBytes(reqId: const Uuid().v4(), uid: uid, mode: mode));
    return res.unlockMode.isEmpty ? mode : res.unlockMode;
  }

  Future<SessionStatusRes> sessionStatus({required String clientId}) async {
    final res = await _rpc(invokeSessionStatusBytes(reqId: const Uuid().v4(), uid: uid, clientId: clientId));
    return res.sessionStatus ?? const SessionStatusRes();
  }

  Future<bool> sessionUnlock({required String clientId, String pin = ''}) async {
    final res = await _rpc(invokeSessionUnlockBytes(reqId: const Uuid().v4(), uid: uid, clientId: clientId, pin: pin));
    return res.sessionUnlockOk;
  }

  Future<List<AccountLiveConn>> liveConnsList({int targetUid = 0}) async {
    final res = await _rpc(invokeLiveConnsBytes(reqId: const Uuid().v4(), uid: uid, targetUid: targetUid));
    return res.liveConns;
  }

  Future<void> deviceLabelPut({required String dv, required String labelUser}) async {
    await _rpc(invokeDeviceLabelPutBytes(reqId: const Uuid().v4(), uid: uid, dv: dv, labelUser: labelUser));
  }

  Future<void> liveConnRevoke({required String dv}) async {
    await _rpc(invokeLiveConnRevokeBytes(reqId: const Uuid().v4(), uid: uid, dv: dv));
  }

  Future<int> liveConnRevokeOthers({required String selfDv}) async {
    final res = await _rpc(invokeLiveConnRevokeOthersBytes(reqId: const Uuid().v4(), uid: uid, selfDv: selfDv));
    return res.revoked;
  }

  Future<InvokeAccountRes> _rpc(List<int> body) async {
    final httpRes = await invoke(body: body);
    if (httpRes.statusCode >= 400) throw ApiException(httpRes.error.isEmpty ? 'Request failed' : httpRes.error);
    if (httpRes.statusCode == 0 && httpRes.error.isNotEmpty) throw ApiException(httpRes.error);
    final parsed = invokeAccountResParse(httpRes.body);
    if (!parsed.ok) throw ApiException(parsed.errorMessage.isEmpty ? 'Request failed' : parsed.errorMessage);
    return parsed;
  }
}
