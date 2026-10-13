import 'dart:io';

import 'package:alienai_c35/c/update/app_update_paths_android.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('appUpdateAndroid path helpers', () {
    const root = '/data/app_flutter';
    expect(appUpdateAndroidVersionDir(root, 292), '$root${Platform.pathSeparator}292');
    expect(appUpdateAndroidApkPath(root, 292), '$root${Platform.pathSeparator}292${Platform.pathSeparator}update.apk');
    expect(appUpdateAndroidReadyMarkerPath(root, 292), '$root${Platform.pathSeparator}292${Platform.pathSeparator}.ready');
  });
}
