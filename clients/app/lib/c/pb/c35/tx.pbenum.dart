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

import 'package:protobuf/protobuf.dart' as $pb;

class TxInputSource extends $pb.ProtobufEnum {
  static const TxInputSource TX_INPUT_SOURCE_UNSPECIFIED = TxInputSource._(0, _omitEnumNames ? '' : 'TX_INPUT_SOURCE_UNSPECIFIED');
  static const TxInputSource TX_INPUT_SOURCE_MANUAL = TxInputSource._(1, _omitEnumNames ? '' : 'TX_INPUT_SOURCE_MANUAL');
  static const TxInputSource TX_INPUT_SOURCE_WEB = TxInputSource._(2, _omitEnumNames ? '' : 'TX_INPUT_SOURCE_WEB');
  static const TxInputSource TX_INPUT_SOURCE_AI = TxInputSource._(3, _omitEnumNames ? '' : 'TX_INPUT_SOURCE_AI');
  static const TxInputSource TX_INPUT_SOURCE_API = TxInputSource._(4, _omitEnumNames ? '' : 'TX_INPUT_SOURCE_API');

  static const $core.List<TxInputSource> values = <TxInputSource> [
    TX_INPUT_SOURCE_UNSPECIFIED,
    TX_INPUT_SOURCE_MANUAL,
    TX_INPUT_SOURCE_WEB,
    TX_INPUT_SOURCE_AI,
    TX_INPUT_SOURCE_API,
  ];

  static final $core.Map<$core.int, TxInputSource> _byValue = $pb.ProtobufEnum.initByValue(values);
  static TxInputSource? valueOf($core.int value) => _byValue[value];

  const TxInputSource._($core.int v, $core.String n) : super(v, n);
}

class TxType extends $pb.ProtobufEnum {
  static const TxType TX_TYPE_UNSPECIFIED = TxType._(0, _omitEnumNames ? '' : 'TX_TYPE_UNSPECIFIED');
  static const TxType TX_TYPE_SALE = TxType._(1, _omitEnumNames ? '' : 'TX_TYPE_SALE');
  static const TxType TX_TYPE_PURCHASE = TxType._(2, _omitEnumNames ? '' : 'TX_TYPE_PURCHASE');
  static const TxType TX_TYPE_TRANSFER = TxType._(3, _omitEnumNames ? '' : 'TX_TYPE_TRANSFER');
  static const TxType TX_TYPE_ADJUSTMENT = TxType._(4, _omitEnumNames ? '' : 'TX_TYPE_ADJUSTMENT');
  static const TxType TX_TYPE_RETURN_SALE = TxType._(5, _omitEnumNames ? '' : 'TX_TYPE_RETURN_SALE');
  static const TxType TX_TYPE_RETURN_PURCHASE = TxType._(6, _omitEnumNames ? '' : 'TX_TYPE_RETURN_PURCHASE');
  static const TxType TX_TYPE_RESERVATION = TxType._(7, _omitEnumNames ? '' : 'TX_TYPE_RESERVATION');
  static const TxType TX_TYPE_SHIP = TxType._(8, _omitEnumNames ? '' : 'TX_TYPE_SHIP');
  static const TxType TX_TYPE_PAYMENT = TxType._(9, _omitEnumNames ? '' : 'TX_TYPE_PAYMENT');
  static const TxType TX_TYPE_RECEIPT = TxType._(10, _omitEnumNames ? '' : 'TX_TYPE_RECEIPT');
  static const TxType TX_TYPE_DEBT_PAYABLE = TxType._(11, _omitEnumNames ? '' : 'TX_TYPE_DEBT_PAYABLE');
  static const TxType TX_TYPE_DEBT_RECEIVABLE = TxType._(12, _omitEnumNames ? '' : 'TX_TYPE_DEBT_RECEIVABLE');
  static const TxType TX_TYPE_INVENTORY = TxType._(13, _omitEnumNames ? '' : 'TX_TYPE_INVENTORY');

