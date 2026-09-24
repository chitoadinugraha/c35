// This is a generated file - do not edit.
//
// Generated from c35/tx.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'tx.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'tx.pbenum.dart';

class TxData extends $pb.GeneratedMessage {
  factory TxData({
    $core.Iterable<$core.String>? proofs,
    TxPrompt? prompt,
    TxDelivery? delivery,
    $core.Iterable<TxPromo>? promos,
  }) {
    final result = TxData._();
    if (proofs != null) result.proofs.addAll(proofs);
    if (prompt != null) result.prompt = prompt;
    if (delivery != null) result.delivery = delivery;
    if (promos != null) result.promos.addAll(promos);
    return result;
  }

  TxData._();

  factory TxData.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TxData()..mergeFromBuffer(data, registry);
  factory TxData.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TxData()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TxData',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: TxData.$_createMessage)
    ..pPS(1, _omitFieldNames ? '' : 'proofs')
    ..aOM<TxPrompt>(2, _omitFieldNames ? '' : 'prompt',
        subBuilder: TxPrompt.$_createMessage)
    ..aOM<TxDelivery>(3, _omitFieldNames ? '' : 'delivery',
        subBuilder: TxDelivery.$_createMessage)
    ..pPM<TxPromo>(4, _omitFieldNames ? '' : 'promos',
        subBuilder: TxPromo.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TxData clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TxData copyWith(void Function(TxData) updates) =>
      super.copyWith((message) => updates(message as TxData)) as TxData;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use TxData() / TxData.new instead')
  static TxData create() => TxData._();
  static $pb.GeneratedMessage $_createMessage() => TxData._();
  @$core.override
  TxData createEmptyInstance() => TxData._();
  @$core.pragma('dart2js:noInline')
  static TxData getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TxData>(TxData.$_createMessage);
  static TxData? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get proofs => $_getList(0);

  @$pb.TagNumber(2)
  TxPrompt get prompt => $_getN(1);
  @$pb.TagNumber(2)
  set prompt(TxPrompt value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasPrompt() => $_has(1);
  @$pb.TagNumber(2)
  void clearPrompt() => $_clearField(2);
  @$pb.TagNumber(2)
  TxPrompt ensurePrompt() => $_ensure(1);

  @$pb.TagNumber(3)
  TxDelivery get delivery => $_getN(2);
  @$pb.TagNumber(3)
  set delivery(TxDelivery value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasDelivery() => $_has(2);
  @$pb.TagNumber(3)
  void clearDelivery() => $_clearField(3);
  @$pb.TagNumber(3)
  TxDelivery ensureDelivery() => $_ensure(2);

  @$pb.TagNumber(4)
  $pb.PbList<TxPromo> get promos => $_getList(3);
}

class TxPrompt extends $pb.GeneratedMessage {
  factory TxPrompt({
    $core.Iterable<$core.String>? pics,
    $core.String? desc,
  }) {
    final result = TxPrompt._();
    if (pics != null) result.pics.addAll(pics);
    if (desc != null) result.desc = desc;
    return result;
  }

  TxPrompt._();

  factory TxPrompt.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TxPrompt()..mergeFromBuffer(data, registry);
  factory TxPrompt.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TxPrompt()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TxPrompt',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: TxPrompt.$_createMessage)
    ..pPS(1, _omitFieldNames ? '' : 'pics')
    ..aOS(2, _omitFieldNames ? '' : 'desc')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TxPrompt clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TxPrompt copyWith(void Function(TxPrompt) updates) =>
      super.copyWith((message) => updates(message as TxPrompt)) as TxPrompt;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use TxPrompt() / TxPrompt.new instead')
  static TxPrompt create() => TxPrompt._();
  static $pb.GeneratedMessage $_createMessage() => TxPrompt._();
  @$core.override
  TxPrompt createEmptyInstance() => TxPrompt._();
  @$core.pragma('dart2js:noInline')
  static TxPrompt getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TxPrompt>(TxPrompt.$_createMessage);
  static TxPrompt? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get pics => $_getList(0);

  @$pb.TagNumber(2)
  $core.String get desc => $_getSZ(1);
  @$pb.TagNumber(2)
  set desc($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDesc() => $_has(1);
  @$pb.TagNumber(2)
  void clearDesc() => $_clearField(2);
}

class Tx extends $pb.GeneratedMessage {
  factory Tx({
    $fixnum.Int64? siteIid,
    $fixnum.Int64? txId,
    TxType? type,
    TxState? state,
    TxInputMode? inputMode,
    TxInputSource? inputSource,
    $core.bool? isArchived,
    $core.String? desc,
    $fixnum.Int64? timeTsMs,
    $fixnum.Int64? createdByIid,
    $core.String? cancelReason,
    $fixnum.Int64? subjectContactId,
    $core.String? subjectName,
    $core.String? subjectPhone,
    $core.String? subjectAddress,
    $core.String? cashierName,
    $fixnum.Int64? storeId,
    $fixnum.Int64? storeTgtId,
    $core.String? deliveryState,
    $fixnum.Int64? objId,
    $core.String? promoCode,
    $core.bool? isPaid,
    $core.bool? isTaskAssigned,
    TxOrderPayAt? orderPayAt,
    TxData? txData,
    $fixnum.Int64? itemsCount,
    $fixnum.Int64? itemsQty,
    $fixnum.Int64? itemsTotal,
    $fixnum.Int64? debtTotal,
    $fixnum.Int64? debtPaid,
    $fixnum.Int64? debtUnpaid,
    $fixnum.Int64? totalTaxes,
    $fixnum.Int64? totalDiscounts,
    $fixnum.Int64? totalInterest,
    $fixnum.Int64? totalPaid,
    $fixnum.Int64? totalUnpaid,
    $core.int? stockLineCount,
    $core.int? stockQtyIn,
    $core.int? stockQtyOut,
    $core.int? accLineCount,
    $fixnum.Int64? accSum,
    $core.bool? accBalanced,
    $core.bool? hasManualLines,
    $fixnum.Int64? createdTsMs,
    $fixnum.Int64? updatedTsMs,
    $fixnum.Int64? deletedTsMs,
    $fixnum.Int64? total,
    $core.Iterable<TxItem>? items,
    $core.Iterable<TxPayment>? payments,
    $core.Iterable<TxAcc>? accs,
    $core.Iterable<TxStock>? stocks,
    $core.Iterable<TxTax>? taxes,
    $core.Iterable<TxDiscount>? discounts,
  }) {
    final result = Tx._();
    if (siteIid != null) result.siteIid = siteIid;
    if (txId != null) result.txId = txId;
    if (type != null) result.type = type;
    if (state != null) result.state = state;
    if (inputMode != null) result.inputMode = inputMode;
    if (inputSource != null) result.inputSource = inputSource;
    if (isArchived != null) result.isArchived = isArchived;
    if (desc != null) result.desc = desc;
    if (timeTsMs != null) result.timeTsMs = timeTsMs;
    if (createdByIid != null) result.createdByIid = createdByIid;
    if (cancelReason != null) result.cancelReason = cancelReason;
    if (subjectContactId != null) result.subjectContactId = subjectContactId;
    if (subjectName != null) result.subjectName = subjectName;
    if (subjectPhone != null) result.subjectPhone = subjectPhone;
    if (subjectAddress != null) result.subjectAddress = subjectAddress;
    if (cashierName != null) result.cashierName = cashierName;
    if (storeId != null) result.storeId = storeId;
    if (storeTgtId != null) result.storeTgtId = storeTgtId;
    if (deliveryState != null) result.deliveryState = deliveryState;
    if (objId != null) result.objId = objId;
    if (promoCode != null) result.promoCode = promoCode;
    if (isPaid != null) result.isPaid = isPaid;
    if (isTaskAssigned != null) result.isTaskAssigned = isTaskAssigned;
    if (orderPayAt != null) result.orderPayAt = orderPayAt;
    if (txData != null) result.txData = txData;
    if (itemsCount != null) result.itemsCount = itemsCount;
    if (itemsQty != null) result.itemsQty = itemsQty;
    if (itemsTotal != null) result.itemsTotal = itemsTotal;
    if (debtTotal != null) result.debtTotal = debtTotal;
    if (debtPaid != null) result.debtPaid = debtPaid;
    if (debtUnpaid != null) result.debtUnpaid = debtUnpaid;
    if (totalTaxes != null) result.totalTaxes = totalTaxes;
    if (totalDiscounts != null) result.totalDiscounts = totalDiscounts;
    if (totalInterest != null) result.totalInterest = totalInterest;
    if (totalPaid != null) result.totalPaid = totalPaid;
    if (totalUnpaid != null) result.totalUnpaid = totalUnpaid;
    if (stockLineCount != null) result.stockLineCount = stockLineCount;
    if (stockQtyIn != null) result.stockQtyIn = stockQtyIn;
    if (stockQtyOut != null) result.stockQtyOut = stockQtyOut;
    if (accLineCount != null) result.accLineCount = accLineCount;
    if (accSum != null) result.accSum = accSum;
    if (accBalanced != null) result.accBalanced = accBalanced;
    if (hasManualLines != null) result.hasManualLines = hasManualLines;
    if (createdTsMs != null) result.createdTsMs = createdTsMs;
    if (updatedTsMs != null) result.updatedTsMs = updatedTsMs;
    if (deletedTsMs != null) result.deletedTsMs = deletedTsMs;
    if (total != null) result.total = total;
    if (items != null) result.items.addAll(items);
    if (payments != null) result.payments.addAll(payments);
    if (accs != null) result.accs.addAll(accs);
    if (stocks != null) result.stocks.addAll(stocks);
    if (taxes != null) result.taxes.addAll(taxes);
    if (discounts != null) result.discounts.addAll(discounts);
    return result;
  }

  Tx._();

  factory Tx.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Tx()..mergeFromBuffer(data, registry);
  factory Tx.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Tx()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Tx',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: Tx.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'siteIid')
    ..aInt64(2, _omitFieldNames ? '' : 'txId')
    ..aE<TxType>(3, _omitFieldNames ? '' : 'type', enumValues: TxType.values)
    ..aE<TxState>(4, _omitFieldNames ? '' : 'state', enumValues: TxState.values)
    ..aE<TxInputMode>(5, _omitFieldNames ? '' : 'inputMode',
        enumValues: TxInputMode.values)
    ..aE<TxInputSource>(6, _omitFieldNames ? '' : 'inputSource',
        enumValues: TxInputSource.values)
    ..aOB(10, _omitFieldNames ? '' : 'isArchived')
    ..aOS(11, _omitFieldNames ? '' : 'desc')
    ..aInt64(12, _omitFieldNames ? '' : 'timeTsMs')
    ..aInt64(13, _omitFieldNames ? '' : 'createdByIid')
    ..aOS(14, _omitFieldNames ? '' : 'cancelReason')
    ..aInt64(21, _omitFieldNames ? '' : 'subjectContactId')
    ..aOS(22, _omitFieldNames ? '' : 'subjectName')
    ..aOS(23, _omitFieldNames ? '' : 'subjectPhone')
    ..aOS(24, _omitFieldNames ? '' : 'subjectAddress')
    ..aOS(25, _omitFieldNames ? '' : 'cashierName')
    ..aInt64(31, _omitFieldNames ? '' : 'storeId')
    ..aInt64(33, _omitFieldNames ? '' : 'storeTgtId')
    ..aOS(34, _omitFieldNames ? '' : 'deliveryState')
    ..aInt64(41, _omitFieldNames ? '' : 'objId')
    ..aOS(53, _omitFieldNames ? '' : 'promoCode')
    ..aOB(55, _omitFieldNames ? '' : 'isPaid')
    ..aOB(56, _omitFieldNames ? '' : 'isTaskAssigned')
    ..aE<TxOrderPayAt>(57, _omitFieldNames ? '' : 'orderPayAt',
        enumValues: TxOrderPayAt.values)
    ..aOM<TxData>(100, _omitFieldNames ? '' : 'txData',
        subBuilder: TxData.$_createMessage)
    ..aInt64(121, _omitFieldNames ? '' : 'itemsCount')
    ..aInt64(122, _omitFieldNames ? '' : 'itemsQty')
    ..aInt64(123, _omitFieldNames ? '' : 'itemsTotal')
    ..aInt64(131, _omitFieldNames ? '' : 'debtTotal')
    ..aInt64(132, _omitFieldNames ? '' : 'debtPaid')
    ..aInt64(133, _omitFieldNames ? '' : 'debtUnpaid')
    ..aInt64(141, _omitFieldNames ? '' : 'totalTaxes')
    ..aInt64(142, _omitFieldNames ? '' : 'totalDiscounts')
    ..aInt64(143, _omitFieldNames ? '' : 'totalInterest')
    ..aInt64(144, _omitFieldNames ? '' : 'totalPaid')
    ..aInt64(145, _omitFieldNames ? '' : 'totalUnpaid')
    ..aI(151, _omitFieldNames ? '' : 'stockLineCount')
    ..aI(152, _omitFieldNames ? '' : 'stockQtyIn')
    ..aI(153, _omitFieldNames ? '' : 'stockQtyOut')
    ..aI(161, _omitFieldNames ? '' : 'accLineCount')
    ..aInt64(162, _omitFieldNames ? '' : 'accSum')
    ..aOB(163, _omitFieldNames ? '' : 'accBalanced')
    ..aOB(164, _omitFieldNames ? '' : 'hasManualLines')
    ..aInt64(180, _omitFieldNames ? '' : 'createdTsMs')
    ..aInt64(181, _omitFieldNames ? '' : 'updatedTsMs')
    ..aInt64(182, _omitFieldNames ? '' : 'deletedTsMs')
    ..aInt64(200, _omitFieldNames ? '' : 'total')
    ..pPM<TxItem>(201, _omitFieldNames ? '' : 'items',
        subBuilder: TxItem.$_createMessage)
    ..pPM<TxPayment>(202, _omitFieldNames ? '' : 'payments',
        subBuilder: TxPayment.$_createMessage)
    ..pPM<TxAcc>(203, _omitFieldNames ? '' : 'accs',
        subBuilder: TxAcc.$_createMessage)
    ..pPM<TxStock>(204, _omitFieldNames ? '' : 'stocks',
        subBuilder: TxStock.$_createMessage)
    ..pPM<TxTax>(205, _omitFieldNames ? '' : 'taxes',
        subBuilder: TxTax.$_createMessage)
    ..pPM<TxDiscount>(206, _omitFieldNames ? '' : 'discounts',
        subBuilder: TxDiscount.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Tx clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Tx copyWith(void Function(Tx) updates) =>
      super.copyWith((message) => updates(message as Tx)) as Tx;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Tx() / Tx.new instead')
  static Tx create() => Tx._();
  static $pb.GeneratedMessage $_createMessage() => Tx._();
  @$core.override
  Tx createEmptyInstance() => Tx._();
  @$core.pragma('dart2js:noInline')
  static Tx getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Tx>(Tx.$_createMessage);
  static Tx? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get siteIid => $_getI64(0);
  @$pb.TagNumber(1)
  set siteIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSiteIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearSiteIid() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get txId => $_getI64(1);
  @$pb.TagNumber(2)
  set txId($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTxId() => $_has(1);
  @$pb.TagNumber(2)
  void clearTxId() => $_clearField(2);

  @$pb.TagNumber(3)
  TxType get type => $_getN(2);
  @$pb.TagNumber(3)
  set type(TxType value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasType() => $_has(2);
  @$pb.TagNumber(3)
  void clearType() => $_clearField(3);

  @$pb.TagNumber(4)
  TxState get state => $_getN(3);
  @$pb.TagNumber(4)
  set state(TxState value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasState() => $_has(3);
  @$pb.TagNumber(4)
  void clearState() => $_clearField(4);

  @$pb.TagNumber(5)
  TxInputMode get inputMode => $_getN(4);
  @$pb.TagNumber(5)
  set inputMode(TxInputMode value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasInputMode() => $_has(4);
  @$pb.TagNumber(5)
  void clearInputMode() => $_clearField(5);

  @$pb.TagNumber(6)
  TxInputSource get inputSource => $_getN(5);
  @$pb.TagNumber(6)
  set inputSource(TxInputSource value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasInputSource() => $_has(5);
  @$pb.TagNumber(6)
  void clearInputSource() => $_clearField(6);

  @$pb.TagNumber(10)
  $core.bool get isArchived => $_getBF(6);
  @$pb.TagNumber(10)
  set isArchived($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(10)
  $core.bool hasIsArchived() => $_has(6);
  @$pb.TagNumber(10)
  void clearIsArchived() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.String get desc => $_getSZ(7);
  @$pb.TagNumber(11)
  set desc($core.String value) => $_setString(7, value);
  @$pb.TagNumber(11)
  $core.bool hasDesc() => $_has(7);
  @$pb.TagNumber(11)
  void clearDesc() => $_clearField(11);

  @$pb.TagNumber(12)
  $fixnum.Int64 get timeTsMs => $_getI64(8);
  @$pb.TagNumber(12)
  set timeTsMs($fixnum.Int64 value) => $_setInt64(8, value);
  @$pb.TagNumber(12)
  $core.bool hasTimeTsMs() => $_has(8);
  @$pb.TagNumber(12)
  void clearTimeTsMs() => $_clearField(12);

  @$pb.TagNumber(13)
  $fixnum.Int64 get createdByIid => $_getI64(9);
  @$pb.TagNumber(13)
  set createdByIid($fixnum.Int64 value) => $_setInt64(9, value);
  @$pb.TagNumber(13)
  $core.bool hasCreatedByIid() => $_has(9);
  @$pb.TagNumber(13)
  void clearCreatedByIid() => $_clearField(13);

  @$pb.TagNumber(14)
  $core.String get cancelReason => $_getSZ(10);
  @$pb.TagNumber(14)
  set cancelReason($core.String value) => $_setString(10, value);
  @$pb.TagNumber(14)
  $core.bool hasCancelReason() => $_has(10);
  @$pb.TagNumber(14)
  void clearCancelReason() => $_clearField(14);

  @$pb.TagNumber(21)
  $fixnum.Int64 get subjectContactId => $_getI64(11);
  @$pb.TagNumber(21)
  set subjectContactId($fixnum.Int64 value) => $_setInt64(11, value);
  @$pb.TagNumber(21)
  $core.bool hasSubjectContactId() => $_has(11);
  @$pb.TagNumber(21)
  void clearSubjectContactId() => $_clearField(21);

  @$pb.TagNumber(22)
  $core.String get subjectName => $_getSZ(12);
  @$pb.TagNumber(22)
  set subjectName($core.String value) => $_setString(12, value);
  @$pb.TagNumber(22)
  $core.bool hasSubjectName() => $_has(12);
  @$pb.TagNumber(22)
  void clearSubjectName() => $_clearField(22);

  @$pb.TagNumber(23)
  $core.String get subjectPhone => $_getSZ(13);
  @$pb.TagNumber(23)
  set subjectPhone($core.String value) => $_setString(13, value);
  @$pb.TagNumber(23)
  $core.bool hasSubjectPhone() => $_has(13);
  @$pb.TagNumber(23)
  void clearSubjectPhone() => $_clearField(23);

  @$pb.TagNumber(24)
  $core.String get subjectAddress => $_getSZ(14);
  @$pb.TagNumber(24)
  set subjectAddress($core.String value) => $_setString(14, value);
  @$pb.TagNumber(24)
  $core.bool hasSubjectAddress() => $_has(14);
  @$pb.TagNumber(24)
  void clearSubjectAddress() => $_clearField(24);

  @$pb.TagNumber(25)
  $core.String get cashierName => $_getSZ(15);
  @$pb.TagNumber(25)
  set cashierName($core.String value) => $_setString(15, value);
  @$pb.TagNumber(25)
  $core.bool hasCashierName() => $_has(15);
  @$pb.TagNumber(25)
  void clearCashierName() => $_clearField(25);

  @$pb.TagNumber(31)
  $fixnum.Int64 get storeId => $_getI64(16);
  @$pb.TagNumber(31)
  set storeId($fixnum.Int64 value) => $_setInt64(16, value);
  @$pb.TagNumber(31)
  $core.bool hasStoreId() => $_has(16);
  @$pb.TagNumber(31)
  void clearStoreId() => $_clearField(31);

  @$pb.TagNumber(33)
  $fixnum.Int64 get storeTgtId => $_getI64(17);
  @$pb.TagNumber(33)
  set storeTgtId($fixnum.Int64 value) => $_setInt64(17, value);
  @$pb.TagNumber(33)
  $core.bool hasStoreTgtId() => $_has(17);
  @$pb.TagNumber(33)
  void clearStoreTgtId() => $_clearField(33);

  @$pb.TagNumber(34)
  $core.String get deliveryState => $_getSZ(18);
  @$pb.TagNumber(34)
  set deliveryState($core.String value) => $_setString(18, value);
  @$pb.TagNumber(34)
  $core.bool hasDeliveryState() => $_has(18);
  @$pb.TagNumber(34)
  void clearDeliveryState() => $_clearField(34);

  @$pb.TagNumber(41)
  $fixnum.Int64 get objId => $_getI64(19);
  @$pb.TagNumber(41)
  set objId($fixnum.Int64 value) => $_setInt64(19, value);
  @$pb.TagNumber(41)
  $core.bool hasObjId() => $_has(19);
  @$pb.TagNumber(41)
  void clearObjId() => $_clearField(41);

  @$pb.TagNumber(53)
  $core.String get promoCode => $_getSZ(20);
  @$pb.TagNumber(53)
  set promoCode($core.String value) => $_setString(20, value);
  @$pb.TagNumber(53)
  $core.bool hasPromoCode() => $_has(20);
  @$pb.TagNumber(53)
  void clearPromoCode() => $_clearField(53);

  @$pb.TagNumber(55)
  $core.bool get isPaid => $_getBF(21);
  @$pb.TagNumber(55)
  set isPaid($core.bool value) => $_setBool(21, value);
  @$pb.TagNumber(55)
  $core.bool hasIsPaid() => $_has(21);
  @$pb.TagNumber(55)
  void clearIsPaid() => $_clearField(55);

  @$pb.TagNumber(56)
  $core.bool get isTaskAssigned => $_getBF(22);
  @$pb.TagNumber(56)
  set isTaskAssigned($core.bool value) => $_setBool(22, value);
  @$pb.TagNumber(56)
  $core.bool hasIsTaskAssigned() => $_has(22);
  @$pb.TagNumber(56)
  void clearIsTaskAssigned() => $_clearField(56);

  @$pb.TagNumber(57)
  TxOrderPayAt get orderPayAt => $_getN(23);
  @$pb.TagNumber(57)
  set orderPayAt(TxOrderPayAt value) => $_setField(57, value);
  @$pb.TagNumber(57)
  $core.bool hasOrderPayAt() => $_has(23);
  @$pb.TagNumber(57)
  void clearOrderPayAt() => $_clearField(57);

  @$pb.TagNumber(100)
  TxData get txData => $_getN(24);
  @$pb.TagNumber(100)
  set txData(TxData value) => $_setField(100, value);
  @$pb.TagNumber(100)
  $core.bool hasTxData() => $_has(24);
  @$pb.TagNumber(100)
  void clearTxData() => $_clearField(100);
  @$pb.TagNumber(100)
  TxData ensureTxData() => $_ensure(24);

  @$pb.TagNumber(121)
  $fixnum.Int64 get itemsCount => $_getI64(25);
  @$pb.TagNumber(121)
  set itemsCount($fixnum.Int64 value) => $_setInt64(25, value);
  @$pb.TagNumber(121)
  $core.bool hasItemsCount() => $_has(25);
  @$pb.TagNumber(121)
  void clearItemsCount() => $_clearField(121);

  @$pb.TagNumber(122)
  $fixnum.Int64 get itemsQty => $_getI64(26);
  @$pb.TagNumber(122)
  set itemsQty($fixnum.Int64 value) => $_setInt64(26, value);
  @$pb.TagNumber(122)
  $core.bool hasItemsQty() => $_has(26);
  @$pb.TagNumber(122)
  void clearItemsQty() => $_clearField(122);

  @$pb.TagNumber(123)
  $fixnum.Int64 get itemsTotal => $_getI64(27);
  @$pb.TagNumber(123)
  set itemsTotal($fixnum.Int64 value) => $_setInt64(27, value);
  @$pb.TagNumber(123)
  $core.bool hasItemsTotal() => $_has(27);
  @$pb.TagNumber(123)
  void clearItemsTotal() => $_clearField(123);

  @$pb.TagNumber(131)
  $fixnum.Int64 get debtTotal => $_getI64(28);
  @$pb.TagNumber(131)
  set debtTotal($fixnum.Int64 value) => $_setInt64(28, value);
  @$pb.TagNumber(131)
  $core.bool hasDebtTotal() => $_has(28);
  @$pb.TagNumber(131)
  void clearDebtTotal() => $_clearField(131);

  @$pb.TagNumber(132)
  $fixnum.Int64 get debtPaid => $_getI64(29);
  @$pb.TagNumber(132)
  set debtPaid($fixnum.Int64 value) => $_setInt64(29, value);
  @$pb.TagNumber(132)
  $core.bool hasDebtPaid() => $_has(29);
  @$pb.TagNumber(132)
  void clearDebtPaid() => $_clearField(132);

  @$pb.TagNumber(133)
  $fixnum.Int64 get debtUnpaid => $_getI64(30);
  @$pb.TagNumber(133)
  set debtUnpaid($fixnum.Int64 value) => $_setInt64(30, value);
  @$pb.TagNumber(133)
  $core.bool hasDebtUnpaid() => $_has(30);
  @$pb.TagNumber(133)
  void clearDebtUnpaid() => $_clearField(133);

  @$pb.TagNumber(141)
  $fixnum.Int64 get totalTaxes => $_getI64(31);
  @$pb.TagNumber(141)
  set totalTaxes($fixnum.Int64 value) => $_setInt64(31, value);
  @$pb.TagNumber(141)
  $core.bool hasTotalTaxes() => $_has(31);
  @$pb.TagNumber(141)
  void clearTotalTaxes() => $_clearField(141);

  @$pb.TagNumber(142)
  $fixnum.Int64 get totalDiscounts => $_getI64(32);
  @$pb.TagNumber(142)
  set totalDiscounts($fixnum.Int64 value) => $_setInt64(32, value);
  @$pb.TagNumber(142)
  $core.bool hasTotalDiscounts() => $_has(32);
  @$pb.TagNumber(142)
  void clearTotalDiscounts() => $_clearField(142);

  @$pb.TagNumber(143)
  $fixnum.Int64 get totalInterest => $_getI64(33);
  @$pb.TagNumber(143)
  set totalInterest($fixnum.Int64 value) => $_setInt64(33, value);
  @$pb.TagNumber(143)
  $core.bool hasTotalInterest() => $_has(33);
  @$pb.TagNumber(143)
  void clearTotalInterest() => $_clearField(143);

  @$pb.TagNumber(144)
  $fixnum.Int64 get totalPaid => $_getI64(34);
  @$pb.TagNumber(144)
  set totalPaid($fixnum.Int64 value) => $_setInt64(34, value);
  @$pb.TagNumber(144)
  $core.bool hasTotalPaid() => $_has(34);
  @$pb.TagNumber(144)
  void clearTotalPaid() => $_clearField(144);

  @$pb.TagNumber(145)
  $fixnum.Int64 get totalUnpaid => $_getI64(35);
  @$pb.TagNumber(145)
  set totalUnpaid($fixnum.Int64 value) => $_setInt64(35, value);
  @$pb.TagNumber(145)
  $core.bool hasTotalUnpaid() => $_has(35);
  @$pb.TagNumber(145)
  void clearTotalUnpaid() => $_clearField(145);

  @$pb.TagNumber(151)
  $core.int get stockLineCount => $_getIZ(36);
  @$pb.TagNumber(151)
  set stockLineCount($core.int value) => $_setSignedInt32(36, value);
  @$pb.TagNumber(151)
  $core.bool hasStockLineCount() => $_has(36);
  @$pb.TagNumber(151)
  void clearStockLineCount() => $_clearField(151);

  @$pb.TagNumber(152)
  $core.int get stockQtyIn => $_getIZ(37);
  @$pb.TagNumber(152)
  set stockQtyIn($core.int value) => $_setSignedInt32(37, value);
  @$pb.TagNumber(152)
  $core.bool hasStockQtyIn() => $_has(37);
  @$pb.TagNumber(152)
  void clearStockQtyIn() => $_clearField(152);

  @$pb.TagNumber(153)
  $core.int get stockQtyOut => $_getIZ(38);
  @$pb.TagNumber(153)
  set stockQtyOut($core.int value) => $_setSignedInt32(38, value);
  @$pb.TagNumber(153)
  $core.bool hasStockQtyOut() => $_has(38);
  @$pb.TagNumber(153)
  void clearStockQtyOut() => $_clearField(153);

  @$pb.TagNumber(161)
  $core.int get accLineCount => $_getIZ(39);
  @$pb.TagNumber(161)
  set accLineCount($core.int value) => $_setSignedInt32(39, value);
  @$pb.TagNumber(161)
  $core.bool hasAccLineCount() => $_has(39);
  @$pb.TagNumber(161)
  void clearAccLineCount() => $_clearField(161);

  @$pb.TagNumber(162)
  $fixnum.Int64 get accSum => $_getI64(40);
  @$pb.TagNumber(162)
  set accSum($fixnum.Int64 value) => $_setInt64(40, value);
  @$pb.TagNumber(162)
  $core.bool hasAccSum() => $_has(40);
  @$pb.TagNumber(162)
  void clearAccSum() => $_clearField(162);

  @$pb.TagNumber(163)
  $core.bool get accBalanced => $_getBF(41);
  @$pb.TagNumber(163)
  set accBalanced($core.bool value) => $_setBool(41, value);
  @$pb.TagNumber(163)
  $core.bool hasAccBalanced() => $_has(41);
  @$pb.TagNumber(163)
  void clearAccBalanced() => $_clearField(163);

  @$pb.TagNumber(164)
  $core.bool get hasManualLines => $_getBF(42);
  @$pb.TagNumber(164)
  set hasManualLines($core.bool value) => $_setBool(42, value);
  @$pb.TagNumber(164)
  $core.bool hasHasManualLines() => $_has(42);
  @$pb.TagNumber(164)
  void clearHasManualLines() => $_clearField(164);

  @$pb.TagNumber(180)
  $fixnum.Int64 get createdTsMs => $_getI64(43);
  @$pb.TagNumber(180)
  set createdTsMs($fixnum.Int64 value) => $_setInt64(43, value);
  @$pb.TagNumber(180)
  $core.bool hasCreatedTsMs() => $_has(43);
  @$pb.TagNumber(180)
  void clearCreatedTsMs() => $_clearField(180);

  @$pb.TagNumber(181)
  $fixnum.Int64 get updatedTsMs => $_getI64(44);
  @$pb.TagNumber(181)
  set updatedTsMs($fixnum.Int64 value) => $_setInt64(44, value);
  @$pb.TagNumber(181)
  $core.bool hasUpdatedTsMs() => $_has(44);
  @$pb.TagNumber(181)
  void clearUpdatedTsMs() => $_clearField(181);

  @$pb.TagNumber(182)
  $fixnum.Int64 get deletedTsMs => $_getI64(45);
  @$pb.TagNumber(182)
  set deletedTsMs($fixnum.Int64 value) => $_setInt64(45, value);
  @$pb.TagNumber(182)
  $core.bool hasDeletedTsMs() => $_has(45);
  @$pb.TagNumber(182)
  void clearDeletedTsMs() => $_clearField(182);

  @$pb.TagNumber(200)
  $fixnum.Int64 get total => $_getI64(46);
  @$pb.TagNumber(200)
  set total($fixnum.Int64 value) => $_setInt64(46, value);
  @$pb.TagNumber(200)
  $core.bool hasTotal() => $_has(46);
  @$pb.TagNumber(200)
  void clearTotal() => $_clearField(200);

  @$pb.TagNumber(201)
  $pb.PbList<TxItem> get items => $_getList(47);

  @$pb.TagNumber(202)
  $pb.PbList<TxPayment> get payments => $_getList(48);

  @$pb.TagNumber(203)
  $pb.PbList<TxAcc> get accs => $_getList(49);

  @$pb.TagNumber(204)
  $pb.PbList<TxStock> get stocks => $_getList(50);

  @$pb.TagNumber(205)
  $pb.PbList<TxTax> get taxes => $_getList(51);

  @$pb.TagNumber(206)
  $pb.PbList<TxDiscount> get discounts => $_getList(52);
}

class TxItem extends $pb.GeneratedMessage {
  factory TxItem({
    $fixnum.Int64? siteIid,
    $fixnum.Int64? txId,
    $fixnum.Int64? itemId,
    $fixnum.Int64? productId,
    $fixnum.Int64? productRev,
    $fixnum.Int64? ownerIid,
    $fixnum.Int64? price,
    $core.String? note,
    $core.int? qty,
    $core.Iterable<TxItemReservation>? reservations,
    $core.Iterable<TxItemSource>? sources,
    $core.String? batchNumber,
    $core.String? serialNumber,
    TxItemFulfillmentState? fulfillmentState,
    $fixnum.Int64? objId,
    $core.int? totalQty,
    $fixnum.Int64? totalPrice,
    $fixnum.Int64? totalDiscount,
    $fixnum.Int64? totalTax,
    $fixnum.Int64? totalNet,
    $fixnum.Int64? totalUnpaid,
    $fixnum.Int64? totalPaid,
  }) {
    final result = TxItem._();
    if (siteIid != null) result.siteIid = siteIid;
    if (txId != null) result.txId = txId;
    if (itemId != null) result.itemId = itemId;
    if (productId != null) result.productId = productId;
    if (productRev != null) result.productRev = productRev;
    if (ownerIid != null) result.ownerIid = ownerIid;
    if (price != null) result.price = price;
    if (note != null) result.note = note;
    if (qty != null) result.qty = qty;
    if (reservations != null) result.reservations.addAll(reservations);
    if (sources != null) result.sources.addAll(sources);
    if (batchNumber != null) result.batchNumber = batchNumber;
    if (serialNumber != null) result.serialNumber = serialNumber;
    if (fulfillmentState != null) result.fulfillmentState = fulfillmentState;
    if (objId != null) result.objId = objId;
    if (totalQty != null) result.totalQty = totalQty;
    if (totalPrice != null) result.totalPrice = totalPrice;
    if (totalDiscount != null) result.totalDiscount = totalDiscount;
    if (totalTax != null) result.totalTax = totalTax;
    if (totalNet != null) result.totalNet = totalNet;
    if (totalUnpaid != null) result.totalUnpaid = totalUnpaid;
    if (totalPaid != null) result.totalPaid = totalPaid;
    return result;
  }

  TxItem._();

  factory TxItem.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TxItem()..mergeFromBuffer(data, registry);
  factory TxItem.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TxItem()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TxItem',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: TxItem.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'siteIid')
    ..aInt64(2, _omitFieldNames ? '' : 'txId')
    ..aInt64(3, _omitFieldNames ? '' : 'itemId')
    ..aInt64(4, _omitFieldNames ? '' : 'productId')
    ..aInt64(5, _omitFieldNames ? '' : 'productRev')
    ..aInt64(6, _omitFieldNames ? '' : 'ownerIid')
    ..aInt64(11, _omitFieldNames ? '' : 'price')
    ..aOS(12, _omitFieldNames ? '' : 'note')
    ..aI(13, _omitFieldNames ? '' : 'qty')
    ..pPM<TxItemReservation>(21, _omitFieldNames ? '' : 'reservations',
        subBuilder: TxItemReservation.$_createMessage)
    ..pPM<TxItemSource>(31, _omitFieldNames ? '' : 'sources',
        subBuilder: TxItemSource.$_createMessage)
    ..aOS(32, _omitFieldNames ? '' : 'batchNumber')
    ..aOS(33, _omitFieldNames ? '' : 'serialNumber')
    ..aE<TxItemFulfillmentState>(37, _omitFieldNames ? '' : 'fulfillmentState',
        enumValues: TxItemFulfillmentState.values)
    ..aInt64(41, _omitFieldNames ? '' : 'objId')
    ..aI(101, _omitFieldNames ? '' : 'totalQty')
    ..aInt64(102, _omitFieldNames ? '' : 'totalPrice')
    ..aInt64(103, _omitFieldNames ? '' : 'totalDiscount')
    ..aInt64(104, _omitFieldNames ? '' : 'totalTax')
    ..aInt64(105, _omitFieldNames ? '' : 'totalNet')
    ..aInt64(201, _omitFieldNames ? '' : 'totalUnpaid')
    ..aInt64(202, _omitFieldNames ? '' : 'totalPaid')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TxItem clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TxItem copyWith(void Function(TxItem) updates) =>
      super.copyWith((message) => updates(message as TxItem)) as TxItem;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use TxItem() / TxItem.new instead')
  static TxItem create() => TxItem._();
  static $pb.GeneratedMessage $_createMessage() => TxItem._();
  @$core.override
  TxItem createEmptyInstance() => TxItem._();
  @$core.pragma('dart2js:noInline')
  static TxItem getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TxItem>(TxItem.$_createMessage);
  static TxItem? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get siteIid => $_getI64(0);
  @$pb.TagNumber(1)
  set siteIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSiteIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearSiteIid() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get txId => $_getI64(1);
  @$pb.TagNumber(2)
  set txId($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTxId() => $_has(1);
  @$pb.TagNumber(2)
  void clearTxId() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get itemId => $_getI64(2);
  @$pb.TagNumber(3)
  set itemId($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasItemId() => $_has(2);
  @$pb.TagNumber(3)
  void clearItemId() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get productId => $_getI64(3);
  @$pb.TagNumber(4)
  set productId($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasProductId() => $_has(3);
  @$pb.TagNumber(4)
  void clearProductId() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get productRev => $_getI64(4);
  @$pb.TagNumber(5)
  set productRev($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasProductRev() => $_has(4);
  @$pb.TagNumber(5)
  void clearProductRev() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get ownerIid => $_getI64(5);
  @$pb.TagNumber(6)
  set ownerIid($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasOwnerIid() => $_has(5);
  @$pb.TagNumber(6)
  void clearOwnerIid() => $_clearField(6);

  @$pb.TagNumber(11)
  $fixnum.Int64 get price => $_getI64(6);
  @$pb.TagNumber(11)
  set price($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(11)
  $core.bool hasPrice() => $_has(6);
  @$pb.TagNumber(11)
  void clearPrice() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.String get note => $_getSZ(7);
  @$pb.TagNumber(12)
  set note($core.String value) => $_setString(7, value);
  @$pb.TagNumber(12)
  $core.bool hasNote() => $_has(7);
  @$pb.TagNumber(12)
  void clearNote() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.int get qty => $_getIZ(8);
  @$pb.TagNumber(13)
  set qty($core.int value) => $_setSignedInt32(8, value);
  @$pb.TagNumber(13)
  $core.bool hasQty() => $_has(8);
  @$pb.TagNumber(13)
  void clearQty() => $_clearField(13);

  @$pb.TagNumber(21)
  $pb.PbList<TxItemReservation> get reservations => $_getList(9);

  @$pb.TagNumber(31)
  $pb.PbList<TxItemSource> get sources => $_getList(10);

  @$pb.TagNumber(32)
  $core.String get batchNumber => $_getSZ(11);
  @$pb.TagNumber(32)
  set batchNumber($core.String value) => $_setString(11, value);
  @$pb.TagNumber(32)
  $core.bool hasBatchNumber() => $_has(11);
  @$pb.TagNumber(32)
  void clearBatchNumber() => $_clearField(32);

  @$pb.TagNumber(33)
  $core.String get serialNumber => $_getSZ(12);
  @$pb.TagNumber(33)
  set serialNumber($core.String value) => $_setString(12, value);
  @$pb.TagNumber(33)
  $core.bool hasSerialNumber() => $_has(12);
  @$pb.TagNumber(33)
  void clearSerialNumber() => $_clearField(33);

  @$pb.TagNumber(37)
  TxItemFulfillmentState get fulfillmentState => $_getN(13);
  @$pb.TagNumber(37)
  set fulfillmentState(TxItemFulfillmentState value) => $_setField(37, value);
  @$pb.TagNumber(37)
  $core.bool hasFulfillmentState() => $_has(13);
  @$pb.TagNumber(37)
  void clearFulfillmentState() => $_clearField(37);

  @$pb.TagNumber(41)
  $fixnum.Int64 get objId => $_getI64(14);
  @$pb.TagNumber(41)
  set objId($fixnum.Int64 value) => $_setInt64(14, value);
  @$pb.TagNumber(41)
  $core.bool hasObjId() => $_has(14);
  @$pb.TagNumber(41)
  void clearObjId() => $_clearField(41);

  @$pb.TagNumber(101)
  $core.int get totalQty => $_getIZ(15);
  @$pb.TagNumber(101)
  set totalQty($core.int value) => $_setSignedInt32(15, value);
  @$pb.TagNumber(101)
  $core.bool hasTotalQty() => $_has(15);
  @$pb.TagNumber(101)
  void clearTotalQty() => $_clearField(101);

  @$pb.TagNumber(102)
  $fixnum.Int64 get totalPrice => $_getI64(16);
  @$pb.TagNumber(102)
  set totalPrice($fixnum.Int64 value) => $_setInt64(16, value);
  @$pb.TagNumber(102)
  $core.bool hasTotalPrice() => $_has(16);
  @$pb.TagNumber(102)
  void clearTotalPrice() => $_clearField(102);

  @$pb.TagNumber(103)
  $fixnum.Int64 get totalDiscount => $_getI64(17);
  @$pb.TagNumber(103)
  set totalDiscount($fixnum.Int64 value) => $_setInt64(17, value);
  @$pb.TagNumber(103)
  $core.bool hasTotalDiscount() => $_has(17);
  @$pb.TagNumber(103)
  void clearTotalDiscount() => $_clearField(103);

  @$pb.TagNumber(104)
  $fixnum.Int64 get totalTax => $_getI64(18);
  @$pb.TagNumber(104)
  set totalTax($fixnum.Int64 value) => $_setInt64(18, value);
  @$pb.TagNumber(104)
  $core.bool hasTotalTax() => $_has(18);
  @$pb.TagNumber(104)
  void clearTotalTax() => $_clearField(104);

  @$pb.TagNumber(105)
  $fixnum.Int64 get totalNet => $_getI64(19);
  @$pb.TagNumber(105)
  set totalNet($fixnum.Int64 value) => $_setInt64(19, value);
  @$pb.TagNumber(105)
  $core.bool hasTotalNet() => $_has(19);
  @$pb.TagNumber(105)
  void clearTotalNet() => $_clearField(105);

  @$pb.TagNumber(201)
  $fixnum.Int64 get totalUnpaid => $_getI64(20);
  @$pb.TagNumber(201)
  set totalUnpaid($fixnum.Int64 value) => $_setInt64(20, value);
  @$pb.TagNumber(201)
  $core.bool hasTotalUnpaid() => $_has(20);
  @$pb.TagNumber(201)
  void clearTotalUnpaid() => $_clearField(201);

  @$pb.TagNumber(202)
  $fixnum.Int64 get totalPaid => $_getI64(21);
  @$pb.TagNumber(202)
  set totalPaid($fixnum.Int64 value) => $_setInt64(21, value);
  @$pb.TagNumber(202)
  $core.bool hasTotalPaid() => $_has(21);
  @$pb.TagNumber(202)
  void clearTotalPaid() => $_clearField(202);
}

class TxItemReservation extends $pb.GeneratedMessage {
  factory TxItemReservation({
    $fixnum.Int64? resId,
    $fixnum.Int64? productId,
    $core.int? qty,
    $core.int? durationQty,
    $core.String? note,
    $fixnum.Int64? startTsMs,
    $fixnum.Int64? endTsMs,
    $core.String? state,
    $core.bool? isNoShow,
    $core.bool? isUnavailable,
  }) {
    final result = TxItemReservation._();
    if (resId != null) result.resId = resId;
    if (productId != null) result.productId = productId;
    if (qty != null) result.qty = qty;
    if (durationQty != null) result.durationQty = durationQty;
    if (note != null) result.note = note;
    if (startTsMs != null) result.startTsMs = startTsMs;
    if (endTsMs != null) result.endTsMs = endTsMs;
    if (state != null) result.state = state;
    if (isNoShow != null) result.isNoShow = isNoShow;
    if (isUnavailable != null) result.isUnavailable = isUnavailable;
    return result;
  }

  TxItemReservation._();

  factory TxItemReservation.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TxItemReservation()..mergeFromBuffer(data, registry);
  factory TxItemReservation.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TxItemReservation()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TxItemReservation',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: TxItemReservation.$_createMessage)
    ..aInt64(4, _omitFieldNames ? '' : 'resId')
    ..aInt64(5, _omitFieldNames ? '' : 'productId')
    ..aI(10, _omitFieldNames ? '' : 'qty')
    ..aI(11, _omitFieldNames ? '' : 'durationQty')
    ..aOS(12, _omitFieldNames ? '' : 'note')
    ..aInt64(20, _omitFieldNames ? '' : 'startTsMs')
    ..aInt64(21, _omitFieldNames ? '' : 'endTsMs')
    ..aOS(30, _omitFieldNames ? '' : 'state')
    ..aOB(31, _omitFieldNames ? '' : 'isNoShow')
    ..aOB(32, _omitFieldNames ? '' : 'isUnavailable')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TxItemReservation clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TxItemReservation copyWith(void Function(TxItemReservation) updates) =>
      super.copyWith((message) => updates(message as TxItemReservation))
          as TxItemReservation;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use TxItemReservation() / TxItemReservation.new instead')
  static TxItemReservation create() => TxItemReservation._();
  static $pb.GeneratedMessage $_createMessage() => TxItemReservation._();
  @$core.override
  TxItemReservation createEmptyInstance() => TxItemReservation._();
  @$core.pragma('dart2js:noInline')
  static TxItemReservation getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TxItemReservation>(
          TxItemReservation.$_createMessage);
  static TxItemReservation? _defaultInstance;

  @$pb.TagNumber(4)
  $fixnum.Int64 get resId => $_getI64(0);
  @$pb.TagNumber(4)
  set resId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(4)
  $core.bool hasResId() => $_has(0);
  @$pb.TagNumber(4)
  void clearResId() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get productId => $_getI64(1);
  @$pb.TagNumber(5)
  set productId($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(5)
  $core.bool hasProductId() => $_has(1);
  @$pb.TagNumber(5)
  void clearProductId() => $_clearField(5);

  @$pb.TagNumber(10)
  $core.int get qty => $_getIZ(2);
  @$pb.TagNumber(10)
  set qty($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(10)
  $core.bool hasQty() => $_has(2);
  @$pb.TagNumber(10)
  void clearQty() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.int get durationQty => $_getIZ(3);
  @$pb.TagNumber(11)
  set durationQty($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(11)
  $core.bool hasDurationQty() => $_has(3);
  @$pb.TagNumber(11)
  void clearDurationQty() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.String get note => $_getSZ(4);
  @$pb.TagNumber(12)
  set note($core.String value) => $_setString(4, value);
  @$pb.TagNumber(12)
  $core.bool hasNote() => $_has(4);
  @$pb.TagNumber(12)
  void clearNote() => $_clearField(12);

  @$pb.TagNumber(20)
  $fixnum.Int64 get startTsMs => $_getI64(5);
  @$pb.TagNumber(20)
  set startTsMs($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(20)
  $core.bool hasStartTsMs() => $_has(5);
  @$pb.TagNumber(20)
  void clearStartTsMs() => $_clearField(20);

  @$pb.TagNumber(21)
  $fixnum.Int64 get endTsMs => $_getI64(6);
  @$pb.TagNumber(21)
  set endTsMs($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(21)
  $core.bool hasEndTsMs() => $_has(6);
  @$pb.TagNumber(21)
  void clearEndTsMs() => $_clearField(21);

  @$pb.TagNumber(30)
  $core.String get state => $_getSZ(7);
  @$pb.TagNumber(30)
  set state($core.String value) => $_setString(7, value);
  @$pb.TagNumber(30)
  $core.bool hasState() => $_has(7);
  @$pb.TagNumber(30)
  void clearState() => $_clearField(30);

  @$pb.TagNumber(31)
  $core.bool get isNoShow => $_getBF(8);
  @$pb.TagNumber(31)
  set isNoShow($core.bool value) => $_setBool(8, value);
  @$pb.TagNumber(31)
  $core.bool hasIsNoShow() => $_has(8);
  @$pb.TagNumber(31)
  void clearIsNoShow() => $_clearField(31);

  @$pb.TagNumber(32)
  $core.bool get isUnavailable => $_getBF(9);
  @$pb.TagNumber(32)
  set isUnavailable($core.bool value) => $_setBool(9, value);
  @$pb.TagNumber(32)
  $core.bool hasIsUnavailable() => $_has(9);
  @$pb.TagNumber(32)
  void clearIsUnavailable() => $_clearField(32);
}

class TxItemSource extends $pb.GeneratedMessage {
  factory TxItemSource({
    $fixnum.Int64? srcId,
    $fixnum.Int64? objId,
    $fixnum.Int64? productId,
    $core.int? qty,
    $core.String? note,
  }) {
    final result = TxItemSource._();
    if (srcId != null) result.srcId = srcId;
    if (objId != null) result.objId = objId;
    if (productId != null) result.productId = productId;
    if (qty != null) result.qty = qty;
    if (note != null) result.note = note;
    return result;
  }

  TxItemSource._();

  factory TxItemSource.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TxItemSource()..mergeFromBuffer(data, registry);
  factory TxItemSource.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TxItemSource()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TxItemSource',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: TxItemSource.$_createMessage)
    ..aInt64(4, _omitFieldNames ? '' : 'srcId')
    ..aInt64(10, _omitFieldNames ? '' : 'objId')
    ..aInt64(11, _omitFieldNames ? '' : 'productId')
    ..aI(12, _omitFieldNames ? '' : 'qty')
    ..aOS(13, _omitFieldNames ? '' : 'note')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TxItemSource clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TxItemSource copyWith(void Function(TxItemSource) updates) =>
      super.copyWith((message) => updates(message as TxItemSource))
          as TxItemSource;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use TxItemSource() / TxItemSource.new instead')
  static TxItemSource create() => TxItemSource._();
  static $pb.GeneratedMessage $_createMessage() => TxItemSource._();
  @$core.override
  TxItemSource createEmptyInstance() => TxItemSource._();
  @$core.pragma('dart2js:noInline')
  static TxItemSource getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TxItemSource>(
          TxItemSource.$_createMessage);
  static TxItemSource? _defaultInstance;

  @$pb.TagNumber(4)
  $fixnum.Int64 get srcId => $_getI64(0);
  @$pb.TagNumber(4)
  set srcId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(4)
  $core.bool hasSrcId() => $_has(0);
  @$pb.TagNumber(4)
  void clearSrcId() => $_clearField(4);

  @$pb.TagNumber(10)
  $fixnum.Int64 get objId => $_getI64(1);
  @$pb.TagNumber(10)
  set objId($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(10)
  $core.bool hasObjId() => $_has(1);
  @$pb.TagNumber(10)
  void clearObjId() => $_clearField(10);

  @$pb.TagNumber(11)
  $fixnum.Int64 get productId => $_getI64(2);
  @$pb.TagNumber(11)
  set productId($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(11)
  $core.bool hasProductId() => $_has(2);
  @$pb.TagNumber(11)
  void clearProductId() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.int get qty => $_getIZ(3);
  @$pb.TagNumber(12)
  set qty($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(12)
  $core.bool hasQty() => $_has(3);
  @$pb.TagNumber(12)
  void clearQty() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.String get note => $_getSZ(4);
  @$pb.TagNumber(13)
  set note($core.String value) => $_setString(4, value);
  @$pb.TagNumber(13)
  $core.bool hasNote() => $_has(4);
  @$pb.TagNumber(13)
  void clearNote() => $_clearField(13);
}

class TxDelivery extends $pb.GeneratedMessage {
  factory TxDelivery({
    $fixnum.Int64? objId,
    $fixnum.Int64? contactId,
    $fixnum.Int64? userIid,
    TxDeliveryTo? to,
    TxDeliveryService? service,
    $core.String? state,
  }) {
    final result = TxDelivery._();
    if (objId != null) result.objId = objId;
    if (contactId != null) result.contactId = contactId;
    if (userIid != null) result.userIid = userIid;
    if (to != null) result.to = to;
    if (service != null) result.service = service;
    if (state != null) result.state = state;
    return result;
  }

  TxDelivery._();

  factory TxDelivery.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TxDelivery()..mergeFromBuffer(data, registry);
  factory TxDelivery.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TxDelivery()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TxDelivery',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: TxDelivery.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'objId')
    ..aInt64(2, _omitFieldNames ? '' : 'contactId')
    ..aInt64(3, _omitFieldNames ? '' : 'userIid')
    ..aOM<TxDeliveryTo>(11, _omitFieldNames ? '' : 'to',
        subBuilder: TxDeliveryTo.$_createMessage)
    ..aOM<TxDeliveryService>(12, _omitFieldNames ? '' : 'service',
        subBuilder: TxDeliveryService.$_createMessage)
    ..aOS(200, _omitFieldNames ? '' : 'state')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TxDelivery clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TxDelivery copyWith(void Function(TxDelivery) updates) =>
      super.copyWith((message) => updates(message as TxDelivery)) as TxDelivery;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use TxDelivery() / TxDelivery.new instead')
  static TxDelivery create() => TxDelivery._();
  static $pb.GeneratedMessage $_createMessage() => TxDelivery._();
  @$core.override
  TxDelivery createEmptyInstance() => TxDelivery._();
  @$core.pragma('dart2js:noInline')
  static TxDelivery getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TxDelivery>(TxDelivery.$_createMessage);
  static TxDelivery? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get objId => $_getI64(0);
  @$pb.TagNumber(1)
  set objId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasObjId() => $_has(0);
  @$pb.TagNumber(1)
  void clearObjId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get contactId => $_getI64(1);
  @$pb.TagNumber(2)
  set contactId($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasContactId() => $_has(1);
  @$pb.TagNumber(2)
  void clearContactId() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get userIid => $_getI64(2);
  @$pb.TagNumber(3)
  set userIid($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasUserIid() => $_has(2);
  @$pb.TagNumber(3)
  void clearUserIid() => $_clearField(3);

  @$pb.TagNumber(11)
  TxDeliveryTo get to => $_getN(3);
  @$pb.TagNumber(11)
  set to(TxDeliveryTo value) => $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasTo() => $_has(3);
  @$pb.TagNumber(11)
  void clearTo() => $_clearField(11);
  @$pb.TagNumber(11)
  TxDeliveryTo ensureTo() => $_ensure(3);

  @$pb.TagNumber(12)
  TxDeliveryService get service => $_getN(4);
  @$pb.TagNumber(12)
  set service(TxDeliveryService value) => $_setField(12, value);
  @$pb.TagNumber(12)
  $core.bool hasService() => $_has(4);
  @$pb.TagNumber(12)
  void clearService() => $_clearField(12);
  @$pb.TagNumber(12)
  TxDeliveryService ensureService() => $_ensure(4);

  @$pb.TagNumber(200)
  $core.String get state => $_getSZ(5);
  @$pb.TagNumber(200)
  set state($core.String value) => $_setString(5, value);
  @$pb.TagNumber(200)
  $core.bool hasState() => $_has(5);
  @$pb.TagNumber(200)
  void clearState() => $_clearField(200);
}

class TxDeliveryTo extends $pb.GeneratedMessage {
  factory TxDeliveryTo({
    $core.String? name,
    $core.String? phone,
    $core.String? address,
    $core.String? email,
  }) {
    final result = TxDeliveryTo._();
    if (name != null) result.name = name;
    if (phone != null) result.phone = phone;
    if (address != null) result.address = address;
    if (email != null) result.email = email;
    return result;
  }

  TxDeliveryTo._();

  factory TxDeliveryTo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TxDeliveryTo()..mergeFromBuffer(data, registry);
  factory TxDeliveryTo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TxDeliveryTo()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TxDeliveryTo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: TxDeliveryTo.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'phone')
    ..aOS(3, _omitFieldNames ? '' : 'address')
    ..aOS(4, _omitFieldNames ? '' : 'email')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TxDeliveryTo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TxDeliveryTo copyWith(void Function(TxDeliveryTo) updates) =>
      super.copyWith((message) => updates(message as TxDeliveryTo))
          as TxDeliveryTo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use TxDeliveryTo() / TxDeliveryTo.new instead')
  static TxDeliveryTo create() => TxDeliveryTo._();
  static $pb.GeneratedMessage $_createMessage() => TxDeliveryTo._();
  @$core.override
  TxDeliveryTo createEmptyInstance() => TxDeliveryTo._();
  @$core.pragma('dart2js:noInline')
  static TxDeliveryTo getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TxDeliveryTo>(
          TxDeliveryTo.$_createMessage);
  static TxDeliveryTo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get phone => $_getSZ(1);
  @$pb.TagNumber(2)
  set phone($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPhone() => $_has(1);
  @$pb.TagNumber(2)
  void clearPhone() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get address => $_getSZ(2);
  @$pb.TagNumber(3)
  set address($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAddress() => $_has(2);
  @$pb.TagNumber(3)
  void clearAddress() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get email => $_getSZ(3);
  @$pb.TagNumber(4)
  set email($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasEmail() => $_has(3);
  @$pb.TagNumber(4)
  void clearEmail() => $_clearField(4);
}

class TxDeliveryService extends $pb.GeneratedMessage {
  factory TxDeliveryService({
    $core.String? name,
    $core.String? trackingNumber,
    $core.String? trackingUrl,
    $core.String? note,
  }) {
    final result = TxDeliveryService._();
    if (name != null) result.name = name;
    if (trackingNumber != null) result.trackingNumber = trackingNumber;
    if (trackingUrl != null) result.trackingUrl = trackingUrl;
    if (note != null) result.note = note;
    return result;
  }

  TxDeliveryService._();

  factory TxDeliveryService.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TxDeliveryService()..mergeFromBuffer(data, registry);
  factory TxDeliveryService.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TxDeliveryService()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TxDeliveryService',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: TxDeliveryService.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'trackingNumber')
    ..aOS(3, _omitFieldNames ? '' : 'trackingUrl')
    ..aOS(4, _omitFieldNames ? '' : 'note')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TxDeliveryService clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TxDeliveryService copyWith(void Function(TxDeliveryService) updates) =>
      super.copyWith((message) => updates(message as TxDeliveryService))
          as TxDeliveryService;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use TxDeliveryService() / TxDeliveryService.new instead')
  static TxDeliveryService create() => TxDeliveryService._();
  static $pb.GeneratedMessage $_createMessage() => TxDeliveryService._();
  @$core.override
  TxDeliveryService createEmptyInstance() => TxDeliveryService._();
  @$core.pragma('dart2js:noInline')
  static TxDeliveryService getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TxDeliveryService>(
          TxDeliveryService.$_createMessage);
  static TxDeliveryService? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get trackingNumber => $_getSZ(1);
  @$pb.TagNumber(2)
  set trackingNumber($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTrackingNumber() => $_has(1);
  @$pb.TagNumber(2)
  void clearTrackingNumber() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get trackingUrl => $_getSZ(2);
  @$pb.TagNumber(3)
  set trackingUrl($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTrackingUrl() => $_has(2);
  @$pb.TagNumber(3)
  void clearTrackingUrl() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get note => $_getSZ(3);
  @$pb.TagNumber(4)
  set note($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasNote() => $_has(3);
  @$pb.TagNumber(4)
  void clearNote() => $_clearField(4);
}

class TxDiscount extends $pb.GeneratedMessage {
  factory TxDiscount({
    $fixnum.Int64? discountId,
    $core.String? discountType,
    $fixnum.Int64? amount,
    $core.String? note,
  }) {
    final result = TxDiscount._();
    if (discountId != null) result.discountId = discountId;
    if (discountType != null) result.discountType = discountType;
    if (amount != null) result.amount = amount;
    if (note != null) result.note = note;
    return result;
  }

  TxDiscount._();

  factory TxDiscount.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TxDiscount()..mergeFromBuffer(data, registry);
  factory TxDiscount.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TxDiscount()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TxDiscount',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: TxDiscount.$_createMessage)
    ..aInt64(3, _omitFieldNames ? '' : 'discountId')
    ..aOS(10, _omitFieldNames ? '' : 'discountType')
    ..aInt64(11, _omitFieldNames ? '' : 'amount')
    ..aOS(12, _omitFieldNames ? '' : 'note')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TxDiscount clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TxDiscount copyWith(void Function(TxDiscount) updates) =>
      super.copyWith((message) => updates(message as TxDiscount)) as TxDiscount;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use TxDiscount() / TxDiscount.new instead')
  static TxDiscount create() => TxDiscount._();
  static $pb.GeneratedMessage $_createMessage() => TxDiscount._();
  @$core.override
  TxDiscount createEmptyInstance() => TxDiscount._();
  @$core.pragma('dart2js:noInline')
  static TxDiscount getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TxDiscount>(TxDiscount.$_createMessage);
  static TxDiscount? _defaultInstance;

  @$pb.TagNumber(3)
  $fixnum.Int64 get discountId => $_getI64(0);
  @$pb.TagNumber(3)
  set discountId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(3)
  $core.bool hasDiscountId() => $_has(0);
  @$pb.TagNumber(3)
  void clearDiscountId() => $_clearField(3);

  @$pb.TagNumber(10)
  $core.String get discountType => $_getSZ(1);
  @$pb.TagNumber(10)
  set discountType($core.String value) => $_setString(1, value);
  @$pb.TagNumber(10)
  $core.bool hasDiscountType() => $_has(1);
  @$pb.TagNumber(10)
  void clearDiscountType() => $_clearField(10);

  @$pb.TagNumber(11)
  $fixnum.Int64 get amount => $_getI64(2);
  @$pb.TagNumber(11)
  set amount($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(11)
  $core.bool hasAmount() => $_has(2);
  @$pb.TagNumber(11)
  void clearAmount() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.String get note => $_getSZ(3);
  @$pb.TagNumber(12)
  set note($core.String value) => $_setString(3, value);
  @$pb.TagNumber(12)
  $core.bool hasNote() => $_has(3);
  @$pb.TagNumber(12)
  void clearNote() => $_clearField(12);
}

class TxTax extends $pb.GeneratedMessage {
  factory TxTax({
    $fixnum.Int64? taxId,
    $core.String? taxType,
    $fixnum.Int64? amount,
    $core.String? note,
  }) {
    final result = TxTax._();
    if (taxId != null) result.taxId = taxId;
    if (taxType != null) result.taxType = taxType;
    if (amount != null) result.amount = amount;
    if (note != null) result.note = note;
    return result;
  }

  TxTax._();

  factory TxTax.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TxTax()..mergeFromBuffer(data, registry);
  factory TxTax.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TxTax()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TxTax',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: TxTax.$_createMessage)
    ..aInt64(3, _omitFieldNames ? '' : 'taxId')
    ..aOS(10, _omitFieldNames ? '' : 'taxType')
    ..aInt64(11, _omitFieldNames ? '' : 'amount')
    ..aOS(12, _omitFieldNames ? '' : 'note')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TxTax clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TxTax copyWith(void Function(TxTax) updates) =>
      super.copyWith((message) => updates(message as TxTax)) as TxTax;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use TxTax() / TxTax.new instead')
  static TxTax create() => TxTax._();
  static $pb.GeneratedMessage $_createMessage() => TxTax._();
  @$core.override
  TxTax createEmptyInstance() => TxTax._();
  @$core.pragma('dart2js:noInline')
  static TxTax getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TxTax>(TxTax.$_createMessage);
  static TxTax? _defaultInstance;

  @$pb.TagNumber(3)
  $fixnum.Int64 get taxId => $_getI64(0);
  @$pb.TagNumber(3)
  set taxId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(3)
  $core.bool hasTaxId() => $_has(0);
  @$pb.TagNumber(3)
  void clearTaxId() => $_clearField(3);

  @$pb.TagNumber(10)
  $core.String get taxType => $_getSZ(1);
  @$pb.TagNumber(10)
  set taxType($core.String value) => $_setString(1, value);
  @$pb.TagNumber(10)
  $core.bool hasTaxType() => $_has(1);
  @$pb.TagNumber(10)
  void clearTaxType() => $_clearField(10);

  @$pb.TagNumber(11)
  $fixnum.Int64 get amount => $_getI64(2);
  @$pb.TagNumber(11)
  set amount($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(11)
  $core.bool hasAmount() => $_has(2);
  @$pb.TagNumber(11)
  void clearAmount() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.String get note => $_getSZ(3);
  @$pb.TagNumber(12)
  set note($core.String value) => $_setString(3, value);
  @$pb.TagNumber(12)
  $core.bool hasNote() => $_has(3);
  @$pb.TagNumber(12)
  void clearNote() => $_clearField(12);
}

class TxPromo extends $pb.GeneratedMessage {
  factory TxPromo({
    $core.String? promoId,
    $core.String? code,
    $core.String? name,
    $fixnum.Int64? amount,
  }) {
    final result = TxPromo._();
    if (promoId != null) result.promoId = promoId;
    if (code != null) result.code = code;
    if (name != null) result.name = name;
    if (amount != null) result.amount = amount;
    return result;
  }

  TxPromo._();

  factory TxPromo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TxPromo()..mergeFromBuffer(data, registry);
  factory TxPromo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TxPromo()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TxPromo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: TxPromo.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'promoId')
    ..aOS(2, _omitFieldNames ? '' : 'code')
    ..aOS(3, _omitFieldNames ? '' : 'name')
    ..aInt64(4, _omitFieldNames ? '' : 'amount')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TxPromo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TxPromo copyWith(void Function(TxPromo) updates) =>
      super.copyWith((message) => updates(message as TxPromo)) as TxPromo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use TxPromo() / TxPromo.new instead')
  static TxPromo create() => TxPromo._();
  static $pb.GeneratedMessage $_createMessage() => TxPromo._();
  @$core.override
  TxPromo createEmptyInstance() => TxPromo._();
  @$core.pragma('dart2js:noInline')
  static TxPromo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TxPromo>(TxPromo.$_createMessage);
  static TxPromo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get promoId => $_getSZ(0);
  @$pb.TagNumber(1)
  set promoId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPromoId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPromoId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get code => $_getSZ(1);
  @$pb.TagNumber(2)
  set code($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCode() => $_has(1);
  @$pb.TagNumber(2)
  void clearCode() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get name => $_getSZ(2);
  @$pb.TagNumber(3)
  set name($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasName() => $_has(2);
  @$pb.TagNumber(3)
  void clearName() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get amount => $_getI64(3);
  @$pb.TagNumber(4)
  set amount($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAmount() => $_has(3);
  @$pb.TagNumber(4)
  void clearAmount() => $_clearField(4);
}

class TxPayment extends $pb.GeneratedMessage {
  factory TxPayment({
    $fixnum.Int64? paymentId,
    TxPaymentMethod? method,
    $fixnum.Int64? tsMs,
    $fixnum.Int64? amount,
    $core.String? note,
    $core.String? fromWallet,
    $core.String? toWallet,
    $fixnum.Int64? debtInterest,
    $core.String? paymentJson,
    $core.Iterable<TxInstallment>? installments,
  }) {
    final result = TxPayment._();
    if (paymentId != null) result.paymentId = paymentId;
    if (method != null) result.method = method;
    if (tsMs != null) result.tsMs = tsMs;
    if (amount != null) result.amount = amount;
    if (note != null) result.note = note;
    if (fromWallet != null) result.fromWallet = fromWallet;
    if (toWallet != null) result.toWallet = toWallet;
    if (debtInterest != null) result.debtInterest = debtInterest;
    if (paymentJson != null) result.paymentJson = paymentJson;
    if (installments != null) result.installments.addAll(installments);
    return result;
  }

  TxPayment._();

  factory TxPayment.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TxPayment()..mergeFromBuffer(data, registry);
  factory TxPayment.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TxPayment()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TxPayment',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: TxPayment.$_createMessage)
    ..aInt64(3, _omitFieldNames ? '' : 'paymentId')
    ..aE<TxPaymentMethod>(10, _omitFieldNames ? '' : 'method',
        enumValues: TxPaymentMethod.values)
    ..aInt64(11, _omitFieldNames ? '' : 'tsMs')
    ..aInt64(12, _omitFieldNames ? '' : 'amount')
    ..aOS(13, _omitFieldNames ? '' : 'note')
    ..aOS(20, _omitFieldNames ? '' : 'fromWallet')
    ..aOS(21, _omitFieldNames ? '' : 'toWallet')
    ..aInt64(25, _omitFieldNames ? '' : 'debtInterest')
    ..aOS(100, _omitFieldNames ? '' : 'paymentJson')
    ..pPM<TxInstallment>(110, _omitFieldNames ? '' : 'installments',
        subBuilder: TxInstallment.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TxPayment clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TxPayment copyWith(void Function(TxPayment) updates) =>
      super.copyWith((message) => updates(message as TxPayment)) as TxPayment;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use TxPayment() / TxPayment.new instead')
  static TxPayment create() => TxPayment._();
  static $pb.GeneratedMessage $_createMessage() => TxPayment._();
  @$core.override
  TxPayment createEmptyInstance() => TxPayment._();
  @$core.pragma('dart2js:noInline')
  static TxPayment getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TxPayment>(TxPayment.$_createMessage);
  static TxPayment? _defaultInstance;

  @$pb.TagNumber(3)
  $fixnum.Int64 get paymentId => $_getI64(0);
  @$pb.TagNumber(3)
  set paymentId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(3)
  $core.bool hasPaymentId() => $_has(0);
  @$pb.TagNumber(3)
  void clearPaymentId() => $_clearField(3);

  @$pb.TagNumber(10)
  TxPaymentMethod get method => $_getN(1);
  @$pb.TagNumber(10)
  set method(TxPaymentMethod value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasMethod() => $_has(1);
  @$pb.TagNumber(10)
  void clearMethod() => $_clearField(10);

  @$pb.TagNumber(11)
  $fixnum.Int64 get tsMs => $_getI64(2);
  @$pb.TagNumber(11)
  set tsMs($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(11)
  $core.bool hasTsMs() => $_has(2);
  @$pb.TagNumber(11)
  void clearTsMs() => $_clearField(11);

  @$pb.TagNumber(12)
  $fixnum.Int64 get amount => $_getI64(3);
  @$pb.TagNumber(12)
  set amount($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(12)
  $core.bool hasAmount() => $_has(3);
  @$pb.TagNumber(12)
  void clearAmount() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.String get note => $_getSZ(4);
  @$pb.TagNumber(13)
  set note($core.String value) => $_setString(4, value);
  @$pb.TagNumber(13)
  $core.bool hasNote() => $_has(4);
  @$pb.TagNumber(13)
  void clearNote() => $_clearField(13);

  @$pb.TagNumber(20)
  $core.String get fromWallet => $_getSZ(5);
  @$pb.TagNumber(20)
  set fromWallet($core.String value) => $_setString(5, value);
  @$pb.TagNumber(20)
  $core.bool hasFromWallet() => $_has(5);
  @$pb.TagNumber(20)
  void clearFromWallet() => $_clearField(20);

  @$pb.TagNumber(21)
  $core.String get toWallet => $_getSZ(6);
  @$pb.TagNumber(21)
  set toWallet($core.String value) => $_setString(6, value);
  @$pb.TagNumber(21)
  $core.bool hasToWallet() => $_has(6);
  @$pb.TagNumber(21)
  void clearToWallet() => $_clearField(21);

  @$pb.TagNumber(25)
  $fixnum.Int64 get debtInterest => $_getI64(7);
  @$pb.TagNumber(25)
  set debtInterest($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(25)
  $core.bool hasDebtInterest() => $_has(7);
  @$pb.TagNumber(25)
  void clearDebtInterest() => $_clearField(25);

  @$pb.TagNumber(100)
  $core.String get paymentJson => $_getSZ(8);
  @$pb.TagNumber(100)
  set paymentJson($core.String value) => $_setString(8, value);
  @$pb.TagNumber(100)
  $core.bool hasPaymentJson() => $_has(8);
  @$pb.TagNumber(100)
  void clearPaymentJson() => $_clearField(100);

  @$pb.TagNumber(110)
  $pb.PbList<TxInstallment> get installments => $_getList(9);
}

class TxInstallment extends $pb.GeneratedMessage {
  factory TxInstallment({
    $fixnum.Int64? instId,
    $fixnum.Int64? dueTsMs,
    $fixnum.Int64? amount,
    $core.String? note,
    $core.bool? isPaid,
    $core.bool? isOverdue,
    $core.Iterable<TxDebtPayment>? debtPayments,
  }) {
    final result = TxInstallment._();
    if (instId != null) result.instId = instId;
    if (dueTsMs != null) result.dueTsMs = dueTsMs;
    if (amount != null) result.amount = amount;
    if (note != null) result.note = note;
    if (isPaid != null) result.isPaid = isPaid;
    if (isOverdue != null) result.isOverdue = isOverdue;
    if (debtPayments != null) result.debtPayments.addAll(debtPayments);
    return result;
  }

  TxInstallment._();

  factory TxInstallment.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TxInstallment()..mergeFromBuffer(data, registry);
  factory TxInstallment.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TxInstallment()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TxInstallment',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: TxInstallment.$_createMessage)
    ..aInt64(4, _omitFieldNames ? '' : 'instId')
    ..aInt64(10, _omitFieldNames ? '' : 'dueTsMs')
    ..aInt64(11, _omitFieldNames ? '' : 'amount')
    ..aOS(12, _omitFieldNames ? '' : 'note')
    ..aOB(21, _omitFieldNames ? '' : 'isPaid')
    ..aOB(22, _omitFieldNames ? '' : 'isOverdue')
    ..pPM<TxDebtPayment>(30, _omitFieldNames ? '' : 'debtPayments',
        subBuilder: TxDebtPayment.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TxInstallment clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TxInstallment copyWith(void Function(TxInstallment) updates) =>
      super.copyWith((message) => updates(message as TxInstallment))
          as TxInstallment;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use TxInstallment() / TxInstallment.new instead')
  static TxInstallment create() => TxInstallment._();
  static $pb.GeneratedMessage $_createMessage() => TxInstallment._();
  @$core.override
  TxInstallment createEmptyInstance() => TxInstallment._();
  @$core.pragma('dart2js:noInline')
  static TxInstallment getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TxInstallment>(
          TxInstallment.$_createMessage);
  static TxInstallment? _defaultInstance;

  @$pb.TagNumber(4)
  $fixnum.Int64 get instId => $_getI64(0);
  @$pb.TagNumber(4)
  set instId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(4)
  $core.bool hasInstId() => $_has(0);
  @$pb.TagNumber(4)
  void clearInstId() => $_clearField(4);

  @$pb.TagNumber(10)
  $fixnum.Int64 get dueTsMs => $_getI64(1);
  @$pb.TagNumber(10)
  set dueTsMs($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(10)
  $core.bool hasDueTsMs() => $_has(1);
  @$pb.TagNumber(10)
  void clearDueTsMs() => $_clearField(10);

  @$pb.TagNumber(11)
  $fixnum.Int64 get amount => $_getI64(2);
  @$pb.TagNumber(11)
  set amount($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(11)
  $core.bool hasAmount() => $_has(2);
  @$pb.TagNumber(11)
  void clearAmount() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.String get note => $_getSZ(3);
  @$pb.TagNumber(12)
  set note($core.String value) => $_setString(3, value);
  @$pb.TagNumber(12)
  $core.bool hasNote() => $_has(3);
  @$pb.TagNumber(12)
  void clearNote() => $_clearField(12);

  @$pb.TagNumber(21)
  $core.bool get isPaid => $_getBF(4);
  @$pb.TagNumber(21)
  set isPaid($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(21)
  $core.bool hasIsPaid() => $_has(4);
  @$pb.TagNumber(21)
  void clearIsPaid() => $_clearField(21);

  @$pb.TagNumber(22)
  $core.bool get isOverdue => $_getBF(5);
  @$pb.TagNumber(22)
  set isOverdue($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(22)
  $core.bool hasIsOverdue() => $_has(5);
  @$pb.TagNumber(22)
  void clearIsOverdue() => $_clearField(22);

  @$pb.TagNumber(30)
  $pb.PbList<TxDebtPayment> get debtPayments => $_getList(6);
}

class TxDebtPayment extends $pb.GeneratedMessage {
  factory TxDebtPayment({
    $fixnum.Int64? payId,
    $fixnum.Int64? tsMs,
    TxDebtPaymentMethod? method,
    $fixnum.Int64? amount,
    $core.String? note,
    $fixnum.Int64? overdueInterest,
    $core.String? paymentJson,
  }) {
    final result = TxDebtPayment._();
    if (payId != null) result.payId = payId;
    if (tsMs != null) result.tsMs = tsMs;
    if (method != null) result.method = method;
    if (amount != null) result.amount = amount;
    if (note != null) result.note = note;
    if (overdueInterest != null) result.overdueInterest = overdueInterest;
    if (paymentJson != null) result.paymentJson = paymentJson;
    return result;
  }

  TxDebtPayment._();

  factory TxDebtPayment.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TxDebtPayment()..mergeFromBuffer(data, registry);
  factory TxDebtPayment.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TxDebtPayment()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TxDebtPayment',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: TxDebtPayment.$_createMessage)
    ..aInt64(5, _omitFieldNames ? '' : 'payId')
    ..aInt64(10, _omitFieldNames ? '' : 'tsMs')
    ..aE<TxDebtPaymentMethod>(11, _omitFieldNames ? '' : 'method',
        enumValues: TxDebtPaymentMethod.values)
    ..aInt64(12, _omitFieldNames ? '' : 'amount')
    ..aOS(13, _omitFieldNames ? '' : 'note')
    ..aInt64(14, _omitFieldNames ? '' : 'overdueInterest')
    ..aOS(100, _omitFieldNames ? '' : 'paymentJson')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TxDebtPayment clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TxDebtPayment copyWith(void Function(TxDebtPayment) updates) =>
      super.copyWith((message) => updates(message as TxDebtPayment))
          as TxDebtPayment;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use TxDebtPayment() / TxDebtPayment.new instead')
  static TxDebtPayment create() => TxDebtPayment._();
  static $pb.GeneratedMessage $_createMessage() => TxDebtPayment._();
  @$core.override
  TxDebtPayment createEmptyInstance() => TxDebtPayment._();
  @$core.pragma('dart2js:noInline')
  static TxDebtPayment getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TxDebtPayment>(
          TxDebtPayment.$_createMessage);
  static TxDebtPayment? _defaultInstance;

  @$pb.TagNumber(5)
  $fixnum.Int64 get payId => $_getI64(0);
  @$pb.TagNumber(5)
  set payId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(5)
  $core.bool hasPayId() => $_has(0);
  @$pb.TagNumber(5)
  void clearPayId() => $_clearField(5);

  @$pb.TagNumber(10)
  $fixnum.Int64 get tsMs => $_getI64(1);
  @$pb.TagNumber(10)
  set tsMs($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(10)
  $core.bool hasTsMs() => $_has(1);
  @$pb.TagNumber(10)
  void clearTsMs() => $_clearField(10);

  @$pb.TagNumber(11)
  TxDebtPaymentMethod get method => $_getN(2);
  @$pb.TagNumber(11)
  set method(TxDebtPaymentMethod value) => $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasMethod() => $_has(2);
  @$pb.TagNumber(11)
  void clearMethod() => $_clearField(11);

  @$pb.TagNumber(12)
  $fixnum.Int64 get amount => $_getI64(3);
  @$pb.TagNumber(12)
  set amount($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(12)
  $core.bool hasAmount() => $_has(3);
  @$pb.TagNumber(12)
  void clearAmount() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.String get note => $_getSZ(4);
  @$pb.TagNumber(13)
  set note($core.String value) => $_setString(4, value);
  @$pb.TagNumber(13)
  $core.bool hasNote() => $_has(4);
  @$pb.TagNumber(13)
  void clearNote() => $_clearField(13);

  @$pb.TagNumber(14)
  $fixnum.Int64 get overdueInterest => $_getI64(5);
  @$pb.TagNumber(14)
  set overdueInterest($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(14)
  $core.bool hasOverdueInterest() => $_has(5);
  @$pb.TagNumber(14)
  void clearOverdueInterest() => $_clearField(14);

  @$pb.TagNumber(100)
  $core.String get paymentJson => $_getSZ(6);
  @$pb.TagNumber(100)
  set paymentJson($core.String value) => $_setString(6, value);
  @$pb.TagNumber(100)
  $core.bool hasPaymentJson() => $_has(6);
  @$pb.TagNumber(100)
  void clearPaymentJson() => $_clearField(100);
}

class TxAcc extends $pb.GeneratedMessage {
  factory TxAcc({
    $fixnum.Int64? accId,
    $core.String? accCode,
    $fixnum.Int64? tsMs,
    TxAccSide? side,
    $fixnum.Int64? amount,
    $core.String? note,
    $core.bool? isTxGenerated,
  }) {
    final result = TxAcc._();
    if (accId != null) result.accId = accId;
    if (accCode != null) result.accCode = accCode;
    if (tsMs != null) result.tsMs = tsMs;
    if (side != null) result.side = side;
    if (amount != null) result.amount = amount;
    if (note != null) result.note = note;
    if (isTxGenerated != null) result.isTxGenerated = isTxGenerated;
    return result;
  }

  TxAcc._();

  factory TxAcc.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TxAcc()..mergeFromBuffer(data, registry);
  factory TxAcc.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TxAcc()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TxAcc',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: TxAcc.$_createMessage)
    ..aInt64(3, _omitFieldNames ? '' : 'accId')
    ..aOS(10, _omitFieldNames ? '' : 'accCode')
    ..aInt64(11, _omitFieldNames ? '' : 'tsMs')
    ..aE<TxAccSide>(12, _omitFieldNames ? '' : 'side',
        enumValues: TxAccSide.values)
    ..aInt64(13, _omitFieldNames ? '' : 'amount')
    ..aOS(14, _omitFieldNames ? '' : 'note')
    ..aOB(20, _omitFieldNames ? '' : 'isTxGenerated')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TxAcc clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TxAcc copyWith(void Function(TxAcc) updates) =>
      super.copyWith((message) => updates(message as TxAcc)) as TxAcc;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use TxAcc() / TxAcc.new instead')
  static TxAcc create() => TxAcc._();
  static $pb.GeneratedMessage $_createMessage() => TxAcc._();
  @$core.override
  TxAcc createEmptyInstance() => TxAcc._();
  @$core.pragma('dart2js:noInline')
  static TxAcc getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TxAcc>(TxAcc.$_createMessage);
  static TxAcc? _defaultInstance;

  @$pb.TagNumber(3)
  $fixnum.Int64 get accId => $_getI64(0);
  @$pb.TagNumber(3)
  set accId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(3)
  $core.bool hasAccId() => $_has(0);
  @$pb.TagNumber(3)
  void clearAccId() => $_clearField(3);

  @$pb.TagNumber(10)
  $core.String get accCode => $_getSZ(1);
  @$pb.TagNumber(10)
  set accCode($core.String value) => $_setString(1, value);
  @$pb.TagNumber(10)
  $core.bool hasAccCode() => $_has(1);
  @$pb.TagNumber(10)
  void clearAccCode() => $_clearField(10);

  @$pb.TagNumber(11)
  $fixnum.Int64 get tsMs => $_getI64(2);
  @$pb.TagNumber(11)
  set tsMs($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(11)
  $core.bool hasTsMs() => $_has(2);
  @$pb.TagNumber(11)
  void clearTsMs() => $_clearField(11);

  @$pb.TagNumber(12)
  TxAccSide get side => $_getN(3);
  @$pb.TagNumber(12)
  set side(TxAccSide value) => $_setField(12, value);
  @$pb.TagNumber(12)
  $core.bool hasSide() => $_has(3);
  @$pb.TagNumber(12)
  void clearSide() => $_clearField(12);

  @$pb.TagNumber(13)
  $fixnum.Int64 get amount => $_getI64(4);
  @$pb.TagNumber(13)
  set amount($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(13)
  $core.bool hasAmount() => $_has(4);
  @$pb.TagNumber(13)
  void clearAmount() => $_clearField(13);

  @$pb.TagNumber(14)
  $core.String get note => $_getSZ(5);
  @$pb.TagNumber(14)
  set note($core.String value) => $_setString(5, value);
  @$pb.TagNumber(14)
  $core.bool hasNote() => $_has(5);
  @$pb.TagNumber(14)
  void clearNote() => $_clearField(14);

  @$pb.TagNumber(20)
  $core.bool get isTxGenerated => $_getBF(6);
  @$pb.TagNumber(20)
  set isTxGenerated($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(20)
  $core.bool hasIsTxGenerated() => $_has(6);
  @$pb.TagNumber(20)
  void clearIsTxGenerated() => $_clearField(20);
}

class TxStock extends $pb.GeneratedMessage {
  factory TxStock({
    $fixnum.Int64? stockId,
    $fixnum.Int64? productId,
    $fixnum.Int64? tsMs,
    $fixnum.Int64? objFromId,
    $fixnum.Int64? objToId,
    $core.int? qty,
    $core.int? qtySigned,
    $core.String? direction,
    $core.String? note,
  }) {
    final result = TxStock._();
    if (stockId != null) result.stockId = stockId;
    if (productId != null) result.productId = productId;
    if (tsMs != null) result.tsMs = tsMs;
    if (objFromId != null) result.objFromId = objFromId;
    if (objToId != null) result.objToId = objToId;
    if (qty != null) result.qty = qty;
    if (qtySigned != null) result.qtySigned = qtySigned;
    if (direction != null) result.direction = direction;
    if (note != null) result.note = note;
    return result;
  }

  TxStock._();

  factory TxStock.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TxStock()..mergeFromBuffer(data, registry);
  factory TxStock.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TxStock()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TxStock',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: TxStock.$_createMessage)
    ..aInt64(3, _omitFieldNames ? '' : 'stockId')
    ..aInt64(10, _omitFieldNames ? '' : 'productId')
    ..aInt64(11, _omitFieldNames ? '' : 'tsMs')
    ..aInt64(20, _omitFieldNames ? '' : 'objFromId')
    ..aInt64(21, _omitFieldNames ? '' : 'objToId')
    ..aI(30, _omitFieldNames ? '' : 'qty')
    ..aI(31, _omitFieldNames ? '' : 'qtySigned')
    ..aOS(32, _omitFieldNames ? '' : 'direction')
    ..aOS(33, _omitFieldNames ? '' : 'note')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TxStock clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TxStock copyWith(void Function(TxStock) updates) =>
      super.copyWith((message) => updates(message as TxStock)) as TxStock;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use TxStock() / TxStock.new instead')
  static TxStock create() => TxStock._();
  static $pb.GeneratedMessage $_createMessage() => TxStock._();
  @$core.override
  TxStock createEmptyInstance() => TxStock._();
  @$core.pragma('dart2js:noInline')
  static TxStock getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TxStock>(TxStock.$_createMessage);
  static TxStock? _defaultInstance;

  @$pb.TagNumber(3)
  $fixnum.Int64 get stockId => $_getI64(0);
  @$pb.TagNumber(3)
  set stockId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(3)
  $core.bool hasStockId() => $_has(0);
  @$pb.TagNumber(3)
  void clearStockId() => $_clearField(3);

  @$pb.TagNumber(10)
  $fixnum.Int64 get productId => $_getI64(1);
  @$pb.TagNumber(10)
  set productId($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(10)
  $core.bool hasProductId() => $_has(1);
  @$pb.TagNumber(10)
  void clearProductId() => $_clearField(10);

  @$pb.TagNumber(11)
  $fixnum.Int64 get tsMs => $_getI64(2);
  @$pb.TagNumber(11)
  set tsMs($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(11)
  $core.bool hasTsMs() => $_has(2);
  @$pb.TagNumber(11)
  void clearTsMs() => $_clearField(11);

  @$pb.TagNumber(20)
  $fixnum.Int64 get objFromId => $_getI64(3);
  @$pb.TagNumber(20)
  set objFromId($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(20)
  $core.bool hasObjFromId() => $_has(3);
  @$pb.TagNumber(20)
  void clearObjFromId() => $_clearField(20);

  @$pb.TagNumber(21)
  $fixnum.Int64 get objToId => $_getI64(4);
  @$pb.TagNumber(21)
  set objToId($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(21)
  $core.bool hasObjToId() => $_has(4);
  @$pb.TagNumber(21)
  void clearObjToId() => $_clearField(21);

  @$pb.TagNumber(30)
  $core.int get qty => $_getIZ(5);
  @$pb.TagNumber(30)
  set qty($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(30)
  $core.bool hasQty() => $_has(5);
  @$pb.TagNumber(30)
  void clearQty() => $_clearField(30);

  @$pb.TagNumber(31)
  $core.int get qtySigned => $_getIZ(6);
  @$pb.TagNumber(31)
  set qtySigned($core.int value) => $_setSignedInt32(6, value);
  @$pb.TagNumber(31)
  $core.bool hasQtySigned() => $_has(6);
  @$pb.TagNumber(31)
  void clearQtySigned() => $_clearField(31);

  @$pb.TagNumber(32)
  $core.String get direction => $_getSZ(7);
  @$pb.TagNumber(32)
  set direction($core.String value) => $_setString(7, value);
  @$pb.TagNumber(32)
  $core.bool hasDirection() => $_has(7);
  @$pb.TagNumber(32)
  void clearDirection() => $_clearField(32);

  @$pb.TagNumber(33)
  $core.String get note => $_getSZ(8);
  @$pb.TagNumber(33)
  set note($core.String value) => $_setString(8, value);
  @$pb.TagNumber(33)
  $core.bool hasNote() => $_has(8);
  @$pb.TagNumber(33)
  void clearNote() => $_clearField(33);
}

class ReqTxGet extends $pb.GeneratedMessage {
  factory ReqTxGet({
    $fixnum.Int64? siteIid,
    $fixnum.Int64? txId,
  }) {
    final result = ReqTxGet._();
    if (siteIid != null) result.siteIid = siteIid;
    if (txId != null) result.txId = txId;
    return result;
  }

  ReqTxGet._();

  factory ReqTxGet.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqTxGet()..mergeFromBuffer(data, registry);
  factory ReqTxGet.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqTxGet()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqTxGet',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqTxGet.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'siteIid')
    ..aInt64(2, _omitFieldNames ? '' : 'txId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqTxGet clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqTxGet copyWith(void Function(ReqTxGet) updates) =>
      super.copyWith((message) => updates(message as ReqTxGet)) as ReqTxGet;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqTxGet() / ReqTxGet.new instead')
  static ReqTxGet create() => ReqTxGet._();
  static $pb.GeneratedMessage $_createMessage() => ReqTxGet._();
  @$core.override
  ReqTxGet createEmptyInstance() => ReqTxGet._();
  @$core.pragma('dart2js:noInline')
  static ReqTxGet getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqTxGet>(ReqTxGet.$_createMessage);
  static ReqTxGet? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get siteIid => $_getI64(0);
  @$pb.TagNumber(1)
  set siteIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSiteIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearSiteIid() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get txId => $_getI64(1);
  @$pb.TagNumber(2)
  set txId($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTxId() => $_has(1);
  @$pb.TagNumber(2)
  void clearTxId() => $_clearField(2);
}

class ResTxGet extends $pb.GeneratedMessage {
  factory ResTxGet({
    Tx? tx,
  }) {
    final result = ResTxGet._();
    if (tx != null) result.tx = tx;
    return result;
  }

  ResTxGet._();

  factory ResTxGet.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResTxGet()..mergeFromBuffer(data, registry);
  factory ResTxGet.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResTxGet()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResTxGet',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResTxGet.$_createMessage)
    ..aOM<Tx>(1, _omitFieldNames ? '' : 'tx', subBuilder: Tx.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResTxGet clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResTxGet copyWith(void Function(ResTxGet) updates) =>
      super.copyWith((message) => updates(message as ResTxGet)) as ResTxGet;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResTxGet() / ResTxGet.new instead')
  static ResTxGet create() => ResTxGet._();
  static $pb.GeneratedMessage $_createMessage() => ResTxGet._();
  @$core.override
  ResTxGet createEmptyInstance() => ResTxGet._();
  @$core.pragma('dart2js:noInline')
  static ResTxGet getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResTxGet>(ResTxGet.$_createMessage);
  static ResTxGet? _defaultInstance;

  @$pb.TagNumber(1)
  Tx get tx => $_getN(0);
  @$pb.TagNumber(1)
  set tx(Tx value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasTx() => $_has(0);
  @$pb.TagNumber(1)
  void clearTx() => $_clearField(1);
  @$pb.TagNumber(1)
  Tx ensureTx() => $_ensure(0);
}

class ReqTxList extends $pb.GeneratedMessage {
  factory ReqTxList({
    $fixnum.Int64? siteIid,
    $core.String? q,
    $fixnum.Int64? afterTxId,
    $core.int? limit,
    $core.bool? includeArchived,
    TxType? type,
    TxState? state,
    $fixnum.Int64? subjectContactId,
    $fixnum.Int64? timeFromMs,
    $fixnum.Int64? timeToMs,
    $core.bool? openOnly,
  }) {
    final result = ReqTxList._();
    if (siteIid != null) result.siteIid = siteIid;
    if (q != null) result.q = q;
    if (afterTxId != null) result.afterTxId = afterTxId;
    if (limit != null) result.limit = limit;
    if (includeArchived != null) result.includeArchived = includeArchived;
    if (type != null) result.type = type;
    if (state != null) result.state = state;
    if (subjectContactId != null) result.subjectContactId = subjectContactId;
    if (timeFromMs != null) result.timeFromMs = timeFromMs;
    if (timeToMs != null) result.timeToMs = timeToMs;
    if (openOnly != null) result.openOnly = openOnly;
    return result;
  }

  ReqTxList._();

  factory ReqTxList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqTxList()..mergeFromBuffer(data, registry);
  factory ReqTxList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqTxList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqTxList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqTxList.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'siteIid')
    ..aOS(2, _omitFieldNames ? '' : 'q')
    ..aInt64(3, _omitFieldNames ? '' : 'afterTxId')
    ..aI(4, _omitFieldNames ? '' : 'limit')
    ..aOB(5, _omitFieldNames ? '' : 'includeArchived')
    ..aE<TxType>(6, _omitFieldNames ? '' : 'type', enumValues: TxType.values)
    ..aE<TxState>(7, _omitFieldNames ? '' : 'state', enumValues: TxState.values)
    ..aInt64(10, _omitFieldNames ? '' : 'subjectContactId')
    ..aInt64(11, _omitFieldNames ? '' : 'timeFromMs')
    ..aInt64(12, _omitFieldNames ? '' : 'timeToMs')
    ..aOB(15, _omitFieldNames ? '' : 'openOnly')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqTxList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqTxList copyWith(void Function(ReqTxList) updates) =>
      super.copyWith((message) => updates(message as ReqTxList)) as ReqTxList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqTxList() / ReqTxList.new instead')
  static ReqTxList create() => ReqTxList._();
  static $pb.GeneratedMessage $_createMessage() => ReqTxList._();
  @$core.override
  ReqTxList createEmptyInstance() => ReqTxList._();
  @$core.pragma('dart2js:noInline')
  static ReqTxList getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqTxList>(ReqTxList.$_createMessage);
  static ReqTxList? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get siteIid => $_getI64(0);
  @$pb.TagNumber(1)
  set siteIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSiteIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearSiteIid() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get q => $_getSZ(1);
  @$pb.TagNumber(2)
  set q($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasQ() => $_has(1);
  @$pb.TagNumber(2)
  void clearQ() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get afterTxId => $_getI64(2);
  @$pb.TagNumber(3)
  set afterTxId($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAfterTxId() => $_has(2);
  @$pb.TagNumber(3)
  void clearAfterTxId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get limit => $_getIZ(3);
  @$pb.TagNumber(4)
  set limit($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasLimit() => $_has(3);
  @$pb.TagNumber(4)
  void clearLimit() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get includeArchived => $_getBF(4);
  @$pb.TagNumber(5)
  set includeArchived($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasIncludeArchived() => $_has(4);
  @$pb.TagNumber(5)
  void clearIncludeArchived() => $_clearField(5);

  @$pb.TagNumber(6)
  TxType get type => $_getN(5);
  @$pb.TagNumber(6)
  set type(TxType value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasType() => $_has(5);
  @$pb.TagNumber(6)
  void clearType() => $_clearField(6);

  @$pb.TagNumber(7)
  TxState get state => $_getN(6);
  @$pb.TagNumber(7)
  set state(TxState value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasState() => $_has(6);
  @$pb.TagNumber(7)
  void clearState() => $_clearField(7);

  @$pb.TagNumber(10)
  $fixnum.Int64 get subjectContactId => $_getI64(7);
  @$pb.TagNumber(10)
  set subjectContactId($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(10)
  $core.bool hasSubjectContactId() => $_has(7);
  @$pb.TagNumber(10)
  void clearSubjectContactId() => $_clearField(10);

  @$pb.TagNumber(11)
  $fixnum.Int64 get timeFromMs => $_getI64(8);
  @$pb.TagNumber(11)
  set timeFromMs($fixnum.Int64 value) => $_setInt64(8, value);
  @$pb.TagNumber(11)
  $core.bool hasTimeFromMs() => $_has(8);
  @$pb.TagNumber(11)
  void clearTimeFromMs() => $_clearField(11);

  @$pb.TagNumber(12)
  $fixnum.Int64 get timeToMs => $_getI64(9);
  @$pb.TagNumber(12)
  set timeToMs($fixnum.Int64 value) => $_setInt64(9, value);
  @$pb.TagNumber(12)
  $core.bool hasTimeToMs() => $_has(9);
  @$pb.TagNumber(12)
  void clearTimeToMs() => $_clearField(12);

  @$pb.TagNumber(15)
  $core.bool get openOnly => $_getBF(10);
  @$pb.TagNumber(15)
  set openOnly($core.bool value) => $_setBool(10, value);
  @$pb.TagNumber(15)
  $core.bool hasOpenOnly() => $_has(10);
  @$pb.TagNumber(15)
  void clearOpenOnly() => $_clearField(15);
}

class ResTxList extends $pb.GeneratedMessage {
  factory ResTxList({
    $core.Iterable<Tx>? txs,
  }) {
    final result = ResTxList._();
    if (txs != null) result.txs.addAll(txs);
    return result;
  }

  ResTxList._();

  factory ResTxList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResTxList()..mergeFromBuffer(data, registry);
  factory ResTxList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResTxList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResTxList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResTxList.$_createMessage)
    ..pPM<Tx>(1, _omitFieldNames ? '' : 'txs', subBuilder: Tx.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResTxList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResTxList copyWith(void Function(ResTxList) updates) =>
      super.copyWith((message) => updates(message as ResTxList)) as ResTxList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResTxList() / ResTxList.new instead')
  static ResTxList create() => ResTxList._();
  static $pb.GeneratedMessage $_createMessage() => ResTxList._();
  @$core.override
  ResTxList createEmptyInstance() => ResTxList._();
  @$core.pragma('dart2js:noInline')
  static ResTxList getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResTxList>(ResTxList.$_createMessage);
  static ResTxList? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Tx> get txs => $_getList(0);
}

class ReqTxPut extends $pb.GeneratedMessage {
  factory ReqTxPut({
    Tx? tx,
  }) {
    final result = ReqTxPut._();
    if (tx != null) result.tx = tx;
    return result;
  }

  ReqTxPut._();

  factory ReqTxPut.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqTxPut()..mergeFromBuffer(data, registry);
  factory ReqTxPut.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqTxPut()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqTxPut',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqTxPut.$_createMessage)
    ..aOM<Tx>(1, _omitFieldNames ? '' : 'tx', subBuilder: Tx.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqTxPut clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqTxPut copyWith(void Function(ReqTxPut) updates) =>
      super.copyWith((message) => updates(message as ReqTxPut)) as ReqTxPut;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqTxPut() / ReqTxPut.new instead')
  static ReqTxPut create() => ReqTxPut._();
  static $pb.GeneratedMessage $_createMessage() => ReqTxPut._();
  @$core.override
  ReqTxPut createEmptyInstance() => ReqTxPut._();
  @$core.pragma('dart2js:noInline')
  static ReqTxPut getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqTxPut>(ReqTxPut.$_createMessage);
  static ReqTxPut? _defaultInstance;

  @$pb.TagNumber(1)
  Tx get tx => $_getN(0);
  @$pb.TagNumber(1)
  set tx(Tx value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasTx() => $_has(0);
  @$pb.TagNumber(1)
  void clearTx() => $_clearField(1);
  @$pb.TagNumber(1)
  Tx ensureTx() => $_ensure(0);
}

class ResTxPut extends $pb.GeneratedMessage {
  factory ResTxPut({
    Tx? tx,
  }) {
    final result = ResTxPut._();
    if (tx != null) result.tx = tx;
    return result;
  }

  ResTxPut._();

  factory ResTxPut.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResTxPut()..mergeFromBuffer(data, registry);
  factory ResTxPut.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResTxPut()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResTxPut',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResTxPut.$_createMessage)
    ..aOM<Tx>(1, _omitFieldNames ? '' : 'tx', subBuilder: Tx.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResTxPut clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResTxPut copyWith(void Function(ResTxPut) updates) =>
      super.copyWith((message) => updates(message as ResTxPut)) as ResTxPut;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResTxPut() / ResTxPut.new instead')
  static ResTxPut create() => ResTxPut._();
  static $pb.GeneratedMessage $_createMessage() => ResTxPut._();
  @$core.override
  ResTxPut createEmptyInstance() => ResTxPut._();
  @$core.pragma('dart2js:noInline')
  static ResTxPut getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResTxPut>(ResTxPut.$_createMessage);
  static ResTxPut? _defaultInstance;

  @$pb.TagNumber(1)
  Tx get tx => $_getN(0);
  @$pb.TagNumber(1)
  set tx(Tx value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasTx() => $_has(0);
  @$pb.TagNumber(1)
  void clearTx() => $_clearField(1);
  @$pb.TagNumber(1)
  Tx ensureTx() => $_ensure(0);
}

class ReqTxPreview extends $pb.GeneratedMessage {
  factory ReqTxPreview({
    Tx? tx,
  }) {
    final result = ReqTxPreview._();
    if (tx != null) result.tx = tx;
    return result;
  }

  ReqTxPreview._();

  factory ReqTxPreview.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqTxPreview()..mergeFromBuffer(data, registry);
  factory ReqTxPreview.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqTxPreview()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqTxPreview',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqTxPreview.$_createMessage)
    ..aOM<Tx>(1, _omitFieldNames ? '' : 'tx', subBuilder: Tx.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqTxPreview clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqTxPreview copyWith(void Function(ReqTxPreview) updates) =>
      super.copyWith((message) => updates(message as ReqTxPreview))
          as ReqTxPreview;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqTxPreview() / ReqTxPreview.new instead')
  static ReqTxPreview create() => ReqTxPreview._();
  static $pb.GeneratedMessage $_createMessage() => ReqTxPreview._();
  @$core.override
  ReqTxPreview createEmptyInstance() => ReqTxPreview._();
  @$core.pragma('dart2js:noInline')
  static ReqTxPreview getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqTxPreview>(
          ReqTxPreview.$_createMessage);
  static ReqTxPreview? _defaultInstance;

  @$pb.TagNumber(1)
  Tx get tx => $_getN(0);
  @$pb.TagNumber(1)
  set tx(Tx value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasTx() => $_has(0);
  @$pb.TagNumber(1)
  void clearTx() => $_clearField(1);
  @$pb.TagNumber(1)
  Tx ensureTx() => $_ensure(0);
}

class ResTxPreview extends $pb.GeneratedMessage {
  factory ResTxPreview({
    Tx? tx,
    $core.Iterable<$core.MapEntry<$core.String, $core.String>>? coaName,
  }) {
    final result = ResTxPreview._();
    if (tx != null) result.tx = tx;
    if (coaName != null) result.coaName.addEntries(coaName);
    return result;
  }

  ResTxPreview._();

  factory ResTxPreview.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResTxPreview()..mergeFromBuffer(data, registry);
  factory ResTxPreview.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResTxPreview()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResTxPreview',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResTxPreview.$_createMessage)
    ..aOM<Tx>(1, _omitFieldNames ? '' : 'tx', subBuilder: Tx.$_createMessage)
    ..m<$core.String, $core.String>(2, _omitFieldNames ? '' : 'coaName',
        entryClassName: 'ResTxPreview.CoaNameEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('c35'))
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResTxPreview clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResTxPreview copyWith(void Function(ResTxPreview) updates) =>
      super.copyWith((message) => updates(message as ResTxPreview))
          as ResTxPreview;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResTxPreview() / ResTxPreview.new instead')
  static ResTxPreview create() => ResTxPreview._();
  static $pb.GeneratedMessage $_createMessage() => ResTxPreview._();
  @$core.override
  ResTxPreview createEmptyInstance() => ResTxPreview._();
  @$core.pragma('dart2js:noInline')
  static ResTxPreview getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResTxPreview>(
          ResTxPreview.$_createMessage);
  static ResTxPreview? _defaultInstance;

  @$pb.TagNumber(1)
  Tx get tx => $_getN(0);
  @$pb.TagNumber(1)
  set tx(Tx value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasTx() => $_has(0);
  @$pb.TagNumber(1)
  void clearTx() => $_clearField(1);
  @$pb.TagNumber(1)
  Tx ensureTx() => $_ensure(0);

  @$pb.TagNumber(2)
  $pb.PbMap<$core.String, $core.String> get coaName => $_getMap(1);
}

class ReqTxDebtPay extends $pb.GeneratedMessage {
  factory ReqTxDebtPay({
    $fixnum.Int64? siteIid,
    $fixnum.Int64? txId,
    TxDebtPayment? payment,
  }) {
    final result = ReqTxDebtPay._();
    if (siteIid != null) result.siteIid = siteIid;
    if (txId != null) result.txId = txId;
    if (payment != null) result.payment = payment;
    return result;
  }

  ReqTxDebtPay._();

  factory ReqTxDebtPay.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqTxDebtPay()..mergeFromBuffer(data, registry);
  factory ReqTxDebtPay.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqTxDebtPay()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqTxDebtPay',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqTxDebtPay.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'siteIid')
    ..aInt64(2, _omitFieldNames ? '' : 'txId')
    ..aOM<TxDebtPayment>(3, _omitFieldNames ? '' : 'payment',
        subBuilder: TxDebtPayment.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqTxDebtPay clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqTxDebtPay copyWith(void Function(ReqTxDebtPay) updates) =>
      super.copyWith((message) => updates(message as ReqTxDebtPay))
          as ReqTxDebtPay;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqTxDebtPay() / ReqTxDebtPay.new instead')
  static ReqTxDebtPay create() => ReqTxDebtPay._();
  static $pb.GeneratedMessage $_createMessage() => ReqTxDebtPay._();
  @$core.override
  ReqTxDebtPay createEmptyInstance() => ReqTxDebtPay._();
  @$core.pragma('dart2js:noInline')
  static ReqTxDebtPay getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqTxDebtPay>(
          ReqTxDebtPay.$_createMessage);
  static ReqTxDebtPay? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get siteIid => $_getI64(0);
  @$pb.TagNumber(1)
  set siteIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSiteIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearSiteIid() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get txId => $_getI64(1);
  @$pb.TagNumber(2)
  set txId($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTxId() => $_has(1);
  @$pb.TagNumber(2)
  void clearTxId() => $_clearField(2);

  @$pb.TagNumber(3)
  TxDebtPayment get payment => $_getN(2);
  @$pb.TagNumber(3)
  set payment(TxDebtPayment value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasPayment() => $_has(2);
  @$pb.TagNumber(3)
  void clearPayment() => $_clearField(3);
  @$pb.TagNumber(3)
  TxDebtPayment ensurePayment() => $_ensure(2);
}

class ResTxDebtPay extends $pb.GeneratedMessage {
  factory ResTxDebtPay({
    Tx? tx,
  }) {
    final result = ResTxDebtPay._();
    if (tx != null) result.tx = tx;
    return result;
  }

  ResTxDebtPay._();

  factory ResTxDebtPay.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResTxDebtPay()..mergeFromBuffer(data, registry);
  factory ResTxDebtPay.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResTxDebtPay()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResTxDebtPay',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResTxDebtPay.$_createMessage)
    ..aOM<Tx>(1, _omitFieldNames ? '' : 'tx', subBuilder: Tx.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResTxDebtPay clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResTxDebtPay copyWith(void Function(ResTxDebtPay) updates) =>
      super.copyWith((message) => updates(message as ResTxDebtPay))
          as ResTxDebtPay;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResTxDebtPay() / ResTxDebtPay.new instead')
  static ResTxDebtPay create() => ResTxDebtPay._();
  static $pb.GeneratedMessage $_createMessage() => ResTxDebtPay._();
  @$core.override
  ResTxDebtPay createEmptyInstance() => ResTxDebtPay._();
  @$core.pragma('dart2js:noInline')
  static ResTxDebtPay getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResTxDebtPay>(
          ResTxDebtPay.$_createMessage);
  static ResTxDebtPay? _defaultInstance;

  @$pb.TagNumber(1)
  Tx get tx => $_getN(0);
  @$pb.TagNumber(1)
  set tx(Tx value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasTx() => $_has(0);
  @$pb.TagNumber(1)
  void clearTx() => $_clearField(1);
  @$pb.TagNumber(1)
  Tx ensureTx() => $_ensure(0);
}

/// Guest checkout (public site — no staff grant)
class ReqSiteGuestOrderPut extends $pb.GeneratedMessage {
  factory ReqSiteGuestOrderPut({
    $fixnum.Int64? siteIid,
    Tx? tx,
  }) {
    final result = ReqSiteGuestOrderPut._();
    if (siteIid != null) result.siteIid = siteIid;
    if (tx != null) result.tx = tx;
    return result;
  }

  ReqSiteGuestOrderPut._();

  factory ReqSiteGuestOrderPut.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSiteGuestOrderPut()..mergeFromBuffer(data, registry);
  factory ReqSiteGuestOrderPut.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSiteGuestOrderPut()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqSiteGuestOrderPut',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqSiteGuestOrderPut.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'siteIid')
    ..aOM<Tx>(2, _omitFieldNames ? '' : 'tx', subBuilder: Tx.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSiteGuestOrderPut clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSiteGuestOrderPut copyWith(void Function(ReqSiteGuestOrderPut) updates) =>
      super.copyWith((message) => updates(message as ReqSiteGuestOrderPut))
          as ReqSiteGuestOrderPut;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ReqSiteGuestOrderPut() / ReqSiteGuestOrderPut.new instead')
  static ReqSiteGuestOrderPut create() => ReqSiteGuestOrderPut._();
  static $pb.GeneratedMessage $_createMessage() => ReqSiteGuestOrderPut._();
  @$core.override
  ReqSiteGuestOrderPut createEmptyInstance() => ReqSiteGuestOrderPut._();
  @$core.pragma('dart2js:noInline')
  static ReqSiteGuestOrderPut getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqSiteGuestOrderPut>(
          ReqSiteGuestOrderPut.$_createMessage);
  static ReqSiteGuestOrderPut? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get siteIid => $_getI64(0);
  @$pb.TagNumber(1)
  set siteIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSiteIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearSiteIid() => $_clearField(1);

  @$pb.TagNumber(2)
  Tx get tx => $_getN(1);
  @$pb.TagNumber(2)
  set tx(Tx value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasTx() => $_has(1);
  @$pb.TagNumber(2)
  void clearTx() => $_clearField(2);
  @$pb.TagNumber(2)
  Tx ensureTx() => $_ensure(1);
}

class ResSiteGuestOrderPut extends $pb.GeneratedMessage {
  factory ResSiteGuestOrderPut({
    Tx? tx,
  }) {
    final result = ResSiteGuestOrderPut._();
    if (tx != null) result.tx = tx;
    return result;
  }

  ResSiteGuestOrderPut._();

  factory ResSiteGuestOrderPut.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSiteGuestOrderPut()..mergeFromBuffer(data, registry);
  factory ResSiteGuestOrderPut.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSiteGuestOrderPut()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResSiteGuestOrderPut',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResSiteGuestOrderPut.$_createMessage)
    ..aOM<Tx>(1, _omitFieldNames ? '' : 'tx', subBuilder: Tx.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSiteGuestOrderPut clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSiteGuestOrderPut copyWith(void Function(ResSiteGuestOrderPut) updates) =>
      super.copyWith((message) => updates(message as ResSiteGuestOrderPut))
          as ResSiteGuestOrderPut;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ResSiteGuestOrderPut() / ResSiteGuestOrderPut.new instead')
  static ResSiteGuestOrderPut create() => ResSiteGuestOrderPut._();
  static $pb.GeneratedMessage $_createMessage() => ResSiteGuestOrderPut._();
  @$core.override
  ResSiteGuestOrderPut createEmptyInstance() => ResSiteGuestOrderPut._();
  @$core.pragma('dart2js:noInline')
  static ResSiteGuestOrderPut getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResSiteGuestOrderPut>(
          ResSiteGuestOrderPut.$_createMessage);
  static ResSiteGuestOrderPut? _defaultInstance;

  @$pb.TagNumber(1)
  Tx get tx => $_getN(0);
  @$pb.TagNumber(1)
  set tx(Tx value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasTx() => $_has(0);
  @$pb.TagNumber(1)
  void clearTx() => $_clearField(1);
  @$pb.TagNumber(1)
  Tx ensureTx() => $_ensure(0);
}

class ReqSiteGuestOrderGet extends $pb.GeneratedMessage {
  factory ReqSiteGuestOrderGet({
    $fixnum.Int64? siteIid,
    $fixnum.Int64? txId,
  }) {
    final result = ReqSiteGuestOrderGet._();
    if (siteIid != null) result.siteIid = siteIid;
    if (txId != null) result.txId = txId;
    return result;
  }

  ReqSiteGuestOrderGet._();

  factory ReqSiteGuestOrderGet.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSiteGuestOrderGet()..mergeFromBuffer(data, registry);
  factory ReqSiteGuestOrderGet.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqSiteGuestOrderGet()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqSiteGuestOrderGet',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqSiteGuestOrderGet.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'siteIid')
    ..aInt64(2, _omitFieldNames ? '' : 'txId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSiteGuestOrderGet clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqSiteGuestOrderGet copyWith(void Function(ReqSiteGuestOrderGet) updates) =>
      super.copyWith((message) => updates(message as ReqSiteGuestOrderGet))
          as ReqSiteGuestOrderGet;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ReqSiteGuestOrderGet() / ReqSiteGuestOrderGet.new instead')
  static ReqSiteGuestOrderGet create() => ReqSiteGuestOrderGet._();
  static $pb.GeneratedMessage $_createMessage() => ReqSiteGuestOrderGet._();
  @$core.override
  ReqSiteGuestOrderGet createEmptyInstance() => ReqSiteGuestOrderGet._();
  @$core.pragma('dart2js:noInline')
  static ReqSiteGuestOrderGet getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReqSiteGuestOrderGet>(
          ReqSiteGuestOrderGet.$_createMessage);
  static ReqSiteGuestOrderGet? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get siteIid => $_getI64(0);
  @$pb.TagNumber(1)
  set siteIid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSiteIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearSiteIid() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get txId => $_getI64(1);
  @$pb.TagNumber(2)
  set txId($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTxId() => $_has(1);
  @$pb.TagNumber(2)
  void clearTxId() => $_clearField(2);
}

class ResSiteGuestOrderGet extends $pb.GeneratedMessage {
  factory ResSiteGuestOrderGet({
    Tx? tx,
  }) {
    final result = ResSiteGuestOrderGet._();
    if (tx != null) result.tx = tx;
    return result;
  }

  ResSiteGuestOrderGet._();

  factory ResSiteGuestOrderGet.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSiteGuestOrderGet()..mergeFromBuffer(data, registry);
  factory ResSiteGuestOrderGet.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResSiteGuestOrderGet()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResSiteGuestOrderGet',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResSiteGuestOrderGet.$_createMessage)
    ..aOM<Tx>(1, _omitFieldNames ? '' : 'tx', subBuilder: Tx.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSiteGuestOrderGet clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResSiteGuestOrderGet copyWith(void Function(ResSiteGuestOrderGet) updates) =>
      super.copyWith((message) => updates(message as ResSiteGuestOrderGet))
          as ResSiteGuestOrderGet;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ResSiteGuestOrderGet() / ResSiteGuestOrderGet.new instead')
  static ResSiteGuestOrderGet create() => ResSiteGuestOrderGet._();
  static $pb.GeneratedMessage $_createMessage() => ResSiteGuestOrderGet._();
  @$core.override
  ResSiteGuestOrderGet createEmptyInstance() => ResSiteGuestOrderGet._();
  @$core.pragma('dart2js:noInline')
  static ResSiteGuestOrderGet getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResSiteGuestOrderGet>(
          ResSiteGuestOrderGet.$_createMessage);
  static ResSiteGuestOrderGet? _defaultInstance;

  @$pb.TagNumber(1)
  Tx get tx => $_getN(0);
  @$pb.TagNumber(1)
  set tx(Tx value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasTx() => $_has(0);
  @$pb.TagNumber(1)
  void clearTx() => $_clearField(1);
  @$pb.TagNumber(1)
  Tx ensureTx() => $_ensure(0);
}

class ExpenseItemInput extends $pb.GeneratedMessage {
  factory ExpenseItemInput({
    $core.String? name,
    $core.String? nameId,
    $core.double? qty,
    $fixnum.Int64? priceMinor,
    $fixnum.Int64? totalMinor,
    $fixnum.Int64? objId,
  }) {
    final result = ExpenseItemInput._();
    if (name != null) result.name = name;
    if (nameId != null) result.nameId = nameId;
    if (qty != null) result.qty = qty;
    if (priceMinor != null) result.priceMinor = priceMinor;
    if (totalMinor != null) result.totalMinor = totalMinor;
    if (objId != null) result.objId = objId;
    return result;
  }

  ExpenseItemInput._();

  factory ExpenseItemInput.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ExpenseItemInput()..mergeFromBuffer(data, registry);
  factory ExpenseItemInput.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ExpenseItemInput()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ExpenseItemInput',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ExpenseItemInput.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'nameId')
    ..aD(3, _omitFieldNames ? '' : 'qty', fieldType: $pb.PbFieldType.OF)
    ..aInt64(4, _omitFieldNames ? '' : 'priceMinor')
    ..aInt64(5, _omitFieldNames ? '' : 'totalMinor')
    ..aInt64(6, _omitFieldNames ? '' : 'objId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExpenseItemInput clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExpenseItemInput copyWith(void Function(ExpenseItemInput) updates) =>
      super.copyWith((message) => updates(message as ExpenseItemInput))
          as ExpenseItemInput;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ExpenseItemInput() / ExpenseItemInput.new instead')
  static ExpenseItemInput create() => ExpenseItemInput._();
  static $pb.GeneratedMessage $_createMessage() => ExpenseItemInput._();
  @$core.override
  ExpenseItemInput createEmptyInstance() => ExpenseItemInput._();
  @$core.pragma('dart2js:noInline')
  static ExpenseItemInput getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ExpenseItemInput>(
          ExpenseItemInput.$_createMessage);
  static ExpenseItemInput? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get nameId => $_getSZ(1);
  @$pb.TagNumber(2)
  set nameId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNameId() => $_has(1);
  @$pb.TagNumber(2)
  void clearNameId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get qty => $_getN(2);
  @$pb.TagNumber(3)
  set qty($core.double value) => $_setFloat(2, value);
  @$pb.TagNumber(3)
  $core.bool hasQty() => $_has(2);
  @$pb.TagNumber(3)
  void clearQty() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get priceMinor => $_getI64(3);
  @$pb.TagNumber(4)
  set priceMinor($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPriceMinor() => $_has(3);
  @$pb.TagNumber(4)
  void clearPriceMinor() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get totalMinor => $_getI64(4);
  @$pb.TagNumber(5)
  set totalMinor($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasTotalMinor() => $_has(4);
  @$pb.TagNumber(5)
  void clearTotalMinor() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get objId => $_getI64(5);
  @$pb.TagNumber(6)
  set objId($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasObjId() => $_has(5);
  @$pb.TagNumber(6)
  void clearObjId() => $_clearField(6);
}

class ReqExpensePut extends $pb.GeneratedMessage {
  factory ReqExpensePut({
    $fixnum.Int64? txId,
    $core.Iterable<ExpenseItemInput>? items,
    $fixnum.Int64? deletedTsMs,
  }) {
    final result = ReqExpensePut._();
    if (txId != null) result.txId = txId;
    if (items != null) result.items.addAll(items);
    if (deletedTsMs != null) result.deletedTsMs = deletedTsMs;
    return result;
  }

  ReqExpensePut._();

  factory ReqExpensePut.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqExpensePut()..mergeFromBuffer(data, registry);
  factory ReqExpensePut.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReqExpensePut()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReqExpensePut',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ReqExpensePut.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'txId')
    ..pPM<ExpenseItemInput>(2, _omitFieldNames ? '' : 'items',
        subBuilder: ExpenseItemInput.$_createMessage)
    ..aInt64(3, _omitFieldNames ? '' : 'deletedTsMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqExpensePut clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReqExpensePut copyWith(void Function(ReqExpensePut) updates) =>
      super.copyWith((message) => updates(message as ReqExpensePut))
          as ReqExpensePut;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReqExpensePut() / ReqExpensePut.new instead')
  static ReqExpensePut create() => ReqExpensePut._();
  static $pb.GeneratedMessage $_createMessage() => ReqExpensePut._();
  @$core.override
  ReqExpensePut createEmptyInstance() => ReqExpensePut._();
  @$core.pragma('dart2js:noInline')
  static ReqExpensePut getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqExpensePut>(
          ReqExpensePut.$_createMessage);
  static ReqExpensePut? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get txId => $_getI64(0);
  @$pb.TagNumber(1)
  set txId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTxId() => $_has(0);
  @$pb.TagNumber(1)
  void clearTxId() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<ExpenseItemInput> get items => $_getList(1);

  @$pb.TagNumber(3)
  $fixnum.Int64 get deletedTsMs => $_getI64(2);
  @$pb.TagNumber(3)
  set deletedTsMs($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDeletedTsMs() => $_has(2);
  @$pb.TagNumber(3)
  void clearDeletedTsMs() => $_clearField(3);
}

class ResExpensePut extends $pb.GeneratedMessage {
  factory ResExpensePut({
    $fixnum.Int64? txId,
    $core.String? blocksJson,
  }) {
    final result = ResExpensePut._();
    if (txId != null) result.txId = txId;
    if (blocksJson != null) result.blocksJson = blocksJson;
    return result;
  }

  ResExpensePut._();

  factory ResExpensePut.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResExpensePut()..mergeFromBuffer(data, registry);
  factory ResExpensePut.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResExpensePut()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResExpensePut',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'),
      createEmptyInstance: ResExpensePut.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'txId')
    ..aOS(2, _omitFieldNames ? '' : 'blocksJson')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResExpensePut clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResExpensePut copyWith(void Function(ResExpensePut) updates) =>
      super.copyWith((message) => updates(message as ResExpensePut))
          as ResExpensePut;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResExpensePut() / ResExpensePut.new instead')
  static ResExpensePut create() => ResExpensePut._();
  static $pb.GeneratedMessage $_createMessage() => ResExpensePut._();
  @$core.override
  ResExpensePut createEmptyInstance() => ResExpensePut._();
  @$core.pragma('dart2js:noInline')
  static ResExpensePut getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResExpensePut>(
          ResExpensePut.$_createMessage);
  static ResExpensePut? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get txId => $_getI64(0);
  @$pb.TagNumber(1)
  set txId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTxId() => $_has(0);
  @$pb.TagNumber(1)
  void clearTxId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get blocksJson => $_getSZ(1);
  @$pb.TagNumber(2)
  set blocksJson($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasBlocksJson() => $_has(1);
  @$pb.TagNumber(2)
  void clearBlocksJson() => $_clearField(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
