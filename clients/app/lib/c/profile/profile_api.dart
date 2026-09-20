import 'package:alienai_c35/c/api/wire.dart';
import 'package:alienai_c35/c/profile/invoke_profile.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:uuid/uuid.dart';

class ProfileApi {
  ProfileApi({required this.invoke});
  final AuthInvokeFn invoke;

  Future<ProfilePutRes> put({required int uid, String? name, String? avatarUrl, String? handle, String? authEmail}) async {
    final res = await _rpc(invokeProfilePutBytes(reqId: const Uuid().v4(), uid: uid, name: name, avatarUrl: avatarUrl, handle: handle, authEmail: authEmail));
    if (!res.ok) throw ApiException(res.errorMessage.isEmpty ? 'Profile update failed' : res.errorMessage);
    final body = res.profilePut;
    if (body == null) throw ApiException('Profile update failed');
    return body;
  }

  Future<ProfileAlienIdCheckRes> alienIdCheck({required int uid, required String alienId}) async {
    final res = await _rpc(invokeAlienIdCheckBytes(reqId: const Uuid().v4(), uid: uid, alienId: alienId));
    if (!res.ok) throw ApiException(res.errorMessage.isEmpty ? 'Alien ID check failed' : res.errorMessage);
    return res.alienIdCheck ?? const ProfileAlienIdCheckRes();
  }

  Future<InvokeProfileRes> _rpc(List<int> body) async {
    final httpRes = await invoke(body: body);
    if (httpRes.statusCode >= 400) throw ApiException(httpRes.error.isEmpty ? 'Profile update failed' : httpRes.error);
    if (httpRes.statusCode == 0 && httpRes.error.isNotEmpty) throw ApiException(httpRes.error);
    return invokeProfileResParse(httpRes.body);
  }
}
