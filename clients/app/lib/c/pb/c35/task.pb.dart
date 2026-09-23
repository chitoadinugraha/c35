// This is a generated file - do not edit.
//
// Generated from c35/task.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'task.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'task.pbenum.dart';

class TaskTrigger extends $pb.GeneratedMessage {
  factory TaskTrigger({
    $fixnum.Int64? id,
    $fixnum.Int64? taskId,
    $fixnum.Int64? ownerIid,
    TaskTriggerKind? kind,
    $core.String? label,
    $core.String? cronExpr,
    $core.String? timezone,
    $fixnum.Int64? runAtMs,
    $core.String? webhookSecret,
    $core.bool? isActive,
    $fixnum.Int64? createdTsMs,
    $fixnum.Int64? updatedTsMs,
    $fixnum.Int64? deletedTsMs,
  }) {
    final result = TaskTrigger._();
    if (id != null) result.id = id;
    if (taskId != null) result.taskId = taskId;
    if (ownerIid != null) result.ownerIid = ownerIid;
    if (kind != null) result.kind = kind;
    if (label != null) result.label = label;
    if (cronExpr != null) result.cronExpr = cronExpr;
    if (timezone != null) result.timezone = timezone;
    if (runAtMs != null) result.runAtMs = runAtMs;
    if (webhookSecret != null) result.webhookSecret = webhookSecret;
    if (isActive != null) result.isActive = isActive;
    if (createdTsMs != null) result.createdTsMs = createdTsMs;
    if (updatedTsMs != null) result.updatedTsMs = updatedTsMs;
    if (deletedTsMs != null) result.deletedTsMs = deletedTsMs;
    return result;
  }

  TaskTrigger._();

