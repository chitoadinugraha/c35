import 'dart:convert';
import 'dart:io';

import 'package:postgres/postgres.dart';

import '../deploy_lib.dart';
import 's3_upload.dart';

SslMode _ybSslMode() {
  final raw = deployEnv('YB_SSLMODE', 'disable').toLowerCase();
  return (raw == 'disable' || raw == 'false' || raw == '0' || raw == 'no') ? SslMode.disable : SslMode.require;
}

Future<Connection> _openPg() async {
  final host = deployEnv('YB_HOST', 'yb-tservers.yugabyte.svc.cluster.local');
  final port = int.tryParse(deployEnv('YB_PORT', '5433')) ?? 5433;
  final database = deployEnv('YB_DATABASE', 'c35');
  final username = deployEnv('YB_USER', 'csa');
  final password = deployEnv('YB_PASSWORD', '');
  if (password.isEmpty) throw StateError('YB_PASSWORD required to register CAS blob');
  return Connection.open(
    Endpoint(host: host, port: port, database: database, username: username, password: password),
    settings: ConnectionSettings(sslMode: _ybSslMode(), connectTimeout: const Duration(seconds: 15)),
  );
}

Future<void> casRegisterS3Blob({required String hash, required int size, required String mimeType}) async {
  final h = hash.trim().toLowerCase();
  if (h.length != 64) throw StateError('Invalid blake3 hash: $h');
  final loc = jsonEncode({'key': 'fs/$h'});
  final conn = await _openPg();
  try {
    await conn.execute(
      Sql.named(r'''
        INSERT INTO ai.file_blob_meta
          (hash_blake3, size_bytes, mime_type, is_inline, store, loc, variants)
        VALUES (@hash, @size, @mime, false, 's3', @loc::jsonb, '{}')
        ON CONFLICT (hash_blake3) DO NOTHING
      '''),
      parameters: {'hash': h, 'size': size, 'mime': mimeType, 'loc': loc},
    );
  } finally {
    await conn.close();
  }
}

Future<void> casUploadLargeFileViaS3({
  required File file,
  required String hash,
  required String mimeType,
}) async {
  final cfg = S3UploadConfig.fromEnv();
  final key = 'fs/${hash.trim().toLowerCase()}';
  final size = file.lengthSync();
  await runStep('Upload blob to S3 ($key)', () async {
    await s3PutFile(cfg: cfg, key: key, file: file, cacheControl: 'public, max-age=31536000, immutable');
  });
  await runStep('Register CAS meta in Yugabyte', () => casRegisterS3Blob(hash: hash, size: size, mimeType: mimeType));
  stdout.writeln('CAS S3 upload hash=$hash size=$size');
}