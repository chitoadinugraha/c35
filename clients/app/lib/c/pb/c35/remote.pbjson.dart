// This is a generated file - do not edit.
//
// Generated from c35/remote.proto.

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

@$core.Deprecated('Use remoteIceTypeDescriptor instead')
const RemoteIceType$json = {
  '1': 'RemoteIceType',
  '2': [
    {'1': 'REMOTE_ICE_TYPE_UNSPECIFIED', '2': 0},
    {'1': 'REMOTE_ICE_TYPE_HOST', '2': 1},
    {'1': 'REMOTE_ICE_TYPE_SRFLX', '2': 2},
    {'1': 'REMOTE_ICE_TYPE_RELAY', '2': 3},
  ],
};

/// Descriptor for `RemoteIceType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List remoteIceTypeDescriptor = $convert.base64Decode(
    'Cg1SZW1vdGVJY2VUeXBlEh8KG1JFTU9URV9JQ0VfVFlQRV9VTlNQRUNJRklFRBAAEhgKFFJFTU'
    '9URV9JQ0VfVFlQRV9IT1NUEAESGQoVUkVNT1RFX0lDRV9UWVBFX1NSRkxYEAISGQoVUkVNT1RF'
    'X0lDRV9UWVBFX1JFTEFZEAM=');

@$core.Deprecated('Use remoteConnectionModeDescriptor instead')
const RemoteConnectionMode$json = {
  '1': 'RemoteConnectionMode',
  '2': [
    {'1': 'REMOTE_CONNECTION_MODE_UNSPECIFIED', '2': 0},
    {'1': 'REMOTE_CONNECTION_MODE_DIRECT', '2': 1},
    {'1': 'REMOTE_CONNECTION_MODE_RELAY', '2': 2},
  ],
};

/// Descriptor for `RemoteConnectionMode`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List remoteConnectionModeDescriptor = $convert.base64Decode(
    'ChRSZW1vdGVDb25uZWN0aW9uTW9kZRImCiJSRU1PVEVfQ09OTkVDVElPTl9NT0RFX1VOU1BFQ0'
    'lGSUVEEAASIQodUkVNT1RFX0NPTk5FQ1RJT05fTU9ERV9ESVJFQ1QQARIgChxSRU1PVEVfQ09O'
    'TkVDVElPTl9NT0RFX1JFTEFZEAI=');

@$core.Deprecated('Use reqRemoteSessionStartDescriptor instead')
const ReqRemoteSessionStart$json = {
  '1': 'ReqRemoteSessionStart',
  '2': [
    {'1': 'device_iid', '3': 1, '4': 1, '5': 3, '10': 'deviceIid'},
    {'1': 'session_id', '3': 2, '4': 1, '5': 9, '10': 'sessionId'},
  ],
};

/// Descriptor for `ReqRemoteSessionStart`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqRemoteSessionStartDescriptor = $convert.base64Decode(
    'ChVSZXFSZW1vdGVTZXNzaW9uU3RhcnQSHQoKZGV2aWNlX2lpZBgBIAEoA1IJZGV2aWNlSWlkEh'
    '0KCnNlc3Npb25faWQYAiABKAlSCXNlc3Npb25JZA==');

@$core.Deprecated('Use resRemoteSessionStartDescriptor instead')
const ResRemoteSessionStart$json = {
  '1': 'ResRemoteSessionStart',
  '2': [
    {'1': 'ok', '3': 1, '4': 1, '5': 8, '10': 'ok'},
    {'1': 'error', '3': 2, '4': 1, '5': 9, '10': 'error'},
    {'1': 'session_id', '3': 3, '4': 1, '5': 9, '10': 'sessionId'},
  ],
};

/// Descriptor for `ResRemoteSessionStart`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resRemoteSessionStartDescriptor = $convert.base64Decode(
    'ChVSZXNSZW1vdGVTZXNzaW9uU3RhcnQSDgoCb2sYASABKAhSAm9rEhQKBWVycm9yGAIgASgJUg'
    'VlcnJvchIdCgpzZXNzaW9uX2lkGAMgASgJUglzZXNzaW9uSWQ=');

@$core.Deprecated('Use rtcSignalOfferDescriptor instead')
const RtcSignalOffer$json = {
  '1': 'RtcSignalOffer',
  '2': [
    {'1': 'device_iid', '3': 1, '4': 1, '5': 3, '10': 'deviceIid'},
    {'1': 'session_id', '3': 2, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'sdp', '3': 3, '4': 1, '5': 9, '10': 'sdp'},
  ],
};

