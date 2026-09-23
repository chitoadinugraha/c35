// This is a generated file - do not edit.
//
// Generated from c35/task.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use taskTriggerKindDescriptor instead')
const TaskTriggerKind$json = {
  '1': 'TaskTriggerKind',
  '2': [
    {'1': 'TASK_TRIGGER_KIND_UNSPECIFIED', '2': 0},
    {'1': 'TASK_TRIGGER_KIND_ONCE', '2': 1},
    {'1': 'TASK_TRIGGER_KIND_CRON', '2': 2},
    {'1': 'TASK_TRIGGER_KIND_WEBHOOK', '2': 3},
  ],
};

/// Descriptor for `TaskTriggerKind`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List taskTriggerKindDescriptor = $convert.base64Decode(
    'Cg9UYXNrVHJpZ2dlcktpbmQSIQodVEFTS19UUklHR0VSX0tJTkRfVU5TUEVDSUZJRUQQABIaCh'
    'ZUQVNLX1RSSUdHRVJfS0lORF9PTkNFEAESGgoWVEFTS19UUklHR0VSX0tJTkRfQ1JPThACEh0K'
    'GVRBU0tfVFJJR0dFUl9LSU5EX1dFQkhPT0sQAw==');

@$core.Deprecated('Use taskRunStatusDescriptor instead')
const TaskRunStatus$json = {
  '1': 'TaskRunStatus',
  '2': [
    {'1': 'TASK_RUN_STATUS_UNSPECIFIED', '2': 0},
    {'1': 'TASK_RUN_STATUS_QUEUED', '2': 1},
    {'1': 'TASK_RUN_STATUS_LEASED', '2': 2},
    {'1': 'TASK_RUN_STATUS_RUNNING', '2': 3},
    {'1': 'TASK_RUN_STATUS_DONE', '2': 4},
    {'1': 'TASK_RUN_STATUS_FAILED', '2': 5},
    {'1': 'TASK_RUN_STATUS_CANCELLED', '2': 6},
  ],
};

/// Descriptor for `TaskRunStatus`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List taskRunStatusDescriptor = $convert.base64Decode(
    'Cg1UYXNrUnVuU3RhdHVzEh8KG1RBU0tfUlVOX1NUQVRVU19VTlNQRUNJRklFRBAAEhoKFlRBU0'
    'tfUlVOX1NUQVRVU19RVUVVRUQQARIaChZUQVNLX1JVTl9TVEFUVVNfTEVBU0VEEAISGwoXVEFT'
    'S19SVU5fU1RBVFVTX1JVTk5JTkcQAxIYChRUQVNLX1JVTl9TVEFUVVNfRE9ORRAEEhoKFlRBU0'
    'tfUlVOX1NUQVRVU19GQUlMRUQQBRIdChlUQVNLX1JVTl9TVEFUVVNfQ0FOQ0VMTEVEEAY=');

@$core.Deprecated('Use taskTriggerDescriptor instead')
const TaskTrigger$json = {
  '1': 'TaskTrigger',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 3, '10': 'id'},
    {'1': 'task_id', '3': 2, '4': 1, '5': 3, '10': 'taskId'},
    {'1': 'owner_iid', '3': 3, '4': 1, '5': 3, '10': 'ownerIid'},
    {
      '1': 'kind',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.c35.TaskTriggerKind',
      '10': 'kind'
    },
    {'1': 'label', '3': 5, '4': 1, '5': 9, '10': 'label'},
    {'1': 'cron_expr', '3': 6, '4': 1, '5': 9, '10': 'cronExpr'},
    {'1': 'timezone', '3': 7, '4': 1, '5': 9, '10': 'timezone'},
    {'1': 'run_at_ms', '3': 8, '4': 1, '5': 3, '10': 'runAtMs'},
    {'1': 'webhook_secret', '3': 9, '4': 1, '5': 9, '10': 'webhookSecret'},
    {'1': 'is_active', '3': 10, '4': 1, '5': 8, '10': 'isActive'},
    {'1': 'created_ts_ms', '3': 20, '4': 1, '5': 3, '10': 'createdTsMs'},
    {'1': 'updated_ts_ms', '3': 21, '4': 1, '5': 3, '10': 'updatedTsMs'},
    {'1': 'deleted_ts_ms', '3': 22, '4': 1, '5': 3, '10': 'deletedTsMs'},
  ],
};

