// This is a generated file - do not edit.
//
// Generated from c35/session.proto.

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

@$core.Deprecated('Use promptModelOptionDescriptor instead')
const PromptModelOption$json = {
  '1': 'PromptModelOption',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'label', '3': 2, '4': 1, '5': 9, '10': 'label'},
    {'1': 'provider', '3': 3, '4': 1, '5': 9, '10': 'provider'},
    {'1': 'is_default', '3': 4, '4': 1, '5': 8, '10': 'isDefault'},
    {'1': 'usd_in_per_1m', '3': 5, '4': 1, '5': 1, '10': 'usdInPer1m'},
    {'1': 'usd_out_per_1m', '3': 6, '4': 1, '5': 1, '10': 'usdOutPer1m'},
    {
      '1': 'supports_thinking',
      '3': 7,
      '4': 1,
      '5': 8,
      '10': 'supportsThinking'
    },
  ],
};

/// Descriptor for `PromptModelOption`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List promptModelOptionDescriptor = $convert.base64Decode(
    'ChFQcm9tcHRNb2RlbE9wdGlvbhIOCgJpZBgBIAEoCVICaWQSFAoFbGFiZWwYAiABKAlSBWxhYm'
    'VsEhoKCHByb3ZpZGVyGAMgASgJUghwcm92aWRlchIdCgppc19kZWZhdWx0GAQgASgIUglpc0Rl'
    'ZmF1bHQSIQoNdXNkX2luX3Blcl8xbRgFIAEoAVIKdXNkSW5QZXIxbRIjCg51c2Rfb3V0X3Blcl'
    '8xbRgGIAEoAVILdXNkT3V0UGVyMW0SKwoRc3VwcG9ydHNfdGhpbmtpbmcYByABKAhSEHN1cHBv'
    'cnRzVGhpbmtpbmc=');

@$core.Deprecated('Use reqSessionInitDescriptor instead')
const ReqSessionInit$json = {
  '1': 'ReqSessionInit',
  '2': [
    {'1': 'since_ms', '3': 1, '4': 1, '5': 3, '10': 'sinceMs'},
    {'1': 'locale', '3': 2, '4': 1, '5': 9, '10': 'locale'},
    {'1': 'tz', '3': 3, '4': 1, '5': 9, '10': 'tz'},
    {'1': 'dv', '3': 4, '4': 1, '5': 9, '10': 'dv'},
    {'1': 'client_id', '3': 5, '4': 1, '5': 9, '10': 'clientId'},
    {'1': 'platform', '3': 6, '4': 1, '5': 5, '10': 'platform'},
    {'1': 'include_inbox', '3': 7, '4': 1, '5': 8, '10': 'includeInbox'},
    {'1': 'include_billing', '3': 8, '4': 1, '5': 8, '10': 'includeBilling'},
    {'1': 'hints_since_ms', '3': 9, '4': 1, '5': 3, '10': 'hintsSinceMs'},
  ],
};

/// Descriptor for `ReqSessionInit`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqSessionInitDescriptor = $convert.base64Decode(
    'Cg5SZXFTZXNzaW9uSW5pdBIZCghzaW5jZV9tcxgBIAEoA1IHc2luY2VNcxIWCgZsb2NhbGUYAi'
    'ABKAlSBmxvY2FsZRIOCgJ0ehgDIAEoCVICdHoSDgoCZHYYBCABKAlSAmR2EhsKCWNsaWVudF9p'
    'ZBgFIAEoCVIIY2xpZW50SWQSGgoIcGxhdGZvcm0YBiABKAVSCHBsYXRmb3JtEiMKDWluY2x1ZG'
    'VfaW5ib3gYByABKAhSDGluY2x1ZGVJbmJveBInCg9pbmNsdWRlX2JpbGxpbmcYCCABKAhSDmlu'
    'Y2x1ZGVCaWxsaW5nEiQKDmhpbnRzX3NpbmNlX21zGAkgASgDUgxoaW50c1NpbmNlTXM=');

