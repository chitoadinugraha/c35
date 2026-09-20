//
//  Generated code. Do not modify.
//  source: c35/chat.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use chatKindDescriptor instead')
const ChatKind$json = {
  '1': 'ChatKind',
  '2': [
    {'1': 'CHAT_KIND_UNSPECIFIED', '2': 0},
    {'1': 'CHAT_KIND_PROMPT', '2': 1},
    {'1': 'CHAT_KIND_DIRECT', '2': 2},
    {'1': 'CHAT_KIND_BOT_PEER', '2': 3},
  ],
};

/// Descriptor for `ChatKind`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List chatKindDescriptor = $convert.base64Decode(
    'CghDaGF0S2luZBIZChVDSEFUX0tJTkRfVU5TUEVDSUZJRUQQABIUChBDSEFUX0tJTkRfUFJPTV'
    'BUEAESFAoQQ0hBVF9LSU5EX0RJUkVDVBACEhYKEkNIQVRfS0lORF9CT1RfUEVFUhAD');

@$core.Deprecated('Use chatMsgRoleDescriptor instead')
const ChatMsgRole$json = {
  '1': 'ChatMsgRole',
  '2': [
    {'1': 'CHAT_MSG_ROLE_UNSPECIFIED', '2': 0},
    {'1': 'CHAT_MSG_ROLE_USER', '2': 1},
    {'1': 'CHAT_MSG_ROLE_ASSISTANT', '2': 2},
    {'1': 'CHAT_MSG_ROLE_SYSTEM', '2': 3},
  ],
};

/// Descriptor for `ChatMsgRole`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List chatMsgRoleDescriptor = $convert.base64Decode(
    'CgtDaGF0TXNnUm9sZRIdChlDSEFUX01TR19ST0xFX1VOU1BFQ0lGSUVEEAASFgoSQ0hBVF9NU0'
    'dfUk9MRV9VU0VSEAESGwoXQ0hBVF9NU0dfUk9MRV9BU1NJU1RBTlQQAhIYChRDSEFUX01TR19S'
    'T0xFX1NZU1RFTRAD');

@$core.Deprecated('Use chatMsgSourceDescriptor instead')
const ChatMsgSource$json = {
  '1': 'ChatMsgSource',
  '2': [
    {'1': 'CHAT_MSG_SOURCE_UNSPECIFIED', '2': 0},
    {'1': 'CHAT_MSG_SOURCE_PROMPT', '2': 1},
    {'1': 'CHAT_MSG_SOURCE_USER', '2': 2},
    {'1': 'CHAT_MSG_SOURCE_EXTERNAL', '2': 3},
    {'1': 'CHAT_MSG_SOURCE_STAFF', '2': 4},
  ],
};

/// Descriptor for `ChatMsgSource`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List chatMsgSourceDescriptor = $convert.base64Decode(
    'Cg1DaGF0TXNnU291cmNlEh8KG0NIQVRfTVNHX1NPVVJDRV9VTlNQRUNJRklFRBAAEhoKFkNIQV'
    'RfTVNHX1NPVVJDRV9QUk9NUFQQARIYChRDSEFUX01TR19TT1VSQ0VfVVNFUhACEhwKGENIQVRf'
    'TVNHX1NPVVJDRV9FWFRFUk5BTBADEhkKFUNIQVRfTVNHX1NPVVJDRV9TVEFGRhAE');

@$core.Deprecated('Use chatMsgStatusDescriptor instead')
const ChatMsgStatus$json = {
  '1': 'ChatMsgStatus',
  '2': [
    {'1': 'CHAT_MSG_STATUS_UNSPECIFIED', '2': 0},
    {'1': 'CHAT_MSG_STATUS_STREAMING', '2': 1},
    {'1': 'CHAT_MSG_STATUS_DONE', '2': 2},
    {'1': 'CHAT_MSG_STATUS_INTERRUPTED', '2': 3},
    {'1': 'CHAT_MSG_STATUS_ERROR', '2': 4},
  ],
};

