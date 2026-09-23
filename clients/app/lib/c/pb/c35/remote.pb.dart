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

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'remote.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'remote.pbenum.dart';

class ReqRemoteSessionStart extends $pb.GeneratedMessage {
  factory ReqRemoteSessionStart({
    $fixnum.Int64? deviceIid,
    $core.String? sessionId,
  }) {
    final result = ReqRemoteSessionStart._();
    if (deviceIid != null) result.deviceIid = deviceIid;
    if (sessionId != null) result.sessionId = sessionId;
    return result;
  }

  ReqRemoteSessionStart._();

  factory ReqRemoteSessionStart.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqRemoteSessionStart()..mergeFromBuffer(data, registry);
  factory ReqRemoteSessionStart.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqRemoteSessionStart()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqRemoteSessionStart',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqRemoteSessionStart.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'deviceIid')
    ..aOS(2, _omitFieldNames ? '' : 'sessionId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqRemoteSessionStart clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqRemoteSessionStart copyWith(
          void Function(ReqRemoteSessionStart) updates) =>
      super.copyWith((message) => updates(message as ReqRemoteSessionStart))
          as ReqRemoteSessionStart;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ReqRemoteSessionStart() / ReqRemoteSessionStart.new instead')
  static ReqRemoteSessionStart create() => ReqRemoteSessionStart._();
  static $pb.GeneratedMessage $_createMessage() => ReqRemoteSessionStart._();
  @$core.override
  ReqRemoteSessionStart createEmptyInstance() => ReqRemoteSessionStart._();
  @$core.pragma('dart2js:noInline')
  static ReqRemoteSessionStart getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqRemoteSessionStart>(
          ReqRemoteSessionStart.$_createMessage);
  static ReqRemoteSessionStart? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get deviceIid => $_getI64(0);
  @$pb.TagNumber(1)
  set deviceIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDeviceIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearDeviceIid() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get sessionId => $_getSZ(1);
  @$pb.TagNumber(2)
  set sessionId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSessionId() => $_has(1);
  @$pb.TagNumber(2)
  void clearSessionId() => $_clearField(2);
}

class ResRemoteSessionStart extends $pb.GeneratedMessage {
  factory ResRemoteSessionStart({
    $core.bool? ok,
    $core.String? error,
    $core.String? sessionId,
  }) {
    final result = ResRemoteSessionStart._();
    if (ok != null) result.ok = ok;
    if (error != null) result.error = error;
    if (sessionId != null) result.sessionId = sessionId;
    return result;
  }

  ResRemoteSessionStart._();

