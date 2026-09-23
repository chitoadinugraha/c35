// This is a generated file - do not edit.
//
// Generated from c35/wire.proto.

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

@$core.Deprecated('Use invokeReqDescriptor instead')
const InvokeReq$json = {
  '1': 'InvokeReq',
  '2': [
    {'1': 'req_id', '3': 1, '4': 1, '5': 9, '10': 'reqId'},
    {'1': 'caller_iid', '3': 2, '4': 1, '5': 3, '10': 'callerIid'},
    {
      '1': 'billing_topup_put',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqBillingTopupPut',
      '9': 0,
      '10': 'billingTopupPut'
    },
    {
      '1': 'billing_package_redeem',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqBillingPackageRedeem',
      '9': 0,
      '10': 'billingPackageRedeem'
    },
    {
      '1': 'billing_package_preview',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqBillingPackagePreview',
      '9': 0,
      '10': 'billingPackagePreview'
    },
    {
      '1': 'bot_usage_stats',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqBotUsageStats',
      '9': 0,
      '10': 'botUsageStats'
    },
    {
      '1': 'billing_summary',
      '3': 14,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqBillingSummary',
      '9': 0,
      '10': 'billingSummary'
    },
    {
      '1': 'billing_plan_subscribe',
      '3': 15,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqBillingPlanSubscribe',
      '9': 0,
      '10': 'billingPlanSubscribe'
    },
    {
      '1': 'billing_history',
      '3': 17,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqBillingHistory',
      '9': 0,
      '10': 'billingHistory'
    },
    {
      '1': 'billing_promotion_create',
      '3': 18,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqBillingPromotionCreate',
      '9': 0,
      '10': 'billingPromotionCreate'
    },
    {
      '1': 'billing_promotion_claim',
      '3': 19,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqBillingPromotionClaim',
      '9': 0,
      '10': 'billingPromotionClaim'
    },
    {
      '1': 'billing_promotion_list',
      '3': 20,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqBillingPromotionList',
      '9': 0,
      '10': 'billingPromotionList'
    },
    {
      '1': 'referral_share_set',
      '3': 62,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqReferralShareSet',
      '9': 0,
      '10': 'referralShareSet'
    },
    {
      '1': 'referral_tree_get',
      '3': 64,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqReferralTreeGet',
      '9': 0,
      '10': 'referralTreeGet'
    },
    {
      '1': 'referral_code_list',
      '3': 65,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqReferralCodeList',
      '9': 0,
      '10': 'referralCodeList'
    },
    {
      '1': 'referral_code_put',
      '3': 67,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqReferralCodePut',
      '9': 0,
      '10': 'referralCodePut'
    },
    {
      '1': 'referral_code_delete',
      '3': 68,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqReferralCodeDelete',
      '9': 0,
      '10': 'referralCodeDelete'
    },
    {
      '1': 'admin_user_search',
      '3': 90,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqAdminUserSearch',
      '9': 0,
      '10': 'adminUserSearch'
    },
    {
      '1': 'admin_user_put',
      '3': 91,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqAdminUserPut',
      '9': 0,
      '10': 'adminUserPut'
    },
    {
      '1': 'referral_user_stats',
      '3': 92,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqReferralUserStats',
      '9': 0,
      '10': 'referralUserStats'
    },
    {
      '1': 'referral_commission_simulate',
      '3': 93,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqReferralCommissionSimulate',
      '9': 0,
      '10': 'referralCommissionSimulate'
    },
    {
      '1': 'channel_telegram_connect',
      '3': 100,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqChannelTelegramConnect',
      '9': 0,
      '10': 'channelTelegramConnect'
    },
    {
      '1': 'channel_whatsapp_meta_connect',
      '3': 101,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqChannelWhatsappMetaConnect',
      '9': 0,
      '10': 'channelWhatsappMetaConnect'
    },
    {
      '1': 'device_pair',
      '3': 102,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqDevicePair',
      '9': 0,
      '10': 'devicePair'
    },
    {
      '1': 'consumption_put',
      '3': 16,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqConsumptionPut',
      '9': 0,
      '10': 'consumptionPut'
    },
    {
      '1': 'inst_list',
      '3': 103,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqInstList',
      '9': 0,
      '10': 'instList'
    },
    {
      '1': 'inst_get',
      '3': 104,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqInstGet',
      '9': 0,
      '10': 'instGet'
    },
    {
      '1': 'inst_put',
      '3': 105,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqInstPut',
      '9': 0,
      '10': 'instPut'
    },
    {
      '1': 'inst_delete',
      '3': 106,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqInstDelete',
      '9': 0,
      '10': 'instDelete'
    },
    {
      '1': 'voice_stt',
      '3': 107,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqVoiceStt',
      '9': 0,
      '10': 'voiceStt'
    },
    {
      '1': 'voice_tts',
      '3': 108,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqVoiceTts',
      '9': 0,
      '10': 'voiceTts'
    },
    {
      '1': 'admin_log_list',
      '3': 109,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqAdminLogList',
      '9': 0,
      '10': 'adminLogList'
    },
    {
      '1': 'translation_put',
      '3': 110,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqTranslationPut',
      '9': 0,
      '10': 'translationPut'
    },
    {
      '1': 'billing_topup_list',
      '3': 111,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqBillingTopupList',
      '9': 0,
      '10': 'billingTopupList'
    },
    {
      '1': 'billing_topup_review',
      '3': 112,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqBillingTopupReview',
      '9': 0,
      '10': 'billingTopupReview'
    },
    {
      '1': 'commission_withdraw',
      '3': 113,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqCommissionWithdraw',
      '9': 0,
      '10': 'commissionWithdraw'
    },
    {
      '1': 'commission_withdraw_list',
      '3': 114,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqCommissionWithdrawList',
      '9': 0,
      '10': 'commissionWithdrawList'
    },
    {
      '1': 'commission_withdraw_review',
      '3': 115,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqCommissionWithdrawReview',
      '9': 0,
      '10': 'commissionWithdrawReview'
    },
    {
      '1': 'referral_ledger_list',
      '3': 116,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqReferralLedgerList',
      '9': 0,
      '10': 'referralLedgerList'
    },
    {
      '1': 'billing_receive_account_put',
      '3': 117,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqBillingReceiveAccountPut',
      '9': 0,
      '10': 'billingReceiveAccountPut'
    },
    {
      '1': 'billing_receive_account_list',
      '3': 118,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqBillingReceiveAccountList',
      '9': 0,
      '10': 'billingReceiveAccountList'
    },
    {
      '1': 'object_alias_list',
      '3': 119,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqObjectAliasList',
      '9': 0,
      '10': 'objectAliasList'
    },
    {
      '1': 'object_alias_put',
      '3': 120,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqObjectAliasPut',
      '9': 0,
      '10': 'objectAliasPut'
    },
    {
      '1': 'object_normalizer_list',
      '3': 121,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqObjectNormalizerList',
      '9': 0,
      '10': 'objectNormalizerList'
    },
    {
      '1': 'billing_topup_methods',
      '3': 122,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqBillingTopupMethods',
      '9': 0,
      '10': 'billingTopupMethods'
    },
    {
      '1': 'billing_topup_get',
      '3': 123,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqBillingTopupGet',
      '9': 0,
      '10': 'billingTopupGet'
    },
  ],
  '8': [
    {'1': 'body'},
  ],
};

