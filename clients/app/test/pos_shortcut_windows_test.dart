import 'dart:io';

import 'package:alienai_c35/c/site/pos_link_format.dart';
import 'package:alienai_c35/c/site/pos_shortcut_install.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('Windows desktop POS shortcut', () async {
    if (!Platform.isWindows) return;
    const siteIid = '999999999';
    const siteName = 'Shortcut Test';
    final stem = posShortcutFileStem(siteName);
    final profile = Platform.environment['USERPROFILE'];
    expect(profile, isNotNull);
    final lnkPath = p.join(profile!, 'Desktop', '$stem.lnk');
    try {
      final res = await posShortcutInstall(siteIid: siteIid, siteName: siteName);
      expect(res, PosShortcutInstallResult.ok);
      expect(File(lnkPath).existsSync(), isTrue);
    } finally {
      final f = File(lnkPath);
      if (f.existsSync()) await f.delete();
    }
  });
}
