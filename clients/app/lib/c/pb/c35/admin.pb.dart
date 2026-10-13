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

class AdminUserReferrerBrief extends $pb.GeneratedMessage {
  factory AdminUserReferrerBrief({
    $fixnum.Int64? identityId,
    $core.String? name,
    $core.String? alienId,
  }) {
    final result = AdminUserReferrerBrief._();
    if (identityId != null) result.identityId = identityId;
    if (name != null) result.name = name;
    if (alienId != null) result.alienId = alienId;
    return result;
  }

  AdminUserReferrerBrief._();

  factory AdminUserReferrerBrief.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AdminUserReferrerBrief()..mergeFromBuffer(data, registry);
  factory AdminUserReferrerBrief.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AdminUserReferrerBrief()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AdminUserReferrerBrief',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: AdminUserReferrerBrief.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'identityId')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOS(3, _omitFieldNames ? '' : 'alienId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AdminUserReferrerBrief clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AdminUserReferrerBrief copyWith(
          void Function(AdminUserReferrerBrief) updates) =>
      super.copyWith((message) => updates(message as AdminUserReferrerBrief))
          as AdminUserReferrerBrief;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use AdminUserReferrerBrief() / AdminUserReferrerBrief.new instead')
  static AdminUserReferrerBrief create() => AdminUserReferrerBrief._();
  static $pb.GeneratedMessage $_createMessage() => AdminUserReferrerBrief._();
  @$core.override
  AdminUserReferrerBrief createEmptyInstance() => AdminUserReferrerBrief._();
  @$core.pragma('dart2js:noInline')
  static AdminUserReferrerBrief getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AdminUserReferrerBrief>(
          AdminUserReferrerBrief.$_createMessage);
  static AdminUserReferrerBrief? _defaultInstance;

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
  $core.String get alienId => $_getSZ(2);
  @$pb.TagNumber(3)
  set alienId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAlienId() => $_has(2);
  @$pb.TagNumber(3)
  void clearAlienId() => $_clearField(3);
}

class AdminUserRegistrationRow extends $pb.GeneratedMessage {
  factory AdminUserRegistrationRow({
    $fixnum.Int64? identityId,
    $core.String? name,
    $core.String? handle,
    $core.String? email,
    $fixnum.Int64? registeredTsMs,
    AdminUserReferrerBrief? referredBy,
  }) {
    final result = AdminUserRegistrationRow._();
    if (identityId != null) result.identityId = identityId;
    if (name != null) result.name = name;
    if (handle != null) result.handle = handle;
    if (email != null) result.email = email;
    if (registeredTsMs != null) result.registeredTsMs = registeredTsMs;
    if (referredBy != null) result.referredBy = referredBy;
    return result;
  }

  AdminUserRegistrationRow._();

