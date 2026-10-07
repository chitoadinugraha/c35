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

import 'site.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'site.pbenum.dart';

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
    $core.String? verifyToken,
    $core.String? verifyError,
    $core.String? tlsError,
    $fixnum.Int64? lastVerifyTsMs,
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
    if (verifyToken != null) result.verifyToken = verifyToken;
    if (verifyError != null) result.verifyError = verifyError;
    if (tlsError != null) result.tlsError = tlsError;
    if (lastVerifyTsMs != null) result.lastVerifyTsMs = lastVerifyTsMs;
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
    ..aOS(7, _omitFieldNames ? '' : 'verifyToken')
    ..aOS(8, _omitFieldNames ? '' : 'verifyError')
    ..aOS(9, _omitFieldNames ? '' : 'tlsError')
    ..aInt64(10, _omitFieldNames ? '' : 'lastVerifyTsMs')
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

  @$pb.TagNumber(7)
  $core.String get verifyToken => $_getSZ(6);
  @$pb.TagNumber(7)
  set verifyToken($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasVerifyToken() => $_has(6);
  @$pb.TagNumber(7)
  void clearVerifyToken() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get verifyError => $_getSZ(7);
  @$pb.TagNumber(8)
  set verifyError($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasVerifyError() => $_has(7);
  @$pb.TagNumber(8)
  void clearVerifyError() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get tlsError => $_getSZ(8);
  @$pb.TagNumber(9)
  set tlsError($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasTlsError() => $_has(8);
  @$pb.TagNumber(9)
  void clearTlsError() => $_clearField(9);

  @$pb.TagNumber(10)
  $fixnum.Int64 get lastVerifyTsMs => $_getI64(9);
  @$pb.TagNumber(10)
  set lastVerifyTsMs($fixnum.Int64 value) => $_setInt64(9, value);
  @$pb.TagNumber(10)
  $core.bool hasLastVerifyTsMs() => $_has(9);
  @$pb.TagNumber(10)
  void clearLastVerifyTsMs() => $_clearField(10);

  @$pb.TagNumber(20)
  $fixnum.Int64 get createdTsMs => $_getI64(10);
  @$pb.TagNumber(20)
  set createdTsMs($fixnum.Int64 value) => $_setInt64(10, value);
  @$pb.TagNumber(20)
  $core.bool hasCreatedTsMs() => $_has(10);
  @$pb.TagNumber(20)
  void clearCreatedTsMs() => $_clearField(20);

  @$pb.TagNumber(21)
  $fixnum.Int64 get updatedTsMs => $_getI64(11);
  @$pb.TagNumber(21)
  set updatedTsMs($fixnum.Int64 value) => $_setInt64(11, value);
  @$pb.TagNumber(21)
  $core.bool hasUpdatedTsMs() => $_has(11);
  @$pb.TagNumber(21)
  void clearUpdatedTsMs() => $_clearField(21);

  @$pb.TagNumber(22)
  $fixnum.Int64 get deletedTsMs => $_getI64(12);
  @$pb.TagNumber(22)
  set deletedTsMs($fixnum.Int64 value) => $_setInt64(12, value);
  @$pb.TagNumber(22)
  $core.bool hasDeletedTsMs() => $_has(12);
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

class SiteProductEmbed extends $pb.GeneratedMessage {
  factory SiteProductEmbed({
    $fixnum.Int64? siteIid,
    $fixnum.Int64? embedId,
    $fixnum.Int64? productId,
    $core.String? label,
    $fixnum.Int64? createdTsMs,
    $fixnum.Int64? updatedTsMs,
    $fixnum.Int64? deletedTsMs,
  }) {
    final result = SiteProductEmbed._();
    if (siteIid != null) result.siteIid = siteIid;
    if (embedId != null) result.embedId = embedId;
    if (productId != null) result.productId = productId;
    if (label != null) result.label = label;
    if (createdTsMs != null) result.createdTsMs = createdTsMs;
    if (updatedTsMs != null) result.updatedTsMs = updatedTsMs;
    if (deletedTsMs != null) result.deletedTsMs = deletedTsMs;
    return result;
  }

  SiteProductEmbed._();

  factory SiteProductEmbed.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SiteProductEmbed()..mergeFromBuffer(data, registry);
  factory SiteProductEmbed.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SiteProductEmbed()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SiteProductEmbed',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: SiteProductEmbed.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'siteIid')
    ..aInt64(2, _omitFieldNames ? '' : 'embedId')
    ..aInt64(3, _omitFieldNames ? '' : 'productId')
    ..aOS(4, _omitFieldNames ? '' : 'label')
    ..aInt64(20, _omitFieldNames ? '' : 'createdTsMs')
    ..aInt64(21, _omitFieldNames ? '' : 'updatedTsMs')
    ..aInt64(22, _omitFieldNames ? '' : 'deletedTsMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SiteProductEmbed clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SiteProductEmbed copyWith(void Function(SiteProductEmbed) updates) =>
      super.copyWith((message) => updates(message as SiteProductEmbed))
          as SiteProductEmbed;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SiteProductEmbed() / SiteProductEmbed.new instead')
  static SiteProductEmbed create() => SiteProductEmbed._();
  static $pb.GeneratedMessage $_createMessage() => SiteProductEmbed._();
  @$core.override
  SiteProductEmbed createEmptyInstance() => SiteProductEmbed._();
  @$core.pragma('dart2js:noInline')
  static SiteProductEmbed getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SiteProductEmbed>(
          SiteProductEmbed.$_createMessage);
  static SiteProductEmbed? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get siteIid => $_getI64(0);
  @$pb.TagNumber(1)
  set siteIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSiteIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearSiteIid() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get embedId => $_getI64(1);
  @$pb.TagNumber(2)
  set embedId($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEmbedId() => $_has(1);
  @$pb.TagNumber(2)
  void clearEmbedId() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get productId => $_getI64(2);
  @$pb.TagNumber(3)
  set productId($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasProductId() => $_has(2);
  @$pb.TagNumber(3)
  void clearProductId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get label => $_getSZ(3);
  @$pb.TagNumber(4)
  set label($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasLabel() => $_has(3);
  @$pb.TagNumber(4)
  void clearLabel() => $_clearField(4);

  @$pb.TagNumber(20)
  $fixnum.Int64 get createdTsMs => $_getI64(4);
  @$pb.TagNumber(20)
  set createdTsMs($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(20)
  $core.bool hasCreatedTsMs() => $_has(4);
  @$pb.TagNumber(20)
  void clearCreatedTsMs() => $_clearField(20);

  @$pb.TagNumber(21)
  $fixnum.Int64 get updatedTsMs => $_getI64(5);
  @$pb.TagNumber(21)
  set updatedTsMs($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(21)
  $core.bool hasUpdatedTsMs() => $_has(5);
  @$pb.TagNumber(21)
  void clearUpdatedTsMs() => $_clearField(21);

  @$pb.TagNumber(22)
  $fixnum.Int64 get deletedTsMs => $_getI64(6);
  @$pb.TagNumber(22)
  set deletedTsMs($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(22)
  $core.bool hasDeletedTsMs() => $_has(6);
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

class SiteLink extends $pb.GeneratedMessage {
  factory SiteLink({
    $fixnum.Int64? siteIid,
    $fixnum.Int64? linkId,
    $core.int? sortOrder,
    $core.String? label,
    $core.String? url,
    $core.String? icon,
    $core.bool? isPinned,
    $core.bool? active,
    $fixnum.Int64? createdTsMs,
    $fixnum.Int64? updatedTsMs,
    $fixnum.Int64? deletedTsMs,
  }) {
    final result = SiteLink._();
    if (siteIid != null) result.siteIid = siteIid;
    if (linkId != null) result.linkId = linkId;
    if (sortOrder != null) result.sortOrder = sortOrder;
    if (label != null) result.label = label;
    if (url != null) result.url = url;
    if (icon != null) result.icon = icon;
    if (isPinned != null) result.isPinned = isPinned;
    if (active != null) result.active = active;
    if (createdTsMs != null) result.createdTsMs = createdTsMs;
    if (updatedTsMs != null) result.updatedTsMs = updatedTsMs;
    if (deletedTsMs != null) result.deletedTsMs = deletedTsMs;
    return result;
  }

  SiteLink._();

  factory SiteLink.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SiteLink()..mergeFromBuffer(data, registry);
  factory SiteLink.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SiteLink()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SiteLink',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: SiteLink.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'siteIid')
    ..aInt64(2, _omitFieldNames ? '' : 'linkId')
    ..aI(3, _omitFieldNames ? '' : 'sortOrder')
    ..aOS(4, _omitFieldNames ? '' : 'label')
    ..aOS(5, _omitFieldNames ? '' : 'url')
    ..aOS(6, _omitFieldNames ? '' : 'icon')
    ..aOB(7, _omitFieldNames ? '' : 'isPinned')
    ..aOB(8, _omitFieldNames ? '' : 'active')
    ..aInt64(20, _omitFieldNames ? '' : 'createdTsMs')
    ..aInt64(21, _omitFieldNames ? '' : 'updatedTsMs')
    ..aInt64(22, _omitFieldNames ? '' : 'deletedTsMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SiteLink clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SiteLink copyWith(void Function(SiteLink) updates) =>
      super.copyWith((message) => updates(message as SiteLink)) as SiteLink;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SiteLink() / SiteLink.new instead')
  static SiteLink create() => SiteLink._();
  static $pb.GeneratedMessage $_createMessage() => SiteLink._();
  @$core.override
  SiteLink createEmptyInstance() => SiteLink._();
  @$core.pragma('dart2js:noInline')
  static SiteLink getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SiteLink>(SiteLink.$_createMessage);
  static SiteLink? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get siteIid => $_getI64(0);
  @$pb.TagNumber(1)
  set siteIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSiteIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearSiteIid() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get linkId => $_getI64(1);
  @$pb.TagNumber(2)
  set linkId($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLinkId() => $_has(1);
  @$pb.TagNumber(2)
  void clearLinkId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get sortOrder => $_getIZ(2);
  @$pb.TagNumber(3)
  set sortOrder($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSortOrder() => $_has(2);
  @$pb.TagNumber(3)
  void clearSortOrder() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get label => $_getSZ(3);
  @$pb.TagNumber(4)
  set label($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasLabel() => $_has(3);
  @$pb.TagNumber(4)
  void clearLabel() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get url => $_getSZ(4);
  @$pb.TagNumber(5)
  set url($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasUrl() => $_has(4);
  @$pb.TagNumber(5)
  void clearUrl() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get icon => $_getSZ(5);
  @$pb.TagNumber(6)
  set icon($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasIcon() => $_has(5);
  @$pb.TagNumber(6)
  void clearIcon() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.bool get isPinned => $_getBF(6);
  @$pb.TagNumber(7)
  set isPinned($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasIsPinned() => $_has(6);
  @$pb.TagNumber(7)
  void clearIsPinned() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.bool get active => $_getBF(7);
  @$pb.TagNumber(8)
  set active($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasActive() => $_has(7);
  @$pb.TagNumber(8)
  void clearActive() => $_clearField(8);

  @$pb.TagNumber(20)
  $fixnum.Int64 get createdTsMs => $_getI64(8);
  @$pb.TagNumber(20)
  set createdTsMs($fixnum.Int64 value) => $_setInt64(8, value);
  @$pb.TagNumber(20)
  $core.bool hasCreatedTsMs() => $_has(8);
  @$pb.TagNumber(20)
  void clearCreatedTsMs() => $_clearField(20);

  @$pb.TagNumber(21)
  $fixnum.Int64 get updatedTsMs => $_getI64(9);
  @$pb.TagNumber(21)
  set updatedTsMs($fixnum.Int64 value) => $_setInt64(9, value);
  @$pb.TagNumber(21)
  $core.bool hasUpdatedTsMs() => $_has(9);
  @$pb.TagNumber(21)
  void clearUpdatedTsMs() => $_clearField(21);

  @$pb.TagNumber(22)
  $fixnum.Int64 get deletedTsMs => $_getI64(10);
  @$pb.TagNumber(22)
  set deletedTsMs($fixnum.Int64 value) => $_setInt64(10, value);
  @$pb.TagNumber(22)
  $core.bool hasDeletedTsMs() => $_has(10);
  @$pb.TagNumber(22)
  void clearDeletedTsMs() => $_clearField(22);
}

class SitePost extends $pb.GeneratedMessage {
  factory SitePost({
    $fixnum.Int64? siteIid,
    $fixnum.Int64? postId,
    $core.int? sortOrder,
    $core.String? title,
    $core.String? caption,
    $core.String? body,
    $core.String? mediaJson,
    $core.bool? onStorefront,
    $core.String? thumb,
    $core.String? feedKind,
    $fixnum.Int64? createdTsMs,
    $fixnum.Int64? updatedTsMs,
    $fixnum.Int64? deletedTsMs,
  }) {
    final result = SitePost._();
    if (siteIid != null) result.siteIid = siteIid;
    if (postId != null) result.postId = postId;
    if (sortOrder != null) result.sortOrder = sortOrder;
    if (title != null) result.title = title;
    if (caption != null) result.caption = caption;
    if (body != null) result.body = body;
    if (mediaJson != null) result.mediaJson = mediaJson;
    if (onStorefront != null) result.onStorefront = onStorefront;
    if (thumb != null) result.thumb = thumb;
    if (feedKind != null) result.feedKind = feedKind;
    if (createdTsMs != null) result.createdTsMs = createdTsMs;
    if (updatedTsMs != null) result.updatedTsMs = updatedTsMs;
    if (deletedTsMs != null) result.deletedTsMs = deletedTsMs;
    return result;
  }

  SitePost._();

  factory SitePost.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SitePost()..mergeFromBuffer(data, registry);
  factory SitePost.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SitePost()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SitePost',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: SitePost.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'siteIid')
    ..aInt64(2, _omitFieldNames ? '' : 'postId')
    ..aI(3, _omitFieldNames ? '' : 'sortOrder')
    ..aOS(4, _omitFieldNames ? '' : 'title')
    ..aOS(5, _omitFieldNames ? '' : 'caption')
    ..aOS(6, _omitFieldNames ? '' : 'body')
    ..aOS(7, _omitFieldNames ? '' : 'mediaJson')
    ..aOB(8, _omitFieldNames ? '' : 'onStorefront')
    ..aOS(9, _omitFieldNames ? '' : 'thumb')
    ..aOS(10, _omitFieldNames ? '' : 'feedKind')
    ..aInt64(20, _omitFieldNames ? '' : 'createdTsMs')
    ..aInt64(21, _omitFieldNames ? '' : 'updatedTsMs')
    ..aInt64(22, _omitFieldNames ? '' : 'deletedTsMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SitePost clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SitePost copyWith(void Function(SitePost) updates) =>
      super.copyWith((message) => updates(message as SitePost)) as SitePost;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SitePost() / SitePost.new instead')
  static SitePost create() => SitePost._();
  static $pb.GeneratedMessage $_createMessage() => SitePost._();
  @$core.override
  SitePost createEmptyInstance() => SitePost._();
  @$core.pragma('dart2js:noInline')
  static SitePost getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SitePost>(SitePost.$_createMessage);
  static SitePost? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get siteIid => $_getI64(0);
  @$pb.TagNumber(1)
  set siteIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSiteIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearSiteIid() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get postId => $_getI64(1);
  @$pb.TagNumber(2)
  set postId($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPostId() => $_has(1);
  @$pb.TagNumber(2)
  void clearPostId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get sortOrder => $_getIZ(2);
  @$pb.TagNumber(3)
  set sortOrder($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSortOrder() => $_has(2);
  @$pb.TagNumber(3)
  void clearSortOrder() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get title => $_getSZ(3);
  @$pb.TagNumber(4)
  set title($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTitle() => $_has(3);
  @$pb.TagNumber(4)
  void clearTitle() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get caption => $_getSZ(4);
  @$pb.TagNumber(5)
  set caption($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasCaption() => $_has(4);
  @$pb.TagNumber(5)
  void clearCaption() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get body => $_getSZ(5);
  @$pb.TagNumber(6)
  set body($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasBody() => $_has(5);
  @$pb.TagNumber(6)
  void clearBody() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get mediaJson => $_getSZ(6);
  @$pb.TagNumber(7)
  set mediaJson($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasMediaJson() => $_has(6);
  @$pb.TagNumber(7)
  void clearMediaJson() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.bool get onStorefront => $_getBF(7);
  @$pb.TagNumber(8)
  set onStorefront($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasOnStorefront() => $_has(7);
  @$pb.TagNumber(8)
  void clearOnStorefront() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get thumb => $_getSZ(8);
  @$pb.TagNumber(9)
  set thumb($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasThumb() => $_has(8);
  @$pb.TagNumber(9)
  void clearThumb() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.String get feedKind => $_getSZ(9);
  @$pb.TagNumber(10)
  set feedKind($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasFeedKind() => $_has(9);
  @$pb.TagNumber(10)
  void clearFeedKind() => $_clearField(10);

  @$pb.TagNumber(20)
  $fixnum.Int64 get createdTsMs => $_getI64(10);
  @$pb.TagNumber(20)
  set createdTsMs($fixnum.Int64 value) => $_setInt64(10, value);
  @$pb.TagNumber(20)
  $core.bool hasCreatedTsMs() => $_has(10);
  @$pb.TagNumber(20)
  void clearCreatedTsMs() => $_clearField(20);

  @$pb.TagNumber(21)
  $fixnum.Int64 get updatedTsMs => $_getI64(11);
  @$pb.TagNumber(21)
  set updatedTsMs($fixnum.Int64 value) => $_setInt64(11, value);
  @$pb.TagNumber(21)
  $core.bool hasUpdatedTsMs() => $_has(11);
  @$pb.TagNumber(21)
  void clearUpdatedTsMs() => $_clearField(21);

  @$pb.TagNumber(22)
  $fixnum.Int64 get deletedTsMs => $_getI64(12);
  @$pb.TagNumber(22)
  set deletedTsMs($fixnum.Int64 value) => $_setInt64(12, value);
  @$pb.TagNumber(22)
  $core.bool hasDeletedTsMs() => $_has(12);
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
    $core.bool? isPinned,
    $core.int? sortOrder,
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
    if (isPinned != null) result.isPinned = isPinned;
    if (sortOrder != null) result.sortOrder = sortOrder;
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
    ..aOB(8, _omitFieldNames ? '' : 'isPinned')
    ..aI(9, _omitFieldNames ? '' : 'sortOrder')
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

  @$pb.TagNumber(8)
  $core.bool get isPinned => $_getBF(7);
  @$pb.TagNumber(8)
  set isPinned($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasIsPinned() => $_has(7);
  @$pb.TagNumber(8)
  void clearIsPinned() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.int get sortOrder => $_getIZ(8);
  @$pb.TagNumber(9)
  set sortOrder($core.int value) => $_setSignedInt32(8, value);
  @$pb.TagNumber(9)
  $core.bool hasSortOrder() => $_has(8);
  @$pb.TagNumber(9)
  void clearSortOrder() => $_clearField(9);
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

class ReqSiteConfigPut extends $pb.GeneratedMessage {
  factory ReqSiteConfigPut({
    $fixnum.Int64? siteIid,
    $core.String? capabilitiesJson,
  }) {
    final result = ReqSiteConfigPut._();
    if (siteIid != null) result.siteIid = siteIid;
    if (capabilitiesJson != null) result.capabilitiesJson = capabilitiesJson;
    return result;
  }

  ReqSiteConfigPut._();

  factory ReqSiteConfigPut.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSiteConfigPut()..mergeFromBuffer(data, registry);
  factory ReqSiteConfigPut.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSiteConfigPut()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqSiteConfigPut',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqSiteConfigPut.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'siteIid')
    ..aOS(2, _omitFieldNames ? '' : 'capabilitiesJson')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSiteConfigPut clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSiteConfigPut copyWith(void Function(ReqSiteConfigPut) updates) =>
      super.copyWith((message) => updates(message as ReqSiteConfigPut))
          as ReqSiteConfigPut;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqSiteConfigPut() / ReqSiteConfigPut.new instead')
  static ReqSiteConfigPut create() => ReqSiteConfigPut._();
  static $pb.GeneratedMessage $_createMessage() => ReqSiteConfigPut._();
  @$core.override
  ReqSiteConfigPut createEmptyInstance() => ReqSiteConfigPut._();
  @$core.pragma('dart2js:noInline')
  static ReqSiteConfigPut getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqSiteConfigPut>(
          ReqSiteConfigPut.$_createMessage);
  static ReqSiteConfigPut? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get siteIid => $_getI64(0);
  @$pb.TagNumber(1)
  set siteIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSiteIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearSiteIid() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get capabilitiesJson => $_getSZ(1);
  @$pb.TagNumber(2)
  set capabilitiesJson($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCapabilitiesJson() => $_has(1);
  @$pb.TagNumber(2)
  void clearCapabilitiesJson() => $_clearField(2);
}

class ResSiteConfigPut extends $pb.GeneratedMessage {
  factory ResSiteConfigPut({
    SiteConfig? config,
  }) {
    final result = ResSiteConfigPut._();
    if (config != null) result.config = config;
    return result;
  }

  ResSiteConfigPut._();

  factory ResSiteConfigPut.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSiteConfigPut()..mergeFromBuffer(data, registry);
  factory ResSiteConfigPut.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSiteConfigPut()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResSiteConfigPut',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResSiteConfigPut.$_createMessage)
    ..aOM<SiteConfig>(1, _omitFieldNames ? '' : 'config',
        subBuilder: SiteConfig.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSiteConfigPut clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSiteConfigPut copyWith(void Function(ResSiteConfigPut) updates) =>
      super.copyWith((message) => updates(message as ResSiteConfigPut))
          as ResSiteConfigPut;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResSiteConfigPut() / ResSiteConfigPut.new instead')
  static ResSiteConfigPut create() => ResSiteConfigPut._();
  static $pb.GeneratedMessage $_createMessage() => ResSiteConfigPut._();
  @$core.override
  ResSiteConfigPut createEmptyInstance() => ResSiteConfigPut._();
  @$core.pragma('dart2js:noInline')
  static ResSiteConfigPut getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResSiteConfigPut>(
          ResSiteConfigPut.$_createMessage);
  static ResSiteConfigPut? _defaultInstance;

  @$pb.TagNumber(1)
  SiteConfig get config => $_getN(0);
  @$pb.TagNumber(1)
  set config(SiteConfig value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasConfig() => $_has(0);
  @$pb.TagNumber(1)
  void clearConfig() => $_clearField(1);
  @$pb.TagNumber(1)
  SiteConfig ensureConfig() => $_ensure(0);
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

class ReqSiteLinkList extends $pb.GeneratedMessage {
  factory ReqSiteLinkList({
    $fixnum.Int64? siteIid,
  }) {
    final result = ReqSiteLinkList._();
    if (siteIid != null) result.siteIid = siteIid;
    return result;
  }

  ReqSiteLinkList._();

  factory ReqSiteLinkList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSiteLinkList()..mergeFromBuffer(data, registry);
  factory ReqSiteLinkList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSiteLinkList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqSiteLinkList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqSiteLinkList.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'siteIid')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSiteLinkList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSiteLinkList copyWith(void Function(ReqSiteLinkList) updates) =>
      super.copyWith((message) => updates(message as ReqSiteLinkList))
          as ReqSiteLinkList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqSiteLinkList() / ReqSiteLinkList.new instead')
  static ReqSiteLinkList create() => ReqSiteLinkList._();
  static $pb.GeneratedMessage $_createMessage() => ReqSiteLinkList._();
  @$core.override
  ReqSiteLinkList createEmptyInstance() => ReqSiteLinkList._();
  @$core.pragma('dart2js:noInline')
  static ReqSiteLinkList getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqSiteLinkList>(
          ReqSiteLinkList.$_createMessage);
  static ReqSiteLinkList? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get siteIid => $_getI64(0);
  @$pb.TagNumber(1)
  set siteIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSiteIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearSiteIid() => $_clearField(1);
}

class ResSiteLinkList extends $pb.GeneratedMessage {
  factory ResSiteLinkList({
    $core.Iterable<SiteLink>? links,
  }) {
    final result = ResSiteLinkList._();
    if (links != null) result.links.addAll(links);
    return result;
  }

  ResSiteLinkList._();

  factory ResSiteLinkList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSiteLinkList()..mergeFromBuffer(data, registry);
  factory ResSiteLinkList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSiteLinkList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResSiteLinkList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResSiteLinkList.$_createMessage)
    ..pPM<SiteLink>(1, _omitFieldNames ? '' : 'links',
        subBuilder: SiteLink.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSiteLinkList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSiteLinkList copyWith(void Function(ResSiteLinkList) updates) =>
      super.copyWith((message) => updates(message as ResSiteLinkList))
          as ResSiteLinkList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResSiteLinkList() / ResSiteLinkList.new instead')
  static ResSiteLinkList create() => ResSiteLinkList._();
  static $pb.GeneratedMessage $_createMessage() => ResSiteLinkList._();
  @$core.override
  ResSiteLinkList createEmptyInstance() => ResSiteLinkList._();
  @$core.pragma('dart2js:noInline')
  static ResSiteLinkList getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResSiteLinkList>(
          ResSiteLinkList.$_createMessage);
  static ResSiteLinkList? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<SiteLink> get links => $_getList(0);
}

class ReqSiteLinkPut extends $pb.GeneratedMessage {
  factory ReqSiteLinkPut({
    $fixnum.Int64? siteIid,
    SiteLink? link,
  }) {
    final result = ReqSiteLinkPut._();
    if (siteIid != null) result.siteIid = siteIid;
    if (link != null) result.link = link;
    return result;
  }

  ReqSiteLinkPut._();

  factory ReqSiteLinkPut.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSiteLinkPut()..mergeFromBuffer(data, registry);
  factory ReqSiteLinkPut.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSiteLinkPut()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqSiteLinkPut',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqSiteLinkPut.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'siteIid')
    ..aOM<SiteLink>(2, _omitFieldNames ? '' : 'link',
        subBuilder: SiteLink.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSiteLinkPut clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSiteLinkPut copyWith(void Function(ReqSiteLinkPut) updates) =>
      super.copyWith((message) => updates(message as ReqSiteLinkPut))
          as ReqSiteLinkPut;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqSiteLinkPut() / ReqSiteLinkPut.new instead')
  static ReqSiteLinkPut create() => ReqSiteLinkPut._();
  static $pb.GeneratedMessage $_createMessage() => ReqSiteLinkPut._();
  @$core.override
  ReqSiteLinkPut createEmptyInstance() => ReqSiteLinkPut._();
  @$core.pragma('dart2js:noInline')
  static ReqSiteLinkPut getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqSiteLinkPut>(
          ReqSiteLinkPut.$_createMessage);
  static ReqSiteLinkPut? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get siteIid => $_getI64(0);
  @$pb.TagNumber(1)
  set siteIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSiteIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearSiteIid() => $_clearField(1);

  @$pb.TagNumber(2)
  SiteLink get link => $_getN(1);
  @$pb.TagNumber(2)
  set link(SiteLink value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasLink() => $_has(1);
  @$pb.TagNumber(2)
  void clearLink() => $_clearField(2);
  @$pb.TagNumber(2)
  SiteLink ensureLink() => $_ensure(1);
}

class ResSiteLinkPut extends $pb.GeneratedMessage {
  factory ResSiteLinkPut({
    $fixnum.Int64? linkId,
  }) {
    final result = ResSiteLinkPut._();
    if (linkId != null) result.linkId = linkId;
    return result;
  }

  ResSiteLinkPut._();

  factory ResSiteLinkPut.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSiteLinkPut()..mergeFromBuffer(data, registry);
  factory ResSiteLinkPut.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSiteLinkPut()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResSiteLinkPut',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResSiteLinkPut.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'linkId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSiteLinkPut clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSiteLinkPut copyWith(void Function(ResSiteLinkPut) updates) =>
      super.copyWith((message) => updates(message as ResSiteLinkPut))
          as ResSiteLinkPut;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResSiteLinkPut() / ResSiteLinkPut.new instead')
  static ResSiteLinkPut create() => ResSiteLinkPut._();
  static $pb.GeneratedMessage $_createMessage() => ResSiteLinkPut._();
  @$core.override
  ResSiteLinkPut createEmptyInstance() => ResSiteLinkPut._();
  @$core.pragma('dart2js:noInline')
  static ResSiteLinkPut getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResSiteLinkPut>(
          ResSiteLinkPut.$_createMessage);
  static ResSiteLinkPut? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get linkId => $_getI64(0);
  @$pb.TagNumber(1)
  set linkId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLinkId() => $_has(0);
  @$pb.TagNumber(1)
  void clearLinkId() => $_clearField(1);
}

class ReqSiteLinkDelete extends $pb.GeneratedMessage {
  factory ReqSiteLinkDelete({
    $fixnum.Int64? siteIid,
    $fixnum.Int64? linkId,
  }) {
    final result = ReqSiteLinkDelete._();
    if (siteIid != null) result.siteIid = siteIid;
    if (linkId != null) result.linkId = linkId;
    return result;
  }

  ReqSiteLinkDelete._();

  factory ReqSiteLinkDelete.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSiteLinkDelete()..mergeFromBuffer(data, registry);
  factory ReqSiteLinkDelete.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSiteLinkDelete()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqSiteLinkDelete',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqSiteLinkDelete.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'siteIid')
    ..aInt64(2, _omitFieldNames ? '' : 'linkId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSiteLinkDelete clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSiteLinkDelete copyWith(void Function(ReqSiteLinkDelete) updates) =>
      super.copyWith((message) => updates(message as ReqSiteLinkDelete))
          as ReqSiteLinkDelete;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqSiteLinkDelete() / ReqSiteLinkDelete.new instead')
  static ReqSiteLinkDelete create() => ReqSiteLinkDelete._();
  static $pb.GeneratedMessage $_createMessage() => ReqSiteLinkDelete._();
  @$core.override
  ReqSiteLinkDelete createEmptyInstance() => ReqSiteLinkDelete._();
  @$core.pragma('dart2js:noInline')
  static ReqSiteLinkDelete getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqSiteLinkDelete>(
          ReqSiteLinkDelete.$_createMessage);
  static ReqSiteLinkDelete? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get siteIid => $_getI64(0);
  @$pb.TagNumber(1)
  set siteIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSiteIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearSiteIid() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get linkId => $_getI64(1);
  @$pb.TagNumber(2)
  set linkId($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLinkId() => $_has(1);
  @$pb.TagNumber(2)
  void clearLinkId() => $_clearField(2);
}

class ResSiteLinkDelete extends $pb.GeneratedMessage {
  factory ResSiteLinkDelete({
    $fixnum.Int64? linkId,
    $core.bool? ok,
  }) {
    final result = ResSiteLinkDelete._();
    if (linkId != null) result.linkId = linkId;
    if (ok != null) result.ok = ok;
    return result;
  }

  ResSiteLinkDelete._();

  factory ResSiteLinkDelete.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSiteLinkDelete()..mergeFromBuffer(data, registry);
  factory ResSiteLinkDelete.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSiteLinkDelete()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResSiteLinkDelete',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResSiteLinkDelete.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'linkId')
    ..aOB(2, _omitFieldNames ? '' : 'ok')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSiteLinkDelete clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSiteLinkDelete copyWith(void Function(ResSiteLinkDelete) updates) =>
      super.copyWith((message) => updates(message as ResSiteLinkDelete))
          as ResSiteLinkDelete;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResSiteLinkDelete() / ResSiteLinkDelete.new instead')
  static ResSiteLinkDelete create() => ResSiteLinkDelete._();
  static $pb.GeneratedMessage $_createMessage() => ResSiteLinkDelete._();
  @$core.override
  ResSiteLinkDelete createEmptyInstance() => ResSiteLinkDelete._();
  @$core.pragma('dart2js:noInline')
  static ResSiteLinkDelete getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResSiteLinkDelete>(
          ResSiteLinkDelete.$_createMessage);
  static ResSiteLinkDelete? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get linkId => $_getI64(0);
  @$pb.TagNumber(1)
  set linkId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLinkId() => $_has(0);
  @$pb.TagNumber(1)
  void clearLinkId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get ok => $_getBF(1);
  @$pb.TagNumber(2)
  set ok($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOk() => $_has(1);
  @$pb.TagNumber(2)
  void clearOk() => $_clearField(2);
}

class ReqSitePostList extends $pb.GeneratedMessage {
  factory ReqSitePostList({
    $fixnum.Int64? siteIid,
  }) {
    final result = ReqSitePostList._();
    if (siteIid != null) result.siteIid = siteIid;
    return result;
  }

  ReqSitePostList._();

  factory ReqSitePostList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSitePostList()..mergeFromBuffer(data, registry);
  factory ReqSitePostList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSitePostList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqSitePostList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqSitePostList.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'siteIid')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSitePostList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSitePostList copyWith(void Function(ReqSitePostList) updates) =>
      super.copyWith((message) => updates(message as ReqSitePostList))
          as ReqSitePostList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqSitePostList() / ReqSitePostList.new instead')
  static ReqSitePostList create() => ReqSitePostList._();
  static $pb.GeneratedMessage $_createMessage() => ReqSitePostList._();
  @$core.override
  ReqSitePostList createEmptyInstance() => ReqSitePostList._();
  @$core.pragma('dart2js:noInline')
  static ReqSitePostList getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqSitePostList>(
          ReqSitePostList.$_createMessage);
  static ReqSitePostList? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get siteIid => $_getI64(0);
  @$pb.TagNumber(1)
  set siteIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSiteIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearSiteIid() => $_clearField(1);
}

class ResSitePostList extends $pb.GeneratedMessage {
  factory ResSitePostList({
    $core.Iterable<SitePost>? posts,
  }) {
    final result = ResSitePostList._();
    if (posts != null) result.posts.addAll(posts);
    return result;
  }

  ResSitePostList._();

  factory ResSitePostList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSitePostList()..mergeFromBuffer(data, registry);
  factory ResSitePostList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSitePostList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResSitePostList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResSitePostList.$_createMessage)
    ..pPM<SitePost>(1, _omitFieldNames ? '' : 'posts',
        subBuilder: SitePost.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSitePostList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSitePostList copyWith(void Function(ResSitePostList) updates) =>
      super.copyWith((message) => updates(message as ResSitePostList))
          as ResSitePostList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResSitePostList() / ResSitePostList.new instead')
  static ResSitePostList create() => ResSitePostList._();
  static $pb.GeneratedMessage $_createMessage() => ResSitePostList._();
  @$core.override
  ResSitePostList createEmptyInstance() => ResSitePostList._();
  @$core.pragma('dart2js:noInline')
  static ResSitePostList getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResSitePostList>(
          ResSitePostList.$_createMessage);
  static ResSitePostList? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<SitePost> get posts => $_getList(0);
}

class ReqSitePostPut extends $pb.GeneratedMessage {
  factory ReqSitePostPut({
    $fixnum.Int64? siteIid,
    SitePost? post,
  }) {
    final result = ReqSitePostPut._();
    if (siteIid != null) result.siteIid = siteIid;
    if (post != null) result.post = post;
    return result;
  }

  ReqSitePostPut._();

  factory ReqSitePostPut.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSitePostPut()..mergeFromBuffer(data, registry);
  factory ReqSitePostPut.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSitePostPut()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqSitePostPut',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqSitePostPut.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'siteIid')
    ..aOM<SitePost>(2, _omitFieldNames ? '' : 'post',
        subBuilder: SitePost.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSitePostPut clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSitePostPut copyWith(void Function(ReqSitePostPut) updates) =>
      super.copyWith((message) => updates(message as ReqSitePostPut))
          as ReqSitePostPut;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqSitePostPut() / ReqSitePostPut.new instead')
  static ReqSitePostPut create() => ReqSitePostPut._();
  static $pb.GeneratedMessage $_createMessage() => ReqSitePostPut._();
  @$core.override
  ReqSitePostPut createEmptyInstance() => ReqSitePostPut._();
  @$core.pragma('dart2js:noInline')
  static ReqSitePostPut getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqSitePostPut>(
          ReqSitePostPut.$_createMessage);
  static ReqSitePostPut? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get siteIid => $_getI64(0);
  @$pb.TagNumber(1)
  set siteIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSiteIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearSiteIid() => $_clearField(1);

  @$pb.TagNumber(2)
  SitePost get post => $_getN(1);
  @$pb.TagNumber(2)
  set post(SitePost value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasPost() => $_has(1);
  @$pb.TagNumber(2)
  void clearPost() => $_clearField(2);
  @$pb.TagNumber(2)
  SitePost ensurePost() => $_ensure(1);
}

class ResSitePostPut extends $pb.GeneratedMessage {
  factory ResSitePostPut({
    $fixnum.Int64? postId,
  }) {
    final result = ResSitePostPut._();
    if (postId != null) result.postId = postId;
    return result;
  }

  ResSitePostPut._();

  factory ResSitePostPut.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSitePostPut()..mergeFromBuffer(data, registry);
  factory ResSitePostPut.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSitePostPut()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResSitePostPut',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResSitePostPut.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'postId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSitePostPut clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSitePostPut copyWith(void Function(ResSitePostPut) updates) =>
      super.copyWith((message) => updates(message as ResSitePostPut))
          as ResSitePostPut;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResSitePostPut() / ResSitePostPut.new instead')
  static ResSitePostPut create() => ResSitePostPut._();
  static $pb.GeneratedMessage $_createMessage() => ResSitePostPut._();
  @$core.override
  ResSitePostPut createEmptyInstance() => ResSitePostPut._();
  @$core.pragma('dart2js:noInline')
  static ResSitePostPut getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResSitePostPut>(
          ResSitePostPut.$_createMessage);
  static ResSitePostPut? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get postId => $_getI64(0);
  @$pb.TagNumber(1)
  set postId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPostId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPostId() => $_clearField(1);
}

class ReqSitePostDelete extends $pb.GeneratedMessage {
  factory ReqSitePostDelete({
    $fixnum.Int64? siteIid,
    $fixnum.Int64? postId,
  }) {
    final result = ReqSitePostDelete._();
    if (siteIid != null) result.siteIid = siteIid;
    if (postId != null) result.postId = postId;
    return result;
  }

  ReqSitePostDelete._();

  factory ReqSitePostDelete.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSitePostDelete()..mergeFromBuffer(data, registry);
  factory ReqSitePostDelete.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSitePostDelete()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqSitePostDelete',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqSitePostDelete.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'siteIid')
    ..aInt64(2, _omitFieldNames ? '' : 'postId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSitePostDelete clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSitePostDelete copyWith(void Function(ReqSitePostDelete) updates) =>
      super.copyWith((message) => updates(message as ReqSitePostDelete))
          as ReqSitePostDelete;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqSitePostDelete() / ReqSitePostDelete.new instead')
  static ReqSitePostDelete create() => ReqSitePostDelete._();
  static $pb.GeneratedMessage $_createMessage() => ReqSitePostDelete._();
  @$core.override
  ReqSitePostDelete createEmptyInstance() => ReqSitePostDelete._();
  @$core.pragma('dart2js:noInline')
  static ReqSitePostDelete getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqSitePostDelete>(
          ReqSitePostDelete.$_createMessage);
  static ReqSitePostDelete? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get siteIid => $_getI64(0);
  @$pb.TagNumber(1)
  set siteIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSiteIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearSiteIid() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get postId => $_getI64(1);
  @$pb.TagNumber(2)
  set postId($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPostId() => $_has(1);
  @$pb.TagNumber(2)
  void clearPostId() => $_clearField(2);
}

class ResSitePostDelete extends $pb.GeneratedMessage {
  factory ResSitePostDelete({
    $fixnum.Int64? postId,
    $core.bool? ok,
  }) {
    final result = ResSitePostDelete._();
    if (postId != null) result.postId = postId;
    if (ok != null) result.ok = ok;
    return result;
  }

  ResSitePostDelete._();

  factory ResSitePostDelete.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSitePostDelete()..mergeFromBuffer(data, registry);
  factory ResSitePostDelete.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSitePostDelete()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResSitePostDelete',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResSitePostDelete.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'postId')
    ..aOB(2, _omitFieldNames ? '' : 'ok')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSitePostDelete clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSitePostDelete copyWith(void Function(ResSitePostDelete) updates) =>
      super.copyWith((message) => updates(message as ResSitePostDelete))
          as ResSitePostDelete;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResSitePostDelete() / ResSitePostDelete.new instead')
  static ResSitePostDelete create() => ResSitePostDelete._();
  static $pb.GeneratedMessage $_createMessage() => ResSitePostDelete._();
  @$core.override
  ResSitePostDelete createEmptyInstance() => ResSitePostDelete._();
  @$core.pragma('dart2js:noInline')
  static ResSitePostDelete getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResSitePostDelete>(
          ResSitePostDelete.$_createMessage);
  static ResSitePostDelete? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get postId => $_getI64(0);
  @$pb.TagNumber(1)
  set postId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPostId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPostId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get ok => $_getBF(1);
  @$pb.TagNumber(2)
  set ok($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOk() => $_has(1);
  @$pb.TagNumber(2)
  void clearOk() => $_clearField(2);
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

class ReqSiteDomainList extends $pb.GeneratedMessage {
  factory ReqSiteDomainList({
    $fixnum.Int64? siteIid,
  }) {
    final result = ReqSiteDomainList._();
    if (siteIid != null) result.siteIid = siteIid;
    return result;
  }

  ReqSiteDomainList._();

  factory ReqSiteDomainList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSiteDomainList()..mergeFromBuffer(data, registry);
  factory ReqSiteDomainList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSiteDomainList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqSiteDomainList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqSiteDomainList.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'siteIid')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSiteDomainList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSiteDomainList copyWith(void Function(ReqSiteDomainList) updates) =>
      super.copyWith((message) => updates(message as ReqSiteDomainList))
          as ReqSiteDomainList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqSiteDomainList() / ReqSiteDomainList.new instead')
  static ReqSiteDomainList create() => ReqSiteDomainList._();
  static $pb.GeneratedMessage $_createMessage() => ReqSiteDomainList._();
  @$core.override
  ReqSiteDomainList createEmptyInstance() => ReqSiteDomainList._();
  @$core.pragma('dart2js:noInline')
  static ReqSiteDomainList getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqSiteDomainList>(
          ReqSiteDomainList.$_createMessage);
  static ReqSiteDomainList? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get siteIid => $_getI64(0);
  @$pb.TagNumber(1)
  set siteIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSiteIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearSiteIid() => $_clearField(1);
}

class ResSiteDomainList extends $pb.GeneratedMessage {
  factory ResSiteDomainList({
    $core.Iterable<SiteDomain>? domains,
  }) {
    final result = ResSiteDomainList._();
    if (domains != null) result.domains.addAll(domains);
    return result;
  }

  ResSiteDomainList._();

  factory ResSiteDomainList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSiteDomainList()..mergeFromBuffer(data, registry);
  factory ResSiteDomainList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSiteDomainList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResSiteDomainList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResSiteDomainList.$_createMessage)
    ..pPM<SiteDomain>(1, _omitFieldNames ? '' : 'domains',
        subBuilder: SiteDomain.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSiteDomainList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSiteDomainList copyWith(void Function(ResSiteDomainList) updates) =>
      super.copyWith((message) => updates(message as ResSiteDomainList))
          as ResSiteDomainList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResSiteDomainList() / ResSiteDomainList.new instead')
  static ResSiteDomainList create() => ResSiteDomainList._();
  static $pb.GeneratedMessage $_createMessage() => ResSiteDomainList._();
  @$core.override
  ResSiteDomainList createEmptyInstance() => ResSiteDomainList._();
  @$core.pragma('dart2js:noInline')
  static ResSiteDomainList getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResSiteDomainList>(
          ResSiteDomainList.$_createMessage);
  static ResSiteDomainList? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<SiteDomain> get domains => $_getList(0);
}

class ReqSiteDomainPut extends $pb.GeneratedMessage {
  factory ReqSiteDomainPut({
    $fixnum.Int64? siteIid,
    SiteDomain? domain,
  }) {
    final result = ReqSiteDomainPut._();
    if (siteIid != null) result.siteIid = siteIid;
    if (domain != null) result.domain = domain;
    return result;
  }

  ReqSiteDomainPut._();

  factory ReqSiteDomainPut.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSiteDomainPut()..mergeFromBuffer(data, registry);
  factory ReqSiteDomainPut.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSiteDomainPut()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqSiteDomainPut',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqSiteDomainPut.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'siteIid')
    ..aOM<SiteDomain>(2, _omitFieldNames ? '' : 'domain',
        subBuilder: SiteDomain.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSiteDomainPut clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSiteDomainPut copyWith(void Function(ReqSiteDomainPut) updates) =>
      super.copyWith((message) => updates(message as ReqSiteDomainPut))
          as ReqSiteDomainPut;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqSiteDomainPut() / ReqSiteDomainPut.new instead')
  static ReqSiteDomainPut create() => ReqSiteDomainPut._();
  static $pb.GeneratedMessage $_createMessage() => ReqSiteDomainPut._();
  @$core.override
  ReqSiteDomainPut createEmptyInstance() => ReqSiteDomainPut._();
  @$core.pragma('dart2js:noInline')
  static ReqSiteDomainPut getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqSiteDomainPut>(
          ReqSiteDomainPut.$_createMessage);
  static ReqSiteDomainPut? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get siteIid => $_getI64(0);
  @$pb.TagNumber(1)
  set siteIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSiteIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearSiteIid() => $_clearField(1);

  @$pb.TagNumber(2)
  SiteDomain get domain => $_getN(1);
  @$pb.TagNumber(2)
  set domain(SiteDomain value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasDomain() => $_has(1);
  @$pb.TagNumber(2)
  void clearDomain() => $_clearField(2);
  @$pb.TagNumber(2)
  SiteDomain ensureDomain() => $_ensure(1);
}

class ResSiteDomainPut extends $pb.GeneratedMessage {
  factory ResSiteDomainPut({
    $fixnum.Int64? id,
  }) {
    final result = ResSiteDomainPut._();
    if (id != null) result.id = id;
    return result;
  }

  ResSiteDomainPut._();

  factory ResSiteDomainPut.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSiteDomainPut()..mergeFromBuffer(data, registry);
  factory ResSiteDomainPut.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSiteDomainPut()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResSiteDomainPut',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResSiteDomainPut.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSiteDomainPut clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSiteDomainPut copyWith(void Function(ResSiteDomainPut) updates) =>
      super.copyWith((message) => updates(message as ResSiteDomainPut))
          as ResSiteDomainPut;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResSiteDomainPut() / ResSiteDomainPut.new instead')
  static ResSiteDomainPut create() => ResSiteDomainPut._();
  static $pb.GeneratedMessage $_createMessage() => ResSiteDomainPut._();
  @$core.override
  ResSiteDomainPut createEmptyInstance() => ResSiteDomainPut._();
  @$core.pragma('dart2js:noInline')
  static ResSiteDomainPut getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResSiteDomainPut>(
          ResSiteDomainPut.$_createMessage);
  static ResSiteDomainPut? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);
}

class ReqSiteDomainVerify extends $pb.GeneratedMessage {
  factory ReqSiteDomainVerify({
    $fixnum.Int64? siteIid,
    $fixnum.Int64? domainId,
    $core.bool? forceTls,
  }) {
    final result = ReqSiteDomainVerify._();
    if (siteIid != null) result.siteIid = siteIid;
    if (domainId != null) result.domainId = domainId;
    if (forceTls != null) result.forceTls = forceTls;
    return result;
  }

  ReqSiteDomainVerify._();

  factory ReqSiteDomainVerify.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSiteDomainVerify()..mergeFromBuffer(data, registry);
  factory ReqSiteDomainVerify.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSiteDomainVerify()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqSiteDomainVerify',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqSiteDomainVerify.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'siteIid')
    ..aInt64(2, _omitFieldNames ? '' : 'domainId')
    ..aOB(3, _omitFieldNames ? '' : 'forceTls')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSiteDomainVerify clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSiteDomainVerify copyWith(void Function(ReqSiteDomainVerify) updates) =>
      super.copyWith((message) => updates(message as ReqSiteDomainVerify))
          as ReqSiteDomainVerify;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use ReqSiteDomainVerify() / ReqSiteDomainVerify.new instead')
  static ReqSiteDomainVerify create() => ReqSiteDomainVerify._();
  static $pb.GeneratedMessage $_createMessage() => ReqSiteDomainVerify._();
  @$core.override
  ReqSiteDomainVerify createEmptyInstance() => ReqSiteDomainVerify._();
  @$core.pragma('dart2js:noInline')
  static ReqSiteDomainVerify getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqSiteDomainVerify>(
          ReqSiteDomainVerify.$_createMessage);
  static ReqSiteDomainVerify? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get siteIid => $_getI64(0);
  @$pb.TagNumber(1)
  set siteIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSiteIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearSiteIid() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get domainId => $_getI64(1);
  @$pb.TagNumber(2)
  set domainId($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDomainId() => $_has(1);
  @$pb.TagNumber(2)
  void clearDomainId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get forceTls => $_getBF(2);
  @$pb.TagNumber(3)
  set forceTls($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasForceTls() => $_has(2);
  @$pb.TagNumber(3)
  void clearForceTls() => $_clearField(3);
}

class ResSiteDomainVerify extends $pb.GeneratedMessage {
  factory ResSiteDomainVerify({
    $core.bool? dnsVerified,
    $core.String? error,
    $core.String? tlsStatus,
  }) {
    final result = ResSiteDomainVerify._();
    if (dnsVerified != null) result.dnsVerified = dnsVerified;
    if (error != null) result.error = error;
    if (tlsStatus != null) result.tlsStatus = tlsStatus;
    return result;
  }

  ResSiteDomainVerify._();

  factory ResSiteDomainVerify.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSiteDomainVerify()..mergeFromBuffer(data, registry);
  factory ResSiteDomainVerify.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSiteDomainVerify()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResSiteDomainVerify',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResSiteDomainVerify.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'dnsVerified')
    ..aOS(2, _omitFieldNames ? '' : 'error')
    ..aOS(3, _omitFieldNames ? '' : 'tlsStatus')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSiteDomainVerify clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSiteDomainVerify copyWith(void Function(ResSiteDomainVerify) updates) =>
      super.copyWith((message) => updates(message as ResSiteDomainVerify))
          as ResSiteDomainVerify;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use ResSiteDomainVerify() / ResSiteDomainVerify.new instead')
  static ResSiteDomainVerify create() => ResSiteDomainVerify._();
  static $pb.GeneratedMessage $_createMessage() => ResSiteDomainVerify._();
  @$core.override
  ResSiteDomainVerify createEmptyInstance() => ResSiteDomainVerify._();
  @$core.pragma('dart2js:noInline')
  static ResSiteDomainVerify getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResSiteDomainVerify>(
          ResSiteDomainVerify.$_createMessage);
  static ResSiteDomainVerify? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get dnsVerified => $_getBF(0);
  @$pb.TagNumber(1)
  set dnsVerified($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDnsVerified() => $_has(0);
  @$pb.TagNumber(1)
  void clearDnsVerified() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get error => $_getSZ(1);
  @$pb.TagNumber(2)
  set error($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get tlsStatus => $_getSZ(2);
  @$pb.TagNumber(3)
  set tlsStatus($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTlsStatus() => $_has(2);
  @$pb.TagNumber(3)
  void clearTlsStatus() => $_clearField(3);
}

class ReqSitePreviewToken extends $pb.GeneratedMessage {
  factory ReqSitePreviewToken({
    $fixnum.Int64? siteIid,
    $core.int? ttlSecs,
  }) {
    final result = ReqSitePreviewToken._();
    if (siteIid != null) result.siteIid = siteIid;
    if (ttlSecs != null) result.ttlSecs = ttlSecs;
    return result;
  }

  ReqSitePreviewToken._();

  factory ReqSitePreviewToken.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSitePreviewToken()..mergeFromBuffer(data, registry);
  factory ReqSitePreviewToken.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSitePreviewToken()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqSitePreviewToken',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqSitePreviewToken.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'siteIid')
    ..aI(2, _omitFieldNames ? '' : 'ttlSecs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSitePreviewToken clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSitePreviewToken copyWith(void Function(ReqSitePreviewToken) updates) =>
      super.copyWith((message) => updates(message as ReqSitePreviewToken))
          as ReqSitePreviewToken;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use ReqSitePreviewToken() / ReqSitePreviewToken.new instead')
  static ReqSitePreviewToken create() => ReqSitePreviewToken._();
  static $pb.GeneratedMessage $_createMessage() => ReqSitePreviewToken._();
  @$core.override
  ReqSitePreviewToken createEmptyInstance() => ReqSitePreviewToken._();
  @$core.pragma('dart2js:noInline')
  static ReqSitePreviewToken getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqSitePreviewToken>(
          ReqSitePreviewToken.$_createMessage);
  static ReqSitePreviewToken? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get siteIid => $_getI64(0);
  @$pb.TagNumber(1)
  set siteIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSiteIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearSiteIid() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get ttlSecs => $_getIZ(1);
  @$pb.TagNumber(2)
  set ttlSecs($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTtlSecs() => $_has(1);
  @$pb.TagNumber(2)
  void clearTtlSecs() => $_clearField(2);
}

class ResSitePreviewToken extends $pb.GeneratedMessage {
  factory ResSitePreviewToken({
    $core.String? token,
    $fixnum.Int64? expiresTsMs,
  }) {
    final result = ResSitePreviewToken._();
    if (token != null) result.token = token;
    if (expiresTsMs != null) result.expiresTsMs = expiresTsMs;
    return result;
  }

  ResSitePreviewToken._();

  factory ResSitePreviewToken.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSitePreviewToken()..mergeFromBuffer(data, registry);
  factory ResSitePreviewToken.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSitePreviewToken()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResSitePreviewToken',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResSitePreviewToken.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'token')
    ..aInt64(2, _omitFieldNames ? '' : 'expiresTsMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSitePreviewToken clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSitePreviewToken copyWith(void Function(ResSitePreviewToken) updates) =>
      super.copyWith((message) => updates(message as ResSitePreviewToken))
          as ResSitePreviewToken;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use ResSitePreviewToken() / ResSitePreviewToken.new instead')
  static ResSitePreviewToken create() => ResSitePreviewToken._();
  static $pb.GeneratedMessage $_createMessage() => ResSitePreviewToken._();
  @$core.override
  ResSitePreviewToken createEmptyInstance() => ResSitePreviewToken._();
  @$core.pragma('dart2js:noInline')
  static ResSitePreviewToken getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResSitePreviewToken>(
          ResSitePreviewToken.$_createMessage);
  static ResSitePreviewToken? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get token => $_getSZ(0);
  @$pb.TagNumber(1)
  set token($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasToken() => $_has(0);
  @$pb.TagNumber(1)
  void clearToken() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get expiresTsMs => $_getI64(1);
  @$pb.TagNumber(2)
  set expiresTsMs($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasExpiresTsMs() => $_has(1);
  @$pb.TagNumber(2)
  void clearExpiresTsMs() => $_clearField(2);
}

class ReqSiteHandlePut extends $pb.GeneratedMessage {
  factory ReqSiteHandlePut({
    $fixnum.Int64? siteIid,
    $core.String? newAlienId,
  }) {
    final result = ReqSiteHandlePut._();
    if (siteIid != null) result.siteIid = siteIid;
    if (newAlienId != null) result.newAlienId = newAlienId;
    return result;
  }

  ReqSiteHandlePut._();

  factory ReqSiteHandlePut.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSiteHandlePut()..mergeFromBuffer(data, registry);
  factory ReqSiteHandlePut.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSiteHandlePut()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqSiteHandlePut',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqSiteHandlePut.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'siteIid')
    ..aOS(2, _omitFieldNames ? '' : 'newAlienId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSiteHandlePut clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSiteHandlePut copyWith(void Function(ReqSiteHandlePut) updates) =>
      super.copyWith((message) => updates(message as ReqSiteHandlePut))
          as ReqSiteHandlePut;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqSiteHandlePut() / ReqSiteHandlePut.new instead')
  static ReqSiteHandlePut create() => ReqSiteHandlePut._();
  static $pb.GeneratedMessage $_createMessage() => ReqSiteHandlePut._();
  @$core.override
  ReqSiteHandlePut createEmptyInstance() => ReqSiteHandlePut._();
  @$core.pragma('dart2js:noInline')
  static ReqSiteHandlePut getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqSiteHandlePut>(
          ReqSiteHandlePut.$_createMessage);
  static ReqSiteHandlePut? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get siteIid => $_getI64(0);
  @$pb.TagNumber(1)
  set siteIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSiteIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearSiteIid() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get newAlienId => $_getSZ(1);
  @$pb.TagNumber(2)
  set newAlienId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNewAlienId() => $_has(1);
  @$pb.TagNumber(2)
  void clearNewAlienId() => $_clearField(2);
}

class ResSiteHandlePut extends $pb.GeneratedMessage {
  factory ResSiteHandlePut({
    $fixnum.Int64? siteIid,
    $core.String? alienId,
    $core.String? url,
  }) {
    final result = ResSiteHandlePut._();
    if (siteIid != null) result.siteIid = siteIid;
    if (alienId != null) result.alienId = alienId;
    if (url != null) result.url = url;
    return result;
  }

  ResSiteHandlePut._();

  factory ResSiteHandlePut.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSiteHandlePut()..mergeFromBuffer(data, registry);
  factory ResSiteHandlePut.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSiteHandlePut()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResSiteHandlePut',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResSiteHandlePut.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'siteIid')
    ..aOS(2, _omitFieldNames ? '' : 'alienId')
    ..aOS(3, _omitFieldNames ? '' : 'url')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSiteHandlePut clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSiteHandlePut copyWith(void Function(ResSiteHandlePut) updates) =>
      super.copyWith((message) => updates(message as ResSiteHandlePut))
          as ResSiteHandlePut;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResSiteHandlePut() / ResSiteHandlePut.new instead')
  static ResSiteHandlePut create() => ResSiteHandlePut._();
  static $pb.GeneratedMessage $_createMessage() => ResSiteHandlePut._();
  @$core.override
  ResSiteHandlePut createEmptyInstance() => ResSiteHandlePut._();
  @$core.pragma('dart2js:noInline')
  static ResSiteHandlePut getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResSiteHandlePut>(
          ResSiteHandlePut.$_createMessage);
  static ResSiteHandlePut? _defaultInstance;

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
  $core.String get url => $_getSZ(2);
  @$pb.TagNumber(3)
  set url($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasUrl() => $_has(2);
  @$pb.TagNumber(3)
  void clearUrl() => $_clearField(3);
}

class ReqSiteBootGet extends $pb.GeneratedMessage {
  factory ReqSiteBootGet({
    $fixnum.Int64? siteIid,
    SiteBootMode? mode,
  }) {
    final result = ReqSiteBootGet._();
    if (siteIid != null) result.siteIid = siteIid;
    if (mode != null) result.mode = mode;
    return result;
  }

  ReqSiteBootGet._();

  factory ReqSiteBootGet.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSiteBootGet()..mergeFromBuffer(data, registry);
  factory ReqSiteBootGet.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSiteBootGet()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqSiteBootGet',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqSiteBootGet.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'siteIid')
    ..aE<SiteBootMode>(2, _omitFieldNames ? '' : 'mode',
        enumValues: SiteBootMode.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSiteBootGet clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSiteBootGet copyWith(void Function(ReqSiteBootGet) updates) =>
      super.copyWith((message) => updates(message as ReqSiteBootGet))
          as ReqSiteBootGet;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqSiteBootGet() / ReqSiteBootGet.new instead')
  static ReqSiteBootGet create() => ReqSiteBootGet._();
  static $pb.GeneratedMessage $_createMessage() => ReqSiteBootGet._();
  @$core.override
  ReqSiteBootGet createEmptyInstance() => ReqSiteBootGet._();
  @$core.pragma('dart2js:noInline')
  static ReqSiteBootGet getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqSiteBootGet>(
          ReqSiteBootGet.$_createMessage);
  static ReqSiteBootGet? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get siteIid => $_getI64(0);
  @$pb.TagNumber(1)
  set siteIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSiteIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearSiteIid() => $_clearField(1);

  @$pb.TagNumber(2)
  SiteBootMode get mode => $_getN(1);
  @$pb.TagNumber(2)
  set mode(SiteBootMode value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasMode() => $_has(1);
  @$pb.TagNumber(2)
  void clearMode() => $_clearField(2);
}

class ResSiteBootGet extends $pb.GeneratedMessage {
  factory ResSiteBootGet({
    $core.String? bootJson,
  }) {
    final result = ResSiteBootGet._();
    if (bootJson != null) result.bootJson = bootJson;
    return result;
  }

  ResSiteBootGet._();

  factory ResSiteBootGet.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSiteBootGet()..mergeFromBuffer(data, registry);
  factory ResSiteBootGet.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSiteBootGet()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResSiteBootGet',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResSiteBootGet.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'bootJson')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSiteBootGet clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSiteBootGet copyWith(void Function(ResSiteBootGet) updates) =>
      super.copyWith((message) => updates(message as ResSiteBootGet))
          as ResSiteBootGet;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResSiteBootGet() / ResSiteBootGet.new instead')
  static ResSiteBootGet create() => ResSiteBootGet._();
  static $pb.GeneratedMessage $_createMessage() => ResSiteBootGet._();
  @$core.override
  ResSiteBootGet createEmptyInstance() => ResSiteBootGet._();
  @$core.pragma('dart2js:noInline')
  static ResSiteBootGet getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResSiteBootGet>(
          ResSiteBootGet.$_createMessage);
  static ResSiteBootGet? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get bootJson => $_getSZ(0);
  @$pb.TagNumber(1)
  set bootJson($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasBootJson() => $_has(0);
  @$pb.TagNumber(1)
  void clearBootJson() => $_clearField(1);
}

class SiteQueryRow extends $pb.GeneratedMessage {
  factory SiteQueryRow({
    $fixnum.Int64? siteIid,
    $core.String? siteName,
    $core.Iterable<$core.MapEntry<$core.String, $core.String>>? cells,
  }) {
    final result = SiteQueryRow._();
    if (siteIid != null) result.siteIid = siteIid;
    if (siteName != null) result.siteName = siteName;
    if (cells != null) result.cells.addEntries(cells);
    return result;
  }

  SiteQueryRow._();

  factory SiteQueryRow.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SiteQueryRow()..mergeFromBuffer(data, registry);
  factory SiteQueryRow.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SiteQueryRow()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SiteQueryRow',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: SiteQueryRow.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'siteIid')
    ..aOS(2, _omitFieldNames ? '' : 'siteName')
    ..m<$core.String, $core.String>(3, _omitFieldNames ? '' : 'cells',
        entryClassName: 'SiteQueryRow.CellsEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('c35'))
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SiteQueryRow clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SiteQueryRow copyWith(void Function(SiteQueryRow) updates) =>
      super.copyWith((message) => updates(message as SiteQueryRow))
          as SiteQueryRow;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SiteQueryRow() / SiteQueryRow.new instead')
  static SiteQueryRow create() => SiteQueryRow._();
  static $pb.GeneratedMessage $_createMessage() => SiteQueryRow._();
  @$core.override
  SiteQueryRow createEmptyInstance() => SiteQueryRow._();
  @$core.pragma('dart2js:noInline')
  static SiteQueryRow getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SiteQueryRow>(
          SiteQueryRow.$_createMessage);
  static SiteQueryRow? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get siteIid => $_getI64(0);
  @$pb.TagNumber(1)
  set siteIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSiteIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearSiteIid() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get siteName => $_getSZ(1);
  @$pb.TagNumber(2)
  set siteName($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSiteName() => $_has(1);
  @$pb.TagNumber(2)
  void clearSiteName() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbMap<$core.String, $core.String> get cells => $_getMap(2);
}

class ReqSiteQueryRun extends $pb.GeneratedMessage {
  factory ReqSiteQueryRun({
    $core.String? queryId,
    $core.Iterable<$fixnum.Int64>? siteIids,
    $core.String? paramsJson,
  }) {
    final result = ReqSiteQueryRun._();
    if (queryId != null) result.queryId = queryId;
    if (siteIids != null) result.siteIids.addAll(siteIids);
    if (paramsJson != null) result.paramsJson = paramsJson;
    return result;
  }

  ReqSiteQueryRun._();

  factory ReqSiteQueryRun.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSiteQueryRun()..mergeFromBuffer(data, registry);
  factory ReqSiteQueryRun.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSiteQueryRun()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqSiteQueryRun',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqSiteQueryRun.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'queryId')
    ..p<$fixnum.Int64>(2, _omitFieldNames ? '' : 'siteIids', $pb.PbFieldType.K6)
    ..aOS(3, _omitFieldNames ? '' : 'paramsJson')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSiteQueryRun clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSiteQueryRun copyWith(void Function(ReqSiteQueryRun) updates) =>
      super.copyWith((message) => updates(message as ReqSiteQueryRun))
          as ReqSiteQueryRun;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqSiteQueryRun() / ReqSiteQueryRun.new instead')
  static ReqSiteQueryRun create() => ReqSiteQueryRun._();
  static $pb.GeneratedMessage $_createMessage() => ReqSiteQueryRun._();
  @$core.override
  ReqSiteQueryRun createEmptyInstance() => ReqSiteQueryRun._();
  @$core.pragma('dart2js:noInline')
  static ReqSiteQueryRun getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqSiteQueryRun>(
          ReqSiteQueryRun.$_createMessage);
  static ReqSiteQueryRun? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get queryId => $_getSZ(0);
  @$pb.TagNumber(1)
  set queryId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasQueryId() => $_has(0);
  @$pb.TagNumber(1)
  void clearQueryId() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<$fixnum.Int64> get siteIids => $_getList(1);

  @$pb.TagNumber(3)
  $core.String get paramsJson => $_getSZ(2);
  @$pb.TagNumber(3)
  set paramsJson($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasParamsJson() => $_has(2);
  @$pb.TagNumber(3)
  void clearParamsJson() => $_clearField(3);
}

class ResSiteQueryRun extends $pb.GeneratedMessage {
  factory ResSiteQueryRun({
    $core.Iterable<SiteQueryRow>? rows,
    $core.String? resultJson,
  }) {
    final result = ResSiteQueryRun._();
    if (rows != null) result.rows.addAll(rows);
    if (resultJson != null) result.resultJson = resultJson;
    return result;
  }

  ResSiteQueryRun._();

  factory ResSiteQueryRun.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSiteQueryRun()..mergeFromBuffer(data, registry);
  factory ResSiteQueryRun.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSiteQueryRun()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResSiteQueryRun',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResSiteQueryRun.$_createMessage)
    ..pPM<SiteQueryRow>(1, _omitFieldNames ? '' : 'rows',
        subBuilder: SiteQueryRow.$_createMessage)
    ..aOS(2, _omitFieldNames ? '' : 'resultJson')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSiteQueryRun clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSiteQueryRun copyWith(void Function(ResSiteQueryRun) updates) =>
      super.copyWith((message) => updates(message as ResSiteQueryRun))
          as ResSiteQueryRun;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResSiteQueryRun() / ResSiteQueryRun.new instead')
  static ResSiteQueryRun create() => ResSiteQueryRun._();
  static $pb.GeneratedMessage $_createMessage() => ResSiteQueryRun._();
  @$core.override
  ResSiteQueryRun createEmptyInstance() => ResSiteQueryRun._();
  @$core.pragma('dart2js:noInline')
  static ResSiteQueryRun getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResSiteQueryRun>(
          ResSiteQueryRun.$_createMessage);
  static ResSiteQueryRun? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<SiteQueryRow> get rows => $_getList(0);

  @$pb.TagNumber(2)
  $core.String get resultJson => $_getSZ(1);
  @$pb.TagNumber(2)
  set resultJson($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasResultJson() => $_has(1);
  @$pb.TagNumber(2)
  void clearResultJson() => $_clearField(2);
}

class ReqSiteGuestContactPut extends $pb.GeneratedMessage {
  factory ReqSiteGuestContactPut({
    $fixnum.Int64? siteIid,
    $core.String? name,
    $core.String? contactVal,
    $core.String? message,
    $core.String? metaJson,
  }) {
    final result = ReqSiteGuestContactPut._();
    if (siteIid != null) result.siteIid = siteIid;
    if (name != null) result.name = name;
    if (contactVal != null) result.contactVal = contactVal;
    if (message != null) result.message = message;
    if (metaJson != null) result.metaJson = metaJson;
    return result;
  }

  ReqSiteGuestContactPut._();

  factory ReqSiteGuestContactPut.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSiteGuestContactPut()..mergeFromBuffer(data, registry);
  factory ReqSiteGuestContactPut.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSiteGuestContactPut()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqSiteGuestContactPut',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqSiteGuestContactPut.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'siteIid')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOS(3, _omitFieldNames ? '' : 'contactVal')
    ..aOS(4, _omitFieldNames ? '' : 'message')
    ..aOS(5, _omitFieldNames ? '' : 'metaJson')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSiteGuestContactPut clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSiteGuestContactPut copyWith(
          void Function(ReqSiteGuestContactPut) updates) =>
      super.copyWith((message) => updates(message as ReqSiteGuestContactPut))
          as ReqSiteGuestContactPut;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ReqSiteGuestContactPut() / ReqSiteGuestContactPut.new instead')
  static ReqSiteGuestContactPut create() => ReqSiteGuestContactPut._();
  static $pb.GeneratedMessage $_createMessage() => ReqSiteGuestContactPut._();
  @$core.override
  ReqSiteGuestContactPut createEmptyInstance() => ReqSiteGuestContactPut._();
  @$core.pragma('dart2js:noInline')
  static ReqSiteGuestContactPut getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqSiteGuestContactPut>(
          ReqSiteGuestContactPut.$_createMessage);
  static ReqSiteGuestContactPut? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get siteIid => $_getI64(0);
  @$pb.TagNumber(1)
  set siteIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSiteIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearSiteIid() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get contactVal => $_getSZ(2);
  @$pb.TagNumber(3)
  set contactVal($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasContactVal() => $_has(2);
  @$pb.TagNumber(3)
  void clearContactVal() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get message => $_getSZ(3);
  @$pb.TagNumber(4)
  set message($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasMessage() => $_has(3);
  @$pb.TagNumber(4)
  void clearMessage() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get metaJson => $_getSZ(4);
  @$pb.TagNumber(5)
  set metaJson($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasMetaJson() => $_has(4);
  @$pb.TagNumber(5)
  void clearMetaJson() => $_clearField(5);
}

class ResSiteGuestContactPut extends $pb.GeneratedMessage {
  factory ResSiteGuestContactPut({
    $core.bool? ok,
    $fixnum.Int64? contactId,
    $core.String? error,
  }) {
    final result = ResSiteGuestContactPut._();
    if (ok != null) result.ok = ok;
    if (contactId != null) result.contactId = contactId;
    if (error != null) result.error = error;
    return result;
  }

  ResSiteGuestContactPut._();

  factory ResSiteGuestContactPut.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSiteGuestContactPut()..mergeFromBuffer(data, registry);
  factory ResSiteGuestContactPut.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSiteGuestContactPut()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResSiteGuestContactPut',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResSiteGuestContactPut.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'ok')
    ..aInt64(2, _omitFieldNames ? '' : 'contactId')
    ..aOS(3, _omitFieldNames ? '' : 'error')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSiteGuestContactPut clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSiteGuestContactPut copyWith(
          void Function(ResSiteGuestContactPut) updates) =>
      super.copyWith((message) => updates(message as ResSiteGuestContactPut))
          as ResSiteGuestContactPut;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ResSiteGuestContactPut() / ResSiteGuestContactPut.new instead')
  static ResSiteGuestContactPut create() => ResSiteGuestContactPut._();
  static $pb.GeneratedMessage $_createMessage() => ResSiteGuestContactPut._();
  @$core.override
  ResSiteGuestContactPut createEmptyInstance() => ResSiteGuestContactPut._();
  @$core.pragma('dart2js:noInline')
  static ResSiteGuestContactPut getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResSiteGuestContactPut>(
          ResSiteGuestContactPut.$_createMessage);
  static ResSiteGuestContactPut? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get ok => $_getBF(0);
  @$pb.TagNumber(1)
  set ok($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOk() => $_has(0);
  @$pb.TagNumber(1)
  void clearOk() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get contactId => $_getI64(1);
  @$pb.TagNumber(2)
  set contactId($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasContactId() => $_has(1);
  @$pb.TagNumber(2)
  void clearContactId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get error => $_getSZ(2);
  @$pb.TagNumber(3)
  set error($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasError() => $_has(2);
  @$pb.TagNumber(3)
  void clearError() => $_clearField(3);
}

class SiteGuestProductItem extends $pb.GeneratedMessage {
  factory SiteGuestProductItem({
    $fixnum.Int64? productId,
    $core.String? name,
    $core.String? desc,
    $fixnum.Int64? price,
    $core.String? pic,
    $core.String? category,
  }) {
    final result = SiteGuestProductItem._();
    if (productId != null) result.productId = productId;
    if (name != null) result.name = name;
    if (desc != null) result.desc = desc;
    if (price != null) result.price = price;
    if (pic != null) result.pic = pic;
    if (category != null) result.category = category;
    return result;
  }

  SiteGuestProductItem._();

  factory SiteGuestProductItem.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SiteGuestProductItem()..mergeFromBuffer(data, registry);
  factory SiteGuestProductItem.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SiteGuestProductItem()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SiteGuestProductItem',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: SiteGuestProductItem.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'productId')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOS(3, _omitFieldNames ? '' : 'desc')
    ..aInt64(4, _omitFieldNames ? '' : 'price')
    ..aOS(5, _omitFieldNames ? '' : 'pic')
    ..aOS(6, _omitFieldNames ? '' : 'category')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SiteGuestProductItem clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SiteGuestProductItem copyWith(void Function(SiteGuestProductItem) updates) =>
      super.copyWith((message) => updates(message as SiteGuestProductItem))
          as SiteGuestProductItem;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SiteGuestProductItem() / SiteGuestProductItem.new instead')
  static SiteGuestProductItem create() => SiteGuestProductItem._();
  static $pb.GeneratedMessage $_createMessage() => SiteGuestProductItem._();
  @$core.override
  SiteGuestProductItem createEmptyInstance() => SiteGuestProductItem._();
  @$core.pragma('dart2js:noInline')
  static SiteGuestProductItem getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SiteGuestProductItem>(
          SiteGuestProductItem.$_createMessage);
  static SiteGuestProductItem? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get productId => $_getI64(0);
  @$pb.TagNumber(1)
  set productId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasProductId() => $_has(0);
  @$pb.TagNumber(1)
  void clearProductId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get desc => $_getSZ(2);
  @$pb.TagNumber(3)
  set desc($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDesc() => $_has(2);
  @$pb.TagNumber(3)
  void clearDesc() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get price => $_getI64(3);
  @$pb.TagNumber(4)
  set price($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPrice() => $_has(3);
  @$pb.TagNumber(4)
  void clearPrice() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get pic => $_getSZ(4);
  @$pb.TagNumber(5)
  set pic($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasPic() => $_has(4);
  @$pb.TagNumber(5)
  void clearPic() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get category => $_getSZ(5);
  @$pb.TagNumber(6)
  set category($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasCategory() => $_has(5);
  @$pb.TagNumber(6)
  void clearCategory() => $_clearField(6);
}

class ReqSiteGuestProductList extends $pb.GeneratedMessage {
  factory ReqSiteGuestProductList({
    $fixnum.Int64? siteIid,
    $core.String? filter,
    $core.String? category,
    $core.String? cursor,
    $core.int? limit,
  }) {
    final result = ReqSiteGuestProductList._();
    if (siteIid != null) result.siteIid = siteIid;
    if (filter != null) result.filter = filter;
    if (category != null) result.category = category;
    if (cursor != null) result.cursor = cursor;
    if (limit != null) result.limit = limit;
    return result;
  }

  ReqSiteGuestProductList._();

  factory ReqSiteGuestProductList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSiteGuestProductList()..mergeFromBuffer(data, registry);
  factory ReqSiteGuestProductList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSiteGuestProductList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqSiteGuestProductList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqSiteGuestProductList.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'siteIid')
    ..aOS(2, _omitFieldNames ? '' : 'filter')
    ..aOS(3, _omitFieldNames ? '' : 'category')
    ..aOS(4, _omitFieldNames ? '' : 'cursor')
    ..aI(5, _omitFieldNames ? '' : 'limit')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSiteGuestProductList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSiteGuestProductList copyWith(
          void Function(ReqSiteGuestProductList) updates) =>
      super.copyWith((message) => updates(message as ReqSiteGuestProductList))
          as ReqSiteGuestProductList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ReqSiteGuestProductList() / ReqSiteGuestProductList.new instead')
  static ReqSiteGuestProductList create() => ReqSiteGuestProductList._();
  static $pb.GeneratedMessage $_createMessage() => ReqSiteGuestProductList._();
  @$core.override
  ReqSiteGuestProductList createEmptyInstance() => ReqSiteGuestProductList._();
  @$core.pragma('dart2js:noInline')
  static ReqSiteGuestProductList getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqSiteGuestProductList>(
          ReqSiteGuestProductList.$_createMessage);
  static ReqSiteGuestProductList? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get siteIid => $_getI64(0);
  @$pb.TagNumber(1)
  set siteIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSiteIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearSiteIid() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get filter => $_getSZ(1);
  @$pb.TagNumber(2)
  set filter($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasFilter() => $_has(1);
  @$pb.TagNumber(2)
  void clearFilter() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get category => $_getSZ(2);
  @$pb.TagNumber(3)
  set category($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCategory() => $_has(2);
  @$pb.TagNumber(3)
  void clearCategory() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get cursor => $_getSZ(3);
  @$pb.TagNumber(4)
  set cursor($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasCursor() => $_has(3);
  @$pb.TagNumber(4)
  void clearCursor() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get limit => $_getIZ(4);
  @$pb.TagNumber(5)
  set limit($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasLimit() => $_has(4);
  @$pb.TagNumber(5)
  void clearLimit() => $_clearField(5);
}

class ResSiteGuestProductList extends $pb.GeneratedMessage {
  factory ResSiteGuestProductList({
    $core.Iterable<SiteGuestProductItem>? items,
    $core.String? nextCursor,
  }) {
    final result = ResSiteGuestProductList._();
    if (items != null) result.items.addAll(items);
    if (nextCursor != null) result.nextCursor = nextCursor;
    return result;
  }

  ResSiteGuestProductList._();

  factory ResSiteGuestProductList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSiteGuestProductList()..mergeFromBuffer(data, registry);
  factory ResSiteGuestProductList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSiteGuestProductList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResSiteGuestProductList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResSiteGuestProductList.$_createMessage)
    ..pPM<SiteGuestProductItem>(1, _omitFieldNames ? '' : 'items',
        subBuilder: SiteGuestProductItem.$_createMessage)
    ..aOS(2, _omitFieldNames ? '' : 'nextCursor')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSiteGuestProductList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSiteGuestProductList copyWith(
          void Function(ResSiteGuestProductList) updates) =>
      super.copyWith((message) => updates(message as ResSiteGuestProductList))
          as ResSiteGuestProductList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ResSiteGuestProductList() / ResSiteGuestProductList.new instead')
  static ResSiteGuestProductList create() => ResSiteGuestProductList._();
  static $pb.GeneratedMessage $_createMessage() => ResSiteGuestProductList._();
  @$core.override
  ResSiteGuestProductList createEmptyInstance() => ResSiteGuestProductList._();
  @$core.pragma('dart2js:noInline')
  static ResSiteGuestProductList getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResSiteGuestProductList>(
          ResSiteGuestProductList.$_createMessage);
  static ResSiteGuestProductList? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<SiteGuestProductItem> get items => $_getList(0);

  @$pb.TagNumber(2)
  $core.String get nextCursor => $_getSZ(1);
  @$pb.TagNumber(2)
  set nextCursor($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNextCursor() => $_has(1);
  @$pb.TagNumber(2)
  void clearNextCursor() => $_clearField(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