  static const $core.List<TxType> values = <TxType> [
    TX_TYPE_UNSPECIFIED,
    TX_TYPE_SALE,
    TX_TYPE_PURCHASE,
    TX_TYPE_TRANSFER,
    TX_TYPE_ADJUSTMENT,
    TX_TYPE_RETURN_SALE,
    TX_TYPE_RETURN_PURCHASE,
    TX_TYPE_RESERVATION,
    TX_TYPE_SHIP,
    TX_TYPE_PAYMENT,
    TX_TYPE_RECEIPT,
    TX_TYPE_DEBT_PAYABLE,
    TX_TYPE_DEBT_RECEIVABLE,
    TX_TYPE_INVENTORY,
  ];

  static final $core.Map<$core.int, TxType> _byValue = $pb.ProtobufEnum.initByValue(values);
  static TxType? valueOf($core.int value) => _byValue[value];

  const TxType._($core.int v, $core.String n) : super(v, n);
}

class TxState extends $pb.ProtobufEnum {
  static const TxState TX_STATE_OK = TxState._(0, _omitEnumNames ? '' : 'TX_STATE_OK');
  static const TxState TX_STATE_DRAFT = TxState._(1, _omitEnumNames ? '' : 'TX_STATE_DRAFT');
  static const TxState TX_STATE_PENDING = TxState._(2, _omitEnumNames ? '' : 'TX_STATE_PENDING');
  static const TxState TX_STATE_WAITING_PAYMENT = TxState._(3, _omitEnumNames ? '' : 'TX_STATE_WAITING_PAYMENT');
  static const TxState TX_STATE_CANCELLED = TxState._(99, _omitEnumNames ? '' : 'TX_STATE_CANCELLED');

  static const $core.List<TxState> values = <TxState> [
    TX_STATE_OK,
    TX_STATE_DRAFT,
    TX_STATE_PENDING,
    TX_STATE_WAITING_PAYMENT,
    TX_STATE_CANCELLED,
  ];

  static final $core.Map<$core.int, TxState> _byValue = $pb.ProtobufEnum.initByValue(values);
  static TxState? valueOf($core.int value) => _byValue[value];

  const TxState._($core.int v, $core.String n) : super(v, n);
}

class TxInputMode extends $pb.ProtobufEnum {
  static const TxInputMode TX_INPUT_MODE_NORMAL = TxInputMode._(0, _omitEnumNames ? '' : 'TX_INPUT_MODE_NORMAL');
  static const TxInputMode TX_INPUT_MODE_ACCOUNTING = TxInputMode._(1, _omitEnumNames ? '' : 'TX_INPUT_MODE_ACCOUNTING');
  static const TxInputMode TX_INPUT_MODE_SELL = TxInputMode._(2, _omitEnumNames ? '' : 'TX_INPUT_MODE_SELL');
  static const TxInputMode TX_INPUT_MODE_PURCHASE = TxInputMode._(3, _omitEnumNames ? '' : 'TX_INPUT_MODE_PURCHASE');

  static const $core.List<TxInputMode> values = <TxInputMode> [
    TX_INPUT_MODE_NORMAL,
    TX_INPUT_MODE_ACCOUNTING,
    TX_INPUT_MODE_SELL,
    TX_INPUT_MODE_PURCHASE,
  ];

  static final $core.Map<$core.int, TxInputMode> _byValue = $pb.ProtobufEnum.initByValue(values);
  static TxInputMode? valueOf($core.int value) => _byValue[value];

  const TxInputMode._($core.int v, $core.String n) : super(v, n);
}

