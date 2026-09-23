// This is a generated file - do not edit.
//
// Generated from c35/collection.proto.

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

@$core.Deprecated('Use colTypeDescriptor instead')
const ColType$json = {
  '1': 'ColType',
  '2': [
    {'1': 'COL_TYPE_UNSPECIFIED', '2': 0},
    {'1': 'COL_TYPE_TEXT', '2': 1},
    {'1': 'COL_TYPE_INT', '2': 2},
    {'1': 'COL_TYPE_MONEY', '2': 3},
    {'1': 'COL_TYPE_BOOL', '2': 4},
    {'1': 'COL_TYPE_PIC', '2': 5},
    {'1': 'COL_TYPE_JSON', '2': 6},
    {'1': 'COL_TYPE_REF', '2': 7},
    {'1': 'COL_TYPE_TS', '2': 8},
  ],
};

/// Descriptor for `ColType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List colTypeDescriptor = $convert.base64Decode(
    'CgdDb2xUeXBlEhgKFENPTF9UWVBFX1VOU1BFQ0lGSUVEEAASEQoNQ09MX1RZUEVfVEVYVBABEh'
    'AKDENPTF9UWVBFX0lOVBACEhIKDkNPTF9UWVBFX01PTkVZEAMSEQoNQ09MX1RZUEVfQk9PTBAE'
    'EhAKDENPTF9UWVBFX1BJQxAFEhEKDUNPTF9UWVBFX0pTT04QBhIQCgxDT0xfVFlQRV9SRUYQBx'
    'IPCgtDT0xfVFlQRV9UUxAI');

@$core.Deprecated('Use colDefDescriptor instead')
const ColDef$json = {
  '1': 'ColDef',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'label', '3': 2, '4': 1, '5': 9, '10': 'label'},
    {'1': 'type', '3': 3, '4': 1, '5': 14, '6': '.c35.ColType', '10': 'type'},
    {'1': 'readonly', '3': 4, '4': 1, '5': 8, '10': 'readonly'},
    {'1': 'required', '3': 5, '4': 1, '5': 8, '10': 'required'},
    {'1': 'ref_collection', '3': 6, '4': 1, '5': 9, '10': 'refCollection'},
    {'1': 'inline_editable', '3': 7, '4': 1, '5': 8, '10': 'inlineEditable'},
  ],
};

/// Descriptor for `ColDef`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List colDefDescriptor = $convert.base64Decode(
    'CgZDb2xEZWYSEAoDa2V5GAEgASgJUgNrZXkSFAoFbGFiZWwYAiABKAlSBWxhYmVsEiAKBHR5cG'
    'UYAyABKA4yDC5jMzUuQ29sVHlwZVIEdHlwZRIaCghyZWFkb25seRgEIAEoCFIIcmVhZG9ubHkS'
    'GgoIcmVxdWlyZWQYBSABKAhSCHJlcXVpcmVkEiUKDnJlZl9jb2xsZWN0aW9uGAYgASgJUg1yZW'
    'ZDb2xsZWN0aW9uEicKD2lubGluZV9lZGl0YWJsZRgHIAEoCFIOaW5saW5lRWRpdGFibGU=');

@$core.Deprecated('Use subTableDefDescriptor instead')
const SubTableDef$json = {
  '1': 'SubTableDef',
  '2': [
    {'1': 'collection', '3': 1, '4': 1, '5': 9, '10': 'collection'},
    {'1': 'label', '3': 2, '4': 1, '5': 9, '10': 'label'},
    {'1': 'fk_keys', '3': 3, '4': 3, '5': 9, '10': 'fkKeys'},
    {'1': 'sync_name', '3': 4, '4': 1, '5': 9, '10': 'syncName'},
  ],
};

/// Descriptor for `SubTableDef`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List subTableDefDescriptor = $convert.base64Decode(
    'CgtTdWJUYWJsZURlZhIeCgpjb2xsZWN0aW9uGAEgASgJUgpjb2xsZWN0aW9uEhQKBWxhYmVsGA'
    'IgASgJUgVsYWJlbBIXCgdma19rZXlzGAMgAygJUgZma0tleXMSGwoJc3luY19uYW1lGAQgASgJ'
    'UghzeW5jTmFtZQ==');

@$core.Deprecated('Use tableDefDescriptor instead')
const TableDef$json = {
  '1': 'TableDef',
  '2': [
    {'1': 'collection', '3': 1, '4': 1, '5': 9, '10': 'collection'},
    {'1': 'label', '3': 2, '4': 1, '5': 9, '10': 'label'},
    {
      '1': 'columns',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.c35.ColDef',
      '10': 'columns'
    },
    {
      '1': 'subtables',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.c35.SubTableDef',
      '10': 'subtables'
    },
    {'1': 'sync_name', '3': 5, '4': 1, '5': 9, '10': 'syncName'},
    {'1': 'site_scoped', '3': 6, '4': 1, '5': 8, '10': 'siteScoped'},
    {'1': 'primary_key', '3': 7, '4': 1, '5': 9, '10': 'primaryKey'},
  ],
};

/// Descriptor for `TableDef`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List tableDefDescriptor = $convert.base64Decode(
    'CghUYWJsZURlZhIeCgpjb2xsZWN0aW9uGAEgASgJUgpjb2xsZWN0aW9uEhQKBWxhYmVsGAIgAS'
    'gJUgVsYWJlbBIlCgdjb2x1bW5zGAMgAygLMgsuYzM1LkNvbERlZlIHY29sdW1ucxIuCglzdWJ0'
    'YWJsZXMYBCADKAsyEC5jMzUuU3ViVGFibGVEZWZSCXN1YnRhYmxlcxIbCglzeW5jX25hbWUYBS'
    'ABKAlSCHN5bmNOYW1lEh8KC3NpdGVfc2NvcGVkGAYgASgIUgpzaXRlU2NvcGVkEh8KC3ByaW1h'
    'cnlfa2V5GAcgASgJUgpwcmltYXJ5S2V5');

@$core.Deprecated('Use reqCollectionDefListDescriptor instead')
const ReqCollectionDefList$json = {
  '1': 'ReqCollectionDefList',
  '2': [
    {'1': 'site_iid', '3': 1, '4': 1, '5': 3, '10': 'siteIid'},
  ],
};

/// Descriptor for `ReqCollectionDefList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqCollectionDefListDescriptor =
    $convert.base64Decode(
        'ChRSZXFDb2xsZWN0aW9uRGVmTGlzdBIZCghzaXRlX2lpZBgBIAEoA1IHc2l0ZUlpZA==');

@$core.Deprecated('Use resCollectionDefListDescriptor instead')
const ResCollectionDefList$json = {
  '1': 'ResCollectionDefList',
  '2': [
    {
      '1': 'tables',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.c35.TableDef',
      '10': 'tables'
    },
  ],
};

/// Descriptor for `ResCollectionDefList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resCollectionDefListDescriptor = $convert.base64Decode(
    'ChRSZXNDb2xsZWN0aW9uRGVmTGlzdBIlCgZ0YWJsZXMYASADKAsyDS5jMzUuVGFibGVEZWZSBn'
    'RhYmxlcw==');
