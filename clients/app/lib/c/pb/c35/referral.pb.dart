//
//  Generated code. Do not modify.
//  source: c35/referral.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

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
    final $result = create();
    if (code != null) {
      $result.code = code;
    }
    if (type != null) {
      $result.type = type;
    }
    if (name != null) {
      $result.name = name;
    }
    if (issuedBy != null) {
      $result.issuedBy = issuedBy;
    }
    if (priceUsd != null) {
      $result.priceUsd = priceUsd;
    }
    if (durationMonths != null) {
      $result.durationMonths = durationMonths;
    }
    if (basePlanSlug != null) {
      $result.basePlanSlug = basePlanSlug;
    }
    if (maxUses != null) {
      $result.maxUses = maxUses;
    }
    if (usedCount != null) {
      $result.usedCount = usedCount;
    }
    if (expiresAtMs != null) {
      $result.expiresAtMs = expiresAtMs;
    }
    return $result;
  }
  ReferralCodeDoc._() : super();
  factory ReferralCodeDoc.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ReferralCodeDoc.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ReferralCodeDoc', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'code')
    ..aOS(2, _omitFieldNames ? '' : 'type')
    ..aOS(3, _omitFieldNames ? '' : 'name')
    ..aInt64(4, _omitFieldNames ? '' : 'issuedBy')
    ..a<$core.double>(5, _omitFieldNames ? '' : 'priceUsd', $pb.PbFieldType.OD)
    ..a<$core.int>(6, _omitFieldNames ? '' : 'durationMonths', $pb.PbFieldType.O3)
    ..aOS(7, _omitFieldNames ? '' : 'basePlanSlug')
    ..a<$core.int>(8, _omitFieldNames ? '' : 'maxUses', $pb.PbFieldType.O3)
    ..a<$core.int>(9, _omitFieldNames ? '' : 'usedCount', $pb.PbFieldType.O3)
    ..aInt64(10, _omitFieldNames ? '' : 'expiresAtMs')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ReferralCodeDoc clone() => ReferralCodeDoc()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ReferralCodeDoc copyWith(void Function(ReferralCodeDoc) updates) => super.copyWith((message) => updates(message as ReferralCodeDoc)) as ReferralCodeDoc;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReferralCodeDoc create() => ReferralCodeDoc._();
  ReferralCodeDoc createEmptyInstance() => create();
  static $pb.PbList<ReferralCodeDoc> createRepeated() => $pb.PbList<ReferralCodeDoc>();
  @$core.pragma('dart2js:noInline')
  static ReferralCodeDoc getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReferralCodeDoc>(create);
  static ReferralCodeDoc? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get code => $_getSZ(0);
  @$pb.TagNumber(1)
  set code($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasCode() => $_has(0);
  @$pb.TagNumber(1)
  void clearCode() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get type => $_getSZ(1);
  @$pb.TagNumber(2)
  set type($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasType() => $_has(1);
  @$pb.TagNumber(2)
  void clearType() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get name => $_getSZ(2);
  @$pb.TagNumber(3)
  set name($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasName() => $_has(2);
  @$pb.TagNumber(3)
  void clearName() => clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get issuedBy => $_getI64(3);
  @$pb.TagNumber(4)
  set issuedBy($fixnum.Int64 v) { $_setInt64(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasIssuedBy() => $_has(3);
  @$pb.TagNumber(4)
  void clearIssuedBy() => clearField(4);

  @$pb.TagNumber(5)
  $core.double get priceUsd => $_getN(4);
  @$pb.TagNumber(5)
  set priceUsd($core.double v) { $_setDouble(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasPriceUsd() => $_has(4);
  @$pb.TagNumber(5)
  void clearPriceUsd() => clearField(5);

  @$pb.TagNumber(6)
  $core.int get durationMonths => $_getIZ(5);
  @$pb.TagNumber(6)
  set durationMonths($core.int v) { $_setSignedInt32(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasDurationMonths() => $_has(5);
  @$pb.TagNumber(6)
  void clearDurationMonths() => clearField(6);

  @$pb.TagNumber(7)
  $core.String get basePlanSlug => $_getSZ(6);
  @$pb.TagNumber(7)
  set basePlanSlug($core.String v) { $_setString(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasBasePlanSlug() => $_has(6);
  @$pb.TagNumber(7)
  void clearBasePlanSlug() => clearField(7);

  @$pb.TagNumber(8)
  $core.int get maxUses => $_getIZ(7);
  @$pb.TagNumber(8)
  set maxUses($core.int v) { $_setSignedInt32(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasMaxUses() => $_has(7);
  @$pb.TagNumber(8)
  void clearMaxUses() => clearField(8);

  @$pb.TagNumber(9)
  $core.int get usedCount => $_getIZ(8);
  @$pb.TagNumber(9)
  set usedCount($core.int v) { $_setSignedInt32(8, v); }
  @$pb.TagNumber(9)
  $core.bool hasUsedCount() => $_has(8);
  @$pb.TagNumber(9)
  void clearUsedCount() => clearField(9);

  @$pb.TagNumber(10)
  $fixnum.Int64 get expiresAtMs => $_getI64(9);
  @$pb.TagNumber(10)
  set expiresAtMs($fixnum.Int64 v) { $_setInt64(9, v); }
  @$pb.TagNumber(10)
  $core.bool hasExpiresAtMs() => $_has(9);
  @$pb.TagNumber(10)
  void clearExpiresAtMs() => clearField(10);
}

class ReferralShareDoc extends $pb.GeneratedMessage {
  factory ReferralShareDoc({
    $fixnum.Int64? parentUid,
    $fixnum.Int64? childUid,
    $core.int? sharePercent,
  }) {
    final $result = create();
    if (parentUid != null) {
      $result.parentUid = parentUid;
    }
    if (childUid != null) {
      $result.childUid = childUid;
    }
    if (sharePercent != null) {
      $result.sharePercent = sharePercent;
    }
    return $result;
  }
  ReferralShareDoc._() : super();
  factory ReferralShareDoc.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ReferralShareDoc.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ReferralShareDoc', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'parentUid')
    ..aInt64(2, _omitFieldNames ? '' : 'childUid')
    ..a<$core.int>(3, _omitFieldNames ? '' : 'sharePercent', $pb.PbFieldType.O3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ReferralShareDoc clone() => ReferralShareDoc()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ReferralShareDoc copyWith(void Function(ReferralShareDoc) updates) => super.copyWith((message) => updates(message as ReferralShareDoc)) as ReferralShareDoc;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReferralShareDoc create() => ReferralShareDoc._();
  ReferralShareDoc createEmptyInstance() => create();
  static $pb.PbList<ReferralShareDoc> createRepeated() => $pb.PbList<ReferralShareDoc>();
  @$core.pragma('dart2js:noInline')
  static ReferralShareDoc getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReferralShareDoc>(create);
  static ReferralShareDoc? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get parentUid => $_getI64(0);
  @$pb.TagNumber(1)
  set parentUid($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasParentUid() => $_has(0);
  @$pb.TagNumber(1)
  void clearParentUid() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get childUid => $_getI64(1);
  @$pb.TagNumber(2)
  set childUid($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasChildUid() => $_has(1);
  @$pb.TagNumber(2)
  void clearChildUid() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get sharePercent => $_getIZ(2);
  @$pb.TagNumber(3)
  set sharePercent($core.int v) { $_setSignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasSharePercent() => $_has(2);
  @$pb.TagNumber(3)
  void clearSharePercent() => clearField(3);
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
    final $result = create();
    if (identityId != null) {
      $result.identityId = identityId;
    }
    if (name != null) {
      $result.name = name;
    }
    if (email != null) {
      $result.email = email;
    }
    if (avatarUrl != null) {
      $result.avatarUrl = avatarUrl;
    }
    if (handle != null) {
      $result.handle = handle;
    }
    if (referredBy != null) {
      $result.referredBy = referredBy;
    }
    if (childCount != null) {
      $result.childCount = childCount;
    }
    if (isRoot != null) {
      $result.isRoot = isRoot;
    }
    if (isBanned != null) {
      $result.isBanned = isBanned;
    }
    if (globalRoles != null) {
      $result.globalRoles.addAll(globalRoles);
    }
    return $result;
  }
  ReferralTreeNode._() : super();
  factory ReferralTreeNode.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ReferralTreeNode.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ReferralTreeNode', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'identityId')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOS(3, _omitFieldNames ? '' : 'email')
    ..aOS(4, _omitFieldNames ? '' : 'avatarUrl')
    ..aOS(5, _omitFieldNames ? '' : 'handle')
    ..aInt64(6, _omitFieldNames ? '' : 'referredBy')
    ..a<$core.int>(7, _omitFieldNames ? '' : 'childCount', $pb.PbFieldType.O3)
    ..aOB(8, _omitFieldNames ? '' : 'isRoot')
    ..aOB(9, _omitFieldNames ? '' : 'isBanned')
    ..pPS(10, _omitFieldNames ? '' : 'globalRoles')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ReferralTreeNode clone() => ReferralTreeNode()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ReferralTreeNode copyWith(void Function(ReferralTreeNode) updates) => super.copyWith((message) => updates(message as ReferralTreeNode)) as ReferralTreeNode;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReferralTreeNode create() => ReferralTreeNode._();
  ReferralTreeNode createEmptyInstance() => create();
  static $pb.PbList<ReferralTreeNode> createRepeated() => $pb.PbList<ReferralTreeNode>();
  @$core.pragma('dart2js:noInline')
  static ReferralTreeNode getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReferralTreeNode>(create);
  static ReferralTreeNode? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get identityId => $_getI64(0);
  @$pb.TagNumber(1)
  set identityId($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasIdentityId() => $_has(0);
  @$pb.TagNumber(1)
  void clearIdentityId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get email => $_getSZ(2);
  @$pb.TagNumber(3)
  set email($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasEmail() => $_has(2);
  @$pb.TagNumber(3)
  void clearEmail() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get avatarUrl => $_getSZ(3);
  @$pb.TagNumber(4)
  set avatarUrl($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasAvatarUrl() => $_has(3);
  @$pb.TagNumber(4)
  void clearAvatarUrl() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get handle => $_getSZ(4);
  @$pb.TagNumber(5)
  set handle($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasHandle() => $_has(4);
  @$pb.TagNumber(5)
  void clearHandle() => clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get referredBy => $_getI64(5);
  @$pb.TagNumber(6)
  set referredBy($fixnum.Int64 v) { $_setInt64(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasReferredBy() => $_has(5);
  @$pb.TagNumber(6)
  void clearReferredBy() => clearField(6);

  @$pb.TagNumber(7)
  $core.int get childCount => $_getIZ(6);
  @$pb.TagNumber(7)
  set childCount($core.int v) { $_setSignedInt32(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasChildCount() => $_has(6);
  @$pb.TagNumber(7)
  void clearChildCount() => clearField(7);

  @$pb.TagNumber(8)
  $core.bool get isRoot => $_getBF(7);
  @$pb.TagNumber(8)
  set isRoot($core.bool v) { $_setBool(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasIsRoot() => $_has(7);
  @$pb.TagNumber(8)
  void clearIsRoot() => clearField(8);

  @$pb.TagNumber(9)
  $core.bool get isBanned => $_getBF(8);
  @$pb.TagNumber(9)
  set isBanned($core.bool v) { $_setBool(8, v); }
  @$pb.TagNumber(9)
  $core.bool hasIsBanned() => $_has(8);
  @$pb.TagNumber(9)
  void clearIsBanned() => clearField(9);

  @$pb.TagNumber(10)
  $core.List<$core.String> get globalRoles => $_getList(9);
}

class ReferralTreeSlice extends $pb.GeneratedMessage {
  factory ReferralTreeSlice({
    $core.Iterable<ReferralTreeNode>? nodes,
    $core.Iterable<ReferralShareDoc>? branchShares,
  }) {
    final $result = create();
    if (nodes != null) {
      $result.nodes.addAll(nodes);
    }
    if (branchShares != null) {
      $result.branchShares.addAll(branchShares);
    }
    return $result;
  }
  ReferralTreeSlice._() : super();
  factory ReferralTreeSlice.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ReferralTreeSlice.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ReferralTreeSlice', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..pc<ReferralTreeNode>(1, _omitFieldNames ? '' : 'nodes', $pb.PbFieldType.PM, subBuilder: ReferralTreeNode.create)
    ..pc<ReferralShareDoc>(2, _omitFieldNames ? '' : 'branchShares', $pb.PbFieldType.PM, subBuilder: ReferralShareDoc.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ReferralTreeSlice clone() => ReferralTreeSlice()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ReferralTreeSlice copyWith(void Function(ReferralTreeSlice) updates) => super.copyWith((message) => updates(message as ReferralTreeSlice)) as ReferralTreeSlice;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReferralTreeSlice create() => ReferralTreeSlice._();
  ReferralTreeSlice createEmptyInstance() => create();
  static $pb.PbList<ReferralTreeSlice> createRepeated() => $pb.PbList<ReferralTreeSlice>();
  @$core.pragma('dart2js:noInline')
  static ReferralTreeSlice getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReferralTreeSlice>(create);
  static ReferralTreeSlice? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<ReferralTreeNode> get nodes => $_getList(0);

  @$pb.TagNumber(2)
  $core.List<ReferralShareDoc> get branchShares => $_getList(1);
}

class ReqReferralShareSet extends $pb.GeneratedMessage {
  factory ReqReferralShareSet({
    $fixnum.Int64? parentUid,
    $fixnum.Int64? childUid,
    $core.int? sharePercent,
  }) {
    final $result = create();
    if (parentUid != null) {
      $result.parentUid = parentUid;
    }
    if (childUid != null) {
      $result.childUid = childUid;
    }
    if (sharePercent != null) {
      $result.sharePercent = sharePercent;
    }
    return $result;
  }
  ReqReferralShareSet._() : super();
  factory ReqReferralShareSet.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ReqReferralShareSet.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ReqReferralShareSet', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'parentUid')
    ..aInt64(2, _omitFieldNames ? '' : 'childUid')
    ..a<$core.int>(3, _omitFieldNames ? '' : 'sharePercent', $pb.PbFieldType.O3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ReqReferralShareSet clone() => ReqReferralShareSet()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ReqReferralShareSet copyWith(void Function(ReqReferralShareSet) updates) => super.copyWith((message) => updates(message as ReqReferralShareSet)) as ReqReferralShareSet;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReqReferralShareSet create() => ReqReferralShareSet._();
  ReqReferralShareSet createEmptyInstance() => create();
  static $pb.PbList<ReqReferralShareSet> createRepeated() => $pb.PbList<ReqReferralShareSet>();
  @$core.pragma('dart2js:noInline')
  static ReqReferralShareSet getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqReferralShareSet>(create);
  static ReqReferralShareSet? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get parentUid => $_getI64(0);
  @$pb.TagNumber(1)
  set parentUid($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasParentUid() => $_has(0);
  @$pb.TagNumber(1)
  void clearParentUid() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get childUid => $_getI64(1);
  @$pb.TagNumber(2)
  set childUid($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasChildUid() => $_has(1);
  @$pb.TagNumber(2)
  void clearChildUid() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get sharePercent => $_getIZ(2);
  @$pb.TagNumber(3)
  set sharePercent($core.int v) { $_setSignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasSharePercent() => $_has(2);
  @$pb.TagNumber(3)
  void clearSharePercent() => clearField(3);
}

class ResReferralShareSet extends $pb.GeneratedMessage {
  factory ResReferralShareSet({
    $core.bool? success,
  }) {
    final $result = create();
    if (success != null) {
      $result.success = success;
    }
    return $result;
  }
  ResReferralShareSet._() : super();
  factory ResReferralShareSet.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ResReferralShareSet.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ResReferralShareSet', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ResReferralShareSet clone() => ResReferralShareSet()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ResReferralShareSet copyWith(void Function(ResReferralShareSet) updates) => super.copyWith((message) => updates(message as ResReferralShareSet)) as ResReferralShareSet;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResReferralShareSet create() => ResReferralShareSet._();
  ResReferralShareSet createEmptyInstance() => create();
  static $pb.PbList<ResReferralShareSet> createRepeated() => $pb.PbList<ResReferralShareSet>();
  @$core.pragma('dart2js:noInline')
  static ResReferralShareSet getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResReferralShareSet>(create);
  static ResReferralShareSet? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool v) { $_setBool(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => clearField(1);
}

class ReqReferralTreeGet extends $pb.GeneratedMessage {
  factory ReqReferralTreeGet({
    $fixnum.Int64? rootId,
    $core.int? depth,
  }) {
    final $result = create();
    if (rootId != null) {
      $result.rootId = rootId;
    }
    if (depth != null) {
      $result.depth = depth;
    }
    return $result;
  }
  ReqReferralTreeGet._() : super();
  factory ReqReferralTreeGet.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ReqReferralTreeGet.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ReqReferralTreeGet', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'rootId')
    ..a<$core.int>(2, _omitFieldNames ? '' : 'depth', $pb.PbFieldType.O3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ReqReferralTreeGet clone() => ReqReferralTreeGet()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ReqReferralTreeGet copyWith(void Function(ReqReferralTreeGet) updates) => super.copyWith((message) => updates(message as ReqReferralTreeGet)) as ReqReferralTreeGet;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReqReferralTreeGet create() => ReqReferralTreeGet._();
  ReqReferralTreeGet createEmptyInstance() => create();
  static $pb.PbList<ReqReferralTreeGet> createRepeated() => $pb.PbList<ReqReferralTreeGet>();
  @$core.pragma('dart2js:noInline')
  static ReqReferralTreeGet getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqReferralTreeGet>(create);
  static ReqReferralTreeGet? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get rootId => $_getI64(0);
  @$pb.TagNumber(1)
  set rootId($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasRootId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRootId() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get depth => $_getIZ(1);
  @$pb.TagNumber(2)
  set depth($core.int v) { $_setSignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasDepth() => $_has(1);
  @$pb.TagNumber(2)
  void clearDepth() => clearField(2);
}

class ResReferralTreeGet extends $pb.GeneratedMessage {
  factory ResReferralTreeGet({
    ReferralTreeSlice? slice,
  }) {
    final $result = create();
    if (slice != null) {
      $result.slice = slice;
    }
    return $result;
  }
  ResReferralTreeGet._() : super();
  factory ResReferralTreeGet.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ResReferralTreeGet.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ResReferralTreeGet', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aOM<ReferralTreeSlice>(1, _omitFieldNames ? '' : 'slice', subBuilder: ReferralTreeSlice.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ResReferralTreeGet clone() => ResReferralTreeGet()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ResReferralTreeGet copyWith(void Function(ResReferralTreeGet) updates) => super.copyWith((message) => updates(message as ResReferralTreeGet)) as ResReferralTreeGet;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResReferralTreeGet create() => ResReferralTreeGet._();
  ResReferralTreeGet createEmptyInstance() => create();
  static $pb.PbList<ResReferralTreeGet> createRepeated() => $pb.PbList<ResReferralTreeGet>();
  @$core.pragma('dart2js:noInline')
  static ResReferralTreeGet getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResReferralTreeGet>(create);
  static ResReferralTreeGet? _defaultInstance;

  @$pb.TagNumber(1)
  ReferralTreeSlice get slice => $_getN(0);
  @$pb.TagNumber(1)
  set slice(ReferralTreeSlice v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasSlice() => $_has(0);
  @$pb.TagNumber(1)
  void clearSlice() => clearField(1);
  @$pb.TagNumber(1)
  ReferralTreeSlice ensureSlice() => $_ensure(0);
}

class ReqReferralCodeList extends $pb.GeneratedMessage {
  factory ReqReferralCodeList() => create();
  ReqReferralCodeList._() : super();
  factory ReqReferralCodeList.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ReqReferralCodeList.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ReqReferralCodeList', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ReqReferralCodeList clone() => ReqReferralCodeList()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ReqReferralCodeList copyWith(void Function(ReqReferralCodeList) updates) => super.copyWith((message) => updates(message as ReqReferralCodeList)) as ReqReferralCodeList;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReqReferralCodeList create() => ReqReferralCodeList._();
  ReqReferralCodeList createEmptyInstance() => create();
  static $pb.PbList<ReqReferralCodeList> createRepeated() => $pb.PbList<ReqReferralCodeList>();
  @$core.pragma('dart2js:noInline')
  static ReqReferralCodeList getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqReferralCodeList>(create);
  static ReqReferralCodeList? _defaultInstance;
}

class ResReferralCodeList extends $pb.GeneratedMessage {
  factory ResReferralCodeList({
    $core.Iterable<ReferralCodeDoc>? items,
  }) {
    final $result = create();
    if (items != null) {
      $result.items.addAll(items);
    }
    return $result;
  }
  ResReferralCodeList._() : super();
  factory ResReferralCodeList.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ResReferralCodeList.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ResReferralCodeList', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..pc<ReferralCodeDoc>(1, _omitFieldNames ? '' : 'items', $pb.PbFieldType.PM, subBuilder: ReferralCodeDoc.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ResReferralCodeList clone() => ResReferralCodeList()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ResReferralCodeList copyWith(void Function(ResReferralCodeList) updates) => super.copyWith((message) => updates(message as ResReferralCodeList)) as ResReferralCodeList;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResReferralCodeList create() => ResReferralCodeList._();
  ResReferralCodeList createEmptyInstance() => create();
  static $pb.PbList<ResReferralCodeList> createRepeated() => $pb.PbList<ResReferralCodeList>();
  @$core.pragma('dart2js:noInline')
  static ResReferralCodeList getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResReferralCodeList>(create);
  static ResReferralCodeList? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<ReferralCodeDoc> get items => $_getList(0);
}

class ReqReferralCodePut extends $pb.GeneratedMessage {
  factory ReqReferralCodePut({
    ReferralCodeDoc? code,
  }) {
    final $result = create();
    if (code != null) {
      $result.code = code;
    }
    return $result;
  }
  ReqReferralCodePut._() : super();
  factory ReqReferralCodePut.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ReqReferralCodePut.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ReqReferralCodePut', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aOM<ReferralCodeDoc>(1, _omitFieldNames ? '' : 'code', subBuilder: ReferralCodeDoc.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ReqReferralCodePut clone() => ReqReferralCodePut()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ReqReferralCodePut copyWith(void Function(ReqReferralCodePut) updates) => super.copyWith((message) => updates(message as ReqReferralCodePut)) as ReqReferralCodePut;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReqReferralCodePut create() => ReqReferralCodePut._();
  ReqReferralCodePut createEmptyInstance() => create();
  static $pb.PbList<ReqReferralCodePut> createRepeated() => $pb.PbList<ReqReferralCodePut>();
  @$core.pragma('dart2js:noInline')
  static ReqReferralCodePut getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqReferralCodePut>(create);
  static ReqReferralCodePut? _defaultInstance;

  @$pb.TagNumber(1)
  ReferralCodeDoc get code => $_getN(0);
  @$pb.TagNumber(1)
  set code(ReferralCodeDoc v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasCode() => $_has(0);
  @$pb.TagNumber(1)
  void clearCode() => clearField(1);
  @$pb.TagNumber(1)
  ReferralCodeDoc ensureCode() => $_ensure(0);
}

class ReqReferralCodeDelete extends $pb.GeneratedMessage {
  factory ReqReferralCodeDelete({
    $core.String? code,
  }) {
    final $result = create();
    if (code != null) {
      $result.code = code;
    }
    return $result;
  }
  ReqReferralCodeDelete._() : super();
  factory ReqReferralCodeDelete.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ReqReferralCodeDelete.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ReqReferralCodeDelete', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'code')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ReqReferralCodeDelete clone() => ReqReferralCodeDelete()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ReqReferralCodeDelete copyWith(void Function(ReqReferralCodeDelete) updates) => super.copyWith((message) => updates(message as ReqReferralCodeDelete)) as ReqReferralCodeDelete;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReqReferralCodeDelete create() => ReqReferralCodeDelete._();
  ReqReferralCodeDelete createEmptyInstance() => create();
  static $pb.PbList<ReqReferralCodeDelete> createRepeated() => $pb.PbList<ReqReferralCodeDelete>();
  @$core.pragma('dart2js:noInline')
  static ReqReferralCodeDelete getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqReferralCodeDelete>(create);
  static ReqReferralCodeDelete? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get code => $_getSZ(0);
  @$pb.TagNumber(1)
  set code($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasCode() => $_has(0);
  @$pb.TagNumber(1)
  void clearCode() => clearField(1);
}

class ReferralStatPeriod extends $pb.GeneratedMessage {
  factory ReferralStatPeriod({
    $fixnum.Int64? fromMs,
    $fixnum.Int64? toMs,
  }) {
    final $result = create();
    if (fromMs != null) {
      $result.fromMs = fromMs;
    }
    if (toMs != null) {
      $result.toMs = toMs;
    }
    return $result;
  }
  ReferralStatPeriod._() : super();
  factory ReferralStatPeriod.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ReferralStatPeriod.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ReferralStatPeriod', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'fromMs')
    ..aInt64(2, _omitFieldNames ? '' : 'toMs')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ReferralStatPeriod clone() => ReferralStatPeriod()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ReferralStatPeriod copyWith(void Function(ReferralStatPeriod) updates) => super.copyWith((message) => updates(message as ReferralStatPeriod)) as ReferralStatPeriod;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReferralStatPeriod create() => ReferralStatPeriod._();
  ReferralStatPeriod createEmptyInstance() => create();
  static $pb.PbList<ReferralStatPeriod> createRepeated() => $pb.PbList<ReferralStatPeriod>();
  @$core.pragma('dart2js:noInline')
  static ReferralStatPeriod getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReferralStatPeriod>(create);
  static ReferralStatPeriod? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get fromMs => $_getI64(0);
  @$pb.TagNumber(1)
  set fromMs($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasFromMs() => $_has(0);
  @$pb.TagNumber(1)
  void clearFromMs() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get toMs => $_getI64(1);
  @$pb.TagNumber(2)
  set toMs($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasToMs() => $_has(1);
  @$pb.TagNumber(2)
  void clearToMs() => clearField(2);
}

class ReferralUserStatColumn extends $pb.GeneratedMessage {
  factory ReferralUserStatColumn({
    $core.int? referralCount,
    $core.double? commissionIdr,
    $core.double? commissionUsd,
    $fixnum.Int64? tokensAlien,
    $fixnum.Int64? tokensApi,
  }) {
    final $result = create();
    if (referralCount != null) {
      $result.referralCount = referralCount;
    }
    if (commissionIdr != null) {
      $result.commissionIdr = commissionIdr;
    }
    if (commissionUsd != null) {
      $result.commissionUsd = commissionUsd;
    }
    if (tokensAlien != null) {
      $result.tokensAlien = tokensAlien;
    }
    if (tokensApi != null) {
      $result.tokensApi = tokensApi;
    }
    return $result;
  }
  ReferralUserStatColumn._() : super();
  factory ReferralUserStatColumn.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ReferralUserStatColumn.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ReferralUserStatColumn', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'referralCount', $pb.PbFieldType.O3)
    ..a<$core.double>(2, _omitFieldNames ? '' : 'commissionIdr', $pb.PbFieldType.OD)
    ..a<$core.double>(3, _omitFieldNames ? '' : 'commissionUsd', $pb.PbFieldType.OD)
    ..aInt64(4, _omitFieldNames ? '' : 'tokensAlien')
    ..aInt64(5, _omitFieldNames ? '' : 'tokensApi')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ReferralUserStatColumn clone() => ReferralUserStatColumn()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ReferralUserStatColumn copyWith(void Function(ReferralUserStatColumn) updates) => super.copyWith((message) => updates(message as ReferralUserStatColumn)) as ReferralUserStatColumn;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReferralUserStatColumn create() => ReferralUserStatColumn._();
  ReferralUserStatColumn createEmptyInstance() => create();
  static $pb.PbList<ReferralUserStatColumn> createRepeated() => $pb.PbList<ReferralUserStatColumn>();
  @$core.pragma('dart2js:noInline')
  static ReferralUserStatColumn getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReferralUserStatColumn>(create);
  static ReferralUserStatColumn? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get referralCount => $_getIZ(0);
  @$pb.TagNumber(1)
  set referralCount($core.int v) { $_setSignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasReferralCount() => $_has(0);
  @$pb.TagNumber(1)
  void clearReferralCount() => clearField(1);

  @$pb.TagNumber(2)
  $core.double get commissionIdr => $_getN(1);
  @$pb.TagNumber(2)
  set commissionIdr($core.double v) { $_setDouble(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasCommissionIdr() => $_has(1);
  @$pb.TagNumber(2)
  void clearCommissionIdr() => clearField(2);

  @$pb.TagNumber(3)
  $core.double get commissionUsd => $_getN(2);
  @$pb.TagNumber(3)
  set commissionUsd($core.double v) { $_setDouble(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasCommissionUsd() => $_has(2);
  @$pb.TagNumber(3)
  void clearCommissionUsd() => clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get tokensAlien => $_getI64(3);
  @$pb.TagNumber(4)
  set tokensAlien($fixnum.Int64 v) { $_setInt64(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasTokensAlien() => $_has(3);
  @$pb.TagNumber(4)
  void clearTokensAlien() => clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get tokensApi => $_getI64(4);
  @$pb.TagNumber(5)
  set tokensApi($fixnum.Int64 v) { $_setInt64(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasTokensApi() => $_has(4);
  @$pb.TagNumber(5)
  void clearTokensApi() => clearField(5);
}

class ReqReferralUserStats extends $pb.GeneratedMessage {
  factory ReqReferralUserStats({
    $fixnum.Int64? subjectUid,
    ReferralStatPeriod? colA,
    ReferralStatPeriod? colB,
  }) {
    final $result = create();
    if (subjectUid != null) {
      $result.subjectUid = subjectUid;
    }
    if (colA != null) {
      $result.colA = colA;
    }
    if (colB != null) {
      $result.colB = colB;
    }
    return $result;
  }
  ReqReferralUserStats._() : super();
  factory ReqReferralUserStats.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ReqReferralUserStats.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ReqReferralUserStats', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'subjectUid')
    ..aOM<ReferralStatPeriod>(2, _omitFieldNames ? '' : 'colA', subBuilder: ReferralStatPeriod.create)
    ..aOM<ReferralStatPeriod>(3, _omitFieldNames ? '' : 'colB', subBuilder: ReferralStatPeriod.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ReqReferralUserStats clone() => ReqReferralUserStats()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ReqReferralUserStats copyWith(void Function(ReqReferralUserStats) updates) => super.copyWith((message) => updates(message as ReqReferralUserStats)) as ReqReferralUserStats;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReqReferralUserStats create() => ReqReferralUserStats._();
  ReqReferralUserStats createEmptyInstance() => create();
  static $pb.PbList<ReqReferralUserStats> createRepeated() => $pb.PbList<ReqReferralUserStats>();
  @$core.pragma('dart2js:noInline')
  static ReqReferralUserStats getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqReferralUserStats>(create);
  static ReqReferralUserStats? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get subjectUid => $_getI64(0);
  @$pb.TagNumber(1)
  set subjectUid($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasSubjectUid() => $_has(0);
  @$pb.TagNumber(1)
  void clearSubjectUid() => clearField(1);

  @$pb.TagNumber(2)
  ReferralStatPeriod get colA => $_getN(1);
  @$pb.TagNumber(2)
  set colA(ReferralStatPeriod v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasColA() => $_has(1);
  @$pb.TagNumber(2)
  void clearColA() => clearField(2);
  @$pb.TagNumber(2)
  ReferralStatPeriod ensureColA() => $_ensure(1);

  @$pb.TagNumber(3)
  ReferralStatPeriod get colB => $_getN(2);
  @$pb.TagNumber(3)
  set colB(ReferralStatPeriod v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasColB() => $_has(2);
  @$pb.TagNumber(3)
  void clearColB() => clearField(3);
  @$pb.TagNumber(3)
  ReferralStatPeriod ensureColB() => $_ensure(2);
}

class ResReferralUserStats extends $pb.GeneratedMessage {
  factory ResReferralUserStats({
    ReferralUserStatColumn? colA,
    ReferralUserStatColumn? colB,
  }) {
    final $result = create();
    if (colA != null) {
      $result.colA = colA;
    }
    if (colB != null) {
      $result.colB = colB;
    }
    return $result;
  }
  ResReferralUserStats._() : super();
  factory ResReferralUserStats.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ResReferralUserStats.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ResReferralUserStats', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aOM<ReferralUserStatColumn>(1, _omitFieldNames ? '' : 'colA', subBuilder: ReferralUserStatColumn.create)
    ..aOM<ReferralUserStatColumn>(2, _omitFieldNames ? '' : 'colB', subBuilder: ReferralUserStatColumn.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ResReferralUserStats clone() => ResReferralUserStats()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ResReferralUserStats copyWith(void Function(ResReferralUserStats) updates) => super.copyWith((message) => updates(message as ResReferralUserStats)) as ResReferralUserStats;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResReferralUserStats create() => ResReferralUserStats._();
  ResReferralUserStats createEmptyInstance() => create();
  static $pb.PbList<ResReferralUserStats> createRepeated() => $pb.PbList<ResReferralUserStats>();
  @$core.pragma('dart2js:noInline')
  static ResReferralUserStats getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResReferralUserStats>(create);
  static ResReferralUserStats? _defaultInstance;

  @$pb.TagNumber(1)
  ReferralUserStatColumn get colA => $_getN(0);
  @$pb.TagNumber(1)
  set colA(ReferralUserStatColumn v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasColA() => $_has(0);
  @$pb.TagNumber(1)
  void clearColA() => clearField(1);
  @$pb.TagNumber(1)
  ReferralUserStatColumn ensureColA() => $_ensure(0);

  @$pb.TagNumber(2)
  ReferralUserStatColumn get colB => $_getN(1);
  @$pb.TagNumber(2)
  set colB(ReferralUserStatColumn v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasColB() => $_has(1);
  @$pb.TagNumber(2)
  void clearColB() => clearField(2);
  @$pb.TagNumber(2)
  ReferralUserStatColumn ensureColB() => $_ensure(1);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