/// Descriptor for `RtcSignalOffer`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rtcSignalOfferDescriptor = $convert.base64Decode(
    'Cg5SdGNTaWduYWxPZmZlchIdCgpkZXZpY2VfaWlkGAEgASgDUglkZXZpY2VJaWQSHQoKc2Vzc2'
    'lvbl9pZBgCIAEoCVIJc2Vzc2lvbklkEhAKA3NkcBgDIAEoCVIDc2Rw');

@$core.Deprecated('Use rtcSignalAnswerDescriptor instead')
const RtcSignalAnswer$json = {
  '1': 'RtcSignalAnswer',
  '2': [
    {'1': 'device_iid', '3': 1, '4': 1, '5': 3, '10': 'deviceIid'},
    {'1': 'session_id', '3': 2, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'sdp', '3': 3, '4': 1, '5': 9, '10': 'sdp'},
  ],
};

/// Descriptor for `RtcSignalAnswer`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rtcSignalAnswerDescriptor = $convert.base64Decode(
    'Cg9SdGNTaWduYWxBbnN3ZXISHQoKZGV2aWNlX2lpZBgBIAEoA1IJZGV2aWNlSWlkEh0KCnNlc3'
    'Npb25faWQYAiABKAlSCXNlc3Npb25JZBIQCgNzZHAYAyABKAlSA3NkcA==');

@$core.Deprecated('Use rtcSignalIceDescriptor instead')
const RtcSignalIce$json = {
  '1': 'RtcSignalIce',
  '2': [
    {'1': 'device_iid', '3': 1, '4': 1, '5': 3, '10': 'deviceIid'},
    {'1': 'session_id', '3': 2, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'candidate', '3': 3, '4': 1, '5': 9, '10': 'candidate'},
    {'1': 'sdp_mid', '3': 4, '4': 1, '5': 9, '10': 'sdpMid'},
    {'1': 'sdp_mline_index', '3': 5, '4': 1, '5': 13, '10': 'sdpMlineIndex'},
  ],
};

/// Descriptor for `RtcSignalIce`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rtcSignalIceDescriptor = $convert.base64Decode(
    'CgxSdGNTaWduYWxJY2USHQoKZGV2aWNlX2lpZBgBIAEoA1IJZGV2aWNlSWlkEh0KCnNlc3Npb2'
    '5faWQYAiABKAlSCXNlc3Npb25JZBIcCgljYW5kaWRhdGUYAyABKAlSCWNhbmRpZGF0ZRIXCgdz'
    'ZHBfbWlkGAQgASgJUgZzZHBNaWQSJgoPc2RwX21saW5lX2luZGV4GAUgASgNUg1zZHBNbGluZU'
    'luZGV4');

@$core.Deprecated('Use reqRemoteSessionStopDescriptor instead')
const ReqRemoteSessionStop$json = {
  '1': 'ReqRemoteSessionStop',
  '2': [
    {'1': 'device_iid', '3': 1, '4': 1, '5': 3, '10': 'deviceIid'},
    {'1': 'session_id', '3': 2, '4': 1, '5': 9, '10': 'sessionId'},
  ],
};

/// Descriptor for `ReqRemoteSessionStop`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqRemoteSessionStopDescriptor = $convert.base64Decode(
    'ChRSZXFSZW1vdGVTZXNzaW9uU3RvcBIdCgpkZXZpY2VfaWlkGAEgASgDUglkZXZpY2VJaWQSHQ'
    'oKc2Vzc2lvbl9pZBgCIAEoCVIJc2Vzc2lvbklk');

@$core.Deprecated('Use resRemoteSessionStopDescriptor instead')
const ResRemoteSessionStop$json = {
  '1': 'ResRemoteSessionStop',
  '2': [
    {'1': 'ok', '3': 1, '4': 1, '5': 8, '10': 'ok'},
  ],
};

/// Descriptor for `ResRemoteSessionStop`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resRemoteSessionStopDescriptor = $convert
    .base64Decode('ChRSZXNSZW1vdGVTZXNzaW9uU3RvcBIOCgJvaxgBIAEoCFICb2s=');