/// Descriptor for `InvokeReq`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List invokeReqDescriptor = $convert.base64Decode(
    'CglJbnZva2VSZXESFQoGcmVxX2lkGAEgASgJUgVyZXFJZBIdCgpjYWxsZXJfaWlkGAIgASgDUg'
    'ljYWxsZXJJaWQSRQoRYmlsbGluZ190b3B1cF9wdXQYCiABKAsyFy5jMzUuUmVxQmlsbGluZ1Rv'
    'cHVwUHV0SABSD2JpbGxpbmdUb3B1cFB1dBJUChZiaWxsaW5nX3BhY2thZ2VfcmVkZWVtGAsgAS'
    'gLMhwuYzM1LlJlcUJpbGxpbmdQYWNrYWdlUmVkZWVtSABSFGJpbGxpbmdQYWNrYWdlUmVkZWVt'
    'ElcKF2JpbGxpbmdfcGFja2FnZV9wcmV2aWV3GAwgASgLMh0uYzM1LlJlcUJpbGxpbmdQYWNrYW'
    'dlUHJldmlld0gAUhViaWxsaW5nUGFja2FnZVByZXZpZXcSPwoPYm90X3VzYWdlX3N0YXRzGA0g'
    'ASgLMhUuYzM1LlJlcUJvdFVzYWdlU3RhdHNIAFINYm90VXNhZ2VTdGF0cxJBCg9iaWxsaW5nX3'
    'N1bW1hcnkYDiABKAsyFi5jMzUuUmVxQmlsbGluZ1N1bW1hcnlIAFIOYmlsbGluZ1N1bW1hcnkS'
    'VAoWYmlsbGluZ19wbGFuX3N1YnNjcmliZRgPIAEoCzIcLmMzNS5SZXFCaWxsaW5nUGxhblN1Yn'
    'NjcmliZUgAUhRiaWxsaW5nUGxhblN1YnNjcmliZRJBCg9iaWxsaW5nX2hpc3RvcnkYESABKAsy'
    'Fi5jMzUuUmVxQmlsbGluZ0hpc3RvcnlIAFIOYmlsbGluZ0hpc3RvcnkSWgoYYmlsbGluZ19wcm'
    '9tb3Rpb25fY3JlYXRlGBIgASgLMh4uYzM1LlJlcUJpbGxpbmdQcm9tb3Rpb25DcmVhdGVIAFIW'
    'YmlsbGluZ1Byb21vdGlvbkNyZWF0ZRJXChdiaWxsaW5nX3Byb21vdGlvbl9jbGFpbRgTIAEoCz'
    'IdLmMzNS5SZXFCaWxsaW5nUHJvbW90aW9uQ2xhaW1IAFIVYmlsbGluZ1Byb21vdGlvbkNsYWlt'
    'ElQKFmJpbGxpbmdfcHJvbW90aW9uX2xpc3QYFCABKAsyHC5jMzUuUmVxQmlsbGluZ1Byb21vdG'
    'lvbkxpc3RIAFIUYmlsbGluZ1Byb21vdGlvbkxpc3QSSAoScmVmZXJyYWxfc2hhcmVfc2V0GD4g'
    'ASgLMhguYzM1LlJlcVJlZmVycmFsU2hhcmVTZXRIAFIQcmVmZXJyYWxTaGFyZVNldBJFChFyZW'
    'ZlcnJhbF90cmVlX2dldBhAIAEoCzIXLmMzNS5SZXFSZWZlcnJhbFRyZWVHZXRIAFIPcmVmZXJy'
    'YWxUcmVlR2V0EkgKEnJlZmVycmFsX2NvZGVfbGlzdBhBIAEoCzIYLmMzNS5SZXFSZWZlcnJhbE'
    'NvZGVMaXN0SABSEHJlZmVycmFsQ29kZUxpc3QSRQoRcmVmZXJyYWxfY29kZV9wdXQYQyABKAsy'
    'Fy5jMzUuUmVxUmVmZXJyYWxDb2RlUHV0SABSD3JlZmVycmFsQ29kZVB1dBJOChRyZWZlcnJhbF'
    '9jb2RlX2RlbGV0ZRhEIAEoCzIaLmMzNS5SZXFSZWZlcnJhbENvZGVEZWxldGVIAFIScmVmZXJy'
    'YWxDb2RlRGVsZXRlEkUKEWFkbWluX3VzZXJfc2VhcmNoGFogASgLMhcuYzM1LlJlcUFkbWluVX'
    'NlclNlYXJjaEgAUg9hZG1pblVzZXJTZWFyY2gSPAoOYWRtaW5fdXNlcl9wdXQYWyABKAsyFC5j'
    'MzUuUmVxQWRtaW5Vc2VyUHV0SABSDGFkbWluVXNlclB1dBJLChNyZWZlcnJhbF91c2VyX3N0YX'
    'RzGFwgASgLMhkuYzM1LlJlcVJlZmVycmFsVXNlclN0YXRzSABSEXJlZmVycmFsVXNlclN0YXRz'
    'EmYKHHJlZmVycmFsX2NvbW1pc3Npb25fc2ltdWxhdGUYXSABKAsyIi5jMzUuUmVxUmVmZXJyYW'
    'xDb21taXNzaW9uU2ltdWxhdGVIAFIacmVmZXJyYWxDb21taXNzaW9uU2ltdWxhdGUSWgoYY2hh'
    'bm5lbF90ZWxlZ3JhbV9jb25uZWN0GGQgASgLMh4uYzM1LlJlcUNoYW5uZWxUZWxlZ3JhbUNvbm'
    '5lY3RIAFIWY2hhbm5lbFRlbGVncmFtQ29ubmVjdBJnCh1jaGFubmVsX3doYXRzYXBwX21ldGFf'
    'Y29ubmVjdBhlIAEoCzIiLmMzNS5SZXFDaGFubmVsV2hhdHNhcHBNZXRhQ29ubmVjdEgAUhpjaG'
    'FubmVsV2hhdHNhcHBNZXRhQ29ubmVjdBI1CgtkZXZpY2VfcGFpchhmIAEoCzISLmMzNS5SZXFE'
    'ZXZpY2VQYWlySABSCmRldmljZVBhaXISQQoPY29uc3VtcHRpb25fcHV0GBAgASgLMhYuYzM1Ll'
    'JlcUNvbnN1bXB0aW9uUHV0SABSDmNvbnN1bXB0aW9uUHV0Ei8KCWluc3RfbGlzdBhnIAEoCzIQ'
    'LmMzNS5SZXFJbnN0TGlzdEgAUghpbnN0TGlzdBIsCghpbnN0X2dldBhoIAEoCzIPLmMzNS5SZX'
    'FJbnN0R2V0SABSB2luc3RHZXQSLAoIaW5zdF9wdXQYaSABKAsyDy5jMzUuUmVxSW5zdFB1dEgA'
    'UgdpbnN0UHV0EjUKC2luc3RfZGVsZXRlGGogASgLMhIuYzM1LlJlcUluc3REZWxldGVIAFIKaW'
    '5zdERlbGV0ZRIvCgl2b2ljZV9zdHQYayABKAsyEC5jMzUuUmVxVm9pY2VTdHRIAFIIdm9pY2VT'
    'dHQSLwoJdm9pY2VfdHRzGGwgASgLMhAuYzM1LlJlcVZvaWNlVHRzSABSCHZvaWNlVHRzEjwKDm'
    'FkbWluX2xvZ19saXN0GG0gASgLMhQuYzM1LlJlcUFkbWluTG9nTGlzdEgAUgxhZG1pbkxvZ0xp'
    'c3QSQQoPdHJhbnNsYXRpb25fcHV0GG4gASgLMhYuYzM1LlJlcVRyYW5zbGF0aW9uUHV0SABSDn'
    'RyYW5zbGF0aW9uUHV0EkgKEmJpbGxpbmdfdG9wdXBfbGlzdBhvIAEoCzIYLmMzNS5SZXFCaWxs'
    'aW5nVG9wdXBMaXN0SABSEGJpbGxpbmdUb3B1cExpc3QSTgoUYmlsbGluZ190b3B1cF9yZXZpZX'
    'cYcCABKAsyGi5jMzUuUmVxQmlsbGluZ1RvcHVwUmV2aWV3SABSEmJpbGxpbmdUb3B1cFJldmll'
    'dxJNChNjb21taXNzaW9uX3dpdGhkcmF3GHEgASgLMhouYzM1LlJlcUNvbW1pc3Npb25XaXRoZH'
    'Jhd0gAUhJjb21taXNzaW9uV2l0aGRyYXcSWgoYY29tbWlzc2lvbl93aXRoZHJhd19saXN0GHIg'
    'ASgLMh4uYzM1LlJlcUNvbW1pc3Npb25XaXRoZHJhd0xpc3RIAFIWY29tbWlzc2lvbldpdGhkcm'
    'F3TGlzdBJgChpjb21taXNzaW9uX3dpdGhkcmF3X3JldmlldxhzIAEoCzIgLmMzNS5SZXFDb21t'
    'aXNzaW9uV2l0aGRyYXdSZXZpZXdIAFIYY29tbWlzc2lvbldpdGhkcmF3UmV2aWV3Ek4KFHJlZm'
    'VycmFsX2xlZGdlcl9saXN0GHQgASgLMhouYzM1LlJlcVJlZmVycmFsTGVkZ2VyTGlzdEgAUhJy'
    'ZWZlcnJhbExlZGdlckxpc3QSYQobYmlsbGluZ19yZWNlaXZlX2FjY291bnRfcHV0GHUgASgLMi'
    'AuYzM1LlJlcUJpbGxpbmdSZWNlaXZlQWNjb3VudFB1dEgAUhhiaWxsaW5nUmVjZWl2ZUFjY291'
    'bnRQdXQSZAocYmlsbGluZ19yZWNlaXZlX2FjY291bnRfbGlzdBh2IAEoCzIhLmMzNS5SZXFCaW'
    'xsaW5nUmVjZWl2ZUFjY291bnRMaXN0SABSGWJpbGxpbmdSZWNlaXZlQWNjb3VudExpc3QSRQoR'
    'b2JqZWN0X2FsaWFzX2xpc3QYdyABKAsyFy5jMzUuUmVxT2JqZWN0QWxpYXNMaXN0SABSD29iam'
    'VjdEFsaWFzTGlzdBJCChBvYmplY3RfYWxpYXNfcHV0GHggASgLMhYuYzM1LlJlcU9iamVjdEFs'
    'aWFzUHV0SABSDm9iamVjdEFsaWFzUHV0ElQKFm9iamVjdF9ub3JtYWxpemVyX2xpc3QYeSABKA'
    'syHC5jMzUuUmVxT2JqZWN0Tm9ybWFsaXplckxpc3RIAFIUb2JqZWN0Tm9ybWFsaXplckxpc3QS'
    'UQoVYmlsbGluZ190b3B1cF9tZXRob2RzGHogASgLMhsuYzM1LlJlcUJpbGxpbmdUb3B1cE1ldG'
    'hvZHNIAFITYmlsbGluZ1RvcHVwTWV0aG9kcxJFChFiaWxsaW5nX3RvcHVwX2dldBh7IAEoCzIX'
    'LmMzNS5SZXFCaWxsaW5nVG9wdXBHZXRIAFIPYmlsbGluZ1RvcHVwR2V0QgYKBGJvZHk=');

@$core.Deprecated('Use invokeResDescriptor instead')
const InvokeRes$json = {
  '1': 'InvokeRes',
  '2': [
    {'1': 'req_id', '3': 1, '4': 1, '5': 9, '10': 'reqId'},
    {'1': 'status_code', '3': 2, '4': 1, '5': 5, '10': 'statusCode'},
    {'1': 'error_message', '3': 3, '4': 1, '5': 9, '10': 'errorMessage'},
    {
      '1': 'billing_topup_put',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.c35.ResBillingTopupPut',
      '9': 0,
      '10': 'billingTopupPut'
    },
    {
      '1': 'billing_package_redeem',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.c35.ResBillingPackageRedeem',
      '9': 0,
      '10': 'billingPackageRedeem'
    },
    {
      '1': 'billing_package_preview',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.c35.ResBillingPackagePreview',
      '9': 0,
      '10': 'billingPackagePreview'
    },
    {
      '1': 'bot_usage_stats',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.c35.ResBotUsageStats',
      '9': 0,
      '10': 'botUsageStats'
    },
    {
      '1': 'billing_summary',
      '3': 14,
      '4': 1,
      '5': 11,
      '6': '.c35.ResBillingSummary',
      '9': 0,
      '10': 'billingSummary'
    },
    {
      '1': 'billing_plan_subscribe',
      '3': 15,
      '4': 1,
      '5': 11,
      '6': '.c35.ResBillingPlanSubscribe',
      '9': 0,
      '10': 'billingPlanSubscribe'
    },
    {
      '1': 'billing_history',
      '3': 17,
      '4': 1,
      '5': 11,
      '6': '.c35.ResBillingHistory',
      '9': 0,
      '10': 'billingHistory'
    },
    {
      '1': 'billing_promotion_create',
      '3': 18,
      '4': 1,
      '5': 11,
      '6': '.c35.ResBillingPromotionCreate',
      '9': 0,
      '10': 'billingPromotionCreate'
    },
    {
      '1': 'billing_promotion_claim',
      '3': 19,
      '4': 1,
      '5': 11,
      '6': '.c35.ResBillingPromotionClaim',
      '9': 0,
      '10': 'billingPromotionClaim'
    },
    {
      '1': 'billing_promotion_list',
      '3': 20,
      '4': 1,
      '5': 11,
      '6': '.c35.ResBillingPromotionList',
      '9': 0,
      '10': 'billingPromotionList'
    },
    {
      '1': 'referral_share_set',
      '3': 62,
      '4': 1,
      '5': 11,
      '6': '.c35.ResReferralShareSet',
      '9': 0,
      '10': 'referralShareSet'
    },
    {
      '1': 'referral_tree_get',
      '3': 64,
      '4': 1,
      '5': 11,
      '6': '.c35.ResReferralTreeGet',
      '9': 0,
      '10': 'referralTreeGet'
    },
    {
      '1': 'referral_code_list',
      '3': 65,
      '4': 1,
      '5': 11,
      '6': '.c35.ResReferralCodeList',
      '9': 0,
      '10': 'referralCodeList'
    },
    {
      '1': 'referral_code_put',
      '3': 67,
      '4': 1,
      '5': 11,
      '6': '.c35.ReferralCodeDoc',
      '9': 0,
      '10': 'referralCodePut'
    },
    {
      '1': 'admin_user_search',
      '3': 90,
      '4': 1,
      '5': 11,
      '6': '.c35.ResAdminUserSearch',
      '9': 0,
      '10': 'adminUserSearch'
    },
    {
      '1': 'admin_user_put',
      '3': 91,
      '4': 1,
      '5': 11,
      '6': '.c35.ResAdminUserPut',
      '9': 0,
      '10': 'adminUserPut'
    },
    {
      '1': 'referral_user_stats',
      '3': 92,
      '4': 1,
      '5': 11,
      '6': '.c35.ResReferralUserStats',
      '9': 0,
      '10': 'referralUserStats'
    },
    {
      '1': 'referral_commission_simulate',
      '3': 93,
      '4': 1,
      '5': 11,
      '6': '.c35.ResReferralCommissionSimulate',
      '9': 0,
      '10': 'referralCommissionSimulate'
    },
    {
      '1': 'channel_telegram_connect',
      '3': 100,
      '4': 1,
      '5': 11,
      '6': '.c35.ResChannelTelegramConnect',
      '9': 0,
      '10': 'channelTelegramConnect'
    },
    {
      '1': 'channel_whatsapp_meta_connect',
      '3': 101,
      '4': 1,
      '5': 11,
      '6': '.c35.ResChannelWhatsappMetaConnect',
      '9': 0,
      '10': 'channelWhatsappMetaConnect'
    },
    {
      '1': 'device_pair',
      '3': 102,
      '4': 1,
      '5': 11,
      '6': '.c35.ResDevicePair',
      '9': 0,
      '10': 'devicePair'
    },
    {
      '1': 'consumption_put',
      '3': 16,
      '4': 1,
      '5': 11,
      '6': '.c35.ResConsumptionPut',
      '9': 0,
      '10': 'consumptionPut'
    },
    {
      '1': 'inst_list',
      '3': 103,
      '4': 1,
      '5': 11,
      '6': '.c35.ResInstList',
      '9': 0,
      '10': 'instList'
    },
    {
      '1': 'inst_get',
      '3': 104,
      '4': 1,
      '5': 11,
      '6': '.c35.ResInstGet',
      '9': 0,
      '10': 'instGet'
    },
    {
      '1': 'inst_put',
      '3': 105,
      '4': 1,
      '5': 11,
      '6': '.c35.ResInstPut',
      '9': 0,
      '10': 'instPut'
    },
    {
      '1': 'inst_delete',
      '3': 106,
      '4': 1,
      '5': 11,
      '6': '.c35.ResInstDelete',
      '9': 0,
      '10': 'instDelete'
    },
    {
      '1': 'voice_stt',
      '3': 107,
      '4': 1,
      '5': 11,
      '6': '.c35.ResVoiceStt',
      '9': 0,
      '10': 'voiceStt'
    },
    {
      '1': 'voice_tts',
      '3': 108,
      '4': 1,
      '5': 11,
      '6': '.c35.ResVoiceTts',
      '9': 0,
      '10': 'voiceTts'
    },
    {
      '1': 'admin_log_list',
      '3': 109,
      '4': 1,
      '5': 11,
      '6': '.c35.ResAdminLogList',
      '9': 0,
      '10': 'adminLogList'
    },
    {
      '1': 'translation_put',
      '3': 110,
      '4': 1,
      '5': 11,
      '6': '.c35.ResTranslationPut',
      '9': 0,
      '10': 'translationPut'
    },
    {
      '1': 'billing_topup_list',
      '3': 111,
      '4': 1,
      '5': 11,
      '6': '.c35.ResBillingTopupList',
      '9': 0,
      '10': 'billingTopupList'
    },
    {
      '1': 'billing_topup_review',
      '3': 112,
      '4': 1,
      '5': 11,
      '6': '.c35.ResBillingTopupReview',
      '9': 0,
      '10': 'billingTopupReview'
    },
    {
      '1': 'commission_withdraw',
      '3': 113,
      '4': 1,
      '5': 11,
      '6': '.c35.ResCommissionWithdraw',
      '9': 0,
      '10': 'commissionWithdraw'
    },
    {
      '1': 'commission_withdraw_list',
      '3': 114,
      '4': 1,
      '5': 11,
      '6': '.c35.ResCommissionWithdrawList',
      '9': 0,
      '10': 'commissionWithdrawList'
    },
    {
      '1': 'commission_withdraw_review',
      '3': 115,
      '4': 1,
      '5': 11,
      '6': '.c35.ResCommissionWithdrawReview',
      '9': 0,
      '10': 'commissionWithdrawReview'
    },
    {
      '1': 'referral_ledger_list',
      '3': 116,
      '4': 1,
      '5': 11,
      '6': '.c35.ResReferralLedgerList',
      '9': 0,
      '10': 'referralLedgerList'
    },
    {
      '1': 'billing_receive_account_put',
      '3': 117,
      '4': 1,
      '5': 11,
      '6': '.c35.ResBillingReceiveAccountPut',
      '9': 0,
      '10': 'billingReceiveAccountPut'
    },
    {
      '1': 'billing_receive_account_list',
      '3': 118,
      '4': 1,
      '5': 11,
      '6': '.c35.ResBillingReceiveAccountList',
      '9': 0,
      '10': 'billingReceiveAccountList'
    },
    {
      '1': 'object_alias_list',
      '3': 119,
      '4': 1,
      '5': 11,
      '6': '.c35.ResObjectAliasList',
      '9': 0,
      '10': 'objectAliasList'
    },
    {
      '1': 'object_alias_put',
      '3': 120,
      '4': 1,
      '5': 11,
      '6': '.c35.ResObjectAliasPut',
      '9': 0,
      '10': 'objectAliasPut'
    },
    {
      '1': 'object_normalizer_list',
      '3': 121,
      '4': 1,
      '5': 11,
      '6': '.c35.ResObjectNormalizerList',
      '9': 0,
      '10': 'objectNormalizerList'
    },
    {
      '1': 'billing_topup_methods',
      '3': 122,
      '4': 1,
      '5': 11,
      '6': '.c35.ResBillingTopupMethods',
      '9': 0,
      '10': 'billingTopupMethods'
    },
    {
      '1': 'billing_topup_get',
      '3': 123,
      '4': 1,
      '5': 11,
      '6': '.c35.ResBillingTopupGet',
      '9': 0,
      '10': 'billingTopupGet'
    },
  ],
  '8': [
    {'1': 'body'},
  ],
};

