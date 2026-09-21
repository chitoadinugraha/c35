// This is a generated file - do not edit.
//
// Generated from c35/referral.proto.

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

@$core.Deprecated('Use referralCodeDocDescriptor instead')
const ReferralCodeDoc$json = {
  '1': 'ReferralCodeDoc',
  '2': [
    {'1': 'code', '3': 1, '4': 1, '5': 9, '10': 'code'},
    {'1': 'type', '3': 2, '4': 1, '5': 9, '10': 'type'},
    {'1': 'name', '3': 3, '4': 1, '5': 9, '10': 'name'},
    {'1': 'issued_by', '3': 4, '4': 1, '5': 3, '10': 'issuedBy'},
    {'1': 'price_usd', '3': 5, '4': 1, '5': 1, '10': 'priceUsd'},
    {'1': 'duration_months', '3': 6, '4': 1, '5': 5, '10': 'durationMonths'},
    {'1': 'base_plan_slug', '3': 7, '4': 1, '5': 9, '10': 'basePlanSlug'},
    {'1': 'max_uses', '3': 8, '4': 1, '5': 5, '10': 'maxUses'},
    {'1': 'used_count', '3': 9, '4': 1, '5': 5, '10': 'usedCount'},
    {'1': 'expires_at_ms', '3': 10, '4': 1, '5': 3, '10': 'expiresAtMs'},
  ],
};

/// Descriptor for `ReferralCodeDoc`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List referralCodeDocDescriptor = $convert.base64Decode(
    'Cg9SZWZlcnJhbENvZGVEb2MSEgoEY29kZRgBIAEoCVIEY29kZRISCgR0eXBlGAIgASgJUgR0eX'
    'BlEhIKBG5hbWUYAyABKAlSBG5hbWUSGwoJaXNzdWVkX2J5GAQgASgDUghpc3N1ZWRCeRIbCglw'
    'cmljZV91c2QYBSABKAFSCHByaWNlVXNkEicKD2R1cmF0aW9uX21vbnRocxgGIAEoBVIOZHVyYX'
    'Rpb25Nb250aHMSJAoOYmFzZV9wbGFuX3NsdWcYByABKAlSDGJhc2VQbGFuU2x1ZxIZCghtYXhf'
    'dXNlcxgIIAEoBVIHbWF4VXNlcxIdCgp1c2VkX2NvdW50GAkgASgFUgl1c2VkQ291bnQSIgoNZX'
    'hwaXJlc19hdF9tcxgKIAEoA1ILZXhwaXJlc0F0TXM=');

@$core.Deprecated('Use referralShareDocDescriptor instead')
const ReferralShareDoc$json = {
  '1': 'ReferralShareDoc',
  '2': [
    {'1': 'parent_uid', '3': 1, '4': 1, '5': 3, '10': 'parentUid'},
    {'1': 'child_uid', '3': 2, '4': 1, '5': 3, '10': 'childUid'},
    {'1': 'share_percent', '3': 3, '4': 1, '5': 5, '10': 'sharePercent'},
  ],
};

/// Descriptor for `ReferralShareDoc`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List referralShareDocDescriptor = $convert.base64Decode(
    'ChBSZWZlcnJhbFNoYXJlRG9jEh0KCnBhcmVudF91aWQYASABKANSCXBhcmVudFVpZBIbCgljaG'
    'lsZF91aWQYAiABKANSCGNoaWxkVWlkEiMKDXNoYXJlX3BlcmNlbnQYAyABKAVSDHNoYXJlUGVy'
    'Y2VudA==');

@$core.Deprecated('Use referralTreeNodeDescriptor instead')
const ReferralTreeNode$json = {
  '1': 'ReferralTreeNode',
  '2': [
    {'1': 'identity_id', '3': 1, '4': 1, '5': 3, '10': 'identityId'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'email', '3': 3, '4': 1, '5': 9, '10': 'email'},
    {'1': 'avatar_url', '3': 4, '4': 1, '5': 9, '10': 'avatarUrl'},
    {'1': 'handle', '3': 5, '4': 1, '5': 9, '10': 'handle'},
    {'1': 'referred_by', '3': 6, '4': 1, '5': 3, '10': 'referredBy'},
    {'1': 'child_count', '3': 7, '4': 1, '5': 5, '10': 'childCount'},
    {'1': 'is_root', '3': 8, '4': 1, '5': 8, '10': 'isRoot'},
    {'1': 'is_banned', '3': 9, '4': 1, '5': 8, '10': 'isBanned'},
    {'1': 'global_roles', '3': 10, '4': 3, '5': 9, '10': 'globalRoles'},
  ],
};

