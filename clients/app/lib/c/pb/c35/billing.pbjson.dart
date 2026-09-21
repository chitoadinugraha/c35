// This is a generated file - do not edit.
//
// Generated from c35/billing.proto.

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

@$core.Deprecated('Use billingProfileDescriptor instead')
const BillingProfile$json = {
  '1': 'BillingProfile',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 3, '10': 'id'},
    {'1': 'owner_iid', '3': 2, '4': 1, '5': 3, '10': 'ownerIid'},
    {'1': 'plan_tier', '3': 3, '4': 1, '5': 9, '10': 'planTier'},
    {
      '1': 'default_wallet_currency',
      '3': 4,
      '4': 1,
      '5': 9,
      '10': 'defaultWalletCurrency'
    },
    {
      '1': 'alien_allow_5h_used',
      '3': 5,
      '4': 1,
      '5': 1,
      '10': 'alienAllow5hUsed'
    },
    {
      '1': 'alien_allow_5h_limit',
      '3': 6,
      '4': 1,
      '5': 1,
      '10': 'alienAllow5hLimit'
    },
    {
      '1': 'alien_allow_weekly_used',
      '3': 7,
      '4': 1,
      '5': 1,
      '10': 'alienAllowWeeklyUsed'
    },
    {
      '1': 'alien_allow_weekly_limit',
      '3': 8,
      '4': 1,
      '5': 1,
      '10': 'alienAllowWeeklyLimit'
    },
    {
      '1': 'window_5h_start_ms',
      '3': 9,
      '4': 1,
      '5': 3,
      '10': 'window5hStartMs'
    },
    {
      '1': 'window_weekly_start_ms',
      '3': 10,
      '4': 1,
      '5': 3,
      '10': 'windowWeeklyStartMs'
    },
    {
      '1': 'commission_available_usd',
      '3': 11,
      '4': 1,
      '5': 1,
      '10': 'commissionAvailableUsd'
    },
    {
      '1': 'commission_earned_usd',
      '3': 12,
      '4': 1,
      '5': 1,
      '10': 'commissionEarnedUsd'
    },
    {
      '1': 'commission_available_idr',
      '3': 13,
      '4': 1,
      '5': 1,
      '10': 'commissionAvailableIdr'
    },
    {
      '1': 'commission_earned_idr',
      '3': 14,
      '4': 1,
      '5': 1,
      '10': 'commissionEarnedIdr'
    },
    {'1': 'updated_ts_ms', '3': 15, '4': 1, '5': 3, '10': 'updatedTsMs'},
  ],
};

/// Descriptor for `BillingProfile`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List billingProfileDescriptor = $convert.base64Decode(
    'Cg5CaWxsaW5nUHJvZmlsZRIOCgJpZBgBIAEoA1ICaWQSGwoJb3duZXJfaWlkGAIgASgDUghvd2'
    '5lcklpZBIbCglwbGFuX3RpZXIYAyABKAlSCHBsYW5UaWVyEjYKF2RlZmF1bHRfd2FsbGV0X2N1'
    'cnJlbmN5GAQgASgJUhVkZWZhdWx0V2FsbGV0Q3VycmVuY3kSLQoTYWxpZW5fYWxsb3dfNWhfdX'
    'NlZBgFIAEoAVIQYWxpZW5BbGxvdzVoVXNlZBIvChRhbGllbl9hbGxvd181aF9saW1pdBgGIAEo'
    'AVIRYWxpZW5BbGxvdzVoTGltaXQSNQoXYWxpZW5fYWxsb3dfd2Vla2x5X3VzZWQYByABKAFSFG'
    'FsaWVuQWxsb3dXZWVrbHlVc2VkEjcKGGFsaWVuX2FsbG93X3dlZWtseV9saW1pdBgIIAEoAVIV'
    'YWxpZW5BbGxvd1dlZWtseUxpbWl0EisKEndpbmRvd181aF9zdGFydF9tcxgJIAEoA1IPd2luZG'
    '93NWhTdGFydE1zEjMKFndpbmRvd193ZWVrbHlfc3RhcnRfbXMYCiABKANSE3dpbmRvd1dlZWts'
    'eVN0YXJ0TXMSOAoYY29tbWlzc2lvbl9hdmFpbGFibGVfdXNkGAsgASgBUhZjb21taXNzaW9uQX'
    'ZhaWxhYmxlVXNkEjIKFWNvbW1pc3Npb25fZWFybmVkX3VzZBgMIAEoAVITY29tbWlzc2lvbkVh'
    'cm5lZFVzZBI4Chhjb21taXNzaW9uX2F2YWlsYWJsZV9pZHIYDSABKAFSFmNvbW1pc3Npb25Bdm'
    'FpbGFibGVJZHISMgoVY29tbWlzc2lvbl9lYXJuZWRfaWRyGA4gASgBUhNjb21taXNzaW9uRWFy'
    'bmVkSWRyEiIKDXVwZGF0ZWRfdHNfbXMYDyABKANSC3VwZGF0ZWRUc01z');

