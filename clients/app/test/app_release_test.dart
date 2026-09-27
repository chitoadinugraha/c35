import 'package:alienai_c35/c/update/app_release.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('appReleaseParse reads windows payload', () {
    final r = appReleaseParse({
      'version': 235,
      'versionName': '20.235.0',
      'min': 200,
      'hash': 'abc123',
      'size': 1024,
      'url': 'https://api.alienai.id/fs/abc123?exp=1&sig=x',
    });
    expect(r?.version, 235);
    expect(r?.min, 200);
    expect(r?.hash, 'abc123');
    expect(appReleaseNeedsUpdate(local: 234, remote: r!), isTrue);
    expect(appReleaseForceUpdate(local: 199, remote: r), isTrue);
    expect(appReleaseForceUpdate(local: 234, remote: r), isFalse);
  });

  test('appReleaseParse rejects invalid version', () {
    expect(appReleaseParse({'version': 0}), isNull);
  });

  test('appReleasePlatformsParse reads platform map', () {
    final all = appReleasePlatformsParse({
      'platforms': {
        'android': {'version': 248, 'versionName': '20.248.0', 'min': 0, 'url': 'https://play.google.com'},
        'remote-windows': {'version': 12, 'versionName': '1.12.0', 'min': 0, 'url': 'https://alienai.id'},
        'server': {'version': 248, 'versionName': '20.248.0', 'min': 0, 'url': 'https://api.alienai.id/livez'},
      },
    });
    expect(all?.versionOf('android'), 248);
    expect(all?.versionOf('remote-windows'), 12);
    expect(all?.versionOf('server'), 248);
  });
}
