// This is a generated file - do not edit.
//
// Generated from c35/tx.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use txInputSourceDescriptor instead')
const TxInputSource$json = {
  '1': 'TxInputSource',
  '2': [
    {'1': 'TX_INPUT_SOURCE_UNSPECIFIED', '2': 0},
    {'1': 'TX_INPUT_SOURCE_MANUAL', '2': 1},
    {'1': 'TX_INPUT_SOURCE_WEB', '2': 2},
    {'1': 'TX_INPUT_SOURCE_AI', '2': 3},
    {'1': 'TX_INPUT_SOURCE_API', '2': 4},
  ],
};

/// Descriptor for `TxInputSource`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List txInputSourceDescriptor = $convert.base64Decode(
    'Cg1UeElucHV0U291cmNlEh8KG1RYX0lOUFVUX1NPVVJDRV9VTlNQRUNJRklFRBAAEhoKFlRYX0'
    'lOUFVUX1NPVVJDRV9NQU5VQUwQARIXChNUWF9JTlBVVF9TT1VSQ0VfV0VCEAISFgoSVFhfSU5Q'
    'VVRfU09VUkNFX0FJEAMSFwoTVFhfSU5QVVRfU09VUkNFX0FQSRAE');

@$core.Deprecated('Use txTypeDescriptor instead')
const TxType$json = {
  '1': 'TxType',
  '2': [
    {'1': 'TX_TYPE_UNSPECIFIED', '2': 0},
    {'1': 'TX_TYPE_SALE', '2': 1},
    {'1': 'TX_TYPE_PURCHASE', '2': 2},
    {'1': 'TX_TYPE_TRANSFER', '2': 3},
    {'1': 'TX_TYPE_ADJUSTMENT', '2': 4},
    {'1': 'TX_TYPE_RETURN_SALE', '2': 5},
    {'1': 'TX_TYPE_RETURN_PURCHASE', '2': 6},
    {'1': 'TX_TYPE_RESERVATION', '2': 7},
    {'1': 'TX_TYPE_SHIP', '2': 8},
    {'1': 'TX_TYPE_PAYMENT', '2': 9},
    {'1': 'TX_TYPE_RECEIPT', '2': 10},
    {'1': 'TX_TYPE_DEBT_PAYABLE', '2': 11},
    {'1': 'TX_TYPE_DEBT_RECEIVABLE', '2': 12},
    {'1': 'TX_TYPE_INVENTORY', '2': 13},
  ],
};

/// Descriptor for `TxType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List txTypeDescriptor = $convert.base64Decode(
    'CgZUeFR5cGUSFwoTVFhfVFlQRV9VTlNQRUNJRklFRBAAEhAKDFRYX1RZUEVfU0FMRRABEhQKEF'
    'RYX1RZUEVfUFVSQ0hBU0UQAhIUChBUWF9UWVBFX1RSQU5TRkVSEAMSFgoSVFhfVFlQRV9BREpV'
    'U1RNRU5UEAQSFwoTVFhfVFlQRV9SRVRVUk5fU0FMRRAFEhsKF1RYX1RZUEVfUkVUVVJOX1BVUk'
    'NIQVNFEAYSFwoTVFhfVFlQRV9SRVNFUlZBVElPThAHEhAKDFRYX1RZUEVfU0hJUBAIEhMKD1RY'
    'X1RZUEVfUEFZTUVOVBAJEhMKD1RYX1RZUEVfUkVDRUlQVBAKEhgKFFRYX1RZUEVfREVCVF9QQV'
    'lBQkxFEAsSGwoXVFhfVFlQRV9ERUJUX1JFQ0VJVkFCTEUQDBIVChFUWF9UWVBFX0lOVkVOVE9S'
    'WRAN');

@$core.Deprecated('Use txStateDescriptor instead')
const TxState$json = {
  '1': 'TxState',
  '2': [
    {'1': 'TX_STATE_OK', '2': 0},
    {'1': 'TX_STATE_DRAFT', '2': 1},
    {'1': 'TX_STATE_PENDING', '2': 2},
    {'1': 'TX_STATE_WAITING_PAYMENT', '2': 3},
    {'1': 'TX_STATE_CANCELLED', '2': 99},
  ],
};

/// Descriptor for `TxState`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List txStateDescriptor = $convert.base64Decode(
    'CgdUeFN0YXRlEg8KC1RYX1NUQVRFX09LEAASEgoOVFhfU1RBVEVfRFJBRlQQARIUChBUWF9TVE'
    'FURV9QRU5ESU5HEAISHAoYVFhfU1RBVEVfV0FJVElOR19QQVlNRU5UEAMSFgoSVFhfU1RBVEVf'
    'Q0FOQ0VMTEVEEGM=');

@$core.Deprecated('Use txInputModeDescriptor instead')
const TxInputMode$json = {
  '1': 'TxInputMode',
  '2': [
    {'1': 'TX_INPUT_MODE_NORMAL', '2': 0},
    {'1': 'TX_INPUT_MODE_ACCOUNTING', '2': 1},
    {'1': 'TX_INPUT_MODE_SELL', '2': 2},
    {'1': 'TX_INPUT_MODE_PURCHASE', '2': 3},
  ],
};

/// Descriptor for `TxInputMode`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List txInputModeDescriptor = $convert.base64Decode(
    'CgtUeElucHV0TW9kZRIYChRUWF9JTlBVVF9NT0RFX05PUk1BTBAAEhwKGFRYX0lOUFVUX01PRE'
    'VfQUNDT1VOVElORxABEhYKElRYX0lOUFVUX01PREVfU0VMTBACEhoKFlRYX0lOUFVUX01PREVf'
    'UFVSQ0hBU0UQAw==');

@$core.Deprecated('Use txPaymentMethodDescriptor instead')
const TxPaymentMethod$json = {
  '1': 'TxPaymentMethod',
  '2': [
    {'1': 'TX_PAYMENT_METHOD_UNSPECIFIED', '2': 0},
    {'1': 'TX_PAYMENT_METHOD_CASH', '2': 1},
    {'1': 'TX_PAYMENT_METHOD_CARD', '2': 2},
    {'1': 'TX_PAYMENT_METHOD_TRANSFER', '2': 3},
    {'1': 'TX_PAYMENT_METHOD_QRIS', '2': 4},
    {'1': 'TX_PAYMENT_METHOD_DEBT', '2': 5},
    {'1': 'TX_PAYMENT_METHOD_WALLET', '2': 6},
  ],
};

/// Descriptor for `TxPaymentMethod`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List txPaymentMethodDescriptor = $convert.base64Decode(
    'Cg9UeFBheW1lbnRNZXRob2QSIQodVFhfUEFZTUVOVF9NRVRIT0RfVU5TUEVDSUZJRUQQABIaCh'
    'ZUWF9QQVlNRU5UX01FVEhPRF9DQVNIEAESGgoWVFhfUEFZTUVOVF9NRVRIT0RfQ0FSRBACEh4K'
    'GlRYX1BBWU1FTlRfTUVUSE9EX1RSQU5TRkVSEAMSGgoWVFhfUEFZTUVOVF9NRVRIT0RfUVJJUx'
    'AEEhoKFlRYX1BBWU1FTlRfTUVUSE9EX0RFQlQQBRIcChhUWF9QQVlNRU5UX01FVEhPRF9XQUxM'
    'RVQQBg==');

@$core.Deprecated('Use txDebtPaymentMethodDescriptor instead')
const TxDebtPaymentMethod$json = {
  '1': 'TxDebtPaymentMethod',
  '2': [
    {'1': 'TX_DEBT_PAYMENT_METHOD_UNSPECIFIED', '2': 0},
    {'1': 'TX_DEBT_PAYMENT_METHOD_CASH', '2': 1},
    {'1': 'TX_DEBT_PAYMENT_METHOD_CARD', '2': 2},
    {'1': 'TX_DEBT_PAYMENT_METHOD_TRANSFER', '2': 3},
    {'1': 'TX_DEBT_PAYMENT_METHOD_QRIS', '2': 4},
    {'1': 'TX_DEBT_PAYMENT_METHOD_WALLET', '2': 5},
  ],
};

