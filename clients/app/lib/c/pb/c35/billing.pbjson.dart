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
    {
      '1': 'alien_pool_limit_idr',
      '3': 16,
      '4': 1,
      '5': 1,
      '10': 'alienPoolLimitIdr'
    },
    {
      '1': 'alien_pool_used_idr',
      '3': 17,
      '4': 1,
      '5': 1,
      '10': 'alienPoolUsedIdr'
    },
    {
      '1': 'frontier_pool_limit_idr',
      '3': 18,
      '4': 1,
      '5': 1,
      '10': 'frontierPoolLimitIdr'
    },
    {
      '1': 'frontier_pool_used_idr',
      '3': 19,
      '4': 1,
      '5': 1,
      '10': 'frontierPoolUsedIdr'
    },
    {
      '1': 'pool_period_start_ms',
      '3': 20,
      '4': 1,
      '5': 3,
      '10': 'poolPeriodStartMs'
    },
    {
      '1': 'trial_expires_ts_ms',
      '3': 21,
      '4': 1,
      '5': 3,
      '10': 'trialExpiresTsMs'
    },
    {
      '1': 'active_promotion_id',
      '3': 22,
      '4': 1,
      '5': 3,
      '10': 'activePromotionId'
    },
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
    'bmVkSWRyEiIKDXVwZGF0ZWRfdHNfbXMYDyABKANSC3VwZGF0ZWRUc01zEi8KFGFsaWVuX3Bvb2'
    'xfbGltaXRfaWRyGBAgASgBUhFhbGllblBvb2xMaW1pdElkchItChNhbGllbl9wb29sX3VzZWRf'
    'aWRyGBEgASgBUhBhbGllblBvb2xVc2VkSWRyEjUKF2Zyb250aWVyX3Bvb2xfbGltaXRfaWRyGB'
    'IgASgBUhRmcm9udGllclBvb2xMaW1pdElkchIzChZmcm9udGllcl9wb29sX3VzZWRfaWRyGBMg'
    'ASgBUhNmcm9udGllclBvb2xVc2VkSWRyEi8KFHBvb2xfcGVyaW9kX3N0YXJ0X21zGBQgASgDUh'
    'Fwb29sUGVyaW9kU3RhcnRNcxItChN0cmlhbF9leHBpcmVzX3RzX21zGBUgASgDUhB0cmlhbEV4'
    'cGlyZXNUc01zEi4KE2FjdGl2ZV9wcm9tb3Rpb25faWQYFiABKANSEWFjdGl2ZVByb21vdGlvbk'
    'lk');

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
    {
      '1': 'alien_pool_limit_idr',
      '3': 7,
      '4': 1,
      '5': 1,
      '10': 'alienPoolLimitIdr'
    },
    {
      '1': 'alien_pool_used_idr',
      '3': 8,
      '4': 1,
      '5': 1,
      '10': 'alienPoolUsedIdr'
    },
    {
      '1': 'frontier_pool_limit_idr',
      '3': 9,
      '4': 1,
      '5': 1,
      '10': 'frontierPoolLimitIdr'
    },
    {
      '1': 'frontier_pool_used_idr',
      '3': 10,
      '4': 1,
      '5': 1,
      '10': 'frontierPoolUsedIdr'
    },
    {
      '1': 'pool_period_start_ms',
      '3': 11,
      '4': 1,
      '5': 3,
      '10': 'poolPeriodStartMs'
    },
    {
      '1': 'trial_expires_ts_ms',
      '3': 12,
      '4': 1,
      '5': 3,
      '10': 'trialExpiresTsMs'
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
    '5kb3dfd2Vla2x5X3N0YXJ0X21zGAYgASgDUhN3aW5kb3dXZWVrbHlTdGFydE1zEi8KFGFsaWVu'
    'X3Bvb2xfbGltaXRfaWRyGAcgASgBUhFhbGllblBvb2xMaW1pdElkchItChNhbGllbl9wb29sX3'
    'VzZWRfaWRyGAggASgBUhBhbGllblBvb2xVc2VkSWRyEjUKF2Zyb250aWVyX3Bvb2xfbGltaXRf'
    'aWRyGAkgASgBUhRmcm9udGllclBvb2xMaW1pdElkchIzChZmcm9udGllcl9wb29sX3VzZWRfaW'
    'RyGAogASgBUhNmcm9udGllclBvb2xVc2VkSWRyEi8KFHBvb2xfcGVyaW9kX3N0YXJ0X21zGAsg'
    'ASgDUhFwb29sUGVyaW9kU3RhcnRNcxItChN0cmlhbF9leHBpcmVzX3RzX21zGAwgASgDUhB0cm'
    'lhbEV4cGlyZXNUc01z');

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
    {'1': 'order_id', '3': 2, '4': 1, '5': 9, '10': 'orderId'},
    {'1': 'payment_url', '3': 3, '4': 1, '5': 9, '10': 'paymentUrl'},
    {'1': 'qr_code_data', '3': 4, '4': 1, '5': 9, '10': 'qrCodeData'},
    {'1': 'instruction', '3': 5, '4': 1, '5': 9, '10': 'instruction'},
    {'1': 'status', '3': 6, '4': 1, '5': 9, '10': 'status'},
    {'1': 'credit_amount_idr', '3': 7, '4': 1, '5': 1, '10': 'creditAmountIdr'},
    {'1': 'fee_amount_idr', '3': 8, '4': 1, '5': 1, '10': 'feeAmountIdr'},
    {'1': 'gross_amount_idr', '3': 9, '4': 1, '5': 1, '10': 'grossAmountIdr'},
  ],
};

/// Descriptor for `ResBillingTopupPut`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resBillingTopupPutDescriptor = $convert.base64Decode(
    'ChJSZXNCaWxsaW5nVG9wdXBQdXQSMgoHcmVxdWVzdBgBIAEoCzIYLmMzNS5CaWxsaW5nVG9wdX'
    'BSZXF1ZXN0UgdyZXF1ZXN0EhkKCG9yZGVyX2lkGAIgASgJUgdvcmRlcklkEh8KC3BheW1lbnRf'
    'dXJsGAMgASgJUgpwYXltZW50VXJsEiAKDHFyX2NvZGVfZGF0YRgEIAEoCVIKcXJDb2RlRGF0YR'
    'IgCgtpbnN0cnVjdGlvbhgFIAEoCVILaW5zdHJ1Y3Rpb24SFgoGc3RhdHVzGAYgASgJUgZzdGF0'
    'dXMSKgoRY3JlZGl0X2Ftb3VudF9pZHIYByABKAFSD2NyZWRpdEFtb3VudElkchIkCg5mZWVfYW'
    '1vdW50X2lkchgIIAEoAVIMZmVlQW1vdW50SWRyEigKEGdyb3NzX2Ftb3VudF9pZHIYCSABKAFS'
    'Dmdyb3NzQW1vdW50SWRy');

@$core.Deprecated('Use billingTopupMethodOptionDescriptor instead')
const BillingTopupMethodOption$json = {
  '1': 'BillingTopupMethodOption',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'label', '3': 2, '4': 1, '5': 9, '10': 'label'},
    {'1': 'provider', '3': 3, '4': 1, '5': 9, '10': 'provider'},
    {'1': 'payment_type', '3': 4, '4': 1, '5': 9, '10': 'paymentType'},
    {'1': 'note', '3': 5, '4': 1, '5': 9, '10': 'note'},
    {'1': 'fee_amount_idr', '3': 6, '4': 1, '5': 1, '10': 'feeAmountIdr'},
    {'1': 'fee_is_percent', '3': 7, '4': 1, '5': 8, '10': 'feeIsPercent'},
    {'1': 'fee_rate_bps', '3': 8, '4': 1, '5': 1, '10': 'feeRateBps'},
  ],
};

