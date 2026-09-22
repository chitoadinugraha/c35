// This is a generated file - do not edit.
//
// Generated from c35/catalog.proto.

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

@$core.Deprecated('Use topicItemDescriptor instead')
const TopicItem$json = {
  '1': 'TopicItem',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'label_key', '3': 2, '4': 1, '5': 9, '10': 'labelKey'},
    {'1': 'inst', '3': 3, '4': 1, '5': 9, '10': 'inst'},
    {'1': 'extend', '3': 4, '4': 1, '5': 9, '10': 'extend'},
    {'1': 'sort', '3': 5, '4': 1, '5': 5, '10': 'sort'},
    {'1': 'enabled', '3': 6, '4': 1, '5': 8, '10': 'enabled'},
  ],
};

/// Descriptor for `TopicItem`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List topicItemDescriptor = $convert.base64Decode(
    'CglUb3BpY0l0ZW0SDgoCaWQYASABKAlSAmlkEhsKCWxhYmVsX2tleRgCIAEoCVIIbGFiZWxLZX'
    'kSEgoEaW5zdBgDIAEoCVIEaW5zdBIWCgZleHRlbmQYBCABKAlSBmV4dGVuZBISCgRzb3J0GAUg'
    'ASgFUgRzb3J0EhgKB2VuYWJsZWQYBiABKAhSB2VuYWJsZWQ=');

@$core.Deprecated('Use mentionItemDescriptor instead')
const MentionItem$json = {
  '1': 'MentionItem',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'topic_id', '3': 2, '4': 1, '5': 9, '10': 'topicId'},
    {'1': 'inst_id', '3': 3, '4': 1, '5': 9, '10': 'instId'},
    {'1': 'icon', '3': 4, '4': 1, '5': 9, '10': 'icon'},
    {'1': 'color', '3': 5, '4': 1, '5': 9, '10': 'color'},
    {'1': 'sort', '3': 6, '4': 1, '5': 5, '10': 'sort'},
    {'1': 'label_key', '3': 7, '4': 1, '5': 9, '10': 'labelKey'},
    {'1': 'caption_key', '3': 8, '4': 1, '5': 9, '10': 'captionKey'},
    {'1': 'search_terms', '3': 9, '4': 3, '5': 9, '10': 'searchTerms'},
    {'1': 'enabled', '3': 10, '4': 1, '5': 8, '10': 'enabled'},
    {'1': 'title', '3': 11, '4': 1, '5': 9, '10': 'title'},
    {'1': 'scope_label', '3': 12, '4': 1, '5': 9, '10': 'scopeLabel'},
    {'1': 'label', '3': 13, '4': 1, '5': 9, '10': 'label'},
    {'1': 'scope_ref', '3': 14, '4': 1, '5': 9, '10': 'scopeRef'},
    {'1': 'kind', '3': 15, '4': 1, '5': 9, '10': 'kind'},
  ],
};

/// Descriptor for `MentionItem`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mentionItemDescriptor = $convert.base64Decode(
    'CgtNZW50aW9uSXRlbRIOCgJpZBgBIAEoCVICaWQSGQoIdG9waWNfaWQYAiABKAlSB3RvcGljSW'
    'QSFwoHaW5zdF9pZBgDIAEoCVIGaW5zdElkEhIKBGljb24YBCABKAlSBGljb24SFAoFY29sb3IY'
    'BSABKAlSBWNvbG9yEhIKBHNvcnQYBiABKAVSBHNvcnQSGwoJbGFiZWxfa2V5GAcgASgJUghsYW'
    'JlbEtleRIfCgtjYXB0aW9uX2tleRgIIAEoCVIKY2FwdGlvbktleRIhCgxzZWFyY2hfdGVybXMY'
    'CSADKAlSC3NlYXJjaFRlcm1zEhgKB2VuYWJsZWQYCiABKAhSB2VuYWJsZWQSFAoFdGl0bGUYCy'
    'ABKAlSBXRpdGxlEh8KC3Njb3BlX2xhYmVsGAwgASgJUgpzY29wZUxhYmVsEhQKBWxhYmVsGA0g'
    'ASgJUgVsYWJlbBIbCglzY29wZV9yZWYYDiABKAlSCHNjb3BlUmVmEhIKBGtpbmQYDyABKAlSBG'
    'tpbmQ=');

@$core.Deprecated('Use mentionCatalogDescriptor instead')
const MentionCatalog$json = {
  '1': 'MentionCatalog',
  '2': [
    {'1': 'rev', '3': 1, '4': 1, '5': 3, '10': 'rev'},
    {
      '1': 'items',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.c35.MentionItem',
      '10': 'items'
    },
  ],
};

/// Descriptor for `MentionCatalog`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mentionCatalogDescriptor = $convert.base64Decode(
    'Cg5NZW50aW9uQ2F0YWxvZxIQCgNyZXYYASABKANSA3JldhImCgVpdGVtcxgCIAMoCzIQLmMzNS'
    '5NZW50aW9uSXRlbVIFaXRlbXM=');