/// Descriptor for `TaskTrigger`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List taskTriggerDescriptor = $convert.base64Decode(
    'CgtUYXNrVHJpZ2dlchIOCgJpZBgBIAEoA1ICaWQSFwoHdGFza19pZBgCIAEoA1IGdGFza0lkEh'
    'sKCW93bmVyX2lpZBgDIAEoA1IIb3duZXJJaWQSKAoEa2luZBgEIAEoDjIULmMzNS5UYXNrVHJp'
    'Z2dlcktpbmRSBGtpbmQSFAoFbGFiZWwYBSABKAlSBWxhYmVsEhsKCWNyb25fZXhwchgGIAEoCV'
    'IIY3JvbkV4cHISGgoIdGltZXpvbmUYByABKAlSCHRpbWV6b25lEhoKCXJ1bl9hdF9tcxgIIAEo'
    'A1IHcnVuQXRNcxIlCg53ZWJob29rX3NlY3JldBgJIAEoCVINd2ViaG9va1NlY3JldBIbCglpc1'
    '9hY3RpdmUYCiABKAhSCGlzQWN0aXZlEiIKDWNyZWF0ZWRfdHNfbXMYFCABKANSC2NyZWF0ZWRU'
    'c01zEiIKDXVwZGF0ZWRfdHNfbXMYFSABKANSC3VwZGF0ZWRUc01zEiIKDWRlbGV0ZWRfdHNfbX'
    'MYFiABKANSC2RlbGV0ZWRUc01z');

@$core.Deprecated('Use taskDescriptor instead')
const Task$json = {
  '1': 'Task',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 3, '10': 'id'},
    {'1': 'owner_iid', '3': 2, '4': 1, '5': 3, '10': 'ownerIid'},
    {'1': 'device_iid', '3': 3, '4': 1, '5': 3, '10': 'deviceIid'},
    {'1': 'name', '3': 4, '4': 1, '5': 9, '10': 'name'},
    {'1': 'skill_id', '3': 5, '4': 1, '5': 3, '10': 'skillId'},
    {'1': 'prompt', '3': 6, '4': 1, '5': 9, '10': 'prompt'},
    {'1': 'model', '3': 7, '4': 1, '5': 9, '10': 'model'},
    {'1': 'is_active', '3': 8, '4': 1, '5': 8, '10': 'isActive'},
    {
      '1': 'triggers',
      '3': 9,
      '4': 3,
      '5': 11,
      '6': '.c35.TaskTrigger',
      '10': 'triggers'
    },
    {'1': 'created_ts_ms', '3': 20, '4': 1, '5': 3, '10': 'createdTsMs'},
    {'1': 'updated_ts_ms', '3': 21, '4': 1, '5': 3, '10': 'updatedTsMs'},
    {'1': 'deleted_ts_ms', '3': 22, '4': 1, '5': 3, '10': 'deletedTsMs'},
  ],
};

/// Descriptor for `Task`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List taskDescriptor = $convert.base64Decode(
    'CgRUYXNrEg4KAmlkGAEgASgDUgJpZBIbCglvd25lcl9paWQYAiABKANSCG93bmVySWlkEh0KCm'
    'RldmljZV9paWQYAyABKANSCWRldmljZUlpZBISCgRuYW1lGAQgASgJUgRuYW1lEhkKCHNraWxs'
    'X2lkGAUgASgDUgdza2lsbElkEhYKBnByb21wdBgGIAEoCVIGcHJvbXB0EhQKBW1vZGVsGAcgAS'
    'gJUgVtb2RlbBIbCglpc19hY3RpdmUYCCABKAhSCGlzQWN0aXZlEiwKCHRyaWdnZXJzGAkgAygL'
    'MhAuYzM1LlRhc2tUcmlnZ2VyUgh0cmlnZ2VycxIiCg1jcmVhdGVkX3RzX21zGBQgASgDUgtjcm'
    'VhdGVkVHNNcxIiCg11cGRhdGVkX3RzX21zGBUgASgDUgt1cGRhdGVkVHNNcxIiCg1kZWxldGVk'
    'X3RzX21zGBYgASgDUgtkZWxldGVkVHNNcw==');

