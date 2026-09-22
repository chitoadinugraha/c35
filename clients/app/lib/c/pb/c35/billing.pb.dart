// This is a generated file - do not edit.
//
// Generated from c35/billing.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'referral.pb.dart' as $0;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class BillingProfile extends $pb.GeneratedMessage {
  factory BillingProfile({
    $fixnum.Int64? id,
    $fixnum.Int64? ownerIid,
    $core.String? planTier,
    $core.String? defaultWalletCurrency,
    $core.double? alienAllow5hUsed,
    $core.double? alienAllow5hLimit,
    $core.double? alienAllowWeeklyUsed,
    $core.double? alienAllowWeeklyLimit,
    $fixnum.Int64? window5hStartMs,
    $fixnum.Int64? windowWeeklyStartMs,
    $core.double? commissionAvailableUsd,
    $core.double? commissionEarnedUsd,
    $core.double? commissionAvailableIdr,
    $core.double? commissionEarnedIdr,
    $fixnum.Int64? updatedTsMs,
    $core.double? alienPoolLimitIdr,
    $core.double? alienPoolUsedIdr,
    $core.double? frontierPoolLimitIdr,
    $core.double? frontierPoolUsedIdr,
    $fixnum.Int64? poolPeriodStartMs,
    $fixnum.Int64? trialExpiresTsMs,
    $fixnum.Int64? activePromotionId,
  }) {
    final result = BillingProfile._();
    if (id != null) result.id = id;
    if (ownerIid != null) result.ownerIid = ownerIid;
    if (planTier != null) result.planTier = planTier;
    if (defaultWalletCurrency != null)
      result.defaultWalletCurrency = defaultWalletCurrency;
    if (alienAllow5hUsed != null) result.alienAllow5hUsed = alienAllow5hUsed;
    if (alienAllow5hLimit != null) result.alienAllow5hLimit = alienAllow5hLimit;
    if (alienAllowWeeklyUsed != null)
      result.alienAllowWeeklyUsed = alienAllowWeeklyUsed;
    if (alienAllowWeeklyLimit != null)
      result.alienAllowWeeklyLimit = alienAllowWeeklyLimit;
    if (window5hStartMs != null) result.window5hStartMs = window5hStartMs;
    if (windowWeeklyStartMs != null)
      result.windowWeeklyStartMs = windowWeeklyStartMs;
    if (commissionAvailableUsd != null)
      result.commissionAvailableUsd = commissionAvailableUsd;
    if (commissionEarnedUsd != null)
      result.commissionEarnedUsd = commissionEarnedUsd;
    if (commissionAvailableIdr != null)
      result.commissionAvailableIdr = commissionAvailableIdr;
    if (commissionEarnedIdr != null)
      result.commissionEarnedIdr = commissionEarnedIdr;
    if (updatedTsMs != null) result.updatedTsMs = updatedTsMs;
    if (alienPoolLimitIdr != null) result.alienPoolLimitIdr = alienPoolLimitIdr;
    if (alienPoolUsedIdr != null) result.alienPoolUsedIdr = alienPoolUsedIdr;
    if (frontierPoolLimitIdr != null)
      result.frontierPoolLimitIdr = frontierPoolLimitIdr;
    if (frontierPoolUsedIdr != null)
      result.frontierPoolUsedIdr = frontierPoolUsedIdr;
    if (poolPeriodStartMs != null) result.poolPeriodStartMs = poolPeriodStartMs;
    if (trialExpiresTsMs != null) result.trialExpiresTsMs = trialExpiresTsMs;
    if (activePromotionId != null) result.activePromotionId = activePromotionId;
    return result;
  }

  BillingProfile._();

  factory BillingProfile.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BillingProfile()..mergeFromBuffer(data, registry);
  factory BillingProfile.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BillingProfile()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BillingProfile',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: BillingProfile.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..aInt64(2, _omitFieldNames ? '' : 'ownerIid')
    ..aOS(3, _omitFieldNames ? '' : 'planTier')
    ..aOS(4, _omitFieldNames ? '' : 'defaultWalletCurrency')
    ..aD(5, _omitFieldNames ? '' : 'alienAllow5hUsed',
        protoName: 'alien_allow_5h_used')
    ..aD(6, _omitFieldNames ? '' : 'alienAllow5hLimit',
        protoName: 'alien_allow_5h_limit')
    ..aD(7, _omitFieldNames ? '' : 'alienAllowWeeklyUsed')
    ..aD(8, _omitFieldNames ? '' : 'alienAllowWeeklyLimit')
    ..aInt64(9, _omitFieldNames ? '' : 'window5hStartMs',
        protoName: 'window_5h_start_ms')
    ..aInt64(10, _omitFieldNames ? '' : 'windowWeeklyStartMs')
    ..aD(11, _omitFieldNames ? '' : 'commissionAvailableUsd')
    ..aD(12, _omitFieldNames ? '' : 'commissionEarnedUsd')
    ..aD(13, _omitFieldNames ? '' : 'commissionAvailableIdr')
    ..aD(14, _omitFieldNames ? '' : 'commissionEarnedIdr')
    ..aInt64(15, _omitFieldNames ? '' : 'updatedTsMs')
    ..aD(16, _omitFieldNames ? '' : 'alienPoolLimitIdr')
    ..aD(17, _omitFieldNames ? '' : 'alienPoolUsedIdr')
    ..aD(18, _omitFieldNames ? '' : 'frontierPoolLimitIdr')
    ..aD(19, _omitFieldNames ? '' : 'frontierPoolUsedIdr')
    ..aInt64(20, _omitFieldNames ? '' : 'poolPeriodStartMs')
    ..aInt64(21, _omitFieldNames ? '' : 'trialExpiresTsMs')
    ..aInt64(22, _omitFieldNames ? '' : 'activePromotionId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BillingProfile clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BillingProfile copyWith(void Function(BillingProfile) updates) =>
      super.copyWith((message) => updates(message as BillingProfile))
          as BillingProfile;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use BillingProfile() / BillingProfile.new instead')
  static BillingProfile create() => BillingProfile._();
  static $pb.GeneratedMessage $_createMessage() => BillingProfile._();
  @$core.override
  BillingProfile createEmptyInstance() => BillingProfile._();
  @$core.pragma('dart2js:noInline')
  static BillingProfile getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BillingProfile>(
          BillingProfile.$_createMessage);
  static BillingProfile? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get ownerIid => $_getI64(1);
  @$pb.TagNumber(2)
  set ownerIid($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOwnerIid() => $_has(1);
  @$pb.TagNumber(2)
  void clearOwnerIid() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get planTier => $_getSZ(2);
  @$pb.TagNumber(3)
  set planTier($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPlanTier() => $_has(2);
  @$pb.TagNumber(3)
  void clearPlanTier() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get defaultWalletCurrency => $_getSZ(3);
  @$pb.TagNumber(4)
  set defaultWalletCurrency($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDefaultWalletCurrency() => $_has(3);
  @$pb.TagNumber(4)
  void clearDefaultWalletCurrency() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.double get alienAllow5hUsed => $_getN(4);
  @$pb.TagNumber(5)
  set alienAllow5hUsed($core.double value) => $_setDouble(4, value);
  @$pb.TagNumber(5)
  $core.bool hasAlienAllow5hUsed() => $_has(4);
  @$pb.TagNumber(5)
  void clearAlienAllow5hUsed() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.double get alienAllow5hLimit => $_getN(5);
  @$pb.TagNumber(6)
  set alienAllow5hLimit($core.double value) => $_setDouble(5, value);
  @$pb.TagNumber(6)
  $core.bool hasAlienAllow5hLimit() => $_has(5);
  @$pb.TagNumber(6)
  void clearAlienAllow5hLimit() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.double get alienAllowWeeklyUsed => $_getN(6);
  @$pb.TagNumber(7)
  set alienAllowWeeklyUsed($core.double value) => $_setDouble(6, value);
  @$pb.TagNumber(7)
  $core.bool hasAlienAllowWeeklyUsed() => $_has(6);
  @$pb.TagNumber(7)
  void clearAlienAllowWeeklyUsed() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.double get alienAllowWeeklyLimit => $_getN(7);
  @$pb.TagNumber(8)
  set alienAllowWeeklyLimit($core.double value) => $_setDouble(7, value);
  @$pb.TagNumber(8)
  $core.bool hasAlienAllowWeeklyLimit() => $_has(7);
  @$pb.TagNumber(8)
  void clearAlienAllowWeeklyLimit() => $_clearField(8);

  @$pb.TagNumber(9)
  $fixnum.Int64 get window5hStartMs => $_getI64(8);
  @$pb.TagNumber(9)
  set window5hStartMs($fixnum.Int64 value) => $_setInt64(8, value);
  @$pb.TagNumber(9)
  $core.bool hasWindow5hStartMs() => $_has(8);
  @$pb.TagNumber(9)
  void clearWindow5hStartMs() => $_clearField(9);

  @$pb.TagNumber(10)
  $fixnum.Int64 get windowWeeklyStartMs => $_getI64(9);
  @$pb.TagNumber(10)
  set windowWeeklyStartMs($fixnum.Int64 value) => $_setInt64(9, value);
  @$pb.TagNumber(10)
  $core.bool hasWindowWeeklyStartMs() => $_has(9);
  @$pb.TagNumber(10)
  void clearWindowWeeklyStartMs() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.double get commissionAvailableUsd => $_getN(10);
  @$pb.TagNumber(11)
  set commissionAvailableUsd($core.double value) => $_setDouble(10, value);
  @$pb.TagNumber(11)
  $core.bool hasCommissionAvailableUsd() => $_has(10);
  @$pb.TagNumber(11)
  void clearCommissionAvailableUsd() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.double get commissionEarnedUsd => $_getN(11);
  @$pb.TagNumber(12)
  set commissionEarnedUsd($core.double value) => $_setDouble(11, value);
  @$pb.TagNumber(12)
  $core.bool hasCommissionEarnedUsd() => $_has(11);
  @$pb.TagNumber(12)
  void clearCommissionEarnedUsd() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.double get commissionAvailableIdr => $_getN(12);
  @$pb.TagNumber(13)
  set commissionAvailableIdr($core.double value) => $_setDouble(12, value);
  @$pb.TagNumber(13)
  $core.bool hasCommissionAvailableIdr() => $_has(12);
  @$pb.TagNumber(13)
  void clearCommissionAvailableIdr() => $_clearField(13);

  @$pb.TagNumber(14)
  $core.double get commissionEarnedIdr => $_getN(13);
  @$pb.TagNumber(14)
  set commissionEarnedIdr($core.double value) => $_setDouble(13, value);
  @$pb.TagNumber(14)
  $core.bool hasCommissionEarnedIdr() => $_has(13);
  @$pb.TagNumber(14)
  void clearCommissionEarnedIdr() => $_clearField(14);

  @$pb.TagNumber(15)
  $fixnum.Int64 get updatedTsMs => $_getI64(14);
  @$pb.TagNumber(15)
  set updatedTsMs($fixnum.Int64 value) => $_setInt64(14, value);
  @$pb.TagNumber(15)
  $core.bool hasUpdatedTsMs() => $_has(14);
  @$pb.TagNumber(15)
  void clearUpdatedTsMs() => $_clearField(15);

  /// v3 IDR pools (Phase 4b)
  @$pb.TagNumber(16)
  $core.double get alienPoolLimitIdr => $_getN(15);
  @$pb.TagNumber(16)
  set alienPoolLimitIdr($core.double value) => $_setDouble(15, value);
  @$pb.TagNumber(16)
  $core.bool hasAlienPoolLimitIdr() => $_has(15);
  @$pb.TagNumber(16)
  void clearAlienPoolLimitIdr() => $_clearField(16);

  @$pb.TagNumber(17)
  $core.double get alienPoolUsedIdr => $_getN(16);
  @$pb.TagNumber(17)
  set alienPoolUsedIdr($core.double value) => $_setDouble(16, value);
  @$pb.TagNumber(17)
  $core.bool hasAlienPoolUsedIdr() => $_has(16);
  @$pb.TagNumber(17)
  void clearAlienPoolUsedIdr() => $_clearField(17);

  @$pb.TagNumber(18)
  $core.double get frontierPoolLimitIdr => $_getN(17);
  @$pb.TagNumber(18)
  set frontierPoolLimitIdr($core.double value) => $_setDouble(17, value);
  @$pb.TagNumber(18)
  $core.bool hasFrontierPoolLimitIdr() => $_has(17);
  @$pb.TagNumber(18)
  void clearFrontierPoolLimitIdr() => $_clearField(18);

  @$pb.TagNumber(19)
  $core.double get frontierPoolUsedIdr => $_getN(18);
  @$pb.TagNumber(19)
  set frontierPoolUsedIdr($core.double value) => $_setDouble(18, value);
  @$pb.TagNumber(19)
  $core.bool hasFrontierPoolUsedIdr() => $_has(18);
  @$pb.TagNumber(19)
  void clearFrontierPoolUsedIdr() => $_clearField(19);

  @$pb.TagNumber(20)
  $fixnum.Int64 get poolPeriodStartMs => $_getI64(19);
  @$pb.TagNumber(20)
  set poolPeriodStartMs($fixnum.Int64 value) => $_setInt64(19, value);
  @$pb.TagNumber(20)
  $core.bool hasPoolPeriodStartMs() => $_has(19);
  @$pb.TagNumber(20)
  void clearPoolPeriodStartMs() => $_clearField(20);

  @$pb.TagNumber(21)
  $fixnum.Int64 get trialExpiresTsMs => $_getI64(20);
  @$pb.TagNumber(21)
  set trialExpiresTsMs($fixnum.Int64 value) => $_setInt64(20, value);
  @$pb.TagNumber(21)
  $core.bool hasTrialExpiresTsMs() => $_has(20);
  @$pb.TagNumber(21)
  void clearTrialExpiresTsMs() => $_clearField(21);

  @$pb.TagNumber(22)
  $fixnum.Int64 get activePromotionId => $_getI64(21);
  @$pb.TagNumber(22)
  set activePromotionId($fixnum.Int64 value) => $_setInt64(21, value);
  @$pb.TagNumber(22)
  $core.bool hasActivePromotionId() => $_has(21);
  @$pb.TagNumber(22)
  void clearActivePromotionId() => $_clearField(22);
}

class BillingWallet extends $pb.GeneratedMessage {
  factory BillingWallet({
    $fixnum.Int64? id,
    $fixnum.Int64? ownerIid,
    $core.String? currency,
    $core.double? balance,
    $core.bool? isDefault,
    $core.String? name,
    $fixnum.Int64? updatedTsMs,
  }) {
    final result = BillingWallet._();
    if (id != null) result.id = id;
    if (ownerIid != null) result.ownerIid = ownerIid;
    if (currency != null) result.currency = currency;
    if (balance != null) result.balance = balance;
    if (isDefault != null) result.isDefault = isDefault;
    if (name != null) result.name = name;
    if (updatedTsMs != null) result.updatedTsMs = updatedTsMs;
    return result;
  }

  BillingWallet._();

  factory BillingWallet.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BillingWallet()..mergeFromBuffer(data, registry);
  factory BillingWallet.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BillingWallet()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BillingWallet',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: BillingWallet.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..aInt64(2, _omitFieldNames ? '' : 'ownerIid')
    ..aOS(3, _omitFieldNames ? '' : 'currency')
    ..aD(4, _omitFieldNames ? '' : 'balance')
    ..aOB(5, _omitFieldNames ? '' : 'isDefault')
    ..aOS(6, _omitFieldNames ? '' : 'name')
    ..aInt64(7, _omitFieldNames ? '' : 'updatedTsMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BillingWallet clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BillingWallet copyWith(void Function(BillingWallet) updates) =>
      super.copyWith((message) => updates(message as BillingWallet))
          as BillingWallet;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use BillingWallet() / BillingWallet.new instead')
  static BillingWallet create() => BillingWallet._();
  static $pb.GeneratedMessage $_createMessage() => BillingWallet._();
  @$core.override
  BillingWallet createEmptyInstance() => BillingWallet._();
  @$core.pragma('dart2js:noInline')
  static BillingWallet getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BillingWallet>(
          BillingWallet.$_createMessage);
  static BillingWallet? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get ownerIid => $_getI64(1);
  @$pb.TagNumber(2)
  set ownerIid($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOwnerIid() => $_has(1);
  @$pb.TagNumber(2)
  void clearOwnerIid() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get currency => $_getSZ(2);
  @$pb.TagNumber(3)
  set currency($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCurrency() => $_has(2);
  @$pb.TagNumber(3)
  void clearCurrency() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get balance => $_getN(3);
  @$pb.TagNumber(4)
  set balance($core.double value) => $_setDouble(3, value);
  @$pb.TagNumber(4)
  $core.bool hasBalance() => $_has(3);
  @$pb.TagNumber(4)
  void clearBalance() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get isDefault => $_getBF(4);
  @$pb.TagNumber(5)
  set isDefault($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasIsDefault() => $_has(4);
  @$pb.TagNumber(5)
  void clearIsDefault() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get name => $_getSZ(5);
  @$pb.TagNumber(6)
  set name($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasName() => $_has(5);
  @$pb.TagNumber(6)
  void clearName() => $_clearField(6);

  @$pb.TagNumber(7)
  $fixnum.Int64 get updatedTsMs => $_getI64(6);
  @$pb.TagNumber(7)
  set updatedTsMs($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(7)
  $core.bool hasUpdatedTsMs() => $_has(6);
  @$pb.TagNumber(7)
  void clearUpdatedTsMs() => $_clearField(7);
}

class BillingPlanPrice extends $pb.GeneratedMessage {
  factory BillingPlanPrice({
    $core.String? planSlug,
    $core.String? currency,
    $core.double? amount,
    $core.String? billingPeriod,
  }) {
    final result = BillingPlanPrice._();
    if (planSlug != null) result.planSlug = planSlug;
    if (currency != null) result.currency = currency;
    if (amount != null) result.amount = amount;
    if (billingPeriod != null) result.billingPeriod = billingPeriod;
    return result;
  }

  BillingPlanPrice._();

  factory BillingPlanPrice.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BillingPlanPrice()..mergeFromBuffer(data, registry);
  factory BillingPlanPrice.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BillingPlanPrice()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BillingPlanPrice',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: BillingPlanPrice.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'planSlug')
    ..aOS(2, _omitFieldNames ? '' : 'currency')
    ..aD(3, _omitFieldNames ? '' : 'amount')
    ..aOS(4, _omitFieldNames ? '' : 'billingPeriod')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BillingPlanPrice clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BillingPlanPrice copyWith(void Function(BillingPlanPrice) updates) =>
      super.copyWith((message) => updates(message as BillingPlanPrice))
          as BillingPlanPrice;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use BillingPlanPrice() / BillingPlanPrice.new instead')
  static BillingPlanPrice create() => BillingPlanPrice._();
  static $pb.GeneratedMessage $_createMessage() => BillingPlanPrice._();
  @$core.override
  BillingPlanPrice createEmptyInstance() => BillingPlanPrice._();
  @$core.pragma('dart2js:noInline')
  static BillingPlanPrice getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BillingPlanPrice>(
          BillingPlanPrice.$_createMessage);
  static BillingPlanPrice? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get planSlug => $_getSZ(0);
  @$pb.TagNumber(1)
  set planSlug($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPlanSlug() => $_has(0);
  @$pb.TagNumber(1)
  void clearPlanSlug() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get currency => $_getSZ(1);
  @$pb.TagNumber(2)
  set currency($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCurrency() => $_has(1);
  @$pb.TagNumber(2)
  void clearCurrency() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get amount => $_getN(2);
  @$pb.TagNumber(3)
  set amount($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAmount() => $_has(2);
  @$pb.TagNumber(3)
  void clearAmount() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get billingPeriod => $_getSZ(3);
  @$pb.TagNumber(4)
  set billingPeriod($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasBillingPeriod() => $_has(3);
  @$pb.TagNumber(4)
  void clearBillingPeriod() => $_clearField(4);
}

class BillingFxRate extends $pb.GeneratedMessage {
  factory BillingFxRate({
    $fixnum.Int64? id,
    $core.String? currency,
    $fixnum.Int64? microPerUsd,
    $fixnum.Int64? effectiveFromMs,
  }) {
    final result = BillingFxRate._();
    if (id != null) result.id = id;
    if (currency != null) result.currency = currency;
    if (microPerUsd != null) result.microPerUsd = microPerUsd;
    if (effectiveFromMs != null) result.effectiveFromMs = effectiveFromMs;
    return result;
  }

  BillingFxRate._();

  factory BillingFxRate.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BillingFxRate()..mergeFromBuffer(data, registry);
  factory BillingFxRate.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BillingFxRate()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BillingFxRate',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: BillingFxRate.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'currency')
    ..aInt64(3, _omitFieldNames ? '' : 'microPerUsd')
    ..aInt64(4, _omitFieldNames ? '' : 'effectiveFromMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BillingFxRate clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BillingFxRate copyWith(void Function(BillingFxRate) updates) =>
      super.copyWith((message) => updates(message as BillingFxRate))
          as BillingFxRate;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use BillingFxRate() / BillingFxRate.new instead')
  static BillingFxRate create() => BillingFxRate._();
  static $pb.GeneratedMessage $_createMessage() => BillingFxRate._();
  @$core.override
  BillingFxRate createEmptyInstance() => BillingFxRate._();
  @$core.pragma('dart2js:noInline')
  static BillingFxRate getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BillingFxRate>(
          BillingFxRate.$_createMessage);
  static BillingFxRate? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get currency => $_getSZ(1);
  @$pb.TagNumber(2)
  set currency($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCurrency() => $_has(1);
  @$pb.TagNumber(2)
  void clearCurrency() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get microPerUsd => $_getI64(2);
  @$pb.TagNumber(3)
  set microPerUsd($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMicroPerUsd() => $_has(2);
  @$pb.TagNumber(3)
  void clearMicroPerUsd() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get effectiveFromMs => $_getI64(3);
  @$pb.TagNumber(4)
  set effectiveFromMs($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasEffectiveFromMs() => $_has(3);
  @$pb.TagNumber(4)
  void clearEffectiveFromMs() => $_clearField(4);
}

class BillingPurchase extends $pb.GeneratedMessage {
  factory BillingPurchase({
    $fixnum.Int64? id,
    $fixnum.Int64? ownerIid,
    $core.String? planSlug,
    $core.String? currency,
    $core.double? amount,
    $core.String? provider,
    $core.String? status,
    $core.String? scope,
    $fixnum.Int64? scopeIid,
    $fixnum.Int64? settledTsMs,
    $fixnum.Int64? createdTsMs,
  }) {
    final result = BillingPurchase._();
    if (id != null) result.id = id;
    if (ownerIid != null) result.ownerIid = ownerIid;
    if (planSlug != null) result.planSlug = planSlug;
    if (currency != null) result.currency = currency;
    if (amount != null) result.amount = amount;
    if (provider != null) result.provider = provider;
    if (status != null) result.status = status;
    if (scope != null) result.scope = scope;
    if (scopeIid != null) result.scopeIid = scopeIid;
    if (settledTsMs != null) result.settledTsMs = settledTsMs;
    if (createdTsMs != null) result.createdTsMs = createdTsMs;
    return result;
  }

  BillingPurchase._();

  factory BillingPurchase.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BillingPurchase()..mergeFromBuffer(data, registry);
  factory BillingPurchase.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BillingPurchase()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BillingPurchase',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: BillingPurchase.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..aInt64(2, _omitFieldNames ? '' : 'ownerIid')
    ..aOS(3, _omitFieldNames ? '' : 'planSlug')
    ..aOS(4, _omitFieldNames ? '' : 'currency')
    ..aD(5, _omitFieldNames ? '' : 'amount')
    ..aOS(6, _omitFieldNames ? '' : 'provider')
    ..aOS(7, _omitFieldNames ? '' : 'status')
    ..aOS(8, _omitFieldNames ? '' : 'scope')
    ..aInt64(9, _omitFieldNames ? '' : 'scopeIid')
    ..aInt64(10, _omitFieldNames ? '' : 'settledTsMs')
    ..aInt64(11, _omitFieldNames ? '' : 'createdTsMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BillingPurchase clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BillingPurchase copyWith(void Function(BillingPurchase) updates) =>
      super.copyWith((message) => updates(message as BillingPurchase))
          as BillingPurchase;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use BillingPurchase() / BillingPurchase.new instead')
  static BillingPurchase create() => BillingPurchase._();
  static $pb.GeneratedMessage $_createMessage() => BillingPurchase._();
  @$core.override
  BillingPurchase createEmptyInstance() => BillingPurchase._();
  @$core.pragma('dart2js:noInline')
  static BillingPurchase getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BillingPurchase>(
          BillingPurchase.$_createMessage);
  static BillingPurchase? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get ownerIid => $_getI64(1);
  @$pb.TagNumber(2)
  set ownerIid($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOwnerIid() => $_has(1);
  @$pb.TagNumber(2)
  void clearOwnerIid() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get planSlug => $_getSZ(2);
  @$pb.TagNumber(3)
  set planSlug($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPlanSlug() => $_has(2);
  @$pb.TagNumber(3)
  void clearPlanSlug() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get currency => $_getSZ(3);
  @$pb.TagNumber(4)
  set currency($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasCurrency() => $_has(3);
  @$pb.TagNumber(4)
  void clearCurrency() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.double get amount => $_getN(4);
  @$pb.TagNumber(5)
  set amount($core.double value) => $_setDouble(4, value);
  @$pb.TagNumber(5)
  $core.bool hasAmount() => $_has(4);
  @$pb.TagNumber(5)
  void clearAmount() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get provider => $_getSZ(5);
  @$pb.TagNumber(6)
  set provider($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasProvider() => $_has(5);
  @$pb.TagNumber(6)
  void clearProvider() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get status => $_getSZ(6);
  @$pb.TagNumber(7)
  set status($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasStatus() => $_has(6);
  @$pb.TagNumber(7)
  void clearStatus() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get scope => $_getSZ(7);
  @$pb.TagNumber(8)
  set scope($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasScope() => $_has(7);
  @$pb.TagNumber(8)
  void clearScope() => $_clearField(8);

  @$pb.TagNumber(9)
  $fixnum.Int64 get scopeIid => $_getI64(8);
  @$pb.TagNumber(9)
  set scopeIid($fixnum.Int64 value) => $_setInt64(8, value);
  @$pb.TagNumber(9)
  $core.bool hasScopeIid() => $_has(8);
  @$pb.TagNumber(9)
  void clearScopeIid() => $_clearField(9);

  @$pb.TagNumber(10)
  $fixnum.Int64 get settledTsMs => $_getI64(9);
  @$pb.TagNumber(10)
  set settledTsMs($fixnum.Int64 value) => $_setInt64(9, value);
  @$pb.TagNumber(10)
  $core.bool hasSettledTsMs() => $_has(9);
  @$pb.TagNumber(10)
  void clearSettledTsMs() => $_clearField(10);

  @$pb.TagNumber(11)
  $fixnum.Int64 get createdTsMs => $_getI64(10);
  @$pb.TagNumber(11)
  set createdTsMs($fixnum.Int64 value) => $_setInt64(10, value);
  @$pb.TagNumber(11)
  $core.bool hasCreatedTsMs() => $_has(10);
  @$pb.TagNumber(11)
  void clearCreatedTsMs() => $_clearField(11);
}

/// Session init snapshot (replaces single BillingAccount when v2 live)
class BillingSnapshot extends $pb.GeneratedMessage {
  factory BillingSnapshot({
    BillingProfile? profile,
    $core.Iterable<BillingWallet>? wallets,
  }) {
    final result = BillingSnapshot._();
    if (profile != null) result.profile = profile;
    if (wallets != null) result.wallets.addAll(wallets);
    return result;
  }

  BillingSnapshot._();

  factory BillingSnapshot.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BillingSnapshot()..mergeFromBuffer(data, registry);
  factory BillingSnapshot.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BillingSnapshot()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BillingSnapshot',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: BillingSnapshot.$_createMessage)
    ..aOM<BillingProfile>(1, _omitFieldNames ? '' : 'profile',
        subBuilder: BillingProfile.$_createMessage)
    ..pPM<BillingWallet>(2, _omitFieldNames ? '' : 'wallets',
        subBuilder: BillingWallet.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BillingSnapshot clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BillingSnapshot copyWith(void Function(BillingSnapshot) updates) =>
      super.copyWith((message) => updates(message as BillingSnapshot))
          as BillingSnapshot;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use BillingSnapshot() / BillingSnapshot.new instead')
  static BillingSnapshot create() => BillingSnapshot._();
  static $pb.GeneratedMessage $_createMessage() => BillingSnapshot._();
  @$core.override
  BillingSnapshot createEmptyInstance() => BillingSnapshot._();
  @$core.pragma('dart2js:noInline')
  static BillingSnapshot getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BillingSnapshot>(
          BillingSnapshot.$_createMessage);
  static BillingSnapshot? _defaultInstance;

  @$pb.TagNumber(1)
  BillingProfile get profile => $_getN(0);
  @$pb.TagNumber(1)
  set profile(BillingProfile value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasProfile() => $_has(0);
  @$pb.TagNumber(1)
  void clearProfile() => $_clearField(1);
  @$pb.TagNumber(1)
  BillingProfile ensureProfile() => $_ensure(0);

  @$pb.TagNumber(2)
  $pb.PbList<BillingWallet> get wallets => $_getList(1);
}

class BillingAccount extends $pb.GeneratedMessage {
  factory BillingAccount({
    $fixnum.Int64? id,
    $fixnum.Int64? ownerIid,
    $core.String? name,
    $core.double? balanceUsd,
    $core.double? balanceIdr,
    $core.String? planTier,
    $core.double? alienAllow5hUsed,
    $core.double? alienAllow5hLimit,
    $core.double? alienAllowWeeklyUsed,
    $core.double? alienAllowWeeklyLimit,
    $fixnum.Int64? window5hStartMs,
    $fixnum.Int64? windowWeeklyStartMs,
    $core.String? billingCurrency,
    $fixnum.Int64? fxMicroPerUsd,
    $core.double? commissionAvailableUsd,
    $core.double? commissionEarnedUsd,
    $core.double? commissionAvailableIdr,
    $core.double? commissionEarnedIdr,
    $core.String? metaJson,
    $fixnum.Int64? createdTsMs,
    $fixnum.Int64? updatedTsMs,
    $fixnum.Int64? deletedTsMs,
  }) {
    final result = BillingAccount._();
    if (id != null) result.id = id;
    if (ownerIid != null) result.ownerIid = ownerIid;
    if (name != null) result.name = name;
    if (balanceUsd != null) result.balanceUsd = balanceUsd;
    if (balanceIdr != null) result.balanceIdr = balanceIdr;
    if (planTier != null) result.planTier = planTier;
    if (alienAllow5hUsed != null) result.alienAllow5hUsed = alienAllow5hUsed;
    if (alienAllow5hLimit != null) result.alienAllow5hLimit = alienAllow5hLimit;
    if (alienAllowWeeklyUsed != null)
      result.alienAllowWeeklyUsed = alienAllowWeeklyUsed;
    if (alienAllowWeeklyLimit != null)
      result.alienAllowWeeklyLimit = alienAllowWeeklyLimit;
    if (window5hStartMs != null) result.window5hStartMs = window5hStartMs;
    if (windowWeeklyStartMs != null)
      result.windowWeeklyStartMs = windowWeeklyStartMs;
    if (billingCurrency != null) result.billingCurrency = billingCurrency;
    if (fxMicroPerUsd != null) result.fxMicroPerUsd = fxMicroPerUsd;
    if (commissionAvailableUsd != null)
      result.commissionAvailableUsd = commissionAvailableUsd;
    if (commissionEarnedUsd != null)
      result.commissionEarnedUsd = commissionEarnedUsd;
    if (commissionAvailableIdr != null)
      result.commissionAvailableIdr = commissionAvailableIdr;
    if (commissionEarnedIdr != null)
      result.commissionEarnedIdr = commissionEarnedIdr;
    if (metaJson != null) result.metaJson = metaJson;
    if (createdTsMs != null) result.createdTsMs = createdTsMs;
    if (updatedTsMs != null) result.updatedTsMs = updatedTsMs;
    if (deletedTsMs != null) result.deletedTsMs = deletedTsMs;
    return result;
  }

  BillingAccount._();

  factory BillingAccount.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BillingAccount()..mergeFromBuffer(data, registry);
  factory BillingAccount.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BillingAccount()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BillingAccount',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: BillingAccount.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..aInt64(2, _omitFieldNames ? '' : 'ownerIid')
    ..aOS(3, _omitFieldNames ? '' : 'name')
    ..aD(4, _omitFieldNames ? '' : 'balanceUsd')
    ..aD(5, _omitFieldNames ? '' : 'balanceIdr')
    ..aOS(6, _omitFieldNames ? '' : 'planTier')
    ..aD(7, _omitFieldNames ? '' : 'alienAllow5hUsed',
        protoName: 'alien_allow_5h_used')
    ..aD(8, _omitFieldNames ? '' : 'alienAllow5hLimit',
        protoName: 'alien_allow_5h_limit')
    ..aD(9, _omitFieldNames ? '' : 'alienAllowWeeklyUsed')
    ..aD(10, _omitFieldNames ? '' : 'alienAllowWeeklyLimit')
    ..aInt64(11, _omitFieldNames ? '' : 'window5hStartMs',
        protoName: 'window_5h_start_ms')
    ..aInt64(12, _omitFieldNames ? '' : 'windowWeeklyStartMs')
    ..aOS(13, _omitFieldNames ? '' : 'billingCurrency')
    ..aInt64(14, _omitFieldNames ? '' : 'fxMicroPerUsd')
    ..aD(15, _omitFieldNames ? '' : 'commissionAvailableUsd')
    ..aD(16, _omitFieldNames ? '' : 'commissionEarnedUsd')
    ..aD(17, _omitFieldNames ? '' : 'commissionAvailableIdr')
    ..aD(18, _omitFieldNames ? '' : 'commissionEarnedIdr')
    ..aOS(19, _omitFieldNames ? '' : 'metaJson')
    ..aInt64(20, _omitFieldNames ? '' : 'createdTsMs')
    ..aInt64(21, _omitFieldNames ? '' : 'updatedTsMs')
    ..aInt64(22, _omitFieldNames ? '' : 'deletedTsMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BillingAccount clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BillingAccount copyWith(void Function(BillingAccount) updates) =>
      super.copyWith((message) => updates(message as BillingAccount))
          as BillingAccount;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use BillingAccount() / BillingAccount.new instead')
  static BillingAccount create() => BillingAccount._();
  static $pb.GeneratedMessage $_createMessage() => BillingAccount._();
  @$core.override
  BillingAccount createEmptyInstance() => BillingAccount._();
  @$core.pragma('dart2js:noInline')
  static BillingAccount getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BillingAccount>(
          BillingAccount.$_createMessage);
  static BillingAccount? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get ownerIid => $_getI64(1);
  @$pb.TagNumber(2)
  set ownerIid($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOwnerIid() => $_has(1);
  @$pb.TagNumber(2)
  void clearOwnerIid() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get name => $_getSZ(2);
  @$pb.TagNumber(3)
  set name($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasName() => $_has(2);
  @$pb.TagNumber(3)
  void clearName() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get balanceUsd => $_getN(3);
  @$pb.TagNumber(4)
  set balanceUsd($core.double value) => $_setDouble(3, value);
  @$pb.TagNumber(4)
  $core.bool hasBalanceUsd() => $_has(3);
  @$pb.TagNumber(4)
  void clearBalanceUsd() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.double get balanceIdr => $_getN(4);
  @$pb.TagNumber(5)
  set balanceIdr($core.double value) => $_setDouble(4, value);
  @$pb.TagNumber(5)
  $core.bool hasBalanceIdr() => $_has(4);
  @$pb.TagNumber(5)
  void clearBalanceIdr() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get planTier => $_getSZ(5);
  @$pb.TagNumber(6)
  set planTier($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasPlanTier() => $_has(5);
  @$pb.TagNumber(6)
  void clearPlanTier() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.double get alienAllow5hUsed => $_getN(6);
  @$pb.TagNumber(7)
  set alienAllow5hUsed($core.double value) => $_setDouble(6, value);
  @$pb.TagNumber(7)
  $core.bool hasAlienAllow5hUsed() => $_has(6);
  @$pb.TagNumber(7)
  void clearAlienAllow5hUsed() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.double get alienAllow5hLimit => $_getN(7);
  @$pb.TagNumber(8)
  set alienAllow5hLimit($core.double value) => $_setDouble(7, value);
  @$pb.TagNumber(8)
  $core.bool hasAlienAllow5hLimit() => $_has(7);
  @$pb.TagNumber(8)
  void clearAlienAllow5hLimit() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.double get alienAllowWeeklyUsed => $_getN(8);
  @$pb.TagNumber(9)
  set alienAllowWeeklyUsed($core.double value) => $_setDouble(8, value);
  @$pb.TagNumber(9)
  $core.bool hasAlienAllowWeeklyUsed() => $_has(8);
  @$pb.TagNumber(9)
  void clearAlienAllowWeeklyUsed() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.double get alienAllowWeeklyLimit => $_getN(9);
  @$pb.TagNumber(10)
  set alienAllowWeeklyLimit($core.double value) => $_setDouble(9, value);
  @$pb.TagNumber(10)
  $core.bool hasAlienAllowWeeklyLimit() => $_has(9);
  @$pb.TagNumber(10)
  void clearAlienAllowWeeklyLimit() => $_clearField(10);

  @$pb.TagNumber(11)
  $fixnum.Int64 get window5hStartMs => $_getI64(10);
  @$pb.TagNumber(11)
  set window5hStartMs($fixnum.Int64 value) => $_setInt64(10, value);
  @$pb.TagNumber(11)
  $core.bool hasWindow5hStartMs() => $_has(10);
  @$pb.TagNumber(11)
  void clearWindow5hStartMs() => $_clearField(11);

  @$pb.TagNumber(12)
  $fixnum.Int64 get windowWeeklyStartMs => $_getI64(11);
  @$pb.TagNumber(12)
  set windowWeeklyStartMs($fixnum.Int64 value) => $_setInt64(11, value);
  @$pb.TagNumber(12)
  $core.bool hasWindowWeeklyStartMs() => $_has(11);
  @$pb.TagNumber(12)
  void clearWindowWeeklyStartMs() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.String get billingCurrency => $_getSZ(12);
  @$pb.TagNumber(13)
  set billingCurrency($core.String value) => $_setString(12, value);
  @$pb.TagNumber(13)
  $core.bool hasBillingCurrency() => $_has(12);
  @$pb.TagNumber(13)
  void clearBillingCurrency() => $_clearField(13);

  @$pb.TagNumber(14)
  $fixnum.Int64 get fxMicroPerUsd => $_getI64(13);
  @$pb.TagNumber(14)
  set fxMicroPerUsd($fixnum.Int64 value) => $_setInt64(13, value);
  @$pb.TagNumber(14)
  $core.bool hasFxMicroPerUsd() => $_has(13);
  @$pb.TagNumber(14)
  void clearFxMicroPerUsd() => $_clearField(14);

  @$pb.TagNumber(15)
  $core.double get commissionAvailableUsd => $_getN(14);
  @$pb.TagNumber(15)
  set commissionAvailableUsd($core.double value) => $_setDouble(14, value);
  @$pb.TagNumber(15)
  $core.bool hasCommissionAvailableUsd() => $_has(14);
  @$pb.TagNumber(15)
  void clearCommissionAvailableUsd() => $_clearField(15);

  @$pb.TagNumber(16)
  $core.double get commissionEarnedUsd => $_getN(15);
  @$pb.TagNumber(16)
  set commissionEarnedUsd($core.double value) => $_setDouble(15, value);
  @$pb.TagNumber(16)
  $core.bool hasCommissionEarnedUsd() => $_has(15);
  @$pb.TagNumber(16)
  void clearCommissionEarnedUsd() => $_clearField(16);

  @$pb.TagNumber(17)
  $core.double get commissionAvailableIdr => $_getN(16);
  @$pb.TagNumber(17)
  set commissionAvailableIdr($core.double value) => $_setDouble(16, value);
  @$pb.TagNumber(17)
  $core.bool hasCommissionAvailableIdr() => $_has(16);
  @$pb.TagNumber(17)
  void clearCommissionAvailableIdr() => $_clearField(17);

  @$pb.TagNumber(18)
  $core.double get commissionEarnedIdr => $_getN(17);
  @$pb.TagNumber(18)
  set commissionEarnedIdr($core.double value) => $_setDouble(17, value);
  @$pb.TagNumber(18)
  $core.bool hasCommissionEarnedIdr() => $_has(17);
  @$pb.TagNumber(18)
  void clearCommissionEarnedIdr() => $_clearField(18);

  @$pb.TagNumber(19)
  $core.String get metaJson => $_getSZ(18);
  @$pb.TagNumber(19)
  set metaJson($core.String value) => $_setString(18, value);
  @$pb.TagNumber(19)
  $core.bool hasMetaJson() => $_has(18);
  @$pb.TagNumber(19)
  void clearMetaJson() => $_clearField(19);

  @$pb.TagNumber(20)
  $fixnum.Int64 get createdTsMs => $_getI64(19);
  @$pb.TagNumber(20)
  set createdTsMs($fixnum.Int64 value) => $_setInt64(19, value);
  @$pb.TagNumber(20)
  $core.bool hasCreatedTsMs() => $_has(19);
  @$pb.TagNumber(20)
  void clearCreatedTsMs() => $_clearField(20);

  @$pb.TagNumber(21)
  $fixnum.Int64 get updatedTsMs => $_getI64(20);
  @$pb.TagNumber(21)
  set updatedTsMs($fixnum.Int64 value) => $_setInt64(20, value);
  @$pb.TagNumber(21)
  $core.bool hasUpdatedTsMs() => $_has(20);
  @$pb.TagNumber(21)
  void clearUpdatedTsMs() => $_clearField(21);

  @$pb.TagNumber(22)
  $fixnum.Int64 get deletedTsMs => $_getI64(21);
  @$pb.TagNumber(22)
  set deletedTsMs($fixnum.Int64 value) => $_setInt64(21, value);
  @$pb.TagNumber(22)
  $core.bool hasDeletedTsMs() => $_has(21);
  @$pb.TagNumber(22)
  void clearDeletedTsMs() => $_clearField(22);
}

class BillingTopupRequest extends $pb.GeneratedMessage {
  factory BillingTopupRequest({
    $fixnum.Int64? id,
    $fixnum.Int64? ownerIid,
    $fixnum.Int64? billingAccountId,
    $core.double? amountUsd,
    $core.double? amountIdr,
    $core.String? provider,
    $core.String? paymentType,
    $core.String? externalOrderId,
    $core.String? proofUrl,
    $core.String? status,
    $core.String? rejectReason,
    $fixnum.Int64? reviewedByIid,
    $fixnum.Int64? settledTsMs,
    $fixnum.Int64? createdTsMs,
    $fixnum.Int64? updatedTsMs,
  }) {
    final result = BillingTopupRequest._();
    if (id != null) result.id = id;
    if (ownerIid != null) result.ownerIid = ownerIid;
    if (billingAccountId != null) result.billingAccountId = billingAccountId;
    if (amountUsd != null) result.amountUsd = amountUsd;
    if (amountIdr != null) result.amountIdr = amountIdr;
    if (provider != null) result.provider = provider;
    if (paymentType != null) result.paymentType = paymentType;
    if (externalOrderId != null) result.externalOrderId = externalOrderId;
    if (proofUrl != null) result.proofUrl = proofUrl;
    if (status != null) result.status = status;
    if (rejectReason != null) result.rejectReason = rejectReason;
    if (reviewedByIid != null) result.reviewedByIid = reviewedByIid;
    if (settledTsMs != null) result.settledTsMs = settledTsMs;
    if (createdTsMs != null) result.createdTsMs = createdTsMs;
    if (updatedTsMs != null) result.updatedTsMs = updatedTsMs;
    return result;
  }

  BillingTopupRequest._();

  factory BillingTopupRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BillingTopupRequest()..mergeFromBuffer(data, registry);
  factory BillingTopupRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BillingTopupRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BillingTopupRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: BillingTopupRequest.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..aInt64(2, _omitFieldNames ? '' : 'ownerIid')
    ..aInt64(3, _omitFieldNames ? '' : 'billingAccountId')
    ..aD(4, _omitFieldNames ? '' : 'amountUsd')
    ..aD(5, _omitFieldNames ? '' : 'amountIdr')
    ..aOS(6, _omitFieldNames ? '' : 'provider')
    ..aOS(7, _omitFieldNames ? '' : 'paymentType')
    ..aOS(8, _omitFieldNames ? '' : 'externalOrderId')
    ..aOS(9, _omitFieldNames ? '' : 'proofUrl')
    ..aOS(10, _omitFieldNames ? '' : 'status')
    ..aOS(11, _omitFieldNames ? '' : 'rejectReason')
    ..aInt64(12, _omitFieldNames ? '' : 'reviewedByIid')
    ..aInt64(13, _omitFieldNames ? '' : 'settledTsMs')
    ..aInt64(14, _omitFieldNames ? '' : 'createdTsMs')
    ..aInt64(15, _omitFieldNames ? '' : 'updatedTsMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BillingTopupRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BillingTopupRequest copyWith(void Function(BillingTopupRequest) updates) =>
      super.copyWith((message) => updates(message as BillingTopupRequest))
          as BillingTopupRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use BillingTopupRequest() / BillingTopupRequest.new instead')
  static BillingTopupRequest create() => BillingTopupRequest._();
  static $pb.GeneratedMessage $_createMessage() => BillingTopupRequest._();
  @$core.override
  BillingTopupRequest createEmptyInstance() => BillingTopupRequest._();
  @$core.pragma('dart2js:noInline')
  static BillingTopupRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BillingTopupRequest>(
          BillingTopupRequest.$_createMessage);
  static BillingTopupRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get ownerIid => $_getI64(1);
  @$pb.TagNumber(2)
  set ownerIid($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOwnerIid() => $_has(1);
  @$pb.TagNumber(2)
  void clearOwnerIid() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get billingAccountId => $_getI64(2);
  @$pb.TagNumber(3)
  set billingAccountId($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasBillingAccountId() => $_has(2);
  @$pb.TagNumber(3)
  void clearBillingAccountId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get amountUsd => $_getN(3);
  @$pb.TagNumber(4)
  set amountUsd($core.double value) => $_setDouble(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAmountUsd() => $_has(3);
  @$pb.TagNumber(4)
  void clearAmountUsd() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.double get amountIdr => $_getN(4);
  @$pb.TagNumber(5)
  set amountIdr($core.double value) => $_setDouble(4, value);
  @$pb.TagNumber(5)
  $core.bool hasAmountIdr() => $_has(4);
  @$pb.TagNumber(5)
  void clearAmountIdr() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get provider => $_getSZ(5);
  @$pb.TagNumber(6)
  set provider($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasProvider() => $_has(5);
  @$pb.TagNumber(6)
  void clearProvider() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get paymentType => $_getSZ(6);
  @$pb.TagNumber(7)
  set paymentType($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasPaymentType() => $_has(6);
  @$pb.TagNumber(7)
  void clearPaymentType() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get externalOrderId => $_getSZ(7);
  @$pb.TagNumber(8)
  set externalOrderId($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasExternalOrderId() => $_has(7);
  @$pb.TagNumber(8)
  void clearExternalOrderId() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get proofUrl => $_getSZ(8);
  @$pb.TagNumber(9)
  set proofUrl($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasProofUrl() => $_has(8);
  @$pb.TagNumber(9)
  void clearProofUrl() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.String get status => $_getSZ(9);
  @$pb.TagNumber(10)
  set status($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasStatus() => $_has(9);
  @$pb.TagNumber(10)
  void clearStatus() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.String get rejectReason => $_getSZ(10);
  @$pb.TagNumber(11)
  set rejectReason($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasRejectReason() => $_has(10);
  @$pb.TagNumber(11)
  void clearRejectReason() => $_clearField(11);

  @$pb.TagNumber(12)
  $fixnum.Int64 get reviewedByIid => $_getI64(11);
  @$pb.TagNumber(12)
  set reviewedByIid($fixnum.Int64 value) => $_setInt64(11, value);
  @$pb.TagNumber(12)
  $core.bool hasReviewedByIid() => $_has(11);
  @$pb.TagNumber(12)
  void clearReviewedByIid() => $_clearField(12);

  @$pb.TagNumber(13)
  $fixnum.Int64 get settledTsMs => $_getI64(12);
  @$pb.TagNumber(13)
  set settledTsMs($fixnum.Int64 value) => $_setInt64(12, value);
  @$pb.TagNumber(13)
  $core.bool hasSettledTsMs() => $_has(12);
  @$pb.TagNumber(13)
  void clearSettledTsMs() => $_clearField(13);

  @$pb.TagNumber(14)
  $fixnum.Int64 get createdTsMs => $_getI64(13);
  @$pb.TagNumber(14)
  set createdTsMs($fixnum.Int64 value) => $_setInt64(13, value);
  @$pb.TagNumber(14)
  $core.bool hasCreatedTsMs() => $_has(13);
  @$pb.TagNumber(14)
  void clearCreatedTsMs() => $_clearField(14);

  @$pb.TagNumber(15)
  $fixnum.Int64 get updatedTsMs => $_getI64(14);
  @$pb.TagNumber(15)
  set updatedTsMs($fixnum.Int64 value) => $_setInt64(14, value);
  @$pb.TagNumber(15)
  $core.bool hasUpdatedTsMs() => $_has(14);
  @$pb.TagNumber(15)
  void clearUpdatedTsMs() => $_clearField(15);
}

/// NATS push: c35.user.{iid}.balance | .quota | .commission
class BillingPushBalance extends $pb.GeneratedMessage {
  factory BillingPushBalance({
    $fixnum.Int64? billingAccountId,
    $core.double? balanceUsd,
    $core.double? balanceIdr,
    $fixnum.Int64? updatedTsMs,
    $fixnum.Int64? walletId,
    $core.String? currency,
    $core.double? balance,
  }) {
    final result = BillingPushBalance._();
    if (billingAccountId != null) result.billingAccountId = billingAccountId;
    if (balanceUsd != null) result.balanceUsd = balanceUsd;
    if (balanceIdr != null) result.balanceIdr = balanceIdr;
    if (updatedTsMs != null) result.updatedTsMs = updatedTsMs;
    if (walletId != null) result.walletId = walletId;
    if (currency != null) result.currency = currency;
    if (balance != null) result.balance = balance;
    return result;
  }

  BillingPushBalance._();

  factory BillingPushBalance.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BillingPushBalance()..mergeFromBuffer(data, registry);
  factory BillingPushBalance.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BillingPushBalance()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BillingPushBalance',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: BillingPushBalance.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'billingAccountId')
    ..aD(2, _omitFieldNames ? '' : 'balanceUsd')
    ..aD(3, _omitFieldNames ? '' : 'balanceIdr')
    ..aInt64(4, _omitFieldNames ? '' : 'updatedTsMs')
    ..aInt64(5, _omitFieldNames ? '' : 'walletId')
    ..aOS(6, _omitFieldNames ? '' : 'currency')
    ..aD(7, _omitFieldNames ? '' : 'balance')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BillingPushBalance clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BillingPushBalance copyWith(void Function(BillingPushBalance) updates) =>
      super.copyWith((message) => updates(message as BillingPushBalance))
          as BillingPushBalance;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use BillingPushBalance() / BillingPushBalance.new instead')
  static BillingPushBalance create() => BillingPushBalance._();
  static $pb.GeneratedMessage $_createMessage() => BillingPushBalance._();
  @$core.override
  BillingPushBalance createEmptyInstance() => BillingPushBalance._();
  @$core.pragma('dart2js:noInline')
  static BillingPushBalance getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BillingPushBalance>(
          BillingPushBalance.$_createMessage);
  static BillingPushBalance? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get billingAccountId => $_getI64(0);
  @$pb.TagNumber(1)
  set billingAccountId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasBillingAccountId() => $_has(0);
  @$pb.TagNumber(1)
  void clearBillingAccountId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get balanceUsd => $_getN(1);
  @$pb.TagNumber(2)
  set balanceUsd($core.double value) => $_setDouble(1, value);
  @$pb.TagNumber(2)
  $core.bool hasBalanceUsd() => $_has(1);
  @$pb.TagNumber(2)
  void clearBalanceUsd() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get balanceIdr => $_getN(2);
  @$pb.TagNumber(3)
  set balanceIdr($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasBalanceIdr() => $_has(2);
  @$pb.TagNumber(3)
  void clearBalanceIdr() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get updatedTsMs => $_getI64(3);
  @$pb.TagNumber(4)
  set updatedTsMs($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasUpdatedTsMs() => $_has(3);
  @$pb.TagNumber(4)
  void clearUpdatedTsMs() => $_clearField(4);

  /// v2 fields (populate when wallet model live)
  @$pb.TagNumber(5)
  $fixnum.Int64 get walletId => $_getI64(4);
  @$pb.TagNumber(5)
  set walletId($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasWalletId() => $_has(4);
  @$pb.TagNumber(5)
  void clearWalletId() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get currency => $_getSZ(5);
  @$pb.TagNumber(6)
  set currency($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasCurrency() => $_has(5);
  @$pb.TagNumber(6)
  void clearCurrency() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.double get balance => $_getN(6);
  @$pb.TagNumber(7)
  set balance($core.double value) => $_setDouble(6, value);
  @$pb.TagNumber(7)
  $core.bool hasBalance() => $_has(6);
  @$pb.TagNumber(7)
  void clearBalance() => $_clearField(7);
}

class BillingPushQuota extends $pb.GeneratedMessage {
  factory BillingPushQuota({
    $core.double? alienAllow5hUsed,
    $core.double? alienAllow5hLimit,
    $core.double? alienAllowWeeklyUsed,
    $core.double? alienAllowWeeklyLimit,
    $fixnum.Int64? window5hStartMs,
    $fixnum.Int64? windowWeeklyStartMs,
    $core.double? alienPoolLimitIdr,
    $core.double? alienPoolUsedIdr,
    $core.double? frontierPoolLimitIdr,
    $core.double? frontierPoolUsedIdr,
    $fixnum.Int64? poolPeriodStartMs,
    $fixnum.Int64? trialExpiresTsMs,
  }) {
    final result = BillingPushQuota._();
    if (alienAllow5hUsed != null) result.alienAllow5hUsed = alienAllow5hUsed;
    if (alienAllow5hLimit != null) result.alienAllow5hLimit = alienAllow5hLimit;
    if (alienAllowWeeklyUsed != null)
      result.alienAllowWeeklyUsed = alienAllowWeeklyUsed;
    if (alienAllowWeeklyLimit != null)
      result.alienAllowWeeklyLimit = alienAllowWeeklyLimit;
    if (window5hStartMs != null) result.window5hStartMs = window5hStartMs;
    if (windowWeeklyStartMs != null)
      result.windowWeeklyStartMs = windowWeeklyStartMs;
    if (alienPoolLimitIdr != null) result.alienPoolLimitIdr = alienPoolLimitIdr;
    if (alienPoolUsedIdr != null) result.alienPoolUsedIdr = alienPoolUsedIdr;
    if (frontierPoolLimitIdr != null)
      result.frontierPoolLimitIdr = frontierPoolLimitIdr;
    if (frontierPoolUsedIdr != null)
      result.frontierPoolUsedIdr = frontierPoolUsedIdr;
    if (poolPeriodStartMs != null) result.poolPeriodStartMs = poolPeriodStartMs;
    if (trialExpiresTsMs != null) result.trialExpiresTsMs = trialExpiresTsMs;
    return result;
  }

  BillingPushQuota._();

  factory BillingPushQuota.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BillingPushQuota()..mergeFromBuffer(data, registry);
  factory BillingPushQuota.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BillingPushQuota()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BillingPushQuota',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: BillingPushQuota.$_createMessage)
    ..aD(1, _omitFieldNames ? '' : 'alienAllow5hUsed',
        protoName: 'alien_allow_5h_used')
    ..aD(2, _omitFieldNames ? '' : 'alienAllow5hLimit',
        protoName: 'alien_allow_5h_limit')
    ..aD(3, _omitFieldNames ? '' : 'alienAllowWeeklyUsed')
    ..aD(4, _omitFieldNames ? '' : 'alienAllowWeeklyLimit')
    ..aInt64(5, _omitFieldNames ? '' : 'window5hStartMs',
        protoName: 'window_5h_start_ms')
    ..aInt64(6, _omitFieldNames ? '' : 'windowWeeklyStartMs')
    ..aD(7, _omitFieldNames ? '' : 'alienPoolLimitIdr')
    ..aD(8, _omitFieldNames ? '' : 'alienPoolUsedIdr')
    ..aD(9, _omitFieldNames ? '' : 'frontierPoolLimitIdr')
    ..aD(10, _omitFieldNames ? '' : 'frontierPoolUsedIdr')
    ..aInt64(11, _omitFieldNames ? '' : 'poolPeriodStartMs')
    ..aInt64(12, _omitFieldNames ? '' : 'trialExpiresTsMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BillingPushQuota clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BillingPushQuota copyWith(void Function(BillingPushQuota) updates) =>
      super.copyWith((message) => updates(message as BillingPushQuota))
          as BillingPushQuota;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use BillingPushQuota() / BillingPushQuota.new instead')
  static BillingPushQuota create() => BillingPushQuota._();
  static $pb.GeneratedMessage $_createMessage() => BillingPushQuota._();
  @$core.override
  BillingPushQuota createEmptyInstance() => BillingPushQuota._();
  @$core.pragma('dart2js:noInline')
  static BillingPushQuota getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BillingPushQuota>(
          BillingPushQuota.$_createMessage);
  static BillingPushQuota? _defaultInstance;

  @$pb.TagNumber(1)
  $core.double get alienAllow5hUsed => $_getN(0);
  @$pb.TagNumber(1)
  set alienAllow5hUsed($core.double value) => $_setDouble(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAlienAllow5hUsed() => $_has(0);
  @$pb.TagNumber(1)
  void clearAlienAllow5hUsed() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get alienAllow5hLimit => $_getN(1);
  @$pb.TagNumber(2)
  set alienAllow5hLimit($core.double value) => $_setDouble(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAlienAllow5hLimit() => $_has(1);
  @$pb.TagNumber(2)
  void clearAlienAllow5hLimit() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get alienAllowWeeklyUsed => $_getN(2);
  @$pb.TagNumber(3)
  set alienAllowWeeklyUsed($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAlienAllowWeeklyUsed() => $_has(2);
  @$pb.TagNumber(3)
  void clearAlienAllowWeeklyUsed() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get alienAllowWeeklyLimit => $_getN(3);
  @$pb.TagNumber(4)
  set alienAllowWeeklyLimit($core.double value) => $_setDouble(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAlienAllowWeeklyLimit() => $_has(3);
  @$pb.TagNumber(4)
  void clearAlienAllowWeeklyLimit() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get window5hStartMs => $_getI64(4);
  @$pb.TagNumber(5)
  set window5hStartMs($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasWindow5hStartMs() => $_has(4);
  @$pb.TagNumber(5)
  void clearWindow5hStartMs() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get windowWeeklyStartMs => $_getI64(5);
  @$pb.TagNumber(6)
  set windowWeeklyStartMs($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasWindowWeeklyStartMs() => $_has(5);
  @$pb.TagNumber(6)
  void clearWindowWeeklyStartMs() => $_clearField(6);

  /// v3 IDR pools (Phase 4b)
  @$pb.TagNumber(7)
  $core.double get alienPoolLimitIdr => $_getN(6);
  @$pb.TagNumber(7)
  set alienPoolLimitIdr($core.double value) => $_setDouble(6, value);
  @$pb.TagNumber(7)
  $core.bool hasAlienPoolLimitIdr() => $_has(6);
  @$pb.TagNumber(7)
  void clearAlienPoolLimitIdr() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.double get alienPoolUsedIdr => $_getN(7);
  @$pb.TagNumber(8)
  set alienPoolUsedIdr($core.double value) => $_setDouble(7, value);
  @$pb.TagNumber(8)
  $core.bool hasAlienPoolUsedIdr() => $_has(7);
  @$pb.TagNumber(8)
  void clearAlienPoolUsedIdr() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.double get frontierPoolLimitIdr => $_getN(8);
  @$pb.TagNumber(9)
  set frontierPoolLimitIdr($core.double value) => $_setDouble(8, value);
  @$pb.TagNumber(9)
  $core.bool hasFrontierPoolLimitIdr() => $_has(8);
  @$pb.TagNumber(9)
  void clearFrontierPoolLimitIdr() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.double get frontierPoolUsedIdr => $_getN(9);
  @$pb.TagNumber(10)
  set frontierPoolUsedIdr($core.double value) => $_setDouble(9, value);
  @$pb.TagNumber(10)
  $core.bool hasFrontierPoolUsedIdr() => $_has(9);
  @$pb.TagNumber(10)
  void clearFrontierPoolUsedIdr() => $_clearField(10);

  @$pb.TagNumber(11)
  $fixnum.Int64 get poolPeriodStartMs => $_getI64(10);
  @$pb.TagNumber(11)
  set poolPeriodStartMs($fixnum.Int64 value) => $_setInt64(10, value);
  @$pb.TagNumber(11)
  $core.bool hasPoolPeriodStartMs() => $_has(10);
  @$pb.TagNumber(11)
  void clearPoolPeriodStartMs() => $_clearField(11);

  @$pb.TagNumber(12)
  $fixnum.Int64 get trialExpiresTsMs => $_getI64(11);
  @$pb.TagNumber(12)
  set trialExpiresTsMs($fixnum.Int64 value) => $_setInt64(11, value);
  @$pb.TagNumber(12)
  $core.bool hasTrialExpiresTsMs() => $_has(11);
  @$pb.TagNumber(12)
  void clearTrialExpiresTsMs() => $_clearField(12);
}

class BillingPushCommission extends $pb.GeneratedMessage {
  factory BillingPushCommission({
    $core.double? commissionAvailableUsd,
    $core.double? commissionEarnedUsd,
    $core.double? commissionAvailableIdr,
    $core.double? commissionEarnedIdr,
  }) {
    final result = BillingPushCommission._();
    if (commissionAvailableUsd != null)
      result.commissionAvailableUsd = commissionAvailableUsd;
    if (commissionEarnedUsd != null)
      result.commissionEarnedUsd = commissionEarnedUsd;
    if (commissionAvailableIdr != null)
      result.commissionAvailableIdr = commissionAvailableIdr;
    if (commissionEarnedIdr != null)
      result.commissionEarnedIdr = commissionEarnedIdr;
    return result;
  }

  BillingPushCommission._();

  factory BillingPushCommission.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BillingPushCommission()..mergeFromBuffer(data, registry);
  factory BillingPushCommission.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BillingPushCommission()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BillingPushCommission',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: BillingPushCommission.$_createMessage)
    ..aD(1, _omitFieldNames ? '' : 'commissionAvailableUsd')
    ..aD(2, _omitFieldNames ? '' : 'commissionEarnedUsd')
    ..aD(3, _omitFieldNames ? '' : 'commissionAvailableIdr')
    ..aD(4, _omitFieldNames ? '' : 'commissionEarnedIdr')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BillingPushCommission clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BillingPushCommission copyWith(
          void Function(BillingPushCommission) updates) =>
      super.copyWith((message) => updates(message as BillingPushCommission))
          as BillingPushCommission;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use BillingPushCommission() / BillingPushCommission.new instead')
  static BillingPushCommission create() => BillingPushCommission._();
  static $pb.GeneratedMessage $_createMessage() => BillingPushCommission._();
  @$core.override
  BillingPushCommission createEmptyInstance() => BillingPushCommission._();
  @$core.pragma('dart2js:noInline')
  static BillingPushCommission getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BillingPushCommission>(
          BillingPushCommission.$_createMessage);
  static BillingPushCommission? _defaultInstance;

  @$pb.TagNumber(1)
  $core.double get commissionAvailableUsd => $_getN(0);
  @$pb.TagNumber(1)
  set commissionAvailableUsd($core.double value) => $_setDouble(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCommissionAvailableUsd() => $_has(0);
  @$pb.TagNumber(1)
  void clearCommissionAvailableUsd() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get commissionEarnedUsd => $_getN(1);
  @$pb.TagNumber(2)
  set commissionEarnedUsd($core.double value) => $_setDouble(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCommissionEarnedUsd() => $_has(1);
  @$pb.TagNumber(2)
  void clearCommissionEarnedUsd() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get commissionAvailableIdr => $_getN(2);
  @$pb.TagNumber(3)
  set commissionAvailableIdr($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCommissionAvailableIdr() => $_has(2);
  @$pb.TagNumber(3)
  void clearCommissionAvailableIdr() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get commissionEarnedIdr => $_getN(3);
  @$pb.TagNumber(4)
  set commissionEarnedIdr($core.double value) => $_setDouble(3, value);
  @$pb.TagNumber(4)
  $core.bool hasCommissionEarnedIdr() => $_has(3);
  @$pb.TagNumber(4)
  void clearCommissionEarnedIdr() => $_clearField(4);
}

/// Invoke (HTTP or Ws invoke) — user submit top-up
class ReqBillingTopupPut extends $pb.GeneratedMessage {
  factory ReqBillingTopupPut({
    $core.double? amountUsd,
    $core.double? amountIdr,
    $core.String? provider,
    $core.String? paymentType,
    $core.String? proofUrl,
  }) {
    final result = ReqBillingTopupPut._();
    if (amountUsd != null) result.amountUsd = amountUsd;
    if (amountIdr != null) result.amountIdr = amountIdr;
    if (provider != null) result.provider = provider;
    if (paymentType != null) result.paymentType = paymentType;
    if (proofUrl != null) result.proofUrl = proofUrl;
    return result;
  }

  ReqBillingTopupPut._();

  factory ReqBillingTopupPut.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqBillingTopupPut()..mergeFromBuffer(data, registry);
  factory ReqBillingTopupPut.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqBillingTopupPut()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqBillingTopupPut',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqBillingTopupPut.$_createMessage)
    ..aD(1, _omitFieldNames ? '' : 'amountUsd')
    ..aD(2, _omitFieldNames ? '' : 'amountIdr')
    ..aOS(3, _omitFieldNames ? '' : 'provider')
    ..aOS(4, _omitFieldNames ? '' : 'paymentType')
    ..aOS(5, _omitFieldNames ? '' : 'proofUrl')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqBillingTopupPut clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqBillingTopupPut copyWith(void Function(ReqBillingTopupPut) updates) =>
      super.copyWith((message) => updates(message as ReqBillingTopupPut))
          as ReqBillingTopupPut;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqBillingTopupPut() / ReqBillingTopupPut.new instead')
  static ReqBillingTopupPut create() => ReqBillingTopupPut._();
  static $pb.GeneratedMessage $_createMessage() => ReqBillingTopupPut._();
  @$core.override
  ReqBillingTopupPut createEmptyInstance() => ReqBillingTopupPut._();
  @$core.pragma('dart2js:noInline')
  static ReqBillingTopupPut getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqBillingTopupPut>(
          ReqBillingTopupPut.$_createMessage);
  static ReqBillingTopupPut? _defaultInstance;

  @$pb.TagNumber(1)
  $core.double get amountUsd => $_getN(0);
  @$pb.TagNumber(1)
  set amountUsd($core.double value) => $_setDouble(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAmountUsd() => $_has(0);
  @$pb.TagNumber(1)
  void clearAmountUsd() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get amountIdr => $_getN(1);
  @$pb.TagNumber(2)
  set amountIdr($core.double value) => $_setDouble(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAmountIdr() => $_has(1);
  @$pb.TagNumber(2)
  void clearAmountIdr() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get provider => $_getSZ(2);
  @$pb.TagNumber(3)
  set provider($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasProvider() => $_has(2);
  @$pb.TagNumber(3)
  void clearProvider() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get paymentType => $_getSZ(3);
  @$pb.TagNumber(4)
  set paymentType($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPaymentType() => $_has(3);
  @$pb.TagNumber(4)
  void clearPaymentType() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get proofUrl => $_getSZ(4);
  @$pb.TagNumber(5)
  set proofUrl($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasProofUrl() => $_has(4);
  @$pb.TagNumber(5)
  void clearProofUrl() => $_clearField(5);
}

class ResBillingTopupPut extends $pb.GeneratedMessage {
  factory ResBillingTopupPut({
    BillingTopupRequest? request,
  }) {
    final result = ResBillingTopupPut._();
    if (request != null) result.request = request;
    return result;
  }

  ResBillingTopupPut._();

  factory ResBillingTopupPut.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResBillingTopupPut()..mergeFromBuffer(data, registry);
  factory ResBillingTopupPut.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResBillingTopupPut()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResBillingTopupPut',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResBillingTopupPut.$_createMessage)
    ..aOM<BillingTopupRequest>(1, _omitFieldNames ? '' : 'request',
        subBuilder: BillingTopupRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResBillingTopupPut clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResBillingTopupPut copyWith(void Function(ResBillingTopupPut) updates) =>
      super.copyWith((message) => updates(message as ResBillingTopupPut))
          as ResBillingTopupPut;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResBillingTopupPut() / ResBillingTopupPut.new instead')
  static ResBillingTopupPut create() => ResBillingTopupPut._();
  static $pb.GeneratedMessage $_createMessage() => ResBillingTopupPut._();
  @$core.override
  ResBillingTopupPut createEmptyInstance() => ResBillingTopupPut._();
  @$core.pragma('dart2js:noInline')
  static ResBillingTopupPut getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResBillingTopupPut>(
          ResBillingTopupPut.$_createMessage);
  static ResBillingTopupPut? _defaultInstance;

  @$pb.TagNumber(1)
  BillingTopupRequest get request => $_getN(0);
  @$pb.TagNumber(1)
  set request(BillingTopupRequest value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasRequest() => $_has(0);
  @$pb.TagNumber(1)
  void clearRequest() => $_clearField(1);
  @$pb.TagNumber(1)
  BillingTopupRequest ensureRequest() => $_ensure(0);
}

class ReqBillingPlanSubscribe extends $pb.GeneratedMessage {
  factory ReqBillingPlanSubscribe({
    $core.String? planSlug,
    $core.String? currency,
    $fixnum.Int64? walletId,
    $core.bool? directPurchase,
    $core.String? billingPeriod,
  }) {
    final result = ReqBillingPlanSubscribe._();
    if (planSlug != null) result.planSlug = planSlug;
    if (currency != null) result.currency = currency;
    if (walletId != null) result.walletId = walletId;
    if (directPurchase != null) result.directPurchase = directPurchase;
    if (billingPeriod != null) result.billingPeriod = billingPeriod;
    return result;
  }

  ReqBillingPlanSubscribe._();

  factory ReqBillingPlanSubscribe.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqBillingPlanSubscribe()..mergeFromBuffer(data, registry);
  factory ReqBillingPlanSubscribe.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqBillingPlanSubscribe()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqBillingPlanSubscribe',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqBillingPlanSubscribe.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'planSlug')
    ..aOS(2, _omitFieldNames ? '' : 'currency')
    ..aInt64(3, _omitFieldNames ? '' : 'walletId')
    ..aOB(4, _omitFieldNames ? '' : 'directPurchase')
    ..aOS(5, _omitFieldNames ? '' : 'billingPeriod')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqBillingPlanSubscribe clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqBillingPlanSubscribe copyWith(
          void Function(ReqBillingPlanSubscribe) updates) =>
      super.copyWith((message) => updates(message as ReqBillingPlanSubscribe))
          as ReqBillingPlanSubscribe;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ReqBillingPlanSubscribe() / ReqBillingPlanSubscribe.new instead')
  static ReqBillingPlanSubscribe create() => ReqBillingPlanSubscribe._();
  static $pb.GeneratedMessage $_createMessage() => ReqBillingPlanSubscribe._();
  @$core.override
  ReqBillingPlanSubscribe createEmptyInstance() => ReqBillingPlanSubscribe._();
  @$core.pragma('dart2js:noInline')
  static ReqBillingPlanSubscribe getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqBillingPlanSubscribe>(
          ReqBillingPlanSubscribe.$_createMessage);
  static ReqBillingPlanSubscribe? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get planSlug => $_getSZ(0);
  @$pb.TagNumber(1)
  set planSlug($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPlanSlug() => $_has(0);
  @$pb.TagNumber(1)
  void clearPlanSlug() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get currency => $_getSZ(1);
  @$pb.TagNumber(2)
  set currency($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCurrency() => $_has(1);
  @$pb.TagNumber(2)
  void clearCurrency() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get walletId => $_getI64(2);
  @$pb.TagNumber(3)
  set walletId($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasWalletId() => $_has(2);
  @$pb.TagNumber(3)
  void clearWalletId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get directPurchase => $_getBF(3);
  @$pb.TagNumber(4)
  set directPurchase($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDirectPurchase() => $_has(3);
  @$pb.TagNumber(4)
  void clearDirectPurchase() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get billingPeriod => $_getSZ(4);
  @$pb.TagNumber(5)
  set billingPeriod($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasBillingPeriod() => $_has(4);
  @$pb.TagNumber(5)
  void clearBillingPeriod() => $_clearField(5);
}

class ResBillingPlanSubscribe extends $pb.GeneratedMessage {
  factory ResBillingPlanSubscribe({
    $core.String? planTier,
    $core.double? balanceUsd,
    $core.double? balanceIdr,
    $core.double? alienAllow5hLimit,
    $core.double? alienAllowWeeklyLimit,
  }) {
    final result = ResBillingPlanSubscribe._();
    if (planTier != null) result.planTier = planTier;
    if (balanceUsd != null) result.balanceUsd = balanceUsd;
    if (balanceIdr != null) result.balanceIdr = balanceIdr;
    if (alienAllow5hLimit != null) result.alienAllow5hLimit = alienAllow5hLimit;
    if (alienAllowWeeklyLimit != null)
      result.alienAllowWeeklyLimit = alienAllowWeeklyLimit;
    return result;
  }

  ResBillingPlanSubscribe._();

  factory ResBillingPlanSubscribe.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResBillingPlanSubscribe()..mergeFromBuffer(data, registry);
  factory ResBillingPlanSubscribe.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResBillingPlanSubscribe()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResBillingPlanSubscribe',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResBillingPlanSubscribe.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'planTier')
    ..aD(2, _omitFieldNames ? '' : 'balanceUsd')
    ..aD(3, _omitFieldNames ? '' : 'balanceIdr')
    ..aD(4, _omitFieldNames ? '' : 'alienAllow5hLimit',
        protoName: 'alien_allow_5h_limit')
    ..aD(5, _omitFieldNames ? '' : 'alienAllowWeeklyLimit')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResBillingPlanSubscribe clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResBillingPlanSubscribe copyWith(
          void Function(ResBillingPlanSubscribe) updates) =>
      super.copyWith((message) => updates(message as ResBillingPlanSubscribe))
          as ResBillingPlanSubscribe;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ResBillingPlanSubscribe() / ResBillingPlanSubscribe.new instead')
  static ResBillingPlanSubscribe create() => ResBillingPlanSubscribe._();
  static $pb.GeneratedMessage $_createMessage() => ResBillingPlanSubscribe._();
  @$core.override
  ResBillingPlanSubscribe createEmptyInstance() => ResBillingPlanSubscribe._();
  @$core.pragma('dart2js:noInline')
  static ResBillingPlanSubscribe getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResBillingPlanSubscribe>(
          ResBillingPlanSubscribe.$_createMessage);
  static ResBillingPlanSubscribe? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get planTier => $_getSZ(0);
  @$pb.TagNumber(1)
  set planTier($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPlanTier() => $_has(0);
  @$pb.TagNumber(1)
  void clearPlanTier() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get balanceUsd => $_getN(1);
  @$pb.TagNumber(2)
  set balanceUsd($core.double value) => $_setDouble(1, value);
  @$pb.TagNumber(2)
  $core.bool hasBalanceUsd() => $_has(1);
  @$pb.TagNumber(2)
  void clearBalanceUsd() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get balanceIdr => $_getN(2);
  @$pb.TagNumber(3)
  set balanceIdr($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasBalanceIdr() => $_has(2);
  @$pb.TagNumber(3)
  void clearBalanceIdr() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get alienAllow5hLimit => $_getN(3);
  @$pb.TagNumber(4)
  set alienAllow5hLimit($core.double value) => $_setDouble(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAlienAllow5hLimit() => $_has(3);
  @$pb.TagNumber(4)
  void clearAlienAllow5hLimit() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.double get alienAllowWeeklyLimit => $_getN(4);
  @$pb.TagNumber(5)
  set alienAllowWeeklyLimit($core.double value) => $_setDouble(4, value);
  @$pb.TagNumber(5)
  $core.bool hasAlienAllowWeeklyLimit() => $_has(4);
  @$pb.TagNumber(5)
  void clearAlienAllowWeeklyLimit() => $_clearField(5);
}

class ReqBillingPackageRedeem extends $pb.GeneratedMessage {
  factory ReqBillingPackageRedeem({
    $core.String? code,
  }) {
    final result = ReqBillingPackageRedeem._();
    if (code != null) result.code = code;
    return result;
  }

  ReqBillingPackageRedeem._();

  factory ReqBillingPackageRedeem.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqBillingPackageRedeem()..mergeFromBuffer(data, registry);
  factory ReqBillingPackageRedeem.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqBillingPackageRedeem()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqBillingPackageRedeem',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqBillingPackageRedeem.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'code')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqBillingPackageRedeem clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqBillingPackageRedeem copyWith(
          void Function(ReqBillingPackageRedeem) updates) =>
      super.copyWith((message) => updates(message as ReqBillingPackageRedeem))
          as ReqBillingPackageRedeem;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ReqBillingPackageRedeem() / ReqBillingPackageRedeem.new instead')
  static ReqBillingPackageRedeem create() => ReqBillingPackageRedeem._();
  static $pb.GeneratedMessage $_createMessage() => ReqBillingPackageRedeem._();
  @$core.override
  ReqBillingPackageRedeem createEmptyInstance() => ReqBillingPackageRedeem._();
  @$core.pragma('dart2js:noInline')
  static ReqBillingPackageRedeem getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqBillingPackageRedeem>(
          ReqBillingPackageRedeem.$_createMessage);
  static ReqBillingPackageRedeem? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get code => $_getSZ(0);
  @$pb.TagNumber(1)
  set code($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCode() => $_has(0);
  @$pb.TagNumber(1)
  void clearCode() => $_clearField(1);
}

class ResBillingPackageRedeem extends $pb.GeneratedMessage {
  factory ResBillingPackageRedeem({
    $fixnum.Int64? purchaseId,
    $core.double? amountUsd,
    $core.double? amountIdr,
    $core.String? planTier,
    $core.int? durationMonths,
    $core.String? packageName,
  }) {
    final result = ResBillingPackageRedeem._();
    if (purchaseId != null) result.purchaseId = purchaseId;
    if (amountUsd != null) result.amountUsd = amountUsd;
    if (amountIdr != null) result.amountIdr = amountIdr;
    if (planTier != null) result.planTier = planTier;
    if (durationMonths != null) result.durationMonths = durationMonths;
    if (packageName != null) result.packageName = packageName;
    return result;
  }

  ResBillingPackageRedeem._();

  factory ResBillingPackageRedeem.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResBillingPackageRedeem()..mergeFromBuffer(data, registry);
  factory ResBillingPackageRedeem.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResBillingPackageRedeem()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResBillingPackageRedeem',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResBillingPackageRedeem.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'purchaseId')
    ..aD(2, _omitFieldNames ? '' : 'amountUsd')
    ..aD(3, _omitFieldNames ? '' : 'amountIdr')
    ..aOS(4, _omitFieldNames ? '' : 'planTier')
    ..aI(5, _omitFieldNames ? '' : 'durationMonths')
    ..aOS(6, _omitFieldNames ? '' : 'packageName')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResBillingPackageRedeem clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResBillingPackageRedeem copyWith(
          void Function(ResBillingPackageRedeem) updates) =>
      super.copyWith((message) => updates(message as ResBillingPackageRedeem))
          as ResBillingPackageRedeem;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ResBillingPackageRedeem() / ResBillingPackageRedeem.new instead')
  static ResBillingPackageRedeem create() => ResBillingPackageRedeem._();
  static $pb.GeneratedMessage $_createMessage() => ResBillingPackageRedeem._();
  @$core.override
  ResBillingPackageRedeem createEmptyInstance() => ResBillingPackageRedeem._();
  @$core.pragma('dart2js:noInline')
  static ResBillingPackageRedeem getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResBillingPackageRedeem>(
          ResBillingPackageRedeem.$_createMessage);
  static ResBillingPackageRedeem? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get purchaseId => $_getI64(0);
  @$pb.TagNumber(1)
  set purchaseId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPurchaseId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPurchaseId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get amountUsd => $_getN(1);
  @$pb.TagNumber(2)
  set amountUsd($core.double value) => $_setDouble(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAmountUsd() => $_has(1);
  @$pb.TagNumber(2)
  void clearAmountUsd() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get amountIdr => $_getN(2);
  @$pb.TagNumber(3)
  set amountIdr($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAmountIdr() => $_has(2);
  @$pb.TagNumber(3)
  void clearAmountIdr() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get planTier => $_getSZ(3);
  @$pb.TagNumber(4)
  set planTier($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPlanTier() => $_has(3);
  @$pb.TagNumber(4)
  void clearPlanTier() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get durationMonths => $_getIZ(4);
  @$pb.TagNumber(5)
  set durationMonths($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasDurationMonths() => $_has(4);
  @$pb.TagNumber(5)
  void clearDurationMonths() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get packageName => $_getSZ(5);
  @$pb.TagNumber(6)
  set packageName($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasPackageName() => $_has(5);
  @$pb.TagNumber(6)
  void clearPackageName() => $_clearField(6);
}

class ReqBillingPackagePreview extends $pb.GeneratedMessage {
  factory ReqBillingPackagePreview({
    $core.String? code,
  }) {
    final result = ReqBillingPackagePreview._();
    if (code != null) result.code = code;
    return result;
  }

  ReqBillingPackagePreview._();

  factory ReqBillingPackagePreview.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqBillingPackagePreview()..mergeFromBuffer(data, registry);
  factory ReqBillingPackagePreview.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqBillingPackagePreview()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqBillingPackagePreview',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqBillingPackagePreview.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'code')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqBillingPackagePreview clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqBillingPackagePreview copyWith(
          void Function(ReqBillingPackagePreview) updates) =>
      super.copyWith((message) => updates(message as ReqBillingPackagePreview))
          as ReqBillingPackagePreview;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ReqBillingPackagePreview() / ReqBillingPackagePreview.new instead')
  static ReqBillingPackagePreview create() => ReqBillingPackagePreview._();
  static $pb.GeneratedMessage $_createMessage() => ReqBillingPackagePreview._();
  @$core.override
  ReqBillingPackagePreview createEmptyInstance() =>
      ReqBillingPackagePreview._();
  @$core.pragma('dart2js:noInline')
  static ReqBillingPackagePreview getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqBillingPackagePreview>(
          ReqBillingPackagePreview.$_createMessage);
  static ReqBillingPackagePreview? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get code => $_getSZ(0);
  @$pb.TagNumber(1)
  set code($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCode() => $_has(0);
  @$pb.TagNumber(1)
  void clearCode() => $_clearField(1);
}

class ResBillingPackagePreview extends $pb.GeneratedMessage {
  factory ResBillingPackagePreview({
    $core.double? amountUsd,
    $core.double? amountIdr,
    $core.String? planTier,
    $core.String? packageName,
    $0.ResReferralCommissionSimulate? commission,
  }) {
    final result = ResBillingPackagePreview._();
    if (amountUsd != null) result.amountUsd = amountUsd;
    if (amountIdr != null) result.amountIdr = amountIdr;
    if (planTier != null) result.planTier = planTier;
    if (packageName != null) result.packageName = packageName;
    if (commission != null) result.commission = commission;
    return result;
  }

  ResBillingPackagePreview._();

  factory ResBillingPackagePreview.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResBillingPackagePreview()..mergeFromBuffer(data, registry);
  factory ResBillingPackagePreview.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResBillingPackagePreview()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResBillingPackagePreview',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResBillingPackagePreview.$_createMessage)
    ..aD(1, _omitFieldNames ? '' : 'amountUsd')
    ..aD(2, _omitFieldNames ? '' : 'amountIdr')
    ..aOS(3, _omitFieldNames ? '' : 'planTier')
    ..aOS(4, _omitFieldNames ? '' : 'packageName')
    ..aOM<$0.ResReferralCommissionSimulate>(
        5, _omitFieldNames ? '' : 'commission',
        subBuilder: $0.ResReferralCommissionSimulate.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResBillingPackagePreview clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResBillingPackagePreview copyWith(
          void Function(ResBillingPackagePreview) updates) =>
      super.copyWith((message) => updates(message as ResBillingPackagePreview))
          as ResBillingPackagePreview;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ResBillingPackagePreview() / ResBillingPackagePreview.new instead')
  static ResBillingPackagePreview create() => ResBillingPackagePreview._();
  static $pb.GeneratedMessage $_createMessage() => ResBillingPackagePreview._();
  @$core.override
  ResBillingPackagePreview createEmptyInstance() =>
      ResBillingPackagePreview._();
  @$core.pragma('dart2js:noInline')
  static ResBillingPackagePreview getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResBillingPackagePreview>(
          ResBillingPackagePreview.$_createMessage);
  static ResBillingPackagePreview? _defaultInstance;

  @$pb.TagNumber(1)
  $core.double get amountUsd => $_getN(0);
  @$pb.TagNumber(1)
  set amountUsd($core.double value) => $_setDouble(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAmountUsd() => $_has(0);
  @$pb.TagNumber(1)
  void clearAmountUsd() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get amountIdr => $_getN(1);
  @$pb.TagNumber(2)
  set amountIdr($core.double value) => $_setDouble(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAmountIdr() => $_has(1);
  @$pb.TagNumber(2)
  void clearAmountIdr() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get planTier => $_getSZ(2);
  @$pb.TagNumber(3)
  set planTier($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPlanTier() => $_has(2);
  @$pb.TagNumber(3)
  void clearPlanTier() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get packageName => $_getSZ(3);
  @$pb.TagNumber(4)
  set packageName($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPackageName() => $_has(3);
  @$pb.TagNumber(4)
  void clearPackageName() => $_clearField(4);

  @$pb.TagNumber(5)
  $0.ResReferralCommissionSimulate get commission => $_getN(4);
  @$pb.TagNumber(5)
  set commission($0.ResReferralCommissionSimulate value) =>
      $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasCommission() => $_has(4);
  @$pb.TagNumber(5)
  void clearCommission() => $_clearField(5);
  @$pb.TagNumber(5)
  $0.ResReferralCommissionSimulate ensureCommission() => $_ensure(4);
}

class BotUsageModelRow extends $pb.GeneratedMessage {
  factory BotUsageModelRow({
    $core.String? model,
    $core.String? planSlug,
    $core.int? turns,
    $core.int? tokensIn,
    $core.int? tokensOut,
    $core.double? costUsd,
  }) {
    final result = BotUsageModelRow._();
    if (model != null) result.model = model;
    if (planSlug != null) result.planSlug = planSlug;
    if (turns != null) result.turns = turns;
    if (tokensIn != null) result.tokensIn = tokensIn;
    if (tokensOut != null) result.tokensOut = tokensOut;
    if (costUsd != null) result.costUsd = costUsd;
    return result;
  }

  BotUsageModelRow._();

  factory BotUsageModelRow.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BotUsageModelRow()..mergeFromBuffer(data, registry);
  factory BotUsageModelRow.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BotUsageModelRow()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BotUsageModelRow',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: BotUsageModelRow.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'model')
    ..aOS(2, _omitFieldNames ? '' : 'planSlug')
    ..aI(3, _omitFieldNames ? '' : 'turns')
    ..aI(4, _omitFieldNames ? '' : 'tokensIn')
    ..aI(5, _omitFieldNames ? '' : 'tokensOut')
    ..aD(6, _omitFieldNames ? '' : 'costUsd')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BotUsageModelRow clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BotUsageModelRow copyWith(void Function(BotUsageModelRow) updates) =>
      super.copyWith((message) => updates(message as BotUsageModelRow))
          as BotUsageModelRow;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use BotUsageModelRow() / BotUsageModelRow.new instead')
  static BotUsageModelRow create() => BotUsageModelRow._();
  static $pb.GeneratedMessage $_createMessage() => BotUsageModelRow._();
  @$core.override
  BotUsageModelRow createEmptyInstance() => BotUsageModelRow._();
  @$core.pragma('dart2js:noInline')
  static BotUsageModelRow getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BotUsageModelRow>(
          BotUsageModelRow.$_createMessage);
  static BotUsageModelRow? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get model => $_getSZ(0);
  @$pb.TagNumber(1)
  set model($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasModel() => $_has(0);
  @$pb.TagNumber(1)
  void clearModel() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get planSlug => $_getSZ(1);
  @$pb.TagNumber(2)
  set planSlug($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPlanSlug() => $_has(1);
  @$pb.TagNumber(2)
  void clearPlanSlug() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get turns => $_getIZ(2);
  @$pb.TagNumber(3)
  set turns($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTurns() => $_has(2);
  @$pb.TagNumber(3)
  void clearTurns() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get tokensIn => $_getIZ(3);
  @$pb.TagNumber(4)
  set tokensIn($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTokensIn() => $_has(3);
  @$pb.TagNumber(4)
  void clearTokensIn() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get tokensOut => $_getIZ(4);
  @$pb.TagNumber(5)
  set tokensOut($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasTokensOut() => $_has(4);
  @$pb.TagNumber(5)
  void clearTokensOut() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.double get costUsd => $_getN(5);
  @$pb.TagNumber(6)
  set costUsd($core.double value) => $_setDouble(5, value);
  @$pb.TagNumber(6)
  $core.bool hasCostUsd() => $_has(5);
  @$pb.TagNumber(6)
  void clearCostUsd() => $_clearField(6);
}

class ReqBotUsageStats extends $pb.GeneratedMessage {
  factory ReqBotUsageStats({
    $fixnum.Int64? botIid,
  }) {
    final result = ReqBotUsageStats._();
    if (botIid != null) result.botIid = botIid;
    return result;
  }

  ReqBotUsageStats._();

  factory ReqBotUsageStats.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqBotUsageStats()..mergeFromBuffer(data, registry);
  factory ReqBotUsageStats.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqBotUsageStats()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqBotUsageStats',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqBotUsageStats.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'botIid')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqBotUsageStats clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqBotUsageStats copyWith(void Function(ReqBotUsageStats) updates) =>
      super.copyWith((message) => updates(message as ReqBotUsageStats))
          as ReqBotUsageStats;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqBotUsageStats() / ReqBotUsageStats.new instead')
  static ReqBotUsageStats create() => ReqBotUsageStats._();
  static $pb.GeneratedMessage $_createMessage() => ReqBotUsageStats._();
  @$core.override
  ReqBotUsageStats createEmptyInstance() => ReqBotUsageStats._();
  @$core.pragma('dart2js:noInline')
  static ReqBotUsageStats getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqBotUsageStats>(
          ReqBotUsageStats.$_createMessage);
  static ReqBotUsageStats? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get botIid => $_getI64(0);
  @$pb.TagNumber(1)
  set botIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasBotIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearBotIid() => $_clearField(1);
}

class ResBotUsageStats extends $pb.GeneratedMessage {
  factory ResBotUsageStats({
    $fixnum.Int64? botIid,
    $core.String? planSlug,
    $core.int? msgsUsed,
    $core.int? msgsLimit,
    $core.double? totalCostUsd,
    $core.int? totalTokensIn,
    $core.int? totalTokensOut,
    $core.Iterable<BotUsageModelRow>? byModel,
  }) {
    final result = ResBotUsageStats._();
    if (botIid != null) result.botIid = botIid;
    if (planSlug != null) result.planSlug = planSlug;
    if (msgsUsed != null) result.msgsUsed = msgsUsed;
    if (msgsLimit != null) result.msgsLimit = msgsLimit;
    if (totalCostUsd != null) result.totalCostUsd = totalCostUsd;
    if (totalTokensIn != null) result.totalTokensIn = totalTokensIn;
    if (totalTokensOut != null) result.totalTokensOut = totalTokensOut;
    if (byModel != null) result.byModel.addAll(byModel);
    return result;
  }

  ResBotUsageStats._();

  factory ResBotUsageStats.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResBotUsageStats()..mergeFromBuffer(data, registry);
  factory ResBotUsageStats.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResBotUsageStats()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResBotUsageStats',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResBotUsageStats.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'botIid')
    ..aOS(2, _omitFieldNames ? '' : 'planSlug')
    ..aI(3, _omitFieldNames ? '' : 'msgsUsed')
    ..aI(4, _omitFieldNames ? '' : 'msgsLimit')
    ..aD(5, _omitFieldNames ? '' : 'totalCostUsd')
    ..aI(6, _omitFieldNames ? '' : 'totalTokensIn')
    ..aI(7, _omitFieldNames ? '' : 'totalTokensOut')
    ..pPM<BotUsageModelRow>(8, _omitFieldNames ? '' : 'byModel',
        subBuilder: BotUsageModelRow.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResBotUsageStats clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResBotUsageStats copyWith(void Function(ResBotUsageStats) updates) =>
      super.copyWith((message) => updates(message as ResBotUsageStats))
          as ResBotUsageStats;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResBotUsageStats() / ResBotUsageStats.new instead')
  static ResBotUsageStats create() => ResBotUsageStats._();
  static $pb.GeneratedMessage $_createMessage() => ResBotUsageStats._();
  @$core.override
  ResBotUsageStats createEmptyInstance() => ResBotUsageStats._();
  @$core.pragma('dart2js:noInline')
  static ResBotUsageStats getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResBotUsageStats>(
          ResBotUsageStats.$_createMessage);
  static ResBotUsageStats? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get botIid => $_getI64(0);
  @$pb.TagNumber(1)
  set botIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasBotIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearBotIid() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get planSlug => $_getSZ(1);
  @$pb.TagNumber(2)
  set planSlug($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPlanSlug() => $_has(1);
  @$pb.TagNumber(2)
  void clearPlanSlug() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get msgsUsed => $_getIZ(2);
  @$pb.TagNumber(3)
  set msgsUsed($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMsgsUsed() => $_has(2);
  @$pb.TagNumber(3)
  void clearMsgsUsed() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get msgsLimit => $_getIZ(3);
  @$pb.TagNumber(4)
  set msgsLimit($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasMsgsLimit() => $_has(3);
  @$pb.TagNumber(4)
  void clearMsgsLimit() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.double get totalCostUsd => $_getN(4);
  @$pb.TagNumber(5)
  set totalCostUsd($core.double value) => $_setDouble(4, value);
  @$pb.TagNumber(5)
  $core.bool hasTotalCostUsd() => $_has(4);
  @$pb.TagNumber(5)
  void clearTotalCostUsd() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get totalTokensIn => $_getIZ(5);
  @$pb.TagNumber(6)
  set totalTokensIn($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasTotalTokensIn() => $_has(5);
  @$pb.TagNumber(6)
  void clearTotalTokensIn() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.int get totalTokensOut => $_getIZ(6);
  @$pb.TagNumber(7)
  set totalTokensOut($core.int value) => $_setSignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasTotalTokensOut() => $_has(6);
  @$pb.TagNumber(7)
  void clearTotalTokensOut() => $_clearField(7);

  @$pb.TagNumber(8)
  $pb.PbList<BotUsageModelRow> get byModel => $_getList(7);
}

class ReqBillingSummary extends $pb.GeneratedMessage {
  factory ReqBillingSummary({
    $fixnum.Int64? billingAccountId,
  }) {
    final result = ReqBillingSummary._();
    if (billingAccountId != null) result.billingAccountId = billingAccountId;
    return result;
  }

  ReqBillingSummary._();

  factory ReqBillingSummary.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqBillingSummary()..mergeFromBuffer(data, registry);
  factory ReqBillingSummary.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqBillingSummary()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqBillingSummary',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqBillingSummary.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'billingAccountId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqBillingSummary clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqBillingSummary copyWith(void Function(ReqBillingSummary) updates) =>
      super.copyWith((message) => updates(message as ReqBillingSummary))
          as ReqBillingSummary;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqBillingSummary() / ReqBillingSummary.new instead')
  static ReqBillingSummary create() => ReqBillingSummary._();
  static $pb.GeneratedMessage $_createMessage() => ReqBillingSummary._();
  @$core.override
  ReqBillingSummary createEmptyInstance() => ReqBillingSummary._();
  @$core.pragma('dart2js:noInline')
  static ReqBillingSummary getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqBillingSummary>(
          ReqBillingSummary.$_createMessage);
  static ReqBillingSummary? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get billingAccountId => $_getI64(0);
  @$pb.TagNumber(1)
  set billingAccountId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasBillingAccountId() => $_has(0);
  @$pb.TagNumber(1)
  void clearBillingAccountId() => $_clearField(1);
}

class BillingPlanDoc extends $pb.GeneratedMessage {
  factory BillingPlanDoc({
    $core.String? slug,
    $core.String? name,
    $core.int? sortOrder,
    $core.double? priceUsd,
    $core.int? durationMonths,
    $core.double? alienAllow5hUsd,
    $core.double? alienAllowWeeklyUsd,
    $core.int? msgsLimit,
    $core.int? channelsLimit,
    $core.int? concurrentLimit,
    $core.bool? overageEnabled,
  }) {
    final result = BillingPlanDoc._();
    if (slug != null) result.slug = slug;
    if (name != null) result.name = name;
    if (sortOrder != null) result.sortOrder = sortOrder;
    if (priceUsd != null) result.priceUsd = priceUsd;
    if (durationMonths != null) result.durationMonths = durationMonths;
    if (alienAllow5hUsd != null) result.alienAllow5hUsd = alienAllow5hUsd;
    if (alienAllowWeeklyUsd != null)
      result.alienAllowWeeklyUsd = alienAllowWeeklyUsd;
    if (msgsLimit != null) result.msgsLimit = msgsLimit;
    if (channelsLimit != null) result.channelsLimit = channelsLimit;
    if (concurrentLimit != null) result.concurrentLimit = concurrentLimit;
    if (overageEnabled != null) result.overageEnabled = overageEnabled;
    return result;
  }

  BillingPlanDoc._();

  factory BillingPlanDoc.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BillingPlanDoc()..mergeFromBuffer(data, registry);
  factory BillingPlanDoc.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BillingPlanDoc()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BillingPlanDoc',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: BillingPlanDoc.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'slug')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aI(3, _omitFieldNames ? '' : 'sortOrder')
    ..aD(4, _omitFieldNames ? '' : 'priceUsd')
    ..aI(5, _omitFieldNames ? '' : 'durationMonths')
    ..aD(6, _omitFieldNames ? '' : 'alienAllow5hUsd',
        protoName: 'alien_allow_5h_usd')
    ..aD(7, _omitFieldNames ? '' : 'alienAllowWeeklyUsd')
    ..aI(8, _omitFieldNames ? '' : 'msgsLimit')
    ..aI(9, _omitFieldNames ? '' : 'channelsLimit')
    ..aI(10, _omitFieldNames ? '' : 'concurrentLimit')
    ..aOB(11, _omitFieldNames ? '' : 'overageEnabled')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BillingPlanDoc clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BillingPlanDoc copyWith(void Function(BillingPlanDoc) updates) =>
      super.copyWith((message) => updates(message as BillingPlanDoc))
          as BillingPlanDoc;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use BillingPlanDoc() / BillingPlanDoc.new instead')
  static BillingPlanDoc create() => BillingPlanDoc._();
  static $pb.GeneratedMessage $_createMessage() => BillingPlanDoc._();
  @$core.override
  BillingPlanDoc createEmptyInstance() => BillingPlanDoc._();
  @$core.pragma('dart2js:noInline')
  static BillingPlanDoc getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BillingPlanDoc>(
          BillingPlanDoc.$_createMessage);
  static BillingPlanDoc? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get slug => $_getSZ(0);
  @$pb.TagNumber(1)
  set slug($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSlug() => $_has(0);
  @$pb.TagNumber(1)
  void clearSlug() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get sortOrder => $_getIZ(2);
  @$pb.TagNumber(3)
  set sortOrder($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSortOrder() => $_has(2);
  @$pb.TagNumber(3)
  void clearSortOrder() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get priceUsd => $_getN(3);
  @$pb.TagNumber(4)
  set priceUsd($core.double value) => $_setDouble(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPriceUsd() => $_has(3);
  @$pb.TagNumber(4)
  void clearPriceUsd() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get durationMonths => $_getIZ(4);
  @$pb.TagNumber(5)
  set durationMonths($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasDurationMonths() => $_has(4);
  @$pb.TagNumber(5)
  void clearDurationMonths() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.double get alienAllow5hUsd => $_getN(5);
  @$pb.TagNumber(6)
  set alienAllow5hUsd($core.double value) => $_setDouble(5, value);
  @$pb.TagNumber(6)
  $core.bool hasAlienAllow5hUsd() => $_has(5);
  @$pb.TagNumber(6)
  void clearAlienAllow5hUsd() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.double get alienAllowWeeklyUsd => $_getN(6);
  @$pb.TagNumber(7)
  set alienAllowWeeklyUsd($core.double value) => $_setDouble(6, value);
  @$pb.TagNumber(7)
  $core.bool hasAlienAllowWeeklyUsd() => $_has(6);
  @$pb.TagNumber(7)
  void clearAlienAllowWeeklyUsd() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.int get msgsLimit => $_getIZ(7);
  @$pb.TagNumber(8)
  set msgsLimit($core.int value) => $_setSignedInt32(7, value);
  @$pb.TagNumber(8)
  $core.bool hasMsgsLimit() => $_has(7);
  @$pb.TagNumber(8)
  void clearMsgsLimit() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.int get channelsLimit => $_getIZ(8);
  @$pb.TagNumber(9)
  set channelsLimit($core.int value) => $_setSignedInt32(8, value);
  @$pb.TagNumber(9)
  $core.bool hasChannelsLimit() => $_has(8);
  @$pb.TagNumber(9)
  void clearChannelsLimit() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.int get concurrentLimit => $_getIZ(9);
  @$pb.TagNumber(10)
  set concurrentLimit($core.int value) => $_setSignedInt32(9, value);
  @$pb.TagNumber(10)
  $core.bool hasConcurrentLimit() => $_has(9);
  @$pb.TagNumber(10)
  void clearConcurrentLimit() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.bool get overageEnabled => $_getBF(10);
  @$pb.TagNumber(11)
  set overageEnabled($core.bool value) => $_setBool(10, value);
  @$pb.TagNumber(11)
  $core.bool hasOverageEnabled() => $_has(10);
  @$pb.TagNumber(11)
  void clearOverageEnabled() => $_clearField(11);
}

class BillingHistoryRow extends $pb.GeneratedMessage {
  factory BillingHistoryRow({
    $core.String? kind,
    $core.String? title,
    $core.double? amountUsd,
    $core.double? amountIdr,
    $core.String? status,
    $fixnum.Int64? tsMs,
    $core.String? currency,
    $core.double? amount,
  }) {
    final result = BillingHistoryRow._();
    if (kind != null) result.kind = kind;
    if (title != null) result.title = title;
    if (amountUsd != null) result.amountUsd = amountUsd;
    if (amountIdr != null) result.amountIdr = amountIdr;
    if (status != null) result.status = status;
    if (tsMs != null) result.tsMs = tsMs;
    if (currency != null) result.currency = currency;
    if (amount != null) result.amount = amount;
    return result;
  }

  BillingHistoryRow._();

  factory BillingHistoryRow.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BillingHistoryRow()..mergeFromBuffer(data, registry);
  factory BillingHistoryRow.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BillingHistoryRow()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BillingHistoryRow',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: BillingHistoryRow.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'kind')
    ..aOS(2, _omitFieldNames ? '' : 'title')
    ..aD(3, _omitFieldNames ? '' : 'amountUsd')
    ..aD(4, _omitFieldNames ? '' : 'amountIdr')
    ..aOS(5, _omitFieldNames ? '' : 'status')
    ..aInt64(6, _omitFieldNames ? '' : 'tsMs')
    ..aOS(7, _omitFieldNames ? '' : 'currency')
    ..aD(8, _omitFieldNames ? '' : 'amount')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BillingHistoryRow clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BillingHistoryRow copyWith(void Function(BillingHistoryRow) updates) =>
      super.copyWith((message) => updates(message as BillingHistoryRow))
          as BillingHistoryRow;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use BillingHistoryRow() / BillingHistoryRow.new instead')
  static BillingHistoryRow create() => BillingHistoryRow._();
  static $pb.GeneratedMessage $_createMessage() => BillingHistoryRow._();
  @$core.override
  BillingHistoryRow createEmptyInstance() => BillingHistoryRow._();
  @$core.pragma('dart2js:noInline')
  static BillingHistoryRow getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BillingHistoryRow>(
          BillingHistoryRow.$_createMessage);
  static BillingHistoryRow? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get kind => $_getSZ(0);
  @$pb.TagNumber(1)
  set kind($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasKind() => $_has(0);
  @$pb.TagNumber(1)
  void clearKind() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get title => $_getSZ(1);
  @$pb.TagNumber(2)
  set title($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTitle() => $_has(1);
  @$pb.TagNumber(2)
  void clearTitle() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get amountUsd => $_getN(2);
  @$pb.TagNumber(3)
  set amountUsd($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAmountUsd() => $_has(2);
  @$pb.TagNumber(3)
  void clearAmountUsd() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get amountIdr => $_getN(3);
  @$pb.TagNumber(4)
  set amountIdr($core.double value) => $_setDouble(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAmountIdr() => $_has(3);
  @$pb.TagNumber(4)
  void clearAmountIdr() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get status => $_getSZ(4);
  @$pb.TagNumber(5)
  set status($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasStatus() => $_has(4);
  @$pb.TagNumber(5)
  void clearStatus() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get tsMs => $_getI64(5);
  @$pb.TagNumber(6)
  set tsMs($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasTsMs() => $_has(5);
  @$pb.TagNumber(6)
  void clearTsMs() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get currency => $_getSZ(6);
  @$pb.TagNumber(7)
  set currency($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasCurrency() => $_has(6);
  @$pb.TagNumber(7)
  void clearCurrency() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.double get amount => $_getN(7);
  @$pb.TagNumber(8)
  set amount($core.double value) => $_setDouble(7, value);
  @$pb.TagNumber(8)
  $core.bool hasAmount() => $_has(7);
  @$pb.TagNumber(8)
  void clearAmount() => $_clearField(8);
}

class ReqBillingHistory extends $pb.GeneratedMessage {
  factory ReqBillingHistory({
    $core.int? limit,
    $core.String? currency,
  }) {
    final result = ReqBillingHistory._();
    if (limit != null) result.limit = limit;
    if (currency != null) result.currency = currency;
    return result;
  }

  ReqBillingHistory._();

  factory ReqBillingHistory.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqBillingHistory()..mergeFromBuffer(data, registry);
  factory ReqBillingHistory.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqBillingHistory()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqBillingHistory',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqBillingHistory.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'limit')
    ..aOS(2, _omitFieldNames ? '' : 'currency')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqBillingHistory clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqBillingHistory copyWith(void Function(ReqBillingHistory) updates) =>
      super.copyWith((message) => updates(message as ReqBillingHistory))
          as ReqBillingHistory;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqBillingHistory() / ReqBillingHistory.new instead')
  static ReqBillingHistory create() => ReqBillingHistory._();
  static $pb.GeneratedMessage $_createMessage() => ReqBillingHistory._();
  @$core.override
  ReqBillingHistory createEmptyInstance() => ReqBillingHistory._();
  @$core.pragma('dart2js:noInline')
  static ReqBillingHistory getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqBillingHistory>(
          ReqBillingHistory.$_createMessage);
  static ReqBillingHistory? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get limit => $_getIZ(0);
  @$pb.TagNumber(1)
  set limit($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLimit() => $_has(0);
  @$pb.TagNumber(1)
  void clearLimit() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get currency => $_getSZ(1);
  @$pb.TagNumber(2)
  set currency($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCurrency() => $_has(1);
  @$pb.TagNumber(2)
  void clearCurrency() => $_clearField(2);
}

class ResBillingHistory extends $pb.GeneratedMessage {
  factory ResBillingHistory({
    $core.Iterable<BillingHistoryRow>? rows,
  }) {
    final result = ResBillingHistory._();
    if (rows != null) result.rows.addAll(rows);
    return result;
  }

  ResBillingHistory._();

  factory ResBillingHistory.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResBillingHistory()..mergeFromBuffer(data, registry);
  factory ResBillingHistory.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResBillingHistory()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResBillingHistory',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResBillingHistory.$_createMessage)
    ..pPM<BillingHistoryRow>(1, _omitFieldNames ? '' : 'rows',
        subBuilder: BillingHistoryRow.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResBillingHistory clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResBillingHistory copyWith(void Function(ResBillingHistory) updates) =>
      super.copyWith((message) => updates(message as ResBillingHistory))
          as ResBillingHistory;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResBillingHistory() / ResBillingHistory.new instead')
  static ResBillingHistory create() => ResBillingHistory._();
  static $pb.GeneratedMessage $_createMessage() => ResBillingHistory._();
  @$core.override
  ResBillingHistory createEmptyInstance() => ResBillingHistory._();
  @$core.pragma('dart2js:noInline')
  static ResBillingHistory getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResBillingHistory>(
          ResBillingHistory.$_createMessage);
  static ResBillingHistory? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<BillingHistoryRow> get rows => $_getList(0);
}

class BillingPromotion extends $pb.GeneratedMessage {
  factory BillingPromotion({
    $fixnum.Int64? id,
    $core.String? code,
    $core.String? type,
    $core.String? audience,
    $core.String? name,
    $core.String? basePlanSlug,
    $core.double? poolMultiplier,
    $core.double? alienPoolIdr,
    $core.double? frontierPoolIdr,
    $core.int? durationDays,
    $core.int? durationMinutes,
    $core.int? maxClaimsTotal,
    $core.int? maxClaimsPerEmail,
    $fixnum.Int64? validFromMs,
    $fixnum.Int64? validToMs,
    $core.String? scope,
    $core.bool? isActive,
    $fixnum.Int64? createdByIid,
    $core.int? claimsCount,
    $fixnum.Int64? createdTsMs,
    $core.String? metaJson,
    $fixnum.Int64? updatedTsMs,
  }) {
    final result = BillingPromotion._();
    if (id != null) result.id = id;
    if (code != null) result.code = code;
    if (type != null) result.type = type;
    if (audience != null) result.audience = audience;
    if (name != null) result.name = name;
    if (basePlanSlug != null) result.basePlanSlug = basePlanSlug;
    if (poolMultiplier != null) result.poolMultiplier = poolMultiplier;
    if (alienPoolIdr != null) result.alienPoolIdr = alienPoolIdr;
    if (frontierPoolIdr != null) result.frontierPoolIdr = frontierPoolIdr;
    if (durationDays != null) result.durationDays = durationDays;
    if (durationMinutes != null) result.durationMinutes = durationMinutes;
    if (maxClaimsTotal != null) result.maxClaimsTotal = maxClaimsTotal;
    if (maxClaimsPerEmail != null) result.maxClaimsPerEmail = maxClaimsPerEmail;
    if (validFromMs != null) result.validFromMs = validFromMs;
    if (validToMs != null) result.validToMs = validToMs;
    if (scope != null) result.scope = scope;
    if (isActive != null) result.isActive = isActive;
    if (createdByIid != null) result.createdByIid = createdByIid;
    if (claimsCount != null) result.claimsCount = claimsCount;
    if (createdTsMs != null) result.createdTsMs = createdTsMs;
    if (metaJson != null) result.metaJson = metaJson;
    if (updatedTsMs != null) result.updatedTsMs = updatedTsMs;
    return result;
  }

  BillingPromotion._();

  factory BillingPromotion.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BillingPromotion()..mergeFromBuffer(data, registry);
  factory BillingPromotion.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BillingPromotion()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BillingPromotion',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: BillingPromotion.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'code')
    ..aOS(3, _omitFieldNames ? '' : 'type')
    ..aOS(4, _omitFieldNames ? '' : 'audience')
    ..aOS(5, _omitFieldNames ? '' : 'name')
    ..aOS(6, _omitFieldNames ? '' : 'basePlanSlug')
    ..aD(7, _omitFieldNames ? '' : 'poolMultiplier')
    ..aD(8, _omitFieldNames ? '' : 'alienPoolIdr')
    ..aD(9, _omitFieldNames ? '' : 'frontierPoolIdr')
    ..aI(10, _omitFieldNames ? '' : 'durationDays')
    ..aI(11, _omitFieldNames ? '' : 'durationMinutes')
    ..aI(12, _omitFieldNames ? '' : 'maxClaimsTotal')
    ..aI(13, _omitFieldNames ? '' : 'maxClaimsPerEmail')
    ..aInt64(14, _omitFieldNames ? '' : 'validFromMs')
    ..aInt64(15, _omitFieldNames ? '' : 'validToMs')
    ..aOS(16, _omitFieldNames ? '' : 'scope')
    ..aOB(17, _omitFieldNames ? '' : 'isActive')
    ..aInt64(18, _omitFieldNames ? '' : 'createdByIid')
    ..aI(19, _omitFieldNames ? '' : 'claimsCount')
    ..aInt64(20, _omitFieldNames ? '' : 'createdTsMs')
    ..aOS(21, _omitFieldNames ? '' : 'metaJson')
    ..aInt64(22, _omitFieldNames ? '' : 'updatedTsMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BillingPromotion clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BillingPromotion copyWith(void Function(BillingPromotion) updates) =>
      super.copyWith((message) => updates(message as BillingPromotion))
          as BillingPromotion;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use BillingPromotion() / BillingPromotion.new instead')
  static BillingPromotion create() => BillingPromotion._();
  static $pb.GeneratedMessage $_createMessage() => BillingPromotion._();
  @$core.override
  BillingPromotion createEmptyInstance() => BillingPromotion._();
  @$core.pragma('dart2js:noInline')
  static BillingPromotion getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BillingPromotion>(
          BillingPromotion.$_createMessage);
  static BillingPromotion? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get code => $_getSZ(1);
  @$pb.TagNumber(2)
  set code($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCode() => $_has(1);
  @$pb.TagNumber(2)
  void clearCode() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get type => $_getSZ(2);
  @$pb.TagNumber(3)
  set type($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasType() => $_has(2);
  @$pb.TagNumber(3)
  void clearType() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get audience => $_getSZ(3);
  @$pb.TagNumber(4)
  set audience($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAudience() => $_has(3);
  @$pb.TagNumber(4)
  void clearAudience() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get name => $_getSZ(4);
  @$pb.TagNumber(5)
  set name($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasName() => $_has(4);
  @$pb.TagNumber(5)
  void clearName() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get basePlanSlug => $_getSZ(5);
  @$pb.TagNumber(6)
  set basePlanSlug($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasBasePlanSlug() => $_has(5);
  @$pb.TagNumber(6)
  void clearBasePlanSlug() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.double get poolMultiplier => $_getN(6);
  @$pb.TagNumber(7)
  set poolMultiplier($core.double value) => $_setDouble(6, value);
  @$pb.TagNumber(7)
  $core.bool hasPoolMultiplier() => $_has(6);
  @$pb.TagNumber(7)
  void clearPoolMultiplier() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.double get alienPoolIdr => $_getN(7);
  @$pb.TagNumber(8)
  set alienPoolIdr($core.double value) => $_setDouble(7, value);
  @$pb.TagNumber(8)
  $core.bool hasAlienPoolIdr() => $_has(7);
  @$pb.TagNumber(8)
  void clearAlienPoolIdr() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.double get frontierPoolIdr => $_getN(8);
  @$pb.TagNumber(9)
  set frontierPoolIdr($core.double value) => $_setDouble(8, value);
  @$pb.TagNumber(9)
  $core.bool hasFrontierPoolIdr() => $_has(8);
  @$pb.TagNumber(9)
  void clearFrontierPoolIdr() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.int get durationDays => $_getIZ(9);
  @$pb.TagNumber(10)
  set durationDays($core.int value) => $_setSignedInt32(9, value);
  @$pb.TagNumber(10)
  $core.bool hasDurationDays() => $_has(9);
  @$pb.TagNumber(10)
  void clearDurationDays() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.int get durationMinutes => $_getIZ(10);
  @$pb.TagNumber(11)
  set durationMinutes($core.int value) => $_setSignedInt32(10, value);
  @$pb.TagNumber(11)
  $core.bool hasDurationMinutes() => $_has(10);
  @$pb.TagNumber(11)
  void clearDurationMinutes() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.int get maxClaimsTotal => $_getIZ(11);
  @$pb.TagNumber(12)
  set maxClaimsTotal($core.int value) => $_setSignedInt32(11, value);
  @$pb.TagNumber(12)
  $core.bool hasMaxClaimsTotal() => $_has(11);
  @$pb.TagNumber(12)
  void clearMaxClaimsTotal() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.int get maxClaimsPerEmail => $_getIZ(12);
  @$pb.TagNumber(13)
  set maxClaimsPerEmail($core.int value) => $_setSignedInt32(12, value);
  @$pb.TagNumber(13)
  $core.bool hasMaxClaimsPerEmail() => $_has(12);
  @$pb.TagNumber(13)
  void clearMaxClaimsPerEmail() => $_clearField(13);

  @$pb.TagNumber(14)
  $fixnum.Int64 get validFromMs => $_getI64(13);
  @$pb.TagNumber(14)
  set validFromMs($fixnum.Int64 value) => $_setInt64(13, value);
  @$pb.TagNumber(14)
  $core.bool hasValidFromMs() => $_has(13);
  @$pb.TagNumber(14)
  void clearValidFromMs() => $_clearField(14);

  @$pb.TagNumber(15)
  $fixnum.Int64 get validToMs => $_getI64(14);
  @$pb.TagNumber(15)
  set validToMs($fixnum.Int64 value) => $_setInt64(14, value);
  @$pb.TagNumber(15)
  $core.bool hasValidToMs() => $_has(14);
  @$pb.TagNumber(15)
  void clearValidToMs() => $_clearField(15);

  @$pb.TagNumber(16)
  $core.String get scope => $_getSZ(15);
  @$pb.TagNumber(16)
  set scope($core.String value) => $_setString(15, value);
  @$pb.TagNumber(16)
  $core.bool hasScope() => $_has(15);
  @$pb.TagNumber(16)
  void clearScope() => $_clearField(16);

  @$pb.TagNumber(17)
  $core.bool get isActive => $_getBF(16);
  @$pb.TagNumber(17)
  set isActive($core.bool value) => $_setBool(16, value);
  @$pb.TagNumber(17)
  $core.bool hasIsActive() => $_has(16);
  @$pb.TagNumber(17)
  void clearIsActive() => $_clearField(17);

  @$pb.TagNumber(18)
  $fixnum.Int64 get createdByIid => $_getI64(17);
  @$pb.TagNumber(18)
  set createdByIid($fixnum.Int64 value) => $_setInt64(17, value);
  @$pb.TagNumber(18)
  $core.bool hasCreatedByIid() => $_has(17);
  @$pb.TagNumber(18)
  void clearCreatedByIid() => $_clearField(18);

  @$pb.TagNumber(19)
  $core.int get claimsCount => $_getIZ(18);
  @$pb.TagNumber(19)
  set claimsCount($core.int value) => $_setSignedInt32(18, value);
  @$pb.TagNumber(19)
  $core.bool hasClaimsCount() => $_has(18);
  @$pb.TagNumber(19)
  void clearClaimsCount() => $_clearField(19);

  @$pb.TagNumber(20)
  $fixnum.Int64 get createdTsMs => $_getI64(19);
  @$pb.TagNumber(20)
  set createdTsMs($fixnum.Int64 value) => $_setInt64(19, value);
  @$pb.TagNumber(20)
  $core.bool hasCreatedTsMs() => $_has(19);
  @$pb.TagNumber(20)
  void clearCreatedTsMs() => $_clearField(20);

  @$pb.TagNumber(21)
  $core.String get metaJson => $_getSZ(20);
  @$pb.TagNumber(21)
  set metaJson($core.String value) => $_setString(20, value);
  @$pb.TagNumber(21)
  $core.bool hasMetaJson() => $_has(20);
  @$pb.TagNumber(21)
  void clearMetaJson() => $_clearField(21);

  @$pb.TagNumber(22)
  $fixnum.Int64 get updatedTsMs => $_getI64(21);
  @$pb.TagNumber(22)
  set updatedTsMs($fixnum.Int64 value) => $_setInt64(21, value);
  @$pb.TagNumber(22)
  $core.bool hasUpdatedTsMs() => $_has(21);
  @$pb.TagNumber(22)
  void clearUpdatedTsMs() => $_clearField(22);
}

class BillingPromotionClaim extends $pb.GeneratedMessage {
  factory BillingPromotionClaim({
    $fixnum.Int64? id,
    $fixnum.Int64? promotionId,
    $fixnum.Int64? ownerIid,
    $core.String? email,
    $fixnum.Int64? expiresTsMs,
    $core.double? alienPoolUsedIdr,
    $core.double? frontierPoolUsedIdr,
    $core.String? metaJson,
    $fixnum.Int64? createdTsMs,
  }) {
    final result = BillingPromotionClaim._();
    if (id != null) result.id = id;
    if (promotionId != null) result.promotionId = promotionId;
    if (ownerIid != null) result.ownerIid = ownerIid;
    if (email != null) result.email = email;
    if (expiresTsMs != null) result.expiresTsMs = expiresTsMs;
    if (alienPoolUsedIdr != null) result.alienPoolUsedIdr = alienPoolUsedIdr;
    if (frontierPoolUsedIdr != null)
      result.frontierPoolUsedIdr = frontierPoolUsedIdr;
    if (metaJson != null) result.metaJson = metaJson;
    if (createdTsMs != null) result.createdTsMs = createdTsMs;
    return result;
  }

  BillingPromotionClaim._();

  factory BillingPromotionClaim.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BillingPromotionClaim()..mergeFromBuffer(data, registry);
  factory BillingPromotionClaim.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BillingPromotionClaim()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BillingPromotionClaim',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: BillingPromotionClaim.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..aInt64(2, _omitFieldNames ? '' : 'promotionId')
    ..aInt64(3, _omitFieldNames ? '' : 'ownerIid')
    ..aOS(4, _omitFieldNames ? '' : 'email')
    ..aInt64(5, _omitFieldNames ? '' : 'expiresTsMs')
    ..aD(6, _omitFieldNames ? '' : 'alienPoolUsedIdr')
    ..aD(7, _omitFieldNames ? '' : 'frontierPoolUsedIdr')
    ..aOS(8, _omitFieldNames ? '' : 'metaJson')
    ..aInt64(9, _omitFieldNames ? '' : 'createdTsMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BillingPromotionClaim clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BillingPromotionClaim copyWith(
          void Function(BillingPromotionClaim) updates) =>
      super.copyWith((message) => updates(message as BillingPromotionClaim))
          as BillingPromotionClaim;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use BillingPromotionClaim() / BillingPromotionClaim.new instead')
  static BillingPromotionClaim create() => BillingPromotionClaim._();
  static $pb.GeneratedMessage $_createMessage() => BillingPromotionClaim._();
  @$core.override
  BillingPromotionClaim createEmptyInstance() => BillingPromotionClaim._();
  @$core.pragma('dart2js:noInline')
  static BillingPromotionClaim getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BillingPromotionClaim>(
          BillingPromotionClaim.$_createMessage);
  static BillingPromotionClaim? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get promotionId => $_getI64(1);
  @$pb.TagNumber(2)
  set promotionId($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPromotionId() => $_has(1);
  @$pb.TagNumber(2)
  void clearPromotionId() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get ownerIid => $_getI64(2);
  @$pb.TagNumber(3)
  set ownerIid($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasOwnerIid() => $_has(2);
  @$pb.TagNumber(3)
  void clearOwnerIid() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get email => $_getSZ(3);
  @$pb.TagNumber(4)
  set email($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasEmail() => $_has(3);
  @$pb.TagNumber(4)
  void clearEmail() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get expiresTsMs => $_getI64(4);
  @$pb.TagNumber(5)
  set expiresTsMs($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasExpiresTsMs() => $_has(4);
  @$pb.TagNumber(5)
  void clearExpiresTsMs() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.double get alienPoolUsedIdr => $_getN(5);
  @$pb.TagNumber(6)
  set alienPoolUsedIdr($core.double value) => $_setDouble(5, value);
  @$pb.TagNumber(6)
  $core.bool hasAlienPoolUsedIdr() => $_has(5);
  @$pb.TagNumber(6)
  void clearAlienPoolUsedIdr() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.double get frontierPoolUsedIdr => $_getN(6);
  @$pb.TagNumber(7)
  set frontierPoolUsedIdr($core.double value) => $_setDouble(6, value);
  @$pb.TagNumber(7)
  $core.bool hasFrontierPoolUsedIdr() => $_has(6);
  @$pb.TagNumber(7)
  void clearFrontierPoolUsedIdr() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get metaJson => $_getSZ(7);
  @$pb.TagNumber(8)
  set metaJson($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasMetaJson() => $_has(7);
  @$pb.TagNumber(8)
  void clearMetaJson() => $_clearField(8);

  @$pb.TagNumber(9)
  $fixnum.Int64 get createdTsMs => $_getI64(8);
  @$pb.TagNumber(9)
  set createdTsMs($fixnum.Int64 value) => $_setInt64(8, value);
  @$pb.TagNumber(9)
  $core.bool hasCreatedTsMs() => $_has(8);
  @$pb.TagNumber(9)
  void clearCreatedTsMs() => $_clearField(9);
}

class ReqBillingPromotionCreate extends $pb.GeneratedMessage {
  factory ReqBillingPromotionCreate({
    $core.String? code,
    $core.String? type,
    $core.String? audience,
    $core.String? name,
    $core.String? basePlanSlug,
    $core.double? poolMultiplier,
    $core.double? alienPoolIdr,
    $core.double? frontierPoolIdr,
    $core.int? durationDays,
    $core.int? durationMinutes,
    $core.int? maxClaimsTotal,
    $core.int? maxClaimsPerEmail,
    $fixnum.Int64? validFromMs,
    $fixnum.Int64? validToMs,
    $core.String? scope,
    $core.bool? isActive,
  }) {
    final result = ReqBillingPromotionCreate._();
    if (code != null) result.code = code;
    if (type != null) result.type = type;
    if (audience != null) result.audience = audience;
    if (name != null) result.name = name;
    if (basePlanSlug != null) result.basePlanSlug = basePlanSlug;
    if (poolMultiplier != null) result.poolMultiplier = poolMultiplier;
    if (alienPoolIdr != null) result.alienPoolIdr = alienPoolIdr;
    if (frontierPoolIdr != null) result.frontierPoolIdr = frontierPoolIdr;
    if (durationDays != null) result.durationDays = durationDays;
    if (durationMinutes != null) result.durationMinutes = durationMinutes;
    if (maxClaimsTotal != null) result.maxClaimsTotal = maxClaimsTotal;
    if (maxClaimsPerEmail != null) result.maxClaimsPerEmail = maxClaimsPerEmail;
    if (validFromMs != null) result.validFromMs = validFromMs;
    if (validToMs != null) result.validToMs = validToMs;
    if (scope != null) result.scope = scope;
    if (isActive != null) result.isActive = isActive;
    return result;
  }

  ReqBillingPromotionCreate._();

  factory ReqBillingPromotionCreate.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqBillingPromotionCreate()..mergeFromBuffer(data, registry);
  factory ReqBillingPromotionCreate.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqBillingPromotionCreate()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqBillingPromotionCreate',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqBillingPromotionCreate.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'code')
    ..aOS(2, _omitFieldNames ? '' : 'type')
    ..aOS(3, _omitFieldNames ? '' : 'audience')
    ..aOS(4, _omitFieldNames ? '' : 'name')
    ..aOS(5, _omitFieldNames ? '' : 'basePlanSlug')
    ..aD(6, _omitFieldNames ? '' : 'poolMultiplier')
    ..aD(7, _omitFieldNames ? '' : 'alienPoolIdr')
    ..aD(8, _omitFieldNames ? '' : 'frontierPoolIdr')
    ..aI(9, _omitFieldNames ? '' : 'durationDays')
    ..aI(10, _omitFieldNames ? '' : 'durationMinutes')
    ..aI(11, _omitFieldNames ? '' : 'maxClaimsTotal')
    ..aI(12, _omitFieldNames ? '' : 'maxClaimsPerEmail')
    ..aInt64(13, _omitFieldNames ? '' : 'validFromMs')
    ..aInt64(14, _omitFieldNames ? '' : 'validToMs')
    ..aOS(15, _omitFieldNames ? '' : 'scope')
    ..aOB(16, _omitFieldNames ? '' : 'isActive')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqBillingPromotionCreate clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqBillingPromotionCreate copyWith(
          void Function(ReqBillingPromotionCreate) updates) =>
      super.copyWith((message) => updates(message as ReqBillingPromotionCreate))
          as ReqBillingPromotionCreate;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ReqBillingPromotionCreate() / ReqBillingPromotionCreate.new instead')
  static ReqBillingPromotionCreate create() => ReqBillingPromotionCreate._();
  static $pb.GeneratedMessage $_createMessage() =>
      ReqBillingPromotionCreate._();
  @$core.override
  ReqBillingPromotionCreate createEmptyInstance() =>
      ReqBillingPromotionCreate._();
  @$core.pragma('dart2js:noInline')
  static ReqBillingPromotionCreate getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqBillingPromotionCreate>(
          ReqBillingPromotionCreate.$_createMessage);
  static ReqBillingPromotionCreate? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get code => $_getSZ(0);
  @$pb.TagNumber(1)
  set code($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCode() => $_has(0);
  @$pb.TagNumber(1)
  void clearCode() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get type => $_getSZ(1);
  @$pb.TagNumber(2)
  set type($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasType() => $_has(1);
  @$pb.TagNumber(2)
  void clearType() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get audience => $_getSZ(2);
  @$pb.TagNumber(3)
  set audience($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAudience() => $_has(2);
  @$pb.TagNumber(3)
  void clearAudience() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get name => $_getSZ(3);
  @$pb.TagNumber(4)
  set name($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasName() => $_has(3);
  @$pb.TagNumber(4)
  void clearName() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get basePlanSlug => $_getSZ(4);
  @$pb.TagNumber(5)
  set basePlanSlug($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasBasePlanSlug() => $_has(4);
  @$pb.TagNumber(5)
  void clearBasePlanSlug() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.double get poolMultiplier => $_getN(5);
  @$pb.TagNumber(6)
  set poolMultiplier($core.double value) => $_setDouble(5, value);
  @$pb.TagNumber(6)
  $core.bool hasPoolMultiplier() => $_has(5);
  @$pb.TagNumber(6)
  void clearPoolMultiplier() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.double get alienPoolIdr => $_getN(6);
  @$pb.TagNumber(7)
  set alienPoolIdr($core.double value) => $_setDouble(6, value);
  @$pb.TagNumber(7)
  $core.bool hasAlienPoolIdr() => $_has(6);
  @$pb.TagNumber(7)
  void clearAlienPoolIdr() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.double get frontierPoolIdr => $_getN(7);
  @$pb.TagNumber(8)
  set frontierPoolIdr($core.double value) => $_setDouble(7, value);
  @$pb.TagNumber(8)
  $core.bool hasFrontierPoolIdr() => $_has(7);
  @$pb.TagNumber(8)
  void clearFrontierPoolIdr() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.int get durationDays => $_getIZ(8);
  @$pb.TagNumber(9)
  set durationDays($core.int value) => $_setSignedInt32(8, value);
  @$pb.TagNumber(9)
  $core.bool hasDurationDays() => $_has(8);
  @$pb.TagNumber(9)
  void clearDurationDays() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.int get durationMinutes => $_getIZ(9);
  @$pb.TagNumber(10)
  set durationMinutes($core.int value) => $_setSignedInt32(9, value);
  @$pb.TagNumber(10)
  $core.bool hasDurationMinutes() => $_has(9);
  @$pb.TagNumber(10)
  void clearDurationMinutes() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.int get maxClaimsTotal => $_getIZ(10);
  @$pb.TagNumber(11)
  set maxClaimsTotal($core.int value) => $_setSignedInt32(10, value);
  @$pb.TagNumber(11)
  $core.bool hasMaxClaimsTotal() => $_has(10);
  @$pb.TagNumber(11)
  void clearMaxClaimsTotal() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.int get maxClaimsPerEmail => $_getIZ(11);
  @$pb.TagNumber(12)
  set maxClaimsPerEmail($core.int value) => $_setSignedInt32(11, value);
  @$pb.TagNumber(12)
  $core.bool hasMaxClaimsPerEmail() => $_has(11);
  @$pb.TagNumber(12)
  void clearMaxClaimsPerEmail() => $_clearField(12);

  @$pb.TagNumber(13)
  $fixnum.Int64 get validFromMs => $_getI64(12);
  @$pb.TagNumber(13)
  set validFromMs($fixnum.Int64 value) => $_setInt64(12, value);
  @$pb.TagNumber(13)
  $core.bool hasValidFromMs() => $_has(12);
  @$pb.TagNumber(13)
  void clearValidFromMs() => $_clearField(13);

  @$pb.TagNumber(14)
  $fixnum.Int64 get validToMs => $_getI64(13);
  @$pb.TagNumber(14)
  set validToMs($fixnum.Int64 value) => $_setInt64(13, value);
  @$pb.TagNumber(14)
  $core.bool hasValidToMs() => $_has(13);
  @$pb.TagNumber(14)
  void clearValidToMs() => $_clearField(14);

  @$pb.TagNumber(15)
  $core.String get scope => $_getSZ(14);
  @$pb.TagNumber(15)
  set scope($core.String value) => $_setString(14, value);
  @$pb.TagNumber(15)
  $core.bool hasScope() => $_has(14);
  @$pb.TagNumber(15)
  void clearScope() => $_clearField(15);

  @$pb.TagNumber(16)
  $core.bool get isActive => $_getBF(15);
  @$pb.TagNumber(16)
  set isActive($core.bool value) => $_setBool(15, value);
  @$pb.TagNumber(16)
  $core.bool hasIsActive() => $_has(15);
  @$pb.TagNumber(16)
  void clearIsActive() => $_clearField(16);
}

class ResBillingPromotionCreate extends $pb.GeneratedMessage {
  factory ResBillingPromotionCreate({
    $fixnum.Int64? promotionId,
    BillingPromotion? promotion,
  }) {
    final result = ResBillingPromotionCreate._();
    if (promotionId != null) result.promotionId = promotionId;
    if (promotion != null) result.promotion = promotion;
    return result;
  }

  ResBillingPromotionCreate._();

  factory ResBillingPromotionCreate.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResBillingPromotionCreate()..mergeFromBuffer(data, registry);
  factory ResBillingPromotionCreate.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResBillingPromotionCreate()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResBillingPromotionCreate',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResBillingPromotionCreate.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'promotionId')
    ..aOM<BillingPromotion>(2, _omitFieldNames ? '' : 'promotion',
        subBuilder: BillingPromotion.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResBillingPromotionCreate clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResBillingPromotionCreate copyWith(
          void Function(ResBillingPromotionCreate) updates) =>
      super.copyWith((message) => updates(message as ResBillingPromotionCreate))
          as ResBillingPromotionCreate;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ResBillingPromotionCreate() / ResBillingPromotionCreate.new instead')
  static ResBillingPromotionCreate create() => ResBillingPromotionCreate._();
  static $pb.GeneratedMessage $_createMessage() =>
      ResBillingPromotionCreate._();
  @$core.override
  ResBillingPromotionCreate createEmptyInstance() =>
      ResBillingPromotionCreate._();
  @$core.pragma('dart2js:noInline')
  static ResBillingPromotionCreate getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResBillingPromotionCreate>(
          ResBillingPromotionCreate.$_createMessage);
  static ResBillingPromotionCreate? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get promotionId => $_getI64(0);
  @$pb.TagNumber(1)
  set promotionId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPromotionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPromotionId() => $_clearField(1);

  @$pb.TagNumber(2)
  BillingPromotion get promotion => $_getN(1);
  @$pb.TagNumber(2)
  set promotion(BillingPromotion value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasPromotion() => $_has(1);
  @$pb.TagNumber(2)
  void clearPromotion() => $_clearField(2);
  @$pb.TagNumber(2)
  BillingPromotion ensurePromotion() => $_ensure(1);
}

class ReqBillingPromotionClaim extends $pb.GeneratedMessage {
  factory ReqBillingPromotionClaim({
    $core.String? code,
    $core.String? email,
    $fixnum.Int64? promotionId,
  }) {
    final result = ReqBillingPromotionClaim._();
    if (code != null) result.code = code;
    if (email != null) result.email = email;
    if (promotionId != null) result.promotionId = promotionId;
    return result;
  }

  ReqBillingPromotionClaim._();

  factory ReqBillingPromotionClaim.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqBillingPromotionClaim()..mergeFromBuffer(data, registry);
  factory ReqBillingPromotionClaim.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqBillingPromotionClaim()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqBillingPromotionClaim',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqBillingPromotionClaim.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'code')
    ..aOS(2, _omitFieldNames ? '' : 'email')
    ..aInt64(3, _omitFieldNames ? '' : 'promotionId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqBillingPromotionClaim clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqBillingPromotionClaim copyWith(
          void Function(ReqBillingPromotionClaim) updates) =>
      super.copyWith((message) => updates(message as ReqBillingPromotionClaim))
          as ReqBillingPromotionClaim;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ReqBillingPromotionClaim() / ReqBillingPromotionClaim.new instead')
  static ReqBillingPromotionClaim create() => ReqBillingPromotionClaim._();
  static $pb.GeneratedMessage $_createMessage() => ReqBillingPromotionClaim._();
  @$core.override
  ReqBillingPromotionClaim createEmptyInstance() =>
      ReqBillingPromotionClaim._();
  @$core.pragma('dart2js:noInline')
  static ReqBillingPromotionClaim getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqBillingPromotionClaim>(
          ReqBillingPromotionClaim.$_createMessage);
  static ReqBillingPromotionClaim? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get code => $_getSZ(0);
  @$pb.TagNumber(1)
  set code($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCode() => $_has(0);
  @$pb.TagNumber(1)
  void clearCode() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get email => $_getSZ(1);
  @$pb.TagNumber(2)
  set email($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEmail() => $_has(1);
  @$pb.TagNumber(2)
  void clearEmail() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get promotionId => $_getI64(2);
  @$pb.TagNumber(3)
  set promotionId($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPromotionId() => $_has(2);
  @$pb.TagNumber(3)
  void clearPromotionId() => $_clearField(3);
}

class ResBillingPromotionClaim extends $pb.GeneratedMessage {
  factory ResBillingPromotionClaim({
    $fixnum.Int64? claimId,
    $fixnum.Int64? promotionId,
    $core.double? alienPoolLimitIdr,
    $core.double? frontierPoolLimitIdr,
    $fixnum.Int64? expiresTsMs,
    $core.String? planTier,
    $core.String? promoType,
    BillingPromotionClaim? claim,
    BillingPromotion? promotion,
    BillingProfile? profile,
  }) {
    final result = ResBillingPromotionClaim._();
    if (claimId != null) result.claimId = claimId;
    if (promotionId != null) result.promotionId = promotionId;
    if (alienPoolLimitIdr != null) result.alienPoolLimitIdr = alienPoolLimitIdr;
    if (frontierPoolLimitIdr != null)
      result.frontierPoolLimitIdr = frontierPoolLimitIdr;
    if (expiresTsMs != null) result.expiresTsMs = expiresTsMs;
    if (planTier != null) result.planTier = planTier;
    if (promoType != null) result.promoType = promoType;
    if (claim != null) result.claim = claim;
    if (promotion != null) result.promotion = promotion;
    if (profile != null) result.profile = profile;
    return result;
  }

  ResBillingPromotionClaim._();

  factory ResBillingPromotionClaim.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResBillingPromotionClaim()..mergeFromBuffer(data, registry);
  factory ResBillingPromotionClaim.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResBillingPromotionClaim()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResBillingPromotionClaim',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResBillingPromotionClaim.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'claimId')
    ..aInt64(2, _omitFieldNames ? '' : 'promotionId')
    ..aD(3, _omitFieldNames ? '' : 'alienPoolLimitIdr')
    ..aD(4, _omitFieldNames ? '' : 'frontierPoolLimitIdr')
    ..aInt64(5, _omitFieldNames ? '' : 'expiresTsMs')
    ..aOS(6, _omitFieldNames ? '' : 'planTier')
    ..aOS(7, _omitFieldNames ? '' : 'promoType')
    ..aOM<BillingPromotionClaim>(8, _omitFieldNames ? '' : 'claim',
        subBuilder: BillingPromotionClaim.$_createMessage)
    ..aOM<BillingPromotion>(9, _omitFieldNames ? '' : 'promotion',
        subBuilder: BillingPromotion.$_createMessage)
    ..aOM<BillingProfile>(10, _omitFieldNames ? '' : 'profile',
        subBuilder: BillingProfile.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResBillingPromotionClaim clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResBillingPromotionClaim copyWith(
          void Function(ResBillingPromotionClaim) updates) =>
      super.copyWith((message) => updates(message as ResBillingPromotionClaim))
          as ResBillingPromotionClaim;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ResBillingPromotionClaim() / ResBillingPromotionClaim.new instead')
  static ResBillingPromotionClaim create() => ResBillingPromotionClaim._();
  static $pb.GeneratedMessage $_createMessage() => ResBillingPromotionClaim._();
  @$core.override
  ResBillingPromotionClaim createEmptyInstance() =>
      ResBillingPromotionClaim._();
  @$core.pragma('dart2js:noInline')
  static ResBillingPromotionClaim getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResBillingPromotionClaim>(
          ResBillingPromotionClaim.$_createMessage);
  static ResBillingPromotionClaim? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get claimId => $_getI64(0);
  @$pb.TagNumber(1)
  set claimId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasClaimId() => $_has(0);
  @$pb.TagNumber(1)
  void clearClaimId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get promotionId => $_getI64(1);
  @$pb.TagNumber(2)
  set promotionId($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPromotionId() => $_has(1);
  @$pb.TagNumber(2)
  void clearPromotionId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get alienPoolLimitIdr => $_getN(2);
  @$pb.TagNumber(3)
  set alienPoolLimitIdr($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAlienPoolLimitIdr() => $_has(2);
  @$pb.TagNumber(3)
  void clearAlienPoolLimitIdr() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get frontierPoolLimitIdr => $_getN(3);
  @$pb.TagNumber(4)
  set frontierPoolLimitIdr($core.double value) => $_setDouble(3, value);
  @$pb.TagNumber(4)
  $core.bool hasFrontierPoolLimitIdr() => $_has(3);
  @$pb.TagNumber(4)
  void clearFrontierPoolLimitIdr() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get expiresTsMs => $_getI64(4);
  @$pb.TagNumber(5)
  set expiresTsMs($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasExpiresTsMs() => $_has(4);
  @$pb.TagNumber(5)
  void clearExpiresTsMs() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get planTier => $_getSZ(5);
  @$pb.TagNumber(6)
  set planTier($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasPlanTier() => $_has(5);
  @$pb.TagNumber(6)
  void clearPlanTier() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get promoType => $_getSZ(6);
  @$pb.TagNumber(7)
  set promoType($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasPromoType() => $_has(6);
  @$pb.TagNumber(7)
  void clearPromoType() => $_clearField(7);

  @$pb.TagNumber(8)
  BillingPromotionClaim get claim => $_getN(7);
  @$pb.TagNumber(8)
  set claim(BillingPromotionClaim value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasClaim() => $_has(7);
  @$pb.TagNumber(8)
  void clearClaim() => $_clearField(8);
  @$pb.TagNumber(8)
  BillingPromotionClaim ensureClaim() => $_ensure(7);

  @$pb.TagNumber(9)
  BillingPromotion get promotion => $_getN(8);
  @$pb.TagNumber(9)
  set promotion(BillingPromotion value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasPromotion() => $_has(8);
  @$pb.TagNumber(9)
  void clearPromotion() => $_clearField(9);
  @$pb.TagNumber(9)
  BillingPromotion ensurePromotion() => $_ensure(8);

  @$pb.TagNumber(10)
  BillingProfile get profile => $_getN(9);
  @$pb.TagNumber(10)
  set profile(BillingProfile value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasProfile() => $_has(9);
  @$pb.TagNumber(10)
  void clearProfile() => $_clearField(10);
  @$pb.TagNumber(10)
  BillingProfile ensureProfile() => $_ensure(9);
}

class ReqBillingPromotionList extends $pb.GeneratedMessage {
  factory ReqBillingPromotionList() => ReqBillingPromotionList._();

  ReqBillingPromotionList._();

  factory ReqBillingPromotionList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqBillingPromotionList()..mergeFromBuffer(data, registry);
  factory ReqBillingPromotionList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqBillingPromotionList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqBillingPromotionList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqBillingPromotionList.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqBillingPromotionList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqBillingPromotionList copyWith(
          void Function(ReqBillingPromotionList) updates) =>
      super.copyWith((message) => updates(message as ReqBillingPromotionList))
          as ReqBillingPromotionList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ReqBillingPromotionList() / ReqBillingPromotionList.new instead')
  static ReqBillingPromotionList create() => ReqBillingPromotionList._();
  static $pb.GeneratedMessage $_createMessage() => ReqBillingPromotionList._();
  @$core.override
  ReqBillingPromotionList createEmptyInstance() => ReqBillingPromotionList._();
  @$core.pragma('dart2js:noInline')
  static ReqBillingPromotionList getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqBillingPromotionList>(
          ReqBillingPromotionList.$_createMessage);
  static ReqBillingPromotionList? _defaultInstance;
}

class ResBillingPromotionList extends $pb.GeneratedMessage {
  factory ResBillingPromotionList({
    $core.Iterable<BillingPromotion>? items,
  }) {
    final result = ResBillingPromotionList._();
    if (items != null) result.items.addAll(items);
    return result;
  }

  ResBillingPromotionList._();

  factory ResBillingPromotionList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResBillingPromotionList()..mergeFromBuffer(data, registry);
  factory ResBillingPromotionList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResBillingPromotionList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResBillingPromotionList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResBillingPromotionList.$_createMessage)
    ..pPM<BillingPromotion>(1, _omitFieldNames ? '' : 'items',
        subBuilder: BillingPromotion.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResBillingPromotionList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResBillingPromotionList copyWith(
          void Function(ResBillingPromotionList) updates) =>
      super.copyWith((message) => updates(message as ResBillingPromotionList))
          as ResBillingPromotionList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ResBillingPromotionList() / ResBillingPromotionList.new instead')
  static ResBillingPromotionList create() => ResBillingPromotionList._();
  static $pb.GeneratedMessage $_createMessage() => ResBillingPromotionList._();
  @$core.override
  ResBillingPromotionList createEmptyInstance() => ResBillingPromotionList._();
  @$core.pragma('dart2js:noInline')
  static ResBillingPromotionList getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResBillingPromotionList>(
          ResBillingPromotionList.$_createMessage);
  static ResBillingPromotionList? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<BillingPromotion> get items => $_getList(0);
}

class ResBillingSummary extends $pb.GeneratedMessage {
  factory ResBillingSummary({
    $core.double? balanceUsd,
    $core.String? planTier,
    $core.int? quota5hUsed,
    $core.int? quota5hLimit,
    $fixnum.Int64? window5hResetsAtMs,
    $core.String? meterState,
    $core.bool? botsPaused,
    $core.int? quotaWeeklyUsed,
    $core.int? quotaWeeklyLimit,
    $fixnum.Int64? windowWeeklyResetsAtMs,
    $core.double? balanceIdr,
    $core.double? commissionAvailableUsd,
    $core.double? commissionAvailableIdr,
    $core.double? alienAllow5hUsed,
    $core.double? alienAllow5hLimit,
    $core.double? alienAllowWeeklyUsed,
    $core.double? alienAllowWeeklyLimit,
    $core.Iterable<BillingPlanDoc>? plans,
    $core.bool? overageEnabled,
  }) {
    final result = ResBillingSummary._();
    if (balanceUsd != null) result.balanceUsd = balanceUsd;
    if (planTier != null) result.planTier = planTier;
    if (quota5hUsed != null) result.quota5hUsed = quota5hUsed;
    if (quota5hLimit != null) result.quota5hLimit = quota5hLimit;
    if (window5hResetsAtMs != null)
      result.window5hResetsAtMs = window5hResetsAtMs;
    if (meterState != null) result.meterState = meterState;
    if (botsPaused != null) result.botsPaused = botsPaused;
    if (quotaWeeklyUsed != null) result.quotaWeeklyUsed = quotaWeeklyUsed;
    if (quotaWeeklyLimit != null) result.quotaWeeklyLimit = quotaWeeklyLimit;
    if (windowWeeklyResetsAtMs != null)
      result.windowWeeklyResetsAtMs = windowWeeklyResetsAtMs;
    if (balanceIdr != null) result.balanceIdr = balanceIdr;
    if (commissionAvailableUsd != null)
      result.commissionAvailableUsd = commissionAvailableUsd;
    if (commissionAvailableIdr != null)
      result.commissionAvailableIdr = commissionAvailableIdr;
    if (alienAllow5hUsed != null) result.alienAllow5hUsed = alienAllow5hUsed;
    if (alienAllow5hLimit != null) result.alienAllow5hLimit = alienAllow5hLimit;
    if (alienAllowWeeklyUsed != null)
      result.alienAllowWeeklyUsed = alienAllowWeeklyUsed;
    if (alienAllowWeeklyLimit != null)
      result.alienAllowWeeklyLimit = alienAllowWeeklyLimit;
    if (plans != null) result.plans.addAll(plans);
    if (overageEnabled != null) result.overageEnabled = overageEnabled;
    return result;
  }

  ResBillingSummary._();

  factory ResBillingSummary.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResBillingSummary()..mergeFromBuffer(data, registry);
  factory ResBillingSummary.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResBillingSummary()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResBillingSummary',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResBillingSummary.$_createMessage)
    ..aD(1, _omitFieldNames ? '' : 'balanceUsd')
    ..aOS(2, _omitFieldNames ? '' : 'planTier')
    ..aI(3, _omitFieldNames ? '' : 'quota5hUsed', protoName: 'quota_5h_used')
    ..aI(4, _omitFieldNames ? '' : 'quota5hLimit', protoName: 'quota_5h_limit')
    ..aInt64(5, _omitFieldNames ? '' : 'window5hResetsAtMs',
        protoName: 'window_5h_resets_at_ms')
    ..aOS(6, _omitFieldNames ? '' : 'meterState')
    ..aOB(7, _omitFieldNames ? '' : 'botsPaused')
    ..aI(8, _omitFieldNames ? '' : 'quotaWeeklyUsed')
    ..aI(9, _omitFieldNames ? '' : 'quotaWeeklyLimit')
    ..aInt64(10, _omitFieldNames ? '' : 'windowWeeklyResetsAtMs')
    ..aD(11, _omitFieldNames ? '' : 'balanceIdr')
    ..aD(12, _omitFieldNames ? '' : 'commissionAvailableUsd')
    ..aD(13, _omitFieldNames ? '' : 'commissionAvailableIdr')
    ..aD(14, _omitFieldNames ? '' : 'alienAllow5hUsed',
        protoName: 'alien_allow_5h_used')
    ..aD(15, _omitFieldNames ? '' : 'alienAllow5hLimit',
        protoName: 'alien_allow_5h_limit')
    ..aD(16, _omitFieldNames ? '' : 'alienAllowWeeklyUsed')
    ..aD(17, _omitFieldNames ? '' : 'alienAllowWeeklyLimit')
    ..pPM<BillingPlanDoc>(18, _omitFieldNames ? '' : 'plans',
        subBuilder: BillingPlanDoc.$_createMessage)
    ..aOB(19, _omitFieldNames ? '' : 'overageEnabled')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResBillingSummary clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResBillingSummary copyWith(void Function(ResBillingSummary) updates) =>
      super.copyWith((message) => updates(message as ResBillingSummary))
          as ResBillingSummary;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResBillingSummary() / ResBillingSummary.new instead')
  static ResBillingSummary create() => ResBillingSummary._();
  static $pb.GeneratedMessage $_createMessage() => ResBillingSummary._();
  @$core.override
  ResBillingSummary createEmptyInstance() => ResBillingSummary._();
  @$core.pragma('dart2js:noInline')
  static ResBillingSummary getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResBillingSummary>(
          ResBillingSummary.$_createMessage);
  static ResBillingSummary? _defaultInstance;

  @$pb.TagNumber(1)
  $core.double get balanceUsd => $_getN(0);
  @$pb.TagNumber(1)
  set balanceUsd($core.double value) => $_setDouble(0, value);
  @$pb.TagNumber(1)
  $core.bool hasBalanceUsd() => $_has(0);
  @$pb.TagNumber(1)
  void clearBalanceUsd() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get planTier => $_getSZ(1);
  @$pb.TagNumber(2)
  set planTier($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPlanTier() => $_has(1);
  @$pb.TagNumber(2)
  void clearPlanTier() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get quota5hUsed => $_getIZ(2);
  @$pb.TagNumber(3)
  set quota5hUsed($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasQuota5hUsed() => $_has(2);
  @$pb.TagNumber(3)
  void clearQuota5hUsed() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get quota5hLimit => $_getIZ(3);
  @$pb.TagNumber(4)
  set quota5hLimit($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasQuota5hLimit() => $_has(3);
  @$pb.TagNumber(4)
  void clearQuota5hLimit() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get window5hResetsAtMs => $_getI64(4);
  @$pb.TagNumber(5)
  set window5hResetsAtMs($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasWindow5hResetsAtMs() => $_has(4);
  @$pb.TagNumber(5)
  void clearWindow5hResetsAtMs() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get meterState => $_getSZ(5);
  @$pb.TagNumber(6)
  set meterState($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasMeterState() => $_has(5);
  @$pb.TagNumber(6)
  void clearMeterState() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.bool get botsPaused => $_getBF(6);
  @$pb.TagNumber(7)
  set botsPaused($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasBotsPaused() => $_has(6);
  @$pb.TagNumber(7)
  void clearBotsPaused() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.int get quotaWeeklyUsed => $_getIZ(7);
  @$pb.TagNumber(8)
  set quotaWeeklyUsed($core.int value) => $_setSignedInt32(7, value);
  @$pb.TagNumber(8)
  $core.bool hasQuotaWeeklyUsed() => $_has(7);
  @$pb.TagNumber(8)
  void clearQuotaWeeklyUsed() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.int get quotaWeeklyLimit => $_getIZ(8);
  @$pb.TagNumber(9)
  set quotaWeeklyLimit($core.int value) => $_setSignedInt32(8, value);
  @$pb.TagNumber(9)
  $core.bool hasQuotaWeeklyLimit() => $_has(8);
  @$pb.TagNumber(9)
  void clearQuotaWeeklyLimit() => $_clearField(9);

  @$pb.TagNumber(10)
  $fixnum.Int64 get windowWeeklyResetsAtMs => $_getI64(9);
  @$pb.TagNumber(10)
  set windowWeeklyResetsAtMs($fixnum.Int64 value) => $_setInt64(9, value);
  @$pb.TagNumber(10)
  $core.bool hasWindowWeeklyResetsAtMs() => $_has(9);
  @$pb.TagNumber(10)
  void clearWindowWeeklyResetsAtMs() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.double get balanceIdr => $_getN(10);
  @$pb.TagNumber(11)
  set balanceIdr($core.double value) => $_setDouble(10, value);
  @$pb.TagNumber(11)
  $core.bool hasBalanceIdr() => $_has(10);
  @$pb.TagNumber(11)
  void clearBalanceIdr() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.double get commissionAvailableUsd => $_getN(11);
  @$pb.TagNumber(12)
  set commissionAvailableUsd($core.double value) => $_setDouble(11, value);
  @$pb.TagNumber(12)
  $core.bool hasCommissionAvailableUsd() => $_has(11);
  @$pb.TagNumber(12)
  void clearCommissionAvailableUsd() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.double get commissionAvailableIdr => $_getN(12);
  @$pb.TagNumber(13)
  set commissionAvailableIdr($core.double value) => $_setDouble(12, value);
  @$pb.TagNumber(13)
  $core.bool hasCommissionAvailableIdr() => $_has(12);
  @$pb.TagNumber(13)
  void clearCommissionAvailableIdr() => $_clearField(13);

  @$pb.TagNumber(14)
  $core.double get alienAllow5hUsed => $_getN(13);
  @$pb.TagNumber(14)
  set alienAllow5hUsed($core.double value) => $_setDouble(13, value);
  @$pb.TagNumber(14)
  $core.bool hasAlienAllow5hUsed() => $_has(13);
  @$pb.TagNumber(14)
  void clearAlienAllow5hUsed() => $_clearField(14);

  @$pb.TagNumber(15)
  $core.double get alienAllow5hLimit => $_getN(14);
  @$pb.TagNumber(15)
  set alienAllow5hLimit($core.double value) => $_setDouble(14, value);
  @$pb.TagNumber(15)
  $core.bool hasAlienAllow5hLimit() => $_has(14);
  @$pb.TagNumber(15)
  void clearAlienAllow5hLimit() => $_clearField(15);

  @$pb.TagNumber(16)
  $core.double get alienAllowWeeklyUsed => $_getN(15);
  @$pb.TagNumber(16)
  set alienAllowWeeklyUsed($core.double value) => $_setDouble(15, value);
  @$pb.TagNumber(16)
  $core.bool hasAlienAllowWeeklyUsed() => $_has(15);
  @$pb.TagNumber(16)
  void clearAlienAllowWeeklyUsed() => $_clearField(16);

  @$pb.TagNumber(17)
  $core.double get alienAllowWeeklyLimit => $_getN(16);
  @$pb.TagNumber(17)
  set alienAllowWeeklyLimit($core.double value) => $_setDouble(16, value);
  @$pb.TagNumber(17)
  $core.bool hasAlienAllowWeeklyLimit() => $_has(16);
  @$pb.TagNumber(17)
  void clearAlienAllowWeeklyLimit() => $_clearField(17);

  @$pb.TagNumber(18)
  $pb.PbList<BillingPlanDoc> get plans => $_getList(17);

  @$pb.TagNumber(19)
  $core.bool get overageEnabled => $_getBF(18);
  @$pb.TagNumber(19)
  set overageEnabled($core.bool value) => $_setBool(18, value);
  @$pb.TagNumber(19)
  $core.bool hasOverageEnabled() => $_has(18);
  @$pb.TagNumber(19)
  void clearOverageEnabled() => $_clearField(19);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
