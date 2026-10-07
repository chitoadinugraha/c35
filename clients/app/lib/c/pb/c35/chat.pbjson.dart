// This is a generated file - do not edit.
//
// Generated from c35/chat.proto.

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

@$core.Deprecated('Use promptFollowupKindDescriptor instead')
const PromptFollowupKind$json = {
  '1': 'PromptFollowupKind',
  '2': [
    {'1': 'PROMPT_FOLLOWUP_KIND_UNSPECIFIED', '2': 0},
    {'1': 'PROMPT_FOLLOWUP_KIND_STEER', '2': 1},
    {'1': 'PROMPT_FOLLOWUP_KIND_QUEUE', '2': 2},
  ],
};

/// Descriptor for `PromptFollowupKind`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List promptFollowupKindDescriptor = $convert.base64Decode(
    'ChJQcm9tcHRGb2xsb3d1cEtpbmQSJAogUFJPTVBUX0ZPTExPV1VQX0tJTkRfVU5TUEVDSUZJRU'
    'QQABIeChpQUk9NUFRfRk9MTE9XVVBfS0lORF9TVEVFUhABEh4KGlBST01QVF9GT0xMT1dVUF9L'
    'SU5EX1FVRVVFEAI=');

@$core.Deprecated('Use chatFeedbackVoteDescriptor instead')
const ChatFeedbackVote$json = {
  '1': 'ChatFeedbackVote',
  '2': [
    {'1': 'CHAT_FEEDBACK_VOTE_UNSPECIFIED', '2': 0},
    {'1': 'CHAT_FEEDBACK_VOTE_GOOD', '2': 1},
    {'1': 'CHAT_FEEDBACK_VOTE_BAD', '2': 2},
  ],
};

/// Descriptor for `ChatFeedbackVote`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List chatFeedbackVoteDescriptor = $convert.base64Decode(
    'ChBDaGF0RmVlZGJhY2tWb3RlEiIKHkNIQVRfRkVFREJBQ0tfVk9URV9VTlNQRUNJRklFRBAAEh'
    'sKF0NIQVRfRkVFREJBQ0tfVk9URV9HT09EEAESGgoWQ0hBVF9GRUVEQkFDS19WT1RFX0JBRBAC');

@$core.Deprecated('Use chatFeedbackAuthorRoleDescriptor instead')
const ChatFeedbackAuthorRole$json = {
  '1': 'ChatFeedbackAuthorRole',
  '2': [
    {'1': 'CHAT_FEEDBACK_AUTHOR_ROLE_UNSPECIFIED', '2': 0},
    {'1': 'CHAT_FEEDBACK_AUTHOR_ROLE_SYSTEM', '2': 1},
    {'1': 'CHAT_FEEDBACK_AUTHOR_ROLE_USER', '2': 2},
    {'1': 'CHAT_FEEDBACK_AUTHOR_ROLE_STAFF', '2': 3},
  ],
};

/// Descriptor for `ChatFeedbackAuthorRole`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List chatFeedbackAuthorRoleDescriptor = $convert.base64Decode(
    'ChZDaGF0RmVlZGJhY2tBdXRob3JSb2xlEikKJUNIQVRfRkVFREJBQ0tfQVVUSE9SX1JPTEVfVU'
    '5TUEVDSUZJRUQQABIkCiBDSEFUX0ZFRURCQUNLX0FVVEhPUl9ST0xFX1NZU1RFTRABEiIKHkNI'
    'QVRfRkVFREJBQ0tfQVVUSE9SX1JPTEVfVVNFUhACEiMKH0NIQVRfRkVFREJBQ0tfQVVUSE9SX1'
    'JPTEVfU1RBRkYQAw==');

@$core.Deprecated('Use chatDescriptor instead')
const Chat$json = {
  '1': 'Chat',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 3, '10': 'id'},
    {'1': 'kind', '3': 2, '4': 1, '5': 14, '6': '.c35.ChatKind', '10': 'kind'},
    {'1': 'owner_iid', '3': 3, '4': 1, '5': 3, '10': 'ownerIid'},
    {'1': 'title', '3': 4, '4': 1, '5': 9, '10': 'title'},
    {'1': 'tags', '3': 5, '4': 3, '5': 9, '10': 'tags'},
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
    {'1': 'context_window', '3': 19, '4': 1, '5': 5, '10': 'contextWindow'},
  ],
};

/// Descriptor for `Chat`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List chatDescriptor = $convert.base64Decode(
    'CgRDaGF0Eg4KAmlkGAEgASgDUgJpZBIhCgRraW5kGAIgASgOMg0uYzM1LkNoYXRLaW5kUgRraW'
    '5kEhsKCW93bmVyX2lpZBgDIAEoA1IIb3duZXJJaWQSFAoFdGl0bGUYBCABKAlSBXRpdGxlEhIK'
    'BHRhZ3MYBSADKAlSBHRhZ3MSFAoFbW9kZWwYBiABKAlSBW1vZGVsEhcKB2JvdF9paWQYByABKA'
    'NSBmJvdElpZBIdCgpjaGFubmVsX2lkGAggASgJUgljaGFubmVsSWQSGQoIcGVlcl9rZXkYCSAB'
    'KAlSB3BlZXJLZXkSGwoJcGVlcl9uYW1lGAogASgJUghwZWVyTmFtZRIZCghwZWVyX3BpYxgLIA'
    'EoCVIHcGVlclBpYxIoChBhaV9yZXBseV9lbmFibGVkGAwgASgIUg5haVJlcGx5RW5hYmxlZBIj'
    'Cg5sYXN0X21zZ190c19tcxgNIAEoA1ILbGFzdE1zZ1RzTXMSKAoQbGFzdF9tc2dfcHJldmlldx'
    'gOIAEoCVIObGFzdE1zZ1ByZXZpZXcSGwoJbWV0YV9qc29uGA8gASgJUghtZXRhSnNvbhIiCg1j'
    'cmVhdGVkX3RzX21zGBAgASgDUgtjcmVhdGVkVHNNcxIiCg11cGRhdGVkX3RzX21zGBEgASgDUg'
    't1cGRhdGVkVHNNcxIiCg1kZWxldGVkX3RzX21zGBIgASgDUgtkZWxldGVkVHNNcxIlCg5jb250'
    'ZXh0X3dpbmRvdxgTIAEoBVINY29udGV4dFdpbmRvdw==');

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
    {'1': 'last_msg_status', '3': 12, '4': 1, '5': 9, '10': 'lastMsgStatus'},
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
    'gDUgtkZWxldGVkVHNNcxImCg9sYXN0X21zZ19zdGF0dXMYDCABKAlSDWxhc3RNc2dTdGF0dXM=');

@$core.Deprecated('Use chatMsgDescriptor instead')
const ChatMsg$json = {
  '1': 'ChatMsg',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 3, '10': 'id'},
    {'1': 'chat_id', '3': 2, '4': 1, '5': 3, '10': 'chatId'},
    {'1': 'owner_iid', '3': 3, '4': 1, '5': 3, '10': 'ownerIid'},
    {'1': 'req_id', '3': 4, '4': 1, '5': 9, '10': 'reqId'},
    {'1': 'sender_iid', '3': 5, '4': 1, '5': 3, '10': 'senderIid'},
    {
      '1': 'role',
      '3': 6,
      '4': 1,
      '5': 14,
      '6': '.c35.ChatMsgRole',
      '10': 'role'
    },
    {
      '1': 'source',
      '3': 7,
      '4': 1,
      '5': 14,
      '6': '.c35.ChatMsgSource',
      '10': 'source'
    },
    {'1': 'content', '3': 8, '4': 1, '5': 9, '10': 'content'},
    {'1': 'thought', '3': 9, '4': 1, '5': 9, '10': 'thought'},
    {'1': 'attachments_json', '3': 10, '4': 1, '5': 9, '10': 'attachmentsJson'},
    {'1': 'blocks_json', '3': 11, '4': 1, '5': 9, '10': 'blocksJson'},
    {'1': 'tokens_in', '3': 12, '4': 1, '5': 5, '10': 'tokensIn'},
    {'1': 'tokens_out', '3': 13, '4': 1, '5': 5, '10': 'tokensOut'},
    {'1': 'duration_ms', '3': 14, '4': 1, '5': 5, '10': 'durationMs'},
    {
      '1': 'status',
      '3': 15,
      '4': 1,
      '5': 14,
      '6': '.c35.ChatMsgStatus',
      '10': 'status'
    },
    {'1': 'cost_usd', '3': 16, '4': 1, '5': 1, '10': 'costUsd'},
    {'1': 'created_ts_ms', '3': 17, '4': 1, '5': 3, '10': 'createdTsMs'},
    {'1': 'updated_ts_ms', '3': 18, '4': 1, '5': 3, '10': 'updatedTsMs'},
    {'1': 'deleted_ts_ms', '3': 19, '4': 1, '5': 3, '10': 'deletedTsMs'},
    {'1': 'error_text', '3': 20, '4': 1, '5': 9, '10': 'errorText'},
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
    'RUc01zEh0KCmVycm9yX3RleHQYFCABKAlSCWVycm9yVGV4dA==');

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
    {
      '1': 'members',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.c35.ChatMember',
      '10': 'members'
    },
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
    {
      '1': 'messages',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.c35.ChatMsg',
      '10': 'messages'
    },
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
    {'1': 'mention_ids', '3': 6, '4': 3, '5': 9, '10': 'mentionIds'},
    {'1': 'topic_id', '3': 7, '4': 1, '5': 9, '10': 'topicId'},
    {'1': 'tool_mode', '3': 8, '4': 1, '5': 9, '10': 'toolMode'},
    {'1': 'device_iids', '3': 9, '4': 3, '5': 3, '10': 'deviceIids'},
    {'1': 'talk', '3': 10, '4': 1, '5': 8, '10': 'talk'},
  ],
};

