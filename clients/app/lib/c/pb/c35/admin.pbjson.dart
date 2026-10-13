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

@$core.Deprecated('Use adminUserReferrerBriefDescriptor instead')
const AdminUserReferrerBrief$json = {
  '1': 'AdminUserReferrerBrief',
  '2': [
    {'1': 'identity_id', '3': 1, '4': 1, '5': 3, '10': 'identityId'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'alien_id', '3': 3, '4': 1, '5': 9, '10': 'alienId'},
  ],
};

/// Descriptor for `AdminUserReferrerBrief`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List adminUserReferrerBriefDescriptor =
    $convert.base64Decode(
        'ChZBZG1pblVzZXJSZWZlcnJlckJyaWVmEh8KC2lkZW50aXR5X2lkGAEgASgDUgppZGVudGl0eU'
        'lkEhIKBG5hbWUYAiABKAlSBG5hbWUSGQoIYWxpZW5faWQYAyABKAlSB2FsaWVuSWQ=');

@$core.Deprecated('Use adminUserRegistrationRowDescriptor instead')
const AdminUserRegistrationRow$json = {
  '1': 'AdminUserRegistrationRow',
  '2': [
    {'1': 'identity_id', '3': 1, '4': 1, '5': 3, '10': 'identityId'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'handle', '3': 3, '4': 1, '5': 9, '10': 'handle'},
    {'1': 'email', '3': 4, '4': 1, '5': 9, '10': 'email'},
    {'1': 'registered_ts_ms', '3': 5, '4': 1, '5': 3, '10': 'registeredTsMs'},
    {
      '1': 'referred_by',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.c35.AdminUserReferrerBrief',
      '10': 'referredBy'
    },
  ],
};

/// Descriptor for `AdminUserRegistrationRow`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List adminUserRegistrationRowDescriptor = $convert.base64Decode(
    'ChhBZG1pblVzZXJSZWdpc3RyYXRpb25Sb3cSHwoLaWRlbnRpdHlfaWQYASABKANSCmlkZW50aX'
    'R5SWQSEgoEbmFtZRgCIAEoCVIEbmFtZRIWCgZoYW5kbGUYAyABKAlSBmhhbmRsZRIUCgVlbWFp'
    'bBgEIAEoCVIFZW1haWwSKAoQcmVnaXN0ZXJlZF90c19tcxgFIAEoA1IOcmVnaXN0ZXJlZFRzTX'
    'MSPAoLcmVmZXJyZWRfYnkYBiABKAsyGy5jMzUuQWRtaW5Vc2VyUmVmZXJyZXJCcmllZlIKcmVm'
    'ZXJyZWRCeQ==');

@$core.Deprecated('Use reqAdminUserRegistrationsListDescriptor instead')
const ReqAdminUserRegistrationsList$json = {
  '1': 'ReqAdminUserRegistrationsList',
  '2': [
    {'1': 'preset', '3': 1, '4': 1, '5': 9, '10': 'preset'},
    {'1': 'since', '3': 2, '4': 1, '5': 9, '10': 'since'},
    {'1': 'until', '3': 3, '4': 1, '5': 9, '10': 'until'},
    {'1': 'count_only', '3': 4, '4': 1, '5': 8, '10': 'countOnly'},
    {'1': 'limit', '3': 5, '4': 1, '5': 5, '10': 'limit'},
    {
      '1': 'after_registered_ts_ms',
      '3': 6,
      '4': 1,
      '5': 3,
      '10': 'afterRegisteredTsMs'
    },
    {'1': 'after_identity_id', '3': 7, '4': 1, '5': 3, '10': 'afterIdentityId'},
    {'1': 'referred_by_uid', '3': 8, '4': 1, '5': 3, '10': 'referredByUid'},
    {'1': 'timezone', '3': 9, '4': 1, '5': 9, '10': 'timezone'},
  ],
};

