import 'package:alienai_c35/c/billing/billing_format.dart';
import 'package:alienai_c35/c/pb/c35/billing.pb.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';

class WalletRow {
  WalletRow({
    this.balanceUsd = 0,
    this.balanceIdr = 0,
    this.allow5hUsed = 0,
    this.allow5hLimit = 0,
    this.allowWeeklyUsed = 0,
    this.allowWeeklyLimit = 0,
    this.frontierAllow5hUsed = 0,
    this.frontierAllow5hLimit = 0,
    this.frontierAllowWeeklyUsed = 0,
    this.frontierAllowWeeklyLimit = 0,
    this.billingCurrency = 'IDR',
    this.fxMicroPerUsd = 17630000000,
  });

  final double balanceUsd;
  final double balanceIdr;
  final double allow5hUsed;
  final double allow5hLimit;
  final double allowWeeklyUsed;
  final double allowWeeklyLimit;
  final double frontierAllow5hUsed;
  final double frontierAllow5hLimit;
  final double frontierAllowWeeklyUsed;
  final double frontierAllowWeeklyLimit;
  final String billingCurrency;
  final int fxMicroPerUsd;
}

class AppStore extends ChangeNotifier {
  AppStore._();
  static final AppStore instance = AppStore._();

  BillingAccount? billing;
  BillingPushQuota? quota;
  var thisPcOnRail = false;
  var thisPcPending = false;

  WalletRow get wallet {
    final b = billing;
    if (b == null) return WalletRow();
    return WalletRow(
      balanceUsd: b.balanceUsd,
      balanceIdr: b.balanceIdr,
      allow5hUsed: b.alienAllow5hUsed,
      allow5hLimit: b.alienAllow5hLimit,
      allowWeeklyUsed: b.alienAllowWeeklyUsed,
      allowWeeklyLimit: b.alienAllowWeeklyLimit,
      frontierAllow5hUsed: b.frontierAllow5hUsed,
      frontierAllow5hLimit: b.frontierAllow5hLimit,
      frontierAllowWeeklyUsed: b.frontierAllowWeeklyUsed,
      frontierAllowWeeklyLimit: b.frontierAllowWeeklyLimit,
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

  void billingPut(BillingAccount account, {bool force = false}) {
    final cur = billing;
    if (!force && cur != null && _billingUpdatedTsMs(cur) > _billingUpdatedTsMs(account) && _billingUpdatedTsMs(account) > 0) return;
    var next = account;
    if (cur != null && billingAccountIncomingDowngradesPaid(cur, next)) {
      next = billingAccountPackageRetainPaid(cur, next);
    }
    billing = billingAccountPackageReconcile(next);
    notifyListeners();
  }

  int _billingUpdatedTsMs(BillingAccount account) => account.hasUpdatedTsMs() ? account.updatedTsMs.toInt() : 0;

  void billingBalancePush(BillingPushBalance push) {
    final base = billing ?? BillingAccount(billingCurrency: push.hasCurrency() && push.currency.isNotEmpty ? push.currency : 'IDR');
    billing = billingAccountMerge(base, balance: push);
    notifyListeners();
  }

  void billingQuotaPush(BillingPushQuota push) {
    quota = push;
    if (billing == null) {
      notifyListeners();
      return;
    }
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
      balanceIdr: row.balanceIdr,
      alienAllow5hUsed: row.allow5hUsed,
      alienAllow5hLimit: row.allow5hLimit,
      alienAllowWeeklyUsed: row.allowWeeklyUsed,
      alienAllowWeeklyLimit: row.allowWeeklyLimit,
      frontierAllow5hUsed: row.frontierAllow5hUsed,
      frontierAllow5hLimit: row.frontierAllow5hLimit,
      frontierAllowWeeklyUsed: row.frontierAllowWeeklyUsed,
      frontierAllowWeeklyLimit: row.frontierAllowWeeklyLimit,
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