/// Descriptor for `ReqPrompt`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqPromptDescriptor = $convert.base64Decode(
    'CglSZXFQcm9tcHQSFwoHY2hhdF9pZBgBIAEoA1IGY2hhdElkEhQKBW1vZGVsGAIgASgJUgVtb2'
    'RlbBISCgR0ZXh0GAMgASgJUgR0ZXh0EikKEGF0dGFjaG1lbnRzX2pzb24YBCABKAlSD2F0dGFj'
    'aG1lbnRzSnNvbhIaCgh0aGlua2luZxgFIAEoCVIIdGhpbmtpbmcSHwoLbWVudGlvbl9pZHMYBi'
    'ADKAlSCm1lbnRpb25JZHMSGQoIdG9waWNfaWQYByABKAlSB3RvcGljSWQSGwoJdG9vbF9tb2Rl'
    'GAggASgJUgh0b29sTW9kZRIfCgtkZXZpY2VfaWlkcxgJIAMoA1IKZGV2aWNlSWlkcxISCgR0YW'
    'xrGAogASgIUgR0YWxr');

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

@$core.Deprecated('Use contextUsageDescriptor instead')
const ContextUsage$json = {
  '1': 'ContextUsage',
  '2': [
    {'1': 'instructions', '3': 1, '4': 1, '5': 5, '10': 'instructions'},
    {'1': 'memory', '3': 2, '4': 1, '5': 5, '10': 'memory'},
    {'1': 'context', '3': 3, '4': 1, '5': 5, '10': 'context'},
    {'1': 'tools', '3': 4, '4': 1, '5': 5, '10': 'tools'},
    {'1': 'conversation', '3': 5, '4': 1, '5': 5, '10': 'conversation'},
  ],
};

/// Descriptor for `ContextUsage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List contextUsageDescriptor = $convert.base64Decode(
    'CgxDb250ZXh0VXNhZ2USIgoMaW5zdHJ1Y3Rpb25zGAEgASgFUgxpbnN0cnVjdGlvbnMSFgoGbW'
    'Vtb3J5GAIgASgFUgZtZW1vcnkSGAoHY29udGV4dBgDIAEoBVIHY29udGV4dBIUCgV0b29scxgE'
    'IAEoBVIFdG9vbHMSIgoMY29udmVyc2F0aW9uGAUgASgFUgxjb252ZXJzYXRpb24=');

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
    {'1': 'trace_json', '3': 8, '4': 1, '5': 9, '10': 'traceJson'},
    {'1': 'error_message', '3': 9, '4': 1, '5': 9, '10': 'errorMessage'},
    {'1': 'prompt_tokens', '3': 10, '4': 1, '5': 5, '10': 'promptTokens'},
    {'1': 'context_window', '3': 11, '4': 1, '5': 5, '10': 'contextWindow'},
    {
      '1': 'usage',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.c35.ContextUsage',
      '10': 'usage'
    },
  ],
};

/// Descriptor for `ResPromptEnd`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resPromptEndDescriptor = $convert.base64Decode(
    'CgxSZXNQcm9tcHRFbmQSFQoGbXNnX2lkGAEgASgDUgVtc2dJZBIbCgl0b2tlbnNfaW4YAiABKA'
    'VSCHRva2Vuc0luEh0KCnRva2Vuc19vdXQYAyABKAVSCXRva2Vuc091dBIZCghjb3N0X3VzZBgE'
    'IAEoAVIHY29zdFVzZBIfCgtkdXJhdGlvbl9tcxgFIAEoBVIKZHVyYXRpb25NcxIUCgVtb2RlbB'
    'gGIAEoCVIFbW9kZWwSFQoGcmVxX2lkGAcgASgJUgVyZXFJZBIdCgp0cmFjZV9qc29uGAggASgJ'
    'Ugl0cmFjZUpzb24SIwoNZXJyb3JfbWVzc2FnZRgJIAEoCVIMZXJyb3JNZXNzYWdlEiMKDXByb2'
    '1wdF90b2tlbnMYCiABKAVSDHByb21wdFRva2VucxIlCg5jb250ZXh0X3dpbmRvdxgLIAEoBVIN'
    'Y29udGV4dFdpbmRvdxInCgV1c2FnZRgMIAEoCzIRLmMzNS5Db250ZXh0VXNhZ2VSBXVzYWdl');

@$core.Deprecated('Use resPromptFailDescriptor instead')
const ResPromptFail$json = {
  '1': 'ResPromptFail',
  '2': [
    {'1': 'message', '3': 1, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `ResPromptFail`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resPromptFailDescriptor = $convert
    .base64Decode('Cg1SZXNQcm9tcHRGYWlsEhgKB21lc3NhZ2UYASABKAlSB21lc3NhZ2U=');

@$core.Deprecated('Use reqPromptAbortDescriptor instead')
const ReqPromptAbort$json = {
  '1': 'ReqPromptAbort',
  '2': [
    {'1': 'chat_id', '3': 1, '4': 1, '5': 3, '10': 'chatId'},
    {'1': 'req_id', '3': 2, '4': 1, '5': 9, '10': 'reqId'},
  ],
};

/// Descriptor for `ReqPromptAbort`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqPromptAbortDescriptor = $convert.base64Decode(
    'Cg5SZXFQcm9tcHRBYm9ydBIXCgdjaGF0X2lkGAEgASgDUgZjaGF0SWQSFQoGcmVxX2lkGAIgAS'
    'gJUgVyZXFJZA==');

@$core.Deprecated('Use reqPromptFollowupPutDescriptor instead')
const ReqPromptFollowupPut$json = {
  '1': 'ReqPromptFollowupPut',
  '2': [
    {'1': 'chat_id', '3': 1, '4': 1, '5': 3, '10': 'chatId'},
    {'1': 'req_id', '3': 2, '4': 1, '5': 9, '10': 'reqId'},
    {'1': 'text', '3': 3, '4': 1, '5': 9, '10': 'text'},
    {'1': 'attachments_json', '3': 4, '4': 1, '5': 9, '10': 'attachmentsJson'},
    {
      '1': 'kind',
      '3': 5,
      '4': 1,
      '5': 14,
      '6': '.c35.PromptFollowupKind',
      '10': 'kind'
    },
  ],
};

/// Descriptor for `ReqPromptFollowupPut`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqPromptFollowupPutDescriptor = $convert.base64Decode(
    'ChRSZXFQcm9tcHRGb2xsb3d1cFB1dBIXCgdjaGF0X2lkGAEgASgDUgZjaGF0SWQSFQoGcmVxX2'
    'lkGAIgASgJUgVyZXFJZBISCgR0ZXh0GAMgASgJUgR0ZXh0EikKEGF0dGFjaG1lbnRzX2pzb24Y'
    'BCABKAlSD2F0dGFjaG1lbnRzSnNvbhIrCgRraW5kGAUgASgOMhcuYzM1LlByb21wdEZvbGxvd3'
    'VwS2luZFIEa2luZA==');

@$core.Deprecated('Use resPromptFollowupPutDescriptor instead')
const ResPromptFollowupPut$json = {
  '1': 'ResPromptFollowupPut',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'req_id', '3': 2, '4': 1, '5': 9, '10': 'reqId'},
    {'1': 'queue_depth', '3': 3, '4': 1, '5': 5, '10': 'queueDepth'},
    {'1': 'rejected', '3': 4, '4': 1, '5': 8, '10': 'rejected'},
    {'1': 'reject_reason', '3': 5, '4': 1, '5': 9, '10': 'rejectReason'},
  ],
};

