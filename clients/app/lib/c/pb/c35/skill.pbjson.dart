// This is a generated file - do not edit.
//
// Generated from c35/skill.proto.

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

@$core.Deprecated('Use skillScopeDescriptor instead')
const SkillScope$json = {
  '1': 'SkillScope',
  '2': [
    {'1': 'SKILL_SCOPE_UNSPECIFIED', '2': 0},
    {'1': 'SKILL_SCOPE_USER', '2': 1},
    {'1': 'SKILL_SCOPE_DEVICE', '2': 2},
    {'1': 'SKILL_SCOPE_TEAM', '2': 3},
    {'1': 'SKILL_SCOPE_GLOBAL', '2': 4},
  ],
};

/// Descriptor for `SkillScope`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List skillScopeDescriptor = $convert.base64Decode(
    'CgpTa2lsbFNjb3BlEhsKF1NLSUxMX1NDT1BFX1VOU1BFQ0lGSUVEEAASFAoQU0tJTExfU0NPUE'
    'VfVVNFUhABEhYKElNLSUxMX1NDT1BFX0RFVklDRRACEhQKEFNLSUxMX1NDT1BFX1RFQU0QAxIW'
    'ChJTS0lMTF9TQ09QRV9HTE9CQUwQBA==');

@$core.Deprecated('Use skillSourceDescriptor instead')
const SkillSource$json = {
  '1': 'SkillSource',
  '2': [
    {'1': 'SKILL_SOURCE_UNSPECIFIED', '2': 0},
    {'1': 'SKILL_SOURCE_TAUGHT', '2': 1},
    {'1': 'SKILL_SOURCE_CATALOG', '2': 2},
    {'1': 'SKILL_SOURCE_IMPORT', '2': 3},
  ],
};

/// Descriptor for `SkillSource`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List skillSourceDescriptor = $convert.base64Decode(
    'CgtTa2lsbFNvdXJjZRIcChhTS0lMTF9TT1VSQ0VfVU5TUEVDSUZJRUQQABIXChNTS0lMTF9TT1'
    'VSQ0VfVEFVR0hUEAESGAoUU0tJTExfU09VUkNFX0NBVEFMT0cQAhIXChNTS0lMTF9TT1VSQ0Vf'
    'SU1QT1JUEAM=');

@$core.Deprecated('Use skillDescriptor instead')
const Skill$json = {
  '1': 'Skill',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 3, '10': 'id'},
    {'1': 'owner_iid', '3': 2, '4': 1, '5': 3, '10': 'ownerIid'},
    {
      '1': 'scope',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.c35.SkillScope',
      '10': 'scope'
    },
    {'1': 'device_iid', '3': 4, '4': 1, '5': 3, '10': 'deviceIid'},
    {'1': 'team_iid', '3': 5, '4': 1, '5': 3, '10': 'teamIid'},
    {'1': 'title', '3': 6, '4': 1, '5': 9, '10': 'title'},
    {'1': 'hash_blake3', '3': 7, '4': 1, '5': 9, '10': 'hashBlake3'},
    {'1': 'body_md', '3': 8, '4': 1, '5': 9, '10': 'bodyMd'},
    {
      '1': 'source',
      '3': 9,
      '4': 1,
      '5': 14,
      '6': '.c35.SkillSource',
      '10': 'source'
    },
    {'1': 'catalog_id', '3': 10, '4': 1, '5': 3, '10': 'catalogId'},
    {
      '1': 'catalog_variant_id',
      '3': 11,
      '4': 1,
      '5': 3,
      '10': 'catalogVariantId'
    },
    {
      '1': 'catalog_release_id',
      '3': 12,
      '4': 1,
      '5': 3,
      '10': 'catalogReleaseId'
    },
    {'1': 'author_name', '3': 13, '4': 1, '5': 9, '10': 'authorName'},
    {'1': 'tags_json', '3': 14, '4': 1, '5': 9, '10': 'tagsJson'},
    {'1': 'phrases_json', '3': 15, '4': 1, '5': 9, '10': 'phrasesJson'},
    {'1': 'auto_run', '3': 16, '4': 1, '5': 8, '10': 'autoRun'},
    {'1': 'surface', '3': 17, '4': 1, '5': 9, '10': 'surface'},
    {'1': 'target_app', '3': 18, '4': 1, '5': 9, '10': 'targetApp'},
    {'1': 'url_pattern', '3': 19, '4': 1, '5': 9, '10': 'urlPattern'},
    {
      '1': 'steps',
      '3': 20,
      '4': 3,
      '5': 11,
      '6': '.c35.SkillStep',
      '10': 'steps'
    },
    {'1': 'created_ts_ms', '3': 30, '4': 1, '5': 3, '10': 'createdTsMs'},
    {'1': 'updated_ts_ms', '3': 31, '4': 1, '5': 3, '10': 'updatedTsMs'},
    {'1': 'deleted_ts_ms', '3': 32, '4': 1, '5': 3, '10': 'deletedTsMs'},
  ],
};

