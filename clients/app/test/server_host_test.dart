import 'package:alienai_c35/c/conn/server_host.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('serverHostIsLocalDev recognizes loopback hosts', () {
    expect(serverHostIsLocalDev(serverHostLocalUrl), isTrue);
    expect(serverHostIsLocalDev(serverHostAndroidEmulatorLocalUrl), isTrue);
    expect(serverHostIsLocalDev('http://localhost:8080'), isTrue);
    expect(serverHostIsLocalDev(serverHostProductionUrl), isFalse);
    expect(serverHostIsLocalDev(serverHostTailscaleUrl), isFalse);
  });

  test('serverHostLooksValid rejects broken URLs', () {
    expect(serverHostLooksValid(serverHostLocalUrl), isTrue);
    expect(serverHostLooksValid('http'), isFalse);
    expect(serverHostLooksValid(''), isFalse);
  });

  test('serverHostDebugDefault uses loopback on Android (adb reverse)', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(serverHostDebugDefault(), serverHostLocalUrl);
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    expect(serverHostDebugDefault(), serverHostLocalUrl);
    debugDefaultTargetPlatformOverride = null;
  });
}
