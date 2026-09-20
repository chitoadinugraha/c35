//
//  Generated code. Do not modify.
//  source: c35/session.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

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
  ],
};

/// Descriptor for `ReqSessionInit`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqSessionInitDescriptor = $convert.base64Decode(
    'Cg5SZXFTZXNzaW9uSW5pdBIZCghzaW5jZV9tcxgBIAEoA1IHc2luY2VNcxIWCgZsb2NhbGUYAi'
    'ABKAlSBmxvY2FsZRIOCgJ0ehgDIAEoCVICdHoSDgoCZHYYBCABKAlSAmR2EhsKCWNsaWVudF9p'
    'ZBgFIAEoCVIIY2xpZW50SWQSGgoIcGxhdGZvcm0YBiABKAVSCHBsYXRmb3JtEiMKDWluY2x1ZG'
    'VfaW5ib3gYByABKAhSDGluY2x1ZGVJbmJveBInCg9pbmNsdWRlX2JpbGxpbmcYCCABKAhSDmlu'
    'Y2x1ZGVCaWxsaW5n');

@$core.Deprecated('Use resSessionInitDescriptor instead')
const ResSessionInit$json = {
  '1': 'ResSessionInit',
  '2': [
    {'1': 'server_time_ms', '3': 1, '4': 1, '5': 3, '10': 'serverTimeMs'},
    {'1': 'since_ms', '3': 2, '4': 1, '5': 3, '10': 'sinceMs'},
    {'1': 'session_id', '3': 3, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'profile', '3': 4, '4': 1, '5': 11, '6': '.c35.IdentityProfile', '10': 'profile'},
    {'1': 'billing', '3': 5, '4': 1, '5': 11, '6': '.c35.BillingAccount', '10': 'billing'},
    {'1': 'nav', '3': 6, '4': 1, '5': 11, '6': '.c35.NavCounts', '10': 'nav'},
    {'1': 'settings_json', '3': 7, '4': 1, '5': 9, '10': 'settingsJson'},
    {'1': 'inbox_chats', '3': 8, '4': 3, '5': 11, '6': '.c35.Chat', '10': 'inboxChats'},
    {'1': 'inbox_members', '3': 9, '4': 3, '5': 11, '6': '.c35.ChatMember', '10': 'inboxMembers'},
    {'1': 'sync', '3': 10, '4': 1, '5': 11, '6': '.c35.ResSync', '10': 'sync'},
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
    'gLMgwuYzM1LlJlc1N5bmNSBHN5bmM=');

