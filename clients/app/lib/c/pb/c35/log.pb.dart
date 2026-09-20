//
//  Generated code. Do not modify.
//  source: c35/log.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

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
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    if (ownerIid != null) {
      $result.ownerIid = ownerIid;
    }
    if (kind != null) {
      $result.kind = kind;
    }
    if (topic != null) {
      $result.topic = topic;
    }
    if (dv != null) {
      $result.dv = dv;
    }
    if (reqId != null) {
      $result.reqId = reqId;
    }
    if (chatId != null) {
      $result.chatId = chatId;
    }
    if (taskId != null) {
      $result.taskId = taskId;
    }
    if (deviceIid != null) {
      $result.deviceIid = deviceIid;
    }
    if (text != null) {
      $result.text = text;
    }
    if (model != null) {
      $result.model = model;
    }
    if (tokensIn != null) {
      $result.tokensIn = tokensIn;
    }
    if (tokensOut != null) {
      $result.tokensOut = tokensOut;
    }
    if (durationMs != null) {
      $result.durationMs = durationMs;
    }
    if (costUsd != null) {
      $result.costUsd = costUsd;
    }
    if (metaJson != null) {
      $result.metaJson = metaJson;
    }
    if (createdTsMs != null) {
      $result.createdTsMs = createdTsMs;
    }
    if (updatedTsMs != null) {
      $result.updatedTsMs = updatedTsMs;
    }
    if (deletedTsMs != null) {
      $result.deletedTsMs = deletedTsMs;
    }
    return $result;
  }
  Log._() : super();
  factory Log.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Log.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Log', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
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
    ..a<$core.int>(12, _omitFieldNames ? '' : 'tokensIn', $pb.PbFieldType.O3)
    ..a<$core.int>(13, _omitFieldNames ? '' : 'tokensOut', $pb.PbFieldType.O3)
    ..a<$core.int>(14, _omitFieldNames ? '' : 'durationMs', $pb.PbFieldType.O3)
    ..a<$core.double>(15, _omitFieldNames ? '' : 'costUsd', $pb.PbFieldType.OD)
    ..aOS(16, _omitFieldNames ? '' : 'metaJson')
    ..aInt64(17, _omitFieldNames ? '' : 'createdTsMs')
    ..aInt64(18, _omitFieldNames ? '' : 'updatedTsMs')
    ..aInt64(19, _omitFieldNames ? '' : 'deletedTsMs')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Log clone() => Log()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Log copyWith(void Function(Log) updates) => super.copyWith((message) => updates(message as Log)) as Log;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Log create() => Log._();
  Log createEmptyInstance() => create();
  static $pb.PbList<Log> createRepeated() => $pb.PbList<Log>();
  @$core.pragma('dart2js:noInline')
  static Log getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Log>(create);
  static Log? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get ownerIid => $_getI64(1);
  @$pb.TagNumber(2)
  set ownerIid($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasOwnerIid() => $_has(1);
  @$pb.TagNumber(2)
  void clearOwnerIid() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get kind => $_getSZ(2);
  @$pb.TagNumber(3)
  set kind($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasKind() => $_has(2);
  @$pb.TagNumber(3)
  void clearKind() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get topic => $_getSZ(3);
  @$pb.TagNumber(4)
  set topic($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasTopic() => $_has(3);
  @$pb.TagNumber(4)
  void clearTopic() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get dv => $_getSZ(4);
  @$pb.TagNumber(5)
  set dv($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasDv() => $_has(4);
  @$pb.TagNumber(5)
  void clearDv() => clearField(5);

  @$pb.TagNumber(6)
  $core.String get reqId => $_getSZ(5);
  @$pb.TagNumber(6)
  set reqId($core.String v) { $_setString(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasReqId() => $_has(5);
  @$pb.TagNumber(6)
  void clearReqId() => clearField(6);

  @$pb.TagNumber(7)
  $fixnum.Int64 get chatId => $_getI64(6);
  @$pb.TagNumber(7)
  set chatId($fixnum.Int64 v) { $_setInt64(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasChatId() => $_has(6);
  @$pb.TagNumber(7)
  void clearChatId() => clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get taskId => $_getI64(7);
  @$pb.TagNumber(8)
  set taskId($fixnum.Int64 v) { $_setInt64(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasTaskId() => $_has(7);
  @$pb.TagNumber(8)
  void clearTaskId() => clearField(8);

  @$pb.TagNumber(9)
  $fixnum.Int64 get deviceIid => $_getI64(8);
  @$pb.TagNumber(9)
  set deviceIid($fixnum.Int64 v) { $_setInt64(8, v); }
  @$pb.TagNumber(9)
  $core.bool hasDeviceIid() => $_has(8);
  @$pb.TagNumber(9)
  void clearDeviceIid() => clearField(9);

  @$pb.TagNumber(10)
  $core.String get text => $_getSZ(9);
  @$pb.TagNumber(10)
  set text($core.String v) { $_setString(9, v); }
  @$pb.TagNumber(10)
  $core.bool hasText() => $_has(9);
  @$pb.TagNumber(10)
  void clearText() => clearField(10);

  @$pb.TagNumber(11)
  $core.String get model => $_getSZ(10);
  @$pb.TagNumber(11)
  set model($core.String v) { $_setString(10, v); }
  @$pb.TagNumber(11)
  $core.bool hasModel() => $_has(10);
  @$pb.TagNumber(11)
  void clearModel() => clearField(11);

  @$pb.TagNumber(12)
  $core.int get tokensIn => $_getIZ(11);
  @$pb.TagNumber(12)
  set tokensIn($core.int v) { $_setSignedInt32(11, v); }
  @$pb.TagNumber(12)
  $core.bool hasTokensIn() => $_has(11);
  @$pb.TagNumber(12)
  void clearTokensIn() => clearField(12);

  @$pb.TagNumber(13)
  $core.int get tokensOut => $_getIZ(12);
  @$pb.TagNumber(13)
  set tokensOut($core.int v) { $_setSignedInt32(12, v); }
  @$pb.TagNumber(13)
  $core.bool hasTokensOut() => $_has(12);
  @$pb.TagNumber(13)
  void clearTokensOut() => clearField(13);

  @$pb.TagNumber(14)
  $core.int get durationMs => $_getIZ(13);
  @$pb.TagNumber(14)
  set durationMs($core.int v) { $_setSignedInt32(13, v); }
  @$pb.TagNumber(14)
  $core.bool hasDurationMs() => $_has(13);
  @$pb.TagNumber(14)
  void clearDurationMs() => clearField(14);

  @$pb.TagNumber(15)
  $core.double get costUsd => $_getN(14);
  @$pb.TagNumber(15)
  set costUsd($core.double v) { $_setDouble(14, v); }
  @$pb.TagNumber(15)
  $core.bool hasCostUsd() => $_has(14);
  @$pb.TagNumber(15)
  void clearCostUsd() => clearField(15);

  @$pb.TagNumber(16)
  $core.String get metaJson => $_getSZ(15);
  @$pb.TagNumber(16)
  set metaJson($core.String v) { $_setString(15, v); }
  @$pb.TagNumber(16)
  $core.bool hasMetaJson() => $_has(15);
  @$pb.TagNumber(16)
  void clearMetaJson() => clearField(16);

  @$pb.TagNumber(17)
  $fixnum.Int64 get createdTsMs => $_getI64(16);
  @$pb.TagNumber(17)
  set createdTsMs($fixnum.Int64 v) { $_setInt64(16, v); }
  @$pb.TagNumber(17)
  $core.bool hasCreatedTsMs() => $_has(16);
  @$pb.TagNumber(17)
  void clearCreatedTsMs() => clearField(17);

  @$pb.TagNumber(18)
  $fixnum.Int64 get updatedTsMs => $_getI64(17);
  @$pb.TagNumber(18)
  set updatedTsMs($fixnum.Int64 v) { $_setInt64(17, v); }
  @$pb.TagNumber(18)
  $core.bool hasUpdatedTsMs() => $_has(17);
  @$pb.TagNumber(18)
  void clearUpdatedTsMs() => clearField(18);

  @$pb.TagNumber(19)
  $fixnum.Int64 get deletedTsMs => $_getI64(18);
  @$pb.TagNumber(19)
  set deletedTsMs($fixnum.Int64 v) { $_setInt64(18, v); }
  @$pb.TagNumber(19)
  $core.bool hasDeletedTsMs() => $_has(18);
  @$pb.TagNumber(19)
  void clearDeletedTsMs() => clearField(19);
}

/// NATS live tail: log.{iid}.{dv}.{topic}
class LogPush extends $pb.GeneratedMessage {
  factory LogPush({
    Log? row,
  }) {
    final $result = create();
    if (row != null) {
      $result.row = row;
    }
    return $result;
  }
  LogPush._() : super();
  factory LogPush.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory LogPush.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'LogPush', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aOM<Log>(1, _omitFieldNames ? '' : 'row', subBuilder: Log.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  LogPush clone() => LogPush()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  LogPush copyWith(void Function(LogPush) updates) => super.copyWith((message) => updates(message as LogPush)) as LogPush;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LogPush create() => LogPush._();
  LogPush createEmptyInstance() => create();
  static $pb.PbList<LogPush> createRepeated() => $pb.PbList<LogPush>();
  @$core.pragma('dart2js:noInline')
  static LogPush getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LogPush>(create);
  static LogPush? _defaultInstance;

  @$pb.TagNumber(1)
  Log get row => $_getN(0);
  @$pb.TagNumber(1)
  set row(Log v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasRow() => $_has(0);
  @$pb.TagNumber(1)
  void clearRow() => clearField(1);
  @$pb.TagNumber(1)
  Log ensureRow() => $_ensure(0);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
