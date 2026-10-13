import 'package:alienai_c35/c/update/app_update_channel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('appUpdateChannel defaults to play', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await appUpdateChannelGet(), AppUpdateChannel.play);
  });

  test('appUpdateChannel round-trip apk', () async {
    SharedPreferences.setMockInitialValues({});
    await appUpdateChannelPreferApk();
    expect(await appUpdateChannelGet(), AppUpdateChannel.apk);
    await appUpdateChannelPut(AppUpdateChannel.play);
    expect(await appUpdateChannelGet(), AppUpdateChannel.play);
  });

  test('appUpdateChannelParse', () {
    expect(appUpdateChannelParse('apk'), AppUpdateChannel.apk);
    expect(appUpdateChannelParse('play'), AppUpdateChannel.play);
    expect(appUpdateChannelParse(null), AppUpdateChannel.play);
  });
}
