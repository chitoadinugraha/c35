// This is a generated file - do not edit.
//
// Generated from c35/mail.proto.

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

@$core.Deprecated('Use mailDirectionDescriptor instead')
const MailDirection$json = {
  '1': 'MailDirection',
  '2': [
    {'1': 'MAIL_DIRECTION_UNSPECIFIED', '2': 0},
    {'1': 'MAIL_DIRECTION_IN', '2': 1},
    {'1': 'MAIL_DIRECTION_OUT', '2': 2},
  ],
};

/// Descriptor for `MailDirection`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List mailDirectionDescriptor = $convert.base64Decode(
    'Cg1NYWlsRGlyZWN0aW9uEh4KGk1BSUxfRElSRUNUSU9OX1VOU1BFQ0lGSUVEEAASFQoRTUFJTF'
    '9ESVJFQ1RJT05fSU4QARIWChJNQUlMX0RJUkVDVElPTl9PVVQQAg==');

@$core.Deprecated('Use mailStatusDescriptor instead')
const MailStatus$json = {
  '1': 'MailStatus',
  '2': [
    {'1': 'MAIL_STATUS_UNSPECIFIED', '2': 0},
    {'1': 'MAIL_STATUS_RECEIVED', '2': 1},
    {'1': 'MAIL_STATUS_QUEUED', '2': 2},
    {'1': 'MAIL_STATUS_SENT', '2': 3},
    {'1': 'MAIL_STATUS_FAILED', '2': 4},
  ],
};

/// Descriptor for `MailStatus`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List mailStatusDescriptor = $convert.base64Decode(
    'CgpNYWlsU3RhdHVzEhsKF01BSUxfU1RBVFVTX1VOU1BFQ0lGSUVEEAASGAoUTUFJTF9TVEFUVV'
    'NfUkVDRUlWRUQQARIWChJNQUlMX1NUQVRVU19RVUVVRUQQAhIUChBNQUlMX1NUQVRVU19TRU5U'
    'EAMSFgoSTUFJTF9TVEFUVVNfRkFJTEVEEAQ=');

@$core.Deprecated('Use mailMailboxKindDescriptor instead')
const MailMailboxKind$json = {
  '1': 'MailMailboxKind',
  '2': [
    {'1': 'MAIL_MAILBOX_KIND_UNSPECIFIED', '2': 0},
    {'1': 'MAIL_MAILBOX_KIND_PERSONAL', '2': 1},
    {'1': 'MAIL_MAILBOX_KIND_SITE', '2': 2},
  ],
};

/// Descriptor for `MailMailboxKind`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List mailMailboxKindDescriptor = $convert.base64Decode(
    'Cg9NYWlsTWFpbGJveEtpbmQSIQodTUFJTF9NQUlMQk9YX0tJTkRfVU5TUEVDSUZJRUQQABIeCh'
    'pNQUlMX01BSUxCT1hfS0lORF9QRVJTT05BTBABEhoKFk1BSUxfTUFJTEJPWF9LSU5EX1NJVEUQ'
    'Ag==');

@$core.Deprecated('Use mailMailboxAccessDescriptor instead')
const MailMailboxAccess$json = {
  '1': 'MailMailboxAccess',
  '2': [
    {'1': 'MAIL_MAILBOX_ACCESS_UNSPECIFIED', '2': 0},
    {'1': 'MAIL_MAILBOX_ACCESS_READ', '2': 1},
    {'1': 'MAIL_MAILBOX_ACCESS_WRITE', '2': 2},
  ],
};

/// Descriptor for `MailMailboxAccess`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List mailMailboxAccessDescriptor = $convert.base64Decode(
    'ChFNYWlsTWFpbGJveEFjY2VzcxIjCh9NQUlMX01BSUxCT1hfQUNDRVNTX1VOU1BFQ0lGSUVEEA'
    'ASHAoYTUFJTF9NQUlMQk9YX0FDQ0VTU19SRUFEEAESHQoZTUFJTF9NQUlMQk9YX0FDQ0VTU19X'
    'UklURRAC');

@$core.Deprecated('Use mailAccountDescriptor instead')
const MailAccount$json = {
  '1': 'MailAccount',
  '2': [
    {'1': 'owner_iid', '3': 1, '4': 1, '5': 3, '10': 'ownerIid'},
    {'1': 'address', '3': 2, '4': 1, '5': 9, '10': 'address'},
    {'1': 'created_ts_ms', '3': 3, '4': 1, '5': 3, '10': 'createdTsMs'},
    {'1': 'mailbox_id', '3': 4, '4': 1, '5': 3, '10': 'mailboxId'},
  ],
};

/// Descriptor for `MailAccount`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mailAccountDescriptor = $convert.base64Decode(
    'CgtNYWlsQWNjb3VudBIbCglvd25lcl9paWQYASABKANSCG93bmVySWlkEhgKB2FkZHJlc3MYAi'
    'ABKAlSB2FkZHJlc3MSIgoNY3JlYXRlZF90c19tcxgDIAEoA1ILY3JlYXRlZFRzTXMSHQoKbWFp'
    'bGJveF9pZBgEIAEoA1IJbWFpbGJveElk');

@$core.Deprecated('Use mailMailboxMemberDescriptor instead')
const MailMailboxMember$json = {
  '1': 'MailMailboxMember',
  '2': [
    {'1': 'member_iid', '3': 1, '4': 1, '5': 3, '10': 'memberIid'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'email', '3': 3, '4': 1, '5': 9, '10': 'email'},
    {
      '1': 'access',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.c35.MailMailboxAccess',
      '10': 'access'
    },
  ],
};

