// This is a generated file - do not edit.
//
// Generated from c35/site.proto.

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

@$core.Deprecated('Use siteBootModeDescriptor instead')
const SiteBootMode$json = {
  '1': 'SiteBootMode',
  '2': [
    {'1': 'SITE_BOOT_MODE_UNSPECIFIED', '2': 0},
    {'1': 'SITE_BOOT_MODE_DRAFT', '2': 1},
    {'1': 'SITE_BOOT_MODE_PUBLISHED', '2': 2},
  ],
};

/// Descriptor for `SiteBootMode`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List siteBootModeDescriptor = $convert.base64Decode(
    'CgxTaXRlQm9vdE1vZGUSHgoaU0lURV9CT09UX01PREVfVU5TUEVDSUZJRUQQABIYChRTSVRFX0'
    'JPT1RfTU9ERV9EUkFGVBABEhwKGFNJVEVfQk9PVF9NT0RFX1BVQkxJU0hFRBAC');

@$core.Deprecated('Use siteBlockDescriptor instead')
const SiteBlock$json = {
  '1': 'SiteBlock',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'type', '3': 2, '4': 1, '5': 9, '10': 'type'},
    {'1': 'props_json', '3': 3, '4': 1, '5': 9, '10': 'propsJson'},
  ],
};

/// Descriptor for `SiteBlock`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List siteBlockDescriptor = $convert.base64Decode(
    'CglTaXRlQmxvY2sSDgoCaWQYASABKAlSAmlkEhIKBHR5cGUYAiABKAlSBHR5cGUSHQoKcHJvcH'
    'NfanNvbhgDIAEoCVIJcHJvcHNKc29u');

@$core.Deprecated('Use sitePageDescriptor instead')
const SitePage$json = {
  '1': 'SitePage',
  '2': [
    {'1': 'path', '3': 1, '4': 1, '5': 9, '10': 'path'},
    {'1': 'title', '3': 2, '4': 1, '5': 9, '10': 'title'},
    {
      '1': 'blocks',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.c35.SiteBlock',
      '10': 'blocks'
    },
  ],
};

/// Descriptor for `SitePage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sitePageDescriptor = $convert.base64Decode(
    'CghTaXRlUGFnZRISCgRwYXRoGAEgASgJUgRwYXRoEhQKBXRpdGxlGAIgASgJUgV0aXRsZRImCg'
    'ZibG9ja3MYAyADKAsyDi5jMzUuU2l0ZUJsb2NrUgZibG9ja3M=');

@$core.Deprecated('Use siteDocDescriptor instead')
const SiteDoc$json = {
  '1': 'SiteDoc',
  '2': [
    {
      '1': 'pages',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.c35.SitePage',
      '10': 'pages'
    },
    {'1': 'theme_json', '3': 2, '4': 1, '5': 9, '10': 'themeJson'},
    {'1': 'meta_json', '3': 3, '4': 1, '5': 9, '10': 'metaJson'},
  ],
};

/// Descriptor for `SiteDoc`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List siteDocDescriptor = $convert.base64Decode(
    'CgdTaXRlRG9jEiMKBXBhZ2VzGAEgAygLMg0uYzM1LlNpdGVQYWdlUgVwYWdlcxIdCgp0aGVtZV'
    '9qc29uGAIgASgJUgl0aGVtZUpzb24SGwoJbWV0YV9qc29uGAMgASgJUghtZXRhSnNvbg==');

@$core.Deprecated('Use siteConfigDescriptor instead')
const SiteConfig$json = {
  '1': 'SiteConfig',
  '2': [
    {'1': 'site_iid', '3': 1, '4': 1, '5': 3, '10': 'siteIid'},
    {'1': 'owner_iid', '3': 2, '4': 1, '5': 3, '10': 'ownerIid'},
    {
      '1': 'published_version_id',
      '3': 3,
      '4': 1,
      '5': 9,
      '10': 'publishedVersionId'
    },
    {
      '1': 'inventory_costing_method',
      '3': 4,
      '4': 1,
      '5': 9,
      '10': 'inventoryCostingMethod'
    },
    {'1': 'tz', '3': 5, '4': 1, '5': 9, '10': 'tz'},
    {
      '1': 'payroll_policy_json',
      '3': 6,
      '4': 1,
      '5': 9,
      '10': 'payrollPolicyJson'
    },
    {
      '1': 'presence_policy_json',
      '3': 7,
      '4': 1,
      '5': 9,
      '10': 'presencePolicyJson'
    },
    {
      '1': 'capabilities_json',
      '3': 8,
      '4': 1,
      '5': 9,
      '10': 'capabilitiesJson'
    },
    {
      '1': 'alien_id_changed_ts_ms',
      '3': 9,
      '4': 1,
      '5': 3,
      '10': 'alienIdChangedTsMs'
    },
    {'1': 'created_ts_ms', '3': 20, '4': 1, '5': 3, '10': 'createdTsMs'},
    {'1': 'updated_ts_ms', '3': 21, '4': 1, '5': 3, '10': 'updatedTsMs'},
    {'1': 'deleted_ts_ms', '3': 22, '4': 1, '5': 3, '10': 'deletedTsMs'},
  ],
};

/// Descriptor for `SiteConfig`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List siteConfigDescriptor = $convert.base64Decode(
    'CgpTaXRlQ29uZmlnEhkKCHNpdGVfaWlkGAEgASgDUgdzaXRlSWlkEhsKCW93bmVyX2lpZBgCIA'
    'EoA1IIb3duZXJJaWQSMAoUcHVibGlzaGVkX3ZlcnNpb25faWQYAyABKAlSEnB1Ymxpc2hlZFZl'
    'cnNpb25JZBI4ChhpbnZlbnRvcnlfY29zdGluZ19tZXRob2QYBCABKAlSFmludmVudG9yeUNvc3'
    'RpbmdNZXRob2QSDgoCdHoYBSABKAlSAnR6Ei4KE3BheXJvbGxfcG9saWN5X2pzb24YBiABKAlS'
    'EXBheXJvbGxQb2xpY3lKc29uEjAKFHByZXNlbmNlX3BvbGljeV9qc29uGAcgASgJUhJwcmVzZW'
    '5jZVBvbGljeUpzb24SKwoRY2FwYWJpbGl0aWVzX2pzb24YCCABKAlSEGNhcGFiaWxpdGllc0pz'
    'b24SMgoWYWxpZW5faWRfY2hhbmdlZF90c19tcxgJIAEoA1ISYWxpZW5JZENoYW5nZWRUc01zEi'
    'IKDWNyZWF0ZWRfdHNfbXMYFCABKANSC2NyZWF0ZWRUc01zEiIKDXVwZGF0ZWRfdHNfbXMYFSAB'
    'KANSC3VwZGF0ZWRUc01zEiIKDWRlbGV0ZWRfdHNfbXMYFiABKANSC2RlbGV0ZWRUc01z');

@$core.Deprecated('Use siteDomainDescriptor instead')
const SiteDomain$json = {
  '1': 'SiteDomain',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 3, '10': 'id'},
    {'1': 'site_iid', '3': 2, '4': 1, '5': 3, '10': 'siteIid'},
    {'1': 'hostname', '3': 3, '4': 1, '5': 9, '10': 'hostname'},
    {'1': 'is_primary', '3': 4, '4': 1, '5': 8, '10': 'isPrimary'},
    {'1': 'tls_status', '3': 5, '4': 1, '5': 9, '10': 'tlsStatus'},
    {'1': 'verified_ts_ms', '3': 6, '4': 1, '5': 3, '10': 'verifiedTsMs'},
    {'1': 'verify_token', '3': 7, '4': 1, '5': 9, '10': 'verifyToken'},
    {'1': 'verify_error', '3': 8, '4': 1, '5': 9, '10': 'verifyError'},
    {'1': 'tls_error', '3': 9, '4': 1, '5': 9, '10': 'tlsError'},
    {'1': 'last_verify_ts_ms', '3': 10, '4': 1, '5': 3, '10': 'lastVerifyTsMs'},
    {'1': 'created_ts_ms', '3': 20, '4': 1, '5': 3, '10': 'createdTsMs'},
    {'1': 'updated_ts_ms', '3': 21, '4': 1, '5': 3, '10': 'updatedTsMs'},
    {'1': 'deleted_ts_ms', '3': 22, '4': 1, '5': 3, '10': 'deletedTsMs'},
  ],
};

/// Descriptor for `SiteDomain`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List siteDomainDescriptor = $convert.base64Decode(
    'CgpTaXRlRG9tYWluEg4KAmlkGAEgASgDUgJpZBIZCghzaXRlX2lpZBgCIAEoA1IHc2l0ZUlpZB'
    'IaCghob3N0bmFtZRgDIAEoCVIIaG9zdG5hbWUSHQoKaXNfcHJpbWFyeRgEIAEoCFIJaXNQcmlt'
    'YXJ5Eh0KCnRsc19zdGF0dXMYBSABKAlSCXRsc1N0YXR1cxIkCg52ZXJpZmllZF90c19tcxgGIA'
    'EoA1IMdmVyaWZpZWRUc01zEiEKDHZlcmlmeV90b2tlbhgHIAEoCVILdmVyaWZ5VG9rZW4SIQoM'
    'dmVyaWZ5X2Vycm9yGAggASgJUgt2ZXJpZnlFcnJvchIbCgl0bHNfZXJyb3IYCSABKAlSCHRsc0'
    'Vycm9yEikKEWxhc3RfdmVyaWZ5X3RzX21zGAogASgDUg5sYXN0VmVyaWZ5VHNNcxIiCg1jcmVh'
    'dGVkX3RzX21zGBQgASgDUgtjcmVhdGVkVHNNcxIiCg11cGRhdGVkX3RzX21zGBUgASgDUgt1cG'
    'RhdGVkVHNNcxIiCg1kZWxldGVkX3RzX21zGBYgASgDUgtkZWxldGVkVHNNcw==');

@$core.Deprecated('Use siteDraftDescriptor instead')
const SiteDraft$json = {
  '1': 'SiteDraft',
  '2': [
    {'1': 'site_iid', '3': 1, '4': 1, '5': 3, '10': 'siteIid'},
    {'1': 'owner_iid', '3': 2, '4': 1, '5': 3, '10': 'ownerIid'},
    {'1': 'doc', '3': 3, '4': 1, '5': 11, '6': '.c35.SiteDoc', '10': 'doc'},
    {'1': 'created_ts_ms', '3': 20, '4': 1, '5': 3, '10': 'createdTsMs'},
    {'1': 'updated_ts_ms', '3': 21, '4': 1, '5': 3, '10': 'updatedTsMs'},
    {'1': 'deleted_ts_ms', '3': 22, '4': 1, '5': 3, '10': 'deletedTsMs'},
  ],
};

/// Descriptor for `SiteDraft`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List siteDraftDescriptor = $convert.base64Decode(
    'CglTaXRlRHJhZnQSGQoIc2l0ZV9paWQYASABKANSB3NpdGVJaWQSGwoJb3duZXJfaWlkGAIgAS'
    'gDUghvd25lcklpZBIeCgNkb2MYAyABKAsyDC5jMzUuU2l0ZURvY1IDZG9jEiIKDWNyZWF0ZWRf'
    'dHNfbXMYFCABKANSC2NyZWF0ZWRUc01zEiIKDXVwZGF0ZWRfdHNfbXMYFSABKANSC3VwZGF0ZW'
    'RUc01zEiIKDWRlbGV0ZWRfdHNfbXMYFiABKANSC2RlbGV0ZWRUc01z');

