//
//  Generated code. Do not modify.
//  source: c35/site.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

class SiteBlock extends $pb.GeneratedMessage {
  factory SiteBlock({
    $core.String? id,
    $core.String? type,
    $core.String? propsJson,
  }) {
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    if (type != null) {
      $result.type = type;
    }
    if (propsJson != null) {
      $result.propsJson = propsJson;
    }
    return $result;
  }
  SiteBlock._() : super();
  factory SiteBlock.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SiteBlock.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SiteBlock', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'type')
    ..aOS(3, _omitFieldNames ? '' : 'propsJson')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SiteBlock clone() => SiteBlock()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SiteBlock copyWith(void Function(SiteBlock) updates) => super.copyWith((message) => updates(message as SiteBlock)) as SiteBlock;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SiteBlock create() => SiteBlock._();
  SiteBlock createEmptyInstance() => create();
  static $pb.PbList<SiteBlock> createRepeated() => $pb.PbList<SiteBlock>();
  @$core.pragma('dart2js:noInline')
  static SiteBlock getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SiteBlock>(create);
  static SiteBlock? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get type => $_getSZ(1);
  @$pb.TagNumber(2)
  set type($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasType() => $_has(1);
  @$pb.TagNumber(2)
  void clearType() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get propsJson => $_getSZ(2);
  @$pb.TagNumber(3)
  set propsJson($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasPropsJson() => $_has(2);
  @$pb.TagNumber(3)
  void clearPropsJson() => clearField(3);
}

class SitePage extends $pb.GeneratedMessage {
  factory SitePage({
    $core.String? path,
    $core.String? title,
    $core.Iterable<SiteBlock>? blocks,
  }) {
    final $result = create();
    if (path != null) {
      $result.path = path;
    }
    if (title != null) {
      $result.title = title;
    }
    if (blocks != null) {
      $result.blocks.addAll(blocks);
    }
    return $result;
  }
  SitePage._() : super();
  factory SitePage.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SitePage.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SitePage', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'path')
    ..aOS(2, _omitFieldNames ? '' : 'title')
    ..pc<SiteBlock>(3, _omitFieldNames ? '' : 'blocks', $pb.PbFieldType.PM, subBuilder: SiteBlock.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SitePage clone() => SitePage()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SitePage copyWith(void Function(SitePage) updates) => super.copyWith((message) => updates(message as SitePage)) as SitePage;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SitePage create() => SitePage._();
  SitePage createEmptyInstance() => create();
  static $pb.PbList<SitePage> createRepeated() => $pb.PbList<SitePage>();
  @$core.pragma('dart2js:noInline')
  static SitePage getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SitePage>(create);
  static SitePage? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get path => $_getSZ(0);
  @$pb.TagNumber(1)
  set path($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearPath() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get title => $_getSZ(1);
  @$pb.TagNumber(2)
  set title($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasTitle() => $_has(1);
  @$pb.TagNumber(2)
  void clearTitle() => clearField(2);

  @$pb.TagNumber(3)
  $core.List<SiteBlock> get blocks => $_getList(2);
}

class SiteDoc extends $pb.GeneratedMessage {
  factory SiteDoc({
    $core.Iterable<SitePage>? pages,
    $core.String? themeJson,
    $core.String? metaJson,
  }) {
    final $result = create();
    if (pages != null) {
      $result.pages.addAll(pages);
    }
    if (themeJson != null) {
      $result.themeJson = themeJson;
    }
    if (metaJson != null) {
      $result.metaJson = metaJson;
    }
    return $result;
  }
  SiteDoc._() : super();
  factory SiteDoc.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SiteDoc.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SiteDoc', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..pc<SitePage>(1, _omitFieldNames ? '' : 'pages', $pb.PbFieldType.PM, subBuilder: SitePage.create)
    ..aOS(2, _omitFieldNames ? '' : 'themeJson')
    ..aOS(3, _omitFieldNames ? '' : 'metaJson')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SiteDoc clone() => SiteDoc()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SiteDoc copyWith(void Function(SiteDoc) updates) => super.copyWith((message) => updates(message as SiteDoc)) as SiteDoc;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SiteDoc create() => SiteDoc._();
  SiteDoc createEmptyInstance() => create();
  static $pb.PbList<SiteDoc> createRepeated() => $pb.PbList<SiteDoc>();
  @$core.pragma('dart2js:noInline')
  static SiteDoc getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SiteDoc>(create);
  static SiteDoc? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<SitePage> get pages => $_getList(0);

  @$pb.TagNumber(2)
  $core.String get themeJson => $_getSZ(1);
  @$pb.TagNumber(2)
  set themeJson($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasThemeJson() => $_has(1);
  @$pb.TagNumber(2)
  void clearThemeJson() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get metaJson => $_getSZ(2);
  @$pb.TagNumber(3)
  set metaJson($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasMetaJson() => $_has(2);
  @$pb.TagNumber(3)
  void clearMetaJson() => clearField(3);
}

class SiteConfig extends $pb.GeneratedMessage {
  factory SiteConfig({
    $fixnum.Int64? siteIid,
    $fixnum.Int64? ownerIid,
    $core.String? publishedVersionId,
    $core.String? inventoryCostingMethod,
    $core.String? tz,
    $core.String? payrollPolicyJson,
    $core.String? presencePolicyJson,
    $core.String? capabilitiesJson,
    $fixnum.Int64? alienIdChangedTsMs,
    $fixnum.Int64? createdTsMs,
    $fixnum.Int64? updatedTsMs,
    $fixnum.Int64? deletedTsMs,
  }) {
    final $result = create();
    if (siteIid != null) {
      $result.siteIid = siteIid;
    }
    if (ownerIid != null) {
      $result.ownerIid = ownerIid;
    }
    if (publishedVersionId != null) {
      $result.publishedVersionId = publishedVersionId;
    }
    if (inventoryCostingMethod != null) {
      $result.inventoryCostingMethod = inventoryCostingMethod;
    }
    if (tz != null) {
      $result.tz = tz;
    }
    if (payrollPolicyJson != null) {
      $result.payrollPolicyJson = payrollPolicyJson;
    }
    if (presencePolicyJson != null) {
      $result.presencePolicyJson = presencePolicyJson;
    }
    if (capabilitiesJson != null) {
      $result.capabilitiesJson = capabilitiesJson;
    }
    if (alienIdChangedTsMs != null) {
      $result.alienIdChangedTsMs = alienIdChangedTsMs;
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
  SiteConfig._() : super();
  factory SiteConfig.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SiteConfig.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SiteConfig', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'siteIid')
    ..aInt64(2, _omitFieldNames ? '' : 'ownerIid')
    ..aOS(3, _omitFieldNames ? '' : 'publishedVersionId')
    ..aOS(4, _omitFieldNames ? '' : 'inventoryCostingMethod')
    ..aOS(5, _omitFieldNames ? '' : 'tz')
    ..aOS(6, _omitFieldNames ? '' : 'payrollPolicyJson')
    ..aOS(7, _omitFieldNames ? '' : 'presencePolicyJson')
    ..aOS(8, _omitFieldNames ? '' : 'capabilitiesJson')
    ..aInt64(9, _omitFieldNames ? '' : 'alienIdChangedTsMs')
    ..aInt64(20, _omitFieldNames ? '' : 'createdTsMs')
    ..aInt64(21, _omitFieldNames ? '' : 'updatedTsMs')
    ..aInt64(22, _omitFieldNames ? '' : 'deletedTsMs')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SiteConfig clone() => SiteConfig()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SiteConfig copyWith(void Function(SiteConfig) updates) => super.copyWith((message) => updates(message as SiteConfig)) as SiteConfig;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SiteConfig create() => SiteConfig._();
  SiteConfig createEmptyInstance() => create();
  static $pb.PbList<SiteConfig> createRepeated() => $pb.PbList<SiteConfig>();
  @$core.pragma('dart2js:noInline')
  static SiteConfig getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SiteConfig>(create);
  static SiteConfig? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get siteIid => $_getI64(0);
  @$pb.TagNumber(1)
  set siteIid($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasSiteIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearSiteIid() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get ownerIid => $_getI64(1);
  @$pb.TagNumber(2)
  set ownerIid($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasOwnerIid() => $_has(1);
  @$pb.TagNumber(2)
  void clearOwnerIid() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get publishedVersionId => $_getSZ(2);
  @$pb.TagNumber(3)
  set publishedVersionId($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasPublishedVersionId() => $_has(2);
  @$pb.TagNumber(3)
  void clearPublishedVersionId() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get inventoryCostingMethod => $_getSZ(3);
  @$pb.TagNumber(4)
  set inventoryCostingMethod($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasInventoryCostingMethod() => $_has(3);
  @$pb.TagNumber(4)
  void clearInventoryCostingMethod() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get tz => $_getSZ(4);
  @$pb.TagNumber(5)
  set tz($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasTz() => $_has(4);
  @$pb.TagNumber(5)
  void clearTz() => clearField(5);

  @$pb.TagNumber(6)
  $core.String get payrollPolicyJson => $_getSZ(5);
  @$pb.TagNumber(6)
  set payrollPolicyJson($core.String v) { $_setString(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasPayrollPolicyJson() => $_has(5);
  @$pb.TagNumber(6)
  void clearPayrollPolicyJson() => clearField(6);

  @$pb.TagNumber(7)
  $core.String get presencePolicyJson => $_getSZ(6);
  @$pb.TagNumber(7)
  set presencePolicyJson($core.String v) { $_setString(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasPresencePolicyJson() => $_has(6);
  @$pb.TagNumber(7)
  void clearPresencePolicyJson() => clearField(7);

  @$pb.TagNumber(8)
  $core.String get capabilitiesJson => $_getSZ(7);
  @$pb.TagNumber(8)
  set capabilitiesJson($core.String v) { $_setString(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasCapabilitiesJson() => $_has(7);
  @$pb.TagNumber(8)
  void clearCapabilitiesJson() => clearField(8);

  @$pb.TagNumber(9)
  $fixnum.Int64 get alienIdChangedTsMs => $_getI64(8);
  @$pb.TagNumber(9)
  set alienIdChangedTsMs($fixnum.Int64 v) { $_setInt64(8, v); }
  @$pb.TagNumber(9)
  $core.bool hasAlienIdChangedTsMs() => $_has(8);
  @$pb.TagNumber(9)
  void clearAlienIdChangedTsMs() => clearField(9);

  @$pb.TagNumber(20)
  $fixnum.Int64 get createdTsMs => $_getI64(9);
  @$pb.TagNumber(20)
  set createdTsMs($fixnum.Int64 v) { $_setInt64(9, v); }
  @$pb.TagNumber(20)
  $core.bool hasCreatedTsMs() => $_has(9);
  @$pb.TagNumber(20)
  void clearCreatedTsMs() => clearField(20);

  @$pb.TagNumber(21)
  $fixnum.Int64 get updatedTsMs => $_getI64(10);
  @$pb.TagNumber(21)
  set updatedTsMs($fixnum.Int64 v) { $_setInt64(10, v); }
  @$pb.TagNumber(21)
  $core.bool hasUpdatedTsMs() => $_has(10);
  @$pb.TagNumber(21)
  void clearUpdatedTsMs() => clearField(21);

  @$pb.TagNumber(22)
  $fixnum.Int64 get deletedTsMs => $_getI64(11);
  @$pb.TagNumber(22)
  set deletedTsMs($fixnum.Int64 v) { $_setInt64(11, v); }
  @$pb.TagNumber(22)
  $core.bool hasDeletedTsMs() => $_has(11);
  @$pb.TagNumber(22)
  void clearDeletedTsMs() => clearField(22);
}

class SiteDomain extends $pb.GeneratedMessage {
  factory SiteDomain({
    $fixnum.Int64? id,
    $fixnum.Int64? siteIid,
    $core.String? hostname,
    $core.bool? isPrimary,
    $core.String? tlsStatus,
    $fixnum.Int64? verifiedTsMs,
    $fixnum.Int64? createdTsMs,
    $fixnum.Int64? updatedTsMs,
    $fixnum.Int64? deletedTsMs,
  }) {
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    if (siteIid != null) {
      $result.siteIid = siteIid;
    }
    if (hostname != null) {
      $result.hostname = hostname;
    }
    if (isPrimary != null) {
      $result.isPrimary = isPrimary;
    }
    if (tlsStatus != null) {
      $result.tlsStatus = tlsStatus;
    }
    if (verifiedTsMs != null) {
      $result.verifiedTsMs = verifiedTsMs;
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
  SiteDomain._() : super();
  factory SiteDomain.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SiteDomain.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SiteDomain', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..aInt64(2, _omitFieldNames ? '' : 'siteIid')
    ..aOS(3, _omitFieldNames ? '' : 'hostname')
    ..aOB(4, _omitFieldNames ? '' : 'isPrimary')
    ..aOS(5, _omitFieldNames ? '' : 'tlsStatus')
    ..aInt64(6, _omitFieldNames ? '' : 'verifiedTsMs')
    ..aInt64(20, _omitFieldNames ? '' : 'createdTsMs')
    ..aInt64(21, _omitFieldNames ? '' : 'updatedTsMs')
    ..aInt64(22, _omitFieldNames ? '' : 'deletedTsMs')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SiteDomain clone() => SiteDomain()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SiteDomain copyWith(void Function(SiteDomain) updates) => super.copyWith((message) => updates(message as SiteDomain)) as SiteDomain;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SiteDomain create() => SiteDomain._();
  SiteDomain createEmptyInstance() => create();
  static $pb.PbList<SiteDomain> createRepeated() => $pb.PbList<SiteDomain>();
  @$core.pragma('dart2js:noInline')
  static SiteDomain getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SiteDomain>(create);
  static SiteDomain? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get siteIid => $_getI64(1);
  @$pb.TagNumber(2)
  set siteIid($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasSiteIid() => $_has(1);
  @$pb.TagNumber(2)
  void clearSiteIid() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get hostname => $_getSZ(2);
  @$pb.TagNumber(3)
  set hostname($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasHostname() => $_has(2);
  @$pb.TagNumber(3)
  void clearHostname() => clearField(3);

  @$pb.TagNumber(4)
  $core.bool get isPrimary => $_getBF(3);
  @$pb.TagNumber(4)
  set isPrimary($core.bool v) { $_setBool(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasIsPrimary() => $_has(3);
  @$pb.TagNumber(4)
  void clearIsPrimary() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get tlsStatus => $_getSZ(4);
  @$pb.TagNumber(5)
  set tlsStatus($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasTlsStatus() => $_has(4);
  @$pb.TagNumber(5)
  void clearTlsStatus() => clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get verifiedTsMs => $_getI64(5);
  @$pb.TagNumber(6)
  set verifiedTsMs($fixnum.Int64 v) { $_setInt64(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasVerifiedTsMs() => $_has(5);
  @$pb.TagNumber(6)
  void clearVerifiedTsMs() => clearField(6);

  @$pb.TagNumber(20)
  $fixnum.Int64 get createdTsMs => $_getI64(6);
  @$pb.TagNumber(20)
  set createdTsMs($fixnum.Int64 v) { $_setInt64(6, v); }
  @$pb.TagNumber(20)
  $core.bool hasCreatedTsMs() => $_has(6);
  @$pb.TagNumber(20)
  void clearCreatedTsMs() => clearField(20);

  @$pb.TagNumber(21)
  $fixnum.Int64 get updatedTsMs => $_getI64(7);
  @$pb.TagNumber(21)
  set updatedTsMs($fixnum.Int64 v) { $_setInt64(7, v); }
  @$pb.TagNumber(21)
  $core.bool hasUpdatedTsMs() => $_has(7);
  @$pb.TagNumber(21)
  void clearUpdatedTsMs() => clearField(21);

  @$pb.TagNumber(22)
  $fixnum.Int64 get deletedTsMs => $_getI64(8);
  @$pb.TagNumber(22)
  set deletedTsMs($fixnum.Int64 v) { $_setInt64(8, v); }
  @$pb.TagNumber(22)
  $core.bool hasDeletedTsMs() => $_has(8);
  @$pb.TagNumber(22)
  void clearDeletedTsMs() => clearField(22);
}

class SiteDraft extends $pb.GeneratedMessage {
  factory SiteDraft({
    $fixnum.Int64? siteIid,
    $fixnum.Int64? ownerIid,
    SiteDoc? doc,
    $fixnum.Int64? createdTsMs,
    $fixnum.Int64? updatedTsMs,
    $fixnum.Int64? deletedTsMs,
  }) {
    final $result = create();
    if (siteIid != null) {
      $result.siteIid = siteIid;
    }
    if (ownerIid != null) {
      $result.ownerIid = ownerIid;
    }
    if (doc != null) {
      $result.doc = doc;
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
  SiteDraft._() : super();
  factory SiteDraft.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SiteDraft.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SiteDraft', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'siteIid')
    ..aInt64(2, _omitFieldNames ? '' : 'ownerIid')
    ..aOM<SiteDoc>(3, _omitFieldNames ? '' : 'doc', subBuilder: SiteDoc.create)
    ..aInt64(20, _omitFieldNames ? '' : 'createdTsMs')
    ..aInt64(21, _omitFieldNames ? '' : 'updatedTsMs')
    ..aInt64(22, _omitFieldNames ? '' : 'deletedTsMs')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SiteDraft clone() => SiteDraft()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SiteDraft copyWith(void Function(SiteDraft) updates) => super.copyWith((message) => updates(message as SiteDraft)) as SiteDraft;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SiteDraft create() => SiteDraft._();
  SiteDraft createEmptyInstance() => create();
  static $pb.PbList<SiteDraft> createRepeated() => $pb.PbList<SiteDraft>();
  @$core.pragma('dart2js:noInline')
  static SiteDraft getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SiteDraft>(create);
  static SiteDraft? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get siteIid => $_getI64(0);
  @$pb.TagNumber(1)
  set siteIid($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasSiteIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearSiteIid() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get ownerIid => $_getI64(1);
  @$pb.TagNumber(2)
  set ownerIid($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasOwnerIid() => $_has(1);
  @$pb.TagNumber(2)
  void clearOwnerIid() => clearField(2);

  @$pb.TagNumber(3)
  SiteDoc get doc => $_getN(2);
  @$pb.TagNumber(3)
  set doc(SiteDoc v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasDoc() => $_has(2);
  @$pb.TagNumber(3)
  void clearDoc() => clearField(3);
  @$pb.TagNumber(3)
  SiteDoc ensureDoc() => $_ensure(2);

  @$pb.TagNumber(20)
  $fixnum.Int64 get createdTsMs => $_getI64(3);
  @$pb.TagNumber(20)
  set createdTsMs($fixnum.Int64 v) { $_setInt64(3, v); }
  @$pb.TagNumber(20)
  $core.bool hasCreatedTsMs() => $_has(3);
  @$pb.TagNumber(20)
  void clearCreatedTsMs() => clearField(20);

  @$pb.TagNumber(21)
  $fixnum.Int64 get updatedTsMs => $_getI64(4);
  @$pb.TagNumber(21)
  set updatedTsMs($fixnum.Int64 v) { $_setInt64(4, v); }
  @$pb.TagNumber(21)
  $core.bool hasUpdatedTsMs() => $_has(4);
  @$pb.TagNumber(21)
  void clearUpdatedTsMs() => clearField(21);

  @$pb.TagNumber(22)
  $fixnum.Int64 get deletedTsMs => $_getI64(5);
  @$pb.TagNumber(22)
  set deletedTsMs($fixnum.Int64 v) { $_setInt64(5, v); }
  @$pb.TagNumber(22)
  $core.bool hasDeletedTsMs() => $_has(5);
  @$pb.TagNumber(22)
  void clearDeletedTsMs() => clearField(22);
}

class SitePublish extends $pb.GeneratedMessage {
  factory SitePublish({
    $fixnum.Int64? siteIid,
    $core.String? versionId,
    SiteDoc? doc,
    $core.String? renderHash,
    $fixnum.Int64? publishedTsMs,
    $core.bool? isActive,
    $fixnum.Int64? createdTsMs,
    $fixnum.Int64? updatedTsMs,
    $fixnum.Int64? deletedTsMs,
  }) {
    final $result = create();
    if (siteIid != null) {
      $result.siteIid = siteIid;
    }
    if (versionId != null) {
      $result.versionId = versionId;
    }
    if (doc != null) {
      $result.doc = doc;
    }
    if (renderHash != null) {
      $result.renderHash = renderHash;
    }
    if (publishedTsMs != null) {
      $result.publishedTsMs = publishedTsMs;
    }
    if (isActive != null) {
      $result.isActive = isActive;
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
  SitePublish._() : super();
  factory SitePublish.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SitePublish.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SitePublish', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'siteIid')
    ..aOS(2, _omitFieldNames ? '' : 'versionId')
    ..aOM<SiteDoc>(3, _omitFieldNames ? '' : 'doc', subBuilder: SiteDoc.create)
    ..aOS(4, _omitFieldNames ? '' : 'renderHash')
    ..aInt64(5, _omitFieldNames ? '' : 'publishedTsMs')
    ..aOB(6, _omitFieldNames ? '' : 'isActive')
    ..aInt64(20, _omitFieldNames ? '' : 'createdTsMs')
    ..aInt64(21, _omitFieldNames ? '' : 'updatedTsMs')
    ..aInt64(22, _omitFieldNames ? '' : 'deletedTsMs')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SitePublish clone() => SitePublish()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SitePublish copyWith(void Function(SitePublish) updates) => super.copyWith((message) => updates(message as SitePublish)) as SitePublish;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SitePublish create() => SitePublish._();
  SitePublish createEmptyInstance() => create();
  static $pb.PbList<SitePublish> createRepeated() => $pb.PbList<SitePublish>();
  @$core.pragma('dart2js:noInline')
  static SitePublish getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SitePublish>(create);
  static SitePublish? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get siteIid => $_getI64(0);
  @$pb.TagNumber(1)
  set siteIid($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasSiteIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearSiteIid() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get versionId => $_getSZ(1);
  @$pb.TagNumber(2)
  set versionId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasVersionId() => $_has(1);
  @$pb.TagNumber(2)
  void clearVersionId() => clearField(2);

  @$pb.TagNumber(3)
  SiteDoc get doc => $_getN(2);
  @$pb.TagNumber(3)
  set doc(SiteDoc v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasDoc() => $_has(2);
  @$pb.TagNumber(3)
  void clearDoc() => clearField(3);
  @$pb.TagNumber(3)
  SiteDoc ensureDoc() => $_ensure(2);

  @$pb.TagNumber(4)
  $core.String get renderHash => $_getSZ(3);
  @$pb.TagNumber(4)
  set renderHash($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasRenderHash() => $_has(3);
  @$pb.TagNumber(4)
  void clearRenderHash() => clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get publishedTsMs => $_getI64(4);
  @$pb.TagNumber(5)
  set publishedTsMs($fixnum.Int64 v) { $_setInt64(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasPublishedTsMs() => $_has(4);
  @$pb.TagNumber(5)
  void clearPublishedTsMs() => clearField(5);

  @$pb.TagNumber(6)
  $core.bool get isActive => $_getBF(5);
  @$pb.TagNumber(6)
  set isActive($core.bool v) { $_setBool(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasIsActive() => $_has(5);
  @$pb.TagNumber(6)
  void clearIsActive() => clearField(6);

  @$pb.TagNumber(20)
  $fixnum.Int64 get createdTsMs => $_getI64(6);
  @$pb.TagNumber(20)
  set createdTsMs($fixnum.Int64 v) { $_setInt64(6, v); }
  @$pb.TagNumber(20)
  $core.bool hasCreatedTsMs() => $_has(6);
  @$pb.TagNumber(20)
  void clearCreatedTsMs() => clearField(20);

  @$pb.TagNumber(21)
  $fixnum.Int64 get updatedTsMs => $_getI64(7);
  @$pb.TagNumber(21)
  set updatedTsMs($fixnum.Int64 v) { $_setInt64(7, v); }
  @$pb.TagNumber(21)
  $core.bool hasUpdatedTsMs() => $_has(7);
  @$pb.TagNumber(21)
  void clearUpdatedTsMs() => clearField(21);

  @$pb.TagNumber(22)
  $fixnum.Int64 get deletedTsMs => $_getI64(8);
  @$pb.TagNumber(22)
  set deletedTsMs($fixnum.Int64 v) { $_setInt64(8, v); }
  @$pb.TagNumber(22)
  $core.bool hasDeletedTsMs() => $_has(8);
  @$pb.TagNumber(22)
  void clearDeletedTsMs() => clearField(22);
}

class SiteProduct extends $pb.GeneratedMessage {
  factory SiteProduct({
    $fixnum.Int64? siteIid,
    $fixnum.Int64? productId,
    $core.int? type,
    $core.String? name,
    $core.String? desc,
    $core.String? unit,
    $core.String? sku,
    $fixnum.Int64? rev,
    $core.bool? canSell,
    $core.bool? canReserve,
    $core.bool? trackStock,
    $core.int? stockQty,
    $fixnum.Int64? price,
    $core.String? pic,
    $core.String? category,
    $core.String? productJson,
    $core.bool? isArchived,
    $fixnum.Int64? createdTsMs,
    $fixnum.Int64? updatedTsMs,
    $fixnum.Int64? deletedTsMs,
  }) {
    final $result = create();
    if (siteIid != null) {
      $result.siteIid = siteIid;
    }
    if (productId != null) {
      $result.productId = productId;
    }
    if (type != null) {
      $result.type = type;
    }
    if (name != null) {
      $result.name = name;
    }
    if (desc != null) {
      $result.desc = desc;
    }
    if (unit != null) {
      $result.unit = unit;
    }
    if (sku != null) {
      $result.sku = sku;
    }
    if (rev != null) {
      $result.rev = rev;
    }
    if (canSell != null) {
      $result.canSell = canSell;
    }
    if (canReserve != null) {
      $result.canReserve = canReserve;
    }
    if (trackStock != null) {
      $result.trackStock = trackStock;
    }
    if (stockQty != null) {
      $result.stockQty = stockQty;
    }
    if (price != null) {
      $result.price = price;
    }
    if (pic != null) {
      $result.pic = pic;
    }
    if (category != null) {
      $result.category = category;
    }
    if (productJson != null) {
      $result.productJson = productJson;
    }
    if (isArchived != null) {
      $result.isArchived = isArchived;
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
  SiteProduct._() : super();
  factory SiteProduct.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SiteProduct.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SiteProduct', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'siteIid')
    ..aInt64(2, _omitFieldNames ? '' : 'productId')
    ..a<$core.int>(3, _omitFieldNames ? '' : 'type', $pb.PbFieldType.O3)
    ..aOS(4, _omitFieldNames ? '' : 'name')
    ..aOS(5, _omitFieldNames ? '' : 'desc')
    ..aOS(6, _omitFieldNames ? '' : 'unit')
    ..aOS(7, _omitFieldNames ? '' : 'sku')
    ..aInt64(8, _omitFieldNames ? '' : 'rev')
    ..aOB(9, _omitFieldNames ? '' : 'canSell')
    ..aOB(10, _omitFieldNames ? '' : 'canReserve')
    ..aOB(11, _omitFieldNames ? '' : 'trackStock')
    ..a<$core.int>(12, _omitFieldNames ? '' : 'stockQty', $pb.PbFieldType.O3)
    ..aInt64(13, _omitFieldNames ? '' : 'price')
    ..aOS(14, _omitFieldNames ? '' : 'pic')
    ..aOS(15, _omitFieldNames ? '' : 'category')
    ..aOS(16, _omitFieldNames ? '' : 'productJson')
    ..aOB(17, _omitFieldNames ? '' : 'isArchived')
    ..aInt64(20, _omitFieldNames ? '' : 'createdTsMs')
    ..aInt64(21, _omitFieldNames ? '' : 'updatedTsMs')
    ..aInt64(22, _omitFieldNames ? '' : 'deletedTsMs')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SiteProduct clone() => SiteProduct()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SiteProduct copyWith(void Function(SiteProduct) updates) => super.copyWith((message) => updates(message as SiteProduct)) as SiteProduct;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SiteProduct create() => SiteProduct._();
  SiteProduct createEmptyInstance() => create();
  static $pb.PbList<SiteProduct> createRepeated() => $pb.PbList<SiteProduct>();
  @$core.pragma('dart2js:noInline')
  static SiteProduct getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SiteProduct>(create);
  static SiteProduct? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get siteIid => $_getI64(0);
  @$pb.TagNumber(1)
  set siteIid($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasSiteIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearSiteIid() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get productId => $_getI64(1);
  @$pb.TagNumber(2)
  set productId($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasProductId() => $_has(1);
  @$pb.TagNumber(2)
  void clearProductId() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get type => $_getIZ(2);
  @$pb.TagNumber(3)
  set type($core.int v) { $_setSignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasType() => $_has(2);
  @$pb.TagNumber(3)
  void clearType() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get name => $_getSZ(3);
  @$pb.TagNumber(4)
  set name($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasName() => $_has(3);
  @$pb.TagNumber(4)
  void clearName() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get desc => $_getSZ(4);
  @$pb.TagNumber(5)
  set desc($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasDesc() => $_has(4);
  @$pb.TagNumber(5)
  void clearDesc() => clearField(5);

  @$pb.TagNumber(6)
  $core.String get unit => $_getSZ(5);
  @$pb.TagNumber(6)
  set unit($core.String v) { $_setString(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasUnit() => $_has(5);
  @$pb.TagNumber(6)
  void clearUnit() => clearField(6);

  @$pb.TagNumber(7)
  $core.String get sku => $_getSZ(6);
  @$pb.TagNumber(7)
  set sku($core.String v) { $_setString(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasSku() => $_has(6);
  @$pb.TagNumber(7)
  void clearSku() => clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get rev => $_getI64(7);
  @$pb.TagNumber(8)
  set rev($fixnum.Int64 v) { $_setInt64(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasRev() => $_has(7);
  @$pb.TagNumber(8)
  void clearRev() => clearField(8);

  @$pb.TagNumber(9)
  $core.bool get canSell => $_getBF(8);
  @$pb.TagNumber(9)
  set canSell($core.bool v) { $_setBool(8, v); }
  @$pb.TagNumber(9)
  $core.bool hasCanSell() => $_has(8);
  @$pb.TagNumber(9)
  void clearCanSell() => clearField(9);

  @$pb.TagNumber(10)
  $core.bool get canReserve => $_getBF(9);
  @$pb.TagNumber(10)
  set canReserve($core.bool v) { $_setBool(9, v); }
  @$pb.TagNumber(10)
  $core.bool hasCanReserve() => $_has(9);
  @$pb.TagNumber(10)
  void clearCanReserve() => clearField(10);

  @$pb.TagNumber(11)
  $core.bool get trackStock => $_getBF(10);
  @$pb.TagNumber(11)
  set trackStock($core.bool v) { $_setBool(10, v); }
  @$pb.TagNumber(11)
  $core.bool hasTrackStock() => $_has(10);
  @$pb.TagNumber(11)
  void clearTrackStock() => clearField(11);

  @$pb.TagNumber(12)
  $core.int get stockQty => $_getIZ(11);
  @$pb.TagNumber(12)
  set stockQty($core.int v) { $_setSignedInt32(11, v); }
  @$pb.TagNumber(12)
  $core.bool hasStockQty() => $_has(11);
  @$pb.TagNumber(12)
  void clearStockQty() => clearField(12);

  @$pb.TagNumber(13)
  $fixnum.Int64 get price => $_getI64(12);
  @$pb.TagNumber(13)
  set price($fixnum.Int64 v) { $_setInt64(12, v); }
  @$pb.TagNumber(13)
  $core.bool hasPrice() => $_has(12);
  @$pb.TagNumber(13)
  void clearPrice() => clearField(13);

  @$pb.TagNumber(14)
  $core.String get pic => $_getSZ(13);
  @$pb.TagNumber(14)
  set pic($core.String v) { $_setString(13, v); }
  @$pb.TagNumber(14)
  $core.bool hasPic() => $_has(13);
  @$pb.TagNumber(14)
  void clearPic() => clearField(14);

  @$pb.TagNumber(15)
  $core.String get category => $_getSZ(14);
  @$pb.TagNumber(15)
  set category($core.String v) { $_setString(14, v); }
  @$pb.TagNumber(15)
  $core.bool hasCategory() => $_has(14);
  @$pb.TagNumber(15)
  void clearCategory() => clearField(15);

  @$pb.TagNumber(16)
  $core.String get productJson => $_getSZ(15);
  @$pb.TagNumber(16)
  set productJson($core.String v) { $_setString(15, v); }
  @$pb.TagNumber(16)
  $core.bool hasProductJson() => $_has(15);
  @$pb.TagNumber(16)
  void clearProductJson() => clearField(16);

  @$pb.TagNumber(17)
  $core.bool get isArchived => $_getBF(16);
  @$pb.TagNumber(17)
  set isArchived($core.bool v) { $_setBool(16, v); }
  @$pb.TagNumber(17)
  $core.bool hasIsArchived() => $_has(16);
  @$pb.TagNumber(17)
  void clearIsArchived() => clearField(17);

  @$pb.TagNumber(20)
  $fixnum.Int64 get createdTsMs => $_getI64(17);
  @$pb.TagNumber(20)
  set createdTsMs($fixnum.Int64 v) { $_setInt64(17, v); }
  @$pb.TagNumber(20)
  $core.bool hasCreatedTsMs() => $_has(17);
  @$pb.TagNumber(20)
  void clearCreatedTsMs() => clearField(20);

  @$pb.TagNumber(21)
  $fixnum.Int64 get updatedTsMs => $_getI64(18);
  @$pb.TagNumber(21)
  set updatedTsMs($fixnum.Int64 v) { $_setInt64(18, v); }
  @$pb.TagNumber(21)
  $core.bool hasUpdatedTsMs() => $_has(18);
  @$pb.TagNumber(21)
  void clearUpdatedTsMs() => clearField(21);

  @$pb.TagNumber(22)
  $fixnum.Int64 get deletedTsMs => $_getI64(19);
  @$pb.TagNumber(22)
  set deletedTsMs($fixnum.Int64 v) { $_setInt64(19, v); }
  @$pb.TagNumber(22)
  $core.bool hasDeletedTsMs() => $_has(19);
  @$pb.TagNumber(22)
  void clearDeletedTsMs() => clearField(22);
}

class SiteContact extends $pb.GeneratedMessage {
  factory SiteContact({
    $fixnum.Int64? siteIid,
    $fixnum.Int64? contactId,
    $core.String? name,
    $core.String? phone,
    $core.String? email,
    $core.String? address,
    $core.String? note,
    $core.String? metaJson,
    $core.bool? isArchived,
    $fixnum.Int64? createdTsMs,
    $fixnum.Int64? updatedTsMs,
    $fixnum.Int64? deletedTsMs,
  }) {
    final $result = create();
    if (siteIid != null) {
      $result.siteIid = siteIid;
    }
    if (contactId != null) {
      $result.contactId = contactId;
    }
    if (name != null) {
      $result.name = name;
    }
    if (phone != null) {
      $result.phone = phone;
    }
    if (email != null) {
      $result.email = email;
    }
    if (address != null) {
      $result.address = address;
    }
    if (note != null) {
      $result.note = note;
    }
    if (metaJson != null) {
      $result.metaJson = metaJson;
    }
    if (isArchived != null) {
      $result.isArchived = isArchived;
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
  SiteContact._() : super();
  factory SiteContact.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SiteContact.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SiteContact', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'siteIid')
    ..aInt64(2, _omitFieldNames ? '' : 'contactId')
    ..aOS(3, _omitFieldNames ? '' : 'name')
    ..aOS(4, _omitFieldNames ? '' : 'phone')
    ..aOS(5, _omitFieldNames ? '' : 'email')
    ..aOS(6, _omitFieldNames ? '' : 'address')
    ..aOS(7, _omitFieldNames ? '' : 'note')
    ..aOS(8, _omitFieldNames ? '' : 'metaJson')
    ..aOB(9, _omitFieldNames ? '' : 'isArchived')
    ..aInt64(20, _omitFieldNames ? '' : 'createdTsMs')
    ..aInt64(21, _omitFieldNames ? '' : 'updatedTsMs')
    ..aInt64(22, _omitFieldNames ? '' : 'deletedTsMs')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SiteContact clone() => SiteContact()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SiteContact copyWith(void Function(SiteContact) updates) => super.copyWith((message) => updates(message as SiteContact)) as SiteContact;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SiteContact create() => SiteContact._();
  SiteContact createEmptyInstance() => create();
  static $pb.PbList<SiteContact> createRepeated() => $pb.PbList<SiteContact>();
  @$core.pragma('dart2js:noInline')
  static SiteContact getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SiteContact>(create);
  static SiteContact? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get siteIid => $_getI64(0);
  @$pb.TagNumber(1)
  set siteIid($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasSiteIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearSiteIid() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get contactId => $_getI64(1);
  @$pb.TagNumber(2)
  set contactId($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasContactId() => $_has(1);
  @$pb.TagNumber(2)
  void clearContactId() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get name => $_getSZ(2);
  @$pb.TagNumber(3)
  set name($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasName() => $_has(2);
  @$pb.TagNumber(3)
  void clearName() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get phone => $_getSZ(3);
  @$pb.TagNumber(4)
  set phone($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasPhone() => $_has(3);
  @$pb.TagNumber(4)
  void clearPhone() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get email => $_getSZ(4);
  @$pb.TagNumber(5)
  set email($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasEmail() => $_has(4);
  @$pb.TagNumber(5)
  void clearEmail() => clearField(5);

  @$pb.TagNumber(6)
  $core.String get address => $_getSZ(5);
  @$pb.TagNumber(6)
  set address($core.String v) { $_setString(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasAddress() => $_has(5);
  @$pb.TagNumber(6)
  void clearAddress() => clearField(6);

  @$pb.TagNumber(7)
  $core.String get note => $_getSZ(6);
  @$pb.TagNumber(7)
  set note($core.String v) { $_setString(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasNote() => $_has(6);
  @$pb.TagNumber(7)
  void clearNote() => clearField(7);

  @$pb.TagNumber(8)
  $core.String get metaJson => $_getSZ(7);
  @$pb.TagNumber(8)
  set metaJson($core.String v) { $_setString(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasMetaJson() => $_has(7);
  @$pb.TagNumber(8)
  void clearMetaJson() => clearField(8);

  @$pb.TagNumber(9)
  $core.bool get isArchived => $_getBF(8);
  @$pb.TagNumber(9)
  set isArchived($core.bool v) { $_setBool(8, v); }
  @$pb.TagNumber(9)
  $core.bool hasIsArchived() => $_has(8);
  @$pb.TagNumber(9)
  void clearIsArchived() => clearField(9);

  @$pb.TagNumber(20)
  $fixnum.Int64 get createdTsMs => $_getI64(9);
  @$pb.TagNumber(20)
  set createdTsMs($fixnum.Int64 v) { $_setInt64(9, v); }
  @$pb.TagNumber(20)
  $core.bool hasCreatedTsMs() => $_has(9);
  @$pb.TagNumber(20)
  void clearCreatedTsMs() => clearField(20);

  @$pb.TagNumber(21)
  $fixnum.Int64 get updatedTsMs => $_getI64(10);
  @$pb.TagNumber(21)
  set updatedTsMs($fixnum.Int64 v) { $_setInt64(10, v); }
  @$pb.TagNumber(21)
  $core.bool hasUpdatedTsMs() => $_has(10);
  @$pb.TagNumber(21)
  void clearUpdatedTsMs() => clearField(21);

  @$pb.TagNumber(22)
  $fixnum.Int64 get deletedTsMs => $_getI64(11);
  @$pb.TagNumber(22)
  set deletedTsMs($fixnum.Int64 v) { $_setInt64(11, v); }
  @$pb.TagNumber(22)
  $core.bool hasDeletedTsMs() => $_has(11);
  @$pb.TagNumber(22)
  void clearDeletedTsMs() => clearField(22);
}

class SiteObject extends $pb.GeneratedMessage {
  factory SiteObject({
    $fixnum.Int64? id,
    $fixnum.Int64? siteIid,
    $core.String? clientId,
    $core.String? name,
    $core.String? code,
    $core.String? kind,
    $fixnum.Int64? productId,
    $core.bool? canOrder,
    $core.bool? canBeReserved,
    $core.bool? isActive,
    $core.String? desc,
    $core.String? pic,
    $core.String? metaJson,
    $fixnum.Int64? createdTsMs,
    $fixnum.Int64? updatedTsMs,
    $fixnum.Int64? deletedTsMs,
  }) {
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    if (siteIid != null) {
      $result.siteIid = siteIid;
    }
    if (clientId != null) {
      $result.clientId = clientId;
    }
    if (name != null) {
      $result.name = name;
    }
    if (code != null) {
      $result.code = code;
    }
    if (kind != null) {
      $result.kind = kind;
    }
    if (productId != null) {
      $result.productId = productId;
    }
    if (canOrder != null) {
      $result.canOrder = canOrder;
    }
    if (canBeReserved != null) {
      $result.canBeReserved = canBeReserved;
    }
    if (isActive != null) {
      $result.isActive = isActive;
    }
    if (desc != null) {
      $result.desc = desc;
    }
    if (pic != null) {
      $result.pic = pic;
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
  SiteObject._() : super();
  factory SiteObject.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SiteObject.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SiteObject', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..aInt64(2, _omitFieldNames ? '' : 'siteIid')
    ..aOS(3, _omitFieldNames ? '' : 'clientId')
    ..aOS(4, _omitFieldNames ? '' : 'name')
    ..aOS(5, _omitFieldNames ? '' : 'code')
    ..aOS(6, _omitFieldNames ? '' : 'kind')
    ..aInt64(7, _omitFieldNames ? '' : 'productId')
    ..aOB(8, _omitFieldNames ? '' : 'canOrder')
    ..aOB(9, _omitFieldNames ? '' : 'canBeReserved')
    ..aOB(10, _omitFieldNames ? '' : 'isActive')
    ..aOS(11, _omitFieldNames ? '' : 'desc')
    ..aOS(12, _omitFieldNames ? '' : 'pic')
    ..aOS(13, _omitFieldNames ? '' : 'metaJson')
    ..aInt64(20, _omitFieldNames ? '' : 'createdTsMs')
    ..aInt64(21, _omitFieldNames ? '' : 'updatedTsMs')
    ..aInt64(22, _omitFieldNames ? '' : 'deletedTsMs')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SiteObject clone() => SiteObject()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SiteObject copyWith(void Function(SiteObject) updates) => super.copyWith((message) => updates(message as SiteObject)) as SiteObject;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SiteObject create() => SiteObject._();
  SiteObject createEmptyInstance() => create();
  static $pb.PbList<SiteObject> createRepeated() => $pb.PbList<SiteObject>();
  @$core.pragma('dart2js:noInline')
  static SiteObject getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SiteObject>(create);
  static SiteObject? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get siteIid => $_getI64(1);
  @$pb.TagNumber(2)
  set siteIid($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasSiteIid() => $_has(1);
  @$pb.TagNumber(2)
  void clearSiteIid() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get clientId => $_getSZ(2);
  @$pb.TagNumber(3)
  set clientId($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasClientId() => $_has(2);
  @$pb.TagNumber(3)
  void clearClientId() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get name => $_getSZ(3);
  @$pb.TagNumber(4)
  set name($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasName() => $_has(3);
  @$pb.TagNumber(4)
  void clearName() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get code => $_getSZ(4);
  @$pb.TagNumber(5)
  set code($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasCode() => $_has(4);
  @$pb.TagNumber(5)
  void clearCode() => clearField(5);

  @$pb.TagNumber(6)
  $core.String get kind => $_getSZ(5);
  @$pb.TagNumber(6)
  set kind($core.String v) { $_setString(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasKind() => $_has(5);
  @$pb.TagNumber(6)
  void clearKind() => clearField(6);

  @$pb.TagNumber(7)
  $fixnum.Int64 get productId => $_getI64(6);
  @$pb.TagNumber(7)
  set productId($fixnum.Int64 v) { $_setInt64(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasProductId() => $_has(6);
  @$pb.TagNumber(7)
  void clearProductId() => clearField(7);

  @$pb.TagNumber(8)
  $core.bool get canOrder => $_getBF(7);
  @$pb.TagNumber(8)
  set canOrder($core.bool v) { $_setBool(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasCanOrder() => $_has(7);
  @$pb.TagNumber(8)
  void clearCanOrder() => clearField(8);

  @$pb.TagNumber(9)
  $core.bool get canBeReserved => $_getBF(8);
  @$pb.TagNumber(9)
  set canBeReserved($core.bool v) { $_setBool(8, v); }
  @$pb.TagNumber(9)
  $core.bool hasCanBeReserved() => $_has(8);
  @$pb.TagNumber(9)
  void clearCanBeReserved() => clearField(9);

  @$pb.TagNumber(10)
  $core.bool get isActive => $_getBF(9);
  @$pb.TagNumber(10)
  set isActive($core.bool v) { $_setBool(9, v); }
  @$pb.TagNumber(10)
  $core.bool hasIsActive() => $_has(9);
  @$pb.TagNumber(10)
  void clearIsActive() => clearField(10);

  @$pb.TagNumber(11)
  $core.String get desc => $_getSZ(10);
  @$pb.TagNumber(11)
  set desc($core.String v) { $_setString(10, v); }
  @$pb.TagNumber(11)
  $core.bool hasDesc() => $_has(10);
  @$pb.TagNumber(11)
  void clearDesc() => clearField(11);

  @$pb.TagNumber(12)
  $core.String get pic => $_getSZ(11);
  @$pb.TagNumber(12)
  set pic($core.String v) { $_setString(11, v); }
  @$pb.TagNumber(12)
  $core.bool hasPic() => $_has(11);
  @$pb.TagNumber(12)
  void clearPic() => clearField(12);

  @$pb.TagNumber(13)
  $core.String get metaJson => $_getSZ(12);
  @$pb.TagNumber(13)
  set metaJson($core.String v) { $_setString(12, v); }
  @$pb.TagNumber(13)
  $core.bool hasMetaJson() => $_has(12);
  @$pb.TagNumber(13)
  void clearMetaJson() => clearField(13);

  @$pb.TagNumber(20)
  $fixnum.Int64 get createdTsMs => $_getI64(13);
  @$pb.TagNumber(20)
  set createdTsMs($fixnum.Int64 v) { $_setInt64(13, v); }
  @$pb.TagNumber(20)
  $core.bool hasCreatedTsMs() => $_has(13);
  @$pb.TagNumber(20)
  void clearCreatedTsMs() => clearField(20);

  @$pb.TagNumber(21)
  $fixnum.Int64 get updatedTsMs => $_getI64(14);
  @$pb.TagNumber(21)
  set updatedTsMs($fixnum.Int64 v) { $_setInt64(14, v); }
  @$pb.TagNumber(21)
  $core.bool hasUpdatedTsMs() => $_has(14);
  @$pb.TagNumber(21)
  void clearUpdatedTsMs() => clearField(21);

  @$pb.TagNumber(22)
  $fixnum.Int64 get deletedTsMs => $_getI64(15);
  @$pb.TagNumber(22)
  set deletedTsMs($fixnum.Int64 v) { $_setInt64(15, v); }
  @$pb.TagNumber(22)
  $core.bool hasDeletedTsMs() => $_has(15);
  @$pb.TagNumber(22)
  void clearDeletedTsMs() => clearField(22);
}

class SiteRow extends $pb.GeneratedMessage {
  factory SiteRow({
    $fixnum.Int64? siteIid,
    $core.String? alienId,
    $core.String? name,
    $core.String? pic,
    $core.String? publishedVersionId,
    $fixnum.Int64? updatedTsMs,
    $core.bool? isArchived,
  }) {
    final $result = create();
    if (siteIid != null) {
      $result.siteIid = siteIid;
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
    if (publishedVersionId != null) {
      $result.publishedVersionId = publishedVersionId;
    }
    if (updatedTsMs != null) {
      $result.updatedTsMs = updatedTsMs;
    }
    if (isArchived != null) {
      $result.isArchived = isArchived;
    }
    return $result;
  }
  SiteRow._() : super();
  factory SiteRow.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SiteRow.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SiteRow', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'siteIid')
    ..aOS(2, _omitFieldNames ? '' : 'alienId')
    ..aOS(3, _omitFieldNames ? '' : 'name')
    ..aOS(4, _omitFieldNames ? '' : 'pic')
    ..aOS(5, _omitFieldNames ? '' : 'publishedVersionId')
    ..aInt64(6, _omitFieldNames ? '' : 'updatedTsMs')
    ..aOB(7, _omitFieldNames ? '' : 'isArchived')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SiteRow clone() => SiteRow()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SiteRow copyWith(void Function(SiteRow) updates) => super.copyWith((message) => updates(message as SiteRow)) as SiteRow;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SiteRow create() => SiteRow._();
  SiteRow createEmptyInstance() => create();
  static $pb.PbList<SiteRow> createRepeated() => $pb.PbList<SiteRow>();
  @$core.pragma('dart2js:noInline')
  static SiteRow getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SiteRow>(create);
  static SiteRow? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get siteIid => $_getI64(0);
  @$pb.TagNumber(1)
  set siteIid($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasSiteIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearSiteIid() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get alienId => $_getSZ(1);
  @$pb.TagNumber(2)
  set alienId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasAlienId() => $_has(1);
  @$pb.TagNumber(2)
  void clearAlienId() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get name => $_getSZ(2);
  @$pb.TagNumber(3)
  set name($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasName() => $_has(2);
  @$pb.TagNumber(3)
  void clearName() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get pic => $_getSZ(3);
  @$pb.TagNumber(4)
  set pic($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasPic() => $_has(3);
  @$pb.TagNumber(4)
  void clearPic() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get publishedVersionId => $_getSZ(4);
  @$pb.TagNumber(5)
  set publishedVersionId($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasPublishedVersionId() => $_has(4);
  @$pb.TagNumber(5)
  void clearPublishedVersionId() => clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get updatedTsMs => $_getI64(5);
  @$pb.TagNumber(6)
  set updatedTsMs($fixnum.Int64 v) { $_setInt64(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasUpdatedTsMs() => $_has(5);
  @$pb.TagNumber(6)
  void clearUpdatedTsMs() => clearField(6);

  @$pb.TagNumber(7)
  $core.bool get isArchived => $_getBF(6);
  @$pb.TagNumber(7)
  set isArchived($core.bool v) { $_setBool(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasIsArchived() => $_has(6);
  @$pb.TagNumber(7)
  void clearIsArchived() => clearField(7);
}

class ReqSiteList extends $pb.GeneratedMessage {
  factory ReqSiteList({
    $core.bool? archived,
  }) {
    final $result = create();
    if (archived != null) {
      $result.archived = archived;
    }
    return $result;
  }
  ReqSiteList._() : super();
  factory ReqSiteList.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ReqSiteList.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ReqSiteList', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'archived')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ReqSiteList clone() => ReqSiteList()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ReqSiteList copyWith(void Function(ReqSiteList) updates) => super.copyWith((message) => updates(message as ReqSiteList)) as ReqSiteList;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReqSiteList create() => ReqSiteList._();
  ReqSiteList createEmptyInstance() => create();
  static $pb.PbList<ReqSiteList> createRepeated() => $pb.PbList<ReqSiteList>();
  @$core.pragma('dart2js:noInline')
  static ReqSiteList getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqSiteList>(create);
  static ReqSiteList? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get archived => $_getBF(0);
  @$pb.TagNumber(1)
  set archived($core.bool v) { $_setBool(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasArchived() => $_has(0);
  @$pb.TagNumber(1)
  void clearArchived() => clearField(1);
}

class ResSiteList extends $pb.GeneratedMessage {
  factory ResSiteList({
    $core.Iterable<SiteRow>? sites,
    $core.int? archivedCount,
  }) {
    final $result = create();
    if (sites != null) {
      $result.sites.addAll(sites);
    }
    if (archivedCount != null) {
      $result.archivedCount = archivedCount;
    }
    return $result;
  }
  ResSiteList._() : super();
  factory ResSiteList.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ResSiteList.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ResSiteList', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..pc<SiteRow>(1, _omitFieldNames ? '' : 'sites', $pb.PbFieldType.PM, subBuilder: SiteRow.create)
    ..a<$core.int>(2, _omitFieldNames ? '' : 'archivedCount', $pb.PbFieldType.O3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ResSiteList clone() => ResSiteList()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ResSiteList copyWith(void Function(ResSiteList) updates) => super.copyWith((message) => updates(message as ResSiteList)) as ResSiteList;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResSiteList create() => ResSiteList._();
  ResSiteList createEmptyInstance() => create();
  static $pb.PbList<ResSiteList> createRepeated() => $pb.PbList<ResSiteList>();
  @$core.pragma('dart2js:noInline')
  static ResSiteList getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResSiteList>(create);
  static ResSiteList? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<SiteRow> get sites => $_getList(0);

  @$pb.TagNumber(2)
  $core.int get archivedCount => $_getIZ(1);
  @$pb.TagNumber(2)
  set archivedCount($core.int v) { $_setSignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasArchivedCount() => $_has(1);
  @$pb.TagNumber(2)
  void clearArchivedCount() => clearField(2);
}

class ReqSiteDraftGet extends $pb.GeneratedMessage {
  factory ReqSiteDraftGet({
    $fixnum.Int64? siteIid,
  }) {
    final $result = create();
    if (siteIid != null) {
      $result.siteIid = siteIid;
    }
    return $result;
  }
  ReqSiteDraftGet._() : super();
  factory ReqSiteDraftGet.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ReqSiteDraftGet.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ReqSiteDraftGet', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'siteIid')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ReqSiteDraftGet clone() => ReqSiteDraftGet()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ReqSiteDraftGet copyWith(void Function(ReqSiteDraftGet) updates) => super.copyWith((message) => updates(message as ReqSiteDraftGet)) as ReqSiteDraftGet;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReqSiteDraftGet create() => ReqSiteDraftGet._();
  ReqSiteDraftGet createEmptyInstance() => create();
  static $pb.PbList<ReqSiteDraftGet> createRepeated() => $pb.PbList<ReqSiteDraftGet>();
  @$core.pragma('dart2js:noInline')
  static ReqSiteDraftGet getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqSiteDraftGet>(create);
  static ReqSiteDraftGet? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get siteIid => $_getI64(0);
  @$pb.TagNumber(1)
  set siteIid($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasSiteIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearSiteIid() => clearField(1);
}

class ResSiteDraftGet extends $pb.GeneratedMessage {
  factory ResSiteDraftGet({
    SiteDraft? draft,
    SiteConfig? config,
  }) {
    final $result = create();
    if (draft != null) {
      $result.draft = draft;
    }
    if (config != null) {
      $result.config = config;
    }
    return $result;
  }
  ResSiteDraftGet._() : super();
  factory ResSiteDraftGet.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ResSiteDraftGet.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ResSiteDraftGet', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aOM<SiteDraft>(1, _omitFieldNames ? '' : 'draft', subBuilder: SiteDraft.create)
    ..aOM<SiteConfig>(2, _omitFieldNames ? '' : 'config', subBuilder: SiteConfig.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ResSiteDraftGet clone() => ResSiteDraftGet()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ResSiteDraftGet copyWith(void Function(ResSiteDraftGet) updates) => super.copyWith((message) => updates(message as ResSiteDraftGet)) as ResSiteDraftGet;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResSiteDraftGet create() => ResSiteDraftGet._();
  ResSiteDraftGet createEmptyInstance() => create();
  static $pb.PbList<ResSiteDraftGet> createRepeated() => $pb.PbList<ResSiteDraftGet>();
  @$core.pragma('dart2js:noInline')
  static ResSiteDraftGet getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResSiteDraftGet>(create);
  static ResSiteDraftGet? _defaultInstance;

  @$pb.TagNumber(1)
  SiteDraft get draft => $_getN(0);
  @$pb.TagNumber(1)
  set draft(SiteDraft v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasDraft() => $_has(0);
  @$pb.TagNumber(1)
  void clearDraft() => clearField(1);
  @$pb.TagNumber(1)
  SiteDraft ensureDraft() => $_ensure(0);

  @$pb.TagNumber(2)
  SiteConfig get config => $_getN(1);
  @$pb.TagNumber(2)
  set config(SiteConfig v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasConfig() => $_has(1);
  @$pb.TagNumber(2)
  void clearConfig() => clearField(2);
  @$pb.TagNumber(2)
  SiteConfig ensureConfig() => $_ensure(1);
}

class ReqSiteDraftPut extends $pb.GeneratedMessage {
  factory ReqSiteDraftPut({
    SiteDraft? draft,
    $core.bool? skipPublish,
  }) {
    final $result = create();
    if (draft != null) {
      $result.draft = draft;
    }
    if (skipPublish != null) {
      $result.skipPublish = skipPublish;
    }
    return $result;
  }
  ReqSiteDraftPut._() : super();
  factory ReqSiteDraftPut.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ReqSiteDraftPut.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ReqSiteDraftPut', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aOM<SiteDraft>(1, _omitFieldNames ? '' : 'draft', subBuilder: SiteDraft.create)
    ..aOB(2, _omitFieldNames ? '' : 'skipPublish')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ReqSiteDraftPut clone() => ReqSiteDraftPut()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ReqSiteDraftPut copyWith(void Function(ReqSiteDraftPut) updates) => super.copyWith((message) => updates(message as ReqSiteDraftPut)) as ReqSiteDraftPut;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReqSiteDraftPut create() => ReqSiteDraftPut._();
  ReqSiteDraftPut createEmptyInstance() => create();
  static $pb.PbList<ReqSiteDraftPut> createRepeated() => $pb.PbList<ReqSiteDraftPut>();
  @$core.pragma('dart2js:noInline')
  static ReqSiteDraftPut getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqSiteDraftPut>(create);
  static ReqSiteDraftPut? _defaultInstance;

  @$pb.TagNumber(1)
  SiteDraft get draft => $_getN(0);
  @$pb.TagNumber(1)
  set draft(SiteDraft v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasDraft() => $_has(0);
  @$pb.TagNumber(1)
  void clearDraft() => clearField(1);
  @$pb.TagNumber(1)
  SiteDraft ensureDraft() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.bool get skipPublish => $_getBF(1);
  @$pb.TagNumber(2)
  set skipPublish($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasSkipPublish() => $_has(1);
  @$pb.TagNumber(2)
  void clearSkipPublish() => clearField(2);
}

class ResSiteDraftPut extends $pb.GeneratedMessage {
  factory ResSiteDraftPut({
    $fixnum.Int64? siteIid,
  }) {
    final $result = create();
    if (siteIid != null) {
      $result.siteIid = siteIid;
    }
    return $result;
  }
  ResSiteDraftPut._() : super();
  factory ResSiteDraftPut.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ResSiteDraftPut.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ResSiteDraftPut', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'siteIid')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ResSiteDraftPut clone() => ResSiteDraftPut()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ResSiteDraftPut copyWith(void Function(ResSiteDraftPut) updates) => super.copyWith((message) => updates(message as ResSiteDraftPut)) as ResSiteDraftPut;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResSiteDraftPut create() => ResSiteDraftPut._();
  ResSiteDraftPut createEmptyInstance() => create();
  static $pb.PbList<ResSiteDraftPut> createRepeated() => $pb.PbList<ResSiteDraftPut>();
  @$core.pragma('dart2js:noInline')
  static ResSiteDraftPut getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResSiteDraftPut>(create);
  static ResSiteDraftPut? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get siteIid => $_getI64(0);
  @$pb.TagNumber(1)
  set siteIid($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasSiteIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearSiteIid() => clearField(1);
}

class ReqSitePublish extends $pb.GeneratedMessage {
  factory ReqSitePublish({
    $fixnum.Int64? siteIid,
  }) {
    final $result = create();
    if (siteIid != null) {
      $result.siteIid = siteIid;
    }
    return $result;
  }
  ReqSitePublish._() : super();
  factory ReqSitePublish.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ReqSitePublish.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ReqSitePublish', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'siteIid')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ReqSitePublish clone() => ReqSitePublish()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ReqSitePublish copyWith(void Function(ReqSitePublish) updates) => super.copyWith((message) => updates(message as ReqSitePublish)) as ReqSitePublish;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReqSitePublish create() => ReqSitePublish._();
  ReqSitePublish createEmptyInstance() => create();
  static $pb.PbList<ReqSitePublish> createRepeated() => $pb.PbList<ReqSitePublish>();
  @$core.pragma('dart2js:noInline')
  static ReqSitePublish getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqSitePublish>(create);
  static ReqSitePublish? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get siteIid => $_getI64(0);
  @$pb.TagNumber(1)
  set siteIid($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasSiteIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearSiteIid() => clearField(1);
}

class ResSitePublish extends $pb.GeneratedMessage {
  factory ResSitePublish({
    SitePublish? publish,
  }) {
    final $result = create();
    if (publish != null) {
      $result.publish = publish;
    }
    return $result;
  }
  ResSitePublish._() : super();
  factory ResSitePublish.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ResSitePublish.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ResSitePublish', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aOM<SitePublish>(1, _omitFieldNames ? '' : 'publish', subBuilder: SitePublish.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ResSitePublish clone() => ResSitePublish()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ResSitePublish copyWith(void Function(ResSitePublish) updates) => super.copyWith((message) => updates(message as ResSitePublish)) as ResSitePublish;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResSitePublish create() => ResSitePublish._();
  ResSitePublish createEmptyInstance() => create();
  static $pb.PbList<ResSitePublish> createRepeated() => $pb.PbList<ResSitePublish>();
  @$core.pragma('dart2js:noInline')
  static ResSitePublish getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResSitePublish>(create);
  static ResSitePublish? _defaultInstance;

  @$pb.TagNumber(1)
  SitePublish get publish => $_getN(0);
  @$pb.TagNumber(1)
  set publish(SitePublish v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasPublish() => $_has(0);
  @$pb.TagNumber(1)
  void clearPublish() => clearField(1);
  @$pb.TagNumber(1)
  SitePublish ensurePublish() => $_ensure(0);
}

class ReqSiteProductList extends $pb.GeneratedMessage {
  factory ReqSiteProductList({
    $fixnum.Int64? siteIid,
  }) {
    final $result = create();
    if (siteIid != null) {
      $result.siteIid = siteIid;
    }
    return $result;
  }
  ReqSiteProductList._() : super();
  factory ReqSiteProductList.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ReqSiteProductList.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ReqSiteProductList', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'siteIid')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ReqSiteProductList clone() => ReqSiteProductList()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ReqSiteProductList copyWith(void Function(ReqSiteProductList) updates) => super.copyWith((message) => updates(message as ReqSiteProductList)) as ReqSiteProductList;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReqSiteProductList create() => ReqSiteProductList._();
  ReqSiteProductList createEmptyInstance() => create();
  static $pb.PbList<ReqSiteProductList> createRepeated() => $pb.PbList<ReqSiteProductList>();
  @$core.pragma('dart2js:noInline')
  static ReqSiteProductList getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqSiteProductList>(create);
  static ReqSiteProductList? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get siteIid => $_getI64(0);
  @$pb.TagNumber(1)
  set siteIid($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasSiteIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearSiteIid() => clearField(1);
}

class ResSiteProductList extends $pb.GeneratedMessage {
  factory ResSiteProductList({
    $core.Iterable<SiteProduct>? products,
  }) {
    final $result = create();
    if (products != null) {
      $result.products.addAll(products);
    }
    return $result;
  }
  ResSiteProductList._() : super();
  factory ResSiteProductList.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ResSiteProductList.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ResSiteProductList', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..pc<SiteProduct>(1, _omitFieldNames ? '' : 'products', $pb.PbFieldType.PM, subBuilder: SiteProduct.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ResSiteProductList clone() => ResSiteProductList()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ResSiteProductList copyWith(void Function(ResSiteProductList) updates) => super.copyWith((message) => updates(message as ResSiteProductList)) as ResSiteProductList;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResSiteProductList create() => ResSiteProductList._();
  ResSiteProductList createEmptyInstance() => create();
  static $pb.PbList<ResSiteProductList> createRepeated() => $pb.PbList<ResSiteProductList>();
  @$core.pragma('dart2js:noInline')
  static ResSiteProductList getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResSiteProductList>(create);
  static ResSiteProductList? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<SiteProduct> get products => $_getList(0);
}

class ReqSiteProductPut extends $pb.GeneratedMessage {
  factory ReqSiteProductPut({
    $fixnum.Int64? siteIid,
    SiteProduct? product,
  }) {
    final $result = create();
    if (siteIid != null) {
      $result.siteIid = siteIid;
    }
    if (product != null) {
      $result.product = product;
    }
    return $result;
  }
  ReqSiteProductPut._() : super();
  factory ReqSiteProductPut.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ReqSiteProductPut.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ReqSiteProductPut', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'siteIid')
    ..aOM<SiteProduct>(2, _omitFieldNames ? '' : 'product', subBuilder: SiteProduct.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ReqSiteProductPut clone() => ReqSiteProductPut()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ReqSiteProductPut copyWith(void Function(ReqSiteProductPut) updates) => super.copyWith((message) => updates(message as ReqSiteProductPut)) as ReqSiteProductPut;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReqSiteProductPut create() => ReqSiteProductPut._();
  ReqSiteProductPut createEmptyInstance() => create();
  static $pb.PbList<ReqSiteProductPut> createRepeated() => $pb.PbList<ReqSiteProductPut>();
  @$core.pragma('dart2js:noInline')
  static ReqSiteProductPut getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqSiteProductPut>(create);
  static ReqSiteProductPut? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get siteIid => $_getI64(0);
  @$pb.TagNumber(1)
  set siteIid($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasSiteIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearSiteIid() => clearField(1);

  @$pb.TagNumber(2)
  SiteProduct get product => $_getN(1);
  @$pb.TagNumber(2)
  set product(SiteProduct v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasProduct() => $_has(1);
  @$pb.TagNumber(2)
  void clearProduct() => clearField(2);
  @$pb.TagNumber(2)
  SiteProduct ensureProduct() => $_ensure(1);
}

class ResSiteProductPut extends $pb.GeneratedMessage {
  factory ResSiteProductPut({
    $fixnum.Int64? productId,
  }) {
    final $result = create();
    if (productId != null) {
      $result.productId = productId;
    }
    return $result;
  }
  ResSiteProductPut._() : super();
  factory ResSiteProductPut.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ResSiteProductPut.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ResSiteProductPut', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'productId')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ResSiteProductPut clone() => ResSiteProductPut()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ResSiteProductPut copyWith(void Function(ResSiteProductPut) updates) => super.copyWith((message) => updates(message as ResSiteProductPut)) as ResSiteProductPut;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResSiteProductPut create() => ResSiteProductPut._();
  ResSiteProductPut createEmptyInstance() => create();
  static $pb.PbList<ResSiteProductPut> createRepeated() => $pb.PbList<ResSiteProductPut>();
  @$core.pragma('dart2js:noInline')
  static ResSiteProductPut getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResSiteProductPut>(create);
  static ResSiteProductPut? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get productId => $_getI64(0);
  @$pb.TagNumber(1)
  set productId($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasProductId() => $_has(0);
  @$pb.TagNumber(1)
  void clearProductId() => clearField(1);
}

class ReqSiteContactList extends $pb.GeneratedMessage {
  factory ReqSiteContactList({
    $fixnum.Int64? siteIid,
    $core.String? q,
  }) {
    final $result = create();
    if (siteIid != null) {
      $result.siteIid = siteIid;
    }
    if (q != null) {
      $result.q = q;
    }
    return $result;
  }
  ReqSiteContactList._() : super();
  factory ReqSiteContactList.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ReqSiteContactList.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ReqSiteContactList', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'siteIid')
    ..aOS(2, _omitFieldNames ? '' : 'q')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ReqSiteContactList clone() => ReqSiteContactList()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ReqSiteContactList copyWith(void Function(ReqSiteContactList) updates) => super.copyWith((message) => updates(message as ReqSiteContactList)) as ReqSiteContactList;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReqSiteContactList create() => ReqSiteContactList._();
  ReqSiteContactList createEmptyInstance() => create();
  static $pb.PbList<ReqSiteContactList> createRepeated() => $pb.PbList<ReqSiteContactList>();
  @$core.pragma('dart2js:noInline')
  static ReqSiteContactList getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqSiteContactList>(create);
  static ReqSiteContactList? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get siteIid => $_getI64(0);
  @$pb.TagNumber(1)
  set siteIid($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasSiteIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearSiteIid() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get q => $_getSZ(1);
  @$pb.TagNumber(2)
  set q($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasQ() => $_has(1);
  @$pb.TagNumber(2)
  void clearQ() => clearField(2);
}

class ResSiteContactList extends $pb.GeneratedMessage {
  factory ResSiteContactList({
    $core.Iterable<SiteContact>? contacts,
  }) {
    final $result = create();
    if (contacts != null) {
      $result.contacts.addAll(contacts);
    }
    return $result;
  }
  ResSiteContactList._() : super();
  factory ResSiteContactList.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ResSiteContactList.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ResSiteContactList', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..pc<SiteContact>(1, _omitFieldNames ? '' : 'contacts', $pb.PbFieldType.PM, subBuilder: SiteContact.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ResSiteContactList clone() => ResSiteContactList()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ResSiteContactList copyWith(void Function(ResSiteContactList) updates) => super.copyWith((message) => updates(message as ResSiteContactList)) as ResSiteContactList;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResSiteContactList create() => ResSiteContactList._();
  ResSiteContactList createEmptyInstance() => create();
  static $pb.PbList<ResSiteContactList> createRepeated() => $pb.PbList<ResSiteContactList>();
  @$core.pragma('dart2js:noInline')
  static ResSiteContactList getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResSiteContactList>(create);
  static ResSiteContactList? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<SiteContact> get contacts => $_getList(0);
}

class ReqSiteContactPut extends $pb.GeneratedMessage {
  factory ReqSiteContactPut({
    $fixnum.Int64? siteIid,
    SiteContact? contact,
  }) {
    final $result = create();
    if (siteIid != null) {
      $result.siteIid = siteIid;
    }
    if (contact != null) {
      $result.contact = contact;
    }
    return $result;
  }
  ReqSiteContactPut._() : super();
  factory ReqSiteContactPut.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ReqSiteContactPut.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ReqSiteContactPut', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'siteIid')
    ..aOM<SiteContact>(2, _omitFieldNames ? '' : 'contact', subBuilder: SiteContact.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ReqSiteContactPut clone() => ReqSiteContactPut()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ReqSiteContactPut copyWith(void Function(ReqSiteContactPut) updates) => super.copyWith((message) => updates(message as ReqSiteContactPut)) as ReqSiteContactPut;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReqSiteContactPut create() => ReqSiteContactPut._();
  ReqSiteContactPut createEmptyInstance() => create();
  static $pb.PbList<ReqSiteContactPut> createRepeated() => $pb.PbList<ReqSiteContactPut>();
  @$core.pragma('dart2js:noInline')
  static ReqSiteContactPut getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqSiteContactPut>(create);
  static ReqSiteContactPut? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get siteIid => $_getI64(0);
  @$pb.TagNumber(1)
  set siteIid($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasSiteIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearSiteIid() => clearField(1);

  @$pb.TagNumber(2)
  SiteContact get contact => $_getN(1);
  @$pb.TagNumber(2)
  set contact(SiteContact v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasContact() => $_has(1);
  @$pb.TagNumber(2)
  void clearContact() => clearField(2);
  @$pb.TagNumber(2)
  SiteContact ensureContact() => $_ensure(1);
}

class ResSiteContactPut extends $pb.GeneratedMessage {
  factory ResSiteContactPut({
    $fixnum.Int64? contactId,
  }) {
    final $result = create();
    if (contactId != null) {
      $result.contactId = contactId;
    }
    return $result;
  }
  ResSiteContactPut._() : super();
  factory ResSiteContactPut.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ResSiteContactPut.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ResSiteContactPut', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'contactId')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ResSiteContactPut clone() => ResSiteContactPut()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ResSiteContactPut copyWith(void Function(ResSiteContactPut) updates) => super.copyWith((message) => updates(message as ResSiteContactPut)) as ResSiteContactPut;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResSiteContactPut create() => ResSiteContactPut._();
  ResSiteContactPut createEmptyInstance() => create();
  static $pb.PbList<ResSiteContactPut> createRepeated() => $pb.PbList<ResSiteContactPut>();
  @$core.pragma('dart2js:noInline')
  static ResSiteContactPut getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResSiteContactPut>(create);
  static ResSiteContactPut? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get contactId => $_getI64(0);
  @$pb.TagNumber(1)
  set contactId($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasContactId() => $_has(0);
  @$pb.TagNumber(1)
  void clearContactId() => clearField(1);
}

class ReqSiteObjectList extends $pb.GeneratedMessage {
  factory ReqSiteObjectList({
    $fixnum.Int64? siteIid,
  }) {
    final $result = create();
    if (siteIid != null) {
      $result.siteIid = siteIid;
    }
    return $result;
  }
  ReqSiteObjectList._() : super();
  factory ReqSiteObjectList.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ReqSiteObjectList.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ReqSiteObjectList', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'siteIid')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ReqSiteObjectList clone() => ReqSiteObjectList()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ReqSiteObjectList copyWith(void Function(ReqSiteObjectList) updates) => super.copyWith((message) => updates(message as ReqSiteObjectList)) as ReqSiteObjectList;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReqSiteObjectList create() => ReqSiteObjectList._();
  ReqSiteObjectList createEmptyInstance() => create();
  static $pb.PbList<ReqSiteObjectList> createRepeated() => $pb.PbList<ReqSiteObjectList>();
  @$core.pragma('dart2js:noInline')
  static ReqSiteObjectList getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqSiteObjectList>(create);
  static ReqSiteObjectList? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get siteIid => $_getI64(0);
  @$pb.TagNumber(1)
  set siteIid($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasSiteIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearSiteIid() => clearField(1);
}

class ResSiteObjectList extends $pb.GeneratedMessage {
  factory ResSiteObjectList({
    $core.Iterable<SiteObject>? objs,
  }) {
    final $result = create();
    if (objs != null) {
      $result.objs.addAll(objs);
    }
    return $result;
  }
  ResSiteObjectList._() : super();
  factory ResSiteObjectList.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ResSiteObjectList.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ResSiteObjectList', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..pc<SiteObject>(1, _omitFieldNames ? '' : 'objs', $pb.PbFieldType.PM, subBuilder: SiteObject.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ResSiteObjectList clone() => ResSiteObjectList()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ResSiteObjectList copyWith(void Function(ResSiteObjectList) updates) => super.copyWith((message) => updates(message as ResSiteObjectList)) as ResSiteObjectList;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResSiteObjectList create() => ResSiteObjectList._();
  ResSiteObjectList createEmptyInstance() => create();
  static $pb.PbList<ResSiteObjectList> createRepeated() => $pb.PbList<ResSiteObjectList>();
  @$core.pragma('dart2js:noInline')
  static ResSiteObjectList getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResSiteObjectList>(create);
  static ResSiteObjectList? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<SiteObject> get objs => $_getList(0);
}

class ReqSiteObjectPut extends $pb.GeneratedMessage {
  factory ReqSiteObjectPut({
    $fixnum.Int64? siteIid,
    SiteObject? obj,
  }) {
    final $result = create();
    if (siteIid != null) {
      $result.siteIid = siteIid;
    }
    if (obj != null) {
      $result.obj = obj;
    }
    return $result;
  }
  ReqSiteObjectPut._() : super();
  factory ReqSiteObjectPut.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ReqSiteObjectPut.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ReqSiteObjectPut', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'siteIid')
    ..aOM<SiteObject>(2, _omitFieldNames ? '' : 'obj', subBuilder: SiteObject.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ReqSiteObjectPut clone() => ReqSiteObjectPut()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ReqSiteObjectPut copyWith(void Function(ReqSiteObjectPut) updates) => super.copyWith((message) => updates(message as ReqSiteObjectPut)) as ReqSiteObjectPut;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReqSiteObjectPut create() => ReqSiteObjectPut._();
  ReqSiteObjectPut createEmptyInstance() => create();
  static $pb.PbList<ReqSiteObjectPut> createRepeated() => $pb.PbList<ReqSiteObjectPut>();
  @$core.pragma('dart2js:noInline')
  static ReqSiteObjectPut getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqSiteObjectPut>(create);
  static ReqSiteObjectPut? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get siteIid => $_getI64(0);
  @$pb.TagNumber(1)
  set siteIid($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasSiteIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearSiteIid() => clearField(1);

  @$pb.TagNumber(2)
  SiteObject get obj => $_getN(1);
  @$pb.TagNumber(2)
  set obj(SiteObject v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasObj() => $_has(1);
  @$pb.TagNumber(2)
  void clearObj() => clearField(2);
  @$pb.TagNumber(2)
  SiteObject ensureObj() => $_ensure(1);
}

class ResSiteObjectPut extends $pb.GeneratedMessage {
  factory ResSiteObjectPut({
    $fixnum.Int64? id,
  }) {
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    return $result;
  }
  ResSiteObjectPut._() : super();
  factory ResSiteObjectPut.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ResSiteObjectPut.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ResSiteObjectPut', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ResSiteObjectPut clone() => ResSiteObjectPut()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ResSiteObjectPut copyWith(void Function(ResSiteObjectPut) updates) => super.copyWith((message) => updates(message as ResSiteObjectPut)) as ResSiteObjectPut;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResSiteObjectPut create() => ResSiteObjectPut._();
  ResSiteObjectPut createEmptyInstance() => create();
  static $pb.PbList<ResSiteObjectPut> createRepeated() => $pb.PbList<ResSiteObjectPut>();
  @$core.pragma('dart2js:noInline')
  static ResSiteObjectPut getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResSiteObjectPut>(create);
  static ResSiteObjectPut? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