/// Descriptor for `BillingTopupMethodOption`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List billingTopupMethodOptionDescriptor = $convert.base64Decode(
    'ChhCaWxsaW5nVG9wdXBNZXRob2RPcHRpb24SDgoCaWQYASABKAlSAmlkEhQKBWxhYmVsGAIgAS'
    'gJUgVsYWJlbBIaCghwcm92aWRlchgDIAEoCVIIcHJvdmlkZXISIQoMcGF5bWVudF90eXBlGAQg'
    'ASgJUgtwYXltZW50VHlwZRISCgRub3RlGAUgASgJUgRub3RlEiQKDmZlZV9hbW91bnRfaWRyGA'
    'YgASgBUgxmZWVBbW91bnRJZHISJAoOZmVlX2lzX3BlcmNlbnQYByABKAhSDGZlZUlzUGVyY2Vu'
    'dBIgCgxmZWVfcmF0ZV9icHMYCCABKAFSCmZlZVJhdGVCcHM=');

@$core.Deprecated('Use reqBillingTopupMethodsDescriptor instead')
const ReqBillingTopupMethods$json = {
  '1': 'ReqBillingTopupMethods',
  '2': [
    {'1': 'sample_amount_idr', '3': 1, '4': 1, '5': 1, '10': 'sampleAmountIdr'},
  ],
};

/// Descriptor for `ReqBillingTopupMethods`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqBillingTopupMethodsDescriptor =
    $convert.base64Decode(
        'ChZSZXFCaWxsaW5nVG9wdXBNZXRob2RzEioKEXNhbXBsZV9hbW91bnRfaWRyGAEgASgBUg9zYW'
        '1wbGVBbW91bnRJZHI=');

@$core.Deprecated('Use resBillingTopupMethodsDescriptor instead')
const ResBillingTopupMethods$json = {
  '1': 'ResBillingTopupMethods',
  '2': [
    {
      '1': 'methods',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.c35.BillingTopupMethodOption',
      '10': 'methods'
    },
  ],
};

/// Descriptor for `ResBillingTopupMethods`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resBillingTopupMethodsDescriptor =
    $convert.base64Decode(
        'ChZSZXNCaWxsaW5nVG9wdXBNZXRob2RzEjcKB21ldGhvZHMYASADKAsyHS5jMzUuQmlsbGluZ1'
        'RvcHVwTWV0aG9kT3B0aW9uUgdtZXRob2Rz');

@$core.Deprecated('Use reqBillingTopupGetDescriptor instead')
const ReqBillingTopupGet$json = {
  '1': 'ReqBillingTopupGet',
  '2': [
    {'1': 'order_id', '3': 1, '4': 1, '5': 9, '10': 'orderId'},
  ],
};

/// Descriptor for `ReqBillingTopupGet`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqBillingTopupGetDescriptor =
    $convert.base64Decode(
        'ChJSZXFCaWxsaW5nVG9wdXBHZXQSGQoIb3JkZXJfaWQYASABKAlSB29yZGVySWQ=');

@$core.Deprecated('Use resBillingTopupGetDescriptor instead')
const ResBillingTopupGet$json = {
  '1': 'ResBillingTopupGet',
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

/// Descriptor for `ResBillingTopupGet`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resBillingTopupGetDescriptor = $convert.base64Decode(
    'ChJSZXNCaWxsaW5nVG9wdXBHZXQSMgoHcmVxdWVzdBgBIAEoCzIYLmMzNS5CaWxsaW5nVG9wdX'
    'BSZXF1ZXN0UgdyZXF1ZXN0');

@$core.Deprecated('Use billingTopupQueueItemDescriptor instead')
const BillingTopupQueueItem$json = {
  '1': 'BillingTopupQueueItem',
  '2': [
    {'1': 'request_id', '3': 1, '4': 1, '5': 3, '10': 'requestId'},
    {'1': 'owner_iid', '3': 2, '4': 1, '5': 3, '10': 'ownerIid'},
    {'1': 'amount_idr', '3': 3, '4': 1, '5': 1, '10': 'amountIdr'},
    {'1': 'amount_usd', '3': 4, '4': 1, '5': 1, '10': 'amountUsd'},
    {'1': 'proof_url', '3': 5, '4': 1, '5': 9, '10': 'proofUrl'},
    {'1': 'status', '3': 6, '4': 1, '5': 9, '10': 'status'},
    {'1': 'created_ts_ms', '3': 7, '4': 1, '5': 3, '10': 'createdTsMs'},
    {'1': 'user_name', '3': 8, '4': 1, '5': 9, '10': 'userName'},
    {'1': 'user_pic', '3': 9, '4': 1, '5': 9, '10': 'userPic'},
    {'1': 'user_handle', '3': 10, '4': 1, '5': 9, '10': 'userHandle'},
    {'1': 'reject_reason', '3': 11, '4': 1, '5': 9, '10': 'rejectReason'},
    {'1': 'reviewed_by_iid', '3': 12, '4': 1, '5': 3, '10': 'reviewedByIid'},
    {'1': 'reviewer_name', '3': 13, '4': 1, '5': 9, '10': 'reviewerName'},
    {'1': 'reviewer_pic', '3': 14, '4': 1, '5': 9, '10': 'reviewerPic'},
  ],
};

/// Descriptor for `BillingTopupQueueItem`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List billingTopupQueueItemDescriptor = $convert.base64Decode(
    'ChVCaWxsaW5nVG9wdXBRdWV1ZUl0ZW0SHQoKcmVxdWVzdF9pZBgBIAEoA1IJcmVxdWVzdElkEh'
    'sKCW93bmVyX2lpZBgCIAEoA1IIb3duZXJJaWQSHQoKYW1vdW50X2lkchgDIAEoAVIJYW1vdW50'
    'SWRyEh0KCmFtb3VudF91c2QYBCABKAFSCWFtb3VudFVzZBIbCglwcm9vZl91cmwYBSABKAlSCH'
    'Byb29mVXJsEhYKBnN0YXR1cxgGIAEoCVIGc3RhdHVzEiIKDWNyZWF0ZWRfdHNfbXMYByABKANS'
    'C2NyZWF0ZWRUc01zEhsKCXVzZXJfbmFtZRgIIAEoCVIIdXNlck5hbWUSGQoIdXNlcl9waWMYCS'
    'ABKAlSB3VzZXJQaWMSHwoLdXNlcl9oYW5kbGUYCiABKAlSCnVzZXJIYW5kbGUSIwoNcmVqZWN0'
    'X3JlYXNvbhgLIAEoCVIMcmVqZWN0UmVhc29uEiYKD3Jldmlld2VkX2J5X2lpZBgMIAEoA1INcm'
    'V2aWV3ZWRCeUlpZBIjCg1yZXZpZXdlcl9uYW1lGA0gASgJUgxyZXZpZXdlck5hbWUSIQoMcmV2'
    'aWV3ZXJfcGljGA4gASgJUgtyZXZpZXdlclBpYw==');

@$core.Deprecated('Use reqBillingTopupListDescriptor instead')
const ReqBillingTopupList$json = {
  '1': 'ReqBillingTopupList',
  '2': [
    {'1': 'status', '3': 1, '4': 1, '5': 9, '10': 'status'},
    {'1': 'limit', '3': 2, '4': 1, '5': 5, '10': 'limit'},
  ],
};

/// Descriptor for `ReqBillingTopupList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqBillingTopupListDescriptor = $convert.base64Decode(
    'ChNSZXFCaWxsaW5nVG9wdXBMaXN0EhYKBnN0YXR1cxgBIAEoCVIGc3RhdHVzEhQKBWxpbWl0GA'
    'IgASgFUgVsaW1pdA==');

@$core.Deprecated('Use resBillingTopupListDescriptor instead')
const ResBillingTopupList$json = {
  '1': 'ResBillingTopupList',
  '2': [
    {
      '1': 'requests',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.c35.BillingTopupQueueItem',
      '10': 'requests'
    },
  ],
};