@$core.Deprecated('Use billingWalletDescriptor instead')
const BillingWallet$json = {
  '1': 'BillingWallet',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 3, '10': 'id'},
    {'1': 'owner_iid', '3': 2, '4': 1, '5': 3, '10': 'ownerIid'},
    {'1': 'currency', '3': 3, '4': 1, '5': 9, '10': 'currency'},
    {'1': 'balance', '3': 4, '4': 1, '5': 1, '10': 'balance'},
    {'1': 'is_default', '3': 5, '4': 1, '5': 8, '10': 'isDefault'},
    {'1': 'name', '3': 6, '4': 1, '5': 9, '10': 'name'},
    {'1': 'updated_ts_ms', '3': 7, '4': 1, '5': 3, '10': 'updatedTsMs'},
  ],
};

/// Descriptor for `BillingWallet`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List billingWalletDescriptor = $convert.base64Decode(
    'Cg1CaWxsaW5nV2FsbGV0Eg4KAmlkGAEgASgDUgJpZBIbCglvd25lcl9paWQYAiABKANSCG93bm'
    'VySWlkEhoKCGN1cnJlbmN5GAMgASgJUghjdXJyZW5jeRIYCgdiYWxhbmNlGAQgASgBUgdiYWxh'
    'bmNlEh0KCmlzX2RlZmF1bHQYBSABKAhSCWlzRGVmYXVsdBISCgRuYW1lGAYgASgJUgRuYW1lEi'
    'IKDXVwZGF0ZWRfdHNfbXMYByABKANSC3VwZGF0ZWRUc01z');

@$core.Deprecated('Use billingPlanPriceDescriptor instead')
const BillingPlanPrice$json = {
  '1': 'BillingPlanPrice',
  '2': [
    {'1': 'plan_slug', '3': 1, '4': 1, '5': 9, '10': 'planSlug'},
    {'1': 'currency', '3': 2, '4': 1, '5': 9, '10': 'currency'},
    {'1': 'amount', '3': 3, '4': 1, '5': 1, '10': 'amount'},
    {'1': 'billing_period', '3': 4, '4': 1, '5': 9, '10': 'billingPeriod'},
  ],
};

/// Descriptor for `BillingPlanPrice`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List billingPlanPriceDescriptor = $convert.base64Decode(
    'ChBCaWxsaW5nUGxhblByaWNlEhsKCXBsYW5fc2x1ZxgBIAEoCVIIcGxhblNsdWcSGgoIY3Vycm'
    'VuY3kYAiABKAlSCGN1cnJlbmN5EhYKBmFtb3VudBgDIAEoAVIGYW1vdW50EiUKDmJpbGxpbmdf'
    'cGVyaW9kGAQgASgJUg1iaWxsaW5nUGVyaW9k');

@$core.Deprecated('Use billingFxRateDescriptor instead')
const BillingFxRate$json = {
  '1': 'BillingFxRate',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 3, '10': 'id'},
    {'1': 'currency', '3': 2, '4': 1, '5': 9, '10': 'currency'},
    {'1': 'micro_per_usd', '3': 3, '4': 1, '5': 3, '10': 'microPerUsd'},
    {'1': 'effective_from_ms', '3': 4, '4': 1, '5': 3, '10': 'effectiveFromMs'},
  ],
};

/// Descriptor for `BillingFxRate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List billingFxRateDescriptor = $convert.base64Decode(
    'Cg1CaWxsaW5nRnhSYXRlEg4KAmlkGAEgASgDUgJpZBIaCghjdXJyZW5jeRgCIAEoCVIIY3Vycm'
    'VuY3kSIgoNbWljcm9fcGVyX3VzZBgDIAEoA1ILbWljcm9QZXJVc2QSKgoRZWZmZWN0aXZlX2Zy'
    'b21fbXMYBCABKANSD2VmZmVjdGl2ZUZyb21Ncw==');

@$core.Deprecated('Use billingPurchaseDescriptor instead')
const BillingPurchase$json = {
  '1': 'BillingPurchase',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 3, '10': 'id'},
    {'1': 'owner_iid', '3': 2, '4': 1, '5': 3, '10': 'ownerIid'},
    {'1': 'plan_slug', '3': 3, '4': 1, '5': 9, '10': 'planSlug'},
    {'1': 'currency', '3': 4, '4': 1, '5': 9, '10': 'currency'},
    {'1': 'amount', '3': 5, '4': 1, '5': 1, '10': 'amount'},
    {'1': 'provider', '3': 6, '4': 1, '5': 9, '10': 'provider'},
    {'1': 'status', '3': 7, '4': 1, '5': 9, '10': 'status'},
    {'1': 'scope', '3': 8, '4': 1, '5': 9, '10': 'scope'},
    {'1': 'scope_iid', '3': 9, '4': 1, '5': 3, '10': 'scopeIid'},
    {'1': 'settled_ts_ms', '3': 10, '4': 1, '5': 3, '10': 'settledTsMs'},
    {'1': 'created_ts_ms', '3': 11, '4': 1, '5': 3, '10': 'createdTsMs'},
  ],
};

/// Descriptor for `BillingPurchase`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List billingPurchaseDescriptor = $convert.base64Decode(
    'Cg9CaWxsaW5nUHVyY2hhc2USDgoCaWQYASABKANSAmlkEhsKCW93bmVyX2lpZBgCIAEoA1IIb3'
    'duZXJJaWQSGwoJcGxhbl9zbHVnGAMgASgJUghwbGFuU2x1ZxIaCghjdXJyZW5jeRgEIAEoCVII'
    'Y3VycmVuY3kSFgoGYW1vdW50GAUgASgBUgZhbW91bnQSGgoIcHJvdmlkZXIYBiABKAlSCHByb3'
    'ZpZGVyEhYKBnN0YXR1cxgHIAEoCVIGc3RhdHVzEhQKBXNjb3BlGAggASgJUgVzY29wZRIbCglz'
    'Y29wZV9paWQYCSABKANSCHNjb3BlSWlkEiIKDXNldHRsZWRfdHNfbXMYCiABKANSC3NldHRsZW'
    'RUc01zEiIKDWNyZWF0ZWRfdHNfbXMYCyABKANSC2NyZWF0ZWRUc01z');

