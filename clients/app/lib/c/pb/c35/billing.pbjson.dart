//
//  Generated code. Do not modify.
//  source: c35/billing.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use billingAccountDescriptor instead')
const BillingAccount$json = {
  '1': 'BillingAccount',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 3, '10': 'id'},
    {'1': 'owner_iid', '3': 2, '4': 1, '5': 3, '10': 'ownerIid'},
    {'1': 'name', '3': 3, '4': 1, '5': 9, '10': 'name'},
    {'1': 'balance_usd', '3': 4, '4': 1, '5': 1, '10': 'balanceUsd'},
    {'1': 'balance_idr', '3': 5, '4': 1, '5': 1, '10': 'balanceIdr'},
    {'1': 'plan_tier', '3': 6, '4': 1, '5': 9, '10': 'planTier'},
    {'1': 'alien_allow_5h_used', '3': 7, '4': 1, '5': 1, '10': 'alienAllow5hUsed'},
    {'1': 'alien_allow_5h_limit', '3': 8, '4': 1, '5': 1, '10': 'alienAllow5hLimit'},
    {'1': 'alien_allow_weekly_used', '3': 9, '4': 1, '5': 1, '10': 'alienAllowWeeklyUsed'},
    {'1': 'alien_allow_weekly_limit', '3': 10, '4': 1, '5': 1, '10': 'alienAllowWeeklyLimit'},
    {'1': 'window_5h_start_ms', '3': 11, '4': 1, '5': 3, '10': 'window5hStartMs'},
    {'1': 'window_weekly_start_ms', '3': 12, '4': 1, '5': 3, '10': 'windowWeeklyStartMs'},
    {'1': 'billing_currency', '3': 13, '4': 1, '5': 9, '10': 'billingCurrency'},
    {'1': 'fx_micro_per_usd', '3': 14, '4': 1, '5': 3, '10': 'fxMicroPerUsd'},
    {'1': 'commission_available_usd', '3': 15, '4': 1, '5': 1, '10': 'commissionAvailableUsd'},
    {'1': 'commission_earned_usd', '3': 16, '4': 1, '5': 1, '10': 'commissionEarnedUsd'},
    {'1': 'commission_available_idr', '3': 17, '4': 1, '5': 1, '10': 'commissionAvailableIdr'},
    {'1': 'commission_earned_idr', '3': 18, '4': 1, '5': 1, '10': 'commissionEarnedIdr'},
    {'1': 'meta_json', '3': 19, '4': 1, '5': 9, '10': 'metaJson'},
    {'1': 'created_ts_ms', '3': 20, '4': 1, '5': 3, '10': 'createdTsMs'},
    {'1': 'updated_ts_ms', '3': 21, '4': 1, '5': 3, '10': 'updatedTsMs'},
    {'1': 'deleted_ts_ms', '3': 22, '4': 1, '5': 3, '10': 'deletedTsMs'},
  ],
};