/// Descriptor for `ResBillingTopupList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resBillingTopupListDescriptor = $convert.base64Decode(
    'ChNSZXNCaWxsaW5nVG9wdXBMaXN0EjYKCHJlcXVlc3RzGAEgAygLMhouYzM1LkJpbGxpbmdUb3'
    'B1cFF1ZXVlSXRlbVIIcmVxdWVzdHM=');

@$core.Deprecated('Use reqBillingTopupReviewDescriptor instead')
const ReqBillingTopupReview$json = {
  '1': 'ReqBillingTopupReview',
  '2': [
    {'1': 'request_id', '3': 1, '4': 1, '5': 3, '10': 'requestId'},
    {'1': 'action', '3': 2, '4': 1, '5': 9, '10': 'action'},
    {'1': 'reason', '3': 3, '4': 1, '5': 9, '10': 'reason'},
  ],
};

/// Descriptor for `ReqBillingTopupReview`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqBillingTopupReviewDescriptor = $convert.base64Decode(
    'ChVSZXFCaWxsaW5nVG9wdXBSZXZpZXcSHQoKcmVxdWVzdF9pZBgBIAEoA1IJcmVxdWVzdElkEh'
    'YKBmFjdGlvbhgCIAEoCVIGYWN0aW9uEhYKBnJlYXNvbhgDIAEoCVIGcmVhc29u');

@$core.Deprecated('Use resBillingTopupReviewDescriptor instead')
const ResBillingTopupReview$json = {
  '1': 'ResBillingTopupReview',
};

/// Descriptor for `ResBillingTopupReview`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resBillingTopupReviewDescriptor =
    $convert.base64Decode('ChVSZXNCaWxsaW5nVG9wdXBSZXZpZXc=');

@$core.Deprecated('Use commissionWithdrawQueueItemDescriptor instead')
const CommissionWithdrawQueueItem$json = {
  '1': 'CommissionWithdrawQueueItem',
  '2': [
    {'1': 'request_id', '3': 1, '4': 1, '5': 3, '10': 'requestId'},
    {'1': 'owner_iid', '3': 2, '4': 1, '5': 3, '10': 'ownerIid'},
    {'1': 'amount_usd', '3': 3, '4': 1, '5': 1, '10': 'amountUsd'},
    {'1': 'amount_idr', '3': 4, '4': 1, '5': 1, '10': 'amountIdr'},
    {'1': 'currency', '3': 5, '4': 1, '5': 9, '10': 'currency'},
    {'1': 'payout_method', '3': 6, '4': 1, '5': 9, '10': 'payoutMethod'},
    {'1': 'bank_id', '3': 7, '4': 1, '5': 9, '10': 'bankId'},
    {'1': 'bank_short_name', '3': 8, '4': 1, '5': 9, '10': 'bankShortName'},
    {'1': 'account_number', '3': 9, '4': 1, '5': 9, '10': 'accountNumber'},
    {'1': 'account_name', '3': 10, '4': 1, '5': 9, '10': 'accountName'},
    {'1': 'note', '3': 11, '4': 1, '5': 9, '10': 'note'},
    {
      '1': 'transfer_proof_url',
      '3': 12,
      '4': 1,
      '5': 9,
      '10': 'transferProofUrl'
    },
    {'1': 'status', '3': 13, '4': 1, '5': 9, '10': 'status'},
    {'1': 'created_ts_ms', '3': 14, '4': 1, '5': 3, '10': 'createdTsMs'},
    {'1': 'user_name', '3': 15, '4': 1, '5': 9, '10': 'userName'},
    {'1': 'user_pic', '3': 16, '4': 1, '5': 9, '10': 'userPic'},
    {'1': 'decline_reason', '3': 17, '4': 1, '5': 9, '10': 'declineReason'},
    {'1': 'reviewed_by_iid', '3': 18, '4': 1, '5': 3, '10': 'reviewedByIid'},
    {'1': 'reviewer_name', '3': 19, '4': 1, '5': 9, '10': 'reviewerName'},
    {'1': 'reviewer_pic', '3': 20, '4': 1, '5': 9, '10': 'reviewerPic'},
  ],
};

/// Descriptor for `CommissionWithdrawQueueItem`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List commissionWithdrawQueueItemDescriptor = $convert.base64Decode(
    'ChtDb21taXNzaW9uV2l0aGRyYXdRdWV1ZUl0ZW0SHQoKcmVxdWVzdF9pZBgBIAEoA1IJcmVxdW'
    'VzdElkEhsKCW93bmVyX2lpZBgCIAEoA1IIb3duZXJJaWQSHQoKYW1vdW50X3VzZBgDIAEoAVIJ'
    'YW1vdW50VXNkEh0KCmFtb3VudF9pZHIYBCABKAFSCWFtb3VudElkchIaCghjdXJyZW5jeRgFIA'
    'EoCVIIY3VycmVuY3kSIwoNcGF5b3V0X21ldGhvZBgGIAEoCVIMcGF5b3V0TWV0aG9kEhcKB2Jh'
    'bmtfaWQYByABKAlSBmJhbmtJZBImCg9iYW5rX3Nob3J0X25hbWUYCCABKAlSDWJhbmtTaG9ydE'
    '5hbWUSJQoOYWNjb3VudF9udW1iZXIYCSABKAlSDWFjY291bnROdW1iZXISIQoMYWNjb3VudF9u'
    'YW1lGAogASgJUgthY2NvdW50TmFtZRISCgRub3RlGAsgASgJUgRub3RlEiwKEnRyYW5zZmVyX3'
    'Byb29mX3VybBgMIAEoCVIQdHJhbnNmZXJQcm9vZlVybBIWCgZzdGF0dXMYDSABKAlSBnN0YXR1'
    'cxIiCg1jcmVhdGVkX3RzX21zGA4gASgDUgtjcmVhdGVkVHNNcxIbCgl1c2VyX25hbWUYDyABKA'
    'lSCHVzZXJOYW1lEhkKCHVzZXJfcGljGBAgASgJUgd1c2VyUGljEiUKDmRlY2xpbmVfcmVhc29u'
    'GBEgASgJUg1kZWNsaW5lUmVhc29uEiYKD3Jldmlld2VkX2J5X2lpZBgSIAEoA1INcmV2aWV3ZW'
    'RCeUlpZBIjCg1yZXZpZXdlcl9uYW1lGBMgASgJUgxyZXZpZXdlck5hbWUSIQoMcmV2aWV3ZXJf'
    'cGljGBQgASgJUgtyZXZpZXdlclBpYw==');

@$core.Deprecated('Use reqCommissionWithdrawListDescriptor instead')
const ReqCommissionWithdrawList$json = {
  '1': 'ReqCommissionWithdrawList',
  '2': [
    {'1': 'status', '3': 1, '4': 1, '5': 9, '10': 'status'},
    {'1': 'limit', '3': 2, '4': 1, '5': 5, '10': 'limit'},
  ],
};

/// Descriptor for `ReqCommissionWithdrawList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqCommissionWithdrawListDescriptor =
    $convert.base64Decode(
        'ChlSZXFDb21taXNzaW9uV2l0aGRyYXdMaXN0EhYKBnN0YXR1cxgBIAEoCVIGc3RhdHVzEhQKBW'
        'xpbWl0GAIgASgFUgVsaW1pdA==');

@$core.Deprecated('Use resCommissionWithdrawListDescriptor instead')
const ResCommissionWithdrawList$json = {
  '1': 'ResCommissionWithdrawList',
  '2': [
    {
      '1': 'requests',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.c35.CommissionWithdrawQueueItem',
      '10': 'requests'
    },
  ],
};

/// Descriptor for `ResCommissionWithdrawList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resCommissionWithdrawListDescriptor =
    $convert.base64Decode(
        'ChlSZXNDb21taXNzaW9uV2l0aGRyYXdMaXN0EjwKCHJlcXVlc3RzGAEgAygLMiAuYzM1LkNvbW'
        '1pc3Npb25XaXRoZHJhd1F1ZXVlSXRlbVIIcmVxdWVzdHM=');