/// Descriptor for `Skill`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List skillDescriptor = $convert.base64Decode(
    'CgVTa2lsbBIOCgJpZBgBIAEoA1ICaWQSGwoJb3duZXJfaWlkGAIgASgDUghvd25lcklpZBIlCg'
    'VzY29wZRgDIAEoDjIPLmMzNS5Ta2lsbFNjb3BlUgVzY29wZRIdCgpkZXZpY2VfaWlkGAQgASgD'
    'UglkZXZpY2VJaWQSGQoIdGVhbV9paWQYBSABKANSB3RlYW1JaWQSFAoFdGl0bGUYBiABKAlSBX'
    'RpdGxlEh8KC2hhc2hfYmxha2UzGAcgASgJUgpoYXNoQmxha2UzEhcKB2JvZHlfbWQYCCABKAlS'
    'BmJvZHlNZBIoCgZzb3VyY2UYCSABKA4yEC5jMzUuU2tpbGxTb3VyY2VSBnNvdXJjZRIdCgpjYX'
    'RhbG9nX2lkGAogASgDUgljYXRhbG9nSWQSLAoSY2F0YWxvZ192YXJpYW50X2lkGAsgASgDUhBj'
    'YXRhbG9nVmFyaWFudElkEiwKEmNhdGFsb2dfcmVsZWFzZV9pZBgMIAEoA1IQY2F0YWxvZ1JlbG'
    'Vhc2VJZBIfCgthdXRob3JfbmFtZRgNIAEoCVIKYXV0aG9yTmFtZRIbCgl0YWdzX2pzb24YDiAB'
    'KAlSCHRhZ3NKc29uEiEKDHBocmFzZXNfanNvbhgPIAEoCVILcGhyYXNlc0pzb24SGQoIYXV0b1'
    '9ydW4YECABKAhSB2F1dG9SdW4SGAoHc3VyZmFjZRgRIAEoCVIHc3VyZmFjZRIdCgp0YXJnZXRf'
    'YXBwGBIgASgJUgl0YXJnZXRBcHASHwoLdXJsX3BhdHRlcm4YEyABKAlSCnVybFBhdHRlcm4SJA'
    'oFc3RlcHMYFCADKAsyDi5jMzUuU2tpbGxTdGVwUgVzdGVwcxIiCg1jcmVhdGVkX3RzX21zGB4g'
    'ASgDUgtjcmVhdGVkVHNNcxIiCg11cGRhdGVkX3RzX21zGB8gASgDUgt1cGRhdGVkVHNNcxIiCg'
    '1kZWxldGVkX3RzX21zGCAgASgDUgtkZWxldGVkVHNNcw==');

