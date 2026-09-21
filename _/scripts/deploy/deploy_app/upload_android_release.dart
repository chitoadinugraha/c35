import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../deploy_lib.dart';
import 'build_android.dart';

String _uploadBase() => deployEnv('C35_SERVER', 'https://alienai.id').trim().replaceAll(RegExp(r'/+$'), '');

Future<void> uploadAndroidApkToCas({required String apkPath, required int version, required String localHash}) async {
  final token = deployEnv('DEPLOY_AUTH_TOKEN', '');
  if (token.isEmpty) throw StateError('DEPLOY_AUTH_TOKEN required to upload Android APK');
  final bytes = await File(apkPath).readAsBytes();
  final uri = Uri.parse('${_uploadBase()}/v1/file/upload');
  final res = await http.post(
    uri,
    headers: {
      'Content-Type': 'application/vnd.android.package-archive',
      'Authorization': 'Bearer $token',
      'x-file-name': Uri.encodeComponent('alienai-android-$version.apk'),
    },
    body: bytes,
  );
  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw StateError('CAS upload failed (${res.statusCode}): ${res.body}');
  }
  final body = jsonDecode(res.body) as Map<String, dynamic>;
  final hash = '${body['hash'] ?? ''}'.trim().toLowerCase();
  if (hash.isEmpty) throw StateError('CAS upload returned empty hash');
  if (hash != localHash.toLowerCase()) throw StateError('CAS hash mismatch: local=$localHash remote=$hash');
  stdout.writeln('✓ CAS upload hash=$hash size=${body['size_bytes'] ?? bytes.length}');
}

Future<void> uploadAndroidApkRelease(AndroidApkResult build) async {
  await runStep('Upload Android APK to CAS', () => uploadAndroidApkToCas(apkPath: build.apkPath, version: build.version, localHash: build.hash));
}