/// Descriptor for `ChatMsgStatus`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List chatMsgStatusDescriptor = $convert.base64Decode(
    'Cg1DaGF0TXNnU3RhdHVzEh8KG0NIQVRfTVNHX1NUQVRVU19VTlNQRUNJRklFRBAAEh0KGUNIQV'
    'RfTVNHX1NUQVRVU19TVFJFQU1JTkcQARIYChRDSEFUX01TR19TVEFUVVNfRE9ORRACEh8KG0NI'
    'QVRfTVNHX1NUQVRVU19JTlRFUlJVUFRFRBADEhkKFUNIQVRfTVNHX1NUQVRVU19FUlJPUhAE');

@$core.Deprecated('Use chatDescriptor instead')
const Chat$json = {
  '1': 'Chat',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 3, '10': 'id'},
    {'1': 'kind', '3': 2, '4': 1, '5': 14, '6': '.c35.ChatKind', '10': 'kind'},
    {'1': 'owner_iid', '3': 3, '4': 1, '5': 3, '10': 'ownerIid'},
    {'1': 'title', '3': 4, '4': 1, '5': 9, '10': 'title'},
    {'1': 'tag', '3': 5, '4': 1, '5': 9, '10': 'tag'},
    {'1': 'model', '3': 6, '4': 1, '5': 9, '10': 'model'},
    {'1': 'bot_iid', '3': 7, '4': 1, '5': 3, '10': 'botIid'},
    {'1': 'channel_id', '3': 8, '4': 1, '5': 9, '10': 'channelId'},
    {'1': 'peer_key', '3': 9, '4': 1, '5': 9, '10': 'peerKey'},
    {'1': 'peer_name', '3': 10, '4': 1, '5': 9, '10': 'peerName'},
    {'1': 'peer_pic', '3': 11, '4': 1, '5': 9, '10': 'peerPic'},
    {'1': 'ai_reply_enabled', '3': 12, '4': 1, '5': 8, '10': 'aiReplyEnabled'},
    {'1': 'last_msg_ts_ms', '3': 13, '4': 1, '5': 3, '10': 'lastMsgTsMs'},
    {'1': 'last_msg_preview', '3': 14, '4': 1, '5': 9, '10': 'lastMsgPreview'},
    {'1': 'meta_json', '3': 15, '4': 1, '5': 9, '10': 'metaJson'},
    {'1': 'created_ts_ms', '3': 16, '4': 1, '5': 3, '10': 'createdTsMs'},
    {'1': 'updated_ts_ms', '3': 17, '4': 1, '5': 3, '10': 'updatedTsMs'},
    {'1': 'deleted_ts_ms', '3': 18, '4': 1, '5': 3, '10': 'deletedTsMs'},
  ],
};

/// Descriptor for `Chat`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List chatDescriptor = $convert.base64Decode(
    'CgRDaGF0Eg4KAmlkGAEgASgDUgJpZBIhCgRraW5kGAIgASgOMg0uYzM1LkNoYXRLaW5kUgRraW'
    '5kEhsKCW93bmVyX2lpZBgDIAEoA1IIb3duZXJJaWQSFAoFdGl0bGUYBCABKAlSBXRpdGxlEhAK'
    'A3RhZxgFIAEoCVIDdGFnEhQKBW1vZGVsGAYgASgJUgVtb2RlbBIXCgdib3RfaWlkGAcgASgDUg'
    'Zib3RJaWQSHQoKY2hhbm5lbF9pZBgIIAEoCVIJY2hhbm5lbElkEhkKCHBlZXJfa2V5GAkgASgJ'
    'UgdwZWVyS2V5EhsKCXBlZXJfbmFtZRgKIAEoCVIIcGVlck5hbWUSGQoIcGVlcl9waWMYCyABKA'
    'lSB3BlZXJQaWMSKAoQYWlfcmVwbHlfZW5hYmxlZBgMIAEoCFIOYWlSZXBseUVuYWJsZWQSIwoO'
    'bGFzdF9tc2dfdHNfbXMYDSABKANSC2xhc3RNc2dUc01zEigKEGxhc3RfbXNnX3ByZXZpZXcYDi'
    'ABKAlSDmxhc3RNc2dQcmV2aWV3EhsKCW1ldGFfanNvbhgPIAEoCVIIbWV0YUpzb24SIgoNY3Jl'
    'YXRlZF90c19tcxgQIAEoA1ILY3JlYXRlZFRzTXMSIgoNdXBkYXRlZF90c19tcxgRIAEoA1ILdX'
    'BkYXRlZFRzTXMSIgoNZGVsZXRlZF90c19tcxgSIAEoA1ILZGVsZXRlZFRzTXM=');

