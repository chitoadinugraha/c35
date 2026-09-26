import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../deploy_lib.dart';
import 'agent_version.dart';
import 'build_remote_windows.dart';
import 'publish_remote_agent_version.dart';

String _uploadBase() => deployEnv('C35_SERVER', 'https://alienai.id').trim().replaceAll(RegExp(r'/+$'), '');

Future<void> uploadRemoteBlobToCas({
  required String zipPath,
  required int version,
  required String localHash,
  required String fileName,
  required String contentType,
}) async {
  final token = deployEnv('DEPLOY_AUTH_TOKEN', '');
  if (token.isEmpty) throw StateError('DEPLOY_AUTH_TOKEN required to upload remote agent zip');
  final bytes = await File(zipPath).readAsBytes();
  final uri = Uri.parse('${_uploadBase()}/v1/file/upload');
  final res = await http.post(
    uri,
    headers: {
      'Content-Type': contentType,
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

Future<void> uploadRemoteZipToCas({required String zipPath, required int version, required String localHash}) async {
  await uploadRemoteBlobToCas(
    zipPath: zipPath,
    version: version,
    localHash: localHash,
    fileName: remoteWindowsZipFileName(version),
    contentType: 'application/zip',
  );
}

Future<void> uploadRemoteSetupToCas({required String setupPath, required int version, required String localHash}) async {
  await uploadRemoteBlobToCas(
    zipPath: setupPath,
    version: version,
    localHash: localHash,
    fileName: remoteWindowsSetupFileName(version),
    contentType: 'application/octet-stream',
  );
}

Future<void> uploadAndPublishRemoteRelease(RemoteWindowsBuildResult build) async {
  if (build.setupPath == null || build.setupHash == null || build.setupSize == null) {
    throw StateError('Setup installer required for publish (build on Windows with Inno Setup 6)');
  }
  await runStep('Upload remote agent setup to CAS', () => uploadRemoteSetupToCas(setupPath: build.setupPath!, version: build.version, localHash: build.setupHash!));
  await runStep('Upload remote agent OTA zip to CAS', () => uploadRemoteZipToCas(zipPath: build.zipPath, version: build.version, localHash: build.hash));
  await publishRemoteAgentVersion(
    version: build.version,
    versionName: build.versionName,
    hash: build.hash,
    size: build.size,
    setupHash: build.setupHash!,
    setupSize: build.setupSize!,
  );
}
