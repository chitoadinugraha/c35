// This is a generated file - do not edit.
//
// Generated from c35/inst.proto.

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

class InstDoc extends $pb.GeneratedMessage {
  factory InstDoc({
    $core.String? id,
    $core.String? scope,
    $core.String? kind,
    $core.String? topicId,
    $core.Iterable<$core.String>? topics,
    $core.String? inst,
    $core.Iterable<$core.String>? phrases,
    $core.Iterable<$core.String>? triggers,
    $core.int? priority,
    $core.bool? enabled,
    $core.String? defHash,
    $fixnum.Int64? createdTsMs,
    $fixnum.Int64? updatedTsMs,
    $fixnum.Int64? deletedTsMs,
  }) {
    final result = InstDoc._();
    if (id != null) result.id = id;
    if (scope != null) result.scope = scope;
    if (kind != null) result.kind = kind;
    if (topicId != null) result.topicId = topicId;
    if (topics != null) result.topics.addAll(topics);
    if (inst != null) result.inst = inst;
    if (phrases != null) result.phrases.addAll(phrases);
    if (triggers != null) result.triggers.addAll(triggers);
    if (priority != null) result.priority = priority;
    if (enabled != null) result.enabled = enabled;
    if (defHash != null) result.defHash = defHash;
    if (createdTsMs != null) result.createdTsMs = createdTsMs;
    if (updatedTsMs != null) result.updatedTsMs = updatedTsMs;
    if (deletedTsMs != null) result.deletedTsMs = deletedTsMs;
    return result;
  }

  InstDoc._();

