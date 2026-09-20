//
//  Generated code. Do not modify.
//  source: c35/wire.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use invokeReqDescriptor instead')
const InvokeReq$json = {
  '1': 'InvokeReq',
  '2': [
    {'1': 'req_id', '3': 1, '4': 1, '5': 9, '10': 'reqId'},
    {'1': 'caller_iid', '3': 2, '4': 1, '5': 3, '10': 'callerIid'},
    {'1': 'billing_topup_put', '3': 10, '4': 1, '5': 11, '6': '.c35.ReqBillingTopupPut', '9': 0, '10': 'billingTopupPut'},
    {'1': 'referral_share_set', '3': 62, '4': 1, '5': 11, '6': '.c35.ReqReferralShareSet', '9': 0, '10': 'referralShareSet'},
    {'1': 'referral_tree_get', '3': 64, '4': 1, '5': 11, '6': '.c35.ReqReferralTreeGet', '9': 0, '10': 'referralTreeGet'},
    {'1': 'referral_code_list', '3': 65, '4': 1, '5': 11, '6': '.c35.ReqReferralCodeList', '9': 0, '10': 'referralCodeList'},
    {'1': 'referral_code_put', '3': 67, '4': 1, '5': 11, '6': '.c35.ReqReferralCodePut', '9': 0, '10': 'referralCodePut'},
    {'1': 'referral_code_delete', '3': 68, '4': 1, '5': 11, '6': '.c35.ReqReferralCodeDelete', '9': 0, '10': 'referralCodeDelete'},
    {'1': 'referral_user_stats', '3': 92, '4': 1, '5': 11, '6': '.c35.ReqReferralUserStats', '9': 0, '10': 'referralUserStats'},
  ],
  '8': [
    {'1': 'body'},
  ],
};

/// Descriptor for `InvokeReq`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List invokeReqDescriptor = $convert.base64Decode(
    'CglJbnZva2VSZXESFQoGcmVxX2lkGAEgASgJUgVyZXFJZBIdCgpjYWxsZXJfaWlkGAIgASgDUg'
    'ljYWxsZXJJaWQSRQoRYmlsbGluZ190b3B1cF9wdXQYCiABKAsyFy5jMzUuUmVxQmlsbGluZ1Rv'
    'cHVwUHV0SABSD2JpbGxpbmdUb3B1cFB1dBJIChJyZWZlcnJhbF9zaGFyZV9zZXQYPiABKAsyGC'
    '5jMzUuUmVxUmVmZXJyYWxTaGFyZVNldEgAUhByZWZlcnJhbFNoYXJlU2V0EkUKEXJlZmVycmFs'
    'X3RyZWVfZ2V0GEAgASgLMhcuYzM1LlJlcVJlZmVycmFsVHJlZUdldEgAUg9yZWZlcnJhbFRyZW'
    'VHZXQSSAoScmVmZXJyYWxfY29kZV9saXN0GEEgASgLMhguYzM1LlJlcVJlZmVycmFsQ29kZUxp'
    'c3RIAFIQcmVmZXJyYWxDb2RlTGlzdBJFChFyZWZlcnJhbF9jb2RlX3B1dBhDIAEoCzIXLmMzNS'
    '5SZXFSZWZlcnJhbENvZGVQdXRIAFIPcmVmZXJyYWxDb2RlUHV0Ek4KFHJlZmVycmFsX2NvZGVf'
    'ZGVsZXRlGEQgASgLMhouYzM1LlJlcVJlZmVycmFsQ29kZURlbGV0ZUgAUhJyZWZlcnJhbENvZG'
    'VEZWxldGUSSwoTcmVmZXJyYWxfdXNlcl9zdGF0cxhcIAEoCzIZLmMzNS5SZXFSZWZlcnJhbFVz'
    'ZXJTdGF0c0gAUhFyZWZlcnJhbFVzZXJTdGF0c0IGCgRib2R5');

