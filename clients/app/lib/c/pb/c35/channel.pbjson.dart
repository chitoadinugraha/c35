// This is a generated file - do not edit.
//
// Generated from c35/channel.proto.

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

@$core.Deprecated('Use botChannelDocDescriptor instead')
const BotChannelDoc$json = {
  '1': 'BotChannelDoc',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'platform', '3': 2, '4': 1, '5': 9, '10': 'platform'},
    {'1': 'provider', '3': 3, '4': 1, '5': 9, '10': 'provider'},
    {'1': 'status', '3': 4, '4': 1, '5': 9, '10': 'status'},
    {'1': 'bot_username', '3': 5, '4': 1, '5': 9, '10': 'botUsername'},
    {'1': 'phone', '3': 6, '4': 1, '5': 9, '10': 'phone'},
    {'1': 'error_message', '3': 7, '4': 1, '5': 9, '10': 'errorMessage'},
  ],
};

/// Descriptor for `BotChannelDoc`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List botChannelDocDescriptor = $convert.base64Decode(
    'Cg1Cb3RDaGFubmVsRG9jEg4KAmlkGAEgASgJUgJpZBIaCghwbGF0Zm9ybRgCIAEoCVIIcGxhdG'
    'Zvcm0SGgoIcHJvdmlkZXIYAyABKAlSCHByb3ZpZGVyEhYKBnN0YXR1cxgEIAEoCVIGc3RhdHVz'
    'EiEKDGJvdF91c2VybmFtZRgFIAEoCVILYm90VXNlcm5hbWUSFAoFcGhvbmUYBiABKAlSBXBob2'
    '5lEiMKDWVycm9yX21lc3NhZ2UYByABKAlSDGVycm9yTWVzc2FnZQ==');

@$core.Deprecated('Use reqChannelTelegramConnectDescriptor instead')
const ReqChannelTelegramConnect$json = {
  '1': 'ReqChannelTelegramConnect',
  '2': [
    {'1': 'bot_iid', '3': 1, '4': 1, '5': 3, '10': 'botIid'},
    {'1': 'bot_token', '3': 2, '4': 1, '5': 9, '10': 'botToken'},
  ],
};

/// Descriptor for `ReqChannelTelegramConnect`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqChannelTelegramConnectDescriptor =
    $convert.base64Decode(
        'ChlSZXFDaGFubmVsVGVsZWdyYW1Db25uZWN0EhcKB2JvdF9paWQYASABKANSBmJvdElpZBIbCg'
        'lib3RfdG9rZW4YAiABKAlSCGJvdFRva2Vu');

@$core.Deprecated('Use resChannelTelegramConnectDescriptor instead')
const ResChannelTelegramConnect$json = {
  '1': 'ResChannelTelegramConnect',
  '2': [
    {'1': 'bot_iid', '3': 1, '4': 1, '5': 3, '10': 'botIid'},
    {
      '1': 'channel',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.c35.BotChannelDoc',
      '10': 'channel'
    },
    {'1': 'webhook_url', '3': 3, '4': 1, '5': 9, '10': 'webhookUrl'},
  ],
};

/// Descriptor for `ResChannelTelegramConnect`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resChannelTelegramConnectDescriptor = $convert.base64Decode(
    'ChlSZXNDaGFubmVsVGVsZWdyYW1Db25uZWN0EhcKB2JvdF9paWQYASABKANSBmJvdElpZBIsCg'
    'djaGFubmVsGAIgASgLMhIuYzM1LkJvdENoYW5uZWxEb2NSB2NoYW5uZWwSHwoLd2ViaG9va191'
    'cmwYAyABKAlSCndlYmhvb2tVcmw=');

@$core.Deprecated('Use reqChannelWhatsappMetaConnectDescriptor instead')
const ReqChannelWhatsappMetaConnect$json = {
  '1': 'ReqChannelWhatsappMetaConnect',
  '2': [
    {'1': 'bot_iid', '3': 1, '4': 1, '5': 3, '10': 'botIid'},
    {'1': 'access_token', '3': 2, '4': 1, '5': 9, '10': 'accessToken'},
    {'1': 'phone_number_id', '3': 3, '4': 1, '5': 9, '10': 'phoneNumberId'},
  ],
};

