import 'dart:convert';
import 'dart:io';
import 'package:googleapis_auth/auth_io.dart';
import '../deploy_app/deploy_app_lib.dart';
import '../deploy_lib.dart';
Future<void> main() async {
  deployLoadEnvLocal();
  final creds = ServiceAccountCredentials.fromJson(await playStoreCredentialsJson());
  final c = await clientViaServiceAccount(creds, ['https://www.googleapis.com/auth/androidpublisher']);
  const pkg = 'id.alienai';
  final root = 'https://androidpublisher.googleapis.com/androidpublisher/v3/applications/$pkg';
  final subs = <String>[];
  var token = '';
  do {
    final q = token.isEmpty ? '?pageSize=100' : '?pageSize=100&pageToken=$token';
    final res = await c.get(Uri.parse('$root/subscriptions$q'));
    final map = jsonDecode(res.body) as Map<String, dynamic>;
    for (final s in map['subscriptions'] as List<dynamic>? ?? []) {
      subs.add((s as Map)['productId'] as String);
    }
    token = map['nextPageToken'] as String? ?? '';
  } while (token.isNotEmpty);
  final otps = <String>[];
  token = '';
  do {
    final q = token.isEmpty ? '?pageSize=100' : '?pageSize=100&pageToken=$token';
    final res = await c.get(Uri.parse('$root/oneTimeProducts$q'));
    if (res.statusCode == 204 || res.body.trim().isEmpty) break;
    final map = jsonDecode(res.body) as Map<String, dynamic>;
    for (final p in map['oneTimeProducts'] as List<dynamic>? ?? []) {
      otps.add((p as Map)['productId'] as String);
    }
    token = map['nextPageToken'] as String? ?? '';
  } while (token.isNotEmpty);
  stdout.writeln('subscriptions listed: ${subs.length} unique: ${subs.toSet().length}');
  stdout.writeln('one-time listed: ${otps.length} unique: ${otps.toSet().length}');
  var dupBp = false;
  for (final id in subs) {
    final res = await c.get(Uri.parse('$root/subscriptions/$id'));
    final sub = jsonDecode(res.body) as Map<String, dynamic>;
    final plans = sub['basePlans'] as List<dynamic>? ?? [];
    final ids = <String>[];
    for (final bp in plans) {
      ids.add((bp as Map)['basePlanId'] as String);
    }
    final dups = ids.where((x) => ids.where((y) => y == x).length > 1).toSet();
    if (dups.isNotEmpty) { dupBp = true; stdout.writeln('DUP basePlan $id: $dups (all: $ids)'); }
    String? idPrice;
    for (final bp in plans) {
      for (final rc in (bp as Map)['regionalConfigs'] as List<dynamic>? ?? []) {
        final r = rc as Map;
        if (r['regionCode'] == 'ID') {
          final pr = r['price'] as Map?;
          idPrice = pr == null ? null : '${pr['units']} ${pr['currencyCode']}';
        }
      }
    }
    stdout.writeln('  $id basePlans=${ids.join(',')} ID price=$idPrice');
  }
  for (final id in otps) {
    final res = await c.get(Uri.parse('$root/oneTimeProducts/$id'));
    final p = jsonDecode(res.body) as Map<String, dynamic>;
    final opts = p['purchaseOptions'] as List<dynamic>? ?? [];
    if (opts.length > 1) stdout.writeln('WARN $id has ${opts.length} purchaseOptions');
    String? idPrice;
    for (final rc in (opts.first as Map)['regionalPricingAndAvailabilityConfigs'] as List<dynamic>? ?? []) {
      final r = rc as Map;
      if (r['regionCode'] == 'ID') {
        final pr = r['price'] as Map?;
        idPrice = pr == null ? null : '${pr['units']} ${pr['currencyCode']}';
      }
    }
    stdout.writeln('  $id ID price=$idPrice opts=${opts.length}');
  }
  if (!dupBp) stdout.writeln('No duplicate basePlanId per subscription.');
  c.close();
}