@$core.Deprecated('Use sitePublishDescriptor instead')
const SitePublish$json = {
  '1': 'SitePublish',
  '2': [
    {'1': 'site_iid', '3': 1, '4': 1, '5': 3, '10': 'siteIid'},
    {'1': 'version_id', '3': 2, '4': 1, '5': 9, '10': 'versionId'},
    {'1': 'doc', '3': 3, '4': 1, '5': 11, '6': '.c35.SiteDoc', '10': 'doc'},
    {'1': 'render_hash', '3': 4, '4': 1, '5': 9, '10': 'renderHash'},
    {'1': 'published_ts_ms', '3': 5, '4': 1, '5': 3, '10': 'publishedTsMs'},
    {'1': 'is_active', '3': 6, '4': 1, '5': 8, '10': 'isActive'},
    {'1': 'created_ts_ms', '3': 20, '4': 1, '5': 3, '10': 'createdTsMs'},
    {'1': 'updated_ts_ms', '3': 21, '4': 1, '5': 3, '10': 'updatedTsMs'},
    {'1': 'deleted_ts_ms', '3': 22, '4': 1, '5': 3, '10': 'deletedTsMs'},
  ],
};

/// Descriptor for `SitePublish`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sitePublishDescriptor = $convert.base64Decode(
    'CgtTaXRlUHVibGlzaBIZCghzaXRlX2lpZBgBIAEoA1IHc2l0ZUlpZBIdCgp2ZXJzaW9uX2lkGA'
    'IgASgJUgl2ZXJzaW9uSWQSHgoDZG9jGAMgASgLMgwuYzM1LlNpdGVEb2NSA2RvYxIfCgtyZW5k'
    'ZXJfaGFzaBgEIAEoCVIKcmVuZGVySGFzaBImCg9wdWJsaXNoZWRfdHNfbXMYBSABKANSDXB1Ym'
    'xpc2hlZFRzTXMSGwoJaXNfYWN0aXZlGAYgASgIUghpc0FjdGl2ZRIiCg1jcmVhdGVkX3RzX21z'
    'GBQgASgDUgtjcmVhdGVkVHNNcxIiCg11cGRhdGVkX3RzX21zGBUgASgDUgt1cGRhdGVkVHNNcx'
    'IiCg1kZWxldGVkX3RzX21zGBYgASgDUgtkZWxldGVkVHNNcw==');

@$core.Deprecated('Use siteProductDescriptor instead')
const SiteProduct$json = {
  '1': 'SiteProduct',
  '2': [
    {'1': 'site_iid', '3': 1, '4': 1, '5': 3, '10': 'siteIid'},
    {'1': 'product_id', '3': 2, '4': 1, '5': 3, '10': 'productId'},
    {'1': 'type', '3': 3, '4': 1, '5': 5, '10': 'type'},
    {'1': 'name', '3': 4, '4': 1, '5': 9, '10': 'name'},
    {'1': 'desc', '3': 5, '4': 1, '5': 9, '10': 'desc'},
    {'1': 'unit', '3': 6, '4': 1, '5': 9, '10': 'unit'},
    {'1': 'sku', '3': 7, '4': 1, '5': 9, '10': 'sku'},
    {'1': 'rev', '3': 8, '4': 1, '5': 3, '10': 'rev'},
    {'1': 'can_sell', '3': 9, '4': 1, '5': 8, '10': 'canSell'},
    {'1': 'can_reserve', '3': 10, '4': 1, '5': 8, '10': 'canReserve'},
    {'1': 'track_stock', '3': 11, '4': 1, '5': 8, '10': 'trackStock'},
    {'1': 'stock_qty', '3': 12, '4': 1, '5': 5, '10': 'stockQty'},
    {'1': 'price', '3': 13, '4': 1, '5': 3, '10': 'price'},
    {'1': 'pic', '3': 14, '4': 1, '5': 9, '10': 'pic'},
    {'1': 'category', '3': 15, '4': 1, '5': 9, '10': 'category'},
    {'1': 'product_json', '3': 16, '4': 1, '5': 9, '10': 'productJson'},
    {'1': 'is_archived', '3': 17, '4': 1, '5': 8, '10': 'isArchived'},
    {'1': 'sort_order', '3': 19, '4': 1, '5': 5, '10': 'sortOrder'},
    {'1': 'created_ts_ms', '3': 20, '4': 1, '5': 3, '10': 'createdTsMs'},
    {'1': 'updated_ts_ms', '3': 21, '4': 1, '5': 3, '10': 'updatedTsMs'},
    {'1': 'deleted_ts_ms', '3': 22, '4': 1, '5': 3, '10': 'deletedTsMs'},
  ],
};

/// Descriptor for `SiteProduct`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List siteProductDescriptor = $convert.base64Decode(
    'CgtTaXRlUHJvZHVjdBIZCghzaXRlX2lpZBgBIAEoA1IHc2l0ZUlpZBIdCgpwcm9kdWN0X2lkGA'
    'IgASgDUglwcm9kdWN0SWQSEgoEdHlwZRgDIAEoBVIEdHlwZRISCgRuYW1lGAQgASgJUgRuYW1l'
    'EhIKBGRlc2MYBSABKAlSBGRlc2MSEgoEdW5pdBgGIAEoCVIEdW5pdBIQCgNza3UYByABKAlSA3'
    'NrdRIQCgNyZXYYCCABKANSA3JldhIZCghjYW5fc2VsbBgJIAEoCFIHY2FuU2VsbBIfCgtjYW5f'
    'cmVzZXJ2ZRgKIAEoCFIKY2FuUmVzZXJ2ZRIfCgt0cmFja19zdG9jaxgLIAEoCFIKdHJhY2tTdG'
    '9jaxIbCglzdG9ja19xdHkYDCABKAVSCHN0b2NrUXR5EhQKBXByaWNlGA0gASgDUgVwcmljZRIQ'
    'CgNwaWMYDiABKAlSA3BpYxIaCghjYXRlZ29yeRgPIAEoCVIIY2F0ZWdvcnkSIQoMcHJvZHVjdF'
    '9qc29uGBAgASgJUgtwcm9kdWN0SnNvbhIfCgtpc19hcmNoaXZlZBgRIAEoCFIKaXNBcmNoaXZl'
    'ZBIdCgpzb3J0X29yZGVyGBMgASgFUglzb3J0T3JkZXISIgoNY3JlYXRlZF90c19tcxgUIAEoA1'
    'ILY3JlYXRlZFRzTXMSIgoNdXBkYXRlZF90c19tcxgVIAEoA1ILdXBkYXRlZFRzTXMSIgoNZGVs'
    'ZXRlZF90c19tcxgWIAEoA1ILZGVsZXRlZFRzTXM=');

@$core.Deprecated('Use siteProductEmbedDescriptor instead')
const SiteProductEmbed$json = {
  '1': 'SiteProductEmbed',
  '2': [
    {'1': 'site_iid', '3': 1, '4': 1, '5': 3, '10': 'siteIid'},
    {'1': 'embed_id', '3': 2, '4': 1, '5': 3, '10': 'embedId'},
    {'1': 'product_id', '3': 3, '4': 1, '5': 3, '10': 'productId'},
    {'1': 'label', '3': 4, '4': 1, '5': 9, '10': 'label'},
    {'1': 'created_ts_ms', '3': 20, '4': 1, '5': 3, '10': 'createdTsMs'},
    {'1': 'updated_ts_ms', '3': 21, '4': 1, '5': 3, '10': 'updatedTsMs'},
    {'1': 'deleted_ts_ms', '3': 22, '4': 1, '5': 3, '10': 'deletedTsMs'},
  ],
};

/// Descriptor for `SiteProductEmbed`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List siteProductEmbedDescriptor = $convert.base64Decode(
    'ChBTaXRlUHJvZHVjdEVtYmVkEhkKCHNpdGVfaWlkGAEgASgDUgdzaXRlSWlkEhkKCGVtYmVkX2'
    'lkGAIgASgDUgdlbWJlZElkEh0KCnByb2R1Y3RfaWQYAyABKANSCXByb2R1Y3RJZBIUCgVsYWJl'
    'bBgEIAEoCVIFbGFiZWwSIgoNY3JlYXRlZF90c19tcxgUIAEoA1ILY3JlYXRlZFRzTXMSIgoNdX'
    'BkYXRlZF90c19tcxgVIAEoA1ILdXBkYXRlZFRzTXMSIgoNZGVsZXRlZF90c19tcxgWIAEoA1IL'
    'ZGVsZXRlZFRzTXM=');

@$core.Deprecated('Use siteContactDescriptor instead')
const SiteContact$json = {
  '1': 'SiteContact',
  '2': [
    {'1': 'site_iid', '3': 1, '4': 1, '5': 3, '10': 'siteIid'},
    {'1': 'contact_id', '3': 2, '4': 1, '5': 3, '10': 'contactId'},
    {'1': 'name', '3': 3, '4': 1, '5': 9, '10': 'name'},
    {'1': 'phone', '3': 4, '4': 1, '5': 9, '10': 'phone'},
    {'1': 'email', '3': 5, '4': 1, '5': 9, '10': 'email'},
    {'1': 'address', '3': 6, '4': 1, '5': 9, '10': 'address'},
    {'1': 'note', '3': 7, '4': 1, '5': 9, '10': 'note'},
    {'1': 'meta_json', '3': 8, '4': 1, '5': 9, '10': 'metaJson'},
    {'1': 'is_archived', '3': 9, '4': 1, '5': 8, '10': 'isArchived'},
    {'1': 'created_ts_ms', '3': 20, '4': 1, '5': 3, '10': 'createdTsMs'},
    {'1': 'updated_ts_ms', '3': 21, '4': 1, '5': 3, '10': 'updatedTsMs'},
    {'1': 'deleted_ts_ms', '3': 22, '4': 1, '5': 3, '10': 'deletedTsMs'},
  ],
};

/// Descriptor for `SiteContact`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List siteContactDescriptor = $convert.base64Decode(
    'CgtTaXRlQ29udGFjdBIZCghzaXRlX2lpZBgBIAEoA1IHc2l0ZUlpZBIdCgpjb250YWN0X2lkGA'
    'IgASgDUgljb250YWN0SWQSEgoEbmFtZRgDIAEoCVIEbmFtZRIUCgVwaG9uZRgEIAEoCVIFcGhv'
    'bmUSFAoFZW1haWwYBSABKAlSBWVtYWlsEhgKB2FkZHJlc3MYBiABKAlSB2FkZHJlc3MSEgoEbm'
    '90ZRgHIAEoCVIEbm90ZRIbCgltZXRhX2pzb24YCCABKAlSCG1ldGFKc29uEh8KC2lzX2FyY2hp'
    'dmVkGAkgASgIUgppc0FyY2hpdmVkEiIKDWNyZWF0ZWRfdHNfbXMYFCABKANSC2NyZWF0ZWRUc0'
    '1zEiIKDXVwZGF0ZWRfdHNfbXMYFSABKANSC3VwZGF0ZWRUc01zEiIKDWRlbGV0ZWRfdHNfbXMY'
    'FiABKANSC2RlbGV0ZWRUc01z');

