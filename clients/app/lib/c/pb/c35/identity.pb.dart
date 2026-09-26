// This is a generated file - do not edit.
//
// Generated from c35/identity.proto.

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

class IdentityProfile extends $pb.GeneratedMessage {
  factory IdentityProfile({
    $fixnum.Int64? iid,
    $core.String? kind,
    $core.String? type,
    $core.String? alienId,
    $core.String? name,
    $core.String? pic,
    $core.String? locale,
    $core.String? tz,
    $fixnum.Int64? billingIid,
    $core.bool? isRoot,
    $core.String? locationCity,
    $core.String? locationRegion,
    $core.String? locationCountry,
    $core.String? locationSource,
  }) {
    final result = IdentityProfile._();
    if (iid != null) result.iid = iid;
    if (kind != null) result.kind = kind;
    if (type != null) result.type = type;
    if (alienId != null) result.alienId = alienId;
    if (name != null) result.name = name;
    if (pic != null) result.pic = pic;
    if (locale != null) result.locale = locale;
    if (tz != null) result.tz = tz;
    if (billingIid != null) result.billingIid = billingIid;
    if (isRoot != null) result.isRoot = isRoot;
    if (locationCity != null) result.locationCity = locationCity;
    if (locationRegion != null) result.locationRegion = locationRegion;
    if (locationCountry != null) result.locationCountry = locationCountry;
    if (locationSource != null) result.locationSource = locationSource;
    return result;
  }

  IdentityProfile._();

