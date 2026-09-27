import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../deploy_lib.dart';
import 'build_ffmpeg_windows.dart';
import 'ffmpeg_version.dart';
import 'publish_ffmpeg_windows_version.dart';

String _uploadBase() => deployEnv('C35_SERVER', 'https://alienai.id').trim().replaceAll(RegExp(r'/+$'), '');

Future<void> uploadFfmpegZipToCas({required String zipPath, required int version, required String localHash}) async {
  final token = deployEnv('DEPLOY_AUTH_TOKEN', '');
  if (token.isEmpty) throw StateError('DEPLOY_AUTH_TOKEN required to upload ffmpeg zip');
  final bytes = await File(zipPath).readAsBytes();
  final uri = Uri.parse('${_uploadBase()}/v1/file/upload');
  final res = await http.post(
    uri,
    headers: {
      'Content-Type': 'application/zip',
      'Authorization': 'Bearer $token',
      'x-file-name': Uri.encodeComponent(ffmpegWindowsZipFileName(version)),
    },
    body: bytes,
  );
  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw StateError('CAS upload failed (${res.statusCode}): ${res.body}');
  }
  final body = jsonDecode(res.body) as Map<String, dynamic>;
  final hash = '${body['hash'] ?? ''}'.trim().toLowerCase();
  if (hash.isEmpty) throw StateError('CAS upload returned empty hash');
  if (hash != localHash.toLowerCase()) {
    throw StateError('CAS hash mismatch: local=$localHash remote=$hash');
  }
  stdout.writeln('CAS upload ${ffmpegWindowsZipFileName(version)} hash=$hash size=${body['size_bytes'] ?? bytes.length}');
}

Future<void> uploadAndPublishFfmpegRelease(FfmpegWindowsBuildResult build, {required int minAgentBuild, bool skipNats = false}) async {
  await runStep('Upload ffmpeg-windows zip to CAS', () => uploadFfmpegZipToCas(zipPath: build.zipPath, version: build.version, localHash: build.hash));
  await publishFfmpegWindowsVersion(
    version: build.version,
    versionName: build.versionName,
    hash: build.hash,
    size: build.size,
    minAgentBuild: minAgentBuild,
    skipNats: skipNats,
  );
}
