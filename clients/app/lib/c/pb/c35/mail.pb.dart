// This is a generated file - do not edit.
//
// Generated from c35/mail.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'mail.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'mail.pbenum.dart';

class MailAccount extends $pb.GeneratedMessage {
  factory MailAccount({
    $fixnum.Int64? ownerIid,
    $core.String? address,
    $fixnum.Int64? createdTsMs,
    $fixnum.Int64? mailboxId,
  }) {
    final result = MailAccount._();
    if (ownerIid != null) result.ownerIid = ownerIid;
    if (address != null) result.address = address;
    if (createdTsMs != null) result.createdTsMs = createdTsMs;
    if (mailboxId != null) result.mailboxId = mailboxId;
    return result;
  }

  MailAccount._();

  factory MailAccount.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MailAccount()..mergeFromBuffer(data, registry);
  factory MailAccount.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MailAccount()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MailAccount',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: MailAccount.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'ownerIid')
    ..aOS(2, _omitFieldNames ? '' : 'address')
    ..aInt64(3, _omitFieldNames ? '' : 'createdTsMs')
    ..aInt64(4, _omitFieldNames ? '' : 'mailboxId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MailAccount clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MailAccount copyWith(void Function(MailAccount) updates) =>
      super.copyWith((message) => updates(message as MailAccount))
          as MailAccount;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use MailAccount() / MailAccount.new instead')
  static MailAccount create() => MailAccount._();
  static $pb.GeneratedMessage $_createMessage() => MailAccount._();
  @$core.override
  MailAccount createEmptyInstance() => MailAccount._();
  @$core.pragma('dart2js:noInline')
  static MailAccount getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MailAccount>(
          MailAccount.$_createMessage);
  static MailAccount? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get ownerIid => $_getI64(0);
  @$pb.TagNumber(1)
  set ownerIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOwnerIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearOwnerIid() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get address => $_getSZ(1);
  @$pb.TagNumber(2)
  set address($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAddress() => $_has(1);
  @$pb.TagNumber(2)
  void clearAddress() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get createdTsMs => $_getI64(2);
  @$pb.TagNumber(3)
  set createdTsMs($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCreatedTsMs() => $_has(2);
  @$pb.TagNumber(3)
  void clearCreatedTsMs() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get mailboxId => $_getI64(3);
  @$pb.TagNumber(4)
  set mailboxId($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasMailboxId() => $_has(3);
  @$pb.TagNumber(4)
  void clearMailboxId() => $_clearField(4);
}

class MailMailboxMember extends $pb.GeneratedMessage {
  factory MailMailboxMember({
    $fixnum.Int64? memberIid,
    $core.String? name,
    $core.String? email,
    MailMailboxAccess? access,
  }) {
    final result = MailMailboxMember._();
    if (memberIid != null) result.memberIid = memberIid;
    if (name != null) result.name = name;
    if (email != null) result.email = email;
    if (access != null) result.access = access;
    return result;
  }

  MailMailboxMember._();

  factory MailMailboxMember.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MailMailboxMember()..mergeFromBuffer(data, registry);
  factory MailMailboxMember.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MailMailboxMember()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MailMailboxMember',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: MailMailboxMember.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'memberIid')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOS(3, _omitFieldNames ? '' : 'email')
    ..aE<MailMailboxAccess>(4, _omitFieldNames ? '' : 'access',
        enumValues: MailMailboxAccess.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MailMailboxMember clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MailMailboxMember copyWith(void Function(MailMailboxMember) updates) =>
      super.copyWith((message) => updates(message as MailMailboxMember))
          as MailMailboxMember;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use MailMailboxMember() / MailMailboxMember.new instead')
  static MailMailboxMember create() => MailMailboxMember._();
  static $pb.GeneratedMessage $_createMessage() => MailMailboxMember._();
  @$core.override
  MailMailboxMember createEmptyInstance() => MailMailboxMember._();
  @$core.pragma('dart2js:noInline')
  static MailMailboxMember getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MailMailboxMember>(
          MailMailboxMember.$_createMessage);
  static MailMailboxMember? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get memberIid => $_getI64(0);
  @$pb.TagNumber(1)
  set memberIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMemberIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearMemberIid() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get email => $_getSZ(2);
  @$pb.TagNumber(3)
  set email($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasEmail() => $_has(2);
  @$pb.TagNumber(3)
  void clearEmail() => $_clearField(3);

  @$pb.TagNumber(4)
  MailMailboxAccess get access => $_getN(3);
  @$pb.TagNumber(4)
  set access(MailMailboxAccess value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasAccess() => $_has(3);
  @$pb.TagNumber(4)
  void clearAccess() => $_clearField(4);
}

class MailMailbox extends $pb.GeneratedMessage {
  factory MailMailbox({
    $fixnum.Int64? mailboxId,
    $core.String? address,
    MailMailboxKind? kind,
    $fixnum.Int64? siteIid,
    $core.String? siteName,
    $core.String? label,
    $core.int? subscriberLimit,
    MailMailboxAccess? myAccess,
    $core.int? unreadCount,
    $core.Iterable<MailMailboxMember>? members,
  }) {
    final result = MailMailbox._();
    if (mailboxId != null) result.mailboxId = mailboxId;
    if (address != null) result.address = address;
    if (kind != null) result.kind = kind;
    if (siteIid != null) result.siteIid = siteIid;
    if (siteName != null) result.siteName = siteName;
    if (label != null) result.label = label;
    if (subscriberLimit != null) result.subscriberLimit = subscriberLimit;
    if (myAccess != null) result.myAccess = myAccess;
    if (unreadCount != null) result.unreadCount = unreadCount;
    if (members != null) result.members.addAll(members);
    return result;
  }

  MailMailbox._();

  factory MailMailbox.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MailMailbox()..mergeFromBuffer(data, registry);
  factory MailMailbox.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MailMailbox()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MailMailbox',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: MailMailbox.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'mailboxId')
    ..aOS(2, _omitFieldNames ? '' : 'address')
    ..aE<MailMailboxKind>(3, _omitFieldNames ? '' : 'kind',
        enumValues: MailMailboxKind.values)
    ..aInt64(4, _omitFieldNames ? '' : 'siteIid')
    ..aOS(5, _omitFieldNames ? '' : 'siteName')
    ..aOS(6, _omitFieldNames ? '' : 'label')
    ..aI(7, _omitFieldNames ? '' : 'subscriberLimit')
    ..aE<MailMailboxAccess>(8, _omitFieldNames ? '' : 'myAccess',
        enumValues: MailMailboxAccess.values)
    ..aI(9, _omitFieldNames ? '' : 'unreadCount')
    ..pPM<MailMailboxMember>(10, _omitFieldNames ? '' : 'members',
        subBuilder: MailMailboxMember.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MailMailbox clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MailMailbox copyWith(void Function(MailMailbox) updates) =>
      super.copyWith((message) => updates(message as MailMailbox))
          as MailMailbox;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use MailMailbox() / MailMailbox.new instead')
  static MailMailbox create() => MailMailbox._();
  static $pb.GeneratedMessage $_createMessage() => MailMailbox._();
  @$core.override
  MailMailbox createEmptyInstance() => MailMailbox._();
  @$core.pragma('dart2js:noInline')
  static MailMailbox getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MailMailbox>(
          MailMailbox.$_createMessage);
  static MailMailbox? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get mailboxId => $_getI64(0);
  @$pb.TagNumber(1)
  set mailboxId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMailboxId() => $_has(0);
  @$pb.TagNumber(1)
  void clearMailboxId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get address => $_getSZ(1);
  @$pb.TagNumber(2)
  set address($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAddress() => $_has(1);
  @$pb.TagNumber(2)
  void clearAddress() => $_clearField(2);

  @$pb.TagNumber(3)
  MailMailboxKind get kind => $_getN(2);
  @$pb.TagNumber(3)
  set kind(MailMailboxKind value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasKind() => $_has(2);
  @$pb.TagNumber(3)
  void clearKind() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get siteIid => $_getI64(3);
  @$pb.TagNumber(4)
  set siteIid($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSiteIid() => $_has(3);
  @$pb.TagNumber(4)
  void clearSiteIid() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get siteName => $_getSZ(4);
  @$pb.TagNumber(5)
  set siteName($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSiteName() => $_has(4);
  @$pb.TagNumber(5)
  void clearSiteName() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get label => $_getSZ(5);
  @$pb.TagNumber(6)
  set label($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasLabel() => $_has(5);
  @$pb.TagNumber(6)
  void clearLabel() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.int get subscriberLimit => $_getIZ(6);
  @$pb.TagNumber(7)
  set subscriberLimit($core.int value) => $_setSignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasSubscriberLimit() => $_has(6);
  @$pb.TagNumber(7)
  void clearSubscriberLimit() => $_clearField(7);

  @$pb.TagNumber(8)
  MailMailboxAccess get myAccess => $_getN(7);
  @$pb.TagNumber(8)
  set myAccess(MailMailboxAccess value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasMyAccess() => $_has(7);
  @$pb.TagNumber(8)
  void clearMyAccess() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.int get unreadCount => $_getIZ(8);
  @$pb.TagNumber(9)
  set unreadCount($core.int value) => $_setSignedInt32(8, value);
  @$pb.TagNumber(9)
  $core.bool hasUnreadCount() => $_has(8);
  @$pb.TagNumber(9)
  void clearUnreadCount() => $_clearField(9);

  @$pb.TagNumber(10)
  $pb.PbList<MailMailboxMember> get members => $_getList(9);
}

class MailMessage extends $pb.GeneratedMessage {
  factory MailMessage({
    $fixnum.Int64? messageId,
    MailDirection? direction,
    $core.String? fromAddr,
    $core.String? toAddr,
    $core.String? subject,
    $core.String? bodyText,
    $core.String? bodyHtml,
    MailStatus? status,
    $core.String? attachmentsJson,
    $core.String? error,
    $fixnum.Int64? createdTsMs,
    $fixnum.Int64? sentTsMs,
    $core.bool? isArchived,
    $core.bool? isRead,
  }) {
    final result = MailMessage._();
    if (messageId != null) result.messageId = messageId;
    if (direction != null) result.direction = direction;
    if (fromAddr != null) result.fromAddr = fromAddr;
    if (toAddr != null) result.toAddr = toAddr;
    if (subject != null) result.subject = subject;
    if (bodyText != null) result.bodyText = bodyText;
    if (bodyHtml != null) result.bodyHtml = bodyHtml;
    if (status != null) result.status = status;
    if (attachmentsJson != null) result.attachmentsJson = attachmentsJson;
    if (error != null) result.error = error;
    if (createdTsMs != null) result.createdTsMs = createdTsMs;
    if (sentTsMs != null) result.sentTsMs = sentTsMs;
    if (isArchived != null) result.isArchived = isArchived;
    if (isRead != null) result.isRead = isRead;
    return result;
  }

  MailMessage._();

  factory MailMessage.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MailMessage()..mergeFromBuffer(data, registry);
  factory MailMessage.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MailMessage()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MailMessage',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: MailMessage.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'messageId')
    ..aE<MailDirection>(2, _omitFieldNames ? '' : 'direction',
        enumValues: MailDirection.values)
    ..aOS(3, _omitFieldNames ? '' : 'fromAddr')
    ..aOS(4, _omitFieldNames ? '' : 'toAddr')
    ..aOS(5, _omitFieldNames ? '' : 'subject')
    ..aOS(6, _omitFieldNames ? '' : 'bodyText')
    ..aOS(7, _omitFieldNames ? '' : 'bodyHtml')
    ..aE<MailStatus>(8, _omitFieldNames ? '' : 'status',
        enumValues: MailStatus.values)
    ..aOS(9, _omitFieldNames ? '' : 'attachmentsJson')
    ..aOS(10, _omitFieldNames ? '' : 'error')
    ..aInt64(11, _omitFieldNames ? '' : 'createdTsMs')
    ..aInt64(12, _omitFieldNames ? '' : 'sentTsMs')
    ..aOB(13, _omitFieldNames ? '' : 'isArchived')
    ..aOB(14, _omitFieldNames ? '' : 'isRead')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MailMessage clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MailMessage copyWith(void Function(MailMessage) updates) =>
      super.copyWith((message) => updates(message as MailMessage))
          as MailMessage;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use MailMessage() / MailMessage.new instead')
  static MailMessage create() => MailMessage._();
  static $pb.GeneratedMessage $_createMessage() => MailMessage._();
  @$core.override
  MailMessage createEmptyInstance() => MailMessage._();
  @$core.pragma('dart2js:noInline')
  static MailMessage getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MailMessage>(
          MailMessage.$_createMessage);
  static MailMessage? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get messageId => $_getI64(0);
  @$pb.TagNumber(1)
  set messageId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessageId() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessageId() => $_clearField(1);

  @$pb.TagNumber(2)
  MailDirection get direction => $_getN(1);
  @$pb.TagNumber(2)
  set direction(MailDirection value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasDirection() => $_has(1);
  @$pb.TagNumber(2)
  void clearDirection() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get fromAddr => $_getSZ(2);
  @$pb.TagNumber(3)
  set fromAddr($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasFromAddr() => $_has(2);
  @$pb.TagNumber(3)
  void clearFromAddr() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get toAddr => $_getSZ(3);
  @$pb.TagNumber(4)
  set toAddr($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasToAddr() => $_has(3);
  @$pb.TagNumber(4)
  void clearToAddr() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get subject => $_getSZ(4);
  @$pb.TagNumber(5)
  set subject($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSubject() => $_has(4);
  @$pb.TagNumber(5)
  void clearSubject() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get bodyText => $_getSZ(5);
  @$pb.TagNumber(6)
  set bodyText($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasBodyText() => $_has(5);
  @$pb.TagNumber(6)
  void clearBodyText() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get bodyHtml => $_getSZ(6);
  @$pb.TagNumber(7)
  set bodyHtml($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasBodyHtml() => $_has(6);
  @$pb.TagNumber(7)
  void clearBodyHtml() => $_clearField(7);

  @$pb.TagNumber(8)
  MailStatus get status => $_getN(7);
  @$pb.TagNumber(8)
  set status(MailStatus value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasStatus() => $_has(7);
  @$pb.TagNumber(8)
  void clearStatus() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get attachmentsJson => $_getSZ(8);
  @$pb.TagNumber(9)
  set attachmentsJson($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasAttachmentsJson() => $_has(8);
  @$pb.TagNumber(9)
  void clearAttachmentsJson() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.String get error => $_getSZ(9);
  @$pb.TagNumber(10)
  set error($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasError() => $_has(9);
  @$pb.TagNumber(10)
  void clearError() => $_clearField(10);

  @$pb.TagNumber(11)
  $fixnum.Int64 get createdTsMs => $_getI64(10);
  @$pb.TagNumber(11)
  set createdTsMs($fixnum.Int64 value) => $_setInt64(10, value);
  @$pb.TagNumber(11)
  $core.bool hasCreatedTsMs() => $_has(10);
  @$pb.TagNumber(11)
  void clearCreatedTsMs() => $_clearField(11);

  @$pb.TagNumber(12)
  $fixnum.Int64 get sentTsMs => $_getI64(11);
  @$pb.TagNumber(12)
  set sentTsMs($fixnum.Int64 value) => $_setInt64(11, value);
  @$pb.TagNumber(12)
  $core.bool hasSentTsMs() => $_has(11);
  @$pb.TagNumber(12)
  void clearSentTsMs() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.bool get isArchived => $_getBF(12);
  @$pb.TagNumber(13)
  set isArchived($core.bool value) => $_setBool(12, value);
  @$pb.TagNumber(13)
  $core.bool hasIsArchived() => $_has(12);
  @$pb.TagNumber(13)
  void clearIsArchived() => $_clearField(13);

  @$pb.TagNumber(14)
  $core.bool get isRead => $_getBF(13);
  @$pb.TagNumber(14)
  set isRead($core.bool value) => $_setBool(13, value);
  @$pb.TagNumber(14)
  $core.bool hasIsRead() => $_has(13);
  @$pb.TagNumber(14)
  void clearIsRead() => $_clearField(14);
}

class MailAttachment extends $pb.GeneratedMessage {
  factory MailAttachment({
    $core.String? path,
    $core.String? name,
    $core.String? mime,
    $fixnum.Int64? size,
  }) {
    final result = MailAttachment._();
    if (path != null) result.path = path;
    if (name != null) result.name = name;
    if (mime != null) result.mime = mime;
    if (size != null) result.size = size;
    return result;
  }

  MailAttachment._();

  factory MailAttachment.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MailAttachment()..mergeFromBuffer(data, registry);
  factory MailAttachment.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MailAttachment()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MailAttachment',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: MailAttachment.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'path')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOS(3, _omitFieldNames ? '' : 'mime')
    ..aInt64(4, _omitFieldNames ? '' : 'size')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MailAttachment clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MailAttachment copyWith(void Function(MailAttachment) updates) =>
      super.copyWith((message) => updates(message as MailAttachment))
          as MailAttachment;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use MailAttachment() / MailAttachment.new instead')
  static MailAttachment create() => MailAttachment._();
  static $pb.GeneratedMessage $_createMessage() => MailAttachment._();
  @$core.override
  MailAttachment createEmptyInstance() => MailAttachment._();
  @$core.pragma('dart2js:noInline')
  static MailAttachment getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MailAttachment>(
          MailAttachment.$_createMessage);
  static MailAttachment? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get path => $_getSZ(0);
  @$pb.TagNumber(1)
  set path($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearPath() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get mime => $_getSZ(2);
  @$pb.TagNumber(3)
  set mime($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMime() => $_has(2);
  @$pb.TagNumber(3)
  void clearMime() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get size => $_getI64(3);
  @$pb.TagNumber(4)
  set size($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSize() => $_has(3);
  @$pb.TagNumber(4)
  void clearSize() => $_clearField(4);
}

class MailDomainSetupStep extends $pb.GeneratedMessage {
  factory MailDomainSetupStep({
    $core.String? key,
    $core.String? status,
    $core.String? detail,
  }) {
    final result = MailDomainSetupStep._();
    if (key != null) result.key = key;
    if (status != null) result.status = status;
    if (detail != null) result.detail = detail;
    return result;
  }

  MailDomainSetupStep._();

  factory MailDomainSetupStep.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MailDomainSetupStep()..mergeFromBuffer(data, registry);
  factory MailDomainSetupStep.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MailDomainSetupStep()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MailDomainSetupStep',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: MailDomainSetupStep.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'key')
    ..aOS(2, _omitFieldNames ? '' : 'status')
    ..aOS(3, _omitFieldNames ? '' : 'detail')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MailDomainSetupStep clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MailDomainSetupStep copyWith(void Function(MailDomainSetupStep) updates) =>
      super.copyWith((message) => updates(message as MailDomainSetupStep))
          as MailDomainSetupStep;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use MailDomainSetupStep() / MailDomainSetupStep.new instead')
  static MailDomainSetupStep create() => MailDomainSetupStep._();
  static $pb.GeneratedMessage $_createMessage() => MailDomainSetupStep._();
  @$core.override
  MailDomainSetupStep createEmptyInstance() => MailDomainSetupStep._();
  @$core.pragma('dart2js:noInline')
  static MailDomainSetupStep getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MailDomainSetupStep>(
          MailDomainSetupStep.$_createMessage);
  static MailDomainSetupStep? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get key => $_getSZ(0);
  @$pb.TagNumber(1)
  set key($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearKey() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get status => $_getSZ(1);
  @$pb.TagNumber(2)
  set status($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasStatus() => $_has(1);
  @$pb.TagNumber(2)
  void clearStatus() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get detail => $_getSZ(2);
  @$pb.TagNumber(3)
  set detail($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDetail() => $_has(2);
  @$pb.TagNumber(3)
  void clearDetail() => $_clearField(3);
}

class MailDomain extends $pb.GeneratedMessage {
  factory MailDomain({
    $core.String? hostname,
    $core.String? zoneId,
    $core.bool? sendingEnabled,
    $core.bool? routingEnabled,
    $fixnum.Int64? createdTsMs,
    $core.Iterable<MailDomainSetupStep>? setupSteps,
    $core.String? errorSummary,
  }) {
    final result = MailDomain._();
    if (hostname != null) result.hostname = hostname;
    if (zoneId != null) result.zoneId = zoneId;
    if (sendingEnabled != null) result.sendingEnabled = sendingEnabled;
    if (routingEnabled != null) result.routingEnabled = routingEnabled;
    if (createdTsMs != null) result.createdTsMs = createdTsMs;
    if (setupSteps != null) result.setupSteps.addAll(setupSteps);
    if (errorSummary != null) result.errorSummary = errorSummary;
    return result;
  }

  MailDomain._();

  factory MailDomain.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MailDomain()..mergeFromBuffer(data, registry);
  factory MailDomain.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MailDomain()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MailDomain',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: MailDomain.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'hostname')
    ..aOS(2, _omitFieldNames ? '' : 'zoneId')
    ..aOB(3, _omitFieldNames ? '' : 'sendingEnabled')
    ..aOB(4, _omitFieldNames ? '' : 'routingEnabled')
    ..aInt64(5, _omitFieldNames ? '' : 'createdTsMs')
    ..pPM<MailDomainSetupStep>(6, _omitFieldNames ? '' : 'setupSteps',
        subBuilder: MailDomainSetupStep.$_createMessage)
    ..aOS(7, _omitFieldNames ? '' : 'errorSummary')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MailDomain clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MailDomain copyWith(void Function(MailDomain) updates) =>
      super.copyWith((message) => updates(message as MailDomain)) as MailDomain;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use MailDomain() / MailDomain.new instead')
  static MailDomain create() => MailDomain._();
  static $pb.GeneratedMessage $_createMessage() => MailDomain._();
  @$core.override
  MailDomain createEmptyInstance() => MailDomain._();
  @$core.pragma('dart2js:noInline')
  static MailDomain getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MailDomain>(MailDomain.$_createMessage);
  static MailDomain? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get hostname => $_getSZ(0);
  @$pb.TagNumber(1)
  set hostname($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasHostname() => $_has(0);
  @$pb.TagNumber(1)
  void clearHostname() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get zoneId => $_getSZ(1);
  @$pb.TagNumber(2)
  set zoneId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasZoneId() => $_has(1);
  @$pb.TagNumber(2)
  void clearZoneId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get sendingEnabled => $_getBF(2);
  @$pb.TagNumber(3)
  set sendingEnabled($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSendingEnabled() => $_has(2);
  @$pb.TagNumber(3)
  void clearSendingEnabled() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get routingEnabled => $_getBF(3);
  @$pb.TagNumber(4)
  set routingEnabled($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasRoutingEnabled() => $_has(3);
  @$pb.TagNumber(4)
  void clearRoutingEnabled() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get createdTsMs => $_getI64(4);
  @$pb.TagNumber(5)
  set createdTsMs($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasCreatedTsMs() => $_has(4);
  @$pb.TagNumber(5)
  void clearCreatedTsMs() => $_clearField(5);

  @$pb.TagNumber(6)
  $pb.PbList<MailDomainSetupStep> get setupSteps => $_getList(5);

  @$pb.TagNumber(7)
  $core.String get errorSummary => $_getSZ(6);
  @$pb.TagNumber(7)
  set errorSummary($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasErrorSummary() => $_has(6);
  @$pb.TagNumber(7)
  void clearErrorSummary() => $_clearField(7);
}

class ReqMailList extends $pb.GeneratedMessage {
  factory ReqMailList({
    MailDirection? direction,
    $core.int? limit,
    $fixnum.Int64? beforeMessageId,
    $core.bool? isArchived,
    $fixnum.Int64? mailboxId,
  }) {
    final result = ReqMailList._();
    if (direction != null) result.direction = direction;
    if (limit != null) result.limit = limit;
    if (beforeMessageId != null) result.beforeMessageId = beforeMessageId;
    if (isArchived != null) result.isArchived = isArchived;
    if (mailboxId != null) result.mailboxId = mailboxId;
    return result;
  }

  ReqMailList._();

  factory ReqMailList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqMailList()..mergeFromBuffer(data, registry);
  factory ReqMailList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqMailList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqMailList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqMailList.$_createMessage)
    ..aE<MailDirection>(1, _omitFieldNames ? '' : 'direction',
        enumValues: MailDirection.values)
    ..aI(2, _omitFieldNames ? '' : 'limit')
    ..aInt64(3, _omitFieldNames ? '' : 'beforeMessageId')
    ..aOB(4, _omitFieldNames ? '' : 'isArchived')
    ..aInt64(5, _omitFieldNames ? '' : 'mailboxId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqMailList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqMailList copyWith(void Function(ReqMailList) updates) =>
      super.copyWith((message) => updates(message as ReqMailList))
          as ReqMailList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqMailList() / ReqMailList.new instead')
  static ReqMailList create() => ReqMailList._();
  static $pb.GeneratedMessage $_createMessage() => ReqMailList._();
  @$core.override
  ReqMailList createEmptyInstance() => ReqMailList._();
  @$core.pragma('dart2js:noInline')
  static ReqMailList getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqMailList>(
          ReqMailList.$_createMessage);
  static ReqMailList? _defaultInstance;

  @$pb.TagNumber(1)
  MailDirection get direction => $_getN(0);
  @$pb.TagNumber(1)
  set direction(MailDirection value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasDirection() => $_has(0);
  @$pb.TagNumber(1)
  void clearDirection() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get limit => $_getIZ(1);
  @$pb.TagNumber(2)
  set limit($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLimit() => $_has(1);
  @$pb.TagNumber(2)
  void clearLimit() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get beforeMessageId => $_getI64(2);
  @$pb.TagNumber(3)
  set beforeMessageId($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasBeforeMessageId() => $_has(2);
  @$pb.TagNumber(3)
  void clearBeforeMessageId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get isArchived => $_getBF(3);
  @$pb.TagNumber(4)
  set isArchived($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasIsArchived() => $_has(3);
  @$pb.TagNumber(4)
  void clearIsArchived() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get mailboxId => $_getI64(4);
  @$pb.TagNumber(5)
  set mailboxId($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasMailboxId() => $_has(4);
  @$pb.TagNumber(5)
  void clearMailboxId() => $_clearField(5);
}

class ResMailList extends $pb.GeneratedMessage {
  factory ResMailList({
    $core.Iterable<MailMessage>? messages,
  }) {
    final result = ResMailList._();
    if (messages != null) result.messages.addAll(messages);
    return result;
  }

  ResMailList._();

  factory ResMailList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResMailList()..mergeFromBuffer(data, registry);
  factory ResMailList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResMailList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResMailList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResMailList.$_createMessage)
    ..pPM<MailMessage>(1, _omitFieldNames ? '' : 'messages',
        subBuilder: MailMessage.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResMailList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResMailList copyWith(void Function(ResMailList) updates) =>
      super.copyWith((message) => updates(message as ResMailList))
          as ResMailList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResMailList() / ResMailList.new instead')
  static ResMailList create() => ResMailList._();
  static $pb.GeneratedMessage $_createMessage() => ResMailList._();
  @$core.override
  ResMailList createEmptyInstance() => ResMailList._();
  @$core.pragma('dart2js:noInline')
  static ResMailList getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResMailList>(
          ResMailList.$_createMessage);
  static ResMailList? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<MailMessage> get messages => $_getList(0);
}

class ReqMailGet extends $pb.GeneratedMessage {
  factory ReqMailGet({
    $fixnum.Int64? messageId,
    $fixnum.Int64? mailboxId,
  }) {
    final result = ReqMailGet._();
    if (messageId != null) result.messageId = messageId;
    if (mailboxId != null) result.mailboxId = mailboxId;
    return result;
  }

  ReqMailGet._();

  factory ReqMailGet.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqMailGet()..mergeFromBuffer(data, registry);
  factory ReqMailGet.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqMailGet()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqMailGet',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqMailGet.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'messageId')
    ..aInt64(2, _omitFieldNames ? '' : 'mailboxId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqMailGet clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqMailGet copyWith(void Function(ReqMailGet) updates) =>
      super.copyWith((message) => updates(message as ReqMailGet)) as ReqMailGet;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqMailGet() / ReqMailGet.new instead')
  static ReqMailGet create() => ReqMailGet._();
  static $pb.GeneratedMessage $_createMessage() => ReqMailGet._();
  @$core.override
  ReqMailGet createEmptyInstance() => ReqMailGet._();
  @$core.pragma('dart2js:noInline')
  static ReqMailGet getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqMailGet>(ReqMailGet.$_createMessage);
  static ReqMailGet? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get messageId => $_getI64(0);
  @$pb.TagNumber(1)
  set messageId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessageId() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessageId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get mailboxId => $_getI64(1);
  @$pb.TagNumber(2)
  set mailboxId($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMailboxId() => $_has(1);
  @$pb.TagNumber(2)
  void clearMailboxId() => $_clearField(2);
}

class ResMailGet extends $pb.GeneratedMessage {
  factory ResMailGet({
    MailMessage? message,
  }) {
    final result = ResMailGet._();
    if (message != null) result.message = message;
    return result;
  }

  ResMailGet._();

  factory ResMailGet.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResMailGet()..mergeFromBuffer(data, registry);
  factory ResMailGet.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResMailGet()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResMailGet',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResMailGet.$_createMessage)
    ..aOM<MailMessage>(1, _omitFieldNames ? '' : 'message',
        subBuilder: MailMessage.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResMailGet clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResMailGet copyWith(void Function(ResMailGet) updates) =>
      super.copyWith((message) => updates(message as ResMailGet)) as ResMailGet;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResMailGet() / ResMailGet.new instead')
  static ResMailGet create() => ResMailGet._();
  static $pb.GeneratedMessage $_createMessage() => ResMailGet._();
  @$core.override
  ResMailGet createEmptyInstance() => ResMailGet._();
  @$core.pragma('dart2js:noInline')
  static ResMailGet getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResMailGet>(ResMailGet.$_createMessage);
  static ResMailGet? _defaultInstance;

  @$pb.TagNumber(1)
  MailMessage get message => $_getN(0);
  @$pb.TagNumber(1)
  set message(MailMessage value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);
  @$pb.TagNumber(1)
  MailMessage ensureMessage() => $_ensure(0);
}

class ReqMailSend extends $pb.GeneratedMessage {
  factory ReqMailSend({
    $core.String? toAddr,
    $core.String? subject,
    $core.String? bodyText,
    $core.String? bodyHtml,
    $core.Iterable<MailAttachment>? attachments,
    $fixnum.Int64? mailboxId,
  }) {
    final result = ReqMailSend._();
    if (toAddr != null) result.toAddr = toAddr;
    if (subject != null) result.subject = subject;
    if (bodyText != null) result.bodyText = bodyText;
    if (bodyHtml != null) result.bodyHtml = bodyHtml;
    if (attachments != null) result.attachments.addAll(attachments);
    if (mailboxId != null) result.mailboxId = mailboxId;
    return result;
  }

  ReqMailSend._();

  factory ReqMailSend.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqMailSend()..mergeFromBuffer(data, registry);
  factory ReqMailSend.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqMailSend()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqMailSend',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqMailSend.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'toAddr')
    ..aOS(2, _omitFieldNames ? '' : 'subject')
    ..aOS(3, _omitFieldNames ? '' : 'bodyText')
    ..aOS(4, _omitFieldNames ? '' : 'bodyHtml')
    ..pPM<MailAttachment>(5, _omitFieldNames ? '' : 'attachments',
        subBuilder: MailAttachment.$_createMessage)
    ..aInt64(6, _omitFieldNames ? '' : 'mailboxId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqMailSend clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqMailSend copyWith(void Function(ReqMailSend) updates) =>
      super.copyWith((message) => updates(message as ReqMailSend))
          as ReqMailSend;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqMailSend() / ReqMailSend.new instead')
  static ReqMailSend create() => ReqMailSend._();
  static $pb.GeneratedMessage $_createMessage() => ReqMailSend._();
  @$core.override
  ReqMailSend createEmptyInstance() => ReqMailSend._();
  @$core.pragma('dart2js:noInline')
  static ReqMailSend getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqMailSend>(
          ReqMailSend.$_createMessage);
  static ReqMailSend? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get toAddr => $_getSZ(0);
  @$pb.TagNumber(1)
  set toAddr($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasToAddr() => $_has(0);
  @$pb.TagNumber(1)
  void clearToAddr() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get subject => $_getSZ(1);
  @$pb.TagNumber(2)
  set subject($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSubject() => $_has(1);
  @$pb.TagNumber(2)
  void clearSubject() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get bodyText => $_getSZ(2);
  @$pb.TagNumber(3)
  set bodyText($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasBodyText() => $_has(2);
  @$pb.TagNumber(3)
  void clearBodyText() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get bodyHtml => $_getSZ(3);
  @$pb.TagNumber(4)
  set bodyHtml($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasBodyHtml() => $_has(3);
  @$pb.TagNumber(4)
  void clearBodyHtml() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbList<MailAttachment> get attachments => $_getList(4);

  @$pb.TagNumber(6)
  $fixnum.Int64 get mailboxId => $_getI64(5);
  @$pb.TagNumber(6)
  set mailboxId($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasMailboxId() => $_has(5);
  @$pb.TagNumber(6)
  void clearMailboxId() => $_clearField(6);
}

class ResMailSend extends $pb.GeneratedMessage {
  factory ResMailSend({
    MailMessage? message,
  }) {
    final result = ResMailSend._();
    if (message != null) result.message = message;
    return result;
  }

  ResMailSend._();

  factory ResMailSend.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResMailSend()..mergeFromBuffer(data, registry);
  factory ResMailSend.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResMailSend()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResMailSend',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResMailSend.$_createMessage)
    ..aOM<MailMessage>(1, _omitFieldNames ? '' : 'message',
        subBuilder: MailMessage.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResMailSend clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResMailSend copyWith(void Function(ResMailSend) updates) =>
      super.copyWith((message) => updates(message as ResMailSend))
          as ResMailSend;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResMailSend() / ResMailSend.new instead')
  static ResMailSend create() => ResMailSend._();
  static $pb.GeneratedMessage $_createMessage() => ResMailSend._();
  @$core.override
  ResMailSend createEmptyInstance() => ResMailSend._();
  @$core.pragma('dart2js:noInline')
  static ResMailSend getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResMailSend>(
          ResMailSend.$_createMessage);
  static ResMailSend? _defaultInstance;

  @$pb.TagNumber(1)
  MailMessage get message => $_getN(0);
  @$pb.TagNumber(1)
  set message(MailMessage value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);
  @$pb.TagNumber(1)
  MailMessage ensureMessage() => $_ensure(0);
}

class ReqMailMailboxList extends $pb.GeneratedMessage {
  factory ReqMailMailboxList() => ReqMailMailboxList._();

  ReqMailMailboxList._();

  factory ReqMailMailboxList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqMailMailboxList()..mergeFromBuffer(data, registry);
  factory ReqMailMailboxList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqMailMailboxList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqMailMailboxList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqMailMailboxList.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqMailMailboxList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqMailMailboxList copyWith(void Function(ReqMailMailboxList) updates) =>
      super.copyWith((message) => updates(message as ReqMailMailboxList))
          as ReqMailMailboxList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqMailMailboxList() / ReqMailMailboxList.new instead')
  static ReqMailMailboxList create() => ReqMailMailboxList._();
  static $pb.GeneratedMessage $_createMessage() => ReqMailMailboxList._();
  @$core.override
  ReqMailMailboxList createEmptyInstance() => ReqMailMailboxList._();
  @$core.pragma('dart2js:noInline')
  static ReqMailMailboxList getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqMailMailboxList>(
          ReqMailMailboxList.$_createMessage);
  static ReqMailMailboxList? _defaultInstance;
}

class ResMailMailboxList extends $pb.GeneratedMessage {
  factory ResMailMailboxList({
    $core.Iterable<MailMailbox>? mailboxes,
  }) {
    final result = ResMailMailboxList._();
    if (mailboxes != null) result.mailboxes.addAll(mailboxes);
    return result;
  }

  ResMailMailboxList._();

  factory ResMailMailboxList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResMailMailboxList()..mergeFromBuffer(data, registry);
  factory ResMailMailboxList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResMailMailboxList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResMailMailboxList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResMailMailboxList.$_createMessage)
    ..pPM<MailMailbox>(1, _omitFieldNames ? '' : 'mailboxes',
        subBuilder: MailMailbox.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResMailMailboxList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResMailMailboxList copyWith(void Function(ResMailMailboxList) updates) =>
      super.copyWith((message) => updates(message as ResMailMailboxList))
          as ResMailMailboxList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResMailMailboxList() / ResMailMailboxList.new instead')
  static ResMailMailboxList create() => ResMailMailboxList._();
  static $pb.GeneratedMessage $_createMessage() => ResMailMailboxList._();
  @$core.override
  ResMailMailboxList createEmptyInstance() => ResMailMailboxList._();
  @$core.pragma('dart2js:noInline')
  static ResMailMailboxList getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResMailMailboxList>(
          ResMailMailboxList.$_createMessage);
  static ResMailMailboxList? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<MailMailbox> get mailboxes => $_getList(0);
}

class ReqMailDomainList extends $pb.GeneratedMessage {
  factory ReqMailDomainList() => ReqMailDomainList._();

  ReqMailDomainList._();

  factory ReqMailDomainList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqMailDomainList()..mergeFromBuffer(data, registry);
  factory ReqMailDomainList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqMailDomainList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqMailDomainList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqMailDomainList.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqMailDomainList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqMailDomainList copyWith(void Function(ReqMailDomainList) updates) =>
      super.copyWith((message) => updates(message as ReqMailDomainList))
          as ReqMailDomainList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqMailDomainList() / ReqMailDomainList.new instead')
  static ReqMailDomainList create() => ReqMailDomainList._();
  static $pb.GeneratedMessage $_createMessage() => ReqMailDomainList._();
  @$core.override
  ReqMailDomainList createEmptyInstance() => ReqMailDomainList._();
  @$core.pragma('dart2js:noInline')
  static ReqMailDomainList getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqMailDomainList>(
          ReqMailDomainList.$_createMessage);
  static ReqMailDomainList? _defaultInstance;
}

class ResMailDomainList extends $pb.GeneratedMessage {
  factory ResMailDomainList({
    $core.Iterable<MailDomain>? domains,
  }) {
    final result = ResMailDomainList._();
    if (domains != null) result.domains.addAll(domains);
    return result;
  }

  ResMailDomainList._();

  factory ResMailDomainList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResMailDomainList()..mergeFromBuffer(data, registry);
  factory ResMailDomainList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResMailDomainList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResMailDomainList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResMailDomainList.$_createMessage)
    ..pPM<MailDomain>(1, _omitFieldNames ? '' : 'domains',
        subBuilder: MailDomain.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResMailDomainList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResMailDomainList copyWith(void Function(ResMailDomainList) updates) =>
      super.copyWith((message) => updates(message as ResMailDomainList))
          as ResMailDomainList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResMailDomainList() / ResMailDomainList.new instead')
  static ResMailDomainList create() => ResMailDomainList._();
  static $pb.GeneratedMessage $_createMessage() => ResMailDomainList._();
  @$core.override
  ResMailDomainList createEmptyInstance() => ResMailDomainList._();
  @$core.pragma('dart2js:noInline')
  static ResMailDomainList getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResMailDomainList>(
          ResMailDomainList.$_createMessage);
  static ResMailDomainList? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<MailDomain> get domains => $_getList(0);
}

class ReqMailDomainAdd extends $pb.GeneratedMessage {
  factory ReqMailDomainAdd({
    $core.String? hostname,
  }) {
    final result = ReqMailDomainAdd._();
    if (hostname != null) result.hostname = hostname;
    return result;
  }

  ReqMailDomainAdd._();

  factory ReqMailDomainAdd.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqMailDomainAdd()..mergeFromBuffer(data, registry);
  factory ReqMailDomainAdd.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqMailDomainAdd()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqMailDomainAdd',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqMailDomainAdd.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'hostname')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqMailDomainAdd clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqMailDomainAdd copyWith(void Function(ReqMailDomainAdd) updates) =>
      super.copyWith((message) => updates(message as ReqMailDomainAdd))
          as ReqMailDomainAdd;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqMailDomainAdd() / ReqMailDomainAdd.new instead')
  static ReqMailDomainAdd create() => ReqMailDomainAdd._();
  static $pb.GeneratedMessage $_createMessage() => ReqMailDomainAdd._();
  @$core.override
  ReqMailDomainAdd createEmptyInstance() => ReqMailDomainAdd._();
  @$core.pragma('dart2js:noInline')
  static ReqMailDomainAdd getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqMailDomainAdd>(
          ReqMailDomainAdd.$_createMessage);
  static ReqMailDomainAdd? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get hostname => $_getSZ(0);
  @$pb.TagNumber(1)
  set hostname($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasHostname() => $_has(0);
  @$pb.TagNumber(1)
  void clearHostname() => $_clearField(1);
}

class ResMailDomainAdd extends $pb.GeneratedMessage {
  factory ResMailDomainAdd({
    MailDomain? domain,
  }) {
    final result = ResMailDomainAdd._();
    if (domain != null) result.domain = domain;
    return result;
  }

  ResMailDomainAdd._();

  factory ResMailDomainAdd.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResMailDomainAdd()..mergeFromBuffer(data, registry);
  factory ResMailDomainAdd.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResMailDomainAdd()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResMailDomainAdd',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResMailDomainAdd.$_createMessage)
    ..aOM<MailDomain>(1, _omitFieldNames ? '' : 'domain',
        subBuilder: MailDomain.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResMailDomainAdd clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResMailDomainAdd copyWith(void Function(ResMailDomainAdd) updates) =>
      super.copyWith((message) => updates(message as ResMailDomainAdd))
          as ResMailDomainAdd;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResMailDomainAdd() / ResMailDomainAdd.new instead')
  static ResMailDomainAdd create() => ResMailDomainAdd._();
  static $pb.GeneratedMessage $_createMessage() => ResMailDomainAdd._();
  @$core.override
  ResMailDomainAdd createEmptyInstance() => ResMailDomainAdd._();
  @$core.pragma('dart2js:noInline')
  static ResMailDomainAdd getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResMailDomainAdd>(
          ResMailDomainAdd.$_createMessage);
  static ResMailDomainAdd? _defaultInstance;

  @$pb.TagNumber(1)
  MailDomain get domain => $_getN(0);
  @$pb.TagNumber(1)
  set domain(MailDomain value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasDomain() => $_has(0);
  @$pb.TagNumber(1)
  void clearDomain() => $_clearField(1);
  @$pb.TagNumber(1)
  MailDomain ensureDomain() => $_ensure(0);
}

class ReqMailAccountGet extends $pb.GeneratedMessage {
  factory ReqMailAccountGet() => ReqMailAccountGet._();

  ReqMailAccountGet._();

  factory ReqMailAccountGet.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqMailAccountGet()..mergeFromBuffer(data, registry);
  factory ReqMailAccountGet.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqMailAccountGet()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqMailAccountGet',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqMailAccountGet.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqMailAccountGet clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqMailAccountGet copyWith(void Function(ReqMailAccountGet) updates) =>
      super.copyWith((message) => updates(message as ReqMailAccountGet))
          as ReqMailAccountGet;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqMailAccountGet() / ReqMailAccountGet.new instead')
  static ReqMailAccountGet create() => ReqMailAccountGet._();
  static $pb.GeneratedMessage $_createMessage() => ReqMailAccountGet._();
  @$core.override
  ReqMailAccountGet createEmptyInstance() => ReqMailAccountGet._();
  @$core.pragma('dart2js:noInline')
  static ReqMailAccountGet getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqMailAccountGet>(
          ReqMailAccountGet.$_createMessage);
  static ReqMailAccountGet? _defaultInstance;
}

class ResMailAccountGet extends $pb.GeneratedMessage {
  factory ResMailAccountGet({
    MailAccount? account,
  }) {
    final result = ResMailAccountGet._();
    if (account != null) result.account = account;
    return result;
  }

  ResMailAccountGet._();

  factory ResMailAccountGet.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResMailAccountGet()..mergeFromBuffer(data, registry);
  factory ResMailAccountGet.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResMailAccountGet()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResMailAccountGet',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResMailAccountGet.$_createMessage)
    ..aOM<MailAccount>(1, _omitFieldNames ? '' : 'account',
        subBuilder: MailAccount.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResMailAccountGet clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResMailAccountGet copyWith(void Function(ResMailAccountGet) updates) =>
      super.copyWith((message) => updates(message as ResMailAccountGet))
          as ResMailAccountGet;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResMailAccountGet() / ResMailAccountGet.new instead')
  static ResMailAccountGet create() => ResMailAccountGet._();
  static $pb.GeneratedMessage $_createMessage() => ResMailAccountGet._();
  @$core.override
  ResMailAccountGet createEmptyInstance() => ResMailAccountGet._();
  @$core.pragma('dart2js:noInline')
  static ResMailAccountGet getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResMailAccountGet>(
          ResMailAccountGet.$_createMessage);
  static ResMailAccountGet? _defaultInstance;

  @$pb.TagNumber(1)
  MailAccount get account => $_getN(0);
  @$pb.TagNumber(1)
  set account(MailAccount value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasAccount() => $_has(0);
  @$pb.TagNumber(1)
  void clearAccount() => $_clearField(1);
  @$pb.TagNumber(1)
  MailAccount ensureAccount() => $_ensure(0);
}

class ReqMailArchive extends $pb.GeneratedMessage {
  factory ReqMailArchive({
    $core.Iterable<$fixnum.Int64>? messageIds,
    $core.bool? archive,
    $fixnum.Int64? mailboxId,
  }) {
    final result = ReqMailArchive._();
    if (messageIds != null) result.messageIds.addAll(messageIds);
    if (archive != null) result.archive = archive;
    if (mailboxId != null) result.mailboxId = mailboxId;
    return result;
  }

  ReqMailArchive._();

  factory ReqMailArchive.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqMailArchive()..mergeFromBuffer(data, registry);
  factory ReqMailArchive.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqMailArchive()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqMailArchive',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqMailArchive.$_createMessage)
    ..p<$fixnum.Int64>(
        1, _omitFieldNames ? '' : 'messageIds', $pb.PbFieldType.K6)
    ..aOB(2, _omitFieldNames ? '' : 'archive')
    ..aInt64(3, _omitFieldNames ? '' : 'mailboxId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqMailArchive clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqMailArchive copyWith(void Function(ReqMailArchive) updates) =>
      super.copyWith((message) => updates(message as ReqMailArchive))
          as ReqMailArchive;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqMailArchive() / ReqMailArchive.new instead')
  static ReqMailArchive create() => ReqMailArchive._();
  static $pb.GeneratedMessage $_createMessage() => ReqMailArchive._();
  @$core.override
  ReqMailArchive createEmptyInstance() => ReqMailArchive._();
  @$core.pragma('dart2js:noInline')
  static ReqMailArchive getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqMailArchive>(
          ReqMailArchive.$_createMessage);
  static ReqMailArchive? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$fixnum.Int64> get messageIds => $_getList(0);

  @$pb.TagNumber(2)
  $core.bool get archive => $_getBF(1);
  @$pb.TagNumber(2)
  set archive($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasArchive() => $_has(1);
  @$pb.TagNumber(2)
  void clearArchive() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get mailboxId => $_getI64(2);
  @$pb.TagNumber(3)
  set mailboxId($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMailboxId() => $_has(2);
  @$pb.TagNumber(3)
  void clearMailboxId() => $_clearField(3);
}

class ResMailArchive extends $pb.GeneratedMessage {
  factory ResMailArchive({
    $core.int? count,
  }) {
    final result = ResMailArchive._();
    if (count != null) result.count = count;
    return result;
  }

  ResMailArchive._();

  factory ResMailArchive.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResMailArchive()..mergeFromBuffer(data, registry);
  factory ResMailArchive.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResMailArchive()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResMailArchive',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResMailArchive.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'count')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResMailArchive clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResMailArchive copyWith(void Function(ResMailArchive) updates) =>
      super.copyWith((message) => updates(message as ResMailArchive))
          as ResMailArchive;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResMailArchive() / ResMailArchive.new instead')
  static ResMailArchive create() => ResMailArchive._();
  static $pb.GeneratedMessage $_createMessage() => ResMailArchive._();
  @$core.override
  ResMailArchive createEmptyInstance() => ResMailArchive._();
  @$core.pragma('dart2js:noInline')
  static ResMailArchive getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResMailArchive>(
          ResMailArchive.$_createMessage);
  static ResMailArchive? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get count => $_getIZ(0);
  @$pb.TagNumber(1)
  set count($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCount() => $_has(0);
  @$pb.TagNumber(1)
  void clearCount() => $_clearField(1);
}

class MailGroup extends $pb.GeneratedMessage {
  factory MailGroup({
    $core.String? groupId,
    $core.String? name,
    $core.String? description,
    $core.Iterable<$core.String>? emails,
    $fixnum.Int64? createdTsMs,
    $fixnum.Int64? updatedTsMs,
  }) {
    final result = MailGroup._();
    if (groupId != null) result.groupId = groupId;
    if (name != null) result.name = name;
    if (description != null) result.description = description;
    if (emails != null) result.emails.addAll(emails);
    if (createdTsMs != null) result.createdTsMs = createdTsMs;
    if (updatedTsMs != null) result.updatedTsMs = updatedTsMs;
    return result;
  }

  MailGroup._();

  factory MailGroup.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MailGroup()..mergeFromBuffer(data, registry);
  factory MailGroup.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MailGroup()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MailGroup',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: MailGroup.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'groupId')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOS(3, _omitFieldNames ? '' : 'description')
    ..pPS(4, _omitFieldNames ? '' : 'emails')
    ..aInt64(5, _omitFieldNames ? '' : 'createdTsMs')
    ..aInt64(6, _omitFieldNames ? '' : 'updatedTsMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MailGroup clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MailGroup copyWith(void Function(MailGroup) updates) =>
      super.copyWith((message) => updates(message as MailGroup)) as MailGroup;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use MailGroup() / MailGroup.new instead')
  static MailGroup create() => MailGroup._();
  static $pb.GeneratedMessage $_createMessage() => MailGroup._();
  @$core.override
  MailGroup createEmptyInstance() => MailGroup._();
  @$core.pragma('dart2js:noInline')
  static MailGroup getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MailGroup>(MailGroup.$_createMessage);
  static MailGroup? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get groupId => $_getSZ(0);
  @$pb.TagNumber(1)
  set groupId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasGroupId() => $_has(0);
  @$pb.TagNumber(1)
  void clearGroupId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get description => $_getSZ(2);
  @$pb.TagNumber(3)
  set description($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDescription() => $_has(2);
  @$pb.TagNumber(3)
  void clearDescription() => $_clearField(3);

  @$pb.TagNumber(4)
  $pb.PbList<$core.String> get emails => $_getList(3);

  @$pb.TagNumber(5)
  $fixnum.Int64 get createdTsMs => $_getI64(4);
  @$pb.TagNumber(5)
  set createdTsMs($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasCreatedTsMs() => $_has(4);
  @$pb.TagNumber(5)
  void clearCreatedTsMs() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get updatedTsMs => $_getI64(5);
  @$pb.TagNumber(6)
  set updatedTsMs($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasUpdatedTsMs() => $_has(5);
  @$pb.TagNumber(6)
  void clearUpdatedTsMs() => $_clearField(6);
}

class ReqMailGroupList extends $pb.GeneratedMessage {
  factory ReqMailGroupList({
    $fixnum.Int64? mailboxId,
  }) {
    final result = ReqMailGroupList._();
    if (mailboxId != null) result.mailboxId = mailboxId;
    return result;
  }

  ReqMailGroupList._();

  factory ReqMailGroupList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqMailGroupList()..mergeFromBuffer(data, registry);
  factory ReqMailGroupList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqMailGroupList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqMailGroupList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqMailGroupList.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'mailboxId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqMailGroupList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqMailGroupList copyWith(void Function(ReqMailGroupList) updates) =>
      super.copyWith((message) => updates(message as ReqMailGroupList))
          as ReqMailGroupList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqMailGroupList() / ReqMailGroupList.new instead')
  static ReqMailGroupList create() => ReqMailGroupList._();
  static $pb.GeneratedMessage $_createMessage() => ReqMailGroupList._();
  @$core.override
  ReqMailGroupList createEmptyInstance() => ReqMailGroupList._();
  @$core.pragma('dart2js:noInline')
  static ReqMailGroupList getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqMailGroupList>(
          ReqMailGroupList.$_createMessage);
  static ReqMailGroupList? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get mailboxId => $_getI64(0);
  @$pb.TagNumber(1)
  set mailboxId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMailboxId() => $_has(0);
  @$pb.TagNumber(1)
  void clearMailboxId() => $_clearField(1);
}

class ResMailGroupList extends $pb.GeneratedMessage {
  factory ResMailGroupList({
    $core.Iterable<MailGroup>? groups,
  }) {
    final result = ResMailGroupList._();
    if (groups != null) result.groups.addAll(groups);
    return result;
  }

  ResMailGroupList._();

  factory ResMailGroupList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResMailGroupList()..mergeFromBuffer(data, registry);
  factory ResMailGroupList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResMailGroupList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResMailGroupList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResMailGroupList.$_createMessage)
    ..pPM<MailGroup>(1, _omitFieldNames ? '' : 'groups',
        subBuilder: MailGroup.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResMailGroupList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResMailGroupList copyWith(void Function(ResMailGroupList) updates) =>
      super.copyWith((message) => updates(message as ResMailGroupList))
          as ResMailGroupList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResMailGroupList() / ResMailGroupList.new instead')
  static ResMailGroupList create() => ResMailGroupList._();
  static $pb.GeneratedMessage $_createMessage() => ResMailGroupList._();
  @$core.override
  ResMailGroupList createEmptyInstance() => ResMailGroupList._();
  @$core.pragma('dart2js:noInline')
  static ResMailGroupList getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResMailGroupList>(
          ResMailGroupList.$_createMessage);
  static ResMailGroupList? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<MailGroup> get groups => $_getList(0);
}

class ReqMailGroupUpsert extends $pb.GeneratedMessage {
  factory ReqMailGroupUpsert({
    MailGroup? group,
    $fixnum.Int64? mailboxId,
  }) {
    final result = ReqMailGroupUpsert._();
    if (group != null) result.group = group;
    if (mailboxId != null) result.mailboxId = mailboxId;
    return result;
  }

  ReqMailGroupUpsert._();

  factory ReqMailGroupUpsert.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqMailGroupUpsert()..mergeFromBuffer(data, registry);
  factory ReqMailGroupUpsert.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqMailGroupUpsert()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqMailGroupUpsert',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqMailGroupUpsert.$_createMessage)
    ..aOM<MailGroup>(1, _omitFieldNames ? '' : 'group',
        subBuilder: MailGroup.$_createMessage)
    ..aInt64(2, _omitFieldNames ? '' : 'mailboxId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqMailGroupUpsert clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqMailGroupUpsert copyWith(void Function(ReqMailGroupUpsert) updates) =>
      super.copyWith((message) => updates(message as ReqMailGroupUpsert))
          as ReqMailGroupUpsert;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqMailGroupUpsert() / ReqMailGroupUpsert.new instead')
  static ReqMailGroupUpsert create() => ReqMailGroupUpsert._();
  static $pb.GeneratedMessage $_createMessage() => ReqMailGroupUpsert._();
  @$core.override
  ReqMailGroupUpsert createEmptyInstance() => ReqMailGroupUpsert._();
  @$core.pragma('dart2js:noInline')
  static ReqMailGroupUpsert getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqMailGroupUpsert>(
          ReqMailGroupUpsert.$_createMessage);
  static ReqMailGroupUpsert? _defaultInstance;

  @$pb.TagNumber(1)
  MailGroup get group => $_getN(0);
  @$pb.TagNumber(1)
  set group(MailGroup value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasGroup() => $_has(0);
  @$pb.TagNumber(1)
  void clearGroup() => $_clearField(1);
  @$pb.TagNumber(1)
  MailGroup ensureGroup() => $_ensure(0);

  @$pb.TagNumber(2)
  $fixnum.Int64 get mailboxId => $_getI64(1);
  @$pb.TagNumber(2)
  set mailboxId($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMailboxId() => $_has(1);
  @$pb.TagNumber(2)
  void clearMailboxId() => $_clearField(2);
}

class ResMailGroupUpsert extends $pb.GeneratedMessage {
  factory ResMailGroupUpsert({
    MailGroup? group,
  }) {
    final result = ResMailGroupUpsert._();
    if (group != null) result.group = group;
    return result;
  }

  ResMailGroupUpsert._();

  factory ResMailGroupUpsert.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResMailGroupUpsert()..mergeFromBuffer(data, registry);
  factory ResMailGroupUpsert.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResMailGroupUpsert()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResMailGroupUpsert',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResMailGroupUpsert.$_createMessage)
    ..aOM<MailGroup>(1, _omitFieldNames ? '' : 'group',
        subBuilder: MailGroup.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResMailGroupUpsert clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResMailGroupUpsert copyWith(void Function(ResMailGroupUpsert) updates) =>
      super.copyWith((message) => updates(message as ResMailGroupUpsert))
          as ResMailGroupUpsert;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResMailGroupUpsert() / ResMailGroupUpsert.new instead')
  static ResMailGroupUpsert create() => ResMailGroupUpsert._();
  static $pb.GeneratedMessage $_createMessage() => ResMailGroupUpsert._();
  @$core.override
  ResMailGroupUpsert createEmptyInstance() => ResMailGroupUpsert._();
  @$core.pragma('dart2js:noInline')
  static ResMailGroupUpsert getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResMailGroupUpsert>(
          ResMailGroupUpsert.$_createMessage);
  static ResMailGroupUpsert? _defaultInstance;

  @$pb.TagNumber(1)
  MailGroup get group => $_getN(0);
  @$pb.TagNumber(1)
  set group(MailGroup value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasGroup() => $_has(0);
  @$pb.TagNumber(1)
  void clearGroup() => $_clearField(1);
  @$pb.TagNumber(1)
  MailGroup ensureGroup() => $_ensure(0);
}

class ReqMailGroupDelete extends $pb.GeneratedMessage {
  factory ReqMailGroupDelete({
    $core.String? groupId,
    $fixnum.Int64? mailboxId,
  }) {
    final result = ReqMailGroupDelete._();
    if (groupId != null) result.groupId = groupId;
    if (mailboxId != null) result.mailboxId = mailboxId;
    return result;
  }

  ReqMailGroupDelete._();

  factory ReqMailGroupDelete.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqMailGroupDelete()..mergeFromBuffer(data, registry);
  factory ReqMailGroupDelete.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqMailGroupDelete()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqMailGroupDelete',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqMailGroupDelete.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'groupId')
    ..aInt64(2, _omitFieldNames ? '' : 'mailboxId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqMailGroupDelete clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqMailGroupDelete copyWith(void Function(ReqMailGroupDelete) updates) =>
      super.copyWith((message) => updates(message as ReqMailGroupDelete))
          as ReqMailGroupDelete;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqMailGroupDelete() / ReqMailGroupDelete.new instead')
  static ReqMailGroupDelete create() => ReqMailGroupDelete._();
  static $pb.GeneratedMessage $_createMessage() => ReqMailGroupDelete._();
  @$core.override
  ReqMailGroupDelete createEmptyInstance() => ReqMailGroupDelete._();
  @$core.pragma('dart2js:noInline')
  static ReqMailGroupDelete getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqMailGroupDelete>(
          ReqMailGroupDelete.$_createMessage);
  static ReqMailGroupDelete? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get groupId => $_getSZ(0);
  @$pb.TagNumber(1)
  set groupId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasGroupId() => $_has(0);
  @$pb.TagNumber(1)
  void clearGroupId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get mailboxId => $_getI64(1);
  @$pb.TagNumber(2)
  set mailboxId($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMailboxId() => $_has(1);
  @$pb.TagNumber(2)
  void clearMailboxId() => $_clearField(2);
}

class ResMailGroupDelete extends $pb.GeneratedMessage {
  factory ResMailGroupDelete({
    $core.bool? success,
  }) {
    final result = ResMailGroupDelete._();
    if (success != null) result.success = success;
    return result;
  }

  ResMailGroupDelete._();

  factory ResMailGroupDelete.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResMailGroupDelete()..mergeFromBuffer(data, registry);
  factory ResMailGroupDelete.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResMailGroupDelete()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResMailGroupDelete',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResMailGroupDelete.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResMailGroupDelete clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResMailGroupDelete copyWith(void Function(ResMailGroupDelete) updates) =>
      super.copyWith((message) => updates(message as ResMailGroupDelete))
          as ResMailGroupDelete;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResMailGroupDelete() / ResMailGroupDelete.new instead')
  static ResMailGroupDelete create() => ResMailGroupDelete._();
  static $pb.GeneratedMessage $_createMessage() => ResMailGroupDelete._();
  @$core.override
  ResMailGroupDelete createEmptyInstance() => ResMailGroupDelete._();
  @$core.pragma('dart2js:noInline')
  static ResMailGroupDelete getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResMailGroupDelete>(
          ResMailGroupDelete.$_createMessage);
  static ResMailGroupDelete? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);
}

class ReqMailBroadcast extends $pb.GeneratedMessage {
  factory ReqMailBroadcast({
    $core.String? groupId,
    $core.Iterable<$core.String>? customEmails,
    $core.String? subject,
    $core.String? bodyText,
    $core.String? bodyHtml,
    $core.Iterable<MailAttachment>? attachments,
    $fixnum.Int64? mailboxId,
  }) {
    final result = ReqMailBroadcast._();
    if (groupId != null) result.groupId = groupId;
    if (customEmails != null) result.customEmails.addAll(customEmails);
    if (subject != null) result.subject = subject;
    if (bodyText != null) result.bodyText = bodyText;
    if (bodyHtml != null) result.bodyHtml = bodyHtml;
    if (attachments != null) result.attachments.addAll(attachments);
    if (mailboxId != null) result.mailboxId = mailboxId;
    return result;
  }

  ReqMailBroadcast._();

  factory ReqMailBroadcast.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqMailBroadcast()..mergeFromBuffer(data, registry);
  factory ReqMailBroadcast.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqMailBroadcast()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqMailBroadcast',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqMailBroadcast.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'groupId')
    ..pPS(2, _omitFieldNames ? '' : 'customEmails')
    ..aOS(3, _omitFieldNames ? '' : 'subject')
    ..aOS(4, _omitFieldNames ? '' : 'bodyText')
    ..aOS(5, _omitFieldNames ? '' : 'bodyHtml')
    ..pPM<MailAttachment>(6, _omitFieldNames ? '' : 'attachments',
        subBuilder: MailAttachment.$_createMessage)
    ..aInt64(7, _omitFieldNames ? '' : 'mailboxId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqMailBroadcast clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqMailBroadcast copyWith(void Function(ReqMailBroadcast) updates) =>
      super.copyWith((message) => updates(message as ReqMailBroadcast))
          as ReqMailBroadcast;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqMailBroadcast() / ReqMailBroadcast.new instead')
  static ReqMailBroadcast create() => ReqMailBroadcast._();
  static $pb.GeneratedMessage $_createMessage() => ReqMailBroadcast._();
  @$core.override
  ReqMailBroadcast createEmptyInstance() => ReqMailBroadcast._();
  @$core.pragma('dart2js:noInline')
  static ReqMailBroadcast getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqMailBroadcast>(
          ReqMailBroadcast.$_createMessage);
  static ReqMailBroadcast? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get groupId => $_getSZ(0);
  @$pb.TagNumber(1)
  set groupId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasGroupId() => $_has(0);
  @$pb.TagNumber(1)
  void clearGroupId() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get customEmails => $_getList(1);

  @$pb.TagNumber(3)
  $core.String get subject => $_getSZ(2);
  @$pb.TagNumber(3)
  set subject($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSubject() => $_has(2);
  @$pb.TagNumber(3)
  void clearSubject() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get bodyText => $_getSZ(3);
  @$pb.TagNumber(4)
  set bodyText($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasBodyText() => $_has(3);
  @$pb.TagNumber(4)
  void clearBodyText() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get bodyHtml => $_getSZ(4);
  @$pb.TagNumber(5)
  set bodyHtml($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasBodyHtml() => $_has(4);
  @$pb.TagNumber(5)
  void clearBodyHtml() => $_clearField(5);

  @$pb.TagNumber(6)
  $pb.PbList<MailAttachment> get attachments => $_getList(5);

  @$pb.TagNumber(7)
  $fixnum.Int64 get mailboxId => $_getI64(6);
  @$pb.TagNumber(7)
  set mailboxId($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(7)
  $core.bool hasMailboxId() => $_has(6);
  @$pb.TagNumber(7)
  void clearMailboxId() => $_clearField(7);
}

class MailBroadcastFailure extends $pb.GeneratedMessage {
  factory MailBroadcastFailure({
    $core.String? toAddr,
    $core.String? error,
  }) {
    final result = MailBroadcastFailure._();
    if (toAddr != null) result.toAddr = toAddr;
    if (error != null) result.error = error;
    return result;
  }

  MailBroadcastFailure._();

  factory MailBroadcastFailure.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MailBroadcastFailure()..mergeFromBuffer(data, registry);
  factory MailBroadcastFailure.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MailBroadcastFailure()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MailBroadcastFailure',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: MailBroadcastFailure.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'toAddr')
    ..aOS(2, _omitFieldNames ? '' : 'error')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MailBroadcastFailure clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MailBroadcastFailure copyWith(void Function(MailBroadcastFailure) updates) =>
      super.copyWith((message) => updates(message as MailBroadcastFailure))
          as MailBroadcastFailure;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use MailBroadcastFailure() / MailBroadcastFailure.new instead')
  static MailBroadcastFailure create() => MailBroadcastFailure._();
  static $pb.GeneratedMessage $_createMessage() => MailBroadcastFailure._();
  @$core.override
  MailBroadcastFailure createEmptyInstance() => MailBroadcastFailure._();
  @$core.pragma('dart2js:noInline')
  static MailBroadcastFailure getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MailBroadcastFailure>(
          MailBroadcastFailure.$_createMessage);
  static MailBroadcastFailure? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get toAddr => $_getSZ(0);
  @$pb.TagNumber(1)
  set toAddr($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasToAddr() => $_has(0);
  @$pb.TagNumber(1)
  void clearToAddr() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get error => $_getSZ(1);
  @$pb.TagNumber(2)
  set error($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
}

class ResMailBroadcast extends $pb.GeneratedMessage {
  factory ResMailBroadcast({
    $core.int? queuedCount,
    $core.Iterable<MailBroadcastFailure>? failures,
  }) {
    final result = ResMailBroadcast._();
    if (queuedCount != null) result.queuedCount = queuedCount;
    if (failures != null) result.failures.addAll(failures);
    return result;
  }

  ResMailBroadcast._();

  factory ResMailBroadcast.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResMailBroadcast()..mergeFromBuffer(data, registry);
  factory ResMailBroadcast.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResMailBroadcast()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResMailBroadcast',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResMailBroadcast.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'queuedCount')
    ..pPM<MailBroadcastFailure>(2, _omitFieldNames ? '' : 'failures',
        subBuilder: MailBroadcastFailure.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResMailBroadcast clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResMailBroadcast copyWith(void Function(ResMailBroadcast) updates) =>
      super.copyWith((message) => updates(message as ResMailBroadcast))
          as ResMailBroadcast;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResMailBroadcast() / ResMailBroadcast.new instead')
  static ResMailBroadcast create() => ResMailBroadcast._();
  static $pb.GeneratedMessage $_createMessage() => ResMailBroadcast._();
  @$core.override
  ResMailBroadcast createEmptyInstance() => ResMailBroadcast._();
  @$core.pragma('dart2js:noInline')
  static ResMailBroadcast getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResMailBroadcast>(
          ResMailBroadcast.$_createMessage);
  static ResMailBroadcast? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get queuedCount => $_getIZ(0);
  @$pb.TagNumber(1)
  set queuedCount($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasQueuedCount() => $_has(0);
  @$pb.TagNumber(1)
  void clearQueuedCount() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<MailBroadcastFailure> get failures => $_getList(1);
}

class ReqMailMarkRead extends $pb.GeneratedMessage {
  factory ReqMailMarkRead({
    $core.Iterable<$fixnum.Int64>? messageIds,
    $core.bool? read,
    $fixnum.Int64? mailboxId,
  }) {
    final result = ReqMailMarkRead._();
    if (messageIds != null) result.messageIds.addAll(messageIds);
    if (read != null) result.read = read;
    if (mailboxId != null) result.mailboxId = mailboxId;
    return result;
  }

  ReqMailMarkRead._();

  factory ReqMailMarkRead.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqMailMarkRead()..mergeFromBuffer(data, registry);
  factory ReqMailMarkRead.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqMailMarkRead()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqMailMarkRead',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqMailMarkRead.$_createMessage)
    ..p<$fixnum.Int64>(
        1, _omitFieldNames ? '' : 'messageIds', $pb.PbFieldType.K6)
    ..aOB(2, _omitFieldNames ? '' : 'read')
    ..aInt64(3, _omitFieldNames ? '' : 'mailboxId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqMailMarkRead clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqMailMarkRead copyWith(void Function(ReqMailMarkRead) updates) =>
      super.copyWith((message) => updates(message as ReqMailMarkRead))
          as ReqMailMarkRead;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqMailMarkRead() / ReqMailMarkRead.new instead')
  static ReqMailMarkRead create() => ReqMailMarkRead._();
  static $pb.GeneratedMessage $_createMessage() => ReqMailMarkRead._();
  @$core.override
  ReqMailMarkRead createEmptyInstance() => ReqMailMarkRead._();
  @$core.pragma('dart2js:noInline')
  static ReqMailMarkRead getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqMailMarkRead>(
          ReqMailMarkRead.$_createMessage);
  static ReqMailMarkRead? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$fixnum.Int64> get messageIds => $_getList(0);

  @$pb.TagNumber(2)
  $core.bool get read => $_getBF(1);
  @$pb.TagNumber(2)
  set read($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRead() => $_has(1);
  @$pb.TagNumber(2)
  void clearRead() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get mailboxId => $_getI64(2);
  @$pb.TagNumber(3)
  set mailboxId($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMailboxId() => $_has(2);
  @$pb.TagNumber(3)
  void clearMailboxId() => $_clearField(3);
}

class ResMailMarkRead extends $pb.GeneratedMessage {
  factory ResMailMarkRead({
    $core.int? count,
    $core.int? inboxUnreadCount,
  }) {
    final result = ResMailMarkRead._();
    if (count != null) result.count = count;
    if (inboxUnreadCount != null) result.inboxUnreadCount = inboxUnreadCount;
    return result;
  }

  ResMailMarkRead._();

  factory ResMailMarkRead.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResMailMarkRead()..mergeFromBuffer(data, registry);
  factory ResMailMarkRead.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResMailMarkRead()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResMailMarkRead',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResMailMarkRead.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'count')
    ..aI(2, _omitFieldNames ? '' : 'inboxUnreadCount')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResMailMarkRead clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResMailMarkRead copyWith(void Function(ResMailMarkRead) updates) =>
      super.copyWith((message) => updates(message as ResMailMarkRead))
          as ResMailMarkRead;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResMailMarkRead() / ResMailMarkRead.new instead')
  static ResMailMarkRead create() => ResMailMarkRead._();
  static $pb.GeneratedMessage $_createMessage() => ResMailMarkRead._();
  @$core.override
  ResMailMarkRead createEmptyInstance() => ResMailMarkRead._();
  @$core.pragma('dart2js:noInline')
  static ResMailMarkRead getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResMailMarkRead>(
          ResMailMarkRead.$_createMessage);
  static ResMailMarkRead? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get count => $_getIZ(0);
  @$pb.TagNumber(1)
  set count($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCount() => $_has(0);
  @$pb.TagNumber(1)
  void clearCount() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get inboxUnreadCount => $_getIZ(1);
  @$pb.TagNumber(2)
  set inboxUnreadCount($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasInboxUnreadCount() => $_has(1);
  @$pb.TagNumber(2)
  void clearInboxUnreadCount() => $_clearField(2);
}

class ReqMailMailboxAdminList extends $pb.GeneratedMessage {
  factory ReqMailMailboxAdminList() => ReqMailMailboxAdminList._();

  ReqMailMailboxAdminList._();

  factory ReqMailMailboxAdminList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqMailMailboxAdminList()..mergeFromBuffer(data, registry);
  factory ReqMailMailboxAdminList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqMailMailboxAdminList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqMailMailboxAdminList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqMailMailboxAdminList.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqMailMailboxAdminList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqMailMailboxAdminList copyWith(
          void Function(ReqMailMailboxAdminList) updates) =>
      super.copyWith((message) => updates(message as ReqMailMailboxAdminList))
          as ReqMailMailboxAdminList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ReqMailMailboxAdminList() / ReqMailMailboxAdminList.new instead')
  static ReqMailMailboxAdminList create() => ReqMailMailboxAdminList._();
  static $pb.GeneratedMessage $_createMessage() => ReqMailMailboxAdminList._();
  @$core.override
  ReqMailMailboxAdminList createEmptyInstance() => ReqMailMailboxAdminList._();
  @$core.pragma('dart2js:noInline')
  static ReqMailMailboxAdminList getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqMailMailboxAdminList>(
          ReqMailMailboxAdminList.$_createMessage);
  static ReqMailMailboxAdminList? _defaultInstance;
}

class ResMailMailboxAdminList extends $pb.GeneratedMessage {
  factory ResMailMailboxAdminList({
    $core.Iterable<MailMailbox>? mailboxes,
  }) {
    final result = ResMailMailboxAdminList._();
    if (mailboxes != null) result.mailboxes.addAll(mailboxes);
    return result;
  }

  ResMailMailboxAdminList._();

  factory ResMailMailboxAdminList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResMailMailboxAdminList()..mergeFromBuffer(data, registry);
  factory ResMailMailboxAdminList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResMailMailboxAdminList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResMailMailboxAdminList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResMailMailboxAdminList.$_createMessage)
    ..pPM<MailMailbox>(1, _omitFieldNames ? '' : 'mailboxes',
        subBuilder: MailMailbox.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResMailMailboxAdminList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResMailMailboxAdminList copyWith(
          void Function(ResMailMailboxAdminList) updates) =>
      super.copyWith((message) => updates(message as ResMailMailboxAdminList))
          as ResMailMailboxAdminList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ResMailMailboxAdminList() / ResMailMailboxAdminList.new instead')
  static ResMailMailboxAdminList create() => ResMailMailboxAdminList._();
  static $pb.GeneratedMessage $_createMessage() => ResMailMailboxAdminList._();
  @$core.override
  ResMailMailboxAdminList createEmptyInstance() => ResMailMailboxAdminList._();
  @$core.pragma('dart2js:noInline')
  static ResMailMailboxAdminList getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResMailMailboxAdminList>(
          ResMailMailboxAdminList.$_createMessage);
  static ResMailMailboxAdminList? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<MailMailbox> get mailboxes => $_getList(0);
}

class ReqMailMailboxCreate extends $pb.GeneratedMessage {
  factory ReqMailMailboxCreate({
    MailMailboxKind? kind,
    $fixnum.Int64? siteIid,
    $core.String? address,
    $core.String? label,
    $core.int? subscriberLimit,
    $core.Iterable<MailMailboxMember>? members,
  }) {
    final result = ReqMailMailboxCreate._();
    if (kind != null) result.kind = kind;
    if (siteIid != null) result.siteIid = siteIid;
    if (address != null) result.address = address;
    if (label != null) result.label = label;
    if (subscriberLimit != null) result.subscriberLimit = subscriberLimit;
    if (members != null) result.members.addAll(members);
    return result;
  }

  ReqMailMailboxCreate._();

  factory ReqMailMailboxCreate.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqMailMailboxCreate()..mergeFromBuffer(data, registry);
  factory ReqMailMailboxCreate.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqMailMailboxCreate()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqMailMailboxCreate',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqMailMailboxCreate.$_createMessage)
    ..aE<MailMailboxKind>(1, _omitFieldNames ? '' : 'kind',
        enumValues: MailMailboxKind.values)
    ..aInt64(2, _omitFieldNames ? '' : 'siteIid')
    ..aOS(3, _omitFieldNames ? '' : 'address')
    ..aOS(4, _omitFieldNames ? '' : 'label')
    ..aI(5, _omitFieldNames ? '' : 'subscriberLimit')
    ..pPM<MailMailboxMember>(6, _omitFieldNames ? '' : 'members',
        subBuilder: MailMailboxMember.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqMailMailboxCreate clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqMailMailboxCreate copyWith(void Function(ReqMailMailboxCreate) updates) =>
      super.copyWith((message) => updates(message as ReqMailMailboxCreate))
          as ReqMailMailboxCreate;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ReqMailMailboxCreate() / ReqMailMailboxCreate.new instead')
  static ReqMailMailboxCreate create() => ReqMailMailboxCreate._();
  static $pb.GeneratedMessage $_createMessage() => ReqMailMailboxCreate._();
  @$core.override
  ReqMailMailboxCreate createEmptyInstance() => ReqMailMailboxCreate._();
  @$core.pragma('dart2js:noInline')
  static ReqMailMailboxCreate getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqMailMailboxCreate>(
          ReqMailMailboxCreate.$_createMessage);
  static ReqMailMailboxCreate? _defaultInstance;

  @$pb.TagNumber(1)
  MailMailboxKind get kind => $_getN(0);
  @$pb.TagNumber(1)
  set kind(MailMailboxKind value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasKind() => $_has(0);
  @$pb.TagNumber(1)
  void clearKind() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get siteIid => $_getI64(1);
  @$pb.TagNumber(2)
  set siteIid($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSiteIid() => $_has(1);
  @$pb.TagNumber(2)
  void clearSiteIid() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get address => $_getSZ(2);
  @$pb.TagNumber(3)
  set address($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAddress() => $_has(2);
  @$pb.TagNumber(3)
  void clearAddress() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get label => $_getSZ(3);
  @$pb.TagNumber(4)
  set label($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasLabel() => $_has(3);
  @$pb.TagNumber(4)
  void clearLabel() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get subscriberLimit => $_getIZ(4);
  @$pb.TagNumber(5)
  set subscriberLimit($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSubscriberLimit() => $_has(4);
  @$pb.TagNumber(5)
  void clearSubscriberLimit() => $_clearField(5);

  @$pb.TagNumber(6)
  $pb.PbList<MailMailboxMember> get members => $_getList(5);
}

class ResMailMailboxCreate extends $pb.GeneratedMessage {
  factory ResMailMailboxCreate({
    MailMailbox? mailbox,
  }) {
    final result = ResMailMailboxCreate._();
    if (mailbox != null) result.mailbox = mailbox;
    return result;
  }

  ResMailMailboxCreate._();

  factory ResMailMailboxCreate.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResMailMailboxCreate()..mergeFromBuffer(data, registry);
  factory ResMailMailboxCreate.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResMailMailboxCreate()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResMailMailboxCreate',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResMailMailboxCreate.$_createMessage)
    ..aOM<MailMailbox>(1, _omitFieldNames ? '' : 'mailbox',
        subBuilder: MailMailbox.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResMailMailboxCreate clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResMailMailboxCreate copyWith(void Function(ResMailMailboxCreate) updates) =>
      super.copyWith((message) => updates(message as ResMailMailboxCreate))
          as ResMailMailboxCreate;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ResMailMailboxCreate() / ResMailMailboxCreate.new instead')
  static ResMailMailboxCreate create() => ResMailMailboxCreate._();
  static $pb.GeneratedMessage $_createMessage() => ResMailMailboxCreate._();
  @$core.override
  ResMailMailboxCreate createEmptyInstance() => ResMailMailboxCreate._();
  @$core.pragma('dart2js:noInline')
  static ResMailMailboxCreate getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResMailMailboxCreate>(
          ResMailMailboxCreate.$_createMessage);
  static ResMailMailboxCreate? _defaultInstance;

  @$pb.TagNumber(1)
  MailMailbox get mailbox => $_getN(0);
  @$pb.TagNumber(1)
  set mailbox(MailMailbox value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasMailbox() => $_has(0);
  @$pb.TagNumber(1)
  void clearMailbox() => $_clearField(1);
  @$pb.TagNumber(1)
  MailMailbox ensureMailbox() => $_ensure(0);
}

class ReqMailMailboxUpdate extends $pb.GeneratedMessage {
  factory ReqMailMailboxUpdate({
    $fixnum.Int64? mailboxId,
    $core.String? label,
    $core.int? subscriberLimit,
    $core.Iterable<MailMailboxMember>? members,
  }) {
    final result = ReqMailMailboxUpdate._();
    if (mailboxId != null) result.mailboxId = mailboxId;
    if (label != null) result.label = label;
    if (subscriberLimit != null) result.subscriberLimit = subscriberLimit;
    if (members != null) result.members.addAll(members);
    return result;
  }

  ReqMailMailboxUpdate._();

  factory ReqMailMailboxUpdate.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqMailMailboxUpdate()..mergeFromBuffer(data, registry);
  factory ReqMailMailboxUpdate.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqMailMailboxUpdate()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqMailMailboxUpdate',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqMailMailboxUpdate.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'mailboxId')
    ..aOS(2, _omitFieldNames ? '' : 'label')
    ..aI(3, _omitFieldNames ? '' : 'subscriberLimit')
    ..pPM<MailMailboxMember>(4, _omitFieldNames ? '' : 'members',
        subBuilder: MailMailboxMember.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqMailMailboxUpdate clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqMailMailboxUpdate copyWith(void Function(ReqMailMailboxUpdate) updates) =>
      super.copyWith((message) => updates(message as ReqMailMailboxUpdate))
          as ReqMailMailboxUpdate;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ReqMailMailboxUpdate() / ReqMailMailboxUpdate.new instead')
  static ReqMailMailboxUpdate create() => ReqMailMailboxUpdate._();
  static $pb.GeneratedMessage $_createMessage() => ReqMailMailboxUpdate._();
  @$core.override
  ReqMailMailboxUpdate createEmptyInstance() => ReqMailMailboxUpdate._();
  @$core.pragma('dart2js:noInline')
  static ReqMailMailboxUpdate getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqMailMailboxUpdate>(
          ReqMailMailboxUpdate.$_createMessage);
  static ReqMailMailboxUpdate? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get mailboxId => $_getI64(0);
  @$pb.TagNumber(1)
  set mailboxId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMailboxId() => $_has(0);
  @$pb.TagNumber(1)
  void clearMailboxId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get label => $_getSZ(1);
  @$pb.TagNumber(2)
  set label($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLabel() => $_has(1);
  @$pb.TagNumber(2)
  void clearLabel() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get subscriberLimit => $_getIZ(2);
  @$pb.TagNumber(3)
  set subscriberLimit($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSubscriberLimit() => $_has(2);
  @$pb.TagNumber(3)
  void clearSubscriberLimit() => $_clearField(3);

  @$pb.TagNumber(4)
  $pb.PbList<MailMailboxMember> get members => $_getList(3);
}

class ResMailMailboxUpdate extends $pb.GeneratedMessage {
  factory ResMailMailboxUpdate({
    MailMailbox? mailbox,
  }) {
    final result = ResMailMailboxUpdate._();
    if (mailbox != null) result.mailbox = mailbox;
    return result;
  }

  ResMailMailboxUpdate._();

  factory ResMailMailboxUpdate.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResMailMailboxUpdate()..mergeFromBuffer(data, registry);
  factory ResMailMailboxUpdate.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResMailMailboxUpdate()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResMailMailboxUpdate',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResMailMailboxUpdate.$_createMessage)
    ..aOM<MailMailbox>(1, _omitFieldNames ? '' : 'mailbox',
        subBuilder: MailMailbox.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResMailMailboxUpdate clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResMailMailboxUpdate copyWith(void Function(ResMailMailboxUpdate) updates) =>
      super.copyWith((message) => updates(message as ResMailMailboxUpdate))
          as ResMailMailboxUpdate;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ResMailMailboxUpdate() / ResMailMailboxUpdate.new instead')
  static ResMailMailboxUpdate create() => ResMailMailboxUpdate._();
  static $pb.GeneratedMessage $_createMessage() => ResMailMailboxUpdate._();
  @$core.override
  ResMailMailboxUpdate createEmptyInstance() => ResMailMailboxUpdate._();
  @$core.pragma('dart2js:noInline')
  static ResMailMailboxUpdate getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResMailMailboxUpdate>(
          ResMailMailboxUpdate.$_createMessage);
  static ResMailMailboxUpdate? _defaultInstance;

  @$pb.TagNumber(1)
  MailMailbox get mailbox => $_getN(0);
  @$pb.TagNumber(1)
  set mailbox(MailMailbox value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasMailbox() => $_has(0);
  @$pb.TagNumber(1)
  void clearMailbox() => $_clearField(1);
  @$pb.TagNumber(1)
  MailMailbox ensureMailbox() => $_ensure(0);
}

class ReqMailMailboxDelete extends $pb.GeneratedMessage {
  factory ReqMailMailboxDelete({
    $fixnum.Int64? mailboxId,
  }) {
    final result = ReqMailMailboxDelete._();
    if (mailboxId != null) result.mailboxId = mailboxId;
    return result;
  }

  ReqMailMailboxDelete._();

  factory ReqMailMailboxDelete.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqMailMailboxDelete()..mergeFromBuffer(data, registry);
  factory ReqMailMailboxDelete.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqMailMailboxDelete()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqMailMailboxDelete',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqMailMailboxDelete.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'mailboxId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqMailMailboxDelete clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqMailMailboxDelete copyWith(void Function(ReqMailMailboxDelete) updates) =>
      super.copyWith((message) => updates(message as ReqMailMailboxDelete))
          as ReqMailMailboxDelete;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ReqMailMailboxDelete() / ReqMailMailboxDelete.new instead')
  static ReqMailMailboxDelete create() => ReqMailMailboxDelete._();
  static $pb.GeneratedMessage $_createMessage() => ReqMailMailboxDelete._();
  @$core.override
  ReqMailMailboxDelete createEmptyInstance() => ReqMailMailboxDelete._();
  @$core.pragma('dart2js:noInline')
  static ReqMailMailboxDelete getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqMailMailboxDelete>(
          ReqMailMailboxDelete.$_createMessage);
  static ReqMailMailboxDelete? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get mailboxId => $_getI64(0);
  @$pb.TagNumber(1)
  set mailboxId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMailboxId() => $_has(0);
  @$pb.TagNumber(1)
  void clearMailboxId() => $_clearField(1);
}

class ResMailMailboxDelete extends $pb.GeneratedMessage {
  factory ResMailMailboxDelete({
    $core.bool? success,
  }) {
    final result = ResMailMailboxDelete._();
    if (success != null) result.success = success;
    return result;
  }

  ResMailMailboxDelete._();

  factory ResMailMailboxDelete.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResMailMailboxDelete()..mergeFromBuffer(data, registry);
  factory ResMailMailboxDelete.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResMailMailboxDelete()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResMailMailboxDelete',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResMailMailboxDelete.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResMailMailboxDelete clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResMailMailboxDelete copyWith(void Function(ResMailMailboxDelete) updates) =>
      super.copyWith((message) => updates(message as ResMailMailboxDelete))
          as ResMailMailboxDelete;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ResMailMailboxDelete() / ResMailMailboxDelete.new instead')
  static ResMailMailboxDelete create() => ResMailMailboxDelete._();
  static $pb.GeneratedMessage $_createMessage() => ResMailMailboxDelete._();
  @$core.override
  ResMailMailboxDelete createEmptyInstance() => ResMailMailboxDelete._();
  @$core.pragma('dart2js:noInline')
  static ResMailMailboxDelete getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResMailMailboxDelete>(
          ResMailMailboxDelete.$_createMessage);
  static ResMailMailboxDelete? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);
}

class ReqMailDomainFix extends $pb.GeneratedMessage {
  factory ReqMailDomainFix({
    $core.String? hostname,
  }) {
    final result = ReqMailDomainFix._();
    if (hostname != null) result.hostname = hostname;
    return result;
  }

  ReqMailDomainFix._();

  factory ReqMailDomainFix.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqMailDomainFix()..mergeFromBuffer(data, registry);
  factory ReqMailDomainFix.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqMailDomainFix()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqMailDomainFix',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqMailDomainFix.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'hostname')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqMailDomainFix clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqMailDomainFix copyWith(void Function(ReqMailDomainFix) updates) =>
      super.copyWith((message) => updates(message as ReqMailDomainFix))
          as ReqMailDomainFix;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqMailDomainFix() / ReqMailDomainFix.new instead')
  static ReqMailDomainFix create() => ReqMailDomainFix._();
  static $pb.GeneratedMessage $_createMessage() => ReqMailDomainFix._();
  @$core.override
  ReqMailDomainFix createEmptyInstance() => ReqMailDomainFix._();
  @$core.pragma('dart2js:noInline')
  static ReqMailDomainFix getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqMailDomainFix>(
          ReqMailDomainFix.$_createMessage);
  static ReqMailDomainFix? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get hostname => $_getSZ(0);
  @$pb.TagNumber(1)
  set hostname($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasHostname() => $_has(0);
  @$pb.TagNumber(1)
  void clearHostname() => $_clearField(1);
}

class ResMailDomainFix extends $pb.GeneratedMessage {
  factory ResMailDomainFix({
    MailDomain? domain,
  }) {
    final result = ResMailDomainFix._();
    if (domain != null) result.domain = domain;
    return result;
  }

  ResMailDomainFix._();

  factory ResMailDomainFix.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResMailDomainFix()..mergeFromBuffer(data, registry);
  factory ResMailDomainFix.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResMailDomainFix()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResMailDomainFix',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResMailDomainFix.$_createMessage)
    ..aOM<MailDomain>(1, _omitFieldNames ? '' : 'domain',
        subBuilder: MailDomain.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResMailDomainFix clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResMailDomainFix copyWith(void Function(ResMailDomainFix) updates) =>
      super.copyWith((message) => updates(message as ResMailDomainFix))
          as ResMailDomainFix;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResMailDomainFix() / ResMailDomainFix.new instead')
  static ResMailDomainFix create() => ResMailDomainFix._();
  static $pb.GeneratedMessage $_createMessage() => ResMailDomainFix._();
  @$core.override
  ResMailDomainFix createEmptyInstance() => ResMailDomainFix._();
  @$core.pragma('dart2js:noInline')
  static ResMailDomainFix getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResMailDomainFix>(
          ResMailDomainFix.$_createMessage);
  static ResMailDomainFix? _defaultInstance;

  @$pb.TagNumber(1)
  MailDomain get domain => $_getN(0);
  @$pb.TagNumber(1)
  set domain(MailDomain value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasDomain() => $_has(0);
  @$pb.TagNumber(1)
  void clearDomain() => $_clearField(1);
  @$pb.TagNumber(1)
  MailDomain ensureDomain() => $_ensure(0);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
