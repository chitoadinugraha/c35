import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../deploy_lib.dart';
import 'build_windows.dart';
import 'cas_upload_s3.dart';
import 'publish_app_version.dart';

String _uploadBase() => deployEnv('C35_SERVER', 'https://alienai.id').trim().replaceAll(RegExp(r'/+$'), '');

Future<void> uploadWindowsZipToCas({required String zipPath, required int version, required String localHash}) async {
  final file = File(zipPath);
  final size = file.lengthSync();
  const inlineMax = 512 * 1024;
  final viaS3 = deployEnv('CAS_UPLOAD_VIA_S3', size > inlineMax ? '1' : '0') == '1';
  if (viaS3) {
    await casUploadLargeFileViaS3(file: file, hash: localHash, mimeType: 'application/zip');
    return;
  }
  final token = deployEnv('DEPLOY_AUTH_TOKEN', '');
  if (token.isEmpty) throw StateError('DEPLOY_AUTH_TOKEN required to upload Windows release zip');
  final bytes = await file.readAsBytes();
  final uri = Uri.parse('${_uploadBase()}/v1/file/upload');
  const maxAttempts = 3;
  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      final res = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/zip',
          'Authorization': 'Bearer $token',
          'x-file-name': Uri.encodeComponent('alienai-windows-$version.zip'),
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
      stdout.writeln('✓ CAS upload hash=$hash size=${body['size_bytes'] ?? bytes.length}');
      return;
    } on Object catch (e) {
      if (attempt >= maxAttempts) rethrow;
      final waitSec = 5 * attempt;
      stdout.writeln('CAS upload attempt $attempt failed ($e); retry in ${waitSec}s...');
      await Future<void>.delayed(Duration(seconds: waitSec));
    }
  }
}

Future<void> uploadWindowsReleaseOnly(WindowsBuildResult build) async {
  await uploadWindowsZipToCas(zipPath: build.zipPath, version: build.version, localHash: build.hash);
}

Future<void> uploadAndPublishWindowsRelease(WindowsBuildResult build) async {
  await runStep('Upload Windows zip to CAS', () => uploadWindowsReleaseOnly(build));
  await publishWindowsAppVersion(version: build.version, hash: build.hash, size: build.size);
}
