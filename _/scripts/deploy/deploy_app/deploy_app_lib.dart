import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../deploy_lib.dart';
import 'update_version.dart';

void deployAppBumpVersion() {
  final version = versionStampBump(repoRoot());
  stdout.writeln('✓ Version bumped to $version for next deploy');
}

const playStorePackageName = 'id.alienai.agent';

String playStoreCredentialsPath() => p.join(repoRoot(), '_', 'certs', 'google-play-upload-service-account.json');

List<String> playStoreDefaultCredentialPaths() => [playStoreCredentialsPath()];

Future<Map<String, dynamic>> playStoreCredentialsJson() async {
  final jsonEnv = Platform.environment['GOOGLE_PLAY_SERVICE_ACCOUNT_JSON'];
  if (jsonEnv != null && jsonEnv.isNotEmpty) {
    return jsonDecode(jsonEnv) as Map<String, dynamic>;
  }
  final explicit = Platform.environment['GOOGLE_PLAY_SERVICE_ACCOUNT_JSON_PATH'];
  if (explicit != null && explicit.isNotEmpty && File(explicit).existsSync()) {
    return jsonDecode(await File(explicit).readAsString()) as Map<String, dynamic>;
  }
  for (final path in playStoreDefaultCredentialPaths()) {
    if (File(path).existsSync()) {
      return jsonDecode(await File(path).readAsString()) as Map<String, dynamic>;
    }
  }
  throw StateError(
    'Play Store credentials not found.\n'
    'Set GOOGLE_PLAY_SERVICE_ACCOUNT_JSON, GOOGLE_PLAY_SERVICE_ACCOUNT_JSON_PATH,\n'
    'or add one of:\n'
    '${playStoreDefaultCredentialPaths().map((x) => '- $x').join('\n')}',
  );
}

bool isPlayStoreUploadConfigured() =>
    Platform.environment['GOOGLE_PLAY_SERVICE_ACCOUNT_JSON']?.isNotEmpty == true ||
    Platform.environment['GOOGLE_PLAY_SERVICE_ACCOUNT_JSON_PATH']?.isNotEmpty == true ||
    playStoreDefaultCredentialPaths().any((p) => File(p).existsSync());

String findAabFile(String dir) {
  final files = Directory(dir).listSync().whereType<File>().where((f) => f.path.endsWith('.aab')).toList();
  if (files.isEmpty) throw StateError('No .aab file found in $dir');
  return files.first.path;
}

String defaultAabOutputDir() => p.join(deployAppDir(repoRoot()), 'build', 'app', 'outputs', 'bundle', 'release');

String aabBundleSizeLabel([String? buildDir]) {
  final path = findAabFile(buildDir ?? defaultAabOutputDir());
  return formatBytes(File(path).lengthSync());
}
