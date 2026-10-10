import 'package:alienai_c35/c/parts/windows_taskbar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('windowsPosSiteIidFromExecutableArguments', () {
    expect(
      windowsPosSiteIidFromExecutableArguments(['id.alienai://pos/42001']),
      '42001',
    );
    expect(
      windowsPosSiteIidFromExecutableArguments(['--enable-dart-profiling']),
      isNull,
    );
    expect(windowsLaunchedForPosShortcut(['id.alienai://pos/99']), isTrue);
    expect(windowsLaunchedForPosShortcut([]), isFalse);
  });

  test('windowsPosAppUserModelId', () {
    expect(windowsPosAppUserModelId('42001'), 'id.alienai.pos.42001');
    expect(windowsMainAppUserModelId, 'id.alienai.main');
  });
}
