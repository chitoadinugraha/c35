import 'package:shared_preferences/shared_preferences.dart';

const _dismissedVersionKey = 'app_update_dismissed_version';

Future<bool> appUpdateDismissedVersion(int versionCode) async {
  final p = await SharedPreferences.getInstance();
  return (p.getInt(_dismissedVersionKey) ?? 0) >= versionCode;
}

Future<void> appUpdateDismissedVersionPut(int versionCode) async {
  final p = await SharedPreferences.getInstance();
  final cur = p.getInt(_dismissedVersionKey) ?? 0;
  if (versionCode <= cur) return;
  await p.setInt(_dismissedVersionKey, versionCode);
}