@$core.Deprecated('Use siteLinkDescriptor instead')
const SiteLink$json = {
  '1': 'SiteLink',
  '2': [
    {'1': 'site_iid', '3': 1, '4': 1, '5': 3, '10': 'siteIid'},
    {'1': 'link_id', '3': 2, '4': 1, '5': 3, '10': 'linkId'},
    {'1': 'sort_order', '3': 3, '4': 1, '5': 5, '10': 'sortOrder'},
    {'1': 'label', '3': 4, '4': 1, '5': 9, '10': 'label'},
    {'1': 'url', '3': 5, '4': 1, '5': 9, '10': 'url'},
    {'1': 'icon', '3': 6, '4': 1, '5': 9, '10': 'icon'},
    {'1': 'is_pinned', '3': 7, '4': 1, '5': 8, '10': 'isPinned'},
    {'1': 'active', '3': 8, '4': 1, '5': 8, '10': 'active'},
    {'1': 'created_ts_ms', '3': 20, '4': 1, '5': 3, '10': 'createdTsMs'},
    {'1': 'updated_ts_ms', '3': 21, '4': 1, '5': 3, '10': 'updatedTsMs'},
    {'1': 'deleted_ts_ms', '3': 22, '4': 1, '5': 3, '10': 'deletedTsMs'},
  ],
};

/// Descriptor for `SiteLink`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List siteLinkDescriptor = $convert.base64Decode(
    'CghTaXRlTGluaxIZCghzaXRlX2lpZBgBIAEoA1IHc2l0ZUlpZBIXCgdsaW5rX2lkGAIgASgDUg'
    'ZsaW5rSWQSHQoKc29ydF9vcmRlchgDIAEoBVIJc29ydE9yZGVyEhQKBWxhYmVsGAQgASgJUgVs'
    'YWJlbBIQCgN1cmwYBSABKAlSA3VybBISCgRpY29uGAYgASgJUgRpY29uEhsKCWlzX3Bpbm5lZB'
    'gHIAEoCFIIaXNQaW5uZWQSFgoGYWN0aXZlGAggASgIUgZhY3RpdmUSIgoNY3JlYXRlZF90c19t'
    'cxgUIAEoA1ILY3JlYXRlZFRzTXMSIgoNdXBkYXRlZF90c19tcxgVIAEoA1ILdXBkYXRlZFRzTX'
    'MSIgoNZGVsZXRlZF90c19tcxgWIAEoA1ILZGVsZXRlZFRzTXM=');

@$core.Deprecated('Use sitePostDescriptor instead')
const SitePost$json = {
  '1': 'SitePost',
  '2': [
    {'1': 'site_iid', '3': 1, '4': 1, '5': 3, '10': 'siteIid'},
    {'1': 'post_id', '3': 2, '4': 1, '5': 3, '10': 'postId'},
    {'1': 'sort_order', '3': 3, '4': 1, '5': 5, '10': 'sortOrder'},
    {'1': 'title', '3': 4, '4': 1, '5': 9, '10': 'title'},
    {'1': 'caption', '3': 5, '4': 1, '5': 9, '10': 'caption'},
    {'1': 'body', '3': 6, '4': 1, '5': 9, '10': 'body'},
    {'1': 'media_json', '3': 7, '4': 1, '5': 9, '10': 'mediaJson'},
    {'1': 'on_storefront', '3': 8, '4': 1, '5': 8, '10': 'onStorefront'},
    {'1': 'thumb', '3': 9, '4': 1, '5': 9, '10': 'thumb'},
    {'1': 'feed_kind', '3': 10, '4': 1, '5': 9, '10': 'feedKind'},
    {'1': 'created_ts_ms', '3': 20, '4': 1, '5': 3, '10': 'createdTsMs'},
    {'1': 'updated_ts_ms', '3': 21, '4': 1, '5': 3, '10': 'updatedTsMs'},
    {'1': 'deleted_ts_ms', '3': 22, '4': 1, '5': 3, '10': 'deletedTsMs'},
  ],
};

/// Descriptor for `SitePost`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sitePostDescriptor = $convert.base64Decode(
    'CghTaXRlUG9zdBIZCghzaXRlX2lpZBgBIAEoA1IHc2l0ZUlpZBIXCgdwb3N0X2lkGAIgASgDUg'
    'Zwb3N0SWQSHQoKc29ydF9vcmRlchgDIAEoBVIJc29ydE9yZGVyEhQKBXRpdGxlGAQgASgJUgV0'
    'aXRsZRIYCgdjYXB0aW9uGAUgASgJUgdjYXB0aW9uEhIKBGJvZHkYBiABKAlSBGJvZHkSHQoKbW'
    'VkaWFfanNvbhgHIAEoCVIJbWVkaWFKc29uEiMKDW9uX3N0b3JlZnJvbnQYCCABKAhSDG9uU3Rv'
    'cmVmcm9udBIUCgV0aHVtYhgJIAEoCVIFdGh1bWISGwoJZmVlZF9raW5kGAogASgJUghmZWVkS2'
    'luZBIiCg1jcmVhdGVkX3RzX21zGBQgASgDUgtjcmVhdGVkVHNNcxIiCg11cGRhdGVkX3RzX21z'
    'GBUgASgDUgt1cGRhdGVkVHNNcxIiCg1kZWxldGVkX3RzX21zGBYgASgDUgtkZWxldGVkVHNNcw'
    '==');

@$core.Deprecated('Use siteObjectDescriptor instead')
const SiteObject$json = {
  '1': 'SiteObject',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 3, '10': 'id'},
    {'1': 'site_iid', '3': 2, '4': 1, '5': 3, '10': 'siteIid'},
    {'1': 'client_id', '3': 3, '4': 1, '5': 9, '10': 'clientId'},
    {'1': 'name', '3': 4, '4': 1, '5': 9, '10': 'name'},
    {'1': 'code', '3': 5, '4': 1, '5': 9, '10': 'code'},
    {'1': 'kind', '3': 6, '4': 1, '5': 9, '10': 'kind'},
    {'1': 'product_id', '3': 7, '4': 1, '5': 3, '10': 'productId'},
    {'1': 'can_order', '3': 8, '4': 1, '5': 8, '10': 'canOrder'},
    {'1': 'can_be_reserved', '3': 9, '4': 1, '5': 8, '10': 'canBeReserved'},
    {'1': 'is_active', '3': 10, '4': 1, '5': 8, '10': 'isActive'},
    {'1': 'desc', '3': 11, '4': 1, '5': 9, '10': 'desc'},
    {'1': 'pic', '3': 12, '4': 1, '5': 9, '10': 'pic'},
    {'1': 'meta_json', '3': 13, '4': 1, '5': 9, '10': 'metaJson'},
    {'1': 'created_ts_ms', '3': 20, '4': 1, '5': 3, '10': 'createdTsMs'},
    {'1': 'updated_ts_ms', '3': 21, '4': 1, '5': 3, '10': 'updatedTsMs'},
    {'1': 'deleted_ts_ms', '3': 22, '4': 1, '5': 3, '10': 'deletedTsMs'},
  ],
};

/// Descriptor for `SiteObject`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List siteObjectDescriptor = $convert.base64Decode(
    'CgpTaXRlT2JqZWN0Eg4KAmlkGAEgASgDUgJpZBIZCghzaXRlX2lpZBgCIAEoA1IHc2l0ZUlpZB'
    'IbCgljbGllbnRfaWQYAyABKAlSCGNsaWVudElkEhIKBG5hbWUYBCABKAlSBG5hbWUSEgoEY29k'
    'ZRgFIAEoCVIEY29kZRISCgRraW5kGAYgASgJUgRraW5kEh0KCnByb2R1Y3RfaWQYByABKANSCX'
    'Byb2R1Y3RJZBIbCgljYW5fb3JkZXIYCCABKAhSCGNhbk9yZGVyEiYKD2Nhbl9iZV9yZXNlcnZl'
    'ZBgJIAEoCFINY2FuQmVSZXNlcnZlZBIbCglpc19hY3RpdmUYCiABKAhSCGlzQWN0aXZlEhIKBG'
    'Rlc2MYCyABKAlSBGRlc2MSEAoDcGljGAwgASgJUgNwaWMSGwoJbWV0YV9qc29uGA0gASgJUght'
    'ZXRhSnNvbhIiCg1jcmVhdGVkX3RzX21zGBQgASgDUgtjcmVhdGVkVHNNcxIiCg11cGRhdGVkX3'
    'RzX21zGBUgASgDUgt1cGRhdGVkVHNNcxIiCg1kZWxldGVkX3RzX21zGBYgASgDUgtkZWxldGVk'
    'VHNNcw==');

@$core.Deprecated('Use siteRowDescriptor instead')
const SiteRow$json = {
  '1': 'SiteRow',
  '2': [
    {'1': 'site_iid', '3': 1, '4': 1, '5': 3, '10': 'siteIid'},
    {'1': 'alien_id', '3': 2, '4': 1, '5': 9, '10': 'alienId'},
    {'1': 'name', '3': 3, '4': 1, '5': 9, '10': 'name'},
    {'1': 'pic', '3': 4, '4': 1, '5': 9, '10': 'pic'},
    {
      '1': 'published_version_id',
      '3': 5,
      '4': 1,
      '5': 9,
      '10': 'publishedVersionId'
    },
    {'1': 'updated_ts_ms', '3': 6, '4': 1, '5': 3, '10': 'updatedTsMs'},
    {'1': 'is_archived', '3': 7, '4': 1, '5': 8, '10': 'isArchived'},
    {'1': 'is_pinned', '3': 8, '4': 1, '5': 8, '10': 'isPinned'},
    {'1': 'sort_order', '3': 9, '4': 1, '5': 5, '10': 'sortOrder'},
  ],
};

/// Descriptor for `SiteRow`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List siteRowDescriptor = $convert.base64Decode(
    'CgdTaXRlUm93EhkKCHNpdGVfaWlkGAEgASgDUgdzaXRlSWlkEhkKCGFsaWVuX2lkGAIgASgJUg'
    'dhbGllbklkEhIKBG5hbWUYAyABKAlSBG5hbWUSEAoDcGljGAQgASgJUgNwaWMSMAoUcHVibGlz'
    'aGVkX3ZlcnNpb25faWQYBSABKAlSEnB1Ymxpc2hlZFZlcnNpb25JZBIiCg11cGRhdGVkX3RzX2'
    '1zGAYgASgDUgt1cGRhdGVkVHNNcxIfCgtpc19hcmNoaXZlZBgHIAEoCFIKaXNBcmNoaXZlZBIb'
    'Cglpc19waW5uZWQYCCABKAhSCGlzUGlubmVkEh0KCnNvcnRfb3JkZXIYCSABKAVSCXNvcnRPcm'
    'Rlcg==');

@$core.Deprecated('Use reqSiteListDescriptor instead')
const ReqSiteList$json = {
  '1': 'ReqSiteList',
  '2': [
    {'1': 'archived', '3': 1, '4': 1, '5': 8, '10': 'archived'},
  ],
};

/// Descriptor for `ReqSiteList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqSiteListDescriptor = $convert
    .base64Decode('CgtSZXFTaXRlTGlzdBIaCghhcmNoaXZlZBgBIAEoCFIIYXJjaGl2ZWQ=');

