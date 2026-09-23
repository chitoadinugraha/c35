// This is a generated file - do not edit.
//
// Generated from c35/voice.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class ReqVoiceStt extends $pb.GeneratedMessage {
  factory ReqVoiceStt({
    $core.List<$core.int>? audio,
    $core.String? mime,
    $core.String? lang,
    $core.String? reqId,
  }) {
    final result = ReqVoiceStt._();
    if (audio != null) result.audio = audio;
    if (mime != null) result.mime = mime;
    if (lang != null) result.lang = lang;
    if (reqId != null) result.reqId = reqId;
    return result;
  }

  ReqVoiceStt._();

  factory ReqVoiceStt.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqVoiceStt()..mergeFromBuffer(data, registry);
  factory ReqVoiceStt.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqVoiceStt()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqVoiceStt',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqVoiceStt.$_createMessage)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'audio', $pb.PbFieldType.OY)
    ..aOS(2, _omitFieldNames ? '' : 'mime')
    ..aOS(3, _omitFieldNames ? '' : 'lang')
    ..aOS(4, _omitFieldNames ? '' : 'reqId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqVoiceStt clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqVoiceStt copyWith(void Function(ReqVoiceStt) updates) =>
      super.copyWith((message) => updates(message as ReqVoiceStt))
          as ReqVoiceStt;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqVoiceStt() / ReqVoiceStt.new instead')
  static ReqVoiceStt create() => ReqVoiceStt._();
  static $pb.GeneratedMessage $_createMessage() => ReqVoiceStt._();
  @$core.override
  ReqVoiceStt createEmptyInstance() => ReqVoiceStt._();
  @$core.pragma('dart2js:noInline')
  static ReqVoiceStt getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqVoiceStt>(
          ReqVoiceStt.$_createMessage);
  static ReqVoiceStt? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get audio => $_getN(0);
  @$pb.TagNumber(1)
  set audio($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAudio() => $_has(0);
  @$pb.TagNumber(1)
  void clearAudio() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get mime => $_getSZ(1);
  @$pb.TagNumber(2)
  set mime($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMime() => $_has(1);
  @$pb.TagNumber(2)
  void clearMime() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get lang => $_getSZ(2);
  @$pb.TagNumber(3)
  set lang($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLang() => $_has(2);
  @$pb.TagNumber(3)
  void clearLang() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get reqId => $_getSZ(3);
  @$pb.TagNumber(4)
  set reqId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasReqId() => $_has(3);
  @$pb.TagNumber(4)
  void clearReqId() => $_clearField(4);
}

class ResVoiceStt extends $pb.GeneratedMessage {
  factory ResVoiceStt({
    $core.String? text,
    $core.String? error,
  }) {
    final result = ResVoiceStt._();
    if (text != null) result.text = text;
    if (error != null) result.error = error;
    return result;
  }

  ResVoiceStt._();

  factory ResVoiceStt.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResVoiceStt()..mergeFromBuffer(data, registry);
  factory ResVoiceStt.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResVoiceStt()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResVoiceStt',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResVoiceStt.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'text')
    ..aOS(2, _omitFieldNames ? '' : 'error')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResVoiceStt clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResVoiceStt copyWith(void Function(ResVoiceStt) updates) =>
      super.copyWith((message) => updates(message as ResVoiceStt))
          as ResVoiceStt;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResVoiceStt() / ResVoiceStt.new instead')
  static ResVoiceStt create() => ResVoiceStt._();
  static $pb.GeneratedMessage $_createMessage() => ResVoiceStt._();
  @$core.override
  ResVoiceStt createEmptyInstance() => ResVoiceStt._();
  @$core.pragma('dart2js:noInline')
  static ResVoiceStt getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResVoiceStt>(
          ResVoiceStt.$_createMessage);
  static ResVoiceStt? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get text => $_getSZ(0);
  @$pb.TagNumber(1)
  set text($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasText() => $_has(0);
  @$pb.TagNumber(1)
  void clearText() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get error => $_getSZ(1);
  @$pb.TagNumber(2)
  set error($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
}

class ReqVoiceTts extends $pb.GeneratedMessage {
  factory ReqVoiceTts({
    $core.String? text,
    $core.String? lang,
    $core.String? reqId,
  }) {
    final result = ReqVoiceTts._();
    if (text != null) result.text = text;
    if (lang != null) result.lang = lang;
    if (reqId != null) result.reqId = reqId;
    return result;
  }

  ReqVoiceTts._();

  factory ReqVoiceTts.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqVoiceTts()..mergeFromBuffer(data, registry);
  factory ReqVoiceTts.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqVoiceTts()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqVoiceTts',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqVoiceTts.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'text')
    ..aOS(2, _omitFieldNames ? '' : 'lang')
    ..aOS(3, _omitFieldNames ? '' : 'reqId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqVoiceTts clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqVoiceTts copyWith(void Function(ReqVoiceTts) updates) =>
      super.copyWith((message) => updates(message as ReqVoiceTts))
          as ReqVoiceTts;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqVoiceTts() / ReqVoiceTts.new instead')
  static ReqVoiceTts create() => ReqVoiceTts._();
  static $pb.GeneratedMessage $_createMessage() => ReqVoiceTts._();
  @$core.override
  ReqVoiceTts createEmptyInstance() => ReqVoiceTts._();
  @$core.pragma('dart2js:noInline')
  static ReqVoiceTts getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqVoiceTts>(
          ReqVoiceTts.$_createMessage);
  static ReqVoiceTts? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get text => $_getSZ(0);
  @$pb.TagNumber(1)
  set text($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasText() => $_has(0);
  @$pb.TagNumber(1)
  void clearText() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get lang => $_getSZ(1);
  @$pb.TagNumber(2)
  set lang($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLang() => $_has(1);
  @$pb.TagNumber(2)
  void clearLang() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get reqId => $_getSZ(2);
  @$pb.TagNumber(3)
  set reqId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasReqId() => $_has(2);
  @$pb.TagNumber(3)
  void clearReqId() => $_clearField(3);
}

class ResVoiceTts extends $pb.GeneratedMessage {
  factory ResVoiceTts({
    $core.List<$core.int>? audio,
    $core.String? mime,
    $core.String? error,
  }) {
    final result = ResVoiceTts._();
    if (audio != null) result.audio = audio;
    if (mime != null) result.mime = mime;
    if (error != null) result.error = error;
    return result;
  }

  ResVoiceTts._();

  factory ResVoiceTts.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResVoiceTts()..mergeFromBuffer(data, registry);
  factory ResVoiceTts.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResVoiceTts()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResVoiceTts',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResVoiceTts.$_createMessage)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'audio', $pb.PbFieldType.OY)
    ..aOS(2, _omitFieldNames ? '' : 'mime')
    ..aOS(3, _omitFieldNames ? '' : 'error')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResVoiceTts clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResVoiceTts copyWith(void Function(ResVoiceTts) updates) =>
      super.copyWith((message) => updates(message as ResVoiceTts))
          as ResVoiceTts;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResVoiceTts() / ResVoiceTts.new instead')
  static ResVoiceTts create() => ResVoiceTts._();
  static $pb.GeneratedMessage $_createMessage() => ResVoiceTts._();
  @$core.override
  ResVoiceTts createEmptyInstance() => ResVoiceTts._();
  @$core.pragma('dart2js:noInline')
  static ResVoiceTts getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResVoiceTts>(
          ResVoiceTts.$_createMessage);
  static ResVoiceTts? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get audio => $_getN(0);
  @$pb.TagNumber(1)
  set audio($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAudio() => $_has(0);
  @$pb.TagNumber(1)
  void clearAudio() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get mime => $_getSZ(1);
  @$pb.TagNumber(2)
  set mime($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMime() => $_has(1);
  @$pb.TagNumber(2)
  void clearMime() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get error => $_getSZ(2);
  @$pb.TagNumber(3)
  set error($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasError() => $_has(2);
  @$pb.TagNumber(3)
  void clearError() => $_clearField(3);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