/// Descriptor for `BillingAccount`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List billingAccountDescriptor = $convert.base64Decode(
    'Cg5CaWxsaW5nQWNjb3VudBIOCgJpZBgBIAEoA1ICaWQSGwoJb3duZXJfaWlkGAIgASgDUghvd2'
    '5lcklpZBISCgRuYW1lGAMgASgJUgRuYW1lEh8KC2JhbGFuY2VfdXNkGAQgASgBUgpiYWxhbmNl'
    'VXNkEh8KC2JhbGFuY2VfaWRyGAUgASgBUgpiYWxhbmNlSWRyEhsKCXBsYW5fdGllchgGIAEoCV'
    'IIcGxhblRpZXISLQoTYWxpZW5fYWxsb3dfNWhfdXNlZBgHIAEoAVIQYWxpZW5BbGxvdzVoVXNl'
    'ZBIvChRhbGllbl9hbGxvd181aF9saW1pdBgIIAEoAVIRYWxpZW5BbGxvdzVoTGltaXQSNQoXYW'
    'xpZW5fYWxsb3dfd2Vla2x5X3VzZWQYCSABKAFSFGFsaWVuQWxsb3dXZWVrbHlVc2VkEjcKGGFs'
    'aWVuX2FsbG93X3dlZWtseV9saW1pdBgKIAEoAVIVYWxpZW5BbGxvd1dlZWtseUxpbWl0EisKEn'
    'dpbmRvd181aF9zdGFydF9tcxgLIAEoA1IPd2luZG93NWhTdGFydE1zEjMKFndpbmRvd193ZWVr'
    'bHlfc3RhcnRfbXMYDCABKANSE3dpbmRvd1dlZWtseVN0YXJ0TXMSKQoQYmlsbGluZ19jdXJyZW'
    '5jeRgNIAEoCVIPYmlsbGluZ0N1cnJlbmN5EicKEGZ4X21pY3JvX3Blcl91c2QYDiABKANSDWZ4'
    'TWljcm9QZXJVc2QSOAoYY29tbWlzc2lvbl9hdmFpbGFibGVfdXNkGA8gASgBUhZjb21taXNzaW'
    '9uQXZhaWxhYmxlVXNkEjIKFWNvbW1pc3Npb25fZWFybmVkX3VzZBgQIAEoAVITY29tbWlzc2lv'
    'bkVhcm5lZFVzZBI4Chhjb21taXNzaW9uX2F2YWlsYWJsZV9pZHIYESABKAFSFmNvbW1pc3Npb2'
    '5BdmFpbGFibGVJZHISMgoVY29tbWlzc2lvbl9lYXJuZWRfaWRyGBIgASgBUhNjb21taXNzaW9u'
    'RWFybmVkSWRyEhsKCW1ldGFfanNvbhgTIAEoCVIIbWV0YUpzb24SIgoNY3JlYXRlZF90c19tcx'
    'gUIAEoA1ILY3JlYXRlZFRzTXMSIgoNdXBkYXRlZF90c19tcxgVIAEoA1ILdXBkYXRlZFRzTXMS'
    'IgoNZGVsZXRlZF90c19tcxgWIAEoA1ILZGVsZXRlZFRzTXM=');

@$core.Deprecated('Use billingTopupRequestDescriptor instead')
const BillingTopupRequest$json = {
  '1': 'BillingTopupRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 3, '10': 'id'},
    {'1': 'owner_iid', '3': 2, '4': 1, '5': 3, '10': 'ownerIid'},
    {'1': 'billing_account_id', '3': 3, '4': 1, '5': 3, '10': 'billingAccountId'},
    {'1': 'amount_usd', '3': 4, '4': 1, '5': 1, '10': 'amountUsd'},
    {'1': 'amount_idr', '3': 5, '4': 1, '5': 1, '10': 'amountIdr'},
    {'1': 'provider', '3': 6, '4': 1, '5': 9, '10': 'provider'},
    {'1': 'payment_type', '3': 7, '4': 1, '5': 9, '10': 'paymentType'},
    {'1': 'external_order_id', '3': 8, '4': 1, '5': 9, '10': 'externalOrderId'},
    {'1': 'proof_url', '3': 9, '4': 1, '5': 9, '10': 'proofUrl'},
    {'1': 'status', '3': 10, '4': 1, '5': 9, '10': 'status'},
    {'1': 'reject_reason', '3': 11, '4': 1, '5': 9, '10': 'rejectReason'},
    {'1': 'reviewed_by_iid', '3': 12, '4': 1, '5': 3, '10': 'reviewedByIid'},
    {'1': 'settled_ts_ms', '3': 13, '4': 1, '5': 3, '10': 'settledTsMs'},
    {'1': 'created_ts_ms', '3': 14, '4': 1, '5': 3, '10': 'createdTsMs'},
    {'1': 'updated_ts_ms', '3': 15, '4': 1, '5': 3, '10': 'updatedTsMs'},
  ],
};