/// Descriptor for `ResPromptFollowupPut`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resPromptFollowupPutDescriptor = $convert.base64Decode(
    'ChRSZXNQcm9tcHRGb2xsb3d1cFB1dBIOCgJpZBgBIAEoCVICaWQSFQoGcmVxX2lkGAIgASgJUg'
    'VyZXFJZBIfCgtxdWV1ZV9kZXB0aBgDIAEoBVIKcXVldWVEZXB0aBIaCghyZWplY3RlZBgEIAEo'
    'CFIIcmVqZWN0ZWQSIwoNcmVqZWN0X3JlYXNvbhgFIAEoCVIMcmVqZWN0UmVhc29u');

@$core.Deprecated('Use promptFollowupRowDescriptor instead')
const PromptFollowupRow$json = {
  '1': 'PromptFollowupRow',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'req_id', '3': 2, '4': 1, '5': 9, '10': 'reqId'},
    {'1': 'chat_id', '3': 3, '4': 1, '5': 3, '10': 'chatId'},
    {
      '1': 'kind',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.c35.PromptFollowupKind',
      '10': 'kind'
    },
    {'1': 'status', '3': 5, '4': 1, '5': 9, '10': 'status'},
    {'1': 'text', '3': 6, '4': 1, '5': 9, '10': 'text'},
    {'1': 'seq', '3': 7, '4': 1, '5': 5, '10': 'seq'},
    {'1': 'created_ts_ms', '3': 8, '4': 1, '5': 3, '10': 'createdTsMs'},
  ],
};

/// Descriptor for `PromptFollowupRow`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List promptFollowupRowDescriptor = $convert.base64Decode(
    'ChFQcm9tcHRGb2xsb3d1cFJvdxIOCgJpZBgBIAEoCVICaWQSFQoGcmVxX2lkGAIgASgJUgVyZX'
    'FJZBIXCgdjaGF0X2lkGAMgASgDUgZjaGF0SWQSKwoEa2luZBgEIAEoDjIXLmMzNS5Qcm9tcHRG'
    'b2xsb3d1cEtpbmRSBGtpbmQSFgoGc3RhdHVzGAUgASgJUgZzdGF0dXMSEgoEdGV4dBgGIAEoCV'
    'IEdGV4dBIQCgNzZXEYByABKAVSA3NlcRIiCg1jcmVhdGVkX3RzX21zGAggASgDUgtjcmVhdGVk'
    'VHNNcw==');

@$core.Deprecated('Use reqPromptFollowupListDescriptor instead')
const ReqPromptFollowupList$json = {
  '1': 'ReqPromptFollowupList',
  '2': [
    {'1': 'chat_id', '3': 1, '4': 1, '5': 3, '10': 'chatId'},
    {'1': 'req_id', '3': 2, '4': 1, '5': 9, '10': 'reqId'},
  ],
};

/// Descriptor for `ReqPromptFollowupList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqPromptFollowupListDescriptor = $convert.base64Decode(
    'ChVSZXFQcm9tcHRGb2xsb3d1cExpc3QSFwoHY2hhdF9pZBgBIAEoA1IGY2hhdElkEhUKBnJlcV'
    '9pZBgCIAEoCVIFcmVxSWQ=');

@$core.Deprecated('Use resPromptFollowupListDescriptor instead')
const ResPromptFollowupList$json = {
  '1': 'ResPromptFollowupList',
  '2': [
    {
      '1': 'items',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.c35.PromptFollowupRow',
      '10': 'items'
    },
    {'1': 'active_req_id', '3': 2, '4': 1, '5': 9, '10': 'activeReqId'},
  ],
};

/// Descriptor for `ResPromptFollowupList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resPromptFollowupListDescriptor = $convert.base64Decode(
    'ChVSZXNQcm9tcHRGb2xsb3d1cExpc3QSLAoFaXRlbXMYASADKAsyFi5jMzUuUHJvbXB0Rm9sbG'
    '93dXBSb3dSBWl0ZW1zEiIKDWFjdGl2ZV9yZXFfaWQYAiABKAlSC2FjdGl2ZVJlcUlk');

@$core.Deprecated('Use reqPromptFollowupCancelDescriptor instead')
const ReqPromptFollowupCancel$json = {
  '1': 'ReqPromptFollowupCancel',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
  ],
};

/// Descriptor for `ReqPromptFollowupCancel`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqPromptFollowupCancelDescriptor = $convert
    .base64Decode('ChdSZXFQcm9tcHRGb2xsb3d1cENhbmNlbBIOCgJpZBgBIAEoCVICaWQ=');

@$core.Deprecated('Use resPromptFollowupCancelDescriptor instead')
const ResPromptFollowupCancel$json = {
  '1': 'ResPromptFollowupCancel',
  '2': [
    {'1': 'ok', '3': 1, '4': 1, '5': 8, '10': 'ok'},
  ],
};

/// Descriptor for `ResPromptFollowupCancel`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resPromptFollowupCancelDescriptor = $convert
    .base64Decode('ChdSZXNQcm9tcHRGb2xsb3d1cENhbmNlbBIOCgJvaxgBIAEoCFICb2s=');

@$core.Deprecated('Use promptFollowupPushDescriptor instead')
const PromptFollowupPush$json = {
  '1': 'PromptFollowupPush',
  '2': [
    {'1': 'active_req_id', '3': 1, '4': 1, '5': 9, '10': 'activeReqId'},
    {
      '1': 'items',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.c35.PromptFollowupRow',
      '10': 'items'
    },
  ],
};

/// Descriptor for `PromptFollowupPush`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List promptFollowupPushDescriptor = $convert.base64Decode(
    'ChJQcm9tcHRGb2xsb3d1cFB1c2gSIgoNYWN0aXZlX3JlcV9pZBgBIAEoCVILYWN0aXZlUmVxSW'
    'QSLAoFaXRlbXMYAiADKAsyFi5jMzUuUHJvbXB0Rm9sbG93dXBSb3dSBWl0ZW1z');

@$core.Deprecated('Use promptRunPushDescriptor instead')
const PromptRunPush$json = {
  '1': 'PromptRunPush',
  '2': [
    {'1': 'req_id', '3': 1, '4': 1, '5': 9, '10': 'reqId'},
    {'1': 'parent_req_id', '3': 2, '4': 1, '5': 9, '10': 'parentReqId'},
    {'1': 'kind', '3': 3, '4': 1, '5': 9, '10': 'kind'},
    {'1': 'device_iid', '3': 4, '4': 1, '5': 3, '10': 'deviceIid'},
    {'1': 'status', '3': 5, '4': 1, '5': 9, '10': 'status'},
    {'1': 'label', '3': 6, '4': 1, '5': 9, '10': 'label'},
    {'1': 'topic_id', '3': 7, '4': 1, '5': 9, '10': 'topicId'},
    {'1': 'turn_count', '3': 8, '4': 1, '5': 5, '10': 'turnCount'},
    {'1': 'tokens_in', '3': 9, '4': 1, '5': 5, '10': 'tokensIn'},
    {'1': 'tokens_out', '3': 10, '4': 1, '5': 5, '10': 'tokensOut'},
    {'1': 'cost_usd', '3': 11, '4': 1, '5': 1, '10': 'costUsd'},
    {'1': 'duration_ms', '3': 12, '4': 1, '5': 5, '10': 'durationMs'},
    {'1': 'fail_class', '3': 13, '4': 1, '5': 9, '10': 'failClass'},
    {'1': 'fail_reason', '3': 14, '4': 1, '5': 9, '10': 'failReason'},
  ],
};