@$core.Deprecated('Use billingSnapshotDescriptor instead')
const BillingSnapshot$json = {
  '1': 'BillingSnapshot',
  '2': [
    {
      '1': 'profile',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.c35.BillingProfile',
      '10': 'profile'
    },
    {
      '1': 'wallets',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.c35.BillingWallet',
      '10': 'wallets'
    },
  ],
};

/// Descriptor for `BillingSnapshot`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List billingSnapshotDescriptor = $convert.base64Decode(
    'Cg9CaWxsaW5nU25hcHNob3QSLQoHcHJvZmlsZRgBIAEoCzITLmMzNS5CaWxsaW5nUHJvZmlsZV'
    'IHcHJvZmlsZRIsCgd3YWxsZXRzGAIgAygLMhIuYzM1LkJpbGxpbmdXYWxsZXRSB3dhbGxldHM=');

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
    {
      '1': 'alien_allow_5h_used',
      '3': 7,
      '4': 1,
      '5': 1,
      '10': 'alienAllow5hUsed'
    },
    {
      '1': 'alien_allow_5h_limit',
      '3': 8,
      '4': 1,
      '5': 1,
      '10': 'alienAllow5hLimit'
    },
    {
      '1': 'alien_allow_weekly_used',
      '3': 9,
      '4': 1,
      '5': 1,
      '10': 'alienAllowWeeklyUsed'
    },
    {
      '1': 'alien_allow_weekly_limit',
      '3': 10,
      '4': 1,
      '5': 1,
      '10': 'alienAllowWeeklyLimit'
    },
    {
      '1': 'window_5h_start_ms',
      '3': 11,
      '4': 1,
      '5': 3,
      '10': 'window5hStartMs'
    },
    {
      '1': 'window_weekly_start_ms',
      '3': 12,
      '4': 1,
      '5': 3,
      '10': 'windowWeeklyStartMs'
    },
    {'1': 'billing_currency', '3': 13, '4': 1, '5': 9, '10': 'billingCurrency'},
    {'1': 'fx_micro_per_usd', '3': 14, '4': 1, '5': 3, '10': 'fxMicroPerUsd'},
    {
      '1': 'commission_available_usd',
      '3': 15,
      '4': 1,
      '5': 1,
      '10': 'commissionAvailableUsd'
    },
    {
      '1': 'commission_earned_usd',
      '3': 16,
      '4': 1,
      '5': 1,
      '10': 'commissionEarnedUsd'
    },
    {
      '1': 'commission_available_idr',
      '3': 17,
      '4': 1,
      '5': 1,
      '10': 'commissionAvailableIdr'
    },
    {
      '1': 'commission_earned_idr',
      '3': 18,
      '4': 1,
      '5': 1,
      '10': 'commissionEarnedIdr'
    },
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
    {
      '1': 'billing_account_id',
      '3': 3,
      '4': 1,
      '5': 3,
      '10': 'billingAccountId'
    },
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
    {
      '1': 'billing_account_id',
      '3': 1,
      '4': 1,
      '5': 3,
      '10': 'billingAccountId'
    },
    {'1': 'balance_usd', '3': 2, '4': 1, '5': 1, '10': 'balanceUsd'},
    {'1': 'balance_idr', '3': 3, '4': 1, '5': 1, '10': 'balanceIdr'},
    {'1': 'updated_ts_ms', '3': 4, '4': 1, '5': 3, '10': 'updatedTsMs'},
    {'1': 'wallet_id', '3': 5, '4': 1, '5': 3, '10': 'walletId'},
    {'1': 'currency', '3': 6, '4': 1, '5': 9, '10': 'currency'},
    {'1': 'balance', '3': 7, '4': 1, '5': 1, '10': 'balance'},
  ],
};

/// Descriptor for `BillingPushBalance`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List billingPushBalanceDescriptor = $convert.base64Decode(
    'ChJCaWxsaW5nUHVzaEJhbGFuY2USLAoSYmlsbGluZ19hY2NvdW50X2lkGAEgASgDUhBiaWxsaW'
    '5nQWNjb3VudElkEh8KC2JhbGFuY2VfdXNkGAIgASgBUgpiYWxhbmNlVXNkEh8KC2JhbGFuY2Vf'
    'aWRyGAMgASgBUgpiYWxhbmNlSWRyEiIKDXVwZGF0ZWRfdHNfbXMYBCABKANSC3VwZGF0ZWRUc0'
    '1zEhsKCXdhbGxldF9pZBgFIAEoA1IId2FsbGV0SWQSGgoIY3VycmVuY3kYBiABKAlSCGN1cnJl'
    'bmN5EhgKB2JhbGFuY2UYByABKAFSB2JhbGFuY2U=');