@$core.Deprecated('Use taskRunDescriptor instead')
const TaskRun$json = {
  '1': 'TaskRun',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 3, '10': 'id'},
    {'1': 'owner_iid', '3': 2, '4': 1, '5': 3, '10': 'ownerIid'},
    {'1': 'device_iid', '3': 3, '4': 1, '5': 3, '10': 'deviceIid'},
    {'1': 'task_id', '3': 4, '4': 1, '5': 3, '10': 'taskId'},
    {'1': 'trigger_id', '3': 5, '4': 1, '5': 3, '10': 'triggerId'},
    {'1': 'chat_id', '3': 6, '4': 1, '5': 3, '10': 'chatId'},
    {'1': 'req_id', '3': 7, '4': 1, '5': 9, '10': 'reqId'},
    {
      '1': 'status',
      '3': 8,
      '4': 1,
      '5': 14,
      '6': '.c35.TaskRunStatus',
      '10': 'status'
    },
    {'1': 'prompt', '3': 9, '4': 1, '5': 9, '10': 'prompt'},
    {'1': 'skill_id', '3': 10, '4': 1, '5': 3, '10': 'skillId'},
    {'1': 'model', '3': 11, '4': 1, '5': 9, '10': 'model'},
    {'1': 'step_index', '3': 12, '4': 1, '5': 5, '10': 'stepIndex'},
    {'1': 'summary', '3': 13, '4': 1, '5': 9, '10': 'summary'},
    {'1': 'error', '3': 14, '4': 1, '5': 9, '10': 'error'},
    {'1': 'lease_pod', '3': 15, '4': 1, '5': 9, '10': 'leasePod'},
    {
      '1': 'lease_expires_ts_ms',
      '3': 16,
      '4': 1,
      '5': 3,
      '10': 'leaseExpiresTsMs'
    },
    {'1': 'started_ts_ms', '3': 17, '4': 1, '5': 3, '10': 'startedTsMs'},
    {'1': 'finished_ts_ms', '3': 18, '4': 1, '5': 3, '10': 'finishedTsMs'},
    {'1': 'created_ts_ms', '3': 20, '4': 1, '5': 3, '10': 'createdTsMs'},
    {'1': 'updated_ts_ms', '3': 21, '4': 1, '5': 3, '10': 'updatedTsMs'},
    {'1': 'deleted_ts_ms', '3': 22, '4': 1, '5': 3, '10': 'deletedTsMs'},
  ],
};