/// Descriptor for `InvokeRes`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List invokeResDescriptor = $convert.base64Decode(
    'CglJbnZva2VSZXMSFQoGcmVxX2lkGAEgASgJUgVyZXFJZBIfCgtzdGF0dXNfY29kZRgCIAEoBV'
    'IKc3RhdHVzQ29kZRIjCg1lcnJvcl9tZXNzYWdlGAMgASgJUgxlcnJvck1lc3NhZ2USRQoRYmls'
    'bGluZ190b3B1cF9wdXQYCiABKAsyFy5jMzUuUmVzQmlsbGluZ1RvcHVwUHV0SABSD2JpbGxpbm'
    'dUb3B1cFB1dBJUChZiaWxsaW5nX3BhY2thZ2VfcmVkZWVtGAsgASgLMhwuYzM1LlJlc0JpbGxp'
    'bmdQYWNrYWdlUmVkZWVtSABSFGJpbGxpbmdQYWNrYWdlUmVkZWVtElcKF2JpbGxpbmdfcGFja2'
    'FnZV9wcmV2aWV3GAwgASgLMh0uYzM1LlJlc0JpbGxpbmdQYWNrYWdlUHJldmlld0gAUhViaWxs'
    'aW5nUGFja2FnZVByZXZpZXcSPwoPYm90X3VzYWdlX3N0YXRzGA0gASgLMhUuYzM1LlJlc0JvdF'
    'VzYWdlU3RhdHNIAFINYm90VXNhZ2VTdGF0cxJBCg9iaWxsaW5nX3N1bW1hcnkYDiABKAsyFi5j'
    'MzUuUmVzQmlsbGluZ1N1bW1hcnlIAFIOYmlsbGluZ1N1bW1hcnkSVAoWYmlsbGluZ19wbGFuX3'
    'N1YnNjcmliZRgPIAEoCzIcLmMzNS5SZXNCaWxsaW5nUGxhblN1YnNjcmliZUgAUhRiaWxsaW5n'
    'UGxhblN1YnNjcmliZRJBCg9iaWxsaW5nX2hpc3RvcnkYESABKAsyFi5jMzUuUmVzQmlsbGluZ0'
    'hpc3RvcnlIAFIOYmlsbGluZ0hpc3RvcnkSWgoYYmlsbGluZ19wcm9tb3Rpb25fY3JlYXRlGBIg'
    'ASgLMh4uYzM1LlJlc0JpbGxpbmdQcm9tb3Rpb25DcmVhdGVIAFIWYmlsbGluZ1Byb21vdGlvbk'
    'NyZWF0ZRJXChdiaWxsaW5nX3Byb21vdGlvbl9jbGFpbRgTIAEoCzIdLmMzNS5SZXNCaWxsaW5n'
    'UHJvbW90aW9uQ2xhaW1IAFIVYmlsbGluZ1Byb21vdGlvbkNsYWltElQKFmJpbGxpbmdfcHJvbW'
    '90aW9uX2xpc3QYFCABKAsyHC5jMzUuUmVzQmlsbGluZ1Byb21vdGlvbkxpc3RIAFIUYmlsbGlu'
    'Z1Byb21vdGlvbkxpc3QSSAoScmVmZXJyYWxfc2hhcmVfc2V0GD4gASgLMhguYzM1LlJlc1JlZm'
    'VycmFsU2hhcmVTZXRIAFIQcmVmZXJyYWxTaGFyZVNldBJFChFyZWZlcnJhbF90cmVlX2dldBhA'
    'IAEoCzIXLmMzNS5SZXNSZWZlcnJhbFRyZWVHZXRIAFIPcmVmZXJyYWxUcmVlR2V0EkgKEnJlZm'
    'VycmFsX2NvZGVfbGlzdBhBIAEoCzIYLmMzNS5SZXNSZWZlcnJhbENvZGVMaXN0SABSEHJlZmVy'
    'cmFsQ29kZUxpc3QSQgoRcmVmZXJyYWxfY29kZV9wdXQYQyABKAsyFC5jMzUuUmVmZXJyYWxDb2'
    'RlRG9jSABSD3JlZmVycmFsQ29kZVB1dBJFChFhZG1pbl91c2VyX3NlYXJjaBhaIAEoCzIXLmMz'
    'NS5SZXNBZG1pblVzZXJTZWFyY2hIAFIPYWRtaW5Vc2VyU2VhcmNoEjwKDmFkbWluX3VzZXJfcH'
    'V0GFsgASgLMhQuYzM1LlJlc0FkbWluVXNlclB1dEgAUgxhZG1pblVzZXJQdXQSSwoTcmVmZXJy'
    'YWxfdXNlcl9zdGF0cxhcIAEoCzIZLmMzNS5SZXNSZWZlcnJhbFVzZXJTdGF0c0gAUhFyZWZlcn'
    'JhbFVzZXJTdGF0cxJmChxyZWZlcnJhbF9jb21taXNzaW9uX3NpbXVsYXRlGF0gASgLMiIuYzM1'
    'LlJlc1JlZmVycmFsQ29tbWlzc2lvblNpbXVsYXRlSABSGnJlZmVycmFsQ29tbWlzc2lvblNpbX'
    'VsYXRlEloKGGNoYW5uZWxfdGVsZWdyYW1fY29ubmVjdBhkIAEoCzIeLmMzNS5SZXNDaGFubmVs'
    'VGVsZWdyYW1Db25uZWN0SABSFmNoYW5uZWxUZWxlZ3JhbUNvbm5lY3QSZwodY2hhbm5lbF93aG'
    'F0c2FwcF9tZXRhX2Nvbm5lY3QYZSABKAsyIi5jMzUuUmVzQ2hhbm5lbFdoYXRzYXBwTWV0YUNv'
    'bm5lY3RIAFIaY2hhbm5lbFdoYXRzYXBwTWV0YUNvbm5lY3QSNQoLZGV2aWNlX3BhaXIYZiABKA'
    'syEi5jMzUuUmVzRGV2aWNlUGFpckgAUgpkZXZpY2VQYWlyEkEKD2NvbnN1bXB0aW9uX3B1dBgQ'
    'IAEoCzIWLmMzNS5SZXNDb25zdW1wdGlvblB1dEgAUg5jb25zdW1wdGlvblB1dBIvCglpbnN0X2'
    'xpc3QYZyABKAsyEC5jMzUuUmVzSW5zdExpc3RIAFIIaW5zdExpc3QSLAoIaW5zdF9nZXQYaCAB'
    'KAsyDy5jMzUuUmVzSW5zdEdldEgAUgdpbnN0R2V0EiwKCGluc3RfcHV0GGkgASgLMg8uYzM1Ll'
    'Jlc0luc3RQdXRIAFIHaW5zdFB1dBI1CgtpbnN0X2RlbGV0ZRhqIAEoCzISLmMzNS5SZXNJbnN0'
    'RGVsZXRlSABSCmluc3REZWxldGUSLwoJdm9pY2Vfc3R0GGsgASgLMhAuYzM1LlJlc1ZvaWNlU3'
    'R0SABSCHZvaWNlU3R0Ei8KCXZvaWNlX3R0cxhsIAEoCzIQLmMzNS5SZXNWb2ljZVR0c0gAUgh2'
    'b2ljZVR0cxI8Cg5hZG1pbl9sb2dfbGlzdBhtIAEoCzIULmMzNS5SZXNBZG1pbkxvZ0xpc3RIAF'
    'IMYWRtaW5Mb2dMaXN0EkEKD3RyYW5zbGF0aW9uX3B1dBhuIAEoCzIWLmMzNS5SZXNUcmFuc2xh'
    'dGlvblB1dEgAUg50cmFuc2xhdGlvblB1dBJIChJiaWxsaW5nX3RvcHVwX2xpc3QYbyABKAsyGC'
    '5jMzUuUmVzQmlsbGluZ1RvcHVwTGlzdEgAUhBiaWxsaW5nVG9wdXBMaXN0Ek4KFGJpbGxpbmdf'
    'dG9wdXBfcmV2aWV3GHAgASgLMhouYzM1LlJlc0JpbGxpbmdUb3B1cFJldmlld0gAUhJiaWxsaW'
    '5nVG9wdXBSZXZpZXcSTQoTY29tbWlzc2lvbl93aXRoZHJhdxhxIAEoCzIaLmMzNS5SZXNDb21t'
    'aXNzaW9uV2l0aGRyYXdIAFISY29tbWlzc2lvbldpdGhkcmF3EloKGGNvbW1pc3Npb25fd2l0aG'
    'RyYXdfbGlzdBhyIAEoCzIeLmMzNS5SZXNDb21taXNzaW9uV2l0aGRyYXdMaXN0SABSFmNvbW1p'
    'c3Npb25XaXRoZHJhd0xpc3QSYAoaY29tbWlzc2lvbl93aXRoZHJhd19yZXZpZXcYcyABKAsyIC'
    '5jMzUuUmVzQ29tbWlzc2lvbldpdGhkcmF3UmV2aWV3SABSGGNvbW1pc3Npb25XaXRoZHJhd1Jl'
    'dmlldxJOChRyZWZlcnJhbF9sZWRnZXJfbGlzdBh0IAEoCzIaLmMzNS5SZXNSZWZlcnJhbExlZG'
    'dlckxpc3RIAFIScmVmZXJyYWxMZWRnZXJMaXN0EmEKG2JpbGxpbmdfcmVjZWl2ZV9hY2NvdW50'
    'X3B1dBh1IAEoCzIgLmMzNS5SZXNCaWxsaW5nUmVjZWl2ZUFjY291bnRQdXRIAFIYYmlsbGluZ1'
    'JlY2VpdmVBY2NvdW50UHV0EmQKHGJpbGxpbmdfcmVjZWl2ZV9hY2NvdW50X2xpc3QYdiABKAsy'
    'IS5jMzUuUmVzQmlsbGluZ1JlY2VpdmVBY2NvdW50TGlzdEgAUhliaWxsaW5nUmVjZWl2ZUFjY2'
    '91bnRMaXN0EkUKEW9iamVjdF9hbGlhc19saXN0GHcgASgLMhcuYzM1LlJlc09iamVjdEFsaWFz'
    'TGlzdEgAUg9vYmplY3RBbGlhc0xpc3QSQgoQb2JqZWN0X2FsaWFzX3B1dBh4IAEoCzIWLmMzNS'
    '5SZXNPYmplY3RBbGlhc1B1dEgAUg5vYmplY3RBbGlhc1B1dBJUChZvYmplY3Rfbm9ybWFsaXpl'
    'cl9saXN0GHkgASgLMhwuYzM1LlJlc09iamVjdE5vcm1hbGl6ZXJMaXN0SABSFG9iamVjdE5vcm'
    '1hbGl6ZXJMaXN0ElEKFWJpbGxpbmdfdG9wdXBfbWV0aG9kcxh6IAEoCzIbLmMzNS5SZXNCaWxs'
    'aW5nVG9wdXBNZXRob2RzSABSE2JpbGxpbmdUb3B1cE1ldGhvZHMSRQoRYmlsbGluZ190b3B1cF'
    '9nZXQYeyABKAsyFy5jMzUuUmVzQmlsbGluZ1RvcHVwR2V0SABSD2JpbGxpbmdUb3B1cEdldEIG'
    'CgRib2R5');