@$core.Deprecated('Use remoteSessionPushDescriptor instead')
const RemoteSessionPush$json = {
  '1': 'RemoteSessionPush',
  '2': [
    {'1': 'device_iid', '3': 1, '4': 1, '5': 3, '10': 'deviceIid'},
    {'1': 'session_id', '3': 2, '4': 1, '5': 9, '10': 'sessionId'},
    {
      '1': 'mode',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.c35.RemoteConnectionMode',
      '10': 'mode'
    },
    {
      '1': 'selected_ice',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.c35.RemoteIceType',
      '10': 'selectedIce'
    },
    {'1': 'video_active', '3': 5, '4': 1, '5': 8, '10': 'videoActive'},
    {'1': 'webrtc_connected', '3': 6, '4': 1, '5': 8, '10': 'webrtcConnected'},
    {'1': 'update_ready', '3': 7, '4': 1, '5': 8, '10': 'updateReady'},
    {'1': 'update_version', '3': 8, '4': 1, '5': 3, '10': 'updateVersion'},
  ],
};

/// Descriptor for `RemoteSessionPush`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List remoteSessionPushDescriptor = $convert.base64Decode(
    'ChFSZW1vdGVTZXNzaW9uUHVzaBIdCgpkZXZpY2VfaWlkGAEgASgDUglkZXZpY2VJaWQSHQoKc2'
    'Vzc2lvbl9pZBgCIAEoCVIJc2Vzc2lvbklkEi0KBG1vZGUYAyABKA4yGS5jMzUuUmVtb3RlQ29u'
    'bmVjdGlvbk1vZGVSBG1vZGUSNQoMc2VsZWN0ZWRfaWNlGAQgASgOMhIuYzM1LlJlbW90ZUljZV'
    'R5cGVSC3NlbGVjdGVkSWNlEiEKDHZpZGVvX2FjdGl2ZRgFIAEoCFILdmlkZW9BY3RpdmUSKQoQ'
    'd2VicnRjX2Nvbm5lY3RlZBgGIAEoCFIPd2VicnRjQ29ubmVjdGVkEiEKDHVwZGF0ZV9yZWFkeR'
    'gHIAEoCFILdXBkYXRlUmVhZHkSJQoOdXBkYXRlX3ZlcnNpb24YCCABKANSDXVwZGF0ZVZlcnNp'
    'b24=');

@$core.Deprecated('Use iceServerDescriptor instead')
const IceServer$json = {
  '1': 'IceServer',
  '2': [
    {'1': 'urls', '3': 1, '4': 3, '5': 9, '10': 'urls'},
    {'1': 'username', '3': 2, '4': 1, '5': 9, '10': 'username'},
    {'1': 'credential', '3': 3, '4': 1, '5': 9, '10': 'credential'},
  ],
};

/// Descriptor for `IceServer`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List iceServerDescriptor = $convert.base64Decode(
    'CglJY2VTZXJ2ZXISEgoEdXJscxgBIAMoCVIEdXJscxIaCgh1c2VybmFtZRgCIAEoCVIIdXNlcm'
    '5hbWUSHgoKY3JlZGVudGlhbBgDIAEoCVIKY3JlZGVudGlhbA==');

@$core.Deprecated('Use reqRemoteIceConfigDescriptor instead')
const ReqRemoteIceConfig$json = {
  '1': 'ReqRemoteIceConfig',
};

/// Descriptor for `ReqRemoteIceConfig`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqRemoteIceConfigDescriptor =
    $convert.base64Decode('ChJSZXFSZW1vdGVJY2VDb25maWc=');

@$core.Deprecated('Use resRemoteIceConfigDescriptor instead')
const ResRemoteIceConfig$json = {
  '1': 'ResRemoteIceConfig',
  '2': [
    {
      '1': 'ice_servers',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.c35.IceServer',
      '10': 'iceServers'
    },
    {'1': 'ttl_sec', '3': 2, '4': 1, '5': 13, '10': 'ttlSec'},
  ],
};

/// Descriptor for `ResRemoteIceConfig`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resRemoteIceConfigDescriptor = $convert.base64Decode(
    'ChJSZXNSZW1vdGVJY2VDb25maWcSLwoLaWNlX3NlcnZlcnMYASADKAsyDi5jMzUuSWNlU2Vydm'
    'VyUgppY2VTZXJ2ZXJzEhcKB3R0bF9zZWMYAiABKA1SBnR0bFNlYw==');