/// Descriptor for `TxDebtPaymentMethod`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List txDebtPaymentMethodDescriptor = $convert.base64Decode(
    'ChNUeERlYnRQYXltZW50TWV0aG9kEiYKIlRYX0RFQlRfUEFZTUVOVF9NRVRIT0RfVU5TUEVDSU'
    'ZJRUQQABIfChtUWF9ERUJUX1BBWU1FTlRfTUVUSE9EX0NBU0gQARIfChtUWF9ERUJUX1BBWU1F'
    'TlRfTUVUSE9EX0NBUkQQAhIjCh9UWF9ERUJUX1BBWU1FTlRfTUVUSE9EX1RSQU5TRkVSEAMSHw'
    'obVFhfREVCVF9QQVlNRU5UX01FVEhPRF9RUklTEAQSIQodVFhfREVCVF9QQVlNRU5UX01FVEhP'
    'RF9XQUxMRVQQBQ==');

@$core.Deprecated('Use txAccSideDescriptor instead')
const TxAccSide$json = {
  '1': 'TxAccSide',
  '2': [
    {'1': 'TX_ACC_SIDE_UNSPECIFIED', '2': 0},
    {'1': 'TX_ACC_SIDE_DEBIT', '2': 1},
    {'1': 'TX_ACC_SIDE_CREDIT', '2': 2},
  ],
};

/// Descriptor for `TxAccSide`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List txAccSideDescriptor = $convert.base64Decode(
    'CglUeEFjY1NpZGUSGwoXVFhfQUNDX1NJREVfVU5TUEVDSUZJRUQQABIVChFUWF9BQ0NfU0lERV'
    '9ERUJJVBABEhYKElRYX0FDQ19TSURFX0NSRURJVBAC');

@$core.Deprecated('Use txItemFulfillmentStateDescriptor instead')
const TxItemFulfillmentState$json = {
  '1': 'TxItemFulfillmentState',
  '2': [
    {'1': 'TX_ITEM_FULFILLMENT_UNSPECIFIED', '2': 0},
    {'1': 'TX_ITEM_FULFILLMENT_PENDING', '2': 1},
    {'1': 'TX_ITEM_FULFILLMENT_IN_PROGRESS', '2': 2},
    {'1': 'TX_ITEM_FULFILLMENT_DONE', '2': 3},
  ],
};

/// Descriptor for `TxItemFulfillmentState`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List txItemFulfillmentStateDescriptor = $convert.base64Decode(
    'ChZUeEl0ZW1GdWxmaWxsbWVudFN0YXRlEiMKH1RYX0lURU1fRlVMRklMTE1FTlRfVU5TUEVDSU'
    'ZJRUQQABIfChtUWF9JVEVNX0ZVTEZJTExNRU5UX1BFTkRJTkcQARIjCh9UWF9JVEVNX0ZVTEZJ'
    'TExNRU5UX0lOX1BST0dSRVNTEAISHAoYVFhfSVRFTV9GVUxGSUxMTUVOVF9ET05FEAM=');

@$core.Deprecated('Use txOrderPayAtDescriptor instead')
const TxOrderPayAt$json = {
  '1': 'TxOrderPayAt',
  '2': [
    {'1': 'TX_ORDER_PAY_AT_UNSPECIFIED', '2': 0},
    {'1': 'TX_ORDER_PAY_AT_CASHIER', '2': 1},
    {'1': 'TX_ORDER_PAY_AT_TABLE', '2': 2},
  ],
};

/// Descriptor for `TxOrderPayAt`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List txOrderPayAtDescriptor = $convert.base64Decode(
    'CgxUeE9yZGVyUGF5QXQSHwobVFhfT1JERVJfUEFZX0FUX1VOU1BFQ0lGSUVEEAASGwoXVFhfT1'
    'JERVJfUEFZX0FUX0NBU0hJRVIQARIZChVUWF9PUkRFUl9QQVlfQVRfVEFCTEUQAg==');

@$core.Deprecated('Use txDataDescriptor instead')
const TxData$json = {
  '1': 'TxData',
  '2': [
    {'1': 'proofs', '3': 1, '4': 3, '5': 9, '10': 'proofs'},
    {
      '1': 'prompt',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.c35.TxPrompt',
      '10': 'prompt'
    },
    {
      '1': 'delivery',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.c35.TxDelivery',
      '10': 'delivery'
    },
    {
      '1': 'promos',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.c35.TxPromo',
      '10': 'promos'
    },
  ],
};

/// Descriptor for `TxData`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List txDataDescriptor = $convert.base64Decode(
    'CgZUeERhdGESFgoGcHJvb2ZzGAEgAygJUgZwcm9vZnMSJQoGcHJvbXB0GAIgASgLMg0uYzM1Ll'
    'R4UHJvbXB0UgZwcm9tcHQSKwoIZGVsaXZlcnkYAyABKAsyDy5jMzUuVHhEZWxpdmVyeVIIZGVs'
    'aXZlcnkSJAoGcHJvbW9zGAQgAygLMgwuYzM1LlR4UHJvbW9SBnByb21vcw==');

@$core.Deprecated('Use txPromptDescriptor instead')
const TxPrompt$json = {
  '1': 'TxPrompt',
  '2': [
    {'1': 'pics', '3': 1, '4': 3, '5': 9, '10': 'pics'},
    {'1': 'desc', '3': 2, '4': 1, '5': 9, '10': 'desc'},
  ],
};

/// Descriptor for `TxPrompt`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List txPromptDescriptor = $convert.base64Decode(
    'CghUeFByb21wdBISCgRwaWNzGAEgAygJUgRwaWNzEhIKBGRlc2MYAiABKAlSBGRlc2M=');

