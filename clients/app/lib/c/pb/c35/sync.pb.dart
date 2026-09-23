// This is a generated file - do not edit.
//
// Generated from c35/sync.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

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

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class SyncCollectionCursor extends $pb.GeneratedMessage {
  factory SyncCollectionCursor({
    $core.String? name,
    $fixnum.Int64? maxUpdatedTsMs,
    $core.bool? caughtUp,
  }) {
    final result = SyncCollectionCursor._();
    if (name != null) result.name = name;
    if (maxUpdatedTsMs != null) result.maxUpdatedTsMs = maxUpdatedTsMs;
    if (caughtUp != null) result.caughtUp = caughtUp;
    return result;
  }

  SyncCollectionCursor._();

  factory SyncCollectionCursor.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SyncCollectionCursor()..mergeFromBuffer(data, registry);
  factory SyncCollectionCursor.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SyncCollectionCursor()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SyncCollectionCursor',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: SyncCollectionCursor.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aInt64(2, _omitFieldNames ? '' : 'maxUpdatedTsMs')
    ..aOB(3, _omitFieldNames ? '' : 'caughtUp')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SyncCollectionCursor clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SyncCollectionCursor copyWith(void Function(SyncCollectionCursor) updates) =>
      super.copyWith((message) => updates(message as SyncCollectionCursor))
          as SyncCollectionCursor;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SyncCollectionCursor() / SyncCollectionCursor.new instead')
  static SyncCollectionCursor create() => SyncCollectionCursor._();
  static $pb.GeneratedMessage $_createMessage() => SyncCollectionCursor._();
  @$core.override
  SyncCollectionCursor createEmptyInstance() => SyncCollectionCursor._();
  @$core.pragma('dart2js:noInline')
  static SyncCollectionCursor getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SyncCollectionCursor>(
          SyncCollectionCursor.$_createMessage);
  static SyncCollectionCursor? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get maxUpdatedTsMs => $_getI64(1);
  @$pb.TagNumber(2)
  set maxUpdatedTsMs($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMaxUpdatedTsMs() => $_has(1);
  @$pb.TagNumber(2)
  void clearMaxUpdatedTsMs() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get caughtUp => $_getBF(2);
  @$pb.TagNumber(3)
  set caughtUp($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCaughtUp() => $_has(2);
  @$pb.TagNumber(3)
  void clearCaughtUp() => $_clearField(3);
}

class ReqSync extends $pb.GeneratedMessage {
  factory ReqSync({
    $fixnum.Int64? sinceMs,
    $core.Iterable<$core.String>? collections,
    $core.int? limitPerCollection,
  }) {
    final result = ReqSync._();
    if (sinceMs != null) result.sinceMs = sinceMs;
    if (collections != null) result.collections.addAll(collections);
    if (limitPerCollection != null)
      result.limitPerCollection = limitPerCollection;
    return result;
  }

  ReqSync._();

  factory ReqSync.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSync()..mergeFromBuffer(data, registry);
  factory ReqSync.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSync()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqSync',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqSync.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'sinceMs')
    ..pPS(2, _omitFieldNames ? '' : 'collections')
    ..aI(3, _omitFieldNames ? '' : 'limitPerCollection')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSync clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSync copyWith(void Function(ReqSync) updates) =>
      super.copyWith((message) => updates(message as ReqSync)) as ReqSync;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqSync() / ReqSync.new instead')
  static ReqSync create() => ReqSync._();
  static $pb.GeneratedMessage $_createMessage() => ReqSync._();
  @$core.override
  ReqSync createEmptyInstance() => ReqSync._();
  @$core.pragma('dart2js:noInline')
  static ReqSync getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqSync>(ReqSync.$_createMessage);
  static ReqSync? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get sinceMs => $_getI64(0);
  @$pb.TagNumber(1)
  set sinceMs($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSinceMs() => $_has(0);
  @$pb.TagNumber(1)
  void clearSinceMs() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get collections => $_getList(1);

  @$pb.TagNumber(3)
  $core.int get limitPerCollection => $_getIZ(2);
  @$pb.TagNumber(3)
  set limitPerCollection($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLimitPerCollection() => $_has(2);
  @$pb.TagNumber(3)
  void clearLimitPerCollection() => $_clearField(3);
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
    $core.Iterable<$5.SiteConfig>? siteConfigs,
    $core.Iterable<$5.SiteDomain>? siteDomains,
    $core.Iterable<$5.SiteProductEmbed>? siteProductEmbeds,
  }) {
    final result = ResSync._();
    if (sinceMs != null) result.sinceMs = sinceMs;
    if (serverTimeMs != null) result.serverTimeMs = serverTimeMs;
    if (cursors != null) result.cursors.addAll(cursors);
    if (chats != null) result.chats.addAll(chats);
    if (chatMembers != null) result.chatMembers.addAll(chatMembers);
    if (chatMsgs != null) result.chatMsgs.addAll(chatMsgs);
    if (billingAccounts != null) result.billingAccounts.addAll(billingAccounts);
    if (logs != null) result.logs.addAll(logs);
    if (skills != null) result.skills.addAll(skills);
    if (consumptions != null) result.consumptions.addAll(consumptions);
    if (consumptionWaters != null)
      result.consumptionWaters.addAll(consumptionWaters);
    if (siteDrafts != null) result.siteDrafts.addAll(siteDrafts);
    if (siteProducts != null) result.siteProducts.addAll(siteProducts);
    if (siteContacts != null) result.siteContacts.addAll(siteContacts);
    if (siteObjects != null) result.siteObjects.addAll(siteObjects);
    if (txs != null) result.txs.addAll(txs);
    if (siteConfigs != null) result.siteConfigs.addAll(siteConfigs);
    if (siteDomains != null) result.siteDomains.addAll(siteDomains);
    if (siteProductEmbeds != null)
      result.siteProductEmbeds.addAll(siteProductEmbeds);
    return result;
  }

  ResSync._();

  factory ResSync.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSync()..mergeFromBuffer(data, registry);
  factory ResSync.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSync()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResSync',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResSync.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'sinceMs')
    ..aInt64(2, _omitFieldNames ? '' : 'serverTimeMs')
    ..pPM<SyncCollectionCursor>(3, _omitFieldNames ? '' : 'cursors',
        subBuilder: SyncCollectionCursor.$_createMessage)
    ..pPM<$0.Chat>(10, _omitFieldNames ? '' : 'chats',
        subBuilder: $0.Chat.$_createMessage)
    ..pPM<$0.ChatMember>(11, _omitFieldNames ? '' : 'chatMembers',
        subBuilder: $0.ChatMember.$_createMessage)
    ..pPM<$0.ChatMsg>(12, _omitFieldNames ? '' : 'chatMsgs',
        subBuilder: $0.ChatMsg.$_createMessage)
    ..pPM<$1.BillingAccount>(13, _omitFieldNames ? '' : 'billingAccounts',
        subBuilder: $1.BillingAccount.$_createMessage)
    ..pPM<$2.Log>(14, _omitFieldNames ? '' : 'logs',
        subBuilder: $2.Log.$_createMessage)
    ..pPM<$3.Skill>(20, _omitFieldNames ? '' : 'skills',
        subBuilder: $3.Skill.$_createMessage)
    ..pPM<$4.Consumption>(21, _omitFieldNames ? '' : 'consumptions',
        subBuilder: $4.Consumption.$_createMessage)
    ..pPM<$4.ConsumptionWater>(22, _omitFieldNames ? '' : 'consumptionWaters',
        subBuilder: $4.ConsumptionWater.$_createMessage)
    ..pPM<$5.SiteDraft>(23, _omitFieldNames ? '' : 'siteDrafts',
        subBuilder: $5.SiteDraft.$_createMessage)
    ..pPM<$5.SiteProduct>(24, _omitFieldNames ? '' : 'siteProducts',
        subBuilder: $5.SiteProduct.$_createMessage)
    ..pPM<$5.SiteContact>(25, _omitFieldNames ? '' : 'siteContacts',
        subBuilder: $5.SiteContact.$_createMessage)
    ..pPM<$5.SiteObject>(26, _omitFieldNames ? '' : 'siteObjects',
        subBuilder: $5.SiteObject.$_createMessage)
    ..pPM<$6.Tx>(27, _omitFieldNames ? '' : 'txs',
        subBuilder: $6.Tx.$_createMessage)
    ..pPM<$5.SiteConfig>(28, _omitFieldNames ? '' : 'siteConfigs',
        subBuilder: $5.SiteConfig.$_createMessage)
    ..pPM<$5.SiteDomain>(29, _omitFieldNames ? '' : 'siteDomains',
        subBuilder: $5.SiteDomain.$_createMessage)
    ..pPM<$5.SiteProductEmbed>(30, _omitFieldNames ? '' : 'siteProductEmbeds',
        subBuilder: $5.SiteProductEmbed.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSync clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSync copyWith(void Function(ResSync) updates) =>
      super.copyWith((message) => updates(message as ResSync)) as ResSync;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResSync() / ResSync.new instead')
  static ResSync create() => ResSync._();
  static $pb.GeneratedMessage $_createMessage() => ResSync._();
  @$core.override
  ResSync createEmptyInstance() => ResSync._();
  @$core.pragma('dart2js:noInline')
  static ResSync getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResSync>(ResSync.$_createMessage);
  static ResSync? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get sinceMs => $_getI64(0);
  @$pb.TagNumber(1)
  set sinceMs($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSinceMs() => $_has(0);
  @$pb.TagNumber(1)
  void clearSinceMs() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get serverTimeMs => $_getI64(1);
  @$pb.TagNumber(2)
  set serverTimeMs($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasServerTimeMs() => $_has(1);
  @$pb.TagNumber(2)
  void clearServerTimeMs() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<SyncCollectionCursor> get cursors => $_getList(2);

  @$pb.TagNumber(10)
  $pb.PbList<$0.Chat> get chats => $_getList(3);

  @$pb.TagNumber(11)
  $pb.PbList<$0.ChatMember> get chatMembers => $_getList(4);

  @$pb.TagNumber(12)
  $pb.PbList<$0.ChatMsg> get chatMsgs => $_getList(5);

  @$pb.TagNumber(13)
  $pb.PbList<$1.BillingAccount> get billingAccounts => $_getList(6);

  @$pb.TagNumber(14)
  $pb.PbList<$2.Log> get logs => $_getList(7);

  @$pb.TagNumber(20)
  $pb.PbList<$3.Skill> get skills => $_getList(8);

  @$pb.TagNumber(21)
  $pb.PbList<$4.Consumption> get consumptions => $_getList(9);

  @$pb.TagNumber(22)
  $pb.PbList<$4.ConsumptionWater> get consumptionWaters => $_getList(10);

  @$pb.TagNumber(23)
  $pb.PbList<$5.SiteDraft> get siteDrafts => $_getList(11);

  @$pb.TagNumber(24)
  $pb.PbList<$5.SiteProduct> get siteProducts => $_getList(12);

  @$pb.TagNumber(25)
  $pb.PbList<$5.SiteContact> get siteContacts => $_getList(13);

  @$pb.TagNumber(26)
  $pb.PbList<$5.SiteObject> get siteObjects => $_getList(14);

  @$pb.TagNumber(27)
  $pb.PbList<$6.Tx> get txs => $_getList(15);

  @$pb.TagNumber(28)
  $pb.PbList<$5.SiteConfig> get siteConfigs => $_getList(16);

  @$pb.TagNumber(29)
  $pb.PbList<$5.SiteDomain> get siteDomains => $_getList(17);

  @$pb.TagNumber(30)
  $pb.PbList<$5.SiteProductEmbed> get siteProductEmbeds => $_getList(18);
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
  siteConfig,
  siteDomain,
  siteProductEmbed,
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
    $5.SiteConfig? siteConfig,
    $5.SiteDomain? siteDomain,
    $5.SiteProductEmbed? siteProductEmbed,
  }) {
    final result = SyncPush._();
    if (chat != null) result.chat = chat;
    if (chatMember != null) result.chatMember = chatMember;
    if (chatMsg != null) result.chatMsg = chatMsg;
    if (billingAccount != null) result.billingAccount = billingAccount;
    if (log != null) result.log = log;
    if (skill != null) result.skill = skill;
    if (consumption != null) result.consumption = consumption;
    if (consumptionWater != null) result.consumptionWater = consumptionWater;
    if (siteDraft != null) result.siteDraft = siteDraft;
    if (siteProduct != null) result.siteProduct = siteProduct;
    if (siteContact != null) result.siteContact = siteContact;
    if (siteObject != null) result.siteObject = siteObject;
    if (tx != null) result.tx = tx;
    if (siteConfig != null) result.siteConfig = siteConfig;
    if (siteDomain != null) result.siteDomain = siteDomain;
    if (siteProductEmbed != null) result.siteProductEmbed = siteProductEmbed;
    return result;
  }

  SyncPush._();

  factory SyncPush.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SyncPush()..mergeFromBuffer(data, registry);
  factory SyncPush.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SyncPush()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, SyncPush_Body> _SyncPush_BodyByTag = {
    1: SyncPush_Body.chat,
    2: SyncPush_Body.chatMember,
    3: SyncPush_Body.chatMsg,
    4: SyncPush_Body.billingAccount,
    5: SyncPush_Body.log,
    6: SyncPush_Body.skill,
    7: SyncPush_Body.consumption,
    8: SyncPush_Body.consumptionWater,
    9: SyncPush_Body.siteDraft,
    10: SyncPush_Body.siteProduct,
    11: SyncPush_Body.siteContact,
    12: SyncPush_Body.siteObject,
    13: SyncPush_Body.tx,
    14: SyncPush_Body.siteConfig,
    15: SyncPush_Body.siteDomain,
    16: SyncPush_Body.siteProductEmbed,
    0: SyncPush_Body.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SyncPush',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: SyncPush.$_createMessage)
    ..oo(0, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16])
    ..aOM<$0.Chat>(1, _omitFieldNames ? '' : 'chat',
        subBuilder: $0.Chat.$_createMessage)
    ..aOM<$0.ChatMember>(2, _omitFieldNames ? '' : 'chatMember',
        subBuilder: $0.ChatMember.$_createMessage)
    ..aOM<$0.ChatMsg>(3, _omitFieldNames ? '' : 'chatMsg',
        subBuilder: $0.ChatMsg.$_createMessage)
    ..aOM<$1.BillingAccount>(4, _omitFieldNames ? '' : 'billingAccount',
        subBuilder: $1.BillingAccount.$_createMessage)
    ..aOM<$2.Log>(5, _omitFieldNames ? '' : 'log',
        subBuilder: $2.Log.$_createMessage)
    ..aOM<$3.Skill>(6, _omitFieldNames ? '' : 'skill',
        subBuilder: $3.Skill.$_createMessage)
    ..aOM<$4.Consumption>(7, _omitFieldNames ? '' : 'consumption',
        subBuilder: $4.Consumption.$_createMessage)
    ..aOM<$4.ConsumptionWater>(8, _omitFieldNames ? '' : 'consumptionWater',
        subBuilder: $4.ConsumptionWater.$_createMessage)
    ..aOM<$5.SiteDraft>(9, _omitFieldNames ? '' : 'siteDraft',
        subBuilder: $5.SiteDraft.$_createMessage)
    ..aOM<$5.SiteProduct>(10, _omitFieldNames ? '' : 'siteProduct',
        subBuilder: $5.SiteProduct.$_createMessage)
    ..aOM<$5.SiteContact>(11, _omitFieldNames ? '' : 'siteContact',
        subBuilder: $5.SiteContact.$_createMessage)
    ..aOM<$5.SiteObject>(12, _omitFieldNames ? '' : 'siteObject',
        subBuilder: $5.SiteObject.$_createMessage)
    ..aOM<$6.Tx>(13, _omitFieldNames ? '' : 'tx',
        subBuilder: $6.Tx.$_createMessage)
    ..aOM<$5.SiteConfig>(14, _omitFieldNames ? '' : 'siteConfig',
        subBuilder: $5.SiteConfig.$_createMessage)
    ..aOM<$5.SiteDomain>(15, _omitFieldNames ? '' : 'siteDomain',
        subBuilder: $5.SiteDomain.$_createMessage)
    ..aOM<$5.SiteProductEmbed>(16, _omitFieldNames ? '' : 'siteProductEmbed',
        subBuilder: $5.SiteProductEmbed.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SyncPush clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SyncPush copyWith(void Function(SyncPush) updates) =>
      super.copyWith((message) => updates(message as SyncPush)) as SyncPush;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SyncPush() / SyncPush.new instead')
  static SyncPush create() => SyncPush._();
  static $pb.GeneratedMessage $_createMessage() => SyncPush._();
  @$core.override
  SyncPush createEmptyInstance() => SyncPush._();
  @$core.pragma('dart2js:noInline')
  static SyncPush getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SyncPush>(SyncPush.$_createMessage);
  static SyncPush? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  @$pb.TagNumber(6)
  @$pb.TagNumber(7)
  @$pb.TagNumber(8)
  @$pb.TagNumber(9)
  @$pb.TagNumber(10)
  @$pb.TagNumber(11)
  @$pb.TagNumber(12)
  @$pb.TagNumber(13)
  @$pb.TagNumber(14)
  @$pb.TagNumber(15)
  @$pb.TagNumber(16)
  SyncPush_Body whichBody() => _SyncPush_BodyByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  @$pb.TagNumber(6)
  @$pb.TagNumber(7)
  @$pb.TagNumber(8)
  @$pb.TagNumber(9)
  @$pb.TagNumber(10)
  @$pb.TagNumber(11)
  @$pb.TagNumber(12)
  @$pb.TagNumber(13)
  @$pb.TagNumber(14)
  @$pb.TagNumber(15)
  @$pb.TagNumber(16)
  void clearBody() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $0.Chat get chat => $_getN(0);
  @$pb.TagNumber(1)
  set chat($0.Chat value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasChat() => $_has(0);
  @$pb.TagNumber(1)
  void clearChat() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.Chat ensureChat() => $_ensure(0);

  @$pb.TagNumber(2)
  $0.ChatMember get chatMember => $_getN(1);
  @$pb.TagNumber(2)
  set chatMember($0.ChatMember value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasChatMember() => $_has(1);
  @$pb.TagNumber(2)
  void clearChatMember() => $_clearField(2);
  @$pb.TagNumber(2)
  $0.ChatMember ensureChatMember() => $_ensure(1);

  @$pb.TagNumber(3)
  $0.ChatMsg get chatMsg => $_getN(2);
  @$pb.TagNumber(3)
  set chatMsg($0.ChatMsg value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasChatMsg() => $_has(2);
  @$pb.TagNumber(3)
  void clearChatMsg() => $_clearField(3);
  @$pb.TagNumber(3)
  $0.ChatMsg ensureChatMsg() => $_ensure(2);

  @$pb.TagNumber(4)
  $1.BillingAccount get billingAccount => $_getN(3);
  @$pb.TagNumber(4)
  set billingAccount($1.BillingAccount value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasBillingAccount() => $_has(3);
  @$pb.TagNumber(4)
  void clearBillingAccount() => $_clearField(4);
  @$pb.TagNumber(4)
  $1.BillingAccount ensureBillingAccount() => $_ensure(3);

  @$pb.TagNumber(5)
  $2.Log get log => $_getN(4);
  @$pb.TagNumber(5)
  set log($2.Log value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasLog() => $_has(4);
  @$pb.TagNumber(5)
  void clearLog() => $_clearField(5);
  @$pb.TagNumber(5)
  $2.Log ensureLog() => $_ensure(4);

  @$pb.TagNumber(6)
  $3.Skill get skill => $_getN(5);
  @$pb.TagNumber(6)
  set skill($3.Skill value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasSkill() => $_has(5);
  @$pb.TagNumber(6)
  void clearSkill() => $_clearField(6);
  @$pb.TagNumber(6)
  $3.Skill ensureSkill() => $_ensure(5);

  @$pb.TagNumber(7)
  $4.Consumption get consumption => $_getN(6);
  @$pb.TagNumber(7)
  set consumption($4.Consumption value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasConsumption() => $_has(6);
  @$pb.TagNumber(7)
  void clearConsumption() => $_clearField(7);
  @$pb.TagNumber(7)
  $4.Consumption ensureConsumption() => $_ensure(6);

  @$pb.TagNumber(8)
  $4.ConsumptionWater get consumptionWater => $_getN(7);
  @$pb.TagNumber(8)
  set consumptionWater($4.ConsumptionWater value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasConsumptionWater() => $_has(7);
  @$pb.TagNumber(8)
  void clearConsumptionWater() => $_clearField(8);
  @$pb.TagNumber(8)
  $4.ConsumptionWater ensureConsumptionWater() => $_ensure(7);

  @$pb.TagNumber(9)
  $5.SiteDraft get siteDraft => $_getN(8);
  @$pb.TagNumber(9)
  set siteDraft($5.SiteDraft value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasSiteDraft() => $_has(8);
  @$pb.TagNumber(9)
  void clearSiteDraft() => $_clearField(9);
  @$pb.TagNumber(9)
  $5.SiteDraft ensureSiteDraft() => $_ensure(8);

  @$pb.TagNumber(10)
  $5.SiteProduct get siteProduct => $_getN(9);
  @$pb.TagNumber(10)
  set siteProduct($5.SiteProduct value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasSiteProduct() => $_has(9);
  @$pb.TagNumber(10)
  void clearSiteProduct() => $_clearField(10);
  @$pb.TagNumber(10)
  $5.SiteProduct ensureSiteProduct() => $_ensure(9);

  @$pb.TagNumber(11)
  $5.SiteContact get siteContact => $_getN(10);
  @$pb.TagNumber(11)
  set siteContact($5.SiteContact value) => $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasSiteContact() => $_has(10);
  @$pb.TagNumber(11)
  void clearSiteContact() => $_clearField(11);
  @$pb.TagNumber(11)
  $5.SiteContact ensureSiteContact() => $_ensure(10);

  @$pb.TagNumber(12)
  $5.SiteObject get siteObject => $_getN(11);
  @$pb.TagNumber(12)
  set siteObject($5.SiteObject value) => $_setField(12, value);
  @$pb.TagNumber(12)
  $core.bool hasSiteObject() => $_has(11);
  @$pb.TagNumber(12)
  void clearSiteObject() => $_clearField(12);
  @$pb.TagNumber(12)
  $5.SiteObject ensureSiteObject() => $_ensure(11);

  @$pb.TagNumber(13)
  $6.Tx get tx => $_getN(12);
  @$pb.TagNumber(13)
  set tx($6.Tx value) => $_setField(13, value);
  @$pb.TagNumber(13)
  $core.bool hasTx() => $_has(12);
  @$pb.TagNumber(13)
  void clearTx() => $_clearField(13);
  @$pb.TagNumber(13)
  $6.Tx ensureTx() => $_ensure(12);

  @$pb.TagNumber(14)
  $5.SiteConfig get siteConfig => $_getN(13);
  @$pb.TagNumber(14)
  set siteConfig($5.SiteConfig value) => $_setField(14, value);
  @$pb.TagNumber(14)
  $core.bool hasSiteConfig() => $_has(13);
  @$pb.TagNumber(14)
  void clearSiteConfig() => $_clearField(14);
  @$pb.TagNumber(14)
  $5.SiteConfig ensureSiteConfig() => $_ensure(13);

  @$pb.TagNumber(15)
  $5.SiteDomain get siteDomain => $_getN(14);
  @$pb.TagNumber(15)
  set siteDomain($5.SiteDomain value) => $_setField(15, value);
  @$pb.TagNumber(15)
  $core.bool hasSiteDomain() => $_has(14);
  @$pb.TagNumber(15)
  void clearSiteDomain() => $_clearField(15);
  @$pb.TagNumber(15)
  $5.SiteDomain ensureSiteDomain() => $_ensure(14);

  @$pb.TagNumber(16)
  $5.SiteProductEmbed get siteProductEmbed => $_getN(15);
  @$pb.TagNumber(16)
  set siteProductEmbed($5.SiteProductEmbed value) => $_setField(16, value);
  @$pb.TagNumber(16)
  $core.bool hasSiteProductEmbed() => $_has(15);
  @$pb.TagNumber(16)
  void clearSiteProductEmbed() => $_clearField(16);
  @$pb.TagNumber(16)
  $5.SiteProductEmbed ensureSiteProductEmbed() => $_ensure(15);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