/// Descriptor for `PromptRunPush`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List promptRunPushDescriptor = $convert.base64Decode(
    'Cg1Qcm9tcHRSdW5QdXNoEhUKBnJlcV9pZBgBIAEoCVIFcmVxSWQSIgoNcGFyZW50X3JlcV9pZB'
    'gCIAEoCVILcGFyZW50UmVxSWQSEgoEa2luZBgDIAEoCVIEa2luZBIdCgpkZXZpY2VfaWlkGAQg'
    'ASgDUglkZXZpY2VJaWQSFgoGc3RhdHVzGAUgASgJUgZzdGF0dXMSFAoFbGFiZWwYBiABKAlSBW'
    'xhYmVsEhkKCHRvcGljX2lkGAcgASgJUgd0b3BpY0lkEh0KCnR1cm5fY291bnQYCCABKAVSCXR1'
    'cm5Db3VudBIbCgl0b2tlbnNfaW4YCSABKAVSCHRva2Vuc0luEh0KCnRva2Vuc19vdXQYCiABKA'
    'VSCXRva2Vuc091dBIZCghjb3N0X3VzZBgLIAEoAVIHY29zdFVzZBIfCgtkdXJhdGlvbl9tcxgM'
    'IAEoBVIKZHVyYXRpb25NcxIdCgpmYWlsX2NsYXNzGA0gASgJUglmYWlsQ2xhc3MSHwoLZmFpbF'
    '9yZWFzb24YDiABKAlSCmZhaWxSZWFzb24=');

@$core.Deprecated('Use promptRunJobDescriptor instead')
const PromptRunJob$json = {
  '1': 'PromptRunJob',
  '2': [
    {'1': 'req_id', '3': 1, '4': 1, '5': 9, '10': 'reqId'},
    {'1': 'owner_iid', '3': 2, '4': 1, '5': 3, '10': 'ownerIid'},
    {'1': 'chat_id', '3': 3, '4': 1, '5': 3, '10': 'chatId'},
  ],
};

/// Descriptor for `PromptRunJob`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List promptRunJobDescriptor = $convert.base64Decode(
    'CgxQcm9tcHRSdW5Kb2ISFQoGcmVxX2lkGAEgASgJUgVyZXFJZBIbCglvd25lcl9paWQYAiABKA'
    'NSCG93bmVySWlkEhcKB2NoYXRfaWQYAyABKANSBmNoYXRJZA==');

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
    {
      '1': 'message',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.c35.ChatMsg',
      '10': 'message'
    },
  ],
};

/// Descriptor for `ResChatSend`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resChatSendDescriptor = $convert.base64Decode(
    'CgtSZXNDaGF0U2VuZBImCgdtZXNzYWdlGAEgASgLMgwuYzM1LkNoYXRNc2dSB21lc3NhZ2U=');

@$core.Deprecated('Use tagSetDescriptor instead')
const TagSet$json = {
  '1': 'TagSet',
  '2': [
    {'1': 'tags', '3': 1, '4': 3, '5': 9, '10': 'tags'},
  ],
};

/// Descriptor for `TagSet`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List tagSetDescriptor =
    $convert.base64Decode('CgZUYWdTZXQSEgoEdGFncxgBIAMoCVIEdGFncw==');

@$core.Deprecated('Use reqChatPatchDescriptor instead')
const ReqChatPatch$json = {
  '1': 'ReqChatPatch',
  '2': [
    {'1': 'chat_id', '3': 1, '4': 1, '5': 3, '10': 'chatId'},
    {'1': 'pinned', '3': 2, '4': 1, '5': 8, '9': 0, '10': 'pinned', '17': true},
    {
      '1': 'archived',
      '3': 3,
      '4': 1,
      '5': 8,
      '9': 1,
      '10': 'archived',
      '17': true
    },
    {
      '1': 'tags',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.c35.TagSet',
      '9': 2,
      '10': 'tags',
      '17': true
    },
    {
      '1': 'deleted',
      '3': 5,
      '4': 1,
      '5': 8,
      '9': 3,
      '10': 'deleted',
      '17': true
    },
  ],
  '8': [
    {'1': '_pinned'},
    {'1': '_archived'},
    {'1': '_tags'},
    {'1': '_deleted'},
  ],
};

/// Descriptor for `ReqChatPatch`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqChatPatchDescriptor = $convert.base64Decode(
    'CgxSZXFDaGF0UGF0Y2gSFwoHY2hhdF9pZBgBIAEoA1IGY2hhdElkEhsKBnBpbm5lZBgCIAEoCE'
    'gAUgZwaW5uZWSIAQESHwoIYXJjaGl2ZWQYAyABKAhIAVIIYXJjaGl2ZWSIAQESJAoEdGFncxgE'
    'IAEoCzILLmMzNS5UYWdTZXRIAlIEdGFnc4gBARIdCgdkZWxldGVkGAUgASgISANSB2RlbGV0ZW'
    'SIAQFCCQoHX3Bpbm5lZEILCglfYXJjaGl2ZWRCBwoFX3RhZ3NCCgoIX2RlbGV0ZWQ=');

@$core.Deprecated('Use resChatPatchDescriptor instead')
const ResChatPatch$json = {
  '1': 'ResChatPatch',
  '2': [
    {'1': 'chat', '3': 1, '4': 1, '5': 11, '6': '.c35.Chat', '10': 'chat'},
    {
      '1': 'member',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.c35.ChatMember',
      '10': 'member'
    },
  ],
};

/// Descriptor for `ResChatPatch`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resChatPatchDescriptor = $convert.base64Decode(
    'CgxSZXNDaGF0UGF0Y2gSHQoEY2hhdBgBIAEoCzIJLmMzNS5DaGF0UgRjaGF0EicKBm1lbWJlch'
    'gCIAEoCzIPLmMzNS5DaGF0TWVtYmVyUgZtZW1iZXI=');

@$core.Deprecated('Use reqChatHistoryClearDescriptor instead')
const ReqChatHistoryClear$json = {
  '1': 'ReqChatHistoryClear',
  '2': [
    {'1': 'dry_run', '3': 1, '4': 1, '5': 8, '10': 'dryRun'},
  ],
};

/// Descriptor for `ReqChatHistoryClear`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqChatHistoryClearDescriptor =
    $convert.base64Decode(
        'ChNSZXFDaGF0SGlzdG9yeUNsZWFyEhcKB2RyeV9ydW4YASABKAhSBmRyeVJ1bg==');

@$core.Deprecated('Use resChatHistoryClearDescriptor instead')
const ResChatHistoryClear$json = {
  '1': 'ResChatHistoryClear',
  '2': [
    {'1': 'msgs_deleted', '3': 1, '4': 1, '5': 5, '10': 'msgsDeleted'},
    {'1': 'chats_affected', '3': 2, '4': 1, '5': 5, '10': 'chatsAffected'},
  ],
};

/// Descriptor for `ResChatHistoryClear`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resChatHistoryClearDescriptor = $convert.base64Decode(
    'ChNSZXNDaGF0SGlzdG9yeUNsZWFyEiEKDG1zZ3NfZGVsZXRlZBgBIAEoBVILbXNnc0RlbGV0ZW'
    'QSJQoOY2hhdHNfYWZmZWN0ZWQYAiABKAVSDWNoYXRzQWZmZWN0ZWQ=');

@$core.Deprecated('Use userMemoryDescriptor instead')
const UserMemory$json = {
  '1': 'UserMemory',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 3, '10': 'id'},
    {'1': 'owner_iid', '3': 2, '4': 1, '5': 3, '10': 'ownerIid'},
    {'1': 'bot_iid', '3': 3, '4': 1, '5': 3, '10': 'botIid'},
    {'1': 'category', '3': 4, '4': 1, '5': 9, '10': 'category'},
    {'1': 'key', '3': 5, '4': 1, '5': 9, '10': 'key'},
    {'1': 'content', '3': 6, '4': 1, '5': 9, '10': 'content'},
    {'1': 'confidence', '3': 7, '4': 1, '5': 1, '10': 'confidence'},
  ],
};

/// Descriptor for `UserMemory`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List userMemoryDescriptor = $convert.base64Decode(
    'CgpVc2VyTWVtb3J5Eg4KAmlkGAEgASgDUgJpZBIbCglvd25lcl9paWQYAiABKANSCG93bmVySW'
    'lkEhcKB2JvdF9paWQYAyABKANSBmJvdElpZBIaCghjYXRlZ29yeRgEIAEoCVIIY2F0ZWdvcnkS'
    'EAoDa2V5GAUgASgJUgNrZXkSGAoHY29udGVudBgGIAEoCVIHY29udGVudBIeCgpjb25maWRlbm'
    'NlGAcgASgBUgpjb25maWRlbmNl');

@$core.Deprecated('Use reqMemoryListDescriptor instead')
const ReqMemoryList$json = {
  '1': 'ReqMemoryList',
  '2': [
    {'1': 'limit', '3': 1, '4': 1, '5': 5, '10': 'limit'},
  ],
};

