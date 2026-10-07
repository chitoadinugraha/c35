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

  test('billingAccountMerge keeps frontier limits on legacy quota push', () {
    final base = BillingAccount(
      planTier: 'ultra',
      alienAllow5hLimit: 4,
      alienAllowWeeklyLimit: 80,
      frontierAllow5hLimit: 0.8,
      frontierAllowWeeklyLimit: 16,
    );
    final quota = BillingPushQuota(
      alienAllow5hUsed: 0.1,
      alienAllow5hLimit: 4,
      alienAllowWeeklyUsed: 0.2,
      alienAllowWeeklyLimit: 80,
    );
    final merged = billingAccountMerge(base, quota: quota);
    expect(merged.frontierAllow5hLimit, 0.8);
    expect(merged.frontierAllowWeeklyLimit, 16);
  });

  test('billingAccountMerge keeps ultra when paid shell gets freemium quota', () {
    final base = BillingAccount(
      planTier: 'ultra',
      alienAllow5hLimit: 4,
      alienAllowWeeklyLimit: 80,
      frontierAllow5hLimit: 0.8,
      frontierAllowWeeklyLimit: 16,
      balanceIdr: 50000000,
    );
    final quota = BillingPushQuota(
      alienAllow5hUsed: 0.1,
      alienAllow5hLimit: 0,
      alienAllowWeeklyUsed: 0.2,
      alienAllowWeeklyLimit: 0,
      freemiumActive: true,
      freemiumMsgsUsed: 1,
      freemiumMsgsLimit: 30,
    );
    final merged = billingAccountMerge(base, quota: quota);
    expect(merged.planTier, 'ultra');
    expect(merged.alienAllow5hLimit, 4);
    expect(merged.freemiumActive, isFalse);
    expect(merged.balanceIdr, 50000000);
  });

  test('billingAccountMerge restores ultra when quota freemium but paid rings', () {
    final base = BillingAccount(planTier: 'free', freemiumActive: true);
    final quota = BillingPushQuota(
      alienAllow5hUsed: 0,
      alienAllow5hLimit: 4,
      alienAllowWeeklyUsed: 0,
      alienAllowWeeklyLimit: 80,
      freemiumActive: true,
      planExpiresTsMs: Int64(DateTime.now().add(const Duration(days: 365)).millisecondsSinceEpoch),
    );
    final merged = billingAccountMerge(base, quota: quota);
    expect(merged.planTier, 'ultra');
    expect(merged.freemiumActive, isFalse);
  });

  test('billingPushBalanceShouldApply ignores zero balance without timestamp', () {
    final base = BillingAccount(balanceIdr: 50000000, updatedTsMs: Int64(5000));
    final push = BillingPushBalance(balanceIdr: 0);
    expect(billingPushBalanceShouldApply(base, push), isFalse);
    final stamped = BillingPushBalance(balanceIdr: 0, updatedTsMs: Int64(6000));
    expect(billingPushBalanceShouldApply(base, stamped), isTrue);
  });

  test('billingAccountMerge derives frontier limits when missing', () {
    final base = BillingAccount(planTier: 'ultra', alienAllow5hLimit: 4, alienAllowWeeklyLimit: 80);
    final quota = BillingPushQuota(
      alienAllow5hUsed: 0,
      alienAllow5hLimit: 4,
      alienAllowWeeklyUsed: 0,
      alienAllowWeeklyLimit: 80,
    );
    final merged = billingAccountMerge(base, quota: quota);
    expect(merged.frontierAllow5hLimit, 0.8);
    expect(merged.frontierAllowWeeklyLimit, 16);
  });
}