/// Descriptor for `MailMailboxMember`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mailMailboxMemberDescriptor = $convert.base64Decode(
    'ChFNYWlsTWFpbGJveE1lbWJlchIdCgptZW1iZXJfaWlkGAEgASgDUgltZW1iZXJJaWQSEgoEbm'
    'FtZRgCIAEoCVIEbmFtZRIUCgVlbWFpbBgDIAEoCVIFZW1haWwSLgoGYWNjZXNzGAQgASgOMhYu'
    'YzM1Lk1haWxNYWlsYm94QWNjZXNzUgZhY2Nlc3M=');

@$core.Deprecated('Use mailMailboxDescriptor instead')
const MailMailbox$json = {
  '1': 'MailMailbox',
  '2': [
    {'1': 'mailbox_id', '3': 1, '4': 1, '5': 3, '10': 'mailboxId'},
    {'1': 'address', '3': 2, '4': 1, '5': 9, '10': 'address'},
    {
      '1': 'kind',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.c35.MailMailboxKind',
      '10': 'kind'
    },
    {'1': 'site_iid', '3': 4, '4': 1, '5': 3, '10': 'siteIid'},
    {'1': 'site_name', '3': 5, '4': 1, '5': 9, '10': 'siteName'},
    {'1': 'label', '3': 6, '4': 1, '5': 9, '10': 'label'},
    {'1': 'subscriber_limit', '3': 7, '4': 1, '5': 5, '10': 'subscriberLimit'},
    {
      '1': 'my_access',
      '3': 8,
      '4': 1,
      '5': 14,
      '6': '.c35.MailMailboxAccess',
      '10': 'myAccess'
    },
    {'1': 'unread_count', '3': 9, '4': 1, '5': 5, '10': 'unreadCount'},
    {
      '1': 'members',
      '3': 10,
      '4': 3,
      '5': 11,
      '6': '.c35.MailMailboxMember',
      '10': 'members'
    },
  ],
};

/// Descriptor for `MailMailbox`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mailMailboxDescriptor = $convert.base64Decode(
    'CgtNYWlsTWFpbGJveBIdCgptYWlsYm94X2lkGAEgASgDUgltYWlsYm94SWQSGAoHYWRkcmVzcx'
    'gCIAEoCVIHYWRkcmVzcxIoCgRraW5kGAMgASgOMhQuYzM1Lk1haWxNYWlsYm94S2luZFIEa2lu'
    'ZBIZCghzaXRlX2lpZBgEIAEoA1IHc2l0ZUlpZBIbCglzaXRlX25hbWUYBSABKAlSCHNpdGVOYW'
    '1lEhQKBWxhYmVsGAYgASgJUgVsYWJlbBIpChBzdWJzY3JpYmVyX2xpbWl0GAcgASgFUg9zdWJz'
    'Y3JpYmVyTGltaXQSMwoJbXlfYWNjZXNzGAggASgOMhYuYzM1Lk1haWxNYWlsYm94QWNjZXNzUg'
    'hteUFjY2VzcxIhCgx1bnJlYWRfY291bnQYCSABKAVSC3VucmVhZENvdW50EjAKB21lbWJlcnMY'
    'CiADKAsyFi5jMzUuTWFpbE1haWxib3hNZW1iZXJSB21lbWJlcnM=');

@$core.Deprecated('Use mailMessageDescriptor instead')
const MailMessage$json = {
  '1': 'MailMessage',
  '2': [
    {'1': 'message_id', '3': 1, '4': 1, '5': 3, '10': 'messageId'},
    {
      '1': 'direction',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.c35.MailDirection',
      '10': 'direction'
    },
    {'1': 'from_addr', '3': 3, '4': 1, '5': 9, '10': 'fromAddr'},
    {'1': 'to_addr', '3': 4, '4': 1, '5': 9, '10': 'toAddr'},
    {'1': 'subject', '3': 5, '4': 1, '5': 9, '10': 'subject'},
    {'1': 'body_text', '3': 6, '4': 1, '5': 9, '10': 'bodyText'},
    {'1': 'body_html', '3': 7, '4': 1, '5': 9, '10': 'bodyHtml'},
    {
      '1': 'status',
      '3': 8,
      '4': 1,
      '5': 14,
      '6': '.c35.MailStatus',
      '10': 'status'
    },
    {'1': 'attachments_json', '3': 9, '4': 1, '5': 9, '10': 'attachmentsJson'},
    {'1': 'error', '3': 10, '4': 1, '5': 9, '10': 'error'},
    {'1': 'created_ts_ms', '3': 11, '4': 1, '5': 3, '10': 'createdTsMs'},
    {'1': 'sent_ts_ms', '3': 12, '4': 1, '5': 3, '10': 'sentTsMs'},
    {'1': 'is_archived', '3': 13, '4': 1, '5': 8, '10': 'isArchived'},
    {'1': 'is_read', '3': 14, '4': 1, '5': 8, '10': 'isRead'},
  ],
};