/// Descriptor for `ReqAdminUserRegistrationsList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqAdminUserRegistrationsListDescriptor = $convert.base64Decode(
    'Ch1SZXFBZG1pblVzZXJSZWdpc3RyYXRpb25zTGlzdBIWCgZwcmVzZXQYASABKAlSBnByZXNldB'
    'IUCgVzaW5jZRgCIAEoCVIFc2luY2USFAoFdW50aWwYAyABKAlSBXVudGlsEh0KCmNvdW50X29u'
    'bHkYBCABKAhSCWNvdW50T25seRIUCgVsaW1pdBgFIAEoBVIFbGltaXQSMwoWYWZ0ZXJfcmVnaX'
    'N0ZXJlZF90c19tcxgGIAEoA1ITYWZ0ZXJSZWdpc3RlcmVkVHNNcxIqChFhZnRlcl9pZGVudGl0'
    'eV9pZBgHIAEoA1IPYWZ0ZXJJZGVudGl0eUlkEiYKD3JlZmVycmVkX2J5X3VpZBgIIAEoA1INcm'
    'VmZXJyZWRCeVVpZBIaCgh0aW1lem9uZRgJIAEoCVIIdGltZXpvbmU=');

@$core.Deprecated('Use resAdminUserRegistrationsListDescriptor instead')
const ResAdminUserRegistrationsList$json = {
  '1': 'ResAdminUserRegistrationsList',
  '2': [
    {'1': 'count', '3': 1, '4': 1, '5': 3, '10': 'count'},
    {
      '1': 'users',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.c35.AdminUserRegistrationRow',
      '10': 'users'
    },
    {'1': 'timezone_used', '3': 3, '4': 1, '5': 9, '10': 'timezoneUsed'},
    {'1': 'window_start_ms', '3': 4, '4': 1, '5': 3, '10': 'windowStartMs'},
    {'1': 'window_end_ms', '3': 5, '4': 1, '5': 3, '10': 'windowEndMs'},
    {'1': 'has_more', '3': 6, '4': 1, '5': 8, '10': 'hasMore'},
  ],
};

/// Descriptor for `ResAdminUserRegistrationsList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resAdminUserRegistrationsListDescriptor = $convert.base64Decode(
    'Ch1SZXNBZG1pblVzZXJSZWdpc3RyYXRpb25zTGlzdBIUCgVjb3VudBgBIAEoA1IFY291bnQSMw'
    'oFdXNlcnMYAiADKAsyHS5jMzUuQWRtaW5Vc2VyUmVnaXN0cmF0aW9uUm93UgV1c2VycxIjCg10'
    'aW1lem9uZV91c2VkGAMgASgJUgx0aW1lem9uZVVzZWQSJgoPd2luZG93X3N0YXJ0X21zGAQgAS'
    'gDUg13aW5kb3dTdGFydE1zEiIKDXdpbmRvd19lbmRfbXMYBSABKANSC3dpbmRvd0VuZE1zEhkK'
    'CGhhc19tb3JlGAYgASgIUgdoYXNNb3Jl');

@$core.Deprecated('Use adminGlobalRolesPatchDescriptor instead')
const AdminGlobalRolesPatch$json = {
  '1': 'AdminGlobalRolesPatch',
  '2': [
    {'1': 'roles', '3': 1, '4': 3, '5': 9, '10': 'roles'},
  ],
};

/// Descriptor for `AdminGlobalRolesPatch`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List adminGlobalRolesPatchDescriptor =
    $convert.base64Decode(
        'ChVBZG1pbkdsb2JhbFJvbGVzUGF0Y2gSFAoFcm9sZXMYASADKAlSBXJvbGVz');

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
    {
      '1': 'global_roles',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.c35.AdminGlobalRolesPatch',
      '9': 5,
      '10': 'globalRoles',
      '17': true
    },
  ],
  '8': [
    {'1': '_name'},
    {'1': '_avatar_url'},
    {'1': '_referred_by_uid'},
    {'1': '_handle'},
    {'1': '_auth_email'},
    {'1': '_global_roles'},
  ],
};

