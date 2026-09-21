// This is a generated file - do not edit.
//
// Generated from c35/device.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'identity.pb.dart' as $0;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// Client submits pairing code from agent/IoT screen (XXXXX-XXXXX or raw 10 chars)
class ReqDevicePair extends $pb.GeneratedMessage {
  factory ReqDevicePair({
    $core.String? code,
  }) {
    final result = ReqDevicePair._();
    if (code != null) result.code = code;
    return result;
  }

  ReqDevicePair._();

  factory ReqDevicePair.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqDevicePair()..mergeFromBuffer(data, registry);
  factory ReqDevicePair.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqDevicePair()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqDevicePair',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqDevicePair.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'code')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqDevicePair clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqDevicePair copyWith(void Function(ReqDevicePair) updates) =>
      super.copyWith((message) => updates(message as ReqDevicePair))
          as ReqDevicePair;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqDevicePair() / ReqDevicePair.new instead')
  static ReqDevicePair create() => ReqDevicePair._();
  static $pb.GeneratedMessage $_createMessage() => ReqDevicePair._();
  @$core.override
  ReqDevicePair createEmptyInstance() => ReqDevicePair._();
  @$core.pragma('dart2js:noInline')
  static ReqDevicePair getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqDevicePair>(
          ReqDevicePair.$_createMessage);
  static ReqDevicePair? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get code => $_getSZ(0);
  @$pb.TagNumber(1)
  set code($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCode() => $_has(0);
  @$pb.TagNumber(1)
  void clearCode() => $_clearField(1);
}

class ResDevicePair extends $pb.GeneratedMessage {
  factory ResDevicePair({
    $0.IdentityListRow? device,
  }) {
    final result = ResDevicePair._();
    if (device != null) result.device = device;
    return result;
  }

  ResDevicePair._();

  factory ResDevicePair.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResDevicePair()..mergeFromBuffer(data, registry);
  factory ResDevicePair.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResDevicePair()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResDevicePair',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResDevicePair.$_createMessage)
    ..aOM<$0.IdentityListRow>(1, _omitFieldNames ? '' : 'device',
        subBuilder: $0.IdentityListRow.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResDevicePair clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResDevicePair copyWith(void Function(ResDevicePair) updates) =>
      super.copyWith((message) => updates(message as ResDevicePair))
          as ResDevicePair;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResDevicePair() / ResDevicePair.new instead')
  static ResDevicePair create() => ResDevicePair._();
  static $pb.GeneratedMessage $_createMessage() => ResDevicePair._();
  @$core.override
  ResDevicePair createEmptyInstance() => ResDevicePair._();
  @$core.pragma('dart2js:noInline')
  static ResDevicePair getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResDevicePair>(
          ResDevicePair.$_createMessage);
  static ResDevicePair? _defaultInstance;

  @$pb.TagNumber(1)
  $0.IdentityListRow get device => $_getN(0);
  @$pb.TagNumber(1)
  set device($0.IdentityListRow value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasDevice() => $_has(0);
  @$pb.TagNumber(1)
  void clearDevice() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.IdentityListRow ensureDevice() => $_ensure(0);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