@$core.Deprecated('Use billingPushQuotaDescriptor instead')
const BillingPushQuota$json = {
  '1': 'BillingPushQuota',
  '2': [
    {
      '1': 'alien_allow_5h_used',
      '3': 1,
      '4': 1,
      '5': 1,
      '10': 'alienAllow5hUsed'
    },
    {
      '1': 'alien_allow_5h_limit',
      '3': 2,
      '4': 1,
      '5': 1,
      '10': 'alienAllow5hLimit'
    },
    {
      '1': 'alien_allow_weekly_used',
      '3': 3,
      '4': 1,
      '5': 1,
      '10': 'alienAllowWeeklyUsed'
    },
    {
      '1': 'alien_allow_weekly_limit',
      '3': 4,
      '4': 1,
      '5': 1,
      '10': 'alienAllowWeeklyLimit'
    },
    {
      '1': 'window_5h_start_ms',
      '3': 5,
      '4': 1,
      '5': 3,
      '10': 'window5hStartMs'
    },
    {
      '1': 'window_weekly_start_ms',
      '3': 6,
      '4': 1,
      '5': 3,
      '10': 'windowWeeklyStartMs'
    },
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
    {
      '1': 'commission_available_usd',
      '3': 1,
      '4': 1,
      '5': 1,
      '10': 'commissionAvailableUsd'
    },
    {
      '1': 'commission_earned_usd',
      '3': 2,
      '4': 1,
      '5': 1,
      '10': 'commissionEarnedUsd'
    },
    {
      '1': 'commission_available_idr',
      '3': 3,
      '4': 1,
      '5': 1,
      '10': 'commissionAvailableIdr'
    },
    {
      '1': 'commission_earned_idr',
      '3': 4,
      '4': 1,
      '5': 1,
      '10': 'commissionEarnedIdr'
    },
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
    {
      '1': 'request',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.c35.BillingTopupRequest',
      '10': 'request'
    },
  ],
};

/// Descriptor for `ResBillingTopupPut`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resBillingTopupPutDescriptor = $convert.base64Decode(
    'ChJSZXNCaWxsaW5nVG9wdXBQdXQSMgoHcmVxdWVzdBgBIAEoCzIYLmMzNS5CaWxsaW5nVG9wdX'
    'BSZXF1ZXN0UgdyZXF1ZXN0');

@$core.Deprecated('Use reqBillingPlanSubscribeDescriptor instead')
const ReqBillingPlanSubscribe$json = {
  '1': 'ReqBillingPlanSubscribe',
  '2': [
    {'1': 'plan_slug', '3': 1, '4': 1, '5': 9, '10': 'planSlug'},
    {'1': 'currency', '3': 2, '4': 1, '5': 9, '10': 'currency'},
    {'1': 'wallet_id', '3': 3, '4': 1, '5': 3, '10': 'walletId'},
    {'1': 'direct_purchase', '3': 4, '4': 1, '5': 8, '10': 'directPurchase'},
  ],
};

/// Descriptor for `ReqBillingPlanSubscribe`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqBillingPlanSubscribeDescriptor = $convert.base64Decode(
    'ChdSZXFCaWxsaW5nUGxhblN1YnNjcmliZRIbCglwbGFuX3NsdWcYASABKAlSCHBsYW5TbHVnEh'
    'oKCGN1cnJlbmN5GAIgASgJUghjdXJyZW5jeRIbCgl3YWxsZXRfaWQYAyABKANSCHdhbGxldElk'
    'EicKD2RpcmVjdF9wdXJjaGFzZRgEIAEoCFIOZGlyZWN0UHVyY2hhc2U=');

@$core.Deprecated('Use resBillingPlanSubscribeDescriptor instead')
const ResBillingPlanSubscribe$json = {
  '1': 'ResBillingPlanSubscribe',
  '2': [
    {'1': 'plan_tier', '3': 1, '4': 1, '5': 9, '10': 'planTier'},
    {'1': 'balance_usd', '3': 2, '4': 1, '5': 1, '10': 'balanceUsd'},
    {'1': 'balance_idr', '3': 3, '4': 1, '5': 1, '10': 'balanceIdr'},
    {
      '1': 'alien_allow_5h_limit',
      '3': 4,
      '4': 1,
      '5': 1,
      '10': 'alienAllow5hLimit'
    },
    {
      '1': 'alien_allow_weekly_limit',
      '3': 5,
      '4': 1,
      '5': 1,
      '10': 'alienAllowWeeklyLimit'
    },
  ],
};

/// Descriptor for `ResBillingPlanSubscribe`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resBillingPlanSubscribeDescriptor = $convert.base64Decode(
    'ChdSZXNCaWxsaW5nUGxhblN1YnNjcmliZRIbCglwbGFuX3RpZXIYASABKAlSCHBsYW5UaWVyEh'
    '8KC2JhbGFuY2VfdXNkGAIgASgBUgpiYWxhbmNlVXNkEh8KC2JhbGFuY2VfaWRyGAMgASgBUgpi'
    'YWxhbmNlSWRyEi8KFGFsaWVuX2FsbG93XzVoX2xpbWl0GAQgASgBUhFhbGllbkFsbG93NWhMaW'
    '1pdBI3ChhhbGllbl9hbGxvd193ZWVrbHlfbGltaXQYBSABKAFSFWFsaWVuQWxsb3dXZWVrbHlM'
    'aW1pdA==');