/// Descriptor for `ReqChannelWhatsappMetaConnect`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqChannelWhatsappMetaConnectDescriptor =
    $convert.base64Decode(
        'Ch1SZXFDaGFubmVsV2hhdHNhcHBNZXRhQ29ubmVjdBIXCgdib3RfaWlkGAEgASgDUgZib3RJaW'
        'QSIQoMYWNjZXNzX3Rva2VuGAIgASgJUgthY2Nlc3NUb2tlbhImCg9waG9uZV9udW1iZXJfaWQY'
        'AyABKAlSDXBob25lTnVtYmVySWQ=');

@$core.Deprecated('Use resChannelWhatsappMetaConnectDescriptor instead')
const ResChannelWhatsappMetaConnect$json = {
  '1': 'ResChannelWhatsappMetaConnect',
  '2': [
    {'1': 'bot_iid', '3': 1, '4': 1, '5': 3, '10': 'botIid'},
    {
      '1': 'channel',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.c35.BotChannelDoc',
      '10': 'channel'
    },
    {'1': 'webhook_url', '3': 3, '4': 1, '5': 9, '10': 'webhookUrl'},
    {'1': 'verify_token', '3': 4, '4': 1, '5': 9, '10': 'verifyToken'},
  ],
};

/// Descriptor for `ResChannelWhatsappMetaConnect`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resChannelWhatsappMetaConnectDescriptor = $convert.base64Decode(
    'Ch1SZXNDaGFubmVsV2hhdHNhcHBNZXRhQ29ubmVjdBIXCgdib3RfaWlkGAEgASgDUgZib3RJaW'
    'QSLAoHY2hhbm5lbBgCIAEoCzISLmMzNS5Cb3RDaGFubmVsRG9jUgdjaGFubmVsEh8KC3dlYmhv'
    'b2tfdXJsGAMgASgJUgp3ZWJob29rVXJsEiEKDHZlcmlmeV90b2tlbhgEIAEoCVILdmVyaWZ5VG'
    '9rZW4=');

@$core.Deprecated('Use channelWebhookResDescriptor instead')
const ChannelWebhookRes$json = {
  '1': 'ChannelWebhookRes',
  '2': [
    {'1': 'status', '3': 1, '4': 1, '5': 9, '10': 'status'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
    {'1': 'chat_id', '3': 3, '4': 1, '5': 3, '10': 'chatId'},
    {'1': 'peer_iid', '3': 4, '4': 1, '5': 3, '10': 'peerIid'},
  ],
};

/// Descriptor for `ChannelWebhookRes`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List channelWebhookResDescriptor = $convert.base64Decode(
    'ChFDaGFubmVsV2ViaG9va1JlcxIWCgZzdGF0dXMYASABKAlSBnN0YXR1cxIYCgdtZXNzYWdlGA'
    'IgASgJUgdtZXNzYWdlEhcKB2NoYXRfaWQYAyABKANSBmNoYXRJZBIZCghwZWVyX2lpZBgEIAEo'
    'A1IHcGVlcklpZA==');

@$core.Deprecated('Use reqChannelWhatsappPairStartDescriptor instead')
const ReqChannelWhatsappPairStart$json = {
  '1': 'ReqChannelWhatsappPairStart',
  '2': [
    {'1': 'bot_iid', '3': 1, '4': 1, '5': 3, '10': 'botIid'},
    {'1': 'channel_id', '3': 2, '4': 1, '5': 9, '10': 'channelId'},
  ],
};

/// Descriptor for `ReqChannelWhatsappPairStart`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqChannelWhatsappPairStartDescriptor =
    $convert.base64Decode(
        'ChtSZXFDaGFubmVsV2hhdHNhcHBQYWlyU3RhcnQSFwoHYm90X2lpZBgBIAEoA1IGYm90SWlkEh'
        '0KCmNoYW5uZWxfaWQYAiABKAlSCWNoYW5uZWxJZA==');

@$core.Deprecated('Use reqChannelWhatsappPairWatchDescriptor instead')
const ReqChannelWhatsappPairWatch$json = {
  '1': 'ReqChannelWhatsappPairWatch',
  '2': [
    {'1': 'bot_iid', '3': 1, '4': 1, '5': 3, '10': 'botIid'},
    {'1': 'channel_id', '3': 2, '4': 1, '5': 9, '10': 'channelId'},
  ],
};

