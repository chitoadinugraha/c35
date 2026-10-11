import 'dart:io';

import 'package:postgres/postgres.dart';

import '../deploy_lib.dart';

const playBillingMarkup = 1.15;
const playPlanPrefix = 'id.alienai.plan.';
const playCreditPrefix = 'id.alienai.credit.';
const playUserPlanSlugs = ['lite', 'plus', 'pro', 'ultra'];
const playCreditPacksIdr = [50000.0, 100000.0, 200000.0, 500000.0, 1000000.0];
const playCreditPacksUsd = [5.0, 10.0, 25.0, 50.0, 100.0];

enum PlayCatalogKind { plan, credit }

class PlayCatalogItem {
  PlayCatalogItem({
    required this.productId,
    required this.kind,
    required this.currency,
    required this.regionCode,
    required this.storePrice,
    this.planSlug = '',
    this.billingPeriod = '',
    this.basePlanId = '',
    this.webPrice = 0,
    this.listingTitle = '',
  });

  final String productId;
  final PlayCatalogKind kind;
  final String currency;
  final String regionCode;
  final double storePrice;
  final String planSlug;
  final String billingPeriod;
  final String basePlanId;
  final double webPrice;
  final String listingTitle;
}

double playPriceIdr(double webIdr) => (webIdr * playBillingMarkup).roundToDouble();

double playStorePriceUsd(double webUsd) => ((webUsd * playBillingMarkup) * 100).round() / 100;

String defaultBasePlanId(String billingPeriod) {
  final p = billingPeriod.trim().toLowerCase();
  if (p == 'yearly') return 'yearly';
  return 'monthly';
}

String billingPeriodIso(String billingPeriod) {
  final p = billingPeriod.trim().toLowerCase();
  if (p == 'yearly') return 'P1Y';
  return 'P1M';
}

SslMode _ybSslMode() {
  final raw = deployEnv('YB_SSLMODE', 'disable').toLowerCase();
  return (raw == 'disable' || raw == 'false' || raw == '0' || raw == 'no') ? SslMode.disable : SslMode.require;
}

Future<Connection> openBillingCatalogPg() async {
  final host = deployEnv('YB_HOST', '127.0.0.1');
  final port = int.tryParse(deployEnv('YB_PORT', '5433')) ?? 5433;
  final database = deployEnv('YB_DATABASE', 'c35');
  final username = deployEnv('YB_USER', 'csa');
  final password = deployEnv('YB_PASSWORD', '');
  if (password.isEmpty) {
    throw StateError(
      'YB_PASSWORD required to load plan prices from ai.billing_plan_price.\n'
      'Set it in .env.local or the environment (same as other deploy scripts).',
    );
  }
  return Connection.open(
    Endpoint(host: host, port: port, database: database, username: username, password: password),
    settings: ConnectionSettings(sslMode: _ybSslMode(), connectTimeout: const Duration(seconds: 20)),
  );
}

Future<List<PlayCatalogItem>> loadPlayBillingCatalog({required String currencyFilter}) async {
  final wantIdr = currencyFilter == 'all' || currencyFilter == 'IDR';
  final wantUsd = currencyFilter == 'all' || currencyFilter == 'USD';
  final items = <PlayCatalogItem>[];

  final conn = await openBillingCatalogPg();
  try {
    if (wantIdr) {
      items.addAll(await _loadPlans(conn, 'IDR', 'ID'));
      for (final credit in playCreditPacksIdr) {
        final store = playPriceIdr(credit);
        items.add(
          PlayCatalogItem(
            productId: '$playCreditPrefix${credit.round()}',
            kind: PlayCatalogKind.credit,
            currency: 'IDR',
            regionCode: 'ID',
            storePrice: store,
            webPrice: credit,
            listingTitle: 'Alien AI credits ${credit.round()} IDR',
          ),
        );
      }
    }
    if (wantUsd) {
      items.addAll(await _loadPlans(conn, 'USD', 'US'));
      for (final credit in playCreditPacksUsd) {
        final store = playStorePriceUsd(credit);
        items.add(
          PlayCatalogItem(
            productId: '${playCreditPrefix}usd.$credit',
            kind: PlayCatalogKind.credit,
            currency: 'USD',
            regionCode: 'US',
            storePrice: store,
            webPrice: credit,
            listingTitle: 'Alien AI credits \$$credit',
          ),
        );
      }
    }
  } finally {
    await conn.close();
  }
  return items;
}

Future<List<PlayCatalogItem>> _loadPlans(Connection conn, String currency, String regionCode) async {
  final rows = await conn.execute(
    Sql.named('''
      SELECT p.plan_slug, p.billing_period, p.amount::float8 AS amount, bp.name
      FROM ai.billing_plan_price p
      JOIN ai.billing_plan bp ON bp.slug = p.plan_slug
      WHERE p.currency = @currency AND p.is_active = TRUE
        AND bp.scope = 'user' AND bp.is_active = TRUE
        AND p.plan_slug IN ('lite', 'plus', 'pro', 'ultra')
      ORDER BY bp.sort_order, p.billing_period
    '''),
    parameters: {'currency': currency},
  );
  final out = <PlayCatalogItem>[];
  for (final row in rows) {
    final slug = row[0] as String;
    final period = row[1] as String;
    final web = (row[2] as double?) ?? 0;
    final name = (row[3] as String?) ?? slug;
    if (web <= 0) continue;
    final store = currency == 'USD' ? playStorePriceUsd(web) : playPriceIdr(web);
    out.add(
      PlayCatalogItem(
        productId: '$playPlanPrefix$slug.$period',
        kind: PlayCatalogKind.plan,
        currency: currency,
        regionCode: regionCode,
        storePrice: store,
        planSlug: slug,
        billingPeriod: period,
        basePlanId: defaultBasePlanId(period),
        webPrice: web,
        listingTitle: 'Alien AI $name (${period == 'yearly' ? 'yearly' : 'monthly'})',
      ),
    );
  }
  return out;
}

void printPlayCatalogSummary(List<PlayCatalogItem> items) {
  stdout.writeln('Play billing catalog (${items.length} SKUs):');
  for (final item in items) {
    final kind = item.kind == PlayCatalogKind.plan ? 'plan' : 'credit';
    stdout.writeln(
      '  $kind ${item.productId} ${item.regionCode} ${item.currency} '
      'store=${item.storePrice.toStringAsFixed(item.currency == 'IDR' ? 0 : 2)} '
      '(web=${item.webPrice})',
    );
  }
}