/// Descriptor for `TaskRun`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List taskRunDescriptor = $convert.base64Decode(
    'CgdUYXNrUnVuEg4KAmlkGAEgASgDUgJpZBIbCglvd25lcl9paWQYAiABKANSCG93bmVySWlkEh'
    '0KCmRldmljZV9paWQYAyABKANSCWRldmljZUlpZBIXCgd0YXNrX2lkGAQgASgDUgZ0YXNrSWQS'
    'HQoKdHJpZ2dlcl9pZBgFIAEoA1IJdHJpZ2dlcklkEhcKB2NoYXRfaWQYBiABKANSBmNoYXRJZB'
    'IVCgZyZXFfaWQYByABKAlSBXJlcUlkEioKBnN0YXR1cxgIIAEoDjISLmMzNS5UYXNrUnVuU3Rh'
    'dHVzUgZzdGF0dXMSFgoGcHJvbXB0GAkgASgJUgZwcm9tcHQSGQoIc2tpbGxfaWQYCiABKANSB3'
    'NraWxsSWQSFAoFbW9kZWwYCyABKAlSBW1vZGVsEh0KCnN0ZXBfaW5kZXgYDCABKAVSCXN0ZXBJ'
    'bmRleBIYCgdzdW1tYXJ5GA0gASgJUgdzdW1tYXJ5EhQKBWVycm9yGA4gASgJUgVlcnJvchIbCg'
    'lsZWFzZV9wb2QYDyABKAlSCGxlYXNlUG9kEi0KE2xlYXNlX2V4cGlyZXNfdHNfbXMYECABKANS'
    'EGxlYXNlRXhwaXJlc1RzTXMSIgoNc3RhcnRlZF90c19tcxgRIAEoA1ILc3RhcnRlZFRzTXMSJA'
    'oOZmluaXNoZWRfdHNfbXMYEiABKANSDGZpbmlzaGVkVHNNcxIiCg1jcmVhdGVkX3RzX21zGBQg'
    'ASgDUgtjcmVhdGVkVHNNcxIiCg11cGRhdGVkX3RzX21zGBUgASgDUgt1cGRhdGVkVHNNcxIiCg'
    '1kZWxldGVkX3RzX21zGBYgASgDUgtkZWxldGVkVHNNcw==');

@$core.Deprecated('Use reqTaskListDescriptor instead')
const ReqTaskList$json = {
  '1': 'ReqTaskList',
  '2': [
    {'1': 'device_iid', '3': 1, '4': 1, '5': 3, '10': 'deviceIid'},
    {'1': 'include_inactive', '3': 2, '4': 1, '5': 8, '10': 'includeInactive'},
  ],
};

/// Descriptor for `ReqTaskList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqTaskListDescriptor = $convert.base64Decode(
    'CgtSZXFUYXNrTGlzdBIdCgpkZXZpY2VfaWlkGAEgASgDUglkZXZpY2VJaWQSKQoQaW5jbHVkZV'
    '9pbmFjdGl2ZRgCIAEoCFIPaW5jbHVkZUluYWN0aXZl');

@$core.Deprecated('Use resTaskListDescriptor instead')
const ResTaskList$json = {
  '1': 'ResTaskList',
  '2': [
    {'1': 'tasks', '3': 1, '4': 3, '5': 11, '6': '.c35.Task', '10': 'tasks'},
  ],
};

/// Descriptor for `ResTaskList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resTaskListDescriptor = $convert.base64Decode(
    'CgtSZXNUYXNrTGlzdBIfCgV0YXNrcxgBIAMoCzIJLmMzNS5UYXNrUgV0YXNrcw==');

@$core.Deprecated('Use reqTaskPutDescriptor instead')
const ReqTaskPut$json = {
  '1': 'ReqTaskPut',
  '2': [
    {'1': 'task', '3': 1, '4': 1, '5': 11, '6': '.c35.Task', '10': 'task'},
  ],
};

/// Descriptor for `ReqTaskPut`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqTaskPutDescriptor = $convert.base64Decode(
    'CgpSZXFUYXNrUHV0Eh0KBHRhc2sYASABKAsyCS5jMzUuVGFza1IEdGFzaw==');

@$core.Deprecated('Use resTaskPutDescriptor instead')
const ResTaskPut$json = {
  '1': 'ResTaskPut',
  '2': [
    {'1': 'task', '3': 1, '4': 1, '5': 11, '6': '.c35.Task', '10': 'task'},
  ],
};

/// Descriptor for `ResTaskPut`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resTaskPutDescriptor = $convert.base64Decode(
    'CgpSZXNUYXNrUHV0Eh0KBHRhc2sYASABKAsyCS5jMzUuVGFza1IEdGFzaw==');

