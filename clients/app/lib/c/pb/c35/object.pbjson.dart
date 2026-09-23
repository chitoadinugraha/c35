// This is a generated file - do not edit.
//
// Generated from c35/object.proto.

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

@$core.Deprecated('Use objectNormalizerDocDescriptor instead')
const ObjectNormalizerDoc$json = {
  '1': 'ObjectNormalizerDoc',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 3, '10': 'id'},
    {'1': 'slug', '3': 2, '4': 1, '5': 9, '10': 'slug'},
    {'1': 'parent_id', '3': 3, '4': 1, '5': 3, '10': 'parentId'},
    {'1': 'path', '3': 4, '4': 1, '5': 9, '10': 'path'},
    {'1': 'depth', '3': 5, '4': 1, '5': 5, '10': 'depth'},
    {'1': 'kind', '3': 6, '4': 1, '5': 9, '10': 'kind'},
  ],
};

/// Descriptor for `ObjectNormalizerDoc`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List objectNormalizerDocDescriptor = $convert.base64Decode(
    'ChNPYmplY3ROb3JtYWxpemVyRG9jEg4KAmlkGAEgASgDUgJpZBISCgRzbHVnGAIgASgJUgRzbH'
    'VnEhsKCXBhcmVudF9pZBgDIAEoA1IIcGFyZW50SWQSEgoEcGF0aBgEIAEoCVIEcGF0aBIUCgVk'
    'ZXB0aBgFIAEoBVIFZGVwdGgSEgoEa2luZBgGIAEoCVIEa2luZA==');

@$core.Deprecated('Use objectAliasDocDescriptor instead')
const ObjectAliasDoc$json = {
  '1': 'ObjectAliasDoc',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 3, '10': 'id'},
    {'1': 'obj_id', '3': 2, '4': 1, '5': 3, '10': 'objId'},
    {'1': 'lang', '3': 3, '4': 1, '5': 9, '10': 'lang'},
    {'1': 'name', '3': 4, '4': 1, '5': 9, '10': 'name'},
    {'1': 'name_norm', '3': 5, '4': 1, '5': 9, '10': 'nameNorm'},
    {'1': 'is_canonical', '3': 6, '4': 1, '5': 8, '10': 'isCanonical'},
    {'1': 'verified', '3': 7, '4': 1, '5': 8, '10': 'verified'},
    {'1': 'obj_path', '3': 8, '4': 1, '5': 9, '10': 'objPath'},
  ],
};

/// Descriptor for `ObjectAliasDoc`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List objectAliasDocDescriptor = $convert.base64Decode(
    'Cg5PYmplY3RBbGlhc0RvYxIOCgJpZBgBIAEoA1ICaWQSFQoGb2JqX2lkGAIgASgDUgVvYmpJZB'
    'ISCgRsYW5nGAMgASgJUgRsYW5nEhIKBG5hbWUYBCABKAlSBG5hbWUSGwoJbmFtZV9ub3JtGAUg'
    'ASgJUghuYW1lTm9ybRIhCgxpc19jYW5vbmljYWwYBiABKAhSC2lzQ2Fub25pY2FsEhoKCHZlcm'
    'lmaWVkGAcgASgIUgh2ZXJpZmllZBIZCghvYmpfcGF0aBgIIAEoCVIHb2JqUGF0aA==');

@$core.Deprecated('Use reqObjectAliasListDescriptor instead')
const ReqObjectAliasList$json = {
  '1': 'ReqObjectAliasList',
  '2': [
    {
      '1': 'verified',
      '3': 1,
      '4': 1,
      '5': 8,
      '9': 0,
      '10': 'verified',
      '17': true
    },
    {'1': 'lang', '3': 2, '4': 1, '5': 9, '9': 1, '10': 'lang', '17': true},
    {'1': 'q', '3': 3, '4': 1, '5': 9, '9': 2, '10': 'q', '17': true},
    {'1': 'limit', '3': 4, '4': 1, '5': 5, '10': 'limit'},
  ],
  '8': [
    {'1': '_verified'},
    {'1': '_lang'},
    {'1': '_q'},
  ],
};

