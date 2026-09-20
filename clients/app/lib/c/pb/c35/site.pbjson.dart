//
//  Generated code. Do not modify.
//  source: c35/site.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

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
    {'1': 'blocks', '3': 3, '4': 3, '5': 11, '6': '.c35.SiteBlock', '10': 'blocks'},
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
    {'1': 'pages', '3': 1, '4': 3, '5': 11, '6': '.c35.SitePage', '10': 'pages'},
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
    {'1': 'published_version_id', '3': 3, '4': 1, '5': 9, '10': 'publishedVersionId'},
    {'1': 'inventory_costing_method', '3': 4, '4': 1, '5': 9, '10': 'inventoryCostingMethod'},
    {'1': 'tz', '3': 5, '4': 1, '5': 9, '10': 'tz'},
    {'1': 'payroll_policy_json', '3': 6, '4': 1, '5': 9, '10': 'payrollPolicyJson'},
    {'1': 'presence_policy_json', '3': 7, '4': 1, '5': 9, '10': 'presencePolicyJson'},
    {'1': 'capabilities_json', '3': 8, '4': 1, '5': 9, '10': 'capabilitiesJson'},
    {'1': 'alien_id_changed_ts_ms', '3': 9, '4': 1, '5': 3, '10': 'alienIdChangedTsMs'},
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
    'EoA1IMdmVyaWZpZWRUc01zEiIKDWNyZWF0ZWRfdHNfbXMYFCABKANSC2NyZWF0ZWRUc01zEiIK'
    'DXVwZGF0ZWRfdHNfbXMYFSABKANSC3VwZGF0ZWRUc01zEiIKDWRlbGV0ZWRfdHNfbXMYFiABKA'
    'NSC2RlbGV0ZWRUc01z');

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
    'ZBIiCg1jcmVhdGVkX3RzX21zGBQgASgDUgtjcmVhdGVkVHNNcxIiCg11cGRhdGVkX3RzX21zGB'
    'UgASgDUgt1cGRhdGVkVHNNcxIiCg1kZWxldGVkX3RzX21zGBYgASgDUgtkZWxldGVkVHNNcw==');

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
    {'1': 'published_version_id', '3': 5, '4': 1, '5': 9, '10': 'publishedVersionId'},
    {'1': 'updated_ts_ms', '3': 6, '4': 1, '5': 3, '10': 'updatedTsMs'},
    {'1': 'is_archived', '3': 7, '4': 1, '5': 8, '10': 'isArchived'},
  ],
};

/// Descriptor for `SiteRow`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List siteRowDescriptor = $convert.base64Decode(
    'CgdTaXRlUm93EhkKCHNpdGVfaWlkGAEgASgDUgdzaXRlSWlkEhkKCGFsaWVuX2lkGAIgASgJUg'
    'dhbGllbklkEhIKBG5hbWUYAyABKAlSBG5hbWUSEAoDcGljGAQgASgJUgNwaWMSMAoUcHVibGlz'
    'aGVkX3ZlcnNpb25faWQYBSABKAlSEnB1Ymxpc2hlZFZlcnNpb25JZBIiCg11cGRhdGVkX3RzX2'
    '1zGAYgASgDUgt1cGRhdGVkVHNNcxIfCgtpc19hcmNoaXZlZBgHIAEoCFIKaXNBcmNoaXZlZA==');

@$core.Deprecated('Use reqSiteListDescriptor instead')
const ReqSiteList$json = {
  '1': 'ReqSiteList',
  '2': [
    {'1': 'archived', '3': 1, '4': 1, '5': 8, '10': 'archived'},
  ],
};

/// Descriptor for `ReqSiteList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqSiteListDescriptor = $convert.base64Decode(
    'CgtSZXFTaXRlTGlzdBIaCghhcmNoaXZlZBgBIAEoCFIIYXJjaGl2ZWQ=');

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
    {'1': 'draft', '3': 1, '4': 1, '5': 11, '6': '.c35.SiteDraft', '10': 'draft'},
    {'1': 'config', '3': 2, '4': 1, '5': 11, '6': '.c35.SiteConfig', '10': 'config'},
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
    {'1': 'draft', '3': 1, '4': 1, '5': 11, '6': '.c35.SiteDraft', '10': 'draft'},
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
    {'1': 'publish', '3': 1, '4': 1, '5': 11, '6': '.c35.SitePublish', '10': 'publish'},
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
final $typed_data.Uint8List reqSiteProductListDescriptor = $convert.base64Decode(
    'ChJSZXFTaXRlUHJvZHVjdExpc3QSGQoIc2l0ZV9paWQYASABKANSB3NpdGVJaWQ=');

@$core.Deprecated('Use resSiteProductListDescriptor instead')
const ResSiteProductList$json = {
  '1': 'ResSiteProductList',
  '2': [
    {'1': 'products', '3': 1, '4': 3, '5': 11, '6': '.c35.SiteProduct', '10': 'products'},
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
    {'1': 'product', '3': 2, '4': 1, '5': 11, '6': '.c35.SiteProduct', '10': 'product'},
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
    {'1': 'contacts', '3': 1, '4': 3, '5': 11, '6': '.c35.SiteContact', '10': 'contacts'},
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
    {'1': 'contact', '3': 2, '4': 1, '5': 11, '6': '.c35.SiteContact', '10': 'contact'},
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
    {'1': 'objs', '3': 1, '4': 3, '5': 11, '6': '.c35.SiteObject', '10': 'objs'},
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
final $typed_data.Uint8List resSiteObjectPutDescriptor = $convert.base64Decode(
    'ChBSZXNTaXRlT2JqZWN0UHV0Eg4KAmlkGAEgASgDUgJpZA==');

