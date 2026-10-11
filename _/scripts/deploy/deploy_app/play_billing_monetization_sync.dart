import 'dart:io';

import 'package:googleapis_auth/auth_io.dart';

import '../deploy_lib.dart';
import 'deploy_app_lib.dart';
import 'play_billing_catalog.dart';
import 'play_billing_monetization_api.dart';

const _scope = 'https://www.googleapis.com/auth/androidpublisher';

Future<void> runPlayBillingCatalogSyncCli(List<String> args) async {
  deployLoadEnvLocal();
  var apply = false;
  var createMissing = false;
  var currency = 'IDR';
  String? regionsVersion;
  for (final arg in args) {
    if (arg == '--apply') apply = true;
    else if (arg == '--create-missing') createMissing = true;
    else if (arg.startsWith('--currency=')) currency = arg.substring(11).trim().toUpperCase();
    else if (arg.startsWith('--regions-version=')) regionsVersion = arg.substring(18).trim();
    else if (arg != '--help' && arg != '-h') throw ArgumentError('Unknown flag: $arg');
  }
  if (currency == 'ALL') currency = 'all';
  if (currency != 'IDR' && currency != 'USD' && currency != 'all') {
    throw ArgumentError('--currency must be IDR, USD, or all');
  }

  final package = Platform.environment['PLAY_STORE_PACKAGE_NAME'] ?? playStorePackageName;
  final items = await loadPlayBillingCatalog(currencyFilter: currency);
  printPlayCatalogSummary(items);

  final creds = ServiceAccountCredentials.fromJson(await playStoreCredentialsJson());
  final client = await clientViaServiceAccount(creds, [_scope]);
  final api = PlayMonetizationApi(client: client, packageName: package);
  regionsVersion ??= deployEnv('PLAY_REGIONS_VERSION', '');
  if (regionsVersion.isEmpty) {
    regionsVersion = await api.discoverRegionsVersion();
    stdout.writeln('Resolved regionsVersion=$regionsVersion');
  }

  for (final item in items) {
    if (item.kind == PlayCatalogKind.plan) {
      await _syncPlan(api, item, regionsVersion!, apply, createMissing);
    } else {
      await _syncCredit(api, item, regionsVersion!, apply, createMissing);
    }
  }
  client.close();
  stdout.writeln(apply ? 'Done (changes applied).' : 'Dry run complete (no API writes).');
}


Future<void> _syncPlan(PlayMonetizationApi api, PlayCatalogItem item, String rv, bool apply, bool createMissing) async {
  final path = '/subscriptions/${item.productId}';
  final existing = await api.getJson(path);
  if (existing.isEmpty && !createMissing) {
    stdout.writeln('[skip] subscription ${item.productId} not in Play (use --create-missing)');
    return;
  }
  final body = existing.isEmpty ? _newSub(item) : _mergeSub(existing, item, createMissing);
  if (body == null) return;
  _log('subscription', item, _subPrice(existing, item.basePlanId, item.regionCode));
  if (!apply) return;
  await patchWithRegionsRetry(api, path, body: body, updateMask: 'basePlans', regionsVersion: rv, allowMissing: existing.isEmpty);
  stdout.writeln('  applied subscription ${item.productId}');
}

Future<void> _syncCredit(PlayMonetizationApi api, PlayCatalogItem item, String rv, bool apply, bool createMissing) async {
  final getPath = '/oneTimeProducts/${item.productId}';
  final patchPath = '/onetimeproducts/${item.productId}';
  final existing = await api.getJson(getPath);
  if (existing.isEmpty && !createMissing) {
    stdout.writeln('[skip] one-time ${item.productId} not in Play (use --create-missing)');
    return;
  }
  final body = existing.isEmpty ? _newOtp(item) : _mergeOtp(existing, item);
  _log('one-time', item, _otpPrice(existing, item.regionCode));
  if (!apply) return;
  await patchWithRegionsRetry(api, patchPath, body: body, updateMask: 'purchaseOptions', regionsVersion: rv, allowMissing: existing.isEmpty);
  stdout.writeln('  applied one-time ${item.productId}');
}

void _log(String kind, PlayCatalogItem item, String? current) {
  final p = item.storePrice.toStringAsFixed(item.currency == 'IDR' ? 0 : 2);
  stdout.writeln('$kind ${item.productId} ${item.regionCode}: ${current ?? '(none)'} -> $p ${item.currency}');
}