@$core.Deprecated('Use txDescriptor instead')
const Tx$json = {
  '1': 'Tx',
  '2': [
    {'1': 'site_iid', '3': 1, '4': 1, '5': 3, '10': 'siteIid'},
    {'1': 'tx_id', '3': 2, '4': 1, '5': 3, '10': 'txId'},
    {'1': 'type', '3': 3, '4': 1, '5': 14, '6': '.c35.TxType', '10': 'type'},
    {'1': 'state', '3': 4, '4': 1, '5': 14, '6': '.c35.TxState', '10': 'state'},
    {
      '1': 'input_mode',
      '3': 5,
      '4': 1,
      '5': 14,
      '6': '.c35.TxInputMode',
      '10': 'inputMode'
    },
    {
      '1': 'input_source',
      '3': 6,
      '4': 1,
      '5': 14,
      '6': '.c35.TxInputSource',
      '10': 'inputSource'
    },
    {'1': 'is_archived', '3': 10, '4': 1, '5': 8, '10': 'isArchived'},
    {'1': 'desc', '3': 11, '4': 1, '5': 9, '10': 'desc'},
    {'1': 'time_ts_ms', '3': 12, '4': 1, '5': 3, '10': 'timeTsMs'},
    {'1': 'created_by_iid', '3': 13, '4': 1, '5': 3, '10': 'createdByIid'},
    {'1': 'cancel_reason', '3': 14, '4': 1, '5': 9, '10': 'cancelReason'},
    {
      '1': 'subject_contact_id',
      '3': 21,
      '4': 1,
      '5': 3,
      '10': 'subjectContactId'
    },
    {'1': 'subject_name', '3': 22, '4': 1, '5': 9, '10': 'subjectName'},
    {'1': 'subject_phone', '3': 23, '4': 1, '5': 9, '10': 'subjectPhone'},
    {'1': 'subject_address', '3': 24, '4': 1, '5': 9, '10': 'subjectAddress'},
    {'1': 'cashier_name', '3': 25, '4': 1, '5': 9, '10': 'cashierName'},
    {'1': 'store_id', '3': 31, '4': 1, '5': 3, '10': 'storeId'},
    {'1': 'store_tgt_id', '3': 33, '4': 1, '5': 3, '10': 'storeTgtId'},
    {'1': 'delivery_state', '3': 34, '4': 1, '5': 9, '10': 'deliveryState'},
    {'1': 'obj_id', '3': 41, '4': 1, '5': 3, '10': 'objId'},
    {'1': 'promo_code', '3': 53, '4': 1, '5': 9, '10': 'promoCode'},
    {'1': 'is_paid', '3': 55, '4': 1, '5': 8, '10': 'isPaid'},
    {'1': 'is_task_assigned', '3': 56, '4': 1, '5': 8, '10': 'isTaskAssigned'},
    {
      '1': 'order_pay_at',
      '3': 57,
      '4': 1,
      '5': 14,
      '6': '.c35.TxOrderPayAt',
      '10': 'orderPayAt'
    },
    {'1': 'items_count', '3': 121, '4': 1, '5': 3, '10': 'itemsCount'},
    {'1': 'items_qty', '3': 122, '4': 1, '5': 3, '10': 'itemsQty'},
    {'1': 'items_total', '3': 123, '4': 1, '5': 3, '10': 'itemsTotal'},
    {'1': 'debt_total', '3': 131, '4': 1, '5': 3, '10': 'debtTotal'},
    {'1': 'debt_paid', '3': 132, '4': 1, '5': 3, '10': 'debtPaid'},
    {'1': 'debt_unpaid', '3': 133, '4': 1, '5': 3, '10': 'debtUnpaid'},
    {'1': 'total_taxes', '3': 141, '4': 1, '5': 3, '10': 'totalTaxes'},
    {'1': 'total_discounts', '3': 142, '4': 1, '5': 3, '10': 'totalDiscounts'},
    {'1': 'total_interest', '3': 143, '4': 1, '5': 3, '10': 'totalInterest'},
    {'1': 'total_paid', '3': 144, '4': 1, '5': 3, '10': 'totalPaid'},
    {'1': 'total_unpaid', '3': 145, '4': 1, '5': 3, '10': 'totalUnpaid'},
    {'1': 'total', '3': 200, '4': 1, '5': 3, '10': 'total'},
    {'1': 'stock_line_count', '3': 151, '4': 1, '5': 5, '10': 'stockLineCount'},
    {'1': 'stock_qty_in', '3': 152, '4': 1, '5': 5, '10': 'stockQtyIn'},
    {'1': 'stock_qty_out', '3': 153, '4': 1, '5': 5, '10': 'stockQtyOut'},
    {'1': 'acc_line_count', '3': 161, '4': 1, '5': 5, '10': 'accLineCount'},
    {'1': 'acc_sum', '3': 162, '4': 1, '5': 3, '10': 'accSum'},
    {'1': 'acc_balanced', '3': 163, '4': 1, '5': 8, '10': 'accBalanced'},
    {'1': 'has_manual_lines', '3': 164, '4': 1, '5': 8, '10': 'hasManualLines'},
    {
      '1': 'tx_data',
      '3': 100,
      '4': 1,
      '5': 11,
      '6': '.c35.TxData',
      '10': 'txData'
    },
    {
      '1': 'items',
      '3': 201,
      '4': 3,
      '5': 11,
      '6': '.c35.TxItem',
      '10': 'items'
    },
    {
      '1': 'payments',
      '3': 202,
      '4': 3,
      '5': 11,
      '6': '.c35.TxPayment',
      '10': 'payments'
    },
    {'1': 'accs', '3': 203, '4': 3, '5': 11, '6': '.c35.TxAcc', '10': 'accs'},
    {
      '1': 'stocks',
      '3': 204,
      '4': 3,
      '5': 11,
      '6': '.c35.TxStock',
      '10': 'stocks'
    },
    {'1': 'taxes', '3': 205, '4': 3, '5': 11, '6': '.c35.TxTax', '10': 'taxes'},
    {
      '1': 'discounts',
      '3': 206,
      '4': 3,
      '5': 11,
      '6': '.c35.TxDiscount',
      '10': 'discounts'
    },
    {'1': 'created_ts_ms', '3': 180, '4': 1, '5': 3, '10': 'createdTsMs'},
    {'1': 'updated_ts_ms', '3': 181, '4': 1, '5': 3, '10': 'updatedTsMs'},
    {'1': 'deleted_ts_ms', '3': 182, '4': 1, '5': 3, '10': 'deletedTsMs'},
  ],
};

/// Descriptor for `Tx`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List txDescriptor = $convert.base64Decode(
    'CgJUeBIZCghzaXRlX2lpZBgBIAEoA1IHc2l0ZUlpZBITCgV0eF9pZBgCIAEoA1IEdHhJZBIfCg'
    'R0eXBlGAMgASgOMgsuYzM1LlR4VHlwZVIEdHlwZRIiCgVzdGF0ZRgEIAEoDjIMLmMzNS5UeFN0'
    'YXRlUgVzdGF0ZRIvCgppbnB1dF9tb2RlGAUgASgOMhAuYzM1LlR4SW5wdXRNb2RlUglpbnB1dE'
    '1vZGUSNQoMaW5wdXRfc291cmNlGAYgASgOMhIuYzM1LlR4SW5wdXRTb3VyY2VSC2lucHV0U291'
    'cmNlEh8KC2lzX2FyY2hpdmVkGAogASgIUgppc0FyY2hpdmVkEhIKBGRlc2MYCyABKAlSBGRlc2'
    'MSHAoKdGltZV90c19tcxgMIAEoA1IIdGltZVRzTXMSJAoOY3JlYXRlZF9ieV9paWQYDSABKANS'
    'DGNyZWF0ZWRCeUlpZBIjCg1jYW5jZWxfcmVhc29uGA4gASgJUgxjYW5jZWxSZWFzb24SLAoSc3'
    'ViamVjdF9jb250YWN0X2lkGBUgASgDUhBzdWJqZWN0Q29udGFjdElkEiEKDHN1YmplY3RfbmFt'
    'ZRgWIAEoCVILc3ViamVjdE5hbWUSIwoNc3ViamVjdF9waG9uZRgXIAEoCVIMc3ViamVjdFBob2'
    '5lEicKD3N1YmplY3RfYWRkcmVzcxgYIAEoCVIOc3ViamVjdEFkZHJlc3MSIQoMY2FzaGllcl9u'
    'YW1lGBkgASgJUgtjYXNoaWVyTmFtZRIZCghzdG9yZV9pZBgfIAEoA1IHc3RvcmVJZBIgCgxzdG'
    '9yZV90Z3RfaWQYISABKANSCnN0b3JlVGd0SWQSJQoOZGVsaXZlcnlfc3RhdGUYIiABKAlSDWRl'
    'bGl2ZXJ5U3RhdGUSFQoGb2JqX2lkGCkgASgDUgVvYmpJZBIdCgpwcm9tb19jb2RlGDUgASgJUg'
    'lwcm9tb0NvZGUSFwoHaXNfcGFpZBg3IAEoCFIGaXNQYWlkEigKEGlzX3Rhc2tfYXNzaWduZWQY'
    'OCABKAhSDmlzVGFza0Fzc2lnbmVkEjMKDG9yZGVyX3BheV9hdBg5IAEoDjIRLmMzNS5UeE9yZG'
    'VyUGF5QXRSCm9yZGVyUGF5QXQSHwoLaXRlbXNfY291bnQYeSABKANSCml0ZW1zQ291bnQSGwoJ'
    'aXRlbXNfcXR5GHogASgDUghpdGVtc1F0eRIfCgtpdGVtc190b3RhbBh7IAEoA1IKaXRlbXNUb3'
    'RhbBIeCgpkZWJ0X3RvdGFsGIMBIAEoA1IJZGVidFRvdGFsEhwKCWRlYnRfcGFpZBiEASABKANS'
    'CGRlYnRQYWlkEiAKC2RlYnRfdW5wYWlkGIUBIAEoA1IKZGVidFVucGFpZBIgCgt0b3RhbF90YX'
    'hlcxiNASABKANSCnRvdGFsVGF4ZXMSKAoPdG90YWxfZGlzY291bnRzGI4BIAEoA1IOdG90YWxE'
    'aXNjb3VudHMSJgoOdG90YWxfaW50ZXJlc3QYjwEgASgDUg10b3RhbEludGVyZXN0Eh4KCnRvdG'
    'FsX3BhaWQYkAEgASgDUgl0b3RhbFBhaWQSIgoMdG90YWxfdW5wYWlkGJEBIAEoA1ILdG90YWxV'
    'bnBhaWQSFQoFdG90YWwYyAEgASgDUgV0b3RhbBIpChBzdG9ja19saW5lX2NvdW50GJcBIAEoBV'
    'IOc3RvY2tMaW5lQ291bnQSIQoMc3RvY2tfcXR5X2luGJgBIAEoBVIKc3RvY2tRdHlJbhIjCg1z'
    'dG9ja19xdHlfb3V0GJkBIAEoBVILc3RvY2tRdHlPdXQSJQoOYWNjX2xpbmVfY291bnQYoQEgAS'
    'gFUgxhY2NMaW5lQ291bnQSGAoHYWNjX3N1bRiiASABKANSBmFjY1N1bRIiCgxhY2NfYmFsYW5j'
    'ZWQYowEgASgIUgthY2NCYWxhbmNlZBIpChBoYXNfbWFudWFsX2xpbmVzGKQBIAEoCFIOaGFzTW'
    'FudWFsTGluZXMSJAoHdHhfZGF0YRhkIAEoCzILLmMzNS5UeERhdGFSBnR4RGF0YRIiCgVpdGVt'
    'cxjJASADKAsyCy5jMzUuVHhJdGVtUgVpdGVtcxIrCghwYXltZW50cxjKASADKAsyDi5jMzUuVH'
    'hQYXltZW50UghwYXltZW50cxIfCgRhY2NzGMsBIAMoCzIKLmMzNS5UeEFjY1IEYWNjcxIlCgZz'
    'dG9ja3MYzAEgAygLMgwuYzM1LlR4U3RvY2tSBnN0b2NrcxIhCgV0YXhlcxjNASADKAsyCi5jMz'
    'UuVHhUYXhSBXRheGVzEi4KCWRpc2NvdW50cxjOASADKAsyDy5jMzUuVHhEaXNjb3VudFIJZGlz'
    'Y291bnRzEiMKDWNyZWF0ZWRfdHNfbXMYtAEgASgDUgtjcmVhdGVkVHNNcxIjCg11cGRhdGVkX3'
    'RzX21zGLUBIAEoA1ILdXBkYXRlZFRzTXMSIwoNZGVsZXRlZF90c19tcxi2ASABKANSC2RlbGV0'
    'ZWRUc01z');