@$core.Deprecated('Use resSiteListDescriptor instead')
const ResSiteList$json = {
  '1': 'ResSiteList',
  '2': [
    {'1': 'sites', '3': 1, '4': 3, '5': 11, '6': '.c35.SiteRow', '10': 'sites'},
    {'1': 'archived_count', '3': 2, '4': 1, '5': 5, '10': 'archivedCount'},
  ],
};

/// Descriptor for `ResSiteList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resSiteListDescriptor = $convert.base64Decode(
    'CgtSZXNTaXRlTGlzdBIiCgVzaXRlcxgBIAMoCzIMLmMzNS5TaXRlUm93UgVzaXRlcxIlCg5hcm'
    'NoaXZlZF9jb3VudBgCIAEoBVINYXJjaGl2ZWRDb3VudA==');

@$core.Deprecated('Use reqSiteDraftGetDescriptor instead')
const ReqSiteDraftGet$json = {
  '1': 'ReqSiteDraftGet',
  '2': [
    {'1': 'site_iid', '3': 1, '4': 1, '5': 3, '10': 'siteIid'},
  ],
};

/// Descriptor for `ReqSiteDraftGet`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqSiteDraftGetDescriptor = $convert.base64Decode(
    'Cg9SZXFTaXRlRHJhZnRHZXQSGQoIc2l0ZV9paWQYASABKANSB3NpdGVJaWQ=');

@$core.Deprecated('Use resSiteDraftGetDescriptor instead')
const ResSiteDraftGet$json = {
  '1': 'ResSiteDraftGet',
  '2': [
    {
      '1': 'draft',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.c35.SiteDraft',
      '10': 'draft'
    },
    {
      '1': 'config',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.c35.SiteConfig',
      '10': 'config'
    },
  ],
};

/// Descriptor for `ResSiteDraftGet`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resSiteDraftGetDescriptor = $convert.base64Decode(
    'Cg9SZXNTaXRlRHJhZnRHZXQSJAoFZHJhZnQYASABKAsyDi5jMzUuU2l0ZURyYWZ0UgVkcmFmdB'
    'InCgZjb25maWcYAiABKAsyDy5jMzUuU2l0ZUNvbmZpZ1IGY29uZmln');

@$core.Deprecated('Use reqSiteDraftPutDescriptor instead')
const ReqSiteDraftPut$json = {
  '1': 'ReqSiteDraftPut',
  '2': [
    {
      '1': 'draft',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.c35.SiteDraft',
      '10': 'draft'
    },
    {'1': 'skip_publish', '3': 2, '4': 1, '5': 8, '10': 'skipPublish'},
  ],
};

/// Descriptor for `ReqSiteDraftPut`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqSiteDraftPutDescriptor = $convert.base64Decode(
    'Cg9SZXFTaXRlRHJhZnRQdXQSJAoFZHJhZnQYASABKAsyDi5jMzUuU2l0ZURyYWZ0UgVkcmFmdB'
    'IhCgxza2lwX3B1Ymxpc2gYAiABKAhSC3NraXBQdWJsaXNo');

@$core.Deprecated('Use resSiteDraftPutDescriptor instead')
const ResSiteDraftPut$json = {
  '1': 'ResSiteDraftPut',
  '2': [
    {'1': 'site_iid', '3': 1, '4': 1, '5': 3, '10': 'siteIid'},
  ],
};

/// Descriptor for `ResSiteDraftPut`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resSiteDraftPutDescriptor = $convert.base64Decode(
    'Cg9SZXNTaXRlRHJhZnRQdXQSGQoIc2l0ZV9paWQYASABKANSB3NpdGVJaWQ=');

@$core.Deprecated('Use reqSiteConfigPutDescriptor instead')
const ReqSiteConfigPut$json = {
  '1': 'ReqSiteConfigPut',
  '2': [
    {'1': 'site_iid', '3': 1, '4': 1, '5': 3, '10': 'siteIid'},
    {
      '1': 'capabilities_json',
      '3': 2,
      '4': 1,
      '5': 9,
      '10': 'capabilitiesJson'
    },
  ],
};

/// Descriptor for `ReqSiteConfigPut`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqSiteConfigPutDescriptor = $convert.base64Decode(
    'ChBSZXFTaXRlQ29uZmlnUHV0EhkKCHNpdGVfaWlkGAEgASgDUgdzaXRlSWlkEisKEWNhcGFiaW'
    'xpdGllc19qc29uGAIgASgJUhBjYXBhYmlsaXRpZXNKc29u');

@$core.Deprecated('Use resSiteConfigPutDescriptor instead')
const ResSiteConfigPut$json = {
  '1': 'ResSiteConfigPut',
  '2': [
    {
      '1': 'config',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.c35.SiteConfig',
      '10': 'config'
    },
  ],
};

/// Descriptor for `ResSiteConfigPut`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resSiteConfigPutDescriptor = $convert.base64Decode(
    'ChBSZXNTaXRlQ29uZmlnUHV0EicKBmNvbmZpZxgBIAEoCzIPLmMzNS5TaXRlQ29uZmlnUgZjb2'
    '5maWc=');

@$core.Deprecated('Use reqSitePublishDescriptor instead')
const ReqSitePublish$json = {
  '1': 'ReqSitePublish',
  '2': [
    {'1': 'site_iid', '3': 1, '4': 1, '5': 3, '10': 'siteIid'},
  ],
};

/// Descriptor for `ReqSitePublish`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqSitePublishDescriptor = $convert.base64Decode(
    'Cg5SZXFTaXRlUHVibGlzaBIZCghzaXRlX2lpZBgBIAEoA1IHc2l0ZUlpZA==');

@$core.Deprecated('Use resSitePublishDescriptor instead')
const ResSitePublish$json = {
  '1': 'ResSitePublish',
  '2': [
    {
      '1': 'publish',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.c35.SitePublish',
      '10': 'publish'
    },
  ],
};

/// Descriptor for `ResSitePublish`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resSitePublishDescriptor = $convert.base64Decode(
    'Cg5SZXNTaXRlUHVibGlzaBIqCgdwdWJsaXNoGAEgASgLMhAuYzM1LlNpdGVQdWJsaXNoUgdwdW'
    'JsaXNo');

@$core.Deprecated('Use reqSiteProductListDescriptor instead')
const ReqSiteProductList$json = {
  '1': 'ReqSiteProductList',
  '2': [
    {'1': 'site_iid', '3': 1, '4': 1, '5': 3, '10': 'siteIid'},
  ],
};

/// Descriptor for `ReqSiteProductList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqSiteProductListDescriptor =
    $convert.base64Decode(
        'ChJSZXFTaXRlUHJvZHVjdExpc3QSGQoIc2l0ZV9paWQYASABKANSB3NpdGVJaWQ=');

@$core.Deprecated('Use resSiteProductListDescriptor instead')
const ResSiteProductList$json = {
  '1': 'ResSiteProductList',
  '2': [
    {
      '1': 'products',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.c35.SiteProduct',
      '10': 'products'
    },
  ],
};

/// Descriptor for `ResSiteProductList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resSiteProductListDescriptor = $convert.base64Decode(
    'ChJSZXNTaXRlUHJvZHVjdExpc3QSLAoIcHJvZHVjdHMYASADKAsyEC5jMzUuU2l0ZVByb2R1Y3'
    'RSCHByb2R1Y3Rz');

@$core.Deprecated('Use reqSiteProductPutDescriptor instead')
const ReqSiteProductPut$json = {
  '1': 'ReqSiteProductPut',
  '2': [
    {'1': 'site_iid', '3': 1, '4': 1, '5': 3, '10': 'siteIid'},
    {
      '1': 'product',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.c35.SiteProduct',
      '10': 'product'
    },
  ],
};

/// Descriptor for `ReqSiteProductPut`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqSiteProductPutDescriptor = $convert.base64Decode(
    'ChFSZXFTaXRlUHJvZHVjdFB1dBIZCghzaXRlX2lpZBgBIAEoA1IHc2l0ZUlpZBIqCgdwcm9kdW'
    'N0GAIgASgLMhAuYzM1LlNpdGVQcm9kdWN0Ugdwcm9kdWN0');

@$core.Deprecated('Use resSiteProductPutDescriptor instead')
const ResSiteProductPut$json = {
  '1': 'ResSiteProductPut',
  '2': [
    {'1': 'product_id', '3': 1, '4': 1, '5': 3, '10': 'productId'},
  ],
};

/// Descriptor for `ResSiteProductPut`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resSiteProductPutDescriptor = $convert.base64Decode(
    'ChFSZXNTaXRlUHJvZHVjdFB1dBIdCgpwcm9kdWN0X2lkGAEgASgDUglwcm9kdWN0SWQ=');

@$core.Deprecated('Use reqSiteProductDeleteDescriptor instead')
const ReqSiteProductDelete$json = {
  '1': 'ReqSiteProductDelete',
  '2': [
    {'1': 'site_iid', '3': 1, '4': 1, '5': 3, '10': 'siteIid'},
    {'1': 'product_id', '3': 2, '4': 1, '5': 3, '10': 'productId'},
  ],
};

/// Descriptor for `ReqSiteProductDelete`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqSiteProductDeleteDescriptor = $convert.base64Decode(
    'ChRSZXFTaXRlUHJvZHVjdERlbGV0ZRIZCghzaXRlX2lpZBgBIAEoA1IHc2l0ZUlpZBIdCgpwcm'
    '9kdWN0X2lkGAIgASgDUglwcm9kdWN0SWQ=');

@$core.Deprecated('Use resSiteProductDeleteDescriptor instead')
const ResSiteProductDelete$json = {
  '1': 'ResSiteProductDelete',
  '2': [
    {'1': 'product_id', '3': 1, '4': 1, '5': 3, '10': 'productId'},
    {'1': 'ok', '3': 2, '4': 1, '5': 8, '10': 'ok'},
  ],
};

/// Descriptor for `ResSiteProductDelete`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resSiteProductDeleteDescriptor = $convert.base64Decode(
    'ChRSZXNTaXRlUHJvZHVjdERlbGV0ZRIdCgpwcm9kdWN0X2lkGAEgASgDUglwcm9kdWN0SWQSDg'
    'oCb2sYAiABKAhSAm9r');

@$core.Deprecated('Use siteProductReorderEntryDescriptor instead')
const SiteProductReorderEntry$json = {
  '1': 'SiteProductReorderEntry',
  '2': [
    {'1': 'product_id', '3': 1, '4': 1, '5': 3, '10': 'productId'},
    {'1': 'sort_order', '3': 2, '4': 1, '5': 5, '10': 'sortOrder'},
  ],
};

/// Descriptor for `SiteProductReorderEntry`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List siteProductReorderEntryDescriptor =
    $convert.base64Decode(
        'ChdTaXRlUHJvZHVjdFJlb3JkZXJFbnRyeRIdCgpwcm9kdWN0X2lkGAEgASgDUglwcm9kdWN0SW'
        'QSHQoKc29ydF9vcmRlchgCIAEoBVIJc29ydE9yZGVy');

@$core.Deprecated('Use reqSiteProductReorderDescriptor instead')
const ReqSiteProductReorder$json = {
  '1': 'ReqSiteProductReorder',
  '2': [
    {'1': 'site_iid', '3': 1, '4': 1, '5': 3, '10': 'siteIid'},
    {
      '1': 'entries',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.c35.SiteProductReorderEntry',
      '10': 'entries'
    },
  ],
};