/// Descriptor for `MailMessage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mailMessageDescriptor = $convert.base64Decode(
    'CgtNYWlsTWVzc2FnZRIdCgptZXNzYWdlX2lkGAEgASgDUgltZXNzYWdlSWQSMAoJZGlyZWN0aW'
    '9uGAIgASgOMhIuYzM1Lk1haWxEaXJlY3Rpb25SCWRpcmVjdGlvbhIbCglmcm9tX2FkZHIYAyAB'
    'KAlSCGZyb21BZGRyEhcKB3RvX2FkZHIYBCABKAlSBnRvQWRkchIYCgdzdWJqZWN0GAUgASgJUg'
    'dzdWJqZWN0EhsKCWJvZHlfdGV4dBgGIAEoCVIIYm9keVRleHQSGwoJYm9keV9odG1sGAcgASgJ'
    'Ughib2R5SHRtbBInCgZzdGF0dXMYCCABKA4yDy5jMzUuTWFpbFN0YXR1c1IGc3RhdHVzEikKEG'
    'F0dGFjaG1lbnRzX2pzb24YCSABKAlSD2F0dGFjaG1lbnRzSnNvbhIUCgVlcnJvchgKIAEoCVIF'
    'ZXJyb3ISIgoNY3JlYXRlZF90c19tcxgLIAEoA1ILY3JlYXRlZFRzTXMSHAoKc2VudF90c19tcx'
    'gMIAEoA1IIc2VudFRzTXMSHwoLaXNfYXJjaGl2ZWQYDSABKAhSCmlzQXJjaGl2ZWQSFwoHaXNf'
    'cmVhZBgOIAEoCFIGaXNSZWFk');

@$core.Deprecated('Use mailAttachmentDescriptor instead')
const MailAttachment$json = {
  '1': 'MailAttachment',
  '2': [
    {'1': 'path', '3': 1, '4': 1, '5': 9, '10': 'path'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'mime', '3': 3, '4': 1, '5': 9, '10': 'mime'},
    {'1': 'size', '3': 4, '4': 1, '5': 3, '10': 'size'},
  ],
};

/// Descriptor for `MailAttachment`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mailAttachmentDescriptor = $convert.base64Decode(
    'Cg5NYWlsQXR0YWNobWVudBISCgRwYXRoGAEgASgJUgRwYXRoEhIKBG5hbWUYAiABKAlSBG5hbW'
    'USEgoEbWltZRgDIAEoCVIEbWltZRISCgRzaXplGAQgASgDUgRzaXpl');

@$core.Deprecated('Use mailDomainSetupStepDescriptor instead')
const MailDomainSetupStep$json = {
  '1': 'MailDomainSetupStep',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'status', '3': 2, '4': 1, '5': 9, '10': 'status'},
    {'1': 'detail', '3': 3, '4': 1, '5': 9, '10': 'detail'},
  ],
};

/// Descriptor for `MailDomainSetupStep`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mailDomainSetupStepDescriptor = $convert.base64Decode(
    'ChNNYWlsRG9tYWluU2V0dXBTdGVwEhAKA2tleRgBIAEoCVIDa2V5EhYKBnN0YXR1cxgCIAEoCV'
    'IGc3RhdHVzEhYKBmRldGFpbBgDIAEoCVIGZGV0YWls');

@$core.Deprecated('Use mailDomainDescriptor instead')
const MailDomain$json = {
  '1': 'MailDomain',
  '2': [
    {'1': 'hostname', '3': 1, '4': 1, '5': 9, '10': 'hostname'},
    {'1': 'zone_id', '3': 2, '4': 1, '5': 9, '10': 'zoneId'},
    {'1': 'sending_enabled', '3': 3, '4': 1, '5': 8, '10': 'sendingEnabled'},
    {'1': 'routing_enabled', '3': 4, '4': 1, '5': 8, '10': 'routingEnabled'},
    {'1': 'created_ts_ms', '3': 5, '4': 1, '5': 3, '10': 'createdTsMs'},
    {
      '1': 'setup_steps',
      '3': 6,
      '4': 3,
      '5': 11,
      '6': '.c35.MailDomainSetupStep',
      '10': 'setupSteps'
    },
    {'1': 'error_summary', '3': 7, '4': 1, '5': 9, '10': 'errorSummary'},
  ],
};

/// Descriptor for `MailDomain`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mailDomainDescriptor = $convert.base64Decode(
    'CgpNYWlsRG9tYWluEhoKCGhvc3RuYW1lGAEgASgJUghob3N0bmFtZRIXCgd6b25lX2lkGAIgAS'
    'gJUgZ6b25lSWQSJwoPc2VuZGluZ19lbmFibGVkGAMgASgIUg5zZW5kaW5nRW5hYmxlZBInCg9y'
    'b3V0aW5nX2VuYWJsZWQYBCABKAhSDnJvdXRpbmdFbmFibGVkEiIKDWNyZWF0ZWRfdHNfbXMYBS'
    'ABKANSC2NyZWF0ZWRUc01zEjkKC3NldHVwX3N0ZXBzGAYgAygLMhguYzM1Lk1haWxEb21haW5T'
    'ZXR1cFN0ZXBSCnNldHVwU3RlcHMSIwoNZXJyb3Jfc3VtbWFyeRgHIAEoCVIMZXJyb3JTdW1tYX'
    'J5');

@$core.Deprecated('Use reqMailListDescriptor instead')
const ReqMailList$json = {
  '1': 'ReqMailList',
  '2': [
    {
      '1': 'direction',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.c35.MailDirection',
      '10': 'direction'
    },
    {'1': 'limit', '3': 2, '4': 1, '5': 5, '10': 'limit'},
    {'1': 'before_message_id', '3': 3, '4': 1, '5': 3, '10': 'beforeMessageId'},
    {'1': 'is_archived', '3': 4, '4': 1, '5': 8, '10': 'isArchived'},
    {'1': 'mailbox_id', '3': 5, '4': 1, '5': 3, '10': 'mailboxId'},
  ],
};

/// Descriptor for `ReqMailList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqMailListDescriptor = $convert.base64Decode(
    'CgtSZXFNYWlsTGlzdBIwCglkaXJlY3Rpb24YASABKA4yEi5jMzUuTWFpbERpcmVjdGlvblIJZG'
    'lyZWN0aW9uEhQKBWxpbWl0GAIgASgFUgVsaW1pdBIqChFiZWZvcmVfbWVzc2FnZV9pZBgDIAEo'
    'A1IPYmVmb3JlTWVzc2FnZUlkEh8KC2lzX2FyY2hpdmVkGAQgASgIUgppc0FyY2hpdmVkEh0KCm'
    '1haWxib3hfaWQYBSABKANSCW1haWxib3hJZA==');

