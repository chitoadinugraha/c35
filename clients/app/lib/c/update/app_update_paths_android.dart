import 'dart:io';

import 'package:path_provider/path_provider.dart';

String appUpdateAndroidVersionDir(String root, int version) => '$root${Platform.pathSeparator}$version';

String appUpdateAndroidApkPath(String root, int version) => '${appUpdateAndroidVersionDir(root, version)}${Platform.pathSeparator}update.apk';

String appUpdateAndroidReadyMarkerPath(String root, int version) => '${appUpdateAndroidVersionDir(root, version)}${Platform.pathSeparator}.ready';

Future<String> appUpdateAndroidRootDir() async {
  final dir = await getApplicationSupportDirectory();
  return '${dir.path}${Platform.pathSeparator}alienai-updates';
}

Future<String> appUpdateApkFilePath(int version) async {
  final root = await appUpdateAndroidRootDir();
  return appUpdateAndroidApkPath(root, version);
}

Future<bool> appUpdateApkStagedReady(int version) async {
  final root = await appUpdateAndroidRootDir();
  final apk = File(appUpdateAndroidApkPath(root, version));
  final ready = File(appUpdateAndroidReadyMarkerPath(root, version));
  return apk.existsSync() && apk.lengthSync() > 0 && ready.existsSync();
}

Future<void> appUpdateApkWriteReadyMarker(int version) async {
  final root = await appUpdateAndroidRootDir();
  final dir = Directory(appUpdateAndroidVersionDir(root, version));
  dir.createSync(recursive: true);
  File(appUpdateAndroidReadyMarkerPath(root, version)).writeAsStringSync('1');
}

Future<void> appUpdateApkClearStage(int version) async {
  final root = await appUpdateAndroidRootDir();
  final dir = Directory(appUpdateAndroidVersionDir(root, version));
  if (dir.existsSync()) dir.deleteSync(recursive: true);
}
