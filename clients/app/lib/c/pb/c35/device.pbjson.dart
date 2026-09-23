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

@$core.Deprecated('Use reqDevicePairRegisterDescriptor instead')
const ReqDevicePairRegister$json = {
  '1': 'ReqDevicePairRegister',
  '2': [
    {'1': 'device_name', '3': 1, '4': 1, '5': 9, '10': 'deviceName'},
    {'1': 'device_type', '3': 2, '4': 1, '5': 9, '10': 'deviceType'},
  ],
};

/// Descriptor for `ReqDevicePairRegister`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqDevicePairRegisterDescriptor = $convert.base64Decode(
    'ChVSZXFEZXZpY2VQYWlyUmVnaXN0ZXISHwoLZGV2aWNlX25hbWUYASABKAlSCmRldmljZU5hbW'
    'USHwoLZGV2aWNlX3R5cGUYAiABKAlSCmRldmljZVR5cGU=');

@$core.Deprecated('Use resDevicePairRegisterDescriptor instead')
const ResDevicePairRegister$json = {
  '1': 'ResDevicePairRegister',
  '2': [
    {'1': 'code', '3': 1, '4': 1, '5': 9, '10': 'code'},
    {'1': 'device_secret', '3': 2, '4': 1, '5': 9, '10': 'deviceSecret'},
    {'1': 'expires_in_sec', '3': 3, '4': 1, '5': 3, '10': 'expiresInSec'},
  ],
};

/// Descriptor for `ResDevicePairRegister`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resDevicePairRegisterDescriptor = $convert.base64Decode(
    'ChVSZXNEZXZpY2VQYWlyUmVnaXN0ZXISEgoEY29kZRgBIAEoCVIEY29kZRIjCg1kZXZpY2Vfc2'
    'VjcmV0GAIgASgJUgxkZXZpY2VTZWNyZXQSJAoOZXhwaXJlc19pbl9zZWMYAyABKANSDGV4cGly'
    'ZXNJblNlYw==');

@$core.Deprecated('Use reqDevicePairPollDescriptor instead')
const ReqDevicePairPoll$json = {
  '1': 'ReqDevicePairPoll',
  '2': [
    {'1': 'device_secret', '3': 1, '4': 1, '5': 9, '10': 'deviceSecret'},
  ],
};

/// Descriptor for `ReqDevicePairPoll`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqDevicePairPollDescriptor = $convert.base64Decode(
    'ChFSZXFEZXZpY2VQYWlyUG9sbBIjCg1kZXZpY2Vfc2VjcmV0GAEgASgJUgxkZXZpY2VTZWNyZX'
    'Q=');

@$core.Deprecated('Use resDevicePairPollDescriptor instead')
const ResDevicePairPoll$json = {
  '1': 'ResDevicePairPoll',
  '2': [
    {'1': 'status', '3': 2, '4': 1, '5': 9, '10': 'status'},
    {'1': 'session_key', '3': 3, '4': 1, '5': 9, '10': 'sessionKey'},
    {'1': 'device_iid', '3': 4, '4': 1, '5': 3, '10': 'deviceIid'},
  ],
};

/// Descriptor for `ResDevicePairPoll`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resDevicePairPollDescriptor = $convert.base64Decode(
    'ChFSZXNEZXZpY2VQYWlyUG9sbBIWCgZzdGF0dXMYAiABKAlSBnN0YXR1cxIfCgtzZXNzaW9uX2'
    'tleRgDIAEoCVIKc2Vzc2lvbktleRIdCgpkZXZpY2VfaWlkGAQgASgDUglkZXZpY2VJaWQ=');