/// Descriptor for `ReqMemoryList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqMemoryListDescriptor = $convert
    .base64Decode('Cg1SZXFNZW1vcnlMaXN0EhQKBWxpbWl0GAEgASgFUgVsaW1pdA==');

@$core.Deprecated('Use resMemoryListDescriptor instead')
const ResMemoryList$json = {
  '1': 'ResMemoryList',
  '2': [
    {
      '1': 'items',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.c35.UserMemory',
      '10': 'items'
    },
  ],
};

/// Descriptor for `ResMemoryList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resMemoryListDescriptor = $convert.base64Decode(
    'Cg1SZXNNZW1vcnlMaXN0EiUKBWl0ZW1zGAEgAygLMg8uYzM1LlVzZXJNZW1vcnlSBWl0ZW1z');

@$core.Deprecated('Use reqMemoryDeleteDescriptor instead')
const ReqMemoryDelete$json = {
  '1': 'ReqMemoryDelete',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 3, '10': 'id'},
  ],
};

/// Descriptor for `ReqMemoryDelete`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqMemoryDeleteDescriptor =
    $convert.base64Decode('Cg9SZXFNZW1vcnlEZWxldGUSDgoCaWQYASABKANSAmlk');

@$core.Deprecated('Use resMemoryDeleteDescriptor instead')
const ResMemoryDelete$json = {
  '1': 'ResMemoryDelete',
  '2': [
    {'1': 'ok', '3': 1, '4': 1, '5': 8, '10': 'ok'},
  ],
};

/// Descriptor for `ResMemoryDelete`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resMemoryDeleteDescriptor =
    $convert.base64Decode('Cg9SZXNNZW1vcnlEZWxldGUSDgoCb2sYASABKAhSAm9r');

@$core.Deprecated('Use reqChatDeviceContextListDescriptor instead')
const ReqChatDeviceContextList$json = {
  '1': 'ReqChatDeviceContextList',
  '2': [
    {'1': 'device_iid', '3': 1, '4': 1, '5': 3, '10': 'deviceIid'},
    {'1': 'include_archived', '3': 2, '4': 1, '5': 8, '10': 'includeArchived'},
    {'1': 'limit', '3': 3, '4': 1, '5': 5, '10': 'limit'},
  ],
};

/// Descriptor for `ReqChatDeviceContextList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqChatDeviceContextListDescriptor = $convert.base64Decode(
    'ChhSZXFDaGF0RGV2aWNlQ29udGV4dExpc3QSHQoKZGV2aWNlX2lpZBgBIAEoA1IJZGV2aWNlSW'
    'lkEikKEGluY2x1ZGVfYXJjaGl2ZWQYAiABKAhSD2luY2x1ZGVBcmNoaXZlZBIUCgVsaW1pdBgD'
    'IAEoBVIFbGltaXQ=');

@$core.Deprecated('Use resChatDeviceContextListDescriptor instead')
const ResChatDeviceContextList$json = {
  '1': 'ResChatDeviceContextList',
  '2': [
    {'1': 'chats', '3': 1, '4': 3, '5': 11, '6': '.c35.Chat', '10': 'chats'},
    {
      '1': 'members',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.c35.ChatMember',
      '10': 'members'
    },
  ],
};

/// Descriptor for `ResChatDeviceContextList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resChatDeviceContextListDescriptor =
    $convert.base64Decode(
        'ChhSZXNDaGF0RGV2aWNlQ29udGV4dExpc3QSHwoFY2hhdHMYASADKAsyCS5jMzUuQ2hhdFIFY2'
        'hhdHMSKQoHbWVtYmVycxgCIAMoCzIPLmMzNS5DaGF0TWVtYmVyUgdtZW1iZXJz');

@$core.Deprecated('Use reqChatDeviceContextCreateDescriptor instead')
const ReqChatDeviceContextCreate$json = {
  '1': 'ReqChatDeviceContextCreate',
  '2': [
    {'1': 'device_iid', '3': 1, '4': 1, '5': 3, '10': 'deviceIid'},
    {'1': 'title', '3': 2, '4': 1, '5': 9, '10': 'title'},
  ],
};

/// Descriptor for `ReqChatDeviceContextCreate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqChatDeviceContextCreateDescriptor =
    $convert.base64Decode(
        'ChpSZXFDaGF0RGV2aWNlQ29udGV4dENyZWF0ZRIdCgpkZXZpY2VfaWlkGAEgASgDUglkZXZpY2'
        'VJaWQSFAoFdGl0bGUYAiABKAlSBXRpdGxl');

@$core.Deprecated('Use resChatDeviceContextCreateDescriptor instead')
const ResChatDeviceContextCreate$json = {
  '1': 'ResChatDeviceContextCreate',
  '2': [
    {'1': 'chat', '3': 1, '4': 1, '5': 11, '6': '.c35.Chat', '10': 'chat'},
    {
      '1': 'member',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.c35.ChatMember',
      '10': 'member'
    },
  ],
};

/// Descriptor for `ResChatDeviceContextCreate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resChatDeviceContextCreateDescriptor =
    $convert.base64Decode(
        'ChpSZXNDaGF0RGV2aWNlQ29udGV4dENyZWF0ZRIdCgRjaGF0GAEgASgLMgkuYzM1LkNoYXRSBG'
        'NoYXQSJwoGbWVtYmVyGAIgASgLMg8uYzM1LkNoYXRNZW1iZXJSBm1lbWJlcg==');

@$core.Deprecated('Use assetTagHintDescriptor instead')
const AssetTagHint$json = {
  '1': 'AssetTagHint',
  '2': [
    {'1': 'tag', '3': 1, '4': 1, '5': 9, '10': 'tag'},
    {'1': 'count', '3': 2, '4': 1, '5': 5, '10': 'count'},
  ],
};

/// Descriptor for `AssetTagHint`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List assetTagHintDescriptor = $convert.base64Decode(
    'CgxBc3NldFRhZ0hpbnQSEAoDdGFnGAEgASgJUgN0YWcSFAoFY291bnQYAiABKAVSBWNvdW50');

@$core.Deprecated('Use reqAssetTagListDescriptor instead')
const ReqAssetTagList$json = {
  '1': 'ReqAssetTagList',
  '2': [
    {'1': 'kind', '3': 1, '4': 1, '5': 9, '10': 'kind'},
    {'1': 'prefix', '3': 2, '4': 1, '5': 9, '10': 'prefix'},
    {'1': 'limit', '3': 3, '4': 1, '5': 5, '10': 'limit'},
  ],
};

/// Descriptor for `ReqAssetTagList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqAssetTagListDescriptor = $convert.base64Decode(
    'Cg9SZXFBc3NldFRhZ0xpc3QSEgoEa2luZBgBIAEoCVIEa2luZBIWCgZwcmVmaXgYAiABKAlSBn'
    'ByZWZpeBIUCgVsaW1pdBgDIAEoBVIFbGltaXQ=');

@$core.Deprecated('Use resAssetTagListDescriptor instead')
const ResAssetTagList$json = {
  '1': 'ResAssetTagList',
  '2': [
    {
      '1': 'hints',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.c35.AssetTagHint',
      '10': 'hints'
    },
  ],
};

/// Descriptor for `ResAssetTagList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resAssetTagListDescriptor = $convert.base64Decode(
    'Cg9SZXNBc3NldFRhZ0xpc3QSJwoFaGludHMYASADKAsyES5jMzUuQXNzZXRUYWdIaW50UgVoaW'
    '50cw==');

@$core.Deprecated('Use reqLogListDescriptor instead')
const ReqLogList$json = {
  '1': 'ReqLogList',
  '2': [
    {'1': 'req_id', '3': 1, '4': 1, '5': 9, '10': 'reqId'},
    {'1': 'limit', '3': 2, '4': 1, '5': 5, '10': 'limit'},
  ],
};

/// Descriptor for `ReqLogList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqLogListDescriptor = $convert.base64Decode(
    'CgpSZXFMb2dMaXN0EhUKBnJlcV9pZBgBIAEoCVIFcmVxSWQSFAoFbGltaXQYAiABKAVSBWxpbW'
    'l0');

@$core.Deprecated('Use resLogListDescriptor instead')
const ResLogList$json = {
  '1': 'ResLogList',
  '2': [
    {'1': 'logs', '3': 1, '4': 3, '5': 11, '6': '.c35.Log', '10': 'logs'},
  ],
};