@$core.Deprecated('Use skillStepDescriptor instead')
const SkillStep$json = {
  '1': 'SkillStep',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 3, '10': 'id'},
    {'1': 'skill_id', '3': 2, '4': 1, '5': 3, '10': 'skillId'},
    {'1': 'owner_iid', '3': 3, '4': 1, '5': 3, '10': 'ownerIid'},
    {'1': 'ord', '3': 4, '4': 1, '5': 5, '10': 'ord'},
    {'1': 'kind', '3': 5, '4': 1, '5': 9, '10': 'kind'},
    {'1': 'label', '3': 6, '4': 1, '5': 9, '10': 'label'},
    {'1': 'ax_target_json', '3': 7, '4': 1, '5': 9, '10': 'axTargetJson'},
    {'1': 'screenshot_hash', '3': 8, '4': 1, '5': 9, '10': 'screenshotHash'},
    {'1': 'comment', '3': 9, '4': 1, '5': 9, '10': 'comment'},
    {'1': 'secret_id', '3': 10, '4': 1, '5': 3, '10': 'secretId'},
    {
      '1': 'tape_local_only_json',
      '3': 11,
      '4': 1,
      '5': 9,
      '10': 'tapeLocalOnlyJson'
    },
    {'1': 'created_ts_ms', '3': 20, '4': 1, '5': 3, '10': 'createdTsMs'},
    {'1': 'updated_ts_ms', '3': 21, '4': 1, '5': 3, '10': 'updatedTsMs'},
    {'1': 'deleted_ts_ms', '3': 22, '4': 1, '5': 3, '10': 'deletedTsMs'},
  ],
};

/// Descriptor for `SkillStep`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List skillStepDescriptor = $convert.base64Decode(
    'CglTa2lsbFN0ZXASDgoCaWQYASABKANSAmlkEhkKCHNraWxsX2lkGAIgASgDUgdza2lsbElkEh'
    'sKCW93bmVyX2lpZBgDIAEoA1IIb3duZXJJaWQSEAoDb3JkGAQgASgFUgNvcmQSEgoEa2luZBgF'
    'IAEoCVIEa2luZBIUCgVsYWJlbBgGIAEoCVIFbGFiZWwSJAoOYXhfdGFyZ2V0X2pzb24YByABKA'
    'lSDGF4VGFyZ2V0SnNvbhInCg9zY3JlZW5zaG90X2hhc2gYCCABKAlSDnNjcmVlbnNob3RIYXNo'
    'EhgKB2NvbW1lbnQYCSABKAlSB2NvbW1lbnQSGwoJc2VjcmV0X2lkGAogASgDUghzZWNyZXRJZB'
    'IvChR0YXBlX2xvY2FsX29ubHlfanNvbhgLIAEoCVIRdGFwZUxvY2FsT25seUpzb24SIgoNY3Jl'
    'YXRlZF90c19tcxgUIAEoA1ILY3JlYXRlZFRzTXMSIgoNdXBkYXRlZF90c19tcxgVIAEoA1ILdX'
    'BkYXRlZFRzTXMSIgoNZGVsZXRlZF90c19tcxgWIAEoA1ILZGVsZXRlZFRzTXM=');

@$core.Deprecated('Use skillCatalogDescriptor instead')
const SkillCatalog$json = {
  '1': 'SkillCatalog',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 3, '10': 'id'},
    {'1': 'author_iid', '3': 2, '4': 1, '5': 3, '10': 'authorIid'},
    {'1': 'author_name', '3': 3, '4': 1, '5': 9, '10': 'authorName'},
    {'1': 'slug', '3': 4, '4': 1, '5': 9, '10': 'slug'},
    {'1': 'title', '3': 5, '4': 1, '5': 9, '10': 'title'},
    {'1': 'summary', '3': 6, '4': 1, '5': 9, '10': 'summary'},
    {'1': 'body_md', '3': 7, '4': 1, '5': 9, '10': 'bodyMd'},
    {'1': 'tags_json', '3': 8, '4': 1, '5': 9, '10': 'tagsJson'},
    {'1': 'install_count', '3': 9, '4': 1, '5': 5, '10': 'installCount'},
    {'1': 'rating', '3': 10, '4': 1, '5': 1, '10': 'rating'},
    {'1': 'is_verified', '3': 11, '4': 1, '5': 8, '10': 'isVerified'},
    {'1': 'status', '3': 12, '4': 1, '5': 9, '10': 'status'},
  ],
};

