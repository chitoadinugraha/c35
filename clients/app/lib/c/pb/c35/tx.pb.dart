//
//  Generated code. Do not modify.
//  source: c35/tx.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'tx.pbenum.dart';

export 'tx.pbenum.dart';

class TxData extends $pb.GeneratedMessage {
  factory TxData({
    $core.Iterable<$core.String>? proofs,
    TxPrompt? prompt,
    TxDelivery? delivery,
    $core.Iterable<TxPromo>? promos,
  }) {
    final $result = create();
    if (proofs != null) {
      $result.proofs.addAll(proofs);
    }
    if (prompt != null) {
      $result.prompt = prompt;
    }
    if (delivery != null) {
      $result.delivery = delivery;
    }
    if (promos != null) {
      $result.promos.addAll(promos);
    }
    return $result;
  }
  TxData._() : super();
  factory TxData.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TxData.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'TxData', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'proofs')
    ..aOM<TxPrompt>(2, _omitFieldNames ? '' : 'prompt', subBuilder: TxPrompt.create)
    ..aOM<TxDelivery>(3, _omitFieldNames ? '' : 'delivery', subBuilder: TxDelivery.create)
    ..pc<TxPromo>(4, _omitFieldNames ? '' : 'promos', $pb.PbFieldType.PM, subBuilder: TxPromo.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  TxData clone() => TxData()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  TxData copyWith(void Function(TxData) updates) => super.copyWith((message) => updates(message as TxData)) as TxData;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TxData create() => TxData._();
  TxData createEmptyInstance() => create();
  static $pb.PbList<TxData> createRepeated() => $pb.PbList<TxData>();
  @$core.pragma('dart2js:noInline')
  static TxData getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TxData>(create);
  static TxData? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.String> get proofs => $_getList(0);

  @$pb.TagNumber(2)
  TxPrompt get prompt => $_getN(1);
  @$pb.TagNumber(2)
  set prompt(TxPrompt v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasPrompt() => $_has(1);
  @$pb.TagNumber(2)
  void clearPrompt() => clearField(2);
  @$pb.TagNumber(2)
  TxPrompt ensurePrompt() => $_ensure(1);

  @$pb.TagNumber(3)
  TxDelivery get delivery => $_getN(2);
  @$pb.TagNumber(3)
  set delivery(TxDelivery v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasDelivery() => $_has(2);
  @$pb.TagNumber(3)
  void clearDelivery() => clearField(3);
  @$pb.TagNumber(3)
  TxDelivery ensureDelivery() => $_ensure(2);

  @$pb.TagNumber(4)
  $core.List<TxPromo> get promos => $_getList(3);
}

class TxPrompt extends $pb.GeneratedMessage {
  factory TxPrompt({
    $core.Iterable<$core.String>? pics,
    $core.String? desc,
  }) {
    final $result = create();
    if (pics != null) {
      $result.pics.addAll(pics);
    }
    if (desc != null) {
      $result.desc = desc;
    }
    return $result;
  }
  TxPrompt._() : super();
  factory TxPrompt.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TxPrompt.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'TxPrompt', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'pics')
    ..aOS(2, _omitFieldNames ? '' : 'desc')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  TxPrompt clone() => TxPrompt()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  TxPrompt copyWith(void Function(TxPrompt) updates) => super.copyWith((message) => updates(message as TxPrompt)) as TxPrompt;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TxPrompt create() => TxPrompt._();
  TxPrompt createEmptyInstance() => create();
  static $pb.PbList<TxPrompt> createRepeated() => $pb.PbList<TxPrompt>();
  @$core.pragma('dart2js:noInline')
  static TxPrompt getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TxPrompt>(create);
  static TxPrompt? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.String> get pics => $_getList(0);

  @$pb.TagNumber(2)
  $core.String get desc => $_getSZ(1);
  @$pb.TagNumber(2)
  set desc($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasDesc() => $_has(1);
  @$pb.TagNumber(2)
  void clearDesc() => clearField(2);
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
    final $result = create();
    if (siteIid != null) {
      $result.siteIid = siteIid;
    }
    if (txId != null) {
      $result.txId = txId;
    }
    if (type != null) {
      $result.type = type;
    }
    if (state != null) {
      $result.state = state;
    }
    if (inputMode != null) {
      $result.inputMode = inputMode;
    }
    if (inputSource != null) {
      $result.inputSource = inputSource;
    }
    if (isArchived != null) {
      $result.isArchived = isArchived;
    }
    if (desc != null) {
      $result.desc = desc;
    }
    if (timeTsMs != null) {
      $result.timeTsMs = timeTsMs;
    }
    if (createdByIid != null) {
      $result.createdByIid = createdByIid;
    }
    if (cancelReason != null) {
      $result.cancelReason = cancelReason;
    }
    if (subjectContactId != null) {
      $result.subjectContactId = subjectContactId;
    }
    if (subjectName != null) {
      $result.subjectName = subjectName;
    }
    if (subjectPhone != null) {
      $result.subjectPhone = subjectPhone;
    }
    if (subjectAddress != null) {
      $result.subjectAddress = subjectAddress;
    }
    if (cashierName != null) {
      $result.cashierName = cashierName;
    }
    if (storeId != null) {
      $result.storeId = storeId;
    }
    if (storeTgtId != null) {
      $result.storeTgtId = storeTgtId;
    }
    if (deliveryState != null) {
      $result.deliveryState = deliveryState;
    }
    if (objId != null) {
      $result.objId = objId;
    }
    if (promoCode != null) {
      $result.promoCode = promoCode;
    }
    if (isPaid != null) {
      $result.isPaid = isPaid;
    }
    if (isTaskAssigned != null) {
      $result.isTaskAssigned = isTaskAssigned;
    }
    if (orderPayAt != null) {
      $result.orderPayAt = orderPayAt;
    }
    if (txData != null) {
      $result.txData = txData;
    }
    if (itemsCount != null) {
      $result.itemsCount = itemsCount;
    }
    if (itemsQty != null) {
      $result.itemsQty = itemsQty;
    }
    if (itemsTotal != null) {
      $result.itemsTotal = itemsTotal;
    }
    if (debtTotal != null) {
      $result.debtTotal = debtTotal;
    }
    if (debtPaid != null) {
      $result.debtPaid = debtPaid;
    }
    if (debtUnpaid != null) {
      $result.debtUnpaid = debtUnpaid;
    }
    if (totalTaxes != null) {
      $result.totalTaxes = totalTaxes;
    }
    if (totalDiscounts != null) {
      $result.totalDiscounts = totalDiscounts;
    }
    if (totalInterest != null) {
      $result.totalInterest = totalInterest;
    }
    if (totalPaid != null) {
      $result.totalPaid = totalPaid;
    }
    if (totalUnpaid != null) {
      $result.totalUnpaid = totalUnpaid;
    }
    if (stockLineCount != null) {
      $result.stockLineCount = stockLineCount;
    }
    if (stockQtyIn != null) {
      $result.stockQtyIn = stockQtyIn;
    }
    if (stockQtyOut != null) {
      $result.stockQtyOut = stockQtyOut;
    }
    if (accLineCount != null) {
      $result.accLineCount = accLineCount;
    }
    if (accSum != null) {
      $result.accSum = accSum;
    }
    if (accBalanced != null) {
      $result.accBalanced = accBalanced;
    }
    if (hasManualLines != null) {
      $result.hasManualLines = hasManualLines;
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
    if (total != null) {
      $result.total = total;
    }
    if (items != null) {
      $result.items.addAll(items);
    }
    if (payments != null) {
      $result.payments.addAll(payments);
    }
    if (accs != null) {
      $result.accs.addAll(accs);
    }
    if (stocks != null) {
      $result.stocks.addAll(stocks);
    }
    if (taxes != null) {
      $result.taxes.addAll(taxes);
    }
    if (discounts != null) {
      $result.discounts.addAll(discounts);
    }
    return $result;
  }
  Tx._() : super();
  factory Tx.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Tx.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Tx', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'siteIid')
    ..aInt64(2, _omitFieldNames ? '' : 'txId')
    ..e<TxType>(3, _omitFieldNames ? '' : 'type', $pb.PbFieldType.OE, defaultOrMaker: TxType.TX_TYPE_UNSPECIFIED, valueOf: TxType.valueOf, enumValues: TxType.values)
    ..e<TxState>(4, _omitFieldNames ? '' : 'state', $pb.PbFieldType.OE, defaultOrMaker: TxState.TX_STATE_OK, valueOf: TxState.valueOf, enumValues: TxState.values)
    ..e<TxInputMode>(5, _omitFieldNames ? '' : 'inputMode', $pb.PbFieldType.OE, defaultOrMaker: TxInputMode.TX_INPUT_MODE_NORMAL, valueOf: TxInputMode.valueOf, enumValues: TxInputMode.values)
    ..e<TxInputSource>(6, _omitFieldNames ? '' : 'inputSource', $pb.PbFieldType.OE, defaultOrMaker: TxInputSource.TX_INPUT_SOURCE_UNSPECIFIED, valueOf: TxInputSource.valueOf, enumValues: TxInputSource.values)
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
    ..e<TxOrderPayAt>(57, _omitFieldNames ? '' : 'orderPayAt', $pb.PbFieldType.OE, defaultOrMaker: TxOrderPayAt.TX_ORDER_PAY_AT_UNSPECIFIED, valueOf: TxOrderPayAt.valueOf, enumValues: TxOrderPayAt.values)
    ..aOM<TxData>(100, _omitFieldNames ? '' : 'txData', subBuilder: TxData.create)
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
    ..a<$core.int>(151, _omitFieldNames ? '' : 'stockLineCount', $pb.PbFieldType.O3)
    ..a<$core.int>(152, _omitFieldNames ? '' : 'stockQtyIn', $pb.PbFieldType.O3)
    ..a<$core.int>(153, _omitFieldNames ? '' : 'stockQtyOut', $pb.PbFieldType.O3)
    ..a<$core.int>(161, _omitFieldNames ? '' : 'accLineCount', $pb.PbFieldType.O3)
    ..aInt64(162, _omitFieldNames ? '' : 'accSum')
    ..aOB(163, _omitFieldNames ? '' : 'accBalanced')
    ..aOB(164, _omitFieldNames ? '' : 'hasManualLines')
    ..aInt64(180, _omitFieldNames ? '' : 'createdTsMs')
    ..aInt64(181, _omitFieldNames ? '' : 'updatedTsMs')
    ..aInt64(182, _omitFieldNames ? '' : 'deletedTsMs')
    ..aInt64(200, _omitFieldNames ? '' : 'total')
    ..pc<TxItem>(201, _omitFieldNames ? '' : 'items', $pb.PbFieldType.PM, subBuilder: TxItem.create)
    ..pc<TxPayment>(202, _omitFieldNames ? '' : 'payments', $pb.PbFieldType.PM, subBuilder: TxPayment.create)
    ..pc<TxAcc>(203, _omitFieldNames ? '' : 'accs', $pb.PbFieldType.PM, subBuilder: TxAcc.create)
    ..pc<TxStock>(204, _omitFieldNames ? '' : 'stocks', $pb.PbFieldType.PM, subBuilder: TxStock.create)
    ..pc<TxTax>(205, _omitFieldNames ? '' : 'taxes', $pb.PbFieldType.PM, subBuilder: TxTax.create)
    ..pc<TxDiscount>(206, _omitFieldNames ? '' : 'discounts', $pb.PbFieldType.PM, subBuilder: TxDiscount.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Tx clone() => Tx()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Tx copyWith(void Function(Tx) updates) => super.copyWith((message) => updates(message as Tx)) as Tx;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Tx create() => Tx._();
  Tx createEmptyInstance() => create();
  static $pb.PbList<Tx> createRepeated() => $pb.PbList<Tx>();
  @$core.pragma('dart2js:noInline')
  static Tx getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Tx>(create);
  static Tx? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get siteIid => $_getI64(0);
  @$pb.TagNumber(1)
  set siteIid($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasSiteIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearSiteIid() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get txId => $_getI64(1);
  @$pb.TagNumber(2)
  set txId($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasTxId() => $_has(1);
  @$pb.TagNumber(2)
  void clearTxId() => clearField(2);

  @$pb.TagNumber(3)
  TxType get type => $_getN(2);
  @$pb.TagNumber(3)
  set type(TxType v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasType() => $_has(2);
  @$pb.TagNumber(3)
  void clearType() => clearField(3);

  @$pb.TagNumber(4)
  TxState get state => $_getN(3);
  @$pb.TagNumber(4)
  set state(TxState v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasState() => $_has(3);
  @$pb.TagNumber(4)
  void clearState() => clearField(4);

  @$pb.TagNumber(5)
  TxInputMode get inputMode => $_getN(4);
  @$pb.TagNumber(5)
  set inputMode(TxInputMode v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasInputMode() => $_has(4);
  @$pb.TagNumber(5)
  void clearInputMode() => clearField(5);

  @$pb.TagNumber(6)
  TxInputSource get inputSource => $_getN(5);
  @$pb.TagNumber(6)
  set inputSource(TxInputSource v) { setField(6, v); }
  @$pb.TagNumber(6)
  $core.bool hasInputSource() => $_has(5);
  @$pb.TagNumber(6)
  void clearInputSource() => clearField(6);

  @$pb.TagNumber(10)
  $core.bool get isArchived => $_getBF(6);
  @$pb.TagNumber(10)
  set isArchived($core.bool v) { $_setBool(6, v); }
  @$pb.TagNumber(10)
  $core.bool hasIsArchived() => $_has(6);
  @$pb.TagNumber(10)
  void clearIsArchived() => clearField(10);

  @$pb.TagNumber(11)
  $core.String get desc => $_getSZ(7);
  @$pb.TagNumber(11)
  set desc($core.String v) { $_setString(7, v); }
  @$pb.TagNumber(11)
  $core.bool hasDesc() => $_has(7);
  @$pb.TagNumber(11)
  void clearDesc() => clearField(11);

  @$pb.TagNumber(12)
  $fixnum.Int64 get timeTsMs => $_getI64(8);
  @$pb.TagNumber(12)
  set timeTsMs($fixnum.Int64 v) { $_setInt64(8, v); }
  @$pb.TagNumber(12)
  $core.bool hasTimeTsMs() => $_has(8);
  @$pb.TagNumber(12)
  void clearTimeTsMs() => clearField(12);

  @$pb.TagNumber(13)
  $fixnum.Int64 get createdByIid => $_getI64(9);
  @$pb.TagNumber(13)
  set createdByIid($fixnum.Int64 v) { $_setInt64(9, v); }
  @$pb.TagNumber(13)
  $core.bool hasCreatedByIid() => $_has(9);
  @$pb.TagNumber(13)
  void clearCreatedByIid() => clearField(13);

  @$pb.TagNumber(14)
  $core.String get cancelReason => $_getSZ(10);
  @$pb.TagNumber(14)
  set cancelReason($core.String v) { $_setString(10, v); }
  @$pb.TagNumber(14)
  $core.bool hasCancelReason() => $_has(10);
  @$pb.TagNumber(14)
  void clearCancelReason() => clearField(14);

  @$pb.TagNumber(21)
  $fixnum.Int64 get subjectContactId => $_getI64(11);
  @$pb.TagNumber(21)
  set subjectContactId($fixnum.Int64 v) { $_setInt64(11, v); }
  @$pb.TagNumber(21)
  $core.bool hasSubjectContactId() => $_has(11);
  @$pb.TagNumber(21)
  void clearSubjectContactId() => clearField(21);

  @$pb.TagNumber(22)
  $core.String get subjectName => $_getSZ(12);
  @$pb.TagNumber(22)
  set subjectName($core.String v) { $_setString(12, v); }
  @$pb.TagNumber(22)
  $core.bool hasSubjectName() => $_has(12);
  @$pb.TagNumber(22)
  void clearSubjectName() => clearField(22);

  @$pb.TagNumber(23)
  $core.String get subjectPhone => $_getSZ(13);
  @$pb.TagNumber(23)
  set subjectPhone($core.String v) { $_setString(13, v); }
  @$pb.TagNumber(23)
  $core.bool hasSubjectPhone() => $_has(13);
  @$pb.TagNumber(23)
  void clearSubjectPhone() => clearField(23);

  @$pb.TagNumber(24)
  $core.String get subjectAddress => $_getSZ(14);
  @$pb.TagNumber(24)
  set subjectAddress($core.String v) { $_setString(14, v); }
  @$pb.TagNumber(24)
  $core.bool hasSubjectAddress() => $_has(14);
  @$pb.TagNumber(24)
  void clearSubjectAddress() => clearField(24);

  @$pb.TagNumber(25)
  $core.String get cashierName => $_getSZ(15);
  @$pb.TagNumber(25)
  set cashierName($core.String v) { $_setString(15, v); }
  @$pb.TagNumber(25)
  $core.bool hasCashierName() => $_has(15);
  @$pb.TagNumber(25)
  void clearCashierName() => clearField(25);

  @$pb.TagNumber(31)
  $fixnum.Int64 get storeId => $_getI64(16);
  @$pb.TagNumber(31)
  set storeId($fixnum.Int64 v) { $_setInt64(16, v); }
  @$pb.TagNumber(31)
  $core.bool hasStoreId() => $_has(16);
  @$pb.TagNumber(31)
  void clearStoreId() => clearField(31);

  @$pb.TagNumber(33)
  $fixnum.Int64 get storeTgtId => $_getI64(17);
  @$pb.TagNumber(33)
  set storeTgtId($fixnum.Int64 v) { $_setInt64(17, v); }
  @$pb.TagNumber(33)
  $core.bool hasStoreTgtId() => $_has(17);
  @$pb.TagNumber(33)
  void clearStoreTgtId() => clearField(33);

  @$pb.TagNumber(34)
  $core.String get deliveryState => $_getSZ(18);
  @$pb.TagNumber(34)
  set deliveryState($core.String v) { $_setString(18, v); }
  @$pb.TagNumber(34)
  $core.bool hasDeliveryState() => $_has(18);
  @$pb.TagNumber(34)
  void clearDeliveryState() => clearField(34);

  @$pb.TagNumber(41)
  $fixnum.Int64 get objId => $_getI64(19);
  @$pb.TagNumber(41)
  set objId($fixnum.Int64 v) { $_setInt64(19, v); }
  @$pb.TagNumber(41)
  $core.bool hasObjId() => $_has(19);
  @$pb.TagNumber(41)
  void clearObjId() => clearField(41);

  @$pb.TagNumber(53)
  $core.String get promoCode => $_getSZ(20);
  @$pb.TagNumber(53)
  set promoCode($core.String v) { $_setString(20, v); }
  @$pb.TagNumber(53)
  $core.bool hasPromoCode() => $_has(20);
  @$pb.TagNumber(53)
  void clearPromoCode() => clearField(53);

  @$pb.TagNumber(55)
  $core.bool get isPaid => $_getBF(21);
  @$pb.TagNumber(55)
  set isPaid($core.bool v) { $_setBool(21, v); }
  @$pb.TagNumber(55)
  $core.bool hasIsPaid() => $_has(21);
  @$pb.TagNumber(55)
  void clearIsPaid() => clearField(55);

  @$pb.TagNumber(56)
  $core.bool get isTaskAssigned => $_getBF(22);
  @$pb.TagNumber(56)
  set isTaskAssigned($core.bool v) { $_setBool(22, v); }
  @$pb.TagNumber(56)
  $core.bool hasIsTaskAssigned() => $_has(22);
  @$pb.TagNumber(56)
  void clearIsTaskAssigned() => clearField(56);

  @$pb.TagNumber(57)
  TxOrderPayAt get orderPayAt => $_getN(23);
  @$pb.TagNumber(57)
  set orderPayAt(TxOrderPayAt v) { setField(57, v); }
  @$pb.TagNumber(57)
  $core.bool hasOrderPayAt() => $_has(23);
  @$pb.TagNumber(57)
  void clearOrderPayAt() => clearField(57);

  @$pb.TagNumber(100)
  TxData get txData => $_getN(24);
  @$pb.TagNumber(100)
  set txData(TxData v) { setField(100, v); }
  @$pb.TagNumber(100)
  $core.bool hasTxData() => $_has(24);
  @$pb.TagNumber(100)
  void clearTxData() => clearField(100);
  @$pb.TagNumber(100)
  TxData ensureTxData() => $_ensure(24);

  @$pb.TagNumber(121)
  $fixnum.Int64 get itemsCount => $_getI64(25);
  @$pb.TagNumber(121)
  set itemsCount($fixnum.Int64 v) { $_setInt64(25, v); }
  @$pb.TagNumber(121)
  $core.bool hasItemsCount() => $_has(25);
  @$pb.TagNumber(121)
  void clearItemsCount() => clearField(121);

  @$pb.TagNumber(122)
  $fixnum.Int64 get itemsQty => $_getI64(26);
  @$pb.TagNumber(122)
  set itemsQty($fixnum.Int64 v) { $_setInt64(26, v); }
  @$pb.TagNumber(122)
  $core.bool hasItemsQty() => $_has(26);
  @$pb.TagNumber(122)
  void clearItemsQty() => clearField(122);

  @$pb.TagNumber(123)
  $fixnum.Int64 get itemsTotal => $_getI64(27);
  @$pb.TagNumber(123)
  set itemsTotal($fixnum.Int64 v) { $_setInt64(27, v); }
  @$pb.TagNumber(123)
  $core.bool hasItemsTotal() => $_has(27);
  @$pb.TagNumber(123)
  void clearItemsTotal() => clearField(123);

  @$pb.TagNumber(131)
  $fixnum.Int64 get debtTotal => $_getI64(28);
  @$pb.TagNumber(131)
  set debtTotal($fixnum.Int64 v) { $_setInt64(28, v); }
  @$pb.TagNumber(131)
  $core.bool hasDebtTotal() => $_has(28);
  @$pb.TagNumber(131)
  void clearDebtTotal() => clearField(131);

  @$pb.TagNumber(132)
  $fixnum.Int64 get debtPaid => $_getI64(29);
  @$pb.TagNumber(132)
  set debtPaid($fixnum.Int64 v) { $_setInt64(29, v); }
  @$pb.TagNumber(132)
  $core.bool hasDebtPaid() => $_has(29);
  @$pb.TagNumber(132)
  void clearDebtPaid() => clearField(132);

  @$pb.TagNumber(133)
  $fixnum.Int64 get debtUnpaid => $_getI64(30);
  @$pb.TagNumber(133)
  set debtUnpaid($fixnum.Int64 v) { $_setInt64(30, v); }
  @$pb.TagNumber(133)
  $core.bool hasDebtUnpaid() => $_has(30);
  @$pb.TagNumber(133)
  void clearDebtUnpaid() => clearField(133);

  @$pb.TagNumber(141)
  $fixnum.Int64 get totalTaxes => $_getI64(31);
  @$pb.TagNumber(141)
  set totalTaxes($fixnum.Int64 v) { $_setInt64(31, v); }
  @$pb.TagNumber(141)
  $core.bool hasTotalTaxes() => $_has(31);
  @$pb.TagNumber(141)
  void clearTotalTaxes() => clearField(141);

  @$pb.TagNumber(142)
  $fixnum.Int64 get totalDiscounts => $_getI64(32);
  @$pb.TagNumber(142)
  set totalDiscounts($fixnum.Int64 v) { $_setInt64(32, v); }
  @$pb.TagNumber(142)
  $core.bool hasTotalDiscounts() => $_has(32);
  @$pb.TagNumber(142)
  void clearTotalDiscounts() => clearField(142);

  @$pb.TagNumber(143)
  $fixnum.Int64 get totalInterest => $_getI64(33);
  @$pb.TagNumber(143)
  set totalInterest($fixnum.Int64 v) { $_setInt64(33, v); }
  @$pb.TagNumber(143)
  $core.bool hasTotalInterest() => $_has(33);
  @$pb.TagNumber(143)
  void clearTotalInterest() => clearField(143);

  @$pb.TagNumber(144)
  $fixnum.Int64 get totalPaid => $_getI64(34);
  @$pb.TagNumber(144)
  set totalPaid($fixnum.Int64 v) { $_setInt64(34, v); }
  @$pb.TagNumber(144)
  $core.bool hasTotalPaid() => $_has(34);
  @$pb.TagNumber(144)
  void clearTotalPaid() => clearField(144);

  @$pb.TagNumber(145)
  $fixnum.Int64 get totalUnpaid => $_getI64(35);
  @$pb.TagNumber(145)
  set totalUnpaid($fixnum.Int64 v) { $_setInt64(35, v); }
  @$pb.TagNumber(145)
  $core.bool hasTotalUnpaid() => $_has(35);
  @$pb.TagNumber(145)
  void clearTotalUnpaid() => clearField(145);

  @$pb.TagNumber(151)
  $core.int get stockLineCount => $_getIZ(36);
  @$pb.TagNumber(151)
  set stockLineCount($core.int v) { $_setSignedInt32(36, v); }
  @$pb.TagNumber(151)
  $core.bool hasStockLineCount() => $_has(36);
  @$pb.TagNumber(151)
  void clearStockLineCount() => clearField(151);

  @$pb.TagNumber(152)
  $core.int get stockQtyIn => $_getIZ(37);
  @$pb.TagNumber(152)
  set stockQtyIn($core.int v) { $_setSignedInt32(37, v); }
  @$pb.TagNumber(152)
  $core.bool hasStockQtyIn() => $_has(37);
  @$pb.TagNumber(152)
  void clearStockQtyIn() => clearField(152);

  @$pb.TagNumber(153)
  $core.int get stockQtyOut => $_getIZ(38);
  @$pb.TagNumber(153)
  set stockQtyOut($core.int v) { $_setSignedInt32(38, v); }
  @$pb.TagNumber(153)
  $core.bool hasStockQtyOut() => $_has(38);
  @$pb.TagNumber(153)
  void clearStockQtyOut() => clearField(153);

  @$pb.TagNumber(161)
  $core.int get accLineCount => $_getIZ(39);
  @$pb.TagNumber(161)
  set accLineCount($core.int v) { $_setSignedInt32(39, v); }
  @$pb.TagNumber(161)
  $core.bool hasAccLineCount() => $_has(39);
  @$pb.TagNumber(161)
  void clearAccLineCount() => clearField(161);

  @$pb.TagNumber(162)
  $fixnum.Int64 get accSum => $_getI64(40);
  @$pb.TagNumber(162)
  set accSum($fixnum.Int64 v) { $_setInt64(40, v); }
  @$pb.TagNumber(162)
  $core.bool hasAccSum() => $_has(40);
  @$pb.TagNumber(162)
  void clearAccSum() => clearField(162);

  @$pb.TagNumber(163)
  $core.bool get accBalanced => $_getBF(41);
  @$pb.TagNumber(163)
  set accBalanced($core.bool v) { $_setBool(41, v); }
  @$pb.TagNumber(163)
  $core.bool hasAccBalanced() => $_has(41);
  @$pb.TagNumber(163)
  void clearAccBalanced() => clearField(163);

  @$pb.TagNumber(164)
  $core.bool get hasManualLines => $_getBF(42);
  @$pb.TagNumber(164)
  set hasManualLines($core.bool v) { $_setBool(42, v); }
  @$pb.TagNumber(164)
  $core.bool hasHasManualLines() => $_has(42);
  @$pb.TagNumber(164)
  void clearHasManualLines() => clearField(164);

  @$pb.TagNumber(180)
  $fixnum.Int64 get createdTsMs => $_getI64(43);
  @$pb.TagNumber(180)
  set createdTsMs($fixnum.Int64 v) { $_setInt64(43, v); }
  @$pb.TagNumber(180)
  $core.bool hasCreatedTsMs() => $_has(43);
  @$pb.TagNumber(180)
  void clearCreatedTsMs() => clearField(180);

  @$pb.TagNumber(181)
  $fixnum.Int64 get updatedTsMs => $_getI64(44);
  @$pb.TagNumber(181)
  set updatedTsMs($fixnum.Int64 v) { $_setInt64(44, v); }
  @$pb.TagNumber(181)
  $core.bool hasUpdatedTsMs() => $_has(44);
  @$pb.TagNumber(181)
  void clearUpdatedTsMs() => clearField(181);

  @$pb.TagNumber(182)
  $fixnum.Int64 get deletedTsMs => $_getI64(45);
  @$pb.TagNumber(182)
  set deletedTsMs($fixnum.Int64 v) { $_setInt64(45, v); }
  @$pb.TagNumber(182)
  $core.bool hasDeletedTsMs() => $_has(45);
  @$pb.TagNumber(182)
  void clearDeletedTsMs() => clearField(182);

  @$pb.TagNumber(200)
  $fixnum.Int64 get total => $_getI64(46);
  @$pb.TagNumber(200)
  set total($fixnum.Int64 v) { $_setInt64(46, v); }
  @$pb.TagNumber(200)
  $core.bool hasTotal() => $_has(46);
  @$pb.TagNumber(200)
  void clearTotal() => clearField(200);

  @$pb.TagNumber(201)
  $core.List<TxItem> get items => $_getList(47);

  @$pb.TagNumber(202)
  $core.List<TxPayment> get payments => $_getList(48);

  @$pb.TagNumber(203)
  $core.List<TxAcc> get accs => $_getList(49);

  @$pb.TagNumber(204)
  $core.List<TxStock> get stocks => $_getList(50);

  @$pb.TagNumber(205)
  $core.List<TxTax> get taxes => $_getList(51);

  @$pb.TagNumber(206)
  $core.List<TxDiscount> get discounts => $_getList(52);
}

class TxItem extends $pb.GeneratedMessage {
  factory TxItem({
    $fixnum.Int64? siteIid,
    $fixnum.Int64? txId,
    $fixnum.Int64? itemId,
    $fixnum.Int64? productId,
    $fixnum.Int64? productRev,
    $fixnum.Int64? price,
    $core.String? note,
    $core.int? qty,
    $core.Iterable<TxItemReservation>? reservations,
    $core.Iterable<TxItemSource>? sources,
    $core.String? batchNumber,
    $core.String? serialNumber,
    TxItemFulfillmentState? fulfillmentState,
    $core.int? totalQty,
    $fixnum.Int64? totalPrice,
    $fixnum.Int64? totalDiscount,
    $fixnum.Int64? totalTax,
    $fixnum.Int64? totalNet,
    $fixnum.Int64? totalUnpaid,
    $fixnum.Int64? totalPaid,
  }) {
    final $result = create();
    if (siteIid != null) {
      $result.siteIid = siteIid;
    }
    if (txId != null) {
      $result.txId = txId;
    }
    if (itemId != null) {
      $result.itemId = itemId;
    }
    if (productId != null) {
      $result.productId = productId;
    }
    if (productRev != null) {
      $result.productRev = productRev;
    }
    if (price != null) {
      $result.price = price;
    }
    if (note != null) {
      $result.note = note;
    }
    if (qty != null) {
      $result.qty = qty;
    }
    if (reservations != null) {
      $result.reservations.addAll(reservations);
    }
    if (sources != null) {
      $result.sources.addAll(sources);
    }
    if (batchNumber != null) {
      $result.batchNumber = batchNumber;
    }
    if (serialNumber != null) {
      $result.serialNumber = serialNumber;
    }
    if (fulfillmentState != null) {
      $result.fulfillmentState = fulfillmentState;
    }
    if (totalQty != null) {
      $result.totalQty = totalQty;
    }
    if (totalPrice != null) {
      $result.totalPrice = totalPrice;
    }
    if (totalDiscount != null) {
      $result.totalDiscount = totalDiscount;
    }
    if (totalTax != null) {
      $result.totalTax = totalTax;
    }
    if (totalNet != null) {
      $result.totalNet = totalNet;
    }
    if (totalUnpaid != null) {
      $result.totalUnpaid = totalUnpaid;
    }
    if (totalPaid != null) {
      $result.totalPaid = totalPaid;
    }
    return $result;
  }
  TxItem._() : super();
  factory TxItem.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TxItem.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'TxItem', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'siteIid')
    ..aInt64(2, _omitFieldNames ? '' : 'txId')
    ..aInt64(3, _omitFieldNames ? '' : 'itemId')
    ..aInt64(4, _omitFieldNames ? '' : 'productId')
    ..aInt64(5, _omitFieldNames ? '' : 'productRev')
    ..aInt64(11, _omitFieldNames ? '' : 'price')
    ..aOS(12, _omitFieldNames ? '' : 'note')
    ..a<$core.int>(13, _omitFieldNames ? '' : 'qty', $pb.PbFieldType.O3)
    ..pc<TxItemReservation>(21, _omitFieldNames ? '' : 'reservations', $pb.PbFieldType.PM, subBuilder: TxItemReservation.create)
    ..pc<TxItemSource>(31, _omitFieldNames ? '' : 'sources', $pb.PbFieldType.PM, subBuilder: TxItemSource.create)
    ..aOS(32, _omitFieldNames ? '' : 'batchNumber')
    ..aOS(33, _omitFieldNames ? '' : 'serialNumber')
    ..e<TxItemFulfillmentState>(37, _omitFieldNames ? '' : 'fulfillmentState', $pb.PbFieldType.OE, defaultOrMaker: TxItemFulfillmentState.TX_ITEM_FULFILLMENT_UNSPECIFIED, valueOf: TxItemFulfillmentState.valueOf, enumValues: TxItemFulfillmentState.values)
    ..a<$core.int>(101, _omitFieldNames ? '' : 'totalQty', $pb.PbFieldType.O3)
    ..aInt64(102, _omitFieldNames ? '' : 'totalPrice')
    ..aInt64(103, _omitFieldNames ? '' : 'totalDiscount')
    ..aInt64(104, _omitFieldNames ? '' : 'totalTax')
    ..aInt64(105, _omitFieldNames ? '' : 'totalNet')
    ..aInt64(201, _omitFieldNames ? '' : 'totalUnpaid')
    ..aInt64(202, _omitFieldNames ? '' : 'totalPaid')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  TxItem clone() => TxItem()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  TxItem copyWith(void Function(TxItem) updates) => super.copyWith((message) => updates(message as TxItem)) as TxItem;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TxItem create() => TxItem._();
  TxItem createEmptyInstance() => create();
  static $pb.PbList<TxItem> createRepeated() => $pb.PbList<TxItem>();
  @$core.pragma('dart2js:noInline')
  static TxItem getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TxItem>(create);
  static TxItem? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get siteIid => $_getI64(0);
  @$pb.TagNumber(1)
  set siteIid($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasSiteIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearSiteIid() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get txId => $_getI64(1);
  @$pb.TagNumber(2)
  set txId($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasTxId() => $_has(1);
  @$pb.TagNumber(2)
  void clearTxId() => clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get itemId => $_getI64(2);
  @$pb.TagNumber(3)
  set itemId($fixnum.Int64 v) { $_setInt64(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasItemId() => $_has(2);
  @$pb.TagNumber(3)
  void clearItemId() => clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get productId => $_getI64(3);
  @$pb.TagNumber(4)
  set productId($fixnum.Int64 v) { $_setInt64(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasProductId() => $_has(3);
  @$pb.TagNumber(4)
  void clearProductId() => clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get productRev => $_getI64(4);
  @$pb.TagNumber(5)
  set productRev($fixnum.Int64 v) { $_setInt64(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasProductRev() => $_has(4);
  @$pb.TagNumber(5)
  void clearProductRev() => clearField(5);

  @$pb.TagNumber(11)
  $fixnum.Int64 get price => $_getI64(5);
  @$pb.TagNumber(11)
  set price($fixnum.Int64 v) { $_setInt64(5, v); }
  @$pb.TagNumber(11)
  $core.bool hasPrice() => $_has(5);
  @$pb.TagNumber(11)
  void clearPrice() => clearField(11);

  @$pb.TagNumber(12)
  $core.String get note => $_getSZ(6);
  @$pb.TagNumber(12)
  set note($core.String v) { $_setString(6, v); }
  @$pb.TagNumber(12)
  $core.bool hasNote() => $_has(6);
  @$pb.TagNumber(12)
  void clearNote() => clearField(12);

  @$pb.TagNumber(13)
  $core.int get qty => $_getIZ(7);
  @$pb.TagNumber(13)
  set qty($core.int v) { $_setSignedInt32(7, v); }
  @$pb.TagNumber(13)
  $core.bool hasQty() => $_has(7);
  @$pb.TagNumber(13)
  void clearQty() => clearField(13);

  @$pb.TagNumber(21)
  $core.List<TxItemReservation> get reservations => $_getList(8);

  @$pb.TagNumber(31)
  $core.List<TxItemSource> get sources => $_getList(9);

  @$pb.TagNumber(32)
  $core.String get batchNumber => $_getSZ(10);
  @$pb.TagNumber(32)
  set batchNumber($core.String v) { $_setString(10, v); }
  @$pb.TagNumber(32)
  $core.bool hasBatchNumber() => $_has(10);
  @$pb.TagNumber(32)
  void clearBatchNumber() => clearField(32);

  @$pb.TagNumber(33)
  $core.String get serialNumber => $_getSZ(11);
  @$pb.TagNumber(33)
  set serialNumber($core.String v) { $_setString(11, v); }
  @$pb.TagNumber(33)
  $core.bool hasSerialNumber() => $_has(11);
  @$pb.TagNumber(33)
  void clearSerialNumber() => clearField(33);

  @$pb.TagNumber(37)
  TxItemFulfillmentState get fulfillmentState => $_getN(12);
  @$pb.TagNumber(37)
  set fulfillmentState(TxItemFulfillmentState v) { setField(37, v); }
  @$pb.TagNumber(37)
  $core.bool hasFulfillmentState() => $_has(12);
  @$pb.TagNumber(37)
  void clearFulfillmentState() => clearField(37);

  @$pb.TagNumber(101)
  $core.int get totalQty => $_getIZ(13);
  @$pb.TagNumber(101)
  set totalQty($core.int v) { $_setSignedInt32(13, v); }
  @$pb.TagNumber(101)
  $core.bool hasTotalQty() => $_has(13);
  @$pb.TagNumber(101)
  void clearTotalQty() => clearField(101);

  @$pb.TagNumber(102)
  $fixnum.Int64 get totalPrice => $_getI64(14);
  @$pb.TagNumber(102)
  set totalPrice($fixnum.Int64 v) { $_setInt64(14, v); }
  @$pb.TagNumber(102)
  $core.bool hasTotalPrice() => $_has(14);
  @$pb.TagNumber(102)
  void clearTotalPrice() => clearField(102);

  @$pb.TagNumber(103)
  $fixnum.Int64 get totalDiscount => $_getI64(15);
  @$pb.TagNumber(103)
  set totalDiscount($fixnum.Int64 v) { $_setInt64(15, v); }
  @$pb.TagNumber(103)
  $core.bool hasTotalDiscount() => $_has(15);
  @$pb.TagNumber(103)
  void clearTotalDiscount() => clearField(103);

  @$pb.TagNumber(104)
  $fixnum.Int64 get totalTax => $_getI64(16);
  @$pb.TagNumber(104)
  set totalTax($fixnum.Int64 v) { $_setInt64(16, v); }
  @$pb.TagNumber(104)
  $core.bool hasTotalTax() => $_has(16);
  @$pb.TagNumber(104)
  void clearTotalTax() => clearField(104);

  @$pb.TagNumber(105)
  $fixnum.Int64 get totalNet => $_getI64(17);
  @$pb.TagNumber(105)
  set totalNet($fixnum.Int64 v) { $_setInt64(17, v); }
  @$pb.TagNumber(105)
  $core.bool hasTotalNet() => $_has(17);
  @$pb.TagNumber(105)
  void clearTotalNet() => clearField(105);

  @$pb.TagNumber(201)
  $fixnum.Int64 get totalUnpaid => $_getI64(18);
  @$pb.TagNumber(201)
  set totalUnpaid($fixnum.Int64 v) { $_setInt64(18, v); }
  @$pb.TagNumber(201)
  $core.bool hasTotalUnpaid() => $_has(18);
  @$pb.TagNumber(201)
  void clearTotalUnpaid() => clearField(201);

  @$pb.TagNumber(202)
  $fixnum.Int64 get totalPaid => $_getI64(19);
  @$pb.TagNumber(202)
  set totalPaid($fixnum.Int64 v) { $_setInt64(19, v); }
  @$pb.TagNumber(202)
  $core.bool hasTotalPaid() => $_has(19);
  @$pb.TagNumber(202)
  void clearTotalPaid() => clearField(202);
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
    final $result = create();
    if (resId != null) {
      $result.resId = resId;
    }
    if (productId != null) {
      $result.productId = productId;
    }
    if (qty != null) {
      $result.qty = qty;
    }
    if (durationQty != null) {
      $result.durationQty = durationQty;
    }
    if (note != null) {
      $result.note = note;
    }
    if (startTsMs != null) {
      $result.startTsMs = startTsMs;
    }
    if (endTsMs != null) {
      $result.endTsMs = endTsMs;
    }
    if (state != null) {
      $result.state = state;
    }
    if (isNoShow != null) {
      $result.isNoShow = isNoShow;
    }
    if (isUnavailable != null) {
      $result.isUnavailable = isUnavailable;
    }
    return $result;
  }
  TxItemReservation._() : super();
  factory TxItemReservation.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TxItemReservation.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'TxItemReservation', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aInt64(4, _omitFieldNames ? '' : 'resId')
    ..aInt64(5, _omitFieldNames ? '' : 'productId')
    ..a<$core.int>(10, _omitFieldNames ? '' : 'qty', $pb.PbFieldType.O3)
    ..a<$core.int>(11, _omitFieldNames ? '' : 'durationQty', $pb.PbFieldType.O3)
    ..aOS(12, _omitFieldNames ? '' : 'note')
    ..aInt64(20, _omitFieldNames ? '' : 'startTsMs')
    ..aInt64(21, _omitFieldNames ? '' : 'endTsMs')
    ..aOS(30, _omitFieldNames ? '' : 'state')
    ..aOB(31, _omitFieldNames ? '' : 'isNoShow')
    ..aOB(32, _omitFieldNames ? '' : 'isUnavailable')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  TxItemReservation clone() => TxItemReservation()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  TxItemReservation copyWith(void Function(TxItemReservation) updates) => super.copyWith((message) => updates(message as TxItemReservation)) as TxItemReservation;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TxItemReservation create() => TxItemReservation._();
  TxItemReservation createEmptyInstance() => create();
  static $pb.PbList<TxItemReservation> createRepeated() => $pb.PbList<TxItemReservation>();
  @$core.pragma('dart2js:noInline')
  static TxItemReservation getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TxItemReservation>(create);
  static TxItemReservation? _defaultInstance;

  @$pb.TagNumber(4)
  $fixnum.Int64 get resId => $_getI64(0);
  @$pb.TagNumber(4)
  set resId($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(4)
  $core.bool hasResId() => $_has(0);
  @$pb.TagNumber(4)
  void clearResId() => clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get productId => $_getI64(1);
  @$pb.TagNumber(5)
  set productId($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(5)
  $core.bool hasProductId() => $_has(1);
  @$pb.TagNumber(5)
  void clearProductId() => clearField(5);

  @$pb.TagNumber(10)
  $core.int get qty => $_getIZ(2);
  @$pb.TagNumber(10)
  set qty($core.int v) { $_setSignedInt32(2, v); }
  @$pb.TagNumber(10)
  $core.bool hasQty() => $_has(2);
  @$pb.TagNumber(10)
  void clearQty() => clearField(10);

  @$pb.TagNumber(11)
  $core.int get durationQty => $_getIZ(3);
  @$pb.TagNumber(11)
  set durationQty($core.int v) { $_setSignedInt32(3, v); }
  @$pb.TagNumber(11)
  $core.bool hasDurationQty() => $_has(3);
  @$pb.TagNumber(11)
  void clearDurationQty() => clearField(11);

  @$pb.TagNumber(12)
  $core.String get note => $_getSZ(4);
  @$pb.TagNumber(12)
  set note($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(12)
  $core.bool hasNote() => $_has(4);
  @$pb.TagNumber(12)
  void clearNote() => clearField(12);

  @$pb.TagNumber(20)
  $fixnum.Int64 get startTsMs => $_getI64(5);
  @$pb.TagNumber(20)
  set startTsMs($fixnum.Int64 v) { $_setInt64(5, v); }
  @$pb.TagNumber(20)
  $core.bool hasStartTsMs() => $_has(5);
  @$pb.TagNumber(20)
  void clearStartTsMs() => clearField(20);

  @$pb.TagNumber(21)
  $fixnum.Int64 get endTsMs => $_getI64(6);
  @$pb.TagNumber(21)
  set endTsMs($fixnum.Int64 v) { $_setInt64(6, v); }
  @$pb.TagNumber(21)
  $core.bool hasEndTsMs() => $_has(6);
  @$pb.TagNumber(21)
  void clearEndTsMs() => clearField(21);

  @$pb.TagNumber(30)
  $core.String get state => $_getSZ(7);
  @$pb.TagNumber(30)
  set state($core.String v) { $_setString(7, v); }
  @$pb.TagNumber(30)
  $core.bool hasState() => $_has(7);
  @$pb.TagNumber(30)
  void clearState() => clearField(30);

  @$pb.TagNumber(31)
  $core.bool get isNoShow => $_getBF(8);
  @$pb.TagNumber(31)
  set isNoShow($core.bool v) { $_setBool(8, v); }
  @$pb.TagNumber(31)
  $core.bool hasIsNoShow() => $_has(8);
  @$pb.TagNumber(31)
  void clearIsNoShow() => clearField(31);

  @$pb.TagNumber(32)
  $core.bool get isUnavailable => $_getBF(9);
  @$pb.TagNumber(32)
  set isUnavailable($core.bool v) { $_setBool(9, v); }
  @$pb.TagNumber(32)
  $core.bool hasIsUnavailable() => $_has(9);
  @$pb.TagNumber(32)
  void clearIsUnavailable() => clearField(32);
}

class TxItemSource extends $pb.GeneratedMessage {
  factory TxItemSource({
    $fixnum.Int64? srcId,
    $fixnum.Int64? objId,
    $fixnum.Int64? productId,
    $core.int? qty,
    $core.String? note,
  }) {
    final $result = create();
    if (srcId != null) {
      $result.srcId = srcId;
    }
    if (objId != null) {
      $result.objId = objId;
    }
    if (productId != null) {
      $result.productId = productId;
    }
    if (qty != null) {
      $result.qty = qty;
    }
    if (note != null) {
      $result.note = note;
    }
    return $result;
  }
  TxItemSource._() : super();
  factory TxItemSource.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TxItemSource.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'TxItemSource', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aInt64(4, _omitFieldNames ? '' : 'srcId')
    ..aInt64(10, _omitFieldNames ? '' : 'objId')
    ..aInt64(11, _omitFieldNames ? '' : 'productId')
    ..a<$core.int>(12, _omitFieldNames ? '' : 'qty', $pb.PbFieldType.O3)
    ..aOS(13, _omitFieldNames ? '' : 'note')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  TxItemSource clone() => TxItemSource()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  TxItemSource copyWith(void Function(TxItemSource) updates) => super.copyWith((message) => updates(message as TxItemSource)) as TxItemSource;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TxItemSource create() => TxItemSource._();
  TxItemSource createEmptyInstance() => create();
  static $pb.PbList<TxItemSource> createRepeated() => $pb.PbList<TxItemSource>();
  @$core.pragma('dart2js:noInline')
  static TxItemSource getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TxItemSource>(create);
  static TxItemSource? _defaultInstance;

  @$pb.TagNumber(4)
  $fixnum.Int64 get srcId => $_getI64(0);
  @$pb.TagNumber(4)
  set srcId($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(4)
  $core.bool hasSrcId() => $_has(0);
  @$pb.TagNumber(4)
  void clearSrcId() => clearField(4);

  @$pb.TagNumber(10)
  $fixnum.Int64 get objId => $_getI64(1);
  @$pb.TagNumber(10)
  set objId($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(10)
  $core.bool hasObjId() => $_has(1);
  @$pb.TagNumber(10)
  void clearObjId() => clearField(10);

  @$pb.TagNumber(11)
  $fixnum.Int64 get productId => $_getI64(2);
  @$pb.TagNumber(11)
  set productId($fixnum.Int64 v) { $_setInt64(2, v); }
  @$pb.TagNumber(11)
  $core.bool hasProductId() => $_has(2);
  @$pb.TagNumber(11)
  void clearProductId() => clearField(11);

  @$pb.TagNumber(12)
  $core.int get qty => $_getIZ(3);
  @$pb.TagNumber(12)
  set qty($core.int v) { $_setSignedInt32(3, v); }
  @$pb.TagNumber(12)
  $core.bool hasQty() => $_has(3);
  @$pb.TagNumber(12)
  void clearQty() => clearField(12);

  @$pb.TagNumber(13)
  $core.String get note => $_getSZ(4);
  @$pb.TagNumber(13)
  set note($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(13)
  $core.bool hasNote() => $_has(4);
  @$pb.TagNumber(13)
  void clearNote() => clearField(13);
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
    final $result = create();
    if (objId != null) {
      $result.objId = objId;
    }
    if (contactId != null) {
      $result.contactId = contactId;
    }
    if (userIid != null) {
      $result.userIid = userIid;
    }
    if (to != null) {
      $result.to = to;
    }
    if (service != null) {
      $result.service = service;
    }
    if (state != null) {
      $result.state = state;
    }
    return $result;
  }
  TxDelivery._() : super();
  factory TxDelivery.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TxDelivery.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'TxDelivery', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'objId')
    ..aInt64(2, _omitFieldNames ? '' : 'contactId')
    ..aInt64(3, _omitFieldNames ? '' : 'userIid')
    ..aOM<TxDeliveryTo>(11, _omitFieldNames ? '' : 'to', subBuilder: TxDeliveryTo.create)
    ..aOM<TxDeliveryService>(12, _omitFieldNames ? '' : 'service', subBuilder: TxDeliveryService.create)
    ..aOS(200, _omitFieldNames ? '' : 'state')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  TxDelivery clone() => TxDelivery()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  TxDelivery copyWith(void Function(TxDelivery) updates) => super.copyWith((message) => updates(message as TxDelivery)) as TxDelivery;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TxDelivery create() => TxDelivery._();
  TxDelivery createEmptyInstance() => create();
  static $pb.PbList<TxDelivery> createRepeated() => $pb.PbList<TxDelivery>();
  @$core.pragma('dart2js:noInline')
  static TxDelivery getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TxDelivery>(create);
  static TxDelivery? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get objId => $_getI64(0);
  @$pb.TagNumber(1)
  set objId($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasObjId() => $_has(0);
  @$pb.TagNumber(1)
  void clearObjId() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get contactId => $_getI64(1);
  @$pb.TagNumber(2)
  set contactId($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasContactId() => $_has(1);
  @$pb.TagNumber(2)
  void clearContactId() => clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get userIid => $_getI64(2);
  @$pb.TagNumber(3)
  set userIid($fixnum.Int64 v) { $_setInt64(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasUserIid() => $_has(2);
  @$pb.TagNumber(3)
  void clearUserIid() => clearField(3);

  @$pb.TagNumber(11)
  TxDeliveryTo get to => $_getN(3);
  @$pb.TagNumber(11)
  set to(TxDeliveryTo v) { setField(11, v); }
  @$pb.TagNumber(11)
  $core.bool hasTo() => $_has(3);
  @$pb.TagNumber(11)
  void clearTo() => clearField(11);
  @$pb.TagNumber(11)
  TxDeliveryTo ensureTo() => $_ensure(3);

  @$pb.TagNumber(12)
  TxDeliveryService get service => $_getN(4);
  @$pb.TagNumber(12)
  set service(TxDeliveryService v) { setField(12, v); }
  @$pb.TagNumber(12)
  $core.bool hasService() => $_has(4);
  @$pb.TagNumber(12)
  void clearService() => clearField(12);
  @$pb.TagNumber(12)
  TxDeliveryService ensureService() => $_ensure(4);

  @$pb.TagNumber(200)
  $core.String get state => $_getSZ(5);
  @$pb.TagNumber(200)
  set state($core.String v) { $_setString(5, v); }
  @$pb.TagNumber(200)
  $core.bool hasState() => $_has(5);
  @$pb.TagNumber(200)
  void clearState() => clearField(200);
}

class TxDeliveryTo extends $pb.GeneratedMessage {
  factory TxDeliveryTo({
    $core.String? name,
    $core.String? phone,
    $core.String? address,
    $core.String? email,
  }) {
    final $result = create();
    if (name != null) {
      $result.name = name;
    }
    if (phone != null) {
      $result.phone = phone;
    }
    if (address != null) {
      $result.address = address;
    }
    if (email != null) {
      $result.email = email;
    }
    return $result;
  }
  TxDeliveryTo._() : super();
  factory TxDeliveryTo.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TxDeliveryTo.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'TxDeliveryTo', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'phone')
    ..aOS(3, _omitFieldNames ? '' : 'address')
    ..aOS(4, _omitFieldNames ? '' : 'email')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  TxDeliveryTo clone() => TxDeliveryTo()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  TxDeliveryTo copyWith(void Function(TxDeliveryTo) updates) => super.copyWith((message) => updates(message as TxDeliveryTo)) as TxDeliveryTo;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TxDeliveryTo create() => TxDeliveryTo._();
  TxDeliveryTo createEmptyInstance() => create();
  static $pb.PbList<TxDeliveryTo> createRepeated() => $pb.PbList<TxDeliveryTo>();
  @$core.pragma('dart2js:noInline')
  static TxDeliveryTo getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TxDeliveryTo>(create);
  static TxDeliveryTo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get phone => $_getSZ(1);
  @$pb.TagNumber(2)
  set phone($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasPhone() => $_has(1);
  @$pb.TagNumber(2)
  void clearPhone() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get address => $_getSZ(2);
  @$pb.TagNumber(3)
  set address($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasAddress() => $_has(2);
  @$pb.TagNumber(3)
  void clearAddress() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get email => $_getSZ(3);
  @$pb.TagNumber(4)
  set email($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasEmail() => $_has(3);
  @$pb.TagNumber(4)
  void clearEmail() => clearField(4);
}

class TxDeliveryService extends $pb.GeneratedMessage {
  factory TxDeliveryService({
    $core.String? name,
    $core.String? trackingNumber,
    $core.String? trackingUrl,
    $core.String? note,
  }) {
    final $result = create();
    if (name != null) {
      $result.name = name;
    }
    if (trackingNumber != null) {
      $result.trackingNumber = trackingNumber;
    }
    if (trackingUrl != null) {
      $result.trackingUrl = trackingUrl;
    }
    if (note != null) {
      $result.note = note;
    }
    return $result;
  }
  TxDeliveryService._() : super();
  factory TxDeliveryService.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TxDeliveryService.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'TxDeliveryService', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'trackingNumber')
    ..aOS(3, _omitFieldNames ? '' : 'trackingUrl')
    ..aOS(4, _omitFieldNames ? '' : 'note')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  TxDeliveryService clone() => TxDeliveryService()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  TxDeliveryService copyWith(void Function(TxDeliveryService) updates) => super.copyWith((message) => updates(message as TxDeliveryService)) as TxDeliveryService;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TxDeliveryService create() => TxDeliveryService._();
  TxDeliveryService createEmptyInstance() => create();
  static $pb.PbList<TxDeliveryService> createRepeated() => $pb.PbList<TxDeliveryService>();
  @$core.pragma('dart2js:noInline')
  static TxDeliveryService getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TxDeliveryService>(create);
  static TxDeliveryService? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get trackingNumber => $_getSZ(1);
  @$pb.TagNumber(2)
  set trackingNumber($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasTrackingNumber() => $_has(1);
  @$pb.TagNumber(2)
  void clearTrackingNumber() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get trackingUrl => $_getSZ(2);
  @$pb.TagNumber(3)
  set trackingUrl($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasTrackingUrl() => $_has(2);
  @$pb.TagNumber(3)
  void clearTrackingUrl() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get note => $_getSZ(3);
  @$pb.TagNumber(4)
  set note($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasNote() => $_has(3);
  @$pb.TagNumber(4)
  void clearNote() => clearField(4);
}

class TxDiscount extends $pb.GeneratedMessage {
  factory TxDiscount({
    $fixnum.Int64? discountId,
    $core.String? discountType,
    $fixnum.Int64? amount,
    $core.String? note,
  }) {
    final $result = create();
    if (discountId != null) {
      $result.discountId = discountId;
    }
    if (discountType != null) {
      $result.discountType = discountType;
    }
    if (amount != null) {
      $result.amount = amount;
    }
    if (note != null) {
      $result.note = note;
    }
    return $result;
  }
  TxDiscount._() : super();
  factory TxDiscount.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TxDiscount.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'TxDiscount', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aInt64(3, _omitFieldNames ? '' : 'discountId')
    ..aOS(10, _omitFieldNames ? '' : 'discountType')
    ..aInt64(11, _omitFieldNames ? '' : 'amount')
    ..aOS(12, _omitFieldNames ? '' : 'note')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  TxDiscount clone() => TxDiscount()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  TxDiscount copyWith(void Function(TxDiscount) updates) => super.copyWith((message) => updates(message as TxDiscount)) as TxDiscount;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TxDiscount create() => TxDiscount._();
  TxDiscount createEmptyInstance() => create();
  static $pb.PbList<TxDiscount> createRepeated() => $pb.PbList<TxDiscount>();
  @$core.pragma('dart2js:noInline')
  static TxDiscount getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TxDiscount>(create);
  static TxDiscount? _defaultInstance;

  @$pb.TagNumber(3)
  $fixnum.Int64 get discountId => $_getI64(0);
  @$pb.TagNumber(3)
  set discountId($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(3)
  $core.bool hasDiscountId() => $_has(0);
  @$pb.TagNumber(3)
  void clearDiscountId() => clearField(3);

  @$pb.TagNumber(10)
  $core.String get discountType => $_getSZ(1);
  @$pb.TagNumber(10)
  set discountType($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(10)
  $core.bool hasDiscountType() => $_has(1);
  @$pb.TagNumber(10)
  void clearDiscountType() => clearField(10);

  @$pb.TagNumber(11)
  $fixnum.Int64 get amount => $_getI64(2);
  @$pb.TagNumber(11)
  set amount($fixnum.Int64 v) { $_setInt64(2, v); }
  @$pb.TagNumber(11)
  $core.bool hasAmount() => $_has(2);
  @$pb.TagNumber(11)
  void clearAmount() => clearField(11);

  @$pb.TagNumber(12)
  $core.String get note => $_getSZ(3);
  @$pb.TagNumber(12)
  set note($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(12)
  $core.bool hasNote() => $_has(3);
  @$pb.TagNumber(12)
  void clearNote() => clearField(12);
}

class TxTax extends $pb.GeneratedMessage {
  factory TxTax({
    $fixnum.Int64? taxId,
    $core.String? taxType,
    $fixnum.Int64? amount,
    $core.String? note,
  }) {
    final $result = create();
    if (taxId != null) {
      $result.taxId = taxId;
    }
    if (taxType != null) {
      $result.taxType = taxType;
    }
    if (amount != null) {
      $result.amount = amount;
    }
    if (note != null) {
      $result.note = note;
    }
    return $result;
  }
  TxTax._() : super();
  factory TxTax.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TxTax.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'TxTax', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aInt64(3, _omitFieldNames ? '' : 'taxId')
    ..aOS(10, _omitFieldNames ? '' : 'taxType')
    ..aInt64(11, _omitFieldNames ? '' : 'amount')
    ..aOS(12, _omitFieldNames ? '' : 'note')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  TxTax clone() => TxTax()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  TxTax copyWith(void Function(TxTax) updates) => super.copyWith((message) => updates(message as TxTax)) as TxTax;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TxTax create() => TxTax._();
  TxTax createEmptyInstance() => create();
  static $pb.PbList<TxTax> createRepeated() => $pb.PbList<TxTax>();
  @$core.pragma('dart2js:noInline')
  static TxTax getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TxTax>(create);
  static TxTax? _defaultInstance;

  @$pb.TagNumber(3)
  $fixnum.Int64 get taxId => $_getI64(0);
  @$pb.TagNumber(3)
  set taxId($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(3)
  $core.bool hasTaxId() => $_has(0);
  @$pb.TagNumber(3)
  void clearTaxId() => clearField(3);

  @$pb.TagNumber(10)
  $core.String get taxType => $_getSZ(1);
  @$pb.TagNumber(10)
  set taxType($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(10)
  $core.bool hasTaxType() => $_has(1);
  @$pb.TagNumber(10)
  void clearTaxType() => clearField(10);

  @$pb.TagNumber(11)
  $fixnum.Int64 get amount => $_getI64(2);
  @$pb.TagNumber(11)
  set amount($fixnum.Int64 v) { $_setInt64(2, v); }
  @$pb.TagNumber(11)
  $core.bool hasAmount() => $_has(2);
  @$pb.TagNumber(11)
  void clearAmount() => clearField(11);

  @$pb.TagNumber(12)
  $core.String get note => $_getSZ(3);
  @$pb.TagNumber(12)
  set note($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(12)
  $core.bool hasNote() => $_has(3);
  @$pb.TagNumber(12)
  void clearNote() => clearField(12);
}

class TxPromo extends $pb.GeneratedMessage {
  factory TxPromo({
    $core.String? promoId,
    $core.String? code,
    $core.String? name,
    $fixnum.Int64? amount,
  }) {
    final $result = create();
    if (promoId != null) {
      $result.promoId = promoId;
    }
    if (code != null) {
      $result.code = code;
    }
    if (name != null) {
      $result.name = name;
    }
    if (amount != null) {
      $result.amount = amount;
    }
    return $result;
  }
  TxPromo._() : super();
  factory TxPromo.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TxPromo.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'TxPromo', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'promoId')
    ..aOS(2, _omitFieldNames ? '' : 'code')
    ..aOS(3, _omitFieldNames ? '' : 'name')
    ..aInt64(4, _omitFieldNames ? '' : 'amount')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  TxPromo clone() => TxPromo()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  TxPromo copyWith(void Function(TxPromo) updates) => super.copyWith((message) => updates(message as TxPromo)) as TxPromo;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TxPromo create() => TxPromo._();
  TxPromo createEmptyInstance() => create();
  static $pb.PbList<TxPromo> createRepeated() => $pb.PbList<TxPromo>();
  @$core.pragma('dart2js:noInline')
  static TxPromo getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TxPromo>(create);
  static TxPromo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get promoId => $_getSZ(0);
  @$pb.TagNumber(1)
  set promoId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasPromoId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPromoId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get code => $_getSZ(1);
  @$pb.TagNumber(2)
  set code($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasCode() => $_has(1);
  @$pb.TagNumber(2)
  void clearCode() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get name => $_getSZ(2);
  @$pb.TagNumber(3)
  set name($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasName() => $_has(2);
  @$pb.TagNumber(3)
  void clearName() => clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get amount => $_getI64(3);
  @$pb.TagNumber(4)
  set amount($fixnum.Int64 v) { $_setInt64(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasAmount() => $_has(3);
  @$pb.TagNumber(4)
  void clearAmount() => clearField(4);
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
    final $result = create();
    if (paymentId != null) {
      $result.paymentId = paymentId;
    }
    if (method != null) {
      $result.method = method;
    }
    if (tsMs != null) {
      $result.tsMs = tsMs;
    }
    if (amount != null) {
      $result.amount = amount;
    }
    if (note != null) {
      $result.note = note;
    }
    if (fromWallet != null) {
      $result.fromWallet = fromWallet;
    }
    if (toWallet != null) {
      $result.toWallet = toWallet;
    }
    if (debtInterest != null) {
      $result.debtInterest = debtInterest;
    }
    if (paymentJson != null) {
      $result.paymentJson = paymentJson;
    }
    if (installments != null) {
      $result.installments.addAll(installments);
    }
    return $result;
  }
  TxPayment._() : super();
  factory TxPayment.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TxPayment.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'TxPayment', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aInt64(3, _omitFieldNames ? '' : 'paymentId')
    ..e<TxPaymentMethod>(10, _omitFieldNames ? '' : 'method', $pb.PbFieldType.OE, defaultOrMaker: TxPaymentMethod.TX_PAYMENT_METHOD_UNSPECIFIED, valueOf: TxPaymentMethod.valueOf, enumValues: TxPaymentMethod.values)
    ..aInt64(11, _omitFieldNames ? '' : 'tsMs')
    ..aInt64(12, _omitFieldNames ? '' : 'amount')
    ..aOS(13, _omitFieldNames ? '' : 'note')
    ..aOS(20, _omitFieldNames ? '' : 'fromWallet')
    ..aOS(21, _omitFieldNames ? '' : 'toWallet')
    ..aInt64(25, _omitFieldNames ? '' : 'debtInterest')
    ..aOS(100, _omitFieldNames ? '' : 'paymentJson')
    ..pc<TxInstallment>(110, _omitFieldNames ? '' : 'installments', $pb.PbFieldType.PM, subBuilder: TxInstallment.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  TxPayment clone() => TxPayment()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  TxPayment copyWith(void Function(TxPayment) updates) => super.copyWith((message) => updates(message as TxPayment)) as TxPayment;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TxPayment create() => TxPayment._();
  TxPayment createEmptyInstance() => create();
  static $pb.PbList<TxPayment> createRepeated() => $pb.PbList<TxPayment>();
  @$core.pragma('dart2js:noInline')
  static TxPayment getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TxPayment>(create);
  static TxPayment? _defaultInstance;

  @$pb.TagNumber(3)
  $fixnum.Int64 get paymentId => $_getI64(0);
  @$pb.TagNumber(3)
  set paymentId($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(3)
  $core.bool hasPaymentId() => $_has(0);
  @$pb.TagNumber(3)
  void clearPaymentId() => clearField(3);

  @$pb.TagNumber(10)
  TxPaymentMethod get method => $_getN(1);
  @$pb.TagNumber(10)
  set method(TxPaymentMethod v) { setField(10, v); }
  @$pb.TagNumber(10)
  $core.bool hasMethod() => $_has(1);
  @$pb.TagNumber(10)
  void clearMethod() => clearField(10);

  @$pb.TagNumber(11)
  $fixnum.Int64 get tsMs => $_getI64(2);
  @$pb.TagNumber(11)
  set tsMs($fixnum.Int64 v) { $_setInt64(2, v); }
  @$pb.TagNumber(11)
  $core.bool hasTsMs() => $_has(2);
  @$pb.TagNumber(11)
  void clearTsMs() => clearField(11);

  @$pb.TagNumber(12)
  $fixnum.Int64 get amount => $_getI64(3);
  @$pb.TagNumber(12)
  set amount($fixnum.Int64 v) { $_setInt64(3, v); }
  @$pb.TagNumber(12)
  $core.bool hasAmount() => $_has(3);
  @$pb.TagNumber(12)
  void clearAmount() => clearField(12);

  @$pb.TagNumber(13)
  $core.String get note => $_getSZ(4);
  @$pb.TagNumber(13)
  set note($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(13)
  $core.bool hasNote() => $_has(4);
  @$pb.TagNumber(13)
  void clearNote() => clearField(13);

  @$pb.TagNumber(20)
  $core.String get fromWallet => $_getSZ(5);
  @$pb.TagNumber(20)
  set fromWallet($core.String v) { $_setString(5, v); }
  @$pb.TagNumber(20)
  $core.bool hasFromWallet() => $_has(5);
  @$pb.TagNumber(20)
  void clearFromWallet() => clearField(20);

  @$pb.TagNumber(21)
  $core.String get toWallet => $_getSZ(6);
  @$pb.TagNumber(21)
  set toWallet($core.String v) { $_setString(6, v); }
  @$pb.TagNumber(21)
  $core.bool hasToWallet() => $_has(6);
  @$pb.TagNumber(21)
  void clearToWallet() => clearField(21);

  @$pb.TagNumber(25)
  $fixnum.Int64 get debtInterest => $_getI64(7);
  @$pb.TagNumber(25)
  set debtInterest($fixnum.Int64 v) { $_setInt64(7, v); }
  @$pb.TagNumber(25)
  $core.bool hasDebtInterest() => $_has(7);
  @$pb.TagNumber(25)
  void clearDebtInterest() => clearField(25);

  @$pb.TagNumber(100)
  $core.String get paymentJson => $_getSZ(8);
  @$pb.TagNumber(100)
  set paymentJson($core.String v) { $_setString(8, v); }
  @$pb.TagNumber(100)
  $core.bool hasPaymentJson() => $_has(8);
  @$pb.TagNumber(100)
  void clearPaymentJson() => clearField(100);

  @$pb.TagNumber(110)
  $core.List<TxInstallment> get installments => $_getList(9);
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
    final $result = create();
    if (instId != null) {
      $result.instId = instId;
    }
    if (dueTsMs != null) {
      $result.dueTsMs = dueTsMs;
    }
    if (amount != null) {
      $result.amount = amount;
    }
    if (note != null) {
      $result.note = note;
    }
    if (isPaid != null) {
      $result.isPaid = isPaid;
    }
    if (isOverdue != null) {
      $result.isOverdue = isOverdue;
    }
    if (debtPayments != null) {
      $result.debtPayments.addAll(debtPayments);
    }
    return $result;
  }
  TxInstallment._() : super();
  factory TxInstallment.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TxInstallment.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'TxInstallment', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aInt64(4, _omitFieldNames ? '' : 'instId')
    ..aInt64(10, _omitFieldNames ? '' : 'dueTsMs')
    ..aInt64(11, _omitFieldNames ? '' : 'amount')
    ..aOS(12, _omitFieldNames ? '' : 'note')
    ..aOB(21, _omitFieldNames ? '' : 'isPaid')
    ..aOB(22, _omitFieldNames ? '' : 'isOverdue')
    ..pc<TxDebtPayment>(30, _omitFieldNames ? '' : 'debtPayments', $pb.PbFieldType.PM, subBuilder: TxDebtPayment.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  TxInstallment clone() => TxInstallment()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  TxInstallment copyWith(void Function(TxInstallment) updates) => super.copyWith((message) => updates(message as TxInstallment)) as TxInstallment;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TxInstallment create() => TxInstallment._();
  TxInstallment createEmptyInstance() => create();
  static $pb.PbList<TxInstallment> createRepeated() => $pb.PbList<TxInstallment>();
  @$core.pragma('dart2js:noInline')
  static TxInstallment getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TxInstallment>(create);
  static TxInstallment? _defaultInstance;

  @$pb.TagNumber(4)
  $fixnum.Int64 get instId => $_getI64(0);
  @$pb.TagNumber(4)
  set instId($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(4)
  $core.bool hasInstId() => $_has(0);
  @$pb.TagNumber(4)
  void clearInstId() => clearField(4);

  @$pb.TagNumber(10)
  $fixnum.Int64 get dueTsMs => $_getI64(1);
  @$pb.TagNumber(10)
  set dueTsMs($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(10)
  $core.bool hasDueTsMs() => $_has(1);
  @$pb.TagNumber(10)
  void clearDueTsMs() => clearField(10);

  @$pb.TagNumber(11)
  $fixnum.Int64 get amount => $_getI64(2);
  @$pb.TagNumber(11)
  set amount($fixnum.Int64 v) { $_setInt64(2, v); }
  @$pb.TagNumber(11)
  $core.bool hasAmount() => $_has(2);
  @$pb.TagNumber(11)
  void clearAmount() => clearField(11);

  @$pb.TagNumber(12)
  $core.String get note => $_getSZ(3);
  @$pb.TagNumber(12)
  set note($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(12)
  $core.bool hasNote() => $_has(3);
  @$pb.TagNumber(12)
  void clearNote() => clearField(12);

  @$pb.TagNumber(21)
  $core.bool get isPaid => $_getBF(4);
  @$pb.TagNumber(21)
  set isPaid($core.bool v) { $_setBool(4, v); }
  @$pb.TagNumber(21)
  $core.bool hasIsPaid() => $_has(4);
  @$pb.TagNumber(21)
  void clearIsPaid() => clearField(21);

  @$pb.TagNumber(22)
  $core.bool get isOverdue => $_getBF(5);
  @$pb.TagNumber(22)
  set isOverdue($core.bool v) { $_setBool(5, v); }
  @$pb.TagNumber(22)
  $core.bool hasIsOverdue() => $_has(5);
  @$pb.TagNumber(22)
  void clearIsOverdue() => clearField(22);

  @$pb.TagNumber(30)
  $core.List<TxDebtPayment> get debtPayments => $_getList(6);
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
    final $result = create();
    if (payId != null) {
      $result.payId = payId;
    }
    if (tsMs != null) {
      $result.tsMs = tsMs;
    }
    if (method != null) {
      $result.method = method;
    }
    if (amount != null) {
      $result.amount = amount;
    }
    if (note != null) {
      $result.note = note;
    }
    if (overdueInterest != null) {
      $result.overdueInterest = overdueInterest;
    }
    if (paymentJson != null) {
      $result.paymentJson = paymentJson;
    }
    return $result;
  }
  TxDebtPayment._() : super();
  factory TxDebtPayment.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TxDebtPayment.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'TxDebtPayment', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aInt64(5, _omitFieldNames ? '' : 'payId')
    ..aInt64(10, _omitFieldNames ? '' : 'tsMs')
    ..e<TxDebtPaymentMethod>(11, _omitFieldNames ? '' : 'method', $pb.PbFieldType.OE, defaultOrMaker: TxDebtPaymentMethod.TX_DEBT_PAYMENT_METHOD_UNSPECIFIED, valueOf: TxDebtPaymentMethod.valueOf, enumValues: TxDebtPaymentMethod.values)
    ..aInt64(12, _omitFieldNames ? '' : 'amount')
    ..aOS(13, _omitFieldNames ? '' : 'note')
    ..aInt64(14, _omitFieldNames ? '' : 'overdueInterest')
    ..aOS(100, _omitFieldNames ? '' : 'paymentJson')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  TxDebtPayment clone() => TxDebtPayment()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  TxDebtPayment copyWith(void Function(TxDebtPayment) updates) => super.copyWith((message) => updates(message as TxDebtPayment)) as TxDebtPayment;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TxDebtPayment create() => TxDebtPayment._();
  TxDebtPayment createEmptyInstance() => create();
  static $pb.PbList<TxDebtPayment> createRepeated() => $pb.PbList<TxDebtPayment>();
  @$core.pragma('dart2js:noInline')
  static TxDebtPayment getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TxDebtPayment>(create);
  static TxDebtPayment? _defaultInstance;

  @$pb.TagNumber(5)
  $fixnum.Int64 get payId => $_getI64(0);
  @$pb.TagNumber(5)
  set payId($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(5)
  $core.bool hasPayId() => $_has(0);
  @$pb.TagNumber(5)
  void clearPayId() => clearField(5);

  @$pb.TagNumber(10)
  $fixnum.Int64 get tsMs => $_getI64(1);
  @$pb.TagNumber(10)
  set tsMs($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(10)
  $core.bool hasTsMs() => $_has(1);
  @$pb.TagNumber(10)
  void clearTsMs() => clearField(10);

  @$pb.TagNumber(11)
  TxDebtPaymentMethod get method => $_getN(2);
  @$pb.TagNumber(11)
  set method(TxDebtPaymentMethod v) { setField(11, v); }
  @$pb.TagNumber(11)
  $core.bool hasMethod() => $_has(2);
  @$pb.TagNumber(11)
  void clearMethod() => clearField(11);

  @$pb.TagNumber(12)
  $fixnum.Int64 get amount => $_getI64(3);
  @$pb.TagNumber(12)
  set amount($fixnum.Int64 v) { $_setInt64(3, v); }
  @$pb.TagNumber(12)
  $core.bool hasAmount() => $_has(3);
  @$pb.TagNumber(12)
  void clearAmount() => clearField(12);

  @$pb.TagNumber(13)
  $core.String get note => $_getSZ(4);
  @$pb.TagNumber(13)
  set note($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(13)
  $core.bool hasNote() => $_has(4);
  @$pb.TagNumber(13)
  void clearNote() => clearField(13);

  @$pb.TagNumber(14)
  $fixnum.Int64 get overdueInterest => $_getI64(5);
  @$pb.TagNumber(14)
  set overdueInterest($fixnum.Int64 v) { $_setInt64(5, v); }
  @$pb.TagNumber(14)
  $core.bool hasOverdueInterest() => $_has(5);
  @$pb.TagNumber(14)
  void clearOverdueInterest() => clearField(14);

  @$pb.TagNumber(100)
  $core.String get paymentJson => $_getSZ(6);
  @$pb.TagNumber(100)
  set paymentJson($core.String v) { $_setString(6, v); }
  @$pb.TagNumber(100)
  $core.bool hasPaymentJson() => $_has(6);
  @$pb.TagNumber(100)
  void clearPaymentJson() => clearField(100);
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
    final $result = create();
    if (accId != null) {
      $result.accId = accId;
    }
    if (accCode != null) {
      $result.accCode = accCode;
    }
    if (tsMs != null) {
      $result.tsMs = tsMs;
    }
    if (side != null) {
      $result.side = side;
    }
    if (amount != null) {
      $result.amount = amount;
    }
    if (note != null) {
      $result.note = note;
    }
    if (isTxGenerated != null) {
      $result.isTxGenerated = isTxGenerated;
    }
    return $result;
  }
  TxAcc._() : super();
  factory TxAcc.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TxAcc.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'TxAcc', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aInt64(3, _omitFieldNames ? '' : 'accId')
    ..aOS(10, _omitFieldNames ? '' : 'accCode')
    ..aInt64(11, _omitFieldNames ? '' : 'tsMs')
    ..e<TxAccSide>(12, _omitFieldNames ? '' : 'side', $pb.PbFieldType.OE, defaultOrMaker: TxAccSide.TX_ACC_SIDE_UNSPECIFIED, valueOf: TxAccSide.valueOf, enumValues: TxAccSide.values)
    ..aInt64(13, _omitFieldNames ? '' : 'amount')
    ..aOS(14, _omitFieldNames ? '' : 'note')
    ..aOB(20, _omitFieldNames ? '' : 'isTxGenerated')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  TxAcc clone() => TxAcc()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  TxAcc copyWith(void Function(TxAcc) updates) => super.copyWith((message) => updates(message as TxAcc)) as TxAcc;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TxAcc create() => TxAcc._();
  TxAcc createEmptyInstance() => create();
  static $pb.PbList<TxAcc> createRepeated() => $pb.PbList<TxAcc>();
  @$core.pragma('dart2js:noInline')
  static TxAcc getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TxAcc>(create);
  static TxAcc? _defaultInstance;

  @$pb.TagNumber(3)
  $fixnum.Int64 get accId => $_getI64(0);
  @$pb.TagNumber(3)
  set accId($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(3)
  $core.bool hasAccId() => $_has(0);
  @$pb.TagNumber(3)
  void clearAccId() => clearField(3);

  @$pb.TagNumber(10)
  $core.String get accCode => $_getSZ(1);
  @$pb.TagNumber(10)
  set accCode($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(10)
  $core.bool hasAccCode() => $_has(1);
  @$pb.TagNumber(10)
  void clearAccCode() => clearField(10);

  @$pb.TagNumber(11)
  $fixnum.Int64 get tsMs => $_getI64(2);
  @$pb.TagNumber(11)
  set tsMs($fixnum.Int64 v) { $_setInt64(2, v); }
  @$pb.TagNumber(11)
  $core.bool hasTsMs() => $_has(2);
  @$pb.TagNumber(11)
  void clearTsMs() => clearField(11);

  @$pb.TagNumber(12)
  TxAccSide get side => $_getN(3);
  @$pb.TagNumber(12)
  set side(TxAccSide v) { setField(12, v); }
  @$pb.TagNumber(12)
  $core.bool hasSide() => $_has(3);
  @$pb.TagNumber(12)
  void clearSide() => clearField(12);

  @$pb.TagNumber(13)
  $fixnum.Int64 get amount => $_getI64(4);
  @$pb.TagNumber(13)
  set amount($fixnum.Int64 v) { $_setInt64(4, v); }
  @$pb.TagNumber(13)
  $core.bool hasAmount() => $_has(4);
  @$pb.TagNumber(13)
  void clearAmount() => clearField(13);

  @$pb.TagNumber(14)
  $core.String get note => $_getSZ(5);
  @$pb.TagNumber(14)
  set note($core.String v) { $_setString(5, v); }
  @$pb.TagNumber(14)
  $core.bool hasNote() => $_has(5);
  @$pb.TagNumber(14)
  void clearNote() => clearField(14);

  @$pb.TagNumber(20)
  $core.bool get isTxGenerated => $_getBF(6);
  @$pb.TagNumber(20)
  set isTxGenerated($core.bool v) { $_setBool(6, v); }
  @$pb.TagNumber(20)
  $core.bool hasIsTxGenerated() => $_has(6);
  @$pb.TagNumber(20)
  void clearIsTxGenerated() => clearField(20);
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
    final $result = create();
    if (stockId != null) {
      $result.stockId = stockId;
    }
    if (productId != null) {
      $result.productId = productId;
    }
    if (tsMs != null) {
      $result.tsMs = tsMs;
    }
    if (objFromId != null) {
      $result.objFromId = objFromId;
    }
    if (objToId != null) {
      $result.objToId = objToId;
    }
    if (qty != null) {
      $result.qty = qty;
    }
    if (qtySigned != null) {
      $result.qtySigned = qtySigned;
    }
    if (direction != null) {
      $result.direction = direction;
    }
    if (note != null) {
      $result.note = note;
    }
    return $result;
  }
  TxStock._() : super();
  factory TxStock.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TxStock.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'TxStock', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aInt64(3, _omitFieldNames ? '' : 'stockId')
    ..aInt64(10, _omitFieldNames ? '' : 'productId')
    ..aInt64(11, _omitFieldNames ? '' : 'tsMs')
    ..aInt64(20, _omitFieldNames ? '' : 'objFromId')
    ..aInt64(21, _omitFieldNames ? '' : 'objToId')
    ..a<$core.int>(30, _omitFieldNames ? '' : 'qty', $pb.PbFieldType.O3)
    ..a<$core.int>(31, _omitFieldNames ? '' : 'qtySigned', $pb.PbFieldType.O3)
    ..aOS(32, _omitFieldNames ? '' : 'direction')
    ..aOS(33, _omitFieldNames ? '' : 'note')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  TxStock clone() => TxStock()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  TxStock copyWith(void Function(TxStock) updates) => super.copyWith((message) => updates(message as TxStock)) as TxStock;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TxStock create() => TxStock._();
  TxStock createEmptyInstance() => create();
  static $pb.PbList<TxStock> createRepeated() => $pb.PbList<TxStock>();
  @$core.pragma('dart2js:noInline')
  static TxStock getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TxStock>(create);
  static TxStock? _defaultInstance;

  @$pb.TagNumber(3)
  $fixnum.Int64 get stockId => $_getI64(0);
  @$pb.TagNumber(3)
  set stockId($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(3)
  $core.bool hasStockId() => $_has(0);
  @$pb.TagNumber(3)
  void clearStockId() => clearField(3);

  @$pb.TagNumber(10)
  $fixnum.Int64 get productId => $_getI64(1);
  @$pb.TagNumber(10)
  set productId($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(10)
  $core.bool hasProductId() => $_has(1);
  @$pb.TagNumber(10)
  void clearProductId() => clearField(10);

  @$pb.TagNumber(11)
  $fixnum.Int64 get tsMs => $_getI64(2);
  @$pb.TagNumber(11)
  set tsMs($fixnum.Int64 v) { $_setInt64(2, v); }
  @$pb.TagNumber(11)
  $core.bool hasTsMs() => $_has(2);
  @$pb.TagNumber(11)
  void clearTsMs() => clearField(11);

  @$pb.TagNumber(20)
  $fixnum.Int64 get objFromId => $_getI64(3);
  @$pb.TagNumber(20)
  set objFromId($fixnum.Int64 v) { $_setInt64(3, v); }
  @$pb.TagNumber(20)
  $core.bool hasObjFromId() => $_has(3);
  @$pb.TagNumber(20)
  void clearObjFromId() => clearField(20);

  @$pb.TagNumber(21)
  $fixnum.Int64 get objToId => $_getI64(4);
  @$pb.TagNumber(21)
  set objToId($fixnum.Int64 v) { $_setInt64(4, v); }
  @$pb.TagNumber(21)
  $core.bool hasObjToId() => $_has(4);
  @$pb.TagNumber(21)
  void clearObjToId() => clearField(21);

  @$pb.TagNumber(30)
  $core.int get qty => $_getIZ(5);
  @$pb.TagNumber(30)
  set qty($core.int v) { $_setSignedInt32(5, v); }
  @$pb.TagNumber(30)
  $core.bool hasQty() => $_has(5);
  @$pb.TagNumber(30)
  void clearQty() => clearField(30);

  @$pb.TagNumber(31)
  $core.int get qtySigned => $_getIZ(6);
  @$pb.TagNumber(31)
  set qtySigned($core.int v) { $_setSignedInt32(6, v); }
  @$pb.TagNumber(31)
  $core.bool hasQtySigned() => $_has(6);
  @$pb.TagNumber(31)
  void clearQtySigned() => clearField(31);

  @$pb.TagNumber(32)
  $core.String get direction => $_getSZ(7);
  @$pb.TagNumber(32)
  set direction($core.String v) { $_setString(7, v); }
  @$pb.TagNumber(32)
  $core.bool hasDirection() => $_has(7);
  @$pb.TagNumber(32)
  void clearDirection() => clearField(32);

  @$pb.TagNumber(33)
  $core.String get note => $_getSZ(8);
  @$pb.TagNumber(33)
  set note($core.String v) { $_setString(8, v); }
  @$pb.TagNumber(33)
  $core.bool hasNote() => $_has(8);
  @$pb.TagNumber(33)
  void clearNote() => clearField(33);
}

class ReqTxGet extends $pb.GeneratedMessage {
  factory ReqTxGet({
    $fixnum.Int64? siteIid,
    $fixnum.Int64? txId,
  }) {
    final $result = create();
    if (siteIid != null) {
      $result.siteIid = siteIid;
    }
    if (txId != null) {
      $result.txId = txId;
    }
    return $result;
  }
  ReqTxGet._() : super();
  factory ReqTxGet.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ReqTxGet.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ReqTxGet', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'siteIid')
    ..aInt64(2, _omitFieldNames ? '' : 'txId')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ReqTxGet clone() => ReqTxGet()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ReqTxGet copyWith(void Function(ReqTxGet) updates) => super.copyWith((message) => updates(message as ReqTxGet)) as ReqTxGet;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReqTxGet create() => ReqTxGet._();
  ReqTxGet createEmptyInstance() => create();
  static $pb.PbList<ReqTxGet> createRepeated() => $pb.PbList<ReqTxGet>();
  @$core.pragma('dart2js:noInline')
  static ReqTxGet getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqTxGet>(create);
  static ReqTxGet? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get siteIid => $_getI64(0);
  @$pb.TagNumber(1)
  set siteIid($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasSiteIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearSiteIid() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get txId => $_getI64(1);
  @$pb.TagNumber(2)
  set txId($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasTxId() => $_has(1);
  @$pb.TagNumber(2)
  void clearTxId() => clearField(2);
}

class ResTxGet extends $pb.GeneratedMessage {
  factory ResTxGet({
    Tx? tx,
  }) {
    final $result = create();
    if (tx != null) {
      $result.tx = tx;
    }
    return $result;
  }
  ResTxGet._() : super();
  factory ResTxGet.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ResTxGet.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ResTxGet', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aOM<Tx>(1, _omitFieldNames ? '' : 'tx', subBuilder: Tx.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ResTxGet clone() => ResTxGet()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ResTxGet copyWith(void Function(ResTxGet) updates) => super.copyWith((message) => updates(message as ResTxGet)) as ResTxGet;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResTxGet create() => ResTxGet._();
  ResTxGet createEmptyInstance() => create();
  static $pb.PbList<ResTxGet> createRepeated() => $pb.PbList<ResTxGet>();
  @$core.pragma('dart2js:noInline')
  static ResTxGet getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResTxGet>(create);
  static ResTxGet? _defaultInstance;

  @$pb.TagNumber(1)
  Tx get tx => $_getN(0);
  @$pb.TagNumber(1)
  set tx(Tx v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasTx() => $_has(0);
  @$pb.TagNumber(1)
  void clearTx() => clearField(1);
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
    final $result = create();
    if (siteIid != null) {
      $result.siteIid = siteIid;
    }
    if (q != null) {
      $result.q = q;
    }
    if (afterTxId != null) {
      $result.afterTxId = afterTxId;
    }
    if (limit != null) {
      $result.limit = limit;
    }
    if (includeArchived != null) {
      $result.includeArchived = includeArchived;
    }
    if (type != null) {
      $result.type = type;
    }
    if (state != null) {
      $result.state = state;
    }
    if (subjectContactId != null) {
      $result.subjectContactId = subjectContactId;
    }
    if (timeFromMs != null) {
      $result.timeFromMs = timeFromMs;
    }
    if (timeToMs != null) {
      $result.timeToMs = timeToMs;
    }
    if (openOnly != null) {
      $result.openOnly = openOnly;
    }
    return $result;
  }
  ReqTxList._() : super();
  factory ReqTxList.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ReqTxList.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ReqTxList', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'siteIid')
    ..aOS(2, _omitFieldNames ? '' : 'q')
    ..aInt64(3, _omitFieldNames ? '' : 'afterTxId')
    ..a<$core.int>(4, _omitFieldNames ? '' : 'limit', $pb.PbFieldType.O3)
    ..aOB(5, _omitFieldNames ? '' : 'includeArchived')
    ..e<TxType>(6, _omitFieldNames ? '' : 'type', $pb.PbFieldType.OE, defaultOrMaker: TxType.TX_TYPE_UNSPECIFIED, valueOf: TxType.valueOf, enumValues: TxType.values)
    ..e<TxState>(7, _omitFieldNames ? '' : 'state', $pb.PbFieldType.OE, defaultOrMaker: TxState.TX_STATE_OK, valueOf: TxState.valueOf, enumValues: TxState.values)
    ..aInt64(10, _omitFieldNames ? '' : 'subjectContactId')
    ..aInt64(11, _omitFieldNames ? '' : 'timeFromMs')
    ..aInt64(12, _omitFieldNames ? '' : 'timeToMs')
    ..aOB(15, _omitFieldNames ? '' : 'openOnly')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ReqTxList clone() => ReqTxList()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ReqTxList copyWith(void Function(ReqTxList) updates) => super.copyWith((message) => updates(message as ReqTxList)) as ReqTxList;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReqTxList create() => ReqTxList._();
  ReqTxList createEmptyInstance() => create();
  static $pb.PbList<ReqTxList> createRepeated() => $pb.PbList<ReqTxList>();
  @$core.pragma('dart2js:noInline')
  static ReqTxList getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqTxList>(create);
  static ReqTxList? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get siteIid => $_getI64(0);
  @$pb.TagNumber(1)
  set siteIid($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasSiteIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearSiteIid() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get q => $_getSZ(1);
  @$pb.TagNumber(2)
  set q($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasQ() => $_has(1);
  @$pb.TagNumber(2)
  void clearQ() => clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get afterTxId => $_getI64(2);
  @$pb.TagNumber(3)
  set afterTxId($fixnum.Int64 v) { $_setInt64(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasAfterTxId() => $_has(2);
  @$pb.TagNumber(3)
  void clearAfterTxId() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get limit => $_getIZ(3);
  @$pb.TagNumber(4)
  set limit($core.int v) { $_setSignedInt32(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasLimit() => $_has(3);
  @$pb.TagNumber(4)
  void clearLimit() => clearField(4);

  @$pb.TagNumber(5)
  $core.bool get includeArchived => $_getBF(4);
  @$pb.TagNumber(5)
  set includeArchived($core.bool v) { $_setBool(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasIncludeArchived() => $_has(4);
  @$pb.TagNumber(5)
  void clearIncludeArchived() => clearField(5);

  @$pb.TagNumber(6)
  TxType get type => $_getN(5);
  @$pb.TagNumber(6)
  set type(TxType v) { setField(6, v); }
  @$pb.TagNumber(6)
  $core.bool hasType() => $_has(5);
  @$pb.TagNumber(6)
  void clearType() => clearField(6);

  @$pb.TagNumber(7)
  TxState get state => $_getN(6);
  @$pb.TagNumber(7)
  set state(TxState v) { setField(7, v); }
  @$pb.TagNumber(7)
  $core.bool hasState() => $_has(6);
  @$pb.TagNumber(7)
  void clearState() => clearField(7);

  @$pb.TagNumber(10)
  $fixnum.Int64 get subjectContactId => $_getI64(7);
  @$pb.TagNumber(10)
  set subjectContactId($fixnum.Int64 v) { $_setInt64(7, v); }
  @$pb.TagNumber(10)
  $core.bool hasSubjectContactId() => $_has(7);
  @$pb.TagNumber(10)
  void clearSubjectContactId() => clearField(10);

  @$pb.TagNumber(11)
  $fixnum.Int64 get timeFromMs => $_getI64(8);
  @$pb.TagNumber(11)
  set timeFromMs($fixnum.Int64 v) { $_setInt64(8, v); }
  @$pb.TagNumber(11)
  $core.bool hasTimeFromMs() => $_has(8);
  @$pb.TagNumber(11)
  void clearTimeFromMs() => clearField(11);

  @$pb.TagNumber(12)
  $fixnum.Int64 get timeToMs => $_getI64(9);
  @$pb.TagNumber(12)
  set timeToMs($fixnum.Int64 v) { $_setInt64(9, v); }
  @$pb.TagNumber(12)
  $core.bool hasTimeToMs() => $_has(9);
  @$pb.TagNumber(12)
  void clearTimeToMs() => clearField(12);

  @$pb.TagNumber(15)
  $core.bool get openOnly => $_getBF(10);
  @$pb.TagNumber(15)
  set openOnly($core.bool v) { $_setBool(10, v); }
  @$pb.TagNumber(15)
  $core.bool hasOpenOnly() => $_has(10);
  @$pb.TagNumber(15)
  void clearOpenOnly() => clearField(15);
}

class ResTxList extends $pb.GeneratedMessage {
  factory ResTxList({
    $core.Iterable<Tx>? txs,
  }) {
    final $result = create();
    if (txs != null) {
      $result.txs.addAll(txs);
    }
    return $result;
  }
  ResTxList._() : super();
  factory ResTxList.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ResTxList.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ResTxList', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..pc<Tx>(1, _omitFieldNames ? '' : 'txs', $pb.PbFieldType.PM, subBuilder: Tx.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ResTxList clone() => ResTxList()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ResTxList copyWith(void Function(ResTxList) updates) => super.copyWith((message) => updates(message as ResTxList)) as ResTxList;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResTxList create() => ResTxList._();
  ResTxList createEmptyInstance() => create();
  static $pb.PbList<ResTxList> createRepeated() => $pb.PbList<ResTxList>();
  @$core.pragma('dart2js:noInline')
  static ResTxList getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResTxList>(create);
  static ResTxList? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<Tx> get txs => $_getList(0);
}

class ReqTxPut extends $pb.GeneratedMessage {
  factory ReqTxPut({
    Tx? tx,
  }) {
    final $result = create();
    if (tx != null) {
      $result.tx = tx;
    }
    return $result;
  }
  ReqTxPut._() : super();
  factory ReqTxPut.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ReqTxPut.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ReqTxPut', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aOM<Tx>(1, _omitFieldNames ? '' : 'tx', subBuilder: Tx.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ReqTxPut clone() => ReqTxPut()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ReqTxPut copyWith(void Function(ReqTxPut) updates) => super.copyWith((message) => updates(message as ReqTxPut)) as ReqTxPut;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReqTxPut create() => ReqTxPut._();
  ReqTxPut createEmptyInstance() => create();
  static $pb.PbList<ReqTxPut> createRepeated() => $pb.PbList<ReqTxPut>();
  @$core.pragma('dart2js:noInline')
  static ReqTxPut getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqTxPut>(create);
  static ReqTxPut? _defaultInstance;

  @$pb.TagNumber(1)
  Tx get tx => $_getN(0);
  @$pb.TagNumber(1)
  set tx(Tx v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasTx() => $_has(0);
  @$pb.TagNumber(1)
  void clearTx() => clearField(1);
  @$pb.TagNumber(1)
  Tx ensureTx() => $_ensure(0);
}

class ResTxPut extends $pb.GeneratedMessage {
  factory ResTxPut({
    Tx? tx,
  }) {
    final $result = create();
    if (tx != null) {
      $result.tx = tx;
    }
    return $result;
  }
  ResTxPut._() : super();
  factory ResTxPut.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ResTxPut.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ResTxPut', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aOM<Tx>(1, _omitFieldNames ? '' : 'tx', subBuilder: Tx.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ResTxPut clone() => ResTxPut()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ResTxPut copyWith(void Function(ResTxPut) updates) => super.copyWith((message) => updates(message as ResTxPut)) as ResTxPut;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResTxPut create() => ResTxPut._();
  ResTxPut createEmptyInstance() => create();
  static $pb.PbList<ResTxPut> createRepeated() => $pb.PbList<ResTxPut>();
  @$core.pragma('dart2js:noInline')
  static ResTxPut getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResTxPut>(create);
  static ResTxPut? _defaultInstance;

  @$pb.TagNumber(1)
  Tx get tx => $_getN(0);
  @$pb.TagNumber(1)
  set tx(Tx v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasTx() => $_has(0);
  @$pb.TagNumber(1)
  void clearTx() => clearField(1);
  @$pb.TagNumber(1)
  Tx ensureTx() => $_ensure(0);
}

class ReqTxPreview extends $pb.GeneratedMessage {
  factory ReqTxPreview({
    Tx? tx,
  }) {
    final $result = create();
    if (tx != null) {
      $result.tx = tx;
    }
    return $result;
  }
  ReqTxPreview._() : super();
  factory ReqTxPreview.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ReqTxPreview.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ReqTxPreview', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aOM<Tx>(1, _omitFieldNames ? '' : 'tx', subBuilder: Tx.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ReqTxPreview clone() => ReqTxPreview()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ReqTxPreview copyWith(void Function(ReqTxPreview) updates) => super.copyWith((message) => updates(message as ReqTxPreview)) as ReqTxPreview;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReqTxPreview create() => ReqTxPreview._();
  ReqTxPreview createEmptyInstance() => create();
  static $pb.PbList<ReqTxPreview> createRepeated() => $pb.PbList<ReqTxPreview>();
  @$core.pragma('dart2js:noInline')
  static ReqTxPreview getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqTxPreview>(create);
  static ReqTxPreview? _defaultInstance;

  @$pb.TagNumber(1)
  Tx get tx => $_getN(0);
  @$pb.TagNumber(1)
  set tx(Tx v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasTx() => $_has(0);
  @$pb.TagNumber(1)
  void clearTx() => clearField(1);
  @$pb.TagNumber(1)
  Tx ensureTx() => $_ensure(0);
}

class ResTxPreview extends $pb.GeneratedMessage {
  factory ResTxPreview({
    Tx? tx,
    $core.Map<$core.String, $core.String>? coaName,
  }) {
    final $result = create();
    if (tx != null) {
      $result.tx = tx;
    }
    if (coaName != null) {
      $result.coaName.addAll(coaName);
    }
    return $result;
  }
  ResTxPreview._() : super();
  factory ResTxPreview.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ResTxPreview.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ResTxPreview', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aOM<Tx>(1, _omitFieldNames ? '' : 'tx', subBuilder: Tx.create)
    ..m<$core.String, $core.String>(2, _omitFieldNames ? '' : 'coaName', entryClassName: 'ResTxPreview.CoaNameEntry', keyFieldType: $pb.PbFieldType.OS, valueFieldType: $pb.PbFieldType.OS, packageName: const $pb.PackageName('c35'))
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ResTxPreview clone() => ResTxPreview()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ResTxPreview copyWith(void Function(ResTxPreview) updates) => super.copyWith((message) => updates(message as ResTxPreview)) as ResTxPreview;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResTxPreview create() => ResTxPreview._();
  ResTxPreview createEmptyInstance() => create();
  static $pb.PbList<ResTxPreview> createRepeated() => $pb.PbList<ResTxPreview>();
  @$core.pragma('dart2js:noInline')
  static ResTxPreview getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResTxPreview>(create);
  static ResTxPreview? _defaultInstance;

  @$pb.TagNumber(1)
  Tx get tx => $_getN(0);
  @$pb.TagNumber(1)
  set tx(Tx v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasTx() => $_has(0);
  @$pb.TagNumber(1)
  void clearTx() => clearField(1);
  @$pb.TagNumber(1)
  Tx ensureTx() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.Map<$core.String, $core.String> get coaName => $_getMap(1);
}

class ReqTxDebtPay extends $pb.GeneratedMessage {
  factory ReqTxDebtPay({
    $fixnum.Int64? siteIid,
    $fixnum.Int64? txId,
    TxDebtPayment? payment,
  }) {
    final $result = create();
    if (siteIid != null) {
      $result.siteIid = siteIid;
    }
    if (txId != null) {
      $result.txId = txId;
    }
    if (payment != null) {
      $result.payment = payment;
    }
    return $result;
  }
  ReqTxDebtPay._() : super();
  factory ReqTxDebtPay.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ReqTxDebtPay.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ReqTxDebtPay', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'siteIid')
    ..aInt64(2, _omitFieldNames ? '' : 'txId')
    ..aOM<TxDebtPayment>(3, _omitFieldNames ? '' : 'payment', subBuilder: TxDebtPayment.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ReqTxDebtPay clone() => ReqTxDebtPay()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ReqTxDebtPay copyWith(void Function(ReqTxDebtPay) updates) => super.copyWith((message) => updates(message as ReqTxDebtPay)) as ReqTxDebtPay;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReqTxDebtPay create() => ReqTxDebtPay._();
  ReqTxDebtPay createEmptyInstance() => create();
  static $pb.PbList<ReqTxDebtPay> createRepeated() => $pb.PbList<ReqTxDebtPay>();
  @$core.pragma('dart2js:noInline')
  static ReqTxDebtPay getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqTxDebtPay>(create);
  static ReqTxDebtPay? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get siteIid => $_getI64(0);
  @$pb.TagNumber(1)
  set siteIid($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasSiteIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearSiteIid() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get txId => $_getI64(1);
  @$pb.TagNumber(2)
  set txId($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasTxId() => $_has(1);
  @$pb.TagNumber(2)
  void clearTxId() => clearField(2);

  @$pb.TagNumber(3)
  TxDebtPayment get payment => $_getN(2);
  @$pb.TagNumber(3)
  set payment(TxDebtPayment v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasPayment() => $_has(2);
  @$pb.TagNumber(3)
  void clearPayment() => clearField(3);
  @$pb.TagNumber(3)
  TxDebtPayment ensurePayment() => $_ensure(2);
}

class ResTxDebtPay extends $pb.GeneratedMessage {
  factory ResTxDebtPay({
    Tx? tx,
  }) {
    final $result = create();
    if (tx != null) {
      $result.tx = tx;
    }
    return $result;
  }
  ResTxDebtPay._() : super();
  factory ResTxDebtPay.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ResTxDebtPay.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ResTxDebtPay', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aOM<Tx>(1, _omitFieldNames ? '' : 'tx', subBuilder: Tx.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ResTxDebtPay clone() => ResTxDebtPay()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ResTxDebtPay copyWith(void Function(ResTxDebtPay) updates) => super.copyWith((message) => updates(message as ResTxDebtPay)) as ResTxDebtPay;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResTxDebtPay create() => ResTxDebtPay._();
  ResTxDebtPay createEmptyInstance() => create();
  static $pb.PbList<ResTxDebtPay> createRepeated() => $pb.PbList<ResTxDebtPay>();
  @$core.pragma('dart2js:noInline')
  static ResTxDebtPay getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResTxDebtPay>(create);
  static ResTxDebtPay? _defaultInstance;

  @$pb.TagNumber(1)
  Tx get tx => $_getN(0);
  @$pb.TagNumber(1)
  set tx(Tx v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasTx() => $_has(0);
  @$pb.TagNumber(1)
  void clearTx() => clearField(1);
  @$pb.TagNumber(1)
  Tx ensureTx() => $_ensure(0);
}

/// Guest checkout (public site — no staff grant)
class ReqSiteGuestOrderPut extends $pb.GeneratedMessage {
  factory ReqSiteGuestOrderPut({
    $fixnum.Int64? siteIid,
    Tx? tx,
  }) {
    final $result = create();
    if (siteIid != null) {
      $result.siteIid = siteIid;
    }
    if (tx != null) {
      $result.tx = tx;
    }
    return $result;
  }
  ReqSiteGuestOrderPut._() : super();
  factory ReqSiteGuestOrderPut.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ReqSiteGuestOrderPut.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ReqSiteGuestOrderPut', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'siteIid')
    ..aOM<Tx>(2, _omitFieldNames ? '' : 'tx', subBuilder: Tx.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ReqSiteGuestOrderPut clone() => ReqSiteGuestOrderPut()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ReqSiteGuestOrderPut copyWith(void Function(ReqSiteGuestOrderPut) updates) => super.copyWith((message) => updates(message as ReqSiteGuestOrderPut)) as ReqSiteGuestOrderPut;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReqSiteGuestOrderPut create() => ReqSiteGuestOrderPut._();
  ReqSiteGuestOrderPut createEmptyInstance() => create();
  static $pb.PbList<ReqSiteGuestOrderPut> createRepeated() => $pb.PbList<ReqSiteGuestOrderPut>();
  @$core.pragma('dart2js:noInline')
  static ReqSiteGuestOrderPut getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqSiteGuestOrderPut>(create);
  static ReqSiteGuestOrderPut? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get siteIid => $_getI64(0);
  @$pb.TagNumber(1)
  set siteIid($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasSiteIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearSiteIid() => clearField(1);

  @$pb.TagNumber(2)
  Tx get tx => $_getN(1);
  @$pb.TagNumber(2)
  set tx(Tx v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasTx() => $_has(1);
  @$pb.TagNumber(2)
  void clearTx() => clearField(2);
  @$pb.TagNumber(2)
  Tx ensureTx() => $_ensure(1);
}

class ResSiteGuestOrderPut extends $pb.GeneratedMessage {
  factory ResSiteGuestOrderPut({
    Tx? tx,
  }) {
    final $result = create();
    if (tx != null) {
      $result.tx = tx;
    }
    return $result;
  }
  ResSiteGuestOrderPut._() : super();
  factory ResSiteGuestOrderPut.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ResSiteGuestOrderPut.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ResSiteGuestOrderPut', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aOM<Tx>(1, _omitFieldNames ? '' : 'tx', subBuilder: Tx.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ResSiteGuestOrderPut clone() => ResSiteGuestOrderPut()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ResSiteGuestOrderPut copyWith(void Function(ResSiteGuestOrderPut) updates) => super.copyWith((message) => updates(message as ResSiteGuestOrderPut)) as ResSiteGuestOrderPut;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResSiteGuestOrderPut create() => ResSiteGuestOrderPut._();
  ResSiteGuestOrderPut createEmptyInstance() => create();
  static $pb.PbList<ResSiteGuestOrderPut> createRepeated() => $pb.PbList<ResSiteGuestOrderPut>();
  @$core.pragma('dart2js:noInline')
  static ResSiteGuestOrderPut getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResSiteGuestOrderPut>(create);
  static ResSiteGuestOrderPut? _defaultInstance;

  @$pb.TagNumber(1)
  Tx get tx => $_getN(0);
  @$pb.TagNumber(1)
  set tx(Tx v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasTx() => $_has(0);
  @$pb.TagNumber(1)
  void clearTx() => clearField(1);
  @$pb.TagNumber(1)
  Tx ensureTx() => $_ensure(0);
}

class ReqSiteGuestOrderGet extends $pb.GeneratedMessage {
  factory ReqSiteGuestOrderGet({
    $fixnum.Int64? siteIid,
    $fixnum.Int64? txId,
  }) {
    final $result = create();
    if (siteIid != null) {
      $result.siteIid = siteIid;
    }
    if (txId != null) {
      $result.txId = txId;
    }
    return $result;
  }
  ReqSiteGuestOrderGet._() : super();
  factory ReqSiteGuestOrderGet.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ReqSiteGuestOrderGet.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ReqSiteGuestOrderGet', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'siteIid')
    ..aInt64(2, _omitFieldNames ? '' : 'txId')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ReqSiteGuestOrderGet clone() => ReqSiteGuestOrderGet()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ReqSiteGuestOrderGet copyWith(void Function(ReqSiteGuestOrderGet) updates) => super.copyWith((message) => updates(message as ReqSiteGuestOrderGet)) as ReqSiteGuestOrderGet;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReqSiteGuestOrderGet create() => ReqSiteGuestOrderGet._();
  ReqSiteGuestOrderGet createEmptyInstance() => create();
  static $pb.PbList<ReqSiteGuestOrderGet> createRepeated() => $pb.PbList<ReqSiteGuestOrderGet>();
  @$core.pragma('dart2js:noInline')
  static ReqSiteGuestOrderGet getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReqSiteGuestOrderGet>(create);
  static ReqSiteGuestOrderGet? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get siteIid => $_getI64(0);
  @$pb.TagNumber(1)
  set siteIid($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasSiteIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearSiteIid() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get txId => $_getI64(1);
  @$pb.TagNumber(2)
  set txId($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasTxId() => $_has(1);
  @$pb.TagNumber(2)
  void clearTxId() => clearField(2);
}

class ResSiteGuestOrderGet extends $pb.GeneratedMessage {
  factory ResSiteGuestOrderGet({
    Tx? tx,
  }) {
    final $result = create();
    if (tx != null) {
      $result.tx = tx;
    }
    return $result;
  }
  ResSiteGuestOrderGet._() : super();
  factory ResSiteGuestOrderGet.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ResSiteGuestOrderGet.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ResSiteGuestOrderGet', package: const $pb.PackageName(_omitMessageNames ? '' : 'c35'), createEmptyInstance: create)
    ..aOM<Tx>(1, _omitFieldNames ? '' : 'tx', subBuilder: Tx.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ResSiteGuestOrderGet clone() => ResSiteGuestOrderGet()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ResSiteGuestOrderGet copyWith(void Function(ResSiteGuestOrderGet) updates) => super.copyWith((message) => updates(message as ResSiteGuestOrderGet)) as ResSiteGuestOrderGet;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResSiteGuestOrderGet create() => ResSiteGuestOrderGet._();
  ResSiteGuestOrderGet createEmptyInstance() => create();
  static $pb.PbList<ResSiteGuestOrderGet> createRepeated() => $pb.PbList<ResSiteGuestOrderGet>();
  @$core.pragma('dart2js:noInline')
  static ResSiteGuestOrderGet getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResSiteGuestOrderGet>(create);
  static ResSiteGuestOrderGet? _defaultInstance;

  @$pb.TagNumber(1)
  Tx get tx => $_getN(0);
  @$pb.TagNumber(1)
  set tx(Tx v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasTx() => $_has(0);
  @$pb.TagNumber(1)
  void clearTx() => clearField(1);
  @$pb.TagNumber(1)
  Tx ensureTx() => $_ensure(0);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