@$core.Deprecated('Use resSessionInitDescriptor instead')
const ResSessionInit$json = {
  '1': 'ResSessionInit',
  '2': [
    {'1': 'server_time_ms', '3': 1, '4': 1, '5': 3, '10': 'serverTimeMs'},
    {'1': 'since_ms', '3': 2, '4': 1, '5': 3, '10': 'sinceMs'},
    {'1': 'session_id', '3': 3, '4': 1, '5': 9, '10': 'sessionId'},
    {
      '1': 'profile',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.c35.IdentityProfile',
      '10': 'profile'
    },
    {
      '1': 'billing',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.c35.BillingAccount',
      '10': 'billing'
    },
    {'1': 'nav', '3': 6, '4': 1, '5': 11, '6': '.c35.NavCounts', '10': 'nav'},
    {'1': 'settings_json', '3': 7, '4': 1, '5': 9, '10': 'settingsJson'},
    {
      '1': 'inbox_chats',
      '3': 8,
      '4': 3,
      '5': 11,
      '6': '.c35.Chat',
      '10': 'inboxChats'
    },
    {
      '1': 'inbox_members',
      '3': 9,
      '4': 3,
      '5': 11,
      '6': '.c35.ChatMember',
      '10': 'inboxMembers'
    },
    {'1': 'sync', '3': 10, '4': 1, '5': 11, '6': '.c35.ResSync', '10': 'sync'},
    {
      '1': 'models',
      '3': 11,
      '4': 3,
      '5': 11,
      '6': '.c35.PromptModelOption',
      '10': 'models'
    },
    {
      '1': 'mentions',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.c35.MentionCatalog',
      '10': 'mentions'
    },
    {
      '1': 'hints',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.c35.HintCatalog',
      '10': 'hints'
    },
  ],
};

/// Descriptor for `ResSessionInit`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resSessionInitDescriptor = $convert.base64Decode(
    'Cg5SZXNTZXNzaW9uSW5pdBIkCg5zZXJ2ZXJfdGltZV9tcxgBIAEoA1IMc2VydmVyVGltZU1zEh'
    'kKCHNpbmNlX21zGAIgASgDUgdzaW5jZU1zEh0KCnNlc3Npb25faWQYAyABKAlSCXNlc3Npb25J'
    'ZBIuCgdwcm9maWxlGAQgASgLMhQuYzM1LklkZW50aXR5UHJvZmlsZVIHcHJvZmlsZRItCgdiaW'
    'xsaW5nGAUgASgLMhMuYzM1LkJpbGxpbmdBY2NvdW50UgdiaWxsaW5nEiAKA25hdhgGIAEoCzIO'
    'LmMzNS5OYXZDb3VudHNSA25hdhIjCg1zZXR0aW5nc19qc29uGAcgASgJUgxzZXR0aW5nc0pzb2'
    '4SKgoLaW5ib3hfY2hhdHMYCCADKAsyCS5jMzUuQ2hhdFIKaW5ib3hDaGF0cxI0Cg1pbmJveF9t'
    'ZW1iZXJzGAkgAygLMg8uYzM1LkNoYXRNZW1iZXJSDGluYm94TWVtYmVycxIgCgRzeW5jGAogAS'
    'gLMgwuYzM1LlJlc1N5bmNSBHN5bmMSLgoGbW9kZWxzGAsgAygLMhYuYzM1LlByb21wdE1vZGVs'
    'T3B0aW9uUgZtb2RlbHMSLwoIbWVudGlvbnMYDCABKAsyEy5jMzUuTWVudGlvbkNhdGFsb2dSCG'
    '1lbnRpb25zEiYKBWhpbnRzGA0gASgLMhAuYzM1LkhpbnRDYXRhbG9nUgVoaW50cw==');
