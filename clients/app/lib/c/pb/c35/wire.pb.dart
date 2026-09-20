//
//  Generated code. Do not modify.
//  source: c35/wire.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'billing.pb.dart' as $1;
import 'chat.pb.dart' as $0;
import 'consumption.pb.dart' as $4;
import 'log.pb.dart' as $2;
import 'referral.pb.dart' as $9;
import 'session.pb.dart' as $10;
import 'site.pb.dart' as $5;
import 'skill.pb.dart' as $3;
import 'sync.pb.dart' as $8;
import 'tx.pb.dart' as $6;
import 'types.pb.dart' as $11;

enum InvokeReq_Body {
  billingTopupPut, 
  referralShareSet, 
  referralTreeGet, 
  referralCodeList, 
  referralCodePut, 
  referralCodeDelete, 
  referralUserStats, 
  notSet
}

/// HTTP invoke envelope (referral, admin, billing review, …)
class InvokeReq extends $pb.GeneratedMessage {
  factory InvokeReq({
    $core.String? reqId,
    $fixnum.Int64? callerIid,
    $1.ReqBillingTopupPut? billingTopupPut,
    $9.ReqReferralShareSet? referralShareSet,
    $9.ReqReferralTreeGet? referralTreeGet,
    $9.ReqReferralCodeList? referralCodeList,
    $9.ReqReferralCodePut? referralCodePut,
    $9.ReqReferralCodeDelete? referralCodeDelete,
    $9.ReqReferralUserStats? referralUserStats,
  }) {
    final $result = create();
    if (reqId != null) {
      $result.reqId = reqId;
    }
    if (callerIid != null) {
      $result.callerIid = callerIid;
    }
    if (billingTopupPut != null) {
      $result.billingTopupPut = billingTopupPut;
    }
    if (referralShareSet != null) {
      $result.referralShareSet = referralShareSet;
    }
    if (referralTreeGet != null) {
      $result.referralTreeGet = referralTreeGet;
    }
    if (referralCodeList != null) {
      $result.referralCodeList = referralCodeList;
    }
    if (referralCodePut != null) {
      $result.referralCodePut = referralCodePut;
    }
    if (referralCodeDelete != null) {
      $result.referralCodeDelete = referralCodeDelete;
    }
    if (referralUserStats != null) {
      $result.referralUserStats = referralUserStats;
    }
    return $result;
  }
  InvokeReq._() : super();
  factory InvokeReq.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory InvokeReq.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, InvokeReq_Body> _InvokeReq_BodyByTag = {
    10 : InvokeReq_Body.billingTopupPut,
    62 : InvokeReq_Body.referralShareSet,
    64 : InvokeReq_Body.referralTreeGet,
    65 : InvokeReq_Body.referralCodeList,
    67 : InvokeReq_Body.referralCodePut,
    68 : InvokeReq_Body.referralCodeDelete,
    92 : InvokeReq_Body.referralUserStats,
    0 : InvokeReq_Body.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'InvokeReq', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..oo(0, [10, 62, 64, 65, 67, 68, 92])
    ..aOS(1, _omitFieldNames ? '' : 'reqId')
    ..aInt64(2, _omitFieldNames ? '' : 'callerIid')
    ..aOM<$1.ReqBillingTopupPut>(10, _omitFieldNames ? '' : 'billingTopupPut', subBuilder: $1.ReqBillingTopupPut.create)
    ..aOM<$9.ReqReferralShareSet>(62, _omitFieldNames ? '' : 'referralShareSet', subBuilder: $9.ReqReferralShareSet.create)
    ..aOM<$9.ReqReferralTreeGet>(64, _omitFieldNames ? '' : 'referralTreeGet', subBuilder: $9.ReqReferralTreeGet.create)
    ..aOM<$9.ReqReferralCodeList>(65, _omitFieldNames ? '' : 'referralCodeList', subBuilder: $9.ReqReferralCodeList.create)
    ..aOM<$9.ReqReferralCodePut>(67, _omitFieldNames ? '' : 'referralCodePut', subBuilder: $9.ReqReferralCodePut.create)
    ..aOM<$9.ReqReferralCodeDelete>(68, _omitFieldNames ? '' : 'referralCodeDelete', subBuilder: $9.ReqReferralCodeDelete.create)
    ..aOM<$9.ReqReferralUserStats>(92, _omitFieldNames ? '' : 'referralUserStats', subBuilder: $9.ReqReferralUserStats.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  InvokeReq clone() => InvokeReq()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  InvokeReq copyWith(void Function(InvokeReq) updates) => super.copyWith((message) => updates(message as InvokeReq)) as InvokeReq;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InvokeReq create() => InvokeReq._();
  InvokeReq createEmptyInstance() => create();
  static $pb.PbList<InvokeReq> createRepeated() => $pb.PbList<InvokeReq>();
  @$core.pragma('dart2js:noInline')
  static InvokeReq getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<InvokeReq>(create);
  static InvokeReq? _defaultInstance;

  InvokeReq_Body whichBody() => _InvokeReq_BodyByTag[$_whichOneof(0)]!;
  void clearBody() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get reqId => $_getSZ(0);
  @$pb.TagNumber(1)
  set reqId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasReqId() => $_has(0);
  @$pb.TagNumber(1)
  void clearReqId() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get callerIid => $_getI64(1);
  @$pb.TagNumber(2)
  set callerIid($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasCallerIid() => $_has(1);
  @$pb.TagNumber(2)
  void clearCallerIid() => clearField(2);

  @$pb.TagNumber(10)
  $1.ReqBillingTopupPut get billingTopupPut => $_getN(2);
  @$pb.TagNumber(10)
  set billingTopupPut($1.ReqBillingTopupPut v) { setField(10, v); }
  @$pb.TagNumber(10)
  $core.bool hasBillingTopupPut() => $_has(2);
  @$pb.TagNumber(10)
  void clearBillingTopupPut() => clearField(10);
  @$pb.TagNumber(10)
  $1.ReqBillingTopupPut ensureBillingTopupPut() => $_ensure(2);

  @$pb.TagNumber(62)
  $9.ReqReferralShareSet get referralShareSet => $_getN(3);
  @$pb.TagNumber(62)
  set referralShareSet($9.ReqReferralShareSet v) { setField(62, v); }
  @$pb.TagNumber(62)
  $core.bool hasReferralShareSet() => $_has(3);
  @$pb.TagNumber(62)
  void clearReferralShareSet() => clearField(62);
  @$pb.TagNumber(62)
  $9.ReqReferralShareSet ensureReferralShareSet() => $_ensure(3);

  @$pb.TagNumber(64)
  $9.ReqReferralTreeGet get referralTreeGet => $_getN(4);
  @$pb.TagNumber(64)
  set referralTreeGet($9.ReqReferralTreeGet v) { setField(64, v); }
  @$pb.TagNumber(64)
  $core.bool hasReferralTreeGet() => $_has(4);
  @$pb.TagNumber(64)
  void clearReferralTreeGet() => clearField(64);
  @$pb.TagNumber(64)
  $9.ReqReferralTreeGet ensureReferralTreeGet() => $_ensure(4);

  @$pb.TagNumber(65)
  $9.ReqReferralCodeList get referralCodeList => $_getN(5);
  @$pb.TagNumber(65)
  set referralCodeList($9.ReqReferralCodeList v) { setField(65, v); }
  @$pb.TagNumber(65)
  $core.bool hasReferralCodeList() => $_has(5);
  @$pb.TagNumber(65)
  void clearReferralCodeList() => clearField(65);
  @$pb.TagNumber(65)
  $9.ReqReferralCodeList ensureReferralCodeList() => $_ensure(5);

  @$pb.TagNumber(67)
  $9.ReqReferralCodePut get referralCodePut => $_getN(6);
  @$pb.TagNumber(67)
  set referralCodePut($9.ReqReferralCodePut v) { setField(67, v); }
  @$pb.TagNumber(67)
  $core.bool hasReferralCodePut() => $_has(6);
  @$pb.TagNumber(67)
  void clearReferralCodePut() => clearField(67);
  @$pb.TagNumber(67)
  $9.ReqReferralCodePut ensureReferralCodePut() => $_ensure(6);

  @$pb.TagNumber(68)
  $9.ReqReferralCodeDelete get referralCodeDelete => $_getN(7);
  @$pb.TagNumber(68)
  set referralCodeDelete($9.ReqReferralCodeDelete v) { setField(68, v); }
  @$pb.TagNumber(68)
  $core.bool hasReferralCodeDelete() => $_has(7);
  @$pb.TagNumber(68)
  void clearReferralCodeDelete() => clearField(68);
  @$pb.TagNumber(68)
  $9.ReqReferralCodeDelete ensureReferralCodeDelete() => $_ensure(7);

  @$pb.TagNumber(92)
  $9.ReqReferralUserStats get referralUserStats => $_getN(8);
  @$pb.TagNumber(92)
  set referralUserStats($9.ReqReferralUserStats v) { setField(92, v); }
  @$pb.TagNumber(92)
  $core.bool hasReferralUserStats() => $_has(8);
  @$pb.TagNumber(92)
  void clearReferralUserStats() => clearField(92);
  @$pb.TagNumber(92)
  $9.ReqReferralUserStats ensureReferralUserStats() => $_ensure(8);
}

enum InvokeRes_Body {
  billingTopupPut, 
  referralShareSet, 
  referralTreeGet, 
  referralCodeList, 
  referralCodePut, 
  referralUserStats, 
  notSet
}

class InvokeRes extends $pb.GeneratedMessage {
  factory InvokeRes({
    $core.String? reqId,
    $core.int? statusCode,
    $core.String? errorMessage,
    $1.ResBillingTopupPut? billingTopupPut,
    $9.ResReferralShareSet? referralShareSet,
    $9.ResReferralTreeGet? referralTreeGet,
    $9.ResReferralCodeList? referralCodeList,
    $9.ReferralCodeDoc? referralCodePut,
    $9.ResReferralUserStats? referralUserStats,
  }) {
    final $result = create();
    if (reqId != null) {
      $result.reqId = reqId;
    }
    if (statusCode != null) {
      $result.statusCode = statusCode;
    }
    if (errorMessage != null) {
      $result.errorMessage = errorMessage;
    }
    if (billingTopupPut != null) {
      $result.billingTopupPut = billingTopupPut;
    }
    if (referralShareSet != null) {
      $result.referralShareSet = referralShareSet;
    }
    if (referralTreeGet != null) {
      $result.referralTreeGet = referralTreeGet;
    }
    if (referralCodeList != null) {
      $result.referralCodeList = referralCodeList;
    }
    if (referralCodePut != null) {
      $result.referralCodePut = referralCodePut;
    }
    if (referralUserStats != null) {
      $result.referralUserStats = referralUserStats;
    }
    return $result;
  }
  InvokeRes._() : super();
  factory InvokeRes.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory InvokeRes.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, InvokeRes_Body> _InvokeRes_BodyByTag = {
    10 : InvokeRes_Body.billingTopupPut,
    62 : InvokeRes_Body.referralShareSet,
    64 : InvokeRes_Body.referralTreeGet,
    65 : InvokeRes_Body.referralCodeList,
    67 : InvokeRes_Body.referralCodePut,
    92 : InvokeRes_Body.referralUserStats,
    0 : InvokeRes_Body.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'InvokeRes', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..oo(0, [10, 62, 64, 65, 67, 92])
    ..aOS(1, _omitFieldNames ? '' : 'reqId')
    ..a<$core.int>(2, _omitFieldNames ? '' : 'statusCode', $pb.PbFieldType.O3)
    ..aOS(3, _omitFieldNames ? '' : 'errorMessage')
    ..aOM<$1.ResBillingTopupPut>(10, _omitFieldNames ? '' : 'billingTopupPut', subBuilder: $1.ResBillingTopupPut.create)
    ..aOM<$9.ResReferralShareSet>(62, _omitFieldNames ? '' : 'referralShareSet', subBuilder: $9.ResReferralShareSet.create)
    ..aOM<$9.ResReferralTreeGet>(64, _omitFieldNames ? '' : 'referralTreeGet', subBuilder: $9.ResReferralTreeGet.create)
    ..aOM<$9.ResReferralCodeList>(65, _omitFieldNames ? '' : 'referralCodeList', subBuilder: $9.ResReferralCodeList.create)
    ..aOM<$9.ReferralCodeDoc>(67, _omitFieldNames ? '' : 'referralCodePut', subBuilder: $9.ReferralCodeDoc.create)
    ..aOM<$9.ResReferralUserStats>(92, _omitFieldNames ? '' : 'referralUserStats', subBuilder: $9.ResReferralUserStats.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  InvokeRes clone() => InvokeRes()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  InvokeRes copyWith(void Function(InvokeRes) updates) => super.copyWith((message) => updates(message as InvokeRes)) as InvokeRes;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InvokeRes create() => InvokeRes._();
  InvokeRes createEmptyInstance() => create();
  static $pb.PbList<InvokeRes> createRepeated() => $pb.PbList<InvokeRes>();
  @$core.pragma('dart2js:noInline')
  static InvokeRes getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<InvokeRes>(create);
  static InvokeRes? _defaultInstance;

  InvokeRes_Body whichBody() => _InvokeRes_BodyByTag[$_whichOneof(0)]!;
  void clearBody() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get reqId => $_getSZ(0);
  @$pb.TagNumber(1)
  set reqId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasReqId() => $_has(0);
  @$pb.TagNumber(1)
  void clearReqId() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get statusCode => $_getIZ(1);
  @$pb.TagNumber(2)
  set statusCode($core.int v) { $_setSignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasStatusCode() => $_has(1);
  @$pb.TagNumber(2)
  void clearStatusCode() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get errorMessage => $_getSZ(2);
  @$pb.TagNumber(3)
  set errorMessage($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasErrorMessage() => $_has(2);
  @$pb.TagNumber(3)
  void clearErrorMessage() => clearField(3);

  @$pb.TagNumber(10)
  $1.ResBillingTopupPut get billingTopupPut => $_getN(3);
  @$pb.TagNumber(10)
  set billingTopupPut($1.ResBillingTopupPut v) { setField(10, v); }
  @$pb.TagNumber(10)
  $core.bool hasBillingTopupPut() => $_has(3);
  @$pb.TagNumber(10)
  void clearBillingTopupPut() => clearField(10);
  @$pb.TagNumber(10)
  $1.ResBillingTopupPut ensureBillingTopupPut() => $_ensure(3);

  @$pb.TagNumber(62)
  $9.ResReferralShareSet get referralShareSet => $_getN(4);
  @$pb.TagNumber(62)
  set referralShareSet($9.ResReferralShareSet v) { setField(62, v); }
  @$pb.TagNumber(62)
  $core.bool hasReferralShareSet() => $_has(4);
  @$pb.TagNumber(62)
  void clearReferralShareSet() => clearField(62);
  @$pb.TagNumber(62)
  $9.ResReferralShareSet ensureReferralShareSet() => $_ensure(4);

  @$pb.TagNumber(64)
  $9.ResReferralTreeGet get referralTreeGet => $_getN(5);
  @$pb.TagNumber(64)
  set referralTreeGet($9.ResReferralTreeGet v) { setField(64, v); }
  @$pb.TagNumber(64)
  $core.bool hasReferralTreeGet() => $_has(5);
  @$pb.TagNumber(64)
  void clearReferralTreeGet() => clearField(64);
  @$pb.TagNumber(64)
  $9.ResReferralTreeGet ensureReferralTreeGet() => $_ensure(5);

  @$pb.TagNumber(65)
  $9.ResReferralCodeList get referralCodeList => $_getN(6);
  @$pb.TagNumber(65)
  set referralCodeList($9.ResReferralCodeList v) { setField(65, v); }
  @$pb.TagNumber(65)
  $core.bool hasReferralCodeList() => $_has(6);
  @$pb.TagNumber(65)
  void clearReferralCodeList() => clearField(65);
  @$pb.TagNumber(65)
  $9.ResReferralCodeList ensureReferralCodeList() => $_ensure(6);

  @$pb.TagNumber(67)
  $9.ReferralCodeDoc get referralCodePut => $_getN(7);
  @$pb.TagNumber(67)
  set referralCodePut($9.ReferralCodeDoc v) { setField(67, v); }
  @$pb.TagNumber(67)
  $core.bool hasReferralCodePut() => $_has(7);
  @$pb.TagNumber(67)
  void clearReferralCodePut() => clearField(67);
  @$pb.TagNumber(67)
  $9.ReferralCodeDoc ensureReferralCodePut() => $_ensure(7);

  @$pb.TagNumber(92)
  $9.ResReferralUserStats get referralUserStats => $_getN(8);
  @$pb.TagNumber(92)
  set referralUserStats($9.ResReferralUserStats v) { setField(92, v); }
  @$pb.TagNumber(92)
  $core.bool hasReferralUserStats() => $_has(8);
  @$pb.TagNumber(92)
  void clearReferralUserStats() => clearField(92);
  @$pb.TagNumber(92)
  $9.ResReferralUserStats ensureReferralUserStats() => $_ensure(8);
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
  notSet
}

/// WebSocket client → server
class WsReq extends $pb.GeneratedMessage {
  factory WsReq({
    $core.String? reqId,
    $10.ReqSessionInit? sessionInit,
    $8.ReqSync? sync,
    $0.ReqInboxList? inboxList,
    $0.ReqChatMsgList? chatMsgList,
    $0.ReqPrompt? prompt,
    $0.ReqPromptAbort? promptAbort,
    $0.ReqChatStop? chatStop,
    $0.ReqChatSend? chatSend,
    InvokeReq? invoke,
    $3.ReqSkillList? skillList,
    $4.ReqConsumptionList? consumptionList,
    $5.ReqSiteList? siteList,
    $6.ReqTxList? txList,
  }) {
    final $result = create();
    if (reqId != null) {
      $result.reqId = reqId;
    }
    if (sessionInit != null) {
      $result.sessionInit = sessionInit;
    }
    if (sync != null) {
      $result.sync = sync;
    }
    if (inboxList != null) {
      $result.inboxList = inboxList;
    }
    if (chatMsgList != null) {
      $result.chatMsgList = chatMsgList;
    }
    if (prompt != null) {
      $result.prompt = prompt;
    }
    if (promptAbort != null) {
      $result.promptAbort = promptAbort;
    }
    if (chatStop != null) {
      $result.chatStop = chatStop;
    }
    if (chatSend != null) {
      $result.chatSend = chatSend;
    }
    if (invoke != null) {
      $result.invoke = invoke;
    }
    if (skillList != null) {
      $result.skillList = skillList;
    }
    if (consumptionList != null) {
      $result.consumptionList = consumptionList;
    }
    if (siteList != null) {
      $result.siteList = siteList;
    }
    if (txList != null) {
      $result.txList = txList;
    }
    return $result;
  }
  WsReq._() : super();
  factory WsReq.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory WsReq.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, WsReq_Body> _WsReq_BodyByTag = {
    2 : WsReq_Body.sessionInit,
    3 : WsReq_Body.sync,
    4 : WsReq_Body.inboxList,
    5 : WsReq_Body.chatMsgList,
    6 : WsReq_Body.prompt,
    7 : WsReq_Body.promptAbort,
    8 : WsReq_Body.chatStop,
    9 : WsReq_Body.chatSend,
    10 : WsReq_Body.invoke,
    20 : WsReq_Body.skillList,
    21 : WsReq_Body.consumptionList,
    22 : WsReq_Body.siteList,
    23 : WsReq_Body.txList,
    0 : WsReq_Body.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'WsReq', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..oo(0, [2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 21, 22, 23])
    ..aOS(1, _omitFieldNames ? '' : 'reqId')
    ..aOM<$10.ReqSessionInit>(2, _omitFieldNames ? '' : 'sessionInit', subBuilder: $10.ReqSessionInit.create)
    ..aOM<$8.ReqSync>(3, _omitFieldNames ? '' : 'sync', subBuilder: $8.ReqSync.create)
    ..aOM<$0.ReqInboxList>(4, _omitFieldNames ? '' : 'inboxList', subBuilder: $0.ReqInboxList.create)
    ..aOM<$0.ReqChatMsgList>(5, _omitFieldNames ? '' : 'chatMsgList', subBuilder: $0.ReqChatMsgList.create)
    ..aOM<$0.ReqPrompt>(6, _omitFieldNames ? '' : 'prompt', subBuilder: $0.ReqPrompt.create)
    ..aOM<$0.ReqPromptAbort>(7, _omitFieldNames ? '' : 'promptAbort', subBuilder: $0.ReqPromptAbort.create)
    ..aOM<$0.ReqChatStop>(8, _omitFieldNames ? '' : 'chatStop', subBuilder: $0.ReqChatStop.create)
    ..aOM<$0.ReqChatSend>(9, _omitFieldNames ? '' : 'chatSend', subBuilder: $0.ReqChatSend.create)
    ..aOM<InvokeReq>(10, _omitFieldNames ? '' : 'invoke', subBuilder: InvokeReq.create)
    ..aOM<$3.ReqSkillList>(20, _omitFieldNames ? '' : 'skillList', subBuilder: $3.ReqSkillList.create)
    ..aOM<$4.ReqConsumptionList>(21, _omitFieldNames ? '' : 'consumptionList', subBuilder: $4.ReqConsumptionList.create)
    ..aOM<$5.ReqSiteList>(22, _omitFieldNames ? '' : 'siteList', subBuilder: $5.ReqSiteList.create)
    ..aOM<$6.ReqTxList>(23, _omitFieldNames ? '' : 'txList', subBuilder: $6.ReqTxList.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  WsReq clone() => WsReq()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  WsReq copyWith(void Function(WsReq) updates) => super.copyWith((message) => updates(message as WsReq)) as WsReq;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WsReq create() => WsReq._();
  WsReq createEmptyInstance() => create();
  static $pb.PbList<WsReq> createRepeated() => $pb.PbList<WsReq>();
  @$core.pragma('dart2js:noInline')
  static WsReq getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<WsReq>(create);
  static WsReq? _defaultInstance;

  WsReq_Body whichBody() => _WsReq_BodyByTag[$_whichOneof(0)]!;
  void clearBody() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get reqId => $_getSZ(0);
  @$pb.TagNumber(1)
  set reqId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasReqId() => $_has(0);
  @$pb.TagNumber(1)
  void clearReqId() => clearField(1);

  @$pb.TagNumber(2)
  $10.ReqSessionInit get sessionInit => $_getN(1);
  @$pb.TagNumber(2)
  set sessionInit($10.ReqSessionInit v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasSessionInit() => $_has(1);
  @$pb.TagNumber(2)
  void clearSessionInit() => clearField(2);
  @$pb.TagNumber(2)
  $10.ReqSessionInit ensureSessionInit() => $_ensure(1);

  @$pb.TagNumber(3)
  $8.ReqSync get sync => $_getN(2);
  @$pb.TagNumber(3)
  set sync($8.ReqSync v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasSync() => $_has(2);
  @$pb.TagNumber(3)
  void clearSync() => clearField(3);
  @$pb.TagNumber(3)
  $8.ReqSync ensureSync() => $_ensure(2);

  @$pb.TagNumber(4)
  $0.ReqInboxList get inboxList => $_getN(3);
  @$pb.TagNumber(4)
  set inboxList($0.ReqInboxList v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasInboxList() => $_has(3);
  @$pb.TagNumber(4)
  void clearInboxList() => clearField(4);
  @$pb.TagNumber(4)
  $0.ReqInboxList ensureInboxList() => $_ensure(3);

  @$pb.TagNumber(5)
  $0.ReqChatMsgList get chatMsgList => $_getN(4);
  @$pb.TagNumber(5)
  set chatMsgList($0.ReqChatMsgList v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasChatMsgList() => $_has(4);
  @$pb.TagNumber(5)
  void clearChatMsgList() => clearField(5);
  @$pb.TagNumber(5)
  $0.ReqChatMsgList ensureChatMsgList() => $_ensure(4);

  @$pb.TagNumber(6)
  $0.ReqPrompt get prompt => $_getN(5);
  @$pb.TagNumber(6)
  set prompt($0.ReqPrompt v) { setField(6, v); }
  @$pb.TagNumber(6)
  $core.bool hasPrompt() => $_has(5);
  @$pb.TagNumber(6)
  void clearPrompt() => clearField(6);
  @$pb.TagNumber(6)
  $0.ReqPrompt ensurePrompt() => $_ensure(5);

  @$pb.TagNumber(7)
  $0.ReqPromptAbort get promptAbort => $_getN(6);
  @$pb.TagNumber(7)
  set promptAbort($0.ReqPromptAbort v) { setField(7, v); }
  @$pb.TagNumber(7)
  $core.bool hasPromptAbort() => $_has(6);
  @$pb.TagNumber(7)
  void clearPromptAbort() => clearField(7);
  @$pb.TagNumber(7)
  $0.ReqPromptAbort ensurePromptAbort() => $_ensure(6);

  @$pb.TagNumber(8)
  $0.ReqChatStop get chatStop => $_getN(7);
  @$pb.TagNumber(8)
  set chatStop($0.ReqChatStop v) { setField(8, v); }
  @$pb.TagNumber(8)
  $core.bool hasChatStop() => $_has(7);
  @$pb.TagNumber(8)
  void clearChatStop() => clearField(8);
  @$pb.TagNumber(8)
  $0.ReqChatStop ensureChatStop() => $_ensure(7);

  @$pb.TagNumber(9)
  $0.ReqChatSend get chatSend => $_getN(8);
  @$pb.TagNumber(9)
  set chatSend($0.ReqChatSend v) { setField(9, v); }
  @$pb.TagNumber(9)
  $core.bool hasChatSend() => $_has(8);
  @$pb.TagNumber(9)
  void clearChatSend() => clearField(9);
  @$pb.TagNumber(9)
  $0.ReqChatSend ensureChatSend() => $_ensure(8);

  @$pb.TagNumber(10)
  InvokeReq get invoke => $_getN(9);
  @$pb.TagNumber(10)
  set invoke(InvokeReq v) { setField(10, v); }
  @$pb.TagNumber(10)
  $core.bool hasInvoke() => $_has(9);
  @$pb.TagNumber(10)
  void clearInvoke() => clearField(10);
  @$pb.TagNumber(10)
  InvokeReq ensureInvoke() => $_ensure(9);

  @$pb.TagNumber(20)
  $3.ReqSkillList get skillList => $_getN(10);
  @$pb.TagNumber(20)
  set skillList($3.ReqSkillList v) { setField(20, v); }
  @$pb.TagNumber(20)
  $core.bool hasSkillList() => $_has(10);
  @$pb.TagNumber(20)
  void clearSkillList() => clearField(20);
  @$pb.TagNumber(20)
  $3.ReqSkillList ensureSkillList() => $_ensure(10);

  @$pb.TagNumber(21)
  $4.ReqConsumptionList get consumptionList => $_getN(11);
  @$pb.TagNumber(21)
  set consumptionList($4.ReqConsumptionList v) { setField(21, v); }
  @$pb.TagNumber(21)
  $core.bool hasConsumptionList() => $_has(11);
  @$pb.TagNumber(21)
  void clearConsumptionList() => clearField(21);
  @$pb.TagNumber(21)
  $4.ReqConsumptionList ensureConsumptionList() => $_ensure(11);

  @$pb.TagNumber(22)
  $5.ReqSiteList get siteList => $_getN(12);
  @$pb.TagNumber(22)
  set siteList($5.ReqSiteList v) { setField(22, v); }
  @$pb.TagNumber(22)
  $core.bool hasSiteList() => $_has(12);
  @$pb.TagNumber(22)
  void clearSiteList() => clearField(22);
  @$pb.TagNumber(22)
  $5.ReqSiteList ensureSiteList() => $_ensure(12);

  @$pb.TagNumber(23)
  $6.ReqTxList get txList => $_getN(13);
  @$pb.TagNumber(23)
  set txList($6.ReqTxList v) { setField(23, v); }
  @$pb.TagNumber(23)
  $core.bool hasTxList() => $_has(13);
  @$pb.TagNumber(23)
  void clearTxList() => clearField(23);
  @$pb.TagNumber(23)
  $6.ReqTxList ensureTxList() => $_ensure(13);
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
  chatStop, 
  chatSend, 
  invoke, 
  syncPush, 
  billingBalance, 
  billingQuota, 
  billingCommission, 
  logPush, 
  skillList, 
  consumptionList, 
  siteList, 
  txList, 
  notSet
}

/// WebSocket server → client
class WsRes extends $pb.GeneratedMessage {
  factory WsRes({
    $core.String? reqId,
    $11.Err? err,
    $10.ResSessionInit? sessionInit,
    $8.ResSync? sync,
    $0.ResInboxList? inboxList,
    $0.ResChatMsgList? chatMsgList,
    $0.ResPromptStart? promptStart,
    $0.ResPromptDelta? promptDelta,
    $0.ResPromptEnd? promptEnd,
    $0.ResPromptFail? promptFail,
    $0.ResChatStop? chatStop,
    $0.ResChatSend? chatSend,
    InvokeRes? invoke,
    $8.SyncPush? syncPush,
    $1.BillingPushBalance? billingBalance,
    $1.BillingPushQuota? billingQuota,
    $1.BillingPushCommission? billingCommission,
    $2.LogPush? logPush,
    $3.ResSkillList? skillList,
    $4.ResConsumptionList? consumptionList,
    $5.ResSiteList? siteList,
    $6.ResTxList? txList,
  }) {
    final $result = create();
    if (reqId != null) {
      $result.reqId = reqId;
    }
    if (err != null) {
      $result.err = err;
    }
    if (sessionInit != null) {
      $result.sessionInit = sessionInit;
    }
    if (sync != null) {
      $result.sync = sync;
    }
    if (inboxList != null) {
      $result.inboxList = inboxList;
    }
    if (chatMsgList != null) {
      $result.chatMsgList = chatMsgList;
    }
    if (promptStart != null) {
      $result.promptStart = promptStart;
    }
    if (promptDelta != null) {
      $result.promptDelta = promptDelta;
    }
    if (promptEnd != null) {
      $result.promptEnd = promptEnd;
    }
    if (promptFail != null) {
      $result.promptFail = promptFail;
    }
    if (chatStop != null) {
      $result.chatStop = chatStop;
    }
    if (chatSend != null) {
      $result.chatSend = chatSend;
    }
    if (invoke != null) {
      $result.invoke = invoke;
    }
    if (syncPush != null) {
      $result.syncPush = syncPush;
    }
    if (billingBalance != null) {
      $result.billingBalance = billingBalance;
    }
    if (billingQuota != null) {
      $result.billingQuota = billingQuota;
    }
    if (billingCommission != null) {
      $result.billingCommission = billingCommission;
    }
    if (logPush != null) {
      $result.logPush = logPush;
    }
    if (skillList != null) {
      $result.skillList = skillList;
    }
    if (consumptionList != null) {
      $result.consumptionList = consumptionList;
    }
    if (siteList != null) {
      $result.siteList = siteList;
    }
    if (txList != null) {
      $result.txList = txList;
    }
    return $result;
  }
  WsRes._() : super();
  factory WsRes.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory WsRes.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, WsRes_Body> _WsRes_BodyByTag = {
    2 : WsRes_Body.err,
    10 : WsRes_Body.sessionInit,
    11 : WsRes_Body.sync,
    12 : WsRes_Body.inboxList,
    13 : WsRes_Body.chatMsgList,
    20 : WsRes_Body.promptStart,
    21 : WsRes_Body.promptDelta,
    22 : WsRes_Body.promptEnd,
    23 : WsRes_Body.promptFail,
    30 : WsRes_Body.chatStop,
    31 : WsRes_Body.chatSend,
    40 : WsRes_Body.invoke,
    50 : WsRes_Body.syncPush,
    60 : WsRes_Body.billingBalance,
    61 : WsRes_Body.billingQuota,
    62 : WsRes_Body.billingCommission,
    70 : WsRes_Body.logPush,
    80 : WsRes_Body.skillList,
    81 : WsRes_Body.consumptionList,
    82 : WsRes_Body.siteList,
    83 : WsRes_Body.txList,
    0 : WsRes_Body.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'WsRes', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..oo(0, [2, 10, 11, 12, 13, 20, 21, 22, 23, 30, 31, 40, 50, 60, 61, 62, 70, 80, 81, 82, 83])
    ..aOS(1, _omitFieldNames ? '' : 'reqId')
    ..aOM<$11.Err>(2, _omitFieldNames ? '' : 'err', subBuilder: $11.Err.create)
    ..aOM<$10.ResSessionInit>(10, _omitFieldNames ? '' : 'sessionInit', subBuilder: $10.ResSessionInit.create)
    ..aOM<$8.ResSync>(11, _omitFieldNames ? '' : 'sync', subBuilder: $8.ResSync.create)
    ..aOM<$0.ResInboxList>(12, _omitFieldNames ? '' : 'inboxList', subBuilder: $0.ResInboxList.create)
    ..aOM<$0.ResChatMsgList>(13, _omitFieldNames ? '' : 'chatMsgList', subBuilder: $0.ResChatMsgList.create)
    ..aOM<$0.ResPromptStart>(20, _omitFieldNames ? '' : 'promptStart', subBuilder: $0.ResPromptStart.create)
    ..aOM<$0.ResPromptDelta>(21, _omitFieldNames ? '' : 'promptDelta', subBuilder: $0.ResPromptDelta.create)
    ..aOM<$0.ResPromptEnd>(22, _omitFieldNames ? '' : 'promptEnd', subBuilder: $0.ResPromptEnd.create)
    ..aOM<$0.ResPromptFail>(23, _omitFieldNames ? '' : 'promptFail', subBuilder: $0.ResPromptFail.create)
    ..aOM<$0.ResChatStop>(30, _omitFieldNames ? '' : 'chatStop', subBuilder: $0.ResChatStop.create)
    ..aOM<$0.ResChatSend>(31, _omitFieldNames ? '' : 'chatSend', subBuilder: $0.ResChatSend.create)
    ..aOM<InvokeRes>(40, _omitFieldNames ? '' : 'invoke', subBuilder: InvokeRes.create)
    ..aOM<$8.SyncPush>(50, _omitFieldNames ? '' : 'syncPush', subBuilder: $8.SyncPush.create)
    ..aOM<$1.BillingPushBalance>(60, _omitFieldNames ? '' : 'billingBalance', subBuilder: $1.BillingPushBalance.create)
    ..aOM<$1.BillingPushQuota>(61, _omitFieldNames ? '' : 'billingQuota', subBuilder: $1.BillingPushQuota.create)
    ..aOM<$1.BillingPushCommission>(62, _omitFieldNames ? '' : 'billingCommission', subBuilder: $1.BillingPushCommission.create)
    ..aOM<$2.LogPush>(70, _omitFieldNames ? '' : 'logPush', subBuilder: $2.LogPush.create)
    ..aOM<$3.ResSkillList>(80, _omitFieldNames ? '' : 'skillList', subBuilder: $3.ResSkillList.create)
    ..aOM<$4.ResConsumptionList>(81, _omitFieldNames ? '' : 'consumptionList', subBuilder: $4.ResConsumptionList.create)
    ..aOM<$5.ResSiteList>(82, _omitFieldNames ? '' : 'siteList', subBuilder: $5.ResSiteList.create)
    ..aOM<$6.ResTxList>(83, _omitFieldNames ? '' : 'txList', subBuilder: $6.ResTxList.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  WsRes clone() => WsRes()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  WsRes copyWith(void Function(WsRes) updates) => super.copyWith((message) => updates(message as WsRes)) as WsRes;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WsRes create() => WsRes._();
  WsRes createEmptyInstance() => create();
  static $pb.PbList<WsRes> createRepeated() => $pb.PbList<WsRes>();
  @$core.pragma('dart2js:noInline')
  static WsRes getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<WsRes>(create);
  static WsRes? _defaultInstance;

  WsRes_Body whichBody() => _WsRes_BodyByTag[$_whichOneof(0)]!;
  void clearBody() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get reqId => $_getSZ(0);
  @$pb.TagNumber(1)
  set reqId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasReqId() => $_has(0);
  @$pb.TagNumber(1)
  void clearReqId() => clearField(1);

  @$pb.TagNumber(2)
  $11.Err get err => $_getN(1);
  @$pb.TagNumber(2)
  set err($11.Err v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasErr() => $_has(1);
  @$pb.TagNumber(2)
  void clearErr() => clearField(2);
  @$pb.TagNumber(2)
  $11.Err ensureErr() => $_ensure(1);

  @$pb.TagNumber(10)
  $10.ResSessionInit get sessionInit => $_getN(2);
  @$pb.TagNumber(10)
  set sessionInit($10.ResSessionInit v) { setField(10, v); }
  @$pb.TagNumber(10)
  $core.bool hasSessionInit() => $_has(2);
  @$pb.TagNumber(10)
  void clearSessionInit() => clearField(10);
  @$pb.TagNumber(10)
  $10.ResSessionInit ensureSessionInit() => $_ensure(2);

  @$pb.TagNumber(11)
  $8.ResSync get sync => $_getN(3);
  @$pb.TagNumber(11)
  set sync($8.ResSync v) { setField(11, v); }
  @$pb.TagNumber(11)
  $core.bool hasSync() => $_has(3);
  @$pb.TagNumber(11)
  void clearSync() => clearField(11);
  @$pb.TagNumber(11)
  $8.ResSync ensureSync() => $_ensure(3);

  @$pb.TagNumber(12)
  $0.ResInboxList get inboxList => $_getN(4);
  @$pb.TagNumber(12)
  set inboxList($0.ResInboxList v) { setField(12, v); }
  @$pb.TagNumber(12)
  $core.bool hasInboxList() => $_has(4);
  @$pb.TagNumber(12)
  void clearInboxList() => clearField(12);
  @$pb.TagNumber(12)
  $0.ResInboxList ensureInboxList() => $_ensure(4);

  @$pb.TagNumber(13)
  $0.ResChatMsgList get chatMsgList => $_getN(5);
  @$pb.TagNumber(13)
  set chatMsgList($0.ResChatMsgList v) { setField(13, v); }
  @$pb.TagNumber(13)
  $core.bool hasChatMsgList() => $_has(5);
  @$pb.TagNumber(13)
  void clearChatMsgList() => clearField(13);
  @$pb.TagNumber(13)
  $0.ResChatMsgList ensureChatMsgList() => $_ensure(5);

  @$pb.TagNumber(20)
  $0.ResPromptStart get promptStart => $_getN(6);
  @$pb.TagNumber(20)
  set promptStart($0.ResPromptStart v) { setField(20, v); }
  @$pb.TagNumber(20)
  $core.bool hasPromptStart() => $_has(6);
  @$pb.TagNumber(20)
  void clearPromptStart() => clearField(20);
  @$pb.TagNumber(20)
  $0.ResPromptStart ensurePromptStart() => $_ensure(6);

  @$pb.TagNumber(21)
  $0.ResPromptDelta get promptDelta => $_getN(7);
  @$pb.TagNumber(21)
  set promptDelta($0.ResPromptDelta v) { setField(21, v); }
  @$pb.TagNumber(21)
  $core.bool hasPromptDelta() => $_has(7);
  @$pb.TagNumber(21)
  void clearPromptDelta() => clearField(21);
  @$pb.TagNumber(21)
  $0.ResPromptDelta ensurePromptDelta() => $_ensure(7);

  @$pb.TagNumber(22)
  $0.ResPromptEnd get promptEnd => $_getN(8);
  @$pb.TagNumber(22)
  set promptEnd($0.ResPromptEnd v) { setField(22, v); }
  @$pb.TagNumber(22)
  $core.bool hasPromptEnd() => $_has(8);
  @$pb.TagNumber(22)
  void clearPromptEnd() => clearField(22);
  @$pb.TagNumber(22)
  $0.ResPromptEnd ensurePromptEnd() => $_ensure(8);

  @$pb.TagNumber(23)
  $0.ResPromptFail get promptFail => $_getN(9);
  @$pb.TagNumber(23)
  set promptFail($0.ResPromptFail v) { setField(23, v); }
  @$pb.TagNumber(23)
  $core.bool hasPromptFail() => $_has(9);
  @$pb.TagNumber(23)
  void clearPromptFail() => clearField(23);
  @$pb.TagNumber(23)
  $0.ResPromptFail ensurePromptFail() => $_ensure(9);

  @$pb.TagNumber(30)
  $0.ResChatStop get chatStop => $_getN(10);
  @$pb.TagNumber(30)
  set chatStop($0.ResChatStop v) { setField(30, v); }
  @$pb.TagNumber(30)
  $core.bool hasChatStop() => $_has(10);
  @$pb.TagNumber(30)
  void clearChatStop() => clearField(30);
  @$pb.TagNumber(30)
  $0.ResChatStop ensureChatStop() => $_ensure(10);

  @$pb.TagNumber(31)
  $0.ResChatSend get chatSend => $_getN(11);
  @$pb.TagNumber(31)
  set chatSend($0.ResChatSend v) { setField(31, v); }
  @$pb.TagNumber(31)
  $core.bool hasChatSend() => $_has(11);
  @$pb.TagNumber(31)
  void clearChatSend() => clearField(31);
  @$pb.TagNumber(31)
  $0.ResChatSend ensureChatSend() => $_ensure(11);

  @$pb.TagNumber(40)
  InvokeRes get invoke => $_getN(12);
  @$pb.TagNumber(40)
  set invoke(InvokeRes v) { setField(40, v); }
  @$pb.TagNumber(40)
  $core.bool hasInvoke() => $_has(12);
  @$pb.TagNumber(40)
  void clearInvoke() => clearField(40);
  @$pb.TagNumber(40)
  InvokeRes ensureInvoke() => $_ensure(12);

  @$pb.TagNumber(50)
  $8.SyncPush get syncPush => $_getN(13);
  @$pb.TagNumber(50)
  set syncPush($8.SyncPush v) { setField(50, v); }
  @$pb.TagNumber(50)
  $core.bool hasSyncPush() => $_has(13);
  @$pb.TagNumber(50)
  void clearSyncPush() => clearField(50);
  @$pb.TagNumber(50)
  $8.SyncPush ensureSyncPush() => $_ensure(13);

  @$pb.TagNumber(60)
  $1.BillingPushBalance get billingBalance => $_getN(14);
  @$pb.TagNumber(60)
  set billingBalance($1.BillingPushBalance v) { setField(60, v); }
  @$pb.TagNumber(60)
  $core.bool hasBillingBalance() => $_has(14);
  @$pb.TagNumber(60)
  void clearBillingBalance() => clearField(60);
  @$pb.TagNumber(60)
  $1.BillingPushBalance ensureBillingBalance() => $_ensure(14);

  @$pb.TagNumber(61)
  $1.BillingPushQuota get billingQuota => $_getN(15);
  @$pb.TagNumber(61)
  set billingQuota($1.BillingPushQuota v) { setField(61, v); }
  @$pb.TagNumber(61)
  $core.bool hasBillingQuota() => $_has(15);
  @$pb.TagNumber(61)
  void clearBillingQuota() => clearField(61);
  @$pb.TagNumber(61)
  $1.BillingPushQuota ensureBillingQuota() => $_ensure(15);

  @$pb.TagNumber(62)
  $1.BillingPushCommission get billingCommission => $_getN(16);
  @$pb.TagNumber(62)
  set billingCommission($1.BillingPushCommission v) { setField(62, v); }
  @$pb.TagNumber(62)
  $core.bool hasBillingCommission() => $_has(16);
  @$pb.TagNumber(62)
  void clearBillingCommission() => clearField(62);
  @$pb.TagNumber(62)
  $1.BillingPushCommission ensureBillingCommission() => $_ensure(16);

  @$pb.TagNumber(70)
  $2.LogPush get logPush => $_getN(17);
  @$pb.TagNumber(70)
  set logPush($2.LogPush v) { setField(70, v); }
  @$pb.TagNumber(70)
  $core.bool hasLogPush() => $_has(17);
  @$pb.TagNumber(70)
  void clearLogPush() => clearField(70);
  @$pb.TagNumber(70)
  $2.LogPush ensureLogPush() => $_ensure(17);

  @$pb.TagNumber(80)
  $3.ResSkillList get skillList => $_getN(18);
  @$pb.TagNumber(80)
  set skillList($3.ResSkillList v) { setField(80, v); }
  @$pb.TagNumber(80)
  $core.bool hasSkillList() => $_has(18);
  @$pb.TagNumber(80)
  void clearSkillList() => clearField(80);
  @$pb.TagNumber(80)
  $3.ResSkillList ensureSkillList() => $_ensure(18);

  @$pb.TagNumber(81)
  $4.ResConsumptionList get consumptionList => $_getN(19);
  @$pb.TagNumber(81)
  set consumptionList($4.ResConsumptionList v) { setField(81, v); }
  @$pb.TagNumber(81)
  $core.bool hasConsumptionList() => $_has(19);
  @$pb.TagNumber(81)
  void clearConsumptionList() => clearField(81);
  @$pb.TagNumber(81)
  $4.ResConsumptionList ensureConsumptionList() => $_ensure(19);

  @$pb.TagNumber(82)
  $5.ResSiteList get siteList => $_getN(20);
  @$pb.TagNumber(82)
  set siteList($5.ResSiteList v) { setField(82, v); }
  @$pb.TagNumber(82)
  $core.bool hasSiteList() => $_has(20);
  @$pb.TagNumber(82)
  void clearSiteList() => clearField(82);
  @$pb.TagNumber(82)
  $5.ResSiteList ensureSiteList() => $_ensure(20);

  @$pb.TagNumber(83)
  $6.ResTxList get txList => $_getN(21);
  @$pb.TagNumber(83)
  set txList($6.ResTxList v) { setField(83, v); }
  @$pb.TagNumber(83)
  $core.bool hasTxList() => $_has(21);
  @$pb.TagNumber(83)
  void clearTxList() => clearField(83);
  @$pb.TagNumber(83)
  $6.ResTxList ensureTxList() => $_ensure(21);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
