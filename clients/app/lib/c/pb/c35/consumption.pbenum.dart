//
//  Generated code. Do not modify.
//  source: c35/consumption.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class ConsumeMealType extends $pb.ProtobufEnum {
  static const ConsumeMealType CONSUME_MEAL_TYPE_OTHER = ConsumeMealType._(0, _omitEnumNames ? '' : 'CONSUME_MEAL_TYPE_OTHER');
  static const ConsumeMealType CONSUME_MEAL_TYPE_BREAKFAST = ConsumeMealType._(1, _omitEnumNames ? '' : 'CONSUME_MEAL_TYPE_BREAKFAST');
  static const ConsumeMealType CONSUME_MEAL_TYPE_LUNCH = ConsumeMealType._(2, _omitEnumNames ? '' : 'CONSUME_MEAL_TYPE_LUNCH');
  static const ConsumeMealType CONSUME_MEAL_TYPE_DINNER = ConsumeMealType._(3, _omitEnumNames ? '' : 'CONSUME_MEAL_TYPE_DINNER');
  static const ConsumeMealType CONSUME_MEAL_TYPE_SNACK = ConsumeMealType._(4, _omitEnumNames ? '' : 'CONSUME_MEAL_TYPE_SNACK');
  static const ConsumeMealType CONSUME_MEAL_TYPE_DESSERT = ConsumeMealType._(5, _omitEnumNames ? '' : 'CONSUME_MEAL_TYPE_DESSERT');
  static const ConsumeMealType CONSUME_MEAL_TYPE_LATE_NIGHT = ConsumeMealType._(6, _omitEnumNames ? '' : 'CONSUME_MEAL_TYPE_LATE_NIGHT');

  static const $core.List<ConsumeMealType> values = <ConsumeMealType> [
    CONSUME_MEAL_TYPE_OTHER,
    CONSUME_MEAL_TYPE_BREAKFAST,
    CONSUME_MEAL_TYPE_LUNCH,
    CONSUME_MEAL_TYPE_DINNER,
    CONSUME_MEAL_TYPE_SNACK,
    CONSUME_MEAL_TYPE_DESSERT,
    CONSUME_MEAL_TYPE_LATE_NIGHT,
  ];

  static final $core.Map<$core.int, ConsumeMealType> _byValue = $pb.ProtobufEnum.initByValue(values);
  static ConsumeMealType? valueOf($core.int value) => _byValue[value];

  const ConsumeMealType._($core.int v, $core.String n) : super(v, n);
}


const _omitEnumNames = $core.bool.fromEnvironment('protobuf.omit_enum_names');
