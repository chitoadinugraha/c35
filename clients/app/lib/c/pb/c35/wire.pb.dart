// This is a generated file - do not edit.
//
// Generated from c35/wire.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'admin.pb.dart' as $3;
import 'billing.pb.dart' as $0;
import 'channel.pb.dart' as $4;
import 'chat.pb.dart' as $8;
import 'consumption.pb.dart' as $1;
import 'device.pb.dart' as $5;
import 'identity.pb.dart' as $12;
import 'log.pb.dart' as $14;
import 'referral.pb.dart' as $2;
import 'session.pb.dart' as $6;
import 'site.pb.dart' as $10;
import 'skill.pb.dart' as $9;
import 'sync.pb.dart' as $7;
import 'tx.pb.dart' as $11;
import 'types.pb.dart' as $13;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

enum InvokeReq_Body {
  billingTopupPut,
  billingPackageRedeem,
  billingPackagePreview,
  botUsageStats,
  billingSummary,
  billingPlanSubscribe,
  consumptionPut,
  billingHistory,
  referralShareSet,
  referralTreeGet,
  referralCodeList,
  referralCodePut,
  referralCodeDelete,
  adminUserSearch,
  adminUserPut,
  referralUserStats,
  referralCommissionSimulate,
  channelTelegramConnect,
  channelWhatsappMetaConnect,
  devicePair,
  notSet
}

/// HTTP invoke envelope (referral, admin, billing review, …)
class InvokeReq extends $pb.GeneratedMessage {
  factory InvokeReq({
    $core.String? reqId,
    $fixnum.Int64? callerIid,
    $0.ReqBillingTopupPut? billingTopupPut,
    $0.ReqBillingPackageRedeem? billingPackageRedeem,
    $0.ReqBillingPackagePreview? billingPackagePreview,
    $0.ReqBotUsageStats? botUsageStats,
    $0.ReqBillingSummary? billingSummary,
    $0.ReqBillingPlanSubscribe? billingPlanSubscribe,
    $1.ReqConsumptionPut? consumptionPut,
    $0.ReqBillingHistory? billingHistory,
    $2.ReqReferralShareSet? referralShareSet,
    $2.ReqReferralTreeGet? referralTreeGet,
    $2.ReqReferralCodeList? referralCodeList,
    $2.ReqReferralCodePut? referralCodePut,
    $2.ReqReferralCodeDelete? referralCodeDelete,
    $3.ReqAdminUserSearch? adminUserSearch,
    $3.ReqAdminUserPut? adminUserPut,
    $2.ReqReferralUserStats? referralUserStats,
    $2.ReqReferralCommissionSimulate? referralCommissionSimulate,
    $4.ReqChannelTelegramConnect? channelTelegramConnect,
    $4.ReqChannelWhatsappMetaConnect? channelWhatsappMetaConnect,
    $5.ReqDevicePair? devicePair,
  }) {
    final result = InvokeReq._();
    if (reqId != null) result.reqId = reqId;
    if (callerIid != null) result.callerIid = callerIid;
    if (billingTopupPut != null) result.billingTopupPut = billingTopupPut;
    if (billingPackageRedeem != null)
      result.billingPackageRedeem = billingPackageRedeem;
    if (billingPackagePreview != null)
      result.billingPackagePreview = billingPackagePreview;
    if (botUsageStats != null) result.botUsageStats = botUsageStats;
    if (billingSummary != null) result.billingSummary = billingSummary;
    if (billingPlanSubscribe != null)
      result.billingPlanSubscribe = billingPlanSubscribe;
    if (consumptionPut != null) result.consumptionPut = consumptionPut;
    if (billingHistory != null) result.billingHistory = billingHistory;
    if (referralShareSet != null) result.referralShareSet = referralShareSet;
    if (referralTreeGet != null) result.referralTreeGet = referralTreeGet;
    if (referralCodeList != null) result.referralCodeList = referralCodeList;
    if (referralCodePut != null) result.referralCodePut = referralCodePut;
    if (referralCodeDelete != null)
      result.referralCodeDelete = referralCodeDelete;
    if (adminUserSearch != null) result.adminUserSearch = adminUserSearch;
    if (adminUserPut != null) result.adminUserPut = adminUserPut;
    if (referralUserStats != null) result.referralUserStats = referralUserStats;
    if (referralCommissionSimulate != null)
      result.referralCommissionSimulate = referralCommissionSimulate;
    if (channelTelegramConnect != null)
      result.channelTelegramConnect = channelTelegramConnect;
    if (channelWhatsappMetaConnect != null)
      result.channelWhatsappMetaConnect = channelWhatsappMetaConnect;
    if (devicePair != null) result.devicePair = devicePair;
    return result;
  }

  InvokeReq._();

