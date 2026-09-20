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

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'chat.pbenum.dart';

export 'chat.pbenum.dart';

class Chat extends $pb.GeneratedMessage {
  factory Chat({
    $fixnum.Int64? id,
    ChatKind? kind,
    $fixnum.Int64? ownerIid,
    $core.String? title,
    $core.String? tag,
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
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    if (kind != null) {
      $result.kind = kind;
    }
    if (ownerIid != null) {
      $result.ownerIid = ownerIid;
    }
    if (title != null) {
      $result.title = title;
    }
    if (tag != null) {
      $result.tag = tag;
    }
    if (model != null) {
      $result.model = model;
    }
    if (botIid != null) {
      $result.botIid = botIid;
    }
    if (channelId != null) {
      $result.channelId = channelId;
    }
    if (peerKey != null) {
      $result.peerKey = peerKey;
    }
    if (peerName != null) {
      $result.peerName = peerName;
    }
    if (peerPic != null) {
      $result.peerPic = peerPic;
    }
    if (aiReplyEnabled != null) {
      $result.aiReplyEnabled = aiReplyEnabled;
    }
    if (lastMsgTsMs != null) {
      $result.lastMsgTsMs = lastMsgTsMs;
    }
    if (lastMsgPreview != null) {
      $result.lastMsgPreview = lastMsgPreview;
    }
    if (metaJson != null) {
      $result.metaJson = metaJson;
    }
    if (createdTsMs != null) {
      $result.createdTsMs = createdTsMs;
    }
    if (updatedTsMs != null) {
      $result.updatedTsMs = updatedTsMs;
    }
    if (deletedTsMs != null) {
      $result.deletedTsMs = deletedTsMs;
    }
    return $result;
  }
  Chat._() : super();
  factory Chat.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Chat.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Chat', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..e<ChatKind>(2, _omitFieldNames ? '' : 'kind', $pb.PbFieldType.OE, defaultOrMaker: ChatKind.CHAT_KIND_UNSPECIFIED, valueOf: ChatKind.valueOf, enumValues: ChatKind.values)
    ..aInt64(3, _omitFieldNames ? '' : 'ownerIid')
    ..aOS(4, _omitFieldNames ? '' : 'title')
    ..aOS(5, _omitFieldNames ? '' : 'tag')
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
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Chat clone() => Chat()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Chat copyWith(void Function(Chat) updates) => super.copyWith((message) => updates(message as Chat)) as Chat;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Chat create() => Chat._();
  Chat createEmptyInstance() => create();
  static $pb.PbList<Chat> createRepeated() => $pb.PbList<Chat>();
  @$core.pragma('dart2js:noInline')
  static Chat getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Chat>(create);
  static Chat? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  ChatKind get kind => $_getN(1);
  @$pb.TagNumber(2)
  set kind(ChatKind v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasKind() => $_has(1);
  @$pb.TagNumber(2)
  void clearKind() => clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get ownerIid => $_getI64(2);
  @$pb.TagNumber(3)
  set ownerIid($fixnum.Int64 v) { $_setInt64(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasOwnerIid() => $_has(2);
  @$pb.TagNumber(3)
  void clearOwnerIid() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get title => $_getSZ(3);
  @$pb.TagNumber(4)
  set title($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasTitle() => $_has(3);
  @$pb.TagNumber(4)
  void clearTitle() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get tag => $_getSZ(4);
  @$pb.TagNumber(5)
  set tag($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasTag() => $_has(4);
  @$pb.TagNumber(5)
  void clearTag() => clearField(5);

  @$pb.TagNumber(6)
  $core.String get model => $_getSZ(5);
  @$pb.TagNumber(6)
  set model($core.String v) { $_setString(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasModel() => $_has(5);
  @$pb.TagNumber(6)
  void clearModel() => clearField(6);

  @$pb.TagNumber(7)
  $fixnum.Int64 get botIid => $_getI64(6);
  @$pb.TagNumber(7)
  set botIid($fixnum.Int64 v) { $_setInt64(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasBotIid() => $_has(6);
  @$pb.TagNumber(7)
  void clearBotIid() => clearField(7);

  @$pb.TagNumber(8)
  $core.String get channelId => $_getSZ(7);
  @$pb.TagNumber(8)
  set channelId($core.String v) { $_setString(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasChannelId() => $_has(7);
  @$pb.TagNumber(8)
  void clearChannelId() => clearField(8);

  @$pb.TagNumber(9)
  $core.String get peerKey => $_getSZ(8);
  @$pb.TagNumber(9)
  set peerKey($core.String v) { $_setString(8, v); }
  @$pb.TagNumber(9)
  $core.bool hasPeerKey() => $_has(8);
  @$pb.TagNumber(9)
  void clearPeerKey() => clearField(9);

  @$pb.TagNumber(10)
  $core.String get peerName => $_getSZ(9);
  @$pb.TagNumber(10)
  set peerName($core.String v) { $_setString(9, v); }
  @$pb.TagNumber(10)
  $core.bool hasPeerName() => $_has(9);
  @$pb.TagNumber(10)
  void clearPeerName() => clearField(10);

  @$pb.TagNumber(11)
  $core.String get peerPic => $_getSZ(10);
  @$pb.TagNumber(11)
  set peerPic($core.String v) { $_setString(10, v); }
  @$pb.TagNumber(11)
  $core.bool hasPeerPic() => $_has(10);
  @$pb.TagNumber(11)
  void clearPeerPic() => clearField(11);

  @$pb.TagNumber(12)
  $core.bool get aiReplyEnabled => $_getBF(11);
  @$pb.TagNumber(12)
  set aiReplyEnabled($core.bool v) { $_setBool(11, v); }
  @$pb.TagNumber(12)
  $core.bool hasAiReplyEnabled() => $_has(11);
  @$pb.TagNumber(12)
  void clearAiReplyEnabled() => clearField(12);

  @$pb.TagNumber(13)
  $fixnum.Int64 get lastMsgTsMs => $_getI64(12);
  @$pb.TagNumber(13)
  set lastMsgTsMs($fixnum.Int64 v) { $_setInt64(12, v); }
  @$pb.TagNumber(13)
  $core.bool hasLastMsgTsMs() => $_has(12);
  @$pb.TagNumber(13)
  void clearLastMsgTsMs() => clearField(13);

  @$pb.TagNumber(14)
  $core.String get lastMsgPreview => $_getSZ(13);
  @$pb.TagNumber(14)
  set lastMsgPreview($core.String v) { $_setString(13, v); }
  @$pb.TagNumber(14)
  $core.bool hasLastMsgPreview() => $_has(13);
  @$pb.TagNumber(14)
  void clearLastMsgPreview() => clearField(14);

  @$pb.TagNumber(15)
  $core.String get metaJson => $_getSZ(14);
  @$pb.TagNumber(15)
  set metaJson($core.String v) { $_setString(14, v); }
  @$pb.TagNumber(15)
  $core.bool hasMetaJson() => $_has(14);
  @$pb.TagNumber(15)
  void clearMetaJson() => clearField(15);

  @$pb.TagNumber(16)
  $fixnum.Int64 get createdTsMs => $_getI64(15);
  @$pb.TagNumber(16)
  set createdTsMs($fixnum.Int64 v) { $_setInt64(15, v); }
  @$pb.TagNumber(16)
  $core.bool hasCreatedTsMs() => $_has(15);
  @$pb.TagNumber(16)
  void clearCreatedTsMs() => clearField(16);

  @$pb.TagNumber(17)
  $fixnum.Int64 get updatedTsMs => $_getI64(16);
  @$pb.TagNumber(17)
  set updatedTsMs($fixnum.Int64 v) { $_setInt64(16, v); }
  @$pb.TagNumber(17)
  $core.bool hasUpdatedTsMs() => $_has(16);
  @$pb.TagNumber(17)
  void clearUpdatedTsMs() => clearField(17);

  @$pb.TagNumber(18)
  $fixnum.Int64 get deletedTsMs => $_getI64(17);
  @$pb.TagNumber(18)
  set deletedTsMs($fixnum.Int64 v) { $_setInt64(17, v); }
  @$pb.TagNumber(18)
  $core.bool hasDeletedTsMs() => $_has(17);
  @$pb.TagNumber(18)
  void clearDeletedTsMs() => clearField(18);
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
  }) {
    final $result = create();
    if (chatId != null) {
      $result.chatId = chatId;
    }
    if (memberIid != null) {
      $result.memberIid = memberIid;
    }
    if (lastReadMsgId != null) {
      $result.lastReadMsgId = lastReadMsgId;
    }
    if (unreadCount != null) {
      $result.unreadCount = unreadCount;
    }
    if (lastMsgTsMs != null) {
      $result.lastMsgTsMs = lastMsgTsMs;
    }
    if (lastMsgPreview != null) {
      $result.lastMsgPreview = lastMsgPreview;
    }
    if (pinnedTsMs != null) {
      $result.pinnedTsMs = pinnedTsMs;
    }
    if (archivedTsMs != null) {
      $result.archivedTsMs = archivedTsMs;
    }
    if (createdTsMs != null) {
      $result.createdTsMs = createdTsMs;
    }
    if (updatedTsMs != null) {
      $result.updatedTsMs = updatedTsMs;
    }
    if (deletedTsMs != null) {
      $result.deletedTsMs = deletedTsMs;
    }
    return $result;
  }
  ChatMember._() : super();
  factory ChatMember.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ChatMember.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ChatMember', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'chatId')
    ..aInt64(2, _omitFieldNames ? '' : 'memberIid')
    ..aInt64(3, _omitFieldNames ? '' : 'lastReadMsgId')
    ..a<$core.int>(4, _omitFieldNames ? '' : 'unreadCount', $pb.PbFieldType.O3)
    ..aInt64(5, _omitFieldNames ? '' : 'lastMsgTsMs')
    ..aOS(6, _omitFieldNames ? '' : 'lastMsgPreview')
    ..aInt64(7, _omitFieldNames ? '' : 'pinnedTsMs')
    ..aInt64(8, _omitFieldNames ? '' : 'archivedTsMs')
    ..aInt64(9, _omitFieldNames ? '' : 'createdTsMs')
    ..aInt64(10, _omitFieldNames ? '' : 'updatedTsMs')
    ..aInt64(11, _omitFieldNames ? '' : 'deletedTsMs')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ChatMember clone() => ChatMember()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ChatMember copyWith(void Function(ChatMember) updates) => super.copyWith((message) => updates(message as ChatMember)) as ChatMember;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ChatMember create() => ChatMember._();
  ChatMember createEmptyInstance() => create();
  static $pb.PbList<ChatMember> createRepeated() => $pb.PbList<ChatMember>();
  @$core.pragma('dart2js:noInline')
  static ChatMember getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ChatMember>(create);
  static ChatMember? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get chatId => $_getI64(0);
  @$pb.TagNumber(1)
  set chatId($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasChatId() => $_has(0);
  @$pb.TagNumber(1)
  void clearChatId() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get memberIid => $_getI64(1);
  @$pb.TagNumber(2)
  set memberIid($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasMemberIid() => $_has(1);
  @$pb.TagNumber(2)
  void clearMemberIid() => clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get lastReadMsgId => $_getI64(2);
  @$pb.TagNumber(3)
  set lastReadMsgId($fixnum.Int64 v) { $_setInt64(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasLastReadMsgId() => $_has(2);
  @$pb.TagNumber(3)
  void clearLastReadMsgId() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get unreadCount => $_getIZ(3);
  @$pb.TagNumber(4)
  set unreadCount($core.int v) { $_setSignedInt32(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasUnreadCount() => $_has(3);
  @$pb.TagNumber(4)
  void clearUnreadCount() => clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get lastMsgTsMs => $_getI64(4);
  @$pb.TagNumber(5)
  set lastMsgTsMs($fixnum.Int64 v) { $_setInt64(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasLastMsgTsMs() => $_has(4);
  @$pb.TagNumber(5)
  void clearLastMsgTsMs() => clearField(5);

  @$pb.TagNumber(6)
  $core.String get lastMsgPreview => $_getSZ(5);
  @$pb.TagNumber(6)
  set lastMsgPreview($core.String v) { $_setString(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasLastMsgPreview() => $_has(5);
  @$pb.TagNumber(6)
  void clearLastMsgPreview() => clearField(6);

  @$pb.TagNumber(7)
  $fixnum.Int64 get pinnedTsMs => $_getI64(6);
  @$pb.TagNumber(7)
  set pinnedTsMs($fixnum.Int64 v) { $_setInt64(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasPinnedTsMs() => $_has(6);
  @$pb.TagNumber(7)
  void clearPinnedTsMs() => clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get archivedTsMs => $_getI64(7);
  @$pb.TagNumber(8)
  set archivedTsMs($fixnum.Int64 v) { $_setInt64(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasArchivedTsMs() => $_has(7);
  @$pb.TagNumber(8)
  void clearArchivedTsMs() => clearField(8);

  @$pb.TagNumber(9)
  $fixnum.Int64 get createdTsMs => $_getI64(8);
  @$pb.TagNumber(9)
  set createdTsMs($fixnum.Int64 v) { $_setInt64(8, v); }
  @$pb.TagNumber(9)
  $core.bool hasCreatedTsMs() => $_has(8);
  @$pb.TagNumber(9)
  void clearCreatedTsMs() => clearField(9);

  @$pb.TagNumber(10)
  $fixnum.Int64 get updatedTsMs => $_getI64(9);
  @$pb.TagNumber(10)
  set updatedTsMs($fixnum.Int64 v) { $_setInt64(9, v); }
  @$pb.TagNumber(10)
  $core.bool hasUpdatedTsMs() => $_has(9);
  @$pb.TagNumber(10)
  void clearUpdatedTsMs() => clearField(10);

  @$pb.TagNumber(11)
  $fixnum.Int64 get deletedTsMs => $_getI64(10);
  @$pb.TagNumber(11)
  set deletedTsMs($fixnum.Int64 v) { $_setInt64(10, v); }
  @$pb.TagNumber(11)
  $core.bool hasDeletedTsMs() => $_has(10);
  @$pb.TagNumber(11)
  void clearDeletedTsMs() => clearField(11);
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
  }) {
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    if (chatId != null) {
      $result.chatId = chatId;
    }
    if (ownerIid != null) {
      $result.ownerIid = ownerIid;
    }
    if (reqId != null) {
      $result.reqId = reqId;
    }
    if (senderIid != null) {
      $result.senderIid = senderIid;
    }
    if (role != null) {
      $result.role = role;
    }
    if (source != null) {
      $result.source = source;
    }
    if (content != null) {
      $result.content = content;
    }
    if (thought != null) {
      $result.thought = thought;
    }
    if (attachmentsJson != null) {
      $result.attachmentsJson = attachmentsJson;
    }
    if (blocksJson != null) {
      $result.blocksJson = blocksJson;
    }
    if (tokensIn != null) {
      $result.tokensIn = tokensIn;
    }
    if (tokensOut != null) {
      $result.tokensOut = tokensOut;
    }
    if (durationMs != null) {
      $result.durationMs = durationMs;
    }
    if (status != null) {
      $result.status = status;
    }
    if (costUsd != null) {
      $result.costUsd = costUsd;
    }
    if (createdTsMs != null) {
      $result.createdTsMs = createdTsMs;
    }
    if (updatedTsMs != null) {
      $result.updatedTsMs = updatedTsMs;
    }
    if (deletedTsMs != null) {
      $result.deletedTsMs = deletedTsMs;
    }
    return $result;
  }
  ChatMsg._() : super();
  factory ChatMsg.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ChatMsg.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ChatMsg', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..aInt64(2, _omitFieldNames ? '' : 'chatId')
    ..aInt64(3, _omitFieldNames ? '' : 'ownerIid')
    ..aOS(4, _omitFieldNames ? '' : 'reqId')
    ..aInt64(5, _omitFieldNames ? '' : 'senderIid')
    ..e<ChatMsgRole>(6, _omitFieldNames ? '' : 'role', $pb.PbFieldType.OE, defaultOrMaker: ChatMsgRole.CHAT_MSG_ROLE_UNSPECIFIED, valueOf: ChatMsgRole.valueOf, enumValues: ChatMsgRole.values)
    ..e<ChatMsgSource>(7, _omitFieldNames ? '' : 'source', $pb.PbFieldType.OE, defaultOrMaker: ChatMsgSource.CHAT_MSG_SOURCE_UNSPECIFIED, valueOf: ChatMsgSource.valueOf, enumValues: ChatMsgSource.values)
    ..aOS(8, _omitFieldNames ? '' : 'content')
    ..aOS(9, _omitFieldNames ? '' : 'thought')
    ..aOS(10, _omitFieldNames ? '' : 'attachmentsJson')
    ..aOS(11, _omitFieldNames ? '' : 'blocksJson')
    ..a<$core.int>(12, _omitFieldNames ? '' : 'tokensIn', $pb.PbFieldType.O3)
    ..a<$core.int>(13, _omitFieldNames ? '' : 'tokensOut', $pb.PbFieldType.O3)
    ..a<$core.int>(14, _omitFieldNames ? '' : 'durationMs', $pb.PbFieldType.O3)
    ..e<ChatMsgStatus>(15, _omitFieldNames ? '' : 'status', $pb.PbFieldType.OE, defaultOrMaker: ChatMsgStatus.CHAT_MSG_STATUS_UNSPECIFIED, valueOf: ChatMsgStatus.valueOf, enumValues: ChatMsgStatus.values)
    ..a<$core.double>(16, _omitFieldNames ? '' : 'costUsd', $pb.PbFieldType.OD)
    ..aInt64(17, _omitFieldNames ? '' : 'createdTsMs')
    ..aInt64(18, _omitFieldNames ? '' : 'updatedTsMs')
    ..aInt64(19, _omitFieldNames ? '' : 'deletedTsMs')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ChatMsg clone() => ChatMsg()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ChatMsg copyWith(void Function(ChatMsg) updates) => super.copyWith((message) => updates(message as ChatMsg)) as ChatMsg;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ChatMsg create() => ChatMsg._();
  ChatMsg createEmptyInstance() => create();
  static $pb.PbList<ChatMsg> createRepeated() => $pb.PbList<ChatMsg>();
  @$core.pragma('dart2js:noInline')
  static ChatMsg getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ChatMsg>(create);
  static ChatMsg? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get chatId => $_getI64(1);
  @$pb.TagNumber(2)
  set chatId($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasChatId() => $_has(1);
  @$pb.TagNumber(2)
  void clearChatId() => clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get ownerIid => $_getI64(2);
  @$pb.TagNumber(3)
  set ownerIid($fixnum.Int64 v) { $_setInt64(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasOwnerIid() => $_has(2);
  @$pb.TagNumber(3)
  void clearOwnerIid() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get reqId => $_getSZ(3);
  @$pb.TagNumber(4)
  set reqId($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasReqId() => $_has(3);
  @$pb.TagNumber(4)
  void clearReqId() => clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get senderIid => $_getI64(4);
  @$pb.TagNumber(5)
  set senderIid($fixnum.Int64 v) { $_setInt64(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasSenderIid() => $_has(4);
  @$pb.TagNumber(5)
  void clearSenderIid() => clearField(5);

  @$pb.TagNumber(6)
  ChatMsgRole get role => $_getN(5);
  @$pb.TagNumber(6)
  set role(ChatMsgRole v) { setField(6, v); }
  @$pb.TagNumber(6)
  $core.bool hasRole() => $_has(5);
  @$pb.TagNumber(6)
  void clearRole() => clearField(6);

  @$pb.TagNumber(7)
  ChatMsgSource get source => $_getN(6);
  @$pb.TagNumber(7)
  set source(ChatMsgSource v) { setField(7, v); }
  @$pb.TagNumber(7)
  $core.bool hasSource() => $_has(6);
  @$pb.TagNumber(7)
  void clearSource() => clearField(7);

  @$pb.TagNumber(8)
  $core.String get content => $_getSZ(7);
  @$pb.TagNumber(8)
  set content($core.String v) { $_setString(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasContent() => $_has(7);
  @$pb.TagNumber(8)
  void clearContent() => clearField(8);

  @$pb.TagNumber(9)
  $core.String get thought => $_getSZ(8);
  @$pb.TagNumber(9)
  set thought($core.String v) { $_setString(8, v); }
  @$pb.TagNumber(9)
  $core.bool hasThought() => $_has(8);
  @$pb.TagNumber(9)
  void clearThought() => clearField(9);

  @$pb.TagNumber(10)
  $core.String get attachmentsJson => $_getSZ(9);
  @$pb.TagNumber(10)
  set attachmentsJson($core.String v) { $_setString(9, v); }
  @$pb.TagNumber(10)
  $core.bool hasAttachmentsJson() => $_has(9);
  @$pb.TagNumber(10)
  void clearAttachmentsJson() => clearField(10);

  @$pb.TagNumber(11)
  $core.String get blocksJson => $_getSZ(10);
  @$pb.TagNumber(11)
  set blocksJson($core.String v) { $_setString(10, v); }
  @$pb.TagNumber(11)
  $core.bool hasBlocksJson() => $_has(10);
  @$pb.TagNumber(11)
  void clearBlocksJson() => clearField(11);

  @$pb.TagNumber(12)
  $core.int get tokensIn => $_getIZ(11);
  @$pb.TagNumber(12)
  set tokensIn($core.int v) { $_setSignedInt32(11, v); }
  @$pb.TagNumber(12)
  $core.bool hasTokensIn() => $_has(11);
  @$pb.TagNumber(12)
  void clearTokensIn() => clearField(12);

  @$pb.TagNumber(13)
  $core.int get tokensOut => $_getIZ(12);
  @$pb.TagNumber(13)
  set tokensOut($core.int v) { $_setSignedInt32(12, v); }
  @$pb.TagNumber(13)
  $core.bool hasTokensOut() => $_has(12);
  @$pb.TagNumber(13)
  void clearTokensOut() => clearField(13);

  @$pb.TagNumber(14)
  $core.int get durationMs => $_getIZ(13);
  @$pb.TagNumber(14)
  set durationMs($core.int v) { $_setSignedInt32(13, v); }
  @$pb.TagNumber(14)
  $core.bool hasDurationMs() => $_has(13);
  @$pb.TagNumber(14)
  void clearDurationMs() => clearField(14);

  @$pb.TagNumber(15)
  ChatMsgStatus get status => $_getN(14);
  @$pb.TagNumber(15)
  set status(ChatMsgStatus v) { setField(15, v); }
  @$pb.TagNumber(15)
  $core.bool hasStatus() => $_has(14);
  @$pb.TagNumber(15)
  void clearStatus() => clearField(15);

  @$pb.TagNumber(16)
  $core.double get costUsd => $_getN(15);
  @$pb.TagNumber(16)
  set costUsd($core.double v) { $_setDouble(15, v); }
  @$pb.TagNumber(16)
  $core.bool hasCostUsd() => $_has(15);
  @$pb.TagNumber(16)
  void clearCostUsd() => clearField(16);

  @$pb.TagNumber(17)
  $fixnum.Int64 get createdTsMs => $_getI64(16);
  @$pb.TagNumber(17)
  set createdTsMs($fixnum.Int64 v) { $_setInt64(16, v); }
  @$pb.TagNumber(17)
  $core.bool hasCreatedTsMs() => $_has(16);
  @$pb.TagNumber(17)
  void clearCreatedTsMs() => clearField(17);

  @$pb.TagNumber(18)
  $fixnum.Int64 get updatedTsMs => $_getI64(17);
  @$pb.TagNumber(18)
  set updatedTsMs($fixnum.Int64 v) { $_setInt64(17, v); }
  @$pb.TagNumber(18)
  $core.bool hasUpdatedTsMs() => $_has(17);
  @$pb.TagNumber(18)
  void clearUpdatedTsMs() => clearField(18);

  @$pb.TagNumber(19)
  $fixnum.Int64 get deletedTsMs => $_getI64(18);
  @$pb.TagNumber(19)
  set deletedTsMs($fixnum.Int64 v) { $_setInt64(18, v); }
  @$pb.TagNumber(19)
  $core.bool hasDeletedTsMs() => $_has(18);
  @$pb.TagNumber(19)
  void clearDeletedTsMs() => clearField(19);
}

/// Home inbox (prompt only)
class ReqInboxList extends $pb.GeneratedMessage {
  factory ReqInboxList({
    $core.bool? includeArchived,
    $core.int? limit,
  }) {
    final $result = create();
    if (includeArchived != null) {
      $result.includeArchived = includeArchived;
    }
    if (limit != null) {
      $result.limit = limit;
    }
    return $result;
  }
  ReqInboxList._() : super();
  factory ReqInboxList.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ReqInboxList.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ReqInboxList', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'includeArchived')
    ..a<$core.int>(2, _omitFieldNames ? '' : 'limit', $pb.PbFieldType.O3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ReqInboxList clone() => ReqInboxList()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ReqInboxList copyWith(void Function(ReqInboxList) updates) => super.copyWith((message) => updates(message as ReqInboxList)) as ReqInboxList;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReqInboxList create() => ReqInboxList._();
  ReqInboxList createEmptyInstance() => create();
  static $pb.PbList<ReqInboxList> createRepeated() => $pb.PbList<ReqInboxList>();
  @$core.pragma('dart2js:noInline')
  static ReqInboxList getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqInboxList>(create);
  static ReqInboxList? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get includeArchived => $_getBF(0);
  @$pb.TagNumber(1)
  set includeArchived($core.bool v) { $_setBool(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasIncludeArchived() => $_has(0);
  @$pb.TagNumber(1)
  void clearIncludeArchived() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get limit => $_getIZ(1);
  @$pb.TagNumber(2)
  set limit($core.int v) { $_setSignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasLimit() => $_has(1);
  @$pb.TagNumber(2)
  void clearLimit() => clearField(2);
}

class ResInboxList extends $pb.GeneratedMessage {
  factory ResInboxList({
    $core.Iterable<Chat>? chats,
    $core.Iterable<ChatMember>? members,
  }) {
    final $result = create();
    if (chats != null) {
      $result.chats.addAll(chats);
    }
    if (members != null) {
      $result.members.addAll(members);
    }
    return $result;
  }
  ResInboxList._() : super();
  factory ResInboxList.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ResInboxList.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ResInboxList', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..pc<Chat>(1, _omitFieldNames ? '' : 'chats', $pb.PbFieldType.PM, subBuilder: Chat.create)
    ..pc<ChatMember>(2, _omitFieldNames ? '' : 'members', $pb.PbFieldType.PM, subBuilder: ChatMember.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ResInboxList clone() => ResInboxList()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ResInboxList copyWith(void Function(ResInboxList) updates) => super.copyWith((message) => updates(message as ResInboxList)) as ResInboxList;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResInboxList create() => ResInboxList._();
  ResInboxList createEmptyInstance() => create();
  static $pb.PbList<ResInboxList> createRepeated() => $pb.PbList<ResInboxList>();
  @$core.pragma('dart2js:noInline')
  static ResInboxList getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResInboxList>(create);
  static ResInboxList? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<Chat> get chats => $_getList(0);

  @$pb.TagNumber(2)
  $core.List<ChatMember> get members => $_getList(1);
}

class ReqChatMsgList extends $pb.GeneratedMessage {
  factory ReqChatMsgList({
    $fixnum.Int64? chatId,
    $fixnum.Int64? beforeId,
    $core.int? limit,
  }) {
    final $result = create();
    if (chatId != null) {
      $result.chatId = chatId;
    }
    if (beforeId != null) {
      $result.beforeId = beforeId;
    }
    if (limit != null) {
      $result.limit = limit;
    }
    return $result;
  }
  ReqChatMsgList._() : super();
  factory ReqChatMsgList.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ReqChatMsgList.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ReqChatMsgList', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'chatId')
    ..aInt64(2, _omitFieldNames ? '' : 'beforeId')
    ..a<$core.int>(3, _omitFieldNames ? '' : 'limit', $pb.PbFieldType.O3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ReqChatMsgList clone() => ReqChatMsgList()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ReqChatMsgList copyWith(void Function(ReqChatMsgList) updates) => super.copyWith((message) => updates(message as ReqChatMsgList)) as ReqChatMsgList;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReqChatMsgList create() => ReqChatMsgList._();
  ReqChatMsgList createEmptyInstance() => create();
  static $pb.PbList<ReqChatMsgList> createRepeated() => $pb.PbList<ReqChatMsgList>();
  @$core.pragma('dart2js:noInline')
  static ReqChatMsgList getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqChatMsgList>(create);
  static ReqChatMsgList? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get chatId => $_getI64(0);
  @$pb.TagNumber(1)
  set chatId($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasChatId() => $_has(0);
  @$pb.TagNumber(1)
  void clearChatId() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get beforeId => $_getI64(1);
  @$pb.TagNumber(2)
  set beforeId($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasBeforeId() => $_has(1);
  @$pb.TagNumber(2)
  void clearBeforeId() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get limit => $_getIZ(2);
  @$pb.TagNumber(3)
  set limit($core.int v) { $_setSignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasLimit() => $_has(2);
  @$pb.TagNumber(3)
  void clearLimit() => clearField(3);
}

class ResChatMsgList extends $pb.GeneratedMessage {
  factory ResChatMsgList({
    $core.Iterable<ChatMsg>? messages,
  }) {
    final $result = create();
    if (messages != null) {
      $result.messages.addAll(messages);
    }
    return $result;
  }
  ResChatMsgList._() : super();
  factory ResChatMsgList.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ResChatMsgList.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ResChatMsgList', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..pc<ChatMsg>(1, _omitFieldNames ? '' : 'messages', $pb.PbFieldType.PM, subBuilder: ChatMsg.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ResChatMsgList clone() => ResChatMsgList()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ResChatMsgList copyWith(void Function(ResChatMsgList) updates) => super.copyWith((message) => updates(message as ResChatMsgList)) as ResChatMsgList;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResChatMsgList create() => ResChatMsgList._();
  ResChatMsgList createEmptyInstance() => create();
  static $pb.PbList<ResChatMsgList> createRepeated() => $pb.PbList<ResChatMsgList>();
  @$core.pragma('dart2js:noInline')
  static ResChatMsgList getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResChatMsgList>(create);
  static ResChatMsgList? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<ChatMsg> get messages => $_getList(0);
}

/// Personal AI prompt stream
class ReqPrompt extends $pb.GeneratedMessage {
  factory ReqPrompt({
    $fixnum.Int64? chatId,
    $core.String? model,
    $core.String? text,
    $core.String? attachmentsJson,
    $core.String? thinking,
  }) {
    final $result = create();
    if (chatId != null) {
      $result.chatId = chatId;
    }
    if (model != null) {
      $result.model = model;
    }
    if (text != null) {
      $result.text = text;
    }
    if (attachmentsJson != null) {
      $result.attachmentsJson = attachmentsJson;
    }
    if (thinking != null) {
      $result.thinking = thinking;
    }
    return $result;
  }
  ReqPrompt._() : super();
  factory ReqPrompt.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ReqPrompt.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ReqPrompt', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'chatId')
    ..aOS(2, _omitFieldNames ? '' : 'model')
    ..aOS(3, _omitFieldNames ? '' : 'text')
    ..aOS(4, _omitFieldNames ? '' : 'attachmentsJson')
    ..aOS(5, _omitFieldNames ? '' : 'thinking')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ReqPrompt clone() => ReqPrompt()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ReqPrompt copyWith(void Function(ReqPrompt) updates) => super.copyWith((message) => updates(message as ReqPrompt)) as ReqPrompt;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReqPrompt create() => ReqPrompt._();
  ReqPrompt createEmptyInstance() => create();
  static $pb.PbList<ReqPrompt> createRepeated() => $pb.PbList<ReqPrompt>();
  @$core.pragma('dart2js:noInline')
  static ReqPrompt getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqPrompt>(create);
  static ReqPrompt? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get chatId => $_getI64(0);
  @$pb.TagNumber(1)
  set chatId($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasChatId() => $_has(0);
  @$pb.TagNumber(1)
  void clearChatId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get model => $_getSZ(1);
  @$pb.TagNumber(2)
  set model($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasModel() => $_has(1);
  @$pb.TagNumber(2)
  void clearModel() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get text => $_getSZ(2);
  @$pb.TagNumber(3)
  set text($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasText() => $_has(2);
  @$pb.TagNumber(3)
  void clearText() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get attachmentsJson => $_getSZ(3);
  @$pb.TagNumber(4)
  set attachmentsJson($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasAttachmentsJson() => $_has(3);
  @$pb.TagNumber(4)
  void clearAttachmentsJson() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get thinking => $_getSZ(4);
  @$pb.TagNumber(5)
  set thinking($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasThinking() => $_has(4);
  @$pb.TagNumber(5)
  void clearThinking() => clearField(5);
}

class ResPromptStart extends $pb.GeneratedMessage {
  factory ResPromptStart({
    $fixnum.Int64? chatId,
    $fixnum.Int64? msgId,
    $core.String? model,
  }) {
    final $result = create();
    if (chatId != null) {
      $result.chatId = chatId;
    }
    if (msgId != null) {
      $result.msgId = msgId;
    }
    if (model != null) {
      $result.model = model;
    }
    return $result;
  }
  ResPromptStart._() : super();
  factory ResPromptStart.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ResPromptStart.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ResPromptStart', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'chatId')
    ..aInt64(2, _omitFieldNames ? '' : 'msgId')
    ..aOS(3, _omitFieldNames ? '' : 'model')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ResPromptStart clone() => ResPromptStart()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ResPromptStart copyWith(void Function(ResPromptStart) updates) => super.copyWith((message) => updates(message as ResPromptStart)) as ResPromptStart;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResPromptStart create() => ResPromptStart._();
  ResPromptStart createEmptyInstance() => create();
  static $pb.PbList<ResPromptStart> createRepeated() => $pb.PbList<ResPromptStart>();
  @$core.pragma('dart2js:noInline')
  static ResPromptStart getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResPromptStart>(create);
  static ResPromptStart? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get chatId => $_getI64(0);
  @$pb.TagNumber(1)
  set chatId($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasChatId() => $_has(0);
  @$pb.TagNumber(1)
  void clearChatId() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get msgId => $_getI64(1);
  @$pb.TagNumber(2)
  set msgId($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasMsgId() => $_has(1);
  @$pb.TagNumber(2)
  void clearMsgId() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get model => $_getSZ(2);
  @$pb.TagNumber(3)
  set model($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasModel() => $_has(2);
  @$pb.TagNumber(3)
  void clearModel() => clearField(3);
}

class ResPromptDelta extends $pb.GeneratedMessage {
  factory ResPromptDelta({
    $core.String? text,
    $core.bool? thought,
    $core.String? blocksJson,
  }) {
    final $result = create();
    if (text != null) {
      $result.text = text;
    }
    if (thought != null) {
      $result.thought = thought;
    }
    if (blocksJson != null) {
      $result.blocksJson = blocksJson;
    }
    return $result;
  }
  ResPromptDelta._() : super();
  factory ResPromptDelta.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ResPromptDelta.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ResPromptDelta', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'text')
    ..aOB(2, _omitFieldNames ? '' : 'thought')
    ..aOS(3, _omitFieldNames ? '' : 'blocksJson')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ResPromptDelta clone() => ResPromptDelta()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ResPromptDelta copyWith(void Function(ResPromptDelta) updates) => super.copyWith((message) => updates(message as ResPromptDelta)) as ResPromptDelta;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResPromptDelta create() => ResPromptDelta._();
  ResPromptDelta createEmptyInstance() => create();
  static $pb.PbList<ResPromptDelta> createRepeated() => $pb.PbList<ResPromptDelta>();
  @$core.pragma('dart2js:noInline')
  static ResPromptDelta getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResPromptDelta>(create);
  static ResPromptDelta? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get text => $_getSZ(0);
  @$pb.TagNumber(1)
  set text($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasText() => $_has(0);
  @$pb.TagNumber(1)
  void clearText() => clearField(1);

  @$pb.TagNumber(2)
  $core.bool get thought => $_getBF(1);
  @$pb.TagNumber(2)
  set thought($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasThought() => $_has(1);
  @$pb.TagNumber(2)
  void clearThought() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get blocksJson => $_getSZ(2);
  @$pb.TagNumber(3)
  set blocksJson($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasBlocksJson() => $_has(2);
  @$pb.TagNumber(3)
  void clearBlocksJson() => clearField(3);
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
  }) {
    final $result = create();
    if (msgId != null) {
      $result.msgId = msgId;
    }
    if (tokensIn != null) {
      $result.tokensIn = tokensIn;
    }
    if (tokensOut != null) {
      $result.tokensOut = tokensOut;
    }
    if (costUsd != null) {
      $result.costUsd = costUsd;
    }
    if (durationMs != null) {
      $result.durationMs = durationMs;
    }
    if (model != null) {
      $result.model = model;
    }
    if (reqId != null) {
      $result.reqId = reqId;
    }
    return $result;
  }
  ResPromptEnd._() : super();
  factory ResPromptEnd.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ResPromptEnd.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ResPromptEnd', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'msgId')
    ..a<$core.int>(2, _omitFieldNames ? '' : 'tokensIn', $pb.PbFieldType.O3)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'tokensOut', $pb.PbFieldType.O3)
    ..a<$core.double>(4, _omitFieldNames ? '' : 'costUsd', $pb.PbFieldType.OD)
    ..a<$core.int>(5, _omitFieldNames ? '' : 'durationMs', $pb.PbFieldType.O3)
    ..aOS(6, _omitFieldNames ? '' : 'model')
    ..aOS(7, _omitFieldNames ? '' : 'reqId')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ResPromptEnd clone() => ResPromptEnd()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ResPromptEnd copyWith(void Function(ResPromptEnd) updates) => super.copyWith((message) => updates(message as ResPromptEnd)) as ResPromptEnd;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResPromptEnd create() => ResPromptEnd._();
  ResPromptEnd createEmptyInstance() => create();
  static $pb.PbList<ResPromptEnd> createRepeated() => $pb.PbList<ResPromptEnd>();
  @$core.pragma('dart2js:noInline')
  static ResPromptEnd getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResPromptEnd>(create);
  static ResPromptEnd? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get msgId => $_getI64(0);
  @$pb.TagNumber(1)
  set msgId($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasMsgId() => $_has(0);
  @$pb.TagNumber(1)
  void clearMsgId() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get tokensIn => $_getIZ(1);
  @$pb.TagNumber(2)
  set tokensIn($core.int v) { $_setSignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasTokensIn() => $_has(1);
  @$pb.TagNumber(2)
  void clearTokensIn() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get tokensOut => $_getIZ(2);
  @$pb.TagNumber(3)
  set tokensOut($core.int v) { $_setSignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasTokensOut() => $_has(2);
  @$pb.TagNumber(3)
  void clearTokensOut() => clearField(3);

  @$pb.TagNumber(4)
  $core.double get costUsd => $_getN(3);
  @$pb.TagNumber(4)
  set costUsd($core.double v) { $_setDouble(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasCostUsd() => $_has(3);
  @$pb.TagNumber(4)
  void clearCostUsd() => clearField(4);

  @$pb.TagNumber(5)
  $core.int get durationMs => $_getIZ(4);
  @$pb.TagNumber(5)
  set durationMs($core.int v) { $_setSignedInt32(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasDurationMs() => $_has(4);
  @$pb.TagNumber(5)
  void clearDurationMs() => clearField(5);

  @$pb.TagNumber(6)
  $core.String get model => $_getSZ(5);
  @$pb.TagNumber(6)
  set model($core.String v) { $_setString(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasModel() => $_has(5);
  @$pb.TagNumber(6)
  void clearModel() => clearField(6);

  @$pb.TagNumber(7)
  $core.String get reqId => $_getSZ(6);
  @$pb.TagNumber(7)
  set reqId($core.String v) { $_setString(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasReqId() => $_has(6);
  @$pb.TagNumber(7)
  void clearReqId() => clearField(7);
}

class ResPromptFail extends $pb.GeneratedMessage {
  factory ResPromptFail({
    $core.String? message,
  }) {
    final $result = create();
    if (message != null) {
      $result.message = message;
    }
    return $result;
  }
  ResPromptFail._() : super();
  factory ResPromptFail.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ResPromptFail.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ResPromptFail', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ResPromptFail clone() => ResPromptFail()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ResPromptFail copyWith(void Function(ResPromptFail) updates) => super.copyWith((message) => updates(message as ResPromptFail)) as ResPromptFail;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResPromptFail create() => ResPromptFail._();
  ResPromptFail createEmptyInstance() => create();
  static $pb.PbList<ResPromptFail> createRepeated() => $pb.PbList<ResPromptFail>();
  @$core.pragma('dart2js:noInline')
  static ResPromptFail getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResPromptFail>(create);
  static ResPromptFail? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get message => $_getSZ(0);
  @$pb.TagNumber(1)
  set message($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => clearField(1);
}

class ReqPromptAbort extends $pb.GeneratedMessage {
  factory ReqPromptAbort({
    $fixnum.Int64? chatId,
  }) {
    final $result = create();
    if (chatId != null) {
      $result.chatId = chatId;
    }
    return $result;
  }
  ReqPromptAbort._() : super();
  factory ReqPromptAbort.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ReqPromptAbort.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ReqPromptAbort', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'chatId')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ReqPromptAbort clone() => ReqPromptAbort()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ReqPromptAbort copyWith(void Function(ReqPromptAbort) updates) => super.copyWith((message) => updates(message as ReqPromptAbort)) as ReqPromptAbort;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReqPromptAbort create() => ReqPromptAbort._();
  ReqPromptAbort createEmptyInstance() => create();
  static $pb.PbList<ReqPromptAbort> createRepeated() => $pb.PbList<ReqPromptAbort>();
  @$core.pragma('dart2js:noInline')
  static ReqPromptAbort getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqPromptAbort>(create);
  static ReqPromptAbort? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get chatId => $_getI64(0);
  @$pb.TagNumber(1)
  set chatId($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasChatId() => $_has(0);
  @$pb.TagNumber(1)
  void clearChatId() => clearField(1);
}

/// bot_peer: stop AI for ONE conversation (not bot / channel)
class ReqChatStop extends $pb.GeneratedMessage {
  factory ReqChatStop({
    $fixnum.Int64? chatId,
    $core.bool? stopped,
  }) {
    final $result = create();
    if (chatId != null) {
      $result.chatId = chatId;
    }
    if (stopped != null) {
      $result.stopped = stopped;
    }
    return $result;
  }
  ReqChatStop._() : super();
  factory ReqChatStop.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ReqChatStop.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ReqChatStop', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'chatId')
    ..aOB(2, _omitFieldNames ? '' : 'stopped')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ReqChatStop clone() => ReqChatStop()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ReqChatStop copyWith(void Function(ReqChatStop) updates) => super.copyWith((message) => updates(message as ReqChatStop)) as ReqChatStop;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReqChatStop create() => ReqChatStop._();
  ReqChatStop createEmptyInstance() => create();
  static $pb.PbList<ReqChatStop> createRepeated() => $pb.PbList<ReqChatStop>();
  @$core.pragma('dart2js:noInline')
  static ReqChatStop getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqChatStop>(create);
  static ReqChatStop? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get chatId => $_getI64(0);
  @$pb.TagNumber(1)
  set chatId($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasChatId() => $_has(0);
  @$pb.TagNumber(1)
  void clearChatId() => clearField(1);

  @$pb.TagNumber(2)
  $core.bool get stopped => $_getBF(1);
  @$pb.TagNumber(2)
  set stopped($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasStopped() => $_has(1);
  @$pb.TagNumber(2)
  void clearStopped() => clearField(2);
}

class ResChatStop extends $pb.GeneratedMessage {
  factory ResChatStop({
    $fixnum.Int64? chatId,
    $core.bool? aiReplyEnabled,
  }) {
    final $result = create();
    if (chatId != null) {
      $result.chatId = chatId;
    }
    if (aiReplyEnabled != null) {
      $result.aiReplyEnabled = aiReplyEnabled;
    }
    return $result;
  }
  ResChatStop._() : super();
  factory ResChatStop.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ResChatStop.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ResChatStop', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'chatId')
    ..aOB(2, _omitFieldNames ? '' : 'aiReplyEnabled')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ResChatStop clone() => ResChatStop()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ResChatStop copyWith(void Function(ResChatStop) updates) => super.copyWith((message) => updates(message as ResChatStop)) as ResChatStop;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResChatStop create() => ResChatStop._();
  ResChatStop createEmptyInstance() => create();
  static $pb.PbList<ResChatStop> createRepeated() => $pb.PbList<ResChatStop>();
  @$core.pragma('dart2js:noInline')
  static ResChatStop getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResChatStop>(create);
  static ResChatStop? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get chatId => $_getI64(0);
  @$pb.TagNumber(1)
  set chatId($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasChatId() => $_has(0);
  @$pb.TagNumber(1)
  void clearChatId() => clearField(1);

  @$pb.TagNumber(2)
  $core.bool get aiReplyEnabled => $_getBF(1);
  @$pb.TagNumber(2)
  set aiReplyEnabled($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasAiReplyEnabled() => $_has(1);
  @$pb.TagNumber(2)
  void clearAiReplyEnabled() => clearField(2);
}

/// bot_peer: staff manual send
class ReqChatSend extends $pb.GeneratedMessage {
  factory ReqChatSend({
    $fixnum.Int64? chatId,
    $core.String? text,
    $core.String? attachmentsJson,
  }) {
    final $result = create();
    if (chatId != null) {
      $result.chatId = chatId;
    }
    if (text != null) {
      $result.text = text;
    }
    if (attachmentsJson != null) {
      $result.attachmentsJson = attachmentsJson;
    }
    return $result;
  }
  ReqChatSend._() : super();
  factory ReqChatSend.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ReqChatSend.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ReqChatSend', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'chatId')
    ..aOS(2, _omitFieldNames ? '' : 'text')
    ..aOS(3, _omitFieldNames ? '' : 'attachmentsJson')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ReqChatSend clone() => ReqChatSend()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ReqChatSend copyWith(void Function(ReqChatSend) updates) => super.copyWith((message) => updates(message as ReqChatSend)) as ReqChatSend;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReqChatSend create() => ReqChatSend._();
  ReqChatSend createEmptyInstance() => create();
  static $pb.PbList<ReqChatSend> createRepeated() => $pb.PbList<ReqChatSend>();
  @$core.pragma('dart2js:noInline')
  static ReqChatSend getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqChatSend>(create);
  static ReqChatSend? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get chatId => $_getI64(0);
  @$pb.TagNumber(1)
  set chatId($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasChatId() => $_has(0);
  @$pb.TagNumber(1)
  void clearChatId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get text => $_getSZ(1);
  @$pb.TagNumber(2)
  set text($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasText() => $_has(1);
  @$pb.TagNumber(2)
  void clearText() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get attachmentsJson => $_getSZ(2);
  @$pb.TagNumber(3)
  set attachmentsJson($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasAttachmentsJson() => $_has(2);
  @$pb.TagNumber(3)
  void clearAttachmentsJson() => clearField(3);
}

class ResChatSend extends $pb.GeneratedMessage {
  factory ResChatSend({
    ChatMsg? message,
  }) {
    final $result = create();
    if (message != null) {
      $result.message = message;
    }
    return $result;
  }
  ResChatSend._() : super();
  factory ResChatSend.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ResChatSend.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ResChatSend', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aOM<ChatMsg>(1, _omitFieldNames ? '' : 'message', subBuilder: ChatMsg.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ResChatSend clone() => ResChatSend()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ResChatSend copyWith(void Function(ResChatSend) updates) => super.copyWith((message) => updates(message as ResChatSend)) as ResChatSend;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResChatSend create() => ResChatSend._();
  ResChatSend createEmptyInstance() => create();
  static $pb.PbList<ResChatSend> createRepeated() => $pb.PbList<ResChatSend>();
  @$core.pragma('dart2js:noInline')
  static ResChatSend getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResChatSend>(create);
  static ResChatSend? _defaultInstance;

  @$pb.TagNumber(1)
  ChatMsg get message => $_getN(0);
  @$pb.TagNumber(1)
  set message(ChatMsg v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => clearField(1);
  @$pb.TagNumber(1)
  ChatMsg ensureMessage() => $_ensure(0);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
