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

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
