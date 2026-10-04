import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../deploy_lib.dart';
import 'agent_version.dart';
import 'build_remote_android.dart';
import 'publish_remote_android_version.dart';

String _uploadBase() => deployEnv('C35_SERVER', 'https://alienai.id').trim().replaceAll(RegExp(r'/+$'), '');

Future<void> uploadRemoteAndroidApkToCas({
  required String apkPath,
  required int version,
  required String localHash,
}) async {
  final token = deployEnv('DEPLOY_AUTH_TOKEN', '');
  if (token.isEmpty) throw StateError('DEPLOY_AUTH_TOKEN required to upload remote-android apk');
  final bytes = await File(apkPath).readAsBytes();
  final uri = Uri.parse('${_uploadBase()}/v1/file/upload');
  final fileName = remoteAndroidApkFileName(version);
  final res = await http.post(
    uri,
    headers: {
      'Content-Type': 'application/vnd.android.package-archive',
      'Authorization': 'Bearer $token',
      'x-file-name': Uri.encodeComponent(fileName),
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
  stdout.writeln('✓ CAS upload $fileName hash=$hash size=${body['size_bytes'] ?? bytes.length}');
}

Future<void> uploadAndPublishRemoteAndroidRelease(RemoteAndroidBuildResult build) async {
  await runStep('Upload remote-android APK to CAS', () => uploadRemoteAndroidApkToCas(apkPath: build.apkPath, version: build.version, localHash: build.hash));
  await publishRemoteAndroidVersion(
    version: build.version,
    versionName: build.versionName,
    apkHash: build.hash,
    apkSize: build.size,
  );
}