  factory InstDoc.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      InstDoc()..mergeFromBuffer(data, registry);
  factory InstDoc.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      InstDoc()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InstDoc',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: InstDoc.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'scope')
    ..aOS(3, _omitFieldNames ? '' : 'kind')
    ..aOS(4, _omitFieldNames ? '' : 'topicId')
    ..pPS(5, _omitFieldNames ? '' : 'topics')
    ..aOS(6, _omitFieldNames ? '' : 'inst')
    ..pPS(7, _omitFieldNames ? '' : 'phrases')
    ..pPS(8, _omitFieldNames ? '' : 'triggers')
    ..aI(9, _omitFieldNames ? '' : 'priority')
    ..aOB(10, _omitFieldNames ? '' : 'enabled')
    ..aOS(11, _omitFieldNames ? '' : 'defHash')
    ..aInt64(12, _omitFieldNames ? '' : 'createdTsMs')
    ..aInt64(13, _omitFieldNames ? '' : 'updatedTsMs')
    ..aInt64(14, _omitFieldNames ? '' : 'deletedTsMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InstDoc clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InstDoc copyWith(void Function(InstDoc) updates) =>
      super.copyWith((message) => updates(message as InstDoc)) as InstDoc;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use InstDoc() / InstDoc.new instead')
  static InstDoc create() => InstDoc._();
  static $pb.GeneratedMessage $_createMessage() => InstDoc._();
  @$core.override
  InstDoc createEmptyInstance() => InstDoc._();
  @$core.pragma('dart2js:noInline')
  static InstDoc getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<InstDoc>(InstDoc.$_createMessage);
  static InstDoc? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get scope => $_getSZ(1);
  @$pb.TagNumber(2)
  set scope($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasScope() => $_has(1);
  @$pb.TagNumber(2)
  void clearScope() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get kind => $_getSZ(2);
  @$pb.TagNumber(3)
  set kind($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasKind() => $_has(2);
  @$pb.TagNumber(3)
  void clearKind() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get topicId => $_getSZ(3);
  @$pb.TagNumber(4)
  set topicId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTopicId() => $_has(3);
  @$pb.TagNumber(4)
  void clearTopicId() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbList<$core.String> get topics => $_getList(4);

  @$pb.TagNumber(6)
  $core.String get inst => $_getSZ(5);
  @$pb.TagNumber(6)
  set inst($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasInst() => $_has(5);
  @$pb.TagNumber(6)
  void clearInst() => $_clearField(6);

  @$pb.TagNumber(7)
  $pb.PbList<$core.String> get phrases => $_getList(6);

  @$pb.TagNumber(8)
  $pb.PbList<$core.String> get triggers => $_getList(7);

  @$pb.TagNumber(9)
  $core.int get priority => $_getIZ(8);
  @$pb.TagNumber(9)
  set priority($core.int value) => $_setSignedInt32(8, value);
  @$pb.TagNumber(9)
  $core.bool hasPriority() => $_has(8);
  @$pb.TagNumber(9)
  void clearPriority() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.bool get enabled => $_getBF(9);
  @$pb.TagNumber(10)
  set enabled($core.bool value) => $_setBool(9, value);
  @$pb.TagNumber(10)
  $core.bool hasEnabled() => $_has(9);
  @$pb.TagNumber(10)
  void clearEnabled() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.String get defHash => $_getSZ(10);
  @$pb.TagNumber(11)
  set defHash($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasDefHash() => $_has(10);
  @$pb.TagNumber(11)
  void clearDefHash() => $_clearField(11);

  @$pb.TagNumber(12)
  $fixnum.Int64 get createdTsMs => $_getI64(11);
  @$pb.TagNumber(12)
  set createdTsMs($fixnum.Int64 value) => $_setInt64(11, value);
  @$pb.TagNumber(12)
  $core.bool hasCreatedTsMs() => $_has(11);
  @$pb.TagNumber(12)
  void clearCreatedTsMs() => $_clearField(12);

  @$pb.TagNumber(13)
  $fixnum.Int64 get updatedTsMs => $_getI64(12);
  @$pb.TagNumber(13)
  set updatedTsMs($fixnum.Int64 value) => $_setInt64(12, value);
  @$pb.TagNumber(13)
  $core.bool hasUpdatedTsMs() => $_has(12);
  @$pb.TagNumber(13)
  void clearUpdatedTsMs() => $_clearField(13);

  @$pb.TagNumber(14)
  $fixnum.Int64 get deletedTsMs => $_getI64(13);
  @$pb.TagNumber(14)
  set deletedTsMs($fixnum.Int64 value) => $_setInt64(13, value);
  @$pb.TagNumber(14)
  $core.bool hasDeletedTsMs() => $_has(13);
  @$pb.TagNumber(14)
  void clearDeletedTsMs() => $_clearField(14);
}

class ReqInstList extends $pb.GeneratedMessage {
  factory ReqInstList({
    $core.String? scope,
    $core.String? kind,
    $core.bool? enabled,
    $core.bool? includeDeleted,
  }) {
    final result = ReqInstList._();
    if (scope != null) result.scope = scope;
    if (kind != null) result.kind = kind;
    if (enabled != null) result.enabled = enabled;
    if (includeDeleted != null) result.includeDeleted = includeDeleted;
    return result;
  }

  ReqInstList._();

  factory ReqInstList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqInstList()..mergeFromBuffer(data, registry);
  factory ReqInstList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqInstList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqInstList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqInstList.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'scope')
    ..aOS(2, _omitFieldNames ? '' : 'kind')
    ..aOB(3, _omitFieldNames ? '' : 'enabled')
    ..aOB(4, _omitFieldNames ? '' : 'includeDeleted')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqInstList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqInstList copyWith(void Function(ReqInstList) updates) =>
      super.copyWith((message) => updates(message as ReqInstList))
          as ReqInstList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqInstList() / ReqInstList.new instead')
  static ReqInstList create() => ReqInstList._();
  static $pb.GeneratedMessage $_createMessage() => ReqInstList._();
  @$core.override
  ReqInstList createEmptyInstance() => ReqInstList._();
  @$core.pragma('dart2js:noInline')
  static ReqInstList getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqInstList>(
          ReqInstList.$_createMessage);
  static ReqInstList? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get scope => $_getSZ(0);
  @$pb.TagNumber(1)
  set scope($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasScope() => $_has(0);
  @$pb.TagNumber(1)
  void clearScope() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get kind => $_getSZ(1);
  @$pb.TagNumber(2)
  set kind($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasKind() => $_has(1);
  @$pb.TagNumber(2)
  void clearKind() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get enabled => $_getBF(2);
  @$pb.TagNumber(3)
  set enabled($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasEnabled() => $_has(2);
  @$pb.TagNumber(3)
  void clearEnabled() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get includeDeleted => $_getBF(3);
  @$pb.TagNumber(4)
  set includeDeleted($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasIncludeDeleted() => $_has(3);
  @$pb.TagNumber(4)
  void clearIncludeDeleted() => $_clearField(4);
}

class ResInstList extends $pb.GeneratedMessage {
  factory ResInstList({
    $core.Iterable<InstDoc>? items,
  }) {
    final result = ResInstList._();
    if (items != null) result.items.addAll(items);
    return result;
  }

  ResInstList._();

  factory ResInstList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResInstList()..mergeFromBuffer(data, registry);
  factory ResInstList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResInstList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResInstList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResInstList.$_createMessage)
    ..pPM<InstDoc>(1, _omitFieldNames ? '' : 'items',
        subBuilder: InstDoc.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResInstList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResInstList copyWith(void Function(ResInstList) updates) =>
      super.copyWith((message) => updates(message as ResInstList))
          as ResInstList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResInstList() / ResInstList.new instead')
  static ResInstList create() => ResInstList._();
  static $pb.GeneratedMessage $_createMessage() => ResInstList._();
  @$core.override
  ResInstList createEmptyInstance() => ResInstList._();
  @$core.pragma('dart2js:noInline')
  static ResInstList getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResInstList>(
          ResInstList.$_createMessage);
  static ResInstList? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<InstDoc> get items => $_getList(0);
}

class ReqInstGet extends $pb.GeneratedMessage {
  factory ReqInstGet({
    $core.String? id,
  }) {
    final result = ReqInstGet._();
    if (id != null) result.id = id;
    return result;
  }

  ReqInstGet._();

  factory ReqInstGet.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqInstGet()..mergeFromBuffer(data, registry);
  factory ReqInstGet.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqInstGet()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqInstGet',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqInstGet.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqInstGet clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqInstGet copyWith(void Function(ReqInstGet) updates) =>
      super.copyWith((message) => updates(message as ReqInstGet)) as ReqInstGet;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqInstGet() / ReqInstGet.new instead')
  static ReqInstGet create() => ReqInstGet._();
  static $pb.GeneratedMessage $_createMessage() => ReqInstGet._();
  @$core.override
  ReqInstGet createEmptyInstance() => ReqInstGet._();
  @$core.pragma('dart2js:noInline')
  static ReqInstGet getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqInstGet>(ReqInstGet.$_createMessage);
  static ReqInstGet? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);
}

class ResInstGet extends $pb.GeneratedMessage {
  factory ResInstGet({
    InstDoc? item,
  }) {
    final result = ResInstGet._();
    if (item != null) result.item = item;
    return result;
  }

  ResInstGet._();

  factory ResInstGet.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResInstGet()..mergeFromBuffer(data, registry);
  factory ResInstGet.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResInstGet()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResInstGet',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResInstGet.$_createMessage)
    ..aOM<InstDoc>(1, _omitFieldNames ? '' : 'item',
        subBuilder: InstDoc.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResInstGet clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResInstGet copyWith(void Function(ResInstGet) updates) =>
      super.copyWith((message) => updates(message as ResInstGet)) as ResInstGet;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResInstGet() / ResInstGet.new instead')
  static ResInstGet create() => ResInstGet._();
  static $pb.GeneratedMessage $_createMessage() => ResInstGet._();
  @$core.override
  ResInstGet createEmptyInstance() => ResInstGet._();
  @$core.pragma('dart2js:noInline')
  static ResInstGet getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResInstGet>(ResInstGet.$_createMessage);
  static ResInstGet? _defaultInstance;

  @$pb.TagNumber(1)
  InstDoc get item => $_getN(0);
  @$pb.TagNumber(1)
  set item(InstDoc value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasItem() => $_has(0);
  @$pb.TagNumber(1)
  void clearItem() => $_clearField(1);
  @$pb.TagNumber(1)
  InstDoc ensureItem() => $_ensure(0);
}

class ReqInstPut extends $pb.GeneratedMessage {
  factory ReqInstPut({
    InstDoc? doc,
  }) {
    final result = ReqInstPut._();
    if (doc != null) result.doc = doc;
    return result;
  }

  ReqInstPut._();

  factory ReqInstPut.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqInstPut()..mergeFromBuffer(data, registry);
  factory ReqInstPut.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqInstPut()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqInstPut',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqInstPut.$_createMessage)
    ..aOM<InstDoc>(1, _omitFieldNames ? '' : 'doc',
        subBuilder: InstDoc.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqInstPut clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqInstPut copyWith(void Function(ReqInstPut) updates) =>
      super.copyWith((message) => updates(message as ReqInstPut)) as ReqInstPut;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqInstPut() / ReqInstPut.new instead')
  static ReqInstPut create() => ReqInstPut._();
  static $pb.GeneratedMessage $_createMessage() => ReqInstPut._();
  @$core.override
  ReqInstPut createEmptyInstance() => ReqInstPut._();
  @$core.pragma('dart2js:noInline')
  static ReqInstPut getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqInstPut>(ReqInstPut.$_createMessage);
  static ReqInstPut? _defaultInstance;

  @$pb.TagNumber(1)
  InstDoc get doc => $_getN(0);
  @$pb.TagNumber(1)
  set doc(InstDoc value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasDoc() => $_has(0);
  @$pb.TagNumber(1)
  void clearDoc() => $_clearField(1);
  @$pb.TagNumber(1)
  InstDoc ensureDoc() => $_ensure(0);
}

class ResInstPut extends $pb.GeneratedMessage {
  factory ResInstPut({
    InstDoc? doc,
  }) {
    final result = ResInstPut._();
    if (doc != null) result.doc = doc;
    return result;
  }

  ResInstPut._();

  factory ResInstPut.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResInstPut()..mergeFromBuffer(data, registry);
  factory ResInstPut.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResInstPut()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResInstPut',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResInstPut.$_createMessage)
    ..aOM<InstDoc>(1, _omitFieldNames ? '' : 'doc',
        subBuilder: InstDoc.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResInstPut clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResInstPut copyWith(void Function(ResInstPut) updates) =>
      super.copyWith((message) => updates(message as ResInstPut)) as ResInstPut;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResInstPut() / ResInstPut.new instead')
  static ResInstPut create() => ResInstPut._();
  static $pb.GeneratedMessage $_createMessage() => ResInstPut._();
  @$core.override
  ResInstPut createEmptyInstance() => ResInstPut._();
  @$core.pragma('dart2js:noInline')
  static ResInstPut getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResInstPut>(ResInstPut.$_createMessage);
  static ResInstPut? _defaultInstance;

  @$pb.TagNumber(1)
  InstDoc get doc => $_getN(0);
  @$pb.TagNumber(1)
  set doc(InstDoc value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasDoc() => $_has(0);
  @$pb.TagNumber(1)
  void clearDoc() => $_clearField(1);
  @$pb.TagNumber(1)
  InstDoc ensureDoc() => $_ensure(0);
}

class ReqInstDelete extends $pb.GeneratedMessage {
  factory ReqInstDelete({
    $core.String? id,
  }) {
    final result = ReqInstDelete._();
    if (id != null) result.id = id;
    return result;
  }

  ReqInstDelete._();

  factory ReqInstDelete.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqInstDelete()..mergeFromBuffer(data, registry);
  factory ReqInstDelete.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqInstDelete()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqInstDelete',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqInstDelete.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqInstDelete clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqInstDelete copyWith(void Function(ReqInstDelete) updates) =>
      super.copyWith((message) => updates(message as ReqInstDelete))
          as ReqInstDelete;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqInstDelete() / ReqInstDelete.new instead')
  static ReqInstDelete create() => ReqInstDelete._();
  static $pb.GeneratedMessage $_createMessage() => ReqInstDelete._();
  @$core.override
  ReqInstDelete createEmptyInstance() => ReqInstDelete._();
  @$core.pragma('dart2js:noInline')
  static ReqInstDelete getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqInstDelete>(
          ReqInstDelete.$_createMessage);
  static ReqInstDelete? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);
}

class ResInstDelete extends $pb.GeneratedMessage {
  factory ResInstDelete() => ResInstDelete._();

  ResInstDelete._();

  factory ResInstDelete.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResInstDelete()..mergeFromBuffer(data, registry);
  factory ResInstDelete.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResInstDelete()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResInstDelete',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResInstDelete.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResInstDelete clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResInstDelete copyWith(void Function(ResInstDelete) updates) =>
      super.copyWith((message) => updates(message as ResInstDelete))
          as ResInstDelete;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResInstDelete() / ResInstDelete.new instead')
  static ResInstDelete create() => ResInstDelete._();
  static $pb.GeneratedMessage $_createMessage() => ResInstDelete._();
  @$core.override
  ResInstDelete createEmptyInstance() => ResInstDelete._();
  @$core.pragma('dart2js:noInline')
  static ResInstDelete getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResInstDelete>(
          ResInstDelete.$_createMessage);
  static ResInstDelete? _defaultInstance;
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
