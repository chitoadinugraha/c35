// This is a generated file - do not edit.
//
// Generated from c35/identity.proto.

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
    {'1': 'location_city', '3': 11, '4': 1, '5': 9, '10': 'locationCity'},
    {'1': 'location_region', '3': 12, '4': 1, '5': 9, '10': 'locationRegion'},
    {'1': 'location_country', '3': 13, '4': 1, '5': 9, '10': 'locationCountry'},
    {'1': 'location_source', '3': 14, '4': 1, '5': 9, '10': 'locationSource'},
  ],
};

/// Descriptor for `IdentityProfile`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List identityProfileDescriptor = $convert.base64Decode(
    'Cg9JZGVudGl0eVByb2ZpbGUSEAoDaWlkGAEgASgDUgNpaWQSEgoEa2luZBgCIAEoCVIEa2luZB'
    'ISCgR0eXBlGAMgASgJUgR0eXBlEhkKCGFsaWVuX2lkGAQgASgJUgdhbGllbklkEhIKBG5hbWUY'
    'BSABKAlSBG5hbWUSEAoDcGljGAYgASgJUgNwaWMSFgoGbG9jYWxlGAcgASgJUgZsb2NhbGUSDg'
    'oCdHoYCCABKAlSAnR6Eh8KC2JpbGxpbmdfaWlkGAkgASgDUgpiaWxsaW5nSWlkEhcKB2lzX3Jv'
    'b3QYCiABKAhSBmlzUm9vdBIjCg1sb2NhdGlvbl9jaXR5GAsgASgJUgxsb2NhdGlvbkNpdHkSJw'
    'oPbG9jYXRpb25fcmVnaW9uGAwgASgJUg5sb2NhdGlvblJlZ2lvbhIpChBsb2NhdGlvbl9jb3Vu'
    'dHJ5GA0gASgJUg9sb2NhdGlvbkNvdW50cnkSJwoPbG9jYXRpb25fc291cmNlGA4gASgJUg5sb2'
    'NhdGlvblNvdXJjZQ==');

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

@$core.Deprecated('Use identityRowDescriptor instead')
const IdentityRow$json = {
  '1': 'IdentityRow',
  '2': [
    {'1': 'iid', '3': 1, '4': 1, '5': 3, '10': 'iid'},
    {'1': 'kind', '3': 2, '4': 1, '5': 9, '10': 'kind'},
    {'1': 'type', '3': 3, '4': 1, '5': 9, '10': 'type'},
    {'1': 'alien_id', '3': 4, '4': 1, '5': 9, '10': 'alienId'},
    {'1': 'name', '3': 5, '4': 1, '5': 9, '10': 'name'},
    {'1': 'pic', '3': 6, '4': 1, '5': 9, '10': 'pic'},
    {'1': 'meta_json', '3': 7, '4': 1, '5': 9, '10': 'metaJson'},
    {'1': 'owner_iid', '3': 8, '4': 1, '5': 3, '10': 'ownerIid'},
    {'1': 'updated_ts_ms', '3': 9, '4': 1, '5': 3, '10': 'updatedTsMs'},
  ],
};

/// Descriptor for `IdentityRow`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List identityRowDescriptor = $convert.base64Decode(
    'CgtJZGVudGl0eVJvdxIQCgNpaWQYASABKANSA2lpZBISCgRraW5kGAIgASgJUgRraW5kEhIKBH'
    'R5cGUYAyABKAlSBHR5cGUSGQoIYWxpZW5faWQYBCABKAlSB2FsaWVuSWQSEgoEbmFtZRgFIAEo'
    'CVIEbmFtZRIQCgNwaWMYBiABKAlSA3BpYxIbCgltZXRhX2pzb24YByABKAlSCG1ldGFKc29uEh'
    'sKCW93bmVyX2lpZBgIIAEoA1IIb3duZXJJaWQSIgoNdXBkYXRlZF90c19tcxgJIAEoA1ILdXBk'
    'YXRlZFRzTXM=');

