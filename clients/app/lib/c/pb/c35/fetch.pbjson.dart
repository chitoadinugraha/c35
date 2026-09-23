// This is a generated file - do not edit.
//
// Generated from c35/fetch.proto.

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

@$core.Deprecated('Use fetchFxPushDescriptor instead')
const FetchFxPush$json = {
  '1': 'FetchFxPush',
  '2': [
    {'1': 'fx_rate_id', '3': 1, '4': 1, '5': 3, '10': 'fxRateId'},
    {'1': 'micro_per_usd', '3': 2, '4': 1, '5': 3, '10': 'microPerUsd'},
    {'1': 'raw_idr_per_usd', '3': 3, '4': 1, '5': 1, '10': 'rawIdrPerUsd'},
    {
      '1': 'published_idr_per_usd',
      '3': 4,
      '4': 1,
      '5': 1,
      '10': 'publishedIdrPerUsd'
    },
    {'1': 'effective_ts_ms', '3': 5, '4': 1, '5': 3, '10': 'effectiveTsMs'},
  ],
};

/// Descriptor for `FetchFxPush`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fetchFxPushDescriptor = $convert.base64Decode(
    'CgtGZXRjaEZ4UHVzaBIcCgpmeF9yYXRlX2lkGAEgASgDUghmeFJhdGVJZBIiCg1taWNyb19wZX'
    'JfdXNkGAIgASgDUgttaWNyb1BlclVzZBIlCg9yYXdfaWRyX3Blcl91c2QYAyABKAFSDHJhd0lk'
    'clBlclVzZBIxChVwdWJsaXNoZWRfaWRyX3Blcl91c2QYBCABKAFSEnB1Ymxpc2hlZElkclBlcl'
    'VzZBImCg9lZmZlY3RpdmVfdHNfbXMYBSABKANSDWVmZmVjdGl2ZVRzTXM=');

@$core.Deprecated('Use fetchLlmCatalogPushDescriptor instead')
const FetchLlmCatalogPush$json = {
  '1': 'FetchLlmCatalogPush',
  '2': [
    {'1': 'sync_ts_ms', '3': 1, '4': 1, '5': 3, '10': 'syncTsMs'},
    {'1': 'model_count', '3': 2, '4': 1, '5': 5, '10': 'modelCount'},
  ],
};

/// Descriptor for `FetchLlmCatalogPush`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fetchLlmCatalogPushDescriptor = $convert.base64Decode(
    'ChNGZXRjaExsbUNhdGFsb2dQdXNoEhwKCnN5bmNfdHNfbXMYASABKANSCHN5bmNUc01zEh8KC2'
    '1vZGVsX2NvdW50GAIgASgFUgptb2RlbENvdW50');
