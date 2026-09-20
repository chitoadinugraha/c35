//
//  Generated code. Do not modify.
//  source: c35/sync.proto
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
import 'site.pb.dart' as $5;
import 'skill.pb.dart' as $3;
import 'tx.pb.dart' as $6;

class SyncCollectionCursor extends $pb.GeneratedMessage {
  factory SyncCollectionCursor({
    $core.String? name,
    $fixnum.Int64? maxUpdatedTsMs,
    $core.bool? caughtUp,
  }) {
    final $result = create();
    if (name != null) {
      $result.name = name;
    }
    if (maxUpdatedTsMs != null) {
      $result.maxUpdatedTsMs = maxUpdatedTsMs;
    }
    if (caughtUp != null) {
      $result.caughtUp = caughtUp;
    }
    return $result;
  }
  SyncCollectionCursor._() : super();
  factory SyncCollectionCursor.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SyncCollectionCursor.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SyncCollectionCursor', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aInt64(2, _omitFieldNames ? '' : 'maxUpdatedTsMs')
    ..aOB(3, _omitFieldNames ? '' : 'caughtUp')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SyncCollectionCursor clone() => SyncCollectionCursor()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SyncCollectionCursor copyWith(void Function(SyncCollectionCursor) updates) => super.copyWith((message) => updates(message as SyncCollectionCursor)) as SyncCollectionCursor;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SyncCollectionCursor create() => SyncCollectionCursor._();
  SyncCollectionCursor createEmptyInstance() => create();
  static $pb.PbList<SyncCollectionCursor> createRepeated() => $pb.PbList<SyncCollectionCursor>();
  @$core.pragma('dart2js:noInline')
  static SyncCollectionCursor getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SyncCollectionCursor>(create);
  static SyncCollectionCursor? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get maxUpdatedTsMs => $_getI64(1);
  @$pb.TagNumber(2)
  set maxUpdatedTsMs($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasMaxUpdatedTsMs() => $_has(1);
  @$pb.TagNumber(2)
  void clearMaxUpdatedTsMs() => clearField(2);

  @$pb.TagNumber(3)
  $core.bool get caughtUp => $_getBF(2);
  @$pb.TagNumber(3)
  set caughtUp($core.bool v) { $_setBool(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasCaughtUp() => $_has(2);
  @$pb.TagNumber(3)
  void clearCaughtUp() => clearField(3);
}

class ReqSync extends $pb.GeneratedMessage {
  factory ReqSync({
    $fixnum.Int64? sinceMs,
    $core.Iterable<$core.String>? collections,
    $core.int? limitPerCollection,
  }) {
    final $result = create();
    if (sinceMs != null) {
      $result.sinceMs = sinceMs;
    }
    if (collections != null) {
      $result.collections.addAll(collections);
    }
    if (limitPerCollection != null) {
      $result.limitPerCollection = limitPerCollection;
    }
    return $result;
  }
  ReqSync._() : super();
  factory ReqSync.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ReqSync.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ReqSync', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'sinceMs')
    ..pPS(2, _omitFieldNames ? '' : 'collections')
    ..a<$core.int>(3, _omitFieldNames ? '' : 'limitPerCollection', $pb.PbFieldType.O3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ReqSync clone() => ReqSync()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ReqSync copyWith(void Function(ReqSync) updates) => super.copyWith((message) => updates(message as ReqSync)) as ReqSync;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReqSync create() => ReqSync._();
  ReqSync createEmptyInstance() => create();
  static $pb.PbList<ReqSync> createRepeated() => $pb.PbList<ReqSync>();
  @$core.pragma('dart2js:noInline')
  static ReqSync getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqSync>(create);
  static ReqSync? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get sinceMs => $_getI64(0);
  @$pb.TagNumber(1)
  set sinceMs($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasSinceMs() => $_has(0);
  @$pb.TagNumber(1)
  void clearSinceMs() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.String> get collections => $_getList(1);

  @$pb.TagNumber(3)
  $core.int get limitPerCollection => $_getIZ(2);
  @$pb.TagNumber(3)
  set limitPerCollection($core.int v) { $_setSignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasLimitPerCollection() => $_has(2);
  @$pb.TagNumber(3)
  void clearLimitPerCollection() => clearField(3);
}

class ResSync extends $pb.GeneratedMessage {
  factory ResSync({
    $fixnum.Int64? sinceMs,
    $fixnum.Int64? serverTimeMs,
    $core.Iterable<SyncCollectionCursor>? cursors,
    $core.Iterable<$0.Chat>? chats,
    $core.Iterable<$0.ChatMember>? chatMembers,
    $core.Iterable<$0.ChatMsg>? chatMsgs,
    $core.Iterable<$1.BillingAccount>? billingAccounts,
    $core.Iterable<$2.Log>? logs,
    $core.Iterable<$3.Skill>? skills,
    $core.Iterable<$4.Consumption>? consumptions,
    $core.Iterable<$4.ConsumptionWater>? consumptionWaters,
    $core.Iterable<$5.SiteDraft>? siteDrafts,
    $core.Iterable<$5.SiteProduct>? siteProducts,
    $core.Iterable<$5.SiteContact>? siteContacts,
    $core.Iterable<$5.SiteObject>? siteObjects,
    $core.Iterable<$6.Tx>? txs,
  }) {
    final $result = create();
    if (sinceMs != null) {
      $result.sinceMs = sinceMs;
    }
    if (serverTimeMs != null) {
      $result.serverTimeMs = serverTimeMs;
    }
    if (cursors != null) {
      $result.cursors.addAll(cursors);
    }
    if (chats != null) {
      $result.chats.addAll(chats);
    }
    if (chatMembers != null) {
      $result.chatMembers.addAll(chatMembers);
    }
    if (chatMsgs != null) {
      $result.chatMsgs.addAll(chatMsgs);
    }
    if (billingAccounts != null) {
      $result.billingAccounts.addAll(billingAccounts);
    }
    if (logs != null) {
      $result.logs.addAll(logs);
    }
    if (skills != null) {
      $result.skills.addAll(skills);
    }
    if (consumptions != null) {
      $result.consumptions.addAll(consumptions);
    }
    if (consumptionWaters != null) {
      $result.consumptionWaters.addAll(consumptionWaters);
    }
    if (siteDrafts != null) {
      $result.siteDrafts.addAll(siteDrafts);
    }
    if (siteProducts != null) {
      $result.siteProducts.addAll(siteProducts);
    }
    if (siteContacts != null) {
      $result.siteContacts.addAll(siteContacts);
    }
    if (siteObjects != null) {
      $result.siteObjects.addAll(siteObjects);
    }
    if (txs != null) {
      $result.txs.addAll(txs);
    }
    return $result;
  }
  ResSync._() : super();
  factory ResSync.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ResSync.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ResSync', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'sinceMs')
    ..aInt64(2, _omitFieldNames ? '' : 'serverTimeMs')
    ..pc<SyncCollectionCursor>(3, _omitFieldNames ? '' : 'cursors', $pb.PbFieldType.PM, subBuilder: SyncCollectionCursor.create)
    ..pc<$0.Chat>(10, _omitFieldNames ? '' : 'chats', $pb.PbFieldType.PM, subBuilder: $0.Chat.create)
    ..pc<$0.ChatMember>(11, _omitFieldNames ? '' : 'chatMembers', $pb.PbFieldType.PM, subBuilder: $0.ChatMember.create)
    ..pc<$0.ChatMsg>(12, _omitFieldNames ? '' : 'chatMsgs', $pb.PbFieldType.PM, subBuilder: $0.ChatMsg.create)
    ..pc<$1.BillingAccount>(13, _omitFieldNames ? '' : 'billingAccounts', $pb.PbFieldType.PM, subBuilder: $1.BillingAccount.create)
    ..pc<$2.Log>(14, _omitFieldNames ? '' : 'logs', $pb.PbFieldType.PM, subBuilder: $2.Log.create)
    ..pc<$3.Skill>(20, _omitFieldNames ? '' : 'skills', $pb.PbFieldType.PM, subBuilder: $3.Skill.create)
    ..pc<$4.Consumption>(21, _omitFieldNames ? '' : 'consumptions', $pb.PbFieldType.PM, subBuilder: $4.Consumption.create)
    ..pc<$4.ConsumptionWater>(22, _omitFieldNames ? '' : 'consumptionWaters', $pb.PbFieldType.PM, subBuilder: $4.ConsumptionWater.create)
    ..pc<$5.SiteDraft>(23, _omitFieldNames ? '' : 'siteDrafts', $pb.PbFieldType.PM, subBuilder: $5.SiteDraft.create)
    ..pc<$5.SiteProduct>(24, _omitFieldNames ? '' : 'siteProducts', $pb.PbFieldType.PM, subBuilder: $5.SiteProduct.create)
    ..pc<$5.SiteContact>(25, _omitFieldNames ? '' : 'siteContacts', $pb.PbFieldType.PM, subBuilder: $5.SiteContact.create)
    ..pc<$5.SiteObject>(26, _omitFieldNames ? '' : 'siteObjects', $pb.PbFieldType.PM, subBuilder: $5.SiteObject.create)
    ..pc<$6.Tx>(27, _omitFieldNames ? '' : 'txs', $pb.PbFieldType.PM, subBuilder: $6.Tx.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ResSync clone() => ResSync()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ResSync copyWith(void Function(ResSync) updates) => super.copyWith((message) => updates(message as ResSync)) as ResSync;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResSync create() => ResSync._();
  ResSync createEmptyInstance() => create();
  static $pb.PbList<ResSync> createRepeated() => $pb.PbList<ResSync>();
  @$core.pragma('dart2js:noInline')
  static ResSync getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResSync>(create);
  static ResSync? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get sinceMs => $_getI64(0);
  @$pb.TagNumber(1)
  set sinceMs($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasSinceMs() => $_has(0);
  @$pb.TagNumber(1)
  void clearSinceMs() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get serverTimeMs => $_getI64(1);
  @$pb.TagNumber(2)
  set serverTimeMs($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasServerTimeMs() => $_has(1);
  @$pb.TagNumber(2)
  void clearServerTimeMs() => clearField(2);

  @$pb.TagNumber(3)
  $core.List<SyncCollectionCursor> get cursors => $_getList(2);

  @$pb.TagNumber(10)
  $core.List<$0.Chat> get chats => $_getList(3);

  @$pb.TagNumber(11)
  $core.List<$0.ChatMember> get chatMembers => $_getList(4);

  @$pb.TagNumber(12)
  $core.List<$0.ChatMsg> get chatMsgs => $_getList(5);

  @$pb.TagNumber(13)
  $core.List<$1.BillingAccount> get billingAccounts => $_getList(6);

  @$pb.TagNumber(14)
  $core.List<$2.Log> get logs => $_getList(7);

  @$pb.TagNumber(20)
  $core.List<$3.Skill> get skills => $_getList(8);

  @$pb.TagNumber(21)
  $core.List<$4.Consumption> get consumptions => $_getList(9);

  @$pb.TagNumber(22)
  $core.List<$4.ConsumptionWater> get consumptionWaters => $_getList(10);

  @$pb.TagNumber(23)
  $core.List<$5.SiteDraft> get siteDrafts => $_getList(11);

  @$pb.TagNumber(24)
  $core.List<$5.SiteProduct> get siteProducts => $_getList(12);

  @$pb.TagNumber(25)
  $core.List<$5.SiteContact> get siteContacts => $_getList(13);

  @$pb.TagNumber(26)
  $core.List<$5.SiteObject> get siteObjects => $_getList(14);

  @$pb.TagNumber(27)
  $core.List<$6.Tx> get txs => $_getList(15);
}

enum SyncPush_Body {
  chat, 
  chatMember, 
  chatMsg, 
  billingAccount, 
  log, 
  skill, 
  consumption, 
  consumptionWater, 
  siteDraft, 
  siteProduct, 
  siteContact, 
  siteObject, 
  tx, 
  notSet
}

/// Unsolicited server push over WS after NATS / local mutation
class SyncPush extends $pb.GeneratedMessage {
  factory SyncPush({
    $0.Chat? chat,
    $0.ChatMember? chatMember,
    $0.ChatMsg? chatMsg,
    $1.BillingAccount? billingAccount,
    $2.Log? log,
    $3.Skill? skill,
    $4.Consumption? consumption,
    $4.ConsumptionWater? consumptionWater,
    $5.SiteDraft? siteDraft,
    $5.SiteProduct? siteProduct,
    $5.SiteContact? siteContact,
    $5.SiteObject? siteObject,
    $6.Tx? tx,
  }) {
    final $result = create();
    if (chat != null) {
      $result.chat = chat;
    }
    if (chatMember != null) {
      $result.chatMember = chatMember;
    }
    if (chatMsg != null) {
      $result.chatMsg = chatMsg;
    }
    if (billingAccount != null) {
      $result.billingAccount = billingAccount;
    }
    if (log != null) {
      $result.log = log;
    }
    if (skill != null) {
      $result.skill = skill;
    }
    if (consumption != null) {
      $result.consumption = consumption;
    }
    if (consumptionWater != null) {
      $result.consumptionWater = consumptionWater;
    }
    if (siteDraft != null) {
      $result.siteDraft = siteDraft;
    }
    if (siteProduct != null) {
      $result.siteProduct = siteProduct;
    }
    if (siteContact != null) {
      $result.siteContact = siteContact;
    }
    if (siteObject != null) {
      $result.siteObject = siteObject;
    }
    if (tx != null) {
      $result.tx = tx;
    }
    return $result;
  }
  SyncPush._() : super();
  factory SyncPush.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SyncPush.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, SyncPush_Body> _SyncPush_BodyByTag = {
    1 : SyncPush_Body.chat,
    2 : SyncPush_Body.chatMember,
    3 : SyncPush_Body.chatMsg,
    4 : SyncPush_Body.billingAccount,
    5 : SyncPush_Body.log,
    6 : SyncPush_Body.skill,
    7 : SyncPush_Body.consumption,
    8 : SyncPush_Body.consumptionWater,
    9 : SyncPush_Body.siteDraft,
    10 : SyncPush_Body.siteProduct,
    11 : SyncPush_Body.siteContact,
    12 : SyncPush_Body.siteObject,
    13 : SyncPush_Body.tx,
    0 : SyncPush_Body.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SyncPush', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..oo(0, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13])
    ..aOM<$0.Chat>(1, _omitFieldNames ? '' : 'chat', subBuilder: $0.Chat.create)
    ..aOM<$0.ChatMember>(2, _omitFieldNames ? '' : 'chatMember', subBuilder: $0.ChatMember.create)
    ..aOM<$0.ChatMsg>(3, _omitFieldNames ? '' : 'chatMsg', subBuilder: $0.ChatMsg.create)
    ..aOM<$1.BillingAccount>(4, _omitFieldNames ? '' : 'billingAccount', subBuilder: $1.BillingAccount.create)
    ..aOM<$2.Log>(5, _omitFieldNames ? '' : 'log', subBuilder: $2.Log.create)
    ..aOM<$3.Skill>(6, _omitFieldNames ? '' : 'skill', subBuilder: $3.Skill.create)
    ..aOM<$4.Consumption>(7, _omitFieldNames ? '' : 'consumption', subBuilder: $4.Consumption.create)
    ..aOM<$4.ConsumptionWater>(8, _omitFieldNames ? '' : 'consumptionWater', subBuilder: $4.ConsumptionWater.create)
    ..aOM<$5.SiteDraft>(9, _omitFieldNames ? '' : 'siteDraft', subBuilder: $5.SiteDraft.create)
    ..aOM<$5.SiteProduct>(10, _omitFieldNames ? '' : 'siteProduct', subBuilder: $5.SiteProduct.create)
    ..aOM<$5.SiteContact>(11, _omitFieldNames ? '' : 'siteContact', subBuilder: $5.SiteContact.create)
    ..aOM<$5.SiteObject>(12, _omitFieldNames ? '' : 'siteObject', subBuilder: $5.SiteObject.create)
    ..aOM<$6.Tx>(13, _omitFieldNames ? '' : 'tx', subBuilder: $6.Tx.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SyncPush clone() => SyncPush()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SyncPush copyWith(void Function(SyncPush) updates) => super.copyWith((message) => updates(message as SyncPush)) as SyncPush;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SyncPush create() => SyncPush._();
  SyncPush createEmptyInstance() => create();
  static $pb.PbList<SyncPush> createRepeated() => $pb.PbList<SyncPush>();
  @$core.pragma('dart2js:noInline')
  static SyncPush getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SyncPush>(create);
  static SyncPush? _defaultInstance;

  SyncPush_Body whichBody() => _SyncPush_BodyByTag[$_whichOneof(0)]!;
  void clearBody() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $0.Chat get chat => $_getN(0);
  @$pb.TagNumber(1)
  set chat($0.Chat v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasChat() => $_has(0);
  @$pb.TagNumber(1)
  void clearChat() => clearField(1);
  @$pb.TagNumber(1)
  $0.Chat ensureChat() => $_ensure(0);

  @$pb.TagNumber(2)
  $0.ChatMember get chatMember => $_getN(1);
  @$pb.TagNumber(2)
  set chatMember($0.ChatMember v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasChatMember() => $_has(1);
  @$pb.TagNumber(2)
  void clearChatMember() => clearField(2);
  @$pb.TagNumber(2)
  $0.ChatMember ensureChatMember() => $_ensure(1);

  @$pb.TagNumber(3)
  $0.ChatMsg get chatMsg => $_getN(2);
  @$pb.TagNumber(3)
  set chatMsg($0.ChatMsg v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasChatMsg() => $_has(2);
  @$pb.TagNumber(3)
  void clearChatMsg() => clearField(3);
  @$pb.TagNumber(3)
  $0.ChatMsg ensureChatMsg() => $_ensure(2);

  @$pb.TagNumber(4)
  $1.BillingAccount get billingAccount => $_getN(3);
  @$pb.TagNumber(4)
  set billingAccount($1.BillingAccount v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasBillingAccount() => $_has(3);
  @$pb.TagNumber(4)
  void clearBillingAccount() => clearField(4);
  @$pb.TagNumber(4)
  $1.BillingAccount ensureBillingAccount() => $_ensure(3);

  @$pb.TagNumber(5)
  $2.Log get log => $_getN(4);
  @$pb.TagNumber(5)
  set log($2.Log v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasLog() => $_has(4);
  @$pb.TagNumber(5)
  void clearLog() => clearField(5);
  @$pb.TagNumber(5)
  $2.Log ensureLog() => $_ensure(4);

  @$pb.TagNumber(6)
  $3.Skill get skill => $_getN(5);
  @$pb.TagNumber(6)
  set skill($3.Skill v) { setField(6, v); }
  @$pb.TagNumber(6)
  $core.bool hasSkill() => $_has(5);
  @$pb.TagNumber(6)
  void clearSkill() => clearField(6);
  @$pb.TagNumber(6)
  $3.Skill ensureSkill() => $_ensure(5);

  @$pb.TagNumber(7)
  $4.Consumption get consumption => $_getN(6);
  @$pb.TagNumber(7)
  set consumption($4.Consumption v) { setField(7, v); }
  @$pb.TagNumber(7)
  $core.bool hasConsumption() => $_has(6);
  @$pb.TagNumber(7)
  void clearConsumption() => clearField(7);
  @$pb.TagNumber(7)
  $4.Consumption ensureConsumption() => $_ensure(6);

  @$pb.TagNumber(8)
  $4.ConsumptionWater get consumptionWater => $_getN(7);
  @$pb.TagNumber(8)
  set consumptionWater($4.ConsumptionWater v) { setField(8, v); }
  @$pb.TagNumber(8)
  $core.bool hasConsumptionWater() => $_has(7);
  @$pb.TagNumber(8)
  void clearConsumptionWater() => clearField(8);
  @$pb.TagNumber(8)
  $4.ConsumptionWater ensureConsumptionWater() => $_ensure(7);

  @$pb.TagNumber(9)
  $5.SiteDraft get siteDraft => $_getN(8);
  @$pb.TagNumber(9)
  set siteDraft($5.SiteDraft v) { setField(9, v); }
  @$pb.TagNumber(9)
  $core.bool hasSiteDraft() => $_has(8);
  @$pb.TagNumber(9)
  void clearSiteDraft() => clearField(9);
  @$pb.TagNumber(9)
  $5.SiteDraft ensureSiteDraft() => $_ensure(8);

  @$pb.TagNumber(10)
  $5.SiteProduct get siteProduct => $_getN(9);
  @$pb.TagNumber(10)
  set siteProduct($5.SiteProduct v) { setField(10, v); }
  @$pb.TagNumber(10)
  $core.bool hasSiteProduct() => $_has(9);
  @$pb.TagNumber(10)
  void clearSiteProduct() => clearField(10);
  @$pb.TagNumber(10)
  $5.SiteProduct ensureSiteProduct() => $_ensure(9);

  @$pb.TagNumber(11)
  $5.SiteContact get siteContact => $_getN(10);
  @$pb.TagNumber(11)
  set siteContact($5.SiteContact v) { setField(11, v); }
  @$pb.TagNumber(11)
  $core.bool hasSiteContact() => $_has(10);
  @$pb.TagNumber(11)
  void clearSiteContact() => clearField(11);
  @$pb.TagNumber(11)
  $5.SiteContact ensureSiteContact() => $_ensure(10);

  @$pb.TagNumber(12)
  $5.SiteObject get siteObject => $_getN(11);
  @$pb.TagNumber(12)
  set siteObject($5.SiteObject v) { setField(12, v); }
  @$pb.TagNumber(12)
  $core.bool hasSiteObject() => $_has(11);
  @$pb.TagNumber(12)
  void clearSiteObject() => clearField(12);
  @$pb.TagNumber(12)
  $5.SiteObject ensureSiteObject() => $_ensure(11);

  @$pb.TagNumber(13)
  $6.Tx get tx => $_getN(12);
  @$pb.TagNumber(13)
  set tx($6.Tx v) { setField(13, v); }
  @$pb.TagNumber(13)
  $core.bool hasTx() => $_has(12);
  @$pb.TagNumber(13)
  void clearTx() => clearField(13);
  @$pb.TagNumber(13)
  $6.Tx ensureTx() => $_ensure(12);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
