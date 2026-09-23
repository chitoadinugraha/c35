// This is a generated file - do not edit.
//
// Generated from c35/channel.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// One entry inside identity(kind=bot).meta.channels[]
class BotChannelDoc extends $pb.GeneratedMessage {
  factory BotChannelDoc({
    $core.String? id,
    $core.String? platform,
    $core.String? provider,
    $core.String? status,
    $core.String? botUsername,
    $core.String? phone,
    $core.String? errorMessage,
  }) {
    final result = BotChannelDoc._();
    if (id != null) result.id = id;
    if (platform != null) result.platform = platform;
    if (provider != null) result.provider = provider;
    if (status != null) result.status = status;
    if (botUsername != null) result.botUsername = botUsername;
    if (phone != null) result.phone = phone;
    if (errorMessage != null) result.errorMessage = errorMessage;
    return result;
  }

  BotChannelDoc._();

  factory BotChannelDoc.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BotChannelDoc()..mergeFromBuffer(data, registry);
  factory BotChannelDoc.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BotChannelDoc()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BotChannelDoc',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: BotChannelDoc.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'platform')
    ..aOS(3, _omitFieldNames ? '' : 'provider')
    ..aOS(4, _omitFieldNames ? '' : 'status')
    ..aOS(5, _omitFieldNames ? '' : 'botUsername')
    ..aOS(6, _omitFieldNames ? '' : 'phone')
    ..aOS(7, _omitFieldNames ? '' : 'errorMessage')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BotChannelDoc clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BotChannelDoc copyWith(void Function(BotChannelDoc) updates) =>
      super.copyWith((message) => updates(message as BotChannelDoc))
          as BotChannelDoc;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use BotChannelDoc() / BotChannelDoc.new instead')
  static BotChannelDoc create() => BotChannelDoc._();
  static $pb.GeneratedMessage $_createMessage() => BotChannelDoc._();
  @$core.override
  BotChannelDoc createEmptyInstance() => BotChannelDoc._();
  @$core.pragma('dart2js:noInline')
  static BotChannelDoc getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BotChannelDoc>(
          BotChannelDoc.$_createMessage);
  static BotChannelDoc? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get platform => $_getSZ(1);
  @$pb.TagNumber(2)
  set platform($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPlatform() => $_has(1);
  @$pb.TagNumber(2)
  void clearPlatform() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get provider => $_getSZ(2);
  @$pb.TagNumber(3)
  set provider($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasProvider() => $_has(2);
  @$pb.TagNumber(3)
  void clearProvider() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get status => $_getSZ(3);
  @$pb.TagNumber(4)
  set status($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasStatus() => $_has(3);
  @$pb.TagNumber(4)
  void clearStatus() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get botUsername => $_getSZ(4);
  @$pb.TagNumber(5)
  set botUsername($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasBotUsername() => $_has(4);
  @$pb.TagNumber(5)
  void clearBotUsername() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get phone => $_getSZ(5);
  @$pb.TagNumber(6)
  set phone($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasPhone() => $_has(5);
  @$pb.TagNumber(6)
  void clearPhone() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get errorMessage => $_getSZ(6);
  @$pb.TagNumber(7)
  set errorMessage($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasErrorMessage() => $_has(6);
  @$pb.TagNumber(7)
  void clearErrorMessage() => $_clearField(7);
}

class ReqChannelTelegramConnect extends $pb.GeneratedMessage {
  factory ReqChannelTelegramConnect({
    $fixnum.Int64? botIid,
    $core.String? botToken,
  }) {
    final result = ReqChannelTelegramConnect._();
    if (botIid != null) result.botIid = botIid;
    if (botToken != null) result.botToken = botToken;
    return result;
  }

  ReqChannelTelegramConnect._();

  factory ReqChannelTelegramConnect.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqChannelTelegramConnect()..mergeFromBuffer(data, registry);
  factory ReqChannelTelegramConnect.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqChannelTelegramConnect()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqChannelTelegramConnect',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqChannelTelegramConnect.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'botIid')
    ..aOS(2, _omitFieldNames ? '' : 'botToken')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqChannelTelegramConnect clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqChannelTelegramConnect copyWith(
          void Function(ReqChannelTelegramConnect) updates) =>
      super.copyWith((message) => updates(message as ReqChannelTelegramConnect))
          as ReqChannelTelegramConnect;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ReqChannelTelegramConnect() / ReqChannelTelegramConnect.new instead')
  static ReqChannelTelegramConnect create() => ReqChannelTelegramConnect._();
  static $pb.GeneratedMessage $_createMessage() =>
      ReqChannelTelegramConnect._();
  @$core.override
  ReqChannelTelegramConnect createEmptyInstance() =>
      ReqChannelTelegramConnect._();
  @$core.pragma('dart2js:noInline')
  static ReqChannelTelegramConnect getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqChannelTelegramConnect>(
          ReqChannelTelegramConnect.$_createMessage);
  static ReqChannelTelegramConnect? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get botIid => $_getI64(0);
  @$pb.TagNumber(1)
  set botIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasBotIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearBotIid() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get botToken => $_getSZ(1);
  @$pb.TagNumber(2)
  set botToken($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasBotToken() => $_has(1);
  @$pb.TagNumber(2)
  void clearBotToken() => $_clearField(2);
}

class ResChannelTelegramConnect extends $pb.GeneratedMessage {
  factory ResChannelTelegramConnect({
    $fixnum.Int64? botIid,
    BotChannelDoc? channel,
    $core.String? webhookUrl,
  }) {
    final result = ResChannelTelegramConnect._();
    if (botIid != null) result.botIid = botIid;
    if (channel != null) result.channel = channel;
    if (webhookUrl != null) result.webhookUrl = webhookUrl;
    return result;
  }

  ResChannelTelegramConnect._();

  factory ResChannelTelegramConnect.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResChannelTelegramConnect()..mergeFromBuffer(data, registry);
  factory ResChannelTelegramConnect.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResChannelTelegramConnect()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResChannelTelegramConnect',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResChannelTelegramConnect.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'botIid')
    ..aOM<BotChannelDoc>(2, _omitFieldNames ? '' : 'channel',
        subBuilder: BotChannelDoc.$_createMessage)
    ..aOS(3, _omitFieldNames ? '' : 'webhookUrl')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResChannelTelegramConnect clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResChannelTelegramConnect copyWith(
          void Function(ResChannelTelegramConnect) updates) =>
      super.copyWith((message) => updates(message as ResChannelTelegramConnect))
          as ResChannelTelegramConnect;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ResChannelTelegramConnect() / ResChannelTelegramConnect.new instead')
  static ResChannelTelegramConnect create() => ResChannelTelegramConnect._();
  static $pb.GeneratedMessage $_createMessage() =>
      ResChannelTelegramConnect._();
  @$core.override
  ResChannelTelegramConnect createEmptyInstance() =>
      ResChannelTelegramConnect._();
  @$core.pragma('dart2js:noInline')
  static ResChannelTelegramConnect getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResChannelTelegramConnect>(
          ResChannelTelegramConnect.$_createMessage);
  static ResChannelTelegramConnect? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get botIid => $_getI64(0);
  @$pb.TagNumber(1)
  set botIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasBotIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearBotIid() => $_clearField(1);

  @$pb.TagNumber(2)
  BotChannelDoc get channel => $_getN(1);
  @$pb.TagNumber(2)
  set channel(BotChannelDoc value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasChannel() => $_has(1);
  @$pb.TagNumber(2)
  void clearChannel() => $_clearField(2);
  @$pb.TagNumber(2)
  BotChannelDoc ensureChannel() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.String get webhookUrl => $_getSZ(2);
  @$pb.TagNumber(3)
  set webhookUrl($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasWebhookUrl() => $_has(2);
  @$pb.TagNumber(3)
  void clearWebhookUrl() => $_clearField(3);
}

class ReqChannelWhatsappMetaConnect extends $pb.GeneratedMessage {
  factory ReqChannelWhatsappMetaConnect({
    $fixnum.Int64? botIid,
    $core.String? accessToken,
    $core.String? phoneNumberId,
  }) {
    final result = ReqChannelWhatsappMetaConnect._();
    if (botIid != null) result.botIid = botIid;
    if (accessToken != null) result.accessToken = accessToken;
    if (phoneNumberId != null) result.phoneNumberId = phoneNumberId;
    return result;
  }

  ReqChannelWhatsappMetaConnect._();

  factory ReqChannelWhatsappMetaConnect.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqChannelWhatsappMetaConnect()..mergeFromBuffer(data, registry);
  factory ReqChannelWhatsappMetaConnect.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqChannelWhatsappMetaConnect()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqChannelWhatsappMetaConnect',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqChannelWhatsappMetaConnect.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'botIid')
    ..aOS(2, _omitFieldNames ? '' : 'accessToken')
    ..aOS(3, _omitFieldNames ? '' : 'phoneNumberId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqChannelWhatsappMetaConnect clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqChannelWhatsappMetaConnect copyWith(
          void Function(ReqChannelWhatsappMetaConnect) updates) =>
      super.copyWith(
              (message) => updates(message as ReqChannelWhatsappMetaConnect))
          as ReqChannelWhatsappMetaConnect;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ReqChannelWhatsappMetaConnect() / ReqChannelWhatsappMetaConnect.new instead')
  static ReqChannelWhatsappMetaConnect create() =>
      ReqChannelWhatsappMetaConnect._();
  static $pb.GeneratedMessage $_createMessage() =>
      ReqChannelWhatsappMetaConnect._();
  @$core.override
  ReqChannelWhatsappMetaConnect createEmptyInstance() =>
      ReqChannelWhatsappMetaConnect._();
  @$core.pragma('dart2js:noInline')
  static ReqChannelWhatsappMetaConnect getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqChannelWhatsappMetaConnect>(
          ReqChannelWhatsappMetaConnect.$_createMessage);
  static ReqChannelWhatsappMetaConnect? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get botIid => $_getI64(0);
  @$pb.TagNumber(1)
  set botIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasBotIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearBotIid() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get accessToken => $_getSZ(1);
  @$pb.TagNumber(2)
  set accessToken($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAccessToken() => $_has(1);
  @$pb.TagNumber(2)
  void clearAccessToken() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get phoneNumberId => $_getSZ(2);
  @$pb.TagNumber(3)
  set phoneNumberId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPhoneNumberId() => $_has(2);
  @$pb.TagNumber(3)
  void clearPhoneNumberId() => $_clearField(3);
}

class ResChannelWhatsappMetaConnect extends $pb.GeneratedMessage {
  factory ResChannelWhatsappMetaConnect({
    $fixnum.Int64? botIid,
    BotChannelDoc? channel,
    $core.String? webhookUrl,
    $core.String? verifyToken,
  }) {
    final result = ResChannelWhatsappMetaConnect._();
    if (botIid != null) result.botIid = botIid;
    if (channel != null) result.channel = channel;
    if (webhookUrl != null) result.webhookUrl = webhookUrl;
    if (verifyToken != null) result.verifyToken = verifyToken;
    return result;
  }

  ResChannelWhatsappMetaConnect._();

  factory ResChannelWhatsappMetaConnect.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResChannelWhatsappMetaConnect()..mergeFromBuffer(data, registry);
  factory ResChannelWhatsappMetaConnect.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResChannelWhatsappMetaConnect()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResChannelWhatsappMetaConnect',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResChannelWhatsappMetaConnect.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'botIid')
    ..aOM<BotChannelDoc>(2, _omitFieldNames ? '' : 'channel',
        subBuilder: BotChannelDoc.$_createMessage)
    ..aOS(3, _omitFieldNames ? '' : 'webhookUrl')
    ..aOS(4, _omitFieldNames ? '' : 'verifyToken')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResChannelWhatsappMetaConnect clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResChannelWhatsappMetaConnect copyWith(
          void Function(ResChannelWhatsappMetaConnect) updates) =>
      super.copyWith(
              (message) => updates(message as ResChannelWhatsappMetaConnect))
          as ResChannelWhatsappMetaConnect;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ResChannelWhatsappMetaConnect() / ResChannelWhatsappMetaConnect.new instead')
  static ResChannelWhatsappMetaConnect create() =>
      ResChannelWhatsappMetaConnect._();
  static $pb.GeneratedMessage $_createMessage() =>
      ResChannelWhatsappMetaConnect._();
  @$core.override
  ResChannelWhatsappMetaConnect createEmptyInstance() =>
      ResChannelWhatsappMetaConnect._();
  @$core.pragma('dart2js:noInline')
  static ResChannelWhatsappMetaConnect getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResChannelWhatsappMetaConnect>(
          ResChannelWhatsappMetaConnect.$_createMessage);
  static ResChannelWhatsappMetaConnect? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get botIid => $_getI64(0);
  @$pb.TagNumber(1)
  set botIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasBotIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearBotIid() => $_clearField(1);

  @$pb.TagNumber(2)
  BotChannelDoc get channel => $_getN(1);
  @$pb.TagNumber(2)
  set channel(BotChannelDoc value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasChannel() => $_has(1);
  @$pb.TagNumber(2)
  void clearChannel() => $_clearField(2);
  @$pb.TagNumber(2)
  BotChannelDoc ensureChannel() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.String get webhookUrl => $_getSZ(2);
  @$pb.TagNumber(3)
  set webhookUrl($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasWebhookUrl() => $_has(2);
  @$pb.TagNumber(3)
  void clearWebhookUrl() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get verifyToken => $_getSZ(3);
  @$pb.TagNumber(4)
  set verifyToken($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasVerifyToken() => $_has(3);
  @$pb.TagNumber(4)
  void clearVerifyToken() => $_clearField(4);
}

class ChannelWebhookRes extends $pb.GeneratedMessage {
  factory ChannelWebhookRes({
    $core.String? status,
    $core.String? message,
    $fixnum.Int64? chatId,
    $fixnum.Int64? peerIid,
  }) {
    final result = ChannelWebhookRes._();
    if (status != null) result.status = status;
    if (message != null) result.message = message;
    if (chatId != null) result.chatId = chatId;
    if (peerIid != null) result.peerIid = peerIid;
    return result;
  }

  ChannelWebhookRes._();

  factory ChannelWebhookRes.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ChannelWebhookRes()..mergeFromBuffer(data, registry);
  factory ChannelWebhookRes.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ChannelWebhookRes()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ChannelWebhookRes',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ChannelWebhookRes.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'status')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..aInt64(3, _omitFieldNames ? '' : 'chatId')
    ..aInt64(4, _omitFieldNames ? '' : 'peerIid')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChannelWebhookRes clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChannelWebhookRes copyWith(void Function(ChannelWebhookRes) updates) =>
      super.copyWith((message) => updates(message as ChannelWebhookRes))
          as ChannelWebhookRes;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ChannelWebhookRes() / ChannelWebhookRes.new instead')
  static ChannelWebhookRes create() => ChannelWebhookRes._();
  static $pb.GeneratedMessage $_createMessage() => ChannelWebhookRes._();
  @$core.override
  ChannelWebhookRes createEmptyInstance() => ChannelWebhookRes._();
  @$core.pragma('dart2js:noInline')
  static ChannelWebhookRes getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ChannelWebhookRes>(
          ChannelWebhookRes.$_createMessage);
  static ChannelWebhookRes? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get status => $_getSZ(0);
  @$pb.TagNumber(1)
  set status($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasStatus() => $_has(0);
  @$pb.TagNumber(1)
  void clearStatus() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get chatId => $_getI64(2);
  @$pb.TagNumber(3)
  set chatId($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasChatId() => $_has(2);
  @$pb.TagNumber(3)
  void clearChatId() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get peerIid => $_getI64(3);
  @$pb.TagNumber(4)
  set peerIid($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPeerIid() => $_has(3);
  @$pb.TagNumber(4)
  void clearPeerIid() => $_clearField(4);
}

class ReqChannelWhatsappPairStart extends $pb.GeneratedMessage {
  factory ReqChannelWhatsappPairStart({
    $fixnum.Int64? botIid,
    $core.String? channelId,
  }) {
    final result = ReqChannelWhatsappPairStart._();
    if (botIid != null) result.botIid = botIid;
    if (channelId != null) result.channelId = channelId;
    return result;
  }

  ReqChannelWhatsappPairStart._();

  factory ReqChannelWhatsappPairStart.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqChannelWhatsappPairStart()..mergeFromBuffer(data, registry);
  factory ReqChannelWhatsappPairStart.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqChannelWhatsappPairStart()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqChannelWhatsappPairStart',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqChannelWhatsappPairStart.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'botIid')
    ..aOS(2, _omitFieldNames ? '' : 'channelId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqChannelWhatsappPairStart clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqChannelWhatsappPairStart copyWith(
          void Function(ReqChannelWhatsappPairStart) updates) =>
      super.copyWith(
              (message) => updates(message as ReqChannelWhatsappPairStart))
          as ReqChannelWhatsappPairStart;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ReqChannelWhatsappPairStart() / ReqChannelWhatsappPairStart.new instead')
  static ReqChannelWhatsappPairStart create() =>
      ReqChannelWhatsappPairStart._();
  static $pb.GeneratedMessage $_createMessage() =>
      ReqChannelWhatsappPairStart._();
  @$core.override
  ReqChannelWhatsappPairStart createEmptyInstance() =>
      ReqChannelWhatsappPairStart._();
  @$core.pragma('dart2js:noInline')
  static ReqChannelWhatsappPairStart getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqChannelWhatsappPairStart>(
          ReqChannelWhatsappPairStart.$_createMessage);
  static ReqChannelWhatsappPairStart? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get botIid => $_getI64(0);
  @$pb.TagNumber(1)
  set botIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasBotIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearBotIid() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get channelId => $_getSZ(1);
  @$pb.TagNumber(2)
  set channelId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasChannelId() => $_has(1);
  @$pb.TagNumber(2)
  void clearChannelId() => $_clearField(2);
}

class ReqChannelWhatsappPairWatch extends $pb.GeneratedMessage {
  factory ReqChannelWhatsappPairWatch({
    $fixnum.Int64? botIid,
    $core.String? channelId,
  }) {
    final result = ReqChannelWhatsappPairWatch._();
    if (botIid != null) result.botIid = botIid;
    if (channelId != null) result.channelId = channelId;
    return result;
  }

  ReqChannelWhatsappPairWatch._();

  factory ReqChannelWhatsappPairWatch.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqChannelWhatsappPairWatch()..mergeFromBuffer(data, registry);
  factory ReqChannelWhatsappPairWatch.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqChannelWhatsappPairWatch()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqChannelWhatsappPairWatch',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqChannelWhatsappPairWatch.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'botIid')
    ..aOS(2, _omitFieldNames ? '' : 'channelId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqChannelWhatsappPairWatch clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqChannelWhatsappPairWatch copyWith(
          void Function(ReqChannelWhatsappPairWatch) updates) =>
      super.copyWith(
              (message) => updates(message as ReqChannelWhatsappPairWatch))
          as ReqChannelWhatsappPairWatch;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ReqChannelWhatsappPairWatch() / ReqChannelWhatsappPairWatch.new instead')
  static ReqChannelWhatsappPairWatch create() =>
      ReqChannelWhatsappPairWatch._();
  static $pb.GeneratedMessage $_createMessage() =>
      ReqChannelWhatsappPairWatch._();
  @$core.override
  ReqChannelWhatsappPairWatch createEmptyInstance() =>
      ReqChannelWhatsappPairWatch._();
  @$core.pragma('dart2js:noInline')
  static ReqChannelWhatsappPairWatch getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqChannelWhatsappPairWatch>(
          ReqChannelWhatsappPairWatch.$_createMessage);
  static ReqChannelWhatsappPairWatch? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get botIid => $_getI64(0);
  @$pb.TagNumber(1)
  set botIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasBotIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearBotIid() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get channelId => $_getSZ(1);
  @$pb.TagNumber(2)
  set channelId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasChannelId() => $_has(1);
  @$pb.TagNumber(2)
  void clearChannelId() => $_clearField(2);
}

class ReqChannelWhatsappPairAbort extends $pb.GeneratedMessage {
  factory ReqChannelWhatsappPairAbort({
    $fixnum.Int64? botIid,
    $core.String? channelId,
  }) {
    final result = ReqChannelWhatsappPairAbort._();
    if (botIid != null) result.botIid = botIid;
    if (channelId != null) result.channelId = channelId;
    return result;
  }

  ReqChannelWhatsappPairAbort._();

  factory ReqChannelWhatsappPairAbort.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqChannelWhatsappPairAbort()..mergeFromBuffer(data, registry);
  factory ReqChannelWhatsappPairAbort.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqChannelWhatsappPairAbort()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqChannelWhatsappPairAbort',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqChannelWhatsappPairAbort.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'botIid')
    ..aOS(2, _omitFieldNames ? '' : 'channelId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqChannelWhatsappPairAbort clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqChannelWhatsappPairAbort copyWith(
          void Function(ReqChannelWhatsappPairAbort) updates) =>
      super.copyWith(
              (message) => updates(message as ReqChannelWhatsappPairAbort))
          as ReqChannelWhatsappPairAbort;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ReqChannelWhatsappPairAbort() / ReqChannelWhatsappPairAbort.new instead')
  static ReqChannelWhatsappPairAbort create() =>
      ReqChannelWhatsappPairAbort._();
  static $pb.GeneratedMessage $_createMessage() =>
      ReqChannelWhatsappPairAbort._();
  @$core.override
  ReqChannelWhatsappPairAbort createEmptyInstance() =>
      ReqChannelWhatsappPairAbort._();
  @$core.pragma('dart2js:noInline')
  static ReqChannelWhatsappPairAbort getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqChannelWhatsappPairAbort>(
          ReqChannelWhatsappPairAbort.$_createMessage);
  static ReqChannelWhatsappPairAbort? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get botIid => $_getI64(0);
  @$pb.TagNumber(1)
  set botIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasBotIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearBotIid() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get channelId => $_getSZ(1);
  @$pb.TagNumber(2)
  set channelId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasChannelId() => $_has(1);
  @$pb.TagNumber(2)
  void clearChannelId() => $_clearField(2);
}

class ResChannelWhatsappPair extends $pb.GeneratedMessage {
  factory ResChannelWhatsappPair({
    $core.bool? ok,
    $core.String? error,
    $fixnum.Int64? botIid,
    BotChannelDoc? channel,
    $core.String? qrRaw,
    $core.String? phone,
  }) {
    final result = ResChannelWhatsappPair._();
    if (ok != null) result.ok = ok;
    if (error != null) result.error = error;
    if (botIid != null) result.botIid = botIid;
    if (channel != null) result.channel = channel;
    if (qrRaw != null) result.qrRaw = qrRaw;
    if (phone != null) result.phone = phone;
    return result;
  }

  ResChannelWhatsappPair._();

  factory ResChannelWhatsappPair.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResChannelWhatsappPair()..mergeFromBuffer(data, registry);
  factory ResChannelWhatsappPair.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResChannelWhatsappPair()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResChannelWhatsappPair',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResChannelWhatsappPair.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'ok')
    ..aOS(2, _omitFieldNames ? '' : 'error')
    ..aInt64(3, _omitFieldNames ? '' : 'botIid')
    ..aOM<BotChannelDoc>(4, _omitFieldNames ? '' : 'channel',
        subBuilder: BotChannelDoc.$_createMessage)
    ..aOS(5, _omitFieldNames ? '' : 'qrRaw')
    ..aOS(6, _omitFieldNames ? '' : 'phone')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResChannelWhatsappPair clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResChannelWhatsappPair copyWith(
          void Function(ResChannelWhatsappPair) updates) =>
      super.copyWith((message) => updates(message as ResChannelWhatsappPair))
          as ResChannelWhatsappPair;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ResChannelWhatsappPair() / ResChannelWhatsappPair.new instead')
  static ResChannelWhatsappPair create() => ResChannelWhatsappPair._();
  static $pb.GeneratedMessage $_createMessage() => ResChannelWhatsappPair._();
  @$core.override
  ResChannelWhatsappPair createEmptyInstance() => ResChannelWhatsappPair._();
  @$core.pragma('dart2js:noInline')
  static ResChannelWhatsappPair getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResChannelWhatsappPair>(
          ResChannelWhatsappPair.$_createMessage);
  static ResChannelWhatsappPair? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get ok => $_getBF(0);
  @$pb.TagNumber(1)
  set ok($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOk() => $_has(0);
  @$pb.TagNumber(1)
  void clearOk() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get error => $_getSZ(1);
  @$pb.TagNumber(2)
  set error($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get botIid => $_getI64(2);
  @$pb.TagNumber(3)
  set botIid($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasBotIid() => $_has(2);
  @$pb.TagNumber(3)
  void clearBotIid() => $_clearField(3);

  @$pb.TagNumber(4)
  BotChannelDoc get channel => $_getN(3);
  @$pb.TagNumber(4)
  set channel(BotChannelDoc value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasChannel() => $_has(3);
  @$pb.TagNumber(4)
  void clearChannel() => $_clearField(4);
  @$pb.TagNumber(4)
  BotChannelDoc ensureChannel() => $_ensure(3);

  @$pb.TagNumber(5)
  $core.String get qrRaw => $_getSZ(4);
  @$pb.TagNumber(5)
  set qrRaw($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasQrRaw() => $_has(4);
  @$pb.TagNumber(5)
  void clearQrRaw() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get phone => $_getSZ(5);
  @$pb.TagNumber(6)
  set phone($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasPhone() => $_has(5);
  @$pb.TagNumber(6)
  void clearPhone() => $_clearField(6);
}

class ReqChannelDisconnect extends $pb.GeneratedMessage {
  factory ReqChannelDisconnect({
    $fixnum.Int64? botIid,
    $core.String? channelId,
  }) {
    final result = ReqChannelDisconnect._();
    if (botIid != null) result.botIid = botIid;
    if (channelId != null) result.channelId = channelId;
    return result;
  }

  ReqChannelDisconnect._();

  factory ReqChannelDisconnect.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqChannelDisconnect()..mergeFromBuffer(data, registry);
  factory ReqChannelDisconnect.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqChannelDisconnect()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqChannelDisconnect',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqChannelDisconnect.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'botIid')
    ..aOS(2, _omitFieldNames ? '' : 'channelId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqChannelDisconnect clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqChannelDisconnect copyWith(void Function(ReqChannelDisconnect) updates) =>
      super.copyWith((message) => updates(message as ReqChannelDisconnect))
          as ReqChannelDisconnect;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ReqChannelDisconnect() / ReqChannelDisconnect.new instead')
  static ReqChannelDisconnect create() => ReqChannelDisconnect._();
  static $pb.GeneratedMessage $_createMessage() => ReqChannelDisconnect._();
  @$core.override
  ReqChannelDisconnect createEmptyInstance() => ReqChannelDisconnect._();
  @$core.pragma('dart2js:noInline')
  static ReqChannelDisconnect getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqChannelDisconnect>(
          ReqChannelDisconnect.$_createMessage);
  static ReqChannelDisconnect? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get botIid => $_getI64(0);
  @$pb.TagNumber(1)
  set botIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasBotIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearBotIid() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get channelId => $_getSZ(1);
  @$pb.TagNumber(2)
  set channelId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasChannelId() => $_has(1);
  @$pb.TagNumber(2)
  void clearChannelId() => $_clearField(2);
}

class ResChannelDisconnect extends $pb.GeneratedMessage {
  factory ResChannelDisconnect({
    $core.bool? ok,
    $core.String? error,
    $fixnum.Int64? botIid,
    $core.String? channelId,
  }) {
    final result = ResChannelDisconnect._();
    if (ok != null) result.ok = ok;
    if (error != null) result.error = error;
    if (botIid != null) result.botIid = botIid;
    if (channelId != null) result.channelId = channelId;
    return result;
  }

  ResChannelDisconnect._();

  factory ResChannelDisconnect.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResChannelDisconnect()..mergeFromBuffer(data, registry);
  factory ResChannelDisconnect.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResChannelDisconnect()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResChannelDisconnect',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResChannelDisconnect.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'ok')
    ..aOS(2, _omitFieldNames ? '' : 'error')
    ..aInt64(3, _omitFieldNames ? '' : 'botIid')
    ..aOS(4, _omitFieldNames ? '' : 'channelId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResChannelDisconnect clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResChannelDisconnect copyWith(void Function(ResChannelDisconnect) updates) =>
      super.copyWith((message) => updates(message as ResChannelDisconnect))
          as ResChannelDisconnect;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ResChannelDisconnect() / ResChannelDisconnect.new instead')
  static ResChannelDisconnect create() => ResChannelDisconnect._();
  static $pb.GeneratedMessage $_createMessage() => ResChannelDisconnect._();
  @$core.override
  ResChannelDisconnect createEmptyInstance() => ResChannelDisconnect._();
  @$core.pragma('dart2js:noInline')
  static ResChannelDisconnect getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResChannelDisconnect>(
          ResChannelDisconnect.$_createMessage);
  static ResChannelDisconnect? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get ok => $_getBF(0);
  @$pb.TagNumber(1)
  set ok($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOk() => $_has(0);
  @$pb.TagNumber(1)
  void clearOk() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get error => $_getSZ(1);
  @$pb.TagNumber(2)
  set error($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get botIid => $_getI64(2);
  @$pb.TagNumber(3)
  set botIid($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasBotIid() => $_has(2);
  @$pb.TagNumber(3)
  void clearBotIid() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get channelId => $_getSZ(3);
  @$pb.TagNumber(4)
  set channelId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasChannelId() => $_has(3);
  @$pb.TagNumber(4)
  void clearChannelId() => $_clearField(4);
}

/// Unsolicited WS push while pair dialog open (from NATS ev → WS fanout)
class ChannelPairPush extends $pb.GeneratedMessage {
  factory ChannelPairPush({
    $fixnum.Int64? botIid,
    $core.String? channelId,
    $core.String? status,
    $core.String? qrRaw,
    $core.String? phone,
    $core.String? errorMessage,
  }) {
    final result = ChannelPairPush._();
    if (botIid != null) result.botIid = botIid;
    if (channelId != null) result.channelId = channelId;
    if (status != null) result.status = status;
    if (qrRaw != null) result.qrRaw = qrRaw;
    if (phone != null) result.phone = phone;
    if (errorMessage != null) result.errorMessage = errorMessage;
    return result;
  }

  ChannelPairPush._();

  factory ChannelPairPush.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ChannelPairPush()..mergeFromBuffer(data, registry);
  factory ChannelPairPush.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ChannelPairPush()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ChannelPairPush',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ChannelPairPush.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'botIid')
    ..aOS(2, _omitFieldNames ? '' : 'channelId')
    ..aOS(3, _omitFieldNames ? '' : 'status')
    ..aOS(4, _omitFieldNames ? '' : 'qrRaw')
    ..aOS(5, _omitFieldNames ? '' : 'phone')
    ..aOS(6, _omitFieldNames ? '' : 'errorMessage')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChannelPairPush clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChannelPairPush copyWith(void Function(ChannelPairPush) updates) =>
      super.copyWith((message) => updates(message as ChannelPairPush))
          as ChannelPairPush;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ChannelPairPush() / ChannelPairPush.new instead')
  static ChannelPairPush create() => ChannelPairPush._();
  static $pb.GeneratedMessage $_createMessage() => ChannelPairPush._();
  @$core.override
  ChannelPairPush createEmptyInstance() => ChannelPairPush._();
  @$core.pragma('dart2js:noInline')
  static ChannelPairPush getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ChannelPairPush>(
          ChannelPairPush.$_createMessage);
  static ChannelPairPush? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get botIid => $_getI64(0);
  @$pb.TagNumber(1)
  set botIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasBotIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearBotIid() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get channelId => $_getSZ(1);
  @$pb.TagNumber(2)
  set channelId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasChannelId() => $_has(1);
  @$pb.TagNumber(2)
  void clearChannelId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get status => $_getSZ(2);
  @$pb.TagNumber(3)
  set status($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasStatus() => $_has(2);
  @$pb.TagNumber(3)
  void clearStatus() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get qrRaw => $_getSZ(3);
  @$pb.TagNumber(4)
  set qrRaw($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasQrRaw() => $_has(3);
  @$pb.TagNumber(4)
  void clearQrRaw() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get phone => $_getSZ(4);
  @$pb.TagNumber(5)
  set phone($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasPhone() => $_has(4);
  @$pb.TagNumber(5)
  void clearPhone() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get errorMessage => $_getSZ(5);
  @$pb.TagNumber(6)
  set errorMessage($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasErrorMessage() => $_has(5);
  @$pb.TagNumber(6)
  void clearErrorMessage() => $_clearField(6);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
