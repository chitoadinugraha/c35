// This is a generated file - do not edit.
//
// Generated from c35/site.proto.

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

class SiteBlock extends $pb.GeneratedMessage {
  factory SiteBlock({
    $core.String? id,
    $core.String? type,
    $core.String? propsJson,
  }) {
    final result = SiteBlock._();
    if (id != null) result.id = id;
    if (type != null) result.type = type;
    if (propsJson != null) result.propsJson = propsJson;
    return result;
  }

  SiteBlock._();

  factory SiteBlock.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SiteBlock()..mergeFromBuffer(data, registry);
  factory SiteBlock.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SiteBlock()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SiteBlock',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: SiteBlock.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'type')
    ..aOS(3, _omitFieldNames ? '' : 'propsJson')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SiteBlock clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SiteBlock copyWith(void Function(SiteBlock) updates) =>
      super.copyWith((message) => updates(message as SiteBlock)) as SiteBlock;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SiteBlock() / SiteBlock.new instead')
  static SiteBlock create() => SiteBlock._();
  static $pb.GeneratedMessage $_createMessage() => SiteBlock._();
  @$core.override
  SiteBlock createEmptyInstance() => SiteBlock._();
  @$core.pragma('dart2js:noInline')
  static SiteBlock getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SiteBlock>(SiteBlock.$_createMessage);
  static SiteBlock? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get type => $_getSZ(1);
  @$pb.TagNumber(2)
  set type($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasType() => $_has(1);
  @$pb.TagNumber(2)
  void clearType() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get propsJson => $_getSZ(2);
  @$pb.TagNumber(3)
  set propsJson($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPropsJson() => $_has(2);
  @$pb.TagNumber(3)
  void clearPropsJson() => $_clearField(3);
}

class SitePage extends $pb.GeneratedMessage {
  factory SitePage({
    $core.String? path,
    $core.String? title,
    $core.Iterable<SiteBlock>? blocks,
  }) {
    final result = SitePage._();
    if (path != null) result.path = path;
    if (title != null) result.title = title;
    if (blocks != null) result.blocks.addAll(blocks);
    return result;
  }

  SitePage._();

  factory SitePage.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SitePage()..mergeFromBuffer(data, registry);
  factory SitePage.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SitePage()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SitePage',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: SitePage.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'path')
    ..aOS(2, _omitFieldNames ? '' : 'title')
    ..pPM<SiteBlock>(3, _omitFieldNames ? '' : 'blocks',
        subBuilder: SiteBlock.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SitePage clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SitePage copyWith(void Function(SitePage) updates) =>
      super.copyWith((message) => updates(message as SitePage)) as SitePage;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SitePage() / SitePage.new instead')
  static SitePage create() => SitePage._();
  static $pb.GeneratedMessage $_createMessage() => SitePage._();
  @$core.override
  SitePage createEmptyInstance() => SitePage._();
  @$core.pragma('dart2js:noInline')
  static SitePage getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SitePage>(SitePage.$_createMessage);
  static SitePage? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get path => $_getSZ(0);
  @$pb.TagNumber(1)
  set path($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearPath() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get title => $_getSZ(1);
  @$pb.TagNumber(2)
  set title($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTitle() => $_has(1);
  @$pb.TagNumber(2)
  void clearTitle() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<SiteBlock> get blocks => $_getList(2);
}

class SiteDoc extends $pb.GeneratedMessage {
  factory SiteDoc({
    $core.Iterable<SitePage>? pages,
    $core.String? themeJson,
    $core.String? metaJson,
  }) {
    final result = SiteDoc._();
    if (pages != null) result.pages.addAll(pages);
    if (themeJson != null) result.themeJson = themeJson;
    if (metaJson != null) result.metaJson = metaJson;
    return result;
  }

  SiteDoc._();

  factory SiteDoc.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SiteDoc()..mergeFromBuffer(data, registry);
  factory SiteDoc.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SiteDoc()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SiteDoc',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: SiteDoc.$_createMessage)
    ..pPM<SitePage>(1, _omitFieldNames ? '' : 'pages',
        subBuilder: SitePage.$_createMessage)
    ..aOS(2, _omitFieldNames ? '' : 'themeJson')
    ..aOS(3, _omitFieldNames ? '' : 'metaJson')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SiteDoc clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SiteDoc copyWith(void Function(SiteDoc) updates) =>
      super.copyWith((message) => updates(message as SiteDoc)) as SiteDoc;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SiteDoc() / SiteDoc.new instead')
  static SiteDoc create() => SiteDoc._();
  static $pb.GeneratedMessage $_createMessage() => SiteDoc._();
  @$core.override
  SiteDoc createEmptyInstance() => SiteDoc._();
  @$core.pragma('dart2js:noInline')
  static SiteDoc getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SiteDoc>(SiteDoc.$_createMessage);
  static SiteDoc? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<SitePage> get pages => $_getList(0);

  @$pb.TagNumber(2)
  $core.String get themeJson => $_getSZ(1);
  @$pb.TagNumber(2)
  set themeJson($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasThemeJson() => $_has(1);
  @$pb.TagNumber(2)
  void clearThemeJson() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get metaJson => $_getSZ(2);
  @$pb.TagNumber(3)
  set metaJson($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMetaJson() => $_has(2);
  @$pb.TagNumber(3)
  void clearMetaJson() => $_clearField(3);
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
    final result = SiteConfig._();
    if (siteIid != null) result.siteIid = siteIid;
    if (ownerIid != null) result.ownerIid = ownerIid;
    if (publishedVersionId != null)
      result.publishedVersionId = publishedVersionId;
    if (inventoryCostingMethod != null)
      result.inventoryCostingMethod = inventoryCostingMethod;
    if (tz != null) result.tz = tz;
    if (payrollPolicyJson != null) result.payrollPolicyJson = payrollPolicyJson;
    if (presencePolicyJson != null)
      result.presencePolicyJson = presencePolicyJson;
    if (capabilitiesJson != null) result.capabilitiesJson = capabilitiesJson;
    if (alienIdChangedTsMs != null)
      result.alienIdChangedTsMs = alienIdChangedTsMs;
    if (createdTsMs != null) result.createdTsMs = createdTsMs;
    if (updatedTsMs != null) result.updatedTsMs = updatedTsMs;
    if (deletedTsMs != null) result.deletedTsMs = deletedTsMs;
    return result;
  }

  SiteConfig._();

  factory SiteConfig.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SiteConfig()..mergeFromBuffer(data, registry);
  factory SiteConfig.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SiteConfig()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SiteConfig',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: SiteConfig.$_createMessage)
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
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SiteConfig clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SiteConfig copyWith(void Function(SiteConfig) updates) =>
      super.copyWith((message) => updates(message as SiteConfig)) as SiteConfig;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SiteConfig() / SiteConfig.new instead')
  static SiteConfig create() => SiteConfig._();
  static $pb.GeneratedMessage $_createMessage() => SiteConfig._();
  @$core.override
  SiteConfig createEmptyInstance() => SiteConfig._();
  @$core.pragma('dart2js:noInline')
  static SiteConfig getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SiteConfig>(SiteConfig.$_createMessage);
  static SiteConfig? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get siteIid => $_getI64(0);
  @$pb.TagNumber(1)
  set siteIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSiteIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearSiteIid() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get ownerIid => $_getI64(1);
  @$pb.TagNumber(2)
  set ownerIid($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOwnerIid() => $_has(1);
  @$pb.TagNumber(2)
  void clearOwnerIid() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get publishedVersionId => $_getSZ(2);
  @$pb.TagNumber(3)
  set publishedVersionId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPublishedVersionId() => $_has(2);
  @$pb.TagNumber(3)
  void clearPublishedVersionId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get inventoryCostingMethod => $_getSZ(3);
  @$pb.TagNumber(4)
  set inventoryCostingMethod($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasInventoryCostingMethod() => $_has(3);
  @$pb.TagNumber(4)
  void clearInventoryCostingMethod() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get tz => $_getSZ(4);
  @$pb.TagNumber(5)
  set tz($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasTz() => $_has(4);
  @$pb.TagNumber(5)
  void clearTz() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get payrollPolicyJson => $_getSZ(5);
  @$pb.TagNumber(6)
  set payrollPolicyJson($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasPayrollPolicyJson() => $_has(5);
  @$pb.TagNumber(6)
  void clearPayrollPolicyJson() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get presencePolicyJson => $_getSZ(6);
  @$pb.TagNumber(7)
  set presencePolicyJson($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasPresencePolicyJson() => $_has(6);
  @$pb.TagNumber(7)
  void clearPresencePolicyJson() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get capabilitiesJson => $_getSZ(7);
  @$pb.TagNumber(8)
  set capabilitiesJson($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasCapabilitiesJson() => $_has(7);
  @$pb.TagNumber(8)
  void clearCapabilitiesJson() => $_clearField(8);

  @$pb.TagNumber(9)
  $fixnum.Int64 get alienIdChangedTsMs => $_getI64(8);
  @$pb.TagNumber(9)
  set alienIdChangedTsMs($fixnum.Int64 value) => $_setInt64(8, value);
  @$pb.TagNumber(9)
  $core.bool hasAlienIdChangedTsMs() => $_has(8);
  @$pb.TagNumber(9)
  void clearAlienIdChangedTsMs() => $_clearField(9);

  @$pb.TagNumber(20)
  $fixnum.Int64 get createdTsMs => $_getI64(9);
  @$pb.TagNumber(20)
  set createdTsMs($fixnum.Int64 value) => $_setInt64(9, value);
  @$pb.TagNumber(20)
  $core.bool hasCreatedTsMs() => $_has(9);
  @$pb.TagNumber(20)
  void clearCreatedTsMs() => $_clearField(20);

  @$pb.TagNumber(21)
  $fixnum.Int64 get updatedTsMs => $_getI64(10);
  @$pb.TagNumber(21)
  set updatedTsMs($fixnum.Int64 value) => $_setInt64(10, value);
  @$pb.TagNumber(21)
  $core.bool hasUpdatedTsMs() => $_has(10);
  @$pb.TagNumber(21)
  void clearUpdatedTsMs() => $_clearField(21);

  @$pb.TagNumber(22)
  $fixnum.Int64 get deletedTsMs => $_getI64(11);
  @$pb.TagNumber(22)
  set deletedTsMs($fixnum.Int64 value) => $_setInt64(11, value);
  @$pb.TagNumber(22)
  $core.bool hasDeletedTsMs() => $_has(11);
  @$pb.TagNumber(22)
  void clearDeletedTsMs() => $_clearField(22);
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
    final result = SiteDomain._();
    if (id != null) result.id = id;
    if (siteIid != null) result.siteIid = siteIid;
    if (hostname != null) result.hostname = hostname;
    if (isPrimary != null) result.isPrimary = isPrimary;
    if (tlsStatus != null) result.tlsStatus = tlsStatus;
    if (verifiedTsMs != null) result.verifiedTsMs = verifiedTsMs;
    if (createdTsMs != null) result.createdTsMs = createdTsMs;
    if (updatedTsMs != null) result.updatedTsMs = updatedTsMs;
    if (deletedTsMs != null) result.deletedTsMs = deletedTsMs;
    return result;
  }

  SiteDomain._();

  factory SiteDomain.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SiteDomain()..mergeFromBuffer(data, registry);
  factory SiteDomain.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SiteDomain()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SiteDomain',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: SiteDomain.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..aInt64(2, _omitFieldNames ? '' : 'siteIid')
    ..aOS(3, _omitFieldNames ? '' : 'hostname')
    ..aOB(4, _omitFieldNames ? '' : 'isPrimary')
    ..aOS(5, _omitFieldNames ? '' : 'tlsStatus')
    ..aInt64(6, _omitFieldNames ? '' : 'verifiedTsMs')
    ..aInt64(20, _omitFieldNames ? '' : 'createdTsMs')
    ..aInt64(21, _omitFieldNames ? '' : 'updatedTsMs')
    ..aInt64(22, _omitFieldNames ? '' : 'deletedTsMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SiteDomain clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SiteDomain copyWith(void Function(SiteDomain) updates) =>
      super.copyWith((message) => updates(message as SiteDomain)) as SiteDomain;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SiteDomain() / SiteDomain.new instead')
  static SiteDomain create() => SiteDomain._();
  static $pb.GeneratedMessage $_createMessage() => SiteDomain._();
  @$core.override
  SiteDomain createEmptyInstance() => SiteDomain._();
  @$core.pragma('dart2js:noInline')
  static SiteDomain getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SiteDomain>(SiteDomain.$_createMessage);
  static SiteDomain? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get siteIid => $_getI64(1);
  @$pb.TagNumber(2)
  set siteIid($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSiteIid() => $_has(1);
  @$pb.TagNumber(2)
  void clearSiteIid() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get hostname => $_getSZ(2);
  @$pb.TagNumber(3)
  set hostname($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasHostname() => $_has(2);
  @$pb.TagNumber(3)
  void clearHostname() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get isPrimary => $_getBF(3);
  @$pb.TagNumber(4)
  set isPrimary($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasIsPrimary() => $_has(3);
  @$pb.TagNumber(4)
  void clearIsPrimary() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get tlsStatus => $_getSZ(4);
  @$pb.TagNumber(5)
  set tlsStatus($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasTlsStatus() => $_has(4);
  @$pb.TagNumber(5)
  void clearTlsStatus() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get verifiedTsMs => $_getI64(5);
  @$pb.TagNumber(6)
  set verifiedTsMs($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasVerifiedTsMs() => $_has(5);
  @$pb.TagNumber(6)
  void clearVerifiedTsMs() => $_clearField(6);

  @$pb.TagNumber(20)
  $fixnum.Int64 get createdTsMs => $_getI64(6);
  @$pb.TagNumber(20)
  set createdTsMs($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(20)
  $core.bool hasCreatedTsMs() => $_has(6);
  @$pb.TagNumber(20)
  void clearCreatedTsMs() => $_clearField(20);

  @$pb.TagNumber(21)
  $fixnum.Int64 get updatedTsMs => $_getI64(7);
  @$pb.TagNumber(21)
  set updatedTsMs($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(21)
  $core.bool hasUpdatedTsMs() => $_has(7);
  @$pb.TagNumber(21)
  void clearUpdatedTsMs() => $_clearField(21);

  @$pb.TagNumber(22)
  $fixnum.Int64 get deletedTsMs => $_getI64(8);
  @$pb.TagNumber(22)
  set deletedTsMs($fixnum.Int64 value) => $_setInt64(8, value);
  @$pb.TagNumber(22)
  $core.bool hasDeletedTsMs() => $_has(8);
  @$pb.TagNumber(22)
  void clearDeletedTsMs() => $_clearField(22);
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
    final result = SiteDraft._();
    if (siteIid != null) result.siteIid = siteIid;
    if (ownerIid != null) result.ownerIid = ownerIid;
    if (doc != null) result.doc = doc;
    if (createdTsMs != null) result.createdTsMs = createdTsMs;
    if (updatedTsMs != null) result.updatedTsMs = updatedTsMs;
    if (deletedTsMs != null) result.deletedTsMs = deletedTsMs;
    return result;
  }

  SiteDraft._();

  factory SiteDraft.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SiteDraft()..mergeFromBuffer(data, registry);
  factory SiteDraft.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SiteDraft()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SiteDraft',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: SiteDraft.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'siteIid')
    ..aInt64(2, _omitFieldNames ? '' : 'ownerIid')
    ..aOM<SiteDoc>(3, _omitFieldNames ? '' : 'doc',
        subBuilder: SiteDoc.$_createMessage)
    ..aInt64(20, _omitFieldNames ? '' : 'createdTsMs')
    ..aInt64(21, _omitFieldNames ? '' : 'updatedTsMs')
    ..aInt64(22, _omitFieldNames ? '' : 'deletedTsMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SiteDraft clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SiteDraft copyWith(void Function(SiteDraft) updates) =>
      super.copyWith((message) => updates(message as SiteDraft)) as SiteDraft;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SiteDraft() / SiteDraft.new instead')
  static SiteDraft create() => SiteDraft._();
  static $pb.GeneratedMessage $_createMessage() => SiteDraft._();
  @$core.override
  SiteDraft createEmptyInstance() => SiteDraft._();
  @$core.pragma('dart2js:noInline')
  static SiteDraft getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SiteDraft>(SiteDraft.$_createMessage);
  static SiteDraft? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get siteIid => $_getI64(0);
  @$pb.TagNumber(1)
  set siteIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSiteIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearSiteIid() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get ownerIid => $_getI64(1);
  @$pb.TagNumber(2)
  set ownerIid($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOwnerIid() => $_has(1);
  @$pb.TagNumber(2)
  void clearOwnerIid() => $_clearField(2);

  @$pb.TagNumber(3)
  SiteDoc get doc => $_getN(2);
  @$pb.TagNumber(3)
  set doc(SiteDoc value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasDoc() => $_has(2);
  @$pb.TagNumber(3)
  void clearDoc() => $_clearField(3);
  @$pb.TagNumber(3)
  SiteDoc ensureDoc() => $_ensure(2);

  @$pb.TagNumber(20)
  $fixnum.Int64 get createdTsMs => $_getI64(3);
  @$pb.TagNumber(20)
  set createdTsMs($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(20)
  $core.bool hasCreatedTsMs() => $_has(3);
  @$pb.TagNumber(20)
  void clearCreatedTsMs() => $_clearField(20);

  @$pb.TagNumber(21)
  $fixnum.Int64 get updatedTsMs => $_getI64(4);
  @$pb.TagNumber(21)
  set updatedTsMs($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(21)
  $core.bool hasUpdatedTsMs() => $_has(4);
  @$pb.TagNumber(21)
  void clearUpdatedTsMs() => $_clearField(21);

  @$pb.TagNumber(22)
  $fixnum.Int64 get deletedTsMs => $_getI64(5);
  @$pb.TagNumber(22)
  set deletedTsMs($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(22)
  $core.bool hasDeletedTsMs() => $_has(5);
  @$pb.TagNumber(22)
  void clearDeletedTsMs() => $_clearField(22);
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
    final result = SitePublish._();
    if (siteIid != null) result.siteIid = siteIid;
    if (versionId != null) result.versionId = versionId;
    if (doc != null) result.doc = doc;
    if (renderHash != null) result.renderHash = renderHash;
    if (publishedTsMs != null) result.publishedTsMs = publishedTsMs;
    if (isActive != null) result.isActive = isActive;
    if (createdTsMs != null) result.createdTsMs = createdTsMs;
    if (updatedTsMs != null) result.updatedTsMs = updatedTsMs;
    if (deletedTsMs != null) result.deletedTsMs = deletedTsMs;
    return result;
  }

  SitePublish._();

  factory SitePublish.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SitePublish()..mergeFromBuffer(data, registry);
  factory SitePublish.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SitePublish()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SitePublish',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: SitePublish.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'siteIid')
    ..aOS(2, _omitFieldNames ? '' : 'versionId')
    ..aOM<SiteDoc>(3, _omitFieldNames ? '' : 'doc',
        subBuilder: SiteDoc.$_createMessage)
    ..aOS(4, _omitFieldNames ? '' : 'renderHash')
    ..aInt64(5, _omitFieldNames ? '' : 'publishedTsMs')
    ..aOB(6, _omitFieldNames ? '' : 'isActive')
    ..aInt64(20, _omitFieldNames ? '' : 'createdTsMs')
    ..aInt64(21, _omitFieldNames ? '' : 'updatedTsMs')
    ..aInt64(22, _omitFieldNames ? '' : 'deletedTsMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SitePublish clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SitePublish copyWith(void Function(SitePublish) updates) =>
      super.copyWith((message) => updates(message as SitePublish))
          as SitePublish;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SitePublish() / SitePublish.new instead')
  static SitePublish create() => SitePublish._();
  static $pb.GeneratedMessage $_createMessage() => SitePublish._();
  @$core.override
  SitePublish createEmptyInstance() => SitePublish._();
  @$core.pragma('dart2js:noInline')
  static SitePublish getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SitePublish>(
          SitePublish.$_createMessage);
  static SitePublish? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get siteIid => $_getI64(0);
  @$pb.TagNumber(1)
  set siteIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSiteIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearSiteIid() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get versionId => $_getSZ(1);
  @$pb.TagNumber(2)
  set versionId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasVersionId() => $_has(1);
  @$pb.TagNumber(2)
  void clearVersionId() => $_clearField(2);

  @$pb.TagNumber(3)
  SiteDoc get doc => $_getN(2);
  @$pb.TagNumber(3)
  set doc(SiteDoc value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasDoc() => $_has(2);
  @$pb.TagNumber(3)
  void clearDoc() => $_clearField(3);
  @$pb.TagNumber(3)
  SiteDoc ensureDoc() => $_ensure(2);

  @$pb.TagNumber(4)
  $core.String get renderHash => $_getSZ(3);
  @$pb.TagNumber(4)
  set renderHash($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasRenderHash() => $_has(3);
  @$pb.TagNumber(4)
  void clearRenderHash() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get publishedTsMs => $_getI64(4);
  @$pb.TagNumber(5)
  set publishedTsMs($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasPublishedTsMs() => $_has(4);
  @$pb.TagNumber(5)
  void clearPublishedTsMs() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get isActive => $_getBF(5);
  @$pb.TagNumber(6)
  set isActive($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasIsActive() => $_has(5);
  @$pb.TagNumber(6)
  void clearIsActive() => $_clearField(6);

  @$pb.TagNumber(20)
  $fixnum.Int64 get createdTsMs => $_getI64(6);
  @$pb.TagNumber(20)
  set createdTsMs($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(20)
  $core.bool hasCreatedTsMs() => $_has(6);
  @$pb.TagNumber(20)
  void clearCreatedTsMs() => $_clearField(20);

  @$pb.TagNumber(21)
  $fixnum.Int64 get updatedTsMs => $_getI64(7);
  @$pb.TagNumber(21)
  set updatedTsMs($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(21)
  $core.bool hasUpdatedTsMs() => $_has(7);
  @$pb.TagNumber(21)
  void clearUpdatedTsMs() => $_clearField(21);

  @$pb.TagNumber(22)
  $fixnum.Int64 get deletedTsMs => $_getI64(8);
  @$pb.TagNumber(22)
  set deletedTsMs($fixnum.Int64 value) => $_setInt64(8, value);
  @$pb.TagNumber(22)
  $core.bool hasDeletedTsMs() => $_has(8);
  @$pb.TagNumber(22)
  void clearDeletedTsMs() => $_clearField(22);
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
    final result = SiteProduct._();
    if (siteIid != null) result.siteIid = siteIid;
    if (productId != null) result.productId = productId;
    if (type != null) result.type = type;
    if (name != null) result.name = name;
    if (desc != null) result.desc = desc;
    if (unit != null) result.unit = unit;
    if (sku != null) result.sku = sku;
    if (rev != null) result.rev = rev;
    if (canSell != null) result.canSell = canSell;
    if (canReserve != null) result.canReserve = canReserve;
    if (trackStock != null) result.trackStock = trackStock;
    if (stockQty != null) result.stockQty = stockQty;
    if (price != null) result.price = price;
    if (pic != null) result.pic = pic;
    if (category != null) result.category = category;
    if (productJson != null) result.productJson = productJson;
    if (isArchived != null) result.isArchived = isArchived;
    if (createdTsMs != null) result.createdTsMs = createdTsMs;
    if (updatedTsMs != null) result.updatedTsMs = updatedTsMs;
    if (deletedTsMs != null) result.deletedTsMs = deletedTsMs;
    return result;
  }

  SiteProduct._();

  factory SiteProduct.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SiteProduct()..mergeFromBuffer(data, registry);
  factory SiteProduct.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SiteProduct()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SiteProduct',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: SiteProduct.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'siteIid')
    ..aInt64(2, _omitFieldNames ? '' : 'productId')
    ..aI(3, _omitFieldNames ? '' : 'type')
    ..aOS(4, _omitFieldNames ? '' : 'name')
    ..aOS(5, _omitFieldNames ? '' : 'desc')
    ..aOS(6, _omitFieldNames ? '' : 'unit')
    ..aOS(7, _omitFieldNames ? '' : 'sku')
    ..aInt64(8, _omitFieldNames ? '' : 'rev')
    ..aOB(9, _omitFieldNames ? '' : 'canSell')
    ..aOB(10, _omitFieldNames ? '' : 'canReserve')
    ..aOB(11, _omitFieldNames ? '' : 'trackStock')
    ..aI(12, _omitFieldNames ? '' : 'stockQty')
    ..aInt64(13, _omitFieldNames ? '' : 'price')
    ..aOS(14, _omitFieldNames ? '' : 'pic')
    ..aOS(15, _omitFieldNames ? '' : 'category')
    ..aOS(16, _omitFieldNames ? '' : 'productJson')
    ..aOB(17, _omitFieldNames ? '' : 'isArchived')
    ..aInt64(20, _omitFieldNames ? '' : 'createdTsMs')
    ..aInt64(21, _omitFieldNames ? '' : 'updatedTsMs')
    ..aInt64(22, _omitFieldNames ? '' : 'deletedTsMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SiteProduct clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SiteProduct copyWith(void Function(SiteProduct) updates) =>
      super.copyWith((message) => updates(message as SiteProduct))
          as SiteProduct;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SiteProduct() / SiteProduct.new instead')
  static SiteProduct create() => SiteProduct._();
  static $pb.GeneratedMessage $_createMessage() => SiteProduct._();
  @$core.override
  SiteProduct createEmptyInstance() => SiteProduct._();
  @$core.pragma('dart2js:noInline')
  static SiteProduct getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SiteProduct>(
          SiteProduct.$_createMessage);
  static SiteProduct? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get siteIid => $_getI64(0);
  @$pb.TagNumber(1)
  set siteIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSiteIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearSiteIid() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get productId => $_getI64(1);
  @$pb.TagNumber(2)
  set productId($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasProductId() => $_has(1);
  @$pb.TagNumber(2)
  void clearProductId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get type => $_getIZ(2);
  @$pb.TagNumber(3)
  set type($core.int value) => $_setSignedInt32(2, value);
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
  $core.String get desc => $_getSZ(4);
  @$pb.TagNumber(5)
  set desc($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasDesc() => $_has(4);
  @$pb.TagNumber(5)
  void clearDesc() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get unit => $_getSZ(5);
  @$pb.TagNumber(6)
  set unit($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasUnit() => $_has(5);
  @$pb.TagNumber(6)
  void clearUnit() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get sku => $_getSZ(6);
  @$pb.TagNumber(7)
  set sku($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasSku() => $_has(6);
  @$pb.TagNumber(7)
  void clearSku() => $_clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get rev => $_getI64(7);
  @$pb.TagNumber(8)
  set rev($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(8)
  $core.bool hasRev() => $_has(7);
  @$pb.TagNumber(8)
  void clearRev() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.bool get canSell => $_getBF(8);
  @$pb.TagNumber(9)
  set canSell($core.bool value) => $_setBool(8, value);
  @$pb.TagNumber(9)
  $core.bool hasCanSell() => $_has(8);
  @$pb.TagNumber(9)
  void clearCanSell() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.bool get canReserve => $_getBF(9);
  @$pb.TagNumber(10)
  set canReserve($core.bool value) => $_setBool(9, value);
  @$pb.TagNumber(10)
  $core.bool hasCanReserve() => $_has(9);
  @$pb.TagNumber(10)
  void clearCanReserve() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.bool get trackStock => $_getBF(10);
  @$pb.TagNumber(11)
  set trackStock($core.bool value) => $_setBool(10, value);
  @$pb.TagNumber(11)
  $core.bool hasTrackStock() => $_has(10);
  @$pb.TagNumber(11)
  void clearTrackStock() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.int get stockQty => $_getIZ(11);
  @$pb.TagNumber(12)
  set stockQty($core.int value) => $_setSignedInt32(11, value);
  @$pb.TagNumber(12)
  $core.bool hasStockQty() => $_has(11);
  @$pb.TagNumber(12)
  void clearStockQty() => $_clearField(12);

  @$pb.TagNumber(13)
  $fixnum.Int64 get price => $_getI64(12);
  @$pb.TagNumber(13)
  set price($fixnum.Int64 value) => $_setInt64(12, value);
  @$pb.TagNumber(13)
  $core.bool hasPrice() => $_has(12);
  @$pb.TagNumber(13)
  void clearPrice() => $_clearField(13);

  @$pb.TagNumber(14)
  $core.String get pic => $_getSZ(13);
  @$pb.TagNumber(14)
  set pic($core.String value) => $_setString(13, value);
  @$pb.TagNumber(14)
  $core.bool hasPic() => $_has(13);
  @$pb.TagNumber(14)
  void clearPic() => $_clearField(14);

  @$pb.TagNumber(15)
  $core.String get category => $_getSZ(14);
  @$pb.TagNumber(15)
  set category($core.String value) => $_setString(14, value);
  @$pb.TagNumber(15)
  $core.bool hasCategory() => $_has(14);
  @$pb.TagNumber(15)
  void clearCategory() => $_clearField(15);

  @$pb.TagNumber(16)
  $core.String get productJson => $_getSZ(15);
  @$pb.TagNumber(16)
  set productJson($core.String value) => $_setString(15, value);
  @$pb.TagNumber(16)
  $core.bool hasProductJson() => $_has(15);
  @$pb.TagNumber(16)
  void clearProductJson() => $_clearField(16);

  @$pb.TagNumber(17)
  $core.bool get isArchived => $_getBF(16);
  @$pb.TagNumber(17)
  set isArchived($core.bool value) => $_setBool(16, value);
  @$pb.TagNumber(17)
  $core.bool hasIsArchived() => $_has(16);
  @$pb.TagNumber(17)
  void clearIsArchived() => $_clearField(17);

  @$pb.TagNumber(20)
  $fixnum.Int64 get createdTsMs => $_getI64(17);
  @$pb.TagNumber(20)
  set createdTsMs($fixnum.Int64 value) => $_setInt64(17, value);
  @$pb.TagNumber(20)
  $core.bool hasCreatedTsMs() => $_has(17);
  @$pb.TagNumber(20)
  void clearCreatedTsMs() => $_clearField(20);

  @$pb.TagNumber(21)
  $fixnum.Int64 get updatedTsMs => $_getI64(18);
  @$pb.TagNumber(21)
  set updatedTsMs($fixnum.Int64 value) => $_setInt64(18, value);
  @$pb.TagNumber(21)
  $core.bool hasUpdatedTsMs() => $_has(18);
  @$pb.TagNumber(21)
  void clearUpdatedTsMs() => $_clearField(21);

  @$pb.TagNumber(22)
  $fixnum.Int64 get deletedTsMs => $_getI64(19);
  @$pb.TagNumber(22)
  set deletedTsMs($fixnum.Int64 value) => $_setInt64(19, value);
  @$pb.TagNumber(22)
  $core.bool hasDeletedTsMs() => $_has(19);
  @$pb.TagNumber(22)
  void clearDeletedTsMs() => $_clearField(22);
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
    final result = SiteContact._();
    if (siteIid != null) result.siteIid = siteIid;
    if (contactId != null) result.contactId = contactId;
    if (name != null) result.name = name;
    if (phone != null) result.phone = phone;
    if (email != null) result.email = email;
    if (address != null) result.address = address;
    if (note != null) result.note = note;
    if (metaJson != null) result.metaJson = metaJson;
    if (isArchived != null) result.isArchived = isArchived;
    if (createdTsMs != null) result.createdTsMs = createdTsMs;
    if (updatedTsMs != null) result.updatedTsMs = updatedTsMs;
    if (deletedTsMs != null) result.deletedTsMs = deletedTsMs;
    return result;
  }

  SiteContact._();

  factory SiteContact.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SiteContact()..mergeFromBuffer(data, registry);
  factory SiteContact.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SiteContact()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SiteContact',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: SiteContact.$_createMessage)
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
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SiteContact clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SiteContact copyWith(void Function(SiteContact) updates) =>
      super.copyWith((message) => updates(message as SiteContact))
          as SiteContact;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SiteContact() / SiteContact.new instead')
  static SiteContact create() => SiteContact._();
  static $pb.GeneratedMessage $_createMessage() => SiteContact._();
  @$core.override
  SiteContact createEmptyInstance() => SiteContact._();
  @$core.pragma('dart2js:noInline')
  static SiteContact getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SiteContact>(
          SiteContact.$_createMessage);
  static SiteContact? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get siteIid => $_getI64(0);
  @$pb.TagNumber(1)
  set siteIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSiteIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearSiteIid() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get contactId => $_getI64(1);
  @$pb.TagNumber(2)
  set contactId($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasContactId() => $_has(1);
  @$pb.TagNumber(2)
  void clearContactId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get name => $_getSZ(2);
  @$pb.TagNumber(3)
  set name($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasName() => $_has(2);
  @$pb.TagNumber(3)
  void clearName() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get phone => $_getSZ(3);
  @$pb.TagNumber(4)
  set phone($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPhone() => $_has(3);
  @$pb.TagNumber(4)
  void clearPhone() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get email => $_getSZ(4);
  @$pb.TagNumber(5)
  set email($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasEmail() => $_has(4);
  @$pb.TagNumber(5)
  void clearEmail() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get address => $_getSZ(5);
  @$pb.TagNumber(6)
  set address($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasAddress() => $_has(5);
  @$pb.TagNumber(6)
  void clearAddress() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get note => $_getSZ(6);
  @$pb.TagNumber(7)
  set note($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasNote() => $_has(6);
  @$pb.TagNumber(7)
  void clearNote() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get metaJson => $_getSZ(7);
  @$pb.TagNumber(8)
  set metaJson($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasMetaJson() => $_has(7);
  @$pb.TagNumber(8)
  void clearMetaJson() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.bool get isArchived => $_getBF(8);
  @$pb.TagNumber(9)
  set isArchived($core.bool value) => $_setBool(8, value);
  @$pb.TagNumber(9)
  $core.bool hasIsArchived() => $_has(8);
  @$pb.TagNumber(9)
  void clearIsArchived() => $_clearField(9);

  @$pb.TagNumber(20)
  $fixnum.Int64 get createdTsMs => $_getI64(9);
  @$pb.TagNumber(20)
  set createdTsMs($fixnum.Int64 value) => $_setInt64(9, value);
  @$pb.TagNumber(20)
  $core.bool hasCreatedTsMs() => $_has(9);
  @$pb.TagNumber(20)
  void clearCreatedTsMs() => $_clearField(20);

  @$pb.TagNumber(21)
  $fixnum.Int64 get updatedTsMs => $_getI64(10);
  @$pb.TagNumber(21)
  set updatedTsMs($fixnum.Int64 value) => $_setInt64(10, value);
  @$pb.TagNumber(21)
  $core.bool hasUpdatedTsMs() => $_has(10);
  @$pb.TagNumber(21)
  void clearUpdatedTsMs() => $_clearField(21);

  @$pb.TagNumber(22)
  $fixnum.Int64 get deletedTsMs => $_getI64(11);
  @$pb.TagNumber(22)
  set deletedTsMs($fixnum.Int64 value) => $_setInt64(11, value);
  @$pb.TagNumber(22)
  $core.bool hasDeletedTsMs() => $_has(11);
  @$pb.TagNumber(22)
  void clearDeletedTsMs() => $_clearField(22);
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
    final result = SiteObject._();
    if (id != null) result.id = id;
    if (siteIid != null) result.siteIid = siteIid;
    if (clientId != null) result.clientId = clientId;
    if (name != null) result.name = name;
    if (code != null) result.code = code;
    if (kind != null) result.kind = kind;
    if (productId != null) result.productId = productId;
    if (canOrder != null) result.canOrder = canOrder;
    if (canBeReserved != null) result.canBeReserved = canBeReserved;
    if (isActive != null) result.isActive = isActive;
    if (desc != null) result.desc = desc;
    if (pic != null) result.pic = pic;
    if (metaJson != null) result.metaJson = metaJson;
    if (createdTsMs != null) result.createdTsMs = createdTsMs;
    if (updatedTsMs != null) result.updatedTsMs = updatedTsMs;
    if (deletedTsMs != null) result.deletedTsMs = deletedTsMs;
    return result;
  }

  SiteObject._();

  factory SiteObject.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SiteObject()..mergeFromBuffer(data, registry);
  factory SiteObject.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SiteObject()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SiteObject',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: SiteObject.$_createMessage)
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
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SiteObject clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SiteObject copyWith(void Function(SiteObject) updates) =>
      super.copyWith((message) => updates(message as SiteObject)) as SiteObject;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SiteObject() / SiteObject.new instead')
  static SiteObject create() => SiteObject._();
  static $pb.GeneratedMessage $_createMessage() => SiteObject._();
  @$core.override
  SiteObject createEmptyInstance() => SiteObject._();
  @$core.pragma('dart2js:noInline')
  static SiteObject getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SiteObject>(SiteObject.$_createMessage);
  static SiteObject? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get siteIid => $_getI64(1);
  @$pb.TagNumber(2)
  set siteIid($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSiteIid() => $_has(1);
  @$pb.TagNumber(2)
  void clearSiteIid() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get clientId => $_getSZ(2);
  @$pb.TagNumber(3)
  set clientId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasClientId() => $_has(2);
  @$pb.TagNumber(3)
  void clearClientId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get name => $_getSZ(3);
  @$pb.TagNumber(4)
  set name($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasName() => $_has(3);
  @$pb.TagNumber(4)
  void clearName() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get code => $_getSZ(4);
  @$pb.TagNumber(5)
  set code($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasCode() => $_has(4);
  @$pb.TagNumber(5)
  void clearCode() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get kind => $_getSZ(5);
  @$pb.TagNumber(6)
  set kind($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasKind() => $_has(5);
  @$pb.TagNumber(6)
  void clearKind() => $_clearField(6);

  @$pb.TagNumber(7)
  $fixnum.Int64 get productId => $_getI64(6);
  @$pb.TagNumber(7)
  set productId($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(7)
  $core.bool hasProductId() => $_has(6);
  @$pb.TagNumber(7)
  void clearProductId() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.bool get canOrder => $_getBF(7);
  @$pb.TagNumber(8)
  set canOrder($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasCanOrder() => $_has(7);
  @$pb.TagNumber(8)
  void clearCanOrder() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.bool get canBeReserved => $_getBF(8);
  @$pb.TagNumber(9)
  set canBeReserved($core.bool value) => $_setBool(8, value);
  @$pb.TagNumber(9)
  $core.bool hasCanBeReserved() => $_has(8);
  @$pb.TagNumber(9)
  void clearCanBeReserved() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.bool get isActive => $_getBF(9);
  @$pb.TagNumber(10)
  set isActive($core.bool value) => $_setBool(9, value);
  @$pb.TagNumber(10)
  $core.bool hasIsActive() => $_has(9);
  @$pb.TagNumber(10)
  void clearIsActive() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.String get desc => $_getSZ(10);
  @$pb.TagNumber(11)
  set desc($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasDesc() => $_has(10);
  @$pb.TagNumber(11)
  void clearDesc() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.String get pic => $_getSZ(11);
  @$pb.TagNumber(12)
  set pic($core.String value) => $_setString(11, value);
  @$pb.TagNumber(12)
  $core.bool hasPic() => $_has(11);
  @$pb.TagNumber(12)
  void clearPic() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.String get metaJson => $_getSZ(12);
  @$pb.TagNumber(13)
  set metaJson($core.String value) => $_setString(12, value);
  @$pb.TagNumber(13)
  $core.bool hasMetaJson() => $_has(12);
  @$pb.TagNumber(13)
  void clearMetaJson() => $_clearField(13);

  @$pb.TagNumber(20)
  $fixnum.Int64 get createdTsMs => $_getI64(13);
  @$pb.TagNumber(20)
  set createdTsMs($fixnum.Int64 value) => $_setInt64(13, value);
  @$pb.TagNumber(20)
  $core.bool hasCreatedTsMs() => $_has(13);
  @$pb.TagNumber(20)
  void clearCreatedTsMs() => $_clearField(20);

  @$pb.TagNumber(21)
  $fixnum.Int64 get updatedTsMs => $_getI64(14);
  @$pb.TagNumber(21)
  set updatedTsMs($fixnum.Int64 value) => $_setInt64(14, value);
  @$pb.TagNumber(21)
  $core.bool hasUpdatedTsMs() => $_has(14);
  @$pb.TagNumber(21)
  void clearUpdatedTsMs() => $_clearField(21);

  @$pb.TagNumber(22)
  $fixnum.Int64 get deletedTsMs => $_getI64(15);
  @$pb.TagNumber(22)
  set deletedTsMs($fixnum.Int64 value) => $_setInt64(15, value);
  @$pb.TagNumber(22)
  $core.bool hasDeletedTsMs() => $_has(15);
  @$pb.TagNumber(22)
  void clearDeletedTsMs() => $_clearField(22);
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
    final result = SiteRow._();
    if (siteIid != null) result.siteIid = siteIid;
    if (alienId != null) result.alienId = alienId;
    if (name != null) result.name = name;
    if (pic != null) result.pic = pic;
    if (publishedVersionId != null)
      result.publishedVersionId = publishedVersionId;
    if (updatedTsMs != null) result.updatedTsMs = updatedTsMs;
    if (isArchived != null) result.isArchived = isArchived;
    return result;
  }

  SiteRow._();

  factory SiteRow.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SiteRow()..mergeFromBuffer(data, registry);
  factory SiteRow.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SiteRow()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SiteRow',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: SiteRow.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'siteIid')
    ..aOS(2, _omitFieldNames ? '' : 'alienId')
    ..aOS(3, _omitFieldNames ? '' : 'name')
    ..aOS(4, _omitFieldNames ? '' : 'pic')
    ..aOS(5, _omitFieldNames ? '' : 'publishedVersionId')
    ..aInt64(6, _omitFieldNames ? '' : 'updatedTsMs')
    ..aOB(7, _omitFieldNames ? '' : 'isArchived')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SiteRow clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SiteRow copyWith(void Function(SiteRow) updates) =>
      super.copyWith((message) => updates(message as SiteRow)) as SiteRow;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SiteRow() / SiteRow.new instead')
  static SiteRow create() => SiteRow._();
  static $pb.GeneratedMessage $_createMessage() => SiteRow._();
  @$core.override
  SiteRow createEmptyInstance() => SiteRow._();
  @$core.pragma('dart2js:noInline')
  static SiteRow getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SiteRow>(SiteRow.$_createMessage);
  static SiteRow? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get siteIid => $_getI64(0);
  @$pb.TagNumber(1)
  set siteIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSiteIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearSiteIid() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get alienId => $_getSZ(1);
  @$pb.TagNumber(2)
  set alienId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAlienId() => $_has(1);
  @$pb.TagNumber(2)
  void clearAlienId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get name => $_getSZ(2);
  @$pb.TagNumber(3)
  set name($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasName() => $_has(2);
  @$pb.TagNumber(3)
  void clearName() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get pic => $_getSZ(3);
  @$pb.TagNumber(4)
  set pic($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPic() => $_has(3);
  @$pb.TagNumber(4)
  void clearPic() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get publishedVersionId => $_getSZ(4);
  @$pb.TagNumber(5)
  set publishedVersionId($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasPublishedVersionId() => $_has(4);
  @$pb.TagNumber(5)
  void clearPublishedVersionId() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get updatedTsMs => $_getI64(5);
  @$pb.TagNumber(6)
  set updatedTsMs($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasUpdatedTsMs() => $_has(5);
  @$pb.TagNumber(6)
  void clearUpdatedTsMs() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.bool get isArchived => $_getBF(6);
  @$pb.TagNumber(7)
  set isArchived($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasIsArchived() => $_has(6);
  @$pb.TagNumber(7)
  void clearIsArchived() => $_clearField(7);
}

class ReqSiteList extends $pb.GeneratedMessage {
  factory ReqSiteList({
    $core.bool? archived,
  }) {
    final result = ReqSiteList._();
    if (archived != null) result.archived = archived;
    return result;
  }

  ReqSiteList._();

  factory ReqSiteList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSiteList()..mergeFromBuffer(data, registry);
  factory ReqSiteList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSiteList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqSiteList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqSiteList.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'archived')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSiteList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSiteList copyWith(void Function(ReqSiteList) updates) =>
      super.copyWith((message) => updates(message as ReqSiteList))
          as ReqSiteList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqSiteList() / ReqSiteList.new instead')
  static ReqSiteList create() => ReqSiteList._();
  static $pb.GeneratedMessage $_createMessage() => ReqSiteList._();
  @$core.override
  ReqSiteList createEmptyInstance() => ReqSiteList._();
  @$core.pragma('dart2js:noInline')
  static ReqSiteList getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqSiteList>(
          ReqSiteList.$_createMessage);
  static ReqSiteList? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get archived => $_getBF(0);
  @$pb.TagNumber(1)
  set archived($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasArchived() => $_has(0);
  @$pb.TagNumber(1)
  void clearArchived() => $_clearField(1);
}

class ResSiteList extends $pb.GeneratedMessage {
  factory ResSiteList({
    $core.Iterable<SiteRow>? sites,
    $core.int? archivedCount,
  }) {
    final result = ResSiteList._();
    if (sites != null) result.sites.addAll(sites);
    if (archivedCount != null) result.archivedCount = archivedCount;
    return result;
  }

  ResSiteList._();

  factory ResSiteList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSiteList()..mergeFromBuffer(data, registry);
  factory ResSiteList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSiteList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResSiteList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResSiteList.$_createMessage)
    ..pPM<SiteRow>(1, _omitFieldNames ? '' : 'sites',
        subBuilder: SiteRow.$_createMessage)
    ..aI(2, _omitFieldNames ? '' : 'archivedCount')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSiteList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSiteList copyWith(void Function(ResSiteList) updates) =>
      super.copyWith((message) => updates(message as ResSiteList))
          as ResSiteList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResSiteList() / ResSiteList.new instead')
  static ResSiteList create() => ResSiteList._();
  static $pb.GeneratedMessage $_createMessage() => ResSiteList._();
  @$core.override
  ResSiteList createEmptyInstance() => ResSiteList._();
  @$core.pragma('dart2js:noInline')
  static ResSiteList getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResSiteList>(
          ResSiteList.$_createMessage);
  static ResSiteList? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<SiteRow> get sites => $_getList(0);

  @$pb.TagNumber(2)
  $core.int get archivedCount => $_getIZ(1);
  @$pb.TagNumber(2)
  set archivedCount($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasArchivedCount() => $_has(1);
  @$pb.TagNumber(2)
  void clearArchivedCount() => $_clearField(2);
}

class ReqSiteDraftGet extends $pb.GeneratedMessage {
  factory ReqSiteDraftGet({
    $fixnum.Int64? siteIid,
  }) {
    final result = ReqSiteDraftGet._();
    if (siteIid != null) result.siteIid = siteIid;
    return result;
  }

  ReqSiteDraftGet._();

  factory ReqSiteDraftGet.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSiteDraftGet()..mergeFromBuffer(data, registry);
  factory ReqSiteDraftGet.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSiteDraftGet()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqSiteDraftGet',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqSiteDraftGet.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'siteIid')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSiteDraftGet clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSiteDraftGet copyWith(void Function(ReqSiteDraftGet) updates) =>
      super.copyWith((message) => updates(message as ReqSiteDraftGet))
          as ReqSiteDraftGet;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqSiteDraftGet() / ReqSiteDraftGet.new instead')
  static ReqSiteDraftGet create() => ReqSiteDraftGet._();
  static $pb.GeneratedMessage $_createMessage() => ReqSiteDraftGet._();
  @$core.override
  ReqSiteDraftGet createEmptyInstance() => ReqSiteDraftGet._();
  @$core.pragma('dart2js:noInline')
  static ReqSiteDraftGet getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqSiteDraftGet>(
          ReqSiteDraftGet.$_createMessage);
  static ReqSiteDraftGet? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get siteIid => $_getI64(0);
  @$pb.TagNumber(1)
  set siteIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSiteIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearSiteIid() => $_clearField(1);
}

class ResSiteDraftGet extends $pb.GeneratedMessage {
  factory ResSiteDraftGet({
    SiteDraft? draft,
    SiteConfig? config,
  }) {
    final result = ResSiteDraftGet._();
    if (draft != null) result.draft = draft;
    if (config != null) result.config = config;
    return result;
  }

  ResSiteDraftGet._();

  factory ResSiteDraftGet.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSiteDraftGet()..mergeFromBuffer(data, registry);
  factory ResSiteDraftGet.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSiteDraftGet()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResSiteDraftGet',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResSiteDraftGet.$_createMessage)
    ..aOM<SiteDraft>(1, _omitFieldNames ? '' : 'draft',
        subBuilder: SiteDraft.$_createMessage)
    ..aOM<SiteConfig>(2, _omitFieldNames ? '' : 'config',
        subBuilder: SiteConfig.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSiteDraftGet clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSiteDraftGet copyWith(void Function(ResSiteDraftGet) updates) =>
      super.copyWith((message) => updates(message as ResSiteDraftGet))
          as ResSiteDraftGet;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResSiteDraftGet() / ResSiteDraftGet.new instead')
  static ResSiteDraftGet create() => ResSiteDraftGet._();
  static $pb.GeneratedMessage $_createMessage() => ResSiteDraftGet._();
  @$core.override
  ResSiteDraftGet createEmptyInstance() => ResSiteDraftGet._();
  @$core.pragma('dart2js:noInline')
  static ResSiteDraftGet getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResSiteDraftGet>(
          ResSiteDraftGet.$_createMessage);
  static ResSiteDraftGet? _defaultInstance;

  @$pb.TagNumber(1)
  SiteDraft get draft => $_getN(0);
  @$pb.TagNumber(1)
  set draft(SiteDraft value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasDraft() => $_has(0);
  @$pb.TagNumber(1)
  void clearDraft() => $_clearField(1);
  @$pb.TagNumber(1)
  SiteDraft ensureDraft() => $_ensure(0);

  @$pb.TagNumber(2)
  SiteConfig get config => $_getN(1);
  @$pb.TagNumber(2)
  set config(SiteConfig value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasConfig() => $_has(1);
  @$pb.TagNumber(2)
  void clearConfig() => $_clearField(2);
  @$pb.TagNumber(2)
  SiteConfig ensureConfig() => $_ensure(1);
}

class ReqSiteDraftPut extends $pb.GeneratedMessage {
  factory ReqSiteDraftPut({
    SiteDraft? draft,
    $core.bool? skipPublish,
  }) {
    final result = ReqSiteDraftPut._();
    if (draft != null) result.draft = draft;
    if (skipPublish != null) result.skipPublish = skipPublish;
    return result;
  }

  ReqSiteDraftPut._();

  factory ReqSiteDraftPut.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSiteDraftPut()..mergeFromBuffer(data, registry);
  factory ReqSiteDraftPut.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSiteDraftPut()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqSiteDraftPut',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqSiteDraftPut.$_createMessage)
    ..aOM<SiteDraft>(1, _omitFieldNames ? '' : 'draft',
        subBuilder: SiteDraft.$_createMessage)
    ..aOB(2, _omitFieldNames ? '' : 'skipPublish')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSiteDraftPut clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSiteDraftPut copyWith(void Function(ReqSiteDraftPut) updates) =>
      super.copyWith((message) => updates(message as ReqSiteDraftPut))
          as ReqSiteDraftPut;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqSiteDraftPut() / ReqSiteDraftPut.new instead')
  static ReqSiteDraftPut create() => ReqSiteDraftPut._();
  static $pb.GeneratedMessage $_createMessage() => ReqSiteDraftPut._();
  @$core.override
  ReqSiteDraftPut createEmptyInstance() => ReqSiteDraftPut._();
  @$core.pragma('dart2js:noInline')
  static ReqSiteDraftPut getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqSiteDraftPut>(
          ReqSiteDraftPut.$_createMessage);
  static ReqSiteDraftPut? _defaultInstance;

  @$pb.TagNumber(1)
  SiteDraft get draft => $_getN(0);
  @$pb.TagNumber(1)
  set draft(SiteDraft value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasDraft() => $_has(0);
  @$pb.TagNumber(1)
  void clearDraft() => $_clearField(1);
  @$pb.TagNumber(1)
  SiteDraft ensureDraft() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.bool get skipPublish => $_getBF(1);
  @$pb.TagNumber(2)
  set skipPublish($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSkipPublish() => $_has(1);
  @$pb.TagNumber(2)
  void clearSkipPublish() => $_clearField(2);
}

class ResSiteDraftPut extends $pb.GeneratedMessage {
  factory ResSiteDraftPut({
    $fixnum.Int64? siteIid,
  }) {
    final result = ResSiteDraftPut._();
    if (siteIid != null) result.siteIid = siteIid;
    return result;
  }

  ResSiteDraftPut._();

  factory ResSiteDraftPut.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSiteDraftPut()..mergeFromBuffer(data, registry);
  factory ResSiteDraftPut.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSiteDraftPut()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResSiteDraftPut',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResSiteDraftPut.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'siteIid')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSiteDraftPut clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSiteDraftPut copyWith(void Function(ResSiteDraftPut) updates) =>
      super.copyWith((message) => updates(message as ResSiteDraftPut))
          as ResSiteDraftPut;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResSiteDraftPut() / ResSiteDraftPut.new instead')
  static ResSiteDraftPut create() => ResSiteDraftPut._();
  static $pb.GeneratedMessage $_createMessage() => ResSiteDraftPut._();
  @$core.override
  ResSiteDraftPut createEmptyInstance() => ResSiteDraftPut._();
  @$core.pragma('dart2js:noInline')
  static ResSiteDraftPut getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResSiteDraftPut>(
          ResSiteDraftPut.$_createMessage);
  static ResSiteDraftPut? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get siteIid => $_getI64(0);
  @$pb.TagNumber(1)
  set siteIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSiteIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearSiteIid() => $_clearField(1);
}

class ReqSitePublish extends $pb.GeneratedMessage {
  factory ReqSitePublish({
    $fixnum.Int64? siteIid,
  }) {
    final result = ReqSitePublish._();
    if (siteIid != null) result.siteIid = siteIid;
    return result;
  }

  ReqSitePublish._();

  factory ReqSitePublish.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSitePublish()..mergeFromBuffer(data, registry);
  factory ReqSitePublish.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSitePublish()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqSitePublish',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqSitePublish.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'siteIid')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSitePublish clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSitePublish copyWith(void Function(ReqSitePublish) updates) =>
      super.copyWith((message) => updates(message as ReqSitePublish))
          as ReqSitePublish;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqSitePublish() / ReqSitePublish.new instead')
  static ReqSitePublish create() => ReqSitePublish._();
  static $pb.GeneratedMessage $_createMessage() => ReqSitePublish._();
  @$core.override
  ReqSitePublish createEmptyInstance() => ReqSitePublish._();
  @$core.pragma('dart2js:noInline')
  static ReqSitePublish getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqSitePublish>(
          ReqSitePublish.$_createMessage);
  static ReqSitePublish? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get siteIid => $_getI64(0);
  @$pb.TagNumber(1)
  set siteIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSiteIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearSiteIid() => $_clearField(1);
}

class ResSitePublish extends $pb.GeneratedMessage {
  factory ResSitePublish({
    SitePublish? publish,
  }) {
    final result = ResSitePublish._();
    if (publish != null) result.publish = publish;
    return result;
  }

  ResSitePublish._();

  factory ResSitePublish.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSitePublish()..mergeFromBuffer(data, registry);
  factory ResSitePublish.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSitePublish()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResSitePublish',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResSitePublish.$_createMessage)
    ..aOM<SitePublish>(1, _omitFieldNames ? '' : 'publish',
        subBuilder: SitePublish.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSitePublish clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSitePublish copyWith(void Function(ResSitePublish) updates) =>
      super.copyWith((message) => updates(message as ResSitePublish))
          as ResSitePublish;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResSitePublish() / ResSitePublish.new instead')
  static ResSitePublish create() => ResSitePublish._();
  static $pb.GeneratedMessage $_createMessage() => ResSitePublish._();
  @$core.override
  ResSitePublish createEmptyInstance() => ResSitePublish._();
  @$core.pragma('dart2js:noInline')
  static ResSitePublish getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResSitePublish>(
          ResSitePublish.$_createMessage);
  static ResSitePublish? _defaultInstance;

  @$pb.TagNumber(1)
  SitePublish get publish => $_getN(0);
  @$pb.TagNumber(1)
  set publish(SitePublish value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPublish() => $_has(0);
  @$pb.TagNumber(1)
  void clearPublish() => $_clearField(1);
  @$pb.TagNumber(1)
  SitePublish ensurePublish() => $_ensure(0);
}

class ReqSiteProductList extends $pb.GeneratedMessage {
  factory ReqSiteProductList({
    $fixnum.Int64? siteIid,
  }) {
    final result = ReqSiteProductList._();
    if (siteIid != null) result.siteIid = siteIid;
    return result;
  }

  ReqSiteProductList._();

  factory ReqSiteProductList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSiteProductList()..mergeFromBuffer(data, registry);
  factory ReqSiteProductList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSiteProductList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqSiteProductList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqSiteProductList.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'siteIid')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSiteProductList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSiteProductList copyWith(void Function(ReqSiteProductList) updates) =>
      super.copyWith((message) => updates(message as ReqSiteProductList))
          as ReqSiteProductList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqSiteProductList() / ReqSiteProductList.new instead')
  static ReqSiteProductList create() => ReqSiteProductList._();
  static $pb.GeneratedMessage $_createMessage() => ReqSiteProductList._();
  @$core.override
  ReqSiteProductList createEmptyInstance() => ReqSiteProductList._();
  @$core.pragma('dart2js:noInline')
  static ReqSiteProductList getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqSiteProductList>(
          ReqSiteProductList.$_createMessage);
  static ReqSiteProductList? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get siteIid => $_getI64(0);
  @$pb.TagNumber(1)
  set siteIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSiteIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearSiteIid() => $_clearField(1);
}

class ResSiteProductList extends $pb.GeneratedMessage {
  factory ResSiteProductList({
    $core.Iterable<SiteProduct>? products,
  }) {
    final result = ResSiteProductList._();
    if (products != null) result.products.addAll(products);
    return result;
  }

  ResSiteProductList._();

  factory ResSiteProductList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSiteProductList()..mergeFromBuffer(data, registry);
  factory ResSiteProductList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSiteProductList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResSiteProductList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResSiteProductList.$_createMessage)
    ..pPM<SiteProduct>(1, _omitFieldNames ? '' : 'products',
        subBuilder: SiteProduct.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSiteProductList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSiteProductList copyWith(void Function(ResSiteProductList) updates) =>
      super.copyWith((message) => updates(message as ResSiteProductList))
          as ResSiteProductList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResSiteProductList() / ResSiteProductList.new instead')
  static ResSiteProductList create() => ResSiteProductList._();
  static $pb.GeneratedMessage $_createMessage() => ResSiteProductList._();
  @$core.override
  ResSiteProductList createEmptyInstance() => ResSiteProductList._();
  @$core.pragma('dart2js:noInline')
  static ResSiteProductList getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResSiteProductList>(
          ResSiteProductList.$_createMessage);
  static ResSiteProductList? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<SiteProduct> get products => $_getList(0);
}

class ReqSiteProductPut extends $pb.GeneratedMessage {
  factory ReqSiteProductPut({
    $fixnum.Int64? siteIid,
    SiteProduct? product,
  }) {
    final result = ReqSiteProductPut._();
    if (siteIid != null) result.siteIid = siteIid;
    if (product != null) result.product = product;
    return result;
  }

  ReqSiteProductPut._();

  factory ReqSiteProductPut.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSiteProductPut()..mergeFromBuffer(data, registry);
  factory ReqSiteProductPut.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSiteProductPut()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqSiteProductPut',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqSiteProductPut.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'siteIid')
    ..aOM<SiteProduct>(2, _omitFieldNames ? '' : 'product',
        subBuilder: SiteProduct.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSiteProductPut clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSiteProductPut copyWith(void Function(ReqSiteProductPut) updates) =>
      super.copyWith((message) => updates(message as ReqSiteProductPut))
          as ReqSiteProductPut;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqSiteProductPut() / ReqSiteProductPut.new instead')
  static ReqSiteProductPut create() => ReqSiteProductPut._();
  static $pb.GeneratedMessage $_createMessage() => ReqSiteProductPut._();
  @$core.override
  ReqSiteProductPut createEmptyInstance() => ReqSiteProductPut._();
  @$core.pragma('dart2js:noInline')
  static ReqSiteProductPut getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqSiteProductPut>(
          ReqSiteProductPut.$_createMessage);
  static ReqSiteProductPut? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get siteIid => $_getI64(0);
  @$pb.TagNumber(1)
  set siteIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSiteIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearSiteIid() => $_clearField(1);

  @$pb.TagNumber(2)
  SiteProduct get product => $_getN(1);
  @$pb.TagNumber(2)
  set product(SiteProduct value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasProduct() => $_has(1);
  @$pb.TagNumber(2)
  void clearProduct() => $_clearField(2);
  @$pb.TagNumber(2)
  SiteProduct ensureProduct() => $_ensure(1);
}

class ResSiteProductPut extends $pb.GeneratedMessage {
  factory ResSiteProductPut({
    $fixnum.Int64? productId,
  }) {
    final result = ResSiteProductPut._();
    if (productId != null) result.productId = productId;
    return result;
  }

  ResSiteProductPut._();

  factory ResSiteProductPut.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSiteProductPut()..mergeFromBuffer(data, registry);
  factory ResSiteProductPut.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSiteProductPut()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResSiteProductPut',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResSiteProductPut.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'productId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSiteProductPut clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSiteProductPut copyWith(void Function(ResSiteProductPut) updates) =>
      super.copyWith((message) => updates(message as ResSiteProductPut))
          as ResSiteProductPut;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResSiteProductPut() / ResSiteProductPut.new instead')
  static ResSiteProductPut create() => ResSiteProductPut._();
  static $pb.GeneratedMessage $_createMessage() => ResSiteProductPut._();
  @$core.override
  ResSiteProductPut createEmptyInstance() => ResSiteProductPut._();
  @$core.pragma('dart2js:noInline')
  static ResSiteProductPut getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResSiteProductPut>(
          ResSiteProductPut.$_createMessage);
  static ResSiteProductPut? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get productId => $_getI64(0);
  @$pb.TagNumber(1)
  set productId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasProductId() => $_has(0);
  @$pb.TagNumber(1)
  void clearProductId() => $_clearField(1);
}

class ReqSiteContactList extends $pb.GeneratedMessage {
  factory ReqSiteContactList({
    $fixnum.Int64? siteIid,
    $core.String? q,
  }) {
    final result = ReqSiteContactList._();
    if (siteIid != null) result.siteIid = siteIid;
    if (q != null) result.q = q;
    return result;
  }

  ReqSiteContactList._();

  factory ReqSiteContactList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSiteContactList()..mergeFromBuffer(data, registry);
  factory ReqSiteContactList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSiteContactList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqSiteContactList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqSiteContactList.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'siteIid')
    ..aOS(2, _omitFieldNames ? '' : 'q')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSiteContactList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSiteContactList copyWith(void Function(ReqSiteContactList) updates) =>
      super.copyWith((message) => updates(message as ReqSiteContactList))
          as ReqSiteContactList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqSiteContactList() / ReqSiteContactList.new instead')
  static ReqSiteContactList create() => ReqSiteContactList._();
  static $pb.GeneratedMessage $_createMessage() => ReqSiteContactList._();
  @$core.override
  ReqSiteContactList createEmptyInstance() => ReqSiteContactList._();
  @$core.pragma('dart2js:noInline')
  static ReqSiteContactList getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqSiteContactList>(
          ReqSiteContactList.$_createMessage);
  static ReqSiteContactList? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get siteIid => $_getI64(0);
  @$pb.TagNumber(1)
  set siteIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSiteIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearSiteIid() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get q => $_getSZ(1);
  @$pb.TagNumber(2)
  set q($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasQ() => $_has(1);
  @$pb.TagNumber(2)
  void clearQ() => $_clearField(2);
}

class ResSiteContactList extends $pb.GeneratedMessage {
  factory ResSiteContactList({
    $core.Iterable<SiteContact>? contacts,
  }) {
    final result = ResSiteContactList._();
    if (contacts != null) result.contacts.addAll(contacts);
    return result;
  }

  ResSiteContactList._();

  factory ResSiteContactList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSiteContactList()..mergeFromBuffer(data, registry);
  factory ResSiteContactList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSiteContactList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResSiteContactList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResSiteContactList.$_createMessage)
    ..pPM<SiteContact>(1, _omitFieldNames ? '' : 'contacts',
        subBuilder: SiteContact.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSiteContactList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSiteContactList copyWith(void Function(ResSiteContactList) updates) =>
      super.copyWith((message) => updates(message as ResSiteContactList))
          as ResSiteContactList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResSiteContactList() / ResSiteContactList.new instead')
  static ResSiteContactList create() => ResSiteContactList._();
  static $pb.GeneratedMessage $_createMessage() => ResSiteContactList._();
  @$core.override
  ResSiteContactList createEmptyInstance() => ResSiteContactList._();
  @$core.pragma('dart2js:noInline')
  static ResSiteContactList getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResSiteContactList>(
          ResSiteContactList.$_createMessage);
  static ResSiteContactList? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<SiteContact> get contacts => $_getList(0);
}

class ReqSiteContactPut extends $pb.GeneratedMessage {
  factory ReqSiteContactPut({
    $fixnum.Int64? siteIid,
    SiteContact? contact,
  }) {
    final result = ReqSiteContactPut._();
    if (siteIid != null) result.siteIid = siteIid;
    if (contact != null) result.contact = contact;
    return result;
  }

  ReqSiteContactPut._();

  factory ReqSiteContactPut.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSiteContactPut()..mergeFromBuffer(data, registry);
  factory ReqSiteContactPut.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSiteContactPut()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqSiteContactPut',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqSiteContactPut.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'siteIid')
    ..aOM<SiteContact>(2, _omitFieldNames ? '' : 'contact',
        subBuilder: SiteContact.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSiteContactPut clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSiteContactPut copyWith(void Function(ReqSiteContactPut) updates) =>
      super.copyWith((message) => updates(message as ReqSiteContactPut))
          as ReqSiteContactPut;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqSiteContactPut() / ReqSiteContactPut.new instead')
  static ReqSiteContactPut create() => ReqSiteContactPut._();
  static $pb.GeneratedMessage $_createMessage() => ReqSiteContactPut._();
  @$core.override
  ReqSiteContactPut createEmptyInstance() => ReqSiteContactPut._();
  @$core.pragma('dart2js:noInline')
  static ReqSiteContactPut getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqSiteContactPut>(
          ReqSiteContactPut.$_createMessage);
  static ReqSiteContactPut? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get siteIid => $_getI64(0);
  @$pb.TagNumber(1)
  set siteIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSiteIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearSiteIid() => $_clearField(1);

  @$pb.TagNumber(2)
  SiteContact get contact => $_getN(1);
  @$pb.TagNumber(2)
  set contact(SiteContact value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasContact() => $_has(1);
  @$pb.TagNumber(2)
  void clearContact() => $_clearField(2);
  @$pb.TagNumber(2)
  SiteContact ensureContact() => $_ensure(1);
}

class ResSiteContactPut extends $pb.GeneratedMessage {
  factory ResSiteContactPut({
    $fixnum.Int64? contactId,
  }) {
    final result = ResSiteContactPut._();
    if (contactId != null) result.contactId = contactId;
    return result;
  }

  ResSiteContactPut._();

  factory ResSiteContactPut.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSiteContactPut()..mergeFromBuffer(data, registry);
  factory ResSiteContactPut.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSiteContactPut()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResSiteContactPut',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResSiteContactPut.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'contactId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSiteContactPut clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSiteContactPut copyWith(void Function(ResSiteContactPut) updates) =>
      super.copyWith((message) => updates(message as ResSiteContactPut))
          as ResSiteContactPut;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResSiteContactPut() / ResSiteContactPut.new instead')
  static ResSiteContactPut create() => ResSiteContactPut._();
  static $pb.GeneratedMessage $_createMessage() => ResSiteContactPut._();
  @$core.override
  ResSiteContactPut createEmptyInstance() => ResSiteContactPut._();
  @$core.pragma('dart2js:noInline')
  static ResSiteContactPut getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResSiteContactPut>(
          ResSiteContactPut.$_createMessage);
  static ResSiteContactPut? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get contactId => $_getI64(0);
  @$pb.TagNumber(1)
  set contactId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasContactId() => $_has(0);
  @$pb.TagNumber(1)
  void clearContactId() => $_clearField(1);
}

class ReqSiteObjectList extends $pb.GeneratedMessage {
  factory ReqSiteObjectList({
    $fixnum.Int64? siteIid,
  }) {
    final result = ReqSiteObjectList._();
    if (siteIid != null) result.siteIid = siteIid;
    return result;
  }

  ReqSiteObjectList._();

  factory ReqSiteObjectList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSiteObjectList()..mergeFromBuffer(data, registry);
  factory ReqSiteObjectList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSiteObjectList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqSiteObjectList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqSiteObjectList.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'siteIid')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSiteObjectList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSiteObjectList copyWith(void Function(ReqSiteObjectList) updates) =>
      super.copyWith((message) => updates(message as ReqSiteObjectList))
          as ReqSiteObjectList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqSiteObjectList() / ReqSiteObjectList.new instead')
  static ReqSiteObjectList create() => ReqSiteObjectList._();
  static $pb.GeneratedMessage $_createMessage() => ReqSiteObjectList._();
  @$core.override
  ReqSiteObjectList createEmptyInstance() => ReqSiteObjectList._();
  @$core.pragma('dart2js:noInline')
  static ReqSiteObjectList getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqSiteObjectList>(
          ReqSiteObjectList.$_createMessage);
  static ReqSiteObjectList? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get siteIid => $_getI64(0);
  @$pb.TagNumber(1)
  set siteIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSiteIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearSiteIid() => $_clearField(1);
}

class ResSiteObjectList extends $pb.GeneratedMessage {
  factory ResSiteObjectList({
    $core.Iterable<SiteObject>? objs,
  }) {
    final result = ResSiteObjectList._();
    if (objs != null) result.objs.addAll(objs);
    return result;
  }

  ResSiteObjectList._();

  factory ResSiteObjectList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSiteObjectList()..mergeFromBuffer(data, registry);
  factory ResSiteObjectList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSiteObjectList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResSiteObjectList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResSiteObjectList.$_createMessage)
    ..pPM<SiteObject>(1, _omitFieldNames ? '' : 'objs',
        subBuilder: SiteObject.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSiteObjectList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSiteObjectList copyWith(void Function(ResSiteObjectList) updates) =>
      super.copyWith((message) => updates(message as ResSiteObjectList))
          as ResSiteObjectList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResSiteObjectList() / ResSiteObjectList.new instead')
  static ResSiteObjectList create() => ResSiteObjectList._();
  static $pb.GeneratedMessage $_createMessage() => ResSiteObjectList._();
  @$core.override
  ResSiteObjectList createEmptyInstance() => ResSiteObjectList._();
  @$core.pragma('dart2js:noInline')
  static ResSiteObjectList getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResSiteObjectList>(
          ResSiteObjectList.$_createMessage);
  static ResSiteObjectList? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<SiteObject> get objs => $_getList(0);
}

class ReqSiteObjectPut extends $pb.GeneratedMessage {
  factory ReqSiteObjectPut({
    $fixnum.Int64? siteIid,
    SiteObject? obj,
  }) {
    final result = ReqSiteObjectPut._();
    if (siteIid != null) result.siteIid = siteIid;
    if (obj != null) result.obj = obj;
    return result;
  }

  ReqSiteObjectPut._();

  factory ReqSiteObjectPut.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSiteObjectPut()..mergeFromBuffer(data, registry);
  factory ReqSiteObjectPut.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSiteObjectPut()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqSiteObjectPut',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqSiteObjectPut.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'siteIid')
    ..aOM<SiteObject>(2, _omitFieldNames ? '' : 'obj',
        subBuilder: SiteObject.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSiteObjectPut clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSiteObjectPut copyWith(void Function(ReqSiteObjectPut) updates) =>
      super.copyWith((message) => updates(message as ReqSiteObjectPut))
          as ReqSiteObjectPut;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqSiteObjectPut() / ReqSiteObjectPut.new instead')
  static ReqSiteObjectPut create() => ReqSiteObjectPut._();
  static $pb.GeneratedMessage $_createMessage() => ReqSiteObjectPut._();
  @$core.override
  ReqSiteObjectPut createEmptyInstance() => ReqSiteObjectPut._();
  @$core.pragma('dart2js:noInline')
  static ReqSiteObjectPut getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqSiteObjectPut>(
          ReqSiteObjectPut.$_createMessage);
  static ReqSiteObjectPut? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get siteIid => $_getI64(0);
  @$pb.TagNumber(1)
  set siteIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSiteIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearSiteIid() => $_clearField(1);

  @$pb.TagNumber(2)
  SiteObject get obj => $_getN(1);
  @$pb.TagNumber(2)
  set obj(SiteObject value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasObj() => $_has(1);
  @$pb.TagNumber(2)
  void clearObj() => $_clearField(2);
  @$pb.TagNumber(2)
  SiteObject ensureObj() => $_ensure(1);
}

class ResSiteObjectPut extends $pb.GeneratedMessage {
  factory ResSiteObjectPut({
    $fixnum.Int64? id,
  }) {
    final result = ResSiteObjectPut._();
    if (id != null) result.id = id;
    return result;
  }

  ResSiteObjectPut._();

  factory ResSiteObjectPut.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSiteObjectPut()..mergeFromBuffer(data, registry);
  factory ResSiteObjectPut.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSiteObjectPut()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResSiteObjectPut',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResSiteObjectPut.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSiteObjectPut clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSiteObjectPut copyWith(void Function(ResSiteObjectPut) updates) =>
      super.copyWith((message) => updates(message as ResSiteObjectPut))
          as ResSiteObjectPut;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResSiteObjectPut() / ResSiteObjectPut.new instead')
  static ResSiteObjectPut create() => ResSiteObjectPut._();
  static $pb.GeneratedMessage $_createMessage() => ResSiteObjectPut._();
  @$core.override
  ResSiteObjectPut createEmptyInstance() => ResSiteObjectPut._();
  @$core.pragma('dart2js:noInline')
  static ResSiteObjectPut getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResSiteObjectPut>(
          ResSiteObjectPut.$_createMessage);
  static ResSiteObjectPut? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
