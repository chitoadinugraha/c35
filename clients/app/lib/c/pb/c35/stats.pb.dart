// This is a generated file - do not edit.
//
// Generated from c35/stats.proto.

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

class DiskMountStat extends $pb.GeneratedMessage {
  factory DiskMountStat({
    $core.String? label,
    $core.String? mount,
    $fixnum.Int64? usedBytes,
    $fixnum.Int64? totalBytes,
    $core.double? readBps,
    $core.double? writeBps,
  }) {
    final result = DiskMountStat._();
    if (label != null) result.label = label;
    if (mount != null) result.mount = mount;
    if (usedBytes != null) result.usedBytes = usedBytes;
    if (totalBytes != null) result.totalBytes = totalBytes;
    if (readBps != null) result.readBps = readBps;
    if (writeBps != null) result.writeBps = writeBps;
    return result;
  }

  DiskMountStat._();

  factory DiskMountStat.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DiskMountStat()..mergeFromBuffer(data, registry);
  factory DiskMountStat.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DiskMountStat()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DiskMountStat',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: DiskMountStat.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'label')
    ..aOS(2, _omitFieldNames ? '' : 'mount')
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'usedBytes', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        4, _omitFieldNames ? '' : 'totalBytes', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aD(5, _omitFieldNames ? '' : 'readBps')
    ..aD(6, _omitFieldNames ? '' : 'writeBps')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DiskMountStat clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DiskMountStat copyWith(void Function(DiskMountStat) updates) =>
      super.copyWith((message) => updates(message as DiskMountStat))
          as DiskMountStat;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use DiskMountStat() / DiskMountStat.new instead')
  static DiskMountStat create() => DiskMountStat._();
  static $pb.GeneratedMessage $_createMessage() => DiskMountStat._();
  @$core.override
  DiskMountStat createEmptyInstance() => DiskMountStat._();
  @$core.pragma('dart2js:noInline')
  static DiskMountStat getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DiskMountStat>(
          DiskMountStat.$_createMessage);
  static DiskMountStat? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get label => $_getSZ(0);
  @$pb.TagNumber(1)
  set label($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLabel() => $_has(0);
  @$pb.TagNumber(1)
  void clearLabel() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get mount => $_getSZ(1);
  @$pb.TagNumber(2)
  set mount($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMount() => $_has(1);
  @$pb.TagNumber(2)
  void clearMount() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get usedBytes => $_getI64(2);
  @$pb.TagNumber(3)
  set usedBytes($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasUsedBytes() => $_has(2);
  @$pb.TagNumber(3)
  void clearUsedBytes() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get totalBytes => $_getI64(3);
  @$pb.TagNumber(4)
  set totalBytes($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTotalBytes() => $_has(3);
  @$pb.TagNumber(4)
  void clearTotalBytes() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.double get readBps => $_getN(4);
  @$pb.TagNumber(5)
  set readBps($core.double value) => $_setDouble(4, value);
  @$pb.TagNumber(5)
  $core.bool hasReadBps() => $_has(4);
  @$pb.TagNumber(5)
  void clearReadBps() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.double get writeBps => $_getN(5);
  @$pb.TagNumber(6)
  set writeBps($core.double value) => $_setDouble(5, value);
  @$pb.TagNumber(6)
  $core.bool hasWriteBps() => $_has(5);
  @$pb.TagNumber(6)
  void clearWriteBps() => $_clearField(6);
}

class DiskDeviceStat extends $pb.GeneratedMessage {
  factory DiskDeviceStat({
    $core.String? device,
    $core.String? mount,
    $core.String? label,
    $core.bool? isBoot,
    $fixnum.Int64? usedBytes,
    $fixnum.Int64? totalBytes,
    $core.double? readBps,
    $core.double? writeBps,
  }) {
    final result = DiskDeviceStat._();
    if (device != null) result.device = device;
    if (mount != null) result.mount = mount;
    if (label != null) result.label = label;
    if (isBoot != null) result.isBoot = isBoot;
    if (usedBytes != null) result.usedBytes = usedBytes;
    if (totalBytes != null) result.totalBytes = totalBytes;
    if (readBps != null) result.readBps = readBps;
    if (writeBps != null) result.writeBps = writeBps;
    return result;
  }

  DiskDeviceStat._();

  factory DiskDeviceStat.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DiskDeviceStat()..mergeFromBuffer(data, registry);
  factory DiskDeviceStat.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DiskDeviceStat()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DiskDeviceStat',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: DiskDeviceStat.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'device')
    ..aOS(2, _omitFieldNames ? '' : 'mount')
    ..aOS(3, _omitFieldNames ? '' : 'label')
    ..aOB(4, _omitFieldNames ? '' : 'isBoot')
    ..a<$fixnum.Int64>(
        5, _omitFieldNames ? '' : 'usedBytes', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        6, _omitFieldNames ? '' : 'totalBytes', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aD(7, _omitFieldNames ? '' : 'readBps')
    ..aD(8, _omitFieldNames ? '' : 'writeBps')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DiskDeviceStat clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DiskDeviceStat copyWith(void Function(DiskDeviceStat) updates) =>
      super.copyWith((message) => updates(message as DiskDeviceStat))
          as DiskDeviceStat;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use DiskDeviceStat() / DiskDeviceStat.new instead')
  static DiskDeviceStat create() => DiskDeviceStat._();
  static $pb.GeneratedMessage $_createMessage() => DiskDeviceStat._();
  @$core.override
  DiskDeviceStat createEmptyInstance() => DiskDeviceStat._();
  @$core.pragma('dart2js:noInline')
  static DiskDeviceStat getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DiskDeviceStat>(
          DiskDeviceStat.$_createMessage);
  static DiskDeviceStat? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get device => $_getSZ(0);
  @$pb.TagNumber(1)
  set device($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDevice() => $_has(0);
  @$pb.TagNumber(1)
  void clearDevice() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get mount => $_getSZ(1);
  @$pb.TagNumber(2)
  set mount($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMount() => $_has(1);
  @$pb.TagNumber(2)
  void clearMount() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get label => $_getSZ(2);
  @$pb.TagNumber(3)
  set label($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLabel() => $_has(2);
  @$pb.TagNumber(3)
  void clearLabel() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get isBoot => $_getBF(3);
  @$pb.TagNumber(4)
  set isBoot($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasIsBoot() => $_has(3);
  @$pb.TagNumber(4)
  void clearIsBoot() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get usedBytes => $_getI64(4);
  @$pb.TagNumber(5)
  set usedBytes($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasUsedBytes() => $_has(4);
  @$pb.TagNumber(5)
  void clearUsedBytes() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get totalBytes => $_getI64(5);
  @$pb.TagNumber(6)
  set totalBytes($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasTotalBytes() => $_has(5);
  @$pb.TagNumber(6)
  void clearTotalBytes() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.double get readBps => $_getN(6);
  @$pb.TagNumber(7)
  set readBps($core.double value) => $_setDouble(6, value);
  @$pb.TagNumber(7)
  $core.bool hasReadBps() => $_has(6);
  @$pb.TagNumber(7)
  void clearReadBps() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.double get writeBps => $_getN(7);
  @$pb.TagNumber(8)
  set writeBps($core.double value) => $_setDouble(7, value);
  @$pb.TagNumber(8)
  $core.bool hasWriteBps() => $_has(7);
  @$pb.TagNumber(8)
  void clearWriteBps() => $_clearField(8);
}

class VolumeStat extends $pb.GeneratedMessage {
  factory VolumeStat({
    $core.String? namespace,
    $core.String? pvcName,
    $core.String? podName,
    $core.String? nodeName,
    $fixnum.Int64? usedBytes,
    $fixnum.Int64? capacityBytes,
    $core.String? storageClass,
    $core.String? label,
  }) {
    final result = VolumeStat._();
    if (namespace != null) result.namespace = namespace;
    if (pvcName != null) result.pvcName = pvcName;
    if (podName != null) result.podName = podName;
    if (nodeName != null) result.nodeName = nodeName;
    if (usedBytes != null) result.usedBytes = usedBytes;
    if (capacityBytes != null) result.capacityBytes = capacityBytes;
    if (storageClass != null) result.storageClass = storageClass;
    if (label != null) result.label = label;
    return result;
  }

  VolumeStat._();

  factory VolumeStat.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      VolumeStat()..mergeFromBuffer(data, registry);
  factory VolumeStat.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      VolumeStat()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'VolumeStat',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: VolumeStat.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'namespace')
    ..aOS(2, _omitFieldNames ? '' : 'pvcName')
    ..aOS(3, _omitFieldNames ? '' : 'podName')
    ..aOS(4, _omitFieldNames ? '' : 'nodeName')
    ..a<$fixnum.Int64>(
        5, _omitFieldNames ? '' : 'usedBytes', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        6, _omitFieldNames ? '' : 'capacityBytes', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(7, _omitFieldNames ? '' : 'storageClass')
    ..aOS(8, _omitFieldNames ? '' : 'label')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VolumeStat clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VolumeStat copyWith(void Function(VolumeStat) updates) =>
      super.copyWith((message) => updates(message as VolumeStat)) as VolumeStat;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use VolumeStat() / VolumeStat.new instead')
  static VolumeStat create() => VolumeStat._();
  static $pb.GeneratedMessage $_createMessage() => VolumeStat._();
  @$core.override
  VolumeStat createEmptyInstance() => VolumeStat._();
  @$core.pragma('dart2js:noInline')
  static VolumeStat getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<VolumeStat>(VolumeStat.$_createMessage);
  static VolumeStat? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get namespace => $_getSZ(0);
  @$pb.TagNumber(1)
  set namespace($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasNamespace() => $_has(0);
  @$pb.TagNumber(1)
  void clearNamespace() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get pvcName => $_getSZ(1);
  @$pb.TagNumber(2)
  set pvcName($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPvcName() => $_has(1);
  @$pb.TagNumber(2)
  void clearPvcName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get podName => $_getSZ(2);
  @$pb.TagNumber(3)
  set podName($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPodName() => $_has(2);
  @$pb.TagNumber(3)
  void clearPodName() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get nodeName => $_getSZ(3);
  @$pb.TagNumber(4)
  set nodeName($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasNodeName() => $_has(3);
  @$pb.TagNumber(4)
  void clearNodeName() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get usedBytes => $_getI64(4);
  @$pb.TagNumber(5)
  set usedBytes($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasUsedBytes() => $_has(4);
  @$pb.TagNumber(5)
  void clearUsedBytes() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get capacityBytes => $_getI64(5);
  @$pb.TagNumber(6)
  set capacityBytes($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasCapacityBytes() => $_has(5);
  @$pb.TagNumber(6)
  void clearCapacityBytes() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get storageClass => $_getSZ(6);
  @$pb.TagNumber(7)
  set storageClass($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasStorageClass() => $_has(6);
  @$pb.TagNumber(7)
  void clearStorageClass() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get label => $_getSZ(7);
  @$pb.TagNumber(8)
  set label($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasLabel() => $_has(7);
  @$pb.TagNumber(8)
  void clearLabel() => $_clearField(8);
}

class NodeStat extends $pb.GeneratedMessage {
  factory NodeStat({
    $core.String? nodeName,
    $core.int? cpuCores,
    $core.double? cpuPct,
    $fixnum.Int64? memUsedBytes,
    $fixnum.Int64? memTotalBytes,
    $core.Iterable<DiskMountStat>? mounts,
    $core.double? netInBps,
    $core.double? netOutBps,
    $fixnum.Int64? tsMs,
    $core.Iterable<DiskDeviceStat>? devices,
    $fixnum.Int64? swapUsedBytes,
    $fixnum.Int64? swapTotalBytes,
  }) {
    final result = NodeStat._();
    if (nodeName != null) result.nodeName = nodeName;
    if (cpuCores != null) result.cpuCores = cpuCores;
    if (cpuPct != null) result.cpuPct = cpuPct;
    if (memUsedBytes != null) result.memUsedBytes = memUsedBytes;
    if (memTotalBytes != null) result.memTotalBytes = memTotalBytes;
    if (mounts != null) result.mounts.addAll(mounts);
    if (netInBps != null) result.netInBps = netInBps;
    if (netOutBps != null) result.netOutBps = netOutBps;
    if (tsMs != null) result.tsMs = tsMs;
    if (devices != null) result.devices.addAll(devices);
    if (swapUsedBytes != null) result.swapUsedBytes = swapUsedBytes;
    if (swapTotalBytes != null) result.swapTotalBytes = swapTotalBytes;
    return result;
  }

  NodeStat._();

  factory NodeStat.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      NodeStat()..mergeFromBuffer(data, registry);
  factory NodeStat.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      NodeStat()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NodeStat',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: NodeStat.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'nodeName')
    ..aI(2, _omitFieldNames ? '' : 'cpuCores')
    ..aD(3, _omitFieldNames ? '' : 'cpuPct')
    ..a<$fixnum.Int64>(
        4, _omitFieldNames ? '' : 'memUsedBytes', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        5, _omitFieldNames ? '' : 'memTotalBytes', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..pPM<DiskMountStat>(6, _omitFieldNames ? '' : 'mounts',
        subBuilder: DiskMountStat.$_createMessage)
    ..aD(7, _omitFieldNames ? '' : 'netInBps')
    ..aD(8, _omitFieldNames ? '' : 'netOutBps')
    ..aInt64(9, _omitFieldNames ? '' : 'tsMs')
    ..pPM<DiskDeviceStat>(10, _omitFieldNames ? '' : 'devices',
        subBuilder: DiskDeviceStat.$_createMessage)
    ..a<$fixnum.Int64>(
        11, _omitFieldNames ? '' : 'swapUsedBytes', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        12, _omitFieldNames ? '' : 'swapTotalBytes', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NodeStat clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NodeStat copyWith(void Function(NodeStat) updates) =>
      super.copyWith((message) => updates(message as NodeStat)) as NodeStat;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use NodeStat() / NodeStat.new instead')
  static NodeStat create() => NodeStat._();
  static $pb.GeneratedMessage $_createMessage() => NodeStat._();
  @$core.override
  NodeStat createEmptyInstance() => NodeStat._();
  @$core.pragma('dart2js:noInline')
  static NodeStat getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NodeStat>(NodeStat.$_createMessage);
  static NodeStat? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get nodeName => $_getSZ(0);
  @$pb.TagNumber(1)
  set nodeName($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasNodeName() => $_has(0);
  @$pb.TagNumber(1)
  void clearNodeName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get cpuCores => $_getIZ(1);
  @$pb.TagNumber(2)
  set cpuCores($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCpuCores() => $_has(1);
  @$pb.TagNumber(2)
  void clearCpuCores() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get cpuPct => $_getN(2);
  @$pb.TagNumber(3)
  set cpuPct($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCpuPct() => $_has(2);
  @$pb.TagNumber(3)
  void clearCpuPct() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get memUsedBytes => $_getI64(3);
  @$pb.TagNumber(4)
  set memUsedBytes($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasMemUsedBytes() => $_has(3);
  @$pb.TagNumber(4)
  void clearMemUsedBytes() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get memTotalBytes => $_getI64(4);
  @$pb.TagNumber(5)
  set memTotalBytes($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasMemTotalBytes() => $_has(4);
  @$pb.TagNumber(5)
  void clearMemTotalBytes() => $_clearField(5);

  @$pb.TagNumber(6)
  $pb.PbList<DiskMountStat> get mounts => $_getList(5);

  @$pb.TagNumber(7)
  $core.double get netInBps => $_getN(6);
  @$pb.TagNumber(7)
  set netInBps($core.double value) => $_setDouble(6, value);
  @$pb.TagNumber(7)
  $core.bool hasNetInBps() => $_has(6);
  @$pb.TagNumber(7)
  void clearNetInBps() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.double get netOutBps => $_getN(7);
  @$pb.TagNumber(8)
  set netOutBps($core.double value) => $_setDouble(7, value);
  @$pb.TagNumber(8)
  $core.bool hasNetOutBps() => $_has(7);
  @$pb.TagNumber(8)
  void clearNetOutBps() => $_clearField(8);

  @$pb.TagNumber(9)
  $fixnum.Int64 get tsMs => $_getI64(8);
  @$pb.TagNumber(9)
  set tsMs($fixnum.Int64 value) => $_setInt64(8, value);
  @$pb.TagNumber(9)
  $core.bool hasTsMs() => $_has(8);
  @$pb.TagNumber(9)
  void clearTsMs() => $_clearField(9);

  @$pb.TagNumber(10)
  $pb.PbList<DiskDeviceStat> get devices => $_getList(9);

  @$pb.TagNumber(11)
  $fixnum.Int64 get swapUsedBytes => $_getI64(10);
  @$pb.TagNumber(11)
  set swapUsedBytes($fixnum.Int64 value) => $_setInt64(10, value);
  @$pb.TagNumber(11)
  $core.bool hasSwapUsedBytes() => $_has(10);
  @$pb.TagNumber(11)
  void clearSwapUsedBytes() => $_clearField(11);

  @$pb.TagNumber(12)
  $fixnum.Int64 get swapTotalBytes => $_getI64(11);
  @$pb.TagNumber(12)
  set swapTotalBytes($fixnum.Int64 value) => $_setInt64(11, value);
  @$pb.TagNumber(12)
  $core.bool hasSwapTotalBytes() => $_has(11);
  @$pb.TagNumber(12)
  void clearSwapTotalBytes() => $_clearField(12);
}

enum StatsPush_Body { node, volume, notSet }

class StatsPush extends $pb.GeneratedMessage {
  factory StatsPush({
    NodeStat? node,
    VolumeStat? volume,
  }) {
    final result = StatsPush._();
    if (node != null) result.node = node;
    if (volume != null) result.volume = volume;
    return result;
  }

  StatsPush._();

  factory StatsPush.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StatsPush()..mergeFromBuffer(data, registry);
  factory StatsPush.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StatsPush()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, StatsPush_Body> _StatsPush_BodyByTag = {
    1: StatsPush_Body.node,
    2: StatsPush_Body.volume,
    0: StatsPush_Body.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StatsPush',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: StatsPush.$_createMessage)
    ..oo(0, [1, 2])
    ..aOM<NodeStat>(1, _omitFieldNames ? '' : 'node',
        subBuilder: NodeStat.$_createMessage)
    ..aOM<VolumeStat>(2, _omitFieldNames ? '' : 'volume',
        subBuilder: VolumeStat.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StatsPush clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StatsPush copyWith(void Function(StatsPush) updates) =>
      super.copyWith((message) => updates(message as StatsPush)) as StatsPush;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use StatsPush() / StatsPush.new instead')
  static StatsPush create() => StatsPush._();
  static $pb.GeneratedMessage $_createMessage() => StatsPush._();
  @$core.override
  StatsPush createEmptyInstance() => StatsPush._();
  @$core.pragma('dart2js:noInline')
  static StatsPush getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StatsPush>(StatsPush.$_createMessage);
  static StatsPush? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  StatsPush_Body whichBody() => _StatsPush_BodyByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearBody() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  NodeStat get node => $_getN(0);
  @$pb.TagNumber(1)
  set node(NodeStat value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasNode() => $_has(0);
  @$pb.TagNumber(1)
  void clearNode() => $_clearField(1);
  @$pb.TagNumber(1)
  NodeStat ensureNode() => $_ensure(0);

  @$pb.TagNumber(2)
  VolumeStat get volume => $_getN(1);
  @$pb.TagNumber(2)
  set volume(VolumeStat value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasVolume() => $_has(1);
  @$pb.TagNumber(2)
  void clearVolume() => $_clearField(2);
  @$pb.TagNumber(2)
  VolumeStat ensureVolume() => $_ensure(1);
}

class ReqStatsSubscribe extends $pb.GeneratedMessage {
  factory ReqStatsSubscribe() => ReqStatsSubscribe._();

  ReqStatsSubscribe._();

  factory ReqStatsSubscribe.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqStatsSubscribe()..mergeFromBuffer(data, registry);
  factory ReqStatsSubscribe.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqStatsSubscribe()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqStatsSubscribe',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqStatsSubscribe.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqStatsSubscribe clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqStatsSubscribe copyWith(void Function(ReqStatsSubscribe) updates) =>
      super.copyWith((message) => updates(message as ReqStatsSubscribe))
          as ReqStatsSubscribe;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqStatsSubscribe() / ReqStatsSubscribe.new instead')
  static ReqStatsSubscribe create() => ReqStatsSubscribe._();
  static $pb.GeneratedMessage $_createMessage() => ReqStatsSubscribe._();
  @$core.override
  ReqStatsSubscribe createEmptyInstance() => ReqStatsSubscribe._();
  @$core.pragma('dart2js:noInline')
  static ReqStatsSubscribe getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqStatsSubscribe>(
          ReqStatsSubscribe.$_createMessage);
  static ReqStatsSubscribe? _defaultInstance;
}

class ReqStatsUnsubscribe extends $pb.GeneratedMessage {
  factory ReqStatsUnsubscribe() => ReqStatsUnsubscribe._();

  ReqStatsUnsubscribe._();

  factory ReqStatsUnsubscribe.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqStatsUnsubscribe()..mergeFromBuffer(data, registry);
  factory ReqStatsUnsubscribe.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqStatsUnsubscribe()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqStatsUnsubscribe',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqStatsUnsubscribe.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqStatsUnsubscribe clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqStatsUnsubscribe copyWith(void Function(ReqStatsUnsubscribe) updates) =>
      super.copyWith((message) => updates(message as ReqStatsUnsubscribe))
          as ReqStatsUnsubscribe;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use ReqStatsUnsubscribe() / ReqStatsUnsubscribe.new instead')
  static ReqStatsUnsubscribe create() => ReqStatsUnsubscribe._();
  static $pb.GeneratedMessage $_createMessage() => ReqStatsUnsubscribe._();
  @$core.override
  ReqStatsUnsubscribe createEmptyInstance() => ReqStatsUnsubscribe._();
  @$core.pragma('dart2js:noInline')
  static ReqStatsUnsubscribe getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqStatsUnsubscribe>(
          ReqStatsUnsubscribe.$_createMessage);
  static ReqStatsUnsubscribe? _defaultInstance;
}

class ReqLogSubscribe extends $pb.GeneratedMessage {
  factory ReqLogSubscribe({
    $fixnum.Int64? ownerIid,
  }) {
    final result = ReqLogSubscribe._();
    if (ownerIid != null) result.ownerIid = ownerIid;
    return result;
  }

  ReqLogSubscribe._();

  factory ReqLogSubscribe.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqLogSubscribe()..mergeFromBuffer(data, registry);
  factory ReqLogSubscribe.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqLogSubscribe()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqLogSubscribe',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqLogSubscribe.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'ownerIid')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqLogSubscribe clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqLogSubscribe copyWith(void Function(ReqLogSubscribe) updates) =>
      super.copyWith((message) => updates(message as ReqLogSubscribe))
          as ReqLogSubscribe;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqLogSubscribe() / ReqLogSubscribe.new instead')
  static ReqLogSubscribe create() => ReqLogSubscribe._();
  static $pb.GeneratedMessage $_createMessage() => ReqLogSubscribe._();
  @$core.override
  ReqLogSubscribe createEmptyInstance() => ReqLogSubscribe._();
  @$core.pragma('dart2js:noInline')
  static ReqLogSubscribe getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqLogSubscribe>(
          ReqLogSubscribe.$_createMessage);
  static ReqLogSubscribe? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get ownerIid => $_getI64(0);
  @$pb.TagNumber(1)
  set ownerIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOwnerIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearOwnerIid() => $_clearField(1);
}

class ReqLogUnsubscribe extends $pb.GeneratedMessage {
  factory ReqLogUnsubscribe() => ReqLogUnsubscribe._();

  ReqLogUnsubscribe._();

  factory ReqLogUnsubscribe.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqLogUnsubscribe()..mergeFromBuffer(data, registry);
  factory ReqLogUnsubscribe.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqLogUnsubscribe()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqLogUnsubscribe',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqLogUnsubscribe.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqLogUnsubscribe clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqLogUnsubscribe copyWith(void Function(ReqLogUnsubscribe) updates) =>
      super.copyWith((message) => updates(message as ReqLogUnsubscribe))
          as ReqLogUnsubscribe;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqLogUnsubscribe() / ReqLogUnsubscribe.new instead')
  static ReqLogUnsubscribe create() => ReqLogUnsubscribe._();
  static $pb.GeneratedMessage $_createMessage() => ReqLogUnsubscribe._();
  @$core.override
  ReqLogUnsubscribe createEmptyInstance() => ReqLogUnsubscribe._();
  @$core.pragma('dart2js:noInline')
  static ReqLogUnsubscribe getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqLogUnsubscribe>(
          ReqLogUnsubscribe.$_createMessage);
  static ReqLogUnsubscribe? _defaultInstance;
}

class OpsMetric1mRow extends $pb.GeneratedMessage {
  factory OpsMetric1mRow({
    $fixnum.Int64? tsMinMs,
    $core.String? entityType,
    $core.String? entityId,
    $core.String? nodeName,
    $core.double? cpuMax,
    $fixnum.Int64? memUsedMax,
    $core.double? netInMax,
    $core.double? netOutMax,
    $core.String? diskDevice,
    $fixnum.Int64? diskUsedLast,
    $fixnum.Int64? diskTotalLast,
    $core.String? volNamespace,
    $core.String? volPvc,
    $fixnum.Int64? volUsedLast,
    $fixnum.Int64? volCapacityLast,
  }) {
    final result = OpsMetric1mRow._();
    if (tsMinMs != null) result.tsMinMs = tsMinMs;
    if (entityType != null) result.entityType = entityType;
    if (entityId != null) result.entityId = entityId;
    if (nodeName != null) result.nodeName = nodeName;
    if (cpuMax != null) result.cpuMax = cpuMax;
    if (memUsedMax != null) result.memUsedMax = memUsedMax;
    if (netInMax != null) result.netInMax = netInMax;
    if (netOutMax != null) result.netOutMax = netOutMax;
    if (diskDevice != null) result.diskDevice = diskDevice;
    if (diskUsedLast != null) result.diskUsedLast = diskUsedLast;
    if (diskTotalLast != null) result.diskTotalLast = diskTotalLast;
    if (volNamespace != null) result.volNamespace = volNamespace;
    if (volPvc != null) result.volPvc = volPvc;
    if (volUsedLast != null) result.volUsedLast = volUsedLast;
    if (volCapacityLast != null) result.volCapacityLast = volCapacityLast;
    return result;
  }

  OpsMetric1mRow._();

  factory OpsMetric1mRow.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      OpsMetric1mRow()..mergeFromBuffer(data, registry);
  factory OpsMetric1mRow.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      OpsMetric1mRow()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OpsMetric1mRow',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: OpsMetric1mRow.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'tsMinMs')
    ..aOS(2, _omitFieldNames ? '' : 'entityType')
    ..aOS(3, _omitFieldNames ? '' : 'entityId')
    ..aOS(4, _omitFieldNames ? '' : 'nodeName')
    ..aD(5, _omitFieldNames ? '' : 'cpuMax')
    ..aInt64(6, _omitFieldNames ? '' : 'memUsedMax')
    ..aD(7, _omitFieldNames ? '' : 'netInMax')
    ..aD(8, _omitFieldNames ? '' : 'netOutMax')
    ..aOS(9, _omitFieldNames ? '' : 'diskDevice')
    ..aInt64(10, _omitFieldNames ? '' : 'diskUsedLast')
    ..aInt64(11, _omitFieldNames ? '' : 'diskTotalLast')
    ..aOS(12, _omitFieldNames ? '' : 'volNamespace')
    ..aOS(13, _omitFieldNames ? '' : 'volPvc')
    ..aInt64(14, _omitFieldNames ? '' : 'volUsedLast')
    ..aInt64(15, _omitFieldNames ? '' : 'volCapacityLast')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OpsMetric1mRow clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OpsMetric1mRow copyWith(void Function(OpsMetric1mRow) updates) =>
      super.copyWith((message) => updates(message as OpsMetric1mRow))
          as OpsMetric1mRow;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use OpsMetric1mRow() / OpsMetric1mRow.new instead')
  static OpsMetric1mRow create() => OpsMetric1mRow._();
  static $pb.GeneratedMessage $_createMessage() => OpsMetric1mRow._();
  @$core.override
  OpsMetric1mRow createEmptyInstance() => OpsMetric1mRow._();
  @$core.pragma('dart2js:noInline')
  static OpsMetric1mRow getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<OpsMetric1mRow>(
          OpsMetric1mRow.$_createMessage);
  static OpsMetric1mRow? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get tsMinMs => $_getI64(0);
  @$pb.TagNumber(1)
  set tsMinMs($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTsMinMs() => $_has(0);
  @$pb.TagNumber(1)
  void clearTsMinMs() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get entityType => $_getSZ(1);
  @$pb.TagNumber(2)
  set entityType($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEntityType() => $_has(1);
  @$pb.TagNumber(2)
  void clearEntityType() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get entityId => $_getSZ(2);
  @$pb.TagNumber(3)
  set entityId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasEntityId() => $_has(2);
  @$pb.TagNumber(3)
  void clearEntityId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get nodeName => $_getSZ(3);
  @$pb.TagNumber(4)
  set nodeName($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasNodeName() => $_has(3);
  @$pb.TagNumber(4)
  void clearNodeName() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.double get cpuMax => $_getN(4);
  @$pb.TagNumber(5)
  set cpuMax($core.double value) => $_setDouble(4, value);
  @$pb.TagNumber(5)
  $core.bool hasCpuMax() => $_has(4);
  @$pb.TagNumber(5)
  void clearCpuMax() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get memUsedMax => $_getI64(5);
  @$pb.TagNumber(6)
  set memUsedMax($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasMemUsedMax() => $_has(5);
  @$pb.TagNumber(6)
  void clearMemUsedMax() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.double get netInMax => $_getN(6);
  @$pb.TagNumber(7)
  set netInMax($core.double value) => $_setDouble(6, value);
  @$pb.TagNumber(7)
  $core.bool hasNetInMax() => $_has(6);
  @$pb.TagNumber(7)
  void clearNetInMax() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.double get netOutMax => $_getN(7);
  @$pb.TagNumber(8)
  set netOutMax($core.double value) => $_setDouble(7, value);
  @$pb.TagNumber(8)
  $core.bool hasNetOutMax() => $_has(7);
  @$pb.TagNumber(8)
  void clearNetOutMax() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get diskDevice => $_getSZ(8);
  @$pb.TagNumber(9)
  set diskDevice($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasDiskDevice() => $_has(8);
  @$pb.TagNumber(9)
  void clearDiskDevice() => $_clearField(9);

  @$pb.TagNumber(10)
  $fixnum.Int64 get diskUsedLast => $_getI64(9);
  @$pb.TagNumber(10)
  set diskUsedLast($fixnum.Int64 value) => $_setInt64(9, value);
  @$pb.TagNumber(10)
  $core.bool hasDiskUsedLast() => $_has(9);
  @$pb.TagNumber(10)
  void clearDiskUsedLast() => $_clearField(10);

  @$pb.TagNumber(11)
  $fixnum.Int64 get diskTotalLast => $_getI64(10);
  @$pb.TagNumber(11)
  set diskTotalLast($fixnum.Int64 value) => $_setInt64(10, value);
  @$pb.TagNumber(11)
  $core.bool hasDiskTotalLast() => $_has(10);
  @$pb.TagNumber(11)
  void clearDiskTotalLast() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.String get volNamespace => $_getSZ(11);
  @$pb.TagNumber(12)
  set volNamespace($core.String value) => $_setString(11, value);
  @$pb.TagNumber(12)
  $core.bool hasVolNamespace() => $_has(11);
  @$pb.TagNumber(12)
  void clearVolNamespace() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.String get volPvc => $_getSZ(12);
  @$pb.TagNumber(13)
  set volPvc($core.String value) => $_setString(12, value);
  @$pb.TagNumber(13)
  $core.bool hasVolPvc() => $_has(12);
  @$pb.TagNumber(13)
  void clearVolPvc() => $_clearField(13);

  @$pb.TagNumber(14)
  $fixnum.Int64 get volUsedLast => $_getI64(13);
  @$pb.TagNumber(14)
  set volUsedLast($fixnum.Int64 value) => $_setInt64(13, value);
  @$pb.TagNumber(14)
  $core.bool hasVolUsedLast() => $_has(13);
  @$pb.TagNumber(14)
  void clearVolUsedLast() => $_clearField(14);

  @$pb.TagNumber(15)
  $fixnum.Int64 get volCapacityLast => $_getI64(14);
  @$pb.TagNumber(15)
  set volCapacityLast($fixnum.Int64 value) => $_setInt64(14, value);
  @$pb.TagNumber(15)
  $core.bool hasVolCapacityLast() => $_has(14);
  @$pb.TagNumber(15)
  void clearVolCapacityLast() => $_clearField(15);
}

class ReqAdminOpsPeaks extends $pb.GeneratedMessage {
  factory ReqAdminOpsPeaks({
    $fixnum.Int64? sinceMs,
    $fixnum.Int64? untilMs,
    $core.String? entityType,
    $core.String? nodeName,
  }) {
    final result = ReqAdminOpsPeaks._();
    if (sinceMs != null) result.sinceMs = sinceMs;
    if (untilMs != null) result.untilMs = untilMs;
    if (entityType != null) result.entityType = entityType;
    if (nodeName != null) result.nodeName = nodeName;
    return result;
  }

  ReqAdminOpsPeaks._();

  factory ReqAdminOpsPeaks.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqAdminOpsPeaks()..mergeFromBuffer(data, registry);
  factory ReqAdminOpsPeaks.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqAdminOpsPeaks()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqAdminOpsPeaks',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqAdminOpsPeaks.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'sinceMs')
    ..aInt64(2, _omitFieldNames ? '' : 'untilMs')
    ..aOS(3, _omitFieldNames ? '' : 'entityType')
    ..aOS(4, _omitFieldNames ? '' : 'nodeName')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqAdminOpsPeaks clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqAdminOpsPeaks copyWith(void Function(ReqAdminOpsPeaks) updates) =>
      super.copyWith((message) => updates(message as ReqAdminOpsPeaks))
          as ReqAdminOpsPeaks;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqAdminOpsPeaks() / ReqAdminOpsPeaks.new instead')
  static ReqAdminOpsPeaks create() => ReqAdminOpsPeaks._();
  static $pb.GeneratedMessage $_createMessage() => ReqAdminOpsPeaks._();
  @$core.override
  ReqAdminOpsPeaks createEmptyInstance() => ReqAdminOpsPeaks._();
  @$core.pragma('dart2js:noInline')
  static ReqAdminOpsPeaks getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqAdminOpsPeaks>(
          ReqAdminOpsPeaks.$_createMessage);
  static ReqAdminOpsPeaks? _defaultInstance;

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

  @$pb.TagNumber(3)
  $core.String get entityType => $_getSZ(2);
  @$pb.TagNumber(3)
  set entityType($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasEntityType() => $_has(2);
  @$pb.TagNumber(3)
  void clearEntityType() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get nodeName => $_getSZ(3);
  @$pb.TagNumber(4)
  set nodeName($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasNodeName() => $_has(3);
  @$pb.TagNumber(4)
  void clearNodeName() => $_clearField(4);
}

class ResAdminOpsPeaks extends $pb.GeneratedMessage {
  factory ResAdminOpsPeaks({
    $core.Iterable<OpsMetric1mRow>? rows,
    $core.double? peakCpuMax,
    $core.double? peakMemPctMax,
  }) {
    final result = ResAdminOpsPeaks._();
    if (rows != null) result.rows.addAll(rows);
    if (peakCpuMax != null) result.peakCpuMax = peakCpuMax;
    if (peakMemPctMax != null) result.peakMemPctMax = peakMemPctMax;
    return result;
  }

  ResAdminOpsPeaks._();

  factory ResAdminOpsPeaks.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResAdminOpsPeaks()..mergeFromBuffer(data, registry);
  factory ResAdminOpsPeaks.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResAdminOpsPeaks()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResAdminOpsPeaks',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResAdminOpsPeaks.$_createMessage)
    ..pPM<OpsMetric1mRow>(1, _omitFieldNames ? '' : 'rows',
        subBuilder: OpsMetric1mRow.$_createMessage)
    ..aD(2, _omitFieldNames ? '' : 'peakCpuMax')
    ..aD(3, _omitFieldNames ? '' : 'peakMemPctMax')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResAdminOpsPeaks clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResAdminOpsPeaks copyWith(void Function(ResAdminOpsPeaks) updates) =>
      super.copyWith((message) => updates(message as ResAdminOpsPeaks))
          as ResAdminOpsPeaks;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResAdminOpsPeaks() / ResAdminOpsPeaks.new instead')
  static ResAdminOpsPeaks create() => ResAdminOpsPeaks._();
  static $pb.GeneratedMessage $_createMessage() => ResAdminOpsPeaks._();
  @$core.override
  ResAdminOpsPeaks createEmptyInstance() => ResAdminOpsPeaks._();
  @$core.pragma('dart2js:noInline')
  static ResAdminOpsPeaks getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResAdminOpsPeaks>(
          ResAdminOpsPeaks.$_createMessage);
  static ResAdminOpsPeaks? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<OpsMetric1mRow> get rows => $_getList(0);

  @$pb.TagNumber(2)
  $core.double get peakCpuMax => $_getN(1);
  @$pb.TagNumber(2)
  set peakCpuMax($core.double value) => $_setDouble(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPeakCpuMax() => $_has(1);
  @$pb.TagNumber(2)
  void clearPeakCpuMax() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get peakMemPctMax => $_getN(2);
  @$pb.TagNumber(3)
  set peakMemPctMax($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPeakMemPctMax() => $_has(2);
  @$pb.TagNumber(3)
  void clearPeakMemPctMax() => $_clearField(3);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
