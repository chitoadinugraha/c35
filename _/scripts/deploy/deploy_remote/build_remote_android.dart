import 'dart:io';

import 'package:path/path.dart' as p;

import '../deploy_app/hash_blake3.dart';
import '../deploy_lib.dart';
import 'agent_version.dart';

class RemoteAndroidBuildResult {
  const RemoteAndroidBuildResult({
    required this.version,
    required this.versionName,
    required this.apkPath,
    required this.hash,
    required this.size,
  });
  final int version;
  final String versionName;
  final String apkPath;
  final String hash;
  final int size;
}

String remoteAndroidCacheDir(String root) => p.join(root, '.cache', 'c_remote', 'remote-android');

String _androidDir(String root) => p.join(root, 'remotes', 'c_remote_android', 'android');

String _gradleExecutable(String androidDir) {
  if (Platform.isWindows) {
    final bat = p.join(androidDir, 'gradlew.bat');
    if (File(bat).existsSync()) return bat;
  } else {
    final sh = p.join(androidDir, 'gradlew');
    if (File(sh).existsSync()) return sh;
  }
  return 'gradle';
}

Future<void> _run(String cwd, String executable, List<String> args) async {
  final proc = await Process.start(executable, args, workingDirectory: cwd, runInShell: true);
  final out = await proc.stdout.transform(SystemEncoding().decoder).join();
  final err = await proc.stderr.transform(SystemEncoding().decoder).join();
  stdout.write(out);
  stderr.write(err);
  final code = await proc.exitCode;
  if (code != 0) throw StateError('$executable ${args.join(' ')} failed ($code)');
}

Future<RemoteAndroidBuildResult> buildRemoteAndroidRelease() async {
  final root = repoRoot();
  final (build, name) = agentVersionRead(root, RemoteAgentProduct.android);
  final androidDir = _androidDir(root);
  final remotesDir = p.join(root, 'remotes');
  final jniLibs = p.join(androidDir, 'app', 'src', 'main', 'jniLibs');
  await _run(remotesDir, 'cargo', ['ndk', '-t', 'arm64-v8a', '-o', jniLibs, 'build', '--release', '-p', 'c_remote_android']);

  final gradle = _gradleExecutable(androidDir);
  await _run(androidDir, gradle, ['assembleRelease']);

  final builtApk = p.join(androidDir, 'app', 'build', 'outputs', 'apk', 'release', 'app-release.apk');
  if (!File(builtApk).existsSync()) {
    throw StateError('Missing $builtApk — run gradle assembleRelease from remotes/c_remote_android/android');
  }

  final cache = Directory(remoteAndroidCacheDir(root));
  cache.createSync(recursive: true);
  final outApk = p.join(cache.path, remoteAndroidApkFileName(build));
  File(builtApk).copySync(outApk);
  final hash = blake3HexOfFile(outApk, root: root);
  final size = File(outApk).lengthSync();
  stdout.writeln('✓ remote-android APK ${formatBytes(size)} hash=$hash');
  return RemoteAndroidBuildResult(version: build, versionName: name, apkPath: outApk, hash: hash, size: size);
}