/// Descriptor for `ReqChannelWhatsappPairWatch`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqChannelWhatsappPairWatchDescriptor =
    $convert.base64Decode(
        'ChtSZXFDaGFubmVsV2hhdHNhcHBQYWlyV2F0Y2gSFwoHYm90X2lpZBgBIAEoA1IGYm90SWlkEh'
        '0KCmNoYW5uZWxfaWQYAiABKAlSCWNoYW5uZWxJZA==');

@$core.Deprecated('Use reqChannelWhatsappPairAbortDescriptor instead')
const ReqChannelWhatsappPairAbort$json = {
  '1': 'ReqChannelWhatsappPairAbort',
  '2': [
    {'1': 'bot_iid', '3': 1, '4': 1, '5': 3, '10': 'botIid'},
    {'1': 'channel_id', '3': 2, '4': 1, '5': 9, '10': 'channelId'},
  ],
};

/// Descriptor for `ReqChannelWhatsappPairAbort`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqChannelWhatsappPairAbortDescriptor =
    $convert.base64Decode(
        'ChtSZXFDaGFubmVsV2hhdHNhcHBQYWlyQWJvcnQSFwoHYm90X2lpZBgBIAEoA1IGYm90SWlkEh'
        '0KCmNoYW5uZWxfaWQYAiABKAlSCWNoYW5uZWxJZA==');

@$core.Deprecated('Use resChannelWhatsappPairDescriptor instead')
const ResChannelWhatsappPair$json = {
  '1': 'ResChannelWhatsappPair',
  '2': [
    {'1': 'ok', '3': 1, '4': 1, '5': 8, '10': 'ok'},
    {'1': 'error', '3': 2, '4': 1, '5': 9, '10': 'error'},
    {'1': 'bot_iid', '3': 3, '4': 1, '5': 3, '10': 'botIid'},
    {
      '1': 'channel',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.c35.BotChannelDoc',
      '10': 'channel'
    },
    {'1': 'qr_raw', '3': 5, '4': 1, '5': 9, '10': 'qrRaw'},
    {'1': 'phone', '3': 6, '4': 1, '5': 9, '10': 'phone'},
  ],
};

/// Descriptor for `ResChannelWhatsappPair`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resChannelWhatsappPairDescriptor = $convert.base64Decode(
    'ChZSZXNDaGFubmVsV2hhdHNhcHBQYWlyEg4KAm9rGAEgASgIUgJvaxIUCgVlcnJvchgCIAEoCV'
    'IFZXJyb3ISFwoHYm90X2lpZBgDIAEoA1IGYm90SWlkEiwKB2NoYW5uZWwYBCABKAsyEi5jMzUu'
    'Qm90Q2hhbm5lbERvY1IHY2hhbm5lbBIVCgZxcl9yYXcYBSABKAlSBXFyUmF3EhQKBXBob25lGA'
    'YgASgJUgVwaG9uZQ==');

@$core.Deprecated('Use channelPairPushDescriptor instead')
const ChannelPairPush$json = {
  '1': 'ChannelPairPush',
  '2': [
    {'1': 'bot_iid', '3': 1, '4': 1, '5': 3, '10': 'botIid'},
    {'1': 'channel_id', '3': 2, '4': 1, '5': 9, '10': 'channelId'},
    {'1': 'status', '3': 3, '4': 1, '5': 9, '10': 'status'},
    {'1': 'qr_raw', '3': 4, '4': 1, '5': 9, '10': 'qrRaw'},
    {'1': 'phone', '3': 5, '4': 1, '5': 9, '10': 'phone'},
    {'1': 'error_message', '3': 6, '4': 1, '5': 9, '10': 'errorMessage'},
  ],
};

/// Descriptor for `ChannelPairPush`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List channelPairPushDescriptor = $convert.base64Decode(
    'Cg9DaGFubmVsUGFpclB1c2gSFwoHYm90X2lpZBgBIAEoA1IGYm90SWlkEh0KCmNoYW5uZWxfaW'
    'QYAiABKAlSCWNoYW5uZWxJZBIWCgZzdGF0dXMYAyABKAlSBnN0YXR1cxIVCgZxcl9yYXcYBCAB'
    'KAlSBXFyUmF3EhQKBXBob25lGAUgASgJUgVwaG9uZRIjCg1lcnJvcl9tZXNzYWdlGAYgASgJUg'
    'xlcnJvck1lc3NhZ2U=');
