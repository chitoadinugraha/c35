// This is a generated file - do not edit.
//
// Generated from c35/collection.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'collection.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'collection.pbenum.dart';

class ColDef extends $pb.GeneratedMessage {
  factory ColDef({
    $core.String? key,
    $core.String? label,
    ColType? type,
    $core.bool? readonly,
    $core.bool? required,
    $core.String? refCollection,
    $core.bool? inlineEditable,
  }) {
    final result = ColDef._();
    if (key != null) result.key = key;
    if (label != null) result.label = label;
    if (type != null) result.type = type;
    if (readonly != null) result.readonly = readonly;
    if (required != null) result.required = required;
    if (refCollection != null) result.refCollection = refCollection;
    if (inlineEditable != null) result.inlineEditable = inlineEditable;
    return result;
  }

  ColDef._();

  factory ColDef.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ColDef()..mergeFromBuffer(data, registry);
  factory ColDef.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ColDef()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ColDef',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ColDef.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'key')
    ..aOS(2, _omitFieldNames ? '' : 'label')
    ..aE<ColType>(3, _omitFieldNames ? '' : 'type', enumValues: ColType.values)
    ..aOB(4, _omitFieldNames ? '' : 'readonly')
    ..aOB(5, _omitFieldNames ? '' : 'required')
    ..aOS(6, _omitFieldNames ? '' : 'refCollection')
    ..aOB(7, _omitFieldNames ? '' : 'inlineEditable')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ColDef clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ColDef copyWith(void Function(ColDef) updates) =>
      super.copyWith((message) => updates(message as ColDef)) as ColDef;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ColDef() / ColDef.new instead')
  static ColDef create() => ColDef._();
  static $pb.GeneratedMessage $_createMessage() => ColDef._();
  @$core.override
  ColDef createEmptyInstance() => ColDef._();
  @$core.pragma('dart2js:noInline')
  static ColDef getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ColDef>(ColDef.$_createMessage);
  static ColDef? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get key => $_getSZ(0);
  @$pb.TagNumber(1)
  set key($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearKey() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get label => $_getSZ(1);
  @$pb.TagNumber(2)
  set label($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLabel() => $_has(1);
  @$pb.TagNumber(2)
  void clearLabel() => $_clearField(2);

  @$pb.TagNumber(3)
  ColType get type => $_getN(2);
  @$pb.TagNumber(3)
  set type(ColType value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasType() => $_has(2);
  @$pb.TagNumber(3)
  void clearType() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get readonly => $_getBF(3);
  @$pb.TagNumber(4)
  set readonly($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasReadonly() => $_has(3);
  @$pb.TagNumber(4)
  void clearReadonly() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get required => $_getBF(4);
  @$pb.TagNumber(5)
  set required($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasRequired() => $_has(4);
  @$pb.TagNumber(5)
  void clearRequired() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get refCollection => $_getSZ(5);
  @$pb.TagNumber(6)
  set refCollection($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasRefCollection() => $_has(5);
  @$pb.TagNumber(6)
  void clearRefCollection() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.bool get inlineEditable => $_getBF(6);
  @$pb.TagNumber(7)
  set inlineEditable($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasInlineEditable() => $_has(6);
  @$pb.TagNumber(7)
  void clearInlineEditable() => $_clearField(7);
}

class SubTableDef extends $pb.GeneratedMessage {
  factory SubTableDef({
    $core.String? collection,
    $core.String? label,
    $core.Iterable<$core.String>? fkKeys,
    $core.String? syncName,
  }) {
    final result = SubTableDef._();
    if (collection != null) result.collection = collection;
    if (label != null) result.label = label;
    if (fkKeys != null) result.fkKeys.addAll(fkKeys);
    if (syncName != null) result.syncName = syncName;
    return result;
  }

  SubTableDef._();

  factory SubTableDef.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SubTableDef()..mergeFromBuffer(data, registry);
  factory SubTableDef.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SubTableDef()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SubTableDef',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: SubTableDef.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'collection')
    ..aOS(2, _omitFieldNames ? '' : 'label')
    ..pPS(3, _omitFieldNames ? '' : 'fkKeys')
    ..aOS(4, _omitFieldNames ? '' : 'syncName')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubTableDef clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubTableDef copyWith(void Function(SubTableDef) updates) =>
      super.copyWith((message) => updates(message as SubTableDef))
          as SubTableDef;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SubTableDef() / SubTableDef.new instead')
  static SubTableDef create() => SubTableDef._();
  static $pb.GeneratedMessage $_createMessage() => SubTableDef._();
  @$core.override
  SubTableDef createEmptyInstance() => SubTableDef._();
  @$core.pragma('dart2js:noInline')
  static SubTableDef getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SubTableDef>(
          SubTableDef.$_createMessage);
  static SubTableDef? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get collection => $_getSZ(0);
  @$pb.TagNumber(1)
  set collection($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCollection() => $_has(0);
  @$pb.TagNumber(1)
  void clearCollection() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get label => $_getSZ(1);
  @$pb.TagNumber(2)
  set label($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLabel() => $_has(1);
  @$pb.TagNumber(2)
  void clearLabel() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<$core.String> get fkKeys => $_getList(2);

  @$pb.TagNumber(4)
  $core.String get syncName => $_getSZ(3);
  @$pb.TagNumber(4)
  set syncName($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSyncName() => $_has(3);
  @$pb.TagNumber(4)
  void clearSyncName() => $_clearField(4);
}

class TableDef extends $pb.GeneratedMessage {
  factory TableDef({
    $core.String? collection,
    $core.String? label,
    $core.Iterable<ColDef>? columns,
    $core.Iterable<SubTableDef>? subtables,
    $core.String? syncName,
    $core.bool? siteScoped,
    $core.String? primaryKey,
  }) {
    final result = TableDef._();
    if (collection != null) result.collection = collection;
    if (label != null) result.label = label;
    if (columns != null) result.columns.addAll(columns);
    if (subtables != null) result.subtables.addAll(subtables);
    if (syncName != null) result.syncName = syncName;
    if (siteScoped != null) result.siteScoped = siteScoped;
    if (primaryKey != null) result.primaryKey = primaryKey;
    return result;
  }

  TableDef._();

  factory TableDef.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TableDef()..mergeFromBuffer(data, registry);
  factory TableDef.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TableDef()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TableDef',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: TableDef.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'collection')
    ..aOS(2, _omitFieldNames ? '' : 'label')
    ..pPM<ColDef>(3, _omitFieldNames ? '' : 'columns',
        subBuilder: ColDef.$_createMessage)
    ..pPM<SubTableDef>(4, _omitFieldNames ? '' : 'subtables',
        subBuilder: SubTableDef.$_createMessage)
    ..aOS(5, _omitFieldNames ? '' : 'syncName')
    ..aOB(6, _omitFieldNames ? '' : 'siteScoped')
    ..aOS(7, _omitFieldNames ? '' : 'primaryKey')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TableDef clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TableDef copyWith(void Function(TableDef) updates) =>
      super.copyWith((message) => updates(message as TableDef)) as TableDef;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use TableDef() / TableDef.new instead')
  static TableDef create() => TableDef._();
  static $pb.GeneratedMessage $_createMessage() => TableDef._();
  @$core.override
  TableDef createEmptyInstance() => TableDef._();
  @$core.pragma('dart2js:noInline')
  static TableDef getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TableDef>(TableDef.$_createMessage);
  static TableDef? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get collection => $_getSZ(0);
  @$pb.TagNumber(1)
  set collection($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCollection() => $_has(0);
  @$pb.TagNumber(1)
  void clearCollection() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get label => $_getSZ(1);
  @$pb.TagNumber(2)
  set label($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLabel() => $_has(1);
  @$pb.TagNumber(2)
  void clearLabel() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<ColDef> get columns => $_getList(2);

  @$pb.TagNumber(4)
  $pb.PbList<SubTableDef> get subtables => $_getList(3);

  @$pb.TagNumber(5)
  $core.String get syncName => $_getSZ(4);
  @$pb.TagNumber(5)
  set syncName($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSyncName() => $_has(4);
  @$pb.TagNumber(5)
  void clearSyncName() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get siteScoped => $_getBF(5);
  @$pb.TagNumber(6)
  set siteScoped($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasSiteScoped() => $_has(5);
  @$pb.TagNumber(6)
  void clearSiteScoped() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get primaryKey => $_getSZ(6);
  @$pb.TagNumber(7)
  set primaryKey($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasPrimaryKey() => $_has(6);
  @$pb.TagNumber(7)
  void clearPrimaryKey() => $_clearField(7);
}

class ReqCollectionDefList extends $pb.GeneratedMessage {
  factory ReqCollectionDefList({
    $fixnum.Int64? siteIid,
  }) {
    final result = ReqCollectionDefList._();
    if (siteIid != null) result.siteIid = siteIid;
    return result;
  }

  ReqCollectionDefList._();

  factory ReqCollectionDefList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqCollectionDefList()..mergeFromBuffer(data, registry);
  factory ReqCollectionDefList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqCollectionDefList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqCollectionDefList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqCollectionDefList.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'siteIid')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqCollectionDefList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqCollectionDefList copyWith(void Function(ReqCollectionDefList) updates) =>
      super.copyWith((message) => updates(message as ReqCollectionDefList))
          as ReqCollectionDefList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ReqCollectionDefList() / ReqCollectionDefList.new instead')
  static ReqCollectionDefList create() => ReqCollectionDefList._();
  static $pb.GeneratedMessage $_createMessage() => ReqCollectionDefList._();
  @$core.override
  ReqCollectionDefList createEmptyInstance() => ReqCollectionDefList._();
  @$core.pragma('dart2js:noInline')
  static ReqCollectionDefList getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqCollectionDefList>(
          ReqCollectionDefList.$_createMessage);
  static ReqCollectionDefList? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get siteIid => $_getI64(0);
  @$pb.TagNumber(1)
  set siteIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSiteIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearSiteIid() => $_clearField(1);
}

class ResCollectionDefList extends $pb.GeneratedMessage {
  factory ResCollectionDefList({
    $core.Iterable<TableDef>? tables,
  }) {
    final result = ResCollectionDefList._();
    if (tables != null) result.tables.addAll(tables);
    return result;
  }

  ResCollectionDefList._();

  factory ResCollectionDefList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResCollectionDefList()..mergeFromBuffer(data, registry);
  factory ResCollectionDefList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResCollectionDefList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResCollectionDefList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResCollectionDefList.$_createMessage)
    ..pPM<TableDef>(1, _omitFieldNames ? '' : 'tables',
        subBuilder: TableDef.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResCollectionDefList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResCollectionDefList copyWith(void Function(ResCollectionDefList) updates) =>
      super.copyWith((message) => updates(message as ResCollectionDefList))
          as ResCollectionDefList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ResCollectionDefList() / ResCollectionDefList.new instead')
  static ResCollectionDefList create() => ResCollectionDefList._();
  static $pb.GeneratedMessage $_createMessage() => ResCollectionDefList._();
  @$core.override
  ResCollectionDefList createEmptyInstance() => ResCollectionDefList._();
  @$core.pragma('dart2js:noInline')
  static ResCollectionDefList getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResCollectionDefList>(
          ResCollectionDefList.$_createMessage);
  static ResCollectionDefList? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<TableDef> get tables => $_getList(0);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