@$core.Deprecated('Use chatMemberDescriptor instead')
const ChatMember$json = {
  '1': 'ChatMember',
  '2': [
    {'1': 'chat_id', '3': 1, '4': 1, '5': 3, '10': 'chatId'},
    {'1': 'member_iid', '3': 2, '4': 1, '5': 3, '10': 'memberIid'},
    {'1': 'last_read_msg_id', '3': 3, '4': 1, '5': 3, '10': 'lastReadMsgId'},
    {'1': 'unread_count', '3': 4, '4': 1, '5': 5, '10': 'unreadCount'},
    {'1': 'last_msg_ts_ms', '3': 5, '4': 1, '5': 3, '10': 'lastMsgTsMs'},
    {'1': 'last_msg_preview', '3': 6, '4': 1, '5': 9, '10': 'lastMsgPreview'},
    {'1': 'pinned_ts_ms', '3': 7, '4': 1, '5': 3, '10': 'pinnedTsMs'},
    {'1': 'archived_ts_ms', '3': 8, '4': 1, '5': 3, '10': 'archivedTsMs'},
    {'1': 'created_ts_ms', '3': 9, '4': 1, '5': 3, '10': 'createdTsMs'},
    {'1': 'updated_ts_ms', '3': 10, '4': 1, '5': 3, '10': 'updatedTsMs'},
    {'1': 'deleted_ts_ms', '3': 11, '4': 1, '5': 3, '10': 'deletedTsMs'},
  ],
};

/// Descriptor for `ChatMember`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List chatMemberDescriptor = $convert.base64Decode(
    'CgpDaGF0TWVtYmVyEhcKB2NoYXRfaWQYASABKANSBmNoYXRJZBIdCgptZW1iZXJfaWlkGAIgAS'
    'gDUgltZW1iZXJJaWQSJwoQbGFzdF9yZWFkX21zZ19pZBgDIAEoA1INbGFzdFJlYWRNc2dJZBIh'
    'Cgx1bnJlYWRfY291bnQYBCABKAVSC3VucmVhZENvdW50EiMKDmxhc3RfbXNnX3RzX21zGAUgAS'
    'gDUgtsYXN0TXNnVHNNcxIoChBsYXN0X21zZ19wcmV2aWV3GAYgASgJUg5sYXN0TXNnUHJldmll'
    'dxIgCgxwaW5uZWRfdHNfbXMYByABKANSCnBpbm5lZFRzTXMSJAoOYXJjaGl2ZWRfdHNfbXMYCC'
    'ABKANSDGFyY2hpdmVkVHNNcxIiCg1jcmVhdGVkX3RzX21zGAkgASgDUgtjcmVhdGVkVHNNcxIi'
    'Cg11cGRhdGVkX3RzX21zGAogASgDUgt1cGRhdGVkVHNNcxIiCg1kZWxldGVkX3RzX21zGAsgAS'
    'gDUgtkZWxldGVkVHNNcw==');

