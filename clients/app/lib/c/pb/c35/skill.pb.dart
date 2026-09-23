// This is a generated file - do not edit.
//
// Generated from c35/skill.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'skill.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

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
    $core.int? patchEpoch,
    $core.int? patchCount,
    $core.int? consecutiveOk,
    $core.String? detectedAppVersion,
    $core.bool? autoSubmit,
    $fixnum.Int64? lastPatchedTsMs,
    $fixnum.Int64? createdTsMs,
    $fixnum.Int64? updatedTsMs,
    $fixnum.Int64? deletedTsMs,
  }) {
    final result = Skill._();
    if (id != null) result.id = id;
    if (ownerIid != null) result.ownerIid = ownerIid;
    if (scope != null) result.scope = scope;
    if (deviceIid != null) result.deviceIid = deviceIid;
    if (teamIid != null) result.teamIid = teamIid;
    if (title != null) result.title = title;
    if (hashBlake3 != null) result.hashBlake3 = hashBlake3;
    if (bodyMd != null) result.bodyMd = bodyMd;
    if (source != null) result.source = source;
    if (catalogId != null) result.catalogId = catalogId;
    if (catalogVariantId != null) result.catalogVariantId = catalogVariantId;
    if (catalogReleaseId != null) result.catalogReleaseId = catalogReleaseId;
    if (authorName != null) result.authorName = authorName;
    if (tagsJson != null) result.tagsJson = tagsJson;
    if (phrasesJson != null) result.phrasesJson = phrasesJson;
    if (autoRun != null) result.autoRun = autoRun;
    if (surface != null) result.surface = surface;
    if (targetApp != null) result.targetApp = targetApp;
    if (urlPattern != null) result.urlPattern = urlPattern;
    if (steps != null) result.steps.addAll(steps);
    if (patchEpoch != null) result.patchEpoch = patchEpoch;
    if (patchCount != null) result.patchCount = patchCount;
    if (consecutiveOk != null) result.consecutiveOk = consecutiveOk;
    if (detectedAppVersion != null)
      result.detectedAppVersion = detectedAppVersion;
    if (autoSubmit != null) result.autoSubmit = autoSubmit;
    if (lastPatchedTsMs != null) result.lastPatchedTsMs = lastPatchedTsMs;
    if (createdTsMs != null) result.createdTsMs = createdTsMs;
    if (updatedTsMs != null) result.updatedTsMs = updatedTsMs;
    if (deletedTsMs != null) result.deletedTsMs = deletedTsMs;
    return result;
  }

  Skill._();

  factory Skill.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Skill()..mergeFromBuffer(data, registry);
  factory Skill.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Skill()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Skill',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: Skill.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..aInt64(2, _omitFieldNames ? '' : 'ownerIid')
    ..aE<SkillScope>(3, _omitFieldNames ? '' : 'scope',
        enumValues: SkillScope.values)
    ..aInt64(4, _omitFieldNames ? '' : 'deviceIid')
    ..aInt64(5, _omitFieldNames ? '' : 'teamIid')
    ..aOS(6, _omitFieldNames ? '' : 'title')
    ..aOS(7, _omitFieldNames ? '' : 'hashBlake3')
    ..aOS(8, _omitFieldNames ? '' : 'bodyMd')
    ..aE<SkillSource>(9, _omitFieldNames ? '' : 'source',
        enumValues: SkillSource.values)
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
    ..pPM<SkillStep>(20, _omitFieldNames ? '' : 'steps',
        subBuilder: SkillStep.$_createMessage)
    ..aI(21, _omitFieldNames ? '' : 'patchEpoch')
    ..aI(22, _omitFieldNames ? '' : 'patchCount')
    ..aI(23, _omitFieldNames ? '' : 'consecutiveOk')
    ..aOS(24, _omitFieldNames ? '' : 'detectedAppVersion')
    ..aOB(25, _omitFieldNames ? '' : 'autoSubmit')
    ..aInt64(26, _omitFieldNames ? '' : 'lastPatchedTsMs')
    ..aInt64(30, _omitFieldNames ? '' : 'createdTsMs')
    ..aInt64(31, _omitFieldNames ? '' : 'updatedTsMs')
    ..aInt64(32, _omitFieldNames ? '' : 'deletedTsMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Skill clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Skill copyWith(void Function(Skill) updates) =>
      super.copyWith((message) => updates(message as Skill)) as Skill;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Skill() / Skill.new instead')
  static Skill create() => Skill._();
  static $pb.GeneratedMessage $_createMessage() => Skill._();
  @$core.override
  Skill createEmptyInstance() => Skill._();
  @$core.pragma('dart2js:noInline')
  static Skill getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Skill>(Skill.$_createMessage);
  static Skill? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get ownerIid => $_getI64(1);
  @$pb.TagNumber(2)
  set ownerIid($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOwnerIid() => $_has(1);
  @$pb.TagNumber(2)
  void clearOwnerIid() => $_clearField(2);

  @$pb.TagNumber(3)
  SkillScope get scope => $_getN(2);
  @$pb.TagNumber(3)
  set scope(SkillScope value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasScope() => $_has(2);
  @$pb.TagNumber(3)
  void clearScope() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get deviceIid => $_getI64(3);
  @$pb.TagNumber(4)
  set deviceIid($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDeviceIid() => $_has(3);
  @$pb.TagNumber(4)
  void clearDeviceIid() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get teamIid => $_getI64(4);
  @$pb.TagNumber(5)
  set teamIid($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasTeamIid() => $_has(4);
  @$pb.TagNumber(5)
  void clearTeamIid() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get title => $_getSZ(5);
  @$pb.TagNumber(6)
  set title($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasTitle() => $_has(5);
  @$pb.TagNumber(6)
  void clearTitle() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get hashBlake3 => $_getSZ(6);
  @$pb.TagNumber(7)
  set hashBlake3($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasHashBlake3() => $_has(6);
  @$pb.TagNumber(7)
  void clearHashBlake3() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get bodyMd => $_getSZ(7);
  @$pb.TagNumber(8)
  set bodyMd($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasBodyMd() => $_has(7);
  @$pb.TagNumber(8)
  void clearBodyMd() => $_clearField(8);

  @$pb.TagNumber(9)
  SkillSource get source => $_getN(8);
  @$pb.TagNumber(9)
  set source(SkillSource value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasSource() => $_has(8);
  @$pb.TagNumber(9)
  void clearSource() => $_clearField(9);

  @$pb.TagNumber(10)
  $fixnum.Int64 get catalogId => $_getI64(9);
  @$pb.TagNumber(10)
  set catalogId($fixnum.Int64 value) => $_setInt64(9, value);
  @$pb.TagNumber(10)
  $core.bool hasCatalogId() => $_has(9);
  @$pb.TagNumber(10)
  void clearCatalogId() => $_clearField(10);

  @$pb.TagNumber(11)
  $fixnum.Int64 get catalogVariantId => $_getI64(10);
  @$pb.TagNumber(11)
  set catalogVariantId($fixnum.Int64 value) => $_setInt64(10, value);
  @$pb.TagNumber(11)
  $core.bool hasCatalogVariantId() => $_has(10);
  @$pb.TagNumber(11)
  void clearCatalogVariantId() => $_clearField(11);

  @$pb.TagNumber(12)
  $fixnum.Int64 get catalogReleaseId => $_getI64(11);
  @$pb.TagNumber(12)
  set catalogReleaseId($fixnum.Int64 value) => $_setInt64(11, value);
  @$pb.TagNumber(12)
  $core.bool hasCatalogReleaseId() => $_has(11);
  @$pb.TagNumber(12)
  void clearCatalogReleaseId() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.String get authorName => $_getSZ(12);
  @$pb.TagNumber(13)
  set authorName($core.String value) => $_setString(12, value);
  @$pb.TagNumber(13)
  $core.bool hasAuthorName() => $_has(12);
  @$pb.TagNumber(13)
  void clearAuthorName() => $_clearField(13);

  @$pb.TagNumber(14)
  $core.String get tagsJson => $_getSZ(13);
  @$pb.TagNumber(14)
  set tagsJson($core.String value) => $_setString(13, value);
  @$pb.TagNumber(14)
  $core.bool hasTagsJson() => $_has(13);
  @$pb.TagNumber(14)
  void clearTagsJson() => $_clearField(14);

  @$pb.TagNumber(15)
  $core.String get phrasesJson => $_getSZ(14);
  @$pb.TagNumber(15)
  set phrasesJson($core.String value) => $_setString(14, value);
  @$pb.TagNumber(15)
  $core.bool hasPhrasesJson() => $_has(14);
  @$pb.TagNumber(15)
  void clearPhrasesJson() => $_clearField(15);

  @$pb.TagNumber(16)
  $core.bool get autoRun => $_getBF(15);
  @$pb.TagNumber(16)
  set autoRun($core.bool value) => $_setBool(15, value);
  @$pb.TagNumber(16)
  $core.bool hasAutoRun() => $_has(15);
  @$pb.TagNumber(16)
  void clearAutoRun() => $_clearField(16);

  @$pb.TagNumber(17)
  $core.String get surface => $_getSZ(16);
  @$pb.TagNumber(17)
  set surface($core.String value) => $_setString(16, value);
  @$pb.TagNumber(17)
  $core.bool hasSurface() => $_has(16);
  @$pb.TagNumber(17)
  void clearSurface() => $_clearField(17);

  @$pb.TagNumber(18)
  $core.String get targetApp => $_getSZ(17);
  @$pb.TagNumber(18)
  set targetApp($core.String value) => $_setString(17, value);
  @$pb.TagNumber(18)
  $core.bool hasTargetApp() => $_has(17);
  @$pb.TagNumber(18)
  void clearTargetApp() => $_clearField(18);

  @$pb.TagNumber(19)
  $core.String get urlPattern => $_getSZ(18);
  @$pb.TagNumber(19)
  set urlPattern($core.String value) => $_setString(18, value);
  @$pb.TagNumber(19)
  $core.bool hasUrlPattern() => $_has(18);
  @$pb.TagNumber(19)
  void clearUrlPattern() => $_clearField(19);

  @$pb.TagNumber(20)
  $pb.PbList<SkillStep> get steps => $_getList(19);

  @$pb.TagNumber(21)
  $core.int get patchEpoch => $_getIZ(20);
  @$pb.TagNumber(21)
  set patchEpoch($core.int value) => $_setSignedInt32(20, value);
  @$pb.TagNumber(21)
  $core.bool hasPatchEpoch() => $_has(20);
  @$pb.TagNumber(21)
  void clearPatchEpoch() => $_clearField(21);

  @$pb.TagNumber(22)
  $core.int get patchCount => $_getIZ(21);
  @$pb.TagNumber(22)
  set patchCount($core.int value) => $_setSignedInt32(21, value);
  @$pb.TagNumber(22)
  $core.bool hasPatchCount() => $_has(21);
  @$pb.TagNumber(22)
  void clearPatchCount() => $_clearField(22);

  @$pb.TagNumber(23)
  $core.int get consecutiveOk => $_getIZ(22);
  @$pb.TagNumber(23)
  set consecutiveOk($core.int value) => $_setSignedInt32(22, value);
  @$pb.TagNumber(23)
  $core.bool hasConsecutiveOk() => $_has(22);
  @$pb.TagNumber(23)
  void clearConsecutiveOk() => $_clearField(23);

  @$pb.TagNumber(24)
  $core.String get detectedAppVersion => $_getSZ(23);
  @$pb.TagNumber(24)
  set detectedAppVersion($core.String value) => $_setString(23, value);
  @$pb.TagNumber(24)
  $core.bool hasDetectedAppVersion() => $_has(23);
  @$pb.TagNumber(24)
  void clearDetectedAppVersion() => $_clearField(24);

  @$pb.TagNumber(25)
  $core.bool get autoSubmit => $_getBF(24);
  @$pb.TagNumber(25)
  set autoSubmit($core.bool value) => $_setBool(24, value);
  @$pb.TagNumber(25)
  $core.bool hasAutoSubmit() => $_has(24);
  @$pb.TagNumber(25)
  void clearAutoSubmit() => $_clearField(25);

  @$pb.TagNumber(26)
  $fixnum.Int64 get lastPatchedTsMs => $_getI64(25);
  @$pb.TagNumber(26)
  set lastPatchedTsMs($fixnum.Int64 value) => $_setInt64(25, value);
  @$pb.TagNumber(26)
  $core.bool hasLastPatchedTsMs() => $_has(25);
  @$pb.TagNumber(26)
  void clearLastPatchedTsMs() => $_clearField(26);

  @$pb.TagNumber(30)
  $fixnum.Int64 get createdTsMs => $_getI64(26);
  @$pb.TagNumber(30)
  set createdTsMs($fixnum.Int64 value) => $_setInt64(26, value);
  @$pb.TagNumber(30)
  $core.bool hasCreatedTsMs() => $_has(26);
  @$pb.TagNumber(30)
  void clearCreatedTsMs() => $_clearField(30);

  @$pb.TagNumber(31)
  $fixnum.Int64 get updatedTsMs => $_getI64(27);
  @$pb.TagNumber(31)
  set updatedTsMs($fixnum.Int64 value) => $_setInt64(27, value);
  @$pb.TagNumber(31)
  $core.bool hasUpdatedTsMs() => $_has(27);
  @$pb.TagNumber(31)
  void clearUpdatedTsMs() => $_clearField(31);

  @$pb.TagNumber(32)
  $fixnum.Int64 get deletedTsMs => $_getI64(28);
  @$pb.TagNumber(32)
  set deletedTsMs($fixnum.Int64 value) => $_setInt64(28, value);
  @$pb.TagNumber(32)
  $core.bool hasDeletedTsMs() => $_has(28);
  @$pb.TagNumber(32)
  void clearDeletedTsMs() => $_clearField(32);
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
    final result = SkillStep._();
    if (id != null) result.id = id;
    if (skillId != null) result.skillId = skillId;
    if (ownerIid != null) result.ownerIid = ownerIid;
    if (ord != null) result.ord = ord;
    if (kind != null) result.kind = kind;
    if (label != null) result.label = label;
    if (axTargetJson != null) result.axTargetJson = axTargetJson;
    if (screenshotHash != null) result.screenshotHash = screenshotHash;
    if (comment != null) result.comment = comment;
    if (secretId != null) result.secretId = secretId;
    if (tapeLocalOnlyJson != null) result.tapeLocalOnlyJson = tapeLocalOnlyJson;
    if (createdTsMs != null) result.createdTsMs = createdTsMs;
    if (updatedTsMs != null) result.updatedTsMs = updatedTsMs;
    if (deletedTsMs != null) result.deletedTsMs = deletedTsMs;
    return result;
  }

  SkillStep._();

  factory SkillStep.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SkillStep()..mergeFromBuffer(data, registry);
  factory SkillStep.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SkillStep()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SkillStep',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: SkillStep.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..aInt64(2, _omitFieldNames ? '' : 'skillId')
    ..aInt64(3, _omitFieldNames ? '' : 'ownerIid')
    ..aI(4, _omitFieldNames ? '' : 'ord')
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
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SkillStep clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SkillStep copyWith(void Function(SkillStep) updates) =>
      super.copyWith((message) => updates(message as SkillStep)) as SkillStep;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SkillStep() / SkillStep.new instead')
  static SkillStep create() => SkillStep._();
  static $pb.GeneratedMessage $_createMessage() => SkillStep._();
  @$core.override
  SkillStep createEmptyInstance() => SkillStep._();
  @$core.pragma('dart2js:noInline')
  static SkillStep getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SkillStep>(SkillStep.$_createMessage);
  static SkillStep? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get skillId => $_getI64(1);
  @$pb.TagNumber(2)
  set skillId($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSkillId() => $_has(1);
  @$pb.TagNumber(2)
  void clearSkillId() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get ownerIid => $_getI64(2);
  @$pb.TagNumber(3)
  set ownerIid($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasOwnerIid() => $_has(2);
  @$pb.TagNumber(3)
  void clearOwnerIid() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get ord => $_getIZ(3);
  @$pb.TagNumber(4)
  set ord($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasOrd() => $_has(3);
  @$pb.TagNumber(4)
  void clearOrd() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get kind => $_getSZ(4);
  @$pb.TagNumber(5)
  set kind($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasKind() => $_has(4);
  @$pb.TagNumber(5)
  void clearKind() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get label => $_getSZ(5);
  @$pb.TagNumber(6)
  set label($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasLabel() => $_has(5);
  @$pb.TagNumber(6)
  void clearLabel() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get axTargetJson => $_getSZ(6);
  @$pb.TagNumber(7)
  set axTargetJson($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasAxTargetJson() => $_has(6);
  @$pb.TagNumber(7)
  void clearAxTargetJson() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get screenshotHash => $_getSZ(7);
  @$pb.TagNumber(8)
  set screenshotHash($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasScreenshotHash() => $_has(7);
  @$pb.TagNumber(8)
  void clearScreenshotHash() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get comment => $_getSZ(8);
  @$pb.TagNumber(9)
  set comment($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasComment() => $_has(8);
  @$pb.TagNumber(9)
  void clearComment() => $_clearField(9);

  @$pb.TagNumber(10)
  $fixnum.Int64 get secretId => $_getI64(9);
  @$pb.TagNumber(10)
  set secretId($fixnum.Int64 value) => $_setInt64(9, value);
  @$pb.TagNumber(10)
  $core.bool hasSecretId() => $_has(9);
  @$pb.TagNumber(10)
  void clearSecretId() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.String get tapeLocalOnlyJson => $_getSZ(10);
  @$pb.TagNumber(11)
  set tapeLocalOnlyJson($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasTapeLocalOnlyJson() => $_has(10);
  @$pb.TagNumber(11)
  void clearTapeLocalOnlyJson() => $_clearField(11);

  @$pb.TagNumber(20)
  $fixnum.Int64 get createdTsMs => $_getI64(11);
  @$pb.TagNumber(20)
  set createdTsMs($fixnum.Int64 value) => $_setInt64(11, value);
  @$pb.TagNumber(20)
  $core.bool hasCreatedTsMs() => $_has(11);
  @$pb.TagNumber(20)
  void clearCreatedTsMs() => $_clearField(20);

  @$pb.TagNumber(21)
  $fixnum.Int64 get updatedTsMs => $_getI64(12);
  @$pb.TagNumber(21)
  set updatedTsMs($fixnum.Int64 value) => $_setInt64(12, value);
  @$pb.TagNumber(21)
  $core.bool hasUpdatedTsMs() => $_has(12);
  @$pb.TagNumber(21)
  void clearUpdatedTsMs() => $_clearField(21);

  @$pb.TagNumber(22)
  $fixnum.Int64 get deletedTsMs => $_getI64(13);
  @$pb.TagNumber(22)
  set deletedTsMs($fixnum.Int64 value) => $_setInt64(13, value);
  @$pb.TagNumber(22)
  $core.bool hasDeletedTsMs() => $_has(13);
  @$pb.TagNumber(22)
  void clearDeletedTsMs() => $_clearField(22);
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
    $core.double? priceUsd,
    $core.double? priceIdr,
    $core.String? billingPeriod,
  }) {
    final result = SkillCatalog._();
    if (id != null) result.id = id;
    if (authorIid != null) result.authorIid = authorIid;
    if (authorName != null) result.authorName = authorName;
    if (slug != null) result.slug = slug;
    if (title != null) result.title = title;
    if (summary != null) result.summary = summary;
    if (bodyMd != null) result.bodyMd = bodyMd;
    if (tagsJson != null) result.tagsJson = tagsJson;
    if (installCount != null) result.installCount = installCount;
    if (rating != null) result.rating = rating;
    if (isVerified != null) result.isVerified = isVerified;
    if (status != null) result.status = status;
    if (priceUsd != null) result.priceUsd = priceUsd;
    if (priceIdr != null) result.priceIdr = priceIdr;
    if (billingPeriod != null) result.billingPeriod = billingPeriod;
    return result;
  }

  SkillCatalog._();

  factory SkillCatalog.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SkillCatalog()..mergeFromBuffer(data, registry);
  factory SkillCatalog.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SkillCatalog()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SkillCatalog',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: SkillCatalog.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..aInt64(2, _omitFieldNames ? '' : 'authorIid')
    ..aOS(3, _omitFieldNames ? '' : 'authorName')
    ..aOS(4, _omitFieldNames ? '' : 'slug')
    ..aOS(5, _omitFieldNames ? '' : 'title')
    ..aOS(6, _omitFieldNames ? '' : 'summary')
    ..aOS(7, _omitFieldNames ? '' : 'bodyMd')
    ..aOS(8, _omitFieldNames ? '' : 'tagsJson')
    ..aI(9, _omitFieldNames ? '' : 'installCount')
    ..aD(10, _omitFieldNames ? '' : 'rating')
    ..aOB(11, _omitFieldNames ? '' : 'isVerified')
    ..aOS(12, _omitFieldNames ? '' : 'status')
    ..aD(13, _omitFieldNames ? '' : 'priceUsd')
    ..aD(14, _omitFieldNames ? '' : 'priceIdr')
    ..aOS(15, _omitFieldNames ? '' : 'billingPeriod')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SkillCatalog clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SkillCatalog copyWith(void Function(SkillCatalog) updates) =>
      super.copyWith((message) => updates(message as SkillCatalog))
          as SkillCatalog;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SkillCatalog() / SkillCatalog.new instead')
  static SkillCatalog create() => SkillCatalog._();
  static $pb.GeneratedMessage $_createMessage() => SkillCatalog._();
  @$core.override
  SkillCatalog createEmptyInstance() => SkillCatalog._();
  @$core.pragma('dart2js:noInline')
  static SkillCatalog getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SkillCatalog>(
          SkillCatalog.$_createMessage);
  static SkillCatalog? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get authorIid => $_getI64(1);
  @$pb.TagNumber(2)
  set authorIid($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAuthorIid() => $_has(1);
  @$pb.TagNumber(2)
  void clearAuthorIid() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get authorName => $_getSZ(2);
  @$pb.TagNumber(3)
  set authorName($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAuthorName() => $_has(2);
  @$pb.TagNumber(3)
  void clearAuthorName() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get slug => $_getSZ(3);
  @$pb.TagNumber(4)
  set slug($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSlug() => $_has(3);
  @$pb.TagNumber(4)
  void clearSlug() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get title => $_getSZ(4);
  @$pb.TagNumber(5)
  set title($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasTitle() => $_has(4);
  @$pb.TagNumber(5)
  void clearTitle() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get summary => $_getSZ(5);
  @$pb.TagNumber(6)
  set summary($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasSummary() => $_has(5);
  @$pb.TagNumber(6)
  void clearSummary() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get bodyMd => $_getSZ(6);
  @$pb.TagNumber(7)
  set bodyMd($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasBodyMd() => $_has(6);
  @$pb.TagNumber(7)
  void clearBodyMd() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get tagsJson => $_getSZ(7);
  @$pb.TagNumber(8)
  set tagsJson($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasTagsJson() => $_has(7);
  @$pb.TagNumber(8)
  void clearTagsJson() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.int get installCount => $_getIZ(8);
  @$pb.TagNumber(9)
  set installCount($core.int value) => $_setSignedInt32(8, value);
  @$pb.TagNumber(9)
  $core.bool hasInstallCount() => $_has(8);
  @$pb.TagNumber(9)
  void clearInstallCount() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.double get rating => $_getN(9);
  @$pb.TagNumber(10)
  set rating($core.double value) => $_setDouble(9, value);
  @$pb.TagNumber(10)
  $core.bool hasRating() => $_has(9);
  @$pb.TagNumber(10)
  void clearRating() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.bool get isVerified => $_getBF(10);
  @$pb.TagNumber(11)
  set isVerified($core.bool value) => $_setBool(10, value);
  @$pb.TagNumber(11)
  $core.bool hasIsVerified() => $_has(10);
  @$pb.TagNumber(11)
  void clearIsVerified() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.String get status => $_getSZ(11);
  @$pb.TagNumber(12)
  set status($core.String value) => $_setString(11, value);
  @$pb.TagNumber(12)
  $core.bool hasStatus() => $_has(11);
  @$pb.TagNumber(12)
  void clearStatus() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.double get priceUsd => $_getN(12);
  @$pb.TagNumber(13)
  set priceUsd($core.double value) => $_setDouble(12, value);
  @$pb.TagNumber(13)
  $core.bool hasPriceUsd() => $_has(12);
  @$pb.TagNumber(13)
  void clearPriceUsd() => $_clearField(13);

  @$pb.TagNumber(14)
  $core.double get priceIdr => $_getN(13);
  @$pb.TagNumber(14)
  set priceIdr($core.double value) => $_setDouble(13, value);
  @$pb.TagNumber(14)
  $core.bool hasPriceIdr() => $_has(13);
  @$pb.TagNumber(14)
  void clearPriceIdr() => $_clearField(14);

  @$pb.TagNumber(15)
  $core.String get billingPeriod => $_getSZ(14);
  @$pb.TagNumber(15)
  set billingPeriod($core.String value) => $_setString(14, value);
  @$pb.TagNumber(15)
  $core.bool hasBillingPeriod() => $_has(14);
  @$pb.TagNumber(15)
  void clearBillingPeriod() => $_clearField(15);
}

class ReqSkillList extends $pb.GeneratedMessage {
  factory ReqSkillList({
    SkillScope? scope,
    $fixnum.Int64? deviceIid,
    $fixnum.Int64? teamIid,
    $fixnum.Int64? sinceMs,
  }) {
    final result = ReqSkillList._();
    if (scope != null) result.scope = scope;
    if (deviceIid != null) result.deviceIid = deviceIid;
    if (teamIid != null) result.teamIid = teamIid;
    if (sinceMs != null) result.sinceMs = sinceMs;
    return result;
  }

  ReqSkillList._();

  factory ReqSkillList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSkillList()..mergeFromBuffer(data, registry);
  factory ReqSkillList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSkillList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqSkillList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqSkillList.$_createMessage)
    ..aE<SkillScope>(1, _omitFieldNames ? '' : 'scope',
        enumValues: SkillScope.values)
    ..aInt64(2, _omitFieldNames ? '' : 'deviceIid')
    ..aInt64(3, _omitFieldNames ? '' : 'teamIid')
    ..aInt64(4, _omitFieldNames ? '' : 'sinceMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSkillList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSkillList copyWith(void Function(ReqSkillList) updates) =>
      super.copyWith((message) => updates(message as ReqSkillList))
          as ReqSkillList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqSkillList() / ReqSkillList.new instead')
  static ReqSkillList create() => ReqSkillList._();
  static $pb.GeneratedMessage $_createMessage() => ReqSkillList._();
  @$core.override
  ReqSkillList createEmptyInstance() => ReqSkillList._();
  @$core.pragma('dart2js:noInline')
  static ReqSkillList getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqSkillList>(
          ReqSkillList.$_createMessage);
  static ReqSkillList? _defaultInstance;

  @$pb.TagNumber(1)
  SkillScope get scope => $_getN(0);
  @$pb.TagNumber(1)
  set scope(SkillScope value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasScope() => $_has(0);
  @$pb.TagNumber(1)
  void clearScope() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get deviceIid => $_getI64(1);
  @$pb.TagNumber(2)
  set deviceIid($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDeviceIid() => $_has(1);
  @$pb.TagNumber(2)
  void clearDeviceIid() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get teamIid => $_getI64(2);
  @$pb.TagNumber(3)
  set teamIid($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTeamIid() => $_has(2);
  @$pb.TagNumber(3)
  void clearTeamIid() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get sinceMs => $_getI64(3);
  @$pb.TagNumber(4)
  set sinceMs($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSinceMs() => $_has(3);
  @$pb.TagNumber(4)
  void clearSinceMs() => $_clearField(4);
}

class ResSkillList extends $pb.GeneratedMessage {
  factory ResSkillList({
    $core.Iterable<Skill>? skills,
  }) {
    final result = ResSkillList._();
    if (skills != null) result.skills.addAll(skills);
    return result;
  }

  ResSkillList._();

  factory ResSkillList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSkillList()..mergeFromBuffer(data, registry);
  factory ResSkillList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSkillList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResSkillList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResSkillList.$_createMessage)
    ..pPM<Skill>(1, _omitFieldNames ? '' : 'skills',
        subBuilder: Skill.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSkillList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSkillList copyWith(void Function(ResSkillList) updates) =>
      super.copyWith((message) => updates(message as ResSkillList))
          as ResSkillList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResSkillList() / ResSkillList.new instead')
  static ResSkillList create() => ResSkillList._();
  static $pb.GeneratedMessage $_createMessage() => ResSkillList._();
  @$core.override
  ResSkillList createEmptyInstance() => ResSkillList._();
  @$core.pragma('dart2js:noInline')
  static ResSkillList getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResSkillList>(
          ResSkillList.$_createMessage);
  static ResSkillList? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Skill> get skills => $_getList(0);
}

class ReqSkillGet extends $pb.GeneratedMessage {
  factory ReqSkillGet({
    $fixnum.Int64? id,
  }) {
    final result = ReqSkillGet._();
    if (id != null) result.id = id;
    return result;
  }

  ReqSkillGet._();

  factory ReqSkillGet.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSkillGet()..mergeFromBuffer(data, registry);
  factory ReqSkillGet.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSkillGet()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqSkillGet',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqSkillGet.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSkillGet clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSkillGet copyWith(void Function(ReqSkillGet) updates) =>
      super.copyWith((message) => updates(message as ReqSkillGet))
          as ReqSkillGet;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqSkillGet() / ReqSkillGet.new instead')
  static ReqSkillGet create() => ReqSkillGet._();
  static $pb.GeneratedMessage $_createMessage() => ReqSkillGet._();
  @$core.override
  ReqSkillGet createEmptyInstance() => ReqSkillGet._();
  @$core.pragma('dart2js:noInline')
  static ReqSkillGet getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqSkillGet>(
          ReqSkillGet.$_createMessage);
  static ReqSkillGet? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);
}

class ResSkillGet extends $pb.GeneratedMessage {
  factory ResSkillGet({
    Skill? skill,
  }) {
    final result = ResSkillGet._();
    if (skill != null) result.skill = skill;
    return result;
  }

  ResSkillGet._();

  factory ResSkillGet.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSkillGet()..mergeFromBuffer(data, registry);
  factory ResSkillGet.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSkillGet()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResSkillGet',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResSkillGet.$_createMessage)
    ..aOM<Skill>(1, _omitFieldNames ? '' : 'skill',
        subBuilder: Skill.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSkillGet clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSkillGet copyWith(void Function(ResSkillGet) updates) =>
      super.copyWith((message) => updates(message as ResSkillGet))
          as ResSkillGet;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResSkillGet() / ResSkillGet.new instead')
  static ResSkillGet create() => ResSkillGet._();
  static $pb.GeneratedMessage $_createMessage() => ResSkillGet._();
  @$core.override
  ResSkillGet createEmptyInstance() => ResSkillGet._();
  @$core.pragma('dart2js:noInline')
  static ResSkillGet getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResSkillGet>(
          ResSkillGet.$_createMessage);
  static ResSkillGet? _defaultInstance;

  @$pb.TagNumber(1)
  Skill get skill => $_getN(0);
  @$pb.TagNumber(1)
  set skill(Skill value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSkill() => $_has(0);
  @$pb.TagNumber(1)
  void clearSkill() => $_clearField(1);
  @$pb.TagNumber(1)
  Skill ensureSkill() => $_ensure(0);
}

class ReqSkillPut extends $pb.GeneratedMessage {
  factory ReqSkillPut({
    Skill? skill,
  }) {
    final result = ReqSkillPut._();
    if (skill != null) result.skill = skill;
    return result;
  }

  ReqSkillPut._();

  factory ReqSkillPut.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSkillPut()..mergeFromBuffer(data, registry);
  factory ReqSkillPut.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSkillPut()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqSkillPut',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqSkillPut.$_createMessage)
    ..aOM<Skill>(1, _omitFieldNames ? '' : 'skill',
        subBuilder: Skill.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSkillPut clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSkillPut copyWith(void Function(ReqSkillPut) updates) =>
      super.copyWith((message) => updates(message as ReqSkillPut))
          as ReqSkillPut;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqSkillPut() / ReqSkillPut.new instead')
  static ReqSkillPut create() => ReqSkillPut._();
  static $pb.GeneratedMessage $_createMessage() => ReqSkillPut._();
  @$core.override
  ReqSkillPut createEmptyInstance() => ReqSkillPut._();
  @$core.pragma('dart2js:noInline')
  static ReqSkillPut getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqSkillPut>(
          ReqSkillPut.$_createMessage);
  static ReqSkillPut? _defaultInstance;

  @$pb.TagNumber(1)
  Skill get skill => $_getN(0);
  @$pb.TagNumber(1)
  set skill(Skill value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSkill() => $_has(0);
  @$pb.TagNumber(1)
  void clearSkill() => $_clearField(1);
  @$pb.TagNumber(1)
  Skill ensureSkill() => $_ensure(0);
}

class ResSkillPut extends $pb.GeneratedMessage {
  factory ResSkillPut({
    Skill? skill,
  }) {
    final result = ResSkillPut._();
    if (skill != null) result.skill = skill;
    return result;
  }

  ResSkillPut._();

  factory ResSkillPut.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSkillPut()..mergeFromBuffer(data, registry);
  factory ResSkillPut.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSkillPut()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResSkillPut',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResSkillPut.$_createMessage)
    ..aOM<Skill>(1, _omitFieldNames ? '' : 'skill',
        subBuilder: Skill.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSkillPut clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSkillPut copyWith(void Function(ResSkillPut) updates) =>
      super.copyWith((message) => updates(message as ResSkillPut))
          as ResSkillPut;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResSkillPut() / ResSkillPut.new instead')
  static ResSkillPut create() => ResSkillPut._();
  static $pb.GeneratedMessage $_createMessage() => ResSkillPut._();
  @$core.override
  ResSkillPut createEmptyInstance() => ResSkillPut._();
  @$core.pragma('dart2js:noInline')
  static ResSkillPut getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResSkillPut>(
          ResSkillPut.$_createMessage);
  static ResSkillPut? _defaultInstance;

  @$pb.TagNumber(1)
  Skill get skill => $_getN(0);
  @$pb.TagNumber(1)
  set skill(Skill value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSkill() => $_has(0);
  @$pb.TagNumber(1)
  void clearSkill() => $_clearField(1);
  @$pb.TagNumber(1)
  Skill ensureSkill() => $_ensure(0);
}

class ReqSkillCatalogList extends $pb.GeneratedMessage {
  factory ReqSkillCatalogList({
    $core.String? q,
    $core.int? limit,
  }) {
    final result = ReqSkillCatalogList._();
    if (q != null) result.q = q;
    if (limit != null) result.limit = limit;
    return result;
  }

  ReqSkillCatalogList._();

  factory ReqSkillCatalogList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSkillCatalogList()..mergeFromBuffer(data, registry);
  factory ReqSkillCatalogList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSkillCatalogList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqSkillCatalogList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqSkillCatalogList.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'q')
    ..aI(2, _omitFieldNames ? '' : 'limit')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSkillCatalogList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSkillCatalogList copyWith(void Function(ReqSkillCatalogList) updates) =>
      super.copyWith((message) => updates(message as ReqSkillCatalogList))
          as ReqSkillCatalogList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use ReqSkillCatalogList() / ReqSkillCatalogList.new instead')
  static ReqSkillCatalogList create() => ReqSkillCatalogList._();
  static $pb.GeneratedMessage $_createMessage() => ReqSkillCatalogList._();
  @$core.override
  ReqSkillCatalogList createEmptyInstance() => ReqSkillCatalogList._();
  @$core.pragma('dart2js:noInline')
  static ReqSkillCatalogList getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqSkillCatalogList>(
          ReqSkillCatalogList.$_createMessage);
  static ReqSkillCatalogList? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get q => $_getSZ(0);
  @$pb.TagNumber(1)
  set q($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasQ() => $_has(0);
  @$pb.TagNumber(1)
  void clearQ() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get limit => $_getIZ(1);
  @$pb.TagNumber(2)
  set limit($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLimit() => $_has(1);
  @$pb.TagNumber(2)
  void clearLimit() => $_clearField(2);
}

class ResSkillCatalogList extends $pb.GeneratedMessage {
  factory ResSkillCatalogList({
    $core.Iterable<SkillCatalog>? catalogs,
  }) {
    final result = ResSkillCatalogList._();
    if (catalogs != null) result.catalogs.addAll(catalogs);
    return result;
  }

  ResSkillCatalogList._();

  factory ResSkillCatalogList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSkillCatalogList()..mergeFromBuffer(data, registry);
  factory ResSkillCatalogList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSkillCatalogList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResSkillCatalogList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResSkillCatalogList.$_createMessage)
    ..pPM<SkillCatalog>(1, _omitFieldNames ? '' : 'catalogs',
        subBuilder: SkillCatalog.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSkillCatalogList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSkillCatalogList copyWith(void Function(ResSkillCatalogList) updates) =>
      super.copyWith((message) => updates(message as ResSkillCatalogList))
          as ResSkillCatalogList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use ResSkillCatalogList() / ResSkillCatalogList.new instead')
  static ResSkillCatalogList create() => ResSkillCatalogList._();
  static $pb.GeneratedMessage $_createMessage() => ResSkillCatalogList._();
  @$core.override
  ResSkillCatalogList createEmptyInstance() => ResSkillCatalogList._();
  @$core.pragma('dart2js:noInline')
  static ResSkillCatalogList getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResSkillCatalogList>(
          ResSkillCatalogList.$_createMessage);
  static ResSkillCatalogList? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<SkillCatalog> get catalogs => $_getList(0);
}

class ReqSkillCatalogInstall extends $pb.GeneratedMessage {
  factory ReqSkillCatalogInstall({
    $fixnum.Int64? catalogId,
    $fixnum.Int64? variantId,
    $fixnum.Int64? releaseId,
    SkillScope? scope,
    $fixnum.Int64? deviceIid,
  }) {
    final result = ReqSkillCatalogInstall._();
    if (catalogId != null) result.catalogId = catalogId;
    if (variantId != null) result.variantId = variantId;
    if (releaseId != null) result.releaseId = releaseId;
    if (scope != null) result.scope = scope;
    if (deviceIid != null) result.deviceIid = deviceIid;
    return result;
  }

  ReqSkillCatalogInstall._();

  factory ReqSkillCatalogInstall.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSkillCatalogInstall()..mergeFromBuffer(data, registry);
  factory ReqSkillCatalogInstall.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSkillCatalogInstall()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqSkillCatalogInstall',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqSkillCatalogInstall.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'catalogId')
    ..aInt64(2, _omitFieldNames ? '' : 'variantId')
    ..aInt64(3, _omitFieldNames ? '' : 'releaseId')
    ..aE<SkillScope>(4, _omitFieldNames ? '' : 'scope',
        enumValues: SkillScope.values)
    ..aInt64(5, _omitFieldNames ? '' : 'deviceIid')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSkillCatalogInstall clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSkillCatalogInstall copyWith(
          void Function(ReqSkillCatalogInstall) updates) =>
      super.copyWith((message) => updates(message as ReqSkillCatalogInstall))
          as ReqSkillCatalogInstall;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ReqSkillCatalogInstall() / ReqSkillCatalogInstall.new instead')
  static ReqSkillCatalogInstall create() => ReqSkillCatalogInstall._();
  static $pb.GeneratedMessage $_createMessage() => ReqSkillCatalogInstall._();
  @$core.override
  ReqSkillCatalogInstall createEmptyInstance() => ReqSkillCatalogInstall._();
  @$core.pragma('dart2js:noInline')
  static ReqSkillCatalogInstall getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqSkillCatalogInstall>(
          ReqSkillCatalogInstall.$_createMessage);
  static ReqSkillCatalogInstall? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get catalogId => $_getI64(0);
  @$pb.TagNumber(1)
  set catalogId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCatalogId() => $_has(0);
  @$pb.TagNumber(1)
  void clearCatalogId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get variantId => $_getI64(1);
  @$pb.TagNumber(2)
  set variantId($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasVariantId() => $_has(1);
  @$pb.TagNumber(2)
  void clearVariantId() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get releaseId => $_getI64(2);
  @$pb.TagNumber(3)
  set releaseId($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasReleaseId() => $_has(2);
  @$pb.TagNumber(3)
  void clearReleaseId() => $_clearField(3);

  @$pb.TagNumber(4)
  SkillScope get scope => $_getN(3);
  @$pb.TagNumber(4)
  set scope(SkillScope value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasScope() => $_has(3);
  @$pb.TagNumber(4)
  void clearScope() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get deviceIid => $_getI64(4);
  @$pb.TagNumber(5)
  set deviceIid($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasDeviceIid() => $_has(4);
  @$pb.TagNumber(5)
  void clearDeviceIid() => $_clearField(5);
}

class ResSkillCatalogInstall extends $pb.GeneratedMessage {
  factory ResSkillCatalogInstall({
    Skill? skill,
  }) {
    final result = ResSkillCatalogInstall._();
    if (skill != null) result.skill = skill;
    return result;
  }

  ResSkillCatalogInstall._();

  factory ResSkillCatalogInstall.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSkillCatalogInstall()..mergeFromBuffer(data, registry);
  factory ResSkillCatalogInstall.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSkillCatalogInstall()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResSkillCatalogInstall',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResSkillCatalogInstall.$_createMessage)
    ..aOM<Skill>(1, _omitFieldNames ? '' : 'skill',
        subBuilder: Skill.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSkillCatalogInstall clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSkillCatalogInstall copyWith(
          void Function(ResSkillCatalogInstall) updates) =>
      super.copyWith((message) => updates(message as ResSkillCatalogInstall))
          as ResSkillCatalogInstall;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ResSkillCatalogInstall() / ResSkillCatalogInstall.new instead')
  static ResSkillCatalogInstall create() => ResSkillCatalogInstall._();
  static $pb.GeneratedMessage $_createMessage() => ResSkillCatalogInstall._();
  @$core.override
  ResSkillCatalogInstall createEmptyInstance() => ResSkillCatalogInstall._();
  @$core.pragma('dart2js:noInline')
  static ResSkillCatalogInstall getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResSkillCatalogInstall>(
          ResSkillCatalogInstall.$_createMessage);
  static ResSkillCatalogInstall? _defaultInstance;

  @$pb.TagNumber(1)
  Skill get skill => $_getN(0);
  @$pb.TagNumber(1)
  set skill(Skill value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSkill() => $_has(0);
  @$pb.TagNumber(1)
  void clearSkill() => $_clearField(1);
  @$pb.TagNumber(1)
  Skill ensureSkill() => $_ensure(0);
}

/// Phase 7: full-text + tag search of the public skill catalog
class ReqSkillCatalogSearch extends $pb.GeneratedMessage {
  factory ReqSkillCatalogSearch({
    $core.String? q,
    $core.String? tagsJson,
    $core.int? limit,
    $core.int? offset,
  }) {
    final result = ReqSkillCatalogSearch._();
    if (q != null) result.q = q;
    if (tagsJson != null) result.tagsJson = tagsJson;
    if (limit != null) result.limit = limit;
    if (offset != null) result.offset = offset;
    return result;
  }

  ReqSkillCatalogSearch._();

  factory ReqSkillCatalogSearch.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSkillCatalogSearch()..mergeFromBuffer(data, registry);
  factory ReqSkillCatalogSearch.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSkillCatalogSearch()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqSkillCatalogSearch',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqSkillCatalogSearch.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'q')
    ..aOS(2, _omitFieldNames ? '' : 'tagsJson')
    ..aI(3, _omitFieldNames ? '' : 'limit')
    ..aI(4, _omitFieldNames ? '' : 'offset')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSkillCatalogSearch clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSkillCatalogSearch copyWith(
          void Function(ReqSkillCatalogSearch) updates) =>
      super.copyWith((message) => updates(message as ReqSkillCatalogSearch))
          as ReqSkillCatalogSearch;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ReqSkillCatalogSearch() / ReqSkillCatalogSearch.new instead')
  static ReqSkillCatalogSearch create() => ReqSkillCatalogSearch._();
  static $pb.GeneratedMessage $_createMessage() => ReqSkillCatalogSearch._();
  @$core.override
  ReqSkillCatalogSearch createEmptyInstance() => ReqSkillCatalogSearch._();
  @$core.pragma('dart2js:noInline')
  static ReqSkillCatalogSearch getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqSkillCatalogSearch>(
          ReqSkillCatalogSearch.$_createMessage);
  static ReqSkillCatalogSearch? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get q => $_getSZ(0);
  @$pb.TagNumber(1)
  set q($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasQ() => $_has(0);
  @$pb.TagNumber(1)
  void clearQ() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get tagsJson => $_getSZ(1);
  @$pb.TagNumber(2)
  set tagsJson($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTagsJson() => $_has(1);
  @$pb.TagNumber(2)
  void clearTagsJson() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get limit => $_getIZ(2);
  @$pb.TagNumber(3)
  set limit($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLimit() => $_has(2);
  @$pb.TagNumber(3)
  void clearLimit() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get offset => $_getIZ(3);
  @$pb.TagNumber(4)
  set offset($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasOffset() => $_has(3);
  @$pb.TagNumber(4)
  void clearOffset() => $_clearField(4);
}

class ResSkillCatalogSearch extends $pb.GeneratedMessage {
  factory ResSkillCatalogSearch({
    $core.Iterable<SkillCatalog>? catalogs,
    $core.int? total,
  }) {
    final result = ResSkillCatalogSearch._();
    if (catalogs != null) result.catalogs.addAll(catalogs);
    if (total != null) result.total = total;
    return result;
  }

  ResSkillCatalogSearch._();

  factory ResSkillCatalogSearch.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSkillCatalogSearch()..mergeFromBuffer(data, registry);
  factory ResSkillCatalogSearch.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSkillCatalogSearch()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResSkillCatalogSearch',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResSkillCatalogSearch.$_createMessage)
    ..pPM<SkillCatalog>(1, _omitFieldNames ? '' : 'catalogs',
        subBuilder: SkillCatalog.$_createMessage)
    ..aI(2, _omitFieldNames ? '' : 'total')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSkillCatalogSearch clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSkillCatalogSearch copyWith(
          void Function(ResSkillCatalogSearch) updates) =>
      super.copyWith((message) => updates(message as ResSkillCatalogSearch))
          as ResSkillCatalogSearch;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ResSkillCatalogSearch() / ResSkillCatalogSearch.new instead')
  static ResSkillCatalogSearch create() => ResSkillCatalogSearch._();
  static $pb.GeneratedMessage $_createMessage() => ResSkillCatalogSearch._();
  @$core.override
  ResSkillCatalogSearch createEmptyInstance() => ResSkillCatalogSearch._();
  @$core.pragma('dart2js:noInline')
  static ResSkillCatalogSearch getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResSkillCatalogSearch>(
          ResSkillCatalogSearch.$_createMessage);
  static ResSkillCatalogSearch? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<SkillCatalog> get catalogs => $_getList(0);

  @$pb.TagNumber(2)
  $core.int get total => $_getIZ(1);
  @$pb.TagNumber(2)
  set total($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTotal() => $_has(1);
  @$pb.TagNumber(2)
  void clearTotal() => $_clearField(2);
}

/// Phase 7: agent submits a local skill to the public catalog for review
class ReqSkillCatalogSubmit extends $pb.GeneratedMessage {
  factory ReqSkillCatalogSubmit({
    $fixnum.Int64? skillId,
    $core.String? submitAction,
    $fixnum.Int64? existingCatalogId,
  }) {
    final result = ReqSkillCatalogSubmit._();
    if (skillId != null) result.skillId = skillId;
    if (submitAction != null) result.submitAction = submitAction;
    if (existingCatalogId != null) result.existingCatalogId = existingCatalogId;
    return result;
  }

  ReqSkillCatalogSubmit._();

  factory ReqSkillCatalogSubmit.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSkillCatalogSubmit()..mergeFromBuffer(data, registry);
  factory ReqSkillCatalogSubmit.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSkillCatalogSubmit()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqSkillCatalogSubmit',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqSkillCatalogSubmit.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'skillId')
    ..aOS(2, _omitFieldNames ? '' : 'submitAction')
    ..aInt64(3, _omitFieldNames ? '' : 'existingCatalogId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSkillCatalogSubmit clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSkillCatalogSubmit copyWith(
          void Function(ReqSkillCatalogSubmit) updates) =>
      super.copyWith((message) => updates(message as ReqSkillCatalogSubmit))
          as ReqSkillCatalogSubmit;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ReqSkillCatalogSubmit() / ReqSkillCatalogSubmit.new instead')
  static ReqSkillCatalogSubmit create() => ReqSkillCatalogSubmit._();
  static $pb.GeneratedMessage $_createMessage() => ReqSkillCatalogSubmit._();
  @$core.override
  ReqSkillCatalogSubmit createEmptyInstance() => ReqSkillCatalogSubmit._();
  @$core.pragma('dart2js:noInline')
  static ReqSkillCatalogSubmit getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqSkillCatalogSubmit>(
          ReqSkillCatalogSubmit.$_createMessage);
  static ReqSkillCatalogSubmit? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get skillId => $_getI64(0);
  @$pb.TagNumber(1)
  set skillId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSkillId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSkillId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get submitAction => $_getSZ(1);
  @$pb.TagNumber(2)
  set submitAction($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSubmitAction() => $_has(1);
  @$pb.TagNumber(2)
  void clearSubmitAction() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get existingCatalogId => $_getI64(2);
  @$pb.TagNumber(3)
  set existingCatalogId($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasExistingCatalogId() => $_has(2);
  @$pb.TagNumber(3)
  void clearExistingCatalogId() => $_clearField(3);
}

class ResSkillCatalogSubmit extends $pb.GeneratedMessage {
  factory ResSkillCatalogSubmit({
    $fixnum.Int64? catalogId,
    $core.String? status,
    $core.String? message,
  }) {
    final result = ResSkillCatalogSubmit._();
    if (catalogId != null) result.catalogId = catalogId;
    if (status != null) result.status = status;
    if (message != null) result.message = message;
    return result;
  }

  ResSkillCatalogSubmit._();

  factory ResSkillCatalogSubmit.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSkillCatalogSubmit()..mergeFromBuffer(data, registry);
  factory ResSkillCatalogSubmit.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSkillCatalogSubmit()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResSkillCatalogSubmit',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResSkillCatalogSubmit.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'catalogId')
    ..aOS(2, _omitFieldNames ? '' : 'status')
    ..aOS(3, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSkillCatalogSubmit clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSkillCatalogSubmit copyWith(
          void Function(ResSkillCatalogSubmit) updates) =>
      super.copyWith((message) => updates(message as ResSkillCatalogSubmit))
          as ResSkillCatalogSubmit;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ResSkillCatalogSubmit() / ResSkillCatalogSubmit.new instead')
  static ResSkillCatalogSubmit create() => ResSkillCatalogSubmit._();
  static $pb.GeneratedMessage $_createMessage() => ResSkillCatalogSubmit._();
  @$core.override
  ResSkillCatalogSubmit createEmptyInstance() => ResSkillCatalogSubmit._();
  @$core.pragma('dart2js:noInline')
  static ResSkillCatalogSubmit getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResSkillCatalogSubmit>(
          ResSkillCatalogSubmit.$_createMessage);
  static ResSkillCatalogSubmit? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get catalogId => $_getI64(0);
  @$pb.TagNumber(1)
  set catalogId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCatalogId() => $_has(0);
  @$pb.TagNumber(1)
  void clearCatalogId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get status => $_getSZ(1);
  @$pb.TagNumber(2)
  set status($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasStatus() => $_has(1);
  @$pb.TagNumber(2)
  void clearStatus() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get message => $_getSZ(2);
  @$pb.TagNumber(3)
  set message($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMessage() => $_has(2);
  @$pb.TagNumber(3)
  void clearMessage() => $_clearField(3);
}

/// Phase 7: agent reports the outcome of running a skill (self-learning feedback)
class ReqSkillRunReport extends $pb.GeneratedMessage {
  factory ReqSkillRunReport({
    $fixnum.Int64? runId,
    $fixnum.Int64? skillId,
    $core.bool? success,
    $core.int? stepIndex,
    $core.String? error,
    $core.String? patchMd,
    $core.String? detectedAppVersion,
    $core.String? metaJson,
  }) {
    final result = ReqSkillRunReport._();
    if (runId != null) result.runId = runId;
    if (skillId != null) result.skillId = skillId;
    if (success != null) result.success = success;
    if (stepIndex != null) result.stepIndex = stepIndex;
    if (error != null) result.error = error;
    if (patchMd != null) result.patchMd = patchMd;
    if (detectedAppVersion != null)
      result.detectedAppVersion = detectedAppVersion;
    if (metaJson != null) result.metaJson = metaJson;
    return result;
  }

  ReqSkillRunReport._();

  factory ReqSkillRunReport.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSkillRunReport()..mergeFromBuffer(data, registry);
  factory ReqSkillRunReport.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSkillRunReport()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqSkillRunReport',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqSkillRunReport.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'runId')
    ..aInt64(2, _omitFieldNames ? '' : 'skillId')
    ..aOB(3, _omitFieldNames ? '' : 'success')
    ..aI(4, _omitFieldNames ? '' : 'stepIndex')
    ..aOS(5, _omitFieldNames ? '' : 'error')
    ..aOS(6, _omitFieldNames ? '' : 'patchMd')
    ..aOS(7, _omitFieldNames ? '' : 'detectedAppVersion')
    ..aOS(8, _omitFieldNames ? '' : 'metaJson')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSkillRunReport clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSkillRunReport copyWith(void Function(ReqSkillRunReport) updates) =>
      super.copyWith((message) => updates(message as ReqSkillRunReport))
          as ReqSkillRunReport;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqSkillRunReport() / ReqSkillRunReport.new instead')
  static ReqSkillRunReport create() => ReqSkillRunReport._();
  static $pb.GeneratedMessage $_createMessage() => ReqSkillRunReport._();
  @$core.override
  ReqSkillRunReport createEmptyInstance() => ReqSkillRunReport._();
  @$core.pragma('dart2js:noInline')
  static ReqSkillRunReport getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqSkillRunReport>(
          ReqSkillRunReport.$_createMessage);
  static ReqSkillRunReport? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get runId => $_getI64(0);
  @$pb.TagNumber(1)
  set runId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRunId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRunId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get skillId => $_getI64(1);
  @$pb.TagNumber(2)
  set skillId($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSkillId() => $_has(1);
  @$pb.TagNumber(2)
  void clearSkillId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get success => $_getBF(2);
  @$pb.TagNumber(3)
  set success($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSuccess() => $_has(2);
  @$pb.TagNumber(3)
  void clearSuccess() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get stepIndex => $_getIZ(3);
  @$pb.TagNumber(4)
  set stepIndex($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasStepIndex() => $_has(3);
  @$pb.TagNumber(4)
  void clearStepIndex() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get error => $_getSZ(4);
  @$pb.TagNumber(5)
  set error($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasError() => $_has(4);
  @$pb.TagNumber(5)
  void clearError() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get patchMd => $_getSZ(5);
  @$pb.TagNumber(6)
  set patchMd($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasPatchMd() => $_has(5);
  @$pb.TagNumber(6)
  void clearPatchMd() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get detectedAppVersion => $_getSZ(6);
  @$pb.TagNumber(7)
  set detectedAppVersion($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasDetectedAppVersion() => $_has(6);
  @$pb.TagNumber(7)
  void clearDetectedAppVersion() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get metaJson => $_getSZ(7);
  @$pb.TagNumber(8)
  set metaJson($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasMetaJson() => $_has(7);
  @$pb.TagNumber(8)
  void clearMetaJson() => $_clearField(8);
}

class ResSkillRunReport extends $pb.GeneratedMessage {
  factory ResSkillRunReport({
    $core.bool? accepted,
    $core.String? message,
  }) {
    final result = ResSkillRunReport._();
    if (accepted != null) result.accepted = accepted;
    if (message != null) result.message = message;
    return result;
  }

  ResSkillRunReport._();

  factory ResSkillRunReport.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSkillRunReport()..mergeFromBuffer(data, registry);
  factory ResSkillRunReport.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSkillRunReport()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResSkillRunReport',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResSkillRunReport.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'accepted')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSkillRunReport clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSkillRunReport copyWith(void Function(ResSkillRunReport) updates) =>
      super.copyWith((message) => updates(message as ResSkillRunReport))
          as ResSkillRunReport;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResSkillRunReport() / ResSkillRunReport.new instead')
  static ResSkillRunReport create() => ResSkillRunReport._();
  static $pb.GeneratedMessage $_createMessage() => ResSkillRunReport._();
  @$core.override
  ResSkillRunReport createEmptyInstance() => ResSkillRunReport._();
  @$core.pragma('dart2js:noInline')
  static ResSkillRunReport getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResSkillRunReport>(
          ResSkillRunReport.$_createMessage);
  static ResSkillRunReport? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get accepted => $_getBF(0);
  @$pb.TagNumber(1)
  set accepted($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAccepted() => $_has(0);
  @$pb.TagNumber(1)
  void clearAccepted() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