@$core.Deprecated('Use txItemDescriptor instead')
const TxItem$json = {
  '1': 'TxItem',
  '2': [
    {'1': 'site_iid', '3': 1, '4': 1, '5': 3, '10': 'siteIid'},
    {'1': 'tx_id', '3': 2, '4': 1, '5': 3, '10': 'txId'},
    {'1': 'item_id', '3': 3, '4': 1, '5': 3, '10': 'itemId'},
    {'1': 'product_id', '3': 4, '4': 1, '5': 3, '10': 'productId'},
    {'1': 'product_rev', '3': 5, '4': 1, '5': 3, '10': 'productRev'},
    {'1': 'price', '3': 11, '4': 1, '5': 3, '10': 'price'},
    {'1': 'qty', '3': 13, '4': 1, '5': 5, '10': 'qty'},
    {'1': 'note', '3': 12, '4': 1, '5': 9, '10': 'note'},
    {'1': 'batch_number', '3': 32, '4': 1, '5': 9, '10': 'batchNumber'},
    {'1': 'serial_number', '3': 33, '4': 1, '5': 9, '10': 'serialNumber'},
    {
      '1': 'fulfillment_state',
      '3': 37,
      '4': 1,
      '5': 14,
      '6': '.c35.TxItemFulfillmentState',
      '10': 'fulfillmentState'
    },
    {'1': 'total_qty', '3': 101, '4': 1, '5': 5, '10': 'totalQty'},
    {'1': 'total_price', '3': 102, '4': 1, '5': 3, '10': 'totalPrice'},
    {'1': 'total_discount', '3': 103, '4': 1, '5': 3, '10': 'totalDiscount'},
    {'1': 'total_tax', '3': 104, '4': 1, '5': 3, '10': 'totalTax'},
    {'1': 'total_net', '3': 105, '4': 1, '5': 3, '10': 'totalNet'},
    {'1': 'total_paid', '3': 202, '4': 1, '5': 3, '10': 'totalPaid'},
    {'1': 'total_unpaid', '3': 201, '4': 1, '5': 3, '10': 'totalUnpaid'},
    {
      '1': 'reservations',
      '3': 21,
      '4': 3,
      '5': 11,
      '6': '.c35.TxItemReservation',
      '10': 'reservations'
    },
    {
      '1': 'sources',
      '3': 31,
      '4': 3,
      '5': 11,
      '6': '.c35.TxItemSource',
      '10': 'sources'
    },
  ],
};

/// Descriptor for `TxItem`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List txItemDescriptor = $convert.base64Decode(
    'CgZUeEl0ZW0SGQoIc2l0ZV9paWQYASABKANSB3NpdGVJaWQSEwoFdHhfaWQYAiABKANSBHR4SW'
    'QSFwoHaXRlbV9pZBgDIAEoA1IGaXRlbUlkEh0KCnByb2R1Y3RfaWQYBCABKANSCXByb2R1Y3RJ'
    'ZBIfCgtwcm9kdWN0X3JldhgFIAEoA1IKcHJvZHVjdFJldhIUCgVwcmljZRgLIAEoA1IFcHJpY2'
    'USEAoDcXR5GA0gASgFUgNxdHkSEgoEbm90ZRgMIAEoCVIEbm90ZRIhCgxiYXRjaF9udW1iZXIY'
    'ICABKAlSC2JhdGNoTnVtYmVyEiMKDXNlcmlhbF9udW1iZXIYISABKAlSDHNlcmlhbE51bWJlch'
    'JIChFmdWxmaWxsbWVudF9zdGF0ZRglIAEoDjIbLmMzNS5UeEl0ZW1GdWxmaWxsbWVudFN0YXRl'
    'UhBmdWxmaWxsbWVudFN0YXRlEhsKCXRvdGFsX3F0eRhlIAEoBVIIdG90YWxRdHkSHwoLdG90YW'
    'xfcHJpY2UYZiABKANSCnRvdGFsUHJpY2USJQoOdG90YWxfZGlzY291bnQYZyABKANSDXRvdGFs'
    'RGlzY291bnQSGwoJdG90YWxfdGF4GGggASgDUgh0b3RhbFRheBIbCgl0b3RhbF9uZXQYaSABKA'
    'NSCHRvdGFsTmV0Eh4KCnRvdGFsX3BhaWQYygEgASgDUgl0b3RhbFBhaWQSIgoMdG90YWxfdW5w'
    'YWlkGMkBIAEoA1ILdG90YWxVbnBhaWQSOgoMcmVzZXJ2YXRpb25zGBUgAygLMhYuYzM1LlR4SX'
    'RlbVJlc2VydmF0aW9uUgxyZXNlcnZhdGlvbnMSKwoHc291cmNlcxgfIAMoCzIRLmMzNS5UeEl0'
    'ZW1Tb3VyY2VSB3NvdXJjZXM=');

