// This is a generated file - do not edit.
//
// Generated from c35/chat.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'chat.pbenum.dart';
import 'log.pb.dart' as $0;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'chat.pbenum.dart';

class Chat extends $pb.GeneratedMessage {
  factory Chat({
    $fixnum.Int64? id,
    ChatKind? kind,
    $fixnum.Int64? ownerIid,
    $core.String? title,
    $core.Iterable<$core.String>? tags,
    $core.String? model,
    $fixnum.Int64? botIid,
    $core.String? channelId,
    $core.String? peerKey,
    $core.String? peerName,
    $core.String? peerPic,
    $core.bool? aiReplyEnabled,
    $fixnum.Int64? lastMsgTsMs,
    $core.String? lastMsgPreview,
    $core.String? metaJson,
    $fixnum.Int64? createdTsMs,
    $fixnum.Int64? updatedTsMs,
    $fixnum.Int64? deletedTsMs,
  }) {
    final result = Chat._();
    if (id != null) result.id = id;
    if (kind != null) result.kind = kind;
    if (ownerIid != null) result.ownerIid = ownerIid;
    if (title != null) result.title = title;
    if (tags != null) result.tags.addAll(tags);
    if (model != null) result.model = model;
    if (botIid != null) result.botIid = botIid;
    if (channelId != null) result.channelId = channelId;
    if (peerKey != null) result.peerKey = peerKey;
    if (peerName != null) result.peerName = peerName;
    if (peerPic != null) result.peerPic = peerPic;
    if (aiReplyEnabled != null) result.aiReplyEnabled = aiReplyEnabled;
    if (lastMsgTsMs != null) result.lastMsgTsMs = lastMsgTsMs;
    if (lastMsgPreview != null) result.lastMsgPreview = lastMsgPreview;
    if (metaJson != null) result.metaJson = metaJson;
    if (createdTsMs != null) result.createdTsMs = createdTsMs;
    if (updatedTsMs != null) result.updatedTsMs = updatedTsMs;
    if (deletedTsMs != null) result.deletedTsMs = deletedTsMs;
    return result;
  }

  Chat._();

