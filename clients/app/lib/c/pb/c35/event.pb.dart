// This is a generated file - do not edit.
//
// Generated from c35/event.proto.

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

class Event extends $pb.GeneratedMessage {
  factory Event({
    $fixnum.Int64? id,
    $core.String? eventKind,
    $core.String? class_3,
    $core.String? subject,
    $fixnum.Int64? ownerIid,
    $core.String? dv,
    $core.String? slug,
    $core.String? text,
    $core.String? metaJson,
    $fixnum.Int64? createdTsMs,
  }) {
    final result = Event._();
    if (id != null) result.id = id;
    if (eventKind != null) result.eventKind = eventKind;
    if (class_3 != null) result.class_3 = class_3;
    if (subject != null) result.subject = subject;
    if (ownerIid != null) result.ownerIid = ownerIid;
    if (dv != null) result.dv = dv;
    if (slug != null) result.slug = slug;
    if (text != null) result.text = text;
    if (metaJson != null) result.metaJson = metaJson;
    if (createdTsMs != null) result.createdTsMs = createdTsMs;
    return result;
  }

  Event._();

  factory Event.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Event()..mergeFromBuffer(data, registry);
  factory Event.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Event()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Event',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: Event.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'eventKind')
    ..aOS(3, _omitFieldNames ? '' : 'class')
    ..aOS(4, _omitFieldNames ? '' : 'subject')
    ..aInt64(5, _omitFieldNames ? '' : 'ownerIid')
    ..aOS(6, _omitFieldNames ? '' : 'dv')
    ..aOS(7, _omitFieldNames ? '' : 'slug')
    ..aOS(8, _omitFieldNames ? '' : 'text')
    ..aOS(9, _omitFieldNames ? '' : 'metaJson')
    ..aInt64(10, _omitFieldNames ? '' : 'createdTsMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Event clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Event copyWith(void Function(Event) updates) =>
      super.copyWith((message) => updates(message as Event)) as Event;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Event() / Event.new instead')
  static Event create() => Event._();
  static $pb.GeneratedMessage $_createMessage() => Event._();
  @$core.override
  Event createEmptyInstance() => Event._();
  @$core.pragma('dart2js:noInline')
  static Event getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Event>(Event.$_createMessage);
  static Event? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get eventKind => $_getSZ(1);
  @$pb.TagNumber(2)
  set eventKind($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEventKind() => $_has(1);
  @$pb.TagNumber(2)
  void clearEventKind() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get class_3 => $_getSZ(2);
  @$pb.TagNumber(3)
  set class_3($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasClass_3() => $_has(2);
  @$pb.TagNumber(3)
  void clearClass_3() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get subject => $_getSZ(3);
  @$pb.TagNumber(4)
  set subject($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSubject() => $_has(3);
  @$pb.TagNumber(4)
  void clearSubject() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get ownerIid => $_getI64(4);
  @$pb.TagNumber(5)
  set ownerIid($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasOwnerIid() => $_has(4);
  @$pb.TagNumber(5)
  void clearOwnerIid() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get dv => $_getSZ(5);
  @$pb.TagNumber(6)
  set dv($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasDv() => $_has(5);
  @$pb.TagNumber(6)
  void clearDv() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get slug => $_getSZ(6);
  @$pb.TagNumber(7)
  set slug($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasSlug() => $_has(6);
  @$pb.TagNumber(7)
  void clearSlug() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get text => $_getSZ(7);
  @$pb.TagNumber(8)
  set text($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasText() => $_has(7);
  @$pb.TagNumber(8)
  void clearText() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get metaJson => $_getSZ(8);
  @$pb.TagNumber(9)
  set metaJson($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasMetaJson() => $_has(8);
  @$pb.TagNumber(9)
  void clearMetaJson() => $_clearField(9);

  @$pb.TagNumber(10)
  $fixnum.Int64 get createdTsMs => $_getI64(9);
  @$pb.TagNumber(10)
  set createdTsMs($fixnum.Int64 value) => $_setInt64(9, value);
  @$pb.TagNumber(10)
  $core.bool hasCreatedTsMs() => $_has(9);
  @$pb.TagNumber(10)
  void clearCreatedTsMs() => $_clearField(10);
}

class EventPush extends $pb.GeneratedMessage {
  factory EventPush({
    Event? event,
  }) {
    final result = EventPush._();
    if (event != null) result.event = event;
    return result;
  }

  EventPush._();

  factory EventPush.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EventPush()..mergeFromBuffer(data, registry);
  factory EventPush.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EventPush()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EventPush',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: EventPush.$_createMessage)
    ..aOM<Event>(1, _omitFieldNames ? '' : 'event',
        subBuilder: Event.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EventPush clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EventPush copyWith(void Function(EventPush) updates) =>
      super.copyWith((message) => updates(message as EventPush)) as EventPush;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use EventPush() / EventPush.new instead')
  static EventPush create() => EventPush._();
  static $pb.GeneratedMessage $_createMessage() => EventPush._();
  @$core.override
  EventPush createEmptyInstance() => EventPush._();
  @$core.pragma('dart2js:noInline')
  static EventPush getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EventPush>(EventPush.$_createMessage);
  static EventPush? _defaultInstance;

  @$pb.TagNumber(1)
  Event get event => $_getN(0);
  @$pb.TagNumber(1)
  set event(Event value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasEvent() => $_has(0);
  @$pb.TagNumber(1)
  void clearEvent() => $_clearField(1);
  @$pb.TagNumber(1)
  Event ensureEvent() => $_ensure(0);
}

class EventUserSession extends $pb.GeneratedMessage {
  factory EventUserSession({
    $core.String? method,
    $core.String? platform,
    $fixnum.Int64? appBuild,
    $fixnum.Int64? sessId,
    $fixnum.Int64? connId,
  }) {
    final result = EventUserSession._();
    if (method != null) result.method = method;
    if (platform != null) result.platform = platform;
    if (appBuild != null) result.appBuild = appBuild;
    if (sessId != null) result.sessId = sessId;
    if (connId != null) result.connId = connId;
    return result;
  }

  EventUserSession._();

  factory EventUserSession.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EventUserSession()..mergeFromBuffer(data, registry);
  factory EventUserSession.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EventUserSession()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EventUserSession',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: EventUserSession.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'method')
    ..aOS(2, _omitFieldNames ? '' : 'platform')
    ..aInt64(3, _omitFieldNames ? '' : 'appBuild')
    ..aInt64(4, _omitFieldNames ? '' : 'sessId')
    ..aInt64(5, _omitFieldNames ? '' : 'connId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EventUserSession clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EventUserSession copyWith(void Function(EventUserSession) updates) =>
      super.copyWith((message) => updates(message as EventUserSession))
          as EventUserSession;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use EventUserSession() / EventUserSession.new instead')
  static EventUserSession create() => EventUserSession._();
  static $pb.GeneratedMessage $_createMessage() => EventUserSession._();
  @$core.override
  EventUserSession createEmptyInstance() => EventUserSession._();
  @$core.pragma('dart2js:noInline')
  static EventUserSession getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<EventUserSession>(
          EventUserSession.$_createMessage);
  static EventUserSession? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get method => $_getSZ(0);
  @$pb.TagNumber(1)
  set method($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMethod() => $_has(0);
  @$pb.TagNumber(1)
  void clearMethod() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get platform => $_getSZ(1);
  @$pb.TagNumber(2)
  set platform($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPlatform() => $_has(1);
  @$pb.TagNumber(2)
  void clearPlatform() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get appBuild => $_getI64(2);
  @$pb.TagNumber(3)
  set appBuild($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAppBuild() => $_has(2);
  @$pb.TagNumber(3)
  void clearAppBuild() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get sessId => $_getI64(3);
  @$pb.TagNumber(4)
  set sessId($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSessId() => $_has(3);
  @$pb.TagNumber(4)
  void clearSessId() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get connId => $_getI64(4);
  @$pb.TagNumber(5)
  set connId($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasConnId() => $_has(4);
  @$pb.TagNumber(5)
  void clearConnId() => $_clearField(5);
}

class EventConsumptionMeal extends $pb.GeneratedMessage {
  factory EventConsumptionMeal({
    $fixnum.Int64? consumptionId,
    $core.String? dayId,
    $core.int? itemCount,
    $core.int? calories,
    $core.String? source,
    $core.String? mealFingerprint,
  }) {
    final result = EventConsumptionMeal._();
    if (consumptionId != null) result.consumptionId = consumptionId;
    if (dayId != null) result.dayId = dayId;
    if (itemCount != null) result.itemCount = itemCount;
    if (calories != null) result.calories = calories;
    if (source != null) result.source = source;
    if (mealFingerprint != null) result.mealFingerprint = mealFingerprint;
    return result;
  }

  EventConsumptionMeal._();

  factory EventConsumptionMeal.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EventConsumptionMeal()..mergeFromBuffer(data, registry);
  factory EventConsumptionMeal.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EventConsumptionMeal()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EventConsumptionMeal',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: EventConsumptionMeal.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'consumptionId')
    ..aOS(2, _omitFieldNames ? '' : 'dayId')
    ..aI(3, _omitFieldNames ? '' : 'itemCount')
    ..aI(4, _omitFieldNames ? '' : 'calories')
    ..aOS(5, _omitFieldNames ? '' : 'source')
    ..aOS(6, _omitFieldNames ? '' : 'mealFingerprint')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EventConsumptionMeal clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EventConsumptionMeal copyWith(void Function(EventConsumptionMeal) updates) =>
      super.copyWith((message) => updates(message as EventConsumptionMeal))
          as EventConsumptionMeal;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use EventConsumptionMeal() / EventConsumptionMeal.new instead')
  static EventConsumptionMeal create() => EventConsumptionMeal._();
  static $pb.GeneratedMessage $_createMessage() => EventConsumptionMeal._();
  @$core.override
  EventConsumptionMeal createEmptyInstance() => EventConsumptionMeal._();
  @$core.pragma('dart2js:noInline')
  static EventConsumptionMeal getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EventConsumptionMeal>(
          EventConsumptionMeal.$_createMessage);
  static EventConsumptionMeal? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get consumptionId => $_getI64(0);
  @$pb.TagNumber(1)
  set consumptionId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasConsumptionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearConsumptionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get dayId => $_getSZ(1);
  @$pb.TagNumber(2)
  set dayId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDayId() => $_has(1);
  @$pb.TagNumber(2)
  void clearDayId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get itemCount => $_getIZ(2);
  @$pb.TagNumber(3)
  set itemCount($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasItemCount() => $_has(2);
  @$pb.TagNumber(3)
  void clearItemCount() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get calories => $_getIZ(3);
  @$pb.TagNumber(4)
  set calories($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasCalories() => $_has(3);
  @$pb.TagNumber(4)
  void clearCalories() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get source => $_getSZ(4);
  @$pb.TagNumber(5)
  set source($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSource() => $_has(4);
  @$pb.TagNumber(5)
  void clearSource() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get mealFingerprint => $_getSZ(5);
  @$pb.TagNumber(6)
  set mealFingerprint($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasMealFingerprint() => $_has(5);
  @$pb.TagNumber(6)
  void clearMealFingerprint() => $_clearField(6);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