/// Descriptor for `ResLogList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resLogListDescriptor = $convert
    .base64Decode('CgpSZXNMb2dMaXN0EhwKBGxvZ3MYASADKAsyCC5jMzUuTG9nUgRsb2dz');

@$core.Deprecated('Use reqBotPeerListDescriptor instead')
const ReqBotPeerList$json = {
  '1': 'ReqBotPeerList',
  '2': [
    {'1': 'bot_iid', '3': 1, '4': 1, '5': 3, '10': 'botIid'},
    {'1': 'include_archived', '3': 2, '4': 1, '5': 8, '10': 'includeArchived'},
    {'1': 'limit', '3': 3, '4': 1, '5': 5, '10': 'limit'},
  ],
};

/// Descriptor for `ReqBotPeerList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqBotPeerListDescriptor = $convert.base64Decode(
    'Cg5SZXFCb3RQZWVyTGlzdBIXCgdib3RfaWlkGAEgASgDUgZib3RJaWQSKQoQaW5jbHVkZV9hcm'
    'NoaXZlZBgCIAEoCFIPaW5jbHVkZUFyY2hpdmVkEhQKBWxpbWl0GAMgASgFUgVsaW1pdA==');

@$core.Deprecated('Use resBotPeerListDescriptor instead')
const ResBotPeerList$json = {
  '1': 'ResBotPeerList',
  '2': [
    {'1': 'chats', '3': 1, '4': 3, '5': 11, '6': '.c35.Chat', '10': 'chats'},
  ],
};

/// Descriptor for `ResBotPeerList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resBotPeerListDescriptor = $convert.base64Decode(
    'Cg5SZXNCb3RQZWVyTGlzdBIfCgVjaGF0cxgBIAMoCzIJLmMzNS5DaGF0UgVjaGF0cw==');

@$core.Deprecated('Use reqBotPeerCreateDescriptor instead')
const ReqBotPeerCreate$json = {
  '1': 'ReqBotPeerCreate',
  '2': [
    {'1': 'bot_iid', '3': 1, '4': 1, '5': 3, '10': 'botIid'},
    {'1': 'title', '3': 2, '4': 1, '5': 9, '10': 'title'},
  ],
};

/// Descriptor for `ReqBotPeerCreate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqBotPeerCreateDescriptor = $convert.base64Decode(
    'ChBSZXFCb3RQZWVyQ3JlYXRlEhcKB2JvdF9paWQYASABKANSBmJvdElpZBIUCgV0aXRsZRgCIA'
    'EoCVIFdGl0bGU=');

@$core.Deprecated('Use resBotPeerCreateDescriptor instead')
const ResBotPeerCreate$json = {
  '1': 'ResBotPeerCreate',
  '2': [
    {'1': 'chat', '3': 1, '4': 1, '5': 11, '6': '.c35.Chat', '10': 'chat'},
  ],
};

/// Descriptor for `ResBotPeerCreate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resBotPeerCreateDescriptor = $convert.base64Decode(
    'ChBSZXNCb3RQZWVyQ3JlYXRlEh0KBGNoYXQYASABKAsyCS5jMzUuQ2hhdFIEY2hhdA==');

@$core.Deprecated('Use reqBotPeerAppSendDescriptor instead')
const ReqBotPeerAppSend$json = {
  '1': 'ReqBotPeerAppSend',
  '2': [
    {'1': 'chat_id', '3': 1, '4': 1, '5': 3, '10': 'chatId'},
    {'1': 'text', '3': 2, '4': 1, '5': 9, '10': 'text'},
    {'1': 'attachments_json', '3': 3, '4': 1, '5': 9, '10': 'attachmentsJson'},
  ],
};

/// Descriptor for `ReqBotPeerAppSend`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqBotPeerAppSendDescriptor = $convert.base64Decode(
    'ChFSZXFCb3RQZWVyQXBwU2VuZBIXCgdjaGF0X2lkGAEgASgDUgZjaGF0SWQSEgoEdGV4dBgCIA'
    'EoCVIEdGV4dBIpChBhdHRhY2htZW50c19qc29uGAMgASgJUg9hdHRhY2htZW50c0pzb24=');

@$core.Deprecated('Use resBotPeerAppSendDescriptor instead')
const ResBotPeerAppSend$json = {
  '1': 'ResBotPeerAppSend',
  '2': [
    {'1': 'chat_id', '3': 1, '4': 1, '5': 3, '10': 'chatId'},
  ],
};

/// Descriptor for `ResBotPeerAppSend`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resBotPeerAppSendDescriptor = $convert.base64Decode(
    'ChFSZXNCb3RQZWVyQXBwU2VuZBIXCgdjaGF0X2lkGAEgASgDUgZjaGF0SWQ=');

@$core.Deprecated('Use reqBotPeerDeleteDescriptor instead')
const ReqBotPeerDelete$json = {
  '1': 'ReqBotPeerDelete',
  '2': [
    {'1': 'chat_id', '3': 1, '4': 1, '5': 3, '10': 'chatId'},
  ],
};

/// Descriptor for `ReqBotPeerDelete`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqBotPeerDeleteDescriptor = $convert.base64Decode(
    'ChBSZXFCb3RQZWVyRGVsZXRlEhcKB2NoYXRfaWQYASABKANSBmNoYXRJZA==');

@$core.Deprecated('Use resBotPeerDeleteDescriptor instead')
const ResBotPeerDelete$json = {
  '1': 'ResBotPeerDelete',
};

/// Descriptor for `ResBotPeerDelete`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resBotPeerDeleteDescriptor =
    $convert.base64Decode('ChBSZXNCb3RQZWVyRGVsZXRl');

@$core.Deprecated('Use chatTypingDescriptor instead')
const ChatTyping$json = {
  '1': 'ChatTyping',
  '2': [
    {'1': 'chat_id', '3': 1, '4': 1, '5': 3, '10': 'chatId'},
    {'1': 'party', '3': 2, '4': 1, '5': 9, '10': 'party'},
    {'1': 'active', '3': 3, '4': 1, '5': 8, '10': 'active'},
  ],
};

/// Descriptor for `ChatTyping`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List chatTypingDescriptor = $convert.base64Decode(
    'CgpDaGF0VHlwaW5nEhcKB2NoYXRfaWQYASABKANSBmNoYXRJZBIUCgVwYXJ0eRgCIAEoCVIFcG'
    'FydHkSFgoGYWN0aXZlGAMgASgIUgZhY3RpdmU=');

@$core.Deprecated('Use chatFeedbackReasonDescriptor instead')
const ChatFeedbackReason$json = {
  '1': 'ChatFeedbackReason',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 5, '10': 'id'},
    {'1': 'slug', '3': 2, '4': 1, '5': 9, '10': 'slug'},
    {
      '1': 'vote',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.c35.ChatFeedbackVote',
      '10': 'vote'
    },
    {'1': 'label', '3': 4, '4': 1, '5': 9, '10': 'label'},
    {'1': 'sort', '3': 5, '4': 1, '5': 5, '10': 'sort'},
  ],
};

/// Descriptor for `ChatFeedbackReason`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List chatFeedbackReasonDescriptor = $convert.base64Decode(
    'ChJDaGF0RmVlZGJhY2tSZWFzb24SDgoCaWQYASABKAVSAmlkEhIKBHNsdWcYAiABKAlSBHNsdW'
    'cSKQoEdm90ZRgDIAEoDjIVLmMzNS5DaGF0RmVlZGJhY2tWb3RlUgR2b3RlEhQKBWxhYmVsGAQg'
    'ASgJUgVsYWJlbBISCgRzb3J0GAUgASgFUgRzb3J0');

@$core.Deprecated('Use chatFeedbackPostDescriptor instead')
const ChatFeedbackPost$json = {
  '1': 'ChatFeedbackPost',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 3, '10': 'id'},
    {'1': 'feedback_id', '3': 2, '4': 1, '5': 3, '10': 'feedbackId'},
    {'1': 'author_iid', '3': 3, '4': 1, '5': 3, '10': 'authorIid'},
    {
      '1': 'author_role',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.c35.ChatFeedbackAuthorRole',
      '10': 'authorRole'
    },
    {'1': 'text', '3': 5, '4': 1, '5': 9, '10': 'text'},
    {'1': 'created_ts_ms', '3': 6, '4': 1, '5': 3, '10': 'createdTsMs'},
  ],
};