@$core.Deprecated('Use wsReqDescriptor instead')
const WsReq$json = {
  '1': 'WsReq',
  '2': [
    {'1': 'req_id', '3': 1, '4': 1, '5': 9, '10': 'reqId'},
    {
      '1': 'session_init',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqSessionInit',
      '9': 0,
      '10': 'sessionInit'
    },
    {
      '1': 'sync',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqSync',
      '9': 0,
      '10': 'sync'
    },
    {
      '1': 'inbox_list',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqInboxList',
      '9': 0,
      '10': 'inboxList'
    },
    {
      '1': 'chat_msg_list',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqChatMsgList',
      '9': 0,
      '10': 'chatMsgList'
    },
    {
      '1': 'prompt',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqPrompt',
      '9': 0,
      '10': 'prompt'
    },
    {
      '1': 'prompt_abort',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqPromptAbort',
      '9': 0,
      '10': 'promptAbort'
    },
    {
      '1': 'chat_stop',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqChatStop',
      '9': 0,
      '10': 'chatStop'
    },
    {
      '1': 'chat_send',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqChatSend',
      '9': 0,
      '10': 'chatSend'
    },
    {
      '1': 'invoke',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.c35.InvokeReq',
      '9': 0,
      '10': 'invoke'
    },
    {
      '1': 'skill_list',
      '3': 20,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqSkillList',
      '9': 0,
      '10': 'skillList'
    },
    {
      '1': 'consumption_list',
      '3': 21,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqConsumptionList',
      '9': 0,
      '10': 'consumptionList'
    },
    {
      '1': 'site_list',
      '3': 22,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqSiteList',
      '9': 0,
      '10': 'siteList'
    },
    {
      '1': 'tx_list',
      '3': 23,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqTxList',
      '9': 0,
      '10': 'txList'
    },
    {
      '1': 'consumption_put',
      '3': 24,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqConsumptionPut',
      '9': 0,
      '10': 'consumptionPut'
    },
    {
      '1': 'chat_patch',
      '3': 25,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqChatPatch',
      '9': 0,
      '10': 'chatPatch'
    },
    {
      '1': 'asset_tag_list',
      '3': 26,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqAssetTagList',
      '9': 0,
      '10': 'assetTagList'
    },
    {
      '1': 'identity_list',
      '3': 27,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqIdentityList',
      '9': 0,
      '10': 'identityList'
    },
    {
      '1': 'identity_grant_patch',
      '3': 28,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqIdentityGrantPatch',
      '9': 0,
      '10': 'identityGrantPatch'
    },
    {
      '1': 'bot_peer_list',
      '3': 29,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqBotPeerList',
      '9': 0,
      '10': 'botPeerList'
    },
    {
      '1': 'log_list',
      '3': 30,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqLogList',
      '9': 0,
      '10': 'logList'
    },
    {
      '1': 'identity_put',
      '3': 31,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqIdentityPut',
      '9': 0,
      '10': 'identityPut'
    },
    {
      '1': 'channel_whatsapp_pair_start',
      '3': 32,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqChannelWhatsappPairStart',
      '9': 0,
      '10': 'channelWhatsappPairStart'
    },
    {
      '1': 'channel_whatsapp_pair_watch',
      '3': 33,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqChannelWhatsappPairWatch',
      '9': 0,
      '10': 'channelWhatsappPairWatch'
    },
    {
      '1': 'channel_whatsapp_pair_abort',
      '3': 34,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqChannelWhatsappPairAbort',
      '9': 0,
      '10': 'channelWhatsappPairAbort'
    },
    {
      '1': 'task_list',
      '3': 35,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqTaskList',
      '9': 0,
      '10': 'taskList'
    },
    {
      '1': 'task_put',
      '3': 36,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqTaskPut',
      '9': 0,
      '10': 'taskPut'
    },
    {
      '1': 'task_run_start',
      '3': 37,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqTaskRunStart',
      '9': 0,
      '10': 'taskRunStart'
    },
    {
      '1': 'task_run_cancel',
      '3': 38,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqTaskRunCancel',
      '9': 0,
      '10': 'taskRunCancel'
    },
    {
      '1': 'task_run_list',
      '3': 39,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqTaskRunList',
      '9': 0,
      '10': 'taskRunList'
    },
    {
      '1': 'remote_session_start',
      '3': 40,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqRemoteSessionStart',
      '9': 0,
      '10': 'remoteSessionStart'
    },
    {
      '1': 'rtc_signal_offer',
      '3': 41,
      '4': 1,
      '5': 11,
      '6': '.c35.RtcSignalOffer',
      '9': 0,
      '10': 'rtcSignalOffer'
    },
    {
      '1': 'rtc_signal_answer',
      '3': 42,
      '4': 1,
      '5': 11,
      '6': '.c35.RtcSignalAnswer',
      '9': 0,
      '10': 'rtcSignalAnswer'
    },
    {
      '1': 'rtc_signal_ice',
      '3': 43,
      '4': 1,
      '5': 11,
      '6': '.c35.RtcSignalIce',
      '9': 0,
      '10': 'rtcSignalIce'
    },
    {
      '1': 'remote_session_stop',
      '3': 44,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqRemoteSessionStop',
      '9': 0,
      '10': 'remoteSessionStop'
    },
    {
      '1': 'channel_disconnect',
      '3': 45,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqChannelDisconnect',
      '9': 0,
      '10': 'channelDisconnect'
    },
    {
      '1': 'identity_delete',
      '3': 46,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqIdentityDelete',
      '9': 0,
      '10': 'identityDelete'
    },
    {
      '1': 'skill_put',
      '3': 47,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqSkillPut',
      '9': 0,
      '10': 'skillPut'
    },
    {
      '1': 'skill_catalog_list',
      '3': 48,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqSkillCatalogList',
      '9': 0,
      '10': 'skillCatalogList'
    },
    {
      '1': 'skill_catalog_install',
      '3': 49,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqSkillCatalogInstall',
      '9': 0,
      '10': 'skillCatalogInstall'
    },
    {
      '1': 'remote_ice_config',
      '3': 50,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqRemoteIceConfig',
      '9': 0,
      '10': 'remoteIceConfig'
    },
    {
      '1': 'collection_def_list',
      '3': 51,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqCollectionDefList',
      '9': 0,
      '10': 'collectionDefList'
    },
    {
      '1': 'site_draft_get',
      '3': 52,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqSiteDraftGet',
      '9': 0,
      '10': 'siteDraftGet'
    },
    {
      '1': 'site_draft_put',
      '3': 53,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqSiteDraftPut',
      '9': 0,
      '10': 'siteDraftPut'
    },
    {
      '1': 'site_publish',
      '3': 54,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqSitePublish',
      '9': 0,
      '10': 'sitePublish'
    },
    {
      '1': 'site_product_list',
      '3': 55,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqSiteProductList',
      '9': 0,
      '10': 'siteProductList'
    },
    {
      '1': 'site_product_put',
      '3': 56,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqSiteProductPut',
      '9': 0,
      '10': 'siteProductPut'
    },
    {
      '1': 'site_contact_list',
      '3': 57,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqSiteContactList',
      '9': 0,
      '10': 'siteContactList'
    },
    {
      '1': 'site_contact_put',
      '3': 58,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqSiteContactPut',
      '9': 0,
      '10': 'siteContactPut'
    },
    {
      '1': 'site_object_list',
      '3': 59,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqSiteObjectList',
      '9': 0,
      '10': 'siteObjectList'
    },
    {
      '1': 'site_object_put',
      '3': 60,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqSiteObjectPut',
      '9': 0,
      '10': 'siteObjectPut'
    },
    {
      '1': 'site_domain_list',
      '3': 61,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqSiteDomainList',
      '9': 0,
      '10': 'siteDomainList'
    },
    {
      '1': 'site_domain_put',
      '3': 62,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqSiteDomainPut',
      '9': 0,
      '10': 'siteDomainPut'
    },
    {
      '1': 'skill_catalog_search',
      '3': 63,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqSkillCatalogSearch',
      '9': 0,
      '10': 'skillCatalogSearch'
    },
    {
      '1': 'skill_catalog_submit',
      '3': 64,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqSkillCatalogSubmit',
      '9': 0,
      '10': 'skillCatalogSubmit'
    },
    {
      '1': 'skill_run_report',
      '3': 65,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqSkillRunReport',
      '9': 0,
      '10': 'skillRunReport'
    },
    {
      '1': 'req_remote_screenshot',
      '3': 66,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqRemoteScreenshot',
      '9': 0,
      '10': 'reqRemoteScreenshot'
    },
    {
      '1': 'req_remote_command',
      '3': 67,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqRemoteCommand',
      '9': 0,
      '10': 'reqRemoteCommand'
    },
    {
      '1': 'voice_stt',
      '3': 68,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqVoiceStt',
      '9': 0,
      '10': 'voiceStt'
    },
    {
      '1': 'voice_tts',
      '3': 69,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqVoiceTts',
      '9': 0,
      '10': 'voiceTts'
    },
    {
      '1': 'stats_subscribe',
      '3': 70,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqStatsSubscribe',
      '9': 0,
      '10': 'statsSubscribe'
    },
    {
      '1': 'stats_unsubscribe',
      '3': 71,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqStatsUnsubscribe',
      '9': 0,
      '10': 'statsUnsubscribe'
    },
    {
      '1': 'log_subscribe',
      '3': 72,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqLogSubscribe',
      '9': 0,
      '10': 'logSubscribe'
    },
    {
      '1': 'log_unsubscribe',
      '3': 73,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqLogUnsubscribe',
      '9': 0,
      '10': 'logUnsubscribe'
    },
    {
      '1': 'mention_list',
      '3': 74,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqMentionList',
      '9': 0,
      '10': 'mentionList'
    },
    {
      '1': 'mention_search',
      '3': 75,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqMentionSearch',
      '9': 0,
      '10': 'mentionSearch'
    },
    {
      '1': 'hint_touch',
      '3': 76,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqHintTouch',
      '9': 0,
      '10': 'hintTouch'
    },
    {
      '1': 'site_config_put',
      '3': 77,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqSiteConfigPut',
      '9': 0,
      '10': 'siteConfigPut'
    },
    {
      '1': 'site_preview_token',
      '3': 78,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqSitePreviewToken',
      '9': 0,
      '10': 'sitePreviewToken'
    },
    {
      '1': 'tx_get',
      '3': 79,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqTxGet',
      '9': 0,
      '10': 'txGet'
    },
    {
      '1': 'tx_put',
      '3': 80,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqTxPut',
      '9': 0,
      '10': 'txPut'
    },
    {
      '1': 'tx_preview',
      '3': 81,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqTxPreview',
      '9': 0,
      '10': 'txPreview'
    },
    {
      '1': 'tx_debt_pay',
      '3': 82,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqTxDebtPay',
      '9': 0,
      '10': 'txDebtPay'
    },
    {
      '1': 'site_query_run',
      '3': 83,
      '4': 1,
      '5': 11,
      '6': '.c35.ReqSiteQueryRun',
      '9': 0,
      '10': 'siteQueryRun'
    },
  ],
  '8': [
    {'1': 'body'},
  ],
};