/// Descriptor for `ReqSiteProductReorder`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqSiteProductReorderDescriptor = $convert.base64Decode(
    'ChVSZXFTaXRlUHJvZHVjdFJlb3JkZXISGQoIc2l0ZV9paWQYASABKANSB3NpdGVJaWQSNgoHZW'
    '50cmllcxgCIAMoCzIcLmMzNS5TaXRlUHJvZHVjdFJlb3JkZXJFbnRyeVIHZW50cmllcw==');

@$core.Deprecated('Use resSiteProductReorderDescriptor instead')
const ResSiteProductReorder$json = {
  '1': 'ResSiteProductReorder',
  '2': [
    {'1': 'ok', '3': 1, '4': 1, '5': 8, '10': 'ok'},
  ],
};

/// Descriptor for `ResSiteProductReorder`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resSiteProductReorderDescriptor = $convert
    .base64Decode('ChVSZXNTaXRlUHJvZHVjdFJlb3JkZXISDgoCb2sYASABKAhSAm9r');

@$core.Deprecated('Use reqSiteContactListDescriptor instead')
const ReqSiteContactList$json = {
  '1': 'ReqSiteContactList',
  '2': [
    {'1': 'site_iid', '3': 1, '4': 1, '5': 3, '10': 'siteIid'},
    {'1': 'q', '3': 2, '4': 1, '5': 9, '10': 'q'},
  ],
};

/// Descriptor for `ReqSiteContactList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqSiteContactListDescriptor = $convert.base64Decode(
    'ChJSZXFTaXRlQ29udGFjdExpc3QSGQoIc2l0ZV9paWQYASABKANSB3NpdGVJaWQSDAoBcRgCIA'
    'EoCVIBcQ==');

@$core.Deprecated('Use resSiteContactListDescriptor instead')
const ResSiteContactList$json = {
  '1': 'ResSiteContactList',
  '2': [
    {
      '1': 'contacts',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.c35.SiteContact',
      '10': 'contacts'
    },
  ],
};

/// Descriptor for `ResSiteContactList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resSiteContactListDescriptor = $convert.base64Decode(
    'ChJSZXNTaXRlQ29udGFjdExpc3QSLAoIY29udGFjdHMYASADKAsyEC5jMzUuU2l0ZUNvbnRhY3'
    'RSCGNvbnRhY3Rz');

@$core.Deprecated('Use reqSiteContactPutDescriptor instead')
const ReqSiteContactPut$json = {
  '1': 'ReqSiteContactPut',
  '2': [
    {'1': 'site_iid', '3': 1, '4': 1, '5': 3, '10': 'siteIid'},
    {
      '1': 'contact',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.c35.SiteContact',
      '10': 'contact'
    },
  ],
};

/// Descriptor for `ReqSiteContactPut`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqSiteContactPutDescriptor = $convert.base64Decode(
    'ChFSZXFTaXRlQ29udGFjdFB1dBIZCghzaXRlX2lpZBgBIAEoA1IHc2l0ZUlpZBIqCgdjb250YW'
    'N0GAIgASgLMhAuYzM1LlNpdGVDb250YWN0Ugdjb250YWN0');

@$core.Deprecated('Use resSiteContactPutDescriptor instead')
const ResSiteContactPut$json = {
  '1': 'ResSiteContactPut',
  '2': [
    {'1': 'contact_id', '3': 1, '4': 1, '5': 3, '10': 'contactId'},
  ],
};

/// Descriptor for `ResSiteContactPut`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resSiteContactPutDescriptor = $convert.base64Decode(
    'ChFSZXNTaXRlQ29udGFjdFB1dBIdCgpjb250YWN0X2lkGAEgASgDUgljb250YWN0SWQ=');

@$core.Deprecated('Use reqSiteLinkListDescriptor instead')
const ReqSiteLinkList$json = {
  '1': 'ReqSiteLinkList',
  '2': [
    {'1': 'site_iid', '3': 1, '4': 1, '5': 3, '10': 'siteIid'},
  ],
};

/// Descriptor for `ReqSiteLinkList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqSiteLinkListDescriptor = $convert.base64Decode(
    'Cg9SZXFTaXRlTGlua0xpc3QSGQoIc2l0ZV9paWQYASABKANSB3NpdGVJaWQ=');

@$core.Deprecated('Use resSiteLinkListDescriptor instead')
const ResSiteLinkList$json = {
  '1': 'ResSiteLinkList',
  '2': [
    {
      '1': 'links',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.c35.SiteLink',
      '10': 'links'
    },
  ],
};

/// Descriptor for `ResSiteLinkList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resSiteLinkListDescriptor = $convert.base64Decode(
    'Cg9SZXNTaXRlTGlua0xpc3QSIwoFbGlua3MYASADKAsyDS5jMzUuU2l0ZUxpbmtSBWxpbmtz');

@$core.Deprecated('Use reqSiteLinkPutDescriptor instead')
const ReqSiteLinkPut$json = {
  '1': 'ReqSiteLinkPut',
  '2': [
    {'1': 'site_iid', '3': 1, '4': 1, '5': 3, '10': 'siteIid'},
    {'1': 'link', '3': 2, '4': 1, '5': 11, '6': '.c35.SiteLink', '10': 'link'},
  ],
};

/// Descriptor for `ReqSiteLinkPut`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqSiteLinkPutDescriptor = $convert.base64Decode(
    'Cg5SZXFTaXRlTGlua1B1dBIZCghzaXRlX2lpZBgBIAEoA1IHc2l0ZUlpZBIhCgRsaW5rGAIgAS'
    'gLMg0uYzM1LlNpdGVMaW5rUgRsaW5r');

@$core.Deprecated('Use resSiteLinkPutDescriptor instead')
const ResSiteLinkPut$json = {
  '1': 'ResSiteLinkPut',
  '2': [
    {'1': 'link_id', '3': 1, '4': 1, '5': 3, '10': 'linkId'},
  ],
};

/// Descriptor for `ResSiteLinkPut`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resSiteLinkPutDescriptor = $convert
    .base64Decode('Cg5SZXNTaXRlTGlua1B1dBIXCgdsaW5rX2lkGAEgASgDUgZsaW5rSWQ=');

@$core.Deprecated('Use reqSiteLinkDeleteDescriptor instead')
const ReqSiteLinkDelete$json = {
  '1': 'ReqSiteLinkDelete',
  '2': [
    {'1': 'site_iid', '3': 1, '4': 1, '5': 3, '10': 'siteIid'},
    {'1': 'link_id', '3': 2, '4': 1, '5': 3, '10': 'linkId'},
  ],
};

/// Descriptor for `ReqSiteLinkDelete`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqSiteLinkDeleteDescriptor = $convert.base64Decode(
    'ChFSZXFTaXRlTGlua0RlbGV0ZRIZCghzaXRlX2lpZBgBIAEoA1IHc2l0ZUlpZBIXCgdsaW5rX2'
    'lkGAIgASgDUgZsaW5rSWQ=');

@$core.Deprecated('Use resSiteLinkDeleteDescriptor instead')
const ResSiteLinkDelete$json = {
  '1': 'ResSiteLinkDelete',
  '2': [
    {'1': 'link_id', '3': 1, '4': 1, '5': 3, '10': 'linkId'},
    {'1': 'ok', '3': 2, '4': 1, '5': 8, '10': 'ok'},
  ],
};

/// Descriptor for `ResSiteLinkDelete`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resSiteLinkDeleteDescriptor = $convert.base64Decode(
    'ChFSZXNTaXRlTGlua0RlbGV0ZRIXCgdsaW5rX2lkGAEgASgDUgZsaW5rSWQSDgoCb2sYAiABKA'
    'hSAm9r');

@$core.Deprecated('Use reqSitePostListDescriptor instead')
const ReqSitePostList$json = {
  '1': 'ReqSitePostList',
  '2': [
    {'1': 'site_iid', '3': 1, '4': 1, '5': 3, '10': 'siteIid'},
  ],
};

/// Descriptor for `ReqSitePostList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqSitePostListDescriptor = $convert.base64Decode(
    'Cg9SZXFTaXRlUG9zdExpc3QSGQoIc2l0ZV9paWQYASABKANSB3NpdGVJaWQ=');

@$core.Deprecated('Use resSitePostListDescriptor instead')
const ResSitePostList$json = {
  '1': 'ResSitePostList',
  '2': [
    {
      '1': 'posts',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.c35.SitePost',
      '10': 'posts'
    },
  ],
};

/// Descriptor for `ResSitePostList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resSitePostListDescriptor = $convert.base64Decode(
    'Cg9SZXNTaXRlUG9zdExpc3QSIwoFcG9zdHMYASADKAsyDS5jMzUuU2l0ZVBvc3RSBXBvc3Rz');

@$core.Deprecated('Use reqSitePostPutDescriptor instead')
const ReqSitePostPut$json = {
  '1': 'ReqSitePostPut',
  '2': [
    {'1': 'site_iid', '3': 1, '4': 1, '5': 3, '10': 'siteIid'},
    {'1': 'post', '3': 2, '4': 1, '5': 11, '6': '.c35.SitePost', '10': 'post'},
  ],
};

/// Descriptor for `ReqSitePostPut`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqSitePostPutDescriptor = $convert.base64Decode(
    'Cg5SZXFTaXRlUG9zdFB1dBIZCghzaXRlX2lpZBgBIAEoA1IHc2l0ZUlpZBIhCgRwb3N0GAIgAS'
    'gLMg0uYzM1LlNpdGVQb3N0UgRwb3N0');

@$core.Deprecated('Use resSitePostPutDescriptor instead')
const ResSitePostPut$json = {
  '1': 'ResSitePostPut',
  '2': [
    {'1': 'post_id', '3': 1, '4': 1, '5': 3, '10': 'postId'},
  ],
};

/// Descriptor for `ResSitePostPut`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resSitePostPutDescriptor = $convert
    .base64Decode('Cg5SZXNTaXRlUG9zdFB1dBIXCgdwb3N0X2lkGAEgASgDUgZwb3N0SWQ=');

@$core.Deprecated('Use reqSitePostDeleteDescriptor instead')
const ReqSitePostDelete$json = {
  '1': 'ReqSitePostDelete',
  '2': [
    {'1': 'site_iid', '3': 1, '4': 1, '5': 3, '10': 'siteIid'},
    {'1': 'post_id', '3': 2, '4': 1, '5': 3, '10': 'postId'},
  ],
};

/// Descriptor for `ReqSitePostDelete`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqSitePostDeleteDescriptor = $convert.base64Decode(
    'ChFSZXFTaXRlUG9zdERlbGV0ZRIZCghzaXRlX2lpZBgBIAEoA1IHc2l0ZUlpZBIXCgdwb3N0X2'
    'lkGAIgASgDUgZwb3N0SWQ=');

@$core.Deprecated('Use resSitePostDeleteDescriptor instead')
const ResSitePostDelete$json = {
  '1': 'ResSitePostDelete',
  '2': [
    {'1': 'post_id', '3': 1, '4': 1, '5': 3, '10': 'postId'},
    {'1': 'ok', '3': 2, '4': 1, '5': 8, '10': 'ok'},
  ],
};