@$core.Deprecated('Use identityListRowDescriptor instead')
const IdentityListRow$json = {
  '1': 'IdentityListRow',
  '2': [
    {
      '1': 'identity',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.c35.IdentityRow',
      '10': 'identity'
    },
    {'1': 'grant_role', '3': 2, '4': 1, '5': 9, '10': 'grantRole'},
    {'1': 'is_pinned', '3': 3, '4': 1, '5': 8, '10': 'isPinned'},
    {'1': 'sort_order', '3': 4, '4': 1, '5': 5, '10': 'sortOrder'},
    {'1': 'archived_ts_ms', '3': 5, '4': 1, '5': 3, '10': 'archivedTsMs'},
  ],
};

/// Descriptor for `IdentityListRow`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List identityListRowDescriptor = $convert.base64Decode(
    'Cg9JZGVudGl0eUxpc3RSb3cSLAoIaWRlbnRpdHkYASABKAsyEC5jMzUuSWRlbnRpdHlSb3dSCG'
    'lkZW50aXR5Eh0KCmdyYW50X3JvbGUYAiABKAlSCWdyYW50Um9sZRIbCglpc19waW5uZWQYAyAB'
    'KAhSCGlzUGlubmVkEh0KCnNvcnRfb3JkZXIYBCABKAVSCXNvcnRPcmRlchIkCg5hcmNoaXZlZF'
    '90c19tcxgFIAEoA1IMYXJjaGl2ZWRUc01z');

@$core.Deprecated('Use reqIdentityListDescriptor instead')
const ReqIdentityList$json = {
  '1': 'ReqIdentityList',
  '2': [
    {'1': 'kinds', '3': 1, '4': 3, '5': 9, '10': 'kinds'},
    {'1': 'include_archived', '3': 2, '4': 1, '5': 8, '10': 'includeArchived'},
  ],
};

/// Descriptor for `ReqIdentityList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqIdentityListDescriptor = $convert.base64Decode(
    'Cg9SZXFJZGVudGl0eUxpc3QSFAoFa2luZHMYASADKAlSBWtpbmRzEikKEGluY2x1ZGVfYXJjaG'
    'l2ZWQYAiABKAhSD2luY2x1ZGVBcmNoaXZlZA==');

@$core.Deprecated('Use resIdentityListDescriptor instead')
const ResIdentityList$json = {
  '1': 'ResIdentityList',
  '2': [
    {
      '1': 'rows',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.c35.IdentityListRow',
      '10': 'rows'
    },
  ],
};

/// Descriptor for `ResIdentityList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resIdentityListDescriptor = $convert.base64Decode(
    'Cg9SZXNJZGVudGl0eUxpc3QSKAoEcm93cxgBIAMoCzIULmMzNS5JZGVudGl0eUxpc3RSb3dSBH'
    'Jvd3M=');

@$core.Deprecated('Use reqIdentityGrantPatchDescriptor instead')
const ReqIdentityGrantPatch$json = {
  '1': 'ReqIdentityGrantPatch',
  '2': [
    {'1': 'resource_iid', '3': 1, '4': 1, '5': 3, '10': 'resourceIid'},
    {
      '1': 'is_pinned',
      '3': 2,
      '4': 1,
      '5': 8,
      '9': 0,
      '10': 'isPinned',
      '17': true
    },
    {
      '1': 'sort_order',
      '3': 3,
      '4': 1,
      '5': 5,
      '9': 1,
      '10': 'sortOrder',
      '17': true
    },
    {
      '1': 'archived',
      '3': 4,
      '4': 1,
      '5': 8,
      '9': 2,
      '10': 'archived',
      '17': true
    },
  ],
  '8': [
    {'1': '_is_pinned'},
    {'1': '_sort_order'},
    {'1': '_archived'},
  ],
};

/// Descriptor for `ReqIdentityGrantPatch`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqIdentityGrantPatchDescriptor = $convert.base64Decode(
    'ChVSZXFJZGVudGl0eUdyYW50UGF0Y2gSIQoMcmVzb3VyY2VfaWlkGAEgASgDUgtyZXNvdXJjZU'
    'lpZBIgCglpc19waW5uZWQYAiABKAhIAFIIaXNQaW5uZWSIAQESIgoKc29ydF9vcmRlchgDIAEo'
    'BUgBUglzb3J0T3JkZXKIAQESHwoIYXJjaGl2ZWQYBCABKAhIAlIIYXJjaGl2ZWSIAQFCDAoKX2'
    'lzX3Bpbm5lZEINCgtfc29ydF9vcmRlckILCglfYXJjaGl2ZWQ=');

