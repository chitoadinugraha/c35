// This is a generated file - do not edit.
//
// Generated from c35/hint.proto.

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

@$core.Deprecated('Use hintActionDescriptor instead')
const HintAction$json = {
  '1': 'HintAction',
  '2': [
    {'1': 'kind', '3': 1, '4': 1, '5': 9, '10': 'kind'},
    {'1': 'payload_json', '3': 2, '4': 1, '5': 9, '10': 'payloadJson'},
  ],
};

/// Descriptor for `HintAction`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List hintActionDescriptor = $convert.base64Decode(
    'CgpIaW50QWN0aW9uEhIKBGtpbmQYASABKAlSBGtpbmQSIQoMcGF5bG9hZF9qc29uGAIgASgJUg'
    'twYXlsb2FkSnNvbg==');

@$core.Deprecated('Use hintItemDescriptor instead')
const HintItem$json = {
  '1': 'HintItem',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'label', '3': 2, '4': 1, '5': 9, '10': 'label'},
    {'1': 'icon', '3': 3, '4': 1, '5': 9, '10': 'icon'},
    {'1': 'sort', '3': 4, '4': 1, '5': 5, '10': 'sort'},
    {
      '1': 'action',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.c35.HintAction',
      '10': 'action'
    },
    {
      '1': 'items',
      '3': 6,
      '4': 3,
      '5': 11,
      '6': '.c35.HintItem',
      '10': 'items'
    },
  ],
};

/// Descriptor for `HintItem`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List hintItemDescriptor = $convert.base64Decode(
    'CghIaW50SXRlbRIOCgJpZBgBIAEoCVICaWQSFAoFbGFiZWwYAiABKAlSBWxhYmVsEhIKBGljb2'
    '4YAyABKAlSBGljb24SEgoEc29ydBgEIAEoBVIEc29ydBInCgZhY3Rpb24YBSABKAsyDy5jMzUu'
    'SGludEFjdGlvblIGYWN0aW9uEiMKBWl0ZW1zGAYgAygLMg0uYzM1LkhpbnRJdGVtUgVpdGVtcw'
    '==');

@$core.Deprecated('Use hintCatalogDescriptor instead')
const HintCatalog$json = {
  '1': 'HintCatalog',
  '2': [
    {'1': 'updated_ts_ms', '3': 1, '4': 1, '5': 3, '10': 'updatedTsMs'},
    {
      '1': 'items',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.c35.HintItem',
      '10': 'items'
    },
  ],
};

/// Descriptor for `HintCatalog`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List hintCatalogDescriptor = $convert.base64Decode(
    'CgtIaW50Q2F0YWxvZxIiCg11cGRhdGVkX3RzX21zGAEgASgDUgt1cGRhdGVkVHNNcxIjCgVpdG'
    'VtcxgCIAMoCzINLmMzNS5IaW50SXRlbVIFaXRlbXM=');

@$core.Deprecated('Use reqHintTouchDescriptor instead')
const ReqHintTouch$json = {
  '1': 'ReqHintTouch',
  '2': [
    {'1': 'asset_iid', '3': 1, '4': 1, '5': 3, '10': 'assetIid'},
    {'1': 'asset_kind', '3': 2, '4': 1, '5': 9, '10': 'assetKind'},
  ],
};

/// Descriptor for `ReqHintTouch`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqHintTouchDescriptor = $convert.base64Decode(
    'CgxSZXFIaW50VG91Y2gSGwoJYXNzZXRfaWlkGAEgASgDUghhc3NldElpZBIdCgphc3NldF9raW'
    '5kGAIgASgJUglhc3NldEtpbmQ=');

@$core.Deprecated('Use resHintTouchDescriptor instead')
const ResHintTouch$json = {
  '1': 'ResHintTouch',
  '2': [
    {'1': 'ok', '3': 1, '4': 1, '5': 8, '10': 'ok'},
  ],
};

/// Descriptor for `ResHintTouch`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resHintTouchDescriptor =
    $convert.base64Decode('CgxSZXNIaW50VG91Y2gSDgoCb2sYASABKAhSAm9r');