/// Descriptor for `ResSitePostDelete`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resSitePostDeleteDescriptor = $convert.base64Decode(
    'ChFSZXNTaXRlUG9zdERlbGV0ZRIXCgdwb3N0X2lkGAEgASgDUgZwb3N0SWQSDgoCb2sYAiABKA'
    'hSAm9r');

@$core.Deprecated('Use reqSiteObjectListDescriptor instead')
const ReqSiteObjectList$json = {
  '1': 'ReqSiteObjectList',
  '2': [
    {'1': 'site_iid', '3': 1, '4': 1, '5': 3, '10': 'siteIid'},
  ],
};

/// Descriptor for `ReqSiteObjectList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqSiteObjectListDescriptor = $convert.base64Decode(
    'ChFSZXFTaXRlT2JqZWN0TGlzdBIZCghzaXRlX2lpZBgBIAEoA1IHc2l0ZUlpZA==');

@$core.Deprecated('Use resSiteObjectListDescriptor instead')
const ResSiteObjectList$json = {
  '1': 'ResSiteObjectList',
  '2': [
    {
      '1': 'objs',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.c35.SiteObject',
      '10': 'objs'
    },
  ],
};

/// Descriptor for `ResSiteObjectList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resSiteObjectListDescriptor = $convert.base64Decode(
    'ChFSZXNTaXRlT2JqZWN0TGlzdBIjCgRvYmpzGAEgAygLMg8uYzM1LlNpdGVPYmplY3RSBG9ian'
    'M=');

@$core.Deprecated('Use reqSiteObjectPutDescriptor instead')
const ReqSiteObjectPut$json = {
  '1': 'ReqSiteObjectPut',
  '2': [
    {'1': 'site_iid', '3': 1, '4': 1, '5': 3, '10': 'siteIid'},
    {'1': 'obj', '3': 2, '4': 1, '5': 11, '6': '.c35.SiteObject', '10': 'obj'},
  ],
};

/// Descriptor for `ReqSiteObjectPut`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqSiteObjectPutDescriptor = $convert.base64Decode(
    'ChBSZXFTaXRlT2JqZWN0UHV0EhkKCHNpdGVfaWlkGAEgASgDUgdzaXRlSWlkEiEKA29iahgCIA'
    'EoCzIPLmMzNS5TaXRlT2JqZWN0UgNvYmo=');

@$core.Deprecated('Use resSiteObjectPutDescriptor instead')
const ResSiteObjectPut$json = {
  '1': 'ResSiteObjectPut',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 3, '10': 'id'},
  ],
};

/// Descriptor for `ResSiteObjectPut`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resSiteObjectPutDescriptor =
    $convert.base64Decode('ChBSZXNTaXRlT2JqZWN0UHV0Eg4KAmlkGAEgASgDUgJpZA==');

@$core.Deprecated('Use reqSiteDomainListDescriptor instead')
const ReqSiteDomainList$json = {
  '1': 'ReqSiteDomainList',
  '2': [
    {'1': 'site_iid', '3': 1, '4': 1, '5': 3, '10': 'siteIid'},
  ],
};

/// Descriptor for `ReqSiteDomainList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqSiteDomainListDescriptor = $convert.base64Decode(
    'ChFSZXFTaXRlRG9tYWluTGlzdBIZCghzaXRlX2lpZBgBIAEoA1IHc2l0ZUlpZA==');

@$core.Deprecated('Use resSiteDomainListDescriptor instead')
const ResSiteDomainList$json = {
  '1': 'ResSiteDomainList',
  '2': [
    {
      '1': 'domains',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.c35.SiteDomain',
      '10': 'domains'
    },
  ],
};

/// Descriptor for `ResSiteDomainList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resSiteDomainListDescriptor = $convert.base64Decode(
    'ChFSZXNTaXRlRG9tYWluTGlzdBIpCgdkb21haW5zGAEgAygLMg8uYzM1LlNpdGVEb21haW5SB2'
    'RvbWFpbnM=');

@$core.Deprecated('Use reqSiteDomainPutDescriptor instead')
const ReqSiteDomainPut$json = {
  '1': 'ReqSiteDomainPut',
  '2': [
    {'1': 'site_iid', '3': 1, '4': 1, '5': 3, '10': 'siteIid'},
    {
      '1': 'domain',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.c35.SiteDomain',
      '10': 'domain'
    },
  ],
};

/// Descriptor for `ReqSiteDomainPut`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqSiteDomainPutDescriptor = $convert.base64Decode(
    'ChBSZXFTaXRlRG9tYWluUHV0EhkKCHNpdGVfaWlkGAEgASgDUgdzaXRlSWlkEicKBmRvbWFpbh'
    'gCIAEoCzIPLmMzNS5TaXRlRG9tYWluUgZkb21haW4=');

@$core.Deprecated('Use resSiteDomainPutDescriptor instead')
const ResSiteDomainPut$json = {
  '1': 'ResSiteDomainPut',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 3, '10': 'id'},
  ],
};

/// Descriptor for `ResSiteDomainPut`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resSiteDomainPutDescriptor =
    $convert.base64Decode('ChBSZXNTaXRlRG9tYWluUHV0Eg4KAmlkGAEgASgDUgJpZA==');

@$core.Deprecated('Use reqSiteDomainVerifyDescriptor instead')
const ReqSiteDomainVerify$json = {
  '1': 'ReqSiteDomainVerify',
  '2': [
    {'1': 'site_iid', '3': 1, '4': 1, '5': 3, '10': 'siteIid'},
    {'1': 'domain_id', '3': 2, '4': 1, '5': 3, '10': 'domainId'},
    {'1': 'force_tls', '3': 3, '4': 1, '5': 8, '10': 'forceTls'},
  ],
};

/// Descriptor for `ReqSiteDomainVerify`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqSiteDomainVerifyDescriptor = $convert.base64Decode(
    'ChNSZXFTaXRlRG9tYWluVmVyaWZ5EhkKCHNpdGVfaWlkGAEgASgDUgdzaXRlSWlkEhsKCWRvbW'
    'Fpbl9pZBgCIAEoA1IIZG9tYWluSWQSGwoJZm9yY2VfdGxzGAMgASgIUghmb3JjZVRscw==');

@$core.Deprecated('Use resSiteDomainVerifyDescriptor instead')
const ResSiteDomainVerify$json = {
  '1': 'ResSiteDomainVerify',
  '2': [
    {'1': 'dns_verified', '3': 1, '4': 1, '5': 8, '10': 'dnsVerified'},
    {'1': 'error', '3': 2, '4': 1, '5': 9, '10': 'error'},
    {'1': 'tls_status', '3': 3, '4': 1, '5': 9, '10': 'tlsStatus'},
  ],
};

/// Descriptor for `ResSiteDomainVerify`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resSiteDomainVerifyDescriptor = $convert.base64Decode(
    'ChNSZXNTaXRlRG9tYWluVmVyaWZ5EiEKDGRuc192ZXJpZmllZBgBIAEoCFILZG5zVmVyaWZpZW'
    'QSFAoFZXJyb3IYAiABKAlSBWVycm9yEh0KCnRsc19zdGF0dXMYAyABKAlSCXRsc1N0YXR1cw==');

@$core.Deprecated('Use reqSitePreviewTokenDescriptor instead')
const ReqSitePreviewToken$json = {
  '1': 'ReqSitePreviewToken',
  '2': [
    {'1': 'site_iid', '3': 1, '4': 1, '5': 3, '10': 'siteIid'},
    {'1': 'ttl_secs', '3': 2, '4': 1, '5': 5, '10': 'ttlSecs'},
  ],
};

/// Descriptor for `ReqSitePreviewToken`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqSitePreviewTokenDescriptor = $convert.base64Decode(
    'ChNSZXFTaXRlUHJldmlld1Rva2VuEhkKCHNpdGVfaWlkGAEgASgDUgdzaXRlSWlkEhkKCHR0bF'
    '9zZWNzGAIgASgFUgd0dGxTZWNz');

@$core.Deprecated('Use resSitePreviewTokenDescriptor instead')
const ResSitePreviewToken$json = {
  '1': 'ResSitePreviewToken',
  '2': [
    {'1': 'token', '3': 1, '4': 1, '5': 9, '10': 'token'},
    {'1': 'expires_ts_ms', '3': 2, '4': 1, '5': 3, '10': 'expiresTsMs'},
  ],
};

/// Descriptor for `ResSitePreviewToken`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resSitePreviewTokenDescriptor = $convert.base64Decode(
    'ChNSZXNTaXRlUHJldmlld1Rva2VuEhQKBXRva2VuGAEgASgJUgV0b2tlbhIiCg1leHBpcmVzX3'
    'RzX21zGAIgASgDUgtleHBpcmVzVHNNcw==');

@$core.Deprecated('Use reqSiteHandlePutDescriptor instead')
const ReqSiteHandlePut$json = {
  '1': 'ReqSiteHandlePut',
  '2': [
    {'1': 'site_iid', '3': 1, '4': 1, '5': 3, '10': 'siteIid'},
    {'1': 'new_alien_id', '3': 2, '4': 1, '5': 9, '10': 'newAlienId'},
  ],
};

/// Descriptor for `ReqSiteHandlePut`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqSiteHandlePutDescriptor = $convert.base64Decode(
    'ChBSZXFTaXRlSGFuZGxlUHV0EhkKCHNpdGVfaWlkGAEgASgDUgdzaXRlSWlkEiAKDG5ld19hbG'
    'llbl9pZBgCIAEoCVIKbmV3QWxpZW5JZA==');

@$core.Deprecated('Use resSiteHandlePutDescriptor instead')
const ResSiteHandlePut$json = {
  '1': 'ResSiteHandlePut',
  '2': [
    {'1': 'site_iid', '3': 1, '4': 1, '5': 3, '10': 'siteIid'},
    {'1': 'alien_id', '3': 2, '4': 1, '5': 9, '10': 'alienId'},
    {'1': 'url', '3': 3, '4': 1, '5': 9, '10': 'url'},
  ],
};

/// Descriptor for `ResSiteHandlePut`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resSiteHandlePutDescriptor = $convert.base64Decode(
    'ChBSZXNTaXRlSGFuZGxlUHV0EhkKCHNpdGVfaWlkGAEgASgDUgdzaXRlSWlkEhkKCGFsaWVuX2'
    'lkGAIgASgJUgdhbGllbklkEhAKA3VybBgDIAEoCVIDdXJs');

@$core.Deprecated('Use reqSiteBootGetDescriptor instead')
const ReqSiteBootGet$json = {
  '1': 'ReqSiteBootGet',
  '2': [
    {'1': 'site_iid', '3': 1, '4': 1, '5': 3, '10': 'siteIid'},
    {
      '1': 'mode',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.c35.SiteBootMode',
      '10': 'mode'
    },
  ],
};

/// Descriptor for `ReqSiteBootGet`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqSiteBootGetDescriptor = $convert.base64Decode(
    'Cg5SZXFTaXRlQm9vdEdldBIZCghzaXRlX2lpZBgBIAEoA1IHc2l0ZUlpZBIlCgRtb2RlGAIgAS'
    'gOMhEuYzM1LlNpdGVCb290TW9kZVIEbW9kZQ==');

@$core.Deprecated('Use resSiteBootGetDescriptor instead')
const ResSiteBootGet$json = {
  '1': 'ResSiteBootGet',
  '2': [
    {'1': 'boot_json', '3': 1, '4': 1, '5': 9, '10': 'bootJson'},
  ],
};