/// Descriptor for `ChatFeedbackPost`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List chatFeedbackPostDescriptor = $convert.base64Decode(
    'ChBDaGF0RmVlZGJhY2tQb3N0Eg4KAmlkGAEgASgDUgJpZBIfCgtmZWVkYmFja19pZBgCIAEoA1'
    'IKZmVlZGJhY2tJZBIdCgphdXRob3JfaWlkGAMgASgDUglhdXRob3JJaWQSPAoLYXV0aG9yX3Jv'
    'bGUYBCABKA4yGy5jMzUuQ2hhdEZlZWRiYWNrQXV0aG9yUm9sZVIKYXV0aG9yUm9sZRISCgR0ZX'
    'h0GAUgASgJUgR0ZXh0EiIKDWNyZWF0ZWRfdHNfbXMYBiABKANSC2NyZWF0ZWRUc01z');

@$core.Deprecated('Use chatMsgFeedbackDescriptor instead')
const ChatMsgFeedback$json = {
  '1': 'ChatMsgFeedback',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 3, '10': 'id'},
    {'1': 'msg_id', '3': 2, '4': 1, '5': 3, '10': 'msgId'},
    {'1': 'chat_id', '3': 3, '4': 1, '5': 3, '10': 'chatId'},
    {
      '1': 'vote',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.c35.ChatFeedbackVote',
      '10': 'vote'
    },
    {'1': 'reason_id', '3': 5, '4': 1, '5': 5, '10': 'reasonId'},
    {'1': 'reason_slug', '3': 6, '4': 1, '5': 9, '10': 'reasonSlug'},
    {'1': 'reason_label', '3': 7, '4': 1, '5': 9, '10': 'reasonLabel'},
    {'1': 'comment', '3': 8, '4': 1, '5': 9, '10': 'comment'},
    {'1': 'updated_ts_ms', '3': 9, '4': 1, '5': 3, '10': 'updatedTsMs'},
    {
      '1': 'posts',
      '3': 10,
      '4': 3,
      '5': 11,
      '6': '.c35.ChatFeedbackPost',
      '10': 'posts'
    },
  ],
};

/// Descriptor for `ChatMsgFeedback`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List chatMsgFeedbackDescriptor = $convert.base64Decode(
    'Cg9DaGF0TXNnRmVlZGJhY2sSDgoCaWQYASABKANSAmlkEhUKBm1zZ19pZBgCIAEoA1IFbXNnSW'
    'QSFwoHY2hhdF9pZBgDIAEoA1IGY2hhdElkEikKBHZvdGUYBCABKA4yFS5jMzUuQ2hhdEZlZWRi'
    'YWNrVm90ZVIEdm90ZRIbCglyZWFzb25faWQYBSABKAVSCHJlYXNvbklkEh8KC3JlYXNvbl9zbH'
    'VnGAYgASgJUgpyZWFzb25TbHVnEiEKDHJlYXNvbl9sYWJlbBgHIAEoCVILcmVhc29uTGFiZWwS'
    'GAoHY29tbWVudBgIIAEoCVIHY29tbWVudBIiCg11cGRhdGVkX3RzX21zGAkgASgDUgt1cGRhdG'
    'VkVHNNcxIrCgVwb3N0cxgKIAMoCzIVLmMzNS5DaGF0RmVlZGJhY2tQb3N0UgVwb3N0cw==');

@$core.Deprecated('Use reqChatFeedbackReasonListDescriptor instead')
const ReqChatFeedbackReasonList$json = {
  '1': 'ReqChatFeedbackReasonList',
  '2': [
    {'1': 'locale', '3': 1, '4': 1, '5': 9, '10': 'locale'},
    {
      '1': 'vote',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.c35.ChatFeedbackVote',
      '10': 'vote'
    },
  ],
};

/// Descriptor for `ReqChatFeedbackReasonList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqChatFeedbackReasonListDescriptor =
    $convert.base64Decode(
        'ChlSZXFDaGF0RmVlZGJhY2tSZWFzb25MaXN0EhYKBmxvY2FsZRgBIAEoCVIGbG9jYWxlEikKBH'
        'ZvdGUYAiABKA4yFS5jMzUuQ2hhdEZlZWRiYWNrVm90ZVIEdm90ZQ==');

@$core.Deprecated('Use resChatFeedbackReasonListDescriptor instead')
const ResChatFeedbackReasonList$json = {
  '1': 'ResChatFeedbackReasonList',
  '2': [
    {
      '1': 'reasons',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.c35.ChatFeedbackReason',
      '10': 'reasons'
    },
  ],
};

/// Descriptor for `ResChatFeedbackReasonList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resChatFeedbackReasonListDescriptor =
    $convert.base64Decode(
        'ChlSZXNDaGF0RmVlZGJhY2tSZWFzb25MaXN0EjEKB3JlYXNvbnMYASADKAsyFy5jMzUuQ2hhdE'
        'ZlZWRiYWNrUmVhc29uUgdyZWFzb25z');

@$core.Deprecated('Use reqChatMsgFeedbackPutDescriptor instead')
const ReqChatMsgFeedbackPut$json = {
  '1': 'ReqChatMsgFeedbackPut',
  '2': [
    {'1': 'msg_id', '3': 1, '4': 1, '5': 3, '10': 'msgId'},
    {'1': 'chat_id', '3': 2, '4': 1, '5': 3, '10': 'chatId'},
    {
      '1': 'vote',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.c35.ChatFeedbackVote',
      '10': 'vote'
    },
    {'1': 'reason_id', '3': 4, '4': 1, '5': 5, '10': 'reasonId'},
    {'1': 'comment', '3': 5, '4': 1, '5': 9, '10': 'comment'},
    {'1': 'locale', '3': 6, '4': 1, '5': 9, '10': 'locale'},
  ],
};

/// Descriptor for `ReqChatMsgFeedbackPut`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqChatMsgFeedbackPutDescriptor = $convert.base64Decode(
    'ChVSZXFDaGF0TXNnRmVlZGJhY2tQdXQSFQoGbXNnX2lkGAEgASgDUgVtc2dJZBIXCgdjaGF0X2'
    'lkGAIgASgDUgZjaGF0SWQSKQoEdm90ZRgDIAEoDjIVLmMzNS5DaGF0RmVlZGJhY2tWb3RlUgR2'
    'b3RlEhsKCXJlYXNvbl9pZBgEIAEoBVIIcmVhc29uSWQSGAoHY29tbWVudBgFIAEoCVIHY29tbW'
    'VudBIWCgZsb2NhbGUYBiABKAlSBmxvY2FsZQ==');

@$core.Deprecated('Use resChatMsgFeedbackPutDescriptor instead')
const ResChatMsgFeedbackPut$json = {
  '1': 'ResChatMsgFeedbackPut',
  '2': [
    {
      '1': 'feedback',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.c35.ChatMsgFeedback',
      '10': 'feedback'
    },
  ],
};

/// Descriptor for `ResChatMsgFeedbackPut`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resChatMsgFeedbackPutDescriptor = $convert.base64Decode(
    'ChVSZXNDaGF0TXNnRmVlZGJhY2tQdXQSMAoIZmVlZGJhY2sYASABKAsyFC5jMzUuQ2hhdE1zZ0'
    'ZlZWRiYWNrUghmZWVkYmFjaw==');

@$core.Deprecated('Use reqChatMsgFeedbackListDescriptor instead')
const ReqChatMsgFeedbackList$json = {
  '1': 'ReqChatMsgFeedbackList',
  '2': [
    {'1': 'chat_id', '3': 1, '4': 1, '5': 3, '10': 'chatId'},
    {'1': 'locale', '3': 2, '4': 1, '5': 9, '10': 'locale'},
  ],
};

/// Descriptor for `ReqChatMsgFeedbackList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqChatMsgFeedbackListDescriptor =
    $convert.base64Decode(
        'ChZSZXFDaGF0TXNnRmVlZGJhY2tMaXN0EhcKB2NoYXRfaWQYASABKANSBmNoYXRJZBIWCgZsb2'
        'NhbGUYAiABKAlSBmxvY2FsZQ==');

@$core.Deprecated('Use resChatMsgFeedbackListDescriptor instead')
const ResChatMsgFeedbackList$json = {
  '1': 'ResChatMsgFeedbackList',
  '2': [
    {
      '1': 'feedback',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.c35.ChatMsgFeedback',
      '10': 'feedback'
    },
  ],
};

