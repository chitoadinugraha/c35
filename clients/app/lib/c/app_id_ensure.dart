import 'package:alienai_c35/c/app_id.dart';
import 'package:alienai_c35/c/session.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _legacyAppId = 'id.alienai.c35';
const _legacyServerHostKey = '$_legacyAppId.server_host';

/// Validates [C35AppId.id] marker and install-id prefix; clears local session on generation change.
Future<void> appIdEnsure() async {
  final p = await SharedPreferences.getInstance();
  if (p.getString(C35AppId.markerKey) == C35AppId.id) {
    await _installIdEnsure(p);
    return;
  }

  final legacyHost = p.getString(_legacyServerHostKey);
  final hadSession = (p.getInt(C35AppId.sessionUid) ?? 0) > 0 || (p.getString(C35AppId.sessionToken) ?? '').isNotEmpty;
  final oldMarker = p.getString(C35AppId.markerKey);
  final upgrading = hadSession || legacyHost != null || (oldMarker != null && oldMarker != C35AppId.id);

  if (upgrading) {
    await Session.instance.clear(clearStored: true);
    await p.remove(C35AppId.installId);
    if (legacyHost != null && legacyHost.isNotEmpty) {
      await p.setString(C35AppId.serverHostKey, legacyHost);
      await p.remove(_legacyServerHostKey);
    }
  }

  await p.setString(C35AppId.markerKey, C35AppId.id);
  await _installIdEnsure(p);
}

Future<void> _installIdEnsure(SharedPreferences p) async {
  final installId = p.getString(C35AppId.installId) ?? '';
  if (installId.isEmpty || installId.startsWith('${C35AppId.id}-')) return;
  await Session.instance.clear(clearStored: true);
  await p.remove(C35AppId.installId);
}
