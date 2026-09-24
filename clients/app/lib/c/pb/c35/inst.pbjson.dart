// This is a generated file - do not edit.
//
// Generated from c35/inst.proto.

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

@$core.Deprecated('Use instDocDescriptor instead')
const InstDoc$json = {
  '1': 'InstDoc',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'scope', '3': 2, '4': 1, '5': 9, '10': 'scope'},
    {'1': 'kind', '3': 3, '4': 1, '5': 9, '10': 'kind'},
    {'1': 'topic_id', '3': 4, '4': 1, '5': 9, '10': 'topicId'},
    {'1': 'topics', '3': 5, '4': 3, '5': 9, '10': 'topics'},
    {'1': 'inst', '3': 6, '4': 1, '5': 9, '10': 'inst'},
    {'1': 'phrases', '3': 7, '4': 3, '5': 9, '10': 'phrases'},
    {'1': 'triggers', '3': 8, '4': 3, '5': 9, '10': 'triggers'},
    {'1': 'include_tools', '3': 15, '4': 3, '5': 9, '10': 'includeTools'},
    {'1': 'exclude_tools', '3': 16, '4': 3, '5': 9, '10': 'excludeTools'},
    {'1': 'priority', '3': 9, '4': 1, '5': 5, '10': 'priority'},
    {
      '1': 'enabled',
      '3': 10,
      '4': 1,
      '5': 8,
      '9': 0,
      '10': 'enabled',
      '17': true
    },
    {'1': 'def_hash', '3': 11, '4': 1, '5': 9, '10': 'defHash'},
    {'1': 'created_ts_ms', '3': 12, '4': 1, '5': 3, '10': 'createdTsMs'},
    {'1': 'updated_ts_ms', '3': 13, '4': 1, '5': 3, '10': 'updatedTsMs'},
    {
      '1': 'deleted_ts_ms',
      '3': 14,
      '4': 1,
      '5': 3,
      '9': 1,
      '10': 'deletedTsMs',
      '17': true
    },
  ],
  '8': [
    {'1': '_enabled'},
    {'1': '_deleted_ts_ms'},
  ],
};

/// Descriptor for `InstDoc`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List instDocDescriptor = $convert.base64Decode(
    'CgdJbnN0RG9jEg4KAmlkGAEgASgJUgJpZBIUCgVzY29wZRgCIAEoCVIFc2NvcGUSEgoEa2luZB'
    'gDIAEoCVIEa2luZBIZCgh0b3BpY19pZBgEIAEoCVIHdG9waWNJZBIWCgZ0b3BpY3MYBSADKAlS'
    'BnRvcGljcxISCgRpbnN0GAYgASgJUgRpbnN0EhgKB3BocmFzZXMYByADKAlSB3BocmFzZXMSGg'
    'oIdHJpZ2dlcnMYCCADKAlSCHRyaWdnZXJzEiMKDWluY2x1ZGVfdG9vbHMYDyADKAlSDGluY2x1'
    'ZGVUb29scxIjCg1leGNsdWRlX3Rvb2xzGBAgAygJUgxleGNsdWRlVG9vbHMSGgoIcHJpb3JpdH'
    'kYCSABKAVSCHByaW9yaXR5Eh0KB2VuYWJsZWQYCiABKAhIAFIHZW5hYmxlZIgBARIZCghkZWZf'
    'aGFzaBgLIAEoCVIHZGVmSGFzaBIiCg1jcmVhdGVkX3RzX21zGAwgASgDUgtjcmVhdGVkVHNNcx'
    'IiCg11cGRhdGVkX3RzX21zGA0gASgDUgt1cGRhdGVkVHNNcxInCg1kZWxldGVkX3RzX21zGA4g'
    'ASgDSAFSC2RlbGV0ZWRUc01ziAEBQgoKCF9lbmFibGVkQhAKDl9kZWxldGVkX3RzX21z');

@$core.Deprecated('Use reqInstListDescriptor instead')
const ReqInstList$json = {
  '1': 'ReqInstList',
  '2': [
    {'1': 'scope', '3': 1, '4': 1, '5': 9, '9': 0, '10': 'scope', '17': true},
    {'1': 'kind', '3': 2, '4': 1, '5': 9, '9': 1, '10': 'kind', '17': true},
    {
      '1': 'enabled',
      '3': 3,
      '4': 1,
      '5': 8,
      '9': 2,
      '10': 'enabled',
      '17': true
    },
    {'1': 'include_deleted', '3': 4, '4': 1, '5': 8, '10': 'includeDeleted'},
  ],
  '8': [
    {'1': '_scope'},
    {'1': '_kind'},
    {'1': '_enabled'},
  ],
};

