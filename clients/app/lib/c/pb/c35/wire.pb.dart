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
import 'chat.pb.dart' as $12;
import 'collection.pb.dart' as $19;
import 'consumption.pb.dart' as $1;
import 'device.pb.dart' as $5;
import 'hint.pb.dart' as $21;
import 'identity.pb.dart' as $16;
import 'inst.pb.dart' as $6;
import 'log.pb.dart' as $23;
import 'object.pb.dart' as $9;
import 'referral.pb.dart' as $2;
import 'remote.pb.dart' as $18;
import 'session.pb.dart' as $10;
import 'site.pb.dart' as $14;
import 'skill.pb.dart' as $13;
import 'stats.pb.dart' as $20;
import 'sync.pb.dart' as $11;
import 'task.pb.dart' as $17;
import 'tx.pb.dart' as $15;
import 'types.pb.dart' as $22;
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
  billingTopupList,
  billingTopupReview,
  commissionWithdraw,
  commissionWithdrawList,
  commissionWithdrawReview,
  referralLedgerList,
  billingReceiveAccountPut,
  billingReceiveAccountList,
  objectAliasList,
  objectAliasPut,
  objectNormalizerList,
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
    $0.ReqBillingTopupList? billingTopupList,
    $0.ReqBillingTopupReview? billingTopupReview,
    $2.ReqCommissionWithdraw? commissionWithdraw,
    $0.ReqCommissionWithdrawList? commissionWithdrawList,
    $0.ReqCommissionWithdrawReview? commissionWithdrawReview,
    $2.ReqReferralLedgerList? referralLedgerList,
    $0.ReqBillingReceiveAccountPut? billingReceiveAccountPut,
    $0.ReqBillingReceiveAccountList? billingReceiveAccountList,
    $9.ReqObjectAliasList? objectAliasList,
    $9.ReqObjectAliasPut? objectAliasPut,
    $9.ReqObjectNormalizerList? objectNormalizerList,
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
    if (billingTopupList != null) result.billingTopupList = billingTopupList;
    if (billingTopupReview != null)
      result.billingTopupReview = billingTopupReview;
    if (commissionWithdraw != null)
      result.commissionWithdraw = commissionWithdraw;
    if (commissionWithdrawList != null)
      result.commissionWithdrawList = commissionWithdrawList;
    if (commissionWithdrawReview != null)
      result.commissionWithdrawReview = commissionWithdrawReview;
    if (referralLedgerList != null)
      result.referralLedgerList = referralLedgerList;
    if (billingReceiveAccountPut != null)
      result.billingReceiveAccountPut = billingReceiveAccountPut;
    if (billingReceiveAccountList != null)
      result.billingReceiveAccountList = billingReceiveAccountList;
    if (objectAliasList != null) result.objectAliasList = objectAliasList;
    if (objectAliasPut != null) result.objectAliasPut = objectAliasPut;
    if (objectNormalizerList != null)
      result.objectNormalizerList = objectNormalizerList;
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
    111: InvokeReq_Body.billingTopupList,
    112: InvokeReq_Body.billingTopupReview,
    113: InvokeReq_Body.commissionWithdraw,
    114: InvokeReq_Body.commissionWithdrawList,
    115: InvokeReq_Body.commissionWithdrawReview,
    116: InvokeReq_Body.referralLedgerList,
    117: InvokeReq_Body.billingReceiveAccountPut,
    118: InvokeReq_Body.billingReceiveAccountList,
    119: InvokeReq_Body.objectAliasList,
    120: InvokeReq_Body.objectAliasPut,
    121: InvokeReq_Body.objectNormalizerList,
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
      121
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
    ..aOM<$0.ReqBillingTopupList>(
        111, _omitFieldNames ? '' : 'billingTopupList',
        subBuilder: $0.ReqBillingTopupList.$_createMessage)
    ..aOM<$0.ReqBillingTopupReview>(
        112, _omitFieldNames ? '' : 'billingTopupReview',
        subBuilder: $0.ReqBillingTopupReview.$_createMessage)
    ..aOM<$2.ReqCommissionWithdraw>(
        113, _omitFieldNames ? '' : 'commissionWithdraw',
        subBuilder: $2.ReqCommissionWithdraw.$_createMessage)
    ..aOM<$0.ReqCommissionWithdrawList>(
        114, _omitFieldNames ? '' : 'commissionWithdrawList',
        subBuilder: $0.ReqCommissionWithdrawList.$_createMessage)
    ..aOM<$0.ReqCommissionWithdrawReview>(
        115, _omitFieldNames ? '' : 'commissionWithdrawReview',
        subBuilder: $0.ReqCommissionWithdrawReview.$_createMessage)
    ..aOM<$2.ReqReferralLedgerList>(
        116, _omitFieldNames ? '' : 'referralLedgerList',
        subBuilder: $2.ReqReferralLedgerList.$_createMessage)
    ..aOM<$0.ReqBillingReceiveAccountPut>(
        117, _omitFieldNames ? '' : 'billingReceiveAccountPut',
        subBuilder: $0.ReqBillingReceiveAccountPut.$_createMessage)
    ..aOM<$0.ReqBillingReceiveAccountList>(
        118, _omitFieldNames ? '' : 'billingReceiveAccountList',
        subBuilder: $0.ReqBillingReceiveAccountList.$_createMessage)
    ..aOM<$9.ReqObjectAliasList>(119, _omitFieldNames ? '' : 'objectAliasList',
        subBuilder: $9.ReqObjectAliasList.$_createMessage)
    ..aOM<$9.ReqObjectAliasPut>(120, _omitFieldNames ? '' : 'objectAliasPut',
        subBuilder: $9.ReqObjectAliasPut.$_createMessage)
    ..aOM<$9.ReqObjectNormalizerList>(
        121, _omitFieldNames ? '' : 'objectNormalizerList',
        subBuilder: $9.ReqObjectNormalizerList.$_createMessage)
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

  @$pb.TagNumber(111)
  $0.ReqBillingTopupList get billingTopupList => $_getN(33);
  @$pb.TagNumber(111)
  set billingTopupList($0.ReqBillingTopupList value) => $_setField(111, value);
  @$pb.TagNumber(111)
  $core.bool hasBillingTopupList() => $_has(33);
  @$pb.TagNumber(111)
  void clearBillingTopupList() => $_clearField(111);
  @$pb.TagNumber(111)
  $0.ReqBillingTopupList ensureBillingTopupList() => $_ensure(33);

  @$pb.TagNumber(112)
  $0.ReqBillingTopupReview get billingTopupReview => $_getN(34);
  @$pb.TagNumber(112)
  set billingTopupReview($0.ReqBillingTopupReview value) =>
      $_setField(112, value);
  @$pb.TagNumber(112)
  $core.bool hasBillingTopupReview() => $_has(34);
  @$pb.TagNumber(112)
  void clearBillingTopupReview() => $_clearField(112);
  @$pb.TagNumber(112)
  $0.ReqBillingTopupReview ensureBillingTopupReview() => $_ensure(34);

  @$pb.TagNumber(113)
  $2.ReqCommissionWithdraw get commissionWithdraw => $_getN(35);
  @$pb.TagNumber(113)
  set commissionWithdraw($2.ReqCommissionWithdraw value) =>
      $_setField(113, value);
  @$pb.TagNumber(113)
  $core.bool hasCommissionWithdraw() => $_has(35);
  @$pb.TagNumber(113)
  void clearCommissionWithdraw() => $_clearField(113);
  @$pb.TagNumber(113)
  $2.ReqCommissionWithdraw ensureCommissionWithdraw() => $_ensure(35);

  @$pb.TagNumber(114)
  $0.ReqCommissionWithdrawList get commissionWithdrawList => $_getN(36);
  @$pb.TagNumber(114)
  set commissionWithdrawList($0.ReqCommissionWithdrawList value) =>
      $_setField(114, value);
  @$pb.TagNumber(114)
  $core.bool hasCommissionWithdrawList() => $_has(36);
  @$pb.TagNumber(114)
  void clearCommissionWithdrawList() => $_clearField(114);
  @$pb.TagNumber(114)
  $0.ReqCommissionWithdrawList ensureCommissionWithdrawList() => $_ensure(36);

  @$pb.TagNumber(115)
  $0.ReqCommissionWithdrawReview get commissionWithdrawReview => $_getN(37);
  @$pb.TagNumber(115)
  set commissionWithdrawReview($0.ReqCommissionWithdrawReview value) =>
      $_setField(115, value);
  @$pb.TagNumber(115)
  $core.bool hasCommissionWithdrawReview() => $_has(37);
  @$pb.TagNumber(115)
  void clearCommissionWithdrawReview() => $_clearField(115);
  @$pb.TagNumber(115)
  $0.ReqCommissionWithdrawReview ensureCommissionWithdrawReview() =>
      $_ensure(37);

  @$pb.TagNumber(116)
  $2.ReqReferralLedgerList get referralLedgerList => $_getN(38);
  @$pb.TagNumber(116)
  set referralLedgerList($2.ReqReferralLedgerList value) =>
      $_setField(116, value);
  @$pb.TagNumber(116)
  $core.bool hasReferralLedgerList() => $_has(38);
  @$pb.TagNumber(116)
  void clearReferralLedgerList() => $_clearField(116);
  @$pb.TagNumber(116)
  $2.ReqReferralLedgerList ensureReferralLedgerList() => $_ensure(38);

  @$pb.TagNumber(117)
  $0.ReqBillingReceiveAccountPut get billingReceiveAccountPut => $_getN(39);
  @$pb.TagNumber(117)
  set billingReceiveAccountPut($0.ReqBillingReceiveAccountPut value) =>
      $_setField(117, value);
  @$pb.TagNumber(117)
  $core.bool hasBillingReceiveAccountPut() => $_has(39);
  @$pb.TagNumber(117)
  void clearBillingReceiveAccountPut() => $_clearField(117);
  @$pb.TagNumber(117)
  $0.ReqBillingReceiveAccountPut ensureBillingReceiveAccountPut() =>
      $_ensure(39);

  @$pb.TagNumber(118)
  $0.ReqBillingReceiveAccountList get billingReceiveAccountList => $_getN(40);
  @$pb.TagNumber(118)
  set billingReceiveAccountList($0.ReqBillingReceiveAccountList value) =>
      $_setField(118, value);
  @$pb.TagNumber(118)
  $core.bool hasBillingReceiveAccountList() => $_has(40);
  @$pb.TagNumber(118)
  void clearBillingReceiveAccountList() => $_clearField(118);
  @$pb.TagNumber(118)
  $0.ReqBillingReceiveAccountList ensureBillingReceiveAccountList() =>
      $_ensure(40);

  @$pb.TagNumber(119)
  $9.ReqObjectAliasList get objectAliasList => $_getN(41);
  @$pb.TagNumber(119)
  set objectAliasList($9.ReqObjectAliasList value) => $_setField(119, value);
  @$pb.TagNumber(119)
  $core.bool hasObjectAliasList() => $_has(41);
  @$pb.TagNumber(119)
  void clearObjectAliasList() => $_clearField(119);
  @$pb.TagNumber(119)
  $9.ReqObjectAliasList ensureObjectAliasList() => $_ensure(41);

  @$pb.TagNumber(120)
  $9.ReqObjectAliasPut get objectAliasPut => $_getN(42);
  @$pb.TagNumber(120)
  set objectAliasPut($9.ReqObjectAliasPut value) => $_setField(120, value);
  @$pb.TagNumber(120)
  $core.bool hasObjectAliasPut() => $_has(42);
  @$pb.TagNumber(120)
  void clearObjectAliasPut() => $_clearField(120);
  @$pb.TagNumber(120)
  $9.ReqObjectAliasPut ensureObjectAliasPut() => $_ensure(42);

  @$pb.TagNumber(121)
  $9.ReqObjectNormalizerList get objectNormalizerList => $_getN(43);
  @$pb.TagNumber(121)
  set objectNormalizerList($9.ReqObjectNormalizerList value) =>
      $_setField(121, value);
  @$pb.TagNumber(121)
  $core.bool hasObjectNormalizerList() => $_has(43);
  @$pb.TagNumber(121)
  void clearObjectNormalizerList() => $_clearField(121);
  @$pb.TagNumber(121)
  $9.ReqObjectNormalizerList ensureObjectNormalizerList() => $_ensure(43);
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
  billingTopupList,
  billingTopupReview,
  commissionWithdraw,
  commissionWithdrawList,
  commissionWithdrawReview,
  referralLedgerList,
  billingReceiveAccountPut,
  billingReceiveAccountList,
  objectAliasList,
  objectAliasPut,
  objectNormalizerList,
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
    $0.ResBillingTopupList? billingTopupList,
    $0.ResBillingTopupReview? billingTopupReview,
    $2.ResCommissionWithdraw? commissionWithdraw,
    $0.ResCommissionWithdrawList? commissionWithdrawList,
    $0.ResCommissionWithdrawReview? commissionWithdrawReview,
    $2.ResReferralLedgerList? referralLedgerList,
    $0.ResBillingReceiveAccountPut? billingReceiveAccountPut,
    $0.ResBillingReceiveAccountList? billingReceiveAccountList,
    $9.ResObjectAliasList? objectAliasList,
    $9.ResObjectAliasPut? objectAliasPut,
    $9.ResObjectNormalizerList? objectNormalizerList,
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
    if (billingTopupList != null) result.billingTopupList = billingTopupList;
    if (billingTopupReview != null)
      result.billingTopupReview = billingTopupReview;
    if (commissionWithdraw != null)
      result.commissionWithdraw = commissionWithdraw;
    if (commissionWithdrawList != null)
      result.commissionWithdrawList = commissionWithdrawList;
    if (commissionWithdrawReview != null)
      result.commissionWithdrawReview = commissionWithdrawReview;
    if (referralLedgerList != null)
      result.referralLedgerList = referralLedgerList;
    if (billingReceiveAccountPut != null)
      result.billingReceiveAccountPut = billingReceiveAccountPut;
    if (billingReceiveAccountList != null)
      result.billingReceiveAccountList = billingReceiveAccountList;
    if (objectAliasList != null) result.objectAliasList = objectAliasList;
    if (objectAliasPut != null) result.objectAliasPut = objectAliasPut;
    if (objectNormalizerList != null)
      result.objectNormalizerList = objectNormalizerList;
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
    111: InvokeRes_Body.billingTopupList,
    112: InvokeRes_Body.billingTopupReview,
    113: InvokeRes_Body.commissionWithdraw,
    114: InvokeRes_Body.commissionWithdrawList,
    115: InvokeRes_Body.commissionWithdrawReview,
    116: InvokeRes_Body.referralLedgerList,
    117: InvokeRes_Body.billingReceiveAccountPut,
    118: InvokeRes_Body.billingReceiveAccountList,
    119: InvokeRes_Body.objectAliasList,
    120: InvokeRes_Body.objectAliasPut,
    121: InvokeRes_Body.objectNormalizerList,
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
      121
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
    ..aOM<$0.ResBillingTopupList>(
        111, _omitFieldNames ? '' : 'billingTopupList',
        subBuilder: $0.ResBillingTopupList.$_createMessage)
    ..aOM<$0.ResBillingTopupReview>(
        112, _omitFieldNames ? '' : 'billingTopupReview',
        subBuilder: $0.ResBillingTopupReview.$_createMessage)
    ..aOM<$2.ResCommissionWithdraw>(
        113, _omitFieldNames ? '' : 'commissionWithdraw',
        subBuilder: $2.ResCommissionWithdraw.$_createMessage)
    ..aOM<$0.ResCommissionWithdrawList>(
        114, _omitFieldNames ? '' : 'commissionWithdrawList',
        subBuilder: $0.ResCommissionWithdrawList.$_createMessage)
    ..aOM<$0.ResCommissionWithdrawReview>(
        115, _omitFieldNames ? '' : 'commissionWithdrawReview',
        subBuilder: $0.ResCommissionWithdrawReview.$_createMessage)
    ..aOM<$2.ResReferralLedgerList>(
        116, _omitFieldNames ? '' : 'referralLedgerList',
        subBuilder: $2.ResReferralLedgerList.$_createMessage)
    ..aOM<$0.ResBillingReceiveAccountPut>(
        117, _omitFieldNames ? '' : 'billingReceiveAccountPut',
        subBuilder: $0.ResBillingReceiveAccountPut.$_createMessage)
    ..aOM<$0.ResBillingReceiveAccountList>(
        118, _omitFieldNames ? '' : 'billingReceiveAccountList',
        subBuilder: $0.ResBillingReceiveAccountList.$_createMessage)
    ..aOM<$9.ResObjectAliasList>(119, _omitFieldNames ? '' : 'objectAliasList',
        subBuilder: $9.ResObjectAliasList.$_createMessage)
    ..aOM<$9.ResObjectAliasPut>(120, _omitFieldNames ? '' : 'objectAliasPut',
        subBuilder: $9.ResObjectAliasPut.$_createMessage)
    ..aOM<$9.ResObjectNormalizerList>(
        121, _omitFieldNames ? '' : 'objectNormalizerList',
        subBuilder: $9.ResObjectNormalizerList.$_createMessage)
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

  @$pb.TagNumber(111)
  $0.ResBillingTopupList get billingTopupList => $_getN(33);
  @$pb.TagNumber(111)
  set billingTopupList($0.ResBillingTopupList value) => $_setField(111, value);
  @$pb.TagNumber(111)
  $core.bool hasBillingTopupList() => $_has(33);
  @$pb.TagNumber(111)
  void clearBillingTopupList() => $_clearField(111);
  @$pb.TagNumber(111)
  $0.ResBillingTopupList ensureBillingTopupList() => $_ensure(33);

  @$pb.TagNumber(112)
  $0.ResBillingTopupReview get billingTopupReview => $_getN(34);
  @$pb.TagNumber(112)
  set billingTopupReview($0.ResBillingTopupReview value) =>
      $_setField(112, value);
  @$pb.TagNumber(112)
  $core.bool hasBillingTopupReview() => $_has(34);
  @$pb.TagNumber(112)
  void clearBillingTopupReview() => $_clearField(112);
  @$pb.TagNumber(112)
  $0.ResBillingTopupReview ensureBillingTopupReview() => $_ensure(34);

  @$pb.TagNumber(113)
  $2.ResCommissionWithdraw get commissionWithdraw => $_getN(35);
  @$pb.TagNumber(113)
  set commissionWithdraw($2.ResCommissionWithdraw value) =>
      $_setField(113, value);
  @$pb.TagNumber(113)
  $core.bool hasCommissionWithdraw() => $_has(35);
  @$pb.TagNumber(113)
  void clearCommissionWithdraw() => $_clearField(113);
  @$pb.TagNumber(113)
  $2.ResCommissionWithdraw ensureCommissionWithdraw() => $_ensure(35);

  @$pb.TagNumber(114)
  $0.ResCommissionWithdrawList get commissionWithdrawList => $_getN(36);
  @$pb.TagNumber(114)
  set commissionWithdrawList($0.ResCommissionWithdrawList value) =>
      $_setField(114, value);
  @$pb.TagNumber(114)
  $core.bool hasCommissionWithdrawList() => $_has(36);
  @$pb.TagNumber(114)
  void clearCommissionWithdrawList() => $_clearField(114);
  @$pb.TagNumber(114)
  $0.ResCommissionWithdrawList ensureCommissionWithdrawList() => $_ensure(36);

  @$pb.TagNumber(115)
  $0.ResCommissionWithdrawReview get commissionWithdrawReview => $_getN(37);
  @$pb.TagNumber(115)
  set commissionWithdrawReview($0.ResCommissionWithdrawReview value) =>
      $_setField(115, value);
  @$pb.TagNumber(115)
  $core.bool hasCommissionWithdrawReview() => $_has(37);
  @$pb.TagNumber(115)
  void clearCommissionWithdrawReview() => $_clearField(115);
  @$pb.TagNumber(115)
  $0.ResCommissionWithdrawReview ensureCommissionWithdrawReview() =>
      $_ensure(37);

  @$pb.TagNumber(116)
  $2.ResReferralLedgerList get referralLedgerList => $_getN(38);
  @$pb.TagNumber(116)
  set referralLedgerList($2.ResReferralLedgerList value) =>
      $_setField(116, value);
  @$pb.TagNumber(116)
  $core.bool hasReferralLedgerList() => $_has(38);
  @$pb.TagNumber(116)
  void clearReferralLedgerList() => $_clearField(116);
  @$pb.TagNumber(116)
  $2.ResReferralLedgerList ensureReferralLedgerList() => $_ensure(38);

  @$pb.TagNumber(117)
  $0.ResBillingReceiveAccountPut get billingReceiveAccountPut => $_getN(39);
  @$pb.TagNumber(117)
  set billingReceiveAccountPut($0.ResBillingReceiveAccountPut value) =>
      $_setField(117, value);
  @$pb.TagNumber(117)
  $core.bool hasBillingReceiveAccountPut() => $_has(39);
  @$pb.TagNumber(117)
  void clearBillingReceiveAccountPut() => $_clearField(117);
  @$pb.TagNumber(117)
  $0.ResBillingReceiveAccountPut ensureBillingReceiveAccountPut() =>
      $_ensure(39);

  @$pb.TagNumber(118)
  $0.ResBillingReceiveAccountList get billingReceiveAccountList => $_getN(40);
  @$pb.TagNumber(118)
  set billingReceiveAccountList($0.ResBillingReceiveAccountList value) =>
      $_setField(118, value);
  @$pb.TagNumber(118)
  $core.bool hasBillingReceiveAccountList() => $_has(40);
  @$pb.TagNumber(118)
  void clearBillingReceiveAccountList() => $_clearField(118);
  @$pb.TagNumber(118)
  $0.ResBillingReceiveAccountList ensureBillingReceiveAccountList() =>
      $_ensure(40);

  @$pb.TagNumber(119)
  $9.ResObjectAliasList get objectAliasList => $_getN(41);
  @$pb.TagNumber(119)
  set objectAliasList($9.ResObjectAliasList value) => $_setField(119, value);
  @$pb.TagNumber(119)
  $core.bool hasObjectAliasList() => $_has(41);
  @$pb.TagNumber(119)
  void clearObjectAliasList() => $_clearField(119);
  @$pb.TagNumber(119)
  $9.ResObjectAliasList ensureObjectAliasList() => $_ensure(41);

  @$pb.TagNumber(120)
  $9.ResObjectAliasPut get objectAliasPut => $_getN(42);
  @$pb.TagNumber(120)
  set objectAliasPut($9.ResObjectAliasPut value) => $_setField(120, value);
  @$pb.TagNumber(120)
  $core.bool hasObjectAliasPut() => $_has(42);
  @$pb.TagNumber(120)
  void clearObjectAliasPut() => $_clearField(120);
  @$pb.TagNumber(120)
  $9.ResObjectAliasPut ensureObjectAliasPut() => $_ensure(42);

  @$pb.TagNumber(121)
  $9.ResObjectNormalizerList get objectNormalizerList => $_getN(43);
  @$pb.TagNumber(121)
  set objectNormalizerList($9.ResObjectNormalizerList value) =>
      $_setField(121, value);
  @$pb.TagNumber(121)
  $core.bool hasObjectNormalizerList() => $_has(43);
  @$pb.TagNumber(121)
  void clearObjectNormalizerList() => $_clearField(121);
  @$pb.TagNumber(121)
  $9.ResObjectNormalizerList ensureObjectNormalizerList() => $_ensure(43);
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
  sitePreviewToken,
  txGet,
  txPut,
  txPreview,
  txDebtPay,
  siteQueryRun,
  notSet
}

