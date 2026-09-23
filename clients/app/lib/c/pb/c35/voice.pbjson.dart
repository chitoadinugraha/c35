// This is a generated file - do not edit.
//
// Generated from c35/voice.proto.

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

@$core.Deprecated('Use reqVoiceSttDescriptor instead')
const ReqVoiceStt$json = {
  '1': 'ReqVoiceStt',
  '2': [
    {'1': 'audio', '3': 1, '4': 1, '5': 12, '10': 'audio'},
    {'1': 'mime', '3': 2, '4': 1, '5': 9, '10': 'mime'},
    {'1': 'lang', '3': 3, '4': 1, '5': 9, '10': 'lang'},
    {'1': 'req_id', '3': 4, '4': 1, '5': 9, '10': 'reqId'},
  ],
};

/// Descriptor for `ReqVoiceStt`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqVoiceSttDescriptor = $convert.base64Decode(
    'CgtSZXFWb2ljZVN0dBIUCgVhdWRpbxgBIAEoDFIFYXVkaW8SEgoEbWltZRgCIAEoCVIEbWltZR'
    'ISCgRsYW5nGAMgASgJUgRsYW5nEhUKBnJlcV9pZBgEIAEoCVIFcmVxSWQ=');

@$core.Deprecated('Use resVoiceSttDescriptor instead')
const ResVoiceStt$json = {
  '1': 'ResVoiceStt',
  '2': [
    {'1': 'text', '3': 1, '4': 1, '5': 9, '10': 'text'},
    {'1': 'error', '3': 2, '4': 1, '5': 9, '10': 'error'},
  ],
};

/// Descriptor for `ResVoiceStt`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resVoiceSttDescriptor = $convert.base64Decode(
    'CgtSZXNWb2ljZVN0dBISCgR0ZXh0GAEgASgJUgR0ZXh0EhQKBWVycm9yGAIgASgJUgVlcnJvcg'
    '==');

@$core.Deprecated('Use reqVoiceTtsDescriptor instead')
const ReqVoiceTts$json = {
  '1': 'ReqVoiceTts',
  '2': [
    {'1': 'text', '3': 1, '4': 1, '5': 9, '10': 'text'},
    {'1': 'lang', '3': 2, '4': 1, '5': 9, '10': 'lang'},
    {'1': 'req_id', '3': 3, '4': 1, '5': 9, '10': 'reqId'},
  ],
};

/// Descriptor for `ReqVoiceTts`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqVoiceTtsDescriptor = $convert.base64Decode(
    'CgtSZXFWb2ljZVR0cxISCgR0ZXh0GAEgASgJUgR0ZXh0EhIKBGxhbmcYAiABKAlSBGxhbmcSFQ'
    'oGcmVxX2lkGAMgASgJUgVyZXFJZA==');

@$core.Deprecated('Use resVoiceTtsDescriptor instead')
const ResVoiceTts$json = {
  '1': 'ResVoiceTts',
  '2': [
    {'1': 'audio', '3': 1, '4': 1, '5': 12, '10': 'audio'},
    {'1': 'mime', '3': 2, '4': 1, '5': 9, '10': 'mime'},
    {'1': 'error', '3': 3, '4': 1, '5': 9, '10': 'error'},
  ],
};

/// Descriptor for `ResVoiceTts`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resVoiceTtsDescriptor = $convert.base64Decode(
    'CgtSZXNWb2ljZVR0cxIUCgVhdWRpbxgBIAEoDFIFYXVkaW8SEgoEbWltZRgCIAEoCVIEbWltZR'
    'IUCgVlcnJvchgDIAEoCVIFZXJyb3I=');