@$core.Deprecated('Use reqCommissionWithdrawReviewDescriptor instead')
const ReqCommissionWithdrawReview$json = {
  '1': 'ReqCommissionWithdrawReview',
  '2': [
    {'1': 'request_id', '3': 1, '4': 1, '5': 3, '10': 'requestId'},
    {'1': 'action', '3': 2, '4': 1, '5': 9, '10': 'action'},
    {
      '1': 'transfer_proof_url',
      '3': 3,
      '4': 1,
      '5': 9,
      '10': 'transferProofUrl'
    },
    {'1': 'reason', '3': 4, '4': 1, '5': 9, '10': 'reason'},
  ],
};

/// Descriptor for `ReqCommissionWithdrawReview`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqCommissionWithdrawReviewDescriptor =
    $convert.base64Decode(
        'ChtSZXFDb21taXNzaW9uV2l0aGRyYXdSZXZpZXcSHQoKcmVxdWVzdF9pZBgBIAEoA1IJcmVxdW'
        'VzdElkEhYKBmFjdGlvbhgCIAEoCVIGYWN0aW9uEiwKEnRyYW5zZmVyX3Byb29mX3VybBgDIAEo'
        'CVIQdHJhbnNmZXJQcm9vZlVybBIWCgZyZWFzb24YBCABKAlSBnJlYXNvbg==');

@$core.Deprecated('Use resCommissionWithdrawReviewDescriptor instead')
const ResCommissionWithdrawReview$json = {
  '1': 'ResCommissionWithdrawReview',
};

/// Descriptor for `ResCommissionWithdrawReview`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resCommissionWithdrawReviewDescriptor =
    $convert.base64Decode('ChtSZXNDb21taXNzaW9uV2l0aGRyYXdSZXZpZXc=');

@$core.Deprecated('Use billingReceiveAccountDescriptor instead')
const BillingReceiveAccount$json = {
  '1': 'BillingReceiveAccount',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 3, '10': 'id'},
    {'1': 'bank_id', '3': 2, '4': 1, '5': 9, '10': 'bankId'},
    {'1': 'account_number', '3': 3, '4': 1, '5': 9, '10': 'accountNumber'},
    {'1': 'account_name', '3': 4, '4': 1, '5': 9, '10': 'accountName'},
    {'1': 'currency', '3': 5, '4': 1, '5': 9, '10': 'currency'},
    {'1': 'is_active', '3': 6, '4': 1, '5': 8, '10': 'isActive'},
    {'1': 'is_default', '3': 7, '4': 1, '5': 8, '10': 'isDefault'},
    {'1': 'label', '3': 8, '4': 1, '5': 9, '10': 'label'},
    {'1': 'created_by_iid', '3': 9, '4': 1, '5': 3, '10': 'createdByIid'},
    {'1': 'meta_json', '3': 10, '4': 1, '5': 9, '10': 'metaJson'},
    {'1': 'created_ts_ms', '3': 11, '4': 1, '5': 3, '10': 'createdTsMs'},
    {'1': 'updated_ts_ms', '3': 12, '4': 1, '5': 3, '10': 'updatedTsMs'},
  ],
};

/// Descriptor for `BillingReceiveAccount`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List billingReceiveAccountDescriptor = $convert.base64Decode(
    'ChVCaWxsaW5nUmVjZWl2ZUFjY291bnQSDgoCaWQYASABKANSAmlkEhcKB2JhbmtfaWQYAiABKA'
    'lSBmJhbmtJZBIlCg5hY2NvdW50X251bWJlchgDIAEoCVINYWNjb3VudE51bWJlchIhCgxhY2Nv'
    'dW50X25hbWUYBCABKAlSC2FjY291bnROYW1lEhoKCGN1cnJlbmN5GAUgASgJUghjdXJyZW5jeR'
    'IbCglpc19hY3RpdmUYBiABKAhSCGlzQWN0aXZlEh0KCmlzX2RlZmF1bHQYByABKAhSCWlzRGVm'
    'YXVsdBIUCgVsYWJlbBgIIAEoCVIFbGFiZWwSJAoOY3JlYXRlZF9ieV9paWQYCSABKANSDGNyZW'
    'F0ZWRCeUlpZBIbCgltZXRhX2pzb24YCiABKAlSCG1ldGFKc29uEiIKDWNyZWF0ZWRfdHNfbXMY'
    'CyABKANSC2NyZWF0ZWRUc01zEiIKDXVwZGF0ZWRfdHNfbXMYDCABKANSC3VwZGF0ZWRUc01z');

@$core.Deprecated('Use reqBillingReceiveAccountPutDescriptor instead')
const ReqBillingReceiveAccountPut$json = {
  '1': 'ReqBillingReceiveAccountPut',
  '2': [
    {
      '1': 'account',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.c35.BillingReceiveAccount',
      '10': 'account'
    },
  ],
};

/// Descriptor for `ReqBillingReceiveAccountPut`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqBillingReceiveAccountPutDescriptor =
    $convert.base64Decode(
        'ChtSZXFCaWxsaW5nUmVjZWl2ZUFjY291bnRQdXQSNAoHYWNjb3VudBgBIAEoCzIaLmMzNS5CaW'
        'xsaW5nUmVjZWl2ZUFjY291bnRSB2FjY291bnQ=');

@$core.Deprecated('Use resBillingReceiveAccountPutDescriptor instead')
const ResBillingReceiveAccountPut$json = {
  '1': 'ResBillingReceiveAccountPut',
  '2': [
    {
      '1': 'account',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.c35.BillingReceiveAccount',
      '10': 'account'
    },
  ],
};

/// Descriptor for `ResBillingReceiveAccountPut`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resBillingReceiveAccountPutDescriptor =
    $convert.base64Decode(
        'ChtSZXNCaWxsaW5nUmVjZWl2ZUFjY291bnRQdXQSNAoHYWNjb3VudBgBIAEoCzIaLmMzNS5CaW'
        'xsaW5nUmVjZWl2ZUFjY291bnRSB2FjY291bnQ=');

@$core.Deprecated('Use reqBillingReceiveAccountListDescriptor instead')
const ReqBillingReceiveAccountList$json = {
  '1': 'ReqBillingReceiveAccountList',
  '2': [
    {'1': 'currency', '3': 1, '4': 1, '5': 9, '10': 'currency'},
    {'1': 'active_only', '3': 2, '4': 1, '5': 8, '10': 'activeOnly'},
  ],
};

/// Descriptor for `ReqBillingReceiveAccountList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqBillingReceiveAccountListDescriptor =
    $convert.base64Decode(
        'ChxSZXFCaWxsaW5nUmVjZWl2ZUFjY291bnRMaXN0EhoKCGN1cnJlbmN5GAEgASgJUghjdXJyZW'
        '5jeRIfCgthY3RpdmVfb25seRgCIAEoCFIKYWN0aXZlT25seQ==');

@$core.Deprecated('Use resBillingReceiveAccountListDescriptor instead')
const ResBillingReceiveAccountList$json = {
  '1': 'ResBillingReceiveAccountList',
  '2': [
    {
      '1': 'accounts',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.c35.BillingReceiveAccount',
      '10': 'accounts'
    },
  ],
};

/// Descriptor for `ResBillingReceiveAccountList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resBillingReceiveAccountListDescriptor =
    $convert.base64Decode(
        'ChxSZXNCaWxsaW5nUmVjZWl2ZUFjY291bnRMaXN0EjYKCGFjY291bnRzGAEgAygLMhouYzM1Lk'
        'JpbGxpbmdSZWNlaXZlQWNjb3VudFIIYWNjb3VudHM=');