  factory TaskTrigger.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TaskTrigger()..mergeFromBuffer(data, registry);
  factory TaskTrigger.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TaskTrigger()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TaskTrigger',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: TaskTrigger.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..aInt64(2, _omitFieldNames ? '' : 'taskId')
    ..aInt64(3, _omitFieldNames ? '' : 'ownerIid')
    ..aE<TaskTriggerKind>(4, _omitFieldNames ? '' : 'kind',
        enumValues: TaskTriggerKind.values)
    ..aOS(5, _omitFieldNames ? '' : 'label')
    ..aOS(6, _omitFieldNames ? '' : 'cronExpr')
    ..aOS(7, _omitFieldNames ? '' : 'timezone')
    ..aInt64(8, _omitFieldNames ? '' : 'runAtMs')
    ..aOS(9, _omitFieldNames ? '' : 'webhookSecret')
    ..aOB(10, _omitFieldNames ? '' : 'isActive')
    ..aInt64(20, _omitFieldNames ? '' : 'createdTsMs')
    ..aInt64(21, _omitFieldNames ? '' : 'updatedTsMs')
    ..aInt64(22, _omitFieldNames ? '' : 'deletedTsMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TaskTrigger clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TaskTrigger copyWith(void Function(TaskTrigger) updates) =>
      super.copyWith((message) => updates(message as TaskTrigger))
          as TaskTrigger;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use TaskTrigger() / TaskTrigger.new instead')
  static TaskTrigger create() => TaskTrigger._();
  static $pb.GeneratedMessage $_createMessage() => TaskTrigger._();
  @$core.override
  TaskTrigger createEmptyInstance() => TaskTrigger._();
  @$core.pragma('dart2js:noInline')
  static TaskTrigger getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TaskTrigger>(
          TaskTrigger.$_createMessage);
  static TaskTrigger? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get taskId => $_getI64(1);
  @$pb.TagNumber(2)
  set taskId($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTaskId() => $_has(1);
  @$pb.TagNumber(2)
  void clearTaskId() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get ownerIid => $_getI64(2);
  @$pb.TagNumber(3)
  set ownerIid($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasOwnerIid() => $_has(2);
  @$pb.TagNumber(3)
  void clearOwnerIid() => $_clearField(3);

  @$pb.TagNumber(4)
  TaskTriggerKind get kind => $_getN(3);
  @$pb.TagNumber(4)
  set kind(TaskTriggerKind value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasKind() => $_has(3);
  @$pb.TagNumber(4)
  void clearKind() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get label => $_getSZ(4);
  @$pb.TagNumber(5)
  set label($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasLabel() => $_has(4);
  @$pb.TagNumber(5)
  void clearLabel() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get cronExpr => $_getSZ(5);
  @$pb.TagNumber(6)
  set cronExpr($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasCronExpr() => $_has(5);
  @$pb.TagNumber(6)
  void clearCronExpr() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get timezone => $_getSZ(6);
  @$pb.TagNumber(7)
  set timezone($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasTimezone() => $_has(6);
  @$pb.TagNumber(7)
  void clearTimezone() => $_clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get runAtMs => $_getI64(7);
  @$pb.TagNumber(8)
  set runAtMs($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(8)
  $core.bool hasRunAtMs() => $_has(7);
  @$pb.TagNumber(8)
  void clearRunAtMs() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get webhookSecret => $_getSZ(8);
  @$pb.TagNumber(9)
  set webhookSecret($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasWebhookSecret() => $_has(8);
  @$pb.TagNumber(9)
  void clearWebhookSecret() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.bool get isActive => $_getBF(9);
  @$pb.TagNumber(10)
  set isActive($core.bool value) => $_setBool(9, value);
  @$pb.TagNumber(10)
  $core.bool hasIsActive() => $_has(9);
  @$pb.TagNumber(10)
  void clearIsActive() => $_clearField(10);

  @$pb.TagNumber(20)
  $fixnum.Int64 get createdTsMs => $_getI64(10);
  @$pb.TagNumber(20)
  set createdTsMs($fixnum.Int64 value) => $_setInt64(10, value);
  @$pb.TagNumber(20)
  $core.bool hasCreatedTsMs() => $_has(10);
  @$pb.TagNumber(20)
  void clearCreatedTsMs() => $_clearField(20);

  @$pb.TagNumber(21)
  $fixnum.Int64 get updatedTsMs => $_getI64(11);
  @$pb.TagNumber(21)
  set updatedTsMs($fixnum.Int64 value) => $_setInt64(11, value);
  @$pb.TagNumber(21)
  $core.bool hasUpdatedTsMs() => $_has(11);
  @$pb.TagNumber(21)
  void clearUpdatedTsMs() => $_clearField(21);

  @$pb.TagNumber(22)
  $fixnum.Int64 get deletedTsMs => $_getI64(12);
  @$pb.TagNumber(22)
  set deletedTsMs($fixnum.Int64 value) => $_setInt64(12, value);
  @$pb.TagNumber(22)
  $core.bool hasDeletedTsMs() => $_has(12);
  @$pb.TagNumber(22)
  void clearDeletedTsMs() => $_clearField(22);
}

class Task extends $pb.GeneratedMessage {
  factory Task({
    $fixnum.Int64? id,
    $fixnum.Int64? ownerIid,
    $fixnum.Int64? deviceIid,
    $core.String? name,
    $fixnum.Int64? skillId,
    $core.String? prompt,
    $core.String? model,
    $core.bool? isActive,
    $core.Iterable<TaskTrigger>? triggers,
    $fixnum.Int64? createdTsMs,
    $fixnum.Int64? updatedTsMs,
    $fixnum.Int64? deletedTsMs,
  }) {
    final result = Task._();
    if (id != null) result.id = id;
    if (ownerIid != null) result.ownerIid = ownerIid;
    if (deviceIid != null) result.deviceIid = deviceIid;
    if (name != null) result.name = name;
    if (skillId != null) result.skillId = skillId;
    if (prompt != null) result.prompt = prompt;
    if (model != null) result.model = model;
    if (isActive != null) result.isActive = isActive;
    if (triggers != null) result.triggers.addAll(triggers);
    if (createdTsMs != null) result.createdTsMs = createdTsMs;
    if (updatedTsMs != null) result.updatedTsMs = updatedTsMs;
    if (deletedTsMs != null) result.deletedTsMs = deletedTsMs;
    return result;
  }

  Task._();

  factory Task.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Task()..mergeFromBuffer(data, registry);
  factory Task.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Task()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Task',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: Task.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..aInt64(2, _omitFieldNames ? '' : 'ownerIid')
    ..aInt64(3, _omitFieldNames ? '' : 'deviceIid')
    ..aOS(4, _omitFieldNames ? '' : 'name')
    ..aInt64(5, _omitFieldNames ? '' : 'skillId')
    ..aOS(6, _omitFieldNames ? '' : 'prompt')
    ..aOS(7, _omitFieldNames ? '' : 'model')
    ..aOB(8, _omitFieldNames ? '' : 'isActive')
    ..pPM<TaskTrigger>(9, _omitFieldNames ? '' : 'triggers',
        subBuilder: TaskTrigger.$_createMessage)
    ..aInt64(20, _omitFieldNames ? '' : 'createdTsMs')
    ..aInt64(21, _omitFieldNames ? '' : 'updatedTsMs')
    ..aInt64(22, _omitFieldNames ? '' : 'deletedTsMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Task clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Task copyWith(void Function(Task) updates) =>
      super.copyWith((message) => updates(message as Task)) as Task;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Task() / Task.new instead')
  static Task create() => Task._();
  static $pb.GeneratedMessage $_createMessage() => Task._();
  @$core.override
  Task createEmptyInstance() => Task._();
  @$core.pragma('dart2js:noInline')
  static Task getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Task>(Task.$_createMessage);
  static Task? _defaultInstance;

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
  $fixnum.Int64 get deviceIid => $_getI64(2);
  @$pb.TagNumber(3)
  set deviceIid($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDeviceIid() => $_has(2);
  @$pb.TagNumber(3)
  void clearDeviceIid() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get name => $_getSZ(3);
  @$pb.TagNumber(4)
  set name($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasName() => $_has(3);
  @$pb.TagNumber(4)
  void clearName() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get skillId => $_getI64(4);
  @$pb.TagNumber(5)
  set skillId($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSkillId() => $_has(4);
  @$pb.TagNumber(5)
  void clearSkillId() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get prompt => $_getSZ(5);
  @$pb.TagNumber(6)
  set prompt($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasPrompt() => $_has(5);
  @$pb.TagNumber(6)
  void clearPrompt() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get model => $_getSZ(6);
  @$pb.TagNumber(7)
  set model($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasModel() => $_has(6);
  @$pb.TagNumber(7)
  void clearModel() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.bool get isActive => $_getBF(7);
  @$pb.TagNumber(8)
  set isActive($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasIsActive() => $_has(7);
  @$pb.TagNumber(8)
  void clearIsActive() => $_clearField(8);

  @$pb.TagNumber(9)
  $pb.PbList<TaskTrigger> get triggers => $_getList(8);

  @$pb.TagNumber(20)
  $fixnum.Int64 get createdTsMs => $_getI64(9);
  @$pb.TagNumber(20)
  set createdTsMs($fixnum.Int64 value) => $_setInt64(9, value);
  @$pb.TagNumber(20)
  $core.bool hasCreatedTsMs() => $_has(9);
  @$pb.TagNumber(20)
  void clearCreatedTsMs() => $_clearField(20);

  @$pb.TagNumber(21)
  $fixnum.Int64 get updatedTsMs => $_getI64(10);
  @$pb.TagNumber(21)
  set updatedTsMs($fixnum.Int64 value) => $_setInt64(10, value);
  @$pb.TagNumber(21)
  $core.bool hasUpdatedTsMs() => $_has(10);
  @$pb.TagNumber(21)
  void clearUpdatedTsMs() => $_clearField(21);

  @$pb.TagNumber(22)
  $fixnum.Int64 get deletedTsMs => $_getI64(11);
  @$pb.TagNumber(22)
  set deletedTsMs($fixnum.Int64 value) => $_setInt64(11, value);
  @$pb.TagNumber(22)
  $core.bool hasDeletedTsMs() => $_has(11);
  @$pb.TagNumber(22)
  void clearDeletedTsMs() => $_clearField(22);
}

class TaskRun extends $pb.GeneratedMessage {
  factory TaskRun({
    $fixnum.Int64? id,
    $fixnum.Int64? ownerIid,
    $fixnum.Int64? deviceIid,
    $fixnum.Int64? taskId,
    $fixnum.Int64? triggerId,
    $fixnum.Int64? chatId,
    $core.String? reqId,
    TaskRunStatus? status,
    $core.String? prompt,
    $fixnum.Int64? skillId,
    $core.String? model,
    $core.int? stepIndex,
    $core.String? summary,
    $core.String? error,
    $core.String? leasePod,
    $fixnum.Int64? leaseExpiresTsMs,
    $fixnum.Int64? startedTsMs,
    $fixnum.Int64? finishedTsMs,
    $fixnum.Int64? createdTsMs,
    $fixnum.Int64? updatedTsMs,
    $fixnum.Int64? deletedTsMs,
  }) {
    final result = TaskRun._();
    if (id != null) result.id = id;
    if (ownerIid != null) result.ownerIid = ownerIid;
    if (deviceIid != null) result.deviceIid = deviceIid;
    if (taskId != null) result.taskId = taskId;
    if (triggerId != null) result.triggerId = triggerId;
    if (chatId != null) result.chatId = chatId;
    if (reqId != null) result.reqId = reqId;
    if (status != null) result.status = status;
    if (prompt != null) result.prompt = prompt;
    if (skillId != null) result.skillId = skillId;
    if (model != null) result.model = model;
    if (stepIndex != null) result.stepIndex = stepIndex;
    if (summary != null) result.summary = summary;
    if (error != null) result.error = error;
    if (leasePod != null) result.leasePod = leasePod;
    if (leaseExpiresTsMs != null) result.leaseExpiresTsMs = leaseExpiresTsMs;
    if (startedTsMs != null) result.startedTsMs = startedTsMs;
    if (finishedTsMs != null) result.finishedTsMs = finishedTsMs;
    if (createdTsMs != null) result.createdTsMs = createdTsMs;
    if (updatedTsMs != null) result.updatedTsMs = updatedTsMs;
    if (deletedTsMs != null) result.deletedTsMs = deletedTsMs;
    return result;
  }

  TaskRun._();

  factory TaskRun.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TaskRun()..mergeFromBuffer(data, registry);
  factory TaskRun.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TaskRun()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TaskRun',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: TaskRun.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..aInt64(2, _omitFieldNames ? '' : 'ownerIid')
    ..aInt64(3, _omitFieldNames ? '' : 'deviceIid')
    ..aInt64(4, _omitFieldNames ? '' : 'taskId')
    ..aInt64(5, _omitFieldNames ? '' : 'triggerId')
    ..aInt64(6, _omitFieldNames ? '' : 'chatId')
    ..aOS(7, _omitFieldNames ? '' : 'reqId')
    ..aE<TaskRunStatus>(8, _omitFieldNames ? '' : 'status',
        enumValues: TaskRunStatus.values)
    ..aOS(9, _omitFieldNames ? '' : 'prompt')
    ..aInt64(10, _omitFieldNames ? '' : 'skillId')
    ..aOS(11, _omitFieldNames ? '' : 'model')
    ..aI(12, _omitFieldNames ? '' : 'stepIndex')
    ..aOS(13, _omitFieldNames ? '' : 'summary')
    ..aOS(14, _omitFieldNames ? '' : 'error')
    ..aOS(15, _omitFieldNames ? '' : 'leasePod')
    ..aInt64(16, _omitFieldNames ? '' : 'leaseExpiresTsMs')
    ..aInt64(17, _omitFieldNames ? '' : 'startedTsMs')
    ..aInt64(18, _omitFieldNames ? '' : 'finishedTsMs')
    ..aInt64(20, _omitFieldNames ? '' : 'createdTsMs')
    ..aInt64(21, _omitFieldNames ? '' : 'updatedTsMs')
    ..aInt64(22, _omitFieldNames ? '' : 'deletedTsMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TaskRun clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TaskRun copyWith(void Function(TaskRun) updates) =>
      super.copyWith((message) => updates(message as TaskRun)) as TaskRun;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use TaskRun() / TaskRun.new instead')
  static TaskRun create() => TaskRun._();
  static $pb.GeneratedMessage $_createMessage() => TaskRun._();
  @$core.override
  TaskRun createEmptyInstance() => TaskRun._();
  @$core.pragma('dart2js:noInline')
  static TaskRun getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TaskRun>(TaskRun.$_createMessage);
  static TaskRun? _defaultInstance;

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
  $fixnum.Int64 get deviceIid => $_getI64(2);
  @$pb.TagNumber(3)
  set deviceIid($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDeviceIid() => $_has(2);
  @$pb.TagNumber(3)
  void clearDeviceIid() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get taskId => $_getI64(3);
  @$pb.TagNumber(4)
  set taskId($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTaskId() => $_has(3);
  @$pb.TagNumber(4)
  void clearTaskId() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get triggerId => $_getI64(4);
  @$pb.TagNumber(5)
  set triggerId($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasTriggerId() => $_has(4);
  @$pb.TagNumber(5)
  void clearTriggerId() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get chatId => $_getI64(5);
  @$pb.TagNumber(6)
  set chatId($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasChatId() => $_has(5);
  @$pb.TagNumber(6)
  void clearChatId() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get reqId => $_getSZ(6);
  @$pb.TagNumber(7)
  set reqId($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasReqId() => $_has(6);
  @$pb.TagNumber(7)
  void clearReqId() => $_clearField(7);

  @$pb.TagNumber(8)
  TaskRunStatus get status => $_getN(7);
  @$pb.TagNumber(8)
  set status(TaskRunStatus value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasStatus() => $_has(7);
  @$pb.TagNumber(8)
  void clearStatus() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get prompt => $_getSZ(8);
  @$pb.TagNumber(9)
  set prompt($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasPrompt() => $_has(8);
  @$pb.TagNumber(9)
  void clearPrompt() => $_clearField(9);

  @$pb.TagNumber(10)
  $fixnum.Int64 get skillId => $_getI64(9);
  @$pb.TagNumber(10)
  set skillId($fixnum.Int64 value) => $_setInt64(9, value);
  @$pb.TagNumber(10)
  $core.bool hasSkillId() => $_has(9);
  @$pb.TagNumber(10)
  void clearSkillId() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.String get model => $_getSZ(10);
  @$pb.TagNumber(11)
  set model($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasModel() => $_has(10);
  @$pb.TagNumber(11)
  void clearModel() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.int get stepIndex => $_getIZ(11);
  @$pb.TagNumber(12)
  set stepIndex($core.int value) => $_setSignedInt32(11, value);
  @$pb.TagNumber(12)
  $core.bool hasStepIndex() => $_has(11);
  @$pb.TagNumber(12)
  void clearStepIndex() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.String get summary => $_getSZ(12);
  @$pb.TagNumber(13)
  set summary($core.String value) => $_setString(12, value);
  @$pb.TagNumber(13)
  $core.bool hasSummary() => $_has(12);
  @$pb.TagNumber(13)
  void clearSummary() => $_clearField(13);

  @$pb.TagNumber(14)
  $core.String get error => $_getSZ(13);
  @$pb.TagNumber(14)
  set error($core.String value) => $_setString(13, value);
  @$pb.TagNumber(14)
  $core.bool hasError() => $_has(13);
  @$pb.TagNumber(14)
  void clearError() => $_clearField(14);

  @$pb.TagNumber(15)
  $core.String get leasePod => $_getSZ(14);
  @$pb.TagNumber(15)
  set leasePod($core.String value) => $_setString(14, value);
  @$pb.TagNumber(15)
  $core.bool hasLeasePod() => $_has(14);
  @$pb.TagNumber(15)
  void clearLeasePod() => $_clearField(15);

  @$pb.TagNumber(16)
  $fixnum.Int64 get leaseExpiresTsMs => $_getI64(15);
  @$pb.TagNumber(16)
  set leaseExpiresTsMs($fixnum.Int64 value) => $_setInt64(15, value);
  @$pb.TagNumber(16)
  $core.bool hasLeaseExpiresTsMs() => $_has(15);
  @$pb.TagNumber(16)
  void clearLeaseExpiresTsMs() => $_clearField(16);

  @$pb.TagNumber(17)
  $fixnum.Int64 get startedTsMs => $_getI64(16);
  @$pb.TagNumber(17)
  set startedTsMs($fixnum.Int64 value) => $_setInt64(16, value);
  @$pb.TagNumber(17)
  $core.bool hasStartedTsMs() => $_has(16);
  @$pb.TagNumber(17)
  void clearStartedTsMs() => $_clearField(17);

  @$pb.TagNumber(18)
  $fixnum.Int64 get finishedTsMs => $_getI64(17);
  @$pb.TagNumber(18)
  set finishedTsMs($fixnum.Int64 value) => $_setInt64(17, value);
  @$pb.TagNumber(18)
  $core.bool hasFinishedTsMs() => $_has(17);
  @$pb.TagNumber(18)
  void clearFinishedTsMs() => $_clearField(18);

  @$pb.TagNumber(20)
  $fixnum.Int64 get createdTsMs => $_getI64(18);
  @$pb.TagNumber(20)
  set createdTsMs($fixnum.Int64 value) => $_setInt64(18, value);
  @$pb.TagNumber(20)
  $core.bool hasCreatedTsMs() => $_has(18);
  @$pb.TagNumber(20)
  void clearCreatedTsMs() => $_clearField(20);

  @$pb.TagNumber(21)
  $fixnum.Int64 get updatedTsMs => $_getI64(19);
  @$pb.TagNumber(21)
  set updatedTsMs($fixnum.Int64 value) => $_setInt64(19, value);
  @$pb.TagNumber(21)
  $core.bool hasUpdatedTsMs() => $_has(19);
  @$pb.TagNumber(21)
  void clearUpdatedTsMs() => $_clearField(21);

  @$pb.TagNumber(22)
  $fixnum.Int64 get deletedTsMs => $_getI64(20);
  @$pb.TagNumber(22)
  set deletedTsMs($fixnum.Int64 value) => $_setInt64(20, value);
  @$pb.TagNumber(22)
  $core.bool hasDeletedTsMs() => $_has(20);
  @$pb.TagNumber(22)
  void clearDeletedTsMs() => $_clearField(22);
}

class ReqTaskList extends $pb.GeneratedMessage {
  factory ReqTaskList({
    $fixnum.Int64? deviceIid,
    $core.bool? includeInactive,
  }) {
    final result = ReqTaskList._();
    if (deviceIid != null) result.deviceIid = deviceIid;
    if (includeInactive != null) result.includeInactive = includeInactive;
    return result;
  }

  ReqTaskList._();

  factory ReqTaskList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqTaskList()..mergeFromBuffer(data, registry);
  factory ReqTaskList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqTaskList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqTaskList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqTaskList.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'deviceIid')
    ..aOB(2, _omitFieldNames ? '' : 'includeInactive')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqTaskList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqTaskList copyWith(void Function(ReqTaskList) updates) =>
      super.copyWith((message) => updates(message as ReqTaskList))
          as ReqTaskList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqTaskList() / ReqTaskList.new instead')
  static ReqTaskList create() => ReqTaskList._();
  static $pb.GeneratedMessage $_createMessage() => ReqTaskList._();
  @$core.override
  ReqTaskList createEmptyInstance() => ReqTaskList._();
  @$core.pragma('dart2js:noInline')
  static ReqTaskList getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqTaskList>(
          ReqTaskList.$_createMessage);
  static ReqTaskList? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get deviceIid => $_getI64(0);
  @$pb.TagNumber(1)
  set deviceIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDeviceIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearDeviceIid() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get includeInactive => $_getBF(1);
  @$pb.TagNumber(2)
  set includeInactive($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasIncludeInactive() => $_has(1);
  @$pb.TagNumber(2)
  void clearIncludeInactive() => $_clearField(2);
}

class ResTaskList extends $pb.GeneratedMessage {
  factory ResTaskList({
    $core.Iterable<Task>? tasks,
  }) {
    final result = ResTaskList._();
    if (tasks != null) result.tasks.addAll(tasks);
    return result;
  }

  ResTaskList._();

  factory ResTaskList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResTaskList()..mergeFromBuffer(data, registry);
  factory ResTaskList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResTaskList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResTaskList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResTaskList.$_createMessage)
    ..pPM<Task>(1, _omitFieldNames ? '' : 'tasks',
        subBuilder: Task.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResTaskList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResTaskList copyWith(void Function(ResTaskList) updates) =>
      super.copyWith((message) => updates(message as ResTaskList))
          as ResTaskList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResTaskList() / ResTaskList.new instead')
  static ResTaskList create() => ResTaskList._();
  static $pb.GeneratedMessage $_createMessage() => ResTaskList._();
  @$core.override
  ResTaskList createEmptyInstance() => ResTaskList._();
  @$core.pragma('dart2js:noInline')
  static ResTaskList getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResTaskList>(
          ResTaskList.$_createMessage);
  static ResTaskList? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Task> get tasks => $_getList(0);
}

class ReqTaskPut extends $pb.GeneratedMessage {
  factory ReqTaskPut({
    Task? task,
  }) {
    final result = ReqTaskPut._();
    if (task != null) result.task = task;
    return result;
  }

  ReqTaskPut._();

  factory ReqTaskPut.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqTaskPut()..mergeFromBuffer(data, registry);
  factory ReqTaskPut.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqTaskPut()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqTaskPut',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqTaskPut.$_createMessage)
    ..aOM<Task>(1, _omitFieldNames ? '' : 'task',
        subBuilder: Task.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqTaskPut clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqTaskPut copyWith(void Function(ReqTaskPut) updates) =>
      super.copyWith((message) => updates(message as ReqTaskPut)) as ReqTaskPut;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqTaskPut() / ReqTaskPut.new instead')
  static ReqTaskPut create() => ReqTaskPut._();
  static $pb.GeneratedMessage $_createMessage() => ReqTaskPut._();
  @$core.override
  ReqTaskPut createEmptyInstance() => ReqTaskPut._();
  @$core.pragma('dart2js:noInline')
  static ReqTaskPut getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqTaskPut>(ReqTaskPut.$_createMessage);
  static ReqTaskPut? _defaultInstance;

  @$pb.TagNumber(1)
  Task get task => $_getN(0);
  @$pb.TagNumber(1)
  set task(Task value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasTask() => $_has(0);
  @$pb.TagNumber(1)
  void clearTask() => $_clearField(1);
  @$pb.TagNumber(1)
  Task ensureTask() => $_ensure(0);
}

class ResTaskPut extends $pb.GeneratedMessage {
  factory ResTaskPut({
    Task? task,
  }) {
    final result = ResTaskPut._();
    if (task != null) result.task = task;
    return result;
  }

  ResTaskPut._();

  factory ResTaskPut.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResTaskPut()..mergeFromBuffer(data, registry);
  factory ResTaskPut.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResTaskPut()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResTaskPut',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResTaskPut.$_createMessage)
    ..aOM<Task>(1, _omitFieldNames ? '' : 'task',
        subBuilder: Task.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResTaskPut clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResTaskPut copyWith(void Function(ResTaskPut) updates) =>
      super.copyWith((message) => updates(message as ResTaskPut)) as ResTaskPut;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResTaskPut() / ResTaskPut.new instead')
  static ResTaskPut create() => ResTaskPut._();
  static $pb.GeneratedMessage $_createMessage() => ResTaskPut._();
  @$core.override
  ResTaskPut createEmptyInstance() => ResTaskPut._();
  @$core.pragma('dart2js:noInline')
  static ResTaskPut getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResTaskPut>(ResTaskPut.$_createMessage);
  static ResTaskPut? _defaultInstance;

  @$pb.TagNumber(1)
  Task get task => $_getN(0);
  @$pb.TagNumber(1)
  set task(Task value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasTask() => $_has(0);
  @$pb.TagNumber(1)
  void clearTask() => $_clearField(1);
  @$pb.TagNumber(1)
  Task ensureTask() => $_ensure(0);
}

class ReqTaskRunStart extends $pb.GeneratedMessage {
  factory ReqTaskRunStart({
    $fixnum.Int64? deviceIid,
    $fixnum.Int64? taskId,
    $core.String? prompt,
    $fixnum.Int64? skillId,
    $core.String? model,
    $fixnum.Int64? chatId,
    $core.String? reqId,
  }) {
    final result = ReqTaskRunStart._();
    if (deviceIid != null) result.deviceIid = deviceIid;
    if (taskId != null) result.taskId = taskId;
    if (prompt != null) result.prompt = prompt;
    if (skillId != null) result.skillId = skillId;
    if (model != null) result.model = model;
    if (chatId != null) result.chatId = chatId;
    if (reqId != null) result.reqId = reqId;
    return result;
  }

  ReqTaskRunStart._();

  factory ReqTaskRunStart.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqTaskRunStart()..mergeFromBuffer(data, registry);
  factory ReqTaskRunStart.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqTaskRunStart()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqTaskRunStart',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqTaskRunStart.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'deviceIid')
    ..aInt64(2, _omitFieldNames ? '' : 'taskId')
    ..aOS(3, _omitFieldNames ? '' : 'prompt')
    ..aInt64(4, _omitFieldNames ? '' : 'skillId')
    ..aOS(5, _omitFieldNames ? '' : 'model')
    ..aInt64(6, _omitFieldNames ? '' : 'chatId')
    ..aOS(7, _omitFieldNames ? '' : 'reqId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqTaskRunStart clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqTaskRunStart copyWith(void Function(ReqTaskRunStart) updates) =>
      super.copyWith((message) => updates(message as ReqTaskRunStart))
          as ReqTaskRunStart;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqTaskRunStart() / ReqTaskRunStart.new instead')
  static ReqTaskRunStart create() => ReqTaskRunStart._();
  static $pb.GeneratedMessage $_createMessage() => ReqTaskRunStart._();
  @$core.override
  ReqTaskRunStart createEmptyInstance() => ReqTaskRunStart._();
  @$core.pragma('dart2js:noInline')
  static ReqTaskRunStart getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqTaskRunStart>(
          ReqTaskRunStart.$_createMessage);
  static ReqTaskRunStart? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get deviceIid => $_getI64(0);
  @$pb.TagNumber(1)
  set deviceIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDeviceIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearDeviceIid() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get taskId => $_getI64(1);
  @$pb.TagNumber(2)
  set taskId($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTaskId() => $_has(1);
  @$pb.TagNumber(2)
  void clearTaskId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get prompt => $_getSZ(2);
  @$pb.TagNumber(3)
  set prompt($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPrompt() => $_has(2);
  @$pb.TagNumber(3)
  void clearPrompt() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get skillId => $_getI64(3);
  @$pb.TagNumber(4)
  set skillId($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSkillId() => $_has(3);
  @$pb.TagNumber(4)
  void clearSkillId() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get model => $_getSZ(4);
  @$pb.TagNumber(5)
  set model($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasModel() => $_has(4);
  @$pb.TagNumber(5)
  void clearModel() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get chatId => $_getI64(5);
  @$pb.TagNumber(6)
  set chatId($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasChatId() => $_has(5);
  @$pb.TagNumber(6)
  void clearChatId() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get reqId => $_getSZ(6);
  @$pb.TagNumber(7)
  set reqId($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasReqId() => $_has(6);
  @$pb.TagNumber(7)
  void clearReqId() => $_clearField(7);
}

class ResTaskRunStart extends $pb.GeneratedMessage {
  factory ResTaskRunStart({
    TaskRun? run,
  }) {
    final result = ResTaskRunStart._();
    if (run != null) result.run = run;
    return result;
  }

  ResTaskRunStart._();

  factory ResTaskRunStart.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResTaskRunStart()..mergeFromBuffer(data, registry);
  factory ResTaskRunStart.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResTaskRunStart()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResTaskRunStart',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResTaskRunStart.$_createMessage)
    ..aOM<TaskRun>(1, _omitFieldNames ? '' : 'run',
        subBuilder: TaskRun.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResTaskRunStart clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResTaskRunStart copyWith(void Function(ResTaskRunStart) updates) =>
      super.copyWith((message) => updates(message as ResTaskRunStart))
          as ResTaskRunStart;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResTaskRunStart() / ResTaskRunStart.new instead')
  static ResTaskRunStart create() => ResTaskRunStart._();
  static $pb.GeneratedMessage $_createMessage() => ResTaskRunStart._();
  @$core.override
  ResTaskRunStart createEmptyInstance() => ResTaskRunStart._();
  @$core.pragma('dart2js:noInline')
  static ResTaskRunStart getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResTaskRunStart>(
          ResTaskRunStart.$_createMessage);
  static ResTaskRunStart? _defaultInstance;

  @$pb.TagNumber(1)
  TaskRun get run => $_getN(0);
  @$pb.TagNumber(1)
  set run(TaskRun value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasRun() => $_has(0);
  @$pb.TagNumber(1)
  void clearRun() => $_clearField(1);
  @$pb.TagNumber(1)
  TaskRun ensureRun() => $_ensure(0);
}

class ReqTaskRunCancel extends $pb.GeneratedMessage {
  factory ReqTaskRunCancel({
    $fixnum.Int64? runId,
  }) {
    final result = ReqTaskRunCancel._();
    if (runId != null) result.runId = runId;
    return result;
  }

  ReqTaskRunCancel._();

  factory ReqTaskRunCancel.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqTaskRunCancel()..mergeFromBuffer(data, registry);
  factory ReqTaskRunCancel.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqTaskRunCancel()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqTaskRunCancel',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqTaskRunCancel.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'runId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqTaskRunCancel clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqTaskRunCancel copyWith(void Function(ReqTaskRunCancel) updates) =>
      super.copyWith((message) => updates(message as ReqTaskRunCancel))
          as ReqTaskRunCancel;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqTaskRunCancel() / ReqTaskRunCancel.new instead')
  static ReqTaskRunCancel create() => ReqTaskRunCancel._();
  static $pb.GeneratedMessage $_createMessage() => ReqTaskRunCancel._();
  @$core.override
  ReqTaskRunCancel createEmptyInstance() => ReqTaskRunCancel._();
  @$core.pragma('dart2js:noInline')
  static ReqTaskRunCancel getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqTaskRunCancel>(
          ReqTaskRunCancel.$_createMessage);
  static ReqTaskRunCancel? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get runId => $_getI64(0);
  @$pb.TagNumber(1)
  set runId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRunId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRunId() => $_clearField(1);
}

class ResTaskRunCancel extends $pb.GeneratedMessage {
  factory ResTaskRunCancel({
    TaskRun? run,
  }) {
    final result = ResTaskRunCancel._();
    if (run != null) result.run = run;
    return result;
  }

  ResTaskRunCancel._();

  factory ResTaskRunCancel.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResTaskRunCancel()..mergeFromBuffer(data, registry);
  factory ResTaskRunCancel.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResTaskRunCancel()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResTaskRunCancel',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResTaskRunCancel.$_createMessage)
    ..aOM<TaskRun>(1, _omitFieldNames ? '' : 'run',
        subBuilder: TaskRun.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResTaskRunCancel clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResTaskRunCancel copyWith(void Function(ResTaskRunCancel) updates) =>
      super.copyWith((message) => updates(message as ResTaskRunCancel))
          as ResTaskRunCancel;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResTaskRunCancel() / ResTaskRunCancel.new instead')
  static ResTaskRunCancel create() => ResTaskRunCancel._();
  static $pb.GeneratedMessage $_createMessage() => ResTaskRunCancel._();
  @$core.override
  ResTaskRunCancel createEmptyInstance() => ResTaskRunCancel._();
  @$core.pragma('dart2js:noInline')
  static ResTaskRunCancel getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResTaskRunCancel>(
          ResTaskRunCancel.$_createMessage);
  static ResTaskRunCancel? _defaultInstance;

  @$pb.TagNumber(1)
  TaskRun get run => $_getN(0);
  @$pb.TagNumber(1)
  set run(TaskRun value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasRun() => $_has(0);
  @$pb.TagNumber(1)
  void clearRun() => $_clearField(1);
  @$pb.TagNumber(1)
  TaskRun ensureRun() => $_ensure(0);
}

class ReqTaskRunList extends $pb.GeneratedMessage {
  factory ReqTaskRunList({
    $fixnum.Int64? deviceIid,
    $fixnum.Int64? sinceMs,
    $core.int? limit,
  }) {
    final result = ReqTaskRunList._();
    if (deviceIid != null) result.deviceIid = deviceIid;
    if (sinceMs != null) result.sinceMs = sinceMs;
    if (limit != null) result.limit = limit;
    return result;
  }

  ReqTaskRunList._();

  factory ReqTaskRunList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqTaskRunList()..mergeFromBuffer(data, registry);
  factory ReqTaskRunList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqTaskRunList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqTaskRunList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqTaskRunList.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'deviceIid')
    ..aInt64(2, _omitFieldNames ? '' : 'sinceMs')
    ..aI(3, _omitFieldNames ? '' : 'limit')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqTaskRunList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqTaskRunList copyWith(void Function(ReqTaskRunList) updates) =>
      super.copyWith((message) => updates(message as ReqTaskRunList))
          as ReqTaskRunList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqTaskRunList() / ReqTaskRunList.new instead')
  static ReqTaskRunList create() => ReqTaskRunList._();
  static $pb.GeneratedMessage $_createMessage() => ReqTaskRunList._();
  @$core.override
  ReqTaskRunList createEmptyInstance() => ReqTaskRunList._();
  @$core.pragma('dart2js:noInline')
  static ReqTaskRunList getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqTaskRunList>(
          ReqTaskRunList.$_createMessage);
  static ReqTaskRunList? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get deviceIid => $_getI64(0);
  @$pb.TagNumber(1)
  set deviceIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDeviceIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearDeviceIid() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get sinceMs => $_getI64(1);
  @$pb.TagNumber(2)
  set sinceMs($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSinceMs() => $_has(1);
  @$pb.TagNumber(2)
  void clearSinceMs() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get limit => $_getIZ(2);
  @$pb.TagNumber(3)
  set limit($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLimit() => $_has(2);
  @$pb.TagNumber(3)
  void clearLimit() => $_clearField(3);
}

class ResTaskRunList extends $pb.GeneratedMessage {
  factory ResTaskRunList({
    $core.Iterable<TaskRun>? runs,
  }) {
    final result = ResTaskRunList._();
    if (runs != null) result.runs.addAll(runs);
    return result;
  }

  ResTaskRunList._();

  factory ResTaskRunList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResTaskRunList()..mergeFromBuffer(data, registry);
  factory ResTaskRunList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResTaskRunList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResTaskRunList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResTaskRunList.$_createMessage)
    ..pPM<TaskRun>(1, _omitFieldNames ? '' : 'runs',
        subBuilder: TaskRun.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResTaskRunList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResTaskRunList copyWith(void Function(ResTaskRunList) updates) =>
      super.copyWith((message) => updates(message as ResTaskRunList))
          as ResTaskRunList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResTaskRunList() / ResTaskRunList.new instead')
  static ResTaskRunList create() => ResTaskRunList._();
  static $pb.GeneratedMessage $_createMessage() => ResTaskRunList._();
  @$core.override
  ResTaskRunList createEmptyInstance() => ResTaskRunList._();
  @$core.pragma('dart2js:noInline')
  static ResTaskRunList getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResTaskRunList>(
          ResTaskRunList.$_createMessage);
  static ResTaskRunList? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<TaskRun> get runs => $_getList(0);
}

/// Unsolicited WS push (NATS c35.user.{owner_iid}.task_run → fanout)
class TaskRunPush extends $pb.GeneratedMessage {
  factory TaskRunPush({
    TaskRun? run,
  }) {
    final result = TaskRunPush._();
    if (run != null) result.run = run;
    return result;
  }

  TaskRunPush._();

  factory TaskRunPush.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TaskRunPush()..mergeFromBuffer(data, registry);
  factory TaskRunPush.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TaskRunPush()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TaskRunPush',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: TaskRunPush.$_createMessage)
    ..aOM<TaskRun>(1, _omitFieldNames ? '' : 'run',
        subBuilder: TaskRun.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TaskRunPush clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TaskRunPush copyWith(void Function(TaskRunPush) updates) =>
      super.copyWith((message) => updates(message as TaskRunPush))
          as TaskRunPush;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use TaskRunPush() / TaskRunPush.new instead')
  static TaskRunPush create() => TaskRunPush._();
  static $pb.GeneratedMessage $_createMessage() => TaskRunPush._();
  @$core.override
  TaskRunPush createEmptyInstance() => TaskRunPush._();
  @$core.pragma('dart2js:noInline')
  static TaskRunPush getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TaskRunPush>(
          TaskRunPush.$_createMessage);
  static TaskRunPush? _defaultInstance;

  @$pb.TagNumber(1)
  TaskRun get run => $_getN(0);
  @$pb.TagNumber(1)
  set run(TaskRun value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasRun() => $_has(0);
  @$pb.TagNumber(1)
  void clearRun() => $_clearField(1);
  @$pb.TagNumber(1)
  TaskRun ensureRun() => $_ensure(0);
}

/// JetStream: c35.act.device.{device_iid}.task.run
class ActDeviceTaskRun extends $pb.GeneratedMessage {
  factory ActDeviceTaskRun({
    $fixnum.Int64? runId,
    $fixnum.Int64? deviceIid,
    $fixnum.Int64? ownerIid,
    $fixnum.Int64? taskId,
    $core.String? reqId,
    $core.String? prompt,
    $fixnum.Int64? skillId,
    $core.String? model,
    $core.int? stepIndex,
    $fixnum.Int64? chatId,
  }) {
    final result = ActDeviceTaskRun._();
    if (runId != null) result.runId = runId;
    if (deviceIid != null) result.deviceIid = deviceIid;
    if (ownerIid != null) result.ownerIid = ownerIid;
    if (taskId != null) result.taskId = taskId;
    if (reqId != null) result.reqId = reqId;
    if (prompt != null) result.prompt = prompt;
    if (skillId != null) result.skillId = skillId;
    if (model != null) result.model = model;
    if (stepIndex != null) result.stepIndex = stepIndex;
    if (chatId != null) result.chatId = chatId;
    return result;
  }

  ActDeviceTaskRun._();

  factory ActDeviceTaskRun.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ActDeviceTaskRun()..mergeFromBuffer(data, registry);
  factory ActDeviceTaskRun.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ActDeviceTaskRun()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ActDeviceTaskRun',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ActDeviceTaskRun.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'runId')
    ..aInt64(2, _omitFieldNames ? '' : 'deviceIid')
    ..aInt64(3, _omitFieldNames ? '' : 'ownerIid')
    ..aInt64(4, _omitFieldNames ? '' : 'taskId')
    ..aOS(5, _omitFieldNames ? '' : 'reqId')
    ..aOS(6, _omitFieldNames ? '' : 'prompt')
    ..aInt64(7, _omitFieldNames ? '' : 'skillId')
    ..aOS(8, _omitFieldNames ? '' : 'model')
    ..aI(9, _omitFieldNames ? '' : 'stepIndex')
    ..aInt64(10, _omitFieldNames ? '' : 'chatId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ActDeviceTaskRun clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ActDeviceTaskRun copyWith(void Function(ActDeviceTaskRun) updates) =>
      super.copyWith((message) => updates(message as ActDeviceTaskRun))
          as ActDeviceTaskRun;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ActDeviceTaskRun() / ActDeviceTaskRun.new instead')
  static ActDeviceTaskRun create() => ActDeviceTaskRun._();
  static $pb.GeneratedMessage $_createMessage() => ActDeviceTaskRun._();
  @$core.override
  ActDeviceTaskRun createEmptyInstance() => ActDeviceTaskRun._();
  @$core.pragma('dart2js:noInline')
  static ActDeviceTaskRun getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ActDeviceTaskRun>(
          ActDeviceTaskRun.$_createMessage);
  static ActDeviceTaskRun? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get runId => $_getI64(0);
  @$pb.TagNumber(1)
  set runId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRunId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRunId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get deviceIid => $_getI64(1);
  @$pb.TagNumber(2)
  set deviceIid($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDeviceIid() => $_has(1);
  @$pb.TagNumber(2)
  void clearDeviceIid() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get ownerIid => $_getI64(2);
  @$pb.TagNumber(3)
  set ownerIid($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasOwnerIid() => $_has(2);
  @$pb.TagNumber(3)
  void clearOwnerIid() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get taskId => $_getI64(3);
  @$pb.TagNumber(4)
  set taskId($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTaskId() => $_has(3);
  @$pb.TagNumber(4)
  void clearTaskId() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get reqId => $_getSZ(4);
  @$pb.TagNumber(5)
  set reqId($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasReqId() => $_has(4);
  @$pb.TagNumber(5)
  void clearReqId() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get prompt => $_getSZ(5);
  @$pb.TagNumber(6)
  set prompt($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasPrompt() => $_has(5);
  @$pb.TagNumber(6)
  void clearPrompt() => $_clearField(6);

  @$pb.TagNumber(7)
  $fixnum.Int64 get skillId => $_getI64(6);
  @$pb.TagNumber(7)
  set skillId($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(7)
  $core.bool hasSkillId() => $_has(6);
  @$pb.TagNumber(7)
  void clearSkillId() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get model => $_getSZ(7);
  @$pb.TagNumber(8)
  set model($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasModel() => $_has(7);
  @$pb.TagNumber(8)
  void clearModel() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.int get stepIndex => $_getIZ(8);
  @$pb.TagNumber(9)
  set stepIndex($core.int value) => $_setSignedInt32(8, value);
  @$pb.TagNumber(9)
  $core.bool hasStepIndex() => $_has(8);
  @$pb.TagNumber(9)
  void clearStepIndex() => $_clearField(9);

  @$pb.TagNumber(10)
  $fixnum.Int64 get chatId => $_getI64(9);
  @$pb.TagNumber(10)
  set chatId($fixnum.Int64 value) => $_setInt64(9, value);
  @$pb.TagNumber(10)
  $core.bool hasChatId() => $_has(9);
  @$pb.TagNumber(10)
  void clearChatId() => $_clearField(10);
}

/// Agent → server progress
class EvDeviceTaskProgress extends $pb.GeneratedMessage {
  factory EvDeviceTaskProgress({
    $fixnum.Int64? runId,
    $fixnum.Int64? deviceIid,
    $core.int? stepIndex,
    $core.String? topic,
    $core.String? text,
    $core.String? metaJson,
  }) {
    final result = EvDeviceTaskProgress._();
    if (runId != null) result.runId = runId;
    if (deviceIid != null) result.deviceIid = deviceIid;
    if (stepIndex != null) result.stepIndex = stepIndex;
    if (topic != null) result.topic = topic;
    if (text != null) result.text = text;
    if (metaJson != null) result.metaJson = metaJson;
    return result;
  }

  EvDeviceTaskProgress._();

  factory EvDeviceTaskProgress.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EvDeviceTaskProgress()..mergeFromBuffer(data, registry);
  factory EvDeviceTaskProgress.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EvDeviceTaskProgress()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EvDeviceTaskProgress',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: EvDeviceTaskProgress.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'runId')
    ..aInt64(2, _omitFieldNames ? '' : 'deviceIid')
    ..aI(3, _omitFieldNames ? '' : 'stepIndex')
    ..aOS(4, _omitFieldNames ? '' : 'topic')
    ..aOS(5, _omitFieldNames ? '' : 'text')
    ..aOS(6, _omitFieldNames ? '' : 'metaJson')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EvDeviceTaskProgress clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EvDeviceTaskProgress copyWith(void Function(EvDeviceTaskProgress) updates) =>
      super.copyWith((message) => updates(message as EvDeviceTaskProgress))
          as EvDeviceTaskProgress;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use EvDeviceTaskProgress() / EvDeviceTaskProgress.new instead')
  static EvDeviceTaskProgress create() => EvDeviceTaskProgress._();
  static $pb.GeneratedMessage $_createMessage() => EvDeviceTaskProgress._();
  @$core.override
  EvDeviceTaskProgress createEmptyInstance() => EvDeviceTaskProgress._();
  @$core.pragma('dart2js:noInline')
  static EvDeviceTaskProgress getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EvDeviceTaskProgress>(
          EvDeviceTaskProgress.$_createMessage);
  static EvDeviceTaskProgress? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get runId => $_getI64(0);
  @$pb.TagNumber(1)
  set runId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRunId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRunId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get deviceIid => $_getI64(1);
  @$pb.TagNumber(2)
  set deviceIid($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDeviceIid() => $_has(1);
  @$pb.TagNumber(2)
  void clearDeviceIid() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get stepIndex => $_getIZ(2);
  @$pb.TagNumber(3)
  set stepIndex($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasStepIndex() => $_has(2);
  @$pb.TagNumber(3)
  void clearStepIndex() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get topic => $_getSZ(3);
  @$pb.TagNumber(4)
  set topic($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTopic() => $_has(3);
  @$pb.TagNumber(4)
  void clearTopic() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get text => $_getSZ(4);
  @$pb.TagNumber(5)
  set text($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasText() => $_has(4);
  @$pb.TagNumber(5)
  void clearText() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get metaJson => $_getSZ(5);
  @$pb.TagNumber(6)
  set metaJson($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasMetaJson() => $_has(5);
  @$pb.TagNumber(6)
  void clearMetaJson() => $_clearField(6);
}

/// Agent → server terminal
class EvDeviceTaskDone extends $pb.GeneratedMessage {
  factory EvDeviceTaskDone({
    $fixnum.Int64? runId,
    $fixnum.Int64? deviceIid,
    TaskRunStatus? status,
    $core.String? summary,
    $core.String? error,
    $core.int? stepIndex,
  }) {
    final result = EvDeviceTaskDone._();
    if (runId != null) result.runId = runId;
    if (deviceIid != null) result.deviceIid = deviceIid;
    if (status != null) result.status = status;
    if (summary != null) result.summary = summary;
    if (error != null) result.error = error;
    if (stepIndex != null) result.stepIndex = stepIndex;
    return result;
  }

  EvDeviceTaskDone._();

  factory EvDeviceTaskDone.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EvDeviceTaskDone()..mergeFromBuffer(data, registry);
  factory EvDeviceTaskDone.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EvDeviceTaskDone()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EvDeviceTaskDone',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: EvDeviceTaskDone.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'runId')
    ..aInt64(2, _omitFieldNames ? '' : 'deviceIid')
    ..aE<TaskRunStatus>(3, _omitFieldNames ? '' : 'status',
        enumValues: TaskRunStatus.values)
    ..aOS(4, _omitFieldNames ? '' : 'summary')
    ..aOS(5, _omitFieldNames ? '' : 'error')
    ..aI(6, _omitFieldNames ? '' : 'stepIndex')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EvDeviceTaskDone clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EvDeviceTaskDone copyWith(void Function(EvDeviceTaskDone) updates) =>
      super.copyWith((message) => updates(message as EvDeviceTaskDone))
          as EvDeviceTaskDone;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use EvDeviceTaskDone() / EvDeviceTaskDone.new instead')
  static EvDeviceTaskDone create() => EvDeviceTaskDone._();
  static $pb.GeneratedMessage $_createMessage() => EvDeviceTaskDone._();
  @$core.override
  EvDeviceTaskDone createEmptyInstance() => EvDeviceTaskDone._();
  @$core.pragma('dart2js:noInline')
  static EvDeviceTaskDone getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<EvDeviceTaskDone>(
          EvDeviceTaskDone.$_createMessage);
  static EvDeviceTaskDone? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get runId => $_getI64(0);
  @$pb.TagNumber(1)
  set runId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRunId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRunId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get deviceIid => $_getI64(1);
  @$pb.TagNumber(2)
  set deviceIid($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDeviceIid() => $_has(1);
  @$pb.TagNumber(2)
  void clearDeviceIid() => $_clearField(2);

  @$pb.TagNumber(3)
  TaskRunStatus get status => $_getN(2);
  @$pb.TagNumber(3)
  set status(TaskRunStatus value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasStatus() => $_has(2);
  @$pb.TagNumber(3)
  void clearStatus() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get summary => $_getSZ(3);
  @$pb.TagNumber(4)
  set summary($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSummary() => $_has(3);
  @$pb.TagNumber(4)
  void clearSummary() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get error => $_getSZ(4);
  @$pb.TagNumber(5)
  set error($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasError() => $_has(4);
  @$pb.TagNumber(5)
  void clearError() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get stepIndex => $_getIZ(5);
  @$pb.TagNumber(6)
  set stepIndex($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasStepIndex() => $_has(5);
  @$pb.TagNumber(6)
  void clearStepIndex() => $_clearField(6);
}

/// Agent connect / disconnect
class EvDevicePresence extends $pb.GeneratedMessage {
  factory EvDevicePresence({
    $fixnum.Int64? deviceIid,
    $fixnum.Int64? ownerIid,
    $core.bool? online,
    $core.String? agentVersion,
    $core.String? pod,
  }) {
    final result = EvDevicePresence._();
    if (deviceIid != null) result.deviceIid = deviceIid;
    if (ownerIid != null) result.ownerIid = ownerIid;
    if (online != null) result.online = online;
    if (agentVersion != null) result.agentVersion = agentVersion;
    if (pod != null) result.pod = pod;
    return result;
  }

  EvDevicePresence._();

  factory EvDevicePresence.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EvDevicePresence()..mergeFromBuffer(data, registry);
  factory EvDevicePresence.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EvDevicePresence()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EvDevicePresence',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: EvDevicePresence.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'deviceIid')
    ..aInt64(2, _omitFieldNames ? '' : 'ownerIid')
    ..aOB(3, _omitFieldNames ? '' : 'online')
    ..aOS(4, _omitFieldNames ? '' : 'agentVersion')
    ..aOS(5, _omitFieldNames ? '' : 'pod')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EvDevicePresence clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EvDevicePresence copyWith(void Function(EvDevicePresence) updates) =>
      super.copyWith((message) => updates(message as EvDevicePresence))
          as EvDevicePresence;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use EvDevicePresence() / EvDevicePresence.new instead')
  static EvDevicePresence create() => EvDevicePresence._();
  static $pb.GeneratedMessage $_createMessage() => EvDevicePresence._();
  @$core.override
  EvDevicePresence createEmptyInstance() => EvDevicePresence._();
  @$core.pragma('dart2js:noInline')
  static EvDevicePresence getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<EvDevicePresence>(
          EvDevicePresence.$_createMessage);
  static EvDevicePresence? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get deviceIid => $_getI64(0);
  @$pb.TagNumber(1)
  set deviceIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDeviceIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearDeviceIid() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get ownerIid => $_getI64(1);
  @$pb.TagNumber(2)
  set ownerIid($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOwnerIid() => $_has(1);
  @$pb.TagNumber(2)
  void clearOwnerIid() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get online => $_getBF(2);
  @$pb.TagNumber(3)
  set online($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasOnline() => $_has(2);
  @$pb.TagNumber(3)
  void clearOnline() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get agentVersion => $_getSZ(3);
  @$pb.TagNumber(4)
  set agentVersion($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAgentVersion() => $_has(3);
  @$pb.TagNumber(4)
  void clearAgentVersion() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get pod => $_getSZ(4);
  @$pb.TagNumber(5)
  set pod($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasPod() => $_has(4);
  @$pb.TagNumber(5)
  void clearPod() => $_clearField(5);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