/// Descriptor for `BillingTopupRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List billingTopupRequestDescriptor = $convert.base64Decode(
    'ChNCaWxsaW5nVG9wdXBSZXF1ZXN0Eg4KAmlkGAEgASgDUgJpZBIbCglvd25lcl9paWQYAiABKA'
    'NSCG93bmVySWlkEiwKEmJpbGxpbmdfYWNjb3VudF9pZBgDIAEoA1IQYmlsbGluZ0FjY291bnRJ'
    'ZBIdCgphbW91bnRfdXNkGAQgASgBUglhbW91bnRVc2QSHQoKYW1vdW50X2lkchgFIAEoAVIJYW'
    '1vdW50SWRyEhoKCHByb3ZpZGVyGAYgASgJUghwcm92aWRlchIhCgxwYXltZW50X3R5cGUYByAB'
    'KAlSC3BheW1lbnRUeXBlEioKEWV4dGVybmFsX29yZGVyX2lkGAggASgJUg9leHRlcm5hbE9yZG'
    'VySWQSGwoJcHJvb2ZfdXJsGAkgASgJUghwcm9vZlVybBIWCgZzdGF0dXMYCiABKAlSBnN0YXR1'
    'cxIjCg1yZWplY3RfcmVhc29uGAsgASgJUgxyZWplY3RSZWFzb24SJgoPcmV2aWV3ZWRfYnlfaW'
    'lkGAwgASgDUg1yZXZpZXdlZEJ5SWlkEiIKDXNldHRsZWRfdHNfbXMYDSABKANSC3NldHRsZWRU'
    'c01zEiIKDWNyZWF0ZWRfdHNfbXMYDiABKANSC2NyZWF0ZWRUc01zEiIKDXVwZGF0ZWRfdHNfbX'
    'MYDyABKANSC3VwZGF0ZWRUc01z');

@$core.Deprecated('Use billingPushBalanceDescriptor instead')
const BillingPushBalance$json = {
  '1': 'BillingPushBalance',
  '2': [
    {'1': 'billing_account_id', '3': 1, '4': 1, '5': 3, '10': 'billingAccountId'},
    {'1': 'balance_usd', '3': 2, '4': 1, '5': 1, '10': 'balanceUsd'},
    {'1': 'balance_idr', '3': 3, '4': 1, '5': 1, '10': 'balanceIdr'},
    {'1': 'updated_ts_ms', '3': 4, '4': 1, '5': 3, '10': 'updatedTsMs'},
  ],
};

/// Descriptor for `BillingPushBalance`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List billingPushBalanceDescriptor = $convert.base64Decode(
    'ChJCaWxsaW5nUHVzaEJhbGFuY2USLAoSYmlsbGluZ19hY2NvdW50X2lkGAEgASgDUhBiaWxsaW'
    '5nQWNjb3VudElkEh8KC2JhbGFuY2VfdXNkGAIgASgBUgpiYWxhbmNlVXNkEh8KC2JhbGFuY2Vf'
    'aWRyGAMgASgBUgpiYWxhbmNlSWRyEiIKDXVwZGF0ZWRfdHNfbXMYBCABKANSC3VwZGF0ZWRUc0'
    '1z');

@$core.Deprecated('Use billingPushQuotaDescriptor instead')
const BillingPushQuota$json = {
  '1': 'BillingPushQuota',
  '2': [
    {'1': 'alien_allow_5h_used', '3': 1, '4': 1, '5': 1, '10': 'alienAllow5hUsed'},
    {'1': 'alien_allow_5h_limit', '3': 2, '4': 1, '5': 1, '10': 'alienAllow5hLimit'},
    {'1': 'alien_allow_weekly_used', '3': 3, '4': 1, '5': 1, '10': 'alienAllowWeeklyUsed'},
    {'1': 'alien_allow_weekly_limit', '3': 4, '4': 1, '5': 1, '10': 'alienAllowWeeklyLimit'},
    {'1': 'window_5h_start_ms', '3': 5, '4': 1, '5': 3, '10': 'window5hStartMs'},
    {'1': 'window_weekly_start_ms', '3': 6, '4': 1, '5': 3, '10': 'windowWeeklyStartMs'},
  ],
};

/// Descriptor for `BillingPushQuota`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List billingPushQuotaDescriptor = $convert.base64Decode(
    'ChBCaWxsaW5nUHVzaFF1b3RhEi0KE2FsaWVuX2FsbG93XzVoX3VzZWQYASABKAFSEGFsaWVuQW'
    'xsb3c1aFVzZWQSLwoUYWxpZW5fYWxsb3dfNWhfbGltaXQYAiABKAFSEWFsaWVuQWxsb3c1aExp'
    'bWl0EjUKF2FsaWVuX2FsbG93X3dlZWtseV91c2VkGAMgASgBUhRhbGllbkFsbG93V2Vla2x5VX'
    'NlZBI3ChhhbGllbl9hbGxvd193ZWVrbHlfbGltaXQYBCABKAFSFWFsaWVuQWxsb3dXZWVrbHlM'
    'aW1pdBIrChJ3aW5kb3dfNWhfc3RhcnRfbXMYBSABKANSD3dpbmRvdzVoU3RhcnRNcxIzChZ3aW'
    '5kb3dfd2Vla2x5X3N0YXJ0X21zGAYgASgDUhN3aW5kb3dXZWVrbHlTdGFydE1z');