@$core.Deprecated('Use reqBillingPlanSubscribeDescriptor instead')
const ReqBillingPlanSubscribe$json = {
  '1': 'ReqBillingPlanSubscribe',
  '2': [
    {'1': 'plan_slug', '3': 1, '4': 1, '5': 9, '10': 'planSlug'},
    {'1': 'currency', '3': 2, '4': 1, '5': 9, '10': 'currency'},
    {'1': 'wallet_id', '3': 3, '4': 1, '5': 3, '10': 'walletId'},
    {'1': 'direct_purchase', '3': 4, '4': 1, '5': 8, '10': 'directPurchase'},
    {'1': 'billing_period', '3': 5, '4': 1, '5': 9, '10': 'billingPeriod'},
  ],
};

/// Descriptor for `ReqBillingPlanSubscribe`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqBillingPlanSubscribeDescriptor = $convert.base64Decode(
    'ChdSZXFCaWxsaW5nUGxhblN1YnNjcmliZRIbCglwbGFuX3NsdWcYASABKAlSCHBsYW5TbHVnEh'
    'oKCGN1cnJlbmN5GAIgASgJUghjdXJyZW5jeRIbCgl3YWxsZXRfaWQYAyABKANSCHdhbGxldElk'
    'EicKD2RpcmVjdF9wdXJjaGFzZRgEIAEoCFIOZGlyZWN0UHVyY2hhc2USJQoOYmlsbGluZ19wZX'
    'Jpb2QYBSABKAlSDWJpbGxpbmdQZXJpb2Q=');

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
    {
      '1': 'price_idr_monthly',
      '3': 12,
      '4': 1,
      '5': 1,
      '10': 'priceIdrMonthly'
    },
    {'1': 'price_idr_yearly', '3': 13, '4': 1, '5': 1, '10': 'priceIdrYearly'},
    {
      '1': 'alien_pool_idr_monthly',
      '3': 14,
      '4': 1,
      '5': 1,
      '10': 'alienPoolIdrMonthly'
    },
    {
      '1': 'frontier_pool_idr_monthly',
      '3': 15,
      '4': 1,
      '5': 1,
      '10': 'frontierPoolIdrMonthly'
    },
    {'1': 'pool_multiplier', '3': 16, '4': 1, '5': 1, '10': 'poolMultiplier'},
    {'1': 'tier', '3': 17, '4': 1, '5': 9, '10': 'tier'},
    {
      '1': 'queue_priority_multiplier',
      '3': 18,
      '4': 1,
      '5': 5,
      '10': 'queuePriorityMultiplier'
    },
    {'1': 'priority_queue', '3': 19, '4': 1, '5': 8, '10': 'priorityQueue'},
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
    'sgASgIUg5vdmVyYWdlRW5hYmxlZBIqChFwcmljZV9pZHJfbW9udGhseRgMIAEoAVIPcHJpY2VJ'
    'ZHJNb250aGx5EigKEHByaWNlX2lkcl95ZWFybHkYDSABKAFSDnByaWNlSWRyWWVhcmx5EjMKFm'
    'FsaWVuX3Bvb2xfaWRyX21vbnRobHkYDiABKAFSE2FsaWVuUG9vbElkck1vbnRobHkSOQoZZnJv'
    'bnRpZXJfcG9vbF9pZHJfbW9udGhseRgPIAEoAVIWZnJvbnRpZXJQb29sSWRyTW9udGhseRInCg'
    '9wb29sX211bHRpcGxpZXIYECABKAFSDnBvb2xNdWx0aXBsaWVyEhIKBHRpZXIYESABKAlSBHRp'
    'ZXISOgoZcXVldWVfcHJpb3JpdHlfbXVsdGlwbGllchgSIAEoBVIXcXVldWVQcmlvcml0eU11bH'
    'RpcGxpZXISJQoOcHJpb3JpdHlfcXVldWUYEyABKAhSDXByaW9yaXR5UXVldWU=');

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

@$core.Deprecated('Use billingPromotionDescriptor instead')
const BillingPromotion$json = {
  '1': 'BillingPromotion',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 3, '10': 'id'},
    {'1': 'code', '3': 2, '4': 1, '5': 9, '10': 'code'},
    {'1': 'type', '3': 3, '4': 1, '5': 9, '10': 'type'},
    {'1': 'audience', '3': 4, '4': 1, '5': 9, '10': 'audience'},
    {'1': 'name', '3': 5, '4': 1, '5': 9, '10': 'name'},
    {'1': 'base_plan_slug', '3': 6, '4': 1, '5': 9, '10': 'basePlanSlug'},
    {'1': 'pool_multiplier', '3': 7, '4': 1, '5': 1, '10': 'poolMultiplier'},
    {'1': 'alien_pool_idr', '3': 8, '4': 1, '5': 1, '10': 'alienPoolIdr'},
    {'1': 'frontier_pool_idr', '3': 9, '4': 1, '5': 1, '10': 'frontierPoolIdr'},
    {'1': 'duration_days', '3': 10, '4': 1, '5': 5, '10': 'durationDays'},
    {'1': 'duration_minutes', '3': 11, '4': 1, '5': 5, '10': 'durationMinutes'},
    {'1': 'max_claims_total', '3': 12, '4': 1, '5': 5, '10': 'maxClaimsTotal'},
    {
      '1': 'max_claims_per_email',
      '3': 13,
      '4': 1,
      '5': 5,
      '10': 'maxClaimsPerEmail'
    },
    {'1': 'valid_from_ms', '3': 14, '4': 1, '5': 3, '10': 'validFromMs'},
    {'1': 'valid_to_ms', '3': 15, '4': 1, '5': 3, '10': 'validToMs'},
    {'1': 'scope', '3': 16, '4': 1, '5': 9, '10': 'scope'},
    {'1': 'is_active', '3': 17, '4': 1, '5': 8, '10': 'isActive'},
    {'1': 'created_by_iid', '3': 18, '4': 1, '5': 3, '10': 'createdByIid'},
    {'1': 'claims_count', '3': 19, '4': 1, '5': 5, '10': 'claimsCount'},
    {'1': 'created_ts_ms', '3': 20, '4': 1, '5': 3, '10': 'createdTsMs'},
    {'1': 'meta_json', '3': 21, '4': 1, '5': 9, '10': 'metaJson'},
    {'1': 'updated_ts_ms', '3': 22, '4': 1, '5': 3, '10': 'updatedTsMs'},
  ],
};

/// Descriptor for `BillingPromotion`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List billingPromotionDescriptor = $convert.base64Decode(
    'ChBCaWxsaW5nUHJvbW90aW9uEg4KAmlkGAEgASgDUgJpZBISCgRjb2RlGAIgASgJUgRjb2RlEh'
    'IKBHR5cGUYAyABKAlSBHR5cGUSGgoIYXVkaWVuY2UYBCABKAlSCGF1ZGllbmNlEhIKBG5hbWUY'
    'BSABKAlSBG5hbWUSJAoOYmFzZV9wbGFuX3NsdWcYBiABKAlSDGJhc2VQbGFuU2x1ZxInCg9wb2'
    '9sX211bHRpcGxpZXIYByABKAFSDnBvb2xNdWx0aXBsaWVyEiQKDmFsaWVuX3Bvb2xfaWRyGAgg'
    'ASgBUgxhbGllblBvb2xJZHISKgoRZnJvbnRpZXJfcG9vbF9pZHIYCSABKAFSD2Zyb250aWVyUG'
    '9vbElkchIjCg1kdXJhdGlvbl9kYXlzGAogASgFUgxkdXJhdGlvbkRheXMSKQoQZHVyYXRpb25f'
    'bWludXRlcxgLIAEoBVIPZHVyYXRpb25NaW51dGVzEigKEG1heF9jbGFpbXNfdG90YWwYDCABKA'
    'VSDm1heENsYWltc1RvdGFsEi8KFG1heF9jbGFpbXNfcGVyX2VtYWlsGA0gASgFUhFtYXhDbGFp'
    'bXNQZXJFbWFpbBIiCg12YWxpZF9mcm9tX21zGA4gASgDUgt2YWxpZEZyb21NcxIeCgt2YWxpZF'
    '90b19tcxgPIAEoA1IJdmFsaWRUb01zEhQKBXNjb3BlGBAgASgJUgVzY29wZRIbCglpc19hY3Rp'
    'dmUYESABKAhSCGlzQWN0aXZlEiQKDmNyZWF0ZWRfYnlfaWlkGBIgASgDUgxjcmVhdGVkQnlJaW'
    'QSIQoMY2xhaW1zX2NvdW50GBMgASgFUgtjbGFpbXNDb3VudBIiCg1jcmVhdGVkX3RzX21zGBQg'
    'ASgDUgtjcmVhdGVkVHNNcxIbCgltZXRhX2pzb24YFSABKAlSCG1ldGFKc29uEiIKDXVwZGF0ZW'
    'RfdHNfbXMYFiABKANSC3VwZGF0ZWRUc01z');

