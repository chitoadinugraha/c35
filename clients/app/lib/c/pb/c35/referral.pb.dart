// This is a generated file - do not edit.
//
// Generated from c35/referral.proto.

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

class ReferralCodeDoc extends $pb.GeneratedMessage {
  factory ReferralCodeDoc({
    $core.String? code,
    $core.String? type,
    $core.String? name,
    $fixnum.Int64? issuedBy,
    $core.double? priceUsd,
    $core.int? durationMonths,
    $core.String? basePlanSlug,
    $core.int? maxUses,
    $core.int? usedCount,
    $fixnum.Int64? expiresAtMs,
  }) {
    final result = ReferralCodeDoc._();
    if (code != null) result.code = code;
    if (type != null) result.type = type;
    if (name != null) result.name = name;
    if (issuedBy != null) result.issuedBy = issuedBy;
    if (priceUsd != null) result.priceUsd = priceUsd;
    if (durationMonths != null) result.durationMonths = durationMonths;
    if (basePlanSlug != null) result.basePlanSlug = basePlanSlug;
    if (maxUses != null) result.maxUses = maxUses;
    if (usedCount != null) result.usedCount = usedCount;
    if (expiresAtMs != null) result.expiresAtMs = expiresAtMs;
    return result;
  }

  ReferralCodeDoc._();

