// This is a generated file - do not edit.
//
// Generated from c35/sync.proto.

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

@$core.Deprecated('Use syncCollectionCursorDescriptor instead')
const SyncCollectionCursor$json = {
  '1': 'SyncCollectionCursor',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'max_updated_ts_ms', '3': 2, '4': 1, '5': 3, '10': 'maxUpdatedTsMs'},
    {'1': 'caught_up', '3': 3, '4': 1, '5': 8, '10': 'caughtUp'},
  ],
};

/// Descriptor for `SyncCollectionCursor`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List syncCollectionCursorDescriptor = $convert.base64Decode(
    'ChRTeW5jQ29sbGVjdGlvbkN1cnNvchISCgRuYW1lGAEgASgJUgRuYW1lEikKEW1heF91cGRhdG'
    'VkX3RzX21zGAIgASgDUg5tYXhVcGRhdGVkVHNNcxIbCgljYXVnaHRfdXAYAyABKAhSCGNhdWdo'
    'dFVw');

@$core.Deprecated('Use reqSyncDescriptor instead')
const ReqSync$json = {
  '1': 'ReqSync',
  '2': [
    {'1': 'since_ms', '3': 1, '4': 1, '5': 3, '10': 'sinceMs'},
    {'1': 'collections', '3': 2, '4': 3, '5': 9, '10': 'collections'},
    {
      '1': 'limit_per_collection',
      '3': 3,
      '4': 1,
      '5': 5,
      '10': 'limitPerCollection'
    },
  ],
};

/// Descriptor for `ReqSync`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqSyncDescriptor = $convert.base64Decode(
    'CgdSZXFTeW5jEhkKCHNpbmNlX21zGAEgASgDUgdzaW5jZU1zEiAKC2NvbGxlY3Rpb25zGAIgAy'
    'gJUgtjb2xsZWN0aW9ucxIwChRsaW1pdF9wZXJfY29sbGVjdGlvbhgDIAEoBVISbGltaXRQZXJD'
    'b2xsZWN0aW9u');

@$core.Deprecated('Use resSyncDescriptor instead')
const ResSync$json = {
  '1': 'ResSync',
  '2': [
    {'1': 'since_ms', '3': 1, '4': 1, '5': 3, '10': 'sinceMs'},
    {'1': 'server_time_ms', '3': 2, '4': 1, '5': 3, '10': 'serverTimeMs'},
    {
      '1': 'cursors',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.c35.SyncCollectionCursor',
      '10': 'cursors'
    },
    {'1': 'chats', '3': 10, '4': 3, '5': 11, '6': '.c35.Chat', '10': 'chats'},
    {
      '1': 'chat_members',
      '3': 11,
      '4': 3,
      '5': 11,
      '6': '.c35.ChatMember',
      '10': 'chatMembers'
    },
    {
      '1': 'chat_msgs',
      '3': 12,
      '4': 3,
      '5': 11,
      '6': '.c35.ChatMsg',
      '10': 'chatMsgs'
    },
    {
      '1': 'billing_accounts',
      '3': 13,
      '4': 3,
      '5': 11,
      '6': '.c35.BillingAccount',
      '10': 'billingAccounts'
    },
    {'1': 'logs', '3': 14, '4': 3, '5': 11, '6': '.c35.Log', '10': 'logs'},
    {
      '1': 'skills',
      '3': 20,
      '4': 3,
      '5': 11,
      '6': '.c35.Skill',
      '10': 'skills'
    },
    {
      '1': 'consumptions',
      '3': 21,
      '4': 3,
      '5': 11,
      '6': '.c35.Consumption',
      '10': 'consumptions'
    },
    {
      '1': 'consumption_waters',
      '3': 22,
      '4': 3,
      '5': 11,
      '6': '.c35.ConsumptionWater',
      '10': 'consumptionWaters'
    },
    {
      '1': 'site_drafts',
      '3': 23,
      '4': 3,
      '5': 11,
      '6': '.c35.SiteDraft',
      '10': 'siteDrafts'
    },
    {
      '1': 'site_configs',
      '3': 28,
      '4': 3,
      '5': 11,
      '6': '.c35.SiteConfig',
      '10': 'siteConfigs'
    },
    {
      '1': 'site_domains',
      '3': 29,
      '4': 3,
      '5': 11,
      '6': '.c35.SiteDomain',
      '10': 'siteDomains'
    },
    {
      '1': 'site_products',
      '3': 24,
      '4': 3,
      '5': 11,
      '6': '.c35.SiteProduct',
      '10': 'siteProducts'
    },
    {
      '1': 'site_product_embeds',
      '3': 30,
      '4': 3,
      '5': 11,
      '6': '.c35.SiteProductEmbed',
      '10': 'siteProductEmbeds'
    },
    {
      '1': 'site_contacts',
      '3': 25,
      '4': 3,
      '5': 11,
      '6': '.c35.SiteContact',
      '10': 'siteContacts'
    },
    {
      '1': 'site_objects',
      '3': 26,
      '4': 3,
      '5': 11,
      '6': '.c35.SiteObject',
      '10': 'siteObjects'
    },
    {'1': 'txs', '3': 27, '4': 3, '5': 11, '6': '.c35.Tx', '10': 'txs'},
  ],
};

