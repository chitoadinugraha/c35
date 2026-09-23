// This is a generated file - do not edit.
//
// Generated from c35/fetch.proto.

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

/// Published by c35-fetcher on c35.fetch.fx after billing_fx_rate insert.
class FetchFxPush extends $pb.GeneratedMessage {
  factory FetchFxPush({
    $fixnum.Int64? fxRateId,
    $fixnum.Int64? microPerUsd,
    $core.double? rawIdrPerUsd,
    $core.double? publishedIdrPerUsd,
    $fixnum.Int64? effectiveTsMs,
  }) {
    final result = FetchFxPush._();
    if (fxRateId != null) result.fxRateId = fxRateId;
    if (microPerUsd != null) result.microPerUsd = microPerUsd;
    if (rawIdrPerUsd != null) result.rawIdrPerUsd = rawIdrPerUsd;
    if (publishedIdrPerUsd != null)
      result.publishedIdrPerUsd = publishedIdrPerUsd;
    if (effectiveTsMs != null) result.effectiveTsMs = effectiveTsMs;
    return result;
  }

  FetchFxPush._();

  factory FetchFxPush.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      FetchFxPush()..mergeFromBuffer(data, registry);
  factory FetchFxPush.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      FetchFxPush()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FetchFxPush',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: FetchFxPush.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'fxRateId')
    ..aInt64(2, _omitFieldNames ? '' : 'microPerUsd')
    ..aD(3, _omitFieldNames ? '' : 'rawIdrPerUsd')
    ..aD(4, _omitFieldNames ? '' : 'publishedIdrPerUsd')
    ..aInt64(5, _omitFieldNames ? '' : 'effectiveTsMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FetchFxPush clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FetchFxPush copyWith(void Function(FetchFxPush) updates) =>
      super.copyWith((message) => updates(message as FetchFxPush))
          as FetchFxPush;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use FetchFxPush() / FetchFxPush.new instead')
  static FetchFxPush create() => FetchFxPush._();
  static $pb.GeneratedMessage $_createMessage() => FetchFxPush._();
  @$core.override
  FetchFxPush createEmptyInstance() => FetchFxPush._();
  @$core.pragma('dart2js:noInline')
  static FetchFxPush getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FetchFxPush>(
          FetchFxPush.$_createMessage);
  static FetchFxPush? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get fxRateId => $_getI64(0);
  @$pb.TagNumber(1)
  set fxRateId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasFxRateId() => $_has(0);
  @$pb.TagNumber(1)
  void clearFxRateId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get microPerUsd => $_getI64(1);
  @$pb.TagNumber(2)
  set microPerUsd($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMicroPerUsd() => $_has(1);
  @$pb.TagNumber(2)
  void clearMicroPerUsd() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get rawIdrPerUsd => $_getN(2);
  @$pb.TagNumber(3)
  set rawIdrPerUsd($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasRawIdrPerUsd() => $_has(2);
  @$pb.TagNumber(3)
  void clearRawIdrPerUsd() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get publishedIdrPerUsd => $_getN(3);
  @$pb.TagNumber(4)
  set publishedIdrPerUsd($core.double value) => $_setDouble(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPublishedIdrPerUsd() => $_has(3);
  @$pb.TagNumber(4)
  void clearPublishedIdrPerUsd() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get effectiveTsMs => $_getI64(4);
  @$pb.TagNumber(5)
  set effectiveTsMs($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasEffectiveTsMs() => $_has(4);
  @$pb.TagNumber(5)
  void clearEffectiveTsMs() => $_clearField(5);
}

/// Published by c35-fetcher on c35.fetch.llm_catalog after llm_catalog_sync.
class FetchLlmCatalogPush extends $pb.GeneratedMessage {
  factory FetchLlmCatalogPush({
    $fixnum.Int64? syncTsMs,
    $core.int? modelCount,
  }) {
    final result = FetchLlmCatalogPush._();
    if (syncTsMs != null) result.syncTsMs = syncTsMs;
    if (modelCount != null) result.modelCount = modelCount;
    return result;
  }

  FetchLlmCatalogPush._();

  factory FetchLlmCatalogPush.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      FetchLlmCatalogPush()..mergeFromBuffer(data, registry);
  factory FetchLlmCatalogPush.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      FetchLlmCatalogPush()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FetchLlmCatalogPush',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: FetchLlmCatalogPush.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'syncTsMs')
    ..aI(2, _omitFieldNames ? '' : 'modelCount')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FetchLlmCatalogPush clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FetchLlmCatalogPush copyWith(void Function(FetchLlmCatalogPush) updates) =>
      super.copyWith((message) => updates(message as FetchLlmCatalogPush))
          as FetchLlmCatalogPush;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use FetchLlmCatalogPush() / FetchLlmCatalogPush.new instead')
  static FetchLlmCatalogPush create() => FetchLlmCatalogPush._();
  static $pb.GeneratedMessage $_createMessage() => FetchLlmCatalogPush._();
  @$core.override
  FetchLlmCatalogPush createEmptyInstance() => FetchLlmCatalogPush._();
  @$core.pragma('dart2js:noInline')
  static FetchLlmCatalogPush getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FetchLlmCatalogPush>(
          FetchLlmCatalogPush.$_createMessage);
  static FetchLlmCatalogPush? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get syncTsMs => $_getI64(0);
  @$pb.TagNumber(1)
  set syncTsMs($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSyncTsMs() => $_has(0);
  @$pb.TagNumber(1)
  void clearSyncTsMs() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get modelCount => $_getIZ(1);
  @$pb.TagNumber(2)
  set modelCount($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasModelCount() => $_has(1);
  @$pb.TagNumber(2)
  void clearModelCount() => $_clearField(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
