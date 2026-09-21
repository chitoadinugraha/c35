// This is a generated file - do not edit.
//
// Generated from c35/session.proto.

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
import 'chat.pb.dart' as $2;
import 'identity.pb.dart' as $0;
import 'sync.pb.dart' as $3;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class PromptModelOption extends $pb.GeneratedMessage {
  factory PromptModelOption({
    $core.String? id,
    $core.String? label,
    $core.String? provider,
    $core.bool? isDefault,
    $core.double? usdInPer1m,
    $core.double? usdOutPer1m,
    $core.bool? supportsThinking,
  }) {
    final result = PromptModelOption._();
    if (id != null) result.id = id;
    if (label != null) result.label = label;
    if (provider != null) result.provider = provider;
    if (isDefault != null) result.isDefault = isDefault;
    if (usdInPer1m != null) result.usdInPer1m = usdInPer1m;
    if (usdOutPer1m != null) result.usdOutPer1m = usdOutPer1m;
    if (supportsThinking != null) result.supportsThinking = supportsThinking;
    return result;
  }

  PromptModelOption._();

  factory PromptModelOption.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PromptModelOption()..mergeFromBuffer(data, registry);
  factory PromptModelOption.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PromptModelOption()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PromptModelOption',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: PromptModelOption.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'label')
    ..aOS(3, _omitFieldNames ? '' : 'provider')
    ..aOB(4, _omitFieldNames ? '' : 'isDefault')
    ..aD(5, _omitFieldNames ? '' : 'usdInPer1m', protoName: 'usd_in_per_1m')
    ..aD(6, _omitFieldNames ? '' : 'usdOutPer1m', protoName: 'usd_out_per_1m')
    ..aOB(7, _omitFieldNames ? '' : 'supportsThinking')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PromptModelOption clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PromptModelOption copyWith(void Function(PromptModelOption) updates) =>
      super.copyWith((message) => updates(message as PromptModelOption))
          as PromptModelOption;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PromptModelOption() / PromptModelOption.new instead')
  static PromptModelOption create() => PromptModelOption._();
  static $pb.GeneratedMessage $_createMessage() => PromptModelOption._();
  @$core.override
  PromptModelOption createEmptyInstance() => PromptModelOption._();
  @$core.pragma('dart2js:noInline')
  static PromptModelOption getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PromptModelOption>(
          PromptModelOption.$_createMessage);
  static PromptModelOption? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get label => $_getSZ(1);
  @$pb.TagNumber(2)
  set label($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLabel() => $_has(1);
  @$pb.TagNumber(2)
  void clearLabel() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get provider => $_getSZ(2);
  @$pb.TagNumber(3)
  set provider($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasProvider() => $_has(2);
  @$pb.TagNumber(3)
  void clearProvider() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get isDefault => $_getBF(3);
  @$pb.TagNumber(4)
  set isDefault($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasIsDefault() => $_has(3);
  @$pb.TagNumber(4)
  void clearIsDefault() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.double get usdInPer1m => $_getN(4);
  @$pb.TagNumber(5)
  set usdInPer1m($core.double value) => $_setDouble(4, value);
  @$pb.TagNumber(5)
  $core.bool hasUsdInPer1m() => $_has(4);
  @$pb.TagNumber(5)
  void clearUsdInPer1m() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.double get usdOutPer1m => $_getN(5);
  @$pb.TagNumber(6)
  set usdOutPer1m($core.double value) => $_setDouble(5, value);
  @$pb.TagNumber(6)
  $core.bool hasUsdOutPer1m() => $_has(5);
  @$pb.TagNumber(6)
  void clearUsdOutPer1m() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.bool get supportsThinking => $_getBF(6);
  @$pb.TagNumber(7)
  set supportsThinking($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasSupportsThinking() => $_has(6);
  @$pb.TagNumber(7)
  void clearSupportsThinking() => $_clearField(7);
}

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
    final result = ReqSessionInit._();
    if (sinceMs != null) result.sinceMs = sinceMs;
    if (locale != null) result.locale = locale;
    if (tz != null) result.tz = tz;
    if (dv != null) result.dv = dv;
    if (clientId != null) result.clientId = clientId;
    if (platform != null) result.platform = platform;
    if (includeInbox != null) result.includeInbox = includeInbox;
    if (includeBilling != null) result.includeBilling = includeBilling;
    return result;
  }

  ReqSessionInit._();

  factory ReqSessionInit.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSessionInit()..mergeFromBuffer(data, registry);
  factory ReqSessionInit.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSessionInit()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqSessionInit',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqSessionInit.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'sinceMs')
    ..aOS(2, _omitFieldNames ? '' : 'locale')
    ..aOS(3, _omitFieldNames ? '' : 'tz')
    ..aOS(4, _omitFieldNames ? '' : 'dv')
    ..aOS(5, _omitFieldNames ? '' : 'clientId')
    ..aI(6, _omitFieldNames ? '' : 'platform')
    ..aOB(7, _omitFieldNames ? '' : 'includeInbox')
    ..aOB(8, _omitFieldNames ? '' : 'includeBilling')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSessionInit clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSessionInit copyWith(void Function(ReqSessionInit) updates) =>
      super.copyWith((message) => updates(message as ReqSessionInit))
          as ReqSessionInit;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqSessionInit() / ReqSessionInit.new instead')
  static ReqSessionInit create() => ReqSessionInit._();
  static $pb.GeneratedMessage $_createMessage() => ReqSessionInit._();
  @$core.override
  ReqSessionInit createEmptyInstance() => ReqSessionInit._();
  @$core.pragma('dart2js:noInline')
  static ReqSessionInit getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqSessionInit>(
          ReqSessionInit.$_createMessage);
  static ReqSessionInit? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get sinceMs => $_getI64(0);
  @$pb.TagNumber(1)
  set sinceMs($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSinceMs() => $_has(0);
  @$pb.TagNumber(1)
  void clearSinceMs() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get locale => $_getSZ(1);
  @$pb.TagNumber(2)
  set locale($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLocale() => $_has(1);
  @$pb.TagNumber(2)
  void clearLocale() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get tz => $_getSZ(2);
  @$pb.TagNumber(3)
  set tz($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTz() => $_has(2);
  @$pb.TagNumber(3)
  void clearTz() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get dv => $_getSZ(3);
  @$pb.TagNumber(4)
  set dv($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDv() => $_has(3);
  @$pb.TagNumber(4)
  void clearDv() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get clientId => $_getSZ(4);
  @$pb.TagNumber(5)
  set clientId($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasClientId() => $_has(4);
  @$pb.TagNumber(5)
  void clearClientId() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get platform => $_getIZ(5);
  @$pb.TagNumber(6)
  set platform($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasPlatform() => $_has(5);
  @$pb.TagNumber(6)
  void clearPlatform() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.bool get includeInbox => $_getBF(6);
  @$pb.TagNumber(7)
  set includeInbox($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasIncludeInbox() => $_has(6);
  @$pb.TagNumber(7)
  void clearIncludeInbox() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.bool get includeBilling => $_getBF(7);
  @$pb.TagNumber(8)
  set includeBilling($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasIncludeBilling() => $_has(7);
  @$pb.TagNumber(8)
  void clearIncludeBilling() => $_clearField(8);
}

class ResSessionInit extends $pb.GeneratedMessage {
  factory ResSessionInit({
    $fixnum.Int64? serverTimeMs,
    $fixnum.Int64? sinceMs,
    $core.String? sessionId,
    $0.IdentityProfile? profile,
    $1.BillingAccount? billing,
    $0.NavCounts? nav,
    $core.String? settingsJson,
    $core.Iterable<$2.Chat>? inboxChats,
    $core.Iterable<$2.ChatMember>? inboxMembers,
    $3.ResSync? sync,
    $core.Iterable<PromptModelOption>? models,
  }) {
    final result = ResSessionInit._();
    if (serverTimeMs != null) result.serverTimeMs = serverTimeMs;
    if (sinceMs != null) result.sinceMs = sinceMs;
    if (sessionId != null) result.sessionId = sessionId;
    if (profile != null) result.profile = profile;
    if (billing != null) result.billing = billing;
    if (nav != null) result.nav = nav;
    if (settingsJson != null) result.settingsJson = settingsJson;
    if (inboxChats != null) result.inboxChats.addAll(inboxChats);
    if (inboxMembers != null) result.inboxMembers.addAll(inboxMembers);
    if (sync != null) result.sync = sync;
    if (models != null) result.models.addAll(models);
    return result;
  }

  ResSessionInit._();

  factory ResSessionInit.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSessionInit()..mergeFromBuffer(data, registry);
  factory ResSessionInit.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSessionInit()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResSessionInit',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResSessionInit.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'serverTimeMs')
    ..aInt64(2, _omitFieldNames ? '' : 'sinceMs')
    ..aOS(3, _omitFieldNames ? '' : 'sessionId')
    ..aOM<$0.IdentityProfile>(4, _omitFieldNames ? '' : 'profile',
        subBuilder: $0.IdentityProfile.$_createMessage)
    ..aOM<$1.BillingAccount>(5, _omitFieldNames ? '' : 'billing',
        subBuilder: $1.BillingAccount.$_createMessage)
    ..aOM<$0.NavCounts>(6, _omitFieldNames ? '' : 'nav',
        subBuilder: $0.NavCounts.$_createMessage)
    ..aOS(7, _omitFieldNames ? '' : 'settingsJson')
    ..pPM<$2.Chat>(8, _omitFieldNames ? '' : 'inboxChats',
        subBuilder: $2.Chat.$_createMessage)
    ..pPM<$2.ChatMember>(9, _omitFieldNames ? '' : 'inboxMembers',
        subBuilder: $2.ChatMember.$_createMessage)
    ..aOM<$3.ResSync>(10, _omitFieldNames ? '' : 'sync',
        subBuilder: $3.ResSync.$_createMessage)
    ..pPM<PromptModelOption>(11, _omitFieldNames ? '' : 'models',
        subBuilder: PromptModelOption.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSessionInit clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSessionInit copyWith(void Function(ResSessionInit) updates) =>
      super.copyWith((message) => updates(message as ResSessionInit))
          as ResSessionInit;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResSessionInit() / ResSessionInit.new instead')
  static ResSessionInit create() => ResSessionInit._();
  static $pb.GeneratedMessage $_createMessage() => ResSessionInit._();
  @$core.override
  ResSessionInit createEmptyInstance() => ResSessionInit._();
  @$core.pragma('dart2js:noInline')
  static ResSessionInit getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResSessionInit>(
          ResSessionInit.$_createMessage);
  static ResSessionInit? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get serverTimeMs => $_getI64(0);
  @$pb.TagNumber(1)
  set serverTimeMs($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasServerTimeMs() => $_has(0);
  @$pb.TagNumber(1)
  void clearServerTimeMs() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get sinceMs => $_getI64(1);
  @$pb.TagNumber(2)
  set sinceMs($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSinceMs() => $_has(1);
  @$pb.TagNumber(2)
  void clearSinceMs() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get sessionId => $_getSZ(2);
  @$pb.TagNumber(3)
  set sessionId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSessionId() => $_has(2);
  @$pb.TagNumber(3)
  void clearSessionId() => $_clearField(3);

  @$pb.TagNumber(4)
  $0.IdentityProfile get profile => $_getN(3);
  @$pb.TagNumber(4)
  set profile($0.IdentityProfile value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasProfile() => $_has(3);
  @$pb.TagNumber(4)
  void clearProfile() => $_clearField(4);
  @$pb.TagNumber(4)
  $0.IdentityProfile ensureProfile() => $_ensure(3);

  @$pb.TagNumber(5)
  $1.BillingAccount get billing => $_getN(4);
  @$pb.TagNumber(5)
  set billing($1.BillingAccount value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasBilling() => $_has(4);
  @$pb.TagNumber(5)
  void clearBilling() => $_clearField(5);
  @$pb.TagNumber(5)
  $1.BillingAccount ensureBilling() => $_ensure(4);

  @$pb.TagNumber(6)
  $0.NavCounts get nav => $_getN(5);
  @$pb.TagNumber(6)
  set nav($0.NavCounts value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasNav() => $_has(5);
  @$pb.TagNumber(6)
  void clearNav() => $_clearField(6);
  @$pb.TagNumber(6)
  $0.NavCounts ensureNav() => $_ensure(5);

  /// Settings blob (locale, theme, …) — same shape as cs_agent settings page
  @$pb.TagNumber(7)
  $core.String get settingsJson => $_getSZ(6);
  @$pb.TagNumber(7)
  set settingsJson($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasSettingsJson() => $_has(6);
  @$pb.TagNumber(7)
  void clearSettingsJson() => $_clearField(7);

  /// Prompt inbox slice (not bot_peer, not direct)
  @$pb.TagNumber(8)
  $pb.PbList<$2.Chat> get inboxChats => $_getList(7);

  @$pb.TagNumber(9)
  $pb.PbList<$2.ChatMember> get inboxMembers => $_getList(8);

  /// Optional broader delta when since_ms > 0
  @$pb.TagNumber(10)
  $3.ResSync get sync => $_getN(9);
  @$pb.TagNumber(10)
  set sync($3.ResSync value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasSync() => $_has(9);
  @$pb.TagNumber(10)
  void clearSync() => $_clearField(10);
  @$pb.TagNumber(10)
  $3.ResSync ensureSync() => $_ensure(9);

  /// LLM picker (from ai.llm_model)
  @$pb.TagNumber(11)
  $pb.PbList<PromptModelOption> get models => $_getList(10);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
