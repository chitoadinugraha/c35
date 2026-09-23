import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class C35AppId {
  static const id = 'id.alienai.c35';
  static const oauthReturn = 'id.alienai://oauth-callback';
  static const sessionUid = 'c35_session_uid';
  static const sessionName = 'c35_session_name';
  static const sessionHandle = 'c35_session_handle';
  static const sessionPic = 'c35_session_pic';
  static const sessionEmail = 'c35_session_email';
  static const sessionToken = 'c35_session_token';
  static const sessionGlobalRoles = 'c35_session_global_roles';
  static const allowControl = 'c35_allow_control';
  static const thisPcName = 'c35_this_pc_name';
  static const installId = 'c35_install_id';
  static const model = 'c35_agent_model';
  static const sessionReferredBy = 'c35_session_referred_by';
  static const sessionReferralDismissed = 'c35_session_referral_dismissed';
}

Future<String> deviceInstallId() async {
  final p = await SharedPreferences.getInstance();
  var id = p.getString(C35AppId.installId) ?? '';
  if (id.isEmpty) {
    id = const Uuid().v4();
    await p.setString(C35AppId.installId, id);
  }
  return id;
}
