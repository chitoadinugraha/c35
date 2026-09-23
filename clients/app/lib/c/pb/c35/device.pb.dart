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

import 'package:fixnum/fixnum.dart' as $fixnum;
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

class ReqDevicePairRegister extends $pb.GeneratedMessage {
  factory ReqDevicePairRegister({
    $core.String? deviceName,
    $core.String? deviceType,
  }) {
    final result = ReqDevicePairRegister._();
    if (deviceName != null) result.deviceName = deviceName;
    if (deviceType != null) result.deviceType = deviceType;
    return result;
  }

  ReqDevicePairRegister._();

  factory ReqDevicePairRegister.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqDevicePairRegister()..mergeFromBuffer(data, registry);
  factory ReqDevicePairRegister.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqDevicePairRegister()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqDevicePairRegister',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqDevicePairRegister.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'deviceName')
    ..aOS(2, _omitFieldNames ? '' : 'deviceType')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqDevicePairRegister clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqDevicePairRegister copyWith(
          void Function(ReqDevicePairRegister) updates) =>
      super.copyWith((message) => updates(message as ReqDevicePairRegister))
          as ReqDevicePairRegister;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ReqDevicePairRegister() / ReqDevicePairRegister.new instead')
  static ReqDevicePairRegister create() => ReqDevicePairRegister._();
  static $pb.GeneratedMessage $_createMessage() => ReqDevicePairRegister._();
  @$core.override
  ReqDevicePairRegister createEmptyInstance() => ReqDevicePairRegister._();
  @$core.pragma('dart2js:noInline')
  static ReqDevicePairRegister getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqDevicePairRegister>(
          ReqDevicePairRegister.$_createMessage);
  static ReqDevicePairRegister? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get deviceName => $_getSZ(0);
  @$pb.TagNumber(1)
  set deviceName($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDeviceName() => $_has(0);
  @$pb.TagNumber(1)
  void clearDeviceName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get deviceType => $_getSZ(1);
  @$pb.TagNumber(2)
  set deviceType($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDeviceType() => $_has(1);
  @$pb.TagNumber(2)
  void clearDeviceType() => $_clearField(2);
}

class ResDevicePairRegister extends $pb.GeneratedMessage {
  factory ResDevicePairRegister({
    $core.String? code,
    $core.String? deviceSecret,
    $fixnum.Int64? expiresInSec,
  }) {
    final result = ResDevicePairRegister._();
    if (code != null) result.code = code;
    if (deviceSecret != null) result.deviceSecret = deviceSecret;
    if (expiresInSec != null) result.expiresInSec = expiresInSec;
    return result;
  }

  ResDevicePairRegister._();

  factory ResDevicePairRegister.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResDevicePairRegister()..mergeFromBuffer(data, registry);
  factory ResDevicePairRegister.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResDevicePairRegister()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResDevicePairRegister',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResDevicePairRegister.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'code')
    ..aOS(2, _omitFieldNames ? '' : 'deviceSecret')
    ..aInt64(3, _omitFieldNames ? '' : 'expiresInSec')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResDevicePairRegister clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResDevicePairRegister copyWith(
          void Function(ResDevicePairRegister) updates) =>
      super.copyWith((message) => updates(message as ResDevicePairRegister))
          as ResDevicePairRegister;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ResDevicePairRegister() / ResDevicePairRegister.new instead')
  static ResDevicePairRegister create() => ResDevicePairRegister._();
  static $pb.GeneratedMessage $_createMessage() => ResDevicePairRegister._();
  @$core.override
  ResDevicePairRegister createEmptyInstance() => ResDevicePairRegister._();
  @$core.pragma('dart2js:noInline')
  static ResDevicePairRegister getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResDevicePairRegister>(
          ResDevicePairRegister.$_createMessage);
  static ResDevicePairRegister? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get code => $_getSZ(0);
  @$pb.TagNumber(1)
  set code($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCode() => $_has(0);
  @$pb.TagNumber(1)
  void clearCode() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get deviceSecret => $_getSZ(1);
  @$pb.TagNumber(2)
  set deviceSecret($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDeviceSecret() => $_has(1);
  @$pb.TagNumber(2)
  void clearDeviceSecret() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get expiresInSec => $_getI64(2);
  @$pb.TagNumber(3)
  set expiresInSec($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasExpiresInSec() => $_has(2);
  @$pb.TagNumber(3)
  void clearExpiresInSec() => $_clearField(3);
}

class ReqDevicePairPoll extends $pb.GeneratedMessage {
  factory ReqDevicePairPoll({
    $core.String? deviceSecret,
  }) {
    final result = ReqDevicePairPoll._();
    if (deviceSecret != null) result.deviceSecret = deviceSecret;
    return result;
  }

  ReqDevicePairPoll._();

  factory ReqDevicePairPoll.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqDevicePairPoll()..mergeFromBuffer(data, registry);
  factory ReqDevicePairPoll.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqDevicePairPoll()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqDevicePairPoll',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqDevicePairPoll.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'deviceSecret')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqDevicePairPoll clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqDevicePairPoll copyWith(void Function(ReqDevicePairPoll) updates) =>
      super.copyWith((message) => updates(message as ReqDevicePairPoll))
          as ReqDevicePairPoll;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqDevicePairPoll() / ReqDevicePairPoll.new instead')
  static ReqDevicePairPoll create() => ReqDevicePairPoll._();
  static $pb.GeneratedMessage $_createMessage() => ReqDevicePairPoll._();
  @$core.override
  ReqDevicePairPoll createEmptyInstance() => ReqDevicePairPoll._();
  @$core.pragma('dart2js:noInline')
  static ReqDevicePairPoll getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqDevicePairPoll>(
          ReqDevicePairPoll.$_createMessage);
  static ReqDevicePairPoll? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get deviceSecret => $_getSZ(0);
  @$pb.TagNumber(1)
  set deviceSecret($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDeviceSecret() => $_has(0);
  @$pb.TagNumber(1)
  void clearDeviceSecret() => $_clearField(1);
}

class ResDevicePairPoll extends $pb.GeneratedMessage {
  factory ResDevicePairPoll({
    $core.String? status,
    $core.String? sessionKey,
    $fixnum.Int64? deviceIid,
  }) {
    final result = ResDevicePairPoll._();
    if (status != null) result.status = status;
    if (sessionKey != null) result.sessionKey = sessionKey;
    if (deviceIid != null) result.deviceIid = deviceIid;
    return result;
  }

  ResDevicePairPoll._();

  factory ResDevicePairPoll.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResDevicePairPoll()..mergeFromBuffer(data, registry);
  factory ResDevicePairPoll.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResDevicePairPoll()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResDevicePairPoll',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResDevicePairPoll.$_createMessage)
    ..aOS(2, _omitFieldNames ? '' : 'status')
    ..aOS(3, _omitFieldNames ? '' : 'sessionKey')
    ..aInt64(4, _omitFieldNames ? '' : 'deviceIid')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResDevicePairPoll clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResDevicePairPoll copyWith(void Function(ResDevicePairPoll) updates) =>
      super.copyWith((message) => updates(message as ResDevicePairPoll))
          as ResDevicePairPoll;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResDevicePairPoll() / ResDevicePairPoll.new instead')
  static ResDevicePairPoll create() => ResDevicePairPoll._();
  static $pb.GeneratedMessage $_createMessage() => ResDevicePairPoll._();
  @$core.override
  ResDevicePairPoll createEmptyInstance() => ResDevicePairPoll._();
  @$core.pragma('dart2js:noInline')
  static ResDevicePairPoll getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResDevicePairPoll>(
          ResDevicePairPoll.$_createMessage);
  static ResDevicePairPoll? _defaultInstance;

  @$pb.TagNumber(2)
  $core.String get status => $_getSZ(0);
  @$pb.TagNumber(2)
  set status($core.String value) => $_setString(0, value);
  @$pb.TagNumber(2)
  $core.bool hasStatus() => $_has(0);
  @$pb.TagNumber(2)
  void clearStatus() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get sessionKey => $_getSZ(1);
  @$pb.TagNumber(3)
  set sessionKey($core.String value) => $_setString(1, value);
  @$pb.TagNumber(3)
  $core.bool hasSessionKey() => $_has(1);
  @$pb.TagNumber(3)
  void clearSessionKey() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get deviceIid => $_getI64(2);
  @$pb.TagNumber(4)
  set deviceIid($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(4)
  $core.bool hasDeviceIid() => $_has(2);
  @$pb.TagNumber(4)
  void clearDeviceIid() => $_clearField(4);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
