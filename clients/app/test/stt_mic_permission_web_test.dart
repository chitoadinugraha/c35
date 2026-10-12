import 'package:alienai_c35/c/stt/stt_mic_permission.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('web mic error mentions browser', () {
    final msg = sttMicErrorMessageForPlatform(
      isWeb: true,
      isWindows: false,
      isAndroid: false,
      isIOS: false,
      isMacOS: false,
    );
    expect(msg.toLowerCase(), contains('browser'));
  });
}
