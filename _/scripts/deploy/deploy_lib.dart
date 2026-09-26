import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

String? _cachedRepoRoot;

String repoRoot() {
  if (_cachedRepoRoot != null) return _cachedRepoRoot!;
  var dir = File.fromUri(Platform.script).parent;
  for (var i = 0; i < 10; i++) {
    final app = File(p.join(dir.path, 'clients', 'app', 'pubspec.yaml'));
    final server = File(p.join(dir.path, 'servers', 'server_ai', 'Cargo.toml'));
    if (app.existsSync() && server.existsSync()) {
      _cachedRepoRoot = dir.path;
      return dir.path;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  throw StateError('Could not find repo root from ${Platform.script}');
}

final Map<String, String> _deployEnvLocal = {};
final Map<String, String> _deployEnvOverrides = {};

void deploySetEnv(String key, String value) => _deployEnvOverrides[key] = value;

void deployLoadEnvLocal() {
  final path = p.join(repoRoot(), '.env.local');
  final file = File(path);
  if (!file.existsSync()) return;
  for (final line in file.readAsLinesSync()) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
    final eq = trimmed.indexOf('=');
    if (eq < 1) continue;
    final name = trimmed.substring(0, eq).trim();
    var value = trimmed.substring(eq + 1).trim();
    if ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith("'") && value.endsWith("'"))) {
      value = value.substring(1, value.length - 1);
    }
    if (Platform.environment.containsKey(name) && (Platform.environment[name]?.trim().isNotEmpty ?? false)) continue;
    _deployEnvLocal[name] = value;
  }
}

String deployEnv(String key, [String fallback = '']) {
  final fromOverride = _deployEnvOverrides[key]?.trim();
  if (fromOverride != null && fromOverride.isNotEmpty) return fromOverride;
  final fromProcess = Platform.environment[key]?.trim();
  if (fromProcess != null && fromProcess.isNotEmpty) return fromProcess;
  final fromFile = _deployEnvLocal[key]?.trim();
  if (fromFile != null && fromFile.isNotEmpty) return fromFile;
  return fallback;
}

String deployDir() => p.join(repoRoot(), '_', 'scripts', 'deploy');

String formatBytes(int bytes) {
  if (bytes >= 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GiB';
  if (bytes >= 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MiB';
  if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(1)} KiB';
  return '$bytes B';
}

int dirBytes(String path) {
  final dir = Directory(path);
  if (!dir.existsSync()) return 0;
  var total = 0;
  for (final e in dir.listSync(recursive: true, followLinks: false)) {
    if (e is File) total += e.lengthSync();
  }
  return total;
}

String dirSizeLabel(String path) => formatBytes(dirBytes(path));

DateTime? _deployStartedAt;
final Map<String, double> _deployMarksSec = {};
final Map<String, int> _deployArtifactsBytes = {};

void deployStart() {
  _deployStartedAt = DateTime.now();
  _deployMarksSec.clear();
  _deployArtifactsBytes.clear();
}

void deployMark(String id, Duration elapsed) => _deployMarksSec[id] = elapsed.inMilliseconds / 1000.0;

void deployArtifact(String id, int bytes) => _deployArtifactsBytes[id] = bytes;

String deployMarkSlug(String label) =>
    label.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'_+'), '_').replaceAll(RegExp(r'^_|_$'), '');

T deployRunSync<T>(String id, T Function() fn) {
  final sw = Stopwatch()..start();
  try {
    return fn();
  } finally {
    sw.stop();
    deployMark(id, sw.elapsed);
  }
}

String _pad2(int n) => n < 10 ? '0$n' : '$n';

String deployDoneAt([DateTime? at]) {
  final d = at ?? DateTime.now();
  return '${d.year}-${_pad2(d.month)}-${_pad2(d.day)}, ${_pad2(d.hour)}:${_pad2(d.minute)}:${_pad2(d.second)}';
}

String formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60);
  if (h > 0) return '${h}h ${m}m ${s}s';
  if (m > 0) return '${m}m ${s}s';
  return '${s}s';
}

void deployDone({String? version, String? detail, String target = 'app-release', bool exitProcess = true}) {
  final finishedAt = DateTime.now();
  final wallElapsed = _deployStartedAt != null ? finishedAt.difference(_deployStartedAt!) : Duration.zero;
  stdout.writeln('');
  if (version != null && version.isNotEmpty) stdout.writeln('📦 $version${detail != null && detail.isNotEmpty ? ' · $detail' : ''}');
  stdout.writeln('✅ Done in ${formatDuration(wallElapsed)} (finished ${deployDoneAt(finishedAt)})');
  final perf = <String, Object?>{
    'kind': 'app',
    'target': target,
    'version': version != null && version.isNotEmpty ? version.replaceFirst('v', '') : '',
    'detail': detail ?? '',
    'duration_sec': wallElapsed.inSeconds,
    'finished_at': deployDoneAt(finishedAt),
  };
  if (_deployMarksSec.isNotEmpty) perf['marks'] = _deployMarksSec;
  if (_deployArtifactsBytes.isNotEmpty) perf['artifacts_bytes'] = _deployArtifactsBytes;
  stdout.writeln('C35_PUBLISH_PERF ${jsonEncode(perf)}');
  if (exitProcess) exit(0);
}

Future<T> runStep<T>(String label, Future<T> Function() task) async {
  _deployStartedAt ??= DateTime.now();
  final start = DateTime.now();
  var frameIndex = 0;
  const frames = ['|', '/', '-', r'\'];
  stdout.writeln('\n→ $label');
  final timer = Timer.periodic(const Duration(milliseconds: 120), (_) {
    final elapsed = DateTime.now().difference(start).inSeconds;
    stdout.write('\r${frames[frameIndex % frames.length]} $label (${elapsed}s)');
    frameIndex++;
  });
  try {
    final result = await task();
    timer.cancel();
    final stepElapsed = DateTime.now().difference(start);
    deployMark(deployMarkSlug(label), stepElapsed);
    stdout.writeln('\r✓ $label completed in ${stepElapsed.inSeconds}s');
    return result;
  } catch (e) {
    timer.cancel();
    stdout.writeln('\r✗ $label failed');
    rethrow;
  }
}

Never phaseFail(String label, String message) {
  stderr.writeln('[error] $label: $message');
  exit(1);
}