@$core.Deprecated('Use reqBillingPackageRedeemDescriptor instead')
const ReqBillingPackageRedeem$json = {
  '1': 'ReqBillingPackageRedeem',
  '2': [
    {'1': 'code', '3': 1, '4': 1, '5': 9, '10': 'code'},
  ],
};

/// Descriptor for `ReqBillingPackageRedeem`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqBillingPackageRedeemDescriptor =
    $convert.base64Decode(
        'ChdSZXFCaWxsaW5nUGFja2FnZVJlZGVlbRISCgRjb2RlGAEgASgJUgRjb2Rl');

@$core.Deprecated('Use resBillingPackageRedeemDescriptor instead')
const ResBillingPackageRedeem$json = {
  '1': 'ResBillingPackageRedeem',
  '2': [
    {'1': 'purchase_id', '3': 1, '4': 1, '5': 3, '10': 'purchaseId'},
    {'1': 'amount_usd', '3': 2, '4': 1, '5': 1, '10': 'amountUsd'},
    {'1': 'amount_idr', '3': 3, '4': 1, '5': 1, '10': 'amountIdr'},
    {'1': 'plan_tier', '3': 4, '4': 1, '5': 9, '10': 'planTier'},
    {'1': 'duration_months', '3': 5, '4': 1, '5': 5, '10': 'durationMonths'},
    {'1': 'package_name', '3': 6, '4': 1, '5': 9, '10': 'packageName'},
  ],
};

/// Descriptor for `ResBillingPackageRedeem`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resBillingPackageRedeemDescriptor = $convert.base64Decode(
    'ChdSZXNCaWxsaW5nUGFja2FnZVJlZGVlbRIfCgtwdXJjaGFzZV9pZBgBIAEoA1IKcHVyY2hhc2'
    'VJZBIdCgphbW91bnRfdXNkGAIgASgBUglhbW91bnRVc2QSHQoKYW1vdW50X2lkchgDIAEoAVIJ'
    'YW1vdW50SWRyEhsKCXBsYW5fdGllchgEIAEoCVIIcGxhblRpZXISJwoPZHVyYXRpb25fbW9udG'
    'hzGAUgASgFUg5kdXJhdGlvbk1vbnRocxIhCgxwYWNrYWdlX25hbWUYBiABKAlSC3BhY2thZ2VO'
    'YW1l');

@$core.Deprecated('Use reqBillingPackagePreviewDescriptor instead')
const ReqBillingPackagePreview$json = {
  '1': 'ReqBillingPackagePreview',
  '2': [
    {'1': 'code', '3': 1, '4': 1, '5': 9, '10': 'code'},
  ],
};

/// Descriptor for `ReqBillingPackagePreview`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqBillingPackagePreviewDescriptor =
    $convert.base64Decode(
        'ChhSZXFCaWxsaW5nUGFja2FnZVByZXZpZXcSEgoEY29kZRgBIAEoCVIEY29kZQ==');

@$core.Deprecated('Use resBillingPackagePreviewDescriptor instead')
const ResBillingPackagePreview$json = {
  '1': 'ResBillingPackagePreview',
  '2': [
    {'1': 'amount_usd', '3': 1, '4': 1, '5': 1, '10': 'amountUsd'},
    {'1': 'amount_idr', '3': 2, '4': 1, '5': 1, '10': 'amountIdr'},
    {'1': 'plan_tier', '3': 3, '4': 1, '5': 9, '10': 'planTier'},
    {'1': 'package_name', '3': 4, '4': 1, '5': 9, '10': 'packageName'},
    {
      '1': 'commission',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.c35.ResReferralCommissionSimulate',
      '10': 'commission'
    },
  ],
};

/// Descriptor for `ResBillingPackagePreview`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resBillingPackagePreviewDescriptor = $convert.base64Decode(
    'ChhSZXNCaWxsaW5nUGFja2FnZVByZXZpZXcSHQoKYW1vdW50X3VzZBgBIAEoAVIJYW1vdW50VX'
    'NkEh0KCmFtb3VudF9pZHIYAiABKAFSCWFtb3VudElkchIbCglwbGFuX3RpZXIYAyABKAlSCHBs'
    'YW5UaWVyEiEKDHBhY2thZ2VfbmFtZRgEIAEoCVILcGFja2FnZU5hbWUSQgoKY29tbWlzc2lvbh'
    'gFIAEoCzIiLmMzNS5SZXNSZWZlcnJhbENvbW1pc3Npb25TaW11bGF0ZVIKY29tbWlzc2lvbg==');

@$core.Deprecated('Use botUsageModelRowDescriptor instead')
const BotUsageModelRow$json = {
  '1': 'BotUsageModelRow',
  '2': [
    {'1': 'model', '3': 1, '4': 1, '5': 9, '10': 'model'},
    {'1': 'plan_slug', '3': 2, '4': 1, '5': 9, '10': 'planSlug'},
    {'1': 'turns', '3': 3, '4': 1, '5': 5, '10': 'turns'},
    {'1': 'tokens_in', '3': 4, '4': 1, '5': 5, '10': 'tokensIn'},
    {'1': 'tokens_out', '3': 5, '4': 1, '5': 5, '10': 'tokensOut'},
    {'1': 'cost_usd', '3': 6, '4': 1, '5': 1, '10': 'costUsd'},
  ],
};