@$core.Deprecated('Use txItemReservationDescriptor instead')
const TxItemReservation$json = {
  '1': 'TxItemReservation',
  '2': [
    {'1': 'res_id', '3': 4, '4': 1, '5': 3, '10': 'resId'},
    {'1': 'product_id', '3': 5, '4': 1, '5': 3, '10': 'productId'},
    {'1': 'qty', '3': 10, '4': 1, '5': 5, '10': 'qty'},
    {'1': 'duration_qty', '3': 11, '4': 1, '5': 5, '10': 'durationQty'},
    {'1': 'note', '3': 12, '4': 1, '5': 9, '10': 'note'},
    {'1': 'start_ts_ms', '3': 20, '4': 1, '5': 3, '10': 'startTsMs'},
    {'1': 'end_ts_ms', '3': 21, '4': 1, '5': 3, '10': 'endTsMs'},
    {'1': 'state', '3': 30, '4': 1, '5': 9, '10': 'state'},
    {'1': 'is_no_show', '3': 31, '4': 1, '5': 8, '10': 'isNoShow'},
    {'1': 'is_unavailable', '3': 32, '4': 1, '5': 8, '10': 'isUnavailable'},
  ],
};

/// Descriptor for `TxItemReservation`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List txItemReservationDescriptor = $convert.base64Decode(
    'ChFUeEl0ZW1SZXNlcnZhdGlvbhIVCgZyZXNfaWQYBCABKANSBXJlc0lkEh0KCnByb2R1Y3RfaW'
    'QYBSABKANSCXByb2R1Y3RJZBIQCgNxdHkYCiABKAVSA3F0eRIhCgxkdXJhdGlvbl9xdHkYCyAB'
    'KAVSC2R1cmF0aW9uUXR5EhIKBG5vdGUYDCABKAlSBG5vdGUSHgoLc3RhcnRfdHNfbXMYFCABKA'
    'NSCXN0YXJ0VHNNcxIaCgllbmRfdHNfbXMYFSABKANSB2VuZFRzTXMSFAoFc3RhdGUYHiABKAlS'
    'BXN0YXRlEhwKCmlzX25vX3Nob3cYHyABKAhSCGlzTm9TaG93EiUKDmlzX3VuYXZhaWxhYmxlGC'
    'AgASgIUg1pc1VuYXZhaWxhYmxl');

@$core.Deprecated('Use txItemSourceDescriptor instead')
const TxItemSource$json = {
  '1': 'TxItemSource',
  '2': [
    {'1': 'src_id', '3': 4, '4': 1, '5': 3, '10': 'srcId'},
    {'1': 'obj_id', '3': 10, '4': 1, '5': 3, '10': 'objId'},
    {'1': 'product_id', '3': 11, '4': 1, '5': 3, '10': 'productId'},
    {'1': 'qty', '3': 12, '4': 1, '5': 5, '10': 'qty'},
    {'1': 'note', '3': 13, '4': 1, '5': 9, '10': 'note'},
  ],
};

/// Descriptor for `TxItemSource`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List txItemSourceDescriptor = $convert.base64Decode(
    'CgxUeEl0ZW1Tb3VyY2USFQoGc3JjX2lkGAQgASgDUgVzcmNJZBIVCgZvYmpfaWQYCiABKANSBW'
    '9iaklkEh0KCnByb2R1Y3RfaWQYCyABKANSCXByb2R1Y3RJZBIQCgNxdHkYDCABKAVSA3F0eRIS'
    'CgRub3RlGA0gASgJUgRub3Rl');

@$core.Deprecated('Use txDeliveryDescriptor instead')
const TxDelivery$json = {
  '1': 'TxDelivery',
  '2': [
    {'1': 'obj_id', '3': 1, '4': 1, '5': 3, '10': 'objId'},
    {'1': 'contact_id', '3': 2, '4': 1, '5': 3, '10': 'contactId'},
    {'1': 'user_iid', '3': 3, '4': 1, '5': 3, '10': 'userIid'},
    {'1': 'to', '3': 11, '4': 1, '5': 11, '6': '.c35.TxDeliveryTo', '10': 'to'},
    {
      '1': 'service',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.c35.TxDeliveryService',
      '10': 'service'
    },
    {'1': 'state', '3': 200, '4': 1, '5': 9, '10': 'state'},
  ],
};

/// Descriptor for `TxDelivery`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List txDeliveryDescriptor = $convert.base64Decode(
    'CgpUeERlbGl2ZXJ5EhUKBm9ial9pZBgBIAEoA1IFb2JqSWQSHQoKY29udGFjdF9pZBgCIAEoA1'
    'IJY29udGFjdElkEhkKCHVzZXJfaWlkGAMgASgDUgd1c2VySWlkEiEKAnRvGAsgASgLMhEuYzM1'
    'LlR4RGVsaXZlcnlUb1ICdG8SMAoHc2VydmljZRgMIAEoCzIWLmMzNS5UeERlbGl2ZXJ5U2Vydm'
    'ljZVIHc2VydmljZRIVCgVzdGF0ZRjIASABKAlSBXN0YXRl');

@$core.Deprecated('Use txDeliveryToDescriptor instead')
const TxDeliveryTo$json = {
  '1': 'TxDeliveryTo',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'phone', '3': 2, '4': 1, '5': 9, '10': 'phone'},
    {'1': 'address', '3': 3, '4': 1, '5': 9, '10': 'address'},
    {'1': 'email', '3': 4, '4': 1, '5': 9, '10': 'email'},
  ],
};

/// Descriptor for `TxDeliveryTo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List txDeliveryToDescriptor = $convert.base64Decode(
    'CgxUeERlbGl2ZXJ5VG8SEgoEbmFtZRgBIAEoCVIEbmFtZRIUCgVwaG9uZRgCIAEoCVIFcGhvbm'
    'USGAoHYWRkcmVzcxgDIAEoCVIHYWRkcmVzcxIUCgVlbWFpbBgEIAEoCVIFZW1haWw=');

@$core.Deprecated('Use txDeliveryServiceDescriptor instead')
const TxDeliveryService$json = {
  '1': 'TxDeliveryService',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'tracking_number', '3': 2, '4': 1, '5': 9, '10': 'trackingNumber'},
    {'1': 'tracking_url', '3': 3, '4': 1, '5': 9, '10': 'trackingUrl'},
    {'1': 'note', '3': 4, '4': 1, '5': 9, '10': 'note'},
  ],
};

/// Descriptor for `TxDeliveryService`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List txDeliveryServiceDescriptor = $convert.base64Decode(
    'ChFUeERlbGl2ZXJ5U2VydmljZRISCgRuYW1lGAEgASgJUgRuYW1lEicKD3RyYWNraW5nX251bW'
    'JlchgCIAEoCVIOdHJhY2tpbmdOdW1iZXISIQoMdHJhY2tpbmdfdXJsGAMgASgJUgt0cmFja2lu'
    'Z1VybBISCgRub3RlGAQgASgJUgRub3Rl');

@$core.Deprecated('Use txDiscountDescriptor instead')
const TxDiscount$json = {
  '1': 'TxDiscount',
  '2': [
    {'1': 'discount_id', '3': 3, '4': 1, '5': 3, '10': 'discountId'},
    {'1': 'discount_type', '3': 10, '4': 1, '5': 9, '10': 'discountType'},
    {'1': 'amount', '3': 11, '4': 1, '5': 3, '10': 'amount'},
    {'1': 'note', '3': 12, '4': 1, '5': 9, '10': 'note'},
  ],
};

