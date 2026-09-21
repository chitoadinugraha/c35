// This is a generated file - do not edit.
//
// Generated from c35/log.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class Log extends $pb.GeneratedMessage {
  factory Log({
    $fixnum.Int64? id,
    $fixnum.Int64? ownerIid,
    $core.String? kind,
    $core.String? topic,
    $core.String? dv,
    $core.String? reqId,
    $fixnum.Int64? chatId,
    $fixnum.Int64? taskId,
    $fixnum.Int64? deviceIid,
    $core.String? text,
    $core.String? model,
    $core.int? tokensIn,
    $core.int? tokensOut,
    $core.int? durationMs,
    $core.double? costUsd,
    $core.String? metaJson,
    $fixnum.Int64? createdTsMs,
    $fixnum.Int64? updatedTsMs,
    $fixnum.Int64? deletedTsMs,
  }) {
    final result = Log._();
    if (id != null) result.id = id;
    if (ownerIid != null) result.ownerIid = ownerIid;
    if (kind != null) result.kind = kind;
    if (topic != null) result.topic = topic;
    if (dv != null) result.dv = dv;
    if (reqId != null) result.reqId = reqId;
    if (chatId != null) result.chatId = chatId;
    if (taskId != null) result.taskId = taskId;
    if (deviceIid != null) result.deviceIid = deviceIid;
    if (text != null) result.text = text;
    if (model != null) result.model = model;
    if (tokensIn != null) result.tokensIn = tokensIn;
    if (tokensOut != null) result.tokensOut = tokensOut;
    if (durationMs != null) result.durationMs = durationMs;
    if (costUsd != null) result.costUsd = costUsd;
    if (metaJson != null) result.metaJson = metaJson;
    if (createdTsMs != null) result.createdTsMs = createdTsMs;
    if (updatedTsMs != null) result.updatedTsMs = updatedTsMs;
    if (deletedTsMs != null) result.deletedTsMs = deletedTsMs;
    return result;
  }

  Log._();

  factory Log.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Log()..mergeFromBuffer(data, registry);
  factory Log.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Log()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Log',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: Log.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..aInt64(2, _omitFieldNames ? '' : 'ownerIid')
    ..aOS(3, _omitFieldNames ? '' : 'kind')
    ..aOS(4, _omitFieldNames ? '' : 'topic')
    ..aOS(5, _omitFieldNames ? '' : 'dv')
    ..aOS(6, _omitFieldNames ? '' : 'reqId')
    ..aInt64(7, _omitFieldNames ? '' : 'chatId')
    ..aInt64(8, _omitFieldNames ? '' : 'taskId')
    ..aInt64(9, _omitFieldNames ? '' : 'deviceIid')
    ..aOS(10, _omitFieldNames ? '' : 'text')
    ..aOS(11, _omitFieldNames ? '' : 'model')
    ..aI(12, _omitFieldNames ? '' : 'tokensIn')
    ..aI(13, _omitFieldNames ? '' : 'tokensOut')
    ..aI(14, _omitFieldNames ? '' : 'durationMs')
    ..aD(15, _omitFieldNames ? '' : 'costUsd')
    ..aOS(16, _omitFieldNames ? '' : 'metaJson')
    ..aInt64(17, _omitFieldNames ? '' : 'createdTsMs')
    ..aInt64(18, _omitFieldNames ? '' : 'updatedTsMs')
    ..aInt64(19, _omitFieldNames ? '' : 'deletedTsMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Log clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Log copyWith(void Function(Log) updates) =>
      super.copyWith((message) => updates(message as Log)) as Log;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Log() / Log.new instead')
  static Log create() => Log._();
  static $pb.GeneratedMessage $_createMessage() => Log._();
  @$core.override
  Log createEmptyInstance() => Log._();
  @$core.pragma('dart2js:noInline')
  static Log getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Log>(Log.$_createMessage);
  static Log? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get ownerIid => $_getI64(1);
  @$pb.TagNumber(2)
  set ownerIid($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOwnerIid() => $_has(1);
  @$pb.TagNumber(2)
  void clearOwnerIid() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get kind => $_getSZ(2);
  @$pb.TagNumber(3)
  set kind($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasKind() => $_has(2);
  @$pb.TagNumber(3)
  void clearKind() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get topic => $_getSZ(3);
  @$pb.TagNumber(4)
  set topic($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTopic() => $_has(3);
  @$pb.TagNumber(4)
  void clearTopic() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get dv => $_getSZ(4);
  @$pb.TagNumber(5)
  set dv($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasDv() => $_has(4);
  @$pb.TagNumber(5)
  void clearDv() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get reqId => $_getSZ(5);
  @$pb.TagNumber(6)
  set reqId($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasReqId() => $_has(5);
  @$pb.TagNumber(6)
  void clearReqId() => $_clearField(6);

  @$pb.TagNumber(7)
  $fixnum.Int64 get chatId => $_getI64(6);
  @$pb.TagNumber(7)
  set chatId($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(7)
  $core.bool hasChatId() => $_has(6);
  @$pb.TagNumber(7)
  void clearChatId() => $_clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get taskId => $_getI64(7);
  @$pb.TagNumber(8)
  set taskId($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(8)
  $core.bool hasTaskId() => $_has(7);
  @$pb.TagNumber(8)
  void clearTaskId() => $_clearField(8);

  @$pb.TagNumber(9)
  $fixnum.Int64 get deviceIid => $_getI64(8);
  @$pb.TagNumber(9)
  set deviceIid($fixnum.Int64 value) => $_setInt64(8, value);
  @$pb.TagNumber(9)
  $core.bool hasDeviceIid() => $_has(8);
  @$pb.TagNumber(9)
  void clearDeviceIid() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.String get text => $_getSZ(9);
  @$pb.TagNumber(10)
  set text($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasText() => $_has(9);
  @$pb.TagNumber(10)
  void clearText() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.String get model => $_getSZ(10);
  @$pb.TagNumber(11)
  set model($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasModel() => $_has(10);
  @$pb.TagNumber(11)
  void clearModel() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.int get tokensIn => $_getIZ(11);
  @$pb.TagNumber(12)
  set tokensIn($core.int value) => $_setSignedInt32(11, value);
  @$pb.TagNumber(12)
  $core.bool hasTokensIn() => $_has(11);
  @$pb.TagNumber(12)
  void clearTokensIn() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.int get tokensOut => $_getIZ(12);
  @$pb.TagNumber(13)
  set tokensOut($core.int value) => $_setSignedInt32(12, value);
  @$pb.TagNumber(13)
  $core.bool hasTokensOut() => $_has(12);
  @$pb.TagNumber(13)
  void clearTokensOut() => $_clearField(13);

  @$pb.TagNumber(14)
  $core.int get durationMs => $_getIZ(13);
  @$pb.TagNumber(14)
  set durationMs($core.int value) => $_setSignedInt32(13, value);
  @$pb.TagNumber(14)
  $core.bool hasDurationMs() => $_has(13);
  @$pb.TagNumber(14)
  void clearDurationMs() => $_clearField(14);

  @$pb.TagNumber(15)
  $core.double get costUsd => $_getN(14);
  @$pb.TagNumber(15)
  set costUsd($core.double value) => $_setDouble(14, value);
  @$pb.TagNumber(15)
  $core.bool hasCostUsd() => $_has(14);
  @$pb.TagNumber(15)
  void clearCostUsd() => $_clearField(15);

  @$pb.TagNumber(16)
  $core.String get metaJson => $_getSZ(15);
  @$pb.TagNumber(16)
  set metaJson($core.String value) => $_setString(15, value);
  @$pb.TagNumber(16)
  $core.bool hasMetaJson() => $_has(15);
  @$pb.TagNumber(16)
  void clearMetaJson() => $_clearField(16);

  @$pb.TagNumber(17)
  $fixnum.Int64 get createdTsMs => $_getI64(16);
  @$pb.TagNumber(17)
  set createdTsMs($fixnum.Int64 value) => $_setInt64(16, value);
  @$pb.TagNumber(17)
  $core.bool hasCreatedTsMs() => $_has(16);
  @$pb.TagNumber(17)
  void clearCreatedTsMs() => $_clearField(17);

  @$pb.TagNumber(18)
  $fixnum.Int64 get updatedTsMs => $_getI64(17);
  @$pb.TagNumber(18)
  set updatedTsMs($fixnum.Int64 value) => $_setInt64(17, value);
  @$pb.TagNumber(18)
  $core.bool hasUpdatedTsMs() => $_has(17);
  @$pb.TagNumber(18)
  void clearUpdatedTsMs() => $_clearField(18);

  @$pb.TagNumber(19)
  $fixnum.Int64 get deletedTsMs => $_getI64(18);
  @$pb.TagNumber(19)
  set deletedTsMs($fixnum.Int64 value) => $_setInt64(18, value);
  @$pb.TagNumber(19)
  $core.bool hasDeletedTsMs() => $_has(18);
  @$pb.TagNumber(19)
  void clearDeletedTsMs() => $_clearField(19);
}

/// NATS live tail: log.{iid}.{dv}.{topic}
class LogPush extends $pb.GeneratedMessage {
  factory LogPush({
    Log? row,
  }) {
    final result = LogPush._();
    if (row != null) result.row = row;
    return result;
  }

  LogPush._();

  factory LogPush.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LogPush()..mergeFromBuffer(data, registry);
  factory LogPush.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LogPush()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LogPush',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: LogPush.$_createMessage)
    ..aOM<Log>(1, _omitFieldNames ? '' : 'row', subBuilder: Log.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LogPush clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LogPush copyWith(void Function(LogPush) updates) =>
      super.copyWith((message) => updates(message as LogPush)) as LogPush;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use LogPush() / LogPush.new instead')
  static LogPush create() => LogPush._();
  static $pb.GeneratedMessage $_createMessage() => LogPush._();
  @$core.override
  LogPush createEmptyInstance() => LogPush._();
  @$core.pragma('dart2js:noInline')
  static LogPush getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LogPush>(LogPush.$_createMessage);
  static LogPush? _defaultInstance;

  @$pb.TagNumber(1)
  Log get row => $_getN(0);
  @$pb.TagNumber(1)
  set row(Log value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasRow() => $_has(0);
  @$pb.TagNumber(1)
  void clearRow() => $_clearField(1);
  @$pb.TagNumber(1)
  Log ensureRow() => $_ensure(0);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