/// Descriptor for `ReqAdminUserPut`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqAdminUserPutDescriptor = $convert.base64Decode(
    'Cg9SZXFBZG1pblVzZXJQdXQSLAoSdGFyZ2V0X2lkZW50aXR5X2lkGAEgASgDUhB0YXJnZXRJZG'
    'VudGl0eUlkEhcKBG5hbWUYAiABKAlIAFIEbmFtZYgBARIiCgphdmF0YXJfdXJsGAMgASgJSAFS'
    'CWF2YXRhclVybIgBARIrCg9yZWZlcnJlZF9ieV91aWQYBCABKANIAlINcmVmZXJyZWRCeVVpZI'
    'gBARIbCgZoYW5kbGUYBSABKAlIA1IGaGFuZGxliAEBEiIKCmF1dGhfZW1haWwYBiABKAlIBFIJ'
    'YXV0aEVtYWlsiAEBEkIKDGdsb2JhbF9yb2xlcxgHIAEoCzIaLmMzNS5BZG1pbkdsb2JhbFJvbG'
    'VzUGF0Y2hIBVILZ2xvYmFsUm9sZXOIAQFCBwoFX25hbWVCDQoLX2F2YXRhcl91cmxCEgoQX3Jl'
    'ZmVycmVkX2J5X3VpZEIJCgdfaGFuZGxlQg0KC19hdXRoX2VtYWlsQg8KDV9nbG9iYWxfcm9sZX'
    'M=');

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

@$core.Deprecated('Use adminLlmCatalogRowDescriptor instead')
const AdminLlmCatalogRow$json = {
  '1': 'AdminLlmCatalogRow',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'provider', '3': 2, '4': 1, '5': 9, '10': 'provider'},
    {'1': 'label', '3': 3, '4': 1, '5': 9, '10': 'label'},
    {'1': 'source', '3': 4, '4': 1, '5': 9, '10': 'source'},
    {'1': 'enabled', '3': 5, '4': 1, '5': 8, '10': 'enabled'},
    {'1': 'usd_in_per_1m', '3': 6, '4': 1, '5': 1, '10': 'usdInPer1m'},
    {
      '1': 'usd_in_cache_per_1m',
      '3': 7,
      '4': 1,
      '5': 1,
      '10': 'usdInCachePer1m'
    },
    {'1': 'usd_out_per_1m', '3': 8, '4': 1, '5': 1, '10': 'usdOutPer1m'},
    {
      '1': 'retail_usd_in_per_1m',
      '3': 9,
      '4': 1,
      '5': 1,
      '10': 'retailUsdInPer1m'
    },
    {
      '1': 'retail_usd_in_cache_per_1m',
      '3': 10,
      '4': 1,
      '5': 1,
      '10': 'retailUsdInCachePer1m'
    },
    {
      '1': 'retail_usd_out_per_1m',
      '3': 11,
      '4': 1,
      '5': 1,
      '10': 'retailUsdOutPer1m'
    },
  ],
};

/// Descriptor for `AdminLlmCatalogRow`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List adminLlmCatalogRowDescriptor = $convert.base64Decode(
    'ChJBZG1pbkxsbUNhdGFsb2dSb3cSDgoCaWQYASABKAlSAmlkEhoKCHByb3ZpZGVyGAIgASgJUg'
    'hwcm92aWRlchIUCgVsYWJlbBgDIAEoCVIFbGFiZWwSFgoGc291cmNlGAQgASgJUgZzb3VyY2US'
    'GAoHZW5hYmxlZBgFIAEoCFIHZW5hYmxlZBIhCg11c2RfaW5fcGVyXzFtGAYgASgBUgp1c2RJbl'
    'BlcjFtEiwKE3VzZF9pbl9jYWNoZV9wZXJfMW0YByABKAFSD3VzZEluQ2FjaGVQZXIxbRIjCg51'
    'c2Rfb3V0X3Blcl8xbRgIIAEoAVILdXNkT3V0UGVyMW0SLgoUcmV0YWlsX3VzZF9pbl9wZXJfMW'
    '0YCSABKAFSEHJldGFpbFVzZEluUGVyMW0SOQoacmV0YWlsX3VzZF9pbl9jYWNoZV9wZXJfMW0Y'
    'CiABKAFSFXJldGFpbFVzZEluQ2FjaGVQZXIxbRIwChVyZXRhaWxfdXNkX291dF9wZXJfMW0YCy'
    'ABKAFSEXJldGFpbFVzZE91dFBlcjFt');

