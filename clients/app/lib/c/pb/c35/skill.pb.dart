//
//  Generated code. Do not modify.
//  source: c35/skill.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'skill.pbenum.dart';

export 'skill.pbenum.dart';

class Skill extends $pb.GeneratedMessage {
  factory Skill({
    $fixnum.Int64? id,
    $fixnum.Int64? ownerIid,
    SkillScope? scope,
    $fixnum.Int64? deviceIid,
    $fixnum.Int64? teamIid,
    $core.String? title,
    $core.String? hashBlake3,
    $core.String? bodyMd,
    SkillSource? source,
    $fixnum.Int64? catalogId,
    $fixnum.Int64? catalogVariantId,
    $fixnum.Int64? catalogReleaseId,
    $core.String? authorName,
    $core.String? tagsJson,
    $core.String? phrasesJson,
    $core.bool? autoRun,
    $core.String? surface,
    $core.String? targetApp,
    $core.String? urlPattern,
    $core.Iterable<SkillStep>? steps,
    $fixnum.Int64? createdTsMs,
    $fixnum.Int64? updatedTsMs,
    $fixnum.Int64? deletedTsMs,
  }) {
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    if (ownerIid != null) {
      $result.ownerIid = ownerIid;
    }
    if (scope != null) {
      $result.scope = scope;
    }
    if (deviceIid != null) {
      $result.deviceIid = deviceIid;
    }
    if (teamIid != null) {
      $result.teamIid = teamIid;
    }
    if (title != null) {
      $result.title = title;
    }
    if (hashBlake3 != null) {
      $result.hashBlake3 = hashBlake3;
    }
    if (bodyMd != null) {
      $result.bodyMd = bodyMd;
    }
    if (source != null) {
      $result.source = source;
    }
    if (catalogId != null) {
      $result.catalogId = catalogId;
    }
    if (catalogVariantId != null) {
      $result.catalogVariantId = catalogVariantId;
    }
    if (catalogReleaseId != null) {
      $result.catalogReleaseId = catalogReleaseId;
    }
    if (authorName != null) {
      $result.authorName = authorName;
    }
    if (tagsJson != null) {
      $result.tagsJson = tagsJson;
    }
    if (phrasesJson != null) {
      $result.phrasesJson = phrasesJson;
    }
    if (autoRun != null) {
      $result.autoRun = autoRun;
    }
    if (surface != null) {
      $result.surface = surface;
    }
    if (targetApp != null) {
      $result.targetApp = targetApp;
    }
    if (urlPattern != null) {
      $result.urlPattern = urlPattern;
    }
    if (steps != null) {
      $result.steps.addAll(steps);
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
  Skill._() : super();
  factory Skill.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Skill.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Skill', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..aInt64(2, _omitFieldNames ? '' : 'ownerIid')
    ..e<SkillScope>(3, _omitFieldNames ? '' : 'scope', $pb.PbFieldType.OE, defaultOrMaker: SkillScope.SKILL_SCOPE_UNSPECIFIED, valueOf: SkillScope.valueOf, enumValues: SkillScope.values)
    ..aInt64(4, _omitFieldNames ? '' : 'deviceIid')
    ..aInt64(5, _omitFieldNames ? '' : 'teamIid')
    ..aOS(6, _omitFieldNames ? '' : 'title')
    ..aOS(7, _omitFieldNames ? '' : 'hashBlake3')
    ..aOS(8, _omitFieldNames ? '' : 'bodyMd')
    ..e<SkillSource>(9, _omitFieldNames ? '' : 'source', $pb.PbFieldType.OE, defaultOrMaker: SkillSource.SKILL_SOURCE_UNSPECIFIED, valueOf: SkillSource.valueOf, enumValues: SkillSource.values)
    ..aInt64(10, _omitFieldNames ? '' : 'catalogId')
    ..aInt64(11, _omitFieldNames ? '' : 'catalogVariantId')
    ..aInt64(12, _omitFieldNames ? '' : 'catalogReleaseId')
    ..aOS(13, _omitFieldNames ? '' : 'authorName')
    ..aOS(14, _omitFieldNames ? '' : 'tagsJson')
    ..aOS(15, _omitFieldNames ? '' : 'phrasesJson')
    ..aOB(16, _omitFieldNames ? '' : 'autoRun')
    ..aOS(17, _omitFieldNames ? '' : 'surface')
    ..aOS(18, _omitFieldNames ? '' : 'targetApp')
    ..aOS(19, _omitFieldNames ? '' : 'urlPattern')
    ..pc<SkillStep>(20, _omitFieldNames ? '' : 'steps', $pb.PbFieldType.PM, subBuilder: SkillStep.create)
    ..aInt64(30, _omitFieldNames ? '' : 'createdTsMs')
    ..aInt64(31, _omitFieldNames ? '' : 'updatedTsMs')
    ..aInt64(32, _omitFieldNames ? '' : 'deletedTsMs')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Skill clone() => Skill()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Skill copyWith(void Function(Skill) updates) => super.copyWith((message) => updates(message as Skill)) as Skill;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Skill create() => Skill._();
  Skill createEmptyInstance() => create();
  static $pb.PbList<Skill> createRepeated() => $pb.PbList<Skill>();
  @$core.pragma('dart2js:noInline')
  static Skill getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Skill>(create);
  static Skill? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get ownerIid => $_getI64(1);
  @$pb.TagNumber(2)
  set ownerIid($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasOwnerIid() => $_has(1);
  @$pb.TagNumber(2)
  void clearOwnerIid() => clearField(2);

  @$pb.TagNumber(3)
  SkillScope get scope => $_getN(2);
  @$pb.TagNumber(3)
  set scope(SkillScope v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasScope() => $_has(2);
  @$pb.TagNumber(3)
  void clearScope() => clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get deviceIid => $_getI64(3);
  @$pb.TagNumber(4)
  set deviceIid($fixnum.Int64 v) { $_setInt64(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasDeviceIid() => $_has(3);
  @$pb.TagNumber(4)
  void clearDeviceIid() => clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get teamIid => $_getI64(4);
  @$pb.TagNumber(5)
  set teamIid($fixnum.Int64 v) { $_setInt64(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasTeamIid() => $_has(4);
  @$pb.TagNumber(5)
  void clearTeamIid() => clearField(5);

  @$pb.TagNumber(6)
  $core.String get title => $_getSZ(5);
  @$pb.TagNumber(6)
  set title($core.String v) { $_setString(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasTitle() => $_has(5);
  @$pb.TagNumber(6)
  void clearTitle() => clearField(6);

  @$pb.TagNumber(7)
  $core.String get hashBlake3 => $_getSZ(6);
  @$pb.TagNumber(7)
  set hashBlake3($core.String v) { $_setString(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasHashBlake3() => $_has(6);
  @$pb.TagNumber(7)
  void clearHashBlake3() => clearField(7);

  @$pb.TagNumber(8)
  $core.String get bodyMd => $_getSZ(7);
  @$pb.TagNumber(8)
  set bodyMd($core.String v) { $_setString(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasBodyMd() => $_has(7);
  @$pb.TagNumber(8)
  void clearBodyMd() => clearField(8);

  @$pb.TagNumber(9)
  SkillSource get source => $_getN(8);
  @$pb.TagNumber(9)
  set source(SkillSource v) { setField(9, v); }
  @$pb.TagNumber(9)
  $core.bool hasSource() => $_has(8);
  @$pb.TagNumber(9)
  void clearSource() => clearField(9);

  @$pb.TagNumber(10)
  $fixnum.Int64 get catalogId => $_getI64(9);
  @$pb.TagNumber(10)
  set catalogId($fixnum.Int64 v) { $_setInt64(9, v); }
  @$pb.TagNumber(10)
  $core.bool hasCatalogId() => $_has(9);
  @$pb.TagNumber(10)
  void clearCatalogId() => clearField(10);

  @$pb.TagNumber(11)
  $fixnum.Int64 get catalogVariantId => $_getI64(10);
  @$pb.TagNumber(11)
  set catalogVariantId($fixnum.Int64 v) { $_setInt64(10, v); }
  @$pb.TagNumber(11)
  $core.bool hasCatalogVariantId() => $_has(10);
  @$pb.TagNumber(11)
  void clearCatalogVariantId() => clearField(11);

  @$pb.TagNumber(12)
  $fixnum.Int64 get catalogReleaseId => $_getI64(11);
  @$pb.TagNumber(12)
  set catalogReleaseId($fixnum.Int64 v) { $_setInt64(11, v); }
  @$pb.TagNumber(12)
  $core.bool hasCatalogReleaseId() => $_has(11);
  @$pb.TagNumber(12)
  void clearCatalogReleaseId() => clearField(12);

  @$pb.TagNumber(13)
  $core.String get authorName => $_getSZ(12);
  @$pb.TagNumber(13)
  set authorName($core.String v) { $_setString(12, v); }
  @$pb.TagNumber(13)
  $core.bool hasAuthorName() => $_has(12);
  @$pb.TagNumber(13)
  void clearAuthorName() => clearField(13);

  @$pb.TagNumber(14)
  $core.String get tagsJson => $_getSZ(13);
  @$pb.TagNumber(14)
  set tagsJson($core.String v) { $_setString(13, v); }
  @$pb.TagNumber(14)
  $core.bool hasTagsJson() => $_has(13);
  @$pb.TagNumber(14)
  void clearTagsJson() => clearField(14);

  @$pb.TagNumber(15)
  $core.String get phrasesJson => $_getSZ(14);
  @$pb.TagNumber(15)
  set phrasesJson($core.String v) { $_setString(14, v); }
  @$pb.TagNumber(15)
  $core.bool hasPhrasesJson() => $_has(14);
  @$pb.TagNumber(15)
  void clearPhrasesJson() => clearField(15);

  @$pb.TagNumber(16)
  $core.bool get autoRun => $_getBF(15);
  @$pb.TagNumber(16)
  set autoRun($core.bool v) { $_setBool(15, v); }
  @$pb.TagNumber(16)
  $core.bool hasAutoRun() => $_has(15);
  @$pb.TagNumber(16)
  void clearAutoRun() => clearField(16);

  @$pb.TagNumber(17)
  $core.String get surface => $_getSZ(16);
  @$pb.TagNumber(17)
  set surface($core.String v) { $_setString(16, v); }
  @$pb.TagNumber(17)
  $core.bool hasSurface() => $_has(16);
  @$pb.TagNumber(17)
  void clearSurface() => clearField(17);

  @$pb.TagNumber(18)
  $core.String get targetApp => $_getSZ(17);
  @$pb.TagNumber(18)
  set targetApp($core.String v) { $_setString(17, v); }
  @$pb.TagNumber(18)
  $core.bool hasTargetApp() => $_has(17);
  @$pb.TagNumber(18)
  void clearTargetApp() => clearField(18);

  @$pb.TagNumber(19)
  $core.String get urlPattern => $_getSZ(18);
  @$pb.TagNumber(19)
  set urlPattern($core.String v) { $_setString(18, v); }
  @$pb.TagNumber(19)
  $core.bool hasUrlPattern() => $_has(18);
  @$pb.TagNumber(19)
  void clearUrlPattern() => clearField(19);

  @$pb.TagNumber(20)
  $core.List<SkillStep> get steps => $_getList(19);

  @$pb.TagNumber(30)
  $fixnum.Int64 get createdTsMs => $_getI64(20);
  @$pb.TagNumber(30)
  set createdTsMs($fixnum.Int64 v) { $_setInt64(20, v); }
  @$pb.TagNumber(30)
  $core.bool hasCreatedTsMs() => $_has(20);
  @$pb.TagNumber(30)
  void clearCreatedTsMs() => clearField(30);

  @$pb.TagNumber(31)
  $fixnum.Int64 get updatedTsMs => $_getI64(21);
  @$pb.TagNumber(31)
  set updatedTsMs($fixnum.Int64 v) { $_setInt64(21, v); }
  @$pb.TagNumber(31)
  $core.bool hasUpdatedTsMs() => $_has(21);
  @$pb.TagNumber(31)
  void clearUpdatedTsMs() => clearField(31);

  @$pb.TagNumber(32)
  $fixnum.Int64 get deletedTsMs => $_getI64(22);
  @$pb.TagNumber(32)
  set deletedTsMs($fixnum.Int64 v) { $_setInt64(22, v); }
  @$pb.TagNumber(32)
  $core.bool hasDeletedTsMs() => $_has(22);
  @$pb.TagNumber(32)
  void clearDeletedTsMs() => clearField(32);
}

class SkillStep extends $pb.GeneratedMessage {
  factory SkillStep({
    $fixnum.Int64? id,
    $fixnum.Int64? skillId,
    $fixnum.Int64? ownerIid,
    $core.int? ord,
    $core.String? kind,
    $core.String? label,
    $core.String? axTargetJson,
    $core.String? screenshotHash,
    $core.String? comment,
    $fixnum.Int64? secretId,
    $core.String? tapeLocalOnlyJson,
    $fixnum.Int64? createdTsMs,
    $fixnum.Int64? updatedTsMs,
    $fixnum.Int64? deletedTsMs,
  }) {
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    if (skillId != null) {
      $result.skillId = skillId;
    }
    if (ownerIid != null) {
      $result.ownerIid = ownerIid;
    }
    if (ord != null) {
      $result.ord = ord;
    }
    if (kind != null) {
      $result.kind = kind;
    }
    if (label != null) {
      $result.label = label;
    }
    if (axTargetJson != null) {
      $result.axTargetJson = axTargetJson;
    }
    if (screenshotHash != null) {
      $result.screenshotHash = screenshotHash;
    }
    if (comment != null) {
      $result.comment = comment;
    }
    if (secretId != null) {
      $result.secretId = secretId;
    }
    if (tapeLocalOnlyJson != null) {
      $result.tapeLocalOnlyJson = tapeLocalOnlyJson;
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
  SkillStep._() : super();
  factory SkillStep.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SkillStep.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SkillStep', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..aInt64(2, _omitFieldNames ? '' : 'skillId')
    ..aInt64(3, _omitFieldNames ? '' : 'ownerIid')
    ..a<$core.int>(4, _omitFieldNames ? '' : 'ord', $pb.PbFieldType.O3)
    ..aOS(5, _omitFieldNames ? '' : 'kind')
    ..aOS(6, _omitFieldNames ? '' : 'label')
    ..aOS(7, _omitFieldNames ? '' : 'axTargetJson')
    ..aOS(8, _omitFieldNames ? '' : 'screenshotHash')
    ..aOS(9, _omitFieldNames ? '' : 'comment')
    ..aInt64(10, _omitFieldNames ? '' : 'secretId')
    ..aOS(11, _omitFieldNames ? '' : 'tapeLocalOnlyJson')
    ..aInt64(20, _omitFieldNames ? '' : 'createdTsMs')
    ..aInt64(21, _omitFieldNames ? '' : 'updatedTsMs')
    ..aInt64(22, _omitFieldNames ? '' : 'deletedTsMs')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SkillStep clone() => SkillStep()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SkillStep copyWith(void Function(SkillStep) updates) => super.copyWith((message) => updates(message as SkillStep)) as SkillStep;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SkillStep create() => SkillStep._();
  SkillStep createEmptyInstance() => create();
  static $pb.PbList<SkillStep> createRepeated() => $pb.PbList<SkillStep>();
  @$core.pragma('dart2js:noInline')
  static SkillStep getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SkillStep>(create);
  static SkillStep? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get skillId => $_getI64(1);
  @$pb.TagNumber(2)
  set skillId($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasSkillId() => $_has(1);
  @$pb.TagNumber(2)
  void clearSkillId() => clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get ownerIid => $_getI64(2);
  @$pb.TagNumber(3)
  set ownerIid($fixnum.Int64 v) { $_setInt64(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasOwnerIid() => $_has(2);
  @$pb.TagNumber(3)
  void clearOwnerIid() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get ord => $_getIZ(3);
  @$pb.TagNumber(4)
  set ord($core.int v) { $_setSignedInt32(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasOrd() => $_has(3);
  @$pb.TagNumber(4)
  void clearOrd() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get kind => $_getSZ(4);
  @$pb.TagNumber(5)
  set kind($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasKind() => $_has(4);
  @$pb.TagNumber(5)
  void clearKind() => clearField(5);

  @$pb.TagNumber(6)
  $core.String get label => $_getSZ(5);
  @$pb.TagNumber(6)
  set label($core.String v) { $_setString(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasLabel() => $_has(5);
  @$pb.TagNumber(6)
  void clearLabel() => clearField(6);

  @$pb.TagNumber(7)
  $core.String get axTargetJson => $_getSZ(6);
  @$pb.TagNumber(7)
  set axTargetJson($core.String v) { $_setString(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasAxTargetJson() => $_has(6);
  @$pb.TagNumber(7)
  void clearAxTargetJson() => clearField(7);

  @$pb.TagNumber(8)
  $core.String get screenshotHash => $_getSZ(7);
  @$pb.TagNumber(8)
  set screenshotHash($core.String v) { $_setString(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasScreenshotHash() => $_has(7);
  @$pb.TagNumber(8)
  void clearScreenshotHash() => clearField(8);

  @$pb.TagNumber(9)
  $core.String get comment => $_getSZ(8);
  @$pb.TagNumber(9)
  set comment($core.String v) { $_setString(8, v); }
  @$pb.TagNumber(9)
  $core.bool hasComment() => $_has(8);
  @$pb.TagNumber(9)
  void clearComment() => clearField(9);

  @$pb.TagNumber(10)
  $fixnum.Int64 get secretId => $_getI64(9);
  @$pb.TagNumber(10)
  set secretId($fixnum.Int64 v) { $_setInt64(9, v); }
  @$pb.TagNumber(10)
  $core.bool hasSecretId() => $_has(9);
  @$pb.TagNumber(10)
  void clearSecretId() => clearField(10);

  @$pb.TagNumber(11)
  $core.String get tapeLocalOnlyJson => $_getSZ(10);
  @$pb.TagNumber(11)
  set tapeLocalOnlyJson($core.String v) { $_setString(10, v); }
  @$pb.TagNumber(11)
  $core.bool hasTapeLocalOnlyJson() => $_has(10);
  @$pb.TagNumber(11)
  void clearTapeLocalOnlyJson() => clearField(11);

  @$pb.TagNumber(20)
  $fixnum.Int64 get createdTsMs => $_getI64(11);
  @$pb.TagNumber(20)
  set createdTsMs($fixnum.Int64 v) { $_setInt64(11, v); }
  @$pb.TagNumber(20)
  $core.bool hasCreatedTsMs() => $_has(11);
  @$pb.TagNumber(20)
  void clearCreatedTsMs() => clearField(20);

  @$pb.TagNumber(21)
  $fixnum.Int64 get updatedTsMs => $_getI64(12);
  @$pb.TagNumber(21)
  set updatedTsMs($fixnum.Int64 v) { $_setInt64(12, v); }
  @$pb.TagNumber(21)
  $core.bool hasUpdatedTsMs() => $_has(12);
  @$pb.TagNumber(21)
  void clearUpdatedTsMs() => clearField(21);

  @$pb.TagNumber(22)
  $fixnum.Int64 get deletedTsMs => $_getI64(13);
  @$pb.TagNumber(22)
  set deletedTsMs($fixnum.Int64 v) { $_setInt64(13, v); }
  @$pb.TagNumber(22)
  $core.bool hasDeletedTsMs() => $_has(13);
  @$pb.TagNumber(22)
  void clearDeletedTsMs() => clearField(22);
}

class SkillCatalog extends $pb.GeneratedMessage {
  factory SkillCatalog({
    $fixnum.Int64? id,
    $fixnum.Int64? authorIid,
    $core.String? authorName,
    $core.String? slug,
    $core.String? title,
    $core.String? summary,
    $core.String? bodyMd,
    $core.String? tagsJson,
    $core.int? installCount,
    $core.double? rating,
    $core.bool? isVerified,
    $core.String? status,
  }) {
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    if (authorIid != null) {
      $result.authorIid = authorIid;
    }
    if (authorName != null) {
      $result.authorName = authorName;
    }
    if (slug != null) {
      $result.slug = slug;
    }
    if (title != null) {
      $result.title = title;
    }
    if (summary != null) {
      $result.summary = summary;
    }
    if (bodyMd != null) {
      $result.bodyMd = bodyMd;
    }
    if (tagsJson != null) {
      $result.tagsJson = tagsJson;
    }
    if (installCount != null) {
      $result.installCount = installCount;
    }
    if (rating != null) {
      $result.rating = rating;
    }
    if (isVerified != null) {
      $result.isVerified = isVerified;
    }
    if (status != null) {
      $result.status = status;
    }
    return $result;
  }
  SkillCatalog._() : super();
  factory SkillCatalog.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SkillCatalog.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SkillCatalog', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..aInt64(2, _omitFieldNames ? '' : 'authorIid')
    ..aOS(3, _omitFieldNames ? '' : 'authorName')
    ..aOS(4, _omitFieldNames ? '' : 'slug')
    ..aOS(5, _omitFieldNames ? '' : 'title')
    ..aOS(6, _omitFieldNames ? '' : 'summary')
    ..aOS(7, _omitFieldNames ? '' : 'bodyMd')
    ..aOS(8, _omitFieldNames ? '' : 'tagsJson')
    ..a<$core.int>(9, _omitFieldNames ? '' : 'installCount', $pb.PbFieldType.O3)
    ..a<$core.double>(10, _omitFieldNames ? '' : 'rating', $pb.PbFieldType.OD)
    ..aOB(11, _omitFieldNames ? '' : 'isVerified')
    ..aOS(12, _omitFieldNames ? '' : 'status')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SkillCatalog clone() => SkillCatalog()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SkillCatalog copyWith(void Function(SkillCatalog) updates) => super.copyWith((message) => updates(message as SkillCatalog)) as SkillCatalog;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SkillCatalog create() => SkillCatalog._();
  SkillCatalog createEmptyInstance() => create();
  static $pb.PbList<SkillCatalog> createRepeated() => $pb.PbList<SkillCatalog>();
  @$core.pragma('dart2js:noInline')
  static SkillCatalog getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SkillCatalog>(create);
  static SkillCatalog? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get authorIid => $_getI64(1);
  @$pb.TagNumber(2)
  set authorIid($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasAuthorIid() => $_has(1);
  @$pb.TagNumber(2)
  void clearAuthorIid() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get authorName => $_getSZ(2);
  @$pb.TagNumber(3)
  set authorName($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasAuthorName() => $_has(2);
  @$pb.TagNumber(3)
  void clearAuthorName() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get slug => $_getSZ(3);
  @$pb.TagNumber(4)
  set slug($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasSlug() => $_has(3);
  @$pb.TagNumber(4)
  void clearSlug() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get title => $_getSZ(4);
  @$pb.TagNumber(5)
  set title($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasTitle() => $_has(4);
  @$pb.TagNumber(5)
  void clearTitle() => clearField(5);

  @$pb.TagNumber(6)
  $core.String get summary => $_getSZ(5);
  @$pb.TagNumber(6)
  set summary($core.String v) { $_setString(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasSummary() => $_has(5);
  @$pb.TagNumber(6)
  void clearSummary() => clearField(6);

  @$pb.TagNumber(7)
  $core.String get bodyMd => $_getSZ(6);
  @$pb.TagNumber(7)
  set bodyMd($core.String v) { $_setString(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasBodyMd() => $_has(6);
  @$pb.TagNumber(7)
  void clearBodyMd() => clearField(7);

  @$pb.TagNumber(8)
  $core.String get tagsJson => $_getSZ(7);
  @$pb.TagNumber(8)
  set tagsJson($core.String v) { $_setString(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasTagsJson() => $_has(7);
  @$pb.TagNumber(8)
  void clearTagsJson() => clearField(8);

  @$pb.TagNumber(9)
  $core.int get installCount => $_getIZ(8);
  @$pb.TagNumber(9)
  set installCount($core.int v) { $_setSignedInt32(8, v); }
  @$pb.TagNumber(9)
  $core.bool hasInstallCount() => $_has(8);
  @$pb.TagNumber(9)
  void clearInstallCount() => clearField(9);

  @$pb.TagNumber(10)
  $core.double get rating => $_getN(9);
  @$pb.TagNumber(10)
  set rating($core.double v) { $_setDouble(9, v); }
  @$pb.TagNumber(10)
  $core.bool hasRating() => $_has(9);
  @$pb.TagNumber(10)
  void clearRating() => clearField(10);

  @$pb.TagNumber(11)
  $core.bool get isVerified => $_getBF(10);
  @$pb.TagNumber(11)
  set isVerified($core.bool v) { $_setBool(10, v); }
  @$pb.TagNumber(11)
  $core.bool hasIsVerified() => $_has(10);
  @$pb.TagNumber(11)
  void clearIsVerified() => clearField(11);

  @$pb.TagNumber(12)
  $core.String get status => $_getSZ(11);
  @$pb.TagNumber(12)
  set status($core.String v) { $_setString(11, v); }
  @$pb.TagNumber(12)
  $core.bool hasStatus() => $_has(11);
  @$pb.TagNumber(12)
  void clearStatus() => clearField(12);
}

class ReqSkillList extends $pb.GeneratedMessage {
  factory ReqSkillList({
    SkillScope? scope,
    $fixnum.Int64? deviceIid,
    $fixnum.Int64? teamIid,
    $fixnum.Int64? sinceMs,
  }) {
    final $result = create();
    if (scope != null) {
      $result.scope = scope;
    }
    if (deviceIid != null) {
      $result.deviceIid = deviceIid;
    }
    if (teamIid != null) {
      $result.teamIid = teamIid;
    }
    if (sinceMs != null) {
      $result.sinceMs = sinceMs;
    }
    return $result;
  }
  ReqSkillList._() : super();
  factory ReqSkillList.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ReqSkillList.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ReqSkillList', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..e<SkillScope>(1, _omitFieldNames ? '' : 'scope', $pb.PbFieldType.OE, defaultOrMaker: SkillScope.SKILL_SCOPE_UNSPECIFIED, valueOf: SkillScope.valueOf, enumValues: SkillScope.values)
    ..aInt64(2, _omitFieldNames ? '' : 'deviceIid')
    ..aInt64(3, _omitFieldNames ? '' : 'teamIid')
    ..aInt64(4, _omitFieldNames ? '' : 'sinceMs')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ReqSkillList clone() => ReqSkillList()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ReqSkillList copyWith(void Function(ReqSkillList) updates) => super.copyWith((message) => updates(message as ReqSkillList)) as ReqSkillList;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReqSkillList create() => ReqSkillList._();
  ReqSkillList createEmptyInstance() => create();
  static $pb.PbList<ReqSkillList> createRepeated() => $pb.PbList<ReqSkillList>();
  @$core.pragma('dart2js:noInline')
  static ReqSkillList getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqSkillList>(create);
  static ReqSkillList? _defaultInstance;

  @$pb.TagNumber(1)
  SkillScope get scope => $_getN(0);
  @$pb.TagNumber(1)
  set scope(SkillScope v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasScope() => $_has(0);
  @$pb.TagNumber(1)
  void clearScope() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get deviceIid => $_getI64(1);
  @$pb.TagNumber(2)
  set deviceIid($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasDeviceIid() => $_has(1);
  @$pb.TagNumber(2)
  void clearDeviceIid() => clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get teamIid => $_getI64(2);
  @$pb.TagNumber(3)
  set teamIid($fixnum.Int64 v) { $_setInt64(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasTeamIid() => $_has(2);
  @$pb.TagNumber(3)
  void clearTeamIid() => clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get sinceMs => $_getI64(3);
  @$pb.TagNumber(4)
  set sinceMs($fixnum.Int64 v) { $_setInt64(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasSinceMs() => $_has(3);
  @$pb.TagNumber(4)
  void clearSinceMs() => clearField(4);
}

class ResSkillList extends $pb.GeneratedMessage {
  factory ResSkillList({
    $core.Iterable<Skill>? skills,
  }) {
    final $result = create();
    if (skills != null) {
      $result.skills.addAll(skills);
    }
    return $result;
  }
  ResSkillList._() : super();
  factory ResSkillList.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ResSkillList.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ResSkillList', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..pc<Skill>(1, _omitFieldNames ? '' : 'skills', $pb.PbFieldType.PM, subBuilder: Skill.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ResSkillList clone() => ResSkillList()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ResSkillList copyWith(void Function(ResSkillList) updates) => super.copyWith((message) => updates(message as ResSkillList)) as ResSkillList;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResSkillList create() => ResSkillList._();
  ResSkillList createEmptyInstance() => create();
  static $pb.PbList<ResSkillList> createRepeated() => $pb.PbList<ResSkillList>();
  @$core.pragma('dart2js:noInline')
  static ResSkillList getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResSkillList>(create);
  static ResSkillList? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<Skill> get skills => $_getList(0);
}

class ReqSkillGet extends $pb.GeneratedMessage {
  factory ReqSkillGet({
    $fixnum.Int64? id,
  }) {
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    return $result;
  }
  ReqSkillGet._() : super();
  factory ReqSkillGet.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ReqSkillGet.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ReqSkillGet', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ReqSkillGet clone() => ReqSkillGet()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ReqSkillGet copyWith(void Function(ReqSkillGet) updates) => super.copyWith((message) => updates(message as ReqSkillGet)) as ReqSkillGet;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReqSkillGet create() => ReqSkillGet._();
  ReqSkillGet createEmptyInstance() => create();
  static $pb.PbList<ReqSkillGet> createRepeated() => $pb.PbList<ReqSkillGet>();
  @$core.pragma('dart2js:noInline')
  static ReqSkillGet getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqSkillGet>(create);
  static ReqSkillGet? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);
}

class ResSkillGet extends $pb.GeneratedMessage {
  factory ResSkillGet({
    Skill? skill,
  }) {
    final $result = create();
    if (skill != null) {
      $result.skill = skill;
    }
    return $result;
  }
  ResSkillGet._() : super();
  factory ResSkillGet.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ResSkillGet.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ResSkillGet', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aOM<Skill>(1, _omitFieldNames ? '' : 'skill', subBuilder: Skill.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ResSkillGet clone() => ResSkillGet()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ResSkillGet copyWith(void Function(ResSkillGet) updates) => super.copyWith((message) => updates(message as ResSkillGet)) as ResSkillGet;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResSkillGet create() => ResSkillGet._();
  ResSkillGet createEmptyInstance() => create();
  static $pb.PbList<ResSkillGet> createRepeated() => $pb.PbList<ResSkillGet>();
  @$core.pragma('dart2js:noInline')
  static ResSkillGet getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResSkillGet>(create);
  static ResSkillGet? _defaultInstance;

  @$pb.TagNumber(1)
  Skill get skill => $_getN(0);
  @$pb.TagNumber(1)
  set skill(Skill v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasSkill() => $_has(0);
  @$pb.TagNumber(1)
  void clearSkill() => clearField(1);
  @$pb.TagNumber(1)
  Skill ensureSkill() => $_ensure(0);
}

class ReqSkillPut extends $pb.GeneratedMessage {
  factory ReqSkillPut({
    Skill? skill,
  }) {
    final $result = create();
    if (skill != null) {
      $result.skill = skill;
    }
    return $result;
  }
  ReqSkillPut._() : super();
  factory ReqSkillPut.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ReqSkillPut.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ReqSkillPut', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aOM<Skill>(1, _omitFieldNames ? '' : 'skill', subBuilder: Skill.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ReqSkillPut clone() => ReqSkillPut()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ReqSkillPut copyWith(void Function(ReqSkillPut) updates) => super.copyWith((message) => updates(message as ReqSkillPut)) as ReqSkillPut;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReqSkillPut create() => ReqSkillPut._();
  ReqSkillPut createEmptyInstance() => create();
  static $pb.PbList<ReqSkillPut> createRepeated() => $pb.PbList<ReqSkillPut>();
  @$core.pragma('dart2js:noInline')
  static ReqSkillPut getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqSkillPut>(create);
  static ReqSkillPut? _defaultInstance;

  @$pb.TagNumber(1)
  Skill get skill => $_getN(0);
  @$pb.TagNumber(1)
  set skill(Skill v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasSkill() => $_has(0);
  @$pb.TagNumber(1)
  void clearSkill() => clearField(1);
  @$pb.TagNumber(1)
  Skill ensureSkill() => $_ensure(0);
}

class ResSkillPut extends $pb.GeneratedMessage {
  factory ResSkillPut({
    Skill? skill,
  }) {
    final $result = create();
    if (skill != null) {
      $result.skill = skill;
    }
    return $result;
  }
  ResSkillPut._() : super();
  factory ResSkillPut.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ResSkillPut.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ResSkillPut', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aOM<Skill>(1, _omitFieldNames ? '' : 'skill', subBuilder: Skill.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ResSkillPut clone() => ResSkillPut()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ResSkillPut copyWith(void Function(ResSkillPut) updates) => super.copyWith((message) => updates(message as ResSkillPut)) as ResSkillPut;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResSkillPut create() => ResSkillPut._();
  ResSkillPut createEmptyInstance() => create();
  static $pb.PbList<ResSkillPut> createRepeated() => $pb.PbList<ResSkillPut>();
  @$core.pragma('dart2js:noInline')
  static ResSkillPut getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResSkillPut>(create);
  static ResSkillPut? _defaultInstance;

  @$pb.TagNumber(1)
  Skill get skill => $_getN(0);
  @$pb.TagNumber(1)
  set skill(Skill v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasSkill() => $_has(0);
  @$pb.TagNumber(1)
  void clearSkill() => clearField(1);
  @$pb.TagNumber(1)
  Skill ensureSkill() => $_ensure(0);
}

class ReqSkillCatalogList extends $pb.GeneratedMessage {
  factory ReqSkillCatalogList({
    $core.String? q,
    $core.int? limit,
  }) {
    final $result = create();
    if (q != null) {
      $result.q = q;
    }
    if (limit != null) {
      $result.limit = limit;
    }
    return $result;
  }
  ReqSkillCatalogList._() : super();
  factory ReqSkillCatalogList.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ReqSkillCatalogList.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ReqSkillCatalogList', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'q')
    ..a<$core.int>(2, _omitFieldNames ? '' : 'limit', $pb.PbFieldType.O3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ReqSkillCatalogList clone() => ReqSkillCatalogList()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ReqSkillCatalogList copyWith(void Function(ReqSkillCatalogList) updates) => super.copyWith((message) => updates(message as ReqSkillCatalogList)) as ReqSkillCatalogList;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReqSkillCatalogList create() => ReqSkillCatalogList._();
  ReqSkillCatalogList createEmptyInstance() => create();
  static $pb.PbList<ReqSkillCatalogList> createRepeated() => $pb.PbList<ReqSkillCatalogList>();
  @$core.pragma('dart2js:noInline')
  static ReqSkillCatalogList getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqSkillCatalogList>(create);
  static ReqSkillCatalogList? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get q => $_getSZ(0);
  @$pb.TagNumber(1)
  set q($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasQ() => $_has(0);
  @$pb.TagNumber(1)
  void clearQ() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get limit => $_getIZ(1);
  @$pb.TagNumber(2)
  set limit($core.int v) { $_setSignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasLimit() => $_has(1);
  @$pb.TagNumber(2)
  void clearLimit() => clearField(2);
}

class ResSkillCatalogList extends $pb.GeneratedMessage {
  factory ResSkillCatalogList({
    $core.Iterable<SkillCatalog>? catalogs,
  }) {
    final $result = create();
    if (catalogs != null) {
      $result.catalogs.addAll(catalogs);
    }
    return $result;
  }
  ResSkillCatalogList._() : super();
  factory ResSkillCatalogList.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ResSkillCatalogList.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ResSkillCatalogList', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..pc<SkillCatalog>(1, _omitFieldNames ? '' : 'catalogs', $pb.PbFieldType.PM, subBuilder: SkillCatalog.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ResSkillCatalogList clone() => ResSkillCatalogList()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ResSkillCatalogList copyWith(void Function(ResSkillCatalogList) updates) => super.copyWith((message) => updates(message as ResSkillCatalogList)) as ResSkillCatalogList;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResSkillCatalogList create() => ResSkillCatalogList._();
  ResSkillCatalogList createEmptyInstance() => create();
  static $pb.PbList<ResSkillCatalogList> createRepeated() => $pb.PbList<ResSkillCatalogList>();
  @$core.pragma('dart2js:noInline')
  static ResSkillCatalogList getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResSkillCatalogList>(create);
  static ResSkillCatalogList? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<SkillCatalog> get catalogs => $_getList(0);
}

class ReqSkillCatalogInstall extends $pb.GeneratedMessage {
  factory ReqSkillCatalogInstall({
    $fixnum.Int64? catalogId,
    $fixnum.Int64? variantId,
    $fixnum.Int64? releaseId,
    SkillScope? scope,
    $fixnum.Int64? deviceIid,
  }) {
    final $result = create();
    if (catalogId != null) {
      $result.catalogId = catalogId;
    }
    if (variantId != null) {
      $result.variantId = variantId;
    }
    if (releaseId != null) {
      $result.releaseId = releaseId;
    }
    if (scope != null) {
      $result.scope = scope;
    }
    if (deviceIid != null) {
      $result.deviceIid = deviceIid;
    }
    return $result;
  }
  ReqSkillCatalogInstall._() : super();
  factory ReqSkillCatalogInstall.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ReqSkillCatalogInstall.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ReqSkillCatalogInstall', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'catalogId')
    ..aInt64(2, _omitFieldNames ? '' : 'variantId')
    ..aInt64(3, _omitFieldNames ? '' : 'releaseId')
    ..e<SkillScope>(4, _omitFieldNames ? '' : 'scope', $pb.PbFieldType.OE, defaultOrMaker: SkillScope.SKILL_SCOPE_UNSPECIFIED, valueOf: SkillScope.valueOf, enumValues: SkillScope.values)
    ..aInt64(5, _omitFieldNames ? '' : 'deviceIid')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ReqSkillCatalogInstall clone() => ReqSkillCatalogInstall()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ReqSkillCatalogInstall copyWith(void Function(ReqSkillCatalogInstall) updates) => super.copyWith((message) => updates(message as ReqSkillCatalogInstall)) as ReqSkillCatalogInstall;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReqSkillCatalogInstall create() => ReqSkillCatalogInstall._();
  ReqSkillCatalogInstall createEmptyInstance() => create();
  static $pb.PbList<ReqSkillCatalogInstall> createRepeated() => $pb.PbList<ReqSkillCatalogInstall>();
  @$core.pragma('dart2js:noInline')
  static ReqSkillCatalogInstall getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqSkillCatalogInstall>(create);
  static ReqSkillCatalogInstall? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get catalogId => $_getI64(0);
  @$pb.TagNumber(1)
  set catalogId($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasCatalogId() => $_has(0);
  @$pb.TagNumber(1)
  void clearCatalogId() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get variantId => $_getI64(1);
  @$pb.TagNumber(2)
  set variantId($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasVariantId() => $_has(1);
  @$pb.TagNumber(2)
  void clearVariantId() => clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get releaseId => $_getI64(2);
  @$pb.TagNumber(3)
  set releaseId($fixnum.Int64 v) { $_setInt64(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasReleaseId() => $_has(2);
  @$pb.TagNumber(3)
  void clearReleaseId() => clearField(3);

  @$pb.TagNumber(4)
  SkillScope get scope => $_getN(3);
  @$pb.TagNumber(4)
  set scope(SkillScope v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasScope() => $_has(3);
  @$pb.TagNumber(4)
  void clearScope() => clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get deviceIid => $_getI64(4);
  @$pb.TagNumber(5)
  set deviceIid($fixnum.Int64 v) { $_setInt64(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasDeviceIid() => $_has(4);
  @$pb.TagNumber(5)
  void clearDeviceIid() => clearField(5);
}

class ResSkillCatalogInstall extends $pb.GeneratedMessage {
  factory ResSkillCatalogInstall({
    Skill? skill,
  }) {
    final $result = create();
    if (skill != null) {
      $result.skill = skill;
    }
    return $result;
  }
  ResSkillCatalogInstall._() : super();
  factory ResSkillCatalogInstall.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ResSkillCatalogInstall.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ResSkillCatalogInstall', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aOM<Skill>(1, _omitFieldNames ? '' : 'skill', subBuilder: Skill.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ResSkillCatalogInstall clone() => ResSkillCatalogInstall()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ResSkillCatalogInstall copyWith(void Function(ResSkillCatalogInstall) updates) => super.copyWith((message) => updates(message as ResSkillCatalogInstall)) as ResSkillCatalogInstall;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResSkillCatalogInstall create() => ResSkillCatalogInstall._();
  ResSkillCatalogInstall createEmptyInstance() => create();
  static $pb.PbList<ResSkillCatalogInstall> createRepeated() => $pb.PbList<ResSkillCatalogInstall>();
  @$core.pragma('dart2js:noInline')
  static ResSkillCatalogInstall getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResSkillCatalogInstall>(create);
  static ResSkillCatalogInstall? _defaultInstance;

  @$pb.TagNumber(1)
  Skill get skill => $_getN(0);
  @$pb.TagNumber(1)
  set skill(Skill v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasSkill() => $_has(0);
  @$pb.TagNumber(1)
  void clearSkill() => clearField(1);
  @$pb.TagNumber(1)
  Skill ensureSkill() => $_ensure(0);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
