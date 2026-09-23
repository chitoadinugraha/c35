import 'dart:io';

import 'package:path/path.dart' as p;

import '../deploy_lib.dart';
import 'update_version.dart';

void _flutterPrepareForBuild(String clientApp) {
  final proc = Process.runSync('flutter', ['pub', 'get'], workingDirectory: clientApp, runInShell: Platform.isWindows);
  stdout.write(proc.stdout);
  stderr.write(proc.stderr);
  if (proc.exitCode != 0) throw StateError('flutter pub get failed (exit ${proc.exitCode})');
  final flutterBuildCache = Directory(p.join(clientApp, '.dart_tool', 'flutter_build'));
  if (flutterBuildCache.existsSync()) flutterBuildCache.deleteSync(recursive: true);
}

String buildWebRelease({String? serverUrl}) {
  final root = repoRoot();
  final clientApp = deployAppDir(root);
  final out = p.join(clientApp, 'build', 'web');
  final version = versionStampSync(root);
  final apiServer = serverUrl?.trim().isNotEmpty == true
      ? serverUrl!.trim()
      : deployEnv('C35_SERVER', 'https://api.alienai.id');
  _flutterPrepareForBuild(clientApp);
  stdout.writeln('Building Flutter web (version $version, server $apiServer)...');
  final proc = Process.runSync(
    'flutter',
    ['build', 'web', '--release', '--base-href', '/app/', '--dart-define=C35_SERVER=$apiServer'],
    workingDirectory: clientApp,
    runInShell: Platform.isWindows,
  );
  stdout.write(proc.stdout);
  stderr.write(proc.stderr);
  if (proc.exitCode != 0) throw StateError('flutter build web failed (exit ${proc.exitCode})');
  if (!Directory(out).existsSync()) throw StateError('Flutter web build missing: $out');
  stdout.writeln('✓ Flutter web build successful');
  return out;
}
