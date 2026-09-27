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

class RemoteFsDriveKind extends $pb.ProtobufEnum {
  static const RemoteFsDriveKind REMOTE_FS_DRIVE_KIND_UNSPECIFIED =
      RemoteFsDriveKind._(
          0, _omitEnumNames ? '' : 'REMOTE_FS_DRIVE_KIND_UNSPECIFIED');
  static const RemoteFsDriveKind REMOTE_FS_DRIVE_KIND_FIXED =
      RemoteFsDriveKind._(
          1, _omitEnumNames ? '' : 'REMOTE_FS_DRIVE_KIND_FIXED');
  static const RemoteFsDriveKind REMOTE_FS_DRIVE_KIND_REMOVABLE =
      RemoteFsDriveKind._(
          2, _omitEnumNames ? '' : 'REMOTE_FS_DRIVE_KIND_REMOVABLE');
  static const RemoteFsDriveKind REMOTE_FS_DRIVE_KIND_REMOTE =
      RemoteFsDriveKind._(
          3, _omitEnumNames ? '' : 'REMOTE_FS_DRIVE_KIND_REMOTE');
  static const RemoteFsDriveKind REMOTE_FS_DRIVE_KIND_CDROM =
      RemoteFsDriveKind._(
          4, _omitEnumNames ? '' : 'REMOTE_FS_DRIVE_KIND_CDROM');
  static const RemoteFsDriveKind REMOTE_FS_DRIVE_KIND_RAM =
      RemoteFsDriveKind._(5, _omitEnumNames ? '' : 'REMOTE_FS_DRIVE_KIND_RAM');

  static const $core.List<RemoteFsDriveKind> values = <RemoteFsDriveKind>[
    REMOTE_FS_DRIVE_KIND_UNSPECIFIED,
    REMOTE_FS_DRIVE_KIND_FIXED,
    REMOTE_FS_DRIVE_KIND_REMOVABLE,
    REMOTE_FS_DRIVE_KIND_REMOTE,
    REMOTE_FS_DRIVE_KIND_CDROM,
    REMOTE_FS_DRIVE_KIND_RAM,
  ];

  static final $core.List<RemoteFsDriveKind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 5);
  static RemoteFsDriveKind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const RemoteFsDriveKind._(super.value, super.name);
}

class RemoteMediaState extends $pb.ProtobufEnum {
  static const RemoteMediaState REMOTE_MEDIA_STATE_UNSPECIFIED =
      RemoteMediaState._(
          0, _omitEnumNames ? '' : 'REMOTE_MEDIA_STATE_UNSPECIFIED');
  static const RemoteMediaState REMOTE_MEDIA_STATE_IDLE =
      RemoteMediaState._(1, _omitEnumNames ? '' : 'REMOTE_MEDIA_STATE_IDLE');
  static const RemoteMediaState REMOTE_MEDIA_STATE_OPENING =
      RemoteMediaState._(2, _omitEnumNames ? '' : 'REMOTE_MEDIA_STATE_OPENING');
  static const RemoteMediaState REMOTE_MEDIA_STATE_PLAYING =
      RemoteMediaState._(3, _omitEnumNames ? '' : 'REMOTE_MEDIA_STATE_PLAYING');
  static const RemoteMediaState REMOTE_MEDIA_STATE_ERROR =
      RemoteMediaState._(4, _omitEnumNames ? '' : 'REMOTE_MEDIA_STATE_ERROR');

  static const $core.List<RemoteMediaState> values = <RemoteMediaState>[
    REMOTE_MEDIA_STATE_UNSPECIFIED,
    REMOTE_MEDIA_STATE_IDLE,
    REMOTE_MEDIA_STATE_OPENING,
    REMOTE_MEDIA_STATE_PLAYING,
    REMOTE_MEDIA_STATE_ERROR,
  ];

  static final $core.List<RemoteMediaState?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static RemoteMediaState? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const RemoteMediaState._(super.value, super.name);
}

class RemoteMediaEncoder extends $pb.ProtobufEnum {
  static const RemoteMediaEncoder REMOTE_MEDIA_ENCODER_UNSPECIFIED =
      RemoteMediaEncoder._(
          0, _omitEnumNames ? '' : 'REMOTE_MEDIA_ENCODER_UNSPECIFIED');
  static const RemoteMediaEncoder REMOTE_MEDIA_ENCODER_HW_MF =
      RemoteMediaEncoder._(
          1, _omitEnumNames ? '' : 'REMOTE_MEDIA_ENCODER_HW_MF');
  static const RemoteMediaEncoder REMOTE_MEDIA_ENCODER_FFMPEG =
      RemoteMediaEncoder._(
          2, _omitEnumNames ? '' : 'REMOTE_MEDIA_ENCODER_FFMPEG');

  static const $core.List<RemoteMediaEncoder> values = <RemoteMediaEncoder>[
    REMOTE_MEDIA_ENCODER_UNSPECIFIED,
    REMOTE_MEDIA_ENCODER_HW_MF,
    REMOTE_MEDIA_ENCODER_FFMPEG,
  ];

  static final $core.List<RemoteMediaEncoder?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static RemoteMediaEncoder? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const RemoteMediaEncoder._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
