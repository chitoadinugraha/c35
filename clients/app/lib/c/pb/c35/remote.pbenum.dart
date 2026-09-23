// This is a generated file - do not edit.
//
// Generated from c35/remote.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class RemoteIceType extends $pb.ProtobufEnum {
  static const RemoteIceType REMOTE_ICE_TYPE_UNSPECIFIED =
      RemoteIceType._(0, _omitEnumNames ? '' : 'REMOTE_ICE_TYPE_UNSPECIFIED');
  static const RemoteIceType REMOTE_ICE_TYPE_HOST =
      RemoteIceType._(1, _omitEnumNames ? '' : 'REMOTE_ICE_TYPE_HOST');
  static const RemoteIceType REMOTE_ICE_TYPE_SRFLX =
      RemoteIceType._(2, _omitEnumNames ? '' : 'REMOTE_ICE_TYPE_SRFLX');
  static const RemoteIceType REMOTE_ICE_TYPE_RELAY =
      RemoteIceType._(3, _omitEnumNames ? '' : 'REMOTE_ICE_TYPE_RELAY');

  static const $core.List<RemoteIceType> values = <RemoteIceType>[
    REMOTE_ICE_TYPE_UNSPECIFIED,
    REMOTE_ICE_TYPE_HOST,
    REMOTE_ICE_TYPE_SRFLX,
    REMOTE_ICE_TYPE_RELAY,
  ];

  static final $core.List<RemoteIceType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static RemoteIceType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const RemoteIceType._(super.value, super.name);
}

class RemoteConnectionMode extends $pb.ProtobufEnum {
  static const RemoteConnectionMode REMOTE_CONNECTION_MODE_UNSPECIFIED =
      RemoteConnectionMode._(
          0, _omitEnumNames ? '' : 'REMOTE_CONNECTION_MODE_UNSPECIFIED');
  static const RemoteConnectionMode REMOTE_CONNECTION_MODE_DIRECT =
      RemoteConnectionMode._(
          1, _omitEnumNames ? '' : 'REMOTE_CONNECTION_MODE_DIRECT');
  static const RemoteConnectionMode REMOTE_CONNECTION_MODE_RELAY =
      RemoteConnectionMode._(
          2, _omitEnumNames ? '' : 'REMOTE_CONNECTION_MODE_RELAY');

  static const $core.List<RemoteConnectionMode> values = <RemoteConnectionMode>[
    REMOTE_CONNECTION_MODE_UNSPECIFIED,
    REMOTE_CONNECTION_MODE_DIRECT,
    REMOTE_CONNECTION_MODE_RELAY,
  ];

  static final $core.List<RemoteConnectionMode?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static RemoteConnectionMode? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const RemoteConnectionMode._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
