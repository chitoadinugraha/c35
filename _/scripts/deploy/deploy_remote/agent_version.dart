import 'dart:io';

import 'package:path/path.dart' as p;

import '../deploy_lib.dart';

final _versionRegex = RegExp(r'^(\d+\.\d+\.\d+)\+(\d+)$');

String remotesDir(String root) => p.join(root, 'remotes');

String versionFilePath(String root) => p.join(remotesDir(root), 'VERSION');

(int build, String name) agentVersionRead(String root) {
  final line = File(versionFilePath(root)).readAsStringSync().trim().split('\n').first.trim();
  final m = _versionRegex.firstMatch(line);
  if (m == null) throw StateError('Invalid remotes/VERSION: $line (expected X.Y.Z+BUILD)');
  return (int.parse(m.group(2)!), m.group(1)!);
}

void agentVersionWrite(String root, String name, int build) {
  File(versionFilePath(root)).writeAsStringSync('$name+$build\n');
}

String agentVersionStampSync(String root) {
  final (build, _) = agentVersionRead(root);
  return '$build';
}

void agentVersionBump(String root) {
  final (build, name) = agentVersionRead(root);
  agentVersionWrite(root, name, build + 1);
  stdout.writeln('✓ Remote agent version bumped to $name+${build + 1}');
}