/// Descriptor for `ReqInstList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqInstListDescriptor = $convert.base64Decode(
    'CgtSZXFJbnN0TGlzdBIZCgVzY29wZRgBIAEoCUgAUgVzY29wZYgBARIXCgRraW5kGAIgASgJSA'
    'FSBGtpbmSIAQESHQoHZW5hYmxlZBgDIAEoCEgCUgdlbmFibGVkiAEBEicKD2luY2x1ZGVfZGVs'
    'ZXRlZBgEIAEoCFIOaW5jbHVkZURlbGV0ZWRCCAoGX3Njb3BlQgcKBV9raW5kQgoKCF9lbmFibG'
    'Vk');

@$core.Deprecated('Use resInstListDescriptor instead')
const ResInstList$json = {
  '1': 'ResInstList',
  '2': [
    {'1': 'items', '3': 1, '4': 3, '5': 11, '6': '.c35.InstDoc', '10': 'items'},
  ],
};

/// Descriptor for `ResInstList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resInstListDescriptor = $convert.base64Decode(
    'CgtSZXNJbnN0TGlzdBIiCgVpdGVtcxgBIAMoCzIMLmMzNS5JbnN0RG9jUgVpdGVtcw==');

@$core.Deprecated('Use reqInstGetDescriptor instead')
const ReqInstGet$json = {
  '1': 'ReqInstGet',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
  ],
};

/// Descriptor for `ReqInstGet`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqInstGetDescriptor =
    $convert.base64Decode('CgpSZXFJbnN0R2V0Eg4KAmlkGAEgASgJUgJpZA==');

@$core.Deprecated('Use resInstGetDescriptor instead')
const ResInstGet$json = {
  '1': 'ResInstGet',
  '2': [
    {'1': 'item', '3': 1, '4': 1, '5': 11, '6': '.c35.InstDoc', '10': 'item'},
  ],
};

/// Descriptor for `ResInstGet`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resInstGetDescriptor = $convert.base64Decode(
    'CgpSZXNJbnN0R2V0EiAKBGl0ZW0YASABKAsyDC5jMzUuSW5zdERvY1IEaXRlbQ==');

@$core.Deprecated('Use reqInstPutDescriptor instead')
const ReqInstPut$json = {
  '1': 'ReqInstPut',
  '2': [
    {'1': 'doc', '3': 1, '4': 1, '5': 11, '6': '.c35.InstDoc', '10': 'doc'},
  ],
};

/// Descriptor for `ReqInstPut`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqInstPutDescriptor = $convert.base64Decode(
    'CgpSZXFJbnN0UHV0Eh4KA2RvYxgBIAEoCzIMLmMzNS5JbnN0RG9jUgNkb2M=');

@$core.Deprecated('Use resInstPutDescriptor instead')
const ResInstPut$json = {
  '1': 'ResInstPut',
  '2': [
    {'1': 'doc', '3': 1, '4': 1, '5': 11, '6': '.c35.InstDoc', '10': 'doc'},
  ],
};

/// Descriptor for `ResInstPut`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resInstPutDescriptor = $convert.base64Decode(
    'CgpSZXNJbnN0UHV0Eh4KA2RvYxgBIAEoCzIMLmMzNS5JbnN0RG9jUgNkb2M=');

@$core.Deprecated('Use reqInstDeleteDescriptor instead')
const ReqInstDelete$json = {
  '1': 'ReqInstDelete',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
  ],
};

/// Descriptor for `ReqInstDelete`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqInstDeleteDescriptor =
    $convert.base64Decode('Cg1SZXFJbnN0RGVsZXRlEg4KAmlkGAEgASgJUgJpZA==');

@$core.Deprecated('Use resInstDeleteDescriptor instead')
const ResInstDelete$json = {
  '1': 'ResInstDelete',
};

/// Descriptor for `ResInstDelete`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resInstDeleteDescriptor =
    $convert.base64Decode('Cg1SZXNJbnN0RGVsZXRl');