  factory ReferralCodeDoc.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReferralCodeDoc()..mergeFromBuffer(data, registry);
  factory ReferralCodeDoc.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReferralCodeDoc()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReferralCodeDoc',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReferralCodeDoc.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'code')
    ..aOS(2, _omitFieldNames ? '' : 'type')
    ..aOS(3, _omitFieldNames ? '' : 'name')
    ..aInt64(4, _omitFieldNames ? '' : 'issuedBy')
    ..aD(5, _omitFieldNames ? '' : 'priceUsd')
    ..aI(6, _omitFieldNames ? '' : 'durationMonths')
    ..aOS(7, _omitFieldNames ? '' : 'basePlanSlug')
    ..aI(8, _omitFieldNames ? '' : 'maxUses')
    ..aI(9, _omitFieldNames ? '' : 'usedCount')
    ..aInt64(10, _omitFieldNames ? '' : 'expiresAtMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReferralCodeDoc clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReferralCodeDoc copyWith(void Function(ReferralCodeDoc) updates) =>
      super.copyWith((message) => updates(message as ReferralCodeDoc))
          as ReferralCodeDoc;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReferralCodeDoc() / ReferralCodeDoc.new instead')
  static ReferralCodeDoc create() => ReferralCodeDoc._();
  static $pb.GeneratedMessage $_createMessage() => ReferralCodeDoc._();
  @$core.override
  ReferralCodeDoc createEmptyInstance() => ReferralCodeDoc._();
  @$core.pragma('dart2js:noInline')
  static ReferralCodeDoc getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReferralCodeDoc>(
          ReferralCodeDoc.$_createMessage);
  static ReferralCodeDoc? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get code => $_getSZ(0);
  @$pb.TagNumber(1)
  set code($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCode() => $_has(0);
  @$pb.TagNumber(1)
  void clearCode() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get type => $_getSZ(1);
  @$pb.TagNumber(2)
  set type($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasType() => $_has(1);
  @$pb.TagNumber(2)
  void clearType() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get name => $_getSZ(2);
  @$pb.TagNumber(3)
  set name($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasName() => $_has(2);
  @$pb.TagNumber(3)
  void clearName() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get issuedBy => $_getI64(3);
  @$pb.TagNumber(4)
  set issuedBy($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasIssuedBy() => $_has(3);
  @$pb.TagNumber(4)
  void clearIssuedBy() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.double get priceUsd => $_getN(4);
  @$pb.TagNumber(5)
  set priceUsd($core.double value) => $_setDouble(4, value);
  @$pb.TagNumber(5)
  $core.bool hasPriceUsd() => $_has(4);
  @$pb.TagNumber(5)
  void clearPriceUsd() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get durationMonths => $_getIZ(5);
  @$pb.TagNumber(6)
  set durationMonths($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasDurationMonths() => $_has(5);
  @$pb.TagNumber(6)
  void clearDurationMonths() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get basePlanSlug => $_getSZ(6);
  @$pb.TagNumber(7)
  set basePlanSlug($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasBasePlanSlug() => $_has(6);
  @$pb.TagNumber(7)
  void clearBasePlanSlug() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.int get maxUses => $_getIZ(7);
  @$pb.TagNumber(8)
  set maxUses($core.int value) => $_setSignedInt32(7, value);
  @$pb.TagNumber(8)
  $core.bool hasMaxUses() => $_has(7);
  @$pb.TagNumber(8)
  void clearMaxUses() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.int get usedCount => $_getIZ(8);
  @$pb.TagNumber(9)
  set usedCount($core.int value) => $_setSignedInt32(8, value);
  @$pb.TagNumber(9)
  $core.bool hasUsedCount() => $_has(8);
  @$pb.TagNumber(9)
  void clearUsedCount() => $_clearField(9);

  @$pb.TagNumber(10)
  $fixnum.Int64 get expiresAtMs => $_getI64(9);
  @$pb.TagNumber(10)
  set expiresAtMs($fixnum.Int64 value) => $_setInt64(9, value);
  @$pb.TagNumber(10)
  $core.bool hasExpiresAtMs() => $_has(9);
  @$pb.TagNumber(10)
  void clearExpiresAtMs() => $_clearField(10);
}

class ReferralShareDoc extends $pb.GeneratedMessage {
  factory ReferralShareDoc({
    $fixnum.Int64? parentUid,
    $fixnum.Int64? childUid,
    $core.int? sharePercent,
  }) {
    final result = ReferralShareDoc._();
    if (parentUid != null) result.parentUid = parentUid;
    if (childUid != null) result.childUid = childUid;
    if (sharePercent != null) result.sharePercent = sharePercent;
    return result;
  }

  ReferralShareDoc._();

  factory ReferralShareDoc.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReferralShareDoc()..mergeFromBuffer(data, registry);
  factory ReferralShareDoc.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReferralShareDoc()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReferralShareDoc',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReferralShareDoc.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'parentUid')
    ..aInt64(2, _omitFieldNames ? '' : 'childUid')
    ..aI(3, _omitFieldNames ? '' : 'sharePercent')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReferralShareDoc clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReferralShareDoc copyWith(void Function(ReferralShareDoc) updates) =>
      super.copyWith((message) => updates(message as ReferralShareDoc))
          as ReferralShareDoc;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReferralShareDoc() / ReferralShareDoc.new instead')
  static ReferralShareDoc create() => ReferralShareDoc._();
  static $pb.GeneratedMessage $_createMessage() => ReferralShareDoc._();
  @$core.override
  ReferralShareDoc createEmptyInstance() => ReferralShareDoc._();
  @$core.pragma('dart2js:noInline')
  static ReferralShareDoc getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReferralShareDoc>(
          ReferralShareDoc.$_createMessage);
  static ReferralShareDoc? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get parentUid => $_getI64(0);
  @$pb.TagNumber(1)
  set parentUid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasParentUid() => $_has(0);
  @$pb.TagNumber(1)
  void clearParentUid() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get childUid => $_getI64(1);
  @$pb.TagNumber(2)
  set childUid($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasChildUid() => $_has(1);
  @$pb.TagNumber(2)
  void clearChildUid() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get sharePercent => $_getIZ(2);
  @$pb.TagNumber(3)
  set sharePercent($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSharePercent() => $_has(2);
  @$pb.TagNumber(3)
  void clearSharePercent() => $_clearField(3);
}

class ReferralTreeNode extends $pb.GeneratedMessage {
  factory ReferralTreeNode({
    $fixnum.Int64? identityId,
    $core.String? name,
    $core.String? email,
    $core.String? avatarUrl,
    $core.String? handle,
    $fixnum.Int64? referredBy,
    $core.int? childCount,
    $core.bool? isRoot,
    $core.bool? isBanned,
    $core.Iterable<$core.String>? globalRoles,
  }) {
    final result = ReferralTreeNode._();
    if (identityId != null) result.identityId = identityId;
    if (name != null) result.name = name;
    if (email != null) result.email = email;
    if (avatarUrl != null) result.avatarUrl = avatarUrl;
    if (handle != null) result.handle = handle;
    if (referredBy != null) result.referredBy = referredBy;
    if (childCount != null) result.childCount = childCount;
    if (isRoot != null) result.isRoot = isRoot;
    if (isBanned != null) result.isBanned = isBanned;
    if (globalRoles != null) result.globalRoles.addAll(globalRoles);
    return result;
  }

  ReferralTreeNode._();

  factory ReferralTreeNode.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReferralTreeNode()..mergeFromBuffer(data, registry);
  factory ReferralTreeNode.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReferralTreeNode()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReferralTreeNode',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReferralTreeNode.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'identityId')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOS(3, _omitFieldNames ? '' : 'email')
    ..aOS(4, _omitFieldNames ? '' : 'avatarUrl')
    ..aOS(5, _omitFieldNames ? '' : 'handle')
    ..aInt64(6, _omitFieldNames ? '' : 'referredBy')
    ..aI(7, _omitFieldNames ? '' : 'childCount')
    ..aOB(8, _omitFieldNames ? '' : 'isRoot')
    ..aOB(9, _omitFieldNames ? '' : 'isBanned')
    ..pPS(10, _omitFieldNames ? '' : 'globalRoles')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReferralTreeNode clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReferralTreeNode copyWith(void Function(ReferralTreeNode) updates) =>
      super.copyWith((message) => updates(message as ReferralTreeNode))
          as ReferralTreeNode;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReferralTreeNode() / ReferralTreeNode.new instead')
  static ReferralTreeNode create() => ReferralTreeNode._();
  static $pb.GeneratedMessage $_createMessage() => ReferralTreeNode._();
  @$core.override
  ReferralTreeNode createEmptyInstance() => ReferralTreeNode._();
  @$core.pragma('dart2js:noInline')
  static ReferralTreeNode getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReferralTreeNode>(
          ReferralTreeNode.$_createMessage);
  static ReferralTreeNode? _defaultInstance;

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

  @$pb.TagNumber(6)
  $fixnum.Int64 get referredBy => $_getI64(5);
  @$pb.TagNumber(6)
  set referredBy($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasReferredBy() => $_has(5);
  @$pb.TagNumber(6)
  void clearReferredBy() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.int get childCount => $_getIZ(6);
  @$pb.TagNumber(7)
  set childCount($core.int value) => $_setSignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasChildCount() => $_has(6);
  @$pb.TagNumber(7)
  void clearChildCount() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.bool get isRoot => $_getBF(7);
  @$pb.TagNumber(8)
  set isRoot($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasIsRoot() => $_has(7);
  @$pb.TagNumber(8)
  void clearIsRoot() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.bool get isBanned => $_getBF(8);
  @$pb.TagNumber(9)
  set isBanned($core.bool value) => $_setBool(8, value);
  @$pb.TagNumber(9)
  $core.bool hasIsBanned() => $_has(8);
  @$pb.TagNumber(9)
  void clearIsBanned() => $_clearField(9);

  @$pb.TagNumber(10)
  $pb.PbList<$core.String> get globalRoles => $_getList(9);
}

class ReferralTreeSlice extends $pb.GeneratedMessage {
  factory ReferralTreeSlice({
    $core.Iterable<ReferralTreeNode>? nodes,
    $core.Iterable<ReferralShareDoc>? branchShares,
  }) {
    final result = ReferralTreeSlice._();
    if (nodes != null) result.nodes.addAll(nodes);
    if (branchShares != null) result.branchShares.addAll(branchShares);
    return result;
  }

  ReferralTreeSlice._();

  factory ReferralTreeSlice.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReferralTreeSlice()..mergeFromBuffer(data, registry);
  factory ReferralTreeSlice.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReferralTreeSlice()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReferralTreeSlice',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReferralTreeSlice.$_createMessage)
    ..pPM<ReferralTreeNode>(1, _omitFieldNames ? '' : 'nodes',
        subBuilder: ReferralTreeNode.$_createMessage)
    ..pPM<ReferralShareDoc>(2, _omitFieldNames ? '' : 'branchShares',
        subBuilder: ReferralShareDoc.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReferralTreeSlice clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReferralTreeSlice copyWith(void Function(ReferralTreeSlice) updates) =>
      super.copyWith((message) => updates(message as ReferralTreeSlice))
          as ReferralTreeSlice;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReferralTreeSlice() / ReferralTreeSlice.new instead')
  static ReferralTreeSlice create() => ReferralTreeSlice._();
  static $pb.GeneratedMessage $_createMessage() => ReferralTreeSlice._();
  @$core.override
  ReferralTreeSlice createEmptyInstance() => ReferralTreeSlice._();
  @$core.pragma('dart2js:noInline')
  static ReferralTreeSlice getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReferralTreeSlice>(
          ReferralTreeSlice.$_createMessage);
  static ReferralTreeSlice? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<ReferralTreeNode> get nodes => $_getList(0);

  @$pb.TagNumber(2)
  $pb.PbList<ReferralShareDoc> get branchShares => $_getList(1);
}

class ReqReferralShareSet extends $pb.GeneratedMessage {
  factory ReqReferralShareSet({
    $fixnum.Int64? parentUid,
    $fixnum.Int64? childUid,
    $core.int? sharePercent,
  }) {
    final result = ReqReferralShareSet._();
    if (parentUid != null) result.parentUid = parentUid;
    if (childUid != null) result.childUid = childUid;
    if (sharePercent != null) result.sharePercent = sharePercent;
    return result;
  }

  ReqReferralShareSet._();

  factory ReqReferralShareSet.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqReferralShareSet()..mergeFromBuffer(data, registry);
  factory ReqReferralShareSet.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqReferralShareSet()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqReferralShareSet',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqReferralShareSet.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'parentUid')
    ..aInt64(2, _omitFieldNames ? '' : 'childUid')
    ..aI(3, _omitFieldNames ? '' : 'sharePercent')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqReferralShareSet clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqReferralShareSet copyWith(void Function(ReqReferralShareSet) updates) =>
      super.copyWith((message) => updates(message as ReqReferralShareSet))
          as ReqReferralShareSet;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use ReqReferralShareSet() / ReqReferralShareSet.new instead')
  static ReqReferralShareSet create() => ReqReferralShareSet._();
  static $pb.GeneratedMessage $_createMessage() => ReqReferralShareSet._();
  @$core.override
  ReqReferralShareSet createEmptyInstance() => ReqReferralShareSet._();
  @$core.pragma('dart2js:noInline')
  static ReqReferralShareSet getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqReferralShareSet>(
          ReqReferralShareSet.$_createMessage);
  static ReqReferralShareSet? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get parentUid => $_getI64(0);
  @$pb.TagNumber(1)
  set parentUid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasParentUid() => $_has(0);
  @$pb.TagNumber(1)
  void clearParentUid() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get childUid => $_getI64(1);
  @$pb.TagNumber(2)
  set childUid($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasChildUid() => $_has(1);
  @$pb.TagNumber(2)
  void clearChildUid() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get sharePercent => $_getIZ(2);
  @$pb.TagNumber(3)
  set sharePercent($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSharePercent() => $_has(2);
  @$pb.TagNumber(3)
  void clearSharePercent() => $_clearField(3);
}

class ResReferralShareSet extends $pb.GeneratedMessage {
  factory ResReferralShareSet({
    $core.bool? success,
  }) {
    final result = ResReferralShareSet._();
    if (success != null) result.success = success;
    return result;
  }

  ResReferralShareSet._();

  factory ResReferralShareSet.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResReferralShareSet()..mergeFromBuffer(data, registry);
  factory ResReferralShareSet.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResReferralShareSet()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResReferralShareSet',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResReferralShareSet.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResReferralShareSet clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResReferralShareSet copyWith(void Function(ResReferralShareSet) updates) =>
      super.copyWith((message) => updates(message as ResReferralShareSet))
          as ResReferralShareSet;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use ResReferralShareSet() / ResReferralShareSet.new instead')
  static ResReferralShareSet create() => ResReferralShareSet._();
  static $pb.GeneratedMessage $_createMessage() => ResReferralShareSet._();
  @$core.override
  ResReferralShareSet createEmptyInstance() => ResReferralShareSet._();
  @$core.pragma('dart2js:noInline')
  static ResReferralShareSet getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResReferralShareSet>(
          ResReferralShareSet.$_createMessage);
  static ResReferralShareSet? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);
}

class ReqReferralTreeGet extends $pb.GeneratedMessage {
  factory ReqReferralTreeGet({
    $fixnum.Int64? rootId,
    $core.int? depth,
  }) {
    final result = ReqReferralTreeGet._();
    if (rootId != null) result.rootId = rootId;
    if (depth != null) result.depth = depth;
    return result;
  }

  ReqReferralTreeGet._();

  factory ReqReferralTreeGet.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqReferralTreeGet()..mergeFromBuffer(data, registry);
  factory ReqReferralTreeGet.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqReferralTreeGet()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqReferralTreeGet',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqReferralTreeGet.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'rootId')
    ..aI(2, _omitFieldNames ? '' : 'depth')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqReferralTreeGet clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqReferralTreeGet copyWith(void Function(ReqReferralTreeGet) updates) =>
      super.copyWith((message) => updates(message as ReqReferralTreeGet))
          as ReqReferralTreeGet;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqReferralTreeGet() / ReqReferralTreeGet.new instead')
  static ReqReferralTreeGet create() => ReqReferralTreeGet._();
  static $pb.GeneratedMessage $_createMessage() => ReqReferralTreeGet._();
  @$core.override
  ReqReferralTreeGet createEmptyInstance() => ReqReferralTreeGet._();
  @$core.pragma('dart2js:noInline')
  static ReqReferralTreeGet getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqReferralTreeGet>(
          ReqReferralTreeGet.$_createMessage);
  static ReqReferralTreeGet? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get rootId => $_getI64(0);
  @$pb.TagNumber(1)
  set rootId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRootId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRootId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get depth => $_getIZ(1);
  @$pb.TagNumber(2)
  set depth($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDepth() => $_has(1);
  @$pb.TagNumber(2)
  void clearDepth() => $_clearField(2);
}

class ResReferralTreeGet extends $pb.GeneratedMessage {
  factory ResReferralTreeGet({
    ReferralTreeSlice? slice,
  }) {
    final result = ResReferralTreeGet._();
    if (slice != null) result.slice = slice;
    return result;
  }

  ResReferralTreeGet._();

  factory ResReferralTreeGet.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResReferralTreeGet()..mergeFromBuffer(data, registry);
  factory ResReferralTreeGet.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResReferralTreeGet()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResReferralTreeGet',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResReferralTreeGet.$_createMessage)
    ..aOM<ReferralTreeSlice>(1, _omitFieldNames ? '' : 'slice',
        subBuilder: ReferralTreeSlice.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResReferralTreeGet clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResReferralTreeGet copyWith(void Function(ResReferralTreeGet) updates) =>
      super.copyWith((message) => updates(message as ResReferralTreeGet))
          as ResReferralTreeGet;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResReferralTreeGet() / ResReferralTreeGet.new instead')
  static ResReferralTreeGet create() => ResReferralTreeGet._();
  static $pb.GeneratedMessage $_createMessage() => ResReferralTreeGet._();
  @$core.override
  ResReferralTreeGet createEmptyInstance() => ResReferralTreeGet._();
  @$core.pragma('dart2js:noInline')
  static ResReferralTreeGet getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResReferralTreeGet>(
          ResReferralTreeGet.$_createMessage);
  static ResReferralTreeGet? _defaultInstance;

  @$pb.TagNumber(1)
  ReferralTreeSlice get slice => $_getN(0);
  @$pb.TagNumber(1)
  set slice(ReferralTreeSlice value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSlice() => $_has(0);
  @$pb.TagNumber(1)
  void clearSlice() => $_clearField(1);
  @$pb.TagNumber(1)
  ReferralTreeSlice ensureSlice() => $_ensure(0);
}

class ReqReferralCodeList extends $pb.GeneratedMessage {
  factory ReqReferralCodeList() => ReqReferralCodeList._();

  ReqReferralCodeList._();

  factory ReqReferralCodeList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqReferralCodeList()..mergeFromBuffer(data, registry);
  factory ReqReferralCodeList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqReferralCodeList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqReferralCodeList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqReferralCodeList.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqReferralCodeList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqReferralCodeList copyWith(void Function(ReqReferralCodeList) updates) =>
      super.copyWith((message) => updates(message as ReqReferralCodeList))
          as ReqReferralCodeList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use ReqReferralCodeList() / ReqReferralCodeList.new instead')
  static ReqReferralCodeList create() => ReqReferralCodeList._();
  static $pb.GeneratedMessage $_createMessage() => ReqReferralCodeList._();
  @$core.override
  ReqReferralCodeList createEmptyInstance() => ReqReferralCodeList._();
  @$core.pragma('dart2js:noInline')
  static ReqReferralCodeList getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqReferralCodeList>(
          ReqReferralCodeList.$_createMessage);
  static ReqReferralCodeList? _defaultInstance;
}

class ResReferralCodeList extends $pb.GeneratedMessage {
  factory ResReferralCodeList({
    $core.Iterable<ReferralCodeDoc>? items,
  }) {
    final result = ResReferralCodeList._();
    if (items != null) result.items.addAll(items);
    return result;
  }

  ResReferralCodeList._();

  factory ResReferralCodeList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResReferralCodeList()..mergeFromBuffer(data, registry);
  factory ResReferralCodeList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResReferralCodeList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResReferralCodeList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResReferralCodeList.$_createMessage)
    ..pPM<ReferralCodeDoc>(1, _omitFieldNames ? '' : 'items',
        subBuilder: ReferralCodeDoc.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResReferralCodeList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResReferralCodeList copyWith(void Function(ResReferralCodeList) updates) =>
      super.copyWith((message) => updates(message as ResReferralCodeList))
          as ResReferralCodeList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use ResReferralCodeList() / ResReferralCodeList.new instead')
  static ResReferralCodeList create() => ResReferralCodeList._();
  static $pb.GeneratedMessage $_createMessage() => ResReferralCodeList._();
  @$core.override
  ResReferralCodeList createEmptyInstance() => ResReferralCodeList._();
  @$core.pragma('dart2js:noInline')
  static ResReferralCodeList getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResReferralCodeList>(
          ResReferralCodeList.$_createMessage);
  static ResReferralCodeList? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<ReferralCodeDoc> get items => $_getList(0);
}

class ReqReferralCodePut extends $pb.GeneratedMessage {
  factory ReqReferralCodePut({
    ReferralCodeDoc? code,
  }) {
    final result = ReqReferralCodePut._();
    if (code != null) result.code = code;
    return result;
  }

  ReqReferralCodePut._();

  factory ReqReferralCodePut.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqReferralCodePut()..mergeFromBuffer(data, registry);
  factory ReqReferralCodePut.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqReferralCodePut()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqReferralCodePut',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqReferralCodePut.$_createMessage)
    ..aOM<ReferralCodeDoc>(1, _omitFieldNames ? '' : 'code',
        subBuilder: ReferralCodeDoc.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqReferralCodePut clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqReferralCodePut copyWith(void Function(ReqReferralCodePut) updates) =>
      super.copyWith((message) => updates(message as ReqReferralCodePut))
          as ReqReferralCodePut;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqReferralCodePut() / ReqReferralCodePut.new instead')
  static ReqReferralCodePut create() => ReqReferralCodePut._();
  static $pb.GeneratedMessage $_createMessage() => ReqReferralCodePut._();
  @$core.override
  ReqReferralCodePut createEmptyInstance() => ReqReferralCodePut._();
  @$core.pragma('dart2js:noInline')
  static ReqReferralCodePut getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqReferralCodePut>(
          ReqReferralCodePut.$_createMessage);
  static ReqReferralCodePut? _defaultInstance;

  @$pb.TagNumber(1)
  ReferralCodeDoc get code => $_getN(0);
  @$pb.TagNumber(1)
  set code(ReferralCodeDoc value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasCode() => $_has(0);
  @$pb.TagNumber(1)
  void clearCode() => $_clearField(1);
  @$pb.TagNumber(1)
  ReferralCodeDoc ensureCode() => $_ensure(0);
}

class ReqReferralCodeDelete extends $pb.GeneratedMessage {
  factory ReqReferralCodeDelete({
    $core.String? code,
  }) {
    final result = ReqReferralCodeDelete._();
    if (code != null) result.code = code;
    return result;
  }

  ReqReferralCodeDelete._();

  factory ReqReferralCodeDelete.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqReferralCodeDelete()..mergeFromBuffer(data, registry);
  factory ReqReferralCodeDelete.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqReferralCodeDelete()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqReferralCodeDelete',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqReferralCodeDelete.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'code')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqReferralCodeDelete clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqReferralCodeDelete copyWith(
          void Function(ReqReferralCodeDelete) updates) =>
      super.copyWith((message) => updates(message as ReqReferralCodeDelete))
          as ReqReferralCodeDelete;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ReqReferralCodeDelete() / ReqReferralCodeDelete.new instead')
  static ReqReferralCodeDelete create() => ReqReferralCodeDelete._();
  static $pb.GeneratedMessage $_createMessage() => ReqReferralCodeDelete._();
  @$core.override
  ReqReferralCodeDelete createEmptyInstance() => ReqReferralCodeDelete._();
  @$core.pragma('dart2js:noInline')
  static ReqReferralCodeDelete getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqReferralCodeDelete>(
          ReqReferralCodeDelete.$_createMessage);
  static ReqReferralCodeDelete? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get code => $_getSZ(0);
  @$pb.TagNumber(1)
  set code($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCode() => $_has(0);
  @$pb.TagNumber(1)
  void clearCode() => $_clearField(1);
}

class ReferralStatPeriod extends $pb.GeneratedMessage {
  factory ReferralStatPeriod({
    $fixnum.Int64? fromMs,
    $fixnum.Int64? toMs,
  }) {
    final result = ReferralStatPeriod._();
    if (fromMs != null) result.fromMs = fromMs;
    if (toMs != null) result.toMs = toMs;
    return result;
  }

  ReferralStatPeriod._();

  factory ReferralStatPeriod.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReferralStatPeriod()..mergeFromBuffer(data, registry);
  factory ReferralStatPeriod.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReferralStatPeriod()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReferralStatPeriod',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReferralStatPeriod.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'fromMs')
    ..aInt64(2, _omitFieldNames ? '' : 'toMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReferralStatPeriod clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReferralStatPeriod copyWith(void Function(ReferralStatPeriod) updates) =>
      super.copyWith((message) => updates(message as ReferralStatPeriod))
          as ReferralStatPeriod;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReferralStatPeriod() / ReferralStatPeriod.new instead')
  static ReferralStatPeriod create() => ReferralStatPeriod._();
  static $pb.GeneratedMessage $_createMessage() => ReferralStatPeriod._();
  @$core.override
  ReferralStatPeriod createEmptyInstance() => ReferralStatPeriod._();
  @$core.pragma('dart2js:noInline')
  static ReferralStatPeriod getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReferralStatPeriod>(
          ReferralStatPeriod.$_createMessage);
  static ReferralStatPeriod? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get fromMs => $_getI64(0);
  @$pb.TagNumber(1)
  set fromMs($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasFromMs() => $_has(0);
  @$pb.TagNumber(1)
  void clearFromMs() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get toMs => $_getI64(1);
  @$pb.TagNumber(2)
  set toMs($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasToMs() => $_has(1);
  @$pb.TagNumber(2)
  void clearToMs() => $_clearField(2);
}

class ReferralUserStatColumn extends $pb.GeneratedMessage {
  factory ReferralUserStatColumn({
    $core.int? referralCount,
    $core.double? commissionIdr,
    $core.double? commissionUsd,
    $fixnum.Int64? tokensAlien,
    $fixnum.Int64? tokensApi,
  }) {
    final result = ReferralUserStatColumn._();
    if (referralCount != null) result.referralCount = referralCount;
    if (commissionIdr != null) result.commissionIdr = commissionIdr;
    if (commissionUsd != null) result.commissionUsd = commissionUsd;
    if (tokensAlien != null) result.tokensAlien = tokensAlien;
    if (tokensApi != null) result.tokensApi = tokensApi;
    return result;
  }

  ReferralUserStatColumn._();

  factory ReferralUserStatColumn.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReferralUserStatColumn()..mergeFromBuffer(data, registry);
  factory ReferralUserStatColumn.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReferralUserStatColumn()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReferralUserStatColumn',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReferralUserStatColumn.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'referralCount')
    ..aD(2, _omitFieldNames ? '' : 'commissionIdr')
    ..aD(3, _omitFieldNames ? '' : 'commissionUsd')
    ..aInt64(4, _omitFieldNames ? '' : 'tokensAlien')
    ..aInt64(5, _omitFieldNames ? '' : 'tokensApi')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReferralUserStatColumn clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReferralUserStatColumn copyWith(
          void Function(ReferralUserStatColumn) updates) =>
      super.copyWith((message) => updates(message as ReferralUserStatColumn))
          as ReferralUserStatColumn;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ReferralUserStatColumn() / ReferralUserStatColumn.new instead')
  static ReferralUserStatColumn create() => ReferralUserStatColumn._();
  static $pb.GeneratedMessage $_createMessage() => ReferralUserStatColumn._();
  @$core.override
  ReferralUserStatColumn createEmptyInstance() => ReferralUserStatColumn._();
  @$core.pragma('dart2js:noInline')
  static ReferralUserStatColumn getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReferralUserStatColumn>(
          ReferralUserStatColumn.$_createMessage);
  static ReferralUserStatColumn? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get referralCount => $_getIZ(0);
  @$pb.TagNumber(1)
  set referralCount($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasReferralCount() => $_has(0);
  @$pb.TagNumber(1)
  void clearReferralCount() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get commissionIdr => $_getN(1);
  @$pb.TagNumber(2)
  set commissionIdr($core.double value) => $_setDouble(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCommissionIdr() => $_has(1);
  @$pb.TagNumber(2)
  void clearCommissionIdr() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get commissionUsd => $_getN(2);
  @$pb.TagNumber(3)
  set commissionUsd($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCommissionUsd() => $_has(2);
  @$pb.TagNumber(3)
  void clearCommissionUsd() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get tokensAlien => $_getI64(3);
  @$pb.TagNumber(4)
  set tokensAlien($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTokensAlien() => $_has(3);
  @$pb.TagNumber(4)
  void clearTokensAlien() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get tokensApi => $_getI64(4);
  @$pb.TagNumber(5)
  set tokensApi($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasTokensApi() => $_has(4);
  @$pb.TagNumber(5)
  void clearTokensApi() => $_clearField(5);
}

class ReqReferralUserStats extends $pb.GeneratedMessage {
  factory ReqReferralUserStats({
    $fixnum.Int64? subjectUid,
    ReferralStatPeriod? colA,
    ReferralStatPeriod? colB,
  }) {
    final result = ReqReferralUserStats._();
    if (subjectUid != null) result.subjectUid = subjectUid;
    if (colA != null) result.colA = colA;
    if (colB != null) result.colB = colB;
    return result;
  }

  ReqReferralUserStats._();

  factory ReqReferralUserStats.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqReferralUserStats()..mergeFromBuffer(data, registry);
  factory ReqReferralUserStats.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqReferralUserStats()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqReferralUserStats',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqReferralUserStats.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'subjectUid')
    ..aOM<ReferralStatPeriod>(2, _omitFieldNames ? '' : 'colA',
        subBuilder: ReferralStatPeriod.$_createMessage)
    ..aOM<ReferralStatPeriod>(3, _omitFieldNames ? '' : 'colB',
        subBuilder: ReferralStatPeriod.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqReferralUserStats clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqReferralUserStats copyWith(void Function(ReqReferralUserStats) updates) =>
      super.copyWith((message) => updates(message as ReqReferralUserStats))
          as ReqReferralUserStats;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ReqReferralUserStats() / ReqReferralUserStats.new instead')
  static ReqReferralUserStats create() => ReqReferralUserStats._();
  static $pb.GeneratedMessage $_createMessage() => ReqReferralUserStats._();
  @$core.override
  ReqReferralUserStats createEmptyInstance() => ReqReferralUserStats._();
  @$core.pragma('dart2js:noInline')
  static ReqReferralUserStats getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqReferralUserStats>(
          ReqReferralUserStats.$_createMessage);
  static ReqReferralUserStats? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get subjectUid => $_getI64(0);
  @$pb.TagNumber(1)
  set subjectUid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSubjectUid() => $_has(0);
  @$pb.TagNumber(1)
  void clearSubjectUid() => $_clearField(1);

  @$pb.TagNumber(2)
  ReferralStatPeriod get colA => $_getN(1);
  @$pb.TagNumber(2)
  set colA(ReferralStatPeriod value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasColA() => $_has(1);
  @$pb.TagNumber(2)
  void clearColA() => $_clearField(2);
  @$pb.TagNumber(2)
  ReferralStatPeriod ensureColA() => $_ensure(1);

  @$pb.TagNumber(3)
  ReferralStatPeriod get colB => $_getN(2);
  @$pb.TagNumber(3)
  set colB(ReferralStatPeriod value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasColB() => $_has(2);
  @$pb.TagNumber(3)
  void clearColB() => $_clearField(3);
  @$pb.TagNumber(3)
  ReferralStatPeriod ensureColB() => $_ensure(2);
}

class ReferralUserWalletSnapshot extends $pb.GeneratedMessage {
  factory ReferralUserWalletSnapshot({
    $core.double? balanceIdr,
    $core.double? balanceUsd,
    $core.double? commissionAvailableIdr,
    $core.double? commissionAvailableUsd,
    $core.String? billingCurrency,
  }) {
    final result = ReferralUserWalletSnapshot._();
    if (balanceIdr != null) result.balanceIdr = balanceIdr;
    if (balanceUsd != null) result.balanceUsd = balanceUsd;
    if (commissionAvailableIdr != null)
      result.commissionAvailableIdr = commissionAvailableIdr;
    if (commissionAvailableUsd != null)
      result.commissionAvailableUsd = commissionAvailableUsd;
    if (billingCurrency != null) result.billingCurrency = billingCurrency;
    return result;
  }

  ReferralUserWalletSnapshot._();

  factory ReferralUserWalletSnapshot.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReferralUserWalletSnapshot()..mergeFromBuffer(data, registry);
  factory ReferralUserWalletSnapshot.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReferralUserWalletSnapshot()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReferralUserWalletSnapshot',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReferralUserWalletSnapshot.$_createMessage)
    ..aD(1, _omitFieldNames ? '' : 'balanceIdr')
    ..aD(2, _omitFieldNames ? '' : 'balanceUsd')
    ..aD(3, _omitFieldNames ? '' : 'commissionAvailableIdr')
    ..aD(4, _omitFieldNames ? '' : 'commissionAvailableUsd')
    ..aOS(5, _omitFieldNames ? '' : 'billingCurrency')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReferralUserWalletSnapshot clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReferralUserWalletSnapshot copyWith(
          void Function(ReferralUserWalletSnapshot) updates) =>
      super.copyWith(
              (message) => updates(message as ReferralUserWalletSnapshot))
          as ReferralUserWalletSnapshot;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ReferralUserWalletSnapshot() / ReferralUserWalletSnapshot.new instead')
  static ReferralUserWalletSnapshot create() => ReferralUserWalletSnapshot._();
  static $pb.GeneratedMessage $_createMessage() =>
      ReferralUserWalletSnapshot._();
  @$core.override
  ReferralUserWalletSnapshot createEmptyInstance() =>
      ReferralUserWalletSnapshot._();
  @$core.pragma('dart2js:noInline')
  static ReferralUserWalletSnapshot getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReferralUserWalletSnapshot>(
          ReferralUserWalletSnapshot.$_createMessage);
  static ReferralUserWalletSnapshot? _defaultInstance;

  @$pb.TagNumber(1)
  $core.double get balanceIdr => $_getN(0);
  @$pb.TagNumber(1)
  set balanceIdr($core.double value) => $_setDouble(0, value);
  @$pb.TagNumber(1)
  $core.bool hasBalanceIdr() => $_has(0);
  @$pb.TagNumber(1)
  void clearBalanceIdr() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get balanceUsd => $_getN(1);
  @$pb.TagNumber(2)
  set balanceUsd($core.double value) => $_setDouble(1, value);
  @$pb.TagNumber(2)
  $core.bool hasBalanceUsd() => $_has(1);
  @$pb.TagNumber(2)
  void clearBalanceUsd() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get commissionAvailableIdr => $_getN(2);
  @$pb.TagNumber(3)
  set commissionAvailableIdr($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCommissionAvailableIdr() => $_has(2);
  @$pb.TagNumber(3)
  void clearCommissionAvailableIdr() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get commissionAvailableUsd => $_getN(3);
  @$pb.TagNumber(4)
  set commissionAvailableUsd($core.double value) => $_setDouble(3, value);
  @$pb.TagNumber(4)
  $core.bool hasCommissionAvailableUsd() => $_has(3);
  @$pb.TagNumber(4)
  void clearCommissionAvailableUsd() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get billingCurrency => $_getSZ(4);
  @$pb.TagNumber(5)
  set billingCurrency($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasBillingCurrency() => $_has(4);
  @$pb.TagNumber(5)
  void clearBillingCurrency() => $_clearField(5);
}

class ResReferralUserStats extends $pb.GeneratedMessage {
  factory ResReferralUserStats({
    ReferralUserStatColumn? colA,
    ReferralUserStatColumn? colB,
    ReferralUserWalletSnapshot? wallet,
    $core.String? authEmail,
    $core.String? authPhone,
  }) {
    final result = ResReferralUserStats._();
    if (colA != null) result.colA = colA;
    if (colB != null) result.colB = colB;
    if (wallet != null) result.wallet = wallet;
    if (authEmail != null) result.authEmail = authEmail;
    if (authPhone != null) result.authPhone = authPhone;
    return result;
  }

  ResReferralUserStats._();

  factory ResReferralUserStats.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResReferralUserStats()..mergeFromBuffer(data, registry);
  factory ResReferralUserStats.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResReferralUserStats()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResReferralUserStats',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResReferralUserStats.$_createMessage)
    ..aOM<ReferralUserStatColumn>(1, _omitFieldNames ? '' : 'colA',
        subBuilder: ReferralUserStatColumn.$_createMessage)
    ..aOM<ReferralUserStatColumn>(2, _omitFieldNames ? '' : 'colB',
        subBuilder: ReferralUserStatColumn.$_createMessage)
    ..aOM<ReferralUserWalletSnapshot>(3, _omitFieldNames ? '' : 'wallet',
        subBuilder: ReferralUserWalletSnapshot.$_createMessage)
    ..aOS(4, _omitFieldNames ? '' : 'authEmail')
    ..aOS(5, _omitFieldNames ? '' : 'authPhone')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResReferralUserStats clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResReferralUserStats copyWith(void Function(ResReferralUserStats) updates) =>
      super.copyWith((message) => updates(message as ResReferralUserStats))
          as ResReferralUserStats;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ResReferralUserStats() / ResReferralUserStats.new instead')
  static ResReferralUserStats create() => ResReferralUserStats._();
  static $pb.GeneratedMessage $_createMessage() => ResReferralUserStats._();
  @$core.override
  ResReferralUserStats createEmptyInstance() => ResReferralUserStats._();
  @$core.pragma('dart2js:noInline')
  static ResReferralUserStats getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResReferralUserStats>(
          ResReferralUserStats.$_createMessage);
  static ResReferralUserStats? _defaultInstance;

  @$pb.TagNumber(1)
  ReferralUserStatColumn get colA => $_getN(0);
  @$pb.TagNumber(1)
  set colA(ReferralUserStatColumn value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasColA() => $_has(0);
  @$pb.TagNumber(1)
  void clearColA() => $_clearField(1);
  @$pb.TagNumber(1)
  ReferralUserStatColumn ensureColA() => $_ensure(0);

  @$pb.TagNumber(2)
  ReferralUserStatColumn get colB => $_getN(1);
  @$pb.TagNumber(2)
  set colB(ReferralUserStatColumn value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasColB() => $_has(1);
  @$pb.TagNumber(2)
  void clearColB() => $_clearField(2);
  @$pb.TagNumber(2)
  ReferralUserStatColumn ensureColB() => $_ensure(1);

  @$pb.TagNumber(3)
  ReferralUserWalletSnapshot get wallet => $_getN(2);
  @$pb.TagNumber(3)
  set wallet(ReferralUserWalletSnapshot value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasWallet() => $_has(2);
  @$pb.TagNumber(3)
  void clearWallet() => $_clearField(3);
  @$pb.TagNumber(3)
  ReferralUserWalletSnapshot ensureWallet() => $_ensure(2);

  /// Populated only when viewer is root / director (login email + phone from identity_provider).
  @$pb.TagNumber(4)
  $core.String get authEmail => $_getSZ(3);
  @$pb.TagNumber(4)
  set authEmail($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAuthEmail() => $_has(3);
  @$pb.TagNumber(4)
  void clearAuthEmail() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get authPhone => $_getSZ(4);
  @$pb.TagNumber(5)
  set authPhone($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasAuthPhone() => $_has(4);
  @$pb.TagNumber(5)
  void clearAuthPhone() => $_clearField(5);
}

class ReferralCommissionLevel extends $pb.GeneratedMessage {
  factory ReferralCommissionLevel({
    $fixnum.Int64? identityId,
    $core.String? name,
    $core.String? avatarUrl,
    $core.int? percent,
    $fixnum.Int64? earnAmount,
    $core.double? poolSharePercent,
  }) {
    final result = ReferralCommissionLevel._();
    if (identityId != null) result.identityId = identityId;
    if (name != null) result.name = name;
    if (avatarUrl != null) result.avatarUrl = avatarUrl;
    if (percent != null) result.percent = percent;
    if (earnAmount != null) result.earnAmount = earnAmount;
    if (poolSharePercent != null) result.poolSharePercent = poolSharePercent;
    return result;
  }

  ReferralCommissionLevel._();

  factory ReferralCommissionLevel.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReferralCommissionLevel()..mergeFromBuffer(data, registry);
  factory ReferralCommissionLevel.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReferralCommissionLevel()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReferralCommissionLevel',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReferralCommissionLevel.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'identityId')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOS(3, _omitFieldNames ? '' : 'avatarUrl')
    ..aI(4, _omitFieldNames ? '' : 'percent')
    ..aInt64(5, _omitFieldNames ? '' : 'earnAmount')
    ..aD(6, _omitFieldNames ? '' : 'poolSharePercent')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReferralCommissionLevel clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReferralCommissionLevel copyWith(
          void Function(ReferralCommissionLevel) updates) =>
      super.copyWith((message) => updates(message as ReferralCommissionLevel))
          as ReferralCommissionLevel;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ReferralCommissionLevel() / ReferralCommissionLevel.new instead')
  static ReferralCommissionLevel create() => ReferralCommissionLevel._();
  static $pb.GeneratedMessage $_createMessage() => ReferralCommissionLevel._();
  @$core.override
  ReferralCommissionLevel createEmptyInstance() => ReferralCommissionLevel._();
  @$core.pragma('dart2js:noInline')
  static ReferralCommissionLevel getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReferralCommissionLevel>(
          ReferralCommissionLevel.$_createMessage);
  static ReferralCommissionLevel? _defaultInstance;

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
  $core.String get avatarUrl => $_getSZ(2);
  @$pb.TagNumber(3)
  set avatarUrl($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAvatarUrl() => $_has(2);
  @$pb.TagNumber(3)
  void clearAvatarUrl() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get percent => $_getIZ(3);
  @$pb.TagNumber(4)
  set percent($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPercent() => $_has(3);
  @$pb.TagNumber(4)
  void clearPercent() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get earnAmount => $_getI64(4);
  @$pb.TagNumber(5)
  set earnAmount($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasEarnAmount() => $_has(4);
  @$pb.TagNumber(5)
  void clearEarnAmount() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.double get poolSharePercent => $_getN(5);
  @$pb.TagNumber(6)
  set poolSharePercent($core.double value) => $_setDouble(5, value);
  @$pb.TagNumber(6)
  $core.bool hasPoolSharePercent() => $_has(5);
  @$pb.TagNumber(6)
  void clearPoolSharePercent() => $_clearField(6);
}

class ReqReferralCommissionSimulate extends $pb.GeneratedMessage {
  factory ReqReferralCommissionSimulate({
    $fixnum.Int64? subjectUid,
    $fixnum.Int64? purchaseAmount,
  }) {
    final result = ReqReferralCommissionSimulate._();
    if (subjectUid != null) result.subjectUid = subjectUid;
    if (purchaseAmount != null) result.purchaseAmount = purchaseAmount;
    return result;
  }

  ReqReferralCommissionSimulate._();

  factory ReqReferralCommissionSimulate.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqReferralCommissionSimulate()..mergeFromBuffer(data, registry);
  factory ReqReferralCommissionSimulate.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqReferralCommissionSimulate()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqReferralCommissionSimulate',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqReferralCommissionSimulate.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'subjectUid')
    ..aInt64(2, _omitFieldNames ? '' : 'purchaseAmount')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqReferralCommissionSimulate clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqReferralCommissionSimulate copyWith(
          void Function(ReqReferralCommissionSimulate) updates) =>
      super.copyWith(
              (message) => updates(message as ReqReferralCommissionSimulate))
          as ReqReferralCommissionSimulate;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ReqReferralCommissionSimulate() / ReqReferralCommissionSimulate.new instead')
  static ReqReferralCommissionSimulate create() =>
      ReqReferralCommissionSimulate._();
  static $pb.GeneratedMessage $_createMessage() =>
      ReqReferralCommissionSimulate._();
  @$core.override
  ReqReferralCommissionSimulate createEmptyInstance() =>
      ReqReferralCommissionSimulate._();
  @$core.pragma('dart2js:noInline')
  static ReqReferralCommissionSimulate getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqReferralCommissionSimulate>(
          ReqReferralCommissionSimulate.$_createMessage);
  static ReqReferralCommissionSimulate? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get subjectUid => $_getI64(0);
  @$pb.TagNumber(1)
  set subjectUid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSubjectUid() => $_has(0);
  @$pb.TagNumber(1)
  void clearSubjectUid() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get purchaseAmount => $_getI64(1);
  @$pb.TagNumber(2)
  set purchaseAmount($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPurchaseAmount() => $_has(1);
  @$pb.TagNumber(2)
  void clearPurchaseAmount() => $_clearField(2);
}

class ResReferralCommissionSimulate extends $pb.GeneratedMessage {
  factory ResReferralCommissionSimulate({
    $fixnum.Int64? purchaseAmount,
    $fixnum.Int64? poolAmount,
    $core.double? poolRate,
    $core.Iterable<ReferralCommissionLevel>? levels,
    $fixnum.Int64? totalDistributed,
    $fixnum.Int64? undistributed,
  }) {
    final result = ResReferralCommissionSimulate._();
    if (purchaseAmount != null) result.purchaseAmount = purchaseAmount;
    if (poolAmount != null) result.poolAmount = poolAmount;
    if (poolRate != null) result.poolRate = poolRate;
    if (levels != null) result.levels.addAll(levels);
    if (totalDistributed != null) result.totalDistributed = totalDistributed;
    if (undistributed != null) result.undistributed = undistributed;
    return result;
  }

  ResReferralCommissionSimulate._();

  factory ResReferralCommissionSimulate.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResReferralCommissionSimulate()..mergeFromBuffer(data, registry);
  factory ResReferralCommissionSimulate.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResReferralCommissionSimulate()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResReferralCommissionSimulate',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResReferralCommissionSimulate.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'purchaseAmount')
    ..aInt64(2, _omitFieldNames ? '' : 'poolAmount')
    ..aD(3, _omitFieldNames ? '' : 'poolRate')
    ..pPM<ReferralCommissionLevel>(4, _omitFieldNames ? '' : 'levels',
        subBuilder: ReferralCommissionLevel.$_createMessage)
    ..aInt64(5, _omitFieldNames ? '' : 'totalDistributed')
    ..aInt64(6, _omitFieldNames ? '' : 'undistributed')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResReferralCommissionSimulate clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResReferralCommissionSimulate copyWith(
          void Function(ResReferralCommissionSimulate) updates) =>
      super.copyWith(
              (message) => updates(message as ResReferralCommissionSimulate))
          as ResReferralCommissionSimulate;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ResReferralCommissionSimulate() / ResReferralCommissionSimulate.new instead')
  static ResReferralCommissionSimulate create() =>
      ResReferralCommissionSimulate._();
  static $pb.GeneratedMessage $_createMessage() =>
      ResReferralCommissionSimulate._();
  @$core.override
  ResReferralCommissionSimulate createEmptyInstance() =>
      ResReferralCommissionSimulate._();
  @$core.pragma('dart2js:noInline')
  static ResReferralCommissionSimulate getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResReferralCommissionSimulate>(
          ResReferralCommissionSimulate.$_createMessage);
  static ResReferralCommissionSimulate? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get purchaseAmount => $_getI64(0);
  @$pb.TagNumber(1)
  set purchaseAmount($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPurchaseAmount() => $_has(0);
  @$pb.TagNumber(1)
  void clearPurchaseAmount() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get poolAmount => $_getI64(1);
  @$pb.TagNumber(2)
  set poolAmount($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPoolAmount() => $_has(1);
  @$pb.TagNumber(2)
  void clearPoolAmount() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get poolRate => $_getN(2);
  @$pb.TagNumber(3)
  set poolRate($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPoolRate() => $_has(2);
  @$pb.TagNumber(3)
  void clearPoolRate() => $_clearField(3);

  @$pb.TagNumber(4)
  $pb.PbList<ReferralCommissionLevel> get levels => $_getList(3);

  @$pb.TagNumber(5)
  $fixnum.Int64 get totalDistributed => $_getI64(4);
  @$pb.TagNumber(5)
  set totalDistributed($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasTotalDistributed() => $_has(4);
  @$pb.TagNumber(5)
  void clearTotalDistributed() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get undistributed => $_getI64(5);
  @$pb.TagNumber(6)
  set undistributed($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasUndistributed() => $_has(5);
  @$pb.TagNumber(6)
  void clearUndistributed() => $_clearField(6);
}

class CommissionLedgerEntry extends $pb.GeneratedMessage {
  factory CommissionLedgerEntry({
    $fixnum.Int64? id,
    $core.String? entryType,
    $core.double? amountUsd,
    $core.double? amountIdr,
    $core.String? currency,
    $core.String? status,
    $fixnum.Int64? sourceIid,
    $core.String? eventType,
    $core.String? referenceId,
    $fixnum.Int64? createdTsMs,
  }) {
    final result = CommissionLedgerEntry._();
    if (id != null) result.id = id;
    if (entryType != null) result.entryType = entryType;
    if (amountUsd != null) result.amountUsd = amountUsd;
    if (amountIdr != null) result.amountIdr = amountIdr;
    if (currency != null) result.currency = currency;
    if (status != null) result.status = status;
    if (sourceIid != null) result.sourceIid = sourceIid;
    if (eventType != null) result.eventType = eventType;
    if (referenceId != null) result.referenceId = referenceId;
    if (createdTsMs != null) result.createdTsMs = createdTsMs;
    return result;
  }

  CommissionLedgerEntry._();

  factory CommissionLedgerEntry.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CommissionLedgerEntry()..mergeFromBuffer(data, registry);
  factory CommissionLedgerEntry.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CommissionLedgerEntry()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CommissionLedgerEntry',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: CommissionLedgerEntry.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'entryType')
    ..aD(3, _omitFieldNames ? '' : 'amountUsd')
    ..aD(4, _omitFieldNames ? '' : 'amountIdr')
    ..aOS(5, _omitFieldNames ? '' : 'currency')
    ..aOS(6, _omitFieldNames ? '' : 'status')
    ..aInt64(7, _omitFieldNames ? '' : 'sourceIid')
    ..aOS(8, _omitFieldNames ? '' : 'eventType')
    ..aOS(9, _omitFieldNames ? '' : 'referenceId')
    ..aInt64(10, _omitFieldNames ? '' : 'createdTsMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CommissionLedgerEntry clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CommissionLedgerEntry copyWith(
          void Function(CommissionLedgerEntry) updates) =>
      super.copyWith((message) => updates(message as CommissionLedgerEntry))
          as CommissionLedgerEntry;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use CommissionLedgerEntry() / CommissionLedgerEntry.new instead')
  static CommissionLedgerEntry create() => CommissionLedgerEntry._();
  static $pb.GeneratedMessage $_createMessage() => CommissionLedgerEntry._();
  @$core.override
  CommissionLedgerEntry createEmptyInstance() => CommissionLedgerEntry._();
  @$core.pragma('dart2js:noInline')
  static CommissionLedgerEntry getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CommissionLedgerEntry>(
          CommissionLedgerEntry.$_createMessage);
  static CommissionLedgerEntry? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get entryType => $_getSZ(1);
  @$pb.TagNumber(2)
  set entryType($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEntryType() => $_has(1);
  @$pb.TagNumber(2)
  void clearEntryType() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get amountUsd => $_getN(2);
  @$pb.TagNumber(3)
  set amountUsd($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAmountUsd() => $_has(2);
  @$pb.TagNumber(3)
  void clearAmountUsd() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get amountIdr => $_getN(3);
  @$pb.TagNumber(4)
  set amountIdr($core.double value) => $_setDouble(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAmountIdr() => $_has(3);
  @$pb.TagNumber(4)
  void clearAmountIdr() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get currency => $_getSZ(4);
  @$pb.TagNumber(5)
  set currency($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasCurrency() => $_has(4);
  @$pb.TagNumber(5)
  void clearCurrency() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get status => $_getSZ(5);
  @$pb.TagNumber(6)
  set status($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasStatus() => $_has(5);
  @$pb.TagNumber(6)
  void clearStatus() => $_clearField(6);

  @$pb.TagNumber(7)
  $fixnum.Int64 get sourceIid => $_getI64(6);
  @$pb.TagNumber(7)
  set sourceIid($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(7)
  $core.bool hasSourceIid() => $_has(6);
  @$pb.TagNumber(7)
  void clearSourceIid() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get eventType => $_getSZ(7);
  @$pb.TagNumber(8)
  set eventType($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasEventType() => $_has(7);
  @$pb.TagNumber(8)
  void clearEventType() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get referenceId => $_getSZ(8);
  @$pb.TagNumber(9)
  set referenceId($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasReferenceId() => $_has(8);
  @$pb.TagNumber(9)
  void clearReferenceId() => $_clearField(9);

  @$pb.TagNumber(10)
  $fixnum.Int64 get createdTsMs => $_getI64(9);
  @$pb.TagNumber(10)
  set createdTsMs($fixnum.Int64 value) => $_setInt64(9, value);
  @$pb.TagNumber(10)
  $core.bool hasCreatedTsMs() => $_has(9);
  @$pb.TagNumber(10)
  void clearCreatedTsMs() => $_clearField(10);
}

class ReqCommissionWithdraw extends $pb.GeneratedMessage {
  factory ReqCommissionWithdraw({
    $core.double? amountUsd,
    $core.String? payoutMethod,
    $core.double? amountIdr,
    $core.String? currency,
    $core.String? bankId,
    $core.String? accountNumber,
    $core.String? accountName,
  }) {
    final result = ReqCommissionWithdraw._();
    if (amountUsd != null) result.amountUsd = amountUsd;
    if (payoutMethod != null) result.payoutMethod = payoutMethod;
    if (amountIdr != null) result.amountIdr = amountIdr;
    if (currency != null) result.currency = currency;
    if (bankId != null) result.bankId = bankId;
    if (accountNumber != null) result.accountNumber = accountNumber;
    if (accountName != null) result.accountName = accountName;
    return result;
  }

  ReqCommissionWithdraw._();

  factory ReqCommissionWithdraw.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqCommissionWithdraw()..mergeFromBuffer(data, registry);
  factory ReqCommissionWithdraw.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqCommissionWithdraw()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqCommissionWithdraw',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqCommissionWithdraw.$_createMessage)
    ..aD(1, _omitFieldNames ? '' : 'amountUsd')
    ..aOS(2, _omitFieldNames ? '' : 'payoutMethod')
    ..aD(3, _omitFieldNames ? '' : 'amountIdr')
    ..aOS(4, _omitFieldNames ? '' : 'currency')
    ..aOS(5, _omitFieldNames ? '' : 'bankId')
    ..aOS(6, _omitFieldNames ? '' : 'accountNumber')
    ..aOS(7, _omitFieldNames ? '' : 'accountName')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqCommissionWithdraw clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqCommissionWithdraw copyWith(
          void Function(ReqCommissionWithdraw) updates) =>
      super.copyWith((message) => updates(message as ReqCommissionWithdraw))
          as ReqCommissionWithdraw;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ReqCommissionWithdraw() / ReqCommissionWithdraw.new instead')
  static ReqCommissionWithdraw create() => ReqCommissionWithdraw._();
  static $pb.GeneratedMessage $_createMessage() => ReqCommissionWithdraw._();
  @$core.override
  ReqCommissionWithdraw createEmptyInstance() => ReqCommissionWithdraw._();
  @$core.pragma('dart2js:noInline')
  static ReqCommissionWithdraw getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqCommissionWithdraw>(
          ReqCommissionWithdraw.$_createMessage);
  static ReqCommissionWithdraw? _defaultInstance;

  @$pb.TagNumber(1)
  $core.double get amountUsd => $_getN(0);
  @$pb.TagNumber(1)
  set amountUsd($core.double value) => $_setDouble(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAmountUsd() => $_has(0);
  @$pb.TagNumber(1)
  void clearAmountUsd() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get payoutMethod => $_getSZ(1);
  @$pb.TagNumber(2)
  set payoutMethod($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPayoutMethod() => $_has(1);
  @$pb.TagNumber(2)
  void clearPayoutMethod() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get amountIdr => $_getN(2);
  @$pb.TagNumber(3)
  set amountIdr($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAmountIdr() => $_has(2);
  @$pb.TagNumber(3)
  void clearAmountIdr() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get currency => $_getSZ(3);
  @$pb.TagNumber(4)
  set currency($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasCurrency() => $_has(3);
  @$pb.TagNumber(4)
  void clearCurrency() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get bankId => $_getSZ(4);
  @$pb.TagNumber(5)
  set bankId($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasBankId() => $_has(4);
  @$pb.TagNumber(5)
  void clearBankId() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get accountNumber => $_getSZ(5);
  @$pb.TagNumber(6)
  set accountNumber($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasAccountNumber() => $_has(5);
  @$pb.TagNumber(6)
  void clearAccountNumber() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get accountName => $_getSZ(6);
  @$pb.TagNumber(7)
  set accountName($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasAccountName() => $_has(6);
  @$pb.TagNumber(7)
  void clearAccountName() => $_clearField(7);
}

class ResCommissionWithdraw extends $pb.GeneratedMessage {
  factory ResCommissionWithdraw({
    $core.bool? success,
    $core.double? commissionAvailableUsd,
    $core.double? newWalletBalanceUsd,
    $core.double? commissionAvailableIdr,
    $core.double? newWalletBalanceIdr,
    $core.String? currency,
  }) {
    final result = ResCommissionWithdraw._();
    if (success != null) result.success = success;
    if (commissionAvailableUsd != null)
      result.commissionAvailableUsd = commissionAvailableUsd;
    if (newWalletBalanceUsd != null)
      result.newWalletBalanceUsd = newWalletBalanceUsd;
    if (commissionAvailableIdr != null)
      result.commissionAvailableIdr = commissionAvailableIdr;
    if (newWalletBalanceIdr != null)
      result.newWalletBalanceIdr = newWalletBalanceIdr;
    if (currency != null) result.currency = currency;
    return result;
  }

  ResCommissionWithdraw._();

  factory ResCommissionWithdraw.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResCommissionWithdraw()..mergeFromBuffer(data, registry);
  factory ResCommissionWithdraw.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResCommissionWithdraw()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResCommissionWithdraw',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResCommissionWithdraw.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aD(2, _omitFieldNames ? '' : 'commissionAvailableUsd')
    ..aD(3, _omitFieldNames ? '' : 'newWalletBalanceUsd')
    ..aD(4, _omitFieldNames ? '' : 'commissionAvailableIdr')
    ..aD(5, _omitFieldNames ? '' : 'newWalletBalanceIdr')
    ..aOS(6, _omitFieldNames ? '' : 'currency')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResCommissionWithdraw clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResCommissionWithdraw copyWith(
          void Function(ResCommissionWithdraw) updates) =>
      super.copyWith((message) => updates(message as ResCommissionWithdraw))
          as ResCommissionWithdraw;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ResCommissionWithdraw() / ResCommissionWithdraw.new instead')
  static ResCommissionWithdraw create() => ResCommissionWithdraw._();
  static $pb.GeneratedMessage $_createMessage() => ResCommissionWithdraw._();
  @$core.override
  ResCommissionWithdraw createEmptyInstance() => ResCommissionWithdraw._();
  @$core.pragma('dart2js:noInline')
  static ResCommissionWithdraw getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResCommissionWithdraw>(
          ResCommissionWithdraw.$_createMessage);
  static ResCommissionWithdraw? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get commissionAvailableUsd => $_getN(1);
  @$pb.TagNumber(2)
  set commissionAvailableUsd($core.double value) => $_setDouble(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCommissionAvailableUsd() => $_has(1);
  @$pb.TagNumber(2)
  void clearCommissionAvailableUsd() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get newWalletBalanceUsd => $_getN(2);
  @$pb.TagNumber(3)
  set newWalletBalanceUsd($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasNewWalletBalanceUsd() => $_has(2);
  @$pb.TagNumber(3)
  void clearNewWalletBalanceUsd() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get commissionAvailableIdr => $_getN(3);
  @$pb.TagNumber(4)
  set commissionAvailableIdr($core.double value) => $_setDouble(3, value);
  @$pb.TagNumber(4)
  $core.bool hasCommissionAvailableIdr() => $_has(3);
  @$pb.TagNumber(4)
  void clearCommissionAvailableIdr() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.double get newWalletBalanceIdr => $_getN(4);
  @$pb.TagNumber(5)
  set newWalletBalanceIdr($core.double value) => $_setDouble(4, value);
  @$pb.TagNumber(5)
  $core.bool hasNewWalletBalanceIdr() => $_has(4);
  @$pb.TagNumber(5)
  void clearNewWalletBalanceIdr() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get currency => $_getSZ(5);
  @$pb.TagNumber(6)
  set currency($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasCurrency() => $_has(5);
  @$pb.TagNumber(6)
  void clearCurrency() => $_clearField(6);
}

class ReqReferralLedgerList extends $pb.GeneratedMessage {
  factory ReqReferralLedgerList({
    $core.int? limit,
  }) {
    final result = ReqReferralLedgerList._();
    if (limit != null) result.limit = limit;
    return result;
  }

  ReqReferralLedgerList._();

  factory ReqReferralLedgerList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqReferralLedgerList()..mergeFromBuffer(data, registry);
  factory ReqReferralLedgerList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqReferralLedgerList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqReferralLedgerList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqReferralLedgerList.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'limit')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqReferralLedgerList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqReferralLedgerList copyWith(
          void Function(ReqReferralLedgerList) updates) =>
      super.copyWith((message) => updates(message as ReqReferralLedgerList))
          as ReqReferralLedgerList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ReqReferralLedgerList() / ReqReferralLedgerList.new instead')
  static ReqReferralLedgerList create() => ReqReferralLedgerList._();
  static $pb.GeneratedMessage $_createMessage() => ReqReferralLedgerList._();
  @$core.override
  ReqReferralLedgerList createEmptyInstance() => ReqReferralLedgerList._();
  @$core.pragma('dart2js:noInline')
  static ReqReferralLedgerList getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqReferralLedgerList>(
          ReqReferralLedgerList.$_createMessage);
  static ReqReferralLedgerList? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get limit => $_getIZ(0);
  @$pb.TagNumber(1)
  set limit($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLimit() => $_has(0);
  @$pb.TagNumber(1)
  void clearLimit() => $_clearField(1);
}

class ResReferralLedgerList extends $pb.GeneratedMessage {
  factory ResReferralLedgerList({
    $core.Iterable<CommissionLedgerEntry>? items,
  }) {
    final result = ResReferralLedgerList._();
    if (items != null) result.items.addAll(items);
    return result;
  }

  ResReferralLedgerList._();

  factory ResReferralLedgerList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResReferralLedgerList()..mergeFromBuffer(data, registry);
  factory ResReferralLedgerList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResReferralLedgerList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResReferralLedgerList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResReferralLedgerList.$_createMessage)
    ..pPM<CommissionLedgerEntry>(1, _omitFieldNames ? '' : 'items',
        subBuilder: CommissionLedgerEntry.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResReferralLedgerList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResReferralLedgerList copyWith(
          void Function(ResReferralLedgerList) updates) =>
      super.copyWith((message) => updates(message as ResReferralLedgerList))
          as ResReferralLedgerList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ResReferralLedgerList() / ResReferralLedgerList.new instead')
  static ResReferralLedgerList create() => ResReferralLedgerList._();
  static $pb.GeneratedMessage $_createMessage() => ResReferralLedgerList._();
  @$core.override
  ResReferralLedgerList createEmptyInstance() => ResReferralLedgerList._();
  @$core.pragma('dart2js:noInline')
  static ResReferralLedgerList getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResReferralLedgerList>(
          ResReferralLedgerList.$_createMessage);
  static ResReferralLedgerList? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<CommissionLedgerEntry> get items => $_getList(0);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