@$core.Deprecated('Use resMailListDescriptor instead')
const ResMailList$json = {
  '1': 'ResMailList',
  '2': [
    {
      '1': 'messages',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.c35.MailMessage',
      '10': 'messages'
    },
  ],
};

/// Descriptor for `ResMailList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resMailListDescriptor = $convert.base64Decode(
    'CgtSZXNNYWlsTGlzdBIsCghtZXNzYWdlcxgBIAMoCzIQLmMzNS5NYWlsTWVzc2FnZVIIbWVzc2'
    'FnZXM=');

@$core.Deprecated('Use reqMailGetDescriptor instead')
const ReqMailGet$json = {
  '1': 'ReqMailGet',
  '2': [
    {'1': 'message_id', '3': 1, '4': 1, '5': 3, '10': 'messageId'},
    {'1': 'mailbox_id', '3': 2, '4': 1, '5': 3, '10': 'mailboxId'},
  ],
};

/// Descriptor for `ReqMailGet`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqMailGetDescriptor = $convert.base64Decode(
    'CgpSZXFNYWlsR2V0Eh0KCm1lc3NhZ2VfaWQYASABKANSCW1lc3NhZ2VJZBIdCgptYWlsYm94X2'
    'lkGAIgASgDUgltYWlsYm94SWQ=');

@$core.Deprecated('Use resMailGetDescriptor instead')
const ResMailGet$json = {
  '1': 'ResMailGet',
  '2': [
    {
      '1': 'message',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.c35.MailMessage',
      '10': 'message'
    },
  ],
};

/// Descriptor for `ResMailGet`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resMailGetDescriptor = $convert.base64Decode(
    'CgpSZXNNYWlsR2V0EioKB21lc3NhZ2UYASABKAsyEC5jMzUuTWFpbE1lc3NhZ2VSB21lc3NhZ2'
    'U=');

@$core.Deprecated('Use reqMailSendDescriptor instead')
const ReqMailSend$json = {
  '1': 'ReqMailSend',
  '2': [
    {'1': 'to_addr', '3': 1, '4': 1, '5': 9, '10': 'toAddr'},
    {'1': 'subject', '3': 2, '4': 1, '5': 9, '10': 'subject'},
    {'1': 'body_text', '3': 3, '4': 1, '5': 9, '10': 'bodyText'},
    {'1': 'body_html', '3': 4, '4': 1, '5': 9, '10': 'bodyHtml'},
    {
      '1': 'attachments',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.c35.MailAttachment',
      '10': 'attachments'
    },
    {'1': 'mailbox_id', '3': 6, '4': 1, '5': 3, '10': 'mailboxId'},
  ],
};

/// Descriptor for `ReqMailSend`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqMailSendDescriptor = $convert.base64Decode(
    'CgtSZXFNYWlsU2VuZBIXCgd0b19hZGRyGAEgASgJUgZ0b0FkZHISGAoHc3ViamVjdBgCIAEoCV'
    'IHc3ViamVjdBIbCglib2R5X3RleHQYAyABKAlSCGJvZHlUZXh0EhsKCWJvZHlfaHRtbBgEIAEo'
    'CVIIYm9keUh0bWwSNQoLYXR0YWNobWVudHMYBSADKAsyEy5jMzUuTWFpbEF0dGFjaG1lbnRSC2'
    'F0dGFjaG1lbnRzEh0KCm1haWxib3hfaWQYBiABKANSCW1haWxib3hJZA==');

@$core.Deprecated('Use resMailSendDescriptor instead')
const ResMailSend$json = {
  '1': 'ResMailSend',
  '2': [
    {
      '1': 'message',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.c35.MailMessage',
      '10': 'message'
    },
  ],
};

/// Descriptor for `ResMailSend`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resMailSendDescriptor = $convert.base64Decode(
    'CgtSZXNNYWlsU2VuZBIqCgdtZXNzYWdlGAEgASgLMhAuYzM1Lk1haWxNZXNzYWdlUgdtZXNzYW'
    'dl');

@$core.Deprecated('Use reqMailMailboxListDescriptor instead')
const ReqMailMailboxList$json = {
  '1': 'ReqMailMailboxList',
};

/// Descriptor for `ReqMailMailboxList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqMailMailboxListDescriptor =
    $convert.base64Decode('ChJSZXFNYWlsTWFpbGJveExpc3Q=');

@$core.Deprecated('Use resMailMailboxListDescriptor instead')
const ResMailMailboxList$json = {
  '1': 'ResMailMailboxList',
  '2': [
    {
      '1': 'mailboxes',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.c35.MailMailbox',
      '10': 'mailboxes'
    },
  ],
};

/// Descriptor for `ResMailMailboxList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resMailMailboxListDescriptor = $convert.base64Decode(
    'ChJSZXNNYWlsTWFpbGJveExpc3QSLgoJbWFpbGJveGVzGAEgAygLMhAuYzM1Lk1haWxNYWlsYm'
    '94UgltYWlsYm94ZXM=');

@$core.Deprecated('Use reqMailDomainListDescriptor instead')
const ReqMailDomainList$json = {
  '1': 'ReqMailDomainList',
};

/// Descriptor for `ReqMailDomainList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqMailDomainListDescriptor =
    $convert.base64Decode('ChFSZXFNYWlsRG9tYWluTGlzdA==');