@$core.Deprecated('Use reqTaskRunStartDescriptor instead')
const ReqTaskRunStart$json = {
  '1': 'ReqTaskRunStart',
  '2': [
    {'1': 'device_iid', '3': 1, '4': 1, '5': 3, '10': 'deviceIid'},
    {'1': 'task_id', '3': 2, '4': 1, '5': 3, '10': 'taskId'},
    {'1': 'prompt', '3': 3, '4': 1, '5': 9, '10': 'prompt'},
    {'1': 'skill_id', '3': 4, '4': 1, '5': 3, '10': 'skillId'},
    {'1': 'model', '3': 5, '4': 1, '5': 9, '10': 'model'},
    {'1': 'chat_id', '3': 6, '4': 1, '5': 3, '10': 'chatId'},
    {'1': 'req_id', '3': 7, '4': 1, '5': 9, '10': 'reqId'},
  ],
};

/// Descriptor for `ReqTaskRunStart`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqTaskRunStartDescriptor = $convert.base64Decode(
    'Cg9SZXFUYXNrUnVuU3RhcnQSHQoKZGV2aWNlX2lpZBgBIAEoA1IJZGV2aWNlSWlkEhcKB3Rhc2'
    'tfaWQYAiABKANSBnRhc2tJZBIWCgZwcm9tcHQYAyABKAlSBnByb21wdBIZCghza2lsbF9pZBgE'
    'IAEoA1IHc2tpbGxJZBIUCgVtb2RlbBgFIAEoCVIFbW9kZWwSFwoHY2hhdF9pZBgGIAEoA1IGY2'
    'hhdElkEhUKBnJlcV9pZBgHIAEoCVIFcmVxSWQ=');

@$core.Deprecated('Use resTaskRunStartDescriptor instead')
const ResTaskRunStart$json = {
  '1': 'ResTaskRunStart',
  '2': [
    {'1': 'run', '3': 1, '4': 1, '5': 11, '6': '.c35.TaskRun', '10': 'run'},
  ],
};

/// Descriptor for `ResTaskRunStart`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resTaskRunStartDescriptor = $convert.base64Decode(
    'Cg9SZXNUYXNrUnVuU3RhcnQSHgoDcnVuGAEgASgLMgwuYzM1LlRhc2tSdW5SA3J1bg==');

@$core.Deprecated('Use reqTaskRunCancelDescriptor instead')
const ReqTaskRunCancel$json = {
  '1': 'ReqTaskRunCancel',
  '2': [
    {'1': 'run_id', '3': 1, '4': 1, '5': 3, '10': 'runId'},
  ],
};

/// Descriptor for `ReqTaskRunCancel`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqTaskRunCancelDescriptor = $convert
    .base64Decode('ChBSZXFUYXNrUnVuQ2FuY2VsEhUKBnJ1bl9pZBgBIAEoA1IFcnVuSWQ=');

@$core.Deprecated('Use resTaskRunCancelDescriptor instead')
const ResTaskRunCancel$json = {
  '1': 'ResTaskRunCancel',
  '2': [
    {'1': 'run', '3': 1, '4': 1, '5': 11, '6': '.c35.TaskRun', '10': 'run'},
  ],
};

/// Descriptor for `ResTaskRunCancel`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resTaskRunCancelDescriptor = $convert.base64Decode(
    'ChBSZXNUYXNrUnVuQ2FuY2VsEh4KA3J1bhgBIAEoCzIMLmMzNS5UYXNrUnVuUgNydW4=');

@$core.Deprecated('Use reqTaskRunListDescriptor instead')
const ReqTaskRunList$json = {
  '1': 'ReqTaskRunList',
  '2': [
    {'1': 'device_iid', '3': 1, '4': 1, '5': 3, '10': 'deviceIid'},
    {'1': 'since_ms', '3': 2, '4': 1, '5': 3, '10': 'sinceMs'},
    {'1': 'limit', '3': 3, '4': 1, '5': 5, '10': 'limit'},
  ],
};

/// Descriptor for `ReqTaskRunList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqTaskRunListDescriptor = $convert.base64Decode(
    'Cg5SZXFUYXNrUnVuTGlzdBIdCgpkZXZpY2VfaWlkGAEgASgDUglkZXZpY2VJaWQSGQoIc2luY2'
    'VfbXMYAiABKANSB3NpbmNlTXMSFAoFbGltaXQYAyABKAVSBWxpbWl0');

