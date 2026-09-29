// This is a generated file - do not edit.
//
// Generated from c35/drive.proto.

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

class DriveFileEntry extends $pb.GeneratedMessage {
  factory DriveFileEntry({
    $core.String? path,
    $core.String? hashBlake3,
    $fixnum.Int64? sizeBytes,
  }) {
    final result = DriveFileEntry._();
    if (path != null) result.path = path;
    if (hashBlake3 != null) result.hashBlake3 = hashBlake3;
    if (sizeBytes != null) result.sizeBytes = sizeBytes;
    return result;
  }

  DriveFileEntry._();

  factory DriveFileEntry.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DriveFileEntry()..mergeFromBuffer(data, registry);
  factory DriveFileEntry.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DriveFileEntry()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DriveFileEntry',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: DriveFileEntry.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'path')
    ..aOS(2, _omitFieldNames ? '' : 'hashBlake3')
    ..aInt64(3, _omitFieldNames ? '' : 'sizeBytes')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DriveFileEntry clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DriveFileEntry copyWith(void Function(DriveFileEntry) updates) =>
      super.copyWith((message) => updates(message as DriveFileEntry))
          as DriveFileEntry;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use DriveFileEntry() / DriveFileEntry.new instead')
  static DriveFileEntry create() => DriveFileEntry._();
  static $pb.GeneratedMessage $_createMessage() => DriveFileEntry._();
  @$core.override
  DriveFileEntry createEmptyInstance() => DriveFileEntry._();
  @$core.pragma('dart2js:noInline')
  static DriveFileEntry getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DriveFileEntry>(
          DriveFileEntry.$_createMessage);
  static DriveFileEntry? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get path => $_getSZ(0);
  @$pb.TagNumber(1)
  set path($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearPath() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get hashBlake3 => $_getSZ(1);
  @$pb.TagNumber(2)
  set hashBlake3($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasHashBlake3() => $_has(1);
  @$pb.TagNumber(2)
  void clearHashBlake3() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get sizeBytes => $_getI64(2);
  @$pb.TagNumber(3)
  set sizeBytes($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSizeBytes() => $_has(2);
  @$pb.TagNumber(3)
  void clearSizeBytes() => $_clearField(3);
}

class ReqDriveTree extends $pb.GeneratedMessage {
  factory ReqDriveTree({
    $core.String? pathPrefix,
  }) {
    final result = ReqDriveTree._();
    if (pathPrefix != null) result.pathPrefix = pathPrefix;
    return result;
  }

  ReqDriveTree._();

  factory ReqDriveTree.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqDriveTree()..mergeFromBuffer(data, registry);
  factory ReqDriveTree.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqDriveTree()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqDriveTree',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqDriveTree.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'pathPrefix')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqDriveTree clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqDriveTree copyWith(void Function(ReqDriveTree) updates) =>
      super.copyWith((message) => updates(message as ReqDriveTree))
          as ReqDriveTree;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqDriveTree() / ReqDriveTree.new instead')
  static ReqDriveTree create() => ReqDriveTree._();
  static $pb.GeneratedMessage $_createMessage() => ReqDriveTree._();
  @$core.override
  ReqDriveTree createEmptyInstance() => ReqDriveTree._();
  @$core.pragma('dart2js:noInline')
  static ReqDriveTree getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqDriveTree>(
          ReqDriveTree.$_createMessage);
  static ReqDriveTree? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get pathPrefix => $_getSZ(0);
  @$pb.TagNumber(1)
  set pathPrefix($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPathPrefix() => $_has(0);
  @$pb.TagNumber(1)
  void clearPathPrefix() => $_clearField(1);
}

class ResDriveTree extends $pb.GeneratedMessage {
  factory ResDriveTree({
    $core.Iterable<DriveFileEntry>? files,
  }) {
    final result = ResDriveTree._();
    if (files != null) result.files.addAll(files);
    return result;
  }

  ResDriveTree._();

  factory ResDriveTree.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResDriveTree()..mergeFromBuffer(data, registry);
  factory ResDriveTree.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResDriveTree()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResDriveTree',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResDriveTree.$_createMessage)
    ..pPM<DriveFileEntry>(1, _omitFieldNames ? '' : 'files',
        subBuilder: DriveFileEntry.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResDriveTree clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResDriveTree copyWith(void Function(ResDriveTree) updates) =>
      super.copyWith((message) => updates(message as ResDriveTree))
          as ResDriveTree;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResDriveTree() / ResDriveTree.new instead')
  static ResDriveTree create() => ResDriveTree._();
  static $pb.GeneratedMessage $_createMessage() => ResDriveTree._();
  @$core.override
  ResDriveTree createEmptyInstance() => ResDriveTree._();
  @$core.pragma('dart2js:noInline')
  static ResDriveTree getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResDriveTree>(
          ResDriveTree.$_createMessage);
  static ResDriveTree? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<DriveFileEntry> get files => $_getList(0);
}

class ReqDriveUpload extends $pb.GeneratedMessage {
  factory ReqDriveUpload({
    $core.String? path,
    $core.List<$core.int>? body,
    $core.String? hashBlake3,
  }) {
    final result = ReqDriveUpload._();
    if (path != null) result.path = path;
    if (body != null) result.body = body;
    if (hashBlake3 != null) result.hashBlake3 = hashBlake3;
    return result;
  }

  ReqDriveUpload._();

  factory ReqDriveUpload.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqDriveUpload()..mergeFromBuffer(data, registry);
  factory ReqDriveUpload.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqDriveUpload()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqDriveUpload',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqDriveUpload.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'path')
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'body', $pb.PbFieldType.OY)
    ..aOS(3, _omitFieldNames ? '' : 'hashBlake3')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqDriveUpload clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqDriveUpload copyWith(void Function(ReqDriveUpload) updates) =>
      super.copyWith((message) => updates(message as ReqDriveUpload))
          as ReqDriveUpload;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqDriveUpload() / ReqDriveUpload.new instead')
  static ReqDriveUpload create() => ReqDriveUpload._();
  static $pb.GeneratedMessage $_createMessage() => ReqDriveUpload._();
  @$core.override
  ReqDriveUpload createEmptyInstance() => ReqDriveUpload._();
  @$core.pragma('dart2js:noInline')
  static ReqDriveUpload getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqDriveUpload>(
          ReqDriveUpload.$_createMessage);
  static ReqDriveUpload? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get path => $_getSZ(0);
  @$pb.TagNumber(1)
  set path($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearPath() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get body => $_getN(1);
  @$pb.TagNumber(2)
  set body($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasBody() => $_has(1);
  @$pb.TagNumber(2)
  void clearBody() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get hashBlake3 => $_getSZ(2);
  @$pb.TagNumber(3)
  set hashBlake3($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasHashBlake3() => $_has(2);
  @$pb.TagNumber(3)
  void clearHashBlake3() => $_clearField(3);
}

class ResDriveUpload extends $pb.GeneratedMessage {
  factory ResDriveUpload({
    DriveFileEntry? file,
  }) {
    final result = ResDriveUpload._();
    if (file != null) result.file = file;
    return result;
  }

  ResDriveUpload._();

  factory ResDriveUpload.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResDriveUpload()..mergeFromBuffer(data, registry);
  factory ResDriveUpload.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResDriveUpload()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResDriveUpload',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResDriveUpload.$_createMessage)
    ..aOM<DriveFileEntry>(1, _omitFieldNames ? '' : 'file',
        subBuilder: DriveFileEntry.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResDriveUpload clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResDriveUpload copyWith(void Function(ResDriveUpload) updates) =>
      super.copyWith((message) => updates(message as ResDriveUpload))
          as ResDriveUpload;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResDriveUpload() / ResDriveUpload.new instead')
  static ResDriveUpload create() => ResDriveUpload._();
  static $pb.GeneratedMessage $_createMessage() => ResDriveUpload._();
  @$core.override
  ResDriveUpload createEmptyInstance() => ResDriveUpload._();
  @$core.pragma('dart2js:noInline')
  static ResDriveUpload getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResDriveUpload>(
          ResDriveUpload.$_createMessage);
  static ResDriveUpload? _defaultInstance;

  @$pb.TagNumber(1)
  DriveFileEntry get file => $_getN(0);
  @$pb.TagNumber(1)
  set file(DriveFileEntry value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasFile() => $_has(0);
  @$pb.TagNumber(1)
  void clearFile() => $_clearField(1);
  @$pb.TagNumber(1)
  DriveFileEntry ensureFile() => $_ensure(0);
}

class ReqDriveDelete extends $pb.GeneratedMessage {
  factory ReqDriveDelete({
    $core.String? path,
  }) {
    final result = ReqDriveDelete._();
    if (path != null) result.path = path;
    return result;
  }

  ReqDriveDelete._();

  factory ReqDriveDelete.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqDriveDelete()..mergeFromBuffer(data, registry);
  factory ReqDriveDelete.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqDriveDelete()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqDriveDelete',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqDriveDelete.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'path')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqDriveDelete clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqDriveDelete copyWith(void Function(ReqDriveDelete) updates) =>
      super.copyWith((message) => updates(message as ReqDriveDelete))
          as ReqDriveDelete;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqDriveDelete() / ReqDriveDelete.new instead')
  static ReqDriveDelete create() => ReqDriveDelete._();
  static $pb.GeneratedMessage $_createMessage() => ReqDriveDelete._();
  @$core.override
  ReqDriveDelete createEmptyInstance() => ReqDriveDelete._();
  @$core.pragma('dart2js:noInline')
  static ReqDriveDelete getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqDriveDelete>(
          ReqDriveDelete.$_createMessage);
  static ReqDriveDelete? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get path => $_getSZ(0);
  @$pb.TagNumber(1)
  set path($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearPath() => $_clearField(1);
}

class ResDriveDelete extends $pb.GeneratedMessage {
  factory ResDriveDelete({
    $core.bool? ok,
  }) {
    final result = ResDriveDelete._();
    if (ok != null) result.ok = ok;
    return result;
  }

  ResDriveDelete._();

  factory ResDriveDelete.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResDriveDelete()..mergeFromBuffer(data, registry);
  factory ResDriveDelete.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResDriveDelete()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResDriveDelete',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResDriveDelete.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'ok')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResDriveDelete clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResDriveDelete copyWith(void Function(ResDriveDelete) updates) =>
      super.copyWith((message) => updates(message as ResDriveDelete))
          as ResDriveDelete;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResDriveDelete() / ResDriveDelete.new instead')
  static ResDriveDelete create() => ResDriveDelete._();
  static $pb.GeneratedMessage $_createMessage() => ResDriveDelete._();
  @$core.override
  ResDriveDelete createEmptyInstance() => ResDriveDelete._();
  @$core.pragma('dart2js:noInline')
  static ResDriveDelete getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResDriveDelete>(
          ResDriveDelete.$_createMessage);
  static ResDriveDelete? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get ok => $_getBF(0);
  @$pb.TagNumber(1)
  set ok($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOk() => $_has(0);
  @$pb.TagNumber(1)
  void clearOk() => $_clearField(1);
}

class ResDriveStorage extends $pb.GeneratedMessage {
  factory ResDriveStorage({
    $fixnum.Int64? storageUsedBytes,
    $fixnum.Int64? storageLimitBytes,
  }) {
    final result = ResDriveStorage._();
    if (storageUsedBytes != null) result.storageUsedBytes = storageUsedBytes;
    if (storageLimitBytes != null) result.storageLimitBytes = storageLimitBytes;
    return result;
  }

  ResDriveStorage._();

  factory ResDriveStorage.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResDriveStorage()..mergeFromBuffer(data, registry);
  factory ResDriveStorage.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResDriveStorage()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResDriveStorage',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResDriveStorage.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'storageUsedBytes')
    ..aInt64(2, _omitFieldNames ? '' : 'storageLimitBytes')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResDriveStorage clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResDriveStorage copyWith(void Function(ResDriveStorage) updates) =>
      super.copyWith((message) => updates(message as ResDriveStorage))
          as ResDriveStorage;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResDriveStorage() / ResDriveStorage.new instead')
  static ResDriveStorage create() => ResDriveStorage._();
  static $pb.GeneratedMessage $_createMessage() => ResDriveStorage._();
  @$core.override
  ResDriveStorage createEmptyInstance() => ResDriveStorage._();
  @$core.pragma('dart2js:noInline')
  static ResDriveStorage getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResDriveStorage>(
          ResDriveStorage.$_createMessage);
  static ResDriveStorage? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get storageUsedBytes => $_getI64(0);
  @$pb.TagNumber(1)
  set storageUsedBytes($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasStorageUsedBytes() => $_has(0);
  @$pb.TagNumber(1)
  void clearStorageUsedBytes() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get storageLimitBytes => $_getI64(1);
  @$pb.TagNumber(2)
  set storageLimitBytes($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasStorageLimitBytes() => $_has(1);
  @$pb.TagNumber(2)
  void clearStorageLimitBytes() => $_clearField(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
