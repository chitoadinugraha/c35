// This is a generated file - do not edit.
//
// Generated from c35/event.proto.

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

@$core.Deprecated('Use eventDescriptor instead')
const Event$json = {
  '1': 'Event',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 3, '10': 'id'},
    {'1': 'event_kind', '3': 2, '4': 1, '5': 9, '10': 'eventKind'},
    {'1': 'class', '3': 3, '4': 1, '5': 9, '10': 'class'},
    {'1': 'subject', '3': 4, '4': 1, '5': 9, '10': 'subject'},
    {'1': 'owner_iid', '3': 5, '4': 1, '5': 3, '10': 'ownerIid'},
    {'1': 'dv', '3': 6, '4': 1, '5': 9, '10': 'dv'},
    {'1': 'slug', '3': 7, '4': 1, '5': 9, '10': 'slug'},
    {'1': 'text', '3': 8, '4': 1, '5': 9, '10': 'text'},
    {'1': 'meta_json', '3': 9, '4': 1, '5': 9, '10': 'metaJson'},
    {'1': 'created_ts_ms', '3': 10, '4': 1, '5': 3, '10': 'createdTsMs'},
  ],
};

/// Descriptor for `Event`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List eventDescriptor = $convert.base64Decode(
    'CgVFdmVudBIOCgJpZBgBIAEoA1ICaWQSHQoKZXZlbnRfa2luZBgCIAEoCVIJZXZlbnRLaW5kEh'
    'QKBWNsYXNzGAMgASgJUgVjbGFzcxIYCgdzdWJqZWN0GAQgASgJUgdzdWJqZWN0EhsKCW93bmVy'
    'X2lpZBgFIAEoA1IIb3duZXJJaWQSDgoCZHYYBiABKAlSAmR2EhIKBHNsdWcYByABKAlSBHNsdW'
    'cSEgoEdGV4dBgIIAEoCVIEdGV4dBIbCgltZXRhX2pzb24YCSABKAlSCG1ldGFKc29uEiIKDWNy'
    'ZWF0ZWRfdHNfbXMYCiABKANSC2NyZWF0ZWRUc01z');

@$core.Deprecated('Use eventPushDescriptor instead')
const EventPush$json = {
  '1': 'EventPush',
  '2': [
    {'1': 'event', '3': 1, '4': 1, '5': 11, '6': '.c35.Event', '10': 'event'},
  ],
};

/// Descriptor for `EventPush`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List eventPushDescriptor = $convert.base64Decode(
    'CglFdmVudFB1c2gSIAoFZXZlbnQYASABKAsyCi5jMzUuRXZlbnRSBWV2ZW50');

@$core.Deprecated('Use eventUserSessionDescriptor instead')
const EventUserSession$json = {
  '1': 'EventUserSession',
  '2': [
    {'1': 'method', '3': 1, '4': 1, '5': 9, '10': 'method'},
    {'1': 'platform', '3': 2, '4': 1, '5': 9, '10': 'platform'},
    {'1': 'app_build', '3': 3, '4': 1, '5': 3, '10': 'appBuild'},
    {'1': 'sess_id', '3': 4, '4': 1, '5': 3, '10': 'sessId'},
    {'1': 'conn_id', '3': 5, '4': 1, '5': 3, '10': 'connId'},
  ],
};

/// Descriptor for `EventUserSession`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List eventUserSessionDescriptor = $convert.base64Decode(
    'ChBFdmVudFVzZXJTZXNzaW9uEhYKBm1ldGhvZBgBIAEoCVIGbWV0aG9kEhoKCHBsYXRmb3JtGA'
    'IgASgJUghwbGF0Zm9ybRIbCglhcHBfYnVpbGQYAyABKANSCGFwcEJ1aWxkEhcKB3Nlc3NfaWQY'
    'BCABKANSBnNlc3NJZBIXCgdjb25uX2lkGAUgASgDUgZjb25uSWQ=');

@$core.Deprecated('Use eventConsumptionMealDescriptor instead')
const EventConsumptionMeal$json = {
  '1': 'EventConsumptionMeal',
  '2': [
    {'1': 'consumption_id', '3': 1, '4': 1, '5': 3, '10': 'consumptionId'},
    {'1': 'day_id', '3': 2, '4': 1, '5': 9, '10': 'dayId'},
    {'1': 'item_count', '3': 3, '4': 1, '5': 5, '10': 'itemCount'},
    {'1': 'calories', '3': 4, '4': 1, '5': 5, '10': 'calories'},
    {'1': 'source', '3': 5, '4': 1, '5': 9, '10': 'source'},
    {'1': 'meal_fingerprint', '3': 6, '4': 1, '5': 9, '10': 'mealFingerprint'},
  ],
};

/// Descriptor for `EventConsumptionMeal`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List eventConsumptionMealDescriptor = $convert.base64Decode(
    'ChRFdmVudENvbnN1bXB0aW9uTWVhbBIlCg5jb25zdW1wdGlvbl9pZBgBIAEoA1INY29uc3VtcH'
    'Rpb25JZBIVCgZkYXlfaWQYAiABKAlSBWRheUlkEh0KCml0ZW1fY291bnQYAyABKAVSCWl0ZW1D'
    'b3VudBIaCghjYWxvcmllcxgEIAEoBVIIY2Fsb3JpZXMSFgoGc291cmNlGAUgASgJUgZzb3VyY2'
    'USKQoQbWVhbF9maW5nZXJwcmludBgGIAEoCVIPbWVhbEZpbmdlcnByaW50');
