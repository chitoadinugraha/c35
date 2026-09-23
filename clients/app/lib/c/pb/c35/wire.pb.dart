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
import 'catalog.pb.dart' as $8;
import 'channel.pb.dart' as $4;
import 'chat.pb.dart' as $11;
import 'collection.pb.dart' as $18;
import 'consumption.pb.dart' as $1;
import 'device.pb.dart' as $5;
import 'hint.pb.dart' as $20;
import 'identity.pb.dart' as $15;
import 'inst.pb.dart' as $6;
import 'log.pb.dart' as $22;
import 'referral.pb.dart' as $2;
import 'remote.pb.dart' as $17;
import 'session.pb.dart' as $9;
import 'site.pb.dart' as $13;
import 'skill.pb.dart' as $12;
import 'stats.pb.dart' as $19;
import 'sync.pb.dart' as $10;
import 'task.pb.dart' as $16;
import 'tx.pb.dart' as $14;
import 'types.pb.dart' as $21;
import 'voice.pb.dart' as $7;

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
  billingPromotionCreate,
  billingPromotionClaim,
  billingPromotionList,
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
  instList,
  instGet,
  instPut,
  instDelete,
  voiceStt,
  voiceTts,
  adminLogList,
  translationPut,
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
    $0.ReqBillingPromotionCreate? billingPromotionCreate,
    $0.ReqBillingPromotionClaim? billingPromotionClaim,
    $0.ReqBillingPromotionList? billingPromotionList,
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
    $6.ReqInstList? instList,
    $6.ReqInstGet? instGet,
    $6.ReqInstPut? instPut,
    $6.ReqInstDelete? instDelete,
    $7.ReqVoiceStt? voiceStt,
    $7.ReqVoiceTts? voiceTts,
    $3.ReqAdminLogList? adminLogList,
    $8.ReqTranslationPut? translationPut,
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
    if (billingPromotionCreate != null)
      result.billingPromotionCreate = billingPromotionCreate;
    if (billingPromotionClaim != null)
      result.billingPromotionClaim = billingPromotionClaim;
    if (billingPromotionList != null)
      result.billingPromotionList = billingPromotionList;
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
    if (instList != null) result.instList = instList;
    if (instGet != null) result.instGet = instGet;
    if (instPut != null) result.instPut = instPut;
    if (instDelete != null) result.instDelete = instDelete;
    if (voiceStt != null) result.voiceStt = voiceStt;
    if (voiceTts != null) result.voiceTts = voiceTts;
    if (adminLogList != null) result.adminLogList = adminLogList;
    if (translationPut != null) result.translationPut = translationPut;
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
    18: InvokeReq_Body.billingPromotionCreate,
    19: InvokeReq_Body.billingPromotionClaim,
    20: InvokeReq_Body.billingPromotionList,
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
    103: InvokeReq_Body.instList,
    104: InvokeReq_Body.instGet,
    105: InvokeReq_Body.instPut,
    106: InvokeReq_Body.instDelete,
    107: InvokeReq_Body.voiceStt,
    108: InvokeReq_Body.voiceTts,
    109: InvokeReq_Body.adminLogList,
    110: InvokeReq_Body.translationPut,
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
      18,
      19,
      20,
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
      102,
      103,
      104,
      105,
      106,
      107,
      108,
      109,
      110
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
    ..aOM<$0.ReqBillingPromotionCreate>(
        18, _omitFieldNames ? '' : 'billingPromotionCreate',
        subBuilder: $0.ReqBillingPromotionCreate.$_createMessage)
    ..aOM<$0.ReqBillingPromotionClaim>(
        19, _omitFieldNames ? '' : 'billingPromotionClaim',
        subBuilder: $0.ReqBillingPromotionClaim.$_createMessage)
    ..aOM<$0.ReqBillingPromotionList>(
        20, _omitFieldNames ? '' : 'billingPromotionList',
        subBuilder: $0.ReqBillingPromotionList.$_createMessage)
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
    ..aOM<$6.ReqInstList>(103, _omitFieldNames ? '' : 'instList',
        subBuilder: $6.ReqInstList.$_createMessage)
    ..aOM<$6.ReqInstGet>(104, _omitFieldNames ? '' : 'instGet',
        subBuilder: $6.ReqInstGet.$_createMessage)
    ..aOM<$6.ReqInstPut>(105, _omitFieldNames ? '' : 'instPut',
        subBuilder: $6.ReqInstPut.$_createMessage)
    ..aOM<$6.ReqInstDelete>(106, _omitFieldNames ? '' : 'instDelete',
        subBuilder: $6.ReqInstDelete.$_createMessage)
    ..aOM<$7.ReqVoiceStt>(107, _omitFieldNames ? '' : 'voiceStt',
        subBuilder: $7.ReqVoiceStt.$_createMessage)
    ..aOM<$7.ReqVoiceTts>(108, _omitFieldNames ? '' : 'voiceTts',
        subBuilder: $7.ReqVoiceTts.$_createMessage)
    ..aOM<$3.ReqAdminLogList>(109, _omitFieldNames ? '' : 'adminLogList',
        subBuilder: $3.ReqAdminLogList.$_createMessage)
    ..aOM<$8.ReqTranslationPut>(110, _omitFieldNames ? '' : 'translationPut',
        subBuilder: $8.ReqTranslationPut.$_createMessage)
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
  @$pb.TagNumber(18)
  @$pb.TagNumber(19)
  @$pb.TagNumber(20)
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
  @$pb.TagNumber(103)
  @$pb.TagNumber(104)
  @$pb.TagNumber(105)
  @$pb.TagNumber(106)
  @$pb.TagNumber(107)
  @$pb.TagNumber(108)
  @$pb.TagNumber(109)
  @$pb.TagNumber(110)
  InvokeReq_Body whichBody() => _InvokeReq_BodyByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(10)
  @$pb.TagNumber(11)
  @$pb.TagNumber(12)
  @$pb.TagNumber(13)
  @$pb.TagNumber(14)
  @$pb.TagNumber(15)
  @$pb.TagNumber(16)
  @$pb.TagNumber(17)
  @$pb.TagNumber(18)
  @$pb.TagNumber(19)
  @$pb.TagNumber(20)
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
  @$pb.TagNumber(103)
  @$pb.TagNumber(104)
  @$pb.TagNumber(105)
  @$pb.TagNumber(106)
  @$pb.TagNumber(107)
  @$pb.TagNumber(108)
  @$pb.TagNumber(109)
  @$pb.TagNumber(110)
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

  @$pb.TagNumber(18)
  $0.ReqBillingPromotionCreate get billingPromotionCreate => $_getN(10);
  @$pb.TagNumber(18)
  set billingPromotionCreate($0.ReqBillingPromotionCreate value) =>
      $_setField(18, value);
  @$pb.TagNumber(18)
  $core.bool hasBillingPromotionCreate() => $_has(10);
  @$pb.TagNumber(18)
  void clearBillingPromotionCreate() => $_clearField(18);
  @$pb.TagNumber(18)
  $0.ReqBillingPromotionCreate ensureBillingPromotionCreate() => $_ensure(10);

  @$pb.TagNumber(19)
  $0.ReqBillingPromotionClaim get billingPromotionClaim => $_getN(11);
  @$pb.TagNumber(19)
  set billingPromotionClaim($0.ReqBillingPromotionClaim value) =>
      $_setField(19, value);
  @$pb.TagNumber(19)
  $core.bool hasBillingPromotionClaim() => $_has(11);
  @$pb.TagNumber(19)
  void clearBillingPromotionClaim() => $_clearField(19);
  @$pb.TagNumber(19)
  $0.ReqBillingPromotionClaim ensureBillingPromotionClaim() => $_ensure(11);

  @$pb.TagNumber(20)
  $0.ReqBillingPromotionList get billingPromotionList => $_getN(12);
  @$pb.TagNumber(20)
  set billingPromotionList($0.ReqBillingPromotionList value) =>
      $_setField(20, value);
  @$pb.TagNumber(20)
  $core.bool hasBillingPromotionList() => $_has(12);
  @$pb.TagNumber(20)
  void clearBillingPromotionList() => $_clearField(20);
  @$pb.TagNumber(20)
  $0.ReqBillingPromotionList ensureBillingPromotionList() => $_ensure(12);

  @$pb.TagNumber(62)
  $2.ReqReferralShareSet get referralShareSet => $_getN(13);
  @$pb.TagNumber(62)
  set referralShareSet($2.ReqReferralShareSet value) => $_setField(62, value);
  @$pb.TagNumber(62)
  $core.bool hasReferralShareSet() => $_has(13);
  @$pb.TagNumber(62)
  void clearReferralShareSet() => $_clearField(62);
  @$pb.TagNumber(62)
  $2.ReqReferralShareSet ensureReferralShareSet() => $_ensure(13);

  @$pb.TagNumber(64)
  $2.ReqReferralTreeGet get referralTreeGet => $_getN(14);
  @$pb.TagNumber(64)
  set referralTreeGet($2.ReqReferralTreeGet value) => $_setField(64, value);
  @$pb.TagNumber(64)
  $core.bool hasReferralTreeGet() => $_has(14);
  @$pb.TagNumber(64)
  void clearReferralTreeGet() => $_clearField(64);
  @$pb.TagNumber(64)
  $2.ReqReferralTreeGet ensureReferralTreeGet() => $_ensure(14);

  @$pb.TagNumber(65)
  $2.ReqReferralCodeList get referralCodeList => $_getN(15);
  @$pb.TagNumber(65)
  set referralCodeList($2.ReqReferralCodeList value) => $_setField(65, value);
  @$pb.TagNumber(65)
  $core.bool hasReferralCodeList() => $_has(15);
  @$pb.TagNumber(65)
  void clearReferralCodeList() => $_clearField(65);
  @$pb.TagNumber(65)
  $2.ReqReferralCodeList ensureReferralCodeList() => $_ensure(15);

  @$pb.TagNumber(67)
  $2.ReqReferralCodePut get referralCodePut => $_getN(16);
  @$pb.TagNumber(67)
  set referralCodePut($2.ReqReferralCodePut value) => $_setField(67, value);
  @$pb.TagNumber(67)
  $core.bool hasReferralCodePut() => $_has(16);
  @$pb.TagNumber(67)
  void clearReferralCodePut() => $_clearField(67);
  @$pb.TagNumber(67)
  $2.ReqReferralCodePut ensureReferralCodePut() => $_ensure(16);

  @$pb.TagNumber(68)
  $2.ReqReferralCodeDelete get referralCodeDelete => $_getN(17);
  @$pb.TagNumber(68)
  set referralCodeDelete($2.ReqReferralCodeDelete value) =>
      $_setField(68, value);
  @$pb.TagNumber(68)
  $core.bool hasReferralCodeDelete() => $_has(17);
  @$pb.TagNumber(68)
  void clearReferralCodeDelete() => $_clearField(68);
  @$pb.TagNumber(68)
  $2.ReqReferralCodeDelete ensureReferralCodeDelete() => $_ensure(17);

  @$pb.TagNumber(90)
  $3.ReqAdminUserSearch get adminUserSearch => $_getN(18);
  @$pb.TagNumber(90)
  set adminUserSearch($3.ReqAdminUserSearch value) => $_setField(90, value);
  @$pb.TagNumber(90)
  $core.bool hasAdminUserSearch() => $_has(18);
  @$pb.TagNumber(90)
  void clearAdminUserSearch() => $_clearField(90);
  @$pb.TagNumber(90)
  $3.ReqAdminUserSearch ensureAdminUserSearch() => $_ensure(18);

  @$pb.TagNumber(91)
  $3.ReqAdminUserPut get adminUserPut => $_getN(19);
  @$pb.TagNumber(91)
  set adminUserPut($3.ReqAdminUserPut value) => $_setField(91, value);
  @$pb.TagNumber(91)
  $core.bool hasAdminUserPut() => $_has(19);
  @$pb.TagNumber(91)
  void clearAdminUserPut() => $_clearField(91);
  @$pb.TagNumber(91)
  $3.ReqAdminUserPut ensureAdminUserPut() => $_ensure(19);

  @$pb.TagNumber(92)
  $2.ReqReferralUserStats get referralUserStats => $_getN(20);
  @$pb.TagNumber(92)
  set referralUserStats($2.ReqReferralUserStats value) => $_setField(92, value);
  @$pb.TagNumber(92)
  $core.bool hasReferralUserStats() => $_has(20);
  @$pb.TagNumber(92)
  void clearReferralUserStats() => $_clearField(92);
  @$pb.TagNumber(92)
  $2.ReqReferralUserStats ensureReferralUserStats() => $_ensure(20);

  @$pb.TagNumber(93)
  $2.ReqReferralCommissionSimulate get referralCommissionSimulate => $_getN(21);
  @$pb.TagNumber(93)
  set referralCommissionSimulate($2.ReqReferralCommissionSimulate value) =>
      $_setField(93, value);
  @$pb.TagNumber(93)
  $core.bool hasReferralCommissionSimulate() => $_has(21);
  @$pb.TagNumber(93)
  void clearReferralCommissionSimulate() => $_clearField(93);
  @$pb.TagNumber(93)
  $2.ReqReferralCommissionSimulate ensureReferralCommissionSimulate() =>
      $_ensure(21);

  @$pb.TagNumber(100)
  $4.ReqChannelTelegramConnect get channelTelegramConnect => $_getN(22);
  @$pb.TagNumber(100)
  set channelTelegramConnect($4.ReqChannelTelegramConnect value) =>
      $_setField(100, value);
  @$pb.TagNumber(100)
  $core.bool hasChannelTelegramConnect() => $_has(22);
  @$pb.TagNumber(100)
  void clearChannelTelegramConnect() => $_clearField(100);
  @$pb.TagNumber(100)
  $4.ReqChannelTelegramConnect ensureChannelTelegramConnect() => $_ensure(22);

  @$pb.TagNumber(101)
  $4.ReqChannelWhatsappMetaConnect get channelWhatsappMetaConnect => $_getN(23);
  @$pb.TagNumber(101)
  set channelWhatsappMetaConnect($4.ReqChannelWhatsappMetaConnect value) =>
      $_setField(101, value);
  @$pb.TagNumber(101)
  $core.bool hasChannelWhatsappMetaConnect() => $_has(23);
  @$pb.TagNumber(101)
  void clearChannelWhatsappMetaConnect() => $_clearField(101);
  @$pb.TagNumber(101)
  $4.ReqChannelWhatsappMetaConnect ensureChannelWhatsappMetaConnect() =>
      $_ensure(23);

  @$pb.TagNumber(102)
  $5.ReqDevicePair get devicePair => $_getN(24);
  @$pb.TagNumber(102)
  set devicePair($5.ReqDevicePair value) => $_setField(102, value);
  @$pb.TagNumber(102)
  $core.bool hasDevicePair() => $_has(24);
  @$pb.TagNumber(102)
  void clearDevicePair() => $_clearField(102);
  @$pb.TagNumber(102)
  $5.ReqDevicePair ensureDevicePair() => $_ensure(24);

  @$pb.TagNumber(103)
  $6.ReqInstList get instList => $_getN(25);
  @$pb.TagNumber(103)
  set instList($6.ReqInstList value) => $_setField(103, value);
  @$pb.TagNumber(103)
  $core.bool hasInstList() => $_has(25);
  @$pb.TagNumber(103)
  void clearInstList() => $_clearField(103);
  @$pb.TagNumber(103)
  $6.ReqInstList ensureInstList() => $_ensure(25);

  @$pb.TagNumber(104)
  $6.ReqInstGet get instGet => $_getN(26);
  @$pb.TagNumber(104)
  set instGet($6.ReqInstGet value) => $_setField(104, value);
  @$pb.TagNumber(104)
  $core.bool hasInstGet() => $_has(26);
  @$pb.TagNumber(104)
  void clearInstGet() => $_clearField(104);
  @$pb.TagNumber(104)
  $6.ReqInstGet ensureInstGet() => $_ensure(26);

  @$pb.TagNumber(105)
  $6.ReqInstPut get instPut => $_getN(27);
  @$pb.TagNumber(105)
  set instPut($6.ReqInstPut value) => $_setField(105, value);
  @$pb.TagNumber(105)
  $core.bool hasInstPut() => $_has(27);
  @$pb.TagNumber(105)
  void clearInstPut() => $_clearField(105);
  @$pb.TagNumber(105)
  $6.ReqInstPut ensureInstPut() => $_ensure(27);

  @$pb.TagNumber(106)
  $6.ReqInstDelete get instDelete => $_getN(28);
  @$pb.TagNumber(106)
  set instDelete($6.ReqInstDelete value) => $_setField(106, value);
  @$pb.TagNumber(106)
  $core.bool hasInstDelete() => $_has(28);
  @$pb.TagNumber(106)
  void clearInstDelete() => $_clearField(106);
  @$pb.TagNumber(106)
  $6.ReqInstDelete ensureInstDelete() => $_ensure(28);

  @$pb.TagNumber(107)
  $7.ReqVoiceStt get voiceStt => $_getN(29);
  @$pb.TagNumber(107)
  set voiceStt($7.ReqVoiceStt value) => $_setField(107, value);
  @$pb.TagNumber(107)
  $core.bool hasVoiceStt() => $_has(29);
  @$pb.TagNumber(107)
  void clearVoiceStt() => $_clearField(107);
  @$pb.TagNumber(107)
  $7.ReqVoiceStt ensureVoiceStt() => $_ensure(29);

  @$pb.TagNumber(108)
  $7.ReqVoiceTts get voiceTts => $_getN(30);
  @$pb.TagNumber(108)
  set voiceTts($7.ReqVoiceTts value) => $_setField(108, value);
  @$pb.TagNumber(108)
  $core.bool hasVoiceTts() => $_has(30);
  @$pb.TagNumber(108)
  void clearVoiceTts() => $_clearField(108);
  @$pb.TagNumber(108)
  $7.ReqVoiceTts ensureVoiceTts() => $_ensure(30);

  @$pb.TagNumber(109)
  $3.ReqAdminLogList get adminLogList => $_getN(31);
  @$pb.TagNumber(109)
  set adminLogList($3.ReqAdminLogList value) => $_setField(109, value);
  @$pb.TagNumber(109)
  $core.bool hasAdminLogList() => $_has(31);
  @$pb.TagNumber(109)
  void clearAdminLogList() => $_clearField(109);
  @$pb.TagNumber(109)
  $3.ReqAdminLogList ensureAdminLogList() => $_ensure(31);

  @$pb.TagNumber(110)
  $8.ReqTranslationPut get translationPut => $_getN(32);
  @$pb.TagNumber(110)
  set translationPut($8.ReqTranslationPut value) => $_setField(110, value);
  @$pb.TagNumber(110)
  $core.bool hasTranslationPut() => $_has(32);
  @$pb.TagNumber(110)
  void clearTranslationPut() => $_clearField(110);
  @$pb.TagNumber(110)
  $8.ReqTranslationPut ensureTranslationPut() => $_ensure(32);
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
  billingPromotionCreate,
  billingPromotionClaim,
  billingPromotionList,
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
  instList,
  instGet,
  instPut,
  instDelete,
  voiceStt,
  voiceTts,
  adminLogList,
  translationPut,
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
    $0.ResBillingPromotionCreate? billingPromotionCreate,
    $0.ResBillingPromotionClaim? billingPromotionClaim,
    $0.ResBillingPromotionList? billingPromotionList,
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
    $6.ResInstList? instList,
    $6.ResInstGet? instGet,
    $6.ResInstPut? instPut,
    $6.ResInstDelete? instDelete,
    $7.ResVoiceStt? voiceStt,
    $7.ResVoiceTts? voiceTts,
    $3.ResAdminLogList? adminLogList,
    $8.ResTranslationPut? translationPut,
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
    if (billingPromotionCreate != null)
      result.billingPromotionCreate = billingPromotionCreate;
    if (billingPromotionClaim != null)
      result.billingPromotionClaim = billingPromotionClaim;
    if (billingPromotionList != null)
      result.billingPromotionList = billingPromotionList;
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
    if (instList != null) result.instList = instList;
    if (instGet != null) result.instGet = instGet;
    if (instPut != null) result.instPut = instPut;
    if (instDelete != null) result.instDelete = instDelete;
    if (voiceStt != null) result.voiceStt = voiceStt;
    if (voiceTts != null) result.voiceTts = voiceTts;
    if (adminLogList != null) result.adminLogList = adminLogList;
    if (translationPut != null) result.translationPut = translationPut;
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
    18: InvokeRes_Body.billingPromotionCreate,
    19: InvokeRes_Body.billingPromotionClaim,
    20: InvokeRes_Body.billingPromotionList,
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
    103: InvokeRes_Body.instList,
    104: InvokeRes_Body.instGet,
    105: InvokeRes_Body.instPut,
    106: InvokeRes_Body.instDelete,
    107: InvokeRes_Body.voiceStt,
    108: InvokeRes_Body.voiceTts,
    109: InvokeRes_Body.adminLogList,
    110: InvokeRes_Body.translationPut,
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
      18,
      19,
      20,
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
      102,
      103,
      104,
      105,
      106,
      107,
      108,
      109,
      110
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
    ..aOM<$0.ResBillingPromotionCreate>(
        18, _omitFieldNames ? '' : 'billingPromotionCreate',
        subBuilder: $0.ResBillingPromotionCreate.$_createMessage)
    ..aOM<$0.ResBillingPromotionClaim>(
        19, _omitFieldNames ? '' : 'billingPromotionClaim',
        subBuilder: $0.ResBillingPromotionClaim.$_createMessage)
    ..aOM<$0.ResBillingPromotionList>(
        20, _omitFieldNames ? '' : 'billingPromotionList',
        subBuilder: $0.ResBillingPromotionList.$_createMessage)
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
    ..aOM<$6.ResInstList>(103, _omitFieldNames ? '' : 'instList',
        subBuilder: $6.ResInstList.$_createMessage)
    ..aOM<$6.ResInstGet>(104, _omitFieldNames ? '' : 'instGet',
        subBuilder: $6.ResInstGet.$_createMessage)
    ..aOM<$6.ResInstPut>(105, _omitFieldNames ? '' : 'instPut',
        subBuilder: $6.ResInstPut.$_createMessage)
    ..aOM<$6.ResInstDelete>(106, _omitFieldNames ? '' : 'instDelete',
        subBuilder: $6.ResInstDelete.$_createMessage)
    ..aOM<$7.ResVoiceStt>(107, _omitFieldNames ? '' : 'voiceStt',
        subBuilder: $7.ResVoiceStt.$_createMessage)
    ..aOM<$7.ResVoiceTts>(108, _omitFieldNames ? '' : 'voiceTts',
        subBuilder: $7.ResVoiceTts.$_createMessage)
    ..aOM<$3.ResAdminLogList>(109, _omitFieldNames ? '' : 'adminLogList',
        subBuilder: $3.ResAdminLogList.$_createMessage)
    ..aOM<$8.ResTranslationPut>(110, _omitFieldNames ? '' : 'translationPut',
        subBuilder: $8.ResTranslationPut.$_createMessage)
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
  @$pb.TagNumber(18)
  @$pb.TagNumber(19)
  @$pb.TagNumber(20)
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
  @$pb.TagNumber(103)
  @$pb.TagNumber(104)
  @$pb.TagNumber(105)
  @$pb.TagNumber(106)
  @$pb.TagNumber(107)
  @$pb.TagNumber(108)
  @$pb.TagNumber(109)
  @$pb.TagNumber(110)
  InvokeRes_Body whichBody() => _InvokeRes_BodyByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(10)
  @$pb.TagNumber(11)
  @$pb.TagNumber(12)
  @$pb.TagNumber(13)
  @$pb.TagNumber(14)
  @$pb.TagNumber(15)
  @$pb.TagNumber(16)
  @$pb.TagNumber(17)
  @$pb.TagNumber(18)
  @$pb.TagNumber(19)
  @$pb.TagNumber(20)
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
  @$pb.TagNumber(103)
  @$pb.TagNumber(104)
  @$pb.TagNumber(105)
  @$pb.TagNumber(106)
  @$pb.TagNumber(107)
  @$pb.TagNumber(108)
  @$pb.TagNumber(109)
  @$pb.TagNumber(110)
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

  @$pb.TagNumber(18)
  $0.ResBillingPromotionCreate get billingPromotionCreate => $_getN(11);
  @$pb.TagNumber(18)
  set billingPromotionCreate($0.ResBillingPromotionCreate value) =>
      $_setField(18, value);
  @$pb.TagNumber(18)
  $core.bool hasBillingPromotionCreate() => $_has(11);
  @$pb.TagNumber(18)
  void clearBillingPromotionCreate() => $_clearField(18);
  @$pb.TagNumber(18)
  $0.ResBillingPromotionCreate ensureBillingPromotionCreate() => $_ensure(11);

  @$pb.TagNumber(19)
  $0.ResBillingPromotionClaim get billingPromotionClaim => $_getN(12);
  @$pb.TagNumber(19)
  set billingPromotionClaim($0.ResBillingPromotionClaim value) =>
      $_setField(19, value);
  @$pb.TagNumber(19)
  $core.bool hasBillingPromotionClaim() => $_has(12);
  @$pb.TagNumber(19)
  void clearBillingPromotionClaim() => $_clearField(19);
  @$pb.TagNumber(19)
  $0.ResBillingPromotionClaim ensureBillingPromotionClaim() => $_ensure(12);

  @$pb.TagNumber(20)
  $0.ResBillingPromotionList get billingPromotionList => $_getN(13);
  @$pb.TagNumber(20)
  set billingPromotionList($0.ResBillingPromotionList value) =>
      $_setField(20, value);
  @$pb.TagNumber(20)
  $core.bool hasBillingPromotionList() => $_has(13);
  @$pb.TagNumber(20)
  void clearBillingPromotionList() => $_clearField(20);
  @$pb.TagNumber(20)
  $0.ResBillingPromotionList ensureBillingPromotionList() => $_ensure(13);

  @$pb.TagNumber(62)
  $2.ResReferralShareSet get referralShareSet => $_getN(14);
  @$pb.TagNumber(62)
  set referralShareSet($2.ResReferralShareSet value) => $_setField(62, value);
  @$pb.TagNumber(62)
  $core.bool hasReferralShareSet() => $_has(14);
  @$pb.TagNumber(62)
  void clearReferralShareSet() => $_clearField(62);
  @$pb.TagNumber(62)
  $2.ResReferralShareSet ensureReferralShareSet() => $_ensure(14);

  @$pb.TagNumber(64)
  $2.ResReferralTreeGet get referralTreeGet => $_getN(15);
  @$pb.TagNumber(64)
  set referralTreeGet($2.ResReferralTreeGet value) => $_setField(64, value);
  @$pb.TagNumber(64)
  $core.bool hasReferralTreeGet() => $_has(15);
  @$pb.TagNumber(64)
  void clearReferralTreeGet() => $_clearField(64);
  @$pb.TagNumber(64)
  $2.ResReferralTreeGet ensureReferralTreeGet() => $_ensure(15);

  @$pb.TagNumber(65)
  $2.ResReferralCodeList get referralCodeList => $_getN(16);
  @$pb.TagNumber(65)
  set referralCodeList($2.ResReferralCodeList value) => $_setField(65, value);
  @$pb.TagNumber(65)
  $core.bool hasReferralCodeList() => $_has(16);
  @$pb.TagNumber(65)
  void clearReferralCodeList() => $_clearField(65);
  @$pb.TagNumber(65)
  $2.ResReferralCodeList ensureReferralCodeList() => $_ensure(16);

  @$pb.TagNumber(67)
  $2.ReferralCodeDoc get referralCodePut => $_getN(17);
  @$pb.TagNumber(67)
  set referralCodePut($2.ReferralCodeDoc value) => $_setField(67, value);
  @$pb.TagNumber(67)
  $core.bool hasReferralCodePut() => $_has(17);
  @$pb.TagNumber(67)
  void clearReferralCodePut() => $_clearField(67);
  @$pb.TagNumber(67)
  $2.ReferralCodeDoc ensureReferralCodePut() => $_ensure(17);

  @$pb.TagNumber(90)
  $3.ResAdminUserSearch get adminUserSearch => $_getN(18);
  @$pb.TagNumber(90)
  set adminUserSearch($3.ResAdminUserSearch value) => $_setField(90, value);
  @$pb.TagNumber(90)
  $core.bool hasAdminUserSearch() => $_has(18);
  @$pb.TagNumber(90)
  void clearAdminUserSearch() => $_clearField(90);
  @$pb.TagNumber(90)
  $3.ResAdminUserSearch ensureAdminUserSearch() => $_ensure(18);

  @$pb.TagNumber(91)
  $3.ResAdminUserPut get adminUserPut => $_getN(19);
  @$pb.TagNumber(91)
  set adminUserPut($3.ResAdminUserPut value) => $_setField(91, value);
  @$pb.TagNumber(91)
  $core.bool hasAdminUserPut() => $_has(19);
  @$pb.TagNumber(91)
  void clearAdminUserPut() => $_clearField(91);
  @$pb.TagNumber(91)
  $3.ResAdminUserPut ensureAdminUserPut() => $_ensure(19);

  @$pb.TagNumber(92)
  $2.ResReferralUserStats get referralUserStats => $_getN(20);
  @$pb.TagNumber(92)
  set referralUserStats($2.ResReferralUserStats value) => $_setField(92, value);
  @$pb.TagNumber(92)
  $core.bool hasReferralUserStats() => $_has(20);
  @$pb.TagNumber(92)
  void clearReferralUserStats() => $_clearField(92);
  @$pb.TagNumber(92)
  $2.ResReferralUserStats ensureReferralUserStats() => $_ensure(20);

  @$pb.TagNumber(93)
  $2.ResReferralCommissionSimulate get referralCommissionSimulate => $_getN(21);
  @$pb.TagNumber(93)
  set referralCommissionSimulate($2.ResReferralCommissionSimulate value) =>
      $_setField(93, value);
  @$pb.TagNumber(93)
  $core.bool hasReferralCommissionSimulate() => $_has(21);
  @$pb.TagNumber(93)
  void clearReferralCommissionSimulate() => $_clearField(93);
  @$pb.TagNumber(93)
  $2.ResReferralCommissionSimulate ensureReferralCommissionSimulate() =>
      $_ensure(21);

  @$pb.TagNumber(100)
  $4.ResChannelTelegramConnect get channelTelegramConnect => $_getN(22);
  @$pb.TagNumber(100)
  set channelTelegramConnect($4.ResChannelTelegramConnect value) =>
      $_setField(100, value);
  @$pb.TagNumber(100)
  $core.bool hasChannelTelegramConnect() => $_has(22);
  @$pb.TagNumber(100)
  void clearChannelTelegramConnect() => $_clearField(100);
  @$pb.TagNumber(100)
  $4.ResChannelTelegramConnect ensureChannelTelegramConnect() => $_ensure(22);

  @$pb.TagNumber(101)
  $4.ResChannelWhatsappMetaConnect get channelWhatsappMetaConnect => $_getN(23);
  @$pb.TagNumber(101)
  set channelWhatsappMetaConnect($4.ResChannelWhatsappMetaConnect value) =>
      $_setField(101, value);
  @$pb.TagNumber(101)
  $core.bool hasChannelWhatsappMetaConnect() => $_has(23);
  @$pb.TagNumber(101)
  void clearChannelWhatsappMetaConnect() => $_clearField(101);
  @$pb.TagNumber(101)
  $4.ResChannelWhatsappMetaConnect ensureChannelWhatsappMetaConnect() =>
      $_ensure(23);

  @$pb.TagNumber(102)
  $5.ResDevicePair get devicePair => $_getN(24);
  @$pb.TagNumber(102)
  set devicePair($5.ResDevicePair value) => $_setField(102, value);
  @$pb.TagNumber(102)
  $core.bool hasDevicePair() => $_has(24);
  @$pb.TagNumber(102)
  void clearDevicePair() => $_clearField(102);
  @$pb.TagNumber(102)
  $5.ResDevicePair ensureDevicePair() => $_ensure(24);

  @$pb.TagNumber(103)
  $6.ResInstList get instList => $_getN(25);
  @$pb.TagNumber(103)
  set instList($6.ResInstList value) => $_setField(103, value);
  @$pb.TagNumber(103)
  $core.bool hasInstList() => $_has(25);
  @$pb.TagNumber(103)
  void clearInstList() => $_clearField(103);
  @$pb.TagNumber(103)
  $6.ResInstList ensureInstList() => $_ensure(25);

  @$pb.TagNumber(104)
  $6.ResInstGet get instGet => $_getN(26);
  @$pb.TagNumber(104)
  set instGet($6.ResInstGet value) => $_setField(104, value);
  @$pb.TagNumber(104)
  $core.bool hasInstGet() => $_has(26);
  @$pb.TagNumber(104)
  void clearInstGet() => $_clearField(104);
  @$pb.TagNumber(104)
  $6.ResInstGet ensureInstGet() => $_ensure(26);

  @$pb.TagNumber(105)
  $6.ResInstPut get instPut => $_getN(27);
  @$pb.TagNumber(105)
  set instPut($6.ResInstPut value) => $_setField(105, value);
  @$pb.TagNumber(105)
  $core.bool hasInstPut() => $_has(27);
  @$pb.TagNumber(105)
  void clearInstPut() => $_clearField(105);
  @$pb.TagNumber(105)
  $6.ResInstPut ensureInstPut() => $_ensure(27);

  @$pb.TagNumber(106)
  $6.ResInstDelete get instDelete => $_getN(28);
  @$pb.TagNumber(106)
  set instDelete($6.ResInstDelete value) => $_setField(106, value);
  @$pb.TagNumber(106)
  $core.bool hasInstDelete() => $_has(28);
  @$pb.TagNumber(106)
  void clearInstDelete() => $_clearField(106);
  @$pb.TagNumber(106)
  $6.ResInstDelete ensureInstDelete() => $_ensure(28);

  @$pb.TagNumber(107)
  $7.ResVoiceStt get voiceStt => $_getN(29);
  @$pb.TagNumber(107)
  set voiceStt($7.ResVoiceStt value) => $_setField(107, value);
  @$pb.TagNumber(107)
  $core.bool hasVoiceStt() => $_has(29);
  @$pb.TagNumber(107)
  void clearVoiceStt() => $_clearField(107);
  @$pb.TagNumber(107)
  $7.ResVoiceStt ensureVoiceStt() => $_ensure(29);

  @$pb.TagNumber(108)
  $7.ResVoiceTts get voiceTts => $_getN(30);
  @$pb.TagNumber(108)
  set voiceTts($7.ResVoiceTts value) => $_setField(108, value);
  @$pb.TagNumber(108)
  $core.bool hasVoiceTts() => $_has(30);
  @$pb.TagNumber(108)
  void clearVoiceTts() => $_clearField(108);
  @$pb.TagNumber(108)
  $7.ResVoiceTts ensureVoiceTts() => $_ensure(30);

  @$pb.TagNumber(109)
  $3.ResAdminLogList get adminLogList => $_getN(31);
  @$pb.TagNumber(109)
  set adminLogList($3.ResAdminLogList value) => $_setField(109, value);
  @$pb.TagNumber(109)
  $core.bool hasAdminLogList() => $_has(31);
  @$pb.TagNumber(109)
  void clearAdminLogList() => $_clearField(109);
  @$pb.TagNumber(109)
  $3.ResAdminLogList ensureAdminLogList() => $_ensure(31);

  @$pb.TagNumber(110)
  $8.ResTranslationPut get translationPut => $_getN(32);
  @$pb.TagNumber(110)
  set translationPut($8.ResTranslationPut value) => $_setField(110, value);
  @$pb.TagNumber(110)
  $core.bool hasTranslationPut() => $_has(32);
  @$pb.TagNumber(110)
  void clearTranslationPut() => $_clearField(110);
  @$pb.TagNumber(110)
  $8.ResTranslationPut ensureTranslationPut() => $_ensure(32);
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
  taskList,
  taskPut,
  taskRunStart,
  taskRunCancel,
  taskRunList,
  remoteSessionStart,
  rtcSignalOffer,
  rtcSignalAnswer,
  rtcSignalIce,
  remoteSessionStop,
  channelDisconnect,
  identityDelete,
  skillPut,
  skillCatalogList,
  skillCatalogInstall,
  remoteIceConfig,
  collectionDefList,
  siteDraftGet,
  siteDraftPut,
  sitePublish,
  siteProductList,
  siteProductPut,
  siteContactList,
  siteContactPut,
  siteObjectList,
  siteObjectPut,
  siteDomainList,
  siteDomainPut,
  skillCatalogSearch,
  skillCatalogSubmit,
  skillRunReport,
  reqRemoteScreenshot,
  reqRemoteCommand,
  voiceStt,
  voiceTts,
  statsSubscribe,
  statsUnsubscribe,
  logSubscribe,
  logUnsubscribe,
  mentionList,
  mentionSearch,
  hintTouch,
  siteConfigPut,
  notSet
}

