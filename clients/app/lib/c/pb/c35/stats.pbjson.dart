// This is a generated file - do not edit.
//
// Generated from c35/stats.proto.

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

@$core.Deprecated('Use diskMountStatDescriptor instead')
const DiskMountStat$json = {
  '1': 'DiskMountStat',
  '2': [
    {'1': 'label', '3': 1, '4': 1, '5': 9, '10': 'label'},
    {'1': 'mount', '3': 2, '4': 1, '5': 9, '10': 'mount'},
    {'1': 'used_bytes', '3': 3, '4': 1, '5': 4, '10': 'usedBytes'},
    {'1': 'total_bytes', '3': 4, '4': 1, '5': 4, '10': 'totalBytes'},
    {'1': 'read_bps', '3': 5, '4': 1, '5': 1, '10': 'readBps'},
    {'1': 'write_bps', '3': 6, '4': 1, '5': 1, '10': 'writeBps'},
  ],
};

/// Descriptor for `DiskMountStat`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List diskMountStatDescriptor = $convert.base64Decode(
    'Cg1EaXNrTW91bnRTdGF0EhQKBWxhYmVsGAEgASgJUgVsYWJlbBIUCgVtb3VudBgCIAEoCVIFbW'
    '91bnQSHQoKdXNlZF9ieXRlcxgDIAEoBFIJdXNlZEJ5dGVzEh8KC3RvdGFsX2J5dGVzGAQgASgE'
    'Ugp0b3RhbEJ5dGVzEhkKCHJlYWRfYnBzGAUgASgBUgdyZWFkQnBzEhsKCXdyaXRlX2JwcxgGIA'
    'EoAVIId3JpdGVCcHM=');

@$core.Deprecated('Use diskDeviceStatDescriptor instead')
const DiskDeviceStat$json = {
  '1': 'DiskDeviceStat',
  '2': [
    {'1': 'device', '3': 1, '4': 1, '5': 9, '10': 'device'},
    {'1': 'mount', '3': 2, '4': 1, '5': 9, '10': 'mount'},
    {'1': 'label', '3': 3, '4': 1, '5': 9, '10': 'label'},
    {'1': 'is_boot', '3': 4, '4': 1, '5': 8, '10': 'isBoot'},
    {'1': 'used_bytes', '3': 5, '4': 1, '5': 4, '10': 'usedBytes'},
    {'1': 'total_bytes', '3': 6, '4': 1, '5': 4, '10': 'totalBytes'},
    {'1': 'read_bps', '3': 7, '4': 1, '5': 1, '10': 'readBps'},
    {'1': 'write_bps', '3': 8, '4': 1, '5': 1, '10': 'writeBps'},
  ],
};

/// Descriptor for `DiskDeviceStat`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List diskDeviceStatDescriptor = $convert.base64Decode(
    'Cg5EaXNrRGV2aWNlU3RhdBIWCgZkZXZpY2UYASABKAlSBmRldmljZRIUCgVtb3VudBgCIAEoCV'
    'IFbW91bnQSFAoFbGFiZWwYAyABKAlSBWxhYmVsEhcKB2lzX2Jvb3QYBCABKAhSBmlzQm9vdBId'
    'Cgp1c2VkX2J5dGVzGAUgASgEUgl1c2VkQnl0ZXMSHwoLdG90YWxfYnl0ZXMYBiABKARSCnRvdG'
    'FsQnl0ZXMSGQoIcmVhZF9icHMYByABKAFSB3JlYWRCcHMSGwoJd3JpdGVfYnBzGAggASgBUgh3'
    'cml0ZUJwcw==');

@$core.Deprecated('Use volumeStatDescriptor instead')
const VolumeStat$json = {
  '1': 'VolumeStat',
  '2': [
    {'1': 'namespace', '3': 1, '4': 1, '5': 9, '10': 'namespace'},
    {'1': 'pvc_name', '3': 2, '4': 1, '5': 9, '10': 'pvcName'},
    {'1': 'pod_name', '3': 3, '4': 1, '5': 9, '10': 'podName'},
    {'1': 'node_name', '3': 4, '4': 1, '5': 9, '10': 'nodeName'},
    {'1': 'used_bytes', '3': 5, '4': 1, '5': 4, '10': 'usedBytes'},
    {'1': 'capacity_bytes', '3': 6, '4': 1, '5': 4, '10': 'capacityBytes'},
    {'1': 'storage_class', '3': 7, '4': 1, '5': 9, '10': 'storageClass'},
    {'1': 'label', '3': 8, '4': 1, '5': 9, '10': 'label'},
  ],
};

/// Descriptor for `VolumeStat`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List volumeStatDescriptor = $convert.base64Decode(
    'CgpWb2x1bWVTdGF0EhwKCW5hbWVzcGFjZRgBIAEoCVIJbmFtZXNwYWNlEhkKCHB2Y19uYW1lGA'
    'IgASgJUgdwdmNOYW1lEhkKCHBvZF9uYW1lGAMgASgJUgdwb2ROYW1lEhsKCW5vZGVfbmFtZRgE'
    'IAEoCVIIbm9kZU5hbWUSHQoKdXNlZF9ieXRlcxgFIAEoBFIJdXNlZEJ5dGVzEiUKDmNhcGFjaX'
    'R5X2J5dGVzGAYgASgEUg1jYXBhY2l0eUJ5dGVzEiMKDXN0b3JhZ2VfY2xhc3MYByABKAlSDHN0'
    'b3JhZ2VDbGFzcxIUCgVsYWJlbBgIIAEoCVIFbGFiZWw=');

