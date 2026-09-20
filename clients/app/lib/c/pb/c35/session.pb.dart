//
//  Generated code. Do not modify.
//  source: c35/session.proto
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
import 'identity.pb.dart' as $7;
import 'sync.pb.dart' as $8;

class ReqSessionInit extends $pb.GeneratedMessage {
  factory ReqSessionInit({
    $fixnum.Int64? sinceMs,
    $core.String? locale,
    $core.String? tz,
    $core.String? dv,
    $core.String? clientId,
    $core.int? platform,
    $core.bool? includeInbox,
    $core.bool? includeBilling,
  }) {
    final $result = create();
    if (sinceMs != null) {
      $result.sinceMs = sinceMs;
    }
    if (locale != null) {
      $result.locale = locale;
    }
    if (tz != null) {
      $result.tz = tz;
    }
    if (dv != null) {
      $result.dv = dv;
    }
    if (clientId != null) {
      $result.clientId = clientId;
    }
    if (platform != null) {
      $result.platform = platform;
    }
    if (includeInbox != null) {
      $result.includeInbox = includeInbox;
    }
    if (includeBilling != null) {
      $result.includeBilling = includeBilling;
    }
    return $result;
  }
  ReqSessionInit._() : super();
  factory ReqSessionInit.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ReqSessionInit.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ReqSessionInit', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'sinceMs')
    ..aOS(2, _omitFieldNames ? '' : 'locale')
    ..aOS(3, _omitFieldNames ? '' : 'tz')
    ..aOS(4, _omitFieldNames ? '' : 'dv')
    ..aOS(5, _omitFieldNames ? '' : 'clientId')
    ..a<$core.int>(6, _omitFieldNames ? '' : 'platform', $pb.PbFieldType.O3)
    ..aOB(7, _omitFieldNames ? '' : 'includeInbox')
    ..aOB(8, _omitFieldNames ? '' : 'includeBilling')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ReqSessionInit clone() => ReqSessionInit()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ReqSessionInit copyWith(void Function(ReqSessionInit) updates) => super.copyWith((message) => updates(message as ReqSessionInit)) as ReqSessionInit;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReqSessionInit create() => ReqSessionInit._();
  ReqSessionInit createEmptyInstance() => create();
  static $pb.PbList<ReqSessionInit> createRepeated() => $pb.PbList<ReqSessionInit>();
  @$core.pragma('dart2js:noInline')
  static ReqSessionInit getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqSessionInit>(create);
  static ReqSessionInit? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get sinceMs => $_getI64(0);
  @$pb.TagNumber(1)
  set sinceMs($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasSinceMs() => $_has(0);
  @$pb.TagNumber(1)
  void clearSinceMs() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get locale => $_getSZ(1);
  @$pb.TagNumber(2)
  set locale($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasLocale() => $_has(1);
  @$pb.TagNumber(2)
  void clearLocale() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get tz => $_getSZ(2);
  @$pb.TagNumber(3)
  set tz($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasTz() => $_has(2);
  @$pb.TagNumber(3)
  void clearTz() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get dv => $_getSZ(3);
  @$pb.TagNumber(4)
  set dv($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasDv() => $_has(3);
  @$pb.TagNumber(4)
  void clearDv() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get clientId => $_getSZ(4);
  @$pb.TagNumber(5)
  set clientId($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasClientId() => $_has(4);
  @$pb.TagNumber(5)
  void clearClientId() => clearField(5);

  @$pb.TagNumber(6)
  $core.int get platform => $_getIZ(5);
  @$pb.TagNumber(6)
  set platform($core.int v) { $_setSignedInt32(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasPlatform() => $_has(5);
  @$pb.TagNumber(6)
  void clearPlatform() => clearField(6);

  @$pb.TagNumber(7)
  $core.bool get includeInbox => $_getBF(6);
  @$pb.TagNumber(7)
  set includeInbox($core.bool v) { $_setBool(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasIncludeInbox() => $_has(6);
  @$pb.TagNumber(7)
  void clearIncludeInbox() => clearField(7);

  @$pb.TagNumber(8)
  $core.bool get includeBilling => $_getBF(7);
  @$pb.TagNumber(8)
  set includeBilling($core.bool v) { $_setBool(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasIncludeBilling() => $_has(7);
  @$pb.TagNumber(8)
  void clearIncludeBilling() => clearField(8);
}

class ResSessionInit extends $pb.GeneratedMessage {
  factory ResSessionInit({
    $fixnum.Int64? serverTimeMs,
    $fixnum.Int64? sinceMs,
    $core.String? sessionId,
    $7.IdentityProfile? profile,
    $1.BillingAccount? billing,
    $7.NavCounts? nav,
    $core.String? settingsJson,
    $core.Iterable<$0.Chat>? inboxChats,
    $core.Iterable<$0.ChatMember>? inboxMembers,
    $8.ResSync? sync,
  }) {
    final $result = create();
    if (serverTimeMs != null) {
      $result.serverTimeMs = serverTimeMs;
    }
    if (sinceMs != null) {
      $result.sinceMs = sinceMs;
    }
    if (sessionId != null) {
      $result.sessionId = sessionId;
    }
    if (profile != null) {
      $result.profile = profile;
    }
    if (billing != null) {
      $result.billing = billing;
    }
    if (nav != null) {
      $result.nav = nav;
    }
    if (settingsJson != null) {
      $result.settingsJson = settingsJson;
    }
    if (inboxChats != null) {
      $result.inboxChats.addAll(inboxChats);
    }
    if (inboxMembers != null) {
      $result.inboxMembers.addAll(inboxMembers);
    }
    if (sync != null) {
      $result.sync = sync;
    }
    return $result;
  }
  ResSessionInit._() : super();
  factory ResSessionInit.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ResSessionInit.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ResSessionInit', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'serverTimeMs')
    ..aInt64(2, _omitFieldNames ? '' : 'sinceMs')
    ..aOS(3, _omitFieldNames ? '' : 'sessionId')
    ..aOM<$7.IdentityProfile>(4, _omitFieldNames ? '' : 'profile', subBuilder: $7.IdentityProfile.create)
    ..aOM<$1.BillingAccount>(5, _omitFieldNames ? '' : 'billing', subBuilder: $1.BillingAccount.create)
    ..aOM<$7.NavCounts>(6, _omitFieldNames ? '' : 'nav', subBuilder: $7.NavCounts.create)
    ..aOS(7, _omitFieldNames ? '' : 'settingsJson')
    ..pc<$0.Chat>(8, _omitFieldNames ? '' : 'inboxChats', $pb.PbFieldType.PM, subBuilder: $0.Chat.create)
    ..pc<$0.ChatMember>(9, _omitFieldNames ? '' : 'inboxMembers', $pb.PbFieldType.PM, subBuilder: $0.ChatMember.create)
    ..aOM<$8.ResSync>(10, _omitFieldNames ? '' : 'sync', subBuilder: $8.ResSync.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ResSessionInit clone() => ResSessionInit()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ResSessionInit copyWith(void Function(ResSessionInit) updates) => super.copyWith((message) => updates(message as ResSessionInit)) as ResSessionInit;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResSessionInit create() => ResSessionInit._();
  ResSessionInit createEmptyInstance() => create();
  static $pb.PbList<ResSessionInit> createRepeated() => $pb.PbList<ResSessionInit>();
  @$core.pragma('dart2js:noInline')
  static ResSessionInit getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResSessionInit>(create);
  static ResSessionInit? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get serverTimeMs => $_getI64(0);
  @$pb.TagNumber(1)
  set serverTimeMs($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasServerTimeMs() => $_has(0);
  @$pb.TagNumber(1)
  void clearServerTimeMs() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get sinceMs => $_getI64(1);
  @$pb.TagNumber(2)
  set sinceMs($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasSinceMs() => $_has(1);
  @$pb.TagNumber(2)
  void clearSinceMs() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get sessionId => $_getSZ(2);
  @$pb.TagNumber(3)
  set sessionId($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasSessionId() => $_has(2);
  @$pb.TagNumber(3)
  void clearSessionId() => clearField(3);

  @$pb.TagNumber(4)
  $7.IdentityProfile get profile => $_getN(3);
  @$pb.TagNumber(4)
  set profile($7.IdentityProfile v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasProfile() => $_has(3);
  @$pb.TagNumber(4)
  void clearProfile() => clearField(4);
  @$pb.TagNumber(4)
  $7.IdentityProfile ensureProfile() => $_ensure(3);

  @$pb.TagNumber(5)
  $1.BillingAccount get billing => $_getN(4);
  @$pb.TagNumber(5)
  set billing($1.BillingAccount v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasBilling() => $_has(4);
  @$pb.TagNumber(5)
  void clearBilling() => clearField(5);
  @$pb.TagNumber(5)
  $1.BillingAccount ensureBilling() => $_ensure(4);

  @$pb.TagNumber(6)
  $7.NavCounts get nav => $_getN(5);
  @$pb.TagNumber(6)
  set nav($7.NavCounts v) { setField(6, v); }
  @$pb.TagNumber(6)
  $core.bool hasNav() => $_has(5);
  @$pb.TagNumber(6)
  void clearNav() => clearField(6);
  @$pb.TagNumber(6)
  $7.NavCounts ensureNav() => $_ensure(5);

  /// Settings blob (locale, theme, …) — same shape as cs_agent settings page
  @$pb.TagNumber(7)
  $core.String get settingsJson => $_getSZ(6);
  @$pb.TagNumber(7)
  set settingsJson($core.String v) { $_setString(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasSettingsJson() => $_has(6);
  @$pb.TagNumber(7)
  void clearSettingsJson() => clearField(7);

  /// Prompt inbox slice (not bot_peer, not direct)
  @$pb.TagNumber(8)
  $core.List<$0.Chat> get inboxChats => $_getList(7);

  @$pb.TagNumber(9)
  $core.List<$0.ChatMember> get inboxMembers => $_getList(8);

  /// Optional broader delta when since_ms > 0
  @$pb.TagNumber(10)
  $8.ResSync get sync => $_getN(9);
  @$pb.TagNumber(10)
  set sync($8.ResSync v) { setField(10, v); }
  @$pb.TagNumber(10)
  $core.bool hasSync() => $_has(9);
  @$pb.TagNumber(10)
  void clearSync() => clearField(10);
  @$pb.TagNumber(10)
  $8.ResSync ensureSync() => $_ensure(9);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