@$core.Deprecated('Use chatMsgDescriptor instead')
const ChatMsg$json = {
  '1': 'ChatMsg',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 3, '10': 'id'},
    {'1': 'chat_id', '3': 2, '4': 1, '5': 3, '10': 'chatId'},
    {'1': 'owner_iid', '3': 3, '4': 1, '5': 3, '10': 'ownerIid'},
    {'1': 'req_id', '3': 4, '4': 1, '5': 9, '10': 'reqId'},
    {'1': 'sender_iid', '3': 5, '4': 1, '5': 3, '10': 'senderIid'},
    {'1': 'role', '3': 6, '4': 1, '5': 14, '6': '.c35.ChatMsgRole', '10': 'role'},
    {'1': 'source', '3': 7, '4': 1, '5': 14, '6': '.c35.ChatMsgSource', '10': 'source'},
    {'1': 'content', '3': 8, '4': 1, '5': 9, '10': 'content'},
    {'1': 'thought', '3': 9, '4': 1, '5': 9, '10': 'thought'},
    {'1': 'attachments_json', '3': 10, '4': 1, '5': 9, '10': 'attachmentsJson'},
    {'1': 'blocks_json', '3': 11, '4': 1, '5': 9, '10': 'blocksJson'},
    {'1': 'tokens_in', '3': 12, '4': 1, '5': 5, '10': 'tokensIn'},
    {'1': 'tokens_out', '3': 13, '4': 1, '5': 5, '10': 'tokensOut'},
    {'1': 'duration_ms', '3': 14, '4': 1, '5': 5, '10': 'durationMs'},
    {'1': 'status', '3': 15, '4': 1, '5': 14, '6': '.c35.ChatMsgStatus', '10': 'status'},
    {'1': 'cost_usd', '3': 16, '4': 1, '5': 1, '10': 'costUsd'},
    {'1': 'created_ts_ms', '3': 17, '4': 1, '5': 3, '10': 'createdTsMs'},
    {'1': 'updated_ts_ms', '3': 18, '4': 1, '5': 3, '10': 'updatedTsMs'},
    {'1': 'deleted_ts_ms', '3': 19, '4': 1, '5': 3, '10': 'deletedTsMs'},
  ],
};

/// Descriptor for `ChatMsg`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List chatMsgDescriptor = $convert.base64Decode(
    'CgdDaGF0TXNnEg4KAmlkGAEgASgDUgJpZBIXCgdjaGF0X2lkGAIgASgDUgZjaGF0SWQSGwoJb3'
    'duZXJfaWlkGAMgASgDUghvd25lcklpZBIVCgZyZXFfaWQYBCABKAlSBXJlcUlkEh0KCnNlbmRl'
    'cl9paWQYBSABKANSCXNlbmRlcklpZBIkCgRyb2xlGAYgASgOMhAuYzM1LkNoYXRNc2dSb2xlUg'
    'Ryb2xlEioKBnNvdXJjZRgHIAEoDjISLmMzNS5DaGF0TXNnU291cmNlUgZzb3VyY2USGAoHY29u'
    'dGVudBgIIAEoCVIHY29udGVudBIYCgd0aG91Z2h0GAkgASgJUgd0aG91Z2h0EikKEGF0dGFjaG'
    '1lbnRzX2pzb24YCiABKAlSD2F0dGFjaG1lbnRzSnNvbhIfCgtibG9ja3NfanNvbhgLIAEoCVIK'
    'YmxvY2tzSnNvbhIbCgl0b2tlbnNfaW4YDCABKAVSCHRva2Vuc0luEh0KCnRva2Vuc19vdXQYDS'
    'ABKAVSCXRva2Vuc091dBIfCgtkdXJhdGlvbl9tcxgOIAEoBVIKZHVyYXRpb25NcxIqCgZzdGF0'
    'dXMYDyABKA4yEi5jMzUuQ2hhdE1zZ1N0YXR1c1IGc3RhdHVzEhkKCGNvc3RfdXNkGBAgASgBUg'
    'djb3N0VXNkEiIKDWNyZWF0ZWRfdHNfbXMYESABKANSC2NyZWF0ZWRUc01zEiIKDXVwZGF0ZWRf'
    'dHNfbXMYEiABKANSC3VwZGF0ZWRUc01zEiIKDWRlbGV0ZWRfdHNfbXMYEyABKANSC2RlbGV0ZW'
    'RUc01z');

