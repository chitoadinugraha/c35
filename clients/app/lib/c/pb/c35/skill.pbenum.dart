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

import 'package:protobuf/protobuf.dart' as $pb;

class SkillScope extends $pb.ProtobufEnum {
  static const SkillScope SKILL_SCOPE_UNSPECIFIED = SkillScope._(0, _omitEnumNames ? '' : 'SKILL_SCOPE_UNSPECIFIED');
  static const SkillScope SKILL_SCOPE_USER = SkillScope._(1, _omitEnumNames ? '' : 'SKILL_SCOPE_USER');
  static const SkillScope SKILL_SCOPE_DEVICE = SkillScope._(2, _omitEnumNames ? '' : 'SKILL_SCOPE_DEVICE');
  static const SkillScope SKILL_SCOPE_TEAM = SkillScope._(3, _omitEnumNames ? '' : 'SKILL_SCOPE_TEAM');
  static const SkillScope SKILL_SCOPE_GLOBAL = SkillScope._(4, _omitEnumNames ? '' : 'SKILL_SCOPE_GLOBAL');

  static const $core.List<SkillScope> values = <SkillScope> [
    SKILL_SCOPE_UNSPECIFIED,
    SKILL_SCOPE_USER,
    SKILL_SCOPE_DEVICE,
    SKILL_SCOPE_TEAM,
    SKILL_SCOPE_GLOBAL,
  ];

  static final $core.Map<$core.int, SkillScope> _byValue = $pb.ProtobufEnum.initByValue(values);
  static SkillScope? valueOf($core.int value) => _byValue[value];

  const SkillScope._($core.int v, $core.String n) : super(v, n);
}

class SkillSource extends $pb.ProtobufEnum {
  static const SkillSource SKILL_SOURCE_UNSPECIFIED = SkillSource._(0, _omitEnumNames ? '' : 'SKILL_SOURCE_UNSPECIFIED');
  static const SkillSource SKILL_SOURCE_TAUGHT = SkillSource._(1, _omitEnumNames ? '' : 'SKILL_SOURCE_TAUGHT');
  static const SkillSource SKILL_SOURCE_CATALOG = SkillSource._(2, _omitEnumNames ? '' : 'SKILL_SOURCE_CATALOG');
  static const SkillSource SKILL_SOURCE_IMPORT = SkillSource._(3, _omitEnumNames ? '' : 'SKILL_SOURCE_IMPORT');

  static const $core.List<SkillSource> values = <SkillSource> [
    SKILL_SOURCE_UNSPECIFIED,
    SKILL_SOURCE_TAUGHT,
    SKILL_SOURCE_CATALOG,
    SKILL_SOURCE_IMPORT,
  ];

  static final $core.Map<$core.int, SkillSource> _byValue = $pb.ProtobufEnum.initByValue(values);
  static SkillSource? valueOf($core.int value) => _byValue[value];

  const SkillSource._($core.int v, $core.String n) : super(v, n);
}


const _omitEnumNames = $core.bool.fromEnvironment('protobuf.omit_enum_names');