/// Descriptor for `ReferralTreeNode`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List referralTreeNodeDescriptor = $convert.base64Decode(
    'ChBSZWZlcnJhbFRyZWVOb2RlEh8KC2lkZW50aXR5X2lkGAEgASgDUgppZGVudGl0eUlkEhIKBG'
    '5hbWUYAiABKAlSBG5hbWUSFAoFZW1haWwYAyABKAlSBWVtYWlsEh0KCmF2YXRhcl91cmwYBCAB'
    'KAlSCWF2YXRhclVybBIWCgZoYW5kbGUYBSABKAlSBmhhbmRsZRIfCgtyZWZlcnJlZF9ieRgGIA'
    'EoA1IKcmVmZXJyZWRCeRIfCgtjaGlsZF9jb3VudBgHIAEoBVIKY2hpbGRDb3VudBIXCgdpc19y'
    'b290GAggASgIUgZpc1Jvb3QSGwoJaXNfYmFubmVkGAkgASgIUghpc0Jhbm5lZBIhCgxnbG9iYW'
    'xfcm9sZXMYCiADKAlSC2dsb2JhbFJvbGVz');

@$core.Deprecated('Use referralTreeSliceDescriptor instead')
const ReferralTreeSlice$json = {
  '1': 'ReferralTreeSlice',
  '2': [
    {
      '1': 'nodes',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.c35.ReferralTreeNode',
      '10': 'nodes'
    },
    {
      '1': 'branch_shares',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.c35.ReferralShareDoc',
      '10': 'branchShares'
    },
  ],
};

/// Descriptor for `ReferralTreeSlice`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List referralTreeSliceDescriptor = $convert.base64Decode(
    'ChFSZWZlcnJhbFRyZWVTbGljZRIrCgVub2RlcxgBIAMoCzIVLmMzNS5SZWZlcnJhbFRyZWVOb2'
    'RlUgVub2RlcxI6Cg1icmFuY2hfc2hhcmVzGAIgAygLMhUuYzM1LlJlZmVycmFsU2hhcmVEb2NS'
    'DGJyYW5jaFNoYXJlcw==');

@$core.Deprecated('Use reqReferralShareSetDescriptor instead')
const ReqReferralShareSet$json = {
  '1': 'ReqReferralShareSet',
  '2': [
    {'1': 'parent_uid', '3': 1, '4': 1, '5': 3, '10': 'parentUid'},
    {'1': 'child_uid', '3': 2, '4': 1, '5': 3, '10': 'childUid'},
    {'1': 'share_percent', '3': 3, '4': 1, '5': 5, '10': 'sharePercent'},
  ],
};

/// Descriptor for `ReqReferralShareSet`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqReferralShareSetDescriptor = $convert.base64Decode(
    'ChNSZXFSZWZlcnJhbFNoYXJlU2V0Eh0KCnBhcmVudF91aWQYASABKANSCXBhcmVudFVpZBIbCg'
    'ljaGlsZF91aWQYAiABKANSCGNoaWxkVWlkEiMKDXNoYXJlX3BlcmNlbnQYAyABKAVSDHNoYXJl'
    'UGVyY2VudA==');

@$core.Deprecated('Use resReferralShareSetDescriptor instead')
const ResReferralShareSet$json = {
  '1': 'ResReferralShareSet',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
  ],
};

/// Descriptor for `ResReferralShareSet`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resReferralShareSetDescriptor =
    $convert.base64Decode(
        'ChNSZXNSZWZlcnJhbFNoYXJlU2V0EhgKB3N1Y2Nlc3MYASABKAhSB3N1Y2Nlc3M=');

