// This is a generated file - do not edit.
//
// Generated from c35/drive.proto.

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

@$core.Deprecated('Use driveFileEntryDescriptor instead')
const DriveFileEntry$json = {
  '1': 'DriveFileEntry',
  '2': [
    {'1': 'path', '3': 1, '4': 1, '5': 9, '10': 'path'},
    {'1': 'hash_blake3', '3': 2, '4': 1, '5': 9, '10': 'hashBlake3'},
    {'1': 'size_bytes', '3': 3, '4': 1, '5': 3, '10': 'sizeBytes'},
  ],
};

/// Descriptor for `DriveFileEntry`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List driveFileEntryDescriptor = $convert.base64Decode(
    'Cg5Ecml2ZUZpbGVFbnRyeRISCgRwYXRoGAEgASgJUgRwYXRoEh8KC2hhc2hfYmxha2UzGAIgAS'
    'gJUgpoYXNoQmxha2UzEh0KCnNpemVfYnl0ZXMYAyABKANSCXNpemVCeXRlcw==');

@$core.Deprecated('Use reqDriveTreeDescriptor instead')
const ReqDriveTree$json = {
  '1': 'ReqDriveTree',
  '2': [
    {'1': 'path_prefix', '3': 1, '4': 1, '5': 9, '10': 'pathPrefix'},
  ],
};

/// Descriptor for `ReqDriveTree`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqDriveTreeDescriptor = $convert.base64Decode(
    'CgxSZXFEcml2ZVRyZWUSHwoLcGF0aF9wcmVmaXgYASABKAlSCnBhdGhQcmVmaXg=');

@$core.Deprecated('Use resDriveTreeDescriptor instead')
const ResDriveTree$json = {
  '1': 'ResDriveTree',
  '2': [
    {
      '1': 'files',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.c35.DriveFileEntry',
      '10': 'files'
    },
  ],
};

/// Descriptor for `ResDriveTree`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resDriveTreeDescriptor = $convert.base64Decode(
    'CgxSZXNEcml2ZVRyZWUSKQoFZmlsZXMYASADKAsyEy5jMzUuRHJpdmVGaWxlRW50cnlSBWZpbG'
    'Vz');

@$core.Deprecated('Use reqDriveUploadDescriptor instead')
const ReqDriveUpload$json = {
  '1': 'ReqDriveUpload',
  '2': [
    {'1': 'path', '3': 1, '4': 1, '5': 9, '10': 'path'},
    {'1': 'body', '3': 2, '4': 1, '5': 12, '10': 'body'},
    {'1': 'hash_blake3', '3': 3, '4': 1, '5': 9, '10': 'hashBlake3'},
  ],
};

/// Descriptor for `ReqDriveUpload`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqDriveUploadDescriptor = $convert.base64Decode(
    'Cg5SZXFEcml2ZVVwbG9hZBISCgRwYXRoGAEgASgJUgRwYXRoEhIKBGJvZHkYAiABKAxSBGJvZH'
    'kSHwoLaGFzaF9ibGFrZTMYAyABKAlSCmhhc2hCbGFrZTM=');

@$core.Deprecated('Use resDriveUploadDescriptor instead')
const ResDriveUpload$json = {
  '1': 'ResDriveUpload',
  '2': [
    {
      '1': 'file',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.c35.DriveFileEntry',
      '10': 'file'
    },
  ],
};

/// Descriptor for `ResDriveUpload`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resDriveUploadDescriptor = $convert.base64Decode(
    'Cg5SZXNEcml2ZVVwbG9hZBInCgRmaWxlGAEgASgLMhMuYzM1LkRyaXZlRmlsZUVudHJ5UgRmaW'
    'xl');

@$core.Deprecated('Use reqDriveDeleteDescriptor instead')
const ReqDriveDelete$json = {
  '1': 'ReqDriveDelete',
  '2': [
    {'1': 'path', '3': 1, '4': 1, '5': 9, '10': 'path'},
  ],
};

/// Descriptor for `ReqDriveDelete`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqDriveDeleteDescriptor =
    $convert.base64Decode('Cg5SZXFEcml2ZURlbGV0ZRISCgRwYXRoGAEgASgJUgRwYXRo');

@$core.Deprecated('Use resDriveDeleteDescriptor instead')
const ResDriveDelete$json = {
  '1': 'ResDriveDelete',
  '2': [
    {'1': 'ok', '3': 1, '4': 1, '5': 8, '10': 'ok'},
  ],
};

/// Descriptor for `ResDriveDelete`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resDriveDeleteDescriptor =
    $convert.base64Decode('Cg5SZXNEcml2ZURlbGV0ZRIOCgJvaxgBIAEoCFICb2s=');

@$core.Deprecated('Use resDriveStorageDescriptor instead')
const ResDriveStorage$json = {
  '1': 'ResDriveStorage',
  '2': [
    {
      '1': 'storage_used_bytes',
      '3': 1,
      '4': 1,
      '5': 3,
      '10': 'storageUsedBytes'
    },
    {
      '1': 'storage_limit_bytes',
      '3': 2,
      '4': 1,
      '5': 3,
      '10': 'storageLimitBytes'
    },
  ],
};

/// Descriptor for `ResDriveStorage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resDriveStorageDescriptor = $convert.base64Decode(
    'Cg9SZXNEcml2ZVN0b3JhZ2USLAoSc3RvcmFnZV91c2VkX2J5dGVzGAEgASgDUhBzdG9yYWdlVX'
    'NlZEJ5dGVzEi4KE3N0b3JhZ2VfbGltaXRfYnl0ZXMYAiABKANSEXN0b3JhZ2VMaW1pdEJ5dGVz');
