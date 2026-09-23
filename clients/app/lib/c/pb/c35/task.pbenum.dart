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

import 'package:protobuf/protobuf.dart' as $pb;

class TaskTriggerKind extends $pb.ProtobufEnum {
  static const TaskTriggerKind TASK_TRIGGER_KIND_UNSPECIFIED =
      TaskTriggerKind._(
          0, _omitEnumNames ? '' : 'TASK_TRIGGER_KIND_UNSPECIFIED');
  static const TaskTriggerKind TASK_TRIGGER_KIND_ONCE =
      TaskTriggerKind._(1, _omitEnumNames ? '' : 'TASK_TRIGGER_KIND_ONCE');
  static const TaskTriggerKind TASK_TRIGGER_KIND_CRON =
      TaskTriggerKind._(2, _omitEnumNames ? '' : 'TASK_TRIGGER_KIND_CRON');
  static const TaskTriggerKind TASK_TRIGGER_KIND_WEBHOOK =
      TaskTriggerKind._(3, _omitEnumNames ? '' : 'TASK_TRIGGER_KIND_WEBHOOK');

  static const $core.List<TaskTriggerKind> values = <TaskTriggerKind>[
    TASK_TRIGGER_KIND_UNSPECIFIED,
    TASK_TRIGGER_KIND_ONCE,
    TASK_TRIGGER_KIND_CRON,
    TASK_TRIGGER_KIND_WEBHOOK,
  ];

  static final $core.List<TaskTriggerKind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static TaskTriggerKind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const TaskTriggerKind._(super.value, super.name);
}

class TaskRunStatus extends $pb.ProtobufEnum {
  static const TaskRunStatus TASK_RUN_STATUS_UNSPECIFIED =
      TaskRunStatus._(0, _omitEnumNames ? '' : 'TASK_RUN_STATUS_UNSPECIFIED');
  static const TaskRunStatus TASK_RUN_STATUS_QUEUED =
      TaskRunStatus._(1, _omitEnumNames ? '' : 'TASK_RUN_STATUS_QUEUED');
  static const TaskRunStatus TASK_RUN_STATUS_LEASED =
      TaskRunStatus._(2, _omitEnumNames ? '' : 'TASK_RUN_STATUS_LEASED');
  static const TaskRunStatus TASK_RUN_STATUS_RUNNING =
      TaskRunStatus._(3, _omitEnumNames ? '' : 'TASK_RUN_STATUS_RUNNING');
  static const TaskRunStatus TASK_RUN_STATUS_DONE =
      TaskRunStatus._(4, _omitEnumNames ? '' : 'TASK_RUN_STATUS_DONE');
  static const TaskRunStatus TASK_RUN_STATUS_FAILED =
      TaskRunStatus._(5, _omitEnumNames ? '' : 'TASK_RUN_STATUS_FAILED');
  static const TaskRunStatus TASK_RUN_STATUS_CANCELLED =
      TaskRunStatus._(6, _omitEnumNames ? '' : 'TASK_RUN_STATUS_CANCELLED');

  static const $core.List<TaskRunStatus> values = <TaskRunStatus>[
    TASK_RUN_STATUS_UNSPECIFIED,
    TASK_RUN_STATUS_QUEUED,
    TASK_RUN_STATUS_LEASED,
    TASK_RUN_STATUS_RUNNING,
    TASK_RUN_STATUS_DONE,
    TASK_RUN_STATUS_FAILED,
    TASK_RUN_STATUS_CANCELLED,
  ];

  static final $core.List<TaskRunStatus?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 6);
  static TaskRunStatus? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const TaskRunStatus._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