/// Descriptor for `ResSiteBootGet`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resSiteBootGetDescriptor = $convert.base64Decode(
    'Cg5SZXNTaXRlQm9vdEdldBIbCglib290X2pzb24YASABKAlSCGJvb3RKc29u');

@$core.Deprecated('Use siteQueryRowDescriptor instead')
const SiteQueryRow$json = {
  '1': 'SiteQueryRow',
  '2': [
    {'1': 'site_iid', '3': 1, '4': 1, '5': 3, '10': 'siteIid'},
    {'1': 'site_name', '3': 2, '4': 1, '5': 9, '10': 'siteName'},
    {
      '1': 'cells',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.c35.SiteQueryRow.CellsEntry',
      '10': 'cells'
    },
  ],
  '3': [SiteQueryRow_CellsEntry$json],
};

@$core.Deprecated('Use siteQueryRowDescriptor instead')
const SiteQueryRow_CellsEntry$json = {
  '1': 'CellsEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `SiteQueryRow`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List siteQueryRowDescriptor = $convert.base64Decode(
    'CgxTaXRlUXVlcnlSb3cSGQoIc2l0ZV9paWQYASABKANSB3NpdGVJaWQSGwoJc2l0ZV9uYW1lGA'
    'IgASgJUghzaXRlTmFtZRIyCgVjZWxscxgDIAMoCzIcLmMzNS5TaXRlUXVlcnlSb3cuQ2VsbHNF'
    'bnRyeVIFY2VsbHMaOAoKQ2VsbHNFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIA'
    'EoCVIFdmFsdWU6AjgB');

@$core.Deprecated('Use reqSiteQueryRunDescriptor instead')
const ReqSiteQueryRun$json = {
  '1': 'ReqSiteQueryRun',
  '2': [
    {'1': 'query_id', '3': 1, '4': 1, '5': 9, '10': 'queryId'},
    {'1': 'site_iids', '3': 2, '4': 3, '5': 3, '10': 'siteIids'},
    {'1': 'params_json', '3': 3, '4': 1, '5': 9, '10': 'paramsJson'},
  ],
};

/// Descriptor for `ReqSiteQueryRun`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqSiteQueryRunDescriptor = $convert.base64Decode(
    'Cg9SZXFTaXRlUXVlcnlSdW4SGQoIcXVlcnlfaWQYASABKAlSB3F1ZXJ5SWQSGwoJc2l0ZV9paW'
    'RzGAIgAygDUghzaXRlSWlkcxIfCgtwYXJhbXNfanNvbhgDIAEoCVIKcGFyYW1zSnNvbg==');

@$core.Deprecated('Use resSiteQueryRunDescriptor instead')
const ResSiteQueryRun$json = {
  '1': 'ResSiteQueryRun',
  '2': [
    {
      '1': 'rows',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.c35.SiteQueryRow',
      '10': 'rows'
    },
    {'1': 'result_json', '3': 2, '4': 1, '5': 9, '10': 'resultJson'},
  ],
};

/// Descriptor for `ResSiteQueryRun`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resSiteQueryRunDescriptor = $convert.base64Decode(
    'Cg9SZXNTaXRlUXVlcnlSdW4SJQoEcm93cxgBIAMoCzIRLmMzNS5TaXRlUXVlcnlSb3dSBHJvd3'
    'MSHwoLcmVzdWx0X2pzb24YAiABKAlSCnJlc3VsdEpzb24=');

@$core.Deprecated('Use reqSiteGuestContactPutDescriptor instead')
const ReqSiteGuestContactPut$json = {
  '1': 'ReqSiteGuestContactPut',
  '2': [
    {'1': 'site_iid', '3': 1, '4': 1, '5': 3, '10': 'siteIid'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'contact_val', '3': 3, '4': 1, '5': 9, '10': 'contactVal'},
    {'1': 'message', '3': 4, '4': 1, '5': 9, '10': 'message'},
    {'1': 'meta_json', '3': 5, '4': 1, '5': 9, '10': 'metaJson'},
  ],
};

/// Descriptor for `ReqSiteGuestContactPut`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqSiteGuestContactPutDescriptor = $convert.base64Decode(
    'ChZSZXFTaXRlR3Vlc3RDb250YWN0UHV0EhkKCHNpdGVfaWlkGAEgASgDUgdzaXRlSWlkEhIKBG'
    '5hbWUYAiABKAlSBG5hbWUSHwoLY29udGFjdF92YWwYAyABKAlSCmNvbnRhY3RWYWwSGAoHbWVz'
    'c2FnZRgEIAEoCVIHbWVzc2FnZRIbCgltZXRhX2pzb24YBSABKAlSCG1ldGFKc29u');

@$core.Deprecated('Use resSiteGuestContactPutDescriptor instead')
const ResSiteGuestContactPut$json = {
  '1': 'ResSiteGuestContactPut',
  '2': [
    {'1': 'ok', '3': 1, '4': 1, '5': 8, '10': 'ok'},
    {'1': 'contact_id', '3': 2, '4': 1, '5': 3, '10': 'contactId'},
    {'1': 'error', '3': 3, '4': 1, '5': 9, '10': 'error'},
  ],
};

/// Descriptor for `ResSiteGuestContactPut`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resSiteGuestContactPutDescriptor =
    $convert.base64Decode(
        'ChZSZXNTaXRlR3Vlc3RDb250YWN0UHV0Eg4KAm9rGAEgASgIUgJvaxIdCgpjb250YWN0X2lkGA'
        'IgASgDUgljb250YWN0SWQSFAoFZXJyb3IYAyABKAlSBWVycm9y');

@$core.Deprecated('Use siteGuestProductItemDescriptor instead')
const SiteGuestProductItem$json = {
  '1': 'SiteGuestProductItem',
  '2': [
    {'1': 'product_id', '3': 1, '4': 1, '5': 3, '10': 'productId'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'desc', '3': 3, '4': 1, '5': 9, '10': 'desc'},
    {'1': 'price', '3': 4, '4': 1, '5': 3, '10': 'price'},
    {'1': 'pic', '3': 5, '4': 1, '5': 9, '10': 'pic'},
    {'1': 'category', '3': 6, '4': 1, '5': 9, '10': 'category'},
  ],
};

/// Descriptor for `SiteGuestProductItem`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List siteGuestProductItemDescriptor = $convert.base64Decode(
    'ChRTaXRlR3Vlc3RQcm9kdWN0SXRlbRIdCgpwcm9kdWN0X2lkGAEgASgDUglwcm9kdWN0SWQSEg'
    'oEbmFtZRgCIAEoCVIEbmFtZRISCgRkZXNjGAMgASgJUgRkZXNjEhQKBXByaWNlGAQgASgDUgVw'
    'cmljZRIQCgNwaWMYBSABKAlSA3BpYxIaCghjYXRlZ29yeRgGIAEoCVIIY2F0ZWdvcnk=');

@$core.Deprecated('Use reqSiteGuestProductListDescriptor instead')
const ReqSiteGuestProductList$json = {
  '1': 'ReqSiteGuestProductList',
  '2': [
    {'1': 'site_iid', '3': 1, '4': 1, '5': 3, '10': 'siteIid'},
    {'1': 'filter', '3': 2, '4': 1, '5': 9, '10': 'filter'},
    {'1': 'category', '3': 3, '4': 1, '5': 9, '10': 'category'},
    {'1': 'cursor', '3': 4, '4': 1, '5': 9, '10': 'cursor'},
    {'1': 'limit', '3': 5, '4': 1, '5': 5, '10': 'limit'},
  ],
};

/// Descriptor for `ReqSiteGuestProductList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqSiteGuestProductListDescriptor = $convert.base64Decode(
    'ChdSZXFTaXRlR3Vlc3RQcm9kdWN0TGlzdBIZCghzaXRlX2lpZBgBIAEoA1IHc2l0ZUlpZBIWCg'
    'ZmaWx0ZXIYAiABKAlSBmZpbHRlchIaCghjYXRlZ29yeRgDIAEoCVIIY2F0ZWdvcnkSFgoGY3Vy'
    'c29yGAQgASgJUgZjdXJzb3ISFAoFbGltaXQYBSABKAVSBWxpbWl0');

@$core.Deprecated('Use resSiteGuestProductListDescriptor instead')
const ResSiteGuestProductList$json = {
  '1': 'ResSiteGuestProductList',
  '2': [
    {
      '1': 'items',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.c35.SiteGuestProductItem',
      '10': 'items'
    },
    {'1': 'next_cursor', '3': 2, '4': 1, '5': 9, '10': 'nextCursor'},
  ],
};

/// Descriptor for `ResSiteGuestProductList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resSiteGuestProductListDescriptor = $convert.base64Decode(
    'ChdSZXNTaXRlR3Vlc3RQcm9kdWN0TGlzdBIvCgVpdGVtcxgBIAMoCzIZLmMzNS5TaXRlR3Vlc3'
    'RQcm9kdWN0SXRlbVIFaXRlbXMSHwoLbmV4dF9jdXJzb3IYAiABKAlSCm5leHRDdXJzb3I=');

@$core.Deprecated('Use siteGrantDescriptor instead')
const SiteGrant$json = {
  '1': 'SiteGrant',
  '2': [
    {'1': 'site_iid', '3': 1, '4': 1, '5': 3, '10': 'siteIid'},
    {'1': 'grantee_iid', '3': 2, '4': 1, '5': 3, '10': 'granteeIid'},
    {'1': 'grantee_alien_id', '3': 3, '4': 1, '5': 9, '10': 'granteeAlienId'},
    {'1': 'grantee_name', '3': 4, '4': 1, '5': 9, '10': 'granteeName'},
    {'1': 'role', '3': 5, '4': 1, '5': 9, '10': 'role'},
    {'1': 'created_ts_ms', '3': 20, '4': 1, '5': 3, '10': 'createdTsMs'},
    {'1': 'updated_ts_ms', '3': 21, '4': 1, '5': 3, '10': 'updatedTsMs'},
  ],
};

/// Descriptor for `SiteGrant`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List siteGrantDescriptor = $convert.base64Decode(
    'CglTaXRlR3JhbnQSGQoIc2l0ZV9paWQYASABKANSB3NpdGVJaWQSHwoLZ3JhbnRlZV9paWQYAi'
    'ABKANSCmdyYW50ZWVJaWQSKAoQZ3JhbnRlZV9hbGllbl9pZBgDIAEoCVIOZ3JhbnRlZUFsaWVu'
    'SWQSIQoMZ3JhbnRlZV9uYW1lGAQgASgJUgtncmFudGVlTmFtZRISCgRyb2xlGAUgASgJUgRyb2'
    'xlEiIKDWNyZWF0ZWRfdHNfbXMYFCABKANSC2NyZWF0ZWRUc01zEiIKDXVwZGF0ZWRfdHNfbXMY'
    'FSABKANSC3VwZGF0ZWRUc01z');

@$core.Deprecated('Use reqSiteGrantListDescriptor instead')
const ReqSiteGrantList$json = {
  '1': 'ReqSiteGrantList',
  '2': [
    {'1': 'site_iid', '3': 1, '4': 1, '5': 3, '10': 'siteIid'},
  ],
};

