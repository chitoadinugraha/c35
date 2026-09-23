// This is a generated file - do not edit.
//
// Generated from c35/object.proto.

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

class ObjectNormalizerDoc extends $pb.GeneratedMessage {
  factory ObjectNormalizerDoc({
    $fixnum.Int64? id,
    $core.String? slug,
    $fixnum.Int64? parentId,
    $core.String? path,
    $core.int? depth,
    $core.String? kind,
  }) {
    final result = ObjectNormalizerDoc._();
    if (id != null) result.id = id;
    if (slug != null) result.slug = slug;
    if (parentId != null) result.parentId = parentId;
    if (path != null) result.path = path;
    if (depth != null) result.depth = depth;
    if (kind != null) result.kind = kind;
    return result;
  }

  ObjectNormalizerDoc._();

  factory ObjectNormalizerDoc.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ObjectNormalizerDoc()..mergeFromBuffer(data, registry);
  factory ObjectNormalizerDoc.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ObjectNormalizerDoc()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ObjectNormalizerDoc',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ObjectNormalizerDoc.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'slug')
    ..aInt64(3, _omitFieldNames ? '' : 'parentId')
    ..aOS(4, _omitFieldNames ? '' : 'path')
    ..aI(5, _omitFieldNames ? '' : 'depth')
    ..aOS(6, _omitFieldNames ? '' : 'kind')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ObjectNormalizerDoc clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ObjectNormalizerDoc copyWith(void Function(ObjectNormalizerDoc) updates) =>
      super.copyWith((message) => updates(message as ObjectNormalizerDoc))
          as ObjectNormalizerDoc;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use ObjectNormalizerDoc() / ObjectNormalizerDoc.new instead')
  static ObjectNormalizerDoc create() => ObjectNormalizerDoc._();
  static $pb.GeneratedMessage $_createMessage() => ObjectNormalizerDoc._();
  @$core.override
  ObjectNormalizerDoc createEmptyInstance() => ObjectNormalizerDoc._();
  @$core.pragma('dart2js:noInline')
  static ObjectNormalizerDoc getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ObjectNormalizerDoc>(
          ObjectNormalizerDoc.$_createMessage);
  static ObjectNormalizerDoc? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get slug => $_getSZ(1);
  @$pb.TagNumber(2)
  set slug($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSlug() => $_has(1);
  @$pb.TagNumber(2)
  void clearSlug() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get parentId => $_getI64(2);
  @$pb.TagNumber(3)
  set parentId($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasParentId() => $_has(2);
  @$pb.TagNumber(3)
  void clearParentId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get path => $_getSZ(3);
  @$pb.TagNumber(4)
  set path($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPath() => $_has(3);
  @$pb.TagNumber(4)
  void clearPath() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get depth => $_getIZ(4);
  @$pb.TagNumber(5)
  set depth($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasDepth() => $_has(4);
  @$pb.TagNumber(5)
  void clearDepth() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get kind => $_getSZ(5);
  @$pb.TagNumber(6)
  set kind($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasKind() => $_has(5);
  @$pb.TagNumber(6)
  void clearKind() => $_clearField(6);
}

class ObjectAliasDoc extends $pb.GeneratedMessage {
  factory ObjectAliasDoc({
    $fixnum.Int64? id,
    $fixnum.Int64? objId,
    $core.String? lang,
    $core.String? name,
    $core.String? nameNorm,
    $core.bool? isCanonical,
    $core.bool? verified,
    $core.String? objPath,
  }) {
    final result = ObjectAliasDoc._();
    if (id != null) result.id = id;
    if (objId != null) result.objId = objId;
    if (lang != null) result.lang = lang;
    if (name != null) result.name = name;
    if (nameNorm != null) result.nameNorm = nameNorm;
    if (isCanonical != null) result.isCanonical = isCanonical;
    if (verified != null) result.verified = verified;
    if (objPath != null) result.objPath = objPath;
    return result;
  }

  ObjectAliasDoc._();

  factory ObjectAliasDoc.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ObjectAliasDoc()..mergeFromBuffer(data, registry);
  factory ObjectAliasDoc.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ObjectAliasDoc()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ObjectAliasDoc',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ObjectAliasDoc.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..aInt64(2, _omitFieldNames ? '' : 'objId')
    ..aOS(3, _omitFieldNames ? '' : 'lang')
    ..aOS(4, _omitFieldNames ? '' : 'name')
    ..aOS(5, _omitFieldNames ? '' : 'nameNorm')
    ..aOB(6, _omitFieldNames ? '' : 'isCanonical')
    ..aOB(7, _omitFieldNames ? '' : 'verified')
    ..aOS(8, _omitFieldNames ? '' : 'objPath')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ObjectAliasDoc clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ObjectAliasDoc copyWith(void Function(ObjectAliasDoc) updates) =>
      super.copyWith((message) => updates(message as ObjectAliasDoc))
          as ObjectAliasDoc;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ObjectAliasDoc() / ObjectAliasDoc.new instead')
  static ObjectAliasDoc create() => ObjectAliasDoc._();
  static $pb.GeneratedMessage $_createMessage() => ObjectAliasDoc._();
  @$core.override
  ObjectAliasDoc createEmptyInstance() => ObjectAliasDoc._();
  @$core.pragma('dart2js:noInline')
  static ObjectAliasDoc getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ObjectAliasDoc>(
          ObjectAliasDoc.$_createMessage);
  static ObjectAliasDoc? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get objId => $_getI64(1);
  @$pb.TagNumber(2)
  set objId($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasObjId() => $_has(1);
  @$pb.TagNumber(2)
  void clearObjId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get lang => $_getSZ(2);
  @$pb.TagNumber(3)
  set lang($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLang() => $_has(2);
  @$pb.TagNumber(3)
  void clearLang() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get name => $_getSZ(3);
  @$pb.TagNumber(4)
  set name($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasName() => $_has(3);
  @$pb.TagNumber(4)
  void clearName() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get nameNorm => $_getSZ(4);
  @$pb.TagNumber(5)
  set nameNorm($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasNameNorm() => $_has(4);
  @$pb.TagNumber(5)
  void clearNameNorm() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get isCanonical => $_getBF(5);
  @$pb.TagNumber(6)
  set isCanonical($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasIsCanonical() => $_has(5);
  @$pb.TagNumber(6)
  void clearIsCanonical() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.bool get verified => $_getBF(6);
  @$pb.TagNumber(7)
  set verified($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasVerified() => $_has(6);
  @$pb.TagNumber(7)
  void clearVerified() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get objPath => $_getSZ(7);
  @$pb.TagNumber(8)
  set objPath($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasObjPath() => $_has(7);
  @$pb.TagNumber(8)
  void clearObjPath() => $_clearField(8);
}

class ReqObjectAliasList extends $pb.GeneratedMessage {
  factory ReqObjectAliasList({
    $core.bool? verified,
    $core.String? lang,
    $core.String? q,
    $core.int? limit,
  }) {
    final result = ReqObjectAliasList._();
    if (verified != null) result.verified = verified;
    if (lang != null) result.lang = lang;
    if (q != null) result.q = q;
    if (limit != null) result.limit = limit;
    return result;
  }

  ReqObjectAliasList._();

  factory ReqObjectAliasList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqObjectAliasList()..mergeFromBuffer(data, registry);
  factory ReqObjectAliasList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqObjectAliasList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqObjectAliasList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqObjectAliasList.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'verified')
    ..aOS(2, _omitFieldNames ? '' : 'lang')
    ..aOS(3, _omitFieldNames ? '' : 'q')
    ..aI(4, _omitFieldNames ? '' : 'limit')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqObjectAliasList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqObjectAliasList copyWith(void Function(ReqObjectAliasList) updates) =>
      super.copyWith((message) => updates(message as ReqObjectAliasList))
          as ReqObjectAliasList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqObjectAliasList() / ReqObjectAliasList.new instead')
  static ReqObjectAliasList create() => ReqObjectAliasList._();
  static $pb.GeneratedMessage $_createMessage() => ReqObjectAliasList._();
  @$core.override
  ReqObjectAliasList createEmptyInstance() => ReqObjectAliasList._();
  @$core.pragma('dart2js:noInline')
  static ReqObjectAliasList getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqObjectAliasList>(
          ReqObjectAliasList.$_createMessage);
  static ReqObjectAliasList? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get verified => $_getBF(0);
  @$pb.TagNumber(1)
  set verified($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasVerified() => $_has(0);
  @$pb.TagNumber(1)
  void clearVerified() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get lang => $_getSZ(1);
  @$pb.TagNumber(2)
  set lang($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLang() => $_has(1);
  @$pb.TagNumber(2)
  void clearLang() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get q => $_getSZ(2);
  @$pb.TagNumber(3)
  set q($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasQ() => $_has(2);
  @$pb.TagNumber(3)
  void clearQ() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get limit => $_getIZ(3);
  @$pb.TagNumber(4)
  set limit($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasLimit() => $_has(3);
  @$pb.TagNumber(4)
  void clearLimit() => $_clearField(4);
}

class ResObjectAliasList extends $pb.GeneratedMessage {
  factory ResObjectAliasList({
    $core.Iterable<ObjectAliasDoc>? items,
  }) {
    final result = ResObjectAliasList._();
    if (items != null) result.items.addAll(items);
    return result;
  }

  ResObjectAliasList._();

  factory ResObjectAliasList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResObjectAliasList()..mergeFromBuffer(data, registry);
  factory ResObjectAliasList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResObjectAliasList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResObjectAliasList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResObjectAliasList.$_createMessage)
    ..pPM<ObjectAliasDoc>(1, _omitFieldNames ? '' : 'items',
        subBuilder: ObjectAliasDoc.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResObjectAliasList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResObjectAliasList copyWith(void Function(ResObjectAliasList) updates) =>
      super.copyWith((message) => updates(message as ResObjectAliasList))
          as ResObjectAliasList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResObjectAliasList() / ResObjectAliasList.new instead')
  static ResObjectAliasList create() => ResObjectAliasList._();
  static $pb.GeneratedMessage $_createMessage() => ResObjectAliasList._();
  @$core.override
  ResObjectAliasList createEmptyInstance() => ResObjectAliasList._();
  @$core.pragma('dart2js:noInline')
  static ResObjectAliasList getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResObjectAliasList>(
          ResObjectAliasList.$_createMessage);
  static ResObjectAliasList? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<ObjectAliasDoc> get items => $_getList(0);
}

class ReqObjectAliasPut extends $pb.GeneratedMessage {
  factory ReqObjectAliasPut({
    ObjectAliasDoc? doc,
  }) {
    final result = ReqObjectAliasPut._();
    if (doc != null) result.doc = doc;
    return result;
  }

  ReqObjectAliasPut._();

  factory ReqObjectAliasPut.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqObjectAliasPut()..mergeFromBuffer(data, registry);
  factory ReqObjectAliasPut.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqObjectAliasPut()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqObjectAliasPut',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqObjectAliasPut.$_createMessage)
    ..aOM<ObjectAliasDoc>(1, _omitFieldNames ? '' : 'doc',
        subBuilder: ObjectAliasDoc.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqObjectAliasPut clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqObjectAliasPut copyWith(void Function(ReqObjectAliasPut) updates) =>
      super.copyWith((message) => updates(message as ReqObjectAliasPut))
          as ReqObjectAliasPut;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqObjectAliasPut() / ReqObjectAliasPut.new instead')
  static ReqObjectAliasPut create() => ReqObjectAliasPut._();
  static $pb.GeneratedMessage $_createMessage() => ReqObjectAliasPut._();
  @$core.override
  ReqObjectAliasPut createEmptyInstance() => ReqObjectAliasPut._();
  @$core.pragma('dart2js:noInline')
  static ReqObjectAliasPut getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqObjectAliasPut>(
          ReqObjectAliasPut.$_createMessage);
  static ReqObjectAliasPut? _defaultInstance;

  @$pb.TagNumber(1)
  ObjectAliasDoc get doc => $_getN(0);
  @$pb.TagNumber(1)
  set doc(ObjectAliasDoc value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasDoc() => $_has(0);
  @$pb.TagNumber(1)
  void clearDoc() => $_clearField(1);
  @$pb.TagNumber(1)
  ObjectAliasDoc ensureDoc() => $_ensure(0);
}

class ResObjectAliasPut extends $pb.GeneratedMessage {
  factory ResObjectAliasPut({
    ObjectAliasDoc? doc,
  }) {
    final result = ResObjectAliasPut._();
    if (doc != null) result.doc = doc;
    return result;
  }

  ResObjectAliasPut._();

  factory ResObjectAliasPut.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResObjectAliasPut()..mergeFromBuffer(data, registry);
  factory ResObjectAliasPut.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResObjectAliasPut()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResObjectAliasPut',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResObjectAliasPut.$_createMessage)
    ..aOM<ObjectAliasDoc>(1, _omitFieldNames ? '' : 'doc',
        subBuilder: ObjectAliasDoc.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResObjectAliasPut clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResObjectAliasPut copyWith(void Function(ResObjectAliasPut) updates) =>
      super.copyWith((message) => updates(message as ResObjectAliasPut))
          as ResObjectAliasPut;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResObjectAliasPut() / ResObjectAliasPut.new instead')
  static ResObjectAliasPut create() => ResObjectAliasPut._();
  static $pb.GeneratedMessage $_createMessage() => ResObjectAliasPut._();
  @$core.override
  ResObjectAliasPut createEmptyInstance() => ResObjectAliasPut._();
  @$core.pragma('dart2js:noInline')
  static ResObjectAliasPut getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResObjectAliasPut>(
          ResObjectAliasPut.$_createMessage);
  static ResObjectAliasPut? _defaultInstance;

  @$pb.TagNumber(1)
  ObjectAliasDoc get doc => $_getN(0);
  @$pb.TagNumber(1)
  set doc(ObjectAliasDoc value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasDoc() => $_has(0);
  @$pb.TagNumber(1)
  void clearDoc() => $_clearField(1);
  @$pb.TagNumber(1)
  ObjectAliasDoc ensureDoc() => $_ensure(0);
}

class ReqObjectNormalizerList extends $pb.GeneratedMessage {
  factory ReqObjectNormalizerList({
    $core.String? q,
    $core.int? limit,
  }) {
    final result = ReqObjectNormalizerList._();
    if (q != null) result.q = q;
    if (limit != null) result.limit = limit;
    return result;
  }

  ReqObjectNormalizerList._();

  factory ReqObjectNormalizerList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqObjectNormalizerList()..mergeFromBuffer(data, registry);
  factory ReqObjectNormalizerList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqObjectNormalizerList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqObjectNormalizerList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqObjectNormalizerList.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'q')
    ..aI(2, _omitFieldNames ? '' : 'limit')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqObjectNormalizerList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqObjectNormalizerList copyWith(
          void Function(ReqObjectNormalizerList) updates) =>
      super.copyWith((message) => updates(message as ReqObjectNormalizerList))
          as ReqObjectNormalizerList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ReqObjectNormalizerList() / ReqObjectNormalizerList.new instead')
  static ReqObjectNormalizerList create() => ReqObjectNormalizerList._();
  static $pb.GeneratedMessage $_createMessage() => ReqObjectNormalizerList._();
  @$core.override
  ReqObjectNormalizerList createEmptyInstance() => ReqObjectNormalizerList._();
  @$core.pragma('dart2js:noInline')
  static ReqObjectNormalizerList getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqObjectNormalizerList>(
          ReqObjectNormalizerList.$_createMessage);
  static ReqObjectNormalizerList? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get q => $_getSZ(0);
  @$pb.TagNumber(1)
  set q($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasQ() => $_has(0);
  @$pb.TagNumber(1)
  void clearQ() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get limit => $_getIZ(1);
  @$pb.TagNumber(2)
  set limit($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLimit() => $_has(1);
  @$pb.TagNumber(2)
  void clearLimit() => $_clearField(2);
}

class ResObjectNormalizerList extends $pb.GeneratedMessage {
  factory ResObjectNormalizerList({
    $core.Iterable<ObjectNormalizerDoc>? items,
  }) {
    final result = ResObjectNormalizerList._();
    if (items != null) result.items.addAll(items);
    return result;
  }

  ResObjectNormalizerList._();

  factory ResObjectNormalizerList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResObjectNormalizerList()..mergeFromBuffer(data, registry);
  factory ResObjectNormalizerList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResObjectNormalizerList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResObjectNormalizerList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResObjectNormalizerList.$_createMessage)
    ..pPM<ObjectNormalizerDoc>(1, _omitFieldNames ? '' : 'items',
        subBuilder: ObjectNormalizerDoc.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResObjectNormalizerList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResObjectNormalizerList copyWith(
          void Function(ResObjectNormalizerList) updates) =>
      super.copyWith((message) => updates(message as ResObjectNormalizerList))
          as ResObjectNormalizerList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ResObjectNormalizerList() / ResObjectNormalizerList.new instead')
  static ResObjectNormalizerList create() => ResObjectNormalizerList._();
  static $pb.GeneratedMessage $_createMessage() => ResObjectNormalizerList._();
  @$core.override
  ResObjectNormalizerList createEmptyInstance() => ResObjectNormalizerList._();
  @$core.pragma('dart2js:noInline')
  static ResObjectNormalizerList getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResObjectNormalizerList>(
          ResObjectNormalizerList.$_createMessage);
  static ResObjectNormalizerList? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<ObjectNormalizerDoc> get items => $_getList(0);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
