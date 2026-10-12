// This is a generated file - do not edit.
//
// Generated from c35/stats.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class AdminDiskCleanKind extends $pb.ProtobufEnum {
  static const AdminDiskCleanKind ADMIN_DISK_CLEAN_UNSPECIFIED =
      AdminDiskCleanKind._(
          0, _omitEnumNames ? '' : 'ADMIN_DISK_CLEAN_UNSPECIFIED');
  static const AdminDiskCleanKind ADMIN_DISK_CLEAN_BOOT =
      AdminDiskCleanKind._(1, _omitEnumNames ? '' : 'ADMIN_DISK_CLEAN_BOOT');
  static const AdminDiskCleanKind ADMIN_DISK_CLEAN_YUGABYTE =
      AdminDiskCleanKind._(
          2, _omitEnumNames ? '' : 'ADMIN_DISK_CLEAN_YUGABYTE');
  static const AdminDiskCleanKind ADMIN_DISK_CLEAN_BUILDKIT =
      AdminDiskCleanKind._(
          3, _omitEnumNames ? '' : 'ADMIN_DISK_CLEAN_BUILDKIT');

  static const $core.List<AdminDiskCleanKind> values = <AdminDiskCleanKind>[
    ADMIN_DISK_CLEAN_UNSPECIFIED,
    ADMIN_DISK_CLEAN_BOOT,
    ADMIN_DISK_CLEAN_YUGABYTE,
    ADMIN_DISK_CLEAN_BUILDKIT,
  ];

  static final $core.List<AdminDiskCleanKind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static AdminDiskCleanKind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const AdminDiskCleanKind._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