  factory ResRemoteSessionStart.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResRemoteSessionStart()..mergeFromBuffer(data, registry);
  factory ResRemoteSessionStart.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResRemoteSessionStart()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResRemoteSessionStart',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResRemoteSessionStart.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'ok')
    ..aOS(2, _omitFieldNames ? '' : 'error')
    ..aOS(3, _omitFieldNames ? '' : 'sessionId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResRemoteSessionStart clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResRemoteSessionStart copyWith(
          void Function(ResRemoteSessionStart) updates) =>
      super.copyWith((message) => updates(message as ResRemoteSessionStart))
          as ResRemoteSessionStart;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ResRemoteSessionStart() / ResRemoteSessionStart.new instead')
  static ResRemoteSessionStart create() => ResRemoteSessionStart._();
  static $pb.GeneratedMessage $_createMessage() => ResRemoteSessionStart._();
  @$core.override
  ResRemoteSessionStart createEmptyInstance() => ResRemoteSessionStart._();
  @$core.pragma('dart2js:noInline')
  static ResRemoteSessionStart getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResRemoteSessionStart>(
          ResRemoteSessionStart.$_createMessage);
  static ResRemoteSessionStart? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get ok => $_getBF(0);
  @$pb.TagNumber(1)
  set ok($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOk() => $_has(0);
  @$pb.TagNumber(1)
  void clearOk() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get error => $_getSZ(1);
  @$pb.TagNumber(2)
  set error($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get sessionId => $_getSZ(2);
  @$pb.TagNumber(3)
  set sessionId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSessionId() => $_has(2);
  @$pb.TagNumber(3)
  void clearSessionId() => $_clearField(3);
}

class RtcSignalOffer extends $pb.GeneratedMessage {
  factory RtcSignalOffer({
    $fixnum.Int64? deviceIid,
    $core.String? sessionId,
    $core.String? sdp,
  }) {
    final result = RtcSignalOffer._();
    if (deviceIid != null) result.deviceIid = deviceIid;
    if (sessionId != null) result.sessionId = sessionId;
    if (sdp != null) result.sdp = sdp;
    return result;
  }

  RtcSignalOffer._();

  factory RtcSignalOffer.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RtcSignalOffer()..mergeFromBuffer(data, registry);
  factory RtcSignalOffer.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RtcSignalOffer()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RtcSignalOffer',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: RtcSignalOffer.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'deviceIid')
    ..aOS(2, _omitFieldNames ? '' : 'sessionId')
    ..aOS(3, _omitFieldNames ? '' : 'sdp')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RtcSignalOffer clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RtcSignalOffer copyWith(void Function(RtcSignalOffer) updates) =>
      super.copyWith((message) => updates(message as RtcSignalOffer))
          as RtcSignalOffer;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RtcSignalOffer() / RtcSignalOffer.new instead')
  static RtcSignalOffer create() => RtcSignalOffer._();
  static $pb.GeneratedMessage $_createMessage() => RtcSignalOffer._();
  @$core.override
  RtcSignalOffer createEmptyInstance() => RtcSignalOffer._();
  @$core.pragma('dart2js:noInline')
  static RtcSignalOffer getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RtcSignalOffer>(
          RtcSignalOffer.$_createMessage);
  static RtcSignalOffer? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get deviceIid => $_getI64(0);
  @$pb.TagNumber(1)
  set deviceIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDeviceIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearDeviceIid() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get sessionId => $_getSZ(1);
  @$pb.TagNumber(2)
  set sessionId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSessionId() => $_has(1);
  @$pb.TagNumber(2)
  void clearSessionId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get sdp => $_getSZ(2);
  @$pb.TagNumber(3)
  set sdp($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSdp() => $_has(2);
  @$pb.TagNumber(3)
  void clearSdp() => $_clearField(3);
}

class RtcSignalAnswer extends $pb.GeneratedMessage {
  factory RtcSignalAnswer({
    $fixnum.Int64? deviceIid,
    $core.String? sessionId,
    $core.String? sdp,
  }) {
    final result = RtcSignalAnswer._();
    if (deviceIid != null) result.deviceIid = deviceIid;
    if (sessionId != null) result.sessionId = sessionId;
    if (sdp != null) result.sdp = sdp;
    return result;
  }

  RtcSignalAnswer._();

  factory RtcSignalAnswer.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RtcSignalAnswer()..mergeFromBuffer(data, registry);
  factory RtcSignalAnswer.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RtcSignalAnswer()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RtcSignalAnswer',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: RtcSignalAnswer.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'deviceIid')
    ..aOS(2, _omitFieldNames ? '' : 'sessionId')
    ..aOS(3, _omitFieldNames ? '' : 'sdp')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RtcSignalAnswer clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RtcSignalAnswer copyWith(void Function(RtcSignalAnswer) updates) =>
      super.copyWith((message) => updates(message as RtcSignalAnswer))
          as RtcSignalAnswer;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RtcSignalAnswer() / RtcSignalAnswer.new instead')
  static RtcSignalAnswer create() => RtcSignalAnswer._();
  static $pb.GeneratedMessage $_createMessage() => RtcSignalAnswer._();
  @$core.override
  RtcSignalAnswer createEmptyInstance() => RtcSignalAnswer._();
  @$core.pragma('dart2js:noInline')
  static RtcSignalAnswer getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RtcSignalAnswer>(
          RtcSignalAnswer.$_createMessage);
  static RtcSignalAnswer? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get deviceIid => $_getI64(0);
  @$pb.TagNumber(1)
  set deviceIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDeviceIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearDeviceIid() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get sessionId => $_getSZ(1);
  @$pb.TagNumber(2)
  set sessionId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSessionId() => $_has(1);
  @$pb.TagNumber(2)
  void clearSessionId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get sdp => $_getSZ(2);
  @$pb.TagNumber(3)
  set sdp($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSdp() => $_has(2);
  @$pb.TagNumber(3)
  void clearSdp() => $_clearField(3);
}

class RtcSignalIce extends $pb.GeneratedMessage {
  factory RtcSignalIce({
    $fixnum.Int64? deviceIid,
    $core.String? sessionId,
    $core.String? candidate,
    $core.String? sdpMid,
    $core.int? sdpMlineIndex,
  }) {
    final result = RtcSignalIce._();
    if (deviceIid != null) result.deviceIid = deviceIid;
    if (sessionId != null) result.sessionId = sessionId;
    if (candidate != null) result.candidate = candidate;
    if (sdpMid != null) result.sdpMid = sdpMid;
    if (sdpMlineIndex != null) result.sdpMlineIndex = sdpMlineIndex;
    return result;
  }

  RtcSignalIce._();

  factory RtcSignalIce.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RtcSignalIce()..mergeFromBuffer(data, registry);
  factory RtcSignalIce.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RtcSignalIce()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RtcSignalIce',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: RtcSignalIce.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'deviceIid')
    ..aOS(2, _omitFieldNames ? '' : 'sessionId')
    ..aOS(3, _omitFieldNames ? '' : 'candidate')
    ..aOS(4, _omitFieldNames ? '' : 'sdpMid')
    ..aI(5, _omitFieldNames ? '' : 'sdpMlineIndex',
        fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RtcSignalIce clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RtcSignalIce copyWith(void Function(RtcSignalIce) updates) =>
      super.copyWith((message) => updates(message as RtcSignalIce))
          as RtcSignalIce;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RtcSignalIce() / RtcSignalIce.new instead')
  static RtcSignalIce create() => RtcSignalIce._();
  static $pb.GeneratedMessage $_createMessage() => RtcSignalIce._();
  @$core.override
  RtcSignalIce createEmptyInstance() => RtcSignalIce._();
  @$core.pragma('dart2js:noInline')
  static RtcSignalIce getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RtcSignalIce>(
          RtcSignalIce.$_createMessage);
  static RtcSignalIce? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get deviceIid => $_getI64(0);
  @$pb.TagNumber(1)
  set deviceIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDeviceIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearDeviceIid() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get sessionId => $_getSZ(1);
  @$pb.TagNumber(2)
  set sessionId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSessionId() => $_has(1);
  @$pb.TagNumber(2)
  void clearSessionId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get candidate => $_getSZ(2);
  @$pb.TagNumber(3)
  set candidate($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCandidate() => $_has(2);
  @$pb.TagNumber(3)
  void clearCandidate() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get sdpMid => $_getSZ(3);
  @$pb.TagNumber(4)
  set sdpMid($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSdpMid() => $_has(3);
  @$pb.TagNumber(4)
  void clearSdpMid() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get sdpMlineIndex => $_getIZ(4);
  @$pb.TagNumber(5)
  set sdpMlineIndex($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSdpMlineIndex() => $_has(4);
  @$pb.TagNumber(5)
  void clearSdpMlineIndex() => $_clearField(5);
}

class ReqRemoteSessionStop extends $pb.GeneratedMessage {
  factory ReqRemoteSessionStop({
    $fixnum.Int64? deviceIid,
    $core.String? sessionId,
  }) {
    final result = ReqRemoteSessionStop._();
    if (deviceIid != null) result.deviceIid = deviceIid;
    if (sessionId != null) result.sessionId = sessionId;
    return result;
  }

  ReqRemoteSessionStop._();

  factory ReqRemoteSessionStop.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqRemoteSessionStop()..mergeFromBuffer(data, registry);
  factory ReqRemoteSessionStop.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqRemoteSessionStop()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqRemoteSessionStop',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqRemoteSessionStop.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'deviceIid')
    ..aOS(2, _omitFieldNames ? '' : 'sessionId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqRemoteSessionStop clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqRemoteSessionStop copyWith(void Function(ReqRemoteSessionStop) updates) =>
      super.copyWith((message) => updates(message as ReqRemoteSessionStop))
          as ReqRemoteSessionStop;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ReqRemoteSessionStop() / ReqRemoteSessionStop.new instead')
  static ReqRemoteSessionStop create() => ReqRemoteSessionStop._();
  static $pb.GeneratedMessage $_createMessage() => ReqRemoteSessionStop._();
  @$core.override
  ReqRemoteSessionStop createEmptyInstance() => ReqRemoteSessionStop._();
  @$core.pragma('dart2js:noInline')
  static ReqRemoteSessionStop getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqRemoteSessionStop>(
          ReqRemoteSessionStop.$_createMessage);
  static ReqRemoteSessionStop? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get deviceIid => $_getI64(0);
  @$pb.TagNumber(1)
  set deviceIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDeviceIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearDeviceIid() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get sessionId => $_getSZ(1);
  @$pb.TagNumber(2)
  set sessionId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSessionId() => $_has(1);
  @$pb.TagNumber(2)
  void clearSessionId() => $_clearField(2);
}

class ResRemoteSessionStop extends $pb.GeneratedMessage {
  factory ResRemoteSessionStop({
    $core.bool? ok,
  }) {
    final result = ResRemoteSessionStop._();
    if (ok != null) result.ok = ok;
    return result;
  }

  ResRemoteSessionStop._();

  factory ResRemoteSessionStop.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResRemoteSessionStop()..mergeFromBuffer(data, registry);
  factory ResRemoteSessionStop.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResRemoteSessionStop()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResRemoteSessionStop',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResRemoteSessionStop.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'ok')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResRemoteSessionStop clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResRemoteSessionStop copyWith(void Function(ResRemoteSessionStop) updates) =>
      super.copyWith((message) => updates(message as ResRemoteSessionStop))
          as ResRemoteSessionStop;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ResRemoteSessionStop() / ResRemoteSessionStop.new instead')
  static ResRemoteSessionStop create() => ResRemoteSessionStop._();
  static $pb.GeneratedMessage $_createMessage() => ResRemoteSessionStop._();
  @$core.override
  ResRemoteSessionStop createEmptyInstance() => ResRemoteSessionStop._();
  @$core.pragma('dart2js:noInline')
  static ResRemoteSessionStop getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResRemoteSessionStop>(
          ResRemoteSessionStop.$_createMessage);
  static ResRemoteSessionStop? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get ok => $_getBF(0);
  @$pb.TagNumber(1)
  set ok($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOk() => $_has(0);
  @$pb.TagNumber(1)
  void clearOk() => $_clearField(1);
}

/// Unsolicited: connection stats for Direct / Relay badge
class RemoteSessionPush extends $pb.GeneratedMessage {
  factory RemoteSessionPush({
    $fixnum.Int64? deviceIid,
    $core.String? sessionId,
    RemoteConnectionMode? mode,
    RemoteIceType? selectedIce,
    $core.bool? videoActive,
    $core.bool? webrtcConnected,
    $core.bool? updateReady,
    $fixnum.Int64? updateVersion,
  }) {
    final result = RemoteSessionPush._();
    if (deviceIid != null) result.deviceIid = deviceIid;
    if (sessionId != null) result.sessionId = sessionId;
    if (mode != null) result.mode = mode;
    if (selectedIce != null) result.selectedIce = selectedIce;
    if (videoActive != null) result.videoActive = videoActive;
    if (webrtcConnected != null) result.webrtcConnected = webrtcConnected;
    if (updateReady != null) result.updateReady = updateReady;
    if (updateVersion != null) result.updateVersion = updateVersion;
    return result;
  }

  RemoteSessionPush._();

  factory RemoteSessionPush.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoteSessionPush()..mergeFromBuffer(data, registry);
  factory RemoteSessionPush.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoteSessionPush()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RemoteSessionPush',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: RemoteSessionPush.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'deviceIid')
    ..aOS(2, _omitFieldNames ? '' : 'sessionId')
    ..aE<RemoteConnectionMode>(3, _omitFieldNames ? '' : 'mode',
        enumValues: RemoteConnectionMode.values)
    ..aE<RemoteIceType>(4, _omitFieldNames ? '' : 'selectedIce',
        enumValues: RemoteIceType.values)
    ..aOB(5, _omitFieldNames ? '' : 'videoActive')
    ..aOB(6, _omitFieldNames ? '' : 'webrtcConnected')
    ..aOB(7, _omitFieldNames ? '' : 'updateReady')
    ..aInt64(8, _omitFieldNames ? '' : 'updateVersion')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoteSessionPush clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoteSessionPush copyWith(void Function(RemoteSessionPush) updates) =>
      super.copyWith((message) => updates(message as RemoteSessionPush))
          as RemoteSessionPush;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RemoteSessionPush() / RemoteSessionPush.new instead')
  static RemoteSessionPush create() => RemoteSessionPush._();
  static $pb.GeneratedMessage $_createMessage() => RemoteSessionPush._();
  @$core.override
  RemoteSessionPush createEmptyInstance() => RemoteSessionPush._();
  @$core.pragma('dart2js:noInline')
  static RemoteSessionPush getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RemoteSessionPush>(
          RemoteSessionPush.$_createMessage);
  static RemoteSessionPush? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get deviceIid => $_getI64(0);
  @$pb.TagNumber(1)
  set deviceIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDeviceIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearDeviceIid() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get sessionId => $_getSZ(1);
  @$pb.TagNumber(2)
  set sessionId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSessionId() => $_has(1);
  @$pb.TagNumber(2)
  void clearSessionId() => $_clearField(2);

  @$pb.TagNumber(3)
  RemoteConnectionMode get mode => $_getN(2);
  @$pb.TagNumber(3)
  set mode(RemoteConnectionMode value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasMode() => $_has(2);
  @$pb.TagNumber(3)
  void clearMode() => $_clearField(3);

  @$pb.TagNumber(4)
  RemoteIceType get selectedIce => $_getN(3);
  @$pb.TagNumber(4)
  set selectedIce(RemoteIceType value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasSelectedIce() => $_has(3);
  @$pb.TagNumber(4)
  void clearSelectedIce() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get videoActive => $_getBF(4);
  @$pb.TagNumber(5)
  set videoActive($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasVideoActive() => $_has(4);
  @$pb.TagNumber(5)
  void clearVideoActive() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get webrtcConnected => $_getBF(5);
  @$pb.TagNumber(6)
  set webrtcConnected($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasWebrtcConnected() => $_has(5);
  @$pb.TagNumber(6)
  void clearWebrtcConnected() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.bool get updateReady => $_getBF(6);
  @$pb.TagNumber(7)
  set updateReady($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasUpdateReady() => $_has(6);
  @$pb.TagNumber(7)
  void clearUpdateReady() => $_clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get updateVersion => $_getI64(7);
  @$pb.TagNumber(8)
  set updateVersion($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(8)
  $core.bool hasUpdateVersion() => $_has(7);
  @$pb.TagNumber(8)
  void clearUpdateVersion() => $_clearField(8);
}

class IceServer extends $pb.GeneratedMessage {
  factory IceServer({
    $core.Iterable<$core.String>? urls,
    $core.String? username,
    $core.String? credential,
  }) {
    final result = IceServer._();
    if (urls != null) result.urls.addAll(urls);
    if (username != null) result.username = username;
    if (credential != null) result.credential = credential;
    return result;
  }

  IceServer._();

  factory IceServer.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      IceServer()..mergeFromBuffer(data, registry);
  factory IceServer.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      IceServer()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'IceServer',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: IceServer.$_createMessage)
    ..pPS(1, _omitFieldNames ? '' : 'urls')
    ..aOS(2, _omitFieldNames ? '' : 'username')
    ..aOS(3, _omitFieldNames ? '' : 'credential')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IceServer clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IceServer copyWith(void Function(IceServer) updates) =>
      super.copyWith((message) => updates(message as IceServer)) as IceServer;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use IceServer() / IceServer.new instead')
  static IceServer create() => IceServer._();
  static $pb.GeneratedMessage $_createMessage() => IceServer._();
  @$core.override
  IceServer createEmptyInstance() => IceServer._();
  @$core.pragma('dart2js:noInline')
  static IceServer getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<IceServer>(IceServer.$_createMessage);
  static IceServer? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get urls => $_getList(0);

  @$pb.TagNumber(2)
  $core.String get username => $_getSZ(1);
  @$pb.TagNumber(2)
  set username($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUsername() => $_has(1);
  @$pb.TagNumber(2)
  void clearUsername() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get credential => $_getSZ(2);
  @$pb.TagNumber(3)
  set credential($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCredential() => $_has(2);
  @$pb.TagNumber(3)
  void clearCredential() => $_clearField(3);
}

class ReqRemoteIceConfig extends $pb.GeneratedMessage {
  factory ReqRemoteIceConfig() => ReqRemoteIceConfig._();

  ReqRemoteIceConfig._();

  factory ReqRemoteIceConfig.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqRemoteIceConfig()..mergeFromBuffer(data, registry);
  factory ReqRemoteIceConfig.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqRemoteIceConfig()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqRemoteIceConfig',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqRemoteIceConfig.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqRemoteIceConfig clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqRemoteIceConfig copyWith(void Function(ReqRemoteIceConfig) updates) =>
      super.copyWith((message) => updates(message as ReqRemoteIceConfig))
          as ReqRemoteIceConfig;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqRemoteIceConfig() / ReqRemoteIceConfig.new instead')
  static ReqRemoteIceConfig create() => ReqRemoteIceConfig._();
  static $pb.GeneratedMessage $_createMessage() => ReqRemoteIceConfig._();
  @$core.override
  ReqRemoteIceConfig createEmptyInstance() => ReqRemoteIceConfig._();
  @$core.pragma('dart2js:noInline')
  static ReqRemoteIceConfig getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqRemoteIceConfig>(
          ReqRemoteIceConfig.$_createMessage);
  static ReqRemoteIceConfig? _defaultInstance;
}

class ResRemoteIceConfig extends $pb.GeneratedMessage {
  factory ResRemoteIceConfig({
    $core.Iterable<IceServer>? iceServers,
    $core.int? ttlSec,
  }) {
    final result = ResRemoteIceConfig._();
    if (iceServers != null) result.iceServers.addAll(iceServers);
    if (ttlSec != null) result.ttlSec = ttlSec;
    return result;
  }

  ResRemoteIceConfig._();

  factory ResRemoteIceConfig.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResRemoteIceConfig()..mergeFromBuffer(data, registry);
  factory ResRemoteIceConfig.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResRemoteIceConfig()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResRemoteIceConfig',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResRemoteIceConfig.$_createMessage)
    ..pPM<IceServer>(1, _omitFieldNames ? '' : 'iceServers',
        subBuilder: IceServer.$_createMessage)
    ..aI(2, _omitFieldNames ? '' : 'ttlSec', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResRemoteIceConfig clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResRemoteIceConfig copyWith(void Function(ResRemoteIceConfig) updates) =>
      super.copyWith((message) => updates(message as ResRemoteIceConfig))
          as ResRemoteIceConfig;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResRemoteIceConfig() / ResRemoteIceConfig.new instead')
  static ResRemoteIceConfig create() => ResRemoteIceConfig._();
  static $pb.GeneratedMessage $_createMessage() => ResRemoteIceConfig._();
  @$core.override
  ResRemoteIceConfig createEmptyInstance() => ResRemoteIceConfig._();
  @$core.pragma('dart2js:noInline')
  static ResRemoteIceConfig getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResRemoteIceConfig>(
          ResRemoteIceConfig.$_createMessage);
  static ResRemoteIceConfig? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<IceServer> get iceServers => $_getList(0);

  @$pb.TagNumber(2)
  $core.int get ttlSec => $_getIZ(1);
  @$pb.TagNumber(2)
  set ttlSec($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTtlSec() => $_has(1);
  @$pb.TagNumber(2)
  void clearTtlSec() => $_clearField(2);
}

class ReqRemoteScreenshot extends $pb.GeneratedMessage {
  factory ReqRemoteScreenshot({
    $fixnum.Int64? deviceIid,
    $core.int? maxWidth,
    $core.int? quality,
    $core.double? markerX,
    $core.double? markerY,
    $core.bool? som,
  }) {
    final result = ReqRemoteScreenshot._();
    if (deviceIid != null) result.deviceIid = deviceIid;
    if (maxWidth != null) result.maxWidth = maxWidth;
    if (quality != null) result.quality = quality;
    if (markerX != null) result.markerX = markerX;
    if (markerY != null) result.markerY = markerY;
    if (som != null) result.som = som;
    return result;
  }

  ReqRemoteScreenshot._();

  factory ReqRemoteScreenshot.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqRemoteScreenshot()..mergeFromBuffer(data, registry);
  factory ReqRemoteScreenshot.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqRemoteScreenshot()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqRemoteScreenshot',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqRemoteScreenshot.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'deviceIid')
    ..aI(2, _omitFieldNames ? '' : 'maxWidth', fieldType: $pb.PbFieldType.OU3)
    ..aI(3, _omitFieldNames ? '' : 'quality', fieldType: $pb.PbFieldType.OU3)
    ..aD(4, _omitFieldNames ? '' : 'markerX')
    ..aD(5, _omitFieldNames ? '' : 'markerY')
    ..aOB(6, _omitFieldNames ? '' : 'som')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqRemoteScreenshot clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqRemoteScreenshot copyWith(void Function(ReqRemoteScreenshot) updates) =>
      super.copyWith((message) => updates(message as ReqRemoteScreenshot))
          as ReqRemoteScreenshot;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use ReqRemoteScreenshot() / ReqRemoteScreenshot.new instead')
  static ReqRemoteScreenshot create() => ReqRemoteScreenshot._();
  static $pb.GeneratedMessage $_createMessage() => ReqRemoteScreenshot._();
  @$core.override
  ReqRemoteScreenshot createEmptyInstance() => ReqRemoteScreenshot._();
  @$core.pragma('dart2js:noInline')
  static ReqRemoteScreenshot getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqRemoteScreenshot>(
          ReqRemoteScreenshot.$_createMessage);
  static ReqRemoteScreenshot? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get deviceIid => $_getI64(0);
  @$pb.TagNumber(1)
  set deviceIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDeviceIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearDeviceIid() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get maxWidth => $_getIZ(1);
  @$pb.TagNumber(2)
  set maxWidth($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMaxWidth() => $_has(1);
  @$pb.TagNumber(2)
  void clearMaxWidth() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get quality => $_getIZ(2);
  @$pb.TagNumber(3)
  set quality($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasQuality() => $_has(2);
  @$pb.TagNumber(3)
  void clearQuality() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get markerX => $_getN(3);
  @$pb.TagNumber(4)
  set markerX($core.double value) => $_setDouble(3, value);
  @$pb.TagNumber(4)
  $core.bool hasMarkerX() => $_has(3);
  @$pb.TagNumber(4)
  void clearMarkerX() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.double get markerY => $_getN(4);
  @$pb.TagNumber(5)
  set markerY($core.double value) => $_setDouble(4, value);
  @$pb.TagNumber(5)
  $core.bool hasMarkerY() => $_has(4);
  @$pb.TagNumber(5)
  void clearMarkerY() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get som => $_getBF(5);
  @$pb.TagNumber(6)
  set som($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasSom() => $_has(5);
  @$pb.TagNumber(6)
  void clearSom() => $_clearField(6);
}

class ResRemoteScreenshot extends $pb.GeneratedMessage {
  factory ResRemoteScreenshot({
    $core.bool? ok,
    $core.String? error,
    $core.int? width,
    $core.int? height,
    $core.List<$core.int>? jpegBytes,
    $core.String? axtreeText,
  }) {
    final result = ResRemoteScreenshot._();
    if (ok != null) result.ok = ok;
    if (error != null) result.error = error;
    if (width != null) result.width = width;
    if (height != null) result.height = height;
    if (jpegBytes != null) result.jpegBytes = jpegBytes;
    if (axtreeText != null) result.axtreeText = axtreeText;
    return result;
  }

  ResRemoteScreenshot._();

  factory ResRemoteScreenshot.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResRemoteScreenshot()..mergeFromBuffer(data, registry);
  factory ResRemoteScreenshot.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResRemoteScreenshot()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResRemoteScreenshot',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResRemoteScreenshot.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'ok')
    ..aOS(2, _omitFieldNames ? '' : 'error')
    ..aI(3, _omitFieldNames ? '' : 'width', fieldType: $pb.PbFieldType.OU3)
    ..aI(4, _omitFieldNames ? '' : 'height', fieldType: $pb.PbFieldType.OU3)
    ..a<$core.List<$core.int>>(
        5, _omitFieldNames ? '' : 'jpegBytes', $pb.PbFieldType.OY)
    ..aOS(6, _omitFieldNames ? '' : 'axtreeText')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResRemoteScreenshot clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResRemoteScreenshot copyWith(void Function(ResRemoteScreenshot) updates) =>
      super.copyWith((message) => updates(message as ResRemoteScreenshot))
          as ResRemoteScreenshot;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use ResRemoteScreenshot() / ResRemoteScreenshot.new instead')
  static ResRemoteScreenshot create() => ResRemoteScreenshot._();
  static $pb.GeneratedMessage $_createMessage() => ResRemoteScreenshot._();
  @$core.override
  ResRemoteScreenshot createEmptyInstance() => ResRemoteScreenshot._();
  @$core.pragma('dart2js:noInline')
  static ResRemoteScreenshot getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResRemoteScreenshot>(
          ResRemoteScreenshot.$_createMessage);
  static ResRemoteScreenshot? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get ok => $_getBF(0);
  @$pb.TagNumber(1)
  set ok($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOk() => $_has(0);
  @$pb.TagNumber(1)
  void clearOk() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get error => $_getSZ(1);
  @$pb.TagNumber(2)
  set error($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get width => $_getIZ(2);
  @$pb.TagNumber(3)
  set width($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasWidth() => $_has(2);
  @$pb.TagNumber(3)
  void clearWidth() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get height => $_getIZ(3);
  @$pb.TagNumber(4)
  set height($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasHeight() => $_has(3);
  @$pb.TagNumber(4)
  void clearHeight() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.List<$core.int> get jpegBytes => $_getN(4);
  @$pb.TagNumber(5)
  set jpegBytes($core.List<$core.int> value) => $_setBytes(4, value);
  @$pb.TagNumber(5)
  $core.bool hasJpegBytes() => $_has(4);
  @$pb.TagNumber(5)
  void clearJpegBytes() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get axtreeText => $_getSZ(5);
  @$pb.TagNumber(6)
  set axtreeText($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasAxtreeText() => $_has(5);
  @$pb.TagNumber(6)
  void clearAxtreeText() => $_clearField(6);
}

class ReqRemoteCommand extends $pb.GeneratedMessage {
  factory ReqRemoteCommand({
    $fixnum.Int64? deviceIid,
    $core.String? command,
    $core.int? timeoutSec,
  }) {
    final result = ReqRemoteCommand._();
    if (deviceIid != null) result.deviceIid = deviceIid;
    if (command != null) result.command = command;
    if (timeoutSec != null) result.timeoutSec = timeoutSec;
    return result;
  }

  ReqRemoteCommand._();

  factory ReqRemoteCommand.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqRemoteCommand()..mergeFromBuffer(data, registry);
  factory ReqRemoteCommand.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqRemoteCommand()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqRemoteCommand',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqRemoteCommand.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'deviceIid')
    ..aOS(2, _omitFieldNames ? '' : 'command')
    ..aI(3, _omitFieldNames ? '' : 'timeoutSec', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqRemoteCommand clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqRemoteCommand copyWith(void Function(ReqRemoteCommand) updates) =>
      super.copyWith((message) => updates(message as ReqRemoteCommand))
          as ReqRemoteCommand;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqRemoteCommand() / ReqRemoteCommand.new instead')
  static ReqRemoteCommand create() => ReqRemoteCommand._();
  static $pb.GeneratedMessage $_createMessage() => ReqRemoteCommand._();
  @$core.override
  ReqRemoteCommand createEmptyInstance() => ReqRemoteCommand._();
  @$core.pragma('dart2js:noInline')
  static ReqRemoteCommand getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqRemoteCommand>(
          ReqRemoteCommand.$_createMessage);
  static ReqRemoteCommand? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get deviceIid => $_getI64(0);
  @$pb.TagNumber(1)
  set deviceIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDeviceIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearDeviceIid() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get command => $_getSZ(1);
  @$pb.TagNumber(2)
  set command($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCommand() => $_has(1);
  @$pb.TagNumber(2)
  void clearCommand() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get timeoutSec => $_getIZ(2);
  @$pb.TagNumber(3)
  set timeoutSec($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTimeoutSec() => $_has(2);
  @$pb.TagNumber(3)
  void clearTimeoutSec() => $_clearField(3);
}

class ResRemoteCommand extends $pb.GeneratedMessage {
  factory ResRemoteCommand({
    $core.bool? ok,
    $core.String? error,
    $core.int? exitCode,
    $core.String? stdout,
    $core.String? stderr,
  }) {
    final result = ResRemoteCommand._();
    if (ok != null) result.ok = ok;
    if (error != null) result.error = error;
    if (exitCode != null) result.exitCode = exitCode;
    if (stdout != null) result.stdout = stdout;
    if (stderr != null) result.stderr = stderr;
    return result;
  }

  ResRemoteCommand._();

  factory ResRemoteCommand.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResRemoteCommand()..mergeFromBuffer(data, registry);
  factory ResRemoteCommand.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResRemoteCommand()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResRemoteCommand',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResRemoteCommand.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'ok')
    ..aOS(2, _omitFieldNames ? '' : 'error')
    ..aI(3, _omitFieldNames ? '' : 'exitCode')
    ..aOS(4, _omitFieldNames ? '' : 'stdout')
    ..aOS(5, _omitFieldNames ? '' : 'stderr')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResRemoteCommand clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResRemoteCommand copyWith(void Function(ResRemoteCommand) updates) =>
      super.copyWith((message) => updates(message as ResRemoteCommand))
          as ResRemoteCommand;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResRemoteCommand() / ResRemoteCommand.new instead')
  static ResRemoteCommand create() => ResRemoteCommand._();
  static $pb.GeneratedMessage $_createMessage() => ResRemoteCommand._();
  @$core.override
  ResRemoteCommand createEmptyInstance() => ResRemoteCommand._();
  @$core.pragma('dart2js:noInline')
  static ResRemoteCommand getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResRemoteCommand>(
          ResRemoteCommand.$_createMessage);
  static ResRemoteCommand? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get ok => $_getBF(0);
  @$pb.TagNumber(1)
  set ok($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOk() => $_has(0);
  @$pb.TagNumber(1)
  void clearOk() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get error => $_getSZ(1);
  @$pb.TagNumber(2)
  set error($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get exitCode => $_getIZ(2);
  @$pb.TagNumber(3)
  set exitCode($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasExitCode() => $_has(2);
  @$pb.TagNumber(3)
  void clearExitCode() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get stdout => $_getSZ(3);
  @$pb.TagNumber(4)
  set stdout($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasStdout() => $_has(3);
  @$pb.TagNumber(4)
  void clearStdout() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get stderr => $_getSZ(4);
  @$pb.TagNumber(5)
  set stderr($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasStderr() => $_has(4);
  @$pb.TagNumber(5)
  void clearStderr() => $_clearField(5);
}

class RemoteInputEvent extends $pb.GeneratedMessage {
  factory RemoteInputEvent({
    $core.String? eventType,
    $core.double? x,
    $core.double? y,
    $core.int? button,
    $core.int? keyCode,
    $core.String? text,
    $core.int? deltaY,
  }) {
    final result = RemoteInputEvent._();
    if (eventType != null) result.eventType = eventType;
    if (x != null) result.x = x;
    if (y != null) result.y = y;
    if (button != null) result.button = button;
    if (keyCode != null) result.keyCode = keyCode;
    if (text != null) result.text = text;
    if (deltaY != null) result.deltaY = deltaY;
    return result;
  }

  RemoteInputEvent._();

  factory RemoteInputEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoteInputEvent()..mergeFromBuffer(data, registry);
  factory RemoteInputEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoteInputEvent()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RemoteInputEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: RemoteInputEvent.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'eventType')
    ..aD(2, _omitFieldNames ? '' : 'x')
    ..aD(3, _omitFieldNames ? '' : 'y')
    ..aI(4, _omitFieldNames ? '' : 'button')
    ..aI(5, _omitFieldNames ? '' : 'keyCode')
    ..aOS(6, _omitFieldNames ? '' : 'text')
    ..aI(7, _omitFieldNames ? '' : 'deltaY')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoteInputEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoteInputEvent copyWith(void Function(RemoteInputEvent) updates) =>
      super.copyWith((message) => updates(message as RemoteInputEvent))
          as RemoteInputEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RemoteInputEvent() / RemoteInputEvent.new instead')
  static RemoteInputEvent create() => RemoteInputEvent._();
  static $pb.GeneratedMessage $_createMessage() => RemoteInputEvent._();
  @$core.override
  RemoteInputEvent createEmptyInstance() => RemoteInputEvent._();
  @$core.pragma('dart2js:noInline')
  static RemoteInputEvent getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RemoteInputEvent>(
          RemoteInputEvent.$_createMessage);
  static RemoteInputEvent? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get eventType => $_getSZ(0);
  @$pb.TagNumber(1)
  set eventType($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEventType() => $_has(0);
  @$pb.TagNumber(1)
  void clearEventType() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get x => $_getN(1);
  @$pb.TagNumber(2)
  set x($core.double value) => $_setDouble(1, value);
  @$pb.TagNumber(2)
  $core.bool hasX() => $_has(1);
  @$pb.TagNumber(2)
  void clearX() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get y => $_getN(2);
  @$pb.TagNumber(3)
  set y($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasY() => $_has(2);
  @$pb.TagNumber(3)
  void clearY() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get button => $_getIZ(3);
  @$pb.TagNumber(4)
  set button($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasButton() => $_has(3);
  @$pb.TagNumber(4)
  void clearButton() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get keyCode => $_getIZ(4);
  @$pb.TagNumber(5)
  set keyCode($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasKeyCode() => $_has(4);
  @$pb.TagNumber(5)
  void clearKeyCode() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get text => $_getSZ(5);
  @$pb.TagNumber(6)
  set text($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasText() => $_has(5);
  @$pb.TagNumber(6)
  void clearText() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.int get deltaY => $_getIZ(6);
  @$pb.TagNumber(7)
  set deltaY($core.int value) => $_setSignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasDeltaY() => $_has(6);
  @$pb.TagNumber(7)
  void clearDeltaY() => $_clearField(7);
}

class RemoteFsEntry extends $pb.GeneratedMessage {
  factory RemoteFsEntry({
    $core.String? name,
    $core.String? path,
    $core.bool? isDir,
    $fixnum.Int64? size,
    $fixnum.Int64? modifiedMs,
  }) {
    final result = RemoteFsEntry._();
    if (name != null) result.name = name;
    if (path != null) result.path = path;
    if (isDir != null) result.isDir = isDir;
    if (size != null) result.size = size;
    if (modifiedMs != null) result.modifiedMs = modifiedMs;
    return result;
  }

  RemoteFsEntry._();

  factory RemoteFsEntry.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoteFsEntry()..mergeFromBuffer(data, registry);
  factory RemoteFsEntry.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoteFsEntry()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RemoteFsEntry',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: RemoteFsEntry.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'path')
    ..aOB(3, _omitFieldNames ? '' : 'isDir')
    ..aInt64(4, _omitFieldNames ? '' : 'size')
    ..aInt64(5, _omitFieldNames ? '' : 'modifiedMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoteFsEntry clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoteFsEntry copyWith(void Function(RemoteFsEntry) updates) =>
      super.copyWith((message) => updates(message as RemoteFsEntry))
          as RemoteFsEntry;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RemoteFsEntry() / RemoteFsEntry.new instead')
  static RemoteFsEntry create() => RemoteFsEntry._();
  static $pb.GeneratedMessage $_createMessage() => RemoteFsEntry._();
  @$core.override
  RemoteFsEntry createEmptyInstance() => RemoteFsEntry._();
  @$core.pragma('dart2js:noInline')
  static RemoteFsEntry getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RemoteFsEntry>(
          RemoteFsEntry.$_createMessage);
  static RemoteFsEntry? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get path => $_getSZ(1);
  @$pb.TagNumber(2)
  set path($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPath() => $_has(1);
  @$pb.TagNumber(2)
  void clearPath() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get isDir => $_getBF(2);
  @$pb.TagNumber(3)
  set isDir($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasIsDir() => $_has(2);
  @$pb.TagNumber(3)
  void clearIsDir() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get size => $_getI64(3);
  @$pb.TagNumber(4)
  set size($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSize() => $_has(3);
  @$pb.TagNumber(4)
  void clearSize() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get modifiedMs => $_getI64(4);
  @$pb.TagNumber(5)
  set modifiedMs($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasModifiedMs() => $_has(4);
  @$pb.TagNumber(5)
  void clearModifiedMs() => $_clearField(5);
}

class RemoteFsListReq extends $pb.GeneratedMessage {
  factory RemoteFsListReq({
    $core.String? path,
  }) {
    final result = RemoteFsListReq._();
    if (path != null) result.path = path;
    return result;
  }

  RemoteFsListReq._();

  factory RemoteFsListReq.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoteFsListReq()..mergeFromBuffer(data, registry);
  factory RemoteFsListReq.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoteFsListReq()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RemoteFsListReq',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: RemoteFsListReq.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'path')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoteFsListReq clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoteFsListReq copyWith(void Function(RemoteFsListReq) updates) =>
      super.copyWith((message) => updates(message as RemoteFsListReq))
          as RemoteFsListReq;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RemoteFsListReq() / RemoteFsListReq.new instead')
  static RemoteFsListReq create() => RemoteFsListReq._();
  static $pb.GeneratedMessage $_createMessage() => RemoteFsListReq._();
  @$core.override
  RemoteFsListReq createEmptyInstance() => RemoteFsListReq._();
  @$core.pragma('dart2js:noInline')
  static RemoteFsListReq getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RemoteFsListReq>(
          RemoteFsListReq.$_createMessage);
  static RemoteFsListReq? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get path => $_getSZ(0);
  @$pb.TagNumber(1)
  set path($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearPath() => $_clearField(1);
}

class RemoteFsListRes extends $pb.GeneratedMessage {
  factory RemoteFsListRes({
    $core.Iterable<RemoteFsEntry>? entries,
    $core.String? error,
  }) {
    final result = RemoteFsListRes._();
    if (entries != null) result.entries.addAll(entries);
    if (error != null) result.error = error;
    return result;
  }

  RemoteFsListRes._();

  factory RemoteFsListRes.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoteFsListRes()..mergeFromBuffer(data, registry);
  factory RemoteFsListRes.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoteFsListRes()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RemoteFsListRes',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: RemoteFsListRes.$_createMessage)
    ..pPM<RemoteFsEntry>(1, _omitFieldNames ? '' : 'entries',
        subBuilder: RemoteFsEntry.$_createMessage)
    ..aOS(2, _omitFieldNames ? '' : 'error')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoteFsListRes clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoteFsListRes copyWith(void Function(RemoteFsListRes) updates) =>
      super.copyWith((message) => updates(message as RemoteFsListRes))
          as RemoteFsListRes;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RemoteFsListRes() / RemoteFsListRes.new instead')
  static RemoteFsListRes create() => RemoteFsListRes._();
  static $pb.GeneratedMessage $_createMessage() => RemoteFsListRes._();
  @$core.override
  RemoteFsListRes createEmptyInstance() => RemoteFsListRes._();
  @$core.pragma('dart2js:noInline')
  static RemoteFsListRes getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RemoteFsListRes>(
          RemoteFsListRes.$_createMessage);
  static RemoteFsListRes? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<RemoteFsEntry> get entries => $_getList(0);

  @$pb.TagNumber(2)
  $core.String get error => $_getSZ(1);
  @$pb.TagNumber(2)
  set error($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
}

class RemoteFsReadReq extends $pb.GeneratedMessage {
  factory RemoteFsReadReq({
    $core.String? path,
    $fixnum.Int64? offset,
    $core.int? length,
  }) {
    final result = RemoteFsReadReq._();
    if (path != null) result.path = path;
    if (offset != null) result.offset = offset;
    if (length != null) result.length = length;
    return result;
  }

  RemoteFsReadReq._();

  factory RemoteFsReadReq.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoteFsReadReq()..mergeFromBuffer(data, registry);
  factory RemoteFsReadReq.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoteFsReadReq()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RemoteFsReadReq',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: RemoteFsReadReq.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'path')
    ..aInt64(2, _omitFieldNames ? '' : 'offset')
    ..aI(3, _omitFieldNames ? '' : 'length')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoteFsReadReq clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoteFsReadReq copyWith(void Function(RemoteFsReadReq) updates) =>
      super.copyWith((message) => updates(message as RemoteFsReadReq))
          as RemoteFsReadReq;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RemoteFsReadReq() / RemoteFsReadReq.new instead')
  static RemoteFsReadReq create() => RemoteFsReadReq._();
  static $pb.GeneratedMessage $_createMessage() => RemoteFsReadReq._();
  @$core.override
  RemoteFsReadReq createEmptyInstance() => RemoteFsReadReq._();
  @$core.pragma('dart2js:noInline')
  static RemoteFsReadReq getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RemoteFsReadReq>(
          RemoteFsReadReq.$_createMessage);
  static RemoteFsReadReq? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get path => $_getSZ(0);
  @$pb.TagNumber(1)
  set path($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearPath() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get offset => $_getI64(1);
  @$pb.TagNumber(2)
  set offset($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOffset() => $_has(1);
  @$pb.TagNumber(2)
  void clearOffset() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get length => $_getIZ(2);
  @$pb.TagNumber(3)
  set length($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLength() => $_has(2);
  @$pb.TagNumber(3)
  void clearLength() => $_clearField(3);
}

class RemoteFsReadRes extends $pb.GeneratedMessage {
  factory RemoteFsReadRes({
    $core.List<$core.int>? data,
    $core.bool? eof,
    $core.String? mime,
    $core.String? error,
  }) {
    final result = RemoteFsReadRes._();
    if (data != null) result.data = data;
    if (eof != null) result.eof = eof;
    if (mime != null) result.mime = mime;
    if (error != null) result.error = error;
    return result;
  }

  RemoteFsReadRes._();

  factory RemoteFsReadRes.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoteFsReadRes()..mergeFromBuffer(data, registry);
  factory RemoteFsReadRes.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoteFsReadRes()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RemoteFsReadRes',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: RemoteFsReadRes.$_createMessage)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'data', $pb.PbFieldType.OY)
    ..aOB(2, _omitFieldNames ? '' : 'eof')
    ..aOS(3, _omitFieldNames ? '' : 'mime')
    ..aOS(4, _omitFieldNames ? '' : 'error')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoteFsReadRes clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoteFsReadRes copyWith(void Function(RemoteFsReadRes) updates) =>
      super.copyWith((message) => updates(message as RemoteFsReadRes))
          as RemoteFsReadRes;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RemoteFsReadRes() / RemoteFsReadRes.new instead')
  static RemoteFsReadRes create() => RemoteFsReadRes._();
  static $pb.GeneratedMessage $_createMessage() => RemoteFsReadRes._();
  @$core.override
  RemoteFsReadRes createEmptyInstance() => RemoteFsReadRes._();
  @$core.pragma('dart2js:noInline')
  static RemoteFsReadRes getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RemoteFsReadRes>(
          RemoteFsReadRes.$_createMessage);
  static RemoteFsReadRes? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get data => $_getN(0);
  @$pb.TagNumber(1)
  set data($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasData() => $_has(0);
  @$pb.TagNumber(1)
  void clearData() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get eof => $_getBF(1);
  @$pb.TagNumber(2)
  set eof($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEof() => $_has(1);
  @$pb.TagNumber(2)
  void clearEof() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get mime => $_getSZ(2);
  @$pb.TagNumber(3)
  set mime($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMime() => $_has(2);
  @$pb.TagNumber(3)
  void clearMime() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get error => $_getSZ(3);
  @$pb.TagNumber(4)
  set error($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasError() => $_has(3);
  @$pb.TagNumber(4)
  void clearError() => $_clearField(4);
}

class RemoteFsWriteReq extends $pb.GeneratedMessage {
  factory RemoteFsWriteReq({
    $core.String? path,
    $fixnum.Int64? offset,
    $core.List<$core.int>? data,
    $core.bool? finalize,
  }) {
    final result = RemoteFsWriteReq._();
    if (path != null) result.path = path;
    if (offset != null) result.offset = offset;
    if (data != null) result.data = data;
    if (finalize != null) result.finalize = finalize;
    return result;
  }

  RemoteFsWriteReq._();

  factory RemoteFsWriteReq.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoteFsWriteReq()..mergeFromBuffer(data, registry);
  factory RemoteFsWriteReq.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoteFsWriteReq()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RemoteFsWriteReq',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: RemoteFsWriteReq.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'path')
    ..aInt64(2, _omitFieldNames ? '' : 'offset')
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'data', $pb.PbFieldType.OY)
    ..aOB(4, _omitFieldNames ? '' : 'finalize')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoteFsWriteReq clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoteFsWriteReq copyWith(void Function(RemoteFsWriteReq) updates) =>
      super.copyWith((message) => updates(message as RemoteFsWriteReq))
          as RemoteFsWriteReq;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RemoteFsWriteReq() / RemoteFsWriteReq.new instead')
  static RemoteFsWriteReq create() => RemoteFsWriteReq._();
  static $pb.GeneratedMessage $_createMessage() => RemoteFsWriteReq._();
  @$core.override
  RemoteFsWriteReq createEmptyInstance() => RemoteFsWriteReq._();
  @$core.pragma('dart2js:noInline')
  static RemoteFsWriteReq getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RemoteFsWriteReq>(
          RemoteFsWriteReq.$_createMessage);
  static RemoteFsWriteReq? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get path => $_getSZ(0);
  @$pb.TagNumber(1)
  set path($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearPath() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get offset => $_getI64(1);
  @$pb.TagNumber(2)
  set offset($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOffset() => $_has(1);
  @$pb.TagNumber(2)
  void clearOffset() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get data => $_getN(2);
  @$pb.TagNumber(3)
  set data($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasData() => $_has(2);
  @$pb.TagNumber(3)
  void clearData() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get finalize => $_getBF(3);
  @$pb.TagNumber(4)
  set finalize($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasFinalize() => $_has(3);
  @$pb.TagNumber(4)
  void clearFinalize() => $_clearField(4);
}

class RemoteFsWriteRes extends $pb.GeneratedMessage {
  factory RemoteFsWriteRes({
    $fixnum.Int64? bytesWritten,
    $core.String? error,
  }) {
    final result = RemoteFsWriteRes._();
    if (bytesWritten != null) result.bytesWritten = bytesWritten;
    if (error != null) result.error = error;
    return result;
  }

  RemoteFsWriteRes._();

  factory RemoteFsWriteRes.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoteFsWriteRes()..mergeFromBuffer(data, registry);
  factory RemoteFsWriteRes.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoteFsWriteRes()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RemoteFsWriteRes',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: RemoteFsWriteRes.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'bytesWritten')
    ..aOS(2, _omitFieldNames ? '' : 'error')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoteFsWriteRes clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoteFsWriteRes copyWith(void Function(RemoteFsWriteRes) updates) =>
      super.copyWith((message) => updates(message as RemoteFsWriteRes))
          as RemoteFsWriteRes;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RemoteFsWriteRes() / RemoteFsWriteRes.new instead')
  static RemoteFsWriteRes create() => RemoteFsWriteRes._();
  static $pb.GeneratedMessage $_createMessage() => RemoteFsWriteRes._();
  @$core.override
  RemoteFsWriteRes createEmptyInstance() => RemoteFsWriteRes._();
  @$core.pragma('dart2js:noInline')
  static RemoteFsWriteRes getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RemoteFsWriteRes>(
          RemoteFsWriteRes.$_createMessage);
  static RemoteFsWriteRes? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get bytesWritten => $_getI64(0);
  @$pb.TagNumber(1)
  set bytesWritten($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasBytesWritten() => $_has(0);
  @$pb.TagNumber(1)
  void clearBytesWritten() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get error => $_getSZ(1);
  @$pb.TagNumber(2)
  set error($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
