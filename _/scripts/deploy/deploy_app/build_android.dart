import 'dart:io';

import 'package:path/path.dart' as p;

import '../deploy_lib.dart';
import 'deploy_build_parallel.dart';
import 'hash_blake3.dart';
import 'update_version.dart';

class AndroidApkResult {
  const AndroidApkResult({required this.version, required this.apkPath, required this.hash, required this.size});
  final int version;
  final String apkPath;
  final String hash;
  final int size;
}

int androidBuildCoreLimit() => resolveDeployBuildCores();

int deployAndroidBuildCores() => resolveDeployBuildCores();

Map<String, String> androidBuildProcessEnvironment() => deployNativeBuildProcessEnvironment();

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
  if (cores > 0) {
    stdout.writeln('Android build parallelism: $cores cores (${deployHostLogicalProcessors()} logical CPUs, Gradle + CMake/Ninja)');
  } else {
    stdout.writeln('Android build parallelism: uncapped (DEPLOY_ANDROID_BUILD_CORES=0)');
  }
  if (deployAndroidGradleStopBeforeBuild()) androidGradleStop(clientApp);
  return deployRunSync('android_aab', () {
    final proc = Process.runSync(
      'flutter',
      [
        'build',
        'appbundle',
        '--release',
        '--dart-define=C35_SERVER=$apiServer',
        '--dart-define=C35_BILLING_DISTRIBUTION=play',
      ],
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
    for (final ent in Directory(buildOutput).listSync()) {
      if (ent is File && ent.path.endsWith('.aab')) {
        deployArtifact('android_aab', ent.lengthSync());
        break;
      }
    }
    stdout.writeln('✓ Flutter Android AAB build successful');
    final verify = p.join(repoRoot(), '_', 'scripts', 'dev', 'verify_play_aab_wallet_strings.ps1');
    if (File(verify).existsSync()) {
      for (final ent in Directory(buildOutput).listSync()) {
        if (ent is File && ent.path.endsWith('.aab')) {
          final proc = Process.runSync(
            'powershell',
            ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', verify, '-AabPath', ent.path],
            runInShell: true,
          );
          stdout.write(proc.stdout);
          stderr.write(proc.stderr);
          if (proc.exitCode != 0) {
            throw StateError('Play AAB wallet string check failed (see verify_play_aab_wallet_strings.ps1)');
          }
          break;
        }
      }
    }
    return buildOutput;
  });
}

String _androidApiServer(String? serverUrl) => serverUrl?.trim().isNotEmpty == true
    ? serverUrl!.trim()
    : (Platform.environment['C35_SERVER']?.trim().isNotEmpty == true ? Platform.environment['C35_SERVER']!.trim() : 'https://alienai.id');

AndroidApkResult androidApkResultFromExisting({int? version}) {
  final root = repoRoot();
  final clientApp = deployAppDir(root);
  final apkPath = p.join(clientApp, 'build', 'app', 'outputs', 'flutter-apk', 'app-release.apk');
  if (!File(apkPath).existsSync()) throw StateError('Android APK not found at $apkPath (build apk first)');
  final v = version ?? int.parse(versionReadPubspec(root).$2.toString());
  final size = File(apkPath).lengthSync();
  final hash = blake3HexOfFile(apkPath, root: root);
  deployArtifact('android_apk', size);
  return AndroidApkResult(version: v, apkPath: apkPath, hash: hash, size: size);
}

AndroidApkResult buildAndroidApk({String? serverUrl, bool stampVersion = false}) {
  final root = repoRoot();
  final clientApp = deployAppDir(root);
  final apkPath = p.join(clientApp, 'build', 'app', 'outputs', 'flutter-apk', 'app-release.apk');
  final version = stampVersion ? int.parse(versionStampSync(root)) : int.parse(versionReadPubspec(root).$2.toString());
  final apiServer = _androidApiServer(serverUrl);
  stdout.writeln('Building Flutter Android APK from clients/app (version $version, server $apiServer)...');
  final cores = deployAndroidBuildCores();
  if (cores > 0) {
    stdout.writeln('Android build parallelism: $cores cores (${deployHostLogicalProcessors()} logical CPUs, Gradle + CMake/Ninja)');
  } else {
    stdout.writeln('Android build parallelism: uncapped (DEPLOY_ANDROID_BUILD_CORES=0)');
  }
  if (deployAndroidGradleStopBeforeBuild()) androidGradleStop(clientApp);
  return deployRunSync('android_apk', () {
    final proc = Process.runSync(
      'flutter',
      [
        'build',
        'apk',
        '--release',
        '--dart-define=C35_SERVER=$apiServer',
        '--dart-define=C35_BILLING_DISTRIBUTION=direct',
      ],
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
    deployArtifact('android_apk', size);
    stdout.writeln('✓ Flutter Android APK build successful hash=$hash size=$size');
    return AndroidApkResult(version: version, apkPath: apkPath, hash: hash, size: size);
  });
}
