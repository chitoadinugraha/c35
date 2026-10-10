import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../deploy_lib.dart';
import 'agent_version.dart';
import 'build_remote_linux.dart';
import 'publish_remote_linux_agent_version.dart';

String _uploadBase() => deployEnv('C35_SERVER', 'https://alienai.id').trim().replaceAll(RegExp(r'/+$'), '');

Future<void> uploadRemoteLinuxZipToCas({
  required String zipPath,
  required int version,
  required String localHash,
}) async {
  final token = deployEnv('DEPLOY_AUTH_TOKEN', '');
  if (token.isEmpty) throw StateError('DEPLOY_AUTH_TOKEN required to upload remote-linux agent zip');
  final bytes = await File(zipPath).readAsBytes();
  final uri = Uri.parse('${_uploadBase()}/v1/file/upload');
  final res = await http.post(
    uri,
    headers: {
      'Content-Type': 'application/zip',
      'Authorization': 'Bearer $token',
      'x-file-name': Uri.encodeComponent(remoteLinuxZipFileName(version)),
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
  stdout.writeln('✓ CAS upload ${remoteLinuxZipFileName(version)} hash=$hash size=${body['size_bytes'] ?? bytes.length}');
}

Future<void> uploadAndPublishRemoteLinuxRelease(RemoteLinuxBuildResult build) async {
  await runStep('Upload remote-linux OTA zip to CAS', () => uploadRemoteLinuxZipToCas(
        zipPath: build.zipPath,
        version: build.version,
        localHash: build.hash,
      ));
  await publishRemoteLinuxAgentVersion(
    version: build.version,
    versionName: build.versionName,
    hash: build.hash,
    size: build.size,
  );
}
