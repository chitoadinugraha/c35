// This is a generated file - do not edit.
//
// Generated from c35/data_source.proto.

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

@$core.Deprecated('Use dataSourceDocDescriptor instead')
const DataSourceDoc$json = {
  '1': 'DataSourceDoc',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 3, '10': 'id'},
    {'1': 'bot_iid', '3': 2, '4': 1, '5': 3, '10': 'botIid'},
    {'1': 'source_kind', '3': 3, '4': 1, '5': 9, '10': 'sourceKind'},
    {'1': 'name', '3': 4, '4': 1, '5': 9, '10': 'name'},
    {'1': 'config_json', '3': 5, '4': 1, '5': 9, '10': 'configJson'},
    {'1': 'sync_status', '3': 6, '4': 1, '5': 9, '10': 'syncStatus'},
    {'1': 'row_count', '3': 7, '4': 1, '5': 5, '10': 'rowCount'},
    {'1': 'synced_ts_ms', '3': 8, '4': 1, '5': 3, '10': 'syncedTsMs'},
    {'1': 'updated_ts_ms', '3': 9, '4': 1, '5': 3, '10': 'updatedTsMs'},
  ],
};

/// Descriptor for `DataSourceDoc`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List dataSourceDocDescriptor = $convert.base64Decode(
    'Cg1EYXRhU291cmNlRG9jEg4KAmlkGAEgASgDUgJpZBIXCgdib3RfaWlkGAIgASgDUgZib3RJaW'
    'QSHwoLc291cmNlX2tpbmQYAyABKAlSCnNvdXJjZUtpbmQSEgoEbmFtZRgEIAEoCVIEbmFtZRIf'
    'Cgtjb25maWdfanNvbhgFIAEoCVIKY29uZmlnSnNvbhIfCgtzeW5jX3N0YXR1cxgGIAEoCVIKc3'
    'luY1N0YXR1cxIbCglyb3dfY291bnQYByABKAVSCHJvd0NvdW50EiAKDHN5bmNlZF90c19tcxgI'
    'IAEoA1IKc3luY2VkVHNNcxIiCg11cGRhdGVkX3RzX21zGAkgASgDUgt1cGRhdGVkVHNNcw==');

@$core.Deprecated('Use reqDataSourceListDescriptor instead')
const ReqDataSourceList$json = {
  '1': 'ReqDataSourceList',
  '2': [
    {'1': 'bot_iid', '3': 1, '4': 1, '5': 3, '10': 'botIid'},
    {
      '1': 'since_updated_ts_ms',
      '3': 2,
      '4': 1,
      '5': 3,
      '10': 'sinceUpdatedTsMs'
    },
    {'1': 'limit', '3': 3, '4': 1, '5': 5, '10': 'limit'},
  ],
};

/// Descriptor for `ReqDataSourceList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqDataSourceListDescriptor = $convert.base64Decode(
    'ChFSZXFEYXRhU291cmNlTGlzdBIXCgdib3RfaWlkGAEgASgDUgZib3RJaWQSLQoTc2luY2VfdX'
    'BkYXRlZF90c19tcxgCIAEoA1IQc2luY2VVcGRhdGVkVHNNcxIUCgVsaW1pdBgDIAEoBVIFbGlt'
    'aXQ=');

@$core.Deprecated('Use resDataSourceListDescriptor instead')
const ResDataSourceList$json = {
  '1': 'ResDataSourceList',
  '2': [
    {
      '1': 'items',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.c35.DataSourceDoc',
      '10': 'items'
    },
  ],
};

/// Descriptor for `ResDataSourceList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resDataSourceListDescriptor = $convert.base64Decode(
    'ChFSZXNEYXRhU291cmNlTGlzdBIoCgVpdGVtcxgBIAMoCzISLmMzNS5EYXRhU291cmNlRG9jUg'
    'VpdGVtcw==');

@$core.Deprecated('Use reqDataSourcePutDescriptor instead')
const ReqDataSourcePut$json = {
  '1': 'ReqDataSourcePut',
  '2': [
    {
      '1': 'doc',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.c35.DataSourceDoc',
      '10': 'doc'
    },
  ],
};

/// Descriptor for `ReqDataSourcePut`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqDataSourcePutDescriptor = $convert.base64Decode(
    'ChBSZXFEYXRhU291cmNlUHV0EiQKA2RvYxgBIAEoCzISLmMzNS5EYXRhU291cmNlRG9jUgNkb2'
    'M=');

@$core.Deprecated('Use resDataSourcePutDescriptor instead')
const ResDataSourcePut$json = {
  '1': 'ResDataSourcePut',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 3, '10': 'id'},
    {
      '1': 'doc',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.c35.DataSourceDoc',
      '10': 'doc'
    },
  ],
};

/// Descriptor for `ResDataSourcePut`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resDataSourcePutDescriptor = $convert.base64Decode(
    'ChBSZXNEYXRhU291cmNlUHV0Eg4KAmlkGAEgASgDUgJpZBIkCgNkb2MYAiABKAsyEi5jMzUuRG'
    'F0YVNvdXJjZURvY1IDZG9j');

@$core.Deprecated('Use reqDataSourceDeleteDescriptor instead')
const ReqDataSourceDelete$json = {
  '1': 'ReqDataSourceDelete',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 3, '10': 'id'},
  ],
};

/// Descriptor for `ReqDataSourceDelete`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqDataSourceDeleteDescriptor = $convert
    .base64Decode('ChNSZXFEYXRhU291cmNlRGVsZXRlEg4KAmlkGAEgASgDUgJpZA==');

@$core.Deprecated('Use resDataSourceDeleteDescriptor instead')
const ResDataSourceDelete$json = {
  '1': 'ResDataSourceDelete',
  '2': [
    {'1': 'ok', '3': 1, '4': 1, '5': 8, '10': 'ok'},
  ],
};

/// Descriptor for `ResDataSourceDelete`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resDataSourceDeleteDescriptor = $convert
    .base64Decode('ChNSZXNEYXRhU291cmNlRGVsZXRlEg4KAm9rGAEgASgIUgJvaw==');

@$core.Deprecated('Use reqDataSourceSyncDescriptor instead')
const ReqDataSourceSync$json = {
  '1': 'ReqDataSourceSync',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 3, '10': 'id'},
  ],
};

/// Descriptor for `ReqDataSourceSync`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqDataSourceSyncDescriptor =
    $convert.base64Decode('ChFSZXFEYXRhU291cmNlU3luYxIOCgJpZBgBIAEoA1ICaWQ=');

@$core.Deprecated('Use resDataSourceSyncDescriptor instead')
const ResDataSourceSync$json = {
  '1': 'ResDataSourceSync',
  '2': [
    {
      '1': 'doc',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.c35.DataSourceDoc',
      '10': 'doc'
    },
  ],
};

/// Descriptor for `ResDataSourceSync`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resDataSourceSyncDescriptor = $convert.base64Decode(
    'ChFSZXNEYXRhU291cmNlU3luYxIkCgNkb2MYASABKAsyEi5jMzUuRGF0YVNvdXJjZURvY1IDZG'
    '9j');