@$core.Deprecated('Use nodeStatDescriptor instead')
const NodeStat$json = {
  '1': 'NodeStat',
  '2': [
    {'1': 'node_name', '3': 1, '4': 1, '5': 9, '10': 'nodeName'},
    {'1': 'cpu_cores', '3': 2, '4': 1, '5': 5, '10': 'cpuCores'},
    {'1': 'cpu_pct', '3': 3, '4': 1, '5': 1, '10': 'cpuPct'},
    {'1': 'mem_used_bytes', '3': 4, '4': 1, '5': 4, '10': 'memUsedBytes'},
    {'1': 'mem_total_bytes', '3': 5, '4': 1, '5': 4, '10': 'memTotalBytes'},
    {
      '1': 'mounts',
      '3': 6,
      '4': 3,
      '5': 11,
      '6': '.c35.DiskMountStat',
      '10': 'mounts'
    },
    {'1': 'net_in_bps', '3': 7, '4': 1, '5': 1, '10': 'netInBps'},
    {'1': 'net_out_bps', '3': 8, '4': 1, '5': 1, '10': 'netOutBps'},
    {'1': 'ts_ms', '3': 9, '4': 1, '5': 3, '10': 'tsMs'},
    {
      '1': 'devices',
      '3': 10,
      '4': 3,
      '5': 11,
      '6': '.c35.DiskDeviceStat',
      '10': 'devices'
    },
  ],
};

/// Descriptor for `NodeStat`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List nodeStatDescriptor = $convert.base64Decode(
    'CghOb2RlU3RhdBIbCglub2RlX25hbWUYASABKAlSCG5vZGVOYW1lEhsKCWNwdV9jb3JlcxgCIA'
    'EoBVIIY3B1Q29yZXMSFwoHY3B1X3BjdBgDIAEoAVIGY3B1UGN0EiQKDm1lbV91c2VkX2J5dGVz'
    'GAQgASgEUgxtZW1Vc2VkQnl0ZXMSJgoPbWVtX3RvdGFsX2J5dGVzGAUgASgEUg1tZW1Ub3RhbE'
    'J5dGVzEioKBm1vdW50cxgGIAMoCzISLmMzNS5EaXNrTW91bnRTdGF0UgZtb3VudHMSHAoKbmV0'
    'X2luX2JwcxgHIAEoAVIIbmV0SW5CcHMSHgoLbmV0X291dF9icHMYCCABKAFSCW5ldE91dEJwcx'
    'ITCgV0c19tcxgJIAEoA1IEdHNNcxItCgdkZXZpY2VzGAogAygLMhMuYzM1LkRpc2tEZXZpY2VT'
    'dGF0UgdkZXZpY2Vz');

@$core.Deprecated('Use statsPushDescriptor instead')
const StatsPush$json = {
  '1': 'StatsPush',
  '2': [
    {
      '1': 'node',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.c35.NodeStat',
      '9': 0,
      '10': 'node'
    },
    {
      '1': 'volume',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.c35.VolumeStat',
      '9': 0,
      '10': 'volume'
    },
  ],
  '8': [
    {'1': 'body'},
  ],
};

/// Descriptor for `StatsPush`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List statsPushDescriptor = $convert.base64Decode(
    'CglTdGF0c1B1c2gSIwoEbm9kZRgBIAEoCzINLmMzNS5Ob2RlU3RhdEgAUgRub2RlEikKBnZvbH'
    'VtZRgCIAEoCzIPLmMzNS5Wb2x1bWVTdGF0SABSBnZvbHVtZUIGCgRib2R5');

@$core.Deprecated('Use reqStatsSubscribeDescriptor instead')
const ReqStatsSubscribe$json = {
  '1': 'ReqStatsSubscribe',
};

/// Descriptor for `ReqStatsSubscribe`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqStatsSubscribeDescriptor =
    $convert.base64Decode('ChFSZXFTdGF0c1N1YnNjcmliZQ==');

@$core.Deprecated('Use reqStatsUnsubscribeDescriptor instead')
const ReqStatsUnsubscribe$json = {
  '1': 'ReqStatsUnsubscribe',
};

/// Descriptor for `ReqStatsUnsubscribe`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqStatsUnsubscribeDescriptor =
    $convert.base64Decode('ChNSZXFTdGF0c1Vuc3Vic2NyaWJl');

@$core.Deprecated('Use reqLogSubscribeDescriptor instead')
const ReqLogSubscribe$json = {
  '1': 'ReqLogSubscribe',
  '2': [
    {
      '1': 'owner_iid',
      '3': 1,
      '4': 1,
      '5': 3,
      '9': 0,
      '10': 'ownerIid',
      '17': true
    },
  ],
  '8': [
    {'1': '_owner_iid'},
  ],
};

/// Descriptor for `ReqLogSubscribe`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqLogSubscribeDescriptor = $convert.base64Decode(
    'Cg9SZXFMb2dTdWJzY3JpYmUSIAoJb3duZXJfaWlkGAEgASgDSABSCG93bmVySWlkiAEBQgwKCl'
    '9vd25lcl9paWQ=');

@$core.Deprecated('Use reqLogUnsubscribeDescriptor instead')
const ReqLogUnsubscribe$json = {
  '1': 'ReqLogUnsubscribe',
};

/// Descriptor for `ReqLogUnsubscribe`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqLogUnsubscribeDescriptor =
    $convert.base64Decode('ChFSZXFMb2dVbnN1YnNjcmliZQ==');
