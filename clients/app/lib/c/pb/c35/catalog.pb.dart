// This is a generated file - do not edit.
//
// Generated from c35/catalog.proto.

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

class TopicItem extends $pb.GeneratedMessage {
  factory TopicItem({
    $core.String? id,
    $core.String? labelKey,
    $core.String? inst,
    $core.String? extend,
    $core.int? sort,
    $core.bool? enabled,
  }) {
    final result = TopicItem._();
    if (id != null) result.id = id;
    if (labelKey != null) result.labelKey = labelKey;
    if (inst != null) result.inst = inst;
    if (extend != null) result.extend = extend;
    if (sort != null) result.sort = sort;
    if (enabled != null) result.enabled = enabled;
    return result;
  }

  TopicItem._();

  factory TopicItem.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TopicItem()..mergeFromBuffer(data, registry);
  factory TopicItem.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TopicItem()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TopicItem',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: TopicItem.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'labelKey')
    ..aOS(3, _omitFieldNames ? '' : 'inst')
    ..aOS(4, _omitFieldNames ? '' : 'extend')
    ..aI(5, _omitFieldNames ? '' : 'sort')
    ..aOB(6, _omitFieldNames ? '' : 'enabled')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TopicItem clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TopicItem copyWith(void Function(TopicItem) updates) =>
      super.copyWith((message) => updates(message as TopicItem)) as TopicItem;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use TopicItem() / TopicItem.new instead')
  static TopicItem create() => TopicItem._();
  static $pb.GeneratedMessage $_createMessage() => TopicItem._();
  @$core.override
  TopicItem createEmptyInstance() => TopicItem._();
  @$core.pragma('dart2js:noInline')
  static TopicItem getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TopicItem>(TopicItem.$_createMessage);
  static TopicItem? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get labelKey => $_getSZ(1);
  @$pb.TagNumber(2)
  set labelKey($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLabelKey() => $_has(1);
  @$pb.TagNumber(2)
  void clearLabelKey() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get inst => $_getSZ(2);
  @$pb.TagNumber(3)
  set inst($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasInst() => $_has(2);
  @$pb.TagNumber(3)
  void clearInst() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get extend => $_getSZ(3);
  @$pb.TagNumber(4)
  set extend($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasExtend() => $_has(3);
  @$pb.TagNumber(4)
  void clearExtend() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get sort => $_getIZ(4);
  @$pb.TagNumber(5)
  set sort($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSort() => $_has(4);
  @$pb.TagNumber(5)
  void clearSort() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get enabled => $_getBF(5);
  @$pb.TagNumber(6)
  set enabled($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasEnabled() => $_has(5);
  @$pb.TagNumber(6)
  void clearEnabled() => $_clearField(6);
}

class MentionItem extends $pb.GeneratedMessage {
  factory MentionItem({
    $core.String? id,
    $core.String? topicId,
    $core.String? instId,
    $core.String? icon,
    $core.String? color,
    $core.int? sort,
    $core.String? labelKey,
    $core.String? captionKey,
    $core.Iterable<$core.String>? searchTerms,
    $core.bool? enabled,
  }) {
    final result = MentionItem._();
    if (id != null) result.id = id;
    if (topicId != null) result.topicId = topicId;
    if (instId != null) result.instId = instId;
    if (icon != null) result.icon = icon;
    if (color != null) result.color = color;
    if (sort != null) result.sort = sort;
    if (labelKey != null) result.labelKey = labelKey;
    if (captionKey != null) result.captionKey = captionKey;
    if (searchTerms != null) result.searchTerms.addAll(searchTerms);
    if (enabled != null) result.enabled = enabled;
    return result;
  }

  MentionItem._();

  factory MentionItem.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MentionItem()..mergeFromBuffer(data, registry);
  factory MentionItem.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MentionItem()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MentionItem',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: MentionItem.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'topicId')
    ..aOS(3, _omitFieldNames ? '' : 'instId')
    ..aOS(4, _omitFieldNames ? '' : 'icon')
    ..aOS(5, _omitFieldNames ? '' : 'color')
    ..aI(6, _omitFieldNames ? '' : 'sort')
    ..aOS(7, _omitFieldNames ? '' : 'labelKey')
    ..aOS(8, _omitFieldNames ? '' : 'captionKey')
    ..pPS(9, _omitFieldNames ? '' : 'searchTerms')
    ..aOB(10, _omitFieldNames ? '' : 'enabled')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MentionItem clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MentionItem copyWith(void Function(MentionItem) updates) =>
      super.copyWith((message) => updates(message as MentionItem))
          as MentionItem;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use MentionItem() / MentionItem.new instead')
  static MentionItem create() => MentionItem._();
  static $pb.GeneratedMessage $_createMessage() => MentionItem._();
  @$core.override
  MentionItem createEmptyInstance() => MentionItem._();
  @$core.pragma('dart2js:noInline')
  static MentionItem getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MentionItem>(
          MentionItem.$_createMessage);
  static MentionItem? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get topicId => $_getSZ(1);
  @$pb.TagNumber(2)
  set topicId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTopicId() => $_has(1);
  @$pb.TagNumber(2)
  void clearTopicId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get instId => $_getSZ(2);
  @$pb.TagNumber(3)
  set instId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasInstId() => $_has(2);
  @$pb.TagNumber(3)
  void clearInstId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get icon => $_getSZ(3);
  @$pb.TagNumber(4)
  set icon($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasIcon() => $_has(3);
  @$pb.TagNumber(4)
  void clearIcon() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get color => $_getSZ(4);
  @$pb.TagNumber(5)
  set color($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasColor() => $_has(4);
  @$pb.TagNumber(5)
  void clearColor() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get sort => $_getIZ(5);
  @$pb.TagNumber(6)
  set sort($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasSort() => $_has(5);
  @$pb.TagNumber(6)
  void clearSort() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get labelKey => $_getSZ(6);
  @$pb.TagNumber(7)
  set labelKey($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasLabelKey() => $_has(6);
  @$pb.TagNumber(7)
  void clearLabelKey() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get captionKey => $_getSZ(7);
  @$pb.TagNumber(8)
  set captionKey($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasCaptionKey() => $_has(7);
  @$pb.TagNumber(8)
  void clearCaptionKey() => $_clearField(8);

  @$pb.TagNumber(9)
  $pb.PbList<$core.String> get searchTerms => $_getList(8);

  @$pb.TagNumber(10)
  $core.bool get enabled => $_getBF(9);
  @$pb.TagNumber(10)
  set enabled($core.bool value) => $_setBool(9, value);
  @$pb.TagNumber(10)
  $core.bool hasEnabled() => $_has(9);
  @$pb.TagNumber(10)
  void clearEnabled() => $_clearField(10);
}

class ReqTopicList extends $pb.GeneratedMessage {
  factory ReqTopicList() => ReqTopicList._();

  ReqTopicList._();

  factory ReqTopicList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqTopicList()..mergeFromBuffer(data, registry);
  factory ReqTopicList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqTopicList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqTopicList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqTopicList.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqTopicList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqTopicList copyWith(void Function(ReqTopicList) updates) =>
      super.copyWith((message) => updates(message as ReqTopicList))
          as ReqTopicList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqTopicList() / ReqTopicList.new instead')
  static ReqTopicList create() => ReqTopicList._();
  static $pb.GeneratedMessage $_createMessage() => ReqTopicList._();
  @$core.override
  ReqTopicList createEmptyInstance() => ReqTopicList._();
  @$core.pragma('dart2js:noInline')
  static ReqTopicList getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqTopicList>(
          ReqTopicList.$_createMessage);
  static ReqTopicList? _defaultInstance;
}

class ResTopicList extends $pb.GeneratedMessage {
  factory ResTopicList({
    $core.Iterable<TopicItem>? topics,
  }) {
    final result = ResTopicList._();
    if (topics != null) result.topics.addAll(topics);
    return result;
  }

  ResTopicList._();

  factory ResTopicList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResTopicList()..mergeFromBuffer(data, registry);
  factory ResTopicList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResTopicList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResTopicList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResTopicList.$_createMessage)
    ..pPM<TopicItem>(1, _omitFieldNames ? '' : 'topics',
        subBuilder: TopicItem.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResTopicList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResTopicList copyWith(void Function(ResTopicList) updates) =>
      super.copyWith((message) => updates(message as ResTopicList))
          as ResTopicList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResTopicList() / ResTopicList.new instead')
  static ResTopicList create() => ResTopicList._();
  static $pb.GeneratedMessage $_createMessage() => ResTopicList._();
  @$core.override
  ResTopicList createEmptyInstance() => ResTopicList._();
  @$core.pragma('dart2js:noInline')
  static ResTopicList getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResTopicList>(
          ResTopicList.$_createMessage);
  static ResTopicList? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<TopicItem> get topics => $_getList(0);
}

class ReqMentionList extends $pb.GeneratedMessage {
  factory ReqMentionList() => ReqMentionList._();

  ReqMentionList._();

  factory ReqMentionList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqMentionList()..mergeFromBuffer(data, registry);
  factory ReqMentionList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqMentionList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqMentionList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqMentionList.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqMentionList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqMentionList copyWith(void Function(ReqMentionList) updates) =>
      super.copyWith((message) => updates(message as ReqMentionList))
          as ReqMentionList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqMentionList() / ReqMentionList.new instead')
  static ReqMentionList create() => ReqMentionList._();
  static $pb.GeneratedMessage $_createMessage() => ReqMentionList._();
  @$core.override
  ReqMentionList createEmptyInstance() => ReqMentionList._();
  @$core.pragma('dart2js:noInline')
  static ReqMentionList getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqMentionList>(
          ReqMentionList.$_createMessage);
  static ReqMentionList? _defaultInstance;
}

class ResMentionList extends $pb.GeneratedMessage {
  factory ResMentionList({
    $core.Iterable<MentionItem>? mentions,
  }) {
    final result = ResMentionList._();
    if (mentions != null) result.mentions.addAll(mentions);
    return result;
  }

  ResMentionList._();

  factory ResMentionList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResMentionList()..mergeFromBuffer(data, registry);
  factory ResMentionList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResMentionList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResMentionList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResMentionList.$_createMessage)
    ..pPM<MentionItem>(1, _omitFieldNames ? '' : 'mentions',
        subBuilder: MentionItem.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResMentionList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResMentionList copyWith(void Function(ResMentionList) updates) =>
      super.copyWith((message) => updates(message as ResMentionList))
          as ResMentionList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResMentionList() / ResMentionList.new instead')
  static ResMentionList create() => ResMentionList._();
  static $pb.GeneratedMessage $_createMessage() => ResMentionList._();
  @$core.override
  ResMentionList createEmptyInstance() => ResMentionList._();
  @$core.pragma('dart2js:noInline')
  static ResMentionList getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResMentionList>(
          ResMentionList.$_createMessage);
  static ResMentionList? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<MentionItem> get mentions => $_getList(0);
}

class ReqTranslationGet extends $pb.GeneratedMessage {
  factory ReqTranslationGet({
    $core.String? lang,
    $core.Iterable<$core.String>? categories,
    $core.Iterable<$core.String>? keys,
  }) {
    final result = ReqTranslationGet._();
    if (lang != null) result.lang = lang;
    if (categories != null) result.categories.addAll(categories);
    if (keys != null) result.keys.addAll(keys);
    return result;
  }

  ReqTranslationGet._();

  factory ReqTranslationGet.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqTranslationGet()..mergeFromBuffer(data, registry);
  factory ReqTranslationGet.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqTranslationGet()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqTranslationGet',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqTranslationGet.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'lang')
    ..pPS(2, _omitFieldNames ? '' : 'categories')
    ..pPS(3, _omitFieldNames ? '' : 'keys')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqTranslationGet clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqTranslationGet copyWith(void Function(ReqTranslationGet) updates) =>
      super.copyWith((message) => updates(message as ReqTranslationGet))
          as ReqTranslationGet;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqTranslationGet() / ReqTranslationGet.new instead')
  static ReqTranslationGet create() => ReqTranslationGet._();
  static $pb.GeneratedMessage $_createMessage() => ReqTranslationGet._();
  @$core.override
  ReqTranslationGet createEmptyInstance() => ReqTranslationGet._();
  @$core.pragma('dart2js:noInline')
  static ReqTranslationGet getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqTranslationGet>(
          ReqTranslationGet.$_createMessage);
  static ReqTranslationGet? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get lang => $_getSZ(0);
  @$pb.TagNumber(1)
  set lang($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLang() => $_has(0);
  @$pb.TagNumber(1)
  void clearLang() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get categories => $_getList(1);

  @$pb.TagNumber(3)
  $pb.PbList<$core.String> get keys => $_getList(2);
}

class ResTranslationGet extends $pb.GeneratedMessage {
  factory ResTranslationGet({
    $core.Iterable<$core.MapEntry<$core.String, $core.String>>? entries,
    $fixnum.Int64? updatedTsMs,
  }) {
    final result = ResTranslationGet._();
    if (entries != null) result.entries.addEntries(entries);
    if (updatedTsMs != null) result.updatedTsMs = updatedTsMs;
    return result;
  }

  ResTranslationGet._();

  factory ResTranslationGet.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResTranslationGet()..mergeFromBuffer(data, registry);
  factory ResTranslationGet.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResTranslationGet()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResTranslationGet',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResTranslationGet.$_createMessage)
    ..m<$core.String, $core.String>(1, _omitFieldNames ? '' : 'entries',
        entryClassName: 'ResTranslationGet.EntriesEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('c35'))
    ..aInt64(2, _omitFieldNames ? '' : 'updatedTsMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResTranslationGet clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResTranslationGet copyWith(void Function(ResTranslationGet) updates) =>
      super.copyWith((message) => updates(message as ResTranslationGet))
          as ResTranslationGet;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResTranslationGet() / ResTranslationGet.new instead')
  static ResTranslationGet create() => ResTranslationGet._();
  static $pb.GeneratedMessage $_createMessage() => ResTranslationGet._();
  @$core.override
  ResTranslationGet createEmptyInstance() => ResTranslationGet._();
  @$core.pragma('dart2js:noInline')
  static ResTranslationGet getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResTranslationGet>(
          ResTranslationGet.$_createMessage);
  static ResTranslationGet? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbMap<$core.String, $core.String> get entries => $_getMap(0);

  @$pb.TagNumber(2)
  $fixnum.Int64 get updatedTsMs => $_getI64(1);
  @$pb.TagNumber(2)
  set updatedTsMs($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUpdatedTsMs() => $_has(1);
  @$pb.TagNumber(2)
  void clearUpdatedTsMs() => $_clearField(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
