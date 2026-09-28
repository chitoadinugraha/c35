// This is a generated file - do not edit.
//
// Generated from c35/data_source.proto.

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

class DataSourceDoc extends $pb.GeneratedMessage {
  factory DataSourceDoc({
    $fixnum.Int64? id,
    $fixnum.Int64? botIid,
    $core.String? sourceKind,
    $core.String? name,
    $core.String? configJson,
    $core.String? syncStatus,
    $core.int? rowCount,
    $fixnum.Int64? syncedTsMs,
    $fixnum.Int64? updatedTsMs,
  }) {
    final result = DataSourceDoc._();
    if (id != null) result.id = id;
    if (botIid != null) result.botIid = botIid;
    if (sourceKind != null) result.sourceKind = sourceKind;
    if (name != null) result.name = name;
    if (configJson != null) result.configJson = configJson;
    if (syncStatus != null) result.syncStatus = syncStatus;
    if (rowCount != null) result.rowCount = rowCount;
    if (syncedTsMs != null) result.syncedTsMs = syncedTsMs;
    if (updatedTsMs != null) result.updatedTsMs = updatedTsMs;
    return result;
  }

  DataSourceDoc._();

  factory DataSourceDoc.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DataSourceDoc()..mergeFromBuffer(data, registry);
  factory DataSourceDoc.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DataSourceDoc()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DataSourceDoc',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: DataSourceDoc.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..aInt64(2, _omitFieldNames ? '' : 'botIid')
    ..aOS(3, _omitFieldNames ? '' : 'sourceKind')
    ..aOS(4, _omitFieldNames ? '' : 'name')
    ..aOS(5, _omitFieldNames ? '' : 'configJson')
    ..aOS(6, _omitFieldNames ? '' : 'syncStatus')
    ..aI(7, _omitFieldNames ? '' : 'rowCount')
    ..aInt64(8, _omitFieldNames ? '' : 'syncedTsMs')
    ..aInt64(9, _omitFieldNames ? '' : 'updatedTsMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DataSourceDoc clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DataSourceDoc copyWith(void Function(DataSourceDoc) updates) =>
      super.copyWith((message) => updates(message as DataSourceDoc))
          as DataSourceDoc;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use DataSourceDoc() / DataSourceDoc.new instead')
  static DataSourceDoc create() => DataSourceDoc._();
  static $pb.GeneratedMessage $_createMessage() => DataSourceDoc._();
  @$core.override
  DataSourceDoc createEmptyInstance() => DataSourceDoc._();
  @$core.pragma('dart2js:noInline')
  static DataSourceDoc getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DataSourceDoc>(
          DataSourceDoc.$_createMessage);
  static DataSourceDoc? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get botIid => $_getI64(1);
  @$pb.TagNumber(2)
  set botIid($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasBotIid() => $_has(1);
  @$pb.TagNumber(2)
  void clearBotIid() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get sourceKind => $_getSZ(2);
  @$pb.TagNumber(3)
  set sourceKind($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSourceKind() => $_has(2);
  @$pb.TagNumber(3)
  void clearSourceKind() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get name => $_getSZ(3);
  @$pb.TagNumber(4)
  set name($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasName() => $_has(3);
  @$pb.TagNumber(4)
  void clearName() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get configJson => $_getSZ(4);
  @$pb.TagNumber(5)
  set configJson($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasConfigJson() => $_has(4);
  @$pb.TagNumber(5)
  void clearConfigJson() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get syncStatus => $_getSZ(5);
  @$pb.TagNumber(6)
  set syncStatus($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasSyncStatus() => $_has(5);
  @$pb.TagNumber(6)
  void clearSyncStatus() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.int get rowCount => $_getIZ(6);
  @$pb.TagNumber(7)
  set rowCount($core.int value) => $_setSignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasRowCount() => $_has(6);
  @$pb.TagNumber(7)
  void clearRowCount() => $_clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get syncedTsMs => $_getI64(7);
  @$pb.TagNumber(8)
  set syncedTsMs($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(8)
  $core.bool hasSyncedTsMs() => $_has(7);
  @$pb.TagNumber(8)
  void clearSyncedTsMs() => $_clearField(8);

  @$pb.TagNumber(9)
  $fixnum.Int64 get updatedTsMs => $_getI64(8);
  @$pb.TagNumber(9)
  set updatedTsMs($fixnum.Int64 value) => $_setInt64(8, value);
  @$pb.TagNumber(9)
  $core.bool hasUpdatedTsMs() => $_has(8);
  @$pb.TagNumber(9)
  void clearUpdatedTsMs() => $_clearField(9);
}

class ReqDataSourceList extends $pb.GeneratedMessage {
  factory ReqDataSourceList({
    $fixnum.Int64? botIid,
    $fixnum.Int64? sinceUpdatedTsMs,
    $core.int? limit,
  }) {
    final result = ReqDataSourceList._();
    if (botIid != null) result.botIid = botIid;
    if (sinceUpdatedTsMs != null) result.sinceUpdatedTsMs = sinceUpdatedTsMs;
    if (limit != null) result.limit = limit;
    return result;
  }

  ReqDataSourceList._();

  factory ReqDataSourceList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqDataSourceList()..mergeFromBuffer(data, registry);
  factory ReqDataSourceList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqDataSourceList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqDataSourceList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqDataSourceList.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'botIid')
    ..aInt64(2, _omitFieldNames ? '' : 'sinceUpdatedTsMs')
    ..aI(3, _omitFieldNames ? '' : 'limit')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqDataSourceList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqDataSourceList copyWith(void Function(ReqDataSourceList) updates) =>
      super.copyWith((message) => updates(message as ReqDataSourceList))
          as ReqDataSourceList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqDataSourceList() / ReqDataSourceList.new instead')
  static ReqDataSourceList create() => ReqDataSourceList._();
  static $pb.GeneratedMessage $_createMessage() => ReqDataSourceList._();
  @$core.override
  ReqDataSourceList createEmptyInstance() => ReqDataSourceList._();
  @$core.pragma('dart2js:noInline')
  static ReqDataSourceList getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqDataSourceList>(
          ReqDataSourceList.$_createMessage);
  static ReqDataSourceList? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get botIid => $_getI64(0);
  @$pb.TagNumber(1)
  set botIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasBotIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearBotIid() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get sinceUpdatedTsMs => $_getI64(1);
  @$pb.TagNumber(2)
  set sinceUpdatedTsMs($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSinceUpdatedTsMs() => $_has(1);
  @$pb.TagNumber(2)
  void clearSinceUpdatedTsMs() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get limit => $_getIZ(2);
  @$pb.TagNumber(3)
  set limit($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLimit() => $_has(2);
  @$pb.TagNumber(3)
  void clearLimit() => $_clearField(3);
}

class ResDataSourceList extends $pb.GeneratedMessage {
  factory ResDataSourceList({
    $core.Iterable<DataSourceDoc>? items,
  }) {
    final result = ResDataSourceList._();
    if (items != null) result.items.addAll(items);
    return result;
  }

  ResDataSourceList._();

  factory ResDataSourceList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResDataSourceList()..mergeFromBuffer(data, registry);
  factory ResDataSourceList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResDataSourceList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResDataSourceList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResDataSourceList.$_createMessage)
    ..pPM<DataSourceDoc>(1, _omitFieldNames ? '' : 'items',
        subBuilder: DataSourceDoc.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResDataSourceList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResDataSourceList copyWith(void Function(ResDataSourceList) updates) =>
      super.copyWith((message) => updates(message as ResDataSourceList))
          as ResDataSourceList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResDataSourceList() / ResDataSourceList.new instead')
  static ResDataSourceList create() => ResDataSourceList._();
  static $pb.GeneratedMessage $_createMessage() => ResDataSourceList._();
  @$core.override
  ResDataSourceList createEmptyInstance() => ResDataSourceList._();
  @$core.pragma('dart2js:noInline')
  static ResDataSourceList getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResDataSourceList>(
          ResDataSourceList.$_createMessage);
  static ResDataSourceList? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<DataSourceDoc> get items => $_getList(0);
}

class ReqDataSourcePut extends $pb.GeneratedMessage {
  factory ReqDataSourcePut({
    DataSourceDoc? doc,
  }) {
    final result = ReqDataSourcePut._();
    if (doc != null) result.doc = doc;
    return result;
  }

  ReqDataSourcePut._();

  factory ReqDataSourcePut.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqDataSourcePut()..mergeFromBuffer(data, registry);
  factory ReqDataSourcePut.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqDataSourcePut()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqDataSourcePut',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqDataSourcePut.$_createMessage)
    ..aOM<DataSourceDoc>(1, _omitFieldNames ? '' : 'doc',
        subBuilder: DataSourceDoc.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqDataSourcePut clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqDataSourcePut copyWith(void Function(ReqDataSourcePut) updates) =>
      super.copyWith((message) => updates(message as ReqDataSourcePut))
          as ReqDataSourcePut;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqDataSourcePut() / ReqDataSourcePut.new instead')
  static ReqDataSourcePut create() => ReqDataSourcePut._();
  static $pb.GeneratedMessage $_createMessage() => ReqDataSourcePut._();
  @$core.override
  ReqDataSourcePut createEmptyInstance() => ReqDataSourcePut._();
  @$core.pragma('dart2js:noInline')
  static ReqDataSourcePut getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqDataSourcePut>(
          ReqDataSourcePut.$_createMessage);
  static ReqDataSourcePut? _defaultInstance;

  @$pb.TagNumber(1)
  DataSourceDoc get doc => $_getN(0);
  @$pb.TagNumber(1)
  set doc(DataSourceDoc value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasDoc() => $_has(0);
  @$pb.TagNumber(1)
  void clearDoc() => $_clearField(1);
  @$pb.TagNumber(1)
  DataSourceDoc ensureDoc() => $_ensure(0);
}

class ResDataSourcePut extends $pb.GeneratedMessage {
  factory ResDataSourcePut({
    $fixnum.Int64? id,
    DataSourceDoc? doc,
  }) {
    final result = ResDataSourcePut._();
    if (id != null) result.id = id;
    if (doc != null) result.doc = doc;
    return result;
  }

  ResDataSourcePut._();

  factory ResDataSourcePut.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResDataSourcePut()..mergeFromBuffer(data, registry);
  factory ResDataSourcePut.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResDataSourcePut()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResDataSourcePut',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResDataSourcePut.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..aOM<DataSourceDoc>(2, _omitFieldNames ? '' : 'doc',
        subBuilder: DataSourceDoc.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResDataSourcePut clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResDataSourcePut copyWith(void Function(ResDataSourcePut) updates) =>
      super.copyWith((message) => updates(message as ResDataSourcePut))
          as ResDataSourcePut;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResDataSourcePut() / ResDataSourcePut.new instead')
  static ResDataSourcePut create() => ResDataSourcePut._();
  static $pb.GeneratedMessage $_createMessage() => ResDataSourcePut._();
  @$core.override
  ResDataSourcePut createEmptyInstance() => ResDataSourcePut._();
  @$core.pragma('dart2js:noInline')
  static ResDataSourcePut getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResDataSourcePut>(
          ResDataSourcePut.$_createMessage);
  static ResDataSourcePut? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  DataSourceDoc get doc => $_getN(1);
  @$pb.TagNumber(2)
  set doc(DataSourceDoc value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasDoc() => $_has(1);
  @$pb.TagNumber(2)
  void clearDoc() => $_clearField(2);
  @$pb.TagNumber(2)
  DataSourceDoc ensureDoc() => $_ensure(1);
}

class ReqDataSourceDelete extends $pb.GeneratedMessage {
  factory ReqDataSourceDelete({
    $fixnum.Int64? id,
  }) {
    final result = ReqDataSourceDelete._();
    if (id != null) result.id = id;
    return result;
  }

  ReqDataSourceDelete._();

  factory ReqDataSourceDelete.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqDataSourceDelete()..mergeFromBuffer(data, registry);
  factory ReqDataSourceDelete.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqDataSourceDelete()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqDataSourceDelete',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqDataSourceDelete.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqDataSourceDelete clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqDataSourceDelete copyWith(void Function(ReqDataSourceDelete) updates) =>
      super.copyWith((message) => updates(message as ReqDataSourceDelete))
          as ReqDataSourceDelete;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use ReqDataSourceDelete() / ReqDataSourceDelete.new instead')
  static ReqDataSourceDelete create() => ReqDataSourceDelete._();
  static $pb.GeneratedMessage $_createMessage() => ReqDataSourceDelete._();
  @$core.override
  ReqDataSourceDelete createEmptyInstance() => ReqDataSourceDelete._();
  @$core.pragma('dart2js:noInline')
  static ReqDataSourceDelete getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqDataSourceDelete>(
          ReqDataSourceDelete.$_createMessage);
  static ReqDataSourceDelete? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);
}

class ResDataSourceDelete extends $pb.GeneratedMessage {
  factory ResDataSourceDelete({
    $core.bool? ok,
  }) {
    final result = ResDataSourceDelete._();
    if (ok != null) result.ok = ok;
    return result;
  }

  ResDataSourceDelete._();

  factory ResDataSourceDelete.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResDataSourceDelete()..mergeFromBuffer(data, registry);
  factory ResDataSourceDelete.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResDataSourceDelete()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResDataSourceDelete',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResDataSourceDelete.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'ok')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResDataSourceDelete clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResDataSourceDelete copyWith(void Function(ResDataSourceDelete) updates) =>
      super.copyWith((message) => updates(message as ResDataSourceDelete))
          as ResDataSourceDelete;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use ResDataSourceDelete() / ResDataSourceDelete.new instead')
  static ResDataSourceDelete create() => ResDataSourceDelete._();
  static $pb.GeneratedMessage $_createMessage() => ResDataSourceDelete._();
  @$core.override
  ResDataSourceDelete createEmptyInstance() => ResDataSourceDelete._();
  @$core.pragma('dart2js:noInline')
  static ResDataSourceDelete getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResDataSourceDelete>(
          ResDataSourceDelete.$_createMessage);
  static ResDataSourceDelete? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get ok => $_getBF(0);
  @$pb.TagNumber(1)
  set ok($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOk() => $_has(0);
  @$pb.TagNumber(1)
  void clearOk() => $_clearField(1);
}

class ReqDataSourceSync extends $pb.GeneratedMessage {
  factory ReqDataSourceSync({
    $fixnum.Int64? id,
  }) {
    final result = ReqDataSourceSync._();
    if (id != null) result.id = id;
    return result;
  }

  ReqDataSourceSync._();

  factory ReqDataSourceSync.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqDataSourceSync()..mergeFromBuffer(data, registry);
  factory ReqDataSourceSync.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqDataSourceSync()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqDataSourceSync',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqDataSourceSync.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqDataSourceSync clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqDataSourceSync copyWith(void Function(ReqDataSourceSync) updates) =>
      super.copyWith((message) => updates(message as ReqDataSourceSync))
          as ReqDataSourceSync;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqDataSourceSync() / ReqDataSourceSync.new instead')
  static ReqDataSourceSync create() => ReqDataSourceSync._();
  static $pb.GeneratedMessage $_createMessage() => ReqDataSourceSync._();
  @$core.override
  ReqDataSourceSync createEmptyInstance() => ReqDataSourceSync._();
  @$core.pragma('dart2js:noInline')
  static ReqDataSourceSync getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqDataSourceSync>(
          ReqDataSourceSync.$_createMessage);
  static ReqDataSourceSync? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);
}

class ResDataSourceSync extends $pb.GeneratedMessage {
  factory ResDataSourceSync({
    DataSourceDoc? doc,
  }) {
    final result = ResDataSourceSync._();
    if (doc != null) result.doc = doc;
    return result;
  }

  ResDataSourceSync._();

  factory ResDataSourceSync.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResDataSourceSync()..mergeFromBuffer(data, registry);
  factory ResDataSourceSync.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResDataSourceSync()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResDataSourceSync',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResDataSourceSync.$_createMessage)
    ..aOM<DataSourceDoc>(1, _omitFieldNames ? '' : 'doc',
        subBuilder: DataSourceDoc.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResDataSourceSync clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResDataSourceSync copyWith(void Function(ResDataSourceSync) updates) =>
      super.copyWith((message) => updates(message as ResDataSourceSync))
          as ResDataSourceSync;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResDataSourceSync() / ResDataSourceSync.new instead')
  static ResDataSourceSync create() => ResDataSourceSync._();
  static $pb.GeneratedMessage $_createMessage() => ResDataSourceSync._();
  @$core.override
  ResDataSourceSync createEmptyInstance() => ResDataSourceSync._();
  @$core.pragma('dart2js:noInline')
  static ResDataSourceSync getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResDataSourceSync>(
          ResDataSourceSync.$_createMessage);
  static ResDataSourceSync? _defaultInstance;

  @$pb.TagNumber(1)
  DataSourceDoc get doc => $_getN(0);
  @$pb.TagNumber(1)
  set doc(DataSourceDoc value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasDoc() => $_has(0);
  @$pb.TagNumber(1)
  void clearDoc() => $_clearField(1);
  @$pb.TagNumber(1)
  DataSourceDoc ensureDoc() => $_ensure(0);
}

class DataSourceSheetTab extends $pb.GeneratedMessage {
  factory DataSourceSheetTab({
    $core.String? title,
    $core.String? gid,
  }) {
    final result = DataSourceSheetTab._();
    if (title != null) result.title = title;
    if (gid != null) result.gid = gid;
    return result;
  }

  DataSourceSheetTab._();

  factory DataSourceSheetTab.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DataSourceSheetTab()..mergeFromBuffer(data, registry);
  factory DataSourceSheetTab.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DataSourceSheetTab()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DataSourceSheetTab',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: DataSourceSheetTab.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'title')
    ..aOS(2, _omitFieldNames ? '' : 'gid')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DataSourceSheetTab clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DataSourceSheetTab copyWith(void Function(DataSourceSheetTab) updates) =>
      super.copyWith((message) => updates(message as DataSourceSheetTab))
          as DataSourceSheetTab;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use DataSourceSheetTab() / DataSourceSheetTab.new instead')
  static DataSourceSheetTab create() => DataSourceSheetTab._();
  static $pb.GeneratedMessage $_createMessage() => DataSourceSheetTab._();
  @$core.override
  DataSourceSheetTab createEmptyInstance() => DataSourceSheetTab._();
  @$core.pragma('dart2js:noInline')
  static DataSourceSheetTab getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DataSourceSheetTab>(
          DataSourceSheetTab.$_createMessage);
  static DataSourceSheetTab? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get title => $_getSZ(0);
  @$pb.TagNumber(1)
  set title($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTitle() => $_has(0);
  @$pb.TagNumber(1)
  void clearTitle() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get gid => $_getSZ(1);
  @$pb.TagNumber(2)
  set gid($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasGid() => $_has(1);
  @$pb.TagNumber(2)
  void clearGid() => $_clearField(2);
}

class ReqDataSourceCheck extends $pb.GeneratedMessage {
  factory ReqDataSourceCheck({
    $core.String? sourceKind,
    $core.String? viewUrl,
  }) {
    final result = ReqDataSourceCheck._();
    if (sourceKind != null) result.sourceKind = sourceKind;
    if (viewUrl != null) result.viewUrl = viewUrl;
    return result;
  }

  ReqDataSourceCheck._();

  factory ReqDataSourceCheck.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqDataSourceCheck()..mergeFromBuffer(data, registry);
  factory ReqDataSourceCheck.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqDataSourceCheck()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqDataSourceCheck',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqDataSourceCheck.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'sourceKind')
    ..aOS(2, _omitFieldNames ? '' : 'viewUrl')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqDataSourceCheck clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqDataSourceCheck copyWith(void Function(ReqDataSourceCheck) updates) =>
      super.copyWith((message) => updates(message as ReqDataSourceCheck))
          as ReqDataSourceCheck;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqDataSourceCheck() / ReqDataSourceCheck.new instead')
  static ReqDataSourceCheck create() => ReqDataSourceCheck._();
  static $pb.GeneratedMessage $_createMessage() => ReqDataSourceCheck._();
  @$core.override
  ReqDataSourceCheck createEmptyInstance() => ReqDataSourceCheck._();
  @$core.pragma('dart2js:noInline')
  static ReqDataSourceCheck getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqDataSourceCheck>(
          ReqDataSourceCheck.$_createMessage);
  static ReqDataSourceCheck? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sourceKind => $_getSZ(0);
  @$pb.TagNumber(1)
  set sourceKind($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSourceKind() => $_has(0);
  @$pb.TagNumber(1)
  void clearSourceKind() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get viewUrl => $_getSZ(1);
  @$pb.TagNumber(2)
  set viewUrl($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasViewUrl() => $_has(1);
  @$pb.TagNumber(2)
  void clearViewUrl() => $_clearField(2);
}

class ResDataSourceCheck extends $pb.GeneratedMessage {
  factory ResDataSourceCheck({
    $core.bool? ok,
    $core.String? errorMsg,
    $core.String? title,
    $core.String? configJson,
    $core.Iterable<DataSourceSheetTab>? tabs,
  }) {
    final result = ResDataSourceCheck._();
    if (ok != null) result.ok = ok;
    if (errorMsg != null) result.errorMsg = errorMsg;
    if (title != null) result.title = title;
    if (configJson != null) result.configJson = configJson;
    if (tabs != null) result.tabs.addAll(tabs);
    return result;
  }

  ResDataSourceCheck._();

  factory ResDataSourceCheck.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResDataSourceCheck()..mergeFromBuffer(data, registry);
  factory ResDataSourceCheck.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResDataSourceCheck()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResDataSourceCheck',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResDataSourceCheck.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'ok')
    ..aOS(2, _omitFieldNames ? '' : 'errorMsg')
    ..aOS(3, _omitFieldNames ? '' : 'title')
    ..aOS(4, _omitFieldNames ? '' : 'configJson')
    ..pPM<DataSourceSheetTab>(5, _omitFieldNames ? '' : 'tabs',
        subBuilder: DataSourceSheetTab.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResDataSourceCheck clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResDataSourceCheck copyWith(void Function(ResDataSourceCheck) updates) =>
      super.copyWith((message) => updates(message as ResDataSourceCheck))
          as ResDataSourceCheck;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResDataSourceCheck() / ResDataSourceCheck.new instead')
  static ResDataSourceCheck create() => ResDataSourceCheck._();
  static $pb.GeneratedMessage $_createMessage() => ResDataSourceCheck._();
  @$core.override
  ResDataSourceCheck createEmptyInstance() => ResDataSourceCheck._();
  @$core.pragma('dart2js:noInline')
  static ResDataSourceCheck getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResDataSourceCheck>(
          ResDataSourceCheck.$_createMessage);
  static ResDataSourceCheck? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get ok => $_getBF(0);
  @$pb.TagNumber(1)
  set ok($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOk() => $_has(0);
  @$pb.TagNumber(1)
  void clearOk() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get errorMsg => $_getSZ(1);
  @$pb.TagNumber(2)
  set errorMsg($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasErrorMsg() => $_has(1);
  @$pb.TagNumber(2)
  void clearErrorMsg() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get title => $_getSZ(2);
  @$pb.TagNumber(3)
  set title($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTitle() => $_has(2);
  @$pb.TagNumber(3)
  void clearTitle() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get configJson => $_getSZ(3);
  @$pb.TagNumber(4)
  set configJson($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasConfigJson() => $_has(3);
  @$pb.TagNumber(4)
  void clearConfigJson() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbList<DataSourceSheetTab> get tabs => $_getList(4);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