@$core.Deprecated('Use resMailDomainListDescriptor instead')
const ResMailDomainList$json = {
  '1': 'ResMailDomainList',
  '2': [
    {
      '1': 'domains',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.c35.MailDomain',
      '10': 'domains'
    },
  ],
};

/// Descriptor for `ResMailDomainList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resMailDomainListDescriptor = $convert.base64Decode(
    'ChFSZXNNYWlsRG9tYWluTGlzdBIpCgdkb21haW5zGAEgAygLMg8uYzM1Lk1haWxEb21haW5SB2'
    'RvbWFpbnM=');

@$core.Deprecated('Use reqMailDomainAddDescriptor instead')
const ReqMailDomainAdd$json = {
  '1': 'ReqMailDomainAdd',
  '2': [
    {'1': 'hostname', '3': 1, '4': 1, '5': 9, '10': 'hostname'},
  ],
};

/// Descriptor for `ReqMailDomainAdd`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqMailDomainAddDescriptor = $convert.base64Decode(
    'ChBSZXFNYWlsRG9tYWluQWRkEhoKCGhvc3RuYW1lGAEgASgJUghob3N0bmFtZQ==');

@$core.Deprecated('Use resMailDomainAddDescriptor instead')
const ResMailDomainAdd$json = {
  '1': 'ResMailDomainAdd',
  '2': [
    {
      '1': 'domain',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.c35.MailDomain',
      '10': 'domain'
    },
  ],
};

/// Descriptor for `ResMailDomainAdd`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resMailDomainAddDescriptor = $convert.base64Decode(
    'ChBSZXNNYWlsRG9tYWluQWRkEicKBmRvbWFpbhgBIAEoCzIPLmMzNS5NYWlsRG9tYWluUgZkb2'
    '1haW4=');

@$core.Deprecated('Use reqMailAccountGetDescriptor instead')
const ReqMailAccountGet$json = {
  '1': 'ReqMailAccountGet',
};

/// Descriptor for `ReqMailAccountGet`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqMailAccountGetDescriptor =
    $convert.base64Decode('ChFSZXFNYWlsQWNjb3VudEdldA==');

@$core.Deprecated('Use resMailAccountGetDescriptor instead')
const ResMailAccountGet$json = {
  '1': 'ResMailAccountGet',
  '2': [
    {
      '1': 'account',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.c35.MailAccount',
      '10': 'account'
    },
  ],
};

/// Descriptor for `ResMailAccountGet`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resMailAccountGetDescriptor = $convert.base64Decode(
    'ChFSZXNNYWlsQWNjb3VudEdldBIqCgdhY2NvdW50GAEgASgLMhAuYzM1Lk1haWxBY2NvdW50Ug'
    'dhY2NvdW50');

@$core.Deprecated('Use reqMailArchiveDescriptor instead')
const ReqMailArchive$json = {
  '1': 'ReqMailArchive',
  '2': [
    {'1': 'message_ids', '3': 1, '4': 3, '5': 3, '10': 'messageIds'},
    {'1': 'archive', '3': 2, '4': 1, '5': 8, '10': 'archive'},
    {'1': 'mailbox_id', '3': 3, '4': 1, '5': 3, '10': 'mailboxId'},
  ],
};

/// Descriptor for `ReqMailArchive`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqMailArchiveDescriptor = $convert.base64Decode(
    'Cg5SZXFNYWlsQXJjaGl2ZRIfCgttZXNzYWdlX2lkcxgBIAMoA1IKbWVzc2FnZUlkcxIYCgdhcm'
    'NoaXZlGAIgASgIUgdhcmNoaXZlEh0KCm1haWxib3hfaWQYAyABKANSCW1haWxib3hJZA==');

@$core.Deprecated('Use resMailArchiveDescriptor instead')
const ResMailArchive$json = {
  '1': 'ResMailArchive',
  '2': [
    {'1': 'count', '3': 1, '4': 1, '5': 5, '10': 'count'},
  ],
};

/// Descriptor for `ResMailArchive`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resMailArchiveDescriptor = $convert
    .base64Decode('Cg5SZXNNYWlsQXJjaGl2ZRIUCgVjb3VudBgBIAEoBVIFY291bnQ=');

@$core.Deprecated('Use mailGroupDescriptor instead')
const MailGroup$json = {
  '1': 'MailGroup',
  '2': [
    {'1': 'group_id', '3': 1, '4': 1, '5': 9, '10': 'groupId'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'description', '3': 3, '4': 1, '5': 9, '10': 'description'},
    {'1': 'emails', '3': 4, '4': 3, '5': 9, '10': 'emails'},
    {'1': 'created_ts_ms', '3': 5, '4': 1, '5': 3, '10': 'createdTsMs'},
    {'1': 'updated_ts_ms', '3': 6, '4': 1, '5': 3, '10': 'updatedTsMs'},
  ],
};

/// Descriptor for `MailGroup`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mailGroupDescriptor = $convert.base64Decode(
    'CglNYWlsR3JvdXASGQoIZ3JvdXBfaWQYASABKAlSB2dyb3VwSWQSEgoEbmFtZRgCIAEoCVIEbm'
    'FtZRIgCgtkZXNjcmlwdGlvbhgDIAEoCVILZGVzY3JpcHRpb24SFgoGZW1haWxzGAQgAygJUgZl'
    'bWFpbHMSIgoNY3JlYXRlZF90c19tcxgFIAEoA1ILY3JlYXRlZFRzTXMSIgoNdXBkYXRlZF90c1'
    '9tcxgGIAEoA1ILdXBkYXRlZFRzTXM=');