/// Descriptor for `BotUsageModelRow`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List botUsageModelRowDescriptor = $convert.base64Decode(
    'ChBCb3RVc2FnZU1vZGVsUm93EhQKBW1vZGVsGAEgASgJUgVtb2RlbBIbCglwbGFuX3NsdWcYAi'
    'ABKAlSCHBsYW5TbHVnEhQKBXR1cm5zGAMgASgFUgV0dXJucxIbCgl0b2tlbnNfaW4YBCABKAVS'
    'CHRva2Vuc0luEh0KCnRva2Vuc19vdXQYBSABKAVSCXRva2Vuc091dBIZCghjb3N0X3VzZBgGIA'
    'EoAVIHY29zdFVzZA==');

@$core.Deprecated('Use reqBotUsageStatsDescriptor instead')
const ReqBotUsageStats$json = {
  '1': 'ReqBotUsageStats',
  '2': [
    {'1': 'bot_iid', '3': 1, '4': 1, '5': 3, '10': 'botIid'},
  ],
};

/// Descriptor for `ReqBotUsageStats`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqBotUsageStatsDescriptor = $convert.base64Decode(
    'ChBSZXFCb3RVc2FnZVN0YXRzEhcKB2JvdF9paWQYASABKANSBmJvdElpZA==');

@$core.Deprecated('Use resBotUsageStatsDescriptor instead')
const ResBotUsageStats$json = {
  '1': 'ResBotUsageStats',
  '2': [
    {'1': 'bot_iid', '3': 1, '4': 1, '5': 3, '10': 'botIid'},
    {'1': 'plan_slug', '3': 2, '4': 1, '5': 9, '10': 'planSlug'},
    {'1': 'msgs_used', '3': 3, '4': 1, '5': 5, '10': 'msgsUsed'},
    {'1': 'msgs_limit', '3': 4, '4': 1, '5': 5, '10': 'msgsLimit'},
    {'1': 'total_cost_usd', '3': 5, '4': 1, '5': 1, '10': 'totalCostUsd'},
    {'1': 'total_tokens_in', '3': 6, '4': 1, '5': 5, '10': 'totalTokensIn'},
    {'1': 'total_tokens_out', '3': 7, '4': 1, '5': 5, '10': 'totalTokensOut'},
    {
      '1': 'by_model',
      '3': 8,
      '4': 3,
      '5': 11,
      '6': '.c35.BotUsageModelRow',
      '10': 'byModel'
    },
  ],
};

/// Descriptor for `ResBotUsageStats`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resBotUsageStatsDescriptor = $convert.base64Decode(
    'ChBSZXNCb3RVc2FnZVN0YXRzEhcKB2JvdF9paWQYASABKANSBmJvdElpZBIbCglwbGFuX3NsdW'
    'cYAiABKAlSCHBsYW5TbHVnEhsKCW1zZ3NfdXNlZBgDIAEoBVIIbXNnc1VzZWQSHQoKbXNnc19s'
    'aW1pdBgEIAEoBVIJbXNnc0xpbWl0EiQKDnRvdGFsX2Nvc3RfdXNkGAUgASgBUgx0b3RhbENvc3'
    'RVc2QSJgoPdG90YWxfdG9rZW5zX2luGAYgASgFUg10b3RhbFRva2Vuc0luEigKEHRvdGFsX3Rv'
    'a2Vuc19vdXQYByABKAVSDnRvdGFsVG9rZW5zT3V0EjAKCGJ5X21vZGVsGAggAygLMhUuYzM1Lk'
    'JvdFVzYWdlTW9kZWxSb3dSB2J5TW9kZWw=');

@$core.Deprecated('Use reqBillingSummaryDescriptor instead')
const ReqBillingSummary$json = {
  '1': 'ReqBillingSummary',
  '2': [
    {
      '1': 'billing_account_id',
      '3': 1,
      '4': 1,
      '5': 3,
      '10': 'billingAccountId'
    },
  ],
};

/// Descriptor for `ReqBillingSummary`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqBillingSummaryDescriptor = $convert.base64Decode(
    'ChFSZXFCaWxsaW5nU3VtbWFyeRIsChJiaWxsaW5nX2FjY291bnRfaWQYASABKANSEGJpbGxpbm'
    'dBY2NvdW50SWQ=');

@$core.Deprecated('Use billingPlanDocDescriptor instead')
const BillingPlanDoc$json = {
  '1': 'BillingPlanDoc',
  '2': [
    {'1': 'slug', '3': 1, '4': 1, '5': 9, '10': 'slug'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'sort_order', '3': 3, '4': 1, '5': 5, '10': 'sortOrder'},
    {'1': 'price_usd', '3': 4, '4': 1, '5': 1, '10': 'priceUsd'},
    {'1': 'duration_months', '3': 5, '4': 1, '5': 5, '10': 'durationMonths'},
    {
      '1': 'alien_allow_5h_usd',
      '3': 6,
      '4': 1,
      '5': 1,
      '10': 'alienAllow5hUsd'
    },
    {
      '1': 'alien_allow_weekly_usd',
      '3': 7,
      '4': 1,
      '5': 1,
      '10': 'alienAllowWeeklyUsd'
    },
    {'1': 'msgs_limit', '3': 8, '4': 1, '5': 5, '10': 'msgsLimit'},
    {'1': 'channels_limit', '3': 9, '4': 1, '5': 5, '10': 'channelsLimit'},
    {'1': 'concurrent_limit', '3': 10, '4': 1, '5': 5, '10': 'concurrentLimit'},
    {'1': 'overage_enabled', '3': 11, '4': 1, '5': 8, '10': 'overageEnabled'},
  ],
};