@$core.Deprecated('Use reqAdminLlmCatalogListDescriptor instead')
const ReqAdminLlmCatalogList$json = {
  '1': 'ReqAdminLlmCatalogList',
  '2': [
    {'1': 'enabled_only', '3': 1, '4': 1, '5': 8, '10': 'enabledOnly'},
  ],
};

/// Descriptor for `ReqAdminLlmCatalogList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqAdminLlmCatalogListDescriptor =
    $convert.base64Decode(
        'ChZSZXFBZG1pbkxsbUNhdGFsb2dMaXN0EiEKDGVuYWJsZWRfb25seRgBIAEoCFILZW5hYmxlZE'
        '9ubHk=');

@$core.Deprecated('Use adminServiceRateRowDescriptor instead')
const AdminServiceRateRow$json = {
  '1': 'AdminServiceRateRow',
  '2': [
    {'1': 'category', '3': 1, '4': 1, '5': 9, '10': 'category'},
    {'1': 'id', '3': 2, '4': 1, '5': 9, '10': 'id'},
    {'1': 'label', '3': 3, '4': 1, '5': 9, '10': 'label'},
    {'1': 'unit', '3': 4, '4': 1, '5': 9, '10': 'unit'},
    {'1': 'wholesale_usd', '3': 5, '4': 1, '5': 1, '10': 'wholesaleUsd'},
    {'1': 'retail_usd', '3': 6, '4': 1, '5': 1, '10': 'retailUsd'},
    {'1': 'detail', '3': 7, '4': 1, '5': 9, '10': 'detail'},
  ],
};

/// Descriptor for `AdminServiceRateRow`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List adminServiceRateRowDescriptor = $convert.base64Decode(
    'ChNBZG1pblNlcnZpY2VSYXRlUm93EhoKCGNhdGVnb3J5GAEgASgJUghjYXRlZ29yeRIOCgJpZB'
    'gCIAEoCVICaWQSFAoFbGFiZWwYAyABKAlSBWxhYmVsEhIKBHVuaXQYBCABKAlSBHVuaXQSIwoN'
    'd2hvbGVzYWxlX3VzZBgFIAEoAVIMd2hvbGVzYWxlVXNkEh0KCnJldGFpbF91c2QYBiABKAFSCX'
    'JldGFpbFVzZBIWCgZkZXRhaWwYByABKAlSBmRldGFpbA==');

@$core.Deprecated('Use resAdminLlmCatalogListDescriptor instead')
const ResAdminLlmCatalogList$json = {
  '1': 'ResAdminLlmCatalogList',
  '2': [
    {
      '1': 'models',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.c35.AdminLlmCatalogRow',
      '10': 'models'
    },
    {'1': 'retail_markup', '3': 2, '4': 1, '5': 1, '10': 'retailMarkup'},
    {
      '1': 'services',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.c35.AdminServiceRateRow',
      '10': 'services'
    },
    {
      '1': 'live',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.c35.AdminServiceRateRow',
      '10': 'live'
    },
  ],
};

