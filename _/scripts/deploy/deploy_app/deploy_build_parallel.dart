import 'dart:io';

import '../deploy_lib.dart';

const _autoCap = 16;
const _autoFloor = 4;

int deployHostLogicalProcessors() {
  final n = Platform.numberOfProcessors;
  return n > 0 ? n : _autoFloor;
}

/// Build parallelism for deploy-time Flutter/Android/Windows compiles.
/// [DEPLOY_ANDROID_BUILD_CORES] or [ANDROID_BUILD_CORES]: integer, `auto`, or `0` (no cap).
/// Default when unset: `auto` (logical CPUs − 1, clamped 4–16).
int resolveDeployBuildCores() {
  for (final key in ['DEPLOY_ANDROID_BUILD_CORES', 'ANDROID_BUILD_CORES']) {
    final raw = deployEnv(key, '').trim();
    if (raw.isEmpty) continue;
    if (raw == '0') return 0;
    if (raw.toLowerCase() == 'auto') return _autoCoreCount();
    final parsed = int.tryParse(raw);
    if (parsed != null) return parsed <= 0 ? 0 : parsed;
  }
  return _autoCoreCount();
}

int _autoCoreCount() {
  final n = deployHostLogicalProcessors();
  return (n - 1).clamp(_autoFloor, _autoCap);
}

Map<String, String> deployNativeBuildProcessEnvironment() {
  final env = Map<String, String>.from(Platform.environment);
  if (!env.containsKey('JAVA_HOME') && Platform.isWindows) {
    const jbr = r'C:\Program Files\Android\Android Studio\jbr';
    if (Directory(jbr).existsSync()) env['JAVA_HOME'] = jbr;
  }
  final limit = resolveDeployBuildCores();
  if (limit <= 0) {
    env.remove('CMAKE_BUILD_PARALLEL_LEVEL');
    env.remove('NINJA_PARALLEL');
    return env;
  }
  final s = limit.toString();
  env['CMAKE_BUILD_PARALLEL_LEVEL'] = s;
  env['NINJA_PARALLEL'] = s;
  final gradleFlags = '-Dorg.gradle.workers.max=$s -Dorg.gradle.parallel=true -Dorg.gradle.caching=true';
  final existing = env['GRADLE_OPTS']?.trim() ?? '';
  env['GRADLE_OPTS'] = existing.isEmpty ? gradleFlags : '$existing $gradleFlags';
  return env;
}

bool deployAndroidGradleStopBeforeBuild() => deployEnv('DEPLOY_ANDROID_GRADLE_STOP', '0') == '1';
