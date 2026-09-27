import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:postgres/postgres.dart';

import '../deploy_app/hash_blake3.dart';
import '../deploy_lib.dart';
import 'ffmpeg_version.dart';

class FfmpegWindowsBuildResult {
  FfmpegWindowsBuildResult({
    required this.version,
    required this.versionName,
    required this.zipPath,
    required this.hash,
    required this.size,
  });

  final int version;
  final String versionName;
  final String zipPath;
  final String hash;
  final int size;
}

String ffmpegCacheDir(String root) => p.join(root, '.cache', 'publish', 'ffmpeg-windows');

String ffmpegZipPath(String root, int version) => p.join(ffmpegCacheDir(root), ffmpegWindowsZipFileName(version));

Archive _dirArchive(String rootDir) {
  final root = Directory(rootDir);
  if (!root.existsSync()) throw StateError('FFmpeg directory not found: $rootDir');
  final ffmpegExe = File(p.join(rootDir, 'ffmpeg.exe'));
  if (!ffmpegExe.existsSync()) throw StateError('ffmpeg.exe required at root of $rootDir');
  final archive = Archive();
  for (final ent in root.listSync(recursive: true, followLinks: false)) {
    if (ent is! File) continue;
    final rel = p.relative(ent.path, from: rootDir).replaceAll(r'\', '/');
    archive.addFile(ArchiveFile(rel, ent.lengthSync(), ent.readAsBytesSync()));
  }
  return archive;
}

Future<FfmpegWindowsBuildResult> buildFfmpegWindowsZip({required String ffmpegDir, required int version}) async {
  if (version <= 0) throw StateError('Invalid ffmpeg publish version: $version');
  final root = repoRoot();
  final cache = Directory(ffmpegCacheDir(root));
  cache.createSync(recursive: true);
  final zipPath = ffmpegZipPath(root, version);
  final archive = _dirArchive(p.normalize(ffmpegDir));
  final zipBytes = ZipEncoder().encode(archive);
  if (zipBytes.isEmpty) throw StateError('Failed to encode ffmpeg zip');
  await File(zipPath).writeAsBytes(zipBytes, flush: true);
  final hash = blake3HexOfFile(zipPath, root: root);
  final size = zipBytes.length;
  deployArtifact('ffmpeg_zip', size);
  stdout.writeln('ffmpeg zip v$version hash=$hash size=${formatBytes(size)}');
  return FfmpegWindowsBuildResult(
    version: version,
    versionName: ffmpegWindowsVersionName(version),
    zipPath: zipPath,
    hash: hash,
    size: size,
  );
}

Future<int> ffmpegWindowsNextVersion() async {
  final host = deployEnv('YB_HOST', 'yb-tservers.yugabyte.svc.cluster.local');
  final port = int.tryParse(deployEnv('YB_PORT', '5433')) ?? 5433;
  final database = deployEnv('YB_DATABASE', 'c35');
  final username = deployEnv('YB_USER', 'csa');
  final password = deployEnv('YB_PASSWORD', '');
  if (password.isEmpty) throw StateError('YB_PASSWORD required to read ffmpeg release version');
  final ssl = deployEnv('YB_SSLMODE', 'disable').toLowerCase();
  final conn = await Connection.open(
    Endpoint(host: host, port: port, database: database, username: username, password: password),
    settings: ConnectionSettings(sslMode: (ssl == 'disable' || ssl == 'false') ? SslMode.disable : SslMode.require),
  );
  try {
    final rows = await conn.execute(
      Sql.named(r"SELECT COALESCE((value->>'version')::bigint, 0) AS v FROM ai.config WHERE key = @key"),
      parameters: {'key': ffmpegWindowsConfigKey},
    );
    final current = rows.isEmpty ? 0 : (rows.first[0] as int? ?? 0);
    return current + 1;
  } finally {
    await conn.close();
  }
}
