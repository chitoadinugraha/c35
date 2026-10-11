import 'dart:io';

import 'play_billing_catalog_sync.dart';

/// Sync Play Console subscription + consumable prices from ai.billing_plan_price (x PLAY_MARKUP).
///
/// Dry run (default):
///   dart run deploy_app/play_store_billing_sync.dart
///
/// Push to Play:
///   dart run deploy_app/play_store_billing_sync.dart --apply
///
/// Create missing SKUs (first-time catalog):
///   dart run deploy_app/play_store_billing_sync.dart --apply --create-missing
///
/// Flags: --currency=IDR|USD|all  --regions-version=2025/02
Future<void> main(List<String> args) async {
  try {
    await runPlayBillingCatalogSyncCli(args);
  } catch (e, s) {
    stderr.writeln(e);
    stderr.writeln(s);
    exitCode = 1;
  }
}