@$core.Deprecated('Use reqReferralTreeGetDescriptor instead')
const ReqReferralTreeGet$json = {
  '1': 'ReqReferralTreeGet',
  '2': [
    {'1': 'root_id', '3': 1, '4': 1, '5': 3, '10': 'rootId'},
    {'1': 'depth', '3': 2, '4': 1, '5': 5, '10': 'depth'},
  ],
};

/// Descriptor for `ReqReferralTreeGet`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqReferralTreeGetDescriptor = $convert.base64Decode(
    'ChJSZXFSZWZlcnJhbFRyZWVHZXQSFwoHcm9vdF9pZBgBIAEoA1IGcm9vdElkEhQKBWRlcHRoGA'
    'IgASgFUgVkZXB0aA==');

@$core.Deprecated('Use resReferralTreeGetDescriptor instead')
const ResReferralTreeGet$json = {
  '1': 'ResReferralTreeGet',
  '2': [
    {
      '1': 'slice',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.c35.ReferralTreeSlice',
      '10': 'slice'
    },
  ],
};

/// Descriptor for `ResReferralTreeGet`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resReferralTreeGetDescriptor = $convert.base64Decode(
    'ChJSZXNSZWZlcnJhbFRyZWVHZXQSLAoFc2xpY2UYASABKAsyFi5jMzUuUmVmZXJyYWxUcmVlU2'
    'xpY2VSBXNsaWNl');

@$core.Deprecated('Use reqReferralCodeListDescriptor instead')
const ReqReferralCodeList$json = {
  '1': 'ReqReferralCodeList',
};

/// Descriptor for `ReqReferralCodeList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqReferralCodeListDescriptor =
    $convert.base64Decode('ChNSZXFSZWZlcnJhbENvZGVMaXN0');

@$core.Deprecated('Use resReferralCodeListDescriptor instead')
const ResReferralCodeList$json = {
  '1': 'ResReferralCodeList',
  '2': [
    {
      '1': 'items',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.c35.ReferralCodeDoc',
      '10': 'items'
    },
  ],
};

/// Descriptor for `ResReferralCodeList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resReferralCodeListDescriptor = $convert.base64Decode(
    'ChNSZXNSZWZlcnJhbENvZGVMaXN0EioKBWl0ZW1zGAEgAygLMhQuYzM1LlJlZmVycmFsQ29kZU'
    'RvY1IFaXRlbXM=');

@$core.Deprecated('Use reqReferralCodePutDescriptor instead')
const ReqReferralCodePut$json = {
  '1': 'ReqReferralCodePut',
  '2': [
    {
      '1': 'code',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.c35.ReferralCodeDoc',
      '10': 'code'
    },
  ],
};

/// Descriptor for `ReqReferralCodePut`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqReferralCodePutDescriptor = $convert.base64Decode(
    'ChJSZXFSZWZlcnJhbENvZGVQdXQSKAoEY29kZRgBIAEoCzIULmMzNS5SZWZlcnJhbENvZGVEb2'
    'NSBGNvZGU=');

@$core.Deprecated('Use reqReferralCodeDeleteDescriptor instead')
const ReqReferralCodeDelete$json = {
  '1': 'ReqReferralCodeDelete',
  '2': [
    {'1': 'code', '3': 1, '4': 1, '5': 9, '10': 'code'},
  ],
};

/// Descriptor for `ReqReferralCodeDelete`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqReferralCodeDeleteDescriptor =
    $convert.base64Decode(
        'ChVSZXFSZWZlcnJhbENvZGVEZWxldGUSEgoEY29kZRgBIAEoCVIEY29kZQ==');

@$core.Deprecated('Use referralStatPeriodDescriptor instead')
const ReferralStatPeriod$json = {
  '1': 'ReferralStatPeriod',
  '2': [
    {'1': 'from_ms', '3': 1, '4': 1, '5': 3, '10': 'fromMs'},
    {'1': 'to_ms', '3': 2, '4': 1, '5': 3, '10': 'toMs'},
  ],
};

/// Descriptor for `ReferralStatPeriod`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List referralStatPeriodDescriptor = $convert.base64Decode(
    'ChJSZWZlcnJhbFN0YXRQZXJpb2QSFwoHZnJvbV9tcxgBIAEoA1IGZnJvbU1zEhMKBXRvX21zGA'
    'IgASgDUgR0b01z');

