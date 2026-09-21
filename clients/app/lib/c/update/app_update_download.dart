import 'dart:io';

import 'package:alienai_c35/c/log.dart';
import 'package:alienai_c35/c/update/app_release.dart';
import 'package:alienai_c35/c/update/app_update_paths.dart';
import 'package:archive/archive.dart';
import 'package:blake3_dart/blake3_dart.dart';

Future<bool> appUpdateDownloadVerify({required AppRelease release, void Function(double progress)? onProgress}) async {
  final zipPath = appUpdateZipPath(release.version);
  final ok = await appUpdateDownloadFile(url: release.url, dest: zipPath, expectSize: release.size, onProgress: onProgress);
  if (!ok) return false;
  if (release.hash.isNotEmpty && !appUpdateBlake3Match(zipPath, release.hash)) {
    lError('update hash mismatch');
    try {
      File(zipPath).deleteSync();
    } catch (_) {}
    return false;
  }
  return appUpdateExtractZip(zipPath: zipPath, stagingDir: appUpdateStagingDir(release.version));
}

bool appUpdateBlake3Match(String path, String expect) {
  try {
    final bytes = File(path).readAsBytesSync();
    final got = blake3Hex(bytes).toLowerCase();
    return got == expect.trim().toLowerCase();
  } catch (e) {
    lError(e);
    return false;
  }
}

Future<bool> appUpdateDownloadFile({required String url, required String dest, int expectSize = 0, void Function(double progress)? onProgress}) async {
  if (url.isEmpty) return false;
  final out = File(dest);
  out.parent.createSync(recursive: true);
  var offset = out.existsSync() ? out.lengthSync() : 0;
  if (expectSize > 0 && offset >= expectSize) {
    onProgress?.call(1.0);
    return true;
  }
  final client = HttpClient();
  try {
    while (true) {
      final req = await client.getUrl(Uri.parse(url));
      if (offset > 0) req.headers.set(HttpHeaders.rangeHeader, 'bytes=$offset-');
      final res = await req.close();
      if (res.statusCode == 416) break;
      if (res.statusCode != 200 && res.statusCode != 206) {
        l('update download http ${res.statusCode}');
        return false;
      }
      final sink = out.openWrite(mode: offset > 0 ? FileMode.append : FileMode.write);
      await for (final chunk in res) {
        sink.add(chunk);
        offset += chunk.length;
        if (expectSize > 0) onProgress?.call((offset / expectSize).clamp(0.0, 1.0));
      }
      await sink.close();
      if (res.statusCode == 200 || expectSize <= 0 || offset >= expectSize) break;
    }
    onProgress?.call(1.0);
    return out.existsSync() && out.lengthSync() > 0;
  } catch (e) {
    lError(e);
    return false;
  } finally {
    client.close(force: true);
  }
}

bool appUpdateExtractZip({required String zipPath, required String stagingDir}) {
  try {
    final dir = Directory(stagingDir);
    if (dir.existsSync()) dir.deleteSync(recursive: true);
    dir.createSync(recursive: true);
    final archive = ZipDecoder().decodeBytes(File(zipPath).readAsBytesSync());
    for (final f in archive) {
      final name = f.name.replaceAll('/', Platform.pathSeparator);
      if (name.contains('..')) continue;
      final out = File('${dir.path}${Platform.pathSeparator}$name');
      if (f.isFile) {
        out.parent.createSync(recursive: true);
        out.writeAsBytesSync(f.content as List<int>);
      } else {
        Directory(out.path).createSync(recursive: true);
      }
    }
    return File('${dir.path}${Platform.pathSeparator}alienai.exe').existsSync();
  } catch (e) {
    lError(e);
    return false;
  }
}

bool appUpdateStagedReady(int version) => File('${appUpdateStagingDir(version)}${Platform.pathSeparator}alienai.exe').existsSync();