  factory InvokeReq.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      InvokeReq()..mergeFromBuffer(data, registry);
  factory InvokeReq.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      InvokeReq()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, InvokeReq_Body> _InvokeReq_BodyByTag = {
    10: InvokeReq_Body.billingTopupPut,
    11: InvokeReq_Body.billingPackageRedeem,
    12: InvokeReq_Body.billingPackagePreview,
    13: InvokeReq_Body.botUsageStats,
    14: InvokeReq_Body.billingSummary,
    15: InvokeReq_Body.billingPlanSubscribe,
    16: InvokeReq_Body.consumptionPut,
    17: InvokeReq_Body.billingHistory,
    62: InvokeReq_Body.referralShareSet,
    64: InvokeReq_Body.referralTreeGet,
    65: InvokeReq_Body.referralCodeList,
    67: InvokeReq_Body.referralCodePut,
    68: InvokeReq_Body.referralCodeDelete,
    90: InvokeReq_Body.adminUserSearch,
    91: InvokeReq_Body.adminUserPut,
    92: InvokeReq_Body.referralUserStats,
    93: InvokeReq_Body.referralCommissionSimulate,
    100: InvokeReq_Body.channelTelegramConnect,
    101: InvokeReq_Body.channelWhatsappMetaConnect,
    102: InvokeReq_Body.devicePair,
    0: InvokeReq_Body.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InvokeReq',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: InvokeReq.$_createMessage)
    ..oo(0, [
      10,
      11,
      12,
      13,
      14,
      15,
      16,
      17,
      62,
      64,
      65,
      67,
      68,
      90,
      91,
      92,
      93,
      100,
      101,
      102
    ])
    ..aOS(1, _omitFieldNames ? '' : 'reqId')
    ..aInt64(2, _omitFieldNames ? '' : 'callerIid')
    ..aOM<$0.ReqBillingTopupPut>(10, _omitFieldNames ? '' : 'billingTopupPut',
        subBuilder: $0.ReqBillingTopupPut.$_createMessage)
    ..aOM<$0.ReqBillingPackageRedeem>(
        11, _omitFieldNames ? '' : 'billingPackageRedeem',
        subBuilder: $0.ReqBillingPackageRedeem.$_createMessage)
    ..aOM<$0.ReqBillingPackagePreview>(
        12, _omitFieldNames ? '' : 'billingPackagePreview',
        subBuilder: $0.ReqBillingPackagePreview.$_createMessage)
    ..aOM<$0.ReqBotUsageStats>(13, _omitFieldNames ? '' : 'botUsageStats',
        subBuilder: $0.ReqBotUsageStats.$_createMessage)
    ..aOM<$0.ReqBillingSummary>(14, _omitFieldNames ? '' : 'billingSummary',
        subBuilder: $0.ReqBillingSummary.$_createMessage)
    ..aOM<$0.ReqBillingPlanSubscribe>(
        15, _omitFieldNames ? '' : 'billingPlanSubscribe',
        subBuilder: $0.ReqBillingPlanSubscribe.$_createMessage)
    ..aOM<$1.ReqConsumptionPut>(16, _omitFieldNames ? '' : 'consumptionPut',
        subBuilder: $1.ReqConsumptionPut.$_createMessage)
    ..aOM<$0.ReqBillingHistory>(17, _omitFieldNames ? '' : 'billingHistory',
        subBuilder: $0.ReqBillingHistory.$_createMessage)
    ..aOM<$2.ReqReferralShareSet>(62, _omitFieldNames ? '' : 'referralShareSet',
        subBuilder: $2.ReqReferralShareSet.$_createMessage)
    ..aOM<$2.ReqReferralTreeGet>(64, _omitFieldNames ? '' : 'referralTreeGet',
        subBuilder: $2.ReqReferralTreeGet.$_createMessage)
    ..aOM<$2.ReqReferralCodeList>(65, _omitFieldNames ? '' : 'referralCodeList',
        subBuilder: $2.ReqReferralCodeList.$_createMessage)
    ..aOM<$2.ReqReferralCodePut>(67, _omitFieldNames ? '' : 'referralCodePut',
        subBuilder: $2.ReqReferralCodePut.$_createMessage)
    ..aOM<$2.ReqReferralCodeDelete>(
        68, _omitFieldNames ? '' : 'referralCodeDelete',
        subBuilder: $2.ReqReferralCodeDelete.$_createMessage)
    ..aOM<$3.ReqAdminUserSearch>(90, _omitFieldNames ? '' : 'adminUserSearch',
        subBuilder: $3.ReqAdminUserSearch.$_createMessage)
    ..aOM<$3.ReqAdminUserPut>(91, _omitFieldNames ? '' : 'adminUserPut',
        subBuilder: $3.ReqAdminUserPut.$_createMessage)
    ..aOM<$2.ReqReferralUserStats>(
        92, _omitFieldNames ? '' : 'referralUserStats',
        subBuilder: $2.ReqReferralUserStats.$_createMessage)
    ..aOM<$2.ReqReferralCommissionSimulate>(
        93, _omitFieldNames ? '' : 'referralCommissionSimulate',
        subBuilder: $2.ReqReferralCommissionSimulate.$_createMessage)
    ..aOM<$4.ReqChannelTelegramConnect>(
        100, _omitFieldNames ? '' : 'channelTelegramConnect',
        subBuilder: $4.ReqChannelTelegramConnect.$_createMessage)
    ..aOM<$4.ReqChannelWhatsappMetaConnect>(
        101, _omitFieldNames ? '' : 'channelWhatsappMetaConnect',
        subBuilder: $4.ReqChannelWhatsappMetaConnect.$_createMessage)
    ..aOM<$5.ReqDevicePair>(102, _omitFieldNames ? '' : 'devicePair',
        subBuilder: $5.ReqDevicePair.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InvokeReq clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InvokeReq copyWith(void Function(InvokeReq) updates) =>
      super.copyWith((message) => updates(message as InvokeReq)) as InvokeReq;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use InvokeReq() / InvokeReq.new instead')
  static InvokeReq create() => InvokeReq._();
  static $pb.GeneratedMessage $_createMessage() => InvokeReq._();
  @$core.override
  InvokeReq createEmptyInstance() => InvokeReq._();
  @$core.pragma('dart2js:noInline')
  static InvokeReq getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<InvokeReq>(InvokeReq.$_createMessage);
  static InvokeReq? _defaultInstance;

  @$pb.TagNumber(10)
  @$pb.TagNumber(11)
  @$pb.TagNumber(12)
  @$pb.TagNumber(13)
  @$pb.TagNumber(14)
  @$pb.TagNumber(15)
  @$pb.TagNumber(16)
  @$pb.TagNumber(17)
  @$pb.TagNumber(62)
  @$pb.TagNumber(64)
  @$pb.TagNumber(65)
  @$pb.TagNumber(67)
  @$pb.TagNumber(68)
  @$pb.TagNumber(90)
  @$pb.TagNumber(91)
  @$pb.TagNumber(92)
  @$pb.TagNumber(93)
  @$pb.TagNumber(100)
  @$pb.TagNumber(101)
  @$pb.TagNumber(102)
  InvokeReq_Body whichBody() => _InvokeReq_BodyByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(10)
  @$pb.TagNumber(11)
  @$pb.TagNumber(12)
  @$pb.TagNumber(13)
  @$pb.TagNumber(14)
  @$pb.TagNumber(15)
  @$pb.TagNumber(16)
  @$pb.TagNumber(17)
  @$pb.TagNumber(62)
  @$pb.TagNumber(64)
  @$pb.TagNumber(65)
  @$pb.TagNumber(67)
  @$pb.TagNumber(68)
  @$pb.TagNumber(90)
  @$pb.TagNumber(91)
  @$pb.TagNumber(92)
  @$pb.TagNumber(93)
  @$pb.TagNumber(100)
  @$pb.TagNumber(101)
  @$pb.TagNumber(102)
  void clearBody() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get reqId => $_getSZ(0);
  @$pb.TagNumber(1)
  set reqId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasReqId() => $_has(0);
  @$pb.TagNumber(1)
  void clearReqId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get callerIid => $_getI64(1);
  @$pb.TagNumber(2)
  set callerIid($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCallerIid() => $_has(1);
  @$pb.TagNumber(2)
  void clearCallerIid() => $_clearField(2);

  @$pb.TagNumber(10)
  $0.ReqBillingTopupPut get billingTopupPut => $_getN(2);
  @$pb.TagNumber(10)
  set billingTopupPut($0.ReqBillingTopupPut value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasBillingTopupPut() => $_has(2);
  @$pb.TagNumber(10)
  void clearBillingTopupPut() => $_clearField(10);
  @$pb.TagNumber(10)
  $0.ReqBillingTopupPut ensureBillingTopupPut() => $_ensure(2);

  @$pb.TagNumber(11)
  $0.ReqBillingPackageRedeem get billingPackageRedeem => $_getN(3);
  @$pb.TagNumber(11)
  set billingPackageRedeem($0.ReqBillingPackageRedeem value) =>
      $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasBillingPackageRedeem() => $_has(3);
  @$pb.TagNumber(11)
  void clearBillingPackageRedeem() => $_clearField(11);
  @$pb.TagNumber(11)
  $0.ReqBillingPackageRedeem ensureBillingPackageRedeem() => $_ensure(3);

  @$pb.TagNumber(12)
  $0.ReqBillingPackagePreview get billingPackagePreview => $_getN(4);
  @$pb.TagNumber(12)
  set billingPackagePreview($0.ReqBillingPackagePreview value) =>
      $_setField(12, value);
  @$pb.TagNumber(12)
  $core.bool hasBillingPackagePreview() => $_has(4);
  @$pb.TagNumber(12)
  void clearBillingPackagePreview() => $_clearField(12);
  @$pb.TagNumber(12)
  $0.ReqBillingPackagePreview ensureBillingPackagePreview() => $_ensure(4);

  @$pb.TagNumber(13)
  $0.ReqBotUsageStats get botUsageStats => $_getN(5);
  @$pb.TagNumber(13)
  set botUsageStats($0.ReqBotUsageStats value) => $_setField(13, value);
  @$pb.TagNumber(13)
  $core.bool hasBotUsageStats() => $_has(5);
  @$pb.TagNumber(13)
  void clearBotUsageStats() => $_clearField(13);
  @$pb.TagNumber(13)
  $0.ReqBotUsageStats ensureBotUsageStats() => $_ensure(5);

  @$pb.TagNumber(14)
  $0.ReqBillingSummary get billingSummary => $_getN(6);
  @$pb.TagNumber(14)
  set billingSummary($0.ReqBillingSummary value) => $_setField(14, value);
  @$pb.TagNumber(14)
  $core.bool hasBillingSummary() => $_has(6);
  @$pb.TagNumber(14)
  void clearBillingSummary() => $_clearField(14);
  @$pb.TagNumber(14)
  $0.ReqBillingSummary ensureBillingSummary() => $_ensure(6);

  @$pb.TagNumber(15)
  $0.ReqBillingPlanSubscribe get billingPlanSubscribe => $_getN(7);
  @$pb.TagNumber(15)
  set billingPlanSubscribe($0.ReqBillingPlanSubscribe value) =>
      $_setField(15, value);
  @$pb.TagNumber(15)
  $core.bool hasBillingPlanSubscribe() => $_has(7);
  @$pb.TagNumber(15)
  void clearBillingPlanSubscribe() => $_clearField(15);
  @$pb.TagNumber(15)
  $0.ReqBillingPlanSubscribe ensureBillingPlanSubscribe() => $_ensure(7);

  @$pb.TagNumber(16)
  $1.ReqConsumptionPut get consumptionPut => $_getN(8);
  @$pb.TagNumber(16)
  set consumptionPut($1.ReqConsumptionPut value) => $_setField(16, value);
  @$pb.TagNumber(16)
  $core.bool hasConsumptionPut() => $_has(8);
  @$pb.TagNumber(16)
  void clearConsumptionPut() => $_clearField(16);
  @$pb.TagNumber(16)
  $1.ReqConsumptionPut ensureConsumptionPut() => $_ensure(8);

  @$pb.TagNumber(17)
  $0.ReqBillingHistory get billingHistory => $_getN(9);
  @$pb.TagNumber(17)
  set billingHistory($0.ReqBillingHistory value) => $_setField(17, value);
  @$pb.TagNumber(17)
  $core.bool hasBillingHistory() => $_has(9);
  @$pb.TagNumber(17)
  void clearBillingHistory() => $_clearField(17);
  @$pb.TagNumber(17)
  $0.ReqBillingHistory ensureBillingHistory() => $_ensure(9);

  @$pb.TagNumber(62)
  $2.ReqReferralShareSet get referralShareSet => $_getN(10);
  @$pb.TagNumber(62)
  set referralShareSet($2.ReqReferralShareSet value) => $_setField(62, value);
  @$pb.TagNumber(62)
  $core.bool hasReferralShareSet() => $_has(10);
  @$pb.TagNumber(62)
  void clearReferralShareSet() => $_clearField(62);
  @$pb.TagNumber(62)
  $2.ReqReferralShareSet ensureReferralShareSet() => $_ensure(10);

  @$pb.TagNumber(64)
  $2.ReqReferralTreeGet get referralTreeGet => $_getN(11);
  @$pb.TagNumber(64)
  set referralTreeGet($2.ReqReferralTreeGet value) => $_setField(64, value);
  @$pb.TagNumber(64)
  $core.bool hasReferralTreeGet() => $_has(11);
  @$pb.TagNumber(64)
  void clearReferralTreeGet() => $_clearField(64);
  @$pb.TagNumber(64)
  $2.ReqReferralTreeGet ensureReferralTreeGet() => $_ensure(11);

  @$pb.TagNumber(65)
  $2.ReqReferralCodeList get referralCodeList => $_getN(12);
  @$pb.TagNumber(65)
  set referralCodeList($2.ReqReferralCodeList value) => $_setField(65, value);
  @$pb.TagNumber(65)
  $core.bool hasReferralCodeList() => $_has(12);
  @$pb.TagNumber(65)
  void clearReferralCodeList() => $_clearField(65);
  @$pb.TagNumber(65)
  $2.ReqReferralCodeList ensureReferralCodeList() => $_ensure(12);

  @$pb.TagNumber(67)
  $2.ReqReferralCodePut get referralCodePut => $_getN(13);
  @$pb.TagNumber(67)
  set referralCodePut($2.ReqReferralCodePut value) => $_setField(67, value);
  @$pb.TagNumber(67)
  $core.bool hasReferralCodePut() => $_has(13);
  @$pb.TagNumber(67)
  void clearReferralCodePut() => $_clearField(67);
  @$pb.TagNumber(67)
  $2.ReqReferralCodePut ensureReferralCodePut() => $_ensure(13);

  @$pb.TagNumber(68)
  $2.ReqReferralCodeDelete get referralCodeDelete => $_getN(14);
  @$pb.TagNumber(68)
  set referralCodeDelete($2.ReqReferralCodeDelete value) =>
      $_setField(68, value);
  @$pb.TagNumber(68)
  $core.bool hasReferralCodeDelete() => $_has(14);
  @$pb.TagNumber(68)
  void clearReferralCodeDelete() => $_clearField(68);
  @$pb.TagNumber(68)
  $2.ReqReferralCodeDelete ensureReferralCodeDelete() => $_ensure(14);

  @$pb.TagNumber(90)
  $3.ReqAdminUserSearch get adminUserSearch => $_getN(15);
  @$pb.TagNumber(90)
  set adminUserSearch($3.ReqAdminUserSearch value) => $_setField(90, value);
  @$pb.TagNumber(90)
  $core.bool hasAdminUserSearch() => $_has(15);
  @$pb.TagNumber(90)
  void clearAdminUserSearch() => $_clearField(90);
  @$pb.TagNumber(90)
  $3.ReqAdminUserSearch ensureAdminUserSearch() => $_ensure(15);

  @$pb.TagNumber(91)
  $3.ReqAdminUserPut get adminUserPut => $_getN(16);
  @$pb.TagNumber(91)
  set adminUserPut($3.ReqAdminUserPut value) => $_setField(91, value);
  @$pb.TagNumber(91)
  $core.bool hasAdminUserPut() => $_has(16);
  @$pb.TagNumber(91)
  void clearAdminUserPut() => $_clearField(91);
  @$pb.TagNumber(91)
  $3.ReqAdminUserPut ensureAdminUserPut() => $_ensure(16);

  @$pb.TagNumber(92)
  $2.ReqReferralUserStats get referralUserStats => $_getN(17);
  @$pb.TagNumber(92)
  set referralUserStats($2.ReqReferralUserStats value) => $_setField(92, value);
  @$pb.TagNumber(92)
  $core.bool hasReferralUserStats() => $_has(17);
  @$pb.TagNumber(92)
  void clearReferralUserStats() => $_clearField(92);
  @$pb.TagNumber(92)
  $2.ReqReferralUserStats ensureReferralUserStats() => $_ensure(17);

  @$pb.TagNumber(93)
  $2.ReqReferralCommissionSimulate get referralCommissionSimulate => $_getN(18);
  @$pb.TagNumber(93)
  set referralCommissionSimulate($2.ReqReferralCommissionSimulate value) =>
      $_setField(93, value);
  @$pb.TagNumber(93)
  $core.bool hasReferralCommissionSimulate() => $_has(18);
  @$pb.TagNumber(93)
  void clearReferralCommissionSimulate() => $_clearField(93);
  @$pb.TagNumber(93)
  $2.ReqReferralCommissionSimulate ensureReferralCommissionSimulate() =>
      $_ensure(18);

  @$pb.TagNumber(100)
  $4.ReqChannelTelegramConnect get channelTelegramConnect => $_getN(19);
  @$pb.TagNumber(100)
  set channelTelegramConnect($4.ReqChannelTelegramConnect value) =>
      $_setField(100, value);
  @$pb.TagNumber(100)
  $core.bool hasChannelTelegramConnect() => $_has(19);
  @$pb.TagNumber(100)
  void clearChannelTelegramConnect() => $_clearField(100);
  @$pb.TagNumber(100)
  $4.ReqChannelTelegramConnect ensureChannelTelegramConnect() => $_ensure(19);

  @$pb.TagNumber(101)
  $4.ReqChannelWhatsappMetaConnect get channelWhatsappMetaConnect => $_getN(20);
  @$pb.TagNumber(101)
  set channelWhatsappMetaConnect($4.ReqChannelWhatsappMetaConnect value) =>
      $_setField(101, value);
  @$pb.TagNumber(101)
  $core.bool hasChannelWhatsappMetaConnect() => $_has(20);
  @$pb.TagNumber(101)
  void clearChannelWhatsappMetaConnect() => $_clearField(101);
  @$pb.TagNumber(101)
  $4.ReqChannelWhatsappMetaConnect ensureChannelWhatsappMetaConnect() =>
      $_ensure(20);

  @$pb.TagNumber(102)
  $5.ReqDevicePair get devicePair => $_getN(21);
  @$pb.TagNumber(102)
  set devicePair($5.ReqDevicePair value) => $_setField(102, value);
  @$pb.TagNumber(102)
  $core.bool hasDevicePair() => $_has(21);
  @$pb.TagNumber(102)
  void clearDevicePair() => $_clearField(102);
  @$pb.TagNumber(102)
  $5.ReqDevicePair ensureDevicePair() => $_ensure(21);
}

enum InvokeRes_Body {
  billingTopupPut,
  billingPackageRedeem,
  billingPackagePreview,
  botUsageStats,
  billingSummary,
  billingPlanSubscribe,
  consumptionPut,
  billingHistory,
  referralShareSet,
  referralTreeGet,
  referralCodeList,
  referralCodePut,
  adminUserSearch,
  adminUserPut,
  referralUserStats,
  referralCommissionSimulate,
  channelTelegramConnect,
  channelWhatsappMetaConnect,
  devicePair,
  notSet
}

class InvokeRes extends $pb.GeneratedMessage {
  factory InvokeRes({
    $core.String? reqId,
    $core.int? statusCode,
    $core.String? errorMessage,
    $0.ResBillingTopupPut? billingTopupPut,
    $0.ResBillingPackageRedeem? billingPackageRedeem,
    $0.ResBillingPackagePreview? billingPackagePreview,
    $0.ResBotUsageStats? botUsageStats,
    $0.ResBillingSummary? billingSummary,
    $0.ResBillingPlanSubscribe? billingPlanSubscribe,
    $1.ResConsumptionPut? consumptionPut,
    $0.ResBillingHistory? billingHistory,
    $2.ResReferralShareSet? referralShareSet,
    $2.ResReferralTreeGet? referralTreeGet,
    $2.ResReferralCodeList? referralCodeList,
    $2.ReferralCodeDoc? referralCodePut,
    $3.ResAdminUserSearch? adminUserSearch,
    $3.ResAdminUserPut? adminUserPut,
    $2.ResReferralUserStats? referralUserStats,
    $2.ResReferralCommissionSimulate? referralCommissionSimulate,
    $4.ResChannelTelegramConnect? channelTelegramConnect,
    $4.ResChannelWhatsappMetaConnect? channelWhatsappMetaConnect,
    $5.ResDevicePair? devicePair,
  }) {
    final result = InvokeRes._();
    if (reqId != null) result.reqId = reqId;
    if (statusCode != null) result.statusCode = statusCode;
    if (errorMessage != null) result.errorMessage = errorMessage;
    if (billingTopupPut != null) result.billingTopupPut = billingTopupPut;
    if (billingPackageRedeem != null)
      result.billingPackageRedeem = billingPackageRedeem;
    if (billingPackagePreview != null)
      result.billingPackagePreview = billingPackagePreview;
    if (botUsageStats != null) result.botUsageStats = botUsageStats;
    if (billingSummary != null) result.billingSummary = billingSummary;
    if (billingPlanSubscribe != null)
      result.billingPlanSubscribe = billingPlanSubscribe;
    if (consumptionPut != null) result.consumptionPut = consumptionPut;
    if (billingHistory != null) result.billingHistory = billingHistory;
    if (referralShareSet != null) result.referralShareSet = referralShareSet;
    if (referralTreeGet != null) result.referralTreeGet = referralTreeGet;
    if (referralCodeList != null) result.referralCodeList = referralCodeList;
    if (referralCodePut != null) result.referralCodePut = referralCodePut;
    if (adminUserSearch != null) result.adminUserSearch = adminUserSearch;
    if (adminUserPut != null) result.adminUserPut = adminUserPut;
    if (referralUserStats != null) result.referralUserStats = referralUserStats;
    if (referralCommissionSimulate != null)
      result.referralCommissionSimulate = referralCommissionSimulate;
    if (channelTelegramConnect != null)
      result.channelTelegramConnect = channelTelegramConnect;
    if (channelWhatsappMetaConnect != null)
      result.channelWhatsappMetaConnect = channelWhatsappMetaConnect;
    if (devicePair != null) result.devicePair = devicePair;
    return result;
  }

  InvokeRes._();

  factory InvokeRes.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      InvokeRes()..mergeFromBuffer(data, registry);
  factory InvokeRes.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      InvokeRes()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, InvokeRes_Body> _InvokeRes_BodyByTag = {
    10: InvokeRes_Body.billingTopupPut,
    11: InvokeRes_Body.billingPackageRedeem,
    12: InvokeRes_Body.billingPackagePreview,
    13: InvokeRes_Body.botUsageStats,
    14: InvokeRes_Body.billingSummary,
    15: InvokeRes_Body.billingPlanSubscribe,
    16: InvokeRes_Body.consumptionPut,
    17: InvokeRes_Body.billingHistory,
    62: InvokeRes_Body.referralShareSet,
    64: InvokeRes_Body.referralTreeGet,
    65: InvokeRes_Body.referralCodeList,
    67: InvokeRes_Body.referralCodePut,
    90: InvokeRes_Body.adminUserSearch,
    91: InvokeRes_Body.adminUserPut,
    92: InvokeRes_Body.referralUserStats,
    93: InvokeRes_Body.referralCommissionSimulate,
    100: InvokeRes_Body.channelTelegramConnect,
    101: InvokeRes_Body.channelWhatsappMetaConnect,
    102: InvokeRes_Body.devicePair,
    0: InvokeRes_Body.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InvokeRes',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: InvokeRes.$_createMessage)
    ..oo(0, [
      10,
      11,
      12,
      13,
      14,
      15,
      16,
      17,
      62,
      64,
      65,
      67,
      90,
      91,
      92,
      93,
      100,
      101,
      102
    ])
    ..aOS(1, _omitFieldNames ? '' : 'reqId')
    ..aI(2, _omitFieldNames ? '' : 'statusCode')
    ..aOS(3, _omitFieldNames ? '' : 'errorMessage')
    ..aOM<$0.ResBillingTopupPut>(10, _omitFieldNames ? '' : 'billingTopupPut',
        subBuilder: $0.ResBillingTopupPut.$_createMessage)
    ..aOM<$0.ResBillingPackageRedeem>(
        11, _omitFieldNames ? '' : 'billingPackageRedeem',
        subBuilder: $0.ResBillingPackageRedeem.$_createMessage)
    ..aOM<$0.ResBillingPackagePreview>(
        12, _omitFieldNames ? '' : 'billingPackagePreview',
        subBuilder: $0.ResBillingPackagePreview.$_createMessage)
    ..aOM<$0.ResBotUsageStats>(13, _omitFieldNames ? '' : 'botUsageStats',
        subBuilder: $0.ResBotUsageStats.$_createMessage)
    ..aOM<$0.ResBillingSummary>(14, _omitFieldNames ? '' : 'billingSummary',
        subBuilder: $0.ResBillingSummary.$_createMessage)
    ..aOM<$0.ResBillingPlanSubscribe>(
        15, _omitFieldNames ? '' : 'billingPlanSubscribe',
        subBuilder: $0.ResBillingPlanSubscribe.$_createMessage)
    ..aOM<$1.ResConsumptionPut>(16, _omitFieldNames ? '' : 'consumptionPut',
        subBuilder: $1.ResConsumptionPut.$_createMessage)
    ..aOM<$0.ResBillingHistory>(17, _omitFieldNames ? '' : 'billingHistory',
        subBuilder: $0.ResBillingHistory.$_createMessage)
    ..aOM<$2.ResReferralShareSet>(62, _omitFieldNames ? '' : 'referralShareSet',
        subBuilder: $2.ResReferralShareSet.$_createMessage)
    ..aOM<$2.ResReferralTreeGet>(64, _omitFieldNames ? '' : 'referralTreeGet',
        subBuilder: $2.ResReferralTreeGet.$_createMessage)
    ..aOM<$2.ResReferralCodeList>(65, _omitFieldNames ? '' : 'referralCodeList',
        subBuilder: $2.ResReferralCodeList.$_createMessage)
    ..aOM<$2.ReferralCodeDoc>(67, _omitFieldNames ? '' : 'referralCodePut',
        subBuilder: $2.ReferralCodeDoc.$_createMessage)
    ..aOM<$3.ResAdminUserSearch>(90, _omitFieldNames ? '' : 'adminUserSearch',
        subBuilder: $3.ResAdminUserSearch.$_createMessage)
    ..aOM<$3.ResAdminUserPut>(91, _omitFieldNames ? '' : 'adminUserPut',
        subBuilder: $3.ResAdminUserPut.$_createMessage)
    ..aOM<$2.ResReferralUserStats>(
        92, _omitFieldNames ? '' : 'referralUserStats',
        subBuilder: $2.ResReferralUserStats.$_createMessage)
    ..aOM<$2.ResReferralCommissionSimulate>(
        93, _omitFieldNames ? '' : 'referralCommissionSimulate',
        subBuilder: $2.ResReferralCommissionSimulate.$_createMessage)
    ..aOM<$4.ResChannelTelegramConnect>(
        100, _omitFieldNames ? '' : 'channelTelegramConnect',
        subBuilder: $4.ResChannelTelegramConnect.$_createMessage)
    ..aOM<$4.ResChannelWhatsappMetaConnect>(
        101, _omitFieldNames ? '' : 'channelWhatsappMetaConnect',
        subBuilder: $4.ResChannelWhatsappMetaConnect.$_createMessage)
    ..aOM<$5.ResDevicePair>(102, _omitFieldNames ? '' : 'devicePair',
        subBuilder: $5.ResDevicePair.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InvokeRes clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InvokeRes copyWith(void Function(InvokeRes) updates) =>
      super.copyWith((message) => updates(message as InvokeRes)) as InvokeRes;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use InvokeRes() / InvokeRes.new instead')
  static InvokeRes create() => InvokeRes._();
  static $pb.GeneratedMessage $_createMessage() => InvokeRes._();
  @$core.override
  InvokeRes createEmptyInstance() => InvokeRes._();
  @$core.pragma('dart2js:noInline')
  static InvokeRes getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<InvokeRes>(InvokeRes.$_createMessage);
  static InvokeRes? _defaultInstance;

  @$pb.TagNumber(10)
  @$pb.TagNumber(11)
  @$pb.TagNumber(12)
  @$pb.TagNumber(13)
  @$pb.TagNumber(14)
  @$pb.TagNumber(15)
  @$pb.TagNumber(16)
  @$pb.TagNumber(17)
  @$pb.TagNumber(62)
  @$pb.TagNumber(64)
  @$pb.TagNumber(65)
  @$pb.TagNumber(67)
  @$pb.TagNumber(90)
  @$pb.TagNumber(91)
  @$pb.TagNumber(92)
  @$pb.TagNumber(93)
  @$pb.TagNumber(100)
  @$pb.TagNumber(101)
  @$pb.TagNumber(102)
  InvokeRes_Body whichBody() => _InvokeRes_BodyByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(10)
  @$pb.TagNumber(11)
  @$pb.TagNumber(12)
  @$pb.TagNumber(13)
  @$pb.TagNumber(14)
  @$pb.TagNumber(15)
  @$pb.TagNumber(16)
  @$pb.TagNumber(17)
  @$pb.TagNumber(62)
  @$pb.TagNumber(64)
  @$pb.TagNumber(65)
  @$pb.TagNumber(67)
  @$pb.TagNumber(90)
  @$pb.TagNumber(91)
  @$pb.TagNumber(92)
  @$pb.TagNumber(93)
  @$pb.TagNumber(100)
  @$pb.TagNumber(101)
  @$pb.TagNumber(102)
  void clearBody() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get reqId => $_getSZ(0);
  @$pb.TagNumber(1)
  set reqId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasReqId() => $_has(0);
  @$pb.TagNumber(1)
  void clearReqId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get statusCode => $_getIZ(1);
  @$pb.TagNumber(2)
  set statusCode($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasStatusCode() => $_has(1);
  @$pb.TagNumber(2)
  void clearStatusCode() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get errorMessage => $_getSZ(2);
  @$pb.TagNumber(3)
  set errorMessage($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasErrorMessage() => $_has(2);
  @$pb.TagNumber(3)
  void clearErrorMessage() => $_clearField(3);

  @$pb.TagNumber(10)
  $0.ResBillingTopupPut get billingTopupPut => $_getN(3);
  @$pb.TagNumber(10)
  set billingTopupPut($0.ResBillingTopupPut value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasBillingTopupPut() => $_has(3);
  @$pb.TagNumber(10)
  void clearBillingTopupPut() => $_clearField(10);
  @$pb.TagNumber(10)
  $0.ResBillingTopupPut ensureBillingTopupPut() => $_ensure(3);

  @$pb.TagNumber(11)
  $0.ResBillingPackageRedeem get billingPackageRedeem => $_getN(4);
  @$pb.TagNumber(11)
  set billingPackageRedeem($0.ResBillingPackageRedeem value) =>
      $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasBillingPackageRedeem() => $_has(4);
  @$pb.TagNumber(11)
  void clearBillingPackageRedeem() => $_clearField(11);
  @$pb.TagNumber(11)
  $0.ResBillingPackageRedeem ensureBillingPackageRedeem() => $_ensure(4);

  @$pb.TagNumber(12)
  $0.ResBillingPackagePreview get billingPackagePreview => $_getN(5);
  @$pb.TagNumber(12)
  set billingPackagePreview($0.ResBillingPackagePreview value) =>
      $_setField(12, value);
  @$pb.TagNumber(12)
  $core.bool hasBillingPackagePreview() => $_has(5);
  @$pb.TagNumber(12)
  void clearBillingPackagePreview() => $_clearField(12);
  @$pb.TagNumber(12)
  $0.ResBillingPackagePreview ensureBillingPackagePreview() => $_ensure(5);

  @$pb.TagNumber(13)
  $0.ResBotUsageStats get botUsageStats => $_getN(6);
  @$pb.TagNumber(13)
  set botUsageStats($0.ResBotUsageStats value) => $_setField(13, value);
  @$pb.TagNumber(13)
  $core.bool hasBotUsageStats() => $_has(6);
  @$pb.TagNumber(13)
  void clearBotUsageStats() => $_clearField(13);
  @$pb.TagNumber(13)
  $0.ResBotUsageStats ensureBotUsageStats() => $_ensure(6);

  @$pb.TagNumber(14)
  $0.ResBillingSummary get billingSummary => $_getN(7);
  @$pb.TagNumber(14)
  set billingSummary($0.ResBillingSummary value) => $_setField(14, value);
  @$pb.TagNumber(14)
  $core.bool hasBillingSummary() => $_has(7);
  @$pb.TagNumber(14)
  void clearBillingSummary() => $_clearField(14);
  @$pb.TagNumber(14)
  $0.ResBillingSummary ensureBillingSummary() => $_ensure(7);

  @$pb.TagNumber(15)
  $0.ResBillingPlanSubscribe get billingPlanSubscribe => $_getN(8);
  @$pb.TagNumber(15)
  set billingPlanSubscribe($0.ResBillingPlanSubscribe value) =>
      $_setField(15, value);
  @$pb.TagNumber(15)
  $core.bool hasBillingPlanSubscribe() => $_has(8);
  @$pb.TagNumber(15)
  void clearBillingPlanSubscribe() => $_clearField(15);
  @$pb.TagNumber(15)
  $0.ResBillingPlanSubscribe ensureBillingPlanSubscribe() => $_ensure(8);

  @$pb.TagNumber(16)
  $1.ResConsumptionPut get consumptionPut => $_getN(9);
  @$pb.TagNumber(16)
  set consumptionPut($1.ResConsumptionPut value) => $_setField(16, value);
  @$pb.TagNumber(16)
  $core.bool hasConsumptionPut() => $_has(9);
  @$pb.TagNumber(16)
  void clearConsumptionPut() => $_clearField(16);
  @$pb.TagNumber(16)
  $1.ResConsumptionPut ensureConsumptionPut() => $_ensure(9);

  @$pb.TagNumber(17)
  $0.ResBillingHistory get billingHistory => $_getN(10);
  @$pb.TagNumber(17)
  set billingHistory($0.ResBillingHistory value) => $_setField(17, value);
  @$pb.TagNumber(17)
  $core.bool hasBillingHistory() => $_has(10);
  @$pb.TagNumber(17)
  void clearBillingHistory() => $_clearField(17);
  @$pb.TagNumber(17)
  $0.ResBillingHistory ensureBillingHistory() => $_ensure(10);

  @$pb.TagNumber(62)
  $2.ResReferralShareSet get referralShareSet => $_getN(11);
  @$pb.TagNumber(62)
  set referralShareSet($2.ResReferralShareSet value) => $_setField(62, value);
  @$pb.TagNumber(62)
  $core.bool hasReferralShareSet() => $_has(11);
  @$pb.TagNumber(62)
  void clearReferralShareSet() => $_clearField(62);
  @$pb.TagNumber(62)
  $2.ResReferralShareSet ensureReferralShareSet() => $_ensure(11);

  @$pb.TagNumber(64)
  $2.ResReferralTreeGet get referralTreeGet => $_getN(12);
  @$pb.TagNumber(64)
  set referralTreeGet($2.ResReferralTreeGet value) => $_setField(64, value);
  @$pb.TagNumber(64)
  $core.bool hasReferralTreeGet() => $_has(12);
  @$pb.TagNumber(64)
  void clearReferralTreeGet() => $_clearField(64);
  @$pb.TagNumber(64)
  $2.ResReferralTreeGet ensureReferralTreeGet() => $_ensure(12);

  @$pb.TagNumber(65)
  $2.ResReferralCodeList get referralCodeList => $_getN(13);
  @$pb.TagNumber(65)
  set referralCodeList($2.ResReferralCodeList value) => $_setField(65, value);
  @$pb.TagNumber(65)
  $core.bool hasReferralCodeList() => $_has(13);
  @$pb.TagNumber(65)
  void clearReferralCodeList() => $_clearField(65);
  @$pb.TagNumber(65)
  $2.ResReferralCodeList ensureReferralCodeList() => $_ensure(13);

  @$pb.TagNumber(67)
  $2.ReferralCodeDoc get referralCodePut => $_getN(14);
  @$pb.TagNumber(67)
  set referralCodePut($2.ReferralCodeDoc value) => $_setField(67, value);
  @$pb.TagNumber(67)
  $core.bool hasReferralCodePut() => $_has(14);
  @$pb.TagNumber(67)
  void clearReferralCodePut() => $_clearField(67);
  @$pb.TagNumber(67)
  $2.ReferralCodeDoc ensureReferralCodePut() => $_ensure(14);

  @$pb.TagNumber(90)
  $3.ResAdminUserSearch get adminUserSearch => $_getN(15);
  @$pb.TagNumber(90)
  set adminUserSearch($3.ResAdminUserSearch value) => $_setField(90, value);
  @$pb.TagNumber(90)
  $core.bool hasAdminUserSearch() => $_has(15);
  @$pb.TagNumber(90)
  void clearAdminUserSearch() => $_clearField(90);
  @$pb.TagNumber(90)
  $3.ResAdminUserSearch ensureAdminUserSearch() => $_ensure(15);

  @$pb.TagNumber(91)
  $3.ResAdminUserPut get adminUserPut => $_getN(16);
  @$pb.TagNumber(91)
  set adminUserPut($3.ResAdminUserPut value) => $_setField(91, value);
  @$pb.TagNumber(91)
  $core.bool hasAdminUserPut() => $_has(16);
  @$pb.TagNumber(91)
  void clearAdminUserPut() => $_clearField(91);
  @$pb.TagNumber(91)
  $3.ResAdminUserPut ensureAdminUserPut() => $_ensure(16);

  @$pb.TagNumber(92)
  $2.ResReferralUserStats get referralUserStats => $_getN(17);
  @$pb.TagNumber(92)
  set referralUserStats($2.ResReferralUserStats value) => $_setField(92, value);
  @$pb.TagNumber(92)
  $core.bool hasReferralUserStats() => $_has(17);
  @$pb.TagNumber(92)
  void clearReferralUserStats() => $_clearField(92);
  @$pb.TagNumber(92)
  $2.ResReferralUserStats ensureReferralUserStats() => $_ensure(17);

  @$pb.TagNumber(93)
  $2.ResReferralCommissionSimulate get referralCommissionSimulate => $_getN(18);
  @$pb.TagNumber(93)
  set referralCommissionSimulate($2.ResReferralCommissionSimulate value) =>
      $_setField(93, value);
  @$pb.TagNumber(93)
  $core.bool hasReferralCommissionSimulate() => $_has(18);
  @$pb.TagNumber(93)
  void clearReferralCommissionSimulate() => $_clearField(93);
  @$pb.TagNumber(93)
  $2.ResReferralCommissionSimulate ensureReferralCommissionSimulate() =>
      $_ensure(18);

  @$pb.TagNumber(100)
  $4.ResChannelTelegramConnect get channelTelegramConnect => $_getN(19);
  @$pb.TagNumber(100)
  set channelTelegramConnect($4.ResChannelTelegramConnect value) =>
      $_setField(100, value);
  @$pb.TagNumber(100)
  $core.bool hasChannelTelegramConnect() => $_has(19);
  @$pb.TagNumber(100)
  void clearChannelTelegramConnect() => $_clearField(100);
  @$pb.TagNumber(100)
  $4.ResChannelTelegramConnect ensureChannelTelegramConnect() => $_ensure(19);

  @$pb.TagNumber(101)
  $4.ResChannelWhatsappMetaConnect get channelWhatsappMetaConnect => $_getN(20);
  @$pb.TagNumber(101)
  set channelWhatsappMetaConnect($4.ResChannelWhatsappMetaConnect value) =>
      $_setField(101, value);
  @$pb.TagNumber(101)
  $core.bool hasChannelWhatsappMetaConnect() => $_has(20);
  @$pb.TagNumber(101)
  void clearChannelWhatsappMetaConnect() => $_clearField(101);
  @$pb.TagNumber(101)
  $4.ResChannelWhatsappMetaConnect ensureChannelWhatsappMetaConnect() =>
      $_ensure(20);

  @$pb.TagNumber(102)
  $5.ResDevicePair get devicePair => $_getN(21);
  @$pb.TagNumber(102)
  set devicePair($5.ResDevicePair value) => $_setField(102, value);
  @$pb.TagNumber(102)
  $core.bool hasDevicePair() => $_has(21);
  @$pb.TagNumber(102)
  void clearDevicePair() => $_clearField(102);
  @$pb.TagNumber(102)
  $5.ResDevicePair ensureDevicePair() => $_ensure(21);
}

enum WsReq_Body {
  sessionInit,
  sync,
  inboxList,
  chatMsgList,
  prompt,
  promptAbort,
  chatStop,
  chatSend,
  invoke,
  skillList,
  consumptionList,
  siteList,
  txList,
  consumptionPut,
  chatPatch,
  assetTagList,
  identityList,
  identityGrantPatch,
  botPeerList,
  logList,
  identityPut,
  channelWhatsappPairStart,
  channelWhatsappPairWatch,
  channelWhatsappPairAbort,
  notSet
}

/// WebSocket client → server
class WsReq extends $pb.GeneratedMessage {
  factory WsReq({
    $core.String? reqId,
    $6.ReqSessionInit? sessionInit,
    $7.ReqSync? sync,
    $8.ReqInboxList? inboxList,
    $8.ReqChatMsgList? chatMsgList,
    $8.ReqPrompt? prompt,
    $8.ReqPromptAbort? promptAbort,
    $8.ReqChatStop? chatStop,
    $8.ReqChatSend? chatSend,
    InvokeReq? invoke,
    $9.ReqSkillList? skillList,
    $1.ReqConsumptionList? consumptionList,
    $10.ReqSiteList? siteList,
    $11.ReqTxList? txList,
    $1.ReqConsumptionPut? consumptionPut,
    $8.ReqChatPatch? chatPatch,
    $8.ReqAssetTagList? assetTagList,
    $12.ReqIdentityList? identityList,
    $12.ReqIdentityGrantPatch? identityGrantPatch,
    $8.ReqBotPeerList? botPeerList,
    $8.ReqLogList? logList,
    $12.ReqIdentityPut? identityPut,
    $4.ReqChannelWhatsappPairStart? channelWhatsappPairStart,
    $4.ReqChannelWhatsappPairWatch? channelWhatsappPairWatch,
    $4.ReqChannelWhatsappPairAbort? channelWhatsappPairAbort,
  }) {
    final result = WsReq._();
    if (reqId != null) result.reqId = reqId;
    if (sessionInit != null) result.sessionInit = sessionInit;
    if (sync != null) result.sync = sync;
    if (inboxList != null) result.inboxList = inboxList;
    if (chatMsgList != null) result.chatMsgList = chatMsgList;
    if (prompt != null) result.prompt = prompt;
    if (promptAbort != null) result.promptAbort = promptAbort;
    if (chatStop != null) result.chatStop = chatStop;
    if (chatSend != null) result.chatSend = chatSend;
    if (invoke != null) result.invoke = invoke;
    if (skillList != null) result.skillList = skillList;
    if (consumptionList != null) result.consumptionList = consumptionList;
    if (siteList != null) result.siteList = siteList;
    if (txList != null) result.txList = txList;
    if (consumptionPut != null) result.consumptionPut = consumptionPut;
    if (chatPatch != null) result.chatPatch = chatPatch;
    if (assetTagList != null) result.assetTagList = assetTagList;
    if (identityList != null) result.identityList = identityList;
    if (identityGrantPatch != null)
      result.identityGrantPatch = identityGrantPatch;
    if (botPeerList != null) result.botPeerList = botPeerList;
    if (logList != null) result.logList = logList;
    if (identityPut != null) result.identityPut = identityPut;
    if (channelWhatsappPairStart != null)
      result.channelWhatsappPairStart = channelWhatsappPairStart;
    if (channelWhatsappPairWatch != null)
      result.channelWhatsappPairWatch = channelWhatsappPairWatch;
    if (channelWhatsappPairAbort != null)
      result.channelWhatsappPairAbort = channelWhatsappPairAbort;
    return result;
  }

  WsReq._();

  factory WsReq.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      WsReq()..mergeFromBuffer(data, registry);
  factory WsReq.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      WsReq()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, WsReq_Body> _WsReq_BodyByTag = {
    2: WsReq_Body.sessionInit,
    3: WsReq_Body.sync,
    4: WsReq_Body.inboxList,
    5: WsReq_Body.chatMsgList,
    6: WsReq_Body.prompt,
    7: WsReq_Body.promptAbort,
    8: WsReq_Body.chatStop,
    9: WsReq_Body.chatSend,
    10: WsReq_Body.invoke,
    20: WsReq_Body.skillList,
    21: WsReq_Body.consumptionList,
    22: WsReq_Body.siteList,
    23: WsReq_Body.txList,
    24: WsReq_Body.consumptionPut,
    25: WsReq_Body.chatPatch,
    26: WsReq_Body.assetTagList,
    27: WsReq_Body.identityList,
    28: WsReq_Body.identityGrantPatch,
    29: WsReq_Body.botPeerList,
    30: WsReq_Body.logList,
    31: WsReq_Body.identityPut,
    32: WsReq_Body.channelWhatsappPairStart,
    33: WsReq_Body.channelWhatsappPairWatch,
    34: WsReq_Body.channelWhatsappPairAbort,
    0: WsReq_Body.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WsReq',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: WsReq.$_createMessage)
    ..oo(0, [
      2,
      3,
      4,
      5,
      6,
      7,
      8,
      9,
      10,
      20,
      21,
      22,
      23,
      24,
      25,
      26,
      27,
      28,
      29,
      30,
      31,
      32,
      33,
      34
    ])
    ..aOS(1, _omitFieldNames ? '' : 'reqId')
    ..aOM<$6.ReqSessionInit>(2, _omitFieldNames ? '' : 'sessionInit',
        subBuilder: $6.ReqSessionInit.$_createMessage)
    ..aOM<$7.ReqSync>(3, _omitFieldNames ? '' : 'sync',
        subBuilder: $7.ReqSync.$_createMessage)
    ..aOM<$8.ReqInboxList>(4, _omitFieldNames ? '' : 'inboxList',
        subBuilder: $8.ReqInboxList.$_createMessage)
    ..aOM<$8.ReqChatMsgList>(5, _omitFieldNames ? '' : 'chatMsgList',
        subBuilder: $8.ReqChatMsgList.$_createMessage)
    ..aOM<$8.ReqPrompt>(6, _omitFieldNames ? '' : 'prompt',
        subBuilder: $8.ReqPrompt.$_createMessage)
    ..aOM<$8.ReqPromptAbort>(7, _omitFieldNames ? '' : 'promptAbort',
        subBuilder: $8.ReqPromptAbort.$_createMessage)
    ..aOM<$8.ReqChatStop>(8, _omitFieldNames ? '' : 'chatStop',
        subBuilder: $8.ReqChatStop.$_createMessage)
    ..aOM<$8.ReqChatSend>(9, _omitFieldNames ? '' : 'chatSend',
        subBuilder: $8.ReqChatSend.$_createMessage)
    ..aOM<InvokeReq>(10, _omitFieldNames ? '' : 'invoke',
        subBuilder: InvokeReq.$_createMessage)
    ..aOM<$9.ReqSkillList>(20, _omitFieldNames ? '' : 'skillList',
        subBuilder: $9.ReqSkillList.$_createMessage)
    ..aOM<$1.ReqConsumptionList>(21, _omitFieldNames ? '' : 'consumptionList',
        subBuilder: $1.ReqConsumptionList.$_createMessage)
    ..aOM<$10.ReqSiteList>(22, _omitFieldNames ? '' : 'siteList',
        subBuilder: $10.ReqSiteList.$_createMessage)
    ..aOM<$11.ReqTxList>(23, _omitFieldNames ? '' : 'txList',
        subBuilder: $11.ReqTxList.$_createMessage)
    ..aOM<$1.ReqConsumptionPut>(24, _omitFieldNames ? '' : 'consumptionPut',
        subBuilder: $1.ReqConsumptionPut.$_createMessage)
    ..aOM<$8.ReqChatPatch>(25, _omitFieldNames ? '' : 'chatPatch',
        subBuilder: $8.ReqChatPatch.$_createMessage)
    ..aOM<$8.ReqAssetTagList>(26, _omitFieldNames ? '' : 'assetTagList',
        subBuilder: $8.ReqAssetTagList.$_createMessage)
    ..aOM<$12.ReqIdentityList>(27, _omitFieldNames ? '' : 'identityList',
        subBuilder: $12.ReqIdentityList.$_createMessage)
    ..aOM<$12.ReqIdentityGrantPatch>(
        28, _omitFieldNames ? '' : 'identityGrantPatch',
        subBuilder: $12.ReqIdentityGrantPatch.$_createMessage)
    ..aOM<$8.ReqBotPeerList>(29, _omitFieldNames ? '' : 'botPeerList',
        subBuilder: $8.ReqBotPeerList.$_createMessage)
    ..aOM<$8.ReqLogList>(30, _omitFieldNames ? '' : 'logList',
        subBuilder: $8.ReqLogList.$_createMessage)
    ..aOM<$12.ReqIdentityPut>(31, _omitFieldNames ? '' : 'identityPut',
        subBuilder: $12.ReqIdentityPut.$_createMessage)
    ..aOM<$4.ReqChannelWhatsappPairStart>(
        32, _omitFieldNames ? '' : 'channelWhatsappPairStart',
        subBuilder: $4.ReqChannelWhatsappPairStart.$_createMessage)
    ..aOM<$4.ReqChannelWhatsappPairWatch>(
        33, _omitFieldNames ? '' : 'channelWhatsappPairWatch',
        subBuilder: $4.ReqChannelWhatsappPairWatch.$_createMessage)
    ..aOM<$4.ReqChannelWhatsappPairAbort>(
        34, _omitFieldNames ? '' : 'channelWhatsappPairAbort',
        subBuilder: $4.ReqChannelWhatsappPairAbort.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WsReq clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WsReq copyWith(void Function(WsReq) updates) =>
      super.copyWith((message) => updates(message as WsReq)) as WsReq;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use WsReq() / WsReq.new instead')
  static WsReq create() => WsReq._();
  static $pb.GeneratedMessage $_createMessage() => WsReq._();
  @$core.override
  WsReq createEmptyInstance() => WsReq._();
  @$core.pragma('dart2js:noInline')
  static WsReq getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WsReq>(WsReq.$_createMessage);
  static WsReq? _defaultInstance;

  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  @$pb.TagNumber(6)
  @$pb.TagNumber(7)
  @$pb.TagNumber(8)
  @$pb.TagNumber(9)
  @$pb.TagNumber(10)
  @$pb.TagNumber(20)
  @$pb.TagNumber(21)
  @$pb.TagNumber(22)
  @$pb.TagNumber(23)
  @$pb.TagNumber(24)
  @$pb.TagNumber(25)
  @$pb.TagNumber(26)
  @$pb.TagNumber(27)
  @$pb.TagNumber(28)
  @$pb.TagNumber(29)
  @$pb.TagNumber(30)
  @$pb.TagNumber(31)
  @$pb.TagNumber(32)
  @$pb.TagNumber(33)
  @$pb.TagNumber(34)
  WsReq_Body whichBody() => _WsReq_BodyByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  @$pb.TagNumber(6)
  @$pb.TagNumber(7)
  @$pb.TagNumber(8)
  @$pb.TagNumber(9)
  @$pb.TagNumber(10)
  @$pb.TagNumber(20)
  @$pb.TagNumber(21)
  @$pb.TagNumber(22)
  @$pb.TagNumber(23)
  @$pb.TagNumber(24)
  @$pb.TagNumber(25)
  @$pb.TagNumber(26)
  @$pb.TagNumber(27)
  @$pb.TagNumber(28)
  @$pb.TagNumber(29)
  @$pb.TagNumber(30)
  @$pb.TagNumber(31)
  @$pb.TagNumber(32)
  @$pb.TagNumber(33)
  @$pb.TagNumber(34)
  void clearBody() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get reqId => $_getSZ(0);
  @$pb.TagNumber(1)
  set reqId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasReqId() => $_has(0);
  @$pb.TagNumber(1)
  void clearReqId() => $_clearField(1);

  @$pb.TagNumber(2)
  $6.ReqSessionInit get sessionInit => $_getN(1);
  @$pb.TagNumber(2)
  set sessionInit($6.ReqSessionInit value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasSessionInit() => $_has(1);
  @$pb.TagNumber(2)
  void clearSessionInit() => $_clearField(2);
  @$pb.TagNumber(2)
  $6.ReqSessionInit ensureSessionInit() => $_ensure(1);

  @$pb.TagNumber(3)
  $7.ReqSync get sync => $_getN(2);
  @$pb.TagNumber(3)
  set sync($7.ReqSync value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasSync() => $_has(2);
  @$pb.TagNumber(3)
  void clearSync() => $_clearField(3);
  @$pb.TagNumber(3)
  $7.ReqSync ensureSync() => $_ensure(2);

  @$pb.TagNumber(4)
  $8.ReqInboxList get inboxList => $_getN(3);
  @$pb.TagNumber(4)
  set inboxList($8.ReqInboxList value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasInboxList() => $_has(3);
  @$pb.TagNumber(4)
  void clearInboxList() => $_clearField(4);
  @$pb.TagNumber(4)
  $8.ReqInboxList ensureInboxList() => $_ensure(3);

  @$pb.TagNumber(5)
  $8.ReqChatMsgList get chatMsgList => $_getN(4);
  @$pb.TagNumber(5)
  set chatMsgList($8.ReqChatMsgList value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasChatMsgList() => $_has(4);
  @$pb.TagNumber(5)
  void clearChatMsgList() => $_clearField(5);
  @$pb.TagNumber(5)
  $8.ReqChatMsgList ensureChatMsgList() => $_ensure(4);

  @$pb.TagNumber(6)
  $8.ReqPrompt get prompt => $_getN(5);
  @$pb.TagNumber(6)
  set prompt($8.ReqPrompt value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasPrompt() => $_has(5);
  @$pb.TagNumber(6)
  void clearPrompt() => $_clearField(6);
  @$pb.TagNumber(6)
  $8.ReqPrompt ensurePrompt() => $_ensure(5);

  @$pb.TagNumber(7)
  $8.ReqPromptAbort get promptAbort => $_getN(6);
  @$pb.TagNumber(7)
  set promptAbort($8.ReqPromptAbort value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasPromptAbort() => $_has(6);
  @$pb.TagNumber(7)
  void clearPromptAbort() => $_clearField(7);
  @$pb.TagNumber(7)
  $8.ReqPromptAbort ensurePromptAbort() => $_ensure(6);

  @$pb.TagNumber(8)
  $8.ReqChatStop get chatStop => $_getN(7);
  @$pb.TagNumber(8)
  set chatStop($8.ReqChatStop value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasChatStop() => $_has(7);
  @$pb.TagNumber(8)
  void clearChatStop() => $_clearField(8);
  @$pb.TagNumber(8)
  $8.ReqChatStop ensureChatStop() => $_ensure(7);

  @$pb.TagNumber(9)
  $8.ReqChatSend get chatSend => $_getN(8);
  @$pb.TagNumber(9)
  set chatSend($8.ReqChatSend value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasChatSend() => $_has(8);
  @$pb.TagNumber(9)
  void clearChatSend() => $_clearField(9);
  @$pb.TagNumber(9)
  $8.ReqChatSend ensureChatSend() => $_ensure(8);

  @$pb.TagNumber(10)
  InvokeReq get invoke => $_getN(9);
  @$pb.TagNumber(10)
  set invoke(InvokeReq value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasInvoke() => $_has(9);
  @$pb.TagNumber(10)
  void clearInvoke() => $_clearField(10);
  @$pb.TagNumber(10)
  InvokeReq ensureInvoke() => $_ensure(9);

  @$pb.TagNumber(20)
  $9.ReqSkillList get skillList => $_getN(10);
  @$pb.TagNumber(20)
  set skillList($9.ReqSkillList value) => $_setField(20, value);
  @$pb.TagNumber(20)
  $core.bool hasSkillList() => $_has(10);
  @$pb.TagNumber(20)
  void clearSkillList() => $_clearField(20);
  @$pb.TagNumber(20)
  $9.ReqSkillList ensureSkillList() => $_ensure(10);

  @$pb.TagNumber(21)
  $1.ReqConsumptionList get consumptionList => $_getN(11);
  @$pb.TagNumber(21)
  set consumptionList($1.ReqConsumptionList value) => $_setField(21, value);
  @$pb.TagNumber(21)
  $core.bool hasConsumptionList() => $_has(11);
  @$pb.TagNumber(21)
  void clearConsumptionList() => $_clearField(21);
  @$pb.TagNumber(21)
  $1.ReqConsumptionList ensureConsumptionList() => $_ensure(11);

  @$pb.TagNumber(22)
  $10.ReqSiteList get siteList => $_getN(12);
  @$pb.TagNumber(22)
  set siteList($10.ReqSiteList value) => $_setField(22, value);
  @$pb.TagNumber(22)
  $core.bool hasSiteList() => $_has(12);
  @$pb.TagNumber(22)
  void clearSiteList() => $_clearField(22);
  @$pb.TagNumber(22)
  $10.ReqSiteList ensureSiteList() => $_ensure(12);

  @$pb.TagNumber(23)
  $11.ReqTxList get txList => $_getN(13);
  @$pb.TagNumber(23)
  set txList($11.ReqTxList value) => $_setField(23, value);
  @$pb.TagNumber(23)
  $core.bool hasTxList() => $_has(13);
  @$pb.TagNumber(23)
  void clearTxList() => $_clearField(23);
  @$pb.TagNumber(23)
  $11.ReqTxList ensureTxList() => $_ensure(13);

  @$pb.TagNumber(24)
  $1.ReqConsumptionPut get consumptionPut => $_getN(14);
  @$pb.TagNumber(24)
  set consumptionPut($1.ReqConsumptionPut value) => $_setField(24, value);
  @$pb.TagNumber(24)
  $core.bool hasConsumptionPut() => $_has(14);
  @$pb.TagNumber(24)
  void clearConsumptionPut() => $_clearField(24);
  @$pb.TagNumber(24)
  $1.ReqConsumptionPut ensureConsumptionPut() => $_ensure(14);

  @$pb.TagNumber(25)
  $8.ReqChatPatch get chatPatch => $_getN(15);
  @$pb.TagNumber(25)
  set chatPatch($8.ReqChatPatch value) => $_setField(25, value);
  @$pb.TagNumber(25)
  $core.bool hasChatPatch() => $_has(15);
  @$pb.TagNumber(25)
  void clearChatPatch() => $_clearField(25);
  @$pb.TagNumber(25)
  $8.ReqChatPatch ensureChatPatch() => $_ensure(15);

  @$pb.TagNumber(26)
  $8.ReqAssetTagList get assetTagList => $_getN(16);
  @$pb.TagNumber(26)
  set assetTagList($8.ReqAssetTagList value) => $_setField(26, value);
  @$pb.TagNumber(26)
  $core.bool hasAssetTagList() => $_has(16);
  @$pb.TagNumber(26)
  void clearAssetTagList() => $_clearField(26);
  @$pb.TagNumber(26)
  $8.ReqAssetTagList ensureAssetTagList() => $_ensure(16);

  @$pb.TagNumber(27)
  $12.ReqIdentityList get identityList => $_getN(17);
  @$pb.TagNumber(27)
  set identityList($12.ReqIdentityList value) => $_setField(27, value);
  @$pb.TagNumber(27)
  $core.bool hasIdentityList() => $_has(17);
  @$pb.TagNumber(27)
  void clearIdentityList() => $_clearField(27);
  @$pb.TagNumber(27)
  $12.ReqIdentityList ensureIdentityList() => $_ensure(17);

  @$pb.TagNumber(28)
  $12.ReqIdentityGrantPatch get identityGrantPatch => $_getN(18);
  @$pb.TagNumber(28)
  set identityGrantPatch($12.ReqIdentityGrantPatch value) =>
      $_setField(28, value);
  @$pb.TagNumber(28)
  $core.bool hasIdentityGrantPatch() => $_has(18);
  @$pb.TagNumber(28)
  void clearIdentityGrantPatch() => $_clearField(28);
  @$pb.TagNumber(28)
  $12.ReqIdentityGrantPatch ensureIdentityGrantPatch() => $_ensure(18);

  @$pb.TagNumber(29)
  $8.ReqBotPeerList get botPeerList => $_getN(19);
  @$pb.TagNumber(29)
  set botPeerList($8.ReqBotPeerList value) => $_setField(29, value);
  @$pb.TagNumber(29)
  $core.bool hasBotPeerList() => $_has(19);
  @$pb.TagNumber(29)
  void clearBotPeerList() => $_clearField(29);
  @$pb.TagNumber(29)
  $8.ReqBotPeerList ensureBotPeerList() => $_ensure(19);

  @$pb.TagNumber(30)
  $8.ReqLogList get logList => $_getN(20);
  @$pb.TagNumber(30)
  set logList($8.ReqLogList value) => $_setField(30, value);
  @$pb.TagNumber(30)
  $core.bool hasLogList() => $_has(20);
  @$pb.TagNumber(30)
  void clearLogList() => $_clearField(30);
  @$pb.TagNumber(30)
  $8.ReqLogList ensureLogList() => $_ensure(20);

  @$pb.TagNumber(31)
  $12.ReqIdentityPut get identityPut => $_getN(21);
  @$pb.TagNumber(31)
  set identityPut($12.ReqIdentityPut value) => $_setField(31, value);
  @$pb.TagNumber(31)
  $core.bool hasIdentityPut() => $_has(21);
  @$pb.TagNumber(31)
  void clearIdentityPut() => $_clearField(31);
  @$pb.TagNumber(31)
  $12.ReqIdentityPut ensureIdentityPut() => $_ensure(21);

  @$pb.TagNumber(32)
  $4.ReqChannelWhatsappPairStart get channelWhatsappPairStart => $_getN(22);
  @$pb.TagNumber(32)
  set channelWhatsappPairStart($4.ReqChannelWhatsappPairStart value) =>
      $_setField(32, value);
  @$pb.TagNumber(32)
  $core.bool hasChannelWhatsappPairStart() => $_has(22);
  @$pb.TagNumber(32)
  void clearChannelWhatsappPairStart() => $_clearField(32);
  @$pb.TagNumber(32)
  $4.ReqChannelWhatsappPairStart ensureChannelWhatsappPairStart() =>
      $_ensure(22);

  @$pb.TagNumber(33)
  $4.ReqChannelWhatsappPairWatch get channelWhatsappPairWatch => $_getN(23);
  @$pb.TagNumber(33)
  set channelWhatsappPairWatch($4.ReqChannelWhatsappPairWatch value) =>
      $_setField(33, value);
  @$pb.TagNumber(33)
  $core.bool hasChannelWhatsappPairWatch() => $_has(23);
  @$pb.TagNumber(33)
  void clearChannelWhatsappPairWatch() => $_clearField(33);
  @$pb.TagNumber(33)
  $4.ReqChannelWhatsappPairWatch ensureChannelWhatsappPairWatch() =>
      $_ensure(23);

  @$pb.TagNumber(34)
  $4.ReqChannelWhatsappPairAbort get channelWhatsappPairAbort => $_getN(24);
  @$pb.TagNumber(34)
  set channelWhatsappPairAbort($4.ReqChannelWhatsappPairAbort value) =>
      $_setField(34, value);
  @$pb.TagNumber(34)
  $core.bool hasChannelWhatsappPairAbort() => $_has(24);
  @$pb.TagNumber(34)
  void clearChannelWhatsappPairAbort() => $_clearField(34);
  @$pb.TagNumber(34)
  $4.ReqChannelWhatsappPairAbort ensureChannelWhatsappPairAbort() =>
      $_ensure(24);
}

enum WsRes_Body {
  err,
  sessionInit,
  sync,
  inboxList,
  chatMsgList,
  promptStart,
  promptDelta,
  promptEnd,
  promptFail,
  identityList,
  identityGrantPatch,
  botPeerList,
  chatStop,
  chatSend,
  channelWhatsappPairStart,
  channelWhatsappPairWatch,
  channelWhatsappPairAbort,
  invoke,
  syncPush,
  billingBalance,
  billingQuota,
  billingCommission,
  logPush,
  channelPairPush,
  skillList,
  consumptionList,
  siteList,
  txList,
  consumptionPut,
  chatPatch,
  assetTagList,
  logList,
  identityPut,
  notSet
}

/// WebSocket server → client
class WsRes extends $pb.GeneratedMessage {
  factory WsRes({
    $core.String? reqId,
    $13.Err? err,
    $6.ResSessionInit? sessionInit,
    $7.ResSync? sync,
    $8.ResInboxList? inboxList,
    $8.ResChatMsgList? chatMsgList,
    $8.ResPromptStart? promptStart,
    $8.ResPromptDelta? promptDelta,
    $8.ResPromptEnd? promptEnd,
    $8.ResPromptFail? promptFail,
    $12.ResIdentityList? identityList,
    $12.ResIdentityGrantPatch? identityGrantPatch,
    $8.ResBotPeerList? botPeerList,
    $8.ResChatStop? chatStop,
    $8.ResChatSend? chatSend,
    $4.ResChannelWhatsappPair? channelWhatsappPairStart,
    $4.ResChannelWhatsappPair? channelWhatsappPairWatch,
    $4.ResChannelWhatsappPair? channelWhatsappPairAbort,
    InvokeRes? invoke,
    $7.SyncPush? syncPush,
    $0.BillingPushBalance? billingBalance,
    $0.BillingPushQuota? billingQuota,
    $0.BillingPushCommission? billingCommission,
    $14.LogPush? logPush,
    $4.ChannelPairPush? channelPairPush,
    $9.ResSkillList? skillList,
    $1.ResConsumptionList? consumptionList,
    $10.ResSiteList? siteList,
    $11.ResTxList? txList,
    $1.ResConsumptionPut? consumptionPut,
    $8.ResChatPatch? chatPatch,
    $8.ResAssetTagList? assetTagList,
    $8.ResLogList? logList,
    $12.ResIdentityPut? identityPut,
  }) {
    final result = WsRes._();
    if (reqId != null) result.reqId = reqId;
    if (err != null) result.err = err;
    if (sessionInit != null) result.sessionInit = sessionInit;
    if (sync != null) result.sync = sync;
    if (inboxList != null) result.inboxList = inboxList;
    if (chatMsgList != null) result.chatMsgList = chatMsgList;
    if (promptStart != null) result.promptStart = promptStart;
    if (promptDelta != null) result.promptDelta = promptDelta;
    if (promptEnd != null) result.promptEnd = promptEnd;
    if (promptFail != null) result.promptFail = promptFail;
    if (identityList != null) result.identityList = identityList;
    if (identityGrantPatch != null)
      result.identityGrantPatch = identityGrantPatch;
    if (botPeerList != null) result.botPeerList = botPeerList;
    if (chatStop != null) result.chatStop = chatStop;
    if (chatSend != null) result.chatSend = chatSend;
    if (channelWhatsappPairStart != null)
      result.channelWhatsappPairStart = channelWhatsappPairStart;
    if (channelWhatsappPairWatch != null)
      result.channelWhatsappPairWatch = channelWhatsappPairWatch;
    if (channelWhatsappPairAbort != null)
      result.channelWhatsappPairAbort = channelWhatsappPairAbort;
    if (invoke != null) result.invoke = invoke;
    if (syncPush != null) result.syncPush = syncPush;
    if (billingBalance != null) result.billingBalance = billingBalance;
    if (billingQuota != null) result.billingQuota = billingQuota;
    if (billingCommission != null) result.billingCommission = billingCommission;
    if (logPush != null) result.logPush = logPush;
    if (channelPairPush != null) result.channelPairPush = channelPairPush;
    if (skillList != null) result.skillList = skillList;
    if (consumptionList != null) result.consumptionList = consumptionList;
    if (siteList != null) result.siteList = siteList;
    if (txList != null) result.txList = txList;
    if (consumptionPut != null) result.consumptionPut = consumptionPut;
    if (chatPatch != null) result.chatPatch = chatPatch;
    if (assetTagList != null) result.assetTagList = assetTagList;
    if (logList != null) result.logList = logList;
    if (identityPut != null) result.identityPut = identityPut;
    return result;
  }

  WsRes._();

  factory WsRes.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      WsRes()..mergeFromBuffer(data, registry);
  factory WsRes.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      WsRes()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, WsRes_Body> _WsRes_BodyByTag = {
    2: WsRes_Body.err,
    10: WsRes_Body.sessionInit,
    11: WsRes_Body.sync,
    12: WsRes_Body.inboxList,
    13: WsRes_Body.chatMsgList,
    20: WsRes_Body.promptStart,
    21: WsRes_Body.promptDelta,
    22: WsRes_Body.promptEnd,
    23: WsRes_Body.promptFail,
    27: WsRes_Body.identityList,
    28: WsRes_Body.identityGrantPatch,
    29: WsRes_Body.botPeerList,
    30: WsRes_Body.chatStop,
    31: WsRes_Body.chatSend,
    32: WsRes_Body.channelWhatsappPairStart,
    33: WsRes_Body.channelWhatsappPairWatch,
    34: WsRes_Body.channelWhatsappPairAbort,
    40: WsRes_Body.invoke,
    50: WsRes_Body.syncPush,
    60: WsRes_Body.billingBalance,
    61: WsRes_Body.billingQuota,
    62: WsRes_Body.billingCommission,
    70: WsRes_Body.logPush,
    71: WsRes_Body.channelPairPush,
    80: WsRes_Body.skillList,
    81: WsRes_Body.consumptionList,
    82: WsRes_Body.siteList,
    83: WsRes_Body.txList,
    84: WsRes_Body.consumptionPut,
    85: WsRes_Body.chatPatch,
    86: WsRes_Body.assetTagList,
    87: WsRes_Body.logList,
    88: WsRes_Body.identityPut,
    0: WsRes_Body.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WsRes',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: WsRes.$_createMessage)
    ..oo(0, [
      2,
      10,
      11,
      12,
      13,
      20,
      21,
      22,
      23,
      27,
      28,
      29,
      30,
      31,
      32,
      33,
      34,
      40,
      50,
      60,
      61,
      62,
      70,
      71,
      80,
      81,
      82,
      83,
      84,
      85,
      86,
      87,
      88
    ])
    ..aOS(1, _omitFieldNames ? '' : 'reqId')
    ..aOM<$13.Err>(2, _omitFieldNames ? '' : 'err',
        subBuilder: $13.Err.$_createMessage)
    ..aOM<$6.ResSessionInit>(10, _omitFieldNames ? '' : 'sessionInit',
        subBuilder: $6.ResSessionInit.$_createMessage)
    ..aOM<$7.ResSync>(11, _omitFieldNames ? '' : 'sync',
        subBuilder: $7.ResSync.$_createMessage)
    ..aOM<$8.ResInboxList>(12, _omitFieldNames ? '' : 'inboxList',
        subBuilder: $8.ResInboxList.$_createMessage)
    ..aOM<$8.ResChatMsgList>(13, _omitFieldNames ? '' : 'chatMsgList',
        subBuilder: $8.ResChatMsgList.$_createMessage)
    ..aOM<$8.ResPromptStart>(20, _omitFieldNames ? '' : 'promptStart',
        subBuilder: $8.ResPromptStart.$_createMessage)
    ..aOM<$8.ResPromptDelta>(21, _omitFieldNames ? '' : 'promptDelta',
        subBuilder: $8.ResPromptDelta.$_createMessage)
    ..aOM<$8.ResPromptEnd>(22, _omitFieldNames ? '' : 'promptEnd',
        subBuilder: $8.ResPromptEnd.$_createMessage)
    ..aOM<$8.ResPromptFail>(23, _omitFieldNames ? '' : 'promptFail',
        subBuilder: $8.ResPromptFail.$_createMessage)
    ..aOM<$12.ResIdentityList>(27, _omitFieldNames ? '' : 'identityList',
        subBuilder: $12.ResIdentityList.$_createMessage)
    ..aOM<$12.ResIdentityGrantPatch>(
        28, _omitFieldNames ? '' : 'identityGrantPatch',
        subBuilder: $12.ResIdentityGrantPatch.$_createMessage)
    ..aOM<$8.ResBotPeerList>(29, _omitFieldNames ? '' : 'botPeerList',
        subBuilder: $8.ResBotPeerList.$_createMessage)
    ..aOM<$8.ResChatStop>(30, _omitFieldNames ? '' : 'chatStop',
        subBuilder: $8.ResChatStop.$_createMessage)
    ..aOM<$8.ResChatSend>(31, _omitFieldNames ? '' : 'chatSend',
        subBuilder: $8.ResChatSend.$_createMessage)
    ..aOM<$4.ResChannelWhatsappPair>(
        32, _omitFieldNames ? '' : 'channelWhatsappPairStart',
        subBuilder: $4.ResChannelWhatsappPair.$_createMessage)
    ..aOM<$4.ResChannelWhatsappPair>(
        33, _omitFieldNames ? '' : 'channelWhatsappPairWatch',
        subBuilder: $4.ResChannelWhatsappPair.$_createMessage)
    ..aOM<$4.ResChannelWhatsappPair>(
        34, _omitFieldNames ? '' : 'channelWhatsappPairAbort',
        subBuilder: $4.ResChannelWhatsappPair.$_createMessage)
    ..aOM<InvokeRes>(40, _omitFieldNames ? '' : 'invoke',
        subBuilder: InvokeRes.$_createMessage)
    ..aOM<$7.SyncPush>(50, _omitFieldNames ? '' : 'syncPush',
        subBuilder: $7.SyncPush.$_createMessage)
    ..aOM<$0.BillingPushBalance>(60, _omitFieldNames ? '' : 'billingBalance',
        subBuilder: $0.BillingPushBalance.$_createMessage)
    ..aOM<$0.BillingPushQuota>(61, _omitFieldNames ? '' : 'billingQuota',
        subBuilder: $0.BillingPushQuota.$_createMessage)
    ..aOM<$0.BillingPushCommission>(
        62, _omitFieldNames ? '' : 'billingCommission',
        subBuilder: $0.BillingPushCommission.$_createMessage)
    ..aOM<$14.LogPush>(70, _omitFieldNames ? '' : 'logPush',
        subBuilder: $14.LogPush.$_createMessage)
    ..aOM<$4.ChannelPairPush>(71, _omitFieldNames ? '' : 'channelPairPush',
        subBuilder: $4.ChannelPairPush.$_createMessage)
    ..aOM<$9.ResSkillList>(80, _omitFieldNames ? '' : 'skillList',
        subBuilder: $9.ResSkillList.$_createMessage)
    ..aOM<$1.ResConsumptionList>(81, _omitFieldNames ? '' : 'consumptionList',
        subBuilder: $1.ResConsumptionList.$_createMessage)
    ..aOM<$10.ResSiteList>(82, _omitFieldNames ? '' : 'siteList',
        subBuilder: $10.ResSiteList.$_createMessage)
    ..aOM<$11.ResTxList>(83, _omitFieldNames ? '' : 'txList',
        subBuilder: $11.ResTxList.$_createMessage)
    ..aOM<$1.ResConsumptionPut>(84, _omitFieldNames ? '' : 'consumptionPut',
        subBuilder: $1.ResConsumptionPut.$_createMessage)
    ..aOM<$8.ResChatPatch>(85, _omitFieldNames ? '' : 'chatPatch',
        subBuilder: $8.ResChatPatch.$_createMessage)
    ..aOM<$8.ResAssetTagList>(86, _omitFieldNames ? '' : 'assetTagList',
        subBuilder: $8.ResAssetTagList.$_createMessage)
    ..aOM<$8.ResLogList>(87, _omitFieldNames ? '' : 'logList',
        subBuilder: $8.ResLogList.$_createMessage)
    ..aOM<$12.ResIdentityPut>(88, _omitFieldNames ? '' : 'identityPut',
        subBuilder: $12.ResIdentityPut.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WsRes clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WsRes copyWith(void Function(WsRes) updates) =>
      super.copyWith((message) => updates(message as WsRes)) as WsRes;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use WsRes() / WsRes.new instead')
  static WsRes create() => WsRes._();
  static $pb.GeneratedMessage $_createMessage() => WsRes._();
  @$core.override
  WsRes createEmptyInstance() => WsRes._();
  @$core.pragma('dart2js:noInline')
  static WsRes getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WsRes>(WsRes.$_createMessage);
  static WsRes? _defaultInstance;

  @$pb.TagNumber(2)
  @$pb.TagNumber(10)
  @$pb.TagNumber(11)
  @$pb.TagNumber(12)
  @$pb.TagNumber(13)
  @$pb.TagNumber(20)
  @$pb.TagNumber(21)
  @$pb.TagNumber(22)
  @$pb.TagNumber(23)
  @$pb.TagNumber(27)
  @$pb.TagNumber(28)
  @$pb.TagNumber(29)
  @$pb.TagNumber(30)
  @$pb.TagNumber(31)
  @$pb.TagNumber(32)
  @$pb.TagNumber(33)
  @$pb.TagNumber(34)
  @$pb.TagNumber(40)
  @$pb.TagNumber(50)
  @$pb.TagNumber(60)
  @$pb.TagNumber(61)
  @$pb.TagNumber(62)
  @$pb.TagNumber(70)
  @$pb.TagNumber(71)
  @$pb.TagNumber(80)
  @$pb.TagNumber(81)
  @$pb.TagNumber(82)
  @$pb.TagNumber(83)
  @$pb.TagNumber(84)
  @$pb.TagNumber(85)
  @$pb.TagNumber(86)
  @$pb.TagNumber(87)
  @$pb.TagNumber(88)
  WsRes_Body whichBody() => _WsRes_BodyByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(2)
  @$pb.TagNumber(10)
  @$pb.TagNumber(11)
  @$pb.TagNumber(12)
  @$pb.TagNumber(13)
  @$pb.TagNumber(20)
  @$pb.TagNumber(21)
  @$pb.TagNumber(22)
  @$pb.TagNumber(23)
  @$pb.TagNumber(27)
  @$pb.TagNumber(28)
  @$pb.TagNumber(29)
  @$pb.TagNumber(30)
  @$pb.TagNumber(31)
  @$pb.TagNumber(32)
  @$pb.TagNumber(33)
  @$pb.TagNumber(34)
  @$pb.TagNumber(40)
  @$pb.TagNumber(50)
  @$pb.TagNumber(60)
  @$pb.TagNumber(61)
  @$pb.TagNumber(62)
  @$pb.TagNumber(70)
  @$pb.TagNumber(71)
  @$pb.TagNumber(80)
  @$pb.TagNumber(81)
  @$pb.TagNumber(82)
  @$pb.TagNumber(83)
  @$pb.TagNumber(84)
  @$pb.TagNumber(85)
  @$pb.TagNumber(86)
  @$pb.TagNumber(87)
  @$pb.TagNumber(88)
  void clearBody() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get reqId => $_getSZ(0);
  @$pb.TagNumber(1)
  set reqId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasReqId() => $_has(0);
  @$pb.TagNumber(1)
  void clearReqId() => $_clearField(1);

  @$pb.TagNumber(2)
  $13.Err get err => $_getN(1);
  @$pb.TagNumber(2)
  set err($13.Err value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasErr() => $_has(1);
  @$pb.TagNumber(2)
  void clearErr() => $_clearField(2);
  @$pb.TagNumber(2)
  $13.Err ensureErr() => $_ensure(1);

  @$pb.TagNumber(10)
  $6.ResSessionInit get sessionInit => $_getN(2);
  @$pb.TagNumber(10)
  set sessionInit($6.ResSessionInit value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasSessionInit() => $_has(2);
  @$pb.TagNumber(10)
  void clearSessionInit() => $_clearField(10);
  @$pb.TagNumber(10)
  $6.ResSessionInit ensureSessionInit() => $_ensure(2);

  @$pb.TagNumber(11)
  $7.ResSync get sync => $_getN(3);
  @$pb.TagNumber(11)
  set sync($7.ResSync value) => $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasSync() => $_has(3);
  @$pb.TagNumber(11)
  void clearSync() => $_clearField(11);
  @$pb.TagNumber(11)
  $7.ResSync ensureSync() => $_ensure(3);

  @$pb.TagNumber(12)
  $8.ResInboxList get inboxList => $_getN(4);
  @$pb.TagNumber(12)
  set inboxList($8.ResInboxList value) => $_setField(12, value);
  @$pb.TagNumber(12)
  $core.bool hasInboxList() => $_has(4);
  @$pb.TagNumber(12)
  void clearInboxList() => $_clearField(12);
  @$pb.TagNumber(12)
  $8.ResInboxList ensureInboxList() => $_ensure(4);

  @$pb.TagNumber(13)
  $8.ResChatMsgList get chatMsgList => $_getN(5);
  @$pb.TagNumber(13)
  set chatMsgList($8.ResChatMsgList value) => $_setField(13, value);
  @$pb.TagNumber(13)
  $core.bool hasChatMsgList() => $_has(5);
  @$pb.TagNumber(13)
  void clearChatMsgList() => $_clearField(13);
  @$pb.TagNumber(13)
  $8.ResChatMsgList ensureChatMsgList() => $_ensure(5);

  @$pb.TagNumber(20)
  $8.ResPromptStart get promptStart => $_getN(6);
  @$pb.TagNumber(20)
  set promptStart($8.ResPromptStart value) => $_setField(20, value);
  @$pb.TagNumber(20)
  $core.bool hasPromptStart() => $_has(6);
  @$pb.TagNumber(20)
  void clearPromptStart() => $_clearField(20);
  @$pb.TagNumber(20)
  $8.ResPromptStart ensurePromptStart() => $_ensure(6);

  @$pb.TagNumber(21)
  $8.ResPromptDelta get promptDelta => $_getN(7);
  @$pb.TagNumber(21)
  set promptDelta($8.ResPromptDelta value) => $_setField(21, value);
  @$pb.TagNumber(21)
  $core.bool hasPromptDelta() => $_has(7);
  @$pb.TagNumber(21)
  void clearPromptDelta() => $_clearField(21);
  @$pb.TagNumber(21)
  $8.ResPromptDelta ensurePromptDelta() => $_ensure(7);

  @$pb.TagNumber(22)
  $8.ResPromptEnd get promptEnd => $_getN(8);
  @$pb.TagNumber(22)
  set promptEnd($8.ResPromptEnd value) => $_setField(22, value);
  @$pb.TagNumber(22)
  $core.bool hasPromptEnd() => $_has(8);
  @$pb.TagNumber(22)
  void clearPromptEnd() => $_clearField(22);
  @$pb.TagNumber(22)
  $8.ResPromptEnd ensurePromptEnd() => $_ensure(8);

  @$pb.TagNumber(23)
  $8.ResPromptFail get promptFail => $_getN(9);
  @$pb.TagNumber(23)
  set promptFail($8.ResPromptFail value) => $_setField(23, value);
  @$pb.TagNumber(23)
  $core.bool hasPromptFail() => $_has(9);
  @$pb.TagNumber(23)
  void clearPromptFail() => $_clearField(23);
  @$pb.TagNumber(23)
  $8.ResPromptFail ensurePromptFail() => $_ensure(9);

  @$pb.TagNumber(27)
  $12.ResIdentityList get identityList => $_getN(10);
  @$pb.TagNumber(27)
  set identityList($12.ResIdentityList value) => $_setField(27, value);
  @$pb.TagNumber(27)
  $core.bool hasIdentityList() => $_has(10);
  @$pb.TagNumber(27)
  void clearIdentityList() => $_clearField(27);
  @$pb.TagNumber(27)
  $12.ResIdentityList ensureIdentityList() => $_ensure(10);

  @$pb.TagNumber(28)
  $12.ResIdentityGrantPatch get identityGrantPatch => $_getN(11);
  @$pb.TagNumber(28)
  set identityGrantPatch($12.ResIdentityGrantPatch value) =>
      $_setField(28, value);
  @$pb.TagNumber(28)
  $core.bool hasIdentityGrantPatch() => $_has(11);
  @$pb.TagNumber(28)
  void clearIdentityGrantPatch() => $_clearField(28);
  @$pb.TagNumber(28)
  $12.ResIdentityGrantPatch ensureIdentityGrantPatch() => $_ensure(11);

  @$pb.TagNumber(29)
  $8.ResBotPeerList get botPeerList => $_getN(12);
  @$pb.TagNumber(29)
  set botPeerList($8.ResBotPeerList value) => $_setField(29, value);
  @$pb.TagNumber(29)
  $core.bool hasBotPeerList() => $_has(12);
  @$pb.TagNumber(29)
  void clearBotPeerList() => $_clearField(29);
  @$pb.TagNumber(29)
  $8.ResBotPeerList ensureBotPeerList() => $_ensure(12);

  @$pb.TagNumber(30)
  $8.ResChatStop get chatStop => $_getN(13);
  @$pb.TagNumber(30)
  set chatStop($8.ResChatStop value) => $_setField(30, value);
  @$pb.TagNumber(30)
  $core.bool hasChatStop() => $_has(13);
  @$pb.TagNumber(30)
  void clearChatStop() => $_clearField(30);
  @$pb.TagNumber(30)
  $8.ResChatStop ensureChatStop() => $_ensure(13);

  @$pb.TagNumber(31)
  $8.ResChatSend get chatSend => $_getN(14);
  @$pb.TagNumber(31)
  set chatSend($8.ResChatSend value) => $_setField(31, value);
  @$pb.TagNumber(31)
  $core.bool hasChatSend() => $_has(14);
  @$pb.TagNumber(31)
  void clearChatSend() => $_clearField(31);
  @$pb.TagNumber(31)
  $8.ResChatSend ensureChatSend() => $_ensure(14);

  @$pb.TagNumber(32)
  $4.ResChannelWhatsappPair get channelWhatsappPairStart => $_getN(15);
  @$pb.TagNumber(32)
  set channelWhatsappPairStart($4.ResChannelWhatsappPair value) =>
      $_setField(32, value);
  @$pb.TagNumber(32)
  $core.bool hasChannelWhatsappPairStart() => $_has(15);
  @$pb.TagNumber(32)
  void clearChannelWhatsappPairStart() => $_clearField(32);
  @$pb.TagNumber(32)
  $4.ResChannelWhatsappPair ensureChannelWhatsappPairStart() => $_ensure(15);

  @$pb.TagNumber(33)
  $4.ResChannelWhatsappPair get channelWhatsappPairWatch => $_getN(16);
  @$pb.TagNumber(33)
  set channelWhatsappPairWatch($4.ResChannelWhatsappPair value) =>
      $_setField(33, value);
  @$pb.TagNumber(33)
  $core.bool hasChannelWhatsappPairWatch() => $_has(16);
  @$pb.TagNumber(33)
  void clearChannelWhatsappPairWatch() => $_clearField(33);
  @$pb.TagNumber(33)
  $4.ResChannelWhatsappPair ensureChannelWhatsappPairWatch() => $_ensure(16);

  @$pb.TagNumber(34)
  $4.ResChannelWhatsappPair get channelWhatsappPairAbort => $_getN(17);
  @$pb.TagNumber(34)
  set channelWhatsappPairAbort($4.ResChannelWhatsappPair value) =>
      $_setField(34, value);
  @$pb.TagNumber(34)
  $core.bool hasChannelWhatsappPairAbort() => $_has(17);
  @$pb.TagNumber(34)
  void clearChannelWhatsappPairAbort() => $_clearField(34);
  @$pb.TagNumber(34)
  $4.ResChannelWhatsappPair ensureChannelWhatsappPairAbort() => $_ensure(17);

  @$pb.TagNumber(40)
  InvokeRes get invoke => $_getN(18);
  @$pb.TagNumber(40)
  set invoke(InvokeRes value) => $_setField(40, value);
  @$pb.TagNumber(40)
  $core.bool hasInvoke() => $_has(18);
  @$pb.TagNumber(40)
  void clearInvoke() => $_clearField(40);
  @$pb.TagNumber(40)
  InvokeRes ensureInvoke() => $_ensure(18);

  @$pb.TagNumber(50)
  $7.SyncPush get syncPush => $_getN(19);
  @$pb.TagNumber(50)
  set syncPush($7.SyncPush value) => $_setField(50, value);
  @$pb.TagNumber(50)
  $core.bool hasSyncPush() => $_has(19);
  @$pb.TagNumber(50)
  void clearSyncPush() => $_clearField(50);
  @$pb.TagNumber(50)
  $7.SyncPush ensureSyncPush() => $_ensure(19);

  @$pb.TagNumber(60)
  $0.BillingPushBalance get billingBalance => $_getN(20);
  @$pb.TagNumber(60)
  set billingBalance($0.BillingPushBalance value) => $_setField(60, value);
  @$pb.TagNumber(60)
  $core.bool hasBillingBalance() => $_has(20);
  @$pb.TagNumber(60)
  void clearBillingBalance() => $_clearField(60);
  @$pb.TagNumber(60)
  $0.BillingPushBalance ensureBillingBalance() => $_ensure(20);

  @$pb.TagNumber(61)
  $0.BillingPushQuota get billingQuota => $_getN(21);
  @$pb.TagNumber(61)
  set billingQuota($0.BillingPushQuota value) => $_setField(61, value);
  @$pb.TagNumber(61)
  $core.bool hasBillingQuota() => $_has(21);
  @$pb.TagNumber(61)
  void clearBillingQuota() => $_clearField(61);
  @$pb.TagNumber(61)
  $0.BillingPushQuota ensureBillingQuota() => $_ensure(21);

  @$pb.TagNumber(62)
  $0.BillingPushCommission get billingCommission => $_getN(22);
  @$pb.TagNumber(62)
  set billingCommission($0.BillingPushCommission value) =>
      $_setField(62, value);
  @$pb.TagNumber(62)
  $core.bool hasBillingCommission() => $_has(22);
  @$pb.TagNumber(62)
  void clearBillingCommission() => $_clearField(62);
  @$pb.TagNumber(62)
  $0.BillingPushCommission ensureBillingCommission() => $_ensure(22);

  @$pb.TagNumber(70)
  $14.LogPush get logPush => $_getN(23);
  @$pb.TagNumber(70)
  set logPush($14.LogPush value) => $_setField(70, value);
  @$pb.TagNumber(70)
  $core.bool hasLogPush() => $_has(23);
  @$pb.TagNumber(70)
  void clearLogPush() => $_clearField(70);
  @$pb.TagNumber(70)
  $14.LogPush ensureLogPush() => $_ensure(23);

  @$pb.TagNumber(71)
  $4.ChannelPairPush get channelPairPush => $_getN(24);
  @$pb.TagNumber(71)
  set channelPairPush($4.ChannelPairPush value) => $_setField(71, value);
  @$pb.TagNumber(71)
  $core.bool hasChannelPairPush() => $_has(24);
  @$pb.TagNumber(71)
  void clearChannelPairPush() => $_clearField(71);
  @$pb.TagNumber(71)
  $4.ChannelPairPush ensureChannelPairPush() => $_ensure(24);

  @$pb.TagNumber(80)
  $9.ResSkillList get skillList => $_getN(25);
  @$pb.TagNumber(80)
  set skillList($9.ResSkillList value) => $_setField(80, value);
  @$pb.TagNumber(80)
  $core.bool hasSkillList() => $_has(25);
  @$pb.TagNumber(80)
  void clearSkillList() => $_clearField(80);
  @$pb.TagNumber(80)
  $9.ResSkillList ensureSkillList() => $_ensure(25);

  @$pb.TagNumber(81)
  $1.ResConsumptionList get consumptionList => $_getN(26);
  @$pb.TagNumber(81)
  set consumptionList($1.ResConsumptionList value) => $_setField(81, value);
  @$pb.TagNumber(81)
  $core.bool hasConsumptionList() => $_has(26);
  @$pb.TagNumber(81)
  void clearConsumptionList() => $_clearField(81);
  @$pb.TagNumber(81)
  $1.ResConsumptionList ensureConsumptionList() => $_ensure(26);

  @$pb.TagNumber(82)
  $10.ResSiteList get siteList => $_getN(27);
  @$pb.TagNumber(82)
  set siteList($10.ResSiteList value) => $_setField(82, value);
  @$pb.TagNumber(82)
  $core.bool hasSiteList() => $_has(27);
  @$pb.TagNumber(82)
  void clearSiteList() => $_clearField(82);
  @$pb.TagNumber(82)
  $10.ResSiteList ensureSiteList() => $_ensure(27);

  @$pb.TagNumber(83)
  $11.ResTxList get txList => $_getN(28);
  @$pb.TagNumber(83)
  set txList($11.ResTxList value) => $_setField(83, value);
  @$pb.TagNumber(83)
  $core.bool hasTxList() => $_has(28);
  @$pb.TagNumber(83)
  void clearTxList() => $_clearField(83);
  @$pb.TagNumber(83)
  $11.ResTxList ensureTxList() => $_ensure(28);

  @$pb.TagNumber(84)
  $1.ResConsumptionPut get consumptionPut => $_getN(29);
  @$pb.TagNumber(84)
  set consumptionPut($1.ResConsumptionPut value) => $_setField(84, value);
  @$pb.TagNumber(84)
  $core.bool hasConsumptionPut() => $_has(29);
  @$pb.TagNumber(84)
  void clearConsumptionPut() => $_clearField(84);
  @$pb.TagNumber(84)
  $1.ResConsumptionPut ensureConsumptionPut() => $_ensure(29);

  @$pb.TagNumber(85)
  $8.ResChatPatch get chatPatch => $_getN(30);
  @$pb.TagNumber(85)
  set chatPatch($8.ResChatPatch value) => $_setField(85, value);
  @$pb.TagNumber(85)
  $core.bool hasChatPatch() => $_has(30);
  @$pb.TagNumber(85)
  void clearChatPatch() => $_clearField(85);
  @$pb.TagNumber(85)
  $8.ResChatPatch ensureChatPatch() => $_ensure(30);

  @$pb.TagNumber(86)
  $8.ResAssetTagList get assetTagList => $_getN(31);
  @$pb.TagNumber(86)
  set assetTagList($8.ResAssetTagList value) => $_setField(86, value);
  @$pb.TagNumber(86)
  $core.bool hasAssetTagList() => $_has(31);
  @$pb.TagNumber(86)
  void clearAssetTagList() => $_clearField(86);
  @$pb.TagNumber(86)
  $8.ResAssetTagList ensureAssetTagList() => $_ensure(31);

  @$pb.TagNumber(87)
  $8.ResLogList get logList => $_getN(32);
  @$pb.TagNumber(87)
  set logList($8.ResLogList value) => $_setField(87, value);
  @$pb.TagNumber(87)
  $core.bool hasLogList() => $_has(32);
  @$pb.TagNumber(87)
  void clearLogList() => $_clearField(87);
  @$pb.TagNumber(87)
  $8.ResLogList ensureLogList() => $_ensure(32);

  @$pb.TagNumber(88)
  $12.ResIdentityPut get identityPut => $_getN(33);
  @$pb.TagNumber(88)
  set identityPut($12.ResIdentityPut value) => $_setField(88, value);
  @$pb.TagNumber(88)
  $core.bool hasIdentityPut() => $_has(33);
  @$pb.TagNumber(88)
  void clearIdentityPut() => $_clearField(88);
  @$pb.TagNumber(88)
  $12.ResIdentityPut ensureIdentityPut() => $_ensure(33);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