@$core.Deprecated('Use billingPromotionClaimDescriptor instead')
const BillingPromotionClaim$json = {
  '1': 'BillingPromotionClaim',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 3, '10': 'id'},
    {'1': 'promotion_id', '3': 2, '4': 1, '5': 3, '10': 'promotionId'},
    {'1': 'owner_iid', '3': 3, '4': 1, '5': 3, '10': 'ownerIid'},
    {'1': 'email', '3': 4, '4': 1, '5': 9, '10': 'email'},
    {'1': 'expires_ts_ms', '3': 5, '4': 1, '5': 3, '10': 'expiresTsMs'},
    {
      '1': 'alien_pool_used_idr',
      '3': 6,
      '4': 1,
      '5': 1,
      '10': 'alienPoolUsedIdr'
    },
    {
      '1': 'frontier_pool_used_idr',
      '3': 7,
      '4': 1,
      '5': 1,
      '10': 'frontierPoolUsedIdr'
    },
    {'1': 'meta_json', '3': 8, '4': 1, '5': 9, '10': 'metaJson'},
    {'1': 'created_ts_ms', '3': 9, '4': 1, '5': 3, '10': 'createdTsMs'},
  ],
};

/// Descriptor for `BillingPromotionClaim`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List billingPromotionClaimDescriptor = $convert.base64Decode(
    'ChVCaWxsaW5nUHJvbW90aW9uQ2xhaW0SDgoCaWQYASABKANSAmlkEiEKDHByb21vdGlvbl9pZB'
    'gCIAEoA1ILcHJvbW90aW9uSWQSGwoJb3duZXJfaWlkGAMgASgDUghvd25lcklpZBIUCgVlbWFp'
    'bBgEIAEoCVIFZW1haWwSIgoNZXhwaXJlc190c19tcxgFIAEoA1ILZXhwaXJlc1RzTXMSLQoTYW'
    'xpZW5fcG9vbF91c2VkX2lkchgGIAEoAVIQYWxpZW5Qb29sVXNlZElkchIzChZmcm9udGllcl9w'
    'b29sX3VzZWRfaWRyGAcgASgBUhNmcm9udGllclBvb2xVc2VkSWRyEhsKCW1ldGFfanNvbhgIIA'
    'EoCVIIbWV0YUpzb24SIgoNY3JlYXRlZF90c19tcxgJIAEoA1ILY3JlYXRlZFRzTXM=');

@$core.Deprecated('Use reqBillingPromotionCreateDescriptor instead')
const ReqBillingPromotionCreate$json = {
  '1': 'ReqBillingPromotionCreate',
  '2': [
    {'1': 'code', '3': 1, '4': 1, '5': 9, '10': 'code'},
    {'1': 'type', '3': 2, '4': 1, '5': 9, '10': 'type'},
    {'1': 'audience', '3': 3, '4': 1, '5': 9, '10': 'audience'},
    {'1': 'name', '3': 4, '4': 1, '5': 9, '10': 'name'},
    {'1': 'base_plan_slug', '3': 5, '4': 1, '5': 9, '10': 'basePlanSlug'},
    {'1': 'pool_multiplier', '3': 6, '4': 1, '5': 1, '10': 'poolMultiplier'},
    {'1': 'alien_pool_idr', '3': 7, '4': 1, '5': 1, '10': 'alienPoolIdr'},
    {'1': 'frontier_pool_idr', '3': 8, '4': 1, '5': 1, '10': 'frontierPoolIdr'},
    {'1': 'duration_days', '3': 9, '4': 1, '5': 5, '10': 'durationDays'},
    {'1': 'duration_minutes', '3': 10, '4': 1, '5': 5, '10': 'durationMinutes'},
    {'1': 'max_claims_total', '3': 11, '4': 1, '5': 5, '10': 'maxClaimsTotal'},
    {
      '1': 'max_claims_per_email',
      '3': 12,
      '4': 1,
      '5': 5,
      '10': 'maxClaimsPerEmail'
    },
    {'1': 'valid_from_ms', '3': 13, '4': 1, '5': 3, '10': 'validFromMs'},
    {'1': 'valid_to_ms', '3': 14, '4': 1, '5': 3, '10': 'validToMs'},
    {'1': 'scope', '3': 15, '4': 1, '5': 9, '10': 'scope'},
    {'1': 'is_active', '3': 16, '4': 1, '5': 8, '10': 'isActive'},
  ],
};

/// Descriptor for `ReqBillingPromotionCreate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqBillingPromotionCreateDescriptor = $convert.base64Decode(
    'ChlSZXFCaWxsaW5nUHJvbW90aW9uQ3JlYXRlEhIKBGNvZGUYASABKAlSBGNvZGUSEgoEdHlwZR'
    'gCIAEoCVIEdHlwZRIaCghhdWRpZW5jZRgDIAEoCVIIYXVkaWVuY2USEgoEbmFtZRgEIAEoCVIE'
    'bmFtZRIkCg5iYXNlX3BsYW5fc2x1ZxgFIAEoCVIMYmFzZVBsYW5TbHVnEicKD3Bvb2xfbXVsdG'
    'lwbGllchgGIAEoAVIOcG9vbE11bHRpcGxpZXISJAoOYWxpZW5fcG9vbF9pZHIYByABKAFSDGFs'
    'aWVuUG9vbElkchIqChFmcm9udGllcl9wb29sX2lkchgIIAEoAVIPZnJvbnRpZXJQb29sSWRyEi'
    'MKDWR1cmF0aW9uX2RheXMYCSABKAVSDGR1cmF0aW9uRGF5cxIpChBkdXJhdGlvbl9taW51dGVz'
    'GAogASgFUg9kdXJhdGlvbk1pbnV0ZXMSKAoQbWF4X2NsYWltc190b3RhbBgLIAEoBVIObWF4Q2'
    'xhaW1zVG90YWwSLwoUbWF4X2NsYWltc19wZXJfZW1haWwYDCABKAVSEW1heENsYWltc1BlckVt'
    'YWlsEiIKDXZhbGlkX2Zyb21fbXMYDSABKANSC3ZhbGlkRnJvbU1zEh4KC3ZhbGlkX3RvX21zGA'
    '4gASgDUgl2YWxpZFRvTXMSFAoFc2NvcGUYDyABKAlSBXNjb3BlEhsKCWlzX2FjdGl2ZRgQIAEo'
    'CFIIaXNBY3RpdmU=');

@$core.Deprecated('Use resBillingPromotionCreateDescriptor instead')
const ResBillingPromotionCreate$json = {
  '1': 'ResBillingPromotionCreate',
  '2': [
    {'1': 'promotion_id', '3': 1, '4': 1, '5': 3, '10': 'promotionId'},
    {
      '1': 'promotion',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.c35.BillingPromotion',
      '10': 'promotion'
    },
  ],
};

