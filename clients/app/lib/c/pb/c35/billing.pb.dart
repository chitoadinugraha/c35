//
//  Generated code. Do not modify.
//  source: c35/billing.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

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
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    if (ownerIid != null) {
      $result.ownerIid = ownerIid;
    }
    if (name != null) {
      $result.name = name;
    }
    if (balanceUsd != null) {
      $result.balanceUsd = balanceUsd;
    }
    if (balanceIdr != null) {
      $result.balanceIdr = balanceIdr;
    }
    if (planTier != null) {
      $result.planTier = planTier;
    }
    if (alienAllow5hUsed != null) {
      $result.alienAllow5hUsed = alienAllow5hUsed;
    }
    if (alienAllow5hLimit != null) {
      $result.alienAllow5hLimit = alienAllow5hLimit;
    }
    if (alienAllowWeeklyUsed != null) {
      $result.alienAllowWeeklyUsed = alienAllowWeeklyUsed;
    }
    if (alienAllowWeeklyLimit != null) {
      $result.alienAllowWeeklyLimit = alienAllowWeeklyLimit;
    }
    if (window5hStartMs != null) {
      $result.window5hStartMs = window5hStartMs;
    }
    if (windowWeeklyStartMs != null) {
      $result.windowWeeklyStartMs = windowWeeklyStartMs;
    }
    if (billingCurrency != null) {
      $result.billingCurrency = billingCurrency;
    }
    if (fxMicroPerUsd != null) {
      $result.fxMicroPerUsd = fxMicroPerUsd;
    }
    if (commissionAvailableUsd != null) {
      $result.commissionAvailableUsd = commissionAvailableUsd;
    }
    if (commissionEarnedUsd != null) {
      $result.commissionEarnedUsd = commissionEarnedUsd;
    }
    if (commissionAvailableIdr != null) {
      $result.commissionAvailableIdr = commissionAvailableIdr;
    }
    if (commissionEarnedIdr != null) {
      $result.commissionEarnedIdr = commissionEarnedIdr;
    }
    if (metaJson != null) {
      $result.metaJson = metaJson;
    }
    if (createdTsMs != null) {
      $result.createdTsMs = createdTsMs;
    }
    if (updatedTsMs != null) {
      $result.updatedTsMs = updatedTsMs;
    }
    if (deletedTsMs != null) {
      $result.deletedTsMs = deletedTsMs;
    }
    return $result;
  }
  BillingAccount._() : super();
  factory BillingAccount.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BillingAccount.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BillingAccount', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..aInt64(2, _omitFieldNames ? '' : 'ownerIid')
    ..aOS(3, _omitFieldNames ? '' : 'name')
    ..a<$core.double>(4, _omitFieldNames ? '' : 'balanceUsd', $pb.PbFieldType.OD)
    ..a<$core.double>(5, _omitFieldNames ? '' : 'balanceIdr', $pb.PbFieldType.OD)
    ..aOS(6, _omitFieldNames ? '' : 'planTier')
    ..a<$core.double>(7, _omitFieldNames ? '' : 'alienAllow5hUsed', $pb.PbFieldType.OD, protoName: 'alien_allow_5h_used')
    ..a<$core.double>(8, _omitFieldNames ? '' : 'alienAllow5hLimit', $pb.PbFieldType.OD, protoName: 'alien_allow_5h_limit')
    ..a<$core.double>(9, _omitFieldNames ? '' : 'alienAllowWeeklyUsed', $pb.PbFieldType.OD)
    ..a<$core.double>(10, _omitFieldNames ? '' : 'alienAllowWeeklyLimit', $pb.PbFieldType.OD)
    ..aInt64(11, _omitFieldNames ? '' : 'window5hStartMs', protoName: 'window_5h_start_ms')
    ..aInt64(12, _omitFieldNames ? '' : 'windowWeeklyStartMs')
    ..aOS(13, _omitFieldNames ? '' : 'billingCurrency')
    ..aInt64(14, _omitFieldNames ? '' : 'fxMicroPerUsd')
    ..a<$core.double>(15, _omitFieldNames ? '' : 'commissionAvailableUsd', $pb.PbFieldType.OD)
    ..a<$core.double>(16, _omitFieldNames ? '' : 'commissionEarnedUsd', $pb.PbFieldType.OD)
    ..a<$core.double>(17, _omitFieldNames ? '' : 'commissionAvailableIdr', $pb.PbFieldType.OD)
    ..a<$core.double>(18, _omitFieldNames ? '' : 'commissionEarnedIdr', $pb.PbFieldType.OD)
    ..aOS(19, _omitFieldNames ? '' : 'metaJson')
    ..aInt64(20, _omitFieldNames ? '' : 'createdTsMs')
    ..aInt64(21, _omitFieldNames ? '' : 'updatedTsMs')
    ..aInt64(22, _omitFieldNames ? '' : 'deletedTsMs')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  BillingAccount clone() => BillingAccount()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  BillingAccount copyWith(void Function(BillingAccount) updates) => super.copyWith((message) => updates(message as BillingAccount)) as BillingAccount;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BillingAccount create() => BillingAccount._();
  BillingAccount createEmptyInstance() => create();
  static $pb.PbList<BillingAccount> createRepeated() => $pb.PbList<BillingAccount>();
  @$core.pragma('dart2js:noInline')
  static BillingAccount getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BillingAccount>(create);
  static BillingAccount? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get ownerIid => $_getI64(1);
  @$pb.TagNumber(2)
  set ownerIid($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasOwnerIid() => $_has(1);
  @$pb.TagNumber(2)
  void clearOwnerIid() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get name => $_getSZ(2);
  @$pb.TagNumber(3)
  set name($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasName() => $_has(2);
  @$pb.TagNumber(3)
  void clearName() => clearField(3);

  @$pb.TagNumber(4)
  $core.double get balanceUsd => $_getN(3);
  @$pb.TagNumber(4)
  set balanceUsd($core.double v) { $_setDouble(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasBalanceUsd() => $_has(3);
  @$pb.TagNumber(4)
  void clearBalanceUsd() => clearField(4);

  @$pb.TagNumber(5)
  $core.double get balanceIdr => $_getN(4);
  @$pb.TagNumber(5)
  set balanceIdr($core.double v) { $_setDouble(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasBalanceIdr() => $_has(4);
  @$pb.TagNumber(5)
  void clearBalanceIdr() => clearField(5);

  @$pb.TagNumber(6)
  $core.String get planTier => $_getSZ(5);
  @$pb.TagNumber(6)
  set planTier($core.String v) { $_setString(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasPlanTier() => $_has(5);
  @$pb.TagNumber(6)
  void clearPlanTier() => clearField(6);

  @$pb.TagNumber(7)
  $core.double get alienAllow5hUsed => $_getN(6);
  @$pb.TagNumber(7)
  set alienAllow5hUsed($core.double v) { $_setDouble(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasAlienAllow5hUsed() => $_has(6);
  @$pb.TagNumber(7)
  void clearAlienAllow5hUsed() => clearField(7);

  @$pb.TagNumber(8)
  $core.double get alienAllow5hLimit => $_getN(7);
  @$pb.TagNumber(8)
  set alienAllow5hLimit($core.double v) { $_setDouble(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasAlienAllow5hLimit() => $_has(7);
  @$pb.TagNumber(8)
  void clearAlienAllow5hLimit() => clearField(8);

  @$pb.TagNumber(9)
  $core.double get alienAllowWeeklyUsed => $_getN(8);
  @$pb.TagNumber(9)
  set alienAllowWeeklyUsed($core.double v) { $_setDouble(8, v); }
  @$pb.TagNumber(9)
  $core.bool hasAlienAllowWeeklyUsed() => $_has(8);
  @$pb.TagNumber(9)
  void clearAlienAllowWeeklyUsed() => clearField(9);

  @$pb.TagNumber(10)
  $core.double get alienAllowWeeklyLimit => $_getN(9);
  @$pb.TagNumber(10)
  set alienAllowWeeklyLimit($core.double v) { $_setDouble(9, v); }
  @$pb.TagNumber(10)
  $core.bool hasAlienAllowWeeklyLimit() => $_has(9);
  @$pb.TagNumber(10)
  void clearAlienAllowWeeklyLimit() => clearField(10);

  @$pb.TagNumber(11)
  $fixnum.Int64 get window5hStartMs => $_getI64(10);
  @$pb.TagNumber(11)
  set window5hStartMs($fixnum.Int64 v) { $_setInt64(10, v); }
  @$pb.TagNumber(11)
  $core.bool hasWindow5hStartMs() => $_has(10);
  @$pb.TagNumber(11)
  void clearWindow5hStartMs() => clearField(11);

  @$pb.TagNumber(12)
  $fixnum.Int64 get windowWeeklyStartMs => $_getI64(11);
  @$pb.TagNumber(12)
  set windowWeeklyStartMs($fixnum.Int64 v) { $_setInt64(11, v); }
  @$pb.TagNumber(12)
  $core.bool hasWindowWeeklyStartMs() => $_has(11);
  @$pb.TagNumber(12)
  void clearWindowWeeklyStartMs() => clearField(12);

  @$pb.TagNumber(13)
  $core.String get billingCurrency => $_getSZ(12);
  @$pb.TagNumber(13)
  set billingCurrency($core.String v) { $_setString(12, v); }
  @$pb.TagNumber(13)
  $core.bool hasBillingCurrency() => $_has(12);
  @$pb.TagNumber(13)
  void clearBillingCurrency() => clearField(13);

  @$pb.TagNumber(14)
  $fixnum.Int64 get fxMicroPerUsd => $_getI64(13);
  @$pb.TagNumber(14)
  set fxMicroPerUsd($fixnum.Int64 v) { $_setInt64(13, v); }
  @$pb.TagNumber(14)
  $core.bool hasFxMicroPerUsd() => $_has(13);
  @$pb.TagNumber(14)
  void clearFxMicroPerUsd() => clearField(14);

  @$pb.TagNumber(15)
  $core.double get commissionAvailableUsd => $_getN(14);
  @$pb.TagNumber(15)
  set commissionAvailableUsd($core.double v) { $_setDouble(14, v); }
  @$pb.TagNumber(15)
  $core.bool hasCommissionAvailableUsd() => $_has(14);
  @$pb.TagNumber(15)
  void clearCommissionAvailableUsd() => clearField(15);

  @$pb.TagNumber(16)
  $core.double get commissionEarnedUsd => $_getN(15);
  @$pb.TagNumber(16)
  set commissionEarnedUsd($core.double v) { $_setDouble(15, v); }
  @$pb.TagNumber(16)
  $core.bool hasCommissionEarnedUsd() => $_has(15);
  @$pb.TagNumber(16)
  void clearCommissionEarnedUsd() => clearField(16);

  @$pb.TagNumber(17)
  $core.double get commissionAvailableIdr => $_getN(16);
  @$pb.TagNumber(17)
  set commissionAvailableIdr($core.double v) { $_setDouble(16, v); }
  @$pb.TagNumber(17)
  $core.bool hasCommissionAvailableIdr() => $_has(16);
  @$pb.TagNumber(17)
  void clearCommissionAvailableIdr() => clearField(17);

  @$pb.TagNumber(18)
  $core.double get commissionEarnedIdr => $_getN(17);
  @$pb.TagNumber(18)
  set commissionEarnedIdr($core.double v) { $_setDouble(17, v); }
  @$pb.TagNumber(18)
  $core.bool hasCommissionEarnedIdr() => $_has(17);
  @$pb.TagNumber(18)
  void clearCommissionEarnedIdr() => clearField(18);

  @$pb.TagNumber(19)
  $core.String get metaJson => $_getSZ(18);
  @$pb.TagNumber(19)
  set metaJson($core.String v) { $_setString(18, v); }
  @$pb.TagNumber(19)
  $core.bool hasMetaJson() => $_has(18);
  @$pb.TagNumber(19)
  void clearMetaJson() => clearField(19);

  @$pb.TagNumber(20)
  $fixnum.Int64 get createdTsMs => $_getI64(19);
  @$pb.TagNumber(20)
  set createdTsMs($fixnum.Int64 v) { $_setInt64(19, v); }
  @$pb.TagNumber(20)
  $core.bool hasCreatedTsMs() => $_has(19);
  @$pb.TagNumber(20)
  void clearCreatedTsMs() => clearField(20);

  @$pb.TagNumber(21)
  $fixnum.Int64 get updatedTsMs => $_getI64(20);
  @$pb.TagNumber(21)
  set updatedTsMs($fixnum.Int64 v) { $_setInt64(20, v); }
  @$pb.TagNumber(21)
  $core.bool hasUpdatedTsMs() => $_has(20);
  @$pb.TagNumber(21)
  void clearUpdatedTsMs() => clearField(21);

  @$pb.TagNumber(22)
  $fixnum.Int64 get deletedTsMs => $_getI64(21);
  @$pb.TagNumber(22)
  set deletedTsMs($fixnum.Int64 v) { $_setInt64(21, v); }
  @$pb.TagNumber(22)
  $core.bool hasDeletedTsMs() => $_has(21);
  @$pb.TagNumber(22)
  void clearDeletedTsMs() => clearField(22);
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
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    if (ownerIid != null) {
      $result.ownerIid = ownerIid;
    }
    if (billingAccountId != null) {
      $result.billingAccountId = billingAccountId;
    }
    if (amountUsd != null) {
      $result.amountUsd = amountUsd;
    }
    if (amountIdr != null) {
      $result.amountIdr = amountIdr;
    }
    if (provider != null) {
      $result.provider = provider;
    }
    if (paymentType != null) {
      $result.paymentType = paymentType;
    }
    if (externalOrderId != null) {
      $result.externalOrderId = externalOrderId;
    }
    if (proofUrl != null) {
      $result.proofUrl = proofUrl;
    }
    if (status != null) {
      $result.status = status;
    }
    if (rejectReason != null) {
      $result.rejectReason = rejectReason;
    }
    if (reviewedByIid != null) {
      $result.reviewedByIid = reviewedByIid;
    }
    if (settledTsMs != null) {
      $result.settledTsMs = settledTsMs;
    }
    if (createdTsMs != null) {
      $result.createdTsMs = createdTsMs;
    }
    if (updatedTsMs != null) {
      $result.updatedTsMs = updatedTsMs;
    }
    return $result;
  }
  BillingTopupRequest._() : super();
  factory BillingTopupRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BillingTopupRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BillingTopupRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..aInt64(2, _omitFieldNames ? '' : 'ownerIid')
    ..aInt64(3, _omitFieldNames ? '' : 'billingAccountId')
    ..a<$core.double>(4, _omitFieldNames ? '' : 'amountUsd', $pb.PbFieldType.OD)
    ..a<$core.double>(5, _omitFieldNames ? '' : 'amountIdr', $pb.PbFieldType.OD)
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
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  BillingTopupRequest clone() => BillingTopupRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  BillingTopupRequest copyWith(void Function(BillingTopupRequest) updates) => super.copyWith((message) => updates(message as BillingTopupRequest)) as BillingTopupRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BillingTopupRequest create() => BillingTopupRequest._();
  BillingTopupRequest createEmptyInstance() => create();
  static $pb.PbList<BillingTopupRequest> createRepeated() => $pb.PbList<BillingTopupRequest>();
  @$core.pragma('dart2js:noInline')
  static BillingTopupRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BillingTopupRequest>(create);
  static BillingTopupRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get ownerIid => $_getI64(1);
  @$pb.TagNumber(2)
  set ownerIid($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasOwnerIid() => $_has(1);
  @$pb.TagNumber(2)
  void clearOwnerIid() => clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get billingAccountId => $_getI64(2);
  @$pb.TagNumber(3)
  set billingAccountId($fixnum.Int64 v) { $_setInt64(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasBillingAccountId() => $_has(2);
  @$pb.TagNumber(3)
  void clearBillingAccountId() => clearField(3);

  @$pb.TagNumber(4)
  $core.double get amountUsd => $_getN(3);
  @$pb.TagNumber(4)
  set amountUsd($core.double v) { $_setDouble(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasAmountUsd() => $_has(3);
  @$pb.TagNumber(4)
  void clearAmountUsd() => clearField(4);

  @$pb.TagNumber(5)
  $core.double get amountIdr => $_getN(4);
  @$pb.TagNumber(5)
  set amountIdr($core.double v) { $_setDouble(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasAmountIdr() => $_has(4);
  @$pb.TagNumber(5)
  void clearAmountIdr() => clearField(5);

  @$pb.TagNumber(6)
  $core.String get provider => $_getSZ(5);
  @$pb.TagNumber(6)
  set provider($core.String v) { $_setString(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasProvider() => $_has(5);
  @$pb.TagNumber(6)
  void clearProvider() => clearField(6);

  @$pb.TagNumber(7)
  $core.String get paymentType => $_getSZ(6);
  @$pb.TagNumber(7)
  set paymentType($core.String v) { $_setString(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasPaymentType() => $_has(6);
  @$pb.TagNumber(7)
  void clearPaymentType() => clearField(7);

  @$pb.TagNumber(8)
  $core.String get externalOrderId => $_getSZ(7);
  @$pb.TagNumber(8)
  set externalOrderId($core.String v) { $_setString(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasExternalOrderId() => $_has(7);
  @$pb.TagNumber(8)
  void clearExternalOrderId() => clearField(8);

  @$pb.TagNumber(9)
  $core.String get proofUrl => $_getSZ(8);
  @$pb.TagNumber(9)
  set proofUrl($core.String v) { $_setString(8, v); }
  @$pb.TagNumber(9)
  $core.bool hasProofUrl() => $_has(8);
  @$pb.TagNumber(9)
  void clearProofUrl() => clearField(9);

  @$pb.TagNumber(10)
  $core.String get status => $_getSZ(9);
  @$pb.TagNumber(10)
  set status($core.String v) { $_setString(9, v); }
  @$pb.TagNumber(10)
  $core.bool hasStatus() => $_has(9);
  @$pb.TagNumber(10)
  void clearStatus() => clearField(10);

  @$pb.TagNumber(11)
  $core.String get rejectReason => $_getSZ(10);
  @$pb.TagNumber(11)
  set rejectReason($core.String v) { $_setString(10, v); }
  @$pb.TagNumber(11)
  $core.bool hasRejectReason() => $_has(10);
  @$pb.TagNumber(11)
  void clearRejectReason() => clearField(11);

  @$pb.TagNumber(12)
  $fixnum.Int64 get reviewedByIid => $_getI64(11);
  @$pb.TagNumber(12)
  set reviewedByIid($fixnum.Int64 v) { $_setInt64(11, v); }
  @$pb.TagNumber(12)
  $core.bool hasReviewedByIid() => $_has(11);
  @$pb.TagNumber(12)
  void clearReviewedByIid() => clearField(12);

  @$pb.TagNumber(13)
  $fixnum.Int64 get settledTsMs => $_getI64(12);
  @$pb.TagNumber(13)
  set settledTsMs($fixnum.Int64 v) { $_setInt64(12, v); }
  @$pb.TagNumber(13)
  $core.bool hasSettledTsMs() => $_has(12);
  @$pb.TagNumber(13)
  void clearSettledTsMs() => clearField(13);

  @$pb.TagNumber(14)
  $fixnum.Int64 get createdTsMs => $_getI64(13);
  @$pb.TagNumber(14)
  set createdTsMs($fixnum.Int64 v) { $_setInt64(13, v); }
  @$pb.TagNumber(14)
  $core.bool hasCreatedTsMs() => $_has(13);
  @$pb.TagNumber(14)
  void clearCreatedTsMs() => clearField(14);

  @$pb.TagNumber(15)
  $fixnum.Int64 get updatedTsMs => $_getI64(14);
  @$pb.TagNumber(15)
  set updatedTsMs($fixnum.Int64 v) { $_setInt64(14, v); }
  @$pb.TagNumber(15)
  $core.bool hasUpdatedTsMs() => $_has(14);
  @$pb.TagNumber(15)
  void clearUpdatedTsMs() => clearField(15);
}

/// NATS push: c35.user.{iid}.balance | .quota | .commission
class BillingPushBalance extends $pb.GeneratedMessage {
  factory BillingPushBalance({
    $fixnum.Int64? billingAccountId,
    $core.double? balanceUsd,
    $core.double? balanceIdr,
    $fixnum.Int64? updatedTsMs,
  }) {
    final $result = create();
    if (billingAccountId != null) {
      $result.billingAccountId = billingAccountId;
    }
    if (balanceUsd != null) {
      $result.balanceUsd = balanceUsd;
    }
    if (balanceIdr != null) {
      $result.balanceIdr = balanceIdr;
    }
    if (updatedTsMs != null) {
      $result.updatedTsMs = updatedTsMs;
    }
    return $result;
  }
  BillingPushBalance._() : super();
  factory BillingPushBalance.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BillingPushBalance.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BillingPushBalance', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'billingAccountId')
    ..a<$core.double>(2, _omitFieldNames ? '' : 'balanceUsd', $pb.PbFieldType.OD)
    ..a<$core.double>(3, _omitFieldNames ? '' : 'balanceIdr', $pb.PbFieldType.OD)
    ..aInt64(4, _omitFieldNames ? '' : 'updatedTsMs')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  BillingPushBalance clone() => BillingPushBalance()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  BillingPushBalance copyWith(void Function(BillingPushBalance) updates) => super.copyWith((message) => updates(message as BillingPushBalance)) as BillingPushBalance;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BillingPushBalance create() => BillingPushBalance._();
  BillingPushBalance createEmptyInstance() => create();
  static $pb.PbList<BillingPushBalance> createRepeated() => $pb.PbList<BillingPushBalance>();
  @$core.pragma('dart2js:noInline')
  static BillingPushBalance getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BillingPushBalance>(create);
  static BillingPushBalance? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get billingAccountId => $_getI64(0);
  @$pb.TagNumber(1)
  set billingAccountId($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasBillingAccountId() => $_has(0);
  @$pb.TagNumber(1)
  void clearBillingAccountId() => clearField(1);

  @$pb.TagNumber(2)
  $core.double get balanceUsd => $_getN(1);
  @$pb.TagNumber(2)
  set balanceUsd($core.double v) { $_setDouble(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasBalanceUsd() => $_has(1);
  @$pb.TagNumber(2)
  void clearBalanceUsd() => clearField(2);

  @$pb.TagNumber(3)
  $core.double get balanceIdr => $_getN(2);
  @$pb.TagNumber(3)
  set balanceIdr($core.double v) { $_setDouble(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasBalanceIdr() => $_has(2);
  @$pb.TagNumber(3)
  void clearBalanceIdr() => clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get updatedTsMs => $_getI64(3);
  @$pb.TagNumber(4)
  set updatedTsMs($fixnum.Int64 v) { $_setInt64(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasUpdatedTsMs() => $_has(3);
  @$pb.TagNumber(4)
  void clearUpdatedTsMs() => clearField(4);
}

class BillingPushQuota extends $pb.GeneratedMessage {
  factory BillingPushQuota({
    $core.double? alienAllow5hUsed,
    $core.double? alienAllow5hLimit,
    $core.double? alienAllowWeeklyUsed,
    $core.double? alienAllowWeeklyLimit,
    $fixnum.Int64? window5hStartMs,
    $fixnum.Int64? windowWeeklyStartMs,
  }) {
    final $result = create();
    if (alienAllow5hUsed != null) {
      $result.alienAllow5hUsed = alienAllow5hUsed;
    }
    if (alienAllow5hLimit != null) {
      $result.alienAllow5hLimit = alienAllow5hLimit;
    }
    if (alienAllowWeeklyUsed != null) {
      $result.alienAllowWeeklyUsed = alienAllowWeeklyUsed;
    }
    if (alienAllowWeeklyLimit != null) {
      $result.alienAllowWeeklyLimit = alienAllowWeeklyLimit;
    }
    if (window5hStartMs != null) {
      $result.window5hStartMs = window5hStartMs;
    }
    if (windowWeeklyStartMs != null) {
      $result.windowWeeklyStartMs = windowWeeklyStartMs;
    }
    return $result;
  }
  BillingPushQuota._() : super();
  factory BillingPushQuota.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BillingPushQuota.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BillingPushQuota', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..a<$core.double>(1, _omitFieldNames ? '' : 'alienAllow5hUsed', $pb.PbFieldType.OD, protoName: 'alien_allow_5h_used')
    ..a<$core.double>(2, _omitFieldNames ? '' : 'alienAllow5hLimit', $pb.PbFieldType.OD, protoName: 'alien_allow_5h_limit')
    ..a<$core.double>(3, _omitFieldNames ? '' : 'alienAllowWeeklyUsed', $pb.PbFieldType.OD)
    ..a<$core.double>(4, _omitFieldNames ? '' : 'alienAllowWeeklyLimit', $pb.PbFieldType.OD)
    ..aInt64(5, _omitFieldNames ? '' : 'window5hStartMs', protoName: 'window_5h_start_ms')
    ..aInt64(6, _omitFieldNames ? '' : 'windowWeeklyStartMs')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  BillingPushQuota clone() => BillingPushQuota()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  BillingPushQuota copyWith(void Function(BillingPushQuota) updates) => super.copyWith((message) => updates(message as BillingPushQuota)) as BillingPushQuota;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BillingPushQuota create() => BillingPushQuota._();
  BillingPushQuota createEmptyInstance() => create();
  static $pb.PbList<BillingPushQuota> createRepeated() => $pb.PbList<BillingPushQuota>();
  @$core.pragma('dart2js:noInline')
  static BillingPushQuota getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BillingPushQuota>(create);
  static BillingPushQuota? _defaultInstance;

  @$pb.TagNumber(1)
  $core.double get alienAllow5hUsed => $_getN(0);
  @$pb.TagNumber(1)
  set alienAllow5hUsed($core.double v) { $_setDouble(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasAlienAllow5hUsed() => $_has(0);
  @$pb.TagNumber(1)
  void clearAlienAllow5hUsed() => clearField(1);

  @$pb.TagNumber(2)
  $core.double get alienAllow5hLimit => $_getN(1);
  @$pb.TagNumber(2)
  set alienAllow5hLimit($core.double v) { $_setDouble(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasAlienAllow5hLimit() => $_has(1);
  @$pb.TagNumber(2)
  void clearAlienAllow5hLimit() => clearField(2);

  @$pb.TagNumber(3)
  $core.double get alienAllowWeeklyUsed => $_getN(2);
  @$pb.TagNumber(3)
  set alienAllowWeeklyUsed($core.double v) { $_setDouble(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasAlienAllowWeeklyUsed() => $_has(2);
  @$pb.TagNumber(3)
  void clearAlienAllowWeeklyUsed() => clearField(3);

  @$pb.TagNumber(4)
  $core.double get alienAllowWeeklyLimit => $_getN(3);
  @$pb.TagNumber(4)
  set alienAllowWeeklyLimit($core.double v) { $_setDouble(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasAlienAllowWeeklyLimit() => $_has(3);
  @$pb.TagNumber(4)
  void clearAlienAllowWeeklyLimit() => clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get window5hStartMs => $_getI64(4);
  @$pb.TagNumber(5)
  set window5hStartMs($fixnum.Int64 v) { $_setInt64(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasWindow5hStartMs() => $_has(4);
  @$pb.TagNumber(5)
  void clearWindow5hStartMs() => clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get windowWeeklyStartMs => $_getI64(5);
  @$pb.TagNumber(6)
  set windowWeeklyStartMs($fixnum.Int64 v) { $_setInt64(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasWindowWeeklyStartMs() => $_has(5);
  @$pb.TagNumber(6)
  void clearWindowWeeklyStartMs() => clearField(6);
}

class BillingPushCommission extends $pb.GeneratedMessage {
  factory BillingPushCommission({
    $core.double? commissionAvailableUsd,
    $core.double? commissionEarnedUsd,
    $core.double? commissionAvailableIdr,
    $core.double? commissionEarnedIdr,
  }) {
    final $result = create();
    if (commissionAvailableUsd != null) {
      $result.commissionAvailableUsd = commissionAvailableUsd;
    }
    if (commissionEarnedUsd != null) {
      $result.commissionEarnedUsd = commissionEarnedUsd;
    }
    if (commissionAvailableIdr != null) {
      $result.commissionAvailableIdr = commissionAvailableIdr;
    }
    if (commissionEarnedIdr != null) {
      $result.commissionEarnedIdr = commissionEarnedIdr;
    }
    return $result;
  }
  BillingPushCommission._() : super();
  factory BillingPushCommission.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BillingPushCommission.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BillingPushCommission', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..a<$core.double>(1, _omitFieldNames ? '' : 'commissionAvailableUsd', $pb.PbFieldType.OD)
    ..a<$core.double>(2, _omitFieldNames ? '' : 'commissionEarnedUsd', $pb.PbFieldType.OD)
    ..a<$core.double>(3, _omitFieldNames ? '' : 'commissionAvailableIdr', $pb.PbFieldType.OD)
    ..a<$core.double>(4, _omitFieldNames ? '' : 'commissionEarnedIdr', $pb.PbFieldType.OD)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  BillingPushCommission clone() => BillingPushCommission()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  BillingPushCommission copyWith(void Function(BillingPushCommission) updates) => super.copyWith((message) => updates(message as BillingPushCommission)) as BillingPushCommission;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BillingPushCommission create() => BillingPushCommission._();
  BillingPushCommission createEmptyInstance() => create();
  static $pb.PbList<BillingPushCommission> createRepeated() => $pb.PbList<BillingPushCommission>();
  @$core.pragma('dart2js:noInline')
  static BillingPushCommission getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BillingPushCommission>(create);
  static BillingPushCommission? _defaultInstance;

  @$pb.TagNumber(1)
  $core.double get commissionAvailableUsd => $_getN(0);
  @$pb.TagNumber(1)
  set commissionAvailableUsd($core.double v) { $_setDouble(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasCommissionAvailableUsd() => $_has(0);
  @$pb.TagNumber(1)
  void clearCommissionAvailableUsd() => clearField(1);

  @$pb.TagNumber(2)
  $core.double get commissionEarnedUsd => $_getN(1);
  @$pb.TagNumber(2)
  set commissionEarnedUsd($core.double v) { $_setDouble(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasCommissionEarnedUsd() => $_has(1);
  @$pb.TagNumber(2)
  void clearCommissionEarnedUsd() => clearField(2);

  @$pb.TagNumber(3)
  $core.double get commissionAvailableIdr => $_getN(2);
  @$pb.TagNumber(3)
  set commissionAvailableIdr($core.double v) { $_setDouble(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasCommissionAvailableIdr() => $_has(2);
  @$pb.TagNumber(3)
  void clearCommissionAvailableIdr() => clearField(3);

  @$pb.TagNumber(4)
  $core.double get commissionEarnedIdr => $_getN(3);
  @$pb.TagNumber(4)
  set commissionEarnedIdr($core.double v) { $_setDouble(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasCommissionEarnedIdr() => $_has(3);
  @$pb.TagNumber(4)
  void clearCommissionEarnedIdr() => clearField(4);
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
    final $result = create();
    if (amountUsd != null) {
      $result.amountUsd = amountUsd;
    }
    if (amountIdr != null) {
      $result.amountIdr = amountIdr;
    }
    if (provider != null) {
      $result.provider = provider;
    }
    if (paymentType != null) {
      $result.paymentType = paymentType;
    }
    if (proofUrl != null) {
      $result.proofUrl = proofUrl;
    }
    return $result;
  }
  ReqBillingTopupPut._() : super();
  factory ReqBillingTopupPut.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ReqBillingTopupPut.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ReqBillingTopupPut', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..a<$core.double>(1, _omitFieldNames ? '' : 'amountUsd', $pb.PbFieldType.OD)
    ..a<$core.double>(2, _omitFieldNames ? '' : 'amountIdr', $pb.PbFieldType.OD)
    ..aOS(3, _omitFieldNames ? '' : 'provider')
    ..aOS(4, _omitFieldNames ? '' : 'paymentType')
    ..aOS(5, _omitFieldNames ? '' : 'proofUrl')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ReqBillingTopupPut clone() => ReqBillingTopupPut()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ReqBillingTopupPut copyWith(void Function(ReqBillingTopupPut) updates) => super.copyWith((message) => updates(message as ReqBillingTopupPut)) as ReqBillingTopupPut;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReqBillingTopupPut create() => ReqBillingTopupPut._();
  ReqBillingTopupPut createEmptyInstance() => create();
  static $pb.PbList<ReqBillingTopupPut> createRepeated() => $pb.PbList<ReqBillingTopupPut>();
  @$core.pragma('dart2js:noInline')
  static ReqBillingTopupPut getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqBillingTopupPut>(create);
  static ReqBillingTopupPut? _defaultInstance;

  @$pb.TagNumber(1)
  $core.double get amountUsd => $_getN(0);
  @$pb.TagNumber(1)
  set amountUsd($core.double v) { $_setDouble(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasAmountUsd() => $_has(0);
  @$pb.TagNumber(1)
  void clearAmountUsd() => clearField(1);

  @$pb.TagNumber(2)
  $core.double get amountIdr => $_getN(1);
  @$pb.TagNumber(2)
  set amountIdr($core.double v) { $_setDouble(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasAmountIdr() => $_has(1);
  @$pb.TagNumber(2)
  void clearAmountIdr() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get provider => $_getSZ(2);
  @$pb.TagNumber(3)
  set provider($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasProvider() => $_has(2);
  @$pb.TagNumber(3)
  void clearProvider() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get paymentType => $_getSZ(3);
  @$pb.TagNumber(4)
  set paymentType($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasPaymentType() => $_has(3);
  @$pb.TagNumber(4)
  void clearPaymentType() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get proofUrl => $_getSZ(4);
  @$pb.TagNumber(5)
  set proofUrl($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasProofUrl() => $_has(4);
  @$pb.TagNumber(5)
  void clearProofUrl() => clearField(5);
}

class ResBillingTopupPut extends $pb.GeneratedMessage {
  factory ResBillingTopupPut({
    BillingTopupRequest? request,
  }) {
    final $result = create();
    if (request != null) {
      $result.request = request;
    }
    return $result;
  }
  ResBillingTopupPut._() : super();
  factory ResBillingTopupPut.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ResBillingTopupPut.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ResBillingTopupPut', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aOM<BillingTopupRequest>(1, _omitFieldNames ? '' : 'request', subBuilder: BillingTopupRequest.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ResBillingTopupPut clone() => ResBillingTopupPut()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ResBillingTopupPut copyWith(void Function(ResBillingTopupPut) updates) => super.copyWith((message) => updates(message as ResBillingTopupPut)) as ResBillingTopupPut;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResBillingTopupPut create() => ResBillingTopupPut._();
  ResBillingTopupPut createEmptyInstance() => create();
  static $pb.PbList<ResBillingTopupPut> createRepeated() => $pb.PbList<ResBillingTopupPut>();
  @$core.pragma('dart2js:noInline')
  static ResBillingTopupPut getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResBillingTopupPut>(create);
  static ResBillingTopupPut? _defaultInstance;

  @$pb.TagNumber(1)
  BillingTopupRequest get request => $_getN(0);
  @$pb.TagNumber(1)
  set request(BillingTopupRequest v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasRequest() => $_has(0);
  @$pb.TagNumber(1)
  void clearRequest() => clearField(1);
  @$pb.TagNumber(1)
  BillingTopupRequest ensureRequest() => $_ensure(0);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
