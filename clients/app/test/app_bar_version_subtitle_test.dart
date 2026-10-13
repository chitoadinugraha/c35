import 'package:alienai_c35/c/parts/app_bar_version_subtitle.dart';
import 'package:alienai_c35/c/update/app_release.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('appBarVersionSubtitle shows current build when up to date', () {
    expect(
      appBarVersionSubtitle(localBuild: 295, remote: const AppRelease(version: 295)),
      'Version 295',
    );
  });

  test('appBarVersionSubtitle shows New when remote is newer', () {
    expect(
      appBarVersionSubtitle(localBuild: 295, remote: const AppRelease(version: 296)),
      'New: 296',
    );
  });
}
