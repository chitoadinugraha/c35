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

import 'field.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'field.pbenum.dart';

class Field extends $pb.GeneratedMessage {
  factory Field({
    $core.String? key,
    $core.String? label,
    $core.String? desc,
    FieldType? type,
    $core.bool? optional,
    $core.String? def,
    $core.String? refCollection,
    $core.String? group,
  }) {
    final result = Field._();
    if (key != null) result.key = key;
    if (label != null) result.label = label;
    if (desc != null) result.desc = desc;
    if (type != null) result.type = type;
    if (optional != null) result.optional = optional;
    if (def != null) result.def = def;
    if (refCollection != null) result.refCollection = refCollection;
    if (group != null) result.group = group;
    return result;
  }

  Field._();

  factory Field.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Field()..mergeFromBuffer(data, registry);
  factory Field.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Field()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Field',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: Field.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'key')
    ..aOS(2, _omitFieldNames ? '' : 'label')
    ..aOS(3, _omitFieldNames ? '' : 'desc')
    ..aE<FieldType>(4, _omitFieldNames ? '' : 'type',
        enumValues: FieldType.values)
    ..aOB(5, _omitFieldNames ? '' : 'optional')
    ..aOS(6, _omitFieldNames ? '' : 'def')
    ..aOS(7, _omitFieldNames ? '' : 'refCollection')
    ..aOS(8, _omitFieldNames ? '' : 'group')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Field clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Field copyWith(void Function(Field) updates) =>
      super.copyWith((message) => updates(message as Field)) as Field;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Field() / Field.new instead')
  static Field create() => Field._();
  static $pb.GeneratedMessage $_createMessage() => Field._();
  @$core.override
  Field createEmptyInstance() => Field._();
  @$core.pragma('dart2js:noInline')
  static Field getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Field>(Field.$_createMessage);
  static Field? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get key => $_getSZ(0);
  @$pb.TagNumber(1)
  set key($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearKey() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get label => $_getSZ(1);
  @$pb.TagNumber(2)
  set label($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLabel() => $_has(1);
  @$pb.TagNumber(2)
  void clearLabel() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get desc => $_getSZ(2);
  @$pb.TagNumber(3)
  set desc($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDesc() => $_has(2);
  @$pb.TagNumber(3)
  void clearDesc() => $_clearField(3);

  @$pb.TagNumber(4)
  FieldType get type => $_getN(3);
  @$pb.TagNumber(4)
  set type(FieldType value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasType() => $_has(3);
  @$pb.TagNumber(4)
  void clearType() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get optional => $_getBF(4);
  @$pb.TagNumber(5)
  set optional($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasOptional() => $_has(4);
  @$pb.TagNumber(5)
  void clearOptional() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get def => $_getSZ(5);
  @$pb.TagNumber(6)
  set def($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasDef() => $_has(5);
  @$pb.TagNumber(6)
  void clearDef() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get refCollection => $_getSZ(6);
  @$pb.TagNumber(7)
  set refCollection($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasRefCollection() => $_has(6);
  @$pb.TagNumber(7)
  void clearRefCollection() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get group => $_getSZ(7);
  @$pb.TagNumber(8)
  set group($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasGroup() => $_has(7);
  @$pb.TagNumber(8)
  void clearGroup() => $_clearField(8);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