@$core.Deprecated('Use resTaskRunListDescriptor instead')
const ResTaskRunList$json = {
  '1': 'ResTaskRunList',
  '2': [
    {'1': 'runs', '3': 1, '4': 3, '5': 11, '6': '.c35.TaskRun', '10': 'runs'},
  ],
};

/// Descriptor for `ResTaskRunList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resTaskRunListDescriptor = $convert.base64Decode(
    'Cg5SZXNUYXNrUnVuTGlzdBIgCgRydW5zGAEgAygLMgwuYzM1LlRhc2tSdW5SBHJ1bnM=');

@$core.Deprecated('Use taskRunPushDescriptor instead')
const TaskRunPush$json = {
  '1': 'TaskRunPush',
  '2': [
    {'1': 'run', '3': 1, '4': 1, '5': 11, '6': '.c35.TaskRun', '10': 'run'},
  ],
};

/// Descriptor for `TaskRunPush`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List taskRunPushDescriptor = $convert.base64Decode(
    'CgtUYXNrUnVuUHVzaBIeCgNydW4YASABKAsyDC5jMzUuVGFza1J1blIDcnVu');

@$core.Deprecated('Use actDeviceTaskRunDescriptor instead')
const ActDeviceTaskRun$json = {
  '1': 'ActDeviceTaskRun',
  '2': [
    {'1': 'run_id', '3': 1, '4': 1, '5': 3, '10': 'runId'},
    {'1': 'device_iid', '3': 2, '4': 1, '5': 3, '10': 'deviceIid'},
    {'1': 'owner_iid', '3': 3, '4': 1, '5': 3, '10': 'ownerIid'},
    {'1': 'task_id', '3': 4, '4': 1, '5': 3, '10': 'taskId'},
    {'1': 'req_id', '3': 5, '4': 1, '5': 9, '10': 'reqId'},
    {'1': 'prompt', '3': 6, '4': 1, '5': 9, '10': 'prompt'},
    {'1': 'skill_id', '3': 7, '4': 1, '5': 3, '10': 'skillId'},
    {'1': 'model', '3': 8, '4': 1, '5': 9, '10': 'model'},
    {'1': 'step_index', '3': 9, '4': 1, '5': 5, '10': 'stepIndex'},
    {'1': 'chat_id', '3': 10, '4': 1, '5': 3, '10': 'chatId'},
  ],
};

/// Descriptor for `ActDeviceTaskRun`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List actDeviceTaskRunDescriptor = $convert.base64Decode(
    'ChBBY3REZXZpY2VUYXNrUnVuEhUKBnJ1bl9pZBgBIAEoA1IFcnVuSWQSHQoKZGV2aWNlX2lpZB'
    'gCIAEoA1IJZGV2aWNlSWlkEhsKCW93bmVyX2lpZBgDIAEoA1IIb3duZXJJaWQSFwoHdGFza19p'
    'ZBgEIAEoA1IGdGFza0lkEhUKBnJlcV9pZBgFIAEoCVIFcmVxSWQSFgoGcHJvbXB0GAYgASgJUg'
    'Zwcm9tcHQSGQoIc2tpbGxfaWQYByABKANSB3NraWxsSWQSFAoFbW9kZWwYCCABKAlSBW1vZGVs'
    'Eh0KCnN0ZXBfaW5kZXgYCSABKAVSCXN0ZXBJbmRleBIXCgdjaGF0X2lkGAogASgDUgZjaGF0SW'
    'Q=');

@$core.Deprecated('Use evDeviceTaskProgressDescriptor instead')
const EvDeviceTaskProgress$json = {
  '1': 'EvDeviceTaskProgress',
  '2': [
    {'1': 'run_id', '3': 1, '4': 1, '5': 3, '10': 'runId'},
    {'1': 'device_iid', '3': 2, '4': 1, '5': 3, '10': 'deviceIid'},
    {'1': 'step_index', '3': 3, '4': 1, '5': 5, '10': 'stepIndex'},
    {'1': 'topic', '3': 4, '4': 1, '5': 9, '10': 'topic'},
    {'1': 'text', '3': 5, '4': 1, '5': 9, '10': 'text'},
    {'1': 'meta_json', '3': 6, '4': 1, '5': 9, '10': 'metaJson'},
  ],
};