/// Descriptor for `ResSync`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resSyncDescriptor = $convert.base64Decode(
    'CgdSZXNTeW5jEhkKCHNpbmNlX21zGAEgASgDUgdzaW5jZU1zEiQKDnNlcnZlcl90aW1lX21zGA'
    'IgASgDUgxzZXJ2ZXJUaW1lTXMSMwoHY3Vyc29ycxgDIAMoCzIZLmMzNS5TeW5jQ29sbGVjdGlv'
    'bkN1cnNvclIHY3Vyc29ycxIfCgVjaGF0cxgKIAMoCzIJLmMzNS5DaGF0UgVjaGF0cxIyCgxjaG'
    'F0X21lbWJlcnMYCyADKAsyDy5jMzUuQ2hhdE1lbWJlclILY2hhdE1lbWJlcnMSKQoJY2hhdF9t'
    'c2dzGAwgAygLMgwuYzM1LkNoYXRNc2dSCGNoYXRNc2dzEj4KEGJpbGxpbmdfYWNjb3VudHMYDS'
    'ADKAsyEy5jMzUuQmlsbGluZ0FjY291bnRSD2JpbGxpbmdBY2NvdW50cxIcCgRsb2dzGA4gAygL'
    'MgguYzM1LkxvZ1IEbG9ncxIiCgZza2lsbHMYFCADKAsyCi5jMzUuU2tpbGxSBnNraWxscxI0Cg'
    'xjb25zdW1wdGlvbnMYFSADKAsyEC5jMzUuQ29uc3VtcHRpb25SDGNvbnN1bXB0aW9ucxJEChJj'
    'b25zdW1wdGlvbl93YXRlcnMYFiADKAsyFS5jMzUuQ29uc3VtcHRpb25XYXRlclIRY29uc3VtcH'
    'Rpb25XYXRlcnMSLwoLc2l0ZV9kcmFmdHMYFyADKAsyDi5jMzUuU2l0ZURyYWZ0UgpzaXRlRHJh'
    'ZnRzEjIKDHNpdGVfY29uZmlncxgcIAMoCzIPLmMzNS5TaXRlQ29uZmlnUgtzaXRlQ29uZmlncx'
    'IyCgxzaXRlX2RvbWFpbnMYHSADKAsyDy5jMzUuU2l0ZURvbWFpblILc2l0ZURvbWFpbnMSNQoN'
    'c2l0ZV9wcm9kdWN0cxgYIAMoCzIQLmMzNS5TaXRlUHJvZHVjdFIMc2l0ZVByb2R1Y3RzEkUKE3'
    'NpdGVfcHJvZHVjdF9lbWJlZHMYHiADKAsyFS5jMzUuU2l0ZVByb2R1Y3RFbWJlZFIRc2l0ZVBy'
    'b2R1Y3RFbWJlZHMSNQoNc2l0ZV9jb250YWN0cxgZIAMoCzIQLmMzNS5TaXRlQ29udGFjdFIMc2'
    'l0ZUNvbnRhY3RzEjIKDHNpdGVfb2JqZWN0cxgaIAMoCzIPLmMzNS5TaXRlT2JqZWN0UgtzaXRl'
    'T2JqZWN0cxIZCgN0eHMYGyADKAsyBy5jMzUuVHhSA3R4cw==');