@$core.Deprecated('Use reqMentionSearchDescriptor instead')
const ReqMentionSearch$json = {
  '1': 'ReqMentionSearch',
  '2': [
    {'1': 'q', '3': 1, '4': 1, '5': 9, '10': 'q'},
    {'1': 'kinds', '3': 2, '4': 3, '5': 9, '10': 'kinds'},
    {'1': 'limit', '3': 3, '4': 1, '5': 5, '10': 'limit'},
  ],
};

/// Descriptor for `ReqMentionSearch`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqMentionSearchDescriptor = $convert.base64Decode(
    'ChBSZXFNZW50aW9uU2VhcmNoEgwKAXEYASABKAlSAXESFAoFa2luZHMYAiADKAlSBWtpbmRzEh'
    'QKBWxpbWl0GAMgASgFUgVsaW1pdA==');

@$core.Deprecated('Use resMentionSearchDescriptor instead')
const ResMentionSearch$json = {
  '1': 'ResMentionSearch',
  '2': [
    {
      '1': 'mentions',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.c35.MentionItem',
      '10': 'mentions'
    },
  ],
};

/// Descriptor for `ResMentionSearch`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resMentionSearchDescriptor = $convert.base64Decode(
    'ChBSZXNNZW50aW9uU2VhcmNoEiwKCG1lbnRpb25zGAEgAygLMhAuYzM1Lk1lbnRpb25JdGVtUg'
    'htZW50aW9ucw==');

@$core.Deprecated('Use reqTopicListDescriptor instead')
const ReqTopicList$json = {
  '1': 'ReqTopicList',
};

/// Descriptor for `ReqTopicList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqTopicListDescriptor =
    $convert.base64Decode('CgxSZXFUb3BpY0xpc3Q=');

@$core.Deprecated('Use resTopicListDescriptor instead')
const ResTopicList$json = {
  '1': 'ResTopicList',
  '2': [
    {
      '1': 'topics',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.c35.TopicItem',
      '10': 'topics'
    },
  ],
};

/// Descriptor for `ResTopicList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resTopicListDescriptor = $convert.base64Decode(
    'CgxSZXNUb3BpY0xpc3QSJgoGdG9waWNzGAEgAygLMg4uYzM1LlRvcGljSXRlbVIGdG9waWNz');

@$core.Deprecated('Use reqMentionListDescriptor instead')
const ReqMentionList$json = {
  '1': 'ReqMentionList',
};

/// Descriptor for `ReqMentionList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqMentionListDescriptor =
    $convert.base64Decode('Cg5SZXFNZW50aW9uTGlzdA==');

@$core.Deprecated('Use resMentionListDescriptor instead')
const ResMentionList$json = {
  '1': 'ResMentionList',
  '2': [
    {
      '1': 'mentions',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.c35.MentionItem',
      '10': 'mentions'
    },
    {'1': 'rev', '3': 2, '4': 1, '5': 3, '10': 'rev'},
  ],
};

/// Descriptor for `ResMentionList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resMentionListDescriptor = $convert.base64Decode(
    'Cg5SZXNNZW50aW9uTGlzdBIsCghtZW50aW9ucxgBIAMoCzIQLmMzNS5NZW50aW9uSXRlbVIIbW'
    'VudGlvbnMSEAoDcmV2GAIgASgDUgNyZXY=');

@$core.Deprecated('Use reqTranslationGetDescriptor instead')
const ReqTranslationGet$json = {
  '1': 'ReqTranslationGet',
  '2': [
    {'1': 'lang', '3': 1, '4': 1, '5': 9, '10': 'lang'},
    {'1': 'categories', '3': 2, '4': 3, '5': 9, '10': 'categories'},
    {'1': 'keys', '3': 3, '4': 3, '5': 9, '10': 'keys'},
  ],
};

/// Descriptor for `ReqTranslationGet`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqTranslationGetDescriptor = $convert.base64Decode(
    'ChFSZXFUcmFuc2xhdGlvbkdldBISCgRsYW5nGAEgASgJUgRsYW5nEh4KCmNhdGVnb3JpZXMYAi'
    'ADKAlSCmNhdGVnb3JpZXMSEgoEa2V5cxgDIAMoCVIEa2V5cw==');

@$core.Deprecated('Use resTranslationGetDescriptor instead')
const ResTranslationGet$json = {
  '1': 'ResTranslationGet',
  '2': [
    {
      '1': 'entries',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.c35.ResTranslationGet.EntriesEntry',
      '10': 'entries'
    },
    {'1': 'updated_ts_ms', '3': 2, '4': 1, '5': 3, '10': 'updatedTsMs'},
  ],
  '3': [ResTranslationGet_EntriesEntry$json],
};

@$core.Deprecated('Use resTranslationGetDescriptor instead')
const ResTranslationGet_EntriesEntry$json = {
  '1': 'EntriesEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `ResTranslationGet`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resTranslationGetDescriptor = $convert.base64Decode(
    'ChFSZXNUcmFuc2xhdGlvbkdldBI9CgdlbnRyaWVzGAEgAygLMiMuYzM1LlJlc1RyYW5zbGF0aW'
    '9uR2V0LkVudHJpZXNFbnRyeVIHZW50cmllcxIiCg11cGRhdGVkX3RzX21zGAIgASgDUgt1cGRh'
    'dGVkVHNNcxo6CgxFbnRyaWVzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKA'
    'lSBXZhbHVlOgI4AQ==');