  factory AdminUserRegistrationRow.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AdminUserRegistrationRow()..mergeFromBuffer(data, registry);
  factory AdminUserRegistrationRow.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AdminUserRegistrationRow()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AdminUserRegistrationRow',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: AdminUserRegistrationRow.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'identityId')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOS(3, _omitFieldNames ? '' : 'handle')
    ..aOS(4, _omitFieldNames ? '' : 'email')
    ..aInt64(5, _omitFieldNames ? '' : 'registeredTsMs')
    ..aOM<AdminUserReferrerBrief>(6, _omitFieldNames ? '' : 'referredBy',
        subBuilder: AdminUserReferrerBrief.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AdminUserRegistrationRow clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AdminUserRegistrationRow copyWith(
          void Function(AdminUserRegistrationRow) updates) =>
      super.copyWith((message) => updates(message as AdminUserRegistrationRow))
          as AdminUserRegistrationRow;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use AdminUserRegistrationRow() / AdminUserRegistrationRow.new instead')
  static AdminUserRegistrationRow create() => AdminUserRegistrationRow._();
  static $pb.GeneratedMessage $_createMessage() => AdminUserRegistrationRow._();
  @$core.override
  AdminUserRegistrationRow createEmptyInstance() =>
      AdminUserRegistrationRow._();
  @$core.pragma('dart2js:noInline')
  static AdminUserRegistrationRow getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AdminUserRegistrationRow>(
          AdminUserRegistrationRow.$_createMessage);
  static AdminUserRegistrationRow? _defaultInstance;

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
  $core.String get handle => $_getSZ(2);
  @$pb.TagNumber(3)
  set handle($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasHandle() => $_has(2);
  @$pb.TagNumber(3)
  void clearHandle() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get email => $_getSZ(3);
  @$pb.TagNumber(4)
  set email($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasEmail() => $_has(3);
  @$pb.TagNumber(4)
  void clearEmail() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get registeredTsMs => $_getI64(4);
  @$pb.TagNumber(5)
  set registeredTsMs($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasRegisteredTsMs() => $_has(4);
  @$pb.TagNumber(5)
  void clearRegisteredTsMs() => $_clearField(5);

  @$pb.TagNumber(6)
  AdminUserReferrerBrief get referredBy => $_getN(5);
  @$pb.TagNumber(6)
  set referredBy(AdminUserReferrerBrief value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasReferredBy() => $_has(5);
  @$pb.TagNumber(6)
  void clearReferredBy() => $_clearField(6);
  @$pb.TagNumber(6)
  AdminUserReferrerBrief ensureReferredBy() => $_ensure(5);
}

class ReqAdminUserRegistrationsList extends $pb.GeneratedMessage {
  factory ReqAdminUserRegistrationsList({
    $core.String? preset,
    $core.String? since,
    $core.String? until,
    $core.bool? countOnly,
    $core.int? limit,
    $fixnum.Int64? afterRegisteredTsMs,
    $fixnum.Int64? afterIdentityId,
    $fixnum.Int64? referredByUid,
    $core.String? timezone,
  }) {
    final result = ReqAdminUserRegistrationsList._();
    if (preset != null) result.preset = preset;
    if (since != null) result.since = since;
    if (until != null) result.until = until;
    if (countOnly != null) result.countOnly = countOnly;
    if (limit != null) result.limit = limit;
    if (afterRegisteredTsMs != null)
      result.afterRegisteredTsMs = afterRegisteredTsMs;
    if (afterIdentityId != null) result.afterIdentityId = afterIdentityId;
    if (referredByUid != null) result.referredByUid = referredByUid;
    if (timezone != null) result.timezone = timezone;
    return result;
  }

  ReqAdminUserRegistrationsList._();

  factory ReqAdminUserRegistrationsList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqAdminUserRegistrationsList()..mergeFromBuffer(data, registry);
  factory ReqAdminUserRegistrationsList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqAdminUserRegistrationsList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqAdminUserRegistrationsList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqAdminUserRegistrationsList.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'preset')
    ..aOS(2, _omitFieldNames ? '' : 'since')
    ..aOS(3, _omitFieldNames ? '' : 'until')
    ..aOB(4, _omitFieldNames ? '' : 'countOnly')
    ..aI(5, _omitFieldNames ? '' : 'limit')
    ..aInt64(6, _omitFieldNames ? '' : 'afterRegisteredTsMs')
    ..aInt64(7, _omitFieldNames ? '' : 'afterIdentityId')
    ..aInt64(8, _omitFieldNames ? '' : 'referredByUid')
    ..aOS(9, _omitFieldNames ? '' : 'timezone')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqAdminUserRegistrationsList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqAdminUserRegistrationsList copyWith(
          void Function(ReqAdminUserRegistrationsList) updates) =>
      super.copyWith(
              (message) => updates(message as ReqAdminUserRegistrationsList))
          as ReqAdminUserRegistrationsList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ReqAdminUserRegistrationsList() / ReqAdminUserRegistrationsList.new instead')
  static ReqAdminUserRegistrationsList create() =>
      ReqAdminUserRegistrationsList._();
  static $pb.GeneratedMessage $_createMessage() =>
      ReqAdminUserRegistrationsList._();
  @$core.override
  ReqAdminUserRegistrationsList createEmptyInstance() =>
      ReqAdminUserRegistrationsList._();
  @$core.pragma('dart2js:noInline')
  static ReqAdminUserRegistrationsList getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqAdminUserRegistrationsList>(
          ReqAdminUserRegistrationsList.$_createMessage);
  static ReqAdminUserRegistrationsList? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get preset => $_getSZ(0);
  @$pb.TagNumber(1)
  set preset($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPreset() => $_has(0);
  @$pb.TagNumber(1)
  void clearPreset() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get since => $_getSZ(1);
  @$pb.TagNumber(2)
  set since($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSince() => $_has(1);
  @$pb.TagNumber(2)
  void clearSince() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get until => $_getSZ(2);
  @$pb.TagNumber(3)
  set until($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasUntil() => $_has(2);
  @$pb.TagNumber(3)
  void clearUntil() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get countOnly => $_getBF(3);
  @$pb.TagNumber(4)
  set countOnly($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasCountOnly() => $_has(3);
  @$pb.TagNumber(4)
  void clearCountOnly() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get limit => $_getIZ(4);
  @$pb.TagNumber(5)
  set limit($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasLimit() => $_has(4);
  @$pb.TagNumber(5)
  void clearLimit() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get afterRegisteredTsMs => $_getI64(5);
  @$pb.TagNumber(6)
  set afterRegisteredTsMs($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasAfterRegisteredTsMs() => $_has(5);
  @$pb.TagNumber(6)
  void clearAfterRegisteredTsMs() => $_clearField(6);

  @$pb.TagNumber(7)
  $fixnum.Int64 get afterIdentityId => $_getI64(6);
  @$pb.TagNumber(7)
  set afterIdentityId($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(7)
  $core.bool hasAfterIdentityId() => $_has(6);
  @$pb.TagNumber(7)
  void clearAfterIdentityId() => $_clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get referredByUid => $_getI64(7);
  @$pb.TagNumber(8)
  set referredByUid($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(8)
  $core.bool hasReferredByUid() => $_has(7);
  @$pb.TagNumber(8)
  void clearReferredByUid() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get timezone => $_getSZ(8);
  @$pb.TagNumber(9)
  set timezone($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasTimezone() => $_has(8);
  @$pb.TagNumber(9)
  void clearTimezone() => $_clearField(9);
}

class ResAdminUserRegistrationsList extends $pb.GeneratedMessage {
  factory ResAdminUserRegistrationsList({
    $fixnum.Int64? count,
    $core.Iterable<AdminUserRegistrationRow>? users,
    $core.String? timezoneUsed,
    $fixnum.Int64? windowStartMs,
    $fixnum.Int64? windowEndMs,
    $core.bool? hasMore,
  }) {
    final result = ResAdminUserRegistrationsList._();
    if (count != null) result.count = count;
    if (users != null) result.users.addAll(users);
    if (timezoneUsed != null) result.timezoneUsed = timezoneUsed;
    if (windowStartMs != null) result.windowStartMs = windowStartMs;
    if (windowEndMs != null) result.windowEndMs = windowEndMs;
    if (hasMore != null) result.hasMore = hasMore;
    return result;
  }

  ResAdminUserRegistrationsList._();

  factory ResAdminUserRegistrationsList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResAdminUserRegistrationsList()..mergeFromBuffer(data, registry);
  factory ResAdminUserRegistrationsList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResAdminUserRegistrationsList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResAdminUserRegistrationsList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResAdminUserRegistrationsList.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'count')
    ..pPM<AdminUserRegistrationRow>(2, _omitFieldNames ? '' : 'users',
        subBuilder: AdminUserRegistrationRow.$_createMessage)
    ..aOS(3, _omitFieldNames ? '' : 'timezoneUsed')
    ..aInt64(4, _omitFieldNames ? '' : 'windowStartMs')
    ..aInt64(5, _omitFieldNames ? '' : 'windowEndMs')
    ..aOB(6, _omitFieldNames ? '' : 'hasMore')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResAdminUserRegistrationsList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResAdminUserRegistrationsList copyWith(
          void Function(ResAdminUserRegistrationsList) updates) =>
      super.copyWith(
              (message) => updates(message as ResAdminUserRegistrationsList))
          as ResAdminUserRegistrationsList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ResAdminUserRegistrationsList() / ResAdminUserRegistrationsList.new instead')
  static ResAdminUserRegistrationsList create() =>
      ResAdminUserRegistrationsList._();
  static $pb.GeneratedMessage $_createMessage() =>
      ResAdminUserRegistrationsList._();
  @$core.override
  ResAdminUserRegistrationsList createEmptyInstance() =>
      ResAdminUserRegistrationsList._();
  @$core.pragma('dart2js:noInline')
  static ResAdminUserRegistrationsList getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResAdminUserRegistrationsList>(
          ResAdminUserRegistrationsList.$_createMessage);
  static ResAdminUserRegistrationsList? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get count => $_getI64(0);
  @$pb.TagNumber(1)
  set count($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCount() => $_has(0);
  @$pb.TagNumber(1)
  void clearCount() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<AdminUserRegistrationRow> get users => $_getList(1);

  @$pb.TagNumber(3)
  $core.String get timezoneUsed => $_getSZ(2);
  @$pb.TagNumber(3)
  set timezoneUsed($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTimezoneUsed() => $_has(2);
  @$pb.TagNumber(3)
  void clearTimezoneUsed() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get windowStartMs => $_getI64(3);
  @$pb.TagNumber(4)
  set windowStartMs($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasWindowStartMs() => $_has(3);
  @$pb.TagNumber(4)
  void clearWindowStartMs() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get windowEndMs => $_getI64(4);
  @$pb.TagNumber(5)
  set windowEndMs($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasWindowEndMs() => $_has(4);
  @$pb.TagNumber(5)
  void clearWindowEndMs() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get hasMore => $_getBF(5);
  @$pb.TagNumber(6)
  set hasMore($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasHasMore() => $_has(5);
  @$pb.TagNumber(6)
  void clearHasMore() => $_clearField(6);
}

class AdminGlobalRolesPatch extends $pb.GeneratedMessage {
  factory AdminGlobalRolesPatch({
    $core.Iterable<$core.String>? roles,
  }) {
    final result = AdminGlobalRolesPatch._();
    if (roles != null) result.roles.addAll(roles);
    return result;
  }

  AdminGlobalRolesPatch._();

  factory AdminGlobalRolesPatch.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AdminGlobalRolesPatch()..mergeFromBuffer(data, registry);
  factory AdminGlobalRolesPatch.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AdminGlobalRolesPatch()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AdminGlobalRolesPatch',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: AdminGlobalRolesPatch.$_createMessage)
    ..pPS(1, _omitFieldNames ? '' : 'roles')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AdminGlobalRolesPatch clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AdminGlobalRolesPatch copyWith(
          void Function(AdminGlobalRolesPatch) updates) =>
      super.copyWith((message) => updates(message as AdminGlobalRolesPatch))
          as AdminGlobalRolesPatch;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use AdminGlobalRolesPatch() / AdminGlobalRolesPatch.new instead')
  static AdminGlobalRolesPatch create() => AdminGlobalRolesPatch._();
  static $pb.GeneratedMessage $_createMessage() => AdminGlobalRolesPatch._();
  @$core.override
  AdminGlobalRolesPatch createEmptyInstance() => AdminGlobalRolesPatch._();
  @$core.pragma('dart2js:noInline')
  static AdminGlobalRolesPatch getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AdminGlobalRolesPatch>(
          AdminGlobalRolesPatch.$_createMessage);
  static AdminGlobalRolesPatch? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get roles => $_getList(0);
}

class ReqAdminUserPut extends $pb.GeneratedMessage {
  factory ReqAdminUserPut({
    $fixnum.Int64? targetIdentityId,
    $core.String? name,
    $core.String? avatarUrl,
    $fixnum.Int64? referredByUid,
    $core.String? handle,
    $core.String? authEmail,
    AdminGlobalRolesPatch? globalRoles,
  }) {
    final result = ReqAdminUserPut._();
    if (targetIdentityId != null) result.targetIdentityId = targetIdentityId;
    if (name != null) result.name = name;
    if (avatarUrl != null) result.avatarUrl = avatarUrl;
    if (referredByUid != null) result.referredByUid = referredByUid;
    if (handle != null) result.handle = handle;
    if (authEmail != null) result.authEmail = authEmail;
    if (globalRoles != null) result.globalRoles = globalRoles;
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
    ..aOM<AdminGlobalRolesPatch>(7, _omitFieldNames ? '' : 'globalRoles',
        subBuilder: AdminGlobalRolesPatch.$_createMessage)
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

  @$pb.TagNumber(7)
  AdminGlobalRolesPatch get globalRoles => $_getN(6);
  @$pb.TagNumber(7)
  set globalRoles(AdminGlobalRolesPatch value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasGlobalRoles() => $_has(6);
  @$pb.TagNumber(7)
  void clearGlobalRoles() => $_clearField(7);
  @$pb.TagNumber(7)
  AdminGlobalRolesPatch ensureGlobalRoles() => $_ensure(6);
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

/// Root-only LLM catalog wholesale + retail ($/1M tokens). Cache column 0 = unknown.
class AdminLlmCatalogRow extends $pb.GeneratedMessage {
  factory AdminLlmCatalogRow({
    $core.String? id,
    $core.String? provider,
    $core.String? label,
    $core.String? source,
    $core.bool? enabled,
    $core.double? usdInPer1m,
    $core.double? usdInCachePer1m,
    $core.double? usdOutPer1m,
    $core.double? retailUsdInPer1m,
    $core.double? retailUsdInCachePer1m,
    $core.double? retailUsdOutPer1m,
  }) {
    final result = AdminLlmCatalogRow._();
    if (id != null) result.id = id;
    if (provider != null) result.provider = provider;
    if (label != null) result.label = label;
    if (source != null) result.source = source;
    if (enabled != null) result.enabled = enabled;
    if (usdInPer1m != null) result.usdInPer1m = usdInPer1m;
    if (usdInCachePer1m != null) result.usdInCachePer1m = usdInCachePer1m;
    if (usdOutPer1m != null) result.usdOutPer1m = usdOutPer1m;
    if (retailUsdInPer1m != null) result.retailUsdInPer1m = retailUsdInPer1m;
    if (retailUsdInCachePer1m != null)
      result.retailUsdInCachePer1m = retailUsdInCachePer1m;
    if (retailUsdOutPer1m != null) result.retailUsdOutPer1m = retailUsdOutPer1m;
    return result;
  }

  AdminLlmCatalogRow._();

  factory AdminLlmCatalogRow.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AdminLlmCatalogRow()..mergeFromBuffer(data, registry);
  factory AdminLlmCatalogRow.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AdminLlmCatalogRow()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AdminLlmCatalogRow',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: AdminLlmCatalogRow.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'provider')
    ..aOS(3, _omitFieldNames ? '' : 'label')
    ..aOS(4, _omitFieldNames ? '' : 'source')
    ..aOB(5, _omitFieldNames ? '' : 'enabled')
    ..aD(6, _omitFieldNames ? '' : 'usdInPer1m', protoName: 'usd_in_per_1m')
    ..aD(7, _omitFieldNames ? '' : 'usdInCachePer1m',
        protoName: 'usd_in_cache_per_1m')
    ..aD(8, _omitFieldNames ? '' : 'usdOutPer1m', protoName: 'usd_out_per_1m')
    ..aD(9, _omitFieldNames ? '' : 'retailUsdInPer1m',
        protoName: 'retail_usd_in_per_1m')
    ..aD(10, _omitFieldNames ? '' : 'retailUsdInCachePer1m',
        protoName: 'retail_usd_in_cache_per_1m')
    ..aD(11, _omitFieldNames ? '' : 'retailUsdOutPer1m',
        protoName: 'retail_usd_out_per_1m')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AdminLlmCatalogRow clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AdminLlmCatalogRow copyWith(void Function(AdminLlmCatalogRow) updates) =>
      super.copyWith((message) => updates(message as AdminLlmCatalogRow))
          as AdminLlmCatalogRow;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use AdminLlmCatalogRow() / AdminLlmCatalogRow.new instead')
  static AdminLlmCatalogRow create() => AdminLlmCatalogRow._();
  static $pb.GeneratedMessage $_createMessage() => AdminLlmCatalogRow._();
  @$core.override
  AdminLlmCatalogRow createEmptyInstance() => AdminLlmCatalogRow._();
  @$core.pragma('dart2js:noInline')
  static AdminLlmCatalogRow getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AdminLlmCatalogRow>(
          AdminLlmCatalogRow.$_createMessage);
  static AdminLlmCatalogRow? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get provider => $_getSZ(1);
  @$pb.TagNumber(2)
  set provider($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasProvider() => $_has(1);
  @$pb.TagNumber(2)
  void clearProvider() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get label => $_getSZ(2);
  @$pb.TagNumber(3)
  set label($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLabel() => $_has(2);
  @$pb.TagNumber(3)
  void clearLabel() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get source => $_getSZ(3);
  @$pb.TagNumber(4)
  set source($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSource() => $_has(3);
  @$pb.TagNumber(4)
  void clearSource() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get enabled => $_getBF(4);
  @$pb.TagNumber(5)
  set enabled($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasEnabled() => $_has(4);
  @$pb.TagNumber(5)
  void clearEnabled() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.double get usdInPer1m => $_getN(5);
  @$pb.TagNumber(6)
  set usdInPer1m($core.double value) => $_setDouble(5, value);
  @$pb.TagNumber(6)
  $core.bool hasUsdInPer1m() => $_has(5);
  @$pb.TagNumber(6)
  void clearUsdInPer1m() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.double get usdInCachePer1m => $_getN(6);
  @$pb.TagNumber(7)
  set usdInCachePer1m($core.double value) => $_setDouble(6, value);
  @$pb.TagNumber(7)
  $core.bool hasUsdInCachePer1m() => $_has(6);
  @$pb.TagNumber(7)
  void clearUsdInCachePer1m() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.double get usdOutPer1m => $_getN(7);
  @$pb.TagNumber(8)
  set usdOutPer1m($core.double value) => $_setDouble(7, value);
  @$pb.TagNumber(8)
  $core.bool hasUsdOutPer1m() => $_has(7);
  @$pb.TagNumber(8)
  void clearUsdOutPer1m() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.double get retailUsdInPer1m => $_getN(8);
  @$pb.TagNumber(9)
  set retailUsdInPer1m($core.double value) => $_setDouble(8, value);
  @$pb.TagNumber(9)
  $core.bool hasRetailUsdInPer1m() => $_has(8);
  @$pb.TagNumber(9)
  void clearRetailUsdInPer1m() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.double get retailUsdInCachePer1m => $_getN(9);
  @$pb.TagNumber(10)
  set retailUsdInCachePer1m($core.double value) => $_setDouble(9, value);
  @$pb.TagNumber(10)
  $core.bool hasRetailUsdInCachePer1m() => $_has(9);
  @$pb.TagNumber(10)
  void clearRetailUsdInCachePer1m() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.double get retailUsdOutPer1m => $_getN(10);
  @$pb.TagNumber(11)
  set retailUsdOutPer1m($core.double value) => $_setDouble(10, value);
  @$pb.TagNumber(11)
  $core.bool hasRetailUsdOutPer1m() => $_has(10);
  @$pb.TagNumber(11)
  void clearRetailUsdOutPer1m() => $_clearField(11);
}

class ReqAdminLlmCatalogList extends $pb.GeneratedMessage {
  factory ReqAdminLlmCatalogList({
    $core.bool? enabledOnly,
  }) {
    final result = ReqAdminLlmCatalogList._();
    if (enabledOnly != null) result.enabledOnly = enabledOnly;
    return result;
  }

  ReqAdminLlmCatalogList._();

  factory ReqAdminLlmCatalogList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqAdminLlmCatalogList()..mergeFromBuffer(data, registry);
  factory ReqAdminLlmCatalogList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqAdminLlmCatalogList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqAdminLlmCatalogList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqAdminLlmCatalogList.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'enabledOnly')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqAdminLlmCatalogList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqAdminLlmCatalogList copyWith(
          void Function(ReqAdminLlmCatalogList) updates) =>
      super.copyWith((message) => updates(message as ReqAdminLlmCatalogList))
          as ReqAdminLlmCatalogList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ReqAdminLlmCatalogList() / ReqAdminLlmCatalogList.new instead')
  static ReqAdminLlmCatalogList create() => ReqAdminLlmCatalogList._();
  static $pb.GeneratedMessage $_createMessage() => ReqAdminLlmCatalogList._();
  @$core.override
  ReqAdminLlmCatalogList createEmptyInstance() => ReqAdminLlmCatalogList._();
  @$core.pragma('dart2js:noInline')
  static ReqAdminLlmCatalogList getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqAdminLlmCatalogList>(
          ReqAdminLlmCatalogList.$_createMessage);
  static ReqAdminLlmCatalogList? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get enabledOnly => $_getBF(0);
  @$pb.TagNumber(1)
  set enabledOnly($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEnabledOnly() => $_has(0);
  @$pb.TagNumber(1)
  void clearEnabledOnly() => $_clearField(1);
}

class AdminServiceRateRow extends $pb.GeneratedMessage {
  factory AdminServiceRateRow({
    $core.String? category,
    $core.String? id,
    $core.String? label,
    $core.String? unit,
    $core.double? wholesaleUsd,
    $core.double? retailUsd,
    $core.String? detail,
  }) {
    final result = AdminServiceRateRow._();
    if (category != null) result.category = category;
    if (id != null) result.id = id;
    if (label != null) result.label = label;
    if (unit != null) result.unit = unit;
    if (wholesaleUsd != null) result.wholesaleUsd = wholesaleUsd;
    if (retailUsd != null) result.retailUsd = retailUsd;
    if (detail != null) result.detail = detail;
    return result;
  }

  AdminServiceRateRow._();

  factory AdminServiceRateRow.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AdminServiceRateRow()..mergeFromBuffer(data, registry);
  factory AdminServiceRateRow.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AdminServiceRateRow()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AdminServiceRateRow',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: AdminServiceRateRow.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'category')
    ..aOS(2, _omitFieldNames ? '' : 'id')
    ..aOS(3, _omitFieldNames ? '' : 'label')
    ..aOS(4, _omitFieldNames ? '' : 'unit')
    ..aD(5, _omitFieldNames ? '' : 'wholesaleUsd')
    ..aD(6, _omitFieldNames ? '' : 'retailUsd')
    ..aOS(7, _omitFieldNames ? '' : 'detail')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AdminServiceRateRow clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AdminServiceRateRow copyWith(void Function(AdminServiceRateRow) updates) =>
      super.copyWith((message) => updates(message as AdminServiceRateRow))
          as AdminServiceRateRow;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use AdminServiceRateRow() / AdminServiceRateRow.new instead')
  static AdminServiceRateRow create() => AdminServiceRateRow._();
  static $pb.GeneratedMessage $_createMessage() => AdminServiceRateRow._();
  @$core.override
  AdminServiceRateRow createEmptyInstance() => AdminServiceRateRow._();
  @$core.pragma('dart2js:noInline')
  static AdminServiceRateRow getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AdminServiceRateRow>(
          AdminServiceRateRow.$_createMessage);
  static AdminServiceRateRow? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get category => $_getSZ(0);
  @$pb.TagNumber(1)
  set category($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCategory() => $_has(0);
  @$pb.TagNumber(1)
  void clearCategory() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get id => $_getSZ(1);
  @$pb.TagNumber(2)
  set id($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasId() => $_has(1);
  @$pb.TagNumber(2)
  void clearId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get label => $_getSZ(2);
  @$pb.TagNumber(3)
  set label($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLabel() => $_has(2);
  @$pb.TagNumber(3)
  void clearLabel() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get unit => $_getSZ(3);
  @$pb.TagNumber(4)
  set unit($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasUnit() => $_has(3);
  @$pb.TagNumber(4)
  void clearUnit() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.double get wholesaleUsd => $_getN(4);
  @$pb.TagNumber(5)
  set wholesaleUsd($core.double value) => $_setDouble(4, value);
  @$pb.TagNumber(5)
  $core.bool hasWholesaleUsd() => $_has(4);
  @$pb.TagNumber(5)
  void clearWholesaleUsd() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.double get retailUsd => $_getN(5);
  @$pb.TagNumber(6)
  set retailUsd($core.double value) => $_setDouble(5, value);
  @$pb.TagNumber(6)
  $core.bool hasRetailUsd() => $_has(5);
  @$pb.TagNumber(6)
  void clearRetailUsd() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get detail => $_getSZ(6);
  @$pb.TagNumber(7)
  set detail($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasDetail() => $_has(6);
  @$pb.TagNumber(7)
  void clearDetail() => $_clearField(7);
}

class ResAdminLlmCatalogList extends $pb.GeneratedMessage {
  factory ResAdminLlmCatalogList({
    $core.Iterable<AdminLlmCatalogRow>? models,
    $core.double? retailMarkup,
    $core.Iterable<AdminServiceRateRow>? services,
    $core.Iterable<AdminServiceRateRow>? live,
  }) {
    final result = ResAdminLlmCatalogList._();
    if (models != null) result.models.addAll(models);
    if (retailMarkup != null) result.retailMarkup = retailMarkup;
    if (services != null) result.services.addAll(services);
    if (live != null) result.live.addAll(live);
    return result;
  }

  ResAdminLlmCatalogList._();

  factory ResAdminLlmCatalogList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResAdminLlmCatalogList()..mergeFromBuffer(data, registry);
  factory ResAdminLlmCatalogList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResAdminLlmCatalogList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResAdminLlmCatalogList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResAdminLlmCatalogList.$_createMessage)
    ..pPM<AdminLlmCatalogRow>(1, _omitFieldNames ? '' : 'models',
        subBuilder: AdminLlmCatalogRow.$_createMessage)
    ..aD(2, _omitFieldNames ? '' : 'retailMarkup')
    ..pPM<AdminServiceRateRow>(3, _omitFieldNames ? '' : 'services',
        subBuilder: AdminServiceRateRow.$_createMessage)
    ..pPM<AdminServiceRateRow>(4, _omitFieldNames ? '' : 'live',
        subBuilder: AdminServiceRateRow.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResAdminLlmCatalogList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResAdminLlmCatalogList copyWith(
          void Function(ResAdminLlmCatalogList) updates) =>
      super.copyWith((message) => updates(message as ResAdminLlmCatalogList))
          as ResAdminLlmCatalogList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ResAdminLlmCatalogList() / ResAdminLlmCatalogList.new instead')
  static ResAdminLlmCatalogList create() => ResAdminLlmCatalogList._();
  static $pb.GeneratedMessage $_createMessage() => ResAdminLlmCatalogList._();
  @$core.override
  ResAdminLlmCatalogList createEmptyInstance() => ResAdminLlmCatalogList._();
  @$core.pragma('dart2js:noInline')
  static ResAdminLlmCatalogList getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResAdminLlmCatalogList>(
          ResAdminLlmCatalogList.$_createMessage);
  static ResAdminLlmCatalogList? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<AdminLlmCatalogRow> get models => $_getList(0);

  @$pb.TagNumber(2)
  $core.double get retailMarkup => $_getN(1);
  @$pb.TagNumber(2)
  set retailMarkup($core.double value) => $_setDouble(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRetailMarkup() => $_has(1);
  @$pb.TagNumber(2)
  void clearRetailMarkup() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<AdminServiceRateRow> get services => $_getList(2);

  @$pb.TagNumber(4)
  $pb.PbList<AdminServiceRateRow> get live => $_getList(3);
}

/// Root console — registrations, app activity (WS), settled payments per window.
class PlatformUserMetricsWindowCounts extends $pb.GeneratedMessage {
  factory PlatformUserMetricsWindowCounts({
    $fixnum.Int64? h24,
    $fixnum.Int64? d7,
    $fixnum.Int64? d30,
    $fixnum.Int64? y1,
  }) {
    final result = PlatformUserMetricsWindowCounts._();
    if (h24 != null) result.h24 = h24;
    if (d7 != null) result.d7 = d7;
    if (d30 != null) result.d30 = d30;
    if (y1 != null) result.y1 = y1;
    return result;
  }

  PlatformUserMetricsWindowCounts._();

  factory PlatformUserMetricsWindowCounts.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PlatformUserMetricsWindowCounts()..mergeFromBuffer(data, registry);
  factory PlatformUserMetricsWindowCounts.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PlatformUserMetricsWindowCounts()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PlatformUserMetricsWindowCounts',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: PlatformUserMetricsWindowCounts.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'h24')
    ..aInt64(2, _omitFieldNames ? '' : 'd7')
    ..aInt64(3, _omitFieldNames ? '' : 'd30')
    ..aInt64(4, _omitFieldNames ? '' : 'y1')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlatformUserMetricsWindowCounts clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlatformUserMetricsWindowCounts copyWith(
          void Function(PlatformUserMetricsWindowCounts) updates) =>
      super.copyWith(
              (message) => updates(message as PlatformUserMetricsWindowCounts))
          as PlatformUserMetricsWindowCounts;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use PlatformUserMetricsWindowCounts() / PlatformUserMetricsWindowCounts.new instead')
  static PlatformUserMetricsWindowCounts create() =>
      PlatformUserMetricsWindowCounts._();
  static $pb.GeneratedMessage $_createMessage() =>
      PlatformUserMetricsWindowCounts._();
  @$core.override
  PlatformUserMetricsWindowCounts createEmptyInstance() =>
      PlatformUserMetricsWindowCounts._();
  @$core.pragma('dart2js:noInline')
  static PlatformUserMetricsWindowCounts getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PlatformUserMetricsWindowCounts>(
          PlatformUserMetricsWindowCounts.$_createMessage);
  static PlatformUserMetricsWindowCounts? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get h24 => $_getI64(0);
  @$pb.TagNumber(1)
  set h24($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasH24() => $_has(0);
  @$pb.TagNumber(1)
  void clearH24() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get d7 => $_getI64(1);
  @$pb.TagNumber(2)
  set d7($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasD7() => $_has(1);
  @$pb.TagNumber(2)
  void clearD7() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get d30 => $_getI64(2);
  @$pb.TagNumber(3)
  set d30($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasD30() => $_has(2);
  @$pb.TagNumber(3)
  void clearD30() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get y1 => $_getI64(3);
  @$pb.TagNumber(4)
  set y1($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasY1() => $_has(3);
  @$pb.TagNumber(4)
  void clearY1() => $_clearField(4);
}

class ReqAdminPlatformUserMetrics extends $pb.GeneratedMessage {
  factory ReqAdminPlatformUserMetrics() => ReqAdminPlatformUserMetrics._();

  ReqAdminPlatformUserMetrics._();

  factory ReqAdminPlatformUserMetrics.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqAdminPlatformUserMetrics()..mergeFromBuffer(data, registry);
  factory ReqAdminPlatformUserMetrics.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqAdminPlatformUserMetrics()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqAdminPlatformUserMetrics',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqAdminPlatformUserMetrics.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqAdminPlatformUserMetrics clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqAdminPlatformUserMetrics copyWith(
          void Function(ReqAdminPlatformUserMetrics) updates) =>
      super.copyWith(
              (message) => updates(message as ReqAdminPlatformUserMetrics))
          as ReqAdminPlatformUserMetrics;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ReqAdminPlatformUserMetrics() / ReqAdminPlatformUserMetrics.new instead')
  static ReqAdminPlatformUserMetrics create() =>
      ReqAdminPlatformUserMetrics._();
  static $pb.GeneratedMessage $_createMessage() =>
      ReqAdminPlatformUserMetrics._();
  @$core.override
  ReqAdminPlatformUserMetrics createEmptyInstance() =>
      ReqAdminPlatformUserMetrics._();
  @$core.pragma('dart2js:noInline')
  static ReqAdminPlatformUserMetrics getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqAdminPlatformUserMetrics>(
          ReqAdminPlatformUserMetrics.$_createMessage);
  static ReqAdminPlatformUserMetrics? _defaultInstance;
}

class ResAdminPlatformUserMetrics extends $pb.GeneratedMessage {
  factory ResAdminPlatformUserMetrics({
    PlatformUserMetricsWindowCounts? users,
    PlatformUserMetricsWindowCounts? activeUsers,
    PlatformUserMetricsWindowCounts? paidUsers,
    $fixnum.Int64? totalUsers,
  }) {
    final result = ResAdminPlatformUserMetrics._();
    if (users != null) result.users = users;
    if (activeUsers != null) result.activeUsers = activeUsers;
    if (paidUsers != null) result.paidUsers = paidUsers;
    if (totalUsers != null) result.totalUsers = totalUsers;
    return result;
  }

  ResAdminPlatformUserMetrics._();

  factory ResAdminPlatformUserMetrics.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResAdminPlatformUserMetrics()..mergeFromBuffer(data, registry);
  factory ResAdminPlatformUserMetrics.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResAdminPlatformUserMetrics()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResAdminPlatformUserMetrics',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResAdminPlatformUserMetrics.$_createMessage)
    ..aOM<PlatformUserMetricsWindowCounts>(1, _omitFieldNames ? '' : 'users',
        subBuilder: PlatformUserMetricsWindowCounts.$_createMessage)
    ..aOM<PlatformUserMetricsWindowCounts>(
        2, _omitFieldNames ? '' : 'activeUsers',
        subBuilder: PlatformUserMetricsWindowCounts.$_createMessage)
    ..aOM<PlatformUserMetricsWindowCounts>(
        3, _omitFieldNames ? '' : 'paidUsers',
        subBuilder: PlatformUserMetricsWindowCounts.$_createMessage)
    ..aInt64(4, _omitFieldNames ? '' : 'totalUsers')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResAdminPlatformUserMetrics clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResAdminPlatformUserMetrics copyWith(
          void Function(ResAdminPlatformUserMetrics) updates) =>
      super.copyWith(
              (message) => updates(message as ResAdminPlatformUserMetrics))
          as ResAdminPlatformUserMetrics;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ResAdminPlatformUserMetrics() / ResAdminPlatformUserMetrics.new instead')
  static ResAdminPlatformUserMetrics create() =>
      ResAdminPlatformUserMetrics._();
  static $pb.GeneratedMessage $_createMessage() =>
      ResAdminPlatformUserMetrics._();
  @$core.override
  ResAdminPlatformUserMetrics createEmptyInstance() =>
      ResAdminPlatformUserMetrics._();
  @$core.pragma('dart2js:noInline')
  static ResAdminPlatformUserMetrics getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResAdminPlatformUserMetrics>(
          ResAdminPlatformUserMetrics.$_createMessage);
  static ResAdminPlatformUserMetrics? _defaultInstance;

  @$pb.TagNumber(1)
  PlatformUserMetricsWindowCounts get users => $_getN(0);
  @$pb.TagNumber(1)
  set users(PlatformUserMetricsWindowCounts value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasUsers() => $_has(0);
  @$pb.TagNumber(1)
  void clearUsers() => $_clearField(1);
  @$pb.TagNumber(1)
  PlatformUserMetricsWindowCounts ensureUsers() => $_ensure(0);

  @$pb.TagNumber(2)
  PlatformUserMetricsWindowCounts get activeUsers => $_getN(1);
  @$pb.TagNumber(2)
  set activeUsers(PlatformUserMetricsWindowCounts value) =>
      $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasActiveUsers() => $_has(1);
  @$pb.TagNumber(2)
  void clearActiveUsers() => $_clearField(2);
  @$pb.TagNumber(2)
  PlatformUserMetricsWindowCounts ensureActiveUsers() => $_ensure(1);

  @$pb.TagNumber(3)
  PlatformUserMetricsWindowCounts get paidUsers => $_getN(2);
  @$pb.TagNumber(3)
  set paidUsers(PlatformUserMetricsWindowCounts value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasPaidUsers() => $_has(2);
  @$pb.TagNumber(3)
  void clearPaidUsers() => $_clearField(3);
  @$pb.TagNumber(3)
  PlatformUserMetricsWindowCounts ensurePaidUsers() => $_ensure(2);

  @$pb.TagNumber(4)
  $fixnum.Int64 get totalUsers => $_getI64(3);
  @$pb.TagNumber(4)
  set totalUsers($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTotalUsers() => $_has(3);
  @$pb.TagNumber(4)
  void clearTotalUsers() => $_clearField(4);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
