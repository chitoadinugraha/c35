import 'dart:io';

import 'package:path/path.dart' as p;

import '../deploy_lib.dart';
import 'update_version.dart';

void _patchWebBootstrapQuery(String webDir, String versionCode) {
  final indexPath = p.join(webDir, 'index.html');
  final index = File(indexPath);
  if (!index.existsSync()) return;
  final html = index.readAsStringSync();
  final patched = html.replaceFirst(
    'src="flutter_bootstrap.js"',
    'src="flutter_bootstrap.js?v=$versionCode"',
  );
  if (patched != html) index.writeAsStringSync(patched);
}

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
  return deployRunSync('flutter_web', () {
    _flutterPrepareForBuild(clientApp);
    stdout.writeln('Building Flutter web (version $version, server $apiServer)...');
    final useCdn = deployEnv('C35_WEB_RESOURCES_CDN', '1') != '0';
    final webArgs = [
      'build',
      'web',
      '--release',
      '--base-href',
      '/app/',
      '--dart-define=C35_SERVER=$apiServer',
      // Wasm dry-run adds a second empty `builds: [{}]` entry to flutter_bootstrap.js and breaks web load (~30%).
      '--no-wasm-dry-run',
    ];
    if (useCdn) webArgs.add('--web-resources-cdn');
    final proc = Process.runSync(
      'flutter',
      webArgs,
      workingDirectory: clientApp,
      runInShell: Platform.isWindows,
    );
    stdout.write(proc.stdout);
    stderr.write(proc.stderr);
    if (proc.exitCode != 0) throw StateError('flutter build web failed (exit ${proc.exitCode})');
    if (!Directory(out).existsSync()) throw StateError('Flutter web build missing: $out');
    if (useCdn) {
      final canvaskitDir = Directory(p.join(out, 'canvaskit'));
      if (canvaskitDir.existsSync()) canvaskitDir.deleteSync(recursive: true);
    }
    _patchWebBootstrapQuery(out, version);
    deployArtifact('web', dirBytes(out));
    stdout.writeln('✓ Flutter web build successful');
    return out;
  });
}