/// Descriptor for `TxDiscount`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List txDiscountDescriptor = $convert.base64Decode(
    'CgpUeERpc2NvdW50Eh8KC2Rpc2NvdW50X2lkGAMgASgDUgpkaXNjb3VudElkEiMKDWRpc2NvdW'
    '50X3R5cGUYCiABKAlSDGRpc2NvdW50VHlwZRIWCgZhbW91bnQYCyABKANSBmFtb3VudBISCgRu'
    'b3RlGAwgASgJUgRub3Rl');

@$core.Deprecated('Use txTaxDescriptor instead')
const TxTax$json = {
  '1': 'TxTax',
  '2': [
    {'1': 'tax_id', '3': 3, '4': 1, '5': 3, '10': 'taxId'},
    {'1': 'tax_type', '3': 10, '4': 1, '5': 9, '10': 'taxType'},
    {'1': 'amount', '3': 11, '4': 1, '5': 3, '10': 'amount'},
    {'1': 'note', '3': 12, '4': 1, '5': 9, '10': 'note'},
  ],
};

/// Descriptor for `TxTax`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List txTaxDescriptor = $convert.base64Decode(
    'CgVUeFRheBIVCgZ0YXhfaWQYAyABKANSBXRheElkEhkKCHRheF90eXBlGAogASgJUgd0YXhUeX'
    'BlEhYKBmFtb3VudBgLIAEoA1IGYW1vdW50EhIKBG5vdGUYDCABKAlSBG5vdGU=');

@$core.Deprecated('Use txPromoDescriptor instead')
const TxPromo$json = {
  '1': 'TxPromo',
  '2': [
    {'1': 'promo_id', '3': 1, '4': 1, '5': 9, '10': 'promoId'},
    {'1': 'code', '3': 2, '4': 1, '5': 9, '10': 'code'},
    {'1': 'name', '3': 3, '4': 1, '5': 9, '10': 'name'},
    {'1': 'amount', '3': 4, '4': 1, '5': 3, '10': 'amount'},
  ],
};

/// Descriptor for `TxPromo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List txPromoDescriptor = $convert.base64Decode(
    'CgdUeFByb21vEhkKCHByb21vX2lkGAEgASgJUgdwcm9tb0lkEhIKBGNvZGUYAiABKAlSBGNvZG'
    'USEgoEbmFtZRgDIAEoCVIEbmFtZRIWCgZhbW91bnQYBCABKANSBmFtb3VudA==');

@$core.Deprecated('Use txPaymentDescriptor instead')
const TxPayment$json = {
  '1': 'TxPayment',
  '2': [
    {'1': 'payment_id', '3': 3, '4': 1, '5': 3, '10': 'paymentId'},
    {
      '1': 'method',
      '3': 10,
      '4': 1,
      '5': 14,
      '6': '.c35.TxPaymentMethod',
      '10': 'method'
    },
    {'1': 'ts_ms', '3': 11, '4': 1, '5': 3, '10': 'tsMs'},
    {'1': 'amount', '3': 12, '4': 1, '5': 3, '10': 'amount'},
    {'1': 'note', '3': 13, '4': 1, '5': 9, '10': 'note'},
    {'1': 'from_wallet', '3': 20, '4': 1, '5': 9, '10': 'fromWallet'},
    {'1': 'to_wallet', '3': 21, '4': 1, '5': 9, '10': 'toWallet'},
    {'1': 'debt_interest', '3': 25, '4': 1, '5': 3, '10': 'debtInterest'},
    {'1': 'payment_json', '3': 100, '4': 1, '5': 9, '10': 'paymentJson'},
    {
      '1': 'installments',
      '3': 110,
      '4': 3,
      '5': 11,
      '6': '.c35.TxInstallment',
      '10': 'installments'
    },
  ],
};

/// Descriptor for `TxPayment`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List txPaymentDescriptor = $convert.base64Decode(
    'CglUeFBheW1lbnQSHQoKcGF5bWVudF9pZBgDIAEoA1IJcGF5bWVudElkEiwKBm1ldGhvZBgKIA'
    'EoDjIULmMzNS5UeFBheW1lbnRNZXRob2RSBm1ldGhvZBITCgV0c19tcxgLIAEoA1IEdHNNcxIW'
    'CgZhbW91bnQYDCABKANSBmFtb3VudBISCgRub3RlGA0gASgJUgRub3RlEh8KC2Zyb21fd2FsbG'
    'V0GBQgASgJUgpmcm9tV2FsbGV0EhsKCXRvX3dhbGxldBgVIAEoCVIIdG9XYWxsZXQSIwoNZGVi'
    'dF9pbnRlcmVzdBgZIAEoA1IMZGVidEludGVyZXN0EiEKDHBheW1lbnRfanNvbhhkIAEoCVILcG'
    'F5bWVudEpzb24SNgoMaW5zdGFsbG1lbnRzGG4gAygLMhIuYzM1LlR4SW5zdGFsbG1lbnRSDGlu'
    'c3RhbGxtZW50cw==');

@$core.Deprecated('Use txInstallmentDescriptor instead')
const TxInstallment$json = {
  '1': 'TxInstallment',
  '2': [
    {'1': 'inst_id', '3': 4, '4': 1, '5': 3, '10': 'instId'},
    {'1': 'due_ts_ms', '3': 10, '4': 1, '5': 3, '10': 'dueTsMs'},
    {'1': 'amount', '3': 11, '4': 1, '5': 3, '10': 'amount'},
    {'1': 'note', '3': 12, '4': 1, '5': 9, '10': 'note'},
    {'1': 'is_paid', '3': 21, '4': 1, '5': 8, '10': 'isPaid'},
    {'1': 'is_overdue', '3': 22, '4': 1, '5': 8, '10': 'isOverdue'},
    {
      '1': 'debt_payments',
      '3': 30,
      '4': 3,
      '5': 11,
      '6': '.c35.TxDebtPayment',
      '10': 'debtPayments'
    },
  ],
};

/// Descriptor for `TxInstallment`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List txInstallmentDescriptor = $convert.base64Decode(
    'Cg1UeEluc3RhbGxtZW50EhcKB2luc3RfaWQYBCABKANSBmluc3RJZBIaCglkdWVfdHNfbXMYCi'
    'ABKANSB2R1ZVRzTXMSFgoGYW1vdW50GAsgASgDUgZhbW91bnQSEgoEbm90ZRgMIAEoCVIEbm90'
    'ZRIXCgdpc19wYWlkGBUgASgIUgZpc1BhaWQSHQoKaXNfb3ZlcmR1ZRgWIAEoCFIJaXNPdmVyZH'
    'VlEjcKDWRlYnRfcGF5bWVudHMYHiADKAsyEi5jMzUuVHhEZWJ0UGF5bWVudFIMZGVidFBheW1l'
    'bnRz');

@$core.Deprecated('Use txDebtPaymentDescriptor instead')
const TxDebtPayment$json = {
  '1': 'TxDebtPayment',
  '2': [
    {'1': 'pay_id', '3': 5, '4': 1, '5': 3, '10': 'payId'},
    {'1': 'ts_ms', '3': 10, '4': 1, '5': 3, '10': 'tsMs'},
    {
      '1': 'method',
      '3': 11,
      '4': 1,
      '5': 14,
      '6': '.c35.TxDebtPaymentMethod',
      '10': 'method'
    },
    {'1': 'amount', '3': 12, '4': 1, '5': 3, '10': 'amount'},
    {'1': 'note', '3': 13, '4': 1, '5': 9, '10': 'note'},
    {'1': 'overdue_interest', '3': 14, '4': 1, '5': 3, '10': 'overdueInterest'},
    {'1': 'payment_json', '3': 100, '4': 1, '5': 9, '10': 'paymentJson'},
  ],
};

