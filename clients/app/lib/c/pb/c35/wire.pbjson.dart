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
    'Fi5jMzUuUmVxQmlsbGluZ0hpc3RvcnlIAFIOYmlsbGluZ0hpc3RvcnkSSAoScmVmZXJyYWxfc2'
    'hhcmVfc2V0GD4gASgLMhguYzM1LlJlcVJlZmVycmFsU2hhcmVTZXRIAFIQcmVmZXJyYWxTaGFy'
    'ZVNldBJFChFyZWZlcnJhbF90cmVlX2dldBhAIAEoCzIXLmMzNS5SZXFSZWZlcnJhbFRyZWVHZX'
    'RIAFIPcmVmZXJyYWxUcmVlR2V0EkgKEnJlZmVycmFsX2NvZGVfbGlzdBhBIAEoCzIYLmMzNS5S'
    'ZXFSZWZlcnJhbENvZGVMaXN0SABSEHJlZmVycmFsQ29kZUxpc3QSRQoRcmVmZXJyYWxfY29kZV'
    '9wdXQYQyABKAsyFy5jMzUuUmVxUmVmZXJyYWxDb2RlUHV0SABSD3JlZmVycmFsQ29kZVB1dBJO'
    'ChRyZWZlcnJhbF9jb2RlX2RlbGV0ZRhEIAEoCzIaLmMzNS5SZXFSZWZlcnJhbENvZGVEZWxldG'
    'VIAFIScmVmZXJyYWxDb2RlRGVsZXRlEkUKEWFkbWluX3VzZXJfc2VhcmNoGFogASgLMhcuYzM1'
    'LlJlcUFkbWluVXNlclNlYXJjaEgAUg9hZG1pblVzZXJTZWFyY2gSPAoOYWRtaW5fdXNlcl9wdX'
    'QYWyABKAsyFC5jMzUuUmVxQWRtaW5Vc2VyUHV0SABSDGFkbWluVXNlclB1dBJLChNyZWZlcnJh'
    'bF91c2VyX3N0YXRzGFwgASgLMhkuYzM1LlJlcVJlZmVycmFsVXNlclN0YXRzSABSEXJlZmVycm'
    'FsVXNlclN0YXRzEmYKHHJlZmVycmFsX2NvbW1pc3Npb25fc2ltdWxhdGUYXSABKAsyIi5jMzUu'
    'UmVxUmVmZXJyYWxDb21taXNzaW9uU2ltdWxhdGVIAFIacmVmZXJyYWxDb21taXNzaW9uU2ltdW'
    'xhdGUSWgoYY2hhbm5lbF90ZWxlZ3JhbV9jb25uZWN0GGQgASgLMh4uYzM1LlJlcUNoYW5uZWxU'
    'ZWxlZ3JhbUNvbm5lY3RIAFIWY2hhbm5lbFRlbGVncmFtQ29ubmVjdBJnCh1jaGFubmVsX3doYX'
    'RzYXBwX21ldGFfY29ubmVjdBhlIAEoCzIiLmMzNS5SZXFDaGFubmVsV2hhdHNhcHBNZXRhQ29u'
    'bmVjdEgAUhpjaGFubmVsV2hhdHNhcHBNZXRhQ29ubmVjdBI1CgtkZXZpY2VfcGFpchhmIAEoCz'
    'ISLmMzNS5SZXFEZXZpY2VQYWlySABSCmRldmljZVBhaXISQQoPY29uc3VtcHRpb25fcHV0GBAg'
    'ASgLMhYuYzM1LlJlcUNvbnN1bXB0aW9uUHV0SABSDmNvbnN1bXB0aW9uUHV0QgYKBGJvZHk=');

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
    'hpc3RvcnlIAFIOYmlsbGluZ0hpc3RvcnkSSAoScmVmZXJyYWxfc2hhcmVfc2V0GD4gASgLMhgu'
    'YzM1LlJlc1JlZmVycmFsU2hhcmVTZXRIAFIQcmVmZXJyYWxTaGFyZVNldBJFChFyZWZlcnJhbF'
    '90cmVlX2dldBhAIAEoCzIXLmMzNS5SZXNSZWZlcnJhbFRyZWVHZXRIAFIPcmVmZXJyYWxUcmVl'
    'R2V0EkgKEnJlZmVycmFsX2NvZGVfbGlzdBhBIAEoCzIYLmMzNS5SZXNSZWZlcnJhbENvZGVMaX'
    'N0SABSEHJlZmVycmFsQ29kZUxpc3QSQgoRcmVmZXJyYWxfY29kZV9wdXQYQyABKAsyFC5jMzUu'
    'UmVmZXJyYWxDb2RlRG9jSABSD3JlZmVycmFsQ29kZVB1dBJFChFhZG1pbl91c2VyX3NlYXJjaB'
    'haIAEoCzIXLmMzNS5SZXNBZG1pblVzZXJTZWFyY2hIAFIPYWRtaW5Vc2VyU2VhcmNoEjwKDmFk'
    'bWluX3VzZXJfcHV0GFsgASgLMhQuYzM1LlJlc0FkbWluVXNlclB1dEgAUgxhZG1pblVzZXJQdX'
    'QSSwoTcmVmZXJyYWxfdXNlcl9zdGF0cxhcIAEoCzIZLmMzNS5SZXNSZWZlcnJhbFVzZXJTdGF0'
    'c0gAUhFyZWZlcnJhbFVzZXJTdGF0cxJmChxyZWZlcnJhbF9jb21taXNzaW9uX3NpbXVsYXRlGF'
    '0gASgLMiIuYzM1LlJlc1JlZmVycmFsQ29tbWlzc2lvblNpbXVsYXRlSABSGnJlZmVycmFsQ29t'
    'bWlzc2lvblNpbXVsYXRlEloKGGNoYW5uZWxfdGVsZWdyYW1fY29ubmVjdBhkIAEoCzIeLmMzNS'
    '5SZXNDaGFubmVsVGVsZWdyYW1Db25uZWN0SABSFmNoYW5uZWxUZWxlZ3JhbUNvbm5lY3QSZwod'
    'Y2hhbm5lbF93aGF0c2FwcF9tZXRhX2Nvbm5lY3QYZSABKAsyIi5jMzUuUmVzQ2hhbm5lbFdoYX'
    'RzYXBwTWV0YUNvbm5lY3RIAFIaY2hhbm5lbFdoYXRzYXBwTWV0YUNvbm5lY3QSNQoLZGV2aWNl'
    'X3BhaXIYZiABKAsyEi5jMzUuUmVzRGV2aWNlUGFpckgAUgpkZXZpY2VQYWlyEkEKD2NvbnN1bX'
    'B0aW9uX3B1dBgQIAEoCzIWLmMzNS5SZXNDb25zdW1wdGlvblB1dEgAUg5jb25zdW1wdGlvblB1'
    'dEIGCgRib2R5');

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
    'SABSGGNoYW5uZWxXaGF0c2FwcFBhaXJBYm9ydEIGCgRib2R5');

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
    'JQdXNoSABSD2NoYW5uZWxQYWlyUHVzaBI4CgxpZGVudGl0eV9wdXQYWCABKAsyEy5jMzUuUmVz'
    'SWRlbnRpdHlQdXRIAFILaWRlbnRpdHlQdXQSXAobY2hhbm5lbF93aGF0c2FwcF9wYWlyX3N0YX'
    'J0GCAgASgLMhsuYzM1LlJlc0NoYW5uZWxXaGF0c2FwcFBhaXJIAFIYY2hhbm5lbFdoYXRzYXBw'
    'UGFpclN0YXJ0ElwKG2NoYW5uZWxfd2hhdHNhcHBfcGFpcl93YXRjaBghIAEoCzIbLmMzNS5SZX'
    'NDaGFubmVsV2hhdHNhcHBQYWlySABSGGNoYW5uZWxXaGF0c2FwcFBhaXJXYXRjaBJcChtjaGFu'
    'bmVsX3doYXRzYXBwX3BhaXJfYWJvcnQYIiABKAsyGy5jMzUuUmVzQ2hhbm5lbFdoYXRzYXBwUG'
    'FpckgAUhhjaGFubmVsV2hhdHNhcHBQYWlyQWJvcnRCBgoEYm9keQ==');