@$core.Deprecated('Use reqInboxListDescriptor instead')
const ReqInboxList$json = {
  '1': 'ReqInboxList',
  '2': [
    {'1': 'include_archived', '3': 1, '4': 1, '5': 8, '10': 'includeArchived'},
    {'1': 'limit', '3': 2, '4': 1, '5': 5, '10': 'limit'},
  ],
};

/// Descriptor for `ReqInboxList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqInboxListDescriptor = $convert.base64Decode(
    'CgxSZXFJbmJveExpc3QSKQoQaW5jbHVkZV9hcmNoaXZlZBgBIAEoCFIPaW5jbHVkZUFyY2hpdm'
    'VkEhQKBWxpbWl0GAIgASgFUgVsaW1pdA==');

@$core.Deprecated('Use resInboxListDescriptor instead')
const ResInboxList$json = {
  '1': 'ResInboxList',
  '2': [
    {'1': 'chats', '3': 1, '4': 3, '5': 11, '6': '.c35.Chat', '10': 'chats'},
    {'1': 'members', '3': 2, '4': 3, '5': 11, '6': '.c35.ChatMember', '10': 'members'},
  ],
};

/// Descriptor for `ResInboxList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resInboxListDescriptor = $convert.base64Decode(
    'CgxSZXNJbmJveExpc3QSHwoFY2hhdHMYASADKAsyCS5jMzUuQ2hhdFIFY2hhdHMSKQoHbWVtYm'
    'VycxgCIAMoCzIPLmMzNS5DaGF0TWVtYmVyUgdtZW1iZXJz');

@$core.Deprecated('Use reqChatMsgListDescriptor instead')
const ReqChatMsgList$json = {
  '1': 'ReqChatMsgList',
  '2': [
    {'1': 'chat_id', '3': 1, '4': 1, '5': 3, '10': 'chatId'},
    {'1': 'before_id', '3': 2, '4': 1, '5': 3, '10': 'beforeId'},
    {'1': 'limit', '3': 3, '4': 1, '5': 5, '10': 'limit'},
  ],
};

/// Descriptor for `ReqChatMsgList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqChatMsgListDescriptor = $convert.base64Decode(
    'Cg5SZXFDaGF0TXNnTGlzdBIXCgdjaGF0X2lkGAEgASgDUgZjaGF0SWQSGwoJYmVmb3JlX2lkGA'
    'IgASgDUghiZWZvcmVJZBIUCgVsaW1pdBgDIAEoBVIFbGltaXQ=');

@$core.Deprecated('Use resChatMsgListDescriptor instead')
const ResChatMsgList$json = {
  '1': 'ResChatMsgList',
  '2': [
    {'1': 'messages', '3': 1, '4': 3, '5': 11, '6': '.c35.ChatMsg', '10': 'messages'},
  ],
};

/// Descriptor for `ResChatMsgList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resChatMsgListDescriptor = $convert.base64Decode(
    'Cg5SZXNDaGF0TXNnTGlzdBIoCghtZXNzYWdlcxgBIAMoCzIMLmMzNS5DaGF0TXNnUghtZXNzYW'
    'dlcw==');

@$core.Deprecated('Use reqPromptDescriptor instead')
const ReqPrompt$json = {
  '1': 'ReqPrompt',
  '2': [
    {'1': 'chat_id', '3': 1, '4': 1, '5': 3, '10': 'chatId'},
    {'1': 'model', '3': 2, '4': 1, '5': 9, '10': 'model'},
    {'1': 'text', '3': 3, '4': 1, '5': 9, '10': 'text'},
    {'1': 'attachments_json', '3': 4, '4': 1, '5': 9, '10': 'attachmentsJson'},
    {'1': 'thinking', '3': 5, '4': 1, '5': 9, '10': 'thinking'},
  ],
};

