import 'package:alienai_c35/c/billing/billing_format.dart';
import 'package:alienai_c35/c/pb/c35/billing.pb.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';

class WalletRow {
  WalletRow({
    this.balanceUsd = 0,
    this.allow5hUsed = 0,
    this.allow5hLimit = 0,
    this.allowWeeklyUsed = 0,
    this.allowWeeklyLimit = 0,
    this.billingCurrency = 'IDR',
    this.fxMicroPerUsd = 17630000000,
  });

  final double balanceUsd;
  final double allow5hUsed;
  final double allow5hLimit;
  final double allowWeeklyUsed;
  final double allowWeeklyLimit;
  final String billingCurrency;
  final int fxMicroPerUsd;
}

class AppStore extends ChangeNotifier {
  AppStore._();
  static final AppStore instance = AppStore._();

  BillingAccount? billing;
  var thisPcOnRail = false;
  var thisPcPending = false;

  WalletRow get wallet {
    final b = billing;
    if (b == null) return WalletRow();
    return WalletRow(
      balanceUsd: b.balanceUsd,
      allow5hUsed: b.alienAllow5hUsed,
      allow5hLimit: b.alienAllow5hLimit,
      allowWeeklyUsed: b.alienAllowWeeklyUsed,
      allowWeeklyLimit: b.alienAllowWeeklyLimit,
      billingCurrency: b.billingCurrency.isNotEmpty ? b.billingCurrency : 'IDR',
      fxMicroPerUsd: b.hasFxMicroPerUsd() ? b.fxMicroPerUsd.toInt() : 17630000000,
    );
  }

  String get planTier => billing?.planTier.isNotEmpty == true ? billing!.planTier : 'free';

  bool get freemiumActive => billingFreemiumActive(billing);

  String get meterState {
    final b = billing;
    if (b == null) return 'green';
    return billingMeterState(b.alienAllow5hUsed, b.alienAllow5hLimit);
  }

  void billingPut(BillingAccount account) {
    billing = account;
    notifyListeners();
  }

  void billingBalancePush(BillingPushBalance push) {
    if (billing == null) return;
    billing = billingAccountMerge(billing!, balance: push);
    notifyListeners();
  }

  void billingQuotaPush(BillingPushQuota push) {
    if (billing == null) return;
    billing = billingAccountMerge(billing!, quota: push);
    notifyListeners();
  }

  void billingCommissionPush(BillingPushCommission push) {
    if (billing == null) return;
    billing = billingAccountMerge(billing!, commission: push);
    notifyListeners();
  }

  void walletPut(WalletRow row) {
    billing = BillingAccount(
      balanceUsd: row.balanceUsd,
      alienAllow5hUsed: row.allow5hUsed,
      alienAllow5hLimit: row.allow5hLimit,
      alienAllowWeeklyUsed: row.allowWeeklyUsed,
      alienAllowWeeklyLimit: row.allowWeeklyLimit,
      billingCurrency: row.billingCurrency,
      fxMicroPerUsd: Int64(row.fxMicroPerUsd),
    );
    notifyListeners();
  }

  void thisPcAllow({int? id, String name = '', bool pending = false}) {
    thisPcOnRail = true;
    thisPcPending = pending;
    notifyListeners();
  }

  void thisPcDeny() {
    thisPcOnRail = false;
    thisPcPending = false;
    notifyListeners();
  }

  void thisPcTryAdopt() {}
}