/// Descriptor for `WsReq`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List wsReqDescriptor = $convert.base64Decode(
    'CgVXc1JlcRIVCgZyZXFfaWQYASABKAlSBXJlcUlkEjgKDHNlc3Npb25faW5pdBgCIAEoCzITLm'
    'MzNS5SZXFTZXNzaW9uSW5pdEgAUgtzZXNzaW9uSW5pdBIiCgRzeW5jGAMgASgLMgwuYzM1LlJl'
    'cVN5bmNIAFIEc3luYxIyCgppbmJveF9saXN0GAQgASgLMhEuYzM1LlJlcUluYm94TGlzdEgAUg'
    'lpbmJveExpc3QSOQoNY2hhdF9tc2dfbGlzdBgFIAEoCzITLmMzNS5SZXFDaGF0TXNnTGlzdEgA'
    'UgtjaGF0TXNnTGlzdBIoCgZwcm9tcHQYBiABKAsyDi5jMzUuUmVxUHJvbXB0SABSBnByb21wdB'
    'I4Cgxwcm9tcHRfYWJvcnQYByABKAsyEy5jMzUuUmVxUHJvbXB0QWJvcnRIAFILcHJvbXB0QWJv'
    'cnQSLwoJY2hhdF9zdG9wGAggASgLMhAuYzM1LlJlcUNoYXRTdG9wSABSCGNoYXRTdG9wEi8KCW'
    'NoYXRfc2VuZBgJIAEoCzIQLmMzNS5SZXFDaGF0U2VuZEgAUghjaGF0U2VuZBIoCgZpbnZva2UY'
    'CiABKAsyDi5jMzUuSW52b2tlUmVxSABSBmludm9rZRIyCgpza2lsbF9saXN0GBQgASgLMhEuYz'
    'M1LlJlcVNraWxsTGlzdEgAUglza2lsbExpc3QSRAoQY29uc3VtcHRpb25fbGlzdBgVIAEoCzIX'
    'LmMzNS5SZXFDb25zdW1wdGlvbkxpc3RIAFIPY29uc3VtcHRpb25MaXN0Ei8KCXNpdGVfbGlzdB'
    'gWIAEoCzIQLmMzNS5SZXFTaXRlTGlzdEgAUghzaXRlTGlzdBIpCgd0eF9saXN0GBcgASgLMg4u'
    'YzM1LlJlcVR4TGlzdEgAUgZ0eExpc3QSQQoPY29uc3VtcHRpb25fcHV0GBggASgLMhYuYzM1Ll'
    'JlcUNvbnN1bXB0aW9uUHV0SABSDmNvbnN1bXB0aW9uUHV0EjIKCmNoYXRfcGF0Y2gYGSABKAsy'
    'ES5jMzUuUmVxQ2hhdFBhdGNoSABSCWNoYXRQYXRjaBI8Cg5hc3NldF90YWdfbGlzdBgaIAEoCz'
    'IULmMzNS5SZXFBc3NldFRhZ0xpc3RIAFIMYXNzZXRUYWdMaXN0EjsKDWlkZW50aXR5X2xpc3QY'
    'GyABKAsyFC5jMzUuUmVxSWRlbnRpdHlMaXN0SABSDGlkZW50aXR5TGlzdBJOChRpZGVudGl0eV'
    '9ncmFudF9wYXRjaBgcIAEoCzIaLmMzNS5SZXFJZGVudGl0eUdyYW50UGF0Y2hIAFISaWRlbnRp'
    'dHlHcmFudFBhdGNoEjkKDWJvdF9wZWVyX2xpc3QYHSABKAsyEy5jMzUuUmVxQm90UGVlckxpc3'
    'RIAFILYm90UGVlckxpc3QSLAoIbG9nX2xpc3QYHiABKAsyDy5jMzUuUmVxTG9nTGlzdEgAUgds'
    'b2dMaXN0EjgKDGlkZW50aXR5X3B1dBgfIAEoCzITLmMzNS5SZXFJZGVudGl0eVB1dEgAUgtpZG'
    'VudGl0eVB1dBJhChtjaGFubmVsX3doYXRzYXBwX3BhaXJfc3RhcnQYICABKAsyIC5jMzUuUmVx'
    'Q2hhbm5lbFdoYXRzYXBwUGFpclN0YXJ0SABSGGNoYW5uZWxXaGF0c2FwcFBhaXJTdGFydBJhCh'
    'tjaGFubmVsX3doYXRzYXBwX3BhaXJfd2F0Y2gYISABKAsyIC5jMzUuUmVxQ2hhbm5lbFdoYXRz'
    'YXBwUGFpcldhdGNoSABSGGNoYW5uZWxXaGF0c2FwcFBhaXJXYXRjaBJhChtjaGFubmVsX3doYX'
    'RzYXBwX3BhaXJfYWJvcnQYIiABKAsyIC5jMzUuUmVxQ2hhbm5lbFdoYXRzYXBwUGFpckFib3J0'
    'SABSGGNoYW5uZWxXaGF0c2FwcFBhaXJBYm9ydBIvCgl0YXNrX2xpc3QYIyABKAsyEC5jMzUuUm'
    'VxVGFza0xpc3RIAFIIdGFza0xpc3QSLAoIdGFza19wdXQYJCABKAsyDy5jMzUuUmVxVGFza1B1'
    'dEgAUgd0YXNrUHV0EjwKDnRhc2tfcnVuX3N0YXJ0GCUgASgLMhQuYzM1LlJlcVRhc2tSdW5TdG'
    'FydEgAUgx0YXNrUnVuU3RhcnQSPwoPdGFza19ydW5fY2FuY2VsGCYgASgLMhUuYzM1LlJlcVRh'
    'c2tSdW5DYW5jZWxIAFINdGFza1J1bkNhbmNlbBI5Cg10YXNrX3J1bl9saXN0GCcgASgLMhMuYz'
    'M1LlJlcVRhc2tSdW5MaXN0SABSC3Rhc2tSdW5MaXN0Ek4KFHJlbW90ZV9zZXNzaW9uX3N0YXJ0'
    'GCggASgLMhouYzM1LlJlcVJlbW90ZVNlc3Npb25TdGFydEgAUhJyZW1vdGVTZXNzaW9uU3Rhcn'
    'QSPwoQcnRjX3NpZ25hbF9vZmZlchgpIAEoCzITLmMzNS5SdGNTaWduYWxPZmZlckgAUg5ydGNT'
    'aWduYWxPZmZlchJCChFydGNfc2lnbmFsX2Fuc3dlchgqIAEoCzIULmMzNS5SdGNTaWduYWxBbn'
    'N3ZXJIAFIPcnRjU2lnbmFsQW5zd2VyEjkKDnJ0Y19zaWduYWxfaWNlGCsgASgLMhEuYzM1LlJ0'
    'Y1NpZ25hbEljZUgAUgxydGNTaWduYWxJY2USSwoTcmVtb3RlX3Nlc3Npb25fc3RvcBgsIAEoCz'
    'IZLmMzNS5SZXFSZW1vdGVTZXNzaW9uU3RvcEgAUhFyZW1vdGVTZXNzaW9uU3RvcBJKChJjaGFu'
    'bmVsX2Rpc2Nvbm5lY3QYLSABKAsyGS5jMzUuUmVxQ2hhbm5lbERpc2Nvbm5lY3RIAFIRY2hhbm'
    '5lbERpc2Nvbm5lY3QSQQoPaWRlbnRpdHlfZGVsZXRlGC4gASgLMhYuYzM1LlJlcUlkZW50aXR5'
    'RGVsZXRlSABSDmlkZW50aXR5RGVsZXRlEi8KCXNraWxsX3B1dBgvIAEoCzIQLmMzNS5SZXFTa2'
    'lsbFB1dEgAUghza2lsbFB1dBJIChJza2lsbF9jYXRhbG9nX2xpc3QYMCABKAsyGC5jMzUuUmVx'
    'U2tpbGxDYXRhbG9nTGlzdEgAUhBza2lsbENhdGFsb2dMaXN0ElEKFXNraWxsX2NhdGFsb2dfaW'
    '5zdGFsbBgxIAEoCzIbLmMzNS5SZXFTa2lsbENhdGFsb2dJbnN0YWxsSABSE3NraWxsQ2F0YWxv'
    'Z0luc3RhbGwSRQoRcmVtb3RlX2ljZV9jb25maWcYMiABKAsyFy5jMzUuUmVxUmVtb3RlSWNlQ2'
    '9uZmlnSABSD3JlbW90ZUljZUNvbmZpZxJLChNjb2xsZWN0aW9uX2RlZl9saXN0GDMgASgLMhku'
    'YzM1LlJlcUNvbGxlY3Rpb25EZWZMaXN0SABSEWNvbGxlY3Rpb25EZWZMaXN0EjwKDnNpdGVfZH'
    'JhZnRfZ2V0GDQgASgLMhQuYzM1LlJlcVNpdGVEcmFmdEdldEgAUgxzaXRlRHJhZnRHZXQSPAoO'
    'c2l0ZV9kcmFmdF9wdXQYNSABKAsyFC5jMzUuUmVxU2l0ZURyYWZ0UHV0SABSDHNpdGVEcmFmdF'
    'B1dBI4CgxzaXRlX3B1Ymxpc2gYNiABKAsyEy5jMzUuUmVxU2l0ZVB1Ymxpc2hIAFILc2l0ZVB1'
    'Ymxpc2gSRQoRc2l0ZV9wcm9kdWN0X2xpc3QYNyABKAsyFy5jMzUuUmVxU2l0ZVByb2R1Y3RMaX'
    'N0SABSD3NpdGVQcm9kdWN0TGlzdBJCChBzaXRlX3Byb2R1Y3RfcHV0GDggASgLMhYuYzM1LlJl'
    'cVNpdGVQcm9kdWN0UHV0SABSDnNpdGVQcm9kdWN0UHV0EkUKEXNpdGVfY29udGFjdF9saXN0GD'
    'kgASgLMhcuYzM1LlJlcVNpdGVDb250YWN0TGlzdEgAUg9zaXRlQ29udGFjdExpc3QSQgoQc2l0'
    'ZV9jb250YWN0X3B1dBg6IAEoCzIWLmMzNS5SZXFTaXRlQ29udGFjdFB1dEgAUg5zaXRlQ29udG'
    'FjdFB1dBJCChBzaXRlX29iamVjdF9saXN0GDsgASgLMhYuYzM1LlJlcVNpdGVPYmplY3RMaXN0'
    'SABSDnNpdGVPYmplY3RMaXN0Ej8KD3NpdGVfb2JqZWN0X3B1dBg8IAEoCzIVLmMzNS5SZXFTaX'
    'RlT2JqZWN0UHV0SABSDXNpdGVPYmplY3RQdXQSQgoQc2l0ZV9kb21haW5fbGlzdBg9IAEoCzIW'
    'LmMzNS5SZXFTaXRlRG9tYWluTGlzdEgAUg5zaXRlRG9tYWluTGlzdBI/Cg9zaXRlX2RvbWFpbl'
    '9wdXQYPiABKAsyFS5jMzUuUmVxU2l0ZURvbWFpblB1dEgAUg1zaXRlRG9tYWluUHV0Ek4KFHNr'
    'aWxsX2NhdGFsb2dfc2VhcmNoGD8gASgLMhouYzM1LlJlcVNraWxsQ2F0YWxvZ1NlYXJjaEgAUh'
    'Jza2lsbENhdGFsb2dTZWFyY2gSTgoUc2tpbGxfY2F0YWxvZ19zdWJtaXQYQCABKAsyGi5jMzUu'
    'UmVxU2tpbGxDYXRhbG9nU3VibWl0SABSEnNraWxsQ2F0YWxvZ1N1Ym1pdBJCChBza2lsbF9ydW'
    '5fcmVwb3J0GEEgASgLMhYuYzM1LlJlcVNraWxsUnVuUmVwb3J0SABSDnNraWxsUnVuUmVwb3J0'
    'Ek4KFXJlcV9yZW1vdGVfc2NyZWVuc2hvdBhCIAEoCzIYLmMzNS5SZXFSZW1vdGVTY3JlZW5zaG'
    '90SABSE3JlcVJlbW90ZVNjcmVlbnNob3QSRQoScmVxX3JlbW90ZV9jb21tYW5kGEMgASgLMhUu'
    'YzM1LlJlcVJlbW90ZUNvbW1hbmRIAFIQcmVxUmVtb3RlQ29tbWFuZBIvCgl2b2ljZV9zdHQYRC'
    'ABKAsyEC5jMzUuUmVxVm9pY2VTdHRIAFIIdm9pY2VTdHQSLwoJdm9pY2VfdHRzGEUgASgLMhAu'
    'YzM1LlJlcVZvaWNlVHRzSABSCHZvaWNlVHRzEkEKD3N0YXRzX3N1YnNjcmliZRhGIAEoCzIWLm'
    'MzNS5SZXFTdGF0c1N1YnNjcmliZUgAUg5zdGF0c1N1YnNjcmliZRJHChFzdGF0c191bnN1YnNj'
    'cmliZRhHIAEoCzIYLmMzNS5SZXFTdGF0c1Vuc3Vic2NyaWJlSABSEHN0YXRzVW5zdWJzY3JpYm'
    'USOwoNbG9nX3N1YnNjcmliZRhIIAEoCzIULmMzNS5SZXFMb2dTdWJzY3JpYmVIAFIMbG9nU3Vi'
    'c2NyaWJlEkEKD2xvZ191bnN1YnNjcmliZRhJIAEoCzIWLmMzNS5SZXFMb2dVbnN1YnNjcmliZU'
    'gAUg5sb2dVbnN1YnNjcmliZRI4CgxtZW50aW9uX2xpc3QYSiABKAsyEy5jMzUuUmVxTWVudGlv'
    'bkxpc3RIAFILbWVudGlvbkxpc3QSPgoObWVudGlvbl9zZWFyY2gYSyABKAsyFS5jMzUuUmVxTW'
    'VudGlvblNlYXJjaEgAUg1tZW50aW9uU2VhcmNoEjIKCmhpbnRfdG91Y2gYTCABKAsyES5jMzUu'
    'UmVxSGludFRvdWNoSABSCWhpbnRUb3VjaBI/Cg9zaXRlX2NvbmZpZ19wdXQYTSABKAsyFS5jMz'
    'UuUmVxU2l0ZUNvbmZpZ1B1dEgAUg1zaXRlQ29uZmlnUHV0EkgKEnNpdGVfcHJldmlld190b2tl'
    'bhhOIAEoCzIYLmMzNS5SZXFTaXRlUHJldmlld1Rva2VuSABSEHNpdGVQcmV2aWV3VG9rZW4SJg'
    'oGdHhfZ2V0GE8gASgLMg0uYzM1LlJlcVR4R2V0SABSBXR4R2V0EiYKBnR4X3B1dBhQIAEoCzIN'
    'LmMzNS5SZXFUeFB1dEgAUgV0eFB1dBIyCgp0eF9wcmV2aWV3GFEgASgLMhEuYzM1LlJlcVR4UH'
    'Jldmlld0gAUgl0eFByZXZpZXcSMwoLdHhfZGVidF9wYXkYUiABKAsyES5jMzUuUmVxVHhEZWJ0'
    'UGF5SABSCXR4RGVidFBheRI8Cg5zaXRlX3F1ZXJ5X3J1bhhTIAEoCzIULmMzNS5SZXFTaXRlUX'
    'VlcnlSdW5IAFIMc2l0ZVF1ZXJ5UnVuQgYKBGJvZHk=');