/// Descriptor for `ReqPrompt`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqPromptDescriptor = $convert.base64Decode(
    'CglSZXFQcm9tcHQSFwoHY2hhdF9pZBgBIAEoA1IGY2hhdElkEhQKBW1vZGVsGAIgASgJUgVtb2'
    'RlbBISCgR0ZXh0GAMgASgJUgR0ZXh0EikKEGF0dGFjaG1lbnRzX2pzb24YBCABKAlSD2F0dGFj'
    'aG1lbnRzSnNvbhIaCgh0aGlua2luZxgFIAEoCVIIdGhpbmtpbmc=');

@$core.Deprecated('Use resPromptStartDescriptor instead')
const ResPromptStart$json = {
  '1': 'ResPromptStart',
  '2': [
    {'1': 'chat_id', '3': 1, '4': 1, '5': 3, '10': 'chatId'},
    {'1': 'msg_id', '3': 2, '4': 1, '5': 3, '10': 'msgId'},
    {'1': 'model', '3': 3, '4': 1, '5': 9, '10': 'model'},
  ],
};

/// Descriptor for `ResPromptStart`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resPromptStartDescriptor = $convert.base64Decode(
    'Cg5SZXNQcm9tcHRTdGFydBIXCgdjaGF0X2lkGAEgASgDUgZjaGF0SWQSFQoGbXNnX2lkGAIgAS'
    'gDUgVtc2dJZBIUCgVtb2RlbBgDIAEoCVIFbW9kZWw=');

@$core.Deprecated('Use resPromptDeltaDescriptor instead')
const ResPromptDelta$json = {
  '1': 'ResPromptDelta',
  '2': [
    {'1': 'text', '3': 1, '4': 1, '5': 9, '10': 'text'},
    {'1': 'thought', '3': 2, '4': 1, '5': 8, '10': 'thought'},
    {'1': 'blocks_json', '3': 3, '4': 1, '5': 9, '10': 'blocksJson'},
  ],
};

/// Descriptor for `ResPromptDelta`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resPromptDeltaDescriptor = $convert.base64Decode(
    'Cg5SZXNQcm9tcHREZWx0YRISCgR0ZXh0GAEgASgJUgR0ZXh0EhgKB3Rob3VnaHQYAiABKAhSB3'
    'Rob3VnaHQSHwoLYmxvY2tzX2pzb24YAyABKAlSCmJsb2Nrc0pzb24=');

@$core.Deprecated('Use resPromptEndDescriptor instead')
const ResPromptEnd$json = {
  '1': 'ResPromptEnd',
  '2': [
    {'1': 'msg_id', '3': 1, '4': 1, '5': 3, '10': 'msgId'},
    {'1': 'tokens_in', '3': 2, '4': 1, '5': 5, '10': 'tokensIn'},
    {'1': 'tokens_out', '3': 3, '4': 1, '5': 5, '10': 'tokensOut'},
    {'1': 'cost_usd', '3': 4, '4': 1, '5': 1, '10': 'costUsd'},
    {'1': 'duration_ms', '3': 5, '4': 1, '5': 5, '10': 'durationMs'},
    {'1': 'model', '3': 6, '4': 1, '5': 9, '10': 'model'},
    {'1': 'req_id', '3': 7, '4': 1, '5': 9, '10': 'reqId'},
  ],
};

/// Descriptor for `ResPromptEnd`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resPromptEndDescriptor = $convert.base64Decode(
    'CgxSZXNQcm9tcHRFbmQSFQoGbXNnX2lkGAEgASgDUgVtc2dJZBIbCgl0b2tlbnNfaW4YAiABKA'
    'VSCHRva2Vuc0luEh0KCnRva2Vuc19vdXQYAyABKAVSCXRva2Vuc091dBIZCghjb3N0X3VzZBgE'
    'IAEoAVIHY29zdFVzZBIfCgtkdXJhdGlvbl9tcxgFIAEoBVIKZHVyYXRpb25NcxIUCgVtb2RlbB'
    'gGIAEoCVIFbW9kZWwSFQoGcmVxX2lkGAcgASgJUgVyZXFJZA==');