/// WebSocket client → server
class WsReq extends $pb.GeneratedMessage {
  factory WsReq({
    $core.String? reqId,
    $10.ReqSessionInit? sessionInit,
    $11.ReqSync? sync,
    $12.ReqInboxList? inboxList,
    $12.ReqChatMsgList? chatMsgList,
    $12.ReqPrompt? prompt,
    $12.ReqPromptAbort? promptAbort,
    $12.ReqChatStop? chatStop,
    $12.ReqChatSend? chatSend,
    InvokeReq? invoke,
    $13.ReqSkillList? skillList,
    $1.ReqConsumptionList? consumptionList,
    $14.ReqSiteList? siteList,
    $15.ReqTxList? txList,
    $1.ReqConsumptionPut? consumptionPut,
    $12.ReqChatPatch? chatPatch,
    $12.ReqAssetTagList? assetTagList,
    $16.ReqIdentityList? identityList,
    $16.ReqIdentityGrantPatch? identityGrantPatch,
    $12.ReqBotPeerList? botPeerList,
    $12.ReqLogList? logList,
    $16.ReqIdentityPut? identityPut,
    $4.ReqChannelWhatsappPairStart? channelWhatsappPairStart,
    $4.ReqChannelWhatsappPairWatch? channelWhatsappPairWatch,
    $4.ReqChannelWhatsappPairAbort? channelWhatsappPairAbort,
    $17.ReqTaskList? taskList,
    $17.ReqTaskPut? taskPut,
    $17.ReqTaskRunStart? taskRunStart,
    $17.ReqTaskRunCancel? taskRunCancel,
    $17.ReqTaskRunList? taskRunList,
    $18.ReqRemoteSessionStart? remoteSessionStart,
    $18.RtcSignalOffer? rtcSignalOffer,
    $18.RtcSignalAnswer? rtcSignalAnswer,
    $18.RtcSignalIce? rtcSignalIce,
    $18.ReqRemoteSessionStop? remoteSessionStop,
    $4.ReqChannelDisconnect? channelDisconnect,
    $16.ReqIdentityDelete? identityDelete,
    $13.ReqSkillPut? skillPut,
    $13.ReqSkillCatalogList? skillCatalogList,
    $13.ReqSkillCatalogInstall? skillCatalogInstall,
    $18.ReqRemoteIceConfig? remoteIceConfig,
    $19.ReqCollectionDefList? collectionDefList,
    $14.ReqSiteDraftGet? siteDraftGet,
    $14.ReqSiteDraftPut? siteDraftPut,
    $14.ReqSitePublish? sitePublish,
    $14.ReqSiteProductList? siteProductList,
    $14.ReqSiteProductPut? siteProductPut,
    $14.ReqSiteContactList? siteContactList,
    $14.ReqSiteContactPut? siteContactPut,
    $14.ReqSiteObjectList? siteObjectList,
    $14.ReqSiteObjectPut? siteObjectPut,
    $14.ReqSiteDomainList? siteDomainList,
    $14.ReqSiteDomainPut? siteDomainPut,
    $13.ReqSkillCatalogSearch? skillCatalogSearch,
    $13.ReqSkillCatalogSubmit? skillCatalogSubmit,
    $13.ReqSkillRunReport? skillRunReport,
    $18.ReqRemoteScreenshot? reqRemoteScreenshot,
    $18.ReqRemoteCommand? reqRemoteCommand,
    $7.ReqVoiceStt? voiceStt,
    $7.ReqVoiceTts? voiceTts,
    $20.ReqStatsSubscribe? statsSubscribe,
    $20.ReqStatsUnsubscribe? statsUnsubscribe,
    $20.ReqLogSubscribe? logSubscribe,
    $20.ReqLogUnsubscribe? logUnsubscribe,
    $8.ReqMentionList? mentionList,
    $8.ReqMentionSearch? mentionSearch,
    $21.ReqHintTouch? hintTouch,
    $14.ReqSiteConfigPut? siteConfigPut,
    $14.ReqSitePreviewToken? sitePreviewToken,
    $15.ReqTxGet? txGet,
    $15.ReqTxPut? txPut,
    $15.ReqTxPreview? txPreview,
    $15.ReqTxDebtPay? txDebtPay,
    $14.ReqSiteQueryRun? siteQueryRun,
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
    if (sitePreviewToken != null) result.sitePreviewToken = sitePreviewToken;
    if (txGet != null) result.txGet = txGet;
    if (txPut != null) result.txPut = txPut;
    if (txPreview != null) result.txPreview = txPreview;
    if (txDebtPay != null) result.txDebtPay = txDebtPay;
    if (siteQueryRun != null) result.siteQueryRun = siteQueryRun;
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
    78: WsReq_Body.sitePreviewToken,
    79: WsReq_Body.txGet,
    80: WsReq_Body.txPut,
    81: WsReq_Body.txPreview,
    82: WsReq_Body.txDebtPay,
    83: WsReq_Body.siteQueryRun,
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
      77,
      78,
      79,
      80,
      81,
      82,
      83
    ])
    ..aOS(1, _omitFieldNames ? '' : 'reqId')
    ..aOM<$10.ReqSessionInit>(2, _omitFieldNames ? '' : 'sessionInit',
        subBuilder: $10.ReqSessionInit.$_createMessage)
    ..aOM<$11.ReqSync>(3, _omitFieldNames ? '' : 'sync',
        subBuilder: $11.ReqSync.$_createMessage)
    ..aOM<$12.ReqInboxList>(4, _omitFieldNames ? '' : 'inboxList',
        subBuilder: $12.ReqInboxList.$_createMessage)
    ..aOM<$12.ReqChatMsgList>(5, _omitFieldNames ? '' : 'chatMsgList',
        subBuilder: $12.ReqChatMsgList.$_createMessage)
    ..aOM<$12.ReqPrompt>(6, _omitFieldNames ? '' : 'prompt',
        subBuilder: $12.ReqPrompt.$_createMessage)
    ..aOM<$12.ReqPromptAbort>(7, _omitFieldNames ? '' : 'promptAbort',
        subBuilder: $12.ReqPromptAbort.$_createMessage)
    ..aOM<$12.ReqChatStop>(8, _omitFieldNames ? '' : 'chatStop',
        subBuilder: $12.ReqChatStop.$_createMessage)
    ..aOM<$12.ReqChatSend>(9, _omitFieldNames ? '' : 'chatSend',
        subBuilder: $12.ReqChatSend.$_createMessage)
    ..aOM<InvokeReq>(10, _omitFieldNames ? '' : 'invoke',
        subBuilder: InvokeReq.$_createMessage)
    ..aOM<$13.ReqSkillList>(20, _omitFieldNames ? '' : 'skillList',
        subBuilder: $13.ReqSkillList.$_createMessage)
    ..aOM<$1.ReqConsumptionList>(21, _omitFieldNames ? '' : 'consumptionList',
        subBuilder: $1.ReqConsumptionList.$_createMessage)
    ..aOM<$14.ReqSiteList>(22, _omitFieldNames ? '' : 'siteList',
        subBuilder: $14.ReqSiteList.$_createMessage)
    ..aOM<$15.ReqTxList>(23, _omitFieldNames ? '' : 'txList',
        subBuilder: $15.ReqTxList.$_createMessage)
    ..aOM<$1.ReqConsumptionPut>(24, _omitFieldNames ? '' : 'consumptionPut',
        subBuilder: $1.ReqConsumptionPut.$_createMessage)
    ..aOM<$12.ReqChatPatch>(25, _omitFieldNames ? '' : 'chatPatch',
        subBuilder: $12.ReqChatPatch.$_createMessage)
    ..aOM<$12.ReqAssetTagList>(26, _omitFieldNames ? '' : 'assetTagList',
        subBuilder: $12.ReqAssetTagList.$_createMessage)
    ..aOM<$16.ReqIdentityList>(27, _omitFieldNames ? '' : 'identityList',
        subBuilder: $16.ReqIdentityList.$_createMessage)
    ..aOM<$16.ReqIdentityGrantPatch>(
        28, _omitFieldNames ? '' : 'identityGrantPatch',
        subBuilder: $16.ReqIdentityGrantPatch.$_createMessage)
    ..aOM<$12.ReqBotPeerList>(29, _omitFieldNames ? '' : 'botPeerList',
        subBuilder: $12.ReqBotPeerList.$_createMessage)
    ..aOM<$12.ReqLogList>(30, _omitFieldNames ? '' : 'logList',
        subBuilder: $12.ReqLogList.$_createMessage)
    ..aOM<$16.ReqIdentityPut>(31, _omitFieldNames ? '' : 'identityPut',
        subBuilder: $16.ReqIdentityPut.$_createMessage)
    ..aOM<$4.ReqChannelWhatsappPairStart>(
        32, _omitFieldNames ? '' : 'channelWhatsappPairStart',
        subBuilder: $4.ReqChannelWhatsappPairStart.$_createMessage)
    ..aOM<$4.ReqChannelWhatsappPairWatch>(
        33, _omitFieldNames ? '' : 'channelWhatsappPairWatch',
        subBuilder: $4.ReqChannelWhatsappPairWatch.$_createMessage)
    ..aOM<$4.ReqChannelWhatsappPairAbort>(
        34, _omitFieldNames ? '' : 'channelWhatsappPairAbort',
        subBuilder: $4.ReqChannelWhatsappPairAbort.$_createMessage)
    ..aOM<$17.ReqTaskList>(35, _omitFieldNames ? '' : 'taskList',
        subBuilder: $17.ReqTaskList.$_createMessage)
    ..aOM<$17.ReqTaskPut>(36, _omitFieldNames ? '' : 'taskPut',
        subBuilder: $17.ReqTaskPut.$_createMessage)
    ..aOM<$17.ReqTaskRunStart>(37, _omitFieldNames ? '' : 'taskRunStart',
        subBuilder: $17.ReqTaskRunStart.$_createMessage)
    ..aOM<$17.ReqTaskRunCancel>(38, _omitFieldNames ? '' : 'taskRunCancel',
        subBuilder: $17.ReqTaskRunCancel.$_createMessage)
    ..aOM<$17.ReqTaskRunList>(39, _omitFieldNames ? '' : 'taskRunList',
        subBuilder: $17.ReqTaskRunList.$_createMessage)
    ..aOM<$18.ReqRemoteSessionStart>(
        40, _omitFieldNames ? '' : 'remoteSessionStart',
        subBuilder: $18.ReqRemoteSessionStart.$_createMessage)
    ..aOM<$18.RtcSignalOffer>(41, _omitFieldNames ? '' : 'rtcSignalOffer',
        subBuilder: $18.RtcSignalOffer.$_createMessage)
    ..aOM<$18.RtcSignalAnswer>(42, _omitFieldNames ? '' : 'rtcSignalAnswer',
        subBuilder: $18.RtcSignalAnswer.$_createMessage)
    ..aOM<$18.RtcSignalIce>(43, _omitFieldNames ? '' : 'rtcSignalIce',
        subBuilder: $18.RtcSignalIce.$_createMessage)
    ..aOM<$18.ReqRemoteSessionStop>(
        44, _omitFieldNames ? '' : 'remoteSessionStop',
        subBuilder: $18.ReqRemoteSessionStop.$_createMessage)
    ..aOM<$4.ReqChannelDisconnect>(
        45, _omitFieldNames ? '' : 'channelDisconnect',
        subBuilder: $4.ReqChannelDisconnect.$_createMessage)
    ..aOM<$16.ReqIdentityDelete>(46, _omitFieldNames ? '' : 'identityDelete',
        subBuilder: $16.ReqIdentityDelete.$_createMessage)
    ..aOM<$13.ReqSkillPut>(47, _omitFieldNames ? '' : 'skillPut',
        subBuilder: $13.ReqSkillPut.$_createMessage)
    ..aOM<$13.ReqSkillCatalogList>(
        48, _omitFieldNames ? '' : 'skillCatalogList',
        subBuilder: $13.ReqSkillCatalogList.$_createMessage)
    ..aOM<$13.ReqSkillCatalogInstall>(
        49, _omitFieldNames ? '' : 'skillCatalogInstall',
        subBuilder: $13.ReqSkillCatalogInstall.$_createMessage)
    ..aOM<$18.ReqRemoteIceConfig>(50, _omitFieldNames ? '' : 'remoteIceConfig',
        subBuilder: $18.ReqRemoteIceConfig.$_createMessage)
    ..aOM<$19.ReqCollectionDefList>(
        51, _omitFieldNames ? '' : 'collectionDefList',
        subBuilder: $19.ReqCollectionDefList.$_createMessage)
    ..aOM<$14.ReqSiteDraftGet>(52, _omitFieldNames ? '' : 'siteDraftGet',
        subBuilder: $14.ReqSiteDraftGet.$_createMessage)
    ..aOM<$14.ReqSiteDraftPut>(53, _omitFieldNames ? '' : 'siteDraftPut',
        subBuilder: $14.ReqSiteDraftPut.$_createMessage)
    ..aOM<$14.ReqSitePublish>(54, _omitFieldNames ? '' : 'sitePublish',
        subBuilder: $14.ReqSitePublish.$_createMessage)
    ..aOM<$14.ReqSiteProductList>(55, _omitFieldNames ? '' : 'siteProductList',
        subBuilder: $14.ReqSiteProductList.$_createMessage)
    ..aOM<$14.ReqSiteProductPut>(56, _omitFieldNames ? '' : 'siteProductPut',
        subBuilder: $14.ReqSiteProductPut.$_createMessage)
    ..aOM<$14.ReqSiteContactList>(57, _omitFieldNames ? '' : 'siteContactList',
        subBuilder: $14.ReqSiteContactList.$_createMessage)
    ..aOM<$14.ReqSiteContactPut>(58, _omitFieldNames ? '' : 'siteContactPut',
        subBuilder: $14.ReqSiteContactPut.$_createMessage)
    ..aOM<$14.ReqSiteObjectList>(59, _omitFieldNames ? '' : 'siteObjectList',
        subBuilder: $14.ReqSiteObjectList.$_createMessage)
    ..aOM<$14.ReqSiteObjectPut>(60, _omitFieldNames ? '' : 'siteObjectPut',
        subBuilder: $14.ReqSiteObjectPut.$_createMessage)
    ..aOM<$14.ReqSiteDomainList>(61, _omitFieldNames ? '' : 'siteDomainList',
        subBuilder: $14.ReqSiteDomainList.$_createMessage)
    ..aOM<$14.ReqSiteDomainPut>(62, _omitFieldNames ? '' : 'siteDomainPut',
        subBuilder: $14.ReqSiteDomainPut.$_createMessage)
    ..aOM<$13.ReqSkillCatalogSearch>(
        63, _omitFieldNames ? '' : 'skillCatalogSearch',
        subBuilder: $13.ReqSkillCatalogSearch.$_createMessage)
    ..aOM<$13.ReqSkillCatalogSubmit>(
        64, _omitFieldNames ? '' : 'skillCatalogSubmit',
        subBuilder: $13.ReqSkillCatalogSubmit.$_createMessage)
    ..aOM<$13.ReqSkillRunReport>(65, _omitFieldNames ? '' : 'skillRunReport',
        subBuilder: $13.ReqSkillRunReport.$_createMessage)
    ..aOM<$18.ReqRemoteScreenshot>(
        66, _omitFieldNames ? '' : 'reqRemoteScreenshot',
        subBuilder: $18.ReqRemoteScreenshot.$_createMessage)
    ..aOM<$18.ReqRemoteCommand>(67, _omitFieldNames ? '' : 'reqRemoteCommand',
        subBuilder: $18.ReqRemoteCommand.$_createMessage)
    ..aOM<$7.ReqVoiceStt>(68, _omitFieldNames ? '' : 'voiceStt',
        subBuilder: $7.ReqVoiceStt.$_createMessage)
    ..aOM<$7.ReqVoiceTts>(69, _omitFieldNames ? '' : 'voiceTts',
        subBuilder: $7.ReqVoiceTts.$_createMessage)
    ..aOM<$20.ReqStatsSubscribe>(70, _omitFieldNames ? '' : 'statsSubscribe',
        subBuilder: $20.ReqStatsSubscribe.$_createMessage)
    ..aOM<$20.ReqStatsUnsubscribe>(
        71, _omitFieldNames ? '' : 'statsUnsubscribe',
        subBuilder: $20.ReqStatsUnsubscribe.$_createMessage)
    ..aOM<$20.ReqLogSubscribe>(72, _omitFieldNames ? '' : 'logSubscribe',
        subBuilder: $20.ReqLogSubscribe.$_createMessage)
    ..aOM<$20.ReqLogUnsubscribe>(73, _omitFieldNames ? '' : 'logUnsubscribe',
        subBuilder: $20.ReqLogUnsubscribe.$_createMessage)
    ..aOM<$8.ReqMentionList>(74, _omitFieldNames ? '' : 'mentionList',
        subBuilder: $8.ReqMentionList.$_createMessage)
    ..aOM<$8.ReqMentionSearch>(75, _omitFieldNames ? '' : 'mentionSearch',
        subBuilder: $8.ReqMentionSearch.$_createMessage)
    ..aOM<$21.ReqHintTouch>(76, _omitFieldNames ? '' : 'hintTouch',
        subBuilder: $21.ReqHintTouch.$_createMessage)
    ..aOM<$14.ReqSiteConfigPut>(77, _omitFieldNames ? '' : 'siteConfigPut',
        subBuilder: $14.ReqSiteConfigPut.$_createMessage)
    ..aOM<$14.ReqSitePreviewToken>(
        78, _omitFieldNames ? '' : 'sitePreviewToken',
        subBuilder: $14.ReqSitePreviewToken.$_createMessage)
    ..aOM<$15.ReqTxGet>(79, _omitFieldNames ? '' : 'txGet',
        subBuilder: $15.ReqTxGet.$_createMessage)
    ..aOM<$15.ReqTxPut>(80, _omitFieldNames ? '' : 'txPut',
        subBuilder: $15.ReqTxPut.$_createMessage)
    ..aOM<$15.ReqTxPreview>(81, _omitFieldNames ? '' : 'txPreview',
        subBuilder: $15.ReqTxPreview.$_createMessage)
    ..aOM<$15.ReqTxDebtPay>(82, _omitFieldNames ? '' : 'txDebtPay',
        subBuilder: $15.ReqTxDebtPay.$_createMessage)
    ..aOM<$14.ReqSiteQueryRun>(83, _omitFieldNames ? '' : 'siteQueryRun',
        subBuilder: $14.ReqSiteQueryRun.$_createMessage)
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
  @$pb.TagNumber(78)
  @$pb.TagNumber(79)
  @$pb.TagNumber(80)
  @$pb.TagNumber(81)
  @$pb.TagNumber(82)
  @$pb.TagNumber(83)
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
  @$pb.TagNumber(78)
  @$pb.TagNumber(79)
  @$pb.TagNumber(80)
  @$pb.TagNumber(81)
  @$pb.TagNumber(82)
  @$pb.TagNumber(83)
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
  $10.ReqSessionInit get sessionInit => $_getN(1);
  @$pb.TagNumber(2)
  set sessionInit($10.ReqSessionInit value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasSessionInit() => $_has(1);
  @$pb.TagNumber(2)
  void clearSessionInit() => $_clearField(2);
  @$pb.TagNumber(2)
  $10.ReqSessionInit ensureSessionInit() => $_ensure(1);

  @$pb.TagNumber(3)
  $11.ReqSync get sync => $_getN(2);
  @$pb.TagNumber(3)
  set sync($11.ReqSync value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasSync() => $_has(2);
  @$pb.TagNumber(3)
  void clearSync() => $_clearField(3);
  @$pb.TagNumber(3)
  $11.ReqSync ensureSync() => $_ensure(2);

  @$pb.TagNumber(4)
  $12.ReqInboxList get inboxList => $_getN(3);
  @$pb.TagNumber(4)
  set inboxList($12.ReqInboxList value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasInboxList() => $_has(3);
  @$pb.TagNumber(4)
  void clearInboxList() => $_clearField(4);
  @$pb.TagNumber(4)
  $12.ReqInboxList ensureInboxList() => $_ensure(3);

  @$pb.TagNumber(5)
  $12.ReqChatMsgList get chatMsgList => $_getN(4);
  @$pb.TagNumber(5)
  set chatMsgList($12.ReqChatMsgList value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasChatMsgList() => $_has(4);
  @$pb.TagNumber(5)
  void clearChatMsgList() => $_clearField(5);
  @$pb.TagNumber(5)
  $12.ReqChatMsgList ensureChatMsgList() => $_ensure(4);

  @$pb.TagNumber(6)
  $12.ReqPrompt get prompt => $_getN(5);
  @$pb.TagNumber(6)
  set prompt($12.ReqPrompt value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasPrompt() => $_has(5);
  @$pb.TagNumber(6)
  void clearPrompt() => $_clearField(6);
  @$pb.TagNumber(6)
  $12.ReqPrompt ensurePrompt() => $_ensure(5);

  @$pb.TagNumber(7)
  $12.ReqPromptAbort get promptAbort => $_getN(6);
  @$pb.TagNumber(7)
  set promptAbort($12.ReqPromptAbort value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasPromptAbort() => $_has(6);
  @$pb.TagNumber(7)
  void clearPromptAbort() => $_clearField(7);
  @$pb.TagNumber(7)
  $12.ReqPromptAbort ensurePromptAbort() => $_ensure(6);

  @$pb.TagNumber(8)
  $12.ReqChatStop get chatStop => $_getN(7);
  @$pb.TagNumber(8)
  set chatStop($12.ReqChatStop value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasChatStop() => $_has(7);
  @$pb.TagNumber(8)
  void clearChatStop() => $_clearField(8);
  @$pb.TagNumber(8)
  $12.ReqChatStop ensureChatStop() => $_ensure(7);

  @$pb.TagNumber(9)
  $12.ReqChatSend get chatSend => $_getN(8);
  @$pb.TagNumber(9)
  set chatSend($12.ReqChatSend value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasChatSend() => $_has(8);
  @$pb.TagNumber(9)
  void clearChatSend() => $_clearField(9);
  @$pb.TagNumber(9)
  $12.ReqChatSend ensureChatSend() => $_ensure(8);

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
  $13.ReqSkillList get skillList => $_getN(10);
  @$pb.TagNumber(20)
  set skillList($13.ReqSkillList value) => $_setField(20, value);
  @$pb.TagNumber(20)
  $core.bool hasSkillList() => $_has(10);
  @$pb.TagNumber(20)
  void clearSkillList() => $_clearField(20);
  @$pb.TagNumber(20)
  $13.ReqSkillList ensureSkillList() => $_ensure(10);

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
  $14.ReqSiteList get siteList => $_getN(12);
  @$pb.TagNumber(22)
  set siteList($14.ReqSiteList value) => $_setField(22, value);
  @$pb.TagNumber(22)
  $core.bool hasSiteList() => $_has(12);
  @$pb.TagNumber(22)
  void clearSiteList() => $_clearField(22);
  @$pb.TagNumber(22)
  $14.ReqSiteList ensureSiteList() => $_ensure(12);

  @$pb.TagNumber(23)
  $15.ReqTxList get txList => $_getN(13);
  @$pb.TagNumber(23)
  set txList($15.ReqTxList value) => $_setField(23, value);
  @$pb.TagNumber(23)
  $core.bool hasTxList() => $_has(13);
  @$pb.TagNumber(23)
  void clearTxList() => $_clearField(23);
  @$pb.TagNumber(23)
  $15.ReqTxList ensureTxList() => $_ensure(13);

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
  $12.ReqChatPatch get chatPatch => $_getN(15);
  @$pb.TagNumber(25)
  set chatPatch($12.ReqChatPatch value) => $_setField(25, value);
  @$pb.TagNumber(25)
  $core.bool hasChatPatch() => $_has(15);
  @$pb.TagNumber(25)
  void clearChatPatch() => $_clearField(25);
  @$pb.TagNumber(25)
  $12.ReqChatPatch ensureChatPatch() => $_ensure(15);

  @$pb.TagNumber(26)
  $12.ReqAssetTagList get assetTagList => $_getN(16);
  @$pb.TagNumber(26)
  set assetTagList($12.ReqAssetTagList value) => $_setField(26, value);
  @$pb.TagNumber(26)
  $core.bool hasAssetTagList() => $_has(16);
  @$pb.TagNumber(26)
  void clearAssetTagList() => $_clearField(26);
  @$pb.TagNumber(26)
  $12.ReqAssetTagList ensureAssetTagList() => $_ensure(16);

  @$pb.TagNumber(27)
  $16.ReqIdentityList get identityList => $_getN(17);
  @$pb.TagNumber(27)
  set identityList($16.ReqIdentityList value) => $_setField(27, value);
  @$pb.TagNumber(27)
  $core.bool hasIdentityList() => $_has(17);
  @$pb.TagNumber(27)
  void clearIdentityList() => $_clearField(27);
  @$pb.TagNumber(27)
  $16.ReqIdentityList ensureIdentityList() => $_ensure(17);

  @$pb.TagNumber(28)
  $16.ReqIdentityGrantPatch get identityGrantPatch => $_getN(18);
  @$pb.TagNumber(28)
  set identityGrantPatch($16.ReqIdentityGrantPatch value) =>
      $_setField(28, value);
  @$pb.TagNumber(28)
  $core.bool hasIdentityGrantPatch() => $_has(18);
  @$pb.TagNumber(28)
  void clearIdentityGrantPatch() => $_clearField(28);
  @$pb.TagNumber(28)
  $16.ReqIdentityGrantPatch ensureIdentityGrantPatch() => $_ensure(18);

  @$pb.TagNumber(29)
  $12.ReqBotPeerList get botPeerList => $_getN(19);
  @$pb.TagNumber(29)
  set botPeerList($12.ReqBotPeerList value) => $_setField(29, value);
  @$pb.TagNumber(29)
  $core.bool hasBotPeerList() => $_has(19);
  @$pb.TagNumber(29)
  void clearBotPeerList() => $_clearField(29);
  @$pb.TagNumber(29)
  $12.ReqBotPeerList ensureBotPeerList() => $_ensure(19);

  @$pb.TagNumber(30)
  $12.ReqLogList get logList => $_getN(20);
  @$pb.TagNumber(30)
  set logList($12.ReqLogList value) => $_setField(30, value);
  @$pb.TagNumber(30)
  $core.bool hasLogList() => $_has(20);
  @$pb.TagNumber(30)
  void clearLogList() => $_clearField(30);
  @$pb.TagNumber(30)
  $12.ReqLogList ensureLogList() => $_ensure(20);

  @$pb.TagNumber(31)
  $16.ReqIdentityPut get identityPut => $_getN(21);
  @$pb.TagNumber(31)
  set identityPut($16.ReqIdentityPut value) => $_setField(31, value);
  @$pb.TagNumber(31)
  $core.bool hasIdentityPut() => $_has(21);
  @$pb.TagNumber(31)
  void clearIdentityPut() => $_clearField(31);
  @$pb.TagNumber(31)
  $16.ReqIdentityPut ensureIdentityPut() => $_ensure(21);

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
  $17.ReqTaskList get taskList => $_getN(25);
  @$pb.TagNumber(35)
  set taskList($17.ReqTaskList value) => $_setField(35, value);
  @$pb.TagNumber(35)
  $core.bool hasTaskList() => $_has(25);
  @$pb.TagNumber(35)
  void clearTaskList() => $_clearField(35);
  @$pb.TagNumber(35)
  $17.ReqTaskList ensureTaskList() => $_ensure(25);

  @$pb.TagNumber(36)
  $17.ReqTaskPut get taskPut => $_getN(26);
  @$pb.TagNumber(36)
  set taskPut($17.ReqTaskPut value) => $_setField(36, value);
  @$pb.TagNumber(36)
  $core.bool hasTaskPut() => $_has(26);
  @$pb.TagNumber(36)
  void clearTaskPut() => $_clearField(36);
  @$pb.TagNumber(36)
  $17.ReqTaskPut ensureTaskPut() => $_ensure(26);

  @$pb.TagNumber(37)
  $17.ReqTaskRunStart get taskRunStart => $_getN(27);
  @$pb.TagNumber(37)
  set taskRunStart($17.ReqTaskRunStart value) => $_setField(37, value);
  @$pb.TagNumber(37)
  $core.bool hasTaskRunStart() => $_has(27);
  @$pb.TagNumber(37)
  void clearTaskRunStart() => $_clearField(37);
  @$pb.TagNumber(37)
  $17.ReqTaskRunStart ensureTaskRunStart() => $_ensure(27);

  @$pb.TagNumber(38)
  $17.ReqTaskRunCancel get taskRunCancel => $_getN(28);
  @$pb.TagNumber(38)
  set taskRunCancel($17.ReqTaskRunCancel value) => $_setField(38, value);
  @$pb.TagNumber(38)
  $core.bool hasTaskRunCancel() => $_has(28);
  @$pb.TagNumber(38)
  void clearTaskRunCancel() => $_clearField(38);
  @$pb.TagNumber(38)
  $17.ReqTaskRunCancel ensureTaskRunCancel() => $_ensure(28);

  @$pb.TagNumber(39)
  $17.ReqTaskRunList get taskRunList => $_getN(29);
  @$pb.TagNumber(39)
  set taskRunList($17.ReqTaskRunList value) => $_setField(39, value);
  @$pb.TagNumber(39)
  $core.bool hasTaskRunList() => $_has(29);
  @$pb.TagNumber(39)
  void clearTaskRunList() => $_clearField(39);
  @$pb.TagNumber(39)
  $17.ReqTaskRunList ensureTaskRunList() => $_ensure(29);

  @$pb.TagNumber(40)
  $18.ReqRemoteSessionStart get remoteSessionStart => $_getN(30);
  @$pb.TagNumber(40)
  set remoteSessionStart($18.ReqRemoteSessionStart value) =>
      $_setField(40, value);
  @$pb.TagNumber(40)
  $core.bool hasRemoteSessionStart() => $_has(30);
  @$pb.TagNumber(40)
  void clearRemoteSessionStart() => $_clearField(40);
  @$pb.TagNumber(40)
  $18.ReqRemoteSessionStart ensureRemoteSessionStart() => $_ensure(30);

  @$pb.TagNumber(41)
  $18.RtcSignalOffer get rtcSignalOffer => $_getN(31);
  @$pb.TagNumber(41)
  set rtcSignalOffer($18.RtcSignalOffer value) => $_setField(41, value);
  @$pb.TagNumber(41)
  $core.bool hasRtcSignalOffer() => $_has(31);
  @$pb.TagNumber(41)
  void clearRtcSignalOffer() => $_clearField(41);
  @$pb.TagNumber(41)
  $18.RtcSignalOffer ensureRtcSignalOffer() => $_ensure(31);

  @$pb.TagNumber(42)
  $18.RtcSignalAnswer get rtcSignalAnswer => $_getN(32);
  @$pb.TagNumber(42)
  set rtcSignalAnswer($18.RtcSignalAnswer value) => $_setField(42, value);
  @$pb.TagNumber(42)
  $core.bool hasRtcSignalAnswer() => $_has(32);
  @$pb.TagNumber(42)
  void clearRtcSignalAnswer() => $_clearField(42);
  @$pb.TagNumber(42)
  $18.RtcSignalAnswer ensureRtcSignalAnswer() => $_ensure(32);

  @$pb.TagNumber(43)
  $18.RtcSignalIce get rtcSignalIce => $_getN(33);
  @$pb.TagNumber(43)
  set rtcSignalIce($18.RtcSignalIce value) => $_setField(43, value);
  @$pb.TagNumber(43)
  $core.bool hasRtcSignalIce() => $_has(33);
  @$pb.TagNumber(43)
  void clearRtcSignalIce() => $_clearField(43);
  @$pb.TagNumber(43)
  $18.RtcSignalIce ensureRtcSignalIce() => $_ensure(33);

  @$pb.TagNumber(44)
  $18.ReqRemoteSessionStop get remoteSessionStop => $_getN(34);
  @$pb.TagNumber(44)
  set remoteSessionStop($18.ReqRemoteSessionStop value) =>
      $_setField(44, value);
  @$pb.TagNumber(44)
  $core.bool hasRemoteSessionStop() => $_has(34);
  @$pb.TagNumber(44)
  void clearRemoteSessionStop() => $_clearField(44);
  @$pb.TagNumber(44)
  $18.ReqRemoteSessionStop ensureRemoteSessionStop() => $_ensure(34);

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
  $16.ReqIdentityDelete get identityDelete => $_getN(36);
  @$pb.TagNumber(46)
  set identityDelete($16.ReqIdentityDelete value) => $_setField(46, value);
  @$pb.TagNumber(46)
  $core.bool hasIdentityDelete() => $_has(36);
  @$pb.TagNumber(46)
  void clearIdentityDelete() => $_clearField(46);
  @$pb.TagNumber(46)
  $16.ReqIdentityDelete ensureIdentityDelete() => $_ensure(36);

  @$pb.TagNumber(47)
  $13.ReqSkillPut get skillPut => $_getN(37);
  @$pb.TagNumber(47)
  set skillPut($13.ReqSkillPut value) => $_setField(47, value);
  @$pb.TagNumber(47)
  $core.bool hasSkillPut() => $_has(37);
  @$pb.TagNumber(47)
  void clearSkillPut() => $_clearField(47);
  @$pb.TagNumber(47)
  $13.ReqSkillPut ensureSkillPut() => $_ensure(37);

  @$pb.TagNumber(48)
  $13.ReqSkillCatalogList get skillCatalogList => $_getN(38);
  @$pb.TagNumber(48)
  set skillCatalogList($13.ReqSkillCatalogList value) => $_setField(48, value);
  @$pb.TagNumber(48)
  $core.bool hasSkillCatalogList() => $_has(38);
  @$pb.TagNumber(48)
  void clearSkillCatalogList() => $_clearField(48);
  @$pb.TagNumber(48)
  $13.ReqSkillCatalogList ensureSkillCatalogList() => $_ensure(38);

  @$pb.TagNumber(49)
  $13.ReqSkillCatalogInstall get skillCatalogInstall => $_getN(39);
  @$pb.TagNumber(49)
  set skillCatalogInstall($13.ReqSkillCatalogInstall value) =>
      $_setField(49, value);
  @$pb.TagNumber(49)
  $core.bool hasSkillCatalogInstall() => $_has(39);
  @$pb.TagNumber(49)
  void clearSkillCatalogInstall() => $_clearField(49);
  @$pb.TagNumber(49)
  $13.ReqSkillCatalogInstall ensureSkillCatalogInstall() => $_ensure(39);

  @$pb.TagNumber(50)
  $18.ReqRemoteIceConfig get remoteIceConfig => $_getN(40);
  @$pb.TagNumber(50)
  set remoteIceConfig($18.ReqRemoteIceConfig value) => $_setField(50, value);
  @$pb.TagNumber(50)
  $core.bool hasRemoteIceConfig() => $_has(40);
  @$pb.TagNumber(50)
  void clearRemoteIceConfig() => $_clearField(50);
  @$pb.TagNumber(50)
  $18.ReqRemoteIceConfig ensureRemoteIceConfig() => $_ensure(40);

  @$pb.TagNumber(51)
  $19.ReqCollectionDefList get collectionDefList => $_getN(41);
  @$pb.TagNumber(51)
  set collectionDefList($19.ReqCollectionDefList value) =>
      $_setField(51, value);
  @$pb.TagNumber(51)
  $core.bool hasCollectionDefList() => $_has(41);
  @$pb.TagNumber(51)
  void clearCollectionDefList() => $_clearField(51);
  @$pb.TagNumber(51)
  $19.ReqCollectionDefList ensureCollectionDefList() => $_ensure(41);

  @$pb.TagNumber(52)
  $14.ReqSiteDraftGet get siteDraftGet => $_getN(42);
  @$pb.TagNumber(52)
  set siteDraftGet($14.ReqSiteDraftGet value) => $_setField(52, value);
  @$pb.TagNumber(52)
  $core.bool hasSiteDraftGet() => $_has(42);
  @$pb.TagNumber(52)
  void clearSiteDraftGet() => $_clearField(52);
  @$pb.TagNumber(52)
  $14.ReqSiteDraftGet ensureSiteDraftGet() => $_ensure(42);

  @$pb.TagNumber(53)
  $14.ReqSiteDraftPut get siteDraftPut => $_getN(43);
  @$pb.TagNumber(53)
  set siteDraftPut($14.ReqSiteDraftPut value) => $_setField(53, value);
  @$pb.TagNumber(53)
  $core.bool hasSiteDraftPut() => $_has(43);
  @$pb.TagNumber(53)
  void clearSiteDraftPut() => $_clearField(53);
  @$pb.TagNumber(53)
  $14.ReqSiteDraftPut ensureSiteDraftPut() => $_ensure(43);

  @$pb.TagNumber(54)
  $14.ReqSitePublish get sitePublish => $_getN(44);
  @$pb.TagNumber(54)
  set sitePublish($14.ReqSitePublish value) => $_setField(54, value);
  @$pb.TagNumber(54)
  $core.bool hasSitePublish() => $_has(44);
  @$pb.TagNumber(54)
  void clearSitePublish() => $_clearField(54);
  @$pb.TagNumber(54)
  $14.ReqSitePublish ensureSitePublish() => $_ensure(44);

  @$pb.TagNumber(55)
  $14.ReqSiteProductList get siteProductList => $_getN(45);
  @$pb.TagNumber(55)
  set siteProductList($14.ReqSiteProductList value) => $_setField(55, value);
  @$pb.TagNumber(55)
  $core.bool hasSiteProductList() => $_has(45);
  @$pb.TagNumber(55)
  void clearSiteProductList() => $_clearField(55);
  @$pb.TagNumber(55)
  $14.ReqSiteProductList ensureSiteProductList() => $_ensure(45);

  @$pb.TagNumber(56)
  $14.ReqSiteProductPut get siteProductPut => $_getN(46);
  @$pb.TagNumber(56)
  set siteProductPut($14.ReqSiteProductPut value) => $_setField(56, value);
  @$pb.TagNumber(56)
  $core.bool hasSiteProductPut() => $_has(46);
  @$pb.TagNumber(56)
  void clearSiteProductPut() => $_clearField(56);
  @$pb.TagNumber(56)
  $14.ReqSiteProductPut ensureSiteProductPut() => $_ensure(46);

  @$pb.TagNumber(57)
  $14.ReqSiteContactList get siteContactList => $_getN(47);
  @$pb.TagNumber(57)
  set siteContactList($14.ReqSiteContactList value) => $_setField(57, value);
  @$pb.TagNumber(57)
  $core.bool hasSiteContactList() => $_has(47);
  @$pb.TagNumber(57)
  void clearSiteContactList() => $_clearField(57);
  @$pb.TagNumber(57)
  $14.ReqSiteContactList ensureSiteContactList() => $_ensure(47);

  @$pb.TagNumber(58)
  $14.ReqSiteContactPut get siteContactPut => $_getN(48);
  @$pb.TagNumber(58)
  set siteContactPut($14.ReqSiteContactPut value) => $_setField(58, value);
  @$pb.TagNumber(58)
  $core.bool hasSiteContactPut() => $_has(48);
  @$pb.TagNumber(58)
  void clearSiteContactPut() => $_clearField(58);
  @$pb.TagNumber(58)
  $14.ReqSiteContactPut ensureSiteContactPut() => $_ensure(48);

  @$pb.TagNumber(59)
  $14.ReqSiteObjectList get siteObjectList => $_getN(49);
  @$pb.TagNumber(59)
  set siteObjectList($14.ReqSiteObjectList value) => $_setField(59, value);
  @$pb.TagNumber(59)
  $core.bool hasSiteObjectList() => $_has(49);
  @$pb.TagNumber(59)
  void clearSiteObjectList() => $_clearField(59);
  @$pb.TagNumber(59)
  $14.ReqSiteObjectList ensureSiteObjectList() => $_ensure(49);

  @$pb.TagNumber(60)
  $14.ReqSiteObjectPut get siteObjectPut => $_getN(50);
  @$pb.TagNumber(60)
  set siteObjectPut($14.ReqSiteObjectPut value) => $_setField(60, value);
  @$pb.TagNumber(60)
  $core.bool hasSiteObjectPut() => $_has(50);
  @$pb.TagNumber(60)
  void clearSiteObjectPut() => $_clearField(60);
  @$pb.TagNumber(60)
  $14.ReqSiteObjectPut ensureSiteObjectPut() => $_ensure(50);

  @$pb.TagNumber(61)
  $14.ReqSiteDomainList get siteDomainList => $_getN(51);
  @$pb.TagNumber(61)
  set siteDomainList($14.ReqSiteDomainList value) => $_setField(61, value);
  @$pb.TagNumber(61)
  $core.bool hasSiteDomainList() => $_has(51);
  @$pb.TagNumber(61)
  void clearSiteDomainList() => $_clearField(61);
  @$pb.TagNumber(61)
  $14.ReqSiteDomainList ensureSiteDomainList() => $_ensure(51);

  @$pb.TagNumber(62)
  $14.ReqSiteDomainPut get siteDomainPut => $_getN(52);
  @$pb.TagNumber(62)
  set siteDomainPut($14.ReqSiteDomainPut value) => $_setField(62, value);
  @$pb.TagNumber(62)
  $core.bool hasSiteDomainPut() => $_has(52);
  @$pb.TagNumber(62)
  void clearSiteDomainPut() => $_clearField(62);
  @$pb.TagNumber(62)
  $14.ReqSiteDomainPut ensureSiteDomainPut() => $_ensure(52);

  @$pb.TagNumber(63)
  $13.ReqSkillCatalogSearch get skillCatalogSearch => $_getN(53);
  @$pb.TagNumber(63)
  set skillCatalogSearch($13.ReqSkillCatalogSearch value) =>
      $_setField(63, value);
  @$pb.TagNumber(63)
  $core.bool hasSkillCatalogSearch() => $_has(53);
  @$pb.TagNumber(63)
  void clearSkillCatalogSearch() => $_clearField(63);
  @$pb.TagNumber(63)
  $13.ReqSkillCatalogSearch ensureSkillCatalogSearch() => $_ensure(53);

  @$pb.TagNumber(64)
  $13.ReqSkillCatalogSubmit get skillCatalogSubmit => $_getN(54);
  @$pb.TagNumber(64)
  set skillCatalogSubmit($13.ReqSkillCatalogSubmit value) =>
      $_setField(64, value);
  @$pb.TagNumber(64)
  $core.bool hasSkillCatalogSubmit() => $_has(54);
  @$pb.TagNumber(64)
  void clearSkillCatalogSubmit() => $_clearField(64);
  @$pb.TagNumber(64)
  $13.ReqSkillCatalogSubmit ensureSkillCatalogSubmit() => $_ensure(54);

  @$pb.TagNumber(65)
  $13.ReqSkillRunReport get skillRunReport => $_getN(55);
  @$pb.TagNumber(65)
  set skillRunReport($13.ReqSkillRunReport value) => $_setField(65, value);
  @$pb.TagNumber(65)
  $core.bool hasSkillRunReport() => $_has(55);
  @$pb.TagNumber(65)
  void clearSkillRunReport() => $_clearField(65);
  @$pb.TagNumber(65)
  $13.ReqSkillRunReport ensureSkillRunReport() => $_ensure(55);

  @$pb.TagNumber(66)
  $18.ReqRemoteScreenshot get reqRemoteScreenshot => $_getN(56);
  @$pb.TagNumber(66)
  set reqRemoteScreenshot($18.ReqRemoteScreenshot value) =>
      $_setField(66, value);
  @$pb.TagNumber(66)
  $core.bool hasReqRemoteScreenshot() => $_has(56);
  @$pb.TagNumber(66)
  void clearReqRemoteScreenshot() => $_clearField(66);
  @$pb.TagNumber(66)
  $18.ReqRemoteScreenshot ensureReqRemoteScreenshot() => $_ensure(56);

  @$pb.TagNumber(67)
  $18.ReqRemoteCommand get reqRemoteCommand => $_getN(57);
  @$pb.TagNumber(67)
  set reqRemoteCommand($18.ReqRemoteCommand value) => $_setField(67, value);
  @$pb.TagNumber(67)
  $core.bool hasReqRemoteCommand() => $_has(57);
  @$pb.TagNumber(67)
  void clearReqRemoteCommand() => $_clearField(67);
  @$pb.TagNumber(67)
  $18.ReqRemoteCommand ensureReqRemoteCommand() => $_ensure(57);

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
  $20.ReqStatsSubscribe get statsSubscribe => $_getN(60);
  @$pb.TagNumber(70)
  set statsSubscribe($20.ReqStatsSubscribe value) => $_setField(70, value);
  @$pb.TagNumber(70)
  $core.bool hasStatsSubscribe() => $_has(60);
  @$pb.TagNumber(70)
  void clearStatsSubscribe() => $_clearField(70);
  @$pb.TagNumber(70)
  $20.ReqStatsSubscribe ensureStatsSubscribe() => $_ensure(60);

  @$pb.TagNumber(71)
  $20.ReqStatsUnsubscribe get statsUnsubscribe => $_getN(61);
  @$pb.TagNumber(71)
  set statsUnsubscribe($20.ReqStatsUnsubscribe value) => $_setField(71, value);
  @$pb.TagNumber(71)
  $core.bool hasStatsUnsubscribe() => $_has(61);
  @$pb.TagNumber(71)
  void clearStatsUnsubscribe() => $_clearField(71);
  @$pb.TagNumber(71)
  $20.ReqStatsUnsubscribe ensureStatsUnsubscribe() => $_ensure(61);

  @$pb.TagNumber(72)
  $20.ReqLogSubscribe get logSubscribe => $_getN(62);
  @$pb.TagNumber(72)
  set logSubscribe($20.ReqLogSubscribe value) => $_setField(72, value);
  @$pb.TagNumber(72)
  $core.bool hasLogSubscribe() => $_has(62);
  @$pb.TagNumber(72)
  void clearLogSubscribe() => $_clearField(72);
  @$pb.TagNumber(72)
  $20.ReqLogSubscribe ensureLogSubscribe() => $_ensure(62);

  @$pb.TagNumber(73)
  $20.ReqLogUnsubscribe get logUnsubscribe => $_getN(63);
  @$pb.TagNumber(73)
  set logUnsubscribe($20.ReqLogUnsubscribe value) => $_setField(73, value);
  @$pb.TagNumber(73)
  $core.bool hasLogUnsubscribe() => $_has(63);
  @$pb.TagNumber(73)
  void clearLogUnsubscribe() => $_clearField(73);
  @$pb.TagNumber(73)
  $20.ReqLogUnsubscribe ensureLogUnsubscribe() => $_ensure(63);

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
  $21.ReqHintTouch get hintTouch => $_getN(66);
  @$pb.TagNumber(76)
  set hintTouch($21.ReqHintTouch value) => $_setField(76, value);
  @$pb.TagNumber(76)
  $core.bool hasHintTouch() => $_has(66);
  @$pb.TagNumber(76)
  void clearHintTouch() => $_clearField(76);
  @$pb.TagNumber(76)
  $21.ReqHintTouch ensureHintTouch() => $_ensure(66);

  @$pb.TagNumber(77)
  $14.ReqSiteConfigPut get siteConfigPut => $_getN(67);
  @$pb.TagNumber(77)
  set siteConfigPut($14.ReqSiteConfigPut value) => $_setField(77, value);
  @$pb.TagNumber(77)
  $core.bool hasSiteConfigPut() => $_has(67);
  @$pb.TagNumber(77)
  void clearSiteConfigPut() => $_clearField(77);
  @$pb.TagNumber(77)
  $14.ReqSiteConfigPut ensureSiteConfigPut() => $_ensure(67);

  @$pb.TagNumber(78)
  $14.ReqSitePreviewToken get sitePreviewToken => $_getN(68);
  @$pb.TagNumber(78)
  set sitePreviewToken($14.ReqSitePreviewToken value) => $_setField(78, value);
  @$pb.TagNumber(78)
  $core.bool hasSitePreviewToken() => $_has(68);
  @$pb.TagNumber(78)
  void clearSitePreviewToken() => $_clearField(78);
  @$pb.TagNumber(78)
  $14.ReqSitePreviewToken ensureSitePreviewToken() => $_ensure(68);

  @$pb.TagNumber(79)
  $15.ReqTxGet get txGet => $_getN(69);
  @$pb.TagNumber(79)
  set txGet($15.ReqTxGet value) => $_setField(79, value);
  @$pb.TagNumber(79)
  $core.bool hasTxGet() => $_has(69);
  @$pb.TagNumber(79)
  void clearTxGet() => $_clearField(79);
  @$pb.TagNumber(79)
  $15.ReqTxGet ensureTxGet() => $_ensure(69);

  @$pb.TagNumber(80)
  $15.ReqTxPut get txPut => $_getN(70);
  @$pb.TagNumber(80)
  set txPut($15.ReqTxPut value) => $_setField(80, value);
  @$pb.TagNumber(80)
  $core.bool hasTxPut() => $_has(70);
  @$pb.TagNumber(80)
  void clearTxPut() => $_clearField(80);
  @$pb.TagNumber(80)
  $15.ReqTxPut ensureTxPut() => $_ensure(70);

  @$pb.TagNumber(81)
  $15.ReqTxPreview get txPreview => $_getN(71);
  @$pb.TagNumber(81)
  set txPreview($15.ReqTxPreview value) => $_setField(81, value);
  @$pb.TagNumber(81)
  $core.bool hasTxPreview() => $_has(71);
  @$pb.TagNumber(81)
  void clearTxPreview() => $_clearField(81);
  @$pb.TagNumber(81)
  $15.ReqTxPreview ensureTxPreview() => $_ensure(71);

  @$pb.TagNumber(82)
  $15.ReqTxDebtPay get txDebtPay => $_getN(72);
  @$pb.TagNumber(82)
  set txDebtPay($15.ReqTxDebtPay value) => $_setField(82, value);
  @$pb.TagNumber(82)
  $core.bool hasTxDebtPay() => $_has(72);
  @$pb.TagNumber(82)
  void clearTxDebtPay() => $_clearField(82);
  @$pb.TagNumber(82)
  $15.ReqTxDebtPay ensureTxDebtPay() => $_ensure(72);

  @$pb.TagNumber(83)
  $14.ReqSiteQueryRun get siteQueryRun => $_getN(73);
  @$pb.TagNumber(83)
  set siteQueryRun($14.ReqSiteQueryRun value) => $_setField(83, value);
  @$pb.TagNumber(83)
  $core.bool hasSiteQueryRun() => $_has(73);
  @$pb.TagNumber(83)
  void clearSiteQueryRun() => $_clearField(83);
  @$pb.TagNumber(83)
  $14.ReqSiteQueryRun ensureSiteQueryRun() => $_ensure(73);
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
  sitePreviewToken,
  txGet,
  txPut,
  txPreview,
  txDebtPay,
  siteQueryRun,
  notSet
}

/// WebSocket server → client
class WsRes extends $pb.GeneratedMessage {
  factory WsRes({
    $core.String? reqId,
    $22.Err? err,
    $10.ResSessionInit? sessionInit,
    $11.ResSync? sync,
    $12.ResInboxList? inboxList,
    $12.ResChatMsgList? chatMsgList,
    $12.ResPromptStart? promptStart,
    $12.ResPromptDelta? promptDelta,
    $12.ResPromptEnd? promptEnd,
    $12.ResPromptFail? promptFail,
    $16.ResIdentityList? identityList,
    $16.ResIdentityGrantPatch? identityGrantPatch,
    $12.ResBotPeerList? botPeerList,
    $12.ResChatStop? chatStop,
    $12.ResChatSend? chatSend,
    $4.ResChannelWhatsappPair? channelWhatsappPairStart,
    $4.ResChannelWhatsappPair? channelWhatsappPairWatch,
    $4.ResChannelWhatsappPair? channelWhatsappPairAbort,
    $17.ResTaskList? taskList,
    $17.ResTaskPut? taskPut,
    $17.ResTaskRunStart? taskRunStart,
    $17.ResTaskRunCancel? taskRunCancel,
    $17.ResTaskRunList? taskRunList,
    InvokeRes? invoke,
    $17.TaskRunPush? taskRunPush,
    $11.SyncPush? syncPush,
    $0.BillingPushBalance? billingBalance,
    $0.BillingPushQuota? billingQuota,
    $0.BillingPushCommission? billingCommission,
    $23.LogPush? logPush,
    $4.ChannelPairPush? channelPairPush,
    $20.StatsPush? statsPush,
    $13.ResSkillList? skillList,
    $1.ResConsumptionList? consumptionList,
    $14.ResSiteList? siteList,
    $15.ResTxList? txList,
    $1.ResConsumptionPut? consumptionPut,
    $12.ResChatPatch? chatPatch,
    $12.ResAssetTagList? assetTagList,
    $12.ResLogList? logList,
    $16.ResIdentityPut? identityPut,
    $18.ResRemoteSessionStart? remoteSessionStart,
    $18.ResRemoteSessionStop? remoteSessionStop,
    $18.RemoteSessionPush? remoteSessionPush,
    $4.ResChannelDisconnect? channelDisconnect,
    $16.ResIdentityDelete? identityDelete,
    $13.ResSkillPut? skillPut,
    $13.ResSkillCatalogList? skillCatalogList,
    $13.ResSkillCatalogInstall? skillCatalogInstall,
    $18.ResRemoteIceConfig? remoteIceConfig,
    $18.RtcSignalOffer? rtcSignalOffer,
    $18.RtcSignalAnswer? rtcSignalAnswer,
    $18.RtcSignalIce? rtcSignalIce,
    $19.ResCollectionDefList? collectionDefList,
    $14.ResSiteDraftGet? siteDraftGet,
    $14.ResSiteDraftPut? siteDraftPut,
    $14.ResSitePublish? sitePublish,
    $14.ResSiteProductList? siteProductList,
    $14.ResSiteProductPut? siteProductPut,
    $14.ResSiteContactList? siteContactList,
    $14.ResSiteContactPut? siteContactPut,
    $14.ResSiteObjectList? siteObjectList,
    $14.ResSiteObjectPut? siteObjectPut,
    $14.ResSiteDomainList? siteDomainList,
    $14.ResSiteDomainPut? siteDomainPut,
    $13.ResSkillCatalogSearch? skillCatalogSearch,
    $13.ResSkillCatalogSubmit? skillCatalogSubmit,
    $13.ResSkillRunReport? skillRunReport,
    $18.ResRemoteScreenshot? resRemoteScreenshot,
    $18.ResRemoteCommand? resRemoteCommand,
    $7.ResVoiceStt? voiceStt,
    $7.ResVoiceTts? voiceTts,
    $8.ResMentionList? mentionList,
    $8.ResMentionSearch? mentionSearch,
    $21.ResHintTouch? hintTouch,
    $12.PromptRunPush? promptRunPush,
    $14.ResSiteConfigPut? siteConfigPut,
    $14.ResSitePreviewToken? sitePreviewToken,
    $15.ResTxGet? txGet,
    $15.ResTxPut? txPut,
    $15.ResTxPreview? txPreview,
    $15.ResTxDebtPay? txDebtPay,
    $14.ResSiteQueryRun? siteQueryRun,
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
    if (sitePreviewToken != null) result.sitePreviewToken = sitePreviewToken;
    if (txGet != null) result.txGet = txGet;
    if (txPut != null) result.txPut = txPut;
    if (txPreview != null) result.txPreview = txPreview;
    if (txDebtPay != null) result.txDebtPay = txDebtPay;
    if (siteQueryRun != null) result.siteQueryRun = siteQueryRun;
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
    126: WsRes_Body.sitePreviewToken,
    127: WsRes_Body.txGet,
    128: WsRes_Body.txPut,
    129: WsRes_Body.txPreview,
    130: WsRes_Body.txDebtPay,
    131: WsRes_Body.siteQueryRun,
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
      125,
      126,
      127,
      128,
      129,
      130,
      131
    ])
    ..aOS(1, _omitFieldNames ? '' : 'reqId')
    ..aOM<$22.Err>(2, _omitFieldNames ? '' : 'err',
        subBuilder: $22.Err.$_createMessage)
    ..aOM<$10.ResSessionInit>(10, _omitFieldNames ? '' : 'sessionInit',
        subBuilder: $10.ResSessionInit.$_createMessage)
    ..aOM<$11.ResSync>(11, _omitFieldNames ? '' : 'sync',
        subBuilder: $11.ResSync.$_createMessage)
    ..aOM<$12.ResInboxList>(12, _omitFieldNames ? '' : 'inboxList',
        subBuilder: $12.ResInboxList.$_createMessage)
    ..aOM<$12.ResChatMsgList>(13, _omitFieldNames ? '' : 'chatMsgList',
        subBuilder: $12.ResChatMsgList.$_createMessage)
    ..aOM<$12.ResPromptStart>(20, _omitFieldNames ? '' : 'promptStart',
        subBuilder: $12.ResPromptStart.$_createMessage)
    ..aOM<$12.ResPromptDelta>(21, _omitFieldNames ? '' : 'promptDelta',
        subBuilder: $12.ResPromptDelta.$_createMessage)
    ..aOM<$12.ResPromptEnd>(22, _omitFieldNames ? '' : 'promptEnd',
        subBuilder: $12.ResPromptEnd.$_createMessage)
    ..aOM<$12.ResPromptFail>(23, _omitFieldNames ? '' : 'promptFail',
        subBuilder: $12.ResPromptFail.$_createMessage)
    ..aOM<$16.ResIdentityList>(27, _omitFieldNames ? '' : 'identityList',
        subBuilder: $16.ResIdentityList.$_createMessage)
    ..aOM<$16.ResIdentityGrantPatch>(
        28, _omitFieldNames ? '' : 'identityGrantPatch',
        subBuilder: $16.ResIdentityGrantPatch.$_createMessage)
    ..aOM<$12.ResBotPeerList>(29, _omitFieldNames ? '' : 'botPeerList',
        subBuilder: $12.ResBotPeerList.$_createMessage)
    ..aOM<$12.ResChatStop>(30, _omitFieldNames ? '' : 'chatStop',
        subBuilder: $12.ResChatStop.$_createMessage)
    ..aOM<$12.ResChatSend>(31, _omitFieldNames ? '' : 'chatSend',
        subBuilder: $12.ResChatSend.$_createMessage)
    ..aOM<$4.ResChannelWhatsappPair>(
        32, _omitFieldNames ? '' : 'channelWhatsappPairStart',
        subBuilder: $4.ResChannelWhatsappPair.$_createMessage)
    ..aOM<$4.ResChannelWhatsappPair>(
        33, _omitFieldNames ? '' : 'channelWhatsappPairWatch',
        subBuilder: $4.ResChannelWhatsappPair.$_createMessage)
    ..aOM<$4.ResChannelWhatsappPair>(
        34, _omitFieldNames ? '' : 'channelWhatsappPairAbort',
        subBuilder: $4.ResChannelWhatsappPair.$_createMessage)
    ..aOM<$17.ResTaskList>(35, _omitFieldNames ? '' : 'taskList',
        subBuilder: $17.ResTaskList.$_createMessage)
    ..aOM<$17.ResTaskPut>(36, _omitFieldNames ? '' : 'taskPut',
        subBuilder: $17.ResTaskPut.$_createMessage)
    ..aOM<$17.ResTaskRunStart>(37, _omitFieldNames ? '' : 'taskRunStart',
        subBuilder: $17.ResTaskRunStart.$_createMessage)
    ..aOM<$17.ResTaskRunCancel>(38, _omitFieldNames ? '' : 'taskRunCancel',
        subBuilder: $17.ResTaskRunCancel.$_createMessage)
    ..aOM<$17.ResTaskRunList>(39, _omitFieldNames ? '' : 'taskRunList',
        subBuilder: $17.ResTaskRunList.$_createMessage)
    ..aOM<InvokeRes>(40, _omitFieldNames ? '' : 'invoke',
        subBuilder: InvokeRes.$_createMessage)
    ..aOM<$17.TaskRunPush>(45, _omitFieldNames ? '' : 'taskRunPush',
        subBuilder: $17.TaskRunPush.$_createMessage)
    ..aOM<$11.SyncPush>(50, _omitFieldNames ? '' : 'syncPush',
        subBuilder: $11.SyncPush.$_createMessage)
    ..aOM<$0.BillingPushBalance>(60, _omitFieldNames ? '' : 'billingBalance',
        subBuilder: $0.BillingPushBalance.$_createMessage)
    ..aOM<$0.BillingPushQuota>(61, _omitFieldNames ? '' : 'billingQuota',
        subBuilder: $0.BillingPushQuota.$_createMessage)
    ..aOM<$0.BillingPushCommission>(
        62, _omitFieldNames ? '' : 'billingCommission',
        subBuilder: $0.BillingPushCommission.$_createMessage)
    ..aOM<$23.LogPush>(70, _omitFieldNames ? '' : 'logPush',
        subBuilder: $23.LogPush.$_createMessage)
    ..aOM<$4.ChannelPairPush>(71, _omitFieldNames ? '' : 'channelPairPush',
        subBuilder: $4.ChannelPairPush.$_createMessage)
    ..aOM<$20.StatsPush>(72, _omitFieldNames ? '' : 'statsPush',
        subBuilder: $20.StatsPush.$_createMessage)
    ..aOM<$13.ResSkillList>(80, _omitFieldNames ? '' : 'skillList',
        subBuilder: $13.ResSkillList.$_createMessage)
    ..aOM<$1.ResConsumptionList>(81, _omitFieldNames ? '' : 'consumptionList',
        subBuilder: $1.ResConsumptionList.$_createMessage)
    ..aOM<$14.ResSiteList>(82, _omitFieldNames ? '' : 'siteList',
        subBuilder: $14.ResSiteList.$_createMessage)
    ..aOM<$15.ResTxList>(83, _omitFieldNames ? '' : 'txList',
        subBuilder: $15.ResTxList.$_createMessage)
    ..aOM<$1.ResConsumptionPut>(84, _omitFieldNames ? '' : 'consumptionPut',
        subBuilder: $1.ResConsumptionPut.$_createMessage)
    ..aOM<$12.ResChatPatch>(85, _omitFieldNames ? '' : 'chatPatch',
        subBuilder: $12.ResChatPatch.$_createMessage)
    ..aOM<$12.ResAssetTagList>(86, _omitFieldNames ? '' : 'assetTagList',
        subBuilder: $12.ResAssetTagList.$_createMessage)
    ..aOM<$12.ResLogList>(87, _omitFieldNames ? '' : 'logList',
        subBuilder: $12.ResLogList.$_createMessage)
    ..aOM<$16.ResIdentityPut>(88, _omitFieldNames ? '' : 'identityPut',
        subBuilder: $16.ResIdentityPut.$_createMessage)
    ..aOM<$18.ResRemoteSessionStart>(
        90, _omitFieldNames ? '' : 'remoteSessionStart',
        subBuilder: $18.ResRemoteSessionStart.$_createMessage)
    ..aOM<$18.ResRemoteSessionStop>(
        91, _omitFieldNames ? '' : 'remoteSessionStop',
        subBuilder: $18.ResRemoteSessionStop.$_createMessage)
    ..aOM<$18.RemoteSessionPush>(92, _omitFieldNames ? '' : 'remoteSessionPush',
        subBuilder: $18.RemoteSessionPush.$_createMessage)
    ..aOM<$4.ResChannelDisconnect>(
        93, _omitFieldNames ? '' : 'channelDisconnect',
        subBuilder: $4.ResChannelDisconnect.$_createMessage)
    ..aOM<$16.ResIdentityDelete>(94, _omitFieldNames ? '' : 'identityDelete',
        subBuilder: $16.ResIdentityDelete.$_createMessage)
    ..aOM<$13.ResSkillPut>(95, _omitFieldNames ? '' : 'skillPut',
        subBuilder: $13.ResSkillPut.$_createMessage)
    ..aOM<$13.ResSkillCatalogList>(
        96, _omitFieldNames ? '' : 'skillCatalogList',
        subBuilder: $13.ResSkillCatalogList.$_createMessage)
    ..aOM<$13.ResSkillCatalogInstall>(
        97, _omitFieldNames ? '' : 'skillCatalogInstall',
        subBuilder: $13.ResSkillCatalogInstall.$_createMessage)
    ..aOM<$18.ResRemoteIceConfig>(98, _omitFieldNames ? '' : 'remoteIceConfig',
        subBuilder: $18.ResRemoteIceConfig.$_createMessage)
    ..aOM<$18.RtcSignalOffer>(99, _omitFieldNames ? '' : 'rtcSignalOffer',
        subBuilder: $18.RtcSignalOffer.$_createMessage)
    ..aOM<$18.RtcSignalAnswer>(100, _omitFieldNames ? '' : 'rtcSignalAnswer',
        subBuilder: $18.RtcSignalAnswer.$_createMessage)
    ..aOM<$18.RtcSignalIce>(101, _omitFieldNames ? '' : 'rtcSignalIce',
        subBuilder: $18.RtcSignalIce.$_createMessage)
    ..aOM<$19.ResCollectionDefList>(
        102, _omitFieldNames ? '' : 'collectionDefList',
        subBuilder: $19.ResCollectionDefList.$_createMessage)
    ..aOM<$14.ResSiteDraftGet>(103, _omitFieldNames ? '' : 'siteDraftGet',
        subBuilder: $14.ResSiteDraftGet.$_createMessage)
    ..aOM<$14.ResSiteDraftPut>(104, _omitFieldNames ? '' : 'siteDraftPut',
        subBuilder: $14.ResSiteDraftPut.$_createMessage)
    ..aOM<$14.ResSitePublish>(105, _omitFieldNames ? '' : 'sitePublish',
        subBuilder: $14.ResSitePublish.$_createMessage)
    ..aOM<$14.ResSiteProductList>(106, _omitFieldNames ? '' : 'siteProductList',
        subBuilder: $14.ResSiteProductList.$_createMessage)
    ..aOM<$14.ResSiteProductPut>(107, _omitFieldNames ? '' : 'siteProductPut',
        subBuilder: $14.ResSiteProductPut.$_createMessage)
    ..aOM<$14.ResSiteContactList>(108, _omitFieldNames ? '' : 'siteContactList',
        subBuilder: $14.ResSiteContactList.$_createMessage)
    ..aOM<$14.ResSiteContactPut>(109, _omitFieldNames ? '' : 'siteContactPut',
        subBuilder: $14.ResSiteContactPut.$_createMessage)
    ..aOM<$14.ResSiteObjectList>(110, _omitFieldNames ? '' : 'siteObjectList',
        subBuilder: $14.ResSiteObjectList.$_createMessage)
    ..aOM<$14.ResSiteObjectPut>(111, _omitFieldNames ? '' : 'siteObjectPut',
        subBuilder: $14.ResSiteObjectPut.$_createMessage)
    ..aOM<$14.ResSiteDomainList>(112, _omitFieldNames ? '' : 'siteDomainList',
        subBuilder: $14.ResSiteDomainList.$_createMessage)
    ..aOM<$14.ResSiteDomainPut>(113, _omitFieldNames ? '' : 'siteDomainPut',
        subBuilder: $14.ResSiteDomainPut.$_createMessage)
    ..aOM<$13.ResSkillCatalogSearch>(
        114, _omitFieldNames ? '' : 'skillCatalogSearch',
        subBuilder: $13.ResSkillCatalogSearch.$_createMessage)
    ..aOM<$13.ResSkillCatalogSubmit>(
        115, _omitFieldNames ? '' : 'skillCatalogSubmit',
        subBuilder: $13.ResSkillCatalogSubmit.$_createMessage)
    ..aOM<$13.ResSkillRunReport>(116, _omitFieldNames ? '' : 'skillRunReport',
        subBuilder: $13.ResSkillRunReport.$_createMessage)
    ..aOM<$18.ResRemoteScreenshot>(
        117, _omitFieldNames ? '' : 'resRemoteScreenshot',
        subBuilder: $18.ResRemoteScreenshot.$_createMessage)
    ..aOM<$18.ResRemoteCommand>(118, _omitFieldNames ? '' : 'resRemoteCommand',
        subBuilder: $18.ResRemoteCommand.$_createMessage)
    ..aOM<$7.ResVoiceStt>(119, _omitFieldNames ? '' : 'voiceStt',
        subBuilder: $7.ResVoiceStt.$_createMessage)
    ..aOM<$7.ResVoiceTts>(120, _omitFieldNames ? '' : 'voiceTts',
        subBuilder: $7.ResVoiceTts.$_createMessage)
    ..aOM<$8.ResMentionList>(121, _omitFieldNames ? '' : 'mentionList',
        subBuilder: $8.ResMentionList.$_createMessage)
    ..aOM<$8.ResMentionSearch>(122, _omitFieldNames ? '' : 'mentionSearch',
        subBuilder: $8.ResMentionSearch.$_createMessage)
    ..aOM<$21.ResHintTouch>(123, _omitFieldNames ? '' : 'hintTouch',
        subBuilder: $21.ResHintTouch.$_createMessage)
    ..aOM<$12.PromptRunPush>(124, _omitFieldNames ? '' : 'promptRunPush',
        subBuilder: $12.PromptRunPush.$_createMessage)
    ..aOM<$14.ResSiteConfigPut>(125, _omitFieldNames ? '' : 'siteConfigPut',
        subBuilder: $14.ResSiteConfigPut.$_createMessage)
    ..aOM<$14.ResSitePreviewToken>(
        126, _omitFieldNames ? '' : 'sitePreviewToken',
        subBuilder: $14.ResSitePreviewToken.$_createMessage)
    ..aOM<$15.ResTxGet>(127, _omitFieldNames ? '' : 'txGet',
        subBuilder: $15.ResTxGet.$_createMessage)
    ..aOM<$15.ResTxPut>(128, _omitFieldNames ? '' : 'txPut',
        subBuilder: $15.ResTxPut.$_createMessage)
    ..aOM<$15.ResTxPreview>(129, _omitFieldNames ? '' : 'txPreview',
        subBuilder: $15.ResTxPreview.$_createMessage)
    ..aOM<$15.ResTxDebtPay>(130, _omitFieldNames ? '' : 'txDebtPay',
        subBuilder: $15.ResTxDebtPay.$_createMessage)
    ..aOM<$14.ResSiteQueryRun>(131, _omitFieldNames ? '' : 'siteQueryRun',
        subBuilder: $14.ResSiteQueryRun.$_createMessage)
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
  @$pb.TagNumber(126)
  @$pb.TagNumber(127)
  @$pb.TagNumber(128)
  @$pb.TagNumber(129)
  @$pb.TagNumber(130)
  @$pb.TagNumber(131)
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
  @$pb.TagNumber(126)
  @$pb.TagNumber(127)
  @$pb.TagNumber(128)
  @$pb.TagNumber(129)
  @$pb.TagNumber(130)
  @$pb.TagNumber(131)
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
  $22.Err get err => $_getN(1);
  @$pb.TagNumber(2)
  set err($22.Err value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasErr() => $_has(1);
  @$pb.TagNumber(2)
  void clearErr() => $_clearField(2);
  @$pb.TagNumber(2)
  $22.Err ensureErr() => $_ensure(1);

  @$pb.TagNumber(10)
  $10.ResSessionInit get sessionInit => $_getN(2);
  @$pb.TagNumber(10)
  set sessionInit($10.ResSessionInit value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasSessionInit() => $_has(2);
  @$pb.TagNumber(10)
  void clearSessionInit() => $_clearField(10);
  @$pb.TagNumber(10)
  $10.ResSessionInit ensureSessionInit() => $_ensure(2);

  @$pb.TagNumber(11)
  $11.ResSync get sync => $_getN(3);
  @$pb.TagNumber(11)
  set sync($11.ResSync value) => $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasSync() => $_has(3);
  @$pb.TagNumber(11)
  void clearSync() => $_clearField(11);
  @$pb.TagNumber(11)
  $11.ResSync ensureSync() => $_ensure(3);

  @$pb.TagNumber(12)
  $12.ResInboxList get inboxList => $_getN(4);
  @$pb.TagNumber(12)
  set inboxList($12.ResInboxList value) => $_setField(12, value);
  @$pb.TagNumber(12)
  $core.bool hasInboxList() => $_has(4);
  @$pb.TagNumber(12)
  void clearInboxList() => $_clearField(12);
  @$pb.TagNumber(12)
  $12.ResInboxList ensureInboxList() => $_ensure(4);

  @$pb.TagNumber(13)
  $12.ResChatMsgList get chatMsgList => $_getN(5);
  @$pb.TagNumber(13)
  set chatMsgList($12.ResChatMsgList value) => $_setField(13, value);
  @$pb.TagNumber(13)
  $core.bool hasChatMsgList() => $_has(5);
  @$pb.TagNumber(13)
  void clearChatMsgList() => $_clearField(13);
  @$pb.TagNumber(13)
  $12.ResChatMsgList ensureChatMsgList() => $_ensure(5);

  @$pb.TagNumber(20)
  $12.ResPromptStart get promptStart => $_getN(6);
  @$pb.TagNumber(20)
  set promptStart($12.ResPromptStart value) => $_setField(20, value);
  @$pb.TagNumber(20)
  $core.bool hasPromptStart() => $_has(6);
  @$pb.TagNumber(20)
  void clearPromptStart() => $_clearField(20);
  @$pb.TagNumber(20)
  $12.ResPromptStart ensurePromptStart() => $_ensure(6);

  @$pb.TagNumber(21)
  $12.ResPromptDelta get promptDelta => $_getN(7);
  @$pb.TagNumber(21)
  set promptDelta($12.ResPromptDelta value) => $_setField(21, value);
  @$pb.TagNumber(21)
  $core.bool hasPromptDelta() => $_has(7);
  @$pb.TagNumber(21)
  void clearPromptDelta() => $_clearField(21);
  @$pb.TagNumber(21)
  $12.ResPromptDelta ensurePromptDelta() => $_ensure(7);

  @$pb.TagNumber(22)
  $12.ResPromptEnd get promptEnd => $_getN(8);
  @$pb.TagNumber(22)
  set promptEnd($12.ResPromptEnd value) => $_setField(22, value);
  @$pb.TagNumber(22)
  $core.bool hasPromptEnd() => $_has(8);
  @$pb.TagNumber(22)
  void clearPromptEnd() => $_clearField(22);
  @$pb.TagNumber(22)
  $12.ResPromptEnd ensurePromptEnd() => $_ensure(8);

  @$pb.TagNumber(23)
  $12.ResPromptFail get promptFail => $_getN(9);
  @$pb.TagNumber(23)
  set promptFail($12.ResPromptFail value) => $_setField(23, value);
  @$pb.TagNumber(23)
  $core.bool hasPromptFail() => $_has(9);
  @$pb.TagNumber(23)
  void clearPromptFail() => $_clearField(23);
  @$pb.TagNumber(23)
  $12.ResPromptFail ensurePromptFail() => $_ensure(9);

  @$pb.TagNumber(27)
  $16.ResIdentityList get identityList => $_getN(10);
  @$pb.TagNumber(27)
  set identityList($16.ResIdentityList value) => $_setField(27, value);
  @$pb.TagNumber(27)
  $core.bool hasIdentityList() => $_has(10);
  @$pb.TagNumber(27)
  void clearIdentityList() => $_clearField(27);
  @$pb.TagNumber(27)
  $16.ResIdentityList ensureIdentityList() => $_ensure(10);

  @$pb.TagNumber(28)
  $16.ResIdentityGrantPatch get identityGrantPatch => $_getN(11);
  @$pb.TagNumber(28)
  set identityGrantPatch($16.ResIdentityGrantPatch value) =>
      $_setField(28, value);
  @$pb.TagNumber(28)
  $core.bool hasIdentityGrantPatch() => $_has(11);
  @$pb.TagNumber(28)
  void clearIdentityGrantPatch() => $_clearField(28);
  @$pb.TagNumber(28)
  $16.ResIdentityGrantPatch ensureIdentityGrantPatch() => $_ensure(11);

  @$pb.TagNumber(29)
  $12.ResBotPeerList get botPeerList => $_getN(12);
  @$pb.TagNumber(29)
  set botPeerList($12.ResBotPeerList value) => $_setField(29, value);
  @$pb.TagNumber(29)
  $core.bool hasBotPeerList() => $_has(12);
  @$pb.TagNumber(29)
  void clearBotPeerList() => $_clearField(29);
  @$pb.TagNumber(29)
  $12.ResBotPeerList ensureBotPeerList() => $_ensure(12);

  @$pb.TagNumber(30)
  $12.ResChatStop get chatStop => $_getN(13);
  @$pb.TagNumber(30)
  set chatStop($12.ResChatStop value) => $_setField(30, value);
  @$pb.TagNumber(30)
  $core.bool hasChatStop() => $_has(13);
  @$pb.TagNumber(30)
  void clearChatStop() => $_clearField(30);
  @$pb.TagNumber(30)
  $12.ResChatStop ensureChatStop() => $_ensure(13);

  @$pb.TagNumber(31)
  $12.ResChatSend get chatSend => $_getN(14);
  @$pb.TagNumber(31)
  set chatSend($12.ResChatSend value) => $_setField(31, value);
  @$pb.TagNumber(31)
  $core.bool hasChatSend() => $_has(14);
  @$pb.TagNumber(31)
  void clearChatSend() => $_clearField(31);
  @$pb.TagNumber(31)
  $12.ResChatSend ensureChatSend() => $_ensure(14);

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
  $17.ResTaskList get taskList => $_getN(18);
  @$pb.TagNumber(35)
  set taskList($17.ResTaskList value) => $_setField(35, value);
  @$pb.TagNumber(35)
  $core.bool hasTaskList() => $_has(18);
  @$pb.TagNumber(35)
  void clearTaskList() => $_clearField(35);
  @$pb.TagNumber(35)
  $17.ResTaskList ensureTaskList() => $_ensure(18);

  @$pb.TagNumber(36)
  $17.ResTaskPut get taskPut => $_getN(19);
  @$pb.TagNumber(36)
  set taskPut($17.ResTaskPut value) => $_setField(36, value);
  @$pb.TagNumber(36)
  $core.bool hasTaskPut() => $_has(19);
  @$pb.TagNumber(36)
  void clearTaskPut() => $_clearField(36);
  @$pb.TagNumber(36)
  $17.ResTaskPut ensureTaskPut() => $_ensure(19);

  @$pb.TagNumber(37)
  $17.ResTaskRunStart get taskRunStart => $_getN(20);
  @$pb.TagNumber(37)
  set taskRunStart($17.ResTaskRunStart value) => $_setField(37, value);
  @$pb.TagNumber(37)
  $core.bool hasTaskRunStart() => $_has(20);
  @$pb.TagNumber(37)
  void clearTaskRunStart() => $_clearField(37);
  @$pb.TagNumber(37)
  $17.ResTaskRunStart ensureTaskRunStart() => $_ensure(20);

  @$pb.TagNumber(38)
  $17.ResTaskRunCancel get taskRunCancel => $_getN(21);
  @$pb.TagNumber(38)
  set taskRunCancel($17.ResTaskRunCancel value) => $_setField(38, value);
  @$pb.TagNumber(38)
  $core.bool hasTaskRunCancel() => $_has(21);
  @$pb.TagNumber(38)
  void clearTaskRunCancel() => $_clearField(38);
  @$pb.TagNumber(38)
  $17.ResTaskRunCancel ensureTaskRunCancel() => $_ensure(21);

  @$pb.TagNumber(39)
  $17.ResTaskRunList get taskRunList => $_getN(22);
  @$pb.TagNumber(39)
  set taskRunList($17.ResTaskRunList value) => $_setField(39, value);
  @$pb.TagNumber(39)
  $core.bool hasTaskRunList() => $_has(22);
  @$pb.TagNumber(39)
  void clearTaskRunList() => $_clearField(39);
  @$pb.TagNumber(39)
  $17.ResTaskRunList ensureTaskRunList() => $_ensure(22);

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
  $17.TaskRunPush get taskRunPush => $_getN(24);
  @$pb.TagNumber(45)
  set taskRunPush($17.TaskRunPush value) => $_setField(45, value);
  @$pb.TagNumber(45)
  $core.bool hasTaskRunPush() => $_has(24);
  @$pb.TagNumber(45)
  void clearTaskRunPush() => $_clearField(45);
  @$pb.TagNumber(45)
  $17.TaskRunPush ensureTaskRunPush() => $_ensure(24);

  @$pb.TagNumber(50)
  $11.SyncPush get syncPush => $_getN(25);
  @$pb.TagNumber(50)
  set syncPush($11.SyncPush value) => $_setField(50, value);
  @$pb.TagNumber(50)
  $core.bool hasSyncPush() => $_has(25);
  @$pb.TagNumber(50)
  void clearSyncPush() => $_clearField(50);
  @$pb.TagNumber(50)
  $11.SyncPush ensureSyncPush() => $_ensure(25);

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
  $23.LogPush get logPush => $_getN(29);
  @$pb.TagNumber(70)
  set logPush($23.LogPush value) => $_setField(70, value);
  @$pb.TagNumber(70)
  $core.bool hasLogPush() => $_has(29);
  @$pb.TagNumber(70)
  void clearLogPush() => $_clearField(70);
  @$pb.TagNumber(70)
  $23.LogPush ensureLogPush() => $_ensure(29);

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
  $20.StatsPush get statsPush => $_getN(31);
  @$pb.TagNumber(72)
  set statsPush($20.StatsPush value) => $_setField(72, value);
  @$pb.TagNumber(72)
  $core.bool hasStatsPush() => $_has(31);
  @$pb.TagNumber(72)
  void clearStatsPush() => $_clearField(72);
  @$pb.TagNumber(72)
  $20.StatsPush ensureStatsPush() => $_ensure(31);

  @$pb.TagNumber(80)
  $13.ResSkillList get skillList => $_getN(32);
  @$pb.TagNumber(80)
  set skillList($13.ResSkillList value) => $_setField(80, value);
  @$pb.TagNumber(80)
  $core.bool hasSkillList() => $_has(32);
  @$pb.TagNumber(80)
  void clearSkillList() => $_clearField(80);
  @$pb.TagNumber(80)
  $13.ResSkillList ensureSkillList() => $_ensure(32);

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
  $14.ResSiteList get siteList => $_getN(34);
  @$pb.TagNumber(82)
  set siteList($14.ResSiteList value) => $_setField(82, value);
  @$pb.TagNumber(82)
  $core.bool hasSiteList() => $_has(34);
  @$pb.TagNumber(82)
  void clearSiteList() => $_clearField(82);
  @$pb.TagNumber(82)
  $14.ResSiteList ensureSiteList() => $_ensure(34);

  @$pb.TagNumber(83)
  $15.ResTxList get txList => $_getN(35);
  @$pb.TagNumber(83)
  set txList($15.ResTxList value) => $_setField(83, value);
  @$pb.TagNumber(83)
  $core.bool hasTxList() => $_has(35);
  @$pb.TagNumber(83)
  void clearTxList() => $_clearField(83);
  @$pb.TagNumber(83)
  $15.ResTxList ensureTxList() => $_ensure(35);

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
  $12.ResChatPatch get chatPatch => $_getN(37);
  @$pb.TagNumber(85)
  set chatPatch($12.ResChatPatch value) => $_setField(85, value);
  @$pb.TagNumber(85)
  $core.bool hasChatPatch() => $_has(37);
  @$pb.TagNumber(85)
  void clearChatPatch() => $_clearField(85);
  @$pb.TagNumber(85)
  $12.ResChatPatch ensureChatPatch() => $_ensure(37);

  @$pb.TagNumber(86)
  $12.ResAssetTagList get assetTagList => $_getN(38);
  @$pb.TagNumber(86)
  set assetTagList($12.ResAssetTagList value) => $_setField(86, value);
  @$pb.TagNumber(86)
  $core.bool hasAssetTagList() => $_has(38);
  @$pb.TagNumber(86)
  void clearAssetTagList() => $_clearField(86);
  @$pb.TagNumber(86)
  $12.ResAssetTagList ensureAssetTagList() => $_ensure(38);

  @$pb.TagNumber(87)
  $12.ResLogList get logList => $_getN(39);
  @$pb.TagNumber(87)
  set logList($12.ResLogList value) => $_setField(87, value);
  @$pb.TagNumber(87)
  $core.bool hasLogList() => $_has(39);
  @$pb.TagNumber(87)
  void clearLogList() => $_clearField(87);
  @$pb.TagNumber(87)
  $12.ResLogList ensureLogList() => $_ensure(39);

  @$pb.TagNumber(88)
  $16.ResIdentityPut get identityPut => $_getN(40);
  @$pb.TagNumber(88)
  set identityPut($16.ResIdentityPut value) => $_setField(88, value);
  @$pb.TagNumber(88)
  $core.bool hasIdentityPut() => $_has(40);
  @$pb.TagNumber(88)
  void clearIdentityPut() => $_clearField(88);
  @$pb.TagNumber(88)
  $16.ResIdentityPut ensureIdentityPut() => $_ensure(40);

  @$pb.TagNumber(90)
  $18.ResRemoteSessionStart get remoteSessionStart => $_getN(41);
  @$pb.TagNumber(90)
  set remoteSessionStart($18.ResRemoteSessionStart value) =>
      $_setField(90, value);
  @$pb.TagNumber(90)
  $core.bool hasRemoteSessionStart() => $_has(41);
  @$pb.TagNumber(90)
  void clearRemoteSessionStart() => $_clearField(90);
  @$pb.TagNumber(90)
  $18.ResRemoteSessionStart ensureRemoteSessionStart() => $_ensure(41);

  @$pb.TagNumber(91)
  $18.ResRemoteSessionStop get remoteSessionStop => $_getN(42);
  @$pb.TagNumber(91)
  set remoteSessionStop($18.ResRemoteSessionStop value) =>
      $_setField(91, value);
  @$pb.TagNumber(91)
  $core.bool hasRemoteSessionStop() => $_has(42);
  @$pb.TagNumber(91)
  void clearRemoteSessionStop() => $_clearField(91);
  @$pb.TagNumber(91)
  $18.ResRemoteSessionStop ensureRemoteSessionStop() => $_ensure(42);

  @$pb.TagNumber(92)
  $18.RemoteSessionPush get remoteSessionPush => $_getN(43);
  @$pb.TagNumber(92)
  set remoteSessionPush($18.RemoteSessionPush value) => $_setField(92, value);
  @$pb.TagNumber(92)
  $core.bool hasRemoteSessionPush() => $_has(43);
  @$pb.TagNumber(92)
  void clearRemoteSessionPush() => $_clearField(92);
  @$pb.TagNumber(92)
  $18.RemoteSessionPush ensureRemoteSessionPush() => $_ensure(43);

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
  $16.ResIdentityDelete get identityDelete => $_getN(45);
  @$pb.TagNumber(94)
  set identityDelete($16.ResIdentityDelete value) => $_setField(94, value);
  @$pb.TagNumber(94)
  $core.bool hasIdentityDelete() => $_has(45);
  @$pb.TagNumber(94)
  void clearIdentityDelete() => $_clearField(94);
  @$pb.TagNumber(94)
  $16.ResIdentityDelete ensureIdentityDelete() => $_ensure(45);

  @$pb.TagNumber(95)
  $13.ResSkillPut get skillPut => $_getN(46);
  @$pb.TagNumber(95)
  set skillPut($13.ResSkillPut value) => $_setField(95, value);
  @$pb.TagNumber(95)
  $core.bool hasSkillPut() => $_has(46);
  @$pb.TagNumber(95)
  void clearSkillPut() => $_clearField(95);
  @$pb.TagNumber(95)
  $13.ResSkillPut ensureSkillPut() => $_ensure(46);

  @$pb.TagNumber(96)
  $13.ResSkillCatalogList get skillCatalogList => $_getN(47);
  @$pb.TagNumber(96)
  set skillCatalogList($13.ResSkillCatalogList value) => $_setField(96, value);
  @$pb.TagNumber(96)
  $core.bool hasSkillCatalogList() => $_has(47);
  @$pb.TagNumber(96)
  void clearSkillCatalogList() => $_clearField(96);
  @$pb.TagNumber(96)
  $13.ResSkillCatalogList ensureSkillCatalogList() => $_ensure(47);

  @$pb.TagNumber(97)
  $13.ResSkillCatalogInstall get skillCatalogInstall => $_getN(48);
  @$pb.TagNumber(97)
  set skillCatalogInstall($13.ResSkillCatalogInstall value) =>
      $_setField(97, value);
  @$pb.TagNumber(97)
  $core.bool hasSkillCatalogInstall() => $_has(48);
  @$pb.TagNumber(97)
  void clearSkillCatalogInstall() => $_clearField(97);
  @$pb.TagNumber(97)
  $13.ResSkillCatalogInstall ensureSkillCatalogInstall() => $_ensure(48);

  @$pb.TagNumber(98)
  $18.ResRemoteIceConfig get remoteIceConfig => $_getN(49);
  @$pb.TagNumber(98)
  set remoteIceConfig($18.ResRemoteIceConfig value) => $_setField(98, value);
  @$pb.TagNumber(98)
  $core.bool hasRemoteIceConfig() => $_has(49);
  @$pb.TagNumber(98)
  void clearRemoteIceConfig() => $_clearField(98);
  @$pb.TagNumber(98)
  $18.ResRemoteIceConfig ensureRemoteIceConfig() => $_ensure(49);

  @$pb.TagNumber(99)
  $18.RtcSignalOffer get rtcSignalOffer => $_getN(50);
  @$pb.TagNumber(99)
  set rtcSignalOffer($18.RtcSignalOffer value) => $_setField(99, value);
  @$pb.TagNumber(99)
  $core.bool hasRtcSignalOffer() => $_has(50);
  @$pb.TagNumber(99)
  void clearRtcSignalOffer() => $_clearField(99);
  @$pb.TagNumber(99)
  $18.RtcSignalOffer ensureRtcSignalOffer() => $_ensure(50);

  @$pb.TagNumber(100)
  $18.RtcSignalAnswer get rtcSignalAnswer => $_getN(51);
  @$pb.TagNumber(100)
  set rtcSignalAnswer($18.RtcSignalAnswer value) => $_setField(100, value);
  @$pb.TagNumber(100)
  $core.bool hasRtcSignalAnswer() => $_has(51);
  @$pb.TagNumber(100)
  void clearRtcSignalAnswer() => $_clearField(100);
  @$pb.TagNumber(100)
  $18.RtcSignalAnswer ensureRtcSignalAnswer() => $_ensure(51);

  @$pb.TagNumber(101)
  $18.RtcSignalIce get rtcSignalIce => $_getN(52);
  @$pb.TagNumber(101)
  set rtcSignalIce($18.RtcSignalIce value) => $_setField(101, value);
  @$pb.TagNumber(101)
  $core.bool hasRtcSignalIce() => $_has(52);
  @$pb.TagNumber(101)
  void clearRtcSignalIce() => $_clearField(101);
  @$pb.TagNumber(101)
  $18.RtcSignalIce ensureRtcSignalIce() => $_ensure(52);

  @$pb.TagNumber(102)
  $19.ResCollectionDefList get collectionDefList => $_getN(53);
  @$pb.TagNumber(102)
  set collectionDefList($19.ResCollectionDefList value) =>
      $_setField(102, value);
  @$pb.TagNumber(102)
  $core.bool hasCollectionDefList() => $_has(53);
  @$pb.TagNumber(102)
  void clearCollectionDefList() => $_clearField(102);
  @$pb.TagNumber(102)
  $19.ResCollectionDefList ensureCollectionDefList() => $_ensure(53);

  @$pb.TagNumber(103)
  $14.ResSiteDraftGet get siteDraftGet => $_getN(54);
  @$pb.TagNumber(103)
  set siteDraftGet($14.ResSiteDraftGet value) => $_setField(103, value);
  @$pb.TagNumber(103)
  $core.bool hasSiteDraftGet() => $_has(54);
  @$pb.TagNumber(103)
  void clearSiteDraftGet() => $_clearField(103);
  @$pb.TagNumber(103)
  $14.ResSiteDraftGet ensureSiteDraftGet() => $_ensure(54);

  @$pb.TagNumber(104)
  $14.ResSiteDraftPut get siteDraftPut => $_getN(55);
  @$pb.TagNumber(104)
  set siteDraftPut($14.ResSiteDraftPut value) => $_setField(104, value);
  @$pb.TagNumber(104)
  $core.bool hasSiteDraftPut() => $_has(55);
  @$pb.TagNumber(104)
  void clearSiteDraftPut() => $_clearField(104);
  @$pb.TagNumber(104)
  $14.ResSiteDraftPut ensureSiteDraftPut() => $_ensure(55);

  @$pb.TagNumber(105)
  $14.ResSitePublish get sitePublish => $_getN(56);
  @$pb.TagNumber(105)
  set sitePublish($14.ResSitePublish value) => $_setField(105, value);
  @$pb.TagNumber(105)
  $core.bool hasSitePublish() => $_has(56);
  @$pb.TagNumber(105)
  void clearSitePublish() => $_clearField(105);
  @$pb.TagNumber(105)
  $14.ResSitePublish ensureSitePublish() => $_ensure(56);

  @$pb.TagNumber(106)
  $14.ResSiteProductList get siteProductList => $_getN(57);
  @$pb.TagNumber(106)
  set siteProductList($14.ResSiteProductList value) => $_setField(106, value);
  @$pb.TagNumber(106)
  $core.bool hasSiteProductList() => $_has(57);
  @$pb.TagNumber(106)
  void clearSiteProductList() => $_clearField(106);
  @$pb.TagNumber(106)
  $14.ResSiteProductList ensureSiteProductList() => $_ensure(57);

  @$pb.TagNumber(107)
  $14.ResSiteProductPut get siteProductPut => $_getN(58);
  @$pb.TagNumber(107)
  set siteProductPut($14.ResSiteProductPut value) => $_setField(107, value);
  @$pb.TagNumber(107)
  $core.bool hasSiteProductPut() => $_has(58);
  @$pb.TagNumber(107)
  void clearSiteProductPut() => $_clearField(107);
  @$pb.TagNumber(107)
  $14.ResSiteProductPut ensureSiteProductPut() => $_ensure(58);

  @$pb.TagNumber(108)
  $14.ResSiteContactList get siteContactList => $_getN(59);
  @$pb.TagNumber(108)
  set siteContactList($14.ResSiteContactList value) => $_setField(108, value);
  @$pb.TagNumber(108)
  $core.bool hasSiteContactList() => $_has(59);
  @$pb.TagNumber(108)
  void clearSiteContactList() => $_clearField(108);
  @$pb.TagNumber(108)
  $14.ResSiteContactList ensureSiteContactList() => $_ensure(59);

  @$pb.TagNumber(109)
  $14.ResSiteContactPut get siteContactPut => $_getN(60);
  @$pb.TagNumber(109)
  set siteContactPut($14.ResSiteContactPut value) => $_setField(109, value);
  @$pb.TagNumber(109)
  $core.bool hasSiteContactPut() => $_has(60);
  @$pb.TagNumber(109)
  void clearSiteContactPut() => $_clearField(109);
  @$pb.TagNumber(109)
  $14.ResSiteContactPut ensureSiteContactPut() => $_ensure(60);

  @$pb.TagNumber(110)
  $14.ResSiteObjectList get siteObjectList => $_getN(61);
  @$pb.TagNumber(110)
  set siteObjectList($14.ResSiteObjectList value) => $_setField(110, value);
  @$pb.TagNumber(110)
  $core.bool hasSiteObjectList() => $_has(61);
  @$pb.TagNumber(110)
  void clearSiteObjectList() => $_clearField(110);
  @$pb.TagNumber(110)
  $14.ResSiteObjectList ensureSiteObjectList() => $_ensure(61);

  @$pb.TagNumber(111)
  $14.ResSiteObjectPut get siteObjectPut => $_getN(62);
  @$pb.TagNumber(111)
  set siteObjectPut($14.ResSiteObjectPut value) => $_setField(111, value);
  @$pb.TagNumber(111)
  $core.bool hasSiteObjectPut() => $_has(62);
  @$pb.TagNumber(111)
  void clearSiteObjectPut() => $_clearField(111);
  @$pb.TagNumber(111)
  $14.ResSiteObjectPut ensureSiteObjectPut() => $_ensure(62);

  @$pb.TagNumber(112)
  $14.ResSiteDomainList get siteDomainList => $_getN(63);
  @$pb.TagNumber(112)
  set siteDomainList($14.ResSiteDomainList value) => $_setField(112, value);
  @$pb.TagNumber(112)
  $core.bool hasSiteDomainList() => $_has(63);
  @$pb.TagNumber(112)
  void clearSiteDomainList() => $_clearField(112);
  @$pb.TagNumber(112)
  $14.ResSiteDomainList ensureSiteDomainList() => $_ensure(63);

  @$pb.TagNumber(113)
  $14.ResSiteDomainPut get siteDomainPut => $_getN(64);
  @$pb.TagNumber(113)
  set siteDomainPut($14.ResSiteDomainPut value) => $_setField(113, value);
  @$pb.TagNumber(113)
  $core.bool hasSiteDomainPut() => $_has(64);
  @$pb.TagNumber(113)
  void clearSiteDomainPut() => $_clearField(113);
  @$pb.TagNumber(113)
  $14.ResSiteDomainPut ensureSiteDomainPut() => $_ensure(64);

  @$pb.TagNumber(114)
  $13.ResSkillCatalogSearch get skillCatalogSearch => $_getN(65);
  @$pb.TagNumber(114)
  set skillCatalogSearch($13.ResSkillCatalogSearch value) =>
      $_setField(114, value);
  @$pb.TagNumber(114)
  $core.bool hasSkillCatalogSearch() => $_has(65);
  @$pb.TagNumber(114)
  void clearSkillCatalogSearch() => $_clearField(114);
  @$pb.TagNumber(114)
  $13.ResSkillCatalogSearch ensureSkillCatalogSearch() => $_ensure(65);

  @$pb.TagNumber(115)
  $13.ResSkillCatalogSubmit get skillCatalogSubmit => $_getN(66);
  @$pb.TagNumber(115)
  set skillCatalogSubmit($13.ResSkillCatalogSubmit value) =>
      $_setField(115, value);
  @$pb.TagNumber(115)
  $core.bool hasSkillCatalogSubmit() => $_has(66);
  @$pb.TagNumber(115)
  void clearSkillCatalogSubmit() => $_clearField(115);
  @$pb.TagNumber(115)
  $13.ResSkillCatalogSubmit ensureSkillCatalogSubmit() => $_ensure(66);

  @$pb.TagNumber(116)
  $13.ResSkillRunReport get skillRunReport => $_getN(67);
  @$pb.TagNumber(116)
  set skillRunReport($13.ResSkillRunReport value) => $_setField(116, value);
  @$pb.TagNumber(116)
  $core.bool hasSkillRunReport() => $_has(67);
  @$pb.TagNumber(116)
  void clearSkillRunReport() => $_clearField(116);
  @$pb.TagNumber(116)
  $13.ResSkillRunReport ensureSkillRunReport() => $_ensure(67);

  @$pb.TagNumber(117)
  $18.ResRemoteScreenshot get resRemoteScreenshot => $_getN(68);
  @$pb.TagNumber(117)
  set resRemoteScreenshot($18.ResRemoteScreenshot value) =>
      $_setField(117, value);
  @$pb.TagNumber(117)
  $core.bool hasResRemoteScreenshot() => $_has(68);
  @$pb.TagNumber(117)
  void clearResRemoteScreenshot() => $_clearField(117);
  @$pb.TagNumber(117)
  $18.ResRemoteScreenshot ensureResRemoteScreenshot() => $_ensure(68);

  @$pb.TagNumber(118)
  $18.ResRemoteCommand get resRemoteCommand => $_getN(69);
  @$pb.TagNumber(118)
  set resRemoteCommand($18.ResRemoteCommand value) => $_setField(118, value);
  @$pb.TagNumber(118)
  $core.bool hasResRemoteCommand() => $_has(69);
  @$pb.TagNumber(118)
  void clearResRemoteCommand() => $_clearField(118);
  @$pb.TagNumber(118)
  $18.ResRemoteCommand ensureResRemoteCommand() => $_ensure(69);

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
  $21.ResHintTouch get hintTouch => $_getN(74);
  @$pb.TagNumber(123)
  set hintTouch($21.ResHintTouch value) => $_setField(123, value);
  @$pb.TagNumber(123)
  $core.bool hasHintTouch() => $_has(74);
  @$pb.TagNumber(123)
  void clearHintTouch() => $_clearField(123);
  @$pb.TagNumber(123)
  $21.ResHintTouch ensureHintTouch() => $_ensure(74);

  @$pb.TagNumber(124)
  $12.PromptRunPush get promptRunPush => $_getN(75);
  @$pb.TagNumber(124)
  set promptRunPush($12.PromptRunPush value) => $_setField(124, value);
  @$pb.TagNumber(124)
  $core.bool hasPromptRunPush() => $_has(75);
  @$pb.TagNumber(124)
  void clearPromptRunPush() => $_clearField(124);
  @$pb.TagNumber(124)
  $12.PromptRunPush ensurePromptRunPush() => $_ensure(75);

  @$pb.TagNumber(125)
  $14.ResSiteConfigPut get siteConfigPut => $_getN(76);
  @$pb.TagNumber(125)
  set siteConfigPut($14.ResSiteConfigPut value) => $_setField(125, value);
  @$pb.TagNumber(125)
  $core.bool hasSiteConfigPut() => $_has(76);
  @$pb.TagNumber(125)
  void clearSiteConfigPut() => $_clearField(125);
  @$pb.TagNumber(125)
  $14.ResSiteConfigPut ensureSiteConfigPut() => $_ensure(76);

  @$pb.TagNumber(126)
  $14.ResSitePreviewToken get sitePreviewToken => $_getN(77);
  @$pb.TagNumber(126)
  set sitePreviewToken($14.ResSitePreviewToken value) => $_setField(126, value);
  @$pb.TagNumber(126)
  $core.bool hasSitePreviewToken() => $_has(77);
  @$pb.TagNumber(126)
  void clearSitePreviewToken() => $_clearField(126);
  @$pb.TagNumber(126)
  $14.ResSitePreviewToken ensureSitePreviewToken() => $_ensure(77);

  @$pb.TagNumber(127)
  $15.ResTxGet get txGet => $_getN(78);
  @$pb.TagNumber(127)
  set txGet($15.ResTxGet value) => $_setField(127, value);
  @$pb.TagNumber(127)
  $core.bool hasTxGet() => $_has(78);
  @$pb.TagNumber(127)
  void clearTxGet() => $_clearField(127);
  @$pb.TagNumber(127)
  $15.ResTxGet ensureTxGet() => $_ensure(78);

  @$pb.TagNumber(128)
  $15.ResTxPut get txPut => $_getN(79);
  @$pb.TagNumber(128)
  set txPut($15.ResTxPut value) => $_setField(128, value);
  @$pb.TagNumber(128)
  $core.bool hasTxPut() => $_has(79);
  @$pb.TagNumber(128)
  void clearTxPut() => $_clearField(128);
  @$pb.TagNumber(128)
  $15.ResTxPut ensureTxPut() => $_ensure(79);

  @$pb.TagNumber(129)
  $15.ResTxPreview get txPreview => $_getN(80);
  @$pb.TagNumber(129)
  set txPreview($15.ResTxPreview value) => $_setField(129, value);
  @$pb.TagNumber(129)
  $core.bool hasTxPreview() => $_has(80);
  @$pb.TagNumber(129)
  void clearTxPreview() => $_clearField(129);
  @$pb.TagNumber(129)
  $15.ResTxPreview ensureTxPreview() => $_ensure(80);

  @$pb.TagNumber(130)
  $15.ResTxDebtPay get txDebtPay => $_getN(81);
  @$pb.TagNumber(130)
  set txDebtPay($15.ResTxDebtPay value) => $_setField(130, value);
  @$pb.TagNumber(130)
  $core.bool hasTxDebtPay() => $_has(81);
  @$pb.TagNumber(130)
  void clearTxDebtPay() => $_clearField(130);
  @$pb.TagNumber(130)
  $15.ResTxDebtPay ensureTxDebtPay() => $_ensure(81);

  @$pb.TagNumber(131)
  $14.ResSiteQueryRun get siteQueryRun => $_getN(82);
  @$pb.TagNumber(131)
  set siteQueryRun($14.ResSiteQueryRun value) => $_setField(131, value);
  @$pb.TagNumber(131)
  $core.bool hasSiteQueryRun() => $_has(82);
  @$pb.TagNumber(131)
  void clearSiteQueryRun() => $_clearField(131);
  @$pb.TagNumber(131)
  $14.ResSiteQueryRun ensureSiteQueryRun() => $_ensure(82);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