/// Descriptor for `TxDebtPayment`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List txDebtPaymentDescriptor = $convert.base64Decode(
    'Cg1UeERlYnRQYXltZW50EhUKBnBheV9pZBgFIAEoA1IFcGF5SWQSEwoFdHNfbXMYCiABKANSBH'
    'RzTXMSMAoGbWV0aG9kGAsgASgOMhguYzM1LlR4RGVidFBheW1lbnRNZXRob2RSBm1ldGhvZBIW'
    'CgZhbW91bnQYDCABKANSBmFtb3VudBISCgRub3RlGA0gASgJUgRub3RlEikKEG92ZXJkdWVfaW'
    '50ZXJlc3QYDiABKANSD292ZXJkdWVJbnRlcmVzdBIhCgxwYXltZW50X2pzb24YZCABKAlSC3Bh'
    'eW1lbnRKc29u');

@$core.Deprecated('Use txAccDescriptor instead')
const TxAcc$json = {
  '1': 'TxAcc',
  '2': [
    {'1': 'acc_id', '3': 3, '4': 1, '5': 3, '10': 'accId'},
    {'1': 'acc_code', '3': 10, '4': 1, '5': 9, '10': 'accCode'},
    {'1': 'ts_ms', '3': 11, '4': 1, '5': 3, '10': 'tsMs'},
    {
      '1': 'side',
      '3': 12,
      '4': 1,
      '5': 14,
      '6': '.c35.TxAccSide',
      '10': 'side'
    },
    {'1': 'amount', '3': 13, '4': 1, '5': 3, '10': 'amount'},
    {'1': 'note', '3': 14, '4': 1, '5': 9, '10': 'note'},
    {'1': 'is_tx_generated', '3': 20, '4': 1, '5': 8, '10': 'isTxGenerated'},
  ],
};

/// Descriptor for `TxAcc`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List txAccDescriptor = $convert.base64Decode(
    'CgVUeEFjYxIVCgZhY2NfaWQYAyABKANSBWFjY0lkEhkKCGFjY19jb2RlGAogASgJUgdhY2NDb2'
    'RlEhMKBXRzX21zGAsgASgDUgR0c01zEiIKBHNpZGUYDCABKA4yDi5jMzUuVHhBY2NTaWRlUgRz'
    'aWRlEhYKBmFtb3VudBgNIAEoA1IGYW1vdW50EhIKBG5vdGUYDiABKAlSBG5vdGUSJgoPaXNfdH'
    'hfZ2VuZXJhdGVkGBQgASgIUg1pc1R4R2VuZXJhdGVk');

@$core.Deprecated('Use txStockDescriptor instead')
const TxStock$json = {
  '1': 'TxStock',
  '2': [
    {'1': 'stock_id', '3': 3, '4': 1, '5': 3, '10': 'stockId'},
    {'1': 'product_id', '3': 10, '4': 1, '5': 3, '10': 'productId'},
    {'1': 'ts_ms', '3': 11, '4': 1, '5': 3, '10': 'tsMs'},
    {'1': 'obj_from_id', '3': 20, '4': 1, '5': 3, '10': 'objFromId'},
    {'1': 'obj_to_id', '3': 21, '4': 1, '5': 3, '10': 'objToId'},
    {'1': 'qty', '3': 30, '4': 1, '5': 5, '10': 'qty'},
    {'1': 'qty_signed', '3': 31, '4': 1, '5': 5, '10': 'qtySigned'},
    {'1': 'direction', '3': 32, '4': 1, '5': 9, '10': 'direction'},
    {'1': 'note', '3': 33, '4': 1, '5': 9, '10': 'note'},
  ],
};

/// Descriptor for `TxStock`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List txStockDescriptor = $convert.base64Decode(
    'CgdUeFN0b2NrEhkKCHN0b2NrX2lkGAMgASgDUgdzdG9ja0lkEh0KCnByb2R1Y3RfaWQYCiABKA'
    'NSCXByb2R1Y3RJZBITCgV0c19tcxgLIAEoA1IEdHNNcxIeCgtvYmpfZnJvbV9pZBgUIAEoA1IJ'
    'b2JqRnJvbUlkEhoKCW9ial90b19pZBgVIAEoA1IHb2JqVG9JZBIQCgNxdHkYHiABKAVSA3F0eR'
    'IdCgpxdHlfc2lnbmVkGB8gASgFUglxdHlTaWduZWQSHAoJZGlyZWN0aW9uGCAgASgJUglkaXJl'
    'Y3Rpb24SEgoEbm90ZRghIAEoCVIEbm90ZQ==');

@$core.Deprecated('Use reqTxGetDescriptor instead')
const ReqTxGet$json = {
  '1': 'ReqTxGet',
  '2': [
    {'1': 'site_iid', '3': 1, '4': 1, '5': 3, '10': 'siteIid'},
    {'1': 'tx_id', '3': 2, '4': 1, '5': 3, '10': 'txId'},
  ],
};

/// Descriptor for `ReqTxGet`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqTxGetDescriptor = $convert.base64Decode(
    'CghSZXFUeEdldBIZCghzaXRlX2lpZBgBIAEoA1IHc2l0ZUlpZBITCgV0eF9pZBgCIAEoA1IEdH'
    'hJZA==');

@$core.Deprecated('Use resTxGetDescriptor instead')
const ResTxGet$json = {
  '1': 'ResTxGet',
  '2': [
    {'1': 'tx', '3': 1, '4': 1, '5': 11, '6': '.c35.Tx', '10': 'tx'},
  ],
};

/// Descriptor for `ResTxGet`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resTxGetDescriptor =
    $convert.base64Decode('CghSZXNUeEdldBIXCgJ0eBgBIAEoCzIHLmMzNS5UeFICdHg=');

@$core.Deprecated('Use reqTxListDescriptor instead')
const ReqTxList$json = {
  '1': 'ReqTxList',
  '2': [
    {'1': 'site_iid', '3': 1, '4': 1, '5': 3, '10': 'siteIid'},
    {'1': 'q', '3': 2, '4': 1, '5': 9, '10': 'q'},
    {'1': 'after_tx_id', '3': 3, '4': 1, '5': 3, '10': 'afterTxId'},
    {'1': 'limit', '3': 4, '4': 1, '5': 5, '10': 'limit'},
    {'1': 'include_archived', '3': 5, '4': 1, '5': 8, '10': 'includeArchived'},
    {'1': 'type', '3': 6, '4': 1, '5': 14, '6': '.c35.TxType', '10': 'type'},
    {'1': 'state', '3': 7, '4': 1, '5': 14, '6': '.c35.TxState', '10': 'state'},
    {
      '1': 'subject_contact_id',
      '3': 10,
      '4': 1,
      '5': 3,
      '10': 'subjectContactId'
    },
    {'1': 'time_from_ms', '3': 11, '4': 1, '5': 3, '10': 'timeFromMs'},
    {'1': 'time_to_ms', '3': 12, '4': 1, '5': 3, '10': 'timeToMs'},
    {'1': 'open_only', '3': 15, '4': 1, '5': 8, '10': 'openOnly'},
  ],
};

/// Descriptor for `ReqTxList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqTxListDescriptor = $convert.base64Decode(
    'CglSZXFUeExpc3QSGQoIc2l0ZV9paWQYASABKANSB3NpdGVJaWQSDAoBcRgCIAEoCVIBcRIeCg'
    'thZnRlcl90eF9pZBgDIAEoA1IJYWZ0ZXJUeElkEhQKBWxpbWl0GAQgASgFUgVsaW1pdBIpChBp'
    'bmNsdWRlX2FyY2hpdmVkGAUgASgIUg9pbmNsdWRlQXJjaGl2ZWQSHwoEdHlwZRgGIAEoDjILLm'
    'MzNS5UeFR5cGVSBHR5cGUSIgoFc3RhdGUYByABKA4yDC5jMzUuVHhTdGF0ZVIFc3RhdGUSLAoS'
    'c3ViamVjdF9jb250YWN0X2lkGAogASgDUhBzdWJqZWN0Q29udGFjdElkEiAKDHRpbWVfZnJvbV'
    '9tcxgLIAEoA1IKdGltZUZyb21NcxIcCgp0aW1lX3RvX21zGAwgASgDUgh0aW1lVG9NcxIbCglv'
    'cGVuX29ubHkYDyABKAhSCG9wZW5Pbmx5');