/// Descriptor for `ResBillingPromotionCreate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resBillingPromotionCreateDescriptor = $convert.base64Decode(
    'ChlSZXNCaWxsaW5nUHJvbW90aW9uQ3JlYXRlEiEKDHByb21vdGlvbl9pZBgBIAEoA1ILcHJvbW'
    '90aW9uSWQSMwoJcHJvbW90aW9uGAIgASgLMhUuYzM1LkJpbGxpbmdQcm9tb3Rpb25SCXByb21v'
    'dGlvbg==');

@$core.Deprecated('Use reqBillingPromotionClaimDescriptor instead')
const ReqBillingPromotionClaim$json = {
  '1': 'ReqBillingPromotionClaim',
  '2': [
    {'1': 'code', '3': 1, '4': 1, '5': 9, '10': 'code'},
    {'1': 'email', '3': 2, '4': 1, '5': 9, '10': 'email'},
    {'1': 'promotion_id', '3': 3, '4': 1, '5': 3, '10': 'promotionId'},
  ],
};

/// Descriptor for `ReqBillingPromotionClaim`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqBillingPromotionClaimDescriptor =
    $convert.base64Decode(
        'ChhSZXFCaWxsaW5nUHJvbW90aW9uQ2xhaW0SEgoEY29kZRgBIAEoCVIEY29kZRIUCgVlbWFpbB'
        'gCIAEoCVIFZW1haWwSIQoMcHJvbW90aW9uX2lkGAMgASgDUgtwcm9tb3Rpb25JZA==');

@$core.Deprecated('Use resBillingPromotionClaimDescriptor instead')
const ResBillingPromotionClaim$json = {
  '1': 'ResBillingPromotionClaim',
  '2': [
    {'1': 'claim_id', '3': 1, '4': 1, '5': 3, '10': 'claimId'},
    {'1': 'promotion_id', '3': 2, '4': 1, '5': 3, '10': 'promotionId'},
    {
      '1': 'alien_pool_limit_idr',
      '3': 3,
      '4': 1,
      '5': 1,
      '10': 'alienPoolLimitIdr'
    },
    {
      '1': 'frontier_pool_limit_idr',
      '3': 4,
      '4': 1,
      '5': 1,
      '10': 'frontierPoolLimitIdr'
    },
    {'1': 'expires_ts_ms', '3': 5, '4': 1, '5': 3, '10': 'expiresTsMs'},
    {'1': 'plan_tier', '3': 6, '4': 1, '5': 9, '10': 'planTier'},
    {'1': 'promo_type', '3': 7, '4': 1, '5': 9, '10': 'promoType'},
    {
      '1': 'claim',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.c35.BillingPromotionClaim',
      '10': 'claim'
    },
    {
      '1': 'promotion',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.c35.BillingPromotion',
      '10': 'promotion'
    },
    {
      '1': 'profile',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.c35.BillingProfile',
      '10': 'profile'
    },
  ],
};

/// Descriptor for `ResBillingPromotionClaim`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resBillingPromotionClaimDescriptor = $convert.base64Decode(
    'ChhSZXNCaWxsaW5nUHJvbW90aW9uQ2xhaW0SGQoIY2xhaW1faWQYASABKANSB2NsYWltSWQSIQ'
    'oMcHJvbW90aW9uX2lkGAIgASgDUgtwcm9tb3Rpb25JZBIvChRhbGllbl9wb29sX2xpbWl0X2lk'
    'chgDIAEoAVIRYWxpZW5Qb29sTGltaXRJZHISNQoXZnJvbnRpZXJfcG9vbF9saW1pdF9pZHIYBC'
    'ABKAFSFGZyb250aWVyUG9vbExpbWl0SWRyEiIKDWV4cGlyZXNfdHNfbXMYBSABKANSC2V4cGly'
    'ZXNUc01zEhsKCXBsYW5fdGllchgGIAEoCVIIcGxhblRpZXISHQoKcHJvbW9fdHlwZRgHIAEoCV'
    'IJcHJvbW9UeXBlEjAKBWNsYWltGAggASgLMhouYzM1LkJpbGxpbmdQcm9tb3Rpb25DbGFpbVIF'
    'Y2xhaW0SMwoJcHJvbW90aW9uGAkgASgLMhUuYzM1LkJpbGxpbmdQcm9tb3Rpb25SCXByb21vdG'
    'lvbhItCgdwcm9maWxlGAogASgLMhMuYzM1LkJpbGxpbmdQcm9maWxlUgdwcm9maWxl');

@$core.Deprecated('Use reqBillingPromotionListDescriptor instead')
const ReqBillingPromotionList$json = {
  '1': 'ReqBillingPromotionList',
};

/// Descriptor for `ReqBillingPromotionList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqBillingPromotionListDescriptor =
    $convert.base64Decode('ChdSZXFCaWxsaW5nUHJvbW90aW9uTGlzdA==');

@$core.Deprecated('Use resBillingPromotionListDescriptor instead')
const ResBillingPromotionList$json = {
  '1': 'ResBillingPromotionList',
  '2': [
    {
      '1': 'items',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.c35.BillingPromotion',
      '10': 'items'
    },
  ],
};

/// Descriptor for `ResBillingPromotionList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resBillingPromotionListDescriptor =
    $convert.base64Decode(
        'ChdSZXNCaWxsaW5nUHJvbW90aW9uTGlzdBIrCgVpdGVtcxgBIAMoCzIVLmMzNS5CaWxsaW5nUH'
        'JvbW90aW9uUgVpdGVtcw==');

@$core.Deprecated('Use billingAdminAdjustReasonTotalDescriptor instead')
const BillingAdminAdjustReasonTotal$json = {
  '1': 'BillingAdminAdjustReasonTotal',
  '2': [
    {'1': 'reason', '3': 1, '4': 1, '5': 9, '10': 'reason'},
    {'1': 'amount_idr', '3': 2, '4': 1, '5': 1, '10': 'amountIdr'},
    {'1': 'amount_usd', '3': 3, '4': 1, '5': 1, '10': 'amountUsd'},
    {'1': 'count', '3': 4, '4': 1, '5': 5, '10': 'count'},
  ],
};

/// Descriptor for `BillingAdminAdjustReasonTotal`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List billingAdminAdjustReasonTotalDescriptor =
    $convert.base64Decode(
        'Ch1CaWxsaW5nQWRtaW5BZGp1c3RSZWFzb25Ub3RhbBIWCgZyZWFzb24YASABKAlSBnJlYXNvbh'
        'IdCgphbW91bnRfaWRyGAIgASgBUglhbW91bnRJZHISHQoKYW1vdW50X3VzZBgDIAEoAVIJYW1v'
        'dW50VXNkEhQKBWNvdW50GAQgASgFUgVjb3VudA==');

@$core.Deprecated('Use billingAdminAdjustEntryDescriptor instead')
const BillingAdminAdjustEntry$json = {
  '1': 'BillingAdminAdjustEntry',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 3, '10': 'id'},
    {'1': 'owner_iid', '3': 2, '4': 1, '5': 3, '10': 'ownerIid'},
    {'1': 'kind', '3': 3, '4': 1, '5': 9, '10': 'kind'},
    {'1': 'amount_usd', '3': 4, '4': 1, '5': 1, '10': 'amountUsd'},
    {'1': 'amount_idr', '3': 5, '4': 1, '5': 1, '10': 'amountIdr'},
    {'1': 'currency', '3': 6, '4': 1, '5': 9, '10': 'currency'},
    {'1': 'direction', '3': 7, '4': 1, '5': 9, '10': 'direction'},
    {'1': 'reason', '3': 8, '4': 1, '5': 9, '10': 'reason'},
    {'1': 'note', '3': 9, '4': 1, '5': 9, '10': 'note'},
    {'1': 'adjusted_by_iid', '3': 10, '4': 1, '5': 3, '10': 'adjustedByIid'},
    {'1': 'adjusted_by_name', '3': 11, '4': 1, '5': 9, '10': 'adjustedByName'},
    {'1': 'created_ts_ms', '3': 12, '4': 1, '5': 3, '10': 'createdTsMs'},
    {'1': 'owner_name', '3': 13, '4': 1, '5': 9, '10': 'ownerName'},
  ],
};