@$core.Deprecated('Use syncPushDescriptor instead')
const SyncPush$json = {
  '1': 'SyncPush',
  '2': [
    {
      '1': 'chat',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.c35.Chat',
      '9': 0,
      '10': 'chat'
    },
    {
      '1': 'chat_member',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.c35.ChatMember',
      '9': 0,
      '10': 'chatMember'
    },
    {
      '1': 'chat_msg',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.c35.ChatMsg',
      '9': 0,
      '10': 'chatMsg'
    },
    {
      '1': 'billing_account',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.c35.BillingAccount',
      '9': 0,
      '10': 'billingAccount'
    },
    {'1': 'log', '3': 5, '4': 1, '5': 11, '6': '.c35.Log', '9': 0, '10': 'log'},
    {
      '1': 'skill',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.c35.Skill',
      '9': 0,
      '10': 'skill'
    },
    {
      '1': 'consumption',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.c35.Consumption',
      '9': 0,
      '10': 'consumption'
    },
    {
      '1': 'consumption_water',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.c35.ConsumptionWater',
      '9': 0,
      '10': 'consumptionWater'
    },
    {
      '1': 'site_draft',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.c35.SiteDraft',
      '9': 0,
      '10': 'siteDraft'
    },
    {
      '1': 'site_config',
      '3': 14,
      '4': 1,
      '5': 11,
      '6': '.c35.SiteConfig',
      '9': 0,
      '10': 'siteConfig'
    },
    {
      '1': 'site_domain',
      '3': 15,
      '4': 1,
      '5': 11,
      '6': '.c35.SiteDomain',
      '9': 0,
      '10': 'siteDomain'
    },
    {
      '1': 'site_product',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.c35.SiteProduct',
      '9': 0,
      '10': 'siteProduct'
    },
    {
      '1': 'site_product_embed',
      '3': 16,
      '4': 1,
      '5': 11,
      '6': '.c35.SiteProductEmbed',
      '9': 0,
      '10': 'siteProductEmbed'
    },
    {
      '1': 'site_contact',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.c35.SiteContact',
      '9': 0,
      '10': 'siteContact'
    },
    {
      '1': 'site_object',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.c35.SiteObject',
      '9': 0,
      '10': 'siteObject'
    },
    {'1': 'tx', '3': 13, '4': 1, '5': 11, '6': '.c35.Tx', '9': 0, '10': 'tx'},
  ],
  '8': [
    {'1': 'body'},
  ],
};

/// Descriptor for `SyncPush`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List syncPushDescriptor = $convert.base64Decode(
    'CghTeW5jUHVzaBIfCgRjaGF0GAEgASgLMgkuYzM1LkNoYXRIAFIEY2hhdBIyCgtjaGF0X21lbW'
    'JlchgCIAEoCzIPLmMzNS5DaGF0TWVtYmVySABSCmNoYXRNZW1iZXISKQoIY2hhdF9tc2cYAyAB'
    'KAsyDC5jMzUuQ2hhdE1zZ0gAUgdjaGF0TXNnEj4KD2JpbGxpbmdfYWNjb3VudBgEIAEoCzITLm'
    'MzNS5CaWxsaW5nQWNjb3VudEgAUg5iaWxsaW5nQWNjb3VudBIcCgNsb2cYBSABKAsyCC5jMzUu'
    'TG9nSABSA2xvZxIiCgVza2lsbBgGIAEoCzIKLmMzNS5Ta2lsbEgAUgVza2lsbBI0Cgtjb25zdW'
    '1wdGlvbhgHIAEoCzIQLmMzNS5Db25zdW1wdGlvbkgAUgtjb25zdW1wdGlvbhJEChFjb25zdW1w'
    'dGlvbl93YXRlchgIIAEoCzIVLmMzNS5Db25zdW1wdGlvbldhdGVySABSEGNvbnN1bXB0aW9uV2'
    'F0ZXISLwoKc2l0ZV9kcmFmdBgJIAEoCzIOLmMzNS5TaXRlRHJhZnRIAFIJc2l0ZURyYWZ0EjIK'
    'C3NpdGVfY29uZmlnGA4gASgLMg8uYzM1LlNpdGVDb25maWdIAFIKc2l0ZUNvbmZpZxIyCgtzaX'
    'RlX2RvbWFpbhgPIAEoCzIPLmMzNS5TaXRlRG9tYWluSABSCnNpdGVEb21haW4SNQoMc2l0ZV9w'
    'cm9kdWN0GAogASgLMhAuYzM1LlNpdGVQcm9kdWN0SABSC3NpdGVQcm9kdWN0EkUKEnNpdGVfcH'
    'JvZHVjdF9lbWJlZBgQIAEoCzIVLmMzNS5TaXRlUHJvZHVjdEVtYmVkSABSEHNpdGVQcm9kdWN0'
    'RW1iZWQSNQoMc2l0ZV9jb250YWN0GAsgASgLMhAuYzM1LlNpdGVDb250YWN0SABSC3NpdGVDb2'
    '50YWN0EjIKC3NpdGVfb2JqZWN0GAwgASgLMg8uYzM1LlNpdGVPYmplY3RIAFIKc2l0ZU9iamVj'
    'dBIZCgJ0eBgNIAEoCzIHLmMzNS5UeEgAUgJ0eEIGCgRib2R5');
