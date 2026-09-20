//
//  Generated code. Do not modify.
//  source: c35/chat.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class ChatKind extends $pb.ProtobufEnum {
  static const ChatKind CHAT_KIND_UNSPECIFIED = ChatKind._(0, _omitEnumNames ? '' : 'CHAT_KIND_UNSPECIFIED');
  static const ChatKind CHAT_KIND_PROMPT = ChatKind._(1, _omitEnumNames ? '' : 'CHAT_KIND_PROMPT');
  static const ChatKind CHAT_KIND_DIRECT = ChatKind._(2, _omitEnumNames ? '' : 'CHAT_KIND_DIRECT');
  static const ChatKind CHAT_KIND_BOT_PEER = ChatKind._(3, _omitEnumNames ? '' : 'CHAT_KIND_BOT_PEER');

  static const $core.List<ChatKind> values = <ChatKind> [
    CHAT_KIND_UNSPECIFIED,
    CHAT_KIND_PROMPT,
    CHAT_KIND_DIRECT,
    CHAT_KIND_BOT_PEER,
  ];

  static final $core.Map<$core.int, ChatKind> _byValue = $pb.ProtobufEnum.initByValue(values);
  static ChatKind? valueOf($core.int value) => _byValue[value];

  const ChatKind._($core.int v, $core.String n) : super(v, n);
}

class ChatMsgRole extends $pb.ProtobufEnum {
  static const ChatMsgRole CHAT_MSG_ROLE_UNSPECIFIED = ChatMsgRole._(0, _omitEnumNames ? '' : 'CHAT_MSG_ROLE_UNSPECIFIED');
  static const ChatMsgRole CHAT_MSG_ROLE_USER = ChatMsgRole._(1, _omitEnumNames ? '' : 'CHAT_MSG_ROLE_USER');
  static const ChatMsgRole CHAT_MSG_ROLE_ASSISTANT = ChatMsgRole._(2, _omitEnumNames ? '' : 'CHAT_MSG_ROLE_ASSISTANT');
  static const ChatMsgRole CHAT_MSG_ROLE_SYSTEM = ChatMsgRole._(3, _omitEnumNames ? '' : 'CHAT_MSG_ROLE_SYSTEM');

  static const $core.List<ChatMsgRole> values = <ChatMsgRole> [
    CHAT_MSG_ROLE_UNSPECIFIED,
    CHAT_MSG_ROLE_USER,
    CHAT_MSG_ROLE_ASSISTANT,
    CHAT_MSG_ROLE_SYSTEM,
  ];

  static final $core.Map<$core.int, ChatMsgRole> _byValue = $pb.ProtobufEnum.initByValue(values);
  static ChatMsgRole? valueOf($core.int value) => _byValue[value];

  const ChatMsgRole._($core.int v, $core.String n) : super(v, n);
}

class ChatMsgSource extends $pb.ProtobufEnum {
  static const ChatMsgSource CHAT_MSG_SOURCE_UNSPECIFIED = ChatMsgSource._(0, _omitEnumNames ? '' : 'CHAT_MSG_SOURCE_UNSPECIFIED');
  static const ChatMsgSource CHAT_MSG_SOURCE_PROMPT = ChatMsgSource._(1, _omitEnumNames ? '' : 'CHAT_MSG_SOURCE_PROMPT');
  static const ChatMsgSource CHAT_MSG_SOURCE_USER = ChatMsgSource._(2, _omitEnumNames ? '' : 'CHAT_MSG_SOURCE_USER');
  static const ChatMsgSource CHAT_MSG_SOURCE_EXTERNAL = ChatMsgSource._(3, _omitEnumNames ? '' : 'CHAT_MSG_SOURCE_EXTERNAL');
  static const ChatMsgSource CHAT_MSG_SOURCE_STAFF = ChatMsgSource._(4, _omitEnumNames ? '' : 'CHAT_MSG_SOURCE_STAFF');

  static const $core.List<ChatMsgSource> values = <ChatMsgSource> [
    CHAT_MSG_SOURCE_UNSPECIFIED,
    CHAT_MSG_SOURCE_PROMPT,
    CHAT_MSG_SOURCE_USER,
    CHAT_MSG_SOURCE_EXTERNAL,
    CHAT_MSG_SOURCE_STAFF,
  ];

  static final $core.Map<$core.int, ChatMsgSource> _byValue = $pb.ProtobufEnum.initByValue(values);
  static ChatMsgSource? valueOf($core.int value) => _byValue[value];

  const ChatMsgSource._($core.int v, $core.String n) : super(v, n);
}

class ChatMsgStatus extends $pb.ProtobufEnum {
  static const ChatMsgStatus CHAT_MSG_STATUS_UNSPECIFIED = ChatMsgStatus._(0, _omitEnumNames ? '' : 'CHAT_MSG_STATUS_UNSPECIFIED');
  static const ChatMsgStatus CHAT_MSG_STATUS_STREAMING = ChatMsgStatus._(1, _omitEnumNames ? '' : 'CHAT_MSG_STATUS_STREAMING');
  static const ChatMsgStatus CHAT_MSG_STATUS_DONE = ChatMsgStatus._(2, _omitEnumNames ? '' : 'CHAT_MSG_STATUS_DONE');
  static const ChatMsgStatus CHAT_MSG_STATUS_INTERRUPTED = ChatMsgStatus._(3, _omitEnumNames ? '' : 'CHAT_MSG_STATUS_INTERRUPTED');
  static const ChatMsgStatus CHAT_MSG_STATUS_ERROR = ChatMsgStatus._(4, _omitEnumNames ? '' : 'CHAT_MSG_STATUS_ERROR');

  static const $core.List<ChatMsgStatus> values = <ChatMsgStatus> [
    CHAT_MSG_STATUS_UNSPECIFIED,
    CHAT_MSG_STATUS_STREAMING,
    CHAT_MSG_STATUS_DONE,
    CHAT_MSG_STATUS_INTERRUPTED,
    CHAT_MSG_STATUS_ERROR,
  ];

  static final $core.Map<$core.int, ChatMsgStatus> _byValue = $pb.ProtobufEnum.initByValue(values);
  static ChatMsgStatus? valueOf($core.int value) => _byValue[value];

  const ChatMsgStatus._($core.int v, $core.String n) : super(v, n);
}


const _omitEnumNames = $core.bool.fromEnvironment('protobuf.omit_enum_names');
