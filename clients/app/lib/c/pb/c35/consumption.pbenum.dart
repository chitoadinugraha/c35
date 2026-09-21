// This is a generated file - do not edit.
//
// Generated from c35/consumption.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class ConsumeMealType extends $pb.ProtobufEnum {
  static const ConsumeMealType CONSUME_MEAL_TYPE_OTHER =
      ConsumeMealType._(0, _omitEnumNames ? '' : 'CONSUME_MEAL_TYPE_OTHER');
  static const ConsumeMealType CONSUME_MEAL_TYPE_BREAKFAST =
      ConsumeMealType._(1, _omitEnumNames ? '' : 'CONSUME_MEAL_TYPE_BREAKFAST');
  static const ConsumeMealType CONSUME_MEAL_TYPE_LUNCH =
      ConsumeMealType._(2, _omitEnumNames ? '' : 'CONSUME_MEAL_TYPE_LUNCH');
  static const ConsumeMealType CONSUME_MEAL_TYPE_DINNER =
      ConsumeMealType._(3, _omitEnumNames ? '' : 'CONSUME_MEAL_TYPE_DINNER');
  static const ConsumeMealType CONSUME_MEAL_TYPE_SNACK =
      ConsumeMealType._(4, _omitEnumNames ? '' : 'CONSUME_MEAL_TYPE_SNACK');
  static const ConsumeMealType CONSUME_MEAL_TYPE_DESSERT =
      ConsumeMealType._(5, _omitEnumNames ? '' : 'CONSUME_MEAL_TYPE_DESSERT');
  static const ConsumeMealType CONSUME_MEAL_TYPE_LATE_NIGHT = ConsumeMealType._(
      6, _omitEnumNames ? '' : 'CONSUME_MEAL_TYPE_LATE_NIGHT');

  static const $core.List<ConsumeMealType> values = <ConsumeMealType>[
    CONSUME_MEAL_TYPE_OTHER,
    CONSUME_MEAL_TYPE_BREAKFAST,
    CONSUME_MEAL_TYPE_LUNCH,
    CONSUME_MEAL_TYPE_DINNER,
    CONSUME_MEAL_TYPE_SNACK,
    CONSUME_MEAL_TYPE_DESSERT,
    CONSUME_MEAL_TYPE_LATE_NIGHT,
  ];

  static final $core.List<ConsumeMealType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 6);
  static ConsumeMealType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ConsumeMealType._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
