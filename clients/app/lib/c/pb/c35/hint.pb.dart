// This is a generated file - do not edit.
//
// Generated from c35/hint.proto.

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

class HintAction extends $pb.GeneratedMessage {
  factory HintAction({
    $core.String? kind,
    $core.String? payloadJson,
  }) {
    final result = HintAction._();
    if (kind != null) result.kind = kind;
    if (payloadJson != null) result.payloadJson = payloadJson;
    return result;
  }

  HintAction._();

  factory HintAction.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      HintAction()..mergeFromBuffer(data, registry);
  factory HintAction.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      HintAction()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'HintAction',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: HintAction.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'kind')
    ..aOS(2, _omitFieldNames ? '' : 'payloadJson')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HintAction clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HintAction copyWith(void Function(HintAction) updates) =>
      super.copyWith((message) => updates(message as HintAction)) as HintAction;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use HintAction() / HintAction.new instead')
  static HintAction create() => HintAction._();
  static $pb.GeneratedMessage $_createMessage() => HintAction._();
  @$core.override
  HintAction createEmptyInstance() => HintAction._();
  @$core.pragma('dart2js:noInline')
  static HintAction getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<HintAction>(HintAction.$_createMessage);
  static HintAction? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get kind => $_getSZ(0);
  @$pb.TagNumber(1)
  set kind($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasKind() => $_has(0);
  @$pb.TagNumber(1)
  void clearKind() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get payloadJson => $_getSZ(1);
  @$pb.TagNumber(2)
  set payloadJson($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPayloadJson() => $_has(1);
  @$pb.TagNumber(2)
  void clearPayloadJson() => $_clearField(2);
}

class HintItem extends $pb.GeneratedMessage {
  factory HintItem({
    $core.String? id,
    $core.String? label,
    $core.String? icon,
    $core.int? sort,
    HintAction? action,
    $core.Iterable<HintItem>? items,
  }) {
    final result = HintItem._();
    if (id != null) result.id = id;
    if (label != null) result.label = label;
    if (icon != null) result.icon = icon;
    if (sort != null) result.sort = sort;
    if (action != null) result.action = action;
    if (items != null) result.items.addAll(items);
    return result;
  }

  HintItem._();

  factory HintItem.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      HintItem()..mergeFromBuffer(data, registry);
  factory HintItem.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      HintItem()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'HintItem',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: HintItem.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'label')
    ..aOS(3, _omitFieldNames ? '' : 'icon')
    ..aI(4, _omitFieldNames ? '' : 'sort')
    ..aOM<HintAction>(5, _omitFieldNames ? '' : 'action',
        subBuilder: HintAction.$_createMessage)
    ..pPM<HintItem>(6, _omitFieldNames ? '' : 'items',
        subBuilder: HintItem.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HintItem clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HintItem copyWith(void Function(HintItem) updates) =>
      super.copyWith((message) => updates(message as HintItem)) as HintItem;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use HintItem() / HintItem.new instead')
  static HintItem create() => HintItem._();
  static $pb.GeneratedMessage $_createMessage() => HintItem._();
  @$core.override
  HintItem createEmptyInstance() => HintItem._();
  @$core.pragma('dart2js:noInline')
  static HintItem getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<HintItem>(HintItem.$_createMessage);
  static HintItem? _defaultInstance;

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
  $core.String get icon => $_getSZ(2);
  @$pb.TagNumber(3)
  set icon($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasIcon() => $_has(2);
  @$pb.TagNumber(3)
  void clearIcon() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get sort => $_getIZ(3);
  @$pb.TagNumber(4)
  set sort($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSort() => $_has(3);
  @$pb.TagNumber(4)
  void clearSort() => $_clearField(4);

  @$pb.TagNumber(5)
  HintAction get action => $_getN(4);
  @$pb.TagNumber(5)
  set action(HintAction value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasAction() => $_has(4);
  @$pb.TagNumber(5)
  void clearAction() => $_clearField(5);
  @$pb.TagNumber(5)
  HintAction ensureAction() => $_ensure(4);

  @$pb.TagNumber(6)
  $pb.PbList<HintItem> get items => $_getList(5);
}

class HintCatalog extends $pb.GeneratedMessage {
  factory HintCatalog({
    $fixnum.Int64? updatedTsMs,
    $core.Iterable<HintItem>? items,
  }) {
    final result = HintCatalog._();
    if (updatedTsMs != null) result.updatedTsMs = updatedTsMs;
    if (items != null) result.items.addAll(items);
    return result;
  }

  HintCatalog._();

  factory HintCatalog.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      HintCatalog()..mergeFromBuffer(data, registry);
  factory HintCatalog.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      HintCatalog()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'HintCatalog',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: HintCatalog.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'updatedTsMs')
    ..pPM<HintItem>(2, _omitFieldNames ? '' : 'items',
        subBuilder: HintItem.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HintCatalog clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HintCatalog copyWith(void Function(HintCatalog) updates) =>
      super.copyWith((message) => updates(message as HintCatalog))
          as HintCatalog;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use HintCatalog() / HintCatalog.new instead')
  static HintCatalog create() => HintCatalog._();
  static $pb.GeneratedMessage $_createMessage() => HintCatalog._();
  @$core.override
  HintCatalog createEmptyInstance() => HintCatalog._();
  @$core.pragma('dart2js:noInline')
  static HintCatalog getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<HintCatalog>(
          HintCatalog.$_createMessage);
  static HintCatalog? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get updatedTsMs => $_getI64(0);
  @$pb.TagNumber(1)
  set updatedTsMs($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUpdatedTsMs() => $_has(0);
  @$pb.TagNumber(1)
  void clearUpdatedTsMs() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<HintItem> get items => $_getList(1);
}

class ReqHintTouch extends $pb.GeneratedMessage {
  factory ReqHintTouch({
    $fixnum.Int64? assetIid,
    $core.String? assetKind,
  }) {
    final result = ReqHintTouch._();
    if (assetIid != null) result.assetIid = assetIid;
    if (assetKind != null) result.assetKind = assetKind;
    return result;
  }

  ReqHintTouch._();

  factory ReqHintTouch.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqHintTouch()..mergeFromBuffer(data, registry);
  factory ReqHintTouch.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqHintTouch()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqHintTouch',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqHintTouch.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'assetIid')
    ..aOS(2, _omitFieldNames ? '' : 'assetKind')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqHintTouch clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqHintTouch copyWith(void Function(ReqHintTouch) updates) =>
      super.copyWith((message) => updates(message as ReqHintTouch))
          as ReqHintTouch;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqHintTouch() / ReqHintTouch.new instead')
  static ReqHintTouch create() => ReqHintTouch._();
  static $pb.GeneratedMessage $_createMessage() => ReqHintTouch._();
  @$core.override
  ReqHintTouch createEmptyInstance() => ReqHintTouch._();
  @$core.pragma('dart2js:noInline')
  static ReqHintTouch getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqHintTouch>(
          ReqHintTouch.$_createMessage);
  static ReqHintTouch? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get assetIid => $_getI64(0);
  @$pb.TagNumber(1)
  set assetIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAssetIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearAssetIid() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get assetKind => $_getSZ(1);
  @$pb.TagNumber(2)
  set assetKind($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAssetKind() => $_has(1);
  @$pb.TagNumber(2)
  void clearAssetKind() => $_clearField(2);
}

class ResHintTouch extends $pb.GeneratedMessage {
  factory ResHintTouch({
    $core.bool? ok,
  }) {
    final result = ResHintTouch._();
    if (ok != null) result.ok = ok;
    return result;
  }

  ResHintTouch._();

  factory ResHintTouch.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResHintTouch()..mergeFromBuffer(data, registry);
  factory ResHintTouch.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResHintTouch()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResHintTouch',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResHintTouch.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'ok')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResHintTouch clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResHintTouch copyWith(void Function(ResHintTouch) updates) =>
      super.copyWith((message) => updates(message as ResHintTouch))
          as ResHintTouch;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResHintTouch() / ResHintTouch.new instead')
  static ResHintTouch create() => ResHintTouch._();
  static $pb.GeneratedMessage $_createMessage() => ResHintTouch._();
  @$core.override
  ResHintTouch createEmptyInstance() => ResHintTouch._();
  @$core.pragma('dart2js:noInline')
  static ResHintTouch getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResHintTouch>(
          ResHintTouch.$_createMessage);
  static ResHintTouch? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get ok => $_getBF(0);
  @$pb.TagNumber(1)
  set ok($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOk() => $_has(0);
  @$pb.TagNumber(1)
  void clearOk() => $_clearField(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
