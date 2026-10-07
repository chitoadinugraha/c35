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

import 'package:protobuf/protobuf.dart' as $pb;

class SiteBootMode extends $pb.ProtobufEnum {
  static const SiteBootMode SITE_BOOT_MODE_UNSPECIFIED =
      SiteBootMode._(0, _omitEnumNames ? '' : 'SITE_BOOT_MODE_UNSPECIFIED');
  static const SiteBootMode SITE_BOOT_MODE_DRAFT =
      SiteBootMode._(1, _omitEnumNames ? '' : 'SITE_BOOT_MODE_DRAFT');
  static const SiteBootMode SITE_BOOT_MODE_PUBLISHED =
      SiteBootMode._(2, _omitEnumNames ? '' : 'SITE_BOOT_MODE_PUBLISHED');

  static const $core.List<SiteBootMode> values = <SiteBootMode>[
    SITE_BOOT_MODE_UNSPECIFIED,
    SITE_BOOT_MODE_DRAFT,
    SITE_BOOT_MODE_PUBLISHED,
  ];

  static final $core.List<SiteBootMode?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static SiteBootMode? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const SiteBootMode._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