@$core.Deprecated('Use referralUserStatColumnDescriptor instead')
const ReferralUserStatColumn$json = {
  '1': 'ReferralUserStatColumn',
  '2': [
    {'1': 'referral_count', '3': 1, '4': 1, '5': 5, '10': 'referralCount'},
    {'1': 'commission_idr', '3': 2, '4': 1, '5': 1, '10': 'commissionIdr'},
    {'1': 'commission_usd', '3': 3, '4': 1, '5': 1, '10': 'commissionUsd'},
    {'1': 'tokens_alien', '3': 4, '4': 1, '5': 3, '10': 'tokensAlien'},
    {'1': 'tokens_api', '3': 5, '4': 1, '5': 3, '10': 'tokensApi'},
  ],
};

/// Descriptor for `ReferralUserStatColumn`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List referralUserStatColumnDescriptor = $convert.base64Decode(
    'ChZSZWZlcnJhbFVzZXJTdGF0Q29sdW1uEiUKDnJlZmVycmFsX2NvdW50GAEgASgFUg1yZWZlcn'
    'JhbENvdW50EiUKDmNvbW1pc3Npb25faWRyGAIgASgBUg1jb21taXNzaW9uSWRyEiUKDmNvbW1p'
    'c3Npb25fdXNkGAMgASgBUg1jb21taXNzaW9uVXNkEiEKDHRva2Vuc19hbGllbhgEIAEoA1ILdG'
    '9rZW5zQWxpZW4SHQoKdG9rZW5zX2FwaRgFIAEoA1IJdG9rZW5zQXBp');

@$core.Deprecated('Use reqReferralUserStatsDescriptor instead')
const ReqReferralUserStats$json = {
  '1': 'ReqReferralUserStats',
  '2': [
    {'1': 'subject_uid', '3': 1, '4': 1, '5': 3, '10': 'subjectUid'},
    {
      '1': 'col_a',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.c35.ReferralStatPeriod',
      '10': 'colA'
    },
    {
      '1': 'col_b',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.c35.ReferralStatPeriod',
      '10': 'colB'
    },
  ],
};

/// Descriptor for `ReqReferralUserStats`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqReferralUserStatsDescriptor = $convert.base64Decode(
    'ChRSZXFSZWZlcnJhbFVzZXJTdGF0cxIfCgtzdWJqZWN0X3VpZBgBIAEoA1IKc3ViamVjdFVpZB'
    'IsCgVjb2xfYRgCIAEoCzIXLmMzNS5SZWZlcnJhbFN0YXRQZXJpb2RSBGNvbEESLAoFY29sX2IY'
    'AyABKAsyFy5jMzUuUmVmZXJyYWxTdGF0UGVyaW9kUgRjb2xC');

@$core.Deprecated('Use resReferralUserStatsDescriptor instead')
const ResReferralUserStats$json = {
  '1': 'ResReferralUserStats',
  '2': [
    {
      '1': 'col_a',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.c35.ReferralUserStatColumn',
      '10': 'colA'
    },
    {
      '1': 'col_b',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.c35.ReferralUserStatColumn',
      '10': 'colB'
    },
  ],
};

/// Descriptor for `ResReferralUserStats`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resReferralUserStatsDescriptor = $convert.base64Decode(
    'ChRSZXNSZWZlcnJhbFVzZXJTdGF0cxIwCgVjb2xfYRgBIAEoCzIbLmMzNS5SZWZlcnJhbFVzZX'
    'JTdGF0Q29sdW1uUgRjb2xBEjAKBWNvbF9iGAIgASgLMhsuYzM1LlJlZmVycmFsVXNlclN0YXRD'
    'b2x1bW5SBGNvbEI=');