  factory Chat.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Chat()..mergeFromBuffer(data, registry);
  factory Chat.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Chat()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Chat',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: Chat.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..aE<ChatKind>(2, _omitFieldNames ? '' : 'kind',
        enumValues: ChatKind.values)
    ..aInt64(3, _omitFieldNames ? '' : 'ownerIid')
    ..aOS(4, _omitFieldNames ? '' : 'title')
    ..pPS(5, _omitFieldNames ? '' : 'tags')
    ..aOS(6, _omitFieldNames ? '' : 'model')
    ..aInt64(7, _omitFieldNames ? '' : 'botIid')
    ..aOS(8, _omitFieldNames ? '' : 'channelId')
    ..aOS(9, _omitFieldNames ? '' : 'peerKey')
    ..aOS(10, _omitFieldNames ? '' : 'peerName')
    ..aOS(11, _omitFieldNames ? '' : 'peerPic')
    ..aOB(12, _omitFieldNames ? '' : 'aiReplyEnabled')
    ..aInt64(13, _omitFieldNames ? '' : 'lastMsgTsMs')
    ..aOS(14, _omitFieldNames ? '' : 'lastMsgPreview')
    ..aOS(15, _omitFieldNames ? '' : 'metaJson')
    ..aInt64(16, _omitFieldNames ? '' : 'createdTsMs')
    ..aInt64(17, _omitFieldNames ? '' : 'updatedTsMs')
    ..aInt64(18, _omitFieldNames ? '' : 'deletedTsMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Chat clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Chat copyWith(void Function(Chat) updates) =>
      super.copyWith((message) => updates(message as Chat)) as Chat;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Chat() / Chat.new instead')
  static Chat create() => Chat._();
  static $pb.GeneratedMessage $_createMessage() => Chat._();
  @$core.override
  Chat createEmptyInstance() => Chat._();
  @$core.pragma('dart2js:noInline')
  static Chat getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Chat>(Chat.$_createMessage);
  static Chat? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  ChatKind get kind => $_getN(1);
  @$pb.TagNumber(2)
  set kind(ChatKind value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasKind() => $_has(1);
  @$pb.TagNumber(2)
  void clearKind() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get ownerIid => $_getI64(2);
  @$pb.TagNumber(3)
  set ownerIid($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasOwnerIid() => $_has(2);
  @$pb.TagNumber(3)
  void clearOwnerIid() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get title => $_getSZ(3);
  @$pb.TagNumber(4)
  set title($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTitle() => $_has(3);
  @$pb.TagNumber(4)
  void clearTitle() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbList<$core.String> get tags => $_getList(4);

  @$pb.TagNumber(6)
  $core.String get model => $_getSZ(5);
  @$pb.TagNumber(6)
  set model($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasModel() => $_has(5);
  @$pb.TagNumber(6)
  void clearModel() => $_clearField(6);

  @$pb.TagNumber(7)
  $fixnum.Int64 get botIid => $_getI64(6);
  @$pb.TagNumber(7)
  set botIid($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(7)
  $core.bool hasBotIid() => $_has(6);
  @$pb.TagNumber(7)
  void clearBotIid() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get channelId => $_getSZ(7);
  @$pb.TagNumber(8)
  set channelId($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasChannelId() => $_has(7);
  @$pb.TagNumber(8)
  void clearChannelId() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get peerKey => $_getSZ(8);
  @$pb.TagNumber(9)
  set peerKey($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasPeerKey() => $_has(8);
  @$pb.TagNumber(9)
  void clearPeerKey() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.String get peerName => $_getSZ(9);
  @$pb.TagNumber(10)
  set peerName($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasPeerName() => $_has(9);
  @$pb.TagNumber(10)
  void clearPeerName() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.String get peerPic => $_getSZ(10);
  @$pb.TagNumber(11)
  set peerPic($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasPeerPic() => $_has(10);
  @$pb.TagNumber(11)
  void clearPeerPic() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.bool get aiReplyEnabled => $_getBF(11);
  @$pb.TagNumber(12)
  set aiReplyEnabled($core.bool value) => $_setBool(11, value);
  @$pb.TagNumber(12)
  $core.bool hasAiReplyEnabled() => $_has(11);
  @$pb.TagNumber(12)
  void clearAiReplyEnabled() => $_clearField(12);

  @$pb.TagNumber(13)
  $fixnum.Int64 get lastMsgTsMs => $_getI64(12);
  @$pb.TagNumber(13)
  set lastMsgTsMs($fixnum.Int64 value) => $_setInt64(12, value);
  @$pb.TagNumber(13)
  $core.bool hasLastMsgTsMs() => $_has(12);
  @$pb.TagNumber(13)
  void clearLastMsgTsMs() => $_clearField(13);

  @$pb.TagNumber(14)
  $core.String get lastMsgPreview => $_getSZ(13);
  @$pb.TagNumber(14)
  set lastMsgPreview($core.String value) => $_setString(13, value);
  @$pb.TagNumber(14)
  $core.bool hasLastMsgPreview() => $_has(13);
  @$pb.TagNumber(14)
  void clearLastMsgPreview() => $_clearField(14);

  @$pb.TagNumber(15)
  $core.String get metaJson => $_getSZ(14);
  @$pb.TagNumber(15)
  set metaJson($core.String value) => $_setString(14, value);
  @$pb.TagNumber(15)
  $core.bool hasMetaJson() => $_has(14);
  @$pb.TagNumber(15)
  void clearMetaJson() => $_clearField(15);

  @$pb.TagNumber(16)
  $fixnum.Int64 get createdTsMs => $_getI64(15);
  @$pb.TagNumber(16)
  set createdTsMs($fixnum.Int64 value) => $_setInt64(15, value);
  @$pb.TagNumber(16)
  $core.bool hasCreatedTsMs() => $_has(15);
  @$pb.TagNumber(16)
  void clearCreatedTsMs() => $_clearField(16);

  @$pb.TagNumber(17)
  $fixnum.Int64 get updatedTsMs => $_getI64(16);
  @$pb.TagNumber(17)
  set updatedTsMs($fixnum.Int64 value) => $_setInt64(16, value);
  @$pb.TagNumber(17)
  $core.bool hasUpdatedTsMs() => $_has(16);
  @$pb.TagNumber(17)
  void clearUpdatedTsMs() => $_clearField(17);

  @$pb.TagNumber(18)
  $fixnum.Int64 get deletedTsMs => $_getI64(17);
  @$pb.TagNumber(18)
  set deletedTsMs($fixnum.Int64 value) => $_setInt64(17, value);
  @$pb.TagNumber(18)
  $core.bool hasDeletedTsMs() => $_has(17);
  @$pb.TagNumber(18)
  void clearDeletedTsMs() => $_clearField(18);
}

class ChatMember extends $pb.GeneratedMessage {
  factory ChatMember({
    $fixnum.Int64? chatId,
    $fixnum.Int64? memberIid,
    $fixnum.Int64? lastReadMsgId,
    $core.int? unreadCount,
    $fixnum.Int64? lastMsgTsMs,
    $core.String? lastMsgPreview,
    $fixnum.Int64? pinnedTsMs,
    $fixnum.Int64? archivedTsMs,
    $fixnum.Int64? createdTsMs,
    $fixnum.Int64? updatedTsMs,
    $fixnum.Int64? deletedTsMs,
    $core.String? lastMsgStatus,
  }) {
    final result = ChatMember._();
    if (chatId != null) result.chatId = chatId;
    if (memberIid != null) result.memberIid = memberIid;
    if (lastReadMsgId != null) result.lastReadMsgId = lastReadMsgId;
    if (unreadCount != null) result.unreadCount = unreadCount;
    if (lastMsgTsMs != null) result.lastMsgTsMs = lastMsgTsMs;
    if (lastMsgPreview != null) result.lastMsgPreview = lastMsgPreview;
    if (pinnedTsMs != null) result.pinnedTsMs = pinnedTsMs;
    if (archivedTsMs != null) result.archivedTsMs = archivedTsMs;
    if (createdTsMs != null) result.createdTsMs = createdTsMs;
    if (updatedTsMs != null) result.updatedTsMs = updatedTsMs;
    if (deletedTsMs != null) result.deletedTsMs = deletedTsMs;
    if (lastMsgStatus != null) result.lastMsgStatus = lastMsgStatus;
    return result;
  }

  ChatMember._();

  factory ChatMember.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ChatMember()..mergeFromBuffer(data, registry);
  factory ChatMember.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ChatMember()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ChatMember',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ChatMember.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'chatId')
    ..aInt64(2, _omitFieldNames ? '' : 'memberIid')
    ..aInt64(3, _omitFieldNames ? '' : 'lastReadMsgId')
    ..aI(4, _omitFieldNames ? '' : 'unreadCount')
    ..aInt64(5, _omitFieldNames ? '' : 'lastMsgTsMs')
    ..aOS(6, _omitFieldNames ? '' : 'lastMsgPreview')
    ..aInt64(7, _omitFieldNames ? '' : 'pinnedTsMs')
    ..aInt64(8, _omitFieldNames ? '' : 'archivedTsMs')
    ..aInt64(9, _omitFieldNames ? '' : 'createdTsMs')
    ..aInt64(10, _omitFieldNames ? '' : 'updatedTsMs')
    ..aInt64(11, _omitFieldNames ? '' : 'deletedTsMs')
    ..aOS(12, _omitFieldNames ? '' : 'lastMsgStatus')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChatMember clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChatMember copyWith(void Function(ChatMember) updates) =>
      super.copyWith((message) => updates(message as ChatMember)) as ChatMember;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ChatMember() / ChatMember.new instead')
  static ChatMember create() => ChatMember._();
  static $pb.GeneratedMessage $_createMessage() => ChatMember._();
  @$core.override
  ChatMember createEmptyInstance() => ChatMember._();
  @$core.pragma('dart2js:noInline')
  static ChatMember getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ChatMember>(ChatMember.$_createMessage);
  static ChatMember? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get chatId => $_getI64(0);
  @$pb.TagNumber(1)
  set chatId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasChatId() => $_has(0);
  @$pb.TagNumber(1)
  void clearChatId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get memberIid => $_getI64(1);
  @$pb.TagNumber(2)
  set memberIid($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMemberIid() => $_has(1);
  @$pb.TagNumber(2)
  void clearMemberIid() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get lastReadMsgId => $_getI64(2);
  @$pb.TagNumber(3)
  set lastReadMsgId($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLastReadMsgId() => $_has(2);
  @$pb.TagNumber(3)
  void clearLastReadMsgId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get unreadCount => $_getIZ(3);
  @$pb.TagNumber(4)
  set unreadCount($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasUnreadCount() => $_has(3);
  @$pb.TagNumber(4)
  void clearUnreadCount() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get lastMsgTsMs => $_getI64(4);
  @$pb.TagNumber(5)
  set lastMsgTsMs($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasLastMsgTsMs() => $_has(4);
  @$pb.TagNumber(5)
  void clearLastMsgTsMs() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get lastMsgPreview => $_getSZ(5);
  @$pb.TagNumber(6)
  set lastMsgPreview($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasLastMsgPreview() => $_has(5);
  @$pb.TagNumber(6)
  void clearLastMsgPreview() => $_clearField(6);

  @$pb.TagNumber(7)
  $fixnum.Int64 get pinnedTsMs => $_getI64(6);
  @$pb.TagNumber(7)
  set pinnedTsMs($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(7)
  $core.bool hasPinnedTsMs() => $_has(6);
  @$pb.TagNumber(7)
  void clearPinnedTsMs() => $_clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get archivedTsMs => $_getI64(7);
  @$pb.TagNumber(8)
  set archivedTsMs($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(8)
  $core.bool hasArchivedTsMs() => $_has(7);
  @$pb.TagNumber(8)
  void clearArchivedTsMs() => $_clearField(8);

  @$pb.TagNumber(9)
  $fixnum.Int64 get createdTsMs => $_getI64(8);
  @$pb.TagNumber(9)
  set createdTsMs($fixnum.Int64 value) => $_setInt64(8, value);
  @$pb.TagNumber(9)
  $core.bool hasCreatedTsMs() => $_has(8);
  @$pb.TagNumber(9)
  void clearCreatedTsMs() => $_clearField(9);

  @$pb.TagNumber(10)
  $fixnum.Int64 get updatedTsMs => $_getI64(9);
  @$pb.TagNumber(10)
  set updatedTsMs($fixnum.Int64 value) => $_setInt64(9, value);
  @$pb.TagNumber(10)
  $core.bool hasUpdatedTsMs() => $_has(9);
  @$pb.TagNumber(10)
  void clearUpdatedTsMs() => $_clearField(10);

  @$pb.TagNumber(11)
  $fixnum.Int64 get deletedTsMs => $_getI64(10);
  @$pb.TagNumber(11)
  set deletedTsMs($fixnum.Int64 value) => $_setInt64(10, value);
  @$pb.TagNumber(11)
  $core.bool hasDeletedTsMs() => $_has(10);
  @$pb.TagNumber(11)
  void clearDeletedTsMs() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.String get lastMsgStatus => $_getSZ(11);
  @$pb.TagNumber(12)
  set lastMsgStatus($core.String value) => $_setString(11, value);
  @$pb.TagNumber(12)
  $core.bool hasLastMsgStatus() => $_has(11);
  @$pb.TagNumber(12)
  void clearLastMsgStatus() => $_clearField(12);
}

class ChatMsg extends $pb.GeneratedMessage {
  factory ChatMsg({
    $fixnum.Int64? id,
    $fixnum.Int64? chatId,
    $fixnum.Int64? ownerIid,
    $core.String? reqId,
    $fixnum.Int64? senderIid,
    ChatMsgRole? role,
    ChatMsgSource? source,
    $core.String? content,
    $core.String? thought,
    $core.String? attachmentsJson,
    $core.String? blocksJson,
    $core.int? tokensIn,
    $core.int? tokensOut,
    $core.int? durationMs,
    ChatMsgStatus? status,
    $core.double? costUsd,
    $fixnum.Int64? createdTsMs,
    $fixnum.Int64? updatedTsMs,
    $fixnum.Int64? deletedTsMs,
    $core.String? errorText,
  }) {
    final result = ChatMsg._();
    if (id != null) result.id = id;
    if (chatId != null) result.chatId = chatId;
    if (ownerIid != null) result.ownerIid = ownerIid;
    if (reqId != null) result.reqId = reqId;
    if (senderIid != null) result.senderIid = senderIid;
    if (role != null) result.role = role;
    if (source != null) result.source = source;
    if (content != null) result.content = content;
    if (thought != null) result.thought = thought;
    if (attachmentsJson != null) result.attachmentsJson = attachmentsJson;
    if (blocksJson != null) result.blocksJson = blocksJson;
    if (tokensIn != null) result.tokensIn = tokensIn;
    if (tokensOut != null) result.tokensOut = tokensOut;
    if (durationMs != null) result.durationMs = durationMs;
    if (status != null) result.status = status;
    if (costUsd != null) result.costUsd = costUsd;
    if (createdTsMs != null) result.createdTsMs = createdTsMs;
    if (updatedTsMs != null) result.updatedTsMs = updatedTsMs;
    if (deletedTsMs != null) result.deletedTsMs = deletedTsMs;
    if (errorText != null) result.errorText = errorText;
    return result;
  }

  ChatMsg._();

  factory ChatMsg.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ChatMsg()..mergeFromBuffer(data, registry);
  factory ChatMsg.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ChatMsg()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ChatMsg',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ChatMsg.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..aInt64(2, _omitFieldNames ? '' : 'chatId')
    ..aInt64(3, _omitFieldNames ? '' : 'ownerIid')
    ..aOS(4, _omitFieldNames ? '' : 'reqId')
    ..aInt64(5, _omitFieldNames ? '' : 'senderIid')
    ..aE<ChatMsgRole>(6, _omitFieldNames ? '' : 'role',
        enumValues: ChatMsgRole.values)
    ..aE<ChatMsgSource>(7, _omitFieldNames ? '' : 'source',
        enumValues: ChatMsgSource.values)
    ..aOS(8, _omitFieldNames ? '' : 'content')
    ..aOS(9, _omitFieldNames ? '' : 'thought')
    ..aOS(10, _omitFieldNames ? '' : 'attachmentsJson')
    ..aOS(11, _omitFieldNames ? '' : 'blocksJson')
    ..aI(12, _omitFieldNames ? '' : 'tokensIn')
    ..aI(13, _omitFieldNames ? '' : 'tokensOut')
    ..aI(14, _omitFieldNames ? '' : 'durationMs')
    ..aE<ChatMsgStatus>(15, _omitFieldNames ? '' : 'status',
        enumValues: ChatMsgStatus.values)
    ..aD(16, _omitFieldNames ? '' : 'costUsd')
    ..aInt64(17, _omitFieldNames ? '' : 'createdTsMs')
    ..aInt64(18, _omitFieldNames ? '' : 'updatedTsMs')
    ..aInt64(19, _omitFieldNames ? '' : 'deletedTsMs')
    ..aOS(20, _omitFieldNames ? '' : 'errorText')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChatMsg clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChatMsg copyWith(void Function(ChatMsg) updates) =>
      super.copyWith((message) => updates(message as ChatMsg)) as ChatMsg;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ChatMsg() / ChatMsg.new instead')
  static ChatMsg create() => ChatMsg._();
  static $pb.GeneratedMessage $_createMessage() => ChatMsg._();
  @$core.override
  ChatMsg createEmptyInstance() => ChatMsg._();
  @$core.pragma('dart2js:noInline')
  static ChatMsg getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ChatMsg>(ChatMsg.$_createMessage);
  static ChatMsg? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get chatId => $_getI64(1);
  @$pb.TagNumber(2)
  set chatId($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasChatId() => $_has(1);
  @$pb.TagNumber(2)
  void clearChatId() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get ownerIid => $_getI64(2);
  @$pb.TagNumber(3)
  set ownerIid($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasOwnerIid() => $_has(2);
  @$pb.TagNumber(3)
  void clearOwnerIid() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get reqId => $_getSZ(3);
  @$pb.TagNumber(4)
  set reqId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasReqId() => $_has(3);
  @$pb.TagNumber(4)
  void clearReqId() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get senderIid => $_getI64(4);
  @$pb.TagNumber(5)
  set senderIid($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSenderIid() => $_has(4);
  @$pb.TagNumber(5)
  void clearSenderIid() => $_clearField(5);

  @$pb.TagNumber(6)
  ChatMsgRole get role => $_getN(5);
  @$pb.TagNumber(6)
  set role(ChatMsgRole value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasRole() => $_has(5);
  @$pb.TagNumber(6)
  void clearRole() => $_clearField(6);

  @$pb.TagNumber(7)
  ChatMsgSource get source => $_getN(6);
  @$pb.TagNumber(7)
  set source(ChatMsgSource value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasSource() => $_has(6);
  @$pb.TagNumber(7)
  void clearSource() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get content => $_getSZ(7);
  @$pb.TagNumber(8)
  set content($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasContent() => $_has(7);
  @$pb.TagNumber(8)
  void clearContent() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get thought => $_getSZ(8);
  @$pb.TagNumber(9)
  set thought($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasThought() => $_has(8);
  @$pb.TagNumber(9)
  void clearThought() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.String get attachmentsJson => $_getSZ(9);
  @$pb.TagNumber(10)
  set attachmentsJson($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasAttachmentsJson() => $_has(9);
  @$pb.TagNumber(10)
  void clearAttachmentsJson() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.String get blocksJson => $_getSZ(10);
  @$pb.TagNumber(11)
  set blocksJson($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasBlocksJson() => $_has(10);
  @$pb.TagNumber(11)
  void clearBlocksJson() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.int get tokensIn => $_getIZ(11);
  @$pb.TagNumber(12)
  set tokensIn($core.int value) => $_setSignedInt32(11, value);
  @$pb.TagNumber(12)
  $core.bool hasTokensIn() => $_has(11);
  @$pb.TagNumber(12)
  void clearTokensIn() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.int get tokensOut => $_getIZ(12);
  @$pb.TagNumber(13)
  set tokensOut($core.int value) => $_setSignedInt32(12, value);
  @$pb.TagNumber(13)
  $core.bool hasTokensOut() => $_has(12);
  @$pb.TagNumber(13)
  void clearTokensOut() => $_clearField(13);

  @$pb.TagNumber(14)
  $core.int get durationMs => $_getIZ(13);
  @$pb.TagNumber(14)
  set durationMs($core.int value) => $_setSignedInt32(13, value);
  @$pb.TagNumber(14)
  $core.bool hasDurationMs() => $_has(13);
  @$pb.TagNumber(14)
  void clearDurationMs() => $_clearField(14);

  @$pb.TagNumber(15)
  ChatMsgStatus get status => $_getN(14);
  @$pb.TagNumber(15)
  set status(ChatMsgStatus value) => $_setField(15, value);
  @$pb.TagNumber(15)
  $core.bool hasStatus() => $_has(14);
  @$pb.TagNumber(15)
  void clearStatus() => $_clearField(15);

  @$pb.TagNumber(16)
  $core.double get costUsd => $_getN(15);
  @$pb.TagNumber(16)
  set costUsd($core.double value) => $_setDouble(15, value);
  @$pb.TagNumber(16)
  $core.bool hasCostUsd() => $_has(15);
  @$pb.TagNumber(16)
  void clearCostUsd() => $_clearField(16);

  @$pb.TagNumber(17)
  $fixnum.Int64 get createdTsMs => $_getI64(16);
  @$pb.TagNumber(17)
  set createdTsMs($fixnum.Int64 value) => $_setInt64(16, value);
  @$pb.TagNumber(17)
  $core.bool hasCreatedTsMs() => $_has(16);
  @$pb.TagNumber(17)
  void clearCreatedTsMs() => $_clearField(17);

  @$pb.TagNumber(18)
  $fixnum.Int64 get updatedTsMs => $_getI64(17);
  @$pb.TagNumber(18)
  set updatedTsMs($fixnum.Int64 value) => $_setInt64(17, value);
  @$pb.TagNumber(18)
  $core.bool hasUpdatedTsMs() => $_has(17);
  @$pb.TagNumber(18)
  void clearUpdatedTsMs() => $_clearField(18);

  @$pb.TagNumber(19)
  $fixnum.Int64 get deletedTsMs => $_getI64(18);
  @$pb.TagNumber(19)
  set deletedTsMs($fixnum.Int64 value) => $_setInt64(18, value);
  @$pb.TagNumber(19)
  $core.bool hasDeletedTsMs() => $_has(18);
  @$pb.TagNumber(19)
  void clearDeletedTsMs() => $_clearField(19);

  @$pb.TagNumber(20)
  $core.String get errorText => $_getSZ(19);
  @$pb.TagNumber(20)
  set errorText($core.String value) => $_setString(19, value);
  @$pb.TagNumber(20)
  $core.bool hasErrorText() => $_has(19);
  @$pb.TagNumber(20)
  void clearErrorText() => $_clearField(20);
}

/// Home inbox (prompt only)
class ReqInboxList extends $pb.GeneratedMessage {
  factory ReqInboxList({
    $core.bool? includeArchived,
    $core.int? limit,
  }) {
    final result = ReqInboxList._();
    if (includeArchived != null) result.includeArchived = includeArchived;
    if (limit != null) result.limit = limit;
    return result;
  }

  ReqInboxList._();

  factory ReqInboxList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqInboxList()..mergeFromBuffer(data, registry);
  factory ReqInboxList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqInboxList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqInboxList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqInboxList.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'includeArchived')
    ..aI(2, _omitFieldNames ? '' : 'limit')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqInboxList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqInboxList copyWith(void Function(ReqInboxList) updates) =>
      super.copyWith((message) => updates(message as ReqInboxList))
          as ReqInboxList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqInboxList() / ReqInboxList.new instead')
  static ReqInboxList create() => ReqInboxList._();
  static $pb.GeneratedMessage $_createMessage() => ReqInboxList._();
  @$core.override
  ReqInboxList createEmptyInstance() => ReqInboxList._();
  @$core.pragma('dart2js:noInline')
  static ReqInboxList getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqInboxList>(
          ReqInboxList.$_createMessage);
  static ReqInboxList? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get includeArchived => $_getBF(0);
  @$pb.TagNumber(1)
  set includeArchived($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIncludeArchived() => $_has(0);
  @$pb.TagNumber(1)
  void clearIncludeArchived() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get limit => $_getIZ(1);
  @$pb.TagNumber(2)
  set limit($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLimit() => $_has(1);
  @$pb.TagNumber(2)
  void clearLimit() => $_clearField(2);
}

class ResInboxList extends $pb.GeneratedMessage {
  factory ResInboxList({
    $core.Iterable<Chat>? chats,
    $core.Iterable<ChatMember>? members,
  }) {
    final result = ResInboxList._();
    if (chats != null) result.chats.addAll(chats);
    if (members != null) result.members.addAll(members);
    return result;
  }

  ResInboxList._();

  factory ResInboxList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResInboxList()..mergeFromBuffer(data, registry);
  factory ResInboxList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResInboxList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResInboxList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResInboxList.$_createMessage)
    ..pPM<Chat>(1, _omitFieldNames ? '' : 'chats',
        subBuilder: Chat.$_createMessage)
    ..pPM<ChatMember>(2, _omitFieldNames ? '' : 'members',
        subBuilder: ChatMember.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResInboxList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResInboxList copyWith(void Function(ResInboxList) updates) =>
      super.copyWith((message) => updates(message as ResInboxList))
          as ResInboxList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResInboxList() / ResInboxList.new instead')
  static ResInboxList create() => ResInboxList._();
  static $pb.GeneratedMessage $_createMessage() => ResInboxList._();
  @$core.override
  ResInboxList createEmptyInstance() => ResInboxList._();
  @$core.pragma('dart2js:noInline')
  static ResInboxList getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResInboxList>(
          ResInboxList.$_createMessage);
  static ResInboxList? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Chat> get chats => $_getList(0);

  @$pb.TagNumber(2)
  $pb.PbList<ChatMember> get members => $_getList(1);
}

class ReqChatMsgList extends $pb.GeneratedMessage {
  factory ReqChatMsgList({
    $fixnum.Int64? chatId,
    $fixnum.Int64? beforeId,
    $core.int? limit,
  }) {
    final result = ReqChatMsgList._();
    if (chatId != null) result.chatId = chatId;
    if (beforeId != null) result.beforeId = beforeId;
    if (limit != null) result.limit = limit;
    return result;
  }

  ReqChatMsgList._();

  factory ReqChatMsgList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqChatMsgList()..mergeFromBuffer(data, registry);
  factory ReqChatMsgList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqChatMsgList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqChatMsgList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqChatMsgList.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'chatId')
    ..aInt64(2, _omitFieldNames ? '' : 'beforeId')
    ..aI(3, _omitFieldNames ? '' : 'limit')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqChatMsgList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqChatMsgList copyWith(void Function(ReqChatMsgList) updates) =>
      super.copyWith((message) => updates(message as ReqChatMsgList))
          as ReqChatMsgList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqChatMsgList() / ReqChatMsgList.new instead')
  static ReqChatMsgList create() => ReqChatMsgList._();
  static $pb.GeneratedMessage $_createMessage() => ReqChatMsgList._();
  @$core.override
  ReqChatMsgList createEmptyInstance() => ReqChatMsgList._();
  @$core.pragma('dart2js:noInline')
  static ReqChatMsgList getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqChatMsgList>(
          ReqChatMsgList.$_createMessage);
  static ReqChatMsgList? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get chatId => $_getI64(0);
  @$pb.TagNumber(1)
  set chatId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasChatId() => $_has(0);
  @$pb.TagNumber(1)
  void clearChatId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get beforeId => $_getI64(1);
  @$pb.TagNumber(2)
  set beforeId($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasBeforeId() => $_has(1);
  @$pb.TagNumber(2)
  void clearBeforeId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get limit => $_getIZ(2);
  @$pb.TagNumber(3)
  set limit($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLimit() => $_has(2);
  @$pb.TagNumber(3)
  void clearLimit() => $_clearField(3);
}

class ResChatMsgList extends $pb.GeneratedMessage {
  factory ResChatMsgList({
    $core.Iterable<ChatMsg>? messages,
  }) {
    final result = ResChatMsgList._();
    if (messages != null) result.messages.addAll(messages);
    return result;
  }

  ResChatMsgList._();

  factory ResChatMsgList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResChatMsgList()..mergeFromBuffer(data, registry);
  factory ResChatMsgList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResChatMsgList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResChatMsgList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResChatMsgList.$_createMessage)
    ..pPM<ChatMsg>(1, _omitFieldNames ? '' : 'messages',
        subBuilder: ChatMsg.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResChatMsgList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResChatMsgList copyWith(void Function(ResChatMsgList) updates) =>
      super.copyWith((message) => updates(message as ResChatMsgList))
          as ResChatMsgList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResChatMsgList() / ResChatMsgList.new instead')
  static ResChatMsgList create() => ResChatMsgList._();
  static $pb.GeneratedMessage $_createMessage() => ResChatMsgList._();
  @$core.override
  ResChatMsgList createEmptyInstance() => ResChatMsgList._();
  @$core.pragma('dart2js:noInline')
  static ResChatMsgList getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResChatMsgList>(
          ResChatMsgList.$_createMessage);
  static ResChatMsgList? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<ChatMsg> get messages => $_getList(0);
}

/// Personal AI prompt stream
class ReqPrompt extends $pb.GeneratedMessage {
  factory ReqPrompt({
    $fixnum.Int64? chatId,
    $core.String? model,
    $core.String? text,
    $core.String? attachmentsJson,
    $core.String? thinking,
    $core.Iterable<$core.String>? mentionIds,
    $core.String? topicId,
    $core.String? toolMode,
    $core.Iterable<$fixnum.Int64>? deviceIids,
  }) {
    final result = ReqPrompt._();
    if (chatId != null) result.chatId = chatId;
    if (model != null) result.model = model;
    if (text != null) result.text = text;
    if (attachmentsJson != null) result.attachmentsJson = attachmentsJson;
    if (thinking != null) result.thinking = thinking;
    if (mentionIds != null) result.mentionIds.addAll(mentionIds);
    if (topicId != null) result.topicId = topicId;
    if (toolMode != null) result.toolMode = toolMode;
    if (deviceIids != null) result.deviceIids.addAll(deviceIids);
    return result;
  }

  ReqPrompt._();

  factory ReqPrompt.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqPrompt()..mergeFromBuffer(data, registry);
  factory ReqPrompt.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqPrompt()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqPrompt',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqPrompt.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'chatId')
    ..aOS(2, _omitFieldNames ? '' : 'model')
    ..aOS(3, _omitFieldNames ? '' : 'text')
    ..aOS(4, _omitFieldNames ? '' : 'attachmentsJson')
    ..aOS(5, _omitFieldNames ? '' : 'thinking')
    ..pPS(6, _omitFieldNames ? '' : 'mentionIds')
    ..aOS(7, _omitFieldNames ? '' : 'topicId')
    ..aOS(8, _omitFieldNames ? '' : 'toolMode')
    ..p<$fixnum.Int64>(
        9, _omitFieldNames ? '' : 'deviceIids', $pb.PbFieldType.K6)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqPrompt clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqPrompt copyWith(void Function(ReqPrompt) updates) =>
      super.copyWith((message) => updates(message as ReqPrompt)) as ReqPrompt;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqPrompt() / ReqPrompt.new instead')
  static ReqPrompt create() => ReqPrompt._();
  static $pb.GeneratedMessage $_createMessage() => ReqPrompt._();
  @$core.override
  ReqPrompt createEmptyInstance() => ReqPrompt._();
  @$core.pragma('dart2js:noInline')
  static ReqPrompt getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqPrompt>(ReqPrompt.$_createMessage);
  static ReqPrompt? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get chatId => $_getI64(0);
  @$pb.TagNumber(1)
  set chatId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasChatId() => $_has(0);
  @$pb.TagNumber(1)
  void clearChatId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get model => $_getSZ(1);
  @$pb.TagNumber(2)
  set model($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasModel() => $_has(1);
  @$pb.TagNumber(2)
  void clearModel() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get text => $_getSZ(2);
  @$pb.TagNumber(3)
  set text($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasText() => $_has(2);
  @$pb.TagNumber(3)
  void clearText() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get attachmentsJson => $_getSZ(3);
  @$pb.TagNumber(4)
  set attachmentsJson($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAttachmentsJson() => $_has(3);
  @$pb.TagNumber(4)
  void clearAttachmentsJson() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get thinking => $_getSZ(4);
  @$pb.TagNumber(5)
  set thinking($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasThinking() => $_has(4);
  @$pb.TagNumber(5)
  void clearThinking() => $_clearField(5);

  @$pb.TagNumber(6)
  $pb.PbList<$core.String> get mentionIds => $_getList(5);

  @$pb.TagNumber(7)
  $core.String get topicId => $_getSZ(6);
  @$pb.TagNumber(7)
  set topicId($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasTopicId() => $_has(6);
  @$pb.TagNumber(7)
  void clearTopicId() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get toolMode => $_getSZ(7);
  @$pb.TagNumber(8)
  set toolMode($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasToolMode() => $_has(7);
  @$pb.TagNumber(8)
  void clearToolMode() => $_clearField(8);

  @$pb.TagNumber(9)
  $pb.PbList<$fixnum.Int64> get deviceIids => $_getList(8);
}

class ResPromptStart extends $pb.GeneratedMessage {
  factory ResPromptStart({
    $fixnum.Int64? chatId,
    $fixnum.Int64? msgId,
    $core.String? model,
  }) {
    final result = ResPromptStart._();
    if (chatId != null) result.chatId = chatId;
    if (msgId != null) result.msgId = msgId;
    if (model != null) result.model = model;
    return result;
  }

  ResPromptStart._();

  factory ResPromptStart.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResPromptStart()..mergeFromBuffer(data, registry);
  factory ResPromptStart.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResPromptStart()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResPromptStart',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResPromptStart.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'chatId')
    ..aInt64(2, _omitFieldNames ? '' : 'msgId')
    ..aOS(3, _omitFieldNames ? '' : 'model')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResPromptStart clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResPromptStart copyWith(void Function(ResPromptStart) updates) =>
      super.copyWith((message) => updates(message as ResPromptStart))
          as ResPromptStart;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResPromptStart() / ResPromptStart.new instead')
  static ResPromptStart create() => ResPromptStart._();
  static $pb.GeneratedMessage $_createMessage() => ResPromptStart._();
  @$core.override
  ResPromptStart createEmptyInstance() => ResPromptStart._();
  @$core.pragma('dart2js:noInline')
  static ResPromptStart getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResPromptStart>(
          ResPromptStart.$_createMessage);
  static ResPromptStart? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get chatId => $_getI64(0);
  @$pb.TagNumber(1)
  set chatId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasChatId() => $_has(0);
  @$pb.TagNumber(1)
  void clearChatId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get msgId => $_getI64(1);
  @$pb.TagNumber(2)
  set msgId($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMsgId() => $_has(1);
  @$pb.TagNumber(2)
  void clearMsgId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get model => $_getSZ(2);
  @$pb.TagNumber(3)
  set model($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasModel() => $_has(2);
  @$pb.TagNumber(3)
  void clearModel() => $_clearField(3);
}

class ResPromptDelta extends $pb.GeneratedMessage {
  factory ResPromptDelta({
    $core.String? text,
    $core.bool? thought,
    $core.String? blocksJson,
  }) {
    final result = ResPromptDelta._();
    if (text != null) result.text = text;
    if (thought != null) result.thought = thought;
    if (blocksJson != null) result.blocksJson = blocksJson;
    return result;
  }

  ResPromptDelta._();

  factory ResPromptDelta.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResPromptDelta()..mergeFromBuffer(data, registry);
  factory ResPromptDelta.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResPromptDelta()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResPromptDelta',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResPromptDelta.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'text')
    ..aOB(2, _omitFieldNames ? '' : 'thought')
    ..aOS(3, _omitFieldNames ? '' : 'blocksJson')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResPromptDelta clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResPromptDelta copyWith(void Function(ResPromptDelta) updates) =>
      super.copyWith((message) => updates(message as ResPromptDelta))
          as ResPromptDelta;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResPromptDelta() / ResPromptDelta.new instead')
  static ResPromptDelta create() => ResPromptDelta._();
  static $pb.GeneratedMessage $_createMessage() => ResPromptDelta._();
  @$core.override
  ResPromptDelta createEmptyInstance() => ResPromptDelta._();
  @$core.pragma('dart2js:noInline')
  static ResPromptDelta getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResPromptDelta>(
          ResPromptDelta.$_createMessage);
  static ResPromptDelta? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get text => $_getSZ(0);
  @$pb.TagNumber(1)
  set text($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasText() => $_has(0);
  @$pb.TagNumber(1)
  void clearText() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get thought => $_getBF(1);
  @$pb.TagNumber(2)
  set thought($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasThought() => $_has(1);
  @$pb.TagNumber(2)
  void clearThought() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get blocksJson => $_getSZ(2);
  @$pb.TagNumber(3)
  set blocksJson($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasBlocksJson() => $_has(2);
  @$pb.TagNumber(3)
  void clearBlocksJson() => $_clearField(3);
}

class ResPromptEnd extends $pb.GeneratedMessage {
  factory ResPromptEnd({
    $fixnum.Int64? msgId,
    $core.int? tokensIn,
    $core.int? tokensOut,
    $core.double? costUsd,
    $core.int? durationMs,
    $core.String? model,
    $core.String? reqId,
    $core.String? traceJson,
    $core.String? errorMessage,
  }) {
    final result = ResPromptEnd._();
    if (msgId != null) result.msgId = msgId;
    if (tokensIn != null) result.tokensIn = tokensIn;
    if (tokensOut != null) result.tokensOut = tokensOut;
    if (costUsd != null) result.costUsd = costUsd;
    if (durationMs != null) result.durationMs = durationMs;
    if (model != null) result.model = model;
    if (reqId != null) result.reqId = reqId;
    if (traceJson != null) result.traceJson = traceJson;
    if (errorMessage != null) result.errorMessage = errorMessage;
    return result;
  }

  ResPromptEnd._();

  factory ResPromptEnd.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResPromptEnd()..mergeFromBuffer(data, registry);
  factory ResPromptEnd.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResPromptEnd()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResPromptEnd',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResPromptEnd.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'msgId')
    ..aI(2, _omitFieldNames ? '' : 'tokensIn')
    ..aI(3, _omitFieldNames ? '' : 'tokensOut')
    ..aD(4, _omitFieldNames ? '' : 'costUsd')
    ..aI(5, _omitFieldNames ? '' : 'durationMs')
    ..aOS(6, _omitFieldNames ? '' : 'model')
    ..aOS(7, _omitFieldNames ? '' : 'reqId')
    ..aOS(8, _omitFieldNames ? '' : 'traceJson')
    ..aOS(9, _omitFieldNames ? '' : 'errorMessage')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResPromptEnd clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResPromptEnd copyWith(void Function(ResPromptEnd) updates) =>
      super.copyWith((message) => updates(message as ResPromptEnd))
          as ResPromptEnd;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResPromptEnd() / ResPromptEnd.new instead')
  static ResPromptEnd create() => ResPromptEnd._();
  static $pb.GeneratedMessage $_createMessage() => ResPromptEnd._();
  @$core.override
  ResPromptEnd createEmptyInstance() => ResPromptEnd._();
  @$core.pragma('dart2js:noInline')
  static ResPromptEnd getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResPromptEnd>(
          ResPromptEnd.$_createMessage);
  static ResPromptEnd? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get msgId => $_getI64(0);
  @$pb.TagNumber(1)
  set msgId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMsgId() => $_has(0);
  @$pb.TagNumber(1)
  void clearMsgId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get tokensIn => $_getIZ(1);
  @$pb.TagNumber(2)
  set tokensIn($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTokensIn() => $_has(1);
  @$pb.TagNumber(2)
  void clearTokensIn() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get tokensOut => $_getIZ(2);
  @$pb.TagNumber(3)
  set tokensOut($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTokensOut() => $_has(2);
  @$pb.TagNumber(3)
  void clearTokensOut() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get costUsd => $_getN(3);
  @$pb.TagNumber(4)
  set costUsd($core.double value) => $_setDouble(3, value);
  @$pb.TagNumber(4)
  $core.bool hasCostUsd() => $_has(3);
  @$pb.TagNumber(4)
  void clearCostUsd() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get durationMs => $_getIZ(4);
  @$pb.TagNumber(5)
  set durationMs($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasDurationMs() => $_has(4);
  @$pb.TagNumber(5)
  void clearDurationMs() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get model => $_getSZ(5);
  @$pb.TagNumber(6)
  set model($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasModel() => $_has(5);
  @$pb.TagNumber(6)
  void clearModel() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get reqId => $_getSZ(6);
  @$pb.TagNumber(7)
  set reqId($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasReqId() => $_has(6);
  @$pb.TagNumber(7)
  void clearReqId() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get traceJson => $_getSZ(7);
  @$pb.TagNumber(8)
  set traceJson($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasTraceJson() => $_has(7);
  @$pb.TagNumber(8)
  void clearTraceJson() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get errorMessage => $_getSZ(8);
  @$pb.TagNumber(9)
  set errorMessage($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasErrorMessage() => $_has(8);
  @$pb.TagNumber(9)
  void clearErrorMessage() => $_clearField(9);
}

class ResPromptFail extends $pb.GeneratedMessage {
  factory ResPromptFail({
    $core.String? message,
  }) {
    final result = ResPromptFail._();
    if (message != null) result.message = message;
    return result;
  }

  ResPromptFail._();

  factory ResPromptFail.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResPromptFail()..mergeFromBuffer(data, registry);
  factory ResPromptFail.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResPromptFail()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResPromptFail',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResPromptFail.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResPromptFail clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResPromptFail copyWith(void Function(ResPromptFail) updates) =>
      super.copyWith((message) => updates(message as ResPromptFail))
          as ResPromptFail;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResPromptFail() / ResPromptFail.new instead')
  static ResPromptFail create() => ResPromptFail._();
  static $pb.GeneratedMessage $_createMessage() => ResPromptFail._();
  @$core.override
  ResPromptFail createEmptyInstance() => ResPromptFail._();
  @$core.pragma('dart2js:noInline')
  static ResPromptFail getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResPromptFail>(
          ResPromptFail.$_createMessage);
  static ResPromptFail? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get message => $_getSZ(0);
  @$pb.TagNumber(1)
  set message($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);
}

class ReqPromptAbort extends $pb.GeneratedMessage {
  factory ReqPromptAbort({
    $fixnum.Int64? chatId,
    $core.String? reqId,
  }) {
    final result = ReqPromptAbort._();
    if (chatId != null) result.chatId = chatId;
    if (reqId != null) result.reqId = reqId;
    return result;
  }

  ReqPromptAbort._();

  factory ReqPromptAbort.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqPromptAbort()..mergeFromBuffer(data, registry);
  factory ReqPromptAbort.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqPromptAbort()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqPromptAbort',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqPromptAbort.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'chatId')
    ..aOS(2, _omitFieldNames ? '' : 'reqId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqPromptAbort clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqPromptAbort copyWith(void Function(ReqPromptAbort) updates) =>
      super.copyWith((message) => updates(message as ReqPromptAbort))
          as ReqPromptAbort;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqPromptAbort() / ReqPromptAbort.new instead')
  static ReqPromptAbort create() => ReqPromptAbort._();
  static $pb.GeneratedMessage $_createMessage() => ReqPromptAbort._();
  @$core.override
  ReqPromptAbort createEmptyInstance() => ReqPromptAbort._();
  @$core.pragma('dart2js:noInline')
  static ReqPromptAbort getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqPromptAbort>(
          ReqPromptAbort.$_createMessage);
  static ReqPromptAbort? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get chatId => $_getI64(0);
  @$pb.TagNumber(1)
  set chatId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasChatId() => $_has(0);
  @$pb.TagNumber(1)
  void clearChatId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get reqId => $_getSZ(1);
  @$pb.TagNumber(2)
  set reqId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasReqId() => $_has(1);
  @$pb.TagNumber(2)
  void clearReqId() => $_clearField(2);
}

class PromptRunPush extends $pb.GeneratedMessage {
  factory PromptRunPush({
    $core.String? reqId,
    $core.String? parentReqId,
    $core.String? kind,
    $fixnum.Int64? deviceIid,
    $core.String? status,
    $core.String? label,
    $core.String? topicId,
    $core.int? turnCount,
    $core.int? tokensIn,
    $core.int? tokensOut,
    $core.double? costUsd,
    $core.int? durationMs,
    $core.String? failClass,
    $core.String? failReason,
  }) {
    final result = PromptRunPush._();
    if (reqId != null) result.reqId = reqId;
    if (parentReqId != null) result.parentReqId = parentReqId;
    if (kind != null) result.kind = kind;
    if (deviceIid != null) result.deviceIid = deviceIid;
    if (status != null) result.status = status;
    if (label != null) result.label = label;
    if (topicId != null) result.topicId = topicId;
    if (turnCount != null) result.turnCount = turnCount;
    if (tokensIn != null) result.tokensIn = tokensIn;
    if (tokensOut != null) result.tokensOut = tokensOut;
    if (costUsd != null) result.costUsd = costUsd;
    if (durationMs != null) result.durationMs = durationMs;
    if (failClass != null) result.failClass = failClass;
    if (failReason != null) result.failReason = failReason;
    return result;
  }

  PromptRunPush._();

  factory PromptRunPush.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PromptRunPush()..mergeFromBuffer(data, registry);
  factory PromptRunPush.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PromptRunPush()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PromptRunPush',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: PromptRunPush.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'reqId')
    ..aOS(2, _omitFieldNames ? '' : 'parentReqId')
    ..aOS(3, _omitFieldNames ? '' : 'kind')
    ..aInt64(4, _omitFieldNames ? '' : 'deviceIid')
    ..aOS(5, _omitFieldNames ? '' : 'status')
    ..aOS(6, _omitFieldNames ? '' : 'label')
    ..aOS(7, _omitFieldNames ? '' : 'topicId')
    ..aI(8, _omitFieldNames ? '' : 'turnCount')
    ..aI(9, _omitFieldNames ? '' : 'tokensIn')
    ..aI(10, _omitFieldNames ? '' : 'tokensOut')
    ..aD(11, _omitFieldNames ? '' : 'costUsd')
    ..aI(12, _omitFieldNames ? '' : 'durationMs')
    ..aOS(13, _omitFieldNames ? '' : 'failClass')
    ..aOS(14, _omitFieldNames ? '' : 'failReason')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PromptRunPush clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PromptRunPush copyWith(void Function(PromptRunPush) updates) =>
      super.copyWith((message) => updates(message as PromptRunPush))
          as PromptRunPush;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PromptRunPush() / PromptRunPush.new instead')
  static PromptRunPush create() => PromptRunPush._();
  static $pb.GeneratedMessage $_createMessage() => PromptRunPush._();
  @$core.override
  PromptRunPush createEmptyInstance() => PromptRunPush._();
  @$core.pragma('dart2js:noInline')
  static PromptRunPush getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PromptRunPush>(
          PromptRunPush.$_createMessage);
  static PromptRunPush? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get reqId => $_getSZ(0);
  @$pb.TagNumber(1)
  set reqId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasReqId() => $_has(0);
  @$pb.TagNumber(1)
  void clearReqId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get parentReqId => $_getSZ(1);
  @$pb.TagNumber(2)
  set parentReqId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasParentReqId() => $_has(1);
  @$pb.TagNumber(2)
  void clearParentReqId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get kind => $_getSZ(2);
  @$pb.TagNumber(3)
  set kind($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasKind() => $_has(2);
  @$pb.TagNumber(3)
  void clearKind() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get deviceIid => $_getI64(3);
  @$pb.TagNumber(4)
  set deviceIid($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDeviceIid() => $_has(3);
  @$pb.TagNumber(4)
  void clearDeviceIid() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get status => $_getSZ(4);
  @$pb.TagNumber(5)
  set status($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasStatus() => $_has(4);
  @$pb.TagNumber(5)
  void clearStatus() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get label => $_getSZ(5);
  @$pb.TagNumber(6)
  set label($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasLabel() => $_has(5);
  @$pb.TagNumber(6)
  void clearLabel() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get topicId => $_getSZ(6);
  @$pb.TagNumber(7)
  set topicId($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasTopicId() => $_has(6);
  @$pb.TagNumber(7)
  void clearTopicId() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.int get turnCount => $_getIZ(7);
  @$pb.TagNumber(8)
  set turnCount($core.int value) => $_setSignedInt32(7, value);
  @$pb.TagNumber(8)
  $core.bool hasTurnCount() => $_has(7);
  @$pb.TagNumber(8)
  void clearTurnCount() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.int get tokensIn => $_getIZ(8);
  @$pb.TagNumber(9)
  set tokensIn($core.int value) => $_setSignedInt32(8, value);
  @$pb.TagNumber(9)
  $core.bool hasTokensIn() => $_has(8);
  @$pb.TagNumber(9)
  void clearTokensIn() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.int get tokensOut => $_getIZ(9);
  @$pb.TagNumber(10)
  set tokensOut($core.int value) => $_setSignedInt32(9, value);
  @$pb.TagNumber(10)
  $core.bool hasTokensOut() => $_has(9);
  @$pb.TagNumber(10)
  void clearTokensOut() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.double get costUsd => $_getN(10);
  @$pb.TagNumber(11)
  set costUsd($core.double value) => $_setDouble(10, value);
  @$pb.TagNumber(11)
  $core.bool hasCostUsd() => $_has(10);
  @$pb.TagNumber(11)
  void clearCostUsd() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.int get durationMs => $_getIZ(11);
  @$pb.TagNumber(12)
  set durationMs($core.int value) => $_setSignedInt32(11, value);
  @$pb.TagNumber(12)
  $core.bool hasDurationMs() => $_has(11);
  @$pb.TagNumber(12)
  void clearDurationMs() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.String get failClass => $_getSZ(12);
  @$pb.TagNumber(13)
  set failClass($core.String value) => $_setString(12, value);
  @$pb.TagNumber(13)
  $core.bool hasFailClass() => $_has(12);
  @$pb.TagNumber(13)
  void clearFailClass() => $_clearField(13);

  @$pb.TagNumber(14)
  $core.String get failReason => $_getSZ(13);
  @$pb.TagNumber(14)
  set failReason($core.String value) => $_setString(13, value);
  @$pb.TagNumber(14)
  $core.bool hasFailReason() => $_has(13);
  @$pb.TagNumber(14)
  void clearFailReason() => $_clearField(14);
}

class PromptRunJob extends $pb.GeneratedMessage {
  factory PromptRunJob({
    $core.String? reqId,
    $fixnum.Int64? ownerIid,
    $fixnum.Int64? chatId,
  }) {
    final result = PromptRunJob._();
    if (reqId != null) result.reqId = reqId;
    if (ownerIid != null) result.ownerIid = ownerIid;
    if (chatId != null) result.chatId = chatId;
    return result;
  }

  PromptRunJob._();

  factory PromptRunJob.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PromptRunJob()..mergeFromBuffer(data, registry);
  factory PromptRunJob.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PromptRunJob()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PromptRunJob',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: PromptRunJob.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'reqId')
    ..aInt64(2, _omitFieldNames ? '' : 'ownerIid')
    ..aInt64(3, _omitFieldNames ? '' : 'chatId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PromptRunJob clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PromptRunJob copyWith(void Function(PromptRunJob) updates) =>
      super.copyWith((message) => updates(message as PromptRunJob))
          as PromptRunJob;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PromptRunJob() / PromptRunJob.new instead')
  static PromptRunJob create() => PromptRunJob._();
  static $pb.GeneratedMessage $_createMessage() => PromptRunJob._();
  @$core.override
  PromptRunJob createEmptyInstance() => PromptRunJob._();
  @$core.pragma('dart2js:noInline')
  static PromptRunJob getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PromptRunJob>(
          PromptRunJob.$_createMessage);
  static PromptRunJob? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get reqId => $_getSZ(0);
  @$pb.TagNumber(1)
  set reqId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasReqId() => $_has(0);
  @$pb.TagNumber(1)
  void clearReqId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get ownerIid => $_getI64(1);
  @$pb.TagNumber(2)
  set ownerIid($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOwnerIid() => $_has(1);
  @$pb.TagNumber(2)
  void clearOwnerIid() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get chatId => $_getI64(2);
  @$pb.TagNumber(3)
  set chatId($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasChatId() => $_has(2);
  @$pb.TagNumber(3)
  void clearChatId() => $_clearField(3);
}

/// bot_peer: stop AI for ONE conversation (not bot / channel)
class ReqChatStop extends $pb.GeneratedMessage {
  factory ReqChatStop({
    $fixnum.Int64? chatId,
    $core.bool? stopped,
  }) {
    final result = ReqChatStop._();
    if (chatId != null) result.chatId = chatId;
    if (stopped != null) result.stopped = stopped;
    return result;
  }

  ReqChatStop._();

  factory ReqChatStop.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqChatStop()..mergeFromBuffer(data, registry);
  factory ReqChatStop.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqChatStop()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqChatStop',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqChatStop.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'chatId')
    ..aOB(2, _omitFieldNames ? '' : 'stopped')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqChatStop clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqChatStop copyWith(void Function(ReqChatStop) updates) =>
      super.copyWith((message) => updates(message as ReqChatStop))
          as ReqChatStop;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqChatStop() / ReqChatStop.new instead')
  static ReqChatStop create() => ReqChatStop._();
  static $pb.GeneratedMessage $_createMessage() => ReqChatStop._();
  @$core.override
  ReqChatStop createEmptyInstance() => ReqChatStop._();
  @$core.pragma('dart2js:noInline')
  static ReqChatStop getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqChatStop>(
          ReqChatStop.$_createMessage);
  static ReqChatStop? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get chatId => $_getI64(0);
  @$pb.TagNumber(1)
  set chatId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasChatId() => $_has(0);
  @$pb.TagNumber(1)
  void clearChatId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get stopped => $_getBF(1);
  @$pb.TagNumber(2)
  set stopped($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasStopped() => $_has(1);
  @$pb.TagNumber(2)
  void clearStopped() => $_clearField(2);
}

class ResChatStop extends $pb.GeneratedMessage {
  factory ResChatStop({
    $fixnum.Int64? chatId,
    $core.bool? aiReplyEnabled,
  }) {
    final result = ResChatStop._();
    if (chatId != null) result.chatId = chatId;
    if (aiReplyEnabled != null) result.aiReplyEnabled = aiReplyEnabled;
    return result;
  }

  ResChatStop._();

  factory ResChatStop.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResChatStop()..mergeFromBuffer(data, registry);
  factory ResChatStop.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResChatStop()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResChatStop',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResChatStop.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'chatId')
    ..aOB(2, _omitFieldNames ? '' : 'aiReplyEnabled')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResChatStop clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResChatStop copyWith(void Function(ResChatStop) updates) =>
      super.copyWith((message) => updates(message as ResChatStop))
          as ResChatStop;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResChatStop() / ResChatStop.new instead')
  static ResChatStop create() => ResChatStop._();
  static $pb.GeneratedMessage $_createMessage() => ResChatStop._();
  @$core.override
  ResChatStop createEmptyInstance() => ResChatStop._();
  @$core.pragma('dart2js:noInline')
  static ResChatStop getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResChatStop>(
          ResChatStop.$_createMessage);
  static ResChatStop? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get chatId => $_getI64(0);
  @$pb.TagNumber(1)
  set chatId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasChatId() => $_has(0);
  @$pb.TagNumber(1)
  void clearChatId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get aiReplyEnabled => $_getBF(1);
  @$pb.TagNumber(2)
  set aiReplyEnabled($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAiReplyEnabled() => $_has(1);
  @$pb.TagNumber(2)
  void clearAiReplyEnabled() => $_clearField(2);
}

/// bot_peer: staff manual send
class ReqChatSend extends $pb.GeneratedMessage {
  factory ReqChatSend({
    $fixnum.Int64? chatId,
    $core.String? text,
    $core.String? attachmentsJson,
  }) {
    final result = ReqChatSend._();
    if (chatId != null) result.chatId = chatId;
    if (text != null) result.text = text;
    if (attachmentsJson != null) result.attachmentsJson = attachmentsJson;
    return result;
  }

  ReqChatSend._();

  factory ReqChatSend.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqChatSend()..mergeFromBuffer(data, registry);
  factory ReqChatSend.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqChatSend()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqChatSend',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqChatSend.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'chatId')
    ..aOS(2, _omitFieldNames ? '' : 'text')
    ..aOS(3, _omitFieldNames ? '' : 'attachmentsJson')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqChatSend clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqChatSend copyWith(void Function(ReqChatSend) updates) =>
      super.copyWith((message) => updates(message as ReqChatSend))
          as ReqChatSend;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqChatSend() / ReqChatSend.new instead')
  static ReqChatSend create() => ReqChatSend._();
  static $pb.GeneratedMessage $_createMessage() => ReqChatSend._();
  @$core.override
  ReqChatSend createEmptyInstance() => ReqChatSend._();
  @$core.pragma('dart2js:noInline')
  static ReqChatSend getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqChatSend>(
          ReqChatSend.$_createMessage);
  static ReqChatSend? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get chatId => $_getI64(0);
  @$pb.TagNumber(1)
  set chatId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasChatId() => $_has(0);
  @$pb.TagNumber(1)
  void clearChatId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get text => $_getSZ(1);
  @$pb.TagNumber(2)
  set text($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasText() => $_has(1);
  @$pb.TagNumber(2)
  void clearText() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get attachmentsJson => $_getSZ(2);
  @$pb.TagNumber(3)
  set attachmentsJson($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAttachmentsJson() => $_has(2);
  @$pb.TagNumber(3)
  void clearAttachmentsJson() => $_clearField(3);
}

class ResChatSend extends $pb.GeneratedMessage {
  factory ResChatSend({
    ChatMsg? message,
  }) {
    final result = ResChatSend._();
    if (message != null) result.message = message;
    return result;
  }

  ResChatSend._();

  factory ResChatSend.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResChatSend()..mergeFromBuffer(data, registry);
  factory ResChatSend.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResChatSend()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResChatSend',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResChatSend.$_createMessage)
    ..aOM<ChatMsg>(1, _omitFieldNames ? '' : 'message',
        subBuilder: ChatMsg.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResChatSend clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResChatSend copyWith(void Function(ResChatSend) updates) =>
      super.copyWith((message) => updates(message as ResChatSend))
          as ResChatSend;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResChatSend() / ResChatSend.new instead')
  static ResChatSend create() => ResChatSend._();
  static $pb.GeneratedMessage $_createMessage() => ResChatSend._();
  @$core.override
  ResChatSend createEmptyInstance() => ResChatSend._();
  @$core.pragma('dart2js:noInline')
  static ResChatSend getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResChatSend>(
          ResChatSend.$_createMessage);
  static ResChatSend? _defaultInstance;

  @$pb.TagNumber(1)
  ChatMsg get message => $_getN(0);
  @$pb.TagNumber(1)
  set message(ChatMsg value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);
  @$pb.TagNumber(1)
  ChatMsg ensureMessage() => $_ensure(0);
}

/// Home prompt chat: pin, archive, tags, soft-delete (per-user member row + chat metadata)
class TagSet extends $pb.GeneratedMessage {
  factory TagSet({
    $core.Iterable<$core.String>? tags,
  }) {
    final result = TagSet._();
    if (tags != null) result.tags.addAll(tags);
    return result;
  }

  TagSet._();

  factory TagSet.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TagSet()..mergeFromBuffer(data, registry);
  factory TagSet.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TagSet()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TagSet',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: TagSet.$_createMessage)
    ..pPS(1, _omitFieldNames ? '' : 'tags')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TagSet clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TagSet copyWith(void Function(TagSet) updates) =>
      super.copyWith((message) => updates(message as TagSet)) as TagSet;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use TagSet() / TagSet.new instead')
  static TagSet create() => TagSet._();
  static $pb.GeneratedMessage $_createMessage() => TagSet._();
  @$core.override
  TagSet createEmptyInstance() => TagSet._();
  @$core.pragma('dart2js:noInline')
  static TagSet getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TagSet>(TagSet.$_createMessage);
  static TagSet? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get tags => $_getList(0);
}

class ReqChatPatch extends $pb.GeneratedMessage {
  factory ReqChatPatch({
    $fixnum.Int64? chatId,
    $core.bool? pinned,
    $core.bool? archived,
    TagSet? tags,
    $core.bool? deleted,
  }) {
    final result = ReqChatPatch._();
    if (chatId != null) result.chatId = chatId;
    if (pinned != null) result.pinned = pinned;
    if (archived != null) result.archived = archived;
    if (tags != null) result.tags = tags;
    if (deleted != null) result.deleted = deleted;
    return result;
  }

  ReqChatPatch._();

  factory ReqChatPatch.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqChatPatch()..mergeFromBuffer(data, registry);
  factory ReqChatPatch.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqChatPatch()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqChatPatch',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqChatPatch.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'chatId')
    ..aOB(2, _omitFieldNames ? '' : 'pinned')
    ..aOB(3, _omitFieldNames ? '' : 'archived')
    ..aOM<TagSet>(4, _omitFieldNames ? '' : 'tags',
        subBuilder: TagSet.$_createMessage)
    ..aOB(5, _omitFieldNames ? '' : 'deleted')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqChatPatch clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqChatPatch copyWith(void Function(ReqChatPatch) updates) =>
      super.copyWith((message) => updates(message as ReqChatPatch))
          as ReqChatPatch;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqChatPatch() / ReqChatPatch.new instead')
  static ReqChatPatch create() => ReqChatPatch._();
  static $pb.GeneratedMessage $_createMessage() => ReqChatPatch._();
  @$core.override
  ReqChatPatch createEmptyInstance() => ReqChatPatch._();
  @$core.pragma('dart2js:noInline')
  static ReqChatPatch getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqChatPatch>(
          ReqChatPatch.$_createMessage);
  static ReqChatPatch? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get chatId => $_getI64(0);
  @$pb.TagNumber(1)
  set chatId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasChatId() => $_has(0);
  @$pb.TagNumber(1)
  void clearChatId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get pinned => $_getBF(1);
  @$pb.TagNumber(2)
  set pinned($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPinned() => $_has(1);
  @$pb.TagNumber(2)
  void clearPinned() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get archived => $_getBF(2);
  @$pb.TagNumber(3)
  set archived($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasArchived() => $_has(2);
  @$pb.TagNumber(3)
  void clearArchived() => $_clearField(3);

  @$pb.TagNumber(4)
  TagSet get tags => $_getN(3);
  @$pb.TagNumber(4)
  set tags(TagSet value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasTags() => $_has(3);
  @$pb.TagNumber(4)
  void clearTags() => $_clearField(4);
  @$pb.TagNumber(4)
  TagSet ensureTags() => $_ensure(3);

  @$pb.TagNumber(5)
  $core.bool get deleted => $_getBF(4);
  @$pb.TagNumber(5)
  set deleted($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasDeleted() => $_has(4);
  @$pb.TagNumber(5)
  void clearDeleted() => $_clearField(5);
}

class ResChatPatch extends $pb.GeneratedMessage {
  factory ResChatPatch({
    Chat? chat,
    ChatMember? member,
  }) {
    final result = ResChatPatch._();
    if (chat != null) result.chat = chat;
    if (member != null) result.member = member;
    return result;
  }

  ResChatPatch._();

  factory ResChatPatch.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResChatPatch()..mergeFromBuffer(data, registry);
  factory ResChatPatch.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResChatPatch()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResChatPatch',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResChatPatch.$_createMessage)
    ..aOM<Chat>(1, _omitFieldNames ? '' : 'chat',
        subBuilder: Chat.$_createMessage)
    ..aOM<ChatMember>(2, _omitFieldNames ? '' : 'member',
        subBuilder: ChatMember.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResChatPatch clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResChatPatch copyWith(void Function(ResChatPatch) updates) =>
      super.copyWith((message) => updates(message as ResChatPatch))
          as ResChatPatch;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResChatPatch() / ResChatPatch.new instead')
  static ResChatPatch create() => ResChatPatch._();
  static $pb.GeneratedMessage $_createMessage() => ResChatPatch._();
  @$core.override
  ResChatPatch createEmptyInstance() => ResChatPatch._();
  @$core.pragma('dart2js:noInline')
  static ResChatPatch getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResChatPatch>(
          ResChatPatch.$_createMessage);
  static ResChatPatch? _defaultInstance;

  @$pb.TagNumber(1)
  Chat get chat => $_getN(0);
  @$pb.TagNumber(1)
  set chat(Chat value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasChat() => $_has(0);
  @$pb.TagNumber(1)
  void clearChat() => $_clearField(1);
  @$pb.TagNumber(1)
  Chat ensureChat() => $_ensure(0);

  @$pb.TagNumber(2)
  ChatMember get member => $_getN(1);
  @$pb.TagNumber(2)
  set member(ChatMember value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasMember() => $_has(1);
  @$pb.TagNumber(2)
  void clearMember() => $_clearField(2);
  @$pb.TagNumber(2)
  ChatMember ensureMember() => $_ensure(1);
}

/// Home prompt: clear all chat messages for caller (dry_run returns counts only)
class ReqChatHistoryClear extends $pb.GeneratedMessage {
  factory ReqChatHistoryClear({
    $core.bool? dryRun,
  }) {
    final result = ReqChatHistoryClear._();
    if (dryRun != null) result.dryRun = dryRun;
    return result;
  }

  ReqChatHistoryClear._();

  factory ReqChatHistoryClear.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqChatHistoryClear()..mergeFromBuffer(data, registry);
  factory ReqChatHistoryClear.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqChatHistoryClear()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqChatHistoryClear',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqChatHistoryClear.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'dryRun')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqChatHistoryClear clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqChatHistoryClear copyWith(void Function(ReqChatHistoryClear) updates) =>
      super.copyWith((message) => updates(message as ReqChatHistoryClear))
          as ReqChatHistoryClear;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use ReqChatHistoryClear() / ReqChatHistoryClear.new instead')
  static ReqChatHistoryClear create() => ReqChatHistoryClear._();
  static $pb.GeneratedMessage $_createMessage() => ReqChatHistoryClear._();
  @$core.override
  ReqChatHistoryClear createEmptyInstance() => ReqChatHistoryClear._();
  @$core.pragma('dart2js:noInline')
  static ReqChatHistoryClear getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqChatHistoryClear>(
          ReqChatHistoryClear.$_createMessage);
  static ReqChatHistoryClear? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get dryRun => $_getBF(0);
  @$pb.TagNumber(1)
  set dryRun($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDryRun() => $_has(0);
  @$pb.TagNumber(1)
  void clearDryRun() => $_clearField(1);
}

class ResChatHistoryClear extends $pb.GeneratedMessage {
  factory ResChatHistoryClear({
    $core.int? msgsDeleted,
    $core.int? chatsAffected,
  }) {
    final result = ResChatHistoryClear._();
    if (msgsDeleted != null) result.msgsDeleted = msgsDeleted;
    if (chatsAffected != null) result.chatsAffected = chatsAffected;
    return result;
  }

  ResChatHistoryClear._();

  factory ResChatHistoryClear.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResChatHistoryClear()..mergeFromBuffer(data, registry);
  factory ResChatHistoryClear.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResChatHistoryClear()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResChatHistoryClear',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResChatHistoryClear.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'msgsDeleted')
    ..aI(2, _omitFieldNames ? '' : 'chatsAffected')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResChatHistoryClear clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResChatHistoryClear copyWith(void Function(ResChatHistoryClear) updates) =>
      super.copyWith((message) => updates(message as ResChatHistoryClear))
          as ResChatHistoryClear;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use ResChatHistoryClear() / ResChatHistoryClear.new instead')
  static ResChatHistoryClear create() => ResChatHistoryClear._();
  static $pb.GeneratedMessage $_createMessage() => ResChatHistoryClear._();
  @$core.override
  ResChatHistoryClear createEmptyInstance() => ResChatHistoryClear._();
  @$core.pragma('dart2js:noInline')
  static ResChatHistoryClear getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResChatHistoryClear>(
          ResChatHistoryClear.$_createMessage);
  static ResChatHistoryClear? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get msgsDeleted => $_getIZ(0);
  @$pb.TagNumber(1)
  set msgsDeleted($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMsgsDeleted() => $_has(0);
  @$pb.TagNumber(1)
  void clearMsgsDeleted() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get chatsAffected => $_getIZ(1);
  @$pb.TagNumber(2)
  set chatsAffected($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasChatsAffected() => $_has(1);
  @$pb.TagNumber(2)
  void clearChatsAffected() => $_clearField(2);
}

class AssetTagHint extends $pb.GeneratedMessage {
  factory AssetTagHint({
    $core.String? tag,
    $core.int? count,
  }) {
    final result = AssetTagHint._();
    if (tag != null) result.tag = tag;
    if (count != null) result.count = count;
    return result;
  }

  AssetTagHint._();

  factory AssetTagHint.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AssetTagHint()..mergeFromBuffer(data, registry);
  factory AssetTagHint.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AssetTagHint()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AssetTagHint',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: AssetTagHint.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'tag')
    ..aI(2, _omitFieldNames ? '' : 'count')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AssetTagHint clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AssetTagHint copyWith(void Function(AssetTagHint) updates) =>
      super.copyWith((message) => updates(message as AssetTagHint))
          as AssetTagHint;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use AssetTagHint() / AssetTagHint.new instead')
  static AssetTagHint create() => AssetTagHint._();
  static $pb.GeneratedMessage $_createMessage() => AssetTagHint._();
  @$core.override
  AssetTagHint createEmptyInstance() => AssetTagHint._();
  @$core.pragma('dart2js:noInline')
  static AssetTagHint getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AssetTagHint>(
          AssetTagHint.$_createMessage);
  static AssetTagHint? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get tag => $_getSZ(0);
  @$pb.TagNumber(1)
  set tag($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTag() => $_has(0);
  @$pb.TagNumber(1)
  void clearTag() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get count => $_getIZ(1);
  @$pb.TagNumber(2)
  set count($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCount() => $_has(1);
  @$pb.TagNumber(2)
  void clearCount() => $_clearField(2);
}

class ReqAssetTagList extends $pb.GeneratedMessage {
  factory ReqAssetTagList({
    $core.String? kind,
    $core.String? prefix,
    $core.int? limit,
  }) {
    final result = ReqAssetTagList._();
    if (kind != null) result.kind = kind;
    if (prefix != null) result.prefix = prefix;
    if (limit != null) result.limit = limit;
    return result;
  }

  ReqAssetTagList._();

  factory ReqAssetTagList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqAssetTagList()..mergeFromBuffer(data, registry);
  factory ReqAssetTagList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqAssetTagList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqAssetTagList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqAssetTagList.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'kind')
    ..aOS(2, _omitFieldNames ? '' : 'prefix')
    ..aI(3, _omitFieldNames ? '' : 'limit')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqAssetTagList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqAssetTagList copyWith(void Function(ReqAssetTagList) updates) =>
      super.copyWith((message) => updates(message as ReqAssetTagList))
          as ReqAssetTagList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqAssetTagList() / ReqAssetTagList.new instead')
  static ReqAssetTagList create() => ReqAssetTagList._();
  static $pb.GeneratedMessage $_createMessage() => ReqAssetTagList._();
  @$core.override
  ReqAssetTagList createEmptyInstance() => ReqAssetTagList._();
  @$core.pragma('dart2js:noInline')
  static ReqAssetTagList getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqAssetTagList>(
          ReqAssetTagList.$_createMessage);
  static ReqAssetTagList? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get kind => $_getSZ(0);
  @$pb.TagNumber(1)
  set kind($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasKind() => $_has(0);
  @$pb.TagNumber(1)
  void clearKind() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get prefix => $_getSZ(1);
  @$pb.TagNumber(2)
  set prefix($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPrefix() => $_has(1);
  @$pb.TagNumber(2)
  void clearPrefix() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get limit => $_getIZ(2);
  @$pb.TagNumber(3)
  set limit($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLimit() => $_has(2);
  @$pb.TagNumber(3)
  void clearLimit() => $_clearField(3);
}

class ResAssetTagList extends $pb.GeneratedMessage {
  factory ResAssetTagList({
    $core.Iterable<AssetTagHint>? hints,
  }) {
    final result = ResAssetTagList._();
    if (hints != null) result.hints.addAll(hints);
    return result;
  }

  ResAssetTagList._();

  factory ResAssetTagList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResAssetTagList()..mergeFromBuffer(data, registry);
  factory ResAssetTagList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResAssetTagList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResAssetTagList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResAssetTagList.$_createMessage)
    ..pPM<AssetTagHint>(1, _omitFieldNames ? '' : 'hints',
        subBuilder: AssetTagHint.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResAssetTagList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResAssetTagList copyWith(void Function(ResAssetTagList) updates) =>
      super.copyWith((message) => updates(message as ResAssetTagList))
          as ResAssetTagList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResAssetTagList() / ResAssetTagList.new instead')
  static ResAssetTagList create() => ResAssetTagList._();
  static $pb.GeneratedMessage $_createMessage() => ResAssetTagList._();
  @$core.override
  ResAssetTagList createEmptyInstance() => ResAssetTagList._();
  @$core.pragma('dart2js:noInline')
  static ResAssetTagList getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResAssetTagList>(
          ResAssetTagList.$_createMessage);
  static ResAssetTagList? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<AssetTagHint> get hints => $_getList(0);
}

class ReqLogList extends $pb.GeneratedMessage {
  factory ReqLogList({
    $core.String? reqId,
    $core.int? limit,
  }) {
    final result = ReqLogList._();
    if (reqId != null) result.reqId = reqId;
    if (limit != null) result.limit = limit;
    return result;
  }

  ReqLogList._();

  factory ReqLogList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqLogList()..mergeFromBuffer(data, registry);
  factory ReqLogList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqLogList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqLogList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqLogList.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'reqId')
    ..aI(2, _omitFieldNames ? '' : 'limit')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqLogList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqLogList copyWith(void Function(ReqLogList) updates) =>
      super.copyWith((message) => updates(message as ReqLogList)) as ReqLogList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqLogList() / ReqLogList.new instead')
  static ReqLogList create() => ReqLogList._();
  static $pb.GeneratedMessage $_createMessage() => ReqLogList._();
  @$core.override
  ReqLogList createEmptyInstance() => ReqLogList._();
  @$core.pragma('dart2js:noInline')
  static ReqLogList getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqLogList>(ReqLogList.$_createMessage);
  static ReqLogList? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get reqId => $_getSZ(0);
  @$pb.TagNumber(1)
  set reqId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasReqId() => $_has(0);
  @$pb.TagNumber(1)
  void clearReqId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get limit => $_getIZ(1);
  @$pb.TagNumber(2)
  set limit($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLimit() => $_has(1);
  @$pb.TagNumber(2)
  void clearLimit() => $_clearField(2);
}

class ResLogList extends $pb.GeneratedMessage {
  factory ResLogList({
    $core.Iterable<$0.Log>? logs,
  }) {
    final result = ResLogList._();
    if (logs != null) result.logs.addAll(logs);
    return result;
  }

  ResLogList._();

  factory ResLogList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResLogList()..mergeFromBuffer(data, registry);
  factory ResLogList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResLogList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResLogList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResLogList.$_createMessage)
    ..pPM<$0.Log>(1, _omitFieldNames ? '' : 'logs',
        subBuilder: $0.Log.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResLogList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResLogList copyWith(void Function(ResLogList) updates) =>
      super.copyWith((message) => updates(message as ResLogList)) as ResLogList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResLogList() / ResLogList.new instead')
  static ResLogList create() => ResLogList._();
  static $pb.GeneratedMessage $_createMessage() => ResLogList._();
  @$core.override
  ResLogList createEmptyInstance() => ResLogList._();
  @$core.pragma('dart2js:noInline')
  static ResLogList getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResLogList>(ResLogList.$_createMessage);
  static ResLogList? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$0.Log> get logs => $_getList(0);
}

class ReqBotPeerList extends $pb.GeneratedMessage {
  factory ReqBotPeerList({
    $fixnum.Int64? botIid,
    $core.bool? includeArchived,
    $core.int? limit,
  }) {
    final result = ReqBotPeerList._();
    if (botIid != null) result.botIid = botIid;
    if (includeArchived != null) result.includeArchived = includeArchived;
    if (limit != null) result.limit = limit;
    return result;
  }

  ReqBotPeerList._();

  factory ReqBotPeerList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqBotPeerList()..mergeFromBuffer(data, registry);
  factory ReqBotPeerList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqBotPeerList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqBotPeerList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqBotPeerList.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'botIid')
    ..aOB(2, _omitFieldNames ? '' : 'includeArchived')
    ..aI(3, _omitFieldNames ? '' : 'limit')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqBotPeerList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqBotPeerList copyWith(void Function(ReqBotPeerList) updates) =>
      super.copyWith((message) => updates(message as ReqBotPeerList))
          as ReqBotPeerList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqBotPeerList() / ReqBotPeerList.new instead')
  static ReqBotPeerList create() => ReqBotPeerList._();
  static $pb.GeneratedMessage $_createMessage() => ReqBotPeerList._();
  @$core.override
  ReqBotPeerList createEmptyInstance() => ReqBotPeerList._();
  @$core.pragma('dart2js:noInline')
  static ReqBotPeerList getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqBotPeerList>(
          ReqBotPeerList.$_createMessage);
  static ReqBotPeerList? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get botIid => $_getI64(0);
  @$pb.TagNumber(1)
  set botIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasBotIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearBotIid() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get includeArchived => $_getBF(1);
  @$pb.TagNumber(2)
  set includeArchived($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasIncludeArchived() => $_has(1);
  @$pb.TagNumber(2)
  void clearIncludeArchived() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get limit => $_getIZ(2);
  @$pb.TagNumber(3)
  set limit($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLimit() => $_has(2);
  @$pb.TagNumber(3)
  void clearLimit() => $_clearField(3);
}

class ResBotPeerList extends $pb.GeneratedMessage {
  factory ResBotPeerList({
    $core.Iterable<Chat>? chats,
  }) {
    final result = ResBotPeerList._();
    if (chats != null) result.chats.addAll(chats);
    return result;
  }

  ResBotPeerList._();

  factory ResBotPeerList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResBotPeerList()..mergeFromBuffer(data, registry);
  factory ResBotPeerList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResBotPeerList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResBotPeerList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResBotPeerList.$_createMessage)
    ..pPM<Chat>(1, _omitFieldNames ? '' : 'chats',
        subBuilder: Chat.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResBotPeerList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResBotPeerList copyWith(void Function(ResBotPeerList) updates) =>
      super.copyWith((message) => updates(message as ResBotPeerList))
          as ResBotPeerList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResBotPeerList() / ResBotPeerList.new instead')
  static ResBotPeerList create() => ResBotPeerList._();
  static $pb.GeneratedMessage $_createMessage() => ResBotPeerList._();
  @$core.override
  ResBotPeerList createEmptyInstance() => ResBotPeerList._();
  @$core.pragma('dart2js:noInline')
  static ResBotPeerList getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResBotPeerList>(
          ResBotPeerList.$_createMessage);
  static ResBotPeerList? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Chat> get chats => $_getList(0);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