/// Descriptor for `BillingPlanDoc`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List billingPlanDocDescriptor = $convert.base64Decode(
    'Cg5CaWxsaW5nUGxhbkRvYxISCgRzbHVnGAEgASgJUgRzbHVnEhIKBG5hbWUYAiABKAlSBG5hbW'
    'USHQoKc29ydF9vcmRlchgDIAEoBVIJc29ydE9yZGVyEhsKCXByaWNlX3VzZBgEIAEoAVIIcHJp'
    'Y2VVc2QSJwoPZHVyYXRpb25fbW9udGhzGAUgASgFUg5kdXJhdGlvbk1vbnRocxIrChJhbGllbl'
    '9hbGxvd181aF91c2QYBiABKAFSD2FsaWVuQWxsb3c1aFVzZBIzChZhbGllbl9hbGxvd193ZWVr'
    'bHlfdXNkGAcgASgBUhNhbGllbkFsbG93V2Vla2x5VXNkEh0KCm1zZ3NfbGltaXQYCCABKAVSCW'
    '1zZ3NMaW1pdBIlCg5jaGFubmVsc19saW1pdBgJIAEoBVINY2hhbm5lbHNMaW1pdBIpChBjb25j'
    'dXJyZW50X2xpbWl0GAogASgFUg9jb25jdXJyZW50TGltaXQSJwoPb3ZlcmFnZV9lbmFibGVkGA'
    'sgASgIUg5vdmVyYWdlRW5hYmxlZA==');

@$core.Deprecated('Use billingHistoryRowDescriptor instead')
const BillingHistoryRow$json = {
  '1': 'BillingHistoryRow',
  '2': [
    {'1': 'kind', '3': 1, '4': 1, '5': 9, '10': 'kind'},
    {'1': 'title', '3': 2, '4': 1, '5': 9, '10': 'title'},
    {'1': 'amount_usd', '3': 3, '4': 1, '5': 1, '10': 'amountUsd'},
    {'1': 'amount_idr', '3': 4, '4': 1, '5': 1, '10': 'amountIdr'},
    {'1': 'status', '3': 5, '4': 1, '5': 9, '10': 'status'},
    {'1': 'ts_ms', '3': 6, '4': 1, '5': 3, '10': 'tsMs'},
    {'1': 'currency', '3': 7, '4': 1, '5': 9, '10': 'currency'},
    {'1': 'amount', '3': 8, '4': 1, '5': 1, '10': 'amount'},
  ],
};

/// Descriptor for `BillingHistoryRow`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List billingHistoryRowDescriptor = $convert.base64Decode(
    'ChFCaWxsaW5nSGlzdG9yeVJvdxISCgRraW5kGAEgASgJUgRraW5kEhQKBXRpdGxlGAIgASgJUg'
    'V0aXRsZRIdCgphbW91bnRfdXNkGAMgASgBUglhbW91bnRVc2QSHQoKYW1vdW50X2lkchgEIAEo'
    'AVIJYW1vdW50SWRyEhYKBnN0YXR1cxgFIAEoCVIGc3RhdHVzEhMKBXRzX21zGAYgASgDUgR0c0'
    '1zEhoKCGN1cnJlbmN5GAcgASgJUghjdXJyZW5jeRIWCgZhbW91bnQYCCABKAFSBmFtb3VudA==');

@$core.Deprecated('Use reqBillingHistoryDescriptor instead')
const ReqBillingHistory$json = {
  '1': 'ReqBillingHistory',
  '2': [
    {'1': 'limit', '3': 1, '4': 1, '5': 5, '10': 'limit'},
    {'1': 'currency', '3': 2, '4': 1, '5': 9, '10': 'currency'},
  ],
};

/// Descriptor for `ReqBillingHistory`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqBillingHistoryDescriptor = $convert.base64Decode(
    'ChFSZXFCaWxsaW5nSGlzdG9yeRIUCgVsaW1pdBgBIAEoBVIFbGltaXQSGgoIY3VycmVuY3kYAi'
    'ABKAlSCGN1cnJlbmN5');

@$core.Deprecated('Use resBillingHistoryDescriptor instead')
const ResBillingHistory$json = {
  '1': 'ResBillingHistory',
  '2': [
    {
      '1': 'rows',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.c35.BillingHistoryRow',
      '10': 'rows'
    },
  ],
};

/// Descriptor for `ResBillingHistory`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resBillingHistoryDescriptor = $convert.base64Decode(
    'ChFSZXNCaWxsaW5nSGlzdG9yeRIqCgRyb3dzGAEgAygLMhYuYzM1LkJpbGxpbmdIaXN0b3J5Um'
    '93UgRyb3dz');