  factory IdentityProfile.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      IdentityProfile()..mergeFromBuffer(data, registry);
  factory IdentityProfile.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      IdentityProfile()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'IdentityProfile',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: IdentityProfile.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'iid')
    ..aOS(2, _omitFieldNames ? '' : 'kind')
    ..aOS(3, _omitFieldNames ? '' : 'type')
    ..aOS(4, _omitFieldNames ? '' : 'alienId')
    ..aOS(5, _omitFieldNames ? '' : 'name')
    ..aOS(6, _omitFieldNames ? '' : 'pic')
    ..aOS(7, _omitFieldNames ? '' : 'locale')
    ..aOS(8, _omitFieldNames ? '' : 'tz')
    ..aInt64(9, _omitFieldNames ? '' : 'billingIid')
    ..aOB(10, _omitFieldNames ? '' : 'isRoot')
    ..aOS(11, _omitFieldNames ? '' : 'locationCity')
    ..aOS(12, _omitFieldNames ? '' : 'locationRegion')
    ..aOS(13, _omitFieldNames ? '' : 'locationCountry')
    ..aOS(14, _omitFieldNames ? '' : 'locationSource')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IdentityProfile clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IdentityProfile copyWith(void Function(IdentityProfile) updates) =>
      super.copyWith((message) => updates(message as IdentityProfile))
          as IdentityProfile;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use IdentityProfile() / IdentityProfile.new instead')
  static IdentityProfile create() => IdentityProfile._();
  static $pb.GeneratedMessage $_createMessage() => IdentityProfile._();
  @$core.override
  IdentityProfile createEmptyInstance() => IdentityProfile._();
  @$core.pragma('dart2js:noInline')
  static IdentityProfile getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<IdentityProfile>(
          IdentityProfile.$_createMessage);
  static IdentityProfile? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get iid => $_getI64(0);
  @$pb.TagNumber(1)
  set iid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearIid() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get kind => $_getSZ(1);
  @$pb.TagNumber(2)
  set kind($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasKind() => $_has(1);
  @$pb.TagNumber(2)
  void clearKind() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get type => $_getSZ(2);
  @$pb.TagNumber(3)
  set type($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasType() => $_has(2);
  @$pb.TagNumber(3)
  void clearType() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get alienId => $_getSZ(3);
  @$pb.TagNumber(4)
  set alienId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAlienId() => $_has(3);
  @$pb.TagNumber(4)
  void clearAlienId() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get name => $_getSZ(4);
  @$pb.TagNumber(5)
  set name($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasName() => $_has(4);
  @$pb.TagNumber(5)
  void clearName() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get pic => $_getSZ(5);
  @$pb.TagNumber(6)
  set pic($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasPic() => $_has(5);
  @$pb.TagNumber(6)
  void clearPic() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get locale => $_getSZ(6);
  @$pb.TagNumber(7)
  set locale($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasLocale() => $_has(6);
  @$pb.TagNumber(7)
  void clearLocale() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get tz => $_getSZ(7);
  @$pb.TagNumber(8)
  set tz($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasTz() => $_has(7);
  @$pb.TagNumber(8)
  void clearTz() => $_clearField(8);

  @$pb.TagNumber(9)
  $fixnum.Int64 get billingIid => $_getI64(8);
  @$pb.TagNumber(9)
  set billingIid($fixnum.Int64 value) => $_setInt64(8, value);
  @$pb.TagNumber(9)
  $core.bool hasBillingIid() => $_has(8);
  @$pb.TagNumber(9)
  void clearBillingIid() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.bool get isRoot => $_getBF(9);
  @$pb.TagNumber(10)
  set isRoot($core.bool value) => $_setBool(9, value);
  @$pb.TagNumber(10)
  $core.bool hasIsRoot() => $_has(9);
  @$pb.TagNumber(10)
  void clearIsRoot() => $_clearField(10);

  /// Approximate user location for local recommendations (city-level).
  @$pb.TagNumber(11)
  $core.String get locationCity => $_getSZ(10);
  @$pb.TagNumber(11)
  set locationCity($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasLocationCity() => $_has(10);
  @$pb.TagNumber(11)
  void clearLocationCity() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.String get locationRegion => $_getSZ(11);
  @$pb.TagNumber(12)
  set locationRegion($core.String value) => $_setString(11, value);
  @$pb.TagNumber(12)
  $core.bool hasLocationRegion() => $_has(11);
  @$pb.TagNumber(12)
  void clearLocationRegion() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.String get locationCountry => $_getSZ(12);
  @$pb.TagNumber(13)
  set locationCountry($core.String value) => $_setString(12, value);
  @$pb.TagNumber(13)
  $core.bool hasLocationCountry() => $_has(12);
  @$pb.TagNumber(13)
  void clearLocationCountry() => $_clearField(13);

  /// device | ip | user — read-only from identity.meta.location.source
  @$pb.TagNumber(14)
  $core.String get locationSource => $_getSZ(13);
  @$pb.TagNumber(14)
  set locationSource($core.String value) => $_setString(13, value);
  @$pb.TagNumber(14)
  $core.bool hasLocationSource() => $_has(13);
  @$pb.TagNumber(14)
  void clearLocationSource() => $_clearField(14);
}

class NavCounts extends $pb.GeneratedMessage {
  factory NavCounts({
    $core.int? bots,
    $core.int? devices,
    $core.int? sites,
    $core.int? mailInboxUnread,
    $core.bool? mailMenuVisible,
  }) {
    final result = NavCounts._();
    if (bots != null) result.bots = bots;
    if (devices != null) result.devices = devices;
    if (sites != null) result.sites = sites;
    if (mailInboxUnread != null) result.mailInboxUnread = mailInboxUnread;
    if (mailMenuVisible != null) result.mailMenuVisible = mailMenuVisible;
    return result;
  }

  NavCounts._();

  factory NavCounts.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      NavCounts()..mergeFromBuffer(data, registry);
  factory NavCounts.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      NavCounts()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NavCounts',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: NavCounts.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'bots')
    ..aI(2, _omitFieldNames ? '' : 'devices')
    ..aI(3, _omitFieldNames ? '' : 'sites')
    ..aI(4, _omitFieldNames ? '' : 'mailInboxUnread')
    ..aOB(5, _omitFieldNames ? '' : 'mailMenuVisible')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NavCounts clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NavCounts copyWith(void Function(NavCounts) updates) =>
      super.copyWith((message) => updates(message as NavCounts)) as NavCounts;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use NavCounts() / NavCounts.new instead')
  static NavCounts create() => NavCounts._();
  static $pb.GeneratedMessage $_createMessage() => NavCounts._();
  @$core.override
  NavCounts createEmptyInstance() => NavCounts._();
  @$core.pragma('dart2js:noInline')
  static NavCounts getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NavCounts>(NavCounts.$_createMessage);
  static NavCounts? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get bots => $_getIZ(0);
  @$pb.TagNumber(1)
  set bots($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasBots() => $_has(0);
  @$pb.TagNumber(1)
  void clearBots() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get devices => $_getIZ(1);
  @$pb.TagNumber(2)
  set devices($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDevices() => $_has(1);
  @$pb.TagNumber(2)
  void clearDevices() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get sites => $_getIZ(2);
  @$pb.TagNumber(3)
  set sites($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSites() => $_has(2);
  @$pb.TagNumber(3)
  void clearSites() => $_clearField(3);

  /// Sum of unread inbound (non-archived) across all mailboxes the user can access.
  @$pb.TagNumber(4)
  $core.int get mailInboxUnread => $_getIZ(3);
  @$pb.TagNumber(4)
  set mailInboxUnread($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasMailInboxUnread() => $_has(3);
  @$pb.TagNumber(4)
  void clearMailInboxUnread() => $_clearField(4);

  /// Show platform mail entry (staff / partner / mailbox_member).
  @$pb.TagNumber(5)
  $core.bool get mailMenuVisible => $_getBF(4);
  @$pb.TagNumber(5)
  set mailMenuVisible($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasMailMenuVisible() => $_has(4);
  @$pb.TagNumber(5)
  void clearMailMenuVisible() => $_clearField(5);
}

class IdentityGrant extends $pb.GeneratedMessage {
  factory IdentityGrant({
    $fixnum.Int64? id,
    $fixnum.Int64? resourceIid,
    $fixnum.Int64? granteeIid,
    $core.String? role,
    $core.Iterable<$core.String>? permissions,
    $core.bool? isPinned,
    $core.String? metaJson,
    $fixnum.Int64? createdTsMs,
    $fixnum.Int64? updatedTsMs,
    $fixnum.Int64? deletedTsMs,
  }) {
    final result = IdentityGrant._();
    if (id != null) result.id = id;
    if (resourceIid != null) result.resourceIid = resourceIid;
    if (granteeIid != null) result.granteeIid = granteeIid;
    if (role != null) result.role = role;
    if (permissions != null) result.permissions.addAll(permissions);
    if (isPinned != null) result.isPinned = isPinned;
    if (metaJson != null) result.metaJson = metaJson;
    if (createdTsMs != null) result.createdTsMs = createdTsMs;
    if (updatedTsMs != null) result.updatedTsMs = updatedTsMs;
    if (deletedTsMs != null) result.deletedTsMs = deletedTsMs;
    return result;
  }

  IdentityGrant._();

  factory IdentityGrant.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      IdentityGrant()..mergeFromBuffer(data, registry);
  factory IdentityGrant.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      IdentityGrant()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'IdentityGrant',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: IdentityGrant.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..aInt64(2, _omitFieldNames ? '' : 'resourceIid')
    ..aInt64(3, _omitFieldNames ? '' : 'granteeIid')
    ..aOS(4, _omitFieldNames ? '' : 'role')
    ..pPS(5, _omitFieldNames ? '' : 'permissions')
    ..aOB(6, _omitFieldNames ? '' : 'isPinned')
    ..aOS(7, _omitFieldNames ? '' : 'metaJson')
    ..aInt64(8, _omitFieldNames ? '' : 'createdTsMs')
    ..aInt64(9, _omitFieldNames ? '' : 'updatedTsMs')
    ..aInt64(10, _omitFieldNames ? '' : 'deletedTsMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IdentityGrant clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IdentityGrant copyWith(void Function(IdentityGrant) updates) =>
      super.copyWith((message) => updates(message as IdentityGrant))
          as IdentityGrant;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use IdentityGrant() / IdentityGrant.new instead')
  static IdentityGrant create() => IdentityGrant._();
  static $pb.GeneratedMessage $_createMessage() => IdentityGrant._();
  @$core.override
  IdentityGrant createEmptyInstance() => IdentityGrant._();
  @$core.pragma('dart2js:noInline')
  static IdentityGrant getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<IdentityGrant>(
          IdentityGrant.$_createMessage);
  static IdentityGrant? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get resourceIid => $_getI64(1);
  @$pb.TagNumber(2)
  set resourceIid($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasResourceIid() => $_has(1);
  @$pb.TagNumber(2)
  void clearResourceIid() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get granteeIid => $_getI64(2);
  @$pb.TagNumber(3)
  set granteeIid($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasGranteeIid() => $_has(2);
  @$pb.TagNumber(3)
  void clearGranteeIid() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get role => $_getSZ(3);
  @$pb.TagNumber(4)
  set role($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasRole() => $_has(3);
  @$pb.TagNumber(4)
  void clearRole() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbList<$core.String> get permissions => $_getList(4);

  @$pb.TagNumber(6)
  $core.bool get isPinned => $_getBF(5);
  @$pb.TagNumber(6)
  set isPinned($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasIsPinned() => $_has(5);
  @$pb.TagNumber(6)
  void clearIsPinned() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get metaJson => $_getSZ(6);
  @$pb.TagNumber(7)
  set metaJson($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasMetaJson() => $_has(6);
  @$pb.TagNumber(7)
  void clearMetaJson() => $_clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get createdTsMs => $_getI64(7);
  @$pb.TagNumber(8)
  set createdTsMs($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(8)
  $core.bool hasCreatedTsMs() => $_has(7);
  @$pb.TagNumber(8)
  void clearCreatedTsMs() => $_clearField(8);

  @$pb.TagNumber(9)
  $fixnum.Int64 get updatedTsMs => $_getI64(8);
  @$pb.TagNumber(9)
  set updatedTsMs($fixnum.Int64 value) => $_setInt64(8, value);
  @$pb.TagNumber(9)
  $core.bool hasUpdatedTsMs() => $_has(8);
  @$pb.TagNumber(9)
  void clearUpdatedTsMs() => $_clearField(9);

  @$pb.TagNumber(10)
  $fixnum.Int64 get deletedTsMs => $_getI64(9);
  @$pb.TagNumber(10)
  set deletedTsMs($fixnum.Int64 value) => $_setInt64(9, value);
  @$pb.TagNumber(10)
  $core.bool hasDeletedTsMs() => $_has(9);
  @$pb.TagNumber(10)
  void clearDeletedTsMs() => $_clearField(10);
}

class IdentityRow extends $pb.GeneratedMessage {
  factory IdentityRow({
    $fixnum.Int64? iid,
    $core.String? kind,
    $core.String? type,
    $core.String? alienId,
    $core.String? name,
    $core.String? pic,
    $core.String? metaJson,
    $fixnum.Int64? ownerIid,
    $fixnum.Int64? updatedTsMs,
  }) {
    final result = IdentityRow._();
    if (iid != null) result.iid = iid;
    if (kind != null) result.kind = kind;
    if (type != null) result.type = type;
    if (alienId != null) result.alienId = alienId;
    if (name != null) result.name = name;
    if (pic != null) result.pic = pic;
    if (metaJson != null) result.metaJson = metaJson;
    if (ownerIid != null) result.ownerIid = ownerIid;
    if (updatedTsMs != null) result.updatedTsMs = updatedTsMs;
    return result;
  }

  IdentityRow._();

  factory IdentityRow.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      IdentityRow()..mergeFromBuffer(data, registry);
  factory IdentityRow.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      IdentityRow()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'IdentityRow',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: IdentityRow.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'iid')
    ..aOS(2, _omitFieldNames ? '' : 'kind')
    ..aOS(3, _omitFieldNames ? '' : 'type')
    ..aOS(4, _omitFieldNames ? '' : 'alienId')
    ..aOS(5, _omitFieldNames ? '' : 'name')
    ..aOS(6, _omitFieldNames ? '' : 'pic')
    ..aOS(7, _omitFieldNames ? '' : 'metaJson')
    ..aInt64(8, _omitFieldNames ? '' : 'ownerIid')
    ..aInt64(9, _omitFieldNames ? '' : 'updatedTsMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IdentityRow clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IdentityRow copyWith(void Function(IdentityRow) updates) =>
      super.copyWith((message) => updates(message as IdentityRow))
          as IdentityRow;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use IdentityRow() / IdentityRow.new instead')
  static IdentityRow create() => IdentityRow._();
  static $pb.GeneratedMessage $_createMessage() => IdentityRow._();
  @$core.override
  IdentityRow createEmptyInstance() => IdentityRow._();
  @$core.pragma('dart2js:noInline')
  static IdentityRow getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<IdentityRow>(
          IdentityRow.$_createMessage);
  static IdentityRow? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get iid => $_getI64(0);
  @$pb.TagNumber(1)
  set iid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearIid() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get kind => $_getSZ(1);
  @$pb.TagNumber(2)
  set kind($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasKind() => $_has(1);
  @$pb.TagNumber(2)
  void clearKind() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get type => $_getSZ(2);
  @$pb.TagNumber(3)
  set type($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasType() => $_has(2);
  @$pb.TagNumber(3)
  void clearType() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get alienId => $_getSZ(3);
  @$pb.TagNumber(4)
  set alienId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAlienId() => $_has(3);
  @$pb.TagNumber(4)
  void clearAlienId() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get name => $_getSZ(4);
  @$pb.TagNumber(5)
  set name($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasName() => $_has(4);
  @$pb.TagNumber(5)
  void clearName() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get pic => $_getSZ(5);
  @$pb.TagNumber(6)
  set pic($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasPic() => $_has(5);
  @$pb.TagNumber(6)
  void clearPic() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get metaJson => $_getSZ(6);
  @$pb.TagNumber(7)
  set metaJson($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasMetaJson() => $_has(6);
  @$pb.TagNumber(7)
  void clearMetaJson() => $_clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get ownerIid => $_getI64(7);
  @$pb.TagNumber(8)
  set ownerIid($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(8)
  $core.bool hasOwnerIid() => $_has(7);
  @$pb.TagNumber(8)
  void clearOwnerIid() => $_clearField(8);

  @$pb.TagNumber(9)
  $fixnum.Int64 get updatedTsMs => $_getI64(8);
  @$pb.TagNumber(9)
  set updatedTsMs($fixnum.Int64 value) => $_setInt64(8, value);
  @$pb.TagNumber(9)
  $core.bool hasUpdatedTsMs() => $_has(8);
  @$pb.TagNumber(9)
  void clearUpdatedTsMs() => $_clearField(9);
}

/// Per-viewer list row: identity + grant prefs for caller
class IdentityListRow extends $pb.GeneratedMessage {
  factory IdentityListRow({
    IdentityRow? identity,
    $core.String? grantRole,
    $core.bool? isPinned,
    $core.int? sortOrder,
    $fixnum.Int64? archivedTsMs,
  }) {
    final result = IdentityListRow._();
    if (identity != null) result.identity = identity;
    if (grantRole != null) result.grantRole = grantRole;
    if (isPinned != null) result.isPinned = isPinned;
    if (sortOrder != null) result.sortOrder = sortOrder;
    if (archivedTsMs != null) result.archivedTsMs = archivedTsMs;
    return result;
  }

  IdentityListRow._();

  factory IdentityListRow.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      IdentityListRow()..mergeFromBuffer(data, registry);
  factory IdentityListRow.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      IdentityListRow()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'IdentityListRow',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: IdentityListRow.$_createMessage)
    ..aOM<IdentityRow>(1, _omitFieldNames ? '' : 'identity',
        subBuilder: IdentityRow.$_createMessage)
    ..aOS(2, _omitFieldNames ? '' : 'grantRole')
    ..aOB(3, _omitFieldNames ? '' : 'isPinned')
    ..aI(4, _omitFieldNames ? '' : 'sortOrder')
    ..aInt64(5, _omitFieldNames ? '' : 'archivedTsMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IdentityListRow clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IdentityListRow copyWith(void Function(IdentityListRow) updates) =>
      super.copyWith((message) => updates(message as IdentityListRow))
          as IdentityListRow;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use IdentityListRow() / IdentityListRow.new instead')
  static IdentityListRow create() => IdentityListRow._();
  static $pb.GeneratedMessage $_createMessage() => IdentityListRow._();
  @$core.override
  IdentityListRow createEmptyInstance() => IdentityListRow._();
  @$core.pragma('dart2js:noInline')
  static IdentityListRow getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<IdentityListRow>(
          IdentityListRow.$_createMessage);
  static IdentityListRow? _defaultInstance;

  @$pb.TagNumber(1)
  IdentityRow get identity => $_getN(0);
  @$pb.TagNumber(1)
  set identity(IdentityRow value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasIdentity() => $_has(0);
  @$pb.TagNumber(1)
  void clearIdentity() => $_clearField(1);
  @$pb.TagNumber(1)
  IdentityRow ensureIdentity() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get grantRole => $_getSZ(1);
  @$pb.TagNumber(2)
  set grantRole($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasGrantRole() => $_has(1);
  @$pb.TagNumber(2)
  void clearGrantRole() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get isPinned => $_getBF(2);
  @$pb.TagNumber(3)
  set isPinned($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasIsPinned() => $_has(2);
  @$pb.TagNumber(3)
  void clearIsPinned() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get sortOrder => $_getIZ(3);
  @$pb.TagNumber(4)
  set sortOrder($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSortOrder() => $_has(3);
  @$pb.TagNumber(4)
  void clearSortOrder() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get archivedTsMs => $_getI64(4);
  @$pb.TagNumber(5)
  set archivedTsMs($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasArchivedTsMs() => $_has(4);
  @$pb.TagNumber(5)
  void clearArchivedTsMs() => $_clearField(5);
}

class ReqIdentityList extends $pb.GeneratedMessage {
  factory ReqIdentityList({
    $core.Iterable<$core.String>? kinds,
    $core.bool? includeArchived,
  }) {
    final result = ReqIdentityList._();
    if (kinds != null) result.kinds.addAll(kinds);
    if (includeArchived != null) result.includeArchived = includeArchived;
    return result;
  }

  ReqIdentityList._();

  factory ReqIdentityList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqIdentityList()..mergeFromBuffer(data, registry);
  factory ReqIdentityList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqIdentityList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqIdentityList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqIdentityList.$_createMessage)
    ..pPS(1, _omitFieldNames ? '' : 'kinds')
    ..aOB(2, _omitFieldNames ? '' : 'includeArchived')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqIdentityList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqIdentityList copyWith(void Function(ReqIdentityList) updates) =>
      super.copyWith((message) => updates(message as ReqIdentityList))
          as ReqIdentityList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqIdentityList() / ReqIdentityList.new instead')
  static ReqIdentityList create() => ReqIdentityList._();
  static $pb.GeneratedMessage $_createMessage() => ReqIdentityList._();
  @$core.override
  ReqIdentityList createEmptyInstance() => ReqIdentityList._();
  @$core.pragma('dart2js:noInline')
  static ReqIdentityList getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqIdentityList>(
          ReqIdentityList.$_createMessage);
  static ReqIdentityList? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get kinds => $_getList(0);

  @$pb.TagNumber(2)
  $core.bool get includeArchived => $_getBF(1);
  @$pb.TagNumber(2)
  set includeArchived($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasIncludeArchived() => $_has(1);
  @$pb.TagNumber(2)
  void clearIncludeArchived() => $_clearField(2);
}

class ResIdentityList extends $pb.GeneratedMessage {
  factory ResIdentityList({
    $core.Iterable<IdentityListRow>? rows,
  }) {
    final result = ResIdentityList._();
    if (rows != null) result.rows.addAll(rows);
    return result;
  }

  ResIdentityList._();

  factory ResIdentityList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResIdentityList()..mergeFromBuffer(data, registry);
  factory ResIdentityList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResIdentityList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResIdentityList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResIdentityList.$_createMessage)
    ..pPM<IdentityListRow>(1, _omitFieldNames ? '' : 'rows',
        subBuilder: IdentityListRow.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResIdentityList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResIdentityList copyWith(void Function(ResIdentityList) updates) =>
      super.copyWith((message) => updates(message as ResIdentityList))
          as ResIdentityList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResIdentityList() / ResIdentityList.new instead')
  static ResIdentityList create() => ResIdentityList._();
  static $pb.GeneratedMessage $_createMessage() => ResIdentityList._();
  @$core.override
  ResIdentityList createEmptyInstance() => ResIdentityList._();
  @$core.pragma('dart2js:noInline')
  static ResIdentityList getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResIdentityList>(
          ResIdentityList.$_createMessage);
  static ResIdentityList? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<IdentityListRow> get rows => $_getList(0);
}

class ReqIdentityGrantPatch extends $pb.GeneratedMessage {
  factory ReqIdentityGrantPatch({
    $fixnum.Int64? resourceIid,
    $core.bool? isPinned,
    $core.int? sortOrder,
    $core.bool? archived,
  }) {
    final result = ReqIdentityGrantPatch._();
    if (resourceIid != null) result.resourceIid = resourceIid;
    if (isPinned != null) result.isPinned = isPinned;
    if (sortOrder != null) result.sortOrder = sortOrder;
    if (archived != null) result.archived = archived;
    return result;
  }

  ReqIdentityGrantPatch._();

  factory ReqIdentityGrantPatch.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqIdentityGrantPatch()..mergeFromBuffer(data, registry);
  factory ReqIdentityGrantPatch.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqIdentityGrantPatch()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqIdentityGrantPatch',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqIdentityGrantPatch.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'resourceIid')
    ..aOB(2, _omitFieldNames ? '' : 'isPinned')
    ..aI(3, _omitFieldNames ? '' : 'sortOrder')
    ..aOB(4, _omitFieldNames ? '' : 'archived')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqIdentityGrantPatch clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqIdentityGrantPatch copyWith(
          void Function(ReqIdentityGrantPatch) updates) =>
      super.copyWith((message) => updates(message as ReqIdentityGrantPatch))
          as ReqIdentityGrantPatch;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ReqIdentityGrantPatch() / ReqIdentityGrantPatch.new instead')
  static ReqIdentityGrantPatch create() => ReqIdentityGrantPatch._();
  static $pb.GeneratedMessage $_createMessage() => ReqIdentityGrantPatch._();
  @$core.override
  ReqIdentityGrantPatch createEmptyInstance() => ReqIdentityGrantPatch._();
  @$core.pragma('dart2js:noInline')
  static ReqIdentityGrantPatch getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqIdentityGrantPatch>(
          ReqIdentityGrantPatch.$_createMessage);
  static ReqIdentityGrantPatch? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get resourceIid => $_getI64(0);
  @$pb.TagNumber(1)
  set resourceIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasResourceIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearResourceIid() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get isPinned => $_getBF(1);
  @$pb.TagNumber(2)
  set isPinned($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasIsPinned() => $_has(1);
  @$pb.TagNumber(2)
  void clearIsPinned() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get sortOrder => $_getIZ(2);
  @$pb.TagNumber(3)
  set sortOrder($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSortOrder() => $_has(2);
  @$pb.TagNumber(3)
  void clearSortOrder() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get archived => $_getBF(3);
  @$pb.TagNumber(4)
  set archived($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasArchived() => $_has(3);
  @$pb.TagNumber(4)
  void clearArchived() => $_clearField(4);
}

class ResIdentityGrantPatch extends $pb.GeneratedMessage {
  factory ResIdentityGrantPatch({
    IdentityListRow? row,
  }) {
    final result = ResIdentityGrantPatch._();
    if (row != null) result.row = row;
    return result;
  }

  ResIdentityGrantPatch._();

  factory ResIdentityGrantPatch.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResIdentityGrantPatch()..mergeFromBuffer(data, registry);
  factory ResIdentityGrantPatch.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResIdentityGrantPatch()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResIdentityGrantPatch',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResIdentityGrantPatch.$_createMessage)
    ..aOM<IdentityListRow>(1, _omitFieldNames ? '' : 'row',
        subBuilder: IdentityListRow.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResIdentityGrantPatch clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResIdentityGrantPatch copyWith(
          void Function(ResIdentityGrantPatch) updates) =>
      super.copyWith((message) => updates(message as ResIdentityGrantPatch))
          as ResIdentityGrantPatch;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ResIdentityGrantPatch() / ResIdentityGrantPatch.new instead')
  static ResIdentityGrantPatch create() => ResIdentityGrantPatch._();
  static $pb.GeneratedMessage $_createMessage() => ResIdentityGrantPatch._();
  @$core.override
  ResIdentityGrantPatch createEmptyInstance() => ResIdentityGrantPatch._();
  @$core.pragma('dart2js:noInline')
  static ResIdentityGrantPatch getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResIdentityGrantPatch>(
          ResIdentityGrantPatch.$_createMessage);
  static ResIdentityGrantPatch? _defaultInstance;

  @$pb.TagNumber(1)
  IdentityListRow get row => $_getN(0);
  @$pb.TagNumber(1)
  set row(IdentityListRow value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasRow() => $_has(0);
  @$pb.TagNumber(1)
  void clearRow() => $_clearField(1);
  @$pb.TagNumber(1)
  IdentityListRow ensureRow() => $_ensure(0);
}

class ReqIdentityPut extends $pb.GeneratedMessage {
  factory ReqIdentityPut({
    $fixnum.Int64? iid,
    $core.String? kind,
    $core.String? type,
    $core.String? name,
    $core.String? pic,
    $core.String? alienId,
    $core.String? metaJson,
  }) {
    final result = ReqIdentityPut._();
    if (iid != null) result.iid = iid;
    if (kind != null) result.kind = kind;
    if (type != null) result.type = type;
    if (name != null) result.name = name;
    if (pic != null) result.pic = pic;
    if (alienId != null) result.alienId = alienId;
    if (metaJson != null) result.metaJson = metaJson;
    return result;
  }

  ReqIdentityPut._();

  factory ReqIdentityPut.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqIdentityPut()..mergeFromBuffer(data, registry);
  factory ReqIdentityPut.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqIdentityPut()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqIdentityPut',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqIdentityPut.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'iid')
    ..aOS(2, _omitFieldNames ? '' : 'kind')
    ..aOS(3, _omitFieldNames ? '' : 'type')
    ..aOS(4, _omitFieldNames ? '' : 'name')
    ..aOS(5, _omitFieldNames ? '' : 'pic')
    ..aOS(6, _omitFieldNames ? '' : 'alienId')
    ..aOS(7, _omitFieldNames ? '' : 'metaJson')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqIdentityPut clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqIdentityPut copyWith(void Function(ReqIdentityPut) updates) =>
      super.copyWith((message) => updates(message as ReqIdentityPut))
          as ReqIdentityPut;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqIdentityPut() / ReqIdentityPut.new instead')
  static ReqIdentityPut create() => ReqIdentityPut._();
  static $pb.GeneratedMessage $_createMessage() => ReqIdentityPut._();
  @$core.override
  ReqIdentityPut createEmptyInstance() => ReqIdentityPut._();
  @$core.pragma('dart2js:noInline')
  static ReqIdentityPut getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqIdentityPut>(
          ReqIdentityPut.$_createMessage);
  static ReqIdentityPut? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get iid => $_getI64(0);
  @$pb.TagNumber(1)
  set iid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearIid() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get kind => $_getSZ(1);
  @$pb.TagNumber(2)
  set kind($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasKind() => $_has(1);
  @$pb.TagNumber(2)
  void clearKind() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get type => $_getSZ(2);
  @$pb.TagNumber(3)
  set type($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasType() => $_has(2);
  @$pb.TagNumber(3)
  void clearType() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get name => $_getSZ(3);
  @$pb.TagNumber(4)
  set name($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasName() => $_has(3);
  @$pb.TagNumber(4)
  void clearName() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get pic => $_getSZ(4);
  @$pb.TagNumber(5)
  set pic($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasPic() => $_has(4);
  @$pb.TagNumber(5)
  void clearPic() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get alienId => $_getSZ(5);
  @$pb.TagNumber(6)
  set alienId($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasAlienId() => $_has(5);
  @$pb.TagNumber(6)
  void clearAlienId() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get metaJson => $_getSZ(6);
  @$pb.TagNumber(7)
  set metaJson($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasMetaJson() => $_has(6);
  @$pb.TagNumber(7)
  void clearMetaJson() => $_clearField(7);
}

class ResIdentityPut extends $pb.GeneratedMessage {
  factory ResIdentityPut({
    IdentityListRow? row,
  }) {
    final result = ResIdentityPut._();
    if (row != null) result.row = row;
    return result;
  }

  ResIdentityPut._();

  factory ResIdentityPut.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResIdentityPut()..mergeFromBuffer(data, registry);
  factory ResIdentityPut.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResIdentityPut()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResIdentityPut',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResIdentityPut.$_createMessage)
    ..aOM<IdentityListRow>(1, _omitFieldNames ? '' : 'row',
        subBuilder: IdentityListRow.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResIdentityPut clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResIdentityPut copyWith(void Function(ResIdentityPut) updates) =>
      super.copyWith((message) => updates(message as ResIdentityPut))
          as ResIdentityPut;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResIdentityPut() / ResIdentityPut.new instead')
  static ResIdentityPut create() => ResIdentityPut._();
  static $pb.GeneratedMessage $_createMessage() => ResIdentityPut._();
  @$core.override
  ResIdentityPut createEmptyInstance() => ResIdentityPut._();
  @$core.pragma('dart2js:noInline')
  static ResIdentityPut getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResIdentityPut>(
          ResIdentityPut.$_createMessage);
  static ResIdentityPut? _defaultInstance;

  @$pb.TagNumber(1)
  IdentityListRow get row => $_getN(0);
  @$pb.TagNumber(1)
  set row(IdentityListRow value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasRow() => $_has(0);
  @$pb.TagNumber(1)
  void clearRow() => $_clearField(1);
  @$pb.TagNumber(1)
  IdentityListRow ensureRow() => $_ensure(0);
}

class ReqIdentityDelete extends $pb.GeneratedMessage {
  factory ReqIdentityDelete({
    $fixnum.Int64? iid,
  }) {
    final result = ReqIdentityDelete._();
    if (iid != null) result.iid = iid;
    return result;
  }

  ReqIdentityDelete._();

  factory ReqIdentityDelete.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqIdentityDelete()..mergeFromBuffer(data, registry);
  factory ReqIdentityDelete.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqIdentityDelete()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqIdentityDelete',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqIdentityDelete.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'iid')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqIdentityDelete clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqIdentityDelete copyWith(void Function(ReqIdentityDelete) updates) =>
      super.copyWith((message) => updates(message as ReqIdentityDelete))
          as ReqIdentityDelete;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqIdentityDelete() / ReqIdentityDelete.new instead')
  static ReqIdentityDelete create() => ReqIdentityDelete._();
  static $pb.GeneratedMessage $_createMessage() => ReqIdentityDelete._();
  @$core.override
  ReqIdentityDelete createEmptyInstance() => ReqIdentityDelete._();
  @$core.pragma('dart2js:noInline')
  static ReqIdentityDelete getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqIdentityDelete>(
          ReqIdentityDelete.$_createMessage);
  static ReqIdentityDelete? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get iid => $_getI64(0);
  @$pb.TagNumber(1)
  set iid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearIid() => $_clearField(1);
}

class ResIdentityDelete extends $pb.GeneratedMessage {
  factory ResIdentityDelete({
    $core.bool? ok,
    $core.String? error,
  }) {
    final result = ResIdentityDelete._();
    if (ok != null) result.ok = ok;
    if (error != null) result.error = error;
    return result;
  }

  ResIdentityDelete._();

  factory ResIdentityDelete.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResIdentityDelete()..mergeFromBuffer(data, registry);
  factory ResIdentityDelete.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResIdentityDelete()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResIdentityDelete',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResIdentityDelete.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'ok')
    ..aOS(2, _omitFieldNames ? '' : 'error')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResIdentityDelete clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResIdentityDelete copyWith(void Function(ResIdentityDelete) updates) =>
      super.copyWith((message) => updates(message as ResIdentityDelete))
          as ResIdentityDelete;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResIdentityDelete() / ResIdentityDelete.new instead')
  static ResIdentityDelete create() => ResIdentityDelete._();
  static $pb.GeneratedMessage $_createMessage() => ResIdentityDelete._();
  @$core.override
  ResIdentityDelete createEmptyInstance() => ResIdentityDelete._();
  @$core.pragma('dart2js:noInline')
  static ResIdentityDelete getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResIdentityDelete>(
          ResIdentityDelete.$_createMessage);
  static ResIdentityDelete? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get ok => $_getBF(0);
  @$pb.TagNumber(1)
  set ok($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOk() => $_has(0);
  @$pb.TagNumber(1)
  void clearOk() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get error => $_getSZ(1);
  @$pb.TagNumber(2)
  set error($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