/// Descriptor for `BillingAdminAdjustEntry`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List billingAdminAdjustEntryDescriptor = $convert.base64Decode(
    'ChdCaWxsaW5nQWRtaW5BZGp1c3RFbnRyeRIOCgJpZBgBIAEoA1ICaWQSGwoJb3duZXJfaWlkGA'
    'IgASgDUghvd25lcklpZBISCgRraW5kGAMgASgJUgRraW5kEh0KCmFtb3VudF91c2QYBCABKAFS'
    'CWFtb3VudFVzZBIdCgphbW91bnRfaWRyGAUgASgBUglhbW91bnRJZHISGgoIY3VycmVuY3kYBi'
    'ABKAlSCGN1cnJlbmN5EhwKCWRpcmVjdGlvbhgHIAEoCVIJZGlyZWN0aW9uEhYKBnJlYXNvbhgI'
    'IAEoCVIGcmVhc29uEhIKBG5vdGUYCSABKAlSBG5vdGUSJgoPYWRqdXN0ZWRfYnlfaWlkGAogAS'
    'gDUg1hZGp1c3RlZEJ5SWlkEigKEGFkanVzdGVkX2J5X25hbWUYCyABKAlSDmFkanVzdGVkQnlO'
    'YW1lEiIKDWNyZWF0ZWRfdHNfbXMYDCABKANSC2NyZWF0ZWRUc01zEh0KCm93bmVyX25hbWUYDS'
    'ABKAlSCW93bmVyTmFtZQ==');

@$core.Deprecated('Use reqBillingAdminAdjustDescriptor instead')
const ReqBillingAdminAdjust$json = {
  '1': 'ReqBillingAdminAdjust',
  '2': [
    {'1': 'subject_uid', '3': 1, '4': 1, '5': 3, '10': 'subjectUid'},
    {'1': 'kind', '3': 2, '4': 1, '5': 9, '10': 'kind'},
    {'1': 'direction', '3': 3, '4': 1, '5': 9, '10': 'direction'},
    {'1': 'amount_idr', '3': 4, '4': 1, '5': 1, '10': 'amountIdr'},
    {'1': 'amount_usd', '3': 5, '4': 1, '5': 1, '10': 'amountUsd'},
    {'1': 'currency', '3': 6, '4': 1, '5': 9, '10': 'currency'},
    {'1': 'reason', '3': 7, '4': 1, '5': 9, '10': 'reason'},
    {'1': 'note', '3': 8, '4': 1, '5': 9, '10': 'note'},
  ],
};

/// Descriptor for `ReqBillingAdminAdjust`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqBillingAdminAdjustDescriptor = $convert.base64Decode(
    'ChVSZXFCaWxsaW5nQWRtaW5BZGp1c3QSHwoLc3ViamVjdF91aWQYASABKANSCnN1YmplY3RVaW'
    'QSEgoEa2luZBgCIAEoCVIEa2luZBIcCglkaXJlY3Rpb24YAyABKAlSCWRpcmVjdGlvbhIdCgph'
    'bW91bnRfaWRyGAQgASgBUglhbW91bnRJZHISHQoKYW1vdW50X3VzZBgFIAEoAVIJYW1vdW50VX'
    'NkEhoKCGN1cnJlbmN5GAYgASgJUghjdXJyZW5jeRIWCgZyZWFzb24YByABKAlSBnJlYXNvbhIS'
    'CgRub3RlGAggASgJUgRub3Rl');

@$core.Deprecated('Use resBillingAdminAdjustDescriptor instead')
const ResBillingAdminAdjust$json = {
  '1': 'ResBillingAdminAdjust',
  '2': [
    {'1': 'balance_idr', '3': 1, '4': 1, '5': 1, '10': 'balanceIdr'},
    {'1': 'balance_usd', '3': 2, '4': 1, '5': 1, '10': 'balanceUsd'},
    {
      '1': 'commission_available_idr',
      '3': 3,
      '4': 1,
      '5': 1,
      '10': 'commissionAvailableIdr'
    },
    {
      '1': 'commission_available_usd',
      '3': 4,
      '4': 1,
      '5': 1,
      '10': 'commissionAvailableUsd'
    },
    {'1': 'currency', '3': 5, '4': 1, '5': 9, '10': 'currency'},
  ],
};

/// Descriptor for `ResBillingAdminAdjust`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resBillingAdminAdjustDescriptor = $convert.base64Decode(
    'ChVSZXNCaWxsaW5nQWRtaW5BZGp1c3QSHwoLYmFsYW5jZV9pZHIYASABKAFSCmJhbGFuY2VJZH'
    'ISHwoLYmFsYW5jZV91c2QYAiABKAFSCmJhbGFuY2VVc2QSOAoYY29tbWlzc2lvbl9hdmFpbGFi'
    'bGVfaWRyGAMgASgBUhZjb21taXNzaW9uQXZhaWxhYmxlSWRyEjgKGGNvbW1pc3Npb25fYXZhaW'
    'xhYmxlX3VzZBgEIAEoAVIWY29tbWlzc2lvbkF2YWlsYWJsZVVzZBIaCghjdXJyZW5jeRgFIAEo'
    'CVIIY3VycmVuY3k=');

@$core.Deprecated('Use reqBillingAdminAdjustListDescriptor instead')
const ReqBillingAdminAdjustList$json = {
  '1': 'ReqBillingAdminAdjustList',
  '2': [
    {'1': 'subject_uid', '3': 1, '4': 1, '5': 3, '10': 'subjectUid'},
    {'1': 'kind', '3': 2, '4': 1, '5': 9, '10': 'kind'},
    {'1': 'reason', '3': 3, '4': 1, '5': 9, '10': 'reason'},
    {'1': 'from_ms', '3': 4, '4': 1, '5': 3, '10': 'fromMs'},
    {'1': 'to_ms', '3': 5, '4': 1, '5': 3, '10': 'toMs'},
    {'1': 'limit', '3': 6, '4': 1, '5': 5, '10': 'limit'},
  ],
};

/// Descriptor for `ReqBillingAdminAdjustList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reqBillingAdminAdjustListDescriptor = $convert.base64Decode(
    'ChlSZXFCaWxsaW5nQWRtaW5BZGp1c3RMaXN0Eh8KC3N1YmplY3RfdWlkGAEgASgDUgpzdWJqZW'
    'N0VWlkEhIKBGtpbmQYAiABKAlSBGtpbmQSFgoGcmVhc29uGAMgASgJUgZyZWFzb24SFwoHZnJv'
    'bV9tcxgEIAEoA1IGZnJvbU1zEhMKBXRvX21zGAUgASgDUgR0b01zEhQKBWxpbWl0GAYgASgFUg'
    'VsaW1pdA==');

@$core.Deprecated('Use resBillingAdminAdjustListDescriptor instead')
const ResBillingAdminAdjustList$json = {
  '1': 'ResBillingAdminAdjustList',
  '2': [
    {
      '1': 'items',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.c35.BillingAdminAdjustEntry',
      '10': 'items'
    },
    {
      '1': 'totals',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.c35.BillingAdminAdjustReasonTotal',
      '10': 'totals'
    },
  ],
};

/// Descriptor for `ResBillingAdminAdjustList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resBillingAdminAdjustListDescriptor = $convert.base64Decode(
    'ChlSZXNCaWxsaW5nQWRtaW5BZGp1c3RMaXN0EjIKBWl0ZW1zGAEgAygLMhwuYzM1LkJpbGxpbm'
    'dBZG1pbkFkanVzdEVudHJ5UgVpdGVtcxI6CgZ0b3RhbHMYAiADKAsyIi5jMzUuQmlsbGluZ0Fk'
    'bWluQWRqdXN0UmVhc29uVG90YWxSBnRvdGFscw==');

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