@$core.Deprecated('Use resBillingSummaryDescriptor instead')
const ResBillingSummary$json = {
  '1': 'ResBillingSummary',
  '2': [
    {'1': 'balance_usd', '3': 1, '4': 1, '5': 1, '10': 'balanceUsd'},
    {'1': 'plan_tier', '3': 2, '4': 1, '5': 9, '10': 'planTier'},
    {'1': 'quota_5h_used', '3': 3, '4': 1, '5': 5, '10': 'quota5hUsed'},
    {'1': 'quota_5h_limit', '3': 4, '4': 1, '5': 5, '10': 'quota5hLimit'},
    {
      '1': 'window_5h_resets_at_ms',
      '3': 5,
      '4': 1,
      '5': 3,
      '10': 'window5hResetsAtMs'
    },
    {'1': 'meter_state', '3': 6, '4': 1, '5': 9, '10': 'meterState'},
    {'1': 'bots_paused', '3': 7, '4': 1, '5': 8, '10': 'botsPaused'},
    {'1': 'quota_weekly_used', '3': 8, '4': 1, '5': 5, '10': 'quotaWeeklyUsed'},
    {
      '1': 'quota_weekly_limit',
      '3': 9,
      '4': 1,
      '5': 5,
      '10': 'quotaWeeklyLimit'
    },
    {
      '1': 'window_weekly_resets_at_ms',
      '3': 10,
      '4': 1,
      '5': 3,
      '10': 'windowWeeklyResetsAtMs'
    },
    {'1': 'balance_idr', '3': 11, '4': 1, '5': 1, '10': 'balanceIdr'},
    {
      '1': 'commission_available_usd',
      '3': 12,
      '4': 1,
      '5': 1,
      '10': 'commissionAvailableUsd'
    },
    {
      '1': 'commission_available_idr',
      '3': 13,
      '4': 1,
      '5': 1,
      '10': 'commissionAvailableIdr'
    },
    {
      '1': 'alien_allow_5h_used',
      '3': 14,
      '4': 1,
      '5': 1,
      '10': 'alienAllow5hUsed'
    },
    {
      '1': 'alien_allow_5h_limit',
      '3': 15,
      '4': 1,
      '5': 1,
      '10': 'alienAllow5hLimit'
    },
    {
      '1': 'alien_allow_weekly_used',
      '3': 16,
      '4': 1,
      '5': 1,
      '10': 'alienAllowWeeklyUsed'
    },
    {
      '1': 'alien_allow_weekly_limit',
      '3': 17,
      '4': 1,
      '5': 1,
      '10': 'alienAllowWeeklyLimit'
    },
    {
      '1': 'plans',
      '3': 18,
      '4': 3,
      '5': 11,
      '6': '.c35.BillingPlanDoc',
      '10': 'plans'
    },
    {'1': 'overage_enabled', '3': 19, '4': 1, '5': 8, '10': 'overageEnabled'},
  ],
};

/// Descriptor for `ResBillingSummary`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resBillingSummaryDescriptor = $convert.base64Decode(
    'ChFSZXNCaWxsaW5nU3VtbWFyeRIfCgtiYWxhbmNlX3VzZBgBIAEoAVIKYmFsYW5jZVVzZBIbCg'
    'lwbGFuX3RpZXIYAiABKAlSCHBsYW5UaWVyEiIKDXF1b3RhXzVoX3VzZWQYAyABKAVSC3F1b3Rh'
    'NWhVc2VkEiQKDnF1b3RhXzVoX2xpbWl0GAQgASgFUgxxdW90YTVoTGltaXQSMgoWd2luZG93Xz'
    'VoX3Jlc2V0c19hdF9tcxgFIAEoA1ISd2luZG93NWhSZXNldHNBdE1zEh8KC21ldGVyX3N0YXRl'
    'GAYgASgJUgptZXRlclN0YXRlEh8KC2JvdHNfcGF1c2VkGAcgASgIUgpib3RzUGF1c2VkEioKEX'
    'F1b3RhX3dlZWtseV91c2VkGAggASgFUg9xdW90YVdlZWtseVVzZWQSLAoScXVvdGFfd2Vla2x5'
    'X2xpbWl0GAkgASgFUhBxdW90YVdlZWtseUxpbWl0EjoKGndpbmRvd193ZWVrbHlfcmVzZXRzX2'
    'F0X21zGAogASgDUhZ3aW5kb3dXZWVrbHlSZXNldHNBdE1zEh8KC2JhbGFuY2VfaWRyGAsgASgB'
    'UgpiYWxhbmNlSWRyEjgKGGNvbW1pc3Npb25fYXZhaWxhYmxlX3VzZBgMIAEoAVIWY29tbWlzc2'
    'lvbkF2YWlsYWJsZVVzZBI4Chhjb21taXNzaW9uX2F2YWlsYWJsZV9pZHIYDSABKAFSFmNvbW1p'
    'c3Npb25BdmFpbGFibGVJZHISLQoTYWxpZW5fYWxsb3dfNWhfdXNlZBgOIAEoAVIQYWxpZW5BbG'
    'xvdzVoVXNlZBIvChRhbGllbl9hbGxvd181aF9saW1pdBgPIAEoAVIRYWxpZW5BbGxvdzVoTGlt'
    'aXQSNQoXYWxpZW5fYWxsb3dfd2Vla2x5X3VzZWQYECABKAFSFGFsaWVuQWxsb3dXZWVrbHlVc2'
    'VkEjcKGGFsaWVuX2FsbG93X3dlZWtseV9saW1pdBgRIAEoAVIVYWxpZW5BbGxvd1dlZWtseUxp'
    'bWl0EikKBXBsYW5zGBIgAygLMhMuYzM1LkJpbGxpbmdQbGFuRG9jUgVwbGFucxInCg9vdmVyYW'
    'dlX2VuYWJsZWQYEyABKAhSDm92ZXJhZ2VFbmFibGVk');