@$core.Deprecated('Use reqMailGroupListDescriptor instead')
const ReqMailGroupList$json = {
  '1': 'ReqMailGroupList',
  '2': [
    {'1': 'mailbox_id', '3': 1, '4': 1, '5': 3, '10': 'mailboxId'},
  ],
};

/// Descriptor for `ReqMailGroupList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqMailGroupListDescriptor = $convert.base64Decode(
    'ChBSZXFNYWlsR3JvdXBMaXN0Eh0KCm1haWxib3hfaWQYASABKANSCW1haWxib3hJZA==');

@$core.Deprecated('Use resMailGroupListDescriptor instead')
const ResMailGroupList$json = {
  '1': 'ResMailGroupList',
  '2': [
    {
      '1': 'groups',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.c35.MailGroup',
      '10': 'groups'
    },
  ],
};

/// Descriptor for `ResMailGroupList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resMailGroupListDescriptor = $convert.base64Decode(
    'ChBSZXNNYWlsR3JvdXBMaXN0EiYKBmdyb3VwcxgBIAMoCzIOLmMzNS5NYWlsR3JvdXBSBmdyb3'
    'Vwcw==');

@$core.Deprecated('Use reqMailGroupUpsertDescriptor instead')
const ReqMailGroupUpsert$json = {
  '1': 'ReqMailGroupUpsert',
  '2': [
    {
      '1': 'group',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.c35.MailGroup',
      '10': 'group'
    },
    {'1': 'mailbox_id', '3': 2, '4': 1, '5': 3, '10': 'mailboxId'},
  ],
};

/// Descriptor for `ReqMailGroupUpsert`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqMailGroupUpsertDescriptor = $convert.base64Decode(
    'ChJSZXFNYWlsR3JvdXBVcHNlcnQSJAoFZ3JvdXAYASABKAsyDi5jMzUuTWFpbEdyb3VwUgVncm'
    '91cBIdCgptYWlsYm94X2lkGAIgASgDUgltYWlsYm94SWQ=');

@$core.Deprecated('Use resMailGroupUpsertDescriptor instead')
const ResMailGroupUpsert$json = {
  '1': 'ResMailGroupUpsert',
  '2': [
    {
      '1': 'group',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.c35.MailGroup',
      '10': 'group'
    },
  ],
};

/// Descriptor for `ResMailGroupUpsert`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resMailGroupUpsertDescriptor = $convert.base64Decode(
    'ChJSZXNNYWlsR3JvdXBVcHNlcnQSJAoFZ3JvdXAYASABKAsyDi5jMzUuTWFpbEdyb3VwUgVncm'
    '91cA==');

@$core.Deprecated('Use reqMailGroupDeleteDescriptor instead')
const ReqMailGroupDelete$json = {
  '1': 'ReqMailGroupDelete',
  '2': [
    {'1': 'group_id', '3': 1, '4': 1, '5': 9, '10': 'groupId'},
    {'1': 'mailbox_id', '3': 2, '4': 1, '5': 3, '10': 'mailboxId'},
  ],
};

/// Descriptor for `ReqMailGroupDelete`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqMailGroupDeleteDescriptor = $convert.base64Decode(
    'ChJSZXFNYWlsR3JvdXBEZWxldGUSGQoIZ3JvdXBfaWQYASABKAlSB2dyb3VwSWQSHQoKbWFpbG'
    'JveF9pZBgCIAEoA1IJbWFpbGJveElk');

@$core.Deprecated('Use resMailGroupDeleteDescriptor instead')
const ResMailGroupDelete$json = {
  '1': 'ResMailGroupDelete',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
  ],
};

/// Descriptor for `ResMailGroupDelete`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resMailGroupDeleteDescriptor =
    $convert.base64Decode(
        'ChJSZXNNYWlsR3JvdXBEZWxldGUSGAoHc3VjY2VzcxgBIAEoCFIHc3VjY2Vzcw==');

@$core.Deprecated('Use reqMailBroadcastDescriptor instead')
const ReqMailBroadcast$json = {
  '1': 'ReqMailBroadcast',
  '2': [
    {'1': 'group_id', '3': 1, '4': 1, '5': 9, '10': 'groupId'},
    {'1': 'custom_emails', '3': 2, '4': 3, '5': 9, '10': 'customEmails'},
    {'1': 'subject', '3': 3, '4': 1, '5': 9, '10': 'subject'},
    {'1': 'body_text', '3': 4, '4': 1, '5': 9, '10': 'bodyText'},
    {'1': 'body_html', '3': 5, '4': 1, '5': 9, '10': 'bodyHtml'},
    {
      '1': 'attachments',
      '3': 6,
      '4': 3,
      '5': 11,
      '6': '.c35.MailAttachment',
      '10': 'attachments'
    },
    {'1': 'mailbox_id', '3': 7, '4': 1, '5': 3, '10': 'mailboxId'},
  ],
};

/// Descriptor for `ReqMailBroadcast`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqMailBroadcastDescriptor = $convert.base64Decode(
    'ChBSZXFNYWlsQnJvYWRjYXN0EhkKCGdyb3VwX2lkGAEgASgJUgdncm91cElkEiMKDWN1c3RvbV'
    '9lbWFpbHMYAiADKAlSDGN1c3RvbUVtYWlscxIYCgdzdWJqZWN0GAMgASgJUgdzdWJqZWN0EhsK'
    'CWJvZHlfdGV4dBgEIAEoCVIIYm9keVRleHQSGwoJYm9keV9odG1sGAUgASgJUghib2R5SHRtbB'
    'I1CgthdHRhY2htZW50cxgGIAMoCzITLmMzNS5NYWlsQXR0YWNobWVudFILYXR0YWNobWVudHMS'
    'HQoKbWFpbGJveF9pZBgHIAEoA1IJbWFpbGJveElk');