/// Descriptor for `ReqSiteGrantList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqSiteGrantListDescriptor = $convert.base64Decode(
    'ChBSZXFTaXRlR3JhbnRMaXN0EhkKCHNpdGVfaWlkGAEgASgDUgdzaXRlSWlk');

@$core.Deprecated('Use resSiteGrantListDescriptor instead')
const ResSiteGrantList$json = {
  '1': 'ResSiteGrantList',
  '2': [
    {
      '1': 'grants',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.c35.SiteGrant',
      '10': 'grants'
    },
  ],
};

/// Descriptor for `ResSiteGrantList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resSiteGrantListDescriptor = $convert.base64Decode(
    'ChBSZXNTaXRlR3JhbnRMaXN0EiYKBmdyYW50cxgBIAMoCzIOLmMzNS5TaXRlR3JhbnRSBmdyYW'
    '50cw==');

@$core.Deprecated('Use reqSiteGrantPutDescriptor instead')
const ReqSiteGrantPut$json = {
  '1': 'ReqSiteGrantPut',
  '2': [
    {'1': 'site_iid', '3': 1, '4': 1, '5': 3, '10': 'siteIid'},
    {'1': 'grantee_iid', '3': 2, '4': 1, '5': 3, '10': 'granteeIid'},
    {'1': 'grantee_alien_id', '3': 3, '4': 1, '5': 9, '10': 'granteeAlienId'},
    {'1': 'role', '3': 4, '4': 1, '5': 9, '10': 'role'},
  ],
};

/// Descriptor for `ReqSiteGrantPut`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqSiteGrantPutDescriptor = $convert.base64Decode(
    'Cg9SZXFTaXRlR3JhbnRQdXQSGQoIc2l0ZV9paWQYASABKANSB3NpdGVJaWQSHwoLZ3JhbnRlZV'
    '9paWQYAiABKANSCmdyYW50ZWVJaWQSKAoQZ3JhbnRlZV9hbGllbl9pZBgDIAEoCVIOZ3JhbnRl'
    'ZUFsaWVuSWQSEgoEcm9sZRgEIAEoCVIEcm9sZQ==');

@$core.Deprecated('Use resSiteGrantPutDescriptor instead')
const ResSiteGrantPut$json = {
  '1': 'ResSiteGrantPut',
  '2': [
    {'1': 'grantee_iid', '3': 1, '4': 1, '5': 3, '10': 'granteeIid'},
    {'1': 'ok', '3': 2, '4': 1, '5': 8, '10': 'ok'},
  ],
};

/// Descriptor for `ResSiteGrantPut`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resSiteGrantPutDescriptor = $convert.base64Decode(
    'Cg9SZXNTaXRlR3JhbnRQdXQSHwoLZ3JhbnRlZV9paWQYASABKANSCmdyYW50ZWVJaWQSDgoCb2'
    'sYAiABKAhSAm9r');

@$core.Deprecated('Use reqSiteGrantDeleteDescriptor instead')
const ReqSiteGrantDelete$json = {
  '1': 'ReqSiteGrantDelete',
  '2': [
    {'1': 'site_iid', '3': 1, '4': 1, '5': 3, '10': 'siteIid'},
    {'1': 'grantee_iid', '3': 2, '4': 1, '5': 3, '10': 'granteeIid'},
  ],
};

/// Descriptor for `ReqSiteGrantDelete`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqSiteGrantDeleteDescriptor = $convert.base64Decode(
    'ChJSZXFTaXRlR3JhbnREZWxldGUSGQoIc2l0ZV9paWQYASABKANSB3NpdGVJaWQSHwoLZ3Jhbn'
    'RlZV9paWQYAiABKANSCmdyYW50ZWVJaWQ=');

@$core.Deprecated('Use resSiteGrantDeleteDescriptor instead')
const ResSiteGrantDelete$json = {
  '1': 'ResSiteGrantDelete',
  '2': [
    {'1': 'grantee_iid', '3': 1, '4': 1, '5': 3, '10': 'granteeIid'},
    {'1': 'ok', '3': 2, '4': 1, '5': 8, '10': 'ok'},
  ],
};

/// Descriptor for `ResSiteGrantDelete`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resSiteGrantDeleteDescriptor = $convert.base64Decode(
    'ChJSZXNTaXRlR3JhbnREZWxldGUSHwoLZ3JhbnRlZV9paWQYASABKANSCmdyYW50ZWVJaWQSDg'
    'oCb2sYAiABKAhSAm9r');

@$core.Deprecated('Use siteQueueDescriptor instead')
const SiteQueue$json = {
  '1': 'SiteQueue',
  '2': [
    {'1': 'site_iid', '3': 1, '4': 1, '5': 3, '10': 'siteIid'},
    {'1': 'queue_id', '3': 2, '4': 1, '5': 3, '10': 'queueId'},
    {'1': 'owner_iid', '3': 3, '4': 1, '5': 3, '10': 'ownerIid'},
    {'1': 'name', '3': 4, '4': 1, '5': 9, '10': 'name'},
    {'1': 'mode', '3': 5, '4': 1, '5': 9, '10': 'mode'},
    {'1': 'prefix', '3': 6, '4': 1, '5': 9, '10': 'prefix'},
    {'1': 'last_ticket_no', '3': 7, '4': 1, '5': 5, '10': 'lastTicketNo'},
    {'1': 'serving_ticket_no', '3': 8, '4': 1, '5': 5, '10': 'servingTicketNo'},
    {'1': 'is_active', '3': 9, '4': 1, '5': 8, '10': 'isActive'},
    {'1': 'meta_json', '3': 10, '4': 1, '5': 9, '10': 'metaJson'},
    {'1': 'created_ts_ms', '3': 20, '4': 1, '5': 3, '10': 'createdTsMs'},
    {'1': 'updated_ts_ms', '3': 21, '4': 1, '5': 3, '10': 'updatedTsMs'},
    {'1': 'deleted_ts_ms', '3': 22, '4': 1, '5': 3, '10': 'deletedTsMs'},
  ],
};

/// Descriptor for `SiteQueue`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List siteQueueDescriptor = $convert.base64Decode(
    'CglTaXRlUXVldWUSGQoIc2l0ZV9paWQYASABKANSB3NpdGVJaWQSGQoIcXVldWVfaWQYAiABKA'
    'NSB3F1ZXVlSWQSGwoJb3duZXJfaWlkGAMgASgDUghvd25lcklpZBISCgRuYW1lGAQgASgJUgRu'
    'YW1lEhIKBG1vZGUYBSABKAlSBG1vZGUSFgoGcHJlZml4GAYgASgJUgZwcmVmaXgSJAoObGFzdF'
    '90aWNrZXRfbm8YByABKAVSDGxhc3RUaWNrZXRObxIqChFzZXJ2aW5nX3RpY2tldF9ubxgIIAEo'
    'BVIPc2VydmluZ1RpY2tldE5vEhsKCWlzX2FjdGl2ZRgJIAEoCFIIaXNBY3RpdmUSGwoJbWV0YV'
    '9qc29uGAogASgJUghtZXRhSnNvbhIiCg1jcmVhdGVkX3RzX21zGBQgASgDUgtjcmVhdGVkVHNN'
    'cxIiCg11cGRhdGVkX3RzX21zGBUgASgDUgt1cGRhdGVkVHNNcxIiCg1kZWxldGVkX3RzX21zGB'
    'YgASgDUgtkZWxldGVkVHNNcw==');

@$core.Deprecated('Use reqSiteQueueListDescriptor instead')
const ReqSiteQueueList$json = {
  '1': 'ReqSiteQueueList',
  '2': [
    {'1': 'site_iid', '3': 1, '4': 1, '5': 3, '10': 'siteIid'},
  ],
};

/// Descriptor for `ReqSiteQueueList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqSiteQueueListDescriptor = $convert.base64Decode(
    'ChBSZXFTaXRlUXVldWVMaXN0EhkKCHNpdGVfaWlkGAEgASgDUgdzaXRlSWlk');

@$core.Deprecated('Use resSiteQueueListDescriptor instead')
const ResSiteQueueList$json = {
  '1': 'ResSiteQueueList',
  '2': [
    {
      '1': 'queues',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.c35.SiteQueue',
      '10': 'queues'
    },
  ],
};

/// Descriptor for `ResSiteQueueList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resSiteQueueListDescriptor = $convert.base64Decode(
    'ChBSZXNTaXRlUXVldWVMaXN0EiYKBnF1ZXVlcxgBIAMoCzIOLmMzNS5TaXRlUXVldWVSBnF1ZX'
    'Vlcw==');

@$core.Deprecated('Use reqSiteQueuePutDescriptor instead')
const ReqSiteQueuePut$json = {
  '1': 'ReqSiteQueuePut',
  '2': [
    {'1': 'site_iid', '3': 1, '4': 1, '5': 3, '10': 'siteIid'},
    {
      '1': 'queue',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.c35.SiteQueue',
      '10': 'queue'
    },
  ],
};

/// Descriptor for `ReqSiteQueuePut`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqSiteQueuePutDescriptor = $convert.base64Decode(
    'Cg9SZXFTaXRlUXVldWVQdXQSGQoIc2l0ZV9paWQYASABKANSB3NpdGVJaWQSJAoFcXVldWUYAi'
    'ABKAsyDi5jMzUuU2l0ZVF1ZXVlUgVxdWV1ZQ==');

@$core.Deprecated('Use resSiteQueuePutDescriptor instead')
const ResSiteQueuePut$json = {
  '1': 'ResSiteQueuePut',
  '2': [
    {'1': 'queue_id', '3': 1, '4': 1, '5': 3, '10': 'queueId'},
  ],
};

/// Descriptor for `ResSiteQueuePut`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resSiteQueuePutDescriptor = $convert.base64Decode(
    'Cg9SZXNTaXRlUXVldWVQdXQSGQoIcXVldWVfaWQYASABKANSB3F1ZXVlSWQ=');

@$core.Deprecated('Use reqSiteQueueAdvanceDescriptor instead')
const ReqSiteQueueAdvance$json = {
  '1': 'ReqSiteQueueAdvance',
  '2': [
    {'1': 'site_iid', '3': 1, '4': 1, '5': 3, '10': 'siteIid'},
    {'1': 'queue_id', '3': 2, '4': 1, '5': 3, '10': 'queueId'},
  ],
};

/// Descriptor for `ReqSiteQueueAdvance`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqSiteQueueAdvanceDescriptor = $convert.base64Decode(
    'ChNSZXFTaXRlUXVldWVBZHZhbmNlEhkKCHNpdGVfaWlkGAEgASgDUgdzaXRlSWlkEhkKCHF1ZX'
    'VlX2lkGAIgASgDUgdxdWV1ZUlk');

@$core.Deprecated('Use resSiteQueueAdvanceDescriptor instead')
const ResSiteQueueAdvance$json = {
  '1': 'ResSiteQueueAdvance',
  '2': [
    {'1': 'serving_ticket_no', '3': 1, '4': 1, '5': 5, '10': 'servingTicketNo'},
  ],
};

/// Descriptor for `ResSiteQueueAdvance`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resSiteQueueAdvanceDescriptor = $convert.base64Decode(
    'ChNSZXNTaXRlUXVldWVBZHZhbmNlEioKEXNlcnZpbmdfdGlja2V0X25vGAEgASgFUg9zZXJ2aW'
    '5nVGlja2V0Tm8=');