@$core.Deprecated('Use wsResDescriptor instead')
const WsRes$json = {
  '1': 'WsRes',
  '2': [
    {'1': 'req_id', '3': 1, '4': 1, '5': 9, '10': 'reqId'},
    {'1': 'err', '3': 2, '4': 1, '5': 11, '6': '.c35.Err', '9': 0, '10': 'err'},
    {
      '1': 'session_init',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.c35.ResSessionInit',
      '9': 0,
      '10': 'sessionInit'
    },
    {
      '1': 'sync',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.c35.ResSync',
      '9': 0,
      '10': 'sync'
    },
    {
      '1': 'inbox_list',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.c35.ResInboxList',
      '9': 0,
      '10': 'inboxList'
    },
    {
      '1': 'chat_msg_list',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.c35.ResChatMsgList',
      '9': 0,
      '10': 'chatMsgList'
    },
    {
      '1': 'prompt_start',
      '3': 20,
      '4': 1,
      '5': 11,
      '6': '.c35.ResPromptStart',
      '9': 0,
      '10': 'promptStart'
    },
    {
      '1': 'prompt_delta',
      '3': 21,
      '4': 1,
      '5': 11,
      '6': '.c35.ResPromptDelta',
      '9': 0,
      '10': 'promptDelta'
    },
    {
      '1': 'prompt_end',
      '3': 22,
      '4': 1,
      '5': 11,
      '6': '.c35.ResPromptEnd',
      '9': 0,
      '10': 'promptEnd'
    },
    {
      '1': 'prompt_fail',
      '3': 23,
      '4': 1,
      '5': 11,
      '6': '.c35.ResPromptFail',
      '9': 0,
      '10': 'promptFail'
    },
    {
      '1': 'chat_stop',
      '3': 30,
      '4': 1,
      '5': 11,
      '6': '.c35.ResChatStop',
      '9': 0,
      '10': 'chatStop'
    },
    {
      '1': 'chat_send',
      '3': 31,
      '4': 1,
      '5': 11,
      '6': '.c35.ResChatSend',
      '9': 0,
      '10': 'chatSend'
    },
    {
      '1': 'invoke',
      '3': 40,
      '4': 1,
      '5': 11,
      '6': '.c35.InvokeRes',
      '9': 0,
      '10': 'invoke'
    },
    {
      '1': 'skill_list',
      '3': 80,
      '4': 1,
      '5': 11,
      '6': '.c35.ResSkillList',
      '9': 0,
      '10': 'skillList'
    },
    {
      '1': 'consumption_list',
      '3': 81,
      '4': 1,
      '5': 11,
      '6': '.c35.ResConsumptionList',
      '9': 0,
      '10': 'consumptionList'
    },
    {
      '1': 'site_list',
      '3': 82,
      '4': 1,
      '5': 11,
      '6': '.c35.ResSiteList',
      '9': 0,
      '10': 'siteList'
    },
    {
      '1': 'tx_list',
      '3': 83,
      '4': 1,
      '5': 11,
      '6': '.c35.ResTxList',
      '9': 0,
      '10': 'txList'
    },
    {
      '1': 'consumption_put',
      '3': 84,
      '4': 1,
      '5': 11,
      '6': '.c35.ResConsumptionPut',
      '9': 0,
      '10': 'consumptionPut'
    },
    {
      '1': 'chat_patch',
      '3': 85,
      '4': 1,
      '5': 11,
      '6': '.c35.ResChatPatch',
      '9': 0,
      '10': 'chatPatch'
    },
    {
      '1': 'asset_tag_list',
      '3': 86,
      '4': 1,
      '5': 11,
      '6': '.c35.ResAssetTagList',
      '9': 0,
      '10': 'assetTagList'
    },
    {
      '1': 'identity_list',
      '3': 27,
      '4': 1,
      '5': 11,
      '6': '.c35.ResIdentityList',
      '9': 0,
      '10': 'identityList'
    },
    {
      '1': 'identity_grant_patch',
      '3': 28,
      '4': 1,
      '5': 11,
      '6': '.c35.ResIdentityGrantPatch',
      '9': 0,
      '10': 'identityGrantPatch'
    },
    {
      '1': 'bot_peer_list',
      '3': 29,
      '4': 1,
      '5': 11,
      '6': '.c35.ResBotPeerList',
      '9': 0,
      '10': 'botPeerList'
    },
    {
      '1': 'log_list',
      '3': 87,
      '4': 1,
      '5': 11,
      '6': '.c35.ResLogList',
      '9': 0,
      '10': 'logList'
    },
    {
      '1': 'sync_push',
      '3': 50,
      '4': 1,
      '5': 11,
      '6': '.c35.SyncPush',
      '9': 0,
      '10': 'syncPush'
    },
    {
      '1': 'billing_balance',
      '3': 60,
      '4': 1,
      '5': 11,
      '6': '.c35.BillingPushBalance',
      '9': 0,
      '10': 'billingBalance'
    },
    {
      '1': 'billing_quota',
      '3': 61,
      '4': 1,
      '5': 11,
      '6': '.c35.BillingPushQuota',
      '9': 0,
      '10': 'billingQuota'
    },
    {
      '1': 'billing_commission',
      '3': 62,
      '4': 1,
      '5': 11,
      '6': '.c35.BillingPushCommission',
      '9': 0,
      '10': 'billingCommission'
    },
    {
      '1': 'log_push',
      '3': 70,
      '4': 1,
      '5': 11,
      '6': '.c35.LogPush',
      '9': 0,
      '10': 'logPush'
    },
    {
      '1': 'channel_pair_push',
      '3': 71,
      '4': 1,
      '5': 11,
      '6': '.c35.ChannelPairPush',
      '9': 0,
      '10': 'channelPairPush'
    },
    {
      '1': 'stats_push',
      '3': 72,
      '4': 1,
      '5': 11,
      '6': '.c35.StatsPush',
      '9': 0,
      '10': 'statsPush'
    },
    {
      '1': 'identity_put',
      '3': 88,
      '4': 1,
      '5': 11,
      '6': '.c35.ResIdentityPut',
      '9': 0,
      '10': 'identityPut'
    },
    {
      '1': 'channel_whatsapp_pair_start',
      '3': 32,
      '4': 1,
      '5': 11,
      '6': '.c35.ResChannelWhatsappPair',
      '9': 0,
      '10': 'channelWhatsappPairStart'
    },
    {
      '1': 'channel_whatsapp_pair_watch',
      '3': 33,
      '4': 1,
      '5': 11,
      '6': '.c35.ResChannelWhatsappPair',
      '9': 0,
      '10': 'channelWhatsappPairWatch'
    },
    {
      '1': 'channel_whatsapp_pair_abort',
      '3': 34,
      '4': 1,
      '5': 11,
      '6': '.c35.ResChannelWhatsappPair',
      '9': 0,
      '10': 'channelWhatsappPairAbort'
    },
    {
      '1': 'task_list',
      '3': 35,
      '4': 1,
      '5': 11,
      '6': '.c35.ResTaskList',
      '9': 0,
      '10': 'taskList'
    },
    {
      '1': 'task_put',
      '3': 36,
      '4': 1,
      '5': 11,
      '6': '.c35.ResTaskPut',
      '9': 0,
      '10': 'taskPut'
    },
    {
      '1': 'task_run_start',
      '3': 37,
      '4': 1,
      '5': 11,
      '6': '.c35.ResTaskRunStart',
      '9': 0,
      '10': 'taskRunStart'
    },
    {
      '1': 'task_run_cancel',
      '3': 38,
      '4': 1,
      '5': 11,
      '6': '.c35.ResTaskRunCancel',
      '9': 0,
      '10': 'taskRunCancel'
    },
    {
      '1': 'task_run_list',
      '3': 39,
      '4': 1,
      '5': 11,
      '6': '.c35.ResTaskRunList',
      '9': 0,
      '10': 'taskRunList'
    },
    {
      '1': 'task_run_push',
      '3': 45,
      '4': 1,
      '5': 11,
      '6': '.c35.TaskRunPush',
      '9': 0,
      '10': 'taskRunPush'
    },
    {
      '1': 'remote_session_start',
      '3': 90,
      '4': 1,
      '5': 11,
      '6': '.c35.ResRemoteSessionStart',
      '9': 0,
      '10': 'remoteSessionStart'
    },
    {
      '1': 'remote_session_stop',
      '3': 91,
      '4': 1,
      '5': 11,
      '6': '.c35.ResRemoteSessionStop',
      '9': 0,
      '10': 'remoteSessionStop'
    },
    {
      '1': 'remote_session_push',
      '3': 92,
      '4': 1,
      '5': 11,
      '6': '.c35.RemoteSessionPush',
      '9': 0,
      '10': 'remoteSessionPush'
    },
    {
      '1': 'channel_disconnect',
      '3': 93,
      '4': 1,
      '5': 11,
      '6': '.c35.ResChannelDisconnect',
      '9': 0,
      '10': 'channelDisconnect'
    },
    {
      '1': 'identity_delete',
      '3': 94,
      '4': 1,
      '5': 11,
      '6': '.c35.ResIdentityDelete',
      '9': 0,
      '10': 'identityDelete'
    },
    {
      '1': 'skill_put',
      '3': 95,
      '4': 1,
      '5': 11,
      '6': '.c35.ResSkillPut',
      '9': 0,
      '10': 'skillPut'
    },
    {
      '1': 'skill_catalog_list',
      '3': 96,
      '4': 1,
      '5': 11,
      '6': '.c35.ResSkillCatalogList',
      '9': 0,
      '10': 'skillCatalogList'
    },
    {
      '1': 'skill_catalog_install',
      '3': 97,
      '4': 1,
      '5': 11,
      '6': '.c35.ResSkillCatalogInstall',
      '9': 0,
      '10': 'skillCatalogInstall'
    },
    {
      '1': 'remote_ice_config',
      '3': 98,
      '4': 1,
      '5': 11,
      '6': '.c35.ResRemoteIceConfig',
      '9': 0,
      '10': 'remoteIceConfig'
    },
    {
      '1': 'collection_def_list',
      '3': 102,
      '4': 1,
      '5': 11,
      '6': '.c35.ResCollectionDefList',
      '9': 0,
      '10': 'collectionDefList'
    },
    {
      '1': 'site_draft_get',
      '3': 103,
      '4': 1,
      '5': 11,
      '6': '.c35.ResSiteDraftGet',
      '9': 0,
      '10': 'siteDraftGet'
    },
    {
      '1': 'site_draft_put',
      '3': 104,
      '4': 1,
      '5': 11,
      '6': '.c35.ResSiteDraftPut',
      '9': 0,
      '10': 'siteDraftPut'
    },
    {
      '1': 'site_publish',
      '3': 105,
      '4': 1,
      '5': 11,
      '6': '.c35.ResSitePublish',
      '9': 0,
      '10': 'sitePublish'
    },
    {
      '1': 'site_product_list',
      '3': 106,
      '4': 1,
      '5': 11,
      '6': '.c35.ResSiteProductList',
      '9': 0,
      '10': 'siteProductList'
    },
    {
      '1': 'site_product_put',
      '3': 107,
      '4': 1,
      '5': 11,
      '6': '.c35.ResSiteProductPut',
      '9': 0,
      '10': 'siteProductPut'
    },
    {
      '1': 'site_contact_list',
      '3': 108,
      '4': 1,
      '5': 11,
      '6': '.c35.ResSiteContactList',
      '9': 0,
      '10': 'siteContactList'
    },
    {
      '1': 'site_contact_put',
      '3': 109,
      '4': 1,
      '5': 11,
      '6': '.c35.ResSiteContactPut',
      '9': 0,
      '10': 'siteContactPut'
    },
    {
      '1': 'site_object_list',
      '3': 110,
      '4': 1,
      '5': 11,
      '6': '.c35.ResSiteObjectList',
      '9': 0,
      '10': 'siteObjectList'
    },
    {
      '1': 'site_object_put',
      '3': 111,
      '4': 1,
      '5': 11,
      '6': '.c35.ResSiteObjectPut',
      '9': 0,
      '10': 'siteObjectPut'
    },
    {
      '1': 'site_domain_list',
      '3': 112,
      '4': 1,
      '5': 11,
      '6': '.c35.ResSiteDomainList',
      '9': 0,
      '10': 'siteDomainList'
    },
    {
      '1': 'site_domain_put',
      '3': 113,
      '4': 1,
      '5': 11,
      '6': '.c35.ResSiteDomainPut',
      '9': 0,
      '10': 'siteDomainPut'
    },
    {
      '1': 'skill_catalog_search',
      '3': 114,
      '4': 1,
      '5': 11,
      '6': '.c35.ResSkillCatalogSearch',
      '9': 0,
      '10': 'skillCatalogSearch'
    },
    {
      '1': 'skill_catalog_submit',
      '3': 115,
      '4': 1,
      '5': 11,
      '6': '.c35.ResSkillCatalogSubmit',
      '9': 0,
      '10': 'skillCatalogSubmit'
    },
    {
      '1': 'skill_run_report',
      '3': 116,
      '4': 1,
      '5': 11,
      '6': '.c35.ResSkillRunReport',
      '9': 0,
      '10': 'skillRunReport'
    },
    {
      '1': 'res_remote_screenshot',
      '3': 117,
      '4': 1,
      '5': 11,
      '6': '.c35.ResRemoteScreenshot',
      '9': 0,
      '10': 'resRemoteScreenshot'
    },
    {
      '1': 'res_remote_command',
      '3': 118,
      '4': 1,
      '5': 11,
      '6': '.c35.ResRemoteCommand',
      '9': 0,
      '10': 'resRemoteCommand'
    },
    {
      '1': 'voice_stt',
      '3': 119,
      '4': 1,
      '5': 11,
      '6': '.c35.ResVoiceStt',
      '9': 0,
      '10': 'voiceStt'
    },
    {
      '1': 'voice_tts',
      '3': 120,
      '4': 1,
      '5': 11,
      '6': '.c35.ResVoiceTts',
      '9': 0,
      '10': 'voiceTts'
    },
    {
      '1': 'rtc_signal_offer',
      '3': 99,
      '4': 1,
      '5': 11,
      '6': '.c35.RtcSignalOffer',
      '9': 0,
      '10': 'rtcSignalOffer'
    },
    {
      '1': 'rtc_signal_answer',
      '3': 100,
      '4': 1,
      '5': 11,
      '6': '.c35.RtcSignalAnswer',
      '9': 0,
      '10': 'rtcSignalAnswer'
    },
    {
      '1': 'rtc_signal_ice',
      '3': 101,
      '4': 1,
      '5': 11,
      '6': '.c35.RtcSignalIce',
      '9': 0,
      '10': 'rtcSignalIce'
    },
    {
      '1': 'mention_list',
      '3': 121,
      '4': 1,
      '5': 11,
      '6': '.c35.ResMentionList',
      '9': 0,
      '10': 'mentionList'
    },
    {
      '1': 'mention_search',
      '3': 122,
      '4': 1,
      '5': 11,
      '6': '.c35.ResMentionSearch',
      '9': 0,
      '10': 'mentionSearch'
    },
    {
      '1': 'hint_touch',
      '3': 123,
      '4': 1,
      '5': 11,
      '6': '.c35.ResHintTouch',
      '9': 0,
      '10': 'hintTouch'
    },
    {
      '1': 'prompt_run_push',
      '3': 124,
      '4': 1,
      '5': 11,
      '6': '.c35.PromptRunPush',
      '9': 0,
      '10': 'promptRunPush'
    },
    {
      '1': 'site_config_put',
      '3': 125,
      '4': 1,
      '5': 11,
      '6': '.c35.ResSiteConfigPut',
      '9': 0,
      '10': 'siteConfigPut'
    },
    {
      '1': 'site_preview_token',
      '3': 126,
      '4': 1,
      '5': 11,
      '6': '.c35.ResSitePreviewToken',
      '9': 0,
      '10': 'sitePreviewToken'
    },
    {
      '1': 'tx_get',
      '3': 127,
      '4': 1,
      '5': 11,
      '6': '.c35.ResTxGet',
      '9': 0,
      '10': 'txGet'
    },
    {
      '1': 'tx_put',
      '3': 128,
      '4': 1,
      '5': 11,
      '6': '.c35.ResTxPut',
      '9': 0,
      '10': 'txPut'
    },
    {
      '1': 'tx_preview',
      '3': 129,
      '4': 1,
      '5': 11,
      '6': '.c35.ResTxPreview',
      '9': 0,
      '10': 'txPreview'
    },
    {
      '1': 'tx_debt_pay',
      '3': 130,
      '4': 1,
      '5': 11,
      '6': '.c35.ResTxDebtPay',
      '9': 0,
      '10': 'txDebtPay'
    },
    {
      '1': 'site_query_run',
      '3': 131,
      '4': 1,
      '5': 11,
      '6': '.c35.ResSiteQueryRun',
      '9': 0,
      '10': 'siteQueryRun'
    },
  ],
  '8': [
    {'1': 'body'},
  ],
};