@$core.Deprecated('Use reqRemoteScreenshotDescriptor instead')
const ReqRemoteScreenshot$json = {
  '1': 'ReqRemoteScreenshot',
  '2': [
    {'1': 'device_iid', '3': 1, '4': 1, '5': 3, '10': 'deviceIid'},
    {'1': 'max_width', '3': 2, '4': 1, '5': 13, '10': 'maxWidth'},
    {'1': 'quality', '3': 3, '4': 1, '5': 13, '10': 'quality'},
    {'1': 'marker_x', '3': 4, '4': 1, '5': 1, '10': 'markerX'},
    {'1': 'marker_y', '3': 5, '4': 1, '5': 1, '10': 'markerY'},
    {'1': 'som', '3': 6, '4': 1, '5': 8, '10': 'som'},
  ],
};

/// Descriptor for `ReqRemoteScreenshot`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqRemoteScreenshotDescriptor = $convert.base64Decode(
    'ChNSZXFSZW1vdGVTY3JlZW5zaG90Eh0KCmRldmljZV9paWQYASABKANSCWRldmljZUlpZBIbCg'
    'ltYXhfd2lkdGgYAiABKA1SCG1heFdpZHRoEhgKB3F1YWxpdHkYAyABKA1SB3F1YWxpdHkSGQoI'
    'bWFya2VyX3gYBCABKAFSB21hcmtlclgSGQoIbWFya2VyX3kYBSABKAFSB21hcmtlclkSEAoDc2'
    '9tGAYgASgIUgNzb20=');

@$core.Deprecated('Use resRemoteScreenshotDescriptor instead')
const ResRemoteScreenshot$json = {
  '1': 'ResRemoteScreenshot',
  '2': [
    {'1': 'ok', '3': 1, '4': 1, '5': 8, '10': 'ok'},
    {'1': 'error', '3': 2, '4': 1, '5': 9, '10': 'error'},
    {'1': 'width', '3': 3, '4': 1, '5': 13, '10': 'width'},
    {'1': 'height', '3': 4, '4': 1, '5': 13, '10': 'height'},
    {'1': 'jpeg_bytes', '3': 5, '4': 1, '5': 12, '10': 'jpegBytes'},
    {'1': 'axtree_text', '3': 6, '4': 1, '5': 9, '10': 'axtreeText'},
  ],
};

/// Descriptor for `ResRemoteScreenshot`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resRemoteScreenshotDescriptor = $convert.base64Decode(
    'ChNSZXNSZW1vdGVTY3JlZW5zaG90Eg4KAm9rGAEgASgIUgJvaxIUCgVlcnJvchgCIAEoCVIFZX'
    'Jyb3ISFAoFd2lkdGgYAyABKA1SBXdpZHRoEhYKBmhlaWdodBgEIAEoDVIGaGVpZ2h0Eh0KCmpw'
    'ZWdfYnl0ZXMYBSABKAxSCWpwZWdCeXRlcxIfCgtheHRyZWVfdGV4dBgGIAEoCVIKYXh0cmVlVG'
    'V4dA==');

@$core.Deprecated('Use reqRemoteCommandDescriptor instead')
const ReqRemoteCommand$json = {
  '1': 'ReqRemoteCommand',
  '2': [
    {'1': 'device_iid', '3': 1, '4': 1, '5': 3, '10': 'deviceIid'},
    {'1': 'command', '3': 2, '4': 1, '5': 9, '10': 'command'},
    {'1': 'timeout_sec', '3': 3, '4': 1, '5': 13, '10': 'timeoutSec'},
  ],
};

/// Descriptor for `ReqRemoteCommand`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqRemoteCommandDescriptor = $convert.base64Decode(
    'ChBSZXFSZW1vdGVDb21tYW5kEh0KCmRldmljZV9paWQYASABKANSCWRldmljZUlpZBIYCgdjb2'
    '1tYW5kGAIgASgJUgdjb21tYW5kEh8KC3RpbWVvdXRfc2VjGAMgASgNUgp0aW1lb3V0U2Vj');

