//
//  Generated code. Do not modify.
//  source: c35/log.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use logDescriptor instead')
const Log$json = {
  '1': 'Log',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 3, '10': 'id'},
    {'1': 'owner_iid', '3': 2, '4': 1, '5': 3, '10': 'ownerIid'},
    {'1': 'kind', '3': 3, '4': 1, '5': 9, '10': 'kind'},
    {'1': 'topic', '3': 4, '4': 1, '5': 9, '10': 'topic'},
    {'1': 'dv', '3': 5, '4': 1, '5': 9, '10': 'dv'},
    {'1': 'req_id', '3': 6, '4': 1, '5': 9, '10': 'reqId'},
    {'1': 'chat_id', '3': 7, '4': 1, '5': 3, '10': 'chatId'},
    {'1': 'task_id', '3': 8, '4': 1, '5': 3, '10': 'taskId'},
    {'1': 'device_iid', '3': 9, '4': 1, '5': 3, '10': 'deviceIid'},
    {'1': 'text', '3': 10, '4': 1, '5': 9, '10': 'text'},
    {'1': 'model', '3': 11, '4': 1, '5': 9, '10': 'model'},
    {'1': 'tokens_in', '3': 12, '4': 1, '5': 5, '10': 'tokensIn'},
    {'1': 'tokens_out', '3': 13, '4': 1, '5': 5, '10': 'tokensOut'},
    {'1': 'duration_ms', '3': 14, '4': 1, '5': 5, '10': 'durationMs'},
    {'1': 'cost_usd', '3': 15, '4': 1, '5': 1, '10': 'costUsd'},
    {'1': 'meta_json', '3': 16, '4': 1, '5': 9, '10': 'metaJson'},
    {'1': 'created_ts_ms', '3': 17, '4': 1, '5': 3, '10': 'createdTsMs'},
    {'1': 'updated_ts_ms', '3': 18, '4': 1, '5': 3, '10': 'updatedTsMs'},
    {'1': 'deleted_ts_ms', '3': 19, '4': 1, '5': 3, '10': 'deletedTsMs'},
  ],
};

/// Descriptor for `Log`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List logDescriptor = $convert.base64Decode(
    'CgNMb2cSDgoCaWQYASABKANSAmlkEhsKCW93bmVyX2lpZBgCIAEoA1IIb3duZXJJaWQSEgoEa2'
    'luZBgDIAEoCVIEa2luZBIUCgV0b3BpYxgEIAEoCVIFdG9waWMSDgoCZHYYBSABKAlSAmR2EhUK'
    'BnJlcV9pZBgGIAEoCVIFcmVxSWQSFwoHY2hhdF9pZBgHIAEoA1IGY2hhdElkEhcKB3Rhc2tfaW'
    'QYCCABKANSBnRhc2tJZBIdCgpkZXZpY2VfaWlkGAkgASgDUglkZXZpY2VJaWQSEgoEdGV4dBgK'
    'IAEoCVIEdGV4dBIUCgVtb2RlbBgLIAEoCVIFbW9kZWwSGwoJdG9rZW5zX2luGAwgASgFUgh0b2'
    'tlbnNJbhIdCgp0b2tlbnNfb3V0GA0gASgFUgl0b2tlbnNPdXQSHwoLZHVyYXRpb25fbXMYDiAB'
    'KAVSCmR1cmF0aW9uTXMSGQoIY29zdF91c2QYDyABKAFSB2Nvc3RVc2QSGwoJbWV0YV9qc29uGB'
    'AgASgJUghtZXRhSnNvbhIiCg1jcmVhdGVkX3RzX21zGBEgASgDUgtjcmVhdGVkVHNNcxIiCg11'
    'cGRhdGVkX3RzX21zGBIgASgDUgt1cGRhdGVkVHNNcxIiCg1kZWxldGVkX3RzX21zGBMgASgDUg'
    'tkZWxldGVkVHNNcw==');

@$core.Deprecated('Use logPushDescriptor instead')
const LogPush$json = {
  '1': 'LogPush',
  '2': [
    {'1': 'row', '3': 1, '4': 1, '5': 11, '6': '.c35.Log', '10': 'row'},
  ],
};

/// Descriptor for `LogPush`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List logPushDescriptor = $convert.base64Decode(
    'CgdMb2dQdXNoEhoKA3JvdxgBIAEoCzIILmMzNS5Mb2dSA3Jvdw==');

