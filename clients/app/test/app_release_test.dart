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
      'url': 'https://alienai.id/fs/abc123?exp=1&sig=x',
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
}