@$core.Deprecated('Use referralCommissionLevelDescriptor instead')
const ReferralCommissionLevel$json = {
  '1': 'ReferralCommissionLevel',
  '2': [
    {'1': 'identity_id', '3': 1, '4': 1, '5': 3, '10': 'identityId'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'avatar_url', '3': 3, '4': 1, '5': 9, '10': 'avatarUrl'},
    {'1': 'percent', '3': 4, '4': 1, '5': 5, '10': 'percent'},
    {'1': 'earn_amount', '3': 5, '4': 1, '5': 3, '10': 'earnAmount'},
    {
      '1': 'pool_share_percent',
      '3': 6,
      '4': 1,
      '5': 1,
      '10': 'poolSharePercent'
    },
  ],
};

/// Descriptor for `ReferralCommissionLevel`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List referralCommissionLevelDescriptor = $convert.base64Decode(
    'ChdSZWZlcnJhbENvbW1pc3Npb25MZXZlbBIfCgtpZGVudGl0eV9pZBgBIAEoA1IKaWRlbnRpdH'
    'lJZBISCgRuYW1lGAIgASgJUgRuYW1lEh0KCmF2YXRhcl91cmwYAyABKAlSCWF2YXRhclVybBIY'
    'CgdwZXJjZW50GAQgASgFUgdwZXJjZW50Eh8KC2Vhcm5fYW1vdW50GAUgASgDUgplYXJuQW1vdW'
    '50EiwKEnBvb2xfc2hhcmVfcGVyY2VudBgGIAEoAVIQcG9vbFNoYXJlUGVyY2VudA==');

@$core.Deprecated('Use reqReferralCommissionSimulateDescriptor instead')
const ReqReferralCommissionSimulate$json = {
  '1': 'ReqReferralCommissionSimulate',
  '2': [
    {'1': 'subject_uid', '3': 1, '4': 1, '5': 3, '10': 'subjectUid'},
    {'1': 'purchase_amount', '3': 2, '4': 1, '5': 3, '10': 'purchaseAmount'},
  ],
};

/// Descriptor for `ReqReferralCommissionSimulate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqReferralCommissionSimulateDescriptor =
    $convert.base64Decode(
        'Ch1SZXFSZWZlcnJhbENvbW1pc3Npb25TaW11bGF0ZRIfCgtzdWJqZWN0X3VpZBgBIAEoA1IKc3'
        'ViamVjdFVpZBInCg9wdXJjaGFzZV9hbW91bnQYAiABKANSDnB1cmNoYXNlQW1vdW50');

@$core.Deprecated('Use resReferralCommissionSimulateDescriptor instead')
const ResReferralCommissionSimulate$json = {
  '1': 'ResReferralCommissionSimulate',
  '2': [
    {'1': 'purchase_amount', '3': 1, '4': 1, '5': 3, '10': 'purchaseAmount'},
    {'1': 'pool_amount', '3': 2, '4': 1, '5': 3, '10': 'poolAmount'},
    {'1': 'pool_rate', '3': 3, '4': 1, '5': 1, '10': 'poolRate'},
    {
      '1': 'levels',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.c35.ReferralCommissionLevel',
      '10': 'levels'
    },
    {
      '1': 'total_distributed',
      '3': 5,
      '4': 1,
      '5': 3,
      '10': 'totalDistributed'
    },
    {'1': 'undistributed', '3': 6, '4': 1, '5': 3, '10': 'undistributed'},
  ],
};

/// Descriptor for `ResReferralCommissionSimulate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resReferralCommissionSimulateDescriptor = $convert.base64Decode(
    'Ch1SZXNSZWZlcnJhbENvbW1pc3Npb25TaW11bGF0ZRInCg9wdXJjaGFzZV9hbW91bnQYASABKA'
    'NSDnB1cmNoYXNlQW1vdW50Eh8KC3Bvb2xfYW1vdW50GAIgASgDUgpwb29sQW1vdW50EhsKCXBv'
    'b2xfcmF0ZRgDIAEoAVIIcG9vbFJhdGUSNAoGbGV2ZWxzGAQgAygLMhwuYzM1LlJlZmVycmFsQ2'
    '9tbWlzc2lvbkxldmVsUgZsZXZlbHMSKwoRdG90YWxfZGlzdHJpYnV0ZWQYBSABKANSEHRvdGFs'
    'RGlzdHJpYnV0ZWQSJAoNdW5kaXN0cmlidXRlZBgGIAEoA1INdW5kaXN0cmlidXRlZA==');