/// Descriptor for `SkillCatalog`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List skillCatalogDescriptor = $convert.base64Decode(
    'CgxTa2lsbENhdGFsb2cSDgoCaWQYASABKANSAmlkEh0KCmF1dGhvcl9paWQYAiABKANSCWF1dG'
    'hvcklpZBIfCgthdXRob3JfbmFtZRgDIAEoCVIKYXV0aG9yTmFtZRISCgRzbHVnGAQgASgJUgRz'
    'bHVnEhQKBXRpdGxlGAUgASgJUgV0aXRsZRIYCgdzdW1tYXJ5GAYgASgJUgdzdW1tYXJ5EhcKB2'
    'JvZHlfbWQYByABKAlSBmJvZHlNZBIbCgl0YWdzX2pzb24YCCABKAlSCHRhZ3NKc29uEiMKDWlu'
    'c3RhbGxfY291bnQYCSABKAVSDGluc3RhbGxDb3VudBIWCgZyYXRpbmcYCiABKAFSBnJhdGluZx'
    'IfCgtpc192ZXJpZmllZBgLIAEoCFIKaXNWZXJpZmllZBIWCgZzdGF0dXMYDCABKAlSBnN0YXR1'
    'cw==');

@$core.Deprecated('Use reqSkillListDescriptor instead')
const ReqSkillList$json = {
  '1': 'ReqSkillList',
  '2': [
    {
      '1': 'scope',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.c35.SkillScope',
      '10': 'scope'
    },
    {'1': 'device_iid', '3': 2, '4': 1, '5': 3, '10': 'deviceIid'},
    {'1': 'team_iid', '3': 3, '4': 1, '5': 3, '10': 'teamIid'},
    {'1': 'since_ms', '3': 4, '4': 1, '5': 3, '10': 'sinceMs'},
  ],
};

/// Descriptor for `ReqSkillList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqSkillListDescriptor = $convert.base64Decode(
    'CgxSZXFTa2lsbExpc3QSJQoFc2NvcGUYASABKA4yDy5jMzUuU2tpbGxTY29wZVIFc2NvcGUSHQ'
    'oKZGV2aWNlX2lpZBgCIAEoA1IJZGV2aWNlSWlkEhkKCHRlYW1faWlkGAMgASgDUgd0ZWFtSWlk'
    'EhkKCHNpbmNlX21zGAQgASgDUgdzaW5jZU1z');

@$core.Deprecated('Use resSkillListDescriptor instead')
const ResSkillList$json = {
  '1': 'ResSkillList',
  '2': [
    {'1': 'skills', '3': 1, '4': 3, '5': 11, '6': '.c35.Skill', '10': 'skills'},
  ],
};

/// Descriptor for `ResSkillList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resSkillListDescriptor = $convert.base64Decode(
    'CgxSZXNTa2lsbExpc3QSIgoGc2tpbGxzGAEgAygLMgouYzM1LlNraWxsUgZza2lsbHM=');

@$core.Deprecated('Use reqSkillGetDescriptor instead')
const ReqSkillGet$json = {
  '1': 'ReqSkillGet',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 3, '10': 'id'},
  ],
};

/// Descriptor for `ReqSkillGet`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqSkillGetDescriptor =
    $convert.base64Decode('CgtSZXFTa2lsbEdldBIOCgJpZBgBIAEoA1ICaWQ=');

@$core.Deprecated('Use resSkillGetDescriptor instead')
const ResSkillGet$json = {
  '1': 'ResSkillGet',
  '2': [
    {'1': 'skill', '3': 1, '4': 1, '5': 11, '6': '.c35.Skill', '10': 'skill'},
  ],
};

/// Descriptor for `ResSkillGet`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resSkillGetDescriptor = $convert.base64Decode(
    'CgtSZXNTa2lsbEdldBIgCgVza2lsbBgBIAEoCzIKLmMzNS5Ta2lsbFIFc2tpbGw=');

@$core.Deprecated('Use reqSkillPutDescriptor instead')
const ReqSkillPut$json = {
  '1': 'ReqSkillPut',
  '2': [
    {'1': 'skill', '3': 1, '4': 1, '5': 11, '6': '.c35.Skill', '10': 'skill'},
  ],
};

/// Descriptor for `ReqSkillPut`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqSkillPutDescriptor = $convert.base64Decode(
    'CgtSZXFTa2lsbFB1dBIgCgVza2lsbBgBIAEoCzIKLmMzNS5Ta2lsbFIFc2tpbGw=');

