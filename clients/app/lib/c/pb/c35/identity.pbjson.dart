//
//  Generated code. Do not modify.
//  source: c35/identity.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use identityProfileDescriptor instead')
const IdentityProfile$json = {
  '1': 'IdentityProfile',
  '2': [
    {'1': 'iid', '3': 1, '4': 1, '5': 3, '10': 'iid'},
    {'1': 'kind', '3': 2, '4': 1, '5': 9, '10': 'kind'},
    {'1': 'type', '3': 3, '4': 1, '5': 9, '10': 'type'},
    {'1': 'alien_id', '3': 4, '4': 1, '5': 9, '10': 'alienId'},
    {'1': 'name', '3': 5, '4': 1, '5': 9, '10': 'name'},
    {'1': 'pic', '3': 6, '4': 1, '5': 9, '10': 'pic'},
    {'1': 'locale', '3': 7, '4': 1, '5': 9, '10': 'locale'},
    {'1': 'tz', '3': 8, '4': 1, '5': 9, '10': 'tz'},
    {'1': 'billing_iid', '3': 9, '4': 1, '5': 3, '10': 'billingIid'},
    {'1': 'is_root', '3': 10, '4': 1, '5': 8, '10': 'isRoot'},
  ],
};

/// Descriptor for `IdentityProfile`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List identityProfileDescriptor = $convert.base64Decode(
    'Cg9JZGVudGl0eVByb2ZpbGUSEAoDaWlkGAEgASgDUgNpaWQSEgoEa2luZBgCIAEoCVIEa2luZB'
    'ISCgR0eXBlGAMgASgJUgR0eXBlEhkKCGFsaWVuX2lkGAQgASgJUgdhbGllbklkEhIKBG5hbWUY'
    'BSABKAlSBG5hbWUSEAoDcGljGAYgASgJUgNwaWMSFgoGbG9jYWxlGAcgASgJUgZsb2NhbGUSDg'
    'oCdHoYCCABKAlSAnR6Eh8KC2JpbGxpbmdfaWlkGAkgASgDUgpiaWxsaW5nSWlkEhcKB2lzX3Jv'
    'b3QYCiABKAhSBmlzUm9vdA==');

@$core.Deprecated('Use navCountsDescriptor instead')
const NavCounts$json = {
  '1': 'NavCounts',
  '2': [
    {'1': 'bots', '3': 1, '4': 1, '5': 5, '10': 'bots'},
    {'1': 'devices', '3': 2, '4': 1, '5': 5, '10': 'devices'},
    {'1': 'sites', '3': 3, '4': 1, '5': 5, '10': 'sites'},
  ],
};

/// Descriptor for `NavCounts`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List navCountsDescriptor = $convert.base64Decode(
    'CglOYXZDb3VudHMSEgoEYm90cxgBIAEoBVIEYm90cxIYCgdkZXZpY2VzGAIgASgFUgdkZXZpY2'
    'VzEhQKBXNpdGVzGAMgASgFUgVzaXRlcw==');

@$core.Deprecated('Use identityGrantDescriptor instead')
const IdentityGrant$json = {
  '1': 'IdentityGrant',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 3, '10': 'id'},
    {'1': 'resource_iid', '3': 2, '4': 1, '5': 3, '10': 'resourceIid'},
    {'1': 'grantee_iid', '3': 3, '4': 1, '5': 3, '10': 'granteeIid'},
    {'1': 'role', '3': 4, '4': 1, '5': 9, '10': 'role'},
    {'1': 'permissions', '3': 5, '4': 3, '5': 9, '10': 'permissions'},
    {'1': 'is_pinned', '3': 6, '4': 1, '5': 8, '10': 'isPinned'},
    {'1': 'meta_json', '3': 7, '4': 1, '5': 9, '10': 'metaJson'},
    {'1': 'created_ts_ms', '3': 8, '4': 1, '5': 3, '10': 'createdTsMs'},
    {'1': 'updated_ts_ms', '3': 9, '4': 1, '5': 3, '10': 'updatedTsMs'},
    {'1': 'deleted_ts_ms', '3': 10, '4': 1, '5': 3, '10': 'deletedTsMs'},
  ],
};

/// Descriptor for `IdentityGrant`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List identityGrantDescriptor = $convert.base64Decode(
    'Cg1JZGVudGl0eUdyYW50Eg4KAmlkGAEgASgDUgJpZBIhCgxyZXNvdXJjZV9paWQYAiABKANSC3'
    'Jlc291cmNlSWlkEh8KC2dyYW50ZWVfaWlkGAMgASgDUgpncmFudGVlSWlkEhIKBHJvbGUYBCAB'
    'KAlSBHJvbGUSIAoLcGVybWlzc2lvbnMYBSADKAlSC3Blcm1pc3Npb25zEhsKCWlzX3Bpbm5lZB'
    'gGIAEoCFIIaXNQaW5uZWQSGwoJbWV0YV9qc29uGAcgASgJUghtZXRhSnNvbhIiCg1jcmVhdGVk'
    'X3RzX21zGAggASgDUgtjcmVhdGVkVHNNcxIiCg11cGRhdGVkX3RzX21zGAkgASgDUgt1cGRhdG'
    'VkVHNNcxIiCg1kZWxldGVkX3RzX21zGAogASgDUgtkZWxldGVkVHNNcw==');

