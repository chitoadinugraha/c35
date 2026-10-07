// This is a generated file - do not edit.
//
// Generated from c35/live.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class LiveOffer extends $pb.GeneratedMessage {
  factory LiveOffer({
    $core.String? id,
    $core.String? family,
    $core.String? label,
    $core.String? labelKey,
    $core.String? provider,
    $core.bool? enabled,
    $core.double? retailUsdPerMin,
    $core.double? inputUsdPerMin,
    $core.double? outputUsdPerMin,
    $core.double? retailVideoUsdPerMin,
  }) {
    final result = LiveOffer._();
    if (id != null) result.id = id;
    if (family != null) result.family = family;
    if (label != null) result.label = label;
    if (labelKey != null) result.labelKey = labelKey;
    if (provider != null) result.provider = provider;
    if (enabled != null) result.enabled = enabled;
    if (retailUsdPerMin != null) result.retailUsdPerMin = retailUsdPerMin;
    if (inputUsdPerMin != null) result.inputUsdPerMin = inputUsdPerMin;
    if (outputUsdPerMin != null) result.outputUsdPerMin = outputUsdPerMin;
    if (retailVideoUsdPerMin != null)
      result.retailVideoUsdPerMin = retailVideoUsdPerMin;
    return result;
  }

  LiveOffer._();

  factory LiveOffer.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LiveOffer()..mergeFromBuffer(data, registry);
  factory LiveOffer.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LiveOffer()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LiveOffer',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: LiveOffer.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'family')
    ..aOS(3, _omitFieldNames ? '' : 'label')
    ..aOS(4, _omitFieldNames ? '' : 'labelKey')
    ..aOS(5, _omitFieldNames ? '' : 'provider')
    ..aOB(6, _omitFieldNames ? '' : 'enabled')
    ..aD(7, _omitFieldNames ? '' : 'retailUsdPerMin')
    ..aD(8, _omitFieldNames ? '' : 'inputUsdPerMin')
    ..aD(9, _omitFieldNames ? '' : 'outputUsdPerMin')
    ..aD(10, _omitFieldNames ? '' : 'retailVideoUsdPerMin')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LiveOffer clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LiveOffer copyWith(void Function(LiveOffer) updates) =>
      super.copyWith((message) => updates(message as LiveOffer)) as LiveOffer;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use LiveOffer() / LiveOffer.new instead')
  static LiveOffer create() => LiveOffer._();
  static $pb.GeneratedMessage $_createMessage() => LiveOffer._();
  @$core.override
  LiveOffer createEmptyInstance() => LiveOffer._();
  @$core.pragma('dart2js:noInline')
  static LiveOffer getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LiveOffer>(LiveOffer.$_createMessage);
  static LiveOffer? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get family => $_getSZ(1);
  @$pb.TagNumber(2)
  set family($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasFamily() => $_has(1);
  @$pb.TagNumber(2)
  void clearFamily() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get label => $_getSZ(2);
  @$pb.TagNumber(3)
  set label($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLabel() => $_has(2);
  @$pb.TagNumber(3)
  void clearLabel() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get labelKey => $_getSZ(3);
  @$pb.TagNumber(4)
  set labelKey($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasLabelKey() => $_has(3);
  @$pb.TagNumber(4)
  void clearLabelKey() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get provider => $_getSZ(4);
  @$pb.TagNumber(5)
  set provider($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasProvider() => $_has(4);
  @$pb.TagNumber(5)
  void clearProvider() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get enabled => $_getBF(5);
  @$pb.TagNumber(6)
  set enabled($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasEnabled() => $_has(5);
  @$pb.TagNumber(6)
  void clearEnabled() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.double get retailUsdPerMin => $_getN(6);
  @$pb.TagNumber(7)
  set retailUsdPerMin($core.double value) => $_setDouble(6, value);
  @$pb.TagNumber(7)
  $core.bool hasRetailUsdPerMin() => $_has(6);
  @$pb.TagNumber(7)
  void clearRetailUsdPerMin() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.double get inputUsdPerMin => $_getN(7);
  @$pb.TagNumber(8)
  set inputUsdPerMin($core.double value) => $_setDouble(7, value);
  @$pb.TagNumber(8)
  $core.bool hasInputUsdPerMin() => $_has(7);
  @$pb.TagNumber(8)
  void clearInputUsdPerMin() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.double get outputUsdPerMin => $_getN(8);
  @$pb.TagNumber(9)
  set outputUsdPerMin($core.double value) => $_setDouble(8, value);
  @$pb.TagNumber(9)
  $core.bool hasOutputUsdPerMin() => $_has(8);
  @$pb.TagNumber(9)
  void clearOutputUsdPerMin() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.double get retailVideoUsdPerMin => $_getN(9);
  @$pb.TagNumber(10)
  set retailVideoUsdPerMin($core.double value) => $_setDouble(9, value);
  @$pb.TagNumber(10)
  $core.bool hasRetailVideoUsdPerMin() => $_has(9);
  @$pb.TagNumber(10)
  void clearRetailVideoUsdPerMin() => $_clearField(10);
}

class LiveCatalog extends $pb.GeneratedMessage {
  factory LiveCatalog({
    $fixnum.Int64? updatedTsMs,
    $core.Iterable<LiveOffer>? offers,
  }) {
    final result = LiveCatalog._();
    if (updatedTsMs != null) result.updatedTsMs = updatedTsMs;
    if (offers != null) result.offers.addAll(offers);
    return result;
  }

  LiveCatalog._();

  factory LiveCatalog.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LiveCatalog()..mergeFromBuffer(data, registry);
  factory LiveCatalog.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LiveCatalog()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LiveCatalog',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: LiveCatalog.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'updatedTsMs')
    ..pPM<LiveOffer>(2, _omitFieldNames ? '' : 'offers',
        subBuilder: LiveOffer.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LiveCatalog clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LiveCatalog copyWith(void Function(LiveCatalog) updates) =>
      super.copyWith((message) => updates(message as LiveCatalog))
          as LiveCatalog;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use LiveCatalog() / LiveCatalog.new instead')
  static LiveCatalog create() => LiveCatalog._();
  static $pb.GeneratedMessage $_createMessage() => LiveCatalog._();
  @$core.override
  LiveCatalog createEmptyInstance() => LiveCatalog._();
  @$core.pragma('dart2js:noInline')
  static LiveCatalog getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LiveCatalog>(
          LiveCatalog.$_createMessage);
  static LiveCatalog? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get updatedTsMs => $_getI64(0);
  @$pb.TagNumber(1)
  set updatedTsMs($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUpdatedTsMs() => $_has(0);
  @$pb.TagNumber(1)
  void clearUpdatedTsMs() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<LiveOffer> get offers => $_getList(1);
}

class ReqLiveStart extends $pb.GeneratedMessage {
  factory ReqLiveStart({
    $core.String? offerId,
    $core.String? locale,
    $core.String? reqId,
    $fixnum.Int64? chatId,
    $core.Iterable<$core.String>? mentionIds,
  }) {
    final result = ReqLiveStart._();
    if (offerId != null) result.offerId = offerId;
    if (locale != null) result.locale = locale;
    if (reqId != null) result.reqId = reqId;
    if (chatId != null) result.chatId = chatId;
    if (mentionIds != null) result.mentionIds.addAll(mentionIds);
    return result;
  }

  ReqLiveStart._();

  factory ReqLiveStart.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqLiveStart()..mergeFromBuffer(data, registry);
  factory ReqLiveStart.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqLiveStart()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqLiveStart',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqLiveStart.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'offerId')
    ..aOS(2, _omitFieldNames ? '' : 'locale')
    ..aOS(3, _omitFieldNames ? '' : 'reqId')
    ..aInt64(4, _omitFieldNames ? '' : 'chatId')
    ..pPS(5, _omitFieldNames ? '' : 'mentionIds')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqLiveStart clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqLiveStart copyWith(void Function(ReqLiveStart) updates) =>
      super.copyWith((message) => updates(message as ReqLiveStart))
          as ReqLiveStart;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqLiveStart() / ReqLiveStart.new instead')
  static ReqLiveStart create() => ReqLiveStart._();
  static $pb.GeneratedMessage $_createMessage() => ReqLiveStart._();
  @$core.override
  ReqLiveStart createEmptyInstance() => ReqLiveStart._();
  @$core.pragma('dart2js:noInline')
  static ReqLiveStart getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqLiveStart>(
          ReqLiveStart.$_createMessage);
  static ReqLiveStart? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get offerId => $_getSZ(0);
  @$pb.TagNumber(1)
  set offerId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOfferId() => $_has(0);
  @$pb.TagNumber(1)
  void clearOfferId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get locale => $_getSZ(1);
  @$pb.TagNumber(2)
  set locale($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLocale() => $_has(1);
  @$pb.TagNumber(2)
  void clearLocale() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get reqId => $_getSZ(2);
  @$pb.TagNumber(3)
  set reqId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasReqId() => $_has(2);
  @$pb.TagNumber(3)
  void clearReqId() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get chatId => $_getI64(3);
  @$pb.TagNumber(4)
  set chatId($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasChatId() => $_has(3);
  @$pb.TagNumber(4)
  void clearChatId() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbList<$core.String> get mentionIds => $_getList(4);
}

class ResLiveStart extends $pb.GeneratedMessage {
  factory ResLiveStart({
    $core.String? error,
    $core.String? liveSessionId,
    $core.String? wsPath,
  }) {
    final result = ResLiveStart._();
    if (error != null) result.error = error;
    if (liveSessionId != null) result.liveSessionId = liveSessionId;
    if (wsPath != null) result.wsPath = wsPath;
    return result;
  }

  ResLiveStart._();

  factory ResLiveStart.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResLiveStart()..mergeFromBuffer(data, registry);
  factory ResLiveStart.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResLiveStart()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResLiveStart',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResLiveStart.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'error')
    ..aOS(2, _omitFieldNames ? '' : 'liveSessionId')
    ..aOS(3, _omitFieldNames ? '' : 'wsPath')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResLiveStart clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResLiveStart copyWith(void Function(ResLiveStart) updates) =>
      super.copyWith((message) => updates(message as ResLiveStart))
          as ResLiveStart;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResLiveStart() / ResLiveStart.new instead')
  static ResLiveStart create() => ResLiveStart._();
  static $pb.GeneratedMessage $_createMessage() => ResLiveStart._();
  @$core.override
  ResLiveStart createEmptyInstance() => ResLiveStart._();
  @$core.pragma('dart2js:noInline')
  static ResLiveStart getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResLiveStart>(
          ResLiveStart.$_createMessage);
  static ResLiveStart? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get error => $_getSZ(0);
  @$pb.TagNumber(1)
  set error($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasError() => $_has(0);
  @$pb.TagNumber(1)
  void clearError() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get liveSessionId => $_getSZ(1);
  @$pb.TagNumber(2)
  set liveSessionId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLiveSessionId() => $_has(1);
  @$pb.TagNumber(2)
  void clearLiveSessionId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get wsPath => $_getSZ(2);
  @$pb.TagNumber(3)
  set wsPath($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasWsPath() => $_has(2);
  @$pb.TagNumber(3)
  void clearWsPath() => $_clearField(3);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
