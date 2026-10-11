import 'dart:convert';

import 'package:http/http.dart' as http;

const playApiRoot = 'https://androidpublisher.googleapis.com/androidpublisher/v3/applications';

class RegionsVersionMismatch implements Exception {
  RegionsVersionMismatch(this.latest, this.body);
  final String latest;
  final String body;
  @override
  String toString() => 'Regions version mismatch; latest=$latest';
}

class PlayMonetizationApi {
  PlayMonetizationApi({required this.client, required this.packageName});

  final http.Client client;
  final String packageName;

  String _url(String path, {Map<String, String>? query}) {
    final base = '$playApiRoot/$packageName$path';
    if (query == null || query.isEmpty) return base;
    final q = query.entries.map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}').join('&');
    return '$base?$q';
  }

  Future<Map<String, dynamic>> getJson(String path, {Map<String, String>? query}) async {
    final res = await client.get(Uri.parse(_url(path, query: query)), headers: {'Accept': 'application/json'});
    if (res.statusCode == 404 || res.statusCode == 204) return {};
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw StateError('GET $path failed (${res.statusCode}): ${res.body}');
    }
    if (res.body.trim().isEmpty) return {};
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<void> patchJson(String path, {required Map<String, dynamic> body, required Map<String, String> query}) async {
    final res = await client.patch(
      Uri.parse(_url(path, query: query)),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode(body),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    final latest = parseLatestRegionsVersion(res.body);
    if (latest != null) throw RegionsVersionMismatch(latest, res.body);
    throw StateError('PATCH $path failed (${res.statusCode}): ${res.body}');
  }

  Future<String> discoverRegionsVersion() async {
    for (final path in ['/oneTimeProducts', '/subscriptions']) {
      final list = await getJson(path, query: {'pageSize': '1'});
      final key = path.contains('oneTime') ? 'oneTimeProducts' : 'subscriptions';
      for (final row in list[key] as List<dynamic>? ?? []) {
        final rv = (row as Map<String, dynamic>)['regionsVersion'] as Map<String, dynamic>?;
        final v = rv?['version'] as String?;
        if (v != null && v.isNotEmpty) return v;
      }
    }
    return '2025/02';
  }
}

String? parseLatestRegionsVersion(String body) {
  final m = RegExp(r'versionId=(\d{4}/\d{2})').firstMatch(body);
  if (m != null) return m.group(1);
  final m2 = RegExp(r'latest value is[^0-9]*(\d{4}/\d{2})').firstMatch(body);
  return m2?.group(1);
}

Map<String, dynamic> moneyFromAmount(double amount, String currency) {
  if (currency == 'IDR' || currency == 'JPY' || currency == 'KRW' || currency == 'VND') {
    return {'currencyCode': currency, 'units': amount.round().toString(), 'nanos': 0};
  }
  final cents = (amount * 100).round();
  return {
    'currencyCode': currency,
    'units': (cents ~/ 100).toString(),
    'nanos': (cents % 100) * 10000000,
  };
}

Future<void> patchWithRegionsRetry(
  PlayMonetizationApi api,
  String path, {
  required Map<String, dynamic> body,
  required String updateMask,
  required String regionsVersion,
  required bool allowMissing,
}) async {
  var version = regionsVersion;
  for (var attempt = 0; attempt < 3; attempt++) {
    try {
      await api.patchJson(
        path,
        body: body,
        query: {
          'updateMask': updateMask,
          'regionsVersion.version': version,
          if (allowMissing) 'allowMissing': 'true',
        },
      );
      return;
    } on RegionsVersionMismatch catch (e) {
      version = e.latest;
    }
  }
}