@$core.Deprecated('Use resRemoteCommandDescriptor instead')
const ResRemoteCommand$json = {
  '1': 'ResRemoteCommand',
  '2': [
    {'1': 'ok', '3': 1, '4': 1, '5': 8, '10': 'ok'},
    {'1': 'error', '3': 2, '4': 1, '5': 9, '10': 'error'},
    {'1': 'exit_code', '3': 3, '4': 1, '5': 5, '10': 'exitCode'},
    {'1': 'stdout', '3': 4, '4': 1, '5': 9, '10': 'stdout'},
    {'1': 'stderr', '3': 5, '4': 1, '5': 9, '10': 'stderr'},
  ],
};

/// Descriptor for `ResRemoteCommand`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resRemoteCommandDescriptor = $convert.base64Decode(
    'ChBSZXNSZW1vdGVDb21tYW5kEg4KAm9rGAEgASgIUgJvaxIUCgVlcnJvchgCIAEoCVIFZXJyb3'
    'ISGwoJZXhpdF9jb2RlGAMgASgFUghleGl0Q29kZRIWCgZzdGRvdXQYBCABKAlSBnN0ZG91dBIW'
    'CgZzdGRlcnIYBSABKAlSBnN0ZGVycg==');

@$core.Deprecated('Use remoteInputEventDescriptor instead')
const RemoteInputEvent$json = {
  '1': 'RemoteInputEvent',
  '2': [
    {'1': 'event_type', '3': 1, '4': 1, '5': 9, '10': 'eventType'},
    {'1': 'x', '3': 2, '4': 1, '5': 1, '10': 'x'},
    {'1': 'y', '3': 3, '4': 1, '5': 1, '10': 'y'},
    {'1': 'button', '3': 4, '4': 1, '5': 5, '10': 'button'},
    {'1': 'key_code', '3': 5, '4': 1, '5': 5, '10': 'keyCode'},
    {'1': 'text', '3': 6, '4': 1, '5': 9, '10': 'text'},
    {'1': 'delta_y', '3': 7, '4': 1, '5': 5, '10': 'deltaY'},
  ],
};

/// Descriptor for `RemoteInputEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List remoteInputEventDescriptor = $convert.base64Decode(
    'ChBSZW1vdGVJbnB1dEV2ZW50Eh0KCmV2ZW50X3R5cGUYASABKAlSCWV2ZW50VHlwZRIMCgF4GA'
    'IgASgBUgF4EgwKAXkYAyABKAFSAXkSFgoGYnV0dG9uGAQgASgFUgZidXR0b24SGQoIa2V5X2Nv'
    'ZGUYBSABKAVSB2tleUNvZGUSEgoEdGV4dBgGIAEoCVIEdGV4dBIXCgdkZWx0YV95GAcgASgFUg'
    'ZkZWx0YVk=');

@$core.Deprecated('Use remoteFsEntryDescriptor instead')
const RemoteFsEntry$json = {
  '1': 'RemoteFsEntry',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'path', '3': 2, '4': 1, '5': 9, '10': 'path'},
    {'1': 'is_dir', '3': 3, '4': 1, '5': 8, '10': 'isDir'},
    {'1': 'size', '3': 4, '4': 1, '5': 3, '10': 'size'},
    {'1': 'modified_ms', '3': 5, '4': 1, '5': 3, '10': 'modifiedMs'},
  ],
};

/// Descriptor for `RemoteFsEntry`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List remoteFsEntryDescriptor = $convert.base64Decode(
    'Cg1SZW1vdGVGc0VudHJ5EhIKBG5hbWUYASABKAlSBG5hbWUSEgoEcGF0aBgCIAEoCVIEcGF0aB'
    'IVCgZpc19kaXIYAyABKAhSBWlzRGlyEhIKBHNpemUYBCABKANSBHNpemUSHwoLbW9kaWZpZWRf'
    'bXMYBSABKANSCm1vZGlmaWVkTXM=');

@$core.Deprecated('Use remoteFsListReqDescriptor instead')
const RemoteFsListReq$json = {
  '1': 'RemoteFsListReq',
  '2': [
    {'1': 'path', '3': 1, '4': 1, '5': 9, '10': 'path'},
  ],
};

/// Descriptor for `RemoteFsListReq`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List remoteFsListReqDescriptor = $convert
    .base64Decode('Cg9SZW1vdGVGc0xpc3RSZXESEgoEcGF0aBgBIAEoCVIEcGF0aA==');

@$core.Deprecated('Use remoteFsListResDescriptor instead')
const RemoteFsListRes$json = {
  '1': 'RemoteFsListRes',
  '2': [
    {
      '1': 'entries',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.c35.RemoteFsEntry',
      '10': 'entries'
    },
    {'1': 'error', '3': 2, '4': 1, '5': 9, '10': 'error'},
  ],
};

