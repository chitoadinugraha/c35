import 'dart:io';

import 'package:path/path.dart' as p;

import '../deploy_lib.dart';
import 'hash_blake3.dart';
import 'update_version.dart';

class AndroidApkResult {
  const AndroidApkResult({required this.version, required this.apkPath, required this.hash, required this.size});
  final int version;
  final String apkPath;
  final String hash;
  final int size;
}

const _defaultAndroidBuildCores = 4;

int androidBuildCoreLimit() {
  final raw = Platform.environment['ANDROID_BUILD_CORES']?.trim();
  if (raw == null || raw.isEmpty) return _defaultAndroidBuildCores;
  if (raw == '0' || raw.toLowerCase() == 'auto') return 0;
  return int.tryParse(raw) ?? _defaultAndroidBuildCores;
}

int deployAndroidBuildCores() {
  final deploy = Platform.environment['DEPLOY_ANDROID_BUILD_CORES']?.trim();
  if (deploy != null && deploy.isNotEmpty) {
    if (deploy == '0' || deploy.toLowerCase() == 'auto') return 0;
    return int.tryParse(deploy) ?? _defaultAndroidBuildCores;
  }
  return _defaultAndroidBuildCores;
}

Map<String, String> androidBuildProcessEnvironment() {
  final env = Map<String, String>.from(Platform.environment);
  if (!env.containsKey('JAVA_HOME') && Platform.isWindows) {
    const jbr = r'C:\Program Files\Android\Android Studio\jbr';
    if (Directory(jbr).existsSync()) env['JAVA_HOME'] = jbr;
  }
  final limit = deployAndroidBuildCores();
  if (limit <= 0) {
    env.remove('CMAKE_BUILD_PARALLEL_LEVEL');
    env.remove('NINJA_PARALLEL');
    return env;
  }
  final s = limit.toString();
  env['CMAKE_BUILD_PARALLEL_LEVEL'] = s;
  env['NINJA_PARALLEL'] = s;
  return env;
}

void androidGradleStop(String clientApp) {
  final gradlew = Platform.isWindows ? p.join(clientApp, 'android', 'gradlew.bat') : p.join(clientApp, 'android', 'gradlew');
  if (!File(gradlew).existsSync()) return;
  final proc = Process.runSync(gradlew, ['--stop'], workingDirectory: p.join(clientApp, 'android'), environment: androidBuildProcessEnvironment(), runInShell: Platform.isWindows);
  if (proc.stdout.toString().trim().isNotEmpty) stdout.write(proc.stdout);
  if (proc.stderr.toString().trim().isNotEmpty) stderr.write(proc.stderr);
}

String buildAndroidAab({String? serverUrl}) {
  final root = repoRoot();
  final clientApp = deployAppDir(root);
  final buildOutput = p.join(clientApp, 'build', 'app', 'outputs', 'bundle', 'release');
  final version = versionStampSync(root);
  final apiServer = serverUrl?.trim().isNotEmpty == true
      ? serverUrl!.trim()
      : (Platform.environment['C35_SERVER']?.trim().isNotEmpty == true ? Platform.environment['C35_SERVER']!.trim() : 'https://alienai.id');
  stdout.writeln('Building Flutter Android AAB from clients/app (version $version, server $apiServer)...');
  final cores = deployAndroidBuildCores();
  if (cores > 0) stdout.writeln('Android build parallelism: $cores cores (Gradle workers + CMake/Ninja)');
  androidGradleStop(clientApp);
  final proc = Process.runSync(
    'flutter',
    ['build', 'appbundle', '--release', '--dart-define=C35_SERVER=$apiServer'],
    workingDirectory: clientApp,
    environment: androidBuildProcessEnvironment(),
    runInShell: Platform.isWindows,
  );
  stdout.write(proc.stdout);
  stderr.write(proc.stderr);
  if (proc.exitCode != 0) throw StateError('flutter build appbundle failed (exit ${proc.exitCode})');
  if (!Directory(buildOutput).existsSync()) {
    throw StateError('Flutter Android build failed. build/app/outputs/bundle/release directory not found.');
  }
  stdout.writeln('✓ Flutter Android AAB build successful');
  return buildOutput;
}

String _androidApiServer(String? serverUrl) => serverUrl?.trim().isNotEmpty == true
    ? serverUrl!.trim()
    : (Platform.environment['C35_SERVER']?.trim().isNotEmpty == true ? Platform.environment['C35_SERVER']!.trim() : 'https://alienai.id');

AndroidApkResult buildAndroidApk({String? serverUrl, bool stampVersion = false}) {
  final root = repoRoot();
  final clientApp = deployAppDir(root);
  final apkPath = p.join(clientApp, 'build', 'app', 'outputs', 'flutter-apk', 'app-release.apk');
  final version = stampVersion ? int.parse(versionStampSync(root)) : int.parse(versionReadPubspec(root).$2.toString());
  final apiServer = _androidApiServer(serverUrl);
  stdout.writeln('Building Flutter Android APK from clients/app (version $version, server $apiServer)...');
  final cores = deployAndroidBuildCores();
  if (cores > 0) stdout.writeln('Android build parallelism: $cores cores (Gradle workers + CMake/Ninja)');
  androidGradleStop(clientApp);
  final proc = Process.runSync(
    'flutter',
    ['build', 'apk', '--release', '--dart-define=C35_SERVER=$apiServer'],
    workingDirectory: clientApp,
    environment: androidBuildProcessEnvironment(),
    runInShell: Platform.isWindows,
  );
  stdout.write(proc.stdout);
  stderr.write(proc.stderr);
  if (proc.exitCode != 0) throw StateError('flutter build apk failed (exit ${proc.exitCode})');
  if (!File(apkPath).existsSync()) throw StateError('Flutter Android APK build failed. app-release.apk not found.');
  final size = File(apkPath).lengthSync();
  final hash = blake3HexOfFile(apkPath, root: root);
  stdout.writeln('✓ Flutter Android APK build successful hash=$hash size=$size');
  return AndroidApkResult(version: version, apkPath: apkPath, hash: hash, size: size);
}