@$core.Deprecated('Use resPromptFailDescriptor instead')
const ResPromptFail$json = {
  '1': 'ResPromptFail',
  '2': [
    {'1': 'message', '3': 1, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `ResPromptFail`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resPromptFailDescriptor = $convert.base64Decode(
    'Cg1SZXNQcm9tcHRGYWlsEhgKB21lc3NhZ2UYASABKAlSB21lc3NhZ2U=');

@$core.Deprecated('Use reqPromptAbortDescriptor instead')
const ReqPromptAbort$json = {
  '1': 'ReqPromptAbort',
  '2': [
    {'1': 'chat_id', '3': 1, '4': 1, '5': 3, '10': 'chatId'},
  ],
};

/// Descriptor for `ReqPromptAbort`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqPromptAbortDescriptor = $convert.base64Decode(
    'Cg5SZXFQcm9tcHRBYm9ydBIXCgdjaGF0X2lkGAEgASgDUgZjaGF0SWQ=');

@$core.Deprecated('Use reqChatStopDescriptor instead')
const ReqChatStop$json = {
  '1': 'ReqChatStop',
  '2': [
    {'1': 'chat_id', '3': 1, '4': 1, '5': 3, '10': 'chatId'},
    {'1': 'stopped', '3': 2, '4': 1, '5': 8, '10': 'stopped'},
  ],
};

/// Descriptor for `ReqChatStop`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqChatStopDescriptor = $convert.base64Decode(
    'CgtSZXFDaGF0U3RvcBIXCgdjaGF0X2lkGAEgASgDUgZjaGF0SWQSGAoHc3RvcHBlZBgCIAEoCF'
    'IHc3RvcHBlZA==');

@$core.Deprecated('Use resChatStopDescriptor instead')
const ResChatStop$json = {
  '1': 'ResChatStop',
  '2': [
    {'1': 'chat_id', '3': 1, '4': 1, '5': 3, '10': 'chatId'},
    {'1': 'ai_reply_enabled', '3': 2, '4': 1, '5': 8, '10': 'aiReplyEnabled'},
  ],
};

/// Descriptor for `ResChatStop`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resChatStopDescriptor = $convert.base64Decode(
    'CgtSZXNDaGF0U3RvcBIXCgdjaGF0X2lkGAEgASgDUgZjaGF0SWQSKAoQYWlfcmVwbHlfZW5hYm'
    'xlZBgCIAEoCFIOYWlSZXBseUVuYWJsZWQ=');

@$core.Deprecated('Use reqChatSendDescriptor instead')
const ReqChatSend$json = {
  '1': 'ReqChatSend',
  '2': [
    {'1': 'chat_id', '3': 1, '4': 1, '5': 3, '10': 'chatId'},
    {'1': 'text', '3': 2, '4': 1, '5': 9, '10': 'text'},
    {'1': 'attachments_json', '3': 3, '4': 1, '5': 9, '10': 'attachmentsJson'},
  ],
};

/// Descriptor for `ReqChatSend`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqChatSendDescriptor = $convert.base64Decode(
    'CgtSZXFDaGF0U2VuZBIXCgdjaGF0X2lkGAEgASgDUgZjaGF0SWQSEgoEdGV4dBgCIAEoCVIEdG'
    'V4dBIpChBhdHRhY2htZW50c19qc29uGAMgASgJUg9hdHRhY2htZW50c0pzb24=');

@$core.Deprecated('Use resChatSendDescriptor instead')
const ResChatSend$json = {
  '1': 'ResChatSend',
  '2': [
    {'1': 'message', '3': 1, '4': 1, '5': 11, '6': '.c35.ChatMsg', '10': 'message'},
  ],
};

/// Descriptor for `ResChatSend`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resChatSendDescriptor = $convert.base64Decode(
    'CgtSZXNDaGF0U2VuZBImCgdtZXNzYWdlGAEgASgLMgwuYzM1LkNoYXRNc2dSB21lc3NhZ2U=');