@$core.Deprecated('Use resTxListDescriptor instead')
const ResTxList$json = {
  '1': 'ResTxList',
  '2': [
    {'1': 'txs', '3': 1, '4': 3, '5': 11, '6': '.c35.Tx', '10': 'txs'},
  ],
};

/// Descriptor for `ResTxList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resTxListDescriptor = $convert
    .base64Decode('CglSZXNUeExpc3QSGQoDdHhzGAEgAygLMgcuYzM1LlR4UgN0eHM=');

@$core.Deprecated('Use reqTxPutDescriptor instead')
const ReqTxPut$json = {
  '1': 'ReqTxPut',
  '2': [
    {'1': 'tx', '3': 1, '4': 1, '5': 11, '6': '.c35.Tx', '10': 'tx'},
  ],
};

/// Descriptor for `ReqTxPut`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqTxPutDescriptor =
    $convert.base64Decode('CghSZXFUeFB1dBIXCgJ0eBgBIAEoCzIHLmMzNS5UeFICdHg=');

@$core.Deprecated('Use resTxPutDescriptor instead')
const ResTxPut$json = {
  '1': 'ResTxPut',
  '2': [
    {'1': 'tx', '3': 1, '4': 1, '5': 11, '6': '.c35.Tx', '10': 'tx'},
  ],
};

/// Descriptor for `ResTxPut`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resTxPutDescriptor =
    $convert.base64Decode('CghSZXNUeFB1dBIXCgJ0eBgBIAEoCzIHLmMzNS5UeFICdHg=');

@$core.Deprecated('Use reqTxPreviewDescriptor instead')
const ReqTxPreview$json = {
  '1': 'ReqTxPreview',
  '2': [
    {'1': 'tx', '3': 1, '4': 1, '5': 11, '6': '.c35.Tx', '10': 'tx'},
  ],
};

/// Descriptor for `ReqTxPreview`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqTxPreviewDescriptor = $convert
    .base64Decode('CgxSZXFUeFByZXZpZXcSFwoCdHgYASABKAsyBy5jMzUuVHhSAnR4');

@$core.Deprecated('Use resTxPreviewDescriptor instead')
const ResTxPreview$json = {
  '1': 'ResTxPreview',
  '2': [
    {'1': 'tx', '3': 1, '4': 1, '5': 11, '6': '.c35.Tx', '10': 'tx'},
    {
      '1': 'coa_name',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.c35.ResTxPreview.CoaNameEntry',
      '10': 'coaName'
    },
  ],
  '3': [ResTxPreview_CoaNameEntry$json],
};

@$core.Deprecated('Use resTxPreviewDescriptor instead')
const ResTxPreview_CoaNameEntry$json = {
  '1': 'CoaNameEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `ResTxPreview`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resTxPreviewDescriptor = $convert.base64Decode(
    'CgxSZXNUeFByZXZpZXcSFwoCdHgYASABKAsyBy5jMzUuVHhSAnR4EjkKCGNvYV9uYW1lGAIgAy'
    'gLMh4uYzM1LlJlc1R4UHJldmlldy5Db2FOYW1lRW50cnlSB2NvYU5hbWUaOgoMQ29hTmFtZUVu'
    'dHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAE=');

@$core.Deprecated('Use reqTxDebtPayDescriptor instead')
const ReqTxDebtPay$json = {
  '1': 'ReqTxDebtPay',
  '2': [
    {'1': 'site_iid', '3': 1, '4': 1, '5': 3, '10': 'siteIid'},
    {'1': 'tx_id', '3': 2, '4': 1, '5': 3, '10': 'txId'},
    {
      '1': 'payment',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.c35.TxDebtPayment',
      '10': 'payment'
    },
  ],
};

/// Descriptor for `ReqTxDebtPay`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqTxDebtPayDescriptor = $convert.base64Decode(
    'CgxSZXFUeERlYnRQYXkSGQoIc2l0ZV9paWQYASABKANSB3NpdGVJaWQSEwoFdHhfaWQYAiABKA'
    'NSBHR4SWQSLAoHcGF5bWVudBgDIAEoCzISLmMzNS5UeERlYnRQYXltZW50UgdwYXltZW50');

@$core.Deprecated('Use resTxDebtPayDescriptor instead')
const ResTxDebtPay$json = {
  '1': 'ResTxDebtPay',
  '2': [
    {'1': 'tx', '3': 1, '4': 1, '5': 11, '6': '.c35.Tx', '10': 'tx'},
  ],
};

/// Descriptor for `ResTxDebtPay`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resTxDebtPayDescriptor = $convert
    .base64Decode('CgxSZXNUeERlYnRQYXkSFwoCdHgYASABKAsyBy5jMzUuVHhSAnR4');

@$core.Deprecated('Use reqSiteGuestOrderPutDescriptor instead')
const ReqSiteGuestOrderPut$json = {
  '1': 'ReqSiteGuestOrderPut',
  '2': [
    {'1': 'site_iid', '3': 1, '4': 1, '5': 3, '10': 'siteIid'},
    {'1': 'tx', '3': 2, '4': 1, '5': 11, '6': '.c35.Tx', '10': 'tx'},
  ],
};

/// Descriptor for `ReqSiteGuestOrderPut`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqSiteGuestOrderPutDescriptor = $convert.base64Decode(
    'ChRSZXFTaXRlR3Vlc3RPcmRlclB1dBIZCghzaXRlX2lpZBgBIAEoA1IHc2l0ZUlpZBIXCgJ0eB'
    'gCIAEoCzIHLmMzNS5UeFICdHg=');

@$core.Deprecated('Use resSiteGuestOrderPutDescriptor instead')
const ResSiteGuestOrderPut$json = {
  '1': 'ResSiteGuestOrderPut',
  '2': [
    {'1': 'tx', '3': 1, '4': 1, '5': 11, '6': '.c35.Tx', '10': 'tx'},
  ],
};

/// Descriptor for `ResSiteGuestOrderPut`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resSiteGuestOrderPutDescriptor =
    $convert.base64Decode(
        'ChRSZXNTaXRlR3Vlc3RPcmRlclB1dBIXCgJ0eBgBIAEoCzIHLmMzNS5UeFICdHg=');

@$core.Deprecated('Use reqSiteGuestOrderGetDescriptor instead')
const ReqSiteGuestOrderGet$json = {
  '1': 'ReqSiteGuestOrderGet',
  '2': [
    {'1': 'site_iid', '3': 1, '4': 1, '5': 3, '10': 'siteIid'},
    {'1': 'tx_id', '3': 2, '4': 1, '5': 3, '10': 'txId'},
  ],
};

/// Descriptor for `ReqSiteGuestOrderGet`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqSiteGuestOrderGetDescriptor = $convert.base64Decode(
    'ChRSZXFTaXRlR3Vlc3RPcmRlckdldBIZCghzaXRlX2lpZBgBIAEoA1IHc2l0ZUlpZBITCgV0eF'
    '9pZBgCIAEoA1IEdHhJZA==');

@$core.Deprecated('Use resSiteGuestOrderGetDescriptor instead')
const ResSiteGuestOrderGet$json = {
  '1': 'ResSiteGuestOrderGet',
  '2': [
    {'1': 'tx', '3': 1, '4': 1, '5': 11, '6': '.c35.Tx', '10': 'tx'},
  ],
};

/// Descriptor for `ResSiteGuestOrderGet`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resSiteGuestOrderGetDescriptor =
    $convert.base64Decode(
        'ChRSZXNTaXRlR3Vlc3RPcmRlckdldBIXCgJ0eBgBIAEoCzIHLmMzNS5UeFICdHg=');
