// This is a generated file - do not edit.
//
// Generated from c35/device.proto.

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

@$core.Deprecated('Use reqDevicePairDescriptor instead')
const ReqDevicePair$json = {
  '1': 'ReqDevicePair',
  '2': [
    {'1': 'code', '3': 1, '4': 1, '5': 9, '10': 'code'},
  ],
};

/// Descriptor for `ReqDevicePair`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqDevicePairDescriptor =
    $convert.base64Decode('Cg1SZXFEZXZpY2VQYWlyEhIKBGNvZGUYASABKAlSBGNvZGU=');

@$core.Deprecated('Use resDevicePairDescriptor instead')
const ResDevicePair$json = {
  '1': 'ResDevicePair',
  '2': [
    {
      '1': 'device',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.c35.IdentityListRow',
      '10': 'device'
    },
  ],
};

/// Descriptor for `ResDevicePair`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resDevicePairDescriptor = $convert.base64Decode(
    'Cg1SZXNEZXZpY2VQYWlyEiwKBmRldmljZRgBIAEoCzIULmMzNS5JZGVudGl0eUxpc3RSb3dSBm'
    'RldmljZQ==');
