import 'package:alienai_c35/c/billing/billing_format.dart';
import 'package:alienai_c35/c/pb/c35/billing.pb.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('billingPushBalanceIsStale ignores older push', () {
    final base = BillingAccount(updatedTsMs: Int64(5000));
    final push = BillingPushBalance(updatedTsMs: Int64(4000), balanceIdr: 999);
    expect(billingPushBalanceIsStale(base, push), isTrue);
    final merged = billingAccountMerge(base, balance: push);
    expect(merged.balanceIdr, 0);
  });

  test('billingAccountMerge applies newer push', () {
    final base = BillingAccount(updatedTsMs: Int64(1000), balanceIdr: 50000);
    final push = BillingPushBalance(updatedTsMs: Int64(2000), balanceIdr: 40000, balanceUsd: 10, currency: 'IDR');
    final merged = billingAccountMerge(base, balance: push);
    expect(merged.balanceIdr, 40000);
    expect(merged.updatedTsMs.toInt(), 2000);
  });

  test('billingWalletBalanceLabel uses IDR leg', () {
    final account = BillingAccount(balanceUsd: 500, balanceIdr: 60000, billingCurrency: 'IDR');
    expect(billingWalletBalanceLabel(account, 'IDR'), 'IDR 60.000');
  });
}
