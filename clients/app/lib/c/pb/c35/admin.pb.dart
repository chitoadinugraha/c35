// This is a generated file - do not edit.
//
// Generated from c35/admin.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'log.pb.dart' as $0;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class AdminUserHit extends $pb.GeneratedMessage {
  factory AdminUserHit({
    $fixnum.Int64? identityId,
    $core.String? name,
    $core.String? email,
    $core.String? avatarUrl,
    $core.String? handle,
  }) {
    final result = AdminUserHit._();
    if (identityId != null) result.identityId = identityId;
    if (name != null) result.name = name;
    if (email != null) result.email = email;
    if (avatarUrl != null) result.avatarUrl = avatarUrl;
    if (handle != null) result.handle = handle;
    return result;
  }

  AdminUserHit._();

  factory AdminUserHit.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AdminUserHit()..mergeFromBuffer(data, registry);
  factory AdminUserHit.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AdminUserHit()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AdminUserHit',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: AdminUserHit.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'identityId')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOS(3, _omitFieldNames ? '' : 'email')
    ..aOS(4, _omitFieldNames ? '' : 'avatarUrl')
    ..aOS(5, _omitFieldNames ? '' : 'handle')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AdminUserHit clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AdminUserHit copyWith(void Function(AdminUserHit) updates) =>
      super.copyWith((message) => updates(message as AdminUserHit))
          as AdminUserHit;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use AdminUserHit() / AdminUserHit.new instead')
  static AdminUserHit create() => AdminUserHit._();
  static $pb.GeneratedMessage $_createMessage() => AdminUserHit._();
  @$core.override
  AdminUserHit createEmptyInstance() => AdminUserHit._();
  @$core.pragma('dart2js:noInline')
  static AdminUserHit getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AdminUserHit>(
          AdminUserHit.$_createMessage);
  static AdminUserHit? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get identityId => $_getI64(0);
  @$pb.TagNumber(1)
  set identityId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIdentityId() => $_has(0);
  @$pb.TagNumber(1)
  void clearIdentityId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get email => $_getSZ(2);
  @$pb.TagNumber(3)
  set email($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasEmail() => $_has(2);
  @$pb.TagNumber(3)
  void clearEmail() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get avatarUrl => $_getSZ(3);
  @$pb.TagNumber(4)
  set avatarUrl($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAvatarUrl() => $_has(3);
  @$pb.TagNumber(4)
  void clearAvatarUrl() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get handle => $_getSZ(4);
  @$pb.TagNumber(5)
  set handle($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasHandle() => $_has(4);
  @$pb.TagNumber(5)
  void clearHandle() => $_clearField(5);
}

class ReqAdminUserSearch extends $pb.GeneratedMessage {
  factory ReqAdminUserSearch({
    $core.String? query,
    $core.int? limit,
  }) {
    final result = ReqAdminUserSearch._();
    if (query != null) result.query = query;
    if (limit != null) result.limit = limit;
    return result;
  }

  ReqAdminUserSearch._();

  factory ReqAdminUserSearch.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqAdminUserSearch()..mergeFromBuffer(data, registry);
  factory ReqAdminUserSearch.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqAdminUserSearch()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqAdminUserSearch',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqAdminUserSearch.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'query')
    ..aI(2, _omitFieldNames ? '' : 'limit')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqAdminUserSearch clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqAdminUserSearch copyWith(void Function(ReqAdminUserSearch) updates) =>
      super.copyWith((message) => updates(message as ReqAdminUserSearch))
          as ReqAdminUserSearch;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqAdminUserSearch() / ReqAdminUserSearch.new instead')
  static ReqAdminUserSearch create() => ReqAdminUserSearch._();
  static $pb.GeneratedMessage $_createMessage() => ReqAdminUserSearch._();
  @$core.override
  ReqAdminUserSearch createEmptyInstance() => ReqAdminUserSearch._();
  @$core.pragma('dart2js:noInline')
  static ReqAdminUserSearch getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqAdminUserSearch>(
          ReqAdminUserSearch.$_createMessage);
  static ReqAdminUserSearch? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get query => $_getSZ(0);
  @$pb.TagNumber(1)
  set query($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasQuery() => $_has(0);
  @$pb.TagNumber(1)
  void clearQuery() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get limit => $_getIZ(1);
  @$pb.TagNumber(2)
  set limit($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLimit() => $_has(1);
  @$pb.TagNumber(2)
  void clearLimit() => $_clearField(2);
}

class ResAdminUserSearch extends $pb.GeneratedMessage {
  factory ResAdminUserSearch({
    $core.Iterable<AdminUserHit>? users,
  }) {
    final result = ResAdminUserSearch._();
    if (users != null) result.users.addAll(users);
    return result;
  }

  ResAdminUserSearch._();

  factory ResAdminUserSearch.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResAdminUserSearch()..mergeFromBuffer(data, registry);
  factory ResAdminUserSearch.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResAdminUserSearch()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResAdminUserSearch',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResAdminUserSearch.$_createMessage)
    ..pPM<AdminUserHit>(1, _omitFieldNames ? '' : 'users',
        subBuilder: AdminUserHit.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResAdminUserSearch clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResAdminUserSearch copyWith(void Function(ResAdminUserSearch) updates) =>
      super.copyWith((message) => updates(message as ResAdminUserSearch))
          as ResAdminUserSearch;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResAdminUserSearch() / ResAdminUserSearch.new instead')
  static ResAdminUserSearch create() => ResAdminUserSearch._();
  static $pb.GeneratedMessage $_createMessage() => ResAdminUserSearch._();
  @$core.override
  ResAdminUserSearch createEmptyInstance() => ResAdminUserSearch._();
  @$core.pragma('dart2js:noInline')
  static ResAdminUserSearch getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResAdminUserSearch>(
          ResAdminUserSearch.$_createMessage);
  static ResAdminUserSearch? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<AdminUserHit> get users => $_getList(0);
}

class ReqAdminUserPut extends $pb.GeneratedMessage {
  factory ReqAdminUserPut({
    $fixnum.Int64? targetIdentityId,
    $core.String? name,
    $core.String? avatarUrl,
    $fixnum.Int64? referredByUid,
    $core.String? handle,
    $core.String? authEmail,
  }) {
    final result = ReqAdminUserPut._();
    if (targetIdentityId != null) result.targetIdentityId = targetIdentityId;
    if (name != null) result.name = name;
    if (avatarUrl != null) result.avatarUrl = avatarUrl;
    if (referredByUid != null) result.referredByUid = referredByUid;
    if (handle != null) result.handle = handle;
    if (authEmail != null) result.authEmail = authEmail;
    return result;
  }

  ReqAdminUserPut._();

  factory ReqAdminUserPut.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqAdminUserPut()..mergeFromBuffer(data, registry);
  factory ReqAdminUserPut.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqAdminUserPut()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqAdminUserPut',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqAdminUserPut.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'targetIdentityId')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOS(3, _omitFieldNames ? '' : 'avatarUrl')
    ..aInt64(4, _omitFieldNames ? '' : 'referredByUid')
    ..aOS(5, _omitFieldNames ? '' : 'handle')
    ..aOS(6, _omitFieldNames ? '' : 'authEmail')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqAdminUserPut clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqAdminUserPut copyWith(void Function(ReqAdminUserPut) updates) =>
      super.copyWith((message) => updates(message as ReqAdminUserPut))
          as ReqAdminUserPut;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqAdminUserPut() / ReqAdminUserPut.new instead')
  static ReqAdminUserPut create() => ReqAdminUserPut._();
  static $pb.GeneratedMessage $_createMessage() => ReqAdminUserPut._();
  @$core.override
  ReqAdminUserPut createEmptyInstance() => ReqAdminUserPut._();
  @$core.pragma('dart2js:noInline')
  static ReqAdminUserPut getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqAdminUserPut>(
          ReqAdminUserPut.$_createMessage);
  static ReqAdminUserPut? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get targetIdentityId => $_getI64(0);
  @$pb.TagNumber(1)
  set targetIdentityId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTargetIdentityId() => $_has(0);
  @$pb.TagNumber(1)
  void clearTargetIdentityId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get avatarUrl => $_getSZ(2);
  @$pb.TagNumber(3)
  set avatarUrl($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAvatarUrl() => $_has(2);
  @$pb.TagNumber(3)
  void clearAvatarUrl() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get referredByUid => $_getI64(3);
  @$pb.TagNumber(4)
  set referredByUid($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasReferredByUid() => $_has(3);
  @$pb.TagNumber(4)
  void clearReferredByUid() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get handle => $_getSZ(4);
  @$pb.TagNumber(5)
  set handle($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasHandle() => $_has(4);
  @$pb.TagNumber(5)
  void clearHandle() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get authEmail => $_getSZ(5);
  @$pb.TagNumber(6)
  set authEmail($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasAuthEmail() => $_has(5);
  @$pb.TagNumber(6)
  void clearAuthEmail() => $_clearField(6);
}

class ResAdminUserPut extends $pb.GeneratedMessage {
  factory ResAdminUserPut() => ResAdminUserPut._();

  ResAdminUserPut._();

  factory ResAdminUserPut.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResAdminUserPut()..mergeFromBuffer(data, registry);
  factory ResAdminUserPut.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResAdminUserPut()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResAdminUserPut',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResAdminUserPut.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResAdminUserPut clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResAdminUserPut copyWith(void Function(ResAdminUserPut) updates) =>
      super.copyWith((message) => updates(message as ResAdminUserPut))
          as ResAdminUserPut;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResAdminUserPut() / ResAdminUserPut.new instead')
  static ResAdminUserPut create() => ResAdminUserPut._();
  static $pb.GeneratedMessage $_createMessage() => ResAdminUserPut._();
  @$core.override
  ResAdminUserPut createEmptyInstance() => ResAdminUserPut._();
  @$core.pragma('dart2js:noInline')
  static ResAdminUserPut getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResAdminUserPut>(
          ResAdminUserPut.$_createMessage);
  static ResAdminUserPut? _defaultInstance;
}

class ReqAdminLogList extends $pb.GeneratedMessage {
  factory ReqAdminLogList({
    $fixnum.Int64? ownerIid,
    $fixnum.Int64? sinceMs,
    $fixnum.Int64? untilMs,
    $core.String? text,
    $core.String? kind,
    $core.String? topic,
    $core.int? limit,
    $fixnum.Int64? beforeId,
    $core.String? eventKind,
    $core.String? class_10,
    $core.String? subjectPrefix,
    $core.bool? excludeTrace,
  }) {
    final result = ReqAdminLogList._();
    if (ownerIid != null) result.ownerIid = ownerIid;
    if (sinceMs != null) result.sinceMs = sinceMs;
    if (untilMs != null) result.untilMs = untilMs;
    if (text != null) result.text = text;
    if (kind != null) result.kind = kind;
    if (topic != null) result.topic = topic;
    if (limit != null) result.limit = limit;
    if (beforeId != null) result.beforeId = beforeId;
    if (eventKind != null) result.eventKind = eventKind;
    if (class_10 != null) result.class_10 = class_10;
    if (subjectPrefix != null) result.subjectPrefix = subjectPrefix;
    if (excludeTrace != null) result.excludeTrace = excludeTrace;
    return result;
  }

  ReqAdminLogList._();

  factory ReqAdminLogList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqAdminLogList()..mergeFromBuffer(data, registry);
  factory ReqAdminLogList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqAdminLogList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqAdminLogList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqAdminLogList.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'ownerIid')
    ..aInt64(2, _omitFieldNames ? '' : 'sinceMs')
    ..aInt64(3, _omitFieldNames ? '' : 'untilMs')
    ..aOS(4, _omitFieldNames ? '' : 'text')
    ..aOS(5, _omitFieldNames ? '' : 'kind')
    ..aOS(6, _omitFieldNames ? '' : 'topic')
    ..aI(7, _omitFieldNames ? '' : 'limit')
    ..aInt64(8, _omitFieldNames ? '' : 'beforeId')
    ..aOS(9, _omitFieldNames ? '' : 'eventKind')
    ..aOS(10, _omitFieldNames ? '' : 'class')
    ..aOS(11, _omitFieldNames ? '' : 'subjectPrefix')
    ..aOB(12, _omitFieldNames ? '' : 'excludeTrace')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqAdminLogList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqAdminLogList copyWith(void Function(ReqAdminLogList) updates) =>
      super.copyWith((message) => updates(message as ReqAdminLogList))
          as ReqAdminLogList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqAdminLogList() / ReqAdminLogList.new instead')
  static ReqAdminLogList create() => ReqAdminLogList._();
  static $pb.GeneratedMessage $_createMessage() => ReqAdminLogList._();
  @$core.override
  ReqAdminLogList createEmptyInstance() => ReqAdminLogList._();
  @$core.pragma('dart2js:noInline')
  static ReqAdminLogList getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqAdminLogList>(
          ReqAdminLogList.$_createMessage);
  static ReqAdminLogList? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get ownerIid => $_getI64(0);
  @$pb.TagNumber(1)
  set ownerIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOwnerIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearOwnerIid() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get sinceMs => $_getI64(1);
  @$pb.TagNumber(2)
  set sinceMs($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSinceMs() => $_has(1);
  @$pb.TagNumber(2)
  void clearSinceMs() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get untilMs => $_getI64(2);
  @$pb.TagNumber(3)
  set untilMs($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasUntilMs() => $_has(2);
  @$pb.TagNumber(3)
  void clearUntilMs() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get text => $_getSZ(3);
  @$pb.TagNumber(4)
  set text($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasText() => $_has(3);
  @$pb.TagNumber(4)
  void clearText() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get kind => $_getSZ(4);
  @$pb.TagNumber(5)
  set kind($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasKind() => $_has(4);
  @$pb.TagNumber(5)
  void clearKind() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get topic => $_getSZ(5);
  @$pb.TagNumber(6)
  set topic($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasTopic() => $_has(5);
  @$pb.TagNumber(6)
  void clearTopic() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.int get limit => $_getIZ(6);
  @$pb.TagNumber(7)
  set limit($core.int value) => $_setSignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasLimit() => $_has(6);
  @$pb.TagNumber(7)
  void clearLimit() => $_clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get beforeId => $_getI64(7);
  @$pb.TagNumber(8)
  set beforeId($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(8)
  $core.bool hasBeforeId() => $_has(7);
  @$pb.TagNumber(8)
  void clearBeforeId() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get eventKind => $_getSZ(8);
  @$pb.TagNumber(9)
  set eventKind($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasEventKind() => $_has(8);
  @$pb.TagNumber(9)
  void clearEventKind() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.String get class_10 => $_getSZ(9);
  @$pb.TagNumber(10)
  set class_10($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasClass_10() => $_has(9);
  @$pb.TagNumber(10)
  void clearClass_10() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.String get subjectPrefix => $_getSZ(10);
  @$pb.TagNumber(11)
  set subjectPrefix($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasSubjectPrefix() => $_has(10);
  @$pb.TagNumber(11)
  void clearSubjectPrefix() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.bool get excludeTrace => $_getBF(11);
  @$pb.TagNumber(12)
  set excludeTrace($core.bool value) => $_setBool(11, value);
  @$pb.TagNumber(12)
  $core.bool hasExcludeTrace() => $_has(11);
  @$pb.TagNumber(12)
  void clearExcludeTrace() => $_clearField(12);
}

class ResAdminLogList extends $pb.GeneratedMessage {
  factory ResAdminLogList({
    $core.Iterable<$0.Log>? logs,
  }) {
    final result = ResAdminLogList._();
    if (logs != null) result.logs.addAll(logs);
    return result;
  }

  ResAdminLogList._();

  factory ResAdminLogList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResAdminLogList()..mergeFromBuffer(data, registry);
  factory ResAdminLogList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResAdminLogList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResAdminLogList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResAdminLogList.$_createMessage)
    ..pPM<$0.Log>(1, _omitFieldNames ? '' : 'logs',
        subBuilder: $0.Log.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResAdminLogList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResAdminLogList copyWith(void Function(ResAdminLogList) updates) =>
      super.copyWith((message) => updates(message as ResAdminLogList))
          as ResAdminLogList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResAdminLogList() / ResAdminLogList.new instead')
  static ResAdminLogList create() => ResAdminLogList._();
  static $pb.GeneratedMessage $_createMessage() => ResAdminLogList._();
  @$core.override
  ResAdminLogList createEmptyInstance() => ResAdminLogList._();
  @$core.pragma('dart2js:noInline')
  static ResAdminLogList getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResAdminLogList>(
          ResAdminLogList.$_createMessage);
  static ResAdminLogList? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$0.Log> get logs => $_getList(0);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
