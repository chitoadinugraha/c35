import 'dart:io';

import 'package:alienai_c35/c/update/app_release.dart';
import 'package:alienai_c35/c/update/app_update_download.dart';
import 'package:alienai_c35/c/update/app_update_paths.dart';
import 'package:archive/archive.dart';
import 'package:blake3_dart/blake3_dart.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('windows update path helpers under LOCALAPPDATA', () {
    final local = Platform.environment['LOCALAPPDATA'];
    expect(local, isNotNull);
    expect(local, isNotEmpty);
    const v = 999001;
    expect(appUpdateRootDir(), '$local${Platform.pathSeparator}AlienAI${Platform.pathSeparator}updates');
    expect(appUpdateZipPath(v), '${appUpdateRootDir()}${Platform.pathSeparator}$v.zip');
    expect(
      appUpdateStagingDir(v),
      '${appUpdateRootDir()}${Platform.pathSeparator}$v${Platform.pathSeparator}staging',
    );
  });

  test('appUpdateBlake3Match', () {
    final dir = Directory.systemTemp.createTempSync('win-ota-blake3-');
    final file = File('${dir.path}${Platform.pathSeparator}payload.bin');
    file.writeAsBytesSync(const [9, 8, 7, 6, 5]);
    final expectHash = blake3Hex(file.readAsBytesSync()).toLowerCase();
    expect(appUpdateBlake3Match(file.path, expectHash), isTrue);
    expect(appUpdateBlake3Match(file.path, '00'), isFalse);
  });

  test('appUpdateExtractZip stages alienai.exe', () {
    final work = Directory.systemTemp.createTempSync('win-ota-extract-');
    final zipPath = '${work.path}${Platform.pathSeparator}bundle.zip';
    final stagingDir = '${work.path}${Platform.pathSeparator}staging';
    final archive = Archive()
      ..addFile(ArchiveFile('alienai.exe', 4, const [0x4d, 0x5a, 0x00, 0x00]));
    File(zipPath).writeAsBytesSync(ZipEncoder().encode(archive)!);
    expect(appUpdateExtractZip(zipPath: zipPath, stagingDir: stagingDir), isTrue);
    expect(
      File('$stagingDir${Platform.pathSeparator}alienai.exe').existsSync(),
      isTrue,
    );
  });

  test('mock server download verify and staging', () async {
    final base = Platform.environment['C35_WINDOWS_UPDATE_MOCK_BASE']?.trim() ?? '';
    if (base.isEmpty) {
      return;
    }
    final release = await appReleaseGet(base, platform: 'windows');
    expect(release, isNotNull);
    expect(release!.version, greaterThan(0));
    expect(release.hash, isNotEmpty);
    expect(release.url, isNotEmpty);

    final zipPath = appUpdateZipPath(release.version);
    final zipFile = File(zipPath);
    if (zipFile.existsSync()) zipFile.deleteSync();
    final staging = Directory(appUpdateStagingDir(release.version));
    if (staging.existsSync()) staging.deleteSync(recursive: true);

    final ok = await appUpdateDownloadVerify(release: release);
    expect(ok, isTrue);
    expect(appUpdateStagedReady(release.version), isTrue);
  });
}