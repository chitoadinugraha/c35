import 'dart:io';

import 'package:path/path.dart' as p;

import '../deploy_lib.dart';

String hashBlake3ToolDir(String root) => p.join(root, '_', 'scripts', 'deploy', 'tools', 'hash_blake3');

String hashBlake3Exe(String root) => p.join(root, '.cache', 'rust', 'hash_blake3', 'release', 'hash_blake3.exe');

void hashBlake3ToolBuild(String root) {
  final target = p.join(root, '.cache', 'rust', 'hash_blake3');
  final proc = Process.runSync(
    'cargo',
    ['build', '--release', '--manifest-path', p.join(hashBlake3ToolDir(root), 'Cargo.toml')],
    environment: {...Platform.environment, 'CARGO_TARGET_DIR': target},
    runInShell: Platform.isWindows,
  );
  if (proc.exitCode != 0) {
    stderr.write(proc.stderr);
    throw StateError('hash_blake3 build failed (exit ${proc.exitCode})');
  }
}

String blake3HexOfFile(String path, {required String root}) {
  hashBlake3ToolBuild(root);
  final exe = hashBlake3Exe(root);
  final proc = Process.runSync(exe, [path], runInShell: false);
  if (proc.exitCode != 0) throw StateError('hash_blake3 failed: ${proc.stderr}');
  return '${proc.stdout}'.trim().toLowerCase();
}
