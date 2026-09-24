// This is a generated file - do not edit.
//
// Generated from c35/field.proto.

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

@$core.Deprecated('Use fieldTypeDescriptor instead')
const FieldType$json = {
  '1': 'FieldType',
  '2': [
    {'1': 'FIELD_TYPE_UNSPECIFIED', '2': 0},
    {'1': 'FIELD_TYPE_TEXT', '2': 1},
    {'1': 'FIELD_TYPE_INT', '2': 2},
    {'1': 'FIELD_TYPE_MONEY', '2': 3},
    {'1': 'FIELD_TYPE_BOOL', '2': 4},
    {'1': 'FIELD_TYPE_PIC', '2': 5},
    {'1': 'FIELD_TYPE_JSON', '2': 6},
    {'1': 'FIELD_TYPE_REF', '2': 7},
    {'1': 'FIELD_TYPE_TS', '2': 8},
  ],
};

/// Descriptor for `FieldType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List fieldTypeDescriptor = $convert.base64Decode(
    'CglGaWVsZFR5cGUSGgoWRklFTERfVFlQRV9VTlNQRUNJRklFRBAAEhMKD0ZJRUxEX1RZUEVfVE'
    'VYVBABEhIKDkZJRUxEX1RZUEVfSU5UEAISFAoQRklFTERfVFlQRV9NT05FWRADEhMKD0ZJRUxE'
    'X1RZUEVfQk9PTBAEEhIKDkZJRUxEX1RZUEVfUElDEAUSEwoPRklFTERfVFlQRV9KU09OEAYSEg'
    'oORklFTERfVFlQRV9SRUYQBxIRCg1GSUVMRF9UWVBFX1RTEAg=');

@$core.Deprecated('Use fieldDescriptor instead')
const Field$json = {
  '1': 'Field',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'label', '3': 2, '4': 1, '5': 9, '10': 'label'},
    {'1': 'desc', '3': 3, '4': 1, '5': 9, '10': 'desc'},
    {'1': 'type', '3': 4, '4': 1, '5': 14, '6': '.c35.FieldType', '10': 'type'},
    {'1': 'optional', '3': 5, '4': 1, '5': 8, '10': 'optional'},
    {'1': 'def', '3': 6, '4': 1, '5': 9, '10': 'def'},
    {'1': 'ref_collection', '3': 7, '4': 1, '5': 9, '10': 'refCollection'},
    {'1': 'group', '3': 8, '4': 1, '5': 9, '10': 'group'},
  ],
};

/// Descriptor for `Field`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fieldDescriptor = $convert.base64Decode(
    'CgVGaWVsZBIQCgNrZXkYASABKAlSA2tleRIUCgVsYWJlbBgCIAEoCVIFbGFiZWwSEgoEZGVzYx'
    'gDIAEoCVIEZGVzYxIiCgR0eXBlGAQgASgOMg4uYzM1LkZpZWxkVHlwZVIEdHlwZRIaCghvcHRp'
    'b25hbBgFIAEoCFIIb3B0aW9uYWwSEAoDZGVmGAYgASgJUgNkZWYSJQoOcmVmX2NvbGxlY3Rpb2'
    '4YByABKAlSDXJlZkNvbGxlY3Rpb24SFAoFZ3JvdXAYCCABKAlSBWdyb3Vw');