@$core.Deprecated('Use mailBroadcastFailureDescriptor instead')
const MailBroadcastFailure$json = {
  '1': 'MailBroadcastFailure',
  '2': [
    {'1': 'to_addr', '3': 1, '4': 1, '5': 9, '10': 'toAddr'},
    {'1': 'error', '3': 2, '4': 1, '5': 9, '10': 'error'},
  ],
};

/// Descriptor for `MailBroadcastFailure`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mailBroadcastFailureDescriptor = $convert.base64Decode(
    'ChRNYWlsQnJvYWRjYXN0RmFpbHVyZRIXCgd0b19hZGRyGAEgASgJUgZ0b0FkZHISFAoFZXJyb3'
    'IYAiABKAlSBWVycm9y');

@$core.Deprecated('Use resMailBroadcastDescriptor instead')
const ResMailBroadcast$json = {
  '1': 'ResMailBroadcast',
  '2': [
    {'1': 'queued_count', '3': 1, '4': 1, '5': 5, '10': 'queuedCount'},
    {
      '1': 'failures',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.c35.MailBroadcastFailure',
      '10': 'failures'
    },
  ],
};

/// Descriptor for `ResMailBroadcast`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resMailBroadcastDescriptor = $convert.base64Decode(
    'ChBSZXNNYWlsQnJvYWRjYXN0EiEKDHF1ZXVlZF9jb3VudBgBIAEoBVILcXVldWVkQ291bnQSNQ'
    'oIZmFpbHVyZXMYAiADKAsyGS5jMzUuTWFpbEJyb2FkY2FzdEZhaWx1cmVSCGZhaWx1cmVz');

@$core.Deprecated('Use reqMailMarkReadDescriptor instead')
const ReqMailMarkRead$json = {
  '1': 'ReqMailMarkRead',
  '2': [
    {'1': 'message_ids', '3': 1, '4': 3, '5': 3, '10': 'messageIds'},
    {'1': 'read', '3': 2, '4': 1, '5': 8, '10': 'read'},
    {'1': 'mailbox_id', '3': 3, '4': 1, '5': 3, '10': 'mailboxId'},
  ],
};

/// Descriptor for `ReqMailMarkRead`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqMailMarkReadDescriptor = $convert.base64Decode(
    'Cg9SZXFNYWlsTWFya1JlYWQSHwoLbWVzc2FnZV9pZHMYASADKANSCm1lc3NhZ2VJZHMSEgoEcm'
    'VhZBgCIAEoCFIEcmVhZBIdCgptYWlsYm94X2lkGAMgASgDUgltYWlsYm94SWQ=');

@$core.Deprecated('Use resMailMarkReadDescriptor instead')
const ResMailMarkRead$json = {
  '1': 'ResMailMarkRead',
  '2': [
    {'1': 'count', '3': 1, '4': 1, '5': 5, '10': 'count'},
    {
      '1': 'inbox_unread_count',
      '3': 2,
      '4': 1,
      '5': 5,
      '10': 'inboxUnreadCount'
    },
  ],
};

/// Descriptor for `ResMailMarkRead`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resMailMarkReadDescriptor = $convert.base64Decode(
    'Cg9SZXNNYWlsTWFya1JlYWQSFAoFY291bnQYASABKAVSBWNvdW50EiwKEmluYm94X3VucmVhZF'
    '9jb3VudBgCIAEoBVIQaW5ib3hVbnJlYWRDb3VudA==');

@$core.Deprecated('Use reqMailMailboxAdminListDescriptor instead')
const ReqMailMailboxAdminList$json = {
  '1': 'ReqMailMailboxAdminList',
};

/// Descriptor for `ReqMailMailboxAdminList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqMailMailboxAdminListDescriptor =
    $convert.base64Decode('ChdSZXFNYWlsTWFpbGJveEFkbWluTGlzdA==');

@$core.Deprecated('Use resMailMailboxAdminListDescriptor instead')
const ResMailMailboxAdminList$json = {
  '1': 'ResMailMailboxAdminList',
  '2': [
    {
      '1': 'mailboxes',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.c35.MailMailbox',
      '10': 'mailboxes'
    },
  ],
};

/// Descriptor for `ResMailMailboxAdminList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resMailMailboxAdminListDescriptor =
    $convert.base64Decode(
        'ChdSZXNNYWlsTWFpbGJveEFkbWluTGlzdBIuCgltYWlsYm94ZXMYASADKAsyEC5jMzUuTWFpbE'
        '1haWxib3hSCW1haWxib3hlcw==');

@$core.Deprecated('Use reqMailMailboxCreateDescriptor instead')
const ReqMailMailboxCreate$json = {
  '1': 'ReqMailMailboxCreate',
  '2': [
    {
      '1': 'kind',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.c35.MailMailboxKind',
      '10': 'kind'
    },
    {'1': 'site_iid', '3': 2, '4': 1, '5': 3, '10': 'siteIid'},
    {'1': 'address', '3': 3, '4': 1, '5': 9, '10': 'address'},
    {'1': 'label', '3': 4, '4': 1, '5': 9, '10': 'label'},
    {'1': 'subscriber_limit', '3': 5, '4': 1, '5': 5, '10': 'subscriberLimit'},
    {
      '1': 'members',
      '3': 6,
      '4': 3,
      '5': 11,
      '6': '.c35.MailMailboxMember',
      '10': 'members'
    },
  ],
};