/// WebSocket client → server
class WsReq extends $pb.GeneratedMessage {
  factory WsReq({
    $core.String? reqId,
    $9.ReqSessionInit? sessionInit,
    $10.ReqSync? sync,
    $11.ReqInboxList? inboxList,
    $11.ReqChatMsgList? chatMsgList,
    $11.ReqPrompt? prompt,
    $11.ReqPromptAbort? promptAbort,
    $11.ReqChatStop? chatStop,
    $11.ReqChatSend? chatSend,
    InvokeReq? invoke,
    $12.ReqSkillList? skillList,
    $1.ReqConsumptionList? consumptionList,
    $13.ReqSiteList? siteList,
    $14.ReqTxList? txList,
    $1.ReqConsumptionPut? consumptionPut,
    $11.ReqChatPatch? chatPatch,
    $11.ReqAssetTagList? assetTagList,
    $15.ReqIdentityList? identityList,
    $15.ReqIdentityGrantPatch? identityGrantPatch,
    $11.ReqBotPeerList? botPeerList,
    $11.ReqLogList? logList,
    $15.ReqIdentityPut? identityPut,
    $4.ReqChannelWhatsappPairStart? channelWhatsappPairStart,
    $4.ReqChannelWhatsappPairWatch? channelWhatsappPairWatch,
    $4.ReqChannelWhatsappPairAbort? channelWhatsappPairAbort,
    $16.ReqTaskList? taskList,
    $16.ReqTaskPut? taskPut,
    $16.ReqTaskRunStart? taskRunStart,
    $16.ReqTaskRunCancel? taskRunCancel,
    $16.ReqTaskRunList? taskRunList,
    $17.ReqRemoteSessionStart? remoteSessionStart,
    $17.RtcSignalOffer? rtcSignalOffer,
    $17.RtcSignalAnswer? rtcSignalAnswer,
    $17.RtcSignalIce? rtcSignalIce,
    $17.ReqRemoteSessionStop? remoteSessionStop,
    $4.ReqChannelDisconnect? channelDisconnect,
    $15.ReqIdentityDelete? identityDelete,
    $12.ReqSkillPut? skillPut,
    $12.ReqSkillCatalogList? skillCatalogList,
    $12.ReqSkillCatalogInstall? skillCatalogInstall,
    $17.ReqRemoteIceConfig? remoteIceConfig,
    $18.ReqCollectionDefList? collectionDefList,
    $13.ReqSiteDraftGet? siteDraftGet,
    $13.ReqSiteDraftPut? siteDraftPut,
    $13.ReqSitePublish? sitePublish,
    $13.ReqSiteProductList? siteProductList,
    $13.ReqSiteProductPut? siteProductPut,
    $13.ReqSiteContactList? siteContactList,
    $13.ReqSiteContactPut? siteContactPut,
    $13.ReqSiteObjectList? siteObjectList,
    $13.ReqSiteObjectPut? siteObjectPut,
    $13.ReqSiteDomainList? siteDomainList,
    $13.ReqSiteDomainPut? siteDomainPut,
    $12.ReqSkillCatalogSearch? skillCatalogSearch,
    $12.ReqSkillCatalogSubmit? skillCatalogSubmit,
    $12.ReqSkillRunReport? skillRunReport,
    $17.ReqRemoteScreenshot? reqRemoteScreenshot,
    $17.ReqRemoteCommand? reqRemoteCommand,
    $7.ReqVoiceStt? voiceStt,
    $7.ReqVoiceTts? voiceTts,
    $19.ReqStatsSubscribe? statsSubscribe,
    $19.ReqStatsUnsubscribe? statsUnsubscribe,
    $19.ReqLogSubscribe? logSubscribe,
    $19.ReqLogUnsubscribe? logUnsubscribe,
    $8.ReqMentionList? mentionList,
    $8.ReqMentionSearch? mentionSearch,
    $20.ReqHintTouch? hintTouch,
    $13.ReqSiteConfigPut? siteConfigPut,
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
    if (taskList != null) result.taskList = taskList;
    if (taskPut != null) result.taskPut = taskPut;
    if (taskRunStart != null) result.taskRunStart = taskRunStart;
    if (taskRunCancel != null) result.taskRunCancel = taskRunCancel;
    if (taskRunList != null) result.taskRunList = taskRunList;
    if (remoteSessionStart != null)
      result.remoteSessionStart = remoteSessionStart;
    if (rtcSignalOffer != null) result.rtcSignalOffer = rtcSignalOffer;
    if (rtcSignalAnswer != null) result.rtcSignalAnswer = rtcSignalAnswer;
    if (rtcSignalIce != null) result.rtcSignalIce = rtcSignalIce;
    if (remoteSessionStop != null) result.remoteSessionStop = remoteSessionStop;
    if (channelDisconnect != null) result.channelDisconnect = channelDisconnect;
    if (identityDelete != null) result.identityDelete = identityDelete;
    if (skillPut != null) result.skillPut = skillPut;
    if (skillCatalogList != null) result.skillCatalogList = skillCatalogList;
    if (skillCatalogInstall != null)
      result.skillCatalogInstall = skillCatalogInstall;
    if (remoteIceConfig != null) result.remoteIceConfig = remoteIceConfig;
    if (collectionDefList != null) result.collectionDefList = collectionDefList;
    if (siteDraftGet != null) result.siteDraftGet = siteDraftGet;
    if (siteDraftPut != null) result.siteDraftPut = siteDraftPut;
    if (sitePublish != null) result.sitePublish = sitePublish;
    if (siteProductList != null) result.siteProductList = siteProductList;
    if (siteProductPut != null) result.siteProductPut = siteProductPut;
    if (siteContactList != null) result.siteContactList = siteContactList;
    if (siteContactPut != null) result.siteContactPut = siteContactPut;
    if (siteObjectList != null) result.siteObjectList = siteObjectList;
    if (siteObjectPut != null) result.siteObjectPut = siteObjectPut;
    if (siteDomainList != null) result.siteDomainList = siteDomainList;
    if (siteDomainPut != null) result.siteDomainPut = siteDomainPut;
    if (skillCatalogSearch != null)
      result.skillCatalogSearch = skillCatalogSearch;
    if (skillCatalogSubmit != null)
      result.skillCatalogSubmit = skillCatalogSubmit;
    if (skillRunReport != null) result.skillRunReport = skillRunReport;
    if (reqRemoteScreenshot != null)
      result.reqRemoteScreenshot = reqRemoteScreenshot;
    if (reqRemoteCommand != null) result.reqRemoteCommand = reqRemoteCommand;
    if (voiceStt != null) result.voiceStt = voiceStt;
    if (voiceTts != null) result.voiceTts = voiceTts;
    if (statsSubscribe != null) result.statsSubscribe = statsSubscribe;
    if (statsUnsubscribe != null) result.statsUnsubscribe = statsUnsubscribe;
    if (logSubscribe != null) result.logSubscribe = logSubscribe;
    if (logUnsubscribe != null) result.logUnsubscribe = logUnsubscribe;
    if (mentionList != null) result.mentionList = mentionList;
    if (mentionSearch != null) result.mentionSearch = mentionSearch;
    if (hintTouch != null) result.hintTouch = hintTouch;
    if (siteConfigPut != null) result.siteConfigPut = siteConfigPut;
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
    35: WsReq_Body.taskList,
    36: WsReq_Body.taskPut,
    37: WsReq_Body.taskRunStart,
    38: WsReq_Body.taskRunCancel,
    39: WsReq_Body.taskRunList,
    40: WsReq_Body.remoteSessionStart,
    41: WsReq_Body.rtcSignalOffer,
    42: WsReq_Body.rtcSignalAnswer,
    43: WsReq_Body.rtcSignalIce,
    44: WsReq_Body.remoteSessionStop,
    45: WsReq_Body.channelDisconnect,
    46: WsReq_Body.identityDelete,
    47: WsReq_Body.skillPut,
    48: WsReq_Body.skillCatalogList,
    49: WsReq_Body.skillCatalogInstall,
    50: WsReq_Body.remoteIceConfig,
    51: WsReq_Body.collectionDefList,
    52: WsReq_Body.siteDraftGet,
    53: WsReq_Body.siteDraftPut,
    54: WsReq_Body.sitePublish,
    55: WsReq_Body.siteProductList,
    56: WsReq_Body.siteProductPut,
    57: WsReq_Body.siteContactList,
    58: WsReq_Body.siteContactPut,
    59: WsReq_Body.siteObjectList,
    60: WsReq_Body.siteObjectPut,
    61: WsReq_Body.siteDomainList,
    62: WsReq_Body.siteDomainPut,
    63: WsReq_Body.skillCatalogSearch,
    64: WsReq_Body.skillCatalogSubmit,
    65: WsReq_Body.skillRunReport,
    66: WsReq_Body.reqRemoteScreenshot,
    67: WsReq_Body.reqRemoteCommand,
    68: WsReq_Body.voiceStt,
    69: WsReq_Body.voiceTts,
    70: WsReq_Body.statsSubscribe,
    71: WsReq_Body.statsUnsubscribe,
    72: WsReq_Body.logSubscribe,
    73: WsReq_Body.logUnsubscribe,
    74: WsReq_Body.mentionList,
    75: WsReq_Body.mentionSearch,
    76: WsReq_Body.hintTouch,
    77: WsReq_Body.siteConfigPut,
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
      34,
      35,
      36,
      37,
      38,
      39,
      40,
      41,
      42,
      43,
      44,
      45,
      46,
      47,
      48,
      49,
      50,
      51,
      52,
      53,
      54,
      55,
      56,
      57,
      58,
      59,
      60,
      61,
      62,
      63,
      64,
      65,
      66,
      67,
      68,
      69,
      70,
      71,
      72,
      73,
      74,
      75,
      76,
      77
    ])
    ..aOS(1, _omitFieldNames ? '' : 'reqId')
    ..aOM<$9.ReqSessionInit>(2, _omitFieldNames ? '' : 'sessionInit',
        subBuilder: $9.ReqSessionInit.$_createMessage)
    ..aOM<$10.ReqSync>(3, _omitFieldNames ? '' : 'sync',
        subBuilder: $10.ReqSync.$_createMessage)
    ..aOM<$11.ReqInboxList>(4, _omitFieldNames ? '' : 'inboxList',
        subBuilder: $11.ReqInboxList.$_createMessage)
    ..aOM<$11.ReqChatMsgList>(5, _omitFieldNames ? '' : 'chatMsgList',
        subBuilder: $11.ReqChatMsgList.$_createMessage)
    ..aOM<$11.ReqPrompt>(6, _omitFieldNames ? '' : 'prompt',
        subBuilder: $11.ReqPrompt.$_createMessage)
    ..aOM<$11.ReqPromptAbort>(7, _omitFieldNames ? '' : 'promptAbort',
        subBuilder: $11.ReqPromptAbort.$_createMessage)
    ..aOM<$11.ReqChatStop>(8, _omitFieldNames ? '' : 'chatStop',
        subBuilder: $11.ReqChatStop.$_createMessage)
    ..aOM<$11.ReqChatSend>(9, _omitFieldNames ? '' : 'chatSend',
        subBuilder: $11.ReqChatSend.$_createMessage)
    ..aOM<InvokeReq>(10, _omitFieldNames ? '' : 'invoke',
        subBuilder: InvokeReq.$_createMessage)
    ..aOM<$12.ReqSkillList>(20, _omitFieldNames ? '' : 'skillList',
        subBuilder: $12.ReqSkillList.$_createMessage)
    ..aOM<$1.ReqConsumptionList>(21, _omitFieldNames ? '' : 'consumptionList',
        subBuilder: $1.ReqConsumptionList.$_createMessage)
    ..aOM<$13.ReqSiteList>(22, _omitFieldNames ? '' : 'siteList',
        subBuilder: $13.ReqSiteList.$_createMessage)
    ..aOM<$14.ReqTxList>(23, _omitFieldNames ? '' : 'txList',
        subBuilder: $14.ReqTxList.$_createMessage)
    ..aOM<$1.ReqConsumptionPut>(24, _omitFieldNames ? '' : 'consumptionPut',
        subBuilder: $1.ReqConsumptionPut.$_createMessage)
    ..aOM<$11.ReqChatPatch>(25, _omitFieldNames ? '' : 'chatPatch',
        subBuilder: $11.ReqChatPatch.$_createMessage)
    ..aOM<$11.ReqAssetTagList>(26, _omitFieldNames ? '' : 'assetTagList',
        subBuilder: $11.ReqAssetTagList.$_createMessage)
    ..aOM<$15.ReqIdentityList>(27, _omitFieldNames ? '' : 'identityList',
        subBuilder: $15.ReqIdentityList.$_createMessage)
    ..aOM<$15.ReqIdentityGrantPatch>(
        28, _omitFieldNames ? '' : 'identityGrantPatch',
        subBuilder: $15.ReqIdentityGrantPatch.$_createMessage)
    ..aOM<$11.ReqBotPeerList>(29, _omitFieldNames ? '' : 'botPeerList',
        subBuilder: $11.ReqBotPeerList.$_createMessage)
    ..aOM<$11.ReqLogList>(30, _omitFieldNames ? '' : 'logList',
        subBuilder: $11.ReqLogList.$_createMessage)
    ..aOM<$15.ReqIdentityPut>(31, _omitFieldNames ? '' : 'identityPut',
        subBuilder: $15.ReqIdentityPut.$_createMessage)
    ..aOM<$4.ReqChannelWhatsappPairStart>(
        32, _omitFieldNames ? '' : 'channelWhatsappPairStart',
        subBuilder: $4.ReqChannelWhatsappPairStart.$_createMessage)
    ..aOM<$4.ReqChannelWhatsappPairWatch>(
        33, _omitFieldNames ? '' : 'channelWhatsappPairWatch',
        subBuilder: $4.ReqChannelWhatsappPairWatch.$_createMessage)
    ..aOM<$4.ReqChannelWhatsappPairAbort>(
        34, _omitFieldNames ? '' : 'channelWhatsappPairAbort',
        subBuilder: $4.ReqChannelWhatsappPairAbort.$_createMessage)
    ..aOM<$16.ReqTaskList>(35, _omitFieldNames ? '' : 'taskList',
        subBuilder: $16.ReqTaskList.$_createMessage)
    ..aOM<$16.ReqTaskPut>(36, _omitFieldNames ? '' : 'taskPut',
        subBuilder: $16.ReqTaskPut.$_createMessage)
    ..aOM<$16.ReqTaskRunStart>(37, _omitFieldNames ? '' : 'taskRunStart',
        subBuilder: $16.ReqTaskRunStart.$_createMessage)
    ..aOM<$16.ReqTaskRunCancel>(38, _omitFieldNames ? '' : 'taskRunCancel',
        subBuilder: $16.ReqTaskRunCancel.$_createMessage)
    ..aOM<$16.ReqTaskRunList>(39, _omitFieldNames ? '' : 'taskRunList',
        subBuilder: $16.ReqTaskRunList.$_createMessage)
    ..aOM<$17.ReqRemoteSessionStart>(
        40, _omitFieldNames ? '' : 'remoteSessionStart',
        subBuilder: $17.ReqRemoteSessionStart.$_createMessage)
    ..aOM<$17.RtcSignalOffer>(41, _omitFieldNames ? '' : 'rtcSignalOffer',
        subBuilder: $17.RtcSignalOffer.$_createMessage)
    ..aOM<$17.RtcSignalAnswer>(42, _omitFieldNames ? '' : 'rtcSignalAnswer',
        subBuilder: $17.RtcSignalAnswer.$_createMessage)
    ..aOM<$17.RtcSignalIce>(43, _omitFieldNames ? '' : 'rtcSignalIce',
        subBuilder: $17.RtcSignalIce.$_createMessage)
    ..aOM<$17.ReqRemoteSessionStop>(
        44, _omitFieldNames ? '' : 'remoteSessionStop',
        subBuilder: $17.ReqRemoteSessionStop.$_createMessage)
    ..aOM<$4.ReqChannelDisconnect>(
        45, _omitFieldNames ? '' : 'channelDisconnect',
        subBuilder: $4.ReqChannelDisconnect.$_createMessage)
    ..aOM<$15.ReqIdentityDelete>(46, _omitFieldNames ? '' : 'identityDelete',
        subBuilder: $15.ReqIdentityDelete.$_createMessage)
    ..aOM<$12.ReqSkillPut>(47, _omitFieldNames ? '' : 'skillPut',
        subBuilder: $12.ReqSkillPut.$_createMessage)
    ..aOM<$12.ReqSkillCatalogList>(
        48, _omitFieldNames ? '' : 'skillCatalogList',
        subBuilder: $12.ReqSkillCatalogList.$_createMessage)
    ..aOM<$12.ReqSkillCatalogInstall>(
        49, _omitFieldNames ? '' : 'skillCatalogInstall',
        subBuilder: $12.ReqSkillCatalogInstall.$_createMessage)
    ..aOM<$17.ReqRemoteIceConfig>(50, _omitFieldNames ? '' : 'remoteIceConfig',
        subBuilder: $17.ReqRemoteIceConfig.$_createMessage)
    ..aOM<$18.ReqCollectionDefList>(
        51, _omitFieldNames ? '' : 'collectionDefList',
        subBuilder: $18.ReqCollectionDefList.$_createMessage)
    ..aOM<$13.ReqSiteDraftGet>(52, _omitFieldNames ? '' : 'siteDraftGet',
        subBuilder: $13.ReqSiteDraftGet.$_createMessage)
    ..aOM<$13.ReqSiteDraftPut>(53, _omitFieldNames ? '' : 'siteDraftPut',
        subBuilder: $13.ReqSiteDraftPut.$_createMessage)
    ..aOM<$13.ReqSitePublish>(54, _omitFieldNames ? '' : 'sitePublish',
        subBuilder: $13.ReqSitePublish.$_createMessage)
    ..aOM<$13.ReqSiteProductList>(55, _omitFieldNames ? '' : 'siteProductList',
        subBuilder: $13.ReqSiteProductList.$_createMessage)
    ..aOM<$13.ReqSiteProductPut>(56, _omitFieldNames ? '' : 'siteProductPut',
        subBuilder: $13.ReqSiteProductPut.$_createMessage)
    ..aOM<$13.ReqSiteContactList>(57, _omitFieldNames ? '' : 'siteContactList',
        subBuilder: $13.ReqSiteContactList.$_createMessage)
    ..aOM<$13.ReqSiteContactPut>(58, _omitFieldNames ? '' : 'siteContactPut',
        subBuilder: $13.ReqSiteContactPut.$_createMessage)
    ..aOM<$13.ReqSiteObjectList>(59, _omitFieldNames ? '' : 'siteObjectList',
        subBuilder: $13.ReqSiteObjectList.$_createMessage)
    ..aOM<$13.ReqSiteObjectPut>(60, _omitFieldNames ? '' : 'siteObjectPut',
        subBuilder: $13.ReqSiteObjectPut.$_createMessage)
    ..aOM<$13.ReqSiteDomainList>(61, _omitFieldNames ? '' : 'siteDomainList',
        subBuilder: $13.ReqSiteDomainList.$_createMessage)
    ..aOM<$13.ReqSiteDomainPut>(62, _omitFieldNames ? '' : 'siteDomainPut',
        subBuilder: $13.ReqSiteDomainPut.$_createMessage)
    ..aOM<$12.ReqSkillCatalogSearch>(
        63, _omitFieldNames ? '' : 'skillCatalogSearch',
        subBuilder: $12.ReqSkillCatalogSearch.$_createMessage)
    ..aOM<$12.ReqSkillCatalogSubmit>(
        64, _omitFieldNames ? '' : 'skillCatalogSubmit',
        subBuilder: $12.ReqSkillCatalogSubmit.$_createMessage)
    ..aOM<$12.ReqSkillRunReport>(65, _omitFieldNames ? '' : 'skillRunReport',
        subBuilder: $12.ReqSkillRunReport.$_createMessage)
    ..aOM<$17.ReqRemoteScreenshot>(
        66, _omitFieldNames ? '' : 'reqRemoteScreenshot',
        subBuilder: $17.ReqRemoteScreenshot.$_createMessage)
    ..aOM<$17.ReqRemoteCommand>(67, _omitFieldNames ? '' : 'reqRemoteCommand',
        subBuilder: $17.ReqRemoteCommand.$_createMessage)
    ..aOM<$7.ReqVoiceStt>(68, _omitFieldNames ? '' : 'voiceStt',
        subBuilder: $7.ReqVoiceStt.$_createMessage)
    ..aOM<$7.ReqVoiceTts>(69, _omitFieldNames ? '' : 'voiceTts',
        subBuilder: $7.ReqVoiceTts.$_createMessage)
    ..aOM<$19.ReqStatsSubscribe>(70, _omitFieldNames ? '' : 'statsSubscribe',
        subBuilder: $19.ReqStatsSubscribe.$_createMessage)
    ..aOM<$19.ReqStatsUnsubscribe>(
        71, _omitFieldNames ? '' : 'statsUnsubscribe',
        subBuilder: $19.ReqStatsUnsubscribe.$_createMessage)
    ..aOM<$19.ReqLogSubscribe>(72, _omitFieldNames ? '' : 'logSubscribe',
        subBuilder: $19.ReqLogSubscribe.$_createMessage)
    ..aOM<$19.ReqLogUnsubscribe>(73, _omitFieldNames ? '' : 'logUnsubscribe',
        subBuilder: $19.ReqLogUnsubscribe.$_createMessage)
    ..aOM<$8.ReqMentionList>(74, _omitFieldNames ? '' : 'mentionList',
        subBuilder: $8.ReqMentionList.$_createMessage)
    ..aOM<$8.ReqMentionSearch>(75, _omitFieldNames ? '' : 'mentionSearch',
        subBuilder: $8.ReqMentionSearch.$_createMessage)
    ..aOM<$20.ReqHintTouch>(76, _omitFieldNames ? '' : 'hintTouch',
        subBuilder: $20.ReqHintTouch.$_createMessage)
    ..aOM<$13.ReqSiteConfigPut>(77, _omitFieldNames ? '' : 'siteConfigPut',
        subBuilder: $13.ReqSiteConfigPut.$_createMessage)
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
  @$pb.TagNumber(35)
  @$pb.TagNumber(36)
  @$pb.TagNumber(37)
  @$pb.TagNumber(38)
  @$pb.TagNumber(39)
  @$pb.TagNumber(40)
  @$pb.TagNumber(41)
  @$pb.TagNumber(42)
  @$pb.TagNumber(43)
  @$pb.TagNumber(44)
  @$pb.TagNumber(45)
  @$pb.TagNumber(46)
  @$pb.TagNumber(47)
  @$pb.TagNumber(48)
  @$pb.TagNumber(49)
  @$pb.TagNumber(50)
  @$pb.TagNumber(51)
  @$pb.TagNumber(52)
  @$pb.TagNumber(53)
  @$pb.TagNumber(54)
  @$pb.TagNumber(55)
  @$pb.TagNumber(56)
  @$pb.TagNumber(57)
  @$pb.TagNumber(58)
  @$pb.TagNumber(59)
  @$pb.TagNumber(60)
  @$pb.TagNumber(61)
  @$pb.TagNumber(62)
  @$pb.TagNumber(63)
  @$pb.TagNumber(64)
  @$pb.TagNumber(65)
  @$pb.TagNumber(66)
  @$pb.TagNumber(67)
  @$pb.TagNumber(68)
  @$pb.TagNumber(69)
  @$pb.TagNumber(70)
  @$pb.TagNumber(71)
  @$pb.TagNumber(72)
  @$pb.TagNumber(73)
  @$pb.TagNumber(74)
  @$pb.TagNumber(75)
  @$pb.TagNumber(76)
  @$pb.TagNumber(77)
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
  @$pb.TagNumber(35)
  @$pb.TagNumber(36)
  @$pb.TagNumber(37)
  @$pb.TagNumber(38)
  @$pb.TagNumber(39)
  @$pb.TagNumber(40)
  @$pb.TagNumber(41)
  @$pb.TagNumber(42)
  @$pb.TagNumber(43)
  @$pb.TagNumber(44)
  @$pb.TagNumber(45)
  @$pb.TagNumber(46)
  @$pb.TagNumber(47)
  @$pb.TagNumber(48)
  @$pb.TagNumber(49)
  @$pb.TagNumber(50)
  @$pb.TagNumber(51)
  @$pb.TagNumber(52)
  @$pb.TagNumber(53)
  @$pb.TagNumber(54)
  @$pb.TagNumber(55)
  @$pb.TagNumber(56)
  @$pb.TagNumber(57)
  @$pb.TagNumber(58)
  @$pb.TagNumber(59)
  @$pb.TagNumber(60)
  @$pb.TagNumber(61)
  @$pb.TagNumber(62)
  @$pb.TagNumber(63)
  @$pb.TagNumber(64)
  @$pb.TagNumber(65)
  @$pb.TagNumber(66)
  @$pb.TagNumber(67)
  @$pb.TagNumber(68)
  @$pb.TagNumber(69)
  @$pb.TagNumber(70)
  @$pb.TagNumber(71)
  @$pb.TagNumber(72)
  @$pb.TagNumber(73)
  @$pb.TagNumber(74)
  @$pb.TagNumber(75)
  @$pb.TagNumber(76)
  @$pb.TagNumber(77)
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
  $9.ReqSessionInit get sessionInit => $_getN(1);
  @$pb.TagNumber(2)
  set sessionInit($9.ReqSessionInit value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasSessionInit() => $_has(1);
  @$pb.TagNumber(2)
  void clearSessionInit() => $_clearField(2);
  @$pb.TagNumber(2)
  $9.ReqSessionInit ensureSessionInit() => $_ensure(1);

  @$pb.TagNumber(3)
  $10.ReqSync get sync => $_getN(2);
  @$pb.TagNumber(3)
  set sync($10.ReqSync value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasSync() => $_has(2);
  @$pb.TagNumber(3)
  void clearSync() => $_clearField(3);
  @$pb.TagNumber(3)
  $10.ReqSync ensureSync() => $_ensure(2);

  @$pb.TagNumber(4)
  $11.ReqInboxList get inboxList => $_getN(3);
  @$pb.TagNumber(4)
  set inboxList($11.ReqInboxList value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasInboxList() => $_has(3);
  @$pb.TagNumber(4)
  void clearInboxList() => $_clearField(4);
  @$pb.TagNumber(4)
  $11.ReqInboxList ensureInboxList() => $_ensure(3);

  @$pb.TagNumber(5)
  $11.ReqChatMsgList get chatMsgList => $_getN(4);
  @$pb.TagNumber(5)
  set chatMsgList($11.ReqChatMsgList value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasChatMsgList() => $_has(4);
  @$pb.TagNumber(5)
  void clearChatMsgList() => $_clearField(5);
  @$pb.TagNumber(5)
  $11.ReqChatMsgList ensureChatMsgList() => $_ensure(4);

  @$pb.TagNumber(6)
  $11.ReqPrompt get prompt => $_getN(5);
  @$pb.TagNumber(6)
  set prompt($11.ReqPrompt value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasPrompt() => $_has(5);
  @$pb.TagNumber(6)
  void clearPrompt() => $_clearField(6);
  @$pb.TagNumber(6)
  $11.ReqPrompt ensurePrompt() => $_ensure(5);

  @$pb.TagNumber(7)
  $11.ReqPromptAbort get promptAbort => $_getN(6);
  @$pb.TagNumber(7)
  set promptAbort($11.ReqPromptAbort value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasPromptAbort() => $_has(6);
  @$pb.TagNumber(7)
  void clearPromptAbort() => $_clearField(7);
  @$pb.TagNumber(7)
  $11.ReqPromptAbort ensurePromptAbort() => $_ensure(6);

  @$pb.TagNumber(8)
  $11.ReqChatStop get chatStop => $_getN(7);
  @$pb.TagNumber(8)
  set chatStop($11.ReqChatStop value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasChatStop() => $_has(7);
  @$pb.TagNumber(8)
  void clearChatStop() => $_clearField(8);
  @$pb.TagNumber(8)
  $11.ReqChatStop ensureChatStop() => $_ensure(7);

  @$pb.TagNumber(9)
  $11.ReqChatSend get chatSend => $_getN(8);
  @$pb.TagNumber(9)
  set chatSend($11.ReqChatSend value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasChatSend() => $_has(8);
  @$pb.TagNumber(9)
  void clearChatSend() => $_clearField(9);
  @$pb.TagNumber(9)
  $11.ReqChatSend ensureChatSend() => $_ensure(8);

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
  $12.ReqSkillList get skillList => $_getN(10);
  @$pb.TagNumber(20)
  set skillList($12.ReqSkillList value) => $_setField(20, value);
  @$pb.TagNumber(20)
  $core.bool hasSkillList() => $_has(10);
  @$pb.TagNumber(20)
  void clearSkillList() => $_clearField(20);
  @$pb.TagNumber(20)
  $12.ReqSkillList ensureSkillList() => $_ensure(10);

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
  $13.ReqSiteList get siteList => $_getN(12);
  @$pb.TagNumber(22)
  set siteList($13.ReqSiteList value) => $_setField(22, value);
  @$pb.TagNumber(22)
  $core.bool hasSiteList() => $_has(12);
  @$pb.TagNumber(22)
  void clearSiteList() => $_clearField(22);
  @$pb.TagNumber(22)
  $13.ReqSiteList ensureSiteList() => $_ensure(12);

  @$pb.TagNumber(23)
  $14.ReqTxList get txList => $_getN(13);
  @$pb.TagNumber(23)
  set txList($14.ReqTxList value) => $_setField(23, value);
  @$pb.TagNumber(23)
  $core.bool hasTxList() => $_has(13);
  @$pb.TagNumber(23)
  void clearTxList() => $_clearField(23);
  @$pb.TagNumber(23)
  $14.ReqTxList ensureTxList() => $_ensure(13);

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
  $11.ReqChatPatch get chatPatch => $_getN(15);
  @$pb.TagNumber(25)
  set chatPatch($11.ReqChatPatch value) => $_setField(25, value);
  @$pb.TagNumber(25)
  $core.bool hasChatPatch() => $_has(15);
  @$pb.TagNumber(25)
  void clearChatPatch() => $_clearField(25);
  @$pb.TagNumber(25)
  $11.ReqChatPatch ensureChatPatch() => $_ensure(15);

  @$pb.TagNumber(26)
  $11.ReqAssetTagList get assetTagList => $_getN(16);
  @$pb.TagNumber(26)
  set assetTagList($11.ReqAssetTagList value) => $_setField(26, value);
  @$pb.TagNumber(26)
  $core.bool hasAssetTagList() => $_has(16);
  @$pb.TagNumber(26)
  void clearAssetTagList() => $_clearField(26);
  @$pb.TagNumber(26)
  $11.ReqAssetTagList ensureAssetTagList() => $_ensure(16);

  @$pb.TagNumber(27)
  $15.ReqIdentityList get identityList => $_getN(17);
  @$pb.TagNumber(27)
  set identityList($15.ReqIdentityList value) => $_setField(27, value);
  @$pb.TagNumber(27)
  $core.bool hasIdentityList() => $_has(17);
  @$pb.TagNumber(27)
  void clearIdentityList() => $_clearField(27);
  @$pb.TagNumber(27)
  $15.ReqIdentityList ensureIdentityList() => $_ensure(17);

  @$pb.TagNumber(28)
  $15.ReqIdentityGrantPatch get identityGrantPatch => $_getN(18);
  @$pb.TagNumber(28)
  set identityGrantPatch($15.ReqIdentityGrantPatch value) =>
      $_setField(28, value);
  @$pb.TagNumber(28)
  $core.bool hasIdentityGrantPatch() => $_has(18);
  @$pb.TagNumber(28)
  void clearIdentityGrantPatch() => $_clearField(28);
  @$pb.TagNumber(28)
  $15.ReqIdentityGrantPatch ensureIdentityGrantPatch() => $_ensure(18);

  @$pb.TagNumber(29)
  $11.ReqBotPeerList get botPeerList => $_getN(19);
  @$pb.TagNumber(29)
  set botPeerList($11.ReqBotPeerList value) => $_setField(29, value);
  @$pb.TagNumber(29)
  $core.bool hasBotPeerList() => $_has(19);
  @$pb.TagNumber(29)
  void clearBotPeerList() => $_clearField(29);
  @$pb.TagNumber(29)
  $11.ReqBotPeerList ensureBotPeerList() => $_ensure(19);

  @$pb.TagNumber(30)
  $11.ReqLogList get logList => $_getN(20);
  @$pb.TagNumber(30)
  set logList($11.ReqLogList value) => $_setField(30, value);
  @$pb.TagNumber(30)
  $core.bool hasLogList() => $_has(20);
  @$pb.TagNumber(30)
  void clearLogList() => $_clearField(30);
  @$pb.TagNumber(30)
  $11.ReqLogList ensureLogList() => $_ensure(20);

  @$pb.TagNumber(31)
  $15.ReqIdentityPut get identityPut => $_getN(21);
  @$pb.TagNumber(31)
  set identityPut($15.ReqIdentityPut value) => $_setField(31, value);
  @$pb.TagNumber(31)
  $core.bool hasIdentityPut() => $_has(21);
  @$pb.TagNumber(31)
  void clearIdentityPut() => $_clearField(31);
  @$pb.TagNumber(31)
  $15.ReqIdentityPut ensureIdentityPut() => $_ensure(21);

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

  @$pb.TagNumber(35)
  $16.ReqTaskList get taskList => $_getN(25);
  @$pb.TagNumber(35)
  set taskList($16.ReqTaskList value) => $_setField(35, value);
  @$pb.TagNumber(35)
  $core.bool hasTaskList() => $_has(25);
  @$pb.TagNumber(35)
  void clearTaskList() => $_clearField(35);
  @$pb.TagNumber(35)
  $16.ReqTaskList ensureTaskList() => $_ensure(25);

  @$pb.TagNumber(36)
  $16.ReqTaskPut get taskPut => $_getN(26);
  @$pb.TagNumber(36)
  set taskPut($16.ReqTaskPut value) => $_setField(36, value);
  @$pb.TagNumber(36)
  $core.bool hasTaskPut() => $_has(26);
  @$pb.TagNumber(36)
  void clearTaskPut() => $_clearField(36);
  @$pb.TagNumber(36)
  $16.ReqTaskPut ensureTaskPut() => $_ensure(26);

  @$pb.TagNumber(37)
  $16.ReqTaskRunStart get taskRunStart => $_getN(27);
  @$pb.TagNumber(37)
  set taskRunStart($16.ReqTaskRunStart value) => $_setField(37, value);
  @$pb.TagNumber(37)
  $core.bool hasTaskRunStart() => $_has(27);
  @$pb.TagNumber(37)
  void clearTaskRunStart() => $_clearField(37);
  @$pb.TagNumber(37)
  $16.ReqTaskRunStart ensureTaskRunStart() => $_ensure(27);

  @$pb.TagNumber(38)
  $16.ReqTaskRunCancel get taskRunCancel => $_getN(28);
  @$pb.TagNumber(38)
  set taskRunCancel($16.ReqTaskRunCancel value) => $_setField(38, value);
  @$pb.TagNumber(38)
  $core.bool hasTaskRunCancel() => $_has(28);
  @$pb.TagNumber(38)
  void clearTaskRunCancel() => $_clearField(38);
  @$pb.TagNumber(38)
  $16.ReqTaskRunCancel ensureTaskRunCancel() => $_ensure(28);

  @$pb.TagNumber(39)
  $16.ReqTaskRunList get taskRunList => $_getN(29);
  @$pb.TagNumber(39)
  set taskRunList($16.ReqTaskRunList value) => $_setField(39, value);
  @$pb.TagNumber(39)
  $core.bool hasTaskRunList() => $_has(29);
  @$pb.TagNumber(39)
  void clearTaskRunList() => $_clearField(39);
  @$pb.TagNumber(39)
  $16.ReqTaskRunList ensureTaskRunList() => $_ensure(29);

  @$pb.TagNumber(40)
  $17.ReqRemoteSessionStart get remoteSessionStart => $_getN(30);
  @$pb.TagNumber(40)
  set remoteSessionStart($17.ReqRemoteSessionStart value) =>
      $_setField(40, value);
  @$pb.TagNumber(40)
  $core.bool hasRemoteSessionStart() => $_has(30);
  @$pb.TagNumber(40)
  void clearRemoteSessionStart() => $_clearField(40);
  @$pb.TagNumber(40)
  $17.ReqRemoteSessionStart ensureRemoteSessionStart() => $_ensure(30);

  @$pb.TagNumber(41)
  $17.RtcSignalOffer get rtcSignalOffer => $_getN(31);
  @$pb.TagNumber(41)
  set rtcSignalOffer($17.RtcSignalOffer value) => $_setField(41, value);
  @$pb.TagNumber(41)
  $core.bool hasRtcSignalOffer() => $_has(31);
  @$pb.TagNumber(41)
  void clearRtcSignalOffer() => $_clearField(41);
  @$pb.TagNumber(41)
  $17.RtcSignalOffer ensureRtcSignalOffer() => $_ensure(31);

  @$pb.TagNumber(42)
  $17.RtcSignalAnswer get rtcSignalAnswer => $_getN(32);
  @$pb.TagNumber(42)
  set rtcSignalAnswer($17.RtcSignalAnswer value) => $_setField(42, value);
  @$pb.TagNumber(42)
  $core.bool hasRtcSignalAnswer() => $_has(32);
  @$pb.TagNumber(42)
  void clearRtcSignalAnswer() => $_clearField(42);
  @$pb.TagNumber(42)
  $17.RtcSignalAnswer ensureRtcSignalAnswer() => $_ensure(32);

  @$pb.TagNumber(43)
  $17.RtcSignalIce get rtcSignalIce => $_getN(33);
  @$pb.TagNumber(43)
  set rtcSignalIce($17.RtcSignalIce value) => $_setField(43, value);
  @$pb.TagNumber(43)
  $core.bool hasRtcSignalIce() => $_has(33);
  @$pb.TagNumber(43)
  void clearRtcSignalIce() => $_clearField(43);
  @$pb.TagNumber(43)
  $17.RtcSignalIce ensureRtcSignalIce() => $_ensure(33);

  @$pb.TagNumber(44)
  $17.ReqRemoteSessionStop get remoteSessionStop => $_getN(34);
  @$pb.TagNumber(44)
  set remoteSessionStop($17.ReqRemoteSessionStop value) =>
      $_setField(44, value);
  @$pb.TagNumber(44)
  $core.bool hasRemoteSessionStop() => $_has(34);
  @$pb.TagNumber(44)
  void clearRemoteSessionStop() => $_clearField(44);
  @$pb.TagNumber(44)
  $17.ReqRemoteSessionStop ensureRemoteSessionStop() => $_ensure(34);

  @$pb.TagNumber(45)
  $4.ReqChannelDisconnect get channelDisconnect => $_getN(35);
  @$pb.TagNumber(45)
  set channelDisconnect($4.ReqChannelDisconnect value) => $_setField(45, value);
  @$pb.TagNumber(45)
  $core.bool hasChannelDisconnect() => $_has(35);
  @$pb.TagNumber(45)
  void clearChannelDisconnect() => $_clearField(45);
  @$pb.TagNumber(45)
  $4.ReqChannelDisconnect ensureChannelDisconnect() => $_ensure(35);

  @$pb.TagNumber(46)
  $15.ReqIdentityDelete get identityDelete => $_getN(36);
  @$pb.TagNumber(46)
  set identityDelete($15.ReqIdentityDelete value) => $_setField(46, value);
  @$pb.TagNumber(46)
  $core.bool hasIdentityDelete() => $_has(36);
  @$pb.TagNumber(46)
  void clearIdentityDelete() => $_clearField(46);
  @$pb.TagNumber(46)
  $15.ReqIdentityDelete ensureIdentityDelete() => $_ensure(36);

  @$pb.TagNumber(47)
  $12.ReqSkillPut get skillPut => $_getN(37);
  @$pb.TagNumber(47)
  set skillPut($12.ReqSkillPut value) => $_setField(47, value);
  @$pb.TagNumber(47)
  $core.bool hasSkillPut() => $_has(37);
  @$pb.TagNumber(47)
  void clearSkillPut() => $_clearField(47);
  @$pb.TagNumber(47)
  $12.ReqSkillPut ensureSkillPut() => $_ensure(37);

  @$pb.TagNumber(48)
  $12.ReqSkillCatalogList get skillCatalogList => $_getN(38);
  @$pb.TagNumber(48)
  set skillCatalogList($12.ReqSkillCatalogList value) => $_setField(48, value);
  @$pb.TagNumber(48)
  $core.bool hasSkillCatalogList() => $_has(38);
  @$pb.TagNumber(48)
  void clearSkillCatalogList() => $_clearField(48);
  @$pb.TagNumber(48)
  $12.ReqSkillCatalogList ensureSkillCatalogList() => $_ensure(38);

  @$pb.TagNumber(49)
  $12.ReqSkillCatalogInstall get skillCatalogInstall => $_getN(39);
  @$pb.TagNumber(49)
  set skillCatalogInstall($12.ReqSkillCatalogInstall value) =>
      $_setField(49, value);
  @$pb.TagNumber(49)
  $core.bool hasSkillCatalogInstall() => $_has(39);
  @$pb.TagNumber(49)
  void clearSkillCatalogInstall() => $_clearField(49);
  @$pb.TagNumber(49)
  $12.ReqSkillCatalogInstall ensureSkillCatalogInstall() => $_ensure(39);

  @$pb.TagNumber(50)
  $17.ReqRemoteIceConfig get remoteIceConfig => $_getN(40);
  @$pb.TagNumber(50)
  set remoteIceConfig($17.ReqRemoteIceConfig value) => $_setField(50, value);
  @$pb.TagNumber(50)
  $core.bool hasRemoteIceConfig() => $_has(40);
  @$pb.TagNumber(50)
  void clearRemoteIceConfig() => $_clearField(50);
  @$pb.TagNumber(50)
  $17.ReqRemoteIceConfig ensureRemoteIceConfig() => $_ensure(40);

  @$pb.TagNumber(51)
  $18.ReqCollectionDefList get collectionDefList => $_getN(41);
  @$pb.TagNumber(51)
  set collectionDefList($18.ReqCollectionDefList value) =>
      $_setField(51, value);
  @$pb.TagNumber(51)
  $core.bool hasCollectionDefList() => $_has(41);
  @$pb.TagNumber(51)
  void clearCollectionDefList() => $_clearField(51);
  @$pb.TagNumber(51)
  $18.ReqCollectionDefList ensureCollectionDefList() => $_ensure(41);

  @$pb.TagNumber(52)
  $13.ReqSiteDraftGet get siteDraftGet => $_getN(42);
  @$pb.TagNumber(52)
  set siteDraftGet($13.ReqSiteDraftGet value) => $_setField(52, value);
  @$pb.TagNumber(52)
  $core.bool hasSiteDraftGet() => $_has(42);
  @$pb.TagNumber(52)
  void clearSiteDraftGet() => $_clearField(52);
  @$pb.TagNumber(52)
  $13.ReqSiteDraftGet ensureSiteDraftGet() => $_ensure(42);

  @$pb.TagNumber(53)
  $13.ReqSiteDraftPut get siteDraftPut => $_getN(43);
  @$pb.TagNumber(53)
  set siteDraftPut($13.ReqSiteDraftPut value) => $_setField(53, value);
  @$pb.TagNumber(53)
  $core.bool hasSiteDraftPut() => $_has(43);
  @$pb.TagNumber(53)
  void clearSiteDraftPut() => $_clearField(53);
  @$pb.TagNumber(53)
  $13.ReqSiteDraftPut ensureSiteDraftPut() => $_ensure(43);

  @$pb.TagNumber(54)
  $13.ReqSitePublish get sitePublish => $_getN(44);
  @$pb.TagNumber(54)
  set sitePublish($13.ReqSitePublish value) => $_setField(54, value);
  @$pb.TagNumber(54)
  $core.bool hasSitePublish() => $_has(44);
  @$pb.TagNumber(54)
  void clearSitePublish() => $_clearField(54);
  @$pb.TagNumber(54)
  $13.ReqSitePublish ensureSitePublish() => $_ensure(44);

  @$pb.TagNumber(55)
  $13.ReqSiteProductList get siteProductList => $_getN(45);
  @$pb.TagNumber(55)
  set siteProductList($13.ReqSiteProductList value) => $_setField(55, value);
  @$pb.TagNumber(55)
  $core.bool hasSiteProductList() => $_has(45);
  @$pb.TagNumber(55)
  void clearSiteProductList() => $_clearField(55);
  @$pb.TagNumber(55)
  $13.ReqSiteProductList ensureSiteProductList() => $_ensure(45);

  @$pb.TagNumber(56)
  $13.ReqSiteProductPut get siteProductPut => $_getN(46);
  @$pb.TagNumber(56)
  set siteProductPut($13.ReqSiteProductPut value) => $_setField(56, value);
  @$pb.TagNumber(56)
  $core.bool hasSiteProductPut() => $_has(46);
  @$pb.TagNumber(56)
  void clearSiteProductPut() => $_clearField(56);
  @$pb.TagNumber(56)
  $13.ReqSiteProductPut ensureSiteProductPut() => $_ensure(46);

  @$pb.TagNumber(57)
  $13.ReqSiteContactList get siteContactList => $_getN(47);
  @$pb.TagNumber(57)
  set siteContactList($13.ReqSiteContactList value) => $_setField(57, value);
  @$pb.TagNumber(57)
  $core.bool hasSiteContactList() => $_has(47);
  @$pb.TagNumber(57)
  void clearSiteContactList() => $_clearField(57);
  @$pb.TagNumber(57)
  $13.ReqSiteContactList ensureSiteContactList() => $_ensure(47);

  @$pb.TagNumber(58)
  $13.ReqSiteContactPut get siteContactPut => $_getN(48);
  @$pb.TagNumber(58)
  set siteContactPut($13.ReqSiteContactPut value) => $_setField(58, value);
  @$pb.TagNumber(58)
  $core.bool hasSiteContactPut() => $_has(48);
  @$pb.TagNumber(58)
  void clearSiteContactPut() => $_clearField(58);
  @$pb.TagNumber(58)
  $13.ReqSiteContactPut ensureSiteContactPut() => $_ensure(48);

  @$pb.TagNumber(59)
  $13.ReqSiteObjectList get siteObjectList => $_getN(49);
  @$pb.TagNumber(59)
  set siteObjectList($13.ReqSiteObjectList value) => $_setField(59, value);
  @$pb.TagNumber(59)
  $core.bool hasSiteObjectList() => $_has(49);
  @$pb.TagNumber(59)
  void clearSiteObjectList() => $_clearField(59);
  @$pb.TagNumber(59)
  $13.ReqSiteObjectList ensureSiteObjectList() => $_ensure(49);

  @$pb.TagNumber(60)
  $13.ReqSiteObjectPut get siteObjectPut => $_getN(50);
  @$pb.TagNumber(60)
  set siteObjectPut($13.ReqSiteObjectPut value) => $_setField(60, value);
  @$pb.TagNumber(60)
  $core.bool hasSiteObjectPut() => $_has(50);
  @$pb.TagNumber(60)
  void clearSiteObjectPut() => $_clearField(60);
  @$pb.TagNumber(60)
  $13.ReqSiteObjectPut ensureSiteObjectPut() => $_ensure(50);

  @$pb.TagNumber(61)
  $13.ReqSiteDomainList get siteDomainList => $_getN(51);
  @$pb.TagNumber(61)
  set siteDomainList($13.ReqSiteDomainList value) => $_setField(61, value);
  @$pb.TagNumber(61)
  $core.bool hasSiteDomainList() => $_has(51);
  @$pb.TagNumber(61)
  void clearSiteDomainList() => $_clearField(61);
  @$pb.TagNumber(61)
  $13.ReqSiteDomainList ensureSiteDomainList() => $_ensure(51);

  @$pb.TagNumber(62)
  $13.ReqSiteDomainPut get siteDomainPut => $_getN(52);
  @$pb.TagNumber(62)
  set siteDomainPut($13.ReqSiteDomainPut value) => $_setField(62, value);
  @$pb.TagNumber(62)
  $core.bool hasSiteDomainPut() => $_has(52);
  @$pb.TagNumber(62)
  void clearSiteDomainPut() => $_clearField(62);
  @$pb.TagNumber(62)
  $13.ReqSiteDomainPut ensureSiteDomainPut() => $_ensure(52);

  @$pb.TagNumber(63)
  $12.ReqSkillCatalogSearch get skillCatalogSearch => $_getN(53);
  @$pb.TagNumber(63)
  set skillCatalogSearch($12.ReqSkillCatalogSearch value) =>
      $_setField(63, value);
  @$pb.TagNumber(63)
  $core.bool hasSkillCatalogSearch() => $_has(53);
  @$pb.TagNumber(63)
  void clearSkillCatalogSearch() => $_clearField(63);
  @$pb.TagNumber(63)
  $12.ReqSkillCatalogSearch ensureSkillCatalogSearch() => $_ensure(53);

  @$pb.TagNumber(64)
  $12.ReqSkillCatalogSubmit get skillCatalogSubmit => $_getN(54);
  @$pb.TagNumber(64)
  set skillCatalogSubmit($12.ReqSkillCatalogSubmit value) =>
      $_setField(64, value);
  @$pb.TagNumber(64)
  $core.bool hasSkillCatalogSubmit() => $_has(54);
  @$pb.TagNumber(64)
  void clearSkillCatalogSubmit() => $_clearField(64);
  @$pb.TagNumber(64)
  $12.ReqSkillCatalogSubmit ensureSkillCatalogSubmit() => $_ensure(54);

  @$pb.TagNumber(65)
  $12.ReqSkillRunReport get skillRunReport => $_getN(55);
  @$pb.TagNumber(65)
  set skillRunReport($12.ReqSkillRunReport value) => $_setField(65, value);
  @$pb.TagNumber(65)
  $core.bool hasSkillRunReport() => $_has(55);
  @$pb.TagNumber(65)
  void clearSkillRunReport() => $_clearField(65);
  @$pb.TagNumber(65)
  $12.ReqSkillRunReport ensureSkillRunReport() => $_ensure(55);

  @$pb.TagNumber(66)
  $17.ReqRemoteScreenshot get reqRemoteScreenshot => $_getN(56);
  @$pb.TagNumber(66)
  set reqRemoteScreenshot($17.ReqRemoteScreenshot value) =>
      $_setField(66, value);
  @$pb.TagNumber(66)
  $core.bool hasReqRemoteScreenshot() => $_has(56);
  @$pb.TagNumber(66)
  void clearReqRemoteScreenshot() => $_clearField(66);
  @$pb.TagNumber(66)
  $17.ReqRemoteScreenshot ensureReqRemoteScreenshot() => $_ensure(56);

  @$pb.TagNumber(67)
  $17.ReqRemoteCommand get reqRemoteCommand => $_getN(57);
  @$pb.TagNumber(67)
  set reqRemoteCommand($17.ReqRemoteCommand value) => $_setField(67, value);
  @$pb.TagNumber(67)
  $core.bool hasReqRemoteCommand() => $_has(57);
  @$pb.TagNumber(67)
  void clearReqRemoteCommand() => $_clearField(67);
  @$pb.TagNumber(67)
  $17.ReqRemoteCommand ensureReqRemoteCommand() => $_ensure(57);

  @$pb.TagNumber(68)
  $7.ReqVoiceStt get voiceStt => $_getN(58);
  @$pb.TagNumber(68)
  set voiceStt($7.ReqVoiceStt value) => $_setField(68, value);
  @$pb.TagNumber(68)
  $core.bool hasVoiceStt() => $_has(58);
  @$pb.TagNumber(68)
  void clearVoiceStt() => $_clearField(68);
  @$pb.TagNumber(68)
  $7.ReqVoiceStt ensureVoiceStt() => $_ensure(58);

  @$pb.TagNumber(69)
  $7.ReqVoiceTts get voiceTts => $_getN(59);
  @$pb.TagNumber(69)
  set voiceTts($7.ReqVoiceTts value) => $_setField(69, value);
  @$pb.TagNumber(69)
  $core.bool hasVoiceTts() => $_has(59);
  @$pb.TagNumber(69)
  void clearVoiceTts() => $_clearField(69);
  @$pb.TagNumber(69)
  $7.ReqVoiceTts ensureVoiceTts() => $_ensure(59);

  @$pb.TagNumber(70)
  $19.ReqStatsSubscribe get statsSubscribe => $_getN(60);
  @$pb.TagNumber(70)
  set statsSubscribe($19.ReqStatsSubscribe value) => $_setField(70, value);
  @$pb.TagNumber(70)
  $core.bool hasStatsSubscribe() => $_has(60);
  @$pb.TagNumber(70)
  void clearStatsSubscribe() => $_clearField(70);
  @$pb.TagNumber(70)
  $19.ReqStatsSubscribe ensureStatsSubscribe() => $_ensure(60);

  @$pb.TagNumber(71)
  $19.ReqStatsUnsubscribe get statsUnsubscribe => $_getN(61);
  @$pb.TagNumber(71)
  set statsUnsubscribe($19.ReqStatsUnsubscribe value) => $_setField(71, value);
  @$pb.TagNumber(71)
  $core.bool hasStatsUnsubscribe() => $_has(61);
  @$pb.TagNumber(71)
  void clearStatsUnsubscribe() => $_clearField(71);
  @$pb.TagNumber(71)
  $19.ReqStatsUnsubscribe ensureStatsUnsubscribe() => $_ensure(61);

  @$pb.TagNumber(72)
  $19.ReqLogSubscribe get logSubscribe => $_getN(62);
  @$pb.TagNumber(72)
  set logSubscribe($19.ReqLogSubscribe value) => $_setField(72, value);
  @$pb.TagNumber(72)
  $core.bool hasLogSubscribe() => $_has(62);
  @$pb.TagNumber(72)
  void clearLogSubscribe() => $_clearField(72);
  @$pb.TagNumber(72)
  $19.ReqLogSubscribe ensureLogSubscribe() => $_ensure(62);

  @$pb.TagNumber(73)
  $19.ReqLogUnsubscribe get logUnsubscribe => $_getN(63);
  @$pb.TagNumber(73)
  set logUnsubscribe($19.ReqLogUnsubscribe value) => $_setField(73, value);
  @$pb.TagNumber(73)
  $core.bool hasLogUnsubscribe() => $_has(63);
  @$pb.TagNumber(73)
  void clearLogUnsubscribe() => $_clearField(73);
  @$pb.TagNumber(73)
  $19.ReqLogUnsubscribe ensureLogUnsubscribe() => $_ensure(63);

  @$pb.TagNumber(74)
  $8.ReqMentionList get mentionList => $_getN(64);
  @$pb.TagNumber(74)
  set mentionList($8.ReqMentionList value) => $_setField(74, value);
  @$pb.TagNumber(74)
  $core.bool hasMentionList() => $_has(64);
  @$pb.TagNumber(74)
  void clearMentionList() => $_clearField(74);
  @$pb.TagNumber(74)
  $8.ReqMentionList ensureMentionList() => $_ensure(64);

  @$pb.TagNumber(75)
  $8.ReqMentionSearch get mentionSearch => $_getN(65);
  @$pb.TagNumber(75)
  set mentionSearch($8.ReqMentionSearch value) => $_setField(75, value);
  @$pb.TagNumber(75)
  $core.bool hasMentionSearch() => $_has(65);
  @$pb.TagNumber(75)
  void clearMentionSearch() => $_clearField(75);
  @$pb.TagNumber(75)
  $8.ReqMentionSearch ensureMentionSearch() => $_ensure(65);

  @$pb.TagNumber(76)
  $20.ReqHintTouch get hintTouch => $_getN(66);
  @$pb.TagNumber(76)
  set hintTouch($20.ReqHintTouch value) => $_setField(76, value);
  @$pb.TagNumber(76)
  $core.bool hasHintTouch() => $_has(66);
  @$pb.TagNumber(76)
  void clearHintTouch() => $_clearField(76);
  @$pb.TagNumber(76)
  $20.ReqHintTouch ensureHintTouch() => $_ensure(66);

  @$pb.TagNumber(77)
  $13.ReqSiteConfigPut get siteConfigPut => $_getN(67);
  @$pb.TagNumber(77)
  set siteConfigPut($13.ReqSiteConfigPut value) => $_setField(77, value);
  @$pb.TagNumber(77)
  $core.bool hasSiteConfigPut() => $_has(67);
  @$pb.TagNumber(77)
  void clearSiteConfigPut() => $_clearField(77);
  @$pb.TagNumber(77)
  $13.ReqSiteConfigPut ensureSiteConfigPut() => $_ensure(67);
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
  taskList,
  taskPut,
  taskRunStart,
  taskRunCancel,
  taskRunList,
  invoke,
  taskRunPush,
  syncPush,
  billingBalance,
  billingQuota,
  billingCommission,
  logPush,
  channelPairPush,
  statsPush,
  skillList,
  consumptionList,
  siteList,
  txList,
  consumptionPut,
  chatPatch,
  assetTagList,
  logList,
  identityPut,
  remoteSessionStart,
  remoteSessionStop,
  remoteSessionPush,
  channelDisconnect,
  identityDelete,
  skillPut,
  skillCatalogList,
  skillCatalogInstall,
  remoteIceConfig,
  rtcSignalOffer,
  rtcSignalAnswer,
  rtcSignalIce,
  collectionDefList,
  siteDraftGet,
  siteDraftPut,
  sitePublish,
  siteProductList,
  siteProductPut,
  siteContactList,
  siteContactPut,
  siteObjectList,
  siteObjectPut,
  siteDomainList,
  siteDomainPut,
  skillCatalogSearch,
  skillCatalogSubmit,
  skillRunReport,
  resRemoteScreenshot,
  resRemoteCommand,
  voiceStt,
  voiceTts,
  mentionList,
  mentionSearch,
  hintTouch,
  promptRunPush,
  siteConfigPut,
  notSet
}

/// WebSocket server → client
class WsRes extends $pb.GeneratedMessage {
  factory WsRes({
    $core.String? reqId,
    $21.Err? err,
    $9.ResSessionInit? sessionInit,
    $10.ResSync? sync,
    $11.ResInboxList? inboxList,
    $11.ResChatMsgList? chatMsgList,
    $11.ResPromptStart? promptStart,
    $11.ResPromptDelta? promptDelta,
    $11.ResPromptEnd? promptEnd,
    $11.ResPromptFail? promptFail,
    $15.ResIdentityList? identityList,
    $15.ResIdentityGrantPatch? identityGrantPatch,
    $11.ResBotPeerList? botPeerList,
    $11.ResChatStop? chatStop,
    $11.ResChatSend? chatSend,
    $4.ResChannelWhatsappPair? channelWhatsappPairStart,
    $4.ResChannelWhatsappPair? channelWhatsappPairWatch,
    $4.ResChannelWhatsappPair? channelWhatsappPairAbort,
    $16.ResTaskList? taskList,
    $16.ResTaskPut? taskPut,
    $16.ResTaskRunStart? taskRunStart,
    $16.ResTaskRunCancel? taskRunCancel,
    $16.ResTaskRunList? taskRunList,
    InvokeRes? invoke,
    $16.TaskRunPush? taskRunPush,
    $10.SyncPush? syncPush,
    $0.BillingPushBalance? billingBalance,
    $0.BillingPushQuota? billingQuota,
    $0.BillingPushCommission? billingCommission,
    $22.LogPush? logPush,
    $4.ChannelPairPush? channelPairPush,
    $19.StatsPush? statsPush,
    $12.ResSkillList? skillList,
    $1.ResConsumptionList? consumptionList,
    $13.ResSiteList? siteList,
    $14.ResTxList? txList,
    $1.ResConsumptionPut? consumptionPut,
    $11.ResChatPatch? chatPatch,
    $11.ResAssetTagList? assetTagList,
    $11.ResLogList? logList,
    $15.ResIdentityPut? identityPut,
    $17.ResRemoteSessionStart? remoteSessionStart,
    $17.ResRemoteSessionStop? remoteSessionStop,
    $17.RemoteSessionPush? remoteSessionPush,
    $4.ResChannelDisconnect? channelDisconnect,
    $15.ResIdentityDelete? identityDelete,
    $12.ResSkillPut? skillPut,
    $12.ResSkillCatalogList? skillCatalogList,
    $12.ResSkillCatalogInstall? skillCatalogInstall,
    $17.ResRemoteIceConfig? remoteIceConfig,
    $17.RtcSignalOffer? rtcSignalOffer,
    $17.RtcSignalAnswer? rtcSignalAnswer,
    $17.RtcSignalIce? rtcSignalIce,
    $18.ResCollectionDefList? collectionDefList,
    $13.ResSiteDraftGet? siteDraftGet,
    $13.ResSiteDraftPut? siteDraftPut,
    $13.ResSitePublish? sitePublish,
    $13.ResSiteProductList? siteProductList,
    $13.ResSiteProductPut? siteProductPut,
    $13.ResSiteContactList? siteContactList,
    $13.ResSiteContactPut? siteContactPut,
    $13.ResSiteObjectList? siteObjectList,
    $13.ResSiteObjectPut? siteObjectPut,
    $13.ResSiteDomainList? siteDomainList,
    $13.ResSiteDomainPut? siteDomainPut,
    $12.ResSkillCatalogSearch? skillCatalogSearch,
    $12.ResSkillCatalogSubmit? skillCatalogSubmit,
    $12.ResSkillRunReport? skillRunReport,
    $17.ResRemoteScreenshot? resRemoteScreenshot,
    $17.ResRemoteCommand? resRemoteCommand,
    $7.ResVoiceStt? voiceStt,
    $7.ResVoiceTts? voiceTts,
    $8.ResMentionList? mentionList,
    $8.ResMentionSearch? mentionSearch,
    $20.ResHintTouch? hintTouch,
    $11.PromptRunPush? promptRunPush,
    $13.ResSiteConfigPut? siteConfigPut,
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
    if (taskList != null) result.taskList = taskList;
    if (taskPut != null) result.taskPut = taskPut;
    if (taskRunStart != null) result.taskRunStart = taskRunStart;
    if (taskRunCancel != null) result.taskRunCancel = taskRunCancel;
    if (taskRunList != null) result.taskRunList = taskRunList;
    if (invoke != null) result.invoke = invoke;
    if (taskRunPush != null) result.taskRunPush = taskRunPush;
    if (syncPush != null) result.syncPush = syncPush;
    if (billingBalance != null) result.billingBalance = billingBalance;
    if (billingQuota != null) result.billingQuota = billingQuota;
    if (billingCommission != null) result.billingCommission = billingCommission;
    if (logPush != null) result.logPush = logPush;
    if (channelPairPush != null) result.channelPairPush = channelPairPush;
    if (statsPush != null) result.statsPush = statsPush;
    if (skillList != null) result.skillList = skillList;
    if (consumptionList != null) result.consumptionList = consumptionList;
    if (siteList != null) result.siteList = siteList;
    if (txList != null) result.txList = txList;
    if (consumptionPut != null) result.consumptionPut = consumptionPut;
    if (chatPatch != null) result.chatPatch = chatPatch;
    if (assetTagList != null) result.assetTagList = assetTagList;
    if (logList != null) result.logList = logList;
    if (identityPut != null) result.identityPut = identityPut;
    if (remoteSessionStart != null)
      result.remoteSessionStart = remoteSessionStart;
    if (remoteSessionStop != null) result.remoteSessionStop = remoteSessionStop;
    if (remoteSessionPush != null) result.remoteSessionPush = remoteSessionPush;
    if (channelDisconnect != null) result.channelDisconnect = channelDisconnect;
    if (identityDelete != null) result.identityDelete = identityDelete;
    if (skillPut != null) result.skillPut = skillPut;
    if (skillCatalogList != null) result.skillCatalogList = skillCatalogList;
    if (skillCatalogInstall != null)
      result.skillCatalogInstall = skillCatalogInstall;
    if (remoteIceConfig != null) result.remoteIceConfig = remoteIceConfig;
    if (rtcSignalOffer != null) result.rtcSignalOffer = rtcSignalOffer;
    if (rtcSignalAnswer != null) result.rtcSignalAnswer = rtcSignalAnswer;
    if (rtcSignalIce != null) result.rtcSignalIce = rtcSignalIce;
    if (collectionDefList != null) result.collectionDefList = collectionDefList;
    if (siteDraftGet != null) result.siteDraftGet = siteDraftGet;
    if (siteDraftPut != null) result.siteDraftPut = siteDraftPut;
    if (sitePublish != null) result.sitePublish = sitePublish;
    if (siteProductList != null) result.siteProductList = siteProductList;
    if (siteProductPut != null) result.siteProductPut = siteProductPut;
    if (siteContactList != null) result.siteContactList = siteContactList;
    if (siteContactPut != null) result.siteContactPut = siteContactPut;
    if (siteObjectList != null) result.siteObjectList = siteObjectList;
    if (siteObjectPut != null) result.siteObjectPut = siteObjectPut;
    if (siteDomainList != null) result.siteDomainList = siteDomainList;
    if (siteDomainPut != null) result.siteDomainPut = siteDomainPut;
    if (skillCatalogSearch != null)
      result.skillCatalogSearch = skillCatalogSearch;
    if (skillCatalogSubmit != null)
      result.skillCatalogSubmit = skillCatalogSubmit;
    if (skillRunReport != null) result.skillRunReport = skillRunReport;
    if (resRemoteScreenshot != null)
      result.resRemoteScreenshot = resRemoteScreenshot;
    if (resRemoteCommand != null) result.resRemoteCommand = resRemoteCommand;
    if (voiceStt != null) result.voiceStt = voiceStt;
    if (voiceTts != null) result.voiceTts = voiceTts;
    if (mentionList != null) result.mentionList = mentionList;
    if (mentionSearch != null) result.mentionSearch = mentionSearch;
    if (hintTouch != null) result.hintTouch = hintTouch;
    if (promptRunPush != null) result.promptRunPush = promptRunPush;
    if (siteConfigPut != null) result.siteConfigPut = siteConfigPut;
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
    35: WsRes_Body.taskList,
    36: WsRes_Body.taskPut,
    37: WsRes_Body.taskRunStart,
    38: WsRes_Body.taskRunCancel,
    39: WsRes_Body.taskRunList,
    40: WsRes_Body.invoke,
    45: WsRes_Body.taskRunPush,
    50: WsRes_Body.syncPush,
    60: WsRes_Body.billingBalance,
    61: WsRes_Body.billingQuota,
    62: WsRes_Body.billingCommission,
    70: WsRes_Body.logPush,
    71: WsRes_Body.channelPairPush,
    72: WsRes_Body.statsPush,
    80: WsRes_Body.skillList,
    81: WsRes_Body.consumptionList,
    82: WsRes_Body.siteList,
    83: WsRes_Body.txList,
    84: WsRes_Body.consumptionPut,
    85: WsRes_Body.chatPatch,
    86: WsRes_Body.assetTagList,
    87: WsRes_Body.logList,
    88: WsRes_Body.identityPut,
    90: WsRes_Body.remoteSessionStart,
    91: WsRes_Body.remoteSessionStop,
    92: WsRes_Body.remoteSessionPush,
    93: WsRes_Body.channelDisconnect,
    94: WsRes_Body.identityDelete,
    95: WsRes_Body.skillPut,
    96: WsRes_Body.skillCatalogList,
    97: WsRes_Body.skillCatalogInstall,
    98: WsRes_Body.remoteIceConfig,
    99: WsRes_Body.rtcSignalOffer,
    100: WsRes_Body.rtcSignalAnswer,
    101: WsRes_Body.rtcSignalIce,
    102: WsRes_Body.collectionDefList,
    103: WsRes_Body.siteDraftGet,
    104: WsRes_Body.siteDraftPut,
    105: WsRes_Body.sitePublish,
    106: WsRes_Body.siteProductList,
    107: WsRes_Body.siteProductPut,
    108: WsRes_Body.siteContactList,
    109: WsRes_Body.siteContactPut,
    110: WsRes_Body.siteObjectList,
    111: WsRes_Body.siteObjectPut,
    112: WsRes_Body.siteDomainList,
    113: WsRes_Body.siteDomainPut,
    114: WsRes_Body.skillCatalogSearch,
    115: WsRes_Body.skillCatalogSubmit,
    116: WsRes_Body.skillRunReport,
    117: WsRes_Body.resRemoteScreenshot,
    118: WsRes_Body.resRemoteCommand,
    119: WsRes_Body.voiceStt,
    120: WsRes_Body.voiceTts,
    121: WsRes_Body.mentionList,
    122: WsRes_Body.mentionSearch,
    123: WsRes_Body.hintTouch,
    124: WsRes_Body.promptRunPush,
    125: WsRes_Body.siteConfigPut,
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
      35,
      36,
      37,
      38,
      39,
      40,
      45,
      50,
      60,
      61,
      62,
      70,
      71,
      72,
      80,
      81,
      82,
      83,
      84,
      85,
      86,
      87,
      88,
      90,
      91,
      92,
      93,
      94,
      95,
      96,
      97,
      98,
      99,
      100,
      101,
      102,
      103,
      104,
      105,
      106,
      107,
      108,
      109,
      110,
      111,
      112,
      113,
      114,
      115,
      116,
      117,
      118,
      119,
      120,
      121,
      122,
      123,
      124,
      125
    ])
    ..aOS(1, _omitFieldNames ? '' : 'reqId')
    ..aOM<$21.Err>(2, _omitFieldNames ? '' : 'err',
        subBuilder: $21.Err.$_createMessage)
    ..aOM<$9.ResSessionInit>(10, _omitFieldNames ? '' : 'sessionInit',
        subBuilder: $9.ResSessionInit.$_createMessage)
    ..aOM<$10.ResSync>(11, _omitFieldNames ? '' : 'sync',
        subBuilder: $10.ResSync.$_createMessage)
    ..aOM<$11.ResInboxList>(12, _omitFieldNames ? '' : 'inboxList',
        subBuilder: $11.ResInboxList.$_createMessage)
    ..aOM<$11.ResChatMsgList>(13, _omitFieldNames ? '' : 'chatMsgList',
        subBuilder: $11.ResChatMsgList.$_createMessage)
    ..aOM<$11.ResPromptStart>(20, _omitFieldNames ? '' : 'promptStart',
        subBuilder: $11.ResPromptStart.$_createMessage)
    ..aOM<$11.ResPromptDelta>(21, _omitFieldNames ? '' : 'promptDelta',
        subBuilder: $11.ResPromptDelta.$_createMessage)
    ..aOM<$11.ResPromptEnd>(22, _omitFieldNames ? '' : 'promptEnd',
        subBuilder: $11.ResPromptEnd.$_createMessage)
    ..aOM<$11.ResPromptFail>(23, _omitFieldNames ? '' : 'promptFail',
        subBuilder: $11.ResPromptFail.$_createMessage)
    ..aOM<$15.ResIdentityList>(27, _omitFieldNames ? '' : 'identityList',
        subBuilder: $15.ResIdentityList.$_createMessage)
    ..aOM<$15.ResIdentityGrantPatch>(
        28, _omitFieldNames ? '' : 'identityGrantPatch',
        subBuilder: $15.ResIdentityGrantPatch.$_createMessage)
    ..aOM<$11.ResBotPeerList>(29, _omitFieldNames ? '' : 'botPeerList',
        subBuilder: $11.ResBotPeerList.$_createMessage)
    ..aOM<$11.ResChatStop>(30, _omitFieldNames ? '' : 'chatStop',
        subBuilder: $11.ResChatStop.$_createMessage)
    ..aOM<$11.ResChatSend>(31, _omitFieldNames ? '' : 'chatSend',
        subBuilder: $11.ResChatSend.$_createMessage)
    ..aOM<$4.ResChannelWhatsappPair>(
        32, _omitFieldNames ? '' : 'channelWhatsappPairStart',
        subBuilder: $4.ResChannelWhatsappPair.$_createMessage)
    ..aOM<$4.ResChannelWhatsappPair>(
        33, _omitFieldNames ? '' : 'channelWhatsappPairWatch',
        subBuilder: $4.ResChannelWhatsappPair.$_createMessage)
    ..aOM<$4.ResChannelWhatsappPair>(
        34, _omitFieldNames ? '' : 'channelWhatsappPairAbort',
        subBuilder: $4.ResChannelWhatsappPair.$_createMessage)
    ..aOM<$16.ResTaskList>(35, _omitFieldNames ? '' : 'taskList',
        subBuilder: $16.ResTaskList.$_createMessage)
    ..aOM<$16.ResTaskPut>(36, _omitFieldNames ? '' : 'taskPut',
        subBuilder: $16.ResTaskPut.$_createMessage)
    ..aOM<$16.ResTaskRunStart>(37, _omitFieldNames ? '' : 'taskRunStart',
        subBuilder: $16.ResTaskRunStart.$_createMessage)
    ..aOM<$16.ResTaskRunCancel>(38, _omitFieldNames ? '' : 'taskRunCancel',
        subBuilder: $16.ResTaskRunCancel.$_createMessage)
    ..aOM<$16.ResTaskRunList>(39, _omitFieldNames ? '' : 'taskRunList',
        subBuilder: $16.ResTaskRunList.$_createMessage)
    ..aOM<InvokeRes>(40, _omitFieldNames ? '' : 'invoke',
        subBuilder: InvokeRes.$_createMessage)
    ..aOM<$16.TaskRunPush>(45, _omitFieldNames ? '' : 'taskRunPush',
        subBuilder: $16.TaskRunPush.$_createMessage)
    ..aOM<$10.SyncPush>(50, _omitFieldNames ? '' : 'syncPush',
        subBuilder: $10.SyncPush.$_createMessage)
    ..aOM<$0.BillingPushBalance>(60, _omitFieldNames ? '' : 'billingBalance',
        subBuilder: $0.BillingPushBalance.$_createMessage)
    ..aOM<$0.BillingPushQuota>(61, _omitFieldNames ? '' : 'billingQuota',
        subBuilder: $0.BillingPushQuota.$_createMessage)
    ..aOM<$0.BillingPushCommission>(
        62, _omitFieldNames ? '' : 'billingCommission',
        subBuilder: $0.BillingPushCommission.$_createMessage)
    ..aOM<$22.LogPush>(70, _omitFieldNames ? '' : 'logPush',
        subBuilder: $22.LogPush.$_createMessage)
    ..aOM<$4.ChannelPairPush>(71, _omitFieldNames ? '' : 'channelPairPush',
        subBuilder: $4.ChannelPairPush.$_createMessage)
    ..aOM<$19.StatsPush>(72, _omitFieldNames ? '' : 'statsPush',
        subBuilder: $19.StatsPush.$_createMessage)
    ..aOM<$12.ResSkillList>(80, _omitFieldNames ? '' : 'skillList',
        subBuilder: $12.ResSkillList.$_createMessage)
    ..aOM<$1.ResConsumptionList>(81, _omitFieldNames ? '' : 'consumptionList',
        subBuilder: $1.ResConsumptionList.$_createMessage)
    ..aOM<$13.ResSiteList>(82, _omitFieldNames ? '' : 'siteList',
        subBuilder: $13.ResSiteList.$_createMessage)
    ..aOM<$14.ResTxList>(83, _omitFieldNames ? '' : 'txList',
        subBuilder: $14.ResTxList.$_createMessage)
    ..aOM<$1.ResConsumptionPut>(84, _omitFieldNames ? '' : 'consumptionPut',
        subBuilder: $1.ResConsumptionPut.$_createMessage)
    ..aOM<$11.ResChatPatch>(85, _omitFieldNames ? '' : 'chatPatch',
        subBuilder: $11.ResChatPatch.$_createMessage)
    ..aOM<$11.ResAssetTagList>(86, _omitFieldNames ? '' : 'assetTagList',
        subBuilder: $11.ResAssetTagList.$_createMessage)
    ..aOM<$11.ResLogList>(87, _omitFieldNames ? '' : 'logList',
        subBuilder: $11.ResLogList.$_createMessage)
    ..aOM<$15.ResIdentityPut>(88, _omitFieldNames ? '' : 'identityPut',
        subBuilder: $15.ResIdentityPut.$_createMessage)
    ..aOM<$17.ResRemoteSessionStart>(
        90, _omitFieldNames ? '' : 'remoteSessionStart',
        subBuilder: $17.ResRemoteSessionStart.$_createMessage)
    ..aOM<$17.ResRemoteSessionStop>(
        91, _omitFieldNames ? '' : 'remoteSessionStop',
        subBuilder: $17.ResRemoteSessionStop.$_createMessage)
    ..aOM<$17.RemoteSessionPush>(92, _omitFieldNames ? '' : 'remoteSessionPush',
        subBuilder: $17.RemoteSessionPush.$_createMessage)
    ..aOM<$4.ResChannelDisconnect>(
        93, _omitFieldNames ? '' : 'channelDisconnect',
        subBuilder: $4.ResChannelDisconnect.$_createMessage)
    ..aOM<$15.ResIdentityDelete>(94, _omitFieldNames ? '' : 'identityDelete',
        subBuilder: $15.ResIdentityDelete.$_createMessage)
    ..aOM<$12.ResSkillPut>(95, _omitFieldNames ? '' : 'skillPut',
        subBuilder: $12.ResSkillPut.$_createMessage)
    ..aOM<$12.ResSkillCatalogList>(
        96, _omitFieldNames ? '' : 'skillCatalogList',
        subBuilder: $12.ResSkillCatalogList.$_createMessage)
    ..aOM<$12.ResSkillCatalogInstall>(
        97, _omitFieldNames ? '' : 'skillCatalogInstall',
        subBuilder: $12.ResSkillCatalogInstall.$_createMessage)
    ..aOM<$17.ResRemoteIceConfig>(98, _omitFieldNames ? '' : 'remoteIceConfig',
        subBuilder: $17.ResRemoteIceConfig.$_createMessage)
    ..aOM<$17.RtcSignalOffer>(99, _omitFieldNames ? '' : 'rtcSignalOffer',
        subBuilder: $17.RtcSignalOffer.$_createMessage)
    ..aOM<$17.RtcSignalAnswer>(100, _omitFieldNames ? '' : 'rtcSignalAnswer',
        subBuilder: $17.RtcSignalAnswer.$_createMessage)
    ..aOM<$17.RtcSignalIce>(101, _omitFieldNames ? '' : 'rtcSignalIce',
        subBuilder: $17.RtcSignalIce.$_createMessage)
    ..aOM<$18.ResCollectionDefList>(
        102, _omitFieldNames ? '' : 'collectionDefList',
        subBuilder: $18.ResCollectionDefList.$_createMessage)
    ..aOM<$13.ResSiteDraftGet>(103, _omitFieldNames ? '' : 'siteDraftGet',
        subBuilder: $13.ResSiteDraftGet.$_createMessage)
    ..aOM<$13.ResSiteDraftPut>(104, _omitFieldNames ? '' : 'siteDraftPut',
        subBuilder: $13.ResSiteDraftPut.$_createMessage)
    ..aOM<$13.ResSitePublish>(105, _omitFieldNames ? '' : 'sitePublish',
        subBuilder: $13.ResSitePublish.$_createMessage)
    ..aOM<$13.ResSiteProductList>(106, _omitFieldNames ? '' : 'siteProductList',
        subBuilder: $13.ResSiteProductList.$_createMessage)
    ..aOM<$13.ResSiteProductPut>(107, _omitFieldNames ? '' : 'siteProductPut',
        subBuilder: $13.ResSiteProductPut.$_createMessage)
    ..aOM<$13.ResSiteContactList>(108, _omitFieldNames ? '' : 'siteContactList',
        subBuilder: $13.ResSiteContactList.$_createMessage)
    ..aOM<$13.ResSiteContactPut>(109, _omitFieldNames ? '' : 'siteContactPut',
        subBuilder: $13.ResSiteContactPut.$_createMessage)
    ..aOM<$13.ResSiteObjectList>(110, _omitFieldNames ? '' : 'siteObjectList',
        subBuilder: $13.ResSiteObjectList.$_createMessage)
    ..aOM<$13.ResSiteObjectPut>(111, _omitFieldNames ? '' : 'siteObjectPut',
        subBuilder: $13.ResSiteObjectPut.$_createMessage)
    ..aOM<$13.ResSiteDomainList>(112, _omitFieldNames ? '' : 'siteDomainList',
        subBuilder: $13.ResSiteDomainList.$_createMessage)
    ..aOM<$13.ResSiteDomainPut>(113, _omitFieldNames ? '' : 'siteDomainPut',
        subBuilder: $13.ResSiteDomainPut.$_createMessage)
    ..aOM<$12.ResSkillCatalogSearch>(
        114, _omitFieldNames ? '' : 'skillCatalogSearch',
        subBuilder: $12.ResSkillCatalogSearch.$_createMessage)
    ..aOM<$12.ResSkillCatalogSubmit>(
        115, _omitFieldNames ? '' : 'skillCatalogSubmit',
        subBuilder: $12.ResSkillCatalogSubmit.$_createMessage)
    ..aOM<$12.ResSkillRunReport>(116, _omitFieldNames ? '' : 'skillRunReport',
        subBuilder: $12.ResSkillRunReport.$_createMessage)
    ..aOM<$17.ResRemoteScreenshot>(
        117, _omitFieldNames ? '' : 'resRemoteScreenshot',
        subBuilder: $17.ResRemoteScreenshot.$_createMessage)
    ..aOM<$17.ResRemoteCommand>(118, _omitFieldNames ? '' : 'resRemoteCommand',
        subBuilder: $17.ResRemoteCommand.$_createMessage)
    ..aOM<$7.ResVoiceStt>(119, _omitFieldNames ? '' : 'voiceStt',
        subBuilder: $7.ResVoiceStt.$_createMessage)
    ..aOM<$7.ResVoiceTts>(120, _omitFieldNames ? '' : 'voiceTts',
        subBuilder: $7.ResVoiceTts.$_createMessage)
    ..aOM<$8.ResMentionList>(121, _omitFieldNames ? '' : 'mentionList',
        subBuilder: $8.ResMentionList.$_createMessage)
    ..aOM<$8.ResMentionSearch>(122, _omitFieldNames ? '' : 'mentionSearch',
        subBuilder: $8.ResMentionSearch.$_createMessage)
    ..aOM<$20.ResHintTouch>(123, _omitFieldNames ? '' : 'hintTouch',
        subBuilder: $20.ResHintTouch.$_createMessage)
    ..aOM<$11.PromptRunPush>(124, _omitFieldNames ? '' : 'promptRunPush',
        subBuilder: $11.PromptRunPush.$_createMessage)
    ..aOM<$13.ResSiteConfigPut>(125, _omitFieldNames ? '' : 'siteConfigPut',
        subBuilder: $13.ResSiteConfigPut.$_createMessage)
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
  @$pb.TagNumber(35)
  @$pb.TagNumber(36)
  @$pb.TagNumber(37)
  @$pb.TagNumber(38)
  @$pb.TagNumber(39)
  @$pb.TagNumber(40)
  @$pb.TagNumber(45)
  @$pb.TagNumber(50)
  @$pb.TagNumber(60)
  @$pb.TagNumber(61)
  @$pb.TagNumber(62)
  @$pb.TagNumber(70)
  @$pb.TagNumber(71)
  @$pb.TagNumber(72)
  @$pb.TagNumber(80)
  @$pb.TagNumber(81)
  @$pb.TagNumber(82)
  @$pb.TagNumber(83)
  @$pb.TagNumber(84)
  @$pb.TagNumber(85)
  @$pb.TagNumber(86)
  @$pb.TagNumber(87)
  @$pb.TagNumber(88)
  @$pb.TagNumber(90)
  @$pb.TagNumber(91)
  @$pb.TagNumber(92)
  @$pb.TagNumber(93)
  @$pb.TagNumber(94)
  @$pb.TagNumber(95)
  @$pb.TagNumber(96)
  @$pb.TagNumber(97)
  @$pb.TagNumber(98)
  @$pb.TagNumber(99)
  @$pb.TagNumber(100)
  @$pb.TagNumber(101)
  @$pb.TagNumber(102)
  @$pb.TagNumber(103)
  @$pb.TagNumber(104)
  @$pb.TagNumber(105)
  @$pb.TagNumber(106)
  @$pb.TagNumber(107)
  @$pb.TagNumber(108)
  @$pb.TagNumber(109)
  @$pb.TagNumber(110)
  @$pb.TagNumber(111)
  @$pb.TagNumber(112)
  @$pb.TagNumber(113)
  @$pb.TagNumber(114)
  @$pb.TagNumber(115)
  @$pb.TagNumber(116)
  @$pb.TagNumber(117)
  @$pb.TagNumber(118)
  @$pb.TagNumber(119)
  @$pb.TagNumber(120)
  @$pb.TagNumber(121)
  @$pb.TagNumber(122)
  @$pb.TagNumber(123)
  @$pb.TagNumber(124)
  @$pb.TagNumber(125)
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
  @$pb.TagNumber(35)
  @$pb.TagNumber(36)
  @$pb.TagNumber(37)
  @$pb.TagNumber(38)
  @$pb.TagNumber(39)
  @$pb.TagNumber(40)
  @$pb.TagNumber(45)
  @$pb.TagNumber(50)
  @$pb.TagNumber(60)
  @$pb.TagNumber(61)
  @$pb.TagNumber(62)
  @$pb.TagNumber(70)
  @$pb.TagNumber(71)
  @$pb.TagNumber(72)
  @$pb.TagNumber(80)
  @$pb.TagNumber(81)
  @$pb.TagNumber(82)
  @$pb.TagNumber(83)
  @$pb.TagNumber(84)
  @$pb.TagNumber(85)
  @$pb.TagNumber(86)
  @$pb.TagNumber(87)
  @$pb.TagNumber(88)
  @$pb.TagNumber(90)
  @$pb.TagNumber(91)
  @$pb.TagNumber(92)
  @$pb.TagNumber(93)
  @$pb.TagNumber(94)
  @$pb.TagNumber(95)
  @$pb.TagNumber(96)
  @$pb.TagNumber(97)
  @$pb.TagNumber(98)
  @$pb.TagNumber(99)
  @$pb.TagNumber(100)
  @$pb.TagNumber(101)
  @$pb.TagNumber(102)
  @$pb.TagNumber(103)
  @$pb.TagNumber(104)
  @$pb.TagNumber(105)
  @$pb.TagNumber(106)
  @$pb.TagNumber(107)
  @$pb.TagNumber(108)
  @$pb.TagNumber(109)
  @$pb.TagNumber(110)
  @$pb.TagNumber(111)
  @$pb.TagNumber(112)
  @$pb.TagNumber(113)
  @$pb.TagNumber(114)
  @$pb.TagNumber(115)
  @$pb.TagNumber(116)
  @$pb.TagNumber(117)
  @$pb.TagNumber(118)
  @$pb.TagNumber(119)
  @$pb.TagNumber(120)
  @$pb.TagNumber(121)
  @$pb.TagNumber(122)
  @$pb.TagNumber(123)
  @$pb.TagNumber(124)
  @$pb.TagNumber(125)
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
  $21.Err get err => $_getN(1);
  @$pb.TagNumber(2)
  set err($21.Err value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasErr() => $_has(1);
  @$pb.TagNumber(2)
  void clearErr() => $_clearField(2);
  @$pb.TagNumber(2)
  $21.Err ensureErr() => $_ensure(1);

  @$pb.TagNumber(10)
  $9.ResSessionInit get sessionInit => $_getN(2);
  @$pb.TagNumber(10)
  set sessionInit($9.ResSessionInit value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasSessionInit() => $_has(2);
  @$pb.TagNumber(10)
  void clearSessionInit() => $_clearField(10);
  @$pb.TagNumber(10)
  $9.ResSessionInit ensureSessionInit() => $_ensure(2);

  @$pb.TagNumber(11)
  $10.ResSync get sync => $_getN(3);
  @$pb.TagNumber(11)
  set sync($10.ResSync value) => $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasSync() => $_has(3);
  @$pb.TagNumber(11)
  void clearSync() => $_clearField(11);
  @$pb.TagNumber(11)
  $10.ResSync ensureSync() => $_ensure(3);

  @$pb.TagNumber(12)
  $11.ResInboxList get inboxList => $_getN(4);
  @$pb.TagNumber(12)
  set inboxList($11.ResInboxList value) => $_setField(12, value);
  @$pb.TagNumber(12)
  $core.bool hasInboxList() => $_has(4);
  @$pb.TagNumber(12)
  void clearInboxList() => $_clearField(12);
  @$pb.TagNumber(12)
  $11.ResInboxList ensureInboxList() => $_ensure(4);

  @$pb.TagNumber(13)
  $11.ResChatMsgList get chatMsgList => $_getN(5);
  @$pb.TagNumber(13)
  set chatMsgList($11.ResChatMsgList value) => $_setField(13, value);
  @$pb.TagNumber(13)
  $core.bool hasChatMsgList() => $_has(5);
  @$pb.TagNumber(13)
  void clearChatMsgList() => $_clearField(13);
  @$pb.TagNumber(13)
  $11.ResChatMsgList ensureChatMsgList() => $_ensure(5);

  @$pb.TagNumber(20)
  $11.ResPromptStart get promptStart => $_getN(6);
  @$pb.TagNumber(20)
  set promptStart($11.ResPromptStart value) => $_setField(20, value);
  @$pb.TagNumber(20)
  $core.bool hasPromptStart() => $_has(6);
  @$pb.TagNumber(20)
  void clearPromptStart() => $_clearField(20);
  @$pb.TagNumber(20)
  $11.ResPromptStart ensurePromptStart() => $_ensure(6);

  @$pb.TagNumber(21)
  $11.ResPromptDelta get promptDelta => $_getN(7);
  @$pb.TagNumber(21)
  set promptDelta($11.ResPromptDelta value) => $_setField(21, value);
  @$pb.TagNumber(21)
  $core.bool hasPromptDelta() => $_has(7);
  @$pb.TagNumber(21)
  void clearPromptDelta() => $_clearField(21);
  @$pb.TagNumber(21)
  $11.ResPromptDelta ensurePromptDelta() => $_ensure(7);

  @$pb.TagNumber(22)
  $11.ResPromptEnd get promptEnd => $_getN(8);
  @$pb.TagNumber(22)
  set promptEnd($11.ResPromptEnd value) => $_setField(22, value);
  @$pb.TagNumber(22)
  $core.bool hasPromptEnd() => $_has(8);
  @$pb.TagNumber(22)
  void clearPromptEnd() => $_clearField(22);
  @$pb.TagNumber(22)
  $11.ResPromptEnd ensurePromptEnd() => $_ensure(8);

  @$pb.TagNumber(23)
  $11.ResPromptFail get promptFail => $_getN(9);
  @$pb.TagNumber(23)
  set promptFail($11.ResPromptFail value) => $_setField(23, value);
  @$pb.TagNumber(23)
  $core.bool hasPromptFail() => $_has(9);
  @$pb.TagNumber(23)
  void clearPromptFail() => $_clearField(23);
  @$pb.TagNumber(23)
  $11.ResPromptFail ensurePromptFail() => $_ensure(9);

  @$pb.TagNumber(27)
  $15.ResIdentityList get identityList => $_getN(10);
  @$pb.TagNumber(27)
  set identityList($15.ResIdentityList value) => $_setField(27, value);
  @$pb.TagNumber(27)
  $core.bool hasIdentityList() => $_has(10);
  @$pb.TagNumber(27)
  void clearIdentityList() => $_clearField(27);
  @$pb.TagNumber(27)
  $15.ResIdentityList ensureIdentityList() => $_ensure(10);

  @$pb.TagNumber(28)
  $15.ResIdentityGrantPatch get identityGrantPatch => $_getN(11);
  @$pb.TagNumber(28)
  set identityGrantPatch($15.ResIdentityGrantPatch value) =>
      $_setField(28, value);
  @$pb.TagNumber(28)
  $core.bool hasIdentityGrantPatch() => $_has(11);
  @$pb.TagNumber(28)
  void clearIdentityGrantPatch() => $_clearField(28);
  @$pb.TagNumber(28)
  $15.ResIdentityGrantPatch ensureIdentityGrantPatch() => $_ensure(11);

  @$pb.TagNumber(29)
  $11.ResBotPeerList get botPeerList => $_getN(12);
  @$pb.TagNumber(29)
  set botPeerList($11.ResBotPeerList value) => $_setField(29, value);
  @$pb.TagNumber(29)
  $core.bool hasBotPeerList() => $_has(12);
  @$pb.TagNumber(29)
  void clearBotPeerList() => $_clearField(29);
  @$pb.TagNumber(29)
  $11.ResBotPeerList ensureBotPeerList() => $_ensure(12);

  @$pb.TagNumber(30)
  $11.ResChatStop get chatStop => $_getN(13);
  @$pb.TagNumber(30)
  set chatStop($11.ResChatStop value) => $_setField(30, value);
  @$pb.TagNumber(30)
  $core.bool hasChatStop() => $_has(13);
  @$pb.TagNumber(30)
  void clearChatStop() => $_clearField(30);
  @$pb.TagNumber(30)
  $11.ResChatStop ensureChatStop() => $_ensure(13);

  @$pb.TagNumber(31)
  $11.ResChatSend get chatSend => $_getN(14);
  @$pb.TagNumber(31)
  set chatSend($11.ResChatSend value) => $_setField(31, value);
  @$pb.TagNumber(31)
  $core.bool hasChatSend() => $_has(14);
  @$pb.TagNumber(31)
  void clearChatSend() => $_clearField(31);
  @$pb.TagNumber(31)
  $11.ResChatSend ensureChatSend() => $_ensure(14);

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

  @$pb.TagNumber(35)
  $16.ResTaskList get taskList => $_getN(18);
  @$pb.TagNumber(35)
  set taskList($16.ResTaskList value) => $_setField(35, value);
  @$pb.TagNumber(35)
  $core.bool hasTaskList() => $_has(18);
  @$pb.TagNumber(35)
  void clearTaskList() => $_clearField(35);
  @$pb.TagNumber(35)
  $16.ResTaskList ensureTaskList() => $_ensure(18);

  @$pb.TagNumber(36)
  $16.ResTaskPut get taskPut => $_getN(19);
  @$pb.TagNumber(36)
  set taskPut($16.ResTaskPut value) => $_setField(36, value);
  @$pb.TagNumber(36)
  $core.bool hasTaskPut() => $_has(19);
  @$pb.TagNumber(36)
  void clearTaskPut() => $_clearField(36);
  @$pb.TagNumber(36)
  $16.ResTaskPut ensureTaskPut() => $_ensure(19);

  @$pb.TagNumber(37)
  $16.ResTaskRunStart get taskRunStart => $_getN(20);
  @$pb.TagNumber(37)
  set taskRunStart($16.ResTaskRunStart value) => $_setField(37, value);
  @$pb.TagNumber(37)
  $core.bool hasTaskRunStart() => $_has(20);
  @$pb.TagNumber(37)
  void clearTaskRunStart() => $_clearField(37);
  @$pb.TagNumber(37)
  $16.ResTaskRunStart ensureTaskRunStart() => $_ensure(20);

  @$pb.TagNumber(38)
  $16.ResTaskRunCancel get taskRunCancel => $_getN(21);
  @$pb.TagNumber(38)
  set taskRunCancel($16.ResTaskRunCancel value) => $_setField(38, value);
  @$pb.TagNumber(38)
  $core.bool hasTaskRunCancel() => $_has(21);
  @$pb.TagNumber(38)
  void clearTaskRunCancel() => $_clearField(38);
  @$pb.TagNumber(38)
  $16.ResTaskRunCancel ensureTaskRunCancel() => $_ensure(21);

  @$pb.TagNumber(39)
  $16.ResTaskRunList get taskRunList => $_getN(22);
  @$pb.TagNumber(39)
  set taskRunList($16.ResTaskRunList value) => $_setField(39, value);
  @$pb.TagNumber(39)
  $core.bool hasTaskRunList() => $_has(22);
  @$pb.TagNumber(39)
  void clearTaskRunList() => $_clearField(39);
  @$pb.TagNumber(39)
  $16.ResTaskRunList ensureTaskRunList() => $_ensure(22);

  @$pb.TagNumber(40)
  InvokeRes get invoke => $_getN(23);
  @$pb.TagNumber(40)
  set invoke(InvokeRes value) => $_setField(40, value);
  @$pb.TagNumber(40)
  $core.bool hasInvoke() => $_has(23);
  @$pb.TagNumber(40)
  void clearInvoke() => $_clearField(40);
  @$pb.TagNumber(40)
  InvokeRes ensureInvoke() => $_ensure(23);

  @$pb.TagNumber(45)
  $16.TaskRunPush get taskRunPush => $_getN(24);
  @$pb.TagNumber(45)
  set taskRunPush($16.TaskRunPush value) => $_setField(45, value);
  @$pb.TagNumber(45)
  $core.bool hasTaskRunPush() => $_has(24);
  @$pb.TagNumber(45)
  void clearTaskRunPush() => $_clearField(45);
  @$pb.TagNumber(45)
  $16.TaskRunPush ensureTaskRunPush() => $_ensure(24);

  @$pb.TagNumber(50)
  $10.SyncPush get syncPush => $_getN(25);
  @$pb.TagNumber(50)
  set syncPush($10.SyncPush value) => $_setField(50, value);
  @$pb.TagNumber(50)
  $core.bool hasSyncPush() => $_has(25);
  @$pb.TagNumber(50)
  void clearSyncPush() => $_clearField(50);
  @$pb.TagNumber(50)
  $10.SyncPush ensureSyncPush() => $_ensure(25);

  @$pb.TagNumber(60)
  $0.BillingPushBalance get billingBalance => $_getN(26);
  @$pb.TagNumber(60)
  set billingBalance($0.BillingPushBalance value) => $_setField(60, value);
  @$pb.TagNumber(60)
  $core.bool hasBillingBalance() => $_has(26);
  @$pb.TagNumber(60)
  void clearBillingBalance() => $_clearField(60);
  @$pb.TagNumber(60)
  $0.BillingPushBalance ensureBillingBalance() => $_ensure(26);

  @$pb.TagNumber(61)
  $0.BillingPushQuota get billingQuota => $_getN(27);
  @$pb.TagNumber(61)
  set billingQuota($0.BillingPushQuota value) => $_setField(61, value);
  @$pb.TagNumber(61)
  $core.bool hasBillingQuota() => $_has(27);
  @$pb.TagNumber(61)
  void clearBillingQuota() => $_clearField(61);
  @$pb.TagNumber(61)
  $0.BillingPushQuota ensureBillingQuota() => $_ensure(27);

  @$pb.TagNumber(62)
  $0.BillingPushCommission get billingCommission => $_getN(28);
  @$pb.TagNumber(62)
  set billingCommission($0.BillingPushCommission value) =>
      $_setField(62, value);
  @$pb.TagNumber(62)
  $core.bool hasBillingCommission() => $_has(28);
  @$pb.TagNumber(62)
  void clearBillingCommission() => $_clearField(62);
  @$pb.TagNumber(62)
  $0.BillingPushCommission ensureBillingCommission() => $_ensure(28);

  @$pb.TagNumber(70)
  $22.LogPush get logPush => $_getN(29);
  @$pb.TagNumber(70)
  set logPush($22.LogPush value) => $_setField(70, value);
  @$pb.TagNumber(70)
  $core.bool hasLogPush() => $_has(29);
  @$pb.TagNumber(70)
  void clearLogPush() => $_clearField(70);
  @$pb.TagNumber(70)
  $22.LogPush ensureLogPush() => $_ensure(29);

  @$pb.TagNumber(71)
  $4.ChannelPairPush get channelPairPush => $_getN(30);
  @$pb.TagNumber(71)
  set channelPairPush($4.ChannelPairPush value) => $_setField(71, value);
  @$pb.TagNumber(71)
  $core.bool hasChannelPairPush() => $_has(30);
  @$pb.TagNumber(71)
  void clearChannelPairPush() => $_clearField(71);
  @$pb.TagNumber(71)
  $4.ChannelPairPush ensureChannelPairPush() => $_ensure(30);

  @$pb.TagNumber(72)
  $19.StatsPush get statsPush => $_getN(31);
  @$pb.TagNumber(72)
  set statsPush($19.StatsPush value) => $_setField(72, value);
  @$pb.TagNumber(72)
  $core.bool hasStatsPush() => $_has(31);
  @$pb.TagNumber(72)
  void clearStatsPush() => $_clearField(72);
  @$pb.TagNumber(72)
  $19.StatsPush ensureStatsPush() => $_ensure(31);

  @$pb.TagNumber(80)
  $12.ResSkillList get skillList => $_getN(32);
  @$pb.TagNumber(80)
  set skillList($12.ResSkillList value) => $_setField(80, value);
  @$pb.TagNumber(80)
  $core.bool hasSkillList() => $_has(32);
  @$pb.TagNumber(80)
  void clearSkillList() => $_clearField(80);
  @$pb.TagNumber(80)
  $12.ResSkillList ensureSkillList() => $_ensure(32);

  @$pb.TagNumber(81)
  $1.ResConsumptionList get consumptionList => $_getN(33);
  @$pb.TagNumber(81)
  set consumptionList($1.ResConsumptionList value) => $_setField(81, value);
  @$pb.TagNumber(81)
  $core.bool hasConsumptionList() => $_has(33);
  @$pb.TagNumber(81)
  void clearConsumptionList() => $_clearField(81);
  @$pb.TagNumber(81)
  $1.ResConsumptionList ensureConsumptionList() => $_ensure(33);

  @$pb.TagNumber(82)
  $13.ResSiteList get siteList => $_getN(34);
  @$pb.TagNumber(82)
  set siteList($13.ResSiteList value) => $_setField(82, value);
  @$pb.TagNumber(82)
  $core.bool hasSiteList() => $_has(34);
  @$pb.TagNumber(82)
  void clearSiteList() => $_clearField(82);
  @$pb.TagNumber(82)
  $13.ResSiteList ensureSiteList() => $_ensure(34);

  @$pb.TagNumber(83)
  $14.ResTxList get txList => $_getN(35);
  @$pb.TagNumber(83)
  set txList($14.ResTxList value) => $_setField(83, value);
  @$pb.TagNumber(83)
  $core.bool hasTxList() => $_has(35);
  @$pb.TagNumber(83)
  void clearTxList() => $_clearField(83);
  @$pb.TagNumber(83)
  $14.ResTxList ensureTxList() => $_ensure(35);

  @$pb.TagNumber(84)
  $1.ResConsumptionPut get consumptionPut => $_getN(36);
  @$pb.TagNumber(84)
  set consumptionPut($1.ResConsumptionPut value) => $_setField(84, value);
  @$pb.TagNumber(84)
  $core.bool hasConsumptionPut() => $_has(36);
  @$pb.TagNumber(84)
  void clearConsumptionPut() => $_clearField(84);
  @$pb.TagNumber(84)
  $1.ResConsumptionPut ensureConsumptionPut() => $_ensure(36);

  @$pb.TagNumber(85)
  $11.ResChatPatch get chatPatch => $_getN(37);
  @$pb.TagNumber(85)
  set chatPatch($11.ResChatPatch value) => $_setField(85, value);
  @$pb.TagNumber(85)
  $core.bool hasChatPatch() => $_has(37);
  @$pb.TagNumber(85)
  void clearChatPatch() => $_clearField(85);
  @$pb.TagNumber(85)
  $11.ResChatPatch ensureChatPatch() => $_ensure(37);

  @$pb.TagNumber(86)
  $11.ResAssetTagList get assetTagList => $_getN(38);
  @$pb.TagNumber(86)
  set assetTagList($11.ResAssetTagList value) => $_setField(86, value);
  @$pb.TagNumber(86)
  $core.bool hasAssetTagList() => $_has(38);
  @$pb.TagNumber(86)
  void clearAssetTagList() => $_clearField(86);
  @$pb.TagNumber(86)
  $11.ResAssetTagList ensureAssetTagList() => $_ensure(38);

  @$pb.TagNumber(87)
  $11.ResLogList get logList => $_getN(39);
  @$pb.TagNumber(87)
  set logList($11.ResLogList value) => $_setField(87, value);
  @$pb.TagNumber(87)
  $core.bool hasLogList() => $_has(39);
  @$pb.TagNumber(87)
  void clearLogList() => $_clearField(87);
  @$pb.TagNumber(87)
  $11.ResLogList ensureLogList() => $_ensure(39);

  @$pb.TagNumber(88)
  $15.ResIdentityPut get identityPut => $_getN(40);
  @$pb.TagNumber(88)
  set identityPut($15.ResIdentityPut value) => $_setField(88, value);
  @$pb.TagNumber(88)
  $core.bool hasIdentityPut() => $_has(40);
  @$pb.TagNumber(88)
  void clearIdentityPut() => $_clearField(88);
  @$pb.TagNumber(88)
  $15.ResIdentityPut ensureIdentityPut() => $_ensure(40);

  @$pb.TagNumber(90)
  $17.ResRemoteSessionStart get remoteSessionStart => $_getN(41);
  @$pb.TagNumber(90)
  set remoteSessionStart($17.ResRemoteSessionStart value) =>
      $_setField(90, value);
  @$pb.TagNumber(90)
  $core.bool hasRemoteSessionStart() => $_has(41);
  @$pb.TagNumber(90)
  void clearRemoteSessionStart() => $_clearField(90);
  @$pb.TagNumber(90)
  $17.ResRemoteSessionStart ensureRemoteSessionStart() => $_ensure(41);

  @$pb.TagNumber(91)
  $17.ResRemoteSessionStop get remoteSessionStop => $_getN(42);
  @$pb.TagNumber(91)
  set remoteSessionStop($17.ResRemoteSessionStop value) =>
      $_setField(91, value);
  @$pb.TagNumber(91)
  $core.bool hasRemoteSessionStop() => $_has(42);
  @$pb.TagNumber(91)
  void clearRemoteSessionStop() => $_clearField(91);
  @$pb.TagNumber(91)
  $17.ResRemoteSessionStop ensureRemoteSessionStop() => $_ensure(42);

  @$pb.TagNumber(92)
  $17.RemoteSessionPush get remoteSessionPush => $_getN(43);
  @$pb.TagNumber(92)
  set remoteSessionPush($17.RemoteSessionPush value) => $_setField(92, value);
  @$pb.TagNumber(92)
  $core.bool hasRemoteSessionPush() => $_has(43);
  @$pb.TagNumber(92)
  void clearRemoteSessionPush() => $_clearField(92);
  @$pb.TagNumber(92)
  $17.RemoteSessionPush ensureRemoteSessionPush() => $_ensure(43);

  @$pb.TagNumber(93)
  $4.ResChannelDisconnect get channelDisconnect => $_getN(44);
  @$pb.TagNumber(93)
  set channelDisconnect($4.ResChannelDisconnect value) => $_setField(93, value);
  @$pb.TagNumber(93)
  $core.bool hasChannelDisconnect() => $_has(44);
  @$pb.TagNumber(93)
  void clearChannelDisconnect() => $_clearField(93);
  @$pb.TagNumber(93)
  $4.ResChannelDisconnect ensureChannelDisconnect() => $_ensure(44);

  @$pb.TagNumber(94)
  $15.ResIdentityDelete get identityDelete => $_getN(45);
  @$pb.TagNumber(94)
  set identityDelete($15.ResIdentityDelete value) => $_setField(94, value);
  @$pb.TagNumber(94)
  $core.bool hasIdentityDelete() => $_has(45);
  @$pb.TagNumber(94)
  void clearIdentityDelete() => $_clearField(94);
  @$pb.TagNumber(94)
  $15.ResIdentityDelete ensureIdentityDelete() => $_ensure(45);

  @$pb.TagNumber(95)
  $12.ResSkillPut get skillPut => $_getN(46);
  @$pb.TagNumber(95)
  set skillPut($12.ResSkillPut value) => $_setField(95, value);
  @$pb.TagNumber(95)
  $core.bool hasSkillPut() => $_has(46);
  @$pb.TagNumber(95)
  void clearSkillPut() => $_clearField(95);
  @$pb.TagNumber(95)
  $12.ResSkillPut ensureSkillPut() => $_ensure(46);

  @$pb.TagNumber(96)
  $12.ResSkillCatalogList get skillCatalogList => $_getN(47);
  @$pb.TagNumber(96)
  set skillCatalogList($12.ResSkillCatalogList value) => $_setField(96, value);
  @$pb.TagNumber(96)
  $core.bool hasSkillCatalogList() => $_has(47);
  @$pb.TagNumber(96)
  void clearSkillCatalogList() => $_clearField(96);
  @$pb.TagNumber(96)
  $12.ResSkillCatalogList ensureSkillCatalogList() => $_ensure(47);

  @$pb.TagNumber(97)
  $12.ResSkillCatalogInstall get skillCatalogInstall => $_getN(48);
  @$pb.TagNumber(97)
  set skillCatalogInstall($12.ResSkillCatalogInstall value) =>
      $_setField(97, value);
  @$pb.TagNumber(97)
  $core.bool hasSkillCatalogInstall() => $_has(48);
  @$pb.TagNumber(97)
  void clearSkillCatalogInstall() => $_clearField(97);
  @$pb.TagNumber(97)
  $12.ResSkillCatalogInstall ensureSkillCatalogInstall() => $_ensure(48);

  @$pb.TagNumber(98)
  $17.ResRemoteIceConfig get remoteIceConfig => $_getN(49);
  @$pb.TagNumber(98)
  set remoteIceConfig($17.ResRemoteIceConfig value) => $_setField(98, value);
  @$pb.TagNumber(98)
  $core.bool hasRemoteIceConfig() => $_has(49);
  @$pb.TagNumber(98)
  void clearRemoteIceConfig() => $_clearField(98);
  @$pb.TagNumber(98)
  $17.ResRemoteIceConfig ensureRemoteIceConfig() => $_ensure(49);

  @$pb.TagNumber(99)
  $17.RtcSignalOffer get rtcSignalOffer => $_getN(50);
  @$pb.TagNumber(99)
  set rtcSignalOffer($17.RtcSignalOffer value) => $_setField(99, value);
  @$pb.TagNumber(99)
  $core.bool hasRtcSignalOffer() => $_has(50);
  @$pb.TagNumber(99)
  void clearRtcSignalOffer() => $_clearField(99);
  @$pb.TagNumber(99)
  $17.RtcSignalOffer ensureRtcSignalOffer() => $_ensure(50);

  @$pb.TagNumber(100)
  $17.RtcSignalAnswer get rtcSignalAnswer => $_getN(51);
  @$pb.TagNumber(100)
  set rtcSignalAnswer($17.RtcSignalAnswer value) => $_setField(100, value);
  @$pb.TagNumber(100)
  $core.bool hasRtcSignalAnswer() => $_has(51);
  @$pb.TagNumber(100)
  void clearRtcSignalAnswer() => $_clearField(100);
  @$pb.TagNumber(100)
  $17.RtcSignalAnswer ensureRtcSignalAnswer() => $_ensure(51);

  @$pb.TagNumber(101)
  $17.RtcSignalIce get rtcSignalIce => $_getN(52);
  @$pb.TagNumber(101)
  set rtcSignalIce($17.RtcSignalIce value) => $_setField(101, value);
  @$pb.TagNumber(101)
  $core.bool hasRtcSignalIce() => $_has(52);
  @$pb.TagNumber(101)
  void clearRtcSignalIce() => $_clearField(101);
  @$pb.TagNumber(101)
  $17.RtcSignalIce ensureRtcSignalIce() => $_ensure(52);

  @$pb.TagNumber(102)
  $18.ResCollectionDefList get collectionDefList => $_getN(53);
  @$pb.TagNumber(102)
  set collectionDefList($18.ResCollectionDefList value) =>
      $_setField(102, value);
  @$pb.TagNumber(102)
  $core.bool hasCollectionDefList() => $_has(53);
  @$pb.TagNumber(102)
  void clearCollectionDefList() => $_clearField(102);
  @$pb.TagNumber(102)
  $18.ResCollectionDefList ensureCollectionDefList() => $_ensure(53);

  @$pb.TagNumber(103)
  $13.ResSiteDraftGet get siteDraftGet => $_getN(54);
  @$pb.TagNumber(103)
  set siteDraftGet($13.ResSiteDraftGet value) => $_setField(103, value);
  @$pb.TagNumber(103)
  $core.bool hasSiteDraftGet() => $_has(54);
  @$pb.TagNumber(103)
  void clearSiteDraftGet() => $_clearField(103);
  @$pb.TagNumber(103)
  $13.ResSiteDraftGet ensureSiteDraftGet() => $_ensure(54);

  @$pb.TagNumber(104)
  $13.ResSiteDraftPut get siteDraftPut => $_getN(55);
  @$pb.TagNumber(104)
  set siteDraftPut($13.ResSiteDraftPut value) => $_setField(104, value);
  @$pb.TagNumber(104)
  $core.bool hasSiteDraftPut() => $_has(55);
  @$pb.TagNumber(104)
  void clearSiteDraftPut() => $_clearField(104);
  @$pb.TagNumber(104)
  $13.ResSiteDraftPut ensureSiteDraftPut() => $_ensure(55);

  @$pb.TagNumber(105)
  $13.ResSitePublish get sitePublish => $_getN(56);
  @$pb.TagNumber(105)
  set sitePublish($13.ResSitePublish value) => $_setField(105, value);
  @$pb.TagNumber(105)
  $core.bool hasSitePublish() => $_has(56);
  @$pb.TagNumber(105)
  void clearSitePublish() => $_clearField(105);
  @$pb.TagNumber(105)
  $13.ResSitePublish ensureSitePublish() => $_ensure(56);

  @$pb.TagNumber(106)
  $13.ResSiteProductList get siteProductList => $_getN(57);
  @$pb.TagNumber(106)
  set siteProductList($13.ResSiteProductList value) => $_setField(106, value);
  @$pb.TagNumber(106)
  $core.bool hasSiteProductList() => $_has(57);
  @$pb.TagNumber(106)
  void clearSiteProductList() => $_clearField(106);
  @$pb.TagNumber(106)
  $13.ResSiteProductList ensureSiteProductList() => $_ensure(57);

  @$pb.TagNumber(107)
  $13.ResSiteProductPut get siteProductPut => $_getN(58);
  @$pb.TagNumber(107)
  set siteProductPut($13.ResSiteProductPut value) => $_setField(107, value);
  @$pb.TagNumber(107)
  $core.bool hasSiteProductPut() => $_has(58);
  @$pb.TagNumber(107)
  void clearSiteProductPut() => $_clearField(107);
  @$pb.TagNumber(107)
  $13.ResSiteProductPut ensureSiteProductPut() => $_ensure(58);

  @$pb.TagNumber(108)
  $13.ResSiteContactList get siteContactList => $_getN(59);
  @$pb.TagNumber(108)
  set siteContactList($13.ResSiteContactList value) => $_setField(108, value);
  @$pb.TagNumber(108)
  $core.bool hasSiteContactList() => $_has(59);
  @$pb.TagNumber(108)
  void clearSiteContactList() => $_clearField(108);
  @$pb.TagNumber(108)
  $13.ResSiteContactList ensureSiteContactList() => $_ensure(59);

  @$pb.TagNumber(109)
  $13.ResSiteContactPut get siteContactPut => $_getN(60);
  @$pb.TagNumber(109)
  set siteContactPut($13.ResSiteContactPut value) => $_setField(109, value);
  @$pb.TagNumber(109)
  $core.bool hasSiteContactPut() => $_has(60);
  @$pb.TagNumber(109)
  void clearSiteContactPut() => $_clearField(109);
  @$pb.TagNumber(109)
  $13.ResSiteContactPut ensureSiteContactPut() => $_ensure(60);

  @$pb.TagNumber(110)
  $13.ResSiteObjectList get siteObjectList => $_getN(61);
  @$pb.TagNumber(110)
  set siteObjectList($13.ResSiteObjectList value) => $_setField(110, value);
  @$pb.TagNumber(110)
  $core.bool hasSiteObjectList() => $_has(61);
  @$pb.TagNumber(110)
  void clearSiteObjectList() => $_clearField(110);
  @$pb.TagNumber(110)
  $13.ResSiteObjectList ensureSiteObjectList() => $_ensure(61);

  @$pb.TagNumber(111)
  $13.ResSiteObjectPut get siteObjectPut => $_getN(62);
  @$pb.TagNumber(111)
  set siteObjectPut($13.ResSiteObjectPut value) => $_setField(111, value);
  @$pb.TagNumber(111)
  $core.bool hasSiteObjectPut() => $_has(62);
  @$pb.TagNumber(111)
  void clearSiteObjectPut() => $_clearField(111);
  @$pb.TagNumber(111)
  $13.ResSiteObjectPut ensureSiteObjectPut() => $_ensure(62);

  @$pb.TagNumber(112)
  $13.ResSiteDomainList get siteDomainList => $_getN(63);
  @$pb.TagNumber(112)
  set siteDomainList($13.ResSiteDomainList value) => $_setField(112, value);
  @$pb.TagNumber(112)
  $core.bool hasSiteDomainList() => $_has(63);
  @$pb.TagNumber(112)
  void clearSiteDomainList() => $_clearField(112);
  @$pb.TagNumber(112)
  $13.ResSiteDomainList ensureSiteDomainList() => $_ensure(63);

  @$pb.TagNumber(113)
  $13.ResSiteDomainPut get siteDomainPut => $_getN(64);
  @$pb.TagNumber(113)
  set siteDomainPut($13.ResSiteDomainPut value) => $_setField(113, value);
  @$pb.TagNumber(113)
  $core.bool hasSiteDomainPut() => $_has(64);
  @$pb.TagNumber(113)
  void clearSiteDomainPut() => $_clearField(113);
  @$pb.TagNumber(113)
  $13.ResSiteDomainPut ensureSiteDomainPut() => $_ensure(64);

  @$pb.TagNumber(114)
  $12.ResSkillCatalogSearch get skillCatalogSearch => $_getN(65);
  @$pb.TagNumber(114)
  set skillCatalogSearch($12.ResSkillCatalogSearch value) =>
      $_setField(114, value);
  @$pb.TagNumber(114)
  $core.bool hasSkillCatalogSearch() => $_has(65);
  @$pb.TagNumber(114)
  void clearSkillCatalogSearch() => $_clearField(114);
  @$pb.TagNumber(114)
  $12.ResSkillCatalogSearch ensureSkillCatalogSearch() => $_ensure(65);

  @$pb.TagNumber(115)
  $12.ResSkillCatalogSubmit get skillCatalogSubmit => $_getN(66);
  @$pb.TagNumber(115)
  set skillCatalogSubmit($12.ResSkillCatalogSubmit value) =>
      $_setField(115, value);
  @$pb.TagNumber(115)
  $core.bool hasSkillCatalogSubmit() => $_has(66);
  @$pb.TagNumber(115)
  void clearSkillCatalogSubmit() => $_clearField(115);
  @$pb.TagNumber(115)
  $12.ResSkillCatalogSubmit ensureSkillCatalogSubmit() => $_ensure(66);

  @$pb.TagNumber(116)
  $12.ResSkillRunReport get skillRunReport => $_getN(67);
  @$pb.TagNumber(116)
  set skillRunReport($12.ResSkillRunReport value) => $_setField(116, value);
  @$pb.TagNumber(116)
  $core.bool hasSkillRunReport() => $_has(67);
  @$pb.TagNumber(116)
  void clearSkillRunReport() => $_clearField(116);
  @$pb.TagNumber(116)
  $12.ResSkillRunReport ensureSkillRunReport() => $_ensure(67);

  @$pb.TagNumber(117)
  $17.ResRemoteScreenshot get resRemoteScreenshot => $_getN(68);
  @$pb.TagNumber(117)
  set resRemoteScreenshot($17.ResRemoteScreenshot value) =>
      $_setField(117, value);
  @$pb.TagNumber(117)
  $core.bool hasResRemoteScreenshot() => $_has(68);
  @$pb.TagNumber(117)
  void clearResRemoteScreenshot() => $_clearField(117);
  @$pb.TagNumber(117)
  $17.ResRemoteScreenshot ensureResRemoteScreenshot() => $_ensure(68);

  @$pb.TagNumber(118)
  $17.ResRemoteCommand get resRemoteCommand => $_getN(69);
  @$pb.TagNumber(118)
  set resRemoteCommand($17.ResRemoteCommand value) => $_setField(118, value);
  @$pb.TagNumber(118)
  $core.bool hasResRemoteCommand() => $_has(69);
  @$pb.TagNumber(118)
  void clearResRemoteCommand() => $_clearField(118);
  @$pb.TagNumber(118)
  $17.ResRemoteCommand ensureResRemoteCommand() => $_ensure(69);

  @$pb.TagNumber(119)
  $7.ResVoiceStt get voiceStt => $_getN(70);
  @$pb.TagNumber(119)
  set voiceStt($7.ResVoiceStt value) => $_setField(119, value);
  @$pb.TagNumber(119)
  $core.bool hasVoiceStt() => $_has(70);
  @$pb.TagNumber(119)
  void clearVoiceStt() => $_clearField(119);
  @$pb.TagNumber(119)
  $7.ResVoiceStt ensureVoiceStt() => $_ensure(70);

  @$pb.TagNumber(120)
  $7.ResVoiceTts get voiceTts => $_getN(71);
  @$pb.TagNumber(120)
  set voiceTts($7.ResVoiceTts value) => $_setField(120, value);
  @$pb.TagNumber(120)
  $core.bool hasVoiceTts() => $_has(71);
  @$pb.TagNumber(120)
  void clearVoiceTts() => $_clearField(120);
  @$pb.TagNumber(120)
  $7.ResVoiceTts ensureVoiceTts() => $_ensure(71);

  @$pb.TagNumber(121)
  $8.ResMentionList get mentionList => $_getN(72);
  @$pb.TagNumber(121)
  set mentionList($8.ResMentionList value) => $_setField(121, value);
  @$pb.TagNumber(121)
  $core.bool hasMentionList() => $_has(72);
  @$pb.TagNumber(121)
  void clearMentionList() => $_clearField(121);
  @$pb.TagNumber(121)
  $8.ResMentionList ensureMentionList() => $_ensure(72);

  @$pb.TagNumber(122)
  $8.ResMentionSearch get mentionSearch => $_getN(73);
  @$pb.TagNumber(122)
  set mentionSearch($8.ResMentionSearch value) => $_setField(122, value);
  @$pb.TagNumber(122)
  $core.bool hasMentionSearch() => $_has(73);
  @$pb.TagNumber(122)
  void clearMentionSearch() => $_clearField(122);
  @$pb.TagNumber(122)
  $8.ResMentionSearch ensureMentionSearch() => $_ensure(73);

  @$pb.TagNumber(123)
  $20.ResHintTouch get hintTouch => $_getN(74);
  @$pb.TagNumber(123)
  set hintTouch($20.ResHintTouch value) => $_setField(123, value);
  @$pb.TagNumber(123)
  $core.bool hasHintTouch() => $_has(74);
  @$pb.TagNumber(123)
  void clearHintTouch() => $_clearField(123);
  @$pb.TagNumber(123)
  $20.ResHintTouch ensureHintTouch() => $_ensure(74);

  @$pb.TagNumber(124)
  $11.PromptRunPush get promptRunPush => $_getN(75);
  @$pb.TagNumber(124)
  set promptRunPush($11.PromptRunPush value) => $_setField(124, value);
  @$pb.TagNumber(124)
  $core.bool hasPromptRunPush() => $_has(75);
  @$pb.TagNumber(124)
  void clearPromptRunPush() => $_clearField(124);
  @$pb.TagNumber(124)
  $11.PromptRunPush ensurePromptRunPush() => $_ensure(75);

  @$pb.TagNumber(125)
  $13.ResSiteConfigPut get siteConfigPut => $_getN(76);
  @$pb.TagNumber(125)
  set siteConfigPut($13.ResSiteConfigPut value) => $_setField(125, value);
  @$pb.TagNumber(125)
  $core.bool hasSiteConfigPut() => $_has(76);
  @$pb.TagNumber(125)
  void clearSiteConfigPut() => $_clearField(125);
  @$pb.TagNumber(125)
  $13.ResSiteConfigPut ensureSiteConfigPut() => $_ensure(76);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
