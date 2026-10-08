import 'package:alienai_c35/c/mention/mention_device_icon.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mentionDeviceIconSpec parses device-kind icons', () {
    expect(mentionDeviceIconSpec('device-kind:android')?.type, 'android');
    expect(mentionDeviceIconSpec('device-kind:windows')?.type, 'windows');
    expect(mentionDeviceIconSpec('device-kind:browser:extension')?.browserEngine, 'extension');
    expect(mentionDeviceIconSpec('computer'), isNull);
  });
}