/// Descriptor for `ReqMailMailboxCreate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqMailMailboxCreateDescriptor = $convert.base64Decode(
    'ChRSZXFNYWlsTWFpbGJveENyZWF0ZRIoCgRraW5kGAEgASgOMhQuYzM1Lk1haWxNYWlsYm94S2'
    'luZFIEa2luZBIZCghzaXRlX2lpZBgCIAEoA1IHc2l0ZUlpZBIYCgdhZGRyZXNzGAMgASgJUgdh'
    'ZGRyZXNzEhQKBWxhYmVsGAQgASgJUgVsYWJlbBIpChBzdWJzY3JpYmVyX2xpbWl0GAUgASgFUg'
    '9zdWJzY3JpYmVyTGltaXQSMAoHbWVtYmVycxgGIAMoCzIWLmMzNS5NYWlsTWFpbGJveE1lbWJl'
    'clIHbWVtYmVycw==');

@$core.Deprecated('Use resMailMailboxCreateDescriptor instead')
const ResMailMailboxCreate$json = {
  '1': 'ResMailMailboxCreate',
  '2': [
    {
      '1': 'mailbox',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.c35.MailMailbox',
      '10': 'mailbox'
    },
  ],
};

/// Descriptor for `ResMailMailboxCreate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resMailMailboxCreateDescriptor = $convert.base64Decode(
    'ChRSZXNNYWlsTWFpbGJveENyZWF0ZRIqCgdtYWlsYm94GAEgASgLMhAuYzM1Lk1haWxNYWlsYm'
    '94UgdtYWlsYm94');

@$core.Deprecated('Use reqMailMailboxUpdateDescriptor instead')
const ReqMailMailboxUpdate$json = {
  '1': 'ReqMailMailboxUpdate',
  '2': [
    {'1': 'mailbox_id', '3': 1, '4': 1, '5': 3, '10': 'mailboxId'},
    {'1': 'label', '3': 2, '4': 1, '5': 9, '10': 'label'},
    {'1': 'subscriber_limit', '3': 3, '4': 1, '5': 5, '10': 'subscriberLimit'},
    {
      '1': 'members',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.c35.MailMailboxMember',
      '10': 'members'
    },
  ],
};

/// Descriptor for `ReqMailMailboxUpdate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqMailMailboxUpdateDescriptor = $convert.base64Decode(
    'ChRSZXFNYWlsTWFpbGJveFVwZGF0ZRIdCgptYWlsYm94X2lkGAEgASgDUgltYWlsYm94SWQSFA'
    'oFbGFiZWwYAiABKAlSBWxhYmVsEikKEHN1YnNjcmliZXJfbGltaXQYAyABKAVSD3N1YnNjcmli'
    'ZXJMaW1pdBIwCgdtZW1iZXJzGAQgAygLMhYuYzM1Lk1haWxNYWlsYm94TWVtYmVyUgdtZW1iZX'
    'Jz');

@$core.Deprecated('Use resMailMailboxUpdateDescriptor instead')
const ResMailMailboxUpdate$json = {
  '1': 'ResMailMailboxUpdate',
  '2': [
    {
      '1': 'mailbox',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.c35.MailMailbox',
      '10': 'mailbox'
    },
  ],
};

/// Descriptor for `ResMailMailboxUpdate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resMailMailboxUpdateDescriptor = $convert.base64Decode(
    'ChRSZXNNYWlsTWFpbGJveFVwZGF0ZRIqCgdtYWlsYm94GAEgASgLMhAuYzM1Lk1haWxNYWlsYm'
    '94UgdtYWlsYm94');

@$core.Deprecated('Use reqMailMailboxDeleteDescriptor instead')
const ReqMailMailboxDelete$json = {
  '1': 'ReqMailMailboxDelete',
  '2': [
    {'1': 'mailbox_id', '3': 1, '4': 1, '5': 3, '10': 'mailboxId'},
  ],
};

/// Descriptor for `ReqMailMailboxDelete`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqMailMailboxDeleteDescriptor = $convert.base64Decode(
    'ChRSZXFNYWlsTWFpbGJveERlbGV0ZRIdCgptYWlsYm94X2lkGAEgASgDUgltYWlsYm94SWQ=');

@$core.Deprecated('Use resMailMailboxDeleteDescriptor instead')
const ResMailMailboxDelete$json = {
  '1': 'ResMailMailboxDelete',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
  ],
};

/// Descriptor for `ResMailMailboxDelete`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resMailMailboxDeleteDescriptor =
    $convert.base64Decode(
        'ChRSZXNNYWlsTWFpbGJveERlbGV0ZRIYCgdzdWNjZXNzGAEgASgIUgdzdWNjZXNz');

@$core.Deprecated('Use reqMailDomainFixDescriptor instead')
const ReqMailDomainFix$json = {
  '1': 'ReqMailDomainFix',
  '2': [
    {'1': 'hostname', '3': 1, '4': 1, '5': 9, '10': 'hostname'},
  ],
};

/// Descriptor for `ReqMailDomainFix`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqMailDomainFixDescriptor = $convert.base64Decode(
    'ChBSZXFNYWlsRG9tYWluRml4EhoKCGhvc3RuYW1lGAEgASgJUghob3N0bmFtZQ==');

@$core.Deprecated('Use resMailDomainFixDescriptor instead')
const ResMailDomainFix$json = {
  '1': 'ResMailDomainFix',
  '2': [
    {
      '1': 'domain',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.c35.MailDomain',
      '10': 'domain'
    },
  ],
};

/// Descriptor for `ResMailDomainFix`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resMailDomainFixDescriptor = $convert.base64Decode(
    'ChBSZXNNYWlsRG9tYWluRml4EicKBmRvbWFpbhgBIAEoCzIPLmMzNS5NYWlsRG9tYWluUgZkb2'
    '1haW4=');