class TxPaymentMethod extends $pb.ProtobufEnum {
  static const TxPaymentMethod TX_PAYMENT_METHOD_UNSPECIFIED = TxPaymentMethod._(0, _omitEnumNames ? '' : 'TX_PAYMENT_METHOD_UNSPECIFIED');
  static const TxPaymentMethod TX_PAYMENT_METHOD_CASH = TxPaymentMethod._(1, _omitEnumNames ? '' : 'TX_PAYMENT_METHOD_CASH');
  static const TxPaymentMethod TX_PAYMENT_METHOD_CARD = TxPaymentMethod._(2, _omitEnumNames ? '' : 'TX_PAYMENT_METHOD_CARD');
  static const TxPaymentMethod TX_PAYMENT_METHOD_TRANSFER = TxPaymentMethod._(3, _omitEnumNames ? '' : 'TX_PAYMENT_METHOD_TRANSFER');
  static const TxPaymentMethod TX_PAYMENT_METHOD_QRIS = TxPaymentMethod._(4, _omitEnumNames ? '' : 'TX_PAYMENT_METHOD_QRIS');
  static const TxPaymentMethod TX_PAYMENT_METHOD_DEBT = TxPaymentMethod._(5, _omitEnumNames ? '' : 'TX_PAYMENT_METHOD_DEBT');
  static const TxPaymentMethod TX_PAYMENT_METHOD_WALLET = TxPaymentMethod._(6, _omitEnumNames ? '' : 'TX_PAYMENT_METHOD_WALLET');

  static const $core.List<TxPaymentMethod> values = <TxPaymentMethod> [
    TX_PAYMENT_METHOD_UNSPECIFIED,
    TX_PAYMENT_METHOD_CASH,
    TX_PAYMENT_METHOD_CARD,
    TX_PAYMENT_METHOD_TRANSFER,
    TX_PAYMENT_METHOD_QRIS,
    TX_PAYMENT_METHOD_DEBT,
    TX_PAYMENT_METHOD_WALLET,
  ];

  static final $core.Map<$core.int, TxPaymentMethod> _byValue = $pb.ProtobufEnum.initByValue(values);
  static TxPaymentMethod? valueOf($core.int value) => _byValue[value];

  const TxPaymentMethod._($core.int v, $core.String n) : super(v, n);
}

class TxDebtPaymentMethod extends $pb.ProtobufEnum {
  static const TxDebtPaymentMethod TX_DEBT_PAYMENT_METHOD_UNSPECIFIED = TxDebtPaymentMethod._(0, _omitEnumNames ? '' : 'TX_DEBT_PAYMENT_METHOD_UNSPECIFIED');
  static const TxDebtPaymentMethod TX_DEBT_PAYMENT_METHOD_CASH = TxDebtPaymentMethod._(1, _omitEnumNames ? '' : 'TX_DEBT_PAYMENT_METHOD_CASH');
  static const TxDebtPaymentMethod TX_DEBT_PAYMENT_METHOD_CARD = TxDebtPaymentMethod._(2, _omitEnumNames ? '' : 'TX_DEBT_PAYMENT_METHOD_CARD');
  static const TxDebtPaymentMethod TX_DEBT_PAYMENT_METHOD_TRANSFER = TxDebtPaymentMethod._(3, _omitEnumNames ? '' : 'TX_DEBT_PAYMENT_METHOD_TRANSFER');
  static const TxDebtPaymentMethod TX_DEBT_PAYMENT_METHOD_QRIS = TxDebtPaymentMethod._(4, _omitEnumNames ? '' : 'TX_DEBT_PAYMENT_METHOD_QRIS');
  static const TxDebtPaymentMethod TX_DEBT_PAYMENT_METHOD_WALLET = TxDebtPaymentMethod._(5, _omitEnumNames ? '' : 'TX_DEBT_PAYMENT_METHOD_WALLET');

  static const $core.List<TxDebtPaymentMethod> values = <TxDebtPaymentMethod> [
    TX_DEBT_PAYMENT_METHOD_UNSPECIFIED,
    TX_DEBT_PAYMENT_METHOD_CASH,
    TX_DEBT_PAYMENT_METHOD_CARD,
    TX_DEBT_PAYMENT_METHOD_TRANSFER,
    TX_DEBT_PAYMENT_METHOD_QRIS,
    TX_DEBT_PAYMENT_METHOD_WALLET,
  ];

  static final $core.Map<$core.int, TxDebtPaymentMethod> _byValue = $pb.ProtobufEnum.initByValue(values);
  static TxDebtPaymentMethod? valueOf($core.int value) => _byValue[value];

  const TxDebtPaymentMethod._($core.int v, $core.String n) : super(v, n);
}