/// Descriptor for `ResAdminLlmCatalogList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resAdminLlmCatalogListDescriptor = $convert.base64Decode(
    'ChZSZXNBZG1pbkxsbUNhdGFsb2dMaXN0Ei8KBm1vZGVscxgBIAMoCzIXLmMzNS5BZG1pbkxsbU'
    'NhdGFsb2dSb3dSBm1vZGVscxIjCg1yZXRhaWxfbWFya3VwGAIgASgBUgxyZXRhaWxNYXJrdXAS'
    'NAoIc2VydmljZXMYAyADKAsyGC5jMzUuQWRtaW5TZXJ2aWNlUmF0ZVJvd1IIc2VydmljZXMSLA'
    'oEbGl2ZRgEIAMoCzIYLmMzNS5BZG1pblNlcnZpY2VSYXRlUm93UgRsaXZl');

@$core.Deprecated('Use platformUserMetricsWindowCountsDescriptor instead')
const PlatformUserMetricsWindowCounts$json = {
  '1': 'PlatformUserMetricsWindowCounts',
  '2': [
    {'1': 'h24', '3': 1, '4': 1, '5': 3, '10': 'h24'},
    {'1': 'd7', '3': 2, '4': 1, '5': 3, '10': 'd7'},
    {'1': 'd30', '3': 3, '4': 1, '5': 3, '10': 'd30'},
    {'1': 'y1', '3': 4, '4': 1, '5': 3, '10': 'y1'},
  ],
};

/// Descriptor for `PlatformUserMetricsWindowCounts`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List platformUserMetricsWindowCountsDescriptor =
    $convert.base64Decode(
        'Ch9QbGF0Zm9ybVVzZXJNZXRyaWNzV2luZG93Q291bnRzEhAKA2gyNBgBIAEoA1IDaDI0Eg4KAm'
        'Q3GAIgASgDUgJkNxIQCgNkMzAYAyABKANSA2QzMBIOCgJ5MRgEIAEoA1ICeTE=');

@$core.Deprecated('Use reqAdminPlatformUserMetricsDescriptor instead')
const ReqAdminPlatformUserMetrics$json = {
  '1': 'ReqAdminPlatformUserMetrics',
};

/// Descriptor for `ReqAdminPlatformUserMetrics`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqAdminPlatformUserMetricsDescriptor =
    $convert.base64Decode('ChtSZXFBZG1pblBsYXRmb3JtVXNlck1ldHJpY3M=');

@$core.Deprecated('Use resAdminPlatformUserMetricsDescriptor instead')
const ResAdminPlatformUserMetrics$json = {
  '1': 'ResAdminPlatformUserMetrics',
  '2': [
    {
      '1': 'users',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.c35.PlatformUserMetricsWindowCounts',
      '10': 'users'
    },
    {
      '1': 'active_users',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.c35.PlatformUserMetricsWindowCounts',
      '10': 'activeUsers'
    },
    {
      '1': 'paid_users',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.c35.PlatformUserMetricsWindowCounts',
      '10': 'paidUsers'
    },
    {'1': 'total_users', '3': 4, '4': 1, '5': 3, '10': 'totalUsers'},
  ],
};

/// Descriptor for `ResAdminPlatformUserMetrics`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resAdminPlatformUserMetricsDescriptor = $convert.base64Decode(
    'ChtSZXNBZG1pblBsYXRmb3JtVXNlck1ldHJpY3MSOgoFdXNlcnMYASABKAsyJC5jMzUuUGxhdG'
    'Zvcm1Vc2VyTWV0cmljc1dpbmRvd0NvdW50c1IFdXNlcnMSRwoMYWN0aXZlX3VzZXJzGAIgASgL'
    'MiQuYzM1LlBsYXRmb3JtVXNlck1ldHJpY3NXaW5kb3dDb3VudHNSC2FjdGl2ZVVzZXJzEkMKCn'
    'BhaWRfdXNlcnMYAyABKAsyJC5jMzUuUGxhdGZvcm1Vc2VyTWV0cmljc1dpbmRvd0NvdW50c1IJ'
    'cGFpZFVzZXJzEh8KC3RvdGFsX3VzZXJzGAQgASgDUgp0b3RhbFVzZXJz');
