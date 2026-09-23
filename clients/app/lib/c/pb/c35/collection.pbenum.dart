// This is a generated file - do not edit.
//
// Generated from c35/collection.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class ColType extends $pb.ProtobufEnum {
  static const ColType COL_TYPE_UNSPECIFIED =
      ColType._(0, _omitEnumNames ? '' : 'COL_TYPE_UNSPECIFIED');
  static const ColType COL_TYPE_TEXT =
      ColType._(1, _omitEnumNames ? '' : 'COL_TYPE_TEXT');
  static const ColType COL_TYPE_INT =
      ColType._(2, _omitEnumNames ? '' : 'COL_TYPE_INT');
  static const ColType COL_TYPE_MONEY =
      ColType._(3, _omitEnumNames ? '' : 'COL_TYPE_MONEY');
  static const ColType COL_TYPE_BOOL =
      ColType._(4, _omitEnumNames ? '' : 'COL_TYPE_BOOL');
  static const ColType COL_TYPE_PIC =
      ColType._(5, _omitEnumNames ? '' : 'COL_TYPE_PIC');
  static const ColType COL_TYPE_JSON =
      ColType._(6, _omitEnumNames ? '' : 'COL_TYPE_JSON');
  static const ColType COL_TYPE_REF =
      ColType._(7, _omitEnumNames ? '' : 'COL_TYPE_REF');
  static const ColType COL_TYPE_TS =
      ColType._(8, _omitEnumNames ? '' : 'COL_TYPE_TS');

  static const $core.List<ColType> values = <ColType>[
    COL_TYPE_UNSPECIFIED,
    COL_TYPE_TEXT,
    COL_TYPE_INT,
    COL_TYPE_MONEY,
    COL_TYPE_BOOL,
    COL_TYPE_PIC,
    COL_TYPE_JSON,
    COL_TYPE_REF,
    COL_TYPE_TS,
  ];

  static final $core.List<ColType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 8);
  static ColType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ColType._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