class TxAccSide extends $pb.ProtobufEnum {
  static const TxAccSide TX_ACC_SIDE_UNSPECIFIED = TxAccSide._(0, _omitEnumNames ? '' : 'TX_ACC_SIDE_UNSPECIFIED');
  static const TxAccSide TX_ACC_SIDE_DEBIT = TxAccSide._(1, _omitEnumNames ? '' : 'TX_ACC_SIDE_DEBIT');
  static const TxAccSide TX_ACC_SIDE_CREDIT = TxAccSide._(2, _omitEnumNames ? '' : 'TX_ACC_SIDE_CREDIT');

  static const $core.List<TxAccSide> values = <TxAccSide> [
    TX_ACC_SIDE_UNSPECIFIED,
    TX_ACC_SIDE_DEBIT,
    TX_ACC_SIDE_CREDIT,
  ];

  static final $core.Map<$core.int, TxAccSide> _byValue = $pb.ProtobufEnum.initByValue(values);
  static TxAccSide? valueOf($core.int value) => _byValue[value];

  const TxAccSide._($core.int v, $core.String n) : super(v, n);
}

class TxItemFulfillmentState extends $pb.ProtobufEnum {
  static const TxItemFulfillmentState TX_ITEM_FULFILLMENT_UNSPECIFIED = TxItemFulfillmentState._(0, _omitEnumNames ? '' : 'TX_ITEM_FULFILLMENT_UNSPECIFIED');
  static const TxItemFulfillmentState TX_ITEM_FULFILLMENT_PENDING = TxItemFulfillmentState._(1, _omitEnumNames ? '' : 'TX_ITEM_FULFILLMENT_PENDING');
  static const TxItemFulfillmentState TX_ITEM_FULFILLMENT_IN_PROGRESS = TxItemFulfillmentState._(2, _omitEnumNames ? '' : 'TX_ITEM_FULFILLMENT_IN_PROGRESS');
  static const TxItemFulfillmentState TX_ITEM_FULFILLMENT_DONE = TxItemFulfillmentState._(3, _omitEnumNames ? '' : 'TX_ITEM_FULFILLMENT_DONE');

  static const $core.List<TxItemFulfillmentState> values = <TxItemFulfillmentState> [
    TX_ITEM_FULFILLMENT_UNSPECIFIED,
    TX_ITEM_FULFILLMENT_PENDING,
    TX_ITEM_FULFILLMENT_IN_PROGRESS,
    TX_ITEM_FULFILLMENT_DONE,
  ];

  static final $core.Map<$core.int, TxItemFulfillmentState> _byValue = $pb.ProtobufEnum.initByValue(values);
  static TxItemFulfillmentState? valueOf($core.int value) => _byValue[value];

  const TxItemFulfillmentState._($core.int v, $core.String n) : super(v, n);
}

class TxOrderPayAt extends $pb.ProtobufEnum {
  static const TxOrderPayAt TX_ORDER_PAY_AT_UNSPECIFIED = TxOrderPayAt._(0, _omitEnumNames ? '' : 'TX_ORDER_PAY_AT_UNSPECIFIED');
  static const TxOrderPayAt TX_ORDER_PAY_AT_CASHIER = TxOrderPayAt._(1, _omitEnumNames ? '' : 'TX_ORDER_PAY_AT_CASHIER');
  static const TxOrderPayAt TX_ORDER_PAY_AT_TABLE = TxOrderPayAt._(2, _omitEnumNames ? '' : 'TX_ORDER_PAY_AT_TABLE');

  static const $core.List<TxOrderPayAt> values = <TxOrderPayAt> [
    TX_ORDER_PAY_AT_UNSPECIFIED,
    TX_ORDER_PAY_AT_CASHIER,
    TX_ORDER_PAY_AT_TABLE,
  ];

  static final $core.Map<$core.int, TxOrderPayAt> _byValue = $pb.ProtobufEnum.initByValue(values);
  static TxOrderPayAt? valueOf($core.int value) => _byValue[value];

  const TxOrderPayAt._($core.int v, $core.String n) : super(v, n);
}


const _omitEnumNames = $core.bool.fromEnvironment('protobuf.omit_enum_names');