@$core.Deprecated('Use billingPushCommissionDescriptor instead')
const BillingPushCommission$json = {
  '1': 'BillingPushCommission',
  '2': [
    {'1': 'commission_available_usd', '3': 1, '4': 1, '5': 1, '10': 'commissionAvailableUsd'},
    {'1': 'commission_earned_usd', '3': 2, '4': 1, '5': 1, '10': 'commissionEarnedUsd'},
    {'1': 'commission_available_idr', '3': 3, '4': 1, '5': 1, '10': 'commissionAvailableIdr'},
    {'1': 'commission_earned_idr', '3': 4, '4': 1, '5': 1, '10': 'commissionEarnedIdr'},
  ],
};

/// Descriptor for `BillingPushCommission`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List billingPushCommissionDescriptor = $convert.base64Decode(
    'ChVCaWxsaW5nUHVzaENvbW1pc3Npb24SOAoYY29tbWlzc2lvbl9hdmFpbGFibGVfdXNkGAEgAS'
    'gBUhZjb21taXNzaW9uQXZhaWxhYmxlVXNkEjIKFWNvbW1pc3Npb25fZWFybmVkX3VzZBgCIAEo'
    'AVITY29tbWlzc2lvbkVhcm5lZFVzZBI4Chhjb21taXNzaW9uX2F2YWlsYWJsZV9pZHIYAyABKA'
    'FSFmNvbW1pc3Npb25BdmFpbGFibGVJZHISMgoVY29tbWlzc2lvbl9lYXJuZWRfaWRyGAQgASgB'
    'UhNjb21taXNzaW9uRWFybmVkSWRy');

@$core.Deprecated('Use reqBillingTopupPutDescriptor instead')
const ReqBillingTopupPut$json = {
  '1': 'ReqBillingTopupPut',
  '2': [
    {'1': 'amount_usd', '3': 1, '4': 1, '5': 1, '10': 'amountUsd'},
    {'1': 'amount_idr', '3': 2, '4': 1, '5': 1, '10': 'amountIdr'},
    {'1': 'provider', '3': 3, '4': 1, '5': 9, '10': 'provider'},
    {'1': 'payment_type', '3': 4, '4': 1, '5': 9, '10': 'paymentType'},
    {'1': 'proof_url', '3': 5, '4': 1, '5': 9, '10': 'proofUrl'},
  ],
};

/// Descriptor for `ReqBillingTopupPut`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqBillingTopupPutDescriptor = $convert.base64Decode(
    'ChJSZXFCaWxsaW5nVG9wdXBQdXQSHQoKYW1vdW50X3VzZBgBIAEoAVIJYW1vdW50VXNkEh0KCm'
    'Ftb3VudF9pZHIYAiABKAFSCWFtb3VudElkchIaCghwcm92aWRlchgDIAEoCVIIcHJvdmlkZXIS'
    'IQoMcGF5bWVudF90eXBlGAQgASgJUgtwYXltZW50VHlwZRIbCglwcm9vZl91cmwYBSABKAlSCH'
    'Byb29mVXJs');

@$core.Deprecated('Use resBillingTopupPutDescriptor instead')
const ResBillingTopupPut$json = {
  '1': 'ResBillingTopupPut',
  '2': [
    {'1': 'request', '3': 1, '4': 1, '5': 11, '6': '.c35.BillingTopupRequest', '10': 'request'},
  ],
};

/// Descriptor for `ResBillingTopupPut`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resBillingTopupPutDescriptor = $convert.base64Decode(
    'ChJSZXNCaWxsaW5nVG9wdXBQdXQSMgoHcmVxdWVzdBgBIAEoCzIYLmMzNS5CaWxsaW5nVG9wdX'
    'BSZXF1ZXN0UgdyZXF1ZXN0');