@$core.Deprecated('Use invokeResDescriptor instead')
const InvokeRes$json = {
  '1': 'InvokeRes',
  '2': [
    {'1': 'req_id', '3': 1, '4': 1, '5': 9, '10': 'reqId'},
    {'1': 'status_code', '3': 2, '4': 1, '5': 5, '10': 'statusCode'},
    {'1': 'error_message', '3': 3, '4': 1, '5': 9, '10': 'errorMessage'},
    {'1': 'billing_topup_put', '3': 10, '4': 1, '5': 11, '6': '.c35.ResBillingTopupPut', '9': 0, '10': 'billingTopupPut'},
    {'1': 'referral_share_set', '3': 62, '4': 1, '5': 11, '6': '.c35.ResReferralShareSet', '9': 0, '10': 'referralShareSet'},
    {'1': 'referral_tree_get', '3': 64, '4': 1, '5': 11, '6': '.c35.ResReferralTreeGet', '9': 0, '10': 'referralTreeGet'},
    {'1': 'referral_code_list', '3': 65, '4': 1, '5': 11, '6': '.c35.ResReferralCodeList', '9': 0, '10': 'referralCodeList'},
    {'1': 'referral_code_put', '3': 67, '4': 1, '5': 11, '6': '.c35.ReferralCodeDoc', '9': 0, '10': 'referralCodePut'},
    {'1': 'referral_user_stats', '3': 92, '4': 1, '5': 11, '6': '.c35.ResReferralUserStats', '9': 0, '10': 'referralUserStats'},
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
    'dUb3B1cFB1dBJIChJyZWZlcnJhbF9zaGFyZV9zZXQYPiABKAsyGC5jMzUuUmVzUmVmZXJyYWxT'
    'aGFyZVNldEgAUhByZWZlcnJhbFNoYXJlU2V0EkUKEXJlZmVycmFsX3RyZWVfZ2V0GEAgASgLMh'
    'cuYzM1LlJlc1JlZmVycmFsVHJlZUdldEgAUg9yZWZlcnJhbFRyZWVHZXQSSAoScmVmZXJyYWxf'
    'Y29kZV9saXN0GEEgASgLMhguYzM1LlJlc1JlZmVycmFsQ29kZUxpc3RIAFIQcmVmZXJyYWxDb2'
    'RlTGlzdBJCChFyZWZlcnJhbF9jb2RlX3B1dBhDIAEoCzIULmMzNS5SZWZlcnJhbENvZGVEb2NI'
    'AFIPcmVmZXJyYWxDb2RlUHV0EksKE3JlZmVycmFsX3VzZXJfc3RhdHMYXCABKAsyGS5jMzUuUm'
    'VzUmVmZXJyYWxVc2VyU3RhdHNIAFIRcmVmZXJyYWxVc2VyU3RhdHNCBgoEYm9keQ==');

@$core.Deprecated('Use wsReqDescriptor instead')
const WsReq$json = {
  '1': 'WsReq',
  '2': [
    {'1': 'req_id', '3': 1, '4': 1, '5': 9, '10': 'reqId'},
    {'1': 'session_init', '3': 2, '4': 1, '5': 11, '6': '.c35.ReqSessionInit', '9': 0, '10': 'sessionInit'},
    {'1': 'sync', '3': 3, '4': 1, '5': 11, '6': '.c35.ReqSync', '9': 0, '10': 'sync'},
    {'1': 'inbox_list', '3': 4, '4': 1, '5': 11, '6': '.c35.ReqInboxList', '9': 0, '10': 'inboxList'},
    {'1': 'chat_msg_list', '3': 5, '4': 1, '5': 11, '6': '.c35.ReqChatMsgList', '9': 0, '10': 'chatMsgList'},
    {'1': 'prompt', '3': 6, '4': 1, '5': 11, '6': '.c35.ReqPrompt', '9': 0, '10': 'prompt'},
    {'1': 'prompt_abort', '3': 7, '4': 1, '5': 11, '6': '.c35.ReqPromptAbort', '9': 0, '10': 'promptAbort'},
    {'1': 'chat_stop', '3': 8, '4': 1, '5': 11, '6': '.c35.ReqChatStop', '9': 0, '10': 'chatStop'},
    {'1': 'chat_send', '3': 9, '4': 1, '5': 11, '6': '.c35.ReqChatSend', '9': 0, '10': 'chatSend'},
    {'1': 'invoke', '3': 10, '4': 1, '5': 11, '6': '.c35.InvokeReq', '9': 0, '10': 'invoke'},
    {'1': 'skill_list', '3': 20, '4': 1, '5': 11, '6': '.c35.ReqSkillList', '9': 0, '10': 'skillList'},
    {'1': 'consumption_list', '3': 21, '4': 1, '5': 11, '6': '.c35.ReqConsumptionList', '9': 0, '10': 'consumptionList'},
    {'1': 'site_list', '3': 22, '4': 1, '5': 11, '6': '.c35.ReqSiteList', '9': 0, '10': 'siteList'},
    {'1': 'tx_list', '3': 23, '4': 1, '5': 11, '6': '.c35.ReqTxList', '9': 0, '10': 'txList'},
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
    'YzM1LlJlcVR4TGlzdEgAUgZ0eExpc3RCBgoEYm9keQ==');

@$core.Deprecated('Use wsResDescriptor instead')
const WsRes$json = {
  '1': 'WsRes',
  '2': [
    {'1': 'req_id', '3': 1, '4': 1, '5': 9, '10': 'reqId'},
    {'1': 'err', '3': 2, '4': 1, '5': 11, '6': '.c35.Err', '9': 0, '10': 'err'},
    {'1': 'session_init', '3': 10, '4': 1, '5': 11, '6': '.c35.ResSessionInit', '9': 0, '10': 'sessionInit'},
    {'1': 'sync', '3': 11, '4': 1, '5': 11, '6': '.c35.ResSync', '9': 0, '10': 'sync'},
    {'1': 'inbox_list', '3': 12, '4': 1, '5': 11, '6': '.c35.ResInboxList', '9': 0, '10': 'inboxList'},
    {'1': 'chat_msg_list', '3': 13, '4': 1, '5': 11, '6': '.c35.ResChatMsgList', '9': 0, '10': 'chatMsgList'},
    {'1': 'prompt_start', '3': 20, '4': 1, '5': 11, '6': '.c35.ResPromptStart', '9': 0, '10': 'promptStart'},
    {'1': 'prompt_delta', '3': 21, '4': 1, '5': 11, '6': '.c35.ResPromptDelta', '9': 0, '10': 'promptDelta'},
    {'1': 'prompt_end', '3': 22, '4': 1, '5': 11, '6': '.c35.ResPromptEnd', '9': 0, '10': 'promptEnd'},
    {'1': 'prompt_fail', '3': 23, '4': 1, '5': 11, '6': '.c35.ResPromptFail', '9': 0, '10': 'promptFail'},
    {'1': 'chat_stop', '3': 30, '4': 1, '5': 11, '6': '.c35.ResChatStop', '9': 0, '10': 'chatStop'},
    {'1': 'chat_send', '3': 31, '4': 1, '5': 11, '6': '.c35.ResChatSend', '9': 0, '10': 'chatSend'},
    {'1': 'invoke', '3': 40, '4': 1, '5': 11, '6': '.c35.InvokeRes', '9': 0, '10': 'invoke'},
    {'1': 'skill_list', '3': 80, '4': 1, '5': 11, '6': '.c35.ResSkillList', '9': 0, '10': 'skillList'},
    {'1': 'consumption_list', '3': 81, '4': 1, '5': 11, '6': '.c35.ResConsumptionList', '9': 0, '10': 'consumptionList'},
    {'1': 'site_list', '3': 82, '4': 1, '5': 11, '6': '.c35.ResSiteList', '9': 0, '10': 'siteList'},
    {'1': 'tx_list', '3': 83, '4': 1, '5': 11, '6': '.c35.ResTxList', '9': 0, '10': 'txList'},
    {'1': 'sync_push', '3': 50, '4': 1, '5': 11, '6': '.c35.SyncPush', '9': 0, '10': 'syncPush'},
    {'1': 'billing_balance', '3': 60, '4': 1, '5': 11, '6': '.c35.BillingPushBalance', '9': 0, '10': 'billingBalance'},
    {'1': 'billing_quota', '3': 61, '4': 1, '5': 11, '6': '.c35.BillingPushQuota', '9': 0, '10': 'billingQuota'},
    {'1': 'billing_commission', '3': 62, '4': 1, '5': 11, '6': '.c35.BillingPushCommission', '9': 0, '10': 'billingCommission'},
    {'1': 'log_push', '3': 70, '4': 1, '5': 11, '6': '.c35.LogPush', '9': 0, '10': 'logPush'},
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
    'gAUgZ0eExpc3QSLAoJc3luY19wdXNoGDIgASgLMg0uYzM1LlN5bmNQdXNoSABSCHN5bmNQdXNo'
    'EkIKD2JpbGxpbmdfYmFsYW5jZRg8IAEoCzIXLmMzNS5CaWxsaW5nUHVzaEJhbGFuY2VIAFIOYm'
    'lsbGluZ0JhbGFuY2USPAoNYmlsbGluZ19xdW90YRg9IAEoCzIVLmMzNS5CaWxsaW5nUHVzaFF1'
    'b3RhSABSDGJpbGxpbmdRdW90YRJLChJiaWxsaW5nX2NvbW1pc3Npb24YPiABKAsyGi5jMzUuQm'
    'lsbGluZ1B1c2hDb21taXNzaW9uSABSEWJpbGxpbmdDb21taXNzaW9uEikKCGxvZ19wdXNoGEYg'
    'ASgLMgwuYzM1LkxvZ1B1c2hIAFIHbG9nUHVzaEIGCgRib2R5');

