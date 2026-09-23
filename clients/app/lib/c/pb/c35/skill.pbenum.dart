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

import 'package:protobuf/protobuf.dart' as $pb;

class SkillScope extends $pb.ProtobufEnum {
  static const SkillScope SKILL_SCOPE_UNSPECIFIED =
      SkillScope._(0, _omitEnumNames ? '' : 'SKILL_SCOPE_UNSPECIFIED');
  static const SkillScope SKILL_SCOPE_USER =
      SkillScope._(1, _omitEnumNames ? '' : 'SKILL_SCOPE_USER');
  static const SkillScope SKILL_SCOPE_DEVICE =
      SkillScope._(2, _omitEnumNames ? '' : 'SKILL_SCOPE_DEVICE');
  static const SkillScope SKILL_SCOPE_TEAM =
      SkillScope._(3, _omitEnumNames ? '' : 'SKILL_SCOPE_TEAM');
  static const SkillScope SKILL_SCOPE_GLOBAL =
      SkillScope._(4, _omitEnumNames ? '' : 'SKILL_SCOPE_GLOBAL');

  static const $core.List<SkillScope> values = <SkillScope>[
    SKILL_SCOPE_UNSPECIFIED,
    SKILL_SCOPE_USER,
    SKILL_SCOPE_DEVICE,
    SKILL_SCOPE_TEAM,
    SKILL_SCOPE_GLOBAL,
  ];

  static final $core.List<SkillScope?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static SkillScope? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const SkillScope._(super.value, super.name);
}

class SkillSource extends $pb.ProtobufEnum {
  static const SkillSource SKILL_SOURCE_UNSPECIFIED =
      SkillSource._(0, _omitEnumNames ? '' : 'SKILL_SOURCE_UNSPECIFIED');
  static const SkillSource SKILL_SOURCE_TAUGHT =
      SkillSource._(1, _omitEnumNames ? '' : 'SKILL_SOURCE_TAUGHT');
  static const SkillSource SKILL_SOURCE_CATALOG =
      SkillSource._(2, _omitEnumNames ? '' : 'SKILL_SOURCE_CATALOG');
  static const SkillSource SKILL_SOURCE_IMPORT =
      SkillSource._(3, _omitEnumNames ? '' : 'SKILL_SOURCE_IMPORT');
  static const SkillSource SKILL_SOURCE_AI_EXPLORE =
      SkillSource._(4, _omitEnumNames ? '' : 'SKILL_SOURCE_AI_EXPLORE');

  static const $core.List<SkillSource> values = <SkillSource>[
    SKILL_SOURCE_UNSPECIFIED,
    SKILL_SOURCE_TAUGHT,
    SKILL_SOURCE_CATALOG,
    SKILL_SOURCE_IMPORT,
    SKILL_SOURCE_AI_EXPLORE,
  ];

  static final $core.List<SkillSource?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static SkillSource? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const SkillSource._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