@$core.Deprecated('Use resIdentityGrantPatchDescriptor instead')
const ResIdentityGrantPatch$json = {
  '1': 'ResIdentityGrantPatch',
  '2': [
    {
      '1': 'row',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.c35.IdentityListRow',
      '10': 'row'
    },
  ],
};

/// Descriptor for `ResIdentityGrantPatch`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resIdentityGrantPatchDescriptor = $convert.base64Decode(
    'ChVSZXNJZGVudGl0eUdyYW50UGF0Y2gSJgoDcm93GAEgASgLMhQuYzM1LklkZW50aXR5TGlzdF'
    'Jvd1IDcm93');

@$core.Deprecated('Use reqIdentityPutDescriptor instead')
const ReqIdentityPut$json = {
  '1': 'ReqIdentityPut',
  '2': [
    {'1': 'iid', '3': 1, '4': 1, '5': 3, '10': 'iid'},
    {'1': 'kind', '3': 2, '4': 1, '5': 9, '10': 'kind'},
    {'1': 'type', '3': 3, '4': 1, '5': 9, '10': 'type'},
    {'1': 'name', '3': 4, '4': 1, '5': 9, '10': 'name'},
    {'1': 'pic', '3': 5, '4': 1, '5': 9, '10': 'pic'},
    {'1': 'alien_id', '3': 6, '4': 1, '5': 9, '10': 'alienId'},
    {'1': 'meta_json', '3': 7, '4': 1, '5': 9, '10': 'metaJson'},
  ],
};

/// Descriptor for `ReqIdentityPut`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqIdentityPutDescriptor = $convert.base64Decode(
    'Cg5SZXFJZGVudGl0eVB1dBIQCgNpaWQYASABKANSA2lpZBISCgRraW5kGAIgASgJUgRraW5kEh'
    'IKBHR5cGUYAyABKAlSBHR5cGUSEgoEbmFtZRgEIAEoCVIEbmFtZRIQCgNwaWMYBSABKAlSA3Bp'
    'YxIZCghhbGllbl9pZBgGIAEoCVIHYWxpZW5JZBIbCgltZXRhX2pzb24YByABKAlSCG1ldGFKc2'
    '9u');

@$core.Deprecated('Use resIdentityPutDescriptor instead')
const ResIdentityPut$json = {
  '1': 'ResIdentityPut',
  '2': [
    {
      '1': 'row',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.c35.IdentityListRow',
      '10': 'row'
    },
  ],
};

/// Descriptor for `ResIdentityPut`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resIdentityPutDescriptor = $convert.base64Decode(
    'Cg5SZXNJZGVudGl0eVB1dBImCgNyb3cYASABKAsyFC5jMzUuSWRlbnRpdHlMaXN0Um93UgNyb3'
    'c=');

@$core.Deprecated('Use reqIdentityDeleteDescriptor instead')
const ReqIdentityDelete$json = {
  '1': 'ReqIdentityDelete',
  '2': [
    {'1': 'iid', '3': 1, '4': 1, '5': 3, '10': 'iid'},
  ],
};

/// Descriptor for `ReqIdentityDelete`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqIdentityDeleteDescriptor = $convert
    .base64Decode('ChFSZXFJZGVudGl0eURlbGV0ZRIQCgNpaWQYASABKANSA2lpZA==');

@$core.Deprecated('Use resIdentityDeleteDescriptor instead')
const ResIdentityDelete$json = {
  '1': 'ResIdentityDelete',
  '2': [
    {'1': 'ok', '3': 1, '4': 1, '5': 8, '10': 'ok'},
    {'1': 'error', '3': 2, '4': 1, '5': 9, '10': 'error'},
  ],
};

/// Descriptor for `ResIdentityDelete`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resIdentityDeleteDescriptor = $convert.base64Decode(
    'ChFSZXNJZGVudGl0eURlbGV0ZRIOCgJvaxgBIAEoCFICb2sSFAoFZXJyb3IYAiABKAlSBWVycm'
    '9y');
