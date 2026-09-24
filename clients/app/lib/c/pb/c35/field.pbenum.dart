// This is a generated file - do not edit.
//
// Generated from c35/field.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class FieldType extends $pb.ProtobufEnum {
  static const FieldType FIELD_TYPE_UNSPECIFIED =
      FieldType._(0, _omitEnumNames ? '' : 'FIELD_TYPE_UNSPECIFIED');
  static const FieldType FIELD_TYPE_TEXT =
      FieldType._(1, _omitEnumNames ? '' : 'FIELD_TYPE_TEXT');
  static const FieldType FIELD_TYPE_INT =
      FieldType._(2, _omitEnumNames ? '' : 'FIELD_TYPE_INT');
  static const FieldType FIELD_TYPE_MONEY =
      FieldType._(3, _omitEnumNames ? '' : 'FIELD_TYPE_MONEY');
  static const FieldType FIELD_TYPE_BOOL =
      FieldType._(4, _omitEnumNames ? '' : 'FIELD_TYPE_BOOL');
  static const FieldType FIELD_TYPE_PIC =
      FieldType._(5, _omitEnumNames ? '' : 'FIELD_TYPE_PIC');
  static const FieldType FIELD_TYPE_JSON =
      FieldType._(6, _omitEnumNames ? '' : 'FIELD_TYPE_JSON');
  static const FieldType FIELD_TYPE_REF =
      FieldType._(7, _omitEnumNames ? '' : 'FIELD_TYPE_REF');
  static const FieldType FIELD_TYPE_TS =
      FieldType._(8, _omitEnumNames ? '' : 'FIELD_TYPE_TS');

  static const $core.List<FieldType> values = <FieldType>[
    FIELD_TYPE_UNSPECIFIED,
    FIELD_TYPE_TEXT,
    FIELD_TYPE_INT,
    FIELD_TYPE_MONEY,
    FIELD_TYPE_BOOL,
    FIELD_TYPE_PIC,
    FIELD_TYPE_JSON,
    FIELD_TYPE_REF,
    FIELD_TYPE_TS,
  ];

  static final $core.List<FieldType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 8);
  static FieldType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const FieldType._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