/// Descriptor for `ReqObjectAliasList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqObjectAliasListDescriptor = $convert.base64Decode(
    'ChJSZXFPYmplY3RBbGlhc0xpc3QSHwoIdmVyaWZpZWQYASABKAhIAFIIdmVyaWZpZWSIAQESFw'
    'oEbGFuZxgCIAEoCUgBUgRsYW5niAEBEhEKAXEYAyABKAlIAlIBcYgBARIUCgVsaW1pdBgEIAEo'
    'BVIFbGltaXRCCwoJX3ZlcmlmaWVkQgcKBV9sYW5nQgQKAl9x');

@$core.Deprecated('Use resObjectAliasListDescriptor instead')
const ResObjectAliasList$json = {
  '1': 'ResObjectAliasList',
  '2': [
    {
      '1': 'items',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.c35.ObjectAliasDoc',
      '10': 'items'
    },
  ],
};

/// Descriptor for `ResObjectAliasList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resObjectAliasListDescriptor = $convert.base64Decode(
    'ChJSZXNPYmplY3RBbGlhc0xpc3QSKQoFaXRlbXMYASADKAsyEy5jMzUuT2JqZWN0QWxpYXNEb2'
    'NSBWl0ZW1z');

@$core.Deprecated('Use reqObjectAliasPutDescriptor instead')
const ReqObjectAliasPut$json = {
  '1': 'ReqObjectAliasPut',
  '2': [
    {
      '1': 'doc',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.c35.ObjectAliasDoc',
      '10': 'doc'
    },
  ],
};

/// Descriptor for `ReqObjectAliasPut`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqObjectAliasPutDescriptor = $convert.base64Decode(
    'ChFSZXFPYmplY3RBbGlhc1B1dBIlCgNkb2MYASABKAsyEy5jMzUuT2JqZWN0QWxpYXNEb2NSA2'
    'RvYw==');

@$core.Deprecated('Use resObjectAliasPutDescriptor instead')
const ResObjectAliasPut$json = {
  '1': 'ResObjectAliasPut',
  '2': [
    {
      '1': 'doc',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.c35.ObjectAliasDoc',
      '10': 'doc'
    },
  ],
};

/// Descriptor for `ResObjectAliasPut`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resObjectAliasPutDescriptor = $convert.base64Decode(
    'ChFSZXNPYmplY3RBbGlhc1B1dBIlCgNkb2MYASABKAsyEy5jMzUuT2JqZWN0QWxpYXNEb2NSA2'
    'RvYw==');

@$core.Deprecated('Use reqObjectNormalizerListDescriptor instead')
const ReqObjectNormalizerList$json = {
  '1': 'ReqObjectNormalizerList',
  '2': [
    {'1': 'q', '3': 1, '4': 1, '5': 9, '9': 0, '10': 'q', '17': true},
    {'1': 'limit', '3': 2, '4': 1, '5': 5, '10': 'limit'},
  ],
  '8': [
    {'1': '_q'},
  ],
};

/// Descriptor for `ReqObjectNormalizerList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqObjectNormalizerListDescriptor =
    $convert.base64Decode(
        'ChdSZXFPYmplY3ROb3JtYWxpemVyTGlzdBIRCgFxGAEgASgJSABSAXGIAQESFAoFbGltaXQYAi'
        'ABKAVSBWxpbWl0QgQKAl9x');

@$core.Deprecated('Use resObjectNormalizerListDescriptor instead')
const ResObjectNormalizerList$json = {
  '1': 'ResObjectNormalizerList',
  '2': [
    {
      '1': 'items',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.c35.ObjectNormalizerDoc',
      '10': 'items'
    },
  ],
};

/// Descriptor for `ResObjectNormalizerList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resObjectNormalizerListDescriptor =
    $convert.base64Decode(
        'ChdSZXNPYmplY3ROb3JtYWxpemVyTGlzdBIuCgVpdGVtcxgBIAMoCzIYLmMzNS5PYmplY3ROb3'
        'JtYWxpemVyRG9jUgVpdGVtcw==');
