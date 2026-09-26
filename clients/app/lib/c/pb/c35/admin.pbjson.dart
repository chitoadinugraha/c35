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

@$core.Deprecated('Use reqAdminLogListDescriptor instead')
const ReqAdminLogList$json = {
  '1': 'ReqAdminLogList',
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
    {'1': 'since_ms', '3': 2, '4': 1, '5': 3, '10': 'sinceMs'},
    {'1': 'until_ms', '3': 3, '4': 1, '5': 3, '10': 'untilMs'},
    {'1': 'text', '3': 4, '4': 1, '5': 9, '10': 'text'},
    {'1': 'kind', '3': 5, '4': 1, '5': 9, '9': 1, '10': 'kind', '17': true},
    {'1': 'topic', '3': 6, '4': 1, '5': 9, '9': 2, '10': 'topic', '17': true},
    {'1': 'limit', '3': 7, '4': 1, '5': 5, '10': 'limit'},
    {
      '1': 'before_id',
      '3': 8,
      '4': 1,
      '5': 3,
      '9': 3,
      '10': 'beforeId',
      '17': true
    },
    {
      '1': 'event_kind',
      '3': 9,
      '4': 1,
      '5': 9,
      '9': 4,
      '10': 'eventKind',
      '17': true
    },
    {'1': 'class', '3': 10, '4': 1, '5': 9, '9': 5, '10': 'class', '17': true},
    {
      '1': 'subject_prefix',
      '3': 11,
      '4': 1,
      '5': 9,
      '9': 6,
      '10': 'subjectPrefix',
      '17': true
    },
    {'1': 'exclude_trace', '3': 12, '4': 1, '5': 8, '10': 'excludeTrace'},
  ],
  '8': [
    {'1': '_owner_iid'},
    {'1': '_kind'},
    {'1': '_topic'},
    {'1': '_before_id'},
    {'1': '_event_kind'},
    {'1': '_class'},
    {'1': '_subject_prefix'},
  ],
};

/// Descriptor for `ReqAdminLogList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqAdminLogListDescriptor = $convert.base64Decode(
    'Cg9SZXFBZG1pbkxvZ0xpc3QSIAoJb3duZXJfaWlkGAEgASgDSABSCG93bmVySWlkiAEBEhkKCH'
    'NpbmNlX21zGAIgASgDUgdzaW5jZU1zEhkKCHVudGlsX21zGAMgASgDUgd1bnRpbE1zEhIKBHRl'
    'eHQYBCABKAlSBHRleHQSFwoEa2luZBgFIAEoCUgBUgRraW5kiAEBEhkKBXRvcGljGAYgASgJSA'
    'JSBXRvcGljiAEBEhQKBWxpbWl0GAcgASgFUgVsaW1pdBIgCgliZWZvcmVfaWQYCCABKANIA1II'
    'YmVmb3JlSWSIAQESIgoKZXZlbnRfa2luZBgJIAEoCUgEUglldmVudEtpbmSIAQESGQoFY2xhc3'
    'MYCiABKAlIBVIFY2xhc3OIAQESKgoOc3ViamVjdF9wcmVmaXgYCyABKAlIBlINc3ViamVjdFBy'
    'ZWZpeIgBARIjCg1leGNsdWRlX3RyYWNlGAwgASgIUgxleGNsdWRlVHJhY2VCDAoKX293bmVyX2'
    'lpZEIHCgVfa2luZEIICgZfdG9waWNCDAoKX2JlZm9yZV9pZEINCgtfZXZlbnRfa2luZEIICgZf'
    'Y2xhc3NCEQoPX3N1YmplY3RfcHJlZml4');

@$core.Deprecated('Use resAdminLogListDescriptor instead')
const ResAdminLogList$json = {
  '1': 'ResAdminLogList',
  '2': [
    {'1': 'logs', '3': 1, '4': 3, '5': 11, '6': '.c35.Log', '10': 'logs'},
  ],
};

/// Descriptor for `ResAdminLogList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resAdminLogListDescriptor = $convert.base64Decode(
    'Cg9SZXNBZG1pbkxvZ0xpc3QSHAoEbG9ncxgBIAMoCzIILmMzNS5Mb2dSBGxvZ3M=');