@$core.Deprecated('Use resSkillPutDescriptor instead')
const ResSkillPut$json = {
  '1': 'ResSkillPut',
  '2': [
    {'1': 'skill', '3': 1, '4': 1, '5': 11, '6': '.c35.Skill', '10': 'skill'},
  ],
};

/// Descriptor for `ResSkillPut`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resSkillPutDescriptor = $convert.base64Decode(
    'CgtSZXNTa2lsbFB1dBIgCgVza2lsbBgBIAEoCzIKLmMzNS5Ta2lsbFIFc2tpbGw=');

@$core.Deprecated('Use reqSkillCatalogListDescriptor instead')
const ReqSkillCatalogList$json = {
  '1': 'ReqSkillCatalogList',
  '2': [
    {'1': 'q', '3': 1, '4': 1, '5': 9, '10': 'q'},
    {'1': 'limit', '3': 2, '4': 1, '5': 5, '10': 'limit'},
  ],
};

/// Descriptor for `ReqSkillCatalogList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqSkillCatalogListDescriptor = $convert.base64Decode(
    'ChNSZXFTa2lsbENhdGFsb2dMaXN0EgwKAXEYASABKAlSAXESFAoFbGltaXQYAiABKAVSBWxpbW'
    'l0');

@$core.Deprecated('Use resSkillCatalogListDescriptor instead')
const ResSkillCatalogList$json = {
  '1': 'ResSkillCatalogList',
  '2': [
    {
      '1': 'catalogs',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.c35.SkillCatalog',
      '10': 'catalogs'
    },
  ],
};

/// Descriptor for `ResSkillCatalogList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resSkillCatalogListDescriptor = $convert.base64Decode(
    'ChNSZXNTa2lsbENhdGFsb2dMaXN0Ei0KCGNhdGFsb2dzGAEgAygLMhEuYzM1LlNraWxsQ2F0YW'
    'xvZ1IIY2F0YWxvZ3M=');

@$core.Deprecated('Use reqSkillCatalogInstallDescriptor instead')
const ReqSkillCatalogInstall$json = {
  '1': 'ReqSkillCatalogInstall',
  '2': [
    {'1': 'catalog_id', '3': 1, '4': 1, '5': 3, '10': 'catalogId'},
    {'1': 'variant_id', '3': 2, '4': 1, '5': 3, '10': 'variantId'},
    {'1': 'release_id', '3': 3, '4': 1, '5': 3, '10': 'releaseId'},
    {
      '1': 'scope',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.c35.SkillScope',
      '10': 'scope'
    },
    {'1': 'device_iid', '3': 5, '4': 1, '5': 3, '10': 'deviceIid'},
  ],
};

/// Descriptor for `ReqSkillCatalogInstall`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqSkillCatalogInstallDescriptor = $convert.base64Decode(
    'ChZSZXFTa2lsbENhdGFsb2dJbnN0YWxsEh0KCmNhdGFsb2dfaWQYASABKANSCWNhdGFsb2dJZB'
    'IdCgp2YXJpYW50X2lkGAIgASgDUgl2YXJpYW50SWQSHQoKcmVsZWFzZV9pZBgDIAEoA1IJcmVs'
    'ZWFzZUlkEiUKBXNjb3BlGAQgASgOMg8uYzM1LlNraWxsU2NvcGVSBXNjb3BlEh0KCmRldmljZV'
    '9paWQYBSABKANSCWRldmljZUlpZA==');

@$core.Deprecated('Use resSkillCatalogInstallDescriptor instead')
const ResSkillCatalogInstall$json = {
  '1': 'ResSkillCatalogInstall',
  '2': [
    {'1': 'skill', '3': 1, '4': 1, '5': 11, '6': '.c35.Skill', '10': 'skill'},
  ],
};

/// Descriptor for `ResSkillCatalogInstall`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resSkillCatalogInstallDescriptor =
    $convert.base64Decode(
        'ChZSZXNTa2lsbENhdGFsb2dJbnN0YWxsEiAKBXNraWxsGAEgASgLMgouYzM1LlNraWxsUgVza2'
        'lsbA==');
