// This is a generated file - do not edit.
//
// Generated from c35/live.proto.

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

@$core.Deprecated('Use liveOfferDescriptor instead')
const LiveOffer$json = {
  '1': 'LiveOffer',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'family', '3': 2, '4': 1, '5': 9, '10': 'family'},
    {'1': 'label', '3': 3, '4': 1, '5': 9, '10': 'label'},
    {'1': 'label_key', '3': 4, '4': 1, '5': 9, '10': 'labelKey'},
    {'1': 'provider', '3': 5, '4': 1, '5': 9, '10': 'provider'},
    {'1': 'enabled', '3': 6, '4': 1, '5': 8, '10': 'enabled'},
    {
      '1': 'retail_usd_per_min',
      '3': 7,
      '4': 1,
      '5': 1,
      '10': 'retailUsdPerMin'
    },
    {'1': 'input_usd_per_min', '3': 8, '4': 1, '5': 1, '10': 'inputUsdPerMin'},
    {
      '1': 'output_usd_per_min',
      '3': 9,
      '4': 1,
      '5': 1,
      '10': 'outputUsdPerMin'
    },
    {
      '1': 'retail_video_usd_per_min',
      '3': 10,
      '4': 1,
      '5': 1,
      '10': 'retailVideoUsdPerMin'
    },
  ],
};

/// Descriptor for `LiveOffer`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List liveOfferDescriptor = $convert.base64Decode(
    'CglMaXZlT2ZmZXISDgoCaWQYASABKAlSAmlkEhYKBmZhbWlseRgCIAEoCVIGZmFtaWx5EhQKBW'
    'xhYmVsGAMgASgJUgVsYWJlbBIbCglsYWJlbF9rZXkYBCABKAlSCGxhYmVsS2V5EhoKCHByb3Zp'
    'ZGVyGAUgASgJUghwcm92aWRlchIYCgdlbmFibGVkGAYgASgIUgdlbmFibGVkEisKEnJldGFpbF'
    '91c2RfcGVyX21pbhgHIAEoAVIPcmV0YWlsVXNkUGVyTWluEikKEWlucHV0X3VzZF9wZXJfbWlu'
    'GAggASgBUg5pbnB1dFVzZFBlck1pbhIrChJvdXRwdXRfdXNkX3Blcl9taW4YCSABKAFSD291dH'
    'B1dFVzZFBlck1pbhI2ChhyZXRhaWxfdmlkZW9fdXNkX3Blcl9taW4YCiABKAFSFHJldGFpbFZp'
    'ZGVvVXNkUGVyTWlu');

@$core.Deprecated('Use liveCatalogDescriptor instead')
const LiveCatalog$json = {
  '1': 'LiveCatalog',
  '2': [
    {'1': 'updated_ts_ms', '3': 1, '4': 1, '5': 3, '10': 'updatedTsMs'},
    {
      '1': 'offers',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.c35.LiveOffer',
      '10': 'offers'
    },
  ],
};

/// Descriptor for `LiveCatalog`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List liveCatalogDescriptor = $convert.base64Decode(
    'CgtMaXZlQ2F0YWxvZxIiCg11cGRhdGVkX3RzX21zGAEgASgDUgt1cGRhdGVkVHNNcxImCgZvZm'
    'ZlcnMYAiADKAsyDi5jMzUuTGl2ZU9mZmVyUgZvZmZlcnM=');

@$core.Deprecated('Use reqLiveStartDescriptor instead')
const ReqLiveStart$json = {
  '1': 'ReqLiveStart',
  '2': [
    {'1': 'offer_id', '3': 1, '4': 1, '5': 9, '10': 'offerId'},
    {'1': 'locale', '3': 2, '4': 1, '5': 9, '10': 'locale'},
    {'1': 'req_id', '3': 3, '4': 1, '5': 9, '10': 'reqId'},
    {'1': 'chat_id', '3': 4, '4': 1, '5': 3, '10': 'chatId'},
    {'1': 'mention_ids', '3': 5, '4': 3, '5': 9, '10': 'mentionIds'},
  ],
};

/// Descriptor for `ReqLiveStart`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqLiveStartDescriptor = $convert.base64Decode(
    'CgxSZXFMaXZlU3RhcnQSGQoIb2ZmZXJfaWQYASABKAlSB29mZmVySWQSFgoGbG9jYWxlGAIgAS'
    'gJUgZsb2NhbGUSFQoGcmVxX2lkGAMgASgJUgVyZXFJZBIXCgdjaGF0X2lkGAQgASgDUgZjaGF0'
    'SWQSHwoLbWVudGlvbl9pZHMYBSADKAlSCm1lbnRpb25JZHM=');

@$core.Deprecated('Use resLiveStartDescriptor instead')
const ResLiveStart$json = {
  '1': 'ResLiveStart',
  '2': [
    {'1': 'error', '3': 1, '4': 1, '5': 9, '10': 'error'},
    {'1': 'live_session_id', '3': 2, '4': 1, '5': 9, '10': 'liveSessionId'},
    {'1': 'ws_path', '3': 3, '4': 1, '5': 9, '10': 'wsPath'},
  ],
};

/// Descriptor for `ResLiveStart`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resLiveStartDescriptor = $convert.base64Decode(
    'CgxSZXNMaXZlU3RhcnQSFAoFZXJyb3IYASABKAlSBWVycm9yEiYKD2xpdmVfc2Vzc2lvbl9pZB'
    'gCIAEoCVINbGl2ZVNlc3Npb25JZBIXCgd3c19wYXRoGAMgASgJUgZ3c1BhdGg=');