/// Descriptor for `WsRes`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List wsResDescriptor = $convert.base64Decode(
    'CgVXc1JlcxIVCgZyZXFfaWQYASABKAlSBXJlcUlkEhwKA2VychgCIAEoCzIILmMzNS5FcnJIAF'
    'IDZXJyEjgKDHNlc3Npb25faW5pdBgKIAEoCzITLmMzNS5SZXNTZXNzaW9uSW5pdEgAUgtzZXNz'
    'aW9uSW5pdBIiCgRzeW5jGAsgASgLMgwuYzM1LlJlc1N5bmNIAFIEc3luYxIyCgppbmJveF9saX'
    'N0GAwgASgLMhEuYzM1LlJlc0luYm94TGlzdEgAUglpbmJveExpc3QSOQoNY2hhdF9tc2dfbGlz'
    'dBgNIAEoCzITLmMzNS5SZXNDaGF0TXNnTGlzdEgAUgtjaGF0TXNnTGlzdBI4Cgxwcm9tcHRfc3'
    'RhcnQYFCABKAsyEy5jMzUuUmVzUHJvbXB0U3RhcnRIAFILcHJvbXB0U3RhcnQSOAoMcHJvbXB0'
    'X2RlbHRhGBUgASgLMhMuYzM1LlJlc1Byb21wdERlbHRhSABSC3Byb21wdERlbHRhEjIKCnByb2'
    '1wdF9lbmQYFiABKAsyES5jMzUuUmVzUHJvbXB0RW5kSABSCXByb21wdEVuZBI1Cgtwcm9tcHRf'
    'ZmFpbBgXIAEoCzISLmMzNS5SZXNQcm9tcHRGYWlsSABSCnByb21wdEZhaWwSLwoJY2hhdF9zdG'
    '9wGB4gASgLMhAuYzM1LlJlc0NoYXRTdG9wSABSCGNoYXRTdG9wEi8KCWNoYXRfc2VuZBgfIAEo'
    'CzIQLmMzNS5SZXNDaGF0U2VuZEgAUghjaGF0U2VuZBIoCgZpbnZva2UYKCABKAsyDi5jMzUuSW'
    '52b2tlUmVzSABSBmludm9rZRIyCgpza2lsbF9saXN0GFAgASgLMhEuYzM1LlJlc1NraWxsTGlz'
    'dEgAUglza2lsbExpc3QSRAoQY29uc3VtcHRpb25fbGlzdBhRIAEoCzIXLmMzNS5SZXNDb25zdW'
    '1wdGlvbkxpc3RIAFIPY29uc3VtcHRpb25MaXN0Ei8KCXNpdGVfbGlzdBhSIAEoCzIQLmMzNS5S'
    'ZXNTaXRlTGlzdEgAUghzaXRlTGlzdBIpCgd0eF9saXN0GFMgASgLMg4uYzM1LlJlc1R4TGlzdE'
    'gAUgZ0eExpc3QSQQoPY29uc3VtcHRpb25fcHV0GFQgASgLMhYuYzM1LlJlc0NvbnN1bXB0aW9u'
    'UHV0SABSDmNvbnN1bXB0aW9uUHV0EjIKCmNoYXRfcGF0Y2gYVSABKAsyES5jMzUuUmVzQ2hhdF'
    'BhdGNoSABSCWNoYXRQYXRjaBI8Cg5hc3NldF90YWdfbGlzdBhWIAEoCzIULmMzNS5SZXNBc3Nl'
    'dFRhZ0xpc3RIAFIMYXNzZXRUYWdMaXN0EjsKDWlkZW50aXR5X2xpc3QYGyABKAsyFC5jMzUuUm'
    'VzSWRlbnRpdHlMaXN0SABSDGlkZW50aXR5TGlzdBJOChRpZGVudGl0eV9ncmFudF9wYXRjaBgc'
    'IAEoCzIaLmMzNS5SZXNJZGVudGl0eUdyYW50UGF0Y2hIAFISaWRlbnRpdHlHcmFudFBhdGNoEj'
    'kKDWJvdF9wZWVyX2xpc3QYHSABKAsyEy5jMzUuUmVzQm90UGVlckxpc3RIAFILYm90UGVlckxp'
    'c3QSLAoIbG9nX2xpc3QYVyABKAsyDy5jMzUuUmVzTG9nTGlzdEgAUgdsb2dMaXN0EiwKCXN5bm'
    'NfcHVzaBgyIAEoCzINLmMzNS5TeW5jUHVzaEgAUghzeW5jUHVzaBJCCg9iaWxsaW5nX2JhbGFu'
    'Y2UYPCABKAsyFy5jMzUuQmlsbGluZ1B1c2hCYWxhbmNlSABSDmJpbGxpbmdCYWxhbmNlEjwKDW'
    'JpbGxpbmdfcXVvdGEYPSABKAsyFS5jMzUuQmlsbGluZ1B1c2hRdW90YUgAUgxiaWxsaW5nUXVv'
    'dGESSwoSYmlsbGluZ19jb21taXNzaW9uGD4gASgLMhouYzM1LkJpbGxpbmdQdXNoQ29tbWlzc2'
    'lvbkgAUhFiaWxsaW5nQ29tbWlzc2lvbhIpCghsb2dfcHVzaBhGIAEoCzIMLmMzNS5Mb2dQdXNo'
    'SABSB2xvZ1B1c2gSQgoRY2hhbm5lbF9wYWlyX3B1c2gYRyABKAsyFC5jMzUuQ2hhbm5lbFBhaX'
    'JQdXNoSABSD2NoYW5uZWxQYWlyUHVzaBIvCgpzdGF0c19wdXNoGEggASgLMg4uYzM1LlN0YXRz'
    'UHVzaEgAUglzdGF0c1B1c2gSOAoMaWRlbnRpdHlfcHV0GFggASgLMhMuYzM1LlJlc0lkZW50aX'
    'R5UHV0SABSC2lkZW50aXR5UHV0ElwKG2NoYW5uZWxfd2hhdHNhcHBfcGFpcl9zdGFydBggIAEo'
    'CzIbLmMzNS5SZXNDaGFubmVsV2hhdHNhcHBQYWlySABSGGNoYW5uZWxXaGF0c2FwcFBhaXJTdG'
    'FydBJcChtjaGFubmVsX3doYXRzYXBwX3BhaXJfd2F0Y2gYISABKAsyGy5jMzUuUmVzQ2hhbm5l'
    'bFdoYXRzYXBwUGFpckgAUhhjaGFubmVsV2hhdHNhcHBQYWlyV2F0Y2gSXAobY2hhbm5lbF93aG'
    'F0c2FwcF9wYWlyX2Fib3J0GCIgASgLMhsuYzM1LlJlc0NoYW5uZWxXaGF0c2FwcFBhaXJIAFIY'
    'Y2hhbm5lbFdoYXRzYXBwUGFpckFib3J0Ei8KCXRhc2tfbGlzdBgjIAEoCzIQLmMzNS5SZXNUYX'
    'NrTGlzdEgAUgh0YXNrTGlzdBIsCgh0YXNrX3B1dBgkIAEoCzIPLmMzNS5SZXNUYXNrUHV0SABS'
    'B3Rhc2tQdXQSPAoOdGFza19ydW5fc3RhcnQYJSABKAsyFC5jMzUuUmVzVGFza1J1blN0YXJ0SA'
    'BSDHRhc2tSdW5TdGFydBI/Cg90YXNrX3J1bl9jYW5jZWwYJiABKAsyFS5jMzUuUmVzVGFza1J1'
    'bkNhbmNlbEgAUg10YXNrUnVuQ2FuY2VsEjkKDXRhc2tfcnVuX2xpc3QYJyABKAsyEy5jMzUuUm'
    'VzVGFza1J1bkxpc3RIAFILdGFza1J1bkxpc3QSNgoNdGFza19ydW5fcHVzaBgtIAEoCzIQLmMz'
    'NS5UYXNrUnVuUHVzaEgAUgt0YXNrUnVuUHVzaBJOChRyZW1vdGVfc2Vzc2lvbl9zdGFydBhaIA'
    'EoCzIaLmMzNS5SZXNSZW1vdGVTZXNzaW9uU3RhcnRIAFIScmVtb3RlU2Vzc2lvblN0YXJ0EksK'
    'E3JlbW90ZV9zZXNzaW9uX3N0b3AYWyABKAsyGS5jMzUuUmVzUmVtb3RlU2Vzc2lvblN0b3BIAF'
    'IRcmVtb3RlU2Vzc2lvblN0b3ASSAoTcmVtb3RlX3Nlc3Npb25fcHVzaBhcIAEoCzIWLmMzNS5S'
    'ZW1vdGVTZXNzaW9uUHVzaEgAUhFyZW1vdGVTZXNzaW9uUHVzaBJKChJjaGFubmVsX2Rpc2Nvbm'
    '5lY3QYXSABKAsyGS5jMzUuUmVzQ2hhbm5lbERpc2Nvbm5lY3RIAFIRY2hhbm5lbERpc2Nvbm5l'
    'Y3QSQQoPaWRlbnRpdHlfZGVsZXRlGF4gASgLMhYuYzM1LlJlc0lkZW50aXR5RGVsZXRlSABSDm'
    'lkZW50aXR5RGVsZXRlEi8KCXNraWxsX3B1dBhfIAEoCzIQLmMzNS5SZXNTa2lsbFB1dEgAUghz'
    'a2lsbFB1dBJIChJza2lsbF9jYXRhbG9nX2xpc3QYYCABKAsyGC5jMzUuUmVzU2tpbGxDYXRhbG'
    '9nTGlzdEgAUhBza2lsbENhdGFsb2dMaXN0ElEKFXNraWxsX2NhdGFsb2dfaW5zdGFsbBhhIAEo'
    'CzIbLmMzNS5SZXNTa2lsbENhdGFsb2dJbnN0YWxsSABSE3NraWxsQ2F0YWxvZ0luc3RhbGwSRQ'
    'oRcmVtb3RlX2ljZV9jb25maWcYYiABKAsyFy5jMzUuUmVzUmVtb3RlSWNlQ29uZmlnSABSD3Jl'
    'bW90ZUljZUNvbmZpZxJLChNjb2xsZWN0aW9uX2RlZl9saXN0GGYgASgLMhkuYzM1LlJlc0NvbG'
    'xlY3Rpb25EZWZMaXN0SABSEWNvbGxlY3Rpb25EZWZMaXN0EjwKDnNpdGVfZHJhZnRfZ2V0GGcg'
    'ASgLMhQuYzM1LlJlc1NpdGVEcmFmdEdldEgAUgxzaXRlRHJhZnRHZXQSPAoOc2l0ZV9kcmFmdF'
    '9wdXQYaCABKAsyFC5jMzUuUmVzU2l0ZURyYWZ0UHV0SABSDHNpdGVEcmFmdFB1dBI4CgxzaXRl'
    'X3B1Ymxpc2gYaSABKAsyEy5jMzUuUmVzU2l0ZVB1Ymxpc2hIAFILc2l0ZVB1Ymxpc2gSRQoRc2'
    'l0ZV9wcm9kdWN0X2xpc3QYaiABKAsyFy5jMzUuUmVzU2l0ZVByb2R1Y3RMaXN0SABSD3NpdGVQ'
    'cm9kdWN0TGlzdBJCChBzaXRlX3Byb2R1Y3RfcHV0GGsgASgLMhYuYzM1LlJlc1NpdGVQcm9kdW'
    'N0UHV0SABSDnNpdGVQcm9kdWN0UHV0EkUKEXNpdGVfY29udGFjdF9saXN0GGwgASgLMhcuYzM1'
    'LlJlc1NpdGVDb250YWN0TGlzdEgAUg9zaXRlQ29udGFjdExpc3QSQgoQc2l0ZV9jb250YWN0X3'
    'B1dBhtIAEoCzIWLmMzNS5SZXNTaXRlQ29udGFjdFB1dEgAUg5zaXRlQ29udGFjdFB1dBJCChBz'
    'aXRlX29iamVjdF9saXN0GG4gASgLMhYuYzM1LlJlc1NpdGVPYmplY3RMaXN0SABSDnNpdGVPYm'
    'plY3RMaXN0Ej8KD3NpdGVfb2JqZWN0X3B1dBhvIAEoCzIVLmMzNS5SZXNTaXRlT2JqZWN0UHV0'
    'SABSDXNpdGVPYmplY3RQdXQSQgoQc2l0ZV9kb21haW5fbGlzdBhwIAEoCzIWLmMzNS5SZXNTaX'
    'RlRG9tYWluTGlzdEgAUg5zaXRlRG9tYWluTGlzdBI/Cg9zaXRlX2RvbWFpbl9wdXQYcSABKAsy'
    'FS5jMzUuUmVzU2l0ZURvbWFpblB1dEgAUg1zaXRlRG9tYWluUHV0Ek4KFHNraWxsX2NhdGFsb2'
    'dfc2VhcmNoGHIgASgLMhouYzM1LlJlc1NraWxsQ2F0YWxvZ1NlYXJjaEgAUhJza2lsbENhdGFs'
    'b2dTZWFyY2gSTgoUc2tpbGxfY2F0YWxvZ19zdWJtaXQYcyABKAsyGi5jMzUuUmVzU2tpbGxDYX'
    'RhbG9nU3VibWl0SABSEnNraWxsQ2F0YWxvZ1N1Ym1pdBJCChBza2lsbF9ydW5fcmVwb3J0GHQg'
    'ASgLMhYuYzM1LlJlc1NraWxsUnVuUmVwb3J0SABSDnNraWxsUnVuUmVwb3J0Ek4KFXJlc19yZW'
    '1vdGVfc2NyZWVuc2hvdBh1IAEoCzIYLmMzNS5SZXNSZW1vdGVTY3JlZW5zaG90SABSE3Jlc1Jl'
    'bW90ZVNjcmVlbnNob3QSRQoScmVzX3JlbW90ZV9jb21tYW5kGHYgASgLMhUuYzM1LlJlc1JlbW'
    '90ZUNvbW1hbmRIAFIQcmVzUmVtb3RlQ29tbWFuZBIvCgl2b2ljZV9zdHQYdyABKAsyEC5jMzUu'
    'UmVzVm9pY2VTdHRIAFIIdm9pY2VTdHQSLwoJdm9pY2VfdHRzGHggASgLMhAuYzM1LlJlc1ZvaW'
    'NlVHRzSABSCHZvaWNlVHRzEj8KEHJ0Y19zaWduYWxfb2ZmZXIYYyABKAsyEy5jMzUuUnRjU2ln'
    'bmFsT2ZmZXJIAFIOcnRjU2lnbmFsT2ZmZXISQgoRcnRjX3NpZ25hbF9hbnN3ZXIYZCABKAsyFC'
    '5jMzUuUnRjU2lnbmFsQW5zd2VySABSD3J0Y1NpZ25hbEFuc3dlchI5Cg5ydGNfc2lnbmFsX2lj'
    'ZRhlIAEoCzIRLmMzNS5SdGNTaWduYWxJY2VIAFIMcnRjU2lnbmFsSWNlEjgKDG1lbnRpb25fbG'
    'lzdBh5IAEoCzITLmMzNS5SZXNNZW50aW9uTGlzdEgAUgttZW50aW9uTGlzdBI+Cg5tZW50aW9u'
    'X3NlYXJjaBh6IAEoCzIVLmMzNS5SZXNNZW50aW9uU2VhcmNoSABSDW1lbnRpb25TZWFyY2gSMg'
    'oKaGludF90b3VjaBh7IAEoCzIRLmMzNS5SZXNIaW50VG91Y2hIAFIJaGludFRvdWNoEjwKD3By'
    'b21wdF9ydW5fcHVzaBh8IAEoCzISLmMzNS5Qcm9tcHRSdW5QdXNoSABSDXByb21wdFJ1blB1c2'
    'gSPwoPc2l0ZV9jb25maWdfcHV0GH0gASgLMhUuYzM1LlJlc1NpdGVDb25maWdQdXRIAFINc2l0'
    'ZUNvbmZpZ1B1dBJIChJzaXRlX3ByZXZpZXdfdG9rZW4YfiABKAsyGC5jMzUuUmVzU2l0ZVByZX'
    'ZpZXdUb2tlbkgAUhBzaXRlUHJldmlld1Rva2VuEiYKBnR4X2dldBh/IAEoCzINLmMzNS5SZXNU'
    'eEdldEgAUgV0eEdldBInCgZ0eF9wdXQYgAEgASgLMg0uYzM1LlJlc1R4UHV0SABSBXR4UHV0Ej'
    'MKCnR4X3ByZXZpZXcYgQEgASgLMhEuYzM1LlJlc1R4UHJldmlld0gAUgl0eFByZXZpZXcSNAoL'
    'dHhfZGVidF9wYXkYggEgASgLMhEuYzM1LlJlc1R4RGVidFBheUgAUgl0eERlYnRQYXkSPQoOc2'
    'l0ZV9xdWVyeV9ydW4YgwEgASgLMhQuYzM1LlJlc1NpdGVRdWVyeVJ1bkgAUgxzaXRlUXVlcnlS'
    'dW5CBgoEYm9keQ==');
