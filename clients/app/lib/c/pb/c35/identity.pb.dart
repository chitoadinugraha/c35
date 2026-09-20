//
//  Generated code. Do not modify.
//  source: c35/identity.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

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
  }) {
    final $result = create();
    if (iid != null) {
      $result.iid = iid;
    }
    if (kind != null) {
      $result.kind = kind;
    }
    if (type != null) {
      $result.type = type;
    }
    if (alienId != null) {
      $result.alienId = alienId;
    }
    if (name != null) {
      $result.name = name;
    }
    if (pic != null) {
      $result.pic = pic;
    }
    if (locale != null) {
      $result.locale = locale;
    }
    if (tz != null) {
      $result.tz = tz;
    }
    if (billingIid != null) {
      $result.billingIid = billingIid;
    }
    if (isRoot != null) {
      $result.isRoot = isRoot;
    }
    return $result;
  }
  IdentityProfile._() : super();
  factory IdentityProfile.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory IdentityProfile.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'IdentityProfile', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
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
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  IdentityProfile clone() => IdentityProfile()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  IdentityProfile copyWith(void Function(IdentityProfile) updates) => super.copyWith((message) => updates(message as IdentityProfile)) as IdentityProfile;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static IdentityProfile create() => IdentityProfile._();
  IdentityProfile createEmptyInstance() => create();
  static $pb.PbList<IdentityProfile> createRepeated() => $pb.PbList<IdentityProfile>();
  @$core.pragma('dart2js:noInline')
  static IdentityProfile getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<IdentityProfile>(create);
  static IdentityProfile? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get iid => $_getI64(0);
  @$pb.TagNumber(1)
  set iid($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearIid() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get kind => $_getSZ(1);
  @$pb.TagNumber(2)
  set kind($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasKind() => $_has(1);
  @$pb.TagNumber(2)
  void clearKind() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get type => $_getSZ(2);
  @$pb.TagNumber(3)
  set type($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasType() => $_has(2);
  @$pb.TagNumber(3)
  void clearType() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get alienId => $_getSZ(3);
  @$pb.TagNumber(4)
  set alienId($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasAlienId() => $_has(3);
  @$pb.TagNumber(4)
  void clearAlienId() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get name => $_getSZ(4);
  @$pb.TagNumber(5)
  set name($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasName() => $_has(4);
  @$pb.TagNumber(5)
  void clearName() => clearField(5);

  @$pb.TagNumber(6)
  $core.String get pic => $_getSZ(5);
  @$pb.TagNumber(6)
  set pic($core.String v) { $_setString(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasPic() => $_has(5);
  @$pb.TagNumber(6)
  void clearPic() => clearField(6);

  @$pb.TagNumber(7)
  $core.String get locale => $_getSZ(6);
  @$pb.TagNumber(7)
  set locale($core.String v) { $_setString(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasLocale() => $_has(6);
  @$pb.TagNumber(7)
  void clearLocale() => clearField(7);

  @$pb.TagNumber(8)
  $core.String get tz => $_getSZ(7);
  @$pb.TagNumber(8)
  set tz($core.String v) { $_setString(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasTz() => $_has(7);
  @$pb.TagNumber(8)
  void clearTz() => clearField(8);

  @$pb.TagNumber(9)
  $fixnum.Int64 get billingIid => $_getI64(8);
  @$pb.TagNumber(9)
  set billingIid($fixnum.Int64 v) { $_setInt64(8, v); }
  @$pb.TagNumber(9)
  $core.bool hasBillingIid() => $_has(8);
  @$pb.TagNumber(9)
  void clearBillingIid() => clearField(9);

  @$pb.TagNumber(10)
  $core.bool get isRoot => $_getBF(9);
  @$pb.TagNumber(10)
  set isRoot($core.bool v) { $_setBool(9, v); }
  @$pb.TagNumber(10)
  $core.bool hasIsRoot() => $_has(9);
  @$pb.TagNumber(10)
  void clearIsRoot() => clearField(10);
}

class NavCounts extends $pb.GeneratedMessage {
  factory NavCounts({
    $core.int? bots,
    $core.int? devices,
    $core.int? sites,
  }) {
    final $result = create();
    if (bots != null) {
      $result.bots = bots;
    }
    if (devices != null) {
      $result.devices = devices;
    }
    if (sites != null) {
      $result.sites = sites;
    }
    return $result;
  }
  NavCounts._() : super();
  factory NavCounts.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory NavCounts.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'NavCounts', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'bots', $pb.PbFieldType.O3)
    ..a<$core.int>(2, _omitFieldNames ? '' : 'devices', $pb.PbFieldType.O3)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'sites', $pb.PbFieldType.O3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  NavCounts clone() => NavCounts()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  NavCounts copyWith(void Function(NavCounts) updates) => super.copyWith((message) => updates(message as NavCounts)) as NavCounts;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NavCounts create() => NavCounts._();
  NavCounts createEmptyInstance() => create();
  static $pb.PbList<NavCounts> createRepeated() => $pb.PbList<NavCounts>();
  @$core.pragma('dart2js:noInline')
  static NavCounts getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<NavCounts>(create);
  static NavCounts? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get bots => $_getIZ(0);
  @$pb.TagNumber(1)
  set bots($core.int v) { $_setSignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasBots() => $_has(0);
  @$pb.TagNumber(1)
  void clearBots() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get devices => $_getIZ(1);
  @$pb.TagNumber(2)
  set devices($core.int v) { $_setSignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasDevices() => $_has(1);
  @$pb.TagNumber(2)
  void clearDevices() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get sites => $_getIZ(2);
  @$pb.TagNumber(3)
  set sites($core.int v) { $_setSignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasSites() => $_has(2);
  @$pb.TagNumber(3)
  void clearSites() => clearField(3);
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
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    if (resourceIid != null) {
      $result.resourceIid = resourceIid;
    }
    if (granteeIid != null) {
      $result.granteeIid = granteeIid;
    }
    if (role != null) {
      $result.role = role;
    }
    if (permissions != null) {
      $result.permissions.addAll(permissions);
    }
    if (isPinned != null) {
      $result.isPinned = isPinned;
    }
    if (metaJson != null) {
      $result.metaJson = metaJson;
    }
    if (createdTsMs != null) {
      $result.createdTsMs = createdTsMs;
    }
    if (updatedTsMs != null) {
      $result.updatedTsMs = updatedTsMs;
    }
    if (deletedTsMs != null) {
      $result.deletedTsMs = deletedTsMs;
    }
    return $result;
  }
  IdentityGrant._() : super();
  factory IdentityGrant.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory IdentityGrant.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'IdentityGrant', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
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
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  IdentityGrant clone() => IdentityGrant()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  IdentityGrant copyWith(void Function(IdentityGrant) updates) => super.copyWith((message) => updates(message as IdentityGrant)) as IdentityGrant;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static IdentityGrant create() => IdentityGrant._();
  IdentityGrant createEmptyInstance() => create();
  static $pb.PbList<IdentityGrant> createRepeated() => $pb.PbList<IdentityGrant>();
  @$core.pragma('dart2js:noInline')
  static IdentityGrant getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<IdentityGrant>(create);
  static IdentityGrant? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get resourceIid => $_getI64(1);
  @$pb.TagNumber(2)
  set resourceIid($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasResourceIid() => $_has(1);
  @$pb.TagNumber(2)
  void clearResourceIid() => clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get granteeIid => $_getI64(2);
  @$pb.TagNumber(3)
  set granteeIid($fixnum.Int64 v) { $_setInt64(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasGranteeIid() => $_has(2);
  @$pb.TagNumber(3)
  void clearGranteeIid() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get role => $_getSZ(3);
  @$pb.TagNumber(4)
  set role($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasRole() => $_has(3);
  @$pb.TagNumber(4)
  void clearRole() => clearField(4);

  @$pb.TagNumber(5)
  $core.List<$core.String> get permissions => $_getList(4);

  @$pb.TagNumber(6)
  $core.bool get isPinned => $_getBF(5);
  @$pb.TagNumber(6)
  set isPinned($core.bool v) { $_setBool(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasIsPinned() => $_has(5);
  @$pb.TagNumber(6)
  void clearIsPinned() => clearField(6);

  @$pb.TagNumber(7)
  $core.String get metaJson => $_getSZ(6);
  @$pb.TagNumber(7)
  set metaJson($core.String v) { $_setString(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasMetaJson() => $_has(6);
  @$pb.TagNumber(7)
  void clearMetaJson() => clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get createdTsMs => $_getI64(7);
  @$pb.TagNumber(8)
  set createdTsMs($fixnum.Int64 v) { $_setInt64(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasCreatedTsMs() => $_has(7);
  @$pb.TagNumber(8)
  void clearCreatedTsMs() => clearField(8);

  @$pb.TagNumber(9)
  $fixnum.Int64 get updatedTsMs => $_getI64(8);
  @$pb.TagNumber(9)
  set updatedTsMs($fixnum.Int64 v) { $_setInt64(8, v); }
  @$pb.TagNumber(9)
  $core.bool hasUpdatedTsMs() => $_has(8);
  @$pb.TagNumber(9)
  void clearUpdatedTsMs() => clearField(9);

  @$pb.TagNumber(10)
  $fixnum.Int64 get deletedTsMs => $_getI64(9);
  @$pb.TagNumber(10)
  set deletedTsMs($fixnum.Int64 v) { $_setInt64(9, v); }
  @$pb.TagNumber(10)
  $core.bool hasDeletedTsMs() => $_has(9);
  @$pb.TagNumber(10)
  void clearDeletedTsMs() => clearField(10);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