/// Descriptor for `EvDeviceTaskProgress`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List evDeviceTaskProgressDescriptor = $convert.base64Decode(
    'ChRFdkRldmljZVRhc2tQcm9ncmVzcxIVCgZydW5faWQYASABKANSBXJ1bklkEh0KCmRldmljZV'
    '9paWQYAiABKANSCWRldmljZUlpZBIdCgpzdGVwX2luZGV4GAMgASgFUglzdGVwSW5kZXgSFAoF'
    'dG9waWMYBCABKAlSBXRvcGljEhIKBHRleHQYBSABKAlSBHRleHQSGwoJbWV0YV9qc29uGAYgAS'
    'gJUghtZXRhSnNvbg==');

@$core.Deprecated('Use evDeviceTaskDoneDescriptor instead')
const EvDeviceTaskDone$json = {
  '1': 'EvDeviceTaskDone',
  '2': [
    {'1': 'run_id', '3': 1, '4': 1, '5': 3, '10': 'runId'},
    {'1': 'device_iid', '3': 2, '4': 1, '5': 3, '10': 'deviceIid'},
    {
      '1': 'status',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.c35.TaskRunStatus',
      '10': 'status'
    },
    {'1': 'summary', '3': 4, '4': 1, '5': 9, '10': 'summary'},
    {'1': 'error', '3': 5, '4': 1, '5': 9, '10': 'error'},
    {'1': 'step_index', '3': 6, '4': 1, '5': 5, '10': 'stepIndex'},
  ],
};

/// Descriptor for `EvDeviceTaskDone`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List evDeviceTaskDoneDescriptor = $convert.base64Decode(
    'ChBFdkRldmljZVRhc2tEb25lEhUKBnJ1bl9pZBgBIAEoA1IFcnVuSWQSHQoKZGV2aWNlX2lpZB'
    'gCIAEoA1IJZGV2aWNlSWlkEioKBnN0YXR1cxgDIAEoDjISLmMzNS5UYXNrUnVuU3RhdHVzUgZz'
    'dGF0dXMSGAoHc3VtbWFyeRgEIAEoCVIHc3VtbWFyeRIUCgVlcnJvchgFIAEoCVIFZXJyb3ISHQ'
    'oKc3RlcF9pbmRleBgGIAEoBVIJc3RlcEluZGV4');

@$core.Deprecated('Use evDevicePresenceDescriptor instead')
const EvDevicePresence$json = {
  '1': 'EvDevicePresence',
  '2': [
    {'1': 'device_iid', '3': 1, '4': 1, '5': 3, '10': 'deviceIid'},
    {'1': 'owner_iid', '3': 2, '4': 1, '5': 3, '10': 'ownerIid'},
    {'1': 'online', '3': 3, '4': 1, '5': 8, '10': 'online'},
    {'1': 'agent_version', '3': 4, '4': 1, '5': 9, '10': 'agentVersion'},
    {'1': 'pod', '3': 5, '4': 1, '5': 9, '10': 'pod'},
  ],
};

/// Descriptor for `EvDevicePresence`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List evDevicePresenceDescriptor = $convert.base64Decode(
    'ChBFdkRldmljZVByZXNlbmNlEh0KCmRldmljZV9paWQYASABKANSCWRldmljZUlpZBIbCglvd2'
    '5lcl9paWQYAiABKANSCG93bmVySWlkEhYKBm9ubGluZRgDIAEoCFIGb25saW5lEiMKDWFnZW50'
    'X3ZlcnNpb24YBCABKAlSDGFnZW50VmVyc2lvbhIQCgNwb2QYBSABKAlSA3BvZA==');