/// Descriptor for `RemoteFsListRes`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List remoteFsListResDescriptor = $convert.base64Decode(
    'Cg9SZW1vdGVGc0xpc3RSZXMSLAoHZW50cmllcxgBIAMoCzISLmMzNS5SZW1vdGVGc0VudHJ5Ug'
    'dlbnRyaWVzEhQKBWVycm9yGAIgASgJUgVlcnJvcg==');

@$core.Deprecated('Use remoteFsReadReqDescriptor instead')
const RemoteFsReadReq$json = {
  '1': 'RemoteFsReadReq',
  '2': [
    {'1': 'path', '3': 1, '4': 1, '5': 9, '10': 'path'},
    {'1': 'offset', '3': 2, '4': 1, '5': 3, '10': 'offset'},
    {'1': 'length', '3': 3, '4': 1, '5': 5, '10': 'length'},
  ],
};

/// Descriptor for `RemoteFsReadReq`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List remoteFsReadReqDescriptor = $convert.base64Decode(
    'Cg9SZW1vdGVGc1JlYWRSZXESEgoEcGF0aBgBIAEoCVIEcGF0aBIWCgZvZmZzZXQYAiABKANSBm'
    '9mZnNldBIWCgZsZW5ndGgYAyABKAVSBmxlbmd0aA==');

@$core.Deprecated('Use remoteFsReadResDescriptor instead')
const RemoteFsReadRes$json = {
  '1': 'RemoteFsReadRes',
  '2': [
    {'1': 'data', '3': 1, '4': 1, '5': 12, '10': 'data'},
    {'1': 'eof', '3': 2, '4': 1, '5': 8, '10': 'eof'},
    {'1': 'mime', '3': 3, '4': 1, '5': 9, '10': 'mime'},
    {'1': 'error', '3': 4, '4': 1, '5': 9, '10': 'error'},
  ],
};

/// Descriptor for `RemoteFsReadRes`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List remoteFsReadResDescriptor = $convert.base64Decode(
    'Cg9SZW1vdGVGc1JlYWRSZXMSEgoEZGF0YRgBIAEoDFIEZGF0YRIQCgNlb2YYAiABKAhSA2VvZh'
    'ISCgRtaW1lGAMgASgJUgRtaW1lEhQKBWVycm9yGAQgASgJUgVlcnJvcg==');

@$core.Deprecated('Use remoteFsWriteReqDescriptor instead')
const RemoteFsWriteReq$json = {
  '1': 'RemoteFsWriteReq',
  '2': [
    {'1': 'path', '3': 1, '4': 1, '5': 9, '10': 'path'},
    {'1': 'offset', '3': 2, '4': 1, '5': 3, '10': 'offset'},
    {'1': 'data', '3': 3, '4': 1, '5': 12, '10': 'data'},
    {'1': 'finalize', '3': 4, '4': 1, '5': 8, '10': 'finalize'},
  ],
};

/// Descriptor for `RemoteFsWriteReq`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List remoteFsWriteReqDescriptor = $convert.base64Decode(
    'ChBSZW1vdGVGc1dyaXRlUmVxEhIKBHBhdGgYASABKAlSBHBhdGgSFgoGb2Zmc2V0GAIgASgDUg'
    'ZvZmZzZXQSEgoEZGF0YRgDIAEoDFIEZGF0YRIaCghmaW5hbGl6ZRgEIAEoCFIIZmluYWxpemU=');

@$core.Deprecated('Use remoteFsWriteResDescriptor instead')
const RemoteFsWriteRes$json = {
  '1': 'RemoteFsWriteRes',
  '2': [
    {'1': 'bytes_written', '3': 1, '4': 1, '5': 3, '10': 'bytesWritten'},
    {'1': 'error', '3': 2, '4': 1, '5': 9, '10': 'error'},
  ],
};

/// Descriptor for `RemoteFsWriteRes`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List remoteFsWriteResDescriptor = $convert.base64Decode(
    'ChBSZW1vdGVGc1dyaXRlUmVzEiMKDWJ5dGVzX3dyaXR0ZW4YASABKANSDGJ5dGVzV3JpdHRlbh'
    'IUCgVlcnJvchgCIAEoCVIFZXJyb3I=');