Map<String, dynamic>? _mergeSub(Map<String, dynamic> existing, PlayCatalogItem item, bool createMissing) {
  final out = Map<String, dynamic>.from(existing);
  final plans = (out['basePlans'] as List<dynamic>? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  var found = false;
  for (final bp in plans) {
    if (bp['basePlanId'] != item.basePlanId) continue;
    found = true;
    final configs = (bp['regionalConfigs'] as List<dynamic>? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    _setPrice(configs, item, subscription: true);
    bp['regionalConfigs'] = configs;
  }
  if (!found) {
    if (!createMissing) {
      stdout.writeln('[skip] ${item.productId}: base plan ${item.basePlanId} missing');
      return null;
    }
    plans.add(_basePlan(item));
  }
  out['basePlans'] = plans;
  out.remove('regionsVersion');
  return out;
}

Map<String, dynamic> _mergeOtp(Map<String, dynamic> existing, PlayCatalogItem item) {
  final out = Map<String, dynamic>.from(existing);
  final options = (out['purchaseOptions'] as List<dynamic>? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  if (options.isEmpty) throw StateError('${item.productId}: no purchaseOptions');
  final opt = options.first;
  final configs = (opt['regionalPricingAndAvailabilityConfigs'] as List<dynamic>? ?? [])
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList();
  _setPrice(configs, item, subscription: false);
  opt['regionalPricingAndAvailabilityConfigs'] = configs;
  out['purchaseOptions'] = options;
  out.remove('regionsVersion');
  return out;
}

void _setPrice(List<Map<String, dynamic>> configs, PlayCatalogItem item, {required bool subscription}) {
  for (final rc in configs) {
    if (rc['regionCode'] == item.regionCode) {
      rc['price'] = moneyFromAmount(item.storePrice, item.currency);
      if (subscription) rc['newSubscriberAvailability'] = rc['newSubscriberAvailability'] ?? true;
      else rc['availability'] = rc['availability'] ?? 'AVAILABLE';
      return;
    }
  }
  configs.add({
    'regionCode': item.regionCode,
    if (subscription) 'newSubscriberAvailability': true else 'availability': 'AVAILABLE',
    'price': moneyFromAmount(item.storePrice, item.currency),
  });
}

Map<String, dynamic> _newSub(PlayCatalogItem item) => {
      'productId': item.productId,
      'listings': [_listing(item.listingTitle, 'Alien AI subscription')],
      'basePlans': [_basePlan(item)],
    };

Map<String, dynamic> _basePlan(PlayCatalogItem item) => {
      'basePlanId': item.basePlanId,
      'state': 'DRAFT',
      'autoRenewingBasePlanType': {
        'billingPeriodDuration': billingPeriodIso(item.billingPeriod),
        'gracePeriodDuration': 'P0D',
        'resubscribeState': 'RESUBSCRIBE_STATE_ACTIVE',
        'prorationMode': 'SUBSCRIPTION_PRORATION_MODE_CHARGE_ON_NEXT_BILLING_DATE',
      },
      'regionalConfigs': [
        {
          'regionCode': item.regionCode,
          'newSubscriberAvailability': true,
          'price': moneyFromAmount(item.storePrice, item.currency),
        },
      ],
    };

Map<String, dynamic> _newOtp(PlayCatalogItem item) {
  final price = moneyFromAmount(item.storePrice, item.currency);
  return {
    'productId': item.productId,
    'listings': [_listing(item.listingTitle, 'Alien AI wallet top-up')],
    'purchaseOptions': [
      {
        'purchaseOptionId': 'default',
        'buyOption': {'legacyCompatible': true, 'multiQuantityEnabled': false},
        'regionalPricingAndAvailabilityConfigs': [
          {'regionCode': item.regionCode, 'availability': 'AVAILABLE', 'price': price},
        ],
        if (item.currency == 'USD')
          'newRegionsConfig': {
            'availability': 'AVAILABLE',
            'usdPrice': price,
            'eurPrice': moneyFromAmount(item.storePrice * 0.92, 'EUR'),
          },
      },
    ],
  };
}

Map<String, dynamic> _listing(String title, String desc) => {
      'languageCode': 'en-US',
      'title': title.length > 55 ? title.substring(0, 55) : title,
      'description': desc.length > 200 ? desc.substring(0, 200) : desc,
    };

String? _subPrice(Map<String, dynamic> sub, String basePlanId, String region) => _moneyLabel(_findSubMoney(sub, basePlanId, region));

String? _otpPrice(Map<String, dynamic> product, String region) => _moneyLabel(_findOtpMoney(product, region));

Map<String, dynamic>? _findSubMoney(Map<String, dynamic> sub, String basePlanId, String region) {
  for (final bp in sub['basePlans'] as List<dynamic>? ?? []) {
    final m = bp as Map<String, dynamic>;
    if (m['basePlanId'] != basePlanId) continue;
    for (final rc in m['regionalConfigs'] as List<dynamic>? ?? []) {
      final r = rc as Map<String, dynamic>;
      if (r['regionCode'] == region) return r['price'] as Map<String, dynamic>?;
    }
  }
  return null;
}

Map<String, dynamic>? _findOtpMoney(Map<String, dynamic> product, String region) {
  final opts = product['purchaseOptions'] as List<dynamic>? ?? [];
  if (opts.isEmpty) return null;
  for (final rc in (opts.first as Map)['regionalPricingAndAvailabilityConfigs'] as List<dynamic>? ?? []) {
    final r = rc as Map<String, dynamic>;
    if (r['regionCode'] == region) return r['price'] as Map<String, dynamic>?;
  }
  return null;
}

String? _moneyLabel(Map<String, dynamic>? price) {
  if (price == null) return null;
  final units = int.tryParse('${price['units']}') ?? 0;
  final nanos = (price['nanos'] as int?) ?? 0;
  return '${units + nanos / 1e9} ${price['currencyCode']}';
}
