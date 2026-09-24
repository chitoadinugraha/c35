// This is a generated file - do not edit.
//
// Generated from c35/report.proto.

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

class UiMetricsCard extends $pb.GeneratedMessage {
  factory UiMetricsCard({
    $core.String? title,
    $core.String? value,
    $core.String? subtitle,
  }) {
    final result = UiMetricsCard._();
    if (title != null) result.title = title;
    if (value != null) result.value = value;
    if (subtitle != null) result.subtitle = subtitle;
    return result;
  }

  UiMetricsCard._();

  factory UiMetricsCard.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UiMetricsCard()..mergeFromBuffer(data, registry);
  factory UiMetricsCard.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UiMetricsCard()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UiMetricsCard',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: UiMetricsCard.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'title')
    ..aOS(2, _omitFieldNames ? '' : 'value')
    ..aOS(3, _omitFieldNames ? '' : 'subtitle')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UiMetricsCard clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UiMetricsCard copyWith(void Function(UiMetricsCard) updates) =>
      super.copyWith((message) => updates(message as UiMetricsCard))
          as UiMetricsCard;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use UiMetricsCard() / UiMetricsCard.new instead')
  static UiMetricsCard create() => UiMetricsCard._();
  static $pb.GeneratedMessage $_createMessage() => UiMetricsCard._();
  @$core.override
  UiMetricsCard createEmptyInstance() => UiMetricsCard._();
  @$core.pragma('dart2js:noInline')
  static UiMetricsCard getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UiMetricsCard>(
          UiMetricsCard.$_createMessage);
  static UiMetricsCard? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get title => $_getSZ(0);
  @$pb.TagNumber(1)
  set title($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTitle() => $_has(0);
  @$pb.TagNumber(1)
  void clearTitle() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get value => $_getSZ(1);
  @$pb.TagNumber(2)
  set value($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasValue() => $_has(1);
  @$pb.TagNumber(2)
  void clearValue() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get subtitle => $_getSZ(2);
  @$pb.TagNumber(3)
  set subtitle($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSubtitle() => $_has(2);
  @$pb.TagNumber(3)
  void clearSubtitle() => $_clearField(3);
}

class UiReportTable extends $pb.GeneratedMessage {
  factory UiReportTable({
    $core.Iterable<$core.String>? headers,
    $core.Iterable<UiReportTableRow>? rows,
  }) {
    final result = UiReportTable._();
    if (headers != null) result.headers.addAll(headers);
    if (rows != null) result.rows.addAll(rows);
    return result;
  }

  UiReportTable._();

  factory UiReportTable.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UiReportTable()..mergeFromBuffer(data, registry);
  factory UiReportTable.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UiReportTable()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UiReportTable',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: UiReportTable.$_createMessage)
    ..pPS(1, _omitFieldNames ? '' : 'headers')
    ..pPM<UiReportTableRow>(2, _omitFieldNames ? '' : 'rows',
        subBuilder: UiReportTableRow.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UiReportTable clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UiReportTable copyWith(void Function(UiReportTable) updates) =>
      super.copyWith((message) => updates(message as UiReportTable))
          as UiReportTable;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use UiReportTable() / UiReportTable.new instead')
  static UiReportTable create() => UiReportTable._();
  static $pb.GeneratedMessage $_createMessage() => UiReportTable._();
  @$core.override
  UiReportTable createEmptyInstance() => UiReportTable._();
  @$core.pragma('dart2js:noInline')
  static UiReportTable getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UiReportTable>(
          UiReportTable.$_createMessage);
  static UiReportTable? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get headers => $_getList(0);

  @$pb.TagNumber(2)
  $pb.PbList<UiReportTableRow> get rows => $_getList(1);
}

class UiReportTableRow extends $pb.GeneratedMessage {
  factory UiReportTableRow({
    $core.Iterable<$core.String>? cells,
  }) {
    final result = UiReportTableRow._();
    if (cells != null) result.cells.addAll(cells);
    return result;
  }

  UiReportTableRow._();

  factory UiReportTableRow.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UiReportTableRow()..mergeFromBuffer(data, registry);
  factory UiReportTableRow.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UiReportTableRow()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UiReportTableRow',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: UiReportTableRow.$_createMessage)
    ..pPS(1, _omitFieldNames ? '' : 'cells')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UiReportTableRow clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UiReportTableRow copyWith(void Function(UiReportTableRow) updates) =>
      super.copyWith((message) => updates(message as UiReportTableRow))
          as UiReportTableRow;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use UiReportTableRow() / UiReportTableRow.new instead')
  static UiReportTableRow create() => UiReportTableRow._();
  static $pb.GeneratedMessage $_createMessage() => UiReportTableRow._();
  @$core.override
  UiReportTableRow createEmptyInstance() => UiReportTableRow._();
  @$core.pragma('dart2js:noInline')
  static UiReportTableRow getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UiReportTableRow>(
          UiReportTableRow.$_createMessage);
  static UiReportTableRow? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get cells => $_getList(0);
}

enum UiWidget_Element { metricsCard, table, notSet }

class UiWidget extends $pb.GeneratedMessage {
  factory UiWidget({
    UiMetricsCard? metricsCard,
    UiReportTable? table,
  }) {
    final result = UiWidget._();
    if (metricsCard != null) result.metricsCard = metricsCard;
    if (table != null) result.table = table;
    return result;
  }

  UiWidget._();

  factory UiWidget.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UiWidget()..mergeFromBuffer(data, registry);
  factory UiWidget.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UiWidget()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, UiWidget_Element> _UiWidget_ElementByTag = {
    1: UiWidget_Element.metricsCard,
    2: UiWidget_Element.table,
    0: UiWidget_Element.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UiWidget',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: UiWidget.$_createMessage)
    ..oo(0, [1, 2])
    ..aOM<UiMetricsCard>(1, _omitFieldNames ? '' : 'metricsCard',
        subBuilder: UiMetricsCard.$_createMessage)
    ..aOM<UiReportTable>(2, _omitFieldNames ? '' : 'table',
        subBuilder: UiReportTable.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UiWidget clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UiWidget copyWith(void Function(UiWidget) updates) =>
      super.copyWith((message) => updates(message as UiWidget)) as UiWidget;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use UiWidget() / UiWidget.new instead')
  static UiWidget create() => UiWidget._();
  static $pb.GeneratedMessage $_createMessage() => UiWidget._();
  @$core.override
  UiWidget createEmptyInstance() => UiWidget._();
  @$core.pragma('dart2js:noInline')
  static UiWidget getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UiWidget>(UiWidget.$_createMessage);
  static UiWidget? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  UiWidget_Element whichElement() => _UiWidget_ElementByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearElement() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  UiMetricsCard get metricsCard => $_getN(0);
  @$pb.TagNumber(1)
  set metricsCard(UiMetricsCard value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasMetricsCard() => $_has(0);
  @$pb.TagNumber(1)
  void clearMetricsCard() => $_clearField(1);
  @$pb.TagNumber(1)
  UiMetricsCard ensureMetricsCard() => $_ensure(0);

  @$pb.TagNumber(2)
  UiReportTable get table => $_getN(1);
  @$pb.TagNumber(2)
  set table(UiReportTable value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasTable() => $_has(1);
  @$pb.TagNumber(2)
  void clearTable() => $_clearField(2);
  @$pb.TagNumber(2)
  UiReportTable ensureTable() => $_ensure(1);
}

class ReqAdminLogReport extends $pb.GeneratedMessage {
  factory ReqAdminLogReport({
    $fixnum.Int64? ownerIid,
    $fixnum.Int64? sinceMs,
    $fixnum.Int64? untilMs,
    $core.int? limit,
  }) {
    final result = ReqAdminLogReport._();
    if (ownerIid != null) result.ownerIid = ownerIid;
    if (sinceMs != null) result.sinceMs = sinceMs;
    if (untilMs != null) result.untilMs = untilMs;
    if (limit != null) result.limit = limit;
    return result;
  }

  ReqAdminLogReport._();

  factory ReqAdminLogReport.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqAdminLogReport()..mergeFromBuffer(data, registry);
  factory ReqAdminLogReport.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqAdminLogReport()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqAdminLogReport',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqAdminLogReport.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'ownerIid')
    ..aInt64(2, _omitFieldNames ? '' : 'sinceMs')
    ..aInt64(3, _omitFieldNames ? '' : 'untilMs')
    ..aI(4, _omitFieldNames ? '' : 'limit')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqAdminLogReport clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqAdminLogReport copyWith(void Function(ReqAdminLogReport) updates) =>
      super.copyWith((message) => updates(message as ReqAdminLogReport))
          as ReqAdminLogReport;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqAdminLogReport() / ReqAdminLogReport.new instead')
  static ReqAdminLogReport create() => ReqAdminLogReport._();
  static $pb.GeneratedMessage $_createMessage() => ReqAdminLogReport._();
  @$core.override
  ReqAdminLogReport createEmptyInstance() => ReqAdminLogReport._();
  @$core.pragma('dart2js:noInline')
  static ReqAdminLogReport getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqAdminLogReport>(
          ReqAdminLogReport.$_createMessage);
  static ReqAdminLogReport? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get ownerIid => $_getI64(0);
  @$pb.TagNumber(1)
  set ownerIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOwnerIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearOwnerIid() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get sinceMs => $_getI64(1);
  @$pb.TagNumber(2)
  set sinceMs($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSinceMs() => $_has(1);
  @$pb.TagNumber(2)
  void clearSinceMs() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get untilMs => $_getI64(2);
  @$pb.TagNumber(3)
  set untilMs($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasUntilMs() => $_has(2);
  @$pb.TagNumber(3)
  void clearUntilMs() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get limit => $_getIZ(3);
  @$pb.TagNumber(4)
  set limit($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasLimit() => $_has(3);
  @$pb.TagNumber(4)
  void clearLimit() => $_clearField(4);
}

class ResAdminLogReport extends $pb.GeneratedMessage {
  factory ResAdminLogReport({
    $core.Iterable<UiWidget>? widgets,
  }) {
    final result = ResAdminLogReport._();
    if (widgets != null) result.widgets.addAll(widgets);
    return result;
  }

  ResAdminLogReport._();

  factory ResAdminLogReport.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResAdminLogReport()..mergeFromBuffer(data, registry);
  factory ResAdminLogReport.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResAdminLogReport()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResAdminLogReport',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResAdminLogReport.$_createMessage)
    ..pPM<UiWidget>(1, _omitFieldNames ? '' : 'widgets',
        subBuilder: UiWidget.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResAdminLogReport clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResAdminLogReport copyWith(void Function(ResAdminLogReport) updates) =>
      super.copyWith((message) => updates(message as ResAdminLogReport))
          as ResAdminLogReport;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResAdminLogReport() / ResAdminLogReport.new instead')
  static ResAdminLogReport create() => ResAdminLogReport._();
  static $pb.GeneratedMessage $_createMessage() => ResAdminLogReport._();
  @$core.override
  ResAdminLogReport createEmptyInstance() => ResAdminLogReport._();
  @$core.pragma('dart2js:noInline')
  static ResAdminLogReport getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResAdminLogReport>(
          ResAdminLogReport.$_createMessage);
  static ResAdminLogReport? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<UiWidget> get widgets => $_getList(0);
}

class ReqAdminPlatformPnl extends $pb.GeneratedMessage {
  factory ReqAdminPlatformPnl({
    $fixnum.Int64? sinceMs,
    $fixnum.Int64? untilMs,
  }) {
    final result = ReqAdminPlatformPnl._();
    if (sinceMs != null) result.sinceMs = sinceMs;
    if (untilMs != null) result.untilMs = untilMs;
    return result;
  }

  ReqAdminPlatformPnl._();

  factory ReqAdminPlatformPnl.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqAdminPlatformPnl()..mergeFromBuffer(data, registry);
  factory ReqAdminPlatformPnl.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqAdminPlatformPnl()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqAdminPlatformPnl',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqAdminPlatformPnl.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'sinceMs')
    ..aInt64(2, _omitFieldNames ? '' : 'untilMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqAdminPlatformPnl clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqAdminPlatformPnl copyWith(void Function(ReqAdminPlatformPnl) updates) =>
      super.copyWith((message) => updates(message as ReqAdminPlatformPnl))
          as ReqAdminPlatformPnl;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use ReqAdminPlatformPnl() / ReqAdminPlatformPnl.new instead')
  static ReqAdminPlatformPnl create() => ReqAdminPlatformPnl._();
  static $pb.GeneratedMessage $_createMessage() => ReqAdminPlatformPnl._();
  @$core.override
  ReqAdminPlatformPnl createEmptyInstance() => ReqAdminPlatformPnl._();
  @$core.pragma('dart2js:noInline')
  static ReqAdminPlatformPnl getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqAdminPlatformPnl>(
          ReqAdminPlatformPnl.$_createMessage);
  static ReqAdminPlatformPnl? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get sinceMs => $_getI64(0);
  @$pb.TagNumber(1)
  set sinceMs($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSinceMs() => $_has(0);
  @$pb.TagNumber(1)
  void clearSinceMs() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get untilMs => $_getI64(1);
  @$pb.TagNumber(2)
  set untilMs($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUntilMs() => $_has(1);
  @$pb.TagNumber(2)
  void clearUntilMs() => $_clearField(2);
}

class ResAdminPlatformPnl extends $pb.GeneratedMessage {
  factory ResAdminPlatformPnl({
    $core.Iterable<UiWidget>? widgets,
    $core.double? revenueUsd,
    $core.double? aiCogsUsd,
    $core.double? infraCogsUsd,
    $core.double? grossProfitUsd,
    $core.double? aiApiVendorUsd,
    $core.double? aiCogsDriftPct,
  }) {
    final result = ResAdminPlatformPnl._();
    if (widgets != null) result.widgets.addAll(widgets);
    if (revenueUsd != null) result.revenueUsd = revenueUsd;
    if (aiCogsUsd != null) result.aiCogsUsd = aiCogsUsd;
    if (infraCogsUsd != null) result.infraCogsUsd = infraCogsUsd;
    if (grossProfitUsd != null) result.grossProfitUsd = grossProfitUsd;
    if (aiApiVendorUsd != null) result.aiApiVendorUsd = aiApiVendorUsd;
    if (aiCogsDriftPct != null) result.aiCogsDriftPct = aiCogsDriftPct;
    return result;
  }

  ResAdminPlatformPnl._();

  factory ResAdminPlatformPnl.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResAdminPlatformPnl()..mergeFromBuffer(data, registry);
  factory ResAdminPlatformPnl.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResAdminPlatformPnl()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResAdminPlatformPnl',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResAdminPlatformPnl.$_createMessage)
    ..pPM<UiWidget>(1, _omitFieldNames ? '' : 'widgets',
        subBuilder: UiWidget.$_createMessage)
    ..aD(2, _omitFieldNames ? '' : 'revenueUsd')
    ..aD(3, _omitFieldNames ? '' : 'aiCogsUsd')
    ..aD(4, _omitFieldNames ? '' : 'infraCogsUsd')
    ..aD(5, _omitFieldNames ? '' : 'grossProfitUsd')
    ..aD(6, _omitFieldNames ? '' : 'aiApiVendorUsd')
    ..aD(7, _omitFieldNames ? '' : 'aiCogsDriftPct')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResAdminPlatformPnl clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResAdminPlatformPnl copyWith(void Function(ResAdminPlatformPnl) updates) =>
      super.copyWith((message) => updates(message as ResAdminPlatformPnl))
          as ResAdminPlatformPnl;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use ResAdminPlatformPnl() / ResAdminPlatformPnl.new instead')
  static ResAdminPlatformPnl create() => ResAdminPlatformPnl._();
  static $pb.GeneratedMessage $_createMessage() => ResAdminPlatformPnl._();
  @$core.override
  ResAdminPlatformPnl createEmptyInstance() => ResAdminPlatformPnl._();
  @$core.pragma('dart2js:noInline')
  static ResAdminPlatformPnl getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResAdminPlatformPnl>(
          ResAdminPlatformPnl.$_createMessage);
  static ResAdminPlatformPnl? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<UiWidget> get widgets => $_getList(0);

  @$pb.TagNumber(2)
  $core.double get revenueUsd => $_getN(1);
  @$pb.TagNumber(2)
  set revenueUsd($core.double value) => $_setDouble(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRevenueUsd() => $_has(1);
  @$pb.TagNumber(2)
  void clearRevenueUsd() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get aiCogsUsd => $_getN(2);
  @$pb.TagNumber(3)
  set aiCogsUsd($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAiCogsUsd() => $_has(2);
  @$pb.TagNumber(3)
  void clearAiCogsUsd() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get infraCogsUsd => $_getN(3);
  @$pb.TagNumber(4)
  set infraCogsUsd($core.double value) => $_setDouble(3, value);
  @$pb.TagNumber(4)
  $core.bool hasInfraCogsUsd() => $_has(3);
  @$pb.TagNumber(4)
  void clearInfraCogsUsd() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.double get grossProfitUsd => $_getN(4);
  @$pb.TagNumber(5)
  set grossProfitUsd($core.double value) => $_setDouble(4, value);
  @$pb.TagNumber(5)
  $core.bool hasGrossProfitUsd() => $_has(4);
  @$pb.TagNumber(5)
  void clearGrossProfitUsd() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.double get aiApiVendorUsd => $_getN(5);
  @$pb.TagNumber(6)
  set aiApiVendorUsd($core.double value) => $_setDouble(5, value);
  @$pb.TagNumber(6)
  $core.bool hasAiApiVendorUsd() => $_has(5);
  @$pb.TagNumber(6)
  void clearAiApiVendorUsd() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.double get aiCogsDriftPct => $_getN(6);
  @$pb.TagNumber(7)
  set aiCogsDriftPct($core.double value) => $_setDouble(6, value);
  @$pb.TagNumber(7)
  $core.bool hasAiCogsDriftPct() => $_has(6);
  @$pb.TagNumber(7)
  void clearAiCogsDriftPct() => $_clearField(7);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