/// Descriptor for `ResChatMsgFeedbackList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resChatMsgFeedbackListDescriptor =
    $convert.base64Decode(
        'ChZSZXNDaGF0TXNnRmVlZGJhY2tMaXN0EjAKCGZlZWRiYWNrGAEgAygLMhQuYzM1LkNoYXRNc2'
        'dGZWVkYmFja1IIZmVlZGJhY2s=');

@$core.Deprecated('Use reqChatContextWindowSetDescriptor instead')
const ReqChatContextWindowSet$json = {
  '1': 'ReqChatContextWindowSet',
  '2': [
    {'1': 'chat_id', '3': 1, '4': 1, '5': 3, '10': 'chatId'},
    {'1': 'context_window', '3': 2, '4': 1, '5': 5, '10': 'contextWindow'},
  ],
};

/// Descriptor for `ReqChatContextWindowSet`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqChatContextWindowSetDescriptor =
    $convert.base64Decode(
        'ChdSZXFDaGF0Q29udGV4dFdpbmRvd1NldBIXCgdjaGF0X2lkGAEgASgDUgZjaGF0SWQSJQoOY2'
        '9udGV4dF93aW5kb3cYAiABKAVSDWNvbnRleHRXaW5kb3c=');

@$core.Deprecated('Use resChatContextWindowSetDescriptor instead')
const ResChatContextWindowSet$json = {
  '1': 'ResChatContextWindowSet',
  '2': [
    {'1': 'context_window', '3': 1, '4': 1, '5': 5, '10': 'contextWindow'},
    {'1': 'prompt_tokens', '3': 2, '4': 1, '5': 5, '10': 'promptTokens'},
    {
      '1': 'usage',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.c35.ContextUsage',
      '10': 'usage'
    },
  ],
};

/// Descriptor for `ResChatContextWindowSet`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resChatContextWindowSetDescriptor = $convert.base64Decode(
    'ChdSZXNDaGF0Q29udGV4dFdpbmRvd1NldBIlCg5jb250ZXh0X3dpbmRvdxgBIAEoBVINY29udG'
    'V4dFdpbmRvdxIjCg1wcm9tcHRfdG9rZW5zGAIgASgFUgxwcm9tcHRUb2tlbnMSJwoFdXNhZ2UY'
    'AyABKAsyES5jMzUuQ29udGV4dFVzYWdlUgV1c2FnZQ==');

@$core.Deprecated('Use reqChatCompactDescriptor instead')
const ReqChatCompact$json = {
  '1': 'ReqChatCompact',
  '2': [
    {'1': 'chat_id', '3': 1, '4': 1, '5': 3, '10': 'chatId'},
  ],
};

/// Descriptor for `ReqChatCompact`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqChatCompactDescriptor = $convert
    .base64Decode('Cg5SZXFDaGF0Q29tcGFjdBIXCgdjaGF0X2lkGAEgASgDUgZjaGF0SWQ=');

@$core.Deprecated('Use resChatCompactDescriptor instead')
const ResChatCompact$json = {
  '1': 'ResChatCompact',
  '2': [
    {'1': 'ran', '3': 1, '4': 1, '5': 8, '10': 'ran'},
    {'1': 'title', '3': 2, '4': 1, '5': 9, '10': 'title'},
    {'1': 'prompt_tokens', '3': 3, '4': 1, '5': 5, '10': 'promptTokens'},
    {'1': 'cost_usd', '3': 4, '4': 1, '5': 1, '10': 'costUsd'},
    {
      '1': 'usage',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.c35.ContextUsage',
      '10': 'usage'
    },
  ],
};

/// Descriptor for `ResChatCompact`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resChatCompactDescriptor = $convert.base64Decode(
    'Cg5SZXNDaGF0Q29tcGFjdBIQCgNyYW4YASABKAhSA3JhbhIUCgV0aXRsZRgCIAEoCVIFdGl0bG'
    'USIwoNcHJvbXB0X3Rva2VucxgDIAEoBVIMcHJvbXB0VG9rZW5zEhkKCGNvc3RfdXNkGAQgASgB'
    'Ugdjb3N0VXNkEicKBXVzYWdlGAUgASgLMhEuYzM1LkNvbnRleHRVc2FnZVIFdXNhZ2U=');

@$core.Deprecated('Use reqMediaRegenerateDescriptor instead')
const ReqMediaRegenerate$json = {
  '1': 'ReqMediaRegenerate',
  '2': [
    {'1': 'msg_id', '3': 1, '4': 1, '5': 3, '10': 'msgId'},
    {'1': 'block_index', '3': 2, '4': 1, '5': 5, '10': 'blockIndex'},
    {'1': 'provider', '3': 3, '4': 1, '5': 9, '10': 'provider'},
    {'1': 'set_default', '3': 4, '4': 1, '5': 8, '10': 'setDefault'},
    {'1': 'chat_id', '3': 5, '4': 1, '5': 3, '10': 'chatId'},
    {'1': 'media_model', '3': 6, '4': 1, '5': 9, '10': 'mediaModel'},
    {'1': 'aspect_ratio', '3': 7, '4': 1, '5': 9, '10': 'aspectRatio'},
    {'1': 'duration_sec', '3': 8, '4': 1, '5': 5, '10': 'durationSec'},
    {'1': 'instrumental', '3': 9, '4': 1, '5': 8, '10': 'instrumental'},
  ],
};

/// Descriptor for `ReqMediaRegenerate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqMediaRegenerateDescriptor = $convert.base64Decode(
    'ChJSZXFNZWRpYVJlZ2VuZXJhdGUSFQoGbXNnX2lkGAEgASgDUgVtc2dJZBIfCgtibG9ja19pbm'
    'RleBgCIAEoBVIKYmxvY2tJbmRleBIaCghwcm92aWRlchgDIAEoCVIIcHJvdmlkZXISHwoLc2V0'
    'X2RlZmF1bHQYBCABKAhSCnNldERlZmF1bHQSFwoHY2hhdF9pZBgFIAEoA1IGY2hhdElkEh8KC2'
    '1lZGlhX21vZGVsGAYgASgJUgptZWRpYU1vZGVsEiEKDGFzcGVjdF9yYXRpbxgHIAEoCVILYXNw'
    'ZWN0UmF0aW8SIQoMZHVyYXRpb25fc2VjGAggASgFUgtkdXJhdGlvblNlYxIiCgxpbnN0cnVtZW'
    '50YWwYCSABKAhSDGluc3RydW1lbnRhbA==');

@$core.Deprecated('Use resMediaRegenerateDescriptor instead')
const ResMediaRegenerate$json = {
  '1': 'ResMediaRegenerate',
  '2': [
    {'1': 'blocks_json', '3': 1, '4': 1, '5': 9, '10': 'blocksJson'},
    {'1': 'retail_usd', '3': 2, '4': 1, '5': 1, '10': 'retailUsd'},
    {'1': 'media_provider', '3': 3, '4': 1, '5': 9, '10': 'mediaProvider'},
    {'1': 'generation_image', '3': 4, '4': 1, '5': 9, '10': 'generationImage'},
    {'1': 'generation_video', '3': 5, '4': 1, '5': 9, '10': 'generationVideo'},
    {'1': 'generation_music', '3': 6, '4': 1, '5': 9, '10': 'generationMusic'},
    {'1': 'req_id', '3': 7, '4': 1, '5': 9, '10': 'reqId'},
    {'1': 'msg_id', '3': 8, '4': 1, '5': 3, '10': 'msgId'},
  ],
};

/// Descriptor for `ResMediaRegenerate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resMediaRegenerateDescriptor = $convert.base64Decode(
    'ChJSZXNNZWRpYVJlZ2VuZXJhdGUSHwoLYmxvY2tzX2pzb24YASABKAlSCmJsb2Nrc0pzb24SHQ'
    'oKcmV0YWlsX3VzZBgCIAEoAVIJcmV0YWlsVXNkEiUKDm1lZGlhX3Byb3ZpZGVyGAMgASgJUg1t'
    'ZWRpYVByb3ZpZGVyEikKEGdlbmVyYXRpb25faW1hZ2UYBCABKAlSD2dlbmVyYXRpb25JbWFnZR'
    'IpChBnZW5lcmF0aW9uX3ZpZGVvGAUgASgJUg9nZW5lcmF0aW9uVmlkZW8SKQoQZ2VuZXJhdGlv'
    'bl9tdXNpYxgGIAEoCVIPZ2VuZXJhdGlvbk11c2ljEhUKBnJlcV9pZBgHIAEoCVIFcmVxSWQSFQ'
    'oGbXNnX2lkGAggASgDUgVtc2dJZA==');
