import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../deploy_lib.dart';

class S3UploadConfig {
  S3UploadConfig({
    required this.endpoint,
    required this.bucket,
    required this.accessKey,
    required this.secretKey,
    required this.region,
    required this.secure,
  });

  final String endpoint;
  final String bucket;
  final String accessKey;
  final String secretKey;
  final String region;
  final bool secure;

  static S3UploadConfig fromEnv() {
    String req(String key) {
      final v = deployEnv(key);
      if (v.isEmpty) throw StateError('$key required for S3 upload');
      return v;
    }

    final secureRaw = deployEnv('S3_SECURE').toLowerCase();
    final secure = secureRaw.isEmpty || secureRaw == 'true' || secureRaw == '1';
    return S3UploadConfig(
      endpoint: req('S3_ENDPOINT').replaceAll(RegExp(r'^https?://'), '').replaceAll(RegExp(r'/+$'), ''),
      bucket: req('S3_BUCKET'),
      accessKey: req('S3_ACCESS_KEY'),
      secretKey: req('S3_SECRET_KEY'),
      region: deployEnv('S3_REGION').isNotEmpty ? deployEnv('S3_REGION') : 'us-east-1',
      secure: secure,
    );
  }

  String get scheme => secure ? 'https' : 'http';

  Uri objectUri(String key) => Uri.parse('$scheme://$endpoint/$bucket/${_normalizeKey(key)}');
}

String _normalizeKey(String key) => key.replaceAll(RegExp(r'^/+'), '');

String _mimeFor(String path) {
  final lower = path.toLowerCase();
  if (lower.endsWith('.html')) return 'text/html; charset=utf-8';
  if (lower.endsWith('.js')) return 'application/javascript';
  if (lower.endsWith('.css')) return 'text/css';
  if (lower.endsWith('.json')) return 'application/json';
  if (lower.endsWith('.wasm')) return 'application/wasm';
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.svg')) return 'image/svg+xml';
  if (lower.endsWith('.ico')) return 'image/x-icon';
  if (lower.endsWith('.woff')) return 'font/woff';
  if (lower.endsWith('.woff2')) return 'font/woff2';
  if (lower.endsWith('.txt')) return 'text/plain; charset=utf-8';
  if (lower.endsWith('.map')) return 'application/json';
  return 'application/octet-stream';
}

String _cacheControlFor(String relPath) {
  final name = p.basename(relPath).toLowerCase();
  if (name == 'index.html' || name == 'flutter_service_worker.js') return 'public, max-age=60';
  return 'public, max-age=31536000, immutable';
}

String _amzDate(DateTime utc) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${utc.year}${two(utc.month)}${two(utc.day)}T${two(utc.hour)}${two(utc.minute)}${two(utc.second)}Z';
}

String _dateStamp(DateTime utc) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${utc.year}${two(utc.month)}${two(utc.day)}';
}

List<int> _hmac(List<int> key, String data) => Hmac(sha256, key).convert(utf8.encode(data)).bytes;

List<int> _signingKey(String secret, String dateStamp, String region, String service) {
  final kDate = _hmac(utf8.encode('AWS4$secret'), dateStamp);
  final kRegion = _hmac(kDate, region);
  final kService = _hmac(kRegion, service);
  return _hmac(kService, 'aws4_request');
}

Future<void> s3PutObject({
  required S3UploadConfig cfg,
  required String key,
  required List<int> body,
  required String contentType,
  required String cacheControl,
}) async {
  final normalized = _normalizeKey(key);
  final uri = cfg.objectUri(normalized);
  final now = DateTime.now().toUtc();
  final amzDate = _amzDate(now);
  final dateStamp = _dateStamp(now);
  final payloadHash = sha256.convert(body).toString();
  final canonicalUri = '/${cfg.bucket}/$normalized';
  final canonicalHeaders =
      'host:${uri.host}${uri.hasPort ? ':${uri.port}' : ''}\n'
      'x-amz-content-sha256:$payloadHash\n'
      'x-amz-date:$amzDate\n';
  const signedHeaders = 'host;x-amz-content-sha256;x-amz-date';
  final canonicalRequest = [
    'PUT',
    canonicalUri,
    '',
    canonicalHeaders,
    signedHeaders,
    payloadHash,
  ].join('\n');
  final credentialScope = '$dateStamp/${cfg.region}/s3/aws4_request';
  final stringToSign = [
    'AWS4-HMAC-SHA256',
    amzDate,
    credentialScope,
    sha256.convert(utf8.encode(canonicalRequest)).toString(),
  ].join('\n');
  final signature = Hmac(sha256, _signingKey(cfg.secretKey, dateStamp, cfg.region, 's3'))
      .convert(utf8.encode(stringToSign))
      .toString();
  final authorization =
      'AWS4-HMAC-SHA256 Credential=${cfg.accessKey}/$credentialScope, '
      'SignedHeaders=$signedHeaders, Signature=$signature';

  final resp = await http.put(
    uri,
    headers: {
      'Host': uri.host + (uri.hasPort ? ':${uri.port}' : ''),
      'Content-Type': contentType,
      'Cache-Control': cacheControl,
      'x-amz-content-sha256': payloadHash,
      'x-amz-date': amzDate,
      'Authorization': authorization,
      'Content-Length': '${body.length}',
    },
    body: body is Uint8List ? body : Uint8List.fromList(body),
  );
  if (resp.statusCode < 200 || resp.statusCode >= 300) {
    throw StateError('S3 PUT $normalized failed (${resp.statusCode}): ${resp.body}');
  }
}

Future<void> s3PutFile({
  required S3UploadConfig cfg,
  required String key,
  required File file,
  required String cacheControl,
}) async {
  final bytes = await file.readAsBytes();
  await s3PutObject(cfg: cfg, key: key, body: bytes, contentType: _mimeFor(file.path), cacheControl: cacheControl);
}

Future<int> s3SyncDir({
  required S3UploadConfig cfg,
  required String localDir,
  required String prefix,
}) async {
  final root = Directory(localDir);
  if (!root.existsSync()) throw StateError('Directory not found: $localDir');
  final base = p.normalize(root.absolute.path);
  final prefixNorm = _normalizeKey(prefix).replaceAll(RegExp(r'/+$'), '');
  var count = 0;
  await for (final entity in root.list(recursive: true, followLinks: false)) {
    if (entity is! File) continue;
    final abs = p.normalize(entity.absolute.path);
    final rel = p.relative(abs, from: base).replaceAll('\\', '/');
    final key = '$prefixNorm/$rel';
    await s3PutFile(cfg: cfg, key: key, file: entity, cacheControl: _cacheControlFor(rel));
    count++;
  }
  return count;
}

Future<void> s3UploadWebBuild({
  required int versionCode,
  required String webBuildDir,
}) async {
  final cfg = S3UploadConfig.fromEnv();
  final versioned = await runStep('Upload Flutter web → app/web/$versionCode/', () async {
    return s3SyncDir(cfg: cfg, localDir: webBuildDir, prefix: 'app/web/$versionCode');
  });
  stdout.writeln('✓ S3 app/web/$versionCode/ ($versioned files, ${dirSizeLabel(webBuildDir)})');
  final current = await runStep('Promote Flutter web → app/web/current/', () async {
    return s3SyncDir(cfg: cfg, localDir: webBuildDir, prefix: 'app/web/current');
  });
  stdout.writeln('✓ S3 app/web/current/ ($current files, ${dirSizeLabel(webBuildDir)})');
}
