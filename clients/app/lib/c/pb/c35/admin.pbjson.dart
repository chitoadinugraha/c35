// This is a generated file - do not edit.
//
// Generated from c35/admin.proto.

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

@$core.Deprecated('Use adminUserHitDescriptor instead')
const AdminUserHit$json = {
  '1': 'AdminUserHit',
  '2': [
    {'1': 'identity_id', '3': 1, '4': 1, '5': 3, '10': 'identityId'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'email', '3': 3, '4': 1, '5': 9, '10': 'email'},
    {'1': 'avatar_url', '3': 4, '4': 1, '5': 9, '10': 'avatarUrl'},
    {'1': 'handle', '3': 5, '4': 1, '5': 9, '10': 'handle'},
  ],
};

/// Descriptor for `AdminUserHit`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List adminUserHitDescriptor = $convert.base64Decode(
    'CgxBZG1pblVzZXJIaXQSHwoLaWRlbnRpdHlfaWQYASABKANSCmlkZW50aXR5SWQSEgoEbmFtZR'
    'gCIAEoCVIEbmFtZRIUCgVlbWFpbBgDIAEoCVIFZW1haWwSHQoKYXZhdGFyX3VybBgEIAEoCVIJ'
    'YXZhdGFyVXJsEhYKBmhhbmRsZRgFIAEoCVIGaGFuZGxl');

@$core.Deprecated('Use reqAdminUserSearchDescriptor instead')
const ReqAdminUserSearch$json = {
  '1': 'ReqAdminUserSearch',
  '2': [
    {'1': 'query', '3': 1, '4': 1, '5': 9, '10': 'query'},
    {'1': 'limit', '3': 2, '4': 1, '5': 5, '10': 'limit'},
  ],
};

/// Descriptor for `ReqAdminUserSearch`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqAdminUserSearchDescriptor = $convert.base64Decode(
    'ChJSZXFBZG1pblVzZXJTZWFyY2gSFAoFcXVlcnkYASABKAlSBXF1ZXJ5EhQKBWxpbWl0GAIgAS'
    'gFUgVsaW1pdA==');

@$core.Deprecated('Use resAdminUserSearchDescriptor instead')
const ResAdminUserSearch$json = {
  '1': 'ResAdminUserSearch',
  '2': [
    {
      '1': 'users',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.c35.AdminUserHit',
      '10': 'users'
    },
  ],
};

/// Descriptor for `ResAdminUserSearch`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resAdminUserSearchDescriptor = $convert.base64Decode(
    'ChJSZXNBZG1pblVzZXJTZWFyY2gSJwoFdXNlcnMYASADKAsyES5jMzUuQWRtaW5Vc2VySGl0Ug'
    'V1c2Vycw==');

@$core.Deprecated('Use reqAdminUserPutDescriptor instead')
const ReqAdminUserPut$json = {
  '1': 'ReqAdminUserPut',
  '2': [
    {
      '1': 'target_identity_id',
      '3': 1,
      '4': 1,
      '5': 3,
      '10': 'targetIdentityId'
    },
    {'1': 'name', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'name', '17': true},
    {
      '1': 'avatar_url',
      '3': 3,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'avatarUrl',
      '17': true
    },
    {
      '1': 'referred_by_uid',
      '3': 4,
      '4': 1,
      '5': 3,
      '9': 2,
      '10': 'referredByUid',
      '17': true
    },
    {'1': 'handle', '3': 5, '4': 1, '5': 9, '9': 3, '10': 'handle', '17': true},
    {
      '1': 'auth_email',
      '3': 6,
      '4': 1,
      '5': 9,
      '9': 4,
      '10': 'authEmail',
      '17': true
    },
  ],
  '8': [
    {'1': '_name'},
    {'1': '_avatar_url'},
    {'1': '_referred_by_uid'},
    {'1': '_handle'},
    {'1': '_auth_email'},
  ],
};

/// Descriptor for `ReqAdminUserPut`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqAdminUserPutDescriptor = $convert.base64Decode(
    'Cg9SZXFBZG1pblVzZXJQdXQSLAoSdGFyZ2V0X2lkZW50aXR5X2lkGAEgASgDUhB0YXJnZXRJZG'
    'VudGl0eUlkEhcKBG5hbWUYAiABKAlIAFIEbmFtZYgBARIiCgphdmF0YXJfdXJsGAMgASgJSAFS'
    'CWF2YXRhclVybIgBARIrCg9yZWZlcnJlZF9ieV91aWQYBCABKANIAlINcmVmZXJyZWRCeVVpZI'
    'gBARIbCgZoYW5kbGUYBSABKAlIA1IGaGFuZGxliAEBEiIKCmF1dGhfZW1haWwYBiABKAlIBFIJ'
    'YXV0aEVtYWlsiAEBQgcKBV9uYW1lQg0KC19hdmF0YXJfdXJsQhIKEF9yZWZlcnJlZF9ieV91aW'
    'RCCQoHX2hhbmRsZUINCgtfYXV0aF9lbWFpbA==');

@$core.Deprecated('Use resAdminUserPutDescriptor instead')
const ResAdminUserPut$json = {
  '1': 'ResAdminUserPut',
};

/// Descriptor for `ResAdminUserPut`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resAdminUserPutDescriptor =
    $convert.base64Decode('Cg9SZXNBZG1pblVzZXJQdXQ=');